# Review — s49-secret-scan

Diff reviewed: `git diff main...story/s49-secret-scan`, in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 162a7d2caef74ea9d9e09838f34a6aab208d1317

## Ownership
I listed the diff with `git diff --name-only main...story/s49-secret-scan` and checked each path against `Owns`: `method/hooks/po-gate.sh`, `method/AGENTS.md`, `tests/gate.test.sh`.
- [x] `method/hooks/po-gate.sh`, `method/AGENTS.md` and `tests/gate.test.sh` are inside `Owns`. `docs/plans/s49-secret-scan.md` and `docs/verif/s49-secret-scan.md` are the story's own evidence.
- [x] One path is outside `Owns`: `docs/decisions/ADR-0028-secrets-refuses-par-po-gate-sans-dependance.md`. AGENTS.md Law 6 requires it ("Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`"), and the plan announces it under "Files touched". So this is a gap in `Owns`, not a breach by the implementer, and it is rated **minor**.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows only the main checkout and this worktree.

## Evidence reused
- [x] `po-gate verif-current s49-secret-scan` exits 0. The record's tree `561cc7dd…` equals HEAD outside `docs/`. Its status is complete: focused tests 31 passed, full suite 267 passed, all exit 0. I relied on it and did not rerun the full suite.
- The project has no Typecheck, E2E or Build command (all set to `—`).
- I read the record's "Not proven here": macOS awk was not exercised, `.polype/` was not refreshed, and the table covers only six formats.

## Plan
- [x] Tasks 1 to 5 are all present and match the plan: the `.env` listing with `--diff-filter=d`, the `SECRET_PATTERNS` table with min-length and left-boundary checks, the scan called before the `story/*` early return, the Law 6 rewrite, and four tests.
- [x] Each run interdict, checked one by one:
  - **No literal key:** the interdict's `git grep` over `method tests docs` on the branch returns nothing.
  - **No echoed value:** the messages carry only path, line and rule.
  - **Other functions untouched:** `plan_validated`, `ship_allowed`, `verif_current`, `floor_guard`, the dispatch and `method/hooks/pre-commit` have no diff.
  - **Existing tests kept:** existing tests in `gate.test.sh` are unchanged and `structure.test.sh` is untouched.
  - **Nothing outside `Owns`:** no diff under `.claude/`, `.polype/`, `bin/`, `implementer.md` or the framing commands.
  - **No new tool:** the scan uses only bash, git and awk.

## References
- [x] Everything the code relies on exists:
  - `refuse` at `po-gate.sh:18`.
  - `set -euo pipefail` at `:15`, so the `git … -z | tr` listing failure really does reach `refuse`.
  - The `header_path` logic copies the floor guard's.
  - The diff options match the ones pinned at `:116` of main.
  - Test helpers `sandbox`, `plan`, `passes`, `contains` and `$METHOD` exist in `tests/gate.test.sh` and `tests/lib.sh`.
- [x] I probed values on scratch repos:
  - **Line numbers:** across several hunks, a token on line 20 is reported as `a b.txt:20` (the path contains a space).
  - **Tricky content lines:** a content line starting with `++` and a fake `+++ b/x` line inside a hunk are both still scanned correctly.
  - **AKIA and ASIA:** both are caught after `AWS_ACCESS_KEY_ID=`.
  - **The story's own diff:** with this story's files (patterns, ADR, plan, tests) staged, the scan exits 0. The tool does not refuse its own source.
- [ ] One value only looks right: the left-boundary rule also applies to the PEM row (see Findings).

## Rules
- [x] `AGENTS.md` conventions are respected: comments in English, tests in bash, Law 6 opening words kept.
- [x] No accepted ADR is contradicted. ADR-0028 records gitleaks as turned down, and ADR-0025's no-dependency rule is kept.

## Tests
- [x] Floor: `po-gate floor-guard s49-secret-scan main` exits 0, so nothing was lowered.
- [x] Each acceptance criterion has a test of the same name. Values are assembled at run time, the refusal is asserted to name the file and not show the value, and the end-to-end `git commit` goes through `core.hooksPath` on `main`. None of the six empty test shapes appear.
- [x] 4 new tests, within the budget of 25.
- [x] Bite: I ran only `gate.test.sh` (22 tests) after each mutation. After each one I restored the file and `git diff --exit-code method/hooks/po-gate.sh` was clean.

| Mutation | Failing tests |
| --- | --- |
| `secret_scan` call moved after the `story/*` early return | 3 |
| Left-boundary check removed | 1 |
| `.env.example` exception removed | 1 |
| `--diff-filter=d` removed | 1 |
| Matched text appended to the message | 1 |
| Minimum-length check neutralised (`RLENGTH >= 0`) | **0** — rule not tested |

- [x] No test became useless because of this story.

## Neighbours
- [x] `method/hooks/pre-commit` still only `exec`s `po-gate.sh pre-commit`. The error output and exit codes 0/1 are unchanged for the plan check, and `bin/polype` installs the hook as before.
- `README.md:34` still describes the pre-commit hook as only refusing code without an approved plan. It is outside `Owns`, so it is rated minor below.

## Findings
- **major** — `method/hooks/po-gate.sh` (`hit()`, the left-boundary check applied to the `private-key` row): a PEM private key whose `-----BEGIN` follows a literal `\n` inside a one-line string is not detected. The rule "a match preceded by `[A-Za-z0-9_]` does not count" sees the `n` of `\n`. I reproduced it: `"tls": "-----END CERTIFICATE-----\n-----BEGIN PRIVATE KEY-----\nMIIE"` staged → exit 0. The same key after a `"` is refused. A cert chain followed by its key in one JSON or env string is a realistic shape for an "obvious" key. The fix is to exempt the PEM row from the boundary check (or put 0 as its boundary), plus one test line. This is contained and nothing regresses, since there was no scan before.
- **minor** — `method/hooks/po-gate.sh`: no test covers the minimum-length rule. Neutralising it fails no test. It only guards against false positives (for example a short `sk_live_x` in docs), and the plan names it as a defence the reviewer should check. One short near-miss in `test_pre_commit_refuses_obvious_keys` would cover it.
- **minor** — `docs/decisions/ADR-0028-secrets-refuses-par-po-gate-sans-dependance.md` is outside the story's `Owns`. Law 6 requires the ADR and the plan announces it; the gap is in `Owns`, not in the code.
- **minor** — `README.md:34` (outside `Owns`, not changed) still says the pre-commit only guards the plan. The wider behaviour is not described there. A later documentation pass should update it.

## Not verified
- **macOS / BSD awk:** I only ran this machine's awk. The patterns stay within POSIX ERE, but the boundary/length loop over `match()` is untested on BSD awk. A person on macOS should run `bash tests/run.sh gate.test.sh`.
- **The live hook in this repository:** the installed `.polype/hooks/po-gate.sh` is the old copy until the next `polype` install. Commits here are not guarded yet. After the install, someone should stage a dummy `.env` in this repo and confirm the refusal.
- **Commits through a temporary index:** `git commit -a` and `git commit <path>` use a temporary index, which `git diff --cached` follows through `GIT_INDEX_FILE`. I did not exercise this. A person should try `git commit -a` with a modified tracked file holding a test key.
- **Paths containing a newline:** the `-z | tr '\0' '\n'` listing would split them. I did not test this; such names are rare.
- **Coverage of real token formats:** I did not check the table against the providers' current formats beyond the shapes the plan describes, and other providers are out of scope by ADR-0028.

Max severity: major
Ship allowed: yes
