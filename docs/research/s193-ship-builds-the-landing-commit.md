# Research — s193-ship-builds-the-landing-commit

[Story](../stories.md)

## Structuring facts
- **False assumption**: the story's line numbers for `po-ship.md` predate s192. Today Step 0 is `method/commands/po-ship.md:17-20`, Step 1 `:33-40`, the start of Step 2 (remote check, base, landing commit) `:47-54`, the local landing `:63-65`.
- **False assumption**: Step 1's checks do not go through `po-run` today; `po-ship.md:34` runs "the project commands verbatim". Through `po-run`, each check appends a row to `docs/verif/<id>.md` (`method/hooks/po-run.sh:56-63`), which leaves the worktree dirty, and cleanup stops on any uncommitted change (`po-ship.md:83`). The rows must be committed with the review (`po-ship.md:34`), before the landing commit is built.
- **Assumption that holds only in part**: `conflict_goes_to_a_human` says nothing is written. In `pr` mode the base must be fresh (`po-ship.md:49`), so the `git fetch origin` comes before the conflict can be seen: on a conflict, origin's tracking refs have moved and nothing else has. `git merge-tree --write-tree` also stores loose objects in every case (seen with git 2.56). No ref, no commit and no file changes.
- `po` writes to git for the first time (ADR-0130, Consequences): `po/src/project.rs:18-19` says "`po` never fetches, pulls, pushes nor writes". That file is outside `Owns`, so the comment stays as it is, and every write goes through a second launcher in `po/src/ship/`.
- The `Merge / Not now` question of the local mode (`po-ship.md:64`) comes after the checks and before the fast-forward, and stays there: under `local`, the build call stops with the `sha` unless `--land` is passed (effective `automatic`), and a second call `--sha <sha>` lands that commit after the person's Merge (plan, The command).

## Story
Gate first, then the landing commit, built by `po ship land <id>` (ADR-0130's name), which reports every step in JSON. Criteria: `gate_comes_first`, `one_commit_no_merge`, `conflict_goes_to_a_human`, `local_mode_lands_here`, `ship_command_calls_it` (model-read, ≥400 fewer words in `po-ship.md`, judged in review), `version_goes_up` (0.8.0 → 0.9.0, three places).

## Current code
- `po/src/main.rs:24` routes `ship` to `ship::main`; usage at `:18` lists the verbs.
- `po/src/ship/mod.rs:49-74` `parse` accepts only `forge` (`USAGE` at `:11`); `main` at `:76` finds the project (`Project::find`), reads `Target branch` and `Ship confirmation`, prints one `ForgeReply`. `po/src/ship/forge.rs` (489 lines) launches `gh`/`glab`/`tea`/`curl` via `program("PO_GH", …)` doubles, never git writes.
- `po/src/project.rs:20-33` `git(dir, args) -> Option<String>`: read-only, `GIT_OPTIONAL_LOCKS=0`, stderr dropped, exit code lost. `Project::find` (`:38-48`) resolves a worktree to the main checkout (`--git-common-dir`'s parent). `Project::setting` (`:55-67`): first `Name:` line with a value; `Test:` does not match `Test budget:`, `Build:` does not match `Build stage:`.
- `po/src/record/gate.rs:12-33` runs `bash <top>/.polype/hooks/po-gate.sh <name> <id>` and keeps code/stdout/stderr, but `record/mod.rs:6` declares it `mod gate;` (private). `record/mod.rs:104-133` `worktree(id)`: cwd → `--show-toplevel` → `rev-parse --abbrev-ref HEAD` must be `story/<id>`, refusal `wrong-branch` (exit 2). Both are outside `Owns`.
- `po/src/output.rs`: `OK 0`, `REFUSED 1`, `UNREADABLE 2`; `reply(body, code)` prints `{"contract":1,…}`; `error(code, error, message)`. One JSON object on stdout, always.
- `method/hooks/po-gate.sh:78-96` `ship_allowed`: last `Ship allowed:` yes, both `Review status: complete`, `Reviewed tree:` matches HEAD outside `docs/`. Refusal text "the review of <id> does not allow shipping (last verdict: …)" on stderr, exit 1. `verif_current` `:134-148`.
- `method/hooks/po-run.sh`: `--story <id> --label <l> -- '<cmd>'`, must run on `story/<id>` (`:37-38`), passes the check's stdout and exit through, 125 when it refuses; appends to `docs/verif/<id>.md` (created when absent).
- `method/commands/po-ship.md` is 2 700 words (`LC_ALL=C wc -w`). Step 0 `:17-20` (gate, plus a fallback "without the hook" restating the gate), Step 1 `:33-40`, Step 2 `:42-65`.

## Attachment points
- `po/src/ship/mod.rs` `parse`/`main`: dispatch on the first argument, `forge` or `land`; `land` goes to a new `po/src/ship/land.rs`.
- New `po/src/ship/git.rs`: the second git launcher ADR-0130 asks for, the only one that writes, returning code, stdout and stderr.
- `docs/interface-agent.md:272`: the `ship forge` row of the lead's verbs table; `ship land` gets the next row.
- `po/Cargo.toml:3`, `po/Cargo.lock` (`name = "po"` entry), `bin/polype:28` `POLYPE_VERSION`.

## Verified interfaces
- `crate::project::{git, Project, Setting}` are `pub`; `Project.root` is `pub`. `crate::output::{reply, error, OK, REFUSED, UNREADABLE}`.
- Story title: `docs/stories.md` headings are `## <id> — <title>` (`method/templates/stories.md:7`) or `### <id> — <title>` (this repo, `docs/stories.md:3132`). `context::Story` (`po/src/context/stories.rs:6-22`) has no title field and lives outside `Owns`: the title is read by `land.rs` itself.
- `git merge-tree --write-tree --name-only --no-messages -z <base> <branch>` (git 2.56 here, ≥2.38 per ADR-0081): exit 0 → tree id; exit 1 → tree id, NUL, then each conflicting path NUL-terminated, a path once per stage, so dedupe; any other exit → error. Without `--no-messages` the messages are localised (French on this machine).
- `git commit-tree <tree> -p <base> -m <msg>` prints the commit; identity from the repo config.
- `git merge --ff-only <sha>` in the root; `git status --porcelain --untracked-files=no` for the root check (`po-ship.md:65`).
- Settings the command reads: `Target branch`, `Merge mode` (`pr`, `local`), `Full suite` (`execute-end`, `ship`, `both`), `E2E stage` (`ship`, `ci`, `—`), `Build stage` (`ship-if-route`, `ship`, `ci`, `—`), `Test`, `E2E`, `Build` (`method/templates/agents-local.md:52-56`).

## Traps
- Tests outside `Owns` that stay green only if `po-ship.md` keeps some text:
  - `tests/ship-follows-forge.test.sh:56-60,79-88`: `## Step 0` and its first `po-gate ship-allowed <id>` come before `## The forge's review rule`, which comes before `## Step 1`; the sentence "`po-gate ship-allowed <id>` is required before any merge, whatever the value" stays (`po-ship.md:45`).
  - `tests/ship-resumes-cleanly.test.sh:9-19`: the push and merge bullets of Step 2 (s194's) stay.
- `tests/ship-reads-the-forge.test.sh:119-120` (outside `Owns`): `po ship land` with no id must still exit non-zero with `error: usage`.
- `tests/ship-and-fleet-cleanup.test.sh:26-34` (in `Owns`): Step 2 keeps at least three bullets starting `- \`Ship confirmation: human\`` / `` `automatic` `` that carry ", the effective value".
- `method/commands/po-setup.md:67` says "**Remote check**, as in `/po-ship`" and restates it: `po-ship.md` must keep a remote-check sentence. `:81` points to the settings commit of the forge section, which this story leaves alone.
- `method/AGENTS.md:107` allows only research, plan, review and oracle files uncommitted in a worktree. Committing the review and the record rows on `story/<id>` is what `po-ship.md:34` already does for the review.
- `po-run`'s check output goes to stdout (`po-run.sh` header), and `po` must print exactly one JSON object: the child's stdout has to go to `po`'s stderr.
- Git hooks: a commit on `story/<id>` runs `po-gate pre-commit` when `core.hooksPath` is set. Docs only, so the plan gate does not apply (`po-gate.sh` header).
- Every story touching `po/` raises the version (ADR-0122); s194–s196 follow and run one at a time.

## Open questions
- `E2E scope` and `E2E browsers` (`po-ship.md:36`) cannot be applied by a program. Is `<E2E>` run verbatim, with scope and browsers left to the project's command? The plan decides: verbatim, and the reply names the stage.
- Should a second conflict, possible after the docs commit, be reported like the first? It cannot happen unless the base already holds `docs/reviews/<id>.md`. The plan treats it like the first conflict, with the docs commit already made.
- The landing commit is not reproducible: `commit-tree` stamps the current time. s194's resume ("a commit already sent is not rebuilt under another id") will need to handle that. Left to s194.

## Complexity
3 → **4**: this is the first time `po` writes git state (fetch, commit, fast-forward). It also launches project checks through `po-run`, three tests outside `Owns` pin text in `po-ship.md`, and the local confirmation moves earlier. That takes it out of the short track, and there is a new JSON contract in `docs/interface-agent.md`.

## Split
—
