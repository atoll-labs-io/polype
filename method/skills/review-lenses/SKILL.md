---
name: review-lenses
description: Four lenses — security, migration, dependencies, performance — that the reviewer turns on after the six steps whenever the diff touches their subject. Preloaded in the reviewer; nowhere else.
---
# Review lenses

A lens widens **where** you look; it never changes **how** you judge. The procedure, the scale and the verdict stay those of `review-antihallu`.

## Which lenses run

Take the list of changed paths the scope check already produced — `git diff --name-only <Target branch>...story/<id>` — and read the diff itself. A lens runs when either column of its row matches.

| Lens | Paths that trigger it | Content that triggers it |
| --- | --- | --- |
| Security | paths naming auth, session, permission or policy, middleware, routes, handlers or API, upload, webhook | a check on who may read or change a record; an HTTP call whose URL comes from input; multipart or file handling; a signature header; a rate limiter; a call to an LLM SDK or a prompt assembled from input |
| Migration | `migrations/`, `*.sql`, `schema.prisma`, `drizzle/`, `alembic/`, `db/migrate/`, or any equivalent | `ALTER TABLE`, `DROP COLUMN`, `RENAME COLUMN` |
| Dependencies | `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`, `Cargo.lock`, `poetry.lock`, `uv.lock`, `go.sum` or any other lockfile; a manifest whose dependency list changed (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`) | an added, removed or bumped dependency entry |
| Performance | server-side code: routes, handlers, services, repositories, jobs, queries | a query or call inside a loop; an `await` inside a loop; a read with no limit |

- A lens whose trigger is absent from the diff does not run, and not running it is not a finding.
- A lens looks at the diff only, never at the rest of the repository.
- Each lens that ran goes on the `Lenses run:` line of the report, with the path or content that set it off; when none ran, the line says `none`.

## Grading

No scale of its own. Every lens finding is graded on the severity scale of `review-antihallu` and written under `## Findings` beside the others; the review still ends with its single pair of verdict lines. The grades named below are only where that scale already puts those defects.

## Security

- Authorization is checked per resource — the record belongs to the caller or to its tenant — and not just per route.
- An outbound request to a URL a user supplied goes through an allow-list and can never reach an internal address.
- An upload has its type and size checked, and is stored outside the root the server publishes.
- A webhook has its signature verified on the raw body before anything happens.
- A rate limit lives in a shared store, not in the memory of one process.
- An error message shows no stack trace, no query, and does not reveal whether another user's data exists.
- An LLM call treats the model's output as data — never executed, never rendered unescaped — and its prompt carries no secret and no other user's data.

**A missing authorization check is critical.** Other security findings take their grade from the scale; a flaw someone can exploit is critical.

## Migration

**Renaming or dropping a column in place is major.** Ask for the expand and contract steps instead: add the new shape, backfill it, move readers and writers over, remove the old shape in a later change.

- The plan states the rollback: how the migration is undone, and whether the data survives the undo.
- A migration whose plan gives no rollback path is a finding.
- A backfill over a large table says how it is batched.

## Dependencies

- Keep to one dependency per change: a lockfile that moves many packages for one feature is a finding.
- The plan gives each added or upgraded dependency and its reason in the plan; a dependency the plan never names is a finding.
- The changelog between the old and new versions was read, and the record says so.
- The install scripts were read; an npm lockfile flags them with `"hasInstallScript": true`.
- A dependency that duplicates one already present, or what the standard library does, needs its reason too.

## Performance

- N+1: one query per item of a list that a single query could fetch.
- An unbounded read: a query or a fetch with no limit on what comes back.
- Missing pagination on a list that grows with use.
- Avoidable sequential calls: independent awaits made one after the other.

Mark each such finding **potential impact**. Never put a number on it — no latency, no query count, no load figure: reading code measures nothing.
