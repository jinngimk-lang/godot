#!/usr/bin/env python3
"""Extract a tiny, explicit set of CC0 MakeHuman Poses02 candidates for visual screening.

This is source-only staging. It never imports, retargets, or writes the Peel Calm
GameEngine rig. The only purpose is to ask whether an official human-authored source
pose visibly contains the cylindrical-grip anatomy missing from the current support hand.
"""
from __future__ import annotations

import hashlib
import json
import sys
import zipfile
from pathlib import Path

TOKENS = (
    "henny_cyclist_normal",
    "punkduck_cyclist01",
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for block in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def main() -> int:
    if len(sys.argv) != 4:
        raise SystemExit("usage: extract_makehuman_pose_sources_v56.py PACK.zip OUT_DIR REPORT.json")
    pack = Path(sys.argv[1])
    out = Path(sys.argv[2])
    report_path = Path(sys.argv[3])
    out.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    selected: dict[str, dict] = {}
    with zipfile.ZipFile(pack) as zf:
        names = zf.namelist()
        for token in TOKENS:
            # Poses02 includes henny_cyclist_normal and henny_cyclist_normal_tough.
            # Match the pose directory exactly so a substring cannot silently select an
            # ambiguous source asset.
            bvh_matches = [
                name for name in names
                if Path(name).suffix.lower() == ".bvh"
                and Path(name).parent.name.lower() == token
                and Path(name).stem.lower() == token
            ]
            if len(bvh_matches) != 1:
                raise RuntimeError(f"expected one exact BVH for {token}, got {bvh_matches}")
            source_name = bvh_matches[0]
            data = zf.read(source_name)
            target_dir = out / token
            target_dir.mkdir(exist_ok=True)
            target = target_dir / Path(source_name).name
            target.write_bytes(data)
            selected[token] = {
                "archive_path": source_name,
                "path": str(target),
                "sha256": sha256_bytes(data),
                "bytes": len(data),
            }

    report = {
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget_allowed": False,
        "source_pack": "MakeHuman Community Poses02",
        "source_url": "https://files2.makehumancommunity.org/asset_packs/poses02/poses02_cc0.zip",
        "declared_license": "CC0",
        "source_pack_sha256": sha256_file(pack),
        "selection_reason": "cyclist poses are human-authored cylindrical handlebar grips; source must pass visual grasp screening before any target-rig transfer is attempted",
        "candidates": selected,
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print("MAKEHUMAN_POSES02_GRIP_SOURCE_V56_SUCCESS")
    print(json.dumps({"pack_sha256": report["source_pack_sha256"], "candidates": list(selected)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
