#!/usr/bin/env bash
# s101 — framing approved in conversation, one item per question (ADR-0074).

CMDS="$METHOD/commands"
FIVE="po-brief po-prd po-stories po-architect po-design-system"
SIX="$FIVE po-stories-review"

ANSWERS='answers Approve / Change / Set aside'
SHORT='The summary aims short and grows when the subject needs it: no fact needed to decide is cut to keep it short.'
WRITTEN='Each item is written only once approved, and the commit asks for no rereading.'

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

test_framing_never_asks_to_read_a_file() {
  local f phrase
  for f in $SIX; do
    require_file "$CMDS/$f.md"
    for phrase in 'end to end' 'grouped AskUserQuestion' 'Show the whole'; do
      ! grep -qF -- "$phrase" "$CMDS/$f.md" || fail "$f.md still says: $phrase"
    done
    [ "$f" = po-brief ] && continue
    ! grep -qF -- 'read the whole' "$CMDS/$f.md" || fail "$f.md still says: read the whole"
  done
  contains "$CMDS/po-brief.md" 'never ask for the file to be read'
  [ -z "$(grep -F 'read the whole' "$CMDS/po-brief.md" | grep -vF 'never ask for the file to be read')" ] \
    || fail "po-brief.md asks for the whole brief to be read outside its bridge line"
}

test_one_item_per_question() {
  local f
  for f in $FIVE; do
    contains "$CMDS/$f.md" "$ANSWERS"
    contains "$CMDS/$f.md" "$WRITTEN"
  done
  contains "$CMDS/po-brief.md" 'one section per question'
  contains "$CMDS/po-prd.md" 'one section per question'
  contains "$CMDS/po-stories.md" 'one story per question'
  contains "$CMDS/po-design-system.md" 'one token group, one contrast fix or one gap per question'
  grep -qF -- 'one ADR per question, then the conventions as one item, then `docs/architecture.md` summarised as one item' \
    <<< "$(section_of "$CMDS/po-architect.md" 'Approval and commit')" \
    || fail "po-architect.md does not put its items one per question in Approval and commit"
}

test_summary_short_but_complete() {
  local f
  for f in $SIX; do contains "$CMDS/$f.md" "$SHORT"; done
  contains "$CMDS/po-brief.md" 'what the section settles and why'
  contains "$CMDS/po-prd.md" 'what the section settles and why'
  contains "$CMDS/po-stories.md" 'what the story delivers, why, and its acceptance criteria'
  contains "$CMDS/po-architect.md" 'what the ADR decides, why, and the options turned down'
}

test_stories_review_surfaces_criticals_only() {
  local review="$CMDS/po-stories-review.md" stories="$CMDS/po-stories.md"
  needs_tool "$review" AskUserQuestion
  contains "$review" 'answers Fix / Accept the risk / Set the story aside'
  contains "$review" 'one critical finding per question'
  contains "$review" 'the finding stays open in the report'
  contains "$review" 'Majors and minors stay in the report and are not asked.'
  contains "$review" 'It never edits the stories.'
  contains "$review" '/po-stories <ids>'
  contains "$stories" 'sent back by `/po-stories-review`'
  contains "$stories" 'keeps its id'
}
