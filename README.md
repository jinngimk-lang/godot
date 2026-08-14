# Peel Calm

Peel Calm is a PC-first, touch-ready Godot relaxation game built around a repeatable café tactile ritual: peel a production label, linger after the release, optionally squeeze/crumple the cup, then move to the next tactile object when you feel ready.

The current V5 candidate deliberately avoids timers, failure pressure and score-chasing. The goal is a comfortable loop that can be repeated for many minutes while cup, label and adhesive feel gradually vary.

## Engine

- Godot **4.7.1 stable**
- GDScript
- No required third-party Godot plugins
- No runtime AI service, private secret, Blender install, or external asset download required

## Run locally

1. Clone this repository or use **Download ZIP** on GitHub.
2. Open Godot 4.7.1 Project Manager.
3. Import/select the repository's `project.godot`.
4. Press **F5** (or the Run Project button).

The repository is the complete runnable project. A fresh clone/ZIP is intended to run without manual path repair.

## The V5 relaxation ritual

1. Move the pointer to the small warm/gold peel-edge dot.
2. Hold the **left mouse button** and pull gently away from the cup.
3. Pull tension must overcome the current label's adhesive resistance before the peel advances. Releasing early preserves peel progress; re-grab the current gold edge to continue.
4. At 100%, the final adhesive bond releases through the existing short `DETACHING -> HELD` transition. The printed order remains on the free label in the right hand.
5. The game does **not** automatically replace the cup. After a short calm settle, the cup becomes squeeze-ready and can remain there indefinitely.
6. To crumple it, make a fresh press and drag inward toward the cup center. Several deliberate squeezes accumulate bounded deformation and paper-crumple Foley. You may linger, squeeze again, or skip the crumple entirely.
7. Press **R** whenever you want the next cup. A new item never arrives because a countdown expired.

The crumple phase is optional sensory play, not a pass/fail requirement. Completing the label release earns the ritual progression; extra cup squeezing provides descriptive/visual/audio feedback without becoming a second score-farming event.

## Controls

- **Esc** — pause / resume. Pause freezes the current ritual phase.
- **R while peeling** — reset only the current label; run progression is preserved.
- **R after a clean release** — move deliberately to the next unlocked tactile cup. This also works during the short settle, so the calm beat is never a forced lockout.
- **Shift+R** — restart the whole run, including Ritual count, unlocks and any pending cup deformation.
- Close the game window normally when finished.

Mouse is the current primary control. The input boundary also accepts touch event shapes. Mobile export and phone haptics remain deferred until the PC tactile experience is validated.

## Soft tactile progression

The primary HUD now emphasizes **Rituals** and **Tactile set** rather than public Score/Feels counters. There is no timer bonus, combo break, failed peel rank or punishment for slow re-grabs.

The run begins with one profile and unlocks two more through completed label-release rituals:

- **Warm Paper** — balanced adhesive, medium label and a softer paper-cup squeeze; available immediately.
- **Silky Long** — longer label, lighter adhesive and a more yielding cup; unlocks after **2 Rituals**.
- **Crisp Seal** — shorter label, firmer adhesive catch and a stiffer/crisper cup; unlocks after **5 Rituals**.

These are not text-only variants. The profiles carry different peel resistance/release response, label size, cup dimensions, cup color and crumple rigidity/compression behavior.

Every profile also has an explicit `contents_profile`. The current V5 runtime uses `type = "none"`; this is an architectural extension point for later cold/clear cups with ice, clink/rattle Foley and content motion. Visible ice simulation is **not** part of the current build yet.

## V5 tactile presentation baseline

- **True detach:** the label fully leaves the cup instead of stretching into an infinite ribbon.
- **Tapered cup contact:** attached label positions and surface normals follow the real tapered paper cup; detached/free portions no longer depend on the cup surface.
- **Print stays on the paper:** order/drink graphics leave the cup with the label.
- **Safer authored hands:** normal runtime uses repository-local rigged CC0 hand GLBs. The dynamic hand now stays inside verified pinch-pose families (`Pinch Up` -> `Pinch Tight`) instead of switching from a fully open pose; the support hand uses a neutral authored pose instead of the earlier over-curled cup pose. Procedural five-finger geometry remains fallback-only.
- **Support-hand crumple staging:** cup deformation moves the existing support-hand root a small bounded amount toward the cup center while leaving its authored skeleton/pose untouched; next cup/reset returns the exact baseline position.
- **Bounded cup crumple:** a deterministic paper-cup model requires several intentional inward squeezes, accumulates deformation without springing fully back, keeps dimensions finite and follows cup shortening with the lid.
- **Visible generated shell:** crumple rendering uses a continuous repository-local `ArrayMesh`; front-face winding, deformation bounds and reset behavior are permanent CI contracts.
- **Real Foley direction preserved:** repository-local CC0-derived adhesive/paper WAVs still drive peeling. Real inward cup deformation reuses the audited paper-flex Foley at a lower/softer character; stationary holds do not retrigger it.
- **Café presentation:** warm background/light, paper-cup seam/base/lip details and compact continuous forearms remain presentation-only layers.

Hand-model provenance and license material are stored under `assets/models/hands/`. Audio source/license provenance is recorded in `assets/audio/ATTRIBUTION.md`.

## Verification

GitHub Actions uses the official Godot 4.7.1 Linux x86_64 release and verifies its checksum. The canonical gate covers:

- fresh headless import plus parser/load guard;
- the configured **default F5/project entrypoint**, not only test-script scene overrides;
- deterministic peel/input/score-compatibility/lifecycle/geometry/hand/Foley tests;
- deterministic `RitualFlow` state transitions, including no timer-driven next item and stale skip-vs-crumple reward rejection;
- deterministic `CupCrumpleModel` ownership, inward-direction, bounded progress/compression and exact-once crumple event tests;
- real tapered-label position + normal smoke;
- café / paper-cup structural presentation smoke;
- generated cup-crumple shell visibility, clockwise front faces, bounded waist deformation, lid-follow and reset smoke;
- compact forearm presentation smoke;
- real ritual-loop smoke covering peel completion -> pointer quarantine -> optional crumple -> crumple Foley -> calm HUD -> deliberate R next;
- repeated five-Ritual unlock progression with no automatic elapsed-time transition;
- pause isolation and reset/restart input quarantine.

Visible V5 changes were additionally exercised through real 1280x720 X11/OpenGL capture branches. The first crumple render was rejected because triangle winding hid the front of the cup; that defect became a permanent regression test before the candidate continued. The combined candidate was also visually checked with the independently reviewed safer hand poses and support-hand staging.

A green CI run proves project/script/resource contracts and machine-observable behavior. It does **not** prove that the squeeze resistance feels ideal, that the hand anatomy is natural enough on your display, that the paper deformation is visually perfect, that Foley balance is relaxing on your headphones, or that the loop stays comfortable over a long session. Those remain owner playtest gates.

## Current boundary and next sensory extensions

The current playable loop is **peel -> linger -> optional cup crumple -> deliberate next cup**.

Prepared but intentionally not claimed as implemented yet:

- clear/cold plastic cup shells;
- visible ice pieces and clink/rattle response;
- cup contents motion;
- lid removal/drinking;
- full soft-body destruction;
- shop/currency/meta-pressure systems.

Future content should add new sensory experiences without turning Peel Calm into a failure-driven or score-grinding game.
