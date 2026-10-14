#!/usr/bin/env bash
# s128 — story-artefact templates carry their links.

GATE="$METHOD/hooks/po-gate.sh"
RUN="$METHOD/hooks/po-run.sh"
TPL="$METHOD/templates"

# template file -> expected link line
expected_link() {
  case "$1" in
    research) echo '[Story](../stories.md)' ;;
    plan) echo '[Story](../stories.md) · [Research](../research/<id>.md)' ;;
    plan-flow) echo '[Story](../stories.md)' ;;
    review) echo '[Story](../stories.md) · [Plan](../plans/<id>.md) · [Verification](../verif/<id>.md)' ;;
    verification-record) echo '[Story](../stories.md) · [Plan](../plans/<id>.md)' ;;
    qa) echo '[Story](../../stories.md) · [Plan](../../plans/<id>.md)' ;;
  esac
}
TEMPLATES="research plan plan-flow review verification-record qa"

# First non-blank line after the first title line of a template.
link_line() { awk '/^# / && !t {t=1; next} t && NF {print; exit}' "$TPL/$1.md"; }

test_templates_carry_links() {
  local t
  for t in $TEMPLATES; do
    require_file "$TPL/$t.md"
    [ "$(link_line "$t")" = "$(expected_link "$t")" ] || fail "$t.md: link line under the title is wrong: $(link_line "$t")"
    ! grep -qF '[[' "$TPL/$t.md" || fail "$t.md holds a wikilink"
    ! grep -qF '.md#' "$TPL/$t.md" || fail "$t.md holds an anchored link"
  done
  [ "$(head -n 1 "$TPL/plan.md")" = '---' ] || fail "plan.md lost its frontmatter on line 1"
  [ "$(head -n 1 "$TPL/plan-flow.md")" = '---' ] || fail "plan-flow.md lost its frontmatter on line 1"
  contains "$TPL/verification-record.md" 'The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer'"'"'s lines.'
}

# Inserts the template's link line, for story s01-a, under the title of a file.
add_link() {
  local file="$1" line; line="$(link_line "$2" | sed 's/<id>/s01-a/g')"
  awk -v l="$line" '{print} /^# / && !t {t=1; print ""; print l}' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

gate_codes() {
  local g codes=""
  for g in plan-validated ship-allowed verif-current qa-current; do
    bash "$GATE" "$g" s01-a >/dev/null 2>&1 && codes="$codes 0" || codes="$codes $?"
  done
  echo "$codes"
}

test_gates_still_read_artifacts() {
  scratch_repo
  cd "$SCRATCH"
  mkdir -p src docs/plans docs/reviews docs/verif docs/qa/s01-a
  echo 'x' > src/app.txt
  git add -A && git commit -qm init
  git checkout -qb story/s01-a

  printf -- '---\nvalidated: yes\n---\n# Plan — s01-a\n\nBody\n' > docs/plans/s01-a.md
  printf '# Verification — s01-a\n\nTree: pending\n\n## Checks\n| Check | Command | Note |\n| --- | --- | --- |\n| Unit suite | `exit 0` | |\n\nVerification status: complete\n' > docs/verif/s01-a.md
  bash "$RUN" --story s01-a --label "Unit suite" -- 'exit 0'
  git add -A
  local tree; tree="$(git write-tree)"
  awk -v t="$tree" '/^Tree: / {$0 = "Tree: " t} {print}' docs/verif/s01-a.md > docs/verif/s01-a.tmp && mv docs/verif/s01-a.tmp docs/verif/s01-a.md
  printf '# Review — s01-a\n\nReview status: complete\nReviewed tree: %s\nMax severity: minor\nShip allowed: yes\n' "$tree" > docs/reviews/s01-a.md
  printf '# QA — s01-a\n\nTree: %s\nQA status: complete\n' "$tree" > docs/qa/s01-a/report.md
  git add -A && git commit -qm artefacts

  local before after
  before="$(gate_codes)"
  [ "$before" = " 0 0 0 0" ] || fail "fixture artefacts are not all accepted: $before"
  add_link docs/plans/s01-a.md plan
  add_link docs/reviews/s01-a.md review
  add_link docs/verif/s01-a.md verification-record
  add_link docs/qa/s01-a/report.md qa
  git add -A && git commit -qm links
  after="$(gate_codes)"
  [ "$before" = "$after" ] || fail "a link line changed a gate result: '$before' became '$after'"

  sed -i 's/^validated: yes/validated: no/' docs/plans/s01-a.md && git commit -qam refuse
  ! bash "$GATE" plan-validated s01-a >/dev/null 2>&1 || fail "a refused plan with a link line was accepted"
  sed -i 's/^validated: no/validated: yes/' docs/plans/s01-a.md && git commit -qam accept

  bash "$RUN" --story s01-a --label "Unit suite" -- 'exit 0'
  git add -A && git commit -qm run
  [ "$(sed -n 3p docs/verif/s01-a.md)" = "$(link_line verification-record | sed 's/<id>/s01-a/g')" ] \
    || fail "po-run moved the link line of the record"
  bash "$GATE" verif-current s01-a >/dev/null 2>&1 || fail "verif-current refused the linked record after a po-run"

  local t l
  for t in $TEMPLATES; do
    l="$(link_line "$t")"
    ! grep -qE '^---$|^## |^([-*] )?(Ship allowed|Review status|Reviewed tree|Fix loop|Tree|Verification status|QA status|validated|track):|Root cause: not found|Technical choice: waiting for a human' <<< "$l" \
      || fail "$t: the link line matches a pattern the commands read: $l"
  done
}

test_links_resolve() {
  local d; d="$(mktemp -d)"
  trap "rm -rf '$d'" EXIT
  mkdir -p "$d/docs/research" "$d/docs/plans" "$d/docs/verif" "$d/docs/reviews" "$d/docs/qa/s01-a"
  : > "$d/docs/stories.md"
  render() { sed "s/<id>/$3/g" "$TPL/$1.md" > "$d/docs/$2"; }
  render research research/s01-a.md s01-a
  render plan plans/s01-a.md s01-a
  render verification-record verif/s01-a.md s01-a
  render review reviews/s01-a.md s01-a
  render qa qa/s01-a/report.md s01-a
  render plan-flow plans/s02-b.md s02-b
  render verification-record verif/s02-b.md s02-b
  render review reviews/s02-b.md s02-b

  local f rendered line target n
  for f in research/s01-a.md plans/s01-a.md verif/s01-a.md reviews/s01-a.md qa/s01-a/report.md plans/s02-b.md verif/s02-b.md reviews/s02-b.md; do
    rendered="$d/docs/$f"
    line="$(awk '/^# / && !t {t=1; next} t && NF {print; exit}' "$rendered")"
    n=0
    while IFS= read -r target; do
      n=$((n + 1))
      [ -f "$(dirname "$rendered")/$target" ] || fail "docs/$f: link '$target' points to a missing file"
    done < <(grep -o '](\([^)]*\))' <<< "$line" | sed 's/^](//; s/)$//')
    [ "$n" -ge 1 ] || fail "docs/$f: no link on the line under the title"
  done
}
