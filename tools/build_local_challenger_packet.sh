#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${1:-origin/main}"
HEAD_REF="${2:-HEAD}"
OUT="${3:-/tmp/review-packet.txt}"
TASK_ID_VALUE="${TASK_ID_VALUE:-unknown}"
PR_NUMBER_VALUE="${PR_NUMBER_VALUE:-unknown}"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-$HEAD_REF}"
ROUND_VALUE="${ROUND_VALUE:-unknown}"

changed_paths="$(git diff --name-only "$BASE_REF...$HEAD_REF")"

append_header() {
  {
    echo "TASK_ID=$TASK_ID_VALUE"
    echo "PR_NUMBER=$PR_NUMBER_VALUE"
    echo "EXPECTED_HEAD_SHA=$EXPECTED_HEAD_VALUE"
    echo "ROUND=$ROUND_VALUE"
    echo '=== CHANGE STAT ==='
    git diff --stat "$BASE_REF...$HEAD_REF"
    echo '=== EXACT PR DIFF (FOCUSED CONTEXT) ==='
    git diff --unified=24 "$BASE_REF...$HEAD_REF"
    echo '=== CHANGED PATHS ==='
    printf '%s\n' "$changed_paths"
  } > "$OUT"
}

append_hud_contracts() {
  {
    echo '=== HUD PRESENTATION CONTRACT ==='
    cat scripts/presentation/hud_chrome_presentation.gd
    echo '=== HUD DETERMINISTIC CONTRACT ==='
    cat tests/test_hud_chrome_presentation.gd
    echo '=== GAMEPLAY HUD SOURCE ==='
    start="$(grep -n '^func _update_hud' scripts/peel_lab.gd | head -n1 | cut -d: -f1)"
    if [ -n "$start" ]; then
      end=$((start + 78))
      sed -n "${start},${end}p" scripts/peel_lab.gd
    fi
    echo '=== PLAYABLE HUD SMOKE ==='
    grep -n -B 12 -A 18 -E 'player HUD|hud_text|reset and pause affordances' tests/smoke_scene.gd || true
    echo '=== REFERENCE HUD SMOKE ==='
    grep -n -B 12 -A 18 -E 'reference HUD|hud_text' tests/smoke_reference_scene.gd || true
  } >> "$OUT"
}

append_hand_contracts() {
  {
    echo '=== DIRECT PRESENTATION/INTERACTION CONTRACTS ==='
    cat scripts/presentation/hand_choreography_presentation.gd
    sed -n '1,230p' scripts/hands/hand_visual.gd
    echo '=== GAMEPLAY HAND OWNERSHIP CONTRACT ==='
    sed -n '1,145p' scripts/peel_lab.gd
    echo '=== REFERENCE CAPTURE CONTRACT ==='
    cat tests/capture_reference_frames.gd
    echo '=== HAND REGRESSION CONTRACTS ==='
    cat tests/test_hand_visual.gd
    cat tests/test_authored_hand_asset.gd
  } >> "$OUT"
}

append_generic_contracts() {
  {
    echo '=== CHANGED PRODUCTION/TEST FILE EXCERPTS ==='
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      case "$path" in
        scripts/*.gd|scripts/**/*.gd|tests/*.gd|tests/**/*.gd)
          if [ -f "$path" ]; then
            echo "--- $path ---"
            head -c 6500 "$path"
            echo
          fi
          ;;
      esac
    done <<< "$changed_paths"
  } >> "$OUT"
}

append_header

if printf '%s\n' "$changed_paths" | grep -Eq '(^|/)(hud_chrome_presentation\.gd|test_hud_chrome_presentation\.gd)$'; then
  append_hud_contracts
elif printf '%s\n' "$changed_paths" | grep -Eq '(hand_visual|hand_choreography|capture_reference_frames|authored_hand|reference.*hand|peel.*grip|partial.*peel)'; then
  append_hand_contracts
else
  append_generic_contracts
fi

bytes="$(wc -c < "$OUT")"
echo "review packet bytes=$bytes"
if [ "$bytes" -ge 42000 ]; then
  echo "review packet exceeds 42000-byte safety budget" >&2
  exit 1
fi
