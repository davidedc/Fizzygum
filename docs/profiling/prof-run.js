#!/usr/bin/env node
'use strict';
/*
 * prof-run.js — boot the built Fizzygum SystemTest harness headless, run a set
 * of SystemTests, and capture (a) a V8 CPU profile via CDP and/or (b) canvas
 * workload counters via page-side instrumentation (prof-instrument.js).
 *
 * Usage:
 *   node prof-run.js --build=<dir> --sw=0|1 --dpr=1|2 [--tests=all|name,name]
 *                    [--out=<prefix>] [--sample-us=300] [--profile] [--counters]
 *                    [--speed=fastest] [--timeout-mins=25]
 *
 * Writes: <out>.cpuprofile, <out>.scripts.json (scriptId->class map),
 *         <out>.counters.json, <out>.meta.json (timings, per-test wall clock).
 */
const fs = require('fs');
const path = require('path');
const TESTS_REPO = path.resolve(__dirname, '..', '..', '..', 'Fizzygum-tests'); // umbrella-sibling layout
const puppeteer = require(path.join(TESTS_REPO, 'node_modules', 'puppeteer'));
try { require(path.join(TESTS_REPO, 'scripts', 'lib', 'kill-stale-browsers'))('prof-run.js'); } catch (e) { console.log('(kill-stale-browsers skipped: ' + e.message + ')'); }

const argv = process.argv.slice(2);
function flag(name, dflt) {
  const a = argv.find((x) => x === '--' + name || x.startsWith('--' + name + '='));
  if (!a) return dflt;
  return a.includes('=') ? a.split('=').slice(1).join('=') : true;
}
const BUILD = path.resolve(process.cwd(), flag('build', path.resolve(__dirname, '..', '..', '..', 'Fizzygum-builds', 'latest')));
const SW = flag('sw', '1');
const DPR = flag('dpr', '1');
const SPEED = flag('speed', 'fastest');
const TESTS = flag('tests', 'all');
const OUT = flag('out', 'profrun');
const SAMPLE_US = parseInt(flag('sample-us', '300'), 10);
const DO_PROFILE = !!flag('profile', false);
const DO_COUNTERS = !!flag('counters', false);
const TIMEOUT_MINS = parseFloat(flag('timeout-mins', '30'));

const HARNESS = path.join(BUILD, 'worldWithSystemTestHarness.html');
if (!fs.existsSync(HARNESS)) { console.error('no harness at ' + HARNESS); process.exit(2); }
const url = 'file://' + HARNESS + '?sw=' + SW + '&dpr=' + DPR + '&speed=' + SPEED + '&intro=0';

const INSTRUMENT_SRC = fs.readFileSync(path.join(__dirname, 'prof-instrument.js'), 'utf8');

// waits inside the page (no waitForFunction — Fizzygum patches prototypes)
function pageWaitReady() {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  return (async () => {
    const t0 = Date.now();
    while (Date.now() - t0 < 60000) {
      try {
        if (window.world && world.worldRenderCanvas && world.worldCanvasContext && window.Automator) {
          return { ok: true, readyAfterMs: Date.now() - t0, perfNow: performance.now() };
        }
      } catch (e) {}
      await sleep(100);
    }
    return { ok: false };
  })();
}

function pageSelectAndStart(tests) {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  return (async () => {
  world.automator.loader.selectTestsFromTagsOrTestNames(tests);
  const t0 = Date.now();
  while (Date.now() - t0 < 30000) {
    if (world.automator.selectedTestsBasedOnTags && world.automator.selectedTestsBasedOnTags.length >= 1) break;
    await sleep(100);
  }
  const sel = (world.automator.selectedTestsBasedOnTags || []).slice();
  // world-side counters: broken-rect repaint volume (only meaningful post-boot)
  try {
    if (window.__PF && !window.__PF._worldWrapped) {
      window.__PF._worldWrapped = true;
      const origP = WorldWdgt.prototype.fullPaintIntoAreaOrBlitFromBackBuffer;
      WorldWdgt.prototype.fullPaintIntoAreaOrBlitFromBackBuffer = function (aContext, aRect) {
        try {
          if (aContext === world.worldCanvasContext && aRect && aRect.width) {
            window.__PF.frames.brokenRects++;
            window.__PF.frames.brokenArea += Math.abs(aRect.width() * aRect.height());
          }
        } catch (e) {}
        return origP.apply(this, arguments);
      };
      const origC = WorldWdgt.prototype.doOneCycle;
      WorldWdgt.prototype.doOneCycle = function () {
        window.__PF.frames.updateBrokenCalls++;
        return origC.apply(this, arguments);
      };
    }
  } catch (e) {}
  world.automator.player.runAllSystemTests();
  return { selected: sel.length, first: sel[0] || null };
  })();
}

function pagePollStatus() {
  try {
    const a = world.automator;
    // profiling runs don't capture references: drop collected failure images
    // (each holds a full-canvas base64 PNG) so a red run can't balloon memory.
    try { if (a.collectedFailureImages && a.collectedFailureImages.length) a.collectedFailureImages.length = 0; } catch (e) {}
    const total = a.loader.testsList().length;
    const idx = a.indexOfSystemTestBeingPlayed;
    let cur = a.loader.testsList()[Math.min(idx, total - 1)] || {};
    if (typeof cur === 'string') cur = { testName: cur };
    return {
      state: Automator.state,
      idle: Automator.state === Automator.IDLE,
      idx: idx,
      total: total,
      failed: (a.failedTests || []).length,
      failedNames: (a.failedTests || []).slice(0, 40),
      current: cur.testName || cur.name || null,
    };
  } catch (e) { return { err: e.message }; }
}

(async () => {
  const meta = { url, build: BUILD, sw: SW, dpr: DPR, speed: SPEED, tests: TESTS, sampleUs: SAMPLE_US, profile: DO_PROFILE, counters: DO_COUNTERS };
  console.log('prof-run: ' + JSON.stringify(meta));
  const browser = await puppeteer.launch({
    headless: 'new',
    protocolTimeout: (TIMEOUT_MINS + 10) * 60 * 1000,
    args: ['--allow-file-access-from-files', '--no-sandbox'],
  });
  let exitCode = 1;
  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1100, height: 800, deviceScaleFactor: 1 });
    const errors = [];
    page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
    page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));

    if (DO_COUNTERS) await page.evaluateOnNewDocument(INSTRUMENT_SRC);

    const cdp = await page.target().createCDPSession();
    const scriptMeta = {}; // scriptId -> {url, startLine}
    if (DO_PROFILE) {
      await cdp.send('Debugger.enable', { maxScriptsCacheSize: 1e9 });
      cdp.on('Debugger.scriptParsed', (ev) => { scriptMeta[ev.scriptId] = { url: ev.url || '', startLine: ev.startLine }; });
      await cdp.send('Profiler.enable');
      await cdp.send('Profiler.setSamplingInterval', { interval: SAMPLE_US });
    }

    const PROFILE_BOOT = !!flag('profile-boot', false);
    const tGoto = Date.now();
    if (DO_PROFILE && PROFILE_BOOT) await cdp.send('Profiler.start');
    await page.goto(url, { waitUntil: 'load', timeout: 90000 });
    meta.loadMs = Date.now() - tGoto;

    const tBoot = Date.now();
    const ready = await page.evaluate(pageWaitReady);
    meta.bootMs = Date.now() - tBoot;
    if (!ready.ok) throw new Error('world did not become ready');
    console.log('  booted in ' + meta.bootMs + ' ms (load ' + meta.loadMs + ' ms)');
    // default: profile only the RUN phase (boot's one-time CoffeeScript compile
    // is measured separately with --profile-boot)
    if (DO_PROFILE && !PROFILE_BOOT) await cdp.send('Profiler.start');

    const testList = TESTS === 'all' ? ['all'] : TESTS.split(',').map((s) => (s.startsWith('SystemTest_') ? s : 'SystemTest_' + s));
    const started = await page.evaluate(pageSelectAndStart, testList);
    console.log('  selected ' + started.selected + ' tests');
    if (!started.selected) throw new Error('no tests selected for ' + JSON.stringify(testList));

    // poll from Node: progress + per-test wall clock + stall detection
    const t0 = Date.now();
    const perTest = []; // {idx, name, tStartMs}
    let lastIdx = -1, lastAdvance = Date.now(), done = false, status = null;
    while (!done) {
      await new Promise((r) => setTimeout(r, 1000));
      status = await page.evaluate(pagePollStatus);
      if (status.err) continue;
      if (status.idx !== lastIdx) {
        perTest.push({ idx: status.idx, name: status.current, atMs: Date.now() - t0 });
        lastIdx = status.idx; lastAdvance = Date.now();
        if (status.idx % 10 === 0) console.log('  progress ' + status.idx + '/' + status.total + ' failed=' + status.failed + ' t=' + Math.round((Date.now() - t0) / 1000) + 's');
      }
      if (status.idle && status.idx >= status.total) done = true;
      if (Date.now() - lastAdvance > TIMEOUT_MINS * 60 * 1000) { console.log('  STALL — aborting run'); break; }
    }
    meta.runMs = Date.now() - t0;
    meta.finalStatus = status;
    meta.pageErrors = errors.slice(0, 40);
    console.log('  run took ' + Math.round(meta.runMs / 1000) + 's; failed=' + (status && status.failed));

    if (DO_PROFILE) {
      const { profile } = await cdp.send('Profiler.stop');
      fs.writeFileSync(OUT + '.cpuprofile', JSON.stringify(profile));
      console.log('  wrote ' + OUT + '.cpuprofile (' + profile.nodes.length + ' nodes, ' + (profile.samples || []).length + ' samples)');
      // map eval'd scripts to class names via their source text
      const ids = Object.keys(scriptMeta);
      const map = {};
      for (const id of ids) {
        const m = scriptMeta[id];
        if (m.url && !m.url.startsWith('debugger')) { map[id] = { url: m.url }; continue; }
        try {
          const { scriptSource } = await cdp.send('Debugger.getScriptSource', { scriptId: id });
          const head = scriptSource.slice(0, 4000);
          let cls = null;
          // meta-compiler fragments are strings of `window.<Class>.prototype.m = ...`
          let mm = head.match(/window\.([A-Za-z_$][\w$]*)\s*[=.]/);
          if (!mm) mm = head.match(/(?:var|window\.)?\s*([A-Za-z_$][\w$]*)\s*=\s*class/);
          if (!mm) mm = head.match(/class\s+([A-Za-z_$][\w$]*)/);
          if (mm) cls = mm[1];
          map[id] = { url: '', cls: cls, len: scriptSource.length };
          if (flag('save-sources', false) && scriptSource.length < 800000) map[id].src = scriptSource;
        } catch (e) { map[id] = { url: m.url || '', err: true }; }
      }
      fs.writeFileSync(OUT + '.scripts.json', JSON.stringify(map));
      console.log('  wrote ' + OUT + '.scripts.json (' + ids.length + ' scripts)');
    }

    if (DO_COUNTERS) {
      const counters = await page.evaluate(() => (window.__PF ? window.__PF.report() : null));
      fs.writeFileSync(OUT + '.counters.json', JSON.stringify(counters, null, 1));
      console.log('  wrote ' + OUT + '.counters.json');
    }

    meta.perTest = perTest;
    fs.writeFileSync(OUT + '.meta.json', JSON.stringify(meta, null, 1));
    exitCode = status && status.idle && status.idx >= status.total ? 0 : 1;
    await page.close();
  } catch (e) {
    console.error(e);
  } finally {
    await browser.close();
  }
  process.exit(exitCode);
})();
