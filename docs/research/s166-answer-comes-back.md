# Research — s166-answer-comes-back

[Story](../stories.md)

## Structuring facts
- Root cause (the story carries `Corrige`, #204 in part): an answer has no way back. `po answer` is a stub that answers `not-built` with exit 2 (`po/src/inbox/mod.rs:39-41`), and `po inbox` refuses `--answered` and `consume` as `unknown-option` (`po/src/inbox/mod.rs:26-37`). Nothing writes `status`/`answer` into a decision file; only `po inbox add` writes one (`po/src/inbox/add.rs:185-220`).
- Gap of the story, not a false assumption: `docs/interface-agent.md` is outside `Owns` (`docs/stories.md:2636`). After this story its `:5` ("chaque autre verbe répond `not-built`") is wrong for `answer`, `:24` does not name the lead's `inbox --answered` and `inbox consume`, and the decision shape (`:111-130`) does not show where consumption is noted. No test reads those lines, so nothing turns red; the lead fixes it by a framing change or leaves it to s169, which owns that file (`docs/stories.md:2694`).
- The contract has no field for "consumed". A field added does not change the contract number (`docs/interface-agent.md:30`), so the plan adds `consumed: {ref, at}` to the decision.
- `method/AGENTS.md` holds 3741 words today; `tests/decision-inbox.test.sh:101-106` caps `## What goes to the person` at 378 and the file at 3743, and this story's own ceiling is 3741 (story text: "pas plus de mots qu'avant").
- `tests/state-as-json.oracle.test.sh:151` still expects `po answer` to say `not-built`: inside `Owns`, one word of that line moves.

## Diagnostic
Reproduction on `173ac1d`, `po` built with `cargo build --release --locked` into a temp target dir, run from this worktree:
- `po answer d-0001 a` → `{"contract":1,"error":"not-built",…}`, exit 2.
- `po inbox --answered` → `unknown-option`, exit 2.
- `po inbox consume d-0001 x` → `unknown-option`, exit 2.
- H1, "the external agent can edit the decision file itself". Refutation sought: does anything check what is written into a decision? `read_file` accepts any parseable object (`po/src/inbox/decision.rs:103-106`), and `Decision` keeps `answer` as a free `Value` (`:62`). A hand edit could name any key or free text. Discarded: it is the interpretation ADR-0107 removes ("une réponse hors des options listées est refusée par un script", `docs/decisions/ADR-0107-…md:46`).
- H2, "`po inbox add` already covers the answer by posing a new decision". Refutation sought: does `add` accept an `answer` or a `status`? `NewDecision` denies unknown fields (`decision.rs:21-35`), and `write` always sets `pending` and `answer: None` (`add.rs:199-200`). Discarded.
- H3, "the missing piece is a verb of `po` that writes only a listed key into a pending decision, plus a list and a consume mark for the lead". Refutation sought: does an ADR forbid `po` from rewriting a decision? ADR-0117 names `answer` among `po`'s verbs (`ADR-0117-…md:25`). ADR-0107 makes the lasting trace what the answer produces, citing the decision's id (`ADR-0107-…md:26`). Kept.

## Story
`po answer <id> <key>` passes a pending decision to `answered` with `answer.key` and `answer.at`, and prints it. Refusals write nothing:
- a key outside `options` → `not-an-option` (1);
- a decision already answered → `already-answered`;
- an unknown id → `unknown-decision`.

`po answer` launches no command, model or session. `po inbox --answered` lists the answered decisions the lead has not consumed. `po inbox consume <id> <ref>` notes what the answer produced and takes the decision out of that list. `method/AGENTS.md` says the lead reads answered decisions at session start, writes what each produces where it lives citing its id (only the id for a `sensitive` one), then consumes it. That rule is judged in review; a word ceiling is tested.

Criteria: `answer_accepts_only_a_listed_option`, `answer_refuses_twice_and_unknown`, `answer_launches_nothing`, `answered_decisions_are_listed_until_consumed`, `rules_say_who_consumes`.

## Current code
- `po/src/main.rs:24`: `answer` goes to `inbox::answer(&rest)` with every argument after the verb; `inbox` to `inbox::main(&rest)` (`:23`). `main.rs` needs no change.
- `po/src/inbox/mod.rs`:
  - `main` dispatch: `[]` → list, `["add"]` → add, `[id]` not starting with `-` → show, else `unknown-option` (2) (`:26-37`). So `--answered` already falls to `unknown-option`, and `consume` alone reaches `show("consume")` → `unknown-decision`.
  - `locate()` gives the project and the inbox folder, refusing `not-a-project` and `no-inbox-setting` (also for `—`) with exit 2 (`:56-78`).
  - `list()` keeps status `pending` (`:80-97`); `show(id)` checks `id_number` before any path, then `unknown-decision` (1) or `unreadable-decision` (2) (`:99-121`); `unknown(id)` (`:123-125`).
  - `pending_ids` (`:45-53`) is what `po state` calls (`po/src/state/mod.rs:172`): it filters `pending`, so an answered decision leaves `waiting` with no change there.
- `po/src/inbox/decision.rs`:
  - `Decision` (`:49-63`): every field but `id` and `status` is an `Option`, always serialised; no `deny_unknown_fields`, and no catch-all, so a field it does not know is dropped on a rewrite.
  - `options: Option<Vec<Value>>` (`:56`): keys are read as `.get("key")` strings.
  - `id_number` (`:66-72`), `read_dir` (`:76-101`, `*.json` only, numeric order), `read_file` (`:103-106`).
- `po/src/inbox/add.rs`:
  - `kept_out_of_git(project, dir)` (`:159-169`) and `place` (`:114-141`) are private to `add`.
  - `write` builds a `Decision` literal (`:187-201`) and publishes by temp file plus `hard_link` (`:202-219`).
- `po/src/output.rs`: `reply`, `error`, `OK`/`REFUSED`/`UNREADABLE` (`:5-44`). `REFUSED` still carries `#[allow(dead_code)]`; the file is out of bounds.
- `po/Cargo.toml:7-10`: `serde`, `serde_json` (no `preserve_order`, so a `Map` rewrite sorts keys), `chrono`. Nothing is missing.
- `method/AGENTS.md:67`: the lead's session-start sentence, the natural place for the consume rule.

## Attachment points
- `po/src/inbox/mod.rs`:
  - `main` gains `["--answered"]` and `["consume", id, ref]`;
  - `answer(args)` replaces the stub.
- New files under `po/src/inbox/` are allowed (`answer.rs`, a shared rewrite helper).
- `po/src/inbox/decision.rs`: `Decision` gains `consumed` and a flattened catch-all for unknown fields; `add.rs:187-201` fills both.
- `add.rs`: `kept_out_of_git` becomes `pub(super)` if `answer` reuses it.
- `method/AGENTS.md:67`.
- `tests/state-as-json.oracle.test.sh:151`.

## Verified interfaces
- Exit codes: 0 done, 1 refused, 2 unreadable or not executable (`docs/interface-agent.md:29`). An error is `{"contract":1,"error","message"}` (`:31`).
- `answer` (`docs/interface-agent.md:161-173`):
  - refusal codes `unknown-decision`, `already-answered`, `not-an-option`; a refusal writes nothing;
  - accepted → `"status": "answered"`, `"answer": {"key": "a", "at": "<date>"}`;
  - no free text: "le porteur qui ne veut aucune des options ne répond pas par cette commande" (`:171`);
  - answering launches nothing; `continue` relaunches, and the lead cites the `id` in what it writes (`:173`).
- Date with offset: `chrono::Local::now().to_rfc3339_opts(SecondsFormat::Secs, false)`, as `add.rs:189`.
- `po inbox add` from a worktree writes into the root's inbox (`tests/decision-inbox.oracle.test.sh:113-117`), through `Project::find` (`po/src/project.rs:38-48`).
- The oracle's launch check copies `tests/state-as-json.oracle.test.sh:174-195`: stubs for forge, model and network commands, plus a logging `git`.
- `rustc 1.99` here, but nothing pins a minimum version: no `rust-version` in `po/Cargo.toml`, no toolchain file, nothing in `ci.yml`. The source build is the fallback of ADR-0115 on a user's machine, so the plan avoids recent std APIs such as `File::lock` (1.89).

## Traps
- **Two answers at once.** Two external agents (voice and chat) may answer the same decision. Read, check `pending`, then write is a race in which both succeed. Locking the decision file itself fails too: the rewrite renames a new inode in, and a waiter then reads the old one. A separate lock file, taken with `create_new` and removed after, is portable on any Rust version.
- **Unknown fields.** `Decision` drops fields it does not know (`decision.rs:49-63`). Rewriting a file written by a newer `po` would lose data, against ADR-0117 (`ADR-0117-…md:32`). A `#[serde(flatten)]` map keeps them, and field order stays as written for known fields.
- **The key is outside data.** Compare it byte for byte with each listed key: no trim, no case folding, never into a path or a shell. The id goes into a path: the `id_number` check comes first, as in `show`.
- **Atomic rewrite.** Write a temp file in the folder, then `rename` over `<id>.json`, so `po inbox` never reads half a file. The temp's extension is not `.json`, so `read_dir` skips it.
- **Frozen phrases** in `## The project lead`: `tests/project-lead.test.sh:276-289` (`reads the state \`po-session\` prints`, `answers the question it was asked first, …`). The enumeration between dashes, "as its first picture of the project", and "a line `po-session` marks as presumed…" are frozen nowhere (grep over `tests/`, `method/`, `docs/*.md`). A draft keeping the frozen phrases measured 3739 words on a scratch copy.
- `tests/decision-inbox.test.sh:38` already sends ill-formed ids through `po inbox <id>`; `consume` must apply the same check.
- s168 reads `blocks` of `pending` decisions only (`docs/stories.md:2678, 2683`). An answered one releases its lanes there without this story doing anything.
- No migration: no decision file in the wild carries `consumed`; an absent one reads as not consumed.

## Open questions
- Codes for `consume` that no document fixes: on a pending decision, a second consume, an empty or multi-line `ref`. The plan settles them (lead verb, outside the external contract, `docs/interface-agent.md:24`).
- Does "ne lance aucune commande" forbid the read-only `git` calls that locate the project (`project.rs:38-40`)? Read as s164 read it for `state` (`tests/state-as-json.oracle.test.sh:164-196`): `git` plumbing that writes nothing is allowed, and every other process is not.
- Should `po answer` refuse when the inbox folder is no longer ignored (setting changed after the decision was posed)? The plan says yes, reusing `kept_out_of_git`.
- Should `consume` check that `ref` exists (an ADR path, a story id)? The contract also allows "une ligne de plan" (`interface-agent.md:173`), which is no path to check. The plan says no: one non-empty line.

## Complexity
Story: 3 → after reading: 3. One Rust folder (a guarded rewrite under a lock, a list, a mark), one sentence of rules under a word ceiling, one word of the s164 oracle. The doc gap adds no code.

## Split
— (not at 5)
