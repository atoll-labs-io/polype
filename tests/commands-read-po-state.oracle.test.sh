#!/usr/bin/env bash
# s172 — oracle: po-session prints what `po state` returns and derives nothing itself; it survives
# a missing po or a missing jq. A stub po stands where the hook looks for it, and its JSON
# contradicts the files on disk, so a line the hook derived itself cannot pass for one it read.

HOOK="$METHOD/hooks/po-session.sh"

# A Polype project at $R with no brief and no stories on disk; $C is its throwaway config dir.
oracle_project() {
  scratch_repo
  R="$(cd "$SCRATCH" && pwd -P)"
  C="$R/.config"
  printf 'Target branch: main\nWorktree root: .worktrees/\nEntry mode: new\nMax attempts: 2\nMerge mode: pr\nShip confirmation: automatic\nProject CLAUDE file: absorbed\n' \
    > "$R/AGENTS.local.md"
  printf '.worktrees/\n.config/\n' > "$R/.gitignore"
  git -C "$R" add -A && git -C "$R" commit -qm framing
}

# stub_po <json>: a po at $C/polype/po that records its arguments and directory, then prints <json>.
stub_po() {
  mkdir -p "$C/polype"
  printf '%s\n' "$1" > "$C/polype/state.json"
  cat > "$C/polype/po" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${0%/*}/args"
pwd -P > "${0%/*}/cwd"
cat "${0%/*}/state.json"
EOF
  chmod +x "$C/polype/po"
}

# session [PATH]: runs the hook from $R with $C as config dir; sets OUT and STATUS.
session() {
  local path="${1:-$PATH}" bash_bin
  bash_bin="$(PATH="$path" command -v bash)"
  STATUS=0
  OUT="$(cd "$R" && PATH="$path" CLAUDE_CONFIG_DIR="$C" CLAUDE_PROJECT_DIR="$R" "$bash_bin" "$HOOK" 2>&1)" || STATUS=$?
}

has_line() { grep -qxF -- "$1" <<< "$OUT" || fail "po-session did not print the line: $1"$'\n'"$OUT"; }
lacks_text() { if grep -qF -- "$1" <<< "$OUT"; then fail "po-session printed: $1"$'\n'"$OUT"; fi; }

# A PATH holding every executable of the current one except jq.
path_without_jq() {
  local out="$SCRATCH/nojq" d
  local -a dirs
  mkdir -p "$out"
  IFS=: read -ra dirs <<< "$PATH"
  for d in "${dirs[@]}"; do
    [ -d "$d" ] || continue
    find "$d" -maxdepth 1 \( -type f -o -type l \) -perm -u+x -print0 2>/dev/null \
      | xargs -0 -r ln -s -t "$out" 2>/dev/null || true
  done
  rm -f "$out/jq"
  if PATH="$out" command -v jq >/dev/null 2>&1; then fail "jq is still reachable without it"; fi
  printf '%s' "$out"
}

STATE_FULL='{"contract":1,"project":"x","commit":"abc1234","method_version":"0.2.0",
"framing":{"stage":"architecture","next":"/po-architect","items":[{"item":"scope","state":"approved"},{"item":"stories","state":"present"},{"item":"stories-review","state":"yes"},{"item":"architecture","state":"missing"},{"item":"design-system","state":"not needed"}]},
"milestone":null,"session":null,"bounds":"unproven","waiting":[],
"lanes":[
 {"story":"s07-g","path":".worktrees/s07-g","stage":"review","next":null,"blocked_by":"root-cause-not-found","stops":[{"code":"root-cause-not-found","file":"docs/research/s07-g.md"},{"code":"technical-choice","file":"docs/plans/s07-g.md","command":"/po-plan s07-g"}]},
 {"story":"s08-h","path":".worktrees/s08-h","stage":"review","next":null,"blocked_by":"qa-blocked","stops":[{"code":"qa-blocked","file":"docs/qa/s08-h/report.md"},{"code":"max-attempts","fix_loop":3,"max_attempts":2}]},
 {"story":"s09-i","path":"/elsewhere/s09-i","stage":"ship","next":null,"blocked_by":"merge-waiting","stops":[{"code":"merge-waiting","branch":"story/s09-i"}]}],
"ready":["s10-j","s11-k"],"held":[],"shipped":[],
"warnings":[{"code":"missing-setting","setting":"Max attempts"},{"code":"unreadable-setting","setting":"Entry mode"},{"code":"orphan-worktree","path":".worktrees/s12-o","branch":null},{"code":"orphan-worktree","path":"/x/y","branch":"other"},{"code":"missing-setting","setting":"Decision inbox"},{"code":"no-gate","story":"s07-g"}]}'

STATE_EMPTY='{"contract":1,"project":"x","commit":"abc1234","method_version":"0.2.0",
"framing":{"stage":"done","next":null,"items":[{"item":"scope","state":"by hand"},{"item":"stories","state":"present"},{"item":"stories-review","state":"yes"},{"item":"architecture","state":"present"},{"item":"design-system","state":"present"}]},
"milestone":null,"session":null,"bounds":"unproven","waiting":[],"lanes":[],"ready":null,"held":null,"shipped":null,"warnings":[]}'

test_session_hook_prints_from_po_state() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  oracle_project
  stub_po "$STATE_FULL"
  session
  [ "$STATUS" -eq 0 ] || fail "po-session exited $STATUS: $OUT"
  [ "$(cat "$C/polype/args")" = state ] || fail "po was not called as 'po state': $(cat "$C/polype/args")"
  [ "$(cat "$C/polype/cwd")" = "$R" ] || fail "po state did not run from the project root: $(cat "$C/polype/cwd")"
  has_line 'Framing: scope approved · stories present · stories review yes · architecture missing · design system not needed'
  has_line 'Framing next: /po-architect'
  has_line 'Unreadable setting: Max attempts'
  has_line 'Unreadable setting: Entry mode'
  has_line 'Ready stories: s10-j, s11-k'
  has_line 'Lanes in flight: s07-g (.worktrees/s07-g), s08-h (.worktrees/s08-h), s09-i (/elsewhere/s09-i)'
  has_line 'Waiting for a human:'
  has_line '- s07-g: root cause not found (docs/research/s07-g.md)'
  has_line '- s07-g: technical choice waiting for a human (docs/plans/s07-g.md) → /po-plan s07-g'
  has_line '- s08-h: QA blocked (docs/qa/s08-h/report.md)'
  has_line '- s08-h: Max attempts reached (Fix loop: 3, Max attempts: 2)'
  has_line '- s09-i: pull request presumed waiting for a human merge (story/s09-i pushed; the forge was not asked)'
  has_line '- .worktrees/s12-o: orphan worktree (detached HEAD)'
  has_line '- /x/y: orphan worktree (other)'
  [ "$(grep -c '^- ' <<< "$OUT")" -eq 7 ] || fail "expected exactly 7 waiting lines:"$'\n'"$OUT"
  lacks_text 'Decision inbox'
  lacks_text 'no-gate'

  stub_po "$STATE_EMPTY"
  session
  [ "$STATUS" -eq 0 ] || fail "po-session exited $STATUS: $OUT"
  has_line 'Framing: scope by hand · stories present · stories review yes · architecture present · design system present'
  has_line 'Framing next: none — framing done'
  has_line 'Ready stories: not computed — Parallel is missing or unreadable in AGENTS.local.md'
  has_line 'Lanes in flight: none'
  has_line 'Waiting for a human: nothing'

  printf 'Parallel: 2\n' >> "$R/AGENTS.local.md"
  session
  has_line 'Ready stories: not read by po'
  lacks_text 'Parallel is missing'
}

test_session_hook_survives_a_missing_po() {
  oracle_project
  mkdir -p "$C"
  session
  [ "$STATUS" -eq 0 ] || fail "po-session exited $STATUS without po: $OUT"
  grep -F 'po not found' <<< "$OUT" | grep -qF 'polype install' || fail "no line names the missing po and the installer: $OUT"
  lacks_text 'Framing'
  lacks_text 'Ready stories'

  stub_po "$STATE_FULL"
  local bare; bare="$(path_without_jq)"
  session "$bare"
  [ "$STATUS" -eq 0 ] || fail "po-session exited $STATUS without jq: $OUT"
  grep -F 'jq not found' <<< "$OUT" | grep -qF "$C/polype/po state" || fail "no line names jq and points to po state: $OUT"
  lacks_text 'Framing'

  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  stub_po '{"contract":1,"project":"x","commit":null,"method_version":"0.2.0","framing":null,"milestone":null,"session":null,"bounds":"unproven","waiting":null,"lanes":null,"ready":null,"held":null,"shipped":null,"warnings":[{"code":"method-version-mismatch","po":"9.9.9","project":"0.2.0"}]}'
  session
  [ "$STATUS" -eq 0 ] || fail "po-session exited $STATUS on a version warning: $OUT"
  has_line 'po warning: {"code":"method-version-mismatch","po":"9.9.9","project":"0.2.0"}'
}
