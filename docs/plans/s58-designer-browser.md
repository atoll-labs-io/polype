---
validated: yes
---
# Plan — s58-designer-browser

[Story](../stories.md) · [Research](../research/s58-designer-browser.md)

Branch `story/s58-designer-browser`. Read `docs/research/s58-designer-browser.md` first; this plan builds on it without repeating it. Decision recorded in `docs/decisions/ADR-0027-designer-herite-le-navigateur-de-la-session.md`.

Track: full. The story is complexity 2 (≤ `Flow threshold`), but it widens the tools of a subagent and a command — an authorization signal — so `auto` escalates it.

## Story
Fix defect 33: the designer and `/po-design` must reach the session's browser tool to look at the mockup.
- `designer_inherits_the_session_browser` — no `tools:` on the designer, `disallowedTools` for what it must not have (ADR-0026's form), Write, Edit and Bash kept.
- `po_design_can_reach_a_browser` — `/po-design` no longer limits its tools to a list without the browser.
- `design_still_writes_no_source_file` — the no-source-file rule stays in both files.

## Tasks
1. [x] **Designer frontmatter.** In `method/agents/designer.md`, replace line 4 `tools: Read, Write, Edit, Bash, Grep, Glob` with `disallowedTools: AskUserQuestion, NotebookEdit`. Keep `name`, `description`, `model: inherit` and the `skills:` list exactly as they are. Body unchanged. Fails if wrong: `test_designer_inherits_the_session_browser` (task 4) and `test_designer_asks_no_one` (task 3).
2. [x] **/po-design frontmatter.** In `method/commands/po-design.md`, delete the `allowed-tools:` key and its seven list lines (lines 4-11). Keep `description` and `argument-hint`; body unchanged, including "It writes no source file." (`:19`) and Step 4's "whatever browser tool the session has" (`:62`). Fails if wrong: `test_po_design_can_reach_a_browser` (task 4).
3. [x] **Existing tests follow the text** (the clauses they checked change, say so in the commit):
   - `tests/design.test.sh:23` — drop `needs_tool "$COMMAND" AskUserQuestion`; `:73` — drop `needs_tool "$COMMAND" Bash`. The command no longer declares tools; the frontmatter rule moves to task 4's test.
   - `tests/fleet-design.test.sh:125` — replace the vacuous `lacks_tool "$DESIGNER" AskUserQuestion` with a check that the designer's `disallowedTools:` line names `AskUserQuestion` as a whole word (`frontmatter "$DESIGNER" | grep -m1 '^disallowedTools:' | grep -qw AskUserQuestion || fail ...`). Keep the rest of `test_designer_asks_no_one`.
   Fails if wrong: `test_designer_asks_no_one` turns red when `AskUserQuestion` is removed from `disallowedTools`.
4. [x] **New `tests/designer-browser.test.sh`**, three functions named after the criteria, using `frontmatter`, `require_file`, `contains`, `fail` from `tests/lib.sh`:
   - `test_designer_inherits_the_session_browser` — designer frontmatter has no `^tools:` line; has a `^disallowedTools:` line; that line names none of `Write`, `Edit`, `Bash` as a whole word (`grep -qw`), so `NotebookEdit` does not count as `Edit`.
   - `test_po_design_can_reach_a_browser` — `po-design.md` frontmatter has neither `^allowed-tools:` nor `^tools:`; and `grep -rniE 'mcp__|playwright|chrome' "$METHOD"` finds nothing (the story assumed this check already existed; it did not).
   - `test_design_still_writes_no_source_file` — `contains` on `po-design.md`: `It writes no source file.` and `never code: nothing in it is copied into source files`; on `designer.md`: `No source file, no test file, no commit`.
   Fails if wrong: each function goes red when its clause or frontmatter line is reverted.
5. [x] **Defect 33.** In `docs/defauts.md:73`, change the last cell `ouvert — s58` to `corrigé par s58`, touching no other line.
6. [x] **Run the suite once** (`Full suite: execute-end`): `bash tests/run.sh`; then `bin/po-lint` is covered by `tests/lint.test.sh`. Commit research, ADR-0027, plan, code and tests together.

## Run interdicts
- `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`, `method/agents/qa.md`, `method/commands/po-qa.md`: empty diff (no designer hook mode in this story, ADR-0027).
- Nothing under `.claude/` or `.polype/` changes (installed copies).
- The bodies of `method/agents/designer.md` and `method/commands/po-design.md` end with an empty diff: only their frontmatter changes.
- No file in `method/` names a browser tool or MCP server: `grep -rniE 'mcp__|playwright|chrome' method/` stays empty.
- `docs/decisions/ADR-0026-*.md` and `ADR-0019-*.md` unchanged (accepted ADRs).
- `docs/defauts.md`: only line 73 changes. `docs/stories.md`, `docs/parite-killer-saas.md`, `README.md`: empty diff.
- `tests/lib.sh` unchanged: `tools_of` keeps ignoring `disallowedTools`; tests read that line directly.

## The pivot
That Claude Code gives the session's tools to a subagent without `tools:` minus its `disallowedTools`, and to a command without `allowed-tools` — the reading ADR-0026 already relies on. Ways it could be wrong:
- `disallowedTools` silently ignored when another key is malformed: compare with `method/agents/qa.md:4`, same spelling and comma list.
- `allowed-tools` on a command only pre-approves rather than restricts: then the defect was half-real for `/po-design` and removing the list costs permission prompts, nothing worse (ADR-0027, Neutral). Polype's own reading is restriction (`method/commands/po-qa.md:2`, `bin/po-lint:142-147`).
- A test reading frontmatter through `tools_of` passes vacuously on a file with no list: the reviewer should start at `tests/fleet-design.test.sh:125` and any `lacks_tool` on the designer.

## Files touched
- `method/agents/designer.md` (frontmatter)
- `method/commands/po-design.md` (frontmatter)
- `tests/design.test.sh`, `tests/fleet-design.test.sh`
- `tests/designer-browser.test.sh` (new)
- `docs/defauts.md` (line 73)
- `docs/research/s58-designer-browser.md`, `docs/plans/s58-designer-browser.md`, `docs/decisions/ADR-0027-designer-herite-le-navigateur-de-la-session.md`

All inside the story's `Owns` except the three `docs/` pipeline files, which every story carries.

## Test strategy
Automated (bash, text-level, the only layer this repository has): 3 new test functions, 1 strengthened (`test_designer_asks_no_one`), 2 assertions removed from `tests/design.test.sh` because the clause they checked is gone. Total new or changed: 4, within `Test budget` 25.
- Each test would go red if its rule were removed: the designer regaining `tools:` or losing Write/Edit/Bash; `/po-design` regaining a tool list; a browser named in `method/`; the source-file sentences deleted; AskUserQuestion dropped from `disallowedTools`.
- Small overlap accepted: `No source file, no test file, no commit` is also checked in `test_designer_writes_only_in_the_story_design_folder`; the criterion needs its own named function, and it pairs that line with `/po-design`'s.
Visual checks: none — no screen.

## Done when
- `bash tests/run.sh` green, `po-lint` clean through `tests/lint.test.sh`.
- Defect 33 reads `corrigé par s58`.
- One commit on `story/s58-designer-browser` carrying code, tests, research, plan and ADR-0027; a review with no open critical finding.
