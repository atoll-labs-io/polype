---
description: Settles one story's screen from docs/design-system.md inside the story worktree — a note of deltas for a derived screen, the note plus one artefact for a new one, looked at in a browser, never measured
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---
# /po-design

Reads settings: `Worktree root`, `Design source`, `Design skill`, `Design tool`

Story: $ARGUMENTS

The plan and the code of a story with a screen should start from a screen someone already decided. This command decides it, from the recorded system, and writes it down in the story's worktree. It writes no source file.

## Checks
1. No `AGENTS.local.md` → stop and point to `/po-setup`.
2. Match $ARGUMENTS to one id of `docs/stories.md`; none or several → list the ids and stop.
3. `<Worktree root><id>` must exist and `git -C <path> rev-parse --abbrev-ref HEAD` must print `story/<id>`. If not, stop and point to `/po-research <id>`. Never create, switch or check out a branch here.
4. Inside the worktree, `docs/design-system.md` is missing → stop and point to `/po-design-system`: there is nothing to derive a screen from.
5. `Design source` is `—` → stop and ask the person to choose `internal` or `external` and write it in `AGENTS.local.md` themselves. Do not set it for them.

Either way the command writes nothing and draws no mockup.

6. The story has no screen to show → say so and stop, writing nothing.

Then read the `design-doctrine` skill, the story, `docs/research/<id>.md` when present, and `docs/design-system.md`. Everything below reads and writes inside the worktree.

## Where the design lives
Every file this command produces goes under `docs/designs/<id>/` in the story worktree: `design.md` always, and for a new screen either `mockup.html` or `brief.md`. These files are the source of truth for the screen: an export from a design tool, a message in a chat or a mockup kept elsewhere is a reference that loses against them, until a person runs `/po-design` again to change them.

They stay uncommitted, like the research and the plan; the implementer commits them with the story.

## Step 1 — Derived or new
Split the screen into its regions. When every region maps to a pattern and to components already listed in `docs/design-system.md`, the screen is derived. When at least one region needs a layout the system does not hold, it is new. When you cannot tell, ask once, in an AskUserQuestion that shows the regions and the pattern each would reuse.

## Step 2 — The note
Fill `templates/design-screen.md` into `docs/designs/<id>/design.md`.

- Derived: the note records the pattern it reuses and the deltas only — what differs from that pattern — and there is no artefact.
- New: fill every section.

Components, variants and tokens come from the inventory of `docs/design-system.md` by name. Whatever the screen needs and the system lacks goes to the note's `## Gaps`; it is recorded, not filled in.

## Step 3 — The artefact
A new screen only, and exactly one artefact, chosen by `Design source`:
- `internal` → `mockup.html`, drawn with the skill named in `Design skill`. When `Design skill` is `—`, stop before drawing and say the project names no skill to draw with.
- `external` → `brief.md`, from `templates/design-brief.md`, written for the tool named in `Design tool`. When `Design tool` is `—`, write the brief for no tool in particular and say so.

Never both. The artefact reaches final fidelity: each state it can be in (drawn from empty, loading, error, success, disabled and focus), light and dark, desktop and mobile, with the real text of the product — no placeholder copy. Its tokens and components are the ones the note lists.

The mockup is a reference for the implementer, never code: nothing in it is copied into source files.

A brief is text for another tool, so it is not rendered; the note says so under `## Seen and not seen`.

## Step 4 — Look at the mockup
Serve `docs/designs/<id>/` over local HTTP with `python3 -m http.server --bind 127.0.0.1 <free port>` — never through `file://`, where fonts, scripts and relative paths behave unlike on a served page. Open the page with whatever browser tool the session has, in light and in dark, at desktop and at mobile width, and go through each state.

Look for what is broken: text that overflows or is cut, overlapping regions, a theme that leaves a surface unstyled, a state that does not show, a control out of reach on mobile. Fix the mockup and look again.

Nothing is measured here. Contrast was measured by `/po-design-system`; this step trusts those numbers.

Write in `## Seen and not seen` what was looked at and what could not be seen — no browser tool in the session, a state the page cannot reach — with the reason. Stop the server when you are done.

## Approval
One grouped AskUserQuestion shows the note, the kind of screen, the gaps and the artefact's path, and asks for approval. A change goes back to the step it belongs to. Nothing is reported as done before approval.

Finish with: "Design written to docs/designs/<id>/ in <path>. Next: /po-plan <id>"
