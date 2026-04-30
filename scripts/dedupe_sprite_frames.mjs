import { createHash } from "node:crypto";
import { mkdir, readdir, rm, copyFile, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

const root = process.cwd();
const sourceDir = path.join(root, "sprites", "rive_frog_frames");
const dedupedDir = path.join(root, "sprites", "rive_frog_frames_deduped");
const manifestPath = path.join(root, "sprites", "rive_frog_frame_map.json");

const names = (await readdir(sourceDir))
  .filter((name) => /^frame_\d{4}\.png$/.test(name))
  .sort();

await rm(dedupedDir, { recursive: true, force: true });
await mkdir(dedupedDir, { recursive: true });

const seen = new Map();
const uniqueFrames = [];
const sourceToUnique = [];

for (const name of names) {
  const file = path.join(sourceDir, name);
  const data = await readFile(file);
  const hash = createHash("sha256").update(data).digest("hex");

  let uniqueIndex = seen.get(hash);
  if (uniqueIndex === undefined) {
    uniqueIndex = uniqueFrames.length;
    seen.set(hash, uniqueIndex);
    const uniqueName = `frame_${String(uniqueIndex).padStart(4, "0")}.png`;
    await copyFile(file, path.join(dedupedDir, uniqueName));
    uniqueFrames.push({ file: uniqueName, firstSourceFrame: name, hash });
  }

  sourceToUnique.push(uniqueIndex);
}

await writeFile(
  manifestPath,
  JSON.stringify({
    sourceDirectory: "sprites/rive_frog_frames",
    directory: "sprites/rive_frog_frames_deduped",
    originalFrames: names.length,
    uniqueFrames: uniqueFrames.length,
    framePattern: "frame_%04d.png",
    sourceToUnique,
    uniqueFrameSources: uniqueFrames.map(({ file, firstSourceFrame }) => ({ file, firstSourceFrame })),
  }, null, 2) + "\n",
);

console.log(`deduped ${names.length} frames to ${uniqueFrames.length}`);
