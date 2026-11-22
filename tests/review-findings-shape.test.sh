#!/usr/bin/env bash
# s141 — a review's findings are checked for the shape /po-ship reads as soon as they are recorded.

GATE="$METHOD/hooks/po-gate.sh"
REVIEW_CMD="$METHOD/commands/po-review.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

# One review block whose `## Findings` holds the lines given, written for story s01-a.
findings_block() {
  printf 'Review status: complete\nFix loop: 0\n\n## Findings\n'
  printf '%s\n' "$@"
  printf '\n## Not verified\n### Critical\n- nothing major left\n\nMax severity: minor\nShip allowed: yes\n'
}

shape() { (cd "$SCRATCH" && bash "$GATE" findings-shape s01-a 2>&1); }

refused() {
  findings_block "$@" > "$SCRATCH/docs/reviews/s01-a.md"
  shape > /dev/null && fail "accepted a shape /po-ship cannot read: $*"
  return 0
}

accepted() {
  findings_block "$@" > "$SCRATCH/docs/reviews/s01-a.md"
  shape > /dev/null || fail "refused a shape /po-ship reads: $* — $(shape)"
}

test_gate_checks_findings_shape() {
  scratch_repo
  mkdir -p "$SCRATCH/docs/reviews"
  local out
  cp "$ROOT/docs/reviews/s137-modified-copy-survives-drop.md" "$SCRATCH/docs/reviews/s01-a.md"
  out="$(shape)" && fail "the s137 review, findings in headings, passed"
  holds "$out" 'docs/reviews/s01-a.md:65: ### F1: major.' "the s137 refusal"
  holds "$out" ':86: ### F2: minor.' "the s137 refusal"
  cp "$ROOT/docs/reviews/s138-mode-hint-cleanup.md" "$SCRATCH/docs/reviews/s01-a.md"
  shape > /dev/null || fail "the s138 review, findings in list items, was refused: $(shape)"

  refused '### F1: Major. heading'
  refused '- see the major point'
  refused '**minor** — x outside a list'
  refused 'Critical: x outside a list'
  printf 'Review status: complete\n## Not verified\n- x\nMax severity: none\nShip allowed: yes\n' > "$SCRATCH/docs/reviews/s01-a.md"
  out="$(shape)" && fail "a review with no ## Findings passed"
  holds "$out" '## Findings' "the refusal of a missing section"

  accepted '- major — a.sh:1 — plain' '- **major** — a.sh:2 — bold' '1. **minor**: numbered' '* minor: star' \
    '- **minor:** colon in bold' '  - an indented major sub-bullet' '' 'none' 'None.' 'No critical or major finding.' \
    '- the majority of cases'

  { findings_block '### F1: major. bad'; findings_block '- major — a.sh:1 — good'; } > "$SCRATCH/docs/reviews/s01-a.md"
  shape > /dev/null || fail "an earlier malformed block counted against the last one"
  { findings_block '- major — a.sh:1 — good'; findings_block '### F1: major. bad'; } > "$SCRATCH/docs/reviews/s01-a.md"
  shape > /dev/null && fail "a malformed last block passed after a well-formed one"
  return 0
}

test_template_shows_the_line() {
  local tpl="$METHOD/templates/review.md" findings
  findings="$(section_of "$tpl" Findings)"
  holds "$findings" '- <critical|major|minor> — <path>:<line> — <the problem>' "the template's ## Findings"
}

test_recording_runs_the_check() {
  frontmatter "$REVIEW_CMD" | grep -qxF '  - Bash(.polype/hooks/po-gate.sh findings-shape:*)' || fail "po-review lacks the narrowed Bash permission"
  lacks_tool "$REVIEW_CMD" Bash
  local rec
  rec="$(section_of "$REVIEW_CMD" Recording)"
  holds "$rec" '`Next action: a person settles the findings shape — po-gate findings-shape <id> refused the reviewer twice`' "po-review ## Recording"
}

test_gate_accepts_only_ship_shapes() {
  scratch_repo
  mkdir -p "$SCRATCH/docs/reviews"
  local l out
  for l in '- major. a.sh:1 x' '- major (a.sh:1) x' '- MAJOR x' '- Major — x' '+ major — x' '1) major — x' '> major — x' '• major — x' '### F1: major.'; do
    refused "$l"
  done
  findings_block '+ major — x' > "$SCRATCH/docs/reviews/s01-a.md"
  out="$(shape)" || true
  holds "$out" 'docs/reviews/s01-a.md:5: + major — x' "the refusal"
  accepted '- **major:** x' '- **major**: x' '- major — a.sh:1 — plain' '- **major** — b' '1. **minor**: c' '* minor: d' '- major-ish thing' 'None.' 'No critical or major finding.'
}

test_other_gate_failures_stop() {
  scratch_repo
  local rc=0 s
  (cd "$SCRATCH" && bash "$GATE" findings-shape >/dev/null 2>&1) || rc=$?
  [ "$rc" -eq 2 ] || fail "no id exits $rc, not 2"
  rc=0
  (cd "$SCRATCH" && bash "$GATE" findings-shape s01-a >/dev/null 2>&1) || rc=$?
  [ "$rc" -eq 2 ] || fail "a missing review exits $rc, not 2"
  s="$(section_of "$REVIEW_CMD" Recording)"
  holds "$s" '`Next action: a person runs po-gate findings-shape <id> — the check could not run (exit <n>)`' "po-review Recording"
}
