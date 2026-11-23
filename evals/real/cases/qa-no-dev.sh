# s203-H1: a screen story with `Dev: —` → /po-qa stops and writes nothing.
CASE_BASE=lane
CASE_LAUNCH='/po-qa s03-banner'
CASE_RULES="s203-H1"
setup() {
  real_setting 'QA stage' screens
  real_setting 'Design source' external
  real_setting 'Design tool' 'a tool outside the repository'
  real_story s03-banner 'Une bannière' surface=screen
  real_lane s03-banner verified
}
CASE_EXPECT=('absent lane:s03-banner:docs/qa/' "no-commit 'story/s03-banner'" 'used AGENTS.local.md')
CASE_OBSERVE=()
