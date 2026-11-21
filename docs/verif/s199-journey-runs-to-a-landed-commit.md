# Verification — s199-journey-runs-to-a-landed-commit

[Story](../stories.md) · [Plan](../plans/s199-journey-runs-to-a-landed-commit.md)

Tree: 79618e730d9fa2d031c7d9d85b625cb1892e40cc

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

## Not proven here
- Cost: `bash tests/run.sh journey-runs-to-a-landed-commit.oracle.test.sh journey-runs-to-a-landed-commit.test.sh` took 9.1 s wall clock (po already built), against the plan's 30 s estimate and 90 s ceiling; no build, one `polype-journey.*` folder per journey, none left under /tmp after the runs.
- Guards bitten on a copy of the tree outside the worktree, each removed alone: missing answer, unknown action, repeat guard, pre-commit probe, audit, protocol rule, token removal, wave cap, `ask`, warnings, unreadable `po next`, "nothing moves", audit inside a run, EXIT trap, the wait between two reviews, and cargo outside the installer (after an assertion was added for it): each made its test fail.
- Not bitten: the TERM trap (`trap 'exit 143' TERM`). Bash 5.3 runs the EXIT trap and exits 143 on a fatal TERM by itself, so `folders_go_on_failure_and_interrupt` passes with or without it; the trap stays as the plan's interface asks. The HUP and INT traps have no test either.
- The reply checks inside the ship answer (`effective`, `landed`, `merged`, `filed`/`no-tracker`, `cleaned`) only sharpen a stop message; without them the repeat guard still stops a run (plan, test strategy).
- That a forged step would be refused, that a model follows the prose, design, QA and the stops that go to a person, and that the gh double behaves like GitHub: see `docs/harnais.md`, `## Le parcours rejoué`.
- A SIGKILL leaves its `polype-journey.*` folder (about 2 MB).
- Full suite through `po-run`: 946 passed in 464 s. Afterwards no `polype-journey.*` under /tmp. One folder of this story was left, `tmp.PbouR9wApB`, by an earlier focused run whose EXIT trap named a local out of scope (fixed before the record; three runs since left nothing), and was removed by hand. One `tmp.*` holding a project with `docs/brief.md` appeared during the suite, from another story's test; it was left in place.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 8a78bacf41ac9f049a57342ba7d2cd5975c8c812 | 2026-11-21T01:53:04Z (464s) |
