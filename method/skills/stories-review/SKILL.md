---
name: stories-review
description: How to judge docs/stories.md against the approved PRD or brief before any story is built — scope coverage first, then graveyard, disguised layers, testable criteria, dependency order, complexity, ids and Owns overlap, with a severity scale of its own. Preloaded in the stories-reviewer.
---
# Reviewing stories before they are built

A gap in the stories is cheapest now: fixing it here means editing one markdown file, while finding it after three stories have shipped means reopening them. The stories were written with the `agentic-stories` skill; this procedure holds them to those same rules from the outside, and names each rule instead of rewriting it.

## Checks, in this order

**1. Coverage, table in hand.** Before reading any story on its own merits, list the scope and match each item to the stories that serve it. From a PRD: each line of `## Core loop` and the `## Angle`. From a brief: the `## Wedge & non-goals` and each entry of `## Premises`. One row per item, the ids that cover it, and whether it is covered. A story counts only when its criteria would actually deliver the item, not when its title mentions it. An item of the scope that no story covers is critical. A story that traces to no item is out of scope (see "Scope: core loop and graveyard" in `agentic-stories`).

**2. Graveyard.** With a PRD (`replace` or `adapt`), read every story against `## Graveyard`. A story that brings a buried feature back, even renamed or shrunk, is critical. With a brief, there is no graveyard: mark the check as not applicable.

**3. Technical layers dressed as stories.** A story nobody can try — a table, an endpoint, a service on its own — breaks "Vertical slices". A contract story that meets the conditions of "Owns and contracts first" is allowed; one that has a single consumer or no observable test is not.

**4. Criteria a test cannot check.** Each criterion must name an input, an action and what is seen (see "Criteria and notes"). Flag vague ones ("works well", "is fast") and stories with more than about seven criteria.

**5. Dependency order.** Every `Depends on` names an id that exists and sits earlier in the file. A dependency on a later or unknown id is critical.

**6. Complexity.** A 5 left unsplit, or a 4 whose notes name no risk, breaks "Complexity and splitting".

**7. Ids.** Each id has the form `s<number>-<slug>`, appears once, and the numbers grow in file order.

**8. Owns overlap.** Compare the `Owns` of every pair of stories, directories included: a directory owned by one story covers every path beneath it. Two stories with no dependency between them that share an `Owns` path are flagged as critical: run side by side, they would edit the same files. A dependency counts when either story reaches the other through its `Depends on` chain. A story that declares no `Owns` at all is a major finding: nobody can tell what it may touch.

## Severity
- **critical** — a scope item no story covers; a graveyard feature revived; a dependency on a later or unknown story; an `Owns` path shared by two stories with no dependency between them. Each of these wastes whole cycles once building starts.
- **major** — a technical layer dressed as a story; a criterion no test can check; a 5 left unsplit; a 4 without its risk; a story with no `Owns`.
- **minor** — id format, thin notes, wording.

`Stories ready: no` means a critical finding or a blocked review, and nothing else. Majors are reported and fixed when convenient; they do not hold back the first story. Rate each finding for what it is, never to push a verdict one way or the other.
