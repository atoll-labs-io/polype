---
validated: yes
---
# Plan — s50-implementer-bounds

[Story](../stories.md) · [Research](../research/s50-implementer-bounds.md)

Branch `story/s50-implementer-bounds`. Read `docs/research/s50-implementer-bounds.md` first; this plan builds on it without repeating it. ADR-0024 (written by this plan) settles how the script finds the story, its `Owns`, its input and how far it reads a Bash command.

## Story
A PreToolUse hook declared in the implementer's frontmatter holds the story's `Owns` and the git verbs of Law 4 while the code is written, instead of the review finding the breach afterwards. Criteria, each one test function of `tests/bounds.test.sh` with the same name: `implementer_declares_a_pretooluse_hook`, `bounds_hook_blocks_when_the_script_cannot_run`, `bounds_deny_writes_outside_owns`, `bounds_deny_forbidden_git_verbs`, `bounds_fail_closed`, `installer_ships_the_bounds_hook`, `installation_doc_names_the_upgrade_path`.

Correction to the story: `bin/polype` needs **no change** — it already ships every file of `method/hooks/` executable (`bin/polype:98`, `:101`, `:143`). It stays in `Owns` but ends with an empty diff.

## Tasks
1. [x] **`method/hooks/po-bounds.sh` — skeleton, input, story resolution, Write/Edit check.** Style of `po-gate.sh` (shebang `#!/usr/bin/env bash`, header comment listing the modes and the exit codes, `set -uo pipefail`, one `deny()` that prints `po-bounds: <reason>` to stderr and exits **2**). The script exits 0 (allow) or 2 (refuse), never anything else, and reads no setting.
   - Mode = `$1`. `implementer` is the only mode; empty or unknown → deny. Write the per-mode part as a `case` so s51 can add `qa` without touching the rest.
   - `jq` missing → deny, naming `jq`. Input = all of stdin. `.tool_name` via `jq -er` (a parse failure or a missing field → deny "unreadable hook input"). `Write`/`Edit` → `.tool_input.file_path` (a string, absolute, else deny). `Bash` → task 2. Any other tool → deny.
   - Path normalisation without `realpath -m` (absent on macOS): walk up to the nearest existing ancestor, resolve it with `cd -P … && pwd -P`, re-append the missing tail; a tail holding a `.` or `..` component → deny; an existing target that is a symlink → deny.
   - Story resolution (ADR-0024): from the resolved directory, `git rev-parse --show-toplevel`; the worktree must be **linked** (`--absolute-git-dir` differs from `--path-format=absolute --git-common-dir`) and on a branch `story/<id>` (`git symbolic-ref --short -q HEAD`); otherwise deny ("not inside a story worktree"). `<id>` = branch minus `story/`.
   - `Owns` = from `git -C <top> show HEAD:docs/stories.md` (committed copy, never the working file): the block opened by a heading `^#+ <id>` followed by a space or end of line, closed by the next `^#` line; inside it, the first line matching `^[-*] \*\*Owns\*\*[[:space:]]*:` (French ` :` and template `:` both). Paths = the backtick-quoted tokens of that line. No file, no story heading, no `Owns` line, or no path in it → deny, each with its own message.
   - Allowed when the path relative to `<top>` starts with `docs/`, or equals an `Owns` entry, or lies under it (entry with its trailing `/` stripped, then `rel == e` or `rel` starts with `e/`). Otherwise deny with `<absolute path> is outside the Owns of <id>` and the `Owns` line verbatim.
   - Test able to fail: `bounds_deny_writes_outside_owns` and `bounds_fail_closed` (task 4).
2. [x] **Same script — the Bash branch (git verbs).** Command = `.tool_input.command` (string, else deny); `.cwd` read as the fallback directory. No other Bash analysis: redirections and non-git commands are allowed (story note).
   - Text: delete the characters `'`, `"` and `\`; turn `;`, `&`, `|`, `(`, `)`, `` ` ``, `$(`, `{`, `}` and newlines into word breaks; split on whitespace. Quoted text is scanned like the rest (ADR-0024: false positives accepted).
   - Walk the words. A word `cd` records the next word as the current directory (relative → against the previous one, starting from `.cwd`). A word equal to `git` or ending in `/git` starts a git call: skip global options — `-C <dir>` (remember it), `-c <v>`, `--git-dir <v>`, `--work-tree <v>`, `--namespace <v>`, any `--x=y` and any other word starting with `-` — then the verb.
   - Verb `switch`, `checkout`, `stash`, `push` → deny. `worktree` followed by `add` → deny (`worktree list` passes). `commit` → its directory is the `-C` one (relative → against the current directory), else the current directory; it must exist, be a linked worktree and be on `story/*`, else deny ("git commit outside a story/<id> branch"). The denial names the verb and quotes the command.
   - Test able to fail: `bounds_deny_forbidden_git_verbs`.
3. [x] **`method/agents/implementer.md` — the hook and one line of prose.** After the `skills:` list (never before it: `tests/fleet-design.test.sh:13-15`, `bin/po-lint:52-61` read `skills:` as consecutive `  - ` lines), add exactly:
   ```yaml
   hooks:
     PreToolUse:
       - matcher: "Edit|Write|Bash"
         hooks:
           - type: command
             command: '"$CLAUDE_PROJECT_DIR"/.polype/hooks/po-bounds.sh implementer || exit 2'
   ```
   Shell form on purpose: `|| exit 2` turns 126, 127, 1 or any other failure into the only blocking code; `$CLAUDE_PROJECT_DIR` because the hook runs in the session's directory, not the worktree (research). In `## Limits`, add one bullet in your own words carrying the exact phrase `A po-bounds refusal is a stop`: report the refused path or command, never reach the same file another way (a shell redirection, `cp`, `sed -i`). No other change to the body.
   - Test able to fail: `implementer_declares_a_pretooluse_hook`, `bounds_hook_blocks_when_the_script_cannot_run`.
4. [x] **`tests/bounds.test.sh` — seven tests, one per criterion.** Header comment `# s50 — the implementer's bounds held by a hook.` Helpers in the file:
   - `lane()`: `scratch_repo`; a committed `docs/stories.md` holding `### s01-demo — Demo` with `- **Owns** : \`src/app.sh\`, \`lib/\``, `## s03-en — En` with `- **Owns**: \`pkg/\`` (template form), and `### s02-bare — Bare` with no `Owns` line; then `git worktree add -q -b story/<id> "$SCRATCH/.worktrees/<id>"` for `s01-demo`, `s02-bare`, `s03-en` and `s99-ghost` (not in the file).
   - `hook_input <tool> <field> <value>`: builds the JSON with `jq -n --arg` (never by string concatenation), with `cwd` = `$SCRATCH`.
   - `bounds_status`/`bounds_stderr`: run `bash "$METHOD/hooks/po-bounds.sh" implementer` with that input.
   Tests:
   - `implementer_declares_a_pretooluse_hook` — frontmatter holds `PreToolUse:`, the matcher covers `Edit`, `Write` and `Bash`, the command holds `.polype/hooks/po-bounds.sh implementer`; body holds `A po-bounds refusal is a stop`.
   - `bounds_hook_blocks_when_the_script_cannot_run` — the command is **read from the frontmatter** (the `command:` line, outer single quotes removed), never retyped, and run with `sh -c` and `CLAUDE_PROJECT_DIR` set to a scratch dir: no script there → 2; script copied without the exec bit → 2; script executable, allowed write → 0; script executable, refused write → 2.
   - `bounds_deny_writes_outside_owns` — exit 0 for `src/app.sh`, `lib/new/deep.sh` (missing dirs), `docs/anything.md`, and `pkg/x` in `s03-en`; exit 2 for `src/other.sh` with stderr holding the path and `**Owns** :`; exit 2 for `<wt>/docs/../evil.sh`; exit 2 for `src/other.sh` after an **uncommitted** edit of the worktree's `docs/stories.md` adding `src/` to `Owns`; Edit refused like Write.
   - `bounds_deny_forbidden_git_verbs` — exit 2 for each of `cd <wt> && git switch main`, `true; git -C <wt> checkout -b x`, `ls | git stash`, `cd <wt> && git worktree add ../y`, `git --no-pager push`, `cd <root> && git commit -m x`, `git -C <root> commit -m x`; exit 0 for `cd <wt> && git commit -m x`, `git -C <wt> status`, `git worktree list`, `echo ok > /tmp/x`.
   - `bounds_fail_closed` — exit 2 for: a write in `s99-ghost` (story not found), in `s02-bare` (no `Owns`), in the main worktree `$SCRATCH/src/app.sh`, outside any repository (`/tmp/...`); stdin `not json`; empty stdin; a Write without `file_path`; mode missing; mode `nobody`; tool `NotebookEdit`.
   - `installer_ships_the_bounds_hook` — `polype init` after a global install in a throwaway HOME (copy `global_home`/`guard_home` from `tests/global-install.test.sh:9-31`, `HOME` and `CLAUDE_CONFIG_DIR` both inside `$SCRATCH`), and `bin/polype-dev-install <project>`: both leave `.polype/hooks/po-bounds.sh` executable next to `.polype/hooks/po-gate.sh`.
   - `installation_doc_names_the_upgrade_path` — task 5's three phrases.
   Run: `bash tests/run.sh bounds.test.sh`.
5. [x] **`docs/installation.md` — the bounds hook (French).** A `### Le hook des bornes de l'implementer` subsection at the end of `## Activer un projet` (before `## Suivre…`), saying: what `po-bounds.sh` refuses (writes outside `Owns` and `docs/`, the git verbs) and that the review keeps its own check; that it needs `jq`, and refuses everything without it; the upgrade path with the exact phrases `relance \`polype init <projet>\`` and `le hook fermé refuse toute écriture de l'implementer` (after `polype install --global`, commit the new `.polype/hooks/po-bounds.sh` on the target branch); the trust limit — under `polype install <projet>` the agents live in `.claude/agents/`, whose frontmatter hooks run only once the folder's trust dialog is accepted, never in a `claude -p` session, where the bounds are **not** held; under the global install they run without it. Add `po-bounds.sh` to nothing else (the tables already cover `method/hooks/`).
   - Test able to fail: `installation_doc_names_the_upgrade_path` (it checks `relance \`polype init <projet>\``, `le hook fermé refuse toute écriture de l'implementer`, `` `jq` ``).
6. [x] **Checks and record.** `bin/po-lint` (story note), the full suite `bash tests/run.sh` once, no type check (`Typecheck: —`). Under "Not proven here" in the record: no live Claude Code session proved that the frontmatter hook fires inside a subagent, nor the value of `$CLAUDE_PROJECT_DIR` there.

## Run interdicts
- `bin/polype`, `bin/po-lint`, `method/hooks/po-gate.sh`, `method/hooks/pre-commit`, `method/AGENTS.md`, `method/skills/review-antihallu/` end with an empty diff (`Installed files` of the rules is s54's; the review's ownership check stays as is).
- `.claude/` and `.polype/` of the worktree end with an empty diff; `bin/polype-dev-install` is never run on the repository root or the worktree.
- No hook in any `settings.json` (ADR-0022 turned that down).
- No existing test file changes; `tests/bounds.test.sh` is the only new test file.
- `docs/stories.md` and `docs/parite-killer-saas.md` (no row for this mechanism) end with an empty diff.
- `po-bounds.sh` calls only bash builtins, `git`, `jq`, `awk`, `sed`, `grep`, `dirname`: no `python3`, `node` or `realpath`. It reads nothing from `AGENTS.local.md`.
- No exit code other than 0 and 2 from `po-bounds.sh` (`grep -n 'exit' method/hooks/po-bounds.sh`).
- The tests never write outside `$SCRATCH` and `mktemp -d` dirs, never into the real `~/.claude`.

## The pivot
Everything rests on **ADR-0024: the story is the one whose linked `story/<id>` worktree contains the target, and its `Owns` comes from the committed `docs/stories.md`**. Ways it could be wrong:
- `$CLAUDE_PROJECT_DIR` may not point at a directory holding `.polype/hooks/po-bounds.sh` for a subagent launched by `/po-drive` → every write refused (closed, not open). Compare with a live run before relying on it; the record says it is not proven.
- The wrapper may let a failure through: check that `bounds_hook_blocks_when_the_script_cannot_run` reads the command from the frontmatter — a retyped copy would keep passing after the frontmatter loses `|| exit 2`.
- The verb scan may miss a form: `git -C <dir> push` (global option skipping), `git` after `|` or `$(`. Neutralise the `push` branch and run only `bounds.test.sh`.
- A fixture can answer for the check: `docs/stories.md` must be committed in `lane()`, or the "uncommitted widening" case proves nothing.

## Files touched
`method/hooks/po-bounds.sh` (new), `method/agents/implementer.md`, `tests/bounds.test.sh` (new), `docs/installation.md`, `docs/decisions/ADR-0024-po-bounds-trouve-la-story-par-son-worktree.md` (new, written by the plan), `docs/research/s50-implementer-bounds.md`, `docs/plans/s50-implementer-bounds.md`, `docs/verif/s50-implementer-bounds.md`.

## Test strategy
Automated, 7 tests, budget 25, all in `tests/bounds.test.sh`:
- The script is the policy: refusals and the allowed cases are tested once, on the script, with real git worktrees and real JSON (writes, git verbs, fail-closed).
- The adapter is the frontmatter command: one test proves the wrapper turns a launch failure into 2 and still lets an allowed call through, by running the declared command itself.
- Installer: one test, observable result (`-x` on the laid file) for `init` and `install <project>`.
- Docs and frontmatter: exact phrases, the repository's convention.
No red-first run (ADR-0012). Not automatable here: Claude Code honouring the hook in a subagent (record, "Not proven here"). Visual checks: none.

## Done when
The seven tests pass, `bin/po-lint` reports no breach, the full suite is green, the record is complete with its `Tree:`, one commit on `story/s50-implementer-bounds` carrying code, tests, research, plan, ADR-0024 and record, and the review allows shipping with no open critical finding.
