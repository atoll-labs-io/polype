---
validated: yes
---
# Plan — s43-mustelinet-bricks

Branch `story/s43-mustelinet-bricks`. Read `docs/research/s43-mustelinet-bricks.md` first; this plan builds on it without repeating it.

Validated autonomously (`Plan validation: autonomous`): no human reviewed this plan.

## Story
A developer knows exactly what to deploy at mustelinet for each capability, so a prototype runs without any third-party account.
- `each_default_brick_has_a_note` — one note per ADR-0020 default brick deployable at mustelinet (Postgres, S3 storage, jobs, email, observability, deployment): what it provides, how it runs there, its settings, its backups.
- `notes_state_what_mustelinet_does_not_provide` — each note says what the host does not provide and what follows (no managed database or object storage, HTTP/HTTPS publication only).
- `notes_give_a_contract_test_checklist` — each note lists what a contract test must prove for the brick.
- `bricks_are_documentation_not_code` — no note claims to ship code; they describe deployment and contracts.

## Decisions settled here
| Question (research "Open questions") | Decision | Why |
| --- | --- | --- |
| Language | Notes in **English**; `docs/catalogue.md` section in French | `boilerplates/next-forge/profile.md` is English; `docs/` is French (AGENTS.local.md Conventions). |
| Layout | **Six files**, no index file in the folder: `postgres.md`, `garage.md`, `jobs.md`, `email.md`, `observability.md`, `deployment.md` | "une note par brique"; `docs/catalogue.md` is the index. |
| Undocumented host facts (outbound SMTP, volume snapshots, registry, Kubernetes docs) | Written as **"not documented — ask the host"**, never as facts | `docs/references/mustelinet.md:6,9,10`. |
| Code in notes | **No fenced code block** at all; env var names and file names in inline backticks only | A manifest in a fence reads as shipped code; the test can check it. |

## Tasks
1. [x] **Note shape.** Every note in `boilerplates/bricks/` follows exactly this shape, headings verbatim and in this order:
   - `# Brick — <brick> (<capability>)`
   - three list lines: `- Capability: <name>` — exactly a first cell of the `## Default bricks` table of `method/skills/capability-bricks/SKILL.md:9-24` (Database, Files, Jobs, Email, Observability, Deployment); `- Default brick (ADR-0020): <the skill's default cell, reworded if needed>`; `- Status: documentation only — this note describes a deployment and its contracts; it ships no code.`
   - `## What it provides` — what the application gets through the capability's interface.
   - `## How it runs at mustelinet` — VM or managed Kubernetes, volume, network exposure (private network vs the edge), per `docs/references/mustelinet.md:5-9`.
   - `## Settings` — the brick's environment variables / config files in inline backticks, with one sentence saying they are the brick's settings, **not** `AGENTS.local.md` settings.
   - `## Backups` — what to back up, where to, how to restore; any reliance on snapshots or on an off-site target is marked `not documented — ask the host`.
   - `## What mustelinet does not provide` — three bullets beginning verbatim `- No managed database`, `- No managed object storage`, `- Publication over HTTP and HTTPS only`, each continuing with ` — so ` and what it implies **for this brick**; further host gaps (outbound SMTP, registry, snapshots) as extra bullets.
   - `## Contract test checklist` — the sentence `Every brick of this capability must pass these; the list adds mustelinet's constraints to the contract of the capability-bricks skill.` then checkbox items `- [ ] Nominal: …`, `- [ ] Refusal: …`, `- [ ] Data effect: …` restating the skill's row for this capability (`SKILL.md:39-52`) without contradicting it, then at least one `- [ ] Mustelinet: …` item specific to the host.
   No fenced code block (no line starting with three backticks) anywhere in a note.
   Test able to fail: all four (task 3).
2. [x] **Write the six notes** with that shape. Content anchors, each grounded in the research; Garage/pg-boss/OTel details kept to what is certain, versions and ports pointing to the upstream docs:
   - `postgres.md` — Database, PostgreSQL on a VM with a block volume for its data directory, or a StatefulSet on managed Kubernetes; reachable only on the private network (TCP cannot go through the edge); migrations by the profile's ORM; settings `DATABASE_URL`; backups `pg_dump` (or WAL archiving) to Garage on another VM plus a restore rehearsal; snapshots `not documented — ask the host`. Mustelinet item: the database port is not reachable from the public edge.
   - `garage.md` — Files, Garage serving the S3 API; the app talks to it on the private network; a public download goes through signed links served by an HTTPS endpoint behind the edge, where the service presents its own certificate (SNI); settings `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `garage.toml`; backups: replication across nodes is not a backup — copy buckets to another volume or site. Mustelinet item: a signed link works through `<vm_id>.<project_id>.apps.mustelinet.com` over HTTPS.
   - `jobs.md` — Jobs, pg-boss (or the profile's equivalent) inside the same PostgreSQL: nothing extra to deploy but a worker process in the app image; settings: the `DATABASE_URL` it shares, concurrency and retry limits; backups: covered by the PostgreSQL backup. Mustelinet item: jobs survive a restart of the worker VM or pod.
   - `email.md` — Email, SMTP through a relay of the project's choice; outbound SMTP from mustelinet `not documented — ask the host`; until it is confirmed, a prototype sends to a capture server (Mailpit or equivalent) inside the private network; settings `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `MAIL_FROM`; backups: nothing to keep beyond the relay's credentials. Mustelinet item: a message reaches the relay from a mustelinet VM, or the note's question to the host is answered.
   - `observability.md` — Observability, OpenTelemetry collector on the private network, OTLP from the app; storage/UI backend is the project's choice (ADR-0020 settles the collector only); settings `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`; backups: telemetry is disposable, keep the collector config in git. Mustelinet item: an unreachable collector leaves the app answering through the edge.
   - `deployment.md` — Deployment, a container image run on a VM (container runtime) or on managed Kubernetes whose documentation is `not documented — ask the host`; publication through the edge on `<vm_id>.<project_id>.apps.mustelinet.com`, with the app presenting its own certificate (port 80 is routed, so an HTTP challenge is possible); custom domains `not documented — ask the host`; image registry not documented; settings: the image's required env vars, refusal to start when one is missing; backups: the image is rebuilt from git, only data bricks hold state. Mustelinet item: the health check answers over HTTPS through the edge.
   Test able to fail: `each_default_brick_has_a_note`, `notes_state_what_mustelinet_does_not_provide`, `notes_give_a_contract_test_checklist`.
3. [x] **Tests.** Create `tests/bricks.test.sh` (header `# s43 — mustelinet brick notes: one per deployable default brick, host gaps, contract checklists, no code.`). `BRICKS="$ROOT/boilerplates/bricks"`, `SKILL="$METHOD/skills/capability-bricks/SKILL.md"`, the list `NOTES="postgres garage jobs email observability deployment"` with their capabilities. Copy `section_of` from `tests/next-forge-profile.test.sh:7`. One helper `brick_note_breaches <file>` printing one line per breach of the shape of task 1 (missing heading, empty section, missing list line, capability not in the skill's table, missing verbatim bullet, missing checklist prefix, fenced block). Four functions:
   - `test_each_default_brick_has_a_note` — each of the six files exists, its `- Capability:` equals the expected name **and** that name is a first cell of the skill's `## Default bricks` table; the four sections What it provides / How it runs at mustelinet / Settings / Backups are non-empty; `postgres.md` Backups contains `pg_dump`; `docs/catalogue.md` names `boilerplates/bricks/`. Mutant: a copy of `postgres.md` without `## Backups` gets a breach from `brick_note_breaches`.
   - `test_notes_state_what_mustelinet_does_not_provide` — in every note, the section holds the three verbatim bullet starts, each followed by ` — so `. Mutant: the `- No managed object storage` line removed → a breach.
   - `test_notes_give_a_contract_test_checklist` — in every note, the checklist section has the intro sentence and at least one `- [ ] Nominal:`, `- [ ] Refusal:`, `- [ ] Data effect:` and `- [ ] Mustelinet:` item. Mutant: the `Refusal:` item removed → a breach.
   - `test_bricks_are_documentation_not_code` — `boilerplates/bricks/` holds only `*.md` files (no other file, no subfolder); every note has the `- Status: documentation only` line and no line starting with three backticks. Mutant: a fenced block appended → a breach.
   Mutants live in `mktemp -d` with an `EXIT` trap, as `tests/next-forge-profile.test.sh:70-77`. Run `bash tests/run.sh bricks.test.sh`.
4. [x] **Catalogue.** In `docs/catalogue.md` (French), add after `## Capacités et briques` a section `## Briques auto-hébergées chez mustelinet`, four to six lines: `boilerplates/bricks/` holds one note per default brick deployable at mustelinet (list the six files); each gives what the brick provides, how it runs there, its settings, its backups, what the host does not provide and a contract checklist; they are documentation, not code; undocumented host facts are questions for the host. No test beyond the `boilerplates/bricks/` mention of task 3.
5. [x] **Closing checks**, once: `bash tests/run.sh` (full suite, `Full suite: execute-end`) and `bin/po-lint` clean.

## Run interdicts
- Empty diff on everything under `method/`, `bin/`, `.claude/`, `.polype/`, `README.md`, `docs/parite-killer-saas.md`, `docs/stories.md`, `docs/decisions/*`, `docs/references/*`, `boilerplates/next-forge/`, and every existing `tests/*.test.sh`.
- `README.md` must not mention `boilerplates/` (`tests/distribution-wiring.test.sh:85`).
- No network access in the test; no file other than `.md` under `boilerplates/bricks/`; no `profile.md` there (po-lint would treat it as a profile).
- No note states an undocumented mustelinet capability (outbound SMTP, snapshots, registry, Kubernetes details, custom domains) as a fact.
- No new setting, no ADR.

## The pivot
**The notes add only what mustelinet changes to the skill's contract, and every host fact is traced to `docs/references/mustelinet.md` or marked `not documented — ask the host`.** How it could be wrong:
- A note invents a host capability — compare every host claim in `## How it runs at mustelinet`, `## Backups` and `## What mustelinet does not provide` with `docs/references/mustelinet.md:5-10`.
- A checklist diverges from the skill's contract row — compare `Nominal`/`Refusal`/`Data effect` items with `method/skills/capability-bricks/SKILL.md:39-52`.
- Six notes is the wrong cut (Cache/Valkey also deployable) — ADR-0020 makes Postgres the Cache default, Valkey only under load, and the story lists six; the reviewer checks the story list, not a wider one.

## Files touched
- `boilerplates/bricks/{postgres,garage,jobs,email,observability,deployment}.md` (new)
- `tests/bricks.test.sh` (new)
- `docs/catalogue.md`
- `docs/research/s43-mustelinet-bricks.md`, `docs/plans/s43-mustelinet-bricks.md`, `docs/verif/s43-mustelinet-bricks.md`

## Test strategy
Automated, 4 tests of 25, one per acceptance criterion, at the only layer there is: the documents. Each runs the real notes through `brick_note_breaches` and proves it bites on one mutant.
- `each_default_brick_has_a_note` — fails if a note is missing, names a capability absent from the skill, or leaves a descriptive section empty.
- `notes_state_what_mustelinet_does_not_provide` — fails if a note drops one of the three host gaps or its implication.
- `notes_give_a_contract_test_checklist` — fails if a note drops one of the four checklist kinds.
- `bricks_are_documentation_not_code` — fails on a non-markdown file, a fenced block or a missing status line.
Existing tests unchanged; `lint.test.sh`, `profile.test.sh`, `distribution-wiring.test.sh` must stay green. No visual check.

## Done when
- The four tests pass, the full suite passes and `bin/po-lint` reports no breach.
- One commit on `story/s43-mustelinet-bricks` by the implementer, with `docs/verif/s43-mustelinet-bricks.md`; a review with no open critical finding; squash-shipped to `m4-catalogue`.
