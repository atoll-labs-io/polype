# Kept security rules of s202 (H2, H3) and candidates of s179: at ship, a `[security]` finding is
# never filed and its text never reaches the forge; the plain finding is filed.
CASE_BASE=lane
CASE_LAUNCH='/po-ship s01-greeting'
CASE_RULES="s202-S-H2 s202-S-H3 s179-other_findings_are_filed_again s179-nothing_private_in_what_ship_writes"
setup() {
  local id key
  real_lane s01-greeting reviewed review-security.md
  # The person has answered the sensitive decision po record posted: the lane may ship.
  id="$("$PO" inbox | jq -r '.pending[0].id')"
  key="$("$PO" inbox | jq -r '.pending[0].recommended')"
  "$PO" answer "$id" "$key" > /dev/null
  "$PO" inbox consume "$id" 'handled by the person' > /dev/null
}
CASE_EXPECT=('gh-issue-posts 1' 'no-text-in-forge s206-witness-of-a-private-finding')
CASE_OBSERVE=('landed s01-greeting')
