# Research — s178-security-findings-stay-private

[Story](../stories.md)

## Structuring facts
- Root cause: `po record review` writes the reviewer's answer whole into `docs/reviews/<id>.md` — `compose::strip_own_header(&answer)` (`po/src/record/mod.rs:182`), then `write_atomic(&path, &text)` (`po/src/record/mod.rs:212`); no line of the answer is set aside. Reproduced: a security finding carrying a witness string comes out in the review file, untracked under `docs/` (see `## Diagnostic`), and the fix run commits "the review that listed them" (`method/agents/implementer.md:47`), `/po-ship` Step 1 too (`method/commands/po-ship.md:51`).
- No story assumption is false. One the story leaves implicit holds: `po record review` is the single place the reviewer's text passes before being written (`method/commands/po-review.md:38`), so the split goes there.
- `po inbox add` reads its decision from stdin and prints its own JSON (`po/src/inbox/add.rs:213-261`, `locate()` printing at `po/src/inbox/mod.rs:107-129`): `po record` cannot call it as is; the add path needs an entry that returns instead of printing.
- A decision with `blocks: [<id>]`, not consumed, holds that story's lane in `po next` (`po/src/next/mod.rs:110-121`, `po/src/next/wave.rs:55`).
- Where the text lives outside the repository, and who removes it: ADR-0123, `accepted` 2026-11-14 — the new setting `Private folder:`, removed by the person (owner, d-0020, d-0021).

## Diagnostic
- Reproduction (scratch repo under `mktemp -d`, the installed `po` 0.2.0, the method's `po-gate.sh` and `templates/review.md`): an answer whose `## Findings` holds `- critical — security — src/a:1 — <witness>` piped to `po record review s01-a` → exit 0, `{"path":"docs/reviews/s01-a.md"}`; `grep -c <witness> docs/reviews/s01-a.md` → 1; `git status --porcelain` → `?? docs/`. Nothing was created in the worktree.
- H1 — `po record` copies the answer whole. Refuting observation: any filter between stdin and the write. None: the body is the stripped answer plus the oracle lines (`po/src/record/mod.rs:182-198`), written as is. **Kept.**
- H2 — a later stage drops security findings before git. Refuting observation: a commit of the review with the finding in it. The implementer's fix commit includes the review (`implementer.md:47`), `/po-ship` Step 1 commits it (`po-ship.md:51`); `po-ship.md:99` only holds back *filing* an issue. **Discarded.**
- H3 — the reviewer is told to keep security text out of its answer. Refuting observation: a rule placing lens findings in `## Findings`. `review-lenses/SKILL.md:26`: every lens finding is "written under `## Findings` beside the others". **Discarded.**

## Story
A security finding of a review stays on the machine, in the decision inbox; the recorded review keeps only a count and the decision's id. Criteria: `security_findings_are_marked`, `recorded_review_holds_a_count_and_an_id`, `nothing_reaches_git`, `verdict_still_counts_them`, `earlier_reviews_read_the_same`, `fix_run_still_reads_them` (judged in review), `words_hold`.

## Current code
- `po/src/record/mod.rs:139-247` `main`: parse → worktree on `story/<id>` (`:100-131`) → `.polype/version`, template → stdin answer → body = stripped answer → `## Tests` oracle line (`:183-198`, skipped with `--composed`) → append or first write (`:200-214`) → `po-gate findings-shape` on the written file (`:216-245`); a shape refusal returns `written: true` (`:219-229`).
- `po/src/record/compose.rs`: `strip_own_header` (`:57-72`), `insert_oracle` (`:76-104`), `first_write`/`append` (`:106-120`). No reading of `## Findings`.
- `po/src/inbox/add.rs`: `main` (`:16-64`) validates (`validate`, `:70-100`), demands for `sensitive` an absolute `context` with `place(..) == Place::Outside` (`:32-45`, `place` `:114-141`: under the root, `.git` included, or in another worktree of the same repo → refused), `kept_out_of_git` (`:159-169`), `write` with `create_new` + hard link (`:185-222`).
- `po/src/inbox/decision.rs:9-43`: `Motive::Security` exists; `NewDecision` fields `motive, sensitive, question, context, options (2..=3 Choice{key,label,consequence}), recommended, why, reversible, blocks`.
- `po/src/inbox/mod.rs:171-193` `show`: `po inbox <id>` prints one decision, answered or consumed alike.
- `method/hooks/po-gate.sh:78-95` `ship_allowed` reads only `Ship allowed:`, `Review status:`, `Reviewed tree:`; never `## Findings` nor `Max severity:`. `:98-136` `findings_shape`: in the last block's `## Findings`, a non-list line is refused only when its first word is a severity (`first()`); a list item only when it names a severity without opening with one.
- `method/templates/review.md:56-58`: the finding shape; `:53` `Lenses run:`. 557 words.
- `method/agents/implementer.md:29-30`: "The review report is your to-do list"; `method/commands/po-execute.md:52-54`: the fix-run prompt points at `docs/reviews/<id>.md` only.
- `method/commands/po-review.md:38`: a refusal with `"written": false` → stop naming `polype install`; `:42`: exit 1 → re-ask the reviewer once, then a blocked report.
- `docs/interface-agent.md:159`: a `sensitive` decision's `context` points to a file outside the repository; `:265`: `record review` row; `:273` "Elle ne rend aucun contenu de fichier, seulement des chemins."

## Attachment points
- `po/src/record/mod.rs` between the strip (`:182`) and the oracle insertion (`:183`): scan the answer's `## Findings`, refuse a malformed mark before anything is written, move marked items out, put a count line in their place. A new `po/src/record/security.rs` beside `compose.rs`.
- `po/src/inbox/`: a non-printing add (`locate` split into a quiet part; `add.rs` body returning `Result`) that `record` calls; `po inbox add` keeps its outputs.
- Version `0.2.0` → `0.3.0`: `po/Cargo.toml:3`, `po/Cargo.lock:165`, `bin/polype:27` (ADR-0122).
- Method texts: `templates/review.md:57-58`, `agents/reviewer.md` `## Your answer`, `skills/review-lenses/SKILL.md:26`, `commands/po-review.md:38,42`, `agents/implementer.md:30`, `commands/po-execute.md:54`.
- `docs/interface-agent.md` (`record review` row and the sensitive paragraph); ADR-0090 frontmatter `superseded-by`.

## Verified interfaces
- `output::reply`, `output::error`; codes `OK 0`, `REFUSED 1`, `UNREADABLE 2` (`po/src/output.rs:5-8,32,37`).
- `Refusal { error, message, written, refused: Option<Vec<String>> }` (`po/src/record/mod.rs:51-58`).
- `Project::find(cwd)` resolves a worktree to the main checkout (`po/src/project.rs:38-48`); `Project::setting` reads `AGENTS.local.md` of that root (`:54-67`); `Project::name()` the root's basename (`:73-78`).
- `Decision inbox` is resolved from the main root (`po/src/inbox/mod.rs:116-128`); default `.polype/inbox/` in this repo (`AGENTS.local.md`).
- Crate dependencies: `serde`, `serde_json`, `chrono` only (`po/Cargo.toml`); `std::os::unix::fs::{DirBuilderExt, OpenOptionsExt}` give modes 0700/0600 without a new crate.
- Tests: `PO="${CARGO_TARGET_DIR:-$ROOT/po/target}/release/po"` (`tests/lib.sh:7`); `tests/run.sh:11-27` builds `po` and sets `CLAUDE_CONFIG_DIR` to a temp dir, but leaves `HOME` and `XDG_STATE_HOME` as they are.
- The record oracle's `fixture`, `review_answer`, `rec`, `in_order` (`tests/record-writes-reports.oracle.test.sh:14-93`) are sourced by `tests/record-writes-reports.test.sh:6`, the existing pattern to reuse.

## Traps
- **The suite and `HOME`**: nothing in `tests/run.sh` redirects `HOME`; a test recording a security finding must set `HOME` and `Private folder` inside its scratch dir, or a `~/` value would reach the developer's real folders.
- **A new template setting**: `tests/leftovers.test.sh:20-26` and `tests/platform-setting.test.sh:115-121` run `bin/polype check` on this repository and fail on any `missing setting:` (`bin/polype:603-627`): this repository's `AGENTS.local.md` must carry it.
- **Version pins**: `0.2.0` written as a fixture `.polype/version` that must equal `PO_VERSION` (`po/src/context/mod.rs:124-131`, else a `method-version-mismatch` warning): `tests/state-carries-session-lines.oracle.test.sh:83,204`, `tests/project-lead.test.sh:103` — both in `Owns`. Pins independent of `PO_VERSION` (fixture text compared to itself): `tests/trust-signals.oracle.test.sh:76,168`, `tests/commands-read-po-state.oracle.test.sh:59,69,131,134` — unchanged. `tests/driver-next-action.oracle.test.sh:20` and `tests/po-prebuilt-and-verified.oracle.test.sh:27` read the version from `bin/polype`.
- **Issue #254**: `tests/readme-onboarding.test.sh` clones the committed HEAD and rebuilds `po` into the shared `CARGO_TARGET_DIR`; uncommitted `po/` changes give a false red.
- **Pinned phrases outside `Owns`**: `tests/review-findings-shape.test.sh:66-84` (in `Owns`) pins the template's finding line, "never a heading", "a finding never starts with `Ship allowed:`", reviewer `## Your answer` and `po-review` `## Recording`/`## Outcome` phrases; `tests/review-header-recorded.oracle.test.sh:19-28`, `tests/review.test.sh`, `tests/wiring.test.sh` pin `reviewer.md`, `po-review.md`, `templates/review.md` (outside `Owns`); `tests/run-ledger.test.sh:150` pins `implementer.md`'s fix-run record sentence; `tests/model-routing.test.sh:61` pins `po-execute.md`'s "A fix run follows the same rule…"; `tests/execute.test.sh:43` pins `implementer.md:24`; `tests/review-lenses.test.sh:24-29` the `Lenses run:` line. All must stay green.
- **Word ceilings** (`LC_ALL=C wc -w`): `templates/review.md` 557, capped at 558 by `tests/record-writes-reports.test.sh:27`; `po-review.md` 1147 (< 1244 by the same test); `po-execute.md` 850; `reviewer.md` 1120; `implementer.md` 1144; `review-lenses/SKILL.md` 824; `review-antihallu/SKILL.md` 1605; `templates/agents-local.md` 1115; `hooks/po-gate.sh` 5843.
- **ADR-0090**: body frozen by a cksum and frontmatter pinned whole (`tests/intake-issue-becomes-a-story.oracle.test.sh:116-124`, in `Owns` for that assertion).
- `/po-ship` Step 3 (`po-ship.md:99`) still holds back every finding of a review whose security lens ran: s179's, untouched here.
- No migration. No new crate.

## Open questions
- Settled by the owner on 2026-11-14, ADR-0123 `accepted`: the text lives under a new setting `Private folder:` (d-0020, option B), the person removes it; the decision holds the lane only for a critical or major security finding (d-0021).
- The answer may still carry security detail outside `## Findings` (a `Lenses run:` trigger, `## Not verified`): only a model rule in `reviewer.md` covers it; judged in review.

## Complexity
4 → 4: one Rust module and a refactor of the inbox add path, five method files under word ceilings, an ADR; the risk the story names (the fix run and the gate must still read the text) is real but contained to `po record`.

## Split
Not needed at 4.
