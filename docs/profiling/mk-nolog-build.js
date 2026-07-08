#!/usr/bin/env node
'use strict';
// Create shadow-build-nolog: identical to shadow-build but with the per-call
// debug console.log in SWCanvas Context2D.drawImage surgically removed
// (the {imageType: ...} argument-object construction is the real cost).
const fs = require('fs');
const path = require('path');
const SRC = path.resolve(process.argv[2] || '/tmp/fizzygum-profiling/shadow-build');
const DST = path.resolve(process.argv[3] || '/tmp/fizzygum-profiling/shadow-build-nolog');

fs.rmSync(DST, { recursive: true, force: true });
fs.mkdirSync(DST);
for (const l of ['js', 'icons', 'font-assets']) fs.symlinkSync(fs.readlinkSync(path.join(SRC, l)), path.join(DST, l));
fs.copyFileSync(path.join(SRC, 'worldWithSystemTestHarness.html'), path.join(DST, 'worldWithSystemTestHarness.html'));
fs.copyFileSync(path.join(SRC, 'segments.json'), path.join(DST, 'segments.json'));

let boot = fs.readFileSync(path.join(SRC, 'profile-boot.js'), 'utf8');
const marker = "console.log('Core drawImage called with:'";
const start = boot.indexOf(marker);
if (start < 0) { console.error('marker not found'); process.exit(1); }
// find the matching close of the console.log( ... ) call
let i = start + 'console.log'.length; // at '('
let depth = 0, end = -1;
for (; i < boot.length; i++) {
  const ch = boot[i];
  if (ch === '(') depth++;
  else if (ch === ')') { depth--; if (depth === 0) { end = i + 1; break; } }
}
if (end < 0) { console.error('unbalanced parens'); process.exit(1); }
if (boot[end] === ';') end++;
boot = boot.slice(0, start) + '/* drawImage debug log stripped for A/B */;' + boot.slice(end);
fs.writeFileSync(path.join(DST, 'profile-boot.js'), boot);
console.log('nolog build ready; removed ' + (end - start) + ' chars of log call');
