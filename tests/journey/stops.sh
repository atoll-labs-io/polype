#!/usr/bin/env bash
# The stop journeys: each stop_* builds or restores a kind of throwaway project, changes one
# setting, one story field, one file on main or the written answers, and runs real journeys through
# po next --remote until a run ends on an ask. Sourced after tests/journey/journey.sh; it only
# defines stop_* functions, each run in its own subshell.

stop_story_track_unreadable() {
  journey_kind local
  journey_setting 'Story track' sometimes
  journey_story s01-stop 'Un arrêt'
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_qa_stage_unreadable() {
  journey_kind local
  journey_setting 'QA stage' sometimes
  journey_story s01-stop 'Un arrêt'
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_flow_threshold_unreadable() {
  journey_kind local
  journey_setting 'Flow threshold' low
  journey_story s01-stop 'Un arrêt'
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_no_complexity() {
  journey_kind local
  journey_story s01-stop 'Un arrêt'
  journey_story_set s01-stop Complexité -
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_plan_validation_unreadable() {
  journey_kind local
  journey_setting 'Plan validation' sometimes
  journey_story s01-stop 'Un arrêt'
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_root_cause_not_found() {
  journey_kind local
  journey_story s01-stop 'Un arrêt' "$JOURNEY_SRC/answers/root-cause"
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_technical_choice() {
  journey_kind local
  journey_story s01-stop 'Un arrêt'
  journey_answers s01-stop "$JOURNEY_SRC/answers/choice" "$JOURNEY_SRC/answers/plain"
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_no_gate() {
  journey_kind local
  git -C "$R" rm -q --cached .polype/hooks/po-gate.sh && git -C "$R" commit -qm 'gate dropped from main' \
    || fail "cannot drop po-gate.sh from main"
  journey_story s01-stop 'Un arrêt'
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_findings_shape() {
  journey_kind local
  journey_story s01-stop 'Un arrêt'
  journey_answers s01-stop "$JOURNEY_SRC/answers/shape" "$JOURNEY_SRC/answers/plain"
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_review_without_verdict() {
  journey_kind local
  journey_story s01-stop 'Un arrêt'
  journey_answers s01-stop "$JOURNEY_SRC/answers/no-verdict" "$JOURNEY_SRC/answers/plain"
  # The coordinator stopped between po record and the blocked report it owed.
  journey_record_blocked() { :; }
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_max_attempts_unreadable() {
  journey_kind local
  journey_setting 'Max attempts' two
  journey_story s01-stop 'Un arrêt'
  journey_answers s01-stop "$JOURNEY_SRC/answers/refused" "$JOURNEY_SRC/answers/plain"
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_max_attempts_reached() {
  journey_kind local
  journey_story s01-stop 'Un arrêt'
  journey_answers s01-stop "$JOURNEY_SRC/answers/refused" "$JOURNEY_SRC/answers/plain"
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_design_source_unset() {
  journey_kind screen
  journey_setting 'Design source' —
  journey_story s01-stop 'Un arrêt'
  journey_story_set s01-stop Surface screen
  journey_answers s01-stop "$JOURNEY_SRC/answers/screen" "$JOURNEY_SRC/answers/plain"
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_no_design_system() {
  journey_kind screen
  git -C "$R" rm -q docs/design-system.md && git -C "$R" commit -qm 'no design system on main' \
    || fail "cannot remove docs/design-system.md from main"
  journey_story s01-stop 'Un arrêt'
  journey_story_set s01-stop Surface screen
  journey_answers s01-stop "$JOURNEY_SRC/answers/screen" "$JOURNEY_SRC/answers/plain"
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_qa_committed_twice() {
  journey_kind screen
  journey_story s01-stop 'Un arrêt'
  journey_story_set s01-stop Surface screen
  journey_answers s01-stop "$JOURNEY_SRC/answers/qa-twice" "$JOURNEY_SRC/answers/screen" "$JOURNEY_SRC/answers/plain"
  # The walk is blocked, then the person settles it and runs /po-qa by hand.
  if journey_run; then return 1; fi
  journey_stopped_on_ask || return 1
  journey_by_hand s01-stop qa || return 1
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_pull_request_closed() {
  journey_kind pr-human
  journey_story s01-stop 'Un arrêt'
  if journey_run; then return 1; fi
  local url
  url="$(awk -F'\t' '$1 == "pr-waiting" && $2 == "s01-stop" {print $3}' "$JOURNEY_LOG")"
  [ -n "$url" ] || return 1
  gh pr close "$url" --repo github.com/acme/project >/dev/null || return 1
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}

stop_env_file_not_ignored() {
  journey_kind local
  journey_story s01-stop 'Un arrêt'
  git -C "$R" config core.excludesFile /dev/null
  # The installer ignores .env*: un-ignore one file, left uncommitted, so po next meets it.
  printf '!.env\n' >> "$R/.gitignore"
  printf 'KEY=one\n' > "$R/.env"
  if journey_run; then return 1; fi
  journey_stopped_on_ask
}
