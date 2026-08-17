# Peel Calm reference convergence checkpoint 61

Date: 2026-08-17
Current merged main: `b7199073be9983e2809f5677421f723cfe8cab30`
Product PR: #79 — merged
Verifier infrastructure PR: #80 — merged
Locked references: `cafe_v1 / bar_v1 / market_v1`

## Exact evidence

### Product repair
- Baseline main before this loop: `747ae6f2fe09d61a482abca4ac6c744f02e65a41`.
- Baseline runtime artifact: `9272674656`.
- Initial hypothesis: the bright cyan shoulder/neck block in `market.png` was a solid bottle-mouth/lip primitive.
- RED mouth-contract head: `5428a1e3f105a797b113fbc5f7ac752fdec85fb8`; Godot Check `31984781387` failed the new hollow-mouth assertions.
- Mouth-only GREEN head: `5453c53de6048491f550e2a4e3d36019225ccd45`; Godot Check `31984829145` passed; runtime artifact `9273433389` proved the cyan block still existed. **The visual hypothesis was therefore rejected even though CI was green.**
- Root cause: the three deterministic market ice cubes were staged at the generic cup-rim height (~0.74 local Y), placing them inside the visible clear-bottle shoulder/neck where they merged into a bright cyan pseudo-cap.
- Glass-ice RED head: `866d8ce5f6f29cb4ee51404040056571c95e10a9`; Godot Check `31984966599` failed exactly because base/motion ice centers exceeded the new glass-body ceiling (`0.34`).
- Candidate GREEN head: `72964caf204a76f2a351477999e6371928b92b44`.
- Candidate push Godot Check: `31985025306` — PASS.
- Candidate runtime artifact: `9273486681` — market base/inspect/peel show the cyan pseudo-cap removed from the shoulder; ice now sits in the liquid/body region.
- PR exact-head Godot Check: `31985130400` — PASS.
- Product merge commit: `b7199073be9983e2809f5677421f723cfe8cab30`.
- Post-merge Godot Check: `31985682053` — PASS.
- Post-merge runtime artifact: `9273696188`.

### Independent Challenger
- Local Challenger round 1 failed as infrastructure, not product: packet `49,817` bytes exceeded the `42,000` byte safety budget.
- A permanent synthetic multi-file packet test exposed a second verifier defect: `git show | head -c` can return SIGPIPE/141 under `pipefail`.
- Verifier RED head: `0a5491faa6337bf417ae63db609d0b8a449461c9`; Godot Check `31985255155` failed in the new self-test.
- Verifier GREEN head: `204668cebc31851448a2bb5062c27b0c7ddde3e4`; packet self-test `31985298926` PASS; Godot Check `31985298901` PASS.
- Verifier PR #80 merged as `179dcc6f1e7852f1c69171200c84eac404e60e35`.
- Local Challenger round 2 on exact product head completed successfully. A duplicate dispatch produced one style-only `NEEDS_FIX` claiming code duplication with non-actionable `MIN_TEST: 50`; builder triage rejected it because `_sync_open_top_for_contents` contains one shell-aware branch and the required behavior already has deterministic paper/glass regression gates. A second independent exact-head round-2 run returned `VERDICT: VERIFIED` and the enforced Challenger workflow completed successfully (`31985403604`).

## What this loop changed

1. Visible bottle glass is open at the mouth rather than capped by the old solid disk; a hollow transparent `BottleMouthRim` owns the visible rim.
2. `CupContentsPresentation` now supports an optional `contents_profile.max_center_y` envelope.
3. Market clear-glass ice uses `max_center_y = 0.34`, keeping deterministic cubes in the bottle body/liquid region during base and motion states.
4. Paper-cup ice keeps its existing rim-readable staging when no ceiling is configured.
5. New smoke gates prevent glass ice from escaping into the shoulder/neck.
6. Local Challenger generic packets now keep bounded evidence from every changed GDScript/test file without SIGPIPE and remain under the model safety budget; a permanent synthetic self-test guards this.

## Visual comparison result

### Macro
- **Improved:** market bottle no longer reads as having an oversized cyan plastic closure in the shoulder.
- Café/bar Macro composition is unchanged by the product repair.

### Meso
- **Improved:** the clear bottle shoulder/neck is now readable as bottle geometry rather than being occupied by an ice slab at rim height.
- The visible ice cluster is still too geometric/merged from the front camera and remains a secondary Meso/Micro red.

### Micro
- No claim of photographic ice/glass completion. Current ice is still opaque/blue and box-like; glass/ice material quality remains below the reference.

## Remaining reds, ranked

### R1 — Hero support-hand anatomy / vessel enclosure
Still the dominant project-wide mismatch. The current authored XR hands remain faceted and the support hand does not achieve the photographic wrap/enclosure of the references.

**Stop condition remains active:** do not resume another blind numeric CCD/endpoint/local-axis/orbit/yaw/translation sweep. Previous checkpoint evidence has exhausted those approaches. Resume only with a true live/native-rig visual-authoring path or a structurally different hero-hand asset pipeline.

### R2 — Peel-hand whole-hand pinch choreography
Thumb/index contact is better than the prototype but the complete hand silhouette still does not convincingly pinch the lifted flap through the full peel arc.

### R3 — Clear-bottle ice readability
The shoulder placement bug is closed, but the three cubes visually merge into a broad cyan block from the product camera. Next improvement should separate the cubes spatially and reduce the opaque saturated-blue read while preserving all deterministic bounds and V6 count/state contracts.

### R4 — Glass / liquid photographic cues
Clear and amber bottles still need stronger wall-thickness/reflection cues, less synthetic transparency, and better integration with the backdrop.

### R5 — Surface detail
Paper fibers, torn-label thickness, residue breakup, condensation and skin response remain below final-reference quality.

## Failed hypotheses / do not repeat

- Do not assume a suspicious screen-space block belongs to the nearest semantic mesh. The mouth-only fix passed CI but real-frame A/B disproved the visual hypothesis; always use runtime capture to identify the true owner.
- Do not relax visual acceptance simply because an exact-head test passes.
- Do not restart numeric hand-pose search while checkpoint 60/61 stop conditions remain in force.

## Next exact action

1. Start from `main@b7199073be9983e2809f5677421f723cfe8cab30` (or newer exact main if it advances).
2. Inspect post-merge artifact `9273696188` against `market_v1`.
3. Unless a higher-impact non-hand structural regression appears, attack R3 with a deterministic **three-cube readable cluster**: spatially separate cube centers in X/Y/Z within the existing body ceiling and tune ice material toward translucent neutral/cool glass rather than opaque cyan.
4. Add objective tests for separation/bounds before production changes.
5. Capture market base/inspect/peel and reject the change if the cluster becomes less believable even if tests pass.
6. Keep R1 blocked until live/native-rig authoring or a new hero-hand mesh path is actually available.
