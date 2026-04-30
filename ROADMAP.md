# NO GOBLINS Roadmap

This game should stay small: one fast browser score-attack loop, clean canvas rendering, and no heavy app shell.

## Now

- Keep the visual direction aligned with the black, green, and orange arcade-frog treatment.
- Keep gameplay to a 30-second score attack.
- Use the extracted frog atlas through `sprites/frog_manifest.json`.
- Keep local best score working without any backend.

## Animation Polish

- Done: keep `idle` pinned to true resting frame `23`.
- Done: keep tongue/chew frames out of idle.
- Done: use authored extracted tongue animations for right, left, and up attacks.
- Done: suppress the generated tongue whenever an authored tongue animation is playing.
- Done: extend authored tongue attacks with canvas-drawn ASCII segments so long throws can reach the clicked fly or miss point.
- Next: refine the off-axis/down fallback tongue or add authored diagonal/down source ranges if the extract contains them.
- Next: use `tools/frame-review.html` for final frame-range tuning after the motion direction feels right.

## Verification

- Check desktop and tall/narrow browser sizes.
- Compare the latest game screenshot against the intended arcade-frog reference.
- Confirm the footer stays inside the game frame.
- Confirm HUD scale and color are subdued enough for the mock.

## Later

- Add a public leaderboard only if needed.
- Prefer Cloudflare Workers + D1 for the backend.
- Keep leaderboard code behind the existing optional API interface.
- Reject impossible scores server-side with simple round-duration and score limits.
