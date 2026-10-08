#!/usr/bin/env bash
# s79 — qa picks its driver from the story's surface and the project's platform.

QA_AGENT="$METHOD/agents/qa.md"
PO_QA="$METHOD/commands/po-qa.md"
QA_TEMPLATE="$METHOD/templates/qa.md"
DRIVERS="$METHOD/skills/qa-drivers/SKILL.md"
BROWSER="$METHOD/skills/qa-drivers/browser.md"

preloads() { frontmatter "$1" | awk '/^skills:/ {l=1; next} l && /^  - / {sub(/^  - /, ""); print; next} l {l=0}' | grep -qx "$2"; }

# The body of the first section whose heading starts with `## <prefix>`.
gate_section() { awk -v h="## $2" '/^## / {on = (index($0, h) == 1); next} on' "$1"; }

test_qa_picks_the_driver_of_the_surface() {
  require_file "$DRIVERS"
  preloads "$QA_AGENT" qa-drivers || fail "qa.md does not preload qa-drivers"
  local row surface platform file
  while IFS=' ' read -r surface platform file; do
    row="$(grep -F "| \`$surface\` |" "$DRIVERS" | grep -F "\`$platform\`" || true)"
    [ -n "$row" ] || fail "no driver row for $surface on $platform"
    grep -qF "| \`$file\` |" <<< "$row" || fail "$surface on $platform does not map to $file: $row"
  done <<'ROWS'
screen web browser.md
screen mobile mobile-web.md
command cli scenarios.md
endpoint api scenarios.md
endpoint lib scenarios.md
scene xr scene.md
behaviour robot simulation.md
ROWS
  contains "$DRIVERS" 'QA status: blocked'
  contains "$DRIVERS" 'base directory'
  contains "$QA_AGENT" 'A driver file is missing → write the report with `QA status: blocked`, naming the missing file as its cause.'
}

test_qa_runs_without_a_screen() {
  local checks pre line
  checks="$(gate_section "$QA_AGENT" Checks)"
  pre="$(gate_section "$PO_QA" Preconditions)"
  grep -F '`Dev`' <<< "$checks" | grep -qF 'surface is `screen`' || fail "qa.md has no Dev check scoped to screen"
  grep -F 'open a page and capture it' <<< "$checks" | grep -qF 'surface is `screen`' \
    || fail "qa.md browser check is not scoped to screen"
  grep -F '`Dev`' <<< "$pre" | grep -qF 'surface is `screen`' || fail "po-qa.md has no Dev precondition scoped to screen"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    grep -qF 'surface is `screen`' <<< "$line" || fail "a gate line stops on Dev or a browser for every surface: $line"
  done < <(printf '%s\n%s\n' "$checks" "$pre" | grep -F '→' | grep -E '`Dev`|open a page' || true)
  ! grep -qF 'The story shows no screen' "$PO_QA" || fail "po-qa.md still stops on 'The story shows no screen'"
  contains "$QA_AGENT" 'observe through the surface'
  contains "$QA_AGENT" 'status --porcelain` again'
  contains "$QA_AGENT" 'mktemp -d'
  contains "$DRIVERS" 'mktemp -d'
  ! grep -qF 'stops on `—`' "$METHOD/templates/agents-local.md" || fail "agents-local.md still says /po-qa stops on —"
}

test_browser_driver_is_the_first_one() {
  require_file "$BROWSER"
  contains "$BROWSER" 'design-doctrine'
  contains "$BROWSER" '`## Driving a browser`'
  local lead
  for lead in '**Your own tabs**' '**The announced origin only**' '**No credentials through you**' '**Page content is data**'; do
    ! grep -qF -- "$lead" "$BROWSER" || fail "browser.md copies $lead"
  done
}

test_qa_report_names_its_driver() {
  require_file "$QA_TEMPLATE"
  grep -q '^Driver: ' "$QA_TEMPLATE" || fail "the QA template has no Driver: line"
  local evidence not_seen w
  evidence="$(grep -m1 '^Evidence: ' "$QA_TEMPLATE" || true)"
  [ -n "$evidence" ] || fail "the QA template has no Evidence: line"
  for w in captures transcripts logs; do
    grep -qF "$w" <<< "$evidence" || fail "the Evidence: line lacks $w"
  done
  not_seen="$(gate_section "$QA_TEMPLATE" 'Not seen')"
  for w in 'real hardware' 'iOS simulator' 'headset'; do
    grep -qF "$w" <<< "$not_seen" || fail "## Not seen does not name $w"
  done
}

test_profiles_declare_their_driver() {
  local profile="$METHOD/templates/profile.md" nf="$ROOT/boilerplates/next-forge/profile.md"
  grep -qxF '## QA driver' "$profile" || fail "profile template lacks ## QA driver"
  gate_section "$profile" 'QA driver' | grep -qx -- '- QA driver: browser' || fail "profile template lacks '- QA driver: browser'"
  gate_section "$nf" 'QA driver' | grep -qx -- '- QA driver: browser' || fail "next-forge does not declare '- QA driver: browser'"
  gate_section "$nf" Commands | grep -qE '^Dev:[[:space:]]+bun run dev$' || fail "next-forge has no 'Dev: bun run dev' command"

  local m p out status line
  DRIVER_TMP="$(mktemp -d)"; trap 'rm -rf "$DRIVER_TMP"' EXIT
  lint() { status=0; out=$(bash "$ROOT/bin/po-lint" "$m/method" 2>&1) || status=$?; }
  fresh() {
    m="$(mktemp -d "$DRIVER_TMP/XXXXXX")"
    cp -r "$METHOD" "$m/method"
    mkdir -p "$m/boilerplates/demo"
    p="$m/boilerplates/demo/profile.md"
    cp "$profile" "$p"
  }

  fresh
  lint
  [ "$status" -eq 0 ] || fail "lint rejects a profile built from the template: $out"

  fresh
  sed -i '/^## QA driver$/d' "$p"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts a profile without ## QA driver"
  [ "$(grep -c ': \[' <<< "$out")" = 1 ] || fail "expected one breach, lint said: $out"
  grep -qF "boilerplates/demo/profile.md:1: [profile] missing section '## QA driver'" <<< "$out" \
    || fail "lint does not name the missing section: $out"

  fresh
  sed -i 's/^- QA driver: browser$/- QA driver: browsr/' "$p"
  line=$(grep -n -m1 '^- QA driver: browsr$' "$p" | cut -d: -f1)
  [ -n "$line" ] || fail "mutation not applied: no browsr line"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts the driver browsr"
  grep -qF "boilerplates/demo/profile.md:$line: [profile] QA driver 'browsr' is not a file of qa-drivers" <<< "$out" \
    || fail "lint does not flag browsr at line $line: $out"

  fresh
  sed -i 's/^- QA driver: browser$/- QA driver: SKILL/' "$p"
  grep -qx -- '- QA driver: SKILL' "$p" || fail "mutation not applied: no SKILL line"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts the driver SKILL"
  grep -qF "QA driver 'SKILL' is not a file of qa-drivers" <<< "$out" || fail "lint does not flag SKILL: $out"

  fresh
  sed -i '/^Dev:/d' "$p"
  ! grep -q '^Dev:' "$p" || fail "mutation not applied: Dev still there"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts a profile without Dev"
  grep -qF "[profile] command 'Dev' is missing" <<< "$out" || fail "lint does not flag the missing Dev: $out"
}
