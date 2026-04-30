# Frog/Fly ASCII Animation Frames

Extracted from `/Users/jk/Downloads/OpenAI_Developers_-_We_re_so_back_ITJCYm.mp4`.

The source animation is canvas-rendered. These frames are a practical ASCII/Unicode remake: draw each block in a monospace font, advance about every 120-170ms, and loop.

## Character Set

- Frog green: `◎`, `,`, `(`, `)`, `{`, `}`, `<`, `>`, `=`, `-`, `^`
- Flies blue: `~●~`, `c=ɔ`, `^`
- Tongue orange: `----`

## Core Frog Poses

Idle:

```text
  ◎,,◎
 (←→)
(>__<)
^^^ ^^^
```

Mouth open / tongue left:

```text
  ◎,,◎
----}-=>)
(>__<)
^^^ ^^^
```

Compact ASCII-only fallback:

```text
  O,,O
 (<->)
(>__<)
^^^ ^^^
```

```text
  O,,O
----}-=>)
(>__<)
^^^ ^^^
```

## Full Frames

```js
export const frogFlyFrames = [
  String.raw`
             ~●~


                   c=ɔ
        ~●~
                 ◎,,◎
                (←→)
               (>__<)
               ^^^ ^^^`,

  String.raw`
                         c=ɔ


        ~●~
                 ◎,,◎
                (←→)
               (>__<)
               ^^^ ^^^`,

  String.raw`
                   c=ɔ


      c=ɔ
                 ◎,,◎
                (←→)
               (>__<)
               ^^^ ^^^`,

  String.raw`
             ~●~


    ~●~          ◎,,◎          ~●~
                (←→)
               (>__<)
               ^^^ ^^^`,

  String.raw`
             ~●~


   ^●~           ◎,,◎
                (←→)
               (>__<)
               ^^^ ^^^`,

  String.raw`



  ^●~--------}-=>)
                 ◎,,◎
               (>__<)
               ^^^ ^^^`,

  String.raw`
                         c=ɔ


      c=ɔ
                 ◎,,◎
                (←→)
               (>__<)
               ^^^ ^^^`,

  String.raw`
             ~●~


        ~●~      ◎,,◎          ~●~
                (←→)
               (>__<)
               ^^^ ^^^`,
];
```

## Minimal Browser Renderer

```html
<pre id="frog" style="background:#000;color:#6bd34f;font:28px/1.05 monospace;padding:24px;width:max-content"></pre>
<script type="module">
  import { frogFlyFrames } from "./frog_fly_ascii_frames.js";

  const el = document.querySelector("#frog");
  let i = 0;
  setInterval(() => {
    el.textContent = frogFlyFrames[i++ % frogFlyFrames.length];
  }, 140);
</script>
```

For color fidelity, render the frog, flies, and tongue as separate absolutely positioned `<pre>` layers: green frog, blue flies, orange tongue. The single-string frames above are easier to paste and preserve the motion.
