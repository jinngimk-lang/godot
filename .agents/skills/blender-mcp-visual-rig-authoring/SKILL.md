---
name: blender-mcp-visual-rig-authoring
description: Use when a Peel Calm hand/limb pose has reached the stop condition for headless numeric scripting and requires genuinely visual native-Blender rig authoring against locked reference images.
---

# Blender MCP Visual Rig Authoring

## Principle

Use a live Blender session with viewport/render screenshots as the feedback loop. Do not convert this capability into another angle, sign, grip, orbit, translation, endpoint, or CCD sweep.

## Required capability

Preferred evaluated bridge: `harveyxiacn/blender-mcp` 0.3.1 or a later version that is re-audited before use. It is MIT-licensed and exposes Blender 4.x/5.x modeling, animation/rigging, viewport/render snapshots, and named checkpoints.

Security boundary:

- keep Blender/addon traffic on `127.0.0.1` only;
- run under least filesystem privilege;
- checkpoint/save before mutations;
- prefer structured rig/animation tools over arbitrary `execute_python`;
- never expose the socket publicly;
- do not enable external asset-generation providers or add credentials for this task;
- re-audit dependencies/version before adoption.

## Peel Calm R1 workflow

1. Open the latest validated native GameEngine/MPFB authoring `.blend` from the newest checkpoint.
2. Load `bar_v1` and `market_v1` as read-only visual targets; runtime/staging frames never replace them.
3. Freeze vessel, camera, physical hand scale, validated side-on forearm choreography, and validated wrist crop.
4. Save a named pre-edit checkpoint.
5. Use viewport screenshots after each meaningful manual/semantic-control adjustment. Judge the whole hand, not endpoint distances.
6. At Macro scale, require: palm beside vessel, fingers progressively wrapping into the far silhouette, readable thumb opposition, hero label still readable, natural frame-entry silhouette.
7. If Macro passes, inspect unobstructed Meso views for web space, knuckle flow, self-intersection, progressive digit depth, wrist continuity, and inspect-rotation stability.
8. Save the accepted same-rig pose and export only after both gates pass.
9. Feed the result into the existing artist-ingest/product-camera path and capture the same Godot bar/market XR-vs-candidate A/B.
10. Run exact-head Godot Check and independent Challenger before any production replacement.

## Stop rules

- A technically green Blender/MCP operation is not a visual PASS.
- Never create automated candidate grids from semantic controls.
- If direct visual authoring still cannot produce a convincing 192×108 enclosure, stop and record the visual failure rather than returning to numeric search.
- Keep skin/PBR, paper, glass, liquid, condensation, and HUD micro-polish frozen until the lower-scale hand gate passes.
