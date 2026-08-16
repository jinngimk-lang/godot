#!/usr/bin/env python3
"""Strictly normalize a local Challenger model response into one JSON object.

Accept either a raw JSON object or the same object wrapped in one Markdown code
fence. Reject prose-wrapped/fuzzy content so verifier failures remain fail-closed.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def _parse_object(text: str) -> dict:
    try:
        value = json.loads(text)
    except json.JSONDecodeError:
        match = re.fullmatch(
            r"\s*```(?:json)?\s*\n?(\{.*\})\s*\n?```\s*",
            text,
            flags=re.DOTALL | re.IGNORECASE,
        )
        if match is None:
            raise ValueError("response is neither raw JSON nor one fenced JSON object")
        try:
            value = json.loads(match.group(1))
        except json.JSONDecodeError as exc:
            raise ValueError(f"fenced response contains invalid JSON: {exc}") from exc

    if not isinstance(value, dict):
        raise ValueError("normalized Challenger response must be a JSON object")
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
