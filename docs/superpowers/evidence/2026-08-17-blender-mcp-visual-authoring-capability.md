# Blender MCP visual-authoring capability audit

Date: 2026-08-17
Purpose: unblock checkpoint-53 R1 without resuming code-authored pose guessing.

## Why this capability is relevant

Checkpoint 53 formally stopped v94/v95-style numeric support-hand searches. The missing capability is a live native-rig loop where an agent can inspect the Blender viewport, adjust the actual GameEngine/MPFB pose, take a new viewport/render snapshot, compare against locked `bar_v1` / `market_v1`, and save/restore checkpoints.

`harveyxiacn/blender-mcp` currently provides that shape of capability:

- package version audited: `0.3.1`;
- Blender 4.x / 5.x support;
- animation/rigging tool groups;
- viewport and render-preview screenshots for multimodal review;
- named checkpoint save/restore;
- MCP bridge to a live Blender addon over localhost TCP;
- MIT license.

This is materially different from the failed headless scripts because visual feedback is part of the mutation loop rather than an after-the-fact render of a generated numeric candidate.

## Provenance / rights

Repository: `https://github.com/harveyxiacn/blender-mcp`

Audited files on 2026-08-17:

- `LICENSE`: MIT, copyright 2024-2026 Blender MCP Contributors.
- `pyproject.toml`: package version `0.3.1`, project license `MIT`, Python >=3.10.
- `SECURITY.md`: documents arbitrary-Python risk, localhost binding, execution timeout/code-size limits, filesystem-path risk, and dependency-supply-chain guidance.

No external model weights or generated 3D assets are required for the intended R1 workflow. The tool is an authoring bridge only; Peel Calm's existing MPFB same-rig asset remains the staged source.

## Security constraints for Peel Calm

If connected in a future runtime:

1. bind Blender addon/MCP traffic to `127.0.0.1` only;
2. do not expose TCP port 9876 or any MCP HTTP transport to a public interface;
3. run Blender with least filesystem privilege and a project-bounded working directory;
4. save a named checkpoint before every pose mutation batch;
5. prefer structured rig/animation tools; use arbitrary Python only for the smallest unsupported primitive and review it first;
6. do not configure paid/external asset providers, credentials, API keys, or cloud-generation services for this task;
7. pin the selected revision/dependencies before production use and re-audit when upgrading.

## TDD / anti-rationalization evidence

RED already exists in project history: checkpoints 39-53 show that without direct visual authoring, successive agents repeatedly rationalized numeric handle tables, joint-axis changes, grip scalars, wrist rotations, translations, and per-digit depth transforms. Some runs were technically green but Macro still failed.

The new skill closes that loophole by allowing mutation only inside a live screenshot-driven Blender loop after the numeric-search stop condition, and by retaining the same 192x108 Macro -> unobstructed Meso -> Godot product-camera -> Challenger gates.

## Current environment result

The present ChatGPT runtime does not expose a dynamically attachable Blender MCP connector, and plugin discovery returned no installable Blender/3D rigging plugin. Therefore this run did **not** install or pretend to use the bridge, did not mutate a hand pose, and did not reopen numeric pose search.

The capability is now documented as a reversible future execution path for any MCP-capable runtime (for example Codex/local tooling) that can attach to a live Blender 4.x session.

## Acceptance for first connected run

The first connected run must:

1. open the latest validated native-rig authoring `.blend` referenced by the newest checkpoint;
2. prove screenshot feedback works before changing bones;
3. save a pre-edit checkpoint;
4. make one direct visual whole-hand pose, not a generated grid;
5. hide guides and judge locked 192x108 Macro first;
6. only if Macro passes, inspect unobstructed Meso anatomy;
7. export the same-rig candidate and use the existing Godot bar/market A/B capture;
8. run exact-head Godot Check and independent Challenger before production integration.
