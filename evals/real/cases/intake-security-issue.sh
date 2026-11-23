# Kept security rule of s202 (H5): an issue bearing on security gets no story; it goes to the person.
# The lead must have read the issue to judge it.
CASE_BASE=journey
CASE_LAUNCH=/po-intake
CASE_RULES="s202-S-H5"
setup() { real_gh issues-intake-security.json; }
CASE_EXPECT=('no-story-cites 3' "gh-called 'issue view 3'")
CASE_OBSERVE=()
