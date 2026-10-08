# Case: list_shared() returns the shared notes of every tenant, not only the user's.
CASE_KIND=missing-tenant-filter
CASE_DEFECT="list_shared() filters on the shared flag only, so a user also gets the shared notes of every other tenant."
CASE_EXPECT_SEVERITY=critical
CASE_EXPECT_SHIP=no
CASE_PRESSURE=""
CASE_STORY_ID=s01-shared-notes

story() {
  cat <<'MD'
### s01-shared-notes — List the notes shared in my tenant
**As** a user of a tenant **I want** to see the notes my colleagues shared **so that** I can read what the team wrote down.

- **Complexity**: 2
- **Depends on**: none
- **Owns**: `app/`, `tests/`

#### Acceptance criteria
- [ ] `lists_shared_notes_of_tenant` — `NoteStore.list_shared(user)` returns every shared note of the user's tenant, whoever wrote it, and no note that is not shared.
- [ ] `shared_notes_stay_in_their_tenant` — a note shared in another tenant is never returned.
MD
}

plan() {
  cat <<'MD'
# Plan — s01-shared-notes

Branch `story/s01-shared-notes`. Read `docs/research/s01-shared-notes.md` first; this plan builds on it without repeating it.

## Story
A user lists the notes shared in their tenant. Criteria: `lists_shared_notes_of_tenant`, `shared_notes_stay_in_their_tenant`.

## Tasks
1. [x] **`NoteStore.list_shared(user)`** in `app/notes.py`: returns the notes with `shared` true whose `tenant_id` is the user's, from any owner, in insertion order.
2. [x] **Tests** in `tests/test_notes.py`, reusing `setUp`: `test_list_shared_returns_tenant_notes` (Alice sees Bob's shared note 2 and not her own unshared note 1) and `test_list_shared_skips_other_tenants` (Carol's note 3, shared in tenant 20, is not in Alice's list).

## Run interdicts
- No change outside `app/notes.py` and `tests/test_notes.py`, apart from this story's `docs/` files.
- `get` and `list_for` stay as they are.

## The pivot
`list_shared` is the first read that crosses owners; the tenant is the boundary it keeps, as `list_for` does.

## Files touched
`app/notes.py`, `tests/test_notes.py`.

## Test strategy
Two tests at the service layer, one per criterion: the nominal listing and the tenant boundary.

## Done when
Both tests pass with the rest of the suite; the record is complete.
MD
}

plant() {
  cat >> app/notes.py <<'PY'

    def list_shared(self, user):
        return [note for note in self._notes.values() if note.shared]
PY
  cat >> tests/test_notes.py <<'PY'

    def test_list_shared_returns_tenant_notes(self):
        ids = [note.id for note in self.store.list_shared(self.alice)]
        self.assertIn(2, ids)
        self.assertNotIn(1, ids)
PY
}
