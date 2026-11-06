'use strict';
// what-pins-core-selftest.js — what-pins-core.js proved able to be wrong: the four icons the boot walk must reach,
// planted classes that show the door test going both ways (behind an await, unguarded, named only in prose), the
// cost-of-a-move cases (a requiredParts declaration, an eager door, a transitive requires chain), and dominance
// rather than mere reachability. Reads the real tree (~1 s). Run by buildSystem/run-selftests.js on every build.

const { analyse, dominatorSubtrees, homeFor, parts } = require('./what-pins-core');
const t = require('./lib/selftest-verdict').cases('what-pins-core');
// ⚠ A tool that cannot be wrong is worthless. Three plants, each aimed at the ONE axis this can be
// wrong on -- does it tell a door from a plain reference -- plus the four icons that must stay.
// hand-list-sanctioned: what-pins-core-selftest.js FAILs (and so the build) on a name here no src file
// declares or the boot walk no longer reaches
const MUST_REACH = ['TypewriterIconWdgt', 'SimpleSlideIconWdgt', 'DashboardsIconWdgt', 'GenericShortcutIconWdgt'];
const ok = (cond, msg) => t.check(cond, msg);

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

// (f) An EAGER door's `requires` on a LAZY home does not satisfy the gate: dev-tools (eager)
//     requires authoring (lazy) directly, but runs from the first frame, so its site still needs
//     a guard. The control is a LAZY door with the same direct `requires` (demos), which needs
//     nothing — so the case fails for the eager-owner discount and nothing else.
const namedFrom = (part, rel) => homeOf(analyse({
  files: orphan,
  outsideFiles: {
    'src/authoring/PlantAuthoringWdgt.coffee': { part: 'authoring', text: '  new PlantedOrphanWdgt\n' },
    [rel]: { part, text: '  new PlantedOrphanWdgt\n' },
  },
}));
const eagerDoor = namedFrom('dev-tools', 'src/dev-tools/PlantDevWdgt.coffee');
const lazyDoor = namedFrom('demos', 'src/demos/PlantDemoWdgt.coffee');
ok(eagerDoor.part === 'authoring' && eagerDoor.needsGuard.join() === 'dev-tools',
  "an EAGER door's direct requires on a LAZY home (dev-tools -> authoring) does NOT satisfy the gate");
ok(lazyDoor.part === 'authoring' && lazyDoor.needsGuard.length === 0 && lazyDoor.needsRequires.length === 0,
  "...and a LAZY door's direct requires on it (demos -> authoring) does (the control)");

// (g) `requires` is ONE LEVEL for the gate. No real lazy chain reaches a part its owner does not
//     also require directly, so one is planted: a lazy part requiring only demos, which requires
//     authoring, must NOT read as permission to name an authoring class.
parts['plant-chain'] = { eager: false, requires: ['demos'], dirs: [] };
const chained = namedFrom('plant-chain', 'src/plant-chain/PlantChainWdgt.coffee');
delete parts['plant-chain'];
ok(chained.part === 'authoring' && chained.needsRequires.join() === 'plant-chain',
  'a transitive requires chain (lazy plant -> demos -> authoring) does NOT satisfy the gate');

const soleBefore = dominatorSubtrees(base.g).subtree.get('TypewriterIconWdgt');
const second = analyse({ bootLines: ['    new TypewriterIconAppearance'] });
const soleAfter = dominatorSubtrees(second.g).subtree.get('TypewriterIconWdgt');
ok(soleBefore.count === 2 && soleAfter.count === 1,
  `a SECOND boot route to TypewriterIconAppearance drops the sole-route subtree ` +
  `${soleBefore.count} -> ${soleAfter.count} (dominance, not mere reachability)`);


t.done();
