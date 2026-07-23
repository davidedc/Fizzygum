#!/usr/bin/env node
'use strict';
/*
 * prof-interactive.js — profile FELT interactive cost on a BUSY desktop, which the
 * suite-based profiler (prof-run.js) is structurally blind to (the suite runs with
 * the default wallpaper and no window churn). Boots the plain world (index.html),
 * OPENS ALL APPS to load up the screen, then scripts three interactions and times each
 * doOneCycle (= one repaint frame):
 *   - DRAG: float-drag the topmost window along a screen-spanning path.
 *   - DRAW: a pen stroke in FizzyPaint.
 *   - COVERED: park a large window fully over the AnalogClock window, then hold ~180
 *     input-free frames while the clock keeps animating — the occlusion-culling sweet
 *     spot (small broken rects fully inside a fully-covering opaque window; see
 *     docs/plans/occlusion-culling-plan.md §6). Judge this phase by MEAN + fire-rate, not
 *     median (its frames are mostly cheap no-ops).
 * Runs once per --wallpaper so plain-vs-dots is an A/B control (confirms the W1/W2
 * pattern fix in-situ and isolates any wallpaper-independent per-frame cost).
 *
 * Occlusion-culling A/B (docs/plans/occlusion-culling-plan.md §6): --cull=on|off|both flips
 * WorldWdgt.occlusionCullingEnabled after boot and re-runs the identical scripted
 * phases — the SAME-BUILD flag A/B is the authoritative before/after (the flag-off
 * path is the untouched super() path). Pin --wallpaper=plain for cull A/Bs (one axis
 * at a time). --occl wraps the cull entry points to tally per-phase {rects seen, culled
 * fires, fire-rate %} + scan-call count. On a PRE-feature build the flag/methods don't
 * exist yet → cull reports "n/a" and --occl reports "unreachable" (that is the P0
 * harness shakedown: cull legs must be identical, --occl must say n/a).
 *
 * Deterministic: fixed paths, no Math.random/Date-driven choices; identical event
 * stream across wallpapers. rAF drives the world loop headless (~60/s), so real
 * page.mouse events + a doOneCycle timing wrapper capture faithful frame costs.
 *
 * Usage: node prof-interactive.js [--wallpaper=dots|plain] [--cull=on|off|both] [--occl]
 *                                 [--profile] [--out=<prefix>] [--build=<dir>]
 *                                 [--drag-frames=140] [--draw-frames=80] [--covered-frames=180]
 * With no --wallpaper it runs BOTH and prints the A/B.  --profile adds a CDP V8
 * cpuprofile per phase (<out>.<wallpaper>.<cull>.<phase>.cpuprofile) for prof-aggregate.
 */
const path = require('path');
const fs = require('fs');
const TESTS_REPO = path.resolve(__dirname, '..', '..', '..', 'Fizzygum-tests');
const puppeteer = require(path.join(TESTS_REPO, 'node_modules', 'puppeteer'));

const args = process.argv.slice(2);
const opt = (k, d) => { const a = args.find(s => s.startsWith('--' + k + '=')); return a ? a.split('=').slice(1).join('=') : d; };
const flag = (k) => args.includes('--' + k);
const BUILD = path.resolve(opt('build', path.resolve(__dirname, '..', '..', '..', 'Fizzygum-builds', 'latest')));
const URL = 'file://' + path.join(BUILD, 'index.html') + (flag('sw') ? '?sw=1' : '');
const OUT = opt('out', '/tmp/fizzygum-profiling/interactive');
const DRAG_FRAMES = parseInt(opt('drag-frames', '140'), 10);
const DRAW_FRAMES = parseInt(opt('draw-frames', '80'), 10);
const COVERED_FRAMES = parseInt(opt('covered-frames', '180'), 10);
const VW = 1280, VH = 900;
const wallpapers = opt('wallpaper', '') ? [opt('wallpaper', '')] : ['plain', 'dots'];
const PHASES = ['drag', 'draw', 'covered'];
// Occlusion-culling axis (docs/plans/occlusion-culling-plan.md §6): both → on & off; on/off → that leg;
// unset → a single run at the build's default (flag untouched).
const cullArg = opt('cull', '');
const cullConfigs = cullArg === 'both' ? ['on', 'off'] : (cullArg ? [cullArg] : [null]);

const sleep = (ms) => new Promise(r => setTimeout(r, ms));
function ready(t){return new Promise(r=>{const s=Date.now();(function tick(){const w=window.world;const ok=!!(w&&w.worldCanvasContext);if(ok||Date.now()-s>t)r(!!ok);else setTimeout(tick,100);})();});}
function stats(a){ if(!a.length) return {n:0}; const s=[...a].sort((x,y)=>x-y); const q=p=>s[Math.min(s.length-1,Math.floor(p*s.length))];
  return {n:s.length, median:+q(0.5).toFixed(2), p95:+q(0.95).toFixed(2), max:+s[s.length-1].toFixed(2), mean:+(a.reduce((x,y)=>x+y,0)/a.length).toFixed(2)}; }

async function installTiming(page){
  await page.evaluate(()=>{ window.__ft={}; window.__phase='idle';
    const o=world.doOneCycle.bind(world);
    world.doOneCycle=function(){ const t0=performance.now(); const r=o(); const dt=performance.now()-t0;
      (window.__ft[window.__phase]=window.__ft[window.__phase]||[]).push(dt); return r; }; });
}
// Instrument SWCanvas canvas-wide compositing: count calls, tally iterated pixels,
// and sample a stack for the FIRST few triggers (to name what sets the op).
async function installCWC(page){
  await page.evaluate(()=>{
    const R = (window.SWCanvas&&SWCanvas.Core&&SWCanvas.Core.Rasterizer);
    window.__cwc = {reachable: !!R, byOp:{}, calls:0, pixels:0, stacks:[]};
    if(!R) return;
    const proto=R.prototype;
    const oPerf=proto._performCanvasWideCompositing;
    proto._performCanvasWideCompositing=function(...a){
      const op=(this._currentOp&&this._currentOp.composite)||'?';
      window.__cwc.calls++; window.__cwc.byOp[op]=(window.__cwc.byOp[op]||0)+1;
      // iteration area actually scanned:
      try{ const sm=this._currentOp.sourceMask; const b=sm.getIterationBounds(this._currentOp.clipMask,true);
        if(!b.isEmpty) window.__cwc.pixels += (b.maxX-b.minX+1)*(b.maxY-b.minY+1); }catch(e){}
      if(window.__cwc.stacks.length<6){ try{ window.__cwc.stacks.push(op+' :: '+(new Error()).stack.split('\n').slice(2,7).join(' <- ').replace(/https?:\/\/[^ ]*\//g,'')); }catch(e){} }
      return oPerf.apply(this,a);
    };
  });
}
async function dumpCWC(page){ return await page.evaluate(()=>window.__cwc); }
// Instrument text: how many strings render per drag frame, and are they repeats
// (→ back buffers NOT being reused) or one-offs. Also count TextWdgt back-buffer
// cache hits vs rebuilds.
async function installText(page){
  await page.evaluate(()=>{
    window.__txt={renders:0, byStr:{}, bbHit:0, bbMiss:0};
    const BT=(window.SWCanvas&&SWCanvas.fonts&&SWCanvas.fonts._raw&&SWCanvas.fonts._raw.BitmapText);
    if(BT&&BT.drawTextFromAtlas){ const o=BT.drawTextFromAtlas.bind(BT);
      BT.drawTextFromAtlas=function(ctx,text,...r){ window.__txt.renders++; const k=String(text).slice(0,24); window.__txt.byStr[k]=(window.__txt.byStr[k]||0)+1; return o(ctx,text,...r); }; }
    if(typeof TextWdgt!=='undefined' && TextWdgt.prototype.createRefreshOrGetBackBuffer){
      const o=TextWdgt.prototype.createRefreshOrGetBackBuffer;
      TextWdgt.prototype.createRefreshOrGetBackBuffer=function(){ const hit=world.cacheForImmutableBackBuffers.get(this.createBufferCacheKey()); if(hit)window.__txt.bbHit++; else window.__txt.bbMiss++; return o.apply(this,arguments); }; }
  });
}
async function dumpText(page){ return await page.evaluate(()=>window.__txt); }
// Apply the occlusion-culling flag after boot. Returns the applied state string:
// 'on'/'off' if the feature exists, 'n/a' on a pre-feature build (flag absent).
async function applyCull(page, cull){
  if(cull === null) return 'default';
  return await page.evaluate((c)=>{
    if(typeof WorldWdgt === 'undefined' || WorldWdgt.occlusionCullingEnabled === undefined) return 'n/a';
    WorldWdgt.occlusionCullingEnabled = (c === 'on');
    return c;
  }, cull);
}
// Instrument the occlusion-culling entry points (mirrors installCWC's shape): per-phase
// {rects seen, culled fires} on WorldWdgt::_paintedFromFrontmostCoverer + a total
// scan-call count on Widget::opaqueCoveredRect. Reports unreachable on a pre-feature build.
async function installOccl(page){
  await page.evaluate(()=>{
    window.__occl = {reachable:false, byPhase:{}, scanCalls:0};
    const W = (typeof WorldWdgt !== 'undefined') ? WorldWdgt.prototype : null;
    const hasPaint = W && typeof W._paintedFromFrontmostCoverer === 'function';
    const hasScan = (typeof Widget !== 'undefined') && typeof Widget.prototype.opaqueCoveredRect === 'function';
    window.__occl.reachable = !!(hasPaint && hasScan);
    if(hasPaint){ const o = W._paintedFromFrontmostCoverer;
      W._paintedFromFrontmostCoverer = function(){ const r = o.apply(this, arguments);
        const ph = window.__phase; const b = (window.__occl.byPhase[ph] = window.__occl.byPhase[ph] || {seen:0, fired:0});
        b.seen++; if(r) b.fired++; return r; }; }
    if(hasScan){ const o = Widget.prototype.opaqueCoveredRect;
      Widget.prototype.opaqueCoveredRect = function(){ window.__occl.scanCalls++; return o.apply(this, arguments); }; }
  });
}
async function dumpOccl(page){ return await page.evaluate(()=>window.__occl); }
async function setPhase(page,ph){ await page.evaluate(p=>{window.__phase=p;},ph); }
async function openAllApps(page){
  return await page.evaluate(async ()=>{
    const names=Object.getOwnPropertyNames(window).filter(k=>{let C;try{C=window[k]}catch(e){return false}
      return typeof C==='function'&&typeof IconicDesktopSystemWindowedApp!=='undefined'&&C.prototype instanceof IconicDesktopSystemWindowedApp}).sort();
    const opened=[]; const errs=[];
    for(const n of names){ try{ (new window[n]()).launch(); opened.push(n); }catch(e){ errs.push(n+': '+(e&&e.message||e)); }
      await new Promise(r=>setTimeout(r,120)); }
    return {opened,errs};
  });
}
async function setWallpaper(page,wp){ await page.evaluate(w=>{ world.wallpaper.patternName=w; world.changed(); },wp); }

// topmost window grab point (titlebar), in CSS px (dpr=ceilPixelRatio=1 in this build)
async function topWindowGrab(page){
  return await page.evaluate(()=>{
    const wins=(world.children||[]).filter(c=>c instanceof WindowWdgt && c.bounds);
    if(!wins.length) return null;
    const w=wins[wins.length-1]; const b=w.bounds;
    return { x: Math.round(b.left()+Math.min(90,(b.right()-b.left())/2)), y: Math.round(b.top()+10),
             title:(w.label&&w.label.text)||w.constructor.name, count:wins.length };
  });
}
// Find the already-open FizzyPaint window ("Drawings Maker", opened in openAllApps)
// and return its content area (CSS px). Finding an existing window keeps the launch
// out of the timing-sensitive path.
async function fizzyPaintCanvasArea(page){
  return await page.evaluate(()=>{
    const wins=(world.children||[]).filter(c=>c instanceof WindowWdgt && c.bounds);
    const isPaint=(w)=>/Paint|Drawing/i.test(w.constructor.name) || (w.label && /paint|drawing/i.test(w.label.text||''));
    const w=wins.filter(isPaint).pop() || wins.pop();
    if(!w) return null; const b=w.bounds;
    return { cx: Math.round((b.left()+b.right())/2), cy: Math.round(b.top()+ (b.bottom()-b.top())*0.6),
             halfW: Math.round((b.right()-b.left())*0.30), halfH: Math.round((b.bottom()-b.top())*0.22),
             title:(w.label&&w.label.text)||w.constructor.name };
  });
}

async function dragPhase(page){
  const g = await topWindowGrab(page);
  if(!g){ console.log('    (no window to drag)'); return; }
  console.log(`    dragging "${g.title}" (${g.count} windows open)`);
  await setPhase(page,'drag');
  await page.mouse.move(g.x,g.y); await page.mouse.down(); await sleep(30);
  // a screen-spanning lissajous so the window sweeps over the other windows + desktop
  const cx=VW/2, cy=VH/2, ax=VW*0.32, ay=VH*0.30;
  for(let i=0;i<DRAG_FRAMES;i++){
    const t=i/DRAG_FRAMES*Math.PI*2*2;
    const x=Math.round(cx+ax*Math.sin(t)), y=Math.round(cy+ay*Math.sin(2*t));
    await page.mouse.move(x,y,{steps:1});
    await sleep(16);
  }
  await page.mouse.up(); await sleep(60);
}
async function drawPhase(page){
  const a = await fizzyPaintCanvasArea(page);
  if(!a || a.err || a.halfW===undefined){ console.log('    (FizzyPaint window not found; skipping draw'+(a&&a.err?': '+a.err:'')+')'); return; }
  console.log(`    drawing in "${a.title}"`);
  await setPhase(page,'draw');
  await page.mouse.move(a.cx-a.halfW,a.cy); await page.mouse.down(); await sleep(30);
  for(let i=0;i<DRAW_FRAMES;i++){
    const t=i/DRAW_FRAMES*Math.PI*2*3;
    const x=Math.round(a.cx+a.halfW*Math.sin(t)), y=Math.round(a.cy+a.halfH*Math.cos(t*1.5));
    await page.mouse.move(x,y,{steps:1});
    await sleep(16);
  }
  await page.mouse.up(); await sleep(60);
}
// COVERED phase (docs/plans/occlusion-culling-plan.md §6): the default desktop clock is a BARE 80x80
// AnalogClockWdgt in the top-right corner (WorldWdgt.createDesktop, added FIRST so every app window
// is already in front of it in z-order). Reposition the largest window over it via the public move
// API, then hold input-free frames: the clock keeps animating (face back-buffered post-C1, hands
// repaint live) → small broken rects fully inside a fully-covering opaque window (the cull sweet spot).
async function coveredPhase(page){
  const info = await page.evaluate((VW)=>{
    const clk = (world.children||[]).find(c=> typeof AnalogClockWdgt!=='undefined' && c instanceof AnalogClockWdgt && c.bounds);
    if(!clk) return {err:'no bare AnalogClockWdgt on the desktop'};
    const cb = clk.bounds;
    const wins = (world.children||[]).filter(c=>c instanceof WindowWdgt && c.bounds);
    const cov = wins.sort((a,b)=>(b.bounds.width()*b.bounds.height())-(a.bounds.width()*a.bounds.height()))[0];
    if(!cov) return {err:'no coverer window'};
    const covW = cov.bounds.width(), covH = cov.bounds.height();
    const margin = 24;
    const newRight = Math.min(VW, cb.right() + margin);
    const newLeft = Math.max(0, Math.round(newRight - covW));
    cov.moveTo(new Point(newLeft, 0));           // pin top-right over the corner clock; top=0 covers its y
    world.changed();
    const nb = cov.bounds, inset = 5;            // Boxy inscribed box = bounds inset radius(4)+1
    return {
      covTitle:(cov.label&&cov.label.text)||cov.constructor.name, covW:Math.round(covW), covH:Math.round(covH),
      clk:`[${Math.round(cb.left())},${Math.round(cb.top())},${Math.round(cb.right())},${Math.round(cb.bottom())}]`,
      covers: (nb.left()+inset <= cb.left() && nb.top()+inset <= cb.top() && nb.right()-inset >= cb.right() && nb.bottom()-inset >= cb.bottom())
    };
  }, VW);
  if(info.err){ console.log('    (covered phase skipped: '+info.err+')'); return; }
  console.log(`    covered clock ${info.clk} with "${info.covTitle}" (${info.covW}x${info.covH}); Boxy inscribed box ${info.covers?'DOES':'does NOT'} contain the clock`);
  await setPhase(page,'covered');
  await sleep(60);                               // let the reposition settle + paint
  await page.evaluate(()=>{ window.__ft.covered = []; }); // time only the steady-state frames
  for(let i=0;i<COVERED_FRAMES;i++){ await sleep(16); }
}

async function runOne(browser, wp, cull){
  const page = await browser.newPage();
  await page.setViewport({width:VW,height:VH,deviceScaleFactor:1});
  const perr=[]; page.on('pageerror',e=>perr.push(e.message));
  await page.goto(URL,{waitUntil:'load',timeout:30000});
  await page.evaluate(ready,15000);
  await installTiming(page);
  const cullState = await applyCull(page, cull);
  if(flag('occl')) await installOccl(page);
  if(flag('cwc')) await installCWC(page);
  if(flag('text')) await installText(page);
  const {opened,errs}=await openAllApps(page);
  const tag = cull === null ? wp : `${wp}/cull=${cullState}`;
  console.log(`  [${tag}] opened ${opened.length} apps${errs.length?` (${errs.length} launch errors)`:''}`);
  await setWallpaper(page,wp);
  await sleep(500);
  await page.evaluate(()=>{ window.__ft={}; }); // discard warm-up/app-open frames

  let client=null;
  if(flag('profile')){ client=await page.target().createCDPSession(); await client.send('Profiler.enable'); await client.send('Profiler.setSamplingInterval',{interval:300}); }

  const cullSeg = cull === null ? '' : `.cull-${cullState}`;
  async function profiled(name, fn){
    if(client){ await client.send('Profiler.start'); }
    await fn();
    if(client){ const {profile}=await client.send('Profiler.stop');
      fs.mkdirSync(path.dirname(OUT),{recursive:true});
      fs.writeFileSync(`${OUT}.${wp}${cullSeg}.${name}.cpuprofile`, JSON.stringify(profile)); }
  }
  await profiled('drag', ()=>dragPhase(page));
  await profiled('draw', ()=>drawPhase(page));
  await profiled('covered', ()=>coveredPhase(page));

  const ft = await page.evaluate(()=>window.__ft);
  const cwc = flag('cwc') ? await dumpCWC(page) : null;
  const txt = flag('text') ? await dumpText(page) : null;
  const occl = flag('occl') ? await dumpOccl(page) : null;
  await page.close();
  const out = {wp, cull:cullState, pageErrors:perr.length, cwc, txt, occl};
  for(const ph of PHASES) out[ph] = stats(ft[ph]||[]);
  return out;
}

(async()=>{
  require(path.join(TESTS_REPO,'scripts','lib','kill-stale-browsers'))('prof-interactive.js');
  console.log('Fizzygum interactive profiler\n  url: '+URL+`\n  viewport ${VW}x${VH} dpr1 · drag ${DRAG_FRAMES}f · draw ${DRAW_FRAMES}f · covered ${COVERED_FRAMES}f · wallpapers: ${wallpapers.join(', ')}`+(cullArg?` · cull: ${cullConfigs.join('/')}`:'')+(flag('occl')?' · +occl counters':'')+(flag('profile')?' · +V8 profile':'')+'\n');
  const browser=await puppeteer.launch({headless:'new',args:['--allow-file-access-from-files','--no-sandbox']});
  const results=[];
  try{ for(const wp of wallpapers){ for(const cull of cullConfigs){ results.push(await runOne(browser,wp,cull)); } } }
  finally{ await browser.close(); }
  const label = (r)=> (r.cull==='default' ? r.wp : `${r.wp}/${r.cull}`);
  const labW = Math.max(11, ...results.map(r=>label(r).length+1));
  console.log('\n=== per-frame doOneCycle cost (ms; lower is better; 16.7ms = 60fps budget) ===');
  console.log('  '+'config'.padEnd(labW)+' phase   n    median   p95     max     mean');
  for(const r of results){ for(const ph of PHASES){ const s=r[ph];
    if(!s.n){ console.log(`  ${label(r).padEnd(labW)} ${ph.padEnd(6)} (no frames)`); continue; }
    console.log(`  ${label(r).padEnd(labW)} ${ph.padEnd(6)} ${String(s.n).padEnd(4)} ${String(s.median).padEnd(8)} ${String(s.p95).padEnd(7)} ${String(s.max).padEnd(7)} ${s.mean}`); } }
  if(flag('occl')){ for(const r of results){ if(!r.occl) continue;
    console.log(`\n=== occlusion culling [${label(r)}] (reachable=${r.occl.reachable}) ===`);
    if(!r.occl.reachable){ console.log('  (pre-feature build — n/a: WorldWdgt._paintedFromFrontmostCoverer / Widget.opaqueCoveredRect absent)'); continue; }
    console.log(`  opaqueCoveredRect scan calls (total): ${r.occl.scanCalls}`);
    for(const ph of PHASES){ const b=r.occl.byPhase[ph]; if(!b){ console.log(`  ${ph.padEnd(8)} (no rects)`); continue; }
      const rate = b.seen ? (100*b.fired/b.seen).toFixed(1) : '0.0';
      console.log(`  ${ph.padEnd(8)} rects seen ${String(b.seen).padStart(6)}   culled fires ${String(b.fired).padStart(6)}   fire-rate ${rate}%`); } } }
  if(flag('cwc')){ for(const r of results){ if(!r.cwc) continue;
    console.log(`\n=== canvas-wide compositing [${r.wp}] (reachable=${r.cwc.reachable}) ===`);
    console.log(`  calls: ${r.cwc.calls}   pixels iterated: ${(r.cwc.pixels/1e6).toFixed(1)}M   by op: ${JSON.stringify(r.cwc.byOp)}`);
    for(const s of (r.cwc.stacks||[])) console.log('   • '+s);
  } }
  if(flag('text')){ for(const r of results){ if(!r.txt) continue; const t=r.txt;
    const top=Object.entries(t.byStr).sort((a,b)=>b[1]-a[1]).slice(0,12);
    console.log(`\n=== text rendering [${r.wp}] over the whole run ===`);
    console.log(`  BitmapText.drawTextFromAtlas calls: ${t.renders}   TextWdgt back-buffer: ${t.bbHit} hits / ${t.bbMiss} rebuilds`);
    console.log(`  most-repeated strings (count × "text"):`);
    for(const [s,c] of top) console.log(`    ${String(c).padStart(5)} × "${s}"`);
  } }
  const wpBoth = wallpapers.length===2 && cullConfigs.length===1 && cullConfigs[0]===null;
  if(wpBoth){
    const pa=results.find(r=>r.wp==='plain'), pd=results.find(r=>r.wp==='dots');
    console.log('\n=== wallpaper A/B (dots vs plain) ===');
    for(const ph of PHASES){ if(pa&&pd&&pa[ph].n&&pd[ph].n)
      console.log(`  ${ph.padEnd(8)} plain median ${pa[ph].median}ms  vs  dots ${pd[ph].median}ms  (Δ ${(pd[ph].median-pa[ph].median).toFixed(2)}ms, ${(pd[ph].median/pa[ph].median).toFixed(2)}x)`); }
  }
  if(cullArg==='both'){
    console.log('\n=== occlusion-culling A/B (off → on; negative Δ = faster with culling) ===');
    for(const wp of wallpapers){
      const on=results.find(r=>r.wp===wp && r.cull==='on'), off=results.find(r=>r.wp===wp && r.cull==='off');
      if(!on||!off) continue;
      if(on.occl && !on.occl.reachable) console.log(`  [${wp}] n/a — pre-feature build (flag absent); off & on legs are the identical super() path`);
      for(const ph of PHASES){ if(!on[ph].n||!off[ph].n) continue;
        const dMed=(on[ph].median-off[ph].median), dMean=(on[ph].mean-off[ph].mean);
        console.log(`  [${wp}] ${ph.padEnd(8)} median ${off[ph].median}→${on[ph].median}ms (Δ ${dMed.toFixed(2)}ms, ${(on[ph].median/off[ph].median).toFixed(2)}x) · mean ${off[ph].mean}→${on[ph].mean}ms (Δ ${dMean.toFixed(2)}ms)`); }
    }
  }
})().catch(e=>{console.error(e);process.exit(1)});
