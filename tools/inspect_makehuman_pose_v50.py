#!/usr/bin/env python3
"""Inspect a MakeHuman CC0 pose pack without touching the MPFB GameEngine rig.

This tool is staging-only. It extracts the holding-wine-glass source BVH/meta,
records immutable hashes, and summarizes the BVH hierarchy/channels/first frame.
It never retargets or writes production pose data.
"""
from __future__ import annotations

import hashlib
import json
import sys
import zipfile
from pathlib import Path

TARGET_TOKEN = "mindfront_sitting_in_armchair_holding_wine_glass"
SOURCE_URL = "https://files2.makehumancommunity.org/asset_packs/poses01/poses01_cc0.zip"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def parse_bvh(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = [line.rstrip() for line in text.splitlines()]
    joints: list[str] = []
    channels: dict[str, list[str]] = {}
    stack: list[str] = []
    current: str | None = None
    frame_time = None
    frame_count = None
    first_frame: list[float] = []
    motion_idx = next((i for i, line in enumerate(lines) if line.strip() == "MOTION"), -1)

    hierarchy_lines = lines if motion_idx < 0 else lines[:motion_idx]
    for raw in hierarchy_lines:
        line = raw.strip()
        if line.startswith("ROOT ") or line.startswith("JOINT "):
            current = line.split(maxsplit=1)[1]
            joints.append(current)
            stack.append(current)
        elif line.startswith("CHANNELS ") and current:
            parts = line.split()
            count = int(parts[1])
            channels[current] = parts[2:2 + count]
        elif line == "}":
            if stack:
                stack.pop()
                current = stack[-1] if stack else None

    if motion_idx >= 0:
        for i in range(motion_idx + 1, min(len(lines), motion_idx + 8)):
            line = lines[i].strip()
            if line.startswith("Frames:"):
                frame_count = int(line.split(":", 1)[1].strip())
            elif line.startswith("Frame Time:"):
                frame_time = float(line.split(":", 1)[1].strip())
            elif line and line[0] in "-0123456789":
                first_frame = [float(v) for v in line.split()]
                break

    right_keywords = ("right", "r_", "_r", "rhand", "hand.r", "wrist.r")
    likely_right = [j for j in joints if any(k in j.lower() for k in right_keywords)]
    return {
        "joint_count": len(joints),
        "joints": joints,
        "likely_right_side_joints": likely_right,
        "channel_count": sum(len(v) for v in channels.values()),
        "channels": channels,
        "frame_count": frame_count,
        "frame_time": frame_time,
        "first_frame_value_count": len(first_frame),
        "first_frame": first_frame,
    }


def main() -> int:
    if len(sys.argv) != 4:
        raise SystemExit("usage: inspect_makehuman_pose_v50.py PACK.zip OUT_DIR REPORT.json")
    pack = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])
    report_path = Path(sys.argv[3])
    out_dir.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    pack_hash = sha256(pack)
    selected: list[dict] = []
    with zipfile.ZipFile(pack) as zf:
        candidates = [n for n in zf.namelist() if TARGET_TOKEN in Path(n).stem.lower()]
        if not candidates:
            # Be tolerant of separators/case changes while still requiring the semantic asset.
            candidates = [n for n in zf.namelist() if "holding" in n.lower() and "wine" in n.lower() and "glass" in n.lower()]
        if not candidates:
            raise RuntimeError("holding-wine-glass pose not found in official Poses 01 archive")
        for name in sorted(candidates):
            suffix = Path(name).suffix.lower()
            if suffix not in {".bvh", ".meta", ".thumb", ".png", ".jpg", ".jpeg"}:
                continue
            target = out_dir / Path(name).name
            target.write_bytes(zf.read(name))
            selected.append({"archive_path": name, "path": str(target), "sha256": sha256(target), "bytes": target.stat().st_size})

    bvh_files = [Path(x["path"]) for x in selected if Path(x["path"]).suffix.lower() == ".bvh"]
    if len(bvh_files) != 1:
        raise RuntimeError(f"expected exactly one source BVH, got {len(bvh_files)}")
    meta_text = "\n".join(Path(x["path"]).read_text(encoding="utf-8", errors="replace") for x in selected if Path(x["path"]).suffix.lower() == ".meta")

    report = {
        "staging_only": True,
        "production_candidate": False,
        "automatic_retarget_allowed": False,
        "source_url": SOURCE_URL,
        "source_pack_sha256": pack_hash,
        "asset_name": TARGET_TOKEN,
        "declared_license_from_official_pack_page": "CC0",
        "extracted_files": selected,
        "meta_text": meta_text,
        "bvh": parse_bvh(bvh_files[0]),
        "safety_contract": "Source BVH is anatomy/silhouette reference only; never import it destructively into the MPFB GameEngine hero rig.",
    }
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    print("MAKEHUMAN_POSE_REFERENCE_V50_INSPECT_SUCCESS")
    print(json.dumps({"pack_sha256": pack_hash, "files": len(selected), "joints": report["bvh"]["joint_count"]}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
