# Research — s192-ship-reads-the-forge

[Story](../stories.md)

## Structuring facts
- **False assumption (criterion `absence_is_not_an_error`)**: « une réponse 404 ou 403 d'un des trois signaux compte comme une absence » contradicts the rule in force. `method/commands/po-ship.md:38` and ADR-0079 (accepted, point 4 and Neutral) count as absence only a 404 for an unprotected branch, an empty list, and the 403 whose message says "Upgrade to GitHub Pro"; « Any other failure leaves that signal unreadable ». ADR-0079 tells a rights 403 from the plan 403 by its message on purpose. A rights 403 read as absence could yield `solo` on a protected repository, hence an agent merge. CODEOWNERS never gets an HTTP answer: it is read with git (`po-ship.md:35`). The plan follows ADR-0079; the wider reading goes to the person.
- **Half-true assumption (criterion `token_never_travels`)**: « les outils de forge sont lancés sans leurs variables de jeton, comme aujourd'hui » holds for `glab` and `tea` only (`po-ship.md:31`, ADR-0083 A). `gh` reads `GH_TOKEN`/`GITHUB_TOKEN` itself, and GitHub's `curl` fallback sends one of them in a header on purpose (`po-ship.md:29`, ADR-0083 Decision Outcome). Removing them would break the GitHub reading.
- `po/src/trust/forge.rs:37-48` (`gh_api`) drops the HTTP status: a 404, a 403 and an unreachable forge all give `None`. The three-way reading (positive, absent, unreadable) needs a launcher that keeps the status. `gh api -i` gives it: checked on 2026-11-18, a 404 prints `HTTP/2.0 404 Not Found` on stdout's first line (ending `\n`), then headers ending `\r\n`, a blank line, the JSON body; exit 1; stderr `gh: Not Found (HTTP 404)`.
- Today `po` makes no HTTP call and writes no git state (`po/src/project.rs:18-19`, `forge.rs:1-3`); s192 stays read-only. Whether the ship enters `po` and in which shape is the owner's choice: ADR-0130 drafted `proposed`.
- `/po-setup` reads the forge in Step 1 before `AGENTS.local.md` exists (`po-setup.md:27`); `po` finds the project through `.polype/version` (`project.rs:43`), which `polype init .` lays before `/po-setup` (`README.md:88-99`). `Target branch` is not written yet: the command needs it as an option.

## Story
`po` reads the forge and gives the effective `Ship confirmation`, so no model re-reads the forge rule at each ship (#211, part 1). Criteria: `verdict_follows_the_three_signals`, `absence_is_not_an_error`, `chosen_is_never_rewritten`, `token_never_travels`, `ship_command_reads_the_value` (model-read, ≥ 600 words fewer in `po-ship.md`, none more in `po-setup.md`), `version_goes_up` (minor).

## Current code
- `method/commands/po-ship.md:24-48` `## The forge's review rule`, 844 words of 3 302 (`LC_ALL=C wc -w`): which forge `:27`, how read `:29-31`, signals `:33-36`, absence `:38`, verdict `:40`, effective value `:42`, rewriting rule `:44`, where the rewrite goes `:46` and « The ship does not wait for that draft » `:48` (both stay until s194). `:62` « Below, `Ship confirmation` is always the effective value that section settled. » `:96` cites the section for the github.com recognition. `:103` the finish names the effective value and why.
- `method/commands/po-setup.md` (2 274 words): `:27` Step 1 reads the forge « exactly as `/po-ship` reads it »; `:40` `Ship confirmation` from that reading (collaborative → `human (forge)`, no question); `:75` the landing's merge proof cites the forge the section recognises; `:90` the effective value the section settles.
- `po/src/trust/forge.rs`: `gh_program` `:18-23` (`PO_GH` double); `github_repo` `:26-35` takes `https://github.com/`, `git@github.com:`, `ssh://git@github.com/` only, so a URL with userinfo is not recognised; `gh_api` `:37-48` (stdin and stderr null); `Forge::of` `:52-55` reads `remote.origin.url` by `git config`. Used by `po state --remote` (`trust/mod.rs:68`) and `po next --remote` (`next/mod.rs:117-120`).
- `po/src/main.rs:16-34` dispatches verbs; usage string `:20`. No `po/src/ship/` exists.
- `po/src/project.rs`: `git()` `:20-33` read-only, `GIT_OPTIONAL_LOCKS=0`; `setting()` `:55-67` first `Name:` line with a value; `on_target()` `:92-94` `git show <ref>:<path>`.
- `po/src/context/lanes.rs:188-196` strips `(forge)`/`(chosen)` and `:353-356` raises `MergeWaiting` from the line's value, not the effective one (out of scope, see Open questions).

## Attachment points
- New `po/src/ship/mod.rs` (`po ship <step>`, step `forge`) and `po/src/ship/forge.rs` (the reading); `po/src/main.rs` one arm and the usage string.
- `po/src/trust/forge.rs`: the program lookup generalised beside `gh_program` for `PO_CURL`, `PO_GLAB`, `PO_TEA`; a status-keeping API call beside `gh_api`.
- `docs/interface-agent.md:264-274` « Les verbes du chef de projet »: one row.
- Precedent for a verb with steps: `po record review|qa` (`po/src/record/mod.rs:80-100`). Precedent for feeding a child's stdin from a thread: `po/src/trust/landed.rs:17-33`.

## Verified interfaces
- `output::reply(body, code)`, `output::error(code, error, message)` (`po/src/output.rs:30-43`); codes `OK 0`, `REFUSED 1`, `UNREADABLE 2` (`:5-7`); contract error codes listed at `docs/interface-agent.md:27`, `missing-setting` at `:109`.
- `Project::find(cwd)` (`project.rs:38-48`), `Project::setting(name) -> Setting` (`:55`), `Project::on_target(target, path)` (`:92`).
- `curl -q -H @-` reads a header from stdin (checked on curl 8.23.0, 2026-11-18): the token reaches GitHub without entering an argument.
- `gh api --help`: `-i, --include` and `--hostname` exist (gh on this machine). `glab` and `tea` are not installed here: their flags (`glab api -i`, `glab auth status --hostname`, `tea api --login`, `tea logins list --output json`) are unverified, as ADR-0083's Neutral already says of `tea`.
- Crate dependencies: `serde`, `serde_json`, `chrono` only (`po/Cargo.toml`, ADR-0118); no HTTP crate. The command launches tools, as `forge.rs` does.
- Version: `0.7.0` in `po/Cargo.toml:3`, `po/Cargo.lock:164-165`, `bin/polype:28`.

## Traps
- **Tests outside `Owns` that read the two command files, and must stay green unmodified**: `tests/ship-and-fleet-cleanup.test.sh:31` (`po-ship.md:62` verbatim); `tests/framing-through-pr.test.sh:53` (`po-setup.md` landing keeps « ## The forge's review rule »); `tests/framing-second-landing.test.sh:24` (« step 3 of `/po-ship` »); `tests/framing-commands-cleanup.test.sh:26-28` (Step 1 « once question 1 of Step 2 has given `Target branch` », Step 2 « from that reading of the forge, made once `Target branch` is known »); `tests/everything-in-issues.test.sh:96-100`. Also `method/AGENTS.md:141` and `method/commands/po-intake.md:76` cite the heading.
- **Tests in `Owns` whose phrases fall** (one by one in the plan): `tests/ship-follows-forge.test.sh` (19 of its assertions), `tests/forge-token-host.test.sh` (all), `tests/ship-resumes-cleanly.test.sh:24-34`.
- Word ceilings: `tests/ship-files-the-other-findings.oracle.test.sh:9` (`po-ship.md` 3302), `tests/defects-seen-on-products.oracle.test.sh:14` (`po-setup.md` 2278); both may only go down.
- `trust-signals.*` and `ship-order-and-closed-pr.*` exercise `gh_api`, `checks`, `pull_request_closed` through `PO_GH`: their behaviour must not move.
- An `origin` URL may hold credentials (`https://user:token@host/...`): never echo it, strip userinfo before reading the host.
- `origin/<Target branch>` may be stale or missing: `po` never fetches (`project.rs:18`). Missing → the CODEOWNERS signal is unreadable.
- Collaborators are paginated; a page that comes back full without a positive entry proves nothing.
- No migration. The story changes `po/`: minor bump 0.7.0 → 0.8.0 in three places (ADR-0122), checked by `bin/po-version-check`.

## Open questions
- Does the owner keep ADR-0079's reading of 403 and 404, or widen it as the criterion writes? (The plan and oracle follow ADR-0079; the oracle tests no contested case.)
- `glab api` `:id` placeholder, `tea` login selection: unproven on a real instance (#75 `parked`). The command implements what `po-ship.md:31-36` says, through doubles only.
- `po next` raises `MergeWaiting` from the line, not the effective value (`lanes.rs:355`): a collaborative repository with `automatic` never gets that stop. Outside `Owns`; to be filed by the lead.
- Does `/po-ship` stop when `po` is missing, or ship on the line's value as an unreadable forge? The plan has it stop, as `/po-drive` does (`po-drive.md:25`).

## Complexity
4 → 4. One read-only step, but three forges, a status-keeping launcher, a token fallback through stdin, and two command files under tests outside `Owns`.

## Split
—
