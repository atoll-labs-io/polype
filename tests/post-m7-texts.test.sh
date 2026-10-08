#!/usr/bin/env bash
# s75 — texts lagging behind the method after M7.

test_installation_describes_the_reviewer_mode() {
  local doc="$ROOT/docs/installation.md" sub bounds
  sub="$(awk '/^### Le mode reviewer$/ {on=1; next} /^##/ {on=0} on' "$doc")"
  [ -n "$sub" ] || fail "no reviewer-mode subsection"
  for p in 'po-bounds.sh reviewer' "d'avant s70" 'polype init <projet>' 'ADR-0047'; do
    grep -qF -- "$p" <<< "$sub" || fail "reviewer subsection lacks: $p"
  done
  bounds="$(awk "/^### Le hook des bornes de l'implementer\$/ {on=1; next} /^## / {on=0} on" "$doc")"
  grep -qF 'ADR-0050' <<< "$bounds" || fail "bounds section does not cite ADR-0050"
  ! grep -qF 'ADR-0039' "$doc" || fail "installation.md still cites ADR-0039"
}

test_rules_name_every_bounded_agent() {
  local f="$METHOD/AGENTS.md"
  contains "$f" 'keeps the `implementer`, `qa` and `reviewer` subagents'
  ! grep -qF 'the `implementer` and `qa` subagents' "$f" || fail "old clause still there"
}

test_agentic_stories_cites_the_overlap_rule() {
  local f="$METHOD/skills/agentic-stories/SKILL.md" s
  s="$(awk '/^## Owns and contracts first/ {on=1; next} /^## / {on=0} on' "$f")"
  grep -qF 'by the overlap rule of check 8 of the `stories-review` skill' <<< "$s" || fail "rule not cited"
  ! grep -qF 'never share a path' <<< "$s" || fail "old wording still there"
}

test_partial_supersession_is_written_and_linked() {
  local pair succ pred f
  contains "$METHOD/templates/adr.md" 'replaced only in part'
  contains "$METHOD/commands/po-architect.md" 'replaced only in part'
  for pair in 0037:0029 0038:0024 0039:0024 0041:0037; do
    succ="${pair%%:*}"; pred="${pair#*:}"
    f="$(ls "$ROOT"/docs/decisions/ADR-"$succ"-*.md)"
    frontmatter "$f" | grep -qxF "supersedes: [ADR-$pred]" || fail "ADR-$succ lacks supersedes ADR-$pred"
    frontmatter "$(ls "$ROOT"/docs/decisions/ADR-"$pred"-*.md)" | grep -E '^superseded-by:' | grep -qF "ADR-$succ" \
      || fail "ADR-$pred does not name ADR-$succ"
  done
  for succ in 0037 0038 0041; do
    frontmatter "$(ls "$ROOT"/docs/decisions/ADR-"$succ"-*.md)" | grep -qx 'status: accepted' || fail "ADR-$succ not accepted"
  done
}
