#!/usr/bin/env bash
# s205 — the oracle of the story: one file, method/word-budget, holds the word ceiling of every .md file of
# method/, of their total and of the four documents the owner listed (d-0055), and bin/po-lint holds it. Each criterion is read by a script; every test below
# runs po-lint or the installer on throwaway trees, never a phrase of method/.
# story_landed comes from s201's helpers, taken unchanged as docs/harnais.md says.
source <(sed '/^test_/,$d' "$ROOT/tests/routing-phrase-tests-retired.oracle.test.sh")

S205_TMP="$(mktemp -d)"
trap 'rm -rf "$S205_TMP"' EXIT

# small_method <dir>: <dir>/method, a tree po-lint reads clean apart from its budget: the two templates its
# other rules read, one command, and a hook, which is code and needs no line.
small_method() {
  local m="$1/method"
  mkdir -p "$m/commands" "$m/agents" "$m/templates" "$m/hooks"
  cp "$METHOD/templates/agents-local.md" "$METHOD/templates/profile.md" "$m/templates/"
  printf -- '---\ndescription: a\n---\n# /po-a\n\nReads settings: none\n\nOne two three four.\n' > "$m/commands/po-a.md"
  printf '#!/usr/bin/env bash\necho a hook is code and holds no ceiling\n' > "$m/hooks/po-x.sh"
  printf '%s' "$m"
}

# A word is a run of characters between blanks, tabs and newlines, counted by awk in the C locale, as po-lint does.
words() { LC_ALL=C awk '{n += NF} END {print n + 0}' < "$1"; }

# write_budget <method> <slack per file> <slack on the total>: one line per .md file at its count plus the
# slack, and the total line.
write_budget() {
  local m="$1" f n total=0
  {
    printf '# a throwaway budget\n'
    while IFS= read -r f; do
      n="$(words "$m/$f")"; total=$((total + n))
      printf '%s %s\n' "$f" "$((n + $2))"
    done < <(cd "$m" && find . -type f -name '*.md' | sed 's|^\./||' | LC_ALL=C sort)
    printf 'total %s\n' "$((total + $3))"
  } > "$m/word-budget"
}

# add_document <method> <path> <words> <slack>: writes <path> beside method/ with <words> words, and lists it
# as ../<path> at its count plus the slack.
add_document() {
  mkdir -p "$(dirname "$1/../$2")"
  yes word | head -n "$3" > "$1/../$2"
  printf '../%s %s\n' "$2" "$(($3 + $4))" >> "$1/word-budget"
}

# as_repository <dir>: makes <dir> the top of a git work tree, the one case where po-lint checks documents.
as_repository() {
  git -C "$1" init -q -b main
  git -C "$1" config user.email test@example.com
  git -C "$1" config user.name test
  git -C "$1" config commit.gpgsign false
}

budget_line() { awk -v k="$2" '$1 == k {print NR; exit}' "$1/word-budget"; }

# set_ceiling <method> <key> <ceiling> [<decision>]: rewrites the line of <key>.
set_ceiling() {
  awk -v k="$2" -v c="$3" -v d="${4:-}" '$1 == k {$0 = k " " c (d == "" ? "" : " " d)} {print}' \
    "$1/word-budget" > "$1/word-budget.next" && mv "$1/word-budget.next" "$1/word-budget"
}
ceiling_of() { awk -v k="$2" '$1 == k {print $2; exit}' "$1/word-budget"; }

lint() { LINT_RC=0; LINT_OUT="$(bash "$ROOT/bin/po-lint" "$@" 2>&1)" || LINT_RC=$?; }

# The lint must refuse, with exactly one breach, of the budget rule, at <where>, naming <what>.
refuses_once() {
  local where="$1" what="$2" why="$3"
  [ "$LINT_RC" -eq 1 ] || fail "$why: po-lint exited $LINT_RC: $LINT_OUT"
  [ "$(grep -c ': \[' <<< "$LINT_OUT")" = 1 ] || fail "$why: expected one breach, po-lint said: $LINT_OUT"
  grep -F -- "$where: [budget]" <<< "$LINT_OUT" | grep -qF -- "$what" \
    || fail "$why: no budget breach at $where naming $what: $LINT_OUT"
}

# The documents outside method/ whose ceiling the owner put in the budget (d-0055).
S205_DOCUMENTS="README.md docs/migration.md docs/parite-killer-saas.md docs/direction.md"

fresh() { small_method "$(mktemp -d "$S205_TMP/XXXXXX")"; }

test_budget_is_one_file() {
  local m
  m="$(fresh)"; write_budget "$m" 0 0
  lint "$m"
  [ "$LINT_RC" -eq 0 ] || fail "po-lint refuses a tree at its budget, a hook without a line: $LINT_OUT"

  m="$(fresh)"; write_budget "$m" 0 10
  printf 'five\n' >> "$m/commands/po-a.md"
  lint "$m"
  refuses_once "word-budget:$(budget_line "$m" commands/po-a.md)" commands/po-a.md "a file past its ceiling"

  m="$(fresh)"; write_budget "$m" 10 0
  printf 'five\n' >> "$m/commands/po-a.md"
  lint "$m"
  refuses_once "word-budget:$(budget_line "$m" total)" "[budget]" "the total past its ceiling"

  m="$(fresh)"; write_budget "$m" 0 50
  mkdir -p "$m/skills/extra"
  printf 'Six more words for the budget.\n' > "$m/skills/extra/SKILL.md"
  lint "$m"
  refuses_once "skills/extra/SKILL.md:1" "skills/extra/SKILL.md" "a .md file with no line"

  m="$(fresh)"
  lint "$m"
  refuses_once "word-budget:1" "[budget]" "a tree with no budget"

  # A document beside method/, in a repository: held to its ceiling, and its line must name a file.
  m="$(fresh)"; write_budget "$m" 0 0; add_document "$m" docs/guide.md 5 0; as_repository "$m/.."
  lint "$m"
  [ "$LINT_RC" -eq 0 ] || fail "po-lint refuses a document at its ceiling: $LINT_OUT"
  printf 'six\n' >> "$m/../docs/guide.md"
  lint "$m"
  refuses_once "word-budget:$(budget_line "$m" ../docs/guide.md)" ../docs/guide.md "a document past its ceiling"
  rm "$m/../docs/guide.md"
  lint "$m"
  refuses_once "word-budget:$(budget_line "$m" ../docs/guide.md)" ../docs/guide.md "a listed document gone"

  # With no repository around method/ (the payload, a copy), the documents are not there to check.
  m="$(fresh)"; write_budget "$m" 0 0
  printf '../README.md 1598\n../docs/direction.md 1192\n' >> "$m/word-budget"
  lint "$m"
  [ "$LINT_RC" -eq 0 ] || fail "po-lint fails on documents absent outside a repository: $LINT_OUT"
}

test_budget_starts_at_todays_counts() {
  local budget="$METHOD/word-budget" total target f n ceiling sum=0 bad=""
  require_file "$budget"
  total="$(awk '$1 == "total" {print $2; exit}' "$budget")"
  [ -n "$total" ] && [ "$total" -lt 57589 ] \
    || fail "the total ceiling is '$total', not under 57589, the count of 2026-11-15"
  for f in $S205_DOCUMENTS; do
    [ -n "$(ceiling_of "$METHOD" "../$f")" ] || bad+="../$f has no line (d-0055); "
  done
  [ -z "$bad" ] || fail "documents the owner listed are missing: $bad"
  target="$(sed -n 's/^Target branch:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*$/\1/p' "$ROOT/AGENTS.local.md" | head -n 1)"
  git -C "$ROOT" rev-parse --verify -q "origin/$target^{commit}" >/dev/null \
    || fail "no origin/$target to tell whether s205 has landed"
  # Once s205 has landed, a later story lowers a count without having to lower its ceiling.
  ! story_landed "$ROOT" "origin/$target" s205-word-budget-is-linted || return 0
  while IFS= read -r f; do
    n="$(words "$METHOD/$f")"; sum=$((sum + n))
    ceiling="$(ceiling_of "$METHOD" "$f")"
    [ "$ceiling" = "$n" ] || bad+="$f (${ceiling:-no line} for $n words); "
  done < <(cd "$METHOD" && find . -type f -name '*.md' | sed 's|^\./||' | LC_ALL=C sort)
  [ "$total" = "$sum" ] || bad+="total ($total for $sum words); "
  for f in $S205_DOCUMENTS; do
    n="$(words "$ROOT/$f")"; ceiling="$(ceiling_of "$METHOD" "../$f")"
    [ "$ceiling" = "$n" ] || bad+="../$f ($ceiling for $n words); "
  done
  [ -z "$bad" ] || fail "ceilings that are not the count of the day: $bad"
}

test_raising_a_ceiling_is_visible() {
  local r m saved c line
  r="$(mktemp -d "$S205_TMP/XXXXXX")"
  git -C "$r" init -q -b main
  git -C "$r" config user.email test@example.com
  git -C "$r" config user.name test
  git -C "$r" config commit.gpgsign false
  m="$(small_method "$r")"
  write_budget "$m" 5 5
  set_ceiling "$m" commands/po-a.md "$(ceiling_of "$m" commands/po-a.md)" d-0001
  add_document "$m" README.md 7 3
  git -C "$r" add -A && git -C "$r" commit -qm base
  git -C "$r" branch story
  # main lowers a ceiling after the story forked: the story is compared with its fork point, not with main.
  set_ceiling "$m" templates/profile.md "$(( $(ceiling_of "$m" templates/profile.md) - 2 ))"
  git -C "$r" commit -qam 'main lowers a ceiling'
  git -C "$r" checkout -q story
  saved="$r/saved-budget"; cp "$m/word-budget" "$saved"
  lint --base main "$m"
  [ "$LINT_RC" -eq 0 ] || fail "a budget unchanged since the fork point is refused against main: $LINT_OUT"

  c="$(ceiling_of "$m" templates/profile.md)"
  set_ceiling "$m" templates/profile.md "$((c + 1))"
  line="$(budget_line "$m" templates/profile.md)"
  lint --base main "$m"
  refuses_once "word-budget:$line" templates/profile.md "a ceiling raised with no decision"
  lint "$m"
  [ "$LINT_RC" -eq 0 ] || fail "without a base, a raised ceiling within its count is refused: $LINT_OUT"
  set_ceiling "$m" templates/profile.md "$((c + 1))" d-0002
  lint --base main "$m"
  [ "$LINT_RC" -eq 0 ] || fail "a ceiling raised citing the owner's decision is refused: $LINT_OUT"
  set_ceiling "$m" templates/profile.md "$((c - 1))"
  lint --base main "$m"
  [ "$LINT_RC" -eq 0 ] || fail "a lowered ceiling is refused: $LINT_OUT"

  cp "$saved" "$m/word-budget"
  c="$(ceiling_of "$m" commands/po-a.md)"
  set_ceiling "$m" commands/po-a.md "$((c + 1))" d-0001
  lint --base main "$m"
  refuses_once "word-budget:$(budget_line "$m" commands/po-a.md)" commands/po-a.md \
    "a ceiling raised on the decision its line already cited"

  cp "$saved" "$m/word-budget"
  set_ceiling "$m" total "$(( $(ceiling_of "$m" total) + 1 ))"
  lint --base main "$m"
  refuses_once "word-budget:$(budget_line "$m" total)" "[budget]" "the total ceiling raised with no decision"

  cp "$saved" "$m/word-budget"
  set_ceiling "$m" ../README.md "$(( $(ceiling_of "$m" ../README.md) + 1 ))"
  lint --base main "$m"
  refuses_once "word-budget:$(budget_line "$m" ../README.md)" ../README.md "a document's ceiling raised with no decision"

  cp "$saved" "$m/word-budget"
  lint --base nowhere/branch "$m"
  [ "$LINT_RC" -ne 0 ] || fail "an absent base passed: $LINT_OUT"
  grep -qF 'nowhere/branch' <<< "$LINT_OUT" || fail "the absent base is not named: $LINT_OUT"
}

test_scattered_ceilings_are_gone() {
  local f hits=""
  for f in "$ROOT"/tests/*.sh; do
    [ "${f##*/}" != word-budget-is-linted.oracle.test.sh ] || continue
    # Counting words of a here-string or of git's output is no ceiling on a file.
    hits+="$(grep -n 'wc -w' "$f" | grep -vF '<<<' | grep -vE 'git [^|]*\| *(LC_ALL=C )?wc -w' \
      | sed "s|^|${f##*/}:|" || true)"
  done
  [ -z "$hits" ] || fail "tests still count the words of a file: $hits"
}

test_budget_is_not_installed() {
  local h out laid
  require_file "$METHOD/word-budget"
  h="$(mktemp -d "$S205_TMP/XXXXXX")"
  export HOME="$h/home" CLAUDE_CONFIG_DIR="$h/home/.claude"
  mkdir -p "$CLAUDE_CONFIG_DIR" "$h/whole" "$h/init"
  git -C "$h/whole" init -q -b main
  git -C "$h/init" init -q -b main
  out="$(bash "$ROOT/bin/polype" install "$h/whole" 2>&1)" || fail "polype install <project> failed: $out"
  out="$(bash "$ROOT/bin/polype" install --global 2>&1)" || fail "polype install --global failed: $out"
  out="$(bash "$CLAUDE_CONFIG_DIR/polype/bin/polype" init "$h/init" 2>&1)" || fail "polype init failed: $out"
  [ -f "$h/init/.polype/templates/plan.md" ] || fail "init laid nothing down: nothing proven"
  laid="$(find "$h/whole" "$h/init" -name .git -prune -o -name word-budget -print)"
  [ -z "$laid" ] || fail "the word budget was laid in a project: $laid"
}
