# s203-H3: no driver, no row, `Platform: —` → the QA is recorded `blocked`, never `complete`; and it
# writes nothing outside docs/qa/<id>/ (security S2).
CASE_BASE=lane
CASE_LAUNCH='/po-qa s03-banner'
CASE_RULES="s203-H3 s203-S2"
setup() {
  real_setting 'QA stage' surfaces
  real_setting 'Platform' '—'
  real_story s03-banner 'Une bannière' surface=command
  real_lane s03-banner verified
}
CASE_EXPECT=('qa-blocked s03-banner' 'clean-except s03-banner docs/qa/s03-banner/')
CASE_OBSERVE=()
