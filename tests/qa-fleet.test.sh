#!/usr/bin/env bash
# s57 — the fleet runs QA for a story that goes to QA (s80), and a review blocked on QA goes back to QA.
# s64 — blocked on QA needs `Review status: blocked`, every command routes it alike, and a current uncommitted report is committed, not walked.

test_drive_resumes_on_an_uncommitted_report() {
  contains "$METHOD/hooks/po-gate.sh" 'is current but docs/qa/$1/ is not committed'
}
