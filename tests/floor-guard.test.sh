#!/usr/bin/env bash
# s48 — the floor guard, run on throwaway repositories.

GATE="$METHOD/hooks/po-gate.sh"

floor_repo() {
  scratch_repo
  cd "$SCRATCH"
  # Settings a user may have that change the diff format; the guard pins its own options.
  git config diff.noprefix true
  git config diff.renames false
  git config color.diff always
  echo base > README.md
  git add -A && git commit -qm base
}

commit() { git add -A && git commit -qm "$1"; }
lines() { mkdir -p "$(dirname "$1")"; f="$1"; shift; printf '%s\n' "$@" > "$f"; }
guard() { code=0; out=$(bash "$GATE" floor-guard "$@" 2>"$SCRATCH/.git/guard.err") || code=$?; }
flagged() { grep -qF -- "$1" <<< "$out" || fail "missing flag '$1' in: $out"; }
not_flagged() { ! grep -qF -- "$1" <<< "$out" || fail "unexpected flag '$1' in: $out"; }

test_floor_guard_has_three_outcomes() {
  floor_repo
  git checkout -qb story/s01-a
  lines src/a.ts 'export const a = 1;'
  commit clean
  guard s01-a main
  [ "$code" -eq 0 ] && [ -z "$out" ] || fail "clean story: exit $code, stdout '$out'"

  lines src/a.ts 'export const a = 1;' '// @ts-ignore'
  commit flagged
  guard s01-a main
  [ "$code" -eq 1 ] || fail "flagged story: exit $code"
  flagged 'src/a.ts:2: typecheck-ignored: // @ts-ignore'
  grep -qF 'flag(s) lower the bar of s01-a' "$SCRATCH/.git/guard.err" || fail "no summary on stderr"

  local args
  for args in 's01-a' 's01-a nosuch' 's02-b main'; do
    # shellcheck disable=SC2086
    guard $args
    [ "$code" -eq 2 ] && [ -z "$out" ] || fail "'$args': exit $code, stdout '$out'"
    grep -qF 'cannot verify the floor of' "$SCRATCH/.git/guard.err" || fail "'$args': no exit-2 message"
  done
}

test_floor_guard_flags_new_suppressions() {
  floor_repo
  lines src/legacy.ts '// @ts-ignore' 'const x: number = "a";' 'export default x;'
  commit legacy
  git checkout -qb story/s01-a
  lines src/legacy.ts '// @ts-ignore' 'const x: number = "a";' 'export default x as number;'
  lines src/feature.test.ts \
    '// @ts-expect-error' \
    'const y: string = 1;' \
    '// eslint-disable-next-line no-console' \
    '/* istanbul ignore next */' \
    'it.skip("skips", () => { expect(y).toBe(1); });' \
    'it.only("focuses", () => { expect(y).toBe(1); });'
  lines app/test_calc.py \
    'import os  # noqa: F401' \
    'import pytest' \
    'def helper():  # type: ignore' \
    '    return 1  # pragma: no cover' \
    '@pytest.mark.skip(reason="later")' \
    'def test_add():' \
    '    assert helper() == 1'
  commit story
  guard s01-a main
  [ "$code" -eq 1 ] || fail "exit $code"
  flagged 'src/feature.test.ts:1: typecheck-ignored:'
  flagged 'src/feature.test.ts:3: lint-disabled:'
  flagged 'src/feature.test.ts:4: coverage-excluded:'
  flagged 'src/feature.test.ts:5: test-skipped:'
  flagged 'src/feature.test.ts:6: test-only:'
  flagged 'app/test_calc.py:1: lint-disabled:'
  flagged 'app/test_calc.py:3: typecheck-ignored:'
  flagged 'app/test_calc.py:4: coverage-excluded:'
  flagged 'app/test_calc.py:5: test-skipped:'
  not_flagged 'src/legacy.ts'
}

test_floor_guard_flags_weakened_tests() {
  floor_repo
  lines tests/old.test.ts 'expect(1).toBe(1);'
  lines app/test_calc.py 'def test_add():' '    assert 1 + 1 == 2' '    assert 2 + 2 == 4'
  lines src/calc.test.ts 'it("adds", () => {' '  expect(1 + 1).toBe(2);' '  expect(2 + 2).toBe(4);' '});'
  lines spec/moved.spec.ts 'expect(true).toBe(true);'
  lines app/test_rewrite.py 'def test_mul():' '    assert 2 * 2 == 4'
  commit tests
  git checkout -qb story/s01-a
  git rm -q tests/old.test.ts
  lines app/test_calc.py 'def test_add():' '    assert 1 + 1 == 2'
  lines src/calc.test.ts 'it("adds", () => {' '  expect(1 + 1).toBe(2);' '});'
  git mv spec/moved.spec.ts spec/renamed.spec.ts
  lines app/test_rewrite.py 'def test_mul():' '    assert 2 * 3 == 6'
  commit story
  guard s01-a main
  [ "$code" -eq 1 ] || fail "exit $code"
  flagged 'tests/old.test.ts:0: test-file-deleted:'
  flagged 'app/test_calc.py:2: assertions-dropped: 1 removed, 0 added'
  flagged 'src/calc.test.ts:2: assertions-dropped: 1 removed, 0 added'
  [ "$(grep -cF 'tests/old.test.ts' <<< "$out")" -eq 1 ] || fail "deleted file flagged more than once: $out"
  not_flagged 'spec/'
  not_flagged 'app/test_rewrite.py'
}

test_floor_guard_flags_empty_catch_and_lowered_thresholds() {
  floor_repo
  lines vitest.config.ts 'export default {' '  test: {' '    coverage: {' \
    '      thresholds: { lines: 80, branches: 70 },' '    },' '  },' '};'
  lines .coveragerc '[report]' 'fail_under = 90'
  lines pyproject.toml '[tool.coverage.report]' 'fail_under = 85' 'show_missing = true'
  lines tsconfig.build.json '{' '  "compilerOptions": {' '    "strict": true' '  }' '}'
  commit config
  git checkout -qb story/s01-a
  lines vitest.config.ts 'export default {' '  test: {' '    coverage: {' \
    '      thresholds: { lines: 60, branches: 90 },' '    },' '  },' '};'
  lines .coveragerc '[report]' 'fail_under = 70'
  lines pyproject.toml '[tool.coverage.report]' 'show_missing = true'
  lines tsconfig.build.json '{' '  "compilerOptions": {' '    "strict": false' '  }' '}'
  lines src/app.ts 'export function a() {' '  try {' '    run();' '  } catch (e) {}' \
    '  try {' '    run();' '  } catch (e) {' '    log(e);' '  }' '}'
  lines app/load.py 'def load():' '    try:' '        return open("x").read()' '    except ValueError:' '        pass'
  commit story
  guard s01-a main
  [ "$code" -eq 1 ] || fail "exit $code"
  flagged 'src/app.ts:4: empty-catch:'
  flagged 'app/load.py:4: empty-catch:'
  flagged 'tsconfig.build.json:3: strict-off:'
  flagged 'vitest.config.ts:4: threshold-lowered: lines 80 → 60'
  flagged '.coveragerc:2: threshold-lowered: fail_under 90 → 70'
  flagged 'pyproject.toml:1: threshold-removed: fail_under 85'
  not_flagged 'branches'
  not_flagged 'src/app.ts:7'
  [ "$(grep -c . <<< "$out")" -eq 6 ] || fail "expected six flags, got: $out"
}

test_review_runs_the_floor_guard() {
  local skill="$METHOD/skills/review-antihallu/SKILL.md" tpl="$METHOD/templates/review.md"
  require_file "$skill"
  contains "$skill" '*Floor.* Run `po-gate floor-guard <id> <Target branch>` from the worktree'
  contains "$skill" 'each printed line is a flag: justified in the plan → **minor**, otherwise **major**'
  contains "$skill" 'a deleted test file the plan does not justify → **critical**'
  contains "$skill" 'the guard could not verify, which is never clean: the review is blocked'
  contains "$skill" '`Failure cause:`'
  require_file "$tpl"
  contains "$tpl" '- [ ] Floor: `po-gate floor-guard <id> <Target branch>` → <0 nothing lowered | 1 each flag graded, listed under Findings | 2 review blocked>'
}
