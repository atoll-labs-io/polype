---
validated: yes
---
# Plan — s01-apply-coupon

Branch `story/s01-apply-coupon`. Read `docs/research/s01-apply-coupon.md` first; this plan builds on it without repeating it.

## Story
Apply a percentage coupon to the cart.
- AC1 — A valid coupon reduces the total by its percentage of the subtotal, rounded down to the cent.
- AC2 — The discount never exceeds the coupon's cap, in cents.
- AC3 — An expired coupon is refused with an error and the total is unchanged.
- AC4 — An unknown coupon code is refused with an error.

## Decisions
| Question (research) | Decision | Rejected |
| --- | --- | --- |
| API shape | `total(items, { couponCode, now } = {})`; no `couponCode` → subtotal, as today | separate `applyCoupon` the caller must remember to chain |
| Where the catalogue lives | new `src/coupons.js`: `COUPONS` catalogue + `couponDiscount(code, subtotalCents, now)` | inside `cart.js` (mixes cart arithmetic and coupon rules) |
| Error shape | throw `Error` with a `code` property: `'COUPON_UNKNOWN'` or `'COUPON_EXPIRED'` | returning `null`/unchanged total silently (AC3/AC4 require an error) |
| Expiry | inclusive, UTC: a coupon expiring `YYYY-MM-DD` is valid while `now < Date.UTC(Y, M-1, D+1)` | exclusive midnight (loses the last day) |
| `now` | `Date` instance, default `new Date()` only when omitted | reading the clock inside the rule |
| Code matching | exact, case-sensitive | normalising case (not asked) |
| Arithmetic | `Math.min(Math.floor(subtotal * percent / 100), capCents)`, percent stored as an integer | fractional percent (`0.1`), float drift |

## Tasks
1. [x] Create `src/coupons.js`: `COUPONS` (`WELCOME10` 10 %/cap 500/expires `2099-12-31`; `SPRING20` 20 %/cap 1000/expires `2025-06-30`) and `couponDiscount(code, subtotalCents, now)` returning the discount in integer cents, throwing `COUPON_UNKNOWN` / `COUPON_EXPIRED`. Tests that fail if wrong: `test/coupons.test.js` — percentage floored (subtotal 3255 × 10 % → 325), cap reached (subtotal 9000 × 10 % → 500, not 900), expired `SPRING20` throws `COUPON_EXPIRED`, unknown `NOPE10` throws `COUPON_UNKNOWN`, last valid day inclusive (`now` = `2025-06-30T23:59:59Z` with `SPRING20` → discount given; `2025-07-01T00:00:00Z` → expired).
2. [x] Extend `total` in `src/cart.js` to `total(items, { couponCode, now } = {})`: subtract `couponDiscount` when `couponCode` is given; errors propagate unchanged. Tests that fail if wrong: `test/cart.test.js` — `total(items, { couponCode: 'WELCOME10', now })` → 3250 − 325 = 2925; expired coupon → throws and a following `total(items)` still returns 3250; existing `total equals subtotal without a coupon` keeps passing.
3. [x] Full suite `node --test`, write `docs/verif/s01-apply-coupon.md`, commit the story (research, plan, record, code, tests).

## Run interdicts
- `subtotal` in `src/cart.js:3-5` ends with an empty diff.
- The two existing tests in `test/cart.test.js:10-16` stay, unmodified.
- No dependency added: `package.json` ends with an empty diff.
- No test reads the real clock: every coupon test passes an explicit `now`.
- No file outside `src/`, `test/`, `docs/` changes.

## The pivot
The discount formula `min(floor(subtotal × percent / 100), cap)` and the inclusive-UTC expiry. Ways it could be wrong:
- Cap applied to the total instead of the discount → compare with the cap test (9000 → 8500, not 500).
- Rounding up or float drift → the floored case (3255 → 325) must fail if `Math.round`/`Math.ceil` is used.
- Expiry off by one day or time zone dependent → the two boundary tests around `2025-06-30T23:59:59Z` / `2025-07-01T00:00:00Z`.

## Files touched
- `src/coupons.js` (new)
- `src/cart.js`
- `test/coupons.test.js` (new)
- `test/cart.test.js` (additions only)
- `docs/research/`, `docs/plans/`, `docs/verif/` for this id

## Test strategy
Service layer only (pure functions, no adapter, no persistence, no UI). Automated tests: 6 in `test/coupons.test.js` (floor, cap, expired, unknown, last valid day, first expired day) + 2 in `test/cart.test.js` (discounted total, refused coupon leaves total unchanged) = 8 new, well under `Test budget` 25. Each one names a rule that, removed, turns it red. No visual check. `Typecheck: —`: the project has none.

## Done when
- All four ACs covered by the tests above; `node --test` green with the two pre-existing tests.
- `docs/verif/s01-apply-coupon.md` complete with a `Tree:` matching the commit.
- One story commit on `story/s01-apply-coupon`; review with no open critical finding; squash-merged to `main`.
