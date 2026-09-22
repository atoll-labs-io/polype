# Brick — container image (Deployment)

- Capability: Deployment
- Default brick (ADR-0020): a container image; mustelinet on managed Kubernetes or a VM
- Status: documentation only — this note describes a deployment and its contracts; it ships no code.

## What it provides

A running application reachable by its users: the image built from the repository starts, checks its settings, runs its migrations and answers a health check reporting the version deployed.

## How it runs at mustelinet

- On a VM running a container runtime, or on the managed Kubernetes created by Terraform from the tenant template. The Kubernetes section of the tenant documentation is not published yet: its details are `not documented — ask the host`.
- Publication goes through the public edge on `<vm_id>.<project_id>.apps.mustelinet.com`, over HTTP (port 80) and HTTPS (port 443) only. For HTTPS the edge routes by SNI, so the application (or its reverse proxy) presents its own certificate for that name; port 80 being routed, an HTTP challenge can obtain one.
- Custom domains: `not documented — ask the host`.
- Where the image is stored: an image registry at mustelinet is `not documented — ask the host`.
- Terraform and CI authenticate with OpenStack application credentials.

## Settings

- The environment variables the image requires — `DATABASE_URL`, the `S3_*`, `SMTP_*` and `OTEL_*` variables of the other bricks, and the profile's own. The image refuses to start when one of them is missing.
- The OpenStack application credentials used by Terraform and CI, kept in the CI's secret store.

These are the brick's settings, read by the deployed application and the deployment tooling; they are not `AGENTS.local.md` settings.

## Backups

- What: nothing in the image. It is rebuilt from git at the deployed commit; only the data bricks (PostgreSQL, Garage) hold state, and their notes cover their backups.
- The Terraform state, if kept locally, must be stored where it survives the machine that ran it.

## What mustelinet does not provide

- No managed database — so the application's database is our PostgreSQL brick, deployed beside it.
- No managed object storage — so its files go to our Garage brick, deployed beside it.
- Publication over HTTP and HTTPS only — so the application is reachable only through the edge on ports 80 and 443, presenting its own certificate; no other port is published.
- An image registry — `not documented — ask the host`; until answered, the image comes from a registry the project chooses.

## Contract test checklist

Every brick of this capability must pass these; the list adds mustelinet's constraints to the contract of the capability-bricks skill.

- [ ] Nominal: the image starts and answers its health check.
- [ ] Refusal: the image refuses to start when a required setting is missing.
- [ ] Data effect: migrations have run and the health check reports the version deployed.
- [ ] Mustelinet: the health check answers over HTTPS through the edge on `<vm_id>.<project_id>.apps.mustelinet.com`, with the certificate presented by the application.
