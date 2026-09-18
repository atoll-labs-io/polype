---
name: codebase-analysis
description: How to read an unfamiliar codebase before changing it — map it, trace one real feature, and write down its habits as rules. Used for story research, architecture work and boilerplate profiles.
---
# Reading someone else's code

Goal: know how this code base really works before touching it, and leave behind rules the next agent can apply without rereading everything.

## Method
1. **Survey.** Top-level folders, entry points, configuration and build files, where tests live and how they are named.
2. **Trace one feature from end to end.** Choose one that resembles the work ahead and follow it: entry point (route, command, handler), logic, data access, what reaches the user. A single trace shows the real habits faster than any README.
3. **Collect the habits.** How files are named and grouped, how errors travel, how data is read and written, how inputs are validated, how tests are organised.
4. **Promote habits to rules.** Something done the same way everywhere is a rule of this code base, written or not.
5. **Mark where new work attaches.** The file, function, registry or route table a change of this kind has to go through.
6. **Write rules, not impressions.** "Each domain has one actions file in `src/actions/`" helps; "there seem to be actions" does not.

## Discipline
- Only name what you have opened. An unopened path that "should" exist is where hallucinations start.
- Attach `path:line` to every fact someone will act on.
- Report how things are. Suggesting a rewrite is out of scope: new work adapts to the existing structure.
