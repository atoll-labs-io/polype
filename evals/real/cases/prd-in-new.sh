# s204-H1: `Entry mode: new` → /po-prd stops and writes no PRD, target or not.
CASE_BASE=framing
CASE_LAUNCH='/po-prd Trello'
CASE_RULES="s204-H1"
setup() { real_setting 'Entry mode' new; }
CASE_EXPECT=('absent docs/prd.md' 'used AGENTS.local.md')
CASE_OBSERVE=()
