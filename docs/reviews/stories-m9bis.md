# Stories review: Polype, milestone "M9 bis — Les restes de M9" (s108–s113)

This is a one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). It was done on 2026-10-13, in a context that did not write the stories, against `docs/stories.md` lines 1665–1757 of the worktree `/home/lecrabe/dev/atoll/polype/.claude/worktrees/framing-m9bis`.

- **Scope source:** the findings left open by the M9 reviews: `docs/reviews/s105-ship-through-pr.md` (M1, M2), `s107-forge-token-bound-to-host.md` (minors 1–2), `s106-framing-through-pr.md` (majors 1–2, minor 3), `s102-ship-follows-the-forge.md` (major 2), `s104-escalation-contract.md` (both majors, the `method/AGENTS.md:79` minor) and `s101-conversational-framing.md` (the major). Also the owner's decisions of 2026-10-13: the `s<n>:` shipped fallback, and the reuse ladder joining the milestone as s113.
- **Platform:** `cli`.
- **Shape:** follows `docs/reviews/stories-m9.md`.

Review status: complete

## Coverage
| Scope item | Covered by | Covered |
| --- | --- | --- |
| s105 M1: a resumed automatic ship refuses its own merge (`po-ship.md:74,77`) | s108 `resumed_ship_merges_the_pushed_head` | yes |
| s105 M2: `test_no_agent_pushes_target_branch` does not bite | s108 `push_targets_only_the_story_ref` | yes |
| s107 minor 1: the `--hostname github.com` pin is untested | s108 `forge_read_pins_and_skips_curlrc` | yes |
| s107 minor 2: `~/.curlrc` is not skipped (`curl -q`) | s108 `forge_read_pins_and_skips_curlrc` | yes |
| s106 major 1: `/po-drive` lanes skip the start-point check of `/po-research` step 2 | s109 `lane_checks_its_start_point` | yes (heading level is wrong, minor) |
| s106 major 2: a second landing on a non-GitHub forge drops earlier files | s110 `second_landing_stacks_on_the_framing_branch` | **partly: the test is ancestry, and ADR-0081 says it never holds on GitHub (critical)** |
| s106 minor 3: nothing realigns the root after a person merges | s110 `root_realigns_after_a_merge` | **partly: same ancestry test, so it never fires on GitHub (critical, same finding)** |
| s102 major 2: the "effective `human`" condition of the waiting row has no test | s109 `pr_wait_needs_effective_human` | yes |
| s104 major 1: a flow plan sent back for a tech choice loses its question | s111 `flow_plan_sent_back_keeps_the_marker` | yes (no ranked options are written, minor) |
| s104 major 2: the `## Approval` paragraph of `po-plan.md` is untested | s111 `approval_test_bites_in_its_section` | yes |
| s104 minor `method/AGENTS.md:79`: not every lone decision is logged; `/po-orchestrator` logs nothing | s109 `lone_decisions_are_all_logged` | partly: no orchestrator section exists, and nothing says when it writes or lands the log (major) |
| s101 major: two framing rules have no biting test | s111 `stories_review_rules_bite` | yes |
| Owner, 2026-10-13: a story counts as shipped on a `s<n>:` subject when no `<id>:` commit exists (po-session, `/po-status`, `/po-drive`) | s112 (all three criteria) | yes |
| Owner, 2026-10-13: the reuse ladder joins the milestone as s113 | s113 | yes (two majors on its measurement half) |

Every story traces to at least one row above.

## Exclusions
There is no graveyard and there are no non-goals: there is no PRD or brief. The options turned down in the notes are not revived. s112 adds no "Livrée" mark in `docs/stories.md`. s113 adds no permanent hook from Ponytail and does not duplicate the Dependencies lens of `review-lenses`.

## Owns overlap (check 8)
I compared every pair with no dependency between them. These pairs have no dependency: s108–s109/s110/s111/s112/s113, s109–s110/s111/s113, s110–s111/s112/s113, s111–s112 and s112–s113. All their entries are disjoint, because they differ by a plain file name at the same segment. The two pairs that do share files are covered by a dependency: s109 and s112 share `po-drive.md` (s112 depends on s109), and s111 and s113 share `po-flow.md` and `po-plan.md` (s113 depends on s111). Every story has an `Owns` line. No `Depends on` points to a later or unknown id. Ids s108–s113 are unique and increase. Every `Surface` is `—`, which `cli` admits.

## Findings
- **critical: s110, both criteria decide "already merged" by ancestry, which never holds on GitHub.**
  - Accepted ADR-0081:14 records it: GitHub "recrée toujours les commits", and the PR head "n'est pas ancêtre de `main`".
  - Under `human`, the person lands the framing PR with Rebase and merge. Nothing then deletes `framing/<slug>`: `po-setup.md:83` deletes it only on the automatic path.
  - So `second_landing_stacks_on_the_framing_branch` would see that branch as "not contained in `origin/<Target branch>`" and stack the next landing on a branch that was already merged. That is a regression of today's GitHub path, which relies on an open PR.
  - `root_realigns_after_a_merge` ("quand `origin/<Target branch>` contient le commit de cadrage") never fires after a GitHub merge, which is exactly the case s106 minor 3 describes.
  - Fix: say how a merge is proven per forge. Use `gh pr view … --json state` printing `MERGED`, or compare content (`git diff --quiet <framing head> origin/<Target branch> -- <paths>`, or `git cherry`). Keep ancestry only for local mode and for true fast-forward forges.
- **major: s109 `lone_decisions_are_all_logged`, `/po-orchestrator` has no `## The decisions log`, and nothing says when it writes or lands the log.**
  - `po-orchestrator.md` has no such section; its stages run 0 to 8.
  - The criterion has it log plan approval and fix runs, which both happen before the ship. A row appended to `docs/decisions-log.md` in the root at that point is a modified tracked file. Under `Merge mode: local`, that stops `/po-ship` (`po-ship.md:81`). This is the same trap the M9 stories review raised for s104.
  - Fix: state the moment (after the ship or the stop) and the landing (as `/po-drive`, `po-drive.md:149-151`), and name the new section.
- **major: s113's last criterion "(revue)" is not something the cycle can check or carry.**
  - The paid runs are launched by the owner, but the review is the reviewer's answer transcribed verbatim (`po-drive.md:131`). No stage writes the owner's rates into it.
  - "La story le dit au lieu de la livrer" has no stage either. Under `Plan validation: autonomous` and `Ship confirmation: automatic`, `/po-drive` would ship the story before anyone ran the arms.
  - Fix: make the measurement a human stop with a named file, for example `docs/reviews/<id>-eval.md` or a line the ship checks. Or take it out of the criteria and into a follow-up story.
- **major: s113 `eval_has_a_yagni_control_arm` does not say where the modified reviewer is installed.**
  - `drift_check` (`bin/po-eval:55-77`) exits when a user-level copy of `reviewer.md` or its skills differs from `method/`.
  - Polype is installed globally on this machine, so writing the control copy into `~/.claude/` either trips that check or overwrites the global install that every project uses.
  - Fix: name the mechanism, for example a temporary `CLAUDE_CONFIG_DIR` for the control arm, and give it a criterion. With an external paid system, a new eval case and a control mode, the story reads as a 4 whose risk the notes do not name.
- **minor:**
  - **s108–s111 carry no `Corrige` line.** This file has used one for review-fix stories since M7. Without it, complexity 2 ≤ `Flow threshold: 2` sends them to the short track without the `diagnostic` skill; s108 is a real defect.
  - **s109:** `## Preparing the lanes` is a level-3 heading in `po-drive.md:86` (`### Preparing the lanes`).
  - **s110 `root_realigns_after_a_merge` leaves the "who" open** ("la commande de cadrage suivante, ou le chef de projet à la reprise"). The second option would need `method/AGENTS.md` or `po-session.sh`/`po-drive.md`, which s110 does not own (the last two belong to s109 and s112). Choosing `git reset --keep` over the existing `git merge --ff-only` (`po-setup.md:83`) is not explained.
  - **s111 `flow_plan_sent_back_keeps_the_marker` writes only the marker.** `po-plan.md:50` asks "with the ADR's options in their ranked order", so no ADR draft or ranked options would be there to ask.
  - **s112:** "les trois disent la règle avec les mêmes mots" is unclear for a bash hook. Say whether this means a comment or a printed line.
  - **s113** is at 7 criteria with 10 `Owns` entries and an ADR. It splits naturally into the ladder (plan and review) and the measurement (eval case and control arm).

Every path, section and phrase the criteria cite exists in `method/`, `bin/`, `evals/` and `tests/`, except the orchestrator section noted above:
- `po-research.md:31` step 2;
- `po-drive.md:65` with its effective-`human` clause, and `po-drive.md:148`;
- `po-ship.md:27,29,74,77`;
- `po-plan.md:30,49-50`;
- `po-flow.md:74`;
- `po-stories-review.md:49` "never changed: a verdict is the subagent's";
- `po-stories.md:53` "has already started";
- `test_stories_review_surfaces_criticals_only`, `test_plan_with_a_tech_choice_waits_for_a_human` and `test_no_agent_pushes_target_branch`;
- `po-session.sh:130-136` `read_shipped`;
- `po-status.md:31`;
- `planner.md:40-41`, the **Plan** and **Short track** bullets;
- `review-antihallu` step 3;
- `implementer.md:51`;
- `bin/po-eval` and its `CASE_EXPECT_SEVERITY` and `CASE_EXPECT_SHIP`;
- the closed kind list in `tests/evals.test.sh:67-70`;
- the demo app `app/notes.py`.

## Not verified
- **Accepted ADRs.** I read only ADR-0081 (to confirm the critical) and grepped the folder. The other accepted ADRs were not read against s108–s113.
- **The repo's shipping history.** I have no shell, so I could not check that this repository's history really ships s01–s10 under `sNN:` subjects, which is s112's premise.
- **`git reset --keep` with the framing files staged in the root.** I did not run it; I believe it is allowed when the staged content equals the target, but did not test it.
- **Other worktrees.** I could not check whether the old `story/reuse-ladder` worktree still exists, or how po-session would report it once s113 takes over.
- **The pinned tests.** Of the tests the milestone and s113 notes name as pinning these files, I did not open every one (`tests/fleet-wiring`, `structure`, `drive`, `resume`, `ship`, `ship-follows-forge`, `framing-through-pr`, `project-lead`, `plan`, `planner`, `flow`, `review`, `surface-routing`, `scene-and-simulation-drivers`). So "additive" is unchecked.
- **Owns outside M9 bis.** I did not compare these `Owns` against stories outside M9 bis that may still be in flight.
- **M9 findings left out of scope** by the caller's list were not checked for coverage: s106 minors 4–6, s102 minors 3–5, s104 `planner.md:56`, and the marker not recognised by `po-session`/`po-status`.
- **Not run:** the suite, `bin/po-lint` and `tests/overlap.test.sh`.

Max severity: critical
Stories ready: no

> Answered at the next commit, 2026-10-13. The critical was put to the person, who approved the fix: s110 proves a framing merge as step 3 of `/po-ship` does (`gh pr view` printing `MERGED` with a pull request, ancestry only without one), stacks only on an unmerged branch, and realigns the root with `git merge --ff-only` from the next framing command. The person also approved splitting s113: s113 keeps the ladder (plan and review), the new s114-reuse-ladder-eval carries the eval case and the control arm, installed in a temporary `CLAUDE_CONFIG_DIR`, and the paid runs happen after its ship, launched by the owner. Majors: s109 gives `/po-orchestrator` a `## The decisions log` written after the ship or the stop and landed through the framing path (complexity 3). Minors: s108–s111 carry a `Corrige` line; s109 names `### Preparing the lanes`; s111 drafts the ADR with ranked options; s112 says the rule is one phrase in `/po-status` and `/po-drive` and applied in `read_shipped`. Stories ready: yes.
