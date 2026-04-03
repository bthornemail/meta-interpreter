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
  };
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

  const snapshot = {
    step: String(projection.step),
    digest: String(projection.digest),
    triplet: `[${projection.triplet.join(", ")}]`,
    order: `[${projection.order.join(", ")}]`,
    seq56: String(projection.seq56),
    layer: String(projection.layer),
    coords: `(${projection.coords.join(", ")})`,
    coeff: String(projection.coeff),
    canvas_data_url: canvas ? canvas.toDataURL() : null,
  };

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

  if (canvas) {
    paintCanvas(canvas, projection);
  }

  publishSnapshot(root, projection, canvas);

  return projection;
}
