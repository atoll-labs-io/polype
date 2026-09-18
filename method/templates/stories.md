# User stories — <product>

> One story = one slice a user can use, written so an agent can build it without guessing.
> Id `s<number>-<short-slug>`, reused verbatim in every pipeline file and in the branch `story/<id>`.

Complexity scale: **1** trivial CRUD · **2** form, persistence and list · **3** business logic or several states · **4** integrations, payments, roles · **5** real time, migrations, external systems. A 4 states its risk; a 5 is split before planning.

## <id> — <title>
**As a** <user> **I want** <action> **so that** <benefit>.

- **Complexity**: <1–5>
- **Depends on**: <story ids, or none>
- **Owns**: <paths this story may change; two stories that share a path never run in parallel>

### Acceptance criteria
- [ ] <observable behaviour, specific enough to become a test>

### Agentic notes
<what a human would infer and an agent must read: files involved, constraints, traps, the reference screen or flow when one exists>
