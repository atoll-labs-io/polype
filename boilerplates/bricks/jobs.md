# Brick — pg-boss (Jobs)

- Capability: Jobs
- Default brick (ADR-0020): a queue inside Postgres, pg-boss or the profile's equivalent
- Status: documentation only — this note describes a deployment and its contracts; it ships no code.

## What it provides

Background work: the application enqueues a job, a worker runs it outside the request, retries it on failure up to a limit and records its state. The queue lives in tables of the Database brick, so it needs no broker of its own.

## How it runs at mustelinet

- Nothing extra to deploy but a worker process: the same application image started in worker mode, on its own VM or container next to the web process, or as a separate deployment on the managed Kubernetes (`not documented — ask the host`).
- The worker reaches PostgreSQL on the private network, exactly like the web process. It publishes nothing, so it needs no route through the edge.

## Settings

- `DATABASE_URL` — shared with the Database brick; the queue's tables live in that database.
- The concurrency of the worker and the retry limit and delay of each queue, set where the profile configures pg-boss or its equivalent.

These are the brick's settings, read by the deployed application; they are not `AGENTS.local.md` settings.

## Backups

- What: the queue's tables, which are part of the PostgreSQL database.
- How: covered by the Database brick's backup; nothing separate to schedule.
- Restore: restoring the database restores the queue; a job that was active at dump time may run again, so jobs are written to be safe to repeat.

## What mustelinet does not provide

- No managed database — so the queue sits in our self-hosted PostgreSQL, and its availability is that server's.
- No managed object storage — so a job that produces a file writes it to our Garage, never to a host bucket.
- Publication over HTTP and HTTPS only — so the worker exposes nothing; a scheduler or webhook that must reach it comes through the web process behind the edge.

## Contract test checklist

Every brick of this capability must pass these; the list adds mustelinet's constraints to the contract of the capability-bricks skill.

- [ ] Nominal: an enqueued job runs once and reports success.
- [ ] Refusal: a failing job is retried up to its limit, then marked failed.
- [ ] Data effect: the job's state (done, retried, failed) is recorded and readable.
- [ ] Mustelinet: jobs survive a restart of the worker VM or pod — a job enqueued before the restart runs after it.
