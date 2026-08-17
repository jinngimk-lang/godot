#!/usr/bin/env python3
"""Parse the local Challenger's small labelled final report into JSON.

The model may reason in prose and may add harmless Markdown decoration or one
trailing sentence. Acceptance remains deterministic: each protocol field must
appear exactly once, then the existing exact-packet validator decides whether a
NEEDS_FIX claim is grounded. Duplicate/conflicting fields still fail closed.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys
from typing import NoReturn

FIELDS = (
    "PROVISIONAL_VERDICT",
    "DEFECT",
    "MIN_TEST",
    "EVIDENCE",
    "EVIDENCE_ANCHOR",
)

# Accept the common harmless formats a local model emits despite a plain-text
# protocol request: `FIELD: value`, `FIELD value`, optional list prefixes, and
# optional Markdown bold decoration. Each field must still occur exactly once.
FIELD_RE = re.compile(
    r"^\s*(?:[-*+]\s+)?(?:\*\*)?(PROVISIONAL_VERDICT|DEFECT|MIN_TEST|EVIDENCE|EVIDENCE_ANCHOR)(?:\*\*)?\s*(?::(?:\*\*)?\s*|\s+)(.+?)\s*$"
)


def fail(message: str, code: int = 4) -> NoReturn:
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
    if not text.strip():
        fail("empty model response")

    found: dict[str, list[str]] = {field: [] for field in FIELDS}
    for raw_line in text.splitlines():
        match = FIELD_RE.match(raw_line)
        if not match:
            continue
        field, value = match.group(1), match.group(2).strip()
        if not value:
            fail(f"empty final field {field}")
        found[field].append(value)

    for field in FIELDS:
        count = len(found[field])
        if count != 1:
            fail(f"expected exactly one {field} line, got {count}")

    values = {field: found[field][0] for field in FIELDS}
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
    output.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
