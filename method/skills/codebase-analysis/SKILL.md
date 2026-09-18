---
name: codebase-analysis
description: Map code you did not write — its structure, its real conventions, where new work plugs in — before touching it. Use for story research, architecture, and onboarding onto a boilerplate.
---
# Codebase analysis

You are about to change code someone else wrote. Learn how it actually works first, and turn what you learn into rules the next agent can follow.

## Sequence: wide, then one deep cut

1. **Map.** Folders, entry points, layers, build and configuration files, test layout.
2. **Walk one feature end to end.** Pick a representative one and follow it from the entry (route, command, event) through the logic and the data access to what the user sees. One walk reveals more real conventions than any document.
3. **Name the recurring patterns.** Naming, file placement, error handling, data access, validation, tests.
4. **Surface the implicit rules.** What the code always does the same way is a rule, even if nobody wrote it down.
5. **Locate the anchor points.** Where new work of this kind plugs in: the file, the function, the registry, the route table.
6. **Report as rules.** "Server actions live in `src/actions/`, one file per domain" — not "there are some actions". Rules are what feed `AGENTS.local.md` and the research.

## Discipline
- Name a file, a function or a signature only after opening it. A plausible path you did not open is a hallucination in waiting.
- Cite `path:line` for every fact that matters.
- Describe; never propose a rewrite. The existing structure is imposed: new work conforms to it.
