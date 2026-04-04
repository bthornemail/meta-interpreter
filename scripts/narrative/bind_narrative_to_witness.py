#!/usr/bin/env python3
"""
Bind canonical narrative NDJSON chapters to template and witness-plane overlays.

This script derives a downstream witness artifact only.
It does not mutate canonical narrative records or runtime law.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import OrderedDict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CANONICAL_DIR = ROOT / "demo" / "narrative" / "canonical"
DERIVED_DIR = ROOT / "demo" / "narrative" / "derived"
CHAPTERS_DIR = CANONICAL_DIR / "chapters"
TEMPLATES_PATH = CANONICAL_DIR / "templates" / "character_progression_templates.json"
HOOKS_PATH = CANONICAL_DIR / "witness_article_hooks.json"
DEFAULT_NDJSON_OUT = DERIVED_DIR / "narrative.bound.v0.ndjson"
DEFAULT_JS_OUT = DERIVED_DIR / "narrative_bound_bundle.js"

TOKEN_RE = re.compile(r"[a-z0-9]+")


def normalize_tokens(*values: str) -> set[str]:
    tokens: set[str] = set()
    for value in values:
        tokens.update(TOKEN_RE.findall(value.lower()))
    return tokens


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_chapter(path: Path) -> dict:
    records = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            records.append(json.loads(line))

    meta = next(record for record in records if record["type"] == "chapter_meta")
    artifact = next((record for record in records if record["type"] == "artifact"), None)
    scenes = OrderedDict((record["id"], record) for record in records if record["type"] == "scene")
    choices = [record for record in records if record["type"] == "choice"]
    semantic_nodes = OrderedDict((record["id"], record) for record in records if record["type"] == "semantic_node")
    semantic_edges = OrderedDict((record["id"], record) for record in records if record["type"] == "semantic_edge")
    semantic_transitions = [record for record in records if record["type"] == "semantic_transition"]

    return {
        "path": path,
        "records": records,
        "meta": meta,
        "artifact": artifact,
        "scenes": scenes,
        "choices": choices,
        "semantic_nodes": semantic_nodes,
        "semantic_edges": semantic_edges,
        "semantic_transitions": semantic_transitions,
    }


def fallback_template_for_phase(phase: str) -> str:
    mapping = {
        "prelude": "tpl_watcher_bootstrap_loop_v1",
        "article": "tpl_tribe_reconciliation_arc_v1",
        "epilogue": "tpl_witness_gate_city_v1",
    }
    return mapping.get(phase, "tpl_watcher_bootstrap_loop_v1")


def choose_template(chapter: dict, templates: list[dict]) -> dict:
    meta = chapter["meta"]
    tokens = normalize_tokens(meta["title"], meta.get("world_theme", ""))
    for scene in chapter["scenes"].values():
        tokens.update(normalize_tokens(scene.get("heading", ""), scene.get("body_text", "")))
    for node in chapter["semantic_nodes"].values():
        tokens.update(normalize_tokens(node.get("label", ""), node.get("kind", "")))

    best = None
    fallback_id = fallback_template_for_phase(meta.get("phase", ""))
    for template in templates:
        score = 0
        for node in template["nodes"]:
            label_tokens = normalize_tokens(node.get("label", ""))
            if label_tokens and label_tokens.issubset(tokens):
                score += 3
            elif tokens.intersection(label_tokens):
                score += 1
        for edge in template["edges"]:
            pred_tokens = normalize_tokens(edge.get("predicate", ""))
            if pred_tokens and pred_tokens.issubset(tokens):
                score += 2
        if best is None or score > best["score"] or (
            score == best["score"] and template["id"] == fallback_id
        ):
            best = {"template": template, "score": score}

    if best is None or best["score"] == 0:
        for template in templates:
            if template["id"] == fallback_id:
                return template
    return best["template"]


def choose_witness_role(chapter: dict, template: dict, hook_matches: list[dict]) -> str:
    title_tokens = normalize_tokens(chapter["meta"]["title"])
    hook_checks = " ".join(
        check for hook in hook_matches for check in hook.get("checks", [])
    ).lower()
    if "law" in hook_checks or "covenant" in title_tokens or "authority" in title_tokens:
        return "advisor.law"
    if "reconciliation" in title_tokens or template["id"] == "tpl_tribe_reconciliation_arc_v1":
        return "advisor.cohesion"
    if hook_matches:
        return "advisor.wisdom"
    return "witness.observe"


def projection_audio_cue(role: str, template_id: str) -> str:
    if role == "advisor.law":
        return "sustained_low_tone"
    if role == "advisor.cohesion":
        return "warm_pulse"
    if template_id == "tpl_watcher_bootstrap_loop_v1":
        return "watcher_chime"
    return "quiet_observation"


def build_bound_artifact(chapters: list[dict], templates: list[dict], hooks: list[dict]) -> tuple[list[dict], dict]:
    template_by_id = {template["id"]: template for template in templates}
    hooks_by_source = {}
    for hook in hooks:
        hooks_by_source.setdefault(hook["source_path"], []).append(hook)

    bound_records: list[dict] = [
        {
            "type": "narrative_binding_meta",
            "version": 1,
            "series": "When Wisdom, Law, and the Tribe Sat Down Together",
            "authority": "canonical narrative remains sovereign; witness binding is advisory only",
            "source": "demo/narrative/canonical/chapters/*.ndjson",
            "templates_path": "demo/narrative/canonical/templates/character_progression_templates.json",
            "hooks_path": "demo/narrative/canonical/witness_article_hooks.json",
        }
    ]
    bundle_chapters: list[dict] = []
    global_step = 0

    for chapter in chapters:
        meta = chapter["meta"]
        template = choose_template(chapter, templates)
        hook_matches = hooks_by_source.get(meta["source_path"], [])
        role = choose_witness_role(chapter, template, hook_matches)
        transitions = template["transitions"]
        template_edges = {edge["id"]: edge for edge in template["edges"]}
        step_records = []

        chapter_summary = {
            "type": "narrative_bound_chapter",
            "chapter_id": meta["id"],
            "title": meta["title"],
            "order": meta.get("order"),
            "phase": meta["phase"],
            "world_theme": meta["world_theme"],
            "template_id": template["id"],
            "template_name": template["name"],
            "witness_role": role,
            "hook_ids": [hook["id"] for hook in hook_matches],
            "source_path": meta["source_path"],
            "artifact_id": chapter["artifact"]["id"] if chapter["artifact"] else None,
            "semantic_transition_count": len(chapter["semantic_transitions"]),
        }
        bound_records.append(chapter_summary)

        transition_targets = {}
        transition_targets.update(chapter["semantic_nodes"])
        transition_targets.update(chapter["semantic_edges"])

        for chapter_step, transition in enumerate(chapter["semantic_transitions"], start=1):
            global_step += 1
            scene = chapter["scenes"].get(transition["scene_id"])
            template_transition = transitions[(chapter_step - 1) % len(transitions)]
            template_edge = template_edges.get(template_transition["target_id"])
            target = transition_targets.get(transition["target_id"], {})
            record = {
                "type": "narrative_bound_step",
                "version": 1,
                "step": global_step,
                "chapter_step": chapter_step,
                "chapter_id": meta["id"],
                "scene_id": transition["scene_id"],
                "template_id": template["id"],
                "template_transition_id": template_transition["id"],
                "template_transition_op": template_transition["op"],
                "template_edge_id": template_transition.get("target_id"),
                "template_edge_predicate": template_edge.get("predicate") if template_edge else None,
                "semantic_transition_id": transition["id"],
                "semantic_op": transition["op"],
                "semantic_target_id": transition["target_id"],
                "semantic_target_type": target.get("type"),
                "semantic_target_kind": target.get("kind"),
                "world_theme": meta["world_theme"],
                "witness": {
                    "role": role,
                    "hook_ids": [hook["id"] for hook in hook_matches],
                    "checks": [check for hook in hook_matches for check in hook.get("checks", [])],
                    "receipt_templates": [
                        hook["receipt_template"] for hook in hook_matches if hook.get("receipt_template")
                    ],
                    "source_refs": [hook["source_path"] for hook in hook_matches],
                },
                "projection": {
                    "heading": scene.get("heading") if scene else None,
                    "world_node": scene.get("world_node") if scene else None,
                    "text_excerpt": ((scene.get("body_text") or "")[:220].strip()) if scene else "",
                    "visual": {
                        "template_id": template["id"],
                        "scene_heading": scene.get("heading") if scene else None,
                        "world_theme": meta["world_theme"],
                    },
                    "audio": {
                        "cue": projection_audio_cue(role, template["id"]),
                        "voice_role": role,
                    },
                },
            }
            step_records.append(record)
            bound_records.append(record)

        bundle_chapters.append(
            {
                "chapter": chapter_summary,
                "template": template,
                "hooks": hook_matches,
                "steps": step_records,
                "scene_count": len(chapter["scenes"]),
            }
        )

    bundle = {
        "type": "narrative_witness_binding_bundle",
        "version": 1,
        "meta": bound_records[0],
        "templates": templates,
        "chapters": bundle_chapters,
        "chapter_order": [chapter["chapter"]["chapter_id"] for chapter in bundle_chapters],
    }
    return bound_records, bundle


def write_ndjson(path: Path, records: list[dict]) -> None:
    lines = [json.dumps(record, ensure_ascii=True, sort_keys=True) for record in records]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_js_bundle(path: Path, bundle: dict) -> None:
    payload = json.dumps(bundle, ensure_ascii=True, sort_keys=True)
    path.write_text(f"window.NARRATIVE_WITNESS_DATA = {payload};\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bind narrative NDJSON chapters to witness-plane overlays.")
    parser.add_argument("--out-ndjson", default=str(DEFAULT_NDJSON_OUT))
    parser.add_argument("--out-js", default=str(DEFAULT_JS_OUT))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    templates = load_json(TEMPLATES_PATH)["templates"]
    hooks = load_json(HOOKS_PATH)["hooks"]
    chapters = [load_chapter(path) for path in sorted(CHAPTERS_DIR.glob("*.ndjson"))]
    bound_records, bundle = build_bound_artifact(chapters, templates, hooks)

    out_ndjson = Path(args.out_ndjson)
    out_js = Path(args.out_js)
    out_ndjson.parent.mkdir(parents=True, exist_ok=True)
    out_js.parent.mkdir(parents=True, exist_ok=True)
    write_ndjson(out_ndjson, bound_records)
    write_js_bundle(out_js, bundle)

    def display_path(path: Path) -> str:
        try:
            return str(path.relative_to(ROOT))
        except ValueError:
            return str(path)

    print(
        json.dumps(
            {
                "bound_records": len(bound_records),
                "chapters": len(chapters),
                "out_ndjson": display_path(out_ndjson),
                "out_js": display_path(out_js),
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
