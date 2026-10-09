# Research — s100-qa-evidence-set-aside

## Structuring facts
- **Root cause (first QA blocks on its own evidence):** `method/agents/qa.md:49`, `method/skills/qa-drivers/scenarios.md:12`, `scene.md:21` and `simulation.md:21` set aside only "a path outside `docs/qa/<id>/`". When `docs/qa/` is not tracked yet (a project's first QA), `git status --porcelain` collapses the whole untracked folder into one line, `?? docs/qa/` — a parent of `docs/qa/<id>/`, not a path inside it — so a literal comparison ends `QA status: blocked` on the walk's own report. Input: any first QA. Proof: reproduced below (`## Diagnostic`).
- **Root cause (untested consequences):** two clauses share their line with another `QA status: blocked`, so a same-line check finds `blocked` even when the clause is gone: `scenarios.md:14` (60-second bound, then the port sentence) and `qa.md:44` (missing driver file, then the zero-row rule). `tests/qa-contract-holds.test.sh:33` and `:21` only pin `within 60 seconds` and `No row matches`.
- **No story assumption is false.** "The three drivers that compare the repository state" are exactly `scenarios.md`, `scene.md`, `simulation.md`; `browser.md`, `mobile-web.md` and `SKILL.md` hold no `porcelain` comparison (grep over `method/skills/qa-drivers/`).
- `git status --untracked-files=all` is no safe fix for the drivers: with `--ignored` it also expands every ignored folder file by file (reproduced: `!! node_modules/z/f`), which would flood the before/after outputs.
- The set-aside check can use `git ls-files --others --exclude-standard -- <parent>`: `ls-files` is a reading verb `po-bounds` grants mode `qa` (`method/hooks/po-bounds.sh:313`).

## Diagnostic
**Reproduction** (throwaway repo under `mktemp -d`, nothing written in the worktree):
- tracked `docs/x.md`, ignored `node_modules/`; before the walk `git status --porcelain --ignored` → `!! node_modules/`.
- after writing `docs/qa/s1/report.md` and `docs/qa/s1/a.txt` → `?? docs/qa/` and `!! node_modules/`. Literally outside `docs/qa/s1/` → blocked. **Reproduced.**
- same with `-uall` → `?? docs/qa/s1/a.txt`, `?? docs/qa/s1/report.md`, `!! node_modules/z/f`.
- `git ls-files --others --exclude-standard -- docs/qa/` → only the two `docs/qa/s1/` files.
- a second repo where `docs/qa/s1/` is committed, then `docs/qa/s2/` written → `?? docs/qa/s2/`: once `docs/qa/` is tracked, the line is the evidence folder itself and nothing blocks.

**Hypotheses**
1. *The collapse of an untracked parent folder makes the evidence look outside `docs/qa/<id>/`.* Refuted if `status` listed `docs/qa/s1/…` paths. It listed `?? docs/qa/` → **kept**.
2. *The blocking comes from `--ignored` lines instead.* Refuted if the `!!` line changed across the walk. It did not (`!! node_modules/` both times) → **discarded**.
3. *Every QA, not only the first, blocks.* Refuted if a QA in a repo with a tracked `docs/qa/` shows its folder as itself. It showed `?? docs/qa/s2/` → **discarded**: the defect is the first QA only (and a fix run's QA, whose folder is committed, is safe).

For the two untested consequences the review's mutations M9 and M2 (`docs/reviews/s93-qa-contract-holds.md`, Bite table) are the proof; I read `scenarios.md:14` and `qa.md:44` and confirm each holds a second `QA status: blocked`.

## Story
Fix the major and minors of `docs/reviews/s93-qa-contract-holds.md` and two minors of `docs/reviews/s94-scene-and-simulation-drivers.md`.
- `first_qa_sets_its_evidence_aside` — `qa` and the three comparing drivers set aside `docs/qa/<id>/` and any parent line covering only it (`?? docs/qa/` at the first QA), or list untracked files one by one.
- `bounded_waits_bite` — the consequence of the 60-second bound of the scenarios driver and that of `qa`'s no-driver-row line each have a test that fails when it disappears or inverts.
- `scene_and_recorder_stop_cleanly` — the scene driver stops every process group it started and makes the engine quit after the capture; the simulation driver's wait for the recorder to stop is bounded, and exceeding it is a finding.

Not in scope: the other two s94 minors (`boilerplates/godot/profile.md:33` resolution, `application/run/main_scene`) — their files are not in `Owns`.

## Current code
- `method/agents/qa.md:43` keeps `git status --porcelain` before the walk; `:49` (step 7) compares after it and blocks on "a path outside `docs/qa/<id>/`". `:44` is one line: missing driver file → blocked; no row / `Platform` missing or `—` → blocked.
- `scenarios.md:12` keeps `status --porcelain --ignored` before the copy, blocks after the walk on a path outside `docs/qa/<id>/`, then states the ignored-folder blind spot. `:14` is the API start paragraph: 60-second bound, then the other-port sentence, both ending `QA status: blocked`. `:16` stops "the process group you started, and only that one" (one service: correct here).
- `scene.md:19` "one engine run per capture script", each in its own `setsid` group; `:21` still stops "the process group you started, and only that one" (singular) then compares. `:28` capture script: await `RenderingServer.frame_post_draw`, then `root.get_texture().get_image().save_png()`; it never tells the engine to quit.
- `simulation.md:21` stops "every process group the walk started" then compares. `:30` "send SIGINT to the recorder's process group and wait until it exits, so the bag is closed with its metadata; the echoes are stopped the same way" — unbounded, unlike the other waits (`--max-wait-time-secs`, `timeout`, 30 s simulated).

## Attachment points
- One sentence appended to `qa.md:49` and to the comparison paragraph of each driver (`scenarios.md:12`, `scene.md:21`, `simulation.md:21`).
- `scene.md:21` (plural stop) and `:28` (quit after save).
- `simulation.md:30` (bounded recorder wait).
- A new test file `tests/qa-evidence-set-aside.test.sh`, auto-discovered by `tests/run.sh`; helpers from `tests/lib.sh` (`contains`, `require_file`, `fail`, `METHOD`).

## Verified interfaces
- `tests/lib.sh`: `fail`, `contains <file> <phrase>` (grep -F, exact), `require_file`, `METHOD="$ROOT/method"`. `lacks` is not in lib: `tests/scene-and-simulation-drivers.test.sh:19` defines its own.
- `po-bounds.sh:313` `QA_GIT_VERBS` includes `status`, `ls-files`.
- Godot: a `--script` extending `SceneTree` can call `quit()` (SceneTree method). Not opened in Godot's source here — see Open questions.

## Traps
Phrases pinned by neighbouring tests, to keep byte-identical:
- `qa.md`: `status --porcelain\` as it stands before the walk` (qa-contract-holds:41), `status --porcelain\` again`, `mktemp -d`, `observe through the surface` (qa-drivers:50-52), the missing-file sentence (qa-drivers:34), `No row matches`, `` `Platform` is missing ``, `A walk that followed no driver file is never \`complete\`` (qa-contract-holds:21-24), and qa.test.sh:38-52.
- `scenarios.md`: `the first output did not list` + `outside \`docs/qa/<id>/\`` on one line, `→ \`QA status: blocked\`, naming that path`, `within 60 seconds` + `QA status: blocked`, `and only that one`, `status --porcelain --ignored`, and the rest of scenario-driver.test.sh:12-45.
- `scene.md` and `simulation.md`: `a path outside \`docs/qa/<id>/\` that the first output did not list` (scene-and-simulation-drivers:13), `root.get_texture().get_image().save_png()`, `stop every process group the walk started` (simulation); simulation must **lack** `the process group you started, and only that one` (:54). godot-scene-driver:76-95 and ros-simulation-driver:78-99 phrase lists.
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS — write new sentences in own words.
- `.claude/` and `.polype/` are installed copies: not refreshed by a story.

## Open questions
- Godot's `SceneTree.quit()` from a `--script`: known API, not checked against Godot 4.7.2 source here; no real capture can run (Godot absent, as s94 recorded).
- The recorder bound value (30 s): no measurement of `ros2 bag record` closing time; the plan picks it and argues it.

## Complexity
Story: 2 → after reading: 2. Four prose files with local edits and one test file; no hook, no gate, no ADR.
