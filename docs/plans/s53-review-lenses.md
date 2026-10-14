---
validated: yes
---
# Plan — s53-review-lenses

[Story](../stories.md) · [Research](../research/s53-review-lenses.md)

Branch `story/s53-review-lenses`. Read `docs/research/s53-review-lenses.md` first; this plan builds on it without repeating it.

Track: full — the story is rated 3, above `Flow threshold: 2`. None of the five full-track signals is present, on the story text or in the code (no migration, screen, authorization, API contract or dependency in this repository; those words are subjects of the lens text). Structural choice recorded in ADR-0030 (preloaded skill, applied after step 6, triggered by the reviewer's reading of the diff). Plan validated autonomously: no human reviewed it.

## Story
The reviewer looks at security, migrations, dependencies and performance when the diff touches them — one reviewer, one severity scale, one verdict.

- `lenses_are_triggered_by_the_diff` — the skill says which paths or contents trigger each lens; the review template has a line listing the lenses run.
- `security_lens_rates_a_missing_authz_check_critical` — per-resource authorization, outbound calls to a supplied URL, upload, webhook signatures, rate limit held by a shared store, error messages, trust boundaries of an LLM call; a missing authorization check is critical.
- `migration_lens_rejects_in_place_renames` — renaming or dropping a column in place is major; the lens asks for expand/contract steps and the rollback.
- `dependency_lens_triggers_on_a_lockfile` — a lockfile in the diff triggers the dependency lens: one dependency per change, its changelog and install scripts read, its reason in the plan.
- `performance_lens_never_invents_numbers` — N+1, unbounded read, missing pagination, avoidable sequential calls; each finding marked "potential impact" (story: « impact potentiel »; method files are English), never quantified.
- `one_reviewer_one_verdict` — the existing reviewer loads the lenses; no new severity scale, no second verdict line.

## Tasks
1. [x] **The skill** — create `method/skills/review-lenses/SKILL.md`, written in English, in your own words (no sentence from gstack, agent-skills or Killer SaaS). Target 60-90 lines; each lens list 5-8 bullets. Structure and the exact phrases the tests pin (keep them verbatim):
   - Frontmatter: `name: review-lenses`; `description:` one sentence saying what the lenses are, ending "Preloaded in the reviewer; nowhere else." (same closing as `review-antihallu/SKILL.md:3`).
   - Intro (2-3 lines): a lens widens **where** the reviewer looks, never **how** it judges.
   - `## Which lenses run` — the reviewer reads `git diff --name-only <Target branch>...story/<id>` (the list the scope check already took) and the diff itself. Then a table `| Lens | Paths that trigger it | Content that triggers it |` with exactly four rows starting `| Security |`, `| Migration |`, `| Dependencies |`, `| Performance |`:
     - Security — paths naming auth, session, permission/policy, middleware, routes/handlers/API, upload, webhook; content: a check on who may read or change a record, an HTTP call whose URL comes from input, multipart/file handling, a signature header, a rate limiter, a call to an LLM SDK or a prompt built from input.
     - Migration — `migrations/`, `*.sql`, `schema.prisma`, `drizzle/`, `alembic/`, `db/migrate/` or any equivalent; content: `ALTER TABLE`, `DROP COLUMN`, `RENAME COLUMN`.
     - Dependencies — the row must name at least `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`, `Cargo.lock`, `poetry.lock`, `uv.lock`, `go.sum` "or any other lockfile", plus a manifest whose dependency list changed (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`).
     - Performance — server-side code: routes, handlers, services, repositories, jobs, queries; content: a query or call inside a loop, an `await` inside a loop, a read with no limit.
   - Under the table, three rules: a lens with no trigger in the diff does not run, and its absence is not a finding; a lens looks at the diff, never at the rest of the repository; each lens run is recorded on the `Lenses run:` line of the report with the path or content that triggered it, or `none`.
   - `## Grading` — must contain the phrase `No scale of its own` and say: each lens finding is graded on the severity scale of `review-antihallu`, written under `## Findings` like any other, and the review keeps its single pair of verdict lines; the grades named below are where that scale already places those defects. No line of this file starts with `Max severity:` or `Ship allowed:`.
   - `## Security` — one bullet per item of the criterion: authorization checked per resource (the record belongs to the caller or its tenant), not only per route; outbound call to a URL a user supplied (allow-list, no internal addresses); upload (type, size, storage outside the served root); webhook signature verified on the raw body before any effect; rate limit held by a shared store, not process memory; error messages that reveal no stack, query or existence of another user's data; LLM call — model output treated as data, never executed or rendered unescaped, no secret or other user's data in the prompt. Pinned sentence, verbatim: `**A missing authorization check is critical.**` Other security findings: graded by the scale (an exploitable flaw is critical).
   - `## Migration` — pinned sentence, verbatim: `**Renaming or dropping a column in place is major.**` Ask for the expand/contract steps (add, backfill, switch readers, remove later) — the words `expand` and `contract` both appear — and for the rollback: how the migration is undone and whether data survives it (the word `rollback` appears). A migration with no rollback path in the plan is a finding.
   - `## Dependencies` — must contain `one dependency per change`, `changelog`, `install scripts` and `reason in the plan`. The reviewer checks that the plan names each added or upgraded dependency and why, that the changelog between versions was read, and that install scripts were read (an npm lockfile marks them `"hasInstallScript": true`). A dependency the plan does not name is a finding.
   - `## Performance` — bullets: N+1 (a query per item of a list), unbounded read, missing pagination, avoidable sequential calls (independent awaits in a row). Pinned: the bolded phrase `**potential impact**`, and the sentence `Never put a number on it` (no latency, no query count, no load figure: a static reading measures nothing).
   Test that fails if wrong: all six tests of task 5.
2. [x] **The reviewer preloads it** — `method/agents/reviewer.md`: add `  - review-lenses` to `skills:` (`:6-9`), after `review-antihallu`. After the sentence of `:15` (kept verbatim, pinned by `tests/ownership.test.sh:45`), add one sentence: the lenses that run after the six steps, and the diff paths that trigger each, are the preloaded `review-lenses` skill; they widen what you look for and add no verdict line. Tools unchanged (no Write).
   Test that fails if wrong: `test_one_reviewer_one_verdict`.
3. [x] **The procedure points to them** — `method/skills/review-antihallu/SKILL.md`: a new section between step 6 (`:45`) and `## Severity` (`:47`), heading exactly `## After the six steps: the lenses`, 2-4 lines: run each lens of the preloaded `review-lenses` skill whose trigger the diff contains; grade its findings on the scale below; record them on `Lenses run:`. Not numbered: `tests/review.test.sh:29` counts six `**N. ` lines. Change nothing else in the file.
   Test that fails if wrong: `test_one_reviewer_one_verdict` (checks the heading sits after `**6. ` and before `## Severity`).
4. [x] **The report records them** — `method/templates/review.md`: a section `## Lenses` between `## Neighbours` (`:45-46`) and `## Findings` (`:48`), holding exactly one line starting `Lenses run:`, e.g. `Lenses run: <security | migration | dependencies | performance — each with the path or content that triggered it | none>`, plus a box `- [ ] Each lens finding graded on the scale above and listed under Findings`. The last two non-blank lines stay `Max severity:` then `Ship allowed:`.
   Test that fails if wrong: `test_lenses_are_triggered_by_the_diff`, `test_one_reviewer_one_verdict`; existing `tests/review.test.sh:21-25` keeps the verdict order.
5. [x] **The tests** — create `tests/review-lenses.test.sh` (header comment `# s53 — review lenses triggered by the diff.`), variables `SKILL="$METHOD/skills/review-lenses/SKILL.md"`, `AGENT`, `ANTIHALLU`, `TPL`; a local `section_of` (copy of `tests/ownership.test.sh:10`) and `holds` (`:12`). One function per criterion, same names:
   - `test_lenses_are_triggered_by_the_diff` — `require_file "$SKILL"`; `section_of "$SKILL" 'Which lenses run'` holds `git diff --name-only <Target branch>...story/<id>` and has the four rows `| Security |`, `| Migration |`, `| Dependencies |`, `| Performance |` (a line starting `| <Lens> |`, matched with a fixed-string prefix); `$TPL` has exactly one line matching `^Lenses run:`, and that line comes before the `^Max severity:` line.
   - `test_security_lens_rates_a_missing_authz_check_critical` — `section_of "$SKILL" Security` holds `**A missing authorization check is critical.**`, `authorization`, `URL`, `upload`, `webhook`, `signature`, `rate limit`, `shared store`, `error message`, `LLM`.
   - `test_migration_lens_rejects_in_place_renames` — `section_of "$SKILL" Migration` holds `**Renaming or dropping a column in place is major.**`, `expand`, `contract`, `rollback`.
   - `test_dependency_lens_triggers_on_a_lockfile` — the `| Dependencies |` row holds `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `Cargo.lock`, `go.sum`; `section_of "$SKILL" Dependencies` holds `one dependency per change`, `changelog`, `install scripts`, `reason in the plan`.
   - `test_performance_lens_never_invents_numbers` — `section_of "$SKILL" Performance` holds `N+1`, `unbounded`, `pagination`, `sequential`, `**potential impact**`, `Never put a number on it`.
   - `test_one_reviewer_one_verdict` — reviewer frontmatter has `  - review-lenses` (`grep -qx`); no other `method/agents/*.md` preloads it; `lacks_tool "$AGENT" Write`; `section_of "$SKILL" Grading` holds `No scale of its own` and `review-antihallu`; `$SKILL` has no line matching `^(Max severity|Ship allowed):`; `$TPL` has exactly one `^Max severity:` and one `^Ship allowed:` line; in `$ANTIHALLU` the line of `## After the six steps: the lenses` is after the line of `^\*\*6\. ` and before `## Severity`, and that section names `review-lenses`.
   Run: `bash tests/run.sh review-lenses.test.sh review.test.sh ownership.test.sh qa-gate.test.sh floor-guard.test.sh`.
6. [x] **Whole checks** — `bin/po-lint` (no breach), then the full suite `bash tests/run.sh` once (`Full suite: execute-end`); `Typecheck: —`, say the project has none. Copy check per `docs/references/gstack-agent-skills.md:6`: `python3 bin/ks-overlap /home/lecrabe/.claude/jobs/aacccb17/tmp/gstack-src/repo/gstack 8`, and rewrite any `method/skills/review-lenses/` line it reports. No local agent-skills copy exists: write that under "Not proven here" in `docs/verif/s53-review-lenses.md` rather than claiming the check ran.
   Test that fails if wrong: the full suite; `tests/lint.test.sh` and `bin/po-lint` for frontmatter tools.

## Run interdicts
- Empty diff for every path outside `Owns` and `docs/`: notably `method/commands/po-review.md`, `method/hooks/`, `method/AGENTS.md`, `bin/`, `.claude/`, `.polype/`, and every existing `tests/*.test.sh` (none of them needs to change; if one fails, fix the method file, not the test).
- `method/skills/review-antihallu/SKILL.md`: the diff is one added section between step 6 and `## Severity`; no existing line changed or removed; still six `**N. ` lines.
- `method/agents/reviewer.md`: no change to `tools:`, `Reads settings:` (no new setting), the verdict lines or `## Limits`; `:15`'s sentence kept verbatim.
- `method/templates/review.md`: no section removed or reordered; the verdict pair stays last and single.
- No new subagent file, no new setting in `method/templates/agents-local.md`, no new severity word (only critical, major, minor).
- No checklist pasted from gstack `review/specialists/` or agent-skills `references/*-checklist.md`; each lens 5-8 bullets.
- Do not write `docs/research/s53-review-lenses.md` or `docs/decisions/ADR-0030-…` again; they are settled (commit them with the code).

## The pivot
Lenses are a **preloaded skill applied after step 6 by the same reviewer, triggered by its own reading of the diff** (ADR-0030). Ways it could be wrong:
- A lens silently never runs because the reviewer misreads a path. Compare: the trigger table must name concrete paths and contents, and the report's `Lenses run:` line makes a missed lens visible; s55 will measure it.
- A lens grade drifts into a second scale (e.g. "lens-critical", a separate verdict or score). Compare: `## Grading` defers to `review-antihallu`'s scale; the template keeps one verdict pair; `test_one_reviewer_one_verdict`.
- The lists grow into copied checklists. Compare: line count (60-90) and `bin/ks-overlap` against gstack.

## Files touched
- `method/skills/review-lenses/SKILL.md` (new)
- `method/agents/reviewer.md`
- `method/skills/review-antihallu/SKILL.md`
- `method/templates/review.md`
- `tests/review-lenses.test.sh` (new)
- Evidence on the branch: `docs/research/s53-review-lenses.md`, `docs/plans/s53-review-lenses.md`, `docs/verif/s53-review-lenses.md`, `docs/decisions/ADR-0030-lentilles-de-revue-prechargees-dans-le-reviewer.md`.

## Test strategy
Six automated tests, one per criterion, all in `tests/review-lenses.test.sh`, within `Test budget: 25`. They check the method text, the only layer this repository has (`AGENTS.local.md` Conventions: tests quote short exact phrases of the file under test). Each pins a phrase whose removal would remove the rule: deleting the authz sentence, the in-place-rename sentence, the lockfile names, `**potential impact**`, the `Lenses run:` line or the preload line turns its test red. No test is added to `tests/review.test.sh` or `tests/ownership.test.sh`: their existing assertions already guard the six steps, the verdict order and the pinned reviewer sentences this story must not break. No visual check: no screen. Whether a real reviewer applies the lenses is behaviour, left to s55's evals.

## Done when
- One commit on `story/s53-review-lenses` holding the five files above and the evidence, `docs/verif/s53-review-lenses.md` complete with the tree, `bin/po-lint` clean, full suite green.
- A review with no open critical finding, then the squash on `main` (`Merge mode: local`). Installed copies (`.claude/`, `.polype/`) are refreshed by a separate commit after ship, as for s52 (`fc15bdc`).
