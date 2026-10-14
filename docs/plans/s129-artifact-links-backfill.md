---
track: flow
validated: yes
---
# Plan (short track) — s129-artifact-links-backfill

[Story](../stories.md)

Written by the `planner` subagent on the short track. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s129-artifact-links-backfill.md`. Validated autonomously (`Plan validation: autonomous`): no human reviewed this plan.

## Verified facts
- **No assumption of the story proved false.** `docs/qa/` does not exist in this repository: no QA report exists yet, so the script handles `docs/qa/<id>/report.md` but the backfill touches none.
- The lines to write are the six of s128, under the first `# ` title: research `[Story](../stories.md)`; plan `[Story](../stories.md) · [Research](../research/<id>.md)`; plan-flow `[Story](../stories.md)`; review `[Story](../stories.md) · [Plan](../plans/<id>.md) · [Verification](../verif/<id>.md)`; record `[Story](../stories.md) · [Plan](../plans/<id>.md)`; QA `[Story](../../stories.md) · [Plan](../../plans/<id>.md)` (`method/templates/research.md:3`, `plan.md:6`, `plan-flow.md:7`, `review.md:3`, `verification-record.md:3`, `qa.md:3`; held by `tests/artifact-link-templates.test.sh:9-18`). Each template's line is "the first non-blank line after the first title line" (`tests/artifact-link-templates.test.sh:22`).
- Template layout: title, blank, link line, blank, body (`method/templates/review.md:1-5`). s128's own fixture inserts it the same way (`tests/artifact-link-templates.test.sh:38-41`, `add_link`).
- Inventory, read in this worktree: 85 research, 117 plans (84 full, 33 with `track: flow` in their frontmatter, all titled `# Plan (short track)`), 117 story reviews, 117 records. Titles: research, reviews, records on line 1; plans on line 4 (full) or 5 (flow), after the frontmatter. In all 436 story files the line right after the title is blank, every file ends with a newline and none holds a CR: an awk rewrite changes no other byte.
- Pairings: every full plan has its research, no flow plan has one, every review has its plan and its record, every record its plan. One research has no plan: `docs/research/s117-eval-reuses-login.md`, a story set aside and removed from `docs/stories.md` (`docs/decisions-log.md:42`); its line `[Story](../stories.md)` still resolves, since the link has no anchor.
- Already linked: `docs/reviews/s128-artifact-link-templates.md:3` and `docs/verif/s128-artifact-link-templates.md:3`; `docs/plans/s128-artifact-link-templates.md` is not. This plan carries its line.
- Non-artefacts in these folders: `docs/reviews/stories-m6.md`, `stories-m8.md`, `stories-m8bis.md`, `stories-m9.md`, `stories-m9bis.md`, `triage-2026-10-14.md`; `docs/reviews/stories.md` is named by `method/commands/po-orchestrator.md:31`. A story id is `s<number>-<slug>` (`method/AGENTS.md`, "Ids and branches"): the glob `s[0-9]*-*` keeps all of them out.
- Readers by position, from s128's verified facts (`docs/plans/s128-artifact-link-templates.md`): frontmatter on line 1 (`method/hooks/po-gate.sh:29`), everything else by pattern or section. `po-gate` compares trees with `docs/` excluded (`method/hooks/po-gate.sh:61-62`, `:146`): editing docs changes no `Tree:` / `Reviewed tree:` result. The pre-commit lets a docs-only diff through without a plan check (`po-gate.sh:289-297`); its secret scan finds nothing in a link line.
- Bounds: the implementer may write anywhere under `docs/` (`method/hooks/po-bounds.sh:5`, `:188`), so a script run rewriting other stories' artefacts stays within bounds; `bin/po-link-artifacts` is in this story's `Owns`.
- `bin/` scripts are bash, `set -u`, with a usage comment and a default located from `$(dirname "$0")` (`bin/po-lint:1-13`). The global install copies all of `bin/` next to `method/` under `~/.claude/polype/` (`bin/polype:89-90`), so `$(dirname "$0")/../method/templates` resolves both in this repository and in the payload — which is how nautile and pecten will run it later.
- Tests call bin scripts as `bash "$ROOT/bin/<name>"` (`tests/lint.test.sh:28`); `scratch_repo` gives a throwaway git repo (`tests/lib.sh:52-59`); `gate_codes` (`tests/artifact-link-templates.test.sh:43-49`) is the pattern for "po-gate gives the same result".
- No story is in progress besides this one (driver's message): the gate comparison of `links_resolve_everywhere` is held on fixtures.

## Escalation signals
| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, `docs/stories.md:1999-2012` | absent — only markdown under `docs/` changes |
| New screen | absent — `Surface: —` | absent — a CLI script |
| Authorization or tenant scope | absent — story text | absent — `po-bounds.sh:188` already lets docs/ through |
| API contract | absent — story text | absent — no command or gate reads the line (s128 facts) |
| New dependency | absent — story text | absent — bash, awk, sed only, as `bin/po-lint` |
| Technical choice that deserves an ADR (library, pattern, data model) | absent — story text | absent — the line's form is settled by s128's templates; reading it from them is an implementation detail |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no `Corrige` line in s129 | absent |

## Story
As project owner I want the artefacts already in the repository to receive the same link line, so that old stories link up like new ones.
- `backfill_is_a_script` — `bin/po-link-artifacts` adds s128's line to each story artefact, only to files that exist, and changes nothing else in them; run again, it changes nothing.
- `existing_artifacts_backfilled` — every story artefact of `docs/research/`, `docs/plans/`, `docs/reviews/`, `docs/verif/` and `docs/qa/` carries the line; `docs/reviews/stories*.md` and `docs/reviews/triage-*.md` are untouched.
- `links_resolve_everywhere` — a test fails if a link of the line, in an existing artefact, points to a missing file, and `po-gate` gives the same result as before on the artefacts of in-progress stories, if any.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| The six link lines | already in this repository: read from `method/templates/<name>.md` with s128's rule (`tests/artifact-link-templates.test.sh:22`) | — no copy: a hard-coded list would drift from the templates |
| Insertion under the title | already in this repository: `add_link`'s awk (`tests/artifact-link-templates.test.sh:38-41`), plus a skip when the line is present | — it lives in a test file, which a bin script cannot source |
| Locating the method | already in this repository: `bin/po-lint:11` resolves `$(dirname "$0")/../method` | — |
| `bin/po-link-artifacts` itself | new code | no existing script walks `docs/` artefacts; bash/awk/sed suffice, no dependency |

## Tasks
1. [x] **Write `bin/po-link-artifacts`** (executable, bash, `set -u`, usage comment as `bin/po-lint:1-8`). `Usage: po-link-artifacts [repository root]`, default `.`; templates from `$(dirname "$0")/../method/templates`. It visits `docs/research/s[0-9]*-*.md`, `docs/plans/s[0-9]*-*.md`, `docs/reviews/s[0-9]*-*.md`, `docs/verif/s[0-9]*-*.md` and `docs/qa/s[0-9]*-*/report.md`. Template per file: research; plan-flow when the plan's frontmatter (line 1 `---` to the next `---`) holds `track: flow`, else plan; review; verification-record; qa. The line: the template's line with `<id>` replaced by the file's id, minus every `[Label](target)` whose target does not exist relative to the file's own directory, the ` · ` separators kept between the remaining ones. Skip, untouched: a file whose first non-blank line after its first `# ` title starts with `[Story](`; a file with no `# ` title; a line left with no link. Otherwise insert, right after the title, a blank line then the link line, keeping the original blank that follows (result: title, blank, link, blank, body, as the templates). Print one line per file changed; exit 0. Write through a temp file then `mv`, as `add_link`. — Test: `test_backfill_is_a_script` fails if any rule is removed (missing-target drop, flow detection, skip when linked, name glob).
2. [x] **Add `tests/artifact-links-backfill.test.sh`, `test_backfill_is_a_script`.** In a temp dir, fixtures under `docs/`: `stories.md`; s01-a full track (research, plan, record, review, `qa/s01-a/report.md`); s02-b flow (plan with `track: flow`, record, review); s03-c full plan whose research is absent; s04-d review already carrying its line; `reviews/stories-m9.md`, `reviews/stories.md` and `reviews/triage-2026-10-14.md` with a `# ` title. Keep a copy, run the script, then assert: each artefact's line under its title equals the template's line for that id (s03-c's plan reads `[Story](../stories.md)` alone, the Research link dropped); deleting the two inserted lines gives back the original byte for byte (`cmp`); s04-d and the three non-artefacts are byte-identical to the copy; a second run prints nothing and changes no checksum. — Bites: removing the existence filter leaves s03-c's Research link; removing the skip doubles s04-d's line.
3. [x] **Same file, `test_links_resolve_everywhere`.** (a) Over `$ROOT/docs`: for every story artefact of the four folders and `docs/qa/*/report.md`, the first non-blank line after the title holds at least one link and each target, resolved from the file's directory, exists (extraction as `tests/artifact-link-templates.test.sh:121`). (b) In a `scratch_repo`, the s128 fixture shape (validated plan, complete record with a `po-run` row and its `Tree:`, review with `Ship allowed: yes`, QA report), committed without link lines; record `gate_codes` for `plan-validated ship-allowed verif-current qa-current`, run the script, commit, assert the codes are unchanged and the four files did change. — Bites: a link line that broke a gate pattern, or a dangling link in any real artefact.
4. [x] **Same file, `test_existing_artifacts_backfilled`.** Copy `$ROOT/docs` to a temp dir, run the script on it, assert it printed nothing and `diff -r` is empty (every artefact already carries its line); assert the first non-blank line after the title of each `docs/reviews/stories*.md` and `docs/reviews/triage-*.md` does not start with `[Story](`. — Bites: any artefact left without its line, or a non-artefact linked.
5. [x] **Run the backfill on this worktree:** `bin/po-link-artifacts .` from the worktree root. Expect 434 files changed: the 436 story files of the inventory minus the two s128 files already linked; this plan carries its line and is skipped. Check `git diff --stat` lists only `docs/research/`, `docs/plans/`, `docs/reviews/`, `docs/verif/`, each file `+2`, `-0`; `git diff --numstat` shows no file with a deletion. Then the focused run `bash tests/run.sh artifact-links-backfill.test.sh artifact-link-templates.test.sh`, then the full suite through `po-run --story s129-artifact-links-backfill --label "Unit suite" -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `method/` ends with an empty diff, templates included: the lines are s128's, read, never rewritten.
- `docs/reviews/stories*.md`, `docs/reviews/triage-*.md`, `docs/stories.md`, `docs/decisions-log.md` end with an empty diff.
- In `docs/research/`, `docs/plans/`, `docs/reviews/`, `docs/verif/`, every changed file is `+2 -0` (`git diff --numstat`), apart from this story's own plan, record and review.
- No hand edit of any artefact: the backfill is the script's output alone.
- No ADR written: the reserved ADR-0088 stays unused.
- No change to `bin/polype`, `.claude/`, `.polype/`, `docs/installation.md`.

## Files touched
- `bin/po-link-artifacts` (new, executable)
- `tests/artifact-links-backfill.test.sh` (new)
- `docs/research/*.md`, `docs/plans/*.md`, `docs/reviews/s*.md`, `docs/verif/*.md` (two added lines each, by the script)
- this story's `docs/plans/`, `docs/verif/`, `docs/reviews/` files

## Test strategy
Three tests, one file, well within `Test budget: 25`, one per criterion. The script's rules are held at the script level on fixtures (task 2), the only place a removed rule shows; the real-repository tests (tasks 3a, 4) hold the backfill's result and keep holding it for every later story, whose artefacts come from s128's templates. The gate comparison reuses `gate_codes`' shape rather than retesting each gate pattern, which `tests/artifact-link-templates.test.sh` already holds. No red-first run.

## Done when
One commit on `story/s129-artifact-links-backfill` holding the script, the test, the backfilled artefacts and this story's evidence; the full suite green through `po-run`; a review with no open critical finding; shipped as `s129-artifact-links-backfill: Les artefacts déjà écrits se relient`.
