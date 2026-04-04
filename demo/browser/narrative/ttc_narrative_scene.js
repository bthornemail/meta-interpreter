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

export function projectionHash(value) {
  const text = typeof value === "string" ? value : JSON.stringify(value);
  return `ph_${stableHash(text).toString(16).padStart(8, "0")}`;
}

function clamp01(value) {
  return Math.max(0, Math.min(1, value));
}

function lerp(start, end, t) {
  return start + (end - start) * t;
}

function mixHex(from, to, t) {
  const value = clamp01(t);
  const a = from.replace("#", "");
  const b = to.replace("#", "");
  const channels = [0, 2, 4].map((index) => {
    const start = parseInt(a.slice(index, index + 2), 16);
    const end = parseInt(b.slice(index, index + 2), 16);
    return Math.round(lerp(start, end, value))
      .toString(16)
      .padStart(2, "0");
  });
  return `#${channels.join("")}`;
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

export function frameBudgetForControls(controls) {
  const depthBonus = controls.depth === "more" ? 6 : 0;
  const attentionBonus = controls.attention === "expand" ? 4 : 0;
  return 6 + depthBonus + attentionBonus;
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
      active_weight: activeNodeIds.has(node.id) ? 1 : 0,
      highlight_weight: activeNodeIds.has(node.id) || stepRecord.witness.role.endsWith("law") && node.kind === "law" ? 1 : 0,
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
      active_weight: edge.id === stepRecord.template_edge_id ? 1 : 0,
      highlight_weight: edge.id === stepRecord.template_edge_id ? 1 : 0,
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

export function interpolateNarrativeScene(fromScene, toScene, t) {
  const progress = clamp01(t);
  const fromNodes = new Map(fromScene.nodes.map((node) => [node.id, node]));
  const fromEdges = new Map(fromScene.edges.map((edge) => [edge.id, edge]));

  const nodes = toScene.nodes.map((targetNode) => {
    const sourceNode = fromNodes.get(targetNode.id) || targetNode;
    return {
      ...targetNode,
      x: Number(lerp(sourceNode.x, targetNode.x, progress).toFixed(3)),
      y: Number(lerp(sourceNode.y, targetNode.y, progress).toFixed(3)),
      z: Number(lerp(sourceNode.z, targetNode.z, progress).toFixed(3)),
      layer: targetNode.layer,
      active_weight: Number(lerp(sourceNode.active ? 1 : 0, targetNode.active ? 1 : 0, progress).toFixed(3)),
      highlight_weight: Number(
        lerp(sourceNode.highlight ? 1 : 0, targetNode.highlight ? 1 : 0, progress).toFixed(3),
      ),
    };
  });

  const edges = toScene.edges.map((targetEdge) => {
    const sourceEdge = fromEdges.get(targetEdge.id) || targetEdge;
    return {
      ...targetEdge,
      offset: Number(lerp(sourceEdge.offset, targetEdge.offset, progress).toFixed(3)),
      x1: Number(lerp(sourceEdge.x1, targetEdge.x1, progress).toFixed(3)),
      y1: Number(lerp(sourceEdge.y1, targetEdge.y1, progress).toFixed(3)),
      x2: Number(lerp(sourceEdge.x2, targetEdge.x2, progress).toFixed(3)),
      y2: Number(lerp(sourceEdge.y2, targetEdge.y2, progress).toFixed(3)),
      z1: Number(lerp(sourceEdge.z1, targetEdge.z1, progress).toFixed(3)),
      z2: Number(lerp(sourceEdge.z2, targetEdge.z2, progress).toFixed(3)),
      active_weight: Number(lerp(sourceEdge.active ? 1 : 0, targetEdge.active ? 1 : 0, progress).toFixed(3)),
      highlight_weight: Number(
        lerp(sourceEdge.highlight ? 1 : 0, targetEdge.highlight ? 1 : 0, progress).toFixed(3),
      ),
    };
  });

  return {
    ...toScene,
    nodes,
    edges,
    interpolation: {
      from_scene_id: fromScene.scene_id,
      to_scene_id: toScene.scene_id,
      t: Number(progress.toFixed(3)),
    },
  };
}

export function renderNarrativeSceneSvg(scene) {
  const attention = attentionSettings(scene.attention);
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
      const activeWeight = edge.active_weight ?? (edge.active ? 1 : 0);
      const dx = edge.x2 - edge.x1;
      const dy = edge.y2 - edge.y1;
      const length = Math.hypot(dx, dy) || 1;
      const nx = (-dy / length) * edge.offset;
      const ny = (dx / length) * edge.offset;
      const stroke = mixHex("#57534e", "#22d3ee", activeWeight);
      const strokeWidth = lerp(1.8 + edge.layer * 0.35, 4 + depthScale(scene.depth) * 1.5, activeWeight);
      const strokeOpacity = lerp(attention.edgeOpacity, 1, activeWeight);
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
          stroke-opacity="${strokeOpacity.toFixed(3)}"
        />
        <text x="${labelX}" y="${labelY}" fill="#cbd5e1" font-size="11" text-anchor="middle">${edge.predicate}</text>
      `;
    })
    .join("");

  const nodeMarkup = orderedNodes
    .map((node) => {
      const activeWeight = node.active_weight ?? (node.active ? 1 : 0);
      const highlightWeight = node.highlight_weight ?? (node.highlight ? 1 : 0);
      const shadowDx = 10 * depthScale(scene.depth);
      const shadowDy = 10 * depthScale(scene.depth) + node.z * 0.12;
      const inactiveRadius = 18 + node.layer * 0.8 * depthScale(scene.depth);
      const radius = lerp(inactiveRadius, 23, activeWeight);
      const stroke = mixHex("#a8a29e", "#22d3ee", highlightWeight);
      const fill = mixHex("#111827", "#082f49", activeWeight);
      const fillOpacity = lerp(attention.inactiveOpacity, 1, activeWeight);
      const strokeWidth = lerp(2.1, 3.2, activeWeight);
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
            fill-opacity="${fillOpacity.toFixed(3)}"
            stroke="${stroke}"
            stroke-width="${strokeWidth.toFixed(3)}"
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

export function renderNarrativeSceneCanvas(canvas, scene) {
  const ctx = canvas.getContext("2d");
  if (!ctx) {
    return;
  }

  const attention = attentionSettings(scene.attention);
  const canvasWidth = canvas.width;
  const canvasHeight = canvas.height;
  const orderedEdges = [...scene.edges].sort((left, right) => left.layer - right.layer || left.id.localeCompare(right.id));
  const orderedNodes = [...scene.nodes].sort((left, right) => left.z - right.z || left.id.localeCompare(right.id));
  const scale = Math.min(canvasWidth / 500, canvasHeight / 340);

  ctx.save();
  ctx.clearRect(0, 0, canvasWidth, canvasHeight);
  ctx.scale(scale, scale);
  ctx.fillStyle = "#09090b";
  ctx.fillRect(0, 0, 500, 340);

  ctx.fillStyle = "#111827";
  ctx.strokeStyle = "rgba(34, 211, 238, 0.4)";
  ctx.lineWidth = 1.2;
  roundRect(ctx, 18, 16, 212, 38, 10);
  ctx.fill();
  ctx.stroke();

  ctx.fillStyle = "#67e8f9";
  ctx.font = "13px ui-sans-serif, system-ui, sans-serif";
  ctx.fillText(scene.title, 32, 32);
  ctx.fillStyle = "#a8a29e";
  ctx.font = "11px ui-sans-serif, system-ui, sans-serif";
  ctx.fillText(scene.subtitle, 32, 48);

  ctx.fillStyle = "#111827";
  ctx.strokeStyle = "rgba(245, 158, 11, 0.5)";
  roundRect(ctx, 340, 20, 140, 28, 8);
  ctx.fill();
  ctx.stroke();
  ctx.fillStyle = "#f8fafc";
  ctx.textAlign = "center";
  ctx.fillText(`${scene.title} · step ${scene.step}`, 410, 38);
  ctx.textAlign = "start";

  for (const layer of [0, 1, 2, 3]) {
    const opacity = 0.04 + layer * 0.03 * depthScale(scene.depth);
    const y = 248 - layer * 20 * depthScale(scene.depth);
    ctx.fillStyle = `rgba(34, 211, 238, ${opacity.toFixed(3)})`;
    ctx.beginPath();
    ctx.ellipse(250, y, 170, 34, 0, 0, Math.PI * 2);
    ctx.fill();
  }

  for (const edge of orderedEdges) {
    const activeWeight = edge.active_weight ?? (edge.active ? 1 : 0);
    const dx = edge.x2 - edge.x1;
    const dy = edge.y2 - edge.y1;
    const length = Math.hypot(dx, dy) || 1;
    const nx = (-dy / length) * edge.offset;
    const ny = (dx / length) * edge.offset;
    const strokeWidth = lerp(1.8 + edge.layer * 0.35, 4 + depthScale(scene.depth) * 1.5, activeWeight);
    const strokeOpacity = lerp(attention.edgeOpacity, 1, activeWeight);

    ctx.strokeStyle = hexToRgba(mixHex("#57534e", "#22d3ee", activeWeight), strokeOpacity);
    ctx.lineWidth = strokeWidth;
    ctx.beginPath();
    ctx.moveTo(edge.x1 + nx, edge.y1 + ny - edge.z1 * 0.08);
    ctx.lineTo(edge.x2 + nx, edge.y2 + ny - edge.z2 * 0.08);
    ctx.stroke();

    ctx.fillStyle = "#cbd5e1";
    ctx.font = "11px ui-sans-serif, system-ui, sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(
      edge.predicate,
      (edge.x1 + edge.x2) / 2 + nx,
      (edge.y1 + edge.y2) / 2 + ny - 10 - edge.layer * 5 * depthScale(scene.depth),
    );
  }

  for (const node of orderedNodes) {
    const activeWeight = node.active_weight ?? (node.active ? 1 : 0);
    const highlightWeight = node.highlight_weight ?? (node.highlight ? 1 : 0);
    const shadowDx = 10 * depthScale(scene.depth);
    const shadowDy = 10 * depthScale(scene.depth) + node.z * 0.12;
    const inactiveRadius = 18 + node.layer * 0.8 * depthScale(scene.depth);
    const radius = lerp(inactiveRadius, 23, activeWeight);
    const fillOpacity = lerp(attention.inactiveOpacity, 1, activeWeight);
    const strokeWidth = lerp(2.1, 3.2, activeWeight);

    ctx.fillStyle = hexToRgba("#020617", attention.shadowOpacity);
    ctx.beginPath();
    ctx.ellipse(node.x + shadowDx, node.y + shadowDy, radius * 1.02, radius * 0.56, 0, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = hexToRgba(mixHex("#111827", "#082f49", activeWeight), fillOpacity);
    ctx.strokeStyle = mixHex("#a8a29e", "#22d3ee", highlightWeight);
    ctx.lineWidth = strokeWidth;
    ctx.beginPath();
    ctx.arc(node.x, node.y - node.z * 0.16, radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = "#f8fafc";
    ctx.font = "11px ui-sans-serif, system-ui, sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(node.label, node.x, node.y - node.z * 0.16 + 4);
  }

  ctx.restore();
}

export function buildNarrativeAFrameScene(scene) {
  const attention = attentionSettings(scene.attention);
  const nodes = scene.nodes.map((node) => {
    const activeWeight = node.active_weight ?? (node.active ? 1 : 0);
    const highlightWeight = node.highlight_weight ?? (node.highlight ? 1 : 0);
    return {
      id: node.id,
      label: node.label,
      kind: node.kind,
      position: {
        x: Number(((node.x - 250) / 62).toFixed(3)),
        y: Number((0.25 + node.z / 72 + activeWeight * 0.18).toFixed(3)),
        z: Number(((node.y - 178) / 62).toFixed(3)),
      },
      radius: Number(lerp(0.22 + node.layer * 0.018, 0.3, activeWeight).toFixed(3)),
      color: mixHex("#111827", "#082f49", activeWeight),
      ring_color: mixHex("#a8a29e", "#22d3ee", highlightWeight),
      opacity: Number(lerp(attention.inactiveOpacity, 1, activeWeight).toFixed(3)),
      active: Boolean(node.active),
      highlight: Boolean(node.highlight),
    };
  });

  const nodeById = new Map(nodes.map((node) => [node.id, node]));
  const edges = scene.edges.map((edge) => {
    const activeWeight = edge.active_weight ?? (edge.active ? 1 : 0);
    return {
      id: edge.id,
      predicate: edge.predicate,
      subject: edge.subject,
      object: edge.object,
      start: nodeById.get(edge.subject)?.position,
      end: nodeById.get(edge.object)?.position,
      color: mixHex("#57534e", "#22d3ee", activeWeight),
      opacity: Number(lerp(attention.edgeOpacity, 1, activeWeight).toFixed(3)),
      active: Boolean(edge.active),
      highlight: Boolean(edge.highlight),
      label_position: {
        x: Number((((edge.x1 + edge.x2) / 2 - 250) / 62).toFixed(3)),
        y: Number((0.95 + Math.max(edge.z1, edge.z2) / 84 + (activeWeight * 0.12)).toFixed(3)),
        z: Number((((edge.y1 + edge.y2) / 2 - 178) / 62).toFixed(3)),
      },
    };
  });

  return {
    chapter_id: scene.chapter_id,
    step: scene.step,
    scene_id: scene.scene_id,
    template_id: scene.template_id,
    title: scene.title,
    subtitle: scene.subtitle,
    interpolation: scene.interpolation || null,
    active_transition: scene.active_transition,
    camera: { position: { x: 0, y: 3.2, z: 6.8 }, rotation: { x: -18, y: 0, z: 0 } },
    nodes,
    edges,
  };
}

export function renderNarrativeAFrameMarkup(aframeScene) {
  const nodeMarkup = aframeScene.nodes.map((node) => `
    <a-entity position="${node.position.x} ${node.position.y} ${node.position.z}">
      <a-sphere radius="${node.radius}" color="${node.color}" opacity="${node.opacity}"></a-sphere>
      <a-ring radius-inner="${(node.radius * 1.1).toFixed(3)}" radius-outer="${(node.radius * 1.18).toFixed(3)}" color="${node.ring_color}" rotation="-90 0 0" position="0 -0.02 0"></a-ring>
      <a-text value="${escapeAFrameText(node.label)}" color="#f8fafc" align="center" width="2.5" position="0 ${(node.radius + 0.22).toFixed(3)} 0"></a-text>
    </a-entity>
  `).join("");

  const edgeMarkup = aframeScene.edges.map((edge) => `
    <a-entity line="start: ${edge.start.x} ${edge.start.y} ${edge.start.z}; end: ${edge.end.x} ${edge.end.y} ${edge.end.z}; color: ${edge.color}; opacity: ${edge.opacity}"></a-entity>
    <a-text value="${escapeAFrameText(edge.predicate)}" color="#cbd5e1" align="center" width="3" position="${edge.label_position.x} ${edge.label_position.y} ${edge.label_position.z}"></a-text>
  `).join("");

  return `
    <a-scene embedded background="color: #09090b" renderer="colorManagement: true; antialias: true">
      <a-entity light="type: ambient; color: #94a3b8; intensity: 0.7"></a-entity>
      <a-entity light="type: directional; color: #67e8f9; intensity: 1.1" position="1.5 3.4 2.2"></a-entity>
      <a-plane color="#0f172a" opacity="0.85" rotation="-90 0 0" width="10" height="10" position="0 0 -0.15"></a-plane>
      <a-entity id="camera-rig" position="0 0 0">
        <a-camera position="${aframeScene.camera.position.x} ${aframeScene.camera.position.y} ${aframeScene.camera.position.z}" rotation="${aframeScene.camera.rotation.x} ${aframeScene.camera.rotation.y} ${aframeScene.camera.rotation.z}"></a-camera>
      </a-entity>
      <a-text value="${escapeAFrameText(aframeScene.title)}" color="#67e8f9" align="center" width="6" position="0 4.8 -1.2"></a-text>
      <a-text value="${escapeAFrameText(aframeScene.subtitle)}" color="#a8a29e" align="center" width="8" position="0 4.35 -1.2"></a-text>
      ${edgeMarkup}
      ${nodeMarkup}
    </a-scene>
  `.trim();
}

export function renderNarrativeAFrame(root, aframeScene) {
  root.innerHTML = renderNarrativeAFrameMarkup(aframeScene);
}

function hexToRgba(hex, alpha) {
  const normalized = hex.replace("#", "");
  const red = parseInt(normalized.slice(0, 2), 16);
  const green = parseInt(normalized.slice(2, 4), 16);
  const blue = parseInt(normalized.slice(4, 6), 16);
  return `rgba(${red}, ${green}, ${blue}, ${alpha})`;
}

function escapeAFrameText(value) {
  return String(value).replaceAll('"', "&quot;");
}

function roundRect(ctx, x, y, width, height, radius) {
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.lineTo(x + width - radius, y);
  ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
  ctx.lineTo(x + width, y + height - radius);
  ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
  ctx.lineTo(x + radius, y + height);
  ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
  ctx.lineTo(x, y + radius);
  ctx.quadraticCurveTo(x, y, x + radius, y);
  ctx.closePath();
}
