# Review: s58-designer-browser

Diff reviewed: `git diff main...story/s58-designer-browser` (one commit, 582f833). The reviewer did not write this code. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 5588e4b03c65606fb83c6116d66d6d9e7be79297

## Ownership
I listed the touched paths with `git diff --name-only main...story/s58-designer-browser` and checked each one against the story's `Owns` line (`docs/stories.md:888`).
- [x] Inside `Owns`: `method/agents/designer.md`, `method/commands/po-design.md`, `tests/design.test.sh`, `tests/fleet-design.test.sh`, `tests/designer-browser.test.sh`, `docs/defauts.md`.
- [x] The story's own pipeline files are in scope by construction: `docs/research/`, `docs/plans/` and `docs/verif/` for s58.
- [x] One path is outside `Owns`: `docs/decisions/ADR-0027-designer-herite-le-navigateur-de-la-session.md`. A written rule requires it (AGENTS.md Law 6: "Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`"). That makes it a gap in the story's `Owns`, not a breach by the implementer, so it is rated **minor**.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows only main and this worktree, and every other `story/*` branch is merged.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s58-designer-browser` exits 0. `Verification mode: record` applies, so I reused the record in `docs/verif/s58-designer-browser.md`.
  - The record is complete: `bash tests/run.sh` exited 0 with 262 passed, 0 failed.
  - The project has no type check command (`Typecheck: —`).
  - Lint runs inside the suite through `tests/lint.test.sh`.
  - I read its "Not proven here" section and carried it into "Not verified" below.
- E2E and Build are `—` in this project. The diff changes no routing and no manifest.

## Plan
- [x] Tasks 1 to 6 are all present, and nothing in the diff falls outside the plan.
  - Task 1: the designer's `tools:` line becomes `disallowedTools: AskUserQuestion, NotebookEdit`.
  - Task 2: `allowed-tools` and its seven list lines are removed from `/po-design`.
  - Task 3: `design.test.sh` loses two `needs_tool` lines, and `fleet-design.test.sh:125` replaces the vacuous `lacks_tool` with a direct read of the `disallowedTools` line.
  - Task 4: the new test file has three functions, each named after an acceptance criterion.
  - Task 5: `defauts.md:73` now reads `corrigé par s58`.
  - Task 6: one commit, and the commit message names the test clauses that changed.
- [x] Run interdicts, checked one by one:
  - `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`, `method/agents/qa.md`, `method/commands/po-qa.md`: not in the diff.
  - `.claude/` and `.polype/`: not in the diff.
  - Designer and `/po-design` bodies: the hunks touch frontmatter only.
  - `grep -rniE 'mcp__|playwright|chrome' method/` returns nothing.
  - ADR-0026 and ADR-0019 are unchanged.
  - `docs/defauts.md` changes on one line only.
  - `docs/stories.md`, `docs/parite-killer-saas.md`, `README.md` and `tests/lib.sh` are unchanged.

## References
- [x] Each reference is confirmed:
  - `frontmatter` exists at `tests/lib.sh:13`.
  - `tools_of`, `has_tool`, `lacks_tool` and `needs_tool` exist at `tests/lib.sh:18-29`; `tools_of` ignores `disallowedTools`, as the research said.
  - `require_file`, `contains`, `fail` and `section_of` are the helpers the tests already used.
  - The designer's spelling matches `method/agents/qa.md:4` (`disallowedTools: Edit, NotebookEdit`).
  - The sentences checked by `test_design_still_writes_no_source_file` exist verbatim in both files.
- [x] The value that matters, the claim that a subagent with no `tools:` inherits the session's tools minus `disallowedTools`, follows the reading already accepted in ADR-0026. Whether `allowed-tools` on a command restricts tools or only pre-approves them was left as an open question in the research. ADR-0027 records it under "Neutral", where the downside is only permission prompts.

## Rules
- [x] The `AGENTS.local.md` conventions are respected: method files are in English, tests are bash and named after the criteria, and the existing tests changed only where their clause changed (the commit says so).
- [x] No accepted ADR is contradicted. ADR-0027 reuses ADR-0026's form, and the designer still asks no one, as ADR-0019 requires.

## Tests
- [x] Floor: `po-gate floor-guard s58-designer-browser main` exits 0, so nothing was lowered. The removed `needs_tool` / `lacks_tool` lines are justified anyway, by name and reason, in plan task 3.
- [x] The assertions pin down the criteria. None of the six empty test shapes appears: the tests read the real method files, with no mock and no fixture.
- [x] Budget: 3 new tests and 1 strengthened test, within `Test budget` 25.
- [x] Bite: I ran five mutations, each with only the relevant test files. Each was undone by restoring a copy of the file, and `git diff --exit-code <file>` came back clean every time. The final `git status --porcelain` is empty.

| # | Mutation | Test files run | Failing tests |
|---|---|---|---|
| 1 | Designer back to `tools: Read, Write, Edit, Bash, Grep, Glob` | designer-browser, fleet-design | 2 (`designer_inherits_the_session_browser`, `designer_asks_no_one`) |
| 2 | `AskUserQuestion` dropped from the designer's `disallowedTools` | designer-browser, fleet-design | 1 (`designer_asks_no_one`) |
| 3 | `Edit` added to the designer's `disallowedTools` | designer-browser | 1 (`designer_inherits_the_session_browser`; `-w` correctly does not count `NotebookEdit` as `Edit`) |
| 4 | `allowed-tools` list put back into `po-design.md` | designer-browser, design | 1 (`po_design_can_reach_a_browser`) |
| 5 | "It writes no source file." deleted from `po-design.md` | designer-browser, design | 1 (`design_still_writes_no_source_file`) |

- [x] Tests the story made useless are removed: the two `needs_tool` lines and the vacuous `lacks_tool`.

## Neighbours
- [x] I read the other callers:
  - `bin/po-lint` `check_tools` skips any file with no tools declaration, so `/po-design` loses the lint check "body asks a question but AskUserQuestion is not declared". ADR-0027 records this ("Bad, because…").
  - `tests/lint.test.sh` mutates `po-plan.md`, `po-brief.md`, `po-execute.md` and `reviewer.md` for its tool rules, not `po-design.md`, so nothing broke.
  - The `needs_tool` lines in `tests/design-system.test.sh` target `po-design-system.md`, which is unchanged.
  - `tests/qa.test.sh` targets `po-qa.md`, which is unchanged.
  - `tests/adr-directory.test.sh` only lists `designer.md` for other clauses.

## Findings
- minor — `docs/decisions/ADR-0027-designer-herite-le-navigateur-de-la-session.md` — the path is outside s58's `Owns` (`docs/stories.md:888`), but AGENTS.md Law 6 requires an ADR for a structural decision. This is a gap in the story's `Owns`, not an implementer breach. The plan's "Files touched" line also says "All inside the story's `Owns` except the three `docs/` pipeline files", which is inaccurate: the ADR is a fourth file and is not pipeline evidence.
- minor — `tests/designer-browser.test.sh:23` — `po_design_can_reach_a_browser` also runs `grep -rniE 'mcp__|playwright|chrome' "$METHOD"` over all of `method/`. Because `chrome` is matched case-insensitively as a substring, any future method text containing "monochrome" or "chromatic" (likely in design prose) would turn this test red for an unrelated reason. The check also enforces a rule beyond the criterion's own clause; a word-bounded pattern would be sturdier.
- minor — `bin/po-lint` (not changed, neighbour) — with no tools declaration, `/po-design` is no longer checked by the AskUserQuestion lint rule, though its body uses AskUserQuestion at `:32` and `:63`. Nothing is broken today. This is accepted and recorded in ADR-0027, and listed here so it stays visible.

## Not verified
- **Real tool inheritance at runtime.** I did not launch the designer subagent or `/po-design` in a live Claude Code session with a browser tool. So I have not observed that the designer inherits the session's browser minus `disallowedTools`, or whether removing `allowed-tools` matters (restriction versus pre-approval). A person should run `/po-design` on a story with a screen in a session that has a browser MCP. They should confirm the page opens, and see whether Write/Edit/Bash now raise permission prompts.
- **The designer's wider powers.** It now inherits every session tool, including WebFetch and any MCP server that writes. Its write bound is still prose in `## Limits`; no hook enforces it (ADR-0027). I did not test any misuse. A follow-up story adding a `designer` mode to `po-bounds` is the recorded way to close this.
- **Screen and design conformity.** The story has no screen, so there was no browser check and no design-system check.
- **Suite and lint.** I did not rerun them; I relied on the matching record (tree checked by `po-gate verif-current`).

Max severity: minor
Ship allowed: yes
