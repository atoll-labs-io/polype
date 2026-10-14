#!/usr/bin/env bash
# s133 — the docs say Polype aims at any harness, Claude Code first, and how to ask for another.

README="$ROOT/README.md"
INSTALL="$ROOT/docs/installation.md"
HELP="$METHOD/commands/po-help.md"
MATRIX="$ROOT/docs/parite-killer-saas.md"

status_of() { awk -F'|' -v id=" $1 " '$2 == id {print $(NF - 1); exit}' "$MATRIX"; }

flat() { tr -s '[:space:]' ' ' < "$1"; }

section_of() { awk -v h="$2" '$0 == h {on=1; next} /^## / {on=0} on' "$1" | tr -s '[:space:]' ' '; }

has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

test_docs_name_any_harness() {
  local f text
  for f in "$README" "$INSTALL" "$HELP"; do
    require_file "$f"
    text="$(flat "$f")"
    for p in 'tout agent ou harness' "pris en charge aujourd'hui : Claude Code" 'prévu ensuite : Codex' 'ouvrir une issue'; do
      has "$text" "$p" || fail "${f#"$ROOT"/} lacks: $p"
    done
    for p in 'portée par des agents Claude Code' 'agents Claude Code encadrés' 'mi-octobre'; do
      has "$text" "$p" && fail "${f#"$ROOT"/} still holds: $p"
    done
  done
  for f in "$README" "$INSTALL"; do
    has "$(flat "$f")" 'ADR-0005' || fail "${f#"$ROOT"/} lacks ADR-0005"
  done
  has "$(sed -n 3p "$README")" 'tout agent ou harness' || fail 'README hook line lacks: tout agent ou harness'
}

test_portable_and_specific_parts_are_named() {
  local sec p
  sec="$(section_of "$README" '## Pour quel agent')"
  [ -n "$sec" ] || fail 'README has no section "## Pour quel agent"'
  for p in 'AGENTS.md' 'SKILL.md' 'scripts shell' 'hooks git' 'subagents' 'PreToolUse' 'SessionStart' 'AskUserQuestion' '~/.claude/'; do
    has "$sec" "$p" || fail "README section lacks: $p"
  done
  p="$(status_of H03)"
  has "$p" 'partiel' || fail 'H03 status is not partiel'
  has "$p" 'README.md' || fail 'H03 status does not mention README.md'
}

test_harness_issue_template_exists() {
  local target tpl
  target="$(grep -o '([^)]*ISSUE_TEMPLATE[^)]*)' "$README" | head -1 | tr -d '()')"
  [ -n "$target" ] || fail 'README links no issue template'
  case "$target" in *http*) fail "issue template link is not relative: $target" ;; esac
  tpl="$ROOT/$target"
  [ -f "$tpl" ] || fail "issue template missing: $target"
  frontmatter "$tpl" | grep -q '^name:.*harness' || fail 'template name lacks harness'
  frontmatter "$tpl" | grep -q '^about:' || fail 'template lacks about:'
  for p in version sous-agents hooks 'AGENTS.md'; do
    grep -qF -- "$p" "$tpl" || fail "template body lacks: $p"
  done
}
