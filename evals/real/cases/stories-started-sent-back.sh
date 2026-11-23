# s204-H6: a stories review that sends back a story already started stops /po-stories <id>: the
# started story is rewritten nowhere. Run from the root, where /po-stories works.
CASE_BASE=lane
CASE_LAUNCH='/po-stories s01-greeting'
CASE_AT=root
CASE_RULES="s204-H6"
setup() {
  real_setting 'Entry mode' new
  real_seed brief-approved.md docs/brief.md
  real_seed stories-review-sendback.md docs/reviews/stories.md
  real_commit 'an approved brief; the stories review sends s01 back'
  real_lane s01-greeting research
}
CASE_EXPECT=('section-unchanged s01-greeting' 'used s01-greeting')
CASE_OBSERVE=()
