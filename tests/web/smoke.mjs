// Browser smoke test for the exported site (PLAN.md §7.4 step 6).
// Usage: node tests/web/smoke.mjs [siteDir] [--shots outDir]
// Serves the site locally, then drives the release and preview builds in Chromium
// (desktop mouse + phone touch emulation with 4x CPU throttling).
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { chromium, devices } from 'playwright';

const args = process.argv.slice(2);
const siteDir = path.resolve(args.find((a) => !a.startsWith('--')) ?? 'build/site');
const shotsIdx = args.indexOf('--shots');
const shotsDir = shotsIdx >= 0 ? path.resolve(args[shotsIdx + 1]) : null;
const MIME = {
  '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream',
  '.json': 'application/json', '.png': 'image/png', '.zip': 'application/zip', '.svg': 'image/svg+xml',
};

function serve(root) {
  const server = http.createServer((req, res) => {
    const url = new URL(req.url, 'http://localhost');
    let file = path.join(root, decodeURIComponent(url.pathname));
    if (!file.startsWith(root)) { res.writeHead(403).end(); return; }
    if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
    if (!fs.existsSync(file)) { res.writeHead(404).end('not found'); return; }
    res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] ?? 'application/octet-stream' });
    fs.createReadStream(file).pipe(res);
  });
  return new Promise((resolve) => server.listen(0, '127.0.0.1', () => resolve(server)));
}

const failures = [];
function check(cond, msg) { if (!cond) { failures.push(msg); console.error('✗', msg); } else { console.log('✓', msg); } }

// Taps everything Godot connects to the speakers so the test can measure real output levels.
// window.__peak() returns the loudest RMS seen since the previous call.
function hookAudio() {
  const peaks = [];
  const Orig = window.AudioContext;
  window.AudioContext = function (...a) {
    const ctx = new Orig(...a);
    const analyser = ctx.createAnalyser();
    analyser.fftSize = 1024;
    ctx.__analyser = analyser;
    const data = new Float32Array(analyser.fftSize);
    setInterval(() => {
      analyser.getFloatTimeDomainData(data);
      let sum = 0;
      for (const v of data) sum += v * v;
      peaks.push(Math.sqrt(sum / data.length));
    }, 10);
    return ctx;
  };
  window.AudioContext.prototype = Orig.prototype;
  const connect = AudioNode.prototype.connect;
  AudioNode.prototype.connect = function (dest, ...rest) {
    if (dest instanceof AudioDestinationNode && this.context.__analyser) connect.call(this, this.context.__analyser);
    return connect.call(this, dest, ...rest);
  };
  window.__peak = () => Math.max(0, ...peaks.splice(0));
}

function watch(page, label) {
  const log = [];
  page.on('console', (m) => {
    const text = m.text();
    log.push(text);
    if (/SCRIPT ERROR|^ERROR:|USER ERROR/.test(text)) failures.push(`${label}: console error: ${text.slice(0, 300)}`);
  });
  page.on('pageerror', (e) => failures.push(`${label}: page error: ${e.message}`));
  return log;
}

async function waitLog(log, needle, timeout = 60000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    if (log.some((l) => l.includes(needle))) return true;
    await new Promise((r) => setTimeout(r, 100));
  }
  return false;
}

async function state(page) {
  const raw = await page.evaluate(() => window.__disordingState ?? null);
  return raw ? JSON.parse(raw) : {};
}

async function waitState(page, pred, timeout = 30000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const s = await state(page);
    if (pred(s)) return s;
    await new Promise((r) => setTimeout(r, 150));
  }
  return state(page);
}

async function rafFps(page, ms = 4000) {
  return page.evaluate((duration) => new Promise((resolve) => {
    let frames = 0; const start = performance.now();
    function tick(now) { frames++; if (now - start < duration) requestAnimationFrame(tick); else resolve(frames * 1000 / (now - start)); }
    requestAnimationFrame(tick);
  }), ms);
}

async function shot(page, name) {
  if (!shotsDir) return;
  fs.mkdirSync(shotsDir, { recursive: true });
  await page.screenshot({ path: path.join(shotsDir, `${name}.png`) });
}

async function tapCenter(page, touch) {
  const vp = page.viewportSize();
  if (touch) await page.touchscreen.tap(vp.width / 2, vp.height / 2);
  else await page.mouse.click(vp.width / 2, vp.height / 2);
}

// The title ignores taps during its fade-in, and software-rendered CI frames are slow,
// so tap again until the calendar reports ready.
async function openCalendar(page, log, touch) {
  for (let i = 0; i < 6; i++) {
    await tapCenter(page, touch);
    if (await waitLog(log, '[disording] calendar ready', 2500)) return true;
  }
  return false;
}

const server = await serve(siteDir);
const base = `http://127.0.0.1:${server.address().port}`;
const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
const report = {};
try {
  // 1. Release build, desktop mouse.
  {
    const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
    const log = watch(page, 'release/desktop');
    await page.goto(`${base}/index.html`);
    check(await waitLog(log, '[disording] title ready', 90000), 'release: title screen boots');
    await page.waitForTimeout(800);
    await shot(page, 'release_title');
    check(await openCalendar(page, log, false), 'release: tap opens the calendar');
    await page.waitForTimeout(1500);
    await shot(page, 'release_calendar');
    check(await page.evaluate(() => window.__disording === undefined), 'release: no dev test API');
    report.desktop_fps = Math.round(await rafFps(page));
    await page.close();
  }
  // 2. Preview build: drive Day 0 through the test API.
  {
    const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
    const log = watch(page, 'preview');
    await page.addInitScript(hookAudio);
    await page.goto(`${base}/preview/index.html`);
    check(await waitLog(log, '[disording] title ready', 90000), 'preview: title screen boots');
    check(await openCalendar(page, log, false), 'preview: tap opens the calendar');
    // Sound: music (Stream playback) and an SFX (Sample playback) must both reach the speakers.
    // At CI's software-rendered frame rates the music fade-in runs slow, so give it a while.
    let music = 0;
    for (let i = 0; i < 8 && music <= 0.002; i++) {
      await page.waitForTimeout(1000);
      music = Math.max(music, await page.evaluate(() => window.__peak()));
    }
    check(music > 0.002, `preview: music reaches the speakers (rms ${music.toFixed(3)})`);
    await page.evaluate(() => window.__disording.cmd('stop_music'));
    await page.waitForTimeout(1000);
    await page.evaluate(() => window.__peak());
    await page.evaluate(() => window.__disording.cmd('play_sfx', 'open'));
    await page.waitForTimeout(1500);
    const sfx = await page.evaluate(() => window.__peak());
    check(sfx > 0.01, `preview: sound effects reach the speakers (rms ${sfx.toFixed(3)})`);
    await page.evaluate(() => window.__disording.cmd('start_day', 0));
    let s = await waitState(page, (st) => st.screen === 'day' && st.state === 'running');
    check(s.state === 'running', `preview: Day 0 runs (state ${JSON.stringify(s)})`);
    await page.waitForTimeout(1500);
    await shot(page, 'preview_day0');
    await page.evaluate(() => window.__disording.cmd('force', 'star'));
    s = await waitState(page, (st) => st.star === true, 5000);
    check(s.star === true, 'preview: star awarded');
    await page.evaluate(() => window.__disording.cmd('force', 'success'));
    s = await waitState(page, (st) => st.state === 'success', 5000);
    check(s.state === 'success', 'preview: success reached');
    await page.waitForTimeout(1200);
    await shot(page, 'preview_results');
    await page.evaluate(() => window.__disording.cmd('goto_calendar', 1));
    s = await waitState(page, (st) => st.screen === 'calendar', 10000);
    check(Array.isArray(s.playable) && s.stars === 0, `preview: calendar after day 0 (stars ${s.stars})`);
    // Every built day (1+) boots, plays a few seconds with its own AI, and its secret works.
    for (const day of (await page.evaluate(() => fetch('build.json').then((r) => r.json()))).days ?? []) {
      await page.evaluate((d) => window.__disording.cmd('start_day', d), day);
      s = await waitState(page, (st) => st.screen === 'day' && st.day === day && st.state === 'running', 60000);
      check(s.state === 'running', `preview: day ${day} runs`);
      await page.evaluate(() => window.__disording.cmd('autoplay', true));
      await page.waitForTimeout(4000);
      await shot(page, `preview_day${day}`);
      await page.evaluate(() => window.__disording.cmd('force', 'star'));
      s = await waitState(page, (st) => st.star === true, 8000);
      check(s.star === true, `preview: day ${day} secret star`);
      await page.evaluate((d) => window.__disording.cmd('goto_calendar', d), day);
      await waitState(page, (st) => st.screen === 'calendar', 10000);
    }
    await page.close();
  }
  // 3. Release build on a phone: touch + 4x CPU throttle.
  {
    const ctx = await browser.newContext({ ...devices['Pixel 7 landscape'] });
    const page = await ctx.newPage();
    const cdp = await ctx.newCDPSession(page);
    await cdp.send('Emulation.setCPUThrottlingRate', { rate: 4 });
    const log = watch(page, 'release/phone');
    await page.goto(`${base}/index.html`);
    check(await waitLog(log, '[disording] title ready', 120000), 'phone: title screen boots');
    await page.waitForTimeout(800);
    await shot(page, 'phone_title');
    check(await openCalendar(page, log, true), 'phone: tap opens the calendar');
    await page.waitForTimeout(1500);
    await shot(page, 'phone_calendar');
    report.phone_throttled_fps = Math.round(await rafFps(page));
    await ctx.close();
  }
} finally {
  await browser.close();
  server.close();
}
console.log('report', JSON.stringify(report));
if (failures.length) {
  console.error(`\n${failures.length} failure(s):\n- ${failures.join('\n- ')}`);
  process.exit(1);
}
console.log('\nbrowser smoke passed');
