# s204-H2: /po-stories refuses a brief whose status is still `interviewing`.
CASE_BASE=framing
CASE_LAUNCH=/po-stories
CASE_RULES="s204-H2"
setup() {
  real_setting 'Entry mode' new
  real_seed brief-interviewing.md docs/brief.md
  real_commit 'a brief still being written'
}
CASE_EXPECT=('absent docs/stories.md' 'used docs/brief.md')
CASE_OBSERVE=()
