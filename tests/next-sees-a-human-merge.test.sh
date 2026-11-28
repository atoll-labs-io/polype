#!/usr/bin/env bash
# s218 — the story's own tests, beside its oracle: a fetch that fails changes nothing, and the forge
# is read only when some lane awaits a merge. The oracle's helpers are sourced inside each test's
# subshell, so its tests do not run twice.

# The actions of the last `po next`, one line each.
actions_of() { jq -c '[.actions[] | {story, action, reason}]' <<< "$OUT"; }

test_unreachable_origin_changes_nothing() {
  ( # shellcheck source=/dev/null
    source "$ROOT/tests/next-sees-a-human-merge.oracle.test.sh"
    merge_project 'human (chosen)'
    git -C "$F" config "url.$SCRATCH/missing.git.insteadOf" https://github.com/acme/app.git
    git -C "$F" config --unset "url.$ORIGIN.insteadOf"
    po_in "$F" next
    next_shape "po next"
    local offline
    offline="$(actions_of)"
    po_in "$F" next --remote
    next_shape "po next --remote, origin unreachable"
    [ "$(actions_of)" = "$offline" ] \
      || fail "a failed fetch changed po next --remote: $(actions_of), offline $offline"
  ) || exit 1
}

test_forge_read_only_when_a_merge_waits() {
  ( # shellcheck source=/dev/null
    source "$ROOT/tests/next-sees-a-human-merge.oracle.test.sh"
    source "$ROOT/tests/driver-next-action.oracle.test.sh"
    project
    setting 'Merge mode' pr
    setting 'Ship confirmation' automatic
    story s01-alpha command - 'src/a/'
    start
    ORIGIN="$SCRATCH/origin.git"
    git init -q --bare -b main "$ORIGIN"
    git -C "$F" remote add origin https://github.com/acme/app.git
    git -C "$F" config "url.$ORIGIN.insteadOf" https://github.com/acme/app.git
    git -C "$F" push -q origin main
    lane s01-alpha
    research_in s01-alpha
    plan_in s01-alpha yes
    git -C "$W" push -q origin story/s01-alpha
    forge_doubles
    solo_forge
    mv "$SCRATCH/gh" "$SCRATCH/gh-answers"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s/gh.log"\nexec "%s/gh-answers" "$@"\n' \
      "$SCRATCH" "$SCRATCH" > "$SCRATCH/gh"
    chmod +x "$SCRATCH/gh"
    : > "$SCRATCH/gh.log"
    po_in "$F" next --remote
    next_shape "po next --remote, lane at execute"
    jq -e '.actions[] | select(.story == "s01-alpha") | .action == "execute"' <<< "$OUT" >/dev/null \
      || fail "s01-alpha is not at execute: $OUT"
    if grep -qE '(^| )(user|repos/acme/app/collaborators)( |$)' "$SCRATCH/gh.log"; then
      fail "po next --remote read the forge with no lane awaiting a merge: $(cat "$SCRATCH/gh.log")"
    fi
  ) || exit 1
}
