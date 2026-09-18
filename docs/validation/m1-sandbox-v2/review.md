# Review — s01-apply-coupon

Diff reviewed: `git diff main...story/s01-apply-coupon` (commit 8f530ac), by a reviewer that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s01-apply-coupon` passed (exit 0). Running `git diff --quiet 09013c1c… HEAD -- . ':(exclude)docs'` also exits 0. So the record matches the committed code, and I reused it: `node --test`, exit 0, 10 passed. Verification mode is `record`, so I did not rerun the full suite. The project has no type check (`Typecheck: —`), no lint command, no E2E command (`E2E: —`) and no build command (`Build: —`). I read the record's "Not proven here" section: it lists types, E2E, build, lint, and the guard checks it leaves to the review. I did those checks below.

## Plan
- [x] Every task is present:
  - Task 1 (`src/coupons.js` with its catalogue, `couponDiscount` and 6 tests) is done.
  - Task 2 (`total(items, { couponCode, now } = {})` with 2 tests) is done.
  - Task 3 (record and one commit) is done.
  - Nothing was added outside the plan.
- [x] Each run interdict checked:
  - `subtotal` is unchanged. Only the import moved it down two lines.
  - The two existing tests in `test/cart.test.js` are unchanged. The diff only adds lines.
  - `package.json` has an empty diff.
  - Every coupon test passes an explicit `now`. The `now = new Date()` default in `total` is only reached when a caller leaves `now` out.
  - No file outside `src/`, `test/` and `docs/` changed.
- [x] The decisions table is followed: the error shape is `Error` with a `.code` of `COUPON_UNKNOWN` or `COUPON_EXPIRED`, expiry is inclusive UTC through `Date.UTC(Y, M-1, D+1)`, codes match exactly, and the arithmetic is integer, multiplying before dividing.

## References
- [x] `import { couponDiscount } from './coupons.js'` resolves to `src/coupons.js:19` with signature `(code, subtotalCents, now)`. The call in `src/cart.js:12` passes the arguments in that order. `Object.hasOwn` works on Node v22.23.2 and also rejects inherited keys such as `toString`. `Date.UTC` rolls day 31 over to the next month correctly.
- [x] The catalogue matches the story's notes in `docs/stories.md`: WELCOME10 is 10 %, cap 500, expires 2099-12-31. SPRING20 is 20 %, cap 1000, expires 2025-06-30. The story leaves the expiry time zone and inclusivity open. The plan chose inclusive UTC, following the research, and the code does exactly that.

## Rules
- [x] The code follows the `AGENTS.md` and `AGENTS.local.md` conventions: ES modules, no dependencies, integer cents, tests in `test/*.test.js` using `node:test`.
- [x] No ADR was contradicted. `docs/decisions/` does not exist in this worktree, so there are no accepted ADRs to check against.

## Tests
- [x] Every assertion is tied to an acceptance criterion:
  - AC1: floor 3255 → 325, and the cart total 2925.
  - AC2: 9000 → 500.
  - AC3: COUPON_EXPIRED, plus the two tests on either side of the expiry boundary.
  - AC4: COUPON_UNKNOWN.

  None of the six "proves nothing" patterns appears. There are no mocks, no `catch` that swallows errors and no fixture interference. Every input is something a real caller could send.
- [x] There are 8 new tests, within the `Test budget` of 25.
- [x] Bite. I made each change in turn and ran only `node --test test/coupons.test.js test/cart.test.js`. After each run I restored the file and confirmed `git diff --exit-code src/` was clean.

  | Change | Tests failing (out of 10) |
  | --- | --- |
  | `Math.floor` → `Math.round` | 1 |
  | `day + 1` → `day` (expiry becomes exclusive) | 1 |
  | `>=` → `>` in the expiry comparison | 1 |
  | cap `Math.min` removed | 1 |
  | expiry guard disabled (`if (false)`) | 3 |
  | `total` ignores the coupon | 2 |

  At the end, `git diff --exit-code` over the whole worktree was clean and `git status --porcelain` was empty.
- [x] No test became useless because of the story.

## Neighbours
- [x] Outside the tests, `total` and `couponDiscount` have no callers. Search: `git grep` over `src/` and `test/`. `total(items)` without a coupon still returns the subtotal, and the existing test at `test/cart.test.js:14-16` confirms it. Nothing is broken.

## Findings
- minor — test/cart.test.js:26 — The second assertion, `total(items) === 3250`, is the same as the existing test at line 15. It would still pass if the coupon rule were removed. The "total unchanged" part of AC3 is really proven by the throw on line 25, so this line adds nothing.
- minor — src/cart.js:11 — Only `couponCode === undefined` counts as "no coupon". A future caller that passes `null` or `''` (for example an empty form field) gets `COUPON_UNKNOWN` instead of the subtotal. That is defensible, but the plan does not state it. There is no such caller today.

## Not verified
- The unknown-code guard (`src/coupons.js:20`) was not tested by mutation. My reasoning: without the guard, `COUPONS['NOPE10']` is undefined and the code throws a TypeError with no `.code`, so the `{ code: 'COUPON_UNKNOWN' }` matcher in `test/coupons.test.js:20` would fail. A person can check this by deleting the guard and running `node --test test/coupons.test.js`.
- The real-clock path, `total(items, { couponCode })` with `now` left out, is not exercised by any test. The run interdict against reading the real clock forbids such a test. A person can check it by hand in a node REPL, where `WELCOME10` should return a discounted total until 2099.
- The project has no type checker, lint, E2E or build command (all `—`), so types, formatting and integration were not checked by any tool at any stage.
- I did not rerun the full unit suite. I relied on the verification record, whose tree matches the commit.
- There is no UI, adapter or persistence, so no screen or flow exists to open. How the coupon reaches a real checkout is outside this story and unverified.

Max severity: minor
Ship allowed: yes
