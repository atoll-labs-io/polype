# Research — s78-platform-setting

## Structuring facts
- **Nuance on `polype_declares_its_platform`**: in a story worktree `bin/polype check .` exits 1 whatever the settings, because `.claude/` is untracked and so absent from the worktree (it lists 34 `missing: .claude/...` lines). The criterion can only mean "no `missing setting:` line", which is how `tests/leftovers.test.sh:20-27` already checks it. That test turns red the moment the template gains `Platform` and `AGENTS.local.md` does not.
- `bin/po-lint` already requires every `## ` heading of the profile template (`bin/po-lint:222,229-231`). So adding `## Platform` to `method/templates/profile.md` is enough for the lint to demand the section. What the lint cannot see today is the platform *value*, and that value is what `/po-setup` will filter on.
- `/po-setup` step 2 is pinned at exactly five numbered questions (`tests/setup-modes.test.sh:33`, `tests/qa.test.sh:68`). Its catalogue phrases are pinned by `tests/catalogue-wiring.test.sh:10-16`, which s78 does not own. `Platform` must therefore be an unnumbered follow-up, asked **before** the catalogue offer that it filters (`po-setup.md:41`, "before question 5").
- `stories-review` cites its checks by number from outside: "check 8" appears in `agentic-stories:21`, the stories template, `/po-stories`, `/po-status` and `tests/owns-overlap.test.sh:40`. A Surface check must become **check 9**, appended after check 8, with nothing renumbered.
- Nothing in `method/` mentions `Platform` or a story `Surface` today. The only hit, `design-system.md:18`, is a table column with another meaning. ADR-0054 settles the values but not three details, which ADR-0055 settles: how the list is written, which surfaces each platform admits, and how a profile writes its platform.

## Story
The project declares its platforms (`Platform`). Each boilerplate profile declares its own (`## Platform`, required by `po-lint`, `web` for next-forge). Each story declares its `Surface`. Criteria:
- `platform_is_a_setting`: a `Platform` row with the seven values; `QA stage` accepts `screens`, `surfaces` or `—`; `Dev` is described as what serves what a person looks at, `—` when there is nothing to serve.
- `profiles_declare_their_platform`
- `setup_asks_the_platform`: an unnumbered follow-up; only the profiles of the declared platforms are offered; `QA stage` is asked even with `Dev` at `—` when a screenless platform is declared.
- `stories_declare_a_surface`: the template, `agentic-stories`, `/po-stories` and `stories-review` (minor when missing, major when it does not fit).
- `polype_declares_its_platform`: `Platform: cli`.

## Current code
- `method/templates/agents-local.md`:
  - Pipeline block `:9-37`, values table `:39-67`, Commands block `:71-79` (`Dev` at `:78`).
  - The `QA stage` row (`:52`) knows only `screens` and `—`.
  - `:81`: "`Dev` starts the development server and prints the address it serves; `/po-qa` needs it and stops on `—`." s79 rewrites the stop clause: s79 owns this file too and depends on s78.
- `method/commands/po-setup.md`:
  - Step 2 has five numbered questions (`:31-35`).
  - Two follow-ups as plain paragraphs: design (`:37`) and QA stage (`:39`). The QA stage one skips when `Dev` is `—`.
  - Catalogue offer at `:41`: every `boilerplates/*/profile.md`, no filter.
  - `:43` "Nothing else is asked beyond these five questions, that design follow-up, the `QA stage` follow-up and the catalogue offer".
- `method/templates/profile.md`:
  - The preamble (`:3`) states what `po-lint` checks.
  - Sections: Identity `:5`, Commands `:12-22`, Code map, Ownership, Where each rule lives, Capabilities `:36-53`, UI inventory `:55-57`, Known traps `:59-61`.
- `bin/po-lint`:
  - `check_profiles` (`:215-252`) takes the required headings, command names and capability names from the template (`:222-224`). "no list is repeated here" (`:186`).
  - The capability check iterates rows only (`:246-250`), so a profile with an empty `## Capabilities` table or a one-line `## UI inventory` passes. The note of the story is confirmed.
  - The settings template is read once into `TEMPLATE` (`:90-96`).
- `boilerplates/next-forge/profile.md:3-10`: Identity, then `## Commands` at `:12`. It has no platform.
- `method/templates/stories.md:10-12`: Complexity, Depends on, Owns. `po-bounds` finds Owns by the literal `**Owns**` (`method/hooks/po-bounds.sh:199`), so a line inserted before it is harmless.
- `method/skills/agentic-stories/SKILL.md`: sections Vertical slices, Owns and contracts first (`:20-25`), Complexity, Dependency order, Scope, Criteria and notes (`:46-50`).
- `method/commands/po-stories.md`:
  - `Reads settings: \`Entry mode\`, \`Target branch\`` (`:13`).
  - Checks `:17-24`, Sequence `:26-32` (step 5 lists the fields written), "Before writing" checklist `:34-43`.
- `method/skills/stories-review/SKILL.md`: checks 1-8 (`:11-35`) and severity (`:37-42`).
- `method/agents/stories-reviewer.md`:
  - `Reads settings: \`Entry mode\`, \`ADR directory\`` (`:12`).
  - Inputs (`:17`): stories, scope source, `AGENTS.md`, ADRs, "Nothing else is in scope".
  - No shell.
- `method/commands/po-stories-review.md`:
  - `:13` reads `Entry mode`, `Target branch`, `Model strong`.
  - Checks `:17-26`; check 6 stops on a missing `Model strong`.
  - The prompt (`:31`) passes `Entry mode: <value>`.
- `AGENTS.local.md` (worktree) already has `QA stage: —` (`:19`) and `Dev: —` (`:46`). It has no `Platform`.
- `bin/polype` `missing_settings` (`:195-211`) prints `missing setting: <name>: <template value>` for each name in a template block that is absent from the project. It runs in `check` (`:378`), `install` and `update`.

## Attachment points
- Setting: a new line in the Pipeline block plus a row in the values table of `agents-local.md`.
- The template value is what `missing_settings` prints to an upgrading project.
- Profile: a `## Platform` section in the template, between Identity and Commands. `po-lint` gets a value check inside `check_profiles`, next to the commands check.
- Setup: one paragraph after the five numbered questions. The catalogue sentence `:41` gains the filter, and `:39` and `:43` are reworded.
- Stories: a `Surface` line between `Depends on` and `Owns`, in the template and in Polype's own order (`docs/stories.md:1200`).
- The admission table lives once, in `agentic-stories`. `stories-review` check 9 and `/po-stories` cite it.
- `Platform` passes from `/po-stories-review` to the subagent through its prompt, the way `Entry mode` already does. The subagent has no shell and no other input.

## Verified interfaces
- `tests/lib.sh`:
  - Helpers: `contains`, `fail`, `require_file`, `template_settings`, `settings_read_by`, `frontmatter`, `needs_tool`/`lacks_tool`.
  - `ROOT` is the worktree root and `METHOD` is `$ROOT/method`.
  - `tests/run.sh` runs each test under `set -eu`.
- The lint mutation pattern: copy `method/` and a `boilerplates/demo/profile.md` into a temp dir, run `bash bin/po-lint <copy>/method`, expect exactly one `: [` breach (`tests/profile.test.sh:39-81`, `tests/lint.test.sh:10-40`).
- `test_lint_checks_profiles` (`tests/profile.test.sh:51-53`) copies the template itself as a profile and expects **zero** breaches. The template's own `## Platform` must therefore pass the new value check.
- `tests/profile.test.sh:19-20` lists the template headings. Add `## Platform` there: the clause changes.
- `tests/structure.test.sh:8-12`: each block line must match `^[A-Z][A-Za-z0-9 ]*:[[:space:]]+[^[:space:]#][^#]*$`. `Platform:          web` and `cli` fit.
- Baseline on this worktree before any edit: `bash tests/run.sh` gives 374 passed, 0 failed, and `bin/po-lint` reports no breach in 25 files.

## Traps
- Pinned phrases that must survive word for word:
  - `po-setup.md`: "Nothing else is asked" (`setup-modes:36`).
  - The five catalogue phrases (`catalogue-wiring:10-16`), including "offer the catalogue before question 5" and "A chosen profile's `## Commands` block becomes the suggestions of question 5, copied verbatim."
  - "If `AGENTS.local.md` is already there, do not touch it." (`structure:38`).
  - In the template: "`Dev` starts the development server" (`qa.test.sh:62`).
  - The `QA stage` follow-up must stay an unnumbered line naming `` `QA stage` `` (`qa.test.sh:66`).
- The lint `fail-closed` rule (`po-lint:164-181`) applies to every new line in a `## Checks` section. A line whose trigger names an absence ("missing", "No ", "`—`") must contain stop, ask, carry on or never blocks.
- The `settings` lint rule (`po-lint:98-115`) breaks if a `Reads settings:` line names `Platform` before the template declares it. The template task comes first.
- Adding a value check means a profile without `## Platform` must yield only the missing-section breach, never a second one. Check the platform line only when the section exists, as the Commands check is gated on `cmdline` (`:233-234`).
- `method/templates/stories-review.md` (the review's checklist) is not in the Owns. Check 9 lives in the skill only.
- `docs/catalogue.md`, `docs/installation.md`, `po-help.md` and `README.md` are not owned either. Nothing new is written there.
- `.claude/` and `.polype/` are installed copies; never edit them. `.polype/templates/agents-local.md` stays stale until the next refresh commit, as with s77 (`f70fbd2`).
- `QA stage: surfaces` becomes a declarable value, but nothing routes on it until s79 and s80 ship. This story only declares it.
- No migration, no dependency, no new screen.

## Open questions
- AskUserQuestion is believed to offer at most four options per question, and there are seven platforms. This was not confirmed from this subagent's tool list. The plan words the follow-up so it does not depend on the limit: it suggests the likely ones and lets the free answer name the others.
- Should `web` admit `endpoint`, since a Next.js app has API routes? ADR-0055 says no: such a project declares `web, api`. A user may find that strict.

## Complexity
Story 3 → 3. The work is prose in eight method files, one small lint rule, and tests. The risk is the number of pinned phrases, not logic.

## Split
Not needed.
