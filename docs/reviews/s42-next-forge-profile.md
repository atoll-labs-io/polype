# Review — s42-next-forge-profile

[Story](../stories.md) · [Plan](../plans/s42-next-forge-profile.md) · [Verification](../verif/s42-next-forge-profile.md)

Diff reviewed: `git diff m4-catalogue...story/s42-next-forge-profile` (one commit, c131c24), in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Ownership
I listed the diff with `git diff --name-only m4-catalogue...story/s42-next-forge-profile` and checked each path against `Owns`: `boilerplates/next-forge/profile.md` and `tests/next-forge-profile.test.sh`.
- [x] Every path is inside `Owns`. The other three files are this story's own pipeline evidence: `docs/research/`, `docs/plans/` and `docs/verif/s42-next-forge-profile.md`.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows no other story worktree.
- [x] The story has an `Owns` line (`docs/stories.md:630`).

## Evidence reused
- [x] `po-gate verif-current s42-next-forge-profile` exits 0, so the record matches the committed code. The record says `Verification status: complete` with every exit code 0: full suite 222 passed, `bin/po-lint` clean, and the grounding test ran over the network without skipping. I reused it and did not rerun the full suite. The project has no type check, E2E or build command (`Typecheck: —`, `E2E: —`, `Build: —`). I read its "Not proven here" section: the prose claims were checked by hand only, and the offline skip is silent in the full suite.

## Plan
- [x] Tasks 1 to 4 are all present, and nothing was added outside the plan.
- [x] I checked each run interdict:
  - the diff does not touch `method/`, `bin/*`, existing tests, `docs/catalogue.md`, `docs/parite-killer-saas.md`, `README.md`, `docs/decisions/*`, `.claude/` or `.polype/`;
  - `boilerplates/next-forge/profile.md` is the only file under `boilerplates/`;
  - no next-forge file was copied into the repository;
  - the profile has exactly the template's eight `## ` headings, in order;
  - the gaps are a bullet list, not a table.

## References
- [x] I cloned next-forge myself into `/tmp` at `f189de79ceef7c1ef69f61f12e272f99b4cdb699` (2026-05-28, v6.0.2, MIT), then deleted the clone. Confirmed against it:
  - the root scripts `test`, `build`, `check` and `migrate`;
  - no `typecheck` task in `turbo.json`, and `build` depends on `test`;
  - the 7 apps and the packages listed;
  - the Neon adapter in `packages/database/index.ts`, and `packages/storage/index.ts` re-exporting `@vercel/blob`;
  - `output = "../generated"` in the Prisma schema, and the database package's `build` is `prisma generate`;
  - `orgId` in `apps/app/app/actions/users/search.ts:33`;
  - the Docker guide requiring standalone output, and the `turbo gen init` generator;
  - every named UI component exists, and `bin/po-lint` reads `boilerplates/*/profile.md`.
- [ ] Some values only look right. Two claims are wrong (findings 1 and 3), and one is loose (finding 4).

## Rules
- [x] `AGENTS.md` conventions are respected: the file is in English, the tests are bash using `tests/lib.sh`, the test function names match the criteria, and the commit is in English.
- [x] No accepted ADR is contradicted. The gaps match `method/skills/capability-bricks/SKILL.md` (ADR-0020). Keeping Prisma is consistent with ADR-0010.

## Tests
- [x] The assertions pin the four criteria. None of the six empty test shapes is present: the grounding check runs against a real checkout, and each test builds its own mutant.
- [x] 4 tests out of a budget of 25.
- [x] Bite: I ran only `next-forge-profile.test.sh` with `NEXT_FORGE_SRC` set to my clone. After each change I restored the file with `git checkout` and confirmed it with `git diff --exit-code`, which was clean every time.
  - The path-existence check disabled (`tests/next-forge-profile.test.sh:40`, `[ -e … ]` changed to `true`): 1 test fails. The built-in mutant catches it.
  - Commit in the profile off by one hex digit: 1 test fails.
  - `packages/rate-limit/` renamed to `packages/ratelimit/` in the profile: 1 test fails.
  - `Test: bun run tests` instead of `bun run test`: 1 test fails.
  - The Files gap bullet deleted: 1 test fails (the gaps test).
  - The path removed from the Deployment Notes cell: 1 test fails.
- [x] No existing test was made useless by this story. `lint.test.sh` now also lints this profile.

## Neighbours
- [x] The only reader of `boilerplates/*/profile.md` is `bin/po-lint:215-252`. It passes, according to the record and to `lint.test.sh`. No code changed, so there are no other callers.

## Findings
1. major — `boilerplates/next-forge/profile.md:52` — The "Access" line puts the access rule in the wrong place. It says the rule lives in the Clerk middleware and that "pages outside `apps/app/app/(authenticated)/` are public". In the clone:
   - `packages/auth/proxy.ts` only re-exports `clerkMiddleware`, and `apps/app/proxy.ts` calls it with no `auth.protect()` and no route matcher for protection, so the middleware attaches the session and blocks nothing.
   - The sign-in guard is `redirectToSignIn()` in `apps/app/app/(authenticated)/layout.tsx`.
   - Server actions (`apps/app/app/actions/`) and API routes (`apps/app/app/api/`) are outside that layout, so each must check `auth()` itself, as `users/search.ts` does.

   A story that follows this line and trusts the middleware would ship an unprotected action. The line should name the layout guard and the per-action/per-route `auth()` check as where access lives. The grounding test cannot catch this because it checks that paths exist, not what they do. It is major, not critical, because it is guidance inside a document and nothing runs today.
2. minor — `boilerplates/next-forge/profile.md:22,98` — `Test: bun run test` does not accept paths, which breaks the template's rule (`method/templates/profile.md:22`: "A `Test` command must accept paths to test files."). The deviation is deliberate, disclosed in the profile and argued in the plan's pivot: no root command takes paths, so it describes the real repository instead of inventing one. The consequence is that a next-forge project cannot do the per-task focused run with its `Test` setting. A person should decide whether the template (s40's file) allows this or whether profiles get a separate focused-test command.
3. minor — `boilerplates/next-forge/profile.md:102` — "Each app … ship[s] a `.env.example`" is inaccurate. Only `apps/app`, `apps/api` and `apps/web` have one; `apps/email`, `apps/docs`, `apps/storybook` and `apps/studio` do not. The packages that have one are `database`, `cms` and `internationalization`.
4. minor — `boilerplates/next-forge/profile.md:103` — "Every package checks its environment through its `keys.ts`" contradicts line 33 ("Most of them…"). In the clone, 16 of the 20 packages have a `keys.ts`.
5. minor — `boilerplates/next-forge/profile.md:92` — "one story per shared component" is inaccurate: there are 46 files in `apps/storybook/stories/` against 55 components under `ui/`.
6. minor — `boilerplates/next-forge/profile.md:24-44` — The Code map skips two top-level directories that the profile cites elsewhere: the root `docs/` (next-forge's own documentation site, which a project would delete, cited on lines 76 and 84) and `turbo/` (generators). The template asks for one line per top-level directory.

## Not verified
- **The prose claims beyond paths and scripts.** I spot-checked the load-bearing ones: auth, tenancy, bricks, generated client, build order, env files, components. I did not check every sentence, for example "status widget" in observability or "locale detection" in i18n. A person should read the Code map descriptions against the clone once.
- **Whether the grounding test skips in normal use.** It skips silently when offline or when GitHub is unreachable, and `tests/run.sh` hides stderr on success, so a green full suite does not prove the grounding ran. The record's direct network run covers this commit only. To prove it on a later run, rerun it with `NEXT_FORGE_SRC` set to a checkout.
- **Starting a real project on next-forge.** I never ran `bun install`, `bun run test` or `bun run build` in next-forge, so the commands are proven to exist, not to succeed. A person adopting the profile should run all three once in a fresh clone.
- **Design conformity.** Not applicable: the story has no screen.

Max severity: major
Ship allowed: yes
