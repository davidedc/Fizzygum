#!/usr/bin/env node
'use strict';
// check-complexity-ratchets.js — two RATCHETS in the check-stinks.js style: a recorded value that may fall and may
// not rise (docs/plans/top-10-cleanups-plan.md §8 step 1).
//
// METHOD COUNT. The four classes that grew with nothing holding them — Widget, WorldWdgt, ActivePointerWdgt and
// FrameWdgt — each hold at most METHOD_CEILINGS' count of methods: the lines of its file that open a method, instance
// or class-side, by the ONE definition of a method header (lib/coffee-method-header.js METHOD_HEADER and
// STATIC_METHOD_HEADER — a wrapped signature counts once, a parameter default holding a call counts). Methods, not
// lines: a line ceiling would punish the comments this project asks for. A class under its ceiling prints UNDER:
// lower the ceiling here, to lock the gain in.
//
// COGNITIVE COMPLEXITY. No function of the compiled sources (src/ and the tests repo's harness, lib/source-files.js
// compiledFiles) scores above COMPLEXITY_CEILING — 15, the published default of SonarSource rule S3776, which the
// analyzer implements — but those RECORDED below at the value they had when this ratchet landed: each may fall and
// may not rise, and a new function above the ceiling fails. A function's key is `Class#method` (instance side),
// `Class.method` (class side), or `<file>#name` for one outside any class (a boot file's). A recorded one that fell
// prints UNDER (lower its record); one that fell to the ceiling or below, or that no longer exists, leaves its entry
// excusing nothing: STALE, delete it. The harness's records (RECORDED_IN_HARNESS) are judged like src's: the harness is
// always read (the build requires the tests repo). The analyzer is vendor/coffeescript-cognitive-complexity/,
// loaded by lib/cognitive-complexity.js on the CoffeeScript the records were measured on (MEASURED_ON).
//
// RULES: METHOD_COUNT_ABOVE_CEILING, COMPLEXITY_ABOVE_CEILING (a function above the ceiling, not recorded),
// COMPLEXITY_ABOVE_RECORD (a recorded function risen), STALE_ALLOWLIST_ENTRY (a ceiling naming no class file, a record
// naming no function above the ceiling). Exit 0 clean, 1 a rule fired, 2 nothing could be measured — no CoffeeScript
// MEASURED_ON found, or a source the analyzer cannot parse (it parses each whole file as CoffeeScript 2.7 does, so a
// spelling only the browser's meta-system accepts — a bare `super` followed by a postfix `if` — must be spelled
// `super(…)` or stand on its own line). That every rule bites is proven on every build by
// check-complexity-ratchets-selftest.js.
//
// Run from Fizzygum/ (the build's gate table does): node ./buildSystem/check-complexity-ratchets.js [--src=DIR]
// [--tests-repo=DIR] — the rails check another src tree or tests repo (a copy carrying a plant).

const fs = require('fs');
const path = require('path');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const { METHOD_HEADER, STATIC_METHOD_HEADER } = require('./lib/coffee-method-header');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'complexity-ratchets');
rejectPositionalArgs(ARGV, 'complexity-ratchets', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'complexity-ratchets');

// the classes held, their files (src-relative) and their ceilings — recorded 2026-11-13 at the tree's own counts
const METHOD_CEILINGS = {
  Widget: { file: 'basic-widgets/Widget.coffee', ceiling: 391 },
  WorldWdgt: { file: 'WorldWdgt.coffee', ceiling: 126 },
  ActivePointerWdgt: { file: 'ActivePointerWdgt.coffee', ceiling: 74 },
  FrameWdgt: { file: 'FrameWdgt.coffee', ceiling: 173 },
};

const COMPLEXITY_CEILING = 15;
// the CoffeeScript the records were measured on: another version's AST may score differently
const MEASURED_ON = '2.7.0';
// every function above the ceiling when the ratchet landed (2026-11-13), at the value it had: it may fall, not rise
const RECORDED = {
  'ActivePointerWdgt#_advancePressAndHoldRecognition': 29,
  'ActivePointerWdgt#_declareDragEmbedEphemerals': 19,
  'ActivePointerWdgt#_dispatchEventsFollowingMouseMove': 30,
  'ActivePointerWdgt#_updateDragEmbedStateMachine': 17,
  'ActivePointerWdgt#determineGrabs': 37,
  'ActivePointerWdgt#drop': 42,
  'ActivePointerWdgt#processPointerDown': 22,
  'ActivePointerWdgt#processPointerUp': 80,
  'BrowserInputBridge#_initKeyboardEventListeners': 19,
  'CaretWdgt#_oneScrollCaretIntoViewPassNoSettle': 21,
  'CaretWdgt#processKeyDown': 30,
  'Class#constructor': 61,
  'Class.endingInReturn': 16,
  'Class.rewriteSuperCalls': 25,
  'CommandPanelWdgt.rowLabelsNaming': 21,
  'DashboardsIconAppearance#_dashboardBarMetrics': 24,
  'DashboardsIconAppearance#_dashboardLineMetrics': 33,
  'DashboardsIconAppearance#_dashboardSpreadDots': 38,
  'DataflowEngine#_orderTopologically': 41,
  'DataflowEngine#_processNode': 18,
  'DegreesConverterIconAppearance#_thermoMetrics': 34,
  'Deserializer.whyItCanNeverBeRestored': 16,
  'DiffingPatchNodeWdgt#diff': 23,
  'Duplicator#_duplicate': 16,
  'Example3DPlotWdgt#drawPlot': 18,
  'FrameBarWdgt#_positionAndResizeChildren': 33,
  'FrameBarWdgt#_reDeriveRosterNoSettle': 23,
  'FrameWdgt#_frameLook': 24,
  'FrameWdgt#_positionAndResizeChildren': 48,
  'FrameWdgt#preferredExtentForWidth': 20,
  'GlassBoxBottomWdgt#_reLayoutSelf': 17,
  'InspectorWdgt#selectionFromList': 21,
  'LCLCodePreprocessor#_avoidLastArgumentInvocationOverflowing': 29,
  'LCLCodePreprocessor#_completeImplicitFunctionPasses': 17,
  'LCLCodePreprocessor#_preprocess': 33,
  'LCLCodePreprocessor#_rearrangeColorCommands': 23,
  'LCLCodePreprocessor#_transformTimesSyntax': 22,
  'LCLCodePreprocessor#beautifyCode': 27,
  'LCLCodePreprocessor#checkBasicSyntax': 30,
  'LCLCodePreprocessor#constructor': 17,
  'LCLTransforms#scale': 18,
  'ListWdgt#_buildAndConnectChildrenNoSettle': 17,
  'MacroToolkit#_widgetAPressMeets': 20,
  'MacroToolkit#titleGrabPoint': 17,
  'MacroToolkit#verifyPressLanding': 22,
  'PatchNodeWdgt#_heightsSplitByWeights': 25,
  'RectangularAppearance#paintIntoAreaOrBlitFromBackBuffer': 17,
  'ScriptIconAppearance#_scriptMetrics': 27,
  'Serializer._buildObjectTable': 106,
  'Serializer.serializeWorld': 37,
  'SimpleSpreadsheetWdgt#_presentCellNoSettle': 23,
  'SimpleSpreadsheetWdgt#_reconcileViewportNoSettle': 24,
  'SimpleSpreadsheetWdgt#_reindexCellsNoSettle': 24,
  'SimpleSpreadsheetWdgt#scrolledBy': 24,
  'StackElementsSizeAdjustingWdgt#nonFloatDragging': 19,
  'StackLayoutEngine.arrange': 43,
  'StorageSorter#_auditStorageNoSettle': 27,
  'StringWdgt#_addTextMenuEntries': 18,
  'StringWdgt#activated': 17,
  'StringWdgt#searchLongestFittingTextByMultiCroppingIt': 55,
  'TemplatesIconAppearance#_heartOutline': 30,
  'TextWdgt#getWrappingData': 19,
  'TransformFrameWdgt#_depositIslandBufferDamageRect': 18,
  'TransformFrameWdgt#_refreshIslandBuffer': 17,
  'TypewriterIconAppearance#_typewriterKeyMetrics': 20,
  'VerticalStackPanelWdgt#_positionAndResizeChildren': 19,
  'ViewportWdgt#_positionAndResizeChildren': 23,
  'ViewportWdgt#_reLayoutScrollbars': 26,
  'ViewportWdgt#takeStrokeScrollFrom': 93,
  'Widget#_destroyNoSettle': 18,
  'Widget#_getRecursiveStackDim': 22,
  'Widget#_insertAddersSuchThat': 18,
  'Widget#_reLayout': 19,
  'Widget#_resolvePickOutFigureNoSettle': 21,
  'Widget#clipThrough': 20,
  'Widget#cornerRadiiFollowingMyOutline': 17,
  'Widget#subWidgetsMergedPreferredBounds': 16,
  'Widget.functionLiteralReading': 25,
  'WorldInventory#diffAgainstBaseline': 28,
  'WorldInventory#takeInventory': 130,
  'WorldWdgt#__reLayoutOneSettleNode': 16,
  'WorldWdgt#_checkARectWithHierarchy': 29,
  'WorldWdgt#_fleshOutDamage': 22,
  'WorldWdgt#_fleshOutFullDamage': 22,
  'WorldWdgt#_recalculateLayoutsBody': 30,
  'WorldWdgt#_repaintDamagedRects': 18,
  'WorldWdgt#_runChildrensStepFunction': 16,
  'WorldWdgt#_severLivenessEdgesIntoWdgtNoSettle': 16,
  'WorldWdgt#_updateEditorSelectionOverlay': 16,
  'WorldWdgt#addDragAffordanceWidgets': 21,
  'WorldWdgt#loadWorldSnapshot': 67,
  'boot/dependencies-finding.coffee#extractDependenciesFromSource': 35,
  'boot/extensions/SWCanvasElement-extensions.coffee#swCanvasEnsureAtlasForFont': 22,
  'boot/extensions/SWCanvasElement-extensions.coffee#swCanvasInstallPoisonedKeyRecorder': 18,
  'boot/globalFunctions.coffee#boot': 30,
  'boot/globalFunctions.coffee#createWorldAndStartStepping': 20,
  'boot/globalFunctions.coffee#loadJSFilePromise': 18,
};
const RECORDED_IN_HARNESS = {
  'AutomatorLoader#loadImagesOfTest': 34,
  'AutomatorLoader#selectTestsFromTagsOrTestNames': 32,
  'AutomatorPlayer#matchOrRecordSWCanvasScreenshot': 20,
  'AutomatorPlayer#replayTestCommands': 25,
  'SystemInfo#constructor': 25,
  'WorldTestSupport#nextStartupAction': 26,
};

// ---- measure everything first: a run that cannot measure fires no rule
let analyzer;
try {
  analyzer = require('./lib/cognitive-complexity').analyzerOn(MEASURED_ON);
} catch (e) {
  console.error(`[complexity-ratchets] ERROR — cannot run the analyzer: ${e.message}`);
  process.exit(2);
}
const files = compiledFiles(ROOTS);
const scored = [];                // { key, complexity, where, harness }
let functions = 0;
for (const p of files) {
  const text = fs.readFileSync(p, 'utf8');
  const r = analyzer.analyze(text, p);
  if (r.error) {
    console.error(`[complexity-ratchets] ERROR — the analyzer cannot parse ${sourceName(p, ROOTS)} as CoffeeScript ${MEASURED_ON}: ${r.error}`);
    process.exit(2);
  }
  const lines = text.split('\n');
  for (const f of r.functions) {
    functions++;
    if (f.complexity <= COMPLEXITY_CEILING) continue;
    const name = sourceName(p, ROOTS);
    const classSide = STATIC_METHOD_HEADER.test(lines[f.line - 1] || '');
    const key = f.klass ? `${f.klass}${classSide ? '.' : '#'}${f.name}` : `${name}#${f.name}`;
    scored.push({ key, complexity: f.complexity, where: `${name}:${f.line}`, harness: name.startsWith('harness/') });
  }
}

const failures = [];
const notes = [];

// ---- method counts
for (const [klass, { file, ceiling }] of Object.entries(METHOD_CEILINGS)) {
  const p = path.join(ROOTS.src, file);
  if (!fs.existsSync(p)) {
    failures.push(rules.fired('STALE_ALLOWLIST_ENTRY', `  STALE_ALLOWLIST_ENTRY  METHOD_CEILINGS.${klass} names ${file}, which does not exist — fix the path or delete the entry`));
    continue;
  }
  const n = fs.readFileSync(p, 'utf8').split('\n').filter((l) => METHOD_HEADER.test(l) || STATIC_METHOD_HEADER.test(l)).length;
  if (n > ceiling) {
    failures.push(rules.fired('METHOD_COUNT_ABOVE_CEILING', `  METHOD_COUNT_ABOVE_CEILING  ${klass}: ${n} methods (ceiling ${ceiling}) — ${file}`));
  } else {
    console.log(`[complexity-ratchets] method-count ${klass}: ${n} (ceiling ${ceiling}) -- ${n < ceiling ? 'UNDER' : 'OK'}`);
    if (n < ceiling) notes.push(`  NOTE ${klass} holds ${n} methods: lower METHOD_CEILINGS.${klass} to ${n} here, to lock the gain in`);
  }
}

// ---- cognitive complexity
const met = new Set();
for (const s of scored) {
  const table = s.harness ? RECORDED_IN_HARNESS : RECORDED;
  const recorded = table[s.key];
  if (recorded === undefined) {
    failures.push(rules.fired('COMPLEXITY_ABOVE_CEILING', `  COMPLEXITY_ABOVE_CEILING  ${s.key}: ${s.complexity} (ceiling ${COMPLEXITY_CEILING}) — ${s.where}`));
    continue;
  }
  met.add((s.harness ? 'harness ' : '') + s.key);
  if (s.complexity > recorded) {
    failures.push(rules.fired('COMPLEXITY_ABOVE_RECORD', `  COMPLEXITY_ABOVE_RECORD  ${s.key}: ${s.complexity} (recorded ${recorded}) — ${s.where}`));
  } else if (s.complexity < recorded) {
    notes.push(`  NOTE ${s.key} scores ${s.complexity}: lower its record (${recorded}) to ${s.complexity} here`);
  }
}
const stale = (table, prefix, label) => {
  for (const [key, recorded] of Object.entries(table)) {
    if (!met.has(prefix + key)) {
      failures.push(rules.fired('STALE_ALLOWLIST_ENTRY', `  STALE_ALLOWLIST_ENTRY  ${label}['${key}'] (${recorded}) names no function above the ceiling — it fell to ${COMPLEXITY_CEILING} or below, or is gone: delete the entry`));
    }
  }
};
stale(RECORDED, '', 'RECORDED');
stale(RECORDED_IN_HARNESS, 'harness ', 'RECORDED_IN_HARNESS');
const under = notes.filter((n) => n.includes('lower its record')).length;
console.log(`[complexity-ratchets] complexity: ${functions} function(s) scored on CoffeeScript ${analyzer.coffeescript.version}; ` +
  `${scored.length} above ${COMPLEXITY_CEILING}, recorded ${Object.keys(RECORDED).length} in src + ` +
  `${Object.keys(RECORDED_IN_HARNESS).length} in the harness` +
  ` -- ${under ? 'UNDER' : 'OK'}`);
for (const n of notes) console.log(n);
if (failures.length) {
  console.error(`\n[complexity-ratchets] FAIL — ${failures.length} problem(s):`);
  for (const f of failures) console.error(f);
  console.error('\nA ratchet may fall and may not rise: split the function or the class rather than raising a number here.');
  process.exit(1);
}
console.log('[complexity-ratchets] OK -- every held class at or under its method ceiling, every function at or under its record.');
process.exit(0);
