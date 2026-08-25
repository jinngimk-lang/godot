# Peel Calm — Persistent Project North Star

This file is the repository-owned whole-project memory for long-running agent work. It exists so the project does not drift when chat context becomes large, compacted, summarized, handed to another agent, or partially forgotten.

## Mandatory reread rule

Read this file:

- at the beginning of every new agent/session working on Peel Calm;
- after context compaction/summarization or any handoff;
- whenever the agent is unsure which visual/product direction is current;
- before a large architecture or presentation pivot;
- before declaring the project complete;
- before continuing from an old branch or historical PR.

Then inspect current `main`, current production code/tests, the active handoff/checkpoints, exact CI/runtime evidence, and the current ecosystem watch ledger. Conversation memory never overrides current repository evidence.

If a verified owner-level direction, major architecture decision, acceptance rule, merged milestone, engine baseline, external-integration decision, or next-work priority changes, update this file in the same workstream so the next agent can recover without the chat transcript.

## Autonomous project stewardship

The owner has delegated normal reversible project decisions to the acting agent. Do not repeatedly ask the owner to choose between ordinary implementation options, minor visual directions, refactors, tests, compatible tools, or repository organization when evidence can decide them.

The agent should autonomously:

- choose the highest-value next defect from runtime evidence;
- create branches/PRs/issues/checkpoints and update repository memory;
- add or use appropriate skills/MCP/connectors when they materially improve execution;
- research current Godot releases, relevant GitHub projects, techniques, assets, and project-adjacent developments;
- reject weak or risky ideas without requiring owner review;
- integrate compatible improvements only after evidence, license/provenance, dependency, and runtime checks;
- keep iterating after technical green when visible/interaction quality is still below the project target.

Separate authorization is still required for destructive/irreversible operations, secrets/credentials, paid services, legal commitments, sensitive disclosures, or external publishing outside the repository.

## Continuous ecosystem intelligence rule

Project completeness includes staying aware of useful external developments. At meaningful work checkpoints, and through scheduled monitoring when available, scan for:

- stable Godot maintenance releases and relevant renderer/input/material fixes;
- mature Godot implementations related to runtime surface masks/painting, paper/cloth-like deformation, mesh/material realism, input feel, Foley, post-processing, or test/capture tooling;
- permissively licensed models/textures/audio only when they strengthen the current object-first tactile fantasy;
- relevant UX/game-feel research and production techniques.

Use this gate before any external source enters production:

`discover -> relevance -> explicit license/provenance -> dependency/architecture fit -> isolated experiment -> exact Godot verification -> runtime visual/feel evidence -> integrate or reject -> update project memory`

Hard rules:

- Unknown or absent license means **no source or asset copying**. It may be studied only as a high-level idea, followed by an original implementation.
- Prefer repository-native code over mandatory third-party plugins when the same user-visible result can be achieved without dependency risk.
- Do not import a library/addon merely because it is impressive; it must solve a current measurable Peel Calm defect.
- Preserve attribution/license/provenance beside any external asset/code that is actually integrated.
- Record candidates and decisions in `docs/research/ECOSYSTEM_WATCH.md` so future agents do not repeatedly rediscover or accidentally reintroduce rejected sources.

## Engine maintenance policy

The verified baseline may advance within a compatible stable Godot maintenance line when official releases recommend adoption. A patch upgrade is not accepted from release notes alone: update CI, run the full configured default launch/tests/smokes/runtime capture suite, inspect visible output, then update this North Star and handoff only after exact-head and merged-main evidence are green.

As of 2026-08-25, Godot 4.7.2 stable is the active maintenance-upgrade candidate from the current 4.7.1 baseline. Do not describe 4.7.2 as the verified project baseline until the full project workflow passes on it.

## Owner-locked completion stack

Do not lose or reorder these five product priorities without new owner feedback or strong runtime evidence:

1. **Optimize scenes** — five showcase selections must become genuinely different, polished places with coherent composition, lighting, depth and foreground surfaces.
2. **Optimize models** — cup, glass jar/bottle, tin can and aluminum can must read as believable hero products rather than primitive geometry.
3. **Optimize label material** — paper front/back/edge, fibers, adhesive boundary, residue and local bending must read as paper rather than tape.
4. **Optimize post-peel label handling** — after 100% release the label must enter an intentional completion lifecycle; it must not remain indefinitely floating over the product as if still being peeled.
5. **Build a logical complete interaction flow** — discover edge, load/grab, peel, inspect, fully release, resolve/dispose/collect the removed label, receive calm completion feedback, clean remaining residue, and continue to the next product/scene without dead ends.

The 2026-08-20 reference-fidelity integration established a machine-verified baseline for all five items. Treat them as permanent regression contracts, not finished areas that may be removed or simplified.

## Current delivered baseline — 2026-08-20

- Five directly selectable, materially distinct scene/product bundles: Coffee Shop, Jar, Tin Can, Supermarket, and Can.
- Approved object-only 1280×720 composition: large centered hero, compact left progress/controls, four-step right tutorial, and persistent five-scene bottom rail.
- Continuous localized corner-peel paper mesh with readable attached copy, bounded cell stretch, fibrous front/back/edge response, adhesive trace, full-sheet release curl, and authored hold/settle/clear lifecycle.
- Persistent vessel-bound glue/fiber residue after paper release.
- Required second interaction pass: once the paper settles, the small hand cursor displays `RUB ↔`; held LMB back-and-forth movement inside the old label footprint fades residue; Continue stays gated until 100% clean.
- Deterministic full-flow verification covers grab → load → peel → detach → settle → rub → clean → next scene, plus pause/reset quarantine and all five scene bundles.
- Canonical visual evidence contains seven states per scene: attached, representative peel, release hold, settling, dirty residue, partial scrub, and clean (35 frames total).

## Product identity

Peel Calm is a relaxing tactile/ASMR desktop game about peeling real-time labels from everyday containers. The pleasure comes from catching an edge, loading the paper and adhesive, overcoming breakaway resistance, hearing/seeing local release, and finishing with a completely detached label and a clean exposed vessel.

It is **object-first**, not character-first.

Current approved hero object family:

1. Coffee Shop — takeaway paper cup / order label.
2. Jar — glass food jar / rustic paper label.
3. Tin Can — metal food can / grocery paper wrap.
4. Supermarket — clear citrus/Yuzu bottle / coated commercial label.
5. Can — aluminum beverage can / thinner, more compliant wrap.

Additional cups, bottles, tins, cans, jars, cartons, tubs, or similar label-bearing objects may be added if they strengthen the same tactile fantasy.

## Presentation direction that must not regress

- No visible human hand/arm model is required or desired for the approved direction.
- Use a small hand-shaped mouse cursor for direct manipulation.
- Do not use a full-screen still image or video playback layer as fake gameplay.
- Real-time Godot object, label, residue, lighting and interaction must remain visible and authoritative.
- The hero object should dominate the center composition; UI is secondary.
- Backgrounds/environments may use photographic or authored assets, but they are environment plates, not replacements for real-time interaction.

## Core controls

The intended interaction language is direct and simple:

- LMB: grab/peel label; after paper release, rub residue clean.
- RMB drag: rotate/inspect product.
- Wheel: zoom.
- R: reset.
- number keys: switch showcase scenes/products.
- Esc: pause/menu.

Input must remain deterministic across pause/reset/scene changes. A held input from before a boundary must not silently continue gameplay afterward.

## Peel mechanics north star

The label must feel like **paper bonded by adhesive**, not loose tape, cloth, rubber, slime, or a freely hanging sheet.

Required causal path:

`new outward pointer work -> stored bond load -> initial breakaway -> local peel-front release -> load relax -> next increment`

Hard rules:

- holding the cursor stationary under tension does not keep advancing progress;
- the first movement builds visible/audible load before meaningful release;
- initial breakaway is stronger than steady peel;
- sideways/inward movement does not grant free progress;
- peel can include restrained deterministic stick-slip variation;
- most bending happens in a narrow band at the peel front;
- detached paper behaves mostly like a stiff sheet;
- the paper has printed front, opaque fibrous backing, visible edge/thickness, and separate adhesive/residue behavior;
- `100%` means the full printed label is visually detached from the container;
- residue can remain on the vessel after paper release.

Current substrate feel ordering, from most resistant/stiff to most compliant, is approximately:

`Jar > Tin / Coffee > Yuzu > Soda Can`

Do not collapse all products to one generic feel profile without new evidence.

## Post-peel lifecycle north star

A fully removed label must not remain forever as an unexplained floating object. Completion has an authored calm resolution:

`ATTACHED -> EDGE_LIFT -> PINCHED -> PEELING -> FULLY_RELEASED -> SHORT_HOLD/SETTLE -> RESIDUE_RUB -> CLEAN -> NEXT_READY`

The exact presentation may differ by product, but it must be logically understandable and reversible/resettable. The released label briefly holds and settles clear of the hero. The user then performs a fresh LMB rub gesture over the remaining adhesive footprint. Hover, stationary hold, and movement outside the footprint do not clean. The next action appears only when cleaning reaches 100%.

Optional post-clean object play such as subtle squeeze, wobble, shake, liquid inertia, or inspection may be added when it strengthens a specific vessel's material identity, but it must remain secondary to the peel/clean fantasy, must be real-time, and must not resurrect obsolete hand-model or fake-video paths.

## Five-scene identity rule

The five showcase scenes must look like five different places even when HUD labels are hidden.

Changing only the product model, label copy or global tint is not enough. Scene identity should come from a combination of:

- environment/source plate or authored geometry;
- crop and camera composition;
- foreground/contact surface;
- lighting direction and color temperature;
- depth/blur structure;
- practical light placement;
- reflections and material response;
- scene-specific props/silhouette when useful.

Target moods:

- Coffee Shop: warm window café, kraft/pulp cup, soft warm contact surface.
- Jar: pantry/kitchen/food-prep environment, glass + sauce, warm natural food cues.
- Tin Can: grocery/cold-case/pantry merchandising, industrial metal emphasis.
- Supermarket: bright refrigerated commercial environment, cool clean lighting.
- Can: beverage/convenience counter or drink-display environment, distinct from Supermarket.

## Image-first visual convergence rule

When the agent has a concrete visual solution, **do not jump directly from idea to Godot and improvise until it looks acceptable**.

Use this loop:

1. Produce a practical visual target first — a mockup, generated reference, compositing template, paintover, layout board, or other concrete image artifact showing the intended final frame. It should represent the actual planned object scale, UI placement, environment, lighting/material mood and peel state.
2. Record the important measurable/observable constraints from that image: object framing, silhouette, label size, peel corner/angle, UI bounds, major light direction, background identity, material cues.
3. Implement the same target in real-time Godot without substituting a full-screen gameplay still/video.
4. Capture the Godot runtime at a directly comparable state and resolution.
5. Compare target vs runtime explicitly. Prefer side-by-side/contact sheet and, when useful, quantitative image differences for alignment/composition/color; do not let a metric override visible structural defects.
6. Identify the largest mismatch, change only the relevant layer where practical, re-run and re-capture.
7. Repeat until the controllable Godot output matches the approved target to the owner’s requested bar.

The owner’s stated completion standard is **100% precise target fidelity**, not “looks pretty”, “close enough”, “CI green”, “85–90% similar”, or an arbitrary number of iterations. In practice, some differences may be inherently non-identical because Godot is real-time and the target may be a generated/static reference; those differences must be called out explicitly rather than silently accepted. Within controllable composition, object geometry, UI, lighting, material behavior, peel state and interaction, keep iterating instead of declaring early completion.

## Verification loop

For meaningful gameplay/visual work:

1. State the user-visible defect.
2. Add a falsifiable behavioral/visual acceptance check; use RED-GREEN when practical.
3. Implement the smallest coherent change.
4. Run the current verified stable Godot patch import/parser guard and configured default launch.
5. Run deterministic unit/input/scene smokes.
6. Capture every affected product at attached, representative mid-peel, fully released, dirty-residue, partial-scrub, and clean states.
7. Inspect captures manually against the target/template image.
8. If the image is worse or still visibly off, reject the direction and continue.
9. Merge only exact-head verified work.
10. Do not claim merged-main verification unless merged `main` itself was separately checked.

Functional green is necessary but never sufficient for visual completion.

## Persistent-memory maintenance

This file should remain compact enough to reread quickly but complete enough to restore project direction. Do not turn it into a chronological diary.

Put detailed implementation history and exact parameters in checkpoints/handoffs. Keep here only:

- current product thesis;
- current non-negotiable UX/presentation rules;
- architecture/interaction invariants;
- acceptance definition;
- current scene family;
- current major priorities;
- current autonomy/external-adoption rules;
- current verified engine family and upgrade policy.

When something here becomes obsolete, replace it rather than appending contradictory guidance.

## Current recovery path

After this file, read:

1. `.agents/PROJECT_KNOWLEDGE.md`
2. `.agents/skills/peel-calm-reference-realism/SKILL.md`
3. `.agents/skills/peel-calm-reference-realism/CURRENT_HANDOFF.md`
4. `docs/research/ECOSYSTEM_WATCH.md` when present
5. `docs/superpowers/checkpoints/2026-08-20-reference-fidelity-final.md`
6. `docs/superpowers/plans/2026-08-20-reference-fidelity-completion.md`
7. current `main` production code/tests/workflows and newest runtime captures.

Highest-value future work, in order:

1. Spatial/local residue cleaning so the exact rubbed region clears first, with restrained glue-roll/paper-crumb visuals and corresponding sound.
2. Owner feel tuning for breakaway force, per-substrate pointer travel, scrub duration, cursor feedback, and Foley balance.
3. Further realtime product/environment realism: stronger silhouettes, glass and metal edge response, contact shadows, paper microdetail, and backdrop/live-surface integration.
4. More irregular tear/release silhouettes without reintroducing print distortion, elastic stretch, or full-height ribbon behavior.
5. Optional vessel-specific post-clean object play where it reinforces material identity.
6. Settings/accessibility, touch-device validation, and performance profiling after the PC mouse loop is stable.
