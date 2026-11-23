# Research — s206-real-run-before-a-release

[Story](../stories.md)

## Structuring facts
- **Half-false assumption.** "`bin/po-eval` needs a token in the environment" holds only under `--control` (`bin/po-eval:196-199`); a plain run uses the caller's own config and login (`bin/po-eval:146-148`). A real run must never touch the caller's config, so it takes the `--control` shape: temporary `CLAUDE_CONFIG_DIR`, login from `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` only.
- **`po run` can launch the real lead with no change to `po/`.** It refuses unless `bounds` is `held` (`po/src/run/mod.rs:123-129`), and `held` means the three bounded agents come from `${CLAUDE_CONFIG_DIR}/agents/` with their hook, none in the repository, and an executable `.polype/hooks/po-bounds.sh` (`po/src/run/bounds.rs:55-62`): a temporary config set up by `polype install --global` plus `polype init <repo>` gives that. It launches `$PO_CLAUDE --bg <flag> <uuid> <command>` and **waits for that child** (`mod.rs:195-210`, `session.rs:39-44`); `po state` asks `$PO_CLAUDE agents --json` (`session.rs:62-80`). A wrapper set as `PO_CLAUDE` can therefore run `claude -p` in the foreground.
- **The journey repository cannot host a real lead as built.** It is a per-project install (`tests/journey/journey.sh:68`), so `bounds` is `unproven`; its stories have no criteria (`journey.sh:145`) and its answers are written in advance. The real run reuses its project files and forge double (`tests/journey/project/`, `tests/journey/doubles/gh`) but builds its own repository.
- **Grading needs no model.** `po state --all` gives per shipped story `track`, `fix_loops`, `max_severity`, `oracle`, `method_version` (`docs/interface-agent.md:115-128`, `po/src/trust/signals.rs:22-41`); a landing is a `<id>: <title>` commit on the target (ADR-0131); lane stage, stops and pending decisions come from `po state` and `po inbox`.
- **The kept security tests are not where the story thinks.** Of the nine whole files s204 kept, seven hold no prose assertion at all (only script tests); the prose lines left are `bounds.test.sh:67,228-230`, `bounds-messages.test.sh:80-81`, `install-collisions.test.sh:233`. `run-ledger.test.sh` is in this `Owns`, but its two kept functions are pinned by s204's oracle (`tests/framing-and-installer-phrase-tests-retired.oracle.test.sh:42,257-261`), outside `Owns`: they stay.

## Story
Before a release, a real lead drives the journey repository; control arms measure what each model-read rule changes; a rule whose removal moves no rate is reported, never removed by the command. Criteria: `real_run_drives_the_journey_repository`, `a_run_is_graded_by_scripts`, `suite_never_pays`, `any_rule_can_have_a_control_arm`, `m21_bis_rules_have_their_cases`, `release_names_its_real_run`, `a_rule_that_moves_nothing_is_reported`.

## Current code
- `bin/po-eval` (257 lines): reviewer evals on eight planted-flaw cases (`evals/cases/`), graded by the last `Max severity:`/`Ship allowed:` lines (`:109-117`); one control arm, hard-wired: `CONTROL_PREFIX` (`:28`) and `control_setup` (`:120-133`) copy `bin`, `method`, `evals`, swap one line of `review-antihallu`, install globally into a temp config. Confirmation before any call (`:201-218`); stdin closed for `claude -p` (`:145-149`).
- `evals/lib.sh`: builds the notes-app repository with a per-project install in a throwaway config (`:149-153`), a story worktree, a real `po-run` record (`:212-251`).
- `tests/journey/journey.sh`: isolation recipe to copy — doubles for `gh` (logs, solo repo, PRs as JSON) and `unexpected` for `curl glab tea task claude` (`:24-29`), `unset GH_TOKEN GITHUB_TOKEN` and git's local vars (`:31-35`), `HOME`, `TMPDIR`, `CLAUDE_CONFIG_DIR` inside the run dir, `GIT_ALLOW_PROTOCOL=file` (`:36-38`), bare origin with `insteadOf` (`:72-79`), settings written from the template by awk (`:42-63`).
- `method/hooks/po-intake.sh:81-103` `scrub`: `po-gate redact`, then every env value whose name holds `TOKEN|KEY|SECRET|PASSWORD` masked by awk through `ENVIRON` — the value never reaches an argument.
- `docs/evals/reuse-ladder.md`: the only measure so far, 48 reviews (8 cases × 3 × 2 arms), rule 3/3 vs control 0/3 on the one case that moved.

## Attachment points
- `bin/po-eval`: new mode `real` beside the reviewer mode; `--control` becomes the arm `reuse-ladder` read from a declaration file.
- `evals/real/` (new): build, launch wrapper, grading, cases, rule registry; `evals/arms/` (new): one declaration per arm.
- `docs/ci.md` `## Publier une version`, `docs/harnais.md` (`## Ce que la suite prouve depuis #207`, "Ce que seul un vrai passage prouve"), `docs/evals/`.

## Verified interfaces
- `po run` / `po continue` take no argument (`mod.rs:75-81`); `continue` resumes with `--resume <uuid>` (`docs/interface-agent.md:226`). Refusals: `bounds-unproven`, `nothing-to-do`, `already-running` (`mod.rs:116-129,186-190`).
- `po state --all` (`interface-agent.md:113`), `lanes[].stage/stops/blocked_by` (`:101-104`), `waiting` (`:96`), `framing.items` (`:100`); `po inbox` (`:131`).
- `claude` 2.1.330 (`claude --help`, free): `-p`, `--session-id`, `--resume`, `--model`, `--max-budget-usd` (print mode only), `--output-format stream-json`, `--permission-mode`, `--permission-prompts none` (anything that would prompt is denied), `--fallback-model` (must never be passed: a refused model would be retried on another, breaking the stop rule of `method/commands/po-drive.md:70`).
- `bin/polype install --global` lays `po` from sources when no prebuilt matches (`bin/polype:890-935`); `polype init <project> [--hooks]` (`bin/polype:66`).
- Subagent models: planner and designer on `Model strong` (`po-drive.md:62-63`), implementer on `Model light` up to `Light up to` (`po-execute.md:21-23`), reviewer and qa as their commands fix.

## Traps
- `tests/routing-phrase-tests-retired.oracle.test.sh` counts, per script, the test functions that launch it, against `origin/main` (`docs/harnais.md:221-227`). `bin/po-eval` is launched by `evals`, `reuse-ladder-eval`, `eval-arms-same-environment` (through sourced helpers), `run-ledger` and `rebuilt-helper-single-defect`: no function may stop launching it. `tests/review-tree-gate.test.sh:62` sources `grade()` out of `bin/po-eval` between its `^grade() {` and `^}` lines: that shape stays.
- `test_evals_run_on_demand_only` (`tests/evals.test.sh:140-154`) and the `--control` tests (`reuse-ladder-eval`, `eval-arms-same-environment`) pin today's messages: `--control` must keep them.
- `method/word-budget` and every `method/` file are outside `Owns`: the story needs none of them. `po/` is outside `Owns`: needed by nothing here.
- The real lead and the planner are not bounded by `po-bounds` (`bounds.rs:13`); a launched agent runs as the user and can read its environment, login included.
- `tests/run.sh` exports a temp `CLAUDE_CONFIG_DIR` and `POLYPE_PO_FETCH=false` (`tests/run.sh:11-27`) but does not unset the login variables: a test calling a real `claude` with a login in the caller's environment would pay. Every test of this story puts a `claude` double first on `PATH`.
- `po state` reads `shipped` only for the current milestone without `--all` (`interface-agent.md:113`).
- A kept transcript can hold anything an agent printed, the login included.

## Open questions
- Settled by the owner on 2026-11-23: how many paid runs ground a retirement (d-0057, ADR-0133) and what confines the launched lead (d-0056, ADR-0134, attended runs only).
- Whether `--max-budget-usd` bounds a run on a subscription token (`CLAUDE_CODE_OAUTH_TOKEN`) as it does on an API key: not knowable without a paid run; the first real run tells.
- The exact permission-rule syntax the allowlist needs (absolute path patterns): the implementer checks Claude Code's documentation, a free read.

## Complexity
4 → 4, at the edge of 5. The paid part is outside the story; inside, the command, its grading and arms are moderate, but some thirty cases must be written, each a small declaration over one shared vocabulary of setups and predicates.

## Split
Not mandatory at 4; kept one story (lead, 2026-11-23). The plan orders it in three groups, each closed by a check: the command, its double and the grading; arms and record; docs, then the 35 case files. Tasks 1-7 deliver every criterion but `m21_bis_rules_have_their_cases`.
