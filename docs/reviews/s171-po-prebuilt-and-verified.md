# Review — s171-po-prebuilt-and-verified

[Story](../stories.md) · [Plan](../plans/s171-po-prebuilt-and-verified.md) · [Verification](../verif/s171-po-prebuilt-and-verified.md)

Method version: 0.2.0

Diff reviewed: `git diff main...story/s171-po-prebuilt-and-verified`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: c2819ec630b7ae6e3917139d5364fef11193038a

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s171-po-prebuilt-and-verified` and checked each path against the story's `Owns`.
- [x] Every path is inside `Owns` (`bin/po-release`, `.github/workflows/release.yml`, `bin/polype`, `docs/installation.md`, `docs/ci.md`, the two `tests/po-prebuilt-and-verified*` files, `tests/run.sh`). The pipeline evidence (research, plan, verif) is in scope by construction. So is `docs/decisions/ADR-0121-po-precompile-plateformes-et-somme-attendue.md`: the diff adds it (status A) and the plan names it.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. s173 is merged. s175 is still running and owns `po/src/next/`, `po/src/context/`, `docs/interface-agent.md` and some tests, so nothing is shared.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s171-po-prebuilt-and-verified` → exit 0, so I reused the record. Outside `docs/`, the code matches both the `Tree:` 7518083… and the run tree 633b495…. The Unit suite `bash tests/run.sh` exited 0, with curl/wget stubs that log. The project has no type check (`Typecheck: —`), no E2E and no build. I read the record's "Not proven here" section, and its items are carried below.
- [x] `po-gate qa-current`: not required. `QA stage: —` means the story does not go to QA.

## Plan
- [x] Tasks 1–8 are all present. `cmd_init` reaches `lay_po`/`clean_machine_files` through `cmd_install`, as the plan says. Nothing outside the plan was changed.
- [x] Run interdicts, one by one:
  - `po/`, `method/`, `ci.yml`, `tests/lib.sh` and the existing test files are untouched. `tests/run.sh` gains only the export and its comment.
  - `PO_SUMS` is empty.
  - No new test reaches the network: every installer run uses a `POLYPE_PO_FETCH` double.
  - The SHA-256 never comes from `cksum`.
  - The cleanup is limited to plain files directly under `<common>/polype/`, and skips global runs.
  - The ADR-0121 body is as added.

## References
- [x] `PO_SUMS` lookup (`po_expected_sum`) and the line `bin/po-release` writes (`<sum>  <name>`) agree. `po_platform` in `bin/polype` and the mapping in `bin/po-release` match line for line. The `ci.yml` checkout pin is the same commit (11d5960…). `po/Cargo.toml` version 0.2.0 = `POLYPE_VERSION`.
- [x] The kept-files list matches every `dir.join(` under `po/src/run/` (session.rs:36,94, mod.rs:93,245). Nothing else in `method/` or `po/src` writes under `<git common dir>/polype/`.
- [x] Probe in a throwaway repo: `git check-ignore -q -- .git/polype/d-0000.json` exits 1. So `po inbox` refuses an inbox set directly at `.git/polype`, and the cleanup cannot delete decision files there.
- [x] Values: curl `--proto =https` does not restrict redirect protocols, but the SHA-256 check covers integrity whatever the transport. `wget` has no timeout. Neither is graded.

## Rules
- [x] `AGENTS.md` conventions respected: commit and comments in English, docs in French, bash tests through `tests/lib.sh` helpers.
- [x] No accepted ADR contradicted: ADR-0105 (the workflow only calls the script and `gh`), ADR-0115, ADR-0117, ADR-0121.

## Tests
- Oracle: `po-gate oracle-intact s171-po-prebuilt-and-verified` → exit 0
- [x] Floor: `po-gate floor-guard s171-po-prebuilt-and-verified main` → 0, nothing lowered. `po-gate oracle-intact` → 0, and the record has no oracle-changes rows.
- [x] The assertions pin down the five testable criteria. Fixtures are throwaway copies with cargo and fetch doubles. None of the six empty shapes: the tamper path hashes the real altered bytes, and the cleanup test plants a tracked file and an inbox.
- [x] 8 tests, within `Test budget` 25.
- [x] Bite:
  - The refusal at `bin/polype:913` replaced by `if false` → 1 failing test (`installer_downloads_and_verifies`). Undone, `git diff --exit-code bin/polype` clean.
  - The kept-files list at `:934` with `lead-session.json|run.lock` removed → 1 failing test (`upgrade_cleans_what_the_old_version_left`). Undone, clean.
  - The cleanup's version guard at `:948` replaced by `true` → **0 failing tests**, across both story files. Undone, clean. This is finding 2.
- [x] No existing test is made useless. `state-as-json*` still greps `po missing`, which is unchanged.

## Neighbours
- [x] `build_po` is now called only from `lay_po`, and its three messages are kept word for word. `tests/state-as-json*.test.sh` grep `po missing`, still printed. `cmd_remove --global` wipes `state_dir`, so `po.sum` goes with it. `is_payload_state_file` gains `po.sum`, which the payload update test covers.

## Lenses
Lenses run: none. No path or content trigger of the table matches: no auth or route path, no lockfile or dependency manifest change, no server-side code. I read the download-and-verify chain anyway under References.

## Findings
- major — bin/polype:902-904, docs/ci.md:17 — The installer picks the binary by version alone. Once `PO_SUMS` holds sums for a version, an install or update from a clone lays the tagged release binary, even when the clone's `po/` sources have moved on under the same `POLYPE_VERSION`.
  - The prebuilt path prints nothing. `check` compares only version strings, so it stays silent too.
  - A po built from newer sources is replaced on the next update, because its sum differs from the published one.
  - This repository has not bumped `POLYPE_VERSION` since s36. Seven commits have changed `po/src` at 0.2.0, and s175 is changing it now. In practice, the method laid from `main` would run beside an older `po`.
  - `docs/ci.md` says to bump both versions at release time. Nothing says a change to `po/` needs a new version before its sums can be trusted to match the sources.
  - Nothing breaks today because `PO_SUMS` is empty. It starts with the first sums commit.
  - Options to choose from: require a version bump for any `po/` change once a release exists, or have a run from a clone prefer its own sources.
- major — bin/polype:944,948 — Two guards in `clean_machine_files` are not tested.
  - The first runs the cleanup only when the po laid is this installer's version. Replacing it with `true` fails 0 tests. Without it, an update that could not lay the new po (no cargo, no network, refused download) would delete the files the older po still in place reads.
  - The second, `po_refused = no`, is not exercised either: the tamper scenario never checks the machine files.
  - Each guard needs one test in the oracle's fixture shape.
- minor — docs/installation.md:557 — "`po not verified` disparaît au prochain `update`" is only true when that update lays po.
  - That needs a clone with `cargo`, or a published sum.
  - An update run from the payload (no sources) with `PO_SUMS` empty prints `no po sources`, keeps `po.sum` absent, and the line stays.
- minor — .github/workflows/release.yml:30 — `gh release upload` has no `--clobber`, so rerunning a failed matrix job after a partial upload fails on the asset already present.

## Not verified
- A real release and download: no tag exists and `PO_SUMS` is empty. Whether `ubuntu-24.04-arm` and `macos-latest` carry `cargo` and `gh`, and whether `gh release upload` accepts `dist/po-*`, will only show on the first pushed tag. A person should push a test tag on a fork and watch the three jobs.
- macOS: `po_platform`, `shasum -a 256` and `bin/po-release` (run there under bash 3.2) only ran on Linux x86_64. Run `bin/po-release` on an Apple Silicon Mac.
- glibc compatibility of the `ubuntu-latest` binary on older distributions: not probed. Documented with `POLYPE_PO_FROM_SOURCES=1`.
- `docs_say_what_is_verified`, judged by reading: `docs/installation.md` says where the binary comes from, what the sum proves and does not prove, the fallback order and how to force sources. `docs/ci.md` says how to publish. Judged adequate, apart from the gap named in the first major finding. A candidate for a `po-eval` control arm (#208).
- Nothing ties the kept-files list (`is_po_machine_file`) to `po/src/`. A later story adding a machine file must update it by hand.
- The curl redirect protocol and wget's lack of timeout were read, not exercised.

Max severity: major
Ship allowed: yes
