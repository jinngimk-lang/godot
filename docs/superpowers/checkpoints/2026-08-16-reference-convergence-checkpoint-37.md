# Peel Calm reference convergence checkpoint 37

Date: 2026-08-16
Production main: `769d6452e75112084f537af99be90721c2629cd5`
No product PR opened from the MPFB staging work.
Locked acceptance references: `bar_v1`, `market_v1` (plus unchanged `cafe_v1` family).

## Why this checkpoint exists

Checkpoint 36 closed numeric/screen-space pose authoring (`tail_px`, `away_from_camera`, CCD, endpoint chasing, contact servos, coefficient/angle sweeps, and whole-hand orbit searches). The remaining R1 is not a request for another optimizer. It is a need for a believable whole-hand support grasp whose silhouette matches the locked bar/market reference intent.

This loop therefore changed capability rather than tuning more pose numbers.

## v79 — real-human water-bottle anatomy source

Branch: `spike/contactpose-water-bottle-reference-v79`
Verified head: `c7467fc3aa1caf7d2dea36d699884a820f1891ce`
ContactPose analysis run: `31917558329` — PASS
ContactPose analysis artifact: `9255366556`
Exact-head Godot Check: `31917558415` — PASS
Runtime reference-frame artifact: `9255366784`

### Source and rights boundary

- Source: public ContactPose Explorer / `facebookresearch/ContactPose`.
- The official object list contains `water_bottle`.
- The Explorer publicly loads static annotation JSON and renders `hands[*].joints`.
- This project uses **only the non-3D-model 21-joint annotation data**, which ContactPose documents under MIT.
- No ContactPose object mesh, MANO model/code/weights, or third-party object asset is imported into Peel Calm.

### Dead data-access paths — do not retry

1. The official ~1.98 GB sample archive downloaded successfully but contains only `full28_use`, not `water_bottle`.
2. The legacy official Dropbox grasp archive returns only an approximately 97 KB error/page payload, not the data archive.
3. Full IEEE DataPort access was not pursued because it would require normal account/access flow; no credentials, paid action, or terms acceptance was attempted.

The public Explorer path made all three unnecessary.

### Evidence result

The public Explorer yielded 96 `water_bottle` annotation files and 137 valid 21-joint hand skeleton candidates.

The selected anatomical reference is **`full6_use`, hand 1**. It was selected by visual palm/side/depth review rather than numeric rank alone because it best matches the locked support-grip grammar:

- index flex: ~24.07°
- middle flex: ~30.93°
- ring flex: ~48.40°
- pinky flex: ~61.42°
- thumb-opposition distance: ~0.410 palm widths
- digit depth span: ~1.433 palm widths

The important qualitative pattern is index-light → progressively deeper middle/ring/pinky enclosure with a separately opposing thumb.

## v80 — one-shot exact anatomical direction retarget

Branch: `spike/contactpose-direct-retarget-v80`
Verified candidate head: `4e97eb6822daad390e6cea2e3cff5f64e85fb740`
Exact-head Godot Check: `31917750229` — PASS
Runtime reference-frame artifact: `9255424061`
MPFB direct-retarget run: `31917750233` — PASS
MPFB retarget artifact: `9255449495`

### Falsifiable hypothesis

If the major remaining problem were simply that scripted Peel Calm finger directions were anatomically wrong, then transferring the selected real-human ContactPose phalanx directions exactly onto the native MPFB GameEngine digit chains—while freezing the proven wrist/palm placement—should make the 192×108 silhouette read as a cylindrical support grasp.

### Controls

- exactly one source candidate (`full6_use`, hand 1);
- no CCD;
- no endpoint optimizer;
- no contact servo;
- no coefficient search;
- no parameter sweep;
- no post-retarget pose correction;
- wrist/palm placement frozen;
- same-rig durable pose saved.

### Structural result

- maximum post-alignment direction error: `0.0°`;
- wrist matrix delta after retarget: `0.0`;
- only 1/4 non-thumb fingertips reached the measured far side of the vessel;
- thumb remained on the same broad side as the four-finger group.

### Visual verdict: **REJECT**

The unobstructed anatomy is materially more natural than the old parallel-finger/shelf experiments, which validates the source anatomy. But the with-vessel 192×108 frame still reads as a hand resting/pressing on the bottle rather than wrapping it. Macro enclosure and clear thumb opposition remain absent.

Because the transfer already achieves 0° source-direction alignment, **direct ContactPose direction retarget is now closed**. Do not tune retarget coefficients, angles, offsets, or add a second automatic retarget candidate. That would recreate the parameter-search path already closed by checkpoint 36.

## Locked acceptance image access

`art/acceptance_refs/v1/MANIFEST.md` confirms the original approved PNGs are persisted in the user project library as:

- `/Peel Calm/Acceptance References/v1/bar_reference.png`
- `/Peel Calm/Acceptance References/v1/market_reference.png`

and gives their exact SHA-256 hashes. The current automation environment can discover the matching File Library images and their captions/metadata, but cannot obtain the raw image bytes through the available File Library fetch path. Therefore this loop did **not** invent or hallucinate 2D hand landmarks from descriptions.

When raw locked reference bytes become directly available to an execution environment, the preferred next evidence upgrade is to extract/annotate the actual support-hand silhouette/landmarks from those approved images and use them as visual guidance. Those derived landmarks are explanatory evidence, not a replacement acceptance target.

## v81 — real-grasp ghost-guide authoring capability

Branch: `spike/contactpose-ghost-guide-v81`
Current code head before this checkpoint: `8f1ae41141f3465b915481c9452c45f578b07a0d`
Exact-head Godot Check: `31918022272` — PASS
Runtime reference-frame artifact: `9255498445`
MPFB ContactPose Ghost Guide run: `31918022360` — in progress at checkpoint-write time

### Purpose

v81 does **not** create another automatic pose candidate. It regenerates the native GameEngine-rig v77 authoring scene, leaves the hand pose unchanged, and overlays the selected real-human ContactPose `full6_use` / hand 1 21-joint skeleton as visible ghost geometry in the same palm-local frame.

The saved `.blend` contract is:

- native MPFB GameEngine hero rig;
- current vessel/camera/wrist/palm authoring setup;
- only the 12 non-thumb finger pose bones selected for direct visual editing;
- real-human ghost skeleton visible as anatomical guidance;
- ghost marked annotation-only / MIT / guide-only;
- no automatic retarget;
- no solver/sweep/optimizer;
- in-scene text explicitly says the ghost is not an acceptance replacement.

The objective is to make genuine visual posing materially easier in a Blender viewport/editor without converting the anatomical guide back into another number search.

## Current red ranking

### R1 — whole-hand support grasp Macro/Meso

Still open. A passing candidate must read at first glance as a relaxed but firm bottle support grip: palm engages the vessel, index is relatively light, middle/ring/pinky progressively wrap around the far contour, and thumb visibly opposes them.

### R2 — Godot product-camera proof

Blocked on R1. Once R1 passes, compare the continuous MPFB limb directly with the XR baseline in real bar/market product FOV and interaction-step captures.

### R3 — peel-hand flap pinch

Blocked behind support-hand R1/R2.

### Micro — skin/PBR, paper fibers, glass micro-highlights, condensation

Frozen until Macro/Meso hand structure passes.

## Closed / do not repeat

- CCD / endpoint chasing;
- contact-distance servo;
- shared-axis or per-joint angle sweeps;
- whole-hand orbit sweeps;
- `tail_px` / `away_from_camera` numeric screen-space authoring;
- direct ContactPose direction retarget tuning;
- old broken ContactPose Dropbox archive;
- re-downloading the 1.98 GB ContactPose sample in search of `water_bottle`.

## Next exact action

1. Complete v81 MPFB run and reopen-contract verification.
2. If v81 is technically valid, persist its artifact/run IDs here; do **not** call R1 solved.
3. Use the resulting ghost-guide `.blend` for direct native-rig visual posing when an execution environment has a real interactive Blender viewport/editor, or when the locked acceptance PNG bytes become directly accessible for reference-landmark overlays.
4. The first visually authored candidate must be singular, not a sweep, and must pass both the 192×108 Macro vessel-grip gate and unobstructed oblique Meso anatomy gate before any Godot integration.
5. Keep production `main` untouched until that proof exists.
