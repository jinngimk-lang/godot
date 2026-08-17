# Hero hand subdivision runtime spike v91 — provenance and gate

Date: 2026-08-17
Base main: `4e76a07dcf587d40f55d5779895d785f3784f740`
Candidate binary commit: `fbb5f716f4db07910a8db95511de205f37463ca3`
Source artifact: same-repository Actions artifact `9281903731` (`authored-hand-subdiv-candidates`).

## Provenance

The candidates are derived from the repository-local CC0-derived authored hand assets already documented under `assets/models/hands/`. No third-party license or source is introduced by this spike.

The prior Blender build report recorded, for each side:
- source mesh `3752v / 6460f` -> candidate `20420v / 19380f`;
- 26 skin groups and a 26-bone `Armature` preserved;
- existing authored actions preserved, including `Cup_Armature`, `Pinch Tight_Armature`, and `Pinch Up_Armature`;
- exporter warning: vertices with more than four influences were normalized to the strongest four on glTF export.

## Falsifiable purpose

This is not a pose search and must not be treated as a final hand solution. It asks one bounded question only: does a rig-preserving structural subdivision of the current provenance-safe mesh materially reduce the runtime faceting/low-density silhouette while preserving import, authored animations, and current interaction?

## Acceptance / rejection gate

1. Exact-head Godot 4.7.1 import + deterministic suite must pass with the candidate GLBs.
2. Fresh runtime `cafe.png` and `cafe_peel38.png` must be inspected against locked `cafe_v1`.
3. If the hands remain visibly anatomically wrong/open around the vessel, or the improvement is only Micro smoothing while R1 support-hand enclosure remains dominant, reject the candidate and do not merge it.
4. No CCD, endpoint chasing, wrist/orbit/yaw/translation grid, or other numeric pose sweep is permitted in this spike.
