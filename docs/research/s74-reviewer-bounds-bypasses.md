# Research — s74-reviewer-bounds-bypasses

[Story](../stories.md)

## Structuring facts
- **The story's list of detours is incomplete.** Two more of the same kind reproduce on the current script, which allows both with exit 0 (sandbox, TMPDIR separate from the "main" repo). First, a substitution vanishes from the word that holds it (`method/hooks/po-bounds.sh:304`), so `git -C "$(echo <main>)" commit` is judged in the cwd. Second, `--attr-source` and `--config-env` take a separate value that `-*) j+1` (`:625`) reads as the verb, so `git --attr-source HEAD push` passes from a probe. Both are folded into this story (ADR-0051).
- **A third detour is left out: the scope of `cd`** (subshell, substitution, `&`, pipeline, `pushd`/`popd`). `cur` is one variable across every line (`:608-611`), and the lexer's output says nothing about context. Fixing it changes the lexer's output format; it needs a story of its own (Open questions).
- **M2's premise does not reproduce on git 2.56.0.** `core.worktree` set through `-c` (any case), `--config-env`, `GIT_CONFIG_COUNT`, `GIT_CONFIG_PARAMETERS` or `GIT_CONFIG_GLOBAL` left the other tree untouched with `checkout -- f` and `reset --hard`, in both a plain repo and a linked worktree. `--work-tree` did write there (control case). The refusal stays as a defence for other git versions.
- M1, M3 and the hook side of M2 do reproduce: all nine probe commands exit 0 today, including `git -C <main> -C . commit`, `git init <main>/x`, `clone <main> <main>/sub`, `worktree add <main>/evil` and `config core.worktree <main>`.
- The line numbers in the s70 review moved after s71. `-C` is now at `:617`, `-c` at `:624` and the temp zone at `:646-647`.

## Story
Mode `reviewer` must judge the git command git will really run. Acceptance criteria:
- `chained_git_dirs_are_folded` — every `-C` chained as git chains them; `git -C <main> -C . commit` from a probe refused.
- `config_worktree_override_is_refused` — `-c core.worktree=…` refused in mode reviewer, like `--work-tree`.
- `temp_zone_verbs_keep_their_paths_in_temp` — in a throwaway repo, `worktree add`, `clone`, `init` accepted only with a destination under the temp dir.
- `reviewer_knows_how_to_check_merged` — `reviewer.md` says how to check a branch is not merged without `git branch --merged`.

## Current code
- `method/hooks/po-bounds.sh` (711 lines). Header comment for mode reviewer at `:19-28` cites ADR-0047.
- `check_bash` (`:582-678`): lexes the command (`:585`), then for each simple command:
  - in reviewer mode, refuses `GIT_DIR=`/`GIT_WORK_TREE=` words, `u` or `q` (`:597-604`);
  - follows `cd <word>` with `join_dir` (`:608-611`; a bare `cd` is not handled: `$((i + 1)) -lt "$n"`);
  - detects git (`:613`) and walks the global options (`:615-628`). `-C` **overwrites** `gdir` (`:617`). `--git-dir`/`--work-tree` are refused in reviewer mode (`:618-623`). `-c|--git-dir|--work-tree|--namespace` skip 2 (`:624`), and any other `-*` skips 1 (`:625`).
- Reviewer branch (`:632-648`): refuses push/send-pack (`:633`) and sets `dir = join_dir(cur, gdir)` (`:634-635`); a nonexistent dir is refused (`:636`). Then three outcomes:
  - in a story worktree, read verbs, `checkout --` or `check_restore` (`:637-645`);
  - in the temp zone, `in_temp_zone "$dir"` and nothing more: no verb argument is read (`:646-647`);
  - otherwise refused.
- Implementer branch (`:649-670`): commit-family verbs use the same `gdir` join (`:665-668`), so `git -C <main> -C . commit` from a story worktree passes there too.
- `join_dir` (`:286`): an absolute second argument wins, otherwise `${1%/}/$2`. An empty `$1` yields `/<rel>` — a trap for an "unknown" cwd.
- `in_temp_zone` (`:75-88`): physical dir under `TMP_ROOT`, and the common dir and top level under it too. `under_temp` (`:71`). `temp_root` (`:63-69`) runs once per Bash call in reviewer mode (`:590`).
- `resolve_path` (`:92-107`): sets `RESOLVED`/`NEAREST`. It denies a relative path, a symlink at the path itself, and a `.`/`..` segment in the part that does not exist yet.
- Lexer `lex_command` (`:293-534`): its output is one line per simple command, words joined by `\037`, each typed `c`/`q`/`u` (`:340`).
  - `opensub` (`:304`) marks `ws[f]=1` (stored as `S[f,k]`, `:308`) but appends nothing to the word, so `"$(x)"/y` is emitted as `q/y` and `a$(pwd)` as `ua` (checked).
  - `S` is used only for "a substitution handed to an interpreter" (`:345,348`).
  - `$VAR` and `~` stay literal in the word (`u$HOME/x`, `u~/x`, checked).
- `method/agents/reviewer.md:35` — the hook paragraph; nothing on the merged check. ADR-0047:48 already gives the workaround (`merge-base --is-ancestor`, `git log`).
- `method/skills/review-antihallu/SKILL.md:14` — the critical "inside another running story's Owns" rule needs "branch not merged into Target branch", the check that `branch --merged` would serve.

## Attachment points
- Lexer: `opensub` (`:304`), plus a constant in `BEGIN` (`:520-527`).
- `check_bash`:
  - the `cd` case (`:608-611`);
  - the global-option loop (`:615-628`);
  - the reviewer temp-zone branch (`:646-647`);
  - the assignment check (`:599-603`).
- `method/agents/reviewer.md:35` (Limits paragraph).
- `docs/decisions/ADR-0047…md` frontmatter `superseded-by` (body untouched); ADR-0051 is written by this planner.
- `tests/bounds.test.sh` after `:504`. Reuses `reviewer_lane` (`:378-385`), `rev_bash`/`rev_status` (`:387-388`), `expect` (`:47`), `bash_status` (`:45`) and `contains` (`tests/lib.sh:43`).

## Verified interfaces
- `hook_input` (`tests/bounds.test.sh:34-37`) sets `cwd` to `$SCRATCH`, the "main checkout". So a bare `git …` without `cd`/`-C` is judged at the main checkout.
- `reviewer_lane` exports `TMPDIR=$TMPROOT` (separate `mktemp -d`), `git init`s `$TMPROOT/probe`, and adds `$TMPROOT/main-wt`, a worktree of the real repo.
- Git 2.56.0, checked:
  - `-C` chains (`-C <main> -C .` lands in `<main>`), and `-C ''` is a no-op;
  - `-Cpath` is an unknown option;
  - `--attr-source X`, `--config-env K=V`, `--namespace X`, `--git-dir X` and `--work-tree X` accept a separate value, while `--list-cmds` and `--super-prefix` do not;
  - a destination written `file:///abs/x` for `clone` or `init` is created **relative to the cwd** (`./file:/abs/x`).
- `tests/lib.sh:46-52`: `scratch_repo` uses `mktemp -d`, under `/tmp`, outside `$TMPROOT`.

## Traps
- **Lexer change reaches every mode.** A substitution marker in the word value changes words that held a substitution, in the implementer and qa modes too. Expected effects:
  - in implementer mode, `git -C "$(…)" commit` becomes refused (its dir no longer exists), where today it is judged in the cwd;
  - qa mode never reads the directory;
  - `GIT_DIR=$(…)` still starts with `GIT_DIR=`.
  Only `tests/bounds.test.sh` runs the hook; `tests/structure.test.sh:82` only quotes `method/AGENTS.md`.
- `test_reviewer_git_is_read_only_outside_restores` (`:428-451`) must stay green unchanged:
  - `git -C $TMPROOT/probe commit -m x`, `cd $TMPROOT/probe && git branch x && git reset --hard` and `cd $TMPROOT && git init other` must still pass the new temp-zone path rule;
  - `cd "$(mktemp -d)" && git init` must stay refused.
- `join_dir ""` gives an absolute `/rel`: an unknown cwd must not go through it.
- `resolve_path` denies directly (exit 2) instead of returning, so a path word that is a symlink, or that holds a nonexistent `..`, refuses the call. That is fail-closed, and the plan accepts it.
- In-flight neighbour s75 owns `docs/installation.md` and ADR-0037/38/39/41, but not ADR-0047, so there is no overlap. Its plan cites ADR-0047 for the reviewer mode, and that stays true under a partial supersession.
- `tests/leftovers.test.sh:10-17` pins the partial-supersession convention: the old ADR keeps `status: accepted` and gains `superseded-by`. ADR-0024 is a precedent.
- No migration, no screen, no dependency, no API contract. The authorization signal is present (po-bounds is a permission policy), which is why this is on the full track (complexity 4 > `Flow threshold` 2 already decided it).

## Open questions
- **Scope of `cd`** (subshell `(cd x); git …`, `$(cd x)`, `cd x &`, `… | cd x`, `pushd`/`popd`). The hook believes the `cd` persists. Proposed follow-up story: the lexer types the command word of a command run in a nested context, and mode reviewer makes `cur` unknown after such a `cd`. Not settled here; ADR-0051 names it as an open gap.
- Whether the new temp-zone path rule blocks a probe pattern that real reviews used, for example cloning the real repository by absolute path. ADR-0051 points to `file://`. The first reviews after ship will show it.
- Whether macOS awk handles a `\036` byte in a word value like gawk does. Linux-only check; a person on macOS runs `bounds.test.sh`.

## Complexity
Story 4 → 4. A single script plus tests, but a security policy with five refusals to add, none of which may break a legitimate probe. The lexer touch raises the risk; the deferred `cd` scope keeps it from reaching 5.

## Split
Not needed at 4. The `cd`-scope gap is the natural next story; it is reported, not planned.
