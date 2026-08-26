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

Finding: the reporter reproduces severe freezing while dragging on an actual Windows touchscreen in Godot 4.7.2 stable and 4.8 dev, while 4.7.1 does not reproduce. The issue is now labeled `confirmed` in addition to `bug`, `regression`, `performance`, and `platform:windows`. On 2026-08-26 a Godot maintainer independently reproduced substantial lag after roughly 35–40 seconds of dragging on a 60 Hz Windows touchscreen, did not reproduce it with multiple pen tablets, and did not reproduce it when the same touch digitizer was mapped to a 120 Hz display. Upstream opened PR #122825, `[Windows] Process all WM_(NC)MOUSEMOVE messages when touch screen/pen input is detected`, explicitly to close #122791. The PR remains open against `master`. Both the issue and the fix PR are currently assigned to the **4.8 milestone**, so there is no present evidence that a 4.7.x maintenance release will contain the fix.

Relevance to Peel Calm: the production interaction target is PC mouse first, so this is still not evidence to roll back the 4.7.2 mouse fix. It materially strengthens the touch-readiness gate, because the regression is no longer only reporter-local or awaiting real-touch reproduction. The refresh-rate-sensitive reproduction also means semantic mouse/touch ownership tests cannot stand in for actual Windows device/performance validation. The 4.8 milestone means the project should not plan touch-readiness work around an assumed near-term 4.7.x patch.

Decision: keep Godot 4.7.2 as production. Do not broaden touch support or claim Windows touchscreen readiness on 4.7.2. Track upstream PR #122825 through merge and release, plus any explicit 4.7 backport if one appears; absent such a backport, treat Godot 4.8 stable as the earliest evidenced upstream release line likely to carry the fix. Only treat the risk as mitigated after a stable build containing the fix is available and Peel Calm either passes isolated real-touch validation or has equivalent device evidence. Do not cherry-pick or vendor the engine patch into this repository.

Status: WATCH — confirmed upstream regression with an open 4.8-milestoned fix candidate; touch validation remains gated, no production rollback.

## Integration log

- 2026-08-25 — owner delegated routine reversible product/engineering decisions and requested continuous related GitHub/public-information scanning plus automatic integration of worthwhile improvements. Governance design and this ledger created on `chore/autonomous-intelligence-loop-v1`.
- 2026-08-25 — Godot 4.7.2 selected as the first evidence-backed maintenance integration, passed exact-head and merged-main canonical verification, and became the production engine patch via PR #164.
- 2026-08-25 — post-merge audit found persistent autonomous Builder/Challenger workflows still pinned to 4.7.1; version-alignment repair started on `fix/agent-toolchain-4.7.2-v1`. Paid Codex Challenger is temporarily unavailable because the API account reported no credits; repository-local Challenger remains the independent no-credit path.
- 2026-08-26 — recorded Godot 4.7 DrawableTexture2D as the preferred first-party fallback for any future dense spatial residue-mask experiment; retained PR #166's repository-native deterministic grid for the current scope.
- 2026-08-26 — recorded upstream Windows touchscreen drag regression #122791 as a touch-readiness gate for Godot 4.7.2; kept the production mouse toolchain on 4.7.2 pending confirmed upstream causality/fix.
- 2026-08-26 — upgraded the #122791 watch after independent upstream 60 Hz touchscreen reproduction and open fix PR #122825; retained the 4.7.2 PC-mouse production toolchain and made stable-fix plus real-touch validation the mitigation gate.
- 2026-08-26 — observed that both #122791 and #122825 are assigned to Godot 4.8; removed any implicit expectation of a 4.7.x fix and made 4.8 stable (or an explicit 4.7 backport) the earliest evidenced upstream mitigation line before real-touch validation.
