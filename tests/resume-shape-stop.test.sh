#!/usr/bin/env bash
# s145 — the orchestrator and /po-flow hand a review blocked on its findings' shape to a person and spend no fix run.

ORCH="$METHOD/commands/po-orchestrator.md"
FLOW="$METHOD/commands/po-flow.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

test_orchestrator_stops_on_shape_block() {
  local s7 s5 marker catchall m c
  s7=$(section_of "$ORCH" 'Stage 7 — Review')
  s5=$(section_of "$ORCH" 'Stage 5 — Execute')
  marker='`Review status: blocked` and a `Next action:` naming `po-gate findings-shape` → stop for a human'
  catchall='Any other blocked review → back to stage 5 as a fix run'
  holds "$s7" 'Delegate to `reviewer` the way `/po-review` does' "orchestrator Stage 7"
  holds "$s7" 'as `/po-review` says' "orchestrator Stage 7"
  holds "$s7" "$marker" "orchestrator Stage 7"
  holds "$s7" 'the check could not run (exit <n>)' "orchestrator Stage 7"
  m=$(grep -nF -- "$marker" "$ORCH" | head -1 | cut -d: -f1)
  c=$(grep -nF -- "$catchall" "$ORCH" | head -1 | cut -d: -f1)
  [ -n "$m" ] && [ -n "$c" ] && [ "$m" -lt "$c" ] || fail "the shape stop must come before the catch-all fix run"
  holds "$s5" 'nor one blocked on findings shape' "orchestrator Stage 5"
}

test_flow_stops_on_shape_block() {
  local line marker
  line=$(grep -F '3. **Fix loops**' "$FLOW")
  marker='`Next action:` naming `po-gate findings-shape` → stop'
  holds "$line" "$marker" "flow Fix loops"
  holds "$line" 'the check could not run (exit <n>)' "flow Fix loops"
  holds "$line" 'Any other `Ship allowed: no` → a fix run of the implementer' "flow Fix loops"
  holds "${line%%Any other \`Ship allowed: no\`*}" "$marker" "flow Fix loops before the catch-all"
}
