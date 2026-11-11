#!/usr/bin/env bash
# s152 — the rules of /po-intake the oracle leaves out: a level root, the copy put back,
# pending framing branches counted as citations, and the stops before anything is written.

INTAKE="$METHOD/commands/po-intake.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1" | tr -s '[:space:]' ' '; }
holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_root_brought_level_before_reading() {
  require_file "$INTAKE"
  local c; c="$(section_of "$INTAKE" Checks)"
  holds "$c" 'before reading anything else: `Merge mode: pr` → `git fetch origin` and, in the root, `git merge --ff-only origin/<Target branch>`' "po-intake ## Checks"
  holds "$c" 'A refused fast-forward → stop.' "po-intake ## Checks"
  holds "$c" '`docs/stories.md` differing from `origin/<Target branch>`, or holding an uncommitted change' "po-intake ## Checks"
}

test_refused_review_puts_the_copy_back() {
  require_file "$INTAKE"
  holds "$(section_of "$INTAKE" 'Writing the stories')" 'Copy `docs/stories.md` to `$d/stories.md` first' "po-intake ## Writing the stories"
  holds "$(section_of "$INTAKE" 'The review')" '`Stories ready: no` → put back `$d/stories.md` over `docs/stories.md`' "po-intake ## The review"
}

test_pending_framing_branches_cite_too() {
  require_file "$INTAKE"
  local t; t="$(section_of "$INTAKE" 'The issues to take in')"
  holds "$t" 'of the root **and** of every `origin/framing/intake-*` branch' "po-intake ## The issues to take in"
  holds "$t" 'the local `framing/intake-*` branches' "po-intake ## The issues to take in"
}

test_no_tracker_or_failed_listing_stops() {
  require_file "$INTAKE"
  holds "$(section_of "$INTAKE" Checks)" '`Issue tracker: —` → stop' "po-intake ## Checks"
  holds "$(section_of "$INTAKE" 'The issues to take in')" 'A listing that fails proves nothing, and neither does one that returns 1000 lines, its limit: stop' "po-intake ## The issues to take in"
}
