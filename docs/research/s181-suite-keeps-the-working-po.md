# Research — s181-suite-keeps-the-working-po

[Story](../stories.md)

## Structuring facts
- Corrected assumption (#221): a detached HEAD alone does not break the quickstart. `git clone` of a source whose detached HEAD sits on a commit some local branch holds checks that branch out, and the test passes (reproduced below). It fails only when no branch holds HEAD, as with CI's pull-request merge commit or `git worktree add --detach <dir> origin/main` behind the local `main`. The oracle uses that case.
- Root cause #254: `tests/run.sh:11` exports `CARGO_TARGET_DIR=$root/po/target` for the whole run, and `lib.sh:7` points `$PO` at `$CARGO_TARGET_DIR/release/po`. `test_quickstart_runs_as_written` (`tests/readme-onboarding.test.sh:101-117`) leaves that variable alone, clones `file://$ROOT` (committed HEAD, `:114`) and runs `install --global`. That reaches `build_po`, which builds the clone's sources into `${CARGO_TARGET_DIR:-…}` (`bin/polype:868-869`), so HEAD's binary overwrites `$PO`.
- Aggravation: the overwritten binary survives later runs. The HEAD build is newer than the working tree's sources, cargo judges the target fresh by mtime, and `tests/run.sh:23` does not rebuild. A tree poisoned once stays that way until a `po/` source is touched (reproduced).
- Root cause #221: `tests/readme-onboarding.test.sh:114` clones `$ROOT` itself, so the clone inherits its HEAD. The README update block runs `git -C ~/src/polype pull` (`README.md:109`), and in a detached clone that stops with "You are not currently on a branch".
- The fix stays inside `tests/readme-onboarding.test.sh`. The quickstart gets its own `CARGO_TARGET_DIR` (the shape `tests/po-prebuilt-and-verified.test.sh:14` uses) and its own bare source repository, whose `main` holds `$ROOT`'s HEAD. `README.md`, `bin/polype`, `tests/run.sh` and `tests/lib.sh` stay unchanged.

## Diagnostic
Every reproduction ran in throwaway clones under `/tmp/s181-repro/`, never in the worktree.

**Reproduction #254.** In a clone of the worktree, `po/src/main.rs` was changed so the usage line holds `MARK-WORKTREE`, and a probe test `zz-probe.test.sh` checks that `"$PO"` prints it.
- `bash tests/run.sh zz-probe.test.sh` → `ok probe`.
- `bash tests/run.sh readme-onboarding.test.sh zz-probe.test.sh` → readme 6 ok, then `FAIL probe` with `PO is not the working tree's: {... "usage: po <state|next|...` (HEAD's text).

**Reproduction #221.** In a clone checked out detached on `a758e52` (a commit `story/s181` holds): `readme-onboarding` passed 6/6. After `git commit --allow-empty` while detached (no branch holds HEAD): 5 ok, `quickstart_runs_as_written` FAIL, output `Vous n'êtes actuellement sur aucune branche … git pull <distant> <branche>`.

**Hypotheses**
| # | Hypothesis | Refuted if | Result |
| --- | --- | --- | --- |
| H1 | The quickstart's `install --global` builds HEAD into the shared `CARGO_TARGET_DIR` | with `export CARGO_TARGET_DIR="$SCRATCH/target"` added to the quickstart, the probe still fails | **kept**. The first run with the export still failed, through the stale target of H2. After `touch po/src/main.rs`, probe alone → ok, then readme + probe → 7 passed. |
| H2 | The first failure with H1's fix comes from an earlier run's leftover, not from a second writer | `touch po/src/main.rs` does not turn the probe green | **kept** as an aggravation, not a second cause. Before the touch, the probe alone was red; after it, green. |
| H3 | Another test writes HEAD-built po into the shared target | a test that clones or copies `po/` with a real cargo and inherits `CARGO_TARGET_DIR` | **discarded**. `grep` for `clone`/`CARGO_TARGET_DIR`: `po-prebuilt-and-verified{,.oracle}.test.sh:14/25` set their own target and use a cargo double. `local-copy-checksums.test.sh:16-31` copies `bin/` and `method/` without `po/`. The other clones (`bounds*`, `throwaway-zone-holds`, profile tests) are not of Polype. |
| H4 | #221 comes from the detached HEAD itself | the quickstart passes from a detached HEAD | **refined**. It passes when a branch holds HEAD and fails when none does (reproduction above). |

Root cause shown for both: see Structuring facts.

## Story
- `working_po_survives_the_suite`: after the readme test, `$PO` is the binary built from the working tree, even when `po/` differs from HEAD.
- `quickstart_runs_from_a_detached_head`: the quickstart test passes from a detached checkout.
- `quickstart_still_runs_as_written`: the README quickstart commands still run as written, and no README line changes.

## Current code
- `tests/run.sh:8-28` exports `CARGO_HOME`, `RUSTUP_HOME`, `CARGO_TARGET_DIR` (`:11`), `POLYPE_PO_FETCH=false` (`:14`) and a temp `CLAUDE_CONFIG_DIR` (`:16-19`). It builds po once with `--locked` (`:23`) and copies it to `$CLAUDE_CONFIG_DIR/polype/po` (`:27`).
- `tests/lib.sh:5-7`: `ROOT` comes from the file's location, and `PO` is assigned outright (no `${PO:-}`). `scratch_repo` is at `:47-54`.
- `tests/readme-onboarding.test.sh:71-125`: it extracts the 4 fenced blocks of `## Démarrage rapide` (`README.md:65-117`) and checks their shape (`:73-99`). Then it runs clone + first sh block + update block with `bash -e` under a scratch `HOME` and `CLAUDE_CONFIG_DIR` (`:101-117`), with only the clone URL swapped (`:114`, checked once at `:115`). The rest of the test is `:118-124`.
- `bin/polype:885-926` `lay_po`: with no `PO_SUMS` entry for the platform, it falls back to `build_po` (`:897-900`). `build_po` (`:857-883`) builds `$base/po` into `${CARGO_TARGET_DIR:-$base/po/target}` and copies it to `po_path`.
- `.github/workflows/ci.yml:15-20` checks a PR's head out as a branch (`ref: ${{ github.head_ref }}`) to work around #221.

## Attachment points
- `tests/readme-onboarding.test.sh:101-102` (after `scratch_repo`, beside `export HOME`): the target dir export and the bare source repository.
- `tests/readme-onboarding.test.sh:114-115`: the substituted URL and its count check.

## Verified interfaces
- `git init --bare -b main <dir>` + `git -C <dir> fetch -q "$ROOT" HEAD:refs/heads/main` works from a worktree, a branch or a detached HEAD. Tried in `/tmp/s181-repro/post`: oracle 3/3 and readme 6/6 green.
- `README.md:109`: `git -C ~/src/polype pull` is a line of its own, which the oracle's third test matches.
- A cold `cargo build --release --locked` of po in a fresh target dir took 6.5 s wall here (3 deps: serde, serde_json, chrono, `po/Cargo.toml`).

## Traps
- **Shallow CI checkout**: `actions/checkout` fetches depth 1. The current test already clones that shallow checkout and passes on push. Fetching from it into a bare repository behaves like the clone, but this is not proven on CI (open question 1).
- **Cost**: the quickstart now does a cold build each run (≈ 6 s here, more on a 2-core runner). Each oracle test runs a nested suite on a copy: a cold build by the copy's `run.sh`, then the quickstart's. Oracle + readme took 70 s wall here.
- **Poisoned targets already on disk**: a `po/target` that a pre-fix run has already overwritten stays stale after the fix (H2) until a `po/` source is touched or `cargo clean` runs. New worktrees start clean.
- `tests/readme-onboarding.test.sh` clones **committed** HEAD: the implementer commits before the full suite (story note, #254).
- The nested runs in the oracle must not inherit the outer `CARGO_TARGET_DIR`, or they would build into this tree's `po/target`. The oracle exports `$SCRATCH/target` before it runs them.
- `.github/workflows/ci.yml:17-20` becomes unnecessary once #221 is fixed. It is out of `Owns` (s182 owns it) and stays as is.

## Open questions
1. Does `git fetch` from CI's shallow checkout into a bare repository pass on `ubuntu-latest`? The plan keeps the fetch and says what to do if the `suite` check fails there.
2. Should `tests/run.sh` also protect `$PO` against any future installer run from another source (a copy outside the target dir)? Nothing needs it today (H3), so the plan leaves `run.sh` alone.

## Complexity
Story 2 → 2. One test function changes in about five lines. The weight is in the oracle (a nested suite on a copy) and its run time.

## Split
—
