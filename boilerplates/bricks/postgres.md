# Brick — PostgreSQL (Database)

- Capability: Database
- Default brick (ADR-0020): self-hosted PostgreSQL, migrations versioned by the profile's ORM
- Example host: [mustelinet](../../docs/references/mustelinet.md)
- Status: documentation only — this note describes a deployment and its contracts; it ships no code.

## What it provides

A relational database the application reaches through its ORM: tables created and changed by the migrations the profile's ORM versions, constraints enforced by the server, transactions. The Jobs brick and, by default, the Cache brick live in the same server, so this is the one stateful service a prototype cannot do without.

## How it runs at the host

- On a VM (a Debian, Ubuntu or Alma image, for instance) with a block volume mounted as the PostgreSQL data directory, so the data outlives the VM; or as a StatefulSet on the host's managed Kubernetes when it offers one.
- Reachable only on the project's private network: a security group opens the PostgreSQL port to the application VMs or nodes and to nothing else. When the host's public edge routes HTTP and HTTPS only, so the database is never published.
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
- Volume snapshots of the block volume: ask the host. An off-site copy outside the host: ask the host.

## What the host may not provide

- No managed database, when the host has none — so we run PostgreSQL ourselves and own its upgrades, its monitoring and its backups.
- No managed object storage, when the host has none — so the dumps go to our own Garage on another VM, not to a host bucket.
- Publication over HTTP and HTTPS only, when the host's edge is limited to them — so the PostgreSQL port stays on the private network, and an administrator reaches it through the host's SSH access, never through the edge.
- Volume snapshots — ask the host; until answered, the dumps are the only backup.

## Contract test checklist

Every brick of this capability must pass these; the list adds the host's constraints to the contract of the capability-bricks skill.

- [ ] Nominal: a migration applies on an empty database and a write then a read return the same row.
- [ ] Refusal: a write breaking a constraint (unique, foreign key, not null) is rejected.
- [ ] Data effect: the row is present after a new connection is opened.
- [ ] Host: the database port is not reachable from the host's public edge, only from the private network.
- [ ] Host: a dump written to Garage restores into an empty server and the application answers its health check against it.
