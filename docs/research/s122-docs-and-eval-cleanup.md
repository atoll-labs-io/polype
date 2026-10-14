# Research — s122-docs-and-eval-cleanup

[Story](../stories.md)

## Structuring facts
- Root cause (the one major): `method/commands/po-drive.md:64` sends back to review only a favourable review whose `Reviewed tree:` the gate refuses, while `method/hooks/po-gate.sh:68-71` (s120) also refuses a missing or non-`complete` `Review status:`. A review `Reviewed tree: <current>` + `Ship allowed: yes` with no status matches no row before `:67` "the ship", and `/po-ship` Step 0 stops it — the loop the s120 review describes. Reproduced (see `## Diagnostic`).
- Root cause (the minors): texts left behind by the stories that changed the rule under them — `docs/installation.md:10` still cites the superseded ADR-0073; `bin/po-eval:84` keeps a pre-s116 message; `evals/cases/rebuilt-helper.sh:51` predates s119's third test; `method/commands/po-status.md:31` keeps the arrow `→ shipped` after s112's sentence; `method/commands/po-status.md:21` predates po-session's `not needed` (s120); `method/AGENTS.md:87` and `method/hooks/po-gate.sh:35-37` predate s120's final shape.
- Trap outside `Owns`: `tests/drive.test.sh:84` locks the exact phrase of `po-drive.md:146` ("the **last** `Ship allowed:` line … must still match the code outside `docs/`"). The status must be **added after** that phrase, never inserted inside it.
- No assumption of the story is false. One date is unproven: the story calls the `CLAUDE.local.md` decision "du 2026-10-14"; `docs/decisions-log.md:40` records the owner's approval under 2026-10-13 (see Open questions).

## Diagnostic
Reproduction (temp repo under `mktemp -d`, nothing written in the worktree): a review holding only `Reviewed tree: <HEAD tree>` and `Ship allowed: yes`; `bash method/hooks/po-gate.sh ship-allowed s1-x` → exit 1, "the review of s1-x has no 'Review status: complete' line for its last verdict — /po-review s1-x". Reading `po-drive.md:52-70` top-down with that review: no row before `:64` matches (record current, review present, not blocked, last verdict `yes`); `:64` names only the `Reviewed tree:` refusal; the next rows need an open/closed PR; `:67` "the ship" matches. `/po-ship` Step 0 (`method/commands/po-ship.md:18`) refuses → next wave, same row.
- H1 "the gate does not actually refuse a status-less review" — refuted by the reproduction above. Discarded.
- H2 "an earlier resume row already catches it" — refuted by reading `:52-68`: the only rows naming `Review status:` are `:62` (`blocked` + `Next action:`) and none for a missing one. Discarded.
- H3 "`:64` covers it because a status-less review is read as a tree refusal" — refuted: `:64` reads "refuses its `Reviewed tree:`" and `:76` explains it as "code was committed after the verdict". Kept as root cause: the row and its prose name one refusal reason out of two.
The minors are not behaviour defects; each was reproduced by reading the cited line on this tree (`git log -1` = 38b3fbf).

## Story
Seven criteria (test names = criteria names, in `tests/docs-and-eval-cleanup.test.sh`):
1. `installation_cites_adr_0086` — installation doc cites ADR-0086, not ADR-0073, says a `CLAUDE.local.md`, even private, moves into the committed `AGENTS.local.md`; `install_writes_no_claude_md` renamed with an honest message.
2. `drift_message_fits_the_mode` — under `--control`, the drift refusal says it guards the real install.
3. `recipe_plan_counts_three_tests` — "The three tests" in the built plan's Done when; `test_demo_app_unchanged` keeps only `get()`, `list_for()`, `missing-tenant-filter`, no recipe count.
4. `status_shipped_rule_reads_once` — no double "shipped"; shared sentence verbatim.
5. `status_design_system_matches_session` — `/po-status` says `design system not needed` exactly when po-session does, and then proposes no `/po-design-system`.
6. `drive_resumes_a_review_the_gate_refuses` — resume row covers any refusal of a `Ship allowed: yes` review; ships text cites the status.
7. `law3_row_states_both_status_checks` — Law 3 row states both status checks; gate's hash comment sits above `paired_hash`.

## Current code
- `docs/installation.md:9-10` "Aucun `CLAUDE.md` : Claude Code lit `AGENTS.md` de lui-même (ADR-0073)." `:185-192` describes the absorption (ADR-0086) and names `CLAUDE.local.md` but never says it may be private nor that `AGENTS.local.md` is committed. No other `ADR-0073` in the file.
- `tests/install.test.sh:46-54` `test_install_writes_no_claude_md`: checks install creates no `CLAUDE.md`, then that a `CLAUDE.md` with notes is left unchanged — true only because the scratch project has no `AGENTS.local.md` (`bin/polype:245-246`). Message "install touched the project's own CLAUDE.md". Its second half overlaps `:56-64` (legacy import test).
- `bin/po-eval:63-86` `drift_check`, called once at `:190`, before the login check `:192` and with `$control` already parsed (`:156-163`). On drift: `:84` "a user-level copy would shadow the method under test; run bin/polype update --global", exit 2. Header `:15-19` says both control arms run on temporary configs.
- `evals/cases/rebuilt-helper.sh:47-51` test strategy names three tests; `:51` "Both tests pass with the rest of the suite; the record is complete." (`evals/lib.sh:292` and `evals/cases/missing-tenant-filter.sh:51` hold the same line, rightly: two tests there.)
- `tests/rebuilt-helper-single-defect.test.sh:36-48` `test_demo_app_unchanged`: get's owner check, list_for's filter, the archive story heading in `evals/lib.sh`, three cases using the archive story/plan, rebuilt-helper not using them, `missing-tenant-filter` holding `if note.shared]`, and `ls … | wc -l = 8`.
- `method/commands/po-status.md:31` "- shipped: <shared sentence> → shipped; an open pull request from `story/<id>` → waiting for merge;". `:21` "`docs/design-system.md` present or not." `:42` "Finish with the single most useful command".
- `method/hooks/po-session.sh:53-62` `no_story_has_a_screen`: stories exist, each has a `- **Surface**` line, none matches `screen` as a word; `:88-96` → `design system not needed`, and `Framing next` never `/po-design-system` then.
- `method/commands/po-drive.md:64` (row), `:76` (prose "A favourable review whose `Reviewed tree:` the gate refuses means code was committed after the verdict…"), `:146` (ships: verdict + tree only).
- `method/AGENTS.md:87` Law 3 row: "…says `yes`, the `Review status:` of that review says `complete` **and** the review's `Reviewed tree:` matches…". `po-ship.md:18` states both status lines; gate `po-gate.sh:68-71` checks `pstatus` (paired with the last verdict) and `lstatus` (file's last).
- `method/hooks/po-gate.sh:35-37` comment (pairing + "the hash must be 40 hex…") above `paired_value` (`:38-45`, returns the raw value); `paired_hash` (`:47-54`) applies the 40-hex rule, uncommented.

## Attachment points
`docs/installation.md:9-10,185-192`; `tests/install.test.sh:46`; `bin/po-eval:84`; `evals/cases/rebuilt-helper.sh:51`; `tests/rebuilt-helper-single-defect.test.sh:36-48`; `method/commands/po-status.md:21,31`; `method/commands/po-drive.md:64,76,146`; `method/AGENTS.md:87`; `method/hooks/po-gate.sh:35-47`; new `tests/docs-and-eval-cleanup.test.sh`.

## Verified interfaces
- Test helpers: `tests/lib.sh` gives `$ROOT`, `$METHOD`, `fail`, `contains`, `require_file`, `scratch_repo`; `tests/run.sh` runs each `test_*` in its own bash.
- Eval test harness: `tests/eval-arms-same-environment.test.sh:4` reuses `source <(sed '/^test_/,$d' "$ROOT/tests/reuse-ladder-eval.test.sh")` → `rl_setup`, `rl_run <answer> <args…>` (sets `RL_STATUS`, `RL_OUT`), `rl_calls`. Drift is made with `echo "# drift" >> "$RLTMP/cfg/agents/reviewer.md"` (`tests/reuse-ladder-eval.test.sh:110`); drift exits before any claude call.
- `tests/short-subject-shipped.test.sh:5` holds the shared sentence as `SENTENCE`; `:26-29` checks it in `po-status.md` and `po-drive.md`.
- `tests/ship.test.sh:40-41` only needs `Reviewed tree:` in the Law 3 row.

## Traps
- `tests/drive.test.sh:84` (not owned) locks the `:146` phrase; `tests/short-subject-shipped.test.sh:5` (not owned) locks the shared sentence; `tests/reuse-ladder-eval.test.sh:111-113` (not owned) greps `agents/reviewer.md differs` on a `--control` drift — the per-file lines at `:67,:76,:80` must stay.
- `po-gate floor-guard` counts removed lines matching `assert`/`expect(` in test files: none of the lines dropped from `test_demo_app_unchanged` holds either.
- Root `AGENTS.md`, `.claude/`, `.polype/` are installed copies (AGENTS.local.md conventions): the Law 3 change goes in `method/AGENTS.md` only; the lead refreshes copies after ship.
- `tests/overlap.test.sh` fails on 8+ words shared with Killer SaaS: new text in own words.
- No migration. `po-status.md:30` has the same blind spot as `po-drive.md:64` (a `yes` refused for its status is not "stale"); not in the criteria — see Open questions.

## Open questions
- Date of the owner's decision: story says 2026-10-14, `docs/decisions-log.md:40` says 2026-10-13. The plan cites the decision through `docs/decisions-log.md` without a date, so neither can be written wrong.
- `po-status.md:30` review bullet: widen "stale" to any refusal of `ship-allowed`? Same file is owned, but no criterion asks; left out, reported.

## Complexity
Story 2 → 3: seven criteria across nine files, one real resume-table behaviour fix, and two text locks outside `Owns` to step around. Still no code path beyond one message branch in `bin/po-eval`.

## Split
—
