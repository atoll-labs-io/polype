---
track: flow
validated: yes
---
# Plan (short track) — s30-grouped-validation

## Verified facts

- `method/commands/po-drive.md:73` already says, in one clause of the dispatch list: "under `human`, group the wave's plans into one AskUserQuestion before any implementer starts". It names the grouping but settles none of what the story asks: no answer set, no rule on which plans get `validated: yes`, nothing under `autonomous`.
- `method/commands/po-drive.md:14` already declares `Plan validation` in its `Reads settings:` line, and `method/commands/po-drive.md:10` already declares `AskUserQuestion`. No frontmatter change is needed.
- **Trap.** `tests/drive.test.sh:45-47` reads every `subagent_type: <x>` occurring inside the `## A wave` section and requires the sequence to be exactly `planner implementer reviewer `. Any new `subagent_type:` mention inside that section breaks a green test of a shipped story. `section_of` (`tests/drive.test.sh:8`) ends a section at the next `^## `, so the new prose must live in its own `##` section, after `## A wave`.
- **Trap.** `tests/resume.test.sh:39` requires `grep -n '^## \(Resuming\|A wave\)$'` to yield exactly `## Resuming` then `## A wave`. A new section may not be named either of those and must not sit between them.
- `tests/drive.test.sh:31-51` and `tests/resume.test.sh` quote many exact phrases of `## A wave`, `## Report`, `## The verdict, and the fix runs` and `## Ships, one at a time`. Those phrases are kept verbatim; the change is additive.
- The approval wording the project already uses, twice: `method/commands/po-plan.md:47` and `method/commands/po-flow.md:65` — "AskUserQuestion \"Approve the plan for <id>?\" … Approve / Change / Stop", "Write `validated: yes` into the frontmatter on Approve and on nothing else". The grouped question is the wave-level form of that same rule.
- `method/commands/po-plan.md:48` fixes the `autonomous` wording: "check the plan against each acceptance criterion yourself, write `validated: yes`, and state that no human reviewed it". The story asks the driver to carry that statement into its wave report.
- `po-drive` has no Write or Edit (`method/commands/po-drive.md:18`, asserted by `tests/drive.test.sh:53-59`); it writes `validated: yes` through Bash, as it already records verdicts through Bash (`method/commands/po-drive.md:80`).
- ADR-0014 (`docs/decisions/ADR-0014-checkpoints-groupes.md`) is `status: accepted` and holds two decisions: grouped plan validation per wave, and a human ship at milestone level. ADR-0015 (`docs/decisions/ADR-0015-…:Consequences`) already killed the second one — "le ship « au niveau du milestone » tombe avec cette décision et sera revu quand la flotte (M3) sera construite" — without superseding ADR-0014. That is the "volet restant" the story names.
- The repository's supersession convention is visible on ADR-0013 (`docs/decisions/ADR-0013-…:4,9`): the superseded ADR's frontmatter becomes `status: superseded` with `superseded-by: [ADR-0015]`, its body untouched. ADR file names are `ADR-NNNN-<slug>.md`, not the `NNNN-<slug>.md` of `method/AGENTS.md`; the story's `Owns` follows the real convention.
- `bin/po-lint` rules that could bite: `settings` (every setting in the `Reads settings:` line must exist in `method/templates/agents-local.md` — unchanged here), `tools` (a body mentioning AskUserQuestion must declare it — already declared), `fail-closed` (only applies inside `## Checks`, `## Preconditions`, `## Step 0`, none of which this story touches).
- `tests/overlap.test.sh` fails on any line of `method/` sharing 8+ consecutive words with Killer SaaS (ADR-0006): the new prose is written from the facts above, from no external source.

### Ownership note, decided here

The story's `Owns` is `method/commands/po-drive.md`, `docs/decisions/ADR-0017-validation-groupee.md`, `tests/grouped-validation.test.sh`.

- **ADR-0014's frontmatter is edited anyway** (two lines: `status`, `superseded-by`), outside `Owns`. Leaving it `accepted` while ADR-0017 supersedes it puts two live, contradicting ADRs in front of every command that reads "the accepted ADRs" — worse than the `major` scope finding this may draw. The body is not touched, per `method/AGENTS.md`.
- **`docs/parite-killer-saas.md` is not touched**, although the story's `Matrice` line names ADR-0014's remaining scope. That file is in s31-fleet-wiring's `Owns`, and s31 updates the matrix as its own criterion. Line T4 will then point at a superseded ADR until s31 runs; that is s31's line to fix, not this story's file to take.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — the story text names no data or schema change | absent — the diff is markdown under `method/`, `docs/decisions/` and `tests/` |
| New screen | absent — no interface in the story text | absent — this repository has no UI |
| Authorization or tenant scope | absent — no actor or permission in the story text | absent — nothing in `po-drive.md` grants access |
| API contract | absent — no interface between programs in the story | absent — `po-drive.md` is prose read by an agent; the subagent contracts it names are unchanged |
| New dependency | absent — the story adds no tool | absent — the new test uses `tests/lib.sh` only |

## Story

**En tant que** développeur **je veux** approuver les plans d'une vague en une seule question **afin de** garder un regard humain sans sérialiser la flotte.

- `drive_groups_plan_approval_per_wave` — with `Plan validation: human`, the driver puts the wave's plans into a single `AskUserQuestion`: approve all, choose, or stop; only the approved plans reach `validated: yes`.
- `drive_says_when_nobody_reviewed` — with `autonomous`, the driver says so explicitly in its wave report.
- `adr_0017_records_the_remaining_scope_of_adr_0014` — an accepted ADR records that grouped validation stays, that shipping is per story (ADR-0015), and that ADR-0014 is superseded.

## Tasks

1. [x] Write `docs/decisions/ADR-0017-validation-groupee.md` from `templates/adr.md`, in French like every ADR of this repository: `status: accepted`, `date: 2026-09-21`, `supersedes: [ADR-0014]`, `superseded-by: []`. Context: ADR-0014 held two decisions and ADR-0015 already dropped the milestone ship without superseding it. Options considered: keep ADR-0014 as is (two live ADRs contradicting each other), re-decide grouped validation from scratch, or supersede ADR-0014 with a decision that keeps only the part still standing. Outcome: the third — grouped plan validation per wave stays, the ship is per story under `Merge mode` and `Ship confirmation` (ADR-0015), and ADR-0014 is superseded. Fails `adr_0017_records_the_remaining_scope_of_adr_0014`.
2. [x] In `docs/decisions/ADR-0014-checkpoints-groupes.md`, frontmatter only: `status: superseded`, `superseded-by: [ADR-0017]`. Body untouched, as on ADR-0013. Fails `adr_0017_records_the_remaining_scope_of_adr_0014`.
3. [x] In `method/commands/po-drive.md`, add a section `## Validating a wave's plans` **after** `## A wave` and **before** `## The verdict, and the fix runs`, containing no `subagent_type:` string (trap above). It settles: one AskUserQuestion for the whole wave, never one per story; the three answers — approve every plan, choose which ones, or stop the wave; what the question shows per plan (story id, its tasks and its test strategy, the path `docs/plans/<id>.md` so a plan can be read whole); that `validated: yes` is written, through Bash, only into the frontmatter of the plans the answer approved; that a plan left unapproved keeps `validated: no`, its lane waits for the next wave, and no implementer is dispatched for it, the gate being the same `po-gate plan-validated <id>` as everywhere; and that `Stop` dispatches no implementer at all, the plans staying on disk for the next run. Fails `drive_groups_plan_approval_per_wave`.
4. [x] In the same file, step 1 of `## Dispatching` keeps its `subagent_type: planner` line and points at the new section instead of settling the approval inline — the phrases `tests/drive.test.sh` quotes stay untouched. Fails `drive_groups_plan_approval_per_wave`.
5. [x] In `## Report` of `method/commands/po-drive.md`, add that under `Plan validation: autonomous` the wave report states that the plans were approved without a human reading them, naming the stories concerned; and that under `human` it states which plans the wave approved and which are still waiting. Keep every phrase `tests/resume.test.sh:44-60` quotes. Fails `drive_says_when_nobody_reviewed`.
6. [x] Write `tests/grouped-validation.test.sh` with the three test functions above, in the style of `tests/drive.test.sh` (`section_of`, `holds`, `require_file`, short exact quotes). Test 3 reads both ADR files: ADR-0017's frontmatter (`status: accepted`, `supersedes: [ADR-0014]`) and body (grouped validation kept, per-story ship citing ADR-0015), and ADR-0014's frontmatter (`status: superseded`, `superseded-by: [ADR-0017]`).

## Run interdicts

- `docs/parite-killer-saas.md`: empty diff — s31 owns it.
- `docs/stories.md`, `method/AGENTS.md`, `method/commands/po-help.md`, `method/commands/po-status.md`: empty diff — s31 owns them.
- `.claude/` and `.polype/` (installed copies): empty diff. Change `method/`; do not run `bin/polype-dev-install`.
- No existing test file is edited. `tests/drive.test.sh` and `tests/resume.test.sh` must end with an empty diff: this story changes no clause they check.
- ADR-0014's body below its frontmatter: empty diff.
- `method/templates/agents-local.md`: empty diff — no new setting; `Plan validation` already exists.
- No `git worktree`, `switch`, `checkout` or `stash` outside this worktree.

## Files touched

- `method/commands/po-drive.md` (modified)
- `docs/decisions/ADR-0017-validation-groupee.md` (new)
- `docs/decisions/ADR-0014-checkpoints-groupes.md` (frontmatter, 2 lines)
- `tests/grouped-validation.test.sh` (new)
- `docs/plans/s30-grouped-validation.md`, `docs/verif/s30-grouped-validation.md` (pipeline evidence)

## Test strategy

Three tests, one per acceptance criterion, in `tests/grouped-validation.test.sh` — well inside `Test budget: 25`. The layer is the only one this repository has: a method file is prose, and the rule it must hold is checked by quoting the short exact phrase that carries it, the way every `tests/*.test.sh` here does. Each test bites because deleting the clause it names from `po-drive.md` or the ADRs makes it fail.

No test is added for the trap itself: `tests/drive.test.sh:45-47` already fails if a `subagent_type:` leaks into `## A wave`, which is exactly the guard needed.

Run at the end of the code stage, per `Full suite: execute-end`: `bash tests/run.sh` (whole suite, so `overlap.test.sh`, `lint.test.sh`, `drive.test.sh` and `resume.test.sh` all speak), plus `bin/po-lint` on `method/`.

## Done when

One commit on `story/s30-grouped-validation` holding the four files and the pipeline evidence; the full suite green including the three new tests and the untouched `drive.test.sh` / `resume.test.sh`; `bin/po-lint` silent; a review with no open critical finding; then one squash commit `s30-grouped-validation: Valider les plans d'une vague en une fois` on `m3-flotte`.
