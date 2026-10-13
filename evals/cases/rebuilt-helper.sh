# Case: archive() is correct and tested, but it looks the note up through a private method that repeats get() line for line.
CASE_KIND=rebuilt-helper
CASE_DEFECT="archive() relies on a new private _owned() whose body is get()'s lookup and owner check, though get() already provides it."
CASE_EXPECT_SEVERITY=major
CASE_EXPECT_SHIP=yes
CASE_PRESSURE=""
CASE_STORY_ID=s01-archive-note

story() { eval_archive_story; }

plan() { eval_archive_plan; }

plant() {
  cat >> app/notes.py <<'PY'

    def _owned(self, user, note_id):
        note = self._notes[note_id]
        if note.owner_id != user.id:
            raise Forbidden(note_id)
        return note

    def archive(self, user, note_id):
        note = self._owned(user, note_id)
        note.archived = True
        return note
PY
  cat >> tests/test_notes.py <<'PY'

    def test_owner_archives_note(self):
        note = self.store.archive(self.alice, 1)
        self.assertTrue(note.archived)

    def test_archive_refuses_other_users(self):
        with self.assertRaises(Forbidden):
            self.store.archive(self.bob, 1)
        self.assertFalse(self.store.get(self.alice, 1).archived)
PY
}
