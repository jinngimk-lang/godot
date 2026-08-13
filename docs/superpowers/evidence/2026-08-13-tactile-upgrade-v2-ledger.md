# Tactile Upgrade V2 — Evidence Ledger

Date: 2026-08-13
Base: `main@b5f32cf722284458104c2688fa95fec9c4177231`

## Owner playtest failures addressed

- V1 reached `100% / COMPLETE` while the label still visibly remained connected to the cup as a stretched ribbon.
- V1 hand presentation read as abstract block/capsule proxies.
- V1 primary peel audio was synthetic oscillator/noise rather than believable paper/adhesive Foley.
- V1 order text was a world-space presentation element instead of belonging to the deforming label surface.

## RED evidence

| Contract | Exact RED SHA | GitHub Actions run | Intended failure |
| --- | --- | --- | --- |
| True detach lifecycle | `2dbd9717db53608ef874ed3e3e46963269f16108` | `31665825791` | `RED: missing label detach lifecycle contract` |
| Bounded/held label geometry | `d4e3c59b95f1894320676efce4c008755718a52c` | `31665944204` | `RED: missing bounded label geometry contract` |
| Print bound to label | `126f5dcda3e00fe23b9fed485d50edec40002541` | `31666074622` | `RED: missing deforming label print provider` |
| Five-finger pinch hand contract | `216ee06f0f20d1f1b3d80349a8215d8f355ac1b6` | `31666197720` | missing new semi-realistic hand methods/anchors |
| Physical Foley event router | `e92d5e0ec2ebc7e42e7b96e77985f5a38cfec48d` | `31666423488` | `RED: missing physical peel foley router` |
| Progressive final detach blend | `9bbf581c7f44213ab53f4035f4e5da1fa9ad264c` | `31666873479` | lifecycle missing `get_detach_alpha()` |
| Authored CC0 hand runtime path | `be1741ea66dd430f58d30dfdd1dcbe055874a28c` | `31667238430` | `RED: HandVisual does not expose authored-hand runtime contract` |

## GREEN checkpoints

| Scope | Exact SHA | GitHub Actions run | Result |
| --- | --- | --- | --- |
| Detach lifecycle | `7e335ba04a6fd90d338d401e1941f995f7c486ed` | `31665854994` | import/unit/smoke success |
| Bounded + detachable label visual | `51799d9e0b5d8354b85b91b1eddd3305e60a40db` | `31666032521` | import/unit/smoke success |
| Label print texture | `c9015b8b28993c612e00206e7a4d708a4b51603b` | `31666146463` | import/unit/smoke success |
| Five-finger procedural fallback | `e5be7d6f664bb3688907d6cc0b0a9359321252f7` | `31666381665` | import/unit/smoke success |
| Foley router | `7e7cea7417c2ce36c7ab9ff9e83efad7caf14a8f` | `31666455285` | import/unit/smoke success |
| Integrated true-detach scene + local Foley | `8925c20727857148a39298d2771495b54c9806f9` | `31667022687` | import/unit/smoke success |
| Clean V2 before authored-hand wrapper | `2cd04e495dfc3169eff7c2e5f6a3e4ec244fa908` | `31667102962` | import/unit/strengthened smoke success |
| Authored rigged GLB wrapper | `3f0acedff343169b7fcdff41c34cc199b70bac25` | `31667437384` | import/unit/scene smoke success |
| Final pre-PR candidate | `5de812837d5526d333ce760d373159b4ec55d59e` | `31667498197` | official Godot 4.7.1 checksum/install, import+parse guard, all deterministic tests and authored-hand/Foley scene smoke success |

## Asset provenance

- Peel Foley is repository-local PCM WAV derived from independently verified CC0 source pages; `assets/audio/ATTRIBUTION.md` records source pages, fetched-source SHA256 values and transformations.
- Normal hand presentation uses repository-local rigged GLBs derived from Godot XR Tools hand models pinned to upstream commit `2d8db860d1adbee97c0968c4b07afe9348263926`.
- Upstream hand model author/CC0 license is preserved under `assets/models/hands/` together with Peel Calm's provenance notes.
- No Godot XR Tools addon is vendored or required at runtime; only self-contained hand presentation assets are used behind Peel Calm's `HandVisual` contract.

## Known UNVERIFIED experiential items

Automation does not prove that the authored hand placement is visually natural on the owner's Windows/GPU setup, that the new Foley is relaxing at the owner's volume/headphones, or that resistance/detach timing feels ideal. Those remain next local-playtest evidence, not CI claims.
