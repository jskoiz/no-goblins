# Froge Fly Minigame

This folder contains the OpenAI DevDay frog/fly animation reverse-engineering work and the in-browser minigame prototype.

## Play

From this folder:

```sh
python3 -m http.server 8765
```

Then open:

```text
http://127.0.0.1:8765/frog_minigame.html
```

## Main Files

- `frog_minigame.html` - playable browser minigame.
- `sprites/frog_sheet.png` - generated transparent frog sprite sheet.
- `sprites/fly_sheet.png` - generated transparent two-frame fly sprite sheet.
- `sprites/manifest.json` - sprite dimensions and source metadata.
- `froge-loop.riv` - original Rive asset pulled from the page.
- `froge_rive_reference.html` - minimal page that plays the original Rive animation.
- `reverse_engineering_notes.md` - notes on what the production page does.
- `module_118647_froge_component.min.js` - extracted production component module.

## Extraction Scripts

- `extract_frames.swift` - extracts still frames from the recording.
- `analyze_colored_bounds.swift` - reports colored glyph bounds in captured frames.
- `make_sprite_atlas.swift` - generates the sprite sheets from captured frames.

## Notes

The production page does not expose editable JavaScript keyframes for the frog. It mounts a Rive animation:

```text
https://cdn.openai.com/ctf-cdn/froge-loop.riv
```

The game therefore uses rendered-frame sprite sheets derived from the captured animation, rather than a live pre-composited Rive loop.
