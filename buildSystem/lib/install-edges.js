'use strict';
/*
 * install-edges.js — WHICH MEMBERS A SUPPORT CLASS COPIES ONTO A CLASS IT DOES NOT OWN, read from the
 * boot edges themselves. ONE harvest for every gate that has to know (check-menu-actions.js RULE 1b,
 * check-part-edges.js's installed-member clauses): the same rule encoded twice drifts, which is the
 * lesson part-edge-scan.js's header records.
 *
 * THE MECHANISM IT READS. src/boot/globalFunctions.coffee's startWorld grafts test machinery onto core
 * prototypes at boot, one edge per line:
 *     WorldTestSupport.installOnto WorldWdgt  if WorldTestSupport?
 * and each support class carries its own `@installOnto`, which copies
 *   - every OWN PROTOTYPE member except `constructor` — methods AND plain fields alike, since
 *     `for own eachMemberName, eachMember of @prototype` does not ask which;
 *   - the STATICS named in `@staticMembersToInstall`, and only those (a blind sweep of a class
 *     function would also copy the meta-system's own bookkeeping over the target's).
 * So a member's presence on the target depends on the support class's PART shipping, not on the
 * target's: on a build without that part the member does not exist, whatever the target's own
 * source says.
 *
 * ⚠ THE SEMANTICS ARE READ, NOT ASSUMED. Each support class's `@installOnto` body is checked for the
 * two copies above (`of @prototype`, `@staticMembersToInstall`), and a body doing neither is an
 * operational error rather than an empty member set: a support class that installs some other way is
 * a shape this harvest does not model, and reading it as "installs nothing" would make every gate
 * built on it silently blind to that class.
 *
 * ⚠ THE STATICS LIST IS ASSERTED, BOTH WAYS. `@staticMembersToInstall` names, by hand, statics the
 * same class declares, and installOnto copies exactly the names it lists — so it can rot in two silent
 * directions: a static declared without being listed is never installed (the target simply lacks it),
 * and a listed name the class no longer declares installs `undefined`, which looks exactly like a
 * legitimate not-yet-set static (two of WorldTestSupport's ARE undefined until first use — so
 * "declared" means a class-body key, never a truthy value). For a support class that HAS the list, the
 * harvest therefore requires it to equal the class's own class-side keys minus the two that ARE the
 * mechanism (`@installOnto` and the list itself), and refuses otherwise: a listed name with no key is
 * a STALE_ALLOWLIST_ENTRY, a key the list leaves out an UNLISTED_STATIC, each naming the class and the
 * file. Everything a support class declares is there to be installed (its prototype is copied whole),
 * so a static it keeps for itself has no place on it. The rule lives HERE, once, so every gate built
 * on the harvest enforces it (check-menu-actions.js runs first in the build; check-part-edges.js
 * too): each reports the refusal and exits non-zero. A support class with no list installs no statics
 * and is not asked.
 *
 * `installEdges(roots)` returns one record per edge, in boot order:
 *     { support, target, supportFile, bootLine, members: [{ name, isStatic }] }
 * A support class whose file is absent (the sibling tests repo is not checked out) yields NO edge;
 * `harnessPresent(testsRepo)` is how a caller tells that case apart from "nothing is installed" and skips.
 */

const fs = require('fs');
const path = require('path');
const { coffeeMask } = require('./coffee-mask');
const { compiledFiles, harnessFiles, SRC, TESTS_REPO } = require('./source-files');

// `roots` is the gate's { src, testsRepo } (lib/source-files.js sourceRoots: default this umbrella's trees; a gate's
// --src= / --tests-repo= rails hand it planted copies). Boot's edges are read from src, the support classes from the
// compiled sources (compiledFiles: src and the tests repo's harness).
const bootGlobalsOf = (src) => path.join(src, 'boot/globalFunctions.coffee');
const BOOT_GLOBALS = bootGlobalsOf(SRC);

const EDGE = /\b([A-Za-z_]\w*)\.installOnto\s+([A-Za-z_]\w*)/g;
// a class-body key at the class-body indent: `name:` (prototype) or `@name:` (class side)
const CLASS_BODY_KEY = /^  (@?)([A-Za-z_$][\w$]*)\s*:(?!:)/;

const harnessPresent = (testsRepo = TESTS_REPO) => harnessFiles(testsRepo) !== undefined;

// One class per file, filename = class name, so a support class is found by its basename in either
// tree the build draws classes from.
const fileOfClassCache = new Map();   // src + testsRepo -> (class name -> file)
function fileOfClass(name, { src = SRC, testsRepo = TESTS_REPO } = {}) {
  const key = src + '\0' + testsRepo;
  if (!fileOfClassCache.has(key)) {
    const files = new Map();
    for (const p of compiledFiles({ src, testsRepo })) files.set(path.basename(p, '.coffee'), p);
    fileOfClassCache.set(key, files);
  }
  return fileOfClassCache.get(key).get(name);
}

// The members `support`'s own @installOnto copies onto `target`, by its own body. Lines inside a
// heredoc are skipped so a code sample in a string can never read as a class-body key. A
// @staticMembersToInstall that disagrees with the class's own class-side keys (see the header) adds
// one line per disagreement to `drift`; installEdges refuses once every edge has been read.
function installedMembersOf(support, target, file, drift) {
  const text = fs.readFileSync(file, 'utf8');
  const lines = text.split('\n');
  const masked = coffeeMask(text, file);   // lib/coffee-mask.js: a line inside a heredoc continues a literal
  const keys = [];                      // { name, isStatic, line }
  for (let i = 0; i < lines.length; i++) {
    if (masked[i].continuesLiteral) continue;
    const k = CLASS_BODY_KEY.exec(masked[i].code);
    if (k) keys.push({ name: k[2], isStatic: k[1] === '@', line: i });
  }

  const header = keys.find(k => k.isStatic && k.name === 'installOnto');
  if (!header) throw new Error(`${support} is installed at boot but declares no @installOnto (${file})`);
  const next = keys.find(k => k.line > header.line);
  const body = masked.slice(header.line + 1, next ? next.line : lines.length).map((l) => l.bare).join('\n');
  const copiesPrototype = /\bof\s+@prototype\b/.test(body);
  const copiesStatics = /@staticMembersToInstall\b/.test(body);
  if (!copiesPrototype && !copiesStatics) {
    throw new Error(`${support}.installOnto copies neither its prototype nor @staticMembersToInstall -- ` +
      `a shape buildSystem/lib/install-edges.js does not model (${file})`);
  }

  const members = [];
  if (copiesPrototype) {
    for (const k of keys) if (!k.isStatic && k.name !== 'constructor') members.push({ name: k.name, isStatic: false });
  }
  if (copiesStatics) {
    const list = keys.find(k => k.isStatic && k.name === 'staticMembersToInstall');
    if (list) {
      let listText = '';                  // its names are strings: read from the code view, the bracket from the bare one
      for (let j = list.line; j < lines.length; j++) {
        listText += masked[j].code + '\n';
        if (masked[j].bare.includes(']')) break;
      }
      const listed = (listText.slice(listText.indexOf('[')).match(/["']([^"']+)["']/g) || []).map(q => q.slice(1, -1));
      for (const name of listed) members.push({ name, isStatic: true });

      // the assertion (see the header): the list must be exactly the class-side keys that are not
      // the mechanism itself -- the @installOnto header and this list, both already found above
      const declared = keys.filter(k => k.isStatic && k !== header && k !== list);
      const where = `${file}:${list.line + 1}`;
      for (const name of listed) {
        if (declared.some(k => k.name === name)) continue;
        drift.push(`STALE_ALLOWLIST_ENTRY ${support}.staticMembersToInstall ${name} — ${support} declares ` +
          `no class-side key @${name}:, so installOnto copies undefined onto ${target} (the list: ${where})`);
      }
      for (const k of declared) {
        if (listed.includes(k.name)) continue;
        drift.push(`UNLISTED_STATIC ${support}.${k.name} — declared at ${file}:${k.line + 1} but absent ` +
          `from @staticMembersToInstall, so installOnto never copies it onto ${target} (the list: ${where})`);
      }
    }
  }
  return members;
}

function installEdges({ src = SRC, testsRepo = TESTS_REPO } = {}) {
  const bootGlobals = bootGlobalsOf(src);
  if (!fs.existsSync(bootGlobals)) return [];
  const edges = [];
  const drift = [];
  coffeeMask(fs.readFileSync(bootGlobals, 'utf8'), bootGlobals).forEach(({ bare: code }, i) => {
    let e;
    EDGE.lastIndex = 0;
    while ((e = EDGE.exec(code)) !== null) {
      const supportFile = fileOfClass(e[1], { src, testsRepo });
      if (!supportFile) continue;           // its repo is not checked out -- see harnessPresent()
      edges.push({ support: e[1], target: e[2], supportFile, bootLine: i + 1,
                   members: installedMembersOf(e[1], e[2], supportFile, drift) });
    }
  });
  if (drift.length) {
    throw new Error('a support class\'s @staticMembersToInstall disagrees with the statics it declares, ' +
      'and installOnto copies exactly the listed names (buildSystem/lib/install-edges.js):\n' +
      drift.map(line => '  ' + line).join('\n') + '\n' +
      'FIX: list every class-side key the support class declares, and delete every listed name it does not.');
  }
  return edges;
}

module.exports = { installEdges, harnessPresent, BOOT_GLOBALS };
