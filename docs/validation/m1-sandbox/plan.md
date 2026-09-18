---
validated: yes
---
# Plan — Story s01-apply-coupon

Branch: `story/s01-apply-coupon`
Research: `docs/research/s01-apply-coupon.md` — read it first; this plan does not repeat it.

## Story
Apply a percentage coupon to the cart total.
1. A valid coupon reduces the total by its percentage of the subtotal, rounded down to the cent.
2. The discount never exceeds the coupon's cap, in cents.
3. An expired coupon is refused with an error and the total is unchanged.
4. An unknown coupon code is refused with an error.

## Decisions
| Question | Decision | Why |
| --- | --- | --- |
| Where the rule lives | New `src/coupons.js`: catalogue + `couponDiscount` | Keeps `cart.js` about totals; one rule, one module, one test file |
| Catalogue shape | `export const COUPONS = { WELCOME10: { percent: 10, capCents: 500, expiresOn: '2099-12-31' }, SPRING20: { percent: 20, capCents: 1000, expiresOn: '2025-06-30' } }` | Fixed in-code catalogue, per the story |
| Signature | `couponDiscount(code, subtotalCents, now = new Date()) → integer cents` | "Now" injectable; default keeps production callers simple |
| Rounding | `Math.floor(subtotalCents * percent / 100)`, then `Math.min(capCents, …)` | Multiply before dividing: integer product, single float division |
| Expiry | Valid through the whole `expiresOn` day, UTC: expired iff `now.toISOString().slice(0, 10) > expiresOn` | "Expires 2099-12-31" read as last valid day; string compare on ISO dates is exact |
| Refusal | `throw new Error('Unknown coupon: <code>')` / `throw new Error('Expired coupon: <code>')` | "Refused with an error"; throwing means no total is ever produced with a refused coupon, so the total is unchanged |
| Code matching | Exact, case-sensitive lookup with `Object.hasOwn(COUPONS, code)` | Not specified; `hasOwn` avoids `toString`/`__proto__` resolving through the prototype |
| Cart API | `total(items, { coupon, now } = {})`: no `coupon` → `subtotal(items)`; otherwise `subtotal − couponDiscount(coupon, subtotal, now)` | Optional second argument keeps `total(items)` and its test unchanged |

## Tasks, in order
1. [x] Create `src/coupons.js` with `COUPONS` and `couponDiscount` per the decision table. Tests in `test/coupons.test.js` (see strategy); run `node --test test/coupons.test.js`.
2. [x] Extend `total` in `src/cart.js` to accept `{ coupon, now }` and subtract the discount. Add one test in `test/cart.test.js`: `total(items, { coupon: 'WELCOME10', now })` with the existing fixture (subtotal 3250) → `2925`. Run `node --test test/cart.test.js`.
3. [x] Full suite once: `node --test`. Typecheck is `—` (none in this project). Write `docs/verif/s01-apply-coupon.md`, then the single story commit.

## Run interdicts
- `subtotal` in `src/cart.js` stays byte-identical; the two existing tests in `test/cart.test.js` stay unchanged.
- No `Date.now()` / `new Date()` inside a test: every test passes an explicit `now`.
- No dependency added; `package.json` unchanged.
- No floating-point money: no `percent / 100` multiplied afterwards, no `toFixed`, no rounding other than `Math.floor`.
- Out of scope: stacking several coupons, case-insensitive codes, persisting coupons, a coupon on an empty cart special case.

## The pivot
Throwing on a refused coupon is how "the total is unchanged" is honoured: a caller holding a total before applying the coupon keeps it. Could be wrong if the product expected `total` to silently ignore a bad coupon and return the subtotal — compare against criterion 3's wording ("refused with an error"). Second hesitation: expiry-day inclusivity — compare the boundary test (`2025-06-30T23:59Z` valid, `2025-07-01T00:00Z` expired) against the story's "expires 2099-12-31".

## Files touched
- `src/coupons.js` (new)
- `src/cart.js`
- `test/coupons.test.js` (new)
- `test/cart.test.js`
- `docs/research/`, `docs/plans/`, `docs/verif/` for this story

## Test strategy
Business rule lives in `couponDiscount` → tested there, at one layer; `total` gets one wiring test. 6 tests total, well under the budget of 25. Each must turn red if its rule is removed:
- `test/coupons.test.js`
  1. Percentage rounded down: `couponDiscount('WELCOME10', 3255, now)` → `325` (325.5 floored; dies if floor becomes round/ceil or is removed).
  2. Cap: `couponDiscount('WELCOME10', 10000, now)` → `500` (uncapped would be 1000).
  3. Expired refused: `SPRING20` with `now = 2025-07-01T00:00:00Z` → `assert.throws(…, /Expired coupon/)`.
  4. Expiry day still valid: `SPRING20` with `now = 2025-06-30T23:59:00Z` and subtotal 3000 → `600`.
  5. Unknown refused: `'NOPE'` → `assert.throws(…, /Unknown coupon/)`.
- `test/cart.test.js`
  6. `total(items, { coupon: 'WELCOME10', now })` → `2925`.
No visual checks: no UI.

## Definition of done
One squash commit on `main`; 6 new tests plus the 2 existing ones green under `node --test`; review with no open critical finding; no deployment in this project.
