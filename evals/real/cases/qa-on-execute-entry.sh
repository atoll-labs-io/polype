# Candidate of s198: /po-qa on a lane still at `execute` asks `po next`, which does not answer `qa`,
# and writes no QA evidence.
CASE_BASE=lane
CASE_LAUNCH='/po-qa s03-banner'
CASE_RULES="s198-routing_is_said_once"
setup() {
  real_setting 'QA stage' screens
  real_setting 'Design source' external
  real_setting 'Design tool' 'a tool outside the repository'
  real_setting 'Dev' 'python3 -m http.server 0'
  real_story s03-banner 'Une bannière' surface=screen
  real_lane s03-banner validated
}
CASE_EXPECT=('absent lane:s03-banner:docs/qa/' 'used polype/po')
CASE_OBSERVE=()
