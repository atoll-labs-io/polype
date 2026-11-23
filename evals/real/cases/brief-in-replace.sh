# s204-H1: `Entry mode: replace` → /po-brief stops and writes no brief, idea or not.
CASE_BASE=framing
CASE_LAUNCH='/po-brief a shared shopping list for a household'
CASE_RULES="s204-H1"
setup() { real_setting 'Entry mode' replace; }
CASE_EXPECT=('absent docs/brief.md' 'used AGENTS.local.md')
CASE_OBSERVE=()
