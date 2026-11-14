#!/usr/bin/env bash
# s170 — the oracle of the story: `po state` reports, for each shipped story, the trust signals read
# from the files the pipeline already writes, and `null` for what it cannot read (#205).

# The fixture builders of s164's oracle, loaded inside a test only, so its tests are not listed here.
s164_fixtures() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/state-as-json.oracle.test.sh"
  need_po
}

HEX=0123456789abcdef0123456789abcdef01234567

# trust_project: the s164 fixture with M1 (s01, s02) shipped whole and M2 current (s03, s04 shipped,
# s05 not), each shipped story landed by one commit `<id>: Landed` holding its plan, review and record.
trust_project() {
  STORIES=""
  fixture
  {
    printf '# Stories\n\n## M1 — Earlier\n\n'
    printf '### %s — %s\n- **Complexité** : 1\n- **Surface** : command\n\n' s01-old-odd 'Old odd' s02-old-bare 'Old bare'
    printf '## M2 — Current\n\n'
    printf '### %s — %s\n- **Complexité** : 1\n- **Surface** : command\n\n' \
      s03-now-full 'Now full' s04-now-flow 'Now flow' s05-not-yet 'Not yet'
  } > "$F/docs/stories.md"
  git -C "$F" add -A
  git -C "$F" commit -qm "docs: stories"

  # Unreadable values everywhere po could be tempted to guess one.
  ship s01-old-odd "$(printf -- '---\nvalidated: yes\ntrack: sideways\n---\n# Plan — s01-old-odd')" "$(cat <<'EOF'
# Review — s01-old-odd

Method version:

Review status: complete
Fix loop: two

## Tests
- Oracle: `po-gate oracle-intact s01-old-odd` → exit 0
  po-gate: s01-old-odd has no oracle: its plan has no ## Acceptance tests section

## Findings
none

Max severity: severe
Ship allowed: yes
EOF
)" "$(printf '## Runs\n\n| Check | Command | Exit | Tree | Time (UTC) |\n| --- | --- | --- | --- | --- |\n| Unit suite | `x` | 0 | %s | yesterday |' "$HEX")"

  ship s02-old-bare - - -

  # A loop-0 review then a fix run's, as po record writes them; the fix run's answer echoes an Oracle line.
  ship s03-now-full "$(printf -- '---\nvalidated: yes\n---\n# Plan — s03-now-full')" "$(cat <<'EOF'
# Review — s03-now-full

[Story](../stories.md)

Method version: 0.1.9

Review status: complete
Fix loop: 0

## Tests
- Oracle: `po-gate oracle-intact s03-now-full` → exit 1
  tests/now.oracle.test.sh: changed without a row in ## Oracle changes

## Findings
- critical — src/a.txt:1 — broken

## Not verified
- one thing

Max severity: critical
Ship allowed: no

Method version: 0.2.0

Review status: complete
Fix loop: 1

## Tests
- Oracle: `po-gate oracle-intact s03-now-full` → exit 0
  tests/now.oracle.test.sh: changed, logged in ## Oracle changes — fixture only — the old one proved nothing
  po-gate: 1 logged oracle change(s) of s03-now-full to judge
- Oracle: `po-gate oracle-intact s03-now-full` → exit 0

## Findings
- major — src/a.txt:2 — left for later

## Not verified
- first thing
  - a detail of the first thing
- second thing
- third thing

Max severity: major
Ship allowed: yes
EOF
)" "$(printf '%s\n' "Tree: $HEX" '' 'Verification status: complete' '' '## Runs' '' \
      '| Check | Command | Exit | Tree | Time (UTC) |' '| --- | --- | --- | --- | --- |' \
      "| Unit suite | \`bash tests/run.sh\` | 1 | $HEX | 2026-11-14T10:00:30Z (30s) |" \
      "| Type check | \`a | b\` | 0 | $HEX | 2026-11-14T10:05:00Z (10s) |" \
      "| Unit suite | \`bash tests/run.sh\` | 0 | $HEX | 2026-11-14T10:20:00Z (25s) |")"

  # A review written before po record stamped it, and a record whose rows carry no duration.
  ship s04-now-flow "$(printf -- '---\ntrack: flow\nvalidated: yes\n---\n# Plan (short track) — s04-now-flow')" "$(cat <<'EOF'
# Review — s04-now-flow

Review status: complete
Fix loop: 0

## Tests
- [x] Oracle: `po-gate oracle-intact s04-now-flow` → exit 0 (intact)

## Findings
none

## Not verified
none

Max severity: minor
Ship allowed: yes
EOF
)" "$(printf '%s\n' '## Runs' '' '| Check | Command | Exit | Tree | Time (UTC) |' '| --- | --- | --- | --- | --- |' \
      "| Unit suite | \`x\` | 0 | $HEX | 2026-11-14T09:00:00Z |" \
      "| Unit suite | \`x\` | 0 | $HEX | 2026-11-14T09:30:00Z |")"
}

# ship <id> <plan|-> <review|-> <record|->: one commit on main titled `<id>: Landed` holding those files.
ship() {
  mkdir -p "$F/docs/plans" "$F/docs/reviews" "$F/docs/verif"
  [ "$2" = - ] || printf '%s\n' "$2" > "$F/docs/plans/$1.md"
  [ "$3" = - ] || printf '%s\n' "$3" > "$F/docs/reviews/$1.md"
  [ "$4" = - ] || printf '%s\n' "$4" > "$F/docs/verif/$1.md"
  echo "$1" > "$F/src/$1.txt"
  git -C "$F" add -A
  git -C "$F" commit -qm "$1: Landed"
}

landed() { git -C "$F" rev-parse "$1" ":/^$2: Landed"; }

# trust_of <id> <jq filter>: the filter applied to the trust object of shipped story <id> in OUT.
trust_of() { jq -cS --arg id "$1" "[.shipped[]? | select(.story == \$id)] | first | .trust | $2" <<< "$OUT"; }

# trust_is <id> <jq filter> <expected JSON>
trust_is() {
  local got
  got="$(trust_of "$1" "$2")"
  [ "$got" = "$(jq -cS . <<< "$3")" ] || fail "$1 $2: $got instead of $(jq -cS . <<< "$3")"
}

test_shipped_stories_carry_trust() {
  s164_fixtures
  trust_project

  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  one_object "po state"
  jq -e '[.shipped[].story] == ["s03-now-full", "s04-now-flow"]' <<< "$OUT" >/dev/null \
    || fail "shipped is not the stories shipped in the current milestone, in file order: $(jq -c .shipped <<< "$OUT")"
  jq -e --arg c "$(landed --short=7 s03-now-full)" '.shipped[0].commit == $c' <<< "$OUT" >/dev/null \
    || fail "shipped[].commit is not the short landed commit: $(jq -c .shipped[0] <<< "$OUT")"
  jq -e 'all(.shipped[]; .trust | keys == (["checks", "cost_usd", "duration_s", "fix_loops", "max_severity",
      "method_version", "not_verified", "oracle", "track"]))' <<< "$OUT" >/dev/null \
    || fail "a trust object does not carry exactly the fields of the contract: $(jq -c .shipped <<< "$OUT")"
  trust_is s03-now-full '{oracle, fix_loops, max_severity, not_verified, method_version, track}' \
    '{"oracle": "changed-with-reason", "fix_loops": 1, "max_severity": "major", "not_verified": 3,
      "method_version": "0.2.0", "track": "full"}'
  trust_is s04-now-flow '{fix_loops, max_severity, not_verified, track}' \
    '{"fix_loops": 0, "max_severity": "minor", "not_verified": 0, "track": "flow"}'

  local current
  current="$(trust_of s03-now-full .)"
  po_in "$F" state --all
  [ "$STATUS" -eq 0 ] || fail "po state --all exited $STATUS: $OUT"
  one_object "po state --all"
  jq -e '[.shipped[].story] == ["s01-old-odd", "s02-old-bare", "s03-now-full", "s04-now-flow"]' <<< "$OUT" >/dev/null \
    || fail "--all does not give every shipped story, in file order: $(jq -c '[.shipped[].story]' <<< "$OUT")"
  [ "$(trust_of s03-now-full .)" = "$current" ] || fail "--all reads s03 otherwise than po state: $(trust_of s03-now-full .)"
}

test_unknown_is_null_never_guessed() {
  s164_fixtures
  trust_project

  po_in "$F" state --all
  [ "$STATUS" -eq 0 ] || fail "po state --all exited $STATUS on old or odd reports: $OUT"
  one_object "po state --all"
  trust_is s04-now-flow '{method_version, oracle}' '{"method_version": null, "oracle": null}'
  trust_is s01-old-odd '{method_version, fix_loops, max_severity, not_verified, track, oracle}' \
    '{"method_version": null, "fix_loops": null, "max_severity": null, "not_verified": null, "track": null,
      "oracle": "none"}'
  trust_is s01-old-odd '.duration_s' 'null'
  trust_is s02-old-bare '.' '{"checks": null, "oracle": null, "fix_loops": null, "max_severity": null,
    "not_verified": null, "method_version": null, "track": null, "duration_s": null, "cost_usd": null}'
}

test_checks_are_read_only_on_request() {
  s164_fixtures
  trust_project
  git -C "$F" remote add origin https://github.com/acme/project.git
  local s01 s03 s04 stubs="$SCRATCH/stubs" calls="$SCRATCH/gh-calls"
  s01="$(landed --verify s01-old-odd)" s03="$(landed --verify s03-now-full)" s04="$(landed --verify s04-now-flow)"
  mkdir -p "$stubs"
  : > "$calls"
  cat > "$SCRATCH/forge" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$calls"
case "\$*" in
  *$s03*) echo '{"total_count": 2, "check_runs": [{"status": "completed", "conclusion": "success"}, {"status": "completed", "conclusion": "skipped"}]}' ;;
  *$s04*) echo '{"total_count": 2, "check_runs": [{"status": "completed", "conclusion": "success"}, {"status": "completed", "conclusion": "failure"}]}' ;;
  *$s01*) echo '{"total_count": 0, "check_runs": []}' ;;
  *) exit 1 ;;
esac
EOF
  chmod +x "$SCRATCH/forge"
  cp "$SCRATCH/forge" "$stubs/gh"

  STATUS=0
  OUT="$(cd "$F" && PO_GH="$SCRATCH/forge" PATH="$stubs:$PATH" "$PO" state --all 2>/dev/null)" || STATUS=$?
  [ "$STATUS" -eq 0 ] || fail "po state --all exited $STATUS: $OUT"
  jq -e 'all(.shipped[]; .trust.checks == null)' <<< "$OUT" >/dev/null \
    || fail "checks is not null without --remote: $(jq -c '[.shipped[].trust.checks]' <<< "$OUT")"
  [ ! -s "$calls" ] || fail "po state asked the forge without --remote: $(cat "$calls")"

  STATUS=0
  OUT="$(cd "$F" && PO_GH="$SCRATCH/forge" "$PO" state --all --remote 2>/dev/null)" || STATUS=$?
  [ "$STATUS" -eq 0 ] || fail "po state --all --remote exited $STATUS: $OUT"
  one_object "po state --all --remote"
  trust_is s03-now-full .checks '"passed"'
  trust_is s04-now-flow .checks '"failed"'
  trust_is s01-old-odd .checks '"none"'
  trust_is s02-old-bare .checks 'null'
  grep -qF "repos/acme/project/commits/$s03" "$calls" || fail "the forge was not asked about the landed commit of s03: $(cat "$calls")"
  if grep -vqF -- '--hostname github.com' "$calls"; then fail "a forge call is not pinned to github.com: $(cat "$calls")"; fi
}

test_duration_comes_from_the_record() {
  s164_fixtures
  trust_project
  local run="$SCRATCH/run" row n
  mkdir -p "$run"
  git -C "$run" init -q -b main
  git -C "$run" config user.email test@example.com
  git -C "$run" config user.name test
  echo x > "$run/a.txt"
  git -C "$run" add -A
  git -C "$run" commit -qm init
  git -C "$run" checkout -qb story/s09-run
  (cd "$run" && bash "$METHOD/hooks/po-run.sh" --story s09-run --label 'Unit suite' -- 'sleep 1') \
    || fail "po-run failed on a passing check"
  row="$(grep '^| Unit suite |' "$run/docs/verif/s09-run.md")"
  [[ "$row" =~ \|\ [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\ \(([0-9]+)s\)\ \|$ ]] \
    || fail "the row of the check carries no duration after its UTC time: $row"
  n="${BASH_REMATCH[1]}"
  [ "$n" -ge 1 ] && [ "$n" -le 30 ] || fail "a check sleeping one second was noted as lasting ${n}s: $row"

  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  trust_is s03-now-full .duration_s '1200'
  trust_is s04-now-flow .duration_s 'null'
  jq -e 'all(.shipped[]; .trust | has("cost_usd") and .cost_usd == null)' <<< "$OUT" >/dev/null \
    || fail "cost_usd is not null while no file carries it: $(jq -c '[.shipped[].trust.cost_usd]' <<< "$OUT")"
}
