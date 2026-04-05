#!/usr/bin/env node

import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawn } from 'node:child_process';
import process from 'node:process';

const chromeBin =
  process.env.CHROME_BIN ??
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const baseUrl = process.env.SCREENSHOT_BASE_URL ?? 'http://127.0.0.1:8123';
const outputDir = process.env.SCREENSHOT_OUTPUT_DIR;
const planFile = process.env.SCREENSHOT_PLAN_FILE;

if (!outputDir) {
  throw new Error('SCREENSHOT_OUTPUT_DIR is required');
}

if (!planFile) {
  throw new Error('SCREENSHOT_PLAN_FILE is required');
}

const plan = JSON.parse(readFileSync(planFile, 'utf8'));
const slides = plan.slides.map((slide, index) => ({
  route: slide.route,
  fileName: `${String(index + 1).padStart(2, '0')}-${slugify(slide.route)}.png`,
}));

const chromePort = 9222;
const viewport = { width: 1512, height: 982 };
const userDataDir = mkdtempSync(join(tmpdir(), 'presentation-agent-chrome-'));

const chrome = spawn(
  chromeBin,
  [
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    `--remote-debugging-port=${chromePort}`,
    `--window-size=${viewport.width},${viewport.height}`,
    `--user-data-dir=${userDataDir}`,
    'about:blank',
  ],
  {
    stdio: 'ignore',
  },
);

try {
  await waitForDebugger(chromePort);

  for (const slide of slides) {
    const pageTarget = await createTarget(
      chromePort,
      `${baseUrl}/?slide=${encodeURIComponent(slide.route)}`,
    );
    const client = await connectClient(pageTarget.webSocketDebuggerUrl);
    try {
      await client.send('Page.enable');
      await client.send('Runtime.enable');
      await client.send('Emulation.setDeviceMetricsOverride', {
        width: viewport.width,
        height: viewport.height,
        deviceScaleFactor: 1,
        mobile: false,
      });
      await client.send('Page.navigate', {
        url: `${baseUrl}/?slide=${encodeURIComponent(slide.route)}`,
      });
      await client.waitFor('Page.loadEventFired');
      await delay(4500);
      await waitForFlutterReady(client);
      await delay(1000);
      const screenshot = await client.send('Page.captureScreenshot', {
        format: 'png',
        fromSurface: true,
      });
      writeFileSync(join(outputDir, slide.fileName), Buffer.from(screenshot.data, 'base64'));
    } finally {
      client.close();
      await fetch(`http://127.0.0.1:${chromePort}/json/close/${pageTarget.id}`);
    }
  }
} finally {
  chrome.kill('SIGTERM');
  await onceProcessExit(chrome);
  rmSync(userDataDir, { recursive: true, force: true });
}

async function waitForDebugger(port) {
  const deadline = Date.now() + 15000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`http://127.0.0.1:${port}/json/version`);
      if (response.ok) {
        return;
      }
    } catch {}
    await delay(200);
  }
  throw new Error(`Chrome DevTools endpoint did not start on port ${port}`);
}

async function createTarget(port, url) {
  const response = await fetch(`http://127.0.0.1:${port}/json/new?${encodeURIComponent(url)}`, {
    method: 'PUT',
  });
  if (!response.ok) {
    throw new Error(`Failed to create target for ${url}: ${response.status}`);
  }
  return response.json();
}

async function connectClient(webSocketDebuggerUrl) {
  const socket = new WebSocket(webSocketDebuggerUrl);
  const pending = new Map();
  const events = new Map();
  let nextId = 0;

  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true });
    socket.addEventListener('error', reject, { once: true });
  });

  socket.addEventListener('message', (event) => {
    const payload = JSON.parse(event.data);

    if (payload.id != null) {
      const entry = pending.get(payload.id);
      if (!entry) {
        return;
      }
      pending.delete(payload.id);
      if (payload.error) {
        entry.reject(new Error(payload.error.message));
        return;
      }
      entry.resolve(payload.result ?? {});
      return;
    }

    const queue = events.get(payload.method) ?? [];
    queue.push(payload.params ?? {});
    events.set(payload.method, queue);
  });

  return {
    async send(method, params = {}) {
      const id = ++nextId;
      const message = { id, method, params };
      const promise = new Promise((resolve, reject) => {
        pending.set(id, { resolve, reject });
      });
      socket.send(JSON.stringify(message));
      return promise;
    },
    async waitFor(method) {
      const deadline = Date.now() + 15000;
      while (Date.now() < deadline) {
        const queue = events.get(method);
        if (queue && queue.length > 0) {
          return queue.shift();
        }
        await delay(100);
      }
      throw new Error(`Timed out waiting for event ${method}`);
    },
    close() {
      socket.close();
    },
  };
}

async function waitForFlutterReady(client) {
  const deadline = Date.now() + 20000;
  while (Date.now() < deadline) {
    const result = await client.send('Runtime.evaluate', {
      expression: `(() => {
        const root = document.querySelector('canvas, flutter-view, flt-glass-pane');
        const rect = root && root.getBoundingClientRect ? root.getBoundingClientRect() : { width: 0, height: 0 };
        const hasCanvas = !!document.querySelector('canvas');
        const hasBodyChildren = !!document.body && document.body.children.length > 0;
        return (rect.width > 0 && rect.height > 0) || hasCanvas || hasBodyChildren;
      })()`,
      returnByValue: true,
    });

    if (result?.result?.value === true) {
      return;
    }
    await delay(250);
  }
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function onceProcessExit(child) {
  return new Promise((resolve) => {
    if (child.exitCode !== null) {
      resolve();
      return;
    }
    child.once('exit', () => resolve());
    setTimeout(resolve, 1000);
  });
}

function slugify(route) {
  return route.replaceAll('/', '').replace(/[^a-z0-9_-]/gi, '-') || 'slide';
}
