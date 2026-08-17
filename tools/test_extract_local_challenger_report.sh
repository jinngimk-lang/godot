#!/usr/bin/env bash
set -euo pipefail

parser="${1:-tools/extract_local_challenger_report.py}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/verified.txt" <<'EOF'
I checked the changed path against the packet and tried a reset counterexample.
The asserted body ceiling and reset path are both exercised by the exact test.
PROVISIONAL_VERDICT: VERIFIED
DEFECT: NONE
MIN_TEST: NONE
EVIDENCE: No concrete defect survived exact-packet falsification.
EVIDENCE_ANCHOR: NO_CONCRETE_DEFECT
EOF
python3 "$parser" "$tmp/verified.txt" "$tmp/verified.json"
jq -e '.verdict == "VERIFIED" and .evidence_anchor == "NO_CONCRETE_DEFECT"' "$tmp/verified.json" >/dev/null

cat > "$tmp/markdown-trailing.txt" <<'EOF'
I tried a boundary case and found no packet-grounded defect.
- **PROVISIONAL_VERDICT:** VERIFIED
- **DEFECT:** NONE
- **MIN_TEST:** NONE
- **EVIDENCE:** The exact candidate already bounds and resets every changed ice state.
- **EVIDENCE_ANCHOR:** NO_CONCRETE_DEFECT
That is my final answer.
EOF
python3 "$parser" "$tmp/markdown-trailing.txt" "$tmp/markdown-trailing.json"
jq -e '.verdict == "VERIFIED" and .evidence_anchor == "NO_CONCRETE_DEFECT"' "$tmp/markdown-trailing.json" >/dev/null

cat > "$tmp/needs-fix.txt" <<'EOF'
A boundary case is not covered when the glass cluster is selected.
PROVISIONAL_VERDICT: NEEDS_FIX
DEFECT: The glass layout branch bypasses the shared body clamp in this fixture.
MIN_TEST: Add a regression case that applies glass_cluster and asserts the resulting center remains inside the configured top limit.
EVIDENCE: The exact packet shows the branch returning before the shared clamp.
EVIDENCE_ANCHOR: return _glass_cluster_transform(index, count, dims)
EOF
python3 "$parser" "$tmp/needs-fix.txt" "$tmp/needs-fix.json"
jq -e '.verdict == "NEEDS_FIX" and (.min_test | length) > 20' "$tmp/needs-fix.json" >/dev/null

cat > "$tmp/no-protocol.txt" <<'EOF'
I will rewrite this instead.
class_name HallucinatedReplacement
func fake_path():
    return 1
EOF
set +e
python3 "$parser" "$tmp/no-protocol.txt" "$tmp/should-not-exist.json"
rc=$?
set -e
test "$rc" -eq 4

cat > "$tmp/conflicting.txt" <<'EOF'
PROVISIONAL_VERDICT: VERIFIED
DEFECT: NONE
MIN_TEST: NONE
EVIDENCE: first complete result
EVIDENCE_ANCHOR: NO_CONCRETE_DEFECT
PROVISIONAL_VERDICT: NEEDS_FIX
DEFECT: conflicting second answer
MIN_TEST: add a regression test for the conflicting answer
EVIDENCE: second complete result
EVIDENCE_ANCHOR: return _glass_cluster_transform(index, count, dims)
EOF
set +e
python3 "$parser" "$tmp/conflicting.txt" "$tmp/should-not-exist-2.json"
rc=$?
set -e
test "$rc" -eq 4

cat > "$tmp/duplicate-field.txt" <<'EOF'
PROVISIONAL_VERDICT: VERIFIED
DEFECT: NONE
DEFECT: actually something else
MIN_TEST: NONE
EVIDENCE: conflicting duplicate field must fail closed
EVIDENCE_ANCHOR: NO_CONCRETE_DEFECT
EOF
set +e
python3 "$parser" "$tmp/duplicate-field.txt" "$tmp/should-not-exist-3.json"
rc=$?
set -e
test "$rc" -eq 4

echo "Local Challenger deterministic report parser self-test PASS"
