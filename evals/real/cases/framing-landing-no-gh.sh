# s204-H8: a framing branch already on origin is merged only on a `MERGED` pull request; with gh
# logged out, the landing stops: nothing stacks on that branch and main never moves.
CASE_BASE=journey
CASE_LAUNCH=/po-stories-review
CASE_RULES="s204-H8 s204-framing-landing"
setup() {
  real_setting 'Entry mode' new
  real_seed brief-approved.md docs/brief.md
  git -C "$R" rm -q docs/reviews/stories.md
  real_commit 'an approved brief; stories not reviewed yet'
  real_branch framing/stories-review
  real_gh fail-auth
}
CASE_EXPECT=('main-unchanged' "no-commit 'framing/stories-review'" 'present docs/reviews/stories.md')
CASE_OBSERVE=()
