# Review: s86-cli-api-profiles

[Story](../stories.md) · [Plan](../plans/s86-cli-api-profiles.md) · [Verification](../verif/s86-cli-api-profiles.md)

Reviewed tree: 1b91472bc6d5c802174d6e920e355d357554101f
Fix loop: 0
Scope: `git diff main...story/s86-cli-api-profiles`, one commit (75e7e7a)
Lenses run: none. The diff holds two markdown profiles, one bash test and docs. It has no auth, route or handler path, no migration, no lockfile or manifest, and no server code.

## Summary
The story is ready to ship. There is no critical or major finding, only two minor ones.

The story adds two profiles, `boilerplates/rust-cli/profile.md` (from rust-starter at 51ebb2f) and `boilerplates/hono-api/profile.md` (from honojs/starter `templates/nodejs/` at 110fb1c). It also adds ADR-0061 and the 3-test file `tests/cli-api-profiles.test.sh`.

I cloned both upstream repos at the profiled commits under /tmp/tmp.YPbNHYYVEV and checked the profiles against them. The identities, licences, dates, paths, scripts, the hard-coded port 3000, the `APP` env prefix, the `termlog` gating, the double parse in `cli_match`, the `--debug` doc text, the random `hazard` output, the ignored `Cargo.lock` and the README's mention of Failure all match the source. Only one sentence is wrong (finding 1).

## Scope check (Owns)
The `Owns` line is `boilerplates/rust-cli/`, `boilerplates/hono-api/`, `tests/cli-api-profiles.test.sh`.
- Both profiles and the test are inside `Owns`.
- `docs/plans/s86-cli-api-profiles.md` and `docs/verif/s86-cli-api-profiles.md` are this story's own pipeline evidence, so they are in scope.
- `docs/decisions/ADR-0061-…md` is added (status A) and the plan names it by file name, so it is in scope.
- Only one other worktree is running, `story/s82-mobile-web-driver`. Its Owns are `method/skills/qa-drivers/mobile-web.md`, `method/skills/design-doctrine/` and `tests/mobile-web-driver.test.sh`. Nothing overlaps, and its ADR is numbered 0060, so the ADR numbers do not collide.

## Step 1: reused evidence
- `po-gate verif-current s86-cli-api-profiles` exits 0 (record is complete, Unit suite `bash tests/run.sh` exit 0).
- `Verification mode: record`, so I did not rerun the full suite.
- The project's Typecheck, E2E and Build commands are `—`: it has none.
- The story has no Surface, so no QA stage applies and `qa-current` does not apply.
- The record's "Not proven here" section is carried into Not verified below.
- I also ran `bin/po-lint` myself: no breach.

## Step 2: references
- Every path the profiles cite exists in the upstream clone at the profiled commit, under the repo root (rust) or `templates/nodejs/` (hono).
- The test's helpers (`ROOT`, `METHOD`, `require_file`, `fail`) are defined in `tests/lib.sh`.
- `bin/po-lint` accepts a method directory as its argument.
- `tests/run.sh` runs each test in its own `bash -c`, so the `trap … EXIT` inside each test function is safe.

## Step 3: plan conformity
- Tasks 1 to 5 are all present.
- The run interdicts hold: the diff touches only the two profiles, the test, ADR-0061 and the story's docs. Nothing changes in `method/`, `bin/`, the existing tests, `.claude/` or `.polype/`, and no upstream file was copied in.
- Each profile has exactly the template's ten `## ` headings.
- The capabilities stay inside the template's list.
- The plan's pivot is respected: the Rust `Test` that takes no path, the Hono template with no `Test`, and the ignored `PORT` are stated in the profiles, not hidden.

## Step 4: tests
- **Floor:** `po-gate floor-guard s86-cli-api-profiles main` exits 0.
- **Budget:** 3 tests out of 25.
- **Proving nothing:** none of the six kinds. The lint test builds its own mutant (`## Known traps` removed) and requires po-lint to fail and to name both files. The grounding test runs its checker on a copy of the profile with a made-up path and requires that path to be reported.
- **Bite tests:** I ran each mutation with only `tests/cli-api-profiles.test.sh`, using `RUST_CLI_SRC`/`HONO_API_SRC` set to my clones. Each was undone with `git checkout --` and confirmed with `git diff --exit-code`.
  1. hono-api `- QA driver: scenarios` changed to `browser`: 1 test fails (`use_scenarios`).
  2. rust-cli `utils/src/logger.rs` changed to `utils/src/log.rs`: 1 test fails (`grounded_in_their_sources`, "path not in the source").
  3. hono-api `Dev: npm run dev` changed to `npm run serve`: 1 test fails (`grounded_in_their_sources`, "npm script not in the source: serve").
- The final `git status --porcelain` is empty and the tree is unchanged.

## Step 5: values
- Commit hashes and dates match `git log -1` of each clone (2025-05-07 and 2026-10-04).
- `LICENSE` starts with `MIT License` (rust), and the root `package.json` has `"license": "MIT"` (hono).
- `port: 3000` is hard-coded in `templates/nodejs/src/index.ts:12`.
- The binary is called `rust-starter`.
- `tests/test_cli.rs::test_cli` asserts that running with no subcommand fails.

## Step 6: neighbours
- `po-setup`, `po-architect` and `po-design-system` read `boilerplates/*/profile.md` generically. `docs/catalogue.md` does not list profiles by name, so it needs no update.
- `bin/po-lint` reads all four profile folders without a breach.

## Findings

1. **minor**: `boilerplates/rust-cli/profile.md:71` is wrong. It says "Every dependency of `utils` sits under the Linux-only target section of `utils/Cargo.toml`". Upstream `utils/Cargo.toml` keeps 11 dependencies under `[dependencies]` (thiserror, config, slog…). Only `slog-journald`, `clap`, `log` and `serde` are under `[target.'cfg(target_os = "linux")'.dependencies]`. The conclusion still holds, because `utils/src/app_config.rs`, `error.rs` and `types.rs` use clap and serde, so the build is Linux-only. Suggested wording: "`clap`, `log` and `serde` sit under the Linux-only target section…". The plan stated this correctly. The profile turned it into a false general claim, and the test cannot catch it because it is prose.
2. **minor**: `tests/cli-api-profiles.test.sh:19-27` has two small style issues in `grounding_breaches`. It declares a local variable named `head`, which shares its name with the `head` command used two lines later. It works, but reads ambiguously. `tokens` is also assigned without `local`. Neither affects behaviour, since each test runs in its own process.

## Not verified
- **None of either profile's commands were run** (`cargo fetch/test/check/build`, `npm install`, `npx tsc --noEmit`, `npm run build/dev`). The record says `npx tsc --noEmit` was not run and does not mention the cargo commands either. In particular, whether `typescript` ^7.0.2 still ships a `tsc` binary is assumed from the `build` script, not checked. To cover it, a person runs `npm install && npx tsc --noEmit && npm run build` in a throwaway copy of `templates/nodejs/`, and `cargo test --workspace && cargo build --release` in a copy of rust-starter, on Linux.
- **The scenarios driver was never run against either starter.** The claim that the Hono QA ends `blocked` because of the hard-coded port is deduced from `scenarios.md` and `src/index.ts`, not observed.
- **Offline the grounding test does not check anything.** Without network, `cli_api_profiles_are_grounded_in_their_sources` prints a note on stderr and passes, as the next-forge precedent does. With network I ran it against my own clones and it passed.
- **Prose claims no test checks** (finding 1 shows one slipped through). Examples are the `.js` extension trap of `NodeNext` and "`tsx watch` does not type-check". I spot-checked them against the source and did not run them.

## Verdict
No critical finding. No major finding. Two minor findings.

Max severity: minor
Ship allowed: yes
