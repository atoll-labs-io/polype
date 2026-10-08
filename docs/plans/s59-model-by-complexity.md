---
validated: yes
---
# Plan — s59-model-by-complexity

Branch `story/s59-model-by-complexity`. Read `docs/research/s59-model-by-complexity.md` first; this plan builds on it without repeating it. Decisions: ADR-0032 (the routing), ADR-0036 (in-context plan and design stay on the session model).

`tests/execute.test.sh` is in the story's `Owns` since `101cf2a` (on this lane's HEAD), so task 2 is inside `po-bounds`.

## Story
Every role that decides runs on `Model strong`; the implementer alone takes `Model light` up to `Light up to`, `Model strong` above. Acceptance criteria, each a test function of `tests/model-routing.test.sh`: `settings_declare_the_model_routing`, `implementer_no_longer_pins_a_model`, `deciders_always_run_on_the_strong_model`, `only_the_implementer_adapts`, `drive_reports_the_model_of_each_lane`, `setup_offers_the_defaults`.

## The rules every task writes (one wording, reused)
| Rule | Text the method carries |
| --- | --- |
| Deciders | the Agent call passes `model:` set to `Model strong`, whatever the complexity |
| Implementer | `Model light` when the story's complexity is at most `Light up to`, `Model strong` above it |
| Complexity read | the score after `→` on the first line of `## Complexity` in `docs/research/<id>.md`; no research file → the `Complexité`/`Complexity` of the story in `docs/stories.md`; neither → `Model strong` |
| `—` | a model setting at `—` passes no `model` at all: the subagent runs on the session's model. `Light up to: —` → the implementer never takes `Model light` |
| Fix run | follows the same rule as the first run of the same story |
| Refusal | the Agent tool rejecting the model name stops the lane (the command, outside `/po-drive`), naming the setting and its value; never retried with another model or with none, and never recorded as a review or a QA report |
| Missing setting | stop and name it — written as `… missing → stop …` in the check section |

The `—` and refusal rules go **outside** `## Checks` / `## Preconditions` / `## Step 0`: inside them, `po-lint`'s fail-closed rule rejects any `→` after `—` that does not say stop (`bin/po-lint:158-182`).

## Tasks
1. [x] **Settings template** — `method/templates/agents-local.md`: after `Tracker:` in the Pipeline block, add `Model strong:      opus`, `Model light:       sonnet`, `Light up to:       2` (column-aligned). Three rows in the values table: `Model strong` — the model every deciding subagent (planner, designer, reviewer, qa, stories-reviewer) runs on: a name the Agent tool accepts, or `—` for the session's model; `Model light` — the model the implementer runs on for a story up to `Light up to`, same values; `Light up to` — highest story complexity whose implementer runs on `Model light`, `—` for never. Test: `settings_declare_the_model_routing` (three names in `template_settings`, three rows, rows mention `—` and `Light up to`). Existing `test_settings_template_one_value_per_line` covers the format.
2. [x] **Implementer frontmatter** — `method/agents/implementer.md:5` becomes `model: inherit`; nothing else in the file. In `tests/execute.test.sh:34` delete the `model: opus` assertion (the clause moves to the new test; say so in the final message). Test: `implementer_no_longer_pins_a_model` (`frontmatter` holds `model: inherit` and no `model: opus`).
3. [x] **`/po-execute` owns the implementer rule** — `Reads settings:` gains `Model strong`, `Model light`, `Light up to`. Preconditions: one item "a model setting missing → stop and name it". New section `## Model` before `## Delegation` with the Implementer, Complexity read, `—`, Fix run and Refusal rows of the table above; the Delegation sentence (`:30`) passes `model` as that section settles. The final report names the model passed (or `session`). Test: `only_the_implementer_adapts` (po-execute part: rule phrase, complexity source both files, fix-run sentence, refusal sentence, `—` sentence).
4. [x] **Deciders in their own commands** — `/po-review`, `/po-qa`, `/po-stories-review`: `Reads settings:` gains `Model strong`; their check section gains "`Model strong` missing → stop and name it"; the delegation line naming `subagent_type: reviewer|qa|stories-reviewer` says, on the same line, that it passes `model:` set to `Model strong`. One sentence each after the delegation: `—` passes none; a refusal stops the command, writes no `docs/reviews/<id>.md` / `docs/reviews/stories.md` and no evidence commit (the setting is at fault, not the work). Test: `deciders_always_run_on_the_strong_model` (each delegation line holds `subagent_type: <role>` and `Model strong`).
5. [x] **`/po-drive`** — `Reads settings:` gains the three; the existing "One of the settings above missing … → stop" line (`:24`) then covers them. Dispatch items 1, 2, 4, 5 (`:91-95`) each say, on their own line, `model:` set to `Model strong`; item 3 (`:93`) and the fix-run sentence (`:125`) say the implementer's model follows `/po-execute`'s `## Model`: `Model light` up to `Light up to`, `Model strong` above. One paragraph: a refused model stops that lane, named in the report with the setting and value; the other lanes carry on. `## Report`: the table gains a column `models`, and one sentence: "the report states, per lane and per stage, the model the subagent ran on — the value passed, or `session` when `—` passed none". Tests: `deciders_always_run_on_the_strong_model` (drive lines), `only_the_implementer_adapts` (drive part), `drive_reports_the_model_of_each_lane`.
6. [x] **`/po-orchestrator` and `/po-flow`** — both `Reads settings:` gain the three. Orchestrator: Stage 0 gains "a model setting missing → stop and name it"; Stage 5 states the implementer rule (pointing to `/po-execute`'s `## Model`, fix runs included); Stages 6 and 7 say `qa` and `reviewer` get `model:` set to `Model strong`. Flow: Execute (`:73`) and Review (`:75`) items state the same; fix loops (`:76`) keep the rule. Each file gains one sentence (ADR-0036): the research, design and plan this command writes in its own context run on the session's model, which no command can choose; start the session on `Model strong` for them. Tests: `deciders_always_run_on_the_strong_model`, `only_the_implementer_adapts` (orchestrator and flow parts, plus the ADR-0036 sentence).
7. [x] **`/po-setup`** — no new numbered question. Extend the sentence at `:43` so it names the model defaults written from the template: `Model strong: opus`, `Model light: sonnet`, `Light up to: 2`; the closing message of Step 3 lists these three values and says they are changed in `AGENTS.local.md`. Tests: `setup_offers_the_defaults` (the three exact pairs in `po-setup.md`, and the template values match); existing `test_setup_asks_entry_mode_and_design_source` still counts 5.
8. [x] **Test file** — `tests/model-routing.test.sh`, the six functions named exactly as the criteria, each quoting short exact phrases of the files above (`contains`, `frontmatter`, `template_settings`, and a same-line grep for delegation lines). Then `po-lint` on `method/` clean, then the full suite once through `po-run`.

## Run interdicts
- `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md` end with an empty diff (installed copies; Polype's own model settings are set by hand after ship, per the story notes).
- `method/agents/` other than `implementer.md` end with an empty diff: planner, designer, qa, reviewer, stories-reviewer stay `model: inherit`; the model is passed at dispatch.
- `method/agents/implementer.md`: only line 5 changes.
- `docs/parite-killer-saas.md` and `tests/distribution-wiring.test.sh`: empty diff (H04 stays `partiel`, outside Owns).
- No command gains a dispatch it did not have: `/po-orchestrator` and `/po-flow` launch no planner or designer subagent (ADR-0036).
- No other existing test changes except `tests/execute.test.sh:34`.
- No fallback wording anywhere: no sentence lets a refused model be replaced by another or by the session's.
- No enumerated list of model names in the method beyond the defaults `opus` and `sonnet`.

## The pivot
**The model is passed at dispatch by the commands, and frontmatters stay `inherit`.** Everything rests on the Agent tool honouring a per-call `model` over the subagent's `model: inherit`. Ways it could be wrong:
- The Agent tool's `model` parameter accepts only a fixed set of short names, or none at all in some harness → compare with the Agent tool schema of the running Claude Code; a refusal is a stop by design, so the failure is loud, but `Model strong: opus` must be a name it takes.
- The complexity read diverges between commands (one reads research, another `docs/stories.md`) → compare the Complexity-read clause in `/po-execute`, `/po-drive`, `/po-orchestrator`, `/po-flow`: they must point to the same rule, not restate a different one.
- A `—` or refusal rule lands inside a check section and trips `po-lint` fail-closed, or a missing-setting line does not say stop → run `bin/po-lint method`.

## Files touched
`method/templates/agents-local.md`, `method/agents/implementer.md`, `method/commands/po-execute.md`, `po-review.md`, `po-qa.md`, `po-stories-review.md`, `po-drive.md`, `po-orchestrator.md`, `po-flow.md`, `po-setup.md`, `tests/model-routing.test.sh` (new), `tests/execute.test.sh` (one line removed). Docs: `docs/research/…`, `docs/plans/…`, `docs/verif/…`, `docs/decisions/ADR-0036-…`.

## Test strategy
Text-contract tests in bash, one file, six functions = six criteria, well within `Test budget` 25. Each must fail when its clause is deleted:
- `settings_declare_the_model_routing` — removing a setting line or its row fails it.
- `implementer_no_longer_pins_a_model` — restoring `model: opus` fails it.
- `deciders_always_run_on_the_strong_model` — grep, in each of the six commands, the line naming `subagent_type: <decider>` for `Model strong`; dropping it from any one line fails.
- `only_the_implementer_adapts` — `/po-execute` holds the rule, complexity source, fix-run and refusal sentences; drive, orchestrator, flow each hold `Light up to` next to the implementer dispatch.
- `drive_reports_the_model_of_each_lane` — the report section holds the per-lane, per-stage model sentence.
- `setup_offers_the_defaults` — the three exact pairs in `po-setup.md` and in the template block.
Existing guards that keep running: `structure.test.sh` (settings known), `setup-modes.test.sh` (5 questions), `adr-directory.test.sh` (po-lint clean), `overlap.test.sh`. No visual check: no screen.

## Done when
Six criteria green in `tests/model-routing.test.sh`, `bash tests/run.sh` green through `po-run`, `po-lint` clean, record complete, one commit on `story/s59-model-by-complexity`, then a review with no open critical finding and the squash on `main`. The ship report reminds that Polype's own `AGENTS.local.md` needs the three settings before the next fleet run.
