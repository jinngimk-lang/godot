#!/usr/bin/env python3
"""Repair only a model-added trailing punctuation mark on grounded anchors.

The local Challenger normalizer is intentionally strict: NEEDS_FIX must quote
verbatim code/test evidence from the exact review packet. Small local models
occasionally copy a real source line and append sentence punctuation (for
example a comma) that is not in the source. This helper may remove exactly one
trailing punctuation character *only* when the repaired anchor occurs exactly
once in the exact packet. It never fuzzy-matches internal whitespace or text.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ALLOWED_TRAILING = {",", ";", ":", "."}


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: resolve_local_challenger_anchor.py VERDICT_JSON REVIEW_PACKET", file=sys.stderr)
        return 2

    verdict_path = Path(sys.argv[1])
    packet_path = Path(sys.argv[2])
    data = json.loads(verdict_path.read_text(encoding="utf-8"))

    if data.get("verdict") != "NEEDS_FIX":
        return 0

    anchor = data.get("evidence_anchor")
    if not isinstance(anchor, str) or len(anchor) < 16:
        return 0

    packet = packet_path.read_text(encoding="utf-8")
    if anchor in packet:
        return 0

    if anchor[-1] not in ALLOWED_TRAILING:
        return 0

    candidate = anchor[:-1]
    if len(candidate) < 16:
        return 0

    # Preserve strict grounding: only repair an unambiguous exact substring.
    if packet.count(candidate) != 1:
        return 0

    data["evidence_anchor"] = candidate
    verdict_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Resolved one trailing anchor punctuation: {anchor!r} -> {candidate!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
