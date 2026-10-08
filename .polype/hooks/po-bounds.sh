#!/usr/bin/env bash
# po-bounds — a Claude Code PreToolUse hook that keeps a subagent inside its story's bounds.
#
#   po-bounds.sh implementer   reads the hook input (JSON) on stdin.
#                              Write/Edit: the path must lie in docs/ or in the Owns of the story
#                              whose linked story/<id> worktree holds it, read in docs/stories.md at
#                              the story's fork point (ADR-0038); entries follow the syntax of the
#                              stories template, anything else is refused.
#                              Bash: no git switch, checkout, stash, push or worktree add, and no
#                              git commit outside a story/<id> worktree.
#   po-bounds.sh qa            Write: the path must lie in docs/qa/<id>/ of the story whose linked
#                              story/<id> worktree holds it; the rest of docs/ is refused too.
#                              Bash: every git call must use a reading verb of an allowlist
#                              (ADR-0026); an unknown verb, or none, is refused. Edit is refused.
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

# Sets BASE and BASE_FROM: the commit story/<id> in worktree $1 forked from, i.e. its merge base with
# the main worktree's branch and that branch's upstream (ADR-0038); or denies.
story_base() {
  local list first up
  local -a refs=()
  list="$(git -C "$1" worktree list --porcelain 2>/dev/null)" || list=""
  first="$(awk '
    NF == 0 { exit }
    $1 == "detached" || $1 == "bare" { print $1; exit }
    /^branch refs\/heads\// { sub(/^branch refs\/heads\//, ""); print "branch " $0; exit }
  ' <<< "$list")"
  case "$first" in
    "branch "?*) BASE_FROM="${first#branch }" ;;
    detached|bare) deny "cannot find the branch story $STORY started from: the main worktree is $first" ;;
    *) deny "cannot find the branch story $STORY started from: the main worktree is on no branch" ;;
  esac
  refs=("refs/heads/$BASE_FROM")
  # Not refs/heads/<b>@{upstream}: git does not resolve that form.
  up="$(git -C "$1" for-each-ref --format='%(upstream)' "refs/heads/$BASE_FROM" 2>/dev/null)" || up=""
  if [ -n "$up" ] && git -C "$1" rev-parse --verify -q "$up^{commit}" >/dev/null 2>&1; then
    refs+=("$up")
  fi
  BASE="$(git -C "$1" merge-base HEAD "${refs[@]}" 2>/dev/null)" && [ -n "$BASE" ] \
    || deny "story/$STORY shares no commit with $BASE_FROM, the branch of the main worktree"
}

# Sets OWNS_LINE to the Owns line of story $2 in docs/stories.md as committed at the story's fork
# point, so that a commit of the story cannot widen its own bounds, and OWNS_AT to that place; or denies.
owns_line() {
  local stories line short
  story_base "$1"
  short="$(git -C "$1" rev-parse --short "$BASE" 2>/dev/null)" || short="$BASE"
  OWNS_AT="at $short (where story/$2 started from $BASE_FROM)"
  stories="$(git -C "$1" show "$BASE:docs/stories.md" 2>/dev/null)" || deny "no committed docs/stories.md $OWNS_AT"
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
    FOUND) deny "story $2 has no **Owns** line in docs/stories.md $OWNS_AT" ;;
    *) deny "story $2 is not in docs/stories.md $OWNS_AT" ;;
  esac
  line="${line%$'\n'FOUND}"
  OWNS_LINE="${line#OWNS }"
}

check_write() {
  local path="$1" line rel entry allowed=no
  resolve_path "$path"
  story_of_dir "$path is not inside a story worktree (a linked worktree on a story/<id> branch)" "$NEAREST"
  case "$RESOLVED" in "$TOP"/*) ;; *) deny "$path is not inside a file of worktree $TOP" ;; esac
  rel="${RESOLVED#"$TOP"/}"
  case "$rel" in docs/*) exit 0 ;; esac
  owns_line "$TOP" "$STORY"
  line="$OWNS_LINE"
  parse_owns "$line"
  [ "${#OWNS[@]}" -gt 0 ] || deny "the **Owns** line of $STORY lists no path: $line"
  # Every entry is checked before any match: one unreadable entry refuses the whole line.
  for entry in "${OWNS[@]}"; do check_entry "$entry" "$line"; done
  for entry in "${OWNS[@]}"; do
    if entry_matches "$entry" "$rel"; then allowed=yes; break; fi
  done
  [ "$allowed" = yes ] || deny "$RESOLVED is outside the Owns of $STORY read $OWNS_AT — $line"
  exit 0
}

unreadable() { deny "the **Owns** line of $STORY holds an entry po-bounds cannot read: $1 — $2"; }

# Sets OWNS to the backticked entries of Owns line $1: entries separated by commas, nothing else.
parse_owns() {
  local line="$1" rest entry
  OWNS=()
  rest="${line#*'**Owns**'}"
  rest="${rest#"${rest%%[![:space:]]*}"}"
  rest="${rest#:}"
  rest="${rest#"${rest%%[![:space:]]*}"}"
  [ -n "$rest" ] || return 0
  while :; do
    case "$rest" in '`'*'`'*) ;; *) unreadable "$rest" "$line" ;; esac
    rest="${rest#\`}"
    entry="${rest%%\`*}"
    rest="${rest#*\`}"
    OWNS+=("$entry")
    rest="${rest#"${rest%%[![:space:]]*}"}"
    [ -n "$rest" ] || return 0
    case "$rest" in ,*) rest="${rest#,}" ;; *) unreadable "$rest" "$line" ;; esac
    rest="${rest#"${rest%%[![:space:]]*}"}"
    [ -n "$rest" ] || unreadable "a comma followed by no entry" "$line"
  done
}

# Refuses entry $1 unless it is a relative path, a folder ending in /, or a * / ** glob (ADR-0038).
check_entry() {
  local e="$1" line="$2" s seg
  case "$e" in
    '') unreadable '`` (empty)' "$line" ;;
    /*) unreadable "\`$e\` (absolute)" "$line" ;;
    *[[:space:]]*|*'?'*|*'['*|*']'*|*'{'*|*'}'*) unreadable "\`$e\` (whitespace, ?, [, ], { or })" "$line" ;;
  esac
  s="${e%/}/"
  while [ -n "$s" ]; do
    seg="${s%%/*}"
    s="${s#*/}"
    case "$seg" in
      ''|.|..) unreadable "\`$e\` (an empty, . or .. segment)" "$line" ;;
      '**') ;;
      *'**'*) unreadable "\`$e\` (** must be a whole segment)" "$line" ;;
    esac
  done
}

# Whether relative path $2 lies in entry $1. A glob becomes an anchored ERE built segment by segment.
entry_matches() {
  local e="$1" rel="$2" body s seg re="" i c
  case "$e" in
    *'*'*) ;;
    */) [ "$rel" = "${e%/}" ] || [[ "$rel" == "${e%/}"/* ]]; return ;;
    *) [ "$rel" = "$e" ]; return ;;
  esac
  body="${e%/}"
  s="$body/"
  while [ -n "$s" ]; do
    seg="${s%%/*}"
    s="${s#*/}"
    if [ "$seg" = '**' ]; then
      if [ -n "$s" ]; then re+='([^/]+/)*'; else re+='.*'; fi
      continue
    fi
    for ((i = 0; i < ${#seg}; i++)); do
      c="${seg:i:1}"
      case "$c" in
        '*') re+='[^/]*' ;;
        .|+|'('|')'|'|'|'^'|'$'|'\') re+="\\$c" ;;
        *) re+="$c" ;;
      esac
    done
    [ -z "$s" ] || re+='/'
  done
  [ "$body" = "$e" ] || re+='/.+'
  re="^$re\$"
  [[ $rel =~ $re ]]
}

# Not check_write: its docs/ shortcut belongs to the implementer.
check_write_qa() {
  local path="$1" rel
  resolve_path "$path"
  story_of_dir "$path is not inside a story worktree (a linked worktree on a story/<id> branch)" "$NEAREST"
  case "$RESOLVED" in "$TOP"/*) ;; *) deny "$path is not inside a file of worktree $TOP" ;; esac
  rel="${RESOLVED#"$TOP"/}"
  case "$rel" in "docs/qa/$STORY/"?*) exit 0 ;; esac
  deny "$RESOLVED is outside docs/qa/$STORY/, the only folder mode qa writes to"
}

join_dir() { case "$2" in /*) printf '%s' "$2" ;; *) printf '%s' "${1%/}/$2" ;; esac; }

QA_GIT_VERBS=" status diff log show rev-parse ls-files ls-tree cat-file merge-base grep blame describe symbolic-ref shortlog "

check_bash() {
  local cmd="$1" cur="$2" mode="$3" text i j n w verb gdir dir
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
      if [ "$mode" = qa ]; then
        if [ "$verb" = worktree ]; then
          [ "${words[j+1]-}" = list ] || deny "git worktree ${words[j+1]-} is forbidden in mode qa, only worktree list reads: $cmd"
        else
          # An empty verb never matches: the list holds single spaces only.
          case "$QA_GIT_VERBS" in
            *" $verb "*) ;;
            *) deny "git ${verb:-without a verb} is forbidden in mode qa, which runs reading verbs only: $cmd" ;;
          esac
        fi
      else
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
      fi
      i=$j
    fi
    i=$((i + 1))
  done
  exit 0
}

mode="${1-}"
case "$mode" in
  implementer|qa) ;;
  *) deny "unknown mode '${mode}' (expected: implementer or qa)" ;;
esac

command -v jq > /dev/null 2>&1 || deny "jq is required and was not found; every call is refused without it"
# Claude Code hands the input over a socket, which /dev/stdin cannot open; cat reads fd 0 directly.
input="$(cat)"
tool="$(jq -er '.tool_name | strings' <<< "$input" 2>/dev/null)" || deny "unreadable hook input"

case "$mode:$tool" in
  implementer:Write|implementer:Edit)
    path="$(jq -er '.tool_input.file_path | strings' <<< "$input" 2>/dev/null)" || deny "unreadable hook input: no file_path"
    check_write "$path"
    ;;
  qa:Write)
    path="$(jq -er '.tool_input.file_path | strings' <<< "$input" 2>/dev/null)" || deny "unreadable hook input: no file_path"
    check_write_qa "$path"
    ;;
  implementer:Bash|qa:Bash)
    cmd="$(jq -er '.tool_input.command | strings' <<< "$input" 2>/dev/null)" || deny "unreadable hook input: no command"
    cwd="$(jq -r '.cwd // empty | strings' <<< "$input" 2>/dev/null)" || deny "unreadable hook input"
    check_bash "$cmd" "$cwd" "$mode"
    ;;
  *) deny "tool $tool is not allowed in mode $mode" ;;
esac
deny "no decision reached"
