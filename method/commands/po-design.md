---
description: Settles one story's screen from docs/design-system.md inside the story worktree — a note of deltas for a derived screen, the note plus one artefact for a new one, looked at in a browser, never measured
argument-hint: <story id or name>
---
# /po-design

Reads settings: `Worktree root`, `Design source`, `Design skill`, `Design tool`

Story: $ARGUMENTS

This command decides a story's screen from the recorded system and writes it down in the story's worktree. It writes no source file.

## By hand
A subagent skips this paragraph. This design is decided on the session's model, which no command can choose (ADR-0036); start the session on `Model strong`. Run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next` and read the story's entry as `/po-drive <id>` does; `po` missing or exiting 2 → stop, naming `polype install`; no `AGENTS.local.md` → stop, naming `/po-setup`. Go on only on `design`, or, for a story with no `Surface` line whose text shows a screen (`AGENTS.md`, Law 1), on `plan` with reason `research, no plan` or `plan-validated refuses`. Any other entry, or a warning naming the story, is reported, an `ask` as a question for the person, and ends the command, writing nothing. `docs/design-system.md` missing → stop, naming `/po-design-system`. `Design source` `—` → stop and ask the person to choose `internal` or `external` and write it in `AGENTS.local.md` themselves. Do not set it for them. At the end, report a new `po next` entry likewise.

Then read the `design-doctrine` skill, the story, `docs/research/<id>.md` when present, and `docs/design-system.md`. Everything below reads and writes inside `<Worktree root><id>`.

## Where the design lives
Every file this command produces goes under `docs/designs/<id>/` in the story worktree: `design.md` always, and for a new screen either `mockup.html` or `brief.md`.

They stay uncommitted, like the research and the plan; the implementer commits them with the story.

## Step 1 — Derived or new
Split the screen into its regions. When every region maps to a pattern and to components already listed in `docs/design-system.md`, the screen is derived. When at least one region needs a layout the system does not hold, it is new. When you cannot tell, ask once, in an AskUserQuestion that shows the regions and the pattern each would reuse.

## Step 2 — The note
Fill `templates/design-screen.md` into `docs/designs/<id>/design.md`: the deltas only for a derived screen.

## Step 3 — The artefact
A new screen only, and exactly one artefact, chosen by `Design source`:
- `internal` → `mockup.html`, drawn with the skill named in `Design skill`. When `Design skill` is `—`, stop before drawing and say the project names no skill to draw with.
- `external` → `brief.md`, from `templates/design-brief.md`, written for the tool named in `Design tool`. When `Design tool` is `—`, write the brief for no tool in particular and say so.

Never both. The artefact reaches final fidelity: each state it can be in (drawn from empty, loading, error, success, disabled and focus), light and dark, desktop and mobile, with the real text of the product — no placeholder copy.

The mockup is a reference for the implementer, never code: nothing in it is copied into source files.

## Step 4 — Look at the mockup
Serve `docs/designs/<id>/` over local HTTP with `python3 -m http.server --bind 127.0.0.1 <free port>`, never through `file://`. Open the page with whatever browser tool the session has, in light and in dark, at desktop and at mobile width, and go through each state.

Look for what is broken: text that overflows or is cut, overlapping regions, a theme that leaves a surface unstyled, a state that does not show, a control out of reach on mobile. Fix the mockup and look again.

Nothing is measured here. Write in `## Seen and not seen` what was looked at and what could not be seen, with the reason, then stop the server.

## Approval
One grouped AskUserQuestion shows the note, the kind of screen, the gaps and the artefact's path, and asks for approval. A change goes back to the step it belongs to. Nothing is reported as done before approval.

Finish with "Design written to docs/designs/<id>/ in <path>."
