// MediaCapabilities selects projection/playback suitability, not canonical computation.
// MediaSource is a timed media projection/transport adapter, not a schema or runtime authority.
// Media Session is a platform control surface only.
// Capture constraints may tune device-facing behavior, but they must not influence runtime law.

const PLAYBACK_PROFILES = [
  {
    name: "high",
    mediaRecorderMime: 'video/webm;codecs=vp8,opus',
    sourceBufferMime: 'video/webm;codecs="vp8,opus"',
    frameRate: 12,
    video: {
      contentType: 'video/webm;codecs="vp8"',
      width: 520,
      height: 360,
      bitrate: 900000,
      framerate: 12,
    },
    audio: {
      contentType: 'audio/webm;codecs="opus"',
      channels: 2,
      bitrate: 128000,
      samplerate: 48000,
    },
  },
  {
    name: "fallback",
    mediaRecorderMime: 'video/webm;codecs=vp8,opus',
    sourceBufferMime: 'video/webm;codecs="vp8,opus"',
    frameRate: 8,
    video: {
      contentType: 'video/webm;codecs="vp8"',
      width: 520,
      height: 360,
      bitrate: 420000,
      framerate: 8,
    },
    audio: {
      contentType: 'audio/webm;codecs="opus"',
      channels: 1,
      bitrate: 64000,
      samplerate: 44100,
    },
  },
];

function safeJson(value) {
  return JSON.stringify(value, null, 2);
}

function ensureArray(value) {
  return Array.isArray(value) ? value : [];
}

async function waitForEvent(target, eventName) {
  await new Promise((resolve) => {
    target.addEventListener(eventName, resolve, { once: true });
  });
}

export async function choosePlaybackProfile() {
  const result = {
    profile: "unsupported",
    supported: false,
    smooth: false,
    powerEfficient: false,
    reason: "MSE or MediaRecorder unavailable",
    config: null,
  };

  if (typeof window.MediaSource === "undefined" || typeof window.MediaRecorder === "undefined") {
    return result;
  }

  for (const profile of PLAYBACK_PROFILES) {
    const sourceOk = window.MediaSource.isTypeSupported(profile.sourceBufferMime);
    const recorderOk = window.MediaRecorder.isTypeSupported?.(profile.mediaRecorderMime) ?? false;
    if (!sourceOk || !recorderOk) {
      continue;
    }

    let capability = { supported: true, smooth: profile.name === "fallback", powerEfficient: profile.name === "fallback" };
    if (navigator.mediaCapabilities?.decodingInfo) {
      try {
        capability = await navigator.mediaCapabilities.decodingInfo({
          type: "media-source",
          video: profile.video,
          audio: profile.audio,
        });
      } catch (error) {
        capability = { supported: true, smooth: false, powerEfficient: false, error: error.message };
      }
    }

    if (!capability.supported) {
      continue;
    }

    if (profile.name === "high" && !(capability.smooth && capability.powerEfficient)) {
      continue;
    }

    return {
      profile: profile.name,
      supported: true,
      smooth: Boolean(capability.smooth),
      powerEfficient: Boolean(capability.powerEfficient),
      reason: "usable",
      config: profile,
    };
  }

  const fallback = PLAYBACK_PROFILES.find(
    (profile) =>
      window.MediaSource.isTypeSupported(profile.sourceBufferMime) &&
      (window.MediaRecorder.isTypeSupported?.(profile.mediaRecorderMime) ?? false)
  );

  if (fallback) {
    return {
      profile: "fallback",
      supported: true,
      smooth: false,
      powerEfficient: false,
      reason: "fallback profile selected",
      config: fallback,
    };
  }

  return result;
}

export class TtcMediaAdapter {
  constructor({ videoEl, statusEl, onStateChange = () => {} }) {
    this.videoEl = videoEl;
    this.statusEl = statusEl;
    this.onStateChange = onStateChange;
    this.profileInfo = {
      profile: "unsupported",
      supported: false,
      smooth: false,
      powerEfficient: false,
      reason: "not started",
      config: null,
    };
    this.lastProjection = null;
    this.mediaSource = null;
    this.sourceBuffer = null;
    this.sourceOpenPromise = null;
    this.objectUrl = null;
    this.queue = [];
    this.recorder = null;
    this.canvasStream = null;
    this.audioContext = null;
    this.audioDestination = null;
    this.mixedStream = null;
    this.mseActive = false;
    this.mseStartedOnce = false;
    this.sessionInstalled = false;
    this.videoEl.muted = true;
    this.videoEl.autoplay = true;
    this.videoEl.playsInline = true;
    this.videoEl.controls = true;
  }

  snapshot() {
    return {
      profile: this.profileInfo.profile,
      supported: this.profileInfo.supported,
      smooth: this.profileInfo.smooth,
      powerEfficient: this.profileInfo.powerEfficient,
      reason: this.profileInfo.reason,
      mediaSourceSupported: typeof window.MediaSource !== "undefined",
      mediaSessionAvailable: typeof navigator.mediaSession !== "undefined",
      mediaSessionInstalled: this.sessionInstalled,
      mseActive: this.mseActive,
      mseStartedOnce: this.mseStartedOnce,
    };
  }

  async start(sourceCanvas, initialProjection = null) {
    await this.dispose();
    this.profileInfo = await choosePlaybackProfile();
    this.publishState();

    if (!this.profileInfo.supported || !this.profileInfo.config) {
      this.statusEl.textContent = `Timed media unavailable: ${this.profileInfo.reason}. Canvas remains authoritative downstream surface.`;
      return this.snapshot();
    }

    this.statusEl.textContent = `Starting ${this.profileInfo.profile} timed media surface…`;

    this.canvasStream = sourceCanvas.captureStream(this.profileInfo.config.frameRate);
    this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
    this.audioDestination = this.audioContext.createMediaStreamDestination();
    this.mixedStream = new MediaStream([
      ...ensureArray(this.canvasStream.getVideoTracks()),
      ...ensureArray(this.audioDestination.stream.getAudioTracks()),
    ]);

    this.mediaSource = new MediaSource();
    this.objectUrl = URL.createObjectURL(this.mediaSource);
    this.videoEl.src = this.objectUrl;
    this.sourceOpenPromise = waitForEvent(this.mediaSource, "sourceopen").then(() => {
      this.sourceBuffer = this.mediaSource.addSourceBuffer(this.profileInfo.config.sourceBufferMime);
      this.sourceBuffer.mode = "sequence";
      this.sourceBuffer.addEventListener("updateend", () => this.appendNextChunk());
    });
    await this.sourceOpenPromise;

    this.recorder = new MediaRecorder(this.mixedStream, {
      mimeType: this.profileInfo.config.mediaRecorderMime,
      videoBitsPerSecond: this.profileInfo.config.video.bitrate,
      audioBitsPerSecond: this.profileInfo.config.audio.bitrate,
    });
    this.recorder.addEventListener("dataavailable", async (event) => {
      if (!event.data || event.data.size === 0) {
        return;
      }
      const chunk = await event.data.arrayBuffer();
      this.queue.push(chunk);
      this.appendNextChunk();
    });
    this.recorder.addEventListener("stop", () => {
      this.mseActive = false;
      this.finishStream();
      this.publishState();
    });

    this.recorder.start(500);
    this.mseActive = true;
    this.mseStartedOnce = true;

    if (initialProjection) {
      this.handleProjection(initialProjection);
    }
    this.installMediaSession(initialProjection);

    try {
      await this.videoEl.play();
    } catch (_error) {
      // Autoplay may be blocked. The controls remain available.
    }

    this.statusEl.textContent = `Timed media active (${this.profileInfo.profile}).`;
    this.publishState();
    return this.snapshot();
  }

  appendNextChunk() {
    if (!this.sourceBuffer || this.sourceBuffer.updating || this.queue.length === 0) {
      return;
    }
    const next = this.queue.shift();
    this.sourceBuffer.appendBuffer(next);
  }

  finishStream() {
    const endWhenReady = () => {
      if (!this.mediaSource || this.mediaSource.readyState !== "open") {
        return;
      }
      if (this.sourceBuffer?.updating || this.queue.length > 0) {
        setTimeout(endWhenReady, 50);
        return;
      }
      try {
        this.mediaSource.endOfStream();
      } catch (_error) {
        // ignore
      }
    };
    endWhenReady();
  }

  handleProjection(projection) {
    this.lastProjection = projection;
    if (this.audioContext?.state === "suspended") {
      this.audioContext.resume().catch(() => {});
    }
    this.playStepTone(projection);
    this.updateMediaSession(projection);
    this.publishState();
  }

  playStepTone(projection) {
    if (!this.audioContext || !this.audioDestination) {
      return;
    }
    const oscillator = this.audioContext.createOscillator();
    const gain = this.audioContext.createGain();
    const now = this.audioContext.currentTime;
    const frequency = 180 + projection.seq56 * 6 + projection.layer * 4 + projection.triplet.reduce((sum, value) => sum + value, 0);

    oscillator.type = "triangle";
    oscillator.frequency.setValueAtTime(frequency, now);
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(0.08, now + 0.02);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.22);
    oscillator.connect(gain);
    gain.connect(this.audioDestination);
    oscillator.start(now);
    oscillator.stop(now + 0.24);
  }

  installMediaSession(initialProjection) {
    if (!navigator.mediaSession) {
      this.sessionInstalled = false;
      this.publishState();
      return;
    }

    navigator.mediaSession.setActionHandler("play", async () => {
      try {
        if (this.videoEl.paused) {
          await this.videoEl.play();
        }
        if (this.recorder?.state === "paused") {
          this.recorder.resume();
        }
      } catch (_error) {
        // ignore
      }
      navigator.mediaSession.playbackState = "playing";
      this.publishState();
    });

    navigator.mediaSession.setActionHandler("pause", () => {
      this.pause();
    });

    this.sessionInstalled = true;
    this.updateMediaSession(initialProjection);
    this.publishState();
  }

  updateMediaSession(projection) {
    if (!navigator.mediaSession) {
      return;
    }
    const current = projection || this.lastProjection;
    navigator.mediaSession.metadata = new MediaMetadata({
      title: current ? `TTC Step ${current.step}` : "TTC Timed Media Surface",
      artist: current ? `digest ${current.digest}` : "TTC",
      album: current
        ? `triplet ${current.triplet.join(",")} / seq56 ${current.seq56}`
        : "Timed media projection",
    });
    navigator.mediaSession.playbackState = this.videoEl.paused ? "paused" : "playing";
  }

  pause() {
    if (this.videoEl) {
      this.videoEl.pause();
    }
    if (this.recorder?.state === "recording") {
      this.recorder.pause();
    }
    if (navigator.mediaSession) {
      navigator.mediaSession.playbackState = "paused";
    }
    this.statusEl.textContent = "Timed media paused.";
    this.publishState();
  }

  async disconnect() {
    if (this.recorder && this.recorder.state !== "inactive") {
      this.recorder.stop();
    }
    if (this.canvasStream) {
      this.canvasStream.getTracks().forEach((track) => track.stop());
    }
    if (this.mixedStream) {
      this.mixedStream.getTracks().forEach((track) => track.stop());
    }
    if (this.audioContext) {
      await this.audioContext.close().catch(() => {});
    }
    if (this.videoEl) {
      this.videoEl.pause();
      this.videoEl.removeAttribute("src");
      this.videoEl.load();
    }
    if (this.objectUrl) {
      URL.revokeObjectURL(this.objectUrl);
    }
    this.mediaSource = null;
    this.sourceBuffer = null;
    this.sourceOpenPromise = null;
    this.objectUrl = null;
    this.queue = [];
    this.recorder = null;
    this.canvasStream = null;
    this.audioContext = null;
    this.audioDestination = null;
    this.mixedStream = null;
    this.mseActive = false;
    this.mseStartedOnce = false;
    if (navigator.mediaSession) {
      navigator.mediaSession.playbackState = "none";
      navigator.mediaSession.metadata = null;
    }
    this.publishState();
  }

  async dispose() {
    await this.disconnect();
    this.statusEl.textContent = "Timed media disconnected.";
  }

  publishState() {
    this.onStateChange(this.snapshot());
  }
}

export class TtcCaptureProbe {
  constructor({ onStateChange = () => {}, statusEl = null }) {
    this.onStateChange = onStateChange;
    this.statusEl = statusEl;
    this.stream = null;
    this.supportedConstraints = {};
    this.trackSnapshots = [];
  }

  snapshot() {
    return {
      supportedConstraints: this.supportedConstraints,
      supportedConstraintCount: Object.keys(this.supportedConstraints).length,
      tracks: this.trackSnapshots,
    };
  }

  publishState() {
    this.onStateChange(this.snapshot());
  }

  probeSupportedConstraints() {
    this.supportedConstraints = navigator.mediaDevices?.getSupportedConstraints?.() ?? {};
    if (this.statusEl) {
      this.statusEl.textContent = `Supported constraints: ${Object.keys(this.supportedConstraints).length}`;
    }
    this.publishState();
    return this.snapshot();
  }

  async requestTrackProbe() {
    if (!navigator.mediaDevices?.getUserMedia) {
      if (this.statusEl) {
        this.statusEl.textContent = "getUserMedia unavailable.";
      }
      this.publishState();
      return this.snapshot();
    }

    await this.stop();
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
      this.trackSnapshots = this.stream.getTracks().map((track) => ({
        kind: track.kind,
        label: track.label,
        capabilities: track.getCapabilities?.() ?? {},
        settings: track.getSettings?.() ?? {},
        constraints: track.getConstraints?.() ?? {},
      }));
      if (this.statusEl) {
        this.statusEl.textContent = `Track probe active: ${this.trackSnapshots.length} track(s).`;
      }
    } catch (error) {
      this.trackSnapshots = [];
      if (this.statusEl) {
        this.statusEl.textContent = `Track probe unavailable: ${error.name || "Error"}.`;
      }
    }
    this.publishState();
    return this.snapshot();
  }

  async stop() {
    if (this.stream) {
      this.stream.getTracks().forEach((track) => track.stop());
      this.stream = null;
    }
    this.trackSnapshots = [];
    this.publishState();
  }
}
