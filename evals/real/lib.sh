#!/usr/bin/env bash
# po-eval real — a real project lead, launched through `po run`, on a throwaway repository built for
# it; every run graded by scripts (grade.sh), control arms declared by files (evals/arms/). Sourced by
# bin/po-eval, whose arm_* functions it uses. Each run costs paid `claude -p` sessions: it is for a
# person who launches and watches it (ADR-0134), so the confirmation is asked on a terminal and no
# option skips it. ADR-0133 says how many runs ground a retirement; this command retires nothing.
#
# Usage: po-eval real [--repeat N] [--sessions S] [--model M] [--budget USD] [--arm <name|file.arm>]…
#                     [--keep] [--record] [case…]          default case journey, N 1, S 3, budget 10
#        po-eval real --list | --rules | --build <case> <dir> | --build-all <dir>
#
# The login comes from ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN, read from the environment
# only: its name is printed, never its value. Every run lives in its own `mktemp -d` folder — HOME,
# TMPDIR and the Claude Code config included — removed when the run ends; the results folder (mode
# 700) is removed at exit unless --keep, which first scrubs every kept file as po-intake does.

REAL="$POLYPE_ROOT/evals/real"
# shellcheck source=grade.sh
source "$REAL/grade.sh"

real_usage() {
  cat >&2 <<'USAGE'
usage: po-eval real [--repeat N] [--sessions S] [--model M] [--budget USD] [--arm <name|file.arm>]… [--keep] [--record] [case…]
       po-eval real --list | --rules | --build <case> <dir> | --build-all <dir>
USAGE
  exit 2
}

real_cases() { local f; for f in "$REAL/cases"/*.sh; do [ -f "$f" ] && { f="${f##*/}"; echo "${f%.sh}"; }; done | sort; }

real_load_case() {
  local name="$1" file="$REAL/cases/$1.sh" var
  [[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]] && [ -f "$file" ] || { echo "po-eval: unknown case: $name" >&2; return 2; }
  for var in $(compgen -v CASE_ || true); do unset "$var"; done
  unset -f setup 2>/dev/null || true
  # shellcheck source=/dev/null
  source "$file"
  case "${CASE_BASE:-}" in journey|framing|lane) ;; *) echo "po-eval: $name: CASE_BASE must be journey, framing or lane" >&2; return 2 ;; esac
  [ -n "${CASE_LAUNCH:-}" ] || { echo "po-eval: $name declares no CASE_LAUNCH" >&2; return 2; }
  declare -F setup > /dev/null || { echo "po-eval: $name defines no setup function" >&2; return 2; }
  [ -n "${CASE_EXPECT+set}" ] && [ "${#CASE_EXPECT[@]}" -gt 0 ] || { echo "po-eval: $name declares no CASE_EXPECT" >&2; return 2; }
}

# po, built once from this checkout and copied into each run's config.
real_build_po() {
  local target="${CARGO_TARGET_DIR:-$POLYPE_ROOT/po/target}" out
  command -v cargo > /dev/null || { echo "po-eval: cargo not found: po cannot be built for the run" >&2; exit 2; }
  out="$(cargo build --release --locked --quiet --manifest-path "$POLYPE_ROOT/po/Cargo.toml" --target-dir "$target" 2>&1)" \
    || { echo "po-eval: po does not build:" >&2; printf '%s\n' "$out" >&2; exit 2; }
  REAL_PO_BIN="$target/release/po"
}

# The isolation of tests/journey/journey.sh:23-38, in the run folder <J>.
real_env() {
  local tool vars
  J="$1" R="$1/project"
  mkdir -p "$J/bin" "$J/home" "$J/tmp" "$J/calls" "$J/prs" "$J/gh" "$J/services" "$J/build" "$J/logs"
  ln -sf "$REAL/doubles/gh" "$J/bin/gh"
  for tool in curl glab tea task claude; do ln -sf "$REAL/doubles/unexpected" "$J/bin/$tool"; done
  vars="$(git rev-parse --local-env-vars)"
  # shellcheck disable=SC2086
  unset GH_TOKEN GITHUB_TOKEN $vars
  : > "$J/home/.gitconfig"
  # The files Claude Code's sandbox mounts over a repository root (ADR-0137), out of every git status.
  mkdir -p "$J/home/.config/git"
  printf '%s\n' /.gitconfig /.gitmodules /.bashrc /.bash_profile /.zshrc /.zshenv /.zprofile /.profile \
    /.ripgreprc /.mcp.json /.vscode/ /.idea/ > "$J/home/.config/git/ignore"
  export PATH="$J/bin:${REAL_RUN_PATH:-$PATH}" HOME="$J/home" TMPDIR="$J/tmp" CLAUDE_CONFIG_DIR="$J/config" JOURNEY_DIR="$J"
  export XDG_CONFIG_HOME="$J/home/.config" GIT_CONFIG_GLOBAL="$J/home/.gitconfig" GIT_CONFIG_NOSYSTEM=1
  export PO_GH="$J/bin/gh" PO_CURL="$J/bin/curl" PO_GLAB="$J/bin/glab" PO_TEA="$J/bin/tea"
  # PO_CLAUDE is the run's launcher; with none (a build), claude-print answers `agents` and nothing else.
  export CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 PO_SHIP_POLL_SECONDS=0 GIT_ALLOW_PROTOCOL=file PO_CLAUDE="${REAL_LAUNCHER:-$REAL/claude-print}" PO="$J/config/polype/po"
}

# The run's PATH, the caller's without each folder that holds a claude, unless dropping it changes
# where a tool the run needs is found: a session then finds no paid claude by a PATH search.
real_path_without_claude() {
  local d keep=""
  local IFS=:
  for d in $PATH; do
    [ -n "$d" ] || continue
    if [ -x "$d/claude" ] && [ ! -d "$d/claude" ] && real_path_spares "$d" "$keep"; then continue; fi
    keep="$keep${keep:+:}$d"
  done
  printf '%s\n' "$keep"
}

# real_path_spares <dir> <folders kept before it>: every tool the run needs is found where it was.
real_path_spares() {
  local t without
  without="$2${2:+:}$(real_path_after "$1")"
  for t in git bash sh env jq node cat sed awk grep find mktemp sort cksum tar bwrap socat; do
    [ "$(PATH="$without"; hash -r; command -v "$t" || true)" = "$(hash -r; command -v "$t" || true)" ] || return 1
  done
}

# The folders of PATH after the first occurrence of <dir>.
real_path_after() {
  local d seen=no out=""
  local IFS=:
  for d in $PATH; do
    if [ "$seen" = yes ]; then out="$out${out:+:}$d"; elif [ "$d" = "$1" ]; then seen=yes; fi
  done
  printf '%s' "$out"
}

# The run's settings (ADR-0137): Bash runs inside Claude Code's sandbox, auto-allowed, writes held
# to the run folder and the network closed; a session with no sandbox stops rather than run bare.
# File tools are held to the run folder, web tools, curl and claude denied; any prompt is denied by
# --permission-prompts none. What governs a session lies inside the run folder: real_governing lets
# the launch see a session that changed it, and that run counts for nothing. Auto memory is off,
# since Claude Code itself would write what the next session reads; real_governing still watches it.
real_permissions() {
  jq -n --arg run "$1" '{autoMemoryEnabled: false, permissions: {
    allow: ["Read(/\($run)/**)", "Edit(/\($run)/**)", "Agent"],
    deny: ["WebFetch", "WebSearch", "Bash(curl:*)", "Bash(claude:*)"]},
    sandbox: {enabled: true, autoAllowBashIfSandboxed: true, failIfUnavailable: true,
      filesystem: {allowWrite: [$run]}}}'
}

# real_config <copy>: the run's Claude Code config, installed from that copy of this checkout.
real_config() {
  local log="$J/logs/install.log"
  CLAUDE_CONFIG_DIR="$J/config" POLYPE_PO_FROM_SOURCES=1 bash "$1/polype/bin/polype" install --global > "$log" 2>&1 \
    || { echo "po-eval: the run's global install failed:" >&2; tail -n 5 "$log" >&2; return 2; }
  cp "$REAL_PO_BIN" "$J/config/polype/po"
  real_permissions "$J" > "$J/config/settings.json"
}

# real_sigs <label> <dir> <find expression>: one line per file or link the expression selects under
# <dir>, `<label>/<path> L <target>` or `<label>/<path> F <x|-> <cksum>`.
real_sigs() {
  local label="$1" dir="$2" f
  shift 2
  [ -d "$dir" ] || return 0
  (cd "$dir" && find . "$@" -print0 2>/dev/null) | LC_ALL=C sort -z | while IFS= read -r -d '' f; do
    f="${f#./}"
    if [ -L "$dir/$f" ]; then printf '%s/%s L %s\n' "$label" "$f" "$(readlink "$dir/$f")"
    elif [ -f "$dir/$f" ]; then
      printf '%s/%s F %s %s\n' "$label" "$f" "$([ -x "$dir/$f" ] && echo x || echo -)" "$(cksum < "$dir/$f" | tr ' ' :)"
    fi
  done
}

# What Claude Code, git and the hooks read from a project folder, wherever it lies in the tree.
real_project_sigs() {
  real_sigs "$1" "$2" \( -path ./.git -o -path ./.worktrees -o -path ./.polype/inbox \) -prune -o \
    \( -path '*/.claude' -o -path '*/.claude/*' -o -path ./.polype -o -path './.polype/*' -o -name CLAUDE.md \
       -o -name CLAUDE.local.md -o -name .mcp.json -o -name AGENTS.md \) \( -type f -o -type l \)
}

# What Claude Code loads from a folder that holds the project or a lane: its instruction files and
# its .claude, nothing below.
real_parent_sigs() {
  real_sigs "$1" "$2" -mindepth 1 \( -type d ! -path ./.claude ! -path './.claude/*' -prune \) -o \
    \( -name CLAUDE.md -o -name CLAUDE.local.md -o -name AGENTS.md -o -name .mcp.json -o -path ./.claude -o -path './.claude/*' \) \
    \( -type f -o -type l \)
}

# The instruction files of every folder above the run folder, up to /.
real_above_sigs() {
  local d="$1" f
  while [ "$d" != / ] && [ "$d" != . ]; do
    d="$(dirname "$d")"
    for f in CLAUDE.md CLAUDE.local.md AGENTS.md .claude/CLAUDE.md .claude/AGENTS.md; do
      if [ -L "$d/$f" ]; then printf 'above:%s L %s\n' "${d%/}/$f" "$(readlink "$d/$f")"
      elif [ -f "$d/$f" ]; then printf 'above:%s F %s\n' "${d%/}/$f" "$(cksum < "$d/$f" | tr ' ' :)"; fi
    done
  done
}

# The keys of a .claude.json that change what a session may run; Claude Code rewrites the rest.
real_claude_json() {
  [ -e "$2" ] || return 0
  jq -rS --arg l "$1" '{mcpServers, projects: ((.projects // {}) | map_values({mcpServers, allowedTools,
      enabledMcpjsonServers, disabledMcpjsonServers, enableAllProjectMcpServers})
      | map_values(with_entries(select(.value != null and .value != [] and .value != {} and .value != false)))
      | with_entries(select(.value != {})))}
    | with_entries(select(.value != null and .value != {})) | select(. != {}) | "\($l) \(tojson)"' "$2" 2>/dev/null \
    || echo "$1 unreadable"
}

# real_governing: one line per thing that changes what the next session runs under, each listed by
# name — in the run's Claude Code config, its settings, instructions, rules, commands, agents, skills,
# hooks, output styles, po with the installed method and the installed plugins, plus the auto memory
# and the keys of .claude.json that widen a session; in HOME, the shell and git startup files, git's
# global ignore, .claude and the instruction files; the doubles on PATH and the forge double's
# switches; git's config and hooks of the root and of the origin; the instruction files of the run
# folder, of .worktrees and of every folder above; the project's own config, hooks and memory files
# in the root and in every worktree, a worktree being held to the root's files.
real_governing() {
  local wt root
  real_sigs config "$J/config" -mindepth 1 \( -path ./settings.json -o -path ./settings.local.json \
    -o -path ./CLAUDE.md -o -path ./CLAUDE.local.md -o -path ./AGENTS.md -o -path './rules/*' -o -path './commands/*' \
    -o -path './agents/*' -o -path './skills/*' -o -path './hooks/*' -o -path './output-styles/*' -o -path './polype/*' \
    -o -path './plugins/cache/*' -o -path './plugins/marketplaces/*' -o -path ./plugins/installed_plugins.json \
    -o -path ./plugins/known_marketplaces.json \) \( -type f -o -type l \)
  real_sigs config/projects "$J/config/projects" -mindepth 1 \( -path '*/memory' -o -path '*/memory/*' \) \( -type f -o -type l \)
  real_claude_json config/.claude.json "$J/config/.claude.json"
  real_sigs home "$J/home" -mindepth 1 \( -path ./.bashrc -o -path ./.bash_profile -o -path ./.bash_login \
    -o -path ./.bash_logout -o -path ./.bash_aliases -o -path ./.profile -o -path ./.zshrc -o -path ./.zshenv \
    -o -path ./.zprofile -o -path ./.zlogin -o -path ./.zlogout -o -path ./.envrc -o -path ./.inputrc \
    -o -path ./.gitconfig -o -path ./.mcp.json -o -path ./CLAUDE.md -o -path ./AGENTS.md \
    -o -path './.config/git/*' -o -path './.claude/*' \) \( -type f -o -type l \)
  real_claude_json home/.claude.json "$J/home/.claude.json"
  real_sigs bin "$J/bin" -mindepth 1 \( -type f -o -type l \)
  real_sigs gh "$J/gh" -mindepth 1 \( -type f -o -type l \)
  git config --file "$R/.git/config" --list 2>/dev/null | grep -v '^branch\.' | LC_ALL=C sort | sed 's|^|git-config |'
  real_sigs git-hooks "$R/.git/hooks" -mindepth 1 \( -type f -o -type l \)
  git config --file "$J/origin.git/config" --list 2>/dev/null | LC_ALL=C sort | sed 's|^|origin-config |'
  real_sigs origin-hooks "$J/origin.git/hooks" -mindepth 1 \( -type f -o -type l \)
  real_parent_sigs run "$J"
  real_parent_sigs worktrees "$R/.worktrees"
  real_above_sigs "$J"
  root="$(real_project_sigs project "$R")"
  printf '%s\n' "$root"
  while IFS= read -r wt; do
    [ -n "$wt" ] && [ "$wt" != "$R" ] && [ -d "$wt" ] || continue
    diff <(printf '%s\n' "$root") <(real_project_sigs project "$wt") \
      | sed -n "s|^[<>] project/\([^ ]*\) .*|worktree/${wt#"$R"/}/\1 differs from the root|p"
  done < <({ git -C "$R" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'
             find "$R/.worktrees" -mindepth 1 -maxdepth 1 -type d 2>/dev/null; } | LC_ALL=C sort -u)
}

real_settings_tsv() {
  printf 'Merge mode\tpr\nPlan validation\tautonomous\nShip confirmation\tautomatic\nFull suite\texecute-end\n'
  printf 'E2E stage\t—\nBuild stage\t—\nQA stage\t—\nIssue tracker\tgithub\nStory track\tauto\n'
  printf 'Flow threshold\t2\nForge checks\trequired\nPrivate folder\t~/private/\nTest\tsh checks/run.sh\n'
}

# real_base <base> <copy>: the throwaway project of tests/journey/project/ at $R, its bare origin
# behind https://github.com/acme/project.git, activated by the config's payload.
real_base() {
  local base="$1" copy="$2"
  git init -q -b main "$R"
  git -C "$R" config user.email lead@example.com
  git -C "$R" config user.name lead
  git -C "$R" config commit.gpgsign false
  cp -R "$POLYPE_ROOT/tests/journey/project/." "$R/"
  if [ "$base" = framing ]; then
    rm -f "$R/docs/stories.md" "$R/docs/reviews/stories.md" "$R/docs/architecture.md" "$R/docs/design-system.md"
  else
    cat "$REAL/stories.md" >> "$R/docs/stories.md"
  fi
  real_settings_tsv > "$J/build/settings.tsv"
  {
    printf '# project — Polype settings\n\n```\n'
    awk -F'\t' 'NR == FNR {value[$1] = $2; next}
      /^```/ {fence = !fence; next}
      fence && NF {name = $0; sub(/:.*/, "", name); print (name in value) ? name ": " value[name] : $0}' \
      "$J/build/settings.tsv" "$copy/polype/method/templates/agents-local.md"
    printf '```\n'
  } > "$R/AGENTS.local.md"
  CLAUDE_CONFIG_DIR="$J/config" bash "$J/config/polype/bin/polype" init "$R" --hooks > "$J/logs/init.log" 2>&1 \
    || { echo "po-eval: polype init failed:" >&2; tail -n 5 "$J/logs/init.log" >&2; return 2; }
  git -C "$R" add -A
  git -C "$R" commit -qm 'throwaway project'
  git init -q --bare -b main "$J/origin.git"
  git -C "$R" remote add origin https://github.com/acme/project.git
  git -C "$R" config "url.$J/origin.git.insteadOf" https://github.com/acme/project.git
  git -C "$R" push -q origin main
  git -C "$R" fetch -q origin
}

# Points a copied project at the bare origin beside it.
real_relocate() {
  local key
  for key in $(git -C "$R" config --name-only --get-regexp '^url\..*\.insteadof$' || true); do
    git -C "$R" config --unset "$key"
  done
  git -C "$R" config "url.$J/origin.git.insteadOf" https://github.com/acme/project.git
}

# What the grade compares with: the stories, every ref, each lane's head and the files on disk.
real_snapshot() {
  local lane
  git -C "$R" fetch -q origin
  cp "$R/docs/stories.md" "$J/build/stories.md" 2>/dev/null || : > "$J/build/stories.md"
  git -C "$R" rev-parse refs/remotes/origin/main > "$J/build/main"
  git -C "$R" rev-parse refs/heads/main > "$J/build/local-main"
  git -C "$R" for-each-ref --format='%(objectname)' > "$J/build/refs"
  for lane in "$R/.worktrees"/*; do
    if [ -d "$lane" ]; then git -C "$lane" rev-parse HEAD > "$J/build/lane.${lane##*/}"; fi
  done
  mkdir -p "$J/build/files"
  (cd "$J" && tar --exclude=.git -cf - project) | (cd "$J/build/files" && tar -xf -)
  rm -rf "$J/calls" && mkdir -p "$J/calls"
}

real_check_bounds() {
  local bounds
  bounds="$(cd "$R" && "$PO" state 2>/dev/null | jq -r '.bounds // "unreadable"')" || bounds=unreadable
  [ "$bounds" = held ] || { echo "po-eval: bounds are '$bounds' in the run of $1: nothing launched (ADR-0134)" >&2; return 2; }
}

real_uuid() {
  if [ -r /proc/sys/kernel/random/uuid ]; then cat /proc/sys/kernel/random/uuid
  else uuidgen | tr '[:upper:]' '[:lower:]'; fi
}

real_said() { jq -r 'if .session then "session: \(.session)" else "po \($verb): \(.error // "no answer") — \(.message // "")" end' --arg verb "$1" 2>/dev/null <<< "$2" || echo "po $1: $2"; }

# real_session_held: the last session ended with a result and no error, and left what governs a
# session as it was built (REAL_GOVERNING, held in the launcher's memory, out of the session's reach);
# otherwise nothing more is launched, and such a change marks the run invalid, naming the first path.
real_session_held() {
  local n changed
  n="$(cat "$REAL_OUT.sessions" 2>/dev/null || echo 0)"
  changed="$(diff <(printf '%s\n' "$REAL_GOVERNING") <(real_governing) | sed -n 's/^[<>] \([^ ]*\).*/\1/p' | head -n 1)"
  if [ -n "$changed" ]; then
    echo "session $n changed what a session runs under ($changed)" > "$REAL_OUT.invalid"
    return 1
  fi
  [ "$n" -gt 0 ] && [ -z "$(real_session_fault "$REAL_OUT.session$n.jsonl")" ]
}

# drive: `po run`, then `po continue` while work is left, nothing waits for a person and the last
# session held. A command case: the wrapper once, in the lane its first argument names (at the root
# with CASE_AT=root), else at the root.
real_launch() {
  local out k=1 arg dir="$R" uuid
  if [ "$CASE_LAUNCH" = drive ]; then
    out="$(cd "$R" && "$PO" run 2>&1)" || true
    real_said run "$out"
    while [ "$k" -lt "$REAL_SESSIONS" ]; do
      real_session_held || break
      out="$(cd "$R" && "$PO" state 2>/dev/null)" || break
      jq -e '(((.lanes // []) | length) > 0 or ((.ready // []) | length) > 0)
        and ((.waiting // []) | length) == 0 and ([(.lanes // [])[] | select(.blocked_by != null)] | length) == 0' \
        <<< "$out" > /dev/null 2>&1 || break
      out="$(cd "$R" && "$PO" continue 2>&1)" || true
      real_said continue "$out"
      k=$((k + 1))
    done
  else
    arg="$(awk '{print $2}' <<< "$CASE_LAUNCH")"
    if [ "${CASE_AT:-}" != root ] && [ -n "$arg" ] && [ -d "$R/.worktrees/$arg" ]; then dir="$R/.worktrees/$arg"; fi
    uuid="$(real_uuid)"
    (cd "$dir" && "$PO_CLAUDE" --bg --session-id "$uuid" "$CASE_LAUNCH") || true
    echo "session: ${uuid:0:8}"
  fi
  real_session_held || true
}

real_stop_services() {
  local f pid
  for f in "$J"/services/*.pid; do
    [ -f "$f" ] || continue
    pid="$(cat "$f")"
    [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
  done
}

# --- setup helpers of the cases: each runs from $R and pushes to origin what it commits on main ---

real_commit() { git -C "$R" add -A && git -C "$R" commit -qm "$1" && git -C "$R" push -q origin main; }

real_title() { sed -n "s/^### $1 — //p" "$R/docs/stories.md" | head -n 1; }

# real_fill <file> <id> <tree>: a written answer of the replayed journey, or a seed, placeholders filled.
real_fill() {
  local text
  text="$(cat "$1")"
  text="${text//@ID@/$2}"
  text="${text//@TITLE@/$(real_title "$2")}"
  text="${text//@TREE@/${3:-}}"
  printf '%s\n' "$text"
}

real_answer() { if [ -f "$REAL/seeds/$1" ]; then echo "$REAL/seeds/$1"; else echo "$POLYPE_ROOT/tests/journey/answers/plain/$1"; fi; }

real_setting() {
  local file="$R/AGENTS.local.md"
  grep -q "^$1:" "$file" || { echo "po-eval: AGENTS.local.md has no line $1:" >&2; return 1; }
  NAME="$1" VALUE="$2" awk 'index($0, ENVIRON["NAME"] ":") == 1 {$0 = ENVIRON["NAME"] ": " ENVIRON["VALUE"]} {print}' \
    "$file" > "$file.new"
  mv "$file.new" "$file"
  real_commit "setting $1"
}

# real_story <id> <title> [complexity=N] [surface=S] [depends=ids] [criteria=no]
real_story() {
  local id="$1" title="$2" complexity=2 surface=command depends=aucune criteria=yes kv
  shift 2
  for kv in "$@"; do
    case "$kv" in
      complexity=*) complexity="${kv#*=}" ;; surface=*) surface="${kv#*=}" ;;
      depends=*) depends="${kv#*=}" ;; criteria=*) criteria="${kv#*=}" ;;
      *) echo "po-eval: real_story: unknown field $kv" >&2; return 1 ;;
    esac
  done
  [ -f "$R/docs/stories.md" ] || printf '# Stories\n\n## M1 — Parcours\n' > "$R/docs/stories.md"
  {
    printf '\n### %s — %s\n\n**En tant que** visiteur du projet jetable **je veux** %s **afin de** voir le projet répondre.\n\n' \
      "$id" "$title" "$title"
    printf -- '- **Complexité** : %s\n- **Dépend de** : %s\n- **Surface** : %s\n- **Owns** : `src/%s.txt`, `checks/%s.check`\n' \
      "$complexity" "$depends" "$surface" "$id" "$id"
    if [ "$criteria" = yes ]; then
      printf "\n#### Critères d'acceptation\n- [ ] \`src/%s.txt\` tient le titre de la story ; \`checks/%s.check\` échoue sans lui.\n" "$id" "$id"
    fi
  } >> "$R/docs/stories.md"
  real_commit "story $id"
}

# real_lane <id> <research|validated|verified|reviewed> [research or review answer]: the story's
# worktree brought to that stage the way the pipeline leaves it, from the replayed journey's answers.
real_lane() {
  local id="$1" stage="$2" answer="${3:-}" lane="$R/.worktrees/$1" tree out
  git -C "$R" worktree add -q -b "story/$id" "$lane" main
  mkdir -p "$lane/docs/research" "$lane/docs/plans" "$lane/docs/verif"
  real_fill "$(real_answer "${answer:-research.md}")" "$id" > "$lane/docs/research/$id.md"
  [ "$stage" != research ] || return 0
  if grep -A6 "^### $id — " "$R/docs/stories.md" | grep -q '^- \*\*Surface\*\* : screen$'; then
    mkdir -p "$lane/docs/designs/$id"
    real_fill "$REAL/seeds/design.md" "$id" > "$lane/docs/designs/$id/design.md"
  fi
  real_fill "$(real_answer plan.md)" "$id" | sed '2s/^validated: no$/validated: yes/' > "$lane/docs/plans/$id.md"
  [ "$stage" != validated ] || return 0
  (cd "$lane" && real_fill "$(real_answer code.patch)" "$id" | git apply)
  git -C "$lane" add -A
  tree="$(git -C "$lane" write-tree)"
  real_fill "$(real_answer record.md)" "$id" "$tree" > "$lane/docs/verif/$id.md"
  out="$(cd "$lane" && .polype/hooks/po-run.sh --story "$id" --label 'Unit suite' -- 'sh checks/run.sh' 2>&1)" \
    || { echo "po-eval: po-run failed in the lane of $id: $out" >&2; return 1; }
  git -C "$lane" add -A
  git -C "$lane" commit -qm "$id: $(real_title "$id")"
  [ "$stage" != verified ] || return 0
  tree="$(git -C "$lane" rev-parse 'HEAD^{tree}')"
  real_fill "$(real_answer "${answer:-review.md}")" "$id" "$tree" > "$J/tmp/$id.review.md"
  out="$(cd "$lane" && "$PO" record review "$id" < "$J/tmp/$id.review.md")" \
    || { echo "po-eval: po record review refused the review of $id: $out" >&2; return 1; }
}

# real_seed <seed> <path>: a file of evals/real/seeds/ copied into the root, uncommitted.
real_seed() { mkdir -p "$(dirname "$R/$2")" && cp "$REAL/seeds/$1" "$R/$2"; }

# real_branch <name>: a branch of origin holding one commit over main.
real_branch() {
  local tmp
  tmp="$(mktemp -d "$J/tmp/branch.XXXXXX")"
  git clone -q "$J/origin.git" "$tmp/c"
  git -C "$tmp/c" switch -q -c "$1"
  printf '%s\n' "$1" > "$tmp/c/branch-note.txt"
  git -C "$tmp/c" add -A
  git -C "$tmp/c" -c user.name=other -c user.email=other@example.com commit -qm "work on $1"
  git -C "$tmp/c" push -q origin "$1"
  rm -rf "$tmp"
  git -C "$R" fetch -q origin
}

# real_behind: origin's main moves one commit ahead of the root's main.
real_behind() {
  local tmp
  tmp="$(mktemp -d "$J/tmp/behind.XXXXXX")"
  git clone -q "$J/origin.git" "$tmp/c"
  echo 'moved on the forge' > "$tmp/c/forge-note.txt"
  git -C "$tmp/c" add -A
  git -C "$tmp/c" -c user.name=other -c user.email=other@example.com commit -qm 'a commit made elsewhere'
  git -C "$tmp/c" push -q origin main
  rm -rf "$tmp"
}

# real_gh <issues seed|fail-issue-list|fail-auth|pr <branch>>: what the forge double answers.
real_gh() {
  case "$1" in
    fail-issue-list|fail-auth) : > "$J/gh/$1" ;;
    pr)
      local n
      n=$(( $(find "$J/prs" -name '*.json' | wc -l) + 1 ))
      jq -n --argjson n "$n" --arg h "$2" '{number: $n, url: "https://github.com/acme/project/pull/\($n)", state: "OPEN",
        isDraft: false, headRefName: $h, baseRefName: "main"}' > "$J/prs/$n.json" ;;
    *) cp "$REAL/seeds/$1" "$J/gh/issues.json" ;;
  esac
}

# real_service <name>: a process the run did not start, which a grade checks is left alone.
real_service() {
  (exec -a "$1" sleep 7200) < /dev/null > /dev/null 2>&1 &
  echo "$!" > "$J/services/$1.pid"
}

# real_build_case <case> <copy>: the run folder $J built for the loaded case, its config included.
# Runs under set -e, never inside a condition, so a failing step stops it.
real_build_case() {
  real_config "$2"
  real_base "$CASE_BASE" "$2"
  (cd "$R"; setup)
  real_snapshot
}

# real_one <case> <n> <arm index, 0 for the rule>: one paid run, graded, its folder removed.
real_one() {
  local case="$1" n="$2" a="$3" label="$2" status=0
  REAL_RUN="$(mktemp -d "$REAL_TMP/po-eval-real.XXXXXX")"
  REAL_RUN="$(cd "$REAL_RUN" && pwd -P)"
  [ "$a" -eq 0 ] || label="$n (${ARMS_NAME[a]})"
  REAL_OUT="$REAL_RESULTS/$case.$n${ARMS_SUFFIX[a]}"
  real_launcher "$REAL_WORK/launch.$case.$n${ARMS_SUFFIX[a]}"
  set +e
  (
    set -e
    real_env "$REAL_RUN"
    real_build_case "$case" "${ARMS_COPY[a]}"
    REAL_GOVERNING="$(real_governing)"
    real_check_bounds "$case"
    real_launch
    real_grade "$case" "$label"
  )
  status=$?
  set -e
  real_drop_run
  REAL_RUN=""
  [ "$status" -eq 0 ] || { echo "po-eval: the run $label of $case could not be graded; nothing more is launched" >&2; exit 2; }
}

# real_launcher <file>: the script PO_CLAUDE names for one run. It hands claude-print what the run
# needs from outside the run's environment, which never holds the real claude's path.
real_launcher() {
  REAL_LAUNCHER="$1"
  printf '#!/usr/bin/env bash\nREAL_CLAUDE=%q REAL_OUT=%q REAL_BUDGET=%q REAL_MODEL=%q exec bash %q "$@"\n' \
    "$REAL_CLAUDE" "$REAL_OUT" "$REAL_BUDGET" "$REAL_MODEL" "$REAL/claude-print" > "$REAL_LAUNCHER"
  chmod 700 "$REAL_LAUNCHER"
}

# real_rate <case> <arm suffix> [observation]: how many of the case's valid runs passed, or saw the
# observation. An invalid run is in no rate.
real_rate() {
  local n p=0 f
  for n in $(seq 1 "$REAL_REPEAT"); do
    f="$REAL_RESULTS/$1.$n$2.grade"
    if [ -z "${3:-}" ]; then [ "$(head -n 1 "$f" 2>/dev/null)" = pass ] && p=$((p + 1))
    else grep -qxF "observe $3: yes" "$f" 2>/dev/null && p=$((p + 1)); fi
  done
  echo "$p"
}

# real_valid <case> <arm suffix>: how many of the case's runs count.
real_valid() {
  local n v=0
  for n in $(seq 1 "$REAL_REPEAT"); do
    [ "$(head -n 1 "$REAL_RESULTS/$1.$n$2.grade" 2>/dev/null)" = invalid ] || v=$((v + 1))
  done
  echo "$v"
}

# The margin of ADR-0133: 1 up to 5 runs per arm, 2 above.
real_margin() { if [ "$REAL_REPEAT" -le 5 ]; then echo 1; else echo 2; fi; }

real_summary() {
  local case a n f line obs rule ctl margin lowered="" raised="" still="" unjudged="" moved judged
  margin="$(real_margin)"
  for case in "${REAL_SELECTED[@]}"; do
    real_load_case "$case"
    if [ "${#ARMS_NAME[@]}" -eq 1 ]; then
      echo "$case: $(real_rate "$case" "")/$(real_valid "$case" "") passed"
    else
      line="$case: rule $(real_rate "$case" "")/$(real_valid "$case" "")"
      for ((a = 1; a < ${#ARMS_NAME[@]}; a++)); do
        line+=" | control ${ARMS_NAME[a]} $(real_rate "$case" "${ARMS_SUFFIX[a]}")/$(real_valid "$case" "${ARMS_SUFFIX[a]}")"
      done
      echo "$line"
    fi
    for obs in ${CASE_OBSERVE[@]+"${CASE_OBSERVE[@]}"}; do
      line="$case observe $obs: "
      if [ "${#ARMS_NAME[@]}" -eq 1 ]; then line+="$(real_rate "$case" "" "$obs")/$(real_valid "$case" "")"
      else
        line+="rule $(real_rate "$case" "" "$obs")/$(real_valid "$case" "")"
        for ((a = 1; a < ${#ARMS_NAME[@]}; a++)); do
          line+=" | control ${ARMS_NAME[a]} $(real_rate "$case" "${ARMS_SUFFIX[a]}" "$obs")/$(real_valid "$case" "${ARMS_SUFFIX[a]}")"
        done
      fi
      echo "$line"
    done
    for ((a = 0; a < ${#ARMS_NAME[@]}; a++)); do
      for n in $(seq 1 "$REAL_REPEAT"); do
        f="$REAL_RESULTS/$case.$n${ARMS_SUFFIX[a]}.grade"
        [ "$(head -n 1 "$f" 2>/dev/null)" = invalid ] || continue
        echo "invalid: $case run $n$([ "$a" -eq 0 ] || echo " (${ARMS_NAME[a]})") — $(sed -n 2p "$f")"
      done
    done
  done
  [ "${#ARMS_NAME[@]}" -gt 1 ] || return 0
  # An arm is compared on a case only when every run of the rule and of that arm counted there: an
  # arm with an invalid run is never said to have moved no rate.
  for ((a = 1; a < ${#ARMS_NAME[@]}; a++)); do
    moved=no judged=yes
    for case in "${REAL_SELECTED[@]}"; do
      real_load_case "$case"
      if [ "$(real_valid "$case" "")" -lt "$REAL_REPEAT" ] || [ "$(real_valid "$case" "${ARMS_SUFFIX[a]}")" -lt "$REAL_REPEAT" ]; then
        judged=no
        continue
      fi
      for obs in "" ${CASE_OBSERVE[@]+"${CASE_OBSERVE[@]}"}; do
        rule="$(real_rate "$case" "" "$obs")" ctl="$(real_rate "$case" "${ARMS_SUFFIX[a]}" "$obs")"
        if [ $((rule - ctl)) -ge "$margin" ]; then lowered+="${lowered:+, }${ARMS_NAME[a]} on $case${obs:+ ($obs)}"; moved=yes; fi
        if [ $((ctl - rule)) -ge "$margin" ]; then raised+="${raised:+, }${ARMS_NAME[a]} on $case${obs:+ ($obs)}"; moved=yes; fi
      done
    done
    if [ "$judged" = no ]; then unjudged+="${unjudged:+, }${ARMS_NAME[a]}"
    elif [ "$moved" = no ]; then still+="${still:+, }${ARMS_NAME[a]}"; fi
  done
  echo "lowered: ${lowered:-none}"
  echo "raised: ${raised:-none}"
  echo "moved no rate: ${still:-none}"
  [ -z "$unjudged" ] || echo "not judged, invalid runs: $unjudged"
}

real_rules() {
  awk -F'\t' 'NR == 1 || /^#/ || NF < 6 {next}
    {
      line = $1 ":"
      if ($3 == "—") line = line " no case — " $6
      else {n = split($3, c, " "); for (i = 1; i <= n; i++) line = line (i > 1 ? ";" : "") " case " c[i]}
      line = line "; kind " $2 "; held by " $4 "; test may go " $5
      if ($3 != "—") line = line "; " $6
      print line
    }' "$REAL/rules.tsv"
}

# Copies each kept file over itself with every secret po-gate knows and every secret-named
# environment value replaced by [redacted], as method/hooks/po-intake.sh:81-103 does.
real_scrub() {
  local f
  find "$1" -type f | while IFS= read -r f; do
    bash "$POLYPE_ROOT/method/hooks/po-gate.sh" redact "$f" > "$f.redacted" 2>/dev/null || cp "$f" "$f.redacted"
    awk '
      BEGIN {
        for (k in ENVIRON) {
          if (toupper(k) !~ /TOKEN|KEY|SECRET|PASSWORD/) continue
          m = split(ENVIRON[k], parts, "\n")
          for (j = 1; j <= m; j++) if (length(parts[j]) >= 8) vals[++nv] = parts[j]
        }
      }
      {
        line = $0
        for (v = 1; v <= nv; v++) {
          out = ""; rest = line
          while ((p = index(rest, vals[v])) > 0) {
            out = out substr(rest, 1, p - 1) "[redacted]"; rest = substr(rest, p + length(vals[v]))
          }
          line = out rest
        }
        print line
      }' "$f.redacted" > "$f"
    rm -f "$f.redacted"
  done
}

real_drop_run() {
  if [ -n "${REAL_RUN:-}" ] && [ -d "$REAL_RUN" ]; then (J="$REAL_RUN"; real_stop_services); rm -rf "$REAL_RUN"; fi
}

real_finish() {
  real_drop_run
  [ -z "${REAL_WORK:-}" ] || rm -rf "$REAL_WORK"
  [ -n "${REAL_RESULTS:-}" ] && [ -d "$REAL_RESULTS" ] || return 0
  if [ "$REAL_KEEP" = yes ]; then real_scrub "$REAL_RESULTS"; else rm -rf "$REAL_RESULTS"; fi
}

# The tree of these paths differs from HEAD, untracked files included.
real_dirty() { [ -n "$(git -C "$POLYPE_ROOT" status --porcelain -- bin method po evals 2>/dev/null)" ]; }

# real_spent <results folder>: what the sessions cost. A result event carries its session's running
# totals, so each session counts once, by its last result; a session with none adds nothing.
real_spent() {
  local f n=0 cost=0 in=0 out=0 row
  for f in "$1"/*.session[0-9]*.jsonl; do
    [ -e "$f" ] || continue
    n=$((n + 1))
    row="$(jq -nrR '[inputs | fromjson? | select(type == "object" and .type == "result")] | last // {}
      | [(.total_cost_usd // 0),
         (if .modelUsage then ([.modelUsage[]?.inputTokens // 0] | add // 0) else (.usage.input_tokens // 0) end),
         (if .modelUsage then ([.modelUsage[]?.outputTokens // 0] | add // 0) else (.usage.output_tokens // 0) end)]
      | @tsv' < "$f" 2>/dev/null)" || { echo "cost: unreadable"; return 0; }
    [ -n "$row" ] || { echo "cost: unreadable"; return 0; }
    read -r c i o <<< "$row"
    cost="$(awk -v a="$cost" -v b="$c" 'BEGIN { printf "%.10f", a + b }')"
    in=$((in + ${i%.*})) out=$((out + ${o%.*}))
  done
  awk -v c="$cost" -v n="$n" -v i="$in" -v o="$out" 'BEGIN { printf "cost: %.2f USD over %d sessions; tokens in %d, out %d\n", c, n, i, o }'
}

# real_record: the run's record under the first free name of its day and version, never over one.
real_record() {
  local version commit base file usage n=2
  version="$(sed -n 's/^POLYPE_VERSION="\(.*\)"$/\1/p' "$POLYPE_ROOT/bin/polype" | head -n 1)"
  commit="$(git -C "$POLYPE_ROOT" rev-parse --short HEAD)"
  base="$POLYPE_ROOT/docs/evals/real-$(date +%Y-%m-%d)-v$version"
  file="$base.md"
  while [ -e "$file" ] || [ -L "$file" ]; do file="$base-$n.md"; n=$((n + 1)); done
  usage="$(real_spent "$REAL_RESULTS")"
  mkdir -p "$POLYPE_ROOT/docs/evals"
  (set -C; {
    echo "# Passage réel — $(date +%Y-%m-%d), Polype $version"
    echo
    echo "- Date: $(date +%Y-%m-%dT%H:%M:%S%z)"
    echo "- Version: $version, commit \`$commit\`"
    echo "- Model: ${REAL_MODEL:-the session default}; case settings: $REAL_MODELS"
    echo "- Login from: $REAL_LOGIN"
    echo "- Cases: ${REAL_SELECTED[*]}; $REAL_REPEAT runs per arm, up to $REAL_SESSIONS sessions each, budget $REAL_BUDGET USD per session"
    echo "- Arms: rule${ARMS_NAME[1]:+ and controls ${ARMS_NAME[*]:1}}"
    echo "- $usage"
    echo
    echo "## Rates"
    echo
    sed 's/^/    /' "$REAL_RESULTS/summary.txt"
    echo
    echo "## Runs"
    echo
    grep -E '^(story |case |session: )' "$REAL_RESULTS/runs.txt" | sed 's/^/    /'
    echo
    echo "No transcript is kept in this file."
  } > "$file") || { echo "po-eval: the record $file could not be written without overwriting one" >&2; return 2; }
  echo "record: ${file#"$POLYPE_ROOT"/}"
}

# The Model strong and Model light a case runs with: the template's, unless its setup sets them.
real_models_of() {
  local strong light file="$REAL/cases/$1.sh" tpl="$POLYPE_ROOT/method/templates/agents-local.md"
  strong="$(sed -n "s/^[[:space:]]*real_setting 'Model strong' \(.*\)$/\1/p" "$file" | tr -d "'\"" | head -n 1)"
  light="$(sed -n "s/^[[:space:]]*real_setting 'Model light' \(.*\)$/\1/p" "$file" | tr -d "'\"" | head -n 1)"
  [ -n "$strong" ] || strong="$(sed -n 's/^Model strong:[[:space:]]*//p' "$tpl" | head -n 1)"
  [ -n "$light" ] || light="$(sed -n 's/^Model light:[[:space:]]*//p' "$tpl" | head -n 1)"
  echo "$1 Model strong $strong, Model light $light"
}

real_build_one() {
  local name="$1" dir="$2" status
  real_load_case "$name" || exit 2
  mkdir -p "$dir"
  dir="$(cd "$dir" && pwd -P)"
  [ -z "$(ls -A "$dir")" ] || { echo "po-eval: $dir is not empty" >&2; exit 2; }
  real_build_po
  set +e
  (
    set -e
    real_env "$dir"
    arm_copy "$J/source"
    real_build_case "$name" "$J/source"
    rm -rf "$J/source"
  )
  status=$?
  set -e
  (J="$dir"; real_stop_services)
  [ "$status" -eq 0 ] || { echo "po-eval: the case $name does not build" >&2; exit 2; }
  echo "$dir/project"
}

# Each base built once, copied for every case, which then runs its own setup.
real_build_all() {
  local dir="$1" name base status
  mkdir -p "$dir"
  dir="$(cd "$dir" && pwd -P)"
  real_build_po
  set +e
  (
    set -e
    real_env "$dir/.shared"
    arm_copy "$J/source"
    real_config "$J/source"
  )
  status=$?
  set -e
  [ "$status" -eq 0 ] || { echo "po-eval: the shared config does not build" >&2; exit 2; }
  for name in $(real_cases); do
    real_load_case "$name" || exit 2
    base="$CASE_BASE"
    if [ "$base" = lane ]; then base=journey; fi
    if [ ! -d "$dir/.bases/$base/project" ]; then
      set +e
      (
        set -e
        real_env "$dir/.bases/$base"
        ln -s "$dir/.shared/config" "$J/config"
        real_base "$base" "$dir/.shared/source"
      ) > "$dir/.shared/base.$base.log" 2>&1
      status=$?
      set -e
      [ "$status" -eq 0 ] || { echo "po-eval: the base $base does not build:" >&2; tail -n 5 "$dir/.shared/base.$base.log" >&2; exit 2; }
    fi
    set +e
    (
      set -e
      real_env "$dir/$name"
      ln -s "$dir/.shared/config" "$J/config"
      cp -a "$dir/.bases/$base/project" "$dir/.bases/$base/origin.git" "$J/"
      real_relocate
      (cd "$R"; setup)
      real_snapshot
    ) > "$dir/.shared/$name.log" 2>&1
    status=$?
    set -e
    (J="$dir/$name"; real_stop_services)
    [ "$status" -eq 0 ] || { echo "po-eval: the case $name does not build:" >&2; tail -n 5 "$dir/.shared/$name.log" >&2; exit 2; }
    echo "$name: built"
  done
}

real_main() {
  local list=no rules=no build="" build_all="" a n case answer total cost tool missing
  REAL_REPEAT=1 REAL_SESSIONS=3 REAL_MODEL="" REAL_BUDGET=10 REAL_KEEP=no REAL_RECORD=no REAL_RUN_PATH=""
  REAL_SELECTED=() ARMS_NAME=(rule) ARMS_SUFFIX=("") ARMS_SPEC=("")
  local -a arm_specs=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --repeat) [ $# -ge 2 ] && [[ "$2" =~ ^[1-9][0-9]*$ ]] || real_usage; REAL_REPEAT="$2"; shift 2 ;;
      --sessions) [ $# -ge 2 ] && [[ "$2" =~ ^[1-9][0-9]*$ ]] || real_usage; REAL_SESSIONS="$2"; shift 2 ;;
      --model) [ $# -ge 2 ] && [ -n "$2" ] || real_usage; REAL_MODEL="$2"; shift 2 ;;
      --budget) [ $# -ge 2 ] && [[ "$2" =~ ^[0-9]+(\.[0-9]+)?$ ]] || real_usage; REAL_BUDGET="$2"; shift 2 ;;
      --arm) [ $# -ge 2 ] && [ -n "$2" ] || real_usage; arm_specs+=("$2"); shift 2 ;;
      --keep) REAL_KEEP=yes; shift ;;
      --record) REAL_RECORD=yes; shift ;;
      --list) list=yes; shift ;;
      --rules) rules=yes; shift ;;
      --build) [ $# -eq 3 ] || real_usage; build="$2"; build_all="$3"; shift 3 ;;
      --build-all) [ $# -eq 2 ] || real_usage; build_all="$2"; shift 2 ;;
      -*) echo "po-eval: unknown option $1" >&2; real_usage ;;
      *) REAL_SELECTED+=("$1"); shift ;;
    esac
  done
  if [ "$list" = yes ]; then real_cases; return 0; fi
  if [ "$rules" = yes ]; then real_rules; return 0; fi
  local -a selected_by_cli=(${REAL_SELECTED[@]+"${REAL_SELECTED[@]}"})
  if [ -n "$build" ]; then real_build_one "$build" "$build_all"; return 0; fi
  if [ -n "$build_all" ]; then real_build_all "$build_all"; return 0; fi

  for a in ${arm_specs[@]+"${arm_specs[@]}"}; do
    arm_read "$a" || exit 2
    for n in "${ARMS_NAME[@]}"; do
      [ "$n" != "$ARM_NAME" ] || { echo "po-eval: two arms are named $ARM_NAME" >&2; exit 2; }
    done
    ARMS_NAME+=("$ARM_NAME") ARMS_SUFFIX+=(".$ARM_NAME") ARMS_SPEC+=("$a")
    # shellcheck disable=SC2206
    [ ${#selected_by_cli[@]} -gt 0 ] || [ -z "$ARM_CASES" ] || REAL_SELECTED+=($ARM_CASES)
  done
  [ ${#REAL_SELECTED[@]} -gt 0 ] || REAL_SELECTED=(journey)
  mapfile -t REAL_SELECTED < <(printf '%s\n' "${REAL_SELECTED[@]}" | awk '!seen[$0]++')
  REAL_MODELS=""
  for case in "${REAL_SELECTED[@]}"; do
    (real_load_case "$case") || exit 2
    REAL_MODELS+="${REAL_MODELS:+; }$(real_models_of "$case")"
  done
  if [ "$REAL_RECORD" = yes ] && real_dirty; then
    echo "po-eval: --record needs bin/, method/, po/ and evals/ as HEAD has them; commit or set aside the changes first" >&2
    exit 2
  fi
  if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    echo "po-eval: a real run launches claude on a temporary config dir that holds no login; set ANTHROPIC_API_KEY, or CLAUDE_CODE_OAUTH_TOKEN from \`claude setup-token\`; nothing run" >&2
    exit 2
  fi
  REAL_LOGIN=""
  [ -z "${ANTHROPIC_API_KEY:-}" ] || REAL_LOGIN=ANTHROPIC_API_KEY
  [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] || REAL_LOGIN+="${REAL_LOGIN:+ and }CLAUDE_CODE_OAUTH_TOKEN"
  REAL_CLAUDE="$(command -v claude || true)"
  case "$REAL_CLAUDE" in /*) ;; *) echo "po-eval: no claude program on PATH; nothing run" >&2; exit 2 ;; esac
  REAL_RUN_PATH="$(real_path_without_claude)"
  if [ "$(uname -s)" = Linux ]; then
    missing=""
    for tool in bwrap socat; do
      (PATH="$REAL_RUN_PATH"; command -v "$tool" > /dev/null) || missing+="${missing:+ and }$tool"
    done
    if [ -n "$missing" ]; then
      echo "po-eval: a real run needs Claude Code's sandbox: $missing not found on PATH; nothing run" >&2
      exit 2
    fi
  fi

  total=$(( ${#REAL_SELECTED[@]} * REAL_REPEAT * ${#ARMS_NAME[@]} ))
  if [ "${#ARMS_NAME[@]}" -gt 1 ]; then
    echo "${#REAL_SELECTED[@]} cases × $REAL_REPEAT repetitions × ${#ARMS_NAME[@]} arms = $total paid runs of claude -p"
  else
    echo "${#REAL_SELECTED[@]} cases × $REAL_REPEAT repetitions = $total paid runs of claude -p"
  fi
  echo "model: ${REAL_MODEL:-the session default}; case settings: $REAL_MODELS"
  cost="$(awk -v b="$REAL_BUDGET" -v s="$REAL_SESSIONS" -v t="$total" 'BEGIN {printf "%g", b * s * t}')"
  echo "budget: $REAL_BUDGET USD per session, $cost USD at most"
  echo "login from $REAL_LOGIN"
  echo "permissions: Claude Code sandbox, prompts denied — for a person who watches this run"
  printf 'Continue? [y/N] '
  if [ ! -t 0 ]; then
    echo
    echo "po-eval: a real run needs a terminal: it is for a person who launches and watches it (ADR-0134); nothing run" >&2
    exit 2
  fi
  answer=""
  read -r answer || true
  case "$answer" in
    y|Y|yes|YES|Yes) ;;
    *) echo "nothing run"; exit 1 ;;
  esac

  REAL_TMP="${TMPDIR:-/tmp}"
  REAL_TMP="${REAL_TMP%/}"
  REAL_RUN="" REAL_WORK="" REAL_RESULTS=""
  trap real_finish EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM
  REAL_RESULTS="$(mktemp -d "$REAL_TMP/po-eval-results.XXXXXX")"
  chmod 700 "$REAL_RESULTS"
  echo "results: $REAL_RESULTS"
  real_build_po
  REAL_WORK="$(mktemp -d "$REAL_TMP/po-eval-arms.XXXXXX")"
  ARMS_COPY=("$REAL_WORK/rule")
  arm_copy "$REAL_WORK/rule"
  for ((a = 1; a < ${#ARMS_NAME[@]}; a++)); do
    arm_read "${ARMS_SPEC[a]}"
    arm_copy "$REAL_WORK/arm$a" "${ARMS_SPEC[a]}"
    ARMS_COPY+=("$REAL_WORK/arm$a")
  done
  # Handed to claude-print by each run's launcher (real_launcher), never through the environment.
  export -n REAL_CLAUDE REAL_BUDGET REAL_MODEL REAL_SESSIONS REAL_OUT REAL_LAUNCHER REAL_RUN_PATH 2>/dev/null || true
  {
    # The runs live in this subshell: its own trap removes the run folder an interrupt leaves.
    trap real_drop_run EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
    for case in "${REAL_SELECTED[@]}"; do
      real_load_case "$case"
      for n in $(seq 1 "$REAL_REPEAT"); do
        for ((a = 0; a < ${#ARMS_NAME[@]}; a++)); do real_one "$case" "$n" "$a"; done
      done
    done
  } | tee "$REAL_RESULTS/runs.txt"
  [ "${PIPESTATUS[0]}" -eq 0 ] || exit 2
  real_summary | tee "$REAL_RESULTS/summary.txt"
  [ "$REAL_RECORD" != yes ] || real_record
  echo "results: $REAL_RESULTS"
}
