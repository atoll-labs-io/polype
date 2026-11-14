#!/usr/bin/env bash
# s172 — task tests: a failing po state is reported, never replaced by a derivation; the two
# commands that now read po state are shorter than the prose they replaced.

HOOK="$METHOD/hooks/po-session.sh"

failing_po_project() {
  scratch_repo
  R="$(cd "$SCRATCH" && pwd -P)"
  C="$R/.config"
  printf 'Target branch: main\nWorktree root: .worktrees/\nEntry mode: new\nMax attempts: 2\nMerge mode: pr\nShip confirmation: automatic\n' \
    > "$R/AGENTS.local.md"
  printf '.config/\n' > "$R/.gitignore"
  git -C "$R" add -A && git -C "$R" commit -qm framing
  mkdir -p "$C/polype"
  cat > "$C/polype/po" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '{"contract":1,"error":"not-a-project","message":"x"}'
exit 2
EOF
  chmod +x "$C/polype/po"
}

test_session_hook_reports_a_failing_po() {
  command -v jq >/dev/null 2>&1 || fail "jq is required by this test"
  failing_po_project
  local out status=0
  out="$(cd "$R" && CLAUDE_CONFIG_DIR="$C" CLAUDE_PROJECT_DIR="$R" bash "$HOOK" 2>&1)" || status=$?
  [ "$status" -eq 0 ] || fail "po-session exited $status: $out"
  grep -qF 'po state failed (exit 2)' <<< "$out" || fail "no line reports the failing po state: $out"
  if grep -qF 'Framing' <<< "$out"; then fail "po-session derived a framing line: $out"; fi
}

test_status_and_retro_shrink() {
  [ "$(wc -w < "$METHOD/commands/po-status.md")" -lt 1101 ] || fail "po-status.md did not shrink below 1101 words"
  [ "$(wc -w < "$METHOD/commands/po-retro.md")" -lt 977 ] || fail "po-retro.md did not shrink below 977 words"
}
