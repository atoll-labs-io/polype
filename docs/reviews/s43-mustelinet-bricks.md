# Review — s43-mustelinet-bricks

Diff reviewed: `git diff m4-catalogue...story/s43-mustelinet-bricks` (one commit, ec8184d), in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Ownership
I listed the changed paths with `git diff --name-only m4-catalogue...story/s43-mustelinet-bricks` and checked each one against `Owns`: `boilerplates/bricks/`, `tests/bricks.test.sh`, `docs/catalogue.md`.
- [x] Every path is inside `Owns`: the six notes under `boilerplates/bricks/`, `tests/bricks.test.sh` and `docs/catalogue.md`. The other three files are this story's own research, plan and verif record.
- [x] Nothing is outside `Owns`.
- [x] No overlap with another running story. `git worktree list` shows only this story's worktree. s44 owns `method/...`, `docs/parite-killer-saas.md` and `tests/catalogue-wiring.test.sh`, none of which this diff touches.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s43-mustelinet-bricks` exited 0. The record says `Verification status: complete` and holds tree 8fcbaa2d. Every exit code in it is 0:
  - task tests: 4 passed
  - full suite `bash tests/run.sh`: 226 passed, 0 failed
  - `bin/po-lint`: clean
- With `Verification mode: record`, that record counts as proof, so I did not rerun the suite. Type check, E2E and Build are `—`: the project has none of them. I read the record's "Not proven here" section and copied its points under Not verified below.

## Plan
- [x] Tasks 1 to 5 are all present, and nothing was changed outside the plan:
  - The note shape is exact: title, the three list lines, the six headings in order.
  - The three host-gap bullets start word for word as the plan requires, each followed by ` — so `.
  - Each checklist has its intro sentence and the four item kinds.
  - `docs/catalogue.md` has the new French section with 4 bullets.
- [x] I checked each run interdict:
  - The diff is empty for `method/`, `bin/`, `.claude/`, `.polype/`, `README.md`, the parity matrix, `docs/stories.md`, `docs/decisions/`, `docs/references/` and `boilerplates/next-forge/`.
  - No existing `tests/*.test.sh` changed.
  - `README.md` does not mention `boilerplates/`.
  - `boilerplates/bricks/` holds only `.md` files and no `profile.md`.
  - The tests do not use the network.
  - No note uses a fenced code block.
  - No new setting and no new ADR.
  - The notes state no undocumented host capability as a fact. SMTP, snapshots, registry, Kubernetes details and custom domains are each written as `not documented — ask the host`.

## References
- [x] I checked every host claim in the notes against `docs/references/mustelinet.md:5-10`. Each one is backed by that file:
  - OS images, block volumes, networks, security groups
  - managed Kubernetes created by Terraform, application credentials
  - edge on `<vm_id>.<project_id>.apps.mustelinet.com`, HTTP and HTTPS only, routing by SNI with the app's own certificate
  - SSH on `ssh.mustelinet.com:2222`
  - no arbitrary TCP
- [x] In every note, the `- Capability:` value is a first-column entry of `method/skills/capability-bricks/SKILL.md` `## Default bricks`. The Default brick lines match ADR-0020.
- [x] The Nominal, Refusal and Data effect items match the skill's contract table (`SKILL.md:39-52`) almost word for word, and none contradicts it.
- [x] The test's `section_of`, `contains`, `require_file` and `fail` helpers exist (`tests/lib.sh:43`) and match `tests/next-forge-profile.test.sh`.
- [ ] One inference goes beyond the reference file (see the finding on `deployment.md`).

## Rules
- [x] `AGENTS.md` and `AGENTS.local.md` conventions are followed: the notes are in English like the only other boilerplate file, and the catalogue section is in French.
- [x] No accepted ADR is contradicted. The six bricks are exactly ADR-0020's deployable defaults. Cache is left out because Postgres is its default, which the plan argues.

## Tests
- [x] There are 4 tests, one per acceptance criterion, each named after it. The assertions read the real notes, and each test also checks that it catches a deliberately broken copy. None of the six shapes of test that prove nothing applies.
- [x] 4 of the 25-test budget.
- [x] Bite: I broke one rule at a time, ran only `bash tests/run.sh bricks.test.sh`, then restored the file with `git checkout -- <file>`. `git diff --exit-code` was clean after each one, and the whole worktree was clean at the end.

| Change | Tests failing |
| --- | --- |
| `## Backups` of `observability.md` emptied | 1 (`each_default_brick_has_a_note`) |
| Code fence appended to `email.md` | 2 |
| `Refusal:` item removed from `jobs.md` | 2 |
| Capability in `garage.md` renamed to `Storage` | 1 |
| ` — so …` implication removed from the HTTP gap in `deployment.md` | 2 |
| A `x.yaml` file added to `boilerplates/bricks/` | 1 (`bricks_are_documentation_not_code`) |

- [x] The story makes no existing test obsolete.

## Neighbours
- [x] `bin/po-lint:226-228` only scans `boilerplates/*/profile.md` and skips a folder that has none, so `bricks/` does not break the lint; the record confirms lint is clean.
- [x] `tests/profile.test.sh` and `tests/next-forge-profile.test.sh` work on their own temporary copies or on `next-forge`, so the new folder does not affect them.
- [x] `po-architect.md:26`, `po-design-system.md:30` and `templates/profile.md:3` describe `boilerplates/<name>/profile.md`. See the first finding.

## Findings
- minor — `boilerplates/bricks/` — The folder sits in the namespace that `method/templates/profile.md:3` and `method/commands/po-architect.md:26` reserve for one boilerplate per `boilerplates/<name>/`. Anyone listing the boilerplates sees a "bricks" boilerplate with no profile. The lint does not complain only because it skips folders without `profile.md`. s44, which wires the catalogue, could name this folder as a special case, or a later story could move it.
- minor — `boilerplates/bricks/deployment.md` ("port 80 being routed, an HTTP challenge can obtain one") — The claim that ACME HTTP-01 works through the edge is an inference. `docs/references/mustelinet.md:7` only says port 80 is routed; it says nothing about certificate issuance. The plan asked for this wording, but it is the only host claim that is neither in the reference nor marked `not documented — ask the host`.
- minor — `boilerplates/bricks/jobs.md` (the `Mustelinet:` checklist item) — "Jobs survive a restart of the worker VM or pod" applies to any host. It adds no mustelinet-specific proof, which is what the checklist intro promises.
- minor — `tests/bricks.test.sh` — The Nominal, Refusal and Data effect items are only checked for being present, not for matching the skill's contract row. If `SKILL.md:39-52` changes later, the notes can drift from it without any test failing. They match today; I compared them by eye.

## Not verified
- **Facts about the tools.** The notes' statements about Garage, pg-boss, the OpenTelemetry Collector, PostgreSQL and Mailpit come from general knowledge, and no test or file in the repository checks them. A person who knows these tools should read the six notes once.
- **The `Mustelinet:` checklist items.** Nothing is deployed at mustelinet, so none of these items has been exercised, and the host-specific statements are only as good as a 2026-09-18 reading of the tenant docs. The first real deployment of a prototype should tick them off. The questions marked "ask the host" (outbound SMTP, snapshots, registry, Kubernetes docs, custom domains) should go to the host.
- **Full suite, lint and task tests.** I did not rerun them; I relied on the verif record, whose tree matches the commit. The record notes that the full-suite exit code was not echoed separately and was inferred from "0 failed"; I accepted that because `run.sh` ends on `[ "$failed" -eq 0 ]`.
- **Things the project does not have.** It has no type check, E2E or build, so none ran. There is no screen, so there was nothing to design-check.

Max severity: minor
Ship allowed: yes
