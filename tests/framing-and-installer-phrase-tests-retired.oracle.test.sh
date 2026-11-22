#!/usr/bin/env bash
# s204 — the oracle of the story: the framing, installer and documentation family keeps only the tests that
# launch a script or pin what a script reads, plus the security phrase tests the owner kept as an exception
# (d-0052). The launch count and the empty-file check are s201's own tests, which run on this tree too; this file
# takes s201's helpers unchanged, as docs/harnais.md says.
source <(sed '/^test_/,$d' "$ROOT/tests/routing-phrase-tests-retired.oracle.test.sh")

# The test files of this family that stay, each with the tests it must still define.
S204_KEPT='
architect.test.sh test_architect_asks_for_the_base test_architect_merges_conventions_instead_of_replacing test_architect_protects_the_settings_blocks
brief.test.sh test_brief_checks_before_writing_approved test_brief_persists_between_sessions
stories-review.test.sh test_stories_review_template_ends_with_stories_ready test_stories_reviewer_is_read_only_without_shell
conversational-framing.test.sh test_stories_review_surfaces_criticals_only
setup-modes.test.sh test_settings_template_declares_framing_settings
framing-commands-cleanup.test.sh test_framing_wording_is_clean test_setup_landing_holds
framing-realign-and-orchestrator-log.test.sh test_every_landing_realigns_the_root
framing-through-pr.test.sh test_framing_commits_on_a_branch
adr-directory.test.sh test_lint_accepts_the_new_setting test_settings_template_declares_the_adr_directory
distribution-wiring.test.sh test_readme_describes_the_pre_commit test_rules_point_at_the_installer
hooks-installer-docs-cleanup.test.sh test_hooks_say_what_they_do_env_word_forks_none test_hooks_say_what_they_do_findings_bullet_warned test_hooks_say_what_they_do_no_squash test_hooks_say_what_they_do_scan_reads_the_base test_hooks_say_what_they_do_story_list_reads_the_base test_installer_and_docs_agree_remove_without_jq
install.test.sh test_install_assembles_agents_md_from_rules_and_settings test_install_copies_commands_agents_skills_templates test_install_copies_skill_subdirectories test_install_creates_no_claude_md_and_spares_one_without_settings test_install_drops_the_legacy_claude_md_import test_install_hooks_flag_sets_hooks_path_in_any_position test_install_ignores_worktrees_and_env_files test_install_keeps_a_hand_written_agents_md test_install_leaves_an_existing_hooks_path_alone test_install_never_touches_settings test_install_removes_files_no_longer_shipped
installer.test.sh test_installation_doc_lists_the_hook_refusals test_installation_matches_the_hook test_installer_check_is_silent_on_a_clean_install test_installer_check_reports_drift test_installer_remove_leaves_the_project_intact test_installer_remove_restores_a_hand_written_agents_md test_installer_stamps_a_version test_installer_state_files_are_not_their_own_ghosts test_installer_supports_install_update_check_and_remove test_installer_update_leaves_no_ghost test_installer_update_preserves_a_modified_file test_installer_update_refreshes_an_untouched_file test_remove_drops_the_legacy_claude_md_import test_remove_leaves_no_empty_file_behind test_update_lists_missing_settings
install-collisions.test.sh test_adr_records_the_contract test_collision_stops_before_writing test_collision_stops_before_writing_global test_hand_written_agents_md_is_absorbed test_hand_written_agents_md_is_absorbed_in_the_rules test_set_aside_is_explicit_and_undone test_set_aside_is_explicit_and_undone_global
installer-leftovers.oracle.test.sh test_failed_remove_names_held_files test_interrupted_run_leaves_a_named_trace test_orphan_before_polype_is_reported test_state_pattern_stays_at_the_top
global-install.test.sh test_installer_global_check_does_not_create_the_user_home test_installer_global_check_reports_payload_drift test_installer_global_install_from_the_payload_keeps_it_whole test_installer_global_puts_commands_in_the_user_home test_installer_global_rejects_a_project_and_global_together test_installer_global_remove_keeps_the_standard_directories test_installer_global_remove_leaves_the_user_home_intact test_installer_global_update_is_idempotent test_installer_init_activates_a_project_after_a_global_install test_installer_init_warns_without_a_global_install test_installer_makes_the_gate_executable_from_a_stale_payload test_installer_refuses_an_incomplete_payload test_installer_runs_through_a_symlink test_installer_usage_names_global_and_init
claude-md-setting.test.sh test_adr_records_the_choice test_kept_keeps_and_imports test_missing_setting_changes_nothing test_setting_has_two_values
no-claude-md.test.sh test_installer_absorbs_claude_md test_precommit_refuses_claude_md test_rules_say_no_claude_md test_session_flags_a_claude_md
local-copy-checksums.test.sh test_committed_copies_refreshed_by_a_pr_stay_intact test_first_update_migrates test_local_copies_have_local_sums test_local_sums_file_stays_out_of_git test_local_sums_win_over_an_old_format_polype_checksums test_update_after_a_pr_refresh_replaces_stale_copies
payload-edit-not-spread.test.sh test_check_lists_payload_edit test_fresh_source_still_updates test_init_does_not_take_payload_edit test_payload_edit_reported_not_spread
payload-kept-outside.test.sh test_adr_records_the_kept_payload test_existing_kept_copy_never_overwritten test_failed_move_is_not_reported_as_done test_kept_copy_removed_once_shipped test_moved_copy_is_not_shipped test_payload_copy_moves_out test_remove_leaves_kept_copies test_symlink_payload_path_not_refused test_update_sweeps_shipped_kept_copy
payload-refuses-foreign-files.test.sh test_adr_records_the_payload_rule test_foreign_payload_file_stops_install test_old_set_aside_never_put_back_in_payload test_payload_signs_itself test_remove_stops_on_foreign_payload_file test_synced_payload_still_installs test_unsigned_payload_says_so
update-keeps-mode.test.sh test_absorbed_settings_helper test_hints_say_init test_init_shrinks_a_full_install test_init_then_update_stays_init test_mode_inferred_without_state test_mode_is_recorded test_session_comment_reads_once test_session_comment_says_why test_session_hint_infers_init_without_mode test_session_hint_trusts_recorded_mode
artifact-link-templates.test.sh test_gates_still_read_artifacts test_links_resolve test_templates_carry_links
lint.test.sh test_lint_checks_every_command_declares_its_settings test_lint_checks_fail_closed_rules_have_a_stop test_lint_checks_tool_permissions_match_the_contract test_lint_fails_when_it_reads_nothing test_lint_is_part_of_the_suite test_lint_reports_how_many_files_it_read
bounds.test.sh test_accepted_gaps_are_written_in_an_adr test_bounds_deny_forbidden_git_verbs test_bounds_deny_writes_outside_owns test_bounds_fail_closed test_bounds_hook_blocks_when_the_script_cannot_run test_bounds_ignore_heredoc_bodies test_bounds_ignore_quoted_arguments test_bounds_read_input_from_a_socket test_bounds_refuse_an_entry_they_cannot_read test_bounds_refuse_moving_a_branch test_bounds_still_catch_real_verbs test_bounds_threat_model_is_written test_chained_git_dirs_are_folded test_config_worktree_override_is_refused test_global_option_values_are_not_verbs test_implementer_declares_a_pretooluse_hook test_installation_doc_names_the_upgrade_path test_installer_ships_the_bounds_hook test_owns_accept_globs test_owns_are_read_where_the_story_started test_qa_allowlist_refuses_writing_forms test_qa_writes_are_bounded_by_the_hook test_quoted_git_after_a_wrapper_option_is_caught test_redirections_are_not_git_paths test_refusal_messages_are_readable test_reviewer_bounds_fail_closed test_reviewer_declares_a_pretooluse_hook test_reviewer_git_is_read_only_outside_restores test_reviewer_knows_how_to_check_merged test_reviewer_rules_are_written_in_adr_0051 test_reviewer_writes_only_in_its_story_or_temp test_temp_zone_verbs_keep_their_paths_in_temp test_unquoted_heredoc_is_expanded_before_reading
bounds-messages.test.sh test_every_refusal_is_readable test_implementer_explores_a_throwaway_clone test_named_fd_redirections_are_read
commands-read-po-state.test.sh test_session_hook_reports_a_failing_po
record-writes-reports.test.sh test_composed_report_is_not_checked test_missing_link_is_dropped
security-findings-stay-private.test.sh test_missing_private_folder_refuses_before_writing test_no_inbox_refuses_before_writing test_only_critical_or_major_holds_the_lane test_private_text_is_owner_only test_reasked_answer_posts_one_decision test_tilde_is_expanded_from_home test_unusable_private_folder_is_refused
decision-inbox.test.sh test_a_dash_is_no_inbox test_an_id_never_reaches_the_filesystem test_parallel_adds_never_share_an_id test_state_waiting_agrees_with_the_list
answer-comes-back.test.sh test_answer_refuses_an_inbox_git_tracks test_consume_refusals_write_nothing test_parallel_answers_record_one test_unknown_fields_survive_a_rewrite
run-ledger.test.sh test_eval_recipes_follow_the_new_record test_fix_run_keeps_the_runs test_implementer_runs_checks_through_po_run test_po_run_appends_a_row test_po_run_passes_the_exit_code_through test_po_run_refuses_outside_a_story_worktree test_suggested_command_is_single_quoted test_verif_current_refuses_a_malformed_checks_row test_verif_current_requires_a_passing_run_per_check
readme-onboarding.test.sh test_existing_config_is_explained test_install_doc_tells_the_truth test_old_bash_is_named test_quickstart_runs_as_written test_setup_hint_names_the_pose
flow.test.sh test_plan_flow_template_carries_verified_facts
'

# The lines a kept function must still hold, `<file>|<text of the line>`: what a script reads inside a function
# that lost its phrases, and every security assertion the owner kept (d-0052).
S204_KEPT_LINES="$(cat <<'LINES'
architect.test.sh|needs_tool "$COMMAND" AskUserQuestion
architect.test.sh|contains "$COMMAND" 'This command never runs a generator or writes source code:'
architect.test.sh|step=$(section_of "$COMMAND" 'Step 4 — Conventions as rules')
architect.test.sh|grep -qF 'keeps every rule already written there and adds the new ones after them' <<< "$step" \
architect.test.sh|grep -qF 'the section is never rewritten from scratch' <<< "$step" \
architect.test.sh|grep -qF 'kept and reported, never deleted in passing' <<< "$step" \
architect.test.sh|grep -qF 'a new rule that contradicts one already written is not added either' <<< "$step" \
architect.test.sh|! grep -qF -- "section's placeholder or body" "$COMMAND" \
architect.test.sh|approval=$(section_of "$COMMAND" 'Approval and commit')
architect.test.sh|grep -qF 'what the new conventions would remove or contradict' <<< "$approval" \
architect.test.sh|grep -qF 'Every settings block of `AGENTS.local.md` stays exactly as it is' <<< "$step" \
architect.test.sh|grep -qF 'this command reads settings, it never decides them' <<< "$step" \
architect.test.sh|grep -qF 'edit no other section of that file' <<< "$step" \
architect.test.sh|grep -qF 'ask the user to edit the settings; do not change them' <<< "$step" \
architect.test.sh|! grep -qF -- "section's placeholder or body" <<< "$step" \
brief.test.sh|frontmatter "$BRIEF_TEMPLATE" | grep -qx 'status: interviewing' || fail "brief template does not start with status: interviewing"
brief.test.sh|section=$(section_of "$BRIEF" 'Finish')
brief.test.sh|checks=$(grep -n -m1 -F -- 'git status --porcelain' <<< "$section" | cut -d: -f1)
brief.test.sh|[ -n "$checks" ] || fail "po-brief.md Finish does not check git status --porcelain"
brief.test.sh|grep -qF -- '`Target branch`' <<< "$section" || fail "po-brief.md Finish does not check the current branch"
brief.test.sh|approved=$(grep -n -m1 -F -- 'set `status: approved`' <<< "$section" | cut -d: -f1)
brief.test.sh|[ -n "$approved" ] || fail "po-brief.md Finish never writes status: approved"
brief.test.sh|[ "$checks" -lt "$approved" ] || fail "po-brief.md writes status: approved before its blocking checks"
brief.test.sh|grep -qF -- 'leaves `docs/brief.md` at `status: interviewing`' <<< "$section" \
stories-review.test.sh|needs_tool "$AGENT" Read
stories-review.test.sh|lacks_tool "$AGENT" Write
stories-review.test.sh|lacks_tool "$AGENT" Edit
stories-review.test.sh|lacks_tool "$AGENT" Bash
stories-review.test.sh|frontmatter "$AGENT" | grep -qx '  - stories-review' || fail "stories-reviewer does not preload stories-review"
stories-review.test.sh|last_two=$(grep -v '^[[:space:]]*$' "$TEMPLATE" | tail -n 2)
stories-review.test.sh|[ "$last_two" = $'Max severity: <critical | major | minor | none>\nStories ready: <yes | no>' ] \
conversational-framing.test.sh|local review="$CMDS/po-stories-review.md"
conversational-framing.test.sh|needs_tool "$review" AskUserQuestion
conversational-framing.test.sh|contains "$review" 'It never edits the stories.'
conversational-framing.test.sh|contains "$review" "never changed: a verdict is the subagent's"
setup-modes.test.sh|local name value row missing=""
setup-modes.test.sh|for name in "Entry mode" "Design source" "Design skill" "Design tool" "Story track" "Flow threshold"; do
setup-modes.test.sh|template_settings | grep -qx "$name" || missing+="$name not in a block; "
setup-modes.test.sh|[ -n "$(table_row "$name")" ] || missing+="$name not in the values table; "
setup-modes.test.sh|for pair in "Entry mode:replace" "Entry mode:adapt" "Entry mode:new" \
setup-modes.test.sh|"Design source:internal" "Design source:external" "Design source:—" \
setup-modes.test.sh|"Story track:full" "Story track:flow" "Story track:auto"; do
setup-modes.test.sh|name="${pair%%:*}" value="${pair#*:}"
setup-modes.test.sh|row=$(table_row "$name")
setup-modes.test.sh|[[ "$row" == *"\`$value\`"* ]] || missing+="$name row lacks \`$value\`; "
setup-modes.test.sh|[ -z "$missing" ] || fail "$missing"
framing-commands-cleanup.test.sh|local setup="$METHOD/commands/po-setup.md"
framing-commands-cleanup.test.sh|local land; land=$(section_of "$setup" 'Landing the framing')
framing-commands-cleanup.test.sh|holds "$land" 'It never commits to `Target branch` directly and never pushes it.' 'landing'
framing-commands-cleanup.test.sh|local loc; loc=$(awk '/^\*\*`Merge mode: local`\*\*/ {on=1} /^\*\*Report\.\*\*/ {on=0} on' <<< "$land")
framing-commands-cleanup.test.sh|holds "$loc" 'A refusal → stop: `framing/<slug>` stays in place and is not deleted' 'local block'
framing-commands-cleanup.test.sh|local setup="$METHOD/commands/po-setup.md" arch="$METHOD/commands/po-architect.md"
framing-commands-cleanup.test.sh|for f in "$setup" "$arch"; do
framing-commands-cleanup.test.sh|contains "$f" 'Never commit a `CLAUDE.md` (ADR-0086)' || fail "$f lacks the ADR reference inside its sentence"
framing-realign-and-orchestrator-log.test.sh|local b; b=$(base_block)
framing-realign-and-orchestrator-log.test.sh|[ -n "$b" ] || fail "po-setup.md has no Base block in its landing section"
framing-realign-and-orchestrator-log.test.sh|holds "$b" 'no stash, checkout or reset forces it' 'Base'
framing-realign-and-orchestrator-log.test.sh|local land; land=$(section_of "$SETUP" 'Landing the framing')
framing-realign-and-orchestrator-log.test.sh|holds "$land" 'is deleted only by the next landing on that same slug' 'the human bullet'
framing-through-pr.test.sh|local land; land=$(landing)
framing-through-pr.test.sh|[ -n "$land" ] || fail "po-setup.md has no '## Landing the framing' section"
framing-through-pr.test.sh|for s in 'GIT_INDEX_FILE' 'git commit-tree <tree> -p <base>' 'refs/heads/framing/<slug>' 'git add -- <paths>'; do
framing-through-pr.test.sh|holds "$land" "$s" 'the landing section'
framing-through-pr.test.sh|for entry in "${FRAMING[@]}"; do
framing-through-pr.test.sh|cmd=${entry%%|*}; slug=${entry##*|}; file="$METHOD/commands/$cmd.md"
framing-through-pr.test.sh|contains "$file" "\`framing/$slug\`"
framing-through-pr.test.sh|[ "$cmd" = po-setup ] || contains "$file" '## Landing the framing'
framing-through-pr.test.sh|! grep -n 'git push' "$file" | grep -vF 'framing/<slug>' | grep -q . \
framing-through-pr.test.sh|! grep -inE 'commit[^.]* on (`Target branch`|the target branch)' "$file" | grep -q . \
framing-through-pr.test.sh|! grep -qF 'Commit from the repository root, on `Target branch`' "$file" \
adr-directory.test.sh|local template="$METHOD/templates/agents-local.md"
adr-directory.test.sh|template_settings | grep -qx 'ADR directory' || fail "the template declares no ADR directory setting"
adr-directory.test.sh|awk '/^```/ {fence=!fence; next} fence' "$template" | grep -qxE 'ADR directory:[[:space:]]+docs/decisions/' \
distribution-wiring.test.sh|contains "$README" 'refuse, sur toutes les branches'
distribution-wiring.test.sh|contains "$README" "fichier d'environnement, clé privée ou jeton connu"
distribution-wiring.test.sh|contains "$README" "un commit de code dont le plan n'est pas validé"
distribution-wiring.test.sh|contains "$METHOD/hooks/po-gate.sh" 'on every branch'
distribution-wiring.test.sh|! grep -qF "Un hook de pre-commit refuse un commit de code" "$README" || fail 'README still states the narrow pre-commit rule'
distribution-wiring.test.sh|contains "$RULES" 'Never edit an installed file'
hooks-installer-docs-cleanup.test.sh|contains "$METHOD/commands/po-setup.md" 'po-gate.sh pre-commit <base>'
hooks-installer-docs-cleanup.test.sh|for f in "$GATE"; do
hooks-installer-docs-cleanup.test.sh|if grep -qi squash "$f"; then fail "${f#"$ROOT"/} still speaks of a squash"; fi
hooks-installer-docs-cleanup.test.sh|if grep -qF '$(git_env_word' "$METHOD/hooks/po-bounds.sh"; then fail "po-bounds.sh still forks a subshell per word"; fi
installer.test.sh|section="$(awk "/^### Le hook des bornes de l'implementer\$/ {on=1; next} /^## / {on=0} on" "$ROOT/docs/installation.md")"
installer.test.sh|[ -n "$section" ] || fail "docs/installation.md has no bounds-hook section"
installer.test.sh|for phrase in 'git update-ref' '-D' '--force' 'cherry-pick' 'pull' 'story/*' 'ADR-0050' \
installer.test.sh|'git fetch . HEAD:main' 'GIT_DIR='; do
installer.test.sh|grep -qF -- "$phrase" <<< "$section" || fail "the bounds-hook section does not say: $phrase"
installer.test.sh|local doc="$ROOT/docs/installation.md" sub p
installer.test.sh|sub="$(awk '/^### Le mode reviewer$/ {on=1; next} /^##/ {on=0} on' "$doc")"
installer.test.sh|[ -n "$sub" ] || fail "no reviewer-mode subsection"
installer.test.sh|for p in '(ADR-0047, précisée par ADR-0051 et ADR-0052)' 'garde-fou contre les erreurs' \
installer.test.sh|'tout verbe sauf `push` et `send-pack`' 'se résolve sous le répertoire temporaire' \
installer.test.sh|'`file://<chemin>`' "Une redirection n'est pas un chemin de git" '`core.worktree`' \
installer.test.sh|'`GIT_CONFIG_PARAMETERS=`'; do
installer.test.sh|grep -qF -- "$p" <<< "$sub" || fail "reviewer subsection lacks: $p"
installer.test.sh|! grep -qF 'un alias git, et, pour' "$doc" || fail "the « et … ni » sentence is still there"
install-collisions.test.sh|contains "$METHOD/AGENTS.md" 'except to append the notes it moves out of a `CLAUDE.md` or a hand-written `AGENTS.md`'
install-collisions.test.sh|contains "$METHOD/AGENTS.md" 'A hand-written root `AGENTS.md` is absorbed the same way, under `## Notes moved from AGENTS.md`'
install-collisions.test.sh|contains "$METHOD/AGENTS.md" 'unless `--set-aside` moves it (ADR-0088)'
install-collisions.test.sh|contains "$METHOD/commands/po-setup.md" 'the notes it moves out of a `CLAUDE.md` or a hand-written `AGENTS.md`.'
install-collisions.test.sh|contains "$ROOT/bin/polype" 'or a hand-written AGENTS.md.'
install-collisions.test.sh|local adrs=("$ROOT"/docs/decisions/ADR-0088-*.md)
install-collisions.test.sh|[ ${#adrs[@]} -eq 1 ] && [ -f "${adrs[0]}" ] || fail "expected exactly one ADR-0088"
install-collisions.test.sh|frontmatter "${adrs[0]}" | grep -qx 'status: accepted' || fail "ADR-0088 is not accepted"
install-collisions.test.sh|contains "${adrs[0]}" '--set-aside'
install-collisions.test.sh|contains "${adrs[0]}" '## Notes moved from AGENTS.md'
install-collisions.test.sh|contains "${adrs[0]}" 'ADR-0086'
install-collisions.test.sh|contains "${adrs[0]}" 'Écartée'
claude-md-setting.test.sh|local tpl="$METHOD/templates/agents-local.md"
claude-md-setting.test.sh|awk '/^```/ {f=!f; next} f' "$tpl" | grep -qx 'Project CLAUDE file: absorbed' \
claude-md-setting.test.sh|grep '^| Project CLAUDE file |' "$tpl" | grep -F '`absorbed`' | grep -qF '`kept`' \
claude-md-setting.test.sh|local sentence="Unless \`Project CLAUDE file\` is \`kept\`, the only \`CLAUDE.md\` is the user's global one"
claude-md-setting.test.sh|for f in "$METHOD/AGENTS.md" "$METHOD/commands/po-setup.md" "$METHOD/commands/po-architect.md"; do
claude-md-setting.test.sh|contains "$f" "$sentence"
claude-md-setting.test.sh|contains "$METHOD/commands/po-setup.md" 'Never commit a `CLAUDE.md` (ADR-0086) unless `Project CLAUDE file` is `kept`'
claude-md-setting.test.sh|contains "$METHOD/commands/po-architect.md" 'Never commit a `CLAUDE.md` (ADR-0086); with `Project CLAUDE file: kept`'
claude-md-setting.test.sh|contains "$METHOD/AGENTS.md" 'with `kept`, both stay, the installer makes the root `CLAUDE.md` start with `@AGENTS.md`'
no-claude-md.test.sh|local sentence="Unless \`Project CLAUDE file\` is \`kept\`, the only \`CLAUDE.md\` is the user's global one: no agent creates a \`CLAUDE.md\` or a \`CLAUDE.local.md\` in a project, and the project's notes go in \`AGENTS.local.md\`."
no-claude-md.test.sh|contains "$METHOD/AGENTS.md" "$sentence"
no-claude-md.test.sh|contains "$METHOD/commands/po-setup.md" "$sentence"
no-claude-md.test.sh|contains "$METHOD/commands/po-architect.md" "$sentence"
no-claude-md.test.sh|contains "$METHOD/AGENTS.md" 'the pre-commit refuses one at any depth'
payload-kept-outside.test.sh|local adrs=("$ROOT"/docs/decisions/ADR-0093-*.md) adr old doc="$ROOT/docs/installation.md"
payload-kept-outside.test.sh|[ "${#adrs[@]}" -eq 1 ] && [ -f "${adrs[0]}" ] || fail "expected exactly one ADR-0093 file"
payload-kept-outside.test.sh|adr="${adrs[0]}"
payload-kept-outside.test.sh|frontmatter "$adr" | grep -qx 'status: accepted' || fail "ADR-0093 is not accepted"
payload-kept-outside.test.sh|frontmatter "$adr" | grep -qx 'supersedes: \[ADR-0092\]' || fail "ADR-0093 does not supersede ADR-0092"
payload-kept-outside.test.sh|contains "$adr" 'polype.kept'
payload-kept-outside.test.sh|contains "$adr" 'perdue pour de bon'
payload-kept-outside.test.sh|# The ADR wraps its prose: the phrase is looked for across line breaks.
payload-kept-outside.test.sh|tr '\n' ' ' < "$adr" | tr -s ' ' | grep -qF "rien n'en signale la fin" \
payload-kept-outside.test.sh|old="$(ls "$ROOT"/docs/decisions/ADR-0092-*.md)"
payload-kept-outside.test.sh|frontmatter "$old" | grep -qx 'superseded-by: \[ADR-0093\]' || fail "ADR-0092 does not link to ADR-0093"
payload-kept-outside.test.sh|frontmatter "$old" | grep -qx 'status: accepted' || fail "ADR-0092 must stay accepted"
payload-kept-outside.test.sh|contains "$doc" 'polype.kept'
payload-kept-outside.test.sh|contains "$doc" 'ADR-0093'
payload-kept-outside.test.sh|contains "$doc" 'moved out of the payload'
payload-kept-outside.test.sh|if grep -qF 'emporte la charge utile' "$doc"; then fail "installation.md still says remove takes the payload edits"; fi
payload-refuses-foreign-files.test.sh|local adrs=("$ROOT"/docs/decisions/ADR-0095-*.md) adr old doc="$ROOT/docs/installation.md"
payload-refuses-foreign-files.test.sh|[ "${#adrs[@]}" -eq 1 ] && [ -f "${adrs[0]}" ] || fail "expected exactly one ADR-0095 file"
payload-refuses-foreign-files.test.sh|adr="${adrs[0]}"
payload-refuses-foreign-files.test.sh|frontmatter "$adr" | grep -qx 'status: accepted' || fail "ADR-0095 is not accepted"
payload-refuses-foreign-files.test.sh|frontmatter "$adr" | grep -qx 'supersedes: \[ADR-0088\]' || fail "ADR-0095 does not supersede ADR-0088"
payload-refuses-foreign-files.test.sh|contains "$adr" '#118'
payload-refuses-foreign-files.test.sh|contains "$adr" '#115'
payload-refuses-foreign-files.test.sh|contains "$adr" 's143'
payload-refuses-foreign-files.test.sh|contains "$adr" 'polype.kept'
payload-refuses-foreign-files.test.sh|contains "$adr" 'payload.sums'
payload-refuses-foreign-files.test.sh|old="$(ls "$ROOT"/docs/decisions/ADR-0088-*.md)"
payload-refuses-foreign-files.test.sh|frontmatter "$old" | grep -qx 'superseded-by: \[ADR-0092, ADR-0095, ADR-0128\]' || fail "ADR-0088 does not link to ADR-0095"
payload-refuses-foreign-files.test.sh|frontmatter "$old" | grep -qx 'status: accepted' || fail "ADR-0088 must stay accepted"
payload-refuses-foreign-files.test.sh|contains "$doc" 'payload.sums'
payload-refuses-foreign-files.test.sh|contains "$doc" 'ADR-0095'
update-keeps-mode.test.sh|if grep -qF 'would lay the commands' "$HOOK"; then fail "po-session still says update would lay the commands"; fi
update-keeps-mode.test.sh|local comments; comments="$(grep -E '^[[:space:]]*#' "$HOOK")"
update-keeps-mode.test.sh|grep -qF 'recorded_mode' <<< "$comments" || fail "no comment of po-session names recorded_mode"
update-keeps-mode.test.sh|grep -qF 'polype init .' <<< "$comments" || fail "no comment of po-session names polype init ."
update-keeps-mode.test.sh|block="$(awk '/local again=/ {for (i = n; i > 0 && lines[i] ~ /^[[:space:]]*#/; i--) out = lines[i] "\n" out; printf "%s", out; exit} {lines[++n] = $0}' "$HOOK")"
update-keeps-mode.test.sh|[ -n "$block" ] || fail "no comment block above local again="
update-keeps-mode.test.sh|[ "$(grep -ow 'advise' <<< "$block" | wc -l)" = 1 ] || fail "the comment does not hold advise exactly once"
update-keeps-mode.test.sh|grep -qF '`polype init .`' <<< "$block" || fail "the comment does not write \`polype init .\` in backticks"
artifact-link-templates.test.sh|for t in $TEMPLATES; do
artifact-link-templates.test.sh|[ "$(link_line "$t")" = "$(expected_link "$t")" ] || fail "$t.md: link line under the title is wrong: $(link_line "$t")"
artifact-link-templates.test.sh|! grep -qF '[[' "$TPL/$t.md" || fail "$t.md holds a wikilink"
artifact-link-templates.test.sh|! grep -qF '.md#' "$TPL/$t.md" || fail "$t.md holds an anchored link"
artifact-link-templates.test.sh|[ "$(head -n 1 "$TPL/plan.md")" = '---' ] || fail "plan.md lost its frontmatter on line 1"
artifact-link-templates.test.sh|[ "$(head -n 1 "$TPL/plan-flow.md")" = '---' ] || fail "plan-flow.md lost its frontmatter on line 1"
bounds.test.sh|fm="$(frontmatter "$IMPLEMENTER")"
bounds.test.sh|grep -q '^  PreToolUse:' <<< "$fm" || fail "no PreToolUse hook in the implementer's frontmatter"
bounds.test.sh|matcher="$(grep -m1 'matcher:' <<< "$fm")"
bounds.test.sh|for tool in Edit Write Bash; do
bounds.test.sh|grep -q "$tool" <<< "$matcher" || fail "the matcher does not cover $tool"
bounds.test.sh|hook_command | grep -qF '.polype/hooks/po-bounds.sh implementer' || fail "the hook does not call po-bounds.sh implementer"
bounds.test.sh|contains "$IMPLEMENTER" 'A po-bounds refusal is a stop'
bounds.test.sh|local doc="$ROOT/docs/installation.md"
bounds.test.sh|contains "$doc" 'relance `polype init <projet>`'
bounds.test.sh|contains "$doc" "le hook fermé refuse toute écriture de l'implementer"
bounds.test.sh|contains "$doc" '`jq`'
bounds.test.sh|local adr="$ROOT/docs/decisions/ADR-0050-po-bounds-lit-un-heredoc-comme-bash-le-lira.md"
bounds.test.sh|local old="$ROOT/docs/decisions/ADR-0039-po-bounds-lit-les-commandes-hors-guillemets-et-heredocs.md"
bounds.test.sh|for p in 'supersedes: [ADR-0039]' '**Lecture des heredocs**' '**Refus du pipe vers un shell**' \
bounds.test.sh|'**Interprètes reconnus**' 'un script écrit puis lancé' '`bash <(…)`' 'un alias git' '`GIT_DIR=…`'; do
bounds.test.sh|contains "$adr" "$p"
bounds.test.sh|contains "$old" 'superseded-by: [ADR-0050]'
bounds.test.sh|contains "$old" 'status: superseded'
bounds.test.sh|contains "$REVIEWER" 'git branch --merged'
bounds.test.sh|contains "$REVIEWER" 'merge-base --is-ancestor'
bounds.test.sh|contains "$REVIEWER" 'file://'
bounds.test.sh|local adr="$ROOT/docs/decisions/ADR-0051-le-reviewer-juge-la-commande-git-que-git-executera.md"
bounds.test.sh|local old="$ROOT/docs/decisions/ADR-0047-le-reviewer-tenu-par-po-bounds-en-mode-reviewer.md"
bounds.test.sh|for p in 'supersedes: [ADR-0047]' '**Répertoire**' 'core.worktree' "la portée d'un \`cd\`"; do
bounds.test.sh|fm="$(frontmatter "$old")"
bounds.test.sh|grep -qx 'superseded-by: \[ADR-0051, ADR-0052\]' <<< "$fm" || fail "ADR-0047 does not say superseded-by: [ADR-0051, ADR-0052]"
bounds.test.sh|grep -qx 'status: accepted' <<< "$fm" || fail "ADR-0047 is no longer accepted"
bounds.test.sh|adr="$(ls "$ROOT"/docs/decisions/ADR-0052-*.md)"
bounds.test.sh|fm="$(frontmatter "$adr")"
bounds.test.sh|grep -qx 'supersedes: \[ADR-0047, ADR-0051\]' <<< "$fm" || fail "ADR-0052 does not supersede ADR-0047 and ADR-0051"
bounds.test.sh|grep -qx 'status: accepted' <<< "$fm" || fail "ADR-0052 is not accepted"
bounds.test.sh|for p in 'garde-fou contre les erreurs' '-zf<chemin>' "la portée d'un \`cd\`" 'un alias git' \
bounds.test.sh|"les hooks d'un dépôt jetable" '`GIT_CONFIG_GLOBAL`' 'une clé construite par substitution' 'bac à sable'; do
bounds.test.sh|for f in 0047 0051; do
bounds.test.sh|frontmatter "$(ls "$ROOT"/docs/decisions/ADR-$f-*.md)" | grep -E '^superseded-by:' | grep -qF 'ADR-0052' \
bounds.test.sh|frontmatter "$(ls "$ROOT"/docs/decisions/ADR-0034-*.md)" | grep -E '^superseded-by:' | grep -qF 'ADR-0041' \
bounds.test.sh|frontmatter "$(ls "$ROOT"/docs/decisions/ADR-0041-*.md)" | grep -E '^supersedes:' | grep -qF 'ADR-0034' \
bounds.test.sh|for f in 0047 0051 0034; do
bounds.test.sh|frontmatter "$(ls "$ROOT"/docs/decisions/ADR-$f-*.md)" | grep -qx 'status: accepted' || fail "ADR-$f is no longer accepted"
run-ledger.test.sh|local agent="$METHOD/agents/implementer.md"
run-ledger.test.sh|contains "$agent" 'po-run.sh --story'
run-ledger.test.sh|contains "$METHOD/skills/testing-doctrine/SKILL.md" 'po-run --story'
run-ledger.test.sh|! grep -qF 'list each command you ran with its exit code' "$agent" \
run-ledger.test.sh|contains "$METHOD/agents/implementer.md" 'Fix run: the record already exists; keep it with every row under `## Runs` and never start it again from the template'
readme-onboarding.test.sh|sec="$(readme_section 'Ce que Polype fait de ta configuration')"
readme-onboarding.test.sh|[ -n "$sec" ] || fail "README has no ## Ce que Polype fait de ta configuration section"
readme-onboarding.test.sh|for phrase in '--set-aside' '.before-polype' 'AGENTS.md' 'Notes moved from AGENTS.md' 'CLAUDE.md' \
readme-onboarding.test.sh|'Project CLAUDE file' 'absorbed' 'kept' 'polype install'; do
readme-onboarding.test.sh|grep -qF -- "$phrase" <<< "$sec" || fail "the configuration section does not say: $phrase"
readme-onboarding.test.sh|n="$(grep -oE 'environ [0-9]+ Ko' <<< "$sec" | grep -oE '[0-9]+')"
readme-onboarding.test.sh|[ -n "$n" ] || fail "the configuration section gives no size as 'environ N Ko'"
readme-onboarding.test.sh|kib=$(( $(wc -c < "$METHOD/AGENTS.md") / 1024 ))
readme-onboarding.test.sh|[ $((n * 4)) -ge $((kib * 3)) ] && [ $((n * 4)) -le $((kib * 5)) ] \
readme-onboarding.test.sh|local doc="$ROOT/docs/installation.md" joined phrase para
readme-onboarding.test.sh|for phrase in '--set-aside' '.before-polype' 'Notes moved from AGENTS.md' 'Project CLAUDE file' \
readme-onboarding.test.sh|'kept' 'ADR-0088' 'ADR-0089'; do
readme-onboarding.test.sh|contains "$doc" "$phrase"
readme-onboarding.test.sh|joined="$(tr '\n' ' ' < "$doc")"
readme-onboarding.test.sh|if grep -qF "ni aux fichiers qu'on a ajoutés" <<< "$joined"; then fail "the doc still says added files are never touched"; fi
readme-onboarding.test.sh|if grep -qF "écrit à la main est d'abord sauvegardé" <<< "$joined"; then fail "the doc still backs AGENTS.md up"; fi
readme-onboarding.test.sh|para="$(awk -v RS= '/ceux qu.il trouve \(ADR-0086\)/' "$doc")"
readme-onboarding.test.sh|[ -n "$para" ] || fail "no paragraph holds ceux qu'il trouve (ADR-0086)"
readme-onboarding.test.sh|grep -qF 'Project CLAUDE file' <<< "$para" || fail "the ADR-0086 paragraph does not name Project CLAUDE file"
flow.test.sh|frontmatter "$TEMPLATE" | grep -qx 'track: flow' || fail "plan-flow frontmatter lacks track: flow"
flow.test.sh|frontmatter "$TEMPLATE" | grep -qx 'validated: no' || fail "plan-flow frontmatter lacks validated: no"
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
  done <<< "$S204_KEPT"
  while IFS='|' read -r file text; do
    [ -n "$file" ] || continue
    grep -qF -- "$text" "$ROOT/tests/$file" 2>/dev/null || missing+="$file: $text; "
  done <<< "$S204_KEPT_LINES"
  [ -z "$missing" ] || fail "contract tests gone: $missing"
}
