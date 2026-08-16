# Peel Calm reference convergence checkpoint 53

Date: 2026-08-16
Production branch: `main`
Verified product merge before this checkpoint: `62de386239ce80c317ec6ffdd3a4e1d7f665129a`
Locked acceptance references remain: `cafe_v1`, `bar_v1`, `market_v1`

## Production change merged this loop

PR #51 — `fix: capture the actual active peel pinch pose` — was squash-merged after exact-head deterministic verification and an independent local Challenger.

The merged change is **reference-capture staging only**. It does not modify production `HandVisual`, gameplay state, input ownership, progression, reset behavior, scene content, or assets.

The capture path now:

1. requests pinch target `1.0`;
2. snaps only the capture-owned smoothed `_pinch_amount` to `1.0`;
3. applies the existing authored pose and refreshes the actual thumb/index pinch anchors;
4. translates the test-owned hand root by the exact `grip_world - current_pinch` delta;
5. fails capture if `_last_authored_pose != "Pinch Tight"`;
6. fails capture if the refreshed pinch anchor is more than `0.5 mm` from the staged flap target.

This closes the evidence defect where earlier partial-peel screenshots could remain visually in the relaxed authored pose even though the capture intended an active pinch.

## Independent gate

Final PR head: `e85f79d0dc2c75c1e1aa99dde29ab099d7ed19d0`.

- PR-head Godot Check `31956773780` — **PASS**.
- Focused independent Challenger run `31956791840` — **PASS / VERIFIED** after independently running the deterministic capture.
- Challenger verdict: `VERDICT: VERIFIED`, `DEFECT: none`, `MIN_TEST: none`.
- PR remained one changed file: `tests/capture_reference_frames.gd`.

## Merged-main exact-head verification

Merge commit: `62de386239ce80c317ec6ffdd3a4e1d7f665129a`.

- Merged-main Godot Check `31957055474` — **PASS**.
- Merged-main reference artifact: `peel-calm-reference-frames`, artifact id `9266224755`.
- All import/launch, unit, scene/reference smoke, label/cafe/crumple/contents/forearm/ritual, reset, pause/input-isolation gates and nine-frame capture passed on the merge commit.

## Real merged-main frame review

The nine merged-main frames were downloaded and reviewed, including:

- `cafe_peel38.png`
- `bar_peel48.png`
- `market_peel45.png`
- base / crumple / inspect states.

The partial-peel evidence is now truthful about the active authored pinch state. The right hand is visibly in the tighter authored pinch rather than silently remaining in the relaxed pose.

However, this **does not close R3**. The real frames still show a prototype-quality pinch/grasp silhouette: the thumb/index/whole-hand relationship does not yet read like the locked close-up references physically pinching the lifted paper flap. This PR fixed evidence truthfulness, not hand quality.

## R1 support-hand model path — stop condition reached

The v93 relative-digit-depth staging experiment is formally stopped. See checkpoint 52 for the detailed evidence.

Final v93 structural evidence head: `794361b1e679c9ed0eb7070153c1c3fb0e17ed4b`.

- Godot Check `31956129174` — **PASS**.
- MPFB V93 Product Camera `31956129156` — **FAIL before GLB/product-frame capture** at the structural progressive far-depth gate.
- Failure artifact `9266051926`.

A single evidence-derived per-digit sign calibration preserved the fixed 4/8/13/18° magnitudes, but the final distal-chain response remained identical to the prior failure. This proves the remaining behavior is not a simple sign convention and makes further code-authored sign/angle/magnitude guessing a disguised search.

Do not create v94/v95 angle/sign/grip/orbit/translation sweeps. Resume R1 support-pose work only when a genuinely visual/artist-authored native GameEngine/MPFB rig pose source is available. Current headless numeric scripting is not an acceptable substitute.

## Remaining reds, ranked

### R1 — Genuine artist-authored whole-hand vessel enclosure

Still the dominant Macro blocker for `bar_v1` / `market_v1`. Valid infrastructure remains: continuous MPFB limb, `-40°` side-on limb choreography, v89 continuous wrist crop, physical scale, semantic authoring controls, ContactPose read-only anatomy guides, product-camera A/B capture.

### R2 — Product-camera Meso anatomy

Blocked until R1 passes thumbnail enclosure. Then inspect web space, knuckle flow, self-intersection, progressive digit depth, separation and inspect rotation.

### R3 — Peel-hand pinch choreography

Capture truthfulness is now fixed and merged, which makes this red easier to judge. The authored pinch itself still fails reference quality and remains behind R1 support-hand Macro work unless priorities are explicitly changed by new visual evidence.

### R4+ — Skin/PBR, paper fiber, glass/liquid, condensation, HUD/micro polish

Remain frozen behind the higher-frequency gates.

## Next exact action

1. Treat `main@62de386239ce80c317ec6ffdd3a4e1d7f665129a` as the verified production content baseline before this documentation checkpoint.
2. Do **not** resume code-authored support-hand transform guessing.
3. Search only for a reversible capability that enables genuinely visual/native-rig whole-hand authoring, or ingest a real artist-authored same-rig pose if one becomes available.
4. When such a pose exists, hide all guides and judge the locked 192×108 Macro first, then unobstructed Meso, then the same Godot bar/market product-camera A/B, then independent Challenger before production replacement.
5. Continue using the newly truthful partial-peel captures when R3 is eventually resumed; never use the pre-fix relaxed-hand screenshots as pinch-quality evidence.

The project is not reference-complete. No MPFB support-hand candidate is approved for production integration.