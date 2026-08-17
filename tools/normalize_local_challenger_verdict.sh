#!/usr/bin/env bash
set -euo pipefail

ANALYSIS_FILE="${1:?usage: normalize_local_challenger_verdict.sh ANALYSIS PACKET OUTPUT_JSON}"
PACKET_FILE="${2:?usage: normalize_local_challenger_verdict.sh ANALYSIS PACKET OUTPUT_JSON}"
OUTPUT_JSON="${3:?usage: normalize_local_challenger_verdict.sh ANALYSIS PACKET OUTPUT_JSON}"

MODEL="qwen2.5-coder:3b"
EXTRACTOR="${EXTRACTOR:-/tmp/extract-local-challenger-json.py}"
VALIDATOR="${VALIDATOR:-/tmp/validate-local-challenger-verdict.sh}"
RETRY_CLASSIFIER="${RETRY_CLASSIFIER:-/tmp/should-retry-local-challenger.sh}"

analysis="$(head -c 12000 "$ANALYSIS_FILE")"
packet="$(head -c 26000 "$PACKET_FILE")"
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
      prompt:("Normalize this independent adversarial review into a verdict. Do not invent a defect unsupported by the analysis or exact packet. If the analysis identifies a concrete reproducible defect, verdict must be NEEDS_FIX only when the packet contains direct evidence for it. For NEEDS_FIX, evidence_anchor MUST be a contiguous 16-240 character verbatim quote copied from the packet that directly demonstrates the claimed defect; do not use section headings, unrelated pre-existing code, or a quote that contradicts the claim. If no such direct anchor exists, return VERIFIED rather than inventing a defect. For VERIFIED, set evidence_anchor to NO_CONCRETE_DEFECT. Return only the requested JSON object; no prose and no Markdown fence. " + $retry_note + "\nContext:\n" + $context + "\nAnalysis:\n" + $analysis + "\nExact packet excerpt:\n" + $packet),
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
normalize_once /tmp/normalize-request.json /tmp/normalize-response.json /tmp/verdict-first.json

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
retry_note="The previous structured attempt was rejected by the strict grounding validator. Re-evaluate once; do not repeat or paraphrase the rejected anchor. If you cannot copy a direct 16-240 character packet quote that proves a concrete defect, you MUST return VERIFIED with evidence_anchor NO_CONCRETE_DEFECT. Previous structured attempt: $first_verdict Validator rejection: $validator_reason"
make_request "$retry_note" > /tmp/normalize-retry-request.json
normalize_once /tmp/normalize-retry-request.json /tmp/normalize-retry-response.json /tmp/verdict-retry.json

# Second pass remains fail-closed. A second unsupported claim is still infra failure.
bash "$VALIDATOR" /tmp/verdict-retry.json "$PACKET_FILE"
cp /tmp/verdict-retry.json "$OUTPUT_JSON"
