#!/usr/bin/env node
'use strict';
/*
 * prof-aggregate.js — aggregate a V8 .cpuprofile into:
 *   - bucket totals (SWCanvas / DetTrig / FizzygumBoot / runtime-compiled
 *     classes (by class name via scripts.json) / native+builtins / idle)
 *   - top functions by self time (merged by functionName+script+line)
 *   - top functions by total time (stack-attributed, no double count)
 *
 * Usage: node prof-aggregate.js <prefix> [--segments=<segments.json>] [--top=40]
 *   reads <prefix>.cpuprofile, <prefix>.scripts.json
 */
const fs = require('fs');
const path = require('path');

const prefix = process.argv[2];
const topN = parseInt((process.argv.find((a) => a.startsWith('--top=')) || '--top=40').split('=')[1], 10);
const segArg = process.argv.find((a) => a.startsWith('--segments='));
const profile = JSON.parse(fs.readFileSync(prefix + '.cpuprofile', 'utf8'));
let scriptsMap = {};
try { scriptsMap = JSON.parse(fs.readFileSync(prefix + '.scripts.json', 'utf8')); } catch (e) {}
let segments = [];
if (segArg) segments = JSON.parse(fs.readFileSync(segArg.split('=')[1], 'utf8'));

const nodes = profile.nodes;
const byId = new Map();
for (const n of nodes) byId.set(n.id, n);
const parent = new Map();
for (const n of nodes) if (n.children) for (const c of n.children) parent.set(c, n.id);

function segmentFor(line) { // 1-based line
  for (const s of segments) if (line >= s.startLine && line <= s.endLine) return s.name;
  return 'BootBundle?';
}

function keyOf(n) {
  const cf = n.callFrame;
  return cf.functionName + '@' + cf.scriptId + ':' + cf.lineNumber;
}

// For eval'd meta-compiler fragments with stored sources: find the enclosing
// `window.<Cls>.prototype.<method> = ...` (or static) assignment above the line.
function methodAtLine(src, line0) {
  const lines = src.split('\n');
  const re = /window\.([A-Za-z_$][\w$]*)(\.prototype)?\.([A-Za-z_$][\w$]*)\s*=/;
  for (let i = Math.min(line0, lines.length - 1); i >= 0; i--) {
    const m = lines[i].match(re);
    if (m) return m[1] + (m[2] ? '.' : '.@') + m[3];
  }
  return null;
}

function labelOf(n) {
  const cf = n.callFrame;
  let where = '';
  const sm = scriptsMap[cf.scriptId];
  if (cf.url && cf.url.includes('profile-boot.js')) where = segmentFor(cf.lineNumber + 1) + ':' + (cf.lineNumber + 1);
  else if (cf.url) where = path.basename(cf.url).slice(0, 40) + ':' + (cf.lineNumber + 1);
  else if (sm && sm.src) {
    const meth = methodAtLine(sm.src, cf.lineNumber);
    where = meth ? '{' + meth + '}' : '[class ' + (sm.cls || '?') + ':' + (cf.lineNumber + 1) + ']';
  } else if (sm && sm.cls) where = '[class ' + sm.cls + ':' + (cf.lineNumber + 1) + ']';
  else where = '[eval ' + cf.scriptId + ']';
  return (cf.functionName || '(anonymous)') + ' ' + where;
}

function bucketOf(n) {
  const cf = n.callFrame;
  const fn = cf.functionName;
  if (fn === '(garbage collector)') return 'gc';
  if (fn === '(program)' || fn === '(idle)' || fn === '(root)') return 'idle/program';
  if (cf.url && cf.url.includes('profile-boot.js')) {
    const seg = segmentFor(cf.lineNumber + 1);
    return seg === 'FizzygumBoot' ? 'boot-bundle(compiler,boot)' : seg;
  }
  if (cf.url && cf.url.includes('fizzygum-boot-min')) return 'boot-bundle-min(SW+boot)';
  if (cf.url) return 'other-url';
  const sm = scriptsMap[cf.scriptId];
  if (sm && sm.cls) {
    if (/^(Automator|SystemTest|Macro)/.test(sm.cls)) return 'harness(' + 'Automator/Macro' + ')';
    return 'fizzygum-classes';
  }
  return 'eval-unknown';
}

// self time per node via samples+timeDeltas (µs)
const selfUs = new Map();
const samples = profile.samples || [];
const deltas = profile.timeDeltas || [];
for (let i = 0; i < samples.length; i++) {
  const dt = deltas[i] > 0 ? deltas[i] : 0;
  selfUs.set(samples[i], (selfUs.get(samples[i]) || 0) + dt);
}
const totalUs = [...selfUs.values()].reduce((a, b) => a + b, 0);

// per-function self, bucket totals
const fnSelf = new Map(); // key -> {us, label, bucket}
const bucketSelf = new Map();
for (const n of nodes) {
  const us = selfUs.get(n.id) || 0;
  if (!us) continue;
  const b = bucketOf(n);
  bucketSelf.set(b, (bucketSelf.get(b) || 0) + us);
  const k = keyOf(n);
  const e = fnSelf.get(k) || { us: 0, label: labelOf(n), bucket: b };
  e.us += us;
  fnSelf.set(k, e);
}

// total time per function: for each sampled leaf, credit every distinct
// function key on the ancestor chain once
const fnTotal = new Map();
const chainCache = new Map(); // nodeId -> array of distinct fn keys on chain
function chainOf(id) {
  if (chainCache.has(id)) return chainCache.get(id);
  const keys = [];
  const seen = new Set();
  let cur = id;
  while (cur !== undefined) {
    const n = byId.get(cur);
    if (!n) break;
    const k = keyOf(n);
    if (!seen.has(k)) { seen.add(k); keys.push(k); }
    cur = parent.get(cur);
  }
  chainCache.set(id, keys);
  return keys;
}
for (let i = 0; i < samples.length; i++) {
  const dt = deltas[i] > 0 ? deltas[i] : 0;
  if (!dt) continue;
  for (const k of chainOf(samples[i])) fnTotal.set(k, (fnTotal.get(k) || 0) + dt);
}

function ms(us) { return (us / 1000).toFixed(0); }
let idleUs = 0;
for (const n of nodes) {
  const fn = n.callFrame.functionName;
  if (fn === '(idle)' || fn === '(program)' || fn === '(root)') idleUs += selfUs.get(n.id) || 0;
}
const busyUs = totalUs - idleUs;
function pct(us) { return ((100 * us) / totalUs).toFixed(1) + '%'; }
function bpct(us) { return ((100 * us) / busyUs).toFixed(1) + '%'; }

console.log('== total sampled: ' + ms(totalUs) + ' ms over ' + samples.length + ' samples; BUSY ' + ms(busyUs) + ' ms (' + pct(busyUs) + ' of total) — busy-% shown as [b:x%]');
console.log('\n== buckets (self time):');
[...bucketSelf.entries()].sort((a, b) => b[1] - a[1]).forEach(([b, us]) => console.log('  ' + pct(us).padStart(6) + ' [b:' + bpct(us) + ']  ' + ms(us).padStart(7) + ' ms  ' + b));

console.log('\n== top ' + topN + ' by SELF time:');
[...fnSelf.entries()].sort((a, b) => b[1].us - a[1].us).slice(0, topN).forEach(([k, e]) => {
  console.log('  ' + pct(e.us).padStart(6) + ' [b:' + bpct(e.us) + ']  ' + ms(e.us).padStart(7) + ' ms  [' + e.bucket + ']  ' + e.label);
});

console.log('\n== top ' + topN + ' by TOTAL time (stack-attributed):');
const labelByKey = new Map();
for (const n of nodes) if (!labelByKey.has(keyOf(n))) labelByKey.set(keyOf(n), { label: labelOf(n), bucket: bucketOf(n) });
[...fnTotal.entries()].sort((a, b) => b[1] - a[1]).slice(0, topN).forEach(([k, us]) => {
  const e = labelByKey.get(k) || { label: k, bucket: '?' };
  if (e.label.startsWith('(root)') || e.label.startsWith('(program)')) return;
  console.log('  ' + pct(us).padStart(6) + '  ' + ms(us).padStart(7) + ' ms  [' + e.bucket + ']  ' + e.label);
});
