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

## Integration log

- 2026-08-25 — owner delegated routine reversible product/engineering decisions and requested continuous related GitHub/public-information scanning plus automatic integration of worthwhile improvements. Governance design and this ledger created on `chore/autonomous-intelligence-loop-v1`.
- 2026-08-25 — Godot 4.7.2 selected as the first evidence-backed maintenance integration, passed exact-head and merged-main canonical verification, and became the production engine patch via PR #164.
- 2026-08-25 — post-merge audit found persistent autonomous Builder/Challenger workflows still pinned to 4.7.1; version-alignment repair started on `fix/agent-toolchain-4.7.2-v1`. Paid Codex Challenger is temporarily unavailable because the API account reported no credits; repository-local Challenger remains the independent no-credit path.
