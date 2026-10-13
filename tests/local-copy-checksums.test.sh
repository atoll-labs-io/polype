#!/usr/bin/env bash
# s123 — the sums of the .claude/ copies live next to them, out of git.

POLYPE="$ROOT/bin/polype"
LOCAL=.claude/.polype-checksums
EDITED=.claude/commands/po-execute.md
REFRESHED=.claude/commands/po-plan.md

project() { scratch_repo; P="$SCRATCH"; }
polype() { bash "$POLYPE" "$@" >/dev/null 2>&1 || fail "polype failed: $*"; }

# The developer's own git excludes may ignore .claude/; tests must not depend on them.
no_user_excludes() { mkdir -p "$SCRATCH/.xdg"; export XDG_CONFIG_HOME="$SCRATCH/.xdg"; }

# A newer method: a copy of bin/ and method/ where po-plan.md and a template gained a line, so
# its refresh changes the committed .polype/ too. Sets NEW.
newer_method() {
  local copy="$SCRATCH/.method-copy"
  mkdir -p "$copy"
  cp -r "$ROOT/bin" "$ROOT/method" "$copy/"
  printf 'a line shipped by a newer version\n' >> "$copy/method/commands/po-plan.md"
  printf 'a line shipped by a newer version\n' >> "$copy/method/templates/plan.md"
  NEW="$copy/bin/polype"
}

commit_all() { git -C "$1" add -A && git -C "$1" commit -qm "$2" || fail "commit failed in $1"; }

# Q is a clone of P with its own identity, since the global git config is /dev/null.
clone_of_p() {
  Q="$SCRATCH/.clone"
  git clone -q "file://$P" "$Q" || fail "clone failed"
  git -C "$Q" config user.email test@example.com
  git -C "$Q" config user.name test
  git -C "$Q" config commit.gpgsign false
}

pull_q_into_p() { git -C "$P" pull -q --ff-only "file://$Q" main || fail "pull failed"; }

test_local_copies_have_local_sums() {
  project
  local claude_lines
  polype install "$P"
  require_file "$P/$LOCAL"
  claude_lines="$(grep '^\.claude/' "$P/.polype/manifest" | sort)"
  [ -n "$claude_lines" ] || fail "the manifest lists no .claude/ copy"
  [ "$(awk '{print $3}' "$P/$LOCAL" | sort)" = "$claude_lines" ] || fail "the local sums do not cover every .claude/ copy"
  if grep -q ' \.claude/' "$P/.polype/checksums"; then fail ".polype/checksums still holds .claude/ sums"; fi
  polype update "$P"
  [ "$(awk '{print $3}' "$P/$LOCAL" | sort)" = "$claude_lines" ] || fail "update lost local sums"
  if grep -q ' \.claude/' "$P/.polype/checksums"; then fail "update wrote .claude/ sums to .polype/checksums"; fi

  # Going from install to init, straight over the install: the local sums left by it must go.
  mkdir -p "$SCRATCH/.home"
  CLAUDE_CONFIG_DIR="$SCRATCH/.home" bash "$POLYPE" init "$P" >/dev/null 2>&1 || fail "init failed"
  require_file "$P/.polype/checksums"
  if [ -e "$P/$LOCAL" ]; then fail "init left local sums though it lays no .claude/ copy"; fi

  polype install "$P"
  require_file "$P/$LOCAL"
  polype remove "$P"
  if [ -e "$P/$LOCAL" ]; then fail "remove left the local sums behind"; fi
  if [ -e "$P/.claude/commands" ]; then fail "remove left .claude/commands behind"; fi
}

test_update_after_a_pr_refresh_replaces_stale_copies() {
  project && newer_method
  printf '.claude/\n' > "$P/.gitignore"
  polype install "$P"
  commit_all "$P" "install"
  printf 'our own rule\n' >> "$P/$EDITED"
  clone_of_p
  polype update "$Q"
  bash "$NEW" update "$Q" >/dev/null 2>&1 || fail "update with the newer method failed in the clone"
  commit_all "$Q" "refresh"
  pull_q_into_p

  local err
  err="$(bash "$NEW" update "$P" 2>&1 >/dev/null)" || fail "update failed: $err"
  grep -qxF 'a line shipped by a newer version' "$P/$REFRESHED" || fail "the stale copy was not refreshed"
  if grep -qF "$REFRESHED" <<< "$err"; then fail "the stale copy was named as modified: $err"; fi
  grep -qxF 'our own rule' "$P/$EDITED" || fail "the hand-edited copy was overwritten"
  grep -qF "modified, left as it is: $EDITED" <<< "$err" || fail "the hand-edited copy was not named: $err"
}

# A checkout already migrated pulls a .polype/checksums committed by a checkout still on the
# old installer, whose .claude/ lines hold the sums of newer copies: the local sums must win.
test_local_sums_win_over_an_old_format_polype_checksums() {
  project && newer_method
  polype install "$P"
  local other="$SCRATCH/.other"
  mkdir -p "$other"
  bash "$NEW" install "$other" >/dev/null 2>&1 || fail "install with the newer method failed"
  grep ' \.claude/' "$other/$LOCAL" >> "$P/.polype/checksums"

  local err
  err="$(bash "$NEW" update "$P" 2>&1 >/dev/null)" || fail "update failed: $err"
  grep -qxF 'a line shipped by a newer version' "$P/$REFRESHED" || fail "the stale copy was not refreshed"
  if grep -qF 'modified, left as it is' <<< "$err"; then fail "an old-format .polype/checksums beat the local sums: $err"; fi
}

test_local_sums_file_stays_out_of_git() {
  project && no_user_excludes
  polype install "$P"
  polype install "$P"
  [ "$(grep -cxF "$LOCAL" "$P/.gitignore")" = 1 ] || fail ".gitignore does not hold $LOCAL exactly once"
  if git -C "$P" status --porcelain --untracked-files=all | grep -qF "$LOCAL"; then
    fail "git status lists the local sums"
  fi

  printf 'hand edit\n' >> "$P/$EDITED"
  local out
  if out="$(bash "$POLYPE" check "$P" 2>&1)"; then fail "check must exit non-zero when a copy drifted"; fi
  grep -qF "modified: $EDITED" <<< "$out" || fail "check did not name the drifted copy: $out"

  rm -rf "$SCRATCH"
  project && no_user_excludes
  printf '.claude/\n' > "$P/.gitignore"
  polype install "$P"
  if grep -qxF "$LOCAL" "$P/.gitignore"; then fail "the line was added though git already ignores the file"; fi
}

test_first_update_migrates() {
  project
  polype install "$P"
  cat "$P/$LOCAL" >> "$P/.polype/checksums"
  rm "$P/$LOCAL"
  printf 'hand edit\n' >> "$P/$EDITED"
  local err
  err="$(bash "$POLYPE" update "$P" 2>&1 >/dev/null)" || fail "update failed: $err"
  grep -qF "modified, left as it is: $EDITED" <<< "$err" || fail "the hand-edited copy was not named: $err"
  [ "$(grep -c 'modified, left as it is' <<< "$err")" = 1 ] || fail "untouched copies were named: $err"
  require_file "$P/$LOCAL"
  grep -q ' \.claude/' "$P/$LOCAL" || fail "the local sums hold no .claude/ line"
  if grep -q ' \.claude/' "$P/.polype/checksums"; then fail ".polype/checksums kept .claude/ sums"; fi
  grep -qF '.claude/.polype-checksums written' <<< "$err" || fail "the migration was not announced: $err"
}

test_committed_copies_refreshed_by_a_pr_stay_intact() {
  project && newer_method && no_user_excludes
  polype install "$P"
  commit_all "$P" "install"
  git -C "$P" ls-files --error-unmatch "$REFRESHED" >/dev/null 2>&1 || fail ".claude/ was not committed"
  clone_of_p
  bash "$NEW" update "$Q" >/dev/null 2>&1 || fail "update with the newer method failed in the clone"
  commit_all "$Q" "refresh"
  pull_q_into_p

  local err
  err="$(bash "$NEW" update "$P" 2>&1 >/dev/null)" || fail "update failed: $err"
  if grep -qF 'modified, left as it is' <<< "$err"; then fail "a copy refreshed by the pull read as modified: $err"; fi
  bash "$NEW" check "$P" >/dev/null 2>&1 || fail "check reports drift after the update"
}

test_installation_doc_names_the_local_sums() {
  local section phrase
  section="$(awk "/^## Les fichiers d'état\$/ {on=1; next} /^## / {on=0} on" "$ROOT/docs/installation.md")"
  [ -n "$section" ] || fail "docs/installation.md has no ## Les fichiers d'état section"
  for phrase in '.claude/.polype-checksums' 'ADR-0087' 'ignoré par git'; do
    grep -qF -- "$phrase" <<< "$section" || fail "the state-files section does not say: $phrase"
  done
}
