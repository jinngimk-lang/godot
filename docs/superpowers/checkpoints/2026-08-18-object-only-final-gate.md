# Object-Only Final Gate

Date: 2026-08-18

Read this after `2026-08-18-object-only-north-star.md` if work resumes.

## Direction remains locked

- No visible hand/arm models.
- No video/still gameplay playback layer.
- Mouse directly drives peel simulation and visible flap.
- Small white hand cursor is rendered inside the gameplay viewport.
- Five directly selectable hero scenes: Coffee Shop, Jar, Tin Can, Supermarket, Can.
- Approved visual composition remains the owner-selected no-hands Coffee Shop mockup.

## Final architecture now in branch

- `PeelLab` owns mouse input, peel controller, rotation, zoom, reset, pause, scene selection.
- `CornerPeelPresentation` owns the visible label. The old `LabelVisual` stays hidden and only supplies scalar simulation/surface math.
- Corner peel uses separate attached and detached mesh surfaces so unpeeled print does not stretch.
- Visible corner area is intentionally smaller than scalar progress so a 38% gameplay peel keeps most label copy readable, as in the reference.
- `CursorPresentation` renders the repository-owned `assets/ui/peel_cursor.svg` in the actual Godot viewport.
- `HeroProductDetailPresentation` replaces primitive jar/tin/soda silhouettes with manufactured lathed/detail geometry while keeping the hidden interaction cylinder stable.
- The large procedural table is no longer rendered; the photographic reference backdrop owns the visible counter and real-time product contact shadow grounds the hero object.
- GL Compatibility metal is intentionally less physically metallic than raw aluminum so Tin/Can remain visually silver without reflection probes.

## Local runtime verification

A fresh branch archive was downloaded and executed locally with the same Godot 4.7.1 release used by CI. The following were run against that snapshot:

1. headless editor import/parse;
2. deterministic `tests/test_runner.gd`;
3. Xvfb GL Compatibility execution of `tests/capture_reference_frames.gd`;
4. generation of all ten base/mid-peel reference frames.

This local run is in addition to the repeated GitHub Actions exact-head runs recorded in the earlier checkpoint.

## Visual acceptance intent

Coffee Shop now has the intended composition fundamentals: warm kraft cup, visible molded lid angle, photographic café environment/counter, readable printed order sticker, localized top-right flap, adhesive trace, software hand cursor, left controls, right HOW TO PLAY, and persistent five-scene rail.

Jar / Tin Can / Supermarket / Can share the same interaction language but use distinct hero silhouettes and label material behavior.

If future work changes any of those fundamentals, treat it as a direction regression unless the owner explicitly changes the north star.
