# Verification — s01-apply-coupon

Tree: 09013c1c479c1aac0d91a76da95245a2a9121dd8

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `node --test` | exit 0 · 10 passed · 0 skipped | 2026-09-18T17:21:31Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project | — |
| Build | — | no such command in this project | — |

Per-task runs before the suite: `node --test test/coupons.test.js` (exit 0, 6 passed), `node --test test/cart.test.js` (exit 0, 4 passed).

## Not proven here
- Types: the project has no type checker (`Typecheck: —`).
- End to end and build: the project has neither (`E2E: —`, `Build: —`).
- Lint and formatting: no command configured.
- Guard neutralisation (whether each test turns red when its rule is removed): left to the review.

Verification status: complete
