# Research — s01-apply-coupon

## Structuring facts
- No coupon code exists anywhere: the catalogue, the lookup and the error paths are all new (`src/cart.js:1-9` is the whole source).
- `total(items)` takes one argument and returns `subtotal(items)` (`src/cart.js:7-9`); its only caller is `test/cart.test.js:14-16`, which must keep passing.
- The story's assumptions hold: money is integer cents (`src/cart.js:1`, `test/cart.test.js:6-7`), there is no clock usage to replace, no dependency, no persistence.
- No project error convention exists yet; this story sets the first one.

## Story
A shopper applies a coupon code to the cart and pays the discounted total.
- A valid coupon reduces the total by its percentage of the subtotal, rounded down to the cent.
- The discount never exceeds the coupon's cap, in cents.
- An expired coupon is refused with an error and the total is unchanged.
- An unknown coupon code is refused with an error.

Catalogue (from the story's notes): `WELCOME10` 10 %, cap 500, expires 2099-12-31; `SPRING20` 20 %, cap 1000, expired 2025-06-30. "Now" must be injectable.

## Current code
- `src/cart.js:3-5` — `subtotal(items)`: `reduce` of `unitPrice * quantity`, integer cents in, integer cents out.
- `src/cart.js:7-9` — `total(items)`: delegates to `subtotal`.
- `test/cart.test.js:1-16` — `node:test` + `node:assert/strict`; fixture of 2 items, subtotal 3250; two tests.
- `package.json` — `"type": "module"`, no dependencies, `npm test` = `node --test`.

## Attachment points
- `src/cart.js` — where `total` lives; the coupon discount must plug into the total computation.
- A coupon catalogue + lookup: either inside `src/cart.js` or a new `src/coupons.js` (both inside the story's `Owns: src/`).
- Tests go in `test/` as `*.test.js` (AGENTS.local.md conventions); `node --test` discovers `test/**/*.test.js` by default.

## Verified interfaces
| Name | Location | Signature / behaviour |
| --- | --- | --- |
| `subtotal` | `src/cart.js:3` | `(items: {unitPrice, quantity}[]) → integer cents` |
| `total` | `src/cart.js:7` | `(items) → subtotal(items)` |
| test runner | `package.json` `scripts.test` | `node --test` (Node v22.23.2 locally) |

## Traps
- `test/cart.test.js:14` asserts `total(items) === 3250` with a single argument: any new signature must keep `total(items)` working without a coupon.
- Rounding: "rounded down to the cent" — with integer cents, `Math.floor(subtotal * percent / 100)`. Floating point: `3250 * 10 / 100` is exact, but a percent expressed as a fraction (`0.1`) can yield `x.9999…`; keep integer arithmetic (multiply before divide).
- Cap applies to the discount, not to the total: `min(floor(subtotal*pct/100), cap)`.
- Expiry dates are calendar days with no time zone in the story. Comparing a `Date` "now" to `new Date('2099-12-31')` (UTC midnight) would make a coupon expire at the *start* of its last day.
- "Total unchanged" on refusal: with a thrown error the caller keeps the previous total; nothing to mutate since the cart is a plain array.
- Pre-commit hook (`.polype/hooks/po-gate.sh:47-60`, `core.hooksPath=.polype/hooks`) refuses code commits on `story/*` before `validated: yes`.
- No migration, no other module depends on `src/cart.js`.

## Open questions
- Is the expiry date inclusive (coupon valid through 2099-12-31) and in which time zone? The plan decides; UTC and inclusive is the least surprising reading.
- API shape: `total(items, { coupon, now })` vs a separate `applyCoupon(...)`. The plan decides.
- Is the coupon code case-sensitive? The story does not say; exact match is the conservative choice.

## Complexity
Story: 2 → after reading: 2–3. Small surface (one file, pure functions), but it introduces a business rule with three branches (valid, expired, unknown) plus rounding and a cap. Stays well under a split.

## Split
Not needed.
