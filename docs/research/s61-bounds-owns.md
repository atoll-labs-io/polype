# Research — s61-bounds-owns

[Story](../stories.md)

## Structuring facts
- **The story assumes "the branch the story started from" is known to the hook; nothing records it.** `po-bounds.sh` reads no setting (`method/hooks/po-bounds.sh:15`, ADR-0024 consequences), the hook input carries no story or branch (ADR-0024 context), and `/po-research` forks from `origin/<Target branch>` or the local `Target branch` (`method/commands/po-research.md`, "The worktree" step 1): the upstream is set only in the first case (git's `branch.autoSetupMerge`). The hook has to derive the start branch; ADR-0038 decides how (main worktree's branch and its upstream).
- `Owns` is read from `HEAD:docs/stories.md` of the story worktree (`po-bounds.sh:57`); `docs/` is always writable (`:84`) and `git commit` is allowed on `story/*` (`:156-160`), so a committed edit of `docs/stories.md` widens the bounds — reproduced by the s50 review (`docs/reviews/s50-implementer-bounds.md:72`).
- An entry counts only if backtick-quoted (`po-bounds.sh:90`) and matches only as an exact path or a directory prefix (`:92-95`); text outside backticks is silently dropped, `*` is a literal character.
- The template writes `- **Owns**: <paths…>` with no syntax at all (`method/templates/stories.md:12`); `agentic-stories` says "as files or directories" (`method/skills/agentic-stories/SKILL.md:21`).
- ADR-0024 chose "`Owns` lu dans `HEAD:docs/stories.md`" (`docs/decisions/ADR-0024-po-bounds-trouve-la-story-par-son-worktree.md:23,31`); it is accepted and cannot be edited, so the new anchor needs ADR-0038 (reserved for this lane).

## Story
`po-bounds` must read a story's `Owns` where the story started, accept `*` and `**` globs, and refuse an entry it cannot read; the stories template and `agentic-stories` must state the entry syntax once. Criteria: `owns_are_read_where_the_story_started`, `owns_accept_globs`, `owns_syntax_is_written_once`, `bounds_refuse_an_entry_they_cannot_read`. Fixes the two majors of the s50 review (`docs/reviews/s50-implementer-bounds.md:72-77`).

## Current code
- `method/hooks/po-bounds.sh` (198 lines, bash + `jq` + `awk` + `grep` + `dirname`):
  - `story_of_dir` (`:24-33`) sets `TOP` (story worktree root) and `STORY`; refuses the main worktree (`:29`) and any non-`story/*` branch (`:31`).
  - `owns_line` (`:55-75`) runs `git show HEAD:docs/stories.md` in the worktree, then an awk scan: a heading `#… <id>` or `#… <id> …` opens the story, the next heading closes it, the first line matching `^[-*] \*\*Owns\*\*[[:space:]]*:` is printed (`:58-67`). Missing story / missing line → deny (`:68-72`). Sets `OWNS_LINE` to the whole line.
  - `check_write` (`:77-98`): resolve path, find story, `docs/*` → allow before reading `Owns` (`:84`), extract backticked entries (`:87-90`), none → deny "lists no path" (`:91`), match exact or prefix after stripping a trailing `/` (`:92-95`), else deny quoting the line (`:96`).
  - `check_write_qa`, `check_bash` and the dispatch (`:101-198`) do not read `Owns`.
- `tests/bounds.test.sh` (228 lines, 9 tests): fixture `lane()` (`:10-32`) commits a `docs/stories.md` with `s01-demo` (`` `src/app.sh`, `lib/` ``, French ` : ` separator), `s03-en` (`##` heading, `` `pkg/` ``), `s02-bare` (no Owns), then adds one linked worktree per story **from `main` after that commit** (`:28-30`) — the fork point is the stories commit. `test_bounds_deny_writes_outside_owns` (`:85-101`) checks the refusal names the path and quotes `**Owns** :` (`:94-95`) and that an *uncommitted* widening is refused (`:98-100`).
- `method/templates/stories.md:12` — `- **Owns**: <paths this story is allowed to change; stories sharing a path never run at the same time>`.
- `method/skills/agentic-stories/SKILL.md:20-21` — section `## Owns and contracts first`, "Every story declares Owns: the paths it is allowed to change, as files or directories."
- `tests/stories.test.sh:30-36` checks that section with `section_of` (`:8`) for two exact phrases.

## Attachment points
- `owns_line` (`po-bounds.sh:55-57`): replace `HEAD` by the fork commit.
- `check_write` (`:86-95`): replace the `grep -o` extraction and prefix match by a strict parser of the whole `Owns` value plus a matcher that knows `*`, `**`, trailing `/`.
- `lane()` in `tests/bounds.test.sh:10-32`: new stories for globs; bad-entry cases need their own story committed on `main` **before** their worktree is added (the fork point only sees what `main` held then).
- `method/templates/stories.md:12` and `SKILL.md:21`: the syntax sentence.

## Verified interfaces
- `git worktree list --porcelain` prints the main worktree first, with a `branch refs/heads/<b>` line (checked here: `worktree /home/lecrabe/dev/atoll/polype` / `branch refs/heads/main`); a detached main worktree prints `detached`, a bare one `bare`.
- This lane: `branch.story/s61-bounds-owns.remote=origin`, `merge=refs/heads/main`; `story/s61-bounds-owns@{upstream}`, `origin/main` and `main` all resolve to `9dbe221` — so a remote-forked lane does carry an upstream.
- `git merge-base HEAD <b1> <b2>` returns the best common ancestor of `HEAD` with either ref (checked in a scratch repo: with `old` behind `main`, the story's fork commit on `main` came back).
- Bash `[[ $s =~ $re ]]` with an unquoted variable regex matched `crates/core/Cargo.toml` against `^crates/[^/]*/Cargo\.toml$` (bash 5 here; `=~` exists since bash 3.2).
- Owns lines in Polype's own `docs/stories.md`: every one is `- **Owns** : ` followed by backticked entries separated by `, ` except `docs/stories.md:129` (a shipped M1 story: `` …, section « Installed files » de `…` ``), which a strict parser would refuse — harmless, that story never runs again. No current entry holds `*`, `?`, `[` or `{`.

## Traps
- Tests that run: `tests/bounds.test.sh` (all nine read `po-bounds.sh`), `tests/stories.test.sh`, `tests/research.test.sh:41-47` (template must keep `**Owns**`, `**Complexity scale**`, `` `s<number>-<short-slug>` ``), `tests/overlap.test.sh` (new method text must not share 8 words with Killer SaaS), `tests/gate.test.sh` copies every hook.
- `test_bounds_deny_writes_outside_owns:95` greps `**Owns** :` in the refusal: the message must keep quoting the raw line.
- The `docs/*` shortcut (`:84`) runs before `owns_line`: a story with an unreadable `Owns` can still write evidence under `docs/`. Keep that order.
- With the fork-point anchor, a human's `Owns` correction committed on `Target branch` after the lane started (as `101cf2a` did for s59) does not reach the running lane; the refusal message must say where it read `Owns` so a person knows to restart or merge.
- `s62-bounds-scan` depends on s61 and owns the same `po-bounds.sh`; it rewrites `check_bash` — stay out of it.
- `docs/installation.md:83-84` says "l'`Owns` committé" — still true (committed at the fork); it is outside `Owns`, leave it.
- `/po-drive` (`method/commands/po-drive.md:36`) and the review ownership check (`method/templates/review.md:16-20`) compare `Owns` paths by reading; with globs they must interpret them. Both are outside this story's `Owns`.
- No migration, no new screen, no API contract, no new dependency (still bash, `git`, `jq`, `awk`). The story touches an access boundary (what the implementer may write): that is the "authorization" signal, but the track is full anyway (complexity 3 > `Flow threshold` 2).

## Open questions
- Should a human correction of `Owns` on `Target branch` mid-lane be honoured (read at the tip instead of the fork)? The story says fork point; the plan follows it and ADR-0038 records the tip as turned down.
- The nautile project's implicit rule "owning `crates/x/src/` owns `crates/x/tests/`" (s50 review `:75`) is not a glob; `crates/*/tests/` covers it once written. Not handled implicitly.

## Complexity
Story 3 → 3. One script, two functions, a test fixture; the risk is the anchor choice (ADR-0038) and a regex conversion that fails closed.

## Split
Not needed.
