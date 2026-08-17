#!/usr/bin/env bash
set -euo pipefail

code="${1:?usage: should_retry_local_challenger.sh VALIDATOR_EXIT_CODE}"
case "$code" in
  42|43|44|45|46)
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
