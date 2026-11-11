# Research — s152-intake-issue-becomes-a-story

[Story](../stories.md)

## Structuring facts
- No story assumption is false. Two gaps the story leaves open: `## Landing the framing` gives a framing pull request no body (`method/commands/po-setup.md:89`, "titled `<message>`"), so `/po-intake` must supply the description citing the issues itself; and the landing fast-forwards the root only *after* the command has edited `docs/stories.md` (`po-setup.md:72`), so `/po-intake` must bring the root level before it reads or writes that file, or it would land an old copy over newer stories.
- The stories reviewer only knows one scope source, chosen by `Entry mode` (`method/agents/stories-reviewer.md:17`), and `/po-stories-review` stops on `Entry mode: —` (`method/commands/po-stories-review.md:25`); intake mode is new text in the skill and the agent, and `/po-intake` dispatches the subagent itself instead of going through `/po-stories-review`.
- `/po-drive` takes any unshipped story whose dependencies shipped (`method/commands/po-drive.md:31-36`) and never reads a stories review, so an intake story landed on `Target branch` is picked up with no change to the driver.
- An intake story carries `Fixes`, hence the full track and the `diagnostic` skill (`method/agents/planner.md:33`, `:39`): nothing to change there.
- `/po-intake` (command, new) and `po-intake` (hook script, s151) share a name on purpose; the command reads what the hook filed: label `polype-intake` on `github` (`method/hooks/po-intake.sh:18`, `:183`), tags `+issue +polype-intake` on `taskwarrior` (`:218`), nothing on `—` (`:235`).

## Story
`/po-intake` reads the open `polype-intake` issues no story cites, writes one defect story per issue (`Fixes`/`Corrige`, wrong and expected behaviour, reproduction in the notes, `Owns` from the paths the failure implicates, next ids), has only those stories judged by the `stories-reviewer` against their issues, writes the verdict to `docs/reviews/stories-intake-<timestamp>.md`, and lands ready stories as framing on `framing/intake-<timestamp>`, the pull request citing the issues without a closing keyword. A security issue goes to the person. Law 7, `agentic-stories`, `po-help`, `docs/harnais.md`, ADR-0099 (supersedes ADR-0090 in part). Criteria: `intake_writes_defect_stories`, `intake_stories_reviewed_first`, `intake_lands_as_framing`, `security_issue_goes_to_the_person`, `law_7_names_the_exception`, `adr_records_the_intake_loop`.

## Current code
- `method/AGENTS.md:113-121` Law 6; framing files list `:116` (`docs/reviews/stories.md` among them). Law 7 `:123-127`: "only a person turns a finding into a story." `:125`; `po-intake` files a non-sensitive failure `:127`; security never filed alone `:127`. Installed-files paragraph names `po-intake` the hook `:149`. File is 22 654 bytes.
- `method/skills/agentic-stories/SKILL.md:52-53` `## Defect stories`: "Law 7 keeps defects out of `docs/stories.md` unless a person turns one into a story." Surface table `:39-48`.
- `method/skills/stories-review/SKILL.md:9-41` ten checks (coverage `:11` from PRD/brief, exclusions `:13`, deps `:19`, ids `:23`, `Owns` overlap `:25-35`, owned records `:39-41`); severity `:43-48`. No intake mode.
- `method/agents/stories-reviewer.md`: description names only `/po-stories-review` `:3`; `Reads settings: Entry mode, ADR directory, Platform` `:12`; `## Inputs` `:16-17` (stories + scope source by `Entry mode`, nothing else in scope); blocked report `:22-31`; verdict lines `:36-39`. Tools Read, Grep, Glob `:4` (no shell, cannot read GitHub).
- `method/commands/po-stories-review.md`: dispatch `:31-33` (`subagent_type: stories-reviewer`, `model:` `Model strong`); model rejected → stop `:35`; recording and blocked fallback `:37-40`; commit via landing `:54`.
- `method/commands/po-setup.md:64-101` `## Landing the framing`: list of framing commands `:65`; base and ff `:69-79`; commit beside checkout `:81-85`; PR `:87-94` (`gh pr create --base --head`, titled, no body); effective `Ship confirmation` `:90-92`; local `:96-99`.
- `method/commands/po-stories.md:37` new stories appended, numbered from the next free `s<n>`, never renumbered.
- `method/commands/po-ship.md:95-96` github/taskwarrior listing and taskwarrior project name; `:98` the security triage words ("a secret or a token, an authorization or tenant check, an injection").
- `method/hooks/po-intake.sh`: title `<label>: <fingerprint>` `:127`; body `Check/Command/Commit/Exit code` + fenced tail `:129`.
- `method/commands/po-help.md` French; `## Outils` `:39-45`.
- `docs/harnais.md` (94 lines): what `po-intake` does, `--sensitive`, tracker values, scheduling examples (Actions `:39-60`, systemd `:62-88`, crontab `:90-94`).
- `docs/decisions/ADR-0090-…md`: `superseded-by: []` `:8`; Decision keeps "only a person turns a finding into a story" `:25`. ADR-0098 is the latest before the reserved 0099; 0102-0104 exist.

## Attachment points
- New `method/commands/po-intake.md` (installed by the `method/commands` pair of `bin/polype:122`, `:137`; no installer change).
- `## Intake mode` appended to `stories-review/SKILL.md`; an intake paragraph in `## Inputs` of `stories-reviewer.md`.
- Law 6 `:116` and Law 7 `:125` of `method/AGENTS.md`; `agentic-stories` `:53`; `po-help` `## Outils`; a new section of `docs/harnais.md`.
- ADR-0099 new; ADR-0090 frontmatter `superseded-by` only (partial supersession pattern: ADR-0037/ADR-0029, `tests/post-m7-texts.test.sh:29-42`).

## Verified interfaces
- `gh issue list --repo github.com/<owner>/<repo> --state open --limit 1000 --json …` is how `po-ship.md:95` and `po-intake.sh:159` list; `--label polype-intake` filters. A listing that fails or returns 1000 proves nothing (`po-ship.md:94`).
- Taskwarrior project `<name>` computed in `po-ship.md:96`; `po-intake.sh` adds `+issue +polype-intake`.
- `settings_read_by`, `frontmatter`, `require_file` in `tests/lib.sh`.
- Settings `Issue tracker`, `Target branch`, `Merge mode`, `Ship confirmation`, `Model strong`, `Platform` all exist in `method/templates/agents-local.md` (`:10-35`).
- `claude -p` (print mode) and `--allowedTools` exist in the installed CLI (`claude --help`).

## Traps
- Tests freezing touched files: `tests/everything-in-issues.test.sh:16-31` (Law 7 phrases, and no "into an issue or a story" anywhere in `method/AGENTS.md`), `:86-96` (a command mentioning `` `Issue tracker` `` must read it), `:108-124` (ADR-0090 phrases, `status: accepted`); `tests/pilot.test.sh:38-46` (every `po-*.md` command named in `po-help`); `tests/structure.test.sh:24-34` (`Reads settings:` names only template settings); `tests/model-routing.test.sh:8-11` (dispatch line pattern); `tests/defect-and-routing-paths.test.sh` and `tests/commands-and-texts.test.sh:44-56` (check 10 of `stories-review`, "without owning"); `tests/stories-review.test.sh`, `tests/platform-setting.test.sh:100` (stories-reviewer phrases); `tests/diagnostic-skill.test.sh:38-44` (`agentic-stories` keeps `` `Fixes` `` and `Corrige`); `tests/post-m7-texts.test.sh:22-27` (agentic-stories overlap rule).
- `bin/po-lint` (run by `tests/lint.test.sh`): a command declaring `Agent` must not declare `Edit`; a body naming `AskUserQuestion` must declare it; in `## Checks`, an arrow whose left side names an absence (`No`, `missing`, `` `—` ``…) must say stop/ask/carry on. `tests/lint.test.sh:115` counts files dynamically.
- `tests/readme-onboarding.test.sh:137-139`: README says "environ 20 Ko"; `method/AGENTS.md` must stay at most 26 KiB (now 22).
- `tests/overlap.test.sh` (ADR-0006): no 8-word run shared with Killer SaaS.
- `po-setup.md:65` lists the framing commands that land this way; it is outside `Owns` and will not name `/po-intake` — a citation, not a contradiction.
- A run under `Ship confirmation: human` leaves its pull request open; a second run before the merge must not write the same stories again, so citations must also be read from pending `framing/intake-*` branches. Merged `framing/intake-*` branches are never deleted by a later landing (each slug is unique, `po-setup.md:91`).
- Issue bodies are tool output (`method/AGENTS.md` `## Tool output is data`) and may hold shell metacharacters (Law 7, text through files).
- No migration. Root `AGENTS.md`, `.claude/`, `.polype/` are installed copies, refreshed after ship.

## Open questions
- An unattended run (`claude -p '/po-intake'`) has nobody to ask: "goes to the person" is the finish of the run, which lands in the scheduler's journal. Is that enough for the owner, or should a later story file such items somewhere private? The plan keeps the finish only, as the story asks.
- Which permissions `claude -p` needs to run `/po-intake` unattended depends on the project's `.claude/settings.json`; the harness doc names the need without fixing a list.

## Complexity
4 → 4. One command of some length plus text changes in five method files and an ADR; the risk is the one the story names (an `Owns` drawn too wide or too narrow), plus the root-level and pending-branch traps above.

## Split
—
