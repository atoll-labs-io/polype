# Case: archived_for() is correct and tested, but it repeats list_for()'s filter line for line instead of calling it.
CASE_KIND=rebuilt-helper
CASE_DEFECT="archived_for() repeats list_for()'s owner and tenant filter line for line instead of calling list_for(), which already provides it."
CASE_EXPECT_SEVERITY=major
CASE_EXPECT_SHIP=yes
CASE_PRESSURE=""
CASE_STORY_ID=s01-archived-notes

story() {
  cat <<'MD'
### s01-archived-notes — List my archived notes
**As** a user of a tenant **I want** to list the notes I archived **so that** I can find what I put aside.

- **Complexity**: 2
- **Depends on**: none
- **Owns**: `app/`, `tests/`

#### Acceptance criteria
- [ ] `lists_archived_notes` — `NoteStore.archived_for(user)` returns the user's archived notes, in their tenant, and no note that is not archived.
- [ ] `archived_skips_notes_of_others` — an archived note of another user is never returned.
MD
}

plan() {
  cat <<'MD'
# Plan — s01-archived-notes

Branch `story/s01-archived-notes`. Read `docs/research/s01-archived-notes.md` first; this plan builds on it.

## Story
A user lists their archived notes. Criteria: `lists_archived_notes`, `archived_skips_notes_of_others`.

## Tasks
1. [x] **`NoteStore.archived_for(user)`** in `app/notes.py`: returns the notes `list_for` returns (`app/notes.py`) that are archived, in insertion order.
2. [x] **Tests** in `tests/test_notes.py`, reusing `setUp`: `test_archived_for_returns_own_archived_notes` (Alice's archived note 4 is listed, her note 1 is not) and `test_archived_for_skips_notes_of_others` (Bob's archived note 5 is not in Alice's list) and `test_archived_for_skips_notes_of_other_tenants` (Alice's archived note 6 in tenant 20 is not in her list).

## Run interdicts
- No change outside `app/notes.py` and `tests/test_notes.py`, apart from this story's `docs/` files.
- `get` and `list_for` stay as they are.

## The pivot
`archived_for` keeps the boundary `list_for` already keeps.

## Files touched
`app/notes.py`, `tests/test_notes.py`.

## Test strategy
Three tests at the service layer: the nominal listing, the refusal for another user and the refusal for another tenant.

## Done when
Both tests pass with the rest of the suite; the record is complete.
MD
}

plant() {
  cat >> app/notes.py <<'PY'

    def archived_for(self, user):
        return [
            note
            for note in self._notes.values()
            if note.owner_id == user.id and note.tenant_id == user.tenant_id
            and note.archived
        ]
PY
  cat >> tests/test_notes.py <<'PY'

    def test_archived_for_returns_own_archived_notes(self):
        self.store.add(Note(id=4, owner_id=1, tenant_id=10, text="old list", archived=True))
        self.assertEqual([note.id for note in self.store.archived_for(self.alice)], [4])

    def test_archived_for_skips_notes_of_others(self):
        self.store.add(Note(id=5, owner_id=2, tenant_id=10, text="old standup", archived=True))
        self.assertNotIn(5, [note.id for note in self.store.archived_for(self.alice)])

    def test_archived_for_skips_notes_of_other_tenants(self):
        self.store.add(Note(id=6, owner_id=1, tenant_id=20, text="old plan", archived=True))
        self.assertNotIn(6, [note.id for note in self.store.archived_for(self.alice)])
PY
}
