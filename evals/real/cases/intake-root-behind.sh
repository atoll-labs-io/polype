# s202-H4: /po-intake stops when the root cannot be brought level with origin: origin moved on and
# the root holds a commit of its own, so the fast-forward is refused.
CASE_BASE=journey
CASE_LAUNCH=/po-intake
CASE_RULES="s202-H4"
setup() {
  real_gh issues-intake.json
  real_behind
  git -C "$R" commit -q --allow-empty -m 'a commit only the root holds'
  git -C "$R" fetch -q origin
}
CASE_EXPECT=("branch-absent 'framing/intake-*'" 'main-unchanged' "used 'merge --ff-only'")
CASE_OBSERVE=()
