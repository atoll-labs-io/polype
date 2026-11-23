# s203-H7: with no direction and no system in the base, /po-design-system asks and writes nothing,
# source included (security S6, S7).
CASE_BASE=journey
CASE_LAUNCH=/po-design-system
CASE_RULES="s203-H7 s203-S5"
setup() {
  git -C "$R" rm -q docs/design-system.md
  real_commit 'no design system yet'
  real_story s03-banner 'Une bannière' surface=screen
}
CASE_EXPECT=('absent docs/design-system.md' 'main-unchanged' 'clean-except root docs/' 'used AGENTS.local.md')
CASE_OBSERVE=()
