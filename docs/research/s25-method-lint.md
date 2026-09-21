# Research — s25-method-lint

## Structuring facts
- **Criterion 1 already exists as a test.** `tests/structure.test.sh:31-44` (`test_every_setting_read_by_a_command_exists_in_template`) already walks `method/commands/*.md` and `method/agents/*.md`, fails on a missing `Reads settings:` line and on a setting absent from the template. `tests/structure.test.sh` is **outside `Owns`**: `bin/po-lint` re-implements the rule rather than moving it, and the duplicate stays green.
- **`tests/lib.sh:29-40` already holds the parsing the lint needs** — `tools_of` (both `allowed-tools:` list and `tools: A, B` inline), `template_settings`, `settings_read_by`. `bin/po-lint` must be standalone (story note), so it re-implements these in awk; `lib.sh` is outside `Owns` anyway.
- **A blanket "every `→` rule needs a stop" would be a false-positive machine**: 95 arrow lines in `method/commands` + `method/agents`, 28 of them with no stop word — and all 28 are legitimate non-blocking branches (`→ continue`, `→ this is a rerun`, `→ push the branch and open one`, verdict success paths, `/po-status` reporting).
- **Narrowing to the `## Checks` / `## Preconditions` sections makes the rule green and sharp** (measured, 0 counter-examples): inside those sections, every `→` line whose trigger names an absence (`No `, `none`, `missing`, `not `, `` `—` ``, `Any other`, `Another`) already carries `stop`, `ask`, `carry on` or `never blocks`. 41 such rules in 10 commands.
- **Today the tool contract holds everywhere, so the lint starts green** — verified frontmatter by frontmatter (`method/commands/*.md:4-12`, `method/agents/*.md`): `po-execute` has no Write/Edit/Bash, `po-review` has Write but no Edit/Bash, `reviewer` and `stories-reviewer` have no Write, and every command whose *body* names AskUserQuestion declares it.

## Story
`bin/po-lint`, a dependency-free bash script reading `method/` and exiting non-zero with `file:line` per breach, plus `tests/lint.test.sh` that runs it, plus hardened tests for `/po-design`, `/po-design-system` and `/po-flow`. Closes defects 9, 10 and 11 of `docs/defauts.md:30-32` — all three instances of the recurring pattern named at `docs/defauts.md:34`: *a test that looks for a phrase in a prompt proves the phrase exists, not that the agent applies it*.

Criteria: `lint_checks_every_command_declares_its_settings`, `lint_checks_tool_permissions_match_the_contract`, `lint_checks_fail_closed_rules_have_a_stop`, `lint_is_part_of_the_suite`, `design_stop_rules_bite`.

## Current code
- `bin/ks-overlap` — the precedent: a standalone script (python3 here) reading `method/`, printing `path:line` hits, `sys.exit(1 if hits else 0)`. Wrapped by `tests/overlap.test.sh:9-17`, which calls it and turns its output into a `fail`. Exactly the shape `bin/po-lint` + `tests/lint.test.sh` must take, in bash.
- `tests/run.sh` — sources every `tests/*.test.sh`, runs each `test_*` in its own process; `ROOT` and `METHOD` come from `tests/lib.sh:5-6`.
- `tests/design.test.sh:23-29` — `test_design_fails_closed_without_system_or_source` greps three phrases inside section `Checks`. **Defect 10**: the phrases can stay while the stop disappears.
- `tests/design-system.test.sh:11-18` — checks `This command never invents an identity:` and one phrase of Step 1. **Defect 9**: the rule "edits no source file" (`method/commands/po-design-system.md:58`) has no test at all.
- `tests/flow.test.sh:20-56` — three tests, all `section_holds` phrase lists. **Defect 11**: the escalation signals are listed, but nothing checks that finding one *stops* the short track, nor that the existing worktree is kept.

## Attachment points
- New `bin/po-lint` (Owns) — `bin/` is not installed by `bin/polype-dev-install`, so nothing to wire there.
- New `tests/lint.test.sh` (Owns) — picked up automatically by `tests/run.sh` glob.
- `tests/design.test.sh`, `tests/design-system.test.sh`, `tests/flow.test.sh` (Owns) — harden, keep existing tests green.
- `docs/defauts.md:30-32` (Owns) — statuses 9, 10, 11 → `corrigé par s25`.
- No `**Matrice**` field on this story → `docs/parite-killer-saas.md` is **not** touched.

## Verified interfaces
- `tools_of` (`tests/lib.sh:29-37`) parses both frontmatter shapes; commands use `allowed-tools:` as a YAML list, subagents use `tools: A, B` inline. Confirmed across all 20 files.
- `settings_read_by` (`tests/lib.sh:47-49`) takes the first `^Reads settings:` line and extracts backticked names. `method/commands/po-help.md:8` says `Reads settings: none` with **no backticks** → yields zero names, and passes. `bin/po-lint` must reproduce that tolerance or po-help breaks it.
- `method/commands/po-help.md:1-4` has **no `allowed-tools` at all** (`disable-model-invocation: true`). Any tool rule must skip files with no tool declaration, or exempt po-help explicitly.
- Sections carrying fail-closed rules: `## Checks` in 10 commands (architect, brief, design, design-system, flow, plan, prd, research, stories, stories-review); `## Preconditions` in po-execute and po-review; po-ship uses `## Step 0 — The verdict, before anything else`; po-setup, po-status, po-orchestrator, po-help have neither.
- `method/commands/po-design.md:25-26` — the two stops of defect 10, plus `:28` `Either way the command writes nothing and draws no mockup.`
- `method/commands/po-design-system.md:58` — `The command edits no source file:` (defect 9), `:34` — stop when no source comes back.
- `method/commands/po-flow.md:34-46` — the escalation section: `a signal there → stop and point to /po-research <id>`, and `keep it as it is, write no plan` after reading the code (defect 11).

## Traps
- **The lint must be green on today's `method/` or `tests/lint.test.sh` fails on arrival.** Every rule has to be calibrated against the measurements above before being written, not after.
- **A rule too clever becomes a phrase test again.** The three decidable families are the story's own: presence (`Reads settings:`, a known setting name), permissions (frontmatter tools), neighbourhood of a stop (trigger and consequence in the same line/paragraph). Anything needing to understand a sentence does not belong in `po-lint`.
- `method/commands/po-execute.md:21` says `AGENTS.local.md exists; if not, point to /po-setup.` — an `otherwise` idiom with **no** stop word, and no `→`. Keeping the rule arrow-scoped avoids flagging a file outside `Owns`. See Open questions.
- `bin/po-lint` must be invoked as `bash "$ROOT/bin/po-lint"` or committed with the executable bit — `tests/overlap.test.sh:13` calls `python3 "$ROOT/bin/ks-overlap"` explicitly and does not rely on the bit.
- `tests/overlap.test.sh` only scans `method/`, so `bin/po-lint` is out of the Killer SaaS overlap check; its wording is still bound by ADR-0006 for anything copied into `method/`.
- `Test budget: 25`. The story asks for 5 test functions (4 lint + the hardened design/design-system/flow ones). Hardening means *replacing assertions inside existing test functions*, not adding functions, wherever possible.
- `.claude/` and `.polype/` are installed copies — `po-lint` reads `method/` only.

## Open questions
- Does the duplication between `bin/po-lint` and `tests/structure.test.sh:31-44` need resolving? The testing doctrine wants one deterministic check per stage; both run in the same suite. `tests/structure.test.sh` is outside `Owns`, so the plan should either accept the duplication and say so, or hand the cleanup to a later story.
- Should the missing stop at `method/commands/po-execute.md:21` (and the `otherwise` idiom in `po-review.md:22-24`) become a new entry in `docs/defauts.md`, given that `po-execute.md` is outside this story's `Owns`?
- For `design_stop_rules_bite`, what counts as proving a consequence in a grep-based suite? The measurable form used by `tests/wiring.test.sh:28-34` is **structural**: assert that the trigger and its stop sit in the same paragraph, and that no production step is reachable before it (heading order). The plan must settle the exact shape.

## Complexity
Story score 3 → **3**. The measurements make the calibration cheap, but four files change and the lint must stay green while genuinely biting.

## Split
Not required.
