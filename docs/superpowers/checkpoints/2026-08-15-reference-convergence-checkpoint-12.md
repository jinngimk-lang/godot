# Peel Calm reference convergence checkpoint 12

Date: 2026-08-15
Branch: `spike/mpfb-hero-limb-authored-grasp-v38`
Production baseline: `main@769d6452e75112084f537af99be90721c2629cd5`
Experimental head before this checkpoint: `1295ece3af3b3c63275f54e866074301bd81542d`
Exact-head Godot Check: run `31859927474` — queued at checkpoint time
MPFB Authored Grasp v38: run `31859927493` — queued at checkpoint time

## Acceptance context

The approved café/bar/market reference family remains the source of truth. R1 is still continuous hero hand-wrist-forearm anatomy/choreography; R2 is real support-wrap / label-pinch contact. Micro polish remains deferred while hand Macro/Meso is unresolved.

## Evidence carried forward from v37

v37 visually rejected joint-arc waypoint steering. Along with v35/v36, the evidence now rejects these as primary grasp generators:

- endpoint-only CCD;
- CCD order permutations;
- random support-axis/sign changes;
- per-phalanx cylindrical waypoint IK;
- simply increasing joint budgets or relaxing endpoint tolerance.

The next abstraction must be authored grasp anatomy first, then only bounded vessel adaptation.

## v38 falsifiable hypothesis

Hypothesis: keeping the improved v35 whole-hand root/palm frame but replacing endpoint optimization with a deterministic artist-authored flexion profile can create a recognizable human support-wrap silhouette. The unknown MPFB GameEngine local flexion axis is isolated by rendering a six-candidate local-axis/sign family rather than optimizing fingertip contact.

Authored flexion profile:

- index: 34 / 48 / 36 degrees;
- middle: 40 / 54 / 40 degrees;
- ring: 44 / 58 / 44 degrees;
- pinky: 48 / 62 / 46 degrees;
- thumb: opposing 28 / 36 / 30 degrees.

This profile intentionally encodes progressive finger closure and thumb opposition. It does not inspect or chase fingertip target errors.

## Implementation

Added:

- `tools/render_mpfb_authored_grasp_v38.py`
- `.github/workflows/mpfb-authored-grasp-v38.yml`

The workflow pins Blender 4.2.0 and MPFB 2.0.17 with the existing verified hashes, builds/extracts the continuous right hero limb, and renders six fixed-axis authored candidates from the same v35-positive whole-hand frame.

## Visual gate

The six candidates must be judged at Macro/Meso by:

1. immediate human vessel-wrap silhouette;
2. palm visually enclosing rather than merely touching the vessel;
3. thumb opposition;
4. visible progressive finger ordering;
5. no obvious self-intersection or long parallel-tine/claw shape;
6. wrist/forearm flow compatible with the approved reference composition.

Numeric palm/tip metrics are diagnostics only and cannot make a candidate pass.

## Promotion rule

If no candidate visibly passes, reject v38 without product integration and use the images to identify the correct authored bend axis/secondary abduction needed for v39. If a candidate passes, freeze that authored grasp as the new staging seed, add only small bounded cup-vs-bottle radius adaptation, then render it in a Godot product-camera staging scene against the XR baseline before any production hand replacement.

No merge to production is justified until the real product-camera frame is visibly closer to the locked references.
