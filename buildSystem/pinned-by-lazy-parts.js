#!/usr/bin/env node
'use strict';
/*
 * pinned-by-lazy-parts.js — which CORE files are named ONLY by LAZY parts?
 *
 * Those files are in core for one reason: moving them into the part that wants them would have made
 * a cross-part edge that nothing ordered. `requires` (parts.json) orders it now, so this list IS the
 * work list for further extraction — and, since a lazy part's classes are absent from
 * js/pre-compiled.js, most of it is production image weight sitting in core for no reason.
 *
 * ⚠ A file named by an EAGER part, or by core, is NOT here and must not move: an eager part is in
 * the artifact from the first frame, so `requires` can only promise the target SHIPS, never that it
 * has ARRIVED. Those references need a guard or an await instead — see build-and-packaging.md §2.
 * ⚠ Comments and string literals are stripped before matching, exactly as check-part-edges.js does:
 * prose naming a class produced false "movable" verdicts in two separate arcs.
 *
 * Usage:  node buildSystem/pinned-by-lazy-parts.js [--list]
 */

const fs=require('fs'), path=require('path'), {execFileSync}=require('child_process');
const REPO=require('path').resolve(__dirname,'..');
const parts=JSON.parse(fs.readFileSync(path.join(REPO,'buildSystem/parts.json'),'utf8')).parts;
const shippable=execFileSync('python3',['-B','buildSystem/build.py','--list-shippable'],{cwd:REPO,encoding:'utf8'}).split('\n').filter(Boolean);
const d2p=new Map();
for(const[n,p]of Object.entries(parts)){if(n.startsWith('//'))continue;for(const d of p.dirs||[])d2p.set(path.posix.normalize(d),n);}
const own=r=>d2p.get(path.posix.normalize(path.posix.dirname(r)));
const lazy=n=>parts[n]&&parts[n].eager===false;
function code(l){let o='',q=null;for(let i=0;i<l.length;i++){const c=l[i];if(q){if(c==='\\'){i++;continue}if(c===q)q=null;continue}if(c==='"'||c==="'"){q=c;continue}if(c==='#')break;o+=c}return o}
const txt=new Map();
for(const r of shippable) if(own(r)) txt.set(r, fs.readFileSync(path.join(REPO,r),'utf8').split('\n').map(code).join('\n'));
const core=[...txt.keys()].filter(r=>own(r)==='core');
let onlyLazy=[], bytes=0;
for(const r of core){
  const cls=path.basename(r,'.coffee'), re=new RegExp('\\b'+cls+'\\b');
  const namers=[...txt.keys()].filter(o=>o!==r&&re.test(txt.get(o)));
  if(!namers.length) continue;
  if(namers.every(o=>own(o)!=='core'&&lazy(own(o)))){
    onlyLazy.push([r,[...new Set(namers.map(own))].join('+')]);
    bytes+=fs.statSync(path.join(REPO,r)).size;
  }
}
console.log(`${onlyLazy.length} core file(s), ${(bytes/1024).toFixed(1)} KB source, are named ONLY by LAZY parts.`);
const fs2=require('fs'),path2=require('path');
const cb=r=>fs2.readFileSync(path2.join(REPO,r),'utf8').split('\n').reduce((a,l)=>{const c=l.split('#')[0].replace(/\s+$/,'');return c.trim()?a+c.length+1:a},0);
const by={}; for(const[r,p]of onlyLazy){ (by[p]??={n:0,b:0}); by[p].n++; by[p].b+=cb(r); }
for(const[p,v]of Object.entries(by).sort((a,b)=>b[1].b-a[1].b)) console.log(`  ${p.padEnd(24)} ${String(v.n).padStart(3)} files  ${(v.b/1024).toFixed(1).padStart(6)} KB code`);
if(process.argv.includes('--list')){
  console.log('\n-- the files --');
  for(const[r,p]of onlyLazy.sort((a,b)=>a[1].localeCompare(b[1])||a[0].localeCompare(b[0])))
    console.log(`  ${p.padEnd(24)} ${r}`);
}
console.log('\nEach moves into the part that names it; where TWO lazy parts name it, one of them');
console.log('declares a parts.json `requires` on the other. Verify each grouping with');
console.log('`fg hypopart <files...>` BEFORE moving anything -- an inheritance edge means it is wrong.');
