#!/usr/bin/env bash
# s14 — stories command and agentic-stories skill.

STORIES="$METHOD/commands/po-stories.md"
SKILL="$METHOD/skills/agentic-stories/SKILL.md"

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_stories_reads_prd_or_brief_by_entry_mode() {
  require_file "$STORIES"
  settings_read_by "$STORIES" | grep -qx 'Entry mode' || fail "po-stories.md does not read \`Entry mode\`"
  contains "$STORIES" '`replace` or `adapt` → the source is `docs/prd.md`'
  contains "$STORIES" 'run /po-prd'
  contains "$STORIES" '`new` → the source is `docs/brief.md`'
  contains "$STORIES" 'run /po-brief'
  contains "$STORIES" '`—` → stop'
}

test_agentic_stories_skill_rejects_technical_layers() {
  local section
  require_file "$SKILL"
  section=$(section_of "$SKILL" 'Vertical slices')
  grep -qF -- 'Never a technical layer: "create the table", "add the endpoint" or "build the service" are not stories.' <<< "$section" \
    || fail "vertical slices do not rule out technical layers"
  grep -qE '^- Bad: ' <<< "$section" || fail "vertical slices lack a Bad: example"
  grep -qE '^- Good: ' <<< "$section" || fail "vertical slices lack a Good: example"
}

test_agentic_stories_skill_requires_owns_and_contracts_first() {
  local section
  require_file "$SKILL"
  section=$(section_of "$SKILL" 'Owns and contracts first')
  grep -qF -- 'Every story declares Owns:' <<< "$section" || fail "stories are not required to declare Owns"
  grep -qF -- 'An interface shared by two stories becomes an earlier story of its own: the contract comes first.' <<< "$section" \
    || fail "shared interfaces are not turned into earlier contract stories"
}

test_stories_split_complexity_five_and_order_dependencies() {
  local section
  require_file "$SKILL"
  contains "$SKILL" 'A 5 is split now'
  contains "$SKILL" 'A 4 names its main risk'
  contains "$SKILL" 'No story depends on a story placed after it.'
  section=$(section_of "$STORIES" 'Before writing')
  grep -qF -- 'Every complexity 5 is split' <<< "$section" || fail "po-stories does not check that every 5 is split"
  grep -qF -- 'no story depends on a story placed after it' <<< "$section" || fail "po-stories does not check dependency order"
}

test_stories_never_revive_the_graveyard() {
  require_file "$SKILL"
  contains "$SKILL" 'Nothing from the graveyard becomes a story'
  contains "$SKILL" 'the equivalent screen of the target'
  grep -qF -- 'no story brings back a graveyard feature' <<< "$(section_of "$STORIES" 'Before writing')" \
    || fail "po-stories does not check the graveyard before writing"
}

# s22 — every source line of ## Checks requires an approved status, and a source
# still being written is refused; the whole-file search this replaces could not tell them apart.
test_stories_requires_an_approved_source_with_a_biting_test() {
  local section sources line
  require_file "$STORIES"
  section=$(section_of "$STORIES" 'Checks')
  sources=$(grep -E 'docs/(prd|brief)\.md' <<< "$section") || true
  [ "$(grep -c . <<< "$sources")" -ge 2 ] || fail "po-stories Checks no longer names both sources"
  while IFS= read -r line; do
    grep -qF -- 'status: approved' <<< "$line" || fail "a source is accepted without status: approved: $line"
  done <<< "$sources"
  grep -qF -- '`status: interviewing`' <<< "$section" || fail "po-stories does not refuse a source still being written"
  grep -qF -- 'is refused like a missing one' <<< "$section" || fail "po-stories does not refuse an unapproved source like a missing one"
}
