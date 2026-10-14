# Research — s58-designer-browser

[Story](../stories.md)

## Structuring facts
- **False assumption of the story**: its notes say `tests/qa.test.sh` checks that no `mcp__`, `playwright` or `chrome` appears in `method/`. No test does: `grep -rniE "mcp__|playwright|chrome" tests/ method/` returns nothing. The rule is held only by prose today; this story adds the check (plan, task 3).
- The designer restricts itself with `tools: Read, Write, Edit, Bash, Grep, Glob` (`method/agents/designer.md:4`) yet must open its mockup "with the browser tool the session has" (`method/agents/designer.md:33`). ADR-0026 recorded the gap as out of s51 (its `Neutral` consequence) and gave the QA agent the form to copy: no `tools:`, `disallowedTools:` (`method/agents/qa.md:4`).
- `/po-design` lists `allowed-tools` (`method/commands/po-design.md:4-11`) without any browser, while Step 4 asks to open the page "with whatever browser tool the session has" (`method/commands/po-design.md:62`).
- Removing both lists breaks two existing assertions (`tests/design.test.sh:23`, `:73`) and turns one into a no-op (`tests/fleet-design.test.sh:125`), because `tools_of` reads only `allowed-tools:`/`tools:` (`tests/lib.sh:18-25`).
- Widening a subagent's tools is a change to the method's permission surface: the story is complexity 2, but it touches authorization, so it takes the full track.

## Story
Defect 33 (`docs/defauts.md:73`, "ouvert — s58"): the designer and `/po-design` are told to look at the mockup in a browser but have no browser tool. Criteria:
- `designer_inherits_the_session_browser` — no `tools:` on the designer; ADR-0026's form (`disallowedTools` for what it must not have); Write, Edit, Bash kept.
- `po_design_can_reach_a_browser` — `/po-design` no longer limits its tools to a list without the browser.
- `design_still_writes_no_source_file` — the rule against writing a source file stays in both files.
Plus: name no browser or MCP server; update `tests/fleet-design.test.sh` with the text; mark defect 33 "corrigé par s58".

## Current code
- `method/agents/designer.md:1-8` — frontmatter: `name`, `description`, `tools:` (line 4), `model: inherit`, `skills: [design-doctrine]`. No hook.
- `method/agents/designer.md:33-34` — "Served and looked at" / "Seen and not seen": the note records "no browser tool in the session" when there is none. Stays valid after the change.
- `method/agents/designer.md:41-45` — "You ask no one": the designer never asks; today enforced by the absence of AskUserQuestion from `tools:` plus `tests/fleet-design.test.sh:125-127`.
- `method/agents/designer.md:47-48` — Limits: "You write under `docs/designs/<id>/` and nowhere else … No source file, no test file, no commit". Prose only; no `po-bounds` mode exists for the designer (`method/hooks/po-bounds.sh:4-11` knows `implementer` and `qa`).
- `method/commands/po-design.md:4-11` — `allowed-tools`: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion. Body uses AskUserQuestion at `:40` and `:71`, Bash at `:62`. Source-file rule: "It writes no source file." (`:19`) and "never code: nothing in it is copied into source files" (`:57`).
- `method/agents/qa.md:4` — `disallowedTools: Edit, NotebookEdit`, no `tools:`; `tests/bounds.test.sh:160-161` pins that form for qa only.
- `docs/decisions/ADR-0026-qa-herite-le-navigateur-et-lit-git-par-liste-blanche.md` — Claude Code ignores `disallowedTools` when `tools:` exists; inheriting also brings WebFetch and any MCP server (Bad consequence).

## Attachment points
- Frontmatter line 4 of `method/agents/designer.md`.
- Frontmatter lines 4-11 of `method/commands/po-design.md`.
- `tests/design.test.sh:23`, `:73`; `tests/fleet-design.test.sh:125`.
- New `tests/designer-browser.test.sh` (one test file per story, convention of `AGENTS.local.md`).
- `docs/defauts.md:73` status cell.
- ADR-0027 (reserved for this lane) in `docs/decisions/`.

## Verified interfaces
- `tools_of FILE` (`tests/lib.sh:18-25`) — prints one tool per line from `allowed-tools:` or `tools:`; ignores `disallowedTools:`. Empty output when neither exists, so `lacks_tool` (`:28`) passes vacuously and `needs_tool` (`:29`) fails.
- `frontmatter FILE` (`tests/lib.sh:13-15`) — the lines between the first two `---`.
- `section_of FILE HEADING` — defined locally in `tests/fleet-design.test.sh:8` and `tests/design.test.sh:9`, not in `lib.sh`.
- `bin/po-lint` `check_tools` (`bin/po-lint:123-156`) skips a file with no tool declaration (`:127-128`); `tests/lint.test.sh:86-101` mutates `po-design.md` only on its `Design source` and `no screen` lines, so its expectations survive the removal.
- `method/commands/po-help.md` already has no `allowed-tools`: a command without one is an accepted shape here.

## Traps
- `tests/design.test.sh:23` `needs_tool "$COMMAND" AskUserQuestion` and `:73` `needs_tool "$COMMAND" Bash` fail once `allowed-tools` is gone; the story owns the file, the clause they checked changes, so they change.
- `tests/fleet-design.test.sh:125` `lacks_tool "$DESIGNER" AskUserQuestion` keeps passing with no `tools:` at all — a test that proves nothing. It must read `disallowedTools:` instead.
- `bin/po-lint` stops checking `po-design.md` for "asks a question but AskUserQuestion is not declared" once nothing is declared; nothing to do, but worth knowing.
- `tests/qa.test.sh:33` checks that the designer preloads `design-doctrine`: keep `skills:` intact.
- Installed copies under `.claude/` and `.polype/` are not touched (convention); there is no `.claude/agents/designer.md` in this worktree anyway.
- No migration. No source code: method text, tests, docs.

## Open questions
- Does `allowed-tools` in a command restrict the session's tools, or only pre-approve the listed ones? Polype treats it as a restriction (`method/commands/po-qa.md:2` "by construction", `bin/po-lint:142-147`); if it only pre-approves, removing it costs permission prompts for Write/Edit/Bash during `/po-design`. The plan follows Polype's reading.
- Should the designer's write bound become a hook (`po-bounds.sh designer`)? Out of Owns; ADR-0027 records it as not done here.

## Complexity
Story 2 → 2. Two frontmatter edits, three test adjustments, one new test file, one ADR, one table cell. The only subtlety is the vacuous `lacks_tool`.

## Split
Not needed.
