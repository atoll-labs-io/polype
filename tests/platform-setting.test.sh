#!/usr/bin/env bash
# s78 — the project declares its platforms, each profile its own, each story its surface.

SETTINGS="$METHOD/templates/agents-local.md"
PROFILE="$METHOD/templates/profile.md"
SETUP="$METHOD/commands/po-setup.md"
STORIES_T="$METHOD/templates/stories.md"
AGENTIC="$METHOD/skills/agentic-stories/SKILL.md"
SREVIEW="$METHOD/skills/stories-review/SKILL.md"

test_platform_is_a_setting() {
  template_settings | grep -qx 'Platform' || fail "Platform is not a template setting"
  local row values
  row=$(grep -m1 '^| Platform |' "$SETTINGS") || fail "no Platform row in the values table"
  # po-lint reads exactly these words from the row, so any other one would widen the list.
  values=$(grep -o '`[a-z][a-z]*`' <<< "$row" | tr -d '`' | tr '\n' ' ')
  [ "$values" = "web mobile cli api lib xr robot " ] || fail "Platform row values are '$values'"
  row=$(grep -m1 '^| QA stage |' "$SETTINGS")
  local v
  for v in '`screens`' '`surfaces`' '`—`'; do
    grep -qF -- "$v" <<< "$row" || fail "QA stage row lacks $v"
  done
  contains "$SETTINGS" "or whatever serves what a person looks at"
  contains "$SETTINGS" "\`—\` when the project has nothing to serve"
}

test_profiles_declare_their_platform() {
  grep -qxF '## Platform' "$PROFILE" || fail "profile template lacks ## Platform"
  grep -qx -- '- Platform: .*' "$PROFILE" || fail "profile template lacks a '- Platform:' line"
  local nf="$ROOT/boilerplates/next-forge/profile.md"
  awk '/^## / {sec = ($0 == "## Platform"); next} sec' "$nf" | grep -qx -- '- Platform: web' \
    || fail "next-forge does not declare '- Platform: web' under ## Platform"

  local m p out status line
  PLATFORM_TMP="$(mktemp -d)"; trap 'rm -rf "$PLATFORM_TMP"' EXIT
  lint() { status=0; out=$(bash "$ROOT/bin/po-lint" "$m/method" 2>&1) || status=$?; }
  fresh() {
    m="$(mktemp -d "$PLATFORM_TMP/XXXXXX")"
    cp -r "$METHOD" "$m/method"
    mkdir -p "$m/boilerplates/demo"
    p="$m/boilerplates/demo/profile.md"
    cp "$PROFILE" "$p"
  }

  fresh
  sed -i '/^## Platform$/d' "$p"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts a profile without ## Platform"
  [ "$(grep -c ': \[' <<< "$out")" = 1 ] || fail "expected one breach, lint said: $out"
  grep -qF "boilerplates/demo/profile.md:1: [profile] missing section '## Platform'" <<< "$out" \
    || fail "lint does not name the missing section: $out"

  fresh
  sed -i 's/^- Platform: web$/- Platform: Web/' "$p"
  line=$(grep -n -m1 '^- Platform: Web$' "$p" | cut -d: -f1)
  [ -n "$line" ] || fail "mutation not applied: no '- Platform: Web' line"
  lint
  [ "$status" -ne 0 ] || fail "lint accepts the platform Web"
  [ "$(grep -c ': \[' <<< "$out")" = 1 ] || fail "expected one breach, lint said: $out"
  grep -qF "boilerplates/demo/profile.md:$line: [profile] platform 'Web' is not a value of the Platform setting" <<< "$out" \
    || fail "lint does not flag Web at line $line: $out"

  fresh
  sed -i 's/^- Platform: web$/- Platform: web, mobile/' "$p"
  grep -qx -- '- Platform: web, mobile' "$p" || fail "mutation not applied: no 'web, mobile' line"
  lint
  [ "$status" -eq 0 ] || fail "lint rejects '- Platform: web, mobile': $out"
}

test_setup_asks_the_platform() {
  local step2
  step2=$(awk '/^## Step 2/ {on=1; next} /^## / {on=0} on' "$SETUP")
  [ "$(grep -cE '^[0-9]+\. ' <<< "$step2")" = 5 ] || fail "step 2 no longer has five numbered questions"
  local plat cat
  plat=$(grep -nE '^[^0-9].*AskUserQuestion call for `Platform`' <<< "$step2" | head -1 | cut -d: -f1)
  cat=$(grep -nF 'offer the catalogue before question 5' <<< "$step2" | head -1 | cut -d: -f1)
  [ -n "$plat" ] || fail "no unnumbered Platform follow-up in step 2"
  [ -n "$cat" ] || fail "no catalogue offer in step 2"
  [ "$plat" -lt "$cat" ] || fail "the Platform follow-up comes after the catalogue offer"
  contains "$SETUP" "whose \`- Platform:\` line names one of the project's platforms"
  contains "$SETUP" "\`cli\`, \`api\`, \`lib\` or \`robot\`"
  grep -E '^[^0-9].*call for `QA stage`' <<< "$step2" | grep -qF '`surfaces`' \
    || fail "the QA stage follow-up does not offer surfaces"
}

test_stories_declare_a_surface() {
  contains "$STORIES_T" "**Surface**"
  local s o
  s=$(grep -n -m1 -F '**Surface**' "$STORIES_T" | cut -d: -f1)
  o=$(grep -n -m1 -F '**Owns**' "$STORIES_T" | cut -d: -f1)
  [ "$o" -eq $((s + 1)) ] || fail "the Owns line does not follow the Surface line"

  grep -qxF '## Surface' "$AGENTIC" || fail "agentic-stories lacks ## Surface"
  local surface
  surface=$(awk '/^## / {on = ($0 == "## Surface"); next} on' "$AGENTIC")
  grep -qF '| Surface | Admitted by the platforms |' <<< "$surface" || fail "no admission table"
  grep -qF '| `command` | `cli` |' <<< "$surface" || fail "command is not admitted by cli"

  local f
  for f in "$METHOD/commands/po-stories.md" "$METHOD/agents/stories-reviewer.md" \
      "$METHOD/commands/po-stories-review.md"; do
    settings_read_by "$f" | grep -qx 'Platform' || fail "${f#"$ROOT"/} does not read Platform"
  done
  contains "$METHOD/commands/po-stories-review.md" "Platform: <value>"

  local c9 sev
  c9=$(awk '/^\*\*9\./ {on=1; print; next} /^## |^\*\*[0-9]+\./ {on=0} on' "$SREVIEW")
  grep -qF 'is a minor finding' <<< "$c9" || fail "check 9 does not rate a missing Surface minor"
  grep -qF 'is major' <<< "$c9" || fail "check 9 does not rate an unadmitted Surface major"
  sev=$(awk '/^## Severity/ {on=1; next} /^## / {on=0} on' "$SREVIEW")
  grep '^- \*\*major\*\*' <<< "$sev" | grep -qF 'Surface' || fail "Severity major does not name Surface"
  grep '^- \*\*minor\*\*' <<< "$sev" | grep -qF 'Surface' || fail "Severity minor does not name Surface"
}

test_polype_declares_its_platform() {
  grep -qx 'Platform:          cli' "$ROOT/AGENTS.local.md" || fail "AGENTS.local.md does not declare Platform: cli"
  local out
  out="$(bash "$ROOT/bin/polype" check "$ROOT" 2>&1 || true)"
  grep -q 'installed in' <<< "$out" || fail "check did not run: $out"
  ! grep -q '^missing setting:' <<< "$out" || fail "$out"
}
