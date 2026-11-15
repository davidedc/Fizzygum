'use strict';
// not-a-gate: fg's verbs and its dispatcher — the programs they launch are the gates, run on demand
// fg-verbs.js — `fg <verb>`: the dispatcher of Fizzygum/fg (the entry point, a short launcher), its usage, and every verb
// that is not the commit point's (`presuite` and `gauntlet` are fg-commit-point.js's, and so are the build, the lint,
// the suite and the leg runner every verb here shares). These verbs live apart from the commit point so that
// lib/what-runs.js, which reads fg-commit-point.js as the commit point's root, does not count their tools as run at a
// commit point (an on-demand tool is not a gate's guard).
//
// Each verb does what the bash fg did (docs/archive/fg-node-port-plan.md §1, §3): the same programs, from the same
// directories, with the same alarms, the same banners, the same exit codes and the same verdict files. Where it does
// otherwise, it is one of the plan's §5 rulings: an UNKNOWN verb prints the usage and exits 2 (`fg` and `fg help` exit
// 0); a long operation is refused while another runs (FG_ALLOW_CONCURRENT=1 overrides); `fg status` tells a RUNNING
// verdict whose fg is gone (STALE); `fingerprint` ends its verdict on every exit; an interrupted verb says INTERRUPTED
// in its verdict and kills its children; an error in fg is INVALID (exit 2).

const fs = require('fs');
const path = require('path');
const sup = require('./lib/fg-supervisor');
const C = require('./fg-commit-point');
const { FZ, FT, ROOT, tmp, L, say, ban, out, launch, capture, killBrowsers, verdictStart, verdictEnd } = C;

const USAGE_HEAD = [
  "fg — Fizzygum cross-repo wrapper (run from ANY cwd:  <umbrella>/fg <cmd>  or  <umbrella>/Fizzygum/fg <cmd>)",
  "  fg build [flags]                          build in Fizzygum/ (verifies 0 violations + done!!!)",
  "  fg suite [--dpr=2|--browser=webkit|...]   full headless suite vs the current build (8 shards)",
].join('\n') + '\n';
const USAGE_TAIL = [
  "                                            Fizzygum-tests/scripts/lib/audited-suite.js) retry a dropped shard themselves; exit 3",
  "                                            (dropped twice, zero failed tests) reads INFRA-FLAKE — re-run, never a FAIL.",
  "                                            The settle leg also RIDES the cached-vs-SLOW twins check (doubleCheckCachedMethodsResults suite-wide; CACHED_DERIVATION_DIVERGED fail-gated).",
  "                                            FG_GAUNTLET_SERIAL=1 fg gauntlet = old sequential path.",
  "  fg revisits|storage|vmtruth [gate args]   gate args, as every audited-suite gate takes them: [shards=6] [--tests=A,B]",
  "                                            [--prelude=FILE] [--out=DIR] [--audit-dir=DIR] (judge an existing dir, run no suite)",
  "  fg revisits                               the SETTLE-RE-VISIT standing gate (~2 min): suite under the",
  "                                            audit prelude, profile asserted vs scripts/revisit-baseline.json",
  "                                            (EMPTY since the up-edge endgame: ANY re-visit = regression).",
  "                                            Also a gauntlet wave-B leg — every commit-point run enforces it.",
  "  fg storage                                the bin/shelf storage DEEP AUDIT (Tier B, ~2 min): suite under",
  "                                            the storage prelude — per-test force-drain + from-scratch",
  "                                            reclassify asserting ZERO moves + residue checks; the profile",
  "                                            must be EMPTY (no baseline file on purpose). Tier A (the",
  "                                            STORAGE_INVARIANT token) already rides every suite leg.",
  "                                            Also a gauntlet wave-B leg — every commit-point run enforces it.",
  "  fg finger                                 THE SUITE AS A FINGER (~6 min, gauntlet wave-D leg): every",
  "                                            intent verb translated to the touch gesture carrying the",
  "                                            same intent, matched against the finger reference axis",
  "                                            (…/ceilPixRatio_<N>/finger/). WebKit + dpr2 = \"an iPad\"",
  "                                            (ruling H2). Mouse-only-by-meaning tests (pointerKinds",
  "                                            metadata) are filtered by the loader.",
  "  fg vmtruth                                the VM-TRUTH object-lifetime gate (Arc B, ~2 min): suite under",
  "                                            a forced-GC prelude — every destroyed widget must be",
  "                                            GC-collectible one teardown later (closure retention the",
  "                                            in-band WORLD_INVENTORY gate cannot see: it never walks",
  "                                            functions) + a post-GC heap-floor ceiling per page.",
  "                                            Verdicts: OK / FAILED / INVALID(2) = measured nothing,",
  "                                            never a pass / INFRA-FLAKE(3). Chrome-only by design (the webkit",
  "                                            leg keeps the in-band tier). Localize findings with",
  "                                            scripts/heap-forensics.js (its self-test runs in the selftests leg).",
  "                                            Also a gauntlet leg (wave C) — every commit point enforces it.",
  "  fg census                                 the ARRANGE-IDEMPOTENCE oracle (~10s): boot + app battery",
  "                                            + resizes, then post-order force-re-lay EVERY widget at its",
  "                                            current frame — any mover / battery skip / page error FAILS.",
  "                                            Run for any arrange/engine change (needs a fresh build).",
  "                                            Also a gauntlet wave-B leg — every commit-point run enforces it.",
  "  fg test <SystemTest_name> [flags]         one test headless",
  "  fg recapture <name…>|--auto [--dprs=1,2]  GATED recapture (scripts/recapture.js): recapture (NO builds —",
  "                                            the world serves tests/ through a symlink, so a captured",
  "                                            reference is live at once), then RE-RUN THE FULL SUITE + print",
  "                                            COMPLETE/INCOMPLETE so a silently-incomplete recapture is",
  "                                            impossible. --auto discovers the stale set itself.",
  "                                            --pointer=finger = the FINGER references (one kind per",
  "                                            run); --jobs=N parallel captures (default 6).",
  "                                            Prefer over eyeballing a footprint.",
  "                                            ⚠ BUILD FIRST (fg build): discovery runs against the EXISTING",
  "                                            build — an unbuilt src edit trips the stale-build guard",
  "                                            and the run comes back INCONCLUSIVE.",
  "  fg run-sequence <name…> [--dpr=N]         run a NAMED SUBSET in ONE shared world (reproduce a cross-test",
  "                                            state leak, DETERMINISM.md §2d); --before=<name> lists predecessors",
  "  fg recapture-inspector                    recapture the inspector member-list churn set (the tests in",
  "                                            Fizzygum-tests/scripts/inspector-churn-set.json; re-derive",
  "                                            it with scripts/derive-inspector-churn-set.js) after a benign",
  "                                            framework-member change — mouse + finger refs, each through the",
  "                                            gated recapture.js; no builds; background it",
  "  fg diffpage <name...> [--dprs=1,2]        build a local ref|now|CSS-diff review page for the given",
  "                                            tests (dumps live renders SERIALLY, refs untouched); also",
  "                                            --tests-file=F | stdin | --assemble-only --work=DIR | --open",
  "                                            prints the fg classify triage table at the end of the run;",
  "                                            each test x dpr is CHANGED / UNCHANGED / INVALID, and",
  "                                            exit 2 = INCOMPLETE (a dump measured nothing — never \"no diff\")",
  "  fg visualise [SystemTest_<name>]          write a test's visualisation.html (its references, metadata",
  "                                            and macro step comments), or every test's (~0.2 s): generated",
  "                                            when wanted, never committed",
  "  fg classify [--work=DIR] [--verbose]      ADVISORY triage of the screenshots in a diffpage work dir:",
  "                                            REVIEW vs BENIGN? (a suspected benign shape, e.g. a member",
  "                                            list that only gained a row), with the evidence. Never",
  "                                            recaptures and never gates — a BENIGN? is a hint for reading",
  "                                            fg diffpage faster, not permission to recapture. --json=F.",
  "  fg fuzz [--rounds=N] [--seed=N]           ON-DEMAND coverage measurement of the SWCanvas text-settle",
  "          [--max-ms=N] [--no-rigs]          gate — NOT a test, NOT a gate, never in the gauntlet.",
  "                                            Delays every glyph-atlas load by a seeded-random 0..max-ms",
  "                                            and runs the suite + both serialization rigs; a test that",
  "                                            fails ONLY under injection has a pixel read the gate does",
  "                                            not cover (DETERMINISM.md §3g/§3i). THREE verdicts:",
  "                                            OK / FAILED (the finding) / INVALID (measured nothing —",
  "                                            a \"failed: 0\" line is NOT a pass). ⚠ NEVER recapture a ref",
  "                                            because of a fuzz failure: fix the READ.",
  "  fg apps                                   app-launch smoke",
  "  fg homepage                               production-profile build + native boot-smoke + restore normal build",
  "  fg critique                               ADVISORY code-critique view (~5 s, read-only, never gates):",
  "                                            every ratchet's \"tighten me now\" + stale-allowlist NOTE,",
  "                                            plus the 5 censuses' summary counts (public/private calls,",
  "                                            HIERARCHY DUPLICATION, whose identical-override subset",
  "                                            also gates the build at zero, property placement, ARGUMENT",
  "                                            HOLES -- what `positional-hole` cannot see -- and WIDGET",
  "                                            CONFORMANCE, whose 2 ratcheted facets also gate the build",
  "                                            at a non-zero FLOOR). The",
  "                                            Critic Browser analogue. jscpd/jsinspect stay on-demand.",
  "  fg doc-narration [--full]                 RATCHET: changelog prose in the PRESENT-TENSE doc buckets",
  "                                            (docs/architecture + docs/tooling). Fails when a file's",
  "                                            count RISES — the docs-side twin of the comment-narration",
  "                                            stink. ⛔ specs/ is NOT scanned (a spec's change statements",
  "                                            are load-bearing), nor are plans/ archive/ measurements/,",
  "                                            which are chronological by design. --write-baseline banks",
  "                                            a clean-up; `<!-- narration-ok: why -->` exempts a line.",
  "                                            Also fails on any closed item (`- [x]`) left in",
  "                                            docs/BACKLOG.md, a hard zero (BACKLOG_CLOSED_ITEM).",
  "                                            Also rides the gauntlet's refs leg (not the build: docs",
  "                                            prose must not block a build).",
  "  fg cc [coffee-cc flags|paths]             Cognitive Complexity (SonarSource S3776) of the CoffeeScript",
  "                                            source (npm pkg coffeescript-cognitive-complexity). Read-only,",
  "                                            no build/browser. `fg cc` = top methods over src; also",
  "                                            --by-class | --by-file | --explain <file> | --top=N | --json.",
  "  fg pinsweep                               EVERY ADVERTISED PIN MUST RESOLVE (~5s): a PinSpec names",
  "                                            its setter by STRING, so an unresolved one accepts a wire",
  "                                            and silently does nothing. Also checks every `announces`.",
  "  fg graph                                  WIDGET-GRAPH LIVENESS CONTRACT (~35s, gauntlet wave-A",
  "                                            leg): the storage leg gates the classifier's IDEMPOTENCE,",
  "                                            this gates its SEMANTICS via the real drain — wire death",
  "                                            severs, wire-into-bin-resident shelves (and relays via",
  "                                            the fixpoint), command edges confer nothing, close asks",
  "                                            anyReferenceOrWireIntoWdgt, mixin super chains terminate.",
  "  fg menusweep                              CLICK EVERY MENU ITEM (~6s): fires every reachable menu",
  "                                            action and fails on a throw — the RUNTIME half of menu",
  "                                            wiring, whose static half runs on the build",
  "                                            (check-menu-actions.js). Catches what no text scan can:",
  "                                            a parameter that IS read and is read as the WRONG THING",
  "                                            (slot 1 of ButtonWdgt's dispatch is the MENU ITEM).",
  "                                            Also a gauntlet wave-A leg.",
  "  fg lazyprobe                              the index.html laziness invariants — every app icon drawn",
  "                                            with NO app class, the Examples folder empty until opened,",
  "                                            one click fetching one app. THE ONLY THING THAT CAN SEE",
  "                                            THIS: the suite runs eager-everything on a page with no",
  "                                            desktop. Also runs in the gauntlet's parts leg (sampled).",
  "  fg hypopart <paths...>                    \"what if these files were a part?\" — inheritance edges,",
  "                                            unguarded references and cross-part callers, using the",
  "                                            BUILD GATE'S own classifier (never a grep)",
  "  fg whatpins [--profile p] [--list]        why is each class in the boot image? Walks from src/boot",
  "                                            and reports (1) what no boot path reaches — movable today,",
  "                                            transitively — and (2) SOLE ROUTES: one class holding a",
  "                                            whole subtree in the image. Section 2 is questions, not",
  "                                            findings. `--why <Class>`. (Its self-test runs on every build.)",
  "  fg fingerprint [profile] [baseref]        MEASURE a packaging change: build <profile> at <baseref>",
  "                                            in a throwaway sibling worktree, build it from the working",
  "                                            tree, diff the fingerprints. Defaults: homepage HEAD.",
  "                                            Leaves the build tree on <profile> — 'fg build' restores.",
  "  fg lint                                   pre-build static checks (~2 s): node --check every git-CHANGED",
  "                                            test .js + the coffee syntax gate if any .coffee changed.",
  "                                            gauntlet/presuite run it first automatically.",
  "  fg status                                 one-shot re-orientation: repos, build freshness, tests,",
  "                                            zombie browsers, fg verdicts (read-only, <2s)",
  "  fg killz                                  kill leftover headless test browsers",
  "build/suite/gauntlet/homepage also maintain /tmp/fg-<cmd>.verdict: \"RUNNING since …\" while",
  "running, \"<CMD> EXIT=<rc> …\" when done — cat it to check a backgrounded run (never poll-loop).",
].join('\n') + '\n';

const usage = () => out(USAGE_HEAD + L.roster().join('\n') + '\n' + USAGE_TAIL);

// a program in the tests repo or in Fizzygum/, its output and its stdin fg's own (a passthrough verb)
const inTests = (script, args, alarmSecs) => launch(['node', script, ...args], { cwd: FT, alarmSecs, stdin: 'inherit', label: script });
const inFizzygum = (script, args) => launch(['node', script, ...args], { cwd: FZ, stdin: 'inherit', label: script });

// the long operations: each builds or launches a browser, so ONE runs at a time (B6, the commit point's lock), and each
// leaves `/tmp/fg-<verb>.running` for as long as it runs
const LONG = new Set(['build', 'suite', 'census', 'revisits', 'storage', 'vmtruth', 'test', 'fuzz', 'diffpage', 'run-sequence',
  'recapture', 'recapture-inspector', 'apps', 'presuite', 'gauntlet', 'homepage', 'menusweep', 'finger', 'pinsweep', 'graph',
  'lazyprobe', 'fingerprint']);
// the verbs that keep a verdict file (`/tmp/fg-<verb>.verdict`): a refused one says REFUSED there
const VERDICT_VERBS = new Set(['build', 'suite', 'census', 'revisits', 'storage', 'vmtruth', 'fuzz', 'recapture', 'recapture-inspector',
  'presuite', 'gauntlet', 'homepage', 'finger', 'fingerprint']);

// gate-style verbs: one program, a verdict, OK / INFRA-FLAKE (3) / INVALID (2) / FAILED
async function gateVerb(cmd, script, args, alarmSecs, upper, codes = {}) {
  verdictStart(cmd);
  await killBrowsers();
  const rc = await inTests(script, args, alarmSecs);
  if (rc === 0) { ban(`${upper} OK`); verdictEnd(cmd, 0, 'OK'); return 0; }
  if (rc === 2 && codes.invalid) { ban(`${upper} INVALID (not a result — measured nothing)`); verdictEnd(cmd, 2, 'INVALID'); return 2; }
  if (rc === 3 && codes.infra) { ban(`${upper} INFRA-FLAKE (a shard dropped twice — re-run; not a result)`); verdictEnd(cmd, 3, 'INFRA-FLAKE'); return 3; }
  ban(`${upper} FAILED`); verdictEnd(cmd, 1, 'FAILED'); return 1;
}
// a sweep: one program, a banner, its exit code
async function sweepVerb(script, args, okText, failText) {
  await killBrowsers();
  const rc = await inTests(script, args);
  ban(rc === 0 ? okText : failText);
  return rc;
}

const VERBS = {
  async build(args) {
    verdictStart('build');
    if (await C.fgBuild(args) === 0) { ban('BUILD OK'); verdictEnd('build', 0, 'OK'); return 0; }
    verdictEnd('build', 1, 'FAILED'); return 1;
  },
  async suite(args) {
    verdictStart('suite');
    if (await C.fgSuite(args, { stdin: 'inherit' }) === 0) { ban('SUITE OK'); verdictEnd('suite', 0, 'OK'); return 0; }
    ban('SUITE FAILED'); verdictEnd('suite', 1, 'FAILED'); return 1;
  },
  // the ARRANGE-IDEMPOTENCE oracle (~10 s, one page): any mover, battery skip or page error fails. Needs a fresh build.
  census: (args) => gateVerb('census', 'scripts/staleness-census.js', args, 300, 'CENSUS'),
  // the SETTLE-RE-VISIT standing gate (~2 min): the suite under the re-visit prelude, against revisit-baseline.json
  revisits: (args) => gateVerb('revisits', 'scripts/revisit-gate.js', args, 600, 'REVISITS', { infra: true }),
  // the bin/shelf storage DEEP AUDIT (~2 min): per-test force-drain + from-scratch reclassify asserting zero moves
  storage: (args) => gateVerb('storage', 'scripts/storage-invariant-gate.js', args, 900, 'STORAGE', { infra: true }),
  // the VM-truth object-lifetime gate (~2 min): collectibility + a post-GC heap floor; Chrome-only by design
  vmtruth: (args) => gateVerb('vmtruth', 'scripts/vm-truth-gate.js', args, 900, 'VMTRUTH', { infra: true, invalid: true }),
  async test(args) {
    if (!args.length) { usage(); return 2; }
    await killBrowsers();
    return inTests('scripts/run-macro-test-headless.js', args, 240);
  },
  // glyph-atlas delay fault injection: THREE outcomes, and INVALID is neither a pass nor a fail
  async fuzz(args) {
    verdictStart('fuzz');
    await killBrowsers();
    const rc = await inTests('scripts/run-atlas-fuzz.js', args, 5400);
    if (rc === 0) { ban('FUZZ OK'); verdictEnd('fuzz', 0, 'OK'); return 0; }
    if (rc === 1) { ban('FUZZ FAILED — a pixel read is NOT covered by the text-settle gate (do NOT recapture)'); verdictEnd('fuzz', 1, 'FAILED (finding)'); return 1; }
    ban('FUZZ INVALID (not a result) — the run measured nothing; do not read it as a pass'); verdictEnd('fuzz', rc, 'INVALID (not a result)'); return rc;
  },
  // a ref|now|CSS-diff review page; exit 2 = INCOMPLETE (a dump that measured nothing is never "no diff")
  async diffpage(args) {
    await killBrowsers();
    const rc = await inTests('scripts/make-diff-page.js', args);
    if (rc === 2) ban('DIFFPAGE INCOMPLETE — some group is INVALID (or an image is undecodable/unpaired): do NOT read the page as \'unchanged\' there');
    return rc;
  },
  // a test's visualisation.html, or every test's: generated when wanted, never committed
  visualise: (args) => inTests('scripts/make-visualisation.js', args),
  // ADVISORY triage of a diffpage work dir: never recaptures, never gates
  classify: (args) => inTests('scripts/classify-diff.js', args),
  // Cognitive Complexity of the CoffeeScript source (the npm package's coffee-cc); `src` when no path is given
  async cc(args) {
    try { fs.accessSync(path.join(FZ, 'node_modules/.bin/coffee-cc'), fs.constants.X_OK); }
    catch (e) { say(`fg cc: coffee-cc not installed — run: ( cd "${FZ}" && npm ci )`); return 3; }
    const a = args.some((x) => !x.startsWith('-')) ? args : [...args, 'src'];
    return launch(['node_modules/.bin/coffee-cc', ...a], { cwd: FZ, stdin: 'inherit' });
  },
  // the GATED recapture: recapture, then re-run the full suite and print COMPLETE/INCOMPLETE
  async recapture(args) {
    if (!args.length) { usage(); return 2; }
    verdictStart('recapture');
    await killBrowsers();
    if (await inTests('scripts/recapture.js', args) === 0) { ban('RECAPTURE OK'); verdictEnd('recapture', 0, 'OK'); return 0; }
    ban('RECAPTURE FAILED'); verdictEnd('recapture', 1, 'FAILED'); return 1;
  },
  // a NAMED subset of tests in ONE shared world (a cross-test state leak, DETERMINISM.md §2d)
  async 'run-sequence'(args) { await killBrowsers(); return inTests('scripts/run-sequence-headless.js', args); },
  // the inspector member-list CHURN SET (Fizzygum-tests/scripts/inspector-churn-set.json, read through its one reader),
  // recaptured through the gated recapture.js once per pointer kind
  async 'recapture-inspector'() {
    verdictStart('recapture-inspector');
    const tAll = C.seconds();
    let failed = '';
    const churn = await capture(['node', '-e', CHURN_READER], { cwd: FT });
    if (churn.rc !== 0) {
      if (churn.rc === 3) {
        ban('RECAPTURE-INSPECTOR REFUSED — Fizzygum-tests/tests/ holds a directory that is no test (above); nothing recaptured.');
        verdictEnd('recapture-inspector', 2, 'REFUSED — tests/ malformed'); return 2;
      }
      ban('RECAPTURE-INSPECTOR REFUSED — Fizzygum-tests/scripts/inspector-churn-set.json is not a current list of tests (above); nothing recaptured. Re-derive it: node scripts/derive-inspector-churn-set.js --write');
      verdictEnd('recapture-inspector', 2, 'REFUSED — churn set not current'); return 2;
    }
    const names = churn.text.split(/\s+/).filter(Boolean);
    const n = churn.text.split('\n').filter((l) => l.length).length;
    say(`  recapturing the ${n} tests of the inspector churn set (Fizzygum-tests/scripts/inspector-churn-set.json)`);
    for (const kind of ['mouse', 'finger']) {
      await killBrowsers();
      const flag = kind === 'finger' ? '--pointer=finger' : '';
      const lg = tmp(`fg-recapture-inspector-${kind}.log`);
      say(`  ${kind} references: node scripts/recapture.js --dprs=1,2 ${flag} <the ${n} tests>   (log: ${lg})`);
      const rc = await C.withLog(lg, 'w', (fd) => launch(['node', 'scripts/recapture.js', '--dprs=1,2', ...(flag ? [flag] : []), ...names],
        { cwd: FT, stdout: fd, stderr: fd }));
      if (rc === 0) say(`  ✓ ${kind}: RECAPTURE COMPLETE`);
      else { say(`  ✗ ${kind}: recapture.js exit ${rc}`); failed += ` ${kind}(exit ${rc})`; }
      for (const l of await C.grepLast(lg, /VERDICT:/, Infinity)) say('    ' + l.replace(/^ */, ''));
    }
    if (failed) {
      ban(`RECAPTURE-INSPECTOR FAILED —${failed} (logs: ${tmp('fg-recapture-inspector-<kind>.log')})`);
      verdictEnd('recapture-inspector', 1, `FAILED —${failed}`); return 1;
    }
    const total = C.seconds() - tAll;
    ban(`RECAPTURE-INSPECTOR OK — ${n} tests, mouse + finger, recaptured and gated in ${Math.floor(total / 60)}m; close with fg gauntlet before committing`);
    verdictEnd('recapture-inspector', 0, `OK ${n} tests mouse+finger total=${total}s`);
    return 0;
  },
  async apps(args) { await killBrowsers(); return inTests('scripts/smoke-apps-headless.js', args, 300); },
  presuite: (args) => C.presuite(args),
  gauntlet: (args) => C.gauntlet(args),
  // the production-profile build + its native boot smoke, then the normal build restored, whatever happened
  async homepage() {
    verdictStart('homepage');
    if (await C.fgBuild(['--profile', 'homepage'])) { verdictEnd('homepage', 1, 'FAILED — homepage build'); return 1; }
    await killBrowsers();
    const hrc = await inTests('scripts/smoke-boot-headless.js', ['--production'], 300);
    ban('restoring normal build…');
    if (await C.fgBuild()) { verdictEnd('homepage', 1, 'FAILED — restoring normal build'); return 1; }
    if (hrc === 0) { ban('HOMEPAGE BOOT OK (normal build restored)'); verdictEnd('homepage', 0, 'OK'); return 0; }
    ban('HOMEPAGE SMOKE FAILED (normal build restored)'); verdictEnd('homepage', 1, 'FAILED — smoke'); return 1;
  },
  menusweep: (args) => sweepVerb('scripts/menu-click-sweep-headless.js', args, 'MENU CLICK SWEEP OK', 'MENU CLICK SWEEP FAILED'),
  async finger(args) {
    verdictStart('finger');
    if (await C.fgSuite(['--pointer=finger', '--browser=webkit', '--dpr=2', ...args], { stdin: 'inherit' }) === 0) {
      ban('FINGER SUITE OK'); verdictEnd('finger', 0, 'OK'); return 0;
    }
    ban('FINGER SUITE FAILED'); verdictEnd('finger', 1, 'FAILED'); return 1;
  },
  pinsweep: (args) => sweepVerb('scripts/pin-sweep-headless.js', args, 'PIN SWEEP OK', 'PIN SWEEP FAILED'),
  graph: (args) => sweepVerb('scripts/graph-liveness-headless.js', args, 'GRAPH LIVENESS OK', 'GRAPH LIVENESS FAILED'),
  // THE ONLY THING THAT CAN SEE LAZINESS (every icon, not the parts leg's sample); it takes no arguments
  lazyprobe: () => inTests('scripts/parts-lazy-icons-headless.js', ['--exhaustive']),
  // "what if these files were a part?", with the build gate's own classifier
  async hypopart(args) {
    if (!args.length) { say('usage: fg hypopart <file-or-dir>...   (paths relative to Fizzygum/)'); return 2; }
    return inFizzygum('buildSystem/hypothetical-part.js', args);
  },
  // why is each class in the boot image?
  whatpins: (args) => inFizzygum('buildSystem/what-pins-core.js', args),
  fingerprint: (args) => fingerprint(args),
  async lint() { return (await C.runLint()) ? 1 : 0; },
  async stinks(args) { return (await inFizzygum('buildSystem/check-stinks.js', args)) ? 1 : 0; },
  // the docs ratchet; its own exit code (2 = INVALID, kept)
  'doc-narration': (args) => inFizzygum('buildSystem/check-doc-narration.js', args),
  status: () => status(),
  critique: () => critique(),
  // what a dead fg run left behind (its recorded programs, with their descendants), then every leftover test browser
  async killz() {
    const stale = await C.killStaleRuns();
    if (stale.count) say(`killed ${stale.count} process(es) that a dead fg run left behind: ${stale.runs.join(', ')}`);
    await killBrowsers(); say('killed leftover headless test browsers (Chrome for Testing / chrome-headless / puppeteer / webkit)'); return 0;
  },
};

// the churn set's one reader, as the bash fg ran it: stdout = the names, one per line; stale entries or a malformed file
// on stderr; a tests/ tree that is not all tests exits 3
const CHURN_READER = `
      let s;
      try { s = require("./scripts/lib/inspector-churn-set").loadInspectorChurnSet(); }
      catch (e) { process.stderr.write("  " + e.message + "\\n"); process.exit(/^TESTS_DIRECTORY_MALFORMED/.test(e.message) ? 3 : 2); }
      if (s.missing.length) { process.stderr.write("  not a test:\\n" + s.missing.map(t => "    " + t + "\\n").join("")); process.exit(2); }
      process.stdout.write(s.tests.join("\\n") + "\\n");`;

// ---- fingerprint: MEASURE a packaging change — build <profile> at a BASELINE ref in a throwaway sibling worktree, build
// it again from the working tree, diff the fingerprints. Fizzygum-tests must be a real WORKTREE there, never a symlink
// (generate-pre-compiled-headless.js and build-tree-fingerprint.js resolve their paths from __dirname: through a link
// they address the REAL build tree, a void measurement that once overwrote Fizzygum-builds/latest). Only node_modules
// is linked.
async function fingerprint(args) {
  const prof = args[0] || 'homepage', base = args[1] || 'HEAD';
  const BASEDIR = `${ROOT}/../Fizzygum-fingerprint-baseline`;
  const fail = (msg, text) => { if (msg) say(msg); verdictEnd('fingerprint', 1, text); return 1; };
  const quiet = { stdout: 'ignore', stderr: 'ignore' };
  verdictStart('fingerprint');
  fs.rmSync(BASEDIR, { recursive: true, force: true });
  await launch(['git', '-C', FZ, 'worktree', 'prune']);
  await launch(['git', '-C', FT, 'worktree', 'prune']);
  fs.mkdirSync(`${BASEDIR}/Fizzygum-builds`, { recursive: true });
  if (await launch(['git', '-C', FZ, 'worktree', 'add', '--detach', `${BASEDIR}/Fizzygum`, base], quiet)) {
    return fail(`fg fingerprint: cannot create a worktree of Fizzygum at '${base}'`, 'FAILED — worktree');
  }
  if (await launch(['git', '-C', FT, 'worktree', 'add', '--detach', `${BASEDIR}/Fizzygum-tests`, 'HEAD'], quiet)) {
    return fail('fg fingerprint: cannot create a worktree of Fizzygum-tests', 'FAILED — worktree');
  }
  const link = (target, at) => { fs.rmSync(at, { recursive: true, force: true }); fs.symlinkSync(target, at); };
  link(`${FT}/node_modules`, `${BASEDIR}/Fizzygum-tests/node_modules`);
  // font-assets/ is gitignored, and every profile that ships an SWCanvas page copies it (through the link: real files)
  if (fs.existsSync(`${FZ}/font-assets`) && fs.statSync(`${FZ}/font-assets`).isDirectory()) link(`${FZ}/font-assets`, `${BASEDIR}/Fizzygum/font-assets`);
  // A baseline from before fg was versioned (Fizzygum/fg) reads it in the umbrella, as a bash program its build's gates
  // read as text: give it the bash fg the repo last had.
  if (!fs.existsSync(`${BASEDIR}/Fizzygum/fg`)) await writeLastBashFg(`${BASEDIR}/fg`);
  // the toolchain (Fizzygum/node_modules, gitignored): this tree's when the lockfile is the same, else the baseline's own
  if (sameBytes(`${FZ}/package-lock.json`, `${BASEDIR}/Fizzygum/package-lock.json`)) link(`${FZ}/node_modules`, `${BASEDIR}/Fizzygum/node_modules`);
  else {
    const rc = await C.withLog(tmp('fg-fingerprint-npm.log'), 'w', (fd) => launch(['npm', 'ci', '--no-audit', '--no-fund'],
      { cwd: `${BASEDIR}/Fizzygum`, stdout: fd, stderr: fd }));
    if (rc) return fail(`fg fingerprint: npm ci in the baseline worktree FAILED — see ${tmp('fg-fingerprint-npm.log')}`, 'FAILED — baseline npm ci');
  }
  const OUT = `${FT}/.scratch/fingerprints`;
  fs.mkdirSync(OUT, { recursive: true });
  ban(`fingerprint: building '${prof}' at BASELINE ${base}`);
  if (await C.withLog(tmp('fg-fingerprint-base.log'), 'w', (fd) => launch(['./build_it_please.sh', '--profile', prof],
    { cwd: `${BASEDIR}/Fizzygum`, stdout: fd, stderr: fd }))) {
    return fail(`fg fingerprint: baseline build FAILED — see ${tmp('fg-fingerprint-base.log')}`, 'FAILED — baseline build');
  }
  if (await launch(['node', 'scripts/build-tree-fingerprint.js', 'write', `${OUT}/base-${prof}.txt`], { cwd: `${BASEDIR}/Fizzygum-tests` })) {
    return fail(undefined, 'FAILED — baseline fingerprint');
  }
  ban(`fingerprint: building '${prof}' from the WORKING TREE`);
  if (await C.withLog(tmp('fg-fingerprint-cand.log'), 'w', (fd) => launch(['./build_it_please.sh', '--profile', prof],
    { cwd: FZ, stdout: fd, stderr: fd }))) {
    return fail(`fg fingerprint: candidate build FAILED — see ${tmp('fg-fingerprint-cand.log')}`, 'FAILED — candidate build');
  }
  if (await launch(['node', 'scripts/build-tree-fingerprint.js', 'write', `${OUT}/cand-${prof}.txt`], { cwd: FT })) {
    return fail(undefined, 'FAILED — candidate fingerprint');
  }
  ban(`fingerprint: ${prof} — BASELINE (${base}) vs WORKING TREE`);
  const drc = await launch(['node', 'scripts/build-tree-fingerprint.js', 'compare', `${OUT}/base-${prof}.txt`, `${OUT}/cand-${prof}.txt`], { cwd: FT });
  await launch(['git', '-C', FZ, 'worktree', 'remove', '--force', `${BASEDIR}/Fizzygum`], quiet);
  await launch(['git', '-C', FT, 'worktree', 'remove', '--force', `${BASEDIR}/Fizzygum-tests`], quiet);
  fs.rmSync(BASEDIR, { recursive: true, force: true });
  ban(`fingerprint: the build tree now holds '${prof}' — run 'fg build' to restore the dev tree`);
  // a DIFFERENCE is the point here: the verdict records that the measurement RAN
  verdictEnd('fingerprint', 0, `OK — compared ${prof} (differences: ${drc === 0 ? 'none' : 'yes'})`);
  return 0;
}
function sameBytes(a, b) {
  try { return fs.readFileSync(a).equals(fs.readFileSync(b)); } catch (e) { return false; }
}
// the newest commit's `fg` that is the bash program, written to `to`
async function writeLastBashFg(to) {
  const log = await capture(['git', '-C', FZ, 'log', '--format=%H', '--', 'fg'], { stderr: 'ignore' });
  for (const c of log.text.split('\n').filter(Boolean)) {
    const show = await capture(['git', '-C', FZ, 'show', `${c}:fg`], { stderr: 'ignore' });
    if (show.rc === 0 && show.text.startsWith('#!/usr/bin/env bash')) { fs.writeFileSync(to, show.text, { mode: 0o755 }); return; }
  }
}

// ---- status: one-shot re-orientation, read-only --------------------------------------------------------------------------
async function status() {
  say(`fg status — ${C.stamp()}`);
  for (const r of ['Fizzygum', 'Fizzygum-tests', 'Fizzygum-builds']) {
    const d = `${ROOT}/${r}`;
    const q = { stderr: 'ignore' };
    const one = async (argv, fallback) => { const x = await capture(argv, q); const v = x.text.replace(/\n+$/, ''); return x.rc === 0 || v ? v : fallback; };
    const b = await one(['git', '-C', d, 'rev-parse', '--abbrev-ref', 'HEAD'], '?');
    const sha = await one(['git', '-C', d, 'rev-parse', '--short', 'HEAD'], '?');
    const dirty = (await capture(['git', '-C', d, 'status', '--porcelain'], q)).text.split('\n').filter((l) => l.length).length;
    const counts = (await capture(['git', '-C', d, 'rev-list', '--left-right', '--count', `origin/${b}...HEAD`], q)).text
      .split('\n').filter((l) => l.length).map((l) => { const f = l.trim().split(/\s+/); return `behind=${f[0]} ahead=${f[1] === undefined ? '' : f[1]}`; }).join('\n');
    say(`  ${r.padEnd(16)} ${b} @ ${sha}  dirty=${dirty}  ${counts || '(no origin tracking)'}`);
  }
  const BUILT = `${ROOT}/Fizzygum-builds/latest/index.html`;
  if (!fs.existsSync(BUILT) || !fs.statSync(BUILT).isFile()) say(`  build: MISSING (no ${BUILT})`);
  else {
    const builtAt = fs.statSync(BUILT).mtimeMs;
    const newer = [];
    const walk = (dir) => {
      let entries;
      try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch (e) { return; }
      for (const e of entries) {
        if (newer.length >= 3) return;
        const p = path.join(dir, e.name);
        if (e.isDirectory()) walk(p);
        else if (e.name.endsWith('.coffee') && fs.statSync(p).mtimeMs > builtAt) newer.push(p);
      }
    };
    walk(`${FZ}/src`); walk(`${ROOT}/Fizzygum-tests/Automator-and-test-harness-src`);
    if (newer.length) { say('  build: STALE — newer source, e.g.:'); for (const p of newer) say('           ' + p); }
    else say(`  build: FRESH (built ${C.stamp(fs.statSync(BUILT).mtime)})`);
  }
  let tests = 0;
  try { tests = fs.readdirSync(`${FT}/tests`).filter((n) => !n.startsWith('.') && /^SystemTest_/.test(n)).length; } catch (e) { /* 0 */ }
  say(`  tests: ${tests} SystemTests`);
  const z = await capture(['pgrep', '-f', 'Chrome for Testing|chrome-headless|puppeteer|webkit'], { stderr: 'ignore' });
  say(`  zombie test browsers: ${z.text.split('\n').filter((l) => l.length).length}   (fg killz clears)`);
  say('  fg verdicts:');
  let names = [];
  try { names = fs.readdirSync(C.TMP).filter((n) => /^fg-.*\.verdict$/.test(n)).sort(); } catch (e) { /* none */ }
  const table = sup.snapshot();
  for (const n of names) {
    const cmd = n.slice(3, -'.verdict'.length);
    let text = '';
    try { text = fs.readFileSync(path.join(C.TMP, n), 'utf8').replace(/\n+$/, ''); } catch (e) { continue; }
    // B2: a RUNNING verdict whose fg is gone (its `.running` names a process that is no longer the same one)
    if (/^RUNNING since /.test(text)) {
      const pid = (/ pid=(\d+)/.exec(text) || [])[1];
      const r = pid && C.readRunning(`fg-${cmd}.${pid}.running`);
      const e = r && table.get(r.pid);
      if (r && !(e && e.start === r.start)) text = `STALE — fg is gone (killed or crashed); not a result (it said: ${text})`;
    }
    say(`    ${('fg-' + cmd).padEnd(24)} ${text}`);
  }
  if (!names.length) say('    (none)');
  return 0;
}

// ---- critique: ONE read-only view of the advisory tier and every "you could tighten a ratchet now" signal ---------------
const CRITIQUE = [
  ['stinks — tighten?', 'buildSystem/check-stinks.js', /UNDER|NOTE|OK --/],
  ['dead-methods — stale allowlist?', 'buildSystem/check-dead-methods.js', /NOTE|OK —/],
  ['unresolved-sends — stale allowlist?', 'buildSystem/check-unresolved-sends.js', /NOTE|OK —/],
  ['call-separation — tighten?', 'buildSystem/check-call-separation.js', /NOTE|OK —/],
  ['complexity ratchets — tighten?', 'buildSystem/check-complexity-ratchets.js', /UNDER|NOTE|OK/],
  ['census: public/private self-calls', 'buildSystem/census-public-private-calls.js', /^(stats|by callee class|hard sites|total|narrowed)/],
  ['census: hierarchy duplication', 'buildSystem/census-hierarchy-duplication.js', /^(scanned|IDENTICAL)/],
  ['census: property placement', 'buildSystem/census-property-placement.js', /^(scanned|PULL-UP:)|withheld/],
  // widget-practices conformance: the ADVISORY view (its two ratcheted facets also run as `--gate` on the build)
  ['census: widget conformance', 'buildSystem/census-widget-conformance.js', /^(\[widget-conformance\]|RATCHETED|ADVISORY| {2}[0-9]\.)/],
  // call arguments — the GATE's own verdict line (it also runs on every build)
  ['call arguments (the gate\'s verdict)', 'buildSystem/check-call-arguments.js', /^\[call-arguments\]/],
];
async function critique() {
  say(`fg critique — ${C.stamp()}   [ADVISORY — nothing here gates]`);
  const t0 = C.seconds();
  for (const [label, script, re] of CRITIQUE) {
    const s = C.seconds();
    const errFile = tmp(`fg-critique-${process.pid}.err`);
    const r = await C.withLog(errFile, 'w', (fd) => capture(['node', './' + script], { cwd: FZ, stderr: fd }));
    let errText = '';
    try { errText = fs.readFileSync(errFile, 'utf8'); fs.rmSync(errFile, { force: true }); } catch (e) { /* none */ }
    out(`\n── ${label} (${C.seconds() - s}s)\n`);
    // the program's stderr first, as bash showed it (its stdout reached the capture through grep, at the end)
    const lines = [...errText.split('\n'), ...r.text.split('\n').filter((l) => re.test(l))];
    for (const l of lines) if (!/^\s*$/.test(l)) say('   ' + l);
  }
  out(`\n── total ${C.seconds() - t0}s\n`);
  say('advisory only — nothing here gates; see Fizzygum/docs/archive/lint-generic-rules-carryover-plan.md');
  say('  lists: add --full to any census; machine-readable: --json <file>');
  return 0;
}

// ---- the dispatcher ------------------------------------------------------------------------------------------------------
async function onInterrupt(sig) {
  const n = 128 + require('os').constants.signals[sig];
  for (const cmd of [...C.openVerdicts]) verdictEnd(cmd, n, `INTERRUPTED by ${sig}`);
  C.releaseAll();
  return n;
}
async function onInternalError(e) {
  for (const cmd of [...C.openVerdicts]) verdictEnd(cmd, 2, `INVALID — fg internal error: ${e && e.message ? e.message : e}`);
  C.releaseAll();
  return 2;
}

// main(argv) → the exit code
async function main(argv) {
  const executable = (p) => { try { fs.accessSync(p, fs.constants.X_OK); return fs.statSync(p).isFile(); } catch (e) { return false; } };
  const directory = (p) => { try { return fs.statSync(p).isDirectory(); } catch (e) { return false; } };
  if (!executable(path.join(FZ, 'build_it_please.sh'))) { say(`fg FATAL: ${FZ}/build_it_please.sh not found — fg lives in Fizzygum/, beside its sibling Fizzygum-tests/`); return 3; }
  if (!directory(path.join(FT, 'scripts'))) { say(`fg FATAL: ${FT}/scripts not found`); return 3; }
  const refusal = C.railsRefusal();
  if (refusal) { sup.err(refusal + '\n'); return 2; }
  sup.guard({ onInterrupt, onInternalError });
  const cmd = argv[0] ? argv[0] : 'help';         // bash's ${1:-help}: an empty first word is help too
  const args = argv.slice(1);
  if (cmd === 'help') { usage(); return 0; }
  if (!Object.prototype.hasOwnProperty.call(VERBS, cmd)) { usage(); return 2; }
  if (LONG.has(cmd)) {
    if (!(await C.acquireLongOp(cmd, VERDICT_VERBS.has(cmd)))) return 2;
    C.markRunning(cmd);
  }
  try {
    const rc = await VERBS[cmd](args);
    // every exit of a verb that started a verdict ends it (B10): one left open here is fg's own error (or, after a
    // signal, the interruption's, which verdictEnd writes as INTERRUPTED)
    for (const c of [...C.openVerdicts]) verdictEnd(c, 2, 'INVALID — fg internal error: the verb ended without its verdict');
    return sup.interruptedRc() || rc;
  } catch (e) {
    // an error thrown in fg (B3): every live tree killed, every open verdict INVALID, exit 2 — nothing was measured
    sup.err(`fg: internal error: ${e && e.stack ? e.stack : e}\n`);
    sup.fail(e);
    await sup.killAll();
    return onInternalError(e);
  } finally { C.releaseAll(); }
}

module.exports = { main, VERBS, LONG, VERDICT_VERBS };
