# Substrate Peel Feel v4

This checkpoint continues the object-only / no-hands direction and specifically addresses the owner feedback that a generic label can still feel like soft tape even after static-load creep is fixed.

## Runtime rule

Every playable variant now owns a `peel_feel` profile that is bound into both the interaction controller and the visible paper renderer on scene switch.

Fields:

- `motion_pixels_per_release` — how much outward pointer work is required for full release drive in a frame. Higher = more resistance / slower peel for the same cursor motion.
- `breakaway_multiplier` — extra release peak during the first ~24% of the peel.
- `bend_band_ratio` — fraction of the detached region allowed to flex near the peel front. Lower = stiffer/thicker paper.
- `backing_thickness` — visible opaque backing separation used by the real-time released paper mesh.

## Current five materials

- Coffee thermal/order sticker: `3.25 px`, `1.24x` breakaway, `0.12` bend band, `0.0034` backing.
- Rustic jar paper: `4.10 px`, `1.34x` breakaway, `0.09` bend band, `0.0052` backing. This is the heaviest / most resistant paper in the set.
- Tin grocery wrap: `3.55 px`, `1.22x` breakaway, `0.11` bend band, `0.0042` backing.
- Yuzu coated paper: `2.75 px`, `1.12x` breakaway, `0.15` bend band, `0.0028` backing. Cleaner and easier to peel.
- Thin soda wrap: `2.40 px`, `1.08x` breakaway, `0.19` bend band, `0.0022` backing. Thinnest and most compliant.

## Wiring

`SubstratePeelFeelBinding` watches the active `SessionModel` variant and the current `PeelController`. It re-applies feel parameters after every scene switch / controller replacement and updates `CornerPeelPresentation` at the same time.

Do not move these values into hand animation, hidden hand proxies, or full-screen reference playback. The authority remains:

`mouse displacement -> controller load / motion gate -> PeelModel release -> CornerPeelPresentation paper response`.

## Verification

Exact-head Godot 4.7.1 run `32117131925` at `1a5f1780c...` passed import, configured launch, all deterministic tests, all interaction smokes, and the five-scene attached / mid / fully released screenshot triplets.

If later tuning changes the numbers, preserve the relative material ordering unless runtime evidence justifies a different physical feel: rustic jar > tin/coffee > coated Yuzu > thin can wrap for stiffness/work requirement.
