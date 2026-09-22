---
name: capability-bricks
description: The default brick of each capability, its alternatives and when to switch, the two editions a product ships in, and what a contract test proves of any brick. Read by /po-architect and by whoever writes a boilerplate profile.
---
# Capabilities and their bricks

A capability is an interface the application codes against; a brick is one implementation of it. Each default is picked self-hostable first, so the edition users run on their own servers needs no account with any third party. The table below comes from Polype's ADR-0020 and is complete here: a project that does not carry that ADR reads it from this file.

## Default bricks

| Capability | Default brick | Alternatives | Switch when |
| --- | --- | --- | --- |
| Database | Self-hosted PostgreSQL, migrations versioned by the profile's ORM | Managed Postgres from the host | The host runs Postgres for you and the project accepts depending on that host. |
| Auth | Better Auth, sessions and accounts kept in our own database | Clerk, or the auth the profile ships | The profile already ships its auth, or the project accepts an identity provider it does not run. |
| Authorization | Application policies, the access matrix tested once | — | Never: the rule stays in the application whatever the host. |
| Multi-tenancy | Organisations stored in the database, tenant filter checked at the repository | — | Never: the rule stays in the application whatever the host. |
| Files | S3 API served by self-hosted Garage | The host's S3, Vercel Blob | The host provides object storage and the project accepts depending on it. |
| Jobs | Queue inside Postgres: pg-boss or the profile's equivalent | Inngest, Trigger.dev | The host or the volume of jobs justifies a managed runner and the project accepts depending on it. |
| Email | SMTP through a relay of the project's choice | Resend or an equivalent | The project prefers a managed sending API over running or renting an SMTP relay. |
| Payment | Stripe for the managed offer; the self-hosted edition has no payment brick | A Merchant of Record: Polar, Lemon Squeezy | B2C VAT across countries makes it worth handing tax collection to a Merchant of Record. |
| Cache and rate limiting | Postgres, or self-hosted Valkey once the load requires it | Upstash | The load outgrows Postgres and the host offers a managed store the project accepts. |
| Observability | OpenTelemetry sent to a self-hosted collector | Sentry | The project accepts a managed error tracker instead of operating its own collector. |
| i18n | The library of the profile's framework | — | Never: the rule stays in the application whatever the host. |
| Deployment | A container image; mustelinet on managed Kubernetes or a VM | The platform of the chosen host | The product is hosted somewhere else than mustelinet. |

Switching to an alternative changes configuration behind the capability's interface; application code is never rewritten for it (ADR-0009). Every switch is recorded as a project ADR.

## Two editions

The self-hosted edition is built without any payment brick. The managed offer carries subscription and usage billing. The first runs on its users' own servers, so no paid service may stand between them and a working product; the second bills by usage too, which is why it needs usage meters on top of subscriptions.

## Contract tests

A contract test is written against the capability, never against one brick: every brick that implements it must pass the same tests. Each row below says what those tests prove, whichever brick answers.

| Capability | Nominal behaviour | Expected refusal | Observable data effect |
| --- | --- | --- | --- |
| Database | A migration applies on an empty database and a write then a read return the same row. | A write breaking a constraint (unique, foreign key, not null) is rejected. | The row is present after a new connection is opened. |
| Auth | Sign-up then sign-in yields a session that identifies the account. | Wrong credentials or an expired session are refused. | The account and its session exist in storage; signing out removes the session. |
| Authorization | An allowed role performs the action. | A role outside the matrix gets a refusal and nothing happens. | Nothing is written when the action is refused. |
| Multi-tenancy | A member reads the records of their own organisation. | A read or write aimed at another organisation's record is refused or finds nothing. | Every row written carries the tenant of the caller. |
| Files | An uploaded object is read back byte for byte. | Reading without the right, or through an expired signed link, is refused. | The object is listed under its key and gone after deletion. |
| Jobs | An enqueued job runs once and reports success. | A failing job is retried up to its limit, then marked failed. | The job's state (done, retried, failed) is recorded and readable. |
| Email | A message sent is accepted for delivery. | An invalid recipient address is rejected before sending. | A test SMTP server captures the message with its recipient and subject. |
| Payment | A checkout for a plan ends in an active subscription. | A declined payment or an unverified webhook changes nothing. | The subscription state and the usage meter are recorded for the account. |
| Cache and rate limiting | A stored value is read back until it expires. | A caller over the limit is refused until the window resets. | The counter of the window is incremented per call. |
| Observability | A request emits a trace and an error is recorded with its context. | An unreachable collector never fails the user's request: the telemetry is dropped, the request succeeds. | The span or error arrives at a test collector. |
| i18n | Each supported locale renders its own text. | A missing key in a supported locale fails the check instead of rendering the key. | The locale chosen by the user is stored and applied on the next request. |
| Deployment | The image starts and answers its health check. | The image refuses to start when a required setting is missing. | Migrations have run and the health check reports the version deployed. |
