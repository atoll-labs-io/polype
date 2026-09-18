---
name: testing-doctrine
description: Polype's testing rules — how many tests a story gets, which layer each belongs to, which tests prove nothing, and at which stage every check runs. Preloaded in the implementer and the reviewer, read by the planner.
---
# Testing doctrine

These rules matter to three roles only — planner, implementer, reviewer — so they live in a skill instead of the rules file every agent loads.

## How many tests?

A story gets up to `Test budget` tests. Going beyond requires a sentence in the plan's test strategy.

The number of tests says nothing about safety. The recurring failure is a story that adds many tests while the single rule it depends on is covered by none of them; counting never reveals that, neutralizing the rule does. A bloated suite also runs slowly, and then people stop running it.

**One question replaces the count: if the rule this test names were deleted, would the test fail? A test that would still pass is worse than no test, because it makes the gap look covered.**

## Which layer?

| Layer | What belongs there |
| --- | --- |
| Service and policy | The heart of it. Access rules are checked once, in the tests of the policy that owns them. Services call the policy instead of re-implementing it, so their tests cover business rules: the normal case, and one refusal per rule the service owns. |
| Persistence | What reading the code cannot establish: how a retried write stays idempotent, and the tenant or owner filter of each query. Call the repository itself — through the service, the refusal happens earlier and the filter is never exercised. |
| Adapter (route, action, controller) | Its own job only: decoding input, dropping fields, turning errors into statuses. One test shows that a refusal becomes a 403; roles and rules are not replayed here. |
| Component | Rarely anything: only branching logic that lives in the component. Displaying data is not a rule. |
| End to end | One scenario for what isolated tests cannot see, typically a side effect inside a transaction that mocks would hide. |

## Four things to cut

1. Access rules tested again per command, when the policy test already covers them.
2. Every pair of an enum or a state machine: the allowed transitions and one representative refusal say it all.
3. The same rule tested in two layers: keep the layer where it lives.
4. Adapters checking a 403 the policy already guarantees.

## No red-first while implementing

Writing a test first to watch it fail, or disabling your own guard to see a test go red, costs a run each time and has not caught anything: a test is never more convincing to anyone than to its own author, minutes after writing it. Implement in whole blocks, add the tests that go with them, run them. Disabling guards on purpose is the reviewer's job, done in a separate context on code it did not write — that is where untested rules actually get found (ADR-0012).

## Tests that prove nothing

Each of these looks fine when you read the assertion; check for all six:

1. The test runs its own query rather than calling the code under test, so it exercises the database, not the repository.
2. The input is a payload the real caller can never send.
3. A `catch` absorbs the error, so the assertion passes even when nothing was thrown.
4. An end-to-end test passes while the page shows no rows at all.
5. A **fixture** carries identifiers that make a later check answer on behalf of the check under test.
6. A **mock** reproduces the condition it was supposed to evaluate.

## When does each check run?

Running a deterministic check twice on the same code buys nothing, so each has one stage.

| Check | Stage | Setting |
| --- | --- | --- |
| Tests of the current task | after that task, with only its test files | — |
| Full unit suite | a single time, when every task is done | `Full suite` |
| Type check | once, after the very last edit, never skipped — test runners often strip types without checking them and linters often ignore types, so only this catches a type error in a test file before CI does | — |
| End to end | once, at ship, just before merging — each run pays a cold start, migrations, seed data and a browser | `E2E stage` · `E2E scope` · `E2E browsers` |
| Production build | at ship, only if routing or a manifest changed, the one breakage a type check misses | `Build stage` |
| Formatting | on staged files, at commit time | — |

When the reviewer disables a guard, it reruns only the test files that mention that guard. Running the entire suite to find out which file turns red is the slowest possible way to learn it.
