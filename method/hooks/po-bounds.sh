#!/usr/bin/env bash
# po-bounds — a Claude Code PreToolUse hook that keeps a subagent inside its story's bounds.
#
#   po-bounds.sh implementer   reads the hook input (JSON) on stdin.
#                              Write/Edit: the path must lie in docs/ or in the committed Owns of the
#                              story whose linked story/<id> worktree holds it.
#                              Bash: no git switch, checkout, stash, push or worktree add, and no
#                              git commit outside a story/<id> worktree.
#
# Exit 0 allows the call, exit 2 refuses it with the reason on stderr. Claude Code lets any other
# code through, so every failure ends in a refusal. Reads no setting; needs jq (ADR-0024).
set -uo pipefail

deny() { echo "po-bounds: $*" >&2; exit 2; }

# An unbound variable or any stray status must not become a non-blocking error.
trap 'rc=$?; [ "$rc" -eq 0 ] || [ "$rc" -eq 2 ] || { echo "po-bounds: internal failure ($rc)" >&2; exit 2; }' EXIT

# Sets TOP and STORY from an existing directory, or denies with "$1".
story_of_dir() {
  local dir="$2" gitdir common branch
  TOP="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || deny "$1"
  gitdir="$(git -C "$dir" rev-parse --absolute-git-dir 2>/dev/null)" || deny "$1"
  common="$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || deny "$1"
  [ "$gitdir" != "$common" ] || deny "$1"
  branch="$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null)" || deny "$1"
  case "$branch" in story/?*) ;; *) deny "$1" ;; esac
  STORY="${branch#story/}"
}

# Sets RESOLVED (physical absolute path, the target may not exist yet) and NEAREST (its deepest
# existing directory). Not realpath -m: macOS lacks it.
resolve_path() {
  local path="$1" dir tail="" base phys
  case "$path" in /*) ;; *) deny "not an absolute path: $path" ;; esac
  [ ! -L "$path" ] || deny "$path is a symbolic link"
  dir="$path"
  while [ ! -d "$dir" ]; do
    base="${dir##*/}"
    case "$base" in .|..) deny "$path holds a . or .. component that does not exist yet" ;; esac
    [ -z "$base" ] || tail="/$base$tail"
    dir="$(dirname "$dir")"
  done
  phys="$(cd -P "$dir" 2>/dev/null && pwd -P)" || deny "cannot resolve $path"
  NEAREST="$phys"
  RESOLVED="${phys%/}$tail"
  [ -z "$tail" ] || [ ! -L "$RESOLVED" ] || deny "$path is a symbolic link"
}

# Sets OWNS_LINE to the Owns line of story $2 in the committed docs/stories.md of worktree $1, or denies.
owns_line() {
  local stories line
  stories="$(git -C "$1" show HEAD:docs/stories.md 2>/dev/null)" || deny "no committed docs/stories.md in $1"
  line="$(awk -v id="$2" '
    /^#/ {
      if (on) exit
      h = $0
      if (h ~ /^#+ /) { sub(/^#+ /, "", h); if (h == id || index(h, id " ") == 1) { on = 1; found = 1 } }
      next
    }
    on && /^[-*] \*\*Owns\*\*[[:space:]]*:/ { print "OWNS " $0; exit }
    END { if (found) print "FOUND" }
  ' <<< "$stories")"
  case "$line" in
    "OWNS "*) ;;
    FOUND) deny "story $2 has no **Owns** line in the committed docs/stories.md" ;;
    *) deny "story $2 is not in the committed docs/stories.md" ;;
  esac
  line="${line%$'\n'FOUND}"
  OWNS_LINE="${line#OWNS }"
}

check_write() {
  local path="$1" line rel entry allowed=no
  local -a owns=()
  resolve_path "$path"
  story_of_dir "$path is not inside a story worktree (a linked worktree on a story/<id> branch)" "$NEAREST"
  case "$RESOLVED" in "$TOP"/*) ;; *) deny "$path is not inside a file of worktree $TOP" ;; esac
  rel="${RESOLVED#"$TOP"/}"
  case "$rel" in docs/*) exit 0 ;; esac
  owns_line "$TOP" "$STORY"
  line="$OWNS_LINE"
  while IFS= read -r entry; do
    entry="${entry//\`/}"
    [ -n "$entry" ] && owns+=("$entry")
  done < <(grep -o '`[^`]*`' <<< "$line")
  [ "${#owns[@]}" -gt 0 ] || deny "the **Owns** line of $STORY lists no path: $line"
  for entry in "${owns[@]}"; do
    entry="${entry%/}"
    if [ "$rel" = "$entry" ] || [[ "$rel" == "$entry"/* ]]; then allowed=yes; break; fi
  done
  [ "$allowed" = yes ] || deny "$RESOLVED is outside the Owns of $STORY — $line"
  exit 0
}

join_dir() { case "$2" in /*) printf '%s' "$2" ;; *) printf '%s' "${1%/}/$2" ;; esac; }

check_bash() {
  local cmd="$1" cur="$2" text i j n w verb gdir dir
  local -a words=()
  text="${cmd//[\'\"\\]/}"
  text="${text//\$(/ }"
  text="${text//[;&|()\`\{\}]/ }"
  text="${text//[$'\n\r\t']/ }"
  read -ra words <<< "$text"
  n=${#words[@]}
  i=0
  while [ "$i" -lt "$n" ]; do
    w="${words[i]}"
    if [ "$w" = cd ] && [ $((i + 1)) -lt "$n" ]; then
      cur="$(join_dir "$cur" "${words[i+1]}")"
      i=$((i + 2)); continue
    fi
    if [ "$w" = git ] || [[ "$w" == */git ]]; then
      j=$((i + 1)); gdir=""
      while [ "$j" -lt "$n" ]; do
        case "${words[j]}" in
          -C) gdir="${words[j+1]-}"; j=$((j + 2)) ;;
          -c|--git-dir|--work-tree|--namespace) j=$((j + 2)) ;;
          -*) j=$((j + 1)) ;;
          *) break ;;
        esac
      done
      verb="${words[j]-}"
      case "$verb" in
        switch|checkout|stash|push) deny "git $verb is forbidden to the implementer: $cmd" ;;
        worktree) [ "${words[j+1]-}" != add ] || deny "git worktree add is forbidden to the implementer: $cmd" ;;
        commit)
          dir="$cur"
          [ -z "$gdir" ] || dir="$(join_dir "$cur" "$gdir")"
          [ -n "$dir" ] && [ -d "$dir" ] || deny "git commit outside a story/<id> branch: $cmd"
          story_of_dir "git commit outside a story/<id> branch: $cmd" "$dir"
          ;;
      esac
      i=$j
    fi
    i=$((i + 1))
  done
  exit 0
}

mode="${1-}"
case "$mode" in
  implementer) ;;
  *) deny "unknown mode '${mode}' (expected: implementer)" ;;
esac

command -v jq > /dev/null 2>&1 || deny "jq is required and was not found; every call is refused without it"
input="$(< /dev/stdin)"
tool="$(jq -er '.tool_name | strings' <<< "$input" 2>/dev/null)" || deny "unreadable hook input"

case "$mode:$tool" in
  implementer:Write|implementer:Edit)
    path="$(jq -er '.tool_input.file_path | strings' <<< "$input" 2>/dev/null)" || deny "unreadable hook input: no file_path"
    check_write "$path"
    ;;
  implementer:Bash)
    cmd="$(jq -er '.tool_input.command | strings' <<< "$input" 2>/dev/null)" || deny "unreadable hook input: no command"
    cwd="$(jq -r '.cwd // empty | strings' <<< "$input" 2>/dev/null)" || deny "unreadable hook input"
    check_bash "$cmd" "$cwd"
    ;;
  *) deny "tool $tool is not allowed in mode $mode" ;;
esac
deny "no decision reached"
