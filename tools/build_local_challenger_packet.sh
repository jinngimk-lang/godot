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
EXACT_DIFF_TOTAL_BYTES=12000
GENERIC_EXCERPT_TOTAL_BYTES=18000
HAND_CONTRACT_TOTAL_BYTES=18000
MAX_DIFF_PER_FILE_BYTES=3600
MAX_EXCERPT_PER_FILE_BYTES=3200
MAX_HAND_CONTRACT_FILE_BYTES=3200

changed_paths="$(git diff --name-only "$BASE_REF...$HEAD_REF")"

show_file() {
  git show "$HEAD_REF:$1"
}

nonempty_line_count() {
  local text="$1"
  local count
  count="$(printf '%s\n' "$text" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
  printf '%s\n' "${count:-0}"
}

bounded_bytes() {
  local path="$1"
  local limit="$2"
  if [ "$limit" -le 0 ]; then
    return 0
  fi
  if [ "$(wc -c < "$path")" -le "$limit" ]; then
    cat "$path"
  else
    head -c "$limit" "$path"
    printf '\n[bounded evidence excerpt truncated at %s bytes]\n' "$limit"
  fi
}

append_bounded_exact_diffs() {
  local changed_count per_file path tmp
  changed_count="$(nonempty_line_count "$changed_paths")"
  [ "$changed_count" -gt 0 ] || return 0
  per_file=$((EXACT_DIFF_TOTAL_BYTES / changed_count))
  if [ "$per_file" -gt "$MAX_DIFF_PER_FILE_BYTES" ]; then
    per_file="$MAX_DIFF_PER_FILE_BYTES"
  fi
  if [ "$per_file" -lt 500 ]; then
    per_file=500
  fi

  echo '=== EXACT PR DIFF (BOUNDED PER CHANGED FILE) ===' >> "$OUT"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    echo "--- EXACT DIFF: $path ---" >> "$OUT"
    tmp="$(mktemp)"
    git diff --unified=8 "$BASE_REF...$HEAD_REF" -- "$path" > "$tmp"
    bounded_bytes "$tmp" "$per_file" >> "$OUT"
    rm -f "$tmp"
    echo >> "$OUT"
  done <<< "$changed_paths"
}

append_header() {
  {
    echo "TASK_ID=$TASK_ID_VALUE"
    echo "PR_NUMBER=$PR_NUMBER_VALUE"
    echo "EXPECTED_HEAD_SHA=$EXPECTED_HEAD_VALUE"
    echo "ROUND=$ROUND_VALUE"
    echo '=== CHANGE STAT ==='
    git diff --stat "$BASE_REF...$HEAD_REF"
    echo '=== CHANGED PATHS ==='
    printf '%s\n' "$changed_paths"
  } > "$OUT"
  append_bounded_exact_diffs
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
  local -a contract_paths=(
    scripts/presentation/hand_choreography_presentation.gd
    scripts/hands/hand_visual.gd
    scripts/peel_lab.gd
    tests/capture_reference_frames.gd
    tests/test_hand_visual.gd
    tests/test_authored_hand_asset.gd
  )
  local existing_count=0 per_file path tmp
  for path in "${contract_paths[@]}"; do
    if git cat-file -e "$HEAD_REF:$path" 2>/dev/null; then
      existing_count=$((existing_count + 1))
    fi
  done
  [ "$existing_count" -gt 0 ] || return 0

  per_file=$((HAND_CONTRACT_TOTAL_BYTES / existing_count))
  if [ "$per_file" -gt "$MAX_HAND_CONTRACT_FILE_BYTES" ]; then
    per_file="$MAX_HAND_CONTRACT_FILE_BYTES"
  fi
  if [ "$per_file" -lt 500 ]; then
    per_file=500
  fi

  echo '=== DIRECT PRESENTATION/INTERACTION CONTRACTS (BOUNDED) ===' >> "$OUT"
  for path in "${contract_paths[@]}"; do
    if ! git cat-file -e "$HEAD_REF:$path" 2>/dev/null; then
      continue
    fi
    echo "--- HAND CONTRACT: $path ---" >> "$OUT"
    tmp="$(mktemp)"
    case "$path" in
      scripts/hands/hand_visual.gd)
        show_file "$path" | sed -n '1,230p' > "$tmp"
        ;;
      scripts/peel_lab.gd)
        show_file "$path" | sed -n '1,145p' > "$tmp"
        ;;
      *)
        show_file "$path" > "$tmp"
        ;;
    esac
    bounded_bytes "$tmp" "$per_file" >> "$OUT"
    rm -f "$tmp"
    echo >> "$OUT"
  done
}

append_generic_contracts() {
  local code_paths code_count per_file path tmp
  code_paths="$(printf '%s\n' "$changed_paths" | grep -E '^(scripts|tests)/.*\.gd$' || true)"
  code_count="$(nonempty_line_count "$code_paths")"
  [ "$code_count" -gt 0 ] || return 0
  per_file=$((GENERIC_EXCERPT_TOTAL_BYTES / code_count))
  if [ "$per_file" -gt "$MAX_EXCERPT_PER_FILE_BYTES" ]; then
    per_file="$MAX_EXCERPT_PER_FILE_BYTES"
  fi
  if [ "$per_file" -lt 500 ]; then
    per_file=500
  fi

  echo '=== CHANGED PRODUCTION/TEST HEAD EXCERPTS ===' >> "$OUT"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if git cat-file -e "$HEAD_REF:$path" 2>/dev/null; then
      echo "--- HEAD EXCERPT: $path ---" >> "$OUT"
      tmp="$(mktemp)"
      show_file "$path" > "$tmp"
      bounded_bytes "$tmp" "$per_file" >> "$OUT"
      rm -f "$tmp"
      echo >> "$OUT"
    fi
  done <<< "$code_paths"
}

append_header

if printf '%s\n' "$changed_paths" | grep -Eq '(^|/)(hud_chrome_presentation\.gd|test_hud_chrome_presentation\.gd)$'; then
  append_hud_contracts
# A capture fixture may be edited for residue, table, glass, HUD, or other
# presentation evidence. That file alone must not route the packet into the
# broader hand-contract bundle. Exact diff + HEAD excerpt already preserve the
# capture change in the generic packet. Only actual hand/pose/grip paths opt
# into hand ownership context, and that context is itself byte-bounded so a
# legitimate multi-file hand batch cannot fail before the reviewer runs.
elif printf '%s\n' "$changed_paths" | grep -Eq '(hand_visual|hand_choreography|authored_hand|reference.*hand|peel.*grip|partial.*peel)'; then
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
