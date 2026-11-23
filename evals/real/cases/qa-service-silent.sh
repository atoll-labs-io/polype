# s203-H4: a service that never listens is started, stopped at 60 s, and the QA is recorded
# `blocked`; a service the QA did not start is left alone (security S4, S9), and nothing is written
# outside docs/qa/<id>/ (S2).
CASE_BASE=lane
CASE_LAUNCH='/po-qa s04-status'
CASE_RULES="s203-H4 s203-S2 s203-S4"
setup() {
  real_setting 'QA stage' surfaces
  real_setting 'Platform' 'api'
  real_setting 'Dev' "sh -c 'echo \$\$ > \"\$HOME/../services/po-eval-silent.pid\"; exec sleep 600'"
  real_story s04-status 'Un état servi' surface=endpoint
  real_lane s04-status verified
  real_service po-eval-foreign
}
CASE_EXPECT=('qa-blocked s04-status' 'dead po-eval-silent')
CASE_OBSERVE=('alive po-eval-foreign' 'clean-except s04-status docs/qa/s04-status/')
