#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
const BUNDLE = path.join(ROOT, "demo", "narrative_data", "narrative_bound_bundle.js");
const SCENE_MODULE = pathToFileURL(path.join(ROOT, "demo", "ttc_narrative_scene.js")).href;

function usage() {
  console.error(
    "usage: node scripts/export_narrative_frames.mjs " +
      "--chapter CHAPTER_ID --from-step N --to-step N --out-dir DIR " +
      "[--frames N] [--mode narrative|witness] [--frame semantic_graph|world|replay_timeline] " +
      "[--attention narrow|expand] [--depth less|more]",
  );
}

function parseArgs(argv) {
  const args = {};
  for (let index = 2; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) {
      throw new Error(`unexpected argument: ${token}`);
    }
    const key = token.slice(2);
    const value = argv[index + 1];
    if (!value || value.startsWith("--")) {
      throw new Error(`missing value for --${key}`);
    }
    args[key] = value;
    index += 1;
  }
  return args;
}

function parseBundle() {
  const text = fs.readFileSync(BUNDLE, "utf8");
  const eq = text.indexOf("=");
  if (eq < 0) {
    throw new Error("narrative bundle missing assignment");
  }
  return JSON.parse(text.slice(eq + 1).trim().replace(/;\s*$/, ""));
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function stableStringify(value) {
  return JSON.stringify(value);
}

function frameFileName(index) {
  return `frame_${String(index).padStart(3, "0")}.svg`;
}

async function main() {
  let args;
  try {
    args = parseArgs(process.argv);
  } catch (error) {
    console.error(String(error.message || error));
    usage();
    process.exit(1);
  }

  const required = ["chapter", "from-step", "to-step", "out-dir"];
  for (const key of required) {
    if (!args[key]) {
      usage();
      process.exit(1);
    }
  }

  const mode = args.mode || "narrative";
  const frame = args.frame || "semantic_graph";
  const attention = args.attention || "narrow";
  const depth = args.depth || "less";
  const fromStep = Number(args["from-step"]);
  const toStep = Number(args["to-step"]);
  if (!Number.isInteger(fromStep) || !Number.isInteger(toStep) || fromStep < 1 || toStep < 1) {
    throw new Error("from-step and to-step must be positive integers");
  }

  const bundle = parseBundle();
  const chapterEntry = bundle.chapters.find((entry) => entry.chapter.chapter_id === args.chapter);
  if (!chapterEntry) {
    throw new Error(`chapter not found: ${args.chapter}`);
  }
  const sourceRecord = chapterEntry.steps[Math.min(fromStep - 1, chapterEntry.steps.length - 1)];
  const targetRecord = chapterEntry.steps[Math.min(toStep - 1, chapterEntry.steps.length - 1)];
  if (!sourceRecord || !targetRecord) {
    throw new Error("source or target step missing from chapter");
  }

  const sceneLib = await import(SCENE_MODULE);
  const controls = { mode, frame, attention, depth };
  const defaultFrames = sourceRecord.chapter_step === targetRecord.chapter_step
    ? 1
    : sceneLib.frameBudgetForControls(controls);
  const frameCount = Math.max(1, Number(args.frames || defaultFrames));
  const fromScene = sceneLib.buildNarrativeScene(chapterEntry, sourceRecord, controls);
  const toScene = sceneLib.buildNarrativeScene(chapterEntry, targetRecord, controls);

  const outDir = path.resolve(args["out-dir"]);
  ensureDir(outDir);
  const framesDir = path.join(outDir, "frames");
  ensureDir(framesDir);

  const receipts = [];
  for (let index = 0; index < frameCount; index += 1) {
    const t = frameCount === 1 ? 1 : index / (frameCount - 1);
    const scene = sourceRecord.chapter_step === targetRecord.chapter_step
      ? toScene
      : sceneLib.interpolateNarrativeScene(fromScene, toScene, t);
    const svgMarkup = sceneLib.renderNarrativeSceneSvg(scene);
    const aframeScene = sceneLib.buildNarrativeAFrameScene(scene);
    const aframeMarkup = sceneLib.renderNarrativeAFrameMarkup(aframeScene);
    const sceneJson = stableStringify(scene);
    const aframeSceneJson = stableStringify(aframeScene);
    const name = frameFileName(index);
    fs.writeFileSync(path.join(framesDir, name), `${svgMarkup}\n`, "utf8");
    receipts.push({
      type: "projection_receipt",
      chapter_id: scene.chapter_id,
      from_step: String(fromStep),
      to_step: String(toStep),
      frame_index: index,
      frame_total: frameCount,
      t: Number(t.toFixed(3)),
      controls,
      scene_id: scene.scene_id,
      target_step: scene.step,
      interpolation: scene.interpolation || null,
      scene_hash: sceneLib.projectionHash(sceneJson),
      svg_hash: sceneLib.projectionHash(svgMarkup),
      aframe_scene_hash: sceneLib.projectionHash(aframeSceneJson),
      aframe_markup_hash: sceneLib.projectionHash(aframeMarkup),
      svg_file: path.posix.join("frames", name),
    });
  }

  const manifest = {
    type: "narrative_frame_export",
    version: 1,
    chapter_id: args.chapter,
    chapter_title: chapterEntry.chapter.title,
    template_id: chapterEntry.chapter.template_id,
    from_step: String(fromStep),
    to_step: String(toStep),
    controls,
    frame_total: frameCount,
    receipts,
  };

  fs.writeFileSync(path.join(outDir, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`, "utf8");
  fs.writeFileSync(
    path.join(outDir, "projection_receipts.ndjson"),
    `${receipts.map((receipt) => JSON.stringify(receipt)).join("\n")}\n`,
    "utf8",
  );

  console.log(
    JSON.stringify(
      {
        chapter_id: args.chapter,
        from_step: String(fromStep),
        to_step: String(toStep),
        frame_total: frameCount,
        out_dir: outDir,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error.message || String(error));
  process.exit(1);
});
