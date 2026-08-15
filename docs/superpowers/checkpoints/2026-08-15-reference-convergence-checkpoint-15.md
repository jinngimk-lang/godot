# Peel Calm reference convergence checkpoint 15

Date: 2026-08-15
Production main baseline: `769d6452e75112084f537af99be90721c2629cd5`
Working branch: `spike/mpfb-hero-limb-camera-wrap-v42`
Exact v42 head before this checkpoint: `2c64d3e5c4eac5be90f67f38779fd455015f3804`

## Acceptance target

The locked café / amber-bar / clear-market acceptance family remains the source of truth. The highest priority remains Macro/Meso human-hand credibility: a continuous hand-wrist-forearm that reads immediately as a real vessel support wrap, followed by a photographic label pinch. Micro skin/PBR, paper fiber, glass highlight and condensation work remains intentionally deferred.

## v41 — explicit artist table, technically green but visually rejected

Branch: `spike/mpfb-hero-limb-artist-authored-v41`
Exact head: `cbcf4287bc6a13f6b8f6602483af9e421ddfe96b`
Godot Check: run `31865114127` — PASS
MPFB Artist Grasp v41: run `31865114125` — PASS
Visual artifact: `mpfb-artist-grasp-v41`, artifact id `9241798594`

Inspected frames:
- `artist_grasp_v41_bottle_wrap.png`
- `artist_grasp_v41_cup_wrap.png`
- `artist_grasp_v41_relaxed_wrap.png`

Visual verdict: **REJECT**.

The continuous MPFB anatomy remains a structural improvement over the production XR hand + generated forearm, but the explicit per-joint authored rotation table still does not create a photographic support wrap. Bottle/cup variants expose long separated fingers on the same camera-facing side of the vessel, read as a claw/fork rather than a hand enveloping the object, and do not provide convincing thumb opposition. The relaxed candidate is anatomically calmer but is not a support grip.

Important diagnostic: v41 numerical contact-like metrics were not allowed to override the images. In the bottle candidate the four finger near-side dots remained strongly positive; visually this corresponds to all fingertips staying exposed on the camera-near hemisphere instead of wrapping around the vessel.

## v42 — camera-relative whole-hand azimuth falsification

Hypothesis: v41 might have a usable authored finger pose but a wrong camera-relative whole-hand azimuth around the vessel. Test one structural variable only: rigidly rotate the already-oriented whole hand around the vertical vessel axis while keeping the v41 `bottle_wrap` finger pose unchanged.

Candidate azimuths:
- -45°
- -25°
- 0°
- +25°
- +45°

Files:
- `tools/render_mpfb_camera_wrap_v42.py`
- `.github/workflows/mpfb-camera-wrap-v42.yml`

Exact head: `2c64d3e5c4eac5be90f67f38779fd455015f3804`
Godot Check: run `31867379035` — PASS
MPFB Camera Wrap v42: run `31867379066` — PASS
Visual artifact: `mpfb-camera-wrap-v42`, artifact id `9242455316`
Artifact digest: `sha256:bed36cb2c0aa156943551849575c01ddeea28e28403add0e5f54b702b231308e`

Inspected frames:
- `camera_wrap_v42_neg45.png`
- `camera_wrap_v42_neg25.png`
- `camera_wrap_v42_zero0.png`
- `camera_wrap_v42_pos25.png`
- `camera_wrap_v42_pos45.png`

Visual verdict: **REJECT ALL FIVE**.

### Macro/Meso observations

- Negative azimuths rotate the hand into a vertical hanging claw. At -45° especially, two long fingers dominate the silhouette and the palm no longer reads as a natural support contact.
- 0° retains the v41 same-side fork/claw problem.
- Positive azimuths lay the palm/fingers horizontally across the front of the vessel. They remain long, separated and camera-exposed rather than disappearing around the far side as a natural cylindrical wrap should.
- None of the five provides credible thumb opposition.
- None reads at thumbnail scale as the support-hand silhouette in the approved café/bar/market references.

Therefore camera-relative azimuth is **not** the missing variable and must not be tuned further.

## What is now falsified / do not repeat

The following paths have accumulated enough real-frame negative evidence and should not be restarted without materially new evidence:

1. fingertip endpoint CCD / target chasing;
2. changing CCD ordering;
3. randomized support-axis search;
4. circular proximal waypoint / joint-arc chasing;
5. shared-axis authored grasp;
6. uniform Z flexion + proximal X fan;
7. automatic per-joint local-axis pose-table search;
8. explicit numeric artist-table flexion without a real pose source;
9. rigid camera-relative azimuth sweep around the vessel;
10. using contact/fingertip metrics as acceptance when Macro/Meso silhouette fails.

## New structural conclusion

The remaining problem is no longer adequately described as an IK tolerance, local bend-axis, flexion-profile, or camera-azimuth problem. The pipeline needs a **real authored grasp pose source** whose full-hand silhouette was created/validated as a human grasp, then transferred/adapted to the continuous MPFB limb.

A useful current official source family exists in the MakeHuman ecosystem:
- MakeHuman Community `poses01` is a checked CC0 pose pack.
- It includes `mindfront_sitting_in_armchair_holding_wine_glass`, which is directly relevant as a human-authored object-holding pose candidate.
- MPFB supports saving/loading full or partial poses for the same rig type, providing a path to persist a validated hand pose once transferred or recreated on the GameEngine rig.

Official provenance references:
- https://static.makehumancommunity.org/assets/assetpacks/poses01.html
- https://static.makehumancommunity.org/mpfb/docs/rigging_posing/save_load.html

This pose pack is a **staging source only**. Do not promote it automatically. Verify the exact asset file, CC0 metadata, import/retarget behavior, hand silhouette and Godot integration before any production use.

## Remaining reds

### R1 — Hero support hand / continuous limb

Still highest priority. MPFB solves the continuous hand-wrist-forearm topology problem, but no accepted human support-wrap pose exists yet.

### R2 — Peel hand / label pinch

Still blocked behind R1. Once a credible authored-pose-source workflow exists, apply the same approach to thumb/index flap pinch with whole-hand approach and wrist flow, not fingertip-only contact.

### R3 — Product material/lighting micro fidelity

Skin PBR, paper fibers, glass optical breakup and condensation remain deferred until R1/R2 Macro/Meso gates pass.

## Next exact action

1. Start a new isolated pose-source spike from this checkpoint/main-safe lineage.
2. Fetch/inspect a provenance-clear CC0 human-authored object-holding pose source, beginning with the MakeHuman Poses 01 wine-glass pose candidate.
3. Extract only the hand/wrist/forearm pose information needed for a support grasp; do not import irrelevant scene/body content into production.
4. Recreate/transfer that pose onto the MPFB GameEngine right limb and render it in the same fixed vessel camera used for v41/v42.
5. Compare Macro/Meso silhouette against the locked references and against v41/v42.
6. If it passes, persist it as an MPFB partial pose and proceed to a real Godot product-camera staging scene. If it fails, reject the source and test a structurally different authored grasp source rather than returning to numeric axis searches.
7. Do not merge v41/v42 experimental branches to production main.
