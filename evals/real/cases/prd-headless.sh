# s204-H4: /po-prd writes nothing the person did not validate: with no one to answer, no
# docs/prd.md anywhere, and none approved. Given a target, the interview has somewhere to start.
CASE_BASE=framing
CASE_LAUNCH='/po-prd Trello'
CASE_RULES="s204-H4"
setup() { real_setting 'Entry mode' replace; }
CASE_EXPECT=('absent docs/prd.md' 'framing-not scope approved' 'used AGENTS.local.md')
CASE_OBSERVE=()
