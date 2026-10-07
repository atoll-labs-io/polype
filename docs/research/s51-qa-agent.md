# Research — s51-qa-agent

## Structuring facts
- **Hidden assumption, false as the story could be read**: "l'agent QA n'a pas Edit" cannot be written as a `tools:` allowlist. A subagent with `tools:` gets only the tools it names, MCP ones included; the designer lists `tools: Read, Write, Edit, Bash, Grep, Glob` (`method/agents/designer.md:4`) and so reaches no browser tool, although it is told to use "the browser tool the session has" (`method/agents/designer.md:33`). Claude Code 2.1.292 accepts `disallowedTools` in agent frontmatter ("Tools removed from the default set. Ignored if `tools` is set"), parsed by the same comma-string parser as `tools`; with `tools` omitted the agent "inherits all tools from parent". The QA agent must therefore carry **no `tools:` line** and `disallowedTools: Edit, NotebookEdit`.
- `po-bounds.sh` has one mode, `implementer` (`method/hooks/po-bounds.sh:142-146`); any other `mode:tool` pair already falls into a refusal (`:162`), so `qa:Edit` is refused with no new code. `check_write` lets the whole of `docs/` through before reading `Owns` (`:80`), which `qa` must not inherit.
- The hook sees Write, Edit and Bash only. A capture is a binary file: the Write tool cannot produce it; it reaches `docs/qa/<id>/` through the browser tool's own file option or a Bash copy, neither of which the hook analyses (ADR-0022, Neutral). The story's "n'accepte d'écriture que sous `docs/qa/<id>/`" holds for Write, not for files a browser tool writes.
- `Tree:` cannot be taken the way the verification record takes it (`git add -A` then `git write-tree`, `method/templates/verification-record.md:5`): `git add` writes the index, which mode `qa` forbids. The reviewer's form, `git rev-parse 'story/<id>^{tree}'` (`method/agents/reviewer.md:20`), is read-only and compares with `code_matches` (`method/hooks/po-gate.sh:32`) the way s52 will need.
- `tests/setup-modes.test.sh:33` fixes exactly five numbered questions in step 2 of `/po-setup`; `Dev` joins question 5, `QA stage` is an unnumbered follow-up.

## Story
A read-only QA subagent walks, in a browser, the screens a story's diff touches and each visible acceptance criterion, and leaves a report with evidence under `docs/qa/<id>/`. It never fixes (Law 2). Criteria: `qa_writes_are_bounded_by_the_hook`, `qa_scope_comes_from_the_diff_and_the_criteria`, `qa_report_has_steps_evidence_and_status`, `qa_stops_without_a_browser_or_a_dev_command`, `setup_asks_for_dev_and_qa_stage`, `browser_contract_is_written_once`, `help_lists_po_qa`. Wiring into the cycle, the gate `qa-current` and the commit of the evidence belong to s52 (`docs/stories.md:786-800`).

## Current code
- `method/hooks/po-bounds.sh` (164 lines, s50): reads hook JSON with `jq` (`:148-150`); `story_of_dir` (`:20-29`) sets `TOP`/`STORY` from a linked worktree on `story/<id>`; `resolve_path` (`:33-48`) refuses relative paths, symlinks and `..` escapes; `check_write` (`:73-94`) allows `docs/*` then the committed `Owns`; `check_bash` (`:98-140`) splits the command into words, follows `cd` and `git -C`, refuses `switch|checkout|stash|push` and `worktree add` (`:125-127`, messages say "forbidden to the implementer") and checks `commit` against the branch (`:128-133`). An `EXIT` trap turns every stray status into 2 (`:17`).
- `method/agents/implementer.md:8-13`: the hook block — matcher `"Edit|Write|Bash"`, command `'"$CLAUDE_PROJECT_DIR"/.polype/hooks/po-bounds.sh implementer || exit 2'`. `:37` tells it to open a screen in a browser (s52 changes that line, not s51).
- `method/agents/designer.md`: preloads `design-doctrine` (`:6-7`); serves and looks at its mockup (`:33-34`).
- `method/agents/reviewer.md:9` also preloads `design-doctrine`: whatever s51 adds to that skill reaches the reviewer.
- `method/skills/design-doctrine/SKILL.md` (29 lines): truth, derived/new, no invention, gaps, mockups, measuring, dark mode. No browser section.
- `method/templates/agents-local.md`: Pipeline block `:9-33`, values table `:35-59`, Commands block `:63-70` (Package manager, Install, Test, Typecheck, E2E, Build), prose `:72`. No `Dev`, no `QA stage`.
- `method/commands/po-setup.md`: step 1 lists command candidates (`:24`); step 2 has five numbered questions (`:31-35`), question 5 being the project commands (`:35`); "Nothing else is asked beyond these five questions, that design follow-up and the catalogue offer" (`:41`).
- `method/commands/po-help.md:26-32`: the story cycle in French, `/po-design` as a sub-item of step 1 (`:28`).
- `method/commands/po-execute.md:18-29` and `method/commands/po-review.md:21-30`: the shape of a command that checks by reading files and dispatches one subagent (`allowed-tools` Read, Glob, Grep, Agent; no Bash).

## Attachment points
- `po-bounds.sh`: the mode `case` (`:143-146`) and the `mode:tool` dispatcher (`:152-163`) gain `qa:Write` and `qa:Bash`.
- New `method/agents/qa.md`, `method/commands/po-qa.md`, `method/templates/qa.md`: the installer copies `method/agents`, `method/commands`, `method/templates` whole (`bin/polype:86`, `:98-101`), so no installer change.
- `design-doctrine/SKILL.md`: one new section, the browser contract.
- `agents-local.md`: `QA stage` in the Pipeline block plus a table row; `Dev` in the Commands block plus a sentence under it.
- `po-setup.md` step 1 and step 2; `po-help.md` cycle.

## Verified interfaces
- `tools_of` / `lacks_tool` / `needs_tool` read only `tools:` and `allowed-tools:` (`tests/lib.sh:17-29`): on a file with no `tools:` line, `lacks_tool qa.md Edit` passes whatever the file says — a test that proves nothing. The QA test must parse `disallowedTools:` itself.
- `template_settings` takes every `Name:` inside a fence of `agents-local.md` (`tests/lib.sh:32-34`): `Dev` and `QA stage` become settings the moment they enter a block.
- `settings_read_by` (`tests/lib.sh:37-39`); `po-lint` refuses a `Reads settings:` name absent from the template (`bin/po-lint:98-115`), skips the tools rules for a file with no tools line (`bin/po-lint:128`), and its fail-closed rule applies in `## Checks|Preconditions|Step 0` sections: an arrow after "No/missing/`—`" must lead to stop/ask/carry on (`bin/po-lint:164-181`).
- `tests/bounds.test.sh`: `lane` (`:9-31`) builds `s01-demo` (`Owns`: `src/app.sh`, `lib/`), `s02-bare`, `s03-en`, `s99-ghost` worktrees; `hook_input` (`:33-36`); `status_with` takes the mode as argument (`:39`); `hook_command` reads the **implementer's** frontmatter only (`:48-51`).
- Run on `tests/run.sh`: each test file is sourced alone with `lib.sh` (`tests/run.sh:11-17`); a second file cannot reuse `lane` without re-running every `test_` of `bounds.test.sh`.
- `po-gate.sh:32` `code_matches <tree>`: `git diff --quiet <tree> HEAD -- . ':(exclude)docs'`.
- Claude Code 2.1.292 agent fields (read in the installed binary): `name, description, prompt, tools, disallowedTools, model, effort, permissionMode, mcpServers, hooks, maxTurns, skills, …`.

## Traps
- `tests/pilot.test.sh:38-46` fails until `/po-qa` appears in `po-help.md` (the new command file alone breaks it).
- `tests/setup-modes.test.sh:33` (five numbered questions) and `:36` (`Nothing else is asked`); `tests/catalogue-wiring.test.sh:14` quotes "becomes the suggestions of question 5, copied verbatim" — keep both sentences intact.
- `tests/structure.test.sh:8-13`: every fenced line of `agents-local.md` must match `Name:  value` with no `#`.
- `tests/profile.test.sh:31`: the profile template's commands are exactly Install…Build; `Dev` must **not** enter `templates/profile.md` (the story also says so).
- `tests/fleet-design.test.sh:52` freezes the lane order in `po-drive.md`; s51 does not touch `po-drive.md`.
- `tests/bounds.test.sh:135`: an unknown mode stays refused; the mode message may change but must not accept anything else.
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS; write in own words. The browser contract comes from gstack (`docs/references/gstack-agent-skills.md:30`), not Killer SaaS.
- Parity matrix: no line covers QA (`docs/parite-killer-saas.md`), nothing to update.
- `docs/` is outside `Owns` except `docs/research`, `docs/plans`, `docs/decisions` written here; `docs/installation.md` (s50) is not touched.
- No migration, no new package (`jq` is already required by ADR-0024).

## Open questions
- Which git verbs the QA may run: a list of reading verbs (fail-closed) or a list of writing verbs (fail-open on a forgotten one)? → ADR-0026.
- Does `/po-qa` itself honour `QA stage: —`? s52 decides when the cycle calls it; a person may still run it by hand. → the plan keeps `/po-qa` independent of `QA stage`.
- Default value of `QA stage` in the template, and what setup suggests. → plan.
- A browser tool whose screenshots only come back as images in the conversation, with no file: the finding then has no capture file. → the template's "none — <reason>" and the status rule.
- The designer's missing browser tool (`designer.md:4` vs `:33`) is a defect outside this story's `Owns`; it goes to a person (Law 7, `Issue tracker: —`).

## Complexity
Story: 4 → after reading: **4**. Hook mode is a small, well-fenced change on s50's script; the weight is in four new method files and in the tool-inheritance trap, which changes the shape of the agent's frontmatter but not the size of the work.

## Split
Not required (score below 5).
