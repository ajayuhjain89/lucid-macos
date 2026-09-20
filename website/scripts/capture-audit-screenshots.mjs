import { spawn } from "child_process";
import fs from "fs";
import path from "path";

const CHROME_PATH = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const PORT = 9222;
const AUDIT_DIR = path.resolve(process.cwd(), ".audit");

if (!fs.existsSync(AUDIT_DIR)) {
  fs.mkdirSync(AUDIT_DIR, { recursive: true });
}

// Helper to send CDP command over WebSocket
function createCDPClient(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 1;
  const callbacks = new Map();

  ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    if (data.id && callbacks.has(data.id)) {
      const cb = callbacks.get(data.id);
      callbacks.delete(data.id);
      if (data.error) cb.reject(new Error(data.error.message));
      else cb.resolve(data.result);
    }
  };

  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const currentId = id++;
      callbacks.set(currentId, { resolve, reject });
      ws.send(JSON.stringify({ id: currentId, method, params }));
    });

  const ready = new Promise((resolve, reject) => {
    ws.onopen = () => resolve();
    ws.onerror = (err) => reject(err);
  });

  return { send, ready, close: () => ws.close() };
}

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function capture() {
  console.log("==> Launching Chrome headless on port " + PORT);
  const chromeProc = spawn(
    CHROME_PATH,
    [
      "--headless=new",
      `--remote-debugging-port=${PORT}`,
      "--disable-gpu",
      "--no-sandbox",
      "--disable-dev-shm-usage",
      "--hide-scrollbars",
      "about:blank",
    ],
    { stdio: "ignore" }
  );

  await sleep(1500);

  try {
    const versionRes = await fetch(`http://127.0.0.1:${PORT}/json/version`);
    const versionData = await versionRes.json();
    const browserWs = versionData.webSocketDebuggerUrl;

    const browser = createCDPClient(browserWs);
    await browser.ready;

    const targets = [
      { name: "1440px-dark", width: 1440, height: 900, dark: true, fullPage: true },
      { name: "1440px-light", width: 1440, height: 900, dark: false, fullPage: true },
      { name: "375px-dark", width: 375, height: 812, dark: true, fullPage: true },
      { name: "375px-light", width: 375, height: 812, dark: false, fullPage: true },
      { name: "320px-dark", width: 320, height: 568, dark: true, fullPage: true },
      { name: "430px-dark", width: 430, height: 932, dark: true, fullPage: true },
      { name: "768px-dark", width: 768, height: 1024, dark: true, fullPage: true },
      { name: "1024px-dark", width: 1024, height: 768, dark: true, fullPage: true },
      { name: "1280px-dark", width: 1280, height: 800, dark: true, fullPage: true },
      { name: "1728px-dark", width: 1728, height: 1117, dark: true, fullPage: true },
    ];

    for (const t of targets) {
      console.log(`Capturing: ${t.name} (${t.width}x${t.height}, dark: ${t.dark})...`);
      const newTarget = await browser.send("Target.createTarget", { url: "about:blank" });
      const targetId = newTarget.targetId;
      const targetWs = `ws://127.0.0.1:${PORT}/devtools/page/${targetId}`;

      const page = createCDPClient(targetWs);
      await page.ready;

      await page.send("Page.enable");
      await page.send("DOM.enable");
      await page.send("CSS.enable");

      await page.send("Emulation.setDeviceMetricsOverride", {
        width: t.width,
        height: t.height,
        deviceScaleFactor: 2,
        mobile: t.width < 768,
      });

      await page.send("Emulation.setEmulatedMedia", {
        media: "screen",
        features: [{ name: "prefers-color-scheme", value: t.dark ? "dark" : "light" }],
      });

      await page.send("Page.navigate", { url: "http://localhost:3005" });
      await sleep(1500);

      // Enforce theme class on documentElement
      await page.send("Runtime.evaluate", {
        expression: t.dark
          ? "document.documentElement.classList.add('dark')"
          : "document.documentElement.classList.remove('dark')",
      });
      await sleep(500);

      const screenshot = await page.send("Page.captureScreenshot", {
        format: "png",
        captureBeyondViewport: t.fullPage,
      });

      const outPath = path.join(AUDIT_DIR, `audit-${t.name}.png`);
      fs.writeFileSync(outPath, Buffer.from(screenshot.data, "base64"));
      console.log(`✓ Saved: ${outPath}`);

      await page.send("Page.close");
      page.close();
    }

    browser.close();
  } catch (err) {
    console.error("Screenshot capture error:", err);
  } finally {
    chromeProc.kill("SIGKILL");
  }
}

capture();
