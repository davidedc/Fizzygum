# Runtime + test-side gates: quiet-fix audit

Date: 2026-11-21. Tree: Fizzygum `b6b2f60f`, Fizzygum-tests `e06b7c26a`. Read-only audit: nothing built, run or edited.
Scope: the runtime tokens (`NON_INTEGER_GEOMETRY`, `NON_FINITE_GEOMETRY`, `WORLD_CONSTRUCTION_DRIFT`, `WORLD_INVENTORY_*`),
the gauntlet's audit legs, and the macro-test discipline. Static build gates and ratchet numbers are the sibling reports
in this directory (`static-gates-audit.md`, `gate-severity-classification.md`).

Every claim is marked **VERIFIED** (I read the tree line, the commit or the ledger myself) or **INFERRED** (from shape,
or from a sub-worker's reading of a session that I did not re-open; where a sub-worker read the session and I read the
tree, it says "session INFERRED, tree VERIFIED"). Verdicts: CONTORTION-STANDING, CONTORTION-UNDONE, DEFENSIBLE, RIGHT
SHAPE, UNSURE.

---

## 0. Headline

The gates themselves are in good order. Every allowlist is either empty or fails when stale (`STALE_ALLOWLIST_ENTRY`);
the world-state exemption list holds one name; the revisit baseline is `{}`; the serialization expectations hold no
expected-fail; there is no pixel tolerance, no skipped or quarantined test, no known-flake list.

What still stands is mostly on the TEST side, plus three "it behaves otherwise while a test plays" or wall-clock spots
in product input code. Thirteen items, ordered by what they cost to leave:

| # | Standing contortion | Where | Gate that drove it | Blast | Pixels |
|---|---|---|---|---|---|
| S1 | Row LOCATORS silently scroll an over-tall pop-up, outside the input queue | `Fizzygum/src/macros/MacroToolkit.coffee:1944` (callers `:1995 :2041 :2076`) | AIM MISSED / macros unravelling once rows were 44 px | M–L | likely |
| S2 | Two tests declared mouse-only after their finger capture missed a clamp by 19 px | `tests/SystemTest_macroSimpleDocumentAllReflowsCorrectlyAsIChangeFontSize/….js:13`, `tests/SystemTest_macroSimpleTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent/….js:13` | finger axis | S–M | finger refs only |
| S3 | A cancel-path test declared mouse-only for one hover assertion of nine | `tests/SystemTest_macroPointerCancelEndsNonFloatDrag/….js:13`, commands `:73` | finger axis | S | finger refs only |
| S4 | A capture whose verify fails is re-captured until it verifies, then reported "captured + verified" | `Fizzygum-tests/scripts/capture-macro-test-references.js:247–290` | byte-exact references | S | none |
| S5 | The list-row verb stacks three scroll mechanisms; the newest runs last so old replays keep their pixels | `MacroToolkit.coffee:2476–2498` | byte-exact references | M | yes (inspector tests) |
| S6 | The edge auto-scroll runs on `Date.now()`; its test polls for up to 20 s instead | `Fizzygum/src/basic-widgets/ViewportWdgt.coffee:1363–1374`; `tests/SystemTest_macroListWdgtAutoScrollsNearDraggedEdge/…_automationCommands.js:40–75` | a parallel-only failure | S–M | none expected |
| S7 | The scroll glide is suppressed while a test plays | `ViewportWdgt.coffee:1311` | screenshot determinism | M | yes if un-suppressed |
| S8 | Pressed moves are event-only while a test plays | `Fizzygum/src/ActivePointerWdgt.coffee:1974` | screenshot determinism | S–M | none expected |
| S9 | A test asks the product's own rule for its expected value | `tests/SystemTest_macroThumbHighlightOnlyUnderAPointer/…_automationCommands.js:20 :29 :33–35 :62` | the test's own re-point (mixin removal) | S | new shots |
| S10 | A reference recaptured over a known defect (the caret's last column under the border) | `Fizzygum/src/basic-widgets/CaretWdgt.coffee:468`; `Fizzygum/docs/BACKLOG.md:163` | revisits | S | one test |
| S11 | A leaf guard where the menu sweep threw; the cause is filed | `Fizzygum/src/demos/BouncerWdgt.coffee:23`; `BACKLOG.md:227` | menusweep (`STEP_ERROR`) | S | none |
| S12 | Two rows that throw when clicked cold are allow-listed | `Fizzygum-tests/scripts/menu-click-sweep-headless.js:181–184` | menusweep | S | none |
| S13 | A test's example class was swapped so the row it presses happens to show | `tests/SystemTest_macroInspectorOpensAClassInItsClassInspector/…_automationCommands.js:56–62` | AIM MISSED | S | none |

Section 12 has each with its quoted lines, evidence and fix. Section 11 has the events the sessions show. One pattern
runs through those events and is worth more than any single item: **the commonest quiet answer was not an exemption, it
was "pre-existing / load flake / out of scope → FILED"**, and in seven recorded cases the real fix happened only after
the owner pushed (11c).

---

## 1. `WORLD_CONSTRUCTION_DRIFT` → `_worldStateAuditExemptions`

**No standing contortion. VERIFIED.**

### The full table (`Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee:272–282`)

| Entry | Stated reason | Against the rule | Verdict |
|---|---|---|---|
| `"lastTime"` (`:281`) | "Widget's constructor seeds `@lastTime = Date.now()`, and the world is a widget … It is the one exemption reconstruction itself creates … `lastTime` is per-member stepping bookkeeping, read only for widgets in `steppingWdgts` (_runChildrensStepFunction), and the world never joins its own set. It cannot reach a render." | a clock reading taken at construction; no render reads it | DEFENSIBLE |

That is the whole list. Two mechanisms beside it also exempt, and belong in the same table:

| Mechanism | What it exempts | Verdict |
|---|---|---|
| The derived-cache RULE, `_isDerivedCacheFieldName` (`:324–325`): any field named `cached…` or `check…Cache` | today eight pairs: `TreeNode`'s `cachedRoot`, `cachedFirstParentClippingAtBounds`; `Widget`'s `cachedFullBounds`, `cachedFullClippedBounds`, `cachedVisibleBasedOnIsVisibleProperty`, `cachedClippedThroughBounds`, `cachedClipThrough`, `cachedIsInCollapsedSubtree`; each with its `check…Cache` stamp | DEFENSIBLE (the stamps are monotonic version counters). Blind spot: it exempts by NAME, so a future world field called `cachedSomething` that is no derived cache would never be fingerprinted. |
| Functions and unreadable fields are skipped (`:350–354`) | methods; a getter that throws | RIGHT SHAPE |

History (VERIFIED, `git log -L272,282`): the list held forty-three names until `812a12355` (2026-08-21, "The ratchet's
exemption list drops from forty-three names to one"), when a reset became a reconstruction. It reports its own stale
entries (`:393–398`). CONTORTION-UNDONE for the old list. No session in the transcript window added or proposed a name
(four sub-workers, `git log -G` over both repos; INFERRED for what they did not reach).

---

## 2. `WORLD_INVENTORY_*`, vmtruth, teardown hygiene, storage invariant

**No standing contortion; three declarations worth a second look. VERIFIED unless marked.**

### `WorldInventory.pageLifetimeStores` (`Fizzygum/src/WorldInventory.coffee:35–46`) — every entry

| Match | Policy | Stated reason | Verdict |
|---|---|---|---|
| `^world\.cacheFor` | bounded | the text/paint LRUs evict at their own capacity | DEFENSIBLE |
| `^world\.widgetsWithMaybeChanged\w*PaintBounds$` | bounded | per-cycle damage queues; the teardown filters dead entries | DEFENSIBLE |
| `^statics\.Color\._cache$` | bounded, cap 300 | the Color intern LRU | DEFENSIBLE |
| `^swCanvasText\.(atlasRequested\|missingAtlases)$` | monotonic-ok | one entry per atlas id per page | DEFENSIBLE |
| `^swCanvasText\.(coldGlyphWidgets\|poisonedCacheKeys)$` | bounded, no cap | "per-refresh transients … the world teardown additionally drops destroyed entries at its seam" | **UNSURE** (below) |
| `\.instancesCounter$` | monotonic-ok | lifetime allocation counter | DEFENSIBLE |
| `\.lastBuiltInstanceNumericID$` | monotonic-ok | zeroed by the sweep, re-advanced by re-construction | DEFENSIBLE |
| `^statics\.WorldWdgt\.(frameCount\|geometryVersion\|structureVersion\|visibilityVersion\|immutableBackBufferGeneration)$` | monotonic-ok | cycle/version counters | DEFENSIBLE |
| `^sourceVault\.entries$` | monotonic-ok | grows only when a lazy part loads | DEFENSIBLE |
| `^dom\.headScripts$` | monotonic-ok | "the test loader appends per-test script tags; spent tags are page-lifetime residue by current design" | **DOUBTFUL** — a declared harness leak, stated in shipping code |
| `^statics\.Automator\.state$` (pushed by the harness, `WorldTestSupport.coffee:424–427`) | monotonic-ok | the runner's own state machine | DEFENSIBLE |

- **`coldGlyphWidgets` is "counted but NOT walked"** (`WorldInventory.coffee:278–281`: "walking it would zombie-report a
  race that is benign by design"). It is the one store the identity audit is told not to look into. The teardown core
  now drops destroyed entries at its seam (contract (B), `Fizzygum/CLAUDE.md`), so at the audit's seat the race may no
  longer exist and the carve-out may exempt nothing. *Measurement:* a `--prelude` plant that walks the list inside
  `takeInventory`, over the suite on both pointers; zero ZOMBIE lines ⇒ delete the carve-out. The carried-widget atlas
  flake of 2026-11-17 (Fizzygum `420b4089`) lived in this store.
- **`dom.headScripts`**: every test's metadata, commands and reference loaders stay in `<head>` for the life of a shard
  page. Declared, not removed. Low; no render reads it.
- **Report-only families** (`:61–74`: `objects`, `strings`, `canvases`, `containers`, `typedArrays`, `walker`):
  aggregates, "gating them would fire on legitimate churn (… 1469 hits on a green suite)". DEFENSIBLE; identity
  (ESCAPED / ZOMBIE) is gated absolutely.

### The other instruments
- **vmtruth**: no grace period, no exemption table. The soft spot is the pin cap (`MAX_PINNED = 200`,
  `scripts/audit-preludes/vm-truth-prelude.js:76`): past it the leg reads INVALID and fg's serial retry absorbs it.
  Filed at `BACKLOG.md:65`; it read INVALID in-wave at least five times in nine days (cleanups-loop-4 U1 and U3,
  editing-residue U5, follow-ups-2 G1, scroll-indicators; ledgers VERIFIED). Two tests were then SHAPED round the cap:
  the scroll-indicators research told its new test to "move a few rows by drag and reach the far end by ONE setter call"
  (`.scratch/scroll-indicators-loop/u5/RESEARCH.md:748`; session INFERRED) and the ledger notes "cell churn kept low for
  vmtruth, ~190" (`scroll-indicators-loop/LEDGER.md:1292`, VERIFIED). FILED-NOT-FIXED, and now steering test design.
- **storage invariant**: no baseline file, by design; the Tier B prelude has no skip list and announces its own
  blindness (`STORAGE-SKIPPED`). One partly inert call: the Tier A audit at the test-teardown seat
  (`WorldTestSupport._beforeBeingDissolved`, `:186–187`) runs after the teardown core has destroyed the bin and the
  shelf, so its bin and shelf scans (`Fizzygum/src/StorageSorter.coffee:170–186`) find nothing to read there and only
  the tracker-member check is live. The harness comment says so (`:176–178`) and the owner was told on 2026-10-23
  (session INFERRED). DOUBTFUL, low: move the call ahead of the container teardown, or drop the two scans from that seat.
- **serialization rigs**: `EXPECTATIONS` holds 192 names, all `true` (`scripts/lib/serialization-expectations.js`);
  `SWCANVAS_ONLY_CHECKS` and `DYNAMIC_FAMILIES` fail when stale. RIGHT SHAPE.
- **Teardown core (B) lines** (a class static, the tooltip timer registry, the cold-glyph array): page-lifetime stores
  letting go of dead widgets. A cause fix, not a nulling added to pass. RIGHT SHAPE.
- **Leaks found by a follower** were fixed where they came from: 42 `WORLD_INVENTORY_` lines after "Don't save" → a
  test-side `win.fullDestroy()` was tried, found to reach nothing, and REMOVED in favour of the product fix
  (Fizzygum `8e4393c6`; session INFERRED). Two others were the test's own cleanup (`destroy()` → `fullDestroy()`), which
  is the rule for a test. RIGHT SHAPE.

---

## 3. Revisit, settle, census, tier-naming, capstone

**One standing item (S11, a leaf guard), one site UNSURE, two gate-prompted shapes judged defensible.**

- **Revisit baseline**: `scripts/revisit-baseline.json` is `{}` and has been since `f8a94c334` (2026-07-17). VERIFIED.
- **Census**: `KNOWN_MOVERS = {}`, `NOT_BATTERIED = {}` (`scripts/staleness-census.js:286 :121`). A temporary
  `KNOWN_MOVERS` entry of 2026-11-05 ("for now it is recorded in the census as a stated finding") was removed the next
  morning with the engine fix (`37c33386`, `cb5e3452c`; session INFERRED, tree VERIFIED). CONTORTION-UNDONE.
- **Tier-naming**: `EXEMPT = {}` (`scripts/tier-naming-audit/tier-naming-prelude.js:91`). `NON_GEOMETRY` (`:61–73`)
  sanctions eleven `_apply*`/`_commit*` names that are not geometry corners, each with what it is. DEFENSIBLE.
- **Settle gate**: one precision carve-out, the orphan-construction auto-defer
  (`notification-settle-prelude.js:62–73`). DEFENSIBLE.

### The capstone's sanction is the declaration window — every site

`Widget._deferredSettleDeclare` (`Fizzygum/src/basic-widgets/Widget.coffee:6034`) marks the pushes it covers as
intentional, so the capstone does not count them. It is the capstone's quiet fix by construction, so each site owes a
reason. The engine's own entrypoints (`:2407 :2600 :2782 :2821 :6021`) are the mechanism. The four hand-placed windows:

| Site | Added | Reason stated | Verdict |
|---|---|---|---|
| `ActivePointerWdgt.coffee:777` — the drop's `_reExpressFigureForPlaneOfNoSettle` | 2026-07 | "the drop's target.add carries the settle"; re-judged 2026-11-21: "may stay declared (the hand answers no removal)" | DEFENSIBLE |
| `Widget.coffee:2274` — `_resolveStandingFigureNoSettle` (the fold of a reused figure) | 2026-07-17, narrowed 2026-11-21 | "rides the caller's own grab settle" | DEFENSIBLE |
| `WorldWdgt.coffee:2228` — the focus station's two `noteFocusChanged` | 2026-10-23 (`a9ad4424`) | "riding the flush that follows is its whole design and no settle may open inside the station" | DEFENSIBLE. Written BEFORE any build: "Without it … the capstone leg would flag it once V makes the focused title bold. At today's values it never fires." (session INFERRED) |
| `WorldWdgt.coffee:1969` — `_keepEditingOnScreenNoSettle` → `_stopEditingNoSettle` | 2026-11-18 (`bbe570c5`) | "the ended edit's caret leaves a layout for this cycle's flush, a deferral DECLARED as such" | **UNSURE** |

- **CONTORTION-UNDONE, and the lesson for this table** (VERIFIED, commit `71a656b1`, 2026-11-21): the pick-up resolver
  ran its EXTRACTION inside a declaration window from 2026-07-17. "Measured on the product before this change: a tilted
  Docs Maker's 'Pick up' ran 7 layout flushes inside the removal notification, the Maker shrank 600x400 -> 52x129 … the
  capstone gate saw nothing (every mark was declared)." The extraction now settles, and the rule is written at
  `Widget.coffee:6029–6033`: a core that takes a widget out of a holder that answers its removal runs inside a settle.
- **`WorldWdgt.coffee:1969` under that rule.** The capstone did not fire first; the window was written by analogy with
  the focus station ("checking how the existing focus station declares the layout deferral … so the caret teardown in
  mine follows the same rules"; session INFERRED). But `_stopEditingNoSettle` destroys the caret — a one-shot structural
  removal, where the 11-21 ruling keeps "one-shot structural mutations out of declarations". Whether the caret's holder
  answers its removal by building decides it. *Measurement:* the notification-settle gate and a flush counter round the
  station, on the tests that end an edit by hiding or collapsing its text. The owner's ruling wanted: may a per-cycle
  station declare a structural mutation?

### Shapes the gates prompted
- **`BouncerWdgt.step`** — S11, section 12.
- **`MenuItemWdgt._refreshRowEnablementConnector`** (`Fizzygum/src/basic-widgets/menu-system/MenuItemWdgt.coffee:501`;
  edge action `"refreshRowEnablement"`, `:213`). Renamed from `_applyRowEnablementConnector` in review because "the
  tiernaming leg would flag _applyRowEnablementConnector (matches its _apply* corner pattern, not in its NON_GEOMETRY
  table) → action renamed refreshRowEnablement (it applies nothing; no table growth)"
  (`.scratch/overnight-toolbar-residue/LEDGER.md:155`, VERIFIED). A prediction, not a firing. The body is `@_changed()`
  and the new name says so; its sibling `_applyRowReflectionConnector` (`:482`) does apply and sits in the table.
  **DEFENSIBLE**. The phrase "no table growth" is the thing to notice: a sanction table that people avoid growing has
  started to act as a ratchet. (On 2026-11-08 the same table took `_applyPropertyAddition` without fuss — session INFERRED.)
- **`StringWdgt._sizeToTextAndDisableFittingInMyParentsArrangeNoSettle`** (`Fizzygum/src/basic-widgets/StringWdgt.coffee:1665`,
  2026-10-24). A second sizing core that omits the layout schedule, because through the ordinary one "the walk re-lays
  it a SECOND time in that flush -- a depth-0 re-visit, which the standing revisit gate … fails on" (`:1660–1664`).
  It is the engine's in-arrange idiom (a parent placing a child through a non-notifying twin) and its constraint on
  callers is written down. **DEFENSIBLE**, INFERRED from shape.
- Three re-visit or careless-push firings were answered at the cause: the revisits leg on the caret laid out twice
  (2026-10-20; but see S10 for what it left), the revisits on a new test (2026-11-05, owner chose the fix), the capstone
  on `_miniatureOf` and the settle gate's `CACHED_DERIVATION_DIVERGED` after it (2026-11-04, Fizzygum `513839b6`,
  `Duplicator.coffee:296`). Sessions INFERRED.

No "if already laid out, return" guard added beside a gate failure turned up in the tree or the ledgers.

---

## 4. `NON_INTEGER_GEOMETRY`

**No standing contortion. One blind spot of the guard, which is not a quiet fix but belongs here.**

- The commit leaves that round (`Widget._moveToNoSettle` `:2395`, `_setExtentNoSettle` `:2588`, `__commitExtent` `:2643`,
  `_setBoundsNoSettle` `:1301`) are the DESIRED-geometry funnel the policy names
  (`docs/architecture/integer-pixel-placement-and-sizing.md` §2). The arrange-apply path asserts and does not round.
  VERIFIED by reading.
- Every `Math.round` / `.round()` ADDED to `src` since 2026-10-10 (`git log -p -G`, about 70 added lines in 16 commits)
  sits where the fractional value is computed: icon geometry, toolbar piece distribution, the spreadsheet's zoomed
  pitches, ratio-locked extents, screen-family points under a tilt, the wheel scale. None is at a consumer. VERIFIED.
  A `NON_INTEGER_GEOMETRY` from an unrounded icon inset (redesign W4) was floored at its producer
  (`WidgetHolderWithCaptionWdgt.coffee:220`; INFERRED). A `NON_FINITE_GEOMETRY` in the scroll-indicators loop was fixed
  in product (`EdgeDockLayoutSpec.notePayloadLeft`; INFERRED).
- **Blind spot**: `ClippingWdgt._applyMoveBy` (`Fizzygum/src/basic-widgets/ClippingWdgt.coffee:257–261`) rewrites
  `@bounds` and each child's (`__commitMoveBy`) without `_assertBoundsWellFormed`, so the guard cannot see a fractional
  MOVE of any clipping class — every window among them. The mixin-removal review recorded it as a ledger line only
  ("the NON_INTEGER/NON_FINITE guard is blind to moves of the 62 clipping classes; pre-existing … integer-pixel doc
  :67–77 claims every leaf checks — worth the owner's look", `.scratch/mixin-removal-loop/LEDGER.md:100–102`, VERIFIED).
  It is in no BACKLOG line. Not a contortion: a gate that reports nothing where it cannot look.
- Not checked: rounding added between 2026-07-01 and 2026-10-10.

---

## 5. Paint audit, capstone, damage

**No suppression list exists. VERIFIED.**

- `scripts/run-paint-audit.js` and `AutomatorPlayer._checkPaintTruthfulness` (`:141`) carry no per-test exemption and no
  region mask. The audit runs ONCE per test, at `stopTestPlaying`: narrow by design, a blind spot rather than a
  contortion.
- No tolerance anywhere: `scripts/lib/imgdiff.js:18`, "the mask is `d >= 1`, never a tolerance".
- Widened damage (`_fullChanged` where `_changed` was right): not auditable by grep. No ledger of the fourteen records a
  `_fullChanged` added to quiet the paint leg (VERIFIED by grep), and no sub-worker found one in a session.
- A tooling note: `scripts/end-of-cycle-audit/eoc-production-probe.js:5` says it "reports precisely what the CAPSTONE
  gate will see", which is false for the caret (the product audit skips inert receivers, `CaretWdgt.coffee:373–376`).
  It over-reported 20–22 pushes in the scroll-indicators loop and cost two investigations (INFERRED). Fix the header or
  mirror the inert branch.

---

## 6. Macro tests

### 6a. Declared aims (`pressMustLandOn`)
179 uses in 97 tests. Every receiver is a widget named by meaning: `@spreadsheetCellAt …` (47), `world` (9, a press
meant for the bare desktop), `grab.piece`, `slider`, `panel.contents`, … No receiver is computed from the press point
(`topWdgtAt…`, `_topWdgtAtScreenPoint`), the "whatever the press hit" spelling. **VERIFIED: that spelling does not
occur.** In the sessions, each `AIM MISSED` that was read was answered by meaning (nine tests on 2026-10-16 that "passed
only because an earlier recapture had baked the wrong behaviour", each fixed with value assertions; the W5 drops
re-aimed "by meaning … adding an order assertion"; INFERRED) — with three softer cases:
- **S13** (section 12): the example class swapped so the row shows.
- `macroClassEditShowsOnTheNextFrame` commands `:181–187`: a click past a line's end "landed on the pane behind the
  text. The edit still worked", so the test now clicks just BEFORE a code string and erases forwards. Commented
  honestly; the past-line-end click is no longer exercised. UNSURE, low.
- `macroWindowCellsInConstrainedScrollStackReflow` commands `:72–74`: the release moved to `[0.5, 0.7]` of the window,
  "above the bottom dock band … where a release would dock the cell instead of stacking it". A fraction, with its
  reason beside it and a suite-wide press/drop trace behind it. DEFENSIBLE; aiming at "the first cell's lower half"
  would say it by meaning.

### 6b. Mouse-only tests — all sixteen

`pointerKinds: ["mouse"]` occurs in sixteen metadata files (a seventeenth only mentions the word in its provenance).
Twelve have screenshots and no `finger/` reference directory; four are assertion-only. No undeclared test lacks finger
references (VERIFIED by walking `tests/`).

| # | Test | Declared | Subject (its own `intent`) | Reason given | Verdict |
|---|---|---|---|---|---|
| 1 | macroDimmedToolCellStaysDarkUnderThePointer | 2026-11-17 `ef0541b5c`, at authoring | the hover fill of a tool cell | a finger never rests | DEFENSIBLE |
| 2 | macroFingerPlainDragScrollsWhereMouseLifts | 08-26 `fb5d3bcfe` | the finger/mouse contrast | the mouse half needs a mouse | DEFENSIBLE |
| 3 | macroFingerTapEditSummonsVirtualKeyboard | 08-26 | a tap summons the keyboard, a mouse click does not | under finger every click is a tap | DEFENSIBLE |
| 4 | macroHoverMovePositionMappedInRotatedIsland | 08-26 | the position a `hoverMoved` delivers | a finger emits no hover move | DEFENSIBLE |
| 5 | macroNestedScrollPanelsRouteWheel | 10-20 `d55a20adb` (finger refs removed); reason re-measured 10-24 | the wheel's per-notch routing | a finger has no notch; the finger counterpart is macroNestedPanesDragLatchesOnePane | DEFENSIBLE |
| 6 | macroMouseDragScrollOfMenuRowsFiresNoRow | 10-23 `d48ab45bf` | "the rule … for the MOUSE" | the finger half is pinned elsewhere | DEFENSIBLE |
| 7 | macroPointerCancelEndsNonFloatDrag | 08-26 | the non-float arm of `processPointerCancel` | "It asserts the POINTER-UNDER state … expected 1 found 0" | **CONTORTION-STANDING (S3)** |
| 8 | macroScrollIndicatorFattensAndDrags | 08-26 | the hover-fattened indicator | fattening is declared out for touch | DEFENSIBLE |
| 9 | macroScrollPolicyNeverFlip | 08-26 | the `scrollPolicy 'never'` crop/scroll flip | "a finger has no wheel to have refused, and the drag it would substitute is refused at a different seam" | **UNSURE** |
| 10 | macroSimpleDocumentAllReflowsCorrectlyAsIChangeFontSize | 08-27 `15e723d7e`, after its finger capture | font-size-driven reflow | "cannot land ON a clamp to the pixel … only the return diverges" | **CONTORTION-STANDING (S2)** |
| 11 | macroSimpleTextScrollPanelUpdatesWellWhenWrappingUnwrapping… | 08-27, after its finger capture | the wrap toggle under an end-scrolled viewport | "the second lands 19 px short at 736" | **CONTORTION-STANDING (S2)** |
| 12 | macroSpreadsheetScrollWheel | 08-26 | the wheel's row/column quantization | the subject is the wheel | DEFENSIBLE |
| 13 | macroSpreadsheetResizeViewport | 08-26 | viewport derivation, cell recycling | the sheet takes no drag-scroll | DEFENSIBLE as a recorded product gap (`BACKLOG.md:96`) |
| 14 | macroSpreadsheetScrollRichCellRetain | 08-26 | a hidden rich cell is retained | same | DEFENSIBLE as a recorded product gap (`BACKLOG.md:96`) |
| 15 | macroTrackPressInTheFatteningCycleStillPages | 10-15 `59dcb5c79` | a hover move and a press in one cycle | a finger's arrival and press are one event | DEFENSIBLE |
| 16 | macroTwoEditsOnOneRingInOneCycle | 10-15 `c5a219952` | the dataflow one-edit-per-ring rule | "the rule under test does not depend on the pointer" | DEFENSIBLE, with a note |

Notes:
- **13, 14**: still true. Only `ViewportWdgt` answers `claimsPlainDragsForScrolling` (`ViewportWdgt.coffee:653`);
  `SimpleSpreadsheetWdgt` extends `ScrollIndicatorHostWdgt` and takes no drag-scroll (VERIFIED after the
  scroll-indicators loop). When the sheet gains a finger scroll these two lose their reason; 12 keeps its own.
- **9**: no measured finger failure is quoted. The subject is the policy flip; the wheel is its probe. *Measurement:*
  `run-macro-test-headless.js SystemTest_macroScrollPolicyNeverFlip --pointer=finger` with the declaration removed. If
  the swipe lifts the panel, that is the touch grammar working and the finger claim wants its own test; none pins it.
- **16**: the subject is no mouse mechanism, so by the letter of the rule it should not be mouse-only. A finger run
  would replay the same raw mouse events and add nothing. Harmless.
- **The opposite failure is filed and open**: `BACKLOG.md:156` — macroHierarchyMenuHoverHighlightsExactSubtree "replays
  under a finger with no wash pixel"; it still carries `finger/` references and no `pointerKinds` (first seen
  2026-10-21: "finger run passes without testing anything … Filed in the BACKLOG, nothing done"; put to the owner
  10-29, undecided; INFERRED). A finger reference that shows nothing is a test green for the wrong reason.
- **The right shape for ONE mouse-only assertion exists and is in use**: `unless @fingerMode()` round it
  (macroCollapsedBarGrip `:68`, macroWindowGripStrip `:59 :79`, macroEditingFollowsAParagraphOffScreen `:136`,
  macroSheetScrollIndicators `:89`, macroDocumentKeepsItsMargin `:355`). VERIFIED.
- A product contortion for the finger axis was PROPOSED and declined: "I first recommended stopping fingers from
  fattening the bar… it broke 12 finger tests… You chose to keep the shipped behaviour, so I reverted" (2026-10-15;
  INFERRED).

### 6c. Waits and idle cycles
Wait verbs in macro sources: `yield "waitNoInputsOngoing"` (4090), `yield "waitForScreenshotReady"` (193), and a
numeric `yield <ms>` in 16 tests (dwell holds of 600 ms, a tooltip's 1500 ms: the tests' own subjects). Two spellings
are the "wait added" shape:

**A poll loop** — one test, S6: `until (list.getScrollX() is scrollLimitX()) or heldOn >= 20000` / `yield 100`, four
times (`macroListWdgtAutoScrollsNearDraggedEdge` commands `:42 :52 :62 :72`). VERIFIED.

**A doubled `waitNoInputsOngoing`** — thirteen sites in four tests (VERIFIED by scanning every commands file for two
identical consecutive wait lines):

| Test | Sites | Written | What the second wait is for |
|---|---|---|---|
| macroSheetScrollIndicators | `:78–79 :84–85 :124–125 :172–173 :185–186 :190–191` | 2026-11-21 | not stated |
| macroSheetScrollPins | `:179–180` | 2026-11-21 | stated, `:174–177`: "The sheet re-derives at its arrange, inside the layout pass, so the slider re-reads one cycle later: a second wait." |
| macroDocumentKeepsItsMargin | `:134–135 :344–345 :363–364` | 2026-11-21 | not stated (each precedes a read of the decline outline and the lock badge after a carried move) |
| macroSimpleDocumentCanAddIndentedParagraph | `:59–60` | migrated test | not stated (after a prompt's OK) |

**UNSURE.** These are deterministic, so they dodge no flake. But the one stated reason records a product property:
after a resize the sheet's bars, and any slider wired to its origin, show the OLD scale for one painted frame, because
the scale is derived in layout, after that cycle's dataflow station. The test waits it out. Either the one-frame lag is
accepted and written into `layout.md` (and the twelve unstated doubles get the same one-line reason), or it is a
defect. *Measurement:* on macroSheetScrollPins drop the wait at `:180` and read `scaleOf rowSlider`; then take a shot
there and compare it with one a cycle later.

**Steps added to keep an identity assertion** (UNSURE; disclosed to the owner at the time, INFERRED): when a selection
ring began to stand through a menu, three tests whose byte-identity claims broke each got "a press on the bare desktop"
before the later shot, which "takes `macroEditModeSlidingToggle` out of the recapture set" — macroEditModeSlidingToggle
commands `:55–59`, macroScrollPolicyNeverFlip `:56–59`, macroSimpleTextScrollPanel…Bottom `:91–92` (tree VERIFIED). The
comments say why and the subject of none of them is the selection. The alternative was to recapture with the ring in
both shots.

### 6d. Assertions narrowed or removed
- **S9** (section 12): three assertions that now compare the product's rule with itself.
- `f1fe12098` (2026-11-02) removed "a collapsed frame offers no grip" from two tests because the product now offers
  one. RIGHT SHAPE.
- `.scratch/editing-residue-followups/LEDGER.md:122`: "dropped the assertion that could not fail and the pitch
  tautology; added the ink's height …". A strengthening. RIGHT SHAPE.
- Mixin removal U8: five state tests were re-pointed from stored state to paint-time answers, and the review found
  "the re-pointed 'told' tests no longer saw the ending told"; pass 3 restored instance spies in three
  (EveryPressIsToldItsEnding +10 assertions, PointerCancelEndsNonFloatDrag +3, WidgetDestroyedOrClosedMidStroke +11;
  `.scratch/mixin-removal-loop/LEDGER.md:531–548`, VERIFIED). The fourth is S9.
- The owner asked on 2026-10-23: "we didn't weaken any of the checks / tests / constraints… did we?" and got two
  disclosures (one dropped layout mark, chosen by him; the inert storage scans of section 2). INFERRED.
- Otherwise no commit message, ledger line or session records an assertion weakened because it failed.

### 6e. Toolkit verbs that rescue a step
Two stand (S1, S5). Judged and found by-meaning: `textSlotScreenPoint`'s ±2 px nudge (checked with the product's own
`slotAt`, faults otherwise), `_handlePressPoint`'s grid scan and `pressPointOf` (stay on the named widget, fault
otherwise), the finger translation's `_aimInsideBox` / `_dragStartInsideSpan`. DEFENSIBLE.

---

## 7. References recaptured over a real difference

**One standing case (S10). The rest checked out or were already fixed.**

- **S10**: the 2026-10-20 revisits fix left "the caret's second column … under the panel's border… I recaptured that
  test alone and filed the border margin" — still open at `BACKLOG.md:163`.
- Fixed historical cases (VERIFIED in memory notes and commits): a recapture that baked in a crash frame (the
  stuck-state canary now lives in the capture script, `:292–306`); `recapture.js` certifying itself falsely
  (`00700691b`); the mass recapture `530b49d4e` (2026-08-25) that baked wrong behaviour into nine tests, found by the new
  `AIM MISSED` check and fixed (`80ee6ca92`); macroMenuInWindowInScrollStackStaysLive's wheel on the wrong pane
  (`d48ab45bf`); two card strips whose "references held a stale arrangement a roster change never re-laid" (`3df542461`);
  macroTiltedWindowDropRequiresDwell's zero-displacement drag (`15e723d7e`); finger references of the slider track that
  "had the bug baked in" (2026-10-15).
- Caught before it landed: a recapture that "was baking the dpr-2 defect into references" was stopped and BitmapText
  fixed (editing-residue follow-ups; INFERRED); a selection ring round the sheet spotted in a fresh reference and fixed
  before the recapture (2026-11-04; INFERRED); "NEEDS RECAPTURE" right after a capture (about 1 in 25) root-caused —
  "pressing a grip raises its window, and the raised window covered its own outline" — and not recaptured over
  (2026-10-31; INFERRED).
- The redesign and focus waves (100–177 tests each) state an owner review of the diff page and a predicted changed set
  (`d55a20adb`, `a57ca60f9`, `3df542461`, `7c71eadad`). VERIFIED for the messages; the per-image reviews are not
  re-auditable.
- **The inspector churn set** (`scripts/inspector-churn-set.json`, sixteen tests; `fg recapture-inspector`,
  `Fizzygum/buildSystem/fg-verbs.js:284`) recaptures every shot of sixteen tests on the strength of set membership,
  while `classify-diff.js` says of the same churn "a real regression inside one of these tests looks identical from
  here". The owner has ruled this recapture a non-cost (memory `byte-identical-not-sacred-for-benign-inspector-recapture.md`),
  and in the sessions read each one was looked at ("With only those two names hidden from the list, it matches its
  references exactly"). **DEFENSIBLE by ruling.** The cause — sixteen tests whose pixels are the member roster of
  framework classes — could be removed with a fixture class the harness owns. A suggestion, not a finding.
- **A capture that does not re-match is retried** — S4.

---

## 8. Runner-side allowlists, skips, tolerances, retries — every entry

| Where | Entry | Reason still true? | Verdict |
|---|---|---|---|
| `menu-click-sweep-headless.js:170` `SKIP` | empty | — | RIGHT SHAPE |
| `:193` `SKIP_PROMPT` | empty | — | RIGHT SHAPE |
| `:178` `KNOWN` | `THREW:throwAnError` | yes, the row exists to throw | DEFENSIBLE |
| | `THREW:deserialiseFromMemoryAndAttachToWorld`, `…AttachToHand` | no — the rows are offered unconditionally, so a cold click throws | **CONTORTION-STANDING (S12)** |
| `:208` `CONDITIONAL_OPENERS` | `OverflowChevronButtonWdgt.triggerToolFromMenu` (flag false) | yes | DEFENSIBLE. The table was born on 2026-10-18 with two more entries (`HandleWdgt.attach`, a lazy test menu); both were removed with their causes (`270bbb82f`, 11-06). CONTORTION-UNDONE |
| `ELLIPSIS_EXCEPTIONS`, `SENTENCE_CASE_EXCEPTIONS` | empty | — | RIGHT SHAPE |
| `PROMPTS_DRIVEN_FLOOR = 53`, `SENTENCE_CASE_ROWS_FLOOR = 3400`, `PIN_CHECKS_FLOOR = 2000`, `APPS_FLOOR = 12` | floors against a vacuous run | each says "never lower it to quieten a red run" | DEFENSIBLE |
| `staleness-census.js:286 KNOWN_MOVERS`, `:121 NOT_BATTERIED` | empty | — | RIGHT SHAPE |
| `lib/gate-tokens.js NOT_GATED` | `DATAFLOW_ERROR` (by-design) | yes; when the runners became fail-closed nothing else had to be excused ("369 tests, gate-violations 0") | DEFENSIBLE |
| | `FIZZYGUM_USE_SWCANVAS` (not-distinctive: excuses nothing) | yes | DEFENSIBLE |
| `expectsCaughtErrors` (metadata) | four tests whose subject IS the catch | yes | RIGHT SHAPE |
| `tier-naming-prelude.js` `NON_GEOMETRY` (11), `EXEMPT` (0) | section 3 | yes | DEFENSIBLE |
| `revisit-baseline.json` | `{}` | — | RIGHT SHAPE |
| `serialization-expectations.js` | 192 × `true` | — | RIGHT SHAPE |
| Known-flake list, quarantine, skipped tests, per-test tolerance | none exists | — | RIGHT SHAPE |
| `fg` leg alarms (`Fizzygum/buildSystem/legs.js`): `selftests` 600 → 900 s on 2026-11-15 | overran at load 35; two options were put to the owner | yes | DEFENSIBLE |

### Retries
| Retry | What it absorbs | Verdict |
|---|---|---|
| `capture-macro-test-references.js:247` `MAX_RETRIES = 2` | a capture whose verify did not re-match | **CONTORTION-STANDING (S4)** |
| `recapture.js:250` one retry of `captureOne` | any capture failure — "the transient browser/boot flake" | DOUBTFUL: the flake it names was a real boot bug, fixed 2026-11-07; the retry does not tell an infra failure from a test that failed while capturing |
| `lib/shards.js:61–67` the probe retried once on ANY thrown exception | added 2026-11-07 after one unexplained crash: "passed on three isolated runs, so… looks like a load flake… making the shard-count probe retry once on any exception" (INFERRED) | DOUBTFUL: never diagnosed; `8ed042297` kept it "a launch or navigation that throws under load". Narrow it to a named launch timeout |
| `lib/audited-suite.js` dropped-shard retry; `run-atlas-fuzz.js:387`; `make-diff-page.js:150` | INVALID / infra only | DEFENSIBLE |
| `fg gauntlet`: a leg that fails in-wave is retried once, alone; pass ⇒ `OK(warn)`, exit 0 (`Fizzygum/buildSystem/fg-commit-point.js:516–537`) | ANY failure — a test's assertion or pixel mismatch included | **DOUBTFUL — owner call** |

**The gauntlet's serial retry.** By `DETERMINISM.md` a test that fails under load and passes alone is a finding; the
retry reports it as a warning and the unit closes. The owner's own words on the first such case: "this is a
deterministic system and there should be no flakiness" (2026-10-15, after a failure was waved as "a load-sensitive
flake already recorded five times"; it was a real same-cycle bug, DETERMINISM §3j; INFERRED). What the retry has
absorbed, every one later shown to be or still suspected to be a real fault:

| Absorbed | Outcome |
|---|---|
| the slider track click (five sightings) | real bug, fixed on the owner's push (Fizzygum `dff5589d`) |
| macroDragEmbedReleaseWhileCharging… (four sightings, each "unexplained one-off") | real test bug (a 250 ms real-time wait against a 450 ms event-time dwell), fixed on the owner's order (`70a2f3ef`) |
| the capstone leg failing on a screenshot in-wave (2026-11-17) | "a real product bug, not load alone", fixed (`420b4089`) |
| menusweep's in-wave `LAYOUT_ERROR` (2026-11-21) | real, fixed after the owner's "Can you fix / improve the mechanism" (`a2015c07`) |
| "CoffeeScript is not defined" boot storms, for months | a real boot bug; the reload retries retired (`8ed042297`). CONTORTION-UNDONE |
| macroInternalVsExternalWindowDrop nesting under load (`mixin-removal-loop/LEDGER.md:107–112`) | **open**, `BACKLOG.md:336`; the fix is known (commands `:37`, a `waitNoInputsOngoing` between carry and release) |
| vmtruth's pin cap (five and more) | **open**, `BACKLOG.md:65` |
| menusweep hanging silently in wave A (twice) | **open**, `BACKLOG.md:157`, unexplained |

A narrower rule would keep the retry for the "measured nothing" family (did not start, DISCONNECTED, INVALID, an alarm)
and report a TEST-level failure that passes alone under its own verdict instead of `OK`. Tooling policy, so it is here
for a ruling and not counted as a contortion.

---

## 9. menusweep, pinsweep, parts

- Skip lists: section 8 (all empty but `KNOWN` and one conditional opener).
- Product code shaped to survive a sweep: one, **S11** (`BouncerWdgt.step`). The three other product comments that
  mention a sweep or a rig (`FrameBarWdgt.coffee:159`, `WidgetHolderWithCaptionWdgt.coffee:146`, `WorldWdgt.coffee:1436`)
  describe behaviour that holds for any code-driven press. VERIFIED.
- The menu fork on `isIndexPage` that hid nine of the desktop's thirteen rows from the sweep is gone
  (`WorldWdgt.coffee:3407`). CONTORTION-UNDONE.
- A rig false positive was fixed in the rig, not papered: the sweep's ellipsis rule stopped "treating a '…' on a
  widget's row as a claim" (2026-11-09; INFERRED).

---

## 10. Product code conditional on being under test — every site

`aTestIsPlaying()` is `Automator? and Automator.state == Automator.PLAYING` (`src/boot/globalFunctions.coffee:177`).
`isIndexPage` is false only on the harness page (`WorldWdgt.coffee:586`). None of these was added in the transcript
window (`git log -G`; one predicate rename on 2026-11-14 touched them all).

| Site | What differs while a test plays | Kind | Verdict |
|---|---|---|---|
| `ViewportWdgt.coffee:1311` `glideSuppressed` | no momentum glide after a drag-scroll release | a mechanism switched off | **CONTORTION-STANDING (S7)** |
| `ActivePointerWdgt.coffee:1974` `pressedMovesAreEventOnly` | pressed moves are delivered only at drained events | a per-cycle re-dispatch switched off | **CONTORTION-STANDING (S8)** |
| `ActivePointerWdgt.coffee:1009` `_holdDecisionTime` | the hold is timed by event time only | clock seam | DEFENSIBLE (a macro supplies the events a still finger does not) |
| `DragChargingRingWdgt.coffee:53` | the ring charges on event time | clock seam | DEFENSIBLE |
| `AnalogClockAppearance.coffee:151` | the clock shows 10:08:37 | clock seam | DEFENSIBLE |
| `FridgeMagnets3DCanvasWdgt.coffee:117`, `Example3DPlotWdgt.coffee:138`, `GraphsPlotsChartsWdgt.coffee:18` | animation clock is event time, or frozen | clock seam | DEFENSIBLE |
| `BlinkerWdgt.coffee:16` | the caret does not blink | clock seam | DEFENSIBLE |
| `ToolTipWdgt.coffee:62` | a tooltip appears at once, with no 500 ms timer | a timer switched off | DOUBTFUL — the timer path, its cancellation and `ongoingTimeouts` (one of the three (B) teardown stores) are run by no test |
| `Widget.coffee:651`, `StringWdgt.coffee:620` `toString` | the instance number and the text extract are hidden | a fork of what is shown | DOUBTFUL — every inspector value, error text and scatter seed a test sees differs from the product's. A reset now reconstructs the world and zeroes the id counters, so the fork may no longer be needed. *Measurement:* remove it, run the suite at two shard counts and compare. Blast L if labels move. |
| `ButtonWdgt.coffee:166` `if Automator? and typeof @action isnt 'string'` | a wrong `action` throws a named error only where the harness ships | dev tripwire | DOUBTFUL, low — a `typeof` costs nothing unconditionally |
| `TreeNode.coffee:336` | an `INVARIANT_VIOLATED` line when a macro looks for no widget | diagnostic | DEFENSIBLE |
| `ActivePointerWdgt.coffee:338 :1336 :1394 :1709` | the fake playback pointer and its indicators | test display | DEFENSIBLE |
| `WorldWdgt.coffee:2319–2354 :2438` | the macro pump | harness seat | DEFENSIBLE |
| `WorldWdgt.coffee:616`, `globalFunctions.coffee:639` (`isIndexPage`) | the harness page sizes the canvas to the test screen and opens on a bare desktop | page identity | DEFENSIBLE |
| `WorldWdgt.coffee:3441` | the "System tests" menu row | harness row | DEFENSIBLE |

Not behind the predicate but the same family: the edge auto-scroll's `Date.now()` — **S6**.

No `isIndexPage` fork of a menu or of behaviour is left (`Widget.coffee:5142`, `ControllerWdgt.coffee:417`,
`WorldWdgt.coffee:3407 :3500` are notes saying so). An older skip, the Automator-playback skip in
`checkDraggingThreshold` ("product bug hidden by the skip"), was retired on 2026-10-24/25 and the grab-correction lag
behind it fixed (INFERRED). CONTORTION-UNDONE.

---

## 11. What the sessions and ledgers show

Four sub-workers read the transcripts (assistant text by regex windows, the ledgers first where a loop kept one).
"I" below means I did not re-open the session; every tree line cited was read by me.

### 11a. Quiet fixes that happened

| Date | Where | Gate | What was done (quote) | Now |
|---|---|---|---|---|
| 2026-08-25 | Fizzygum `5a45a135` (no transcript) | AIM MISSED / unravelling macros once menus outgrew the world | the row locators scroll the menu themselves | **STANDING (S1)** |
| 08-26/27 | tests `fb5d3bcfe`, `15e723d7e` (no transcript) | finger axis | three tests declared mouse-only whose subject is no mouse mechanism | **STANDING (S2, S3)** |
| 10-20 | `884ce6f2` L49507–L49754 (I) | revisits | re-visit cause fixed; "the caret's second column now sits under the panel's border… I recaptured that test alone and filed the border margin" | **STANDING (S10)** |
| 10-21 | `884ce6f2` L60836 (I) | none — a finger run "passes without testing anything" | "Filed in the BACKLOG, nothing done" | open, `BACKLOG.md:156` |
| 10-28/29 | `d055260b` L24353–L25039 (I) | parallel-only failure of the auto-scroll test | "test bug… wait on the actual condition": the poll loop | **STANDING (S6)** |
| 11-05 | `20448fdd` L839–L1001 (I) | census | a `KNOWN_MOVERS` entry "for now" | UNDONE next morning (`37c33386`) |
| 11-07 | `9fdab002` L18277–L18299 (I) | a bite-proof control INVALID once | the probe retries once on any exception | standing, DOUBTFUL (section 8) |
| 11-07 | `e75a5bfe` L6641–L9188 (I) | `apps` leg: world never ready | the wait 15 → 60 s, then "retries once in a fresh page" | UNDONE the same day (`8ed042297`) |
| 11-12 | `17e8eba8` L86635–L86651 (I) | AIM MISSED: the `constructor` row below the visible list | "change only the example class to PointerWdgt" | **STANDING (S13)** |
| 11-12 | mixin-removal U8; subagent `a40a6fc3ce` L490 (I) | a re-point for the removed state field | review: "ThumbHighlightOnlyUnderAPointer … The check is vacuous" — not acted on | **STANDING (S9)** |
| 11-17 | Fizzygum `fa5f3417`; `fd5c9317` L2835 (I) | a list row no thumb stop shows | "The fallback only runs after the thumb nudges have failed, so every scroll that passes today replays byte-identically" | **STANDING (S5)** |
| 11-18 | `c3e1441a` L5294 (I) | three byte-identity assertions broke on a persisting ring | a desktop press before the later shot, which "takes `macroEditModeSlidingToggle` out of the recapture set" | standing, UNSURE (6c) |
| 11-19 | `overnight-editing-residue/LEDGER.md:377–382` (VERIFIED) | capstone: `BinOpenerWdgt._activateMyTile` | "Out of scope → FILED … the test builds the bin's window from code instead" | UNDONE 11-20 (Fizzygum `a5d6abc8`; the test "presses a bin link's tile twice", commands `:44–64`) |
| 11-20 | `5fae7abf` L1816 (I) | capstone: 2 careless pushes at `panel.pickUp()` | "the test no longer plays the way back out of the window… I did not fix it" | UNDONE in two hours (owner; `3f05e852`) |
| 11-20 | `scroll-indicators-loop/LEDGER.md:600` | a new test's read: a tilted window grows 249 → 311 | "FILED. The leg now opens the menu, reads the outer window's extent, then closes" | UNDONE 11-21 (owner; `f28da47a`) |
| 11-21 | `5fae7abf` L13806 (I) | menusweep `STEP_ERROR` | "the bouncer's step does nothing without a parent… the world's stepping of detached widgets is not changed here" | **STANDING (S11)** |

### 11b. Gates that fired and were answered at the cause (a sample; all I unless a commit is named)
2026-10-16 nine `AIM MISSED` tests fixed with value assertions (`80ee6ca92`) · 10-17 census `asBuiltMovers=1` → the
retitle re-lays the strip · 10-23 a snapshot-load leak (`escaped=11`) caught by a new rig check (`b913587b`) · 10-31
"NEEDS RECAPTURE" after a capture → a raise leaves overlays on top · 11-04 capstone and settle on the Duplicator
(`513839b6`) · 11-04 a webkit failure where a test asserted V8's own error text → the test types `throw "over budget"` ·
11-05 revisits on a new test → the base sizing call settles pending tracking containers · 11-07 `DID_NOT_START`
root-caused and the retries retired · 11-09 capstone: 10 careless pushes under a candidate shape → the shape dropped
(owner ruling D2a) · 11-11 teardown hygiene `fixtureDirtied 14/15` → the fixture dirties the new field · 11-17 42
`WORLD_INVENTORY_` lines → product fix `8e4393c6` · 11-17 capstone screenshot failure → `420b4089` · 11-21 the pick-up
extraction (`71a656b1`) · 11-21 `NON_FINITE_GEOMETRY` → `EdgeDockLayoutSpec.notePayloadLeft`.

Parks that were the right process: mixin-removal U5 ("a pixel moved that §2.7 does not grant, and the move is
faithful" → PARKED, owner ruled, then recaptured); backlog loop U36 (a code-pane shot outside the recapture grant →
PARKED with its patch).

### 11c. The pattern: filed first, fixed when pushed
| Date | First answer | What moved it |
|---|---|---|
| 10-15 | "a load-sensitive flake already recorded five times" | owner: "this is a deterministic system and there should be no flakiness" |
| 10-17 … 10-22 | four sightings, each an "unexplained one-off… predates this arc" | the owner ordered it worked |
| 10-28 | "pre-existing load-sensitive flakes… log them as BACKLOG" | root-caused the next day (one by a product fix, one by S6's wait loop) |
| 11-04 | over-tall menu: "stale… out of scope; filed" | owner: "address properly these two" |
| 11-05 | revisits on a new test: "outside the naming change… need your call" | the owner chose the fix |
| 11-20 | capstone at `pickUp`: "I did not fix it" | owner: "add the pickUp defect to the scope of this loop" |
| 11-21 | menusweep `LAYOUT_ERROR`: "load-flake", filed | owner: "Can you fix / improve the mechanism" |

Still on the "filed" side today: `BACKLOG.md:39` (no test sees a glide), `:65` (vmtruth pin cap), `:156` (a hover test
vacuous under a finger), `:157` (menusweep hang), `:163` (caret under the border), `:227` (the world steps detached
widgets), `:336` (the unarmed drop under load).

The owner's request for this audit, in his words (2026-11-16, `fd5c9317` L1839, L2071, L2111; I): "Don't make the
solution worse because of the ratchet"; "which other checks besides ratchets might introduce contortions if followed
blindly?"; "…find where we can determine that a suboptimal shape was used to just quiet or silence a gate to comply to
it blindly." He named no examples.

---

## 12. STANDING CONTORTIONS — actionable

### S1. The row locators scroll the menu themselves
- **Where**: `Fizzygum/src/macros/MacroToolkit.coffee:1944–1961`, inside `_menuRowScrolledIntoView`:
  `viewport.setScrollY viewport.getScrollY() + deltaY  if deltaY != 0` (and the X twin), returned as the last line of
  `getTextMenuItemFromMenu` (`:1995`), `rowOfMenuStandingFor` (`:2041`) and `_promptButtonLabelled` (`:2076`).
  137 tests call a verb that goes through one of them.
- **Gate**: `AIM MISSED` / macros unravelling. Introduced with the 44-px touch geometry (`5a45a135`, 2026-08-25), when
  menus first outgrew the 880-px test world. Its own comment: "the click every caller aims there lands on whatever sits
  behind the menu: the submenu never opens and the macro unravels a step later". INFERRED that it was the cheap way back
  to green (no transcript); VERIFIED that it has kept a test green for the wrong reason: memory
  `spreadsheet-ux-brainstorm.md:13` — "its wheel 400 stopped mid-track and the row verbs' _menuRowScrolledIntoView kept
  it green … ⭐⭐ a toolkit verb that RESCUES a step can keep a test green for a reason other than its claim". That one
  test was fixed (wheel 3000, four value assertions); the verb was not touched.
- **Why**: a QUERY changes the world, with a programmatic setter and no input event. No person scrolls a menu that
  way, so the gestures that reach a row past the fold are exercised by one test, and a defect in scrolling an over-tall
  pop-up would leave every other menu test green.
- **Right fix**: the locators answer the row and touch nothing. A press aimed at a row the viewport clips is a fault
  that names the row and how far out of view it is. A separate verb brings a row into view through the input queue
  (`wheelOn` over the rows; a finger run translates it), and the tests that need it say so.
- **Blast**: M–L, unknown until measured. *First:* a `--prelude` plant that makes `_menuRowScrolledIntoView` throw
  when either delta is non-zero, over the suite on both pointers; the failing set is the set that leans on the rescue.
- **Pixels**: shots taken with such a menu open move (a wheel lands on its own offsets) → recapture of that set.

### S2. Two tests are mouse-only because the finger translation misses a clamp
- **Where**: `tests/SystemTest_macroSimpleDocumentAllReflowsCorrectlyAsIChangeFontSize/SystemTest_macroSimpleDocumentAllReflowsCorrectlyAsIChangeFontSize.js:13–16`
  — reason: "… cannot land ON a clamp to the pixel, because a macro step queues all its events before any drain and so
  cannot re-aim between swipes. The away frame is byte-identical to the mouse's; only the return diverges."
  `tests/SystemTest_macroSimpleTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent/….js:13–16` —
  "… the first end-scroll lands exactly on the clamp (offset 755 …), the second lands 19 px short at 736."
- **Gate**: the finger axis. Both had finger references captured and were then declared: `15e723d7e` (2026-08-27),
  "The 52 orphan finger files of the two tests declared mouse-only after their capture are removed." VERIFIED.
- **Why**: neither subject is a mouse mechanism (font-size reflow; the wrap toggle). Each uses the wheel once, to
  OVER-scroll into a clamp (`@wheelOn_InputEvents doc, -2000`, commands `:112`; `@wheelOn_InputEvents panel, 2000`,
  `:96`) before `assertScreenshotsIdentical`. A request to travel 2000 px into a clamp that ends 19 px SHORT of it is
  not explained by "cannot re-aim": overshooting needs no aim. The loader's own rule
  (`AutomatorLoader.coffee:252–254`): "a failure there is either a translation defect or a product one, and gets looked
  at rather than listed". It was listed.
- **Right fix**: (1) find why the translated swipes stop short of a clamp they were asked to pass (the toolkit's
  `_touchScrollBy` legs, or the product's drag-scroll after a re-wrap changed the range); (2) if it is the translation,
  a clamp-landing verb that is a MACRO, so it yields between swipes and stops when the pane reports its limit;
  (3) delete both declarations and capture finger references.
- **Blast**: S–M. **Pixels**: no mouse reference moves; new finger references (13 shots × 2 densities).

### S3. `macroPointerCancelEndsNonFloatDrag` is mouse-only for one assertion
- **Where**: metadata `:13–16`; the assertion is commands `:73`:
  `@assertValuesEqual "and the pointer still rests on it, so it shows its HOVER look", "highlighted", (thumbLook slider.button)`.
- **Gate**: the finger axis, P3 discovery run (`fb5d3bcfe`, 2026-08-26): "expected 1 found 0". VERIFIED (commit,
  metadata); INFERRED that nothing else failed.
- **Why**: the subject is the non-float arm of `ActivePointerWdgt.processPointerCancel`. A cancel is above all a TOUCH
  event, and eight of the nine assertions (`:71 :72 :74–79`) are pointer-neutral. The declaration leaves that arm with
  no finger coverage.
- **Right fix**: `unless @fingerMode()` round `:73`, with the finger's own expectation beside it (`"atRest"`), as
  macroCollapsedBarGrip `:68` does; reword image_1's claim per pointer; delete the declaration; capture finger
  references (2 shots × 2 densities).
- **Blast**: S. **Pixels**: finger references only.

### S4. An unstable capture is retried until it verifies
- **Where**: `Fizzygum-tests/scripts/capture-macro-test-references.js:247` `const MAX_RETRIES = doClean ? 2 : 0;`;
  `:252` `auto-retry … (previous capture unstable/incomplete — likely pre-settle)`; `:275–278`
  `verify dpr=${dpr} did NOT pass — the just-captured ref did not re-match.` → `failedVerify.push(dpr)` → clean, capture
  and verify again; on a later pass `DONE — references captured + verified`, exit 0 (`:309–313`).
- **Gate**: byte-exact references. Added 2026-07-12 (`e9799e8ce`): "pre-settle auto-retry … the script used to print
  'just RE-RUN this capture'; now it does that itself". VERIFIED.
- **Why**: the same header says "SWCanvas and the input-event queue ARE deterministic (capture is byte-identical
  run-to-run) … a verify FAIL is a real disagreement about the pixels". A reference that does not match the very next
  run of its own test is a nondeterminism finding — the lesson of 2026-10-31 ("'NEEDS RECAPTURE' right after a capture
  is a finding", where the 1-in-25 case turned out to be a real z-order bug) — and "likely pre-settle" is what
  `waitForScreenshotReady` exists to fix at the READ. The retry keeps whichever capture happens to verify, so one of two
  renderings becomes the reference and the test is committed flaky.
- **Right fix**: a verify mismatch is its own outcome (UNSTABLE, non-zero exit) that names the shot and both hashes
  and retries nothing. Keep a retry only for a run that measured nothing, which the runner already tells apart (exit 2).
  `recapture.js:250` and `lib/shards.js:61–67` want the same split.
- **Blast**: S. **Pixels**: none. It may surface tests that are unstable today.

### S5. The list-row verb keeps three mechanisms so old replays keep their pixels
- **Where**: `MacroToolkit.coffee:2476–2498` (`bringInViewAndClickOnListItem_InputEvents_Macro`): a bar drag to a
  fraction (`:2273`), then `for attempt in [0..2]` one-pixel thumb nudges (`:2486–2489`), then `for attempt in [0..2]`
  wheel notches (`:2493–2496`). 17 tests use the family.
- **Gate**: byte-exact references. VERIFIED, commit `fa5f3417` (2026-11-17): "Once the nudges fail it now finishes with
  wheel notches, which scroll by content pixels; every scroll the nudges finish replays as it did." In the code
  (`:2490–2492`): "only once the nudges have failed, so every scroll the nudges already finish replays as it is". No
  wheel-only verb was considered in that session's text (I).
- **Why**: the wheel correction is exact by construction (`:2361`, the delta that centres the row). It makes the
  fraction drag and the nudges redundant; they stay because removing them would move the list's offset in existing
  shots. That is recapture churn choosing the design, which the owner has ruled out (memory
  `dont-let-recapture-churn-dictate-design.md`). Two bounded retry loops also let a scroll that half-works end green.
- **Right fix**: one mechanism — the wheel by content pixels, once, then the click (which already faults on a row it
  cannot aim at). Delete the nudge verb and the fraction drag from this verb; recapture.
- **Blast**: M. **Pixels**: yes — the list's resting offset changes in the inspector tests, both pointers, both densities.

### S6. The edge auto-scroll reads the wall clock, and its test polls
- **Where**: `Fizzygum/src/basic-widgets/ViewportWdgt.coffee:1363` `startedAt = Date.now()` and `:1373`
  `@autoScroll pos  unless Date.now() - startedAt < 500`, then one `autoScroll` step per frame (`:1378`, whose apply is
  marked `determinism-exempt`, `:1394`); the comment above (`:1352–1354`):
  "the screenshotted endpoint is frame-cadence-independent even though the path there isn't". The test:
  `tests/SystemTest_macroListWdgtAutoScrollsNearDraggedEdge/…_automationCommands.js:40–45` —
  `yield 2500` / `until (list.getScrollX() is scrollLimitX()) or heldOn >= 20000` / `yield 100`, four times.
- **Gate**: a parallel-only suite failure, 2026-10-28/29; first "pre-existing load-sensitive flakes… log them as
  BACKLOG", then "test bug… wait on the actual condition" (session INFERRED; tree VERIFIED).
- **Why**: the project's contract (`Fizzygum/CLAUDE.md`, Determinism) is that input code is never a function "of
  wall-clock timers (`setTimeout`/`Date.now`), frame/cycle counts". Here the product is both, and the test was made to
  wait it out — up to twenty seconds — instead. It is the only poll loop in the suite.
- **Right fix**: start and advance the auto-scroll on the event/cycle clock (as `DragChargingRingWdgt._elapsedForCharge`
  does), so a hold of a stated length scrolls a stated distance; then the test holds for that long and asserts, with no
  loop.
- **Blast**: S–M. **Pixels**: none expected (the shots are taken at the clamp).

### S7. The glide is switched off while a test plays
- **Where**: `ViewportWdgt.coffee:1303–1313`: "Both that delta and the glide length are FRAME-CADENCE driven … so while
  a test plays the glide is SUPPRESSED outright" / `glideSuppressed = aTestIsPlaying()`.
- **Gate**: screenshot determinism. VERIFIED, commit `7b7bf24b` (2026-06-11): "Make scroll-by-drag deterministic:
  suppress momentum + edge auto-scroll under pacing control".
- **Why**: same contract as S6. The glide is a function of frame cadence in the product; the suppression hides that
  from the suite and leaves the glide with no test (`BACKLOG.md:39`: "the suite suppresses glides, so `isScrollGliding`
  answering false passes every gate and the macro pump's glide gate never closes").
- **Right fix**: drive the glide from event time (velocity from the stroke's own timestamps, decay by elapsed event
  time), delete the flag, and let the pump's existing `isScrollGliding` gate hold a macro until the glide ends.
- **Blast**: M. **Pixels**: every shot taken after a drag-scroll release shows the content where the glide leaves it →
  recapture, the finger axis most of all (it delivers every wheel as swipes).
- Older than the transcripts and documented; listed because it is the shape the audit asks for. Owner call.

### S8. Pressed moves are event-only while a test plays
- **Where**: `Fizzygum/src/ActivePointerWdgt.coffee:1962–1974`: "a cycle landing between the event that ARMS a touch
  stroke and the next queued move turns one withheld move into a delivered one, and a paint tool lays a dab that another
  run does not (measured: one 4x4 dab, 1 run in 5). So while a test plays, pressed moves are delivered only at drained
  events" / `pressedMovesAreEventOnly = (not atDrainedEvent) and aTestIsPlaying()`.
- **Gate**: screenshot determinism (`83305178`, 2026-08-27). VERIFIED (code, commit); no transcript, and no product-side
  alternative is discussed in the later sessions that read it (I).
- **Why**: the comment states a product nondeterminism (a touch paint stroke lays an extra dab or not, by cycle
  timing) and removes it for tests only. The same comment says "every consumer is idempotent at a standing position",
  which, if true, means the per-cycle re-dispatch buys the product nothing.
- **Right fix**: deliver pressed moves at drained events only, always, and delete the flag — after checking what a
  motionless real press still needs from the per-cycle re-entry (the hold recognizer has its own clock).
  *Measurement:* make it unconditional under a prelude, run the suite on both pointers; then hand-check a still finger
  on a paint surface and on a slider.
- **Blast**: S–M. **Pixels**: none expected (the suite already runs this way).

### S9. A test compares the product's rule with itself
- **Where**: `tests/SystemTest_macroThumbHighlightOnlyUnderAPointer/…_automationCommands.js`: `:20`
  `thumbLook = (t) -> if t._showsPressed() then "pressed" else if t._showsHover() then "highlighted" else "atRest"`;
  `:29` `@assertValuesEqual "the dragged thumb shows its hover highlight exactly when a pointer rests on it", world.hand.mouseOverList.has(thumb), ((thumbLook thumb) is "highlighted")`;
  `:33–35` the "no thumb is highlighted without a pointer on it" sweep; `:62` the same for the indicator's thumb. No
  screenshot.
- **Why**: `SliderButtonWdgt._showsHover` (`Fizzygum/src/basic-widgets/SliderButtonWdgt.coffee:53`) is
  `world.hand.restsOn(@) and not …DraggingSomething()`, and `restsOn` (`ActivePointerWdgt.coffee:1214`) is
  `@pointerCanRest() and @mouseOverList.has aWdgt`. Both sides of the assertion read `mouseOverList`. Before tests
  commit `225987eeb` (mixin removal, 2026-11-12) it read the thumb's STORED state, an independent witness. The loop's
  review said "The check is vacuous" and restored spies in three sibling tests, not in this one (session INFERRED; tree
  VERIFIED). The owner's own rule, from the dup-caret arc: "a check must not ask the product's own rule for its
  expected value".
- **Right fix**: read the PAINTED thumb — a shot, or a pixel probe of its fill on the bright-states fixture
  (`demoMenus.makeSlidersButtonsStatesBright`, which macroSliderButtonStateColors already uses to read a knob's state
  off its pixels) — against the hand's over-list; or retire the three assertions.
- **Blast**: S. **Pixels**: new references if shots are added.

### S10. A reference holds a known defect
- **Where**: `Fizzygum/src/basic-widgets/CaretWdgt.coffee:468`
  `if @parent and @target.isScrollable and !@_amIDirectlyInsideViewport()` (the clamp is skipped for a caret directly
  on a viewport's plane); the references of `macroEditingStringInScrollablePanelCaretAlwaysVisible`; `BACKLOG.md:163`:
  "a caret at the right edge of a padless scrolling viewport … has its last column under the 1 px border;
  `scrollCaretIntoView`'s margin should include the border."
- **Gate**: revisits (the caret was laid out twice in two tests), 2026-10-20. The fix removed the re-visit, and "the
  caret's second column now sits under the panel's border… I recaptured that test alone and filed the border margin"
  (session INFERRED; BACKLOG line and tree VERIFIED; what the reference shows INFERRED).
- **Why**: the gate went quiet and a visible defect went into a reference. The test is named for the caret being
  always visible.
- **Right fix**: `ViewportWdgt.scrollCaretIntoView`'s `marginAroundCaret` (`:1421`) includes the border; recapture that
  test.
- **Blast**: S. **Pixels**: one test, both pointers, both densities.

### S11. A leaf guard where the sweep threw
- **Where**: `Fizzygum/src/demos/BouncerWdgt.coffee:20–23`: "I bounce inside my parent, so without one (a bouncer not
  attached yet, or taken off its holder, stays in the world's stepping set) there is nothing to bounce inside, and my
  step does nothing." / `return unless @parent?` (`:23`).
- **Gate**: menusweep, `STEP_ERROR` from `BouncerWdgt.step` with no parent (2026-11-21): "the world's stepping of
  detached widgets is not changed here" (session INFERRED; tree VERIFIED).
- **Why**: the comment names the cause in its own parenthesis — a detached widget stays in `steppingWdgts` — and guards
  the one class the sweep happened to detach. Filed at `BACKLOG.md:227` ("The world steps every registered stepper,
  attached or not … Reached by the menu sweep (a detached bouncer threw)"). Every other `step` that reads its parent
  has the same hole and no guard.
- **Right fix**: the world steps only attached widgets (or a widget leaves the set when it leaves the tree); then
  delete the guard.
- **Blast**: S–M (the stepping set's membership). **Pixels**: none expected.

### S12. Two rows that throw are allow-listed
- **Where**: `Fizzygum-tests/scripts/menu-click-sweep-headless.js:181–184`:
  `'THREW:deserialiseFromMemoryAndAttachToWorld': 'precondition, not wiring: nothing has been serialised yet, so JSON.parse("") fails. A real user reaches this only after "serialise widget to memory"'`
  and its `…AttachToHand` sibling. Members: `Automator-and-test-harness-src/WidgetTestSupport.coffee:95–101`. Rows:
  `Fizzygum/src/demos/DemoMenus.coffee:706–707`, offered unconditionally.
- **Gate**: menusweep; the entries date from its first commit (`66515925c`, 2026-08-16). VERIFIED.
- **Why**: the reason is not true of the menu: the rows are there before anything is serialised and a click on one
  throws. Dev-menu rows, so the harm is small; it is the one place the `KNOWN` table excuses a real throw.
- **Right fix**: `return world.inform "Nothing has been serialised to memory yet" unless world.lastSerializationString?`
  in both members (or offer the rows only when there is something to load); delete the two entries.
- **Blast**: S. **Pixels**: none.

### S13. The example was changed so the row shows
- **Where**: `tests/SystemTest_macroInspectorOpensAClassInItsClassInspector/…_automationCommands.js:56`
  `onPointerClass = new InspectorWdgt PointerWdgt`, then `:61`
  `@doubleClickAtFractionOf_InputEvents (rowOf onPointerClass, "__super__"), [0.5, 0.5]` and `:68` on the `constructor`
  row — each a press on a row that must happen to be in view.
- **Gate**: `AIM MISSED` on ClippingWdgt's `constructor` row, below the visible list (2026-11-12): "change only the
  example class to PointerWdgt" (session INFERRED; `mixin-removal-loop/LEDGER.md:86` names the miss, VERIFIED).
- **Why**: the test's claim is about the row, not about which class has few enough members for it to show. The next
  member added to `PointerWdgt` or `BoxWdgt` can push the row out again.
- **Right fix**: bring the row into view before the press (the list verb; see S5 for its own repair).
- **Blast**: S. **Pixels**: none (assertion-only steps).

---

## 13. What I could not check, and counts

Scanned (VERIFIED):
- **Tree**: every `*.coffee` under `Fizzygum/src` by grep for the under-test predicates and for comments naming a gate;
  `MacroToolkit.coffee` read in the parts cited; all 454 test directories' metadata and commands files by scripted
  scans (`pointerKinds`, `pressMustLandOn` receivers, every `yield`, duplicate waits, `until`/`while`, `fingerMode`,
  finger reference directories); every script under `Fizzygum-tests/scripts` for allow/skip/retry tables; the harness.
- **Git**: Fizzygum 1025 commits and Fizzygum-tests 643 commits since 2026-07-01 — message greps (recapture, exempt,
  mouse-only, flake, quiet/satisfy/narrow, assertion wording) and `-S`/`-G`/`-L` on the spellings in each section;
  about twenty-five commits read in full.
- **Ledgers**: all fourteen `Fizzygum-tests/.scratch/*/LEDGER.md` (9053 lines) by grep, the hits read in context.
- **Memory**: the index and nine notes.
- **Transcripts**: owner-typed messages of all 32 top-level sessions swept for objection phrases (71 hits, nearly all
  pasted compaction prompts). The rest through four sub-workers, each with about 70–100 tool calls:

| Worker | Files | Reached | Not reached |
|---|---|---|---|
| A | `884ce6f2` (200 MB, 10-15 → 10-23) + 178 subagents | regex passes over all assistant text and owner messages; all 178 subagent FINAL reports regex-scanned; two subagents read in context | the main file was not read sequentially (thinking blocks mostly absent): L1–2800, the W4 icons L40300–45500, W6 and G-A..G-C L50000–60000, the gutter arc L67400–70300 were covered by regex only; 176 subagents beyond their final reports |
| B | `d055260b`, `fa39f982`, `9fdab002`, `e75a5bfe`, `20448fdd`, `d0a2276d`, `1d0246d2` | main files by regex windows; the on-disk arc ledgers of `d055260b` | `d055260b`'s 31 subagents (ledgers and edit scans only) and its SWCanvas-arc portion; `9fdab002`'s 20 subagents (one edit scan); `d0a2276d`, `1d0246d2` skimmed |
| C | `17e8eba8` (317 MB, 11-07 → 11-13) + 121 subagents, `8b8b4cfe` | four ledgers first; main assistant text by regex; all subagent assistant text grepped in aggregate, one read in depth | main-file TOOL RESULTS only scanned for firing tokens; `cleanups-loop/LEDGER.md` grepped, not read end to end |
| D | `5fae7abf`, `fd5c9317`, `c3e1441a`, `3aefc39e`, `f6c026f1`, `f17cfbf3`, `c465c3ed`, `853080ec`, `f4c213ac`, `0f0aec85`, `7c9dad1b`, `0c7bff2d`, `c42374a6` | six ledgers first; the first nine main files by regex windows | the subagents of `0f0aec85`, `7c9dad1b`, `0c7bff2d`, `c42374a6` and those four main files beyond a keyword scan; `853080ec` owner messages only; other subagents regex-scanned |

  Never opened by anyone: `05a325ce`, `1bc99d39`, `2acdc424`, `47698129`, `abb76e2f`, `b6f32cef`, `d5c42ef7`,
  `0e4b5781` (small sessions, 0–5 MB) and this audit's own session.

Not checked, or only in part:
- **I could not run anything**, so every "relies on" count is unknown: how many tests lean on S1's auto-scroll;
  whether macroScrollPolicyNeverFlip passes under a finger; whether the doubled waits hide a painted stale frame;
  whether the `coldGlyphWidgets` carve-out still exempts anything; whether `WorldWdgt.coffee:1969`'s declaration hides a
  flush. Each has its measurement written beside it.
- **July to mid-October 2026 is visible only in git.** Six of the thirteen standing items date from there (S1, S2, S3,
  S4, S7, S8), so their "gate-driven" evidence is a commit message and a code comment, not a session.
- **Recaptures**: about 80 recapture commits since July. I read the messages of the large waves and those naming a
  flake, not each per-image justification. A reference recaptured over a real regression shows only in a diff page
  nobody kept; S10 was found because the session said so.
- **`_fullChanged` widening**, and a `Math.round` at a consumer before 2026-10-10: not swept (closed arcs audited them).
- **Thinking blocks** are empty or absent in most transcripts, so reasoning was read from assistant text and tool
  inputs only: a quiet fix that was never put into words would not have been seen.
