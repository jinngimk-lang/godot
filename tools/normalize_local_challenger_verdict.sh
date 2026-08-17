#!/usr/bin/env bash
set -euo pipefail

ANALYSIS_FILE="${1:?usage: normalize_local_challenger_verdict.sh ANALYSIS PACKET OUTPUT_JSON}"
PACKET_FILE="${2:?usage: normalize_local_challenger_verdict.sh ANALYSIS PACKET OUTPUT_JSON}"
OUTPUT_JSON="${3:?usage: normalize_local_challenger_verdict.sh ANALYSIS PACKET OUTPUT_JSON}"

MODEL="qwen2.5-coder:3b"
EXTRACTOR="${EXTRACTOR:-/tmp/extract-local-challenger-json.py}"
VALIDATOR="${VALIDATOR:-/tmp/validate-local-challenger-verdict.sh}"
RETRY_CLASSIFIER="${RETRY_CLASSIFIER:-/tmp/should-retry-local-challenger.sh}"

# The prose pass is untrusted brainstorming from the same small model. Keep only
# its tail (where the provisional conclusion should live) and make the exact PR
# packet the dominant source of truth for the structured verdict.
analysis="$(tail -c 6500 "$ANALYSIS_FILE")"
packet="$(head -c 22000 "$PACKET_FILE")"
context="$(git diff --stat origin/main...HEAD; git diff --name-only origin/main...HEAD)"

make_request() {
  local retry_note="${1:-}"
  jq -n \
    --arg analysis "$analysis" \
    --arg context "$context" \
    --arg packet "$packet" \
    --arg retry_note "$retry_note" \
    '{
      model:"qwen2.5-coder:3b",
      stream:false,
      prompt:("Produce the grounded verdict for this exact PR packet. The adversarial analysis is UNTRUSTED brainstorming and may contain hallucinated functions, classes, code or conclusions. Never rely on an analysis identifier unless it appears verbatim in the exact packet. Do not write replacement code. Do not emit a Markdown fence or prose outside the JSON object. If the analysis identifies a concrete reproducible defect, verdict may be NEEDS_FIX only when the packet contains direct evidence for it. For NEEDS_FIX, evidence_anchor MUST be a contiguous 16-240 character verbatim quote copied from the packet that directly demonstrates the claimed defect; do not use section headings, unrelated pre-existing code, or a quote that contradicts the claim. min_test must describe a concrete falsifiable regression check, not a number or vague request. If no direct packet anchor proves a concrete defect, return VERIFIED rather than inventing one. For VERIFIED, set evidence_anchor to NO_CONCRETE_DEFECT. " + $retry_note + "\nContext:\n" + $context + "\nUntrusted adversarial notes:\n" + $analysis + "\nExact packet excerpt (source of truth):\n" + $packet),
      format:{
        type:"object",
        properties:{
          verdict:{type:"string",enum:["VERIFIED","NEEDS_FIX"]},
          defect:{type:"string"},
          min_test:{type:"string"},
          evidence:{type:"string"},
          evidence_anchor:{type:"string"}
        },
        required:["verdict","defect","min_test","evidence","evidence_anchor"],
        additionalProperties:false
      }
    }'
}

normalize_once() {
  local request_file="$1"
  local response_file="$2"
  local verdict_file="$3"
  curl -fsS http://127.0.0.1:11434/api/generate \
    -H 'Content-Type: application/json' \
    --data-binary "@$request_file" > "$response_file"
  jq -er '.response' "$response_file" > /tmp/verdict-response.txt
  python3 "$EXTRACTOR" /tmp/verdict-response.txt "$verdict_file"
}

make_request "" > /tmp/normalize-request.json
set +e
normalize_once /tmp/normalize-request.json /tmp/normalize-response.json /tmp/verdict-first.json 2> /tmp/normalize-first.err
normalize_rc=$?
set -e

# Formatting failures used to abort under `set -e` before the existing strict
# retry path could run. Retry one malformed structured response with an even
# narrower instruction, then still pass the result through the same fail-closed
# grounding validator. Network/runtime failures outside the allow-list remain
# infrastructure failures.
if [ "$normalize_rc" -ne 0 ]; then
  if ! bash "$RETRY_CLASSIFIER" "$normalize_rc"; then
    cat /tmp/normalize-first.err >&2
    exit "$normalize_rc"
  fi
  normalize_reason="$(head -c 1200 /tmp/normalize-first.err)"
  retry_note="The previous structured response was unusable (exit $normalize_rc): $normalize_reason. This is the only retry. Ignore any invented code in the adversarial notes. Return exactly one JSON object matching the schema. If no concrete defect is proven by a verbatim exact-packet quote, return VERIFIED with evidence_anchor NO_CONCRETE_DEFECT."
  make_request "$retry_note" > /tmp/normalize-retry-request.json
  normalize_once /tmp/normalize-retry-request.json /tmp/normalize-retry-response.json /tmp/verdict-retry.json
  bash "$VALIDATOR" /tmp/verdict-retry.json "$PACKET_FILE"
  cp /tmp/verdict-retry.json "$OUTPUT_JSON"
  exit 0
fi

set +e
bash "$VALIDATOR" /tmp/verdict-first.json "$PACKET_FILE" 2> /tmp/validator-first.err
validator_rc=$?
set -e

if [ "$validator_rc" -eq 0 ]; then
  cp /tmp/verdict-first.json "$OUTPUT_JSON"
  exit 0
fi

if ! bash "$RETRY_CLASSIFIER" "$validator_rc"; then
  cat /tmp/validator-first.err >&2
  exit "$validator_rc"
fi

validator_reason="$(head -c 1200 /tmp/validator-first.err)"
first_verdict="$(cat /tmp/verdict-first.json)"
retry_note="The previous structured attempt was rejected by the strict grounding validator. Re-evaluate once; do not repeat or paraphrase the rejected anchor. Treat the adversarial notes as untrusted. If you cannot copy a direct 16-240 character packet quote that proves a concrete defect, you MUST return VERIFIED with evidence_anchor NO_CONCRETE_DEFECT. Previous structured attempt: $first_verdict Validator rejection: $validator_reason"
make_request "$retry_note" > /tmp/normalize-retry-request.json
normalize_once /tmp/normalize-retry-request.json /tmp/normalize-retry-response.json /tmp/verdict-retry.json

# Second pass remains fail-closed. A second unsupported claim is still infra failure.
bash "$VALIDATOR" /tmp/verdict-retry.json "$PACKET_FILE"
cp /tmp/verdict-retry.json "$OUTPUT_JSON"
