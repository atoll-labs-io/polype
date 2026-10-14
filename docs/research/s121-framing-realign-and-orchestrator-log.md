# Research — s121-framing-realign-and-orchestrator-log

[Story](../stories.md)

## Structuring facts
- **Root cause 1 (s110 major):** the root's fast-forward in `**Base.**` sits inside the `Merged →` bullet (`method/commands/po-setup.md:71`). That bullet is reached only when `origin/framing/<slug>` exists for **this** command's slug (`:66`) and is proven merged (`:67-69`). A landing whose own slug has no remote branch takes `<base>` = `origin/<Target branch>` at `:66` and never touches the root. Yet the `human` bullet promises "the next landing of any framing command realigns the root as **Base** says" (`:85`). Each command names its own slug (`:61`), so a merge of `framing/architect` is never seen by a `/po-stories` landing.
- **Root cause 2 (s109 minors):** `## The decisions log` of `method/commands/po-orchestrator.md:84` lists two kinds of lone decision only (plans approved under `autonomous`, fix runs). `AGENTS.md:79` and `po-drive.md:153` list more. Its timing (`:88`) names "shipped or the run stopped" only, while the finish (`:92`) treats "Pull request ready: <url>." as a third outcome. It lacks the `local` + `human` "Not now" caveat that `po-drive.md:155` carries.
- No story assumption is false: every file and section the story names exists as described.
- The phrase `never before its ship` in the orchestrator log is pinned by `tests/drive-guards.test.sh:63`. The old `human` sentence is pinned by `tests/framing-second-landing.test.sh:56`. Both test files are on the story's `Owns`.

## Diagnostic
**Reproduction** (no file created; reading plus the existing tests):
- `grep -n "merge --ff-only" method/commands/po-setup.md` prints three lines:
  - `:71`, inside `Merged →`;
  - `:88`, after this landing's own automatic merge;
  - `:93`, in local mode.
  None of them runs on a `pr` landing whose slug has no remote branch, or whose branch is not merged.
- `bash tests/run.sh framing-second-landing.test.sh drive-guards.test.sh framing-through-pr.test.sh` → 9 passed. The suite is green on the defect: `framing-second-landing.test.sh:56` asserts the over-promising sentence itself.

**Hypotheses**
1. *The realignment depends on the command's own slug.* Refuted if some slug-independent `--ff-only` runs before the commit build. The three matches above are all gated (own slug merged, own automatic merge, local). **Kept.**
2. *The `human` sentence is right because all framing commands share one branch.* Refuted by `:61` ("Each command names its own `<slug>`") and the distinct slugs in `tests/framing-through-pr.test.sh:8-16`. **Discarded.**
3. *The orchestrator logs fewer kinds than the rule.* Refuted if `po-orchestrator.md` lists the track, the implementation details and the unasked answers anywhere. It does not: `:84` names only the plan approvals and the fix runs. **Kept.**
4. *"or the run stopped" already covers "Pull request ready".* Its support is that `po-ship.md:76` says "stop here". The refutation is `po-orchestrator.md:92`, which lists "Pull request ready: <url>." as an outcome distinct from "the stage that stopped". So the text is at best ambiguous. **Discarded** as a defence; the timing needs the third case spelled out.
5. *The local "Not now" caveat reaches the orchestrator some other way.* Refuted if `po-orchestrator.md` points to `po-drive.md:155`. It does not: `:88` only says "as `/po-drive` does" about the landing. **Kept.**

## Story
- `every_landing_realigns_the_root`: in `## Landing the framing`, each landing starts, right after the `git fetch`, with `git merge --ff-only origin/<Target branch>` in the root whenever it is a fast-forward, whatever the slug. A refusal is reported and nothing is forced. The `human` bullet promises only what the command does.
- `orchestrator_logs_every_lone_decision`: the orchestrator's log also records the track it chose, each implementation detail it settled, and each answer it gave without asking. A run ending on "Pull request ready" writes its rows at that point. Under `Merge mode: local`, a "Not now" leaves the log staged in the root, as `/po-drive` says.

## Current code
- **`po-setup.md:60-95`** is `## Landing the framing`, used by every framing command and by both decisions-log landings (`po-drive.md:155`, `po-orchestrator.md:88`):
  - `:65-73` `**Base.**`;
  - `:75-79` the commit, built in a temporary index. `:79` stages `<paths>` in the root's index so a later fast-forward does not refuse;
  - `:81-88` pr mode. `:85` is the `human` stop and its over-promising sentence; `:88` realigns after an automatic merge;
  - `:90-93` local mode.
- **`:72` "That ref missing → stop"** refers to `origin/<Target branch>`. It is now placed after the `Merged` bullet, which already used that ref (s110 minor 5).
- **`po-orchestrator.md:83-90`** is the log section: kinds `:84`, file and template `:86`, timing and landing `:88`, the empty case `:90`. `:92` is the finish.
- **The model to align with** is `po-drive.md:153-155`: its kinds list and the "Not now" sentence.
- **`po-ship.md` checks the root in local mode only:** `:81` requires no staged or modified tracked file. Pr mode (`:73-77`) never inspects the root, so log rows written at "Pull request ready" do not block a pr ship.

## Attachment points
- **`po-setup.md` `**Base.**`, pr bullet `:66`:**
  - the realignment goes right after `git fetch origin`;
  - "That ref missing → stop" moves before it, since the realignment needs that ref;
  - `:71` keeps only the branch deletion and the base choice.
- **`po-setup.md:85`:** the sentence after the quoted message. The quoted message itself stays.
- **`po-orchestrator.md:84` and `:88`:** extend the kinds and the timing, and add the "Not now" sentence.
- **New test file:** `tests/framing-realign-and-orchestrator-log.test.sh`, with the helpers already copied in `tests/framing-second-landing.test.sh:6-15` (`section_of`, `holds`, `base_block`, `offset`).

## Verified interfaces
- `tests/run.sh <file>` runs one test file (AGENTS.local.md, `## Commands`).
- `tests/lib.sh` provides `require_file`, `contains`, `fail`. Each test file defines its own `section_of` and `holds`, as `framing-second-landing.test.sh:6-8` and `drive-guards.test.sh:7-12` do.
- **`base_block` (`framing-second-landing.test.sh:10-13`)** cuts from `**Base.**` to `**The commit, built beside the checkout**`.

## Traps
- **`tests/framing-through-pr.test.sh` (not owned, must stay green):**
  - `:39-40`: every `git push` line holds `framing/<slug>`;
  - `:41-42`: no line matches `commit[^.]* on (\`Target branch\`|the target branch)`, case-insensitive. Avoid a sentence such as "commits … on `Target branch`";
  - `:50-56` keeps `git merge --ff-only origin/<Target branch>`, `git merge --ff-only framing/<slug>` and the quoted `"Framing pull request ready: <url>. Land it with Rebase and merge;`.
- **`tests/framing-second-landing.test.sh`:**
  - `:32-33` and `:38-41` keep the `Not merged →` and `Merged →` bullets, in that order, and the exact phrases `` `<base>` is `origin/framing/<slug>`, whether a pull request is open or not `` and `A merged branch is never taken as a base`. The capitalised `Merged →` must stay after `Not merged →`: `offset` is case-sensitive.
  - `:48` needs `A refusal is reported` and `git push origin --delete framing/<slug>` inside `base_block`.
  - `:56` pins the old sentence and must change with it.
- **`tests/drive-guards.test.sh:61-63`** needs the orchestrator log to hold `Plan validation: autonomous`, `each fix run it started`, `` `/po-flow` ``, `templates/decisions-log.md`, `Landing the framing`, `` slug `decisions-log` `` and `never before its ship`. `:67-71` keeps the section after Stage 8.
- **`tests/pilot.test.sh:11`** counts exactly two `## Stage … — checkpoint` headings. Add no heading to the orchestrator.
- **`tests/escalation-contract.test.sh:96-101`** reads the log section of `po-drive.md`, which stays untouched.
- **`tests/overlap.test.sh`:** no 8 consecutive words shared with Killer SaaS. Write the new wording fresh.
- **Root index and the fast-forward:** a root holding staged copies of framing paths (`:79`) fast-forwards when the staged content matches the incoming one. Otherwise git refuses, which is the "reported, nothing forced" path.
- **Installed copies:** `.claude/` and `.polype/` keep the old wording until a reinstall. The story must not edit them.
- **No migration, no dependency, no ADR:** ADR-0080 and ADR-0081 already govern this landing, and the change is method prose only.

## Open questions
- Should the `Merged →` bullet keep its own `--ff-only` once the realignment runs right after the fetch? Running it twice is harmless but redundant. The plan decides: keep a single realignment.
- Left out of scope: the automatic path `:88`, which realigns after its own merge and must stay, since the merge happens after Base. Also s110 minors 2, 3, 4 and 6, which the story does not name; the `**Base.**` reorder fixes minor 5 as a side effect.

## Complexity
Story: 2 → after reading: 2. Two prose edits in two method files, one new test file of two tests, and two one-line test adjustments.

## Split
Not needed.
