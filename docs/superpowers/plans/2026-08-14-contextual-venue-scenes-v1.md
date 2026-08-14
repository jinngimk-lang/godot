# Contextual Venue Scenes V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Couple each existing tactile cup variant to a distinct presentation-only venue with matching table/background/lighting while preserving all gameplay authority and interaction contracts.

**Architecture:** Add `scene_profile` data to `SessionModel`, implement `VenuePresentation` as an isolated procedural `Node3D`, and have `peel_lab.gd` forward the current profile whenever the variant changes. All new visuals remain repository-local and presentation-only.

**Tech Stack:** Godot 4.7.1, GDScript, procedural MeshInstance3D/Light3D nodes, existing SessionModel variant dictionaries.

## Global Constraints

- Runtime must not require external downloads or third-party Godot plugins.
- Venue presentation must never decide peel/crumple/session/input gameplay state.
- Existing camera/cup/hand interaction framing remains stable.
- Generic fictional venues only; no real-brand trade dress.
- Unknown scene ids fall back to café.
- Full canonical Godot Check must pass on the exact reviewed head.

---

### Task 1: Lock the scene-profile data contract

**Files:**
- Modify: `tests/test_session_model.gd`
- Modify: `scripts/session/session_model.gd`

**Interfaces:**
- Produces: `Dictionary current_variant()["scene_profile"]` with stable `id`, table/background/accent/light fields.

- [ ] Add failing assertions that all three variants have unique `scene_profile.id` values in order: `cafe_window`, `night_bar`, `market_coldcase`.
- [ ] Run Godot Check and confirm RED is specifically missing scene profiles.
- [ ] Add the three profile dictionaries to `SessionModel.VARIANTS`.
- [ ] Re-run and confirm the profile contract passes.

### Task 2: Add presentation-only venue switching

**Files:**
- Create: `tests/test_venue_presentation.gd`
- Modify: `tests/test_runner.gd`
- Create: `scripts/presentation/venue_presentation.gd`

**Interfaces:**
- Consumes: `Dictionary scene_profile`.
- Produces: `apply_profile(profile: Dictionary) -> void`, `get_active_profile_id() -> String`, and named roots `CafeVenue`, `BarVenue`, `MarketVenue`.

- [ ] Add a failing test that instantiates `VenuePresentation`, applies all three profiles, verifies active id/root exclusivity, and verifies unknown ids fall back to café.
- [ ] Run Godot Check and confirm RED because `VenuePresentation` is missing.
- [ ] Implement reusable procedural café/bar/market groups plus a shared table/counter and accent light.
- [ ] Re-run units and scene smoke until GREEN.

### Task 3: Wire venue profile into the playable scene

**Files:**
- Modify: `scripts/peel_lab.gd`

**Interfaces:**
- Consumes: `variant.get("scene_profile", {})`.
- Calls: `_venue.apply_profile(...)` inside `_apply_current_variant()`.

- [ ] Add/build `VenuePresentation` in `_build_world()` before interactive cup presentation.
- [ ] Remove the old hard-coded single table from `peel_lab.gd`; table ownership moves to `VenuePresentation`.
- [ ] Forward the current variant profile during every variant application.
- [ ] Run complete Godot Check including default F5, units, scene, café, crumple, forearm, ritual loop, reset/pause isolation.

### Task 4: Exact-head review and visual evidence

**Files:**
- No gameplay production files unless review finds a defect.

- [ ] Compare branch against base and verify only intended docs/session/test/presentation/scene-wiring files changed.
- [ ] Open PR with explicit presentation-only claims and experiential caveats.
- [ ] Trigger independent Challenger through the owner-only dispatcher.
- [ ] Capture/inspect a real rendered frame for each venue when available; machine checks may prove geometry/visibility but not aesthetic quality.
