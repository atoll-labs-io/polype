# Research — Story s01-apply-coupon

## Structuring facts
- No premise is broken: money is already integer cents, `subtotal(items)` sums `unitPrice * quantity` — `src/cart.js:3-5`.
- `total(items)` is a one-argument passthrough to `subtotal` — `src/cart.js:7-9`; an existing test pins `total(items) === subtotal` without a coupon — `test/cart.test.js:14-16`. Any coupon parameter must be optional to keep that test green.
- No coupon concept, no clock, no error convention exists anywhere in `src/` — the story introduces all three.
- `SPRING20` is already expired against today's real date (2026-09-18) and `WELCOME10` is valid until 2099-12-31: tests must inject "now", never read the clock (story's agentic note).
- Pre-commit gate is live: `git config core.hooksPath` → `.polype/hooks`, which refuses a code commit on `story/*` without a validated plan.

## Story
Apply a percentage coupon to the cart total. Acceptance criteria:
1. A valid coupon reduces the total by its percentage of the subtotal, rounded down to the cent.
2. The discount never exceeds the coupon's cap, in cents.
3. An expired coupon is refused with an error and the total is unchanged.
4. An unknown coupon code is refused with an error.

Catalogue (in code): `WELCOME10` 10 %, cap 500, expires 2099-12-31; `SPRING20` 20 %, cap 1000, expired 2025-06-30.

## Code as it is
- `src/cart.js` (9 lines): `subtotal(items)`, `total(items)`. ES module, no dependencies, no validation.
- `test/cart.test.js` (16 lines): `node:test` + `node:assert/strict`, fixture subtotal 3250.
- `package.json`: `"type": "module"`, `test` script `node --test`. Node v22.23.2.

## Anchor points
- `src/cart.js` `total()` — where the discount applies.
- A coupon catalogue + validation: either in `src/cart.js` or a new `src/coupons.js` (conventions: source in `src/`, tests in `test/*.test.js`).

## Verified APIs
- `subtotal(items: {unitPrice, quantity}[]) → number` — `src/cart.js:3`.
- `total(items) → number` — `src/cart.js:7`.
- `node:test` `test`, `node:assert/strict` `assert.equal`, `assert.throws` — Node 22 built-ins.

## Traps
- Rounding: "rounded down to the cent" on a non-negative integer subtotal → `Math.floor(subtotal * percent / 100)`. Computing `subtotal * (percent / 100)` in floats can land just under an integer (e.g. `0.1 * 3` style errors) — multiply before dividing.
- Expiry boundary: "expires 2099-12-31" — whether the coupon is still valid *on* the 31st is unspecified. Comparing `now` against `new Date('2099-12-31')` (midnight UTC) would make the expiry day itself invalid.
- "Total is unchanged" on an expired coupon while also "refused with an error": if refusal throws, the caller never gets a total — "unchanged" then means no side effect / the cart's total without coupon remains what it was.
- Existing test `test/cart.test.js:14` will run with the full suite.
- No migration.

## Open questions
- Error shape: throw vs. return a result object. The story says "refused with an error" → throwing an `Error` fits plain JS with no existing convention; the plan decides.
- Expiry day inclusivity (see Traps) — the plan decides and states it.
- Is the coupon code case-sensitive? Not specified; the catalogue lists upper-case codes.

## Complexity
Scored 2 in `docs/stories.md`. After reading: 3 — it is business logic with several states (valid, capped, expired, unknown) rather than form/persistence, but small: one module, no I/O.

## Split proposal
Not needed.
