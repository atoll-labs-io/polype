# Research — s98-bounds-messages

[Story](../stories.md)

## Structuring facts
- Root cause 1 (raw byte): `deny()` at `method/hooks/po-bounds.sh:53` prints its arguments as they are. The lexer marks a substitution with `\036` (`SM`, `:557`, written at `:328`), and that byte stays in `vals[]`. `readable()` (`:299`) is applied at two sites only (`:633`, `:648`). Every other refusal that prints a word of the command prints the byte: `:636` (m1, `$a`), the verb at `:586`, `:633`, `:636`, `:648`, `:650`, `:653`, `:732`, `:746`, and `:577`, `:581`, `:594`, `:611`.
- Root cause 2 (`{fd}`): the lexer drops the word before `<` or `>` only when it is all digits (`:538`, `wv[sp] ~ /^[0-9]+$/`). `{fd}` goes through `endword` and becomes a `u` word of the command.
- Root cause 3 (checkout): in mode `implementer`, `:750` refuses `switch|checkout|stash|push` whatever directory git runs in. Nothing in that branch looks at the temp zone, and `temp_root` is called for the reviewer only (`:673`).
- No story assumption is false. The raw-byte defect is wider than m1 says: ten more sites print the byte, not one.
- Trap that sizes the work: in `tests/bounds.test.sh`, `lane()` builds `$SCRATCH` with `mktemp -d` under the default `/tmp`, and the implementer tests leave `TMPDIR` unset. A temp zone for the implementer turns `$SCRATCH` into a throwaway repo, and four existing expectations of `git checkout` → 2 (`:319`, `:330`, `:340`) would then flip.

## Diagnostic
Reproduced on the code as it stands. The hook was fed JSON from a `mktemp -d` outside the worktree, with `TMPDIR` set to it and `git init <T>/probe`. Output went through `cat -v`, where `^^` is `\036`.

| Run | Mode | Command | Output |
| --- | --- | --- | --- |
| 1 | reviewer | `git -C <T>/probe log --$(echo o)=/etc/passwd` | `git log names --^^=/etc/passwd, which lies outside the temp dir` (m1) |
| 2 | qa | `git $(echo log)` | `git ^^ is forbidden in mode qa` |
| 3 | reviewer | `git -C /nonexistent $(echo log)` | `git ^^ runs in an unknown or missing directory` |
| 4 | reviewer | `git -C /etc $(echo log)` | `git ^^ runs in /etc, outside a story worktree…` |
| 5 | reviewer | `git -C <T>/probe $(echo log) /etc/x` | `git ^^ names /etc/x…` |
| 6 | lexer | `git -C /x log {fd}>/dev/null` | `cgit␟u-C␟u/x␟ulog␟u{fd}␟r/dev/null` (`{fd}` is a word) |
| 6b | qa | `git -C /x symbolic-ref HEAD {fd}>/dev/null` | `git symbolic-ref with a target writes a ref` (the control `2>/dev/null` passes) |
| 7 | implementer | `git -C <T>/probe checkout -b x` | `git checkout is forbidden to the implementer` |

Hypotheses:
- H1: the byte comes from the command text itself. Refuted by run 1: `$cmd`, at the end of the message, shows `$(echo o)` literally, while the word printed earlier shows `^^`. The byte is the lexer's marker in `vals[]`. **Discarded.**
- H2: only `check_temp_paths` (`:636`) lacks `readable`. Refuted by runs 2–5: refusals in `check_git_read` and in the reviewer's directory checks print it too. **Discarded.**
- H3: `deny` writes `vals[]` words unfiltered, and only two call sites filter them. Refutation looked for: a deny path that prints a `vals` word and does not show `^^`. None found in runs 1–5. **Kept** (root cause 1).
- H4: `{fd}` is read as a word because the fd-number drop at `:538` accepts digits only. Refutation looked for: the lexer output without a `u{fd}` field. Run 6 shows the field. **Kept** (root cause 2).
- H5: the checkout refusal depends on the directory. Refuted by `:749-750`, which never looks at `dir`, and by run 7 in a pure temp repo. The refusal is unconditional. **Kept** as root cause 3, since the opposite hypothesis was refuted.

## Story
Three defects, one story. (1) `every_refusal_is_readable`: no `po-bounds` refusal shows the raw marker byte, including a substitution in an option name. (2) `named_fd_redirections_are_read`: `{fd}>target` is read as a redirection. (3) `implementer_explores_a_throwaway_clone`: in mode `implementer`, a throwaway repo under the temp dir accepts reading verbs and `checkout`, and nothing leaves it for the worktree. An ADR replaces ADR-0050 in part. `method/agents/implementer.md` and `docs/installation.md` keep the ban only for the story worktree.

## Current code
- `method/hooks/po-bounds.sh` (808 lines). The header (`:9-12`) lists the implementer's git refusals. The lexer is `lex_command` (`:317-570`), POSIX awk, which BWK awk and mawk must also run (`:316`). The redirection branch is `:537-543`. `check_temp_paths` (`:620-639`) and `check_redirects` (`:643-655`) say "a path the reviewer cannot read". The `check_bash` git branch per mode is at `:705-770`, the implementer part at `:748-767`.
- `method/agents/implementer.md:23`: "never checkout, switch or stash" with no scope.
- `docs/installation.md:86`: "partout : `git switch`, `checkout`, `stash`, `push` et `worktree add`". The reviewer section (`:115-135`) describes the temp zone.
- `method/commands/po-execute.md:42` already says "never checkout or stash in the story worktree". s96 changed it, and `tests/defect-and-routing-paths.test.sh:60-67` guards it. Out of this story's Owns.
- ADR-0050: the `superseded-by` frontmatter is `[]`, and the body restates the implementer's checkout ban. ADR-0052: `superseded-by: [ADR-0053]`. Its section "Cible d'une redirection, dépôt jetable" is reviewer-only.

## Attachment points
- `deny()` `:53`: one filter covers every refusal.
- Lexer `:538`: the condition that drops an fd prefix.
- `check_bash` `:673`: call `temp_root` for the implementer too. `:748-767`: the implementer's verb rules, plus the zone check.
- `check_temp_paths` `:633`, `check_redirects` `:648`: wording that names the reviewer.

## Verified interfaces
- `in_temp_zone <dir>` (`:86`): true for an existing dir under `TMP_ROOT` that is in no repository, or whose common dir and top level are under `TMP_ROOT`. It needs `temp_root` to have run.
- `try_story_of_dir <dir>` (`:59`): returns 0 and sets `TOP` and `STORY` for a linked `story/*` worktree.
- `check_temp_paths <base> <j>` and `check_redirects <shell dir>` use `vals`, `n`, `j`, `redirs` and `cmd` from `check_bash` through dynamic scope.
- `readable <s>` (`:299`) replaces `\036` with `<substitution>` through a local variable `m`. The pattern is kept as is (bash 3.2, `:658`).
- Test harness: `tests/run.sh` sources `lib.sh` and one test file per run, so helpers are never shared between files. `lib.sh:46` `scratch_repo` uses `mktemp -d` and sets an EXIT trap. `bounds.test.sh:378` `reviewer_lane` exports `TMPDIR` to its own `mktemp -d`.

## Traps
- **Test isolation** (above). `lane()` must give the implementer tests a temp root that does not hold `$SCRATCH`, or `:319`, `:330` and `:340` break. The other implementer cases need `$SCRATCH` and `$WT` to stay outside the zone: `:117` `git worktree list`, `:111-112` commit.
- `reviewer_lane` calls `mktemp -d` after `lane()`. Whatever `TMPDIR` `lane()` exports must exist, or that `mktemp` fails.
- Order inside the implementer branch: a story worktree is judged first. `true; git -C $WT checkout -b x` (`:107`) must stay refused.
- POSIX awk: write `{`/`}` as `[{]`/`[}]` in the ERE. `\{` is an interval in some awks.
- `tests/bounds.test.sh:613` `test_refusal_messages_are_readable` greps `redirects to <substitution>`. Keep that phrase.
- `tests/installer.test.sh:183-190` needs the implementer section of `installation.md` to keep `git update-ref`, `-D`, `--force`, `cherry-pick`, `pull`, `story/*`, `ADR-0050`, `git fetch . HEAD:main` and `GIT_DIR=`. `:193-203` pins phrases of the reviewer section, which stays untouched.
- `.claude/` and `.polype/` are installed copies, refreshed after ship. Live sessions keep the old hook until then.
- No migration.

## Open questions
- `{fd}` before `<<` or `<<<` stays a word, like `2<<<` today. The plan keeps that out of scope, and ADR-0072 says so.
- Should `git switch` follow `checkout` into the zone? Nobody reported it. ADR-0072 turns it down for now.
- `cd /tmp && git clone /local/path x` becomes refused for the implementer, since the source lies outside temp. `file://` or a clone run from the worktree avoids it. ADR-0072 accepts this cost.

## Complexity
Story 2 → 3. The fixes are small, but the implementer gains three states (story worktree, throwaway repo, elsewhere), and the test harness must be isolated so existing expectations hold.

## Split
— (not at 5)
