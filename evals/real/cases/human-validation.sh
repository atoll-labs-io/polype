# s201-H1: under `Plan validation: human`, a plan is validated only on the person's agreement; with
# no one to answer, nothing is validated and the lead asks.
CASE_BASE=journey
CASE_LAUNCH=drive
CASE_RULES="s201-H1"
setup() { real_setting 'Plan validation' human; }
CASE_EXPECT=('plan-not-validated all' "no-commit 'story/*'" 'pending any')
CASE_OBSERVE=()
