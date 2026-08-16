#!/usr/bin/env bash
set -euo pipefail

VERDICT_JSON="${1:?usage: validate_local_challenger_verdict.sh VERDICT_JSON REVIEW_PACKET}"
REVIEW_PACKET="${2:?usage: validate_local_challenger_verdict.sh VERDICT_JSON REVIEW_PACKET}"

verdict="$(jq -er '.verdict | select(. == "VERIFIED" or . == "NEEDS_FIX")' "$VERDICT_JSON")"

if [ "$verdict" = "NEEDS_FIX" ]; then
  anchor="$(jq -er '.evidence_anchor | strings | select(length >= 12)' "$VERDICT_JSON")"
  case "$anchor" in
    '==='*)
      echo "NEEDS_FIX evidence_anchor must quote implementation/test evidence, not a packet heading: $anchor" >&2
      exit 43
      ;;
  esac
  if ! grep -Fq -- "$anchor" "$REVIEW_PACKET"; then
    echo "NEEDS_FIX evidence_anchor is not present verbatim in the exact review packet: $anchor" >&2
    exit 42
  fi
fi
