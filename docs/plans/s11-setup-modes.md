---
validated: yes
---
# Plan — s11-setup-modes

Branch `story/s11-setup-modes`. Read `docs/research/s11-setup-modes.md` first; this plan builds on it without repeating it.

## Story
`/po-setup` asks where the project starts (replace / adapt / new) and who draws the screens; the settings template carries the framing settings the later M2 commands read.
- `settings_template_declares_framing_settings` — `Entry mode`, `Design source`, `Design skill`, `Design tool`, `Story track`, `Flow threshold` declared and each documented in the values table with its values.
- `setup_asks_entry_mode_and_design_source` — five questions in total, no more.
- `setup_never_defaults_design_silently` — a design source left at `—` makes design commands stop and ask again.

## Decisions
| Question | Choice | Why |
| --- | --- | --- |
| Where the settings go | Appended to the `## Pipeline` fence and to its existing values table | The criterion names "the values table"; one table keeps one place to look. A separate section would add a heading for six lines. |
| Template defaults | `Entry mode: —`, `Design source: —`, `Design skill: —`, `Design tool: —`, `Story track: auto`, `Flow threshold: 2` | `—` is "not chosen": setup always asks the first two, and a design command must stop on `—` rather than guess. Track and threshold values come from the story notes. |
| Design skill / tool | Collected inside question 4: `internal` → which skill draws, `external` → which tool; the other one stays `—` | Keeps the count at five; the name only makes sense once the source is known. |
| Story track / Flow threshold | Not asked; template values kept | Story notes fix the defaults; asking would make a sixth question. |

## Tasks
1. [x] `method/templates/agents-local.md`: add the six lines to the `## Pipeline` fence (aligned like the others, no trailing comment) and six rows to the values table: `Entry mode` (`replace` — build an internal replacement of a paid SaaS · `adapt` — a competing product with its own angle · `new` — an idea from scratch · `—` not chosen yet), `Design source` (`internal` — screens drawn in the repository by an agent skill · `external` — a tool outside the repository · `—` means design commands stop and ask), `Design skill` (skill used when the source is `internal`), `Design tool` (tool used when it is `external`), `Story track` (`full` · `flow` · `auto`, `auto` takes the short track up to `Flow threshold`), `Flow threshold` (highest complexity allowed on the short track). — Test: `settings_template_declares_framing_settings`, fails if a name is missing from the fence or from the table, or a listed value is absent from its row.
2. [x] `method/commands/po-setup.md`: step 2 becomes "Five questions"; insert question 3 (entry mode, three options) and question 4 (design source `internal` / `external` / not decided, with the skill or tool name asked in the same call); commands move to question 5; keep "Nothing else is asked" and name `Story track`/`Flow threshold` as keeping template values. Update the frontmatter `description` ("five answers"). Add in step 2 a sentence that a `Design source` left at `—` makes every design command stop and ask for it again, and that setup never fills it on the user's behalf. Keep the three phrases quoted by `tests/structure.test.sh:38,42,43` verbatim. — Tests: `setup_asks_entry_mode_and_design_source` (counts exactly five numbered items in step 2 and finds `Entry mode` and `Design source` there), `setup_never_defaults_design_silently`.
3. [x] `tests/setup-modes.test.sh`: the three tests above, helpers from `tests/lib.sh`, header comment `# s11 — framing settings and setup questions.`
4. [x] `docs/parite-killer-saas.md`: status cells of B02 and C01 only — B02 `partiel — method/templates/agents-local.md ; flotte en M3, profil et briques en M4`, C01 `partiel — method/commands/po-setup.md ; boilerplate en M4`.
5. [x] Full suite `bash tests/run.sh` green (including `overlap.test.sh` and `structure.test.sh`), verification record, one commit.

## Run interdicts
- Empty diff for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `tests/structure.test.sh`, `tests/lib.sh`, every `method/` file other than the two owned ones.
- In `docs/parite-killer-saas.md`, only the status cells of B02 and C01 change.
- No Killer SaaS text: wording written from the French matrix descriptions only.
- No new command reads the new settings in this story (that is s12, s13, s18, s19, s20).

## The pivot
`—` as default for `Entry mode` and `Design source`. It could be wrong if (a) `test_settings_template_one_value_per_line` rejects `—` — compare with `E2E browsers: —` already accepted at `agents-local.md:19`; (b) a later command expects a real default — check s12/s13 criteria, which stop or route on the value, never on absence; (c) the question count drifts above five when skill/tool become separate calls — the test counts numbered items.

## Files touched
`method/templates/agents-local.md`, `method/commands/po-setup.md`, `tests/setup-modes.test.sh`, `docs/parite-killer-saas.md`, plus `docs/research/`, `docs/plans/`, `docs/verif/` for this story.

## Test strategy
Three structural tests in `tests/setup-modes.test.sh`, one per criterion (3 of the 25 budget); all at the text layer, the only layer a markdown method has. Each must fail when its clause is removed: the reviewer deletes a table row, a question, the `—` sentence. Existing `structure.test.sh` guarantees (never overwrite, gitignore, grouped commit, known settings) cover the kept behaviour — no new test for them. No visual check.

## Done when
One commit on `story/s11-setup-modes`, full suite green, a review with no open critical finding, then the squash on `m2-cadrage`.
