---
track: flow
validated: yes
---
# Plan (short track) — s75-post-m7-texts

Written by the planner on the short track (`Story track: auto`, complexity 2 ≤ `Flow threshold` 2). This one file stands in for both the research and the plan: there is no `docs/research/s75-post-m7-texts.md`. Validated autonomously (`Plan validation: autonomous`): no human reviewed it.

## Verified facts
No assumption of the story proved false. One link the story leaves out is noted at the end of this section.

- `docs/installation.md:80` — section `### Le hook des bornes de l'implementer` describes only the implementer mode (`:83` calls `po-bounds.sh implementer`). The word `reviewer` appears nowhere in the file. Next `## ` heading is `:111` (`## Suivre ~/.claude/polype/ avec chezmoi`).
- `docs/installation.md:92` — "Ce qu'il ne voit pas (ADR-0039)" ; the only `ADR-0039` in the file. ADR-0039 is `status: superseded`, `superseded-by: [ADR-0050]` (`ADR-0039…:5,8`). ADR-0050 replaces it whole and restates the gaps: a quoted-delimiter heredoc body is not read **unless a shell reads it** (`ADR-0050…:30`); `GIT_DIR=…`, `--git-dir`, `git fetch . HEAD:main` stay unread in `implementer` and `qa` modes, while `reviewer` refuses `GIT_DIR=` (`ADR-0050…:42`). The sentence at `installation.md:92-93` says nothing about the shell exception.
- `docs/installation.md:99-102` — the upgrade paragraph covers only the implementer ("le hook fermé refuse toute écriture de l'implementer", pinned by `tests/bounds.test.sh:226`).
- Reviewer mode facts: `method/agents/reviewer.md:16` wires `po-bounds.sh reviewer || exit 2` on `Edit|Write|Bash`; `method/hooks/po-bounds.sh:682-683` denies any other mode with "unknown mode". ADR-0047 (`ADR-0047…:27-41`) defines two zones: the story worktree (Write/Edit allowed except under `.git`, git limited to QA read verbs plus `git checkout -- <path>` and `git restore`), and `${TMPDIR:-/tmp}` throwaway repos (any git verb but `push`/`send-pack`); everywhere `push`, `send-pack`, `--git-dir`, `--work-tree`, `GIT_DIR=`, `GIT_WORK_TREE=` refused, and a git command outside both zones (the main checkout included) refused. Its neutral consequence (`ADR-0047…:49`) is the pre-s70 failure this story documents.
- `tests/installer.test.sh:184-190` — `test_installation_doc_lists_the_hook_refusals` cuts the section from `### Le hook des bornes de l'implementer` to the next `^## ` (a `### ` heading does not end it) and requires the phrase `'ADR-0039'` at `:186`. It must change to `'ADR-0050'` (s71 review m2).
- `method/AGENTS.md:123` — "`.polype/hooks/po-bounds.sh`, called `po-bounds`, keeps the `implementer` and `qa` subagents inside their story's bounds: a PreToolUse hook wired from those subagents' frontmatter, …". Pinned verbatim by `tests/structure.test.sh:82`. Only mention of `po-bounds` in that file.
- `method/skills/agentic-stories/SKILL.md:21` — "two stories with no dependency between them never share a path; if they must, one depends on the other." The rule it should cite is check 8 of `method/skills/stories-review/SKILL.md:25-27`; the citing form used elsewhere is "by the overlap rule of check 8 of the `stories-review` skill" (`method/AGENTS.md:51`, `method/commands/po-stories.md:42`, `method/templates/stories.md:12`). `tests/stories.test.sh:30-37,74-81` pin other sentences of that section, not this one.
- `method/templates/adr.md:4,7,8` — `status: accepted  # proposed | accepted | superseded`, `supersedes: []`, `superseded-by: []`; nothing on partial replacement. `tests/pilot.test.sh:49-53` only needs `## Considered Options` and `superseded-by`.
- `method/commands/po-architect.md:48` — "a changed decision is a new ADR whose `supersedes` names the old one, and the old one gets `superseded-by` and `status: superseded`." Only the full case. `tests/architect.test.sh:39` pins `:41`, not `:48`.
- Successor links, each verified in the successor's body before writing:
  - ADR-0038 → ADR-0024: "Ce point d'ADR-0024 est remplacé ici" (`ADR-0038…:14`).
  - ADR-0039 → ADR-0024: "Ce point d'ADR-0024 est remplacé ici (remplacement partiel…)" (`ADR-0039…:14`).
  - ADR-0037 → ADR-0029: "seule sa conséquence neutre change" (`ADR-0037…:14`).
  - ADR-0041 → ADR-0037: "remplace … la conséquence « Bad » d'ADR-0037" (`ADR-0041…:35`).
  - Predecessors already point forward: ADR-0024:9 `[ADR-0038, ADR-0039]`, ADR-0029:9 `[ADR-0037]`, ADR-0037:8 `[ADR-0041, ADR-0044]`, all `status: accepted` (pinned by `tests/leftovers.test.sh:10-18`).
  - The four successors carry `supersedes: []` at line 7 (`ADR-0037:7`, `ADR-0038:7`, `ADR-0039:7`, `ADR-0041:7`).
- **Left out by the story**: `ADR-0041…:35` also says it "remplace ses conséquences neutres" of **ADR-0034**, whose `superseded-by` is `[]`. ADR-0034 is outside `Owns`; see Open question.
- Lane neighbours: s74 (in flight) owns `method/hooks/po-bounds.sh`, `method/agents/reviewer.md`, `tests/bounds.test.sh` — no overlap with this `Owns`, but s74 tightens reviewer mode (chained `-C`, `core.worktree`, temp-zone destinations), so the installation text must stay at ADR-0047's level and not enumerate rules s74 is changing.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text `docs/stories.md:1144-1159` | absent — only markdown and bash tests touched |
| New screen | absent — story text | absent — no UI in this repository |
| Authorization or tenant scope | absent — story text | absent — docs describe `po-bounds`; the hook itself (`method/hooks/po-bounds.sh`) is not touched |
| API contract | absent — story text | absent — no command, setting or template field added; `templates/adr.md` keeps its fields, only comments change |
| New dependency | absent — story text | absent — tests use `tests/lib.sh` helpers only |

## Story
Bring the docs, the rules and the ADRs to the method as M7 bis left it. Criteria (each is a test function name):
- `installation_describes_the_reviewer_mode` — `docs/installation.md` describes `po-bounds` reviewer mode, says a project whose `.polype/hooks/po-bounds.sh` predates s70 blocks every review until `polype init`, and refers to ADR-0050 instead of ADR-0039.
- `rules_name_every_bounded_agent` — "Installed files" of `method/AGENTS.md` says `po-bounds` holds the implementer, qa and the reviewer.
- `agentic_stories_cites_the_overlap_rule` — `agentic-stories` cites check 8's overlap rule instead of only "share a path".
- `partial_supersession_is_written_and_linked` — the ADR template and `/po-architect` describe partial replacement (old ADR stays `accepted` and names its successor; the successor names it in `supersedes`); ADR-0037, 0038, 0039, 0041 name in `supersedes` the ADR they partly replace, bodies untouched.

## Tasks

1. [x] **Installation doc.** In `docs/installation.md`: at `:92` replace `(ADR-0039)` by `(ADR-0050)` and fix the heredoc clause so it matches ADR-0050:30 (a quoted-delimiter body is not read unless a shell reads it); the `GIT_DIR`/`--git-dir`/`fetch .` gaps are said to hold for `implementer` and `qa`. Then add, after `:109` and before `## Suivre…` at `:111`, a subsection `### Le mode reviewer` (French, own words) stating: the reviewer's frontmatter calls `.polype/hooks/po-bounds.sh reviewer`; the two zones of ADR-0047 (story worktree: writes outside `.git`, git read verbs plus `git checkout -- <chemin>` and `git restore`; throwaway repos under `${TMPDIR:-/tmp}`: any verb but `push`); everywhere `push` refused and a git command outside both zones refused, the main checkout included; a project whose `.polype/hooks/po-bounds.sh` dates from before s70 refuses every reviewer call (mode inconnu) and so blocks every review until `polype init <projet>` refreshes it and the script is committed on the target branch; cite `ADR-0047`. In `tests/installer.test.sh:186` replace `'ADR-0039'` by `'ADR-0050'` (changed because this story changes that clause). — Fails if wrong: `test_installation_describes_the_reviewer_mode` (task 6), `test_installation_doc_lists_the_hook_refusals`.
2. [x] **Rules.** In `method/AGENTS.md:123` only, rewrite the `po-bounds` clause to: "`.polype/hooks/po-bounds.sh`, called `po-bounds`, keeps the `implementer`, `qa` and `reviewer` subagents inside their bounds: a PreToolUse hook wired from those subagents' frontmatter, it decides which paths they may write and which git commands they may run." Update `tests/structure.test.sh:82` to that new phrase (changed because the clause changes). — Fails if wrong: `test_rules_name_every_bounded_agent`, the existing structure test.
3. [x] **Agentic stories.** In `method/skills/agentic-stories/SKILL.md:21` replace "never share a path" with a sentence saying two stories with no dependency between them never hold `Owns` entries that overlap, "by the overlap rule of check 8 of the `stories-review` skill", and keep "if they must, one depends on the other". — Fails if wrong: `test_agentic_stories_cites_the_overlap_rule`.
4. [x] **Partial supersession, method side.** `method/templates/adr.md`: extend the comments of the frontmatter so `status` says an ADR replaced only in part stays `accepted`, and `supersedes` / `superseded-by` say they list ADRs replaced or replacing "wholly or in part" (keep both field names and `[]` values). `method/commands/po-architect.md:48`: keep the full case, add the partial one — the old ADR keeps `status: accepted` and names its successor in `superseded-by`, the successor names it in `supersedes`; only these frontmatter links of an accepted ADR ever change. Use the exact phrase `replaced only in part` in both files. — Fails if wrong: `test_partial_supersession_is_written_and_linked`.
5. [x] **Partial supersession, ADR side.** Change only line 7 of four ADRs: ADR-0037 `supersedes: [ADR-0029]`, ADR-0038 `supersedes: [ADR-0024]`, ADR-0039 `supersedes: [ADR-0024]`, ADR-0041 `supersedes: [ADR-0037]`. No other byte of these files changes; ADR-0039 keeps `status: superseded` and `superseded-by: [ADR-0050]` (`tests/bounds.test.sh:502-503`). — Fails if wrong: `test_partial_supersession_is_written_and_linked`.
6. [x] **Tests.** Create `tests/post-m7-texts.test.sh` (header comment `# s75 — …`) with the four functions below, run it alone (`bash tests/run.sh post-m7-texts.test.sh installer.test.sh structure.test.sh`), then the full suite once via `po-run --story s75-post-m7-texts --label test -- 'bash tests/run.sh'`.

## Run interdicts
- Empty diff for `AGENTS.md` (root), `.claude/`, `.polype/`: installed copies, refreshed in a separate commit after ship.
- In `method/AGENTS.md`, only line 123 changes; Law 6's ADR sentence stays as is.
- In the four ADRs, `git diff main -- docs/decisions/` shows exactly four changed lines, each a `supersedes:` line; no body line, no `status:` line changes. ADR-0034, ADR-0024, ADR-0029, ADR-0044, ADR-0047, ADR-0050 untouched.
- No change to `method/hooks/po-bounds.sh`, `method/agents/reviewer.md`, `tests/bounds.test.sh` (s74's lane). The installation text does not describe s74's new refusals (chained `-C`, `core.worktree`, temp-zone destination paths).
- No ADR written: nothing structural is decided here (reserved ADR-0052 stays unused).
- No sentence of 8+ consecutive words from Killer SaaS (`tests/overlap.test.sh`); `docs/parite-killer-saas.md` untouched.

## Files touched
`docs/installation.md`, `method/AGENTS.md`, `method/skills/agentic-stories/SKILL.md`, `method/templates/adr.md`, `method/commands/po-architect.md`, `docs/decisions/ADR-0037-…`, `ADR-0038-…`, `ADR-0039-…`, `ADR-0041-…`, `tests/installer.test.sh`, `tests/structure.test.sh`, `tests/post-m7-texts.test.sh` (new), plus this plan. All inside `Owns`.

## Test strategy
Four new tests (one per criterion) plus two existing pins updated, within `Test budget` 25. Bash text checks, the only layer here.
- `test_installation_describes_the_reviewer_mode` — cut `### Le mode reviewer` up to the next `^##` heading; require `po-bounds.sh reviewer`, `avant s70` (or the exact phrase chosen, quoted from the file), `polype init <projet>`, `ADR-0047`; require `ADR-0050` in the bounds section; `! grep -qF 'ADR-0039' docs/installation.md`. Deleting the subsection or restoring the old reference fails it.
- `test_rules_name_every_bounded_agent` — `section_of`-style cut of `## Installed files` in `$METHOD/AGENTS.md` contains ``keeps the `implementer`, `qa` and `reviewer` subagents``; the old `` `implementer` and `qa` subagents`` is absent.
- `test_agentic_stories_cites_the_overlap_rule` — the `## Owns and contracts first` section contains ``by the overlap rule of check 8 of the `stories-review` skill`` and no longer contains `never share a path`.
- `test_partial_supersession_is_written_and_linked` — `replaced only in part` in `$METHOD/templates/adr.md` and `$METHOD/commands/po-architect.md`; for each pair (0037→0029, 0038→0024, 0039→0024, 0041→0037) the successor's `frontmatter` has the exact `supersedes:` line **and** the predecessor's `superseded-by:` line names the successor (bidirectional, so a one-sided link fails); ADR-0037, 0038, 0041 keep `status: accepted`.
Body integrity of the ADRs is left to the reviewer through the interdict (`git diff`), not a test: no stable reference to compare against.

## The pivot
Where the partial-replacement rule lives in the ADR template. The template has no prose slot for authoring rules, so this plan puts it in frontmatter comments, extending the existing comment on `status:`. That could be wrong: an author who copies the template may keep the comment on a filled `supersedes:` line. Then an exact-line check like `tests/leftovers.test.sh:15` or `tests/grouped-validation.test.sh:56` would not match a future ADR. The mitigation is that `/po-architect:48` carries the full rule in prose. The reviewer should check that the template's field lines still read `supersedes: []` and `superseded-by: []` before any comment.

## Open question
ADR-0041's body (`:35`) also replaces neutral consequences of **ADR-0034**. The story names only ADR-0037. ADR-0034 is outside `Owns`, so its `superseded-by` cannot change. This plan writes `supersedes: [ADR-0037]` only, as the story says, so every link stays two-way. Linking ADR-0041 ↔ ADR-0034 is left to a later story.

## Done when
Every task is ticked. The four new tests and the two updated ones pass. The full suite is green through `po-run` and recorded in `docs/verif/s75-post-m7-texts.md`. There is one commit on `story/s75-post-m7-texts` carrying this plan. The review has no open critical finding, and the squash lands on `main`.
