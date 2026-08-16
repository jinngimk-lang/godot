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

# A concrete NEEDS_FIX verdict often cites a function or file. Those citations
# must exist in the exact review packet. This catches reviewer hallucinations
# without trying to decide the product verdict itself.
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
