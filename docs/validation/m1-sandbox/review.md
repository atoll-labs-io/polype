# Review: story s01-apply-coupon

> A fresh-context review of `git diff main...story/s01-apply-coupon`, run in `/home/lecrabe/.claude/jobs/1b2863ed/tmp/sandbox/.worktrees/s01-apply-coupon` on branch `story/s01-apply-coupon` (commit c14a30c, clean tree). Each finding is rated critical, major or minor.

Review status: complete

## Verification record
- [x] `.polype/hooks/po-gate.sh verif-current s01-apply-coupon` exited 0. `git diff --quiet 28c6ad35… HEAD -- . ':(exclude)docs'` also exited 0. The record says `Verification status: complete` and the full suite `node --test` exited 0 with 8 passed. `Verification mode: record` is set, so I took the record as proof and did not rerun the suite.
- `Typecheck: —`, `E2E: —`, `Build: —` are all `—` in AGENTS.local.md, so none of them ran. That is correct: nothing was substituted for them.
- The record's "Not proven here" section is accurate. There is no type checker, linter or formatter, and the default `now = new Date()` path is never exercised.

## Plan
- [x] All three tasks are present, and the diff touches only the files the plan lists (`src/coupons.js`, `src/cart.js`, `test/coupons.test.js`, `test/cart.test.js`, and the story docs). Nothing outside the plan was added.
- [x] Every run interdict was checked by name:
  - **`subtotal` byte-identical:** yes.
  - **Two existing cart tests unchanged:** yes.
  - **No clock read in tests:** yes. Every test passes an explicit `new Date('<ISO>')`.
  - **`package.json` unchanged:** yes. The diff for it is empty.
  - **No float money:** yes. The code multiplies before dividing and uses `Math.floor` only.
  - **Out-of-scope items:** none implemented.

## References
- [x] Every reference in the diff exists as used:
  - The import `./coupons.js` → `couponDiscount` exists.
  - `Object.hasOwn` is available in Node v22.23.2.
  - `Date.prototype.toISOString().slice(0, 10)` returns `YYYY-MM-DD` in UTC.
  - `node:test` and `node:assert/strict` (`equal`, `throws`) are built-ins.
  - The catalogue values match the story and the plan exactly: WELCOME10 is 10%, cap 500, expires 2099-12-31; SPRING20 is 20%, cap 1000, expires 2025-06-30.
- [x] No plausible-but-wrong values:
  - The fixture subtotal is 3250. 10% of it is 325, so the expected total 2925 is correct.
  - 3255 × 10 / 100 = 325.5, floored to 325.
  - 10000 at 10% is 1000, capped to 500.
  - Expiry is inclusive through the whole UTC day, as the plan decided. The boundary test uses `23:59Z` on the expiry day (valid) and `00:00Z` the next day (expired).
  - I probed directly: `toString`, `__proto__`, `welcome10` and `null` all throw `Unknown coupon`.

## Rules
- [x] The code follows the AGENTS conventions: ES modules, no dependencies, integer cents, `src/` and `test/*.test.js` with `node:test`. The two comments in `coupons.js` both explain *why*.
- [x] There is no `docs/decisions/` directory, so there was no accepted ADR to contradict.

## Tests
- [x] The assertions pin all four acceptance criteria. None of the six failure shapes applies: no `catch` swallows a failure, fixtures and mocks are not involved, and every test calls the real code.
  - Criterion 3's "total unchanged" is honoured structurally: `total` throws before it can return a value. That is tested once, at the `couponDiscount` layer, which follows the "one rule, one layer" cut.
- [x] Volume is 6 new tests, 8 in total, against a `Test budget` of 25.
- [x] Bite: I neutralized six invariants, running only the test file that names each one. After each run I restored the file with `git checkout -- <file>` and confirmed it with `git diff --exit-code`. At the end, `git diff --exit-code` over the whole tree and `git status --short` were empty, and a `cmp` against pre-mutation backups showed both files identical.

  | # | Neutralization | Test file run | Red tests |
  | --- | --- | --- | --- |
  | M1 | Expiry comparison `>` changed to `>=` | `test/coupons.test.js` | 1 |
  | M2 | Expiry check dropped | `test/coupons.test.js` | 1 |
  | M3 | Cap `Math.min` dropped | `test/coupons.test.js` | 1 |
  | M4 | `Math.floor` changed to `Math.round` | `test/coupons.test.js` | 1 |
  | M5 | `Object.hasOwn(COUPONS, code)` changed to `code in COUPONS` | `test/coupons.test.js` | **0** |
  | M6 | `total` returns `sub` without subtracting the discount | `test/cart.test.js` | 1 |

- [x] No tests became redundant. The existing test for `total` without a coupon still guards the optional-argument path.

## Regressions
- [x] The only caller of `total` and `couponDiscount` is the test suite. `total(items)` with no second argument still returns the subtotal, since the default `{}` leaves `coupon` undefined. No other callers exist in `src/`.

## Findings
- **major** — `src/coupons.js:10`: the `Object.hasOwn` guard is untested. Mutation M5 turned zero tests red. The plan made this guard a deliberate decision ("hasOwn avoids toString/__proto__ resolving through the prototype"), but the only unknown-code test uses `'NOPE'`, which fails the guard with or without the fix. If someone later "simplifies" the check to `in` or `COUPONS[code]`, `total(items, { coupon: 'toString' })` would silently return `NaN` instead of throwing. That silently corrupts money. The code is correct today; the gap is in the tests. The fix is one assertion in the existing unknown-coupon test, e.g. `assert.throws(() => couponDiscount('toString', 3000, now), /Unknown coupon/)`.
- **minor** — `src/coupons.js:15`: a caller that passes an invalid `Date` gets a `RangeError` from `toISOString`, not a coupon error. The plan does not specify this input and no caller produces it today, so it is noted only.

## Not verified
- **Real-clock path:** the default `now = new Date()` is never exercised, by design. A human could run `node -e "import('./src/coupons.js').then(m=>console.log(m.couponDiscount('WELCOME10',3250)))"` and expect 325, and the same call with `'SPRING20'` should throw `Expired coupon`.
- **Type checking, lint, formatting:** none is configured (`Typecheck: —`). Nothing checks types at all.
- **E2E and build:** `E2E: —` and `Build: —`, so neither ran. There is no UI, deployment or third party in this story, so nothing was rendered or mocked.
- **Product intent:** this review cannot settle two plan decisions. One is expiry-day inclusivity: a coupon is valid through 23:59:59 UTC on its expiry day, not local time. The other is that an invalid coupon makes `total` throw instead of falling back to the subtotal. A product owner should confirm both.

Max severity: major
Ship allowed: yes
