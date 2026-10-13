# Research — s102-ship-follows-the-forge

## Structuring facts
- **One AC pair needs a reading, not a correction.** `forge_tightening_switches_to_human` says a forge that now requires review moves "the setting" to `human (forge)`; `chosen_value_never_moves` says a `(chosen)` value is never rewritten. ADR-0075 already bounds the rewrite ("ne touche jamais un (choisi)"). Resolved in ADR-0079: only a `(forge)` value is rewritten; the forge's requirement still governs the ship's *effective* value whatever the line says.
- **ADR-0075 leaves four points open** — meaning of a value with no suffix (this repo's own `Ship confirmation: automatic`, `AGENTS.local.md`), how the forge is read, the `automatic (chosen)` vs. required-review case, where the rewritten line is committed. All four settled in `docs/decisions/ADR-0079-ship-confirmation-porte-son-origine-et-la-forge-se-lit-par-gh.md` (reserved number).
- **No script parses `Ship confirmation`.** Only method prose reads it (`method/commands/po-ship.md:38-42`, `po-drive.md:135`, `po-orchestrator.md:79`, `po-flow.md:82`, `method/AGENTS.md:115`); `bin/polype:191-207` only names missing settings. The suffix rule is a text change, no parser.
- **`po-setup.md` Step 2 must keep exactly five numbered lines**: three tests count `^[0-9]+\. ` (`tests/setup-modes.test.sh:32`, `tests/platform-setting.test.sh:73`, `tests/qa.test.sh:66`) and question 4 is frozen (`tests/design-handoff.test.sh:44`). The `Ship confirmation` question must be an unnumbered follow-up.
- **The forge API answers 403 "Upgrade to GitHub Pro"** on a private free repo for both `branches/main/protection` and `rules/branches/main` (probed on `atoll-io/polype`, 2026-10-13); `collaborators` answers and lists `TheCrabe` alone. A plan-limit 403 must count as "no protection", or every solo private repo is "unreadable" forever.

## Story
A solo project lead wants the fleet to merge what `po-gate ship-allowed` proved, without being asked, unless the repository or the person requires a human review (ADR-0075). Criteria: `setup_reads_review_rules_from_the_forge`, `setting_records_its_origin`, `template_defaults_trust_the_gates`, `forge_tightening_switches_to_human`, `chosen_value_never_moves`, `pr_wait_does_not_block_the_fleet`, `ship_gate_unchanged`. Complexity 3, no dependency, `Surface: —`, no screen, no QA (`QA stage: —`).

## Current code
- `method/templates/agents-local.md:12-13` — `Plan validation: human`, `Ship confirmation: human`. Table rows `:44-45`: `human` / `autonomous`, `human` / `automatic`. Header `:5`: "no comment after the value (anything after the colon is the value)".
- `method/commands/po-setup.md:21-28` Step 1 (bullets: lockfile, scripts, default branch, base). `:30` heading "Five questions … plus the Platform, design and QA stage follow-ups and the catalogue offer". `:32` question 2: `Plan validation`, "Propose the same value for `Ship confirmation`; change it only if the user asks." `:45` "Nothing else is asked beyond these five questions, …" listing follow-ups. `:53` commits on `Target branch`.
- `method/commands/po-ship.md:17-18` Step 0 gate; `:20` reads settings; `:22` re-entry when PR already `MERGED`; `:36-39` pr mode (`human` stops at "Pull request ready", `automatic` → `gh pr merge … --squash`); `:41-43` local mode (`human` → AskUserQuestion, root clean on `Target branch`); `:45-48` cleanup on proof. Tools: Read, Bash, AskUserQuestion (`:4-7`) — no Write, so a line rewrite goes through Bash.
- `method/commands/po-drive.md:33-40` ready set (`Parallel` counts "the lanes already running"); `:47-63` resume table, first match wins, ends with "review … `yes`" → the ship (`:62`) and shipped → nothing (`:63`); `:132-137` "Ships, one at a time"; `:135` "`Ship confirmation: human` means one AskUserQuestion per merge"; `:139-150` report and `status` (reasons a human decides, `:148`). Reads `Ship confirmation`, `Merge mode` already (`:14`).
- `method/commands/po-orchestrator.md:78-81` stage 8 defers to `/po-ship` for `Ship confirmation` and `Merge mode`.
- `method/commands/po-flow.md:82` ship step defers to `/po-ship`; `:92` finish line includes "Pull request ready: <url>."
- `method/AGENTS.md:6-8` "Reading settings" ("An agent reads settings, it never decides them"); `:53` "**Ships stay serial** … in the order the reviews passed"; `:113-115` Merging.

## Attachment points
- Suffix rule and the `(forge)` exception: `method/AGENTS.md:8` (append to the paragraph). Fleet: `:53`. Merging: `:115`.
- Forge rule, written once: a new `## The forge's review rule` section in `po-ship.md` between Step 0 (`:17-22`) and `## Step 1` (`:24`). `po-setup.md` Step 1 and the follow-up point to it, as `po-drive.md:82` points to `po-research.md` for worktree preparation.
- Effective value used at `po-ship.md:38`, `:39`, `:42`.
- Waiting lane: a new resume row in `po-drive.md` before `:62`; `Parallel` counting at `:40`; `status` reasons at `:148`; ships paragraph `:133-135`.

## Verified interfaces
- `po-gate ship-allowed <id>` — first command of `po-ship.md` Step 0 (`:18`), before any `## Step 1` (`tests/ship.test.sh:6-13` checks the order). Unchanged by this story.
- `gh pr view story/<id> --json state --jq .state` — already used at `po-ship.md:22` and `:46`; states `OPEN`, `MERGED`, `CLOSED`.
- `gh api repos/{owner}/{repo}/collaborators` returns objects with `login` and `permissions.push` (probed). `gh api user --jq .login` → `TheCrabe` (probed). `gh` 2.102.0 at `/usr/bin/gh`.
- `template_settings` (`tests/lib.sh:33`) — every name in the template's fenced blocks; `tests/structure.test.sh:8-12` requires each fenced line to match `^[A-Z][A-Za-z0-9 ]*:[[:space:]]+[^[:space:]#][^#]*$` — `automatic (forge)` would pass, no `#` allowed.
- `section_of` in `tests/drive.test.sh:8` reads one `## ` section; `holds` greps it fixed-string.

## Traps
- **Frozen phrases to keep** (additive changes only, unless owned and said):
  - `tests/drive.test.sh:85` `` `Ship confirmation: human` means one AskUserQuestion per merge `` — owned; the story changes it and must update this line and say so. Also keep `:79-84` ("Ships never overlap.", "you ship one story, prove it, then ship the next", "requires the repository root clean and on `Target branch`", "`po-gate ship-allowed <id>` first", the last-`Ship allowed:` sentence).
  - `tests/fleet-wiring.test.sh:36-38` "**Ships stay serial**", "lands on `Target branch` alone", "in the order the reviews passed" (Law 1 section of `method/AGENTS.md`).
  - `tests/ship.test.sh`: gate before `## Step 1`; "the **last** line starting with `Ship allowed:`"; "Merge, always as a squash"; `gh pr merge <url> --squash --subject "<id>: <story title>"`; "already prints `MERGED`, go straight to cleanup"; AskUserQuestion tool kept. `tests/review-tree-gate.test.sh:62` "between that verdict and the verdict line before it". A new `##` section between Step 0 and Step 1 falls inside the `ship.test.sh:49` Step 0 slice — harmless, it only greps for presence.
  - `po-setup.md` Step 2: five numbered lines; heading keeps `Platform`, `QA stage`, `catalogue` (`tests/commands-and-texts.test.sh:31-35`); question 4 untouched; "Nothing else is asked" (`setup-modes.test.sh:36`); the Platform follow-up stays before the catalogue offer (`platform-setting.test.sh:74-78`); `QA stage` stays in an unnumbered line (`qa.test.sh:65`). Also `structure.test.sh:38-43`, `catalogue-wiring.test.sh:10-16`, `model-routing.test.sh:81`.
  - `po-drive.md` row order checked by `tests/qa-fleet.test.sh:77-81,181`, `resume.test.sh:39` — a new row placed after the review rows touches none of them.
- **Installed copies**: `.claude/`, `.polype/` and the root `AGENTS.md` are generated; only `method/` changes (`AGENTS.local.md` conventions).
- **`tests/overlap.test.sh`**: no 8-word run shared with Killer SaaS; write fresh prose.
- **`bin/po-lint`**: every `Reads settings:` name must be a template setting (`structure.test.sh:24-33`); no new setting is added, so nothing to declare.
- **Root `AGENTS.local.md` of this repo** stays `Ship confirmation: automatic` with no suffix: by ADR-0079 it reads as `(chosen)`. Not owned; not touched.
- `docs/migration.md:41` and `docs/parite-killer-saas.md` mention the setting generically; not owned, still true.
- **s103 depends on this story** for "a PR waiting for a human merge" in `/po-drive status` (`docs/stories.md:1592`). The status reason must be named in words s103 can quote.
- No migration, no dependency, no new setting.

## Open questions
- A 403 from missing admin rights on `branches/<b>/protection` vs. the plan-limit 403: told apart by message only (ADR-0079 neutral consequence). The plan reads the plan-limit message as "none" and any other 403 as unreadable.
- In `pr` mode with a newly protected branch, the push of the `chore:` settings commit will be refused; ADR-0079 keeps it local and reported. A human reconciles; nothing more is automated here.
- Should a waiting lane be listed by `/po-status` too? `po-status.md` is not owned; left to a later story.

## Complexity
3 → 3. Text-only changes in six owned method files and two tests, but many frozen phrases and the waiting-lane state in `po-drive` (resume row, `Parallel` accounting, `status`) carry the risk. No split.

## Split
—
