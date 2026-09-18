---
description: Create the project's AGENTS.local.md — the settings and commands every Polype command reads. Runs once.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - AskUserQuestion
---
# /po-setup — The project's settings

Reads settings: none

You write `AGENTS.local.md`, the file the project owns and the installer never overwrites. Every other command reads its settings there.

## Contract
- **Never overwrite.** If `AGENTS.local.md` already exists, show its settings and stop: "Settings already exist in AGENTS.local.md. Edit that file, or delete it and rerun /po-setup."
- Never write into `AGENTS.md`: the method owns it.
- Never invent a project command you have not seen in the repository.
- Ask only the three questions below. Everything else keeps its default and can be changed later in the file.

This command is the only creator of `AGENTS.local.md`, so finding it absent is the normal case.

## 1. Read what the repository already answers
Never ask what the code states. Find the package manager from the lockfile, the scripts the project declares (package manifest, task runner, Makefile), and the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`, else the current branch). What you find becomes the proposed answer.

## 2. Ask (AskUserQuestion), and only this
1. **Where a story lands** — `Merge mode` (`pr` or `local`), with `Target branch` confirmed.
2. **Who validates a plan** — `Plan validation` (`human` or `autonomous`). `Ship confirmation` takes the same value unless the user says otherwise: whoever validates plans by hand confirms ships by hand.
3. **The project's commands** — `Package manager`, `Install`, `Test`, `Typecheck`, `E2E`, `Build`, pre-filled from step 1. A command the project lacks stays `—`.

## 3. Write
Fill `templates/agents-local.md` with the answers and the defaults, into `AGENTS.local.md` at the repository root. Keep the shape exactly: one setting per line, no trailing comment — the value is everything after the colon, so a comment becomes part of it. Leave "Project conventions" as its placeholder.

Commit it on `Target branch` (`chore: polype settings`). It is a project file, not a story file.

## 4. Assemble
Rerun the installer so `AGENTS.md` carries the rules plus these settings. If the installer is not available, say so: the settings are written, the assembled file is one install away.

End with: "Settings written to AGENTS.local.md. Next: write the stories in docs/stories.md, then /po-research <story>."
