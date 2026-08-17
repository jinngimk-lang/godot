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
mkdir -p scripts tests

# Create five large changed files whose actual diff is small. This models a
# normal visual/product PR where full-file excerpts, not the patch itself,
# are what can push the local model packet over its strict safety budget.
for path in scripts/a.gd scripts/b.gd scripts/c.gd tests/a.gd tests/b.gd; do
  {
    echo 'extends RefCounted'
    echo 'const REVISION := "base"'
    for i in $(seq 1 420); do
      printf 'var field_%03d := "stable context line %03d for challenger packet sizing"\n' "$i" "$i"
    done
  } > "$path"
done

git add .
git commit -qm base
base="$(git rev-parse HEAD)"

for path in scripts/a.gd scripts/b.gd scripts/c.gd tests/a.gd tests/b.gd; do
  sed -i 's/const REVISION := "base"/const REVISION := "candidate"/' "$path"
done

git add .
git commit -qm candidate
head="$(git rev-parse HEAD)"

TASK_ID_VALUE=1 PR_NUMBER_VALUE=1 EXPECTED_HEAD_VALUE="$head" ROUND_VALUE=1 \
  bash "$tmp/build_local_challenger_packet.sh" "$base" "$head" "$tmp/packet.txt"

bytes="$(wc -c < "$tmp/packet.txt")"
if [ "$bytes" -ge 42000 ]; then
  echo "packet self-test exceeded budget: $bytes" >&2
  exit 1
fi

# The bounded generic packet must still contain evidence from every changed
# file rather than solving the limit by dropping tail files wholesale.
for path in scripts/a.gd scripts/b.gd scripts/c.gd tests/a.gd tests/b.gd; do
  grep -Fq -- "--- $path ---" "$tmp/packet.txt" || {
    echo "packet self-test lost changed-file evidence for $path" >&2
    exit 1
  }
done

grep -Fq 'const REVISION := "candidate"' "$tmp/packet.txt"
echo "Local Challenger packet budget self-test PASS ($bytes bytes)"
