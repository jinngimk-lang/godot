#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

cat > "$tmp/analysis.txt" <<'EOF'
The candidate looks suspicious. Here is unrelated hallucinated replacement code:
class_name FakePresentation
func invented_path():
    return 123
Provisional conclusion: NEEDS_FIX, but this note is intentionally ungrounded.
EOF

cat > "$tmp/packet.txt" <<'EOF'
=== CHANGED PATHS ===
scripts/presentation/cup_contents_presentation.gd
--- scripts/presentation/cup_contents_presentation.gd ---
func _is_glass_cluster() -> bool:
    var contents: Dictionary = _profile.get("contents_profile", {})
    return String(contents.get("layout", "")) == "glass_cluster"
EOF

cat > "$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
state="${MOCK_CURL_STATE:?}"
count=0
if [ -f "$state" ]; then count="$(cat "$state")"; fi
count=$((count + 1))
printf '%s' "$count" > "$state"
if [ "$count" -eq 1 ]; then
  # Reproduce the real PR #81 failure shape: the local model ignores the JSON
  # contract and emits unrelated prose/code with no object envelope.
  jq -nc --arg response 'I will rewrite it instead. class_name FakePresentation extends Node. No structured verdict follows.' '{response:$response}'
else
  jq -nc --arg response '{"verdict":"VERIFIED","defect":"none","min_test":"none","evidence":"The hallucinated FakePresentation code is absent from the exact packet; no concrete defect is grounded.","evidence_anchor":"NO_CONCRETE_DEFECT"}' '{response:$response}'
fi
EOF
chmod +x "$tmp/bin/curl"

MOCK_CURL_STATE="$tmp/curl-count" \
PATH="$tmp/bin:$PATH" \
EXTRACTOR="$repo_root/tools/extract_local_challenger_json.py" \
VALIDATOR="$repo_root/tools/validate_local_challenger_verdict.sh" \
RETRY_CLASSIFIER="$repo_root/tools/should_retry_local_challenger.sh" \
  bash "$repo_root/tools/normalize_local_challenger_verdict.sh" \
    "$tmp/analysis.txt" "$tmp/packet.txt" "$tmp/verdict.json"

jq -e '.verdict == "VERIFIED" and .evidence_anchor == "NO_CONCRETE_DEFECT"' "$tmp/verdict.json" >/dev/null
test "$(cat "$tmp/curl-count")" -eq 2

echo "Local Challenger normalization format-retry self-test PASS"
