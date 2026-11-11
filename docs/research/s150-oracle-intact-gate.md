# Research — s150-oracle-intact-gate

[Story](../stories.md)

## Structuring facts
- No assumption of the story is false. s149 shipped (52a2938): `## Acceptance tests` with its `| Oracle file | cksum |` table is in `method/templates/plan.md:19-25`, `## Oracle changes` with `| Oracle file | What changes | Why |` in `method/templates/verification-record.md:23-27`.
- The model named by the story holds: `floor_guard` at `method/hooks/po-gate.sh:375`, its usage at `:20-21`, its dispatch at `:518`, its own exit-2 helper `unverifiable` at `:372`; `findings-shape` has its twin `shape_unreadable` at `:89`. A new check follows the same shape: own `exit 2` helper, flags on stdout, summary on stderr.
- `po-gate` has no table reader to reuse for the plan or the record: `record_rows` (`:144`) only reads `## Checks` and `## Runs`. One small awk reader of "the rows of the table whose header starts with X, in section Y" serves both new reads.
- The pivot this research leaves to the plan: every input (plan, record, oracle files) is read from the commit `story/<id>` points at, like `floor_guard` reads `story/<id>` (`:381-391`), never from the working tree the other gates read through `$(top)` (`:36`, `:126`).
- The reviewer that will review s150 runs the installed `.polype/hooks/po-gate.sh`, which lacks the new subcommand, and the installed skill, which does not call it: s150 takes effect only after the next refresh of the installed method (as 583b88b did for s147-s149).

## Story
`po-gate oracle-intact <id>` compares the oracle files the plan lists with their recorded `cksum`, on `story/<id>`; `review-antihallu` runs it in step 4 and grades its outcomes; *Bite* starts with the rules the oracle holds.
- `gate_compares_oracle_sums` — all equal → 0; a file changed or missing that `## Oracle changes` does not name → 1, naming it; a named file → 0, one line per change to judge.
- `gate_without_oracle_says_so` — no `## Acceptance tests` section, or `—` there → 0 with a line saying so; plan, branch or record unreadable → 2; the usage says it guards against mistakes, not against an implementer who also rewrites the sum (ADR-0052, ADR-0098).
- `review_runs_the_oracle_gate` — step 4 runs it before reading a test: 1 → critical; each logged change judged, weakening the criterion → major at least; 2 → review blocked, message as `Failure cause:`.
- `bite_starts_with_the_oracle` — *Bite* chooses first, among the rules the story depends on, those the oracle tests hold.

## Current code
- `method/hooks/po-gate.sh` (526 lines): header usage `:1-23`, `set -euo pipefail` `:25`, helpers `top`/`refuse` `:30-31`, gates `plan_validated` `:35`, `ship_allowed` `:69`, `findings_shape` `:90`, `verif_current` `:125`, `qa_current` `:202`, `pre_commit` `:321`, `floor_guard` `:375-515`, dispatch `case` `:517-526` (unknown subcommand → exit 2, `:525`).
- `floor_guard` checks `story/$id^{commit}` with `git rev-parse --verify --quiet` (`:381`) and every failure path calls `unverifiable`, because `set -e` would otherwise turn it into exit 1 (`:374` comment). Flags go to stdout one per line, the count to stderr (`:510-514`).
- `method/skills/review-antihallu/SKILL.md`: step 4 `:40-44` holds four bullets in this order: *Floor.* (`:41`, runs `po-gate floor-guard` "before reading any test"), *Coverage that is only apparent.* (`:42`), *Excess.* (`:43`), *Bite.* (`:44`, "Choose the one or two rules the story depends on — a guard, a condition, a state change, a query filter — and disable each in turn"). Severity scale `:54-58`.
- `method/templates/review.md:41` holds the checklist line for the floor guard; it is outside this story's `Owns`.
- `cksum < file` prints `<crc> <size>` (GNU coreutils 9.12 here; `bin/polype:144` `sum_of() { cksum < "$1"; }`), so `git cat-file blob <rev>:<path> | cksum` prints the same pair for the same bytes.

## Attachment points
- `method/hooks/po-gate.sh`: a usage entry after `:21`; a new section after `floor_guard` (before `case`, `:517`): one exit-2 helper, one table-reader helper, `oracle_intact()`; one dispatch line `oracle-intact) oracle_intact "${2:-}" ;;` in the `case`.
- `method/skills/review-antihallu/SKILL.md`: a new *Oracle.* bullet first in step 4 (before *Floor.*, `:41`); one sentence added to *Bite.* (`:44`).
- `tests/oracle-intact-gate.oracle.test.sh`: the oracle, four functions, one per criterion (convention `AGENTS.local.md:59`). `tests/oracle-intact-gate.test.sh` only if the implementer adds a test of its own (`tests/run.sh:15` fails a file with no `test_`).

## Verified interfaces
- Plan `## Acceptance tests` (`method/templates/plan.md:19-28`): prose placeholder, then `| Oracle file | cksum |` with rows `` | `<path>` | `<crc> <size>` | ``, then `| Criterion | Test |`. A story without oracle writes `—` with its reason in place of both tables (`:20`).
- Record `## Oracle changes` (`method/templates/verification-record.md:23-27`): `| Oracle file | What changes | Why |`; "No row means no oracle file changed".
- Plan path `docs/plans/<id>.md`, record path `docs/verif/<id>.md` (`po-gate.sh:36`, `:126`); both are committed with the code by the implementer (`method/agents/implementer.md:46`).
- `/po-execute` reads `## Acceptance tests` "when it names at least one file, the story **has an oracle**" (`method/commands/po-execute.md:29`).
- Test helpers: `scratch_repo` sets `SCRATCH` and an EXIT trap (`tests/lib.sh`), `contains`, `fail`, `require_file`; `tests/floor-guard.test.sh:6-21` is the shape for gate tests on throwaway repositories (capture `code`, `out`, stderr in `$SCRATCH/.git/*.err`).

## Traps
- Tests that freeze the two owned method files and must stay green: `tests/review.test.sh:27-32` (exactly six `**N. ` steps; the two *Bite.* phrases), `tests/floor-guard.test.sh:190-199` (the *Floor.* bullet's phrases), `tests/ownership.test.sh:50-56` (the `## Six steps` heading after the scope section), `tests/owns-overlap.test.sh`, `tests/review-lenses.test.sh`, `tests/gate.test.sh`, `tests/session-and-gate-checks.test.sh`, `tests/docs-and-eval-cleanup.test.sh:80-87` (the 40-hex comment sits above `paired_hash`), `tests/qa-report-returned-as-text.test.sh:75`. Adding a bullet and a sentence keeps them all; renumbering steps would not.
- `tests/overlap.test.sh` fails a `method/` line sharing 8+ consecutive words with Killer SaaS (ADR-0006): write the new text from the story, not from elsewhere.
- `set -euo pipefail`: a failing `git cat-file` inside `$(...)` aborts with its own code unless guarded; every unreadable path must go through the exit-2 helper, as `floor_guard` does.
- The second table of `## Acceptance tests` (`| Criterion | Test |`) must not be read as oracle rows; only the table whose header's first cell is `Oracle file`.
- The template's prose placeholder mentions `—` inside a `<…>` line; only a line that starts with `—` means "no oracle".
- `.polype/` and `.claude/` are installed copies: never edited (`AGENTS.local.md`, Conventions).
- No migration, no dependency, no new setting.

## Open questions
- Should the record be read when every sum matches? The story needs it only to excuse a difference; the plan reads it only then, so a pre-s149 lane with an intact oracle needs no record.
- A row of `## Oracle changes` naming a file whose sum still matches: ignored (nothing to judge), not an error. The plan settles it that way.
- `templates/review.md` gains no `Oracle:` checklist line (outside `Owns`); the reviewer still runs the check from the skill. A follow-up for the lead to file, not a blocker.

## Complexity
3 → 3. One new gate on an existing model, one bullet and one sentence in the skill; the parsing of two markdown tables is the only real work.

## Split
—
