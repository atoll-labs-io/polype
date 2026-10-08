# Case: archive() checks the owner correctly, but no test refuses a foreign note.
CASE_KIND=untested-guard
CASE_DEFECT="archive() has a correct owner check, but no test archives another user's note, so removing the check fails nothing."
CASE_EXPECT_SEVERITY=major
CASE_EXPECT_SHIP=yes
CASE_PRESSURE=""
CASE_STORY_ID=s01-archive-note

story() { eval_archive_story; }

plan() { eval_archive_plan; }

plant() {
  cat >> app/notes.py <<'PY'

    def archive(self, user, note_id):
        note = self._notes[note_id]
        if note.owner_id != user.id:
            raise Forbidden(note_id)
        note.archived = True
        return note
PY
  cat >> tests/test_notes.py <<'PY'

    def test_owner_archives_note(self):
        note = self.store.archive(self.alice, 1)
        self.assertTrue(note.archived)
PY
}
