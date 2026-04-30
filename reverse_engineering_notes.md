# DevDay Frog/Fly Animation Reverse Engineering Notes

## What It Is

The OpenAI DevDay 2026 hero animation is code-rendered, not a GIF, PNG sprite sheet, video, or plain text block.

The production component mounts a 256 x 256 CSS pixel container and uses Rive to render a `.riv` animation into a canvas:

- Component module: `118647`
- Wrapper module: `362347`
- Rive source: `https://cdn.openai.com/ctf-cdn/froge-loop.riv`
- Local copy: `froge-loop.riv`
- Rive file string metadata includes: `frog loop 2`
- Container classes: `relative mx-auto size-64`
- Rive options: `autoplay: true`, `shouldResizeCanvasToContainer: true`
- Fallback: inline SVG, hidden once Rive loads

## Important Correction

The "ASCII" look is made from vector paths and a Rive animation. It is not drawn with `fillText`, and the characters are not recoverable as a text payload from the page. The fallback SVG contains outlines shaped like glyphs, and the Rive file animates equivalent vector artwork.

## Colors

Observed directly from the component fallback SVG:

- Fly blue: `#328FF2`
- Frog green: `#54CA31`

The tongue/impact color seen in the recording is visually orange; it is inside the Rive binary rather than the exported fallback SVG paths.

## Layout

The hero structure is:

```jsx
<div className="relative flex flex-col items-center text-center">
  <FrogeAnimation />
  <h1>Announcing OpenAI DevDay 2026</h1>
  <p>Save the date for September 29th in San Francisco.</p>
</div>
```

`FrogeAnimation` renders:

```jsx
<div className="relative mx-auto size-64">
  <FallbackSvg className="pointer-events-none absolute inset-0 size-full ..." />
  <RiveComponent className="size-full" />
</div>
```

## Rebuild Strategy For A Minigame

For an interactive browser minigame, use a canvas and draw text-shaped glyphs directly. That preserves the readable ASCII feel and makes collision/game logic simple.

Useful glyph set from visual capture:

```text
  ◎,,◎
 (←→)
(>__<)
^^^ ^^^
```

Flies are small blue clusters:

```text
~●~
c●ɔ
```

Tongue/strike frames use an orange horizontal line from the frog mouth to the target, with a small star impact:

```text
----*
```

## Files

- `module_118647_froge_component.min.js`: extracted production component module for local inspection.
- `froge-loop.riv`: downloaded Rive animation asset.
- `frog_minigame.html`: standalone browser minigame recreation.
