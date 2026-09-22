# Profile — <boilerplate name>

A profile describes one boilerplate once, so that setup, architecture, planning and execution all read the same facts about it. It lives at `boilerplates/<name>/profile.md`. `bin/po-lint` checks it against this template: every `## ` heading below must be present, the command names must stay as they are, and each capability must come from the list in `## Capabilities`.

## Identity and licence

- Name: <boilerplate name>
- Origin: <URL of the repository the profile was written from>
- Licence: <SPDX identifier, e.g. MIT>
- Commit profiled: <full hash the facts below were read at>

## Commands

```
Install:           —
Test:              —
Typecheck:         —
E2E:               —
Build:             —
```

These names are the ones of the `## Commands` block of `AGENTS.local.md`, and the values are copied there verbatim. `—` means the boilerplate has no such command. A `Test` command must accept paths to test files.

## Code map

<One line per top-level directory: what lives there and which layer it belongs to. Name only directories that were opened.>

## Ownership granularity

<The smallest set of paths a story can own alone, e.g. `src/modules/<domain>/`, and the shared paths that make a story run on its own when it touches them, e.g. `src/core/`.>

## Where each rule lives

<For each kind of rule — access, business, validation, tenant filter — the file or directory that owns it, so a story adds it there and nowhere else.>

## Capabilities

| Capability | Brick | Notes |
| --- | --- | --- |
| Database | <brick> | |
| Auth | <brick> | |
| Authorization | <brick> | |
| Multi-tenancy | <brick> | |
| Files | <brick> | |
| Jobs | <brick> | |
| Email | <brick> | |
| Payment | <brick> | |
| Cache and rate limiting | <brick> | |
| Observability | <brick> | |
| i18n | <brick> | |
| Deployment | <brick> | |

A profile keeps only the rows the boilerplate actually provides. The names are fixed; a capability absent from this list is not declared here.

## UI inventory

<The components the boilerplate ships and where they are, so a design reuses them before drawing new ones.>

## Known traps

<What breaks for someone new to this boilerplate: a generated file not to edit, an order of commands, a setting that silently changes behaviour.>
