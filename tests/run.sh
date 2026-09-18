#!/usr/bin/env bash
# Runs every test_* function of tests/*.test.sh (or of the files given as arguments).
set -u
cd "$(dirname "$0")"
files=("$@")
[ ${#files[@]} -gt 0 ] || files=(*.test.sh)

passed=0 failed=0
for file in "${files[@]}"; do
  echo "${file}"
  if ! names=$(bash -c "source ./lib.sh && source './${file}' && declare -F" 2>&1); then
    echo "  FAIL  (file does not load)"; echo "$names"; failed=$((failed + 1)); continue
  fi
  names=$(awk '$3 ~ /^test_/ {print $3}' <<< "$names")
  [ -n "$names" ] || { echo "  FAIL  (no test found)"; failed=$((failed + 1)); continue; }
  for name in $names; do
    if out=$(bash -c "set -eu; source ./lib.sh; source './${file}'; ${name}" 2>&1); then
      echo "  ok    ${name#test_}"; passed=$((passed + 1))
    else
      echo "  FAIL  ${name#test_}"; [ -n "$out" ] && echo "$out"; failed=$((failed + 1))
    fi
  done
done
echo "${passed} passed, ${failed} failed"
[ "$failed" -eq 0 ]
