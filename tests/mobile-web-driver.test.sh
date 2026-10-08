#!/usr/bin/env bash
# s82 — the mobile web driver checks a phone screen through the web render, and the doctrine gives the mobile rules.

DRIVER="$METHOD/skills/qa-drivers/mobile-web.md"
DOCTRINE="$METHOD/skills/design-doctrine/SKILL.md"

section_of() { awk -v h="$2" '/^## / {on = ($0 == h)} on' "$1"; }

test_mobile_web_driver_sets_a_phone_viewport() {
  require_file "$DRIVER"
  local h
  for h in '## Needs' '## Start and stop' '## Exercising a criterion' '## Evidence' '## Cannot show'; do
    grep -qxF -- "$h" "$DRIVER" || fail "mobile-web.md lacks the section: $h"
  done
  contains "$DRIVER" '`Dev`'
  contains "$DRIVER" 'sets its viewport width and height'
  contains "$DRIVER" 'in portrait'
  contains "$DRIVER" 'at 360 and at 412 CSS pixels wide'
  contains "$DRIVER" 'One capture per state and per width'
  contains "$DRIVER" '-360.png'
  contains "$DRIVER" '-412.png'
  contains "$DRIVER" 'docs/qa/<id>/'
  contains "$DRIVER" 'the `## Driving a browser` section of the preloaded `design-doctrine` skill'
  contains "$DRIVER" 'cannot set their size → the QA ends with `QA status: blocked`'
  contains "$DRIVER" 'never emulate a phone width by zooming'
  contains "$DRIVER" 'ADR-0060'
}

test_mobile_rules_are_in_the_doctrine() {
  require_file "$DOCTRINE"
  grep -qxF '## Mobile screens' "$DOCTRINE" || fail "design-doctrine has no ## Mobile screens section"
  local section lead phrase n
  section="$(section_of "$DOCTRINE" '## Mobile screens')"
  for phrase in '44 by 44 points' '44 by 44 CSS pixels' 'notch' 'gesture bar' 'active field' 'reachable only by hovering'; do
    grep -qF -- "$phrase" <<< "$section" || fail "the mobile section does not say: $phrase"
  done
  for lead in '**Touch targets**' '**Safe areas**' '**The keyboard**' '**No hover**'; do
    grep -qF -- "$lead" <<< "$section" || fail "the mobile section lacks $lead"
    n="$(grep -rlF -- "$lead" "$METHOD" | grep -c '')"
    [ "$n" -eq 1 ] || fail "$lead is written in $n files of method/, not one"
  done
  contains "$DRIVER" 'the `## Mobile screens` section of `design-doctrine`'
}

test_native_only_behaviour_is_named() {
  require_file "$DRIVER"
  local section item
  section="$(section_of "$DRIVER" '## Cannot show')"
  for item in 'native permission prompts' 'notifications' 'the camera' 'system gestures'; do
    grep -qF -- "$item" <<< "$section" || fail "## Cannot show of mobile-web.md does not name: $item"
  done
  grep -qF 'under `## Not seen`, one standing line' <<< "$section" || fail "no standing ## Not seen line"
  grep -qF 'one more line per criterion in scope that relies on one of these items' <<< "$section" || fail "no per-criterion line"
  grep -qF 'never reports one of them as seen' <<< "$section" || fail "the driver may report native behaviour as seen"
}
