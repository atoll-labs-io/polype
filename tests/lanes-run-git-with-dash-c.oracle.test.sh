#!/usr/bin/env bash
# s210 — the oracle of the story. Two criteria are read by a script: po-lint refuses a `cd` that
# precedes git anywhere in method/, and no ceiling of method/word-budget rises. The Law 4 wording
# speaks to a model and is judged in review.

S210_TMP="$(mktemp -d)"
trap 'rm -rf "$S210_TMP"' EXIT

# A copy of method/ whose word ceilings cannot be what fails: the lines added below add words.
s210_copy() {
  local dir
  dir="$(mktemp -d "$S210_TMP/XXXXXX")"
  cp -r "$METHOD" "$dir/method"
  sed -i -E 's/^([^#[:space:]]+[[:space:]]+)[0-9]+/\1999999/' "$dir/method/word-budget"
  printf '%s' "$dir/method"
}

s210_lint() { S210_RC=0; S210_OUT="$(bash "$ROOT/bin/po-lint" "$@" 2>&1)" || S210_RC=$?; }

# s210_append <method> <file under method/> <line>: appends the line, prints its number.
s210_append() {
  printf '%s\n' "$3" >> "$1/$2"
  grep -c '' "$1/$2"
}

test_no_cd_before_git_in_method() {
  local m n1 n2 n3 n4 count
  require_file "$ROOT/bin/po-lint"

  s210_lint
  ! grep -qF '[cd-git]' <<< "$S210_OUT" || fail "method/ has a cd before git: $S210_OUT"

  # One breach per place a cd precedes git: a command brief, a skill, a hook, a template.
  m="$(s210_copy)"
  n1="$(s210_append "$m" commands/po-ship.md 'Then run `cd <path> && git status --porcelain`.')"
  n2="$(s210_append "$m" skills/diagnostic/SKILL.md 'Run `cd "$W"; git log -1` first.')"
  n3="$(s210_append "$m" hooks/po-gate.sh 'head="$(cd "$top" && git rev-parse HEAD)"')"
  n4="$(s210_append "$m" templates/plan.md 'Check with `cd <worktree> && po-run x && git diff`.')"
  s210_lint "$m"
  [ "$S210_RC" -ne 0 ] || fail "po-lint exited 0 on four cd-before-git lines: $S210_OUT"
  grep -qF "commands/po-ship.md:$n1: [cd-git]" <<< "$S210_OUT" || fail "po-ship.md:$n1 not named: $S210_OUT"
  grep -qF "skills/diagnostic/SKILL.md:$n2: [cd-git]" <<< "$S210_OUT" || fail "SKILL.md:$n2 not named: $S210_OUT"
  grep -qF "hooks/po-gate.sh:$n3: [cd-git]" <<< "$S210_OUT" || fail "po-gate.sh:$n3 not named: $S210_OUT"
  grep -qF "templates/plan.md:$n4: [cd-git]" <<< "$S210_OUT" || fail "plan.md:$n4 not named: $S210_OUT"
  count="$(grep -c '\[cd-git\]' <<< "$S210_OUT" || true)"
  [ "$count" = 4 ] || fail "expected four cd-git breaches, po-lint said: $S210_OUT"

  # Negative controls: git -C, a cd before another command, and prose naming both stay green.
  m="$(s210_copy)"
  s210_append "$m" commands/po-ship.md 'Run `git -C <path> status` and `cd <path> && po record qa <id>`.' >/dev/null
  s210_append "$m" agents/qa.md 'Run git as `git -C <that path>`, never after a `cd`, every other command after `cd <that path> &&`.' >/dev/null
  s210_lint "$m"
  ! grep -qF '[cd-git]' <<< "$S210_OUT" || fail "the cd-git rule flags legitimate lines: $S210_OUT"
}

test_method_does_not_grow() {
  local target base budget raised=""
  budget="$METHOD/word-budget"
  require_file "$budget"
  target="$(sed -n 's/^Target branch:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*$/\1/p' "$ROOT/AGENTS.local.md" | head -n 1)"
  [ -n "$target" ] || fail "AGENTS.local.md has no Target branch"
  base="$(git -C "$ROOT" merge-base HEAD "origin/$target" 2>/dev/null)" || fail "no merge base with origin/$target"
  git -C "$ROOT" show "$base:method/word-budget" > "$S210_TMP/base-budget" || fail "no word-budget at $base"
  raised="$(awk '
    NR == FNR { if ($0 !~ /^#/ && NF >= 2) old[$1] = $2; next }
    $0 ~ /^#/ || NF < 2 { next }
    !($1 in old) { print $1 " (new line)"; next }
    $2 + 0 > old[$1] + 0 { print $1 " " old[$1] " -> " $2 }
  ' "$S210_TMP/base-budget" "$budget")"
  [ -z "$raised" ] || fail "ceilings raised since $base: $raised"
  s210_lint
  ! grep -qF '[budget]' <<< "$S210_OUT" || fail "method/ is over its word budget: $S210_OUT"
}
