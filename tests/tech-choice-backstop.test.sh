#!/usr/bin/env bash
# s111 — a short-track plan sent back keeps its marker, and the tests that guard the
# marker and two stories-framing rules fail when those rules are deleted.

MARKER='Technical choice: waiting for a human'
MUTANTS="$(mktemp -d)"
trap 'rm -rf "$MUTANTS"' EXIT

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

mutant() {
  local dir
  dir="$(mktemp -d "$MUTANTS/XXXXXX")"
  cp -r "$METHOD" "$dir/method"
  echo "$dir/method"
}

# Sources a test file against the given method tree and runs one test; status is the test's.
run_against() {
  ( METHOD="$1"; CMDS="$1/commands"; source "$2"; "$3" ) >/dev/null 2>&1
}

test_flow_plan_sent_back_keeps_the_marker() {
  local flow="$METHOD/commands/po-flow.md" s
  s="$(section_of "$flow" 'Approval')"
  local want
  for want in "$MARKER" 'validated: no' 'status: proposed' 'Ranking the options' 'templates/adr.md' \
      '/po-research <id>' 'whatever `Plan validation` says' 'in their ranked order'; do
    holds "$s" "$want" 'po-flow Approval'
  done
  local m_at a_at
  m_at="$(grep -nF -- "$MARKER" <<< "$s" | head -1 | cut -d: -f1)"
  a_at="$(grep -nF -- '- `autonomous`' <<< "$s" | head -1 | cut -d: -f1)"
  [ -n "$m_at" ] && [ -n "$a_at" ] || fail "po-flow Approval lost the marker or the autonomous bullet"
  [ "$m_at" -lt "$a_at" ] || fail "po-flow Approval puts the autonomous bullet before the marker"
  settings_read_by "$flow" | grep -qxF 'ADR directory' || fail "po-flow does not list ADR directory in Reads settings"
  holds "$(section_of "$METHOD/commands/po-plan.md" 'Checks first')" "$MARKER" 'po-plan Checks first'
}

test_approval_test_bites_in_its_section() {
  local t="$ROOT/tests/escalation-contract.test.sh" name=test_plan_with_a_tech_choice_waits_for_a_human
  run_against "$METHOD" "$t" "$name" || fail "the test fails on the real method"
  local m f before after
  m="$(mutant)"; f="$m/commands/po-plan.md"
  before="$(wc -l < "$f")"
  grep -v -e '^A plan holding the line `.*is settled with the person first' "$f" > "$f.new" && mv "$f.new" "$f"
  after="$(wc -l < "$f")"
  [ $((before - after)) = 1 ] || fail "mutation removed $((before - after)) lines, expected 1"
  if run_against "$m" "$t" "$name"; then fail "the test still passes without the Approval paragraph"; fi
}

test_stories_review_rules_bite() {
  local t="$ROOT/tests/conversational-framing.test.sh" name=test_stories_review_surfaces_criticals_only
  local m
  m="$(mutant)"
  python3 -I - "$m/commands/po-stories-review.md" "$m/commands/po-stories.md" <<'PY' || fail "mutation did not apply"
import sys
a,b=sys.argv[1:]
s=open(a).read()
assert s.count("never changed: a verdict is the subagent's")==1
i=s.index("never changed: a verdict is the subagent's")
# drop the whole sentence holding the phrase
start=s.rfind(". ",0,i)+1
end=s.index("owner's.",i)+len("owner's.")
open(a,"w").write(s[:start]+s[end:])
s=open(b).read()
i=s.index("A story with a `story/<id>` branch")
end=s.index("it is not reopened here.",i)+len("it is not reopened here.")
open(b,"w").write(s[:i].rstrip(" ")+" "+s[end:].lstrip(" ") if s[end:].strip() else s[:i].rstrip(" ")+s[end:])
PY
  ! grep -qF "never changed: a verdict is the subagent's" "$m/commands/po-stories-review.md" || fail "review mutant keeps its phrase"
  grep -qF 'Stories ready:' "$m/commands/po-stories-review.md" || fail "review mutant lost more than the sentence"
  ! grep -qF 'has already started' "$m/commands/po-stories.md" || fail "stories mutant keeps its phrase"
  grep -qF 'Each story keeps its id.' "$m/commands/po-stories.md" || fail "stories mutant lost 'keeps its id'"
  local review_only stories_only
  review_only="$(mutant)"; stories_only="$(mutant)"
  cp "$m/commands/po-stories-review.md" "$review_only/commands/"
  cp "$m/commands/po-stories.md" "$stories_only/commands/"
  run_against "$METHOD" "$t" "$name" || fail "the test fails on the real method"
  if run_against "$review_only" "$t" "$name"; then fail "passes without the verdict rule"; fi
  if run_against "$stories_only" "$t" "$name"; then fail "passes without the already-started rule"; fi
}
