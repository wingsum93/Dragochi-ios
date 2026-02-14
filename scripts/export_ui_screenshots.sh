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

attachment_map="$({ python3 - "$temp_json" "$XCRESULT_PATH" <<'PY'
import json
import subprocess
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)
xcresult_path = sys.argv[2]

results = {}
loaded_refs = {}

def unwrap(value):
    while isinstance(value, dict) and "_value" in value:
        value = value["_value"]
    return value

def load_ref(ref_id):
    if not isinstance(ref_id, str) or not ref_id:
        return None
    if ref_id in loaded_refs:
        return loaded_refs[ref_id]

    try:
        output = subprocess.check_output(
            [
                "xcrun",
                "xcresulttool",
                "get",
                "--legacy",
                "--path",
                xcresult_path,
                "--id",
                ref_id,
                "--format",
                "json",
            ],
            text=True,
        )
        loaded_refs[ref_id] = json.loads(output)
    except Exception:
        loaded_refs[ref_id] = None

    return loaded_refs[ref_id]

def collect_ref_ids(node, ref_key, out):
    if isinstance(node, dict):
        ref = node.get(ref_key)
        if isinstance(ref, dict):
            ref_id = unwrap(ref.get("id"))
            if isinstance(ref_id, str):
                out.add(ref_id)
        for value in node.values():
            collect_ref_ids(value, ref_key, out)
    elif isinstance(node, list):
        for value in node:
            collect_ref_ids(value, ref_key, out)

def visit_attachments(node):
    if isinstance(node, dict):
        payload = node.get("payloadRef")
        payload_id = unwrap(payload.get("id")) if isinstance(payload, dict) else None
        name = unwrap(node.get("name"))
        filename = unwrap(node.get("filename"))
        resolved_name = name or filename
        if payload_id and isinstance(resolved_name, str) and resolved_name.endswith(".png"):
            results.setdefault(resolved_name, payload_id)
        for value in node.values():
            visit_attachments(value)
    elif isinstance(node, list):
        for value in node:
            visit_attachments(value)

tests_ref_ids = set()
collect_ref_ids(data, "testsRef", tests_ref_ids)
visit_attachments(data)

for tests_ref_id in sorted(tests_ref_ids):
    tests_data = load_ref(tests_ref_id)
    if tests_data is None:
        continue

    visit_attachments(tests_data)

    summary_ref_ids = set()
    collect_ref_ids(tests_data, "summaryRef", summary_ref_ids)

    for summary_ref_id in sorted(summary_ref_ids):
        summary_data = load_ref(summary_ref_id)
        if summary_data is not None:
            visit_attachments(summary_data)

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
