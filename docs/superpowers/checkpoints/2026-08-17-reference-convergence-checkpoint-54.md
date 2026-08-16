# Peel Calm reference convergence checkpoint 54

Date: 2026-08-17
Branch: `spike/blender-mcp-visual-authoring-capability`
Base production/documentation head: `main@3f3c34377ba29cca953f9f64b35d850748db43d6`
Locked acceptance references: `cafe_v1`, `bar_v1`, `market_v1`

## Recovery state

Checkpoint 53 remains authoritative for product quality:

- merged production content baseline before documentation: `62de386239ce80c317ec6ffdd3a4e1d7f665129a`;
- merged-main Godot Check `31957055474` — PASS;
- merged-main reference artifact `9266224755`;
- R1 support-hand numeric/headless pose search is formally stopped;
- R3 capture truthfulness is fixed, but the actual pinch silhouette remains prototype quality.

The latest merged-main nine-frame artifact was re-downloaded and visually reviewed in this run. The partial-peel frames truthfully show `Pinch Tight`, but both support and peel hands remain far from the locked close-up references; this does not change the ranking that R1 is the dominant Macro blocker.

## Capability acquisition result

Plugin discovery found no installable Blender / 3D rigging plugin in the current ChatGPT runtime.

A fresh primary-source audit identified `harveyxiacn/blender-mcp` as a plausible capability that satisfies the **type** of authoring checkpoint 53 requires rather than reopening numeric search:

- package version audited: `0.3.1`;
- MIT license;
- Blender 4.x / 5.x;
- live Blender addon + MCP bridge;
- animation/rigging tools;
- viewport/render snapshots for multimodal visual feedback;
- named checkpoint save/restore.

Its security policy explicitly notes arbitrary-Python execution risk, localhost-only default binding, filesystem-path risk, and dependency-supply-chain concerns. Peel Calm's usage contract therefore requires localhost-only operation, least filesystem privilege, saved checkpoints, structured rig tools by default, and no external providers/credentials.

## New reusable project capability

Added:

- `.agents/skills/blender-mcp-visual-rig-authoring/SKILL.md`
- `docs/superpowers/evidence/2026-08-17-blender-mcp-visual-authoring-capability.md`

The skill is deliberately anti-search: after the R1 stop condition, it permits a live screenshot-driven native-rig authoring loop but forbids angle/sign/grip/orbit/translation grids, endpoint chasing, CCD, or technically-green visual bypasses.

## What was not done

- No hand pose was changed.
- No external MCP was installed into this ChatGPT runtime because no supported dynamic Blender connector is exposed here.
- No production asset, gameplay, input, progression, reset, scene, or capture behavior was changed.
- No paid/external asset provider, API key, credential, or cloud model was configured.
- Numeric v94/v95 support-hand search was not resumed.

## Remaining reds

### R1 — Genuine artist-authored whole-hand vessel enclosure

Still the dominant Macro blocker. The newly documented Blender-MCP path is a capability candidate, not a visual PASS. Resume R1 only in a runtime that can attach to a live Blender session and return viewport screenshots while mutating the native GameEngine/MPFB rig.

### R2 — Product-camera Meso anatomy

Still blocked behind R1 Macro.

### R3 — Peel-hand pinch choreography

Truthful capture exists and was re-reviewed. The actual `Pinch Tight` whole-hand silhouette remains prototype-quality; it stays behind R1 unless R1 remains externally blocked for an extended period and a separate evidence-backed reprioritization is made.

### R4+ — Micro polish

Skin/PBR, paper fiber, glass/liquid, condensation, HUD micro polish remain frozen.

## Next exact action

1. In the first runtime with a supported live Blender MCP/native viewport connection, read the new skill before touching the rig.
2. Open the latest validated native GameEngine/MPFB authoring `.blend` referenced by the R1 staging checkpoints.
3. Prove viewport screenshot feedback and named save/restore work before edits.
4. Produce exactly one direct visual whole-hand support pose against `bar_v1` / `market_v1`; do not generate a candidate grid.
5. Hide guides and judge 192x108 Macro enclosure first; only then judge unobstructed Meso.
6. If both pass, feed the same-rig pose through existing artist-ingest and Godot bar/market product-camera A/B, then exact-head Godot Check and independent Challenger.
7. If no live visual connection is available, keep R1 paused rather than returning to numeric transform guessing.

The project is not reference-complete. This checkpoint closes an authoring-capability research gap, not the visual R1 itself.
