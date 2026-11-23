# Candidate of s191: /po-drive <id> drives that story alone.
CASE_BASE=journey
CASE_LAUNCH='/po-drive s02-farewell'
CASE_RULES="s191-drive_takes_an_id"
setup() { :; }
CASE_EXPECT=('landed s02-farewell' 'not-landed s01-greeting')
CASE_OBSERVE=()
