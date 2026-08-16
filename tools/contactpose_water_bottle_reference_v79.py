#!/usr/bin/env python3
"""Extract real human water-bottle grasp skeletons from ContactPose sample data.

This is a read-only anatomical-reference spike. It never imports MANO, object meshes,
or copies transforms into the production GameEngine rig. It only reads MIT-licensed
21-joint annotations, normalizes them into a palm-local frame, ranks curled/opposed
hand shapes, and renders diagnostic skeleton sheets for visual selection.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Iterable

import matplotlib.pyplot as plt
import numpy as np

# ContactPose follows OpenPose hand ordering:
# 0 wrist; thumb 1-4; index 5-8; middle 9-12; ring 13-16; pinky 17-20.
CHAINS = {
    "thumb": [0, 1, 2, 3, 4],
    "index": [0, 5, 6, 7, 8],
    "middle": [0, 9, 10, 11, 12],
    "ring": [0, 13, 14, 15, 16],
    "pinky": [0, 17, 18, 19, 20],
}
FINGER_CHAINS = [CHAINS[k] for k in ("index", "middle", "ring", "pinky")]


def unit(v: np.ndarray) -> np.ndarray:
    n = float(np.linalg.norm(v))
    if n < 1e-9:
        raise ValueError("degenerate vector")
    return v / n


def palm_local(j: np.ndarray) -> tuple[np.ndarray, float]:
    """Normalize a 21x3 skeleton into a stable palm-local coordinate frame."""
    wrist = j[0]
    index_mcp = j[5]
    middle_mcp = j[9]
    pinky_mcp = j[17]
    x = unit(index_mcp - pinky_mcp)  # radial direction across MCP row
    y_hint = unit(middle_mcp - wrist)  # wrist -> middle MCP
    z = unit(np.cross(x, y_hint))
    y = unit(np.cross(z, x))
    basis = np.stack([x, y, z], axis=1)
    local = (j - wrist) @ basis
    palm_width = float(np.linalg.norm(index_mcp - pinky_mcp))
    if palm_width < 1e-6:
        raise ValueError("degenerate palm width")
    return local / palm_width, palm_width


def angle_deg(a: np.ndarray, b: np.ndarray) -> float:
    a = unit(a)
    b = unit(b)
    c = float(np.clip(np.dot(a, b), -1.0, 1.0))
    return math.degrees(math.acos(c))


def chain_flex(local: np.ndarray, chain: list[int]) -> float:
    pts = local[chain]
    seg = np.diff(pts, axis=0)
    # Exclude wrist->MCP from articulation score; use MCP/PIP/DIP turns.
    turns = [angle_deg(seg[i], seg[i + 1]) for i in range(1, len(seg) - 1)]
    return float(np.mean(turns)) if turns else 0.0


def metrics(local: np.ndarray) -> dict[str, float]:
    flex = [chain_flex(local, c) for c in FINGER_CHAINS]
    finger_tips = local[[8, 12, 16, 20]]
    thumb_tip = local[4]
    # Thumb opposition proxy: closer to the opposing finger-tip centroid is better.
    opp_dist = float(np.linalg.norm(thumb_tip - finger_tips.mean(axis=0)))
    # Enclosure proxy: curled fingers should span depth rather than collapse into a sheet.
    depth_span = float(np.ptp(local[[5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20], 2]))
    tip_depth_span = float(np.ptp(finger_tips[:, 2]))
    # Natural cylindrical support usually has increasing closure toward ulnar digits,
    # but only use this as a weak ranking signal, never as acceptance.
    progression = sum(max(0.0, flex[i + 1] - flex[i]) for i in range(3)) / 3.0
    mean_flex = float(np.mean(flex))
    # Rank only for triage. Final selection is visual.
    score = mean_flex * 0.55 + progression * 0.20 + min(depth_span, 1.5) * 18.0 + min(tip_depth_span, 1.0) * 10.0 - opp_dist * 8.0
    return {
        "index_flex_deg": flex[0],
        "middle_flex_deg": flex[1],
        "ring_flex_deg": flex[2],
        "pinky_flex_deg": flex[3],
        "mean_flex_deg": mean_flex,
        "progression_deg": progression,
        "thumb_opposition_distance_palm_width": opp_dist,
        "digit_depth_span_palm_width": depth_span,
        "tip_depth_span_palm_width": tip_depth_span,
        "triage_score": score,
    }


def annotation_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("annotations.json") if p.parent.name == "water_bottle")


def iter_candidates(paths: Iterable[Path]):
    for p in paths:
        ann = json.loads(p.read_text(encoding="utf-8"))
        session = p.parent.parent.name
        for hand_idx, hand in enumerate(ann.get("hands", [])):
            if not hand.get("valid"):
                continue
            joints = np.asarray(hand.get("joints"), dtype=float)
            if joints.shape != (21, 3) or not np.isfinite(joints).all():
                continue
            try:
                local, palm_width = palm_local(joints)
                m = metrics(local)
            except ValueError:
                continue
            yield {
                "source": str(p),
                "session": session,
                "hand_index": hand_idx,
                "moving": bool(hand.get("moving", False)),
                "palm_width_source_units": palm_width,
                "local_joints": local,
                "metrics": m,
            }


def plot_candidate(ax, local: np.ndarray, view: tuple[int, int], title: str) -> None:
    colors = ["tab:purple", "tab:blue", "tab:green", "tab:orange", "tab:red"]
    for color, chain in zip(colors, CHAINS.values()):
        p = local[chain]
        ax.plot(p[:, view[0]], p[:, view[1]], "-o", lw=1.4, ms=2.8, color=color)
    ax.scatter([0], [0], s=18, c="black")
    ax.set_aspect("equal", adjustable="box")
    ax.set_title(title, fontsize=7)
    ax.grid(alpha=0.15)
    ax.tick_params(labelsize=5)


def make_sheet(candidates: list[dict], out: Path, view: tuple[int, int], suffix: str) -> None:
    n = len(candidates)
    cols = 4
    rows = max(1, math.ceil(n / cols))
    fig, axes = plt.subplots(rows, cols, figsize=(12, 2.8 * rows), squeeze=False)
    for ax in axes.flat:
        ax.axis("off")
    for rank, c in enumerate(candidates):
        ax = axes.flat[rank]
        ax.axis("on")
        m = c["metrics"]
        title = (
            f"#{rank+1} {c['session']} h{c['hand_index']} score={m['triage_score']:.1f}\n"
            f"flex={m['mean_flex_deg']:.0f}° opp={m['thumb_opposition_distance_palm_width']:.2f} depth={m['digit_depth_span_palm_width']:.2f}"
        )
        plot_candidate(ax, c["local_joints"], view, title)
    fig.tight_layout()
    fig.savefig(out / f"contactpose-water-bottle-top-{suffix}.png", dpi=180)
    plt.close(fig)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--top", type=int, default=12)
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    paths = annotation_files(args.root)
    discovery = {
        "root": str(args.root),
        "water_bottle_annotation_count": len(paths),
        "annotation_files": [str(p) for p in paths],
        "license_note": "ContactPose README: code MIT; all non-3D-model data MIT. This spike uses only annotations/joints, not object meshes or MANO code/models.",
    }
    (args.out / "discovery.json").write_text(json.dumps(discovery, indent=2), encoding="utf-8")
    if not paths:
        raise SystemExit("Official sample data contains no water_bottle annotations; see discovery.json")

    candidates = list(iter_candidates(paths))
    if not candidates:
        raise SystemExit("water_bottle annotations found, but no valid 21x3 hand skeletons")
    candidates.sort(key=lambda c: c["metrics"]["triage_score"], reverse=True)
    top = candidates[: args.top]

    serializable = []
    for rank, c in enumerate(top, 1):
        serializable.append({
            "rank": rank,
            "source": c["source"],
            "session": c["session"],
            "hand_index": c["hand_index"],
            "moving": c["moving"],
            "palm_width_source_units": c["palm_width_source_units"],
            "metrics": c["metrics"],
            "normalized_openpose21": c["local_joints"].round(7).tolist(),
        })
    (args.out / "top_candidates.json").write_text(json.dumps(serializable, indent=2), encoding="utf-8")

    # Palm-local views: XY = palm plane; YZ = side/depth; XZ = MCP-width/depth.
    make_sheet(top, args.out, (0, 1), "palm")
    make_sheet(top, args.out, (1, 2), "side")
    make_sheet(top, args.out, (0, 2), "depth")

    lines = [
        "# ContactPose water-bottle anatomical reference v79",
        "",
        f"Found {len(paths)} water_bottle annotation files and {len(candidates)} valid hand skeleton candidates.",
        "",
        "This is anatomical reference only. Final acceptance remains visual against Peel Calm bar_v1/market_v1.",
        "No MANO code/models or ContactPose object meshes are used.",
        "",
        "## Top candidates",
        "",
    ]
    for rank, c in enumerate(top, 1):
        m = c["metrics"]
        lines.append(
            f"{rank}. `{c['session']}` hand {c['hand_index']} — triage {m['triage_score']:.2f}; "
            f"mean flex {m['mean_flex_deg']:.1f}°; thumb opposition distance {m['thumb_opposition_distance_palm_width']:.3f} palm widths; "
            f"digit depth span {m['digit_depth_span_palm_width']:.3f}."
        )
    (args.out / "REPORT.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
