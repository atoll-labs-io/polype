# Research — s194-ship-lands-through-a-pull-request

[Story](../stories.md)

## Structuring facts
- **The story's line numbers are stale**: s192 and s193 shrank `po-ship.md` to 78 lines and 2 298 words (`LC_ALL=C wc -w`). The draft rewrite is now `method/commands/po-ship.md:29-31`, the pr landing `:41-53`. The criterion "at least 600 words less" means ≤ 1 698. Step 3 (`:59-77`, 1 164 words) belongs to s195/s196, so the 600 words come from `:24-31` (258) and `:41-57` (453).
- **`po ship forge` cannot see a GitHub `origin` in a test today**: `forge::read` takes the URL from `git remote get-url origin` (`po/src/ship/forge.rs:442`), which expands `insteadOf` (checked with git 2.56). So a github.com URL rewritten to a local bare repository reads as `unrecognised-host`, and no test can make the forge collaborative while pushing to a bare repository. `trust::forge::Forge::of` reads the configured URL instead (`po/src/trust/forge.rs:143`). The plan reads the configured URL in both places.
- **Story vs prose on a failing forge check**: `po-ship.md:53` says a failing check stops "starting no fix run". The criterion `automatic_waits_for_checks` says it "sends the story to a fix run". No ADR settles this (ADR-0105 only says merge only when checks pass). The criterion is newer and the owner wrote it. Only a `fail`/`cancel` bucket goes to a fix run. A timeout or an unreadable forge still stops for a human.
- **A landing commit is not deterministic across runs**: `land.rs:606` runs `git commit-tree` with the current time, so a rerun of `po ship land` gives another sha for the same tree. "A commit already sent is not rebuilt under another identifier" therefore needs the push step to prefer the remote head of `story/<id>` while it is still the landing: base as only parent, exact subject, tree of a fresh `merge-tree`. `still_the_landing` (`land.rs:460-464`) already does that test.
- **ADR-0130 already names the sub-step** `po ship push <id>` (s194). No new ADR is needed, and ADR-0131 is not used.

## Story
`/po-ship` delegates to a command: sending the landing commit, the pull request, waiting for checks, the merge, and the draft that rewrites a `(forge)` line. An interrupted ship resumes. Criteria: `pr_mode_never_pushes_target`, `human_stops_at_the_pull_request`, `automatic_waits_for_checks`, `resumed_ship_does_not_land_twice` (exact-subject guard, #401, d-0045), `forge_line_is_rewritten_by_the_command`, `description_stays_with_the_model` (model rule, ≥600 words fewer), `version_goes_up`.

## Current code
- `po/src/ship/mod.rs:79-86` dispatches `land` and otherwise `forge`. `USAGE` is at `:13-14`. `origin()` (`:28-35`) and `effective()` (`:37-50`) turn a line plus a verdict into the effective value and the `rewrite`. `(chosen)` never gets a rewrite (`:44-48`).
- `po/src/ship/land.rs`:
  - `worktree()` `:134-160`, `gate()` `:195-206` (runs `.polype/hooks/po-gate.sh ship-allowed`, which reads the review **on disk**, `method/hooks/po-gate.sh:78-92`), `setting()`/`settings()` `:208-237`, `remote_check()` `:239-254`, `title()` `:257-267`.
  - `base()` `:302-316` fetches `origin` under pr.
  - `probe()` `:324-342`, `still_the_landing()` `:460-464`, `landing_by_subject()` `:490-495` (`git log -F --grep=<subject>` then the exact `*found == subject` filter at `:494`), `brings_nothing()` `:498-502`.
  - All of these are private to `land.rs`. Under pr, `--land` and `--sha` are refused (`:528-532`). Nothing is pushed (`:3`).
- `po/src/ship/git.rs:152-168`: the only writing git launcher (`LC_ALL=C`, stdin null). It sets no `GIT_TERMINAL_PROMPT`.
- `po/src/ship/forge.rs`:
  - `read()` `:439-489`; `host_and_path()` `:63-83` and `owner_repo()` `:86-93` give host and `<owner>/<repo>`.
  - Access through `gh` is pinned to `--hostname github.com` (`:204-207`). Tools come through `trust::forge::program` (`PO_GH`, …, `po/src/trust/forge.rs:20-25`), and `quiet_output` (`:110-113`) drops stderr.
- `po-ship.md`:
  - Step 0 `:22`: the hand-merge shortcut through `gh pr view … MERGED`.
  - `:27`: `po ship forge`.
  - `:29-31`: the draft rewrite in prose (temp index, `commit-tree`, lease on `framing/ship-confirmation`, `gh pr create --draft`, reuse, non-GitHub fallback, refused push never forced).
  - `:37`: a `ci` stage waits on `gh pr checks`.
  - `:44`: the gate before any merge.
  - `:46`: the remote check.
  - `:49-53`: the push with `--force-with-lease=story/<id>`, the skip rule and the rebinding of `<sha>`, PR reuse or creation with the description, the human stop line, and the automatic wait (30 s × 30 min, `headRefOid` == sha, JSON buckets, ≥1 check) then `gh pr merge <url> --rebase --match-head-commit <sha>`.
- Allowed tools of `po-ship.md:4-7` are Read, Bash and AskUserQuestion, with no Write.
- `docs/interface-agent.md:272-273` holds the `ship forge` and `ship land` rows. Its usage list says "une autre que `forge` et `land`".

## Attachment points
- `po/src/ship/mod.rs`: route `push` to a new `po/src/ship/push.rs` and extend `USAGE`. Make `effective()` reachable (`pub(super)`).
- `po/src/ship/land.rs`: expose to `push.rs`, as `pub(super)`:
  - `is_id`, `is_sha`, `worktree`, `gate`, `setting`, `title`;
  - `base`, `probe`, `still_the_landing`, `landing_by_subject`, `read`, `git_failed`.
- `po/src/ship/forge.rs:442`: read `git config --get remote.origin.url`. Add a `pub(super)` helper that returns `(host, owner/repo)` for push.
- `po/src/ship/git.rs`: `GIT_TERMINAL_PROMPT=0`, so a push never waits for credentials.
- `docs/interface-agent.md`: a new `ship push` row, and the usage list of the `ship forge` row.
- Version: `po/Cargo.toml:3`, `po/Cargo.lock` (the `name = "po"` entry) and `bin/polype:28`, currently 0.9.0.

## Verified interfaces
- Output: `output::reply(body, code)` adds `contract: 1`. `output::error(code, error, message)`. `OK=0`, `REFUSED=1`, `UNREADABLE=2` (`po/src/output.rs:3-7,31,36`).
- `Project::find` resolves a worktree to the main checkout and reads `AGENTS.local.md` **at the repository root** (`po/src/project.rs:38-48,55-67`). The line a rewrite starts from is that file's. The commit is built on `origin/<Target>`'s copy.
- `gh pr checks` exits 8 while pending and 1 on a failure. The prose decides on the JSON, never the exit code (`po-ship.md:53`). `gh pr list --head <branch> --state all --json …` gives an array, empty when there is none. That separates "none" from "unreadable" better than `gh pr view <branch>`, which fails in both cases.
- Test helpers: `tests/lib.sh:56-58` (`ROOT`, `METHOD`, `PO`), `:61` (global git config off). `tests/run.sh:33-48` runs each function in its own `bash -c` with `set -eu`, and fails a file with no `test_` function.
- `po-gate ship-allowed` reads the review file as it is on disk (`po-gate.sh:79-83`). An appended `Ship allowed: no` refuses.

## Traps
- **Phrase tests that fall (Owns)**:
  - `ship-through-pr.test.sh`: `:8` (`gh pr merge … --match-head-commit`), `:26` (`--force-with-lease=story/<id>`), `test_push_targets_only_the_story_ref` `:34-43` as a whole, and `:56-66` (gate before `gh pr merge` in Step 2). The ADR-0015 lines `:67-70` stay.
  - `ship-resumes-cleanly.test.sh`: its only test `:79-91` falls, so the file goes.
  - `ship-and-fleet-cleanup.test.sh`: `test_ship_text_is_complete` `:24-37` falls, including its grep for `test_push_targets_only_the_story_ref`. Its only mutant targets `po-drive.md` (`:63-65`). It has no mutant of `po-ship.md` (they left with s125/s173), so nothing changes there.
  - `ship-follows-forge.test.sh` `:116-119`: `framing/ship-confirmation`, `gh pr create --draft`, the chore message, "The ship does not wait for that draft". The order check `:120-125` and the gate test `:143-154` stay.
- **Phrases outside Owns that must survive in `po-ship.md`**:
  - `tests/ship.test.sh`: the gate before Step 1, `Cleanup, only after proof`, ``prints exactly `MERGED` ``, ``--force` is not an option``, "Do not test the story branch's own commits", `**One failure and the ship stops**`, ``already prints `MERGED`, go straight to cleanup`` (`:9-31`).
  - Every Step 3 phrase of `everything-in-issues.test.sh` and `review-findings-shape.test.sh`.
  - `## The forge's review rule` as a heading (`method/AGENTS.md:141`, `po-intake.md:76`, `po-setup.md:27,75,90`).
  - `po-setup.md:81` "(as the settings commit of `/po-ship`)" stays true only if po-ship still says the settings commit is built beside the checkout, which `po ship push` now does.
  - `ship-through-pr.test.sh:51` reads ``` `Merge mode: local` is only for a repository without a remote ``` (`po-ship.md:46`). Keep it.
- `tests/ship-files-the-other-findings.oracle.test.sh:9` caps `po-ship.md` at 2 700 words, which still holds.
- **Wait vs tool timeout**: a 30-minute wait in one call exceeds a 10-minute foreground shell call. Polling must be idempotent across a cut call, and `/po-ship` launches it so it is not cut (see the plan's pivot).
- The fetch gives `refs/remotes/origin/story/<id>`. When the remote branch is deleted, that ref stays stale (no `--prune`), and a lease built on it is refused. Observe the remote head with `git ls-remote`.
- Interface-agent rows are long French cells. Add one row and keep it to the facts of the reply.
- `po/` changes, so the version goes to 0.10.0 in three places (ADR-0122), and the stories touching `po/` run one at a time.
- No migration.

## Open questions
- Should the non-GitHub forges (GitLab, Forgejo) get their native merge (ADR-0081: GitLab `ff`, Forgejo `fast-forward-only`)? The plan keeps today's behaviour: branch sent, a person asked. Wiring them stays a later story (#75, `parked`).
- Is the 30-minute bound across a cut-and-rerun call global, or per call? The plan makes it per call. Safety does not depend on it, because nothing merges without passing checks and the gate.

## Complexity
Story 4 → **4**. The code reuses most of s193 and s192. The risk is real: an irreversible forge write, five resume points, and a 30-minute wait that tests must cross without sleeping. It does not need a split: `po ship push` is one sub-step and its draft rewrite shares its forge reading.

## Split
—
