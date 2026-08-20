# 2026-08-20 — Post-peel object play checkpoint

## Owner requirement

The game must not end the interaction at `label disappeared`.

After a complete peel resolves and the label leaves the hero product, the player gets a short object-only tactile play phase before moving to the next scene:

`PEEL -> FULL RELEASE -> LABEL SETTLES/LEAVES -> BARE OBJECT PLAY -> INSPECT/CONTINUE -> NEXT SCENE`

No visible hands or arms are added back.

## Approved interaction language

- Before label resolution, LMB remains direct label peel authority.
- After `LabelLifecycle.is_resolved()` becomes true, LMB is repurposed to direct object play.
- Slow/medium LMB drag can create bounded squeeze/compliance on deformable containers.
- Fast alternating horizontal LMB drags create a damped shake impulse.
- Bottle/jar liquid should lag the container during shake, giving a simple inertia cue.
- RMB drag remains product rotation/inspection.
- Wheel remains zoom.
- Continue is still explicit; object play is optional and must not trap the player.
- R/reset and scene changes must clear squeeze/shake state.

## Material-specific response

Container response must respect physical logic rather than using one generic squash animation:

- Paper cup: visibly compliant; moderate squeeze, light shake.
- Glass sauce jar: essentially rigid to squeeze; contents can lag under shake.
- Tin can: low compliance; modest metallic shell flex only.
- Clear Yuzu bottle: rigid glass; strongest readable liquid inertia during shake.
- Aluminum soda can: compliant but springy; squeeze more than glass/tin and recover calmly.

The interaction model lives in `scripts/interaction/post_peel_object_play.gd` and the runtime binding/presentation lives in `scripts/presentation/post_peel_object_play_presentation.gd`.

## Verification

Deterministic contract: `tests/test_post_peel_object_play.gd`.

Required properties:

- all five product kinds have explicit squeeze + shake profiles;
- paper cup and aluminum can squeeze materially more than glass bottle;
- alternating fast drag produces visible bottle shake;
- bottle shake produces liquid inertia tilt;
- squeeze remains bounded and recovers toward rest after release;
- runtime scene includes `PostPeelObjectPlayPresentation` and activates only after label resolution.

## Completion bar

This phase is not final polish. After mechanics are green, capture and inspect resolved/play states against practical target images. The product should feel like a tactile object on the desk, not a static model with a UI animation. Continue the project-wide order from `.agents/PROJECT_NORTH_STAR.md`: scene quality -> model quality -> label material -> post-peel handling -> complete flow.
