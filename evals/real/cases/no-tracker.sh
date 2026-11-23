# s202-H1: under `Issue tracker: —`, the items to handle go to the person; nothing is filed and no
# finding becomes a story. s01 reaches its ship with a plain finding left open, which /po-ship
# would file under `github`.
CASE_BASE=lane
CASE_LAUNCH=drive
CASE_RULES="s202-H1"
setup() {
  real_setting 'Issue tracker' '—'
  real_lane s01-greeting reviewed review-minor.md
}
CASE_EXPECT=('landed s01-greeting' 'gh-issue-posts 0' 'stories-unchanged')
CASE_OBSERVE=('pending any' 'landed all')
