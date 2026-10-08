#!/usr/bin/env bash
# s35 — a lane also carries a story with a screen.

DRIVE="$METHOD/commands/po-drive.md"
DESIGNER="$METHOD/agents/designer.md"

# The body of one `## <heading>` section, heading excluded; `###` subsections stay inside.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

# The skills a subagent preloads, from the `skills:` list of its frontmatter.
skills_of() {
  frontmatter "$1" | awk '/^skills:/ {list=1; next} list && /^  - / {sub(/^  - /, ""); print; next} list {list=0}'
}

test_designer_agent_carries_the_design_contract() {
  require_file "$DESIGNER"
  grep -qx 'name: designer' <<< "$(frontmatter "$DESIGNER")" || fail "designer.md is not named designer"
  skills_of "$DESIGNER" | grep -qx 'design-doctrine' || fail "designer.md does not preload design-doctrine"

  # The contract is read where it lives, not copied into a second version of it.
  local contract; contract=$(section_of "$DESIGNER" 'The contract you carry')
  [ -n "$contract" ] || fail "designer.md has no '## The contract you carry' section"
  holds "$contract" 'You do not restate `/po-design`, you are bound by it' 'the designer contract'
  holds "$contract" 'read `method/commands/po-design.md`' 'the designer contract'

  # The four requirements /po-design imposes on whoever settles a screen.
  holds "$contract" '**Derived or new**' 'the designer contract'
  holds "$contract" 'the screen is derived' 'the designer contract'
  holds "$contract" '**One artefact at most**' 'the designer contract'
  holds "$contract" 'chosen by `Design source`' 'the designer contract'
  holds "$contract" 'python3 -m http.server' 'the designer contract'
  holds "$contract" 'light and dark, desktop and mobile' 'the designer contract'
  holds "$contract" 'Nothing is measured here' 'the designer contract'
  holds "$contract" 'recorded, never invented' 'the designer contract'

  # A skill the project names is read from disk, since a subagent cannot preload it.
  settings_read_by "$DESIGNER" | grep -qx 'Design skill' || fail 'designer.md does not declare it reads `Design skill`'
  contains "$DESIGNER" '`.claude/skills/<Design skill>/SKILL.md`'
  contains "$DESIGNER" 'stop before drawing'
  contains "$DESIGNER" 'You never draw from taste.'
}

test_drive_inserts_design_between_plan_and_execute() {
  require_file "$DRIVE"
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  [ -n "$wave" ] || fail "po-drive.md has no '## A wave' section"

  # The five subagents of a lane, in the order the lane runs them.
  local order; order=$(grep -o 'subagent_type: [a-z]*' <<< "$wave" | sed 's/subagent_type: //' | tr '\n' ' ')
  [ "$order" = "planner designer implementer qa reviewer " ] \
    || fail "expected planner then designer then implementer then qa then reviewer, found: $order"

  # The stage is a dispatch, with the same two arguments as every other lane stage.
  holds "$wave" '**The design stage**, for a story whose text shows a screen: `subagent_type: designer`' 'the wave section'
  holds "$wave" 'the story id and the absolute worktree path' 'the wave section'
  holds "$wave" '`method/agents/designer.md`' 'the wave section'

  # Dispatched, not replayed: a note already on disk is this lane's design.
  holds "$wave" 'no designer is dispatched' 'the wave section'
  # Started whole, like the other stages, or the lanes do not overlap.
  holds "$wave" 'every designer of a wave leaves before any of them is waited on' 'the wave section'

  # A resumed lane still knows the stage exists.
  local resuming; resuming=$(section_of "$DRIVE" 'Resuming')
  [ -n "$resuming" ] || fail "po-drive.md has no '## Resuming' section"
  holds "$resuming" '`docs/designs/<id>/design.md` is absent | the design stage' 'the resuming table'

  settings_read_by "$DRIVE" | grep -qx 'Design source' \
    || fail 'po-drive.md does not declare it reads `Design source`'
}

test_drive_stops_a_screen_lane_without_a_design_system() {
  require_file "$DRIVE"
  local wave; wave=$(section_of "$DRIVE" 'A wave')
  [ -n "$wave" ] || fail "po-drive.md has no '## A wave' section"

  # The stage sits between the plan and the code.
  local planner design implementer
  planner=$(grep -n -F 'subagent_type: planner' <<< "$wave" | cut -d: -f1 || true)
  design=$(grep -n -F '**The design stage**' <<< "$wave" | cut -d: -f1 || true)
  implementer=$(grep -n -F 'subagent_type: implementer' <<< "$wave" | cut -d: -f1 || true)
  [ -n "$design" ] || fail 'the wave section names no design stage'
  { [ "$planner" -lt "$design" ] && [ "$design" -lt "$implementer" ]; } \
    || fail "the design stage must sit between plan ($planner) and implementation ($implementer), found $design"

  # Both of /po-design's own conditions, checked before any designer leaves.
  holds "$wave" '`docs/design-system.md` missing there → the lane stops' 'the wave section'
  holds "$wave" '`Design source` at `—` → the lane stops' 'the wave section'
  holds "$wave" 'which you never choose for them' 'the wave section'

  # Never skipped to keep a lane moving.
  holds "$wave" 'The stage is never skipped' 'the wave section'
  holds "$wave" 'the implementer does not start' 'the wave section'

  # The design a lane produced was read by nobody, and the report says which stories.
  local report; report=$(section_of "$DRIVE" 'Report')
  [ -n "$report" ] || fail "po-drive.md has no '## Report' section"
  holds "$report" 'names every story whose design no human approved' 'the report section'

  # The reasons a lane used to stop at this stage are gone from the whole file.
  local stale
  stale=$(grep -n -F -e 'a command does not run inside a subagent' -e 'no design subagent exists' \
    -e '`/po-design <id>` to run in `<Worktree root><id>`' "$DRIVE" || true)
  [ -z "$stale" ] || fail "po-drive.md still refuses to dispatch a designer: $stale"
}

test_designer_writes_only_in_the_story_design_folder() {
  require_file "$DESIGNER"
  local limits; limits=$(section_of "$DESIGNER" 'Limits')
  [ -n "$limits" ] || fail "designer.md has no '## Limits' section"

  holds "$limits" 'You write under `docs/designs/<id>/` and nowhere else' 'the designer limits'
  holds "$limits" 'No source file, no test file, no commit' 'the designer limits'
  holds "$limits" 'the files stay uncommitted' 'the designer limits'
  holds "$limits" 'never code' 'the designer limits'

  # It prepared no lane and repairs none.
  contains "$DESIGNER" 'Never run `git worktree add`, `switch`, `checkout` or `stash`'
}

test_designer_asks_no_one() {
  require_file "$DESIGNER"
  frontmatter "$DESIGNER" | grep -m1 '^disallowedTools:' | grep -qw AskUserQuestion \
    || fail "designer.md does not disallow AskUserQuestion"
  local asked; asked=$(grep -n -F 'AskUserQuestion' "$DESIGNER" | grep -v ':disallowedTools:' || true)
  [ -z "$asked" ] || fail "designer.md still reaches for a question: $asked"

  local autonomy; autonomy=$(section_of "$DESIGNER" 'You ask no one')
  [ -n "$autonomy" ] || fail "designer.md has no '## You ask no one' section"
  holds "$autonomy" 'you ask no one anything' 'the designer autonomy'

  # The two tie-breaks /po-design puts to a person, settled in the file instead.
  holds "$autonomy" 'take the screen as **new**' 'the designer autonomy'
  holds "$autonomy" "the note's \`## Gaps\`" 'the designer autonomy'
  holds "$autonomy" 'a lane has none' 'the designer autonomy'
  holds "$autonomy" 'ADR-0019' 'the designer autonomy'
  require_file "$ROOT/docs/decisions/ADR-0019-design-en-lane-sans-approbation.md"
}
