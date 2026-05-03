#!/usr/bin/env bash
# Assertion helpers. Each prints PASS/FAIL with context.

assert_pass() {
  echo "PASS: $1"
  return 0
}

assert_fail() {
  echo "FAIL: $1"
  return 1
}

# assert_grep <description> <pattern> <text>
assert_grep() {
  local desc="$1" pat="$2" text="$3"
  if printf '%s' "$text" | grep -qE "$pat"; then
    assert_pass "$desc"
  else
    assert_fail "$desc — pattern not found: $pat"
  fi
}

# assert_grep_iter <description> <text>  ...then read patterns from stdin, ALL must match.
# Use when one assertion needs multiple co-occurring tokens.
assert_all_grep() {
  local desc="$1" text="$2" pat
  shift 2
  for pat in "$@"; do
    if ! printf '%s' "$text" | grep -qE "$pat"; then
      assert_fail "$desc — missing: $pat"
      return 1
    fi
  done
  assert_pass "$desc"
}
