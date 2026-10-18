# Review: s144-shape-gate-matches-ship

[Story](../stories.md) · [Plan](../plans/s144-shape-gate-matches-ship.md) · [Verification](../verif/s144-shape-gate-matches-ship.md)

Review status: complete
Fix loop: 0
Reviewed tree: dae3d47cb35e92bb5564fd2cc92b7c57cf545b8e
Lenses run: none (the diff is bash gate code, method prose, an ADR and bash tests; no path or content matches the security, migration, dependency or performance triggers)

## Scope
`git diff main...story/s144-shape-gate-matches-ship` touches 9 paths. Six are on the story's `Owns` line: `method/hooks/po-gate.sh`, `method/commands/po-review.md`, `method/commands/po-drive.md`, ADR-0096 (added), ADR-0094 (the one-line `superseded-by` change) and `tests/review-findings-shape.test.sh`. The other three are the story's own research, plan and verification record, which are in scope by construction. Nothing is outside `Owns`.

The plan's run interdicts hold:
- `.claude/`, `.polype/`, `po-ship.md`, `templates/review.md`, `reviewer.md`, `po-orchestrator.md`, `po-flow.md` and `docs/reviews/` all have an empty diff.
- The ADR-0094 diff is exactly `superseded-by: [] → [ADR-0096]`.
- In `po-gate.sh` only `findings_shape`, its header, its comment and its dispatch line change.
- The existing test functions are unchanged.

## Evidence relied on
- `Verification mode: record`. `po-gate verif-current s144-shape-gate-matches-ship` exits 0, with both the installed and the `method/` gate. The record is complete: Tree `c561c214…`, and one `bash tests/run.sh` run on that code exited 0. I did not rerun the full suite.
- The project has no `Typecheck`, `E2E` or `Build` command (all `—`), so nothing of the kind was run.
- The story does not go to QA (`QA stage: —`).
- `po-gate floor-guard s144-shape-gate-matches-ship main` exits 0: no check was made easier to pass.
- I ran the story's test file once: `bash tests/run.sh review-findings-shape.test.sh` passed 8 of 8.

## Bite (each mutation undone; `git diff --exit-code method/hooks/po-gate.sh` was clean after each)
1. Made `ships()` case-insensitive (`tolower(s) ~`): 1 test failed (`gate_accepts_only_ship_shapes`).
2. Stopped judging non-item lines (`else bad = first(l)` → `else bad = 0`): 2 tests failed (`gate_accepts_only_ship_shapes`, `gate_checks_findings_shape`).
3. Put the dispatch back to `findings_shape "${2:?story id required}"`: 1 test failed (`other_gate_failures_stop`).

## Other checks
- **Gate against `/po-ship` step 3.2.** I held the ERE against step 3.2 (`method/commands/po-ship.md`, "Which findings") and the title `sed`, then probed 16 more lines in a throwaway repo (`/tmp/tmp.7BDVINkynE`).
  - Accepted, as step 3.2 reads them: `- **major** —x`, `- **major:**x`, `* **minor** - x`, `10. major: x`, `- **major:** — x`, `Two major findings below`.
  - Refused: `- **Major** — x`, `2. Major: x`, `-  major — x`, `- major`, `Critical: x`, `**minor** — x`.
  - Under `LC_ALL=C`, `- major — x` is still accepted and `- Major — x` still refused.
- **Referenced code exists.** `refuse` (`po-gate.sh:31`), `top` (`:30`) and the dispatcher's default case (`:525`, `exit 2` for an unknown subcommand) are where the diff assumes. So the `/po-review` sentence that sends an older installed gate to "any other exit" is correct.
- **Neighbours.** The only other method file that mentions `findings-shape` is `method/agents/reviewer.md:53`, which is unaffected. `po-orchestrator` and `po-flow` belong to s145's lane, as the plan says.
- **Plan tasks.** All six are present in the diff, and the diff makes no change the plan did not ask for.
- **A missing `## Findings` still exits 1.** That is at `po-gate.sh:118`, as s141 fixed it; I checked it by reading.

## Findings
- minor — method/hooks/po-gate.sh:118 — awk's own fatal exit is 2 (gawk and mawk both), so a review file that exists but cannot be read is reported as "no '## Findings' section" and exits 1. The recording context then re-asks the reviewer as if the review were malformed, and after a second exit 1 the blocked report blames the reviewer's findings. ADR-0096 says a failed read ("lecture en échec") exits 2; only awk exits other than 0, 1 and 2 reach `shape_unreadable`. The final outcome is still a human stop, so the damage is contained. A fix is to have the awk signal "no Findings" with a code awk never uses for a fatal error (e.g. `exit 3`), and map 2 to `shape_unreadable`.

## Not verified
- **mawk / BSD awk.** Only gawk 5.4.1 (`/usr/bin/awk -> gawk`) ran the motif. Under mawk or BSD awk, the `—` alternation and the `[^A-Za-z]+` strip in `first()` were not exercised. To cover it, run `bash tests/run.sh review-findings-shape.test.sh` on a machine where `awk` is mawk.
- **The new "any other exit" path in a real session.** The prose of `/po-review` and `/po-drive` is checked by phrase only. To cover it, a person runs `/po-review` against an installed gate with no `findings-shape` subcommand and checks that the blocked report and the `/po-drive` resume row come out as described.
- **Full suite on the final tree.** I relied on the record's run on tree `c561c214…`, which `verif-current` confirms equals this code outside `docs/`. I did not rerun it myself.

Max severity: minor
Ship allowed: yes
