// The shared renderer is a projection consumer only.
// It may read and update projection-local DOM state, but it must not define
// schema, runtime logic, or transport semantics.
function findWithinRoot(root, selector) {
  return root.matches?.(selector) ? root : root.querySelector(selector);
}

function parseList(raw) {
  return String(raw || "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean)
    .map((value) => Number(value));
}

function parseJson(raw, fallback) {
  if (!raw) {
    return fallback;
  }
  try {
    return JSON.parse(raw);
  } catch {
    return fallback;
  }
}

function formatCarrierResolution(carrierResolution) {
  if (!carrierResolution) {
    return "n/a";
  }
  return JSON.stringify(carrierResolution);
}

function escapeXml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

function nodePosition(index) {
  const centerX = 260;
  const centerY = 126;
  const radius = 98;
  const angle = (-90 + index * (360 / 7)) * (Math.PI / 180);
  return {
    x: centerX + Math.cos(angle) * radius,
    y: centerY + Math.sin(angle) * radius,
  };
}

function createSurface(width, height) {
  const surface =
    typeof OffscreenCanvas !== "undefined" ? new OffscreenCanvas(width, height) : document.createElement("canvas");
  surface.width = width;
  surface.height = height;
  return surface;
}

function drawSeqStrip(ctx, seq56, color) {
  const columns = 8;
  const rows = 7;
  const cell = 18;
  const originX = 188;
  const originY = 262;
  const activeRow = Math.floor(seq56 / columns);
  const activeCol = seq56 % columns;

  ctx.fillStyle = "#0f172a";
  ctx.fillRect(originX - 10, originY - 10, columns * cell + 20, rows * cell + 20);

  for (let row = 0; row < rows; row += 1) {
    for (let col = 0; col < columns; col += 1) {
      const x = originX + col * cell;
      const y = originY + row * cell;
      ctx.fillStyle = row === activeRow && col === activeCol ? color : "#111827";
      ctx.fillRect(x, y, cell - 2, cell - 2);
    }
  }

  ctx.fillStyle = "#94a3b8";
  ctx.font = "12px ui-monospace, SFMono-Regular, monospace";
  ctx.fillText("seq56 strip", originX, originY - 18);
}

function writeDataset(stepEl, step) {
  if (!step) {
    return;
  }

  const resolvedStepIdentity = step.resolved_step_identity || {
    step: String(step.tick ?? step.step ?? 0),
    step_digest: String(step.step_digest ?? step.digest ?? 0),
    address: String(step.address_word ?? step.address ?? "0x0000"),
    lane: String(step.address_lane ?? 0),
    channel: String(step.address_channel ?? 0),
    slot: String(step.address_slot ?? 0),
  };
  const uiFrameResolution = step.ui_frame_resolution || {
    artifact_class: String(step.artifact_class || "claim"),
    workflow_mode: String(step.workflow_mode || "inspect"),
    step_identity: resolvedStepIdentity,
    frame_scope: {
      kind: String(step.frame_scope_kind || "point"),
      ...(step.frame_scope_ref || {}),
    },
  };
  const carrierResolution = step.carrier_resolution || null;

  stepEl.dataset.ttcStep = String(step.tick ?? step.step ?? 0);
  stepEl.dataset.ttcDigest = String(step.step_digest ?? step.digest ?? 0);
  stepEl.dataset.ttcTriplet = (step.triplet || []).join(",");
  stepEl.dataset.ttcOrder = (step.order || []).join(",");
  stepEl.dataset.ttcSeq56 = String(step.seq56 ?? 0);
  stepEl.dataset.ttcIncidenceLayer = String(step.incidence_layer ?? step.layer ?? 0);

  if (Array.isArray(step.incidence_coords)) {
    stepEl.dataset.ttcIncidenceCoords = step.incidence_coords.join(",");
  } else {
    stepEl.dataset.ttcIncidenceCoords = [
      step.incidence_x ?? step.x ?? 0,
      step.incidence_y ?? step.y ?? 0,
      step.incidence_z ?? step.z ?? 0,
    ].join(",");
  }

  stepEl.dataset.ttcIncidenceCoeff = String(step.incidence_coeff ?? step.coeff ?? 0);
  stepEl.dataset.ttcAddress = String(resolvedStepIdentity.address || "0x0000");
  stepEl.dataset.ttcAddressLane = String(resolvedStepIdentity.lane || 0);
  stepEl.dataset.ttcAddressChannel = String(resolvedStepIdentity.channel || 0);
  stepEl.dataset.ttcAddressSlot = String(resolvedStepIdentity.slot || 0);
  stepEl.dataset.ttcMaterialClass = String(step.material_class || "");
  stepEl.dataset.ttcStateClass = String(step.state_class || "");
  stepEl.dataset.ttcCarrierResolution = carrierResolution ? JSON.stringify(carrierResolution) : "";
  stepEl.dataset.ttcArtifactClass = String(uiFrameResolution.artifact_class || step.artifact_class || "claim");
  stepEl.dataset.ttcWorkflowMode = String(uiFrameResolution.workflow_mode || step.workflow_mode || "inspect");
  stepEl.dataset.ttcFrameScopeKind = String(
    uiFrameResolution.frame_scope?.kind || step.frame_scope_kind || "point"
  );
  stepEl.dataset.ttcFrameScopeRef = JSON.stringify(uiFrameResolution.frame_scope || step.frame_scope_ref || { kind: "point" });
  stepEl.dataset.ttcResolvedStepIdentity = JSON.stringify(resolvedStepIdentity);
  stepEl.dataset.ttcUiFrameResolution = JSON.stringify(uiFrameResolution);
}

function readProjection(stepEl) {
  return {
    step: Number(stepEl.dataset.ttcStep),
    digest: stepEl.dataset.ttcDigest,
    triplet: parseList(stepEl.dataset.ttcTriplet),
    order: parseList(stepEl.dataset.ttcOrder),
    seq56: Number(stepEl.dataset.ttcSeq56),
    layer: Number(stepEl.dataset.ttcIncidenceLayer),
    coords: parseList(stepEl.dataset.ttcIncidenceCoords),
    coeff: stepEl.dataset.ttcIncidenceCoeff,
    address: stepEl.dataset.ttcAddress || "0x0000",
    lane: stepEl.dataset.ttcAddressLane || "0",
    channel: stepEl.dataset.ttcAddressChannel || "0",
    slot: stepEl.dataset.ttcAddressSlot || "0",
    material_class: stepEl.dataset.ttcMaterialClass || null,
    state_class: stepEl.dataset.ttcStateClass || null,
    carrier_resolution: parseJson(stepEl.dataset.ttcCarrierResolution, null),
    artifact_class: stepEl.dataset.ttcArtifactClass || "claim",
    workflow_mode: stepEl.dataset.ttcWorkflowMode || "inspect",
    frame_scope_kind: stepEl.dataset.ttcFrameScopeKind || "point",
    frame_scope_ref: parseJson(stepEl.dataset.ttcFrameScopeRef, { kind: "point" }),
    resolved_step_identity: parseJson(stepEl.dataset.ttcResolvedStepIdentity, null),
    ui_frame_resolution: parseJson(stepEl.dataset.ttcUiFrameResolution, null),
  };
}

function resolveProjectionStepIdentity(projection) {
  if (projection.resolved_step_identity) {
    return projection.resolved_step_identity;
  }
  return {
    step: String(projection.step),
    step_digest: String(projection.digest),
    address: String(projection.address || "0x0000"),
    lane: String(projection.lane || "0"),
    channel: String(projection.channel || "0"),
    slot: String(projection.slot || "0"),
  };
}

function resolveProjectionWorkflow(projection) {
  if (projection.ui_frame_resolution?.workflow_mode) {
    return projection.ui_frame_resolution.workflow_mode;
  }
  switch (projection.artifact_class) {
    case "proposal":
      return "evaluate";
    case "closure":
      return "apply";
    case "receipt":
      return "verify";
    case "claim":
    default:
      return "inspect";
  }
}

function resolveProjectionUiFrame(projection) {
  if (projection.ui_frame_resolution) {
    return projection.ui_frame_resolution;
  }
  const scopeKind = projection.frame_scope_kind || "point";
  const baseScope = projection.frame_scope_ref || { kind: scopeKind };
  let frameScope = { ...baseScope, kind: baseScope.kind || scopeKind };
  if (frameScope.kind === "point" && !frameScope.point) {
    frameScope.point = `p${projection.triplet[0] ?? 0}`;
  }
  return {
    artifact_class: projection.artifact_class || "claim",
    workflow_mode: resolveProjectionWorkflow(projection),
    step_identity: resolveProjectionStepIdentity(projection),
    frame_scope: frameScope,
  };
}

function buildSeqCellsSvg(seq56, color) {
  const columns = 8;
  const rows = 7;
  const cell = 18;
  const originX = 188;
  const originY = 262;
  const activeRow = Math.floor(seq56 / columns);
  const activeCol = seq56 % columns;
  const cells = [`<rect x="${originX - 10}" y="${originY - 10}" width="${columns * cell + 20}" height="${rows * cell + 20}" fill="#0f172a" />`];

  for (let row = 0; row < rows; row += 1) {
    for (let col = 0; col < columns; col += 1) {
      const x = originX + col * cell;
      const y = originY + row * cell;
      const fill = row === activeRow && col === activeCol ? color : "#111827";
      cells.push(`<rect x="${x}" y="${y}" width="${cell - 2}" height="${cell - 2}" fill="${fill}" />`);
    }
  }

  cells.push(
    `<text x="${originX}" y="${originY - 18}" fill="#94a3b8" font-family="ui-monospace, SFMono-Regular, monospace" font-size="12">seq56 strip</text>`
  );
  return cells.join("");
}

function updatePanel(root, selector, value) {
  const el = root.querySelector(selector);
  if (el) {
    el.textContent = value;
  }
}

function publishSnapshot(root, projection, canvas) {
  let snapshotEl = root.querySelector("#ttc-projection-snapshot");
  if (!snapshotEl) {
    snapshotEl = document.createElement("script");
    snapshotEl.id = "ttc-projection-snapshot";
    snapshotEl.type = "application/json";
    root.appendChild(snapshotEl);
  }

  const resolvedStepIdentity = resolveProjectionStepIdentity(projection);
  const uiFrameResolution = resolveProjectionUiFrame(projection);
  const snapshot = {
    step: String(projection.step),
    digest: String(projection.digest),
    triplet: `[${projection.triplet.join(", ")}]`,
    order: `[${projection.order.join(", ")}]`,
    seq56: String(projection.seq56),
    layer: String(projection.layer),
    coords: `(${projection.coords.join(", ")})`,
    coeff: String(projection.coeff),
    material_class: projection.material_class,
    state_class: projection.state_class,
    carrier_resolution: projection.carrier_resolution,
    resolved_step_identity: resolvedStepIdentity,
    artifact_class: uiFrameResolution.artifact_class,
    workflow_mode: uiFrameResolution.workflow_mode,
    frame_scope_kind: uiFrameResolution.frame_scope?.kind || projection.frame_scope_kind || "point",
    frame_scope_ref: uiFrameResolution.frame_scope || projection.frame_scope_ref || { kind: "point" },
    ui_frame_resolution: uiFrameResolution,
    canvas_data_url: canvas ? canvas.toDataURL() : null,
  };

  const svgMarkup = renderTtcProjectionSvg(projection);
  snapshot.svg_markup = svgMarkup;
  snapshot.svg_digest_present = svgMarkup.includes(String(projection.digest));

  snapshotEl.textContent = JSON.stringify(snapshot);
}

function paintCanvas(canvas, projection) {
  const visibleCtx = canvas.getContext("2d");
  const surface = createSurface(canvas.width, canvas.height);
  const ctx = surface.getContext("2d");
  const highlightColor = "#38bdf8";
  const orderColors = ["#34d399", "#38bdf8", "#f472b6"];

  ctx.clearRect(0, 0, surface.width, surface.height);
  ctx.fillStyle = "#020617";
  ctx.fillRect(0, 0, surface.width, surface.height);

  ctx.strokeStyle = "#1f2937";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.arc(260, 126, 110, 0, Math.PI * 2);
  ctx.stroke();

  ctx.fillStyle = "#64748b";
  ctx.font = "12px ui-monospace, SFMono-Regular, monospace";
  ctx.fillText(`step ${projection.step}`, 24, 28);
  ctx.fillText(`digest ${projection.digest}`, 24, 48);
  ctx.fillText(
    `layer ${projection.layer} coords (${projection.coords.join(",")}) coeff ${projection.coeff}`,
    24,
    68
  );

  projection.triplet.forEach((value) => {
    const pos = nodePosition(value);
    ctx.beginPath();
    ctx.fillStyle = "#1e293b";
    ctx.arc(pos.x, pos.y, 18, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = "#475569";
    ctx.stroke();
    ctx.fillStyle = "#cbd5e1";
    ctx.font = "14px ui-monospace, SFMono-Regular, monospace";
    ctx.fillText(String(value), pos.x - 4, pos.y + 4);
  });

  projection.order.forEach((value, index) => {
    const pos = nodePosition(value);
    ctx.beginPath();
    ctx.fillStyle = orderColors[index] || highlightColor;
    ctx.arc(pos.x, pos.y, 10, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#020617";
    ctx.font = "11px ui-monospace, SFMono-Regular, monospace";
    ctx.fillText(String(index + 1), pos.x - 3, pos.y + 4);
  });

  drawSeqStrip(ctx, projection.seq56, highlightColor);

  if (surface instanceof OffscreenCanvas && visibleCtx.transferFromImageBitmap) {
    const bitmap = surface.transferToImageBitmap();
    visibleCtx.transferFromImageBitmap(bitmap);
    bitmap.close?.();
  } else {
    visibleCtx.clearRect(0, 0, canvas.width, canvas.height);
    visibleCtx.drawImage(surface, 0, 0);
  }
}

export function readTtcProjection(stepEl) {
  return readProjection(stepEl);
}

export function resolveTtcProjectionStepIdentity(stepEl) {
  return resolveProjectionStepIdentity(readProjection(stepEl));
}

export function resolveTtcProjectionUiFrame(stepEl) {
  return resolveProjectionUiFrame(readProjection(stepEl));
}

export function renderTtcProjectionSvg(projection) {
  const highlightColor = "#38bdf8";
  const orderColors = ["#34d399", "#38bdf8", "#f472b6"];

  const tripletNodes = projection.triplet
    .map((value) => {
      const pos = nodePosition(value);
      return `
        <circle cx="${pos.x}" cy="${pos.y}" r="18" fill="#1e293b" stroke="#475569" stroke-width="2" />
        <text x="${pos.x}" y="${pos.y + 5}" fill="#cbd5e1" font-family="ui-monospace, SFMono-Regular, monospace" font-size="14" text-anchor="middle">${escapeXml(value)}</text>
      `;
    })
    .join("");

  const orderNodes = projection.order
    .map((value, index) => {
      const pos = nodePosition(value);
      return `
        <circle cx="${pos.x}" cy="${pos.y}" r="10" fill="${orderColors[index] || highlightColor}" />
        <text x="${pos.x}" y="${pos.y + 4}" fill="#020617" font-family="ui-monospace, SFMono-Regular, monospace" font-size="11" text-anchor="middle">${index + 1}</text>
      `;
    })
    .join("");

  return `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 520 360" role="img" aria-label="TTC projection witness">
  <rect width="520" height="360" fill="#020617" />
  <circle cx="260" cy="126" r="110" fill="none" stroke="#1f2937" stroke-width="2" />
  <text x="24" y="28" fill="#64748b" font-family="ui-monospace, SFMono-Regular, monospace" font-size="12">step ${escapeXml(projection.step)}</text>
  <text x="24" y="48" fill="#64748b" font-family="ui-monospace, SFMono-Regular, monospace" font-size="12">digest ${escapeXml(projection.digest)}</text>
  <text x="24" y="68" fill="#64748b" font-family="ui-monospace, SFMono-Regular, monospace" font-size="12">layer ${escapeXml(projection.layer)} coords (${escapeXml(projection.coords.join(","))}) coeff ${escapeXml(projection.coeff)}</text>
  ${tripletNodes}
  ${orderNodes}
  ${buildSeqCellsSvg(projection.seq56, highlightColor)}
</svg>`.trim();
}

export function renderTtcProjection(stepEl, step) {
  const root = stepEl.closest("[data-ttc-root]") || document;
  const canvas = findWithinRoot(root, '[data-ttc-surface="matrix"]');

  writeDataset(stepEl, step);

  const projection = readProjection(stepEl);
  updatePanel(root, "#panel-step", String(projection.step));
  updatePanel(root, "#panel-digest", projection.digest);
  updatePanel(root, "#panel-triplet", `[${projection.triplet.join(", ")}]`);
  updatePanel(root, "#panel-order", `[${projection.order.join(", ")}]`);
  updatePanel(root, "#panel-seq56", String(projection.seq56));
  updatePanel(root, "#panel-layer", String(projection.layer));
  updatePanel(root, "#panel-coords", `(${projection.coords.join(", ")})`);
  updatePanel(root, "#panel-coeff", String(projection.coeff));
  updatePanel(root, "#panel-seq56-badge", `seq56 ${projection.seq56}`);
  updatePanel(root, "#panel-material-class", projection.material_class || "n/a");
  updatePanel(root, "#panel-state-class", projection.state_class || "n/a");
  updatePanel(root, "#panel-carrier-resolution", formatCarrierResolution(projection.carrier_resolution));
  const uiFrameResolution = resolveProjectionUiFrame(projection);
  updatePanel(root, "#panel-artifact-class", uiFrameResolution.artifact_class);
  updatePanel(root, "#panel-workflow-mode", uiFrameResolution.workflow_mode);
  updatePanel(
    root,
    "#panel-frame-scope",
    JSON.stringify(uiFrameResolution.frame_scope)
  );

  if (canvas) {
    paintCanvas(canvas, projection);
  }

  const svgHost = findWithinRoot(root, '[data-ttc-surface="svg"]');
  if (svgHost) {
    svgHost.innerHTML = renderTtcProjectionSvg(projection);
  }

  publishSnapshot(root, projection, canvas);

  return projection;
}
