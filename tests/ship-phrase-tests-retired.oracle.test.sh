#!/usr/bin/env bash
# s202 — the oracle of the story: the ship, intake and tracker family keeps only the tests that launch a script or
# pin what a script reads, plus the security phrase tests the owner kept as an exception (d-0052). The launch count
# and the empty-file check are s201's own tests, which run on this tree too; this file takes s201's helpers
# unchanged, as docs/harnais.md says.
source <(sed '/^test_/,$d' "$ROOT/tests/routing-phrase-tests-retired.oracle.test.sh")

# The test files of this family that stay, each with the tests it must still define.
S202_KEPT='
ship.test.sh test_ship_can_ask_before_merging
ship-follows-forge.test.sh test_template_defaults_trust_the_gates
short-subject-shipped.test.sh test_short_subject_counts_as_shipped test_short_subject_is_exact test_session_lists_no_short_shipped_story
intake-follow-ups.oracle.test.sh test_redact_follows_the_scan_rule
failing-check-files-an-issue.oracle.test.sh test_intake_passes_through test_sensitive_failure_goes_to_the_person test_failure_files_one_issue test_secrets_are_scrubbed test_same_failure_not_filed_twice test_tracker_values_hold
po-retro.test.sh test_retro_writes_nothing
session-and-gate-checks.test.sh test_ship_gate_needs_review_status test_session_flags_a_technical_choice test_design_system_only_with_a_screen
everything-in-issues.test.sh test_security_goes_to_the_person test_finding_text_never_enters_a_command
intake-issue-becomes-a-story.oracle.test.sh test_security_issue_goes_to_the_person
'

# The security phrases the owner kept inside a function that also checks something else: each file still holds it.
S202_KEPT_PHRASES='
failing-check-files-an-issue.oracle.test.sh|runs with `--sensitive`
intake-issue-becomes-a-story.oracle.test.sh|no issue text enters a shell argument
'

test_contract_tests_stay() {
  local file names name out phrase missing=""
  while read -r file names; do
    [ -n "$file" ] || continue
    [ -f "$ROOT/tests/$file" ] || { missing+="$file (file gone); "; continue; }
    out="$(tests_defined "$ROOT/tests" "$file")"
    for name in $names; do
      grep -qxF "$name" <<< "$out" || missing+="$file:$name; "
    done
  done <<< "$S202_KEPT"
  while IFS='|' read -r file phrase; do
    [ -n "$file" ] || continue
    grep -qF -- "$phrase" "$ROOT/tests/$file" 2>/dev/null || missing+="$file: $phrase; "
  done <<< "$S202_KEPT_PHRASES"
  [ -z "$missing" ] || fail "contract tests gone: $missing"
}
