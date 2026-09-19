---
description: Frame the replacement or the adaptation of an existing SaaS through an interview, one question at a time, and commit docs/prd.md on the target branch
argument-hint: <target SaaS>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - AskUserQuestion
---
# /po-prd

Reads settings: `Entry mode`, `Target branch`

A kill PRD keeps the part of the target that people really use and buries the rest on purpose. `$ARGUMENTS` names the target; the mode comes from the settings alone, never from the argument.

## Checks
1. No `AGENTS.local.md` → stop: "Run /po-setup first."
2. Read `Entry mode`.
   - `replace` or `adapt` → continue.
   - `new` → stop: "This project starts from an idea, not from an existing SaaS: run /po-brief instead."
   - `—` → stop: "`Entry mode` is not set: run /po-setup or set it in AGENTS.local.md." Do not guess it from the argument.
3. No target in `$ARGUMENTS` → ask for it before anything else.
4. `docs/prd.md` exists with `status: draft` → resume: show the validated sections and continue at the first empty one. With `status: approved` → stop and say the PRD is already approved; editing it is the user's call.

## Interview rules
- One question per message. Wait for the answer before the next one.
- Offer a suggested answer when the target's public product makes one obvious; the user corrects it.
- Nothing enters `docs/prd.md` before the user validates it. Each section is shown in full, validated, and only then written; the file is created from `templates/prd.md` with `status: draft` when the first section is validated.

## Sequence
1. **Target and why** — which product, which plan, and what is wrong with it today.
2. **Mode** — confirm the `Entry mode` value with the user and say what it implies. A mismatch → stop and point to AGENTS.local.md; the interview never switches mode.
3. **Core loop** — go through the target's features one by one. For each: is it in the loop, and its complexity on the scale of `templates/stories.md`, with a one-line justification.
4. **Graveyard** — every feature left out of the loop, with the reason. Aim for an exhaustive list: what is not buried here will come back as a story.
5. **Angle** — what the product does better than the target. In `replace` mode, write the internal gain, or "parity only" when there is none. In `adapt` mode, run the challenge below.
6. **Need**, **Users**, **Constraints** — one section each.
7. **Success criteria** — each one with a number or threshold and the way it is measured; "users are happy" is not a criterion.

**Heavy features.** A feature scored 4 or 5 must justify its place in the core loop: ask what breaks for the user without it. No convincing answer → it goes to the graveyard. A 5 that stays is flagged for splitting when stories are written.

## Adapt mode — challenging the angle
A competing product lives or dies by its angle, so treat it like a brand-new idea and put three probes to it, one per message:
- **Evidence of pain** — who has already complained about this gap in the target, and where can we see it (tickets, reviews, lost deals)? An angle nobody has asked for is a hypothesis; write it down as one.
- **Exact consumer** — which person, in which role, uses the angle and on which occasion? "Everyone" is not an answer.
- **Success signal** — what observable change, within which delay, will show the angle works? It becomes a line of the success criteria.

When a probe gets no answer, the angle section records the gap instead of filling it.

## Finish
1. Show the whole PRD and ask the user to read it end to end. On approval, set `status: approved`.
2. Commit from the repository root, on `Target branch` only; another branch → stop and say so. Check `git status --porcelain` first: an environment file listed there → stop. Commit `docs/prd.md` alone as `docs: PRD for <target>`.

Finish with: "PRD approved. Next: write the stories in docs/stories.md."
