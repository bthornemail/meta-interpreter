#!/usr/bin/env python3
"""Generate a self-contained TTC matrix seal page from canonical bytes.

This page is a generated seal surface. Canonical authority remains the
embedded artifact bytes and verified identity, not the page markup or
rendering.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import html
import json
import mimetypes
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
FRAMEWORK_BIN = ROOT / "bin" / "ttc_framework"
RENDERER_JS = ROOT / "demo" / "ttc_projection_renderer.js"
SEAL_FORMAT_VERSION = "matrix_seal_page.v1"


def run_framework(args: list[str], payload: bytes) -> str:
    proc = subprocess.run(
        [str(FRAMEWORK_BIN), *args],
        input=payload,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        stderr = proc.stderr.decode("utf-8", errors="replace")
        raise RuntimeError(f"{' '.join(args)} failed: {stderr.strip()}")
    return proc.stdout.decode("utf-8", errors="replace")


def load_renderer_script() -> str:
    source = RENDERER_JS.read_text(encoding="utf-8")
    return source.replace("export function renderTtcProjection", "function renderTtcProjection", 1)


def parse_runtime_events(ndjson_text: str) -> list[dict[str, object]]:
    events: list[dict[str, object]] = []
    for line in ndjson_text.splitlines():
        line = line.strip()
        if not line:
            continue
        events.append(json.loads(line))
    return events


def chunk_hex(data: str, width: int = 64) -> str:
    if not data:
        return ""
    return "\n".join(data[i : i + width] for i in range(0, len(data), width))


def step_dataset(step: dict[str, object] | None) -> dict[str, str]:
    if not step:
        return {
            "step": "0",
            "digest": "0",
            "triplet": "0,1,3",
            "order": "0,1,3",
            "seq56": "0",
            "layer": "0",
            "coords": "0,0,0",
            "coeff": "0",
        }
    coords = [
        str(step.get("incidence_x", 0)),
        str(step.get("incidence_y", 0)),
        str(step.get("incidence_z", 0)),
    ]
    return {
        "step": str(step.get("tick", 0)),
        "digest": str(step.get("step_digest", 0)),
        "triplet": ",".join(str(v) for v in step.get("triplet", [])),
        "order": ",".join(str(v) for v in step.get("order", [])),
        "seq56": str(step.get("seq56", 0)),
        "layer": str(step.get("incidence_layer", 0)),
        "coords": ",".join(coords),
        "coeff": str(step.get("incidence_coeff", 0)),
    }


def build_step_metadata(step: dict[str, object] | None) -> str:
    if not step:
        return "<p class=\"empty-note\">No runtime steps were emitted for this payload.</p>"

    rows = [
        ("tick", step.get("tick", 0)),
        ("step_digest", step.get("step_digest", 0)),
        ("triplet", json.dumps(step.get("triplet", []))),
        ("order", json.dumps(step.get("order", []))),
        ("seq56", step.get("seq56", 0)),
        ("incidence_layer", step.get("incidence_layer", 0)),
        (
            "incidence_coords",
            f"({step.get('incidence_x', 0)}, {step.get('incidence_y', 0)}, {step.get('incidence_z', 0)})",
        ),
        ("incidence_coeff", step.get("incidence_coeff", 0)),
        ("grammar_role", step.get("grammar_role", 0)),
        ("address_slot", step.get("address_slot", 0)),
        ("address_lane", step.get("address_lane", 0)),
        ("address_channel", step.get("address_channel", 0)),
    ]
    items = []
    for key, value in rows:
        items.append(
            f"<div class=\"meta-card\"><dt>{html.escape(str(key))}</dt><dd>{html.escape(str(value))}</dd></div>"
        )
    return "<dl class=\"meta-grid\">" + "".join(items) + "</dl>"


def build_html(
    *,
    title: str,
    input_path: Path,
    payload: bytes,
    rule_label: str,
    seed: str | None,
    note: str | None,
    artifact_hash: str,
    runtime_events: list[dict[str, object]],
    runtime_ndjson: str,
    matrix_ascii: str,
) -> str:
    payload_hex = payload.hex()
    payload_hex_chunked = chunk_hex(payload_hex)
    payload_b64 = base64.b64encode(payload).decode("ascii")
    content_hint = mimetypes.guess_type(input_path.name)[0] or "application/octet-stream"
    first_step = runtime_events[0] if runtime_events else None
    ds = step_dataset(first_step)
    rule_version = first_step.get("rule_version", rule_label) if first_step else rule_label
    renderer_js = load_renderer_script()
    note_html = (
        f"<div class=\"identity-note\"><span class=\"label\">provenance note</span><div>{html.escape(note)}</div></div>"
        if note
        else ""
    )
    seed_html = (
        f"<div class=\"identity-note\"><span class=\"label\">seed</span><div>{html.escape(seed)}</div></div>"
        if seed
        else ""
    )

    return f"""<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{html.escape(title)}</title>
    <style>
      :root {{
        color-scheme: dark;
        --bg: #020617;
        --panel: rgba(15, 23, 42, 0.88);
        --panel-border: #1e293b;
        --text: #e2e8f0;
        --muted: #94a3b8;
        --accent: #22d3ee;
        --accent-2: #34d399;
        --warn: #f59e0b;
      }}
      * {{ box-sizing: border-box; }}
      body {{
        margin: 0;
        background: radial-gradient(circle at top, #0f172a, var(--bg) 55%);
        color: var(--text);
        font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      }}
      main {{
        max-width: 1340px;
        margin: 0 auto;
        padding: 32px 24px 56px;
        display: flex;
        flex-direction: column;
        gap: 24px;
      }}
      header {{
        border-bottom: 1px solid var(--panel-border);
        padding-bottom: 20px;
      }}
      .eyebrow {{
        margin: 0 0 10px;
        color: var(--accent);
        font-size: 12px;
        text-transform: uppercase;
        letter-spacing: 0.3em;
      }}
      h1 {{
        margin: 0 0 12px;
        font-size: clamp(2rem, 3vw, 3rem);
      }}
      .lede {{
        max-width: 72ch;
        color: var(--muted);
        line-height: 1.65;
      }}
      .layout {{
        display: grid;
        gap: 20px;
      }}
      .card {{
        background: var(--panel);
        border: 1px solid var(--panel-border);
        border-radius: 20px;
        padding: 20px;
        box-shadow: 0 0 0 1px rgba(255,255,255,0.02);
      }}
      .card h2 {{
        margin: 0 0 10px;
        font-size: 1.1rem;
      }}
      .card p {{
        margin: 0;
        color: var(--muted);
        line-height: 1.6;
      }}
      .identity-grid, .payload-grid, .meta-grid {{
        margin-top: 16px;
        display: grid;
        gap: 12px;
      }}
      .identity-grid {{
        grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      }}
      .payload-grid {{
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      }}
      .meta-grid {{
        grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      }}
      .metric, .meta-card, .identity-note {{
        border: 1px solid var(--panel-border);
        border-radius: 14px;
        background: rgba(2, 6, 23, 0.72);
        padding: 14px;
      }}
      .label, .metric dt, .meta-card dt {{
        margin: 0 0 8px;
        color: var(--muted);
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.22em;
      }}
      .metric dd, .meta-card dd {{
        margin: 0;
        font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
        word-break: break-word;
      }}
      pre {{
        margin: 0;
        padding: 16px;
        overflow: auto;
        border-radius: 14px;
        border: 1px solid var(--panel-border);
        background: rgba(2, 6, 23, 0.9);
        color: #cbd5e1;
        font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
        font-size: 12px;
        line-height: 1.55;
        white-space: pre-wrap;
        overflow-wrap: anywhere;
      }}
      .seal-grid {{
        display: grid;
        gap: 20px;
        grid-template-columns: minmax(0, 1.05fr) minmax(0, 0.95fr);
      }}
      .placeholder {{
        border: 1px dashed #475569;
        border-radius: 14px;
        padding: 16px;
        color: var(--warn);
        background: rgba(30, 41, 59, 0.35);
      }}
      .projection-grid {{
        display: grid;
        gap: 20px;
        grid-template-columns: minmax(0, 1fr) minmax(0, 1.1fr);
      }}
      .step-surface {{
        border: 1px solid rgba(34, 211, 238, 0.45);
        background: rgba(34, 211, 238, 0.08);
        border-radius: 16px;
        padding: 18px;
      }}
      .step-top {{
        display: flex;
        justify-content: space-between;
        gap: 16px;
        align-items: flex-start;
      }}
      .step-title {{
        color: #67e8f9;
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.24em;
      }}
      .step-value, .badge {{
        font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      }}
      .step-value {{
        margin-top: 8px;
        font-size: 1.15rem;
      }}
      .badge {{
        padding: 6px 10px;
        border-radius: 999px;
        background: rgba(2, 6, 23, 0.72);
        font-size: 12px;
        color: #cbd5e1;
      }}
      .canvas-shell {{
        border: 1px solid var(--panel-border);
        border-radius: 16px;
        background: rgba(2, 6, 23, 0.72);
        padding: 12px;
      }}
      canvas {{
        display: block;
        width: 100%;
        height: auto;
        border-radius: 12px;
        border: 1px solid var(--panel-border);
        background: #000;
      }}
      footer {{
        color: var(--muted);
        line-height: 1.65;
        padding-top: 8px;
      }}
      .empty-note {{
        margin-top: 16px;
        color: var(--muted);
      }}
      @media (max-width: 980px) {{
        .seal-grid, .projection-grid {{
          grid-template-columns: 1fr;
        }}
      }}
    </style>
  </head>
  <body>
    <!--
      This page is a generated seal surface.
      Canonical authority remains the embedded artifact bytes and verified identity,
      not the page markup or rendering.

      data-ttc-* is derived projection metadata only.
      It must never drive runtime or canonical decisions.
    -->
    <main data-ttc-root>
      <header>
        <p class="eyebrow">TTC Matrix Seal Page</p>
        <h1>{html.escape(title)}</h1>
        <p class="lede">
          This page is a generated seal surface. Canonical authority remains the embedded
          artifact bytes and verified identity, not the page markup or rendering.
        </p>
      </header>

      <section class="card">
        <h2>Identity</h2>
        <p>The seal page is generated from canonical bytes and artifact identity. It does not define runtime law, schema authority, or transport semantics.</p>
        <div class="identity-grid">
          <div class="metric"><dt>artifact hash (sha256)</dt><dd>{html.escape(artifact_hash)}</dd></div>
          <div class="metric"><dt>rule version</dt><dd>{html.escape(str(rule_version))}</dd></div>
          <div class="metric"><dt>seal format version</dt><dd>{html.escape(SEAL_FORMAT_VERSION)}</dd></div>
          <div class="metric"><dt>generator</dt><dd>generate_matrix_seal_page.py</dd></div>
        </div>
        {note_html}
        {seed_html}
      </section>

      <section class="card">
        <h2>Canonical Payload</h2>
        <p>The payload is shown as a readable witness form. These views do not replace the canonical byte substrate.</p>
        <div class="payload-grid">
          <div class="metric"><dt>input path</dt><dd>{html.escape(str(input_path))}</dd></div>
          <div class="metric"><dt>payload length</dt><dd>{len(payload)} byte(s)</dd></div>
          <div class="metric"><dt>content-type hint</dt><dd>{html.escape(content_hint)}</dd></div>
          <div class="metric"><dt>payload base64</dt><dd>{html.escape(payload_b64)}</dd></div>
        </div>
        <div class="layout" style="margin-top:16px;">
          <div>
            <div class="label">payload hex</div>
            <pre>{html.escape(payload_hex_chunked)}</pre>
          </div>
        </div>
      </section>

      <section class="card">
        <h2>Seal Surface</h2>
        <p>TTC matrix is the current honest seal surface. Standards Aztec remains reserved for future implementation.</p>
        <div class="seal-grid" style="margin-top:16px;">
          <div>
            <div class="label">ttc matrix symbol (ascii)</div>
            <pre>{html.escape(matrix_ascii)}</pre>
          </div>
          <div class="placeholder">
            <div class="label">future standards aztec</div>
            <p style="margin:0; color:inherit;">
              Reserved for a future standards-compliant Aztec layer with mode message,
              Reed-Solomon ECC, and scanner interoperability.
            </p>
          </div>
        </div>
      </section>

      <section class="card">
        <h2>Replay Preview</h2>
        <p>The replay preview is a deterministic witness of runtime output, not a replacement for replay itself.</p>
        {build_step_metadata(first_step)}
        <div class="layout" style="margin-top:16px;">
          <div>
            <div class="label">sample runtime ndjson</div>
            <pre>{html.escape(runtime_ndjson.strip())}</pre>
          </div>
        </div>
      </section>

      <section class="card">
        <h2>Projection Viewer</h2>
        <p>The browser viewer remains projection-only. It reuses the frozen <code>data-ttc-*</code> contract and does not compute runtime state.</p>
        <div class="projection-grid" style="margin-top:16px;">
          <article
            id="seal-step"
            class="step-surface"
            data-ttc-surface="step"
            data-ttc-step="{html.escape(ds['step'])}"
            data-ttc-digest="{html.escape(ds['digest'])}"
            data-ttc-triplet="{html.escape(ds['triplet'])}"
            data-ttc-order="{html.escape(ds['order'])}"
            data-ttc-seq56="{html.escape(ds['seq56'])}"
            data-ttc-incidence-layer="{html.escape(ds['layer'])}"
            data-ttc-incidence-coords="{html.escape(ds['coords'])}"
            data-ttc-incidence-coeff="{html.escape(ds['coeff'])}"
          >
            <div class="step-top">
              <div>
                <div class="step-title">Sealed Step Preview</div>
                <div id="panel-step" class="step-value">{html.escape(ds['step'])}</div>
              </div>
              <div id="panel-seq56-badge" class="badge">seq56 {html.escape(ds['seq56'])}</div>
            </div>
            <dl class="meta-grid" style="margin-top:16px;">
              <div class="meta-card"><dt>Digest</dt><dd id="panel-digest">{html.escape(ds['digest'])}</dd></div>
              <div class="meta-card"><dt>Triplet</dt><dd id="panel-triplet">[{html.escape(ds['triplet'].replace(',', ', '))}]</dd></div>
              <div class="meta-card"><dt>Order</dt><dd id="panel-order">[{html.escape(ds['order'].replace(',', ', '))}]</dd></div>
              <div class="meta-card"><dt>seq56</dt><dd id="panel-seq56">{html.escape(ds['seq56'])}</dd></div>
              <div class="meta-card"><dt>Layer</dt><dd id="panel-layer">{html.escape(ds['layer'])}</dd></div>
              <div class="meta-card"><dt>Coords</dt><dd id="panel-coords">({html.escape(ds['coords'].replace(',', ', '))})</dd></div>
              <div class="meta-card"><dt>Coefficient</dt><dd id="panel-coeff">{html.escape(ds['coeff'])}</dd></div>
            </dl>
          </article>
          <div class="canvas-shell">
            <canvas
              id="ttc-canvas"
              width="520"
              height="360"
              data-ttc-surface="matrix"
            ></canvas>
          </div>
        </div>
      </section>

      <footer class="card">
        <p>This page is a generated seal surface. Canonical authority remains the embedded artifact bytes and verified identity, not the page markup or rendering.</p>
      </footer>
    </main>

    <script>
{renderer_js}

const stepEl = document.getElementById("seal-step");
renderTtcProjection(stepEl);
    </script>
  </body>
</html>
"""


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate a TTC matrix seal page from canonical bytes.")
    parser.add_argument("--input", required=True, help="Path to canonical payload bytes.")
    parser.add_argument("--output", required=True, help="Output HTML path.")
    parser.add_argument("--title", default="TTC Matrix Seal Page", help="Seal page title.")
    parser.add_argument("--rule", default="current", choices=("current", "delta64"), help="Runtime rule.")
    parser.add_argument("--seed", help="Optional runtime seed, used for delta64 when provided.")
    parser.add_argument("--note", help="Optional provenance/build note.")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)
    payload = input_path.read_bytes()
    artifact_hash = hashlib.sha256(payload).hexdigest()

    runtime_args = ["runtime", "--rule", args.rule]
    if args.seed:
        runtime_args.extend(["--seed", args.seed])
    runtime_ndjson = run_framework(runtime_args, payload)
    runtime_events = parse_runtime_events(runtime_ndjson)
    matrix_ascii = run_framework(["matrix-encode", "--ascii"], payload)

    html_text = build_html(
        title=args.title,
        input_path=input_path,
        payload=payload,
        rule_label=args.rule,
        seed=args.seed,
        note=args.note,
        artifact_hash=artifact_hash,
        runtime_events=runtime_events,
        runtime_ndjson=runtime_ndjson,
        matrix_ascii=matrix_ascii,
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(html_text, encoding="utf-8")
    print(f"wrote {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
