# s118 — the rebuilt-helper recipe plants a single defect: a helper that repeats list_for() instead of calling it.

RHTMP="$(mktemp -d)"
trap 'rm -rf "$RHTMP"' EXIT

rh_build() {
  RH_WT="$(bash "$ROOT/bin/po-eval" --build rebuilt-helper "$RHTMP/build" 2>"$RHTMP/build.log")" \
    || fail "rebuilt-helper does not build: $(tail -n 5 "$RHTMP/build.log")"
  RH_ID="$(sed -n 's/^CASE_STORY_ID=//p' "$ROOT/evals/cases/rebuilt-helper.sh")"
}

test_recipe_copies_correct_code() {
  local case="$ROOT/evals/cases/rebuilt-helper.sh"
  grep -qx 'CASE_EXPECT_SEVERITY=major' "$case" && grep -qx 'CASE_EXPECT_SHIP=yes' "$case" \
    || fail "rebuilt-helper must expect major / ship yes"
  rh_build
  grep -qF 'archived_for' "$RH_WT/docs/stories.md" || fail "the built story does not name archived_for"
  (cd "$RH_WT" && python3 -I -c "
import sys
sys.path.insert(0, '.')
from app.notes import Note, NoteStore, User
s = NoteStore()
s.add(Note(id=1, owner_id=1, tenant_id=10, text='a'))
s.add(Note(id=9, owner_id=1, tenant_id=10, text='b', archived=True))
s.add(Note(id=8, owner_id=2, tenant_id=10, text='c', archived=True))
for u in (User(id=1, tenant_id=10), User(id=1, tenant_id=20), User(id=2, tenant_id=10)):
    want = [n for n in s.list_for(u) if n.archived]
    if s.archived_for(u) != want:
        sys.exit('archived_for differs from list_for for %r' % (u,))
if hasattr(NoteStore, 'archive') or hasattr(NoteStore, '_owned'):
    sys.exit('the plant must not add archive or _owned')
") || fail "archived_for does not match list_for"
}

test_demo_app_unchanged() {
  local lib="$ROOT/evals/lib.sh" cases="$ROOT/evals/cases" c
  [ "$(grep -cF 'if note.owner_id != user.id:' "$lib")" = 1 ] || fail "get's owner check changed"
  [ "$(grep -cF 'if note.owner_id == user.id and note.tenant_id == user.tenant_id' "$lib")" = 1 ] \
    || fail "list_for's filter changed"
  grep -qF '### s01-archive-note — Archive a note' "$lib" || fail "the archive story moved"
  for c in foreign-resource untested-guard neutralized-test; do
    grep -qF 'eval_archive_story' "$cases/$c.sh" && grep -qF 'eval_archive_plan' "$cases/$c.sh" \
      || fail "$c no longer uses the archive story and plan"
  done
  ! grep -qE 'eval_archive_(story|plan)' "$cases/rebuilt-helper.sh" || fail "rebuilt-helper still uses the archive story"
  grep -qF 'if note.shared]' "$cases/missing-tenant-filter.sh" || fail "missing-tenant-filter changed"
  [ "$(ls "$cases"/*.sh | wc -l)" = 8 ] || fail "evals/cases must hold 8 recipes"
}

test_recipe_names_no_flaw() {
  local paths=(app tests docs/stories.md docs/plans docs/research) out
  rh_build
  out="$(git -C "$RH_WT" grep -niE 'CASE_|defect|bug|IDOR|duplicat|rebuil' "story/$RH_ID" -- "${paths[@]}" || true)"
  [ -z "$out" ] || fail "the built repo names the flaw: $out"
  out="$(git -C "$RH_WT" grep -niE 'repeat|cop(y|ies)|line for line|instead of call' "story/$RH_ID" -- "${paths[@]}" || true)"
  [ -z "$out" ] || fail "the built repo describes the copy: $out"
}
