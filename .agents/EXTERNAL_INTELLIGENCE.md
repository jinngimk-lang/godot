# Peel Calm External Intelligence Ledger

Purpose: durable, low-noise record of public technical developments that may materially improve Peel Calm. This is not a news dump. Record only findings that change a decision, deserve an experiment, or remain an important watch item.

## Operating rules

- Read current `main`, `.agents/PROJECT_NORTH_STAR.md`, `.agents/PROJECT_KNOWLEDGE.md`, current handoff, Issue #5 claims and exact CI evidence before acting on an external finding.
- Trust order: official Godot sources and official demos first; maintained upstream GitHub projects second; mature community implementations third; discussion/social material only as leads.
- Before copying external source/assets, establish exact origin, revision, license/provenance and compatibility. If that is unclear, do not vendor it.
- Prefer integrating principles, tests and small isolated implementations over dependencies.
- No material finding means no repository churn.
- Production adoption requires a narrow Issue #5 claim, isolated branch, falsifiable acceptance evidence, canonical Godot verification and merged-main recheck.

## Current watchlist

- Godot stable patch releases in the current production minor line.
- Pointer/input latency, event batching and high-polling-rate mouse behavior.
- Compatibility-renderer transparency, refraction and sorting behavior for glass/liquid/residue layers.
- Realtime product-material references for glass, metal, paper and adhesive.
- Rendering/performance regressions affecting 1280×720 object-first presentation.
- Accessibility/input changes that can improve PC mouse interaction without weakening deterministic gesture ownership.
- Maintained GitHub reference projects whose implementation or tests directly address a current North Star gap.
- Verification-toolchain drift: every persistent Builder/Challenger path must use the same production Godot patch as canonical CI.

## 2026-08-25 scan

### ADOPTED — Godot 4.7.2 stable

Source: `godotengine/godot` official `4.7.2-stable` release, published 2026-08-18.

Why it matters: official maintenance release in the currently adopted 4.7 line; upstream recommends maintenance-release adoption. It includes the high-polling-rate mouse performance fix, directly relevant to Peel Calm's repeated high-frequency LMB drag input.

Linux x86_64 editor asset: `Godot_v4.7.2-stable_linux.x86_64.zip`
SHA-256: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`

Decision: production toolchain is Godot 4.7.2. PR #164 exact head `ac727d2d5c7f09778e8a5c14e37073aedf88a1b2` passed canonical Godot Check run `32817255780`, including import, configured launch, unit/smoke gates and the 35-frame lifecycle capture artifact. PR #164 merged as `154d8cdbb3e395da540bd1c5641ec16507778ae4`; merged-main push run `32817415796` also passed. Candidate captures were manually inspected with no obvious engine-patch rendering regression.

Status: INTEGRATED + MERGED-MAIN VERIFIED.

### PROJECT INFRA FIX — autonomous verifier version drift

Finding: immediately after the 4.7.2 adoption, the persistent `agent-builder.yml` and `agent-challenger.yml` workflows were still hard-coded to Godot 4.7.1 in downloads, prompts and evidence text. The exact-head Challenger deterministic checks therefore used an obsolete engine baseline even though canonical CI and project knowledge had moved to 4.7.2.

Decision: align persistent Builder/Challenger workflows to the official 4.7.2 asset/checksum and add canonical static guards that fail if those workflows regress to 4.7.1. This is tracked on `fix/agent-toolchain-4.7.2-v1`.

Additional evidence: Codex Challenger run `32817497263` completed its exact-head checkout and deterministic Godot checks, then failed only when the Codex API reported no remaining credits. Treat that as verifier-infrastructure availability, not a game-code RED. The repository-local Ollama/Qwen Challenger remains the no-credit independent fallback.

Status: INTEGRATING.

### REFERENCE — official procedural glass material

Source: `godotengine/godot-demo-projects`, commit `34fc99545fc41520a958248f607101e7d0b95b05`, file `3d/procedural_materials/materials/glass.tres`.

Observed pattern: `StandardMaterial3D` using alpha transparency, normal mapping, refraction and triplanar UVs.

Decision: research reference only. Do not copy the file into Peel Calm yet. Our Yuzu bottle already has Compatibility-renderer transparency/sorting constraints, so any refraction/normal adoption must be an isolated visual experiment with runtime captures and no broad overlapping transparent volumes.

Status: WATCH/REFERENCE.

### WATCH — transparent-object sorting / OIT work

Finding: current Godot transparency discussions continue to identify object-level sorting limitations for overlapping 3D transparent surfaces, with OIT-style approaches discussed as future/alternative behavior.

Decision: no engine patch or community implementation is adopted. Preserve the existing project rule: avoid deep stacks of overlapping transparent closed volumes when a stable opaque/semitransparent body plus surface/edge cues gives a cleaner Compatibility-renderer result. Re-evaluate only when a stable upstream solution lands or a concrete project defect justifies an isolated experiment.

Status: WATCH.

### REJECT FOR PRODUCTION — Godot 4.8 development builds

Decision: do not move production to a development build while 4.7.x is stable. Track 4.8 features only as research until a stable migration has a specific North Star benefit and a full compatibility plan.

Status: RESEARCH ONLY.

## 2026-08-26 scan

### REFERENCE — Godot 4.7 DrawableTexture2D for local painting

Sources: official Godot 4.7 `Using DrawableTextures` documentation and the official `godot-demo-projects` 4.7 release, which includes the new 2D Drawable Textures demo.

Finding: `DrawableTexture2D` is a first-party GPU-modifiable `Texture2D` API intended for procedural texturing and real-time effects. The official tutorial explicitly demonstrates mouse-drag painting through `blit_rect()`, supports custom `texture_blit` shaders and multiple outputs, and the original accepted proposal specifically targeted a simpler painting path that could work where compute-based approaches were unsuitable for GLES3/Compatibility.

Relevance to Peel Calm: this is a stronger provenance and dependency story than third-party GPU texture-paint addons if a future residue implementation needs a denser continuous cleanup mask. It could encode exact rubbed regions directly in a texture while remaining engine-native.

Decision: do **not** replace PR #166's small deterministic cleanup grid now. Peel Calm's current former-label footprint is small, deterministic, easy to unit-test and already represented without a new GPU-state verification surface. DrawableTexture2D also has current 4.7 edge cases (for example editor `get_image()` behavior) and premultiplied-alpha support is not present in 4.7 texture-blit blending. Keep it as the preferred first-party experiment path only if grid resolution becomes visibly insufficient, irregular residue/crumb masks need denser spatial detail, or a future visual target clearly benefits from texture-space painting. Any adoption must prove Compatibility runtime behavior and deterministic reset/capture behavior on an isolated branch.

Status: WATCH/REFERENCE — preferred over third-party GPU-paint dependencies for any future texture-mask experiment.

### WATCH — Windows touchscreen drag freeze reported in Godot 4.7.2

Source: upstream `godotengine/godot` issue #122791, opened 2026-08-25, and fix candidate PR #122825, opened 2026-08-26.

Finding: the reporter reproduces severe freezing while dragging on an actual Windows touchscreen in Godot 4.7.2 stable and 4.8 dev, while 4.7.1 does not reproduce. The issue is now labeled `confirmed` in addition to `bug`, `regression`, `performance`, and `platform:windows`. On 2026-08-26 a Godot maintainer independently reproduced substantial lag after roughly 35–40 seconds of dragging on a 60 Hz Windows touchscreen, did not reproduce it with multiple pen tablets, and did not reproduce it when the same touch digitizer was mapped to a 120 Hz display. Upstream opened PR #122825, `[Windows] Process all WM_(NC)MOUSEMOVE messages when touch screen/pen input is detected`, explicitly to close #122791. The original issue reporter then tested that candidate and reported on 2026-08-26 that it resolves the issue for them. The PR remains open against `master`. Both the issue and the fix PR are currently assigned to the **4.8 milestone**, so there is still no present evidence that a 4.7.x maintenance release will contain the fix.

Relevance to Peel Calm: the production interaction target is PC mouse first, so this is still not evidence to roll back the 4.7.2 mouse fix. The reporter's successful validation makes PR #122825 materially more credible as the likely upstream mitigation, but it does not make an unreleased engine patch a production dependency. The refresh-rate-sensitive reproduction also means semantic mouse/touch ownership tests cannot stand in for actual Windows device/performance validation. The 4.8 milestone means the project should not plan touch-readiness work around an assumed near-term 4.7.x patch.

Decision: keep Godot 4.7.2 as production. Do not broaden touch support or claim Windows touchscreen readiness on 4.7.2. Track upstream PR #122825 through merge and release, plus any explicit 4.7 backport if one appears; absent such a backport, treat Godot 4.8 stable as the earliest evidenced upstream release line likely to carry the fix. Only treat the risk as mitigated after a stable build containing the fix is available and Peel Calm either passes isolated real-touch validation or has equivalent device evidence. Do not cherry-pick or vendor the engine patch into this repository.

Status: WATCH — confirmed upstream regression with a reporter-validated, open 4.8-milestoned fix candidate; touch validation remains gated, no production rollback.

## 2026-08-27 scan

### WATCH/REFERENCE — native Compatibility-renderer decals in Godot 4.8 dev4

Sources: official Godot 4.8 dev4 release notes (2026-08-26) and merged upstream `godotengine/godot` PR #118070 (`66b4826fca6400f3a7181d49077235f2f4b558f9`).

Finding: Godot 4.8 dev4 now ships first-party `Decal` support in the Compatibility renderer. The implementation is derived from the Mobile renderer and adjusted for OpenGL. Upstream documents a default soft cap of 64 visible decals per frame (hardware/buffer dependent and project-configurable) and a hard maximum of 8 decals affecting one surface. This is an engine-native path for projecting albedo/normal/ORM/emission detail onto curved or uneven realtime geometry without generating replacement meshes.

Relevance to Peel Calm: vessel-bound adhesive smears, sparse fibers, glue-roll marks and small paper crumbs are exactly the kind of localized surface detail that could benefit from projected decals, especially on jars/cans/bottles where extra transparent geometry or bespoke per-vessel residue meshes create sorting and authoring cost. The feature is also a materially better provenance/dependency story than third-party Compatibility decal plugins. However, Peel Calm is still on Godot 4.7.2, and 4.8 dev4 is a preview build; moving production solely for decals would violate the stable-engine policy. The 8-decals-per-surface limit also means this should be treated as a restrained accent layer, not a per-scrub-sample event stream.

Decision: do **not** change the current production renderer/toolchain and do **not** block or replace PR #166's deterministic spatial cleanup field. When Godot 4.8 reaches stable and a migration is independently justified (including the Windows-touch fix path), include a small Compatibility `Decal` residue/crumb experiment in the migration evaluation. Test one or a few decals driven by the existing deterministic cleanup authority, compare captures on all five hero vessels, and reject it if projection artifacts, per-surface limits, reset nondeterminism or capture instability outweigh the visual gain. Prefer this first-party path over community Compatibility decal plugins if that future experiment is needed.

Status: WATCH/REFERENCE — materially relevant 4.8 migration benefit, no current production adoption.

### WATCH — DrawableTexture updates into DecalAtlas are being developed, but GLES3 mipmaps are unresolved

Source: open upstream `godotengine/godot` PR #115653, `Add function to update Atlases (such as DecalAtlas) with changes to individual textures`, with fresh rendering review on 2026-08-27.

Finding: upstream is explicitly developing incremental atlas refresh so a `DrawableTexture2D` used by a `Decal` can change without forcing a full DecalAtlas rebuild. The PR includes both RenderingDevice and GLES3/Compatibility paths and its author supplied a minimal animated DrawableTexture→Decal example. This directly connects two Peel Calm watch paths: a dense engine-native residue mask and projected residue/crumb detail. However, the PR remains open and assigned only to the undetermined `4.x` milestone. A fresh 2026-08-27 renderer review also flags that the GLES3 implementation does not currently show how mip levels are regenerated when mipmaps are used, while the RenderingDevice side handles that case.

Relevance to Peel Calm: if this upstream work eventually lands with the Compatibility mipmap path resolved, a future stable Godot release could support a clean first-party architecture where deterministic scrub authority updates a DrawableTexture mask and a small number of vessel-projected decals consume it. Today that is not a production-ready assumption, especially because Peel Calm is specifically on the Compatibility renderer and requires deterministic capture/reset behavior.

Decision: keep the current repository-native cleanup field and the existing future-4.8 Decal experiment plan unchanged. Do **not** add a DrawableTexture→Decal dependency or design the residue system around PR #115653 while it is open. Re-evaluate only after upstream resolves the GLES3 mipmap concern, the PR merges into a stable-targeted release, and an isolated Peel Calm experiment passes all five vessels plus exact reset/capture checks. This upstream path remains preferable to a third-party dynamic-decal dependency if it matures.

Status: WATCH — promising first-party convergence of two relevant features, but current Compatibility readiness is explicitly incomplete.

## Integration log

- 2026-08-25 — owner delegated routine reversible product/engineering decisions and requested continuous related GitHub/public-information scanning plus automatic integration of worthwhile improvements. Governance design and this ledger created on `chore/autonomous-intelligence-loop-v1`.
- 2026-08-25 — Godot 4.7.2 selected as the first evidence-backed maintenance integration, passed exact-head and merged-main canonical verification, and became the production engine patch via PR #164.
- 2026-08-25 — post-merge audit found persistent autonomous Builder/Challenger workflows still pinned to 4.7.1; version-alignment repair started on `fix/agent-toolchain-4.7.2-v1`. Paid Codex Challenger is temporarily unavailable because the API account reported no credits; repository-local Challenger remains the independent no-credit path.
- 2026-08-26 — recorded Godot 4.7 DrawableTexture2D as the preferred first-party fallback for any future dense spatial residue-mask experiment; retained PR #166's repository-native deterministic grid for the current scope.
- 2026-08-26 — recorded upstream Windows touchscreen drag regression #122791 as a touch-readiness gate for Godot 4.7.2; kept the production mouse toolchain on 4.7.2 pending confirmed upstream causality/fix.
- 2026-08-26 — upgraded the #122791 watch after independent upstream 60 Hz touchscreen reproduction and open fix PR #122825; retained the 4.7.2 PC-mouse production toolchain and made stable-fix plus real-touch validation the mitigation gate.
- 2026-08-26 — observed that both #122791 and #122825 are assigned to Godot 4.8; removed any implicit expectation of a 4.7.x fix and made 4.8 stable (or an explicit 4.7 backport) the earliest evidenced upstream mitigation line before real-touch validation.
- 2026-08-27 — recorded that the original #122791 reporter tested PR #122825 and reported the freeze/lag resolved; upgraded confidence in the candidate while retaining the stable-release plus real-touch mitigation gate.
- 2026-08-27 — recorded Godot 4.8 dev4's merged first-party Compatibility-renderer decal support as a future residue/crumb rendering experiment candidate; retained Godot 4.7.2 and the repository-native deterministic cleanup field for current production.
- 2026-08-27 — recorded upstream PR #115653 as the first-party convergence path for DrawableTexture-driven dynamic DecalAtlas updates, while explicitly gating any Compatibility use on resolution of the fresh GLES3 mipmap concern plus stable release and isolated runtime/capture verification.
