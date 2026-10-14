---
validated: yes
---
# Plan — s100-qa-evidence-set-aside

[Story](../stories.md) · [Research](../research/s100-qa-evidence-set-aside.md)

Branch `story/s100-qa-evidence-set-aside`. Read `docs/research/s100-qa-evidence-set-aside.md` first; this plan builds on it without repeating it. Defect story: the root cause and its reproduction are in the research's `## Structuring facts` and `## Diagnostic`.

## Story
Fix the major and minors of `docs/reviews/s93-qa-contract-holds.md` and the scene-group and recorder-wait minors of `docs/reviews/s94-scene-and-simulation-drivers.md`.
- `first_qa_sets_its_evidence_aside` — `qa` and the three comparing drivers set aside `docs/qa/<id>/` and any parent line that covers only it (`?? docs/qa/` at the first QA).
- `bounded_waits_bite` — the 60-second bound's consequence (scenarios) and the no-driver-row consequence (`qa`) each have a test that fails when it disappears or inverts.
- `scene_and_recorder_stop_cleanly` — the scene driver stops every process group it started and makes the engine quit after the capture; the recorder wait of the simulation driver is bounded, and exceeding it is a finding.

## The set-aside sentence
One sentence, byte-identical in the four files, written as is (the test quotes it whole):

> A line naming a parent of `docs/qa/<id>/`, such as `?? docs/qa/` at a project's first QA, is set aside too when `git -C <path> ls-files --others --exclude-standard -- <that parent>` lists nothing outside `docs/qa/<id>/`.

Called **S** below.

## Tasks
1. [x] `method/agents/qa.md:49` (step 7): append S at the end of that numbered line, after "remove nothing." Change nothing else in the file; line 44 stays byte-identical (task 5 pins it as it is).
   Test: `first_qa_sets_its_evidence_aside` fails if S leaves qa.md.
2. [x] `method/skills/qa-drivers/scenarios.md:12`: insert S right after "and nothing is removed." and before "One blind spot remains", on the same paragraph line. Line 14 (the 60-second paragraph) and line 16 stay byte-identical.
   Test: `first_qa_sets_its_evidence_aside` (scenarios.md); `scenario-driver.test.sh` and `qa-contract-holds.test.sh` stay green.
3. [x] `method/skills/qa-drivers/scene.md`:
   - line 21: replace "stop the process group you started, and only that one." with "stop every process group the walk started — one per engine run — and only those." Keep the rest of the line, then append S after "and nothing is removed."
   - line 28: replace "then call `root.get_texture().get_image().save_png()`." with "then call `root.get_texture().get_image().save_png()`, then `quit()` so the engine exits once its image is saved."
   Test: `scene_and_recorder_stop_cleanly` fails if the singular stop comes back, if "every process group the walk started" or "then `quit()`" leaves; `first_qa_sets_its_evidence_aside` for S. `scene-and-simulation-drivers.test.sh` (`$SET_ASIDE`, `save_png()` phrase) and `godot-scene-driver.test.sh` stay green.
4. [x] `method/skills/qa-drivers/simulation.md`:
   - line 21: append S after "and nothing is removed."
   - line 30: replace "then send SIGINT to the recorder's process group and wait until it exits, so the bag is closed with its metadata; the echoes are stopped the same way." with "then send SIGINT to the recorder's process group and wait at most 30 seconds of real time for it to exit, so the bag is closed with its metadata; a recorder still running after 30 seconds is a finding, and its process group gets SIGKILL. The echoes are stopped the same way."
   Test: `scene_and_recorder_stop_cleanly` fails if the bound or its finding leaves, or if the unbounded "wait until it exits, so the bag" returns; `first_qa_sets_its_evidence_aside` for S. `ros-simulation-driver.test.sh` and `scene-and-simulation-drivers.test.sh` stay green.
5. [x] New `tests/qa-evidence-set-aside.test.sh`, header comment `# s100 — QA evidence never blocks its own walk, and the bounded waits have biting tests.`, variables `QA_AGENT`, `SCENARIOS`, `SCENE`, `SIMULATION` from `$METHOD`, `SET_ASIDE_PARENT` holding S exactly, and a local `lacks` (same shape as `tests/scene-and-simulation-drivers.test.sh:19`). Three functions:
   - `test_first_qa_sets_its_evidence_aside`: for each of the four files, `require_file` then `contains "$f" "$SET_ASIDE_PARENT"`.
   - `test_bounded_waits_bite`: `contains "$SCENARIOS" 'within 60 seconds → stop it and end with `QA status: blocked`'` and `contains "$QA_AGENT" 'set to `—` → write the report with `QA status: blocked`, naming the surface and the platform as its cause.'` — each phrase belongs to its clause alone, unlike the same-line checks of `qa-contract-holds.test.sh`.
   - `test_scene_and_recorder_stop_cleanly`: scene contains `stop every process group the walk started` and `then \`quit()\``, lacks `the process group you started, and only that one`; simulation contains `a recorder still running after 30 seconds is a finding`, lacks `wait until it exits, so the bag`.
   Mind the backticks and the apostrophe inside single-quoted bash strings (`'\''`).
6. [x] Checks: `bash tests/run.sh qa-evidence-set-aside.test.sh qa-contract-holds.test.sh scenario-driver.test.sh godot-scene-driver.test.sh ros-simulation-driver.test.sh scene-and-simulation-drivers.test.sh qa-drivers.test.sh qa.test.sh overlap.test.sh` while working; then once, at the end, `po-run --story s100-qa-evidence-set-aside --label 'Unit suite' -- 'bash tests/run.sh'` and `po-run --story s100-qa-evidence-set-aside --label Lint -- 'bash bin/po-lint'`.

## Scene viewpoints
—

## Run interdicts
- `tests/qa-contract-holds.test.sh` and every other existing test file end with an empty diff: the new test file carries the stronger checks, the old same-line checks stay as they are.
- `method/agents/qa.md`: frontmatter, line 44 and every line but 49 unchanged.
- `scenarios.md:14` and `:16` unchanged; the rest of `scenarios.md`, `scene.md`, `simulation.md` unchanged outside the lines named in tasks 2–4.
- `method/skills/qa-drivers/SKILL.md`, `browser.md`, `mobile-web.md`, `boilerplates/`, `method/hooks/`, `docs/parite-killer-saas.md`, `docs/decisions/`: empty diff. No ADR (ADR-0074 stays unused).
- Nothing under `.claude/` or `.polype/`.
- No `--untracked-files=all` / `-uall` added to any `status` command of the four files.

## The pivot
The fix sets a collapsed parent line aside through an explicit `ls-files` check, instead of the story's other option, listing untracked files one by one (`-uall`). Rejected because the three drivers run `status --porcelain --ignored`, and with `-uall` git also expands every ignored folder file by file (research, Diagnostic: `!! node_modules/z/f`), turning the before/after outputs into the whole build tree. `qa.md` has no `--ignored` and could have used `-uall`, but one rule worded once in four places is easier to hold than two. Ways it could be wrong:
1. **`ls-files` refused in mode `qa`.** Compare with `method/hooks/po-bounds.sh:313` (`QA_GIT_VERBS` lists `ls-files`).
2. **The check lets a stray file through.** `--exclude-standard` drops ignored files, so an ignored stray under `docs/qa/` is not seen by this sentence; but `status` without `-uall` would not show it as a new line either, and ADR-0044 already keeps ignored files out of the evidence. A non-ignored stray under the parent is listed by `ls-files` and keeps the line blocking — compare in a scratch repo with `docs/qa/stray.txt` beside `docs/qa/<id>/`.
3. **30 s of real time for the recorder.** No measurement backs it; it mirrors the file's default 30 s criterion wait, and a bound too short fails visibly (a finding, never a false `complete`). Godot's `quit()` from a `SceneTree` script is known API, not checked against 4.7.2 source.

## Files touched
- `method/agents/qa.md`
- `method/skills/qa-drivers/scenarios.md`
- `method/skills/qa-drivers/scene.md`
- `method/skills/qa-drivers/simulation.md`
- `tests/qa-evidence-set-aside.test.sh` (new)
- `docs/research/s100-qa-evidence-set-aside.md`, `docs/plans/s100-qa-evidence-set-aside.md`, `docs/verif/s100-qa-evidence-set-aside.md`

## Test strategy
Automated, text-contract layer (the project's convention for method prose), 3 tests within the budget of 25, one per acceptance criterion, each named after it. Each quotes a phrase that only its clause carries, so deleting or inverting the clause turns it red — the bite the reviewer will check with the s93 mutations M2 and M9 and their counterparts on S, the plural stop, `quit()` and the 30-second finding. No behavioural test of `git ls-files`: it would test git, not the method.

Not testable here: whether a real `qa` subagent applies S at a first QA, and real Godot/ROS 2 runs (tools absent). Visual checks: none.

## Done when
Tasks 1–6 ticked; the focused run and the recorded `Unit suite` and `Lint` rows pass; one commit carrying code, tests, research, plan and record; a review with no open critical finding.
