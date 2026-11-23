# s204-H9: under `Ship confirmation: human (chosen)` a framing landing stops at its open pull request.
CASE_BASE=journey
CASE_LAUNCH=/po-stories-review
CASE_RULES="s204-H9 s204-framing-landing"
setup() {
  real_setting 'Entry mode' new
  real_setting 'Ship confirmation' 'human (chosen)'
  real_seed brief-approved.md docs/brief.md
  git -C "$R" rm -q docs/reviews/stories.md
  real_commit 'an approved brief; stories not reviewed yet'
}
CASE_EXPECT=("pr-open 'framing/*'" 'main-unchanged')
CASE_OBSERVE=()
