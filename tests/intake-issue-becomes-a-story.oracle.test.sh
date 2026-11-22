#!/usr/bin/env bash
# s152 — the oracle of the story: an issue po-intake filed becomes a story that fixes it,
# reviewed on its issue and landed as framing, security staying with the person (ADR-0099).

INTAKE="$METHOD/commands/po-intake.md"

# Whitespace collapsed, so a phrase holds whatever the line wrapping.
flat() { tr -s '[:space:]' ' ' < "$1"; }
holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_security_issue_goes_to_the_person() {
  require_file "$INTAKE"
  local t; t="$(flat "$INTAKE")"
  holds "$t" 'An issue whose text bears on security — a secret or a token, an authorization or tenant check, an injection — gets no story' "po-intake.md"
  holds "$t" 'it goes to the person (ADR-0090)' "po-intake.md"
  holds "$t" 'in doubt, it bears on security' "po-intake.md"
  holds "$t" 'no issue text enters a shell argument' "po-intake.md"
}
