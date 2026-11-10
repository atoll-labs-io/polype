---
validated: yes
---
# Plan — s157-qa-reads-ignore-rules

[Story](../stories.md) · [Research](../research/s157-qa-reads-ignore-rules.md)

Branch `story/s157-qa-reads-ignore-rules`. Read `docs/research/s157-qa-reads-ignore-rules.md` first; this plan builds on it without repeating it.

## Story
Fixes #167. In mode qa, `po-bounds` refuses `git check-ignore` because the verb is missing from `QA_GIT_VERBS` (`method/hooks/po-bounds.sh:319`), and a refusal stops the walk (`method/agents/qa.md:57`). Add `check-ignore` and `check-attr` to the list; the reviewer, which shares it in its story zone (`:772`), gets them too. ADR-0103 records the widened list and replaces ADR-0026 on that point alone.

Acceptance criteria (each is a test function of the same name): `qa_allows_check_ignore`, `qa_allows_check_attr`, `qa_still_refuses_writing_verbs`, `adr_widens_the_qa_allowlist`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Two words in `QA_GIT_VERBS` | already in this repository, `method/hooks/po-bounds.sh:319` and its matcher `:593-596` | — the existing allowlist is the mechanism; no new check, option or setting |
| Test lane setup (stories file, linked worktree, hook input) | already in this repository as a pattern, `tests/bounds.test.sh:11-43` | each test file is sourced alone (`tests/run.sh:12-15`), so the helpers are redefined in the new file, trimmed to one story; `scratch_repo` (`tests/lib.sh:46`) is reused as is |

## Tasks
1. [x] **Widen the list.** In `method/hooks/po-bounds.sh:319`, add `check-ignore` and `check-attr` to `QA_GIT_VERBS`, keeping the leading and trailing single spaces the matcher relies on (`:592` comment). In the header, line `:21`, cite `(ADR-0026, ADR-0103)` where it cites `(ADR-0026)`. Nothing else in the file changes. Test able to fail: `qa_allows_check_ignore`, `qa_allows_check_attr` (task 4).
2. [x] **Write ADR-0103** at `docs/decisions/ADR-0103-la-qa-lit-les-regles-d-ignorance-de-git.md` from `templates/adr.md`, in French: `status: accepted`, `date: 2026-11-10`, `scope: story s157-qa-reads-ignore-rules`, `supersedes: [ADR-0026]`, `superseded-by: []`, no comment on the link lines. Context: #167 (lagon, `git check-ignore -v site/dist site/.astro` refused, walk `blocked`), and the clash between ADR-0026:33 (the QA rephrases) and `method/agents/qa.md:57` (a refusal is a stop). Considered options: add the two reading verbs (chosen); let the QA rephrase (turned down: a refusal is a stop, it cost lagon's walk); a blacklist of writing verbs (still turned down, as in ADR-0026). Decision Outcome writes the full list, each verb in backticks, on one line beginning `Liste des verbes de lecture :` — `status`, `diff`, `log`, `show`, `rev-parse`, `ls-files`, `ls-tree`, `cat-file`, `merge-base`, `grep`, `blame`, `describe`, `symbolic-ref`, `shortlog`, `check-ignore`, `check-attr`, plus `worktree list` — and says the reviewer receives them in its story zone (ADR-0047, ADR-0051). It states it replaces ADR-0026 on the list only; the rest of ADR-0026 (inherited tools, `Tree:` by `rev-parse`) stands. Test able to fail: `adr_widens_the_qa_allowlist`, `qa_still_refuses_writing_verbs`.
3. [x] **Link ADR-0026.** In `docs/decisions/ADR-0026-qa-herite-le-navigateur-et-lit-git-par-liste-blanche.md`, change line 9 to `superseded-by: [ADR-0103]`. Status (`:4`, `accepted`) and body unchanged. Test able to fail: `adr_widens_the_qa_allowlist`.
4. [x] **Tests** in `tests/qa-reads-ignore-rules.test.sh` (s149 has not landed, so not the `.oracle.` file). A local `lane` builds `scratch_repo` with a committed `docs/stories.md` holding `### s01-demo — Demo` and an `Owns` line, a linked worktree `story/s01-demo`, and its own `TMPDIR`; a local helper feeds `{tool_name: "Bash", tool_input: {command}, cwd: $SCRATCH}` to `bash "$METHOD/hooks/po-bounds.sh" <mode>` and prints the exit code, another prints stderr.
   - `test_qa_allows_check_ignore`: mode qa, `git -C $WT check-ignore -v site/dist site/.astro` → 0; mode reviewer, same command → 0 (the shared list).
   - `test_qa_allows_check_attr`: mode qa, `git -C $WT check-attr -a README.md` → 0.
   - `test_qa_still_refuses_writing_verbs`: mode qa, `git -C $WT add -A` and `git -C $WT commit -m x` → 2, stderr holds `forbidden in mode qa, which runs reading verbs only`; then read the `QA_GIT_VERBS=` line of `po-bounds.sh`, and fail unless every verb of it appears backticked on the `Liste des verbes de lecture :` line of ADR-0103 and every backticked word of that line other than `worktree list` is in `QA_GIT_VERBS` (same set both ways).
   - `test_adr_widens_the_qa_allowlist`: ADR-0103 exists, frontmatter `status: accepted`, `supersedes: [ADR-0026]`; its body names `check-ignore`, `check-attr`, `ADR-0047`, `ADR-0051`; ADR-0026's frontmatter holds `superseded-by: [ADR-0103]` and `status: accepted`; ADR-0026's line 22 list is still the original fourteen verbs (`` `symbolic-ref`, `shortlog`, `worktree list` ``) — a body edit fails it.
   Run them: `bash tests/run.sh qa-reads-ignore-rules.test.sh`.
5. [x] **Full suite** once, through `po-run --story s157-qa-reads-ignore-rules --label test -- 'bash tests/run.sh'`. `tests/bounds.test.sh`, `tests/bounds-messages.test.sh`, `tests/leftovers.test.sh`, `tests/final-leftovers.test.sh` and `tests/overlap.test.sh` must stay green unchanged.

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s157-qa-reads-ignore-rules -- method/hooks/po-bounds.sh` touches line 319 and the header comment line 21 only.
- `docs/decisions/ADR-0026-…md`: the diff is the `superseded-by` line alone; `status` stays `accepted`.
- Empty diff for `tests/bounds.test.sh`, `tests/bounds-messages.test.sh`, `method/agents/qa.md`, `method/agents/reviewer.md`, `method/skills/qa-drivers/`, `docs/decisions/ADR-0047-*`, `docs/decisions/ADR-0051-*`, and every installed copy under `.claude/` and `.polype/`.
- No verb beyond `check-ignore` and `check-attr` is added (no `branch`, `for-each-ref`, `config`): a wider list is a new idea for `Issue tracker`, not this story.
- No change to `method/agents/qa.md:57` (a refusal stays a stop).

## The pivot
That `check-ignore` and `check-attr` are pure reads in every form an agent can pass after the verb. Ways it could be wrong:
- An option that writes: compare with `git help check-ignore` / `git help check-attr` (options `-q`, `-v`, `-n`, `--stdin`, `-z`, `--no-index`, `--non-matching`; `-a`, `--all`, `--cached`, `--source`). None writes a file; `--output` would still be refused before the list check (`po-bounds.sh:584-588`).
- The reviewer zone was meant to stay narrower than qa: ADR-0047:31 ties it to the QA's list by design, and the story asks for the shared gain; check ADR-0103 says so.
- Matching: a verb added without its surrounding spaces would match nothing or a substring; `qa_allows_check_attr` and `qa_allows_check_ignore` exercise the real matcher.

## Files touched
- `method/hooks/po-bounds.sh`
- `docs/decisions/ADR-0103-la-qa-lit-les-regles-d-ignorance-de-git.md` (new)
- `docs/decisions/ADR-0026-qa-herite-le-navigateur-et-lit-git-par-liste-blanche.md` (frontmatter line 9)
- `tests/qa-reads-ignore-rules.test.sh` (new)
- `docs/research/s157-qa-reads-ignore-rules.md`, `docs/plans/s157-qa-reads-ignore-rules.md`, `docs/verif/s157-qa-reads-ignore-rules.md`

## Test strategy
Four tests, one per criterion, all at the hook's own layer (the hook is the policy): they call `po-bounds.sh` itself, never a re-implementation of its list. Within `Test budget` (25).
- The bite: removing `check-ignore` from `:319` turns `qa_allows_check_ignore` red; removing `check-attr` turns `qa_allows_check_attr` red; removing either also breaks the set equality of `qa_still_refuses_writing_verbs`. Making the matcher accept any verb turns the `add`/`commit` refusals red.
- The reviewer assertion sits inside `qa_allows_check_ignore` as one line, not a test of its own: same rule, same variable.
- The ADR tests read frontmatter and quote short exact phrases (`contains`), as `AGENTS.local.md` asks.
- No visual check: no screen.

## Done when
- The four tests pass, the full suite is green through `po-run`, the record is complete.
- One commit on `story/s157-qa-reads-ignore-rules`; at ship, #167 is closed by the landing.
- A review with no open critical finding.
