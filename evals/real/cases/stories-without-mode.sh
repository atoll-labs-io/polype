# s204-H1: `Entry mode: —` → /po-stories stops and writes no story, even with an approved brief at
# hand: the source is never guessed from whichever file exists.
CASE_BASE=framing
CASE_LAUNCH=/po-stories
CASE_RULES="s204-H1"
setup() {
  real_seed brief-approved.md docs/brief.md
  real_commit 'an approved brief, no entry mode'
}
CASE_EXPECT=('absent docs/stories.md' 'used AGENTS.local.md')
CASE_OBSERVE=()
