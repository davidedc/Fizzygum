#!/usr/bin/env node
'use strict';
/*
 * prof-attribute.js — attribute ONE named function's self time by caller chain.
 *
 * Answers "who spends the time inside <fn>?" from a V8 .cpuprofile (as captured by
 * prof-run.js / prof-interactive.js --profile): for every profile node whose
 * functionName matches --fn, its sampled self time is attributed up its parent
 * chain, and aggregated three ways:
 *   1. by IMMEDIATE caller (the parent frame);
 *   2. by NEAREST FRAMEWORK ancestor — the first frame up the chain that is not
 *      inside the SWCanvas/DetTrig segments of the shadow build's profile-boot.js
 *      (Fizzygum's meta-compiled classes live in separate eval scripts, so any
 *      other-script frame is framework/harness code) — i.e. the Fizzygum call site;
 *   3. by ROUTE: the SWCanvas entry point the framework called (the topmost
 *      in-segment frame right below the framework boundary), tagged "via
 *      drawTextFromAtlas" when the chain passes through the glyph-atlas path,
 *      crossed with the framework caller.
 * Plus the top full chains as ground truth.
 *
 * Built for §5B O4 (attribute _drawImageInternal blits: glyph-atlas vs
 * back-buffer) but generic over any function name. Use a SHADOW build profile
 * (mk-shadow-build.sh) — the minified build reports SWCanvas frames as (anon).
 *
 * Usage: node prof-attribute.js <file.cpuprofile> [more.cpuprofile ...]
 *          --fn=_drawImageInternal
 *          [--segments=/tmp/fizzygum-profiling/shadow-build/segments.json]
 *          [--top=18] [--chains=12]
 */
const fs = require('fs');

const args = process.argv.slice(2);
const files = args.filter(a => !a.startsWith('--'));
const opt = (k, d) => { const a = args.find(s => s.startsWith('--' + k + '=')); return a ? a.split('=').slice(1).join('=') : d; };
const FN = opt('fn', '_drawImageInternal');
const TOP = parseInt(opt('top', '18'), 10);
const CHAINS = parseInt(opt('chains', '12'), 10);
const SEGFILE = opt('segments', '/tmp/fizzygum-profiling/shadow-build/segments.json');
if (!files.length) { console.error('usage: node prof-attribute.js <file.cpuprofile> [...] --fn=<name>'); process.exit(1); }

let segments = [];
try { segments = JSON.parse(fs.readFileSync(SEGFILE, 'utf8')); } catch (e) { /* attribution falls back to url-only */ }

// A frame is "in-segment" (SWCanvas/DetTrig prelude) when it lives in profile-boot.js
// inside one of those segment line ranges. callFrame.lineNumber is 0-based; segments.json
// start/end are 1-based. Everything else — eval'd meta-compiled classes, node scripts,
// the FizzygumBoot segment (world/boot plumbing carries real names there) — counts as
// framework for boundary purposes; FizzygumBoot is segment-classified but named anyway.
function segmentOf(cf) {
  if (!cf.url || !cf.url.includes('profile-boot.js')) return null;
  const line = (cf.lineNumber | 0) + 1;
  for (const s of segments) if (line >= s.startLine && line <= s.endLine) return s.name;
  return null;
}
const isEngineFrame = (cf) => { const s = segmentOf(cf); return s === 'SWCanvas' || s === 'DetTrig'; };
const nameOf = (cf) => cf.functionName || '(anonymous)';

function analyze(file) {
  const p = JSON.parse(fs.readFileSync(file, 'utf8'));
  const byId = new Map(); for (const n of p.nodes) byId.set(n.id, n);
  const parent = new Map();
  for (const n of p.nodes) for (const c of (n.children || [])) parent.set(c, n.id);
  const self = new Map();
  let total = 0, idle = 0;
  for (let i = 0; i < p.samples.length; i++) {
    const dt = p.timeDeltas[i] || 0; total += dt;
    const node = byId.get(p.samples[i]); if (!node) continue;
    const fn = nameOf(node.callFrame);
    if (fn === '(idle)' || fn === '(program)') { idle += dt; continue; }
    self.set(node.id, (self.get(node.id) || 0) + dt);
  }
  const busy = total - idle;

  const byImmediate = new Map(), byFramework = new Map(), byRoute = new Map(), byChain = new Map();
  let fnSelf = 0;
  for (const [id, us] of self) {
    const node = byId.get(id);
    if (nameOf(node.callFrame) !== FN) continue;
    fnSelf += us;
    // climb: record immediate caller, nearest framework frame, entry point, glyph marker
    let cur = parent.get(id), immediate = null, entry = null, viaGlyph = false;
    const fwPath = [];                                       // first few framework frames, innermost first
    const chain = [nameOf(node.callFrame)];
    let hops = 0;
    while (cur !== undefined && hops++ < 64) {
      const n = byId.get(cur); if (!n) break;
      const cf = n.callFrame, fname = nameOf(cf);
      if (chain[chain.length - 1] !== fname) chain.push(fname);
      if (!immediate) immediate = fname;
      if (fname === 'drawTextFromAtlas') viaGlyph = true;
      if (isEngineFrame(cf)) { if (!fwPath.length) entry = fname; } // engine frames below the boundary
      else if (fwPath[fwPath.length - 1] !== fname) {
        fwPath.push(fname);                                  // keep climbing: shims (e.g. a fillText
        if (fwPath.length >= 4) break;                       // proto extension) hide the real widget
      }
      cur = parent.get(cur);
    }
    immediate = immediate || '(root)';
    const framework = fwPath.length ? fwPath.join(' <- ') : '(root)';
    const route = (entry || '(direct)') + (viaGlyph ? ' [via drawTextFromAtlas]' : '') + '  ←  ' + framework;
    byImmediate.set(immediate, (byImmediate.get(immediate) || 0) + us);
    byFramework.set(framework, (byFramework.get(framework) || 0) + us);
    byRoute.set(route, (byRoute.get(route) || 0) + us);
    const ckey = chain.slice(0, 14).join(' <- ');
    byChain.set(ckey, (byChain.get(ckey) || 0) + us);
  }

  const ms = (us) => (us / 1000).toFixed(1);
  const pct = (us, base) => base ? (100 * us / base).toFixed(1) + '%' : '-';
  console.log(`\n=== ${file} ===`);
  console.log(`profile total ${ms(total)}ms · busy (excl. idle/program) ${ms(busy)}ms`);
  console.log(`${FN} self time: ${ms(fnSelf)}ms = ${pct(fnSelf, busy)} of busy`);
  if (!fnSelf) { console.log('  (no samples in ' + FN + ')'); return; }
  const dump = (title, m, base) => {
    console.log(`\n  -- ${title} --`);
    [...m.entries()].sort((a, b) => b[1] - a[1]).slice(0, TOP)
      .forEach(([k, us]) => console.log(`  ${pct(us, base).padStart(6)}  ${ms(us).padStart(8)}ms  ${k}`));
  };
  dump(`by ROUTE (engine entry ← framework call site), % of ${FN}`, byRoute, fnSelf);
  dump(`by nearest FRAMEWORK caller, % of ${FN}`, byFramework, fnSelf);
  dump(`by IMMEDIATE caller, % of ${FN}`, byImmediate, fnSelf);
  console.log(`\n  -- top full chains (ground truth) --`);
  [...byChain.entries()].sort((a, b) => b[1] - a[1]).slice(0, CHAINS)
    .forEach(([k, us]) => console.log(`  ${ms(us).padStart(8)}ms  ${k}`));
}

for (const f of files) analyze(f);
