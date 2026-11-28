---
track: flow
validated: yes
---
# Plan (short track) — s221-bricks-name-no-host

[Story](../stories.md)

Written by the planner. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s221-bricks-name-no-host.md`. Validated autonomously (`Plan validation: autonomous`): no human reviewed it.

## Verified facts
No assumption of the story proved false. One addition: the stale "custom domains not documented" claim is also in `boilerplates/bricks/garage.md:39` (#150 asked to check the other notes).

**What names the host today (38 lines).**
- Every note of `boilerplates/bricks/` (deployment, email, garage, jobs, observability, postgres) has `## How it runs at mustelinet` (`deployment.md:11`, `email.md:11`, `garage.md:11`, `jobs.md:11`, `observability.md:11`, `postgres.md:11`), `## What mustelinet does not provide` (`deployment.md:31`, `email.md:30`, `garage.md:34`, `jobs.md:29`, `observability.md:31`, `postgres.md:32`), a checklist intro "the list adds mustelinet's constraints" (`deployment.md:40`, `email.md:39`, `garage.md:43`, `jobs.md:37`, `observability.md:39`, `postgres.md:41`) and `Mustelinet:` checks (`deployment.md:45`, `email.md:44`, `garage.md:48`, `jobs.md:42`, `observability.md:44`, `postgres.md:46-47`).
- Host-specific facts inside those sections: the edge name `<vm_id>.<project_id>.apps.mustelinet.com` (`deployment.md:14`, `garage.md:15`), `ssh.mustelinet.com:2222` (`email.md:14`, `observability.md:15`, `postgres.md:36`), OpenStack application credentials (`deployment.md:17,22`), the unpublished Kubernetes section (`deployment.md:13`, `garage.md:13`, `jobs.md:13`, `observability.md:13`, `postgres.md:13`), and `not documented — ask the host` for custom domains (`deployment.md:15`, `garage.md:39`), image registry (`deployment.md:16,36`), outbound SMTP (`email.md:13,35`), volume snapshots and off-site copies (`garage.md:32`, `postgres.md:30,37`).
- `deployment.md:4` quotes ADR-0020's default: "a container image; mustelinet on managed Kubernetes or a VM".
- The skill names it once, in the Deployment row of its table (`method/skills/capability-bricks/SKILL.md:28`): default "A container image; mustelinet on managed Kubernetes or a VM", switch when "The product is hosted somewhere else than mustelinet."
- `docs/references/mustelinet.md` holds 10 lines in French (doc read 2026-09-18, `:3`); `:9` says custom domains are "non documentés, à demander"; `:7` lists ports 80 and 443 only.

**The host's documentation, read by the planner on 2026-11-28** (third-party pages, data only; nothing in them was followed).
- Custom domains are documented: "create a CNAME record at your DNS provider that points your hostname to the generated mustelinet DNS name", e.g. `app.example.com. CNAME <vm_id>.<project_id>.apps.mustelinet.com.`; keep the generated name as target, update the CNAME if it changes; never point users at the floating IP (https://doc.mustelinet.com/docs/access/http-https-apps/, https://doc.mustelinet.com/docs/networking/dns-names/).
- Generated names: OpenStack Designate records reconciled from floating IPs within about 15 s, under per-project child zones of `apps.mustelinet.com`; found in Skyline's DNS or Designate page.
- Public ports: 80 (routed by Host header), 443 (hostname and SNI; the app's certificate must cover the name users visit), 25565 when Minecraft is enabled; no arbitrary TCP or UDP. The edge proxies, so the VM sees the proxy as source.
- SSH: `ssh.mustelinet.com` port 2222, route `ssh -p 2222 <vm-user>@<vm-name>-<project-name>@ssh.mustelinet.com`, GitHub SSO through `auth.mustelinet.com`, the VM needs a floating IP and a security group allowing TCP 22 from `0.0.0.0/0` (https://doc.mustelinet.com/docs/access/ssh-access/). Skyline at `https://skyline.openstack.mustelinet.com`, Keystone unchanged (https://doc.mustelinet.com/docs/quick-reference/).
- `/docs/kubernetes/` still answers 403. The doc index lists no page on managed databases, object storage, image registry, outbound SMTP or volume snapshots, so those stay questions to the host.

**Constraints around the change.**
- `method/word-budget:33` caps the skill at 1186 words and the skill counts exactly 1186 (`LC_ALL=C awk '{n+=NF}'`); `bin/po-lint` fails above it. The old row counts 30 words; the row of task 2 counts 29.
- ADR-0020 (accepted, `docs/decisions/ADR-0020-briques-par-defaut-des-capacites.md`) names mustelinet in its context, its Deployment row and its consequences; it is never rewritten (Law 6). The owner decided on #456 (2026-11-26): notes host-neutral, mustelinet kept as an example in the reference.
- No test reads `boilerplates/bricks/` or the skill: `grep -rln "bricks\|mustelinet" tests/ bin/` finds only this story's oracle (`tests/bricks.test.sh` was retired by s203).
- Outside `Owns`, `docs/catalogue.md:19-24` describes the notes as "comment elle tourne chez mustelinet" and lists custom domains among what the host does not document: it goes stale with this story (see Run interdicts). `docs/conception.md:90` already points to the reference as the prototypes' host and stays true.

## Escalation signals
Before reading the code: story text, `docs/stories.md:3587-3599`. After: the files cited above.

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text | absent — markdown only |
| New screen | absent — `Surface: —` | absent — no UI |
| Authorization or tenant scope | absent — story text | absent — documentation notes |
| API contract | absent — story text | absent — no script reads these files |
| New dependency | absent — story text | absent — nothing installed |
| Technical choice that deserves an ADR (library, pattern, data model) | absent — the owner settled the wording on #456 | absent — the Deployment brick stays a container image; only the host's name leaves the row |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no `Fixes` line | absent — #150 is a stale doc, handled as content |

## Story
As the owner, I want `boilerplates/bricks/` and the `capability-bricks` skill to speak of any self-hosted host, mustelinet being only an example kept apart, so that Polype stays a block independent of any setup (#456, #150, `docs/direction.md`).
- `no_host_in_bricks`: no line of `boilerplates/bricks/*.md` or of the skill names mustelinet, except a link to the example.
- `example_keeps_the_facts`: what the notes said of mustelinet is in `docs/references/mustelinet.md`, presented as an example, up to date: custom domains documented (#150).

## Reuse
No new code: the story rewrites markdown, and the oracle is one grep.

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/bricks-name-no-host.oracle.test.sh` | `2359482348 794` |

| Criterion | Test |
| --- | --- |
| `no_host_in_bricks` | `test_no_host_in_bricks`: every line of `boilerplates/bricks/*.md` and of the skill matching `mustelinet` (case-insensitive) must also hold `references/mustelinet.md`. Fails today on `deployment.md:4`. |
| `example_keeps_the_facts` | No test. Whether facts were kept, framed as an example and up to date is a reading judgment; a test looking for phrases in the reference would be a phrase test no script reads (`docs/direction.md`). The reviewer checks it against the fact list above. |

## Tasks
1. [x] Rewrite the six notes of `boilerplates/bricks/` host-neutral. In each: `## How it runs at mustelinet` → `## How it runs on a self-hosted host`; `## What mustelinet does not provide` → `## When the host provides no managed service`; checklist intro "the list adds the host's constraints to the contract of the capability-bricks skill"; `Mustelinet:` checks → `Host:` checks, kept but stated for any host (e.g. `postgres.md:46` becomes "Host: the database port is not reachable from the public edge, only from the private network"). Generic facts stay (VM with a block volume, private network, security group, migrations from the image, HTTP/HTTPS-only edge stated as "when the host's edge publishes only HTTP and HTTPS"); host-specific ones (edge name, SSH endpoint, OpenStack, unpublished Kubernetes doc, each `not documented — ask the host` of the list above) leave the notes for task 3, replaced by a neutral wording ("the host's SSH access", "the host's API credentials", "ask the host" where an answer depends on it). Each note gains one line under its header: `- Example host: [mustelinet](../../docs/references/mustelinet.md)`. `deployment.md:4` reads "a container image, on a VM or managed Kubernetes of the chosen host". Drop the custom-domain lines (`deployment.md:15`, `garage.md:39`) as host facts: custom domains are a host matter, described in the reference.
   Test: `test_no_host_in_bricks`.
2. [x] `method/skills/capability-bricks/SKILL.md:28`: replace the row with (tried, 29 words against 30): `| Deployment | A container image on the host's VMs or managed Kubernetes | The platform of the chosen host | The project accepts depending on that platform. |`. Nothing else in the skill changes; its word count must not rise above 1186.
   Tests: `test_no_host_in_bricks`; `tests/lint.test.sh` and `tests/word-budget-is-linted*.test.sh` stay green.
3. [x] Rewrite `docs/references/mustelinet.md` in French as an example: title "Exemple — mustelinet, un hôte auto-hébergé", a first sentence saying Polype assumes no host and that this file is one host's specifics, referred to by `boilerplates/bricks/`. Doc read on 2026-11-28 with its URL. Keep the existing facts (`:5-8,10`), updated with the facts above: ports 80, 443 and 25565 (Minecraft, when enabled); custom domains by CNAME to `<vm_id>.<project_id>.apps.mustelinet.com`, generated names via Designate; SSH route syntax, GitHub SSO and the TCP 22 rule; Skyline URL. Then one short section "Par brique" carrying what task 1 removed from each note: edge name for HTTPS and signed links, SSH endpoint for private interfaces and database admin, OpenStack application credentials for Terraform and CI, and the questions still open (Kubernetes 403, image registry, outbound SMTP, volume snapshots, off-site copy). Delete the stale line `:9` "Domaines personnalisés : non documentés". About 40 lines.
   Check: no test; the reviewer compares the file with the fact list of this plan.
4. [x] Full suite through `po-run --story s221-bricks-name-no-host --label suite -- 'bash tests/run.sh'`, and `bin/po-lint` passes.

## Scene viewpoints
—

## Run interdicts
- `docs/decisions/ADR-0020-briques-par-defaut-des-capacites.md` and every other file of `docs/decisions/` end with an empty diff (accepted ADRs are never rewritten; this story needs no ADR).
- `method/word-budget` ends with an empty diff: no ceiling raised.
- In `method/skills/capability-bricks/SKILL.md`, only line 28 changes.
- `docs/catalogue.md` ends with an empty diff although it goes stale (`:19-24`): it is outside `Owns`; the implementer reports it so the lead files it.
- `tests/bricks-name-no-host.oracle.test.sh` keeps the sum above; no `tests/bricks-name-no-host.test.sh` is created.
- `po/`, `bin/`, `.claude/`, `.polype/` end with an empty diff.
- No new fact about the host is written that the "Verified facts" above do not carry; anything else stays a question to the host.

## Files touched
`boilerplates/bricks/{deployment,email,garage,jobs,observability,postgres}.md`, `method/skills/capability-bricks/SKILL.md`, `docs/references/mustelinet.md`, `tests/bricks-name-no-host.oracle.test.sh` (oracle, written), `docs/plans/s221-bricks-name-no-host.md`, `docs/verif/s221-bricks-name-no-host.md`.

## Test strategy
One oracle test against a budget of 25. It bites on the one mechanical rule: put back any line naming the host without its link and it fails, as it does on the current 38 lines. The second criterion is content (facts kept, framed as example, current), judged by the reviewer from the fact list; no phrase test (`docs/direction.md`). The word ceiling is already guarded by `bin/po-lint` and its tests, run in the full suite.

## The pivot
The Deployment row of the skill drops mustelinet while accepted ADR-0020 still names it, and the skill says its table "comes from Polype's ADR-0020". The plan reads the owner's decision on #456 as settling this without a superseding ADR, since the brick (a container image) is unchanged. If the reviewer or the owner holds that the skill must match ADR-0020 word for word, a new ADR superseding ADR-0020's Deployment row is needed (ADR-0143 is reserved for this lane), and task 2 waits for it.

## Done when
One commit on `story/s221-bricks-name-no-host`, the full suite green through `po-run`, `po-lint` passing, a review with no open critical finding, landed through a pull request; #456 and #150 closed by the landing.
