# Research — s16-architect

## Structuring facts
- **Wrong assumption — `AGENTS.local.md` is said to be written by `/po-setup` alone**: `method/commands/po-setup.md:17` ends "no other command and not the installer ever writes this file". `/po-architect` must write its « Conventions » section (criterion 2). One clause of `po-setup.md` has to admit it — outside Owns, like the `po-help` line below. The installer only reads the file (`bin/polype-dev-install:57-63`), so conventions reach `AGENTS.md` only after a reinstall.
- `po-help` must list every command: `tests/pilot.test.sh:38-46` fails when `method/commands/po-architect.md` exists without `/po-architect` in `method/commands/po-help.md`. Outside Owns; s12–s15 each added one line in « Mise en place » (`po-help.md:13-16`).
- Killer SaaS has same-named files (`commands/ks-architect.md`, `templates/architecture.md`) in the local sources read by `tests/overlap.test.sh:5`: the check runs for real. Write only from the French descriptions C07/B04 (`docs/parite-killer-saas.md:42,30`), never from those sources.
- No catalogue exists yet: no `boilerplates/` folder anywhere in the repository. The profile path `boilerplates/<name>/profile.md` is Polype's (ADR-0001: method and boilerplates share one repo), not the project's, and nothing installs it into a project (`bin/polype-dev-install:44-48` copies only `method/`). The command must treat "no profile" as the normal case in M2.
- ADR path convention: rules say `docs/decisions/NNNN-<slug>.md` from `templates/adr.md` (`method/AGENTS.md:68`); `templates/adr.md` frontmatter has `scope: <framing | story <id>>` — architecture ADRs are `framing`.

## Story
`/po-architect` starts from the project's boilerplate and turns it into conventions written as rules, so each story fits the base instead of reinventing it. Criteria:
- `architect_asks_for_the_base` — no boilerplate detected → offer: a boilerplate from the catalogue or one the user owns; a scaffolded default recorded as an ADR; or an assumed empty repository, with the warning that parallelism will suffer.
- `architect_analyses_code_before_deciding` — applies `codebase-analysis` to the base and writes the conventions as rules in the « Conventions » section of `AGENTS.local.md`.
- `architect_records_structural_decisions_as_adrs` — every structural choice (stack, bricks per capability per ADR-0009, integrations) becomes an ADR in `docs/decisions/` from `templates/adr.md`.
- `architect_never_rewrites_the_base` — the command forbids proposing a rewrite of the boilerplate.
Notes: full profile format is M4; here read `boilerplates/<name>/profile.md` if present, else analyse the code. Output: `docs/architecture.md` committed on `Target branch` with the ADRs and `AGENTS.local.md`.

## Current code
- `method/commands/`: no `po-architect.md`. Framing commands (`po-prd`, `po-brief`, `po-stories`, `po-stories-review`) share a shape: frontmatter `description`, `allowed-tools` list; `Reads settings:` line; "Checks" (no `AGENTS.local.md` → "Run /po-setup first."); sequence; commit on `Target branch` from the repository root, `git status --porcelain` checked for env files first (`po-stories.md:47-49`).
- `method/templates/`: no `architecture.md`. `adr.md` is the MADR-minimal template (frontmatter `adr`, `status`, `scope`, `supersedes`, `superseded-by`; sections Context, Considered Options, Decision Outcome, Consequences).
- `method/skills/codebase-analysis/SKILL.md`: survey → trace one feature end to end → habits → habits promoted to rules → attachment points → "write rules, not impressions"; discipline "Only name what you have opened", `path:line`, "Suggesting a rewrite is out of scope". C08 is already `fait` (`docs/parite-killer-saas.md:43`). The command should call the skill, not restate it.
- `method/templates/agents-local.md:66-68`: `## Conventions` with placeholder `<< layout, stack, patterns, naming, commit style >>`. `po-setup.md:41` "Leave the conventions placeholder as it is" — so `/po-architect` is the one that fills it.
- `docs/architecture.md` is already a consumer contract: read by `/po-research` (`po-research.md:38`) and `/po-plan` (`po-plan.md:30`), committed on `Target branch` (`method/AGENTS.md:64`). Nothing yet produces it.
- Design context (`docs/conception.md:30`): pipeline Stories → Stories review → Architecture (boilerplate) → Design system. Profile contents (`conception.md:60-68`): commands, map, ownership granularity, rules, capabilities with bricks, UI inventory, origin and licence. Without boilerplate, foundations (auth, tenant, billing) become sequential stories before any parallelism (`conception.md:70`) — the source of the empty-repo warning.
- ADR-0009: capability → interface, default brick, alternatives; the project's brick choice "is made at the architecture step and recorded as a project ADR". Capability list: `conception.md:86` (database, auth, authorization, multi-tenant, files, jobs, email, payment, cache, observability, i18n, deployment). No capability catalogue file exists yet (`conception.md:118` lists it as future work).
- Parity: C07 (`:42`) status `à faire`; B04 (`:30`, conventions filled at architecture, from profile then analysis) `à faire` — not in the story's matrix line, but this story delivers it; the plan decides whether to touch it.

## Attachment points
- New: `method/commands/po-architect.md`, `method/templates/architecture.md`, `tests/architect.test.sh`.
- One line in `method/commands/po-help.md` « Mise en place », after `/po-stories-review` (forced by `pilot.test.sh:38`).
- One clause in `method/commands/po-setup.md:17` (see structuring facts).
- Matrix: status cell of C07 (`docs/parite-killer-saas.md:42`); possibly B04.
- Installer copies `method/commands/*` and `method/templates/*` (`bin/polype-dev-install:44-47`): nothing to register.

## Verified interfaces
- `tests/lib.sh`: `contains FILE PHRASE` (fixed, case-sensitive), `require_file`, `needs_tool`/`lacks_tool`, `frontmatter`, `settings_read_by`, `fail`.
- `tests/stories-review.test.sh:11`: local `section_of FILE HEADING` awk idiom, to pin a clause to one section.
- `tests/structure.test.sh:26-35`: every command needs a `Reads settings:` line with only template settings. Candidates exist in `method/templates/agents-local.md`: `Target branch` (:11), `Entry mode` (:23), `Worktree root`, `Install`/`Test`… Any new setting (e.g. a boilerplate name) would need a template line and a table row.
- `tests/pilot.test.sh:48-53`: ADR template keeps `## Considered Options` and `superseded-by`.
- Baseline on `story/s16-architect`: `bash tests/run.sh` → 101 passed, 0 failed.

## Traps
- `tests/overlap.test.sh`: fresh prose only (same-named KS files).
- `tests/pilot.test.sh:38`: help line.
- `tests/structure.test.sh`: `Reads settings:` line names only template settings.
- Method files in English; `po-help` in French.
- `/po-architect` runs on `Target branch` at the repository root (framing, not a story): commit rules as `po-stories.md:47-49`, including the env-file check.
- Rewriting AGENTS.local.md: only the `## Conventions` section; settings blocks untouched (`po-setup` never-overwrite rule, `structure.test.sh` `setup_never_overwrites_settings`).
- Installed copies `.claude/`, `.polype/` not edited.
- No migration, no code outside `method/`, `tests/`, `docs/`.

## Open questions
- Detecting "a boilerplate": what counts — a package manifest / source tree present vs. an empty repo (only docs and Polype files)? The plan fixes the signal.
- Where the catalogue is read from in a project that only has the installed method: the command could list profiles only when `boilerplates/` is reachable, and otherwise say the catalogue is not available. Plan decides the wording.
- Scaffolded default: which one? ADR-0010 names next-forge as the first profiled boilerplate; the command should not hard-code it but propose from the catalogue, recording the choice as an ADR.
- Human checkpoints: base choice and each structural ADR are decisions → AskUserQuestion (needs the tool). Approve ADRs one by one or as a batch (ADR-0014 "checkpoints groupés")?
- New setting for the chosen boilerplate? Probably no — the ADR and `docs/architecture.md` carry it; avoids touching the settings template (outside Owns).
- Template content of `docs/architecture.md`: base and origin, map, capability → brick table with ADR links, ownership granularity, attachment points, conventions pointer.
- Update B04 status as well as C07?

## Complexity
Story 3 → 3. Two method files, a test file, one help line and one clause in `po-setup`; the effort is prose in our own words and tests pinning the rules.

## Split
Not needed.
