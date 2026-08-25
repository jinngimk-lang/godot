# Peel Calm Ecosystem Watch

Purpose: prevent repeated rediscovery, accidental license drift, unnecessary plugin adoption, and stale engine/tooling assumptions. This is a compact decision ledger, not a link dump.

## Adoption gate

Every external candidate must pass:

`discover -> relevance -> explicit license/provenance -> dependency/architecture fit -> isolated experiment -> exact Godot verification -> runtime visual/feel evidence -> integrate/reject -> update memory`

Allowed decisions:

- `INTEGRATE` — evidence-backed and approved for repository integration.
- `STUDY_PATTERN_ONLY` — useful architecture/technique; implement repository-native unless later evidence justifies dependency adoption.
- `WATCH` — potentially useful, not yet worth implementation.
- `REJECT` — conflicts with product/architecture/quality goals.
- `NO_COPY_LICENSE_UNCLEAR` — no code/assets copied; idea-level research only.

## Current candidates

| Date | Candidate | Relevance | License / provenance | Dependency fit | Decision | Evidence / next action |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-08-25 | Godot `4.7.2-stable` | Stability/usability maintenance release for current 4.7.x project | Official Godot release | Direct compatible engine patch; no runtime dependency | `INTEGRATE` after full green | Official release says maintenance releases are compatible and recommended; Linux x86_64 SHA-256 `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`. Update CI and require full import/default launch/tests/smokes/35-frame capture before baseline adoption. |
| 2026-08-25 | `maantho/gpu-texture-painter` | GPU runtime painting, brush masks, atlas-backed local surface modification; directly relevant to spatial residue clearing | MIT; public GitHub repository; Godot 4.4+ | Full addon would introduce a third-party plugin and compute/atlas complexity beyond current deterministic scrub needs | `STUDY_PATTERN_ONLY` | Study camera/brush-to-overlay-mask architecture. Prefer a smaller Peel Calm-specific local residue mask first. Do not vendor addon unless native implementation is proven insufficient. |
| 2026-08-25 | `alfredbaudisch/GodotRuntimeTextureSplatMapPainting` | Runtime splat-map painting and world-to-UV concepts relevant to cleaning masks | Inspected repository has no explicit license metadata/file | Older/demo architecture; not needed as dependency | `NO_COPY_LICENSE_UNCLEAR` | May inform high-level research only. Do not copy source, shaders, or assets without explicit licensing. |

## Search priorities

Prefer current information that can materially improve one of these active gaps:

1. spatial/local residue removal and brush/mask rendering;
2. convincing paper/adhesive material and release edge behavior;
3. glass/metal hero-object realism in Godot Forward+/GL compatibility;
4. tactile mouse game-feel and responsive low-key Foley;
5. runtime capture/image comparison and regression tooling;
6. stable Godot maintenance releases relevant to rendering/input/material behavior.

## Rejection heuristics

Reject or defer candidates that:

- require online AI/runtime services;
- require hidden external downloads for a fresh clone;
- add a large plugin for a small effect that can be implemented natively;
- conflict with object-only realtime interaction;
- encourage fake full-screen video/still gameplay;
- introduce visible hands/arms as a dependency;
- have unknown/unclear licensing for material we would need to copy;
- solve a speculative future feature while current peel/clean/visual defects remain larger.
