#!/usr/bin/env bash
set -euo pipefail

XCRESULT_PATH="${1:-}"
OUTPUT_DIR="${2:-screenshots}"

if [[ -z "$XCRESULT_PATH" ]]; then
  echo "Usage: $0 <path-to.xcresult> [output-dir]" >&2
  exit 1
fi

if [[ ! -d "$XCRESULT_PATH" ]]; then
  echo "Error: xcresult bundle not found at '$XCRESULT_PATH'" >&2
  exit 1
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "Error: xcrun is required to export screenshots from xcresult bundles." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

required_names=(
  "home.png"
  "history.png"
  "stats.png"
  "settings.png"
  "add-session.png"
)

temp_json="$(mktemp)"
trap 'rm -f "$temp_json"' EXIT

xcrun xcresulttool get --legacy --path "$XCRESULT_PATH" --format json > "$temp_json"

attachment_map="$({ python3 - "$temp_json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

results = {}

def visit(node):
    if isinstance(node, dict):
        payload = node.get("payloadRef")
        payload_id = payload.get("id") if isinstance(payload, dict) else None
        filename = node.get("filename") or node.get("name")
        if payload_id and isinstance(filename, str) and filename.endswith(".png"):
            results.setdefault(filename, payload_id)
        for value in node.values():
            visit(value)
    elif isinstance(node, list):
        for value in node:
            visit(value)

visit(data)
for name, payload_id in sorted(results.items()):
    print(f"{name}\t{payload_id}")
PY
} )"

missing=0
for name in "${required_names[@]}"; do
  payload_id="$(awk -F $'\t' -v file="$name" '$1 == file { print $2; exit }' <<< "$attachment_map")"

  if [[ -z "$payload_id" ]]; then
    echo "Warning: attachment '$name' not found in $XCRESULT_PATH" >&2
    missing=1
    continue
  fi

  xcrun xcresulttool export --legacy --type file --path "$XCRESULT_PATH" --id "$payload_id" --output-path "$OUTPUT_DIR/$name"
  echo "Exported $OUTPUT_DIR/$name"
done

if [[ "$missing" -eq 1 ]]; then
  echo "Completed with warnings: one or more expected screenshots were not found." >&2
  exit 2
fi

echo "All screenshots exported to $OUTPUT_DIR"
