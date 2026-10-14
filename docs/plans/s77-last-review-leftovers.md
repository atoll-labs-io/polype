---
validated: yes
---
# Plan — s77-last-review-leftovers

[Story](../stories.md) · [Research](../research/s77-last-review-leftovers.md)

Branch `story/s77-last-review-leftovers`. Read `docs/research/s77-last-review-leftovers.md` first; this plan builds on it without repeating it. ADR-0053 (`docs/decisions/ADR-0053-dev-fd-1-et-2-valent-stdout-et-stderr.md`) is already written by the planner and settles the `/dev/fd` rule; the implementer commits it with the code and does not rewrite it.

Track: full. The story is rated 2 (≤ `Flow threshold`), but `po-bounds` is the access policy of the subagents and AC1 widens what it allows: the "authorization scope" signal.

## Story
Close the open minors of the M7-bis reviews: readable `po-bounds` refusals and `/dev/fd/1|2` (s76 m1, m2), the reviewer told the hook is a guard (s76 "Not verified"), Law 6 and the ADR template aligned with `po-architect` (s75), lighter overlap wording in `po-status` and check 8 (s72).
ACs: `refusal_messages_are_readable`, `reviewer_knows_the_hook_is_a_guard`, `adr_links_are_the_only_edit`, `overlap_wording_is_light` (`docs/stories.md:1186-1189`).

## Tasks
1. [x] **Hook: readable refusals and `/dev/fd/1|2`** (`method/hooks/po-bounds.sh`).
   - Add a helper after `join_dir` (`:297`) that prints its argument with each `\036` replaced by `<substitution>`. Hold the byte in a local first (`local m=$'\036'; printf '%s' "${1//$m/<substitution>}"`), not inline in the expansion.
   - `check_redirects` deny `:646`: print `$(<helper> "$r")` instead of `$r`. `check_temp_paths` deny `:631`: print `$(<helper> "$a")` instead of `$a` (same defect, same message family; the s76 review wrongly thought it immune, research "Probe").
   - Allowlist `:645` becomes `/dev/null|/dev/stdout|/dev/stderr|/dev/fd/1|/dev/fd/2) continue ;;`. No other `/dev/fd/<n>`; nothing resolved by `readlink`.
   - Comments `:27-29` and `:640` list the five targets and cite ADR-0053 once (in the header).

   Failing test: `test_refusal_messages_are_readable` (task 6). Unchanged: `test_redirections_are_not_git_paths`, `test_temp_zone_verbs_keep_their_paths_in_temp`.
2. [x] **ADR-0052 back-link.** In `docs/decisions/ADR-0052-po-bounds-est-un-garde-fou-contre-les-erreurs.md`, line 9 `superseded-by: []` → `superseded-by: [ADR-0053]`. No other line of that file changes. It sits outside `Owns` (a docs/ path), named here so the reviewer's scope check can place it; it is exactly the edit task 4 makes the rule.

   Failing test: `test_refusal_messages_are_readable` checks the two links. `test_bounds_threat_model_is_written` stays green (it reads only `supersedes:` and `status:`).
3. [x] **Reviewer Limits** (`method/agents/reviewer.md:35`). Append, at the end of the paragraph, after "the review is blocked.":
   > The hook guards against your mistakes, not against a deliberate bypass (ADR-0052). A bypass ADR-0052 already lists and accepts is not a finding. A new one you notice is a finding that points to ADR-0052 and asks for a new ADR adding it to that list; it never asks for a fix to the hook.

   Delete nothing: `bounds.test.sh:411,575-577` pin phrases of this paragraph.
   Failing test: `test_reviewer_knows_the_hook_is_a_guard`.
4. [x] **Law 6 and the ADR template.**
   - `method/AGENTS.md:96`: keep the first sentence (pinned by `adr-directory.test.sh:19`) and replace "An accepted ADR is never edited; a new ADR supersedes it." with:
     > An accepted ADR is never rewritten: a new ADR supersedes it, and only its frontmatter links, `supersedes` and `superseded-by`, ever change — plus its `status`, set to `superseded` when the new ADR replaces it wholly.

     The `status` clause keeps Law 6 equal to `po-architect.md:48`.
   - `method/templates/adr.md`: the `supersedes:` and `superseded-by:` lines become bare (`supersedes: []`, `superseded-by: []`). Their explanation moves to one YAML comment line just above them:
     > `# supersedes: ADRs this one replaces, wholly or in part; superseded-by: ADRs replacing this one, wholly or in part. Keep both lines free of comments.`

     Leave the `status:` line and its comment ("replaced only in part" is pinned by `post-m7-texts.test.sh:31`).

   Failing test: `test_adr_links_are_the_only_edit`.
5. [x] **Overlap wording.**
   - `method/commands/po-status.md:36`: replace "an `Owns` collision, with the path that collided, the lane holding it, and the two entries that overlapped by the overlap rule of check 8 of the `stories-review` skill with one path matching both;" with:
     > an `Owns` collision, judged by the overlap rule of check 8 of the `stories-review` skill, with the path that collided, the lane holding it, the two entries that overlapped and one path matching both;
   - `method/skills/stories-review/SKILL.md:25`: replace "Two stories with no dependency between them that share an `Owns` path are flagged as critical" with "Two stories with no dependency between them whose `Owns` entries overlap are flagged as critical". The rest of the sentence stays.
   - `tests/stories-review.test.sh:34`: the pin follows the new sentence. The story changes this clause, so the pin may move.

   Failing test: `test_overlap_wording_is_light`. Also green: `owns-overlap.test.sh` `test_every_overlap_text_cites_the_rule` (the citation phrase stays in `po-status.md`).
6. [x] **Tests.**
   - In `tests/bounds.test.sh`, after `test_bounds_threat_model_is_written`, add `test_refusal_messages_are_readable`:
     - `reviewer_lane`.
     - For `git -C $TMPROOT/probe log > >(cat)` and `git -C $TMPROOT/probe log > \$(echo x)/y`: exit 2. Its stderr, captured as `printf '%s' "$(hook_input Bash command "$c")" | bash "$BOUNDS" reviewer 2>&1 >/dev/null || true`, holds no `$'\036'` byte and holds `redirects to <substitution>`.
     - Exit 0 for `… log >/dev/fd/1` and `… log 2>/dev/fd/2`; exit 2 for `… log >/dev/fd/3`.
     - ADR-0053's `supersedes:` names ADR-0052, ADR-0052's `superseded-by:` names ADR-0053, and ADR-0052 keeps `status: accepted`.
   - New `tests/final-leftovers.test.sh` (header comment `# s77 — the last review leftovers.`) with:
     - `test_reviewer_knows_the_hook_is_a_guard`: `contains` on `reviewer.md` for "guards against your mistakes", "(ADR-0052)", "already lists and accepts is not a finding" and "never asks for a fix to the hook".
     - `test_adr_links_are_the_only_edit`: `contains` the Law 6 phrase "only its frontmatter links, `supersedes` and `superseded-by`, ever change", and the old "An accepted ADR is never edited;" is absent. The template's `frontmatter` holds the exact lines `supersedes: []` and `superseded-by: []` (`grep -qx`), and no `supersedes:`/`superseded-by:` line holds `#`.
     - `test_overlap_wording_is_light`: `po-status.md` holds the new clause of task 5 and no longer holds "overlapped by the overlap rule"; `SKILL.md` holds "whose `Owns` entries overlap are flagged as critical" and no longer holds "share an `Owns` path".
   - Focused: `bash tests/run.sh bounds.test.sh final-leftovers.test.sh stories-review.test.sh owns-overlap.test.sh post-m7-texts.test.sh pilot.test.sh adr-directory.test.sh`.
   - Then the full suite once: `po-run --story s77-last-review-leftovers --label full-suite -- 'bash tests/run.sh'`. It includes `overlap.test.sh`, so every new sentence must be written fresh.

## Run interdicts
- `method/hooks/po-bounds.sh`: only the new helper, the deny lines `:631` and `:646`, the `case` at `:645` and the comments `:27-29`, `:640` change. `lex_command`, `step_dir`, `resolve_path`, `check_git_read`, `check_restore`, `check_config_key`, `check_bash` and `QA_GIT_VERBS` keep an empty diff.
- ADR-0052: one changed line, `superseded-by:`. ADR-0053: no change by the implementer. No other file under `docs/decisions/` changes.
- `method/commands/po-architect.md`, `method/commands/po-drive.md`, `method/skills/agentic-stories/SKILL.md` and `docs/installation.md` keep an empty diff. The s72 minor on agentic-stories and the s76 m3 (`{fd}>`) stay out of scope.
- `.claude/`, `.polype/` and the root `AGENTS.md` keep an empty diff. They are refreshed after ship.
- Existing tests: only `tests/stories-review.test.sh:34` changes, plus one function added to `tests/bounds.test.sh`.
- No `git switch`, `checkout`, `stash`, or `worktree add`.

## The pivot
`/dev/fd/1` and `/dev/fd/2` are allowed **by their exact spelling**, as the existing three are, and recorded by ADR-0053 because they change ADR-0052's list. Ways it could be wrong:
- **Bash's reading.** Bash treats `/dev/fd/N`, `/dev/stdout` and `/dev/stderr` itself in redirections, whatever the OS, so the equivalence is bash's own. If a platform's bash did not, the fd would still be 1 or 2 of the same shell. *Compare:* bash manual, REDIRECTION.
- **Other spellings** (`/dev/fd//1`, `/dev/./fd/1`, `/dev/fd/01`) fall to `resolve_path` and stay refused. This fails closed and is accepted. *Compare:* probe them in review; they must exit 2, never 0.
- **The track.** Reading `po-bounds` as authorization scope is a judgment call. If it is wrong, the cost is only a research file.

The second decision the reviewer should weigh is the Law 6 wording. It keeps the `status: superseded` flip that `po-architect.md:48` allows, which the AC wording leaves out.

## Files touched
- `method/hooks/po-bounds.sh`
- `method/agents/reviewer.md`
- `method/AGENTS.md`
- `method/templates/adr.md`
- `method/commands/po-status.md`
- `method/skills/stories-review/SKILL.md`
- `tests/bounds.test.sh`
- `tests/stories-review.test.sh`
- `tests/final-leftovers.test.sh` (new)
- `docs/decisions/ADR-0052-…md` (frontmatter line 9)
- `docs/decisions/ADR-0053-…md` (new, by the planner)
- `docs/research/s77-…md`, `docs/plans/s77-…md`, `docs/verif/s77-…md`

## Test strategy
There are 4 new tests and 1 pin moved, within the `Test budget` of 25.
- **Behaviour:** one hook test, `test_refusal_messages_are_readable`, at the hook's own layer. It feeds JSON to the script. It bites on:
  - removing the `\036` replacement (the byte reappears, `<substitution>` disappears);
  - removing the `/dev/fd/1|2` case (the hook exits 2 instead of 0);
  - widening the case to `/dev/fd/*` (`/dev/fd/3` exits 0).
- **Texts:** three phrase tests, one per text AC. Each has a positive phrase and an absent old phrase, so restoring the old text fails it.
- No test for the `check_temp_paths` message. It is the same helper, and the redirection case proves it.
- No type check, E2E or build: all are `—`.

## Done when
- One commit on `story/s77-last-review-leftovers` with the code, the tests, ADR-0053, the ADR-0052 back-link, and the research, plan and verif record.
- The full suite is green through `po-run`.
- A review with no open critical finding, then a squash on `main`.
