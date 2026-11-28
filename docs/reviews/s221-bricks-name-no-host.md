# Review — s221-bricks-name-no-host

[Story](../stories.md) · [Plan](../plans/s221-bricks-name-no-host.md) · [Verification](../verif/s221-bricks-name-no-host.md)

Method version: 0.13.0
Recorded: 2026-11-28T13:28:54+01:00

Diff reviewed: `git diff main...story/s221-bricks-name-no-host`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: e6983d6d79c3329b4058934859231a0ff34d8859

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s221-bricks-name-no-host`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. The six `boilerplates/bricks/*.md` fall under `boilerplates/bricks/`. `method/skills/capability-bricks/SKILL.md`, `docs/references/mustelinet.md` and `tests/bricks-name-no-host.oracle.test.sh` are file entries. `docs/plans/s221-…` and `docs/verif/s221-…` are the story's own evidence, in scope by construction.
- [x] Outside `Owns` → major: none
- [x] Inside another running story's `Owns` → critical: none
- [x] No `Owns` line on this story → not the case. The line is at `docs/stories.md:3593`.

## Evidence reused
- [x] `po-gate verif-current s221-bricks-name-no-host` → exit 0, so the record is reused. One `Unit suite` run (`bash tests/run.sh`) exited 0. The project has no `Typecheck` command (`—`). "Not proven here" leaves the content of the reference to the reviewer. That is judged below.
- [x] `po-gate qa-current` → not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–4 are present, and nothing in the diff falls outside the plan. Task 1 differs in wording; see the minor findings.
- [x] Each run interdict checked:
  - Nothing under `docs/decisions/` changed.
  - `method/word-budget` is unchanged. The skill now counts 1185 words against a ceiling of 1186.
  - Only line 28 of the skill changed.
  - `docs/catalogue.md` is unchanged.
  - The oracle sum is intact (`oracle-intact` exit 0), and no `tests/bricks-name-no-host.test.sh` was created.
  - `po/`, `bin/`, `.claude/` and `.polype/` are unchanged.
  - Every new host fact in `docs/references/mustelinet.md` appears either in the plan's Verified facts or in the previous reference.

## References
- [x] Every link `../../docs/references/mustelinet.md` from `boilerplates/bricks/*.md` resolves to the existing file. The oracle uses `$ROOT`, `$METHOD`, `fail` and `require_file`, all from `tests/lib.sh`/`run.sh`, and the run proved them.
- [x] Facts in the reference held against the plan's list:
  - ports 80, 443 and 25565
  - the edge acts as a proxy
  - Designate names and the delay of about 15 s
  - custom domains by CNAME, with the two doc URLs
  - SSH route syntax, GitHub SSO through `auth.mustelinet.com`, the TCP 22 rule
  - Skyline and Keystone URLs
  - Kubernetes still answers 403
  - questions still open: registry, SMTP, snapshots, off-site copy
  - the stale line "Domaines personnalisés : non documentés" is gone

  Every fact the notes lost is now in `## Par brique` (edge name, `ssh.mustelinet.com:2222`, OpenStack application credentials) or under "Non documenté". Criterion `example_keeps_the_facts` is met by reading.

## Rules
- [x] `AGENTS.md` conventions are respected: method files in English, the docs file in French, and `docs/direction.md` (no owner setup in the method) is now honoured by the notes.
- [x] ADR-0020 is not contradicted in substance: the brick, a container image, is unchanged. The skill's Deployment row now differs from ADR-0020's wording, though; see the minor finding. The owner's decision on #456 (2026-11-26) authorises making the notes host-neutral.

## Tests
- Oracle: `po-gate oracle-intact s221-bricks-name-no-host` → exit 0
- [x] Floor: `po-gate floor-guard s221-bricks-name-no-host main` → exit 0, nothing lowered.
- [x] The assertion pins `no_host_in_bricks`, and none of the six empty shapes applies. `example_keeps_the_facts` has no test, by design (`docs/direction.md`), and is judged by reading above.
- [x] 1 test against a `Test budget` of 25.
- [x] Bite: I put `ssh.mustelinet.com:2222` back into `boilerplates/bricks/postgres.md` (the `Publication` line of "What the host may not provide") → 1 test failed out of 1 (`no_host_in_bricks`) → undone with `git checkout --`, and `git diff --exit-code` was clean.
- [x] Tests the story made useless: none. `tests/bricks.test.sh` was already retired by s203.

## Neighbours
- [x] No script, test or `bin/` tool reads the brick notes or their section headings (grep over the worktree). `docs/conception.md:90` stays true. `docs/catalogue.md:19-24` goes stale: it still says the notes describe "comment elle tourne chez mustelinet" and that custom domains are not documented. It is outside `Owns`, and a run interdict of the plan keeps it unchanged, so it is not a finding against this diff. The lead should file it as an issue.

## Lenses
Lenses run: none. The diff is markdown and one bash test, with no auth, route, migration, lockfile or server-side code.
- [x] No lens findings.

## Findings
- minor — boilerplates/bricks/postgres.md:15 — This sentence no longer parses: "When the host's public edge routes HTTP and HTTPS only, so the database is never published." The original said absolutely that the database is never published, because the security group already keeps it private. The new "When…, so…" makes that sound conditional on the edge. A suggested fix: "The database is never published; besides, a host's edge often routes HTTP and HTTPS only."
- minor — boilerplates/bricks/deployment.md:16, boilerplates/bricks/email.md:14 — Two `not documented — ask the host` remain. Task 1 said each of them should leave the notes and become "ask the host". "Not documented" is a statement about one host's documentation, which a host-neutral note cannot make.
- minor — boilerplates/bricks/*.md:12 and the "What the host may not provide" headings — The headings read `## How it runs at the host` and `## What the host may not provide`. Task 1 named `## How it runs on a self-hosted host` and `## When the host provides no managed service`. Nothing reads these headings, so this is a wording gap against the plan only.
- minor — docs/references/mustelinet.md:1 — The title "un hébergeur auto-hébergé" is self-contradictory, and it is not the plan's "un hôte auto-hébergé". mustelinet is a hosting provider on which the projects self-host their bricks.
- minor — method/skills/capability-bricks/SKILL.md:28 — The skill says its table "comes from Polype's ADR-0020", but the Deployment row now differs from ADR-0020:38 ("image conteneur ; mustelinet en Kubernetes managé ou VM"). The switch condition was rewritten too. The brick itself is unchanged, and the owner settled the host-neutral wording on #456, so no superseding ADR is required for this ship. A reader comparing the two will see the gap. Either add a one-line note in a later ADR, or accept the gap.
- minor — tests/bricks-name-no-host.oracle.test.sh:11 — The filter passes any line that holds `references/mustelinet.md`. A line that both links to the example and states host facts would therefore pass. This is acceptable for a one-grep oracle, and is noted only as a limit of what the test proves.

## Not verified
- I did not fetch the host's documentation (doc.mustelinet.com). The reference was checked against the facts the plan says it read on 2026-11-28, not against the third-party pages themselves. If those facts matter, a person should open the four URLs the plan cites and confirm the ports, the CNAME procedure and the SSH route.
- Nothing has been deployed on any host, so none of the `Host:` checklist items of the brick notes has been exercised. They are statements in documentation only.
- I did not rerun the full suite or `bin/po-lint`. I relied on the record's `Unit suite` run, exit 0 on the reviewed code (`verif-current` passed). I counted the skill's word total myself (1185 ≤ 1186).
- No end-to-end or build checks: the project has none (`E2E: —`, `Build: —`).
- `docs/catalogue.md:19-24` is stale after this story, outside `Owns`. A person or the lead should file it.

Max severity: minor
Ship allowed: yes
