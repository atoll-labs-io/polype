#!/usr/bin/env bash
# po-gate — Polype's file-based gates, enforced by git so they hold whatever tool runs the pipeline.
#
#   po-gate plan-validated <id>   exit 0 if docs/plans/<id>.md has `validated: yes` in its frontmatter
#   po-gate ship-allowed <id>     exit 0 if docs/reviews/<id>.md has the line `Ship allowed: yes`
#   po-gate verif-current <id>    exit 0 if docs/verif/<id>.md is complete and describes the committed code
#   po-gate pre-commit            refuse a code commit on story/<id> without a validated plan
#
# No push-time gate: ship squashes, so nothing is left to detect client-side. Enforce
# `po-gate ship-allowed <id>` in CI or branch protection instead.
set -euo pipefail

root() { git rev-parse --show-toplevel 2>/dev/null || pwd; }
say() { echo "po-gate: $*" >&2; }

# The frontmatter only: a `validated: yes` lost in the prose must not validate a plan.
plan_validated() {
  local id="$1" f; f="$(root)/docs/plans/$id.md"
  [ -f "$f" ] || { say "no plan for '$id' (docs/plans/$id.md). Run /po-plan $id."; return 1; }
  if awk 'NR==1 && $0=="---" {inside=1; next} inside && $0=="---" {exit} inside' "$f" \
      | grep -qE '^validated:[[:space:]]*yes[[:space:]]*$'; then
    return 0
  fi
  say "plan '$id' is not validated (frontmatter lacks 'validated: yes'). Validate it with /po-plan $id."
  return 1
}

ship_allowed() {
  local id="$1" f; f="$(root)/docs/reviews/$id.md"
  [ -f "$f" ] || { say "no review for '$id' (docs/reviews/$id.md). Run /po-review $id."; return 1; }
  grep -qE '^Ship allowed:[[:space:]]*yes[[:space:]]*$' "$f" && return 0
  say "ship blocked for '$id': the review does not say 'Ship allowed: yes'."
  return 1
}

# docs/ is excluded from the comparison: the record itself and the ticked plan are written after the run.
verif_current() {
  local id="$1" f tree; f="$(root)/docs/verif/$id.md"
  [ -f "$f" ] || { say "no verification record for '$id' (docs/verif/$id.md)."; return 1; }
  grep -qE '^Verification status:[[:space:]]*complete[[:space:]]*$' "$f" \
    || { say "verification record for '$id' is not complete."; return 1; }
  tree="$(sed -n 's/^Tree:[[:space:]]*\([0-9a-f]\{40\}\)[[:space:]]*$/\1/p' "$f" | head -1)"
  [ -n "$tree" ] || { say "verification record for '$id' has no valid 'Tree:' line."; return 1; }
  git cat-file -e "${tree}^{tree}" 2>/dev/null || { say "tree $tree is not in this repository."; return 1; }
  git diff --quiet "$tree" HEAD -- . ':(exclude)docs' 2>/dev/null && return 0
  say "code changed after the verification of '$id': the record no longer describes HEAD."
  return 1
}

pre_commit() {
  local branch id path code=0
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  case "$branch" in story/*) id="${branch#story/}" ;; *) return 0 ;; esac
  while IFS= read -r path; do
    case "$path" in docs/*|"") ;; *) code=1 ;; esac
  done < <(git diff --cached --name-only)
  [ "$code" = 1 ] || return 0
  plan_validated "$id" && return 0
  say "refusing a code commit on $branch without a validated plan (docs-only commits are allowed)."
  return 1
}

case "${1:-}" in
  plan-validated) plan_validated "${2:?story id required}" ;;
  ship-allowed)   ship_allowed "${2:?story id required}" ;;
  verif-current)  verif_current "${2:?story id required}" ;;
  pre-commit)     pre_commit ;;
  *) echo "usage: po-gate {plan-validated <id>|ship-allowed <id>|verif-current <id>|pre-commit}" >&2; exit 2 ;;
esac
