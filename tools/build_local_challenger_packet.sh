#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${1:-origin/main}"
HEAD_REF="${2:-HEAD}"
OUT="${3:-/tmp/review-packet.txt}"
TASK_ID_VALUE="${TASK_ID_VALUE:-unknown}"
PR_NUMBER_VALUE="${PR_NUMBER_VALUE:-unknown}"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-$HEAD_REF}"
ROUND_VALUE="${ROUND_VALUE:-unknown}"
MAX_PACKET_BYTES=42000
GENERIC_EXCERPT_BYTES=3200

changed_paths="$(git diff --name-only "$BASE_REF...$HEAD_REF")"

show_file() {
  git show "$HEAD_REF:$1"
}

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
  local peel_lab smoke_scene smoke_reference start end
  peel_lab="$(show_file scripts/peel_lab.gd)"
  smoke_scene="$(show_file tests/smoke_scene.gd)"
  smoke_reference="$(show_file tests/smoke_reference_scene.gd)"
  {
    echo '=== HUD PRESENTATION CONTRACT ==='
    show_file scripts/presentation/hud_chrome_presentation.gd
    echo '=== HUD DETERMINISTIC CONTRACT ==='
    show_file tests/test_hud_chrome_presentation.gd
    echo '=== GAMEPLAY HUD SOURCE ==='
    start="$(printf '%s\n' "$peel_lab" | grep -n '^func _update_hud' | head -n1 | cut -d: -f1)"
    if [ -n "$start" ]; then
      end=$((start + 78))
      printf '%s\n' "$peel_lab" | sed -n "${start},${end}p"
    fi
    echo '=== PLAYABLE HUD SMOKE ==='
    printf '%s\n' "$smoke_scene" | grep -n -B 4 -A 8 -E 'player HUD|hud_text|reset and pause affordances' || true
    echo '=== REFERENCE HUD SMOKE ==='
    printf '%s\n' "$smoke_reference" | grep -n -B 4 -A 8 -E 'reference HUD|hud_text' || true
  } >> "$OUT"
}

append_hand_contracts() {
  {
    echo '=== DIRECT PRESENTATION/INTERACTION CONTRACTS ==='
    show_file scripts/presentation/hand_choreography_presentation.gd
    show_file scripts/hands/hand_visual.gd | sed -n '1,230p'
    echo '=== GAMEPLAY HAND OWNERSHIP CONTRACT ==='
    show_file scripts/peel_lab.gd | sed -n '1,145p'
    echo '=== REFERENCE CAPTURE CONTRACT ==='
    show_file tests/capture_reference_frames.gd
    echo '=== HAND REGRESSION CONTRACTS ==='
    show_file tests/test_hand_visual.gd
    show_file tests/test_authored_hand_asset.gd
  } >> "$OUT"
}

append_generic_contracts() {
  {
    echo '=== CHANGED PRODUCTION/TEST FILE EXCERPTS ==='
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      case "$path" in
        scripts/*.gd|scripts/**/*.gd|tests/*.gd|tests/**/*.gd)
          if git cat-file -e "$HEAD_REF:$path" 2>/dev/null; then
            echo "--- $path ---"
            # `head -c` intentionally closes the pipe once the evidence budget
            # is reached. Under `set -o pipefail`, git-show then receives
            # SIGPIPE (141), so explicitly accept that expected bounded-read
            # termination while still retaining evidence from every file.
            show_file "$path" | head -c "$GENERIC_EXCERPT_BYTES" || true
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
if [ "$bytes" -ge "$MAX_PACKET_BYTES" ]; then
  echo "review packet exceeds ${MAX_PACKET_BYTES}-byte safety budget" >&2
  exit 1
fi
