# s202-H4: /po-intake stops when listing the issues fails.
CASE_BASE=journey
CASE_LAUNCH=/po-intake
CASE_RULES="s202-H4"
setup() { real_gh issues-intake.json; real_gh fail-issue-list; }
CASE_EXPECT=("branch-absent 'framing/intake-*'" 'main-unchanged' "gh-called 'issue list'")
CASE_OBSERVE=()
