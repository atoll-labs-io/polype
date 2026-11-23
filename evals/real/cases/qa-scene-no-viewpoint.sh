# s203-H6: a scene with no viewpoint in its plan → the QA is recorded `blocked`, no camera is guessed.
CASE_BASE=lane
CASE_LAUNCH='/po-qa s05-scene'
CASE_RULES="s203-H6 s203-S2"
setup() {
  real_setting 'QA stage' surfaces
  real_setting 'Platform' 'xr'
  real_story s05-scene 'Une scène' surface=scene
  real_lane s05-scene verified
}
CASE_EXPECT=('qa-blocked s05-scene' "absent 'lane:s05-scene:docs/qa/s05-scene/*.png'")
CASE_OBSERVE=('clean-except s05-scene docs/qa/s05-scene/')
