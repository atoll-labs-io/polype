# Brick — PostgreSQL (Database)

- Capability: Database
- Default brick (ADR-0020): self-hosted PostgreSQL, migrations versioned by the profile's ORM
- Status: documentation only — this note describes a deployment and its contracts; it ships no code.

## What it provides

A relational database the application reaches through its ORM: tables created and changed by the migrations the profile's ORM versions, constraints enforced by the server, transactions. The Jobs brick and, by default, the Cache brick live in the same server, so this is the one stateful service a prototype cannot do without.

## How it runs at mustelinet

- On a VM (a Debian, Ubuntu or Alma image, for instance) with a block volume mounted as the PostgreSQL data directory, so the data outlives the VM; or as a StatefulSet on the managed Kubernetes, whose documentation is not published yet (`not documented — ask the host`).
- Reachable only on the project's private network: a security group opens the PostgreSQL port to the application VMs or nodes and to nothing else. The public edge routes HTTP and HTTPS only, so the database is never published.
- Migrations run from the application image, with the profile's ORM, before the new version takes traffic.
- Version and tuning: follow the PostgreSQL documentation; this note fixes none.

## Settings

- `DATABASE_URL` — the connection string (host on the private network, port, database, user, password), handed to the application and to its migration step.
- The server's own `postgresql.conf` and `pg_hba.conf`, the latter accepting only the private network's addresses.

These are the brick's settings, read by the deployed application and the server; they are not `AGENTS.local.md` settings.

## Backups

- What: the whole database, which also holds the jobs and, by default, the cache.
- How: a scheduled `pg_dump` (or WAL archiving for point-in-time recovery), written to the Garage brick running on another VM so that losing the database VM does not lose its backups.
- Restore: rehearse it — load the latest dump into an empty server and run the application's health check against it.
- Volume snapshots of the block volume: `not documented — ask the host`. An off-site copy outside mustelinet: `not documented — ask the host`.

## What mustelinet does not provide

- No managed database — so we run PostgreSQL ourselves and own its upgrades, its monitoring and its backups; the tenant documentation lists none.
- No managed object storage — so the dumps go to our own Garage on another VM, not to a host bucket.
- Publication over HTTP and HTTPS only — so the PostgreSQL port stays on the private network, and an administrator reaches it through SSH (`ssh.mustelinet.com:2222`), never through the edge.
- Volume snapshots — `not documented — ask the host`; until answered, the dumps are the only backup.

## Contract test checklist

Every brick of this capability must pass these; the list adds mustelinet's constraints to the contract of the capability-bricks skill.

- [ ] Nominal: a migration applies on an empty database and a write then a read return the same row.
- [ ] Refusal: a write breaking a constraint (unique, foreign key, not null) is rejected.
- [ ] Data effect: the row is present after a new connection is opened.
- [ ] Mustelinet: the database port is not reachable from the public edge (`<vm_id>.<project_id>.apps.mustelinet.com`), only from the private network.
- [ ] Mustelinet: a dump written to Garage restores into an empty server and the application answers its health check against it.
