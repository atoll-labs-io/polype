# Review: s78-platform-setting

I found no critical issue, so the ship can go ahead. There are two findings: one major and one minor.

- Story: s78-platform-setting, "Le projet déclare ses plateformes, la story sa surface"
- Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s78-platform-setting, on branch `story/s78-platform-setting`
- Scope: `git diff main...story/s78-platform-setting`, which is one commit, 7dfd218
- Reviewed tree: 45a5b7e09b254ab207ac0034b87d093259b09909 (taken again just before answering: unchanged)
- Fix loop: 0
- Lenses run: none. The diff touches no auth, route, handler, migration, lockfile or server code.

## Scope check (Owns)
- **Every changed path is inside the story's `Owns`:**
  - `AGENTS.local.md`
  - `bin/po-lint`
  - `boilerplates/next-forge/profile.md`
  - the 10 `method/` files
  - `tests/platform-setting.test.sh` and `tests/profile.test.sh`
- **Pipeline evidence** is in scope by construction: the research, plan and verif files of s78.
- **`docs/decisions/ADR-0055-chaque-plateforme-admet-ses-surfaces.md`** is newly added (status `A`) and the plan names it, so it is in scope by construction.
- **Other stories:** `git worktree list` shows no other running story, so there is no conflict with another lane.

## Checks
- [x] **`po-gate verif-current s78-platform-setting`** exits 0. The record is complete; Unit suite (`bash tests/run.sh`) and Lint (`bash bin/po-lint`) both exited 0 on this code. With `Verification mode: record` I relied on that record and did not rerun the full suite. I read its "Not proven here" section.
- [x] **Type check, E2E and Build** are `—` in AGENTS.local.md, so the project has none of these commands.
- [x] **`po-gate qa-current`** is not required: the story has no screen (`Surface: —`) and `QA stage: —`.
- [x] **`po-gate floor-guard s78-platform-setting main`** exits 0: nothing was lowered.
- [x] **The plan's run interdicts hold:**
  - none of the forbidden files is in the diff;
  - step 2 of `po-setup.md` still has five numbered lines;
  - `stories-review` checks 1-8 are unchanged and check 9 is only appended;
  - "`/po-qa` needs it and stops on `—`" is still in the settings template;
  - `grep -c mobile bin/po-lint` gives 0;
  - the pinned phrases from the research Traps are present.
- [x] **The six plan tasks are all present and match the plan.** There is no unrequested change. The commit message mentions the `tests/profile.test.sh` change, as the plan asked.
- [x] **References resolve:**
  - `$TEMPLATE` is defined at `bin/po-lint:90`;
  - `template_settings` and `settings_read_by` exist in `tests/lib.sh` (the tests load and pass);
  - ADR-0054 is accepted, and ADR-0055 matches it.
- [x] **Neighbours:** `po-bounds.sh` finds the `**Owns**` line by its marker, not by its position, so the new `Surface` line before `Owns` does not break it. `bin/polype` reads template settings, so an existing project will see `missing setting: Platform`. The plan and the ADR intend this.

## Bite proof
1. **The platform value check in `check_profiles`.** I replaced `|| report … "platform '$name' is not a value of the Platform setting"` with `|| true` and ran `platform-setting.test.sh`.
   - Result: 1 test failed (`profiles_declare_their_platform`: "lint accepts the platform Web").
   - Undone with `git checkout -- bin/po-lint`; `git diff --exit-code bin/po-lint` came back clean.
2. **The "no `- Platform:` line under `## Platform`" check.** I replaced its `report` with `true` and ran `platform-setting.test.sh`, `profile.test.sh` and `next-forge-profile.test.sh`.
   - Result: 0 of 13 tests failed. This branch is not tested (finding 2).
   - Undone the same way; `git diff --exit-code` came back clean.

I also probed `po-lint` on copies under the temp dir:

| Input | Result |
| --- | --- |
| empty value | flagged as `platform ''` |
| `web,` | flagged as `platform ''` |
| `web,api` | passes |
| ` cli ,  robot ` | passes |
| `web api` | flagged |
| settings template with no `| Platform |` row | one `templates/agents-local.md` breach, plus the profile's value flagged |

## Findings

1. **major — `QA stage: surfaces` is offered before anything acts on it, and the method contradicts itself.**
   - **Where:** `method/commands/po-setup.md` (the QA stage paragraph) and `method/templates/agents-local.md` (the `QA stage` row).
   - **What happens:** `/po-setup` now offers `surfaces`, and for `cli`/`api`/`lib`/`robot` projects with `Dev: —` it is the main option. Yet no reader of `QA stage` acts on it: `po-orchestrator.md:41,63`, `po-drive.md:53-55,96`, `po-status.md:29`, `reviewer.md` and `review-antihallu` all test only `screens`.
   - **Effect:** a project that picks `surfaces` gets no QA at all, without being told. A web project that picks it also loses the screen walk that `screens` would have given.
   - **Contradiction:** the same template still says "`/po-qa` needs it and stops on `—`", while setup offers `surfaces` exactly when `Dev` is `—`.
   - **Why only major:** the research Traps acknowledge this gap and leave it to s79/s80 on purpose, the acceptance criteria require setup to offer the value, and nothing that worked before breaks. Until s79 and s80 ship, a refreshed global install offers a value that does nothing.
   - **Options:** ship s79/s80 before refreshing any user install, or have `/po-setup` say that `surfaces` is not yet acted on.

2. **minor — the "no `- Platform:` line under `## Platform`" branch in `bin/po-lint` (`check_profiles`) has no test.**
   - Disabling it failed 0 tests (bite proof 2).
   - If this branch regressed, a profile with the heading but no line would pass lint and never be offered by `/po-setup`. That is exactly the silent drop ADR-0055 turns down.
   - One mutation case in `test_profiles_declare_their_platform` would cover it, for example deleting the `- Platform: web` line and expecting that breach.

## Not verified
- **The agents' behaviour is prose; only its wording is pinned by tests.** I did not run `/po-setup`, `/po-stories` or `/po-stories-review`, so I have not seen an agent ask the `Platform` follow-up, filter the catalogue, offer `surfaces`, write `Surface` lines, or rate them under check 9. To cover it, a person runs `/po-setup` in a scratch repo with `Platform: cli` and `Dev: —`, then `/po-stories` and `/po-stories-review` on a small brief.
- **I did not rerun the full unit suite or lint.** I relied on the po-run record, whose tree the gate confirms.
- **`bin/polype update` on an existing project:** I did not run it to see `missing setting: Platform: web` being only listed, never written. The plan says the installer never writes it (`bin/polype:194-211`), but I did not open that code. To cover it, run `polype update` on a copy of an older project.
- **A `Platform` setting value outside the seven:** `/po-stories` and `/po-stories-review` stop only when `Platform` is missing. Whether an agent rejects a misspelled value such as `Web` was not checked, and no rule says it should.
- **No screen and no QA**, so no design-conformity check applies.

Max severity: major
Ship allowed: yes

---

# Review: s78-platform-setting

There is no critical finding, so the ship can go ahead. I found one major issue and three minor ones.

- Story: s78-platform-setting, "Le projet déclare ses plateformes, la story sa surface"
- Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s78-platform-setting, on branch `story/s78-platform-setting` (HEAD c4a409f)
- Scope: `git diff main...story/s78-platform-setting`. It holds two commits:
  - 7dfd218, which carries the code, the tests, the evidence and ADR-0055;
  - c4a409f, which adds only `docs/reviews/s78-platform-setting.md`.
- Reviewed tree: f8850a20289bde263b072659000f9ff11634b368. I took it again just before answering and it had not changed.
- Fix loop: 1
- **No fix commit exists since the loop-0 review.** The code outside `docs/` is identical in 7dfd218 and c4a409f (`git diff --quiet 7dfd218 c4a409f -- . ':(exclude)docs'` exits 0). This loop therefore judges the same code as loop 0, and the loop-0 findings are still open.
- Lenses run: none. The diff touches no auth, route, handler, migration, lockfile or server code.

## Scope check (Owns)
- **Every changed path matches an entry of the story's `Owns` line** (docs/stories.md:1201):
  - `AGENTS.local.md`
  - `bin/po-lint`
  - `boilerplates/next-forge/profile.md`
  - `method/agents/stories-reviewer.md`
  - `method/commands/po-setup.md`, `po-stories.md` and `po-stories-review.md`
  - `method/skills/agentic-stories/` and `method/skills/stories-review/`
  - `method/templates/agents-local.md`, `profile.md` and `stories.md`
  - `tests/platform-setting.test.sh` and `tests/profile.test.sh`
- **Pipeline evidence** (research, plan, verif and review of s78) is in scope by construction.
- **`docs/decisions/ADR-0055-chaque-plateforme-admet-ses-surfaces.md`** has status `A` and the plan names it, so it is in scope by construction.
- **Other lanes:** `git worktree list` shows no other running story, so there is no conflict with another lane.

## Checks
- [x] **`po-gate verif-current s78-platform-setting`** exits 0. With `Verification mode: record`, I relied on its rows instead of rerunning them:
  - `bash tests/run.sh` exit 0;
  - `bash bin/po-lint` exit 0.

  I read its "Not proven here" section.
- [x] **Commands the project does not have:** `Typecheck`, `E2E` and `Build` are `—` in AGENTS.local.md.
- [x] **`po-gate qa-current`** is not required: the story has no screen (`Surface: —`) and `QA stage: —`.
- [x] **`po-gate floor-guard s78-platform-setting main`** exits 0: nothing was lowered.
- [x] **The plan's run interdicts hold:**
  - none of the forbidden files is in the diff;
  - step 2 of `po-setup.md` keeps exactly five numbered lines;
  - `stories-review` checks 1-8 are unchanged and check 9 is only appended;
  - "`/po-qa` needs it and stops on `—`" is still in the template;
  - `grep -c mobile bin/po-lint` gives 0.
- [x] **The plan's six tasks are all present as written, and nothing unrequested was added.** The commit message justifies the `tests/profile.test.sh` change.
- [x] **References resolve:**
  - `$TEMPLATE` exists in `bin/po-lint`.
  - `template_settings` and `settings_read_by` exist in `tests/lib.sh`.
  - `missing_settings` in `bin/polype:195-211` prints `missing setting: <name>: <value>` at the start of a line, so the test's `^missing setting:` grep is the right one.
  - ADR-0054 is `accepted`, and ADR-0055 settles the three points it left open.
- [x] **Neighbours:**
  - `po-bounds.sh` finds `**Owns**` by its marker, not by line position, so the new `Surface` line in the stories template does not disturb it.
  - `bin/polype check` names the new setting without writing it. I confirmed this by deleting `Platform:` from AGENTS.local.md: the output was `missing setting: Platform: web`. Then I restored the file.
  - The `QA stage` readers (`po-orchestrator.md:41,63`, `po-drive.md:53-55,96`, `po-status.md:29`, `method/AGENTS.md:37,64`, `templates/review.md:24`) still only check for `screens`. See finding 1.

## Bite proof
For each mutation I ran only `platform-setting.test.sh`, `profile.test.sh` and `next-forge-profile.test.sh`, adding `lint.test.sh` for mutations 2 and 3. I undid each one with `git checkout -- bin/po-lint`, and `git diff --exit-code bin/po-lint` came back clean every time.

| # | Mutation | Tests failed |
| --- | --- | --- |
| 1 | Split on commas removed in `check_profiles` (`done < <(tr ',' '\n' <<< "$value")` → `done <<< "$value"`) | 1 (`profiles_declare_their_platform`) — the rule is tested |
| 2 | `report … "no '- Platform:' line under '## Platform'"` replaced by `true` | 0 of 19 — untested (finding 2) |
| 3 | `|| report "templates/agents-local.md" 1 profile "no Platform values in the settings table"` replaced by `|| true` | 0 of 19 — untested (finding 3) |

The loop-0 review also showed that the per-value check bites: neutralising it fails `profiles_declare_their_platform`.

Final state: `git status --porcelain` is empty and `git diff --exit-code` exits 0.

## Findings

1. **major — `QA stage: surfaces` is offered before anything acts on it, and the template contradicts itself.** (Open since loop 0.)
   - **Where:** `method/commands/po-setup.md:41` and `method/templates/agents-local.md:54`.
   - **What happens:** `/po-setup` now offers `surfaces`. For `cli`/`api`/`lib`/`robot` projects whose `Dev` is `—`, it is the only real choice. Yet no reader of `QA stage` acts on it: orchestrator, drive, status, reviewer and the `qa-current` gate all key on `screens`.
   - **Effect:** a project that picks `surfaces` silently gets no QA. A web project that picks it also loses the screen walk that `screens` would have given.
   - **Contradiction:** the same template (`agents-local.md:83`) still says "`/po-qa` needs it and stops on `—`", while setup offers `surfaces` exactly when `Dev` is `—`.
   - **Why only major:** the acceptance criteria require this offer, the research leaves it to s79/s80, and nothing that already worked breaks.
   - **Mitigation:** either do not refresh any user's global install until s79/s80 ship, or have `/po-setup` say that `surfaces` is not yet acted on.

2. **minor — the "no `- Platform:` line under `## Platform`" branch of `check_profiles` in `bin/po-lint` has no test.** (Open since loop 0.)
   - Disabling it failed 0 tests (bite 2).
   - If it regressed, a profile with the heading but no line would pass the lint and never be offered by `/po-setup`. That is exactly the silent drop ADR-0055 rejects.
   - One extra mutation case in `test_profiles_declare_their_platform` would cover it: delete the `- Platform: web` line and expect that breach at the heading's line.

3. **minor — the "no Platform values in the settings table" report in `bin/po-lint` has no test** (bite 3).
   - Its effect is partly redundant: with an empty list, every profile value is flagged anyway.
   - But the message that names the real cause (`templates/agents-local.md`) is unguarded. ADR-0055's "Neutral" consequence calls that row fragile, so a test pinning the report is cheap insurance.

4. **minor — the heading of step 2 in `method/commands/po-setup.md:30` is now stale.**
   - It still reads "Five questions, one AskUserQuestion call each, plus one follow-up on design".
   - Step 2 now has three follow-ups (`Platform`, design, `QA stage`) plus the catalogue offer. The `QA stage` one predates this story; the `Platform` one is new.
   - Line 43 lists them correctly, so the heading contradicts the body.

## Not verified
- **The agents' behaviour is prose; tests pin only its wording.** I did not run `/po-setup`, `/po-stories` or `/po-stories-review`, so I have not seen:
  - an agent asking the `Platform` follow-up;
  - the catalogue being filtered by `- Platform:`;
  - `surfaces` being offered when `Dev` is `—`;
  - `Surface` lines being written or graded under check 9.

  To cover it, a person runs `/po-setup` in a scratch repo with `Platform: cli` and `Dev: —`, then `/po-stories` and `/po-stories-review` on a small brief, including one story whose `Surface` the platform does not admit.
- **The full unit suite and the lint were not rerun.** I relied on the po-run record, which the gate confirms is current. The type check, E2E and build do not exist in this project (`—`).
- **`polype update` on an older real project:** I only probed `polype check` on this worktree, where it lists `Platform: web` and writes nothing. To cover it, run `polype update` on a copy of a project set up before s78.
- **A misspelled `Platform` value in a project's AGENTS.local.md** (for example `Web`): `/po-stories` and `/po-stories-review` stop only when the setting is missing. No rule or test says how an agent handles an invalid value; to check it, run `/po-stories-review` with such a value.
- **No design check:** the story has no screen, so design conformity was not assessed.

Max severity: major
Ship allowed: yes

---

# Review: s78-platform-setting

No critical finding, so the ship can go ahead. One major finding and four minor ones are open. Since loop 0 there has been no fix commit: the code outside `docs/` in 7dfd218 is the same as at HEAD 5554d34 (`git diff --quiet 7dfd218 HEAD -- . ':(exclude)docs'` exits 0). This loop judges the same code as loops 0 and 1. I re-checked it on my own instead of copying the earlier reports.

- Story: s78-platform-setting, "Le projet déclare ses plateformes, la story sa surface"
- Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s78-platform-setting, branch `story/s78-platform-setting`, HEAD 5554d34
- Scope: `git diff main...story/s78-platform-setting`. It has three commits:
  - 7dfd218: code, tests, evidence and ADR-0055
  - c4a409f and 5554d34: only `docs/reviews/s78-platform-setting.md`
- Reviewed tree: 821b33f78011c48f1c8bf5157fa066ee671458db (taken again just before answering, unchanged)
- Fix loop: 2
- Lenses run: none. The diff touches no auth, route, handler, migration, lockfile, manifest or server code. `bin/po-lint` is a local lint script.

## Scope check (Owns)
- **Every code path in the diff is covered by the `Owns` line** at docs/stories.md:1201: `AGENTS.local.md`, `bin/po-lint`, `boilerplates/next-forge/profile.md`, `method/agents/stories-reviewer.md`, `method/commands/po-setup.md`, `po-stories.md`, `po-stories-review.md`, `method/skills/agentic-stories/`, `method/skills/stories-review/`, `method/templates/agents-local.md`, `profile.md`, `stories.md`, `tests/platform-setting.test.sh`, `tests/profile.test.sh`.
- **The pipeline evidence is in scope by construction:** research, plan, verif and review of s78.
- **`docs/decisions/ADR-0055-chaque-plateforme-admet-ses-surfaces.md`** has status `A` and the plan names it, so it is in scope by construction. The number does not clash with anything on `main`, where ADR-0054 is the highest.
- **No other lane:** `git worktree list` shows only the main checkout and this worktree.

## Checks
- [x] **`po-gate verif-current s78-platform-setting`** exits 0. With `Verification mode: record`, I relied on the record instead of rerunning:
  - `bash tests/run.sh`: exit 0
  - `bash bin/po-lint`: exit 0

  I read its "Not proven here" section.
- [x] **Commands the project does not have:** Typecheck, E2E and Build are `—` in AGENTS.local.md.
- [x] **`po-gate qa-current`** is not required: the story has no screen (`Surface: —`) and `QA stage: —`.
- [x] **`po-gate floor-guard s78-platform-setting main`** exits 0: nothing was lowered.
- [x] **Plan against diff:** all six tasks are there as written, and no change was added that the plan does not ask for.
  - Run interdicts hold: step 2 of po-setup keeps five numbered lines, check 9 is only appended, "`/po-qa` needs it and stops on `—`" is kept, and `bin/po-lint` hard-codes no platform list.
  - ADR-0055 settles the three points ADR-0054 left open and does not contradict it.
- [x] **References resolve:**
  - `$TEMPLATE` and `report` exist in `bin/po-lint`.
  - `template_settings` and `settings_read_by` exist in `tests/lib.sh`.
  - `tests/run.sh` runs each test function in its own `bash -c`, so the `trap … EXIT` and the `lint`/`fresh` helpers defined inside the test cannot leak. The same pattern is used in `tests/profile.test.sh:41-43`.
- [x] **Neighbours:**
  - `po-bounds.sh:199` finds `**Owns**` by its marker, so the new `Surface` line before it is harmless.
  - Nothing else in `bin/` or `method/hooks/` parses the bullets of a story by position.
  - Every reader of `QA stage` keys only on `screens`: `po-orchestrator.md:41,63`, `po-drive.md:25,53-55,96`, `po-status.md:29`, `method/AGENTS.md:37,64`, `templates/review.md:24`, `review-antihallu`. See finding 1.
- [x] **Probing `po-lint` on temp copies:** each of these values gives exactly one breach, as expected:

  | Value | Breach |
  | --- | --- |
  | `- Platform:` (empty) | `platform ''` |
  | `we` | `platform 'we'` |
  | `web,,api` | `platform ''` |
  | `web api` | `platform 'web api'` |

## Bite proof
Each mutation went into `bin/po-lint` and was tested against `platform-setting.test.sh`, `profile.test.sh` and `next-forge-profile.test.sh`. Mutation 3 also ran `lint.test.sh`. After each one I ran `git checkout -- bin/po-lint`, and `git diff --exit-code bin/po-lint` came back clean. At the end `git status --porcelain` is empty.

| # | Mutation | Tests failed |
| --- | --- | --- |
| 1 | Trimming of each value removed (`name=$(sed …)` → `name="$name"`) | 1 of 13 (`profiles_declare_their_platform`: "platform ' mobile'"). The comma split and the value check bite. |
| 2 | Whole-line match dropped in the value check (`grep -qxF` → `grep -qF`) | 0 of 13: untested (finding 2) |
| 3 | `report … "no '- Platform:' line under '## Platform'"` → `true` | 0 of 19: untested (finding 3, open since loop 0) |

## Findings
1. **major: `/po-setup` now offers `QA stage: surfaces`, but nothing uses that value yet, and the template contradicts itself.** (Open since loop 0.)
   - **Where:** `method/commands/po-setup.md:41` and `method/templates/agents-local.md:54`.
   - **What happens:** for `cli`/`api`/`lib`/`robot` projects with `Dev: —`, setup offers only `surfaces` or `—`. But every reader of `QA stage` (orchestrator, drive, status, reviewer, the `qa-current` gate) acts only on `screens`.
   - **Effect:** a project that picks `surfaces` silently gets no QA. A web project that picks it loses the screen walk `screens` would have given.
   - **Contradiction:** `agents-local.md:83` still says "`/po-qa` needs it and stops on `—`", while setup offers `surfaces` exactly when `Dev` is `—`.
   - **Why major and not critical:** the acceptance criteria require the offer, the plan forbids routing on it (that is s79/s80's work), and nothing that worked before breaks.
   - **Fix:** do not refresh any user's global install before s79/s80 ship, or have `/po-setup` say that `surfaces` is not acted on yet.
2. **minor: `bin/po-lint` has to match a platform value exactly, and no test checks that** (bite 2).
   - With `grep -qF`, `- Platform: we`, `cl` or an empty value would pass the lint. The profile would then never be offered by `/po-setup`, which is the silent drop ADR-0055 turns down.
   - The `Web` case in `test_profiles_declare_their_platform` does not catch this because it differs only by case.
   - One extra mutation case would cover it: a substring such as `we`, or an empty `- Platform:`, expecting one breach.
3. **minor: the "no `- Platform:` line under `## Platform`" branch of `check_profiles` has no test** (bite 3; open since loop 0).
   - One mutation case would cover it: delete the `- Platform: web` line and expect the breach at the heading's line.
4. **minor: the "no Platform values in the settings table" report in `bin/po-lint` has no test.**
   - I did not run this mutation again. The loop-1 bite (0 of 19) was on identical code.
   - Its effect overlaps with the per-value check, but it is the only message that names the real cause, a broken `| Platform |` row.
   - ADR-0055 itself calls that row fragile ("Neutral" consequence).
5. **minor: the heading of step 2 in `method/commands/po-setup.md:30` is out of date.** It still reads "Five questions, one AskUserQuestion call each, plus one follow-up on design". Step 2 now also has the `Platform` and `QA stage` follow-ups and the catalogue offer, as line 45 correctly lists.

## Not verified
- **Agent behaviour is prose, and the tests pin only its wording.** I did not run `/po-setup`, `/po-stories` or `/po-stories-review`. So I have not seen an agent:
  - ask the `Platform` follow-up
  - filter the catalogue by `- Platform:`
  - offer `surfaces` when `Dev` is `—`
  - write `Surface` lines
  - grade an unadmitted surface major under check 9

  To cover this, a person runs `/po-setup` in a scratch repo with `Platform: cli` and `Dev: —`, then `/po-stories` and `/po-stories-review` on a small brief that includes a `screen` story.
- **The full unit suite and the lint were not rerun.** I relied on the po-run record, which the gate confirms is current. The project has no Typecheck, E2E or Build command (`—`).
- **`polype update` on an older real project:** not run, so it is not confirmed that `missing setting: Platform: web` is only listed and never written. To cover this, run `polype update` on a copy of a project set up before s78.
- **A misspelled `Platform` in a project's AGENTS.local.md (for example `Web`):** `/po-stories` and `/po-stories-review` stop only when the setting is missing. No rule and no test says how an invalid value is handled. To check, run `/po-stories-review` with such a value.
- **Design conformity:** not assessed, because the story has no screen.

Max severity: major
Ship allowed: yes
