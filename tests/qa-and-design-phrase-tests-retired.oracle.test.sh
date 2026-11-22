#!/usr/bin/env bash
# s203 — the oracle of the story: the QA, design, driver and profile family keeps only the tests that launch a
# script or pin what a script reads, plus the security phrase tests the owner kept as an exception (d-0052). The
# launch count and the empty-file check are s201's own tests, which run on this tree too; this file takes s201's
# helpers unchanged, as docs/harnais.md says.
source <(sed '/^test_/,$d' "$ROOT/tests/routing-phrase-tests-retired.oracle.test.sh")

# The test files of this family that stay, each with the tests it must still define.
S203_KEPT='
qa.test.sh test_qa_report_has_steps_evidence_and_status test_browser_contract_is_written_once test_qa_stops_without_a_browser_or_a_dev_command test_setup_asks_for_dev_and_qa_stage
qa-gate.test.sh test_po_gate_qa_current test_qa_current_reads_the_last_status test_qa_current_needs_a_full_tree_hash test_qa_current_requires_a_committed_report test_qa_current_ignores_ignored_files test_po_qa_commits_its_evidence
qa-drivers.test.sh test_qa_runs_without_a_screen test_profiles_declare_their_driver
qa-fleet.test.sh test_drive_resumes_on_an_uncommitted_report
qa-contract-holds.test.sh test_qa_declares_what_it_reads test_scenario_rules_bite
qa-reads-ignore-rules.test.sh test_qa_allows_check_ignore test_qa_allows_check_attr test_qa_still_refuses_writing_verbs
qa-report-returned-as-text.test.sh test_qa_returns_its_report test_qa_report_path_stays
design-system.test.sh test_design_system_never_invents_an_identity test_design_system_measures_contrast_once test_design_doctrine_covers_new_vs_derived_and_gaps
design-handoff.test.sh test_execute_mentions_the_design_when_present
designer-browser.test.sh test_designer_inherits_the_session_browser test_po_design_can_reach_a_browser test_design_still_writes_no_source_file
fleet-design.test.sh test_designer_agent_carries_the_design_contract test_designer_writes_only_in_the_story_design_folder test_designer_asks_no_one
scenario-driver.test.sh test_scenarios_run_each_visible_criterion test_scenarios_start_the_service_itself test_scenarios_leave_the_tree_clean
scene-and-simulation-drivers.test.sh test_scene_capture_is_sized_and_scripted test_simulation_leaves_nothing_running
godot-scene-driver.test.sh test_godot_profile_passes_the_lint test_godot_profile_is_grounded_in_its_source
ros-simulation-driver.test.sh test_ros_profile_passes_the_lint test_ros_profile_is_grounded_in_its_source
platform-setting.test.sh test_platform_is_a_setting test_profiles_declare_their_platform test_stories_declare_a_surface test_polype_declares_its_platform
profile.test.sh test_profile_template_declares_every_section test_profile_commands_map_to_settings test_lint_checks_profiles
profiles-hold.test.sh test_skipped_grounding_is_visible test_lint_holds_its_profile_rules
cli-api-profiles.test.sh test_cli_api_profiles_pass_the_lint test_cli_api_profiles_are_grounded_in_their_sources
expo-profile.test.sh test_expo_profile_passes_the_lint test_expo_profile_is_grounded_in_its_source
flutter-profile.test.sh test_flutter_profile_passes_the_lint test_flutter_profile_is_grounded_in_its_source
native-profiles.test.sh test_native_profiles_pass_the_lint test_native_profiles_are_grounded_in_their_sources
next-forge-profile.test.sh test_next_forge_profile_passes_the_lint test_next_forge_profile_is_grounded_in_the_real_repository
throwaway-zone-holds.test.sh test_throwaway_refuses_another_work_tree test_story_worktree_is_judged_first
'

# The lines a kept function must still hold, `<file>|<text of the line>`: what a script reads inside a function
# that lost its phrases, and every security assertion the owner kept (d-0052).
S203_KEPT_LINES="$(cat <<'LINES'
qa.test.sh|grep -qF 'QA status: <complete | blocked>'
qa.test.sh|'**No credentials through you**'
qa.test.sh|needs_tool "$PO_QA" Agent
qa.test.sh|template_settings | grep -qx 'QA stage'
qa-gate.test.sh|grep -qF 'run a shell'
qa-gate.test.sh|contains "$PO_QA" 'commit -m "<id>: QA evidence" -- docs/qa/<id>/'
qa-drivers.test.sh|contains "$QA_AGENT" 'status --porcelain` again'
qa-drivers.test.sh|contains "$QA_AGENT" 'mktemp -d'
qa-drivers.test.sh|contains "$DRIVERS" 'mktemp -d'
qa-fleet.test.sh|'is current but docs/qa/$1/ is not committed'
qa-contract-holds.test.sh|'status --porcelain` as it stands before the walk'
qa-contract-holds.test.sh|'→ `QA status: blocked`, naming that path'
qa-contract-holds.test.sh|'Each scenario then works from a scratch folder under the same directory'
qa-report-returned-as-text.test.sh|holds "$(awk '/^qa_current\(\)/
qa-report-returned-as-text.test.sh|holds "$report" 'Never write the report yourself' 'qa.md, the report'
design-system.test.sh|needs_tool "$COMMAND" AskUserQuestion
design-system.test.sh|"The command edits no source file:"
design-system.test.sh|'handed to the person'
design-system.test.sh|'a quick fix they name or through a story'
design-system.test.sh|'the code still carries the old values'
design-system.test.sh|needs_tool "$COMMAND" Bash
design-system.test.sh|grep -qxF 'name: design-doctrine'
design-handoff.test.sh|for tool in Bash Write Edit; do lacks_tool "$EXECUTE" "$tool"; done
designer-browser.test.sh|! grep -qE '^(allowed-tools|tools):'
designer-browser.test.sh|contains "$PO_DESIGN" 'It writes no source file.'
designer-browser.test.sh|'never code: nothing in it is copied into source files'
designer-browser.test.sh|contains "$DESIGNER" 'No source file, no test file, no commit'
fleet-design.test.sh|grep -qx 'name: designer'
fleet-design.test.sh|'You write under `docs/designs/<id>/` and nowhere else'
fleet-design.test.sh|'No source file, no test file, no commit'
fleet-design.test.sh|'the files stay uncommitted'
fleet-design.test.sh|'never code'
fleet-design.test.sh|'Never run `git worktree add`, `switch`, `checkout` or `stash`'
fleet-design.test.sh|grep -qw AskUserQuestion
scenario-driver.test.sh|'No secret enters a transcript'
scenario-driver.test.sh|'`<redacted>`'
scenario-driver.test.sh|contains "$DRIVER" '127.0.0.1'
scenario-driver.test.sh|'and only that one'
scenario-driver.test.sh|'you did not start is never started, stopped, restarted or written to'
scenario-driver.test.sh|'runs on a copy, never in the worktree'
scenario-driver.test.sh|contains "$DRIVER" 'mktemp -d'
scenario-driver.test.sh|'ls-files --others --ignored --exclude-standard'
scenario-driver.test.sh|'status --porcelain --ignored'
scene-and-simulation-drivers.test.sh|contains "$SCENE" "$SET_ASIDE"
scene-and-simulation-drivers.test.sh|contains "$SIMULATION" "$SET_ASIDE"
platform-setting.test.sh|"web mobile cli api lib xr robot "
platform-setting.test.sh|contains "$STORIES_T" "**Surface**"
godot-scene-driver.test.sh|'- QA driver: scene'
ros-simulation-driver.test.sh|'- QA driver: simulation'
profile.test.sh|"| Capability | Brick | Notes |"
LINES
)"

test_contract_tests_stay() {
  local file names name out text missing=""
  while read -r file names; do
    [ -n "$file" ] || continue
    [ -f "$ROOT/tests/$file" ] || { missing+="$file (file gone); "; continue; }
    out="$(tests_defined "$ROOT/tests" "$file")"
    for name in $names; do
      grep -qxF "$name" <<< "$out" || missing+="$file:$name; "
    done
  done <<< "$S203_KEPT"
  while IFS='|' read -r file text; do
    [ -n "$file" ] || continue
    grep -qF -- "$text" "$ROOT/tests/$file" 2>/dev/null || missing+="$file: $text; "
  done <<< "$S203_KEPT_LINES"
  [ -z "$missing" ] || fail "contract tests gone: $missing"
}
