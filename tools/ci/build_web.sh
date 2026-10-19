#!/usr/bin/env bash
# Export the release and preview web builds and assemble the Pages site in build/site.
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/../.."
mkdir -p build/logs build/site/preview
touch build/.gdignore
python3 tools/ci/assemble_site.py --build-info
"$GODOT" --headless --path . --import > build/logs/import.log 2>&1 || true
"$GODOT" --headless --path . --export-release "Web" build/site/index.html 2>&1 | tee build/logs/export_release.log
"$GODOT" --headless --path . --export-debug "Web Preview" build/site/preview/index.html 2>&1 | tee build/logs/export_preview.log
if grep -E "ERROR|SCRIPT ERROR" build/logs/export_*.log; then
  echo "❌ export logged errors"; exit 1
fi
python3 tools/ci/assemble_site.py
