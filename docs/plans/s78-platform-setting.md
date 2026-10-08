---
validated: yes
---
# Plan — s78-platform-setting

Branch `story/s78-platform-setting`. Read `docs/research/s78-platform-setting.md` first; this plan builds on it without repeating it. The three details ADR-0054 leaves open are settled in `docs/decisions/ADR-0055-chaque-plateforme-admet-ses-surfaces.md`, which is written, uncommitted, and travels with this story:
- how the list is written: commas, template value `web`;
- which surfaces each platform admits;
- how a profile writes its platform: a `- Platform:` line that `po-lint` checks.

## Story
The project declares `Platform`, each boilerplate profile declares its own, and each story declares a `Surface`. That way design and QA later know what to check without guessing.

The criteria, each one the name of a test in `tests/platform-setting.test.sh`:
- `platform_is_a_setting`
- `profiles_declare_their_platform`
- `setup_asks_the_platform`
- `stories_declare_a_surface`
- `polype_declares_its_platform`

## Tasks
1. [x] **Settings template and Polype's own settings.**
   - In `method/templates/agents-local.md`, add `Platform:          web` to the Pipeline block, on the line just before `QA stage:`, aligned like its neighbours.
   - Add a values-table row just before the `QA stage` row. Its backticked lowercase words must be exactly the seven values, because `po-lint` reads them from it (ADR-0055):
     `| Platform | what the project builds, one or more of `web` · `mobile` · `cli` · `api` · `lib` · `xr` · `robot`, separated by commas; it decides which boilerplate profiles `/po-setup` offers and which `Surface` a story may declare (ADR-0054, ADR-0055) |`
   - Rewrite the `QA stage` row:
     `` `screens` — /po-qa walks the screens a story touches before its review · `surfaces` — /po-qa checks every story whose `Surface` is not `—`, with the driver of that surface (ADR-0054) · `—` — no QA stage ``
   - Rewrite the `Dev` sentence of `:81`. "`Dev` starts the development server" must stay word for word (`tests/qa.test.sh:62`). The clause "`/po-qa` needs it and stops on `—`." stays as it is: s79 rewrites it. The new sentence:
     `` `Dev` starts the development server, or whatever serves what a person looks at (the web render of a mobile app), and prints the address it serves; `—` when the project has nothing to serve. `/po-qa` needs it and stops on `—`. ``
   - In `AGENTS.local.md`, add `Platform:          cli` at the same position.
   - Tests that would fail if this task were wrong:
     - `test_platform_is_a_setting`;
     - `test_polype_declares_its_platform`;
     - the existing `tests/leftovers.test.sh` `test_polype_declares_every_template_setting`, which goes red if only the template gains the line.
2. [x] **The profile declares its platform, and the lint checks it.**
   - In `method/templates/profile.md`, add a section `## Platform` between `## Identity and licence` and `## Commands`. It holds the line `- Platform: web`, then one sentence:
     > One or more values of the `Platform` setting of `templates/agents-local.md`, separated by commas; `/po-setup` offers this profile only to a project that declares one of them.
   - In the same file:
     - Extend the preamble (`:3`) with "and the platforms of `## Platform` must be values of the `Platform` setting".
     - Add to `## UI inventory`: "A boilerplate with no screen says so in one line."
   - In `boilerplates/next-forge/profile.md`, add `## Platform` with `- Platform: web` at the same place.
   - In `bin/po-lint`, change `check_profiles`:
     - Read the allowed values once: `grep -m1 '^| Platform |' "$TEMPLATE" | grep -o '`[a-z][a-z]*`' | tr -d '`'`. If that list is empty, report `templates/agents-local.md` once (rule `profile`).
     - Run the new check only when the profile has the `## Platform` heading, so a missing section stays exactly one breach.
     - Within that section, no `- Platform:` line → report the heading's line, `no '- Platform:' line under '## Platform'`.
     - Otherwise split the value on commas, trim each part, and report each one not in the list, at that line: `platform '<value>' is not a value of the Platform setting`.
     - Update the rule's header comment.
   - In `tests/profile.test.sh:19-20`, add `## Platform` to the heading list. The clause changes; say so in the commit.
   - Tests that would fail if this task were wrong:
     - `test_profiles_declare_their_platform`;
     - the existing `test_lint_checks_profiles`, which demands zero breaches on the template copied as a profile, so the template's own `- Platform: web` must pass;
     - `test_next_forge_profile_passes_the_lint`.
3. [x] **`/po-setup` asks the platform.** Edit `method/commands/po-setup.md`, step 2. The five numbered questions stay as they are.
   - After the list, add an unnumbered paragraph:
     > Before the catalogue offer and question 5, make one separate AskUserQuestion call for `Platform`: what the project builds, one or more of `web`, `mobile`, `cli`, `api`, `lib`, `xr`, `robot`. Offer the likeliest ones as options and let the free answer name any of the seven; write the answer separated by commas.
   - Rewrite the `QA stage` paragraph (`:39`):
     > Once the `Dev` and `Platform` answers are known, make one separate AskUserQuestion call for `QA stage`: `screens` (/po-qa walks the screens a story touches), `surfaces` (/po-qa checks every story whose `Surface` is not `—`) or `—`. Suggest `screens` only when `Dev` is not `—`. When `Dev` is `—` and `Platform` names a platform without a screen — `cli`, `api`, `lib` or `robot` — ask anyway, offering `surfaces` or `—`; otherwise skip this call: `QA stage` stays `—`, since QA cannot start the application.
   - In the catalogue sentence (`:41`), insert after `when it is at hand)` the filter:
     > whose `- Platform:` line names one of the project's platforms
   - Add after it:
     > No profile fits those platforms → say so and carry on without one.
   - Every pinned phrase of `tests/catalogue-wiring.test.sh:10-16` stays intact.
   - Line `:43` becomes: "Nothing else is asked beyond these five questions, the `Platform` follow-up, that design follow-up, the `QA stage` follow-up and the catalogue offer; …", with the rest unchanged.
   - Step 1 gains nothing.
   - Tests that would fail if this task were wrong:
     - `test_setup_asks_the_platform`;
     - the existing `tests/setup-modes.test.sh:29-37`, `tests/qa.test.sh:55-69` and `tests/catalogue-wiring.test.sh:9-17`.
4. [x] **Stories carry a `Surface`, written from `Platform`.**
   - In `method/templates/stories.md`, insert between `Depends on` and `Owns`:
     `- **Surface**: <what a person checks once the story ships: `screen` · `command` · `endpoint` · `scene` · `behaviour`, one the project's `Platform` admits by the table of the `agentic-stories` skill, or `—` when nothing is seen or run>`
   - In `method/skills/agentic-stories/SKILL.md`, add a section `## Surface` between "Owns and contracts first" and "Complexity and splitting". It says:
     - every story declares one `Surface`, with the five values and what each means (ADR-0054);
     - `—` means the story changes nothing a person sees or runs;
     - a story without the line keeps the old rule: it has a screen when its text shows one.
   - The same section carries the admission table, written only here, with the header `| Surface | Admitted by the platforms |` and these rows:

     | Surface | Admitted by the platforms |
     | --- | --- |
     | `screen` | `web`, `mobile` |
     | `command` | `cli` |
     | `endpoint` | `api`, `lib` |
     | `scene` | `xr` |
     | `behaviour` | `robot` |
     | `—` | every platform |

     After the table, add the sentence "a web project that also serves an API declares `web, api`". Add `surface` to the skill's `description`.
   - In `method/commands/po-stories.md`:
     - `Reads settings:` gains `` `Platform` ``.
     - Checks gain an item placed before "Read the `agentic-stories` skill", renumbering it: "`Platform` missing → stop and name it: `/po-setup` writes it, and `polype update` lists it to a project set up before it."
     - Sequence step 2 lists "surface" among the drafted fields, and step 5 lists "surface".
     - "Before writing" gains: "Every story carries a `Surface` the project's `Platform` admits, by the table of the `agentic-stories` skill, or `—`."
   - The lint `fail-closed` rule must stay quiet: the new Checks line says "stop".
   - Test that would fail if this task were wrong: `test_stories_declare_a_surface` (writer half).
5. [x] **`stories-review` checks the surface, reading `Platform`.**
   - In `method/skills/stories-review/SKILL.md`, append check **9** after check 8. Check 8 and every number before it stay unchanged.
     > **9. Surface.** Every story carries a `Surface` line: `screen`, `command`, `endpoint`, `scene`, `behaviour` or `—`. A story without one keeps the old rule — it has a screen when its text shows one — and is a minor finding. A surface that the project's `Platform`, as the command passes it, does not admit by the table of "Surface" in `agentic-stories` is major: the story would be designed or checked with the wrong driver.
   - In the same file's `## Severity`, major gains "a `Surface` the project's `Platform` does not admit" and minor gains "a story with no `Surface` line". Add `surface` to the skill's `description`.
   - In `method/agents/stories-reviewer.md`:
     - `Reads settings:` becomes `` `Entry mode`, `ADR directory`, `Platform` ``.
     - Inputs gain "the project's `Platform`, which the message names".
   - In `method/commands/po-stories-review.md`:
     - `Reads settings:` gains `` `Platform` ``.
     - Checks gain item 7: "`Platform` missing → stop and name it."
     - The prompt's parenthesis becomes `(Entry mode: <value>, Platform: <value>)`.
   - Test that would fail if this task were wrong: `test_stories_declare_a_surface` (review half). `bin/po-lint` must still report no breach, since `Platform` is now a template setting.
6. [x] **Tests and full checks.**
   - Write `tests/platform-setting.test.sh` (see Test strategy) and run it alone: `bash tests/run.sh platform-setting.test.sh profile.test.sh`.
   - Then run, once, through `po-run`:
     - `po-run --story s78-platform-setting --label test -- 'bash tests/run.sh'`;
     - `po-run --story s78-platform-setting --label lint -- 'bash bin/po-lint'`.
   - The baseline was 374 passed, and `po-lint` was clean.

## Run interdicts
- Empty diff for:
  - `.claude/` and `.polype/`, which are installed copies;
  - `docs/stories.md` and every file under `docs/decisions/` except the new ADR-0055;
  - `method/templates/stories-review.md`, `method/agents/qa.md`, `method/commands/po-qa.md`, `method/commands/po-help.md`, `method/commands/po-drive.md`, `method/AGENTS.md`;
  - `README.md`, `docs/catalogue.md`, `docs/installation.md`;
  - `tests/qa.test.sh`, `tests/catalogue-wiring.test.sh`, `tests/leftovers.test.sh`, `tests/owns-overlap.test.sh`.
- `po-setup.md` step 2 still has exactly five lines matching `^[0-9]+\. `.
- The pinned phrases listed in the research's Traps are present word for word.
- `stories-review` checks 1-8 are byte-identical to `main`. Check 9 is appended and nothing is renumbered.
- `agents-local.md` still holds "`/po-qa` needs it and stops on `—`": s79 rewrites it, not this story.
- No file routes on `QA stage: surfaces` or reads `Surface` for design or QA: that is s80's work.
- `bin/po-lint` keeps no hard-coded platform list: `grep -c 'mobile' bin/po-lint` is 0.

## The pivot
The pivot is ADR-0055's **strict admission table**, read from one place. `agentic-stories` writes it, and `po-lint` takes the allowed values from the `Platform` row of the settings template. Three ways it could be wrong:
- **`web` and `endpoint`.** A web app with API routes has to declare `web, api`, or `stories-review` flags its endpoint stories major. Compare with next-forge, whose `apps/api/` serves webhooks (`boilerplates/next-forge/profile.md:28`). If that seems too strict, a later ADR loosens the table; the plan does not.
- **The row extraction.** `po-lint` takes every backticked all-lowercase word of the `| Platform |` row. A future edit that adds such a word (say `` `none` ``) silently widens the list. Compare the extracted list with the seven values in the test.
- **The template value `web`.** An upgrading CLI project reads `missing setting: Platform: web`. The installer only names it and never writes it (`bin/polype:194-211`), so the person still chooses. Check that no installer path writes the value.

## Files touched
- `method/templates/agents-local.md`, `AGENTS.local.md`
- `method/templates/profile.md`, `boilerplates/next-forge/profile.md`, `bin/po-lint`
- `method/commands/po-setup.md`
- `method/templates/stories.md`, `method/skills/agentic-stories/SKILL.md`, `method/commands/po-stories.md`
- `method/skills/stories-review/SKILL.md`, `method/agents/stories-reviewer.md`, `method/commands/po-stories-review.md`
- `tests/platform-setting.test.sh` (new), `tests/profile.test.sh` (heading list)
- Planner's files, committed with the code: `docs/research/s78-platform-setting.md`, `docs/plans/s78-platform-setting.md`, `docs/decisions/ADR-0055-chaque-plateforme-admet-ses-surfaces.md`

## Test strategy
There are five automated tests, one per criterion, in `tests/platform-setting.test.sh`, plus one existing list extended. That is well within `Test budget` (25). Each test quotes short exact phrases. A prose-only rule is guarded by the phrase that states it; the lint is guarded by mutation.

- `test_platform_is_a_setting`:
  - `template_settings` contains `Platform`.
  - The `| Platform |` row holds each of the seven backticked values.
  - The `QA stage` row holds `` `screens` ``, `` `surfaces` `` and `` `—` ``.
  - The template says "or whatever serves what a person looks at" and "`—` when the project has nothing to serve".
- `test_profiles_declare_their_platform`:
  - The profile template has the `## Platform` heading and a `- Platform:` line.
  - The next-forge profile's `## Platform` section holds `- Platform: web`.
  - Lint mutations follow the pattern of `tests/profile.test.sh:39-81`, with exactly one breach each:
    - deleting `## Platform` from a copied profile → `missing section '## Platform'`;
    - `- Platform: Web` → `platform 'Web' is not a value of the Platform setting` at that line;
    - `- Platform: web, mobile` → passes.
  - The last case proves the comma split. Removing the value check makes the second mutation pass, which fails the test.
- `test_setup_asks_the_platform`:
  - Step 2 still has five numbered lines.
  - An unnumbered line of step 2 names `` `Platform` ``, and it comes before the line "offer the catalogue before question 5".
  - `po-setup.md` contains "whose `- Platform:` line names one of the project's platforms" and "`cli`, `api`, `lib` or `robot`".
  - The `QA stage` paragraph names `` `surfaces` ``.
- `test_stories_declare_a_surface`:
  - The template contains `**Surface**` and its `Owns` line follows it.
  - `agentic-stories` has `## Surface` with the header `| Surface | Admitted by the platforms |` and the row `` | `command` | `cli` | ``.
  - `settings_read_by` of `po-stories.md`, `stories-reviewer.md` and `po-stories-review.md` each include `Platform`.
  - `po-stories-review.md` contains `Platform: <value>`.
  - Check 9 of `stories-review` (extracted like `C8_AWK`) contains "is a minor finding" and "is major".
  - `## Severity` names `Surface` under major and minor.
- `test_polype_declares_its_platform`:
  - `AGENTS.local.md` has the line `Platform:          cli`.
  - `bash bin/polype check "$ROOT"` prints `installed in` and no `missing setting:` line. Do not assert on its exit status: in a worktree `.claude/` is absent, so it exits 1.

No manual or visual checks: this story has no screen.

## Done when
- All six tasks are ticked.
- `bash tests/run.sh` is green, with every earlier test still passing, and `bin/po-lint` reports no breach. Both are recorded through `po-run` in `docs/verif/s78-platform-setting.md`.
- One commit on `story/s78-platform-setting` holds the code, the tests, the research, this plan and ADR-0055.
- The review has no open critical finding.
