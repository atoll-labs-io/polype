#!/usr/bin/env bash
# s43 — mustelinet brick notes: one per deployable default brick, host gaps, contract checklists, no code.

BRICKS="$ROOT/boilerplates/bricks"
SKILL="$METHOD/skills/capability-bricks/SKILL.md"
NOTES="postgres garage jobs email observability deployment"

capability_of_note() {
  case "$1" in
    postgres) echo Database ;; garage) echo Files ;; jobs) echo Jobs ;;
    email) echo Email ;; observability) echo Observability ;; deployment) echo Deployment ;;
  esac
}

# The body of one `## <heading>` section of a file, heading excluded.
section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

skill_capabilities() {
  section_of "$SKILL" 'Default bricks' | awk -F'|' '/^\|/ {c=$2; gsub(/^[ \t]+|[ \t]+$/, "", c); if (c == "Capability" || c ~ /^:?-+:?$/) next; print c}'
}

# One line per breach of the note shape of the s43 plan.
brick_note_breaches() {
  local f="$1" cap sec body gaps list
  head -1 "$f" | grep -q '^# Brick — .* (.*)$' || echo "title is not '# Brick — <brick> (<capability>)'"
  cap=$(grep -m1 '^- Capability: ' "$f" | sed 's/^- Capability: //')
  if [ -z "$cap" ]; then
    echo "no '- Capability:' line"
  elif ! skill_capabilities | grep -qxF -- "$cap"; then
    echo "capability '$cap' is not in the skill's Default bricks table"
  fi
  grep -q '^- Default brick (ADR-0020): .' "$f" || echo "no '- Default brick (ADR-0020):' line"
  grep -qxF -- '- Status: documentation only — this note describes a deployment and its contracts; it ships no code.' "$f" \
    || echo "no '- Status: documentation only' line"
  for sec in 'What it provides' 'How it runs at mustelinet' 'Settings' 'Backups' \
      'What mustelinet does not provide' 'Contract test checklist'; do
    if ! grep -qxF -- "## $sec" "$f"; then
      echo "missing section '## $sec'"
    else
      body=$(section_of "$f" "$sec")
      grep -q '[^[:space:]]' <<< "$body" || echo "empty section '## $sec'"
    fi
  done
  list=$(grep '^## ' "$f" | tr '\n' '|')
  [ "$list" = '## What it provides|## How it runs at mustelinet|## Settings|## Backups|## What mustelinet does not provide|## Contract test checklist|' ] \
    || echo "sections out of order: $list"
  section_of "$f" Settings | grep -qF 'not `AGENTS.local.md` settings' || echo "## Settings does not say these are not AGENTS.local.md settings"
  gaps=$(section_of "$f" 'What mustelinet does not provide')
  for gap in '- No managed database' '- No managed object storage' '- Publication over HTTP and HTTPS only'; do
    grep -qF -- "$gap — so " <<< "$gaps" || echo "missing host gap: $gap — so …"
  done
  body=$(section_of "$f" 'Contract test checklist')
  grep -qxF -- "Every brick of this capability must pass these; the list adds mustelinet's constraints to the contract of the capability-bricks skill." <<< "$body" \
    || echo "no checklist intro sentence"
  for item in Nominal Refusal 'Data effect' Mustelinet; do
    grep -q -- "^- \[ \] $item: ." <<< "$body" || echo "no checklist item '- [ ] $item:'"
  done
  if grep -q '^```' "$f"; then echo "fenced code block"; fi
}

note_breaches_all() {
  local n
  for n in $NOTES; do
    require_file "$BRICKS/$n.md"
    brick_note_breaches "$BRICKS/$n.md" | sed "s|^|$n.md: |"
  done
}

test_each_default_brick_has_a_note() {
  local n cap breaches tmp
  for n in $NOTES; do
    require_file "$BRICKS/$n.md"
    cap=$(capability_of_note "$n")
    grep -qxF -- "- Capability: $cap" "$BRICKS/$n.md" || fail "$n.md does not name capability $cap"
    skill_capabilities | grep -qxF -- "$cap" || fail "$cap is not a capability of the skill"
  done
  breaches=$(note_breaches_all)
  [ -z "$breaches" ] || fail "notes breach their shape: $breaches"
  section_of "$BRICKS/postgres.md" Backups | grep -qF pg_dump || fail "postgres.md Backups does not name pg_dump"
  contains "$ROOT/docs/catalogue.md" 'boilerplates/bricks/'

  tmp=$(mktemp -d); trap "rm -rf '$tmp'" EXIT
  awk '/^## Backups$/ {skip=1; next} /^## / {skip=0} !skip' "$BRICKS/postgres.md" > "$tmp/postgres.md"
  grep -qxF '## Backups' "$tmp/postgres.md" && fail "the mutant was not built"
  brick_note_breaches "$tmp/postgres.md" | grep -qF "missing section '## Backups'" \
    || fail "a note without ## Backups went unnoticed"
}

test_notes_state_what_mustelinet_does_not_provide() {
  local n gaps gap tmp
  for n in $NOTES; do
    require_file "$BRICKS/$n.md"
    gaps=$(section_of "$BRICKS/$n.md" 'What mustelinet does not provide')
    for gap in '- No managed database — so ' '- No managed object storage — so ' '- Publication over HTTP and HTTPS only — so '; do
      grep -qF -- "$gap" <<< "$gaps" || fail "$n.md does not state: $gap"
    done
  done

  tmp=$(mktemp -d); trap "rm -rf '$tmp'" EXIT
  grep -v '^- No managed object storage' "$BRICKS/garage.md" > "$tmp/garage.md"
  brick_note_breaches "$tmp/garage.md" | grep -qF 'missing host gap: - No managed object storage' \
    || fail "a note without the object storage gap went unnoticed"
}

test_notes_give_a_contract_test_checklist() {
  local n body item tmp
  for n in $NOTES; do
    require_file "$BRICKS/$n.md"
    body=$(section_of "$BRICKS/$n.md" 'Contract test checklist')
    grep -qF -- "the list adds mustelinet's constraints to the contract of the capability-bricks skill." <<< "$body" \
      || fail "$n.md has no checklist intro"
    for item in Nominal Refusal 'Data effect' Mustelinet; do
      grep -q -- "^- \[ \] $item: ." <<< "$body" || fail "$n.md has no '- [ ] $item:' item"
    done
  done

  tmp=$(mktemp -d); trap "rm -rf '$tmp'" EXIT
  grep -v '^- \[ \] Refusal:' "$BRICKS/email.md" > "$tmp/email.md"
  brick_note_breaches "$tmp/email.md" | grep -qF "no checklist item '- [ ] Refusal:'" \
    || fail "a checklist without its Refusal item went unnoticed"
}

test_bricks_are_documentation_not_code() {
  local n others tmp
  [ -d "$BRICKS" ] || fail "missing folder: boilerplates/bricks/"
  others=$(find "$BRICKS" -mindepth 1 \( -type d -o \! -name '*.md' \) -print)
  [ -z "$others" ] || fail "boilerplates/bricks/ holds more than markdown notes: $others"
  [ ! -e "$BRICKS/profile.md" ] || fail "boilerplates/bricks/ must not hold a profile.md"
  for n in $NOTES; do
    require_file "$BRICKS/$n.md"
    contains "$BRICKS/$n.md" '- Status: documentation only — this note describes a deployment and its contracts; it ships no code.'
    ! grep -q '^```' "$BRICKS/$n.md" || fail "$n.md holds a fenced code block"
  done

  tmp=$(mktemp -d); trap "rm -rf '$tmp'" EXIT
  { cat "$BRICKS/deployment.md"; printf '\n```yaml\nkind: Deployment\n```\n'; } > "$tmp/deployment.md"
  brick_note_breaches "$tmp/deployment.md" | grep -qxF 'fenced code block' \
    || fail "a fenced block in a note went unnoticed"
}
