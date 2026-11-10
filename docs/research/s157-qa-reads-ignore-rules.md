# Research — s157-qa-reads-ignore-rules

[Story](../stories.md)

## Structuring facts
- **Root cause**: `method/hooks/po-bounds.sh:319` — `QA_GIT_VERBS` holds `status diff log show rev-parse ls-files ls-tree cat-file merge-base grep blame describe symbolic-ref shortlog`, no `check-ignore`, no `check-attr`. The input `git -C <wt> check-ignore -v site/dist site/.astro` (issue #167, lagon, 2026-11-10) reaches `check_git_read` (`:582`, called at `:761` in mode qa), whose `case` on the list (`:593-596`) falls to `deny` at `:595`. Proof: reproduced below, the hook prints the exact refusal of #167 and exits 2.
- The story's assumptions hold: the list is at `:319` as the AC says, the refusal message is `:595`, and the reviewer shares the list in its story zone (`:772`), so it is refused the same way (reproduced).
- Why one missing verb ends a walk: `method/agents/qa.md:57` makes any po-bounds refusal a stop with no other route, while ADR-0026:33 still says "la QA reformule". The two disagree; the story settles it on the side of qa.md (ADR-0103 replaces ADR-0026 on the list only).
- Neither new verb writes: `check-ignore` and `check-attr` only print what the ignore and attribute rules say; the `--output` refusal (`:584-588`) keeps applying to them since it runs before the list check.
- s149 has not landed (no `tests/*.oracle.test.sh`, no s149 commit on `story/s157-…`): per the story's note, the criteria functions go to `tests/qa-reads-ignore-rules.test.sh`.

## Diagnostic
Reproduction, on the code as it stands (`b0999a4` for `po-bounds.sh`), by feeding the hook a Bash hook input from a script outside the worktree (`/tmp/s157-repro/run.sh`), `cwd` = this worktree:

| Mode | Command | Exit | stderr |
| --- | --- | --- | --- |
| qa | `git -C <wt> check-ignore -v site/dist site/.astro` | 2 | `git check-ignore is forbidden in mode qa, which runs reading verbs only: …` |
| qa | `git -C <wt> check-attr -a README.md` | 2 | `git check-attr is forbidden in mode qa, …` |
| qa | `git -C <wt> status --porcelain` | 0 | — |
| qa | `git -C <wt> add x` / `commit -m x` | 2 | `… forbidden in mode qa, which runs reading verbs only` |
| reviewer | `git -C <wt> check-ignore -v site/dist` | 2 | `… forbidden in mode reviewer, which runs reading verbs only` |
| reviewer | `git -C <wt> check-attr -a README.md` | 2 | same |
| reviewer | `git -C <wt> status` | 0 | — |

Hypotheses:
1. **The verb is absent from the allowlist** — refuted if `check-ignore` were in `QA_GIT_VERBS` or the refusal came from another `deny`. Read `:319`: absent; the stderr is the text of `:595`. **Kept.**
2. **The lexer misread the call** (e.g. took `-v` or a path for the verb) — refuted if the refusal names `check-ignore` as the verb. It does (`git check-ignore is forbidden…`); the global-option loop (`:735-758`) stops at the first non-option word. **Discarded.**
3. **The refusal came from Claude Code's harness, not po-bounds** — refuted if calling `po-bounds.sh qa` directly reproduces it. It does, word for word. **Discarded.**

## Story
As the owner, I want `po-bounds` in mode qa to accept read-only git verbs such as `git check-ignore`, so a harmless check no longer becomes a refusal, hence a stop that leaves the walk half done.
- `qa_allows_check_ignore` — mode qa, `git -C <wt> check-ignore -v site/dist site/.astro` exits 0; the test fails when `check-ignore` leaves `QA_GIT_VERBS`.
- `qa_allows_check_attr` — `git check-attr` passes the same way.
- `qa_still_refuses_writing_verbs` — `git add`, `git commit` still refused with "forbidden in mode qa, which runs reading verbs only"; `QA_GIT_VERBS` is the list of ADR-0103, shared by the reviewer in its story zone.
- `adr_widens_the_qa_allowlist` — ADR-0103 adds the two verbs to ADR-0026's list, says the reviewer gets them too (ADR-0047, ADR-0051), replaces ADR-0026 on that single point: ADR-0026 gains `superseded-by: ADR-0103`, status and body unchanged. Option turned down: let the QA rephrase (ADR-0026:33).

## Current code
- `method/hooks/po-bounds.sh:18-22` header: mode qa, "every git call must use a reading verb of an allowlist (ADR-0026)". `:24-26`: reviewer story zone uses "git reading verbs of the qa allowlist only".
- `:319` the list, a space-padded string; `:593` matches `*" $verb "*`, so an empty verb never matches.
- `:582-605` `check_git_read`: `--output` refused first (`:584-588`), `worktree` handled apart (only `list`, `:589-590`), then the list, then `symbolic-ref` write forms (`:597-605`).
- `:760-761` mode qa calls it on every git call; `:772` reviewer calls it in a story worktree for any verb but `checkout`/`restore`.
- `docs/decisions/ADR-0026-…md:4` `status: accepted`, `:9` `superseded-by: []`, `:22` the list, `:33` the "QA rephrases" consequence.
- ADR-0047:31 says the reviewer story zone uses "les verbes de lecture de la liste de la QA (ADR-0026)".

## Attachment points
- One word list: `method/hooks/po-bounds.sh:319`. No other code reads verbs for mode qa.
- Header comment `:21` cites ADR-0026 for the allowlist: the place to add ADR-0103.
- `docs/decisions/ADR-0026-…md:9`, the only line of it that may change.
- New: `docs/decisions/ADR-0103-la-qa-lit-les-regles-d-ignorance-de-git.md` (name fixed by `Owns`), `tests/qa-reads-ignore-rules.test.sh`.

## Verified interfaces
- Hook call: JSON `{tool_name: "Bash", tool_input: {command}, cwd}` on stdin, `bash po-bounds.sh qa|reviewer`; exit 0 allows, 2 refuses with `po-bounds: <reason>` on stderr (`po-bounds.sh:54-55`).
- Test helpers: `tests/lib.sh:41` `require_file`, `:43` `contains` (exact, `grep -qF`), `:46` `scratch_repo` (sets `$SCRATCH`, removed on exit), `:13` `frontmatter`.
- Lane pattern to copy: `tests/bounds.test.sh:11-35` `lane()` (stories file with Owns, linked `story/<id>` worktrees, own `TMPDIR`), `:37-40` `hook_input`, `:43` `status_with`, `:160` `qa_status`. These are functions of another test file: the new file defines its own (each test file is sourced alone by `tests/run.sh:12-15`).
- ADR frontmatter link lines must stay comment-free and bracketed (`tests/final-leftovers.test.sh:17-18`; example `ADR-0039…md:8` `superseded-by: [ADR-0050]`).

## Traps
- `tests/bounds.test.sh:171-176,353-362` and `tests/bounds-messages.test.sh:47-51` pin mode qa: none asserts that `check-ignore` or `check-attr` is refused (grepped), so they stay green unchanged; they are outside `Owns`.
- ADR-0026 is `accepted`: only `superseded-by` changes, `status` stays `accepted` (partial replacement, `templates/adr.md` status comment). `tests/leftovers.test.sh:12` pins other ADRs' link lines, not 0026.
- Lane s156 (same milestone) changes ADR-0029's links and the QA report path; no overlap with this `Owns`.
- ADR-0052: po-bounds guards against mistakes, not deliberate bypass; `-c` options before the verb already pass in mode qa for every listed verb. Adding two verbs changes nothing there.
- The repro needed a script file outside the worktree: the session harness refused an inline command that names git with `-C` to another path. The implementer's test runs through `bash tests/run.sh`, unaffected.

## Open questions
- None blocking. Whether other reading verbs (`branch --show-current`, `for-each-ref`, `config --get`) deserve the list is out of scope: the story names two verbs, and a wider list is a new idea for `Issue tracker`.

## Complexity
Story 1 → 1: one word list, one ADR, one superseded-by line, one test file.

## Split
—
