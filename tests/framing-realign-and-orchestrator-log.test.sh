#!/usr/bin/env bash
# s121 — every pr landing realigns the root; the orchestrator logs every kind of lone decision.

SETUP="$METHOD/commands/po-setup.md"
ORCH="$METHOD/commands/po-orchestrator.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

base_block() {
  section_of "$SETUP" 'Landing the framing' |
    awk '/^\*\*Base\.\*\*/ {on=1} /^\*\*The commit, built beside the checkout\*\*/ {on=0} on'
}

offset() { grep -bo -m1 -F -- "$2" <<< "$1" | head -1 | cut -d: -f1; }

test_every_landing_realigns_the_root() {
  require_file "$SETUP"
  local b; b=$(base_block)
  [ -n "$b" ] || fail "po-setup.md has no Base block in its landing section"
  local f m n nm
  f=$(offset "$b" 'git fetch origin')
  m=$(offset "$b" 'git merge --ff-only origin/<Target branch>')
  n=$(offset "$b" 'No `origin/framing/<slug>`')
  nm=$(offset "$b" 'Not merged →')
  [ -n "$f" ] && [ -n "$m" ] && [ -n "$n" ] && [ -n "$nm" ] || fail "Base lost a step of the realignment order"
  [ "$f" -lt "$m" ] && [ "$m" -lt "$n" ] && [ "$n" -lt "$nm" ] || fail "the realignment does not precede the slug-specific decisions"
  holds "$b" 'A refusal is reported' 'Base'
  holds "$b" 'no stash, checkout or reset forces it' 'Base'
  if grep -F -- 'git merge --ff-only origin/<Target branch>' <<< "$b" | grep -qF -- 'framing/<slug>'; then
    fail "the realignment line depends on the slug"
  fi
  local land; land=$(section_of "$SETUP" 'Landing the framing')
  holds "$land" 'is deleted only by the next landing on that same slug' 'the human bullet'
  if grep -qF -- 'the next landing of any framing command realigns the root as **Base** says' <<< "$land"; then
    fail "the human bullet still promises a realignment the command does not make"
  fi
}

test_orchestrator_logs_every_lone_decision() {
  require_file "$ORCH"
  local l; l=$(section_of "$ORCH" 'The decisions log')
  [ -n "$l" ] || fail "po-orchestrator.md has no decisions log section"
  local s
  for s in 'the track it chose at Stage 1' 'each implementation detail it settled without the person' \
    'each answer it gave without asking' 'writes its rows at that moment' 'a `pr` ship never inspects the root' \
    '`Merge mode: local`' '"Not now"' 'staged in the root'; do
    holds "$l" "$s" 'the decisions log'
  done
}
