# Research — s15-stories-review

## Structuring facts
- `po-help` must list every command: `tests/pilot.test.sh:38-46` fails when `method/commands/po-stories-review.md` exists without `/po-stories-review` in `method/commands/po-help.md`. Outside Owns; s12–s14 each added one line there (`method/commands/po-help.md:13-15`). s15 needs the same one-line exception, on top of the `po-research.md` sentence the story already allows.
- Killer SaaS has files with the very same names (`stories-reviewer.md`, `ks-stories-review.md`, `skills/stories-review`, `templates/stories-review-checklist.md`) and its sources are present locally, so `tests/overlap.test.sh` runs for real: every new file must be written from the French description of C06 (`docs/parite-killer-saas.md:41`), never from those sources.
- The scope sources are fixed contracts: PRD sections `## Core loop`, `## Graveyard`, `## Angle`, frontmatter `mode:` / `status:` (`method/templates/prd.md:3-34`); brief sections `## Wedge & non-goals`, `## Premises` (`method/templates/brief.md:21,30`). `/po-stories` picks the source from `Entry mode` (`method/commands/po-stories.md:19-23`); the review must use the same mapping.
- The subagent has no Write, so the command writes the report and commits it on `Target branch` — it needs Agent, Write and Bash, like `/po-review` (Agent, Write) plus the commit of `/po-stories` (`po-stories.md:48-49`).
- `docs/reviews/stories.md` lives next to per-story reviews; `po-gate ship-allowed` reads only `docs/reviews/<id>.md` (`method/hooks/po-gate.sh:26`) and `stories` is not an `s<n>-` id, so no collision.

## Story
A subagent that did not write the stories confronts them with the scope, so that a gap costs a markdown edit rather than lost cycles. Criteria:
- `stories_reviewer_is_read_only_without_shell` — the subagent has no Write, Edit or Bash, and preloads `stories-review`.
- `stories_review_checks_coverage_first` — scope coverage (PRD core loop, or brief wedge and requirements) is checked first, table in hand; an uncovered item is critical.
- `stories_review_checks_owns_overlap` — two stories with no dependency between them that share an `Owns` path are flagged.
- `stories_review_template_ends_with_stories_ready` — the template ends with `Max severity:` then `Stories ready: yes|no`.
- `stories_review_is_a_soft_gate` — the command writes `docs/reviews/stories.md` on `Target branch`; `/po-research` warns when that verdict is missing or `no`, without blocking.

## Current code
- `method/agents/`: `implementer.md` (tools Read, Write, Edit, Bash, Grep, Glob; `skills: [testing-doctrine]`) and `reviewer.md` (tools Read, Grep, Glob, Bash, Edit; `skills: [review-antihallu, testing-doctrine]`; body starts with a `Reads settings:` line; answer ends with two verdict lines) (`method/agents/reviewer.md:1-47`). No stories reviewer.
- `method/commands/po-review.md`: delegation model — Agent tool, `subagent_type: reviewer`, quoted prompt, then "Recording": writes the answer whole; a failed/incomplete answer is recorded as blocked with a critical severity (`po-review.md:27-37`).
- `method/commands/po-stories.md`: "Before writing" checklist (vertical slice, 5 split, 4 names risk, dependency order, traced to core loop/angle or wedge/premise, graveyard, Owns shared ⇒ dependency, contracts first) (`po-stories.md:36-45`). The review re-checks the same rules from outside.
- `method/skills/agentic-stories/SKILL.md`: the rules the stories were written with (sections Vertical slices, Owns and contracts first, Complexity and splitting, Dependency order, Scope: core loop and graveyard, Criteria and notes). The review skill judges against them; it should reference them rather than restate them.
- `method/commands/po-research.md:19-21`: "Checks first" — setup present, id matched. No mention of a stories review. The warning belongs here.
- `method/templates/review.md`: per-story review format ending `Max severity:` / `Ship allowed:`. The stories template mirrors the shape with `Stories ready:` instead.
- Parity C06 (`docs/parite-killer-saas.md:41`): fresh context, read-only, no shell; coverage table first (a gap = critical); graveyard leak, disguised technical layers, untestable criteria, dependency order, complexity, ids, overlaps; own severity scale; soft gate reported by status and research. Polype adds Owns overlap between parallelisable stories. Status: `à faire`. A02 (`:13`) also names `stories-reviewer`; not in this story's matrix line, left alone.

## Attachment points
- New: `method/commands/po-stories-review.md`, `method/agents/stories-reviewer.md`, `method/skills/stories-review/SKILL.md`, `method/templates/stories-review.md`, `tests/stories-review.test.sh`.
- One sentence in `method/commands/po-research.md` "Checks first" (allowed by the story's notes).
- One line in `method/commands/po-help.md` « Mise en place », after `/po-stories` (forced by `pilot.test.sh:38`).
- Matrix: status cell of C06 (`docs/parite-killer-saas.md:41`).
- Installer copies `method/agents/*` and `method/skills/*` recursively (`bin/polype-dev-install:44-48`): nothing to register.

## Verified interfaces
- `tests/lib.sh`: `contains FILE PHRASE` (fixed, case-sensitive), `require_file`, `needs_tool`/`lacks_tool` (read `allowed-tools:` list or `tools: A, B`), `frontmatter`, `settings_read_by`, `fail`.
- `tests/stories.test.sh:8`: local `section_of FILE HEADING` awk idiom — copy it if a clause must be pinned to one section.
- `tests/structure.test.sh:24-34`: every command and agent needs a `Reads settings:` line naming only template settings (`Entry mode`, `Target branch` exist, `method/templates/agents-local.md:23-24`). `Reads settings: none` is accepted (settings_read_by yields nothing; `po-help.md:7`).
- Agent frontmatter: `name`, `description`, `tools`, `model`, `skills:` YAML list (`reviewer.md:1-9`). `needs_tool`/`lacks_tool` work on `tools:` inline.
- `tests/run.sh`: focused run `bash tests/run.sh stories-review.test.sh`. Baseline on `story/s15-stories-review`: 96 passed, 0 failed.

## Traps
- `tests/overlap.test.sh` with same-named Killer SaaS files: fresh prose only.
- `tests/pilot.test.sh:38` — help line (see above).
- Method files in English; `po-help` in French.
- The soft gate must stay soft: `/po-research` warns and continues; wording must not say "stop" for this case.
- `/po-research` runs from the repository root before the worktree exists; `docs/reviews/stories.md` is read from `Target branch` (the root checkout), which is where the command commits it.
- The installed copies `.claude/` and `.polype/` are not edited (conventions).
- No migration, no code outside `method/`, `tests/`, `docs/`.

## Open questions
- Coverage "table in hand": the template should hold a table (scope item → stories covering it → covered yes/no). The plan fixes its columns.
- Severity scale for stories: critical (scope gap, graveyard leak, dependency on a later story, Owns overlap?) vs major/minor. Is an Owns overlap critical (parallel runs collide) or major? The plan decides; the criterion only requires it to be flagged.
- What does `Stories ready: no` mean exactly — any critical, mirroring `Ship allowed`? Probably yes.
- Blocked subagent: record `Max severity: critical` / `Stories ready: no`, as `/po-review` does.
- Re-run after fixes: overwrite `docs/reviews/stories.md` (git keeps history) — no fix-loop counter needed.

## Complexity
Story 3 → 3. Four new method files, one sentence, one help line; the effort is prose in our own words and tests that pin the rules.

## Split
Not needed.
