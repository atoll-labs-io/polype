# Review — s12-prd-kill

[Story](../stories.md) · [Plan](../plans/s12-prd-kill.md) · [Verification](../verif/s12-prd-kill.md)

Diff reviewed: `git diff m2-cadrage...story/s12-prd-kill`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

(`Review status:` line added by /po-review when recording: the reviewer's answer carried both verdict lines but not this one. The rest is the reviewer's answer, unchanged.)

Scope: `git diff m2-cadrage...story/s12-prd-kill`, one commit (0052932), 8 files. Worktree `/home/lecrabe/dev/atoll/polype/.claude/worktrees/m1-cycle/.worktrees/s12-prd-kill`, branch `story/s12-prd-kill`. The tree was clean at the start and is clean at the end.

## 1. Evidence I reused
- `po-gate verif-current s12-prd-kill` exited 0. I also compared by hand: `git diff --quiet 0e8f6bd… HEAD -- . ':(exclude)docs'` shows the committed code matches the record's `Tree:`.
- `Verification mode: record`. `docs/verif/s12-prd-kill.md` is marked complete, with `bash tests/run.sh` at exit 0 (87 passed, which includes `overlap.test.sh` against the local Killer SaaS sources, `structure.test.sh` and `pilot.test.sh`). I did not rerun the full suite.
- The project has no type check, lint, E2E or build command (`—` in AGENTS.local.md). None were run and I did not substitute any.
- Beyond the record, I ran only `bash tests/run.sh prd.test.sh`: 5 passed.

## 2. References
Every reference resolves:
- `tests/lib.sh`: `contains`, `require_file`, `settings_read_by`, `fail`, `$METHOD` all exist with the signatures the tests use.
- `Entry mode` is in `method/templates/agents-local.md:23,46`, with the values `replace`, `adapt`, `new` and `—`. `po-setup.md:32` asks for it.
- `Target branch` is in the template.
- The complexity scale is at `method/templates/stories.md:5`.
- `AskUserQuestion` is used the same way as in `po-setup`, `po-plan` and `po-ship`.
- `/po-brief` is named only as a redirect and is not created, as the plan intends (it belongs to s13).
- `method/` contains no reference to `docs/references/`.

## 3. Plan and interdicts
- Tasks 1–5 and 4b are all present, in the shape the plan describes.
- The diff touches only the files the plan lists. `.claude/`, `.polype/`, `AGENTS*.md`, `tests/lib.sh` and the existing tests are unchanged.
- In the parity matrix, only the C02 and C03 status cells changed.
- The adapt probes are written into the command instead of being read from `docs/references/spec-interrogation.md`. The research justifies this: the installer ships only `method/`. The plan records it as the pivot, and I accept it.

## 4. Tests: five clauses disabled one at a time
After each change I ran only `prd.test.sh`, then restored the file and checked it with `git diff --exit-code method/commands/po-prd.md`.

| Clause disabled | Failing tests |
| --- | --- |
| `new` → stop and point to /po-brief (`new` made to continue) | 1 |
| Heavy rule inverted ("stays in the core loop") | 1 |
| `**Exact consumer**` probe removed from the adapt section | 1 |
| `—` → stop removed | 1 |
| "One question per message." replaced | 1 |

Every rule I disabled is caught. The suite uses 5 of a 25-test budget, with no excess and none of the six kinds of test that prove nothing. The tests only check that phrases are present, so a contradicting clause added elsewhere in the file would go unnoticed. That is the normal limit of text-level tests in this repository, not a finding.

## Findings
- minor — `method/commands/po-prd.md` (adapt section) — the success-signal probe lost its failure side (the signal that would say the angle failed); the evidence-of-pain probe asks who complained rather than the last concrete cost. Wording drift, intent survives.
- minor — `method/commands/po-prd.md` (Checks 3 and 4) — check 3 (ask for a missing target) runs before check 4 (resume a `status: draft` file), so a resumed interview asks for a target the draft already holds; the two checks could be swapped.
- minor — `method/commands/po-help.md` — edited outside the story's Owns (s20 owns it); one line, justified in the plan by `tests/pilot.test.sh`, s20 not running. s20 must keep the `/po-prd` line.

## Not verified
- How `/po-prd` behaves when run: a real interview, one question per message, resuming from a draft, the mode-mismatch stop, `status: approved`, the commit on `Target branch` with the env-file check. A person should run `/po-prd <some SaaS>` once in `replace` and once in `adapt` mode in a scratch project and check `docs/prd.md` against `templates/prd.md`.
- The installed copy after `bin/polype-dev-install` (installer copies `method/` wholesale, not run here).
- The full suite, `overlap.test.sh` included: relied on the verification record.
- The French wording of the `po-help.md` line.

## Verdict
The story meets its five criteria, and each criterion's test catches the removal of its clause. There is no critical or major finding.

Max severity: minor
Ship allowed: yes
