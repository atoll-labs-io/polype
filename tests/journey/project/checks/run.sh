#!/bin/sh
# Runs every checks/*.check from the project root; the first failure fails the run.
for check in checks/*.check; do
  [ -e "$check" ] || continue
  sh "$check" || { echo "check failed: $check" >&2; exit 1; }
done
