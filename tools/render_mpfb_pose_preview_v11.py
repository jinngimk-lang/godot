"""Run the v10 coupled pinch solver with anatomical v11 constraints.

v10 proved that raw fingertip distance is an unsafe objective: it reached a ~4 mm
thumb/index gap by moving the contact midpoint ~75 mm away and accumulating enough
flexion to form looped fingers. v11 keeps the useful coupled solve but constrains
finger flexion and makes contact-location preservation a first-class objective.
"""
from __future__ import annotations
import importlib.util
from pathlib import Path

BASE = Path(__file__).with_name('render_mpfb_pose_preview_v10.py')
spec = importlib.util.spec_from_file_location('mpfb_pose_v10', BASE)
if spec is None or spec.loader is None:
    raise RuntimeError('could not load v10 pose solver')
v10 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v10)

# Keep cumulative index flexion inside a plausible pinch envelope instead of
# allowing the three joints to add up into a loop. Thumb opposition remains the
# primary degree of freedom for closing the final contact gap.
v10.PINCH_BOUNDS = [
    (8, 28), (18, 48), (8, 30),
    (-62, 62), (-56, 56), (-62, 62),
    (-18, 18), (-22, 22), (-44, 44),
    (-12, 12), (-12, 12), (-34, 34),
]

def _pinch_unused_fingers(arm):
    # Staggered relaxed curl. Keep every three-joint sum well below the v10
    # loop-forming envelopes while removing the straight/open neutral silhouette.
    v10._curl_chain(arm, 'middle', (22, 36, 22))
    v10._curl_chain(arm, 'ring', (27, 42, 26))
    v10._curl_chain(arm, 'pinky', (32, 48, 30))

v10._pinch_unused_fingers = _pinch_unused_fingers

# Preserve the intended flap region. A tiny fingertip gap is worthless if both
# digits travel several centimetres away from the reference contact point.
def _score_pinch(arm, p, contact_anchor):
    v10._apply_pinch(arm, p)
    index_tip, thumb_tip, mid, gap = v10._pinch_contact_state(arm)
    desired_gap = .004
    gap_error = abs(gap - desired_gap)
    anchor_error = (mid - contact_anchor).length
    score = gap_error + anchor_error * 2.25 + v10._regularization(p, v10.PINCH_BOUNDS, .0018)
    return score, gap_error, anchor_error, gap, index_tip.copy(), thumb_tip.copy(), mid.copy()

v10._score_pinch = _score_pinch

if __name__ == '__main__':
    v10._run()
