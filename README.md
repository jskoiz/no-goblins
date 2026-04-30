# Froge Fly Minigame

This folder contains a small, intentionally minimal browser score-attack game inspired by the OpenAI DevDay frog/fly animation.

## Play

From this folder:

```sh
python3 -m http.server 8765
```

Then open:

```text
http://127.0.0.1:8765/frog_minigame.html
```

The game is a static single-file Canvas 2D runtime. It does not use React, a game engine, or a build step.

## Main Files

- `frog_minigame.html` - playable browser minigame.
- `sprites/frog_atlas.png` - source 20-column grid atlas for the extracted frog frames.
- `sprites/frog_atlas_clean.png` - runtime atlas with authored orange tongue pixels removed from attack frames.
- `sprites/frog_manifest.json` - frog frame dimensions, mouth/eye offsets, and animation ranges.
- `sprites/fly_sheet.png` - two-frame fly sprite sheet.
- `sprites/rive_frog_frames_deduped/` - deduped source frame sequence used to build the atlas.
- `assets/fonts/` - local OpenAI Sans font files used by the HUD.
- `froge-loop.riv` - canonical source Rive asset kept for reference.
- `tools/frame-review.html` - local helper for scrubbing the frog atlas and copying animation ranges.
- `make_sprite_atlas.swift` - local atlas generator for the checked-in Rive frame extracts.

## Frame Review

Start the local server, then open:

```text
http://127.0.0.1:8765/tools/frame-review.html
```

Use the scrubber and range controls to identify better `idle`, `attackHorizontal`, `attackVertical`, `catchChew`, or `missRecover` ranges. Copy the JSON range into `sprites/frog_manifest.json`; the game reads that manifest at startup.

## Regenerating The Frog Atlas

The current browser-safe atlas is a grid rather than a giant horizontal strip:

```text
frame size: 360 x 360
columns: 20
frames: 436
source atlas: sprites/frog_atlas.png
runtime atlas: sprites/frog_atlas_clean.png
manifest: sprites/frog_manifest.json
```

Regenerate it from the deduped frame folder with:

```sh
swift make_sprite_atlas.swift
```

The older `sprites/frog_sheet.png` remains for reference, but the game prefers `sprites/frog_manifest.json` and `sprites/frog_atlas_clean.png`. The clean atlas lets the canvas-rendered ASCII tongue start at the mouth consistently in `file://`, Helium, and localhost browser modes.

## Leaderboard

Local best score works immediately through `localStorage` under `frog.catch.best`.

Public leaderboard calls are isolated in the game script behind `LEADERBOARD_ENABLED = false`. When a backend exists, enable that flag and provide:

```text
GET  /api/leaderboard?limit=10
POST /api/score
```

Score submissions include session id, score, round duration, tap count, hit count, and client version so a tiny backend can reject obviously impossible scores.

## Notes

The game should stay small and design-focused: 30 seconds, blue flies, orange tongue, mono HUD, local best, and no power-ups or heavy app UI.
