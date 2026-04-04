#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..", "..");
const BUNDLE = path.join(ROOT, "demo", "narrative", "derived", "narrative_bound_bundle.js");
const SCENE_MODULE = pathToFileURL(path.join(ROOT, "demo", "browser", "narrative", "ttc_narrative_scene.js")).href;

const NARRATIVE_CARRIER_MAPPING = {
  claim: {
    material_class: "xx",
    state_class: "LOW_LAW",
    carrier_resolution: {
      resolved_scope: 2,
      resolvable_scope: 0,
      scope_rank: 2,
      closure_rank: 2,
      closure_class: "deterministic_point",
      point_or_region: "point",
      deterministic_closure: true,
    },
  },
  proposal: {
    material_class: "XX",
    state_class: "HIGH_EDIT",
    carrier_resolution: {
      resolved_scope: 0,
      resolvable_scope: 2,
      scope_rank: 0,
      closure_rank: 0,
      closure_class: "open_region",
      point_or_region: "region",
      deterministic_closure: false,
    },
  },
  closure: {
    material_class: "xX",
    state_class: "LOW_LAW",
    carrier_resolution: {
      resolved_scope: 1,
      resolvable_scope: 1,
      scope_rank: 1,
      closure_rank: 2,
      closure_class: "deterministic_projection",
      point_or_region: "region",
      deterministic_closure: true,
    },
  },
  receipt: {
    material_class: "Xx",
    state_class: "LOW_LAW",
    carrier_resolution: {
      resolved_scope: 1,
      resolvable_scope: 1,
      scope_rank: 1,
      closure_rank: 2,
      closure_class: "deterministic_projection",
      point_or_region: "region",
      deterministic_closure: true,
    },
  },
};

function usage() {
  console.error(
    "usage: node scripts/narrative/export_narrative_frames.mjs " +
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

function narrativeCarrierWitness(artifactClass) {
  const mapping = NARRATIVE_CARRIER_MAPPING[artifactClass];
  return {
    material_class: mapping.material_class,
    state_class: mapping.state_class,
    carrier_resolution: { ...mapping.carrier_resolution },
  };
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
    const resolvedStepIdentity = sceneLib.resolveNarrativeSceneStepIdentity(scene);
    const receiptCarrier = narrativeCarrierWitness("receipt");
    const uiFrameResolution = {
      artifact_class: "receipt",
      workflow_mode: "verify",
      step_identity: resolvedStepIdentity,
      frame_scope: {
        kind: "event",
        source_step: String(fromStep),
        target_step: String(toStep),
        receipt_event: `frame:${index}/${frameCount}`,
        contract: "narrative.frame.export.verify.v1",
      },
    };
    fs.writeFileSync(path.join(framesDir, name), `${svgMarkup}\n`, "utf8");
    receipts.push({
      type: "projection_receipt",
      material_class: receiptCarrier.material_class,
      state_class: receiptCarrier.state_class,
      carrier_resolution: receiptCarrier.carrier_resolution,
      artifact_class: "receipt",
      workflow_mode: "verify",
      frame_scope_kind: "event",
      frame_scope_ref: uiFrameResolution.frame_scope,
      chapter_id: scene.chapter_id,
      from_step: String(fromStep),
      to_step: String(toStep),
      frame_index: index,
      frame_total: frameCount,
      t: Number(t.toFixed(3)),
      controls,
      scene_id: scene.scene_id,
      target_step: scene.step,
      resolved_step_identity: resolvedStepIdentity,
      ui_frame_resolution: uiFrameResolution,
      interpolation: scene.interpolation || null,
      scene_hash: sceneLib.projectionHash(sceneJson),
      svg_hash: sceneLib.projectionHash(svgMarkup),
      aframe_scene_hash: sceneLib.projectionHash(aframeSceneJson),
      aframe_markup_hash: sceneLib.projectionHash(aframeMarkup),
      svg_file: path.posix.join("frames", name),
    });
  }

  const manifestCarrier = narrativeCarrierWitness("closure");

  const manifest = {
    type: "narrative_frame_export",
    version: 1,
    material_class: manifestCarrier.material_class,
    state_class: manifestCarrier.state_class,
    carrier_resolution: manifestCarrier.carrier_resolution,
    artifact_class: "closure",
    workflow_mode: "apply",
    frame_scope_kind: "constraint",
    frame_scope_ref: {
      kind: "constraint",
      closure_scope: `frame_window:${fromStep}->${toStep}`,
      contract: "narrative.frame.export.window.v1",
    },
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
