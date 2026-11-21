# Research — s199-journey-runs-to-a-landed-commit

[Story](../stories.md)

## Structuring facts
- **Partly false assumption** in `real_gates_are_crossed`: no gate tells a review written by hand from one written by `po record review`. `po-gate ship-allowed` reads only `Ship allowed:`, `Review status:` and `Reviewed tree:` (`method/hooks/po-gate.sh:77-96`). The same holds for run rows written by hand (`po-gate.sh:150-208`). "Removing a step" can make the journey stop at the gate only if it means *not running* the step. Then po next names the same action again: `review (no review)` (`po/src/next/lane.rs:157-159`), `execute (verif-current refuses)` (`lane.rs:106`), `validate-plan` (`lane.rs:98-100`). A step *replaced by a forgery* goes through. Only `po state` trust (`po/src/trust/signals.rs:20-29`) and the ship order (`lane.rs:238-262`) read what `po record` stamps.
- **The pre-commit has no gate of its own**: when `core.hooksPath` is unset, nothing refuses anything. The journey has to probe it: a code commit made before validation must be refused (`po-gate.sh:379-403`).
- **The whole chain runs end to end today, with no change to `po/`, a hook or a command.** I walked it by hand on two throwaway repositories, in local and pr mode: `po next` → worktree → research and plan → `validated: yes` → code commit through the pre-commit → `po-run` → `po record review` → `po ship forge`, `land`, `push`, `file --file`, `clean` → `po next` answers `{"actions":[]}`, and `po state --all` lists the story as shipped. Under pr, the bare origin's update hook received only `refs/heads/story/s01-greeting` (once to create it, once to delete it).
- The story's line numbers are stale. `/po-orchestrator` and `/po-flow` are gone (s191), `po next` gives the track (s190), and the ship is `po ship forge|land|push|file|clean` (`po/src/ship/mod.rs:85-92`).
- Ships go in the order the reviews were recorded. That order has **one-second precision**: `Recorded:` is written in whole seconds (`po/src/record/mod.rs:231-232`) and read in whole seconds (`lane.rs:260`). A tie goes to the story's rank in `docs/stories.md`, then to the id (`lane.rs:223-224`).

## Story
A replayed script walks a story from `plan` to `<id>: <title>` on `Target branch` with no model. It follows `po next`, applies one written answer per action, crosses the real gates, and runs in `tests/run.sh` with doubles only. Criteria: `journey_follows_po_next`, `story_lands_on_the_full_track`, `story_lands_through_a_pull_request`, `two_lanes_ship_in_order`, `real_gates_are_crossed`, `journey_runs_in_the_suite`. `Owns`: `tests/journey/`, the oracle and test files of the story, `tests/lib.sh`, `docs/harnais.md`.

## Current code
- `tests/run.sh:5-6` runs only `tests/*.test.sh`, so files under `tests/journey/` are never taken for test files. It builds po once (`:22-28`) and copies it to `$CLAUDE_CONFIG_DIR/polype/po`. Each test function runs in its own `bash -c` (`:39`). It exports `CARGO_HOME`, `RUSTUP_HOME`, `CARGO_TARGET_DIR` and `POLYPE_PO_FETCH=false` (`:9-15`).
- `tests/lib.sh:7` gives `PO`, and `:10` gives `GIT_CONFIG_GLOBAL=/dev/null`. `scratch_repo` (`:47-54`) traps EXIT only: a TERM kills bash without running it.
- `po next` (`po/src/next/mod.rs:72-105`) lists one entry per lane first, ordered by `git worktree list`, which **sorts by path**, so by id. The ready stories follow, in the order of `docs/stories.md` (`:90-99`). Each lane's stage comes from its own `po-gate` (`po/src/context/lanes.rs:243-290`). Once every story has landed and every lane is gone, it answers `"actions":[]` (seen).
- What each action needs:
  - `plan`, reason `ready`: no lane yet, so the worktree is made first, by the steps of `method/commands/po-research.md` `## The worktree`.
  - `validate-plan`: only under `Plan validation: human` (`lane.rs:99-100`); under `autonomous` the planner writes the line itself.
  - `execute`: code, a record with a `Tree:`, `po-run` rows, and one commit (`method/agents/implementer.md:44-46`).
  - `review`: `po record review <id>` from the worktree.
  - `ship`: `po ship …`, as `method/commands/po-ship.md` Steps 0-3 lay out.
- The Ship order: `lane.rs:207-232` picks the lane at `ship` whose review was recorded first, and tells the others `wait` / `ships serial: <first>`.

## Attachment points
- New: `tests/journey/journey.sh` (sourced after `lib.sh`), `tests/journey/doubles/`, `tests/journey/project/` (the throwaway project's base files) and `tests/journey/answers/plain/` (the written answers).
- `bin/polype install <dir> --hooks` lays `.polype/hooks`, `.polype/templates` and `.polype/version`, and sets `core.hooksPath` (`bin/polype` `set_hooks_path`, seen). It needs no `AGENTS.local.md` complete beforehand.
- Settings come from `method/templates/agents-local.md`, whose fenced lines can be extracted as `tests/lib.sh:33-35` does.
- Doubles: `PO_GH`, `PO_CURL`, `PO_GLAB` and `PO_TEA` (`po/src/trust/forge.rs:18-25`). The forge is recognised from the origin URL **before** `insteadOf` (`po/src/ship/forge.rs:439-446`), so `https://github.com/acme/project.git` rewritten to a bare repository works, as in `tests/ship-lands-through-a-pull-request.oracle.test.sh:62-66`.

## Verified interfaces
- `po record review <id>` (stdin) must run from `story/<id>`. It needs `.polype/version` and `.polype/templates/review.md`. It writes `Method version:` and `Recorded:`, runs `po-gate oracle-intact` and `findings-shape`, and replies `{"path":…,"method_version":…}` with exit 0 (`po/src/record/mod.rs:143-306`, seen).
- `po ship land <id> [--land]` needs these settings: `Merge mode`, `Full suite`, `E2E stage`, `Build stage`, `Test`, `E2E`, `Build` (`po/src/ship/land.rs:222-237`). `--land` needs `Ship confirmation` to read `automatic` (`:473-490`). `local` with an origin is refused (`:239-254`). The root must sit on main with no tracked change (`:275-297`). The record and the review are committed on the story branch as `<id>: review` (`:432-458`). `Full suite: execute-end` with a current record → `recorded`, so nothing runs again (`:377-380`, seen).
- `po ship push <id> --sha <sha> --body-file <f>`, under pr only. It needs `Forge checks`, `E2E stage` and `Build stage` (`push.rs:137-171`). With no github.com origin it answers `no-pull-request` (`:562`). `Forge checks: required` waits on `gh pr checks`, and `PO_SHIP_POLL_SECONDS=0` removes the sleeps.
- `po ship file <id> [--file]` runs from the worktree and needs `Issue tracker`. With `github`, it needs a github.com origin (`file.rs:470,554`). It files with `gh issue list` and then `gh api --method POST repos/<repo>/issues --input <file>`. Under `—`: `no-tracker` (seen).
- `po ship clean <id>` runs from the root. It refuses a worktree with uncommitted work (`clean.rs:205-224`).
- `po state --all` → `.shipped[]` with `commit` and `trust.method_version`. **Without `--all` it is empty once the milestone is complete** (`po/src/trust/mod.rs:52-60`).
- `po-run.sh` checks the branch (`:36-38`), computes the tree on a copy of the index (`:44-47`) and appends one row (`:57-64`).
- The gh calls one pr ship makes (the forge reading runs twice, in `forge` and in `push`):
  - `auth status --hostname github.com`;
  - `api -i --hostname github.com {user, repos/acme/project/collaborators?per_page=100, …/branches/main/protection, …/rules/branches/main}`;
  - `pr list … --head story/<id> --state all --json …`;
  - `pr create --repo github.com/acme/project --base main --head story/<id> --title <id>: <title> --body-file <f>`;
  - `pr view <url> … --json headRefOid`, `pr checks <url> …`, `pr merge <url> … --rebase --match-head-commit <sha>`, `pr view <url> … --json state`;
  - `issue list …`, `api --hostname github.com --method POST repos/acme/project/issues --input <f>`.

## Traps
- **Locale**: on this machine git answers in French (`fatal : transport 'https' non permis`). Any test that matches a message sets `LC_ALL=C`.
- **The installer launches `cargo build`** (`bin/polype:862-874`), with `--target-dir $CARGO_TARGET_DIR`. A `cargo` double that exits 1 makes it say `cargo could not build po … is missing` and still exit 0 (seen, 0.45 s). This way the journey compiles nothing and never touches the suite's target.
- The installer also lays po into `$CLAUDE_CONFIG_DIR/polype/`. The run.sh copy lives there (s181, `tests/suite-keeps-the-working-po.oracle.test.sh`), so the journey points `CLAUDE_CONFIG_DIR` at its own folder.
- `HOME`: git reads `~/.config/git/ignore`, which ignores `.claude/` here. With `HOME` inside the journey folder, that file is gone. `CARGO_HOME` stays exported by run.sh.
- The real `gh`, `task` and `curl` exist on this machine (`/usr/bin`). The doubles must come first on `PATH` **and** be named by `PO_*`. `po ship file` launches `task` by name (`file.rs:369`). `GH_TOKEN` and `GITHUB_TOKEN` must be unset, or the forge reading switches to curl (`forge.rs:161`).
- `GIT_ALLOW_PROTOCOL=file` makes git refuse every transport except a local one, after the `insteadOf` rewrite: a cheap no-network guard (seen).
- **bash defers a signal trap while a foreground child runs.** A TERM sent only to the parent leaves the journey running. The interrupt test signals the whole process group.
- A lane's `git status` must be empty for `clean`. The pre-commit probe must leave nothing staged or untracked.
- `two_lanes_ship_in_order` cannot tell "order the reviews passed" apart from "rank" unless the two differ. Lanes are always applied in id order, so the story ranked first must be the one reviewed second, and the two reviews must fall in different seconds.
- Cost seen: `po next` takes 14 ms, an install 0.45 s, and a whole local journey under 3 s.

## Open questions
- Whether to file an issue for "no gate reads `po record`'s stamp": the lead decides, since it is outside this story.
- `Plan validation: human` in the throwaway project turns validation into a step of its own. The plan takes that.

## Complexity
4 → 4. Nothing outside `Owns` changes. The work is a harness, its doubles and its answers, plus nine tests.

## Split
— (4)
