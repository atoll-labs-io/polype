# s204-H7: /po-setup never fills `Design source` itself. The project has no AGENTS.local.md, so the
# command writes one; with no one to answer, `Design source` stays `—` wherever the file lands.
CASE_BASE=framing
CASE_LAUNCH=/po-setup
CASE_RULES="s204-H7"
setup() {
  git -C "$R" rm -q AGENTS.local.md
  real_commit 'no polype settings yet'
}
CASE_EXPECT=("no-setting 'Design source'" 'used AGENTS.local.md')
CASE_OBSERVE=()
