# Peel Calm — Owner Playtest

This package is a playtest candidate built from the repository's verified Godot 4.7.1 project. The remaining important judgments are experiential, so please run it like a player rather than like a code review.

## Start

### Windows
1. Extract the whole Windows artifact folder.
2. Run `PeelCalm.exe`.
3. Keep any `.pck` file beside the `.exe` if one is present.

### Linux x86_64
1. Extract the whole Linux artifact folder.
2. If needed: `chmod +x PeelCalm.x86_64`.
3. Run `./PeelCalm.x86_64`.

### Godot editor fallback
If the executable package is blocked by your OS, use the source ZIP with Godot 4.7.1 stable: import `project.godot` and press F5.

## Controls

- Move to the small warm/gold peel edge.
- Hold **left mouse** (or touch) and pull gently away from the cup.
- Release early and re-grab the current gold edge to continue.
- **Esc** — pause / resume.
- **R** — reset the active label; after a completed peel it skips the short presentation delay and advances.
- **Shift+R** — restart the whole run, including score/stamps/unlocks.
- Close the window normally when finished.

## What to test

Try at least 5 clean peels so all three tactile profiles appear: **Warm Paper**, **Silky Long**, and **Crisp Seal**.

Please judge these five things especially:
1. **Resistance:** does the pull feel pleasant and controllable rather than sticky, dead, or twitchy?
2. **Hands:** do the pinch/support poses and forearms look natural enough during motion?
3. **Foley:** are adhesive, paper flex, micro-release, and final-release sounds relaxing and well balanced on your speakers/headphones?
4. **Detach:** does the last bond releasing and the label becoming fully held feel satisfying and clearly untethered?
5. **Visual feel:** does the cup/label/café presentation feel calm and coherent rather than like a technical demo?

## Useful observations to send back

If something feels wrong, the most useful report is short and concrete, for example:
- `Warm Paper: first catch is too hard, then release jumps too fast.`
- `Right hand blocks the peel edge on my display.`
- `Paper flex repeats too loudly during a slow pull.`
- `Final detach looks good but the release sound is too sharp.`

A screenshot or short screen recording is useful for visual issues, but not required.
