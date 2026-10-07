#!/usr/bin/env bash
# po-gate — Polype's gates as plain file checks, so any tool (or CI) can enforce them.
#
#   po-gate plan-validated <id>   0 when the plan's frontmatter says `validated: yes`
#   po-gate ship-allowed <id>     0 when the review's last `Ship allowed:` line says yes and its
#                                 `Reviewed tree:` still matches HEAD outside docs/
#   po-gate verif-current <id>    0 when the verification record is complete and matches HEAD
#   po-gate pre-commit            non-zero on a code commit to story/<id> whose plan is not approved
#
# Squash merges leave nothing for a push hook to inspect; put `po-gate ship-allowed <id>` in CI,
# on a checkout of the story branch tip rather than a merge ref: it compares against HEAD.
set -euo pipefail

top() { git rev-parse --show-toplevel 2>/dev/null || pwd; }
refuse() { echo "po-gate: $*" >&2; return 1; }

frontmatter() { awk 'NR==1 && $0=="---" {on=1; next} on && $0=="---" {exit} on' "$1"; }

plan_validated() {
  local plan; plan="$(top)/docs/plans/$1.md"
  [ -f "$plan" ] || refuse "$1 has no plan yet (docs/plans/$1.md) — /po-plan $1" || return 1
  frontmatter "$plan" | grep -qE '^validated:[[:space:]]*yes[[:space:]]*$' \
    || refuse "the plan of $1 is not approved: its frontmatter lacks 'validated: yes' — /po-plan $1"
}

# The first `<label>:` line holding a full 40-hex hash; abbreviations would resolve in git, so they are refused.
first_hash() { sed -n "s/^$1:[[:space:]]*\([0-9a-f]\{40\}\)[[:space:]]*\$/\1/p" "$2" | head -n 1; }

tree_exists() { git -C "$(top)" cat-file -e "$1^{tree}" 2>/dev/null; }

# docs/ is left out of the comparison: the record, the ticked plan and the review are written after the code they judge.
code_matches() { git -C "$(top)" diff --quiet "$1" HEAD -- . ':(exclude)docs'; }

# Only the last verdict line counts: a report may quote an earlier verdict before giving its own.
ship_allowed() {
  local review verdict tree; review="$(top)/docs/reviews/$1.md"
  [ -f "$review" ] || refuse "$1 has not been reviewed (docs/reviews/$1.md) — /po-review $1" || return 1
  verdict="$(grep -E '^Ship allowed:' "$review" | tail -n 1 || true)"
  [[ "$verdict" =~ ^Ship\ allowed:[[:space:]]*yes[[:space:]]*$ ]] \
    || refuse "the review of $1 does not allow shipping (last verdict: ${verdict:-none})" || return 1
  tree="$(first_hash 'Reviewed tree' "$review")"
  [ -n "$tree" ] || refuse "the review of $1 has no usable 'Reviewed tree:' hash — /po-review $1" || return 1
  { tree_exists "$tree" && code_matches "$tree"; } \
    || refuse "the code of $1 changed after its review (tree $tree); the verdict no longer applies — /po-review $1"
}

verif_current() {
  local record tree; record="$(top)/docs/verif/$1.md"
  [ -f "$record" ] || refuse "$1 has no verification record (docs/verif/$1.md)" || return 1
  grep -qE '^Verification status:[[:space:]]*complete[[:space:]]*$' "$record" \
    || refuse "the verification record of $1 is not marked complete" || return 1
  tree="$(first_hash 'Tree' "$record")"
  [ -n "$tree" ] || refuse "the verification record of $1 has no usable 'Tree:' hash" || return 1
  tree_exists "$tree" \
    || refuse "tree $tree from the record of $1 does not exist in this repository" || return 1
  code_matches "$tree" \
    || refuse "the code of $1 changed after its checks ran; the record no longer matches HEAD"
}

pre_commit() {
  local branch staged path code=no
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  [[ "$branch" == story/* ]] || return 0
  # --no-renames: moving code into docs/ must count as touching code.
  staged="$(git diff --cached --name-only --no-renames)" \
    || refuse "could not list the staged files; refusing the commit" || return 1
  while IFS= read -r path; do
    case "$path" in ''|docs/*) ;; *) code=yes ;; esac
  done <<< "$staged"
  [ "$code" = yes ] || return 0
  plan_validated "${branch#story/}" \
    || refuse "no code commit on $branch before its plan is approved (commits touching only docs/ are fine)"
}

case "${1:-}" in
  plan-validated) plan_validated "${2:?story id required}" ;;
  ship-allowed)   ship_allowed "${2:?story id required}" ;;
  verif-current)  verif_current "${2:?story id required}" ;;
  pre-commit)     pre_commit ;;
  *) echo "po-gate: unknown subcommand '${1:-}' (see the header of this script)" >&2; exit 2 ;;
esac
