#!/usr/bin/env bash
# s124 — the framing landing never commits to or pushes the target branch, and no framing command commits a CLAUDE.md.

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_setup_landing_holds() {
  local setup="$METHOD/commands/po-setup.md"
  require_file "$setup"
  local land; land=$(section_of "$setup" 'Landing the framing')
  holds "$land" 'It never commits to `Target branch` directly and never pushes it.' 'landing'
  local loc; loc=$(awk '/^\*\*`Merge mode: local`\*\*/ {on=1} /^\*\*Report\.\*\*/ {on=0} on' <<< "$land")
  holds "$loc" 'A refusal → stop: `framing/<slug>` stays in place and is not deleted' 'local block'
}

test_framing_wording_is_clean() {
  local setup="$METHOD/commands/po-setup.md" arch="$METHOD/commands/po-architect.md"
  require_file "$setup"; require_file "$arch"
  local f
  for f in "$setup" "$arch"; do
    contains "$f" 'Never commit a `CLAUDE.md` (ADR-0086)' || fail "$f lacks the ADR reference inside its sentence"
  done
}
