#!/usr/bin/env node
'use strict';
/*
 * what-pins-core.js — WHY is each class in the boot image, and what would it take to get it out?
 *
 * THE CASE THIS EXISTS FOR. `DegreesConverterIconAppearance` is 9,479 bytes of vector art that
 * nothing draws except one icon inside the Examples folder, and it sat in production's
 * js/pre-compiled.js for as long as that folder existed. It was found BY EYE. No tool said so, and
 * the near-miss explains the gap: `pinned-by-lazy-parts.js` asks "are this class's namers ALL in
 * lazy parts", which is a ONE-LEVEL question about the partition as it stands. That art's namer was
 * `DegreesConverterIconWdgt`, in core; ITS namer was the app, then in an eager `authoring-launcher`
 * part. Two hops, one of them eager, and the question came back "must not move".
 *
 * WHAT THIS ASKS INSTEAD — reachability, not authorship. A class is in the image because something
 * on the BOOT PATH names it, so walk that path: start at src/boot/*, follow every reference that is
 * not behind a door, and see what you arrive at. Two answers fall out of the one walk, and the
 * second is the one that would have found the case above:
 *
 *   1. WHAT THE WALK NEVER REACHES — in the image, yet nothing at boot names it without first
 *      passing a lazy part's guard or await. Those are movable today, and the walk is TRANSITIVE, so
 *      it reports in one pass what `pinned-by-lazy-parts.js` only converges to over several
 *      move-rebuild-rerun rounds (48 files qualified, then 28 more, then 4, then 1).
 *
 *   2. WHAT THE WALK REACHES THROUGH A SINGLE CLASS — the DOMINATORS. If every boot path to a group
 *      of classes goes through one class, that class alone holds the whole group in the image, and
 *      the group's byte weight is what a door in front of it would be worth. `DegreesConverterApp`
 *      would have appeared here holding 9.6 KB of art it was the sole route to, which is exactly the
 *      shape a human reads as "why is that eager?" — and the answer, that an icon needs the app's
 *      NAME and never the app, was a protocol change rather than a partition move.
 *
 * ⚠ THAT LAST POINT IS THE HONEST LIMIT, and it is worth stating rather than discovering. NO static
 * tool over the old partition could have called that art MOVABLE: the app really was eager, so the
 * art really was boot-reachable, and "pinned" was the correct verdict. What a tool can do is show
 * WHAT a pinning costs, ranked, so the design question gets asked where it is worth asking. Section
 * 1 is a work list. Section 2 is a list of questions, and its entries are not defects.
 *
 * ⛔ IT IS NOT A DECISION-MAKER. A class may be dominated by one route and still belong in core on
 * merits, and moving anything at all is a separate decision — verify a grouping with `fg hypopart`
 * before touching it, and MEASURE with `fg fingerprint`, because four slices in a row missed their
 * byte estimate in both directions (see build-and-packaging.md §5).
 *
 * WHAT COUNTS AS A DOOR is not this file's opinion: `lib/part-edge-scan.js` is the build gate's own
 * guard/await classifier, and this asks it. A site is behind a door when its guarded-part set is
 * non-empty and contains no part that is EAGER in the profile being analysed — an `if Automator?`
 * on a production tree is a dead branch, and a `whenAllLoaded ["maps"], ->` is a fetch that has not
 * happened at boot. Comments and string literals are stripped first, because prose naming a class
 * produced false "movable" verdicts in two separate arcs, and a class NAME as data is the sanctioned
 * indirection for a lazy part.
 *
 * ⚠ The four icons that legitimately cannot move — TypewriterIconWdgt, SimpleSlideIconWdgt,
 * DashboardsIconWdgt, GenericShortcutIconWdgt — are drawn by desktop icons and by
 * FolderWindowWdgt/BinOpenerWdgt at boot, so the walk must REACH all four. It is checked:
 * `--selftest` asserts it, alongside planted classes that prove the door test can go both ways.
 *
 * Usage:
 *   node buildSystem/what-pins-core.js [--profile homepage] [--list] [--roots N]
 *   node buildSystem/what-pins-core.js --why <ClassName>     # a shortest boot path to it
 *   node buildSystem/what-pins-core.js --selftest            # prove it can be wrong
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { codePartOf, guardedPartsPerLine } = require('./lib/part-edge-scan');

const REPO = path.resolve(__dirname, '..');
const BOOT_DIRS = ['src/boot', 'src/boot/extensions'];
const BOOT = '«boot»';

const argv = process.argv.slice(2);
const flag = (name, dflt) => {
  const i = argv.indexOf(name);
  return i >= 0 && argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[i + 1] : dflt;
};
const PROFILE = flag('--profile', 'homepage');
const WHY = flag('--why', null);
const TOP = parseInt(flag('--roots', '25'), 10);
const LIST = argv.includes('--list');
const SELFTEST = argv.includes('--selftest');

function die(msg) { console.error('what-pins-core: ' + msg); process.exit(2); }

// ---- the partition, the profile, and which parts are in the EAGER image ----------------------
const parts = JSON.parse(fs.readFileSync(path.join(REPO, 'buildSystem/parts.json'), 'utf8')).parts;
let profile;
try {
  profile = JSON.parse(fs.readFileSync(path.join(REPO, `buildSystem/profiles/${PROFILE}.json`), 'utf8'));
} catch (e) { die(`no such profile '${PROFILE}': ${e.message}`); }

const partNames = Object.keys(parts).filter(n => !n.startsWith('//'));
const shipped = profile.parts === 'all' ? new Set(partNames) : new Set(profile.parts);
const isLazy = (p) => p !== 'core' && !!parts[p] && parts[p].eager === false;
// The eager image is core plus every EAGER part this profile ships. On `homepage` every non-core
// part is lazy, so the image is exactly core -- which is why homepage and lean emit a byte-identical
// js/pre-compiled.js, and why a packaging change can only be measured by fingerprinting ONE profile.
const inImage = (p) => shipped.has(p) && !isLazy(p);

let shippable;
try {
  shippable = execFileSync('python3', ['-B', 'buildSystem/build.py', '--list-shippable'],
    { cwd: REPO, encoding: 'utf8' }).split('\n').filter(Boolean);
} catch (e) { die('build.py --list-shippable failed: ' + e.message); }

const dirToPart = new Map();
for (const p of partNames) for (const d of parts[p].dirs || []) dirToPart.set(path.posix.normalize(d), p);
const partOfFile = (rel) => dirToPart.get(path.posix.normalize(path.posix.dirname(rel)));

// className -> part, for every NON-core part: this is what the guard classifier keys off.
const ownerOfClass = new Map();
for (const rel of shippable) {
  const p = partOfFile(rel);
  if (p && p !== 'core') ownerOfClass.set(path.basename(rel, '.coffee'), p);
}
if (!ownerOfClass.size) die('no part-owned classes found — is parts.json only core?');

// ⚠⚠ ONE LEVEL, NOT THE CLOSURE. `requires` means three different things depending on who is asking
// — non-transitive for check-part-edges (its `declaredRequires` is a direct read of the array),
// transitive for PartsRegistry's load ORDERING, and a fixpoint for buildProfile's INCLUSION check.
// The binding constraint on a move is the strictest of the three, which is the gate: `dev-tools`
// requires `demos` requires `authoring`, and that does NOT let dev-tools name an authoring class.
// Using the closure here quietly reported a 1.8 KB move as free when it is not.
const directRequires = (p) => new Set([p, ...(((parts[p] || {}).requires) || [])]);

const declaredPartsIn = (text) => {
  const m = /^\s*requiredParts\s*:\s*\[([^\]]*)\]/m.exec(text);
  return m ? (m[1].match(/["']([^"']+)["']/g) || []).map(q => q.slice(1, -1)) : [];
};

/*
 * Build the reference graph.
 *
 * `inject` is what makes --selftest possible without writing a file into src/: it adds synthetic
 * image files and synthetic boot lines to this one run, so the door test can be exercised in both
 * directions on planted input rather than trusted.
 */
function buildGraph(inject) {
  inject = inject || {};
  const files = [];                       // {rel, cls, part, lines, guards, behindDoor}
  const clsToFile = new Map();

  const addFile = (rel, text, part) => {
    const cls = path.basename(rel, '.coffee');
    const lines = text.split('\n');
    const guards = guardedPartsPerLine(lines, ownerOfClass, parts);
    // A class-level `requiredParts: [...]` is an await covering the whole file (the inherited
    // `launch` awaits it before building anything), so the gate reads it and so does this.
    const declaredParts = declaredPartsIn(text);
    const f = { rel, cls, part, lines, guards, code: lines.map(codePartOf),
                behindDoor: declaredParts.length > 0 && !declaredParts.some(inImage),
                doorParts: declaredParts.filter(p => !inImage(p)) };
    files.push(f);
    clsToFile.set(cls, f);
    return f;
  };

  // EVERY shippable source is read, not just the image's. A file OUTSIDE the image is scanned for a
  // different reason: it cannot put anything ON the boot path, but it is a DOOR that names things,
  // and that is the half `pinned-by-lazy-parts.js` gets right and a naive reachability walk gets
  // catastrophically wrong -- skip them and every class only a part names reads back as "named by
  // nothing at all", which is true of the image and useless as an answer.
  const outside = [];
  for (const rel of shippable) {
    const part = partOfFile(rel);
    if (!part) continue;
    if (inImage(part)) addFile(rel, fs.readFileSync(path.join(REPO, rel), 'utf8'), part);
    else outside.push({ rel, part });
  }
  for (const [rel, o] of Object.entries(inject.outsideFiles || {})) outside.push({ rel, part: o.part, text: o.text });
  for (const [rel, text] of Object.entries(inject.files || {})) addFile(rel, text, 'core');

  // Longest-first so a name that is a suffix of another reads tidily; \b does the real work.
  const names = [...clsToFile.keys()].sort((a, b) => b.length - a.length);
  const pat = new Map(names.map(n => [n, new RegExp('\\b' + n + '\\b')]));

  // A site is behind a DOOR when it is guarded/awaited for parts NONE of which is in this image.
  const doorPartsAt = (f, i) => {
    if (f.behindDoor) return f.doorParts;
    const g = [...f.guards[i]];
    return g.length && !g.some(inImage) ? g : null;
  };

  const live = new Map();                 // from -> Map(to -> {file, line})
  const doors = new Map();                // to   -> Set(part) : which lazy doors DO name it
  // ⚠⚠ AND THE SITES, not just the parts. Whether a door's reference SURVIVES a move is a per-SITE
  // question, because check-part-edges accepts THREE different things: the site being intra-part, a
  // parts.json `requires`, and a class-level `requiredParts` covering that file. Modelling only the
  // second told me to add three `requires` edges to the example-* doors — which would have reversed
  // a ⛔ recorded in parts.json, and which the build then proved unnecessary, because every one of
  // those app classes already declares requiredParts:["authoring"]. Advice that overstates the cost
  // of a move is how a work list stops being used.
  const doorSites = new Map();            // to   -> [{part, satisfies:Set<part>}]
  const addSite = (n, part, satisfies) => {
    if (!doorSites.has(n)) doorSites.set(n, []);
    doorSites.get(n).push({ part, satisfies });
  };
  const edge = (from, to, where) => {
    if (from === to) return;
    if (!live.has(from)) live.set(from, new Map());
    if (!live.get(from).has(to)) live.get(from).set(to, where);
  };

  const scanLines = (fromNode, f) => {
    for (let i = 0; i < f.lines.length; i++) {
      const code = f.code[i];
      if (!code.trim()) continue;
      const door = doorPartsAt(f, i);
      for (const n of names) {
        if (!pat.get(n).test(code)) continue;
        if (door) {
          if (!doors.has(n)) doors.set(n, new Set());
          for (const p of door) doors.get(n).add(p);
          // an in-image site behind a guard/await can only legally name the parts it named there
          addSite(n, f.part, new Set(door));
        } else {
          edge(fromNode, n, { rel: f.rel, line: i + 1, text: f.lines[i].trim() });
        }
      }
    }
  };

  for (const f of files) scanLines(f.cls, f);

  // A file outside the image is ITSELF a door: nothing it names is on the boot path, whether the
  // reference is guarded or not, because the file is not there at boot. Every image class it names
  // is credited to that part.
  for (const { rel, part, text: injected } of outside) {
    const text = injected != null ? injected : fs.readFileSync(path.join(REPO, rel), 'utf8');
    // what this FILE may legally name: its own part, whatever that part `requires`, and whatever
    // its class declares in requiredParts (which its inherited `launch` awaits — the declaration IS
    // the await, so check-part-edges honours it for the whole file)
    const satisfies = new Set([...directRequires(part), ...declaredPartsIn(text)]);
    for (const line of text.split('\n').map(codePartOf)) {
      if (!line.trim()) continue;
      for (const n of names) {
        if (!pat.get(n).test(line)) continue;
        if (!doors.has(n)) doors.set(n, new Set());
        doors.get(n).add(part);
        addSite(n, part, satisfies);
      }
    }
  }

  // ROOTS: src/boot/* is compiled at build time and always present, so whatever it names unguarded
  // is in the image by definition. Everything else is reached THROUGH one of these.
  for (const d of BOOT_DIRS) {
    const abs = path.join(REPO, d);
    if (!fs.existsSync(abs)) continue;
    for (const fn of fs.readdirSync(abs)) {
      if (!fn.endsWith('.coffee')) continue;
      const rel = path.posix.join(d, fn);
      const lines = fs.readFileSync(path.join(REPO, rel), 'utf8').split('\n');
      scanLines(BOOT, { rel, lines, code: lines.map(codePartOf),
                        guards: guardedPartsPerLine(lines, ownerOfClass, parts),
                        behindDoor: false, doorParts: [] });
    }
  }
  for (const line of inject.bootLines || []) {
    scanLines(BOOT, { rel: '«injected»', lines: [line], code: [codePartOf(line)],
                      guards: [new Set()], behindDoor: false, doorParts: [] });
  }

  // ---- reachability ---------------------------------------------------------------------------
  const reached = new Set([BOOT]);
  const via = new Map();                  // to -> {from, where}   (BFS tree, for --why)
  const queue = [BOOT];
  while (queue.length) {
    const n = queue.shift();
    for (const [to, where] of (live.get(n) || new Map())) {
      if (reached.has(to)) continue;
      reached.add(to); via.set(to, { from: n, where }); queue.push(to);
    }
  }
  return { files, clsToFile, live, doors, doorSites, reached, via };
}

// ---- weight ----------------------------------------------------------------------------------
// Two numbers, because they disagree and the disagreement is the point: the image cost tracks CLASS
// COUNT at least as much as code bytes (54-class `authoring` took 1.65x as much off the image as
// 4-class `maps` for the same source bytes), and comment bytes never reach a minified image at all.
const weightOf = (f) => {
  let code = 0;
  for (const l of f.lines) { const c = l.split('#')[0].replace(/\s+$/, ''); if (c.trim()) code += c.length + 1; }
  return { bytes: f.lines.join('\n').length, code };
};

// ---- dominators (Cooper-Harvey-Kennedy, iterative) --------------------------------------------
// idom[n] = the class every boot path to n passes through. Its subtree weight is what a door in
// front of it would be worth: nothing else reaches any of it.
function dominators(live, reached) {
  const nodes = [...reached].filter(n => n !== BOOT);
  const order = [];                       // reverse postorder from BOOT
  const seen = new Set([BOOT]);
  (function dfs(n) {
    for (const to of (live.get(n) || new Map()).keys()) {
      if (seen.has(to) || !reached.has(to)) continue;
      seen.add(to); dfs(to);
    }
    order.push(n);
  })(BOOT);
  order.reverse();
  const rpo = new Map(order.map((n, i) => [n, i]));
  const preds = new Map(nodes.map(n => [n, []]));
  for (const [from, tos] of live) {
    if (!reached.has(from)) continue;
    for (const to of tos.keys()) if (preds.has(to)) preds.get(to).push(from);
  }
  const idom = new Map([[BOOT, BOOT]]);
  const intersect = (a, b) => {
    while (a !== b) {
      while (rpo.get(a) > rpo.get(b)) a = idom.get(a);
      while (rpo.get(b) > rpo.get(a)) b = idom.get(b);
    }
    return a;
  };
  let changed = true;
  while (changed) {
    changed = false;
    for (const n of order) {
      if (n === BOOT) continue;
      let neu = null;
      for (const p of preds.get(n) || []) {
        if (!idom.has(p)) continue;
        neu = neu === null ? p : intersect(neu, p);
      }
      if (neu !== null && idom.get(n) !== neu) { idom.set(n, neu); changed = true; }
    }
  }
  return idom;
}

// idom -> the dominator forest, plus each node's subtree weight.
function dominatorSubtrees(g) {
  const idom = dominators(g.live, g.reached);
  const kids = new Map();
  for (const [n, d] of idom) {
    if (n === BOOT) continue;
    if (!kids.has(d)) kids.set(d, []);
    kids.get(d).push(n);
  }
  const subtree = new Map();
  (function weigh(n) {
    let bytes = 0, code = 0, count = 0;
    if (n !== BOOT && g.clsToFile.has(n)) { const w = weightOf(g.clsToFile.get(n)); bytes = w.bytes; code = w.code; count = 1; }
    for (const k of kids.get(n) || []) { const s = weigh(k); bytes += s.bytes; code += s.code; count += s.count; }
    const s = { bytes, code, count };
    subtree.set(n, s);
    return s;
  })(BOOT);
  return { idom, kids, subtree };
}

// ---- report -----------------------------------------------------------------------------------
// Where can this group of classes live? A home is viable when EVERY site that names any of them
// would still be legal after the move — which check-part-edges grants three different ways: the
// site is intra-part, its part `requires` the home, or its class declares the home in
// `requiredParts`. All three are folded into each site's `satisfies` set at scan time.
// ⚠⚠ What is NOT folded in: `requires` never excuses an EAGER door. An eager part is in the
// artifact from the first frame, so the declaration can only promise the home SHIPS, never that it
// has ARRIVED — an eager->lazy reference still needs a guard where it stands. Adding a `requires`
// is not free either: it ORDERS a lazy load, so the home is fetched in full before the door.
function homeFor(classes, doorSet, doorSites) {
  const d = [...doorSet];
  // A home this profile does not ship DELETES the class from the artifact rather than deferring it.
  // That is only sound when no door ships either (the class is wholly dev-only material); otherwise
  // a shipped door would be left pointing at something production no longer has.
  const anyShipped = d.some(p => shipped.has(p));
  let best = null;
  for (const x of d) {
    if (anyShipped && !shipped.has(x)) continue;
    const blocked = new Set();
    for (const c of classes) for (const s of doorSites.get(c) || []) {
      if (s.part !== x && !s.satisfies.has(x)) blocked.add(s.part);
    }
    const needsRequires = [...blocked].filter(isLazy);
    const needsGuard = [...blocked].filter(p => !isLazy(p));
    const rank = [needsGuard.length * 10 + needsRequires.length, shipped.has(x) ? 0 : 1];
    if (!best || rank[0] < best.rank[0] || (rank[0] === best.rank[0] && rank[1] < best.rank[1])) {
      best = { part: x, needsRequires, needsGuard, rank };
    }
  }
  return best;
}

function analyse(inject) {
  const g = buildGraph(inject);
  const imageClasses = [...g.clsToFile.keys()];
  const candidates = imageClasses.filter(c => !g.reached.has(c));

  // ⭐ THE CLUSTER FIXPOINT. A candidate's own references are not on the boot path either, so
  // whatever it names inherits its doors: move a *IconWdgt and its *IconAppearance goes with it.
  // Without this pass an appearance whose only namer is an unreachable icon reads back as "named by
  // nothing at all", and the pair that has to move TOGETHER looks like two unrelated entries. This
  // is the same fixpoint that grew slice 4 from 48 files to 81 -- computed here in one pass instead
  // of converged over four move-rebuild-rerun rounds.
  const cand = new Set(candidates);
  for (let changed = true; changed;) {
    changed = false;
    for (const from of cand) {
      const src = g.doors.get(from);
      if (!src || !src.size) continue;
      for (const to of (g.live.get(from) || new Map()).keys()) {
        if (!cand.has(to)) continue;
        if (!g.doors.has(to)) g.doors.set(to, new Set());
        const dst = g.doors.get(to);
        for (const p of src) if (!dst.has(p)) { dst.add(p); changed = true; }
        // the SITES travel with the doors: whatever constrains where `from` may live constrains
        // `to` identically, since `to` is only reachable through it
        if (!g.doorSites.has(to)) g.doorSites.set(to, []);
        const at = g.doorSites.get(to), seen = new Set(at.map(s => s.part));
        for (const s of g.doorSites.get(from) || []) if (!seen.has(s.part)) { at.push(s); seen.add(s.part); }
      }
    }
  }
  return { g, imageClasses, candidates };
}

if (SELFTEST) {
  // ⚠ A tool that cannot be wrong is worthless. Three plants, each aimed at the ONE axis this can be
  // wrong on -- does it tell a door from a plain reference -- plus the four icons that must stay.
  const MUST_REACH = ['TypewriterIconWdgt', 'SimpleSlideIconWdgt', 'DashboardsIconWdgt', 'GenericShortcutIconWdgt'];
  let bad = 0;
  const ok = (cond, msg) => { console.log(`  ${cond ? '[PASS]' : '[FAIL]'} ${msg}`); if (!cond) bad++; };

  const base = analyse();
  for (const n of MUST_REACH) {
    ok(base.g.clsToFile.has(n) && base.g.reached.has(n),
      `${n} is REACHED from boot (drawn by a desktop icon / folder chrome — it may never be proposed)`);
  }

  const plantBody = (ref) => [
    'class PlantHostWdgt extends Widget',
    '  aMethod: ->', ref,
  ].join('\n');

  // (a) named ONLY from inside a lazy part's await -> must be a candidate, with that door named
  const behind = analyse({
    files: { 'src/PlantHostWdgt.coffee': plantBody(
      '    world.parts.whenAllLoaded ["maps"], ->\n      new PlantedOrphanWdgt'),
             'src/PlantedOrphanWdgt.coffee': 'class PlantedOrphanWdgt extends Widget\n' },
    bootLines: ['    new PlantHostWdgt'],
  });
  ok(behind.candidates.includes('PlantedOrphanWdgt'),
    'a class named ONLY inside `whenAllLoaded ["maps"]` is a CANDIDATE');
  ok([...(behind.g.doors.get('PlantedOrphanWdgt') || [])].join() === 'maps',
    "...and its door is reported as 'maps'");

  // (b) the SAME reference, unguarded -> must NOT be a candidate. This is the half that fails if the
  //     scanner were to treat every reference as a door (which would make every class movable).
  const plain = analyse({
    files: { 'src/PlantHostWdgt.coffee': plantBody('    new PlantedOrphanWdgt'),
             'src/PlantedOrphanWdgt.coffee': 'class PlantedOrphanWdgt extends Widget\n' },
    bootLines: ['    new PlantHostWdgt'],
  });
  ok(!plain.candidates.includes('PlantedOrphanWdgt'),
    'the same reference UNGUARDED is NOT a candidate (the door test decides, not the reference)');

  // (c) a reference that exists only in a COMMENT is not a reference at all
  const prose = analyse({
    files: { 'src/PlantHostWdgt.coffee': plantBody('    # see PlantedOrphanWdgt for the real one'),
             'src/PlantedOrphanWdgt.coffee': 'class PlantedOrphanWdgt extends Widget\n' },
    bootLines: ['    new PlantHostWdgt'],
  });
  ok(prose.candidates.includes('PlantedOrphanWdgt'),
    'a class named only in PROSE is still a candidate (comments are stripped)');

  // (d) SECTION 2's claim, which is the novel one: "sole route" must stop being true the moment a
  //     SECOND route exists. TypewriterIconWdgt is reached from one line of createDesktop and solely
  //     routes its own appearance; name that appearance from boot and the pair must break in two.
  // (e) THE COST OF A MOVE, which is where this was wrong once. A door that declares
  //     `requiredParts: ["authoring"]` may already name an authoring class — check-part-edges says
  //     so (rule 7: the declaration IS the await). Modelling only parts.json `requires` made it
  //     demand three edges on the example-* doors, each of which carries an explicit ⛔ against
  //     exactly that, and the build then proved all three unnecessary.
  const orphan = { 'src/PlantedOrphanWdgt.coffee': 'class PlantedOrphanWdgt extends Widget\n' };
  const namedBy = (decl) => analyse({
    files: orphan,
    outsideFiles: {
      'src/authoring/PlantAuthoringWdgt.coffee': { part: 'authoring', text: '  new PlantedOrphanWdgt\n' },
      'src/examples/slide/PlantDoorApp.coffee': { part: 'example-slide', text: decl + '  new PlantedOrphanWdgt\n' },
    },
  });
  const homeOf = (r) => homeFor(['PlantedOrphanWdgt'], r.g.doors.get('PlantedOrphanWdgt'), r.g.doorSites);
  const declared = homeOf(namedBy('  requiredParts: ["authoring"]\n'));
  const bare = homeOf(namedBy(''));
  ok(declared.part === 'authoring' && declared.needsRequires.length === 0,
    "a door declaring requiredParts:[\"authoring\"] needs NO parts.json edge to name an authoring class");
  ok(bare.part === 'authoring' && bare.needsRequires.join() === 'example-slide',
    '...and the same door WITHOUT that declaration does need one (the control)');

  // (f) `requires` is ONE LEVEL for the gate. dev-tools requires demos requires authoring, and that
  //     chain must NOT read as permission for dev-tools to name an authoring class.
  const chained = homeOf(analyse({
    files: orphan,
    outsideFiles: {
      'src/authoring/PlantAuthoringWdgt.coffee': { part: 'authoring', text: '  new PlantedOrphanWdgt\n' },
      'src/dev-tools/PlantDevWdgt.coffee': { part: 'dev-tools', text: '  new PlantedOrphanWdgt\n' },
    },
  }));
  ok(chained.needsGuard.join() === 'dev-tools',
    'a transitive requires chain (dev-tools -> demos -> authoring) does NOT satisfy the gate');

  const soleBefore = dominatorSubtrees(base.g).subtree.get('TypewriterIconWdgt');
  const second = analyse({ bootLines: ['    new TypewriterIconAppearance'] });
  const soleAfter = dominatorSubtrees(second.g).subtree.get('TypewriterIconWdgt');
  ok(soleBefore.count === 2 && soleAfter.count === 1,
    `a SECOND boot route to TypewriterIconAppearance drops the sole-route subtree ` +
    `${soleBefore.count} -> ${soleAfter.count} (dominance, not mere reachability)`);

  console.log(bad ? `\nSELFTEST FAILED (${bad})` : '\nSELFTEST OK');
  process.exit(bad ? 1 : 0);
}

const { g, imageClasses, candidates } = analyse();

if (WHY) {
  if (!g.clsToFile.has(WHY)) die(`'${WHY}' is not a class in the ${PROFILE} image`);
  if (!g.reached.has(WHY)) {
    const d = [...(g.doors.get(WHY) || [])];
    console.log(`${WHY} is NOT reached from boot. Doors that name it: ${d.join(', ') || '(none at all)'}`);
    process.exit(0);
  }
  const chain = [];
  for (let n = WHY; n !== BOOT; n = g.via.get(n).from) chain.unshift({ n, w: g.via.get(n).where });
  console.log(`${BOOT}`);
  for (const { n, w } of chain) console.log(`  -> ${n}\n       ${w.rel}:${w.line}  ${w.text}`);
  process.exit(0);
}

const tot = (list) => list.reduce((a, c) => {
  const w = weightOf(g.clsToFile.get(c)); a.bytes += w.bytes; a.code += w.code; return a;
}, { bytes: 0, code: 0 });
const kb = (n) => (n / 1024).toFixed(1);

const all = tot(imageClasses), cand = tot(candidates);
console.log(`what-pins-core — profile '${PROFILE}': ${imageClasses.length} classes in the eager image ` +
            `(${kb(all.bytes)} KB source, ${kb(all.code)} KB code)`);
console.log(`  reached from src/boot without passing a lazy door: ${imageClasses.length - candidates.length}`);
console.log(`  NOT reached — movable today: ${candidates.length} (${kb(cand.code)} KB code)\n`);

// ---- 1. candidates ---------------------------------------------------------------------------
console.log('== 1. IN THE IMAGE, YET NO BOOT PATH REACHES THEM ==');
if (!candidates.length) {
  console.log('  (none — every class in the image is named from the boot path without a door in between)');
} else {
  const byDoor = new Map();
  // A part this profile does not ship at all is marked `*`: moving a class there takes it off THIS
  // artifact, but it is a different decision from moving it behind a lazy door -- the class stops
  // existing in production rather than arriving late, so it has to be dev-only material on merits.
  for (const c of candidates) {
    const set = g.doors.get(c) || new Set();
    const d = [...set].sort().map(p => shipped.has(p) ? p : p + '*').join('+')
      || '(named by nothing at all)';
    if (!byDoor.has(d)) byDoor.set(d, { set, cs: [] });
    byDoor.get(d).cs.push(c);
  }
  for (const [d, { set, cs }] of [...byDoor].sort((a, b) => tot(b[1].cs).code - tot(a[1].cs).code)) {
    const w = tot(cs);
    const h = set.size > 1 ? homeFor(cs, set, g.doorSites) : null;
    const cost = !h ? [] : [
      h.needsRequires.length ? `${h.needsRequires.map(m => `'${m}'`).join('+')} declare requires` : null,
      h.needsGuard.length ? `EAGER ${h.needsGuard.map(m => `'${m}'`).join('+')} guard the site` : null,
    ].filter(Boolean);
    const home = !h ? '' : cost.length === 0
      ? `   -> '${h.part}' — every other door already requires it`
      : `   -> '${h.part}' iff ${cost.join(' AND ')}`;
    console.log(`  ${d.padEnd(44)} ${String(cs.length).padStart(3)} class(es)  ${kb(w.code).padStart(6)} KB code${home}`);
    if (LIST) for (const c of cs.sort()) console.log(`      ${g.clsToFile.get(c).rel}`);
  }
  console.log(`\n  * = a part '${PROFILE}' does not ship (a move there deletes it from this artifact,`);
  console.log('      rather than deferring it — only right for genuinely dev-only material).');
  console.log('  A single door means it moves into that part. TWO doors mean one of them declares a');
  console.log('  parts.json `requires` on the other, or it stays. Verify with `fg hypopart` first --');
  console.log('  an inheritance edge across the boundary means the grouping is wrong.');
}

// ---- 2. dominators ---------------------------------------------------------------------------
const { kids, subtree } = dominatorSubtrees(g);

// How many DISTINCT classes name it. This is the column that separates the two kinds of sole route:
// `Widget` dominates 27 classes and is named from 80 places -- structural, and no door will ever go
// in front of it. `DegreesConverterApp` dominated 2 and was named from one line of createDesktop,
// which is the shape worth reading. Weight alone puts the unactionable ones on top.
const refCount = new Map();
for (const [from, tos] of g.live) {
  if (!g.reached.has(from)) continue;
  for (const to of tos.keys()) refCount.set(to, (refCount.get(to) || 0) + 1);
}
const ranked = [...subtree].filter(([n, s]) => n !== BOOT && s.count > 1)
  .sort((a, b) => b[1].code - a[1].code).slice(0, TOP);
const fullSubtree = (n, out) => { for (const k of kids.get(n) || []) { out.push(k); fullSubtree(k, out); } return out; };

console.log(`\n== 2. SOLE ROUTES: every boot path to these classes goes through ONE class ==`);
console.log('   Put a door in front of that class and its whole subtree leaves the image with it. This');
console.log('   is where the C-F art would have shown up: 2 classes, 9.6 KB, one naming site in');
console.log('   createDesktop. ⚠ These are QUESTIONS, not findings — a high `refs` means the class is');
console.log('   structural (Widget, WorldWdgt) and no door will ever go in front of it; a low one');
console.log('   means one decision holds that weight in the image, which is worth reading.\n');
console.log('   KB code  classes  refs   the sole route                     first reached at');
for (const [n, s] of ranked) {
  const w = g.via.get(n).where;
  console.log(`  ${kb(s.code).padStart(7)}  ${String(s.count).padStart(6)}  ${String(refCount.get(n) || 0).padStart(4)}   ` +
              `${n.padEnd(34)} ${w.rel}:${w.line}`);
  if (LIST) for (const k of fullSubtree(n, []).sort()) console.log(`               ${k}`);
}
console.log('\n`--why <Class>` prints a shortest boot path to any class. `--list` expands both sections.');
console.log('Then MEASURE: source bytes have missed the image delta in both directions four times running.');
