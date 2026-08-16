#!/usr/bin/env bash
set -euo pipefail

validator="${1:-tools/validate_local_challenger_verdict.sh}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

packet="$tmp/packet.txt"
cat > "$packet" <<'EOF'
=== CHANGED PATHS ===
tests/test_product_presentation.gd
--- tests/test_product_presentation.gd ---
if outer_mat == null or outer_mat.albedo_color.a > 0.15:
    failures.append("RED: amber outer glass must stay translucent enough for shoulder/neck separation")
EOF

# A path-only anchor is metadata, not evidence. The validator must reject it.
cat > "$tmp/path-only.json" <<'EOF'
{
  "verdict":"NEEDS_FIX",
  "defect":"The test does not verify material properties in tests/test_product_presentation.gd",
  "min_test":"Add material assertions.",
  "evidence":"Only a filename was cited.",
  "evidence_anchor":"test_product_presentation.gd"
}
EOF
if bash "$validator" "$tmp/path-only.json" "$packet" >/dev/null 2>&1; then
  echo "RED: validator accepted a path-only NEEDS_FIX evidence anchor" >&2
  exit 1
fi

# A real contiguous code quote from the exact packet remains valid evidence.
cat > "$tmp/code-quote.json" <<'EOF'
{
  "verdict":"NEEDS_FIX",
  "defect":"The amber alpha threshold is too permissive.",
  "min_test":"Tighten the alpha threshold.",
  "evidence":"The packet contains the exact threshold.",
  "evidence_anchor":"outer_mat.albedo_color.a > 0.15"
}
EOF
bash "$validator" "$tmp/code-quote.json" "$packet"

# VERIFIED never requires a defect anchor.
cat > "$tmp/verified.json" <<'EOF'
{
  "verdict":"VERIFIED",
  "defect":"NONE",
  "min_test":"NONE",
  "evidence":"No concrete defect.",
  "evidence_anchor":"NO_CONCRETE_DEFECT"
}
EOF
bash "$validator" "$tmp/verified.json" "$packet"

echo "Local Challenger verdict validator self-test PASS"
