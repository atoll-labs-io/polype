# The release run: a real lead drives the two journey stories from ready to landed (ADR-0133: one
# journey run, with no arm, before each release).
CASE_BASE=journey
CASE_LAUNCH=drive
CASE_RULES="s202-H1 s190-planner_follows_the_track_it_is_given s192-ship_command_reads_the_value s193-ship_command_calls_it s197-subagents_keep_their_procedure s204-run-ledger"
setup() { :; }
CASE_EXPECT=('landed all' 'stories-unchanged' 'no-unexpected-call')
CASE_OBSERVE=('track s01-greeting flow' 'track s02-farewell full' 'runs-recorded')
