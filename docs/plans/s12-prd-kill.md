---
validated: yes
---
# Plan — s12-prd-kill

[Story](../stories.md) · [Research](../research/s12-prd-kill.md)

Branch `story/s12-prd-kill`. Read `docs/research/s12-prd-kill.md` first; this plan builds on it without repeating it.

## Story
`/po-prd <target SaaS>` frames the replacement (`replace`) or adaptation (`adapt`) of an existing SaaS through a one-question-at-a-time interview, and writes `docs/prd.md` on `Target branch`, so the scope keeps only the core 20 %.
- `prd_reads_entry_mode_and_refuses_new` — reads `Entry mode`; `new` → stop and point to `/po-brief`.
- `prd_asks_one_question_at_a_time` — one question per message; nothing written the user has not validated.
- `prd_template_has_core_loop_graveyard_and_angle` — template has target, mode, core loop table (complexity 1–5 + justification), explicit graveyard, angle, measurable success criteria.
- `prd_challenges_the_angle_in_adapt_mode` — `adapt`: the angle faces probes on evidence of pain, exact consumer, success signal.
- `prd_scores_heavy_features_toward_the_graveyard` — a feature scored 4 or 5 justifies its place or joins the graveyard.

## Decisions
| Question | Choice | Why |
| --- | --- | --- |
| Where the adapt probes live | Written into `po-prd.md` in our own words (evidence of pain, exact consumer, success signal) | Research: `docs/references/spec-interrogation.md` is not installed in target projects; a runtime reference would dangle. The story's criterion is met by the probes' content, not the path. |
| `Entry mode: —` | Stop, point to `/po-setup` or `AGENTS.local.md` | Settings rule: `—` is never guessed around; the mode is never inferred from the argument. |
| Tools | `Read`, `Glob`, `Grep`, `Write`, `Bash`, `AskUserQuestion`; no `Edit` | Writes one doc and commits it, like `po-setup`; never touches code. |
| Validation granularity | Each section is shown and validated before it is written; file starts `status: draft`, becomes `approved` only after the user reads the whole PRD | Satisfies "nothing written unvalidated" and lets an interrupted interview resume from the file. |
| Angle in `replace` mode | Section kept; states what the internal version does better than parity, or says "parity only" explicitly | C02 keeps "angle beyond parity" in both modes; only `adapt` gets the challenge probes. |
| Complexity scale | Referenced from `templates/stories.md`, not redefined | One scale shared by PRD, stories and research (C03). |
| `po-help.md` outside Owns | Add one French line naming `/po-prd` under « Mise en place »; nothing else in that file | `tests/pilot.test.sh:38-46` requires every command in the help; the repository convention keeps existing tests green. Its owner s20 is not running and rewrites the help later. Amendment made after the first execute run hit it; revalidated autonomously. |
| Commit | From the repository root on `Target branch` only; other branch → stop; env-file check before commit; message `docs: PRD for <target>` | Story note: `docs/prd.md` lives on `Target branch`; Law 6 secrets rule. |

## Tasks
1. [x] `method/templates/prd.md`: frontmatter (`target`, `mode`, `status: draft`, `date`); sections `## Target`, `## Mode`, `## Why`, `## Core loop` with table `| Feature | Complexity (1–5) | Justification |` and a line pointing at the scale of `templates/stories.md` plus the 4–5 rule, `## Graveyard` with `| Feature | Why it is left out |`, `## Angle`, `## Need`, `## Users`, `## Constraints`, `## Success criteria` with `| Criterion | Target | How it is measured |`. — Test: `prd_template_has_core_loop_graveyard_and_angle` fails if any heading or either table header is missing.
2. [x] `method/commands/po-prd.md`: frontmatter (`description`, `argument-hint: <target SaaS>`, tools above); `Reads settings: \`Entry mode\`, \`Target branch\``; checks (no `AGENTS.local.md` → `/po-setup`; `Entry mode` `new` → stop with a sentence naming `/po-brief`; `—` → stop); interview rules (a sentence "One question per message." and a sentence that nothing enters `docs/prd.md` before the user validates it); sequence: target and why, mode confirmation, core loop feature by feature with a 1–5 score, graveyard, angle, need, users, constraints, success criteria; an `adapt` subsection with the three probes; the heavy-feature rule sentence; resume from an existing `status: draft` file; final read-through → `status: approved`; commit on `Target branch`. — Tests: `prd_reads_entry_mode_and_refuses_new`, `prd_asks_one_question_at_a_time`, `prd_challenges_the_angle_in_adapt_mode`, `prd_scores_heavy_features_toward_the_graveyard`.
3. [x] `tests/prd.test.sh`: the five tests, header `# s12 — kill PRD command and template.`, helpers of `tests/lib.sh`, each quoting short exact phrases of the file under test. The adapt test reads only the `adapt` section of the command (awk between its heading and the next heading) so the probes must sit there.
4. [x] `docs/parite-killer-saas.md`: status cells of C02 → `fait — method/commands/po-prd.md`, C03 → `fait — method/templates/stories.md, method/templates/prd.md`.
4b. [x] `method/commands/po-help.md`: one line in « Mise en place », after `/po-setup`: `- \`/po-prd <SaaS cible>\` — cadre le remplacement (\`replace\`) ou l'adaptation (\`adapt\`) d'un SaaS existant, une question à la fois.` — Test: existing `every_command_listed_in_help` (`tests/pilot.test.sh:38`).
5. [x] Full suite `bash tests/run.sh` green (incl. `overlap.test.sh`, `structure.test.sh`), verification record, one commit.

## Run interdicts
- Empty diff for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `tests/lib.sh`, every existing test file, every `method/` file other than the two new ones and the single added line of `po-help.md` (task 4b); `method/AGENTS.md` untouched.
- In `docs/parite-killer-saas.md`, only the status cells of C02 and C03 change.
- No reference to `docs/references/` inside `method/`.
- No Killer SaaS text: wording from the French matrix and `docs/conception.md:37-38` only; the overlap test must actually run (sources present).
- No `/po-brief` file created (s13).

## The pivot
Writing the adapt probes into the command instead of pointing at `docs/references/spec-interrogation.md`. Could be wrong if (a) the reviewer reads the criterion as requiring the path — compare with the installer (`bin/polype-dev-install:47`), which ships only `method/`; (b) the reworded probes lose one of the three (pain, consumer, signal) — the test checks each; (c) the wording drifts toward Killer SaaS `ks-prd` — overlap test.

## Files touched
`method/commands/po-prd.md`, `method/templates/prd.md`, `tests/prd.test.sh`, `docs/parite-killer-saas.md`, one line of `method/commands/po-help.md`, plus `docs/research/`, `docs/plans/`, `docs/verif/` for this story.

## Test strategy
Five text-level tests in `tests/prd.test.sh`, one per criterion (5 of 25). Text is the only layer of a markdown method. Each must turn red when its clause goes: the reviewer removes the `new` redirect, the one-question sentence, a template table header, a probe from the adapt section, the 4–5 rule. `structure.test.sh` already covers the `Reads settings:` contract for the new command; `overlap.test.sh` covers ADR-0006. No visual check.

## Done when
One commit on `story/s12-prd-kill`, full suite green, a review with no open critical finding, then the squash on `m2-cadrage`.
