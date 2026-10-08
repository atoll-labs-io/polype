# Profile — rust-cli

## Identity and licence

- Name: rust-starter
- Origin: https://github.com/rust-starter/rust-starter
- Licence: MIT
- Commit profiled: 51ebb2f55f2a79a5c6ccad11aa90dea4f081d400

Package version 2.0.1, commit dated 2025-05-07. A Cargo workspace of three crates (`cli`, `core`, `utils`) plus a root binary, with the command line parsed by clap 4 through its derive API.

## Platform

- Platform: cli

## QA driver

- QA driver: scenarios

## Commands

```
Install:           cargo fetch
Test:              cargo test --workspace
Typecheck:         cargo check --workspace --all-targets
E2E:               —
Build:             cargo build --release
Dev:               —
```

`Test` does **not** accept paths, unlike what the template asks: cargo filters by test name or by test target, so a focused run is `cargo test --test <file stem of tests/>` (for example `cargo test --test test_cli`) or `cargo test <name filter>`. `Dev` is `—` because a command-line program serves nothing. There is no end-to-end tooling beyond the tests that drive the binary.

To run a scenario, build first with `Build`, then call `target/release/rust-starter <subcommand> [options]` from the scenario's scratch folder, using the absolute path of the copy. The binary name follows the package name. Calling it with no subcommand is a usage error with a non-zero exit code (`tests/test_cli.rs` checks it). Configuration comes from variables prefixed `APP_` or from `-c <file>`; logs stay silent unless the program was built with `--features termlog`.

## Code map

- `src/` — the root binary: panic handlers, logger, the embedded default configuration, then a call into the `cli` crate.
- `cli/` — the clap `Cli` struct, the `Commands` enum and the dispatch of every subcommand, all in `cli/src/lib.rs`.
- `core/` — the commands themselves, in `core/src/commands.rs`.
- `utils/` — configuration, errors and logging shared by the other crates.
- `tests/` — integration tests that run the built binary.
- `docker/` — a Dockerfile for the program.
- `.github/workflows/` — continuous integration and the Docker image workflow.

## Ownership granularity

A story owns a new `core/src/<module>.rs` alone. These paths are shared by every subcommand, so a story touching any of them must run alone: `cli/src/lib.rs` (one enum and one match for all subcommands), `core/src/commands.rs`, `core/src/lib.rs`, the root `Cargo.toml` and `utils/`.

## Where each rule lives

- Validation of arguments: the clap derive in `cli/src/lib.rs`.
- Business rules: `core/src/`.
- Configuration: `utils/src/app_config.rs`, layered from the embedded defaults, then `APP_` variables, then `-c <file>`, then the arguments.
- Errors: `utils/src/error.rs`.
- Access and tenant filter: none exists in this starter; a program that needs them adds them in `core/src/`.

## Capabilities

| Capability | Brick | Notes |
| --- | --- | --- |
| Observability | slog | `utils/src/logger.rs`, discarded unless the `termlog` feature is on |
| Deployment | Docker image | `docker/Dockerfile`, built by a workflow under `.github/workflows/` |

## UI inventory

This starter has no screen: it is a command-line program.

## Known traps

- `Cargo.lock` is ignored by git, so a fresh clone resolves dependencies again and two clones may differ.
- `clap`, `log`, `serde` and `slog-journald` sit under the Linux-only target section of `utils/Cargo.toml`, the other dependencies of `utils` under `[dependencies]`; `utils` uses clap and serde, so the workspace builds on Linux only.
- `cli_match` in `cli/src/lib.rs` parses the arguments twice, once with `Cli::parse()` and once with `Cli::command().get_matches()`.
- The doc of the `--debug` flag in `cli/src/lib.rs` says "Set a custom config file", which is the wrong text.
- The `hazard` subcommand prints one of two lines at random: never assert on its output.
- The README mentions Failure for errors while the code uses thiserror.
- `Test` takes no path; see the paragraph under the commands.
