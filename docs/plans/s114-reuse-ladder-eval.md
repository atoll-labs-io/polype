---
validated: yes
---
# Plan — s114-reuse-ladder-eval

Branch `story/s114-reuse-ladder-eval`. Read `docs/research/s114-reuse-ladder-eval.md` first; this plan builds on it without repeating it.

## Story
Deliver the tool that measures s113's reuse rule (`method/skills/review-antihallu/SKILL.md:38`) against a control arm whose only instruction is `Follow YAGNI.`. The rates themselves are not delivered here: the person runs the paid calls after ship.
- `eval_plants_a_rebuilt_helper` — a case whose diff rebuilds a helper of `app/notes.py`, expecting `major` and ship `yes`, with nothing in the built repository naming the flaw. `tests/evals.test.sh` counts the new kind.
- `eval_has_a_yagni_control_arm` — `po-eval --control` runs the same cases on both arms and prints the two rates side by side. `tests/run.sh` makes no paid call.
- `control_arm_never_touches_the_global_install` — the control arm installs into a temporary `CLAUDE_CONFIG_DIR` that is removed at the end, and `~/.claude/` is never modified. `drift_check` still checks the real install.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Case `rebuilt-helper` (story, plan, research, record) | Already in this repository: `eval_archive_story`, `eval_archive_plan` (`evals/lib.sh:250-294`), `eval_story` (`evals/lib.sh:154-173`) | — (only `plant` is new: no existing plant adds a separate helper that copies `get`) |
| Build, launch and grade for one arm | Already in this repository: the body of the run loop (`bin/po-eval:153-168`), moved into a function that both arms call | — |
| Control install | Already in this repository: `bin/polype install --global` under `CLAUDE_CONFIG_DIR` (`bin/polype:30,78-90`), run from a copy of `bin/` + `method/` + `evals/` | — |
| Swapping the sentence | Standard platform: `awk` on the copied `SKILL.md` | Nothing in the repository rewrites one line of a method file |
| Temp dirs and cleanup | Standard platform: `mktemp -d` plus a `trap … EXIT`, as `tests/evals.test.sh:3-4` already does | — |
| A fake `claude` that inspects its environment | New code, in the new test file | `fake_claude` (`tests/evals.test.sh:12-22`) records argv only and is local to that file. Sourcing that file would rerun its `test_*` functions (`tests/run.sh:11-17`) |

No new option beyond `--control`. No setting, no dependency.

## Tasks
1. [x] **Case `evals/cases/rebuilt-helper.sh`.** It follows the shape of `evals/cases/untested-guard.sh`:
   - declarations: `CASE_KIND=rebuilt-helper`, a one-line `CASE_DEFECT`, `CASE_EXPECT_SEVERITY=major`, `CASE_EXPECT_SHIP=yes`, `CASE_PRESSURE=""` and `CASE_STORY_ID=s01-archive-note`;
   - `story` and `plan` call `eval_archive_story` and `eval_archive_plan`;
   - `plant` appends to `NoteStore` a private method `_owned(self, user, note_id)` whose body is `get`'s lookup and owner check line for line (`evals/lib.sh:72-75`), and an `archive` that calls `_owned`, sets `archived` and returns the note;
   - `plant` adds both tests of the plan: `test_owner_archives_note`, and `test_archive_refuses_other_users`, which asserts `Forbidden` and that note 1 stays unarchived.

   The guard is therefore correct and tested, and the rebuilt helper is the only finding. No identifier or comment in the plant says "duplicate", "copy" or "rebuilt".
   Test: `test_eval_plants_a_rebuilt_helper` fails if the plant stops copying `get`'s body, if it calls `self.get(`, or if the expectations change.
2. [x] **`tests/evals.test.sh` counts the kind.** At `:67` and `:72`, add `rebuilt-helper` to both kind lists. At `:70`, change the count from `4` to `5`. In the regex at `:80`, add `duplicat|rebuil`. This changes an existing test because this story changes the clause it checks. The loop then builds the case and checks its plan gate, its record, that it touches `app/notes.py`, that it names nothing, and that the floor guard stays clean (exit 0).
   Test: `test_each_recipe_plants_one_known_defect` fails if the case is missing, misnamed, or lowers a check.
3. [x] **`bin/po-eval`: the control payload.**
   - Add a top-level constant for the s113 prefix, `New code that an existing helper you can cite by`, and a function `control_setup <dir>`.
   - `control_setup` copies `bin/`, `method/` and `evals/` of `$POLYPE_ROOT` into `<dir>/polype`. With `awk`, it replaces in the copy of `method/skills/review-antihallu/SKILL.md` the one line that starts with the prefix by exactly `Follow YAGNI.`. If that line is not found exactly once, it exits 2 with a message saying the sentence moved.
   - It then runs `CLAUDE_CONFIG_DIR=<dir>/config bash <dir>/polype/bin/polype install --global >/dev/null`.
   - `grade`, `drift_check`, `launch_message` and `--build` keep their contracts (`tests/review-tree-gate.test.sh:63`, `tests/run-ledger.test.sh:172`).

   Test: `test_eval_has_a_yagni_control_arm` (the control call sees `Follow YAGNI.` in both copies and not the prefix).
4. [x] **`bin/po-eval`: the `--control` run.**
   - Parse `--control` (`:106-117`) and document it in the header and in `usage`.
   - With `--control`:
     - after `drift_check` (unchanged, on the real config) and before the prompt, refuse with exit 2 when both `ANTHROPIC_API_KEY` and `CLAUDE_CODE_OAUTH_TOKEN` are empty. The message says that the temporary config dir holds no login and names `claude setup-token`. Credentials are never copied or linked.
     - the announcement becomes `N cases × R repetitions × 2 arms = T runs of claude -p`.
     - after confirmation, `ctl="$(mktemp -d)"`, `trap 'rm -rf "$ctl"' EXIT`, then `control_setup "$ctl"`.
   - Move `:154-167` into `run_arm <po-eval> <config-or-empty> <out-prefix>`, which builds with the given po-eval, launches `claude` (with `CLAUDE_CONFIG_DIR` set when a config is given), removes the repository and prints the label.
   - Each repetition runs the rule arm (`$POLYPE_ROOT/bin/po-eval`, inherited config, `$results/<case>/<n>`), then, under `--control`, the control arm (`$ctl/polype/bin/po-eval`, `$ctl/config`, `$results/<case>/<n>.control`).
   - Without `--control`, the output stays the same, byte for byte.
   - With it, one line per case: `<case>: rule P/R (X%) | control Q/R (Y%) — expected S/H; rule got …; control got …`.

   Tests: `test_eval_has_a_yagni_control_arm` and `test_control_arm_never_touches_the_global_install`.
5. [x] **`tests/reuse-ladder-eval.test.sh`.** It has its own temp dir and an `EXIT` trap. Its fake `claude` sits first on `PATH`. At each call it appends `cfg=$CLAUDE_CONFIG_DIR`, the count of `Follow YAGNI.` and of the prefix in `$CLAUDE_CONFIG_DIR/skills/review-antihallu/SKILL.md` and in `$PWD/.claude/skills/review-antihallu/SKILL.md`, then a `---` separator, and it prints `Max severity: major` / `Ship allowed: yes`. Every run pins `TMPDIR`, `HOME=<tmp>/home`, `CLAUDE_CONFIG_DIR=<tmp>/cfg` (a copy of the method's reviewer and of its preloaded skills, so the drift check passes for real), and `ANTHROPIC_API_KEY=test` unless the test unsets it.
   - `test_eval_plants_a_rebuilt_helper`: the case declares `major`/`yes`. Built with `--build`, its `git diff main...story/s01-archive-note -- app/notes.py` has no removed line. Its added lines contain `note = self._notes[note_id]` and `if note.owner_id != user.id:`, and none of them contains `self.get(`. The test diff adds an `assertRaises(Forbidden)`.
   - `test_eval_has_a_yagni_control_arm`:
     - answering `n` to `--control --repeat 1 rebuilt-helper` gives the announcement `1 cases × 1 repetitions × 2 arms = 2 runs` and zero calls;
     - answering `y` gives two calls. In the first, the project copy holds the prefix and no `Follow YAGNI.`. In the second, the config copy and the project copy both hold `Follow YAGNI.` and not the prefix;
     - the output holds `rebuilt-helper: rule 1/1 (100%) | control 1/1 (100%)`;
     - `tests/run.sh` does not mention `po-eval`.
   - `test_control_arm_never_touches_the_global_install`:
     - the control call's `cfg=` lies under the pinned `TMPDIR`, differs from `<tmp>/cfg`, and no longer exists after the run;
     - a checksum listing of `<tmp>/cfg` is identical before and after, and `<tmp>/home/.claude` does not exist;
     - one line appended to `<tmp>/cfg/agents/reviewer.md` makes `--control` exit 2 with `agents/reviewer.md differs` and zero calls;
     - with both token variables unset (`env -u`), `--control` exits 2 with zero calls.
6. [x] **Full suite** once, at the end: `po-run --story s114-reuse-ladder-eval --label "Unit suite" -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff for `method/`, `.claude/`, `.polype/`, `tests/run.sh`, `evals/lib.sh` and every existing file under `evals/cases/`.
- `grade()` stays a top-level function with the shape `tests/review-tree-gate.test.sh:63` extracts.
- No paid call. No real `claude` run during implementation, and none from any test: every test puts the fake first on `PATH`.
- `po-eval` never reads, copies or links `.credentials.json`, and never writes under `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` (`grep -n credentials bin/po-eval` is empty).
- No `docs/evals/reuse-ladder.md`: the rates belong to the person's run after ship.

## The pivot
The control arm is a **modified copy of this checkout**: it is installed globally into a temporary config, and it also builds the throwaway repository, so `Follow YAGNI.` sits in both copies the reviewer could load. It runs on an environment token instead of the user's login. Three ways this could be wrong:
- `claude -p` may need more from its config dir than a token, such as onboarding state or settings. The first paid run shows it: the control rate reads `claude exit N`, and `<n>.control.err` stays in the results dir.
- The two arms may score the same because the generic step 3 ("an unrequested change is a finding") already catches the rebuilt helper. That outcome is a valid measurement, not a defect of the tool, and it is the case where s113's rule gets withdrawn (story notes).
- The swap may be exact but incomplete: other s113 text, such as the `## Reuse` clause of the plan templates, is still loaded in the control arm. The story asks only for the step-3 sentence to be replaced (criterion 2), so the control arm measures that sentence and nothing else. The reviewer compares this with the criterion.

## Files touched
`evals/cases/rebuilt-helper.sh` (new), `bin/po-eval`, `tests/evals.test.sh`, `tests/reuse-ladder-eval.test.sh` (new), and this story's `docs/research/` and `docs/plans/` files.

## Test strategy
Three new tests, one per criterion, in `tests/reuse-ladder-eval.test.sh`, plus the amended `test_each_recipe_plants_one_known_defect`. That is well within `Test budget: 25`. Each test exercises the real `bin/po-eval` and the real `bin/polype` with a fake `claude`; nothing is mocked inside po-eval. What would bite:
- dropping the awk swap fails the control-copy counts;
- dropping the `trap` fails "no longer exists";
- installing into the real config fails the checksum;
- moving the drift check after the control setup still fails the drift refusal with zero calls.

No visual check (CLI).

## Done when
Every acceptance criterion's test passes with the full suite (`bash tests/run.sh`) through `po-run`, the record is complete, and one commit holds code, tests, research and plan. After ship, the lead tells the person that the paid run (`bin/po-eval --control --repeat 3`) is theirs to launch, and that its rates go into `docs/evals/reuse-ladder.md`.
