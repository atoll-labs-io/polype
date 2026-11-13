#!/usr/bin/env bash
# s174 — the oracle of the story: `po state`, rebuilt on one project context, moves no field
# (#249), and a lane whose story landed on the target branch reports `ship` whatever its review (#248).

PO="${PO:-${CARGO_TARGET_DIR:-$ROOT/po/target}/release/po}"

# The fixture builders of s164's oracle, loaded inside a test only, so its tests are not listed here.
s164_fixtures() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/state-as-json.oracle.test.sh"
  need_po
}

# OUT with what may differ between two runs of one fixture replaced: the fixture's own commit, the
# method version the installer stamps, the scratch path. Fields later stories of M21 compute are
# dropped, and lanes are sorted, since git lists worktrees in no promised order.
normalised() {
  jq -S --arg commit "$(git -C "$F" rev-parse --short=7 main 2>/dev/null)" --arg version "$(shipped_version)" \
    --arg scratch "$SCRATCH" '
    del(.ready, .held, .session, .bounds, .shipped)
    | if .lanes then .lanes |= (map(del(.next)) | sort_by(.story)) else . end
    | walk(if type == "string" then
             (if . == $commit and $commit != "" then "<commit>" elif . == $version then "<version>" else . end)
             | gsub($scratch; "<scratch>")
           else . end)' <<< "$OUT"
}

# same <label> <expected JSON>: po state, normalised, is exactly the object Target branch's po printed.
same() {
  local got want
  got="$(normalised)" || fail "$1: po state did not print JSON: $OUT"
  want="$(jq -S . <<< "$2")"
  [ "$got" = "$want" ] || fail "$1: po state moved a field.
      expected: $(jq -c . <<< "$want")
      got:      $(jq -c . <<< "$got")"
}

# Expected objects: the output of the po of Target branch (de387bb) on these fixtures, normalised.
test_state_output_does_not_move() {
  s164_fixtures
  fixture
  lane s01-worktree-only
  lane s02-plan-draft
  plan_in s02-plan-draft no
  printf 'Technical choice: waiting for a human\n' >> "$W/docs/plans/s02-plan-draft.md"
  lane s03-plan-approved
  plan_in s03-plan-approved yes
  lane s04-code-recorded
  plan_in s04-code-recorded yes
  code_in s04-code-recorded
  record_in s04-code-recorded
  lane s05-review-blocked
  plan_in s05-review-blocked yes
  code_in s05-review-blocked
  record_in s05-review-blocked
  review_in s05-review-blocked no
  lane s06-review-passed
  plan_in s06-review-passed yes
  code_in s06-review-passed
  record_in s06-review-passed
  review_in s06-review-passed yes
  lane s07-landed
  plan_in s07-landed yes
  code_in s07-landed
  record_in s07-landed
  review_in s07-landed yes
  git -C "$F" commit -q --allow-empty -m 's07-landed: Landed'
  git -C "$F" worktree add -q -b scratch-branch "$F/.worktrees/stray" main
  decision "$F/.polype/inbox" d-0001 pending
  decision "$F/.polype/inbox" d-0002 answered
  decision "$F/.polype/inbox" d-0003 pending
  printf '{not json\n' > "$F/.polype/inbox/d-0004.json"

  local lanes='[
    {"story": "s01-worktree-only", "stage": "research", "blocked_by": null},
    {"story": "s02-plan-draft", "stage": "plan", "blocked_by": "technical-choice"},
    {"story": "s03-plan-approved", "stage": "execute", "blocked_by": null},
    {"story": "s04-code-recorded", "stage": "review", "blocked_by": null},
    {"story": "s05-review-blocked", "stage": "review", "blocked_by": null},
    {"story": "s06-review-passed", "stage": "ship", "blocked_by": null},
    {"story": "s07-landed", "stage": "ship", "blocked_by": null}]'

  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  same "every setting present" '{
    "contract": 1, "project": "project", "commit": "<commit>", "method_version": "<version>",
    "framing": {"stage": "done", "next": null}, "milestone": {"id": "M1", "stories": 7, "shipped": 1},
    "waiting": ["d-0001", "d-0003"], "lanes": '"$lanes"',
    "warnings": [
      {"code": "orphan-worktree", "path": ".worktrees/stray", "branch": "scratch-branch"},
      {"code": "unreadable-decision", "path": "<scratch>/project/.polype/inbox/d-0004.json"}]}'

  po_in "$F/.worktrees/s03-plan-approved" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS inside a lane: $OUT"
  same "run from a lane" '{
    "contract": 1, "project": "project", "commit": "<commit>", "method_version": "<version>",
    "framing": {"stage": "done", "next": null}, "milestone": {"id": "M1", "stories": 7, "shipped": 1},
    "waiting": ["d-0001", "d-0003"], "lanes": '"$lanes"',
    "warnings": [
      {"code": "orphan-worktree", "path": ".worktrees/stray", "branch": "scratch-branch"},
      {"code": "unreadable-decision", "path": "<scratch>/project/.polype/inbox/d-0004.json"}]}'

  sed -i '/^Decision inbox:/d; /^Max attempts:/d; /^Merge mode:/d; /^Entry mode:/d' "$F/AGENTS.local.md"
  printf '0.0.1-other\n' > "$F/.polype/version"
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS with settings missing: $OUT"
  same "settings missing, another version" '{
    "contract": 1, "project": "project", "commit": "<commit>", "method_version": "0.0.1-other",
    "framing": null, "milestone": {"id": "M1", "stories": 7, "shipped": 1},
    "waiting": null, "lanes": '"$lanes"',
    "warnings": [
      {"code": "method-version-mismatch", "po": "<version>", "project": "0.0.1-other"},
      {"code": "missing-setting", "setting": "Entry mode"},
      {"code": "missing-setting", "setting": "Max attempts"},
      {"code": "missing-setting", "setting": "Merge mode"},
      {"code": "orphan-worktree", "path": ".worktrees/stray", "branch": "scratch-branch"},
      {"code": "missing-setting", "setting": "Decision inbox"}]}'

  sed -i '/^Target branch:/d' "$F/AGENTS.local.md"
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS without Target branch: $OUT"
  same "no target branch" '{
    "contract": 1, "project": "project", "commit": null, "method_version": "0.0.1-other",
    "framing": null, "milestone": null, "waiting": null, "lanes": null,
    "warnings": [
      {"code": "method-version-mismatch", "po": "<version>", "project": "0.0.1-other"},
      {"code": "missing-setting", "setting": "Target branch"},
      {"code": "missing-setting", "setting": "Decision inbox"}]}'
}

test_landed_lane_reports_ship_whatever_its_review() {
  s164_fixtures
  fixture
  # Landed with no review at all: the gates alone would say review.
  lane s04-code-recorded
  plan_in s04-code-recorded yes
  code_in s04-code-recorded
  record_in s04-code-recorded
  # Landed, then a commit after its passing review: ship-allowed no longer holds on this code.
  lane s07-landed
  plan_in s07-landed yes
  code_in s07-landed
  record_in s07-landed
  review_in s07-landed yes
  echo fix > "$W/src/fix.txt"
  git -C "$W" add -A
  git -C "$W" commit -qm 's07-landed: fix after the landing'
  # Not landed, with the same review on stale code: never ship.
  lane s06-review-passed
  plan_in s06-review-passed yes
  code_in s06-review-passed
  record_in s06-review-passed
  review_in s06-review-passed yes
  echo late > "$W/src/late.txt"
  git -C "$W" add -A
  git -C "$W" commit -qm 's06-review-passed: late commit'
  git -C "$F" commit -q --allow-empty -m 's04-code-recorded: Landed'
  git -C "$F" commit -q --allow-empty -m 's07-landed: Landed'

  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  local id stage got bad=""
  while read -r id stage; do
    got="$(jq -r --arg id "$id" '[.lanes[] | select(.story == $id) | .stage] | if length == 1 then .[0] else "missing" end' <<< "$OUT")"
    [ "$got" = "$stage" ] || bad+="$id: $got instead of $stage; "
  done <<'EOF'
s04-code-recorded ship
s07-landed ship
EOF
  [ -z "$bad" ] || fail "a landed lane does not report ship: $bad"
  got="$(jq -r '[.lanes[] | select(.story == "s06-review-passed") | .stage] | .[0] // "missing"' <<< "$OUT")"
  [ "$got" != ship ] && [ "$got" != missing ] || fail "s06-review-passed is not landed and its review is stale, yet: $got"
}
