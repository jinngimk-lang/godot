# Peel Calm reference convergence checkpoint 65 — label identity and adhesive backing integrated

Date: 2026-08-17

## Stable production baseline

- Product merge: PR #101 `feat: differentiate label backing and adhesive residue`.
- Merged production head: `6a743b562883eedb4227da5bc1cdfb21c232a286`.
- Fresh merged-main Godot Check: `32006233403` — PASS.
- Fresh merged-main runtime artifact: `9280118093` (`peel-calm-reference-frames`), digest `sha256:9e734def1cbc64bbb41ec936d4db4d80acf7653c7bde1e0d30f72924063009ba`.
- Locked acceptance references remain `cafe_v1`, `bar_v1`, `market_v1`; runtime/staging frames remain evidence only.
- The owner composite `PEEL CALM v0.9.0` is a multi-scene + guided-step UX reference, not a single Café beauty frame.

## Previously integrated journey work retained

Checkpoint 64 / PR #99 established the guided three-scene journey:

- explicit `SCENE 1/3 -> 2/3 -> 3/3` presentation;
- pointer/touch Café / Bar / Market JourneyRail;
- explicit post-peel Continue destination;
- `Q/E` and `1/2/3` remain expert shortcuts but are not required to understand or continue the experience;
- `R` remains Reset, not overloaded as Next.

Fresh PR #101 main verification preserved that guided flow and its scene/product ownership smokes.

## Loop completed in this checkpoint

Owner-reported Meso red: the three products differed but their labels still read like the same sticker with changed print, and the peeled surface lacked a readable glue/tack/backing impression.

### Root causes proven

1. Scene variants changed print copy/label dimensions but shared one substrate/material family.
2. Clean pulls produced no `ResidueVisual` because damage residue was the only path that exposed residue geometry.
3. The first independent backing material could exist yet remain visually hidden because the loose label did not physically roll to expose its underside.
4. Damaged backing initially fragmented into narrow cells that read as small dark squares rather than torn paper.
5. Earlier staged partial-peel captures could show a `*_peelXX` filename while the HUD still said `Peel 0%`, so that evidence was rejected and the capture harness was repaired.

## RED / GREEN history and rejected candidates

### Scene-specific substrate + clean adhesive RED

Added contracts requiring:

- a distinct `label_profile` for Café / Bar / Market;
- profile-driven label substrate roughness, thickness and fiber behavior;
- a clean partial peel to expose one translucent adhesive/contact film even with zero damage residue;
- damaged peel to add a separate dry fiber backing layer.

Initial RED exact head `15b62d6...` failed Unit while import/default launch passed, proving the profile/clean-trace contract was absent.

### Evidence-harness correction

A machine-green implementation was not accepted because the partial-peel artifact did not tell the same state story as the image. `tests/capture_reference_frames.gd` was changed so:

- Café `peel38` = clean adhesive only;
- Bar `peel48` = damaged adhesive + fibers;
- Market `peel45` = clean adhesive only;
- HUD and JourneyGuide explicitly match staged 38/48/45% progress;
- capture asserts clean = exactly one glue-film surface and damaged = layered adhesive + fiber surfaces.

### Independent peeled backing RED / GREEN

A separate `test_label_backing_material.gd` contract required:

- a real matte backing material with no printed front texture;
- distinct Café / Bar / Market backing signatures;
- physical partial-peel backing/glue-side/edge surfaces.

The focused test fixture was corrected to run `LabelVisual._ready()` before mesh surface assertions; the visual contract itself was not weakened.

### Flap-roll RED / GREEN

Visual review still rejected the machine-green backing because it remained hidden behind the front face. Added a deterministic paper rule:

- only the peeled region may roll;
- free edge rolls to about 150 degrees;
- roll decays smoothly through the loose span;
- peel front and attached stock remain at 0 degrees.

RED head `fa93d208...` failed only because `get_peel_roll_angle` did not exist; import/default launch passed. Production then rotated the peeled sheet height axis around its local centerline tangent, making the matte backing/glue-side camera-readable without changing hand, camera or controller authority.

### Damaged residue-shape RED / GREEN

Visual review rejected narrow/dark residue cells. Added deterministic broad-fiber island contract:

- damaged backing uses 3..5 broad spans;
- every span remains inside peeled width and has readable minimum width;
- clean peel never fabricates fiber islands.

`ResidueVisual` now draws broad irregular torn-paper islands from the same spans used by the test, plus glossy tack streaks. Final bounded material correction makes damaged fiber backing near-opaque and keeps the Bar uncoated backing pale enough to read as paper rather than brown blocks.

## Final exact PR evidence

The original content candidate was `f944ffeb9c45a2b94727a036abaec76c8b7587fd`, but PR ancestry became stale when checkpoint 64 advanced main. It was not merged directly.

A content-preserving two-parent ancestry sync incorporated latest `main@cea8d7a345541ef59c04840d58f79225d8ac6c99` without changing the v85 product bytes.

Final exact PR #101 head:

- `09b20441625c3a84b5868c888b050a6ecbefff34`.
- Merge base exactly matched checkpoint-64 main.
- Diff reduced to the intended 9 v85 files.
- Exact PR Godot Check `32005412998` — PASS.
- Exact PR runtime artifact `9279833862`, digest `sha256:b54e9224aa90bdab19b798546dd7ac9c3ff69a1e199224263aa4d91b647e90ad`.
- Fresh exact-head `cafe_peel38`, `bar_peel48`, `bar_inspect`, `market_peel45`, `market_inspect` were re-inspected after ancestry sync; no visual regression.

### Independent Challenger

- Local Challenger run `32005646222` reviewed exact PR #101 head `09b20441625c3a84b5868c888b050a6ecbefff34`.
- Result: `VERDICT: VERIFIED`, `DEFECT: NONE`.
- Codex Challenger completed independent deterministic verification but failed at the external model step; that run was not treated as VERIFIED.

## Fresh merged-main verification

After protected unchanged-head merge:

- merge commit `6a743b562883eedb4227da5bc1cdfb21c232a286`;
- automatic main Godot Check `32006233403` — PASS;
- fresh runtime artifact `9280118093`, digest `sha256:9e734def1cbc64bbb41ec936d4db4d80acf7653c7bde1e0d30f72924063009ba`;
- fresh merged-main Café and Bar partial-peel frames were re-inspected and retained the accepted label/backing/tack behavior.

## Multi-scale status after merge

### Macro — still RED / stop-conditioned

1. **R1 realistic hand anatomy / vessel enclosure remains the largest visual mismatch.** Current XR-derived hands still do not match the locked references' natural support grip and realistic pinch anatomy.
2. The existing stop condition remains active: do not resume CCD, endpoint chasing, semantic-grip sweeps, wrist/orbit/yaw/translation grids or disguised numeric hand-pose search without genuine live native-Blender/native-rig visual authoring or a structurally better hand source.
3. The present runtime does not expose live Blender MCP, so R1 remains tool-blocked rather than numerically reopened.

### Meso — improved, not photographic-complete

- Café / Bar / Market label substrate identity: materially separated.
- Peeled underside/backing: camera-readable through deterministic flap roll.
- Clean adhesive trace: present for careful peel.
- Damaged Bar backing: separate broad pale torn islands over glossy tack.
- Residue/tack is improved but not claimed photographic-perfect; owner playtest remains a final sensory/aesthetic gate.
- Venue/background depth/readability remains an independent candidate Meso/Macro red and should be re-ranked from fresh evidence rather than assumed.

## Audio diagnosis and next active branch

Owner feedback: reduce the music-like background sound.

Repository diagnosis found no independent BGM player. The likely music-like bed is the continuous `AdhesiveSlow` / `AdhesiveFast` loop pair in `scripts/audio/peel_audio.gd`, which previously could lift near foreground levels under high tension while tactile release one-shots carry the desired ASMR hierarchy.

Successor branch already exists from the v85 exact candidate:

- branch: `fix/quieter-adhesive-foley-v86`;
- current production candidate before ancestry sync: `0919f1a60f0f7dfbd7108c84d609ce4589e22d15`;
- pure mix contract requires continuous loop maxima to remain subordinate to release transients while staying quietly audible;
- Godot Check `32006123121` — PASS on that branch head;
- no Foley event routing was removed; `paper_flex`, `micro_release`, `final_release` remain the tactile foreground events.

Because main has now advanced through PR #101 and this checkpoint, the next run must synchronize v86 with the latest main, rerun exact combined gates, and only then open/review/merge a narrow audio PR.

## Do not repeat

- Do not treat the composite multi-scene reference as one Café camera target.
- Do not require `Q/E` to continue the main journey.
- Do not use a staged partial-peel filename as visual proof if HUD/Guide state disagrees.
- Do not equate a generated backing material with visible backing; product-camera evidence must show it.
- Do not return to narrow square-cell residue geometry for damaged paper backing.
- Do not claim glue/residue photographic perfection from deterministic tests alone.
- Do not reopen blind numeric hand-pose search while the Blender authoring capability is unavailable.

## Next exact action

1. Read latest `main`, this checkpoint, active PRs/branches and fresh runtime artifact.
2. Synchronize `fix/quieter-adhesive-foley-v86` onto latest main without altering its bounded mix change.
3. Rerun exact-head Godot Check; preserve the pure `get_continuous_mix_targets` contract and unchanged tactile-event routing.
4. Run exact-head Local Challenger and merge only unchanged head if verified.
5. After fresh-main audio verification, re-rank the latest owner-visible reds. If live Blender/native-rig authoring becomes available, return immediately to R1 hand authoring; otherwise select the next independent Macro/Meso mismatch from fresh screenshots (likely venue/background depth or composition), not decorative Micro polish.
