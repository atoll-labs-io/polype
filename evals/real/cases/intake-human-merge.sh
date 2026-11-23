# s202-H7: the effective `Ship confirmation` binds the intake landing: under `human (chosen)` the
# new intake pull request stays open. Candidates of s177 observed on the same runs: only the hook
# account's issue is taken in, a pending intake branch does not block, and numbering sees it.
CASE_BASE=journey
CASE_LAUNCH=/po-intake
CASE_RULES="s202-H7 s177-only_the_hook_account_is_taken_in s177-pending_intake_does_not_block s177-numbering_sees_pending_branches"
setup() {
  real_setting 'Ship confirmation' 'human (chosen)'
  real_gh issues-intake-two-authors.json
  real_branch framing/intake-old
  real_gh pr framing/intake-old
}
# framing/intake-<timestamp>: the timestamp starts with the year, which keeps intake-old out.
CASE_EXPECT=("pr-open 'framing/intake-2*'" 'main-unchanged')
CASE_OBSERVE=('no-story-cites 2' "pr-open 'framing/intake-old'")
