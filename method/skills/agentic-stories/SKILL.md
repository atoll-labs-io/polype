---
name: agentic-stories
description: How to cut an approved PRD or brief into stories an agent can build without asking — vertical slices, declared ownership, contracts first, scored complexity, ordered dependencies, no graveyard feature. Used by /po-stories.
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
Every story declares Owns: the paths it is allowed to change, as files or directories. Agents run stories side by side, so two stories with no dependency between them never share a path; if they must, one depends on the other.

An interface shared by two stories becomes an earlier story of its own: the contract comes first. An API shape, a schema other stories read, an event format — it is written once, owned by that story, and every story that uses it lists it under `Depends on`.

This is the only story allowed to face no end user, and only under two conditions: the contract is observable — a test exercises it, or a real caller from the same story uses it — and at least two later stories depend on it. A table, an endpoint or a service with a single consumer is not a contract; it belongs inside the slice that uses it.

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
