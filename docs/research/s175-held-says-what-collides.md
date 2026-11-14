# Research — s175-held-says-what-collides

[Story](../stories.md)

## Structuring facts
- Root cause (owns): `po/src/next/wave.rs:55-58` finds the holder with a closure that drops the pair of entries `overlap` matched, and `Held` (`po/src/next/mod.rs:20-26`) has no field to carry them: only `story`, `reason`, `ref`.
- Root cause (framing): `po` never reads the start point. Stories come from the local `Target branch` only (`po/src/context/stories.rs:93-94`, `po/src/context/mod.rs:132`), and `wave.rs:61-64` makes every story that passes rules 1–3 and `Parallel` ready.
- `po state` takes `held` and `ready` from the same `wave::ready_and_held` (`po/src/state/mod.rs:83-84` → `po/src/next/mod.rs:92-98`): one fix covers both verbs.
- No story assumption is false. One trap the story does not say: `tests/driver-next-action.oracle.test.sh:286-290` compares `held` to an exact array, `s03-charlie` held for `owns`; it must gain the new fields (that file is in `Owns`).
- `po run` decides "work to do" from `next::ready` (`po/src/run/mod.rs:169-174`): a story held for `framing` no longer counts, which is the behaviour `/po-drive` has today.

## Diagnostic
Reproduction (scratch repository under `/tmp`, `po` built from this worktree into `/tmp/s175-po-target`): stories `s01-alpha` (`src/a/`, lane open) and `s02-bravo` (`src/a/x.txt`) committed, `origin/main` set there, then `s03-charlie` committed on `main` only. `po next` printed `{"ready":["s03-charlie"],"held":[{"story":"s02-bravo","reason":"owns","ref":"s01-alpha"}]}`: no entries nor path for `s02-bravo`, and `s03-charlie`, absent from `origin/main`, ready.

| Hypothesis | Refuting observation | Result |
| --- | --- | --- |
| H1 — the pair is computed then lost | `wave.rs:55-57`: `taken.iter().find(|holder| story.owns.iter().any(... overlap(mine, theirs)))` returns the holder only; `Held` has no slot | kept |
| H2 — the start point is read but ignored | `grep -n origin po/src` hits only `lanes.rs:57-59` (landed set) and `next/lane.rs:132-138` (fix-loop count); nothing reads `origin/<target>:docs/stories.md` | kept: never read |
| H3 — `po state` computes `held` apart from `po next` | `state/mod.rs:84` calls `next::held`, same function | discarded |

The oracle written for this plan fails on the current code for these two reasons (run on 2026-11-14: 0 passed, 3 failed).

## Story
`po next` and `po state` name, for a story held for `owns`, the two overlapping `Owns` entries and one path both cover (`null` when the overlap is kept by prudence only); a ready story whose id no heading of `docs/stories.md` on the start point names is held for `framing`, `ref` the start point, keeping its `Parallel` slot empty. The contract says so without changing its number. Criteria: `owns_collision_names_the_path`, `story_off_the_start_point_is_held`, `contract_says_the_new_fields` (review), `routing_cases_follow`.

## Current code
- `po/src/next/wave.rs:9-68` — the ready set: skip landed, laned, orphaned; then `dependency` → `decision` → `owns` → `parallel` → ready, `slots -= 1` and `taken.push(story)` (`:61-64`). `taken` starts with the stories of busy lanes (`:26-30`), ready stories join it in `docs/stories.md` order.
- `po/src/next/overlap.rs:4-31` — `overlap(a, b)`: segment walk; `**` on either side → true (`:14-16`), glob vs plain → `matches`, glob vs glob → true (`:22`). Private `segments` (`:34-40`, a trailing `/` adds `**`) and `matches` (`:43-57`).
- `po/src/next/mod.rs:20-26` — `Held { story, reason, reference }`, `reference` renamed `ref`; derives `Serialize, Clone, Debug, PartialEq`.
- `po/src/context/stories.rs:93-146` — `Stories::read` (`git show <target>:docs/stories.md`) and `Stories::parse`: a heading of two hashes or more, then a space, whose text starts with `s<n>-<slug>` (`story_id`, `:38-52`) opens a story. `story_id` stops at the slug's end, so `### s01-alphabet` never names `s01-alpha`.
- `po/src/context/lanes.rs:54-60` — the existing pattern for the origin copy: `rev-parse --verify -q refs/remotes/origin/<target>`, then use `origin/<target>`.
- `po/src/project.rs:92-94` — `on_target(target, path)` is `git show <ref>:<path>`, any ref.

## Attachment points
- `po/src/context/stories.rs` (or a new file in `po/src/context/`) — read the start point and the ids its `docs/stories.md` holds; `po/src/context/mod.rs:96-112` gains one field, filled after `stories` (`:132`).
- `po/src/next/overlap.rs` — a new function beside `overlap`, reusing `segments` and `matches`.
- `po/src/next/mod.rs:20-26` — `Held` gains the optional collision fields.
- `po/src/next/wave.rs:55-64` — the `owns` branch keeps the pair; the ready branch checks the start point.
- `tests/fixtures/driver-cases/ready-set.cases`, `a-wave.cases` — one case each; `tests/driver-next-action.oracle.test.sh:176-203` — expectation kinds.
- `docs/interface-agent.md:30` (common rules), `:86` (`held[].reason`).

## Verified interfaces
- `pub fn overlap(a: &str, b: &str) -> bool` — `po/src/next/overlap.rs:4`.
- `pub fn ready_and_held(context: &Context) -> Option<(Vec<String>, Vec<Held>)>` — `po/src/next/wave.rs:9`.
- `pub fn on_target(&self, target: &str, path: &str) -> Option<String>` — `po/src/project.rs:92`.
- `pub fn parse(text: &str) -> Stories`, `pub fn find(&self, id) -> Option<&Story>` — `po/src/context/stories.rs:100`, `:148`.
- Test helpers: `expect_held <id> <reason> [ref]` writes `held\t…` (`driver-next-action.oracle.test.sh:179`); `check_expectations` reads `kind id a b` (`:186`) and ignores an unknown kind silently (`case` without default, `:187-201`); replay floor `cases -ge 54` (`:317`); 54 cases today (`grep -c '^case_'`).
- The serialized key order of `Held` is `story, reason, ref` (field order).

## Traps
- `test_ready_and_held_say_why` (`driver-next-action.oracle.test.sh:268-291`) asserts `.held ==` an exact array: `s03-charlie` (`src/a/x.txt` vs lane `src/a/`) gains `entry`, `ref_entry`, `path`. Change it, and say so: the story changes that clause.
- `test_next_gives_one_action_per_lane` (`:258-265`) compares `po state`'s `held` with `po next`'s: both come from the same function, stays green.
- `tests/verbs-read-project-context.oracle.test.sh:20` deletes `ready` and `held` before comparing: the s174 oracle is unaffected, as long as no other key of `po state` moves.
- `tests/state-as-json.oracle.test.sh:157-194` logs every git call of `po state` and fails on `fetch|pull|push|ls-remote|commit|checkout|switch|stash|worktree add|update-ref`: the start point must be read with `rev-parse --verify` and `show` only.
- `po state` and `po next` must answer under a second on this repository (`state-as-json.oracle.test.sh:189-193`, `driver-next-action.test.sh:77-100`): one extra `rev-parse` and one `git show` at most.
- `test_fix_loop_counts_against_the_origin_target_branch` (`driver-next-action.test.sh:102-120`) sets `origin/main` ahead of `main`; its story has a lane, so it never reaches the framing rule.
- `po run` (`po/src/run/mod.rs:169-174`, outside `Owns`) answers `nothing-to-do` when the only candidates are held for `framing`; no fixture of `tests/run-from-outside*.sh` sets an origin ref.
- No `#[cfg(test)]` in the crate: every test is bash, through the binary. `tests/run.sh` builds `po` first.
- `method/commands/po-drive.md` is s173's; it must end with an empty diff here.

## Open questions
- Which pair is named when several overlap? Decided in the plan: the first holder in `taken` order (unchanged), then the first entry of the held story in its `Owns` order that overlaps one of the holder's, then the first such entry of the holder.
- Does a story held for `framing` also join `taken`, so a later story overlapping it is held for `owns` against it? `/po-drive` computes its batch before dropping the lane (`po-drive.md` `## The ready set` rule 3, then `### Preparing the lanes`), so today it does. The plan keeps that.
- Which overlaps yield `path: null`? The plan fixes the computable cases; a path the computation does not build (for example `**/x.md` against `src/*.md`) is `null`, which the criterion allows as prudence.

## Complexity
Story 3 → 3. Two local rules in one module, one read in the context, one contract paragraph, two fixture cases; the only spread is the exact-array assertion of s168's oracle.

## Split
—
