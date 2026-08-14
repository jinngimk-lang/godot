# Physical Peel + Cup Inspection V1 Design

## Goal
Make peeling feel less like clicking a single hotspot and more like manipulating a real adhesive label: grab anywhere visible on the label, build force against damping, preserve label integrity by controlling speed/force, leave residue after rough pulls, and rotate the cup for inspection with the support hand.

## Interaction contract

### Grab anywhere
The gold peel marker becomes a visual hint only. A fresh left-mouse/touch press may begin a peel from any point inside the current projected label interaction region. Re-grabs after release follow the same rule.

### Adhesive damping
PeelModel tracks a bounded internal bond load. Tension builds bond load over time; below-threshold/relaxed input bleeds it down. Release begins only after load crosses an adhesion threshold with hysteresis. This creates resistance and prevents instant detach from a single threshold crossing.

### Integrity and residue
PeelModel also tracks:
- `integrity` in [0,1], starting at 1;
- `residue` in [0,1], starting at 0.

Moderate speed/tension preserves integrity. Excessive pull speed or force increases residue and reduces integrity while still allowing progress. Completion can therefore be physically complete while aesthetically imperfect. Existing completion remains exact-once.

### Visual residue
LabelVisual exposes residue amount. After completion/detach, a thin translucent paper/adhesive strip remains on the cup proportional to residue. This is presentation-only; it does not change progress authority.

### Cup inspection
Right-mouse drag controls a separate `CupInspectModel` yaw target with damping. It is ignored while left-button peel ownership is active. The cup/lid/label/edge marker are grouped under a presentation transform so inspection rotates the object consistently. The support hand yaws subtly with the cup so it reads as turning/holding the object.

## Architecture
Gameplay authority remains deterministic:

`PointerAdapter -> PeelController -> PeelModel`

New pure model:

`right mouse events -> CupInspectModel -> cup presentation transform`

PeelController receives a label interaction region from the scene and no longer requires edge proximity to start. Label geometry/presentation consumes residue/integrity but never decides progress.

## Acceptance
- Pressing inside the label region but far from the gold marker can enter peel interaction.
- Pressing outside the label region cannot begin peeling.
- A brief threshold spike does not instantly release material when bond load is not built.
- Equal moderate sustained pull advances peel with high integrity and low residue.
- Excessive speed/force produces measurably lower integrity and higher residue.
- Completion remains exact-once and reset restores progress/integrity/residue/bond load.
- Right drag changes cup inspection yaw; left peel input and pause/reset boundaries remain isolated.
- Existing deterministic input ownership tests remain green.
