# Review — s162-defects-seen-on-products

[Story](../stories.md) · [Plan](../plans/s162-defects-seen-on-products.md) · [Verification](../verif/s162-defects-seen-on-products.md)

Diff reviewed: `git diff main...story/s162-defects-seen-on-products`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 8457cc0229a418e0d4e1ab1a7c6f8233f109e3e9

## When blocked
- Failure cause: n/a
- Missing: n/a
- Required adaptation: n/a
- Next action: n/a

## Ownership
I listed the diff with `git diff --name-only main...story/s162-defects-seen-on-products` and checked each path against the story's `Owns` line (`docs/stories.md:2559`).
- [x] Every path is inside `Owns`. The five `method/` files and `tests/defects-seen-on-products.oracle.test.sh` are listed there. `docs/research/`, `docs/plans/` and `docs/verif/` of the story are in scope by construction.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. s163's `Owns` does not overlap.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s162-defects-seen-on-products` passes (exit 0), so I reused the record. The last row, `bash tests/run.sh`, exits 0 on tree `573d604f…`, and the code outside `docs/` is identical to HEAD. The record's "Not proven here" says criteria 1 to 3 are judged by reading. The project has no type check (`Typecheck: —`).
- [x] `po-gate qa-current` is not required: `QA stage: —` and `Surface: —`.

## Plan
- [x] Tasks 1 to 7 are all present.
  - designer status check: `designer.md:20`
  - designer skill paths: `designer.md:37-39`
  - template `Owns`: `templates/stories.md:13`
  - agentic-stories clause: `SKILL.md:21`
  - stories-review check 8 and the major list: `:25`, `:54`
  - `/po-setup` skill-existence check: `po-setup.md:46`
  - full suite through `po-run`
- [ ] Not everything stays inside the plan. Task 6 allowed cutting "redundant prose" to pay for the new words, but `po-setup.md:40` lost a sentence that is not redundant (see Findings).
- [x] I checked each run interdict:
  - The diff on `.claude/`, `.polype/`, `AGENTS.md`, `method/AGENTS.md`, `method/hooks/`, `bin/`, `planner.md`, `implementer.md`, `po-design.md`, `po-stories.md` and `docs/stories.md` is empty.
  - `stories-reviewer.md` is unchanged.
  - The oracle's `cksum` is `1702754200 877`, as the plan says.
  - There is no `tests/defects-seen-on-products.test.sh`.
  - No existing test file was edited.
  - stories-review still has ten numbered checks and no `**11.`.
  - The designer does not recompute sums.

## References
- [x] I confirmed the designer's wording against `method/agents/planner.md:22`, `method/agents/implementer.md:24` and `method/AGENTS.md:105`. The skill paths match between `designer.md:37` and `po-setup.md:46`. `po-design.md:46` makes no claim about the path, so it stays consistent.
- [x] Values that only look right: the oracle's word ceilings equal `LC_ALL=C wc -w` of each file at `main`. Measured: designer 967→959, template 315→314, agentic-stories 1119→1119, stories-review 1248→1245, stories-reviewer 451→451, po-setup 2278→2274.

## Rules
- [x] `AGENTS.md` conventions are respected: method files in English, no Killer SaaS overlap (the suite is green).
- [ ] One accepted ADR is weakened, not contradicted. ADR-0079 §3 says a solo repository's `(chosen)` value is changed later by the person in conversation. `/po-setup` no longer tells the person so (see Findings).

## Tests
- [x] Floor: `po-gate floor-guard s162-defects-seen-on-products main` returned 0, so nothing was lowered. `po-gate oracle-intact` also returned 0.
- [x] `test_no_file_grows` pins criterion 4. Criteria 1 to 3 are case 3 of the owner's 2026-11-13 rule, so I judged them by reading, and all three are met in the text. None of the six empty test shapes appears.
- [x] One test, within the `Test budget` of 25.
- [x] Bite: I appended five words to `method/commands/po-setup.md` and ran `defects-seen-on-products.oracle.test.sh`. 1 test failed ("holds 2279 words, 2278 before s162"). I undid it with `git checkout --`; `git diff --exit-code` was clean and the test passed again.
- [x] The story makes no existing test useless.

## Neighbours
- [x] I read `po-design.md:46`, `templates/agents-local.md:28,62`, `planner.md:22`, `implementer.md:24,56`, `AGENTS.md:105` and `po-ship.md:44`. Nothing is broken. The rule that no agent rewrites a `(chosen)` value still lives in `method/AGENTS.md:10` and `po-ship.md:44`.

## Lenses
Lenses run: none. The diff is method prose and one bash test, and no trigger path or content applies.
- [x] There is no lens finding.

## Findings
- major — method/commands/po-setup.md:40 — The story deleted the sentence "Tell the person they change it later by asking in conversation; no agent changes a `(chosen)` value on its own." to pay for the words of task 6.
  The second half is repeated in `method/AGENTS.md:10`. The first half is a behaviour that exists nowhere else: setup told the person how a `(chosen)` `Ship confirmation` is changed later, as ADR-0079 §3 provides ("Elle la change plus tard en conversation"). After this cut, the person is never told.
  The plan allowed cutting "redundant prose" only, and named the `:46` clause as the expected payment. This is an unrequested change of behaviour, contained, with no silent damage.
  Fix: put the instruction back (for example, a mention next to the existing "say the person changes it by asking in conversation" of `:62` for `Issue tracker`), and pay elsewhere.
- minor — method/commands/po-setup.md:46 — The clause "the other one stays `—`" was dropped. Nothing now says that `Design tool` stays `—` when the source is `internal` (or that `Design skill` stays `—` when it is `external`). The `agents-local.md` template default is `—`, so the result is likely unchanged, but the rule is now implicit.

## Not verified
- I did not run the three model-facing rules (designer, stories-reviewer, `/po-setup`). I judged them only by reading, as the plan's case 3 says. A person should run the `po-eval` control arms the plan lists (#208): a designer on a worktree holding the oracle files, a stories review of a story whose `Owns` has no oracle, and a setup given a missing or plugin-only `Design skill`.
- I did not check Pivot 2 of the plan: that a subagent cannot load an enabled plugin skill by name. If it can, `/po-setup` now refuses a skill that works. A person should confirm with a designer dispatch on a project that only has a plugin skill.
- I did not check the edge case where the project's `.claude/skills/<name>/` exists at the repository root but is untracked, so a story worktree would not hold it. If that happens, setup accepts a skill that the designer reads only through `~/.claude/skills/`. Nothing in the diff covers it.
- I did not rerun the full suite. I relied on the `po-run` record (exit 0 on code identical to HEAD).

Max severity: major
Ship allowed: yes
