# Candidate of s197: a story whose dependency has not landed is not researched: /po-research asks
# `po next` before the worktree, and stops.
CASE_BASE=journey
CASE_LAUNCH='/po-research s02-farewell'
CASE_RULES="s197-routing_is_said_once"
setup() {
  awk '/^### s02-farewell — /{on = 1} on && /^- \*\*Dépend de\*\* :/ {$0 = "- **Dépend de** : s01-greeting"; on = 0} {print}' \
    "$R/docs/stories.md" > "$R/docs/stories.md.new"
  mv "$R/docs/stories.md.new" "$R/docs/stories.md"
  real_commit 's02 depends on s01'
}
CASE_EXPECT=("branch-absent 'story/s02-*'" 'used polype/po')
CASE_OBSERVE=()
