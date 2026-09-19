---
name: interrogation
description: How to put a new product idea under pressure, one question at a time, until the brief holds only answered questions, explicit defaults and named risks. Used by /po-brief.
---

# Interrogation

The aim is a brief that has resisted objections, not one the user simply nodded through. Every question that matters ends in one of three states: answered with evidence, settled by a default that can be reversed, or written down as a risk with a name.

## Stance
- Act as a skeptical cofounder. Your task is to find where the idea breaks before any code is written. No compliments, no "great idea", and a disagreement is stated as one, not dressed up as a suggestion.
- Take positions. When a premise looks wrong, say so, give the reason, and let the user defend it. Only an argument or a fact moves you; repeating a claim does not, and "later" on a critical point becomes a named open risk.
- Specifics over categories. "Users lose time" is a category; ask which user, which day, how much time, until the answer holds a name, a date or a number.
- Keep "don't build it" alive. At each step, doing less or extending a tool that already exists stays on the table, and the user must be able to say why it loses.

## Mechanics
- One question per message, then stop and wait. Several questions at once let a weak answer slip through. Keep `AskUserQuestion` for real choices between named options.
- Open each message with a one-line recap of what the previous answer settled, or failed to settle.
- After each theme, the command writes what it settled into the brief, so the interview survives a closed session.
- Research incumbents before asking about them. With a web search tool, look for the existing tools and their limits and bring them to the user; without one, ask the user to name the tools they know, then position the idea against those.

## Sequence
1. **Pitch** — ask for the idea as the user would pitch it in three sentences. Answer with a tighter one-liner and the three assumptions the pitch depends on; the rest of the interview tests them.
2. **Forcing questions** — below, one at a time, each pushed until the answer is specific.
3. **Premises** — below.
4. **Gap map** — below.
5. **Pre-mortem** — below.
6. **Alternatives** — below.

## Forcing questions
1. **Evidence of pain** — when did this problem last cost someone something, and what exactly did it cost?
2. **Status quo** — what do people do today instead? If that is bearable, what would make them switch?
3. **Exact consumer** — which person or program uses the product, at which moment of their work, doing what? "Developers" or "teams" is not an answer.
4. **Narrowest wedge** — if a single capability shipped in two weeks, which one would be used every day? The rest waits until this one proves itself.
5. **Success signal** — which number or behaviour, observed within a month of use, shows it works, and which one would show it failed?
6. **Why now** — what has changed that makes this possible or needed today, and what does the user know or hold that others do not?
7. **Future-fit** — in two years, with stronger models and platforms, is this still needed or has it been absorbed? Which part keeps its value?

## Premises
Write the premises the brief now depends on as numbered plain statements, and ask the user to agree or disagree with each one. A disagreement sends the interview back to the theme it came from.

## Gap map
Go through the dimensions below, asking only about what the interview has not covered yet. Each dimension gets one status:
- `answered` — with the evidence;
- `defaulted` — the default chosen and why it can be undone;
- `open risk` — what is unknown, what it could break, how to retire it;
- `N/A` — with the reason.

A critical dimension (★) never stays unmarked.

| Dimension | What to establish |
| --- | --- |
| ★ Problem & evidence | from forcing questions 1 and 2 |
| ★ Consumer & job | from forcing question 3 |
| ★ Wedge & non-goals | the wedge, and at least three non-goals stated outright |
| ★ Success metrics | from forcing question 5, plus how the number is collected |
| ★ Incumbents & alternatives | the tools found, the cost of switching, why extending one loses |
| Product & distribution | who adopts or pays, how they find it, licence and hosting model, a pricing guess — or "internal tool only", said explicitly |
| ★ Domain model | the main entities, how each is created, changed, expired and deleted, where the data comes from, stale or conflicting data, volumes |
| ★ Interface contract | the protocol and shape of the API, its clients, how versions stay compatible |
| Quality attributes | latency, availability, durability, cost per operation, each with a target number |
| ★ Security & abuse | authentication, authorization, tenants, personal data, retention and deletion, hostile input on every write |
| Operations | hosting, deployment, backup and restore, monitoring, upgrades and migrations |
| ★ Evaluation | how quality gets measured the same way every time; anything that ranks, retrieves or generates needs a scored evaluation set, not tests alone |
| Technical unknowns | what thinking cannot settle and needs a time-boxed spike |

## Pre-mortem
Once the draft brief exists, hand it to a fresh subagent through the `Agent` tool. It works in a fresh context and receives only the draft: none of the conversation, none of your reasoning. Ask it to imagine the project abandoned eighteen months from now and, speaking in turn as a doubtful investor, a senior engineer and a security reviewer, to rank the most likely causes, each tied to a sentence or a gap of the brief, then to name the three questions the author steered around.

Bring each finding to the user, one per message. Each one ends as:
- `accepted` — it becomes a requirement, a non-goal or a named risk;
- `refuted` — the user's reasoning is recorded next to it;
- `spike` — a time-boxed investigation, listed under open risks and spikes.

## Alternatives
Lay out at least three approaches, each with its effort, its risk and what it gives up. One of them is always the cheapest: extend what already exists, or do less. Recommend one and say why; the user chooses. The chosen approach and the ones turned down go into the brief's alternatives table.

## Exit criteria
The interview stops when all of these hold, and not earlier:
- a one-liner a stranger understands;
- the wedge;
- the success metric;
- at least three non-goals;
- every critical dimension (★) marked `answered`, `defaulted` or `open risk` with a way to retire it;
- every pre-mortem finding settled as `accepted`, `refuted` or `spike`;
- the user's explicit agreement after reading the whole brief.
