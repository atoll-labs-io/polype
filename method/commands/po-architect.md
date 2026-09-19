---
description: Settle the project's base, read its code, write its habits as rules in AGENTS.local.md, record one ADR per structural choice and commit docs/architecture.md on the target branch
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---
# /po-architect

Reads settings: `Target branch`, `Package manager`, `Install`, `Test`, `Typecheck`, `E2E`, `Build`

Stories fit a base far better than they invent one. This command decides what that base is, learns how it is built, and turns what it learns into rules and decisions every later stage reads: the conventions in `AGENTS.local.md`, the ADRs in `docs/decisions/`, the map in `docs/architecture.md`. It decides and records; it does not produce code.

## Checks
1. No `AGENTS.local.md` → stop: "Run /po-setup first."
2. Work from the repository root, on `Target branch`. Any other branch → stop and say so; never switch, check out or stash to get there.
3. `docs/architecture.md` already exists → this is a rerun: amend that file rather than starting over, and treat every decision that changes as a new ADR that supersedes the old one.

## Step 1 — The base
A base is detected when the repository holds a package manifest, or source files outside Polype's own files (`AGENTS*.md`, `CLAUDE.md`, `docs/`, `.claude/`, `.polype/`, `.gitignore`).

Look for a profile of that base: when Polype's repository is at hand, `boilerplates/<name>/profile.md` there describes a catalogued boilerplate. A profile is where the reading starts; the code of this project confirms or corrects it. No profile is the ordinary case: the analysis of step 2 then works alone. When no catalogue can be reached, say so and let the user name the boilerplate.

With no base detected, ask one AskUserQuestion with exactly three answers:
- **a boilerplate from the catalogue or one the user owns** — the person brings it into the repository and commits it;
- **a scaffolded default, recorded as an ADR** — the ADR holds the generator's exact command and version;
- **an empty repository, assumed** — recorded as an ADR too. Warn that parallelism will suffer: with no base, authentication, tenancy and billing become foundation stories that run one after another before any two stories can run side by side.

This command never runs a generator or writes source code: for the first two answers the person scaffolds or copies the base, commits it, then runs `/po-architect` again, which now finds a base and continues at step 2. For the third, continue at step 3 with nothing to analyse.

## Step 2 — Read the code before deciding
Apply the `codebase-analysis` skill to the base: the profile first when there is one, then the code itself. Its output — the map, the habits turned into rules with `path:line`, the attachment points — is what steps 3 and 4 draw from.

No decision is drafted before this analysis is done.

## Step 3 — Structural decisions
Each structural choice becomes one ADR in `docs/decisions/` from `templates/adr.md`. Draft one for:
- the stack: language, framework, runtime, as the base already fixes them;
- each capability the project needs — database, authentication, authorization, multi-tenancy, files, background jobs, email, payment, cache, observability, internationalisation, deployment — naming the brick in use as the default and the bricks that could replace it; a capability the project does not need is said so in `docs/architecture.md`, without an ADR;
- each third-party integration the project depends on.

Number them `NNNN-<slug>.md` from the next free number in `docs/decisions/`, with `scope: framing`. They become `status: accepted` once approved. An accepted ADR is never edited: a changed decision is a new ADR whose `supersedes` names the old one, and the old one gets `superseded-by` and `status: superseded`.

## Step 4 — Conventions as rules
Write the conventions as rules in the `## Conventions` section of `AGENTS.local.md`. Replace only that section's placeholder or body, with Edit; every settings block stays as it is — this command reads settings, it never decides them. Each rule is one line an agent can obey, backed by the `path:line` where the base shows it.

The project commands are quoted from the settings into `docs/architecture.md`. When the base defines different ones, report the difference and ask the user to edit the settings; do not change them.

## Never rewrite the base
Never propose rewriting, replacing or restructuring the base: stories adapt to it. A brick that must change is swapped behind its capability by a later story, recorded by a new ADR, never by this command.

## Approval and commit
1. Draft `docs/architecture.md` from `templates/architecture.md`, filling its map, capability table, ownership and attachment points from steps 2 and 3.
2. One grouped AskUserQuestion shows the drafted ADRs, the conventions and `docs/architecture.md` together and asks for approval. A change goes back to the step it belongs to; nothing is written before approval.
3. Write the files. Rerun the installer if it is available, so `AGENTS.md` carries the new conventions; otherwise say that `AGENTS.md` will catch up at the next install.
4. Check `git status --porcelain`: an environment file listed there → stop. On `Target branch`, commit `docs/architecture.md`, the new ADRs, `AGENTS.local.md` and, when the installer regenerated it, `AGENTS.md`, as `docs: architecture`.

Finish with: "Architecture recorded. Next: /po-research <first story id>"
