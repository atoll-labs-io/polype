#!/usr/bin/env bash
# s129 — artefacts already written get the link line of their template.

GATE="$METHOD/hooks/po-gate.sh"
RUN="$METHOD/hooks/po-run.sh"
TPL="$METHOD/templates"
LINK="$ROOT/bin/po-link-artifacts"

tpl_line() { awk '/^# / && !t {t=1; next} t && NF {print; exit}' "$TPL/$1.md" | sed "s/<id>/$2/g"; }
under_title() { awk '/^# / && !t {t=1; next} t && NF {print; exit}' "$1"; }

# Everything but the two lines the script inserted after the title.
without_inserted() { awk '/^# / && !t {t=1; print; skip=2; next} skip>0 {skip--; next} {print}' "$1"; }

gate_codes() {
  local g codes=""
  for g in plan-validated ship-allowed verif-current qa-current; do
    bash "$GATE" "$g" s01-a >/dev/null 2>&1 && codes="$codes 0" || codes="$codes $?"
  done
  echo "$codes"
}

test_backfill_is_a_script() {
  local d; d="$(mktemp -d)"
  trap "rm -rf '$d'" EXIT
  mkdir -p "$d/docs/research" "$d/docs/plans" "$d/docs/verif" "$d/docs/reviews" "$d/docs/qa/s01-a"
  : > "$d/docs/stories.md"
  local body=$'\nBody line\n'
  printf '# Research — s01-a\n%s' "$body" > "$d/docs/research/s01-a.md"
  printf -- '---\nvalidated: yes\n---\n# Plan — s01-a\n%s' "$body" > "$d/docs/plans/s01-a.md"
  printf '# Verification — s01-a\n%s' "$body" > "$d/docs/verif/s01-a.md"
  printf '# Review — s01-a\n%s' "$body" > "$d/docs/reviews/s01-a.md"
  printf '# QA — s01-a\n%s' "$body" > "$d/docs/qa/s01-a/report.md"
  printf -- '---\ntrack: flow\nvalidated: yes\n---\n# Plan (short track) — s02-b\n%s' "$body" > "$d/docs/plans/s02-b.md"
  printf '# Research — s02-b\n%s' "$body" > "$d/docs/research/s02-b.md"
  printf '# Verification — s02-b\n%s' "$body" > "$d/docs/verif/s02-b.md"
  printf '# Review — s02-b\n%s' "$body" > "$d/docs/reviews/s02-b.md"
  printf -- '---\nvalidated: yes\n---\n# Plan — s03-c\n%s' "$body" > "$d/docs/plans/s03-c.md"
  printf '# Review — s04-d\n\n%s\n%s' "$(tpl_line review s04-d)" "$body" > "$d/docs/reviews/s04-d.md"
  local n
  for n in stories-m9 stories triage-2026-10-14; do
    printf '# Title %s\n%s' "$n" "$body" > "$d/docs/reviews/$n.md"
  done
  cp -r "$d/docs" "$d/orig"

  local out; out="$(bash "$LINK" "$d")"
  [ "$(wc -l <<< "$out")" -eq 10 ] || fail "expected 10 files changed, got: $out"

  local pairs="research/s01-a:research:s01-a plans/s01-a:plan:s01-a verif/s01-a:verification-record:s01-a
reviews/s01-a:review:s01-a qa/s01-a/report:qa:s01-a plans/s02-b:plan-flow:s02-b verif/s02-b:verification-record:s02-b
research/s02-b:research:s02-b reviews/s02-b:review:s02-b plans/s03-c:plan:s03-c"
  local p f t id want
  for p in $pairs; do
    IFS=: read -r f t id <<< "$p"
    want="$(tpl_line "$t" "$id")"
    case "$f" in
      plans/s03-c) want="[Story](../stories.md)" ;;
    esac
    [ "$(under_title "$d/docs/$f.md")" = "$want" ] || fail "$f: wrong line: $(under_title "$d/docs/$f.md")"
    cmp -s <(without_inserted "$d/docs/$f.md") "$d/orig/$f.md" || fail "$f: changed more than the two inserted lines"
  done

  for f in reviews/s04-d reviews/stories-m9 reviews/stories reviews/triage-2026-10-14; do
    cmp -s "$d/docs/$f.md" "$d/orig/$f.md" || fail "$f was touched"
  done

  local sums; sums="$(find "$d/docs" -type f | sort | xargs sha256sum)"
  out="$(bash "$LINK" "$d")"
  [ -z "$out" ] || fail "second run printed: $out"
  [ "$sums" = "$(find "$d/docs" -type f | sort | xargs sha256sum)" ] || fail "second run changed files"
}

test_links_resolve_everywhere() {
  local f line target n
  for f in "$ROOT"/docs/research/s[0-9]*-*.md "$ROOT"/docs/plans/s[0-9]*-*.md "$ROOT"/docs/reviews/s[0-9]*-*.md \
           "$ROOT"/docs/verif/s[0-9]*-*.md "$ROOT"/docs/qa/s[0-9]*-*/report.md; do
    [ -f "$f" ] || continue
    line="$(under_title "$f")"
    n=0
    while IFS= read -r target; do
      n=$((n + 1))
      [ -f "$(dirname "$f")/$target" ] || fail "${f#"$ROOT"/}: link '$target' points to a missing file"
    done < <(grep -o '](\([^)]*\))' <<< "$line" | sed 's/^](//; s/)$//')
    [ "$n" -ge 1 ] || fail "${f#"$ROOT"/}: no link on the line under the title"
  done

  scratch_repo
  cd "$SCRATCH"
  mkdir -p src docs/plans docs/reviews docs/verif docs/qa/s01-a
  echo 'x' > src/app.txt
  : > docs/stories.md
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
  [ "$(bash "$LINK" . | wc -l)" -eq 4 ] || fail "the four artefacts were not all linked"
  git add -A && git commit -qm links
  after="$(gate_codes)"
  [ "$before" = "$after" ] || fail "a link line changed a gate result: '$before' became '$after'"
}

test_existing_artifacts_backfilled() {
  local d; d="$(mktemp -d)"
  trap "rm -rf '$d'" EXIT
  cp -r "$ROOT/docs" "$d/docs"
  local out; out="$(bash "$LINK" "$d")"
  [ -z "$out" ] || fail "artefacts without their link line: $out"
  diff -r "$ROOT/docs" "$d/docs" >/dev/null || fail "the script changed the docs"
  local f
  for f in "$ROOT"/docs/reviews/stories*.md "$ROOT"/docs/reviews/triage-*.md; do
    [ -f "$f" ] || continue
    case "$(under_title "$f")" in '[Story]('*) fail "${f#"$ROOT"/} is not an artefact but carries a story link" ;; esac
  done
}
