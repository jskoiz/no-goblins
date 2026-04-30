import { createServer } from "node:http";
import { mkdir, writeFile } from "node:fs/promises";
import { spawn } from "node:child_process";
import { once } from "node:events";
import path from "node:path";

const root = process.cwd();
const outputDir = path.join(root, "rive_frames");
const port = 8891;
const debugPort = 9223;
const chromePath = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

await mkdir(outputDir, { recursive: true });

const html = String.raw`<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    html, body { margin: 0; background: #050505; }
    canvas { width: 512px; height: 512px; display: block; }
  </style>
</head>
<body>
  <canvas id="rive" width="1024" height="1024"></canvas>
  <script src="https://unpkg.com/@rive-app/canvas@2.37.5"></script>
  <script>
    const canvas = document.getElementById("rive");
    const frameCount = 1328;
    const fps = 60;
    const duration = 22.1221;

    function nextFrame() {
      return new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    }

    function pngBlob() {
      return new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
    }

    async function postFrame(index, seconds) {
      const blob = await pngBlob();
      await fetch("/frame?index=" + index + "&seconds=" + seconds.toFixed(6), {
        method: "POST",
        body: blob,
      });
    }

    async function run() {
      const riveInstance = new rive.Rive({
        src: "./froge-loop.riv",
        canvas,
        autoplay: false,
        onLoad: async () => {
          riveInstance.resizeDrawingSurfaceToCanvas();
          const animationNames = riveInstance.animationNames.length ? riveInstance.animationNames : undefined;
          for (let index = 0; index < frameCount; index += 1) {
            const seconds = (duration * index) / frameCount;
            riveInstance.scrub(animationNames, seconds);
            await nextFrame();
            await postFrame(index, seconds);
          }
          await fetch("/done", { method: "POST" });
        },
      });
    }

    run().catch(async (error) => {
      await fetch("/error", { method: "POST", body: String(error && error.stack || error) });
    });
  </script>
</body>
</html>`;

let completed = false;
let failed = null;
let received = 0;

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${port}`);
  try {
    if (url.pathname === "/") {
      res.writeHead(200, { "content-type": "text/html" });
      res.end(html);
      return;
    }
    if (url.pathname === "/froge-loop.riv") {
      res.writeHead(200, { "content-type": "application/octet-stream" });
      res.end(await import("node:fs/promises").then((fs) => fs.readFile(path.join(root, "froge-loop.riv"))));
      return;
    }
    if (url.pathname === "/frame") {
      const index = Number(url.searchParams.get("index"));
      const seconds = Number(url.searchParams.get("seconds"));
      const chunks = [];
      req.on("data", (chunk) => chunks.push(chunk));
      await once(req, "end");
      await writeFile(path.join(outputDir, `frame_${String(index).padStart(4, "0")}.png`), Buffer.concat(chunks));
      received += 1;
      res.writeHead(204);
      res.end();
      return;
    }
    if (url.pathname === "/done") {
      completed = true;
      res.writeHead(204);
      res.end();
      return;
    }
    if (url.pathname === "/error") {
      const chunks = [];
      req.on("data", (chunk) => chunks.push(chunk));
      await once(req, "end");
      failed = Buffer.concat(chunks).toString("utf8");
      res.writeHead(204);
      res.end();
      return;
    }
    res.writeHead(404);
    res.end();
  } catch (error) {
    failed = error.stack || String(error);
    res.writeHead(500);
    res.end(String(error));
  }
});

server.listen(port, "127.0.0.1");
await once(server, "listening");

const chrome = spawn(chromePath, [
  "--headless=new",
  `--remote-debugging-port=${debugPort}`,
  "--disable-gpu",
  "--no-first-run",
  "--no-default-browser-check",
  `http://127.0.0.1:${port}/`,
], { stdio: "ignore" });

const started = Date.now();
while (!completed && !failed) {
  if (Date.now() - started > 180000) {
    failed = `Timed out after receiving ${received} frames`;
    break;
  }
  await new Promise((resolve) => setTimeout(resolve, 500));
}

chrome.kill();
server.close();

if (failed) {
  throw new Error(failed);
}

console.log(`wrote ${received} Rive frames to ${path.relative(root, outputDir)}`);
