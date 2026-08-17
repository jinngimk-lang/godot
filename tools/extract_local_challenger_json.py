#!/usr/bin/env python3
"""Normalize a local Challenger model response into one JSON verdict object.

Formatting tolerance is intentionally separate from verdict grounding. Accept a
raw object, one fenced object, or exactly one flat JSON object surrounded by
non-JSON prose. Reject zero/multiple object envelopes. The downstream strict
validator still decides whether NEEDS_FIX evidence is grounded in the exact
review packet.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def _load_dict(candidate: str, label: str) -> dict:
    try:
        value = json.loads(candidate)
    except json.JSONDecodeError as exc:
        raise ValueError(f"{label} contains invalid JSON: {exc}") from exc
    if not isinstance(value, dict):
        raise ValueError("normalized Challenger response must be a JSON object")
    return value


def _parse_object(text: str) -> dict:
    stripped = text.strip()
    try:
        return _load_dict(stripped, "raw response")
    except ValueError:
        pass

    fenced = re.fullmatch(
        r"```(?:json)?\s*\n?(\{.*\})\s*\n?```",
        stripped,
        flags=re.DOTALL | re.IGNORECASE,
    )
    if fenced is not None:
        return _load_dict(fenced.group(1), "fenced response")

    # Small local models sometimes obey the schema but add a sentence before
    # or after it. Accept exactly one outer JSON object envelope while keeping
    # the semantic gate fail-closed in validate_local_challenger_verdict.sh.
    first = text.find("{")
    last = text.rfind("}")
    if first < 0 or last <= first:
        raise ValueError("response contains no JSON object envelope")

    prefix = text[:first]
    suffix = text[last + 1 :]
    if "{" in prefix or "}" in prefix or "{" in suffix or "}" in suffix:
        raise ValueError("response contains multiple JSON object envelopes")

    value = _load_dict(text[first : last + 1], "embedded response")
    return value


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: extract_local_challenger_json.py INPUT OUTPUT", file=sys.stderr)
        return 2

    source = Path(sys.argv[1])
    destination = Path(sys.argv[2])
    try:
        value = _parse_object(source.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        print(f"challenger JSON normalization failed: {exc}", file=sys.stderr)
        return 4

    destination.write_text(json.dumps(value, separators=(",", ":")) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
