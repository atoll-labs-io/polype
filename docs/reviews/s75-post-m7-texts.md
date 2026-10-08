# Review: s75-post-m7-texts

Reviewed tree: 15a12ea83167670ce78ebfba7776e252fd143120
Fix loop: 0
Lenses run: none (only markdown and bash text tests changed; no auth/route, migration, lockfile or server code path or content in the diff)

Review status: blocked

- **Failure cause:** I could not finish step 4 (bite proof). I changed two rules: ADR-0041 `supersedes: [ADR-0037]` → `[]`, and the `d'avant s70` sentence in `docs/installation.md`. Then I tried to run only the affected test file, `cd /home/lecrabe/dev/atoll/polype/.worktrees/s75-post-m7-texts && bash tests/run.sh post-m7-texts.test.sh`. The Claude Code auto-mode permission classifier refused it with: "Permission for this action was denied by the Claude Code auto mode classifier. Reason: [Irreversible Local Destruction]." I did not try any other route to run it. I put both edits back with Edit, and `git diff --exit-code` exits 0 with an empty `git status --porcelain`. The tree is still 15a12ea8… after the undo.
- **Missing:** the number of failing tests for each disabled rule. Without it, nothing shows that the 4 new tests catch these rules being removed.
- **Required adaptation:** the reviewer subagent needs permission to run `bash tests/run.sh <file>` inside the story worktree, for example a Bash allow rule for `bash tests/run.sh*` in the user's or project's Claude Code settings. Only the user can grant this.
- **Next action:** a person grants that permission and runs `/po-review s75-post-m7-texts` again. Or a person does the bite proof by hand: (1) in `docs/decisions/ADR-0041-…md` set `supersedes: []`, then run `bash tests/run.sh post-m7-texts.test.sh`; `test_partial_supersession_is_written_and_linked` should fail. (2) In `docs/installation.md` remove `d'avant s70`; `test_installation_describes_the_reviewer_mode` should fail. Then `git checkout -- <file>` and `git diff --exit-code`.

## What was done
- **Scope:** all 14 changed paths are inside `Owns` (`docs/stories.md:1149`), counting the plan and verif files, which are the story's own pipeline evidence. s74 is in flight and owns `method/hooks/po-bounds.sh`, `method/agents/reviewer.md` and `tests/bounds.test.sh`. The diff touches none of them.
- **Step 1:** `po-gate verif-current s75-post-m7-texts` exit 0. The record is complete and the unit suite `bash tests/run.sh` exited 0 on code matching this tree. Typecheck, E2E and Build are `—`: the project has none. With `Verification mode: record`, I relied on the record and did not rerun the suite. Its "Not proven here" says the installed copies are refreshed after ship.
- **Step 2:** every reference checked out:
  - `frontmatter` and `contains` exist in `tests/lib.sh`.
  - ADR-0047 and ADR-0050 exist and say what the installation text claims.
  - `po-bounds.sh:682-683` refuses unknown modes, which confirms the "mode inconnu" claim.
  - `method/agents/reviewer.md:16` wires `po-bounds.sh reviewer`.
  - Check 8 of `stories-review` is the cited overlap rule.
- **Step 3:** all 6 tasks are present. The run interdicts hold:
  - exactly 4 `supersedes:` lines changed in `docs/decisions/`;
  - no ADR body or `status:` line touched;
  - ADR-0039 keeps `superseded`/`[ADR-0050]`;
  - only line 123 of `method/AGENTS.md` changed;
  - root `AGENTS.md`, `.claude/` and `.polype/` are untouched.
- **Step 4:** `po-gate floor-guard s75-post-m7-texts main` exit 0. The two existing test changes (`installer.test.sh:186`, `structure.test.sh:82`) follow the clauses this story changes, and the plan says so. 4 new tests, within budget. The partial-supersession test checks the link from both sides. Bite proof: blocked, see above.
- **Step 5/6:** nothing parses the `supersedes` fields or the ADR template by machine except `tests/pilot.test.sh:49`, which still passes per the record. ADR-0024, ADR-0029 and ADR-0037 already pointed forward to these successors.

## Findings
- **minor** — `docs/installation.md` "Le mode reviewer": "n'importe quel verbe sauf `push`" leaves out `send-pack`, which ADR-0047 also refuses in the temp zone. The "Partout" sentence also leaves out the refusals of `--git-dir`, `--work-tree`, `GIT_DIR=` and `GIT_WORK_TREE=` for the reviewer. Both omissions match the plan's own task 1 wording, so this is precision rather than error.
- **minor** — `docs/installation.md:92-96`: the sentence "Ne sont pas lus non plus une variable …, un alias git, et, pour `implementer` et `qa`, … ni …" reads awkwardly. It also sits under a heading titled "de l'implementer" while it now speaks of `qa` as well.
- **minor** — `method/commands/po-architect.md:48` now allows the frontmatter links of an accepted ADR to change. Law 6 in `method/AGENTS.md` still says flatly "An accepted ADR is never edited". The plan's interdict keeps Law 6 as is on purpose, but the two texts now differ slightly.
- **minor** — `method/templates/adr.md`: the comments now sit on the `supersedes: []` / `superseded-by: []` lines (the plan's pivot). An author who keeps a comment on a filled line will break exact-line checks such as `tests/leftovers.test.sh:15`. The field lines themselves still read `supersedes: []` and `superseded-by: []`.
- **note (not a finding against this story)** — ADR-0041:35 also partly replaces ADR-0034, which is not linked. ADR-0034 is outside `Owns`; the plan's Open question records this for a later story.

## Not verified
- **Bite proof of the 4 new tests:** the test run was refused by the permission system. A person should do the two mutations described in Next action.
- **The full suite on this exact tree:** I relied on the `po-run` record, not a fresh run.
- **The installed copies** (`.claude/`, `.polype/`, root `AGENTS.md`): they are refreshed after ship, so the installed `po-bounds` text was not checked against the new rules. Someone should check after the post-ship refresh commit.
- **Overlap with the Killer SaaS text:** I did not run `tests/overlap.test.sh` myself; the record covers it.

Max severity: minor
Ship allowed: no

---

# Review: s75-post-m7-texts

Reviewed tree: 15a12ea83167670ce78ebfba7776e252fd143120
Fix loop: 0
Lenses run: none. The diff changes only markdown and bash text tests. It has no auth, route, migration, lockfile or server-code path or content.

Review status: complete

## Scope
- Running `git diff --name-only main...story/s75-post-m7-texts` lists 14 paths. All are inside the `Owns` line at `docs/stories.md:1149`. Two of them, `docs/plans/s75-post-m7-texts.md` and `docs/verif/s75-post-m7-texts.md`, are the story's own pipeline evidence.
- Overlap with s74: `git worktree list` shows only main and this worktree. s74 has shipped to main (d814b8c). It touched `method/hooks/po-bounds.sh`, `method/agents/reviewer.md`, `tests/bounds.test.sh`, ADR-0047/0051 and `.polype/`. This diff touches none of those files. There is no critical overlap.
- The story branch starts from efc5719, before s74 was merged. I tried to check that it merges cleanly onto the current main with `git merge-tree`. po-bounds refused that command ("git merge-tree is forbidden in mode reviewer"). I did not try another way. The two change sets touch different files, so a textual conflict is unlikely. That is inferred, not proven.
- From an earlier attempt, the worktree has an untracked `docs/reviews/s75-post-m7-texts.md`. It is a blocked review on the same tree. I left it alone. Law 4 allows a review file under `docs/`, and the calling command overwrites it.

## What was done
- **Step 1:** `po-gate verif-current s75-post-m7-texts` exited 0. The record is complete. The unit suite `bash tests/run.sh` exited 0 on code that matches this tree. Typecheck, E2E and Build are `—`: the project has none of them. Under `Verification mode: record` I relied on the record and did not rerun the full suite. Its "Not proven here" section says the installed copies (`.claude/`, `.polype/`, root `AGENTS.md`) are refreshed after ship. The story has no screen and `QA stage` is `—`, so no QA was required.
- **Step 2:** each reference checks out against the files:
  - `frontmatter` and `contains` exist (`tests/lib.sh:13,43`).
  - `method/agents/reviewer.md:16` calls `po-bounds.sh reviewer` on `Edit|Write|Bash`.
  - `po-bounds.sh:682-683` refuses an unknown mode with "unknown mode". This backs the « mode inconnu » claim.
  - In reviewer mode, writes in the worktree are allowed anywhere except `.git`, git is limited to reading verbs plus `checkout --` and `restore`, and `GIT_DIR=` and `--git-dir` are refused. This matches the new text, including the "pour `implementer` et `qa`" limitation.
  - The cited check-8 phrasing is the same one already used in `method/AGENTS.md:51`.
- **Step 3:** all 6 tasks of the plan are done, and nothing was changed that the plan did not ask for. The interdicts hold:
  - `git diff --stat main...story -- docs/decisions/` shows 4 files with one line each, all `supersedes:` lines. No body or `status:` line changed.
  - ADR-0039 keeps `superseded` / `[ADR-0050]`.
  - Only line 123 of `method/AGENTS.md` changed.
  - Root `AGENTS.md`, `.claude/` and `.polype/` are untouched.
  - The template's field lines still begin `supersedes: []` and `superseded-by: []`.
- **Step 4:**
  - `po-gate floor-guard s75-post-m7-texts main` exited 0.
  - The two existing pins changed (`tests/installer.test.sh:186`, `tests/structure.test.sh:82`). Both follow clauses this story changes, and the plan says so.
  - 4 new tests, within the budget of 25.
  - The baseline run of `post-m7-texts`, `installer` and `structure` gave 30 passed, 0 failed.
  - Bite 1: I set `supersedes: []` in ADR-0041 and ran `post-m7-texts.test.sh`. 1 test failed: `partial_supersession_is_written_and_linked` ("ADR-0041 lacks supersedes ADR-0037"). Restored with `git checkout --`; `git diff --exit-code` is clean.
  - Bite 2: I removed the pre-s70 upgrade paragraph from `docs/installation.md` and ran `post-m7-texts` and `installer`. 1 test failed: `installation_describes_the_reviewer_mode` ("lacks: d'avant s70"). Restored; `git diff --exit-code` is clean.
- **Step 5/6:** the only machine reader of the ADR template and the `supersedes` fields is `tests/pilot.test.sh:49`, which is green per the record. The predecessors ADR-0024, 0029 and 0037 already named these successors in `superseded-by`, and the new test checks the link from both sides.

## Findings
- **M1 (major): the new `### Le mode reviewer` text is already out of date with main.** It is at `docs/installation.md:112-123`. It cites only ADR-0047 and says that in the temp dir the reviewer « peut lancer n'importe quel verbe sauf `push` ». On main, s74's ADR-0051 (`supersedes: [ADR-0047]`, in part) has since added rules that this text leaves out:
  - every path a git call names after its verb must resolve under the temp dir;
  - an unknown `-C` or `cd` directory is refused;
  - `core.worktree` and `GIT_CONFIG_PARAMETERS=` / `GIT_CONFIG_COUNT=` are refused everywhere.

  The plan chose to stay at ADR-0047's level on purpose, to keep clear of s74's lane. But s74 has now shipped, so this story lands text that is less strict than the hook. That is exactly what the story set out to prevent. The damage is contained: a reader would at worst get a refusal they did not expect. Follow-up: cite ADR-0051 and state the temp-zone path rule.
- **m1 (minor):** the new sentence at `docs/installation.md:92-96` mixes « et » with « ni » (« un alias git, et, pour `implementer` et `qa`, `GIT_DIR=… git reset`, … ni `git fetch . HEAD:main` »), which is awkward French.
- **m2 (minor):** ADR-0041's body (`:35`) also replaces neutral consequences of ADR-0034, but ADR-0041 ↔ ADR-0034 are not linked. This is outside `Owns`, and the plan records it as an open question. It is left for a later story.
- **m3 (minor):** the template now carries comments on the `supersedes:` / `superseded-by:` lines. An author who copies them into a real ADR would break exact-line checks like `tests/leftovers.test.sh:15`. The plan flags this risk itself, and `/po-architect` carries the rule in prose.
- **m4 (minor):** in `tests/post-m7-texts.test.sh`, the loop variable `p` is not declared `local` in `test_installation_describes_the_reviewer_mode`.

## Not verified
- **A clean merge of the story branch onto the current main (f85b20d).** po-bounds refused `git merge-tree`. To cover it, a person runs `git merge-tree --write-tree main story/s75-post-m7-texts` from the main checkout before ship.
- **The full suite on this tree.** I relied on the po-run record (Verification mode: record) and reran only the three affected test files. The suite was never run on the code as it will be after merging with s74. To cover it, run `bash tests/run.sh` on main after the squash.
- **The installed copies** (`.claude/`, `.polype/`, root `AGENTS.md`). By design they are not refreshed in this story. To cover it, run the post-ship refresh commit and `polype check`.
- **Whether the French prose of `### Le mode reviewer` is free of Killer SaaS text.** I relied on `tests/overlap.test.sh`, which is green per the record. I did not compare it by hand.

Max severity: major
Ship allowed: yes
