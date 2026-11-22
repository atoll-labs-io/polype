#!/usr/bin/env bash
# s134 — everything to handle is an issue.

LAW="$METHOD/AGENTS.md"
SHIP="$METHOD/commands/po-ship.md"

section_of() { awk -v h="$2" '$0 == h {on=1; next} /^## / {on=0} on' "$1" | tr -s '[:space:]' ' '; }

has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

holds() { has "$1" "$2" || fail "$3 lacks: $2"; }

test_security_goes_to_the_person() {
  local step3
  step3="$(section_of "$SHIP" '## Step 3 — Cleanup, only after proof')"
  holds "$step3" '"not filed: security (ADR-0077)"' "po-ship Step 3"
  holds "$(section_of "$LAW" '## Law 7 — Defects are not stories')" \
    'A security finding or a security idea is never filed on its own: it goes to the person' "Law 7"
}

test_finding_text_never_enters_a_command() {
  holds "$(section_of "$LAW" '## Law 7 — Defects are not stories')" \
    'Whoever files, the text never travels inside a shell argument' "Law 7"
}
