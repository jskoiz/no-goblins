# NO GOBLINS

A tiny browser score-attack game built from the OpenAI DevDay frog/fly animation.

## Run

```sh
python3 -m http.server 8765
```

Then open:

```text
http://127.0.0.1:8765/
```

There is no package install, build step, framework runtime, or backend requirement.

## Details

- Static Canvas 2D runtime in `index.html`.
- Source motion comes from sampled frames in `froge-loop.riv`, not a redraw.
- 1,328 exported frames are deduped to 436 unique frames and packed into a 20-column atlas.
- `sprites/frog_manifest.json` defines frame dimensions, animation ranges, mouth anchors, tongue tips, and eye glow anchors.
- Left, right, and upward tongue strikes use source-derived frames. Longer or off-axis throws extend them with Canvas-drawn ASCII tongue segments.
- `sprites/frog_atlas_clean.png` removes source orange tongue pixels from strike frames so the live tongue starts from the measured mouth anchor.
- Local best score is stored in `localStorage`; optional leaderboard hooks stay disabled behind `LEADERBOARD_ENABLED = false`.

## Asset Pipeline

```text
froge-loop.riv
  -> scripts/export_rive_frames.mjs
  -> scripts/dedupe_sprite_frames.mjs
  -> make_sprite_atlas.swift
  -> sprites/frog_atlas_clean.png + sprites/frog_manifest.json
```

Useful files:

- `index.html` - the playable game and Canvas runtime.
- `froge-loop.riv` - source animation reference.
- `sprites/frog_atlas_clean.png` - runtime frog atlas.
- `sprites/frog_manifest.json` - frame dimensions, animation ranges, mouth anchors, tongue tips, and eye glow anchors.
- `sprites/rive_frog_frames_deduped/` - unique sampled source frames used for the atlas.
- `sprites/fly_sheet.png` - two-frame fly sprite sheet.
- `tools/frame-review.html` - local frame scrubber for checking and tuning animation ranges.
- `assets/favicon.svg`, `assets/og-no-goblins.png` - public metadata assets.

## Regenerate The Atlas

The checked-in atlas is already generated. To rebuild it after changing sampled frames:

```sh
swift make_sprite_atlas.swift
```

The current atlas settings are:

```text
frame size: 360 x 360
columns: 20
frames: 436
runtime atlas: sprites/frog_atlas_clean.png
manifest: sprites/frog_manifest.json
```

To review frame ranges locally, start the server and open:

```text
http://127.0.0.1:8765/tools/frame-review.html
```
