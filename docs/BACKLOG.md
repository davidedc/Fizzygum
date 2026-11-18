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
- [ ] ⛔ **An object inspector's "Inherited" filter hides own values under superclass-declared names** — a run's `@step` and own state (`parent`, `bounds`) list only with Inherited on; four options, the owner's design call. → "An object inspector's Inherited filter hides values under superclass names"
- [ ] ⛔ **On a pre-compiled tree, a run's early member replacement reads as its class's source** — reached on `homepage`: the minified image has no function names; options: `keep_fnames`, a boot-side note, or accept. → "A pre-compiled tree's replaced member reads as its class's source"
- [ ] ⛔ **A wrapped member reads as compiled text, which the Smalltalk talk plan says it never does** — U2's MethodTally wrappers show compiled JavaScript; forward the record onto the wrapper or accept it: the owner's call. → "A wrapped member reads as compiled text"
- [ ] **The world's inspector offers to edit its browser listeners** — `world.browserInput`'s listener fields list Remove/Rename/Save; an edit leaves the browser calling the old function and keeps the dissolved world alive.
- [ ] ⛔ **A function held with no kept source shows compiled JavaScript in an editable CoffeeScript pane** — its Save is always refused; a read-only subject (class statics) is typeable too; label the pane or make it read-only. → "A function with no kept source shows compiled JavaScript"
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
- [ ] **`eliminateInvisibleCharacter` strips only the first marker** — `String.replace` with a string pattern replaces one occurrence, so a text holding two U+2063 is measured with the second.
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
- [ ] The `vmtruth` leg's pin cap is within reach of a green suite: a shard's spreadsheet tests leave 139 to 200+ uncollected (all UNRETAINED) cells at a sweep; past 200 a page it reads INVALID — medium: fg's serial retry absorbs it. → "The vmtruth leg's pin cap is within reach of a green suite"

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

### `archive/constructor-parameter-conformance-plan.md` — **CLOSED, P0–P9 all landed**
The arc's narrative, decisions and standing lessons live in that plan's BACKLOG ledger.
- [ ] ⛔ Plan §7d-D: `Widget.textPrompt` keeps a `msg` operand its only receiver (`CodePromptWdgt`) has no title bar to display; whether the door should shed the operand is an owner call. → "Plan §7d-D: Widget.textPrompt keeps an undisplayed msg operand"

### `archive/frames-input-touch-program.md` — the frames·input·touch PROGRAM (CLOSED 2026-08-27; all five plans executed and archived)
One chrome container (`FrameWdgt`) with a runtime `lifetime` state and manifestations derived from lifetime × parentage; Pointer Events; the single-geometry visual wave; the command-panel/`User` model; the gesture grammar + finger harness (the `finger` gauntlet leg, wave D). The living truth is in the architecture corpus (`input-and-gestures.md`, `viewports-and-planes.md`, `widget-authoring-guidelines.md`, the macros CLAUDE docs, the tests-repo reference grammar); rulings and the drained tail ledger are in the archived program doc. Residue rows, each with its origin:
- [ ] **icons on ordinary menus** (world menu, context menus) — owner taste, not built; `CommandSpec.icon` already exists, so a consumer costs one call site. Land only when a consumer asks.
- [ ] **remainder-menu alternative projections** — a grid pop or a label-only pop of the chevron's overflow menu, available by derivation on the same `CommandSpec` rows; land when a consumer asks.
- [ ] **T4 — multi-pointer** — pinch derived from two `pointerId`s, retiring the Safari `gesturestart`/`gesturechange` no-op listeners (ruling I1).
- [ ] **T5 — desktop-edge docking** — the world's edges as dock slots, a taskbar strip; needs a dock loop in the world's arrange, a fill gesture and a precedence against its `StretchLayoutSpec`s, all unruled.
- [ ] ⛔ **T18 — halo crowding at touch scale** — at `handleSize 44` the five corner handles overlap on widgets below ~92 px; fewer handles, edge zones or a halo mode is decided with the owner-pending G2 halo feel-check.
- [ ] **multi-user input attribution** — strokes carry `pointerId` and `world.users` exists; a User-per-pointer mapping is designed when a second input device exists.
- [ ] **finger scrolling for the spreadsheet** — the sheet takes no drag-scroll (wheel/scrollbar only), so its three wheel tests are mouse-only on the finger axis; a finger-scrollable sheet is a product feature.
- [ ] **inspector row-locator: scroll-further beyond 3 nudges** — a row still off-window after 3 nudges throws a named error (never fired in a green run); if a deeper list trips it, extend the nudge loop, not the aim.

### `archive/docked-and-floating-toolbars-plan.md` — who a tool works for: a docked toolbar its host window, a floating one the person (✅ CLOSED 2026-11-17: P0–P5, see its ledger; living truth `architecture/toolbars.md`; the open item below is planned in `plans/toolbar-arc-residue-plan.md` §U7)
- [ ] **A text menu pinned in edit mode keeps its editing rows after a flip to view mode** — a menu is built when it opens, so a pinned one still offers Bold and the rest once its content goes to view mode, and they act — reachable, low.

### `plans/toolbar-arc-residue-plan.md` — the toolbar arc's residue, fixed in one overnight loop (items filed on the way)
- [ ] **A caret's remembered column is not set by every caret move** — Home, End, Left and Right set it; a double- or triple-click, a delete of a selection and Up/Down collapsing a selection do not, so the next Up or Down lands under a stale slot (found by the U1 review, read from code) — reachable, low.
- [ ] **No keyboard way to a line's ends on a keyboard without Home and End** — `CaretWdgt._ctrl` / `cmd` handle only `a` and `z`, so Cmd+Left/Right (a MacBook has no Home or End key) and Ctrl+Home/End do nothing in a text (found by the U1 review, read from code) — reachable, low.
- [ ] **A speech-bubble tool's overflow-row picture shows placeholder boxes** — its text is typed into the row's one-time raster while that size's glyphs are cold (at the glyph size it fits at no size, -1), so the boxes never resolve; true before U2's sizing too (boxes at 16 px); probe in the U2 scratch — reachable, low.
- [ ] **A narrow window's own title strip clips its edit toggle** — below ~175 px wide a window's strip shows close and collapse only and its pencil is laid past its edge (a Docs Maker at its grip floor, 125, shows no pencil; measured by the U4 research); not a docked bar, so U4's floor leaves it — reachable, low.
- [ ] **The selection ring frames a drawing's paint surface after a click in view mode** — the ring asks the clicked glass's own edit flag, which no mode flip writes, so a view-mode Drawings Maker, or a bare drawing in a view-mode document, rings its surface (research C §3.3, U5) — reachable, low.
- [ ] **A widget's base context menu still acts on view-mode content** — its rows ("Pick up", "Color…", "Resize/move…") ask no mode: "Pick up" on a widget hosted in a cell of a sheet in a view-mode document empties the cell, and "Color…" restyles past the editing tools' refusal (U5 review, read from code) — reachable, low.
- [ ] **Other bare mode holders in view-mode content still take drops** — only a cell and a drawing's canvas ask the view mode around them, so a slide panel picked up into a Docs Maker, which is then flipped to view mode, still embeds a dropped widget (U5 review, read from code) — reachable, low.
- [ ] **A copy of a pinned wire menu shows and drives a clone of the wire** — a wire row's source is its `WireSpec`, which a copy copies rather than shares, so the copy's "Fires per event" tick never follows the real wire and toggling it flips only the clone (U6 review, read from code) — reachable, low.

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
- [ ] ⛔ W3 follow-up — the owner-review points W3 left open: an own property dimmed like an inherited one, the code pane's line pitch, toggle and chip looks, the prompt buttons' placement, and more (the plan's §4 W3). → "W3 follow-up — the owner-review points W3 left open"
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
- [ ] W5 follow-up — a caret at the right edge of a padless scrolling viewport (a loose string in a scroll panel) has its last column under the 1 px border; `scrollCaretIntoView`'s margin should include the border. → "W5 follow-up — a caret at a padless viewport's edge under its border"
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

### Pointer hit-test rework 2026-08-21 — residue (no plan doc; the arc ran assessment → execution)
`isTransparentAt` + `noticesTransparentClick` retired for three single-meaning members (`widget-authoring-guidelines.md` §5); what it did not take on: → "Pointer hit-test rework 2026-08-21 — the backlog's note"
- [ ] **`BubblyAppearance.shapeContainsPoint` OVER-CLAIMS its tail strip** — a click beside the spike stops on the bubble; harmless today; a fix needs an analytic body+spike test (a behaviour change with hover churn).

### SliderTrackClickMovesButton side-problems arc 2026-10-15 — residue (no plan doc; case law in `../../Fizzygum-tests/DETERMINISM.md` §3j)
The three measured residue items are CLOSED: `archive/backlog-closed-items-ledger.md` § "Residue arc 2026-10-16"; its follow-ups are filed under that arc. → "SliderTrackClickMovesButton side-problems arc 2026-10-15 — the backlog's note"
- [ ] ⛔ (optional, owner to decide) the gauntlet's `refs` leg hits its leg alarm in-wave on a loaded machine (twice on 2026-10-15) — a budget question; `Alarm clock: 14` names SIGALRM, not 14 s. → "The gauntlet's refs leg hits its leg alarm in-wave on a loaded machine"

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
- [ ] **The overflow (») menu's miniature of a text tool races the glyph atlas on SWCanvas pages** — the Slides toolbar's logo-with-text icon keeps placeholder boxes until the menu reopens; a `StringWdgt`'s, for good. → "The overflow menu's miniature of a text tool races the glyph atlas"
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

### Gate audit 2026-11-16 — residue (no plan doc; detail in `archive/backlog-open-items-detail.md`)
- [ ] **A firing gate says how to go quiet, never when the quiet fix is wrong** — ratchets steered sessions to inline helpers, home code by a ceiling, make a CLAUDE.md line false; many gates have a cheap quiet fix that is a contortion; each should print why it exists and when a raise or sanction is right — medium.
- [ ] **No audit has looked for shapes chosen only to quiet a non-ratchet gate** — search the session transcripts and git for each gate's quiet-fix spelling (an `if X?` guard, a stub, a deletion, a tier rename, a new exemption) and re-judge each find on its merits — medium.

### Tooling arc 2026-10-29 — residue (no plan doc; closed items in `archive/backlog-closed-items-ledger.md`)
- [ ] **A screenshot whose reference never LOADED reports as a pixel mismatch** — an empty candidate set says "no screenshots like this one" (seen in a loaded `settle` leg); give it its own line, then find why one goes missing. → "A screenshot whose reference never LOADED reports as a pixel mismatch."

### One line each — every item names the archived plan and section that owns its detail
- [ ] `docs/tooling/visual-review-sample.txt` names `SystemTest_macroEditModeTogglePencilEyeGlyph`, which has no test directory, so `fg diffpage` refuses the sample; drop it, or name the test covering the glyph now. → "visual-review-sample.txt names a test that no longer exists"
- [ ] Classes are still evaluated in sloppy mode (an indirect `eval.call window`); with `Mixin`'s `arguments.callee` rewrite deleted nothing needs it — whether to compile classes in strict mode is open. → `archive/mixin-removal-plan.md`, "Classes are still evaluated in sloppy mode"
- [ ] A `StretchableWidgetContainerWdgt` keeps a stale `@contents` after "Pick up", "Delete" or "Attach" on its page (a slide, a dashboard, a panel): re-lays move the departed page back, drops go to it — medium. → "A StretchableWidgetContainerWdgt keeps a stale @contents"
- [ ] `SystemTest_macroInternalVsExternalWindowDrop`'s unarmed drop is DETERMINISM.md §3k's class: under load its hold crosses `dwellToArmMs` and the window nests (seen once); schedule the release in event time. → `archive/drag-embed-implementation-plan.md`, "InternalVsExternalWindowDrop's unarmed drop can arm under load"
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
