# Scroll-frame role architecture — the Panel/ScrollPanel refactor

**STATUS BOX** (update per phase)
- P0 re-verification: ✅ DONE 2026-08-19 — zero drift (plan authored same day from the same greps);
  P0.2 verified: no PanelWdgt-subclass constructor forwards an argument to `super` (the bare-`super`
  hits are in `add`/`_reactToChild*` methods, and `CanvasWdgt`'s ctor takes no params); P0.3
  verified: zero `instanceof PanelWdgt|ScrollPanelWdgt` in `Fizzygum-tests/scripts/`; all script
  `scrollPanel` reads are the BIN's own field. Baseline: gauntlet 17/17 PASS (Fizzygum `baf3deac`).
- P1 scrollPolicy: ✅ DONE 2026-08-19 — gauntlet 17/17 PASS (281s), zero recaptures of existing
  references needed (presuite PASS 115s; new
  `SystemTest_macroScrollPolicyNeverFlip` captured dpr1+2, webkit-verified, 4 stable runs; in-run
  identical-pair assertions image_3≡4 (refused wheel) and image_2≡5 (flip round-trip restores exact
  pixels)). AS-BUILT deltas vs the phase text: (a) menu exposure is gated by a class-level
  `offersScrollPolicyToggle` (true on the base; opted out with one-line reasons by ListWdgt,
  ToolbarWdgt, PopUpRowsScrollFrameWdgt, SimpleTextScrollPanelWdgt,
  SimpleVerticalStackScrollPanelWdgt — the dedicated subclasses design their scroll behavior in,
  so the row would be menu rent + a footgun there); (b) the flip defers via
  `@_settleLayoutsAfter => @_invalidateLayout()` — a synchronous `_reLayoutChildren` trips
  layering rule F, and the deferred shape is the honest one (my `_reLayout` is
  'super; @_reLayoutChildren', so the flush delivers the identical re-fit); (c) the adapter is a
  toggle (`toggleScrollPolicyFromMenu`), labels "don't scroll (crop)" ⇄ "allow scrolling";
  (d) `setScrollPolicy` is in `buildSystem/public-api-allowlist.txt` (deliberate end-user API —
  call-separation rule U fires otherwise); (e) probe fact: the generic panel's context menu is
  288px tall in the 440px test world — fits, last row in view (probe kept at
  `Fizzygum-tests/.scratch/p1-menu-height-probe.js`); (f) MACRO-PATTERNS.md gained the
  refused-gesture/round-trip identical-shots entry.
- P3 plane role: ✅ DONE 2026-08-19 — gauntlet 17/17 PASS (351s), zero recaptures (presuite PASS
  113s, zero pixel changes). ⚠ LESSON (cost one 60-test red run): deleting `_reactToChildAdded` from PanelWdgt armed
  bare-`super` crashes in TransformFrameWdgt + StretchablePanelWdgt — a `?.`-dispatched notification
  hook can still have SUBCLASS super-callers, so a member deletion must grep every OVERRIDER for
  `super`, not just every dispatcher (both supers were provably no-op relays; deleted). Implemented:
  `isMyContentsPanel` + `contentsPanelHoldsLooseContent` (ListWdgt opts out) +
  `hidesContainedWidgetFromHierarchyMenu` (ScrollPanelWdgt + FolderWindowWdgt) + the
  `_reactToChildColorChanged`/`_reactToChildAlphaChanged` up-relays on the viewport;
  `ScrolledPaneWdgt` (new, `src/basic-widgets/`) carries the default-plane declarations
  (noticesTransparentClick, up-relay setters, the three holder relays, caret-forward click);
  PanelWdgt ctor is paramless, `@scrollPanel` field + both mirrors + the relays + the
  caret-forward DELETED from it; `_amITheContentsPanelOfAScrollPanelWdgt` and
  `Widget._amIDirectlyInsideScrollPanelWdgt` are parent role queries; the hierarchy-menu
  triple-instanceof exclusion is ONE parent query; `PopUpRowsPaneWdgt extends ScrolledPaneWdgt`.
  AS-BUILT facts: BinWdgt is the ONLY `_reactToChild*InScrollPanel` implementor and its plane is
  default-built (relay move safe — `fg storage`/`fg graph` prove it); Widget.setColor returns
  undefined on a no-change call, and the removed mirror wrote that undefined over the viewport's
  color on any repeated setColor — the relays guard on a real value (tiny invisible fix, viewport
  never paints); ⚠ the comment-smell ratchet rejects history narration — new comments must state
  what IS ("used to spell X" cost a build).
- P4 inheritance cut: ✅ DONE 2026-08-19 — gauntlet 17/17 PASS (298s), zero recaptures
  (presuite PASS 113s; build gates all pass on the cut). `ScrollPanelWdgt extends Widget` + own
  `ClippingAtRectangularBoundsMixin` augment; restated `extraPadding`/`_acceptsDrops`/
  `providesAmenitiesForEditing` + ctor appearance/colors (hit-testing parity, alpha 0 unchanged);
  `childrenCanLockToMe -> false` override DELETED (capability absence = the opt-out);
  SimpleVerticalStackScrollPanelWdgt's dead `removeMenuItem "move all inside"` DELETED. Audit
  outcomes: the six viewport subclasses have zero super/direct calls into lost members; chrome
  children (bars, ModifiedTextTriangleAnnotationWdgt) flip from Widget:3875's loose answer to
  the tail's grabs-to-parent — accepted pending suite evidence (solid chrome is the honest
  answer; HandleWdgt is nonFloatDragging, unaffected; the PLANE keeps PanelWdgt's own override).
- P5 content contract: ✅ DONE 2026-08-19 — gauntlet 17/17 PASS (298s), byte-identical CONFIRMED
  (zero pixel deltas, zero recaptures; presuite PASS 113s). As-built: FOUR queries, not three —
  `viewportConstrainsMyWidth` + `arrangesOwnScrolledChildren` + `managesOwnScrollPinning`
  (declared by SimpleVerticalStackPanelWdgt; capability ABSENCE is the panel default — no
  base-class stubs) and `scrolledContentMeasure(widthHint)` (PanelWdgt default measures at the
  hint; the stack overrides to measure at its own width); the text re-wrap loop moved verbatim
  into `ScrolledPaneWdgt._reWrapTextChildrenTo` (?.-dispatched — only a default plane defines
  it, the exact old `instanceof PanelWdgt` population). All four viewport rungs converted
  (`_positionAndResizeChildren` ×3, `_applyExtent` ×1); zero `instanceof` left in the arrange.
  ⚠ gate catch: the contract move left `subWidgetsMergedPreferredBounds` with only self-calls
  (both contract impls call it on THEMSELVES) → rule U; allowlisted as the pure-measure API
  sibling of the cross-called `subWidgetsMergedFullBounds`.
- P2, P6: not started. P2's owner decisions (which product name/icon survives) still open.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-19. Nothing in this plan has been executed. Every `file:line` reference was
verified against the tree on that date — line numbers DRIFT; the method name / quoted code is
authoritative, so re-grep before trusting any line number.

**MANDATE: complete elimination of the underlying problem, not mitigation.** The problem is that
the container family tangles three roles (viewport / content plane / scroll machinery) across two
classes joined by an implementation-inheritance edge that both classes spend code apologizing for.
The plan removes the tangle at the root: the back-pointer personality switch is deleted (not
wrapped), the inheritance edge is cut (not patched around), the type-test ladder becomes a declared
contract (not a longer ladder), and "behaves like a plain frame" becomes a first-class runtime
policy (not a construction-time class choice). Owner has explicitly waived churn, screenshot
recaptures, legacy support, and serialized-world compatibility — decisions in this plan are made on
architecture alone, and NO phase may keep a wart for compatibility's sake.

---

## §0 Orientation

**The project.** Fizzygum is a CoffeeScript GUI framework ("web operating system") rendered on one
HTML5 canvas, descended from Morphic.js. Three sibling repos under `Fizzygum-all/`: `Fizzygum/`
(source, the only repo this plan edits besides new tests), `Fizzygum-tests/` (SystemTest suite,
served through the `latest/js/tests` symlink — test edits need NO rebuild), `Fizzygum-builds/`
(generated, never edited). All build/test commands go through the wrapper
`/Users/davidedellacasa/code/Fizzygum-all/fg` (absolute path, NEVER `./fg`); bare `fg` prints the
current subcommand roster. Read the root `CLAUDE.md` and `Fizzygum/CLAUDE.md` before touching
anything.

**The vocabulary trap, stated up front.** In this codebase:

- `PanelWdgt` = the plain clipping container (what conversation calls "Frame" — Morphic's
  `FrameMorph` descendant).
- `ScrollPanelWdgt` = the scrolling container (what conversation calls "ScrollFrame").
- `FrameWdgt` = **the WINDOW class** (title bar, close button). It has nothing to do with this
  plan's subject except: ⛔ no class introduced or renamed by this plan may use "Frame" in its
  name — the word is taken.

The prose/code split is real and pre-existing: identifiers say *Panel*, comments and subclass names
say *scroll frame* (`PopUpRowsScrollFrameWdgt`, `_buildScrollFrame`, colloquialName `"menu rows
scroll frame"`). Phase 6 addresses it.

**Why this plan exists now.** Owner questioned the Frame-vs-ScrollFrame architecture: today a
container's scrollability is a construction-time class choice, yet menus (and lists, toolbars,
folders, the bin, prompts, documents) all use scroll frames that 99% of the time have nothing to
scroll and just behave like plain frames. The analysis (this plan's §1–§2) found the codebase has
already converged, case by case, on "scroll frame everywhere it matters" — and that the actual
defect is the ROLE tangle described in the mandate. This plan is the Right-Thing consolidation.

**Critical reframe (do not lose this):** in the auto case there is no "mode" and nothing ever
"turns into" a scroll frame at runtime — scrollbars are not a mode but the visible *consequence of
overflow*. A fitting scroll frame is ALREADY behaviorally a plain frame: bars auto-hide
(`_reLayoutScrollbars` shows a bar only when `@contents.width() >= @width() + 1`), and the `wheel`
handler escalates to the parent whenever content is at its edge — which, when content fits, is
always. What is genuinely missing is only the **'never'** policy ("clip, don't scroll, even when
content overflows") and the honesty of the class relationships around it.

---

## §0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` — orient on repo heads, build
   freshness, test count. Kill leftover browsers with `fg killz` if any.
2. Read this plan in full. Then read, in this order (all under `Fizzygum/`):
   `src/basic-widgets/PanelWdgt.coffee` (~220 lines), `src/basic-widgets/ScrollPanelWdgt.coffee`
   (~980 lines), `src/PopUpWdgt.coffee` lines 1–140,
   `src/basic-widgets/menu-system/PopUpRowsScrollFrameWdgt.coffee` and `PopUpRowsPaneWdgt.coffee`
   (both short), `docs/architecture/widget-authoring-guidelines.md`,
   `docs/architecture/lint-and-static-checks.md` (the gate index — several phases will trip gates
   if its rules are ignored), and the layout doc `docs/architecture/layout.md` §§ on the world
   cycle and settle tiers.
3. Execute phases IN ORDER (P0 → P6). Each phase ends with its own gate (stated in the phase) and
   a proposed commit. **Owner preference: ask before every commit/push — present a summary and a
   proposed message, then wait.** Do not start a later phase in the same session as an earlier
   phase's un-gated changes.
4. Phase 6 (rename) is OWNER-GATED: do not begin it without an explicit owner decision on the
   names (§Phase 6 presents the options).
5. Long ops (`fg gauntlet`, `fg suite`): launch ONCE with `run_in_background` redirected to a log;
   peek via `cat /tmp/fg-<cmd>.verdict` at a ~5-min cadence. Never pipe a gating fg call through
   `| tail`/`| grep`. Never edit `fg`, src, or tests while a launched run is in flight.
6. If a fix shape is falsified twice, STOP and re-frame — do not iterate a third variant
   (standing owner rule).

---

## §1 The system as it stands (verified 2026-08-19)

### 1.1 The two classes and the composite

`PanelWdgt extends Widget` (`src/basic-widgets/PanelWdgt.coffee`) — "clips subwidgets at bounds";
carries `@augmentWith ClippingAtRectangularBoundsMixin`, `_acceptsDrops: true`,
`providesAmenitiesForEditing: true`, a `RectangularAppearance`, and desktop-surface behavior
(drop slots, lock-to-panel granting via `childrenCanLockToMe`, "move all inside" menu entry).

`ScrollPanelWdgt extends PanelWdgt` (`src/basic-widgets/ScrollPanelWdgt.coffee`) — NOT a panel
with scrolling but a **composite viewport**: an invisible outer widget (`@alpha = 0`, never
paints) holding three pieces of chrome — a contents panel (`@contents`, the *plane* everything
scrolls on), and two `SliderWdgt` bars (`@hBar`/`@vBar`) wired through the public pin vocabulary
(`trackTarget @, "setScrollX"/"setScrollY"`). `add` redirects any non-chrome child into
`@contents` (chrome self-identifies via `attachesToScrollFrameDirectly?()` — HandleWdgt,
ModifiedTextTriangleAnnotationWdgt). Scrolling physically MOVES `@contents`
(`scrollX`/`scrollY` → `@contents._moveLeftSideTo` etc.); scroll offset is derived:
`getScrollX: -> @left() - @contents.left()`.

**The plane can be four different things.** `_buildScrollFrameNoSettle` builds a default plane —
`@contents = new PanelWdgt @ unless @contents?` — but callers may pass the plane in:
`new ScrollPanelWdgt new FolderPanelWdgt` (folder windows), `new ScrollPanelWdgt new
ToolPanelWdgt` (toolbars), `super new SimpleVerticalStackPanelWdgt` (stacks — note that class
`extends Widget`, not PanelWdgt), `super new PopUpRowsPaneWdgt()` (menus). So **plane-ness is a
role, not a class** — any topology fix must be parent-based, not class-based. ⭐ Verified fact
that makes Phase 3 clean: `new PanelWdgt <truthy-arg>` exists in EXACTLY ONE place in the tree —
`ScrollPanelWdgt._buildScrollFrameNoSettle`. Every other `new PanelWdgt` site (3 more:
`WindowWithPanelCreatorButtonWdgt`, `FridgeMagnetsWdgt`, `WidgetFactory`) passes nothing. So the
`@scrollPanel` back-pointer's only live population is the *default-built* plane; folder/toolbar/
stack/pop-up planes run with it `undefined` today.

**Subclass inventory.**
- of `ScrollPanelWdgt` (5): `SimpleVerticalStackScrollPanelWdgt` (+its subclass
  `SimpleDocumentScrollPanelWdgt`), `SimpleTextScrollPanelWdgt`, `ListWdgt`,
  `PopUpRowsScrollFrameWdgt`, `ToolbarWdgt`.
- of `PanelWdgt` (13): `ScrollPanelWdgt` itself, `TransformFrameWdgt`, `ShelfWdgt`,
  `IconGridPanelWdgt` (→ `WorldWdgt`, `FolderPanelWdgt`), `StringFieldWdgt`, `CanvasWdgt`
  (→ `SimpleImageWdgt` per a comment), `PopUpRowsPaneWdgt`, `SheetCellsPanelWdgt`,
  `StretchablePanelWdgt`, `FridgeWdgt`, `ToolPanelWdgt`, `SimpleTextPanelWdgt` (demos).
- direct `new ScrollPanelWdgt` sites (7): BinWdgt, FolderWindowWdgt, MacroToolkit (~line 1140),
  WindowWithScrollPanelCreatorButtonWdgt, SampleSlideApp, WidgetFactory, DemoMenus.

**Who already lives on scroll frames:** menus/prompts (unconditionally — see below), lists,
toolbars, folder interiors, the bin, documents, text panels. What still uses plain `PanelWdgt` is
a different ROLE each time: the world/desktop, transform islands, the spreadsheet cells plane, the
shelf, the fridge, and the planes/contents themselves. Nobody "chose Frame over ScrollFrame" —
the census shows the split is already role-shaped in practice, just not in the class design.

### 1.2 The coupling inventory (the defect, itemized)

**(a) The back-pointer personality switch.** `PanelWdgt`'s constructor is
`constructor: (@scrollPanel) ->`; when set, it flips `@noticesTransparentClick = false` and arms
two UP-mirrors: `setColor` copies the color to `@scrollPanel.color` and `setAlphaScaled` copies
alpha to `@scrollPanel.alpha` (PanelWdgt.coffee:64–84). Meanwhile `ScrollPanelWdgt.setColor`/
`setAlphaScaled` mirror DOWN into `@contents`. One fact, two owners, two hand-synced directions —
and the up-mirror silently doesn't run at all for folder/toolbar/stack/pop-up planes (no
back-pointer), so viewport `@color` is only truthful for default planes. Classic
state-duplication smell.

**(b) The parent-topology chokepoints (instanceof).**
- `PanelWdgt._amITheContentsPanelOfAScrollPanelWdgt: -> @parent? and @parent instanceof
  ScrollPanelWdgt` (PanelWdgt.coffee:92) — 3 internal callers: `mouseClickLeft` caret-forward,
  `detachesWhenDragged` refusal, `grabsToParentWhenDragged`.
- `Widget._amIDirectlyInsideScrollPanelWdgt` (Widget.coffee:~3945): `(@parent instanceof
  PanelWdgt or @parent instanceof SimpleVerticalStackPanelWdgt) and @parent.parent instanceof
  ScrollPanelWdgt and !(@parent.parent instanceof ListWdgt)` — callers: `Widget.
  grabsToParentWhenDragged` (~3869), `Widget._amIDirectlyInsideNonTextWrappingScrollPanelWdgt`
  (~3954, which also reads `@parent.parent.isTextLineWrapping`), `SimpleTextWdgt` (~line 82),
  `CaretWdgt` (~line 311, together with `@target.isScrollable`).
- `Widget.grabsToParentWhenDragged` also has a bare `if @parent instanceof PanelWdgt` arm
  (~3875) — NOTE this arm currently matches scroll frames too (they ARE PanelWdgts), i.e. a
  direct child of a VIEWPORT (chrome: handles, annotations, the caret) takes the
  `@isLockingToPanels` answer through it. Phase 4's audit table owns this delta.
- `Widget.hierarchyMenuWidgets` (~4375): three structural exclusions — "PanelWdgt whose parent is
  ScrollPanelWdgt", "SimpleVerticalStackPanelWdgt whose parent is
  SimpleVerticalStackScrollPanelWdgt", "ScrollPanelWdgt whose parent is FolderWindowWdgt" — all
  meaning "internal structure of a construct, hide it".
- `ScrollPanelWdgt._positionAndResizeChildren` — the content-sizing ladder, §1.3.

**(c) The inheritance lie.** `ScrollPanelWdgt extends PanelWdgt` yet: never paints (`alpha = 0`;
takes the plane's color "so its values mimic"); its children are chrome, not content;
`childrenCanLockToMe` flips PanelWdgt's `true` to `false`; `colloquialName` delegates to the
plane (`@contents?.scrollPanelColloquialName?() ? "scrollable panel"`); `add` redirects. Two
shipped classes exist SOLELY to correct wrong inherited answers for the menu case
(`PopUpRowsScrollFrameWdgt`, `PopUpRowsPaneWdgt` — each documents the defect its override fixed:
editing-surface claim, drop-target claim, drag-out claim, and the subtle one, the hit-target
claim: `RectangularAppearance.isTransparentAt` answers opaque-inside-bounds before consulting
anything). Concrete standing rake: `PanelWdgt.addWidgetSpecificMenuEntries` adds "move all
inside" over `@children` — inherited by every scroll frame via the `super` arm of its own
override, where `@children` is `[contents, hBar, vBar]` (today ~harmless because chrome is
already within; `SimpleVerticalStackScrollPanelWdgt` even carries a
`menu.removeMenuItem "move all inside"` line to undo it — a monument to the problem). Every
future PanelWdgt feature lands on scroll frames meaning the wrong thing, silently.

**(d) The two-hop shape leaks.** `PanelWdgt._reactToChildAdded/_reactToChildRemoved/
_reactToChildDropped` relay to `@parent?.parent?._reactToChild*InScrollPanel?` — the base class
encodes "I am the middle node of a three-deep sandwich". (These are PLANE-side behaviors that
happen to sit on the surface class.)

**(e) Name collision inside the bin.** `BinWdgt.scrollPanel` is an UNRELATED field (the bin's
reference to its own ScrollPanelWdgt child) sharing the name of PanelWdgt's back-pointer. Callers:
`BinWdgt`, `BinOpenerWdgt`, `StorageSorter`, `WorldWdgt` (`world.binWdgt.scrollPanel.contents`).
Phase 3 removes the PanelWdgt field, which dissolves the collision; the bin's field stays (it is
an honest child reference).

### 1.3 The content-sizing ladder (verbatim map)

`ScrollPanelWdgt._positionAndResizeChildren` (~line 446) branches on the plane's TYPE:

1. `if @contents instanceof SimpleVerticalStackPanelWdgt` — width-constrain the stack to the
   viewport when `@contents.constrainContentWidth` (a field the stack already declares!), then
   delegate arrange to the stack's own `_positionAndResizeChildren`.
2. `else if @isTextLineWrapping and @contents instanceof PanelWdgt` — re-wrap FIT_BOX_TO_TEXT
   text children at the viewport width.
3. Measure choice: `isContentSizing()` (already a named query — `@isTextLineWrapping` on the
   base, `true` on the stack/text subclasses) picks the §4.1 pure measure
   (`subWidgetsMergedPreferredBounds`, at the stack's own width for a stack, at
   viewport-minus-padding otherwise) vs. the applied read-back
   (`subWidgetsMergedFullBounds` — folders/toolbars, where free-floating child positions are
   STATE).
4. `_applyExtent` (~line 378) has one more rung: reset-scroll-on-resize excludes
   `@contents instanceof SimpleVerticalStackPanelWdgt`.

The ladder is where "who owns the width" is decided per plane KIND, as type tests inside the
viewport. Case law that the contract is real and can FIGHT: a width-owning plane
(`MenuRowsPanelWdgt` hugs its widest row) placed directly as `contents` livelocks against rung 1
and raises `RECALC_NONCONVERGENCE` — which is exactly why pop-ups interpose the pane
(⛔ documented in `PopUpWdgt._buildRowsScrollFrameNoSettle` and
`docs/../memory: popup-overflow-scroll-arc`; do NOT re-attempt the direct shape, §7).

### 1.4 Why it is shaped this way

Morphic descent. In Morphic's absolute-coordinate model (children's bounds are world-absolute;
moving a morph recursively rewrites the subtree's bounds), scrolling MUST physically move a
contents holder — so the wrapper composite (Swing's `JScrollPane`/`JViewport`, Cocoa's
`NSScrollView`/`NSClipView`) is the structurally forced shape, unlike CSS/UIKit where coordinates
are parent-relative and scrolling is a paint-time translation that can be a mere property of any
box. Fizzygum inherited both the composite AND Morphic's habit of implementation-inheriting it
from the plain container. The composite is correct; the inheritance and the personality switch
are the accidents. (The only path to "scrolling as a property of every panel" is re-basing
scroll on the affine transform-island machinery — deliberately OUT of scope, §7.6.)

### 1.5 The precedent that settles the "always composite?" question

`PopUpWdgt._buildRowsScrollFrameNoSettle`'s comment (PopUpWdgt.coffee:86–113) — rows ALWAYS live
in a scroll frame, because "a conditional frame would buy a few widgets per menu at the price of
a THRESHOLD, and a threshold is a state transition somebody has to get right… With the frame
always present there is nothing to cross." This is the in-repo litigation of lazy/conditional
structure, and this plan adopts its verdict globally: the plane is ALWAYS present; behavior
differences are POLICY, never structure (§7.1).

---

## §2 The distilled argument

1. The migration to "scroll frames everywhere it matters" is already done (census §1.1); what
   remains is to make the design say what the practice already is.
2. The remaining defects are five, all load-bearing: the personality switch (§1.2a), the
   parent-topology instanceof chokepoints (§1.2b), the inheritance lie with its standing rake
   (§1.2c), the shape-leaking relays (§1.2d), and the type ladder (§1.3). Each phase below kills
   exactly one.
3. One user-visible capability is genuinely missing: a runtime **'never'** scroll policy, which is
   what makes "frame vs scroll frame" a property flip instead of a class choice — and lets the
   doubled window products (`WindowWithPanelCreatorButtonWdgt` vs
   `WindowWithScrollPanelCreatorButtonWdgt`, both in `WindowsToolbarWdgt`) collapse into one.
   In a live-authoring system, choose-at-construction is a UX defect, not just an API style
   question.
4. Nothing here needs serialization migrations (verified: `src/serialization/` and
   `src/duplication/` contain ZERO Panel/ScrollPanel special-casing; both instantiate via
   `Object.create`, constructors never run on load) and the owner has waived compat anyway.
5. Prior art inside the tree points the way on every move: `isMyScrollBar(aWdgt)` is the exact
   pattern for the role query; the type-test-elimination ε campaign is the idiom for the ladder;
   `PopUpRowsPaneWdgt` is the seed of the plane class; the pop-up comment is the verdict on
   structure-vs-policy.

---

## §3 Target architecture (end state)

Three roles, three honest kinds:

1. **The viewport** — `ScrollPanelWdgt` (rename decision in Phase 6): `extends Widget`,
   `@augmentWith ClippingAtRectangularBoundsMixin` directly (precedent: `FrameWdgt` does exactly
   this — `extends Widget` + a direct augment; `TransformFrameWdgt` by contrast inherits the
   mixin VIA PanelWdgt, which is why it must never gain a direct augment of its own). Owns: clip, the chrome (plane + bars), the scroll
   funnel (`_reLayoutScrollbars` stays THE one announcement point — see the §P8 pins contract in
   the class), and a first-class **`scrollPolicy`**: `'auto'` (today's behavior) | `'never'`
   (clip; all scroll verbs refuse; bars never show; wheel always escalates). Explicitly restates
   the panel-isms it genuinely means (`_acceptsDrops: true`, `providesAmenitiesForEditing: true`,
   `extraPadding`); everything else it used to inherit it either already overrides or is glad to
   lose (Phase 4 table).
2. **The plane role** — parent-based, viewport-side query `isMyContentsPanel(aWdgt)` (mirror of
   the existing `isMyScrollBar`), consulted by all §1.2b chokepoints. Plus a dedicated class for
   the *default* plane: **`ScrolledPaneWdgt extends PanelWdgt`** — carries the declarations the
   default plane needs (`noticesTransparentClick: false`, the color/alpha up-relay expressed as a
   parent-capability notification, the sandwich relays of §1.2d, the plane-side gesture refusals).
   `PopUpRowsPaneWdgt` re-bases onto it and shrinks to its pop-up-specific answers. `PanelWdgt`
   loses its constructor parameter, its back-pointer, and every plane-conditional branch: it
   becomes purely the SURFACE class (desktop-like clipping drop surface).
3. **The content contract** — the plane (whatever class plays it) DECLARES its sizing relationship
   to the viewport via named queries replacing the §1.3 ladder rungs; the viewport reads
   declarations, never types.

Products: ONE window-with-panel product whose body is a viewport, policy-flippable at runtime from
its menu.

Non-goals (unchanged): the menu sandwich stays (§7.2); the desktop, islands, and other surfaces
stay plain panels (§7.4); no transform-based scrolling (§7.6); `SimpleVerticalStackPanelWdgt`
remains `extends Widget` (it is a plane/stack, not a surface — not this plan's business).

Design constraint honored throughout: **add ZERO new public members to `Widget.prototype`**
(⭐ a new public Widget method churns every inspector screenshot like a rename). Rewriting the
BODY of an existing Widget method (`_amIDirectlyInsideScrollPanelWdgt`) does not churn. New
queries live on the viewport/plane classes and are dispatched `?.()`, the house capability idiom.

---

## §4 Phases

Phases are ordered by value-first, then structure: P1/P2 deliver the owner-visible capability with
near-zero structural risk; P3–P5 do the surgery; P6 is the owner-gated rename. Each phase is
independently shippable and gauntlet-gated. Estimated sizes are for orientation only.

### Phase 0 — Re-verification pass (read-only, ~1h)

The coupling inventory in §1 was verified 2026-08-19; the tree moves fast. Before editing:

- P0.1 Re-run the census greps and confirm the facts still hold, especially: (a) `new PanelWdgt`
  with a truthy argument exists only in `_buildScrollFrameNoSettle`; (b) `src/serialization/` +
  `src/duplication/` still contain zero `PanelWdgt|ScrollPanel` matches; (c) the
  `_reactToChild*` dispatch sites are all `?.`-guarded (`Widget.coffee` ~745, ~3517–3521,
  ActivePointerWdgt ~357, ~529); (d) the instanceof site list of §1.2b is complete — grep
  `instanceof PanelWdgt|instanceof ScrollPanelWdgt` fresh and reconcile any NEW site against
  this plan before proceeding.
- P0.2 Grep `super` args in all 13 PanelWdgt subclasses' constructors — confirm none forwards a
  scrollPanel argument (expected: none; `ScrollPanelWdgt` calls bare `super()`).
- P0.3 Skim `Fizzygum-tests/scripts/` uses: `graph-liveness-headless.js` (~160: constructs
  `new ScrollPanelWdgt()` fixtures for the scroll-pin probes), `menu-click-sweep-headless.js`
  (~273: class roster includes both names), `layout-audit-prelude.js`, the revisit preludes.
  Confirm none does `instanceof PanelWdgt` ON a scroll frame in a way a later phase breaks.
- Gate: none (read-only). Deliverable: a short delta note appended to this plan if anything
  drifted, corrections woven in.

### Phase 1 — `scrollPolicy` ('auto' | 'never') + the runtime flip (~½ day)

The one genuinely new capability. All edits in `ScrollPanelWdgt.coffee` unless noted.

- P1.1 Class-level field `scrollPolicy: 'auto'` (class-level declaration per
  widget-authoring-guidelines; serializes for free as a plain field).
- P1.2 Gate the funnel — the class's own architecture makes this small because every scroll path
  already converges (the §P8 "FUNNEL" comment above `pins()`). Exact gate points:
  - `scrollX`/`scrollY` (the movement cores): first line `return false if @scrollPolicy is
    'never'`. This alone makes `setScrollX/Y` (pins), `scrollTo`, `scrollToBottom`, `autoScroll`,
    and the momentum glide inert — they all route through the cores.
  - `wheel`: the escalate-vs-scroll decision must escalate under 'never' (do NOT rely on the
    cores' refusal — the current code only escalates when content is at its edge, so a 'never'
    frame with overflow would otherwise swallow the wheel dead). Add the policy to both axis
    conditions.
  - `mouseDownLeft` (drag-scroll): `return undefined if @scrollPolicy is 'never'` alongside the
    existing `isScrollingByfloatDragging` guard, so the gesture falls through to normal
    grab/detach recognition instead of installing a dead step.
  - `maybeStartAutoScrollForDraggedWidget`: no-op under 'never'.
  - `scrollCaretIntoView`: no-op under 'never' (consistency; a 'never' text panel clips its
    caret, WYSIWYG).
  - `_reLayoutScrollbars`: under 'never', hide both bars unconditionally (before the
    per-axis show logic), keep the trailing `world.dataflow.markNonValueChange @` (the announce
    contract is about the funnel, not about motion).
  - `sliderRangeForPin`: return `undefined` under 'never' (a bound external slider shows no
    scale — same as no-overflow today).
  - `pins()`: UNCHANGED — scroll pins stay advertised; delivery under 'never' is a clamped
    no-op via the cores. Rationale: a policy flip mid-life must not sever wires;
    `fg pinsweep` requires advertised pins be SERVICEABLE (setter resolves and runs — it does).
- P1.3 The flip: public `setScrollPolicy (policy)` — validates the enum, assigns, then
  `@_settleLayoutsAfter => @_reLayoutChildren()` so a flip on a live overflowing frame
  shows/hides bars and re-fits in one settle. Menu exposure on the scroll frame's
  `addWidgetSpecificMenuEntries`: a toggle entry (proposed labels: "don't scroll (crop)" ⇄
  "allow scrolling"; owner may re-word at review). ⚠ Menu-adapter contract
  (`check-menu-actions` + the menu-action-wiring case law): dispatch passes the MENU ITEM in
  slot 1 and more in later slots, so the adapter must be a dedicated
  `toggleScrollPolicyFromMenu: (ignored, ignored2) -> ...` calling the real setter — never wire
  `setScrollPolicy` directly as the action.
- P1.4 Contents sizing under 'never': DELIBERATELY unchanged. The plane still grows to merged
  bounds; overflow is clipped (offset pinned at origin by the refused cores +
  `keepContentsInScrollPanelWdgt`). That IS plain-frame semantics. State this in a comment at the
  policy field.
- P1.5 Tests (in `Fizzygum-tests`, macro style — read `src/macros/CLAUDE.md` +
  `/author-macro-test` in the tests repo first): one new SystemTest,
  `SystemTest_macroScrollPolicyNeverFlip`: build a scroll panel with overflowing content →
  screenshot (bars visible) → flip to 'never' via the menu → screenshot (bars gone, content
  clipped at origin) → wheel over it → screenshot (nothing moved / outer scrolled) → flip back →
  screenshot (bars back, scrolling live). Remember: tests are SERVED through the symlink — no
  rebuild for test edits; capture references with `fg recapture --auto` AFTER building.
- Gate: `fg presuite`, then `fg gauntlet` (pinsweep + menusweep legs specifically validate P1.2/
  P1.3). Commit (ask owner first).

### Phase 2 — Collapse the doubled window products (~2h, rides on P1)

- P2.1 `WindowWithPanelCreatorButtonWdgt.createWidgetToBeHandled` currently returns
  `new FrameWdgt new PanelWdgt`; `WindowWithScrollPanelCreatorButtonWdgt` returns
  `new FrameWdgt new ScrollPanelWdgt`. Collapse: ONE button whose product is
  `new FrameWdgt new ScrollPanelWdgt` (policy 'auto'), with the P1 menu flip covering the
  cropping-panel need. Remove the other button from `WindowsToolbarWdgt` (authoring part;
  `check-part-edges` will hold you honest on any stray reference) and delete its class + its
  icon-appearance class if now unreferenced (`check-dead-methods`/coverage gates will point at
  leftovers).
- P2.2 OWNER DECISIONS to collect at review, not to guess: (a) which of the two products/names
  survives (proposed: keep the *panel* wording — tooltip "panel" — because 'auto' looks like a
  plain panel until content overflows); (b) which icon art survives
  (`WindowWithCroppingPanelIconAppearance` vs `WindowWithScrollingPanelIconAppearance`); (c)
  whether `WidgetFactory.createNewPanelWdgt` (dev tool) keeps offering a bare `PanelWdgt`
  (proposed: YES — the surface class remains a legitimate dev-tools product).
- P2.3 Expect screenshot churn: any test exercising the windows toolbar row layout. Recapture
  deliberately, pixels inspected first (a recapture is a decision to BELIEVE the pixels).
- Gate: `fg presuite` + `fg gauntlet`. Commit (ask).

### Phase 3 — The plane role: `isMyContentsPanel`, `ScrolledPaneWdgt`, back-pointer purge (~1 day)

- P3.1 Viewport-side role query, mirroring `isMyScrollBar`:
  `isMyContentsPanel: (aWdgt) -> aWdgt is @contents`. Convert the §1.2b chokepoints to consult
  it via `?.()` with semantics IDENTICAL today:
  - `PanelWdgt._amITheContentsPanelOfAScrollPanelWdgt` body becomes
    `@parent?.isMyContentsPanel? @` (keep the method — it is the named chokepoint; its three
    callers don't move).
  - `Widget._amIDirectlyInsideScrollPanelWdgt` body becomes
    `@parent?.parent?.isMyContentsPanel?(@parent) and !@parent.parent.contentsSelectionFollowsList?()`
    — the ListWdgt exclusion must survive EXACTLY; express it as a viewport-side capability
    override on `ListWdgt` (name it for what the exclusion means at its call sites — inspect the
    four callers in P0/§1.2b before naming; if the meanings diverge, split the query rather than
    averaging them). Note the old body ALSO required the parent be a PanelWdgt-or-stack; with the
    role query that type test is subsumed (only a viewport answers, and only about its plane).
  - `Widget.hierarchyMenuWidgets`: replace the two scroll-related structural exclusions with
    `each.parent?.isMyContentsPanel?(each)` (plane hidden) and keep/convert the
    FolderWindowWdgt one via the existing `hiddenFromHierarchyMenu?()` idiom (give
    `ScrollPanelWdgt` a `hiddenFromHierarchyMenu` that answers true iff
    `@parent instanceof FolderWindowWdgt` — or better, a folder-window-side declaration;
    executor's judgment, but NO new Widget member).
- P3.2 `ScrolledPaneWdgt extends PanelWdgt` (new file,
  `src/basic-widgets/ScrolledPaneWdgt.coffee`; one class per file, filename = class name — the
  build keys off it; the dependency finder needs the literal `extends PanelWdgt`). Carries, moved
  OUT of PanelWdgt:
  - `noticesTransparentClick: false` (class-level; today set conditionally in PanelWdgt's ctor).
  - the color/alpha up-relay, re-expressed parent-based: in `setColor`, after `super`, notify
    `@parent?._noteContentsColorChanged? aColor` (viewport implements it: adopt the color unless
    equal — preserving today's guard against ping-pong); same for alpha
    (`_noteContentsAlphaChanged`). The viewport's DOWN-mirror (`ScrollPanelWdgt.setColor` →
    `@contents.setColor`) stays as is. Net: same observable sync, zero stored back-pointer.
    ⭐ Behavior delta to embrace (Right Thing): the up-relay now ALSO works for
    folder/toolbar/stack planes if they route through it — but those classes don't subclass
    ScrolledPaneWdgt, so to keep this phase minimal the relay lives in ScrolledPaneWdgt only,
    matching today's de-facto behavior (up-sync only for default planes).
  - the §1.2d sandwich relays: `_reactToChildAdded`, `_reactToChildRemoved`, and the
    `_reactToChildDropped` holder-notification half move to `ScrolledPaneWdgt`. ⚠ SPLIT
    CAREFULLY: `PanelWdgt._reactToChildRemoved/_reactToChildDropped` also do `_reFitContainer
    @parent` — that half is generic panel behavior (a stack/window parent re-fits) and STAYS on
    PanelWdgt; only the `@parent?.parent?._reactToChild*InScrollPanel?` relay lines move.
    Verify against the bin: `BinWdgt`/`StorageSorter` listen via
    `_reactToChild*InScrollPanel` on the bin (the scroll panel's holder) — the bin's plane is a
    DEFAULT plane (`new ScrollPanelWdgt` bare), so it becomes a `ScrolledPaneWdgt` and the relays
    keep firing. Run `fg storage` (gauntlet leg) to prove it.
  - `mouseClickLeft`'s caret-forward branch (the `_amITheContentsPanelOfAScrollPanelWdgt`-gated
    half) — moves; PanelWdgt keeps `bringToForeground()`.
  - the `detachesWhenDragged` / `grabsToParentWhenDragged` plane-refusal branches — ⚠ these must
    KEEP working for NON-default planes too (folder panels must not detach from their viewport!).
    They are chokepointed on `_amITheContentsPanelOfAScrollPanelWdgt`, which is parent-based and
    stays on PanelWdgt — so they DON'T move; they already serve every PanelWdgt-family plane.
    Only genuinely default-plane-specific members move to ScrolledPaneWdgt. (This is the
    subtlety of the phase: split by "whose behavior is this" — plane-ROLE behavior stays on
    PanelWdgt gated by the role query; default-plane-CLASS declarations move.)
  - `_addInPseudoRandomPositionNoSettle`: stays on PanelWdgt (callers reach it via
    `scrollPanel.contents`, and `Widget._addLostWidgetNoSettle` routes through it — verify with
    the grep; it is generic "scatter into me" panel behavior).
- P3.3 The purge: `PanelWdgt.constructor` becomes parameterless (`constructor: ->`); delete the
  `scrollPanel: undefined` declaration, the ctor's `if @scrollPanel` branch, and both up-mirror
  branches. `_buildScrollFrameNoSettle` builds `@contents = new ScrolledPaneWdgt() unless
  @contents?` (note: no argument). `PopUpRowsPaneWdgt` re-bases: `extends ScrolledPaneWdgt`,
  deleting whatever it only declared because the base didn't (`alpha: 0` stays — that one is
  pop-up-specific; re-read its comments member by member).
- P3.4 Sweep check: grep `\.scrollPanel\b` — remaining hits must ALL be the bin-family field
  (§1.2e) plus `DocumentWdgt`'s local variable. Anything else is a missed reader.
- Gate: `fg presuite`; `fg gauntlet` with special attention to the `storage`, `serialization`,
  `graph`, and `census` legs (the plane class changes identity: serialized worlds and the
  duplicator now see `ScrolledPaneWdgt` — owner has waived compat, and the serializer has no
  per-class registry to update, but the RIGS assert structure; fix their expectations, don't
  weaken them). Inspector-family screenshots churn (new class in hierarchy menus? — no: planes
  are hidden from hierarchy menus, but inspectors list fields; recapture what actually
  changes, pixels inspected). Commit (ask).

### Phase 4 — Cut the inheritance: `ScrollPanelWdgt extends Widget` (~1–1.5 days)

The load-bearing phase. `class ScrollPanelWdgt extends Widget` +
`@augmentWith ClippingAtRectangularBoundsMixin, @name` (the mixin carries:
`clipsAtRectangularBounds`, clipped `fullBounds`/`fullClippedBounds`, the clipped paint pair, the
`_applyMoveBy` scroll-optimization override, `plausibleTargetAndDestinationWidgets`).
⚠ Mixin law: the same mixin twice in one inheritance chain is a boot-guarded latent infinite
recursion — PanelWdgt keeps its augment, the viewport gains its own, and NO class may sit under
both (nothing does: the viewport's subtree and PanelWdgt's subtree are disjoint after this
phase — verify by re-grepping `extends ScrollPanelWdgt`).

**The member-by-member audit table.** For every concrete member of `PanelWdgt`, what the viewport
does after the cut. Execute as a checklist; anything found in PanelWdgt that is NOT in this table
(the class WILL have drifted) gets classified into one of the four columns' patterns before
proceeding. ⚠ FOR EVERY member the viewport's chain LOSES, ALSO grep the viewport's own
subclasses (`SimpleVerticalStackScrollPanelWdgt`, `SimpleTextScrollPanelWdgt`, `ListWdgt`,
`PopUpRowsScrollFrameWdgt`, `ToolbarWdgt`, `SimpleDocumentScrollPanelWdgt`) for an override
calling `super` into it and for direct `@`-calls — P3 paid a 60-test red run to learn that a
`?.`-dispatched hook can still have subclass super-callers, and a vanished chain member turns
each one into a runtime TypeError (the plan's P3 STATUS entry has the case).

| PanelWdgt member | Viewport after the cut | Rationale / verification |
|---|---|---|
| `@augmentWith ClippingAtRectangularBoundsMixin` | gains own augment | see mixin law above |
| `scrollPanel` field + ctor param | GONE in P3 | — |
| `extraPadding: 0` | RESTATE on viewport | read by `setContents`, `_positionAndResizeChildren`, `scrollCaretIntoView`; zero outside reads (verified) |
| `_acceptsDrops: true` | RESTATE | `wantsDropOfChild` returns it |
| `providesAmenitiesForEditing: true` | RESTATE | load-bearing: `FrameWdgt` (~1001) shows the pencil off `@contents?.providesAmenitiesForEditing`; `WorldWdgt` (~1654) gates edit-mode focus |
| ctor: `dragsDropsAndEditingEnabled = true` | drop | Widget default is already `true` (Widget.coffee:87) |
| ctor: `@appearance = new RectangularAppearance @` | KEEP INITIALLY (restate) | alpha=0 so it never paints, but it decides `isTransparentAt` (opaque-inside-bounds) → hit-testing parity. A/B removing it is a P4-optional probe: Widget's appearance-less answer is ALSO opaque (`? false`), so removal is plausibly byte-identical — prove with the suite before keeping the removal |
| ctor: colors from preferences | RESTATE (the plane mimic then overwrites in `_buildScrollFrameNoSettle`) |
| `_findDropSlot` | not needed | callers: PanelWdgt-internal + `ToolPanelWdgt` (a PanelWdgt) |
| `makeFolderFromMenu`/`makeFolder` | not needed | menu-wired only for desktop/folder panels |
| `setColor`/`setAlphaScaled` up-mirrors | n/a (viewport has its own down-mirror overrides; re-parent them onto Widget's `super`) | verify `super` semantics unchanged (both call `super aColor` → Widget) |
| `_amITheContentsPanelOfAScrollPanelWdgt` | not needed (viewport is never a plane — nothing puts a viewport as `@contents`: verify by grepping `new ScrollPanelWdgt new ScrollPanelWdgt` = none, and `setContents` callers) |
| `childrenCanLockToMe` | DELETE the viewport's `-> false` override | after the cut the query is simply ABSENT → `?.()` dispatch at Widget ~4450 yields no menu entry: same outcome, one less apology |
| `mouseClickLeft` | inherit Widget's | clicks land on the plane/rows anyway; plane keeps `bringToForeground` via PanelWdgt. VERIFY: no test clicks a bare viewport margin expecting foregrounding |
| `_reactToChildDropped/Removed/Added/Grabbed` | viewport keeps its OWN `_reactToChildDropped`/`_reactToChildGrabbed` overrides (they exist); loses the inherited Removed/Added | dispatches are `?.`-guarded (verified). Semantic delta: chrome detach (a handle/annotation leaving the viewport) no longer triggers PanelWdgt's `_reFitContainer @parent`. Handles are ephemeral overlays (destroyed, not detached); annotations lock. A/B: run the suite; if a regression names this, RESTATE a minimal `_reactToChildRemoved -> @_reFitContainer @parent` on the viewport with a comment |
| `detachesWhenDragged`/`grabsToParentWhenDragged` | inherit Widget's | PanelWdgt's versions = plane-guard + `super`; the viewport is never a plane, so Widget's answer is what it effectively got. ⚠ BUT Widget.grabsToParentWhenDragged's `@parent instanceof PanelWdgt` arm (~3875): children-of-viewport (chrome) LOSE that arm's `@isLockingToPanels` answer. Audit each possible direct child: bars (SliderWdgt: `nonFloatDragging` path — unaffected, verify), handles (`attachesToScrollFrameDirectly`, ephemeral), annotations (`isLockingToPanels = true` → today locked via the arm; after the cut they fall to the `wantsDetachOfChild?`/`return true` tail = still solid with parent → SAME outcome, verify by reading the tail). If any child's answer flips, teach THAT child, not Widget |
| `addWidgetSpecificMenuEntries` ("move all inside") | inherited entry disappears from viewport menus | THE RAKE CLOSES. Delete `SimpleVerticalStackScrollPanelWdgt`'s now-dead `menu.removeMenuItem "move all inside"` line (and its comment). `fg menusweep` + the menu screenshots verify |
| `keepAllSubwidgetsWithin` | not needed | menu-reachable only via the entry above |
| `_addInPseudoRandomPositionNoSettle` | not needed on viewport | called on planes only (verified: `scrollPanel.contents.…` at both call sites + `_addLostWidgetNoSettle`) |

Also in this phase:
- Re-point the two `instanceof` sites that MENTION ScrollPanelWdgt but relied on it being a
  PanelWdgt — re-grep `instanceof PanelWdgt` after the cut and re-classify every hit: does this
  site MEAN "surface" (keep), "plane" (P3 role query), or "used to catch viewports too" (needs
  the viewport class added or a capability)? §1.2b's list is the checklist; the known one is
  `grabsToParentWhenDragged` ~3875 (table row above).
- `Fizzygum-tests` preludes list class names (`layout-audit-prelude.js` ~187/195 groups
  `ScrollPanelWdgt` with panels) — names still resolve; nothing asserts the inheritance edge
  (verified P0.3), but re-run the full gauntlet's audit legs to prove it.
- Gate: `fg presuite`, then FULL `fg gauntlet`. Watch specifically: `census`
  (arrange-idempotence — the ctor restatements must not change one pass), `revisits` (baseline
  EMPTY — any re-visit = regression), the dpr2 leg, `menusweep`. Expect menu screenshots to
  change ("move all inside" gone from scroll-frame menus) → recapture deliberately, diff-inspect
  first. Commit (ask).

### Phase 5 — The content contract: retire the sizing ladder (~1 day, probe-first)

Replace §1.3's type tests with declarations, PRESERVING BYTE-IDENTICAL LAYOUT (this phase is
byte-identical-intent; the house method is the Stage-C probe: instrument, run the suite, count
mismatches, expect zero — see `docs/archive/proper-layouts-4.2-structural-arrange-plan.md`'s
Stage-C precedent, 0/1429).

- P5.1 The contract, three queries answered by the PLANE (defaults on `PanelWdgt`; overrides on
  `SimpleVerticalStackPanelWdgt` — note it extends Widget, so state defaults there too or
  dispatch `?.` with the panel default inline):
  - `viewportConstrainsMyWidth()` — stack: `@constrainContentWidth`; panel default: `false`.
    Replaces rung 1's gate.
  - `arrangesOwnScrolledChildren()` — stack: `true` (viewport then calls the plane's
    `_positionAndResizeChildren`); panel default: `false`. Replaces rung 1's delegation test.
  - `scrolledContentMeasure(widthHint)` — returns the pure preferred-bounds measure the ladder
    computes today (stack: `subWidgetsMergedPreferredBounds(@width())`; wrap-panel:
    `subWidgetsMergedPreferredBounds(widthHint)`), or `undefined` meaning "read my applied
    bounds back" (folders/toolbars). Replaces rung 3. `isContentSizing()` remains the
    viewport-side switch it already is.
  - Rung 2 (text re-wrap) moves INTO the plane: `ScrolledPaneWdgt._reWrapTextChildrenTo
    (textWidth)` containing the FIT_BOX_TO_TEXT loop verbatim; the viewport calls it when
    `@isTextLineWrapping` — the loop reads only the plane's children, so it is plane code that
    was living in the viewport.
  - Rung 4 (`_applyExtent` reset-scroll exclusion): the exclusion means "a wrapping STACK's
    position is managed by the arrange's clamp" (its own comment) — express as the stack
    answering `managesOwnScrollPinning()` true; default false.
- P5.2 ⛔ Scope fence: this phase changes WHERE the decisions live, never WHAT they decide. Any
  temptation to "fix" a contract while moving it (e.g. letting a width-owning plane be direct
  contents) is out of scope (§7.2).
- P5.3 Probe: before/after A/B on the full suite at dpr1 + the presuite dpr2 rider; assert zero
  screenshot deltas and zero `RECALC_NONCONVERGENCE`/`NON_INTEGER_GEOMETRY` tokens. The capstone
  and census gauntlet legs are the deep verifiers here.
- Gate: `fg presuite` + full `fg gauntlet`, zero recaptures EXPECTED (byte-identical intent — a
  needed recapture here means the phase failed; investigate, don't recapture). Commit (ask).

### Phase 6 — Rename by role (OWNER-GATED — collect the decision first)

Present to owner; do not pre-decide:

- **Option A (recommended): rename.** `ScrollPanelWdgt` → `ViewportWdgt` — names the ROLE, true
  at every size ("a viewport that fits its content is still a viewport"), dissolves the
  scroll-frame/panel prose split; `ScrolledPaneWdgt` already matches. Update colloquial fallback
  `"scrollable panel"` → owner's wording (pixel-visible!).
- **Option B: keep `ScrollPanelWdgt`.** Precedent: UIScrollView/CSS "scroll container" name the
  capability ceiling, not the modal behavior. Zero churn, zero risk, prose split stays.
- ⛔ Under either option: nothing gains "Frame" in its name (`FrameWdgt` = window); no name may
  encode the mode ("MaybeScrolling…" is the gloss-in-identifier smell).

If A: execute as ONE verifiable batch per the rename case law — whole-tree identifier + file
rename in `Fizzygum/src` (filename must equal class name), PLUS the cross-repo sweep the P9
lesson mandates: `Fizzygum-tests/scripts/` (the files listed in P0.3 reference the class by name
— `graph-liveness-headless.js`, `menu-click-sweep-headless.js`, `layout-audit-prelude.js`,
revisit/storage preludes, `serialization-roundtrip-headless.js`, `staleness-census.js`,
`pin-sweep-headless.js`) and the macro tests: ⚠ macro source is CoffeeScript inside JS template
literals — a `.coffee`-scoped search CANNOT find construction sites; grep by class name across
`Fizzygum-tests/tests/**/*.js` (93 files mention `ScrollPanelWdgt` as of 2026-08-19).
Colloquial-name pixels shift → screenshot recaptures; hierarchy-menu labels strip `Wdgt`, so
"Viewport" appears in menus — owner sees proposed wording BEFORE the batch. Gate: full
`fg gauntlet` + `fg recapture --auto` (BUILD FIRST — the recapture tool's discovery pass runs
against the existing build). Commit (ask).

### Phase 7 — Close-out (ritual)

Run the `/close-arc` skill: final full gauntlet; docs residue — new architecture doc
`docs/architecture/scroll-frames-and-planes.md` (the three roles, the policy, the content
contract, the pop-up threshold verdict generalized) + weave into
`widget-authoring-guidelines.md` (the "which container do I use" decision) and `layout.md`
(contract queries) via `/docs-sync`; `docs/BACKLOG.md` lines for: the transform-island scroll
horizon (§7.6), the menu-sandwich revisit (§7.2), up-relay for non-default planes if ever wanted
(P3.2 note); `git mv` this plan to `docs/archive/` + stamp + INDEX line; memory note; ONE
end-of-arc review; proposed commit messages; wait for owner.

---

## §5 Verification protocol (applies to every phase)

- Inner loop: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (build + dpr1 suite ∥ paint
  audit ∥ fracplane dpr2 rider, ~3 min).
- Phase close: `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet` — background, log to
  `/tmp/`, watch `/tmp/fg-gauntlet.verdict`. 16–17 legs; the ones this plan leans on hardest:
  `menusweep` (P1.3/P4 menu changes), `pinsweep` (P1.2 pins), `storage` (P3.2 bin relays),
  `serialization` (P3 plane class identity), `census`+`revisits`+capstone (P4/P5 layout parity),
  dpr2/webkit suites (determinism).
- Single test debug: `cd Fizzygum-tests && node scripts/run-macro-test-headless.js
  SystemTest_<name>`.
- Recaptures: `fg recapture --auto`, ALWAYS after a fresh build; inspect the pixel diff before
  believing it; a recapture during Phase 5 is a failure signal, not a fix.
- Fail-gate tokens that must stay at zero: `RECALC_NONCONVERGENCE`, `NON_INTEGER_GEOMETRY`,
  `NON_FINITE_GEOMETRY`, `RESETWORLD_INCOMPLETE`, `POPUP_LARGER_THAN_WORLD`.
- Static gates: read `docs/architecture/lint-and-static-checks.md` before adding any method the
  gates pattern-match (menu adapters, `_`-privacy, method headers — ⭐ the shared header regex
  lives in `buildSystem/lib/coffee-method-header.js`; a malformed header makes SIX gates blind,
  silently).

## §6 Central risks

1. **Layout parity in P4/P5.** The arrange path (`_positionAndResizeChildren` +
   `_reLayoutScrollbars`) is the most case-law-laden code in the tree (schedule-valve V1, §4.1
   Stage C, §4.2 structural arrange, the pinned `implementsDeferredLayout -> false` with the
   16→18 nested-scroll trap). MOVE code verbatim; keep every comment; never "simplify" a guard
   while relocating it. The pinned `implementsDeferredLayout` MUST survive the re-parenting to
   Widget (Widget's derivation is `@_reLayout != Widget::_reLayout` — the viewport defines
   `_reLayout`, so without the explicit pin it flips true and regresses nested scroll).
2. **Hit-testing parity in P4.** The appearance/alpha/isTransparentAt triangle is subtle (the
   PopUpRowsPaneWdgt header documents it). Keep ctor parity first; probe removals separately.
3. **Chrome gesture deltas in P4** (the `~3875` arm) — audited per-child in the table; the rule
   if something flips: teach the child, never widen Widget.
4. **The bin/storage relays in P3** — split the relay lines from the re-fit lines exactly;
   `fg storage` is the dedicated proof.
5. **Session discipline** — this arc touches the two biggest files' hottest paths; keep phases in
   separate commits, gauntlet between, and never two phases un-gated in one working tree.

## §7 Rejected alternatives — do NOT re-attempt

1. **Conditional / lazily-materialized scroll structure** ("add the plane+bars only when content
   overflows"): the threshold trap, litigated and rejected in
   `PopUpWdgt._buildRowsScrollFrameNoSettle`'s comment — a mid-life restructure during the very
   membership change that provokes it, plus identity breakage for references/wires/locks.
   Policy over structure, always.
2. **Width-owning plane as direct `contents`** (e.g. MenuRowsPanelWdgt without the pane
   sandwich): does not terminate — the viewport's width-constrain fights the hug,
   `RECALC_NONCONVERGENCE` (A1 arc). The P5 contract makes the fight *expressible*; it does not
   make the menu sandwich removable in this arc — that would be its own plan with its own probe.
3. **Runtime plane-role conferral via a stored back-pointer/flag** — that IS the `@scrollPanel`
   design being deleted. Role = parent topology, asked live (`isMyContentsPanel`), never stored.
4. **Universal scroll frames** (desktop, transform islands, spreadsheet cells plane, shelf as
   viewports): falsified by the census — those are SURFACES/planes, different role; the
   spreadsheet has its own virtualized scrolling; the desktop's corner-pinned children are
   viewport-anchored by design.
5. **Reusing "Frame" in any new name** — collision with `FrameWdgt` (the window).
6. **Transform-island scrolling** (scroll offset as a clamped translation à la UIScrollView's
   `bounds.origin`, eliminating the moved-plane): the only route to "scrolling as a property of
   every panel", genuinely attractive, and genuinely a separate large arc (hit-testing, damage,
   island buffer cache, two-vocabulary law, fixed-vs-scrolled children). BACKLOG, not here.
7. **`nil`/alias absence values, new Widget.prototype members, `@param` constructor traps** —
   standing codebase laws; the new classes must pass the widget-authoring checklist.

## §8 References

- In-repo docs: `docs/architecture/widget-authoring-guidelines.md`,
  `docs/architecture/layout.md`, `docs/architecture/lint-and-static-checks.md`,
  `docs/architecture/appearance-paint-convention.md`,
  `docs/architecture/constructor-and-parameter-conventions.md`,
  `docs/architecture/serialization-duplication-reference.md`,
  `docs/archive/proper-layouts-4.2-structural-arrange-plan.md` (Stage-C probe method),
  `docs/archive/sizing-model-unification-plan.md` (the implementsDeferredLayout pin).
- Memory notes (`~/.claude/projects/-Users-davidedellacasa-code-Fizzygum-all/memory/`):
  `popup-overflow-scroll-arc.md` (the sandwich + RECALC case law),
  `connector-p8-scroll-tracking.md` (the funnel/announce contract),
  `graph-edges-design-stage-and-topic3-census.md` (mixin-twice boot guard),
  `constructor-parameter-conformance-arc.md` (method-header gate blindness),
  `macro-test-relocation-gotchas.md` + `fizzygum-macro-test-system.md` (test authoring).
- Source anchors (re-grep, don't trust lines): `PanelWdgt.coffee` (ctor, setColor,
  `_amITheContentsPanelOfAScrollPanelWdgt`, the relays), `ScrollPanelWdgt.coffee`
  (`_buildScrollFrameNoSettle`, `_reLayoutScrollbars`, `_positionAndResizeChildren`, `wheel`,
  `mouseDownLeft`, `pins`), `PopUpWdgt.coffee` (`_buildRowsScrollFrameNoSettle`),
  `Widget.coffee` (`_amIDirectlyInsideScrollPanelWdgt`, `grabsToParentWhenDragged`,
  `hierarchyMenuWidgets`, the `childrenCanLockToMe` consumer).

## §9 Start prompt for a fresh session

> Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` to orient. Then open
> `Fizzygum/docs/plans/scroll-frame-role-architecture-plan.md` and read it in full — it is
> self-contained. Follow its §0.5 cold-execution protocol: do the Phase 0 re-verification pass
> first (read-only greps; weave any drift back into the plan), then execute Phase 1 (the
> `scrollPolicy` feature) through its gates. Phases are strictly ordered; each ends with
> `fg presuite` + `fg gauntlet` and a proposed commit — ask the owner before every commit/push,
> and stop for the owner decisions the plan marks OWNER-GATED (Phase 2 product/icon choice,
> Phase 6 rename).
