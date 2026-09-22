# Verification — s42-next-forge-profile

Tree: c9754924b1ad5f1dfdc0ad2d340864617dbe28e2

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Focused tests | `NEXT_FORGE_SRC=<task-1 clone> bash tests/run.sh next-forge-profile.test.sh` | exit 0 · 4 passed · 0 skipped | 2026-09-22T19:44Z |
| Grounding over the network | `test_next_forge_profile_is_grounded_in_the_real_repository` called directly, `NEXT_FORGE_SRC` unset | exit 0, no "not reachable" message: cloned and fetched f189de79ceef7c1ef69f61f12e272f99b4cdb699 | 2026-09-22T19:45Z |
| Unit suite | `bash tests/run.sh` | exit 0 · 222 passed · 0 failed | 2026-09-22T19:46:15Z |
| Lint | `bin/po-lint` | exit 0 · no breach in 23 file(s) of method/ | 2026-09-22T19:46Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project | — |
| Build | — | no such command in this project | — |

An earlier focused run of `next-forge-profile.test.sh profile.test.sh lint.test.sh` failed 2 tests (EXIT traps naming local variables); after the fix, the focused file above passed, and `profile.test.sh` and `lint.test.sh` were then covered by the full suite.

## Not proven here
- The full-suite run does not print whether the grounding test cloned or skipped (run.sh shows output only on failure); the direct network run above is the proof that it cloned, and the focused run proves it against the task-1 clone.
- The grounding check verifies paths, root scripts, commit, origin and licence mechanically; the prose claims (what each package does, the bricks named) were read in the clone by hand, not tested.
- Formatting at commit: no formatter configured.

Verification status: complete
