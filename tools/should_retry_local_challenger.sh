#!/usr/bin/env bash
set -euo pipefail

code="${1:?usage: should_retry_local_challenger.sh FAILURE_EXIT_CODE}"
case "$code" in
  # 4 is the formatter/extractor failure used when a small local model ignores
  # the structured-output contract and emits prose/code with no usable JSON.
  # 42-46 are strict grounding-validator failures. All are safe to retry once;
  # the second pass still fails closed through the same validator.
  4|42|43|44|45|46)
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
