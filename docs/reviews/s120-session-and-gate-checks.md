# Review — s120-session-and-gate-checks

[Story](../stories.md) · [Plan](../plans/s120-session-and-gate-checks.md) · [Verification](../verif/s120-session-and-gate-checks.md)

Diff reviewed: `git diff main...story/s120-session-and-gate-checks` (merge base 9404c10; `main` has since gained 550fa73, which touches `docs/stories.md` only), in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 80d2236506a3e7f6bb437bfb170c1179b65b4b7d

## When blocked
Not blocked.

## Ownership
I listed the diff with `git diff --name-only main...story/s120-session-and-gate-checks` (one commit, ee0f0ea).
- [x] Every path is inside `Owns` (`docs/stories.md:1855`): `method/hooks/po-gate.sh`, `method/hooks/po-session.sh`, `method/AGENTS.md`, `method/commands/po-ship.md`, `tests/gate.test.sh`, `tests/review-tree-gate.test.sh` and `tests/session-and-gate-checks.test.sh`. The three files under `docs/research|plans|verif/s120-…` are this story's pipeline evidence.
- [x] No overlap with another running story. The only other lane is `s121-framing-realign-and-orchestrator-log`, which owns `po-setup.md`, `po-orchestrator.md` and its own test files, so it shares no path with this story.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s120-session-and-gate-checks` exits 0. The record (`Tree: 471472de…`, complete, `Unit suite` `bash tests/run.sh` exit 0) proves the full suite for this code, so I relied on it. The project has no type check (`Typecheck: —`), no E2E and no build. "Not proven here" lists only those three.
- [x] `po-gate qa-current`: not required. `QA stage: —` and `Surface: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–7 are all present and match the plan:
  - `paired_value` was split out of `paired_hash`, and `paired_hash` keeps the same 40-hex rule and exits 0.
  - The status is checked twice: the status paired with the last verdict, and the last status line in the file.
  - The header comment was updated.
  - The existing tests were updated as the plan listed.
  - The marker `if` is in `waiting_for_a_human`.
  - The Surface scan exists and feeds `ds="not needed"`.
  - The rule text was updated in `method/AGENTS.md:87,90` and `method/commands/po-ship.md:18`.
  - The three acceptance tests exist, and the full suite ran through `po-run`.
- [x] Each run interdict was checked:
  - `.polype/`, `.claude/` and the root `AGENTS.md` have an empty diff.
  - `project-lead`, `qa-gate`, `run-ledger` and `floor-guard` tests are untouched and green.
  - The other `po-gate` subcommands keep their behaviour; only `paired_hash` was refactored.
  - `po-session` stays read-only: one more `git show` call, and `test_session_hook_reports_state_read_only` is green.
  - No other `method/` file, `docs/stories.md` or parity file is in the diff.
  - The phrase `between that verdict and the verdict line before it` is kept in `po-ship.md`.

## References
- [x] I opened every call target and confirmed it: `on_target`, `id_re`, `refuse`, `top`, `code_matches`, `tree_exists`, `last_value`, and `scratch_repo`/`contains`/`fail` from `tests/lib.sh`.
- [x] The values have a source:
  - The marker text matches `method/commands/po-drive.md:53`.
  - `Review status: <complete | blocked>` comes from `method/templates/review.md:5`.
  - The Surface vocabulary (`screen · command · endpoint · scene · behaviour · —`) comes from `method/templates/stories.md:12`.
  - The `\bscreen\b`-style match accepts both the English `- **Surface**:` form and the French `- **Surface** :` form.
  - Treating a story with no Surface line as "may have a screen" follows Law 1 and ADR-0054.

## Rules
- [x] The `AGENTS.md` conventions are respected. Only `method/` was changed, the tests are in bash, and the code and messages are in English.
- [x] No accepted ADR is contradicted.

## Tests
- [x] Floor: `po-gate floor-guard s120-session-and-gate-checks main` exits 0 (nothing lowered), with both the installed copy and the `method/` copy.
- [x] Each acceptance criterion has a test with the same name, running the real hook on a throwaway repository. None of the six empty test shapes appears: there are no mocks and no swallowed errors, and the fixtures do not answer for the check.
- [x] There are 3 new tests, well within `Test budget: 25`.
- [x] Bite: every mutation was undone, and `git diff --exit-code` was clean after each one. The focused runs were `session-and-gate-checks`, `gate`, `review-tree-gate`, and `project-lead` for the session rules.

  | Rule disabled | Failing tests |
  | --- | --- |
  | Whole status condition in `ship_allowed` → `true` | 1 (`ship_gate_needs_review_status`, "no status line shipped") |
  | Only the file's-last-status half dropped | 1 ("blocked status written after the verdict was ignored") |
  | Only the paired-status half dropped | 1 ("appended review borrowed the status") |
  | Marker `grep` in `po-session` → `false` | 1 (`session_flags_a_technical_choice`) |
  | `!unknown` dropped from the Surface scan | 2 (`design_system_only_with_a_screen`, `project-lead` `session_hook_reports_state_read_only`) |
  | The `screen` match → never sets `scr` | 1 (`design_system_only_with_a_screen`) |

- [x] No test was made useless. The existing gate tests were changed only so that each refusal still fails for its own reason.

## Neighbours
- [x] I read the other callers of `paired_hash`, which are `verif_current` (`po-gate.sh:83`) and `qa_current` (`:161`). Their tests (`qa-gate`, `run-ledger`, `review-tree-gate`) are green: 58/58 in the focused run.
- [x] I read the prose that restates the ship gate: `po-drive.md:64,146`, `po-status.md:30`, `reviewer.md:27` and `AGENTS.md:137`. The first finding below comes from this.

## Lenses
Lenses run: security — the path `method/hooks/po-session.sh` names "session", and `po-gate.sh` holds a check on who may ship. Nothing exploitable: both scripts read local files and git refs, with no input-supplied URL, no upload and no outside call. No lens finding.
- [x] No lens finding to grade.

## Findings
- major — `method/commands/po-drive.md:64` and `:146` (outside `Owns`) — The fleet's resume table now disagrees with the stricter gate.
  - A review with last `Ship allowed: yes` and a current tree but no `Review status: complete` matches no "back to review" row. That row only covers a refused `Reviewed tree:`.
  - So the lane falls to the row "the ship", and `/po-ship` Step 0 stops it with "Run /po-review <id>". The next wave lands on the ship row again, with no automatic re-review.
  - The prose at `:146` still describes `ship-allowed` as verdict plus tree only.
  - This is exactly the case the story was written for (status omitted three times in M9 bis). No damage goes unnoticed, because the ship is refused, but the lane gets stuck in a loop until someone steps in.
  - Fix: widen the `:64` row to "refuses the review", whatever the reason, and add the status to `:146`. This needs an `Owns` widening or a follow-up story.
- minor — `method/AGENTS.md:87` — The Law 3 row says only "the `Review status:` of that review says `complete`". The gate also refuses when the file's last `Review status:` line (after the verdict) is not `complete`. `po-ship.md:18` states both conditions; the Law 3 row understates the rule.
- minor — `method/hooks/po-gate.sh:35-37` — The comment "The hash of the block … the hash must be 40 hex …" now sits above `paired_value`, which returns the raw value. The hash rule lives in `paired_hash` (`:47`), which has no comment. The comment should be split or moved.

## Not verified
- **The installed copies `.polype/hooks/po-gate.sh` and `po-session.sh` still hold the old rules.** By convention, this story changes only `method/`. Until the installer refreshes them (`bin/polype-dev-install .` / `polype update`), this repository's real gate does not require `Review status:`. A person should refresh the installed copies after the ship and run `po-gate ship-allowed` on a status-less review to see it refused.
- **Real projects were not checked.** I did not run `po-session` against nautile, the real screenless project named in the story, or against Polype's own `docs/stories.md`. Only the throwaway fixtures were exercised. A person should run `CLAUDE_PROJECT_DIR=~/dev/atoll/nautile bash method/hooks/po-session.sh` and confirm that it prints `design system not needed` and `Framing next: none — framing done` (or the earlier step that is really missing).
- **The Surface scan was not tested on unusual Markdown.** I did not test story headings inside fenced code blocks, or a Surface value written `screens` (plural). The template only uses `screen`, and the regex would not match the plural.
- **No type check, E2E or build exists in this project** (`Typecheck`, `E2E`, `Build` are `—`), so none was run.
- **I did not rerun the full suite myself.** I relied on the current verification record (exit 0), as `Verification mode: record` allows. I ran only the focused suites listed above.

Max severity: major
Ship allowed: yes
