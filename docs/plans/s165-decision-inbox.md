---
validated: yes
---
# Plan — s165-decision-inbox

[Story](../stories.md) · [Research](../research/s165-decision-inbox.md)

Branch `story/s165-decision-inbox`. Read `docs/research/s165-decision-inbox.md` first; this plan builds on it without repeating it. PR #252 (`553160a`) lifted the research's blocker: `tests/state-as-json.oracle.test.sh`, `docs/interface-agent.md` and `docs/installation.md` are now in this story's `Owns`.

## Story
`po inbox add` reads one decision as JSON on stdin and validates it. It gives the decision the next id and writes it under the `Decision inbox` folder of the main checkout, never into git. `po inbox` lists the pending decisions, oldest first. `po inbox <id>` prints one decision. A `sensitive` decision must point its `context` outside the repository. The installer ignores the template's inbox location. The rules send everything that goes to the person through the inbox first. `docs/a-trancher.md` goes. Criteria: `add_writes_one_decision_file`, `add_refuses_a_malformed_decision`, `list_prints_pending_oldest_first`, `inbox_never_enters_git`, `sensitive_decisions_carry_no_detail`, `rules_send_every_stop_to_the_inbox`, `provisional_inbox_is_gone`.

### Details this plan settles (the research's open questions; none is a choice for the owner)
| # | Question | Settled as |
| --- | --- | --- |
| 1 | Which `.gitignore` line the installer adds | The template's `Decision inbox` value, read from `$method/templates/agents-local.md`, as the story says. A project that sets another folder inside its repository is refused by `po inbox add` with `inbox-not-ignored`, which tells it what to fix |
| 2 | Refusal codes | `no-inbox-setting` (2); `malformed-decision` (1, the message names the field or rule); `sensitive-context-in-repo` (1, for a sensitive decision whose `context` is missing, relative or inside the repository); `inbox-not-ignored` (1); `unknown-decision` (1, for `inbox <id>` with an unknown or ill-formed id); `unreadable-decision` (2, for `inbox <id>` on a file that does not parse); `inbox-unwritable` (2, an I/O failure); `unknown-option` (2, any other argument). Plus `not-a-project` (2), as for `state` |
| 3 | `Decision inbox: —` | The same as a missing line: exit 2 with `no-inbox-setting`, for `add`, the list and show |
| 4 | Oldest first | Ascending numeric id. Ids are handed out in order, and `d-10000` sorts after `d-9999` |
| 5 | `context` of a decision that is not sensitive | Optional: absent → `null`. Otherwise a path, which `po` never opens |
| 6 | Option shape | `key`, `label` and `consequence` required as strings (the contract's shape); keys non-empty and distinct, since s166's `answer` names one |
| 7 | An unreadable file while listing | Skipped. `po state` already reports it as `unreadable-decision` (`po/src/state/mod.rs:173-176`), so the `inbox` reply keeps its contract shape, `{contract, pending}` |
| 8 | Id allocation between two lanes | Write `.<id>.json.tmp` in the folder, `std::fs::hard_link` it to `<id>.json` (fails if taken → next id), remove the temp. Atomic, never overwrites, and a reader never sees half a file |
| 9 | "Inside the repository" | The path, made absolute against the root, is under `project.root`. Or its nearest existing ancestor answers `git rev-parse --path-format=absolute --git-common-dir` with the project's common dir, which catches a worktree placed outside the root |
| 10 | Docs | `inbox add` and the codes enter `docs/interface-agent.md`; the third `.gitignore` line enters `docs/installation.md` |

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Project root, settings, git helper | Repository: `Project::find`, `setting`, `git` (`po/src/project.rs:20-67`) | — |
| One object out, exit codes, panic hook | Repository: `output::reply`, `output::error`, `REFUSED` (`po/src/output.rs:3-44`) | — |
| Inbox folder resolution | Repository rule `po/src/state/mod.rs:166-171`, copied into `inbox/` | `state/` is out of bounds and its function is private |
| Pending ids for `po state` | Repository: `pending_ids` (`po/src/inbox/mod.rs:33-57`), kept with its signature, now built on the shared reader | — |
| Typed JSON in and out, local date with offset | Dependencies already installed: `serde`, `serde_json`, `chrono` (`po/Cargo.toml:7-10`, ADR-0118) | The standard library has no JSON |
| Atomic, no-overwrite write; stdin; dirs | Standard library (`fs::hard_link`, `io::read_to_string`, `fs::create_dir_all`) | — |
| Ignore check | `git check-ignore -q` through `project::git` | — |
| `.gitignore` line in the installer | Repository: the pattern of `ignore_worktrees_and_env` (`bin/polype:562-570`) and the template read of `missing_settings` (`:583-607`) | — |
| Validation of the input decision | New code (`inbox/`): length, line, option count, recommended in keys, sensitive context | serde checks presence and types only. The ladder keeps validation at this trust boundary |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/decision-inbox.oracle.test.sh` | `2626157713 12113` |

| Criterion | Test |
| --- | --- |
| `add_writes_one_decision_file` | `test_add_writes_one_decision_file` |
| `add_refuses_a_malformed_decision` | `test_add_refuses_a_malformed_decision` |
| `list_prints_pending_oldest_first` | `test_list_prints_pending_oldest_first` |
| `inbox_never_enters_git` | `test_inbox_never_enters_git` |
| `sensitive_decisions_carry_no_detail` | `test_sensitive_decisions_carry_no_detail` |
| `rules_send_every_stop_to_the_inbox` | — the rule speaks to a model: judged in review. Only the word ceiling is tested (task 9). Candidate for a `po-eval` control arm (#208) |
| `provisional_inbox_is_gone` | — a deleted file and one settings line, read by no script: judged in review from the diff |

The oracle fixes these interfaces:
- `po` is reached through `$PO`.
- Input carries no `id`, `asked`, `status` or `answer`.
- The error codes are those of row 2 above.
- The installer prints `added .polype/inbox/ to .gitignore` on stderr, only when it adds the line.

## Tasks
1. [x] **Types and reader** in `po/src/inbox/` (new files there allowed; nothing else in the crate changes).
   - `Motive`: enum, kebab-case: `incoherence`, `new-idea`, `strategic`, `technical-choice`, `stop`, `security`.
   - `NewDecision`: from stdin, `#[serde(deny_unknown_fields)]`.
     - Fields: `motive`, `sensitive` (`#[serde(default)]`), `question`, `context: Option<String>` (default), `options: Vec<Choice>`, `recommended`, `why`, `reversible: bool`, `blocks: Vec<String>`.
     - `Choice {key, label, consequence}`, also `deny_unknown_fields`.
   - `Decision`: written and read back.
     - Field order as in `docs/interface-agent.md:112-130`: `id`, `asked`, `motive`, `sensitive`, `question`, `context`, `options`, `recommended`, `why`, `reversible`, `blocks`, `status`, `answer`.
     - No `deny_unknown_fields`. Every field except `id` and `status` is an `Option` that is always serialized, so a field an older file lacks reads as `null` (ADR-0117).
   - `read_dir(dir) -> io::Result<(Vec<Decision>, Vec<PathBuf>)>`: `*.json` files only, sorted by numeric id.
   - `pending_ids` keeps its signature and is rebuilt on `read_dir`, so `waiting` and `pending` always agree.
   - Fails if wrong: `test_list_prints_pending_oldest_first`; the agreement test of task 9; `tests/state-as-json.oracle.test.sh` `test_waiting_reads_the_inbox_setting`.
2. [x] **List and show.** `inbox::main(args)`:
   - Dispatch:
     - `[]` → list;
     - `["add"]` → task 3;
     - `[id]` → show;
     - an argument starting with `-`, or more arguments → `unknown-option` (2).
   - Outside a project → `not-a-project` (2). Folder resolution as in row 3 and `state/mod.rs:166-171`.
   - List: `{"contract":1,"pending":[…]}` with status `pending` only; a missing folder → `[]`.
   - Show:
     - an id not matching `^d-[0-9]+$` never reaches the filesystem → `unknown-decision` (1);
     - an absent file → `unknown-decision` (1);
     - a file that does not parse → `unreadable-decision` (2);
     - otherwise the decision with `contract`.
   - Fails if wrong: `test_list_prints_pending_oldest_first`; the path test of task 9.
3. [x] **Add.** Order:
   1. Project.
   2. Setting (`no-inbox-setting` names `Decision inbox`).
   3. Read stdin and parse `NewDecision`; any serde error → `malformed-decision` (1).
   4. Rules → `malformed-decision`:
      - `question` non-empty after trim, no `\n` nor `\r`, at most 200 `chars()`;
      - 2 or 3 options;
      - keys non-empty and distinct;
      - `recommended` among keys;
      - `why` non-empty after trim.
   5. When `sensitive`: `context` present, absolute and outside the repository (row 9), else `sensitive-context-in-repo` (1).
   6. Folder outside the repository, or `git check-ignore -q <rel folder>/d-0000.json` succeeds from the root; otherwise `inbox-not-ignored` (1), before anything is created.
   7. `create_dir_all`. The next id is max numeric id of `d-*.json` + 1, formatted `d-%04d`.
   8. `asked` = `chrono::Local::now().to_rfc3339_opts(SecondsFormat::Secs, false)`, `status` `pending`, `answer` `null`.
   9. Write pretty JSON, then the atomic link of row 8; I/O failure → `inbox-unwritable` (2).
   10. Print the decision with `contract`, exit 0.
   - Fails if wrong: `test_add_writes_one_decision_file`, `test_add_refuses_a_malformed_decision`, `test_inbox_never_enters_git` (po part), `test_sensitive_decisions_carry_no_detail`; the concurrency test of task 9.
4. [x] **s164's oracle.** `tests/state-as-json.oracle.test.sh:151`: `for verb in next inbox answer record run continue; do` becomes `for verb in next answer record run continue; do`. That is the one assertion that changes: `po inbox` must no longer say `not-built` with exit 2. Nothing else in that file moves; its other tests stay green. — Fails if wrong: `test_state_prints_one_json_object` red on `po inbox`.
5. [x] **Installer.** `bin/polype`: `ignore_decision_inbox`, called from `wire_the_project` after `ignore_local_sums`.
   - It reads the `Decision inbox:` value inside the fence of `$method/templates/agents-local.md`.
   - When the exact line is missing from `$project/.gitignore` (`grep -qxF`), it appends the line and prints `polype: added <value> to .gitignore: the decision inbox never enters git` on stderr. Otherwise it prints nothing.
   - Its comment says why: ADR-0107.
   - This repository's `.gitignore` gains `.polype/inbox/`.
   - Fails if wrong: the installer part of `test_inbox_never_enters_git`; `tests/install*.test.sh`, `tests/global-install.test.sh`, `tests/state-as-json.oracle.test.sh` `test_installer_builds_po_from_sources` stay green.
6. [x] **Rules.** `method/AGENTS.md`: the inbox rule and `po` beside the hooks, under ceilings measured at `553160a`.
   - Ceilings:
     - `## What goes to the person` ≤ 378 words (`awk '/^## / { on = ($0 == "## What goes to the person") } on' | LC_ALL=C wc -w`, heading included);
     - the file ≤ 3743 (`LC_ALL=C wc -w`);
     - `## Installed files` ≤ 516 (s161's oracle).
   - A draft proven on a scratch copy at 378, 503 and 3741 words:
     - (a) `:73` ends at "…before it is made." The colon list `a library, … a hosting` and `, then by anything else` go.
     - (b) `:77` ends at "…stay stops." Its last clause goes. Then a new paragraph: "Whatever goes to the person is first asked through `po inbox add`, options and recommendation included; when `po` is missing or refuses, the lead says it anyway, with the reason."
     - (c) `:149`: po-session "prints where the project stands and changes nothing. `po`, built by the installer at `~/.claude/polype/po`, answers in JSON."
   - Other wordings are allowed within the ceilings. The phrases the research lists as frozen stay word for word.
   - Fails if wrong: the ceiling test of task 9; `tests/escalation-contract.test.sh`, `tests/everything-in-issues.test.sh`, `tests/structure.test.sh`, `tests/installer-leftovers.oracle.test.sh`.
7. [x] **Provisional inbox gone.** `git rm docs/a-trancher.md`. `AGENTS.local.md:76` becomes "**Pending decisions** wait in the decision inbox (`Decision inbox`, `po inbox`). Ideas with no product pulling them are issues labelled `parked`." — Judged in review.
8. [x] **Docs.**
   - `docs/interface-agent.md`:
     - `:5`: drop the provisional-inbox sentence and say that `inbox` exists since s165;
     - `:24`: the lead's verbs are `next`, `record` and `inbox add`;
     - `## inbox`: how `inbox add` takes a decision (stdin, no `id`/`asked`/`status`/`answer`), the id rule, the location rule (outside the repository, or ignored by git) and a table of the codes of row 2;
     - `:29`: the exit-2 list gains `no-inbox-setting`, `unreadable-decision` and `inbox-unwritable`.
   - `docs/installation.md`:
     - `:261-262` adds the template's `Decision inbox` location;
     - `:111` and `:513` say "trois lignes";
     - `remove` leaves the inbox's decisions in place.
   - Judged by reading.
9. [x] **Task tests and full run.** `tests/decision-inbox.test.sh`, five tests:
   - `po inbox ../AGENTS.local` and `po inbox d-1/../x` → `unknown-decision`, exit 1; `po inbox add extra` → `unknown-option`;
   - eight `po inbox add` in parallel → eight files `d-0001`…`d-0008`, no temp left;
   - `po state`'s `waiting` equals `po inbox`'s ids on a folder holding a file that lacks `why` and an unreadable file;
   - `Decision inbox: —` → `no-inbox-setting`;
   - word ceilings of task 6.
   Then `po-run --story s165-decision-inbox --label 'Unit suite' -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `po/` outside `po/src/inbox/` (`main.rs`, `output.rs`, `project.rs`, `state/`, `next/`, `run/`, `record/`, `trust/`, `Cargo.toml`, `Cargo.lock`). No new crate, no `build.rs`.
- Empty diff: `method/` except `method/AGENTS.md`; the root `AGENTS.md`; `.claude/`; `.polype/`; every existing test except `tests/state-as-json.oracle.test.sh:151`.
- `po answer` still answers `not-built`: it is s166's. No `--answered`, no `consume`.
- `po inbox`, list and show, writes nothing. `po inbox add` writes only `<id>.json` and its transient temp in the inbox folder, and runs no forge, model or network command.
- `deny_unknown_fields` on `NewDecision` and `Choice`, never on `Decision`.
- The decision's shape adds no field beyond `docs/interface-agent.md:112-130`.

## The pivot
Everything rests on "the inbox never enters git" being decided by `po`, at write time, through `git check-ignore` and a test of where the folder sits.
- Wrong if "inside" is a path prefix alone: a `Worktree root` outside the root, or a symlinked folder, slips through. Compare with row 9 and test a folder under a worktree of `../`.
- Wrong if check-ignore runs from the worktree: it would judge the worktree's `.gitignore`. It runs from `project.root`.
- Wrong if `pending_ids` and the list read files differently: `waiting` and `pending` drift apart. Task 9 compares them.
- Second hinge: the word budget of task 6. If the rewrite cannot keep the frozen phrases under 378 words, that is an incoherence to report, not a ceiling to raise.

## Files touched
- `po/src/inbox/**`
- `bin/polype`
- `.gitignore`
- `method/AGENTS.md`
- `AGENTS.local.md`
- `docs/a-trancher.md` (deleted)
- `docs/interface-agent.md`
- `docs/installation.md`
- `tests/state-as-json.oracle.test.sh` (one line)
- `tests/decision-inbox.test.sh`
- Written by the planner: `tests/decision-inbox.oracle.test.sh`, `docs/research/s165-decision-inbox.md`, this plan.

## Test strategy
- Oracle (5): the real `po` on throwaway repositories, and the real installer with cargo hidden.
- Task tests (5): path safety, concurrency, agreement with `po state`, `—`, word ceilings.
- 10 tests in `Test budget` 25. No mock: real git, real filesystem, real installer.
- Judged by reading: the rules of task 6 (`po-eval` candidate, #208), task 7, and the docs of task 8.

## Left for the lead once the story ships
Re-ask with `po inbox add` what `docs/a-trancher.md:9-14` held open, without more detail than that public file gave:

| Item | Motive | Sensitive | Options | Recommended | Reversible | Blocks |
| --- | --- | --- | --- | --- | --- | --- |
| D5 `Flow threshold: 3` as default? | strategic | no | a now · b after M21 · c stay at 2 | b | yes | — |
| D6 where the open security findings of s151/s152 go | security | yes | a private advisory · b ordinary fix story · c leave | b | yes | — |
| D7 security lens of shipped reviews on a public repo | security | yes | a intended · b to the local inbox | b | partly | — |
| D8 required CI check on `main` | strategic | no | a yes · b no | a | yes | — |
| D9 one command drives the work (ADR-0109 `proposed`) | strategic | no | a after s168 · b keep three levels · c drop stage commands too | a | yes | M22 framing |
| D10 architecture before stories (ADR-0110 `proposed`) | strategic | no | a yes · b complete `Owns` after · c change nothing | a | yes | — |

D6 and D7 need an absolute `context` outside the repository. This plan does not know that path: the lead chooses it, for example the hand-over report of 2026-11-12 kept on the machine.

## Validation
The planner checked this plan against each criterion; no human reviewed it (`Plan validation: autonomous`). No technical choice is open: no dependency, no ADR.
- `add_writes_one_decision_file`: task 3, steps 1-2 and 7-10; worktree → root by `Project::find`.
- `add_refuses_a_malformed_decision`: task 3, steps 3-4; every case of the story maps to a serde error or a rule.
- `list_prints_pending_oldest_first`: tasks 1-2; numeric order; show answers answered and pending decisions alike.
- `inbox_never_enters_git`: task 3 step 6 (before any write) and task 5.
- `sensitive_decisions_carry_no_detail`: task 3 step 5; the list treats sensitive decisions like the others.
- `rules_send_every_stop_to_the_inbox`: task 6, under the word ceilings.
- `provisional_inbox_is_gone`: task 7, and this plan lists the open items.

## Done when
The five oracle tests and the five task tests pass with the full suite under `po-run`; `po inbox` answers on this repository from its root and from this worktree; one commit on `story/s165-decision-inbox`, reviewed, shipped as `s165-decision-inbox: Ce qui attend le porteur est un fichier, pas une phrase dans une session`.
