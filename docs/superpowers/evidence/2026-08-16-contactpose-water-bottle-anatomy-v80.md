# ContactPose water-bottle anatomy evidence v80

Date: 2026-08-16
Branch lineage: `spike/contactpose-water-bottle-reference-v80`
Verified analysis head: `780e9fbf2bd79453174eedd6e253136a8e281497`
ContactPose run: `31920195819` — PASS
Godot Check: `31920195834` — PASS
Artifact: `9256129666` (`contactpose-water-bottle-reference-v80`)

## Scope and provenance

This is **staging anatomical-reference evidence only**. It does not alter the Peel Calm production hand, gameplay, MPFB rig, or locked visual acceptance set.

Source: Facebook Research / Georgia Tech ContactPose public Explorer water-bottle annotations. ContactPose documents code as MIT and all data other than separately licensed 3D object models as MIT. This spike reads only the 21-joint hand annotations. It does **not** download or redistribute MANO code/models and does not use ContactPose object meshes.

The public Explorer probe found:

- 96 `water_bottle` annotation files.
- 137 valid 21-joint hand skeleton candidates.
- Both `use` and `handoff` functional intents.

## Why this matters for Peel Calm R1

The real bottle-grasp set directly falsifies the repeated synthetic-grasp failure mode seen in the MPFB v32–v78 experiments. A plausible cylindrical support grasp is not four digits with the same curl/axis or a flat screen-space fan. Across the strongest real candidates, the useful recurring structure is:

1. index is generally the least closed opposing digit;
2. middle and ring close more strongly;
3. pinky often closes deepest;
4. the four digit chains occupy materially different palm-normal depths rather than collapsing into a sheet;
5. the thumb forms a separate opposition relationship rather than merely extending sideways;
6. palm/wrist placement and digit depth ordering must be solved together.

These are **anatomical grammar cues**, not automatic acceptance metrics. Final acceptance remains the locked Peel Calm `bar_v1` / `market_v1` references and real product-camera frames.

## Highest-ranked real candidate

Source session: `full1_use`, hand 0.

Triage-only measurements:

- index flex: 30.59°
- middle flex: 42.17°
- ring flex: 48.97°
- pinky flex: 60.63°
- mean flex: 45.59°
- increasing-closure progression: 10.02°
- thumb-to-opposing-tip-centroid distance: 0.628 palm widths
- digit depth span: 1.449 palm widths
- fingertip depth span: 0.653 palm widths

Palm-local normalized OpenPose-21 joints (wrist = origin, palm width = 1):

```json
[
  [0.0,0.0,0.0],
  [0.3909201,0.3754289,-0.4090531],
  [0.5998603,1.0039847,-0.7491715],
  [0.5938057,1.5455509,-1.0039943],
  [0.7884574,1.7364826,-1.3580615],
  [0.6384583,1.4582079,-0.1551605],
  [0.7260636,2.131234,-0.6495042],
  [0.7218494,2.2842822,-1.0664406],
  [0.7312239,2.2384765,-1.4488096],
  [0.2602413,1.5512913,0.0],
  [0.366044,2.2866931,-0.4618157],
  [0.3457675,2.2883722,-1.0538678],
  [0.3311972,2.1091526,-1.4225456],
  [-0.070554,1.5272918,-0.0299166],
  [-0.0188873,2.1792371,-0.4109396],
  [0.0652926,2.1080055,-0.8819791],
  [0.0411281,1.9099514,-1.1628697],
  [-0.3615417,1.4582079,-0.1551605],
  [-0.3318089,1.9215064,-0.4838819],
  [-0.2698854,1.8438822,-0.6926064],
  [-0.2151044,1.5882432,-0.7955861]
]
```

This candidate is useful because the index→middle→ring→pinky closure progression is explicit while the fingertips also occupy different depth layers. It must **not** be copied blindly into the GameEngine rig; it is a visual/anatomical blueprint for native-rig artist posing.

## Other useful candidates

The artifact contains three orthogonal skeleton sheets (palm, side, depth) for the top 12 real bottle grasps. Several candidates show stronger thumb separation than rank 1, notably `full49_handoff` hand 1 and `full34_use` hand 0, while preserving substantial digit-depth separation. They should be used as secondary references when shaping thumb opposition rather than turning the ranking score into a pose optimizer.

## Decision

**Do not reopen CCD, endpoint chasing, shared-axis curl, angle sweeps, or screen-space numeric tail authoring.**

The next productive use of this evidence is to place a read-only ContactPose ghost skeleton / landmark guide beside the native MPFB GameEngine artist-authoring scene, then visually pose the actual GameEngine rig against the locked bottle and product-camera intent. The existing artist-ingest gate remains the acceptance bridge; ContactPose data never becomes a production runtime dependency.
