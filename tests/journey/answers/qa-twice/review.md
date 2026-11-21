Diff reviewed: `git diff main...story/@ID@`, a written answer of the replayed journey, not a review.

Review status: blocked
Fix loop: @LOOP@
Reviewed tree: @TREE@

## When blocked
- Failure cause: the QA report under review does not cover the criterion its walk was asked to reach.
- Missing: a QA walk that reaches `src/@ID@.txt`.
- Required adaptation: the walk is run again on the code under review.
- Next action: /po-qa @ID@ — the walk is run again before this review.

## Findings
- major — src/@ID@.txt:1 — the QA walk never reached the text the story writes.

## Not verified
Everything a reviewer reads: this verdict is written in advance.

Max severity: major
Ship allowed: no
