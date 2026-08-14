# Peel Calm — Reference Convergence Execution Addendum

This addendum is mandatory alongside `2026-08-14-reference-convergence-long-horizon-master-prompt.md`.

## A. Reference-set versioning / anti-drift

Approved references are versioned acceptance assets, not a vague mood board.

1. Never silently replace an approved target with a newly generated image because the new image is easier to match.
2. Store or document the target family/version used by every visual checkpoint.
3. If a new generated target is proposed, classify it as one of:
   - `DERIVED_STEP_REFERENCE`: fills an interaction state not shown in the approved images while preserving their visual language;
   - `EXPLANATORY_REFERENCE`: diagram/markup used to understand pose, geometry, or lighting;
   - `PROPOSED_DIRECTION_CHANGE`: changes the visual target and therefore must not silently redefine acceptance.
4. Derived references must preserve the approved family’s camera language, material realism, hand scale, venue identity, and tactile intent.
5. Runtime captures are evidence, not references. Do not promote a current game screenshot into the target set merely because it is convenient.

## B. Generate/annotate before coding when the target is ambiguous

When a rendering/modeling/interaction problem cannot be described with unambiguous geometry or state constraints:

1. Generate, sketch, or annotate a concrete target image first.
2. For temporal interactions, create a short target sequence rather than one endpoint image.
3. Mark critical landmarks: contact points, silhouette, camera crop, finger opposition, label lift direction, reflection zones, etc.
4. Only then implement.
5. After implementation, capture the same state from Godot and compare side-by-side.

This is especially mandatory for:

- hand grip and pinch poses;
- vessel silhouette redesign;
- new scene composition;
- peel/torn/residue states;
- crumple stages;
- glass/liquid/ice readability;
- camera changes.

## C. Capability acquisition rule

If progress is blocked because current skills/tools are inadequate, capability acquisition is part of the work rather than a reason to stop.

You may autonomously research and adopt relevant:

- repository-local skills;
- installed plugins/MCP-style connectors;
- open-source Blender/Godot tooling;
- image comparison tooling;
- 3D reconstruction / image-to-3D / multiview-to-3D systems;
- retopology, UV, rigging, weight-transfer, texture, and baking workflows;
- primary research papers and official documentation.

Do not ask for approval merely to learn or install a relevant free/reversible capability when the available environment supports it.

However, autonomous capability acquisition never overrides these gates:

- no paid purchase/subscription without explicit authorization;
- no secret/API-key creation or credential changes without the applicable authorization flow;
- no production dependency with unclear commercial rights;
- no destructive or irreversible external operation;
- no model/weight whose distribution terms conflict with intended release.

Every adopted capability should leave a short provenance/reason note in the repository if it materially affects production.

## D. Quantitative visual-diff artifact rule

When practical, each capture loop should produce both full-resolution frames and a comparison bundle containing:

- strongly downsampled Macro view;
- medium-scale Meso view;
- native-resolution crop(s) for Micro review;
- edge/silhouette comparison for hero hands and vessels;
- landmark/occupancy ratios;
- optional SSIM/MS-SSIM/LPIPS-style metrics if the environment supports them reliably.

A metric is a detector, not the judge. A lower metric can be acceptable only when the visual review identifies why the reference is being matched more faithfully despite pixel differences.

## E. Two-strike model escalation

If the same model/pose red survives two real-frame iterations:

1. stop tweaking lights/materials around it;
2. open a dedicated model spike;
3. test at least one structurally different solution (different asset, retopology, reconstructed mesh, rig/pose approach, etc.);
4. compare candidates using the same camera/reference states;
5. keep the winner only if it improves the real frame without unacceptable rights/performance/interaction cost.

## F. Completion anti-self-deception check

Before claiming any visual milestone complete, ask:

- Would the mismatch still be obvious if both images were shown at thumbnail size?
- Would the mismatch still be obvious with texture detail blurred away?
- Does the hand actually touch/wrap/pinch the correct thing?
- Does the interaction look plausible in intermediate states, not only endpoints?
- Did another scene regress?
- Is the result visibly closer to the approved reference, or merely more elaborate?

If any answer exposes a meaningful red, continue the loop.
