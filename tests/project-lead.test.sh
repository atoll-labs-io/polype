#!/usr/bin/env bash
# s103 — the main session is the project lead; po-session gives it the state, the installer wires it.

RULES="$METHOD/AGENTS.md"
HELP="$METHOD/commands/po-help.md"
INSTALL_DOC="$ROOT/docs/installation.md"
HOOK="$METHOD/hooks/po-session.sh"
POLYPE="$ROOT/bin/polype"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }
holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }
has_line() { grep -qxF -- "$2" <<< "$1" || fail "po-session did not print the line: $2"$'\n'"$1"; }
lacks_text() { if grep -qF -- "$2" <<< "$1"; then fail "po-session printed: $2"$'\n'"$1"; fi; }

session_in() { (cd "$1" && CLAUDE_PROJECT_DIR="$1" bash "$HOOK"); }

# A Polype project in $R, committed on main: AGENTS.local.md with the given extra settings.
polype_repo() {
  scratch_repo
  R="$(cd "$SCRATCH" && pwd -P)"
  {
    printf 'Target branch: main\nWorktree root: .worktrees/\nEntry mode: new\n'
    printf '%s\n' "$@"
  } > "$R/AGENTS.local.md"
  printf '.worktrees/\n' > "$R/.gitignore"
}

commit_all() { git -C "$R" add -A && git -C "$R" commit -qm "${1:-framing}"; }

set_setting() { sed -i "s/^$1:.*/$1: $2/" "$R/AGENTS.local.md"; }

approved_brief() { mkdir -p "$R/docs"; printf -- '---\nstatus: approved\n---\n# Brief\n' > "$R/docs/brief.md"; }

lane() { git -C "$R" worktree add -q -b "story/$1" "$R/.worktrees/$1" main; }

lane_file() { mkdir -p "$(dirname "$R/.worktrees/$1/$2")"; printf '%s\n' "${@:3}" > "$R/.worktrees/$1/$2"; }

test_session_hook_silent_outside_polype() {
  polype_repo 'Max attempts: 2'
  local out
  PLAIN="$(mktemp -d)"
  trap 'rm -rf "$SCRATCH" "$PLAIN"' EXIT

  out="$(cd "$PLAIN" && GIT_CEILING_DIRECTORIES="$PLAIN" CLAUDE_PROJECT_DIR="$PLAIN" bash "$HOOK")" || fail "non-zero exit outside git"
  [ -z "$out" ] || fail "printed outside a git repository: $out"

  mkdir -p "$PLAIN/repo" && git -C "$PLAIN/repo" init -q -b main
  out="$(session_in "$PLAIN/repo")" || fail "non-zero exit in a repository without Polype"
  [ -z "$out" ] || fail "printed in a repository without Polype: $out"

  commit_all
  git -C "$R" worktree add -q -b story/s01-a "$R/.worktrees/s01-a" main
  out="$(session_in "$R/.worktrees/s01-a")" || fail "non-zero exit in a story worktree"
  [ -z "$out" ] || fail "printed in a story worktree: $out"

  out="$(session_in "$R")"
  [ -n "$out" ] || fail "silent in the main checkout of a Polype project"
}

test_session_hook_reports_state_read_only() {
  polype_repo 'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: automatic (chosen)'
  approved_brief
  cat > "$R/docs/stories.md" <<'EOF'
# Stories
## s01-a — A
- **Depends on**: none
## s02-b — B
- **Depends on**: s01-a
## s03-c — C
- **Dépend de** : s04-d
## s04-d — D
- **Depends on**: none
EOF
  commit_all
  git -C "$R" commit -q --allow-empty -m "s01-a: A"
  lane s04-d

  local before after out
  before="$(find "$R" -type f -exec cksum {} + | sort; find "$R" -printf '%p %T@\n' | sort)"
  out="$(session_in "$R")" || fail "non-zero exit"
  after="$(find "$R" -type f -exec cksum {} + | sort; find "$R" -printf '%p %T@\n' | sort)"

  has_line "$out" 'Polype project lead — state read from disk and git by po-session; nothing was run or changed.'
  has_line "$out" 'Framing: scope approved · stories present · stories review none · architecture missing · design system missing'
  has_line "$out" 'Framing next: /po-stories-review'
  has_line "$out" 'Ready stories: s02-b (Owns not checked: /po-drive decides)'
  has_line "$out" 'Lanes in flight: s04-d (.worktrees/s04-d)'
  has_line "$out" 'Waiting for a human: nothing'
  [ "$before" = "$after" ] || fail "po-session changed the repository: $(diff <(echo "$before") <(echo "$after"))"
}

test_session_hook_reports_framing_stage() {
  polype_repo 'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: automatic (chosen)'
  mkdir -p "$R/docs"
  printf -- '---\nstatus: interviewing\n---\n# Brief\n' > "$R/docs/brief.md"
  commit_all
  local out
  out="$(session_in "$R")"
  has_line "$out" 'Framing: scope in progress · stories missing · stories review none · architecture missing · design system missing'
  has_line "$out" 'Framing next: /po-brief'

  git -C "$R" rm -q AGENTS.local.md && git -C "$R" commit -qm "no setup"
  mkdir -p "$R/.polype" && echo 0.2.0 > "$R/.polype/version"
  out="$(session_in "$R")"
  [ "$out" = "Polype project lead — state read from disk and git by po-session; nothing was run or changed."$'\n'"Framing: setup missing → /po-setup" ] \
    || fail "without AGENTS.local.md, expected the setup line alone: $out"
}

test_session_hook_lists_human_escalations() {
  polype_repo 'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: human (forge)'
  approved_brief
  commit_all
  lane s11-root
  lane_file s11-root docs/research/s11-root.md '# Research' 'Root cause: not found'
  lane_file s11-root docs/plans/s11-root.md '---' 'validated: no' '---'
  lane s12-qa
  lane_file s12-qa docs/qa/s12-qa/report.md 'QA status: complete' 'QA status: blocked'
  lane s13-max
  lane_file s13-max docs/reviews/s13-max.md 'Review status: complete' 'Fix loop: 2' 'Ship allowed: no'
  lane s14-pr
  lane_file s14-pr docs/reviews/s14-pr.md 'Review status: complete' 'Fix loop: 0' 'Ship allowed: yes'
  git -C "$R" update-ref refs/remotes/origin/story/s14-pr main
  git -C "$R" branch -q other main
  git -C "$R" worktree add -q "$R/.worktrees/s15-orphan" other

  local out
  out="$(session_in "$R")"
  has_line "$out" 'Waiting for a human:'
  has_line "$out" '- s11-root: root cause not found (docs/research/s11-root.md)'
  has_line "$out" '- s12-qa: QA blocked (docs/qa/s12-qa/report.md)'
  has_line "$out" '- s13-max: Max attempts reached (Fix loop: 2, Max attempts: 2)'
  has_line "$out" '- s14-pr: pull request presumed waiting for a human merge (story/s14-pr pushed; the forge was not asked)'
  has_line "$out" '- .worktrees/s15-orphan: orphan worktree (other)'
}

test_session_hook_keeps_ordinary_lanes_out() {
  polype_repo 'Max attempts: 2' 'Merge mode: pr' 'Ship confirmation: automatic (chosen)'
  approved_brief
  commit_all
  lane s21-loop
  lane_file s21-loop docs/reviews/s21-loop.md 'Review status: complete' 'Fix loop: 1' 'Ship allowed: no'
  lane s22-ok
  lane_file s22-ok docs/reviews/s22-ok.md 'Review status: complete' 'Fix loop: 0' 'Ship allowed: yes'
  lane s23-qa
  lane_file s23-qa docs/reviews/s23-qa.md 'Review status: blocked' 'Fix loop: 2' '- Next action: /po-qa s23-qa' 'Ship allowed: no'
  lane s24-plan
  lane_file s24-plan docs/research/s24-plan.md 'Root cause: not found'
  lane_file s24-plan docs/plans/s24-plan.md '---' 'validated: yes' '---'
  lane s25-qa
  lane_file s25-qa docs/qa/s25-qa/report.md 'QA status: blocked' 'QA status: complete'
  git -C "$R" update-ref refs/remotes/origin/story/s22-ok main

  local out
  out="$(session_in "$R")"
  has_line "$out" 'Waiting for a human: nothing'

  set_setting 'Ship confirmation' 'human (forge)'
  git -C "$R" update-ref -d refs/remotes/origin/story/s22-ok
  out="$(session_in "$R")"
  has_line "$out" 'Waiting for a human: nothing'

  git -C "$R" update-ref refs/remotes/origin/story/s22-ok main
  set_setting 'Merge mode' 'local'
  out="$(session_in "$R")"
  has_line "$out" 'Waiting for a human: nothing'

  set_setting 'Merge mode' 'pr'
  git -C "$R" commit -q --allow-empty -m "s22-ok: shipped"
  out="$(session_in "$R")"
  has_line "$out" 'Waiting for a human: nothing'
  lacks_text "$out" 's22-ok: pull request'
}

# --- Installer ------------------------------------------------------------------------------

# A throwaway project and a throwaway user home, so no run can reach the real ~/.claude.
installer_home() {
  scratch_repo
  export HOME="$SCRATCH/home" CLAUDE_CONFIG_DIR="$SCRATCH/home/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
}

new_project() { mkdir -p "$SCRATCH/$1" && git -C "$SCRATCH/$1" init -q -b main; printf '%s' "$SCRATCH/$1"; }

run_polype() {
  case "${CLAUDE_CONFIG_DIR-}" in "$SCRATCH"/*) ;; *) fail "refusing to run: CLAUDE_CONFIG_DIR is outside $SCRATCH" ;; esac
  bash "$POLYPE" "$@" >/dev/null 2>&1 || fail "polype failed: $*"
}

need_jq() { command -v jq >/dev/null 2>&1 || fail "jq is required by this test and is not installed"; }

hook_count() {
  jq '[.hooks.SessionStart[]?.hooks[]? | select(.command | contains(".polype/hooks/po-session.sh"))] | length' "$1"
}

settings_of_their_own() {
  mkdir -p "$1/.claude"
  printf '%s\n' '{"permissions":{"allow":["Bash(ls)"]},"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo mine"}]}]}}' \
    > "$1/.claude/settings.json"
}

keeps_their_own() {
  jq -e '.permissions == {"allow":["Bash(ls)"]}' "$1" >/dev/null || fail "permissions changed: $(cat "$1")"
  jq -e '[.hooks.SessionStart[].hooks[].command] | index("echo mine") != null' "$1" >/dev/null \
    || fail "the project's own SessionStart hook was dropped: $(cat "$1")"
}

test_installer_wires_the_session_hook() {
  need_jq
  installer_home
  local p s p2
  p="$(new_project p)"; s="$p/.claude/settings.json"
  settings_of_their_own "$p"
  run_polype install "$p"
  keeps_their_own "$s"
  [ "$(hook_count "$s")" = 1 ] || fail "expected one po-session hook after install: $(cat "$s")"
  jq -e '[.hooks.SessionStart[].hooks[].command] | index("\"$CLAUDE_PROJECT_DIR\"/.polype/hooks/po-session.sh") != null' "$s" >/dev/null \
    || fail "the hook command is not the project-relative script: $(cat "$s")"
  run_polype update "$p"
  run_polype update "$p"
  keeps_their_own "$s"
  [ "$(hook_count "$s")" = 1 ] || fail "update duplicated the hook: $(cat "$s")"

  run_polype install --global
  p2="$(new_project p2)"
  run_polype init "$p2"
  [ "$(hook_count "$p2/.claude/settings.json")" = 1 ] || fail "init did not create the hook"
  if grep -q '^\.claude/' "$p2/.polype/manifest"; then fail "the manifest lists a .claude/ file after init"; fi
}

test_installer_unwires_the_session_hook() {
  need_jq
  installer_home
  local p q s
  p="$(new_project p)"; s="$p/.claude/settings.json"
  settings_of_their_own "$p"
  run_polype install "$p"
  run_polype remove "$p"
  keeps_their_own "$s"
  [ "$(hook_count "$s")" = 0 ] || fail "remove left the po-session hook: $(cat "$s")"

  q="$(new_project q)"
  run_polype install "$q"
  [ -f "$q/.claude/settings.json" ] || fail "install did not create .claude/settings.json"
  run_polype remove "$q"
  [ ! -e "$q/.claude/settings.json" ] || fail "remove left a settings.json holding nothing: $(cat "$q/.claude/settings.json")"
  [ ! -e "$q/.claude" ] || fail "remove left .claude/ behind"
  [ -z "$(find "$SCRATCH" -name '*.polype-next')" ] || fail "a temporary file was left behind"
}

test_installer_without_jq_skips_only_the_hook() {
  installer_home
  local bin cmd p q err
  bin="$SCRATCH/bin"; mkdir -p "$bin"
  for cmd in bash env cat cp mv rm mkdir chmod find sed sort head tail grep awk git wc cksum dirname basename readlink touch tr; do
    ln -s "$(command -v "$cmd")" "$bin/$cmd"
  done
  if PATH="$bin" command -v jq >/dev/null 2>&1; then fail "jq is still reachable from the test PATH"; fi
  run_polype install --global

  for mode in init install; do
    p="$(new_project "$mode")"
    err="$(PATH="$bin" "$bin/bash" "$POLYPE" "$mode" "$p" 2>&1 >/dev/null)" || fail "$mode failed without jq: $err"
    [ -d "$p/.polype/templates" ] || fail "$mode without jq laid no templates"
    [ -f "$p/AGENTS.md" ] || fail "$mode without jq assembled no AGENTS.md"
    grep -qF 'jq not found' <<< "$err" || fail "$mode without jq did not say so: $err"
    [ ! -e "$p/.claude/settings.json" ] || fail "$mode without jq wrote .claude/settings.json"
  done
}

# --- Texts ----------------------------------------------------------------------------------

test_rules_name_the_project_lead() {
  local s
  s="$(section_of "$RULES" "The project lead")"
  [ -n "$s" ] || fail "no ## The project lead section in method/AGENTS.md"
  holds "$s" 'The main session of a project is its project lead' "The project lead"
  holds "$s" 'it leads framing in conversation' "The project lead"
  holds "$s" 'runs `/po-drive` wave after wave until the milestone is done' "The project lead"
  holds "$s" "It never writes a story's code" "The project lead"
  holds "$s" 'A subagent is never the project lead' "The project lead"
  holds "$s" 'reads the state `po-session` prints' "The project lead"
}

test_lead_answers_before_driving() {
  local s
  s="$(section_of "$RULES" "The project lead")"
  holds "$s" 'answers the question it was asked first, and relaunches the fleet only when the project is waiting for it' "The project lead"
}

test_help_says_no_command_needed() {
  contains "$HELP" 'Ouvrir une session sur le projet suffit : le chef de projet reprend où il en est, sans commande à taper.'
  contains "$INSTALL_DOC" 'Ouvrir une session suffit : le chef de projet reprend le projet'
}
