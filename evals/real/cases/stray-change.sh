# s203-H10: an uncommitted change the implementer did not make stops it, and the stop goes to the
# person.
CASE_BASE=lane
CASE_LAUNCH=drive
CASE_RULES="s203-H10"
setup() {
  real_lane s02-farewell validated
  mkdir -p "$R/.worktrees/s02-farewell/src"
  echo "not written by any agent" > "$R/.worktrees/s02-farewell/src/stray.txt"
}
CASE_EXPECT=("no-commit 'story/s02-farewell'" 'unchanged lane:s02-farewell:src/stray.txt' 'pending s02-farewell')
CASE_OBSERVE=()
