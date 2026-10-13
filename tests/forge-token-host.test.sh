#!/usr/bin/env bash
# s107 — a forge token only goes to the host that issued it.

SHIP="$METHOD/commands/po-ship.md"

section_of() { awk -v h="## $2" '$0 == h {on=1; next} /^## / {on=0} on' "$1"; }

holds() { grep -qF -- "$2" <<< "$1" || fail "$3 lacks: $2"; }

forge_section() { section_of "$SHIP" "The forge's review rule"; }

test_env_token_only_for_github() {
  local s; s=$(forge_section)
  holds "$s" '`GH_TOKEN` or `GITHUB_TOKEN`' "forge section"
  holds "$s" 'https://api.github.com' "forge section"
  local line var all scrubbed
  while IFS= read -r line; do
    for var in GITLAB_TOKEN GITEA_TOKEN; do
      grep -qF "$var" <<< "$line" && fail "a curl line cites $var"
    done
  done < <(grep -F 'curl' <<< "$s")
  for var in GITLAB_TOKEN GITEA_TOKEN; do
    all=$(grep -o "$var" <<< "$s" | wc -l)
    scrubbed=$(grep -o -- "-u $var" <<< "$s" | wc -l)
    [ "$all" -eq "$scrubbed" ] || fail "$var is named other than to be removed"
  done
}

test_other_forges_through_their_cli_only() {
  local s; s=$(forge_section)
  holds "$s" 'env -u GITLAB_TOKEN -u GITLAB_ACCESS_TOKEN -u OAUTH_TOKEN glab api --hostname' "forge section"
  holds "$s" 'env -u GITEA_TOKEN -u TEA_HOST -u GITEA_INSTANCE_URL tea api' "forge section"
  holds "$s" 'No `glab` or `tea` login for the host of `origin` → the forge is unreadable' "forge section"
}

test_unknown_host_gets_no_token() {
  local s; s=$(forge_section)
  holds "$s" 'The probe carries no token' "forge section"
  holds "$s" 'No call to an unrecognised host carries a token' "forge section"
}
