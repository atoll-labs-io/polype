#!/usr/bin/env bash
# s201 — the oracle of the story: the phrase tests of the routing family are gone, no script is launched
# by fewer test functions than on the base, the contract tests stay and every test file still holds a test.
# Everything above the first test is a helper the oracles of s202 to s204 take without changing it:
#   source <(sed '/^test_/,$d' "$ROOT/tests/routing-phrase-tests-retired.oracle.test.sh")

# A test function launches a script when its body, or the body of a helper it calls, names the script's
# path outside single quotes (where the phrases a test looks for live), once the variables it and its file
# set are replaced by their values, neither as a value given to a variable nor as an argument of a command
# that only reads or prints text (grep, awk, sed, cat, contains, fail and the like). Laying a hook counts, as
# running it does. A hook is named by its file name (`pre-commit` also by `hooksPath`), a file of bin/ by
# `bin/<name>`, po by the `/release/po` or `/polype/po` it runs from. The reading is static and the same
# on both sides, so a count compares; it is not proof that the line ran.
LAUNCH_READER='
import re, sys
scripts = [a.split(":", 1) for a in sys.argv[1:]]
edge = r"(?![A-Za-z0-9_.-])"
def marker(kind, name):
    if kind == "hook":
        return re.compile(r"(?<![A-Za-z0-9_.-])" + re.escape(name) + edge + ("|hooksPath" if name == "pre-commit" else ""))
    if kind == "bin":
        return re.compile(r"bin/" + re.escape(name) + edge)
    return re.compile(r"/(?:release|polype)/po" + edge)
markers = [(name, marker(kind, name)) for kind, name in scripts]
readers = {"awk", "grep", "sed", "cat", "head", "tail", "wc", "cksum", "cmp", "diff", "cut", "tr", "sort",
           "echo", "printf", "fail", "contains", "holds", "lacks", "require_file", "frontmatter", "tools_of",
           "has_tool", "needs_tool", "lacks_tool", "settings_read_by", "section_of", "test", "[", "[["}
separator = re.compile(r"(?:;|&&|\|\||\||\$\(|\(|`|\bthen\b|\bdo\b|\belse\b)")

def launched(text, pattern):
    for line in text.splitlines():
        for m in pattern.finditer(line):
            start = m.start()
            while start > 0 and line[start - 1] not in " \t;|&()<>":
                start -= 1
            if re.match(r"\"?[A-Za-z_][A-Za-z0-9_]*=", line[start:]):
                continue
            cuts = [c.end() for c in separator.finditer(line, 0, m.start())]
            words = line[cuts[-1] if cuts else 0:m.start()].split()
            while words and (words[0] == "!" or re.match(r"[A-Za-z_][A-Za-z0-9_]*=", words[0])):
                words.pop(0)
            if not words or words[0].strip("\"") not in readers:
                return True
    return False

def unquoted(line):
    out, state, i = [], None, 0
    while i < len(line):
        c = line[i]
        if state == "s":
            state = None if c == "\x27" else state
        elif c == "\\" and i + 1 < len(line):
            out.append(line[i:i + 2]); i += 1
        elif state == "d":
            state = None if c == "\"" else state; out.append(c)
        elif c == "\x27":
            state = "s"
        else:
            state = "d" if c == "\"" else state; out.append(c)
        i += 1
    return "".join(out)

def read(block):
    head, _, funcs = block.partition("\0@@FUNCS\n")
    values = {}
    for line in head.splitlines():
        m = re.match(r"declare -\S+ ([A-Za-z_][A-Za-z0-9_]*)=(.*)$", line)
        if m:
            v = m.group(2)
            values[m.group(1)] = v[1:-1] if len(v) > 1 and v[0] == v[-1] == "\"" else v
    bodies, name = {}, None
    for line in funcs.splitlines():
        m = re.match(r"([A-Za-z_][A-Za-z0-9_:-]*) \(\) *$", line)
        if m and name is None:
            name, lines = m.group(1), []
        elif name is not None and line == "}":
            bodies[name] = "\n".join(unquoted(l) for l in lines); name = None
        elif name is not None:
            lines.append(line)
    def expand(text):
        own = dict(values)
        for m in re.finditer(r"(?:^|\s)([A-Za-z_][A-Za-z0-9_]*)=(\"[^\"]*\"|[^\s;]+)", text):
            own.setdefault(m.group(1), m.group(2).strip("\""))
        once = lambda t: re.sub(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?", lambda m: own.get(m.group(1), m.group(0)), t)
        own = {k: once(v) for k, v in own.items()}
        return once(text)
    return bodies, expand

def calls(bodies):
    if not bodies:
        return {}
    names = "|".join(sorted((re.escape(n) for n in bodies), key=len, reverse=True))
    call = re.compile(r"(?:^|[;&|(!`]|\$\(|\b(?:if|then|do|else|elif|while|until)\s)\s*(" + names + r")(?=\s|;|\)|$)", re.M)
    return {n: {m.group(1) for m in call.finditer(b)} - {n} for n, b in bodies.items()}

for block in sys.stdin.read().split("\0@@FILE ")[1:]:
    file, _, rest = block.partition("\n")
    bodies, expand = read(rest)
    graph = calls(bodies)
    for test in sorted(n for n in bodies if n.startswith("test_")):
        seen, todo = set(), [test]
        while todo:
            n = todo.pop()
            if n not in seen:
                seen.add(n); todo.extend(graph.get(n, ()))
        text = expand("\n".join(bodies[n] for n in seen))
        for name, pattern in markers:
            if launched(text, pattern):
                print(name + "\t" + file + ":" + test)
'

# counted_scripts <root>: `<kind>:<name>` of every script whose launches are counted.
counted_scripts() {
  local f
  for f in "$1"/method/hooks/*; do [ -f "$f" ] && printf 'hook:%s\n' "${f##*/}"; done
  for f in "$1"/bin/*; do [ -f "$f" ] && printf 'bin:%s\n' "${f##*/}"; done
  printf 'po:po\n'
}

# script_launches <tests dir> <root>: one `<script>\t<file>:<test function>` line per launch. Each file is
# sourced after lib.sh, in a shell of its own, as tests/run.sh does to list its tests. Its markers start with a
# NUL, which no variable or function can hold, so a file that sources these helpers is read like any other.
script_launches() {
  local tests="$1" root="$2" f
  local -a scripts
  mapfile -t scripts < <(counted_scripts "$root")
  for f in "$tests"/*.test.sh; do
    printf '\0@@FILE %s\n' "${f##*/}"
    (cd "$tests" && bash -c '
      before=" $(compgen -v | tr "\n" " ") "
      source ./lib.sh && source "./$1" || exit 0
      for v in $(compgen -v); do case "$before" in *" $v "*) ;; *) declare -p "$v" 2>/dev/null ;; esac; done
      printf "\0@@FUNCS\n"
      declare -f' _ "${f##*/}" 2>/dev/null </dev/null) || true
  done | python3 -I -c "$LAUNCH_READER" "${scripts[@]}"
}

# script_counts <tests dir> <root>: `<script> <number of test functions that launch it>`, every counted script.
script_counts() {
  local launches
  launches="$(script_launches "$1" "$2")" || return 1
  counted_scripts "$2" | while IFS=: read -r _ name; do
    printf '%s %s\n' "$name" "$(awk -F'\t' -v s="$name" '$1 == s' <<< "$launches" | grep -c . || true)"
  done
}

# A story that rightly lowers a script's count adds one line here: `<script> <count on the base> <count after>
# <story id>`. It allows exactly that drop, and only while no commit of the base ref is titled `<story id>: …`,
# the landing commit /po-ship writes: once the story has landed, the line allows nothing.
LOWERED_COUNTS='
po-gate.sh 136 135 s205-word-budget-is-linted
po 184 183 s208-real-run-in-the-sandbox
'

# story_landed <repository> <commit> <story id>: 0 when a commit reachable from <commit> has a subject starting
# with `<story id>: `, compared as a fixed prefix.
story_landed() {
  git -C "$1" log --format=%s "$2" | P="$3: " awk 'index($0, ENVIRON["P"]) == 1 {found = 1} END {exit !found}'
}

# scripts_kept_their_tests <repository> <base ref>: compares the tests of the merge base of HEAD and <base ref>
# with the working tree. 0 when no counted script is launched by fewer test functions, unless a line of
# LOWERED_COUNTS allows that drop, or on the base itself (HEAD is the merge base and tests/ holds no change:
# nothing to compare); 1 naming each script that lost some, or the base ref when it is absent.
scripts_kept_their_tests() {
  local repo="$1" ref="$2" base head tmp before after rc=0 name old new story id
  git -C "$repo" rev-parse --verify -q "$ref^{commit}" >/dev/null \
    || { echo "no base to compare with: $ref is not in $repo"; return 1; }
  base="$(git -C "$repo" merge-base HEAD "$ref")" || { echo "HEAD shares no commit with $ref"; return 1; }
  head="$(git -C "$repo" rev-parse HEAD)"
  if [ "$base" = "$head" ] && [ -z "$(git -C "$repo" status --porcelain -- tests)" ]; then
    echo "on the base $ref itself: nothing compared"; return 0
  fi
  tmp="$(mktemp -d)"
  git -C "$repo" archive "$base" tests method bin | tar -x -C "$tmp" \
    || { rm -rf "$tmp"; echo "cannot extract tests/, method/ and bin/ of $base"; return 1; }
  before="$(script_counts "$tmp/tests" "$repo")" || { rm -rf "$tmp"; echo "cannot count on $base"; return 1; }
  rm -rf "$tmp"
  after="$(script_counts "$repo/tests" "$repo")" || { echo "cannot count the working tree"; return 1; }
  while read -r name new; do
    old="$(awk -v s="$name" '$1 == s {print $2}' <<< "$before")"
    [ "${old:-0}" -gt "$new" ] || continue
    story=""
    while read -r id; do
      [ -n "$id" ] && ! story_landed "$repo" "$ref" "$id" && { story="$id"; break; }
    done < <(awk -v s="$name" -v o="${old:-0}" -v n="$new" \
      '$1 == s && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ && $2 == o && $3 == n {print $4}' <<< "${LOWERED_COUNTS:-}")
    if [ -n "$story" ]; then echo "$name: launched by $old test functions on $ref, $new here, lowered by $story"
    else echo "$name: launched by $old test functions on $ref, $new here"; rc=1; fi
  done <<< "$after"
  return "$rc"
}

# The test files of the family this story keeps, each with the contract tests it must still define.
KEPT_CONTRACTS='
drive.test.sh test_drive_never_writes_code_or_verdicts test_settings_template_declares_fleet_settings
pilot.test.sh test_status_derives_from_files test_help_is_user_invoked_only
wiring.test.sh test_reviewer_checks_design_conformity_without_measuring
model-routing.test.sh test_settings_declare_the_model_routing test_implementer_no_longer_pins_a_model test_setup_offers_the_defaults
escalation-contract.test.sh test_plan_with_a_tech_choice_waits_for_a_human
defect-and-routing-paths.test.sh test_no_root_cause_goes_to_a_human
planner.test.sh test_planner_preloads_testing_doctrine_and_codebase_analysis test_planner_never_writes_code
planner-writes-the-oracle.test.sh test_plan_lists_its_oracle test_implementer_keeps_the_oracle
plan.test.sh test_plan_template_starts_unvalidated test_plan_writes_no_code
research.test.sh test_research_writes_no_code test_stories_template_declares_owns_and_scale
execute.test.sh test_execute_has_no_write_tools test_implementer_preloads_testing_doctrine test_verification_record_has_tree_and_unfilled_status
review.test.sh test_reviewer_cannot_write_files test_reviewer_preloads_both_doctrines test_review_template_ends_with_verdict_lines test_review_command_writes_blocked_report_on_failure test_review_counts_fix_loops_across_sessions test_review_template_records_the_reviewed_tree
review-lenses.test.sh test_one_reviewer_one_verdict
review-findings-shape.test.sh test_gate_checks_findings_shape test_template_shows_the_line test_recording_runs_the_check test_gate_accepts_only_ship_shapes test_other_gate_failures_stop
review-header-recorded.oracle.test.sh test_template_marks_the_header
review-tree-gate.test.sh test_ship_gate_reads_the_last_review test_verdict_lines_may_be_list_items test_other_tree_lines_read_the_same_way
ownership.test.sh test_qa_current_failure_names_an_uncommitted_report
diagnostic-skill.test.sh test_defect_stories_get_the_diagnostic
oracle-intact-gate.oracle.test.sh test_gate_compares_oracle_sums test_gate_without_oracle_says_so
floor-guard.test.sh test_floor_guard_has_three_outcomes test_floor_guard_flags_new_suppressions test_floor_guard_flags_weakened_tests test_floor_guard_flags_a_test_renamed_out_of_the_test_tree test_floor_guard_says_2_on_an_unreadable_diff test_floor_guard_flags_empty_catch_and_lowered_thresholds
structure.test.sh test_settings_template_one_value_per_line test_settings_template_declares_all_m1_settings test_every_setting_read_by_a_command_exists_in_template test_rules_start_with_generated_marker
leftovers.test.sh test_polype_declares_every_template_setting
docs-and-eval-cleanup.test.sh test_drift_message_fits_the_mode
strict-checks-by-default.test.sh test_profile_declares_strictness test_every_profile_fills_strictness test_strict_command_reaches_typecheck
'

# tests_defined <tests dir> <file>: the test_ functions the file defines, sourced as tests/run.sh sources it.
tests_defined() {
  (cd "$1" && bash -c 'source ./lib.sh && source "./$1" && declare -F' _ "$2" 2>/dev/null </dev/null) \
    | awk '$3 ~ /^test_/ {print $3}'
}

test_contract_tests_stay() {
  local out status=0 file names name missing=""
  out="$(bash "$ROOT/bin/po-lint" "$METHOD" 2>&1)" || status=$?
  [ "$status" -eq 0 ] || fail "po-lint reports breaches: $out"
  while read -r file names; do
    [ -n "$file" ] || continue
    [ -f "$ROOT/tests/$file" ] || { missing+="$file (file gone); "; continue; }
    out="$(tests_defined "$ROOT/tests" "$file")"
    for name in $names; do
      grep -qxF "$name" <<< "$out" || missing+="$file:$name; "
    done
  done <<< "$KEPT_CONTRACTS"
  [ -z "$missing" ] || fail "contract tests gone: $missing"
}

test_no_script_lost_its_tests() {
  local repo out target
  # The reader bites: on a throwaway repository, dropping a launch is named, dropping a phrase is not.
  S201_REPO="$(mktemp -d)"
  trap 'rm -rf "$S201_REPO"' EXIT
  repo="$S201_REPO"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name test
  git -C "$repo" config commit.gpgsign false
  mkdir -p "$repo/tests" "$repo/method/hooks" "$repo/bin"
  cp "$ROOT/tests/lib.sh" "$repo/tests/"
  printf '#!/usr/bin/env bash\n' > "$repo/method/hooks/po-gate.sh"
  printf '#!/usr/bin/env bash\n' > "$repo/bin/po-lint"
  cat > "$repo/tests/a.test.sh" <<'EOF'
GATE="$METHOD/hooks/po-gate.sh"
gate() { bash "$GATE" "$@"; }
test_launch() { gate ship-allowed s01-a; }
test_phrase() { contains "$METHOD/x.md" 'run po-gate.sh and bin/po-lint here'; }
test_lint() { out=$(bash "$ROOT/bin/po-lint" 2>&1); }
EOF
  git -C "$repo" add -A && git -C "$repo" commit -qm base
  git -C "$repo" branch base
  out="$(scripts_kept_their_tests "$repo" base)" || fail "on the base itself the comparison failed: $out"
  grep -qF 'nothing compared' <<< "$out" || fail "on the base itself something was compared: $out"
  sed -i '/^test_phrase/d' "$repo/tests/a.test.sh"
  out="$(scripts_kept_their_tests "$repo" base)" || fail "dropping a phrase test was taken for a lost launch: $out"
  ! grep -qF 'nothing compared' <<< "$out" || fail "an uncommitted change on the base was not compared: $out"
  sed -i '/^test_launch/d' "$repo/tests/a.test.sh"
  out="$(scripts_kept_their_tests "$repo" base)" && fail "an uncommitted drop of a test launching po-gate.sh went unnoticed"
  grep -qF 'po-gate.sh: launched by 1 test functions on base, 0 here' <<< "$out" || fail "the lost launch is not named: $out"
  ! grep -qF 'po-lint' <<< "$out" || fail "po-lint is named though its test stayed: $out"
  git -C "$repo" checkout -qb story && git -C "$repo" commit -qam story
  out="$(scripts_kept_their_tests "$repo" base)" && fail "a committed drop of a test launching po-gate.sh went unnoticed"
  grep -qF 'po-gate.sh: launched by 1' <<< "$out" || fail "the committed lost launch is not named: $out"
  out="$(scripts_kept_their_tests "$repo" nowhere/branch)" && fail "an absent base ref passed"
  grep -qF 'nowhere/branch' <<< "$out" || fail "the absent base ref is not named: $out"

  # A file that sources these helpers, as docs/harnais.md says, is read like any other; a lowered count
  # passes only through a LOWERED_COUNTS line written for that base count.
  sed '/^test_/,$d' "$ROOT/tests/routing-phrase-tests-retired.oracle.test.sh" \
    > "$repo/tests/routing-phrase-tests-retired.oracle.test.sh"
  cat > "$repo/tests/b.test.sh" <<'EOF'
source <(sed '/^test_/,$d' "$ROOT/tests/routing-phrase-tests-retired.oracle.test.sh")
test_sourced() { bash "$METHOD/hooks/po-gate.sh" ship-allowed s01-b; }
EOF
  git -C "$repo" add -A && git -C "$repo" commit -qm sourced && git -C "$repo" branch sourced
  script_launches "$repo/tests" "$repo" | grep -qxF $'po-gate.sh\tb.test.sh:test_sourced' \
    || fail "the launch of a file that sources the count is not counted"
  sed -i '/^test_sourced/d' "$repo/tests/b.test.sh"
  out="$(scripts_kept_their_tests "$repo" sourced)" && fail "a drop in a file that sources the count went unnoticed"
  grep -qF 'po-gate.sh: launched by 1 test functions on sourced, 0 here' <<< "$out" \
    || fail "the lost launch of a file that sources the count is not named: $out"
  out="$(LOWERED_COUNTS='po-gate.sh 1 0 s999-lowered' scripts_kept_their_tests "$repo" sourced)" \
    || fail "a drop listed in LOWERED_COUNTS still failed: $out"
  grep -qF 'lowered by s999-lowered' <<< "$out" || fail "the story that lowered the count is not named: $out"
  out="$(LOWERED_COUNTS='po-gate.sh 2 0 s999-stale' scripts_kept_their_tests "$repo" sourced)" \
    && fail "a LOWERED_COUNTS line written for another base count let the drop through"
  out="$(LOWERED_COUNTS='po-gate.sh 1 - s997-malformed' scripts_kept_their_tests "$repo" sourced)" \
    && fail "a LOWERED_COUNTS line with no count after let the drop through"
  # Once its story has landed, a line allows nothing, even when the base count comes back to its first value.
  git -C "$repo" commit -qam 's999-lowered: lower the count'
  printf '%s\n' 'test_back() { bash "$METHOD/hooks/po-gate.sh" ship-allowed s01-c; }' >> "$repo/tests/b.test.sh"
  git -C "$repo" commit -qam 's998-back: launch it again' && git -C "$repo" branch relaunched
  sed -i '/^test_back/d' "$repo/tests/b.test.sh"
  out="$(LOWERED_COUNTS='po-gate.sh 1 0 s999-lowered' scripts_kept_their_tests "$repo" relaunched)" \
    && fail "a LOWERED_COUNTS line whose story has landed let a later drop through: $out"
  mkdir -p "$repo/own" && cp "$ROOT/tests/lib.sh" "$ROOT/tests/routing-phrase-tests-retired.oracle.test.sh" "$repo/own/"
  script_launches "$repo/own" "$repo" | grep -qxF $'po-lint\trouting-phrase-tests-retired.oracle.test.sh:test_contract_tests_stay' \
    || fail "the launches of this oracle's own tests are not counted"

  # The story itself, against the Target branch as the forge holds it.
  target="$(sed -n 's/^Target branch:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*$/\1/p' "$ROOT/AGENTS.local.md" | head -n 1)"
  [ -n "$target" ] || fail "AGENTS.local.md has no Target branch"
  out="$(scripts_kept_their_tests "$ROOT" "origin/$target")" || fail "$out"
}

test_suite_still_runs_clean() {
  local f empty=""
  for f in "$ROOT"/tests/*.test.sh; do
    [ -n "$(tests_defined "$ROOT/tests" "${f##*/}")" ] || empty+="${f##*/} "
  done
  [ -z "$empty" ] || fail "test files with no test_ function, which tests/run.sh fails: $empty"
}
