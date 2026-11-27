# BACKLOG.md — every open item, with its owning doc

Index only: each open item is ONE line — what is wrong or what is to do, then its reach or severity (README rule 5; a
line over the recorded length fails `check-doc-narration`, `BACKLOG_ITEM_TOO_LONG`). Its full text is in the plan its
section heading names (a section that names none: `archive/backlog-open-items-detail.md`), in that plan's
`## BACKLOG detail` section, under a heading equal to the item's bold title; a trailing `→` gives the file, or the
quoted heading, only where it differs. A line with no bold title and no `→` is the item's whole text (where it names
a plan section, `§7.1`, `W2`, `P4`, that section holds the rest). **What is filed (owner, 2026-11-11):** a
finding a person reaches through the product (a gesture, or a file a save writes) and would notice, or one that is
medium or worse whatever its reach (a crash or hang, lost work, code run unasked, a gate or rig that can hang or flake
or whose bite is unproven); a low finding nobody reaches gets one "noted, not queued" line in its plan's
`## BACKLOG ledger` instead. **OPEN items only** — an item leaves this file when it closes, and lands in the
`## BACKLOG ledger` section of the plan that closed it (README rule 2). A subsection's owning plan lives in `plans/`
while the arc is active and in `archive/` once it closes; either way the open items it left behind stay here. Closed
items whose arc never had a plan file are collected in `archive/backlog-closed-items-ledger.md`, open ones' detail in
`archive/backlog-open-items-detail.md`. Keep it current per README rules 2 and 5; a `- [x]` line here fails
`check-doc-narration` (`BACKLOG_CLOSED_ITEM`, the gauntlet's `refs` leg).

## Open items by owning arc

### `archive/argument-holes-both-repos-plan.md` — the hole test over both repos: a code parser, the callers test, the button family's head in opts (CLOSED 2026-11-07; Units 0, A–E done, see its ledger)
- [ ] **Nothing keeps the similar-code mirror working** — no build or gate runs `coffee-to-js-mirror.js`, so `find_similar_code.sh` stopped unnoticed from 2026-08-16 to 11-10; holding sources to it costs seconds a build.
- [ ] **A `{ booted: true }` wait that saw the world but not boot's end says "did not start"** — `startedWithin` has one line for every predicate, so a boot stuck after the world stands misreads. → "A booted-true wait that saw the world but not boot's end"
- [ ] **The profiling scripts boot their pages their own way** — `docs/profiling/prof-run.js` and `prof-interactive.js` keep their own world waits and "did not become ready" line, outside the shared boot wait.
- [ ] **A hand-list sanction can cite a script that judges nothing** — `check-hand-lists.js` accepts any run-set script as a guard (a library, a `not-a-gate` script), so a guard may check nothing; by reading, low.
- [ ] **A widget file runs the code it carries at load, with no confirm** — a `{"$src"}` method text runs on a drop or "Open from file…" (the world door asks first); confirm, or hold it to a function literal: a product call.
- [ ] ⛔ **A save refused for a function a run left does not offer its way out** — every later save is refused until the person clears the field; offer a button, drop it and say so, or warn at the run: a UX call.
- [ ] ⛔ **An inspector's "Inherited" filter hides own values under superclass-declared names** — a run's `@step` and own state (`parent`, `bounds`) list only with Inherited on; four options, the owner's design call. → "An object inspector's Inherited filter hides values under superclass names"
- [ ] ⛔ **On a pre-compiled tree, a run's early member replacement reads as its class's source** — reached on `homepage`: the minified image has no function names; options: `keep_fnames`, a boot-side note, or accept. → "A pre-compiled tree's replaced member reads as its class's source"
- [ ] ⛔ **A wrapped member reads as compiled text, which the Smalltalk talk plan says it never does** — U2's MethodTally wrappers show compiled JavaScript; forward the record onto the wrapper or accept it: the owner's call. → "A wrapped member reads as compiled text"
- [ ] **The world's inspector offers to edit its browser listeners** — `world.browserInput`'s listener fields list Remove/Rename/Save; an edit leaves the browser calling the old function and keeps the dissolved world alive.
- [ ] ⛔ **A function held with no kept source shows compiled JavaScript in an editable CoffeeScript pane** — on a widget (a class reads by its name), a Save of the text as shown is refused, CoffeeScript typed over it replacing it; label the pane: a UX call. → "A function with no kept source shows compiled JavaScript"
- [ ] **Three plans teach a stamp without its declaration** — creation-and-templates, dataflow-engine-implementation and affine-transforms omit `@serializationTransients`; a stamp alone makes a page object a copy shares.
- [ ] **A runtime object can be stamped only by one class's private helper** — `FridgeMagnets3DCanvasWdgt._keepTransient` holds its `rebuildDerivedValue` stamp to declarations, nothing else does; proven only by a scratch plant.
- [ ] **The field census is blind to `@[name] =` writes** — `census-widget-conformance.js` facet 1 and the other `@field =` scanners read only a literal `@name`, and their headers state no blind spot; by reading, low.
- [ ] ⛔ **Is an inspector's subject always a page object?** — a Duplicate deep-copies a data subject (an array, a plain object), so the copy inspects a detached clone; a widget subject is shared. The owner's ruling.
- [ ] **A hook override that skips `super` is unguarded** — two toolbars overrode `_reactToBeingCopied` without `super` unnoticed; no gate holds a per-class hook override (`_afterDeserialization`, …) to call the one it shadows.
- [ ] **A paint that throws and bans no one is told again on every frame** — reached by a class edit making `opaqueCoveredRect` or the world's paint throw; the growing error log is re-set each frame, so the page slows.
- [ ] **Nothing standing checks that a glide is seen** — the suite suppresses glides, so `isScrollGliding` answering false passes every gate and the macro pump's glide gate never closes; only a scratch probe covers it.
- [ ] **A `$Canvas`'s size is not bounded by the backend's surface** — on an SWCanvas page a saved canvas over 16384 px (from a native page, or resampled up) throws in its builder after the teardown.
- [ ] **`world.loadGuard.unbuildableClassRefused` cannot tell which rule refused** — its expected cause `'NoSuchClassWdgt'` also appears in a wrong refusal naming that class, so the check passes either way.
- [ ] **A save writes an info-doc flag that is no boolean, which the load refuses** — a console `world.infoDoc_x_created = 1` makes a save the load refuses (the save-writes-what-load-refuses class); by reading, low.
- [ ] **A load whose restore throws keeps the registry of the world it replaced** — a save after the failed load writes records that no longer describe the page's code; by reading, low.
- [ ] **A colour takes any number (NaN, ±Infinity, out of range)** — `rgb(NaN,0,0)` keeps the previous fill on native and paints black on SWCanvas; `300,0,0` keys apart from `255,0,0`; refuse, clamp or leave: a design call. → "A colour takes any number: NaN, ±Infinity, out of range"
- [ ] **Spreadsheet formulas are taught `new Color`, which the class calls factory-only** — `docs/specs/dataflow-engine-spec.md` teaches it, so a formula mints an un-interned colour per recompute; teach `Color.create`, or say why not.
- [ ] ⛔ **A load judges an app key's kind by the page's edited members, then returns them to boot** — a `wellKnownKey` edit passes the up-front check and empties the desktop when `resolveApp` throws; parked for the owner. → "A load judges an app key's kind by the page's edited members"
- [ ] **A kept-source alias loses its identity on a copy and a load** — `B.g = P.f` is compiled afresh on B's copy, so `B'.g` is no longer `P'.f`; whether an alias across widgets should follow its referent is open.
- [ ] **A copy pixel-copies every back buffer it will discard** — `_cloneContentInto` deep-copies each widget's `backBuffer` render cache (`_copyCanvas`), though the copy repaints at its first paint anyway.
- [ ] ⛔ **The Smalltalk talk plan describes a `<name>_source` field** — it says `Class.applyMemberEdit` sets `proto[memberName + "_source"]`; the source is kept with its function (`Widget.keptSourceOf`). The owner's plan.
- [ ] **`fg recapture-inspector` recaptures a churn-set test's behaviour shots blindly** — it acts per test, so a shot proving behaviour is re-recorded with the member list's churn; by reading, low.
- [ ] **A scrolled pane keeps its height when its content shrinks in the same settle** — after a class edit an inspector's pane stayed 9164 px where a second re-lay gives 7420; the scroll range is wrong until then.

### `archive/every-gate-bites-plan.md` — every gate's every rule bites, and the build refuses a gate without a proof (CLOSED 2026-11-07; Units 0, A–F done, see its ledger)
- [ ] **The masks Unit 0 found that are heuristic by design** — `check-raw-pointer-reads` ends a handler at a column-0 line and excuses a line naming `screenPointToMyPlane`; `vm-truth-gate.js` skips its heap floor below 20 samples.

### `archive/tests-repo-readers-plan.md` — one definition of a method reference, read from code (CLOSED 2026-11-06; Units 0, A, B, C, E done, see its ledger)
- [ ] **`census-property-placement`'s exclusion 1 counts every WORD inside any string** (3429) as a possible by-name access, where only a whole-name string can reach a member; an advisory census.

### `archive/hand-kept-lists-plan.md` — hand-kept lists: derive them, or make them fail when stale (2026-11-05; CLOSED 2026-11-06, all four tiers landed)
- [ ] **Tier 4's residue** — the four LiveCodeLang vocabulary lists are the hand-list gate's whole Fizzygum baseline (4); once the LiveCodeLang plan's R1 preprocessor gate guards them, sanction them and drop it to 0. → "Tier 4's residue (plan §6 ledger):"

### `archive/world-inventory-instruments-plan.md` — the object-lifetime program, stated in that plan's §0 (Arcs A, B and C CLOSED 2026-08-20/21)
- [ ] ⛔ **OWNER DECISION: a failed async door tells the user NOTHING** — on a transient failure of a part the build ships (a bad `file://` read), a click silently does nothing; whether a door should `inform` is a product call. → "OWNER DECISION: a failed async door tells the user nothing"
- [ ] StorageSorter-roots unification (plan D2's stated non-goal): examine folding `StorageSorter._runClassifier`'s own root/marking enumeration onto `WorldWdgt.graphLivenessRoots()`, in a dedicated pass. → "StorageSorter-roots unification (plan D2's stated non-goal)"

### `archive/shared-base-layer-part-plan.md`
CLOSED 2026-08-02, executed in full (residue in `architecture/build-and-packaging.md` §2/§5); open: the two classes it could not move. → "The backlog's note on this plan"
- [ ] **The last two stay in core: `CanvasWdgt` + `PatchNodeWdgt` (4.3 KB)** — a decision, not a gap: the eager `patch-programming-experimental` part extends `PatchNodeWdgt`. Do not re-attempt for the bytes. → "CanvasWdgt and PatchNodeWdgt stay in core: a decision, not a gap"

### `archive/stroke-flip-and-fracplane-coverage-plan.md`
CLOSED 2026-08-12 — executed in full the day it was authored; residue in `architecture/appearance-paint-convention.md` (stroke + overlay bullets) and the archive stamp. P1–P3 and the thin-stroke finding are in that plan's § "BACKLOG ledger". What remains open is one of the pre-existing defects the arc FOUND:
- [ ] ⛔ **A hand-carried window's pixels are not refreshed when a pending glyph atlas arrives mid-drag** — user-visible (drag a window before fonts settle), invisible to the screenshot gate; owner-gated; a test-side wait landed. → "A hand-carried window is not refreshed when a glyph atlas arrives mid-drag"

### `archive/widget-practices-convergence-plan.md` — ✅ **CLOSED 2026-08-17 (W0–W10), two residuals below**
Acted on the 2026-08-14 widget-practices survey to reach `architecture/widget-authoring-guidelines.md`; per-phase log in the plan's "As landed" blocks. → "The backlog's note on this plan"
- [ ] ⛔ **RESIDUAL W6b — idempotence guards on the B/C/D pin setters** (owner-gated, D3) — independent of P2; it would suppress an equal write's setter side effects (repaint, onward fire): its own commit and evidence. → "RESIDUAL W6b (owner-gated, D3) — idempotence guards on the B/C/D pin setters."
- [ ] ⛔ **RESIDUAL W7 other half — `representativeIcon`** (owner-gated, D4) — all but thirteen classes answer the base `WidgetIconWdgt`; an icon cannot be derived, so hand-write one only for what the desktop can reference. → "RESIDUAL W7 other half (owner-gated, D4) — `representativeIcon`."

### `archive/menu-action-wiring-plan.md` — CLOSED, residual included; SIX live bugs fixed
Both halves gated: `check-menu-actions.js` on the build, `fg menusweep` in gauntlet wave A; the sweep's stated limits are in the plan. → "The backlog's note on this plan"
- [ ] Expand the menu-click sweep's root list only when a bug is found in a class that has none: generic instantiation of ~270 widget classes is fragile, and the reported unbuilt-root count shows the gap. → "Expand the menu sweep's root list only when a bug needs it"

### `archive/frames-input-touch-program.md` — the frames·input·touch PROGRAM (CLOSED 2026-08-27; all five plans executed and archived)
One chrome container (`FrameWdgt`) with a runtime `lifetime` state and manifestations derived from lifetime × parentage; Pointer Events; the single-geometry visual wave; the command-panel/`User` model; the gesture grammar + finger harness (the `finger` gauntlet leg, wave D). The living truth is in the architecture corpus (`input-and-gestures.md`, `viewports-and-planes.md`, `widget-authoring-guidelines.md`, the macros CLAUDE docs, the tests-repo reference grammar); rulings and the drained tail ledger are in the archived program doc. Residue rows, each with its origin:
- [ ] **icons on ordinary menus** (world menu, context menus) — owner taste, not built; `CommandSpec.icon` already exists, so a consumer costs one call site. Land only when a consumer asks.
- [ ] **remainder-menu alternative projections** — a grid pop or a label-only pop of the chevron's overflow menu, available by derivation on the same `CommandSpec` rows; land when a consumer asks.
- [ ] **T4 — multi-pointer** — pinch derived from two `pointerId`s, retiring the Safari `gesturestart`/`gesturechange` no-op listeners (ruling I1).
- [ ] **T5 — desktop-edge docking** — the world's edges as dock slots, a taskbar strip; needs a dock loop in the world's arrange, a fill gesture and a precedence against its `StretchLayoutSpec`s, all unruled.
- [ ] ⛔ **T18 — halo crowding at touch scale** — at `handleSize 44` the five corner handles overlap on widgets below ~92 px; fewer handles, edge zones or a halo mode is decided with the owner-pending G2 halo feel-check.
- [ ] **multi-user input attribution** — strokes carry `pointerId` and `world.users` exists; a User-per-pointer mapping is designed when a second input device exists.
- [ ] **finger scrolling for the spreadsheet** — the sheet takes no drag-scroll (wheel/scrollbar only), so its three wheel tests are mouse-only on the finger axis; a finger-scrollable sheet is a product feature.

### `archive/editing-residue-plan.md` — the editing residue (✅ CLOSED 2026-11-19: U1–U12 landed, see its ledger; the items below were filed on the way)
- [ ] **On a PC, Ctrl+Alt on a key with no AltGr character can type that key's own character** — AltGr is told from a chord by the key's code, which names a US-layout place, so a punctuation key, or any key on another layout, types where Windows types nothing (F6 review; plan §U3) — reachable, low.
- [ ] **A copy or a save made mid-edit keeps the text's selection** — the marks are the text's fields; only the original's clear as the edit ends, so the copy, or the loaded file, shows a selected run with no caret (measured: `Fizzygum-tests/.scratch/dup-caret/probe-v1-text-state-travels.js`) — reachable (dev menu), low.
- [ ] **A driven or computing controller wired to a new target delivers nothing on connect** — the connect's offer is a non-forced mark, so the equal-value cutoff drops it, against spec §8 ("stale+forced"); `ControllerWdgt.coffee:53` reasons from the wrong pair of values (H5c review B1) — reachable, low.
- [ ] **A tilted page taken out of its rotation island stays its window's page** — its own "Attach" or destroy tells only the island (`PanelWdgt._reactToChildRemoved`), so the container keeps the departed page and an empty island (read; dev menu: rotate the page, then its "Attach"; H3d review A1) — reachable, low.
- [ ] **A pinned layout submenu keeps the rows it was built with** — the current alignment (or cross alignment) is left out, nothing ticked, so after a press, here or in its copy, a pinned "Layout in stack"/"Layout in row" menu offers that choice, not the old one (§10; H4b review) — reachable, low.
- [ ] **A duplicated pinned layout prompt writes a clone of the spec** — the size and elasticity prompts (`VerticalStackLayoutSpec`, `DivisionStackLayoutSpec`) still target the spec itself, so a Duplicate of a pinned prompt edits a clone and nothing moves (H4b review A2) — reachable (dev menu), low.
- [ ] **A pinned pop-up dragged back out of the bin does not rejoin `world.openPopUps`** — so a font tool whose pinned Fonts menu was closed to the bin and dragged back opens a SECOND Fonts menu (its lookup derives the open menu from that set); only a pop-up's lifetime write adds to it (H4a review A1) — reachable, low.
- [ ] **A floating toolbar's strip, at the width it is born at, offers close only** — born 46 wide, its collapse and edit toggle drop out of the graded roster; a born-size question no grip floor answers (untitled strips are not floored, plan §1; R4 §E9 Q1; owner postponed 2026-11-19) — reachable, low.
- [ ] **After Disconnect, a pinned wire menu's rows stay, unticked, and do nothing** — they could grey, enabled while the controller still holds the wire they name (`isWiredToActionOf`; the enablement door would need `readerArguments` too; R2 §Q5, §U11 "Landed"; grey or not: postponed 2026-11-19) — reachable, low.

### `archive/toolbar-arc-residue-plan.md` — the toolbar arc's residue (✅ CLOSED 2026-11-18: U1–U7 landed, see its ledger; living truth `architecture/toolbars.md`; the items below were filed on the way)
- [ ] **A widget's base context menu still acts on view-mode content** — "Pick up" on a widget in a cell of a view-mode sheet empties the cell, "Color…" restyles past the tools' refusal (U5 review) — reachable, low; awaits the owner's ruling row by row (some rows stay active in view mode, some not).

### `plans/affine-transforms-plan.md`
Phase 4, residuals, claimsSpace, §7.7 and §7.8 landed; REMAINING = big §7.1-7.4 items, design-first, owner-gated. → "The backlog's note on this plan"
- [ ] §7.1: transform policy engine (banked, not built)
- [ ] §7.2: leaf self-warp (non-island rotation)
- [ ] §7.3: quad-aware damage + occlusion behind transformed widgets
- [ ] §7.4: density folding (owner-downgraded priority)

### `plans/dataflow-engine-implementation-plan.md`
Phases 0-8 plus F1/F2/F4/F5/F6 all LANDED; remaining = F3 (the 'operate' cell submenu); the deferred `firesPerEvent` delivery lane is owned by `plans/wire-vocabulary-extensions-plan.md` W1.
- [ ] F3: the 'operate' cell submenu (a row built with `opensSubmenu: true`, never a typed arrow) — value-class method introspection into a formula

### `plans/wire-vocabulary-extensions-plan.md`
AUTHORED 2026-07-24, NOT STARTED, owner-gated; land the reserved wire semantics (per-event delivery, cold edges, buffer payloads) + record the deadline law. Demand side: `architecture/app-fit-criteria.md` facet 9.
- [ ] W1: `firesPerEvent` per-event mini-pass DELIVERY — flag/menu/edge records landed, delivery still pools; resolve D1–D5 (scoping, settle, pool hygiene, re-entrancy, determinism); acceptance = CounterPatchNodeWdgt + t1–t3 → "W1: firesPerEvent per-event mini-pass delivery"
- [ ] W2: cold edges (spec §8, attribute carried, zero readers) + cold-then-hot structured-event idiom; riders: Diffing `setInput2` bug, written-never-read `setInput*IsConnected` flags, plain/`Hot` setter-pair rationalization
- [ ] W3: buffer payloads as current values — immutable `BufferValue` handle (identity/generation equality), `bufferSetters()` fourth table; spikes S1 (serializer has NO typed-array arm today) + S2 (DeepCopy policy)
- [ ] W4: the deadline law — signal-rate stays below the floor; lands into spec/architecture as residue when W1–W3 land

### `archive/connector-ubiquity-and-reflection-plan.md` — ✅ CLOSED 2026-08-18 (P1–P9, P10(c)+(d))
Landed "a controller is a view of the value it controls"; open: five follow-ons wanting their own decision or arc, two re-homed/refused. → "The backlog's note on this plan"
- [ ] ⛔ **THE SHADOW PASS HAS THREE COVERAGE STRATEGIES AND THEY DISAGREE** — recursive re-paint stacks overlapping children: a visible doubly-dark band under every menu and prompt; unify on the silhouette, own arc, mass recapture.
- [ ] ⛔ **Menu LENGTH is now a pure UX question, and worth its own arc** — widget context menus run 19–42 rows (`TextWdgt` 40); grouping related rows behind submenus would shorten every menu; a taste question. → "Menu LENGTH is now a pure UX question, and worth its own arc."
- [ ] **A2 residue — `SliderWdgt.value` still cannot declare `announces`** — the FOLLOWER arc's job, three parts together: an equal-value cutoff, a second reflector, and refusing a tracking cycle where it would be created. → "A2 residue — SliderWdgt.value cannot declare announces"
- [ ] `FanoutWdgt` is now a visual affordance over a capability every citizen has, rather than the only way to fan out (P4). Nothing forces a rewrite and it lives in a part production does not ship — do it when something needs it.
- [ ] ⛔ **The absorb-query CUT WIRE is a CLASS, not an instance** — a scroll panel's plain `PanelWdgt` contents do not forward the absorb query: one cycle of stale scroll thumb; a design choice, deliberately not fixed. → "The absorb-query cut wire is a class, not an instance"
- [ ] ⛔ P10(a) RECORDED REFUSAL: `ButtonWdgt.trigger` is not routed through the dataflow drain (pools destroy click counts; commands aren't pins); revisit only after W1 lands, opt-in per button. → "P10(a) recorded refusal: ButtonWdgt.trigger stays off the drain"

### `plans/livecodelang-cleanup-and-extensions-plan.md`
AUTHORED 2026-07-07, NOT STARTED; owner-initiated execution only.
- [ ] T1 R1-R4: headless preprocessor test gate + corpus fixes — not started
- [ ] T2 R5-R10: correctness fixes: escaping, boundary guards, magnet geometry, tan collision
- [ ] T3: dead weight & duplication removal, corpus must stay 300/0 — not started
- [ ] T4: preprocessor structural refactor, behavior-preserving — not started
- [ ] T5: language/runtime extensions, owner picks which — not started

### `archive/redesign/redesign-plan.md` — the visual redesign (COMPLETE 2026-10-22; its open follow-ups stay here)
One design system (a `Theme` token layer, seam rules, drawn chrome icons, size-aware icons) reaching the draft (`archive/redesign/`, beside the plan) surface by surface, with the suite made aim-by-meaning first. The look as built is `architecture/visual-design-system.md`; the owner decisions are in the plan's §0.5. The items below are the arc's open follow-ups; "the plan" in them is the archived plan.
- [ ] T follow-up — a hidden or collapsed title piece keeps a STALE box (a pinned menu's hidden `label` at (0,0), a collapsed title's old centre); harmless to the product; should a not-shown piece answer geometry? → "T follow-up — a hidden or collapsed title piece keeps a STALE box"
- [ ] ⛔ W3 follow-up — the owner-review points W3 left open: an own property dimmed like an inherited one, the code pane's line pitch, toggle looks (the chip's closed with the chip), the prompt buttons' placement, and more (the plan's §4 W3). → "W3 follow-up — the owner-review points W3 left open"
- [ ] ⛔ W2 follow-up — the owner-review points W2 left open: the fat scroll indicator's look, tooltip placement over its menu, the 20 px tick column, narrow pinned menus hiding their title (the plan's §4 W2). → "W2 follow-up — the owner-review points W2 left open"
- [ ] ⛔ W1 follow-up — the owner-review points W1 left open: collapsed-strip corners, a window's bottom-corner crescent, card corners, the grip's square and drag lag, the "grip" name clash (the plan's §4 W1). → "W1 follow-up — the owner-review points W1 left open"
- [ ] G-E follow-up — menu, list and member rows copy their look at construction (~16 own fields), so a saved or duplicated row keeps the look of the day it was built; a read at paint is pixel-neutral (rewires 167 shots). → "G-E follow-up — a ROW's look is chosen once and copied at construction"
- [ ] G-E follow-up — the demo pointer ("Make pointer") keeps its own chrome: a 160-grey box and a white label outside the palette, its close glyph low-contrast on that grey; give it the plate look or a role. → "G-E follow-up — the demo pointer keeps its own chrome"
- [ ] G-D follow-up — `macroHierarchyMenuHoverHighlightsExactSubtree` replays under a finger with no wash pixel: declare it mouse-only, drop its finger refs; decide what `macroTargetingHighlightsCandidateWidget`'s finger run asserts. → "G-D follow-up — two hover-wash tests replay under a finger"
- [ ] G-C follow-up — UNEXPLAINED: the `menusweep` gauntlet leg hung silently in parallel wave A twice (300 s alarm, no output), passing its serial retry; its stderr stamps name the root at the next sighting. → "G-C follow-up — UNEXPLAINED: the menusweep leg hung silently in wave A"
- [ ] R0 follow-up — `recapture.js --auto` re-verifies every parallel failure single-process before capturing: about 45–55 min of a 2 h mass recapture; a parallel re-verify (or none) would save most of it. → "R0 follow-up — a MASS recapture is dominated by its discovery pass"
- [ ] F follow-up — the font sets lack ¹ ² “ ” ‘ ― (Arial's ° comes from the symbols atlas, a little wide) and `StringWdgt.toString`'s "↵" boxes in dev displays; adding to the font set regenerates every atlas. → "F follow-up — the S2 symbols W6 left"
- [ ] W5 follow-up — a document paragraph being DRAGGED is plain in the hand (square, flush, re-wrapped at full width) and takes its item shape again where it lands; needs the hand to know where the drag came from. → "W5 follow-up — a document paragraph being DRAGGED is plain in the hand"
- [ ] W5 follow-up — a document drop cannot append after an item whose middle lies below the visible page without scrolling while dragging (seven tests re-aimed); an edge auto-scroll while carrying would close it. → "W5 follow-up — a document drop cannot append below the visible page"
- [ ] W5 follow-up — with the caret 1 px after its slot and 2 px wide (owner decision), a click on it before a glyph under 5 px wide (`t`, `i`, `l`) picks the next slot; at a tight label's end it paints outside the box. → "W5 follow-up — a click on the caret before a narrow glyph"
- [ ] W5 follow-up — `Theme.titleBarTextHeight` could go: its two readers answer only before the title piece exists; removing it needs a class-side "line pitch of a role" query `StringWdgt.linePitch` would share. → "W5 follow-up — Theme.titleBarTextHeight could go"
- [ ] W5 follow-ups (W5e) — a copied or loaded toolbar keeps its items' saved pointer state; a view/edit switch (`_engageDocksNoSettle`) does not tell a docked band's corner chain (no observed case). → "W5 follow-ups (W5e) — a copied or loaded toolbar keeps pointer state"
- [ ] W6 follow-up — a text that sizes its box to its contents measures its stored `@text`, not `transformTextOneToOne @text`, so a display case or a password would size wrongly; no title uses that mode today. → "W6 follow-up — a self-sizing text measures its stored text"
- [ ] W6 follow-up (BitmapText) — 124 shipped dpr-2 bold/italic font atlases at 73–84.5 px carry a one-row image under two-row data, so glyphs past the wrap draw blank; a font-set regeneration (R4) rewrites them. → "W6 follow-up (BitmapText) — dpr-2 bold/italic atlases draw blank"
- [ ] ⛔ W6 follow-up (owner review points) — uneven 11 px menu-header capitals at dpr 1, "Empty window" below the title crop grade, small symbols-atlas glyphs, a rotated widget named after its content, lowercase fixture labels. → "W6 follow-up (owner review points)"
- [ ] W6 follow-up — wording leftovers: a pinned menu's or prompt's quoted `colloquialName` lands in a saved file's name ('"Desktop" window.fzw.json'); the dev menu spells "Serialise" beside "Deserialize…". → "W6 follow-up — wording leftovers"
- [ ] W6 follow-up (design note) — a menu row opening a confirmation would need both the submenu chevron and "…", which the two rules forbid together; no row does today; decide before one is added. → "W6 follow-up (design note) — a menu row that opens a confirmation"
- [ ] F follow-up — S3 ladder anomalies for the icon work: Bin draws lopsided ridges at even S 18–32 (its drop rule measures the two ridges by opposite edges); GenericPanel and Typewriter degenerate at 14. → "F follow-up — S3 ladder anomalies for W4's icon work"
- [ ] G-A follow-up — the C-F converter's demo icon (`CFDegreesConverterIconAppearance`) lost its grey F degree sign: the size-aware base has no secondary-ink helper; add a role helper if a second ink is wanted. → "G-A follow-up — the C-F converter's DEMO variant paints its parent"
- [ ] G-A follow-up — a Fizzytiles magnet's label is a `StringWdgt` that keeps its own font and ink, so a magnet loaded from a snapshot keeps the label look it was saved with (the magnet's box and border are read at paint).
- [ ] ⛔ G-B follow-up (owner G2, still open) — on a widget smaller than ~92 px on a side the halo's five 44 px plates overlap (the corner plate on top); accepted at G-B, decided with the halo feel-check.

### `archive/window-page-gutter-plan.md` — one gutter around a window's page, its bands and its selection ring (✅ CLOSED 2026-10-23: Fizzygum 6e4946cd, Fizzygum-tests cc9aa0e1e, pushed)
A window's PAGE keeps one 8 px gutter on every side and between it and its bands; PANES stay flush; a document's inset yields to the gutter; a page's selection ring lies in the gutter, painted by the window; gutter and letterbox-margin drops go to the page; a Stretchable page in a gutter is a four-edged sheet; a document's caret scroll margin is its own. Rule: `architecture/visual-design-system.md` §4.10.
- [ ] Observation — a world snapshot restores bounds as saved and re-lays nothing, so a window saved under another theme keeps its old geometry until re-laid (a Docs Maker saved at gutter 0 loads flush). → "Observation — a world snapshot restores bounds and re-lays nothing"
- [ ] Naming follow-up — `_insetEdgeRects`, `_targetReachedThroughAGutter`, `_moveGutterDropInsideTarget` and `releasedInAGutter` cover more than their names say; `_clampedPositionWithin`'s comment says `aWdgt` for a `Rectangle`. → "Naming follow-up — gutter names narrower than what they do"

### `archive/spreadsheet-ux-plan.md` — the spreadsheet as a page, with a formula bar, zoom, its own toolbar and the Sheets Maker (✅ COMPLETE 2026-11-04)
Owner rulings R1–R13 (the plan's §1); what the arc left out on purpose:
- [ ] Per-row heights: text bigger than its row is clipped (rows are one height). Plan §1 "Not in this arc".
- [ ] A view (non-edit) mode for the spreadsheet: every other Maker has the edit/view toggle. Plan §1.
- [ ] Ranges: a multi-cell selection (the style subject would hand over a range's style), SUM over a range. Plan §1.
- [ ] Insert / delete a row or column (every formula's references rewritten), and fill down. Plan §1.
- [ ] Pinch-to-zoom as a world-wide gesture any zoomable widget answers (the sheet's zoom is a menu today). Plan §1.
- [ ] ⛔ Observation — a number wider than its column shows ellipsised ("12345…"), so a reader can take the shown digits for the value; `###` or scientific notation: the owner's call. → "Observation — a number wider than its column shows ellipsised"

### `archive/collapsed-bar-grip.md` — a collapsed window keeps its grip, and its bar can have a width of its own (✅ COMPLETE 2026-11-01)
- [ ] Observation — a band collapsed in its dock and then lifted out gains its edit toggle while still collapsed, so its bar shows no grip at any width; harmless: expanding it puts everything right. → "Observation — a collapsed band lifted out of its dock gains a toggle"

### `archive/window-grip-strip.md` — every window's grip in a strip of its own (✅ COMPLETE 2026-10-31; what it dissolved is in that record)
- [ ] ⛔ Owner's call, stands at "one rule": a floating toolbar is a window, so it wears the strip (103 → 145 px tall); a stripless one needs back the retired keep-clear code and a second grip look. → "Owner's call — a floating toolbar wears the window strip"
- [ ] Observation — a panel holding a window, added by code to a view-mode window's content, leaves the inner window's grip showing until the outer changes mode; no gesture reaches this (view mode refuses drops). → "Observation — a window added by code into a view-mode window"
- [ ] Observation — the Examples folder's "New York City" slide in EDIT mode: the map window's viewport is 42 px shorter, so the nested "NYC: traffic" plot is mostly cut off. It opens in view mode, which is unaffected.

### `plans/occlusion-culling-plan.md`
P0-P3 (Avenue A) LANDED 2026-07-09; P4/P5/P5b/P5c OWNER-GATED, not started.
- [ ] P4: Avenue B maintained covered-rect list, replacing per-rect traversal — not started
- [ ] P5: descend to nested opaque panels/window bodies — optional, not started
- [ ] P5b: hand-carried drag coverer (hand paints last, uncounted today) — not started
- [ ] P5c: fringe decomposition of the dragged window's own rects — not started

### `plans/pixel-icons-plan.md`
AUTHORED 2026-07-18, NOT STARTED; replace ~79 vector `*IconAppearance` files with ASCII index-mask pixel icons (16/32/48 all supported, per-icon subset by usage cohort, coverage-rule variant selection; maps/gradients/logo-with-text stay vector); ⛔ two owner gates (P0 aesthetic, P4 mass recapture).
- [ ] ⛔ §5 pre-step: the owner re-judges the convert list against the crispness-audit tiers — per icon keep-vector / pixel-grid / size-aware redraw (9 icons landed size-aware by 2026-07-22). → "§5 pre-step: owner re-judges the convert list"
- [ ] P0: spike (`PixelIconAppearance` + hand-converted Heart) + native≡SWCanvas byte-identity evidence + ⛔ owner aesthetic sign-off
- [ ] P1: rasterizer/parser hardening (variants, crop, literal palette entries)
- [ ] P2: sentinel-supersample authoring tool + all-icon draft contact sheet
- [ ] P3: mass conversion of ~79 appearance files (markers byte-verbatim; Wdgt files untouched)
- [ ] P4: red-set enumeration → diffpage → ⛔ owner recapture approval → serial mass recapture → gauntlet
- [ ] P5: WRITE `architecture/pixel-icons.md` (it does not exist yet — this step is what creates it), measurements, archive+close
- [ ] P6 (banked): dot-mode at large scale; in-system pixel editor; dead vector-helper prune (⚠ FanoutPin uses `_paintRoundedSquareBadge`)

### `plans/runtime-performance-optimization-plan.md`
H1/Arc2-4/W1-W2/A/C1/O1/O2/O4a landed; O4 attribution + correction DONE 2026-07-24; NEXT = O3
- [ ] ⛔ §5B O3: per-widget/descend occlusion (plan P4/P5) — large, owner-gated
- [ ] §5B O4b: SWCanvas glyph-run batching — ⚠ DE-URGENTED by the O4a correction (steady-state glyph stream ≈ just the desktop logo); do not build on the pre-correction numbers. O4a's as-landed entry is in this plan's § "BACKLOG ledger"
- [ ] §8/top banner: S2 Tier 2, S6b, F1 (precompiled test-harness boot) still unlanded
- [ ] §5 F3: dirty-rect DOM present — deprioritized, not landed

### `archive/scroll-indicators-plan.md` — one placement rule for a scroll indicator, the document's margin, and the spreadsheet's own (CLOSED 2026-11-21; U1–U6 and U1b, U2b, U4b–U4e done, see its ledger)
- [ ] A finger's scroll that starts on ANOTHER text of a document being edited ends the edit: the press is read as acting elsewhere (`stopEditingIfWidgetDoesntNeedCaretOrActionIsElsewhere`) before the drag turns into a scroll (probed). Reachable, low. Detail: the plan's §U3.
- [ ] A payload released over a scrolled viewport's FAT bar (a carry with no button held: the "Pick up" row, then a click) lands in the plane displaced by the scroll offset: `ViewportWdgt.add` forwards it unmapped. Seen through U2's plant 4 (236 px off). Reachable, low. Detail: the plan's §U2.
- [ ] An inert child (a highlight, a drag outline) added inside a tracking island re-lays every tracking ancestor (`Widget._invalidateLayout` does not ask `isLayoutInert`): idempotent, one per hover over an island target. Reachable, low. Detail: the plan's §U4b.
- [ ] A throw that escapes the dataflow drain (a pin setter that throws while a wire delivers) escapes `WorldWdgt.doOneCycle`, which catches nothing there, and stops the world's cycle loop: the page freezes. Seen through a U5 plant. Read; reachable only through a defective setter. Medium-low. Detail: the plan's §U5.
- [ ] A tracking slider's own drag is dropped against a stale record after "Follows it too" off then on: the engine's sink cutoff (`DataflowEngine._readValueChanged`) compares against a value the promotion never re-recorded. Read; reachable by gestures. Medium-low. Detail: the plan's §U5.
- [ ] After a mouse drag a slider's thumb rests where the pointer left it, not on its value's stop, while the pointer stays in the band (a sheet's column thumb up to ~10 px off at the default size): every slider re-seats its thumb only at its next arrange. Low. Detail: the plan's §U6.
- [ ] A part picked out of a figure whose tilts cancel (a widget tilted −θ inside a panel tilted +θ) leaves an empty orphan island alive: the extraction builds an identity island the dissolve skips while it has no parent. Read; reachable by hand. Low. Detail: the plan's §U4c.
- [ ] A tilted window content's own halo resize handles half-work (it floats free in its island, so it shows them; its window dictates its size): a corner drag (+40,+30) kept the width and lost the height (measured). An upright content offers none. Reachable, low. Detail: the plan's §U4d.
- [ ] `FrameWdgt._clipThroughForChild` rebuilds the box a window gives its content on every call (~8 `_barSpec()` builds, 2 climbs), on every content paint and clip-cache miss under a window, every frame of a drag; nothing holds that box. Unmeasured. Low. Detail: the plan's §U4d.
- [ ] A squeezed function or bar plot lays its x-axis 13 px below its own box, so a window that crops its content to its body cuts the axis away (seen in the "Plots and maps" dashboard's small plot windows). Reachable, low. Detail: the plan's §U4d.
- [ ] A stretch panel squeezes a child window below its own chrome (a 3D plot window 79 px tall against 89 px of strips and border), so the window has no body and shows no content. Reachable, low. Detail: the plan's §U4d.
- [ ] A tilted nested window is not height-stretchable by its outer window's grip where an upright one is: `FrameWdgt.contentsRecursivelyCanSetHeightFreely` recurses through `isFrame?`, which the island does not answer. Reachable, low. Detail: the plan's §U4b.
- [ ] A tilted window content that leaves its island (its own "Attach", a destroy, a shortcut's bring-up) leaves its window an empty island: only the island is told. The page's case is filed under the editing residue. Read. Reachable, low.

### `plans/single-file-save-plan.md`
AUTHORED 2026-07-10, design LOCKED by owner, no code written yet; next = Phase 0 spikes S1/S2
- [ ] §5 Phase 0: S1 FizzyPaint round-trip spike + S2 hand-built prototype — not yet run
- [ ] §7: banked v1-excluded items: precompiled file, SWCanvas strip, baked edits, dirty guard

### `archive/onion-widget-composition-plan.md` — "The Frame model" — ✅ FLAGSHIP ARC COMPLETE 2026-07-20 (A·C·B·D·E); follow-ons below
Naked `Simple*` capability → framed `*Wdgt` citizen (`FrameWdgt`, was `WindowWdgt`) → App=launcher. Intrinsic-framing principle LOCKED (D1–D9). Correctness-first — no churn deferrals. Every landed phase (§5 P0, A, B, C and its two dock tails, D-1/D-2/D-3, E, E1's refusal, E3, plus the build-tooling and census riders) is in that plan's § "BACKLOG ledger".
- [ ] §5.B follow-ons: `DeckWdgt` = D2 reserved name, no substrate yet → "§5.B follow-ons: DeckWdgt reserved name"
- [ ] §5.D follow-ons: a load-image-FILE flow into `ImageWdgt` (its bitmap loader went with the video player; such a flow builds its loader where it needs one) → "§5.D follow-ons: a load-image-FILE flow into ImageWdgt"

### `plans/creation-and-templates-plan.md`
AUTHORED 2026-07-18, design-stage/exploratory, owner-gated; create = duplicate-a-template (Factory) | run-an-assembler (ScriptRunner); App = a Factory over an empty framed `*Wdgt` in edit mode. Supersedes the reference plan's launcher/Factory.
- [ ] §4.1: name `FactoryWdgt`/`ScriptRunnerWdgt` (use `isTemplate` + the `Duplicator`)
- [ ] §4.2: redefine "App" as a Factory over an empty framed `*Wdgt` in edit mode
- [ ] §4.3: fold the creator zoo (CreatorButton/WidgetFactory/MenusHelper "new X") onto the two primitives — second wave
- [ ] §4.4: (bank) templates as first-class editable objects

### `archive/toolbar-band-depth-plan.md` — a toolbar band as deep as a strip (✅ CLOSED 2026-11-23: Phases 1–6 landed, see its ledger; living truth `architecture/toolbars.md` and `architecture/visual-design-system.md`, "The tool cell")
A toolbar band is 46 px deep, a strip's thickness (one row of 44 px cells and two lines), and a tool's picture stands in a 32 px mark box inside its cell; the items below were left open.
- [ ] **The toolbars' picture faces scale a fixed drawing** — the creator, paint and Template faces are rough at the 32 px mark box on the software backend; redraw them size-aware, one at a time (owner-deferred 2026-11-23) — every Maker's toolbar, low.

### `archive/toolbar-template-one-size-plan.md` — one way out of a tool cell, at one size (✅ CLOSED 2026-11-23: Phases 0–6 landed, see its ledger; living truth `architecture/toolbars.md` §1, §6, §8)
A click on a toolbar Template's cell and a drag out of it give one copy, at the size the tool came into the cell at (its class's `toolExtent`, the owner's Candidate B); the item below was left open.
- [ ] **A sample's map pin is smaller than one taken from a toolbar** — the Sample Dashboard's five pins and the Sample Slide's one are built at the 50 × 40 birth box (picture 28 × 40), a toolbar's pin comes out 35 × 50 — reachable, low.

### `archive/several-bands-per-side-plan.md` — a side holds a list of bands, view mode hides only the tool bands, a toolbar docks at the depth it floats at (✅ CLOSED 2026-11-24: U1–U4 and U1b landed, see its ledger; living truth `architecture/toolbars.md`, `architecture/layout.md`, `architecture/visual-design-system.md`)
- [ ] **A docked document has no pencil** — it keeps the mode it docked with, so one docked in view mode refuses typing while its host edits; lift it out, flip it, dock it back — reachable, low.
- [ ] **The paint revamp's toolbar pieces** — a holder's tray (tool, ink, paper, size), a Maker declaring several bands, flyout cells: designed, each to land with its first consumer.
- [ ] **Attach onto an occupied window orphans its content** — the Attach chooser offers a window that holds a content; attaching makes the new widget its content and leaves the old one off the tree, silently; onto a band it also leaves the band's record and thickness wrong — reachable in dev mode, medium.
- [ ] **A toolbar window put into another window shows a clipped strip** — a free toolbar window whose strip runs down its side, first placed with its height given, keeps its payload's construction height (a 44 strip in a 118 room; a fresh one 50×40 with both scroll indicators) — reachable, low.
- [ ] **A Maker docked in a viewing window keeps its own toolbar showing** — its page refuses typing (the host's view mode reaches it), while its own text bar stays engaged and its bar's Dock and Float rows still act — reachable, low-medium; an owner question.
- [ ] **An enlarged toolbar window docks as deep as its shorter side** — a person who makes a toolbar window 600 × 600 and docks it gets a band about ten cells deep, wider than a Docs Maker's body; R7 records the depth it stands at with no bound — reachable, medium; an owner question.

### `plans/inspector-overhaul-plan.md`
AUTHORED 2026-11-24, spiked the same day; the inspector-overhaul loop landed U1 and U1b on 2026-11-24 and U2, U3, U4 and U5 on 2026-11-25; U3b, the finger icon, closed unrun on 2026-11-25 (the owner's dotted split button has no glyph to put a finger beside); and the owner's three follow-ups of 2026-11-25 landed after the loop (a value shown as code, a door that opens the inspector on a member, the split's one flat piece: the plan's §6, "Follow-ups"). Every unit is closed; the plan stays in `plans/` until the owner closes the arc. One inspector tool: a row of inspectors, each showing one view of its subject (its members, its children, a class's instances or subclasses, or one member's editor), on the division stack. Supersedes the Smalltalk talk plan's U3 (an explorer beside the inspector). Its §0.4 holds the owner's rulings and the open decisions, each with a default.
- [ ] **"Pick up" of a cell of a plain holder's division stack leaves the other cells where they stood** — `Widget._beforeBeingGrabbed` marks no holder, though `ActivePointerWdgt.grab`'s comment says so; the owner's C1: its own piece of work right after this loop — reachable (the cell's menu), medium-low.
- [ ] **A long list takes seconds to paint** — a press on `Widget.prototype`'s Instances (1000 rows) costs long tasks of about 7 s and 2 s, a 1000-row member list re-filtered 4.4 s; a lower cut, or rows built as they scroll in — reachable, medium.
- [ ] **A widget whose constructor throws stays registered in its classes' `instances`** — alive and held by nothing (29 classes build in their constructors); reached since U2 through a member whose value throws as it is shown; one rule of the base would answer it — reachable, medium-low.
- [ ] **A division row whose cells all desire 0 width divides by zero** — `StackLayoutEngine.arrange` (`desC / totDesired`), and a row whose least widths sum to 0, laid out at width 0, does too (`availMain / minMain`): NaN geometry if reached; no person's way to either found — a core engine.
- [ ] **The run-sequence self-test reads its stuck-page case as NOT RUN under load** — its case "the page stopping answering as the sequence starts" waits a time, not the state it plants, so the `selftests` leg fails in wave and passes on its serial retry — low, but a leg that flakes.
- [ ] **"Edit layout" slots stay on an inspector row after a choice** — each choice leaves behind the adders that flanked a destroyed inspector, the set wider by their width; the fix belongs to the "Edit layout" mechanism (owner, A1) — reachable in dev mode, low.
- [ ] **A window does not honour its content's least size** — made smaller than it (by its grip, or a document's column cap), an inspector browser shrinks every cell below its least, buttons narrower than their labels; left so by the owner's ruling (A3), a feature for every window — reachable.
- [ ] **A member editor has no visible "open the value" control** — a member's value opens only by a double-click on its row (the owner's ruling A4); a control in the editor's header is an idea.
- [ ] **An object list's row does not highlight the widget it names** — a hover highlight of the widget a Children or Instances row names, an idea (U4's preparation).
- [ ] **A holder keeps no place for its slack taker** — a header whose title a person picks out stretches its controls, and a member list whose list is picked out stretches its bands: the rule `InspectorWdgt.viewsPlace` answers for a view, one level down — reachable in dev mode.
- [ ] ⛔ The Smalltalk talk plan's U3 (an explorer beside the inspector) is superseded by this plan's row of inspectors, and the talk plan does not say so: both plans claim the explorer — the owner's plan, the owner's edit.
- [ ] §11: a touch-sized way to move every division stack's split (the halo's layout adjusters, "Edit layout"), not only an inspector row's — a general stack has no header band to stand a grip in, so the shape is still to design — reachable by finger.
- [ ] §11: one footer-band mechanism — `FooterBandLayout` (the `CodeAreaWdgt` family, the member editor among it, and `BinWdgt`) beside `BandWdgt`: both on `BandWdgt`, `FooterBandLayout` deleted.
- [ ] **An inspector attached into a row is not reconciled at once** — attached (its developer menu's "Attach"), it waits for the row's next choice or for something to leave the row, and one attached free-floating counts as a cell — reachable in dev mode, low.
- [ ] **A view attached back onto its inspector shares the height with its place** — a view a person took out and attached back stands beside the place kept for it (`InspectorWdgt.viewsPlace`) — reachable in dev mode, low.
- [ ] **A browser whose only inspector was picked up stays a blank window titled "Inspector"** — "Pick up" of the one inspector leaves its window holding an empty set, an empty trail and an empty body — reachable in dev mode, low.
- [ ] **A split button in a header band a person rotates maps its pointer in another plane** — found by reading in U2's review — reachable in dev mode, low.
- [ ] **A double-click in a list standing in no row cannot complete** — a member list a person picked out opens its first click's choice in a window of its own (`InspectorBrowserWdgt.showChoice`), the family of the owner's A4 — reachable in dev mode, low.
- [ ] **Unsaved typing that a re-filter takes away cannot be undone** — a filter toggle removes the editor, so the member chosen again opens a fresh editor with a fresh undo history (ruled in U2's preparation, stated in no doc) — reachable, low.
- [ ] **A split button dropped on the desktop takes no drag** — picked out of its header and dropped there, only its developer menu removes it — reachable in dev mode, low.
- [ ] **The scroll thumb of a 1000-row list is a dot about 3 px long** — a viewport's thumb has no least length (`Widget.prototype`'s Instances) — reachable, low.
- [ ] **`CommandPanelWdgt.rowLabelsNaming` can number a row onto another widget's own name** — "Rectangle 2" twice when a third widget is so named, in every hierarchy menu, chooser and Children list; each row still opens its own object — reachable, low.
- [ ] **The refusal bubble's "new member" draws its space about 2 px wide** — the bubble a name the subject already answers gets from Add…, Duplicate… or Rename… — reachable, low.
- [ ] **An inspector keeps naming a part a person destroyed** — `chooser` and `viewToggles`, as `header` and `classButton` do, after the developer menu's "Destroy" on a toggle, so a world snapshot walks into the destroyed part — reachable in dev mode, low.
- [ ] **A pinned "Add…" prompt outlives its member list** — once a view switch or a choice on its left destroys the list, its OK adds the member and builds a list into the destroyed view — reachable, low.
- [ ] **The "Edit layout" spacer and adder keep an outlined look beside the flat split** — `LayoutSpacerWdgt` and `LayoutElementAdderOrDropletWdgt` keep a bordered plate (`LayoutChromeAppearance`) beside the flat grey divider and tab: two looks of layout chrome; the owner's call — reachable in dev mode, low.
- [ ] ⛔ **The churn-set derivation ends INVALID on a no-picture test that fails its plant by design** — `macroEditMarkAndMenuRowOpenTheSameMember` holds a tool's list to its own members, and the plant declares a member on every class; the tool has no outcome for it (the owner's rule) — a tool that cannot complete.
- [ ] **An inspector saved open on a paint tool restores a detached copy of it** — the copy's Save writes its whole member record over the person's, so an edit made since through the palette's edit mark is lost — reachable, low; by reading, not pressed.

### `plans/inspector-browser-plan.md`
AUTHORED 2026-11-26 after five prototype rounds on the real build and four spikes; IN PROGRESS (U1–U4 and U3.2 landed; the matcher (L19) next, then U5). The inspector as a browser: a set of columns that scrolls, the body below the lists, packages, method categories and comments. It overturns five statements of `plans/inspector-overhaul-plan.md`, each marked there.
- [ ] Filed by U3.2 (Review A A5): a Children list's verb re-reads the list, which labels each child through its `colloquialName`; a person's injected one that throws leaves the view with no list after the verb ran — low, reachable by injected code (§6 U3.2).
- [ ] Filed by U3.2 (Review A A6): a band of verbs picked out of its list (dev mode, Pick up) outlives the view it targets; its press acts on a live child and re-reads into a destroyed view — low, reachable (§6 U3.2; the member list's band has the same shape).
- [ ] Filed by U3.2 (Review A A7): a widget file saved in developer mode and opened in user mode keeps a Children list's band until the view is toggled (its presses do nothing) — low, reachable (§6 U3.2).
- [ ] The build's shared method-header matcher misses 7 real methods (fizzytiles: `name:(…) ->` with no space; a header continued by a backslash): the ten gates grouping code into methods never read those bodies — RULED 2026-11-27 (L19): fixed in its own change, before U5 (plan §6 U5).
- [ ] Filed by the inspector browser's U4: raising a window puts it over a tooltip that is showing (`Widget._bandAboveMe` counts pop-ups and ephemeral overlays above a window, not tooltips) — low, reachable (§5.8, As built in U4).
- [ ] U5: the meta-object keeps a class's comments and its methods' categories, edits and snapshots keep them, and a build gate holds the `#:` marker (§5.9, §5.10).
- [ ] U6: the 64 classes a person opens first get their categories, as marker comments only (decision D1).
- [ ] U7: the code browser: packages, classes, method categories, a class's comment, a member's comment above its code, and its door in the Dev tools menu (§5.11, §5.12).
- [ ] U8: the verbs of categories (add, rename, remove an empty one) and a method moved to another category (§5.14).
- [ ] U9: the verbs of classes: add, and remove of a class made at run time, with the snapshot record that carries such a class (§5.14, decision D2).
- [ ] U10: finding a class or a member by name: two candidates on a review page for the owner to choose between (decision D7); the build follows the choice.
- [ ] U11: close: the docs, the churn set, this file, the review page.
- [ ] §11: writing an edit back to a `.coffee` file; duplicate and rename of a class; a class's statics as a second face of its column; the rest of the tree's categories (the gate's budget, falling); the final icons of the four verbs.
- [ ] **The set can rest off a column edge after its edges move** — a window narrowed while the set stands at an end no column edge marks, a divider's drag, or a view picked out of a column left of the view leaves it starting mid-column until the next notch or stroke — reachable, low.
- [ ] **A class reached by a widget's `constructor` row is named "Function"** — the inspector's header, its class button and the trail's level read the function's generic name, never the class's own (`Utils.colloquialNameOf`) — reachable, low.
- [ ] **A list keeps an interposed pane whose stated reason is gone** — the list's pane was kept because its rows were moved past the hug on growth (`ListWdgt._applyExtent`, deleted); the pop-up's direct-contents shape may now fit it (`docs/architecture/viewports-and-planes.md`) — unreached, low.
- [ ] **A text line too wide for a back buffer stops painting** — an unwrapped line past the 16384-px surface limit at the page's pixel ratio (about 1200 code characters at dpr 2) throws in its paint and is banned (`SimpleTextWdgt`) — reachable, low.
- [ ] **A trail longer than its browser squeezes its buttons** ("Rect…" on a phone). RULED 2026-11-27 (L17): show its last levels, the earlier ones folded behind a leading "…" button that opens them as a menu (`docs/plans/inspector-browser-plan.md` §5.5) — reachable, low, a later pass.
- [ ] **A double-click on a member in the set's rightmost column can miss when the body stands beside** — the editor a first click adds can make the set scroll to show it, so the second click meets what slid under the pointer; the body below, the default, has no such reveal — reachable through `bodyPlace: "beside"`, low.
- [ ] **A trackpad's sideways swipe moves the set a column per wheel event** — a swipe is many small wheel events and a notch moves one rest point whatever its size, as a sheet's does, so a gentle swipe races across the columns — reachable on a trackpad, low.
- [ ] **Under a finger a tooltip comes up after a tap** — a tap whose press opens nothing (a list's Remove, a disabled verb) leaves the tip's countdown running, so the tip shows ~500 ms later with no finger there and stays until the next press; every tooltipped control (the verbs' words are tooltips only) — reachable, low.
- [ ] **A member list keeps a band a dev-mode Destroy destroyed** — `verbsBand` still names it, as `cutNoticeBand` names its own, so a live list retains a destroyed widget and every later choice asks it to reflect its verbs (it holds no buttons) — reachable in developer mode, low.

### `plans/reference-widgets-plan.md` — RE-SCOPED (UI + lifecycle areas only)
AUTHORED+RE-SCOPED 2026-07-18; link/GC → graph-edges plan, launcher/Factory → creation plan. Residual = the visible reference UI + desktop lifecycle areas, built on those two arcs.
- [ ] §4.2: minimise-to-a-bar, distinct from collapse-in-place (second wave)
- [ ] ⛔ §4.4 follow-up: what does save-to-file mean for an ARROW'D shortcut (today: friendly error — no cross-file identity for a dangling-`.lnk` restore; needs its own decision)

### `archive/top-10-cleanups-plan.md`
AUTHORED 2026-11-11, a SURVEY of ten candidate cleanup arcs, ordered by effort (smallest first; the plan's table also gives each item's payoff rank). Each item carries its evidence, its effort estimate, its re-measure command and its first step. Since 2026-11-12 an owner-launched `/loop` executes the items that need no owner decision (the plan's STATUS says which): a landed item's line moves to the plan's `## BACKLOG ledger`, a part-landed one is rewritten to what is left. ⛔ owner decision first on §9.
- [ ] §5's second candidate (unexamined): `FrameWdgt`'s docking family (`dockSideAt` to `floatOutOfDock`) as a seam of its own — assess before assuming it
- [ ] §9 (4 to 5 days): icon shells — one `IconWdgt` plus a derived icon catalog (⛔ owner: is per-icon class identity wanted; kept open by the owner 2026-11-13, the plan's §9 has the recommendation on record — collapse)

### `archive/top-10-cleanups-round-2-plan.md`
AUTHORED 2026-11-13, the second SURVEY of ten candidate cleanup arcs, ordered by effort (smallest first; the plan's table also gives each item's payoff rank). Where the first survey took the framework and the build, this one takes the test harness, the reference set and the verification tooling. Each item carries its evidence, its effort estimate, its re-measure command and its first step. The owner agreed with §1 to §9 on 2026-11-13 (§4 ruled: delete; §9 on its stated criterion) and left §10 out for now; an owner-launched `/loop` executes §1 to §9 one unit at a time (the plan's STATUS). ⛔ owner decision still open before the second step of §6.
- [ ] ⛔ §6 step 2 (1 to 2 days; the owner decides): instruments sharing one suite pass — only `revisits` reads the same in a shared pass; the saving is load, not wall time; recommendation: keep four passes → "§6 step 2: instruments that share a suite pass"
- [ ] ⛔ §8 follow-up (owner ruling): `_automationCommands.js` holds only macro sources, so its name misleads — rename it (e.g. `_macro.js`) or fold it into the metadata file; touches every runner and 389 directories → "§8 follow-up: rename or fold _automationCommands.js"
- [ ] ⛔ §10 (1 to 2 days, then 3; left out for now by the owner): the reference set — a path of the live axes, then one file per reference (the 45.8 MB `.js` copies and the loader go; needs §4 decided) → "§10: the reference set as a path of the live axes"

### `archive/top-10-cleanups-round-3-plan.md`
AUTHORED 2026-11-15, the third SURVEY of ten candidate cleanup arcs, ordered by effort (smallest first; the plan's table also gives each item's payoff rank). Where the first two took the structure, the build, the harness and the verification tooling, this one takes what the ratchets do not measure: zeros nothing holds, the shape the removed recorder left behind, and tools only a person starts. Each item carries its evidence, its effort estimate, its re-measure command and its first step. OWNER 2026-11-15: §1, §2, §3, §5, §6, §8 and §10 approved, for an unattended loop (the plan's STATUS has the rulings); §4, §7 and §9 left for a later day.
- [ ] ⛔ §4 (½ to 1 day; owner, a later day): the `patch-programming-experimental` part — six classes no test builds and no production user reaches; finish the diff and regex nodes, or delete all six → "§4: the patch-programming-experimental part"
- [ ] §7 (1 to 2 days; left for a later day by the owner 2026-11-15; ⛔ owner on which tools go): on-demand tools — one roster, each proven to start by the `selftests` leg
- [ ] The visualisation page generator runs only when asked (`fg visualise`, a capture): no build or leg loads it, so a break shows only on use and a capture only warns — medium; the §7 roster would prove it starts. → "The visualisation page generator runs only when asked"
- [ ] §9 (2 to 3 days; left for a later day by the owner 2026-11-15; ⛔ owner: rename or fold): a test is one file — takes up the round-2 §8 follow-up above; selection facts move to the generated manifest

### `archive/top-10-cleanups-round-4-plan.md`
AUTHORED 2026-11-15, the fourth SURVEY of ten candidate cleanup arcs, ordered by effort (smallest first; the plan's table also gives each item's payoff rank). The source reads clean on every instrument, so seven of the ten are in the tooling and the harness: what the `fg` port's equality rule froze, work that is done twice, and build profiles nothing builds. Each item carries its evidence, its effort estimate, its re-measure command and its first step. OWNER 2026-11-15: §9 left for a later day; the other nine approved along the survey's recommendations, for an unattended loop (the plan's STATUS has the rulings).
- [ ] ⛔ §9 (1 to 1½ days; left for a later day by the owner 2026-11-15; owner: which profiles are products): no verb, leg or gate builds `lean`, `dev-notests` or `dev-precompiled`

## Residual / parked items (owning doc archived)

### View-mode and dock conformance 2026-11-23 — residue (no plan doc; the arc ran investigation → execution)
The Sheets Maker gained the edit toggle, a viewing window stopped offering its dock slots, and a dock's outline became the band it makes; seen on the way: → "View-mode and dock conformance 2026-11-23 — the backlog's note"
- [ ] **The view-only badge reads "view-o…"** — a declining drop target's lock badge is cropped, and a window dragged over a view-mode window's edge now shows it too — reachable, low.
- [ ] **A band whose payload keeps its own height stands short in a side column** — a text window docked left or right leaves its column empty below it; whether a band always spans its slot awaits the owner — reachable, low.

### Pointer hit-test rework 2026-08-21 — residue (no plan doc; the arc ran assessment → execution)
`isTransparentAt` + `noticesTransparentClick` retired for three single-meaning members (`widget-authoring-guidelines.md` §5); what it did not take on: → "Pointer hit-test rework 2026-08-21 — the backlog's note"
- [ ] **`BubblyAppearance.shapeContainsPoint` OVER-CLAIMS its tail strip** — a click beside the spike stops on the bubble; harmless today; a fix needs an analytic body+spike test (a behaviour change with hover churn).

### Residue arc 2026-10-16 — follow-ups (no plan doc; closed items in `archive/backlog-closed-items-ledger.md`)
Six of its follow-ups are CLOSED: `archive/backlog-closed-items-ledger.md` § "Residue arc 2026-10-16 — its six follow-ups". → "Residue arc 2026-10-16 — the backlog's note"
- [ ] **The corner-occupancy protocol does not see the temporary resize/move halo** — a bar runs under the halo's bottom-right handle; and `_setLayoutSpec` updates the visibility of only its first handle child.

### Residue-2 arc 2026-10-25 — residue (no plan doc; closed items in `archive/backlog-closed-items-ledger.md`)
The arc that closed the residue arc's five items (the image widget's back-buffer memo and the back-buffer-memos gate, a saved raster's pixel ratio, SWCanvas's deflate encoder, the finger wheel's held swipes and a scroll stroke ending at its release, the shared method grouping's class-side keys) measured these on the way and left them open:
- [ ] **The sw3d work is not vendored** — SWCanvas branch `sw3d-game` forked before the pinned commit and its `dist/sw3d.min.js` was never rebuilt; bring it in as its own pin bump with a whole-suite check.
- [ ] `census-widget-conformance.js` facet 1 (`declarationsOf`): its `(?!\(|->|=>)` lookahead is defeated by backtracking, so every class-level key counts as a declaration — load-bearing: a naive fix flags function-valued fields. → "census-widget-conformance.js facet 1: lookahead defeated"

### Save/restore-fidelity arc 2026-10-25 — residue (no plan doc; closed items in `archive/backlog-closed-items-ledger.md`)
The arc that closed five save/restore and scroll items (a frame's placeholder exists only while shown; an element the page loads is derived from its holder's path, gate #30; a menu re-takes its width at a lifetime change; a viewport's frame covers its own box) measured these on the way and left them open:
- [ ] **A demo `PointerWdgt` holds its `target` only through a field** — the inventory reads the target as ESCAPED, a single-widget save of a pointer is refused (`→ .target`), and a world snapshot captures it off-tree.
- [ ] **The overflow (») menu's miniature of a text tool races the glyph atlas on SWCanvas pages** — a plain text widget pictured cold keeps placeholder boxes for good (no shipped toolbar reaches it now). → "The overflow menu's miniature of a text tool races the glyph atlas"
- [ ] **On `index-sw.html` outside the harness, SWCanvas's `drawImage` of a `file://` image throws `SecurityError`** — an image widget cannot paint there; nothing shipped draws an `HTMLImageElement` today. → "SWCanvas drawImage of a file:// image throws SecurityError"

### SWCanvas correctness arc 2026-10-27 — residue (no plan doc; closed items in `archive/backlog-closed-items-ledger.md`)
The arc that fixed SWCanvas's queued defects and the egregious ones it found (owner triage rule: fix what reaches Fizzygum's tests or usage, or is egregious — a missing shape or row, a hole, paint in the wrong place, a throw or a hang; the minors stay here) measured these and left them open. Each is SWCanvas-repo work, then a re-vendor, and none reaches Fizzygum's current tests unless it says so. Evidence is under `Fizzygum-tests/.scratch/arc-sw/` (research notes `R-A3/NOTES.md`, `R-B2/NOTES.md`, `R-C2/NOTES.md`).
- [ ] **Ellipses are flattened by their MINOR radius** (SWCanvas) — chords miss the major-axis ends by up to 0.52 px against a 0.25 px tolerance; fix prototyped in `R-B2/v-chords`. Fizzygum draws no ellipse.
- [ ] **Path2D curves are flattened with a USER-space tolerance** (SWCanvas) — the device error grows with the scale (an arc misses by 0.92 px at scale 4; Béziers too). Fizzygum uses no Path2D.
- [ ] **Arc segment counts read the CTM's largest COLUMN length, not its largest singular value** (SWCanvas) — under scale-then-rotate they under-count: 2 SWCanvas PNGs move (51 px); no assertion sees it (worst 0.125 px). → "Arc segment counts read the CTM's largest column length"
- [ ] **Two `arcTo` flatteners disagree** (SWCanvas: a device-space and a user-space count) — `fillStadium` differs from the path `roundRect` in 84 of 5376 cases; fix: one sampler and one count.
- [ ] **Open thick strokes end square to the last CHORD, not to the curve** (SWCanvas `_generateCaps`) — off by 0.76 / 1.51 / 2.31 px at lw 20 / 40 / 60 on r 60 open arcs; closed rings are fine.
- [ ] **`fillArc` / `outerStrokeArc` / `fillStrokeOuter` drop sub-0.5 px segments near the apex** (SWCanvas `ArcOps`) — 23–24 pixel centres missed (worst 0.39 px). Fizzygum calls none of them. → "fillArc and friends drop sub-0.5 px segments near the apex"
- [ ] **Path curves are inscribed chords** (SWCanvas) — a filled curve misses pixel centres up to 0.25 px inside the true curve; exact crossings are prototyped and want the curve-tag layer of the stroke-flattening item.
- [ ] **Stroke flattening ignores the line width, and a curve's vertices are stroked as user joins** (SWCanvas) — 54 arc cases miss 5169–9544 px; design in `R-A2/NOTES.md`: one curve-tag layer and a sweep join. → "Stroke flattening ignores the line width"
- [ ] **A FILL's pixel at an exact tie can depend on where the fill is drawn** (SWCanvas) — 10 of 836 renders differ by 1 px between positions; a device frame was refused; it wants a translation-free stored path first.
- [ ] **A semi-transparent rotated `strokeRect` blends some pixels twice** (SWCanvas `RectOpsRot`) — 48 of 648 cases, every one a rect with min(w, h) < lineWidth; the axis-aligned one does the same on tiny rects.
- [ ] **`Color` stores premultiplied 8-bit components** (SWCanvas) — a translucent colour's straight components drift (up to 127 levels at alpha 1–15); fix prototyped; in Fizzygum ±1 level, INFERRED ~30–40 tests a density to recapture.
- [ ] **`putImageData` of (255,0,0,0) keeps its RGB** (SWCanvas), where Chrome reads back 0,0,0,0. Invisible (alpha 0).
- [ ] **`xor` is binary on partial alpha** (SWCanvas), and `lighter` and the blend modes fall back to source-over (off by up to 220). Fizzygum uses only source-over, source-in and destination-out.
- [ ] **`PaletteAppearance`'s rings sit at a radius ± 0.5 about a pixel centre** (Fizzygum) — both ring edges fall on pixel centres, so the 3.5 ring is asymmetric at dpr 1; radius 3 is symmetric; cosmetic, a recapture.

### `archive/gate-contortions-undo-plan.md` — the gates say what a finding means, and the shapes bent round them are undone (CLOSED 2026-11-23; U1–U19 and U16b, U18b, U18c done, see its ledger; the items below were filed on the way)
- [ ] Filed by U2: `check-part-edges` does not read `world.parts.ensureLoaded("p").then ->` as a guard, so a correct await of a lazy part fails as `UNGUARDED_CLASS_REF` — whether its scanner should read it is a rule change for the owner (plan §U2) — small.
- [ ] Filed by U2: `dead-method-allowlist.txt`'s group "Kept as intentional API … currently unused" gives reasons that name no reach this scan cannot see — re-judge each entry: delete the member, or name its reach (plan §U2) — small.
- [ ] Filed by U2: the paint audit, tier-naming, capstone, storage, vmtruth, graph, parts, apps, serialization and boot-smoke legs print no advice row — where a finding of one has a quiet fix (a baseline or allowlist entry, a declaration), its row names it (plan §U2) — small.
- [ ] Filed by U3: about 21 `_settleLayoutsAfter` thunks fit none of the three sanctioned settle-thunk shapes (other-object receivers, empty or invalidate-only thunks, the layout-spec `@element._settleLayoutsAfter` setters) — each is a smell or a fourth shape (plan §U3) — small.
- [ ] Filed by U3: three `layout-apply-sanctioned` markers sit in `_`-tier methods rule [F] does not judge (`FrameWdgt._reactToChildCollapsed`, `_reactToChildUnCollapsed`, `StretchablePanelWdgt._reLayout`); a stale-marker rule for [F], as thin-wraps has, is a rule change for the owner (plan §U3) — small.
- [ ] Filed by U3: `Fizzygum-tests/CLAUDE.md`'s cross-engine bullet says `AutomatorLoader.loadImagesOfTest` matches references by `/SWCanvas/`; it matches by name, pixel ratio, pointer kind and OS — the instruction file states a false fact (plan §U3) — small.
- [ ] Filed by U4: `DemoMenus.createFridgeMagnets` builds through `world.parts.launch("FridgeMagnetsWdgt")`, a class the code knows named by a string; under `whenAllLoaded ["fizzytiles"]` it would run inline where `launch` defers — the owner's call (plan §U4) — small.
- [ ] Filed by U4: `Fizzygum/CLAUDE.md` says the dependency finder regex-scans for `new X`; it reads `new X` only in a class-body field initialiser, never in a method body — an instruction file states a wider claim than the code (plan §U4) — small.
- [ ] Filed by U7: `close()` on the bin's own window does nothing and says nothing (it would file the window into the bin inside it; only the close button's path puts the bin away); `SystemTest_macroFoldersAndTheBinStayInEditMode` ends with that call under a comment saying it puts the bin away (plan §U7) — small.
- [ ] Filed by U8: `SystemTest_macroScrollPanelCaretBroughtIntoViewWhenMoved`'s finger leg never brings the caret back — its finger image_4 equals image_3, with no caret, against its claim; measure why (the swipe ending the edit?) before choosing a finger drive or a declaration (plan §U8) — small.
- [ ] Filed by U17: `SystemTest_macroStringWdgtAndTextWdgtResizingInLayout` calls `togglefittingSpecWhenBoundsTooSmall()` directly, on a stated reason (a 440 px world, menus that cannot scroll) no longer true — `bringMenuRowIntoView_InputEvents_Macro` now reaches the row the user's way (plan §U17) — small.
- [ ] **While a test plays, a drag-scroll release does not glide** — `ViewportWdgt` sets `glideSuppressed = aTestIsPlaying()`, as the glide runs on frame cadence, so no test drives it; make it event-time, then recapture every shot after a release (R7) — untested product path, medium (plan §BACKLOG detail).
- [ ] **While a test plays, pressed moves are delivered only at drained events** — `ActivePointerWdgt`'s `pressedMovesAreEventOnly`: off the harness a touch paint stroke can lay an extra dab by cycle timing (1 run in 5); deliver at drained events always (R7) — an untested product path, medium (plan §BACKLOG detail).
- [ ] **The edge auto-scroll runs on the wall clock, and its test polls up to 20 s** — `ViewportWdgt._startAutoScrolling` waits 500 ms by `Date.now()` and steps per frame; `SystemTest_macroListWdgtAutoScrollsNearDraggedEdge` loops till the clamp, four times; drive it on event time (R7) — medium (plan §BACKLOG detail).
- [ ] **Type-named predicates with many callers stand for type tests** — `isFrame` (16 lines; "Polymorphic replacement for `instanceof FrameWdgt`"), `isLayoutAdderOrDroplet`, five layout-spec ones: each a moved behaviour, a capability or an honest `instanceof` (§14) — small each, `isFrame` large (plan §BACKLOG detail).
- [ ] **A leg that fails in-wave and passes alone reads OK** — `fg gauntlet`'s serial retry turns any in-wave failure, a test's pixels or assertion included, into `OK(warn)`, and `lib/shards.js` retries its probe on any throw; four failures it absorbed were real bugs (R7) — medium (plan §BACKLOG detail).
- [ ] **`recapture.js`'s completeness gate waves a failing verify through** — a parallel failure that passes one single-process re-run is "infra flake, ignored", and a test recaptured in that very run that then mismatches is listed as NEEDS RECAPTURE, not UNSTABLE (U18) — medium (plan §BACKLOG detail).
- [ ] **The editing station ends an edit inside a settle declaration** — `WorldWdgt._keepEditingOnScreenNoSettle` destroys the caret (`_stopEditingNoSettle`) inside `_deferredSettleDeclare`, unseen by the capstone, where a removal its holder answers belongs in a settle — measure, then rule — small (plan §BACKLOG detail).
- [ ] **Ten doubled `waitNoInputsOngoing` waits in four tests** — the one with a reason records a product lag (a resized sheet's bars and a slider wired to it show the old scale for one painted frame); nine say nothing — accept the lag in `layout.md`, each wait its reason, or fix it — small (plan §BACKLOG detail).
- [ ] **`NON_INTEGER_GEOMETRY` cannot see a clipping widget's move** — `ClippingWdgt._applyMoveBy` rewrites its own and each child's bounds without `_assertBoundsWellFormed`, so a fractional move of any clipping class (every window) passes, though the integer-pixel doc says every leaf checks — medium (plan §BACKLOG detail).
- [ ] **Four soaked sends have no implementor** — `radioButtonWasSwitched?`, `drawAdditionalPartsOnBaseShape?`, `processKeyUp?`, `dataflowApply?`: dead calls a deletion left, invisible to `check-unresolved-sends` (it reads `name(`); `ToggleButtonWdgt` tests two fields nothing sets — small (plan §BACKLOG detail).
- [ ] **A menu row's parts each ask its disabled state** — `InertIconHolderWdgt` and `MenuRowIndicatorWdgt` read `@parent?.isDisabled?()` for their ink; the row's `disabledInkForMyParts` was dropped only for the [U] query count, though `isDisabled` is macro-read API — re-judge on the merits — small (plan §BACKLOG detail).
- [ ] **Four shapes the static audit could not judge** — `FooterBandLayout._arrange` (its sibling's `arrange` is public, marked), the content-property tools' verb dispatched by string, the delete chords that select then delete, `NativeValueKinds.rebuildsItself` with no widget exclusion — small each (plan §BACKLOG detail).

### Tooling arc 2026-10-29 — residue (no plan doc; closed items in `archive/backlog-closed-items-ledger.md`)
- [ ] **A screenshot whose reference never LOADED reports as a pixel mismatch** — an empty candidate set says "no screenshots like this one" (seen in a loaded `settle` leg); give it its own line, then find why one goes missing. → "A screenshot whose reference never LOADED reports as a pixel mismatch."

### One line each — every item names the archived plan and section that owns its detail
- [ ] `docs/tooling/visual-review-sample.txt` names `SystemTest_macroEditModeTogglePencilEyeGlyph`, which has no test directory, so `fg diffpage` refuses the sample; drop it, or name the test covering the glyph now. → "visual-review-sample.txt names a test that no longer exists"
- [ ] Classes are still evaluated in sloppy mode (an indirect `eval.call window`); with `Mixin`'s `arguments.callee` rewrite deleted nothing needs it — whether to compile classes in strict mode is open. → `archive/mixin-removal-plan.md`, "Classes are still evaluated in sloppy mode"
- [ ] A Drawings Maker keeps a stale `@contents` after "Pick up", "Delete" or "Attach" on its canvas: no fresh canvas and glass is built (a slide's, dashboard's, patch board's or panel's page is: `StretchableWidgetContainerWdgt._reactToChildRemoved`) — medium. → "A StretchableWidgetContainerWdgt keeps a stale @contents"
- [ ] `SystemTest_macroInternalVsExternalWindowDrop`'s unarmed drop is DETERMINISM.md §3k's class: under load its hold crosses `dwellToArmMs` and the window nests (seen twice); schedule the release in event time. → `archive/drag-embed-implementation-plan.md`, "InternalVsExternalWindowDrop's unarmed drop can arm under load"
- [ ] `fg fuzz` has NO working regression fixture: reverting flake A's `waitForScreenshotReady` passes 13/13 under injection; a fixture needs many atlas loads and a pixel read near one. → `archive/atlas-delay-fuzz-tool-plan.md`, "fg fuzz has NO working regression fixture"
- [ ] Dynamic parts §5.4 phase 3 (DECLINED by the owner 2026-07-30; optional, not an unfinished retirement): flip further parts to `"eager": false` — `dev-icons` and `patch-programming-experimental` ready. → `archive/build-arc-4-dynamic-parts-plan.md`, "§5.4 phase 3: flip further parts to lazy"
- [ ] `archive/basement-dormant-layout-flag-plan.md` §5: design + implement the cached _inBasement flag
- [ ] `archive/basement-dormant-layout-flag-plan.md` §7: step-by-step build of the flag — not started
- [ ] `archive/basement-dormant-layout-flag-plan.md` §8: mandatory gauntlet + dpr2 torture verification — never run
- [ ] Bin auto-empty (basement-to-bin §6): empty the bin automatically at snapshot/quit — deferred, not rejected; revisit after living with the Bin (its doGC precondition is gone since the bin/shelf split) → `archive/basement-to-bin-plan.md`, "§6 auto-empty: empty the bin at snapshot/quit"
- [ ] `archive/basement-to-bin-plan.md` §4 Phase 3c: bin presentation — swap the pseudo-random scatter for a representativeIcon grid — cosmetic follow-up, owner kept scatter for the semantics arc
- [ ] `archive/caret-follow-in-place-settle-plan.md` §5: decisive first step: trace where typing's caret drains today
- [ ] `archive/caret-follow-in-place-settle-plan.md` §6: implement the fix shape once §5's trace is known
- [ ] `archive/caret-follow-in-place-settle-plan.md` §7: mandatory byte-exact verification protocol — not run
- [ ] ⛔ `archive/claimsspace-footprint-default-and-scroll-reachability-plan.md` §5 S3 / G2: owner halo feel-check (desktop/document/scroll-panel), post-push → `archive/claimsspace-footprint-default-and-scroll-reachability-plan.md`
- [ ] `archive/layout-regressions-2026-07-icons-plots-editghosts-plan.md` §8-C follow-up 4a: FizzyPaint canvas-resize ghost — fix identified, couldn't reproduce to verify
- [ ] `archive/layout-regressions-2026-07-icons-plots-editghosts-plan.md` §8-C follow-up 4b: broader ScrollPanel resize-preservation — implemented, verified no-op, reverted
- [ ] `archive/swcanvas-invisible-pixel-hash-nondeterminism-plan.md` §5: whether PNG export flattens over opaque background — uninspected
- [ ] `archive/swcanvas-invisible-pixel-hash-nondeterminism-plan.md` §5: backfill blast radius (SWCanvas ref count, scriptability) — uncounted
- [ ] `archive/swcanvas-invisible-pixel-hash-nondeterminism-plan.md` §5: cross-engine (V8 vs JSC) invisible-pixel residue identity — unverified
- [ ] `archive/god-class-decomposition-plan.md` Tier 3 / C21: context-menu construction relocation to menusHelper — deferred, screenshot label-strip risk
- [ ] The capstone gate's paint-time half (the paint-read-only audit, which rides the capstone pass) shares the careless-push-count-only weakness of the hover-resync plan's CAPSTONE GATE WEAKNESS note — open. → `archive/hover-resync-after-flush-plan.md`, "The capstone gate's paint-time half has the push-count-only weakness"
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.2 A3: must-call-super table-driven rule — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.4 A6: dead-class detector (ReClassNotReferencedRule) — not built
- [ ] `archive/lint-generic-rules-carryover-plan.md` §8.9: empty-catch stink — needs multiline stink-engine extension
- [ ] ⛔ `archive/lint-ratchet-static-checks-plan.md` Phase 4: encode tier in underscore prefix on immediate mutators — PARKED, owner-gated, low priority → `archive/lint-ratchet-static-checks-plan.md`
- [ ] ⛔ Paint-time scroll translation Phase 4 (owner-gated): lift `scrollOffsetX/Y`, `_writeScrollOffset`, the paint interception and the provider from `ViewportWdgt` to `ClippingWdgt`, unlifted until a second user → `archive/paint-time-scroll-translation-plan.md`, "Phase 4: lift scroll translation to ClippingWdgt"
