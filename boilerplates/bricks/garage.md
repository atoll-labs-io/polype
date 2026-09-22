# Brick — Garage (Files)

- Capability: Files
- Default brick (ADR-0020): the S3 API served by self-hosted Garage
- Status: documentation only — this note describes a deployment and its contracts; it ships no code.

## What it provides

Object storage behind the S3 API: the application uploads, reads, lists and deletes objects by key in a bucket, and hands out signed links for downloads that must not go through the application. Any S3 client library works against it, so switching to a host's S3 later is a change of settings, not of code.

## How it runs at mustelinet

- On one or more VMs, each with a block volume holding Garage's data; or on the managed Kubernetes, whose documentation is not published yet (`not documented — ask the host`).
- The application talks to Garage's S3 endpoint on the private network.
- A public download through a signed link needs an HTTPS endpoint behind the edge: the edge routes by SNI, so the service (or a reverse proxy in front of it) presents its own certificate for `<vm_id>.<project_id>.apps.mustelinet.com`.
- Ports, replication factor and layout: follow the Garage documentation; this note fixes none.

## Settings

- `S3_ENDPOINT` — the S3 URL of Garage on the private network (or its public HTTPS name for signed links).
- `S3_BUCKET` — the bucket the application uses.
- `S3_ACCESS_KEY_ID` and `S3_SECRET_ACCESS_KEY` — the key Garage issued for that bucket.
- `garage.toml` — Garage's own configuration file on each node.

These are the brick's settings, read by the deployed application and by Garage; they are not `AGENTS.local.md` settings.

## Backups

- What: the buckets, plus `garage.toml` and the keys (the latter kept in the project's secret store, never in git).
- How: replication across Garage nodes is not a backup — a deletion replicates too. Copy the buckets on a schedule to another volume or another site with any S3 client.
- Restore: copy a bucket back into an empty Garage and read a known object byte for byte.
- Volume snapshots and an off-site target outside mustelinet: `not documented — ask the host`.

## What mustelinet does not provide

- No managed database — so Garage keeps its metadata on its own volume, and nothing here depends on a host database.
- No managed object storage — so we run Garage ourselves, and its availability and its backups are ours.
- Publication over HTTP and HTTPS only — so the S3 endpoint is public only as HTTPS through the edge, with Garage or its proxy presenting its own certificate; everything else stays on the private network.
- Custom domains — `not documented — ask the host`; signed links use the `apps.mustelinet.com` name until answered.

## Contract test checklist

Every brick of this capability must pass these; the list adds mustelinet's constraints to the contract of the capability-bricks skill.

- [ ] Nominal: an uploaded object is read back byte for byte.
- [ ] Refusal: reading without the right, or through an expired signed link, is refused.
- [ ] Data effect: the object is listed under its key and gone after deletion.
- [ ] Mustelinet: a signed link works through `<vm_id>.<project_id>.apps.mustelinet.com` over HTTPS, with the certificate presented by the service.
