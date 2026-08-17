#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
builder="$repo_root/tools/build_local_challenger_packet.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cp "$builder" "$tmp/build_local_challenger_packet.sh"
cd "$tmp"
git init -q
git config user.email challenger-test@example.invalid
git config user.name ChallengerPacketTest
mkdir -p scripts/presentation scripts/peel scripts/session scripts/hands tests

# Model a real fast visual batch: several production/test files all carry
# meaningful edits, so the exact patch itself is much larger than the model's
# 42 KB packet ceiling. The packet builder must bound evidence per changed file
# rather than fail or silently drop tail files.
paths=(
  scripts/presentation/a.gd
  scripts/presentation/b.gd
  scripts/peel/a.gd
  scripts/session/a.gd
  tests/a.gd
  tests/b.gd
  tests/c.gd
  tests/d.gd
)

for path in "${paths[@]}"; do
  {
    echo 'extends RefCounted'
    echo 'const REVISION := "base"'
    for i in $(seq 1 190); do
      printf 'var field_%03d := "base evidence line %03d with enough text to create a genuinely large product diff"\n' "$i" "$i"
    done
  } > "$path"
done

git add .
git commit -qm base
base="$(git rev-parse HEAD)"

for path in "${paths[@]}"; do
  sed -i 's/const REVISION := "base"/const REVISION := "candidate"/' "$path"
  sed -i 's/base evidence line/candidate evidence line/g' "$path"
done

git add .
git commit -qm candidate
head="$(git rev-parse HEAD)"

raw_diff_bytes="$(git diff "$base...$head" | wc -c)"
if [ "$raw_diff_bytes" -le 42000 ]; then
  echo "packet self-test fixture is not large enough: raw diff=$raw_diff_bytes" >&2
  exit 1
fi

TASK_ID_VALUE=1 PR_NUMBER_VALUE=1 EXPECTED_HEAD_VALUE="$head" ROUND_VALUE=1 \
  bash "$tmp/build_local_challenger_packet.sh" "$base" "$head" "$tmp/packet.txt"

bytes="$(wc -c < "$tmp/packet.txt")"
if [ "$bytes" -ge 42000 ]; then
  echo "packet self-test exceeded budget: $bytes" >&2
  exit 1
fi

# Every changed file must retain both a bounded exact-diff section and a head
# evidence excerpt. This prevents a budget fix from just chopping off later
# files and making evidence anchoring impossible for part of the batch.
for path in "${paths[@]}"; do
  grep -Fq -- "--- EXACT DIFF: $path ---" "$tmp/packet.txt" || {
    echo "packet self-test lost exact-diff evidence for $path" >&2
    exit 1
  }
  grep -Fq -- "--- HEAD EXCERPT: $path ---" "$tmp/packet.txt" || {
    echo "packet self-test lost head excerpt for $path" >&2
    exit 1
  }
done

grep -Fq 'const REVISION := "candidate"' "$tmp/packet.txt"
echo "Local Challenger large-batch packet self-test PASS (raw=$raw_diff_bytes packet=$bytes bytes)"

# Capture fixtures are shared evidence infrastructure. Editing the capture file
# alone must remain a generic exact-diff review; otherwise residue/table/glass
# batches accidentally pull the entire hand contract bundle and exceed budget.
capture_base="$head"
cat > tests/capture_reference_frames.gd <<'CAPTURE'
extends SceneTree
func _stage_inspect() -> void:
    print("residue evidence stays detached")
CAPTURE
git add tests/capture_reference_frames.gd
git commit -qm capture-only
capture_head="$(git rev-parse HEAD)"
TASK_ID_VALUE=2 PR_NUMBER_VALUE=2 EXPECTED_HEAD_VALUE="$capture_head" ROUND_VALUE=1 \
  bash "$tmp/build_local_challenger_packet.sh" "$capture_base" "$capture_head" "$tmp/capture-packet.txt"

grep -Fq -- '--- EXACT DIFF: tests/capture_reference_frames.gd ---' "$tmp/capture-packet.txt"
grep -Fq -- '--- HEAD EXCERPT: tests/capture_reference_frames.gd ---' "$tmp/capture-packet.txt"
if grep -Fq '=== DIRECT PRESENTATION/INTERACTION CONTRACTS' "$tmp/capture-packet.txt"; then
  echo 'capture-only packet incorrectly routed into hand-contract bundle' >&2
  exit 1
fi
echo "Local Challenger capture-only routing self-test PASS ($(wc -c < "$tmp/capture-packet.txt") bytes)"

# Hand ownership batches legitimately need broader context, but that context
# must also remain bounded. Before this regression test, changing
# hand_choreography pulled whole capture/hand contract files and could exceed
# the packet ceiling before Ollama ever ran.
hand_base="$capture_head"
hand_contract_paths=(
  scripts/presentation/hand_choreography_presentation.gd
  scripts/hands/hand_visual.gd
  scripts/peel_lab.gd
  tests/capture_reference_frames.gd
  tests/test_hand_visual.gd
  tests/test_authored_hand_asset.gd
)
for path in "${hand_contract_paths[@]}"; do
  mkdir -p "$(dirname "$path")"
  {
    echo 'extends RefCounted'
    echo 'const HAND_REVISION := "base"'
    for i in $(seq 1 220); do
      printf 'var hand_line_%03d := "bounded hand contract context %03d for independent exact-head review"\n' "$i" "$i"
    done
  } > "$path"
done
git add .
git commit -qm hand-contract-base
hand_base="$(git rev-parse HEAD)"
sed -i 's/const HAND_REVISION := "base"/const HAND_REVISION := "candidate"/' scripts/presentation/hand_choreography_presentation.gd
cat >> scripts/presentation/hand_choreography_presentation.gd <<'HANDCHANGE'
func _cafe_crumple_owns_peel_hand() -> bool:
    return true
HANDCHANGE
git add scripts/presentation/hand_choreography_presentation.gd
git commit -qm hand-contract-candidate
hand_head="$(git rev-parse HEAD)"
TASK_ID_VALUE=3 PR_NUMBER_VALUE=3 EXPECTED_HEAD_VALUE="$hand_head" ROUND_VALUE=1 \
  bash "$tmp/build_local_challenger_packet.sh" "$hand_base" "$hand_head" "$tmp/hand-packet.txt"

grep -Fq -- '--- EXACT DIFF: scripts/presentation/hand_choreography_presentation.gd ---' "$tmp/hand-packet.txt"
grep -Fq -- '=== DIRECT PRESENTATION/INTERACTION CONTRACTS (BOUNDED) ===' "$tmp/hand-packet.txt"
for path in "${hand_contract_paths[@]}"; do
  grep -Fq -- "--- HAND CONTRACT: $path ---" "$tmp/hand-packet.txt" || {
    echo "hand packet lost bounded context for $path" >&2
    exit 1
  }
done
hand_bytes="$(wc -c < "$tmp/hand-packet.txt")"
if [ "$hand_bytes" -ge 42000 ]; then
  echo "hand packet self-test exceeded budget: $hand_bytes" >&2
  exit 1
fi
echo "Local Challenger hand-route packet self-test PASS ($hand_bytes bytes)"
