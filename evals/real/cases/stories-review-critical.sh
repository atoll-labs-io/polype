# s204-H5: a critical finding of the stories review is put to the person; with no one to answer,
# no answer is written in for them. s03 depends on a story that does not exist, which the
# stories-review skill rates critical. The review itself is written whatever its verdict.
CASE_BASE=journey
CASE_LAUNCH=/po-stories-review
CASE_RULES="s204-H5 s204-conversational-framing"
setup() {
  real_setting 'Entry mode' new
  real_seed brief-approved.md docs/brief.md
  git -C "$R" rm -q docs/reviews/stories.md
  real_commit 'an approved brief; stories not reviewed yet'
  real_story s03-banner 'Une bannière' depends=s09-unknown
}
CASE_EXPECT=('present docs/reviews/stories.md' "no-line docs/reviews/stories.md ' — owner:'")
CASE_OBSERVE=('framing-not stories-review yes')
