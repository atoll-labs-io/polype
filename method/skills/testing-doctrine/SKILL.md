---
name: testing-doctrine
description: What to test, at which layer, how much, and when each check runs. Preloaded in the implementer and the reviewer; the planner reads it for the test strategy.
---
# Testing doctrine

Only the agent that writes tests and the agent that judges them act on these rules, so they live here rather than in `AGENTS.md`, which every context pays to load.

## Budget

`Test budget` tests per story (25 unless the project says otherwise). A plan that needs more explains why in its test strategy.

Volume is not safety. Suites grow by dozens of tests per story while the one invariant the story turns on ships with nothing guarding it; that gap has been found by mutation in review, never by counting. A large suite also gets slow, and a slow suite stops being run.

**The criterion that replaces the count: a test that stays green when the rule it names is deleted is worse than no test — it hides the hole it claims to cover.**

## Where each test belongs

| Layer | Test here |
| --- | --- |
| Service and its policy | What matters. **The permission matrix is tested once, in the policy test.** A service never invents access rules — it calls the policy — so its tests cover the business rule: one nominal case and one refusal per rule it owns. |
| Persistence | Only what reading the code does not catch: the ordering that makes a retried mutation idempotent, and the tenant or ownership clause of each query. Call the repository **directly**: the service refuses upstream, so a call through it never reaches the clause. |
| Adapter (route, server action, controller) | Only what the service does not do: parsing the payload, clearing fields, mapping errors to statuses. It checks once that a refusal becomes a 403 — never per role, never per rule. |
| Component | Almost nothing: only conditional logic the component owns. Rendering a list is not a rule. |
| End to end | One scenario, for what unit tests cannot see — typically a side effect written inside a transaction that mocked repositories hide. |

## Four cuts

1. **The matrix once, in the policy test.** Replayed per command, a single service test file passes fifty tests and proves nothing more.
2. **No enum exhaustiveness.** The legal transitions plus one representative refusal say everything every ordered pair would.
3. **One rule, one layer.** Test it where it lives, never again in a caller.
4. **No adapter re-asserting a 403** the policy already owns.

## No red-first during implementation

Do not write a test to watch it fail, and do not neutralize your own guard to see a test turn red. Write the code in whole blocks, write the tests that belong to it, run them. The author who just wrote a test knows it passes; repeating the ritual costs a suite run each time and has found nothing. **Neutralization belongs to the review**, run by a fresh context on someone else's net — that is where it finds untested invariants (ADR-0012).

## Six ways a test names a rule without exercising it

Hard to see by reading assertions alone; check for each one:

1. The test writes its own query instead of calling the code under test — it tests the database, not the repository.
2. The test sends a payload the real interface never produces.
3. A `catch` swallows the failure, so the assertion passes when nothing throws.
4. An end-to-end test stays green while rendering zero rows.
5. A **fixture** whose identifiers let a later guard answer in place of the guard under test.
6. A **mock** that replays the clause it should evaluate.

## When each check runs — once, and once only

A deterministic command run again on the same code gives the same answer at the same cost. Each check therefore has exactly one stage.

| Check | When | Setting |
| --- | --- | --- |
| Focused suite | After each task, on that task's own test files — never the whole project | — |
| Full suite | Once, after the last task | `Full suite` |
| Type check | Once, after the last edit, **always**: most test runners transpile without type checking and most linters do not type, so a type error in a test file passes everything but CI | — |
| End to end | Once, at ship, right before the merge — it costs a cold start, migrations, a seed and a browser | `E2E stage` · `E2E scope` · `E2E browsers` |
| Production build | At ship, only when a route or a manifest moved — the one break a type check cannot see | `Build stage` |
| Formatting | Only on the staged files, at the commit | — |

The reviewer's neutralizations run only the test files that name the invariant, never the suite: a neutralized guard turns red where it is tested, and replaying the whole project to learn that is the most expensive habit a review can have.
