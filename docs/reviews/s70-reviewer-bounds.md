# Review — s70-reviewer-bounds

[Story](../stories.md) · [Plan](../plans/s70-reviewer-bounds.md) · [Verification](../verif/s70-reviewer-bounds.md)

Diff reviewed: `git diff main...story/s70-reviewer-bounds`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 842ec2bb58941f8d7ebb7f2c78f9323366d0ade2

## Ownership
I listed the diff with `git diff --name-status main...story/s70-reviewer-bounds`. It touches 7 paths.
- [x] Every path is inside `Owns`:
  - These three are on the story's `Owns` line: `method/hooks/po-bounds.sh`, `method/agents/reviewer.md`, `tests/bounds.test.sh`.
  - The research, plan and verif files are the story's own pipeline evidence, so they are in scope by construction.
  - `docs/decisions/ADR-0047-…md` is added (status `A`) and the plan names it, so it is in scope too.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. The only other unmerged lane is `s72-overlap-direction`, and its `Owns` shares no path with this diff.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s70-reviewer-bounds` exited 0, so I reused the record:
  - The unit suite (`bash tests/run.sh`) exited 0 on the recorded code.
  - The project has no type check, E2E or build command (`Typecheck: —`, `E2E: —`, `Build: —`).
  - I read its "Not proven here" section; it is carried into Not verified below.
- [x] `po-gate qa-current` was not required: the story has no screen.

## Plan
- [x] Tasks 1–6 are all present, and I found no unrequested change.
- [x] Each run interdict holds:
  - `lex_command`: no changed line inside it. The new functions are added after its closing brace.
  - Existing tests in `tests/bounds.test.sh`: the diff only adds lines, after line 372.
  - `reviewer.md` `tools:` line: unchanged.
  - Files that must stay untouched (`method/AGENTS.md`, `docs/installation.md`, `tests/structure.test.sh`, the skills, `implementer.md`, `qa.md`, `.claude/`, `.polype/`, ADR-0039): none is in the diff.
  - No new dependency and no `realpath`; only jq and POSIX tools are used.
  - `tests/lib.sh`: unchanged.

## References
- [x] I opened every helper the new code calls and confirmed each exists with the arguments used: `owns_line` (line 135), `resolve_path`, `join_dir`, `QA_GIT_VERBS`, `story_base`, `deny`, `frontmatter`, `hook_command`, `lane`, `status_with`.
- [x] `check_git_read` and `check_restore` reuse `vals`, `n`, `cmd` and `mode` from `check_bash`. That works because bash locals are dynamically scoped.
- [x] Values that might only look right:
  - The temp root is resolved physically, and `/` or a missing directory leaves it empty. The tests cover both cases.

## Rules
- [x] The conventions in `AGENTS.md` are respected: the method file is in English and the `Reads settings` line is unchanged.
- [ ] ADR-0047 is contradicted on two points: the "Partout … `--work-tree` refusé" rule and the "une écriture doit aussi satisfaire cette condition" rule. See M2 and M3.

## Tests
- [x] Floor: `po-gate floor-guard s70-reviewer-bounds main` exited 0, so nothing was lowered.
- [x] The four tests carry the acceptance criteria's names and assert exit codes from the real script, fed real JSON. Fixtures and mocks:
  - The temp root is a separate `mktemp -d`, outside `$SCRATCH`.
  - None of the six empty test shapes appears.
- [x] 4 tests, within the budget of 25.
- [x] Bite: I disabled four rules one at a time and ran only `bounds.test.sh` after each change. After each, `git checkout -- method/hooks/po-bounds.sh` plus `git diff --exit-code` came back clean.
  - Dropping the common-dir check in `in_temp_zone` made 2 tests fail (`reviewer_git_is_read_only_outside_restores`, `reviewer_writes_only_in_its_story_or_temp`).
  - Replacing `check_git_read` for other verbs in the story worktree with a no-op made 1 test fail.
  - Accepting any option in `check_restore` made 1 test fail.
  - Neutralising the global `push|send-pack` refusal made 1 test fail.
- [x] No test became useless because of this story.

## Neighbours
- [x] `story_of_dir` (implementer and qa modes) now goes through `try_story_of_dir` and denies the same way. The qa checks moved into `check_git_read` with the same meaning. The existing qa and implementer tests are green, both in the record and in my focused run (21/21).
- [ ] `method/AGENTS.md:123` and `docs/installation.md:80-103` still say po-bounds holds only the implementer and qa (m1).

## Lenses
Lenses run: security — `method/hooks/po-bounds.sh` is a permission policy, and the diff adds a check on who may change which repository.
- [x] Each lens finding is graded on the scale and listed under Findings (M1–M3).

## Findings
I probed the three majors in a throwaway sandbox: a scratch repo outside a separate `TMPDIR`. I deleted the sandbox afterwards.

- **major (M1)** — `method/hooks/po-bounds.sh:613` — The reviewer's git directory is computed from the cwd and the last `-C` only, but git chains every `-C`. With cwd = a temp probe, `git -C <main checkout> -C . commit -m x` is checked as the temp dir and passes (exit 0). It actually commits in the main repository; I confirmed the commit landed in the sandbox's main repo. This breaks the acceptance criterion's "toute commande git hors de ce worktree ou d'un dépôt jetable … refusée". The parsing is inherited from implementer mode, but the reviewer zone decision depends on it. Fix: fold every `-C` into `gdir`, or refuse a second `-C` in mode reviewer.
- **major (M2)** — `method/hooks/po-bounds.sh:602` — `-c` is skipped without being read, so `-c core.worktree=<path>` does what the refused `--work-tree` does. Both of these pass:
  - `git -C <tmp>/probe -c core.worktree=<main> reset --hard`, which rewrites the main checkout's files.
  - `git -C <story wt> -c core.worktree=<main> checkout -- src/app.sh`, which writes into the main checkout.

  ADR-0047 accepts only the separate `git config core.worktree` gap and says `--work-tree` is refused everywhere. In mode reviewer, refuse `-c core.worktree=*` (and `core.worktree` given as a `-c` value).
- **major (M3)** — `method/hooks/po-bounds.sh:624` — In the temp zone "any verb" passes without looking at the verb's path arguments. So `git -C <tmp>/probe worktree add <main>/evil`, `git -C <tmp> clone <main> <main>/sub` and `git init <main>/x` all pass. Each creates files inside the main checkout, which then show up as stray uncommitted work there. This contradicts ADR-0047's "Dans le dépôt jetable, une écriture doit aussi satisfaire cette condition". It is contained: no ref or tracked file of the main repo changes.
- **minor (m1)** — `method/AGENTS.md:123`, `docs/installation.md:80-103` — Both still describe po-bounds as holding only the implementer and qa. They are outside `Owns`; the plan and ADR-0047 defer them. `method/AGENTS.md` is in s72's `Owns`, so the fix has to wait for s72 or go into a follow-up story.
- **minor (m2)** — `method/hooks/po-bounds.sh` (QA allowlist reused) — In the story worktree, `git branch --show-current` and `git branch --merged/--no-merged` are refused. ADR-0047 accepts this and gives the workaround (`merge-base --is-ancestor`, `log`). It is a friction point for the review's "branch not merged" check and is worth one sentence in `reviewer.md`.
- **minor (m3)** — ADR-0047, Consequences (neutral) — Once `polype install --global` ships the new reviewer, a project whose `.polype/hooks/po-bounds.sh` predates s70 refuses every reviewer call (unknown mode). It fails closed, so every review is blocked until `polype init`. This is documented in the ADR only, not in `docs/installation.md`.

## Not verified
- **Whether Claude Code actually runs the reviewer's frontmatter hook in a real `/po-review` dispatch or under `bin/po-eval`.** This review ran under the previously installed reviewer, which has no hook. A person should run one `/po-review` after `polype init` and confirm that a deliberate `git -C <repo root> status` from the reviewer is refused.
- **What `TMPDIR` is inside a real (possibly sandboxed) reviewer session**, and so whether probes under `/tmp` are accepted there. If it differs, the hook fails closed, and the first real review shows it.
- **macOS behaviour** of `cd -P`/`pwd -P` and of a `/var/folders` `TMPDIR`. I tested on Linux only. A person on macOS should run `bash tests/run.sh bounds.test.sh`.
- **Git calls made from a script, Bash redirections, `cp`/`sed -i`, and a previously exported `GIT_DIR`.** ADR-0047 accepts all of these as gaps, and I did not probe them further.
- **The full suite was not rerun.** I relied on the record's passing run for the tree outside `docs/`; I only ran `bounds.test.sh`, as the baseline and for the bite runs.
- **Lanes of other running stories.** The hook cannot tell which story the reviewer is reviewing, so writes into another lane's worktree are allowed (an accepted gap). I did not exercise this.

Max severity: major
Ship allowed: yes
