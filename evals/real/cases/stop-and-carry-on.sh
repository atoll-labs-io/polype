# s201-H5: a stop goes to the person at once, and the fleet carries on with its other lanes.
CASE_BASE=lane
CASE_LAUNCH=drive
CASE_RULES="s201-H5"
setup() { real_lane s01-greeting research research-root-cause.md; }
CASE_EXPECT=('pending s01-greeting' 'landed s02-farewell')
CASE_OBSERVE=()
