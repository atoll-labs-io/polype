# Research — s43-mustelinet-bricks

## Structuring facts
- The only source on mustelinet is `docs/references/mustelinet.md:1-11` (tenant doc read 2026-09-18): VMs, block volumes, networks, floating IPs, security groups, managed Kubernetes via Terraform; **no** managed database or object storage; publication on HTTP 80 / HTTPS 443 only, through an SNI-routing edge where the app presents its own certificate (`:7`); Kubernetes section of the doc unpublished, custom domains undocumented (`:9`); missing capabilities are asked for, not worked around (`:10`). Anything a note claims beyond these lines is an assumption and must be written as one.
- Outbound SMTP, volume snapshots and any off-site backup target are **not documented** anywhere in the repo. The story asks each note for "ses sauvegardes" and for email: the notes must say these are unverified and to be asked of the host, not state them as facts.
- Six notes, one per ADR-0020 default brick that is deployed rather than linked in (`docs/decisions/ADR-0020-briques-par-defaut-des-capacites.md:27-38`): Database (PostgreSQL), Files (Garage, S3 API), Jobs (pg-boss inside Postgres), Email (SMTP relay), Observability (OpenTelemetry collector), Deployment (container image on managed Kubernetes or a VM). Auth, Authorization, Multi-tenancy, i18n are libraries or app code; Payment has no brick in the self-hosted edition; Cache is Postgres by default (Valkey only under load) — none gets a note.
- `bin/po-lint` only scans `boilerplates/*/profile.md` (`bin/po-lint:226-228`): a `boilerplates/bricks/` folder without `profile.md` is invisible to the lint, so the notes need their own test.
- Contract-test content already exists per capability in `method/skills/capability-bricks/SKILL.md:39-52`; the notes must add the mustelinet-specific proofs on top of it, not restate a different contract.

## Story
A developer knows exactly what to deploy at mustelinet for each capability so that a prototype runs without any third-party account. Criteria:
- `each_default_brick_has_a_note` — one note per ADR-0020 default brick deployable at mustelinet (Postgres, S3 storage, jobs, email, observability, deployment): what it provides, how it runs there, its settings, its backups.
- `notes_state_what_mustelinet_does_not_provide` — each note says what the host does not provide and what follows (no managed DB or object storage, HTTP/HTTPS publication only).
- `notes_give_a_contract_test_checklist` — each note lists what a contract test must prove for the brick.
- `bricks_are_documentation_not_code` — no note claims to ship code; they describe deployment and contracts.

## Current code
- `boilerplates/` holds only `next-forge/profile.md` (English, headings `## Identity and licence`, `## Commands`…; `boilerplates/next-forge/profile.md:1-30`).
- `docs/catalogue.md` (French) has three sections: `## Le profil`, `## Capacités et briques`, `## Trois niveaux de boilerplate`. The bricks section points to the skill and `/po-architect`; nothing about deployment notes.
- `method/skills/capability-bricks/SKILL.md:9-24` — default bricks table (English), Deployment row names "mustelinet on managed Kubernetes or a VM" (`:24`); `:39-52` contract-test table: Nominal / Expected refusal / Observable data effect for each capability.
- `docs/conception.md:88-91` — prototypes at mustelinet, production at a large host later, which will bring managed bricks.
- `tests/` — one bash file per story, `test_<criterion>` functions, helpers in `tests/lib.sh` (`require_file`, `contains`, `fail`). `tests/next-forge-profile.test.sh:7` defines a local `section_of` awk helper worth copying (not shared in lib.sh).

## Attachment points
- New folder `boilerplates/bricks/` — six notes plus, optionally, a `README.md` index. File names are the plan's choice (e.g. `postgres.md`, `garage.md`, `jobs.md`, `email.md`, `observability.md`, `deployment.md`).
- `docs/catalogue.md` — a short French section pointing to `boilerplates/bricks/`, saying what a note holds and that it is mustelinet-scoped.
- `tests/bricks.test.sh` — new.

## Verified interfaces
- `bin/po-lint:191` `BOILERPLATES="$METHOD/../boilerplates"`, loop `for f in "$BOILERPLATES"/*/profile.md` (`:226`), `[ -f "$f" ] || continue` — a folder without `profile.md` is skipped, no error.
- `bin/ks-overlap:18` — overlap check scans `method/` only (`PO = …/"method"`); `boilerplates/` and `docs/` are outside it.
- `tests/run.sh:1-24` — runs each `test_*` in its own `bash -c "set -eu; …"`; an unset variable or failing command in a test body ends it.
- `tests/distribution-wiring.test.sh:85` — **fails if `README.md` mentions `boilerplates/`**. Not in this story's Owns, and the story does not need to touch `README.md`; do not mention the folder there.
- `docs/stories.md` s44 owns `method/AGENTS.md`, `po-setup.md`, `po-help.md`, parity matrix — this story touches none of them. `docs/catalogue.md` was owned by s40/s41, both shipped; no running story shares it.

## Traps
- Full suite runs at execute end (`Full suite: execute-end`): the new test must not depend on network or on any tool beyond bash/grep/awk.
- Tests must quote short exact phrases (`contains` is case-sensitive, `AGENTS.local.md` Conventions); a test only checking file existence would keep passing with empty notes — each criterion needs a mutant-style proof or per-note section checks.
- `bricks_are_documentation_not_code`: a test can check that the folder holds only `.md` files and that no note contains a fenced code block claiming to be a deliverable. Plain configuration examples (env var names) may be fine in inline backticks; fenced blocks of Kubernetes/compose manifests would read as shipped code. The plan must pick the rule and test it.
- Language: `boilerplates/next-forge/profile.md` is English, `docs/` is French (`AGENTS.local.md` Conventions: method in English, docs in French; `boilerplates/` not named). Consistency with the only other boilerplate file argues for English notes, French catalogue section.
- No parity-matrix line carries "ADR-0020 (volet mustelinet)" (`grep` on `docs/parite-killer-saas.md` finds no mustelinet row); B02/C07 status is s44's job. Nothing to update there.
- Settings named in notes (env vars like `DATABASE_URL`, `S3_ENDPOINT`) are brick settings, not `AGENTS.local.md` settings; the notes must not present them as Polype settings.
- Garage's S3 endpoint and the OTel collector's OTLP/HTTP receiver are HTTP services: reachable from outside only through the edge on 443 with the service presenting its own certificate; internal traffic stays on the private network. Postgres and SMTP are TCP and cannot be published at all (`docs/references/mustelinet.md:7`).
- Garage facts (S3-compatible, replication factor, `garage.toml`, admin API) come from general knowledge, not from a file in this repo; the notes should keep such details minimal and mark versions/ports as "check the Garage docs" rather than invent them.

## Open questions
- English or French for the notes? (Research leans English, see Traps.)
- One note per brick in six files, or one file with six sections? Criterion says "une note par brique" → six files reads most literally.
- How strong should the "backups" part be given snapshots are undocumented: state the plan (e.g. `pg_dump` to a volume and to Garage on another VM) as a recommendation plus the question to ask the host.
- Should a `README.md` index exist in `boilerplates/bricks/`? It would help discovery; `docs/catalogue.md` can serve the same purpose.

## Complexity
Story: 3 → after reading: 3. Pure documentation plus one test file, but six notes with four mandatory parts each, grounded in a thin host reference, and a test that must bite on each part.

## Split
Not needed.
