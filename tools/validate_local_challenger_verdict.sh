#!/usr/bin/env bash
set -euo pipefail

VERDICT_JSON="${1:?usage: validate_local_challenger_verdict.sh VERDICT_JSON REVIEW_PACKET}"
REVIEW_PACKET="${2:?usage: validate_local_challenger_verdict.sh VERDICT_JSON REVIEW_PACKET}"

verdict="$(jq -er '.verdict | select(. == "VERIFIED" or . == "NEEDS_FIX")' "$VERDICT_JSON")"

if [ "$verdict" != "NEEDS_FIX" ]; then
  exit 0
fi

combined="$(jq -er '[.defect,.min_test,.evidence] | map(select(type == "string")) | join("\n")' "$VERDICT_JSON")"
test "${#combined}" -ge 12
anchor="$(jq -er '.evidence_anchor | strings | select(length >= 16)' "$VERDICT_JSON")"
case "$anchor" in
  '==='*|'---'*)
    echo "NEEDS_FIX evidence_anchor must quote implementation/test evidence, not a packet heading: $anchor" >&2
    exit 44
    ;;
esac

# A changed-file path or basename is packet metadata, not evidence for a defect.
# Small local models can otherwise cite e.g. `test_product_presentation.gd`
# while inventing claims contradicted by the code in that same file.
if [[ "$anchor" =~ ^[A-Za-z0-9_./-]+\.(gd|yml|yaml|sh)$ ]]; then
  echo "NEEDS_FIX evidence_anchor must quote code/test content, not only a file path: $anchor" >&2
  exit 46
fi

if ! grep -Fq -- "$anchor" "$REVIEW_PACKET"; then
  # Small local models sometimes copy a real source line exactly and append
  # one sentence punctuation mark. Repair only that narrow case, only when
  # removing exactly one trailing punctuation character produces a unique
  # verbatim packet match. Internal whitespace/text remain strict; ambiguous
  # or fuzzy matches still fail closed.
  case "${anchor: -1}" in
    ','|';'|':'|'.')
      candidate="${anchor::-1}"
      if [ "${#candidate}" -ge 16 ]; then
        match_count="$(grep -Fo -- "$candidate" "$REVIEW_PACKET" | wc -l | tr -d ' ')"
        if [ "$match_count" = "1" ]; then
          tmp_json="$(mktemp)"
          jq --arg repaired "$candidate" '.evidence_anchor = $repaired' "$VERDICT_JSON" > "$tmp_json"
          mv "$tmp_json" "$VERDICT_JSON"
          anchor="$candidate"
          echo "Resolved one model-added trailing punctuation mark in grounded evidence_anchor" >&2
        fi
      fi
      ;;
  esac
fi

if ! grep -Fq -- "$anchor" "$REVIEW_PACKET"; then
  echo "NEEDS_FIX evidence_anchor is not present verbatim in the exact review packet: $anchor" >&2
  exit 45
fi

# Also reject concrete function/file citations that are absent from the packet.
# The anchor check proves the reviewer saw real code; these checks prevent a
# real quote from being paired with an unrelated invented symbol/path.
mapfile -t function_symbols < <(printf '%s\n' "$combined" | grep -Eo '[A-Za-z_][A-Za-z0-9_]*\(' | sed 's/($//' | sort -u || true)
for symbol in "${function_symbols[@]}"; do
  case "$symbol" in
    if|for|while|match|range|clamp|lerp|print|assert|select|strings)
      continue
      ;;
  esac
  if ! grep -Fq -- "$symbol" "$REVIEW_PACKET"; then
    echo "NEEDS_FIX cites function-like symbol absent from exact review packet: $symbol" >&2
    exit 42
  fi
done

mapfile -t path_symbols < <(printf '%s\n' "$combined" | grep -Eo '[A-Za-z0-9_./-]+\.(gd|yml|yaml|sh)' | sort -u || true)
for path in "${path_symbols[@]}"; do
  if ! grep -Fq -- "$path" "$REVIEW_PACKET"; then
    echo "NEEDS_FIX cites path absent from exact review packet: $path" >&2
    exit 43
  fi
done
