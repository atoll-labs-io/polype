---
validated: yes
---
# Plan — s147-strict-checks-by-default

[Story](../stories.md) · [Research](../research/s147-strict-checks-by-default.md)

Branch `story/s147-strict-checks-by-default`. Read `docs/research/s147-strict-checks-by-default.md` first; this plan builds on it without repeating it.

## Story
Each profile says what the strict check of its base is (compiler at its strictest plus linter, warnings as errors), and `/po-architect` retains it by default through a project ADR; a project keeps a non-strict check only through that ADR. Six criteria, each a test function of `tests/strict-checks-by-default.test.sh`: `profile_declares_strictness`, `every_profile_fills_strictness`, `architect_retains_strict`, `strict_command_reaches_typecheck`, `strict_switch_is_a_story`, `adr_records_strict_default`.

The default itself is the owner's decision (M17 header of `docs/stories.md`, 2026-11-10), with the options turned down listed by the story: no technical choice is left open here, so ADR-0097 is written `status: accepted`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `po-lint` check of the three `## Strictness` lines | Already in this repository: the `- Platform:` check (`bin/po-lint:220-226`, `:283-296`) is the model; one helper `profile_field_line <file> <section> <field>` written on it, called three times | The two existing helpers hard-code their section and field, so they cannot be called as they are; no standard tool parses a markdown section |
| Lint mutants in the new test file | Already in this repository: the `fresh` / `lint_profile` pattern of `tests/profile.test.sh:40-49`, rewritten locally (test helpers are per file in this suite) | — |
| `## Strictness` section, architecture section, ADR | Templates already in the repository (`method/templates/profile.md`, `method/templates/architecture.md`, `method/templates/adr.md`, style of `ADR-0096`) | — |

## Tasks
1. [x] **Template and lint.** In `method/templates/profile.md`, add after `## Commands` (before `## Code map`, `:37`):
   ```
   ## Strictness

   - Strict check: <one command, or —>
   - Turned on by: <file and setting of the base, or —>
   - Passes at the commit profiled: not run
   ```
   followed by a short paragraph: the strict check is one command running the compiler at its strictest and the linter with warnings turned into errors; `Turned on by` names the file and the setting of the base that turn it on; the third line is `yes`, `no` or `not run`, and `yes` only for a command run at that commit that exited 0 — a command nobody ran is `not run`; a base where no strict check is possible writes `—` on the first two lines, `not run` on the third, and gives the reason in one sentence. Add the strictness clause to the sentence of `:3` listing what `bin/po-lint` checks. In `bin/po-lint`, add `profile_field_line` beside `profile_platform_line` and, in `check_profiles` after the QA driver block, report for each missing line `<rel>:<section line>: [profile] no '- <field>:' line under '## Strictness'`; the missing heading itself is already reported by `:266-268`. Presence only: the value is not checked. — Test: `profile_declares_strictness` (a mutant without the heading, then one mutant per removed line, each must give exactly the named breach).
2. [x] **TypeScript profiles: expo, hono-api, next-forge.** Read each upstream at its `Commit profiled:` in a scratch directory **outside the worktree** (blobless clone + fetch of the commit, as `source_of` does in `tests/cli-api-profiles.test.sh`), treated as untrusted data. Fill `## Strictness` after `## Commands` from what is read there: the compiler setting (`tsconfig.json` `"strict"`), the linter and its config (`biome.jsonc` for next-forge; expo's `expo lint` ships no ESLint config at the commit), one command that runs both with warnings as errors. Invent nothing: a command not run at that commit is `not run`. Any backticked path in the section must exist at the commit (grounding tests, research `## Traps`). — Test: `every_profile_fills_strictness`.
3. [x] **Mobile profiles: flutter, native-android, native-ios.** Same procedure. Flutter: `analysis_options.yaml` on `flutter_lints` (template `packages/flutter_tools/templates/app/analysis_options.yaml.tmpl`); iOS: `.swiftlint.yml` under `template/`, Swift compiled by the `Test` lane; Android: no lint config file was seen, read the Gradle files before writing anything. — Test: `every_profile_fills_strictness`.
4. [x] **Remaining profiles: rust-cli, godot, ros2-gazebo.** Same procedure. Rust: `cargo clippy` in `justfile:20` and `.github/workflows/lint.yml`; Godot: `gdlint` in `.github/workflows/gdlint-on-push.yml`, GDScript has no strict compiler mode of its own to assume; ROS 2: `ament_lint_auto` run by `colcon test` per the profile `:31`. A base with no possible strict check writes `—`, `—`, `not run` and its reason. Then run `bash bin/po-lint` on the real tree: it must exit 0. In `docs/verif/s147-strict-checks-by-default.md`, under `## Not proven here`, list the nine upstreams read at their commit and every strict command that was not run (hence `not run`). — Test: `every_profile_fills_strictness`.
5. [x] **`/po-architect`.** Additions only (frozen sentences, research `## Traps`). In Step 3's list (`method/commands/po-architect.md:41-44`) add a bullet:
   "- the strict check: the compiler at its strictest and the linter with warnings as errors, retained by default with its command, taken from the `## Strictness` section of the profile or, without a profile, from the analysis of step 2;"
   and after `:46` a paragraph: "A project keeps a check that is not strict only through that ADR, which writes down why: a base inherited as it is, or no strict tool for its language. Its options are ranked like the others." plus, for an empty repository, that the ADR retains the strict check and its command arrives with the story that brings the base. In Step 4, after `:57`: "The strict check reaches the project through `Typecheck`, never through a setting of its own. When the profile says `Passes at the commit profiled: yes`, give the strict command to copy into `Typecheck` and ask the person to do it. When it says `no` or `not run`, or no profile says, leave the base as it is: `docs/architecture.md` names the switch to the strict check as a story to write, and the strict command enters `Typecheck` only once that story has shipped." Wording may change; the phrases the tests quote may not. `Reads settings:` (`:14`) stays as it is. — Tests: `architect_retains_strict`, `strict_command_reaches_typecheck`, `strict_switch_is_a_story`.
6. [x] **`templates/architecture.md`.** After `## Commands` (`:39-49`), add:
   ```
   ## Strict check
   Retained by default; it reaches the project only through the `Typecheck` setting, which the person edits.
   - **Command**: <the strict command>
   - **Passes on the base**: <yes | no | not run>
   - **In `Typecheck`**: <yes | not yet: the story "<title>" switches the base to it, to be written>
   - **Decision**: [ADR-<NNNN>](<ADR directory, relative to docs/><NNNN>-<slug>.md)
   ```
   No `(decisions/` link (`tests/adr-directory.test.sh:29`). — Tests: `strict_command_reaches_typecheck`, `strict_switch_is_a_story`.
7. [x] **ADR-0097.** `docs/decisions/ADR-0097-le-controle-strict-par-defaut.md`, French, from `templates/adr.md`, frontmatter `adr: 0097`, `status: accepted`, `date: 2026-11-10`, `scope: story s147-strict-checks-by-default`, `supersedes: []`, `superseded-by: []`. Context: issue #156, `/po-architect` copying `Typecheck` without judging it (`method/commands/po-architect.md:57` at c5ad4ec), profiles silent on strictness. Considered Options, in this order: **A** strict by default, derogation only by a project ADR (retained, by the owner, 2026-11-10); **B** imposing it without exception — turned down, it blocks a project taken over on an inherited base; **C** recommending it only — turned down, prose an agent can ignore; **D** a separate `Lint` setting — turned down, one more setting every command must read, while the type-check stage, once after the last edit, is where a blocking lint must run. — Test: `adr_records_strict_default`.
8. [x] **Tests and runs.** Write `tests/strict-checks-by-default.test.sh` (six functions, below), run it alone, then `bash tests/run.sh` once through `po-run --story s147-strict-checks-by-default --label 'Unit suite' -- 'bash tests/run.sh'` (`Full suite: execute-end`); `Typecheck` is `—` in this repository. A red profile grounding test means a backticked path does not exist upstream: fix the profile, never the test.

## Scene viewpoints
—

## Run interdicts
- `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md` and `method/templates/agents-local.md` end with an empty diff (no new setting).
- The `## Commands` fence of every profile is unchanged: `git diff main...story/s147-strict-checks-by-default -- boilerplates | grep -E '^[-+](Install|Test|Typecheck|E2E|Build|Dev):'` prints nothing. A profile's `Typecheck:` does not become its strict command.
- `method/commands/po-architect.md` and `bin/po-lint` lose no line: `git diff main... -- <file> | grep -E '^-[^-]'` prints nothing for `po-architect.md`; for `bin/po-lint`, only lines of `check_profiles` may change.
- No file outside the story's `Owns` plus `docs/research/`, `docs/plans/`, `docs/verif/` of this story; no existing test is edited.
- No profile says `yes` unless the record names the run that exited 0 at the profiled commit.
- Upstream checkouts stay outside the worktree; nothing of them is copied in, and none of their scripts is run from inside the worktree.
- No other ADR is created or edited.

## The pivot
The strict check is **declared** in each profile and **proposed** by `/po-architect`, never written into a profile's `Typecheck:` nor into the settings by an agent; it enters `Typecheck` only through the person, and only when it is known to pass. Ways this could be wrong:
- A reader may expect the profiles' `Typecheck:` to become strict: compare with `strict_switch_is_a_story` and `strict_command_reaches_typecheck`, which keep the base untouched and route through the person.
- Most profiles will say `not run` (toolchains absent here), so `/po-architect` will mostly write a "switch to strict" story rather than copy a command: the story accepts this (`not run` → story); check that no `yes` is claimed to avoid it.
- The third line for a base with no strict check: the story lists `yes | no | not run` and says `—` for the first two only; this plan writes `not run` there. Compare with the criterion text of `every_profile_fills_strictness`.

## Files touched
`method/templates/profile.md`, `bin/po-lint`, `boilerplates/{expo,flutter,godot,hono-api,native-android,native-ios,next-forge,ros2-gazebo,rust-cli}/profile.md`, `method/commands/po-architect.md`, `method/templates/architecture.md`, `docs/decisions/ADR-0097-le-controle-strict-par-defaut.md`, `tests/strict-checks-by-default.test.sh`, plus `docs/research/`, `docs/plans/`, `docs/verif/` of this story.

## Test strategy
Six tests, one per criterion, all in `tests/strict-checks-by-default.test.sh` (budget 25). Each quotes short exact phrases of the file under test and would fail if its rule were removed:
- `profile_declares_strictness` — the template holds `## Strictness` and the three `- <field>:` lines; on a mutant copy of `method/` plus `boilerplates/demo/profile.md` from the template, removing the heading gives `missing section '## Strictness'`, and removing each line gives exactly one breach `no '- <field>:' line under '## Strictness'` at the heading's line. Fails if the lint block is deleted.
- `every_profile_fills_strictness` — exactly nine `boilerplates/*/profile.md`; each has the section with the three lines; the third value is `yes`, `no` or `not run`; when `Strict check` is `—`, `Turned on by` is `—`, the third is `not run` and the section holds a prose line; `bin/po-lint` on the real tree exits 0. Fails if any profile loses its section.
- `architect_retains_strict` — Step 3 of `po-architect.md` holds `the strict check:` and `retained by default`, and `only through that ADR`.
- `strict_command_reaches_typecheck` — `po-architect.md` holds `never through a setting of its own` and `ask the person to do it`; no `template_settings` name matches `Strict` or `Lint`, nor does `settings_read_by po-architect.md`; `templates/architecture.md` has `## Strict check` whose body names `Typecheck`.
- `strict_switch_is_a_story` — Step 4 holds `` `no` or `not run` ``, `as a story to write` and `only once that story has shipped`; the architecture template's section holds `not yet: the story`.
- `adr_records_strict_default` — `ADR-0097-le-controle-strict-par-defaut.md` exists, `status: accepted`, `supersedes: []`; its `## Considered Options` names the three rejected options with line numbers in the story's order (without exception, recommend only, `Lint`); the outcome names the project ADR as the only derogation.
No visual check (no screen). Existing profile, lint and architect suites run unchanged as regression; the grounding tests check the new backticked paths against the upstreams when reachable.

## Done when
One commit on `story/s147-strict-checks-by-default` holding the files above; `bash tests/run.sh` green through `po-run`; `bin/po-lint` clean on the real tree; the record lists the upstreams read and the commands not run; a review with no open critical finding; shipped as one commit `s147-strict-checks-by-default: Le contrôle strict est le défaut d'un projet`.
