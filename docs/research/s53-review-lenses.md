# Research — s53-review-lenses

[Story](../stories.md)

## Structuring facts
- No assumption of the story is false. Everything it names exists and fits in `Owns` (`docs/stories.md:806`): the reviewer preloads its skills from a frontmatter list (`method/agents/reviewer.md:6-9`), and the installer copies `method/skills/` wholesale (`bin/polype:86`, `:100`), so a new `method/skills/review-lenses/` reaches every install pose without any registration.
- The lenses cannot become a seventh numbered step: `tests/review.test.sh:29-30` counts exactly six `**[1-6]. ` lines, and the heading `## Six steps, all of them, in this order` is pinned (`tests/ownership.test.sh:52`). `tests/review.test.sh` is outside `Owns`. They attach as an unnumbered section of `review-antihallu` after step 6 (`method/skills/review-antihallu/SKILL.md:45`) and before `## Severity` (`:47`).
- "One verdict" is already enforced in shape: the template must end with `Max severity:` then `Ship allowed:` (`tests/review.test.sh:21-25`, `method/templates/review.md:54-55`). A `Lenses run:` line goes above `## Findings` (`review.md:48`), never after the verdicts.
- The story's grades (missing authz → critical, in-place rename → major) are placements on the existing scale (`SKILL.md:49-51`: critical = "an exploitable flaw"; major = "a genuine defect … contained"), not a new scale.
- The story writes « impact potentiel » in French; method files are in English (`AGENTS.local.md`, Conventions). The skill says **potential impact**; the test checks the English phrase.

## Story
The reviewer looks at security, migrations, dependencies and performance when the diff touches them, without a second reviewer or a second verdict. Criteria (each a test in `tests/review-lenses.test.sh`): `lenses_are_triggered_by_the_diff`, `security_lens_rates_a_missing_authz_check_critical`, `migration_lens_rejects_in_place_renames`, `dependency_lens_triggers_on_a_lockfile`, `performance_lens_never_invents_numbers`, `one_reviewer_one_verdict`. Note: short lists, rewritten; agent-skills checklists must not be copied (`docs/stories.md:818`).

## Current code
- `method/agents/reviewer.md` (47 lines). Tools `Read, Grep, Glob, Bash, Edit` (`:4`), no Write. Preloads `review-antihallu`, `testing-doctrine`, `design-doctrine` (`:6-9`). Reads `Target branch`, `Verification mode`, `Test budget`, `ADR directory`, `QA stage` (`:13`). `:15` says "The procedure — the scope check that comes first, then six steps and the severity scale — is the preloaded `review-antihallu` skill." `:44-47` the two verdict lines and "`Ship allowed: no` means a critical finding or a blocked review, and nothing else."
- `method/skills/review-antihallu/SKILL.md` (51 lines). Scope check `:9-20` (takes `git diff --name-only <Target branch>...story/<id>`, `:11`); `## Six steps` `:22`; steps 1-6 `:24-45`; `## Severity` `:47-51`. Description ends "Preloaded in the reviewer; nowhere else." (`:3`).
- `method/templates/review.md` (55 lines). Sections: header `:5-7`, When blocked `:9-13`, Ownership `:15-20`, Evidence reused `:22-24`, Plan `:26-28`, References `:30-32`, Rules `:34-36`, Tests `:38-43`, Neighbours `:45-46`, Findings `:48-49`, Not verified `:51-52`, verdicts `:54-55`.
- `method/skills/` holds eight skills, each `SKILL.md` with frontmatter `name` and `description` (e.g. `review-antihallu/SKILL.md:1-4`). No `review-lenses/` yet.
- `method/commands/po-review.md:30` tells the reviewer "How to review is settled by your agent file and the review-antihallu skill". Outside `Owns`; the agent file covers the new preload.

## Attachment points
- New file `method/skills/review-lenses/SKILL.md`.
- `method/agents/reviewer.md:6-9` — add `  - review-lenses` to `skills:`; `:15` — one sentence after the pinned one.
- `method/skills/review-antihallu/SKILL.md` — a section between `:45` and `:47` pointing to the lenses.
- `method/templates/review.md` — a `## Lenses` section with a `Lenses run:` line between Neighbours (`:45-46`) and Findings (`:48`).
- New test file `tests/review-lenses.test.sh`, helpers from `tests/lib.sh` (`frontmatter :13`, `require_file :41`, `contains :43`).

## Verified interfaces
- `tests/run.sh` runs every `test_*` of every `tests/*.test.sh`, each in its own process (`tests/run.sh:9-22`); a focused run: `bash tests/run.sh review-lenses.test.sh`.
- `contains <file> <phrase>` is `grep -qF` — exact and case-sensitive (`tests/lib.sh:43`).
- `frontmatter <file>` prints the lines between the first two `---` (`tests/lib.sh:13-15`); the preload check pattern used today is `frontmatter "$AGENT" | grep -qx '  - review-antihallu'` (`tests/review.test.sh:17`).
- `section_of` is defined per test file, not in `lib.sh` (`tests/ownership.test.sh:10`, `tests/wiring.test.sh:10`): the new test file defines its own.
- `bin/po-lint:150-154`: an agent preloading `review-antihallu` must not declare Write — unchanged by this story. Baseline: `bin/po-lint` reports no breach in 25 files; the four review-related test files pass 23/23 (run 2026-10-08).

## Traps
- Pinned phrases that must survive: `reviewer.md` "The procedure — the scope check that comes first, then six steps and the severity scale" (`tests/ownership.test.sh:45`), "`Ship allowed: no` means a critical finding or a blocked review, and nothing else." (`tests/review.test.sh:50`), `rev-parse 'story/<id>^{tree}'` (`tests/review.test.sh:63`), `git diff --exit-code` (`:13`).
- `review-antihallu`: exactly six `**N. ` lines (`tests/review.test.sh:29`); the step-1 region read by `tests/qa-gate.test.sh:84-85`; floor-guard phrases (`tests/floor-guard.test.sh:140-145`); scope-section phrases (`tests/ownership.test.sh:16-38`).
- `review.md`: last two non-blank lines are the verdicts (`tests/review.test.sh:23`); `Reviewed tree:` before `Max severity:` (`:57-61`); `## Ownership` before `## Evidence reused` (`tests/ownership.test.sh:71-76`) with its four boxes (`:82-87`); the floor box verbatim (`tests/floor-guard.test.sh:148`); a `qa-current` box under Evidence reused (`tests/qa-gate.test.sh:89-90`).
- Copy risk: the mechanism comes from gstack `review/specialists/` and agent-skills `references/*-checklist.md` (`docs/references/gstack-agent-skills.md:34-40`). That file asks a story inspired by them to pass `bin/ks-overlap <src> 8` against both repositories (`:6`). A gstack copy exists at `/home/lecrabe/.claude/jobs/aacccb17/tmp/gstack-src/repo/gstack`; no local agent-skills copy was found. `tests/overlap.test.sh:5` points to a Killer SaaS copy that is absent here, so that test skips silently (`:14-16`).
- No migration, no screen, no authorization, no API contract, no dependency in this repository: the "migration" and "dependency" of the story are subjects of the lens text, not changes. None of the five full-track signals is present.
- Nearby stories: s55 (reviewer evals) depends on s53 (`docs/stories.md:836`) and will plant an authz defect expecting `critical`; s52 just changed `reviewer.md` and `review-antihallu` (commit `8fd9082`), already on `main`.

## Open questions
- Who decides that a lens runs: prose triggers read by the reviewer, or a deterministic `po-gate` subcommand? `po-gate.sh` is outside `Owns`; content triggers (an outbound call to a URL the user supplies, an LLM call) need reading. The plan decides (ADR-0030).
- Severity of non-authz security findings (SSRF, unsigned webhook) and of performance findings: the story fixes only two grades. The plan should leave the rest to the existing scale rather than invent grades.
- Should the skill name concrete lockfiles and migration paths per ecosystem? Proposed: a short list across the common ecosystems, with "or any equivalent" — the reviewer generalises, the test pins a few names.

## Complexity
Story 3 → 3. Four method files and one test file, no script; the cost is in writing four short, original lists and threading them through three files with many pinned phrases.

## Split
Not needed (score below 5).
