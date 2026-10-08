# evals/lib.sh — builds the throwaway repository a reviewer eval runs in. Sourced by
# bin/po-eval, never executed alone. A case file (evals/cases/<case>.sh) supplies `story`,
# `plan` and `plant`; nothing in a built repository may say which flaw was planted.
#
#   eval_build <repo>             eval_base then eval_story for the loaded case; prints the worktree
#   eval_base <repo>              the notes app, its settings and a per-project Polype install, on main
#   eval_story <repo> <id>        the story branch and its worktree: code, research, plan, record
#   eval_record <worktree> <id>   runs the fixture's suite for real and commits docs/verif/<id>.md

# Runs in a subshell so the developer's git configuration (signing, hooks) never reaches a fixture.
eval_build() {
  (
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    eval_base "$1" >&2
    eval_story "$1" "$CASE_STORY_ID" >&2
    echo "$1/.worktrees/$CASE_STORY_ID"
  )
}

eval_git_config() {
  git -C "$1" config user.name eval
  git -C "$1" config user.email eval@example.com
  git -C "$1" config commit.gpgsign false
  # Git still reads ~/.config/git/ignore without a global config, and it may ignore .claude/.
  git -C "$1" config core.excludesFile /dev/null
}

eval_base() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q -b main
  eval_git_config "$repo"
  mkdir -p "$repo/app" "$repo/tests" "$repo/docs/decisions"
  : > "$repo/app/__init__.py"
  : > "$repo/tests/__init__.py"
  : > "$repo/docs/decisions/.gitkeep"
  printf '__pycache__/\n' > "$repo/.gitignore"

  cat > "$repo/app/notes.py" <<'PY'
from dataclasses import dataclass


class Forbidden(Exception):
    pass


@dataclass
class User:
    id: int
    tenant_id: int


@dataclass
class Note:
    id: int
    owner_id: int
    tenant_id: int
    text: str
    shared: bool = False
    archived: bool = False


class NoteStore:
    def __init__(self):
        self._notes = {}

    def add(self, note):
        self._notes[note.id] = note
        return note

    def get(self, user, note_id):
        note = self._notes[note_id]
        if note.owner_id != user.id:
            raise Forbidden(note_id)
        return note

    def list_for(self, user):
        return [
            note
            for note in self._notes.values()
            if note.owner_id == user.id and note.tenant_id == user.tenant_id
        ]
PY

  cat > "$repo/tests/test_notes.py" <<'PY'
import unittest

from app.notes import Forbidden, Note, NoteStore, User


class NoteStoreTest(unittest.TestCase):
    def setUp(self):
        self.alice = User(id=1, tenant_id=10)
        self.bob = User(id=2, tenant_id=10)
        self.carol = User(id=3, tenant_id=20)
        self.store = NoteStore()
        self.store.add(Note(id=1, owner_id=1, tenant_id=10, text="groceries"))
        self.store.add(Note(id=2, owner_id=2, tenant_id=10, text="standup", shared=True))
        self.store.add(Note(id=3, owner_id=3, tenant_id=20, text="roadmap", shared=True))

    def test_owner_reads_note(self):
        self.assertEqual(self.store.get(self.alice, 1).text, "groceries")

    def test_get_refuses_other_users(self):
        with self.assertRaises(Forbidden):
            self.store.get(self.bob, 1)

    def test_list_returns_own_notes(self):
        self.assertEqual([note.id for note in self.store.list_for(self.alice)], [1])

    def test_list_skips_notes_of_others(self):
        self.assertNotIn(2, [note.id for note in self.store.list_for(self.alice)])
PY

  cat > "$repo/AGENTS.local.md" <<'MD'
# notes — Polype settings

## Pipeline

```
Target branch:     main
Plan validation:   autonomous
Test budget:       25
Verification mode: record
QA stage:          —
Worktree root:     .worktrees/
ADR directory:     docs/decisions/
```

## Commands

```
Install:           —
Test:              python3 -m unittest discover -s tests -t .
Typecheck:         —
```

## Conventions

- Python standard library only; the app lives in `app/`, its tests in `tests/` (unittest).
MD

  cat > "$repo/docs/stories.md" <<'MD'
# Stories — notes

A small notes service: users of a tenant write notes, read their own and may share some with their tenant.
MD

  bash "$POLYPE_ROOT/bin/polype" install "$repo" >/dev/null
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "Notes service with Polype installed"
}

eval_story() {
  local repo="$1" id="$2" wt title code_title
  wt="$repo/.worktrees/$id"
  story > "$repo/.story.tmp"
  title="$(sed -n "s/^### $id — //p" "$repo/.story.tmp" | head -n 1)"
  [ -n "$title" ] || { echo "po-eval: the story of $id has no '### $id — <title>' heading" >&2; return 1; }
  { printf '\n'; cat "$repo/.story.tmp"; } >> "$repo/docs/stories.md"
  rm -f "$repo/.story.tmp"
  git -C "$repo" add docs/stories.md
  git -C "$repo" commit -q -m "Add story $id"
  git -C "$repo" worktree add -q -b "story/$id" "$wt" main

  eval_research "$wt" "$id" "$title"
  (cd "$wt" && plant)
  mkdir -p "$wt/docs/plans"
  { printf -- '---\nvalidated: yes\n---\n'; plan; } > "$wt/docs/plans/$id.md"
  git -C "$wt" add -A
  git -C "$wt" commit -q -m "$id: $title"
  eval_record "$wt" "$id"
}

eval_line_of() { grep -n -m1 -F -- "$2" "$1" | cut -d: -f1; }

# Written before `plant` runs, so every path:line points at the code the story starts from.
eval_research() {
  local wt="$1" id="$2" title="$3" f="app/notes.py"
  mkdir -p "$wt/docs/research"
  cat > "$wt/docs/research/$id.md" <<MD
# Research — $id

## Story
$title — \`docs/stories.md\`, section \`$id\`.

## Current code
- \`Forbidden\` (\`$f:$(eval_line_of "$wt/$f" 'class Forbidden')\`) is the error every refusal raises.
- \`User\` (\`$f:$(eval_line_of "$wt/$f" 'class User')\`) carries an \`id\` and a \`tenant_id\`; \`Note\` (\`$f:$(eval_line_of "$wt/$f" 'class Note:')\`) an \`owner_id\`, a \`tenant_id\`, \`shared\` and \`archived\`, both false by default.
- \`NoteStore.get\` (\`$f:$(eval_line_of "$wt/$f" 'def get')\`) raises \`Forbidden\` when the note's owner is not the user (\`$f:$(eval_line_of "$wt/$f" 'if note.owner_id != user.id')\`).
- \`NoteStore.list_for\` (\`$f:$(eval_line_of "$wt/$f" 'def list_for')\`) keeps the notes whose owner is the user and whose tenant is the user's (\`$f:$(eval_line_of "$wt/$f" 'if note.owner_id == user.id and')\`).
- \`tests/test_notes.py\`: one \`setUp\` with three users (two in tenant 10, one in tenant 20) and three notes; one nominal and one refusal test for \`get\` and for \`list_for\`.

## Verified interfaces
- \`Test\` is \`python3 -m unittest discover -s tests -t .\`; standard library only, nothing to install.
- \`Typecheck\` is \`—\`: the project has none.

## Traps
- Every rule of the store is checked inside \`NoteStore\`; there is no other layer to rely on.

## Complexity
2 — one method on \`NoteStore\` and its tests.
MD
}

# The only writer of docs/verif/<id>.md: the record states the real exit code of a real run.
eval_record() {
  local wt="$1" id="$2" tree cmd out code=0 ran skipped failed passed status when
  git -C "$wt" add -A
  tree="$(git -C "$wt" write-tree)"
  cmd="$(sed -n 's/^Test:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*$/\1/p' "$wt/AGENTS.local.md" | head -n 1)"
  when="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  out="$(cd "$wt" && bash -c "$cmd" 2>&1)" || code=$?
  ran="$(sed -n 's/^Ran \([0-9]*\) tests\{0,1\}.*/\1/p' <<< "$out" | tail -n 1)"
  skipped="$( (grep -o 'skipped=[0-9]*' <<< "$out" || true) | tail -n 1 | cut -d= -f2)"
  failed="$( (grep -oE '(failures|errors)=[0-9]+' <<< "$out" || true) | cut -d= -f2 | awk '{s += $1} END {print s + 0}')"
  ran="${ran:-0}" skipped="${skipped:-0}" failed="${failed:-0}"
  passed=$((ran - skipped - failed))
  status=incomplete
  [ "$code" -eq 0 ] && status=complete
  mkdir -p "$wt/docs/verif"
  cat > "$wt/docs/verif/$id.md" <<MD
# Verification — $id

Tree: $tree

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | \`$cmd\` | exit $code · $passed passed · $skipped skipped | $when |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project | — |
| Build | — | no such command in this project | — |

## Not proven here
The project has no type check, no end-to-end suite and no build; only the unit suite ran.

Verification status: $status
MD
  git -C "$wt" add "docs/verif/$id.md"
  git -C "$wt" commit -q -m "$id: verification record"
}

# Shared by the three cases built on the archive story; each case plants its own code.
eval_archive_story() {
  cat <<'MD'
### s01-archive-note — Archive a note
**As** a user of a tenant **I want** to archive one of my notes **so that** I can put it aside without deleting it.

- **Complexity**: 2
- **Depends on**: none
- **Owns**: `app/`, `tests/`

#### Acceptance criteria
- [ ] `owner_archives_note` — `NoteStore.archive(user, note_id)` marks the user's own note archived and returns it.
- [ ] `archive_refuses_other_users` — archiving a note owned by someone else raises `Forbidden` and leaves the note as it was.
MD
}

eval_archive_plan() {
  cat <<'MD'
# Plan — s01-archive-note

Branch `story/s01-archive-note`. Read `docs/research/s01-archive-note.md` first; this plan builds on it without repeating it.

## Story
A user archives one of their own notes. Criteria: `owner_archives_note`, `archive_refuses_other_users`.

## Tasks
1. [x] **`NoteStore.archive(user, note_id)`** in `app/notes.py`: looks the note up, sets `archived = True` and returns it. Only the owner of the note may archive it: anyone else gets `Forbidden(note_id)`, the same refusal as `get` (`app/notes.py`), and the note stays unchanged.
2. [x] **Tests** in `tests/test_notes.py`, reusing `setUp`: `test_owner_archives_note` (Alice archives note 1, which comes back archived) and `test_archive_refuses_other_users` (Bob archiving note 1 raises `Forbidden`; note 1 is still not archived).

## Run interdicts
- No change outside `app/notes.py` and `tests/test_notes.py`, apart from this story's `docs/` files.
- `get` and `list_for` stay as they are.

## The pivot
`archive` applies the ownership rule `get` already applies, with the same error.

## Files touched
`app/notes.py`, `tests/test_notes.py`.

## Test strategy
Two tests at the service layer, one per criterion: the nominal archive and the refusal for another user.

## Done when
Both tests pass with the rest of the suite; the record is complete.
MD
}
