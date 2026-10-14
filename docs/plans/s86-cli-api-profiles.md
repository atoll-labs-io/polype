---
track: flow
validated: yes
---
# Plan (short track) — s86-cli-api-profiles

[Story](../stories.md)

Short track: this file stands in for the research. Validated autonomously (`Plan validation: autonomous`): no human reviewed it. The choice of the two starters is settled in `docs/decisions/ADR-0061-profils-cli-et-api-depuis-rust-starter-et-le-gabarit-node-de-hono.md` (written by the planner, uncommitted, `accepted`: commit it with the code, never edit its body).

`RS:` = `https://github.com/rust-starter/rust-starter` at `51ebb2f55f2a79a5c6ccad11aa90dea4f081d400` (2025-05-07). `HS:` = `https://github.com/honojs/starter` at `110fb1c4dc34e050665ca89e0a2fa1a00fde29ef` (2026-10-04), template `templates/nodejs/` (`HN:`). Both opened in a clone outside the repository on 2026-10-08.

## Verified facts
**Assumption corrected first.** The story implies an obvious public clap starter. The Rust CLI working group's `rust-cli/cli-template` uses structopt, not clap (`Cargo.toml:8` there, edition 2018, last commit 2020), and `rust-github/template` has no clap. Only `RS:` fits; see ADR-0061. Also: `HS:` has **no licence file**; MIT is declared in `HS:package.json:8` and `HS:README.md:28-30`.

Polype side:
- Profile format: ten `## ` headings, Commands fence `Install` `Test` `Typecheck` `E2E` `Build` `Dev`, `- Platform:` and `- QA driver:` lines (`method/templates/profile.md:1-76`).
- `bin/po-lint` checks each `boilerplates/*/profile.md`: every template heading present, fence names exact, platforms among the backticked values of the `| Platform |` row, driver `—` or a file of `method/skills/qa-drivers/` (`bin/po-lint:184-301`). `cli` and `api` are valid platforms (`method/templates/agents-local.md:53`); `scenarios` is a driver file (`method/skills/qa-drivers/scenarios.md:1-3`, covers `cli` and `api`).
- The scenarios driver takes the run or start command from `AGENTS.local.md` **or the profile its conventions name** (`scenarios.md:7`), runs `Install` then `Build` in a copy (`scenarios.md:10`), and needs a start command that accepts a port; none → `QA status: blocked` (`scenarios.md:14`). So each profile must say how to launch the program for a scenario.
- Precedent to follow: `boilerplates/next-forge/profile.md` (structure, deviations stated under the fence, `## Known traps`) and its test `tests/next-forge-profile.test.sh:4-105` (lint + mutant, network grounding with a skip and an env override). Each test file is sourced in its own process (`tests/run.sh:17`), so helpers may be redefined locally.

`RS:` (rust-cli):
- MIT: `RS:LICENSE:1` (`MIT License`), `RS:Cargo.toml:8`. Workspace `utils`, `cli`, `core` (`RS:Cargo.toml:14-15`); package and binary `rust-starter` (`RS:Cargo.toml:2`).
- clap 4 derive in `RS:cli/Cargo.toml:13-15`; the `Cli` struct, the `Commands` enum (`hazard`, `error`, `completion`, `config`) and the dispatch `cli_match` all live in `RS:cli/src/lib.rs:11-115`. Command bodies in `RS:core/src/commands.rs`.
- Entry `RS:src/main.rs`: panic handlers, logger, embedded config `RS:src/resources/default_config.toml`, then `cli::cli_match()`.
- Config layers: embedded TOML, then env vars prefixed `APP` (`RS:utils/src/app_config.rs:47`), then `-c FILE`, then CLI args. Errors in `RS:utils/src/error.rs` (thiserror, `RS:utils/Cargo.toml:15`); logging slog in `RS:utils/src/logger.rs`, discarded unless feature `termlog` (`logger.rs:20-24`).
- Tests: `RS:tests/test_cli.rs` drives the binary with `assert_cmd` (`Command::cargo_bin("rust-starter")`, version string `rust-starter 2.0.1`), plus `RS:utils/tests/test_config.rs`. `RS:justfile` wraps `cargo test --all` and `cargo test --test {{TEST}}`. No path argument: cargo filters by test name or by target name.
- Traps opened: `Cargo.lock` is git-ignored (`RS:.gitignore:2`); everything under `[target.'cfg(target_os = "linux")'.dependencies]` (`RS:utils/Cargo.toml:26-31`) includes `clap`, `log` and `serde`, so `utils` builds on Linux only; `cli_match` parses arguments twice, `Cli::parse()` then `Cli::command().get_matches()` (`RS:cli/src/lib.rs:83,89`); the `--debug` flag's doc says "Set a custom config file" (`lib.rs:27`); `hazard` prints one of two lines at random (`RS:core/src/commands.rs:8-19`); the README advertises Failure (`RS:README.md:68`) while the code uses thiserror. `RS:docker/Dockerfile` and `RS:.github/workflows/` exist.

`HN:` (hono-api):
- `HN:package.json`: scripts `dev` (`tsx watch src/index.ts`), `build` (`tsc`), `start` (`node dist/index.js`); deps `hono`, `@hono/node-server`; devDeps `typescript`, `tsx`, `@types/node`. No test runner, no lockfile.
- `HN:src/index.ts` is the whole app: one `GET /` route, `serve()` with **`port: 3000` hard-coded** (`HN:src/index.ts:12`), logs `Server is running on http://localhost:<port>` (`:14`).
- `HN:tsconfig.json`: `module` `NodeNext`, `verbatimModuleSyntax`, `outDir` `./dist`. `HN:README.md:1-8`: `npm install`, `npm run dev`. `HN:pnpm-workspace.yaml` exists (pnpm build allowance for esbuild) although the README uses npm. `HN:.gitignore` ignores `.env`; nothing loads it.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text: two markdown profiles and a test | absent — `boilerplates/` holds markdown only (`tests/bricks.test.sh:125-128` precedent); no schema in Polype |
| New screen | absent — `Surface : —` | absent — profiles and a bash test; no UI in the diff |
| Authorization or tenant scope | absent — story text | absent — neither starter has access or tenant code (`RS:cli/src/lib.rs`, `HN:src/index.ts`) |
| API contract | absent — the story describes an API boilerplate, it changes no contract | absent — `po-lint` and the profile template stay untouched; only data files are added |
| New dependency | absent — story text | absent — the test uses `git`, `grep`, `awk`, `sed`, already used by `tests/next-forge-profile.test.sh` |

Tasks: 5. Platform/QA routing: no story Surface, no QA stage.

## Story
A developer gets a Rust (clap) CLI profile and a TypeScript (Hono) API profile, so a project without a screen starts from verified facts and a scenario-driven QA.
- `cli_api_profiles_pass_the_lint` — both profiles follow the template, each written from a public, freely licensed starter at a named commit; `bin/po-lint` accepts them.
- `cli_api_profiles_use_scenarios` — platforms `cli` and `api`, driver `scenarios`, and each says how to launch the binary or the service for a scenario.

## Tasks
1. [x] **Clones.** `git clone` `RS:` and `HS:` into a `mktemp -d` outside the repository and any worktree; record `git rev-parse HEAD`. A HEAD other than the commits above → re-open every fact of this plan at the new HEAD before writing, and profile that commit. Nothing of either clone is copied into the repository. Test able to fail: task 4's grounding test.
2. [x] **`boilerplates/rust-cli/profile.md`**, English, own words, the template's ten `## ` headings verbatim and in order, no other `## ` heading.
   - Identity: `- Name: rust-starter`, `- Origin: https://github.com/rust-starter/rust-starter`, `- Licence: MIT`, `- Commit profiled: <40-hex>`; one line: version 2.0.1, commit date, a Cargo workspace of three crates on clap 4.
   - `- Platform: cli`, `- QA driver: scenarios`.
   - Fence: `Install: cargo fetch`, `Test: cargo test --workspace`, `Typecheck: cargo check --workspace --all-targets`, `E2E: —`, `Build: cargo build --release`, `Dev: —`. Under it: `Test` takes no path, a focused run is `cargo test --test <file stem of tests/>` or a test-name filter; `Dev` is `—` because a CLI serves nothing.
   - Under the fence, a paragraph starting exactly `To run a scenario,`: after `Build`, call `target/release/rust-starter <subcommand> [options]` from the scenario's scratch folder with the copy's absolute path; no subcommand is a usage error with a non-zero exit (`RS:tests/test_cli.rs:11-14`); config comes from `APP_`-prefixed variables or `-c <file>`; logs are silent unless built with `--features termlog`; the binary name follows the package name.
   - Code map: `src/`, `cli/`, `core/`, `utils/`, `tests/`, `docker/`, `.github/workflows/`, each in backticks.
   - Ownership: a story owns a new `core/src/<module>.rs` alone; shared, so run alone: `cli/src/lib.rs` (one enum and one match for every subcommand), `core/src/commands.rs`, `core/src/lib.rs`, root `Cargo.toml`, `utils/`.
   - Where each rule lives: argument validation in the clap derive of `cli/src/lib.rs`; business rules in `core/src/`; configuration in `utils/src/app_config.rs`; errors in `utils/src/error.rs`; no access or tenant rule exists, say so.
   - Capabilities: `Observability` (slog, `utils/src/logger.rs`) and `Deployment` (`docker/Dockerfile`, release workflow under `.github/workflows/`), each Notes cell citing a backticked path.
   - UI inventory: one line, no screen. Known traps: every trap listed in the facts above.
3. [x] **`boilerplates/hono-api/profile.md`**, same shape and rules.
   - Identity: `- Name: hono-starter (Node.js template)`, `- Origin: https://github.com/honojs/starter`, `- Licence: MIT`, `- Commit profiled: <40-hex>`; one line: the template directory `templates/nodejs/`, its date, what `npm create hono` would generate; every path of the profile is relative to `templates/nodejs/`. Say that the licence is declared in the repository's `package.json` and README, with no licence file.
   - `- Platform: api`, `- QA driver: scenarios`.
   - Fence: `Install: npm install`, `Test: —`, `Typecheck: npx tsc --noEmit`, `E2E: —`, `Build: npm run build`, `Dev: npm run dev`. Under it: no test runner ships, the first story adds one whose command accepts paths; `Dev` prints its address.
   - Paragraph starting exactly `To run a scenario,`: after `Build`, start `node dist/index.js` with `PORT=<port>` in the background and wait for the log line; **the template ignores `PORT`** (`src/index.ts` hard-codes 3000), so until a story makes `src/index.ts` read `process.env.PORT`, the scenarios driver ends `blocked`; requests with `curl` to `http://127.0.0.1:<port>/`.
   - Code map: `src/`, `src/index.ts`, `package.json`, `tsconfig.json`. Ownership: `src/index.ts` holds the app and every route, so it is shared; a story owns a new `src/routes/<name>.ts` mounted with `app.route()`, the mount line being its one shared edit. Where each rule lives: routes and handlers in `src/index.ts`; no validator, access or tenant code ships, say so. Capabilities: none provided; keep the table header and one line saying so.
   - UI inventory: one line, no screen. Known traps: hard-coded port; no test runner, no lockfile; `pnpm-workspace.yaml` beside an npm README; `tsx watch` does not type-check; `NodeNext` with `"type": "module"` needs `.js` extensions on relative imports; `.env` is ignored by git yet loaded by nothing.
4. [x] **`tests/cli-api-profiles.test.sh`**, header `# s86 — the rust-cli and hono-api profiles: lint, scenarios, grounding in their starters.` Helpers `section_of` and `identity_value` as in `tests/next-forge-profile.test.sh:7-9`. Three functions:
   - `test_cli_api_profiles_pass_the_lint` — `require_file` both; `bash "$ROOT/bin/po-lint"` exits 0; each profile's `Origin` equals its URL above, `Licence` is `MIT`, `Commit profiled` is 40 hex. Then on a `mktemp -d` copy (`method/` + both profiles) with `## Known traps` deleted from each, `po-lint` exits non-zero and names both `boilerplates/rust-cli/profile.md` and `boilerplates/hono-api/profile.md`.
   - `test_cli_api_profiles_use_scenarios` — exact lines `- Platform: cli` / `- Platform: api` and `- QA driver: scenarios` in both; in `section_of … Commands` of each: `To run a scenario,`; rust-cli also `target/release/rust-starter`; hono-api also `node dist/index.js` and `PORT`.
   - `test_cli_api_profiles_are_grounded_in_their_sources` — source: `$RUST_CLI_SRC` / `$HONO_API_SRC` when set, else clone `Origin` and fetch the commit as next-forge's test does; unreachable → one stderr line `(… not reachable: grounding not checked)` and return 0. With a source: `HEAD` equals `Commit profiled`; `LICENSE` starts `MIT License` (rust), `package.json` holds `"license": "MIT"` (hono, repository root); every backticked token matching `^(src|cli|core|utils|tests|docker|\.github)/` or `^(Cargo\.toml|justfile|LICENSE)$` (rust, against the root) or `^src/` or `^(package\.json|tsconfig\.json|pnpm-workspace\.yaml)$` (hono, against `templates/nodejs/`), skipping tokens with `<` or `*`, exists; at least 8 resolve for rust and 4 for hono; each `npm run <x>` of the hono fence is a script of `templates/nodejs/package.json` (`grep '"<x>":'`). Checks sit in one function printing one line per breach; it runs once more on a copy of the rust profile with a made-up `` `core/src/blockchain.rs` `` inserted and must report it.
   Run `bash tests/run.sh cli-api-profiles.test.sh profile.test.sh lint.test.sh`.
5. [x] **Closing checks**, once: `bin/po-lint` clean, then the full suite through `po-run` as `/po-execute` says. Delete task 1's clones.

## Scene viewpoints
—

## Run interdicts
- Empty diff on `method/`, `bin/`, `boilerplates/next-forge/`, `boilerplates/bricks/`, every existing `tests/*.test.sh`, `docs/catalogue.md`, `docs/parite-killer-saas.md`, `README.md`, `.claude/`, `.polype/`.
- `git diff --stat main...` lists only the two profiles, the test, the ADR-0061 file and this story's `docs/` files; no file of either starter enters the repository; no clone inside a worktree.
- No `## ` heading in either profile beyond those of `method/templates/profile.md`; capabilities stay inside the template's list.
- ADR-0061 is committed as written; no other ADR is created.

## The pivot
**The profiles record what the starters really do, deviations included, rather than what the template or the driver would like.** Rust's `Test` takes no path, the Hono template has no `Test` at all and ignores any port setting; both are stated in the profile, not papered over with an invented command. How it could be wrong:
- A reviewer reads "Test must accept paths" (`method/templates/profile.md:35`) as binding — the next-forge precedent (`boilerplates/next-forge/profile.md:31`) states the deviation the same way.
- `npx tsc --noEmit` assumes `typescript` ^7 still ships a `tsc` binary; `HN:package.json` `build` runs `tsc`, which says it does, but nobody ran it. The implementer may not run `npm install` on an untrusted clone; if in doubt, `Typecheck: —` with the reason under the fence is the honest fallback.
- The grounding test needs the network; it skips and says so, like `tests/next-forge-profile.test.sh:89-94`.

## Files touched
`boilerplates/rust-cli/profile.md` (new), `boilerplates/hono-api/profile.md` (new), `tests/cli-api-profiles.test.sh` (new), `docs/decisions/ADR-0061-profils-cli-et-api-depuis-rust-starter-et-le-gabarit-node-de-hono.md` (planner), this plan, `docs/verif/s86-cli-api-profiles.md`.

## Test strategy
3 tests of 25, at the only layer there is, the documents checked by the lint and against their sources.
- `cli_api_profiles_pass_the_lint` — fails on a template breach or a wrong identity line; its mutant proves the lint reads both files.
- `cli_api_profiles_use_scenarios` — fails if a platform, the driver or the launch paragraph goes.
- `cli_api_profiles_are_grounded_in_their_sources` — fails on a wrong commit, licence, path or npm script; its mutant proves the checker bites. Network-dependent, skips loudly.
Existing `profile.test.sh`, `lint.test.sh` and `next-forge-profile.test.sh` stay unchanged and green (the lint now reads three profiles).

## Done when
Both profiles and the test committed with this plan, the ADR and the record in one commit on `story/s86-cli-api-profiles`; `bin/po-lint` clean; full suite green through `po-run`; review with no open critical; squash on `main`.
