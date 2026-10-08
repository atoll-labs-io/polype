# Research — s77-last-review-leftovers

## Structuring facts
- **Unstated by the story:** ADR-0052 (accepted) fixes the redirection allowlist to `/dev/null`, `/dev/stdout`, `/dev/stderr` (`docs/decisions/ADR-0052-po-bounds-est-un-garde-fou-contre-les-erreurs.md:40`). Adding `/dev/fd/1|2` changes an accepted decision → ADR-0053 (written by the planner) supersedes it in part, and ADR-0052's `superseded-by:` gets `[ADR-0053]`, a docs/ path outside `Owns`.
- **Track:** complexity 2 ≤ `Flow threshold` 2, but po-bounds is the subagents' access policy and AC1 widens what it allows → "authorization scope" signal → full track.
- The raw byte comes from the lexer: a substitution leaves `\036` in the word (`method/hooks/po-bounds.sh:313`); `check_redirects` prints `$r` as is (`:646`), and so does `check_temp_paths` with `$a` (`:631`) — the s76 review said the latter avoids it; it does not (probe below).
- The AC1 test needs the reviewer helpers of `tests/bounds.test.sh` (`reviewer_lane` `:378`, `rev_bash` `:388`); `tests/run.sh:11` loads each file alone, so that test lives in `bounds.test.sh`, the three text ACs in the new `tests/final-leftovers.test.sh`.
- Two existing pins move with their clause: `tests/stories-review.test.sh:34` (check 8 sentence). `tests/adr-directory.test.sh:19` pins the first sentence of the Law 6 ADR bullet, which stays.

## Story
Close the open minors of the M7-bis reviews: s76 m1/m2 (po-bounds messages, `/dev/fd/N`), s76 "Not verified" (reviewer Limits framing), s75 (Law 6 vs `po-architect`, ADR template comments), s72 (`po-status` heavy clause, check 8 wording).
ACs (`docs/stories.md:1186-1189`): `refusal_messages_are_readable`, `reviewer_knows_the_hook_is_a_guard`, `adr_links_are_the_only_edit`, `overlap_wording_is_light`.

## Current code
- `method/hooks/po-bounds.sh`
  - header `:27-29` lists the allowlist "/dev/null, /dev/stdout or /dev/stderr".
  - `resolve_path` `:103-122` refuses any symlink (`:106` "`$path is a symbolic link`").
  - `check_temp_paths` `:618-636`: a candidate holding `\036`, `$` or leading `~` → deny "git <verb> names $a, a path the reviewer cannot read" (`:631`).
  - `check_redirects` `:639-653`: comment `:640`; allowlist `case` `:645`; substitution deny `:646` prints `$r`; relative-without-dir deny `:648`; resolve `:650`; outside-temp deny `:651`. Called only in the temp-zone branch, `check_bash` `:742`.
- `method/agents/reviewer.md:35`: "A hook holds these limits …"; ends "A po-bounds refusal is a stop: … the review is blocked." No mention of ADR-0052, mistakes vs bypass, or what to do with a found bypass.
- `method/AGENTS.md:96` (Law 6): "… An accepted ADR is never edited; a new ADR supersedes it."
- `method/commands/po-architect.md:48`: an ADR replaced in part keeps `accepted`, "only these frontmatter links of an accepted ADR ever change"; a wholly replaced one gets `status: superseded`.
- `method/templates/adr.md:4,7,8`: comments on `status:`, `supersedes: []`, `superseded-by: []`.
- `method/commands/po-status.md:36`: "an `Owns` collision, with the path that collided, the lane holding it, and the two entries that overlapped by the overlap rule of check 8 of the `stories-review` skill with one path matching both;".
- `method/skills/stories-review/SKILL.md:25`: "Two stories with no dependency between them that share an `Owns` path are flagged as critical: run side by side, they would edit the same files."

## Probe (method/hooks/po-bounds.sh fed JSON, reviewer mode, gawk)
| Command (probe = git repo under `$TMPDIR`) | stderr |
| --- | --- |
| `git -C <probe> log > >(cat)` | `redirects to ^^, a path the reviewer cannot read` (`^^` = `\036`) |
| `git -C <probe> log > $(echo x)/y` | `redirects to ^^/y, …` |
| `git -C <probe> log >/dev/fd/1` | `/dev/fd/1 is a symbolic link` (Linux: `/dev/fd` → `/proc/self/fd`) |
| `git -C <probe> log 2>/dev/fd/2` | `/dev/fd/2 is a symbolic link` |
| `git -C <probe> log >/dev/stdout` | allowed |
| `git -C <probe> init $(echo x)` | `names ^^, a path the reviewer cannot read` |

On macOS `/dev/fd/1` is not a symlink: it resolves to `/dev/fd/1`, outside temp → "lies outside the temp dir". Not run here.

## Attachment points
- `check_redirects` `case` `:645` (allowlist) and deny `:646`; `check_temp_paths` deny `:631`.
- A small helper next to `join_dir` (`:297`) rendering `\036` readable.
- Comments `:28-29`, `:640`.
- `reviewer.md:35`, end of paragraph. `AGENTS.md:96`. `adr.md:7-8`. `po-status.md:36`. `SKILL.md:25`.

## Verified interfaces
- `deny()` `po-bounds.sh:53`: echoes `po-bounds: $*` to stderr, exit 2.
- `hook_input` `tests/bounds.test.sh:34`, `status_with` `:40`, `expect` `:47`; `reviewer_lane` sets `TMPROOT`, `TMPDIR`, a probe repo at `$TMPROOT/probe` (`:378-385`); `rev_bash` `:388`.
- No stderr helper for reviewer mode exists (`bounds_stderr` `:42` is implementer only).
- `frontmatter`, `contains`, `require_file` `tests/lib.sh:13,41,43`.
- `section_of` / `holds` are redefined per test file (e.g. `tests/owns-overlap.test.sh:12-13`), not in `lib.sh`; a new file defines its own if needed.

## Traps
- `tests/owns-overlap.test.sh:61-70` `test_every_overlap_text_cites_the_rule`: `po-status.md` must keep the phrase "the overlap rule of check 8 of the `stories-review` skill".
- `tests/post-m7-texts.test.sh:31` and `tests/pilot.test.sh:49-53`: the ADR template must keep "replaced only in part", "## Considered Options", "superseded-by".
- `tests/adr-directory.test.sh:19`: keeps "Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`".
- `tests/bounds.test.sh:411,575-577` pin phrases of `reviewer.md:35` ("A po-bounds refusal is a stop", "git branch --merged", "merge-base --is-ancestor", "file://"): add text, delete none.
- `tests/bounds.test.sh:613-635` (`test_bounds_threat_model_is_written`) checks ADR-0052 `supersedes:` exactly and `status: accepted`; changing its `superseded-by:` does not break it.
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS; write new sentences fresh.
- Bash 3.2 (macOS): to stay clear of ANSI-C quoting inside a quoted `${…//…}` (not verified on 3.2 here), put the byte in a local first, as a precaution.
- No migration; no dependency; `jq`/awk unchanged.
- The installed copies `.claude/`, `.polype/` and root `AGENTS.md` are refreshed after ship, never in a story.

## Open questions
- Should Law 6 mention the `status: superseded` flip of a wholly replaced ADR, which `po-architect.md:48` allows and the AC wording ("ne change que dans ses liens de frontmatter") omits? Plan decides: yes, in the same sentence, so the two texts agree.
- Placeholder text for a substitution in a message: plan decides `<substitution>`; the full original command already ends every message.
- ADR-0052's `superseded-by` edit is outside `Owns` (docs/ only); the plan names it so the reviewer's scope check can place it.

## Complexity
Story 2 → 2. Four local edits and one hook rule; the only extra is ADR-0053 and its back-link.

## Split
Not needed.
