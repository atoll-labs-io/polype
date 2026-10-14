---
track: flow
validated: yes
---
# Plan (short track) — s112-short-subject-shipped

[Story](../stories.md)

Written by the planner on the short track (`Story track: auto`, complexity 2 ≤ `Flow threshold: 2`). This one file stands in for both the research and the plan: there is no `docs/research/s112-short-subject-shipped.md`. Validated under `Plan validation: autonomous`: no human reviewed it.

## Verified facts
No assumption of the story proved false. The defect it describes reproduces on this worktree.

- **Reproduced.** `bash method/hooks/po-session.sh` run from the repository root prints `Ready stories: s01-regles-et-reglages, s02-gates, … s10-validation-m1`: the ten stories `main` shipped under `s01:` … `s10:` (`git log --format=%s main | grep -E '^s[0-9]+:'` lists `s01:` to `s10:` and one `s92:`).
- `read_shipped` (`method/hooks/po-session.sh:130-136`) fills `SHIPPED[<id>]` from `git log --format=%s` on `Target branch` plus `origin/<Target branch>` when that ref exists (`:131-132`), keeping only subjects matching `^$id_re:` (`:135`), with `id_re='s[0-9]+-[a-z0-9-]+'` (`:16`). A subject `s01: …` has no `-<slug>`, so it never matches.
- `SHIPPED` is read in three places: the story itself (`:142`), each of its dependencies (`:145`), and the "pull request presumed waiting" line of a lane (`:204`). All three must apply the same rule, otherwise a story depending on `s01-…` stays blocked.
- A subject `s10-autre: …` already matches `id_re` and lands in `SHIPPED` under `s10-autre`, so it cannot mark `s10-x` (`:134-135`).
- Story numbers keep their leading zeros in ids (`s01-regles-et-reglages`, `docs/stories.md`), so "`s<n>:` exactly" means the digits as the id writes them: `s01:` ships `s01-x`, `s1:` does not.
- `s92:` and `s92-review-tree-gate:` both exist on `main`, and `docs/stories.md:1392` holds the only `s92-…` story: the short subject changes nothing there.
- `/po-status` states the shipped rule at `method/commands/po-status.md:31` (`Target branch` or `origin/<Target branch>`); `/po-drive` states it at `method/commands/po-drive.md:31` (only `Target branch`) and says it derives state "the way `/po-status` derives it" (`:29`). The resume table repeats the full-id rule in its last row (`method/commands/po-drive.md:68`), whose right cell `nothing — the story is done` is quoted by `tests/resume.test.sh:27`.
- `po-session` tests build throwaway projects in `tests/project-lead.test.sh:15-28` (`session_in`, `polype_repo`, `commit_all`) over `scratch_repo` (`tests/lib.sh:46-53`). Those helpers live in that test file, not in `lib.sh`; `tests/run.sh:11-17` sources `lib.sh` and one test file per run, so a new file must define its own.
- Dependency `s109-drive-guards` is shipped (`s109-drive-guards: …` on `main`).

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, `docs/stories.md` s112 | absent — no data store; `po-session.sh` reads git only (`:2-4`) |
| New screen | absent — `Surface: —` | absent — CLI hook and markdown commands only |
| Authorization or tenant scope | absent — story text | absent — `read_shipped` / `ready_stories` hold no access rule |
| API contract | absent — story text | absent — the printed lines of `po-session` keep their exact form (`:161`, `:165`) |
| New dependency | absent — story text | absent — `grep -oE` and bash arrays already used (`:135`, `:128`) |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no `Corrige` line on s112 | absent — same |
| Technical choice deserving an ADR | absent — option settled by the owner on 2026-10-13 (story notes) | absent — a fallback inside one existing function |

## Story
As project owner, I want a story shipped under a `sNN:` subject to count as shipped when no commit carries its full id, so that `/po-drive` never relaunches s01 to s10 here or on a repository that kept the old convention.

- `short_subject_counts_as_shipped` — `/po-status` and `/po-drive` say, with the same sentence, that a story `s<n>-<slug>` is shipped on a commit of `Target branch` (or `origin/<Target branch>`) whose subject starts with `<id>:`, or, lacking such a commit, with `s<n>:` exactly; `po-session` applies the same rule in `read_shipped`.
- `short_subject_is_exact` — `s1:` marks neither `s10-…` nor `s100-…`, and a subject `s10-autre:` does not mark `s10-…`; a test shows it on a throwaway repository with `po-session`.
- `session_lists_no_short_shipped_story` — on a throwaway repository whose history ships `s01-x` under `s01: …`, `po-session` does not list `s01-x` among the ready stories.

## Tasks

1. [x] **`po-session.sh`: short subjects in `read_shipped`.** Keep the full-id loop as is. Add a second associative array (e.g. `SHORT_SHIPPED`) filled from the same `git log` output with `grep -oE '^s[0-9]+:'`, key without the colon (`s01`). Add one helper, e.g. `is_shipped() { [ -n "${SHIPPED[$1]-}" ] || [ -n "${SHORT_SHIPPED[${1%%-*}]-}" ]; }`, and use it at the three readers (`:142`, `:145`, `:204`) instead of reading `SHIPPED` directly. One `git log` call, no new process per story. The `${1%%-*}` prefix is the exact digit string of the id, which is what makes `s1:` miss `s10-…`. Test that would fail: `test_short_subject_is_exact` and `test_session_lists_no_short_shipped_story`.
2. [x] **`po-status.md:31`: the shared sentence.** Replace the `shipped:` bullet's rule with the sentence below, keeping `→ shipped; an open pull request from `story/<id>` → waiting for merge;` after it. Test that would fail: `test_short_subject_counts_as_shipped`.
3. [x] **`po-drive.md:31` and `:68`: the same sentence.** At `:31`, replace `a commit whose subject starts with `<id>:` on `Target branch`` with the same sentence (which also adds `origin/<Target branch>`, aligning with `/po-status`). At `:68`, change only the left cell to `the story is shipped, as `## The ready set` reads it`; the right cell `nothing — the story is done` stays word for word (`tests/resume.test.sh:27`). Test that would fail: `test_short_subject_counts_as_shipped`.
4. [x] **`tests/short-subject-shipped.test.sh`.** Header comment `# s112 — …`. Define its own `session_in` / project helpers, copied in spirit from `tests/project-lead.test.sh:15-28` (a project needs `Target branch`, `Worktree root`, `Entry mode`, `Max attempts`, `Merge mode`, `Ship confirmation` in `AGENTS.local.md` and a committed `docs/stories.md`). Three functions, named after the criteria:
   - `test_short_subject_counts_as_shipped` — the shared sentence is found (`grep -F`) in both `method/commands/po-status.md` and `method/commands/po-drive.md`; and `method/hooks/po-session.sh`'s `read_shipped` body (extracted with `awk` from `read_shipped()` to the closing `}`) contains `^s[0-9]+:`.
   - `test_short_subject_is_exact` — stories `s1-a`, `s10-x`, `s100-y` (no dependencies); empty commits `s1: a` and `s10-autre: b`; `po-session` prints exactly the line `Ready stories: s10-x, s100-y (Owns not checked: /po-drive decides)`.
   - `test_session_lists_no_short_shipped_story` — stories `s01-x` and `s02-y` with `- **Depends on**: s01-x`; an empty commit `s01: x`; `po-session` prints exactly `Ready stories: s02-y (Owns not checked: /po-drive decides)`, which shows both the story and its dependent read the rule.
   Run `bash tests/run.sh short-subject-shipped.test.sh project-lead.test.sh resume.test.sh`.
5. [x] **Full suite** through `po-run --story s112-short-subject-shipped --label test -- 'bash tests/run.sh'`, once all tasks are done (`Full suite: execute-end`). `overlap.test.sh` must stay green: the sentence is written fresh.

The shared sentence, verbatim in both commands (Tasks 2 and 3; the test greps it exactly):

> a story `s<n>-<slug>` is shipped when a commit on `Target branch` or `origin/<Target branch>` has a subject starting with `<id>:`, or, when no commit does, with `s<n>:` exactly, its number written as the id writes it

## Scene viewpoints
—

## Run interdicts
- `.claude/` and `.polype/` end with an empty diff (installed copies; change `method/` only).
- The output lines of `po-session` keep their exact text: `Ready stories: …`, `Lanes in flight: …`, `Waiting for a human: …` (`method/hooks/po-session.sh:161-175`, `:211-214`); `tests/project-lead.test.sh` passes unchanged.
- `po-session` stays read-only and makes one `git log` call in `read_shipped`; no `git fetch`, no write.
- `method/commands/po-drive.md` changes only at lines 31 and 68, the rest of the file being out of scope; the right cell `nothing — the story is done` is unchanged.
- `docs/stories.md` is not edited (no "Livrée" mark: the option the owner turned down).
- No existing test file is modified.

## Files touched
- `method/hooks/po-session.sh`
- `method/commands/po-status.md`
- `method/commands/po-drive.md`
- `tests/short-subject-shipped.test.sh` (new)
- `docs/plans/s112-short-subject-shipped.md`, `docs/verif/s112-short-subject-shipped.md`

## Test strategy
Three tests, budget 25. The rule lives in `read_shipped` and its readers, so two behavioural tests run the real hook on a throwaway repository, through the same entry point the session uses: removing the short-subject loop makes `test_session_lists_no_short_shipped_story` list `s01-x`; matching on a prefix (`s1` against `s10…`) makes `test_short_subject_is_exact` drop `s10-x`; reading `SHIPPED` directly for dependencies makes the first test drop `s02-y`. The text test bites if either command loses the sentence. No test per reader site: the dependency case already covers the second reader, and the `:204` line needs a remote ref and a human confirmation that would only replay the same helper.

## Done when
The three criteria hold, the full suite is green through `po-run`, the review has no open critical finding, and the story lands as one commit `s112-short-subject-shipped: Une story livrée sous un sujet court compte comme livrée` through its pull request. After landing, `po-session` on this repository no longer lists s01 to s10 as ready.
