"""Export an image to deterministic low-resolution RGB hex rows for remote visual review.

Usage in Blender:
  blender --background --python tools/export_render_rgbhex.py -- input.png output.rgbhex 128 128

The text format is intentionally simple: first line `RGBHEX <w> <h>`, followed by one
row per image row containing exactly w RGB hex triplets. This lets review tooling retrieve
bounded line ranges and reconstruct the real render without OCR or lossy prose summaries.
"""
from __future__ import annotations

import sys
from pathlib import Path

import bpy


def _args():
    if "--" not in sys.argv:
        raise RuntimeError("missing -- args")
    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) != 4:
        raise RuntimeError("expected input output width height")
    return Path(args[0]), Path(args[1]), int(args[2]), int(args[3])


def _clamp_byte(v: float) -> int:
    return max(0, min(255, int(round(v * 255.0))))


def main() -> None:
    src, dst, width, height = _args()
    if width <= 0 or height <= 0 or width > 256 or height > 256:
        raise RuntimeError("unsupported dimensions")
    image = bpy.data.images.load(str(src.resolve()), check_existing=False)
    image.scale(width, height)
    pixels = list(image.pixels[:])
    dst.parent.mkdir(parents=True, exist_ok=True)
    with dst.open("w", encoding="ascii") as fh:
        fh.write(f"RGBHEX {width} {height}\n")
        for y in range(height):
            # Blender image pixels are bottom-up; write top-down for normal image reconstruction.
            source_y = height - 1 - y
            row = []
            for x in range(width):
                i = (source_y * width + x) * 4
                row.append(f"{_clamp_byte(pixels[i]):02x}{_clamp_byte(pixels[i+1]):02x}{_clamp_byte(pixels[i+2]):02x}")
            fh.write("".join(row) + "\n")
    bpy.data.images.remove(image)
    print("RGBHEX_EXPORT_SUCCESS", src, dst, width, height)


if __name__ == "__main__":
    main()
