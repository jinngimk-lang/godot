# Peel Calm Visual Acceptance References — v1

Status: **LOCKED ACCEPTANCE SET**
Date pinned: 2026-08-14

These are the three user-approved reference images that define the visual north star for the current product direction. Runtime screenshots, generated step diagrams, explanatory markups, and later experiments must not silently replace this set.

The original PNG files are persisted in the user project library under:

- `/Peel Calm/Acceptance References/v1/cafe_reference.png`
- `/Peel Calm/Acceptance References/v1/bar_reference.png`
- `/Peel Calm/Acceptance References/v1/market_reference.png`

## Exact source hashes

| id | role | SHA-256 | source bytes |
|---|---|---|---:|
| `cafe_v1` | Window café / paper cup peel | `1bcb6f75c84319ef1d74da0b372b59519c375c7e94e27c29aeac649c719a257f` | 2,082,113 |
| `bar_v1` | Warm dark bar / amber bottle peel | `3624706d7925a1bf3b51346439b8927605f9c3a0536216e1767484d0074eae73` | 1,916,583 |
| `market_v1` | Convenience cooler / clear yuzu bottle peel | `bb5c269a80d92f26666860bc3dcca28722d2ea856b0604941b77f32e6261be35` | 1,813,736 |

## Derived 1280×720 comparison copies

For automated comparison tooling, a JPEG Q90 derivative may be created without redefining the target. The currently produced derivatives have these hashes:

| id | SHA-256 | bytes |
|---|---|---:|
| `cafe_v1_1280x720_q90` | `82accd0053ffb98ab522324d5ec8d98e0920c9c3c9d724cea9cbee9b908b346b` | 222,980 |
| `bar_v1_1280x720_q90` | `204e2bfc25d1a185720d7e13bf06d6edc39be1962b45d99a21f1e6d2d1a09d2b` | 243,340 |
| `market_v1_1280x720_q90` | `86407e3f79744f0f857177a6fe37494c3c60ce61fd7e316d5e617d7081589bf1` | 186,836 |

## Reference intent

### `cafe_v1`

- large warm café window/daylight environment;
- realistic wood table;
- hero paper cup centered but not oversized;
- realistic human hands with substantial palm volume;
- peel hand pinches the actual lifted paper flap;
- support hand wraps the cup naturally;
- matte paper, lid molding detail, visible fibers/residue;
- quiet top-left interaction UI.

### `bar_v1`

- independent dark/warm bar with practical-light bokeh;
- slender amber glass bottle with strong optical highlights;
- realistic bare forearms/hands;
- support hand firmly grips the bottle;
- peel hand pulls a visibly torn/fibrous label flap;
- wet/dark counter response and rich glass depth;
- compact quiet interaction UI.

### `market_v1`

- bright convenience/supermarket cold-case environment;
- slender clear bottle with pale citrus liquid;
- readable glass/liquid/condensation cues;
- realistic large hands entering naturally from frame edges;
- support hand steadies the bottle;
- peel hand holds a lifted paper/plastic label flap;
- cool neutral commercial light;
- quiet top-left progress/control UI.

## Anti-drift rules

1. Every visual checkpoint must name the acceptance reference id(s) used.
2. A new generated image may be tagged `DERIVED_STEP_REFERENCE` or `EXPLANATORY_REFERENCE`, but it is not an acceptance replacement.
3. Changing this locked set is a product-direction change, not routine iteration.
4. Game runtime captures are evidence and must never be promoted into the acceptance set simply because they are easier to match.
5. If the original PNG bytes are unavailable in a future execution environment, verify the persisted library copy against the hashes above before using it.
