// Narrative scene model and SVG extrusion are downstream projection only.
// Same bound narrative step must yield the same normalized scene object and
// the same SVG witness. Renderer differences may change presentation only,
// never narrative authority.
//
// Future A-Frame contract:
// - consume the same normalized scene object
// - map nodes to 3D anchors
// - map edges to lines/tubes
// - map active transition to elevation/highlight only
// - do not bypass binder/scene layers or redefine semantics

function stableHash(input) {
  let hash = 2166136261;
  for (let index = 0; index < input.length; index += 1) {
    hash ^= input.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function depthScale(depth) {
  return depth === "more" ? 1 : 0.45;
}

function attentionSettings(attention) {
  return attention === "expand"
    ? { inactiveOpacity: 0.92, edgeOpacity: 0.88, shadowOpacity: 0.42 }
    : { inactiveOpacity: 0.62, edgeOpacity: 0.54, shadowOpacity: 0.24 };
}

function chapterSubtitle(chapterEntry, stepRecord, frame, mode) {
  return `${chapterEntry.chapter.phase} · ${chapterEntry.chapter.world_theme} · ${frame} · ${mode}`;
}

function orderedTemplateNodes(template) {
  return [...template.nodes].sort((left, right) => left.id.localeCompare(right.id));
}

function orderedTemplateEdges(template) {
  return [...template.edges].sort((left, right) => left.id.localeCompare(right.id));
}

export function buildNarrativeScene(chapterEntry, stepRecord, controls) {
  const template = chapterEntry.template;
  const mode = controls.mode;
  const frame = controls.frame;
  const attention = controls.attention;
  const depth = controls.depth;
  const nodes = orderedTemplateNodes(template);
  const edges = orderedTemplateEdges(template);
  const activeTransition = {
    template_transition_id: stepRecord.template_transition_id,
    template_edge_id: stepRecord.template_edge_id,
    semantic_transition_id: stepRecord.semantic_transition_id,
    semantic_target_id: stepRecord.semantic_target_id,
  };
  const activeEdge = edges.find((edge) => edge.id === stepRecord.template_edge_id) || null;
  const activeNodeIds = new Set(activeEdge ? [activeEdge.subject, activeEdge.object] : []);
  const ringRadius = 118;
  const centerX = 250;
  const centerY = 178;
  const extrusion = depthScale(depth);

  const nodeEntries = nodes.map((node, index) => {
    const angle = ((Math.PI * 2) / nodes.length) * index - Math.PI / 2;
    const layerSeed = stableHash(`${chapterEntry.chapter.chapter_id}:${node.id}:${frame}`);
    const layer = layerSeed % 4;
    const z = Math.round((layer + 1) * 18 * extrusion);
    const x = Number((centerX + Math.cos(angle) * ringRadius).toFixed(3));
    const y = Number((centerY + Math.sin(angle) * ringRadius).toFixed(3));
    return {
      id: node.id,
      label: node.label,
      kind: node.kind,
      x,
      y,
      z,
      layer,
      active: activeNodeIds.has(node.id),
      highlight: activeNodeIds.has(node.id) || stepRecord.witness.role.endsWith("law") && node.kind === "law",
    };
  });

  const positionById = new Map(nodeEntries.map((node) => [node.id, node]));
  const edgeEntries = edges.map((edge) => {
    const subject = positionById.get(edge.subject);
    const object = positionById.get(edge.object);
    const layerSeed = stableHash(`${chapterEntry.chapter.chapter_id}:${edge.id}:${mode}`);
    const layer = layerSeed % 3;
    const offset = Number((((layer + 1) * 6) - 9).toFixed(3));
    return {
      id: edge.id,
      subject: edge.subject,
      object: edge.object,
      predicate: edge.predicate,
      layer,
      offset,
      active: edge.id === stepRecord.template_edge_id,
      highlight: edge.id === stepRecord.template_edge_id,
      x1: subject.x,
      y1: subject.y,
      x2: object.x,
      y2: object.y,
      z1: subject.z,
      z2: object.z,
    };
  });

  return {
    chapter_id: chapterEntry.chapter.chapter_id,
    step: String(stepRecord.chapter_step),
    scene_id: stepRecord.scene_id,
    template_id: chapterEntry.chapter.template_id,
    frame,
    mode,
    attention,
    depth,
    title: chapterEntry.chapter.title,
    subtitle: chapterSubtitle(chapterEntry, stepRecord, frame, mode),
    nodes: nodeEntries,
    edges: edgeEntries,
    active_transition: activeTransition,
    witness: {
      role: stepRecord.witness.role,
      hook_ids: [...stepRecord.witness.hook_ids],
      checks: [...stepRecord.witness.checks],
      receipt_templates: [...stepRecord.witness.receipt_templates],
    },
    excerpt: stepRecord.projection.text_excerpt || "",
  };
}

export function renderNarrativeSceneSvg(scene) {
  const attention = attentionSettings(scene.attention);
  const nodeById = new Map(scene.nodes.map((node) => [node.id, node]));
  const orderedEdges = [...scene.edges].sort((left, right) => left.layer - right.layer || left.id.localeCompare(right.id));
  const orderedNodes = [...scene.nodes].sort((left, right) => left.z - right.z || left.id.localeCompare(right.id));

  const layerBands = [0, 1, 2, 3]
    .map((layer) => {
      const opacity = 0.04 + layer * 0.03 * depthScale(scene.depth);
      const y = 248 - layer * 20 * depthScale(scene.depth);
      return `<ellipse cx="250" cy="${y}" rx="170" ry="34" fill="#22d3ee" fill-opacity="${opacity.toFixed(3)}" />`;
    })
    .join("");

  const edgeMarkup = orderedEdges
    .map((edge) => {
      const dx = edge.x2 - edge.x1;
      const dy = edge.y2 - edge.y1;
      const length = Math.hypot(dx, dy) || 1;
      const nx = (-dy / length) * edge.offset;
      const ny = (dx / length) * edge.offset;
      const stroke = edge.active ? "#22d3ee" : "#57534e";
      const strokeWidth = edge.active ? 4 + depthScale(scene.depth) * 1.5 : 1.8 + edge.layer * 0.35;
      const labelX = ((edge.x1 + edge.x2) / 2 + nx).toFixed(3);
      const labelY = ((edge.y1 + edge.y2) / 2 + ny - 10 - edge.layer * 5 * depthScale(scene.depth)).toFixed(3);
      return `
        <line
          x1="${(edge.x1 + nx).toFixed(3)}"
          y1="${(edge.y1 + ny - edge.z1 * 0.08).toFixed(3)}"
          x2="${(edge.x2 + nx).toFixed(3)}"
          y2="${(edge.y2 + ny - edge.z2 * 0.08).toFixed(3)}"
          stroke="${stroke}"
          stroke-width="${strokeWidth.toFixed(3)}"
          stroke-opacity="${edge.active ? "1" : attention.edgeOpacity.toFixed(3)}"
        />
        <text x="${labelX}" y="${labelY}" fill="#cbd5e1" font-size="11" text-anchor="middle">${edge.predicate}</text>
      `;
    })
    .join("");

  const nodeMarkup = orderedNodes
    .map((node) => {
      const shadowDx = 10 * depthScale(scene.depth);
      const shadowDy = 10 * depthScale(scene.depth) + node.z * 0.12;
      const radius = node.active ? 23 : 18 + node.layer * 0.8 * depthScale(scene.depth);
      const stroke = node.highlight ? "#22d3ee" : "#a8a29e";
      const fill = node.active ? "#082f49" : "#111827";
      return `
        <g>
          <ellipse
            cx="${(node.x + shadowDx).toFixed(3)}"
            cy="${(node.y + shadowDy).toFixed(3)}"
            rx="${(radius * 1.02).toFixed(3)}"
            ry="${(radius * 0.56).toFixed(3)}"
            fill="#020617"
            fill-opacity="${attention.shadowOpacity.toFixed(3)}"
          />
          <circle
            cx="${node.x.toFixed(3)}"
            cy="${(node.y - node.z * 0.16).toFixed(3)}"
            r="${radius.toFixed(3)}"
            fill="${fill}"
            fill-opacity="${node.active ? "1" : attention.inactiveOpacity.toFixed(3)}"
            stroke="${stroke}"
            stroke-width="${node.active ? 3.2 : 2.1}"
          />
          <text
            x="${node.x.toFixed(3)}"
            y="${(node.y - node.z * 0.16 + 4).toFixed(3)}"
            fill="#f8fafc"
            font-size="11"
            text-anchor="middle"
          >${node.label}</text>
        </g>
      `;
    })
    .join("");

  const badgeText = `${scene.title} · step ${scene.step}`;
  return `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 340" role="img" aria-label="Narrative witness graph">
  <rect width="500" height="340" fill="#09090b" />
  <rect x="18" y="16" width="212" height="38" rx="10" fill="#111827" stroke="#22d3ee" stroke-opacity="0.4" />
  <text x="32" y="32" fill="#67e8f9" font-size="13">${scene.title}</text>
  <text x="32" y="48" fill="#a8a29e" font-size="11">${scene.subtitle}</text>
  <rect x="340" y="20" width="140" height="28" rx="8" fill="#111827" stroke="#f59e0b" stroke-opacity="0.5" />
  <text x="410" y="38" fill="#f8fafc" font-size="11" text-anchor="middle">${badgeText}</text>
  ${layerBands}
  ${edgeMarkup}
  ${nodeMarkup}
</svg>`.trim();
}
