#!/usr/bin/env bash
# Oracle of s221-bricks-name-no-host, written by the planner before any code.

# A line of the brick notes or of the capability-bricks skill may name the example host only to send
# the reader to its reference file; any other mention describes one setup as if it were Polype's.
test_no_host_in_bricks() {
  local files=("$ROOT"/boilerplates/bricks/*.md "$METHOD/skills/capability-bricks/SKILL.md") f bad
  [ -f "${files[0]}" ] || fail "no brick note under boilerplates/bricks/"
  require_file "$METHOD/skills/capability-bricks/SKILL.md"
  for f in "${files[@]}"; do
    bad="$(grep -in 'mustelinet' "$f" | grep -v 'references/mustelinet\.md' || true)"
    [ -z "$bad" ] || fail "${f#"$ROOT"/} names the host outside a link to its reference: $(head -n1 <<< "$bad")"
  done
}
