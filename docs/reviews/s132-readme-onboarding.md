# Review — s132-readme-onboarding

[Story](../stories.md) · [Plan](../plans/s132-readme-onboarding.md) · [Verification](../verif/s132-readme-onboarding.md)

Diff reviewed: `git diff main...story/s132-readme-onboarding`, in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 6209b20ebcc54037e0a9e28a419ed227637debac

## Ownership
I listed the diff with `git diff --name-only main...story/s132-readme-onboarding` and checked each path against `Owns`: `README.md`, `docs/installation.md`, `bin/polype`, `method/hooks/po-session.sh`, `tests/readme-onboarding.test.sh`.
- [x] Every path is inside `Owns`. The only other paths are this story's own `docs/research/`, `docs/plans/` and `docs/verif/` files, which are in scope by construction.
- [x] Nothing is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows only the main checkout and this worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s132-readme-onboarding`: exit 0. With `Verification mode: record`, I reused the record: `bash tests/run.sh` exit 0, on code outside `docs/` that matches `Tree: b4f73c23…`. The project has no type check, E2E or build command (`—` in AGENTS.local.md). I read the record's "Not proven here" section.
- [x] `po-gate qa-current`: not required. The story's `Surface` is `command` and `QA stage` is `—`, so it does not go to QA.

## Plan
- [x] Tasks 1 to 5 are present. Both guards match the plan's block word for word. The README has the four planned sections in the planned order. The installation doc gains the `### Les collisions` subsection and the rewritten passages.
- [x] Run interdicts, one by one:
  - the diff touches only owned paths;
  - in `bin/polype` and `po-session.sh` the diff is the guard block alone, with no added seam;
  - no existing test file changed;
  - nothing under `.claude/` or `.polype/` changed, and no ADR was added;
  - the quickstart test exports `HOME` and `CLAUDE_CONFIG_DIR` under `mktemp -d`, and refuses to run otherwise;
  - `update` behaviour is unchanged.

## References
- [x] I opened every claim and reference. Collisions, `--set-aside` and `.before-polype` match `bin/polype:192-226`. The `Project CLAUDE file` values match `:302-323` and `:412-423`. `CLAUDE_CONFIG_DIR` matches `:37`. The `jq` claims match `bin/polype:438,466` and `po-bounds.sh:830`. `/po-setup` reruns the installer (`po-setup.md` step 3.3).
- [x] Values: "environ 20 Ko" matches `method/AGENTS.md` at 20806 bytes, and the test re-derives it within ±25 %. Exit codes are 1 for the installer (as in the doc) and 0 for po-session (as the hook's contract says).

## Rules
- [x] `AGENTS.md` conventions respected: documentation in French, code and messages in English.
- [x] No accepted ADR is contradicted (ADR-0086, 0088, 0089 checked).

## Tests
- [x] Floor: `po-gate floor-guard s132-readme-onboarding main` exit 0, nothing lowered.
- [x] The assertions pin down the five criteria, and none of the six empty test shapes appears. The quickstart test runs the README blocks as written: only the clone URL is replaced, and only once. It takes off `PATH` every directory holding a `polype`, then ends with two `check` runs that report no drift.
- [x] 5 tests, within `Test budget: 25`.
- [x] Bite tests, each followed by `git checkout -- <file>` and a clean `git diff --exit-code <file>`:
  - **Minor-version check in `bin/polype` weakened** (`-lt 2` changed to `-lt 1`): 1 failing test (`old_bash_is_named`: "polype went on under bash 4 1").
  - **`ln -s` line removed from the README:** 1 failing test (`quickstart_runs_as_written`). It is caught by the static order check, not by running the block.
  - **`ln -s` kept but pointed at a wrong target** (`bin/polypo`): 1 failing test (`quickstart_runs_as_written`, "polype: commande introuvable"). This confirms the executed run itself bites.
- [x] No test is made useless by the story.

## Neighbours
- [x] The guards are top-level code before any function, and the quickstart test drives the installer through the README. The installed copy `.polype/hooks/po-session.sh` is not refreshed, by design. The full suite is green in the record.

## Lenses
Lenses run: none. No auth, migration, dependency or server-side path or content is in the diff.
- [x] No lens findings.

## Findings
- major — docs/installation.md:204-205 — The rewritten bullet still says, for a project with no `AGENTS.local.md`, "lancer `/po-setup`, puis `polype update .`". The new README says (README.md:94) that a project activated by `init` is refreshed with `polype init .`, "jamais par `polype update .`", because `update` would also lay commands, subagents and skills into the project (research, Structuring facts). The README's own quickstart activates with `polype init .` before `/po-setup`, so its reader is exactly the one this sentence sends down the wrong path. The wrong result is visible, not silent. The installer's own stderr hint at bin/polype:423 says the same thing, but that line is outside this diff, and the plan forbids touching it here. That makes it material for a later story or an issue, decided by a person (Law 7).
- minor — README.md:64 — `ln -s ~/.claude/polype/bin/polype` hard-codes `~/.claude`. `bin/polype:37` honours `CLAUDE_CONFIG_DIR`, so a reader who has that variable set gets a dangling link and `polype: command not found` at the next line. The README does not mention the variable.
- minor — README.md:111-112 — The "Pour essayer sans risque" advice comes after a quickstart that has already run `install --global` into the reader's real `~/.claude`, and it relies on `polype` being on the `PATH`, which only that quickstart provides. For the target reader, who has their own Claude Code configuration, the risk-free first try is `~/src/polype/bin/polype install <clone>`, before any `--global`. A collision would still stop the install before any write, so nothing is damaged; this is an ordering and wording issue.
- minor — README.md:64 — `ln -s` without `-f` fails with "File exists" if the reader reruns the first block. The update block does not repeat it, so the documented path is unaffected.

## Not verified
- **No bash older than 4.2 on this machine, and no macOS.** I proved both guards only by running the extracted block with a substituted array name. To cover it, a person should run `bin/polype --help` and the session hook under macOS `/bin/bash` 3.2, and once under bash 4.1.
- **The quickstart test clones the committed tree of `story/<id>`, not the working tree.** It proves the README procedure against the committed installer, not the guard.
- **The quickstart was never run against a real `~/.claude` that already holds the reader's own agents or skills.** That is the collision path a newcomer would hit at `install --global`. The lead's note forbids touching the real config, so I verified it only by reading `bin/polype:192-226`. A person should run the quickstart in a scratch HOME seeded with a hand-written `agents/reviewer.md` and check the stop and `--set-aside` messages.
- **`jq` and `gh` are only listed, not exercised.** Their absence was not simulated.
- **What `/po-setup` does after `polype init .` is not checked.** Its step 3.3 "rerun the installer" does not say whether that means `init` or `update`. Whether it lays commands into an `init` project is not verified; a person should run `/po-setup` on a project activated with `init` and inspect `.claude/`.
- **The README was not read inside a GitHub render.** I checked the fenced-block languages (`sh`, `text`, `sh`) in the source only.

Max severity: major
Ship allowed: yes

---

# Review — s132-readme-onboarding

[Story](../stories.md) · [Plan](../plans/s132-readme-onboarding.md) · [Verification](../verif/s132-readme-onboarding.md)

Diff reviewed: `git diff main...story/s132-readme-onboarding`, in a context that did not write it. This loop judges fix commit d4ff642 against the loop-0 findings. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 7a866d275e01b3d306b7d0a1e074359405b42a53

## Ownership
`git diff --name-only main...story/s132-readme-onboarding` lists `README.md`, `bin/polype`, `docs/installation.md`, `method/hooks/po-session.sh` and `tests/readme-onboarding.test.sh`, plus the story's own research, plan, verif and review files.
- [x] Every code and doc path is inside `Owns`. The pipeline evidence files are in scope by construction.
- [x] Nothing is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows only main and this worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s132-readme-onboarding` exited 0. Because `Verification mode: record`, I reused the record's `bash tests/run.sh` exit 0 and did not rerun the full suite. The project has no type check, E2E or build command: each is `—` in AGENTS.local.md, so none ran. I read "Not proven here", including the fix-run note.
- [x] QA is not required: `Surface: command` and `QA stage: —`.

## Plan
- [x] Fix tasks 6 to 8 are all present:
  - `docs/installation.md:205-208` now sends an `init` project to `polype init .`.
  - The `handle_claude_md` hint (`bin/polype:413-424`) now names the pose: `$mode` is `init` only for `polype init` (`bin/polype:752`).
  - The `ln -sf "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/…"` line in the README and in `docs/installation.md:56` matches `bin/polype:37`.
  - The throwaway-clone try now comes before the first `sh` block (README.md:58-63) and is repeated at README.md:118-120.
- [x] The only non-guard change in `bin/polype` is the hint, which the lead authorised. `po-session.sh` is unchanged by the fix. No existing test, `.claude/`, `.polype/` or ADR was touched.

## References
- [x] `home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`bin/polype:37`) matches the new link line.
- [x] I walked the README's risk-free try myself, in a scratch HOME and `CLAUDE_CONFIG_DIR` under `/tmp/tmp.orb9WizkuK`, with a hand-written `~/.claude/agents/reviewer.md`:
  - `install <essai>` exited 0 and left the user config dir byte-for-byte untouched (find listing diffed).
  - `remove` exited 0 and left only `.gitignore`.
  - `install --global` then stopped with exit 1, wrote nothing and named the file.
  - `--set-aside` produced `reviewer.md.before-polype`.

  All of this matches the README's claims.

## Rules
- [x] French documentation, English code and messages. No accepted ADR is contradicted (ADR-0086, 0088, 0089).

## Tests
- [x] Floor: `po-gate floor-guard s132-readme-onboarding main` exited 0.
- [x] 6 tests, within `Test budget: 25`. The sixth, `test_setup_hint_names_the_pose`, is named in plan task 6. None of the six empty test shapes appears. The quickstart test now uses a non-default `CLAUDE_CONFIG_DIR` and reruns the link line.
- [x] Focused run of `readme-onboarding.test.sh`: 6 passed.
- [x] Bite tests. After each one I ran `git checkout -- <file>` and confirmed a clean `git diff --exit-code <file>`:
  - `[ "$mode" = init ] && again='polype init .'` replaced by `:` in `bin/polype`: 1 failing test (`setup_hint_names_the_pose`).
  - README link line hard-coded back to `~/.claude/...`: 1 failing test (`quickstart_runs_as_written`, "polype: commande introuvable"). The non-default `CLAUDE_CONFIG_DIR` bites.
  - `ln -sf` changed back to `ln -s`: 1 failing test (`quickstart_runs_as_written`, "the link line fails when the first block is run again … Le fichier existe").

## Neighbours
- [x] I searched for other occurrences of `polype update .`. Two siblings of the loop-0 major remain, in owned files, on lines this diff leaves alone (see Findings). `tests/global-install.test.sh:159` still quotes the old `ln -s ~/.claude/...` form in a comment only. That file is outside `Owns`, and the comment is harmless.

## Lenses
Lenses run: none. No auth, migration, dependency or server-side path or content is in the diff.

## Findings
- major — bin/polype:258 — The fix covered only the `handle_claude_md` hint. Its twin for a hand-written `AGENTS.md` still prints "AGENTS.md kept as AGENTS.md.before-polype: no AGENTS.local.md to move it into; run /po-setup, then polype update ." whatever the pose. This is exactly the README quickstart reader's path: `polype init .` runs before `/po-setup`, and a repository with its own `AGENTS.md` is common. The hint sends that reader to `update .`, which the README (README.md:101) and `docs/installation.md:206` now say never to run on an `init` project, because it lays commands, subagents and skills into the project. The result is visible, not silent. The fix is the same `$mode` switch the fix run used at :413-414. Note the lead authorised only "the installer's stderr hint", so widening that permission is the lead's call.
- minor — method/hooks/po-session.sh:244 — For `Project CLAUDE file: absorbed`, the session hint still reads "→ polype update . moves it into AGENTS.local.md". It has no access to the pose, and on an `init` project it gives the advice the README forbids. The line predates this story, sits in an owned file and is pinned by `tests/no-claude-md.test.sh:98` and `tests/claude-md-setting.test.sh:113`, so changing it means changing tests this story does not own. Better handled by a later story or an issue, decided by a person (Law 7).
- minor — README.md:58-60 — The risk-free try asks the reader to run only "la première ligne du bloc ci-dessous", then stop. The block itself carries no marker of where to stop, so a reader who pastes the whole block goes straight to `install --global`. Nothing is damaged, because a collision stops before any write, as I verified. A separate one-line `sh` block holding the clone, or a comment in the block, would read more clearly.

Loop-0 findings: the major (installation.md:204-205 plus the :423 hint) is fixed, the CLAUDE_CONFIG_DIR minor is fixed, the ordering minor is fixed and the `ln` without `-f` minor is fixed.

## Not verified
- **No bash older than 4.2 and no macOS here.** The guards were proven only by the extracted-block test. A person should run `bin/polype --help` and the session hook under macOS `/bin/bash` 3.2 and under bash 4.1.
- **The quickstart test clones the committed tree, not the working tree.** It proves the README procedure against the committed installer.
- **What `/po-setup` step 3 ("Rerun the installer") runs on an `init` project, `init` or `update`, is not checked.** If it runs `update .`, it lays commands into the project, against the README. A person should run `/po-setup` on a project activated by `polype init .` and inspect `.claude/`.
- **`jq` and `gh` are listed, never exercised.** I did not simulate their absence.
- **The README was not viewed in a GitHub render**, so the anchor link `#ce-que-polype-fait-de-ta-configuration` is unchecked. I read only the source.
- **The scratch walk used a reader config with one agent collision only.** A skill-directory collision and a symlinked `~/.claude` entry were not walked.

Max severity: major
Ship allowed: yes

---

# Review — s132-readme-onboarding

[Story](../stories.md) · [Plan](../plans/s132-readme-onboarding.md) · [Verification](../verif/s132-readme-onboarding.md)

Diff reviewed: `git diff main...story/s132-readme-onboarding`, in a context that did not write it. This loop judges fix commit 9c2c02d against the loop-1 findings. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 2
Reviewed tree: 6b0e9027bfe95e37216378ef2197447c5eb63713

## Ownership
`git diff --name-status main...story/s132-readme-onboarding` lists five modified paths: `README.md`, `bin/polype`, `docs/installation.md`, `method/hooks/po-session.sh` and `tests/readme-onboarding.test.sh` (added). The story's own research, plan, verif and review files are also added.
- [x] Every code and doc path is inside `Owns`. The pipeline evidence files are in scope by construction.
- [x] Nothing is outside `Owns`. The two framing commits on main (`docs/stories.md`, `docs/reviews/stories-m11.md`, `docs/decisions-log.md`) are not in the three-dot diff.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows only main and this worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s132-readme-onboarding` exited 0.
  - The record's `Tree: 2a3f12ad…` equals HEAD outside `docs/`: `git diff --quiet` exited 0.
  - The last `Unit suite` row (`bash tests/run.sh`) exited 0.
  - With `Verification mode: record`, I relied on that row and did not rerun the full suite.
  - The project has no type check, E2E or build command: each is `—` in AGENTS.local.md, so none ran.
  - I read "Not proven here", including the fix-run-2 note.
- [x] QA is not required: `Surface: command` and `QA stage: —`.

## Plan
- [x] Fix task 9 is present. In `absorb_agents_md`, `bin/polype:257-260` now chooses `polype init .` when `$mode` is `init`, using the same switch as the `handle_claude_md` hint (`bin/polype:415`).
  - `$mode` is set to `init` only by the `init` dispatch (`bin/polype:754`).
  - `grep 'update \.' bin/polype` finds only these two defaults, so every installer stderr hint naming `polype update .` is now pose-aware. That matches the lead's widened permission.
- [x] Fix task 10 is present. The clone has its own one-line `sh` block (README.md:60-62). The throwaway-clone try sits between that block and the `install --global` block, and opens with "Arrête-toi ici".
- [x] The po-session hint (loop-1 minor 2) was left alone, as the lead decided. `method/hooks/po-session.sh` is not touched by 9c2c02d.
- [x] No existing test, nothing under `.claude/` or `.polype/`, and no ADR was touched.

## References
- [x] `mode` is defaulted at `bin/polype:39`, and `parse_target`/`cmd_init` are reached after `mode=init` is set, so the hint sees the right pose.
- [x] The quickstart test still runs the README blocks in a scratch `HOME`/`CLAUDE_CONFIG_DIR`. It now concatenates clone, install and update blocks, and checks that the clone URL is substituted exactly once.

## Rules
- [x] Documentation is in French; code, comments and the commit message are in English.
- [x] No accepted ADR is contradicted (ADR-0086, 0088, 0089 as in the earlier loops).

## Tests
- [x] Floor: `po-gate floor-guard s132-readme-onboarding main` exited 0.
- [x] 6 tests, within `Test budget: 25`.
  - `setup_hint_names_the_pose` now seeds both a `CLAUDE.md` and an `AGENTS.md`.
  - It checks each hint line separately: `grep -F "$hint" | grep -qF "then $expected"`. So one correct hint cannot answer for the other.
  - None of the six empty test shapes appears.
- [x] Focused run of `readme-onboarding.test.sh`: 6 passed.
- [x] Bite tests. After each one I ran `git checkout -- <file>` and got a clean `git diff --exit-code <file>`:
  - `bin/polype:258` (`[ "$mode" = init ] && again='polype init .'`) replaced by `:`: 1 failing test (`setup_hint_names_the_pose`).
  - `~/src/polype/bin/polype install --global` inserted into the clone block of README.md: 1 failing test (`quickstart_runs_as_written`, "the first block is not the clone alone").

## Neighbours
- [x] No other test pins the old `AGENTS.md` hint text. `install.test.sh` and `installer.test.sh` check only the `.before-polype` file, and the recorded full suite is green.
- [x] `README.md:106` and `docs/installation.md:206` keep the "never `polype update .` on an `init` project" wording, which matches both hints.
- [x] The only remaining `polype update .` advice is `method/hooks/po-session.sh:244`, which the lead deliberately deferred.

## Lenses
Lenses run: none. The diff holds no auth, migration, dependency or server-side path or content.

## Findings
- minor — method/hooks/po-session.sh:244 — Carried over from loop 1 and left open on purpose by the lead. For `Project CLAUDE file: absorbed`, the session hint still says "→ polype update . moves it into AGENTS.local.md". On an `init` project, that is the advice the README forbids. The line predates this story, and the tests that pin it (`tests/no-claude-md.test.sh:98`, `tests/claude-md-setting.test.sh:113`) are outside `Owns`. It is for a person to turn into an issue or a story (Law 7).

Loop-1 findings: the major (the `bin/polype` `AGENTS.md` hint) is fixed and bite-proven. Minor 3 (no visible place to stop in the risk-free try) is fixed and bite-proven. Minor 2 (po-session) stays open by the lead's decision. No new finding.

## Not verified
- **No bash older than 4.2 and no macOS on this machine.** The guards are proven only by the extracted-block test. A person should run `bin/polype --help` and the session hook under macOS `/bin/bash` 3.2 and under bash 4.1.
- **The quickstart test clones the committed tree, not the working tree.** It proves the README procedure against the committed installer.
- **The hand-written `AGENTS.md` hint under `polype update .` on an `init` project still says `update .`.** Under `update`, `$mode` is `project`. That path, and `update` laying commands into an `init` project, is out of this story's scope, as the record says. Not exercised.
- **What `/po-setup` step 3 ("Rerun the installer") runs on an `init` project, `init` or `update`, is not checked.** A person should run `/po-setup` on a project activated by `polype init .` and inspect `.claude/`.
- **`jq` and `gh` are listed, never exercised.** Their absence was not simulated.
- **The README was not viewed in a GitHub render.** The anchor `#ce-que-polype-fait-de-ta-configuration` and the new block layout were read in source only.
- **I did not walk the risk-free try again in a scratch HOME this loop.** The loop-1 walk (`/tmp/tmp.orb9WizkuK`) covered it, and the fix moved only its text, not its commands. Skill-directory and symlinked `~/.claude` collisions were never walked.

Max severity: minor
Ship allowed: yes
