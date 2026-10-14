# Review — s41-capability-bricks

[Story](../stories.md) · [Plan](../plans/s41-capability-bricks.md) · [Verification](../verif/s41-capability-bricks.md)

Diff reviewed: `git diff m4-catalogue...story/s41-capability-bricks` (one commit, eb8d0a8). I did not write this code. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## Ownership
I listed the changed paths with `git diff --name-only m4-catalogue...story/s41-capability-bricks` and checked each one against the story's `Owns` line: `method/skills/capability-bricks/`, `method/commands/po-architect.md`, `tests/capability-bricks.test.sh`, `docs/catalogue.md`.
- [x] Every path is inside `Owns`. The three `docs/{research,plans,verif}/s41-capability-bricks.md` files are the story's own evidence, so they are in scope by definition.
- [x] No path is outside `Owns`.
- [x] No path falls inside another running story's `Owns`.
- [x] The story has an `Owns` line (`docs/stories.md:616`).

## Evidence reused
- [x] `po-gate verif-current s41-capability-bricks` exits 0. `git diff --quiet 93b9127 HEAD -- . ':(exclude)docs'` exits 0, so the record's `Tree:` matches the committed code. The record is marked complete and every exit code in it is 0: focused tests 10 passed, full `bash tests/run.sh` 218 passed (including `overlap.test.sh` against the Killer SaaS sources), `bin/po-lint` clean. With `Verification mode: record`, I reused these results and did not rerun the suite. The project has no type check, end-to-end or build command (`—`), and I did not substitute one.

## Plan
- [x] Tasks 1–6 are all present and match the plan: skill sections and their order, exact table headers, twelve rows in the profile-template order, the verbatim sentences, the Step 3 paragraph, the four tests, the French catalogue section. Nothing appears that the plan did not ask for.
- [x] I checked each run interdict:
  - The diff does not touch `docs/parite-killer-saas.md`, `method/AGENTS.md`, `po-help.md`, `po-setup.md`, `method/templates/*`, `bin/*`, existing tests or `docs/decisions/*`.
  - Nothing under `.claude/`, `.polype/` or `boilerplates/`.
  - `po-architect.md` has one hunk, inside `## Step 3`; the frontmatter and the `Reads settings` line are unchanged.
  - No new setting and no ADR file.
  - The skill is in English and the catalogue section is in French.

## References
- [x] I opened every target:
  - The `method/templates/profile.md` Capabilities table has the same twelve names in the same order.
  - `codebase-analysis` has the same frontmatter shape.
  - The `## Never rewrite the base` section exists at `po-architect.md:59`.
  - `section_of` is identical to the one in `tests/architect.test.sh:8`.
  - `$METHOD`, `require_file`, `contains` and `fail` exist in `tests/lib.sh`.
  - `bin/polype` installs `method/skills` as whole directories, so the new skill gets installed.
  - Referring to the skill by name in plain text follows the existing `codebase-analysis` pattern.
- [x] I compared the skill's default and alternative cells with ADR-0020 row by row, and they match, including "Clerk or the auth the profile ships" and Payment's Merchant of Record condition, which rests on B2C VAT. The "Switch when" cells go further than the ADR, which gives only a generic "when a host or the load justifies it" plus Payment's VAT condition. They are consistent with it, but no source confirms each cell word for word (see Not verified).

## Rules
- [x] `AGENTS.md` and `AGENTS.local.md` conventions are respected, except that the parity cell is not updated (minor finding below).
- [x] No accepted ADR is contradicted. ADR-0009 (configuration swap, project ADR), ADR-0011 (usage billing) and ADR-0020 (gap settled at architecture, brick by brick) are all consistent with the change.

## Tests
- [x] The assertions pin down all four acceptance criteria. None of the six empty test shapes appears: the tests read the real files, there is no mock or catch, and an empty table fails through the `*) fail` branch or the empty-cell check.
- [x] 4 tests, within the budget of 25.
- [x] Bite: I made five mutations, ran only `capability-bricks.test.sh` (plus `architect.test.sh` for the first), and undid each one. `git diff --exit-code` was clean after each, and `git status --porcelain` is empty at the end.
  - Removed "A gap is never settled in silence." from Step 3 → 1 failing test.
  - Changed the Payment default cell so the self-hosted edition uses Stripe → 1 failing test.
  - Set the Multi-tenancy contract refusal to `—` → 1 failing test.
  - Swapped the Files and Jobs rows → 1 failing test.
  - Changed the self-hosted edition sentence to "with a payment brick" → 1 failing test.
- [x] No existing test is made useless by this story. `architect.test.sh` stays green.

## Neighbours
- [x] I read the other users of the changed wording. `tests/architect.test.sh` stays green (in the record, and in my run of the first mutation). `method/templates/architecture.md:29` still says `<brick in use>` (minor finding below). Nothing is broken.

## Findings
- minor — `docs/parite-killer-saas.md:28` (B02) — The story carries `Matrice: B02 (volet briques)`, and `AGENTS.local.md` asks a story to update its parity status cells. The file is in s44's `Owns`, not s41's, so the implementer rightly left it alone. But s44's matrix list (C01, B03, C07) does not include B02, so no story owns the "briques" part of B02. This is a gap in `Owns`, not an implementer breach. A person should assign it.
- minor — `method/commands/po-architect.md:46` — A gap is defined only as "a capability whose profile brick differs from the skill's default". The sentence just before covers a base with no profile ("compare the brick the code of step 2 shows"), where that definition does not apply. "Profile brick" should read something like "the base's brick".
- minor — `method/templates/architecture.md:29` — The template column still says `<brick in use>`, while Step 3 now says "the brick retained". The template was interdicted for this story, so this terminology drift is left for a later cycle.
- minor — `tests/capability-bricks.test.sh:35` — `[ -n "$switch" ]` also accepts `—`. The test does not check the Deployment alternative, Trigger.dev or Lemon Squeezy. The anchor bricks that are checked still catch a rewritten row.

## Not verified
- **Whether an agent running `/po-architect` follows the new Step 3 paragraph**, meaning it actually compares bricks, keeps one per capability, and writes the gap into the capability's ADR. The tests check wording only, and no real profile exists before s42. A person should read the capability ADRs produced by the first `/po-architect` run on a real profile (next-forge, s42) and check that each gap names the profile brick, the default, the brick kept and the switch condition.
- **Whether each "Switch when" condition and each contract-test row is correct.** ADR-0020 does not spell these out; the implementer wrote them. I checked that they are consistent with ADR-0009, ADR-0011 and ADR-0020, not that they are right. The project owner should read them once, especially the Auth "profile ships its auth" condition and the Deployment refusal.
- **The overlap check against Killer SaaS (ADR-0006).** I relied on the record, which says `overlap.test.sh` ran against the sources at their default path. I did not confirm those sources exist on this machine.
- **The French prose in `docs/catalogue.md`.** It has no test, as planned; I read it and it matches the skill.

Max severity: minor
Ship allowed: yes
