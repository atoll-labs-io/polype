# Research — s106-framing-through-pr

[Story](../stories.md)

## Structuring facts
- No story assumption is false. The seven framing commands commit on `Target branch` today, from the root, and none of them pushes: `po-setup.md:56`, `po-brief.md:59`, `po-prd.md:57`, `po-stories.md:60` (and its fix mode, `:56`), `po-stories-review.md:54`, `po-architect.md:72`, `po-design-system.md:74`. The story moves where each commit is made. Each command's checks and approvals stay as they are.
- The mechanism to reuse already exists twice. `po-ship.md:44` (s102) builds the settings commit beside any checkout: a temporary index (`GIT_INDEX_FILE`) and `git commit-tree … -p origin/<Target branch>`. It pushes that commit with a lease to `framing/ship-confirmation` and opens the PR. `po-ship.md:66-82` (s105, ADR-0081) builds the landing commit with `commit-tree` and merges with `gh pr merge <url> --rebase --match-head-commit <sha>` once the effective `Ship confirmation` allows it. Proof of the merge is `MERGED`. Without a remote, the landing is `git merge --ff-only <sha>` in the root.
- The root keeps the framing files uncommitted after the commit is built beside it. A fast-forward of the root then refuses them unless they are staged first. This was tried in a throwaway repository (git 2.56): `git merge --ff-only` refused an untracked `brief.md` and a modified `a` ("seraient écrasées / effacés"). After `git add` of those same paths, it fast-forwarded cleanly.
- `/po-research` starts a story from `origin/<Target branch>` when that ref exists (`po-research.md:30`). It never checks that the story is there, and it reads the story from the root's `docs/stories.md` (`po-research.md:23`).
- `method/AGENTS.md:98` still says that the framing files "are committed on `Target branch`". `AGENTS.md` is not in this story's `Owns`, since s103 and s104 own it. The line stays, and that is consistent: the files do end up on `Target branch`, through a PR.

## Story
In this repository, each of the seven framing commands commits on a branch `framing/<slug>` that starts from `Target branch`. It pushes the branch, opens a PR and lands it as a fast-forward. The agent lands it under the effective `automatic`; the person lands it under `human`. Without a remote, the command fast-forwards on the machine. No framing command commits on `Target branch` or pushes it. `/po-research` creates a story's worktree only when the story's section is on the start point. Otherwise it stops and says that the framing PR is waiting for its merge.
Criteria: `framing_commits_on_a_branch`, `framing_pr_fast_forwards`, `research_waits_for_framing_merge`.

## Current code
| File | Today |
| --- | --- |
| `method/commands/po-setup.md:52-56` | Step 3 writes `AGENTS.local.md`, edits `.gitignore` and reruns the installer. It then commits `AGENTS.local.md`, `.gitignore`, `AGENTS.md`, `.claude/` and `.polype/` "On `Target branch`" as `chore: set up polype`. `Reads settings: none` (`:13`). Step 1 already reads the forge through `## The forge's review rule` of po-ship (`:27`). Step 2 asks `Merge mode` and `Target branch` (`:32`) and writes `Ship confirmation` (`:40`). |
| `method/commands/po-brief.md:56-59` | Finish step 1 checks that the root is on `Target branch` and checks `git status --porcelain`. Step 4 is "From the repository root, commit `docs/brief.md` and the ADR together in one commit, `docs: brief for <product>`". `description` (`:2`) says "commit an approved docs/brief.md on the target branch". Reads `Entry mode`, `Target branch`, `ADR directory` (`:16`). |
| `method/commands/po-prd.md:57` | "Commit from the repository root, on `Target branch` only; …", then `docs/prd.md` alone as `docs: PRD for <target>`. The description at `:2` says "on the target branch". |
| `method/commands/po-stories.md:56,60` | The fix mode commit "follows "Finish"" with `docs: stories fixed after review`. Finish has the same sentence as the PRD, with `docs/stories.md` committed as `docs: stories for <product>`. |
| `method/commands/po-stories-review.md:16,26,54` | Writes the review "on `Target branch`" (`:16`), checks the branch (`:26`), then commits `docs/reviews/stories.md` "alone on `Target branch`" as `docs: stories review` (`:54`). |
| `method/commands/po-architect.md:20,72` | Branch check at `:20`. Commits `docs/architecture.md`, the new ADRs, `AGENTS.local.md` and possibly `AGENTS.md` "On `Target branch`" as `docs: architecture` (`:72`). |
| `method/commands/po-design-system.md:20,74` | Branch check at `:20`. Commits `docs/design-system.md` "On `Target branch`" as `docs: design system` (`:74`). |
| `method/commands/po-research.md:26-32` | Creates the worktree: fetch, start point, `git worktree add -b story/<id> <path> <start point>`, `.env*`, `Install`. It has no check on the story itself. |

## Attachment points
- One new section, `## Landing the framing`, in `po-setup.md`, as the single home of the procedure. Each of the six other commands replaces its commit sentence with: its paths, its message, its `framing/<slug>`, and a reference to that section (`method/commands/po-setup.md`). This follows an existing habit: commands cite another command's section by its `method/commands/<name>.md` path (`po-setup.md:27`, `po-drive.md:86`, `po-status.md:35`).
- `po-research.md`, `## The worktree`: a new step between the fetch (`:30`) and `git worktree add` (`:31`).
- New test file `tests/framing-through-pr.test.sh`.

## Verified interfaces
- `po-ship.md:27-42`: `## The forge's review rule` sets the **effective** `Ship confirmation`, `human` on a collaborative repository whatever the line says (`:40`). Only `/po-ship` rewrites the line (`:42`). The framing landing can read the rule without rewriting the line.
- `po-ship.md:62`, the remote check: `pr` without `origin` → stop; `local` with a remote → stop, citing ADR-0080.
- `po-ship.md:44`: on a forge where no PR is opened yet (GitHub only, per ADR-0081), the branch is sent and the report asks a person to open the PR. A refused push is never forced.
- `po-ship.md:78-79`, local and `human`: an AskUserQuestion with Merge / Not now, then `git merge --ff-only <sha>` in the root, which must be on `Target branch`.
- `po-gate.sh:244-262`, `pre_commit`: a secret and `.env` scan over `git diff --cached`, which honours `GIT_INDEX_FILE`. Its story branch rule applies only on `story/*`. `git commit-tree` skips the hooks, so a landing built beside the checkout must call `po-gate.sh pre-commit` itself with the temporary index. Without that call, it loses the scan the old `git commit` got when hooks are on.
- The story heading is `## <id> — <title>` in `method/templates/stories.md:7`, but `### <id> — …` in this repository (`docs/stories.md:11`). The research check must accept both.
- All 8 commands have `Bash`. All but `po-research` have `AskUserQuestion` (frontmatters read).

## Traps
- **Frozen phrases** that must stay word for word:
  - `brief.test.sh:61-84`: Finish keeps `git status --porcelain` before `set \`status: approved\``, keeps `` `Target branch` `` and `leaves \`docs/brief.md\` at \`status: interviewing\``. The commit line keeps `docs: brief for <product>`, `docs/brief.md`, `the ADR` and `in one commit`, and the section keeps "The approval and its ADR go in the same commit, or neither".
  - `stories-review.test.sh:49`: "writes `docs/reviews/stories.md` on `Target branch`".
  - `structure.test.sh:41-43`: "lists the `Worktree root` folder and `.env*`" and "`.claude/` and `.polype/` together".
  - `research.test.sh:6-14`: "git worktree add -b story/<id> <path> <start point>", "Do not run the tests.", "Do not repair it with `switch`, `checkout` or `stash`.", "start from `origin/<Target branch>` if that ref exists".
  - `conversational-framing.test.sh:10`: "Each item is written only once approved, and the commit asks for no rereading.", plus the `Approval and commit` headings of architect and design-system (`:40`, `architect.test.sh:66`).
  - `ship-follows-forge.test.sh:18-26`: Step 1 and Step 2 of po-setup (forge, `(chosen)` answers). Adding a section after Step 3 keeps them.
- `ship-through-pr.test.sh:31-34` only greps `git push` in po-ship, so new pushes in po-setup do not affect it.
- Settings: `structure.test.sh` (`settings_read_by`) wants every listed setting in the template. `Merge mode` and `Ship confirmation` exist there.
- `tests/overlap.test.sh`: no new line may share 8 consecutive words with Killer SaaS (ADR-0006).
- `po-drive.md:86` (not owned) restates research's worktree steps. A driver following that restatement could skip the new check. The line says "exactly as `/po-research` describes it", so the check is covered by reference. Spelling it out belongs to a later story that owns `po-drive.md` (s104).
- Bootstrap: on a fresh remote where `origin/<Target branch>` does not exist yet, nothing can be landed by PR. A person pushes `Target branch` once, since no agent pushes it.
- Under `human`, the files stay staged and uncommitted in the root until the person merges and the root catches up (`git pull --ff-only`, or the next agent-merged landing). This is because staging keeps that fast-forward possible.
- No migration, no dependency, no ADR needed: ADR-0080 settles "framing goes through a branch and a PR". ADR-0081 settles both the commit built beside the checkout without a checkout or a worktree (Q2 option 1) and the GitHub merge command. s102 already applied both to settings (`po-ship.md:44`).
- Full baseline before the story: `bash tests/run.sh` → 471 passed, 0 failed.

## Open questions
- Cross-references use `method/commands/po-setup.md`. In an installed project, that path is `.claude/commands/po-setup.md` or `~/.claude/commands/po-setup.md`. The precedent (`po-setup.md:27`) has the same gap. The plan follows the precedent and does not fix it here.
- `method/AGENTS.md:98` (Law 6) and `po-help.md` do not say that framing lands through a PR. That wording belongs to s104 (Law 6) or to a later story.
- Whether `gh pr checks --watch` exists in every installed `gh` was not checked on this machine. The plan only waits for the checks when the PR has any.

## Complexity
Story 3 → 3. There are seven commands and one shared procedure. The mechanisms already exist (s102, s105), and the one subtle point is staging the root's index, which a throwaway repository confirmed.

## Split
—
