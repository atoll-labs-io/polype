# Research — s186-stale-decisions-are-flagged

[Story](../stories.md)

## Structuring facts
- **False assumption — the case #331 cites is not caught by the story's rule.** d-0022 was posted with `"blocks": []` (`.polype/inbox/d-0022.json`, main checkout, git-ignored), so criterion `stale_decision_is_flagged` ("toutes les stories de `blocks` sont livrées") never marks it, and criterion `framing_blocks_are_never_stale` ("… ou rien, n'est jamais marquée") forbids marking it. `po` itself still posts that shape: `po record review` gives a security decision `blocks: [id]` only for a critical or major finding, `Vec::new()` otherwise (`po/src/record/security.rs:186`, pinned by `tests/security-findings-stay-private.test.sh:85`), per the owner's d-0021 (a minor finding holds no lane). #331 says it: "nothing marks a pending decision whose `blocks` story, **or the story it came from**, has shipped".
- Root cause, part 1 (no staleness anywhere): `po state` keeps a decision in `waiting` on `status == "pending"` alone (`po/src/state/mod.rs:57-64`), `po inbox` the same (`po/src/inbox/mod.rs:159`), and `po answer` checks only the status and the key (`po/src/inbox/mod.rs:55-71`). None reads the landed set. Proof: reproduction below.
- Root cause, part 2 (no link to the origin story): a decision has no field naming the story it is about (`po/src/inbox/decision.rs:22-35` `NewDecision`, `deny_unknown_fields`; `:48-69` `Decision`). The only story it may name is in `blocks`, and `blocks` means "hold this lane" (`po/src/next/mod.rs:140-151` `holding_decision`). A decision about a story that it must not hold therefore names no story at all.
- **Owns gap.** Fixing the cited case needs the decision to carry its origin story, set by `po record review`: `po/src/record/security.rs:169-187` builds `NewDecision` as a struct literal with every field, so any field added to `NewDecision` (`decision.rs:22`) does not compile until that literal changes. `po/src/record/security.rs` is not in s186's `Owns` (it is in s187's, which depends on s186). Under the blocks-only reading the story wrote, no gap, but #331's case stays open.
- Choice for the owner (ADR-0127, `proposed`): what `po answer` does on a stale decision, and how a decision knows its story. No verb retires a pending decision: `consume` refuses `pending` (`po/src/inbox/mod.rs:87-89`), so a refused answer leaves the decision in `waiting` for good.

## Diagnostic
Reproduction on the code as it stands (`0161d7b`), `po` 0.5.0 built from the worktree into `/tmp/s186-target` (nothing written in the worktree), scratch repo `/tmp/s186-repro.*`: stories s01-alpha (landed, commit `s01-alpha: Alpha`) and s02-beta (not landed); three pending decisions, d-0001 `blocks ["s01-alpha"]`, d-0002 `blocks []`, d-0003 `blocks ["s02-beta"]`.
- `po state`: `waiting ["d-0001","d-0002","d-0003"]`, `held [s02-beta decision d-0003]`; no field tells d-0001 or d-0002 apart.
- `po inbox`: the three decisions with the same 13 keys, no mark.
- `po answer d-0002 a` and `po answer d-0001 b`: both `status: answered`, exit 0.
Defect reproduced for both shapes. Real timeline (`.polype/inbox/d-0022.json`, `git log main`): d-0022 asked 2026-11-14 17:10:48, s178 landed 17:30:46 (`c4db602`), answered `a` "Le corriger dans s178" 18:15:44, consumed as "story s180, PR #323". d-0024 (`blocks []`, about s180) was answered 19:54, before s180 landed (21:02): not stale.

| # | Hypothesis | Refuted by | Result |
| --- | --- | --- | --- |
| 1 | `po state`/`po inbox` list pending decisions without reading the landed set | a read of `Landed` in those paths, or a mark in the reproduction | kept: `state/mod.rs:57-64`, `inbox/mod.rs:159`; no mark |
| 2 | `po answer` accepts any listed key of a pending decision, whatever its stories | a refusal or a mark on d-0001 | kept: `inbox/mod.rs:55-71`; exit 0 |
| 3 | d-0022 named s178 in `blocks`, so a blocks-only rule would have caught it | `blocks` of d-0022 | **discarded**: `"blocks": []`; `security.rs:186` posts `[]` for minor findings |

## Story
A pending decision whose stories have all shipped is marked stale by `po state` and `po inbox`; a framing block or an empty `blocks` is never marked; `po answer` on a stale decision never records silently (refuse with a new error, or record with the mark — owner's choice); `docs/interface-agent.md` says a decision holds its lanes until consumed (#279, judged by reading); `po` goes up a minor step (0.5.0 → 0.6.0, three places, `bin/po-version-check`).

## Current code
- `po/src/state/mod.rs:19-35` `State`: `waiting` and `answered` are `Option<Vec<String>>`, ids only; `compose` (`:56-98`).
- `po/src/inbox/mod.rs`: `list` (`:151-168`) reads the folder through `locate` (`:122-124`) and `decision::read_dir`, never `Context`; `show` (`:191-213`); `answer` (`:47-72`) goes through `rewrite::rewrite` (`rewrite.rs:33-92`), which serialises the whole `Decision` into the file and replies with the same object (`rewrite.rs:79,91`).
- `po/src/inbox/decision.rs:48-69` `Decision`: `consumed` is `skip_serializing_if = "Option::is_none"` (`:65-66`), the precedent for a field absent until it applies; `extra` (`:67-68`) keeps unknown fields of a file.
- `po/src/context/lanes.rs:75-121` `Landed::read(project, target)`, `contains(id)` (also matches a bare `s<n>:` subject); re-exported `pub` from `po/src/context/mod.rs:17`, so `inbox/` can read it without touching `context/`.
- `po/src/context/mod.rs:93-98` `Inbox::answered_not_consumed`, the s184 shared predicate; `inbox/mod.rs:179` keeps its own copy.
- `po/src/next/mod.rs:140-151` `holding_decision`: any unconsumed decision naming the story in `blocks` holds it, status not read — by design (#279, `case_decisions_02_answered_not_consumed`, `tests/fixtures/driver-cases/decisions.cases:14-20`).
- `docs/interface-agent.md:95-96` (`waiting`, `answered`), `:131-163` (decision shape; `:159` `blocks`; `:160` "jusque-là, la décision a exactement la forme ci-dessus"), `:184-199` (`answer` errors and reply), `:30` (contract 1, added field or value keeps it).

## Attachment points
- Staleness predicate: one function in `po/src/inbox/decision.rs` taking a `&Landed` (and, under the origin option, the new field), used by `state/` and `inbox/`.
- `po state`: a new top-level field beside `waiting` (ids), since `waiting` is a list of strings and cannot carry a mark without a contract change.
- `po inbox`, `po inbox <id>`, `po answer`: the mark on the decision object at reply time, never written into the file (staleness changes when a story lands after the file was written); `rewrite::rewrite` would persist any field held in `Decision`.
- Landed set in `inbox/`: `Landed::read(&project, target)` with `Target branch` read through `project.setting` (`po/src/inbox/mod.rs:136` reads `Decision inbox` that way).
- Origin field (if chosen): `NewDecision` + `Decision` in `decision.rs`, `add.rs:212-230` `write`, `record/security.rs:169-187`.

## Verified interfaces
- `pub struct Landed`, `pub fn read(project: &Project, target: &str) -> Landed`, `pub fn contains(&self, id: &str) -> bool` (`lanes.rs:75,81,113`).
- `pub fn rewrite(project, dir, id, change: impl FnOnce(&mut Decision) -> Result<(), Refusal>) -> i32` (`rewrite.rs:33-38`); `Refusal = (&'static str, String)`, printed with exit 1 (`:18,75-77`).
- `Stories::find(&self, id) -> Option<&Story>` (`po/src/context/stories.rs:148`) — tells a story id from a framing name such as `"stories"` or `"M22 framing"` (real `blocks` of d-0026, d-0003).

## Traps
- Output equals file: `tests/decision-inbox.oracle.test.sh:110` and `tests/answer-comes-back.oracle.test.sh:108` compare the reply with the file; `tests/decision-inbox.oracle.test.sh:248` requires every pending decision to have the same keys. Their fixtures never land `s01-one`, so a mark present only on a stale decision keeps them green; a mark always present (`"stale": false`) breaks the first two. `tests/decision-inbox.oracle.test.sh` is not in `Owns`.
- `tests/verbs-read-project-context.oracle.test.sh:21` `normalised` freezes `po state`: the new field joins its `del(...)` (in `Owns`).
- Version: three places (`po/Cargo.toml:3`, `po/Cargo.lock`, `POLYPE_VERSION` of `bin/polype`), checked by `bin/po-version-check` in the suite.
- `po/src/output.rs:46` `not_built` warns at build: s187's, untouched.
- `method/hooks/po-session.sh:78` lists pending decisions by id; it will not show the mark. Not in `Owns`; the criteria do not ask for it.
- `po inbox` today needs no git; reading `Landed` adds a `git log` per call and a dependency on `Target branch` (missing setting → no mark, never a refusal).

## Open questions
- Owner (ADR-0127): `po answer` on a stale decision — record and mark, refuse, or refuse unless confirmed.
- Owner (ADR-0127): how a decision knows its story when it holds none — a new optional field set by `po record review` (needs `record/security.rs` in `Owns`), or `blocks` only (#331's case stays open; criterion `framing_blocks_are_never_stale` as written).
- Lead: under the origin option, amend the story — `Owns` gains `po/src/record/security.rs`, and "ou rien" in `framing_blocks_are_never_stale` becomes "ou rien, sans story d'origine".
- Lead: should `po-session` show the mark (out of `Owns`, out of the criteria)?

## Complexity
Story 3 → 3 with blocks only; 4 with the origin field (a contract field on `inbox add`, `record review`, `state`, `inbox`, `answer`, the contract text, a minor version).

## Split
Not needed at 4.
