# Peel Calm reference convergence checkpoint 03

Date: 2026-08-14
Branch: `feat/reference-multiscale-loop-v1`
Exact verified head before checkpoint: `bc3714159736f2c8475e9a9ac2fc9645019cbbf9`
Godot Check: run `31792225785` — PASS
Acceptance set: `cafe_v1`, `bar_v1`, `market_v1` from `art/acceptance_refs/v1/MANIFEST.md`

## Stable production improvement

Glass-scene support-hand root now has one presentation owner.

- `ForearmPresentation` owns forearm geometry and venue material only.
- `HandChoreographyPresentation` owns glass support-hand root placement/inspection-follow.
- Café support-hand root remains owned by `CrumpleHandStaging`.
- RED run on the intermediate test-only head failed exactly because `ForearmPresentation` still exposed `_update_support_hand`.
- Exact fixed head passed import, launch, deterministic tests, all smoke suites, and the full café/bar/market capture matrix.

This closes a real state-ownership/jitter risk before higher-fidelity arms are introduced.

## Locked visual target

The exact three user-approved images were recovered from conversation files and persisted as the v1 acceptance set. Their source SHA-256 hashes, intent, and anti-drift rules are in `art/acceptance_refs/v1/MANIFEST.md`.

Runtime screenshots remain evidence and cannot silently replace these targets.

## Model escalation experiments

### Candidate A — subdivided existing XR hands

Technical result: PASS.

- source ~3,794 vertices / ~6,540 polygons per GLB;
- candidate ~20,662 vertices / ~19,620 polygons;
- 26-bone rig preserved;
- authored `Cup`, `Grip`, `Hold`, `Pinch Tight`, `Pinch Up` family preserved;
- Godot import/tests/runtime capture passed.

Visual result: REJECT.

- Micro faceting was modestly reduced;
- Macro and Meso silhouette/contact remained essentially the same;
- claw-like right-hand pose, detached support anatomy, and hand-to-forearm seam remained obvious;
- >5× vertex increase did not produce proportional perceptual improvement.

Evidence: `docs/superpowers/evidence/2026-08-14-hand-subdivision-spike.md`.

### Candidate B — generated rigged integrated forearm on XR hand rig

Technical result after correcting a stale smoke assumption: PASS.

The first apparent failure was not a damaged GLB: the candidate imported and deterministic tests passed. The old smoke incorrectly included the newly authored forearm in the palm/hand AABB. The spike separated hand bounds from limb bounds and then passed model build, Godot import, unit tests, scene/forearm/ritual/reset smoke, and all nine runtime captures.

Visual result: REJECT.

Target-vs-baseline-vs-candidate comparison showed the generated forearm inherited an unsuitable local-axis/scale relationship from the wrist-only XR rig. The candidate produced giant limbs entering from the top of frame and substantially regressed Macro composition.

This is useful negative evidence: extending the wrist-only XR rig procedurally is not a credible route to the reference hands.

## Current ranked reds

### R1 — continuous realistic human hand/wrist/forearm asset

The three acceptance references all show one continuous human limb shape. Current runtime still combines a VR-style wrist-only hand with a separately generated forearm. This is now the dominant structural mismatch.

### R2 — photographic grip/pinch pose

The current `Cup` support pose and `Pinch Up`/`Pinch Tight` peel poses are functional but still read as stock XR poses. A new limb candidate must support realistic vessel wrap and actual label-flap pinch.

### R3 — skin/nail PBR

Do not tune this until R1/R2 improve. Current faceting/material response remains obvious, but geometry/pose is the higher-frequency gate.

## Next exact action

Open a structurally different human-limb spike from this verified checkpoint.

Primary route: MPFB/MakeHuman-derived human basemesh using a GameEngine-style rig/material export path, because current MPFB documentation explicitly supports character creation, GameEngine rigs for external applications, and GameEngine PBR-like export materials.

The spike must:

1. use a pinned MPFB version and Blender >=4.2;
2. record MPFB code/asset license split and exact source revision;
3. create a reproducible human basemesh and rig in headless Blender;
4. isolate/retain only the useful hand+wrist+forearm presentation geometry if practical, or keep non-visible body geometry only in staging;
5. produce left/right hero-limb candidates with a documented pose/retarget path;
6. import into Godot 4.7.1;
7. compare identical target/base/candidate states;
8. reject unless thumbnail/Macro and Meso anatomy are materially closer to `cafe_v1`, `bar_v1`, and `market_v1`.

Do not return to XR subdivision or procedural forearm tuning unless new evidence changes the decision.
