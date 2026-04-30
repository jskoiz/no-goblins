# Froge Fly Minigame

This folder contains a small browser minigame inspired by the OpenAI DevDay frog/fly animation.

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
- `sprites/` - frog and fly sprite sheets used by the game.
- `assets/fonts/` - local OpenAI Sans font files used by the HUD.
- `froge-loop.riv` - canonical source Rive asset kept for reference.

## Notes

The repo has been cleaned down to the playable game and the assets it currently needs. Old extraction chunks, cached bundle files, source recordings, frame dumps, and one-off analysis scripts were removed after the Rive asset was recovered.
