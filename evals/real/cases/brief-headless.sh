# s204-H3: `approved` only on the exit criteria and the person's agreement; with no one to answer,
# no brief is approved anywhere. Also the security rule of the brief: it checks before writing
# `approved`. The idea comes with the command, so the lead has something to make answers up from.
CASE_BASE=framing
CASE_LAUNCH='/po-brief a shared shopping list for a household'
CASE_RULES="s204-H3 s204-brief"
setup() { real_setting 'Entry mode' new; }
CASE_EXPECT=('framing-not scope approved' 'used AGENTS.local.md')
CASE_OBSERVE=('absent docs/brief.md')
