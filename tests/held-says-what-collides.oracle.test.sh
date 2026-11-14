#!/usr/bin/env bash
# s175 — the oracle of the story: a story held for `owns` names the two overlapping entries and one
# path both cover, and a story absent from the start point is held for `framing` (#280).

# The fixture builders of s168's oracle, loaded inside a test only, so its tests are not listed here.
s168_fixtures() {
  # shellcheck source=/dev/null
  source "$ROOT/tests/driver-next-action.oracle.test.sh"
  need_po
}

# held_of <id>: the held item of story <id> in OUT, compact, or `null`.
held_of() { jq -cS --arg id "$1" '[.held[]? | select(.story == $id)] | first // null' <<< "$OUT"; }

# held_is <id> <expected JSON object>
held_is() {
  local got
  got="$(held_of "$1")"
  [ "$got" = "$(jq -cS . <<< "$2")" ] || fail "held $1: $got instead of $(jq -cS . <<< "$2")"
}

# po_logged <dir> <args...>: po with gh, curl, wget, ssh stubbed and git logged to $SCRATCH/calls.
po_logged() {
  local dir="$1" stubs="$SCRATCH/stubs" real_git cmd
  shift
  real_git="$(command -v git)"
  mkdir -p "$stubs"
  : > "$SCRATCH/calls"
  for cmd in gh curl wget ssh; do
    printf '#!/usr/bin/env bash\nprintf "%%s %%s\\n" %s "$*" >> "%s"\nexit 0\n' "$cmd" "$SCRATCH/calls" > "$stubs/$cmd"
    chmod +x "$stubs/$cmd"
  done
  printf '#!/usr/bin/env bash\nprintf "git %%s\\n" "$*" >> "%s"\nexec "%s" "$@"\n' "$SCRATCH/calls" "$real_git" > "$stubs/git"
  chmod +x "$stubs/git"
  STATUS=0
  OUT="$(cd "$dir" && PATH="$stubs:$PATH" "$PO" "$@" 2>/dev/null)" || STATUS=$?
}

test_owns_collision_names_the_path() {
  s168_fixtures
  project
  setting Parallel 2
  story s01-alpha command - 'src/a/' 'crates/*/Cargo.toml' 'docs/**/x.md' 'tests/*.sh'
  story s02-bravo command - 'lib/' 'src/a/x.txt'
  story s03-charlie command - 'crates/core/'
  story s04-delta command - 'docs/y.md'
  story s05-echo command - 'tests/a*.sh'
  story s06-foxtrot command - 'src/'
  story s07-golf command s01-alpha 'src/g/'
  story s08-hotel command - 'other/'
  story s09-india command - 'more/'
  start
  lane s01-alpha

  po_in "$F" next
  next_shape "po next"
  held_is s02-bravo '{"story": "s02-bravo", "reason": "owns", "ref": "s01-alpha",
    "entry": "src/a/x.txt", "ref_entry": "src/a/", "path": "src/a/x.txt"}'
  held_is s03-charlie '{"story": "s03-charlie", "reason": "owns", "ref": "s01-alpha",
    "entry": "crates/core/", "ref_entry": "crates/*/Cargo.toml", "path": "crates/core/Cargo.toml"}'
  held_is s04-delta '{"story": "s04-delta", "reason": "owns", "ref": "s01-alpha",
    "entry": "docs/y.md", "ref_entry": "docs/**/x.md", "path": null}'
  held_is s05-echo '{"story": "s05-echo", "reason": "owns", "ref": "s01-alpha",
    "entry": "tests/a*.sh", "ref_entry": "tests/*.sh", "path": null}'
  held_is s06-foxtrot '{"story": "s06-foxtrot", "reason": "owns", "ref": "s01-alpha",
    "entry": "src/", "ref_entry": "src/a/", "path": "src/a/"}'
  held_is s07-golf '{"story": "s07-golf", "reason": "dependency", "ref": "s01-alpha"}'
  held_is s09-india '{"story": "s09-india", "reason": "parallel", "ref": null}'
  jq -e '.ready == ["s08-hotel"]' <<< "$OUT" >/dev/null || fail "the collision fields changed the ready set: $OUT"

  local next="$OUT"
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  jq -e --argjson n "$next" '.held == $n.held' <<< "$OUT" >/dev/null \
    || fail "po state does not carry the held items of po next: $(jq -c .held <<< "$OUT")"
}

test_story_off_the_start_point_is_held() {
  s168_fixtures
  project
  setting Parallel 2
  story s01-alpha command - 'src/a/'
  story s03-charlie command - 'src/c/'
  story s04-delta command - 'src/d/'
  start
  git -C "$F" update-ref refs/remotes/origin/main main
  # The framing of s02-bravo lands on main only: its pull request has not merged on origin.
  printf '# Stories\n\n## M1 — Fixture\n\n' > "$F/docs/stories.md"
  story s01-alpha command - 'src/a/'
  story s02-bravo command - 'src/b/'
  story s03-charlie command - 'src/c/'
  story s04-delta command - 'src/d/'
  git -C "$F" commit -qam 'framing: s02-bravo'

  po_logged "$F" next
  next_shape "po next"
  jq -e '.ready == ["s01-alpha"] and all(.actions[]; .story != "s02-bravo")' <<< "$OUT" >/dev/null \
    || fail "a story off origin/main is ready or has an action: $OUT"
  held_is s02-bravo '{"story": "s02-bravo", "reason": "framing", "ref": "origin/main"}'
  held_is s03-charlie '{"story": "s03-charlie", "reason": "parallel", "ref": null}'
  if grep -qE '^(gh|curl|wget|ssh) ' "$SCRATCH/calls"; then fail "po next asked a forge: $(cat "$SCRATCH/calls")"; fi
  if grep '^git ' "$SCRATCH/calls" | grep -qwE 'fetch|pull|push|ls-remote|remote'; then
    fail "po next asked a remote instead of the local ref: $(grep '^git ' "$SCRATCH/calls")"
  fi

  local next="$OUT"
  po_in "$F" state
  [ "$STATUS" -eq 0 ] || fail "po state exited $STATUS: $OUT"
  jq -e --argjson n "$next" '.held == $n.held and .ready == $n.ready' <<< "$OUT" >/dev/null \
    || fail "po state does not carry what po next holds: $(jq -c '{ready, held}' <<< "$OUT")"

  # Without origin/main the start point is main itself, which holds every story it lists.
  git -C "$F" update-ref -d refs/remotes/origin/main
  po_in "$F" next
  next_shape "po next without origin"
  jq -e '.ready == ["s01-alpha", "s02-bravo"]' <<< "$OUT" >/dev/null \
    || fail "without origin/main, main is not the start point: $OUT"
}

test_routing_cases_follow() {
  s168_fixtures
  local file name body collisions=0 framings=0 failed="" out
  for file in "$CASES"/*.cases; do
    for name in $(bash -c "source '$file' && declare -F" | awk '$3 ~ /^case_/ {print $3}'); do
      body="$(bash -c "source '$file' && declare -f '$name'")"
      if grep -q 'expect_collision ' <<< "$body"; then
        collisions=$((collisions + 1))
      elif grep -qE 'expect_held [^ ]+ framing ' <<< "$body"; then
        framings=$((framings + 1))
      else
        continue
      fi
      if ! out="$( (
          project
          : > "$SCRATCH/expect"
          # shellcheck source=/dev/null
          source "$file"
          "$name"
          po_in "$F" next
          next_shape "$name"
          check_expectations
          [ -z "$BAD" ] || fail "$BAD"
          # The collision lines are checked here too, so a replay that skips them cannot pass.
          grep -q "^collision"$'\t' "$SCRATCH/expect" || grep -q $'^held\t[^\t]*\tframing\t' "$SCRATCH/expect" \
            || fail "the case records neither a collision nor a framing hold"
          while IFS=$'\t' read -r kind id entry ref_entry path; do
            [ "$kind" = collision ] || continue
            got="$(jq -c --arg id "$id" '[.held[]? | select(.story == $id) | [.entry, .ref_entry, (.path // "null")]]' <<< "$OUT")"
            [ "$got" = "$(jq -cn --arg a "$entry" --arg b "$ref_entry" --arg c "$path" '[[$a, $b, $c]]')" ] \
              || fail "collision $id: $got instead of [$entry, $ref_entry, $path]"
          done < "$SCRATCH/expect"
        ) 2>&1 )"; then
        failed+="  ${file##*/} $name: $out"$'\n'
      fi
    done
  done
  [ "$collisions" -ge 1 ] || fail "no routing case under tests/fixtures/driver-cases/ calls expect_collision"
  [ "$framings" -ge 1 ] || fail "no routing case under tests/fixtures/driver-cases/ expects a framing hold"
  [ -z "$failed" ] || fail "routing cases of s175 that po next does not follow:
$failed"
}
