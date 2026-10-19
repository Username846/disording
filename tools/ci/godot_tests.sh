#!/usr/bin/env bash
# Runs the Godot-side checks headlessly: import, compile every script, unit + smoke tests.
# Fails on a non-zero exit code OR any "SCRIPT ERROR"/engine "ERROR:" line in the logs.
set -uo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/../.."
mkdir -p build/logs && touch build/.gdignore
status=0

run() {
  local name="$1"; shift
  echo "::group::$name"
  timeout "${TIMEOUT:-600}" "$GODOT" --headless --path . "$@" > "build/logs/$name.log" 2>&1
  local code=$?
  cat "build/logs/$name.log"
  echo "::endgroup::"
  if [ $code -ne 0 ]; then
    echo "❌ $name exited with $code"; status=1
  fi
  if grep -E "SCRIPT ERROR|^ERROR:" "build/logs/$name.log" | grep -v "Audio bundle" > /dev/null; then
    echo "❌ $name logged errors:"; grep -E -A2 "SCRIPT ERROR|^ERROR:" "build/logs/$name.log" | head -40; status=1
  fi
}

run import --import
run script_check --quit-after 2000 res://tests/script_check.tscn
run tests --fixed-fps 60 res://tests/test_runner.tscn -- --test
exit $status
