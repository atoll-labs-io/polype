# Research — s165-decision-inbox

[Story](../stories.md)

## Structuring facts
- **Lifted on 2026-11-13: PR #252 (`553160a`) added this test file, `docs/interface-agent.md` and `docs/installation.md` to s165's `Owns`, and the lane was fast-forwarded onto it.** The original blocker: s164's shipped oracle asserts that `po inbox` answers `not-built` with exit 2 (`tests/state-as-json.oracle.test.sh:151-156`, loop `for verb in next inbox answer record run continue`). Criterion `list_prints_pending_oldest_first` makes `po inbox` answer `{"contract": 1, "pending": […]}` with exit 0, so that test turns red. The file is outside s165's `Owns` (`docs/stories.md:2616`), and `po-bounds` denies the implementer any write outside `docs/` and `Owns` (`method/hooks/po-bounds.sh:188-198`). That `Owns` line is read at the story's fork point (`po-bounds.sh:155-162`). The fix is a framing change: add `tests/state-as-json.oracle.test.sh` to s165's `Owns`, then restart the lane from the `main` that carries the fix. s166 (`answer`), s168 (`next`) and s169 (`run`, `continue`) run into the same wall: no M21 `Owns` lists that file (`docs/stories.md:2636, 2674, 2694`).
- Root cause (the story carries `Corrige`, #204 in part): nothing writes a decision as a file. `po inbox` and `po inbox add` answer `not-built` (`po/src/inbox/mod.rs:24-30`). Only the reader exists, `pending_ids` (`po/src/inbox/mod.rs:33-57`), which `po state` calls (`po/src/state/mod.rs:166-184`). What waits for the person lives in `docs/a-trancher.md`, a file kept by hand.
- Gaps this story must repair, now inside its `Owns` since PR #252:
  - `docs/interface-agent.md:5` links `a-trancher.md` as the provisional inbox, and that file gets deleted.
  - The contract does not name the lead's verb `inbox add` (`docs/interface-agent.md:24` names only `next` and `record`), nor the refusal codes of `inbox`.
  - `docs/installation.md:261-262, 111, 513` say the installer adds exactly two `.gitignore` lines; this story adds a third.
- Everything else the story assumes holds:
  - `Decision inbox` is already a setting of the template (`method/templates/agents-local.md:40, 75`) and of this repository (`AGENTS.local.md:38`).
  - `polype update` already names a setting missing from a project (`bin/polype:583-607`, called at `:782` and `:1033`).
  - The installer never takes `.polype/inbox/` for a foreign file: collisions concern shipped destinations only (`bin/polype:236-252`), and a project `remove` prunes only empty directories (`bin/polype:217-219`, `:1100`).

## Diagnostic
Reproduction, on the code as it stands (`po` built with `cargo build --release --locked` into a temp target dir):
- `po inbox` returns `{"contract":1,"error":"not-built",…}` with exit 2.
- `echo '{}' | po inbox add` returns the same.
- `po state` on this repository gives `"waiting":[]`.
- H1, "the inbox only needs a reader". Refutation sought: does anything write a decision? Nothing under `po/`, `bin/` or `method/hooks/` creates `*.json` in the inbox. Every decision so far went to `docs/a-trancher.md` by hand. Discarded.
- H2, "the lead can write the JSON file itself". Refutation sought: does any script check what the model writes? `pending_ids` silently drops a malformed file, which shows only as an `unreadable-decision` warning (`po/src/state/mod.rs:173-176`). No script checks the id, the shape or the ignore rule. Discarded as a fix: it leaves validation to the model, the very thing #204 removes.
- H3, "the missing piece is a writer that validates, in `po`". Refutation sought: does ADR-0107 or ADR-0117 forbid `po` from writing? ADR-0117 names `inbox add` as a lead verb of `po` (`docs/decisions/ADR-0117-un-binaire-po-par-machine.md:25`). ADR-0107 puts the inbox in local files kept out of git, at a location set by a setting (`ADR-0107…:39`). Kept.

## Story
`po inbox add` reads one decision as JSON on stdin and gives it the next id (`d-0001`…). It writes `<id>.json` into the `Decision inbox` folder, resolved from the repository root even when run from a worktree, and prints what it wrote. Without the setting, it exits 2 with `no-inbox-setting`. A malformed decision is refused with exit 1 and nothing is written: an unknown `motive`; a `question` that is missing, spans several lines or runs over 200 characters; 2 or 3 `options` required; `recommended` outside the options; `why`, `reversible` or `blocks` missing.

`po inbox` lists the pending decisions, oldest first, in under a second. `po inbox <id>` prints one decision. A folder inside the repository that git does not ignore → exit 1 with `inbox-not-ignored`; a folder outside the repository is written. The installer adds the template's location to the `.gitignore` and says so. A `sensitive` decision needs a `context` outside the repository.

The rules send every stop to the inbox before it is said; this is judged in review, and only a word ceiling is tested. `docs/a-trancher.md` is deleted.

Criteria: `add_writes_one_decision_file`, `add_refuses_a_malformed_decision`, `list_prints_pending_oldest_first`, `inbox_never_enters_git`, `sensitive_decisions_carry_no_detail`, `rules_send_every_stop_to_the_inbox`, `provisional_inbox_is_gone`.

## Current code
- `po/src/main.rs:23-24`: `inbox` goes to `inbox::main(&rest)` with every argument after the verb, and `answer` to `inbox::answer`. So `add`, `<id>` and s166's options are parsed inside `po/src/inbox/`, and `main.rs` needs no change.
- `po/src/output.rs`:
  - `reply(body, code)` flattens `"contract": 1` beside a `Serialize` body (`:10-16`, `:32-35`).
  - `error(code, error, message)` (`:37-44`).
  - `OK`, `REFUSED` (with `#[allow(dead_code)]`, unused until now), `UNREADABLE` (`:5-8`).
  - A panic hook (`:55-73`).
- `po/src/project.rs`:
  - `Project::find(cwd)` resolves the main checkout through `--git-common-dir`, so a worktree answers for the root. It returns `None` outside a Polype project (`:38-48`).
  - `setting(name)` returns the first non-empty `Name:` value (`:55-67`).
  - The `git(dir, args)` helper returns stdout on success only, under `GIT_OPTIONAL_LOCKS=0` (`:20-33`).
  - `root` is canonicalised (`:41`).
- `po/src/inbox/mod.rs`:
  - `DecisionStatus {id, status}` is the narrow read-back view, without `deny_unknown_fields`, per ADR-0117 (`:13-17`).
  - `Pending {ids, unreadable}` (`:19-22`).
  - `pending_ids(dir) -> io::Result<Pending>`: a missing folder gives an empty list. It keeps `*.json` files whose `status` is `pending`, sorted by `id`. A file it cannot parse goes to `unreadable` (`:30-57`).
- `po/src/state/mod.rs:166-171` resolves `Decision inbox` itself: relative to the root, or absolute as given. `—` and a missing line each give `null` plus a warning (`:62-80`). A copy of that resolution inside `inbox/` is needed, since `state/` is out of bounds.
- `po/Cargo.toml:7-10` has `serde` with derive, `serde_json`, and `chrono` (`clock`, `std`) per ADR-0118. That is enough for typed JSON in and out and for a local date with its offset. No dependency is missing.
- `bin/polype`:
  - `wire_the_project` (`:773-783`, a no-op in global mode) calls `ignore_worktrees_and_env` (`:562-570`), which appends missing exact lines to `.gitignore` silently, and `ignore_local_sums` (`:574-580`).
  - `local_setting` reads the project's `AGENTS.local.md` (`:556-560`), and `$method` is the clone's `method/` (`:37`).
  - The `missing_settings` awk reads the template's fenced block (`:583-607`).
- `method/AGENTS.md`:
  - `## What goes to the person` spans `:69-79` (378 words as `awk '/^## / { on = ($0 == "## What goes to the person") } on' | LC_ALL=C wc -w` counts them, heading included). The stops paragraph is `:77`.
  - `## Installed files` is at `:145-153` (505 words; s161's oracle caps it at 516, `tests/installer-leftovers.oracle.test.sh:119-121`).
  - The whole file is 3743 words (`LC_ALL=C wc -w`).
- `AGENTS.local.md:76` points to `docs/a-trancher.md` "until `po inbox` exists (s165)". The root `AGENTS.md:238` repeats it, but the lead's install refresh regenerates that file, never a story.
- `.gitignore` (7 lines) lacks `.polype/inbox/`. `git check-ignore -q .polype/inbox/d-0001.json` exits 1 here.

## Attachment points
- `po/src/inbox/mod.rs`, plus new files under `po/src/inbox/` if the implementer wants them: the `main(args)` dispatch (none → list; `add` → write; one id → show; else `unknown-option`, exit 2), the input type, the stored decision type, the writer.
- `pending_ids` keeps its signature, since `state/mod.rs:172` calls it. Moving it onto the same read-back type as the listing keeps `po state`'s `waiting` and `po inbox`'s `pending` in step.
- `bin/polype`: one function, called from `wire_the_project`, which reads the template's `Decision inbox` value and appends it to `.gitignore` when the exact line is missing, with one stderr line.
- `method/AGENTS.md:77` (stops paragraph) and `:149` (`po` beside the hooks); `AGENTS.local.md:76`; `.gitignore`; deletion of `docs/a-trancher.md`.

## Verified interfaces
- Exit-code contract: 0 done, 1 refused, 2 unreadable; the error shape is `{"contract":1,"error","message"}` (`docs/interface-agent.md:28-31`, `po/src/output.rs`).
- Decision shape (`docs/interface-agent.md:109-138`):
  - fields `id`, `asked`, `motive`, `sensitive`, `question`, `context`, `options[{key,label,consequence}]`, `recommended`, `why`, `reversible`, `blocks`, `status`, `answer`;
  - motives `incoherence`, `new-idea`, `strategic`, `technical-choice`, `stop`, `security`;
  - `sensitive: true` means `context` points outside the repository and the decision is never copied into git, an issue or a log.
- `answer` is s166's: `unknown-decision`, `already-answered`, `not-an-option` (`interface-agent.md:142-150`). `po answer` stays `not-built` here.
- Date: `chrono::Local::now()` with `to_rfc3339_opts(SecondsFormat::Secs, false)` gives `2026-11-12T14:05:00+01:00`, the contract's form (`interface-agent.md:114`).
- `git check-ignore -q <dir>/<file>` exits 0 for a file under a `dir/` pattern even when the folder does not exist yet (checked on a scratch repository). Ignore rules can therefore be checked before anything is created.
- Tests run under `set -eu` (`tests/run.sh:34`). `tests/run.sh` builds `po` once, isolates `CLAUDE_CONFIG_DIR` (`:13-23`), and `tests/lib.sh:7` sets `PO`. The installer test that hides cargo uses a PATH of symlinks (`tests/state-as-json.oracle.test.sh:307-310`), which keeps an install fast.

## Traps
- **The s164 oracle**: unchanged, the full suite fails at `test_state_prints_one_json_object` whatever the implementation. The fixed test keeps its other verbs (`next`, `answer`, `record`, `run`, `continue`) and drops `inbox` from the loop. That is a clause the story changes, which the conventions allow once the file is owned (`AGENTS.local.md`, "change an existing test only when the story changes the clause it checks").
- Frozen phrases of `## What goes to the person`, which the rewrite must keep word for word:
  - `tests/escalation-contract.test.sh:27-41, 82-85, 90-93, 110`;
  - `tests/everything-in-issues.test.sh:29-31`: the three motives, the tech-choice sentences, the marker line, `goes to the person at once, one at a time, and the fleet carries on with its other lanes`, `No gate opens any other way than before`, `the stops of ADR-0070 stay stops`, `docs/decisions-log.md`, `templates/decisions-log.md`, `one dated line with its reason`, the owner's criteria.
  - Not frozen there: the colon list `a library, … a hosting` (`:73`), `then by anything else`, and the enumeration of stops inside dashes (`:77`). These are the room to cut.
- `## Installed files` phrases frozen by `tests/structure.test.sh:73-84`: every hook name, `` `po-gate` checks the gates of Law 3 ``, the `po-bounds` sentence. Also `tests/failing-check-files-an-issue.oracle.test.sh:215-216`.
- A `po inbox <id>` argument goes into a path: an id not matching `d-<digits>` must never reach the filesystem (`po inbox ../../x`).
- Two lanes may run `inbox add` at the same time: the next id must be taken atomically, never by scan-then-write.
- "Inside the repository" must also hold for a path under a worktree placed outside the root (`Worktree root` can be `../…`): compare the git common dir of the nearest existing ancestor, not only a path prefix.
- `po/src/output.rs` keeps `#[allow(dead_code)]` on `REFUSED`, since the file is out of bounds. Using it is enough.
- No migration. Decision files written by an older `po` do not exist yet, but a read-back type must still ignore unknown fields (ADR-0117) and read a missing field as `null`.

## Open questions
- Should `inbox_never_enters_git`'s installer line be the template's `.polype/inbox/` (story text) or the project's own `Decision inbox` value when that is a relative path? The story says the template's.
- Refusal codes the story leaves open: one `malformed-decision` with a message naming the field, and a code for a sensitive `context` inside the repository. Should those codes, and `inbox add`, enter `docs/interface-agent.md`? Settled in the plan.
- Should `po inbox` with a `Decision inbox` of `—` count as no inbox (exit 2, `no-inbox-setting`), as a missing line does?
- Items open in `docs/a-trancher.md:9-14` that the lead re-poses after shipping:
  - D5, `strategic`, `Flow threshold`;
  - D6 and D7, `security`, each `sensitive`, needing an absolute `context` outside the repository, such as the 2026-11-12 hand-over report, whose path this research does not know;
  - D8, `strategic`, branch protection;
  - D9, `strategic`, ADR-0109 `proposed`;
  - D10, `strategic`, ADR-0110 `proposed`.

## Complexity
Story: 3 → after reading: 3. The work is one Rust folder (input type, validation, atomic write, list, show), one installer function, and a prose rewrite under a word ceiling. Owning the s164 oracle and the two docs adds one line to a test and two doc edits, not size.

## Split
— (not at 5)
