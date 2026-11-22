#!/usr/bin/env bash
# s13 — brief command and template.

BRIEF="$METHOD/commands/po-brief.md"
BRIEF_TEMPLATE="$METHOD/templates/brief.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_brief_persists_between_sessions() {
  require_file "$BRIEF_TEMPLATE"
  frontmatter "$BRIEF_TEMPLATE" | grep -qx 'status: interviewing' || fail "brief template does not start with status: interviewing"
}

# s22 — the blocking checks of ## Finish run before anything is written as approved.
test_brief_checks_before_writing_approved() {
  local section checks approved
  section=$(section_of "$BRIEF" 'Finish')
  checks=$(grep -n -m1 -F -- 'git status --porcelain' <<< "$section" | cut -d: -f1)
  [ -n "$checks" ] || fail "po-brief.md Finish does not check git status --porcelain"
  grep -qF -- '`Target branch`' <<< "$section" || fail "po-brief.md Finish does not check the current branch"
  approved=$(grep -n -m1 -F -- 'set `status: approved`' <<< "$section" | cut -d: -f1)
  [ -n "$approved" ] || fail "po-brief.md Finish never writes status: approved"
  [ "$checks" -lt "$approved" ] || fail "po-brief.md writes status: approved before its blocking checks"
  grep -qF -- 'leaves `docs/brief.md` at `status: interviewing`' <<< "$section" \
    || fail "po-brief.md does not say an interruption leaves the brief at status: interviewing"
}
