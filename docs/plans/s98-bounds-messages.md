---
validated: yes
---
# Plan — s98-bounds-messages

[Story](../stories.md) · [Research](../research/s98-bounds-messages.md)

Branch `story/s98-bounds-messages`. Read `docs/research/s98-bounds-messages.md` first. This plan builds on it without repeating it. Decision: ADR-0072 (`docs/decisions/ADR-0072-l-implementer-explore-un-depot-jetable-du-repertoire-temporaire.md`, already written by the planner).

## Story
Three defects of `po-bounds`:
- `every_refusal_is_readable`: no refusal shows the raw `\036` byte, including a substitution in an option name.
- `named_fd_redirections_are_read`: `{fd}>target` is read as a redirection.
- `implementer_explores_a_throwaway_clone`: in mode `implementer`, a throwaway repo under the temp dir accepts reading verbs and `checkout`, and nothing leaves it for the worktree. ADR-0072 replaces ADR-0050 in part. `implementer.md` and `installation.md` forbid checkout only in the story worktree.

## Tasks
1. [x] **Readable refusals, one place.** In `method/hooks/po-bounds.sh`, make `deny()` (`:53`) pass its message through the `\036` → `<substitution>` replacement before printing. Use a local `msg="$*"` and the local-variable pattern of `readable()` (`:299`). Keep `readable` itself; the two existing calls (`:633`, `:648`) may stay. In `check_temp_paths` (`:633`) and `check_redirects` (`:648`), change "a path the reviewer cannot read" to "a path po-bounds cannot read", since the implementer now reaches them. Keep the phrase `redirects to <substitution>`. *Test able to fail:* `test_every_refusal_is_readable`.
2. [x] **Named fd.** In `lex_command`, the redirection branch (`:538`) also drops an unquoted, substitution-free word matching `^[{][A-Za-z_][A-Za-z0-9_]*[}]$` before `<` or `>`, as it drops `^[0-9]+$`. Bracket expressions, not `\{`: POSIX awk. Leave `<<` and `<<<` alone (ADR-0072, Neutral). Update the lexer comment at `:44` ("its fd number included" → "its fd number or `{name}` included"). *Test able to fail:* `test_named_fd_redirections_are_read`.
3. [x] **Isolate the implementer tests from the temp zone.** In `tests/bounds.test.sh`, `lane()` exports `TMPDIR` to a dedicated `mktemp -d` that does not hold `$SCRATCH` (create it before `$SCRATCH` is used, and extend the EXIT trap to remove it). This keeps the scratch checkout out of the new implementer zone. Then `reviewer_lane`'s own `mktemp -d` and `export TMPDIR="$TMPROOT"` still work, and its trap also removes the lane's temp dir. No existing expectation changes. This touches an existing test only because the story adds a temp zone to mode `implementer`. Say so in the commit. *Test able to fail:* the existing `test_bounds_still_catch_real_verbs` (`:337`), `test_bounds_ignore_heredoc_bodies` (`:308`) and `test_bounds_ignore_quoted_arguments` (`:322`), which expect checkout from `$SCRATCH` → 2.
4. [x] **Checkout in a throwaway repo, nothing out.** In `check_bash`:
   - `:673`: call `temp_root` for every mode but `qa`.
   - In the implementer branch (`:748-767`), compute once per git call whether `dir` is a throwaway repo: `dir` known and existing, `try_story_of_dir "$dir"` false, `in_temp_zone "$dir"` true. A story worktree is judged first.
   - Move `checkout` out of `switch|checkout|stash|push`. Refuse it unless the call runs in a throwaway repo, with a message naming the story worktree and the temp dir, e.g. `git checkout is forbidden to the implementer outside a throwaway repo of the temp dir (${TMP_ROOT:-no usable temp dir}): $cmd`.
   - For every git call in a throwaway repo, after the verb rules, run `check_temp_paths "$dir" "$j"` and `check_redirects "$cur"`.
   - All other implementer rules stay as they are.
   - Update the header comment (`:9-12`) to match.
   
   *Test able to fail:* `test_implementer_explores_a_throwaway_clone` (behaviour half), plus the existing `test_bounds_deny_forbidden_git_verbs` (`:103`: `git -C $WT checkout -b x` → 2).
5. [x] **Texts and ADR links.**
   - `method/agents/implementer.md:23`: "never checkout, switch or stash" → scope the ban to the story worktree, e.g. "never checkout, switch or stash in the story worktree; to read another version of a source, clone it under the temp dir, where `git checkout` is allowed as long as every path and redirection stays under it (ADR-0072)".
   - `docs/installation.md`, section "Le hook des bornes de l'implementer":
     - Take `checkout` out of the "partout" list.
     - Add a line saying that `git checkout` is allowed only in a throwaway repo under `${TMPDIR:-/tmp}` (same definition as the reviewer's). Every path named and every redirection target of a git call there must stay under the temp dir, and a local clone run from there uses `file://` (ADR-0072).
     - Keep every phrase `tests/installer.test.sh:186-187` pins.
   - `docs/decisions/ADR-0050-…md` frontmatter: `superseded-by: [ADR-0072]`.
   - `docs/decisions/ADR-0052-…md` frontmatter: `superseded-by: [ADR-0053, ADR-0072]`.
   - Bodies and `status: accepted` unchanged in both.
   
   *Test able to fail:* `test_implementer_explores_a_throwaway_clone` (text half).
6. [x] **Story tests** in a new `tests/bounds-messages.test.sh` (header `# s98 — the last po-bounds messages.`). It has its own small helpers, because `run.sh` sources one test file at a time: a scratch lane with a committed `docs/stories.md` holding one story with an Owns line, a linked `story/<id>` worktree, a `TMPDIR` of its own outside `$SCRATCH`, and a `hook_input`/status/stderr helper per mode. Three tests named after the criteria:
   - `test_every_refusal_is_readable`: for each of reviewer `git -C <probe> log --$(echo o)=/etc/passwd` (m1), qa `git $(echo log)`, reviewer `git -C /etc $(echo log)`, reviewer `git -C /nonexistent $(echo log)` and reviewer `git -C <probe> $(echo log) /etc/x`, assert exit 2, no `\036` in stderr, and `<substitution>` in stderr.
   - `test_named_fd_redirections_are_read`: in qa mode, `git -C $WT symbolic-ref HEAD {fd}>/dev/null` → 0. Today `{fd}` counts as a second non-option and the call is refused as "with a target". `git -C $WT symbolic-ref HEAD 2>/dev/null` → 0, as a control.
   - `test_implementer_explores_a_throwaway_clone`, behaviour: `git clone -q $SCRATCH $TMP/clone` and a linked `git -C $SCRATCH worktree add --detach $TMP/main-wt`, both set up directly. In mode implementer:
     - → 0: `git -C $TMP/clone checkout -q main`, `git -C $TMP/clone checkout -b x`, `cd $TMP/clone && git log --oneline`, `git -C $TMP/clone show HEAD:docs/stories.md > $TMP/out.md`.
     - → 2: `git -C $WT checkout main`, `git -C $SCRATCH checkout main`, `git -C $TMP/main-wt checkout main`, `git -C $TMP/clone checkout main -- $WT/src/app.sh`, `git -C $TMP/clone show HEAD:docs/stories.md > $WT/src/app.sh`, `git -C $TMP/clone diff --output=$WT/x`, `git -C $TMP/clone switch main`.
     - Text half: `contains` the new phrase in `implementer.md` and the new line in `installation.md`. `implementer.md` no longer holds the unscoped `never checkout, switch or stash.`. ADR-0072 `supersedes` names ADR-0050 and ADR-0052. Both of those name ADR-0072 in `superseded-by` and stay `status: accepted`.
   
   Then run `bash tests/run.sh bounds-messages.test.sh bounds.test.sh installer.test.sh post-m7-texts.test.sh defect-and-routing-paths.test.sh`.
7. [x] **Full suite**, once: `po-run --story s98-bounds-messages --label 'Full suite' -- 'bash tests/run.sh'`. `Typecheck` is `—`: say so in the record.

## Scene viewpoints
—

## Run interdicts
- `.claude/` and `.polype/` end with an empty diff (installed copies, refreshed after ship).
- `method/commands/po-execute.md` and `tests/defect-and-routing-paths.test.sh` end with an empty diff: s96 already scoped the prompt.
- ADR-0050 and ADR-0052: only their `superseded-by` line changes. `git diff` shows no other line of either. ADR-0072 is not edited by the implementer beyond fixing a factual mismatch with the code, which is reported.
- Mode `qa` behaviour is unchanged, apart from the readable messages and `{fd}`: `temp_root` is not called for it, and its allowlist is untouched.
- Mode `reviewer` rules are unchanged: `:683-747` keep their logic. Only the wording of the two "the reviewer cannot read" messages changes.
- No existing `expect` value in `tests/bounds.test.sh` changes. Only `lane()`/`reviewer_lane` setup and traps do.
- `lex_command` stays POSIX awk: no `\{` interval, no gawk-only function.
- No file outside the story's Owns and `docs/`.

## The pivot
The pivot is the zone rule: the implementer's `checkout` is allowed only where `in_temp_zone` holds and the dir is not a story worktree, and every git call there is held to the temp-dir path rule. Ways it could be wrong:
- **A real checkout counts as throwaway.** That happens when the project or its main checkout lives under `$TMPDIR`, as `$SCRATCH` does in the tests. Compare: task 3's isolation, and the `git -C $SCRATCH checkout main` → 2 case run with a `TMPDIR` that does not hold `$SCRATCH`.
- **The path rule refuses legitimate exploration.** `cd /tmp && git clone /local/path x` is now refused. Compare against ADR-0072's accepted cost. A reviewer who finds a common exploration form refused should report it as a hook defect (ADR-0052).
- **Centralizing in `deny` hides a byte that is not the marker.** A command the agent typed with a literal `\036` would print `<substitution>`. That is harmless, but it is not literal. Compare `$cmd` in the message with the input.

## Files touched
`method/hooks/po-bounds.sh`, `method/agents/implementer.md`, `docs/installation.md`, `tests/bounds.test.sh` (setup only), `tests/bounds-messages.test.sh` (new), `docs/decisions/ADR-0050-po-bounds-lit-un-heredoc-comme-bash-le-lira.md` and `docs/decisions/ADR-0052-po-bounds-est-un-garde-fou-contre-les-erreurs.md` (frontmatter only). Already written by the planner: `docs/research/s98-bounds-messages.md`, this plan and ADR-0072. `docs/verif/s98-bounds-messages.md` comes from the run.

## Test strategy
Automated tests, at the one layer this repository has (bash tests that feed JSON to the hook): three new tests, one per criterion, in `tests/bounds-messages.test.sh`. Each one bites:
- drop the filter in `deny` and `test_every_refusal_is_readable` fails;
- drop the `{name}` branch and the qa `symbolic-ref … {fd}>/dev/null` case fails;
- drop the zone check and the throwaway-checkout case fails; drop the path or redirect checks in the zone and the `$WT` targets pass.

Existing tests stay unchanged in their expectations: `test_bounds_deny_forbidden_git_verbs`, `test_bounds_still_catch_real_verbs`, `test_refusal_messages_are_readable`, `test_redirections_are_not_git_paths` and `test_installation_doc_lists_the_hook_refusals` guard the rules that must not move. Total new tests: 3, within `Test budget` 25.

No visual checks: the story has no surface.

## Done when
- The story's commit carries the hook, texts, tests, the ADR-0050/0052 links, ADR-0072, research, plan and record.
- `bash tests/run.sh` is green in a `po-run` row.
- The review has no open critical finding.
- After ship, the installed copies are refreshed by the usual "Refresh the installed method" commit, which is not part of this story.
