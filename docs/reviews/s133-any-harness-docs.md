# Review — s133-any-harness-docs

[Story](../stories.md) · [Plan](../plans/s133-any-harness-docs.md) · [Verification](../verif/s133-any-harness-docs.md)

Diff reviewed: `git diff main...story/s133-any-harness-docs`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 00f54b594dbf9df5d9ecbdd584a238c722b447dd

## When blocked
Not blocked. The tree was taken again just before this answer and had not changed (`00f54b594dbf9df5d9ecbdd584a238c722b447dd`). The worktree is clean.

## Ownership
I listed the diff with `git diff --name-status main...story/s133-any-harness-docs` and held each path against the story's `Owns`. The `Owns` line is: `README.md`, `docs/installation.md`, `method/commands/po-help.md`, `docs/parite-killer-saas.md`, `.github/ISSUE_TEMPLATE/`, `tests/any-harness-docs.test.sh`.
- [x] Every path is inside `Owns`:
  - `README.md`, `docs/installation.md`, `docs/parite-killer-saas.md`, `method/commands/po-help.md` and `tests/any-harness-docs.test.sh` each match a file entry.
  - `.github/ISSUE_TEMPLATE/harness-support.md` sits under the folder entry.
  - `docs/plans/s133-any-harness-docs.md` and `docs/verif/s133-any-harness-docs.md` are the story's own pipeline evidence. There is no research file because this is the short track.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. No other story owns these paths.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s133-any-harness-docs` → exit 0, record reused (`Verification mode: record`).
  - The last `Unit suite` row (`bash tests/run.sh`) exited 0 on code equal to the recorded `Tree:`.
  - The project has no type check command (`Typecheck: —`), so none was run.
  - The record's "Not proven here": "That another harness actually reads these docs' promise: none is claimed, Codex support is deferred (ADR-0005)." Noted.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] All six tasks are present and match the plan text:
  - the README hook line and the `## Pour quel agent` section;
  - the issue template;
  - the paragraph in `docs/installation.md`;
  - the po-help line;
  - the H03 cell;
  - the test file.
- [x] Nothing outside the plan.
- [x] Run interdicts, one by one:
  - `method/AGENTS.md`, `docs/conception.md`, `bin/polype`, `method/hooks/` and the ADRs: not in the diff.
  - `.claude/` and `.polype/`: untouched.
  - Existing tests: none changed.
  - `docs/parite-killer-saas.md`: only the last cell of row H03 changed.
  - README `## Démarrage rapide` and `## Ce que Polype fait de ta configuration`: untouched, and the new section has no fenced block.
  - Dates: no Codex date and no `mi-octobre` in the three files.
  - Forge: no issue and no label created.

## References
- [x] The README link `.github/ISSUE_TEMPLATE/harness-support.md` points to a file that exists.
  - The template has the `name:` and `about:` frontmatter GitHub needs (plus `title:`).
  - `ADR-0005` exists, and its Neutral consequence names exactly the three portable parts the README lists.
  - `PreToolUse`, `SessionStart`, `AskUserQuestion` and `~/.claude/` were confirmed in the plan's verified facts. I relied on those facts and did not reopen each file.
- [x] No value that only looks right. The "sans date" wording follows the story notes, which ask that the ADR-0005 date not be repeated.

## Rules
- [x] `AGENTS.md` conventions respected:
  - documentation is in French and the test in English;
  - the overlap test passes (full suite in the record);
  - the H03 cell keeps `partiel`, `method/` and `ADR-0005`.
- [x] No accepted ADR contradicted. Leaving out the ADR-0005 date was decided in the story, not by the implementer.

## Tests
- [x] Floor: `po-gate floor-guard s133-any-harness-docs main` → 0, nothing lowered.
- [x] The assertions pin down the three acceptance criteria. None of the six empty test shapes: the tests read the real files, with no fixture or mock.
  - The test can only check that terms are named, not that the prose makes no false claim. I did that check by hand; it is below.
- [x] Three tests, within `Test budget: 25`.
- [x] Bite, each mutation undone and checked with `git diff --exit-code`, which came back clean every time:
  - Removing the README line "Demande Claude Code aujourd'hui …" → 1 failing test (`portable_and_specific_parts_are_named`: "lacks: subagents").
  - Changing `prévu ensuite : Codex` to `prévu ensuite :` in `po-help.md` → 1 failing test (`docs_name_any_harness`).
  - Pointing the README link to `.github/ISSUE_TEMPLATE/harness.md` → 1 failing test (`harness_issue_template_exists`: "issue template missing").
- [x] The story made no test useless.

## Neighbours
- [x] Other tests hold phrases of the README, `docs/installation.md` and `po-help.md`: `distribution-wiring`, `readme-onboarding`, `hooks-installer-docs-cleanup` and `overlap`. They pass as part of the recorded full suite on this code. The README `Prérequis` (`README.md:53`, Claude Code required) is consistent with the new section.

## Lenses
Lenses run: none (the diff is markdown and one bash document test, with no auth, migration, dependency or server-side path or content).

## Findings
Reading by hand, as a user of another harness would, sentence by sentence. Nothing in the three files claims that Polype already works outside Claude Code:
- The README section says outright that the portable parts are "une intention de conception et non une promesse que cela tourne ailleurs".
- The README says Codex is "prévu ensuite … sans date".
- `docs/installation.md` says "Les poses ci-dessous sont celles de Claude Code".

What remains are wording ambiguities, all minor:

- minor — `README.md:3` — the hook line ends "pensée pour tout agent ou harness, … ; Claude Code d'abord". Read alone, for example on the repository card, "Claude Code d'abord" can mean "Claude Code is the preferred one among those that work", not "the only one supported today". The section ten lines below settles it. The hook could say "seul Claude Code pour l'instant", or something like it.
- minor — `README.md:13`, `docs/installation.md:16` — "Polype vise tout agent ou harness, pris en charge aujourd'hui : Claude Code". After a comma, "pris en charge aujourd'hui" can first be read as describing "tout agent ou harness" ("any harness, supported today") until the colon resolves it. `po-help.md:13` uses a semicolon there and reads clearly. The comma is a side effect of fitting the fixed test phrase; a semicolon or full stop would keep the phrase and lose the ambiguity.
- minor — `docs/installation.md:17` — "Pour un autre outil, il faut ouvrir une issue." The sentence names neither the repository (`atoll-labs-io/polype`) nor the request template. Someone who lands on this page alone does not know where to open it.
- minor — `docs/parite-killer-saas.md:105` — "et une issue demande un autre harness (s133)" can be read as "an issue (already) asks for another harness". The meaning is that an issue template lets someone ask. "un modèle d'issue permet de demander" would be exact.
- minor — `method/commands/po-help.md:13` — the line does not cite `ADR-0005` after Codex, while the story's first criterion writes "Codex (ADR-0005)" for all three files. The plan deliberately requires `ADR-0005` only in the README and `docs/installation.md`, so the diff matches the plan. This is noted only as a gap against a literal reading of the story.

## Not verified
- **How GitHub shows the template.** I did not check that `.github/ISSUE_TEMPLATE/harness-support.md` appears in the "New issue" chooser on `atoll-labs-io/polype`: it only takes effect once it is on the default branch, and the review does not reach the forge. After ship, a person should open "New issue" on the repository and confirm the "Prise en charge d'un harness" entry and its body.
- **How the README renders.** I did not check the rendered README on GitHub (the relative link and the section placement). Verified only as text and by the test. A person should click the "modèle de demande" link on the repository page after ship.
- **Whether the "Demande Claude Code aujourd'hui" list is complete.** I did not check this against every Claude Code-specific mechanism. For example, the `Model strong`/`Model light` model names and the slash-command format of `~/.claude/commands/` are not listed (the second is covered only indirectly by "la pose dans `~/.claude/`"). The story's criterion names only the four items given, so this is not a finding. A person preparing the Codex port should draw up the full table of what degrades (H03, deferred).
- **No other harness was run.** The "portable by design" claim is stated as an intent and not tested.
- **The rest of the suite was not rerun.** The full unit suite was reused from the record, not rerun here. Only `any-harness-docs.test.sh` was run, during the bite proofs.

Max severity: minor
Ship allowed: yes

---

# Review — s133-any-harness-docs

[Story](../stories.md) · [Plan](../plans/s133-any-harness-docs.md) · [Verification](../verif/s133-any-harness-docs.md)

I reviewed `git diff main...story/s133-any-harness-docs` in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: add8c802a8238e799cb8e8ae1ff89ad67bad7184

## When blocked
The review is not blocked. I took the tree again just before answering and it was still `add8c802a8238e799cb8e8ae1ff89ad67bad7184`. The worktree is clean (`git status --porcelain` is empty).

## Ownership
The `Owns` line is: `README.md`, `docs/installation.md`, `method/commands/po-help.md`, `docs/parite-killer-saas.md`, `.github/ISSUE_TEMPLATE/`, `tests/any-harness-docs.test.sh`.
- [x] Every path in the diff is inside `Owns`:
  - `README.md`, `docs/installation.md`, `docs/parite-killer-saas.md`, `method/commands/po-help.md` and `tests/any-harness-docs.test.sh` each match a file entry.
  - `.github/ISSUE_TEMPLATE/harness-support.md` is under the folder entry.
  - `docs/plans/`, `docs/verif/` and `docs/reviews/s133-any-harness-docs.md` are the story's own evidence.
  - There is no research file because the story came through the short track.
- [x] Fix commit 22643fa touches only README.md, docs/installation.md, docs/parite-killer-saas.md, method/commands/po-help.md and the story's verif and review files.
- [x] Nothing is inside another running story's `Owns`. `git worktree list` shows only this story's worktree.

## Evidence reused
- [x] `po-gate verif-current s133-any-harness-docs` → exit 0 (`Verification mode: record`).
  - The record's `Tree: 71bf96f…` matches HEAD outside `docs/` (`git diff --quiet` → 0).
  - The last `Unit suite` row (`bash tests/run.sh`, tree `fb654c8…`, exit 0) also matches HEAD outside `docs/`.
  - The project has no type check (`Typecheck: —`), so none was run.
  - The record's "Not proven here" says another harness was never run. Noted.
- [x] QA is not required: `QA stage: —`.

## Plan
- [x] The fix commit answers each of the five loop-0 minors and changes nothing else:
  1. README hook line (`README.md:3`): "Claude Code d'abord" became "seul Claude Code est pris en charge pour l'instant". Read alone, for example on the repository card, it now says plainly that only Claude Code works today.
  2. Comma ambiguity (`README.md:13`, `docs/installation.md:16`): both now use "Polype vise tout agent ou harness ; pris en charge aujourd'hui : Claude Code ; …", the same pattern as po-help. "Supported today" can no longer be read as describing "any harness".
  3. Where to ask (`docs/installation.md:17-18`): the sentence now names `atoll-labs-io/polype` and the template `.github/ISSUE_TEMPLATE/harness-support.md`.
  4. H03 cell (`docs/parite-killer-saas.md:105`): it now says "un modèle d'issue permet de demander un autre harness (s133)". It still says `partiel`.
  5. po-help (`method/commands/po-help.md:13`): it now cites "Codex (ADR-0005 de Polype)". The "de Polype" is right for an installed cheat sheet: it is read inside a user's project, which has its own ADR numbering.
- [x] The run interdicts still hold:
  - no "mi-octobre" and no Codex date;
  - `method/AGENTS.md`, `docs/conception.md`, `.claude/` and `.polype/` are untouched;
  - no existing test was changed;
  - the new prose lines in `docs/installation.md` are 94, 78 and 93 characters, all under 100.

## References
- [x] `docs/decisions/ADR-0005-codex-differe.md` exists.
- [x] `.github/ISSUE_TEMPLATE/harness-support.md` exists, and the path quoted in `docs/installation.md` is exact.
- [x] The README link resolves (checked by test and by hand).

## Tests
- [x] Floor: `po-gate floor-guard s133-any-harness-docs main` → 0.
- [x] There are 3 tests, within `Test budget: 25`. They read the real files, with no fixture or mock.
- [x] Bite proofs. After each mutation I ran only `any-harness-docs.test.sh`, then undid the change. `git diff --exit-code` was clean each time, and `git status` was clean at the end.
  - I removed "pris en charge aujourd'hui : Claude Code ; " from `README.md:13`. 1 test failed (`docs_name_any_harness`: "README.md lacks: pris en charge aujourd'hui : Claude Code").
  - I removed "(ADR-0005)" from `docs/installation.md:17`. 1 test failed (`docs_name_any_harness`: "docs/installation.md lacks ADR-0005").
- [x] Unchanged code passes: 3 passed, 0 failed.

## Neighbours
- [x] The other tests that quote these files (`readme-onboarding`, `distribution-wiring`, `hooks-installer-docs-cleanup`, `overlap`) pass in the recorded full suite on this exact code.
- [x] No test asserts the old phrase "Claude Code d'abord". The only "d'abord" match is an unrelated negative assertion in `readme-onboarding.test.sh:150`.
- [x] `README.md:53` (Prérequis: Claude Code) is consistent with the new hook line.

## Lenses
Lenses run: none. The diff is markdown plus one bash document test: no auth, migration, dependency or server-side path or content.

## Findings
I reread every changed sentence as someone who uses another harness would. None of them claims that Polype runs outside Claude Code today. Each says what is supported now, what comes next without a date, and where to ask. One minor finding remains:

- minor — `README.md:13`, `docs/installation.md:17` — "ADR-0005" appears as plain text with no link to `docs/decisions/ADR-0005-codex-differe.md`. A reader on GitHub sees a number they cannot follow.

## Not verified
- **How GitHub shows the template.** The template only appears in the "New issue" chooser on `atoll-labs-io/polype` once it is on the default branch. After ship, a person should open "New issue" and check that the entry "Prise en charge d'un harness" is there with its body.
- **How the README renders.** I checked the README only as text and through the test. After ship, a person should click the "modèle de demande" link on the repository page.
- **Whether the "Demande Claude Code aujourd'hui" list is complete.** I did not check it against every Claude Code-specific mechanism (for example the model names, or the slash-command format). The story names only four items. Whoever prepares the Codex port should draw up the full table of what degrades (H03, deferred).
- **No other harness was run.** The "conçu pour se porter" claim is stated as an intent and was not tested.
- **The full suite was not rerun.** I reused it from the record. I ran only `any-harness-docs.test.sh`, for the bite proofs.

Max severity: minor
Ship allowed: yes
