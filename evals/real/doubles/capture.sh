# Sourced by the doubles of a real run: capture_sent <log> <argument…> appends to <log> the text of
# everything the call could send — standard input when it is a pipe or a file, and every file an
# argument names, in any spelling: `-F f`, `-Ff`, `--body-file=f`, `--input=f`, `k=@f`, curl's `k=<f`
# and `k=@f;type=…`, a bare path, `<(…)`. It reads more than a tool would send, never less: a grade that looks for a text in what
# reached the forge sees every way it could have gone. CAPTURE_STDIN then names the file that holds
# standard input, to hand on to the tool the double wraps.

# A pipe no one closes would hold the call: it is read for five seconds at most.
capture_cat() { if command -v timeout > /dev/null; then timeout 5 cat -- "$@"; else cat -- "$@"; fi; }

capture_one() {
  local log="$1" c="$2"
  [ -n "$c" ] && [ "$c" != - ] && [ -e "$c" ] && [ ! -d "$c" ] || return 0
  if [ -f "$c" ]; then { cat -- "$c"; echo; echo ---; } >> "$log" 2>/dev/null
  elif [ -p "$c" ]; then { capture_cat "$c"; echo; echo ---; } >> "$log" 2>/dev/null
  fi
  return 0
}

capture_sent() {
  local log="$1" a rest
  shift
  CAPTURE_STDIN=/dev/null
  if [ ! -t 0 ] && { [ -p /dev/stdin ] || [ -f /dev/stdin ]; }; then
    CAPTURE_STDIN="$(mktemp "${log%/*}/stdin.XXXXXX")"
    capture_cat > "$CAPTURE_STDIN" 2>/dev/null || true
    { cat -- "$CAPTURE_STDIN"; echo; echo ---; } >> "$log"
  fi
  for a in "$@"; do
    capture_one "$log" "$a"
    case "$a" in -[!-]?*) capture_one "$log" "${a:2}" ;; esac
    rest="$a"
    while [[ "$rest" == *[=@\<]* ]]; do
      rest="${rest#*[=@\<]}"
      capture_one "$log" "$rest"
      capture_one "$log" "${rest%%;*}"
    done
  done
}
