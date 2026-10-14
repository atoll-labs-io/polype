#!/usr/bin/env bash
# s127 — hooks, installer and docs keep no trace of an older behaviour.

GATE="$METHOD/hooks/po-gate.sh"

test_hooks_say_what_they_do_scan_reads_the_base() {
  scratch_repo
  cd "$SCRATCH"
  echo a > f.md && git add f.md && git commit -qm base
  local base; base="$(git rev-parse HEAD)"
  printf 'token %s%s\n' 'ghp_' "$(printf 'A%.0s' {1..36})" >> f.md
  echo X=1 > .env && echo notes > CLAUDE.md
  git add -f f.md .env CLAUDE.md && git commit -qm head
  # Each temp index adds over the base one file HEAD already tracks, so only a diff against the base sees it.
  local file idx err
  for file in f.md .env CLAUDE.md; do
    idx="$SCRATCH/.tmp-index-$file"
    GIT_INDEX_FILE="$idx" git read-tree "$base"
    GIT_INDEX_FILE="$idx" git add -f "$file"
    if err=$(GIT_INDEX_FILE="$idx" bash "$GATE" pre-commit "$base" 2>&1); then
      fail "$file, which the commit adds over its base, slipped past the scan"
    fi
    case "$file" in
      f.md) grep -qF 'github-token' <<< "$err" || fail "refusal does not name the rule: $err" ;;
      *) grep -qF "$file" <<< "$err" || fail "refusal does not name $file: $err" ;;
    esac
  done
  if GIT_INDEX_FILE="$idx" bash "$GATE" pre-commit no-such-base 2>/dev/null; then
    fail "an unreadable base was accepted"
  fi
  contains "$METHOD/commands/po-setup.md" 'po-gate.sh pre-commit <base>'
}

test_hooks_say_what_they_do_story_list_reads_the_base() {
  scratch_repo
  cd "$SCRATCH"
  git symbolic-ref HEAD refs/heads/story/s01-a
  echo a > f.md && git add f.md && git commit -qm base
  local base idx="$SCRATCH/.tmp-index" err; base="$(git rev-parse HEAD)"
  mkdir -p src && echo x > src/app.txt && git add src/app.txt && git commit -qm head
  GIT_INDEX_FILE="$idx" git read-tree "$base"
  GIT_INDEX_FILE="$idx" git add src/app.txt
  if err=$(GIT_INDEX_FILE="$idx" bash "$GATE" pre-commit "$base" 2>&1); then
    fail "code added over the base reached story/s01-a without an approved plan"
  fi
  grep -qF 'before its plan is approved' <<< "$err" || fail "refusal does not name the plan: $err"
}

test_hooks_say_what_they_do_no_squash() {
  local f
  for f in "$GATE" "$ROOT/README.md"; do
    if grep -qi squash "$f"; then fail "${f#"$ROOT"/} still speaks of a squash"; fi
  done
}

test_hooks_say_what_they_do_findings_bullet_warned() {
  contains "$METHOD/templates/review.md" 'a finding never starts with `Ship allowed:`'
  scratch_repo
  cd "$SCRATCH"
  mkdir -p docs/reviews src && echo x > src/app.txt
  git add -A && git commit -qm init
  local tree; tree="$(git rev-parse 'HEAD^{tree}')"
  # ADR-0056: any `Ship allowed:` line bounds a verdict block, so such a bullet cuts the verdict from its tree.
  printf 'Review status: complete\nReviewed tree: %s\n## Findings\n- Ship allowed: read from a quoted line — minor\nMax severity: minor\nShip allowed: yes\n' \
    "$tree" > docs/reviews/s01-a.md
  if bash "$GATE" ship-allowed s01-a 2>/dev/null; then fail "a findings bullet starting with 'Ship allowed:' did not refuse"; fi
}

test_hooks_say_what_they_do_env_word_forks_none() {
  if grep -qF '$(git_env_word' "$METHOD/hooks/po-bounds.sh"; then fail "po-bounds.sh still forks a subshell per word"; fi
}

test_installer_and_docs_agree_remove_without_jq() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test and is not installed"
  scratch_repo
  export HOME="$SCRATCH/home" CLAUDE_CONFIG_DIR="$SCRATCH/home/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
  local polype="$ROOT/bin/polype" bin="$SCRATCH/bin" cmd p q before err
  mkdir -p "$bin"
  for cmd in bash env cat cp mv rm rmdir mkdir chmod find sed sort head tail grep awk git wc cksum dirname basename readlink touch tr; do
    ln -s "$(command -v "$cmd")" "$bin/$cmd"
  done
  if PATH="$bin" command -v jq >/dev/null 2>&1; then fail "jq is still reachable from the test PATH"; fi

  p="$SCRATCH/p"; mkdir -p "$p" && git -C "$p" init -q -b main
  bash "$polype" install "$p" >/dev/null 2>&1 || fail "install failed"
  before="$(cat "$p/.claude/settings.json")"
  err="$(PATH="$bin" "$bin/bash" "$polype" remove "$p" 2>&1 >/dev/null)" || fail "remove failed without jq: $err"
  grep -qF 'still runs .polype/hooks/po-session.sh' <<< "$err" || fail "remove without jq did not name the dangling hook: $err"
  [ "$(cat "$p/.claude/settings.json")" = "$before" ] || fail "remove without jq rewrote .claude/settings.json"

  q="$SCRATCH/q"; mkdir -p "$q" && git -C "$q" init -q -b main
  bash "$polype" install "$q" >/dev/null 2>&1 || fail "install failed"
  printf '%s\n' '{"permissions":{}}' > "$q/.claude/settings.json"
  err="$(PATH="$bin" "$bin/bash" "$polype" remove "$q" 2>&1 >/dev/null)" || fail "remove failed without jq: $err"
  if grep -qF 'still runs' <<< "$err"; then fail "remove warned about a hook the file does not hold: $err"; fi
}

test_installer_and_docs_agree_installation_doc() {
  local doc="$ROOT/docs/installation.md" sec long
  require_file "$doc"
  sec="$(awk '/^## Activer un projet$/ {on=1; next} /^## / {on=0} on' "$doc")"
  grep -qF 'fusionné dans `.claude/settings.json`' <<< "$sec" || fail "the project list does not name the merged settings hook"
  sec="$(awk '/^### Un projet en `Merge mode: local` qui a un remote$/ {on=1; next} /^##/ {on=0} on' "$doc")"
  [ -n "$sec" ] || fail "no subsection on a local-mode project with a remote"
  grep -qF 'Merge mode: pr' <<< "$sec" || fail "the local-mode subsection does not name Merge mode: pr"
  grep -qF 'ADR-0080' <<< "$sec" || fail "the local-mode subsection does not cite ADR-0080"
  long="$(LC_ALL=C.UTF-8 awk '/^```/ {f = !f; next} !f && length > 100 {print NR}' "$doc")"
  [ -z "$long" ] || fail "prose lines over 100 characters: $long"
}

test_installer_and_docs_agree_frontmatter_and_brief() {
  local adr brief="$METHOD/templates/brief.md"
  adr="$(ls "$ROOT"/docs/decisions/ADR-0080-*.md)"
  frontmatter "$adr" | grep -qx 'superseded-by: \[ADR-0081\]' || fail "ADR-0080 does not point at ADR-0081"
  frontmatter "$adr" | grep -qx 'status: accepted' || fail "ADR-0080 is no longer accepted"
  if grep -qF 'read the whole' "$brief"; then fail "templates/brief.md still asks to read the whole brief"; fi
  contains "$brief" 'approved on its own question'
}

test_drivers_and_doctrine_read_right_texts() {
  local scene="$METHOD/skills/qa-drivers/scene.md" profile="$ROOT/boilerplates/godot/profile.md"
  contains "$scene" 'application/run/main_scene'
  if grep -qF 'the `run/main_scene`' "$scene"; then fail "scene.md still names the short Godot key"; fi
  grep -F 'Engine command:' "$profile" | grep -qF 'default resolution' \
    || fail "the engine command line does not say 1920x1080 is the default"
  contains "$METHOD/skills/testing-doctrine/SKILL.md" "-- '<command>'\`, which writes their row"
}
