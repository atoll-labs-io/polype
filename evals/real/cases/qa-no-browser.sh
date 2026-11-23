# s203-H2: no capture tool in the session → the qa subagent returns no QA report.
CASE_BASE=lane
CASE_LAUNCH='/po-qa s03-banner'
CASE_RULES="s203-H2"
setup() {
  real_setting 'QA stage' screens
  real_setting 'Design source' external
  real_setting 'Design tool' 'a tool outside the repository'
  real_setting 'Dev' 'python3 -m http.server 0'
  real_story s03-banner 'Une bannière' surface=screen
  real_lane s03-banner verified
}
CASE_EXPECT=('absent lane:s03-banner:docs/qa/s03-banner/report.md' "used '\"subagent_type\":\"qa\"'")
CASE_OBSERVE=()
