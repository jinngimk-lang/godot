#!/usr/bin/env python3
"""Parse the local Challenger's strict five-line final report into JSON.

The small local model may reason in prose, but the acceptance boundary is
fully deterministic: exactly one final protocol block, then the existing
packet-grounding validator decides whether a NEEDS_FIX claim is supported.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

FIELDS = (
    "PROVISIONAL_VERDICT",
    "DEFECT",
    "MIN_TEST",
    "EVIDENCE",
    "EVIDENCE_ANCHOR",
)


def fail(message: str, code: int = 4) -> "NoReturn":
    print(f"challenger report parse failed: {message}", file=sys.stderr)
    raise SystemExit(code)


def normalize_none(value: str) -> bool:
    return value.strip().lower() in {
        "none",
        "n/a",
        "na",
        "no defect",
        "no concrete defect",
        "no concrete defect found",
    }


def main() -> None:
    if len(sys.argv) != 3:
        fail("usage: extract_local_challenger_report.py ANALYSIS OUTPUT_JSON", 2)

    source = pathlib.Path(sys.argv[1])
    output = pathlib.Path(sys.argv[2])
    text = source.read_text(encoding="utf-8", errors="replace")
    lines = [line.rstrip("\r\n") for line in text.splitlines()]
    nonempty = [i for i, line in enumerate(lines) if line.strip()]
    if not nonempty:
        fail("empty model response")

    verdict_indices = [
        i for i, line in enumerate(lines)
        if line.startswith("PROVISIONAL_VERDICT:")
    ]
    if len(verdict_indices) != 1:
        fail(f"expected exactly one PROVISIONAL_VERDICT line, got {len(verdict_indices)}")

    start = verdict_indices[0]
    # The protocol is explicitly a final block. Reject a verdict embedded in
    # middle-of-analysis prose because that makes later contradictory prose
    # impossible to reason about deterministically.
    trailing_nonempty = [i for i in nonempty if i >= start]
    if len(trailing_nonempty) != len(FIELDS):
        fail("final protocol must contain exactly five non-empty lines and nothing after it")

    values: dict[str, str] = {}
    for expected, line_index in zip(FIELDS, trailing_nonempty):
        line = lines[line_index]
        prefix = expected + ":"
        if not line.startswith(prefix):
            fail(f"expected final field {expected}, got: {line[:120]}")
        value = line[len(prefix):].strip()
        if not value:
            fail(f"empty final field {expected}")
        values[expected] = value

    verdict = values["PROVISIONAL_VERDICT"]
    if verdict not in {"VERIFIED", "NEEDS_FIX"}:
        fail(f"unsupported verdict {verdict!r}")

    defect = values["DEFECT"]
    min_test = values["MIN_TEST"]
    evidence = values["EVIDENCE"]
    anchor = values["EVIDENCE_ANCHOR"]

    if verdict == "VERIFIED":
        if not normalize_none(defect):
            fail("VERIFIED must use DEFECT: NONE")
        if not normalize_none(min_test):
            fail("VERIFIED must use MIN_TEST: NONE")
        if anchor != "NO_CONCRETE_DEFECT":
            fail("VERIFIED must use EVIDENCE_ANCHOR: NO_CONCRETE_DEFECT")
        if len(evidence) < 12:
            fail("VERIFIED evidence is too short")
    else:
        if len(defect) < 12:
            fail("NEEDS_FIX defect is too short")
        if len(min_test) < 16 or re.fullmatch(r"[0-9 ._-]+", min_test):
            fail("NEEDS_FIX min_test must be a concrete falsifiable regression check")
        if len(evidence) < 12:
            fail("NEEDS_FIX evidence is too short")
        if not 16 <= len(anchor) <= 240:
            fail("NEEDS_FIX evidence anchor must be 16-240 characters")
        if anchor.startswith("===") or anchor.startswith("---"):
            fail("NEEDS_FIX evidence anchor cannot be a packet heading")

    payload = {
        "verdict": verdict,
        "defect": defect,
        "min_test": min_test,
        "evidence": evidence,
        "evidence_anchor": anchor,
    }
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
