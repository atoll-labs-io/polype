---
track: flow
validated: yes
---
# Plan (short track) — s68-docs-catch-up

[Story](../stories.md)

Written by the planner on the short track (`Story track: auto`, complexity 1 ≤ `Flow threshold: 2`). This file stands in for both the research and the plan: there is no `docs/research/s68-docs-catch-up.md`.

## Verified facts
No assumption of the story proved false. Complexity scored after reading: **1** (two prose edits, one test file).

**README — the pre-commit sentence is stale**
- `README.md:35` says only: "Un hook de pre-commit refuse un commit de code sur une branche de story dont le plan n'est pas validé." Nothing on secrets.
- The real hook: `method/hooks/pre-commit:4` only `exec`s `po-gate.sh pre-commit`.
- `method/hooks/po-gate.sh:227-233` (`pre_commit`) runs `secret_scan` first and refuses on any hit, **before** reading the branch; only then `po-gate.sh:234-235` returns 0 for a branch outside `story/*`. So the secret refusal holds on every branch, the plan refusal only on `story/<id>` (`po-gate.sh:236-244`, docs-only commits pass).
- What `secret_scan` refuses: a staged `.env` / `.env.*` other than `.env.example` (`po-gate.sh:165-170`), and an added line matching a private-key header, an AWS access key, a GitHub token, a Stripe secret key or an Anthropic key (`po-gate.sh:152-157`). Values are never printed (`po-gate.sh:159`, `:232`).
- The gate's own header states the rule: "on every branch, when a staged environment file or an added line holding a private key or a known token is staged" (`po-gate.sh:11-13`).
- Source of the finding: `docs/reviews/s49-secret-scan.md:73`.

**Parity matrix — H04 is stale**
- `docs/parite-killer-saas.md:106`, H04: Polype column "Identique par défaut, réglable par story", status "partiel — `method/agents/` ; le réglage de modèle par story manque encore". Both false now.
- The rule today (ADR-0032, `docs/decisions/ADR-0032-modele-choisi-selon-la-complexite.md:23`): planner, designer, reviewer, qa and stories-reviewer get `Model strong`; the implementer gets `Model light` up to `Light up to`, `Model strong` above.
- Where it lives: `method/commands/po-execute.md:33-35` (`## Model`, complexity read from the research, else the story, else strong); `method/commands/po-drive.md:101` (deciding roles on `Model strong` whatever the complexity); `method/commands/po-review.md:29`, `po-qa.md:31`, `po-stories-review.md:29`; settings in `method/templates/agents-local.md:34-36,65-67`. Every agent file now has `model: inherit` (`method/agents/*.md:5`) — nothing is pinned in `method/agents/` any more.
- Known limit (ADR-0036, `docs/decisions/ADR-0036-…:22`): a plan or design written by a command in its own context (`/po-plan`, `/po-flow`, `/po-orchestrator`, `/po-design`) runs on the session's model; only `/po-drive` passes `Model strong` to the planner and designer.
- Source of the finding: `docs/reviews/s59-model-by-complexity.md:80-82`.
- The Killer SaaS column of H04 ("implémenteur épinglé sur le modèle le plus fort …") describes Killer SaaS, not Polype: it stays.

**The test that pins the stale text**
- `tests/distribution-wiring.test.sh:134-136` require H04 to contain `partiel`, `method/agents/` and `par story` — exactly the stale claims. This story changes that clause, so these three lines change (AGENTS.local.md convention: change an existing test only when the story changes its clause).
- `status_of` (`tests/distribution-wiring.test.sh:13`) reads the last cell by splitting on `|`: the new cells must hold no `|`.
- `test_readme_describes_the_project_and_its_install` (`:58-109`) resolves every backticked `docs/`, `method/`, `bin/`, `tests/` token of the README and every `/po-*` it names: any path added to the README must exist.
- Other tests reading these files: `tests/qa-fleet.test.sh:99-105` (README cycle table and QA sentence, untouched here); `catalogue-wiring` and `fleet-wiring` read the matrix but not H04 (grep `H04` in `tests/` hits only `distribution-wiring.test.sh`).
- Tests are bash, helpers in `tests/lib.sh` (`contains` exact and case-sensitive, `fail`); focused run: `bash tests/run.sh distribution-wiring.test.sh`.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, `docs/stories.md:1042-1052` | absent — only `README.md` and `docs/parite-killer-saas.md` prose change |
| New screen | absent — story text | absent — no UI in this repository |
| Authorization or tenant scope | absent — story text | absent — `po-gate.sh` is read, not changed |
| API contract | absent — story text | absent — no command, agent or template under `method/` changes |
| New dependency | absent — story text | absent — bash test only, `tests/lib.sh` helpers |

## Story
s68-docs-catch-up — La documentation rattrape la méthode. Owns: `README.md`, `docs/parite-killer-saas.md`, `tests/distribution-wiring.test.sh`.
- `readme_describes_the_pre_commit` — le README dit que le pre-commit refuse aussi les secrets, sur toutes les branches.
- `parity_h04_matches_the_model_rule` — la ligne H04 dit que les rôles qui décident tournent sur `Model strong` et que l'implementer s'adapte à la complexité, avec son statut.

## Tasks

1. [x] **README pre-commit sentence.** Replace the sentence at `README.md:35` (keep the rest of the paragraph and the three gates sentence before it word for word — `test_readme_describes_the_project_and_its_install` quotes them) with, in French:
   « Un hook de pre-commit refuse, sur toutes les branches, un commit qui ajoute un secret — fichier d'environnement, clé privée ou jeton connu — et, sur une branche de story, un commit de code dont le plan n'est pas validé. »
   No new backticked path unless it exists. Test that fails if wrong: `test_readme_describes_the_pre_commit` (task 3).
2. [x] **H04 row.** At `docs/parite-killer-saas.md:106`, keep `H04`, the Killer SaaS column, `agents` and `Étendre`. Polype column becomes, in French: les rôles qui décident (planner, designer, reviewer, QA, relecture des stories) tournent sur `Model strong` ; l'implementer prend `Model light` jusqu'à `Light up to`, `Model strong` au-delà, selon la complexité de la story (ADR-0032) ; hors flotte, ce qu'une commande écrit dans son propre contexte tourne sur le modèle de la session (ADR-0036). Status becomes: fait — then the three paths `method/commands/po-execute.md`, `method/commands/po-drive.md`, `method/templates/agents-local.md`, each backticked (no `|` in either cell). Test: `test_parity_h04_matches_the_model_rule` (task 3).
3. [x] **Tests in `tests/distribution-wiring.test.sh`.**
   - Delete lines 134-136 (the H04 `partiel` / `method/agents/` / `par story` checks) and the comment wording that calls H04 partial; the loop at `:115` keeps checking H04 has a readable status. Say so in the commit message.
   - Add `test_readme_describes_the_pre_commit`: `contains` on the README for `refuse, sur toutes les branches`, `fichier d'environnement, clé privée ou jeton connu`, and `un commit de code dont le plan n'est pas validé`; anchor the claim to the gate with `contains "$METHOD/hooks/po-gate.sh" 'on every branch'`; and `! grep -qF "Un hook de pre-commit refuse un commit de code" "$README" || fail …` so the old narrow sentence cannot return.
   - Add `test_parity_h04_matches_the_model_rule`: a helper `polype_of` (awk, `$5` of the H04 row, same shape as `status_of`) and assertions — Polype cell contains `` `Model strong` ``, `` `Model light` ``, `complexité`, `ADR-0032`, and lacks `Identique`; status contains `fait` and `method/commands/po-execute.md`, and lacks `partiel`.
   Run `bash tests/run.sh distribution-wiring.test.sh` — all four functions plus the two new ones green.
4. [x] **Full suite once**, through `po-run` as `/po-execute` says (`Test: bash tests/run.sh`); `overlap.test.sh` stays green (it scans `method/` only, untouched here).

## Run interdicts
- `git diff main...story/s68-docs-catch-up --stat` lists only `README.md`, `docs/parite-killer-saas.md`, `tests/distribution-wiring.test.sh` and this story's `docs/plans/`, `docs/verif/`, `docs/reviews/` files.
- Empty diff for everything under `method/`, `.claude/`, `.polype/`, `bin/`, and every other `tests/*.test.sh`.
- In `docs/parite-killer-saas.md`, only line H04 changes (`git diff -U0` shows one removed and one added line); its Killer SaaS column is byte-identical.
- In `README.md`, only the pre-commit sentence of the paragraph at line 35 changes; the cycle table rows checked by `tests/qa-fleet.test.sh:99-105` are untouched.
- No ADR is written: this story documents existing decisions (ADR-0028, ADR-0032, ADR-0036).
- Other stale lines of the matrix or the README are out of scope, even if seen.

## Files touched
`README.md`, `docs/parite-killer-saas.md`, `tests/distribution-wiring.test.sh`, plus `docs/plans/s68-docs-catch-up.md` and `docs/verif/s68-docs-catch-up.md`.

## The pivot
H04 goes to `fait`, not `partiel`. The original gap ("le réglage de modèle par story manque encore") is closed by a different mechanism — the model follows the story's complexity (ADR-0032) rather than a per-story knob. The remaining limit, a plan written in a command's own context running on the session's model (ADR-0036), is a deliberate, recorded choice, so it is stated in the Polype column rather than kept as a "partial" status. How this could be wrong: a reader may hold that an unenforceable `Model strong` outside `/po-drive` keeps H04 partial. If the reviewer argues so, the fix is the status word plus one assertion, nothing structural.

## Test strategy
Two new tests and three deleted assertions, all in `tests/distribution-wiring.test.sh`, well within `Test budget: 25`. Layer: the documents are the product here, so the tests read them, quoting exact phrases, as every `*-wiring.test.sh` does. Bite: reverting `README.md:35` fails `readme_describes_the_pre_commit` (both the positive phrases and the negative check); reverting H04 fails `parity_h04_matches_the_model_rule` on `fait`, `Model strong` and `Identique`. The `po-gate.sh 'on every branch'` assertion ties the README claim to the gate's stated rule so a change in the gate surfaces here.

## Done when
One commit on `story/s68-docs-catch-up` with the three files and this story's docs; `bash tests/run.sh` green; a review with no open critical finding; squash on `main` titled `s68-docs-catch-up: La documentation rattrape la méthode`. Nothing deploys.
