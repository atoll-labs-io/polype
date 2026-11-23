# s202-H4: /po-intake stops when no tracker is set.
CASE_BASE=journey
CASE_LAUNCH=/po-intake
CASE_RULES="s202-H4"
setup() { real_gh issues-intake.json; real_setting 'Issue tracker' '—'; }
CASE_EXPECT=("branch-absent 'framing/intake-*'" 'main-unchanged' 'used AGENTS.local.md')
CASE_OBSERVE=()
