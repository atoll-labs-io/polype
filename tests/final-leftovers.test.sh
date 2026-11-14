#!/usr/bin/env bash
# s77 — the last review leftovers.

test_reviewer_knows_the_hook_is_a_guard() {
  local p
  for p in 'guards against your mistakes' '(ADR-0052)' 'already lists and accepts is not a finding' 'never asks for a fix to the hook'; do
    contains "$METHOD/agents/reviewer.md" "$p"
  done
}

test_adr_links_are_the_only_edit() {
  local t="$METHOD/templates/adr.md" fm
  contains "$METHOD/AGENTS.md" 'only its frontmatter links, `supersedes` and `superseded-by`, ever change'
  ! grep -qF 'An accepted ADR is never edited;' "$METHOD/AGENTS.md" || fail "Law 6 still says an accepted ADR is never edited"
  fm="$(frontmatter "$t")"
  grep -qx 'supersedes: \[\]' <<< "$fm" || fail "template supersedes line is not bare"
  grep -qx 'superseded-by: \[\]' <<< "$fm" || fail "template superseded-by line is not bare"
  ! grep -E '^(supersedes|superseded-by):' <<< "$fm" | grep -q '#' || fail "a link line holds a comment"
}

test_overlap_wording_is_light() {
  local k="$METHOD/skills/stories-review/SKILL.md"
  contains "$k" 'whose `Owns` entries overlap are flagged as critical'
  ! grep -qF 'share an `Owns` path' "$k" || fail "check 8 keeps the old wording"
}
