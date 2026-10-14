---
validated: yes
---
# Plan — s61-bounds-owns

[Story](../stories.md) · [Research](../research/s61-bounds-owns.md)

Branch `story/s61-bounds-owns`. Read `docs/research/s61-bounds-owns.md` first; this plan builds on it without repeating it. The structural choices are settled in `docs/decisions/ADR-0038-po-bounds-lit-les-owns-au-point-de-depart-de-la-story.md` (written by the planner, reserved number, outside `Owns` by Law 6); implement it as written.

## Story
`po-bounds` reads a story's `Owns` at the story's fork point, not `HEAD`; `Owns` entries may be globs (`*` one segment, `**` several); the entry syntax is stated in the stories template and in `agentic-stories`; an entry outside that syntax is refused by name. Criteria: `owns_are_read_where_the_story_started`, `owns_accept_globs`, `owns_syntax_is_written_once`, `bounds_refuse_an_entry_they_cannot_read`.

## Tasks
1. [x] **Fork-point anchor** in `method/hooks/po-bounds.sh`. Add a helper (e.g. `story_base`) called by `owns_line` (`:55-57`) in place of `HEAD`:
   - main worktree branch: the first `branch refs/heads/<b>` of the **first** block of `git -C "$TOP" worktree list --porcelain`; a first block that is `detached` or `bare`, or has no `branch` line → deny ("cannot find the branch story $STORY started from: the main worktree is …");
   - refs: `refs/heads/<b>`, plus `<b>@{upstream}` when `git rev-parse --verify -q` resolves it;
   - `BASE="$(git -C "$TOP" merge-base HEAD <refs…>)"`, failure → deny;
   - `git -C "$TOP" show "$BASE:docs/stories.md"`; the "no committed docs/stories.md", "not in" and "no **Owns** line" denials now say "at <short BASE> (where story/<id> started from <b>)".
   - Keep the `docs/*` shortcut of `check_write` (`:84`) **before** any of this.
   - Test: `test_owns_are_read_where_the_story_started` (see strategy) — fails if `HEAD` is read again (widening commit allowed), if the upstream is ignored (remote-forked lane refused), or if a detached root is accepted.
2. [x] **Strict `Owns` parser** replacing `:86-91`. Take the text after `**Owns**`, optional spaces and `:` from `OWNS_LINE`; consume it left to right: optional spaces, one `` `entry` ``, optional spaces, then `,` or end. Any other text (an unquoted path, a trailing `.`, free prose) → deny `the **Owns** line of $STORY holds an entry po-bounds cannot read: <that text> — <line>`. Each backticked entry is then validated, refused by name when: empty, starts with `/`, holds a `.`, `..` or empty segment (`//`), holds `?`, `[`, `]`, `{`, `}` or whitespace, or holds `**` that is not a whole segment (`a**`, `**b`, `***`). Validation runs over **all** entries before any matching: one bad entry refuses every non-`docs/` write, even one another entry would cover. No entry at all keeps today's "lists no path" denial.
   - Test: `test_bounds_refuse_an_entry_they_cannot_read`.
3. [x] **Glob matcher** replacing `:92-95`. Per entry: no `*` and no trailing `/` → exact match; trailing `/` without `*` → prefix match (today's behaviour); otherwise build an anchored ERE segment by segment: escape `. + ( ) | ^ $`, `*` → `[^/]*`, a `**` segment → `([^/]+/)*` when followed by more segments, `.*` when last; a trailing `/` on a glob means "anything under it" (`/.+$`). Match with `[[ $rel =~ $re ]]` (no `shopt`, no `globstar`, bash 3.2-safe). The refusal keeps quoting the raw `Owns` line (`tests/bounds.test.sh:95` greps `**Owns** :`).
   - Test: `test_owns_accept_globs` — fails if `*` crosses a `/`, if `**` does not, or if `.` stays a regex wildcard.
4. [x] **Script header** `po-bounds.sh:5-6`: say the `Owns` are read "at the story's fork point (ADR-0038)" and that entries follow the template's syntax. No test (comment only).
5. [x] **Syntax written once.** Replace `method/templates/stories.md:12` placeholder by one stating the syntax, and add the same clause to `method/skills/agentic-stories/SKILL.md:21` (section `## Owns and contracts first`, after "Every story declares Owns:", which `tests/stories.test.sh:34` pins). Both files carry verbatim: ``a file path, a folder ending in `/`, or a glob where `*` stays inside one path segment and `**` spans any number of segments``, plus that entries are in backticks, separated by commas, and that anything else is refused. Keep `**Owns**`, `**Complexity scale**` and `` `s<number>-<short-slug>` `` in the template (`tests/research.test.sh:44-46`). Write it in your own words (`tests/overlap.test.sh`).
   - Test: `test_owns_syntax_is_written_once` in `tests/stories.test.sh`.
6. [x] **Run.** `bash tests/run.sh bounds.test.sh stories.test.sh research.test.sh overlap.test.sh` after tasks 1-5, then the full suite once through `po-run` (`Full suite: execute-end`). `Typecheck: —`.

## Run interdicts
- `check_bash`, `check_write_qa`, `join_dir`, `QA_GIT_VERBS`, `resolve_path`, `story_of_dir` and the dispatch (`po-bounds.sh:23-52`, `:100-198`) end with an empty diff: s62 rewrites the Bash scan next.
- Empty diff for `method/agents/implementer.md`, `method/agents/qa.md`, `method/commands/`, `method/templates/review.md`, `method/AGENTS.md`, `docs/installation.md`, `docs/stories.md`, `docs/decisions/ADR-0024-*`, `.claude/`, `.polype/`, `bin/`, `tests/research.test.sh`, `tests/lib.sh`.
- No assertion of an existing test function in `tests/bounds.test.sh` or `tests/stories.test.sh` changes; `lane()` may gain stories and worktrees, nothing it holds today is altered.
- The script still exits only 0 or 2, reads no setting (`AGENTS.local.md` never opened), and uses no new tool: builtins, `git`, `jq`, `awk`, `grep`, `dirname` only — no `python3`, `realpath`, `shopt`.
- No `git checkout`/`switch`/`stash` run in the worktree itself; tests make their own repositories with `scratch_repo`/`mktemp -d`.

## The pivot
ADR-0038: the fork point is `git merge-base HEAD <main worktree branch> [<its upstream>]`. Ways it could be wrong:
- **The root is not on `Target branch`.** Law 4 keeps it there and `/po-drive`, `/po-ship` run there; compare with `method/commands/po-ship.md:43`. A root on another branch gives an older or foreign base; the story is then usually absent and the write refused — closed, but confusing. The denial must name `<b>` so a person sees it.
- **The lane forked from `origin/<b>` while local `<b>` lags** (`/po-research` step 1). Covered by adding `<b>@{upstream}`; the test pins it. A remote not set as upstream of `<b>` is not covered: the lane is then refused, never widened.
- **A human widens `Owns` on `Target branch` mid-lane** (as `101cf2a` did for s59): the lane does not see it — chosen by the story, recorded in ADR-0038. The refusal names `BASE` so the fix (merge `Target branch` into the story, or restart) is visible.
Secondary: the glob → ERE conversion must fail closed; an unescaped `.` widens silently, which the near-miss case of task 3's test catches.

## Files touched
- `method/hooks/po-bounds.sh`
- `tests/bounds.test.sh`
- `method/templates/stories.md`
- `method/skills/agentic-stories/SKILL.md`
- `tests/stories.test.sh`
- evidence: `docs/research/s61-bounds-owns.md`, `docs/plans/s61-bounds-owns.md`, `docs/verif/s61-bounds-owns.md`, `docs/decisions/ADR-0038-po-bounds-lit-les-owns-au-point-de-depart-de-la-story.md` (already written, do not edit)

## Test strategy
Four new tests (budget 25 per story: 4 used). All at the script layer, driving `po-bounds.sh` through `hook_input`/`write_status`/`bounds_stderr` (`tests/bounds.test.sh:34-45`) on real scratch repositories — no mock of git.

`tests/bounds.test.sh`:
- `test_owns_are_read_where_the_story_started` — in `lane()`: edit `$WT/docs/stories.md` to add `` `src/` `` to s01, `git -C "$WT" commit -qam widen`, then a write to `$WT/src/other.sh` → 2 and stderr names the short hash of the fork commit; `$WT/src/app.sh` still → 0. Upstream case: a bare clone as `origin`, `main` tracking `origin/main`, a story `s06-remote` with `` `rem/` `` pushed to `origin` from a second clone and fetched (local `main` now lags), `git worktree add -b story/s06-remote … origin/main`, then a write to `rem/x` → 0. Detached root: `git -C "$SCRATCH" checkout -q --detach`, a write to `$WT/src/app.sh` → 2.
- `test_owns_accept_globs` — a story `s04-globs` with `` `crates/*/Cargo.toml`, `crates/**/tests/`, `tools/**`, `cfg/*.sh` ``: allowed `crates/core/Cargo.toml`, `crates/a/b/tests/t.rs`, `crates/tests/t.rs` (`**` = zero segments), `tools/a/b/c`, `cfg/run.sh`; refused `crates/a/b/Cargo.toml` (`*` is one segment), `crates/core/src/lib.rs`, `cfg/runXsh` and `cfg/sub/run.sh` (`.` literal, `*` one segment).
- `test_bounds_refuse_an_entry_they_cannot_read` — for each bad Owns value, commit a fresh story on `main` **before** adding its worktree (the fork point must hold it): `src/x.sh` (unquoted), `` `/abs/x` ``, `` `../up/` ``, `` `a//b` ``, `` `a/**b` ``, `` `src/[ab].sh` ``, and `` `src/app.sh`, `src/x` `` followed by trailing prose; a write to a path the valid entry covers → 2, stderr names the bad entry text. A `docs/` write in the same worktree → 0.

`tests/stories.test.sh`:
- `test_owns_syntax_is_written_once` — `contains` the verbatim clause of task 5 in `method/templates/stories.md` and in the `Owns and contracts first` section of `SKILL.md` (via `section_of`).

Existing tests that must stay green unchanged: the nine of `bounds.test.sh` (notably `bounds_deny_writes_outside_owns`, `bounds_fail_closed`), `research.test.sh`, `stories.test.sh`, `overlap.test.sh`, `gate.test.sh`. No visual check.

## Done when
- The four criteria hold and their tests pass; `bash tests/run.sh` green through `po-run`, recorded in `docs/verif/s61-bounds-owns.md`.
- One commit on `story/s61-bounds-owns` carrying code, tests, research, plan, record and ADR-0038.
- Review with no open critical finding; ship squashes to `main` as `s61-bounds-owns: Des \`Owns\` qui ne s'élargissent pas et qui acceptent des globs`.
