# Research — s134-everything-to-handle-is-an-issue

[Story](../stories.md)

## Structuring facts
- **False: no later proof of a human merge exists in `/po-drive`.** A shipped story is never ready (`method/commands/po-drive.md:34`), so no wave reopens its lane; `method/commands/po-drive.md:148` only says cleanup "waits for its pull request to print `MERGED`", and nothing runs it. The story must add that revisit, or `ship_files_open_findings` never fires for a person-merged pull request.
- **False: "only a person turns a finding into a story" is not in Law 7 today.** `method/AGENTS.md:125` says "only a person turns one into an issue or a story"; the kept half must be written as the criterion words it, not "kept word for word".
- **False: `/po-setup` cannot add a question for `Issue tracker` without renaming its Step 2 heading**, which `tests/framing-commands-cleanup.test.sh:27` quotes whole (outside `Owns`). Setup writes the value from the forge reading with no question, and names it in its last message.
- No command reads `Issue tracker` (`grep` of `method/`: only `method/AGENTS.md:125`, `method/templates/agents-local.md:23,56`, `method/templates/stories.md:14`). Filing is prose an agent follows in `/po-ship`; no script, no test that reaches a forge.
- A finding carries no lens tag: findings are `- <severity> — <path:line>: <problem>` (`method/templates/review.md`, `## Findings`; `docs/reviews/s125-ship-and-fleet-cleanup.md:77`); the security lens shows only in the free-text `Lenses run:` line.

## Story
The lead and the fleet file in `Issue tracker` every idea, feature or defect to handle, and every finding a shipped review leaves open, so nothing to do lives only in a conversation, a log or a review. Criteria:
- `law_files_everything_to_handle` — Law 7 says anything to handle, whoever raised it and wherever noted, is filed at once by the lead with its context; under `—` it goes to the person. The "issue" half of "only a person turns one into an issue or a story" goes; "only a person turns a finding into a story" holds; heading unchanged. `## What goes to the person` keeps the out-of-scope idea and adds it is also filed.
- `ship_files_open_findings` — after the merge proof of `/po-ship` Step 3, and when `/po-drive` proves a person's merge later, each open major/minor of the last review becomes an issue titled `<id>: <severity> — <start of finding>`, body naming story, review, severity; no duplicate open title. `github` → `gh` on the github.com repository of `origin`, ADR-0083; `gh` missing or not logged in → nothing filed, reported. `taskwarrior` → `project:<repo name> +issue`. `—` → nothing filed, reported. One test holds the three values.
- `security_goes_to_the_person` — a Security-lens finding or a security idea is never filed alone; it goes to the person (ADR-0077).
- `setup_proposes_the_forge` — `/po-setup` proposes `github` for an `origin` on github.com, `taskwarrior` otherwise or with no remote, writes it; the template row says ideas, features and defects; every reader lists it in `Reads settings:`; Polype's `AGENTS.local.md` holds `Issue tracker: github`.
- `adr_records_the_rule` — ADR-0090: the rule, options turned down (only the person files; only defects; security filed too), and what `—` means.

## Current code
- `method/AGENTS.md:123-125` — Law 7: stories describe the product; a bug goes to `Issue tracker`; review findings are traced where found; only a person makes an issue or a story of one.
- `method/AGENTS.md:69-71` — three motives to reach the person; the second "a new idea outside the approved scope, whoever brought it up"; security is a strategic decision (third motive).
- `method/commands/po-ship.md:11` — `Reads settings:` lacks `Issue tracker`. `:20` stops when any listed setting is missing. `:22` a hand-merged pull request goes "straight to cleanup". `:29` GitHub read: `gh api --hostname github.com`, else `curl` with `GH_TOKEN`/`GITHUB_TOKEN`. `:51` the review is committed on `story/<id>` in Step 1. `:83-86` Step 3: 1 proof (`MERGED` / ancestry), 2 worktree removed if clean (else stop), 3 branch deleted. `:88` finish lines.
- `method/commands/po-drive.md:14` — `Reads settings:` lacks `Issue tracker`; `:23` stops on a missing listed setting. `:65` waiting-for-human-merge row. `:143-150` ships one at a time; `:148` human merge under `pr` "is not the landing". `:152-157` decisions log. `:159-166` report. `:168` `status` launches nothing.
- `method/commands/po-setup.md:13` `Reads settings: none` (it creates the file). `:27` Step 1 reads the forge of `origin` as `/po-ship` does. `:40` Ship confirmation follow-up. `:50` "Nothing else is asked … every other setting keeps the template's value". `:54-58` Step 3 writes.
- `method/templates/agents-local.md:23` default `Issue tracker:     github`; `:56` row "where defects are filed: `github` · `taskwarrior` · `—`".
- `AGENTS.local.md:21` Polype has `Issue tracker:     —`; origin is `git@github.com:atoll-labs-io/polype.git`.
- `method/commands/po-flow.md:91` ship = "apply `/po-ship` from its Step 0": inherits the change, no edit needed.

## Attachment points
- `method/AGENTS.md:125` (Law 7 paragraph) and `:71` (second motive).
- `method/commands/po-ship.md:11` (settings), new step in Step 3 between the proof (`:84`) and the worktree removal (`:85`) — after removal the worktree's review is gone and a stop at `:85` would skip filing; `:88` finish.
- `method/commands/po-drive.md:14` (settings), `:148` (the revisit of a person-merged lane), `## Report` (`:160`) and `status` (`:168`).
- `method/commands/po-setup.md:40-50` (Issue tracker paragraph, `:50` exception), Step 3 finish line.
- `method/templates/agents-local.md:56`; `AGENTS.local.md:21`; new `docs/decisions/ADR-0090-<slug>.md`; new `tests/everything-in-issues.test.sh`.

## Verified interfaces
- `tests/lib.sh`: `contains <file> <exact phrase>`, `require_file`, `fail`, `settings_read_by <file>`, `template_settings`; runner `tests/run.sh` runs each `test_*` in its own process.
- Section extraction is per test file: `section_of()` in `tests/any-harness-docs.test.sh:13` (whitespace-squeezed) or `tests/architect.test.sh:8`; copy one, lib.sh has none.
- `bin/po-lint` settings rule (`:85-112`): every declared setting must exist in the template — `Issue tracker` does. Fail-closed rule (`:158-180`) scans only `## Checks|Preconditions|Step 0` sections: an arrow line naming an absence there must say stop/ask/carry on.
- `gh issue list --repo HOST/OWNER/REPO --state open --search … --json title` and `gh issue create --repo HOST/OWNER/REPO --title … --body …` take a `[HOST/]OWNER/REPO` form, which pins the host; `gh auth status --hostname github.com` tells logged in (honours `GH_TOKEN`). Both on this machine (`/usr/bin/gh`, `/usr/bin/task`) — tests must not call them.
- Taskwarrior: `task add … -- <text>` makes everything after `--` description, so an `s134:` prefix is not parsed as an attribute; `rc.verbose=new-uuid` prints the new uuid for `task <uuid> annotate`.
- Review file: several loops each end with `Max severity:` / `Ship allowed:`; the last review is the block after the previous `Ship allowed:` line (`docs/reviews/s125-ship-and-fleet-cleanup.md:76-86,171-181`). Lens line examples: `Lenses run: none. … no security … path` and `Lenses run: Security, triggered by …` — the word "security" appears even in `none` lines.

## Traps
- Tests that quote the owned files and must stay green: `tests/structure.test.sh:51` (Law 7 heading), `tests/escalation-contract.test.sh:31` ("a new idea outside the approved scope"), `tests/ship.test.sh:17` ("Cleanup, only after proof"), `tests/ship.test.sh:33` ("go straight to cleanup"), `tests/framing-commands-cleanup.test.sh:27` (Step 2 heading of po-setup), `tests/setup-modes.test.sh:36` ("Nothing else is asked", five numbered questions), `tests/ship-follows-forge.test.sh:24`, `tests/structure.test.sh:25` (every read setting in the template).
- `method/skills/agentic-stories/SKILL.md:53` ("unless a person turns one into a story") and ADR-0068 rely on the story half of Law 7: keep it.
- Repository name for Taskwarrior: in a worktree `git rev-parse --show-toplevel` is the worktree folder (`.worktrees/<id>`); take the last path segment of `origin` without `.git`, or with no remote the parent of `git rev-parse --path-format=absolute --git-common-dir`.
- Rerunning `/po-ship` after a stop at Step 3.2 must not file twice: dedupe on an exact open title. Two findings of one review with the same title start would collide: group them in one issue.
- `—` in the `Lenses run:` sense: a line starting `none` that mentions "security" is not the security lens.
- `tests/overlap.test.sh` fails a `method/` line sharing 8+ words with Killer SaaS: write fresh prose.
- The root `AGENTS.md`, `.claude/` and `.polype/` are installed copies, refreshed by the lead after the milestone (commit `60f2052`): not this story's.
- No migration, no dependency, no screen.

## Open questions
- Is "proposes" in `setup_proposes_the_forge` satisfied by writing the forge-derived value with no question and naming it in the final message? Research says yes (test-quoted heading); the plan decides.
- How a shipping agent tells a "security" finding in a review whose lens line is `none`: by its text bearing on security (secret, token, authorization, injection). Judgment, not a parse; the plan names it.
- Should `/po-drive` revisit a person-merged lane at the start of a wave or in the ships section? The plan decides; `status` must stay read-only either way.

## Complexity
3 → 3. Five method files, one settings file, one ADR, one test file; the only non-obvious work is the `/po-drive` revisit the story assumed existed, and the ordering inside Step 3.

## Split
Not needed.
