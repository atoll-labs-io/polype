---
track: flow
validated: yes
---
# Plan (short track) — s24-architect-conventions

[Story](../stories.md)

## Verified facts

- `method/commands/po-architect.md:49` is the whole of the defect: « Write the conventions as rules in the `## Conventions` section of `AGENTS.local.md`. Replace only that section's placeholder or body, with Edit; every settings block stays as it is — this command reads settings, it never decides them. » One sentence carries both the replacement (defect 8) and the unguarded settings promise (defect 7).
- `method/commands/po-architect.md:21` (check 3) is the rerun path: « `docs/architecture.md` already exists → this is a rerun: amend that file rather than starting over ». It says *amend* for the architecture file and says nothing about the Conventions section, so step 4 replaces it.
- `docs/reviews/s16-architect.md:40` proves defect 7 by mutation: deleting the step 4 guard sentence makes **0 tests fail** (13 passed). No test in `tests/` asserts it.
- `docs/reviews/s16-architect.md:49` states defect 8 and its remedy: the grouped approval « shows the new draft but not what it removes », so the rerun path must say that existing rules are kept or amended.
- `tests/architect.test.sh:8` defines `section_of <file> <heading>` (awk, exact `## <heading>` match, body until the next `## `) — the tool needed to pin an assertion inside step 4 rather than anywhere in the file.
- `tests/architect.test.sh:31` already greps the first half of the step 4 sentence (« Write the conventions as rules in the `## Conventions` section of `AGENTS.local.md` ») but does so from `test_architect_analyses_code_before_deciding`, with no assertion on the guard that follows it.
- `tests/lib.sh:43` `contains` is exact and case-sensitive (`grep -qF`); `tests/lib.sh:29` `needs_tool` reads the frontmatter. `AskUserQuestion` is already an allowed tool (`method/commands/po-architect.md:10`), so asking about a contradiction needs no frontmatter change.
- `method/commands/po-architect.md:51` is also inside step 4 and holds the other half of the settings guarantee: « report the difference and ask the user to edit the settings; do not change them ». It is equally untested.
- `method/templates/agents-local.md:66-68`: `## Conventions` is the last section of the file, holding only the placeholder `<< layout, stack, patterns, naming, commit style >>`. Every settings block (`## Pipeline`, `## Commands`) sits above it, so « edit the last section only » is a real, checkable boundary.
- `method/commands/po-setup.md:17` already words the exception the same way: « no other command writes this file except `/po-architect`, which fills only its « Conventions » section ». Out of this story's `Owns` — do not touch it.
- `docs/defauts.md:15-16` carry defects 7 and 8, both `ouvert`.
- `tests/wiring.test.sh:27` only checks that `/po-architect` is listed in the cheat sheet; no other test file reads this command. `bash tests/run.sh` is green today: 133 passed, 0 failed.
- The story has no `Matrice` line, so `docs/parite-killer-saas.md` is not touched.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — the story text changes a prompt file and its test | absent — markdown and bash only, no data |
| New screen | absent — no interface named | absent — nothing in `method/commands/` or `tests/` renders |
| Authorization or tenant scope | absent — no actor or permission named | absent — no role read anywhere |
| API contract | absent — no interface between stories | absent — `section_of` stays local to `tests/architect.test.sh` |
| New dependency | absent — no tool named | absent — bash, grep and awk, already used by `tests/lib.sh` |

## Story

`/po-architect` must complete the Conventions section instead of replacing it, and the promise that it never touches a settings block must be held by a test.

Acceptance criteria:
- `architect_merges_conventions_instead_of_replacing` — on a rerun the conventions already present are kept; new ones are added, and a contradicted convention is raised with the user instead of being overwritten in silence.
- `architect_protects_the_settings_blocks` — the command touches no settings block, and the test fails if that guarantee leaves the file.

## Tasks

1. [x] `method/commands/po-architect.md`, step 4: split line 49 into the write rule and the guard. The write rule keeps `## Conventions` as the only section this command edits and states the merge — a first run replaces the placeholder; a rerun keeps every rule already written, adds the new ones after them, and never rewrites the section from scratch, because a convention written by hand is not the command's to delete. — fails `architect_merges_conventions_instead_of_replacing`.
2. [x] Same section: state what happens to a rule that disagrees with the code now — it is kept and reported, never deleted in passing — and that a new rule contradicting an existing one is not written either way: both are quoted to the person in the grouped `AskUserQuestion` of « Approval and commit », who chooses which stands. — fails `architect_merges_conventions_instead_of_replacing`.
3. [x] Same section: restate the settings guarantee as its own sentence, naming the settings blocks as untouched and repeating that this command reads settings and never decides them, so a test can pin it inside step 4. — fails `architect_protects_the_settings_blocks`.
4. [x] `method/commands/po-architect.md`, « Approval and commit » point 2: the grouped question also shows what a rerun would remove or contradict, so approval is given on the diff and not on the draft alone. — fails `architect_merges_conventions_instead_of_replacing`.
5. [x] `tests/architect.test.sh`: add `test_architect_merges_conventions_instead_of_replacing` and `test_architect_protects_the_settings_blocks`, both reading step 4 through `section_of`, each mixing positive assertions on the new wording with a negative grep on the replacing wording (`section's placeholder or body`) so that reverting the edit turns the test red. — these are the tests themselves.
6. [x] `docs/defauts.md:15-16`: defects 7 and 8 become `corrigé par s24`; no other line changes.

## Run interdicts

- `.claude/` and `.polype/` end with an empty diff: they are installed copies, regenerated by `bin/polype-dev-install`. Do not run the installer.
- `method/commands/po-setup.md`, `method/templates/agents-local.md`, `tests/structure.test.sh`, `tests/wiring.test.sh` end with an empty diff: outside `Owns`.
- `docs/parite-killer-saas.md` ends with an empty diff: this story has no matrix line.
- Only lines 15 and 16 of `docs/defauts.md` change.
- No new test file: the two functions go into `tests/architect.test.sh`.
- Do not edit `AGENTS.local.md` itself — the story changes the command that writes it, not the settings of this repository.

## Files touched

- `method/commands/po-architect.md`
- `tests/architect.test.sh`
- `docs/defauts.md`

## Test strategy

Two new functions in `tests/architect.test.sh` (2 tests for this story, within the budget of 25), at the only layer this repository has for prompt files: exact assertions on the text of the file under test. Both scope their greps to the body of `## Step 4 — Conventions as rules` through `section_of`, so deleting the guarantee or moving it out of the step that writes the file turns them red — which is exactly the mutation `docs/reviews/s16-architect.md:40` showed passing today. Each test pairs its positive assertions with a negative grep on the old replacing wording, so a revert cannot make the file pass on the strength of leftover prose. Run `bash tests/run.sh architect.test.sh` while working, then the full suite `bash tests/run.sh` at the end; `tests/overlap.test.sh` guards the new prose against Killer SaaS wording.

## Done when

- Both criteria pass, and reverting either edit to `method/commands/po-architect.md` turns its test red.
- `bash tests/run.sh` is green, the 133 pre-existing checks included.
- Defects 7 and 8 read `corrigé par s24`.
- One commit on `story/s24-architect-conventions` carrying the plan, the record and the three files.
