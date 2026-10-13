---
validated: yes
---
# Plan — s107-forge-token-bound-to-host

Branch `story/s107-forge-token-bound-to-host`. Read `docs/research/s107-forge-token-bound-to-host.md` first; this plan builds on it without repeating it.

**Waiting for the owner.** The research found the story's assumption false: `glab` (and probably `tea`) prefers a token from the environment over the one stored for the host, for every host. How to close that is a security choice the story does not settle, so it goes to the owner (ADR-0077). Options, ranked in the proposed `docs/decisions/ADR-0083-un-jeton-ne-part-que-vers-l-hote-qui-l-a-emis.md`:

| Rank | Option | Verdict |
| --- | --- | --- |
| A | Call `glab` / `tea` with their token variables removed from the environment, host pinned | recommended — closes the leak, keeps reading for anyone logged in to the right host |
| B | A token variable in the environment makes GitLab/Forgejo unreadable | safe, but blocks a person who has both the variable and a correct login |
| C | Trust the CLI as is (story text to the letter) | rejected — the leak stays whenever `GITLAB_TOKEN` is exported |
| D, E | `*_HOST` binding; keep the fallback | already rejected by the owner on 2026-10-13 |

This plan is written for **A**. On **B**, task 2 swaps its GitLab/Forgejo sentences for "a set `GITLAB_TOKEN`, `GITLAB_ACCESS_TOKEN`, `OAUTH_TOKEN`, `GITEA_TOKEN`, `TEA_HOST` or `GITEA_INSTANCE_URL` → that forge is unreadable, and the report names the variable", and task 3's second test checks that sentence instead. Once decided, set ADR-0083 to `accepted` (or rewrite it for B) and `validated: yes` here.

## Story
A forge token only goes to the host that issued it. Criteria (exact test names):
- `env_token_only_for_github` — in `## The forge's review rule` of `/po-ship`, the `curl` fallback with an environment variable exists for github.com only (`GH_TOKEN` or `GITHUB_TOKEN`); `GITLAB_TOKEN` and `GITEA_TOKEN` are no longer cited as a fallback.
- `other_forges_through_their_cli_only` — GitLab and Forgejo/Gitea are read only through `glab` / `tea`, each token bound to its host; no CLI configured for `origin`'s host → the forge is unreadable and the report says so.
- `unknown_host_gets_no_token` — the `/api/v1/version` probe goes without a token, and no call to an unrecognised host carries one.

## Tasks
1. [x] **Which forge** — `method/commands/po-ship.md:27`. Keep the sentence as it is (its phrases are checked by `tests/ship-follows-forge.test.sh:31`) and append, word for word:
   `The probe carries no token: plain \`curl\`, no header, no \`.netrc\`. No call to an unrecognised host carries a token.`
   Test able to fail: `test_unknown_host_gets_no_token`.
2. [x] **How it is read** — replace the whole paragraph `method/commands/po-ship.md:29` with this text (own words, wording may be polished but the quoted phrases stay verbatim):
   - `**How it is read.** A token only ever goes to the host that issued it.`
   - GitHub: `` `gh api --hostname github.com` `` when `gh` is installed and logged in; otherwise `` `curl` on `https://api.github.com` with `GH_TOKEN` or `GITHUB_TOKEN` ``, sent in a request header, never echoed, never written to a file. These two variables are the only environment tokens this rule uses, and only because GitHub is recognised on the host `github.com` alone. Keep the sentence `No CLI and no token → the forge is unreadable.` right after (required verbatim by `tests/ship-follows-forge.test.sh:32`).
   - GitLab and Forgejo/Gitea: `read only through their CLI, logged in for the host of \`origin\``. GitLab: `` `env -u GITLAB_TOKEN -u GITLAB_ACCESS_TOKEN -u OAUTH_TOKEN glab api --hostname <host> …` `` — glab otherwise prefers those variables to the login stored for the host, whatever the host. Forgejo/Gitea: `` `env -u GITEA_TOKEN -u TEA_HOST -u GITEA_INSTANCE_URL tea api …` `` against the `tea` login whose URL is that host (check first with `` `tea api --help` `` that the installed `tea` has it).
   - `No \`glab\` or \`tea\` login for the host of \`origin\` → the forge is unreadable, and the report says which CLI and which host.`
   - No `curl` fallback for GitLab or Forgejo/Gitea, and no other token variable anywhere in the section.
   Tests able to fail: `test_env_token_only_for_github`, `test_other_forges_through_their_cli_only`.
3. [x] **Tests** — create `tests/forge-token-host.test.sh` (header comment `# s107 — a forge token only goes to the host that issued it.`), with its own `section_of` / `holds` helpers copied from `tests/ship-follows-forge.test.sh:11,13` and a `forge_section` reading `## The forge's review rule` of `$METHOD/commands/po-ship.md`. Three functions:
   - `test_env_token_only_for_github` — the section holds `` `GH_TOKEN` or `GITHUB_TOKEN` `` and `https://api.github.com`; every line of the section that mentions `curl` contains neither `GITLAB_TOKEN` nor `GITEA_TOKEN`; the number of `GITLAB_TOKEN` occurrences in the section equals the number of `-u GITLAB_TOKEN`, same for `GITEA_TOKEN` (a variable is only ever named to be removed).
   - `test_other_forges_through_their_cli_only` — the section holds `env -u GITLAB_TOKEN -u GITLAB_ACCESS_TOKEN -u OAUTH_TOKEN glab api --hostname`, `env -u GITEA_TOKEN -u TEA_HOST -u GITEA_INSTANCE_URL tea api`, and ``No `glab` or `tea` login for the host of `origin` → the forge is unreadable``.
   - `test_unknown_host_gets_no_token` — the section holds `The probe carries no token` and `No call to an unrecognised host carries a token`.
   Run `bash tests/run.sh forge-token-host.test.sh ship-follows-forge.test.sh ship.test.sh ship-through-pr.test.sh review-tree-gate.test.sh`.
4. [x] **Full suite** — once, at the end: `po-run --story s107-forge-token-bound-to-host --label test -- 'bash tests/run.sh'` (`Full suite: execute-end`). `tests/overlap.test.sh` included: the new text is in own words.
5. [x] **ADR** — commit `docs/decisions/ADR-0083-un-jeton-ne-part-que-vers-l-hote-qui-l-a-emis.md` with the story, in the status the owner gave it; commit the research and this plan too.

## Scene viewpoints
—

## Run interdicts
- `method/commands/po-setup.md` ends with an empty diff (it reads the forge "exactly as `/po-ship` reads it", `po-setup.md:27`).
- In `method/commands/po-ship.md`, only lines 27 and 29 change: `:24-26`, `:30-86` (signals, verdict, rewrite, Steps 1-3) end with an empty diff.
- `tests/ship-follows-forge.test.sh`, `tests/ship.test.sh`, `tests/ship-through-pr.test.sh` end with an empty diff and stay green.
- Nothing under `.claude/` or `.polype/` changes (installed copies).
- `docs/stories.md` is not edited by this story; the false assumption is reported to the owner, not patched there.
- No `glab`, `tea` or `curl` call to a real forge during the run.

## The pivot
Everything rests on "**the CLI binds the token to its host only once its environment token variables are removed**". Ways it could be wrong:
- glab reads another variable not in its documented precedence list (e.g. a CI job token with `GLAB_ENABLE_CI_AUTOLOGIN`); compare with glab's "Token precedence" and "Environment variables" pages. CI auto-login uses `CI_SERVER_FQDN`, the CI's own host, so it is bound — but say so if the reviewer finds otherwise.
- tea 1.0 has no `api` subcommand or names its host/login flag differently, so the Forgejo sentence describes a command that does not exist; the existing `tea api --help` check stays to catch it at run time, and the report would then say "unreadable".
- `gh api` without `--hostname` honours `GH_HOST`; pinning `--hostname github.com` is what keeps `GH_ENTERPRISE_TOKEN` out of the GitHub read. The reviewer checks the GitHub sentence pins it.
And on the test side: the counting check of `test_env_token_only_for_github` must fail if `GITLAB_TOKEN` comes back into the `curl` sentence — the reviewer's bite check reintroduces it.

## Files touched
- `method/commands/po-ship.md` (lines 27, 29)
- `tests/forge-token-host.test.sh` (new)
- `docs/decisions/ADR-0083-un-jeton-ne-part-que-vers-l-hote-qui-l-a-emis.md` (new, written at planning)
- `docs/research/s107-forge-token-bound-to-host.md`, `docs/plans/s107-forge-token-bound-to-host.md`

## Test strategy
Three bash text tests, one per criterion, in `tests/forge-token-host.test.sh` — the repository's only layer for method text (`AGENTS.local.md` conventions). 3 of 25. Each checks the clause that carries the rule: removing the env scrub, putting `GITLAB_TOKEN` back in the `curl` sentence, or dropping the probe's no-token sentence turns exactly one of them red. No test replays the existing forge-detection phrases, already held by `tests/ship-follows-forge.test.sh:31-32`. Visual checks: none (`Surface: —`).

## Done when
- The three tests and the four neighbouring ship tests green; full suite green through `po-run`.
- ADR-0083 carries the owner's decision (`accepted`), and this plan `validated: yes`.
- One commit on `story/s107-forge-token-bound-to-host`, a review with no open critical finding, then `/po-ship`.
