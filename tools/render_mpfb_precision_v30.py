"""v30: tighten the direct surface-servo early-stop precision only.

v29 is the first near-pass with a gameplay-realistic 14.9 mm rigid hand-root shift:
- actual flap-face errors: ~3.35 / 3.21 mm;
- flap-center errors: ~5.28 / 4.94 mm;
- max extra finger-joint rotation: only ~10.1 deg of the 24 deg budget;
- visible fingertip gap: 10.156 mm, missing the <=10 mm gate by 0.156 mm.

The v26 servo intentionally stopped a digit once its surface error reached <=4 mm.
That coarse early stop is now larger than the remaining gate miss, while v29 retains
substantial anatomical rotation headroom. This experiment changes exactly one
solver parameter: early stop 4.0 mm -> 1.5 mm. It does NOT relax acceptance gates,
increase the 24-degree joint budget, change morphology, root-shift cap, seed pose,
or paper-face targets.

This is staging/falsification evidence, not production runtime IK.
"""
from __future__ import annotations

import importlib.util
import traceback
from pathlib import Path

BASE = Path(__file__).with_name("render_mpfb_root_align_v29.py")
spec = importlib.util.spec_from_file_location("mpfb_v29", BASE)
if spec is None or spec.loader is None:
    raise RuntimeError("could not load v29 root-align experiment")
v29 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v29)

# Single falsifiable change for v30.
v29.v26.SURFACE_EARLY_STOP = 0.0015

if __name__ == "__main__":
    try:
        v29._run()
        print("MPFB_PRECISION_V30_SUCCESS")
    except BaseException as exc:
        print("MPFB_PRECISION_V30_ERROR:", exc)
        traceback.print_exc()
        raise
