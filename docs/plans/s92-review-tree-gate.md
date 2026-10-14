---
track: flow
validated: yes
---
# Plan (short track) — s92-review-tree-gate

[Story](../stories.md)

Written by the planner on the short track (`Story track: auto`, complexity 2 ≤ `Flow threshold` 2). This file stands in for both research and plan: there is no `docs/research/s92-review-tree-gate.md`. Built on the story as revised by `83b446d`. Decision recorded in ADR-0056 (`docs/decisions/ADR-0056-le-hash-d-une-gate-est-lu-dans-le-bloc-de-son-dernier-verdict.md`). Validated autonomously (`Plan validation: autonomous`); no human reviewed it.

## Verified facts
- **The last s78 review still fails, even with the revised criterion.** `git show story/s78-platform-setting:docs/reviews/s78-platform-setting.md`: line 8 is `- Reviewed tree: 45a5…909 (taken again just before answering: unchanged)` (a blank space after the hash, so it is now read), but line 97, which belongs to the **last** review, is `- Reviewed tree: f885…368. I took it again…`: a full stop is stuck to the hash. Criterion 2 accepts only "texte séparé du hash par une espace", so that review is still refused; that is the reading this plan keeps (ADR-0056). The s78 review is not unblocked by s92 alone.
- `first_hash` (`method/hooks/po-gate.sh:34`) returns the **first** `<label>:` line holding exactly a 40-hex hash and nothing after it but blanks, skipping unusable ones; used by `ship_allowed` (:48), `verif_current` (:59), `qa_current` (:137).
- `ship_allowed` reads the **last** `^Ship allowed:` line (:45) and checks it against `^Ship allowed:[[:space:]]*yes[[:space:]]*$` (:46); a bulleted verdict line is invisible to it. `tests/gate.test.sh:36` requires `Ship allowed: yes, once fixed` to stay refused.
- `qa_current` reads the last `^QA status:` line (:134); `verif_current` accepts any `^Verification status:[[:space:]]*complete` line (:57). Both status readings stay as they are (not in the ACs).
- Templates put the hash before the verdict: `method/templates/review.md` (`Reviewed tree:` in the header, `Ship allowed:` last), `method/templates/qa.md:28-29`, `method/templates/verification-record.md:7,22`. So does every fixture running the three gates: `tests/gate.test.sh:30,84`, `tests/qa-gate.test.sh:25,56`, `tests/run-ledger.test.sh:79,115,124`, `evals/lib.sh:227,240`.
- Stacking is real: `po-review.md:36` says "write the subagent's answer, whole", yet the s78 file holds two reviews, each ending with `Max severity:` / `Ship allowed:` (lines 83-84, 192-193).
- `method/commands/po-ship.md:18` (Step 0, the no-hook check) says "the **last** line starting with `Ship allowed:`" and "the 40-hex hash on its first `Reviewed tree:` line". `tests/ship.test.sh:49-51` require Step 0 to keep `Reviewed tree:` and `':(exclude)docs'`; `tests/drive.test.sh:84` quotes `po-drive.md`, not `po-ship.md`.
- `bin/po-eval` reads no tree. Its `grade` (:96-104) takes `grep -E '^Ship allowed:' | tail -n 1` (:100) and matches `^Ship\ allowed:[[:space:]]*(yes|no)[[:space:]]*$` (:102); its header (:10-11) promises to read the verdict "as strictly as po-gate reads them". `tests/evals.test.sh:132` requires `**Ship allowed:** no` to grade `no verdict`. `grade` is a standalone function, so it can be extracted with `sed -n '/^grade() {/,/^}/p'` and called on a file.
- The gate's awk avoids `{n}` for mawk/BSD awk (`po-gate.sh:255-256`); hash shape is checked as `length == 40 && /^[0-9a-f]+$/` in `record_rows` (:97).
- Tests asserting text of `po-gate.sh`: `tests/qa-fleet.test.sh:185`, `tests/distribution-wiring.test.sh:145` ("on every branch").
- A prototype of task 1-2 in a scratch copy kept `gate.test.sh`, `qa-gate.test.sh`, `run-ledger.test.sh` green (41 tests) and answered as expected on 16 cases: stacked reviews, unfinished appended review, `- `/`* ` accepted, `-  `/`+ `/indented refused, `<hash> (remark)` and `<hash><TAB>note` accepted, `<hash>.`/abbreviated+text/41 hex refused, `Ship allowed: yes, once fixed` refused, bulleted `no` after `yes` refused.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text: no data store | absent — `po-gate.sh`, `po-eval` read markdown only |
| New screen | absent — `Surface: —` | absent — shell scripts and one command text |
| Authorization or tenant scope | absent — story text | absent — the gate decides a ship, but no role or tenant is involved |
| API contract | absent — subcommands unchanged | absent — `po-gate.sh:423-431` and `po-eval` usage (:6-8) unchanged: arguments, exit codes, output |
| New dependency | absent — story text | absent — bash, sed, awk, grep already used |

## The pivot
Which hash belongs to the verdict, and where a hash ends. Chosen: the **last** `<label>:` line after the second-to-last verdict line and before the last one; missing or unusable → refuse, never fall back; a hash ends at end of line or at a blank (ADR-0056). Ways it could be wrong: (1) a report writing its tree **after** its verdict — compare with the three templates and the fixtures above, all tree-first; (2) a review quoting an older `Reviewed tree:` after its own — the quote wins and the gate refuses (safe side); (3) the remark tolerance leaking to the verdict — `Ship allowed: yes, once fixed` must stay refused (`gate.test.sh:36`); (4) `po-ship.md` and `po-eval` drifting from the gate — the AC3 test pins both.

## Story
`po-gate ship-allowed` reads the tree of the same review as the verdict it keeps, and accepts those lines as list items.
- `ship_gate_reads_the_last_review` — with stacked reviews, the `Reviewed tree:` of the last review (the one holding the last `Ship allowed:`) is used, not the first of the file.
- `verdict_lines_may_be_list_items` — `Reviewed tree:` or `Ship allowed:` preceded by `- ` or `* ` reads as the line without it, and text separated from the hash by a blank after it does not stop it being read; any other form stays refused (indentation, other bullet, incomplete hash).
- `other_tree_lines_read_the_same_way` — `Tree:` lines of the record and of the QA report follow the same rule as `Reviewed tree:`, and `/po-ship` (no-hook check) and `bin/po-eval` describe or read these lines the same way.

## Tasks
1. [x] **Shared reader in `method/hooks/po-gate.sh`.** Replace `first_hash` (:33-34) with `paired_hash <label> <verdict ERE> <file>`, one awk pass: a line opening with exactly `- ` or `* ` at column 0 is read without it; a line then starting with `<label>:` sets the candidate to its value with leading blanks trimmed; a line matching the verdict ERE closes a block (candidate → final, candidate cleared); at the end, print the first 40 chars of final only if a block was closed, they are all `[0-9a-f]` (checked as `length == 40 && /^[0-9a-f]+$/`, no `{40}`, see :255-256), and final is exactly 40 chars long or its 41st char is `[[:space:]]`. One- or two-line comment on the *why*. Update header lines 5-10 (tree of the review/report/record carrying the last verdict); keep line 11's "on every branch". — Fails: `test_ship_gate_reads_the_last_review`, `test_verdict_lines_may_be_list_items`.
2. [x] **The three call sites.** `ship_allowed` (:42-52): verdict via `grep -E '^([-*] )?Ship allowed:' | tail -n 1`, bullet stripped before the unchanged `=~` check of :46 (no text after `yes`); tree via `paired_hash 'Reviewed tree' '^([-*] )?Ship allowed:'`. `verif_current` (:59): `paired_hash 'Tree' '^Verification status:'`. `qa_current` (:137): `paired_hash 'Tree' '^QA status:'`. Status readings (:57, :134-135) and every refusal message unchanged. — Fails: all three AC tests.
3. [x] **The two other readers.** `method/commands/po-ship.md:18`, Step 0, no-hook sentence: say the last line starting with `Ship allowed:`, a leading `- ` or `* ` allowed, must read `Ship allowed: yes`; and the hash comes from the last `Reviewed tree:` line between that verdict and the verdict line before it (same leading `- ` or `* `), a full 40-hex hash alone or followed by a blank and a remark; keep `Reviewed tree:`, `':(exclude)docs'` and the stop message verbatim. Must contain the exact phrase `between that verdict and the verdict line before it`. `bin/po-eval:100`: `grep -E '^([-*] )?Ship allowed:' | tail -n 1 | sed 's/^[-*] //'`; regex :102 and `Max severity:` reading unchanged; header :10-11 stays true. — Fails: `test_other_tree_lines_read_the_same_way`.
4. [x] **`tests/review-tree-gate.test.sh`** (new, header `# s92 — …`), three functions named after the ACs, on throwaway repos via `scratch_repo` (`tests/lib.sh`), calling `bash "$METHOD/hooks/po-gate.sh"` as `tests/gate.test.sh:4,15`. Two commits give an old tree T1 and the HEAD tree T2.
   - `test_ship_gate_reads_the_last_review`: `T1 / Ship allowed: no / T2 / Ship allowed: yes` passes (today refused); `T2 / Ship allowed: no / Ship allowed: yes` (last review without tree) refused; `T1 / Ship allowed: yes / T2` with no closing verdict refused.
   - `test_verdict_lines_may_be_list_items`: `- Reviewed tree: T2 (taken again just before answering: unchanged)` + `* Ship allowed: yes` passes; `Ship allowed: yes` then `- Ship allowed: no` refused; each of `  - Reviewed tree: T2`, `+ Reviewed tree: T2`, `Reviewed tree: <T2 first 12> (short)`, `- Reviewed tree: T2. I took it again` refused.
   - `test_other_tree_lines_read_the_same_way`: a record `- Tree: <write-tree> (after git add -A)` with a Checks table of only `—` rows (shape of `gate.test.sh:82-87`) passes `verif-current`; a committed QA report `* Tree: T2` / `QA status: complete` passes `qa-current`, and one stacking `Tree: T2 / QA status: blocked / Tree: T1 / QA status: complete` is refused; `contains "$METHOD/commands/po-ship.md" 'between that verdict and the verdict line before it'`; `grade`, extracted from `bin/po-eval` with `source <(sed -n '/^grade() {/,/^}/p' "$ROOT/bin/po-eval")`, prints `critical/no` for a file `Max severity: critical` / `Ship allowed: yes` / `- Ship allowed: no`.
   Run alone: `bash tests/run.sh review-tree-gate.test.sh gate.test.sh qa-gate.test.sh run-ledger.test.sh ship.test.sh evals.test.sh`.
5. [x] **Record and suite.** Set row 35 of `docs/defauts.md` to `corrigé par s92`. Full suite once through `po-run --story s92-review-tree-gate --label 'Unit suite' -- 'bash tests/run.sh'` (`Full suite: execute-end`); `Typecheck: —`, say so in the record.

## Run interdicts
- `method/templates/*`, `method/agents/reviewer.md`, `method/commands/po-drive.md`, `method/commands/po-review.md`, `evals/`: empty diff.
- `.claude/` and `.polype/`: empty diff (installed copies; never refresh them in this story).
- `po-gate.sh` outside `first_hash`, `ship_allowed`, `verif_current`, `qa_current` and the header comment: empty diff (`record_rows`, `runs_cover_checks`, secret scan, floor guard, pre-commit untouched).
- `po-ship.md`: only the Step 0 no-hook sentence changes. `bin/po-eval`: only line 100 changes.
- No widening beyond the criteria: no indent, no `+ `, no numbered list, no bold, no punctuation stuck to the hash, no text after `Ship allowed: yes`; `QA status:`, `Verification status:`, `Max severity:` stay unbulleted.
- No existing test in `tests/gate.test.sh`, `tests/qa-gate.test.sh`, `tests/ship.test.sh` or `tests/evals.test.sh` edited; the new behaviour lives in the new file.
- `docs/stories.md` and the ADR-0056 file: not edited by the implementer.

## Files touched
- `method/hooks/po-gate.sh`, `method/commands/po-ship.md`, `bin/po-eval`
- `tests/review-tree-gate.test.sh` (new)
- `docs/defauts.md` (row 35 status), `docs/verif/s92-review-tree-gate.md`
- already written by the planner, committed with the code: this plan and `docs/decisions/ADR-0056-…md`

## Test strategy
Three tests, one per acceptance criterion, at the only layer there is: the scripts run on throwaway files and repositories (well under `Test budget` 25). Each one bites: restoring first-hash reading fails the first; dropping the bullet strip, or the blank boundary after the hash, fails the second; leaving `first_hash` on `Tree`, the old `po-ship.md` sentence, or the old `po-eval` grep fails the third. Existing `gate.test.sh`, `qa-gate.test.sh`, `run-ledger.test.sh`, `ship.test.sh`, `evals.test.sh` cover the unchanged refusals (abbreviated, unknown, missing tree; last verdict; qualified verdict; bold verdict in `po-eval`) and must stay green unmodified.

## Done when
One commit on `story/s92-review-tree-gate` carrying the three changed files, the new test file, this plan, ADR-0056, the defect row and a complete record; `bash tests/run.sh` green through `po-run`; a review with no open critical finding; shipped as one squash `s92-review-tree-gate: La gate lit l'arbre de la dernière revue`.
