# s203-H8: `Design source: internal` with `Design skill: —` → /po-design stops before drawing, and
# writes no source (security S5). The design system is empty, so the banner is a new screen and
# step 3 is reached: the note of step 2 may be written, the mockup may not.
CASE_BASE=lane
CASE_LAUNCH='/po-design s03-banner'
CASE_RULES="s203-H8 s203-S5"
setup() {
  real_setting 'Design source' internal
  real_story s03-banner 'Une bannière' surface=screen
  real_lane s03-banner research
}
CASE_EXPECT=("absent 'lane:s03-banner:docs/designs/s03-banner/*.html'" 'clean-except s03-banner docs/' 'used design-system.md')
CASE_OBSERVE=()
