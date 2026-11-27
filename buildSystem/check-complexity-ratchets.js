#!/usr/bin/env node
'use strict';
// check-complexity-ratchets.js — two RATCHETS in the check-stinks.js style, each a BUDGET
// (docs/architecture/lint-and-static-checks.md §3b): a recorded value that may fall, and rises only in the change that
// needs it, its dated reason beside it (docs/archive/top-10-cleanups-plan.md §8 step 1).
//
// METHOD COUNT. The four classes that grew with nothing holding them — Widget, WorldWdgt, ActivePointerWdgt and
// FrameWdgt — each hold at most METHOD_CEILINGS' count of methods: the lines of its file that open a method, instance
// or class-side, by the ONE definition of a method header (lib/coffee-method-header.js METHOD_HEADER and
// STATIC_METHOD_HEADER — a wrapped signature counts once, a parameter default holding a call counts). Methods, not
// lines: a line ceiling would punish the comments this project asks for. A class under its ceiling prints UNDER:
// lower the ceiling here, to lock the gain in. A class over it fails; when the right shape needs the member — a named
// helper, a public door, an intent-named notification, the member's natural home, a long method split into its
// phases — the ceiling rises in the same change.
//
// COGNITIVE COMPLEXITY. No function of the compiled sources (src/ and the tests repo's harness, lib/source-files.js
// compiledFiles) scores above COMPLEXITY_CEILING — 15, the published default of SonarSource rule S3776, which the
// analyzer implements — unless it is RECORDED below: a record may fall, and rises only with a dated reason beside it.
// A function above the ceiling with no record fails. It is RECORDED, its dated reason beside the entry, when it is born
// of a split that lowers a recorded parent, or when no real seam remains to split it along (state threaded through
// many-parameter helpers, or a cut across a try/finally, is no seam). A function's key is `Class#method` (instance side),
// `Class.method` (class side), or `<file>#name` for one outside any class (a boot file's). A recorded one that fell
// prints UNDER (lower its record); one that fell to the ceiling or below, or that no longer exists, leaves its entry
// excusing nothing: STALE, delete it. The harness's records (RECORDED_IN_HARNESS) are judged like src's: the harness is
// always read (the build requires the tests repo). The analyzer is the coffeescript-cognitive-complexity package
// package.json pins, loaded by lib/cognitive-complexity.js on the CoffeeScript the records were measured on (MEASURED_ON).
//
// RULES: METHOD_COUNT_ABOVE_CEILING, COMPLEXITY_ABOVE_CEILING (a function above the ceiling, not recorded),
// COMPLEXITY_ABOVE_RECORD (a recorded function risen), STALE_ALLOWLIST_ENTRY (a ceiling naming no class file, a record
// naming no function above the ceiling). A failing run prints, once per budget rule that fired (the three but the stale
// entry, whose own line says what to do), what its number holds back and when a raise is the answer
// (lib/gate-advice.js). Exit 0 clean, 1 a rule fired, 2 nothing could be measured — no CoffeeScript
// MEASURED_ON found, no analyzer installed (`npm ci` in Fizzygum/), or a source the analyzer cannot parse (it parses each whole file as CoffeeScript 2.7 does, so a
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
const { adviceLines } = require('./lib/gate-advice');

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS], 'complexity-ratchets');
rejectPositionalArgs(ARGV, 'complexity-ratchets', 'a src tree is named with --src=DIR');
const ROOTS = sourceRoots(ARGV, 'complexity-ratchets');

// the classes held, their files (src-relative) and their ceilings — recorded 2026-11-13 at the tree's own counts,
// lowered whenever a class holds fewer, and raised, the dated reason beside the number, when the right shape needs a
// member
const METHOD_CEILINGS = {
  // raised 391 -> 392 on 2026-11-16, owner-approved (the right shape over the count): sitsInViewModeContent, the one
  // question "do I sit in content in view mode", asked by the world's editable focus and by a text's own menu.
  // Raised 392 -> 393 on 2026-11-20 for the editing residue's follow-ups (loop 3, H4b), the owner's grant of one dated
  // raise and the right shape over the count: actOnLayoutKnobFromMenu, the one door through which a layout spec's
  // menu rows name the widget's knob by reader (a row names an outside widget's PART by the widget plus a name), so a
  // copied pinned "Layout in stack" or "Layout in row" menu drives the real spec, not a clone. Raised 393 -> 394 on
  // 2026-11-20 under the owner's standing ruling of 2026-11-16 (the right shape over the count):
  // isLeftOutOfCopiesAndSaves, the one question both walkers ask of a widget the world keeps in a tree (the text
  // caret, an ephemeral overlay), so a copy or a save of what it stands in leaves it out. Lowered 394 -> 393 on 2026-11-22:
  // isVisuallyTransformed is the one answer to whether an island turns or scales a widget, so its private twin,
  // which only the dock band asked, is gone. Raised 393 -> 394 on 2026-11-22 under the owner's standing ruling of
  // 2026-11-16 (the right shape over the count): boxPresentedToOverlays, the box every widget presents to an overlay
  // laid over it, answered on Widget, overridden by a viewport keeping a margin, and asked plainly by its readers.
  // Raised 394 -> 395 on 2026-11-22 under the same ruling: _removeFromTreeNoSettle, the core of removeFromTree, which
  // settles round it as every public structural mutator does (the end-of-cycle capstone found the bin's close button
  // and "Make pointer" leaving the removal's layout to the end of the cycle). Raised 395 -> 396 on 2026-11-22 under
  // the owner's standing ruling of 2026-11-16 (the right shape over the count): _addMyDivisionCellMenuEntries, the
  // division-cell submenu step every cell offers and the layout chrome overrides with nothing. Raised 396 -> 397 on
  // 2026-11-25 under the same ruling: _informOfValue, the VALUE door beside inform (the message door): a bubble
  // titled with a value's printed form, shown as it is, never re-cased as a message is. Lowered 397 -> 395 on
  // 2026-11-25: the code prompt's door (textPrompt) and the one-text reader of a paint tool's code (injectProperties,
  // compilePropertyAssignments and its two helpers) are gone, a tool being an object the inspector edits; in their
  // place the door's verb for "edit my code" (inspectMemberToEdit), its menu row (_addEditCodeMenuEntry) and the one
  // body every holder's member edit shares (injectPropertyInto). Raised 395 -> 396 on 2026-11-26 under the
  // owner's standing ruling of 2026-11-16 (the right shape over the count): keepSourceWith, the kept-source store's
  // one writer, so a paint tool keeping the text of a member it could not make writes no private field of Widget's
  // Lowered 396 -> 395 on 2026-11-27: _moveBottomSideTo went with its one caller, ListWdgt._applyExtent (a list's
  // growth moved its rows inside its pinned plane, by whichever extent a frame applied: a render the cadence chose).
  // raised 395 -> 401 on 2026-11-27 under the owner's standing ruling of 2026-11-16 (the right shape over the count; the
  // inspector-browser plan's U3.2, the owner's ruling L15): a Children list offers the widget menu's Duplicate and Delete
  // where the menu offers them, so the menu's guards are statements both ask — _widgetToAskMenuTo (which widget a
  // right-click asks), developerMenuReachesMe (does the right-click reach my own menu), windowClosedInMyPlace (the close
  // redirect, three inline copies made one) — and Duplicate asks its OWN question: copyPlaceBesideMe (the next place,
  // free, or none) with duplicateBesideMe (a copy beside its original) and _standCopyFreeIn (a free copy's treatment, one
  // statement the menu's Duplicate shares)
  Widget: { file: 'basic-widgets/Widget.coffee', ceiling: 401 },
  // raised 126 -> 128 on 2026-11-16, owner-approved (the right shape over the count): content in view mode refuses
  // restyling through one public door, editableEditorFocus, and the edit-mode flip is announced by its own
  // intent-named notification, noteEditModeChanged. Raised 128 -> 129 on 2026-11-18 for the toolbar residue's U3, on
  // the owner's request for the clean shape: _keepEditingOnScreenNoSettle, the once-per-cycle station that ends an
  // edit whose text left the screen and announces where the editor focus stands, so a tool's look follows what it may
  // act on whatever put the focus away (a close, a hide, a collapse, a drag out of a window), with no hook in those
  // cores. Raised 129 -> 130 on 2026-11-22 under the owner's standing ruling of 2026-11-16 (the right shape over the
  // count): _stepsMember, the one question the step station and the two pump queries ask of a member: is it on the
  // world or the hand, and not banned. Raised 130 -> 136 on 2026-11-22 under the owner's standing ruling of 2026-11-16
  // (the right shape over the count): loadWorldSnapshot is its phases — each step that settles nothing and leaves no
  // local for a later one is a private core it calls in order (_restoreSnapshotIdCounters,
  // _restoreSnapshotPreferences, _restoreSnapshotWorldState and _installSnapshotStorageAndAppWindows inside its one try,
  // _attachSnapshotChildrenNoSettle inside the attach's settle after it), and its notice's text is composed by _sourceEditsNoticeFor,
  // pure; the guards, every settle and the try that guarantees a bin and a shelf stay in the public method
  WorldWdgt: { file: 'WorldWdgt.coffee', ceiling: 136 },
  // raised 74 -> 77 on 2026-11-27 under the owner's standing ruling of 2026-11-16 (the right shape over the count; the
  // inspector-browser plan's U4): a gesture whose first click opened a thing apart consumes its later clicks, and the hand
  // is where presses and releases are decided — noteClickActsForItsGesture (a button's opening click tells the hand),
  // _pointerContinuesAnActedGesture (the one event-time measure, read at the press and the release) and
  // _releaseGoesOnWithAnActedGesture (the record carried on or ended at each release)
  ActivePointerWdgt: { file: 'ActivePointerWdgt.coffee', ceiling: 77 },
  // raised 170 -> 171 on 2026-11-17 under the owner's standing ruling of 2026-11-16 (the right shape over the count): a
  // window is a holder of a paint tool and answers the person's pair (armedDrawingTool / armDrawingTool), offers its
  // docked payloads (dockedPayloads) and the window whose edge slot it occupies (dockHost) as generic queries, so a
  // toolbar can ask whom it works for; the paintingOverlay chain and _dockedToolbar went. Raised 171 -> 172 on
  // 2026-11-18, owner-granted for the toolbar residue's U4 (owner ruling #8): smallestExtentKeepingMyBandsUsable, the
  // extent a person's grip drag stops at so every docked bar's overflow chevron stays usable, derived from the bands
  // (renamed smallestExtentKeepingMyControlsUsable on 2026-11-19 for the editing residue's U9, when the titled strip's
  // floor joined it: the same count, one question).
  // Raised 172 -> 173 on 2026-11-18, owner-granted for the toolbar residue's U5: offersEditToggle, the ONE definition
  // of a window's pencil, which its strip reads and which bounds view mode's downward inheritance. Lowered 173 -> 170
  // on 2026-11-20 for the scroll indicators' U2b: a window hears its content leave in ONE seat, _reactToChildRemoved,
  // whatever the door, so its three per-verb hooks (_beforeChildPickedUp, _beforeChildClosed, _beforeChildDestroyed)
  // are gone. Lowered 170 -> 168 on 2026-11-21 for the scroll indicators' U3: a document keeps its margin itself, so
  // no viewport stands between a window and the page whose ring it paints (_visibleBoxOnMyPage's translation climb
  // went, its island test folded into hostsSelectionRingOf), and the ring's reach is one derived theme value
  // (Theme.pageSelectionOutlineReach) the window and a viewport both read (_pageSelectionRingReach went). Lowered
  // 168 -> 167 on 2026-11-21 for the scroll indicators' U4d: a window shows its content only inside the box it gives
  // it by answering the one per-child clip question every clipping container answers (_clipThroughForChild, declared
  // on ClippingWdgt, whose paint now paints a rounded frame's children inside its outline), so the window's two
  // child-paint overrides went (_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow and its JustShadow
  // twin). Raised 167 -> 176 on 2026-11-23 under the owner's standing ruling of 2026-11-16 (the right shape over the
  // count), for the dock a frame hovers over: the hand outlines the band the release would MAKE, which the host
  // answers from the terms the dock itself would produce, each with one home the arrange and the measure share --
  // bandBoxIfDocked (the public answer), _edgeDockSpecFor (the spec a dock hands over, built for the dock and for its
  // picture), _bandBoundsAt (where a band stands, lifted out of the arrange), _slotThicknessFor (what a band takes of
  // the body), _chromeBesidesStripsAcross (the chrome a band measures across itself, the term _chromeHeight and
  // _chromeWidth now add their strips to), _steadyContentHeight (the measure's steady rule, its chrome as
  // parameters) and _bandBoxTakenOf (what the frame takes of the box it is granted: a text's band in a side column
  // keeps the text's height); _bandThicknessUnder took _dockedBandThickness's place, the spec passed in. And for the offer, which a
  // frame in view mode no longer makes: _myModeEngagesMyDocks (asked by the offer and by a fresh dock's spec) and
  // _holdsAnEditMode (the one definition offersEditToggle and it both read). Raised 176 -> 181 on 2026-11-23 under
  // the same ruling, for the several bands of a side: a side holds a list of bands and no dock destroys one, so the
  // one-occupant read (_dockedFrameAt) went, and four terms came that the measure, the arrange and the outline
  // share -- _bandsAt (a side's bands that count), _bandThicknessesAt (what each measures), _sideThicknessFor (what
  // bands of those thicknesses take of my body, summed once for the measure and the placement) and _bandBoxesAt
  // (where each band of a side stands, the one home of the placement) -- one for my bands as a whole
  // (_framesInMySlots: whether a widget is one of them, what I wear, which bands a content change chooses among), and the floor
  // one band asks of my extent (_floorKeepingBandUsable), lifted out of smallestExtentKeepingMyControlsUsable now
  // that it runs per band. Raised 181 -> 182 on 2026-11-24, the same ruling, for a band's strip: _offersCollapse
  // (whether my strip offers its collapse piece: a band only where collapsing gives room back), the one question
  // _barSpec's roster asks
  FrameWdgt: { file: 'FrameWdgt.coffee', ceiling: 182 },
};

const COMPLEXITY_CEILING = 15;
// the CoffeeScript the records were measured on: another version's AST may score differently
const MEASURED_ON = '2.7.0';
// every function above the ceiling, at the value it may not rise above: the tree's own scores on 2026-11-13, and each
// later record or raise with its dated reason beside it
const RECORDED = {
  // raised 29 -> 32 on 2026-11-23 under the owner's standing ruling of 2026-11-16 (the right shape over the count),
  // owner-approved fix: the hold books the pop-up its menu request opened (_pressHoldMenu), at the request, so the
  // lift that follows puts away that menu and no other fresh pop-up — the message a refused copy raises in the
  // lift's own move stays for the person to read (toolbar-template-one-size plan, the finger finding)
  'ActivePointerWdgt#_advancePressAndHoldRecognition': 32,
  'ActivePointerWdgt#_declareDragEmbedEphemerals': 19,
  'ActivePointerWdgt#_dispatchEventsFollowingMouseMove': 30,
  'ActivePointerWdgt#_updateDragEmbedStateMachine': 17,
  // raised 37 -> 41 on 2026-11-23 under the owner's standing ruling of 2026-11-16 (the right shape over the count):
  // the creator arm's guard for a creator that makes nothing (a tool cell's copy refused, and the person told), the
  // twin of the Template arm's own guard beside it, at its arm's nesting depth; the lid of a tool cell drags through
  // this arm (toolbar-template-one-size plan, Phase 2)
  'ActivePointerWdgt#determineGrabs': 41,
  'ActivePointerWdgt#drop': 42,
  // 17 -> 19 on 2026-11-27 (U4): the press that continues an opened-apart gesture takes no audience, its own branch
  'ActivePointerWdgt#processPointerDown': 19,
  // 76 -> 77 on 2026-11-27 (U4): the no-click branch also takes a later release of an opened-apart gesture
  'ActivePointerWdgt#processPointerUp': 77,
  'CaretWdgt#_oneScrollCaretIntoViewPassNoSettle': 21,
  'CaretWdgt#processKeyDown': 26,
  'Class#constructor': 61,
  'Class.endingInReturn': 16,
  'Class.rewriteSuperCalls': 25,
  'CommandPanelWdgt.rowLabelsNaming': 21,
  'DashboardsIconAppearance#_dashboardBarMetrics': 24,
  'DashboardsIconAppearance#_dashboardLineMetrics': 33,
  'DashboardsIconAppearance#_dashboardSpreadDots': 38,
  'DataflowEngine#_orderTopologically': 41,
  'DegreesConverterIconAppearance#_thermoMetrics': 34,
  'Deserializer.whyItCanNeverBeRestored': 16,
  'DiffingPatchNodeWdgt#diff': 23,
  'Duplicator#_duplicate': 16,
  'Example3DPlotWdgt#drawPlot': 18,
  // raised 33 -> 34 on 2026-11-24 under the owner's standing ruling of 2026-11-16 (the right shape over the count):
  // the strip records whether it shows no piece and no title (gripMarkShows, a layout output its skin's grip mark
  // reads) where its arrange learns it (several-bands plan, U4)
  'FrameBarWdgt#_positionAndResizeChildren': 34,
  // lowered 23 -> 20 on 2026-11-24: the collapse switch's build went to _addCollapseSwitchNoSettle
  'FrameBarWdgt#_reDeriveRosterNoSettle': 20,
  // raised 24 -> 25 on 2026-11-24, the same ruling: the look's grip-mark role (barGripMark: a card's strip, none on a
  // window's)
  'FrameWdgt#_frameLook': 25,
  // raised 46 -> 47 on 2026-11-24 under the owner's standing ruling of 2026-11-16 (the right shape over the count): a
  // band's first arrange takes the steady path, its host dictating its box -- a frame built inside the settle that
  // docks it took the first-placement negotiation's height (its payload's 50x40 construction extent: a 40 px viewport
  // in a 44 grant, a 46x87 stub in a side column) and no later pass corrected it (several-bands plan, U1b)
  'FrameWdgt#_positionAndResizeChildren': 47,
  // raised 17 -> 18 on 2026-11-24, the same ruling, the measure's twin of the condition above: a band measures as its
  // arrange takes it, the steady way (several-bands plan, U1b)
  'FrameWdgt#preferredExtentForWidth': 18,
  'LCLCodePreprocessor#_avoidLastArgumentInvocationOverflowing': 29,
  'LCLCodePreprocessor#_beautifyCode': 27,
  'LCLCodePreprocessor#_completeImplicitFunctionPasses': 17,
  'LCLCodePreprocessor#_preprocess': 33,
  'LCLCodePreprocessor#_rearrangeColorCommands': 23,
  'LCLCodePreprocessor#_transformTimesSyntax': 22,
  'LCLCodePreprocessor#checkBasicSyntax': 30,
  'LCLCodePreprocessor#constructor': 17,
  'LCLTransforms#scale': 18,
  'ListWdgt#_buildAndConnectChildrenNoSettle': 17,
  'MacroToolkit#titleGrabPoint': 17,
  'MacroToolkit#verifyPressLanding': 22,
  'PatchNodeWdgt#_heightsSplitByWeights': 25,
  'RectangularAppearance#paintIntoAreaOrBlitFromBackBuffer': 17,
  'ScriptIconAppearance#_scriptMetrics': 27,
  // raised 106 -> 109 on 2026-11-20 under the owner's standing ruling of 2026-11-16 (the right shape over the count):
  // a widget's children are encoded as a save carries them, one line in encodeOwnProps beside the detach-root's
  // parent, the copy's same rule (Duplicator._clonePropertyInto) — the caret and the ephemeral overlays the world
  // keeps under a widget are left out of its record
  'Serializer._buildObjectTable': 109,
  'Serializer.serializeWorld': 35,
  'SimpleSpreadsheetWdgt#_presentCellNoSettle': 23,
  'SimpleSpreadsheetWdgt#_reconcileViewportNoSettle': 24,
  'SimpleSpreadsheetWdgt#_reindexCellsNoSettle': 24,
  'SimpleSpreadsheetWdgt#scrolledBy': 24,
  // the split's closed-form solve, recorded at 19 as StackElementsSizeAdjustingWdgt#nonFloatDragging. Re-keyed on
  // 2026-11-24 and read at 18: the solve is a QUERY of its own (the split a wanted leading edge asks for), which
  // the splitter's drag handler asks, mapping its own pointer and making the two deferred max-dim writes itself; the
  // handler keeps the guard and the mapping, well under the ceiling. (An inspector browser's divider, a kind of
  // splitter, and its split button ask a solve of the divider's own, InspectorDividerWdgt#sizeDraggedTo.)
  // Re-keyed 2026-11-26 (inspector-browser U1), score unchanged: with the split button asking the column divider's
  // solve, the splitter's own handler is this query's only caller, so it is _-private (check-call-separation [U]).
  'StackElementsSizeAdjustingWdgt#_maxDimsPuttingMyLeadingEdgeAt': 18,
  'StackLayoutEngine.arrange': 43,
  'StorageSorter#_auditStorageNoSettle': 27,
  'StringWdgt#activated': 17,
  'StringWdgt#searchLongestFittingTextByMultiCroppingIt': 55,
  'TemplatesIconAppearance#_heartOutline': 30,
  'TextWdgt#getWrappingData': 19,
  'TransformFrameWdgt#_depositIslandBufferDamageRect': 18,
  'TransformFrameWdgt#_refreshIslandBuffer': 17,
  'TypewriterIconAppearance#_typewriterKeyMetrics': 20,
  'VerticalStackPanelWdgt#_positionAndResizeChildren': 19,
  'ViewportWdgt#_positionAndResizeChildren': 23,
  'ViewportWdgt#takeStrokeScrollFrom': 92,
  'Widget#_destroyNoSettle': 18,
  'Widget#_getRecursiveStackDim': 22,
  'Widget#_insertAddersSuchThat': 18,
  'Widget#_reLayout': 19,
  'Widget#_resolveStandingFigureNoSettle': 21,
  'Widget#cornerRadiiFollowingMyOutline': 17,
  'Widget#subWidgetsMergedPreferredBounds': 16,
  'Widget.functionLiteralReading': 25,
  'WorldInventory#diffAgainstBaseline': 28,
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
  // lowered 67 -> 23 on 2026-11-22: its phases that settle nothing and hand no local on are private cores it calls
  // (each at or under the ceiling); what remains is the four guards, the load-then-re-enter step, every settle (the
  // informs among them), the steps that hand their locals past the try, and the try round the restore
  'WorldWdgt#loadWorldSnapshot': 23,
  'boot/dependencies-finding.coffee#extractDependenciesFromSource': 35,
  'boot/extensions/SWCanvasElement-extensions.coffee#swCanvasEnsureAtlasForFont': 22,
  'boot/extensions/SWCanvasElement-extensions.coffee#swCanvasInstallPoisonedKeyRecorder': 18,
  'boot/globalFunctions.coffee#boot': 30,
  'boot/globalFunctions.coffee#loadJSFilePromise': 18,
};
const RECORDED_IN_HARNESS = {
  'AutomatorLoader#loadImagesOfTest': 25,
  'AutomatorLoader#selectTestsFromTagsOrTestNames': 32,
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
  // a stale entry's own line says what to do; the three budgets print what their numbers hold back and when a raise is
  // the answer
  const budgets = [...rules.firedIds].filter((id) => id !== 'STALE_ALLOWLIST_ENTRY');
  if (budgets.length) { console.error(''); for (const l of adviceLines(rules.gate, budgets)) console.error(l); }
  process.exit(1);
}
console.log('[complexity-ratchets] OK -- every held class at or under its method ceiling, every function at or under its record.');
process.exit(0);
