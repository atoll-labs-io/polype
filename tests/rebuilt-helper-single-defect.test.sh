# s118 — the rebuilt-helper recipe plants a single defect: a helper that repeats list_for() instead of calling it.
# s119 — the plant also tests the tenant clause of archived_for(), so the copy stays the only defect.

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
  local lib="$ROOT/evals/lib.sh" cases="$ROOT/evals/cases"
  [ "$(grep -cF 'if note.owner_id != user.id:' "$lib")" = 1 ] || fail "get's owner check changed"
  [ "$(grep -cF 'if note.owner_id == user.id and note.tenant_id == user.tenant_id' "$lib")" = 1 ] \
    || fail "list_for's filter changed"
  grep -qF 'if note.shared]' "$cases/missing-tenant-filter.sh" || fail "missing-tenant-filter changed"
}

rh_names_no_flaw() {
  local paths=(app tests docs/stories.md docs/plans docs/research) out
  out="$(git -C "$RH_WT" grep -niE 'CASE_|defect|bug|IDOR|duplicat|rebuil' "story/$RH_ID" -- "${paths[@]}" || true)"
  [ -z "$out" ] || fail "the built repo names the flaw: $out"
  out="$(git -C "$RH_WT" grep -niE 'repeat|cop(y|ies)|line for line|instead of call' "story/$RH_ID" -- "${paths[@]}" || true)"
  [ -z "$out" ] || fail "the built repo describes the copy: $out"
}

test_recipe_names_no_flaw() {
  rh_build
  rh_names_no_flaw
}

test_plant_tests_the_tenant_boundary() {
  local added out
  rh_build
  added="$(git -C "$RH_WT" diff "main...story/$RH_ID" -- tests/test_notes.py | grep '^+')"
  grep -E 'Note\(.*owner_id=1, tenant_id=[0-9]+.*archived=True' <<< "$added" | grep -vE 'tenant_id=10[,)]' | grep -q . \
    || fail "the plant adds no archived note of user 1 in another tenant: $added"
  (cd "$RH_WT" && python3 -m unittest discover -s tests -t . >/dev/null 2>&1) || fail "the built suite is not green"
  (cd "$RH_WT" && sed -i '/def archived_for/,$ s/ and note.tenant_id == user.tenant_id//' app/notes.py)
  [ "$(grep -cF 'if note.owner_id == user.id and note.tenant_id == user.tenant_id' "$RH_WT/app/notes.py")" = 1 ] \
    || fail "the mutation did not hit archived_for alone"
  if out="$(cd "$RH_WT" && python3 -m unittest discover -s tests -t . 2>&1)"; then
    fail "removing the tenant clause of archived_for leaves the suite green"
  fi
  grep -qF 'test_archived_for_skips_notes_of_other_tenants' <<< "$out" \
    || fail "the failing test is not the tenant one: $out"
}

test_copy_stays_the_only_defect() {
  local case="$ROOT/evals/cases/rebuilt-helper.sh" added
  grep -qx 'CASE_EXPECT_SEVERITY=major' "$case" && grep -qx 'CASE_EXPECT_SHIP=yes' "$case" \
    || fail "rebuilt-helper must expect major / ship yes"
  rh_build
  added="$(git -C "$RH_WT" diff "main...story/$RH_ID" -- app/notes.py | grep '^+' | grep -v '^+++ ')"
  grep -qF 'def archived_for(self, user):' <<< "$added" \
    && grep -qF 'if note.owner_id == user.id and note.tenant_id == user.tenant_id' <<< "$added" \
    || fail "archived_for no longer repeats list_for's filter: $added"
  ! grep -qF 'self.list_for(' <<< "$added" || fail "archived_for calls list_for"
  rh_names_no_flaw
}
