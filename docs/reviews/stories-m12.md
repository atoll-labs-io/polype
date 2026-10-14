# Stories review: Polype, milestone "M12 — Tout ce qui est à traiter devient une issue" (s134)


A one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). Done on 2026-10-14 by the `stories-reviewer` subagent, in a context that did not write the story. The answer is recorded verbatim.

- **Scope source:** the milestone's Objectif paragraph (owner decision of 2026-10-14).
- **Platform:** `cli`.

## Loop 1

Review status: complete

There are no critical findings. Three findings are major and should be fixed before s134 is planned: the GitHub token rule misreads ADR-0083, the edit to Law 7 also drops the rule on stories, and nothing covers security findings filed on a public tracker.

Files read: `docs/stories.md` (lines 2080–2098, with M11 for the `Owns` comparison); the ADRs 0083, 0018 (and 0003, which it supersedes), 0068, 0077; `method/AGENTS.md` (Law 7 and `## What goes to the person`); `method/templates/agents-local.md`, `method/commands/po-ship.md:29`, `method/commands/po-flow.md:91`.

### Coverage

| Item from the Objectif | Stories | Covered |
| --- | --- | --- |
| An idea for a change, a feature or a defect to handle becomes an issue, whoever brought it up (conversation, subagent, lead) | s134 (`law_files_everything_to_handle`) | yes, as a rule in Law 7 |
| Findings left open in a review become issues | s134 (`ship_files_open_findings`) | yes |
| Items that sit only in the decisions log or in memory become issues | s134 (`law_files_everything_to_handle`, "quel qu'en soit l'auteur") | partly: only the general phrase covers it, no criterion names the decisions log |
| On Polype and on every project that uses it | s134 (`method/AGENTS.md`, `setup_proposes_the_forge`, Polype's `AGENTS.local.md` set to `github`) | yes |
| Finding: no command reads `Issue tracker` | s134 (`/po-ship`, `/po-setup`) | yes |
| Finding: minor findings accepted at ship are traced only in reviews and the log | s134 (`ship_files_open_findings`) | yes |

The story traces to the Objectif and brings back nothing the Objectif keeps out. The dependency, id, complexity (3, with 4 criteria) and surface checks pass: `command` is admitted on `cli`, and the id s134 is unique and follows s133.

### Findings

**major — s134, `ship_files_open_findings` and its notes: they misread ADR-0083 and the `/po-ship` path they say to reuse.** The criterion says: "Avec `github`, le dépôt passe par la CLI de la forge sans les variables de jeton (ADR-0083)". The note says `/po-ship` "retire les variables de jeton pour `gh` (ADR-0083)". Both are wrong. ADR-0083 strips the token variables only for `glab` and `tea`. It explicitly keeps GitHub's fallback through `GH_TOKEN` or `GITHUB_TOKEN`, because github.com issues them. `method/commands/po-ship.md:29` does exactly that: `gh api --hostname github.com`, otherwise `curl` with `GH_TOKEN` or `GITHUB_TOKEN`. Read literally, the criterion has the implementer unset `GH_TOKEN` for `gh issue create`. Filing would then fail for anyone authenticated only by that variable, and the story would diverge from the accepted ADR and from the very path it says to reuse. To fix: restate the rule as ADR-0083 has it (the token only goes to the host that issued it, and filing is pinned to the github.com repository of `origin`); say what happens when `gh` is missing or not logged in; correct the note.

**major — s134, `law_files_everything_to_handle`: the deleted sentence also carries the rule on stories.** The criterion deletes "only a person turns one into an issue or a story" whole. The Objectif concerns issues only. The "or a story" half is what three files rest on: ADR-0068 (accepted): "sauf quand une personne en fait une story"; `method/skills/agentic-stories/SKILL.md:53`: "unless a person turns one into a story"; `method/skills/stories-review/SKILL.md:40`: "a review is evidence and stays as written (Law 7)". Neither skill is in `Owns`, so after the change they would point to a sentence that no longer exists. To fix: drop only the "issue" half, keep "only a person turns one into a story", and keep the heading `## Law 7 — Defects are not stories`, which `tests/structure.test.sh:51` checks.

**major — s134: security findings filed as issues on a possibly public tracker.** Every finding left open at ship (any major or minor not fixed) and every idea is filed at once, automatically. Polype's own repository is public (`atoll-labs-io/polype`, s132's notes). A major security finding would therefore become a public issue with no person in the loop. `## What goes to the person` and ADR-0077 list security as a strategic decision that goes to the person. To fix: add a criterion or a note on how a security finding is handled (held back, sent to the person, or filed privately).

**minor — s134, `Owns`: `method/commands/po-drive.md` and `method/commands/po-orchestrator.md` have no criterion and no note saying what changes in them.** The likely reason: under `Ship confirmation: human` with `Merge mode: pr`, "un ship prouvé" (a proven ship) is only established later, by the fleet. The criterion does not say which command files the issues in that case. Say so, or remove the two entries. Any command that starts reading `Issue tracker` must also list it in its `Reads settings:` line (a repository convention).

**minor — s134, `ship_files_open_findings`: two gaps.** The issue title, which is also the key that prevents a second filing, is not given a format. Two findings of one review could share a title. "une tâche `+issue` du projet" does not say which Taskwarrior `project:` value is used.

**minor — s134, `setup_proposes_the_forge`:** it does not say what `/po-setup` proposes when the remote is not on GitHub, or when there is no remote; "le porteur répond" (the owner answers) is not observable by a test; the template already defaults to `Issue tracker: github` (`method/templates/agents-local.md:23`), and the description of the setting still says "where defects are filed". Nothing in the criteria widens that description, even though the story owns the file.

**minor — s134, `law_files_everything_to_handle`:** the Law 7 text it asks for does not say what the lead does with an idea when `Issue tracker` is `—`. Only the ADR criterion covers that case.

**minor — s134 against s130 and s131 (`Owns` overlap, check 8):** s134 shares entries with them and has no dependency on either: `method/AGENTS.md`, `method/commands/po-setup.md`, `method/templates/agents-local.md`, `AGENTS.local.md`. Rated minor, not critical, because both stories appear to be shipped (s132 and s133 are landed on `main` and depend on them; the template already holds `Project CLAUDE file`). Adding `Dépend de : s133-any-harness-docs` would make the order explicit and close the finding.

### Not verified

- **Whether the Objectif asks for the existing backlog to be filed.** "qu'aucune idée … ne reste seulement dans …" could include items that already exist: the Codex port, the planned features, the "issue à part" for GitLab and Forgejo named in the notes, and findings already open in past reviews and `docs/decisions-log.md`. No criterion files them. If they are in scope, that is a one-time action for the lead rather than a story, but the milestone should say who does it.
- **Which existing tests quote phrases from the files s134 changes**, beyond `tests/structure.test.sh`.
- **"Mémoire" in the Objectif.** Polype owns no memory layer, so I could not match that item to any part of the method.
- **That no other command reads `Issue tracker`.** Confirmed only by searching `method/` for the setting's name.
- **Ship status of s130 and s131.** Inferred from the git snapshot and the template contents.

Max severity: major
Stories ready: yes

> Answered at the next revision, 2026-10-14. Major 1: filing on GitHub goes through `gh` to the github.com repository of `origin`, the token going only to the host that issued it, as ADR-0083 and `/po-ship`'s forge step do; `gh` missing or not logged in → nothing filed and the report says so; the note is corrected. Major 2: only the "issue" half of the Law 7 sentence goes; "only a person turns a finding into a story" stays word for word, and so does the heading. Major 3: new criterion `security_goes_to_the_person` — a Security-lens finding or a security idea is never filed on its own, it goes to the person (ADR-0077). Minors: `/po-orchestrator` leaves `Owns`, `/po-drive` stays for the merge it proves later; title format `<id>: <sévérité> — <début du constat>`; Taskwarrior `project:<nom du dépôt> +issue`; `/po-setup` proposes `taskwarrior` off GitHub or without a remote; the setting's description is widened and readers list it in `Reads settings:`; Law 7 says an idea goes to the person under `—`; `Dépend de : s133-any-harness-docs`. Not verified: the existing backlog was filed by the lead on 2026-10-14 (polype #72–#80, pecten #16–#17, nautile #29–#31). Stories ready: yes.
