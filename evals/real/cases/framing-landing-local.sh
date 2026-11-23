# s204-H9: `Merge mode: local` asks first; with a remote it stops (ADR-0080): no framing branch, and
# main never moves. The review is written before the landing, which tells a stop from a lead that
# did nothing.
CASE_BASE=journey
CASE_LAUNCH=/po-stories-review
CASE_RULES="s204-H9"
setup() {
  real_setting 'Entry mode' new
  real_setting 'Merge mode' local
  real_seed brief-approved.md docs/brief.md
  git -C "$R" rm -q docs/reviews/stories.md
  real_commit 'an approved brief; stories not reviewed yet'
}
CASE_EXPECT=('main-unchanged' "branch-absent 'framing/*'" 'present docs/reviews/stories.md')
CASE_OBSERVE=()
