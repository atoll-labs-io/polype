---
name: agentic-stories
description: How to cut an approved PRD or brief into stories an agent can build without asking — vertical slices, declared ownership, contracts first, a declared surface, scored complexity, ordered dependencies, no graveyard feature. Used by /po-stories.
---

# Agentic stories

A story is read by agents that never saw the conversation behind it. Whatever a colleague would guess from context has to be on the page: what the user gains, what may change, what comes before, how it is checked.

## Vertical slices
A story delivers something a user can do from start to finish once it ships: open a screen, act, see the result stored and shown back. It crosses every layer it needs, thinly, rather than finishing one layer across the product.

Never a technical layer: "create the table", "add the endpoint" or "build the service" are not stories.

- Bad: "Create the orders table" — nobody can use it, no user can tell whether it works, and the next three stories all edit it.
- Good: "A customer places an order and sees it in their list" — it carries just the table, the route and the screen that this action needs, and a person can try it.

When a slice feels too thin to matter, it is usually the right size; when it needs "and then" twice in its title, it is two stories.

## Owns and contracts first
Every story declares Owns: the paths it is allowed to change, each in backticks and separated by commas. An entry is a file path, a folder ending in `/`, or a glob where `*` stays inside one path segment and `**` spans any number of segments; any other text on the line is refused. Agents run stories side by side, so two stories with no dependency between them never hold overlapping `Owns` entries, by the overlap rule of check 8 of the `stories-review` skill; if they must, one depends on the other.

An interface shared by two stories becomes an earlier story of its own: the contract comes first. An API shape, a schema other stories read, an event format — it is written once, owned by that story, and every story that uses it lists it under `Depends on`.

This is the only story allowed to face no end user, and only under two conditions: the contract is observable — a test exercises it, or a real caller from the same story uses it — and at least two later stories depend on it. A table, an endpoint or a service with a single consumer is not a contract; it belongs inside the slice that uses it.

## Surface
Every story declares one `Surface`: what a person checks once it ships, which tells design and QA what to look at (ADR-0054).

- `screen` — a page of a web app or a screen of a mobile app.
- `command` — a command line and what it prints.
- `endpoint` — an API request and its response, or a public call of a library.
- `scene` — a 3D or XR scene.
- `behaviour` — what a robot or an embedded system does.
- `—` — the story changes nothing a person sees or runs.

A story without the line keeps the old rule: it has a screen when its text shows one.

The surface must be one the project's `Platform` admits. This table is the only place that says which (ADR-0055):

| Surface | Admitted by the platforms |
| --- | --- |
| `screen` | `web`, `mobile` |
| `command` | `cli` |
| `endpoint` | `api`, `lib` |
| `scene` | `xr` |
| `behaviour` | `robot` |
| `—` | every platform |

A project declaring several platforms admits the surfaces of each: a web project that also serves an API declares `web, api`.

## Defect stories
Law 7 keeps defects out of `docs/stories.md` unless a person turns one into a story. Such a story carries a `Fixes` line (`Corrige` in a French stories file) naming the defect and where it is recorded. Its criteria state the wrong behaviour and the expected one. The line is optional and sends the story to the full track, researched under the `diagnostic` skill.

## Complexity and splitting
Score each story on the scale of `templates/stories.md`, from 1 (plain create, read, update, delete) to 5 (real time, migrations or external systems).

- A 4 names its main risk in its notes: which integration, which role rule, which payment case can go wrong.
- A 5 is split now, before the file is written — never left for the planner to discover.
- A story that would need more than about ten plan tasks is split too, whatever its score.

Split along what the user gets: the simplest usable path first, the variants and edge cases in later stories that depend on it.

## Dependency order
No story depends on a story placed after it. Foundations and contracts come first, then the core loop, then whatever extends it. Ids are numbered in file order, so the number of a dependency is always lower than the number of the story that needs it.

## Scope: core loop and graveyard
Every story traces back to its source. With a PRD, it serves a line of the core loop or the angle; with a brief, it serves the wedge or one of the premises. A story that points to none of them is out of scope and is dropped or raised with the user.

Nothing from the graveyard becomes a story, whether under its own name or under another one: a "simple export" that rebuilds a buried reporting module is still the buried module. Read each story against the graveyard list before keeping it.

In `replace` and `adapt`, the notes name the equivalent screen of the target when there is one, so the agent imitates a flow that already works instead of inventing one.

## Criteria and notes
- Each acceptance criterion is an observable result that one test can check: an input, an action, what the user or a caller sees. "Works well" or "is fast" are not criteria; "the list shows the new order first" is.
- A handful of criteria per story; past seven, the story is probably two.
- The notes tell the agent what it cannot infer: the files concerned, the constraints to respect, the pitfalls already known, the screen or flow to imitate.
- The id is `s<number>-<short-slug>` and never changes once written: branches and files carry it.
