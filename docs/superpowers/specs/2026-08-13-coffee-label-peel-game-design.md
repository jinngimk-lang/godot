# Coffee Label Peel ASMR — Vertical Slice Design

Date: 2026-08-13
Status: Approved direction; written spec pending owner review
Repository: `jinngimk-lang/godot`
Target engine: Godot 4.7.1 stable
Primary language: GDScript
Initial platform: PC mouse prototype
Portable input target: touch/mobile without gameplay rewrite

## 1. Product Thesis

Build a low-pressure, sensory-focused relaxation game around one familiar micro-action: peeling a printed order/production label cleanly from a coffee cup or drink vessel.

The game should feel satisfying before it feels feature-rich. The first milestone is successful only if repeatedly peeling one label from one cup already feels pleasant.

The product is inspired by real café drink labels as a category, but v1 uses generic fictional branding, typography, order numbers, and cup styling. No Starbucks, Luckin, or other third-party logos/trade dress are required.

## 2. Core Player Fantasy

The player sees a close-up tabletop scene with:

- one drink cup;
- one attached label;
- a left hand stabilizing the cup;
- a right hand pinching and peeling the label;
- soft studio/café lighting;
- minimal UI.

The loop is:

```text
cup appears
→ inspect label edge
→ catch/raise an edge
→ pinch
→ pull against adhesive resistance
→ peel front advances
→ label flexes/curls
→ audio responds to speed/tension
→ label releases completely
→ score/reward moment
→ next cup
```

There is no timer pressure in the first vertical slice.

## 3. Experience Priorities

Priority order is strict:

1. Peel resistance and release cadence.
2. Audio response.
3. Hand/label motion readability.
4. Visual material quality.
5. Completion reward.
6. Content variety.
7. Meta progression.

A large content system must not be used to hide weak peel feel.

## 4. First Vertical Slice Scope

The first playable slice contains exactly one polished interaction scenario:

- one generic hot-paper coffee cup;
- one rectangular thermal-style paper label;
- one neutral table/background;
- one close-up camera;
- left stabilizing hand;
- right peel hand;
- mouse-driven peel interaction;
- responsive peel audio;
- label curl/bend behavior;
- completion score;
- automatic/resettable next-cup loop.

A minimal shell may contain a launch screen and restart/quit controls, but options, inventory, shop, save progression, and multiple cup types are not required to validate the interaction.

## 5. PC-First, Touch-Ready Input Contract

Gameplay code must consume a device-neutral pointer abstraction instead of reading mouse events directly throughout the peel system.

Canonical interaction state:

```text
pressed: bool
position: Vector2
relative: Vector2
velocity: Vector2
released_this_frame: bool
```

PC implementation maps mouse input to this contract.

Later mobile implementation maps touch/drag input to the same contract.

The peel solver, hand response, scoring, and audio logic must not know whether input came from mouse or touch.

## 6. Interaction State Machine

The peel interaction uses explicit states:

```text
IDLE
→ EDGE_HOVER
→ EDGE_LIFT
→ PINCHED
→ PEELING
→ RELEASED
→ COMPLETE
```

### IDLE

No valid peel edge is targeted.

### EDGE_HOVER

Pointer is close enough to a valid label edge/corner. The corner may visually lift by a tiny amount to communicate affordance.

### EDGE_LIFT

Player presses and moves enough to catch the edge. A short local section detaches from the cup.

### PINCHED

The right-hand fingertips visually close around the peel point. Input target is now filtered through the hand response model rather than driving the label directly.

### PEELING

Pointer displacement creates tension. Adhesion releases progressively only when the local release threshold is exceeded.

### RELEASED

Player lets go before full completion. The detached section relaxes toward a plausible resting shape while the still-adhered section remains attached.

### COMPLETE

The peel front reaches the end. Label is fully detached, reward is shown, completion sound plays, and the scene can reset/advance.

## 7. Peel Solver Architecture

V1 must not use a full general-purpose cloth/soft-body simulation.

The label is modeled as a lightweight strip/sheet with:

- an adhered region parameterized over label length;
- a moving peel front;
- a detached region represented by a small chain/grid of points;
- distance constraints between neighboring points;
- damping and limited bend behavior;
- a hand anchor applied to the current grip point;
- cup-surface attachment for the adhered region.

### 7.1 Peel Front

The key simulation variable is normalized peel progress:

```text
peel_progress ∈ [0.0, 1.0]
```

The peel front moves forward when effective pull tension exceeds adhesive resistance.

The release should occur in small increments rather than matching pointer distance 1:1.

This creates the desired rhythm:

```text
pull
→ resistance
→ local release
→ small relaxation
→ resistance builds again
```

### 7.2 Adhesive Model

V1 uses a tunable deterministic model, not a physically exhaustive adhesive simulation.

Parameters include:

- base adhesion strength;
- release hysteresis;
- speed response;
- peel-angle response;
- micro-variation/noise amount;
- damping;
- release increment size.

The model must be stable enough that the same input pattern gives broadly repeatable behavior.

### 7.3 Geometry

The label mesh must visually support:

- adhered portion following the cup surface;
- detached portion bending away from the cup;
- visible curl near the peel front;
- plausible movement without severe self-intersection in the normal play range.

Implementation may use procedural mesh generation or a lightweight strip mesh updated from solver points.

The runtime design must stay compatible with mobile-class hardware.

## 8. Hand Response Model

The right hand is not merely decoration. It communicates resistance.

The pointer controls a desired hand target. The visible hand follows through a damped response:

```text
pointer target
→ filtered hand target
→ grip anchor
→ label tension
```

This small lag is intentional and should increase perceived weight/adhesion.

The left hand primarily stabilizes the cup and may respond subtly to force through:

- small cup rotation/translation limits;
- fingertip compression pose changes;
- small counter-motion.

V1 does not require full-body inverse kinematics.

Hand assets may begin as stylized low-poly or simplified rigged hands, provided the pinch/readability is convincing enough to evaluate the interaction.

## 9. Audio Design

Audio is a first-class simulation output, not a single looping peel sample.

Minimum sound layers/states:

- fingertip/cup contact;
- edge catch;
- slow adhesive peel;
- fast adhesive peel;
- paper flex/crinkle;
- micro release ticks;
- final full release;
- completion reward.

Audio parameters should respond to simulation variables such as:

- peel speed;
- tension;
- release rate;
- remaining adhered area.

Pitch/volume/sample variation should prevent obvious repetition.

V1 audio assets must be original, generated, properly licensed, or temporary clearly marked development sounds. No unlicensed branded café audio is allowed.

## 10. Visual Direction

The visual target is calm, clean, tactile, and close-up.

Preferred qualities:

- warm neutral lighting;
- soft shadows;
- readable paper fibers/roughness at close range;
- clear contrast between cup and label edge;
- low UI density;
- no noisy score explosions that undermine relaxation.

The cup and label should look generic rather than copying a real chain’s protected branding.

## 11. Completion and Scoring

The game rewards quality without creating stressful failure states.

Candidate outcomes:

- `Clean Peel` — full label detached;
- `One Pull` — completed without releasing the grip;
- `Perfect Peel` — full label detached with minimal simulated residue/damage when that mechanic exists.

V1 score can be calculated from:

```text
base area reward
× completion factor
× continuity factor
```

Time is not a score multiplier in the first slice.

## 12. Progression Direction After the Slice

Only after the peel feel passes playtesting should progression expand.

Possible unlock axes:

### Cup types

- paper hot cup;
- transparent plastic iced cup;
- glass tumbler;
- frosted glass;
- metal travel cup;
- special curved vessels.

### Label types

- small order label;
- wide label;
- tall label;
- long wrap label;
- transparent film;
- large production/logistics label;
- alternate paper/adhesive strengths.

The progression fantasy is “unlock bigger and more satisfying things to peel,” not “make the player fail more often.”

## 13. Model Asset Pipeline Integration

The existing repository model asset contract remains valid.

Runtime 3D assets use `.glb` by default.

For important model work such as cups, hands, labels, props, or later environments:

```text
brief
→ generated/authored model
→ GLB candidate
→ preview render(s)
→ visual review
→ accepted asset
→ gameplay integration
```

Every accepted generated model should have a preview image so the owner can review appearance before it becomes canonical game art.

## 14. Repository Shape for the Slice

Expected high-level structure:

```text
/
├── project.godot
├── README.md
├── assets/
│   ├── models/
│   ├── textures/
│   └── audio/
├── scenes/
│   └── peel_lab/
│       ├── peel_lab.tscn
│       ├── cup/
│       ├── hands/
│       ├── label/
│       └── ui/
├── scripts/
│   ├── input/
│   ├── peel/
│   ├── hands/
│   ├── audio/
│   └── scoring/
├── tests/
│   ├── unit/
│   └── smoke/
├── tools/
│   └── modeling/
├── docs/
└── .github/workflows/
```

Exact filenames are defined in the implementation plan.

## 15. Cloud-Repository Delivery Contract

The GitHub repository is the canonical runnable project.

A fresh user must be able to:

```text
git clone https://github.com/jinngimk-lang/godot.git
→ open/import project.godot with Godot 4.7.1
→ run the configured main scene
```

or download the repository ZIP and perform the same import/run flow.

The first successful local run must not require:

- copying hidden local files;
- repairing hard-coded absolute paths;
- installing third-party Godot plugins;
- installing Blender;
- downloading missing runtime models manually;
- setting private environment variables;
- changing editor project settings by hand.

Any optional modeling tooling must be separated from runtime requirements.

## 16. Verification Strategy

The project follows evidence-first verification.

### 16.1 Automated source/engine checks

Every implementation PR should verify as applicable:

1. `project.godot` exists and targets the intended project.
2. Godot 4.7.1 headless import succeeds.
3. GDScript parsing/load succeeds.
4. The configured main scene loads without missing resources.
5. Unit tests for deterministic peel math pass.
6. A smoke scene can instantiate the cup/label/solver path.
7. Input abstraction can receive a simulated pointer sequence.
8. Peel progress remains within `[0, 1]`.
9. Release cannot regress progress into invalid state.
10. Full completion emits exactly one completion event.
11. Missing optional modeling tools do not prevent game startup.

### 16.2 Deterministic peel tests

The solver should expose enough pure/deterministic logic to test at least:

- below-threshold tension does not advance peel front;
- above-threshold tension advances peel front;
- progress clamps at 0 and 1;
- completion triggers at 1;
- pointer release does not detach the remaining adhered region;
- extreme input delta does not create NaN/INF state;
- zero/very small delta remains stable;
- configured parameter bounds reject impossible negative values where appropriate.

### 16.3 Scene smoke tests

Headless checks should load:

- project main scene;
- peel lab scene;
- cup scene;
- label/solver scene;
- hand scenes if runtime assets are present.

### 16.4 GitHub Actions

CI should run on pull requests and pushes to `main`.

At minimum it must:

```text
obtain Godot 4.7.1
→ import project headlessly
→ execute parser/unit/smoke checks
→ fail on script or resource load errors
```

Where practical, CI should preserve logs/artifacts useful for debugging.

### 16.5 Exact-head review

A review/merge decision is valid only for the exact tested PR head.

If the head changes after review, automated checks and review evidence must be refreshed.

The Fixer must not be the Merge Decider for substantive behavior changes.

### 16.6 Post-merge verification

A green PR is not completion.

After merge:

```text
fetch new main SHA
→ verify main CI
→ verify main scene/import contract again
```

### 16.7 What automation cannot prove

Headless CI cannot prove that:

- resistance feels pleasant;
- audio is genuinely relaxing;
- hand motion looks natural;
- camera framing feels premium;
- material rendering looks good on the owner’s GPU/display.

These are explicitly tracked as experiential verification, not silently inferred from green CI.

For major visual/model milestones, preview images should be produced for review.

For major hand-feel milestones, the owner’s local Godot run is a required acceptance signal.

## 17. Definition of Done for the First Playable Slice

The first slice is considered technically complete only when all are true:

1. Fresh clone/ZIP opens in Godot 4.7.1 without manual project repair.
2. Project launches into the peel lab.
3. Mouse can target and catch a label edge.
4. Player can peel the label progressively rather than instantly translating it.
5. Adhesion creates visible/temporal resistance before release.
6. Detached label geometry visibly bends/curls.
7. Right-hand visual follows the grip with intentional damping.
8. Full peel produces one completion event and score reward.
9. Player can reset/receive another cup without restarting the editor.
10. Audio responds materially to peel state/speed rather than playing one fixed identical sound only.
11. Core deterministic tests pass.
12. Godot 4.7.1 headless import/load smoke checks pass in GitHub Actions.
13. Exact merged `main` passes post-merge verification.
14. README contains direct local import/run instructions.
15. No runtime dependency on Blender, AI model services, or third-party Godot plugins.
16. Any claim about “satisfying feel” remains provisional until local experiential playtesting confirms it.

## 18. Explicit Non-Goals for the First Slice

Do not build yet:

- branded Starbucks/Luckin replicas;
- many cup variants;
- shop/inventory;
- currency economy beyond a minimal score proof;
- mobile build/export;
- phone haptics;
- cloud save;
- achievements;
- full menu/options suite;
- complex hand IK/full character body;
- multiplayer;
- ads/IAP;
- procedural level generation;
- full cloth simulation;
- required AI model-generation runtime.

## 19. Main Risks and Countermeasures

### Risk: peel looks like rubber or cloth

Countermeasure: tune bending separately from stretch and keep label mostly inextensible.

### Risk: peel simply follows cursor

Countermeasure: hand damping + tension threshold + incremental peel-front release.

### Risk: physical realism makes interaction frustrating

Countermeasure: optimize for perceived tactility, not laboratory adhesive physics; keep parameters forgiving.

### Risk: hand asset blocks interaction work

Countermeasure: use a simple readable temporary hand model first; solver quality remains independently testable.

### Risk: visual content work delays core feel

Countermeasure: only one cup/label in the slice until interaction passes.

### Risk: CI green creates false confidence

Countermeasure: separate technical verification from experiential verification and require local feel review before calling the slice satisfying.

## 20. Decision

**BUILD** a PC-first, touch-ready Godot 4.7.1 vertical slice centered on one excellent peel interaction.

**USE** a custom lightweight peel solver rather than a general cloth/soft-body dependency.

**KEEP** the cloud GitHub repository as the complete runnable project source.

**REQUIRE** layered automated verification plus post-merge verification.

**DEFER** content breadth, mobile haptics, economy, and large-scale modeling until the core peel experience is proven.
