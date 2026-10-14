---
track: flow
validated: yes
---
# Plan (short track) — s133-any-harness-docs

[Story](../stories.md)

Written on the short track (`Story track: auto`, complexity 2 ≤ `Flow threshold: 2`). This one file
stands in for both the research and the plan: there is no `docs/research/s133-any-harness-docs.md`.

## Verified facts
No assumption of the story proved false. Checked on `story/s133-any-harness-docs` at `c8fbad9`.

- `README.md:3` — the hook line reads « portée par des agents Claude Code encadrés par des gates
  mécaniques » : it holds both formulas the story bans. `tests/distribution-wiring.test.sh:62`
  requires `Une méthode de dev agentique` to stay in the README: keep that phrase in the new hook.
- `README.md:45` — `## Prérequis` lists Claude Code; `tests/readme-onboarding.test.sh:66` requires
  `Claude Code` there. Keep it.
- `tests/readme-onboarding.test.sh:73-99` parses `## Démarrage rapide` and expects exactly the
  fenced blocks `sh, sh, text, sh`; `:127-139` parses `## Ce que Polype fait de ta configuration`.
  The new README text goes in a section of its own, outside both, with no fenced block.
- `tests/distribution-wiring.test.sh:87-98` — every backticked README token or link target starting
  `docs/`, `method/`, `bin/` or `tests/` must exist. A `.github/…` link is not checked there; the
  new test checks it.
- No harness or Codex word in `README.md`, `docs/installation.md`, `method/commands/po-help.md` today
  (grep `Codex\|harness`: no hit). No `.github/` at the worktree root (`ls -a`), as the story says.
- `docs/installation.md:8-14` — the paragraph holding « ceux qu'il trouve (ADR-0086) », read as one
  blank-line-separated paragraph by `tests/readme-onboarding.test.sh:151`: a new paragraph must not
  merge into it. `tests/hooks-installer-docs-cleanup.test.sh:109` refuses prose lines over 100
  characters in that file (code fences excepted).
- `method/commands/po-help.md:9-11` — two intro lines before `## Installation` (`:13`), which must
  stay before `## Mise en place` (`tests/distribution-wiring.test.sh:50-55`). `po-help.md` is under
  `method/`, so `tests/overlap.test.sh` applies: own words only.
- `docs/parite-killer-saas.md:105` — H03 status cell: « partiel — `method/` est la source unique ;
  émission Codex et tableau de dégradation différés (ADR-0005) ». `tests/distribution-wiring.test.sh:
  131-133` requires `partiel`, `method/`, `ADR-0005` in it; `status_of` (`:13`) reads the last column.
  Only that cell changes: the « Codex vers mi-octobre » text of the target column is not this
  story's line to rewrite.
- `docs/decisions/ADR-0005-codex-differe.md` — accepted; its Neutral consequence names exactly the
  portable parts: rules in `AGENTS.md`, skills as `SKILL.md`, gates as shell scripts on markdown.
- Claude Code-specific parts, opened: `PreToolUse` in `method/agents/implementer.md:9`; the
  `SessionStart` merge in `bin/polype:433-435`; `AskUserQuestion` in the frontmatter of
  `method/commands/po-plan.md` and others; the global pose into `~/.claude/`
  (`docs/installation.md:38-48`). Portable parts: `method/skills/*/SKILL.md` (11 files),
  `method/hooks/po-gate.sh`, `po-run.sh`, `po-bounds.sh` and the git hook `method/hooks/pre-commit`.
- `method/hooks/po-bounds.sh:204-240` accepts the Owns entry `.github/ISSUE_TEMPLATE/` (a `.github`
  segment is neither `.` nor `..`), so the implementer may write there.
- A GitHub markdown issue template needs `name:` and `about:` in its frontmatter to show in the
  chooser; labels are left out, since no `harness` label is known to exist on the repository.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, Owns are docs and a test | absent — no schema or data anywhere in Owns |
| New screen | absent — `Surface: command` | absent — markdown and a bash test only |
| Authorization or tenant scope | absent — story text | absent — nothing in Owns touches bounds or gates |
| API contract | absent — story text | absent — `bin/polype`, hooks untouched |
| New dependency | absent — story text | absent — the test uses `tests/lib.sh` helpers only |
| Technical choice that deserves an ADR | absent — story text | absent — template format is a detail (markdown, see Reuse); ADR-0005 already decides Codex |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no such line in the story | absent |

QA: `QA stage: —`, no story goes to QA. Six tasks.

## Story
A user of another agent than Claude Code learns at once that Polype aims at any agent or harness,
which one is supported today, which comes next, and how to ask for theirs.
- `docs_name_any_harness` — README (hook included), `docs/installation.md` and `/po-help` say: any
  agent or harness; supported today, Claude Code; planned next, Codex (ADR-0005), no date; another
  one, open an issue. The two Claude-Code-only formulas are refused in all three files.
- `portable_and_specific_parts_are_named` — the README names what was built to port and what needs
  Claude Code today, without claiming it works elsewhere; the H03 cell says what the story delivers.
- `harness_issue_template_exists` — `.github/ISSUE_TEMPLATE/` holds a harness-support template
  (tool name, version, sub-agents, hooks, reading `AGENTS.md`), linked from the README relatively.

## Reuse
No new code but one test file; it reuses `contains`, `require_file`, `fail` of `tests/lib.sh` and the
`status_of` awk idiom of `tests/distribution-wiring.test.sh:13` (copied into the new file, since test
files do not source each other). The issue template is plain markdown with frontmatter (GitHub's
built-in format), not a YAML issue form: nothing to parse, and grep reads it.

## Tasks
Fixed phrases, written with plain spaces exactly as below, so the test can hold them in all three files:
`tout agent ou harness` · `pris en charge aujourd'hui : Claude Code` · `prévu ensuite : Codex` ·
`ouvrir une issue`. Never write `mi-octobre` or any date for Codex.

1. [x] **README** — rewrite the hook (`README.md:3`), keeping `Une méthode de dev agentique` and
   dropping both banned formulas, so it says Polype is for any agent or harness, Claude Code today.
   Add a section `## Pour quel agent` between `**Statut**` (`:9`) and `## Trois points d'entrée`
   holding the four fixed phrases, `ADR-0005` after Codex, then a few lines: built to port — the
   rules in `AGENTS.md`, the skills in the `SKILL.md` format, the gates as shell scripts and git
   hooks — said as a design intent, not as working elsewhere; needs Claude Code today — the
   subagents, the `PreToolUse` and `SessionStart` hooks, `AskUserQuestion`, the pose in
   `~/.claude/`. End with a relative link `(.github/ISSUE_TEMPLATE/harness-support.md)` to open the
   issue. No fenced block. Test: `test_docs_name_any_harness`, `test_portable_and_specific_parts_are_named`.
2. [x] **Issue template** — create `.github/ISSUE_TEMPLATE/harness-support.md`, French, frontmatter
   `name: Prise en charge d'un harness`, an `about:` line and a `title:` prefix; body asks for the
   tool's name, its version, and what it can do: sous-agents, hooks, lecture d'`AGENTS.md`. Test:
   `test_harness_issue_template_exists`.
3. [x] **docs/installation.md** — a new paragraph after the one ending « (ADR-0089). » (`:14`),
   separated by blank lines, holding the four fixed phrases and `ADR-0005`; it may say that the
   installer's poses below are Claude Code's. Prose lines ≤ 100 characters. The existing sentences on
   Claude Code behaviour (`:12`, `:39`, `:122`, `:208`) stay as they are. Test:
   `test_docs_name_any_harness`, plus the existing 100-character check.
4. [x] **po-help** — one line after `:11`, before `## Installation`, holding the four fixed phrases
   and naming where to open the issue (`atoll-labs-io/polype`). Own words (overlap test). Test:
   `test_docs_name_any_harness`.
5. [x] **Parity H03** — status cell only becomes: `partiel — `method/` est la source unique ; le
   `README.md` dit ce qui se porte et ce qui demande Claude Code, et une issue demande un autre
   harness (s133) ; émission Codex et tableau de dégradation différés (ADR-0005)`. Test:
   `test_portable_and_specific_parts_are_named`, and the existing H03 checks.
6. [x] **Test** — `tests/any-harness-docs.test.sh`, three functions named after the criteria:
   - `test_docs_name_any_harness`: for each of the three files, join lines and squeeze whitespace
     (`tr -s '[:space:]' ' '`), require the four fixed phrases; require `ADR-0005` in README and
     installation.md; refuse `portée par des agents Claude Code`, `agents Claude Code encadrés` and
     `mi-octobre`; require the README hook line (line 3, `> …`) to hold `tout agent ou harness`.
   - `test_portable_and_specific_parts_are_named`: in the `## Pour quel agent` section, require
     `AGENTS.md`, `SKILL.md`, `scripts shell`, `hooks git`, `subagents`, `PreToolUse`,
     `SessionStart`, `AskUserQuestion`, `~/.claude/`; H03 status cell holds `partiel` and `README.md`.
   - `test_harness_issue_template_exists`: the README link target containing `ISSUE_TEMPLATE` is
     relative (no `http`) and `[ -f "$ROOT/<target>" ]`; that file's frontmatter has `name:` holding
     `harness` and an `about:` line; its body holds `version`, `sous-agents`, `hooks`, `AGENTS.md`.
   Run `bash tests/run.sh any-harness-docs.test.sh distribution-wiring.test.sh
   readme-onboarding.test.sh hooks-installer-docs-cleanup.test.sh docs-and-eval-cleanup.test.sh
   overlap.test.sh pilot.test.sh`, then the full suite through `po-run` once.

## Scene viewpoints
—

## Run interdicts
- `method/AGENTS.md`, `docs/conception.md`, `bin/polype`, `method/hooks/`, every ADR: empty diff.
- `.claude/` and `.polype/` (installed copies): never edited.
- No existing test file changed; in particular the phrases held by `tests/distribution-wiring.test.sh`
  and `tests/readme-onboarding.test.sh` stay true.
- `docs/parite-killer-saas.md`: only the last cell of row H03 changes.
- `## Démarrage rapide` and `## Ce que Polype fait de ta configuration` of the README: unchanged.
- No promise beyond the code: no Codex date, no « fonctionne déjà » / works-elsewhere claim, no Codex
  porting work. No issue opened, no label created on the forge.

## Files touched
`README.md`, `.github/ISSUE_TEMPLATE/harness-support.md` (new), `docs/installation.md`,
`method/commands/po-help.md`, `docs/parite-killer-saas.md`, `tests/any-harness-docs.test.sh` (new).

## The pivot
Everything hangs on the four fixed phrases being written identically in three files of different
shapes (a hook line, wrapped prose under 100 characters, a one-line help bullet). Wrong if wrapping
splits a phrase or a typographic non-breaking space slips in before a colon: the whitespace-squeezing
join handles line breaks, not U+00A0, hence « plain spaces » above.

## Test strategy
Three bash tests at the document layer, one per criterion, well within `Test budget: 25`. Each
would fail if its rule were removed: deleting the README section, the phrase in any one file, the
template file or the link, or the H03 mention flips a check. Existing tests guard what must survive
(README phrases, H03 `partiel`/`ADR-0005`, 100-character lines, overlap).

## Done when
The six tasks are ticked, the focused tests and the full suite pass, the review has no open critical
finding, and the story lands as one commit `s133-any-harness-docs: Polype se présente pour tout
harness, Claude Code d'abord` through a pull request.
