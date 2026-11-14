# Verification — s175-held-says-what-collides

[Story](../stories.md) · [Plan](../plans/s175-held-says-what-collides.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: b0b640111ee06b40c51d0dd0f87a99b6a3581ee2

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | builds `po` first (`cargo build --release --locked`), which is the crate's type check |
| Type check | — | no such command in this project (`Typecheck: —`); the build inside the unit suite stands for it |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |
| `tests/driver-next-action.oracle.test.sh` (s168's oracle, not this story's) | `test_ready_and_held_say_why`: the exact `held` array gives `s03-charlie` `entry`, `ref_entry`, `path`; new helper `expect_collision` and a `collision` kind in `check_expectations`; replay floor of `test_every_routing_case_is_a_fixture` raised from 54 to 56 | plan task 4: the story changes the clause these tests check (an `owns` hold now names its pair and a common path) and adds two routing cases |

`tests/held-says-what-collides.oracle.test.sh` is unchanged (cksum `3031440734 7311`).

## Not proven here
- `contract_says_the_new_fields` (`docs/interface-agent.md`): no script reads it; judged in review.
- `po run` treating a `framing`-held story as no work: not tested here (plan interdict: no `po/src/run/` change).
- No end-to-end, build or lint stage exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | df42d46f3c1a379323168d08f546a96184c87ac8 | 2026-11-14T09:04:09Z |
