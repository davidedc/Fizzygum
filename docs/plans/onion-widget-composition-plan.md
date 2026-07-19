# The Frame model — naked capability → manipulable citizen → App

**STATUS: AUTHORED 2026-07-18, REVISED 2026-07-18, RE-VERIFIED 2026-07-19. EXECUTING: Phase A ✅ COMPLETE
2026-07-19 (P0+A1 `03163312`/`c53055fd`, A2a `edd40eb1`, A2b `10aa3342`); §5.C execution design ADDED
2026-07-19 (toolbar substrate re-verified against src @ `10aa3342` — §3.4's A1-drifted names corrected);
Phase C ✅ COMPLETE 2026-07-19 (C1 `1e06b79f`, C2 `74322e1d`, C3 `3e8eecd6`, C4 `ab07bd95`, island fix
`58fa177e`, D6/D7/D8 lock `c4cd9d46`; guard test Fizzygum-tests `24bfa3882`); §5.B execution design ADDED
2026-07-19 (§3.3 substrate re-verified against src @ `c4cd9d46` — verified deltas recorded in §3.3a).
Owner-gated execution.**
This revision **supersedes** the earlier "three-ring onion" framing of this file: the middle "editor
panel" ring is dissolved (the toolbar is a *slot inside the frame*, not a ring), and the naming/structure
below were settled with the owner in a design dialogue on 2026-07-18. Class names verified against the
working tree on 2026-07-18 and **re-verified 2026-07-19 against src @ `72560224`** (after the
container-regularization §5.2e + menu-row-conformance arcs landed): every §3 citation still holds; the
only weave-in was the precise stack-inheritance inventory in §3.1. Anchor on **symbol names**, not line
numbers.

Self-contained: embeds the load-bearing current-state facts so it runs cold. Part of one program with
[`container-regularization-plan.md`](container-regularization-plan.md) (**✅ COMPLETE 2026-07-19**, incl.
its [`menu-row-conformance-plan.md`](menu-row-conformance-plan.md) follow-on — the menu system is now a
genuine stack client),
[`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md),
[`creation-and-templates-plan.md`](creation-and-templates-plan.md), and
[`reference-widgets-plan.md`](reference-widgets-plan.md). Shared north star: orthogonalisation,
de-byzantination, regularity — **the name encodes the role.**

---

## 1. The model

Two kinds of thing, plus one wrapper, plus one shared tool:

- **Naked capability — `Simple*Wdgt`.** Holds data + a self-mutation **API**, no chrome. A *payload*, not
  (in general) a free-standing citizen. E.g. `SimpleTextWdgt`, `SimpleImageWdgt`, `SimpleSpreadsheetWdgt`.
- **Manipulable citizen — a plain-named `*Wdgt`.** A first-class thing you can directly edit, move, resize,
  remove. Some are naked; some are framed (below).
- **The frame — `FrameWdgt`.** The wrapper that gives a payload its manipulation chrome (a bar with
  title / close / collapse / **pencil-eye edit toggle** / resize, plus a content-container that also holds
  a toolbar). `FrameWdgt` has **two skins, derived from context** (parentage): **window** (external,
  obtrusive) and **card** (internal, unobtrusive). This is the class today called `WindowWdgt` — renamed
  because "window" wrongly implies external-only.
- **The toolbar — `ToolbarWdgt`.** The shared, duck-typed, dockable strip of edit buttons. It lives in the
  frame's **toolbar-slot** (top or side), which is present in *both* view and edit mode so flipping the
  pencil never reshuffles the tree. It can also float, and any toolbar can act on any focused widget.

```
   ┌─ FrameWdgt  (skin = window | card; bar: title/close/collapse/pencil-eye/resize) ────────
   │   content-container (stable across modes)
   │     ├─ toolbar-slot ── a ToolbarWdgt when editing (empty/idle when viewing)
   │     └─ payload ─────── a Simple*Wdgt (or a flow of them)
   └──────────────────────────────────────────────────────────────────────────────────────
```

(⚠ The "content-container" is a REGION of the frame's body, not a widget: the §5.C design rules out a
physical intermediate child — the toolbar is a stable direct frame child and the payload stays `@contents`
— see §5.C C-ii for the §5.2d-case-law argument.)

### 1.1 The keystone principle — framing is INTRINSIC to the content type

> **Does the content's naked (`Simple*`) form already afford its own direct manipulation — edit, move,
> remove (and resize where meaningful)?**
> - **Yes** → it is a *naked* citizen **everywhere** (its `Simple*` form *is* the plain-named citizen).
> - **No** → it is a *framed* citizen **everywhere** (the plain-named `*Wdgt` = a `FrameWdgt` subclass
>   wrapping the `Simple*` payload).

This is settled **per content type**, not per context — because Fizzygum is a **direct-manipulation
system**: a thing must be editable *wherever it sits*, so editability (and therefore whether it needs a
frame) **cannot depend on where it was dropped**. Worked examples:

- **Text** — click gives a caret, it reflows (no resize needed), you drag it to move. Its naked form is
  self-manipulable ⇒ **naked everywhere**. A title in a document is just a `SimpleTextWdgt` used plainly
  (role name `TitleWdgt`); it needs no frame.
- **Image** — you cannot paint or resize a bare bitmap. Its naked form is *not* self-manipulable ⇒
  **framed everywhere**. In a document, on a slide, on the desktop, an image is an `ImageWdgt` (frame)
  around a `SimpleImageWdgt` (payload). Only its *placement* varies by context, never its frame.

Two consequences worth stating:
- **"Plain name" means "manipulable citizen", NOT "framed."** `TitleWdgt` is plain + naked; `ImageWdgt`
  is plain + framed. Both are correct.
- **Intrinsic vs contextual split:** *whether a frame exists at all* is **intrinsic** to the content type;
  *how an existing frame is skinned* (window vs card) is **contextual** (derived from parentage — exactly
  as `WindowWdgt.isInternal()` already does).

> **Rejected alternative (do not revive): "frame-on-demand."** An earlier draft let a container *supply*
> a payload's manipulation so the payload could shed its frame in context. This is **wrong for a
> direct-manipulation system** — a container cannot hand an image its paint/resize affordance, so the
> image must always carry its own frame. Framing is fixed by the content type. (Owner ruling, 2026-07-18.)

### 1.2 The pencil/eye toggle

The **edit-mode toggle** splits into an icon and a function, and neither moves with the toolbar question:
- **function** (enter/exit edit mode) = a **capability of the content** (`editButtonPressedFromWindowBar` →
  `enable/disableDragsDropsAndEditing` today);
- **icon** = a button on the **frame's bar** (today `WindowWdgt.editButton`, created iff
  `contents.providesAmenitiesForEditing`).
Pressing it makes a `ToolbarWdgt` appear in the frame's toolbar-slot (docked top/side), of the type
matching the content (text toolbar for text, paint toolbar for an image). A naked self-manipulable citizen
(a title) needs no pencil — you just click and type.

### 1.3 An App is a launcher, not a ring

An **App** = a launcher/**Factory** that opens an **empty framed `*Wdgt` in edit mode** (e.g. "Docs" opens
an empty `DocumentWdgt` with the text toolbar showing). It is *not* a widget layer. Creation/Factory is its
own arc — [`creation-and-templates-plan.md`](creation-and-templates-plan.md).

---

## 2. Provenance (the source notes, 2015–2020)

The design lived in a linked note cluster (Evernote-era; framework then "zombie kernel", widgets "morphs"):
*The way objects carry with them editing capabilities…* (Simple objects hold data + edit API, editing UI is
external); *Widgets should not be presented with an embedded editing toolbar…* (embedded toolbars compose
poorly as cards); *Naming structure of Apps/windows/className of widget inside* (the regular `Simple*`
vocabulary); *Paint program + "Image" widget should use the same editing pattern as Text editor + Text
widget* (paint like text; tool-heads like the caret — folded into §5.D); *Overview on windows* (a window's
main content morph "determines the icon in the references"; the up-triangle "minimises to a bar"); *scan
through all the info windows…* and *why do the info widgets extend simple document?* (a uniform contents
protocol; read-only-ness shouldn't be an inheritance). The *Tiles* and *Cassowary/VFL* notes are
**self-superseded dead-ends** — today's hug/grow/settle engine is the chosen descendant; not revived.

---

## 3. Current-state truth (verified 2026-07-18) — mapped onto the target model

All paths under `Fizzygum/src/`. This is the substrate the migration transforms.

### 3.1 The frame — today's `WindowWdgt` → target `FrameWdgt`
- `WindowWdgt` (`WindowWdgt.coffee`) owns `label`, `closeButton`, the collapse/uncollapse switch, an
  `editButton` (pencil/eye) **iff `@contents.providesAmenitiesForEditing`**, the `resizer`, and exactly
  **one** `contents` widget (laid out by `WindowContentLayoutSpec`). `isInternal()` is **derived from
  parentage**; the window/card skin is re-derived on every reparent (the old manual "make internal" toggle
  is already gone). `representativeIcon()` returns **the content's** icon.
- `WorldWdgt.openFrameWith(contentWidget, extent, position)` is the single fresh-frame wrap (A1 name).
- **⚠ Mis-inheritance to fix:** `WindowWdgt extends SimpleVerticalStackPanelWdgt` — its own header calls
  the extension "misleading." A frame *has* a bar + a content-container; it is not *a* vertical stack.
  `FrameWdgt` should **compose** those, not inherit a stack (composition-over-inheritance; §5.A).
  **The exact inherited surface (re-verified 2026-07-19) the de-inherit must reproduce or consciously
  replace:**
  - **Rides from the stack (FULL inventory, re-verified against the stack source pre-A2):**
    `@augmentWith ClippingAtRectangularBoundsMixin` (frames CLIP at bounds, and the mixin's
    `_applyMoveTo` scroll-optimization override is the frame's repaint path when a parent stack moves
    it); class default `_acceptsDrops: true` (Widget's is **false** — a fresh empty frame accepts
    drops through this); `releasesRatioConstraintOnGrabbedChildren -> true` (the ratio mixin queries
    the HOLDER via `?()` on grab-out — undefined would silently stop releasing);
    `add`/`_addNoSettle` (the frame's own `_addNoSettle` supers through the stack's core, which runs
    `aWdgt._resizeToWithoutSpacing()` on every add; the positionOnScreen sibling-insert logic is dead
    for frames — the frame's wrapper never forwards it); the membership-refit pair
    `_reactToChildRemoved`/`_reactToChildDropped` (`return if
    @parent?._reLayOutAfterContainedPanelChange?(); @_reFitContainer()` — Widget has NO base def; the
    frame's own `_reactToChildDropped` reaches it via bare `super`); `_reLayoutChildren`
    (= `@_positionAndResizeChildren()`, dispatching back into the frame's override — the
    size-tracking marker); `_reLayout` (= `super; @_reLayoutChildren(); @_reLayoutCornerInternalChildren()`);
    `implementsDeferredLayout` **pinned false**; `initialiseDefaultFrameContentLayoutSpec`
    (= `super` + `canSetHeightFreely = false` — matters when a frame is another frame's content);
    `availableWidthForContents` (**consumed by the specs**: `FrameContentLayoutSpec`/`VerticalStackLayoutSpec`
    call `@stack.availableWidthForContents()`, and for frame content `@stack` IS the frame).
  - **Inherited but DEAD for frames (verified):** the stack walkers — base `preferredExtentForWidth`,
    `subWidgetsMergedPreferredBounds`, the `_childWidthInStack`/`_childLeftInStack`/
    `_childMeasuredExtentInStack` trio, `interElementGap`, `constrainContentWidth`, the stack arrange —
    their only external consumer is `ScrollPanelWdgt` on its `@contents`, guarded by
    `instanceof SimpleVerticalStackPanelWdgt`, and a frame is never a scroll panel's contents. The
    frame overrides the arrange and both its own measures. (The 3 `instanceof
    SimpleVerticalStackPanelWdgt` sites are all scroll-contents guards — de-inheriting flips no live
    answer.)
  - **Fully overridden, so inert for windows:** `_positionAndResizeChildren` (the window's own arrange),
    `preferredExtentForWidth` + `preferredExtent` (the window's own §4.1 pure measures). This is why the
    stack base's post-authoring conformance-arc additions (`interElementGap()`, the base
    `preferredExtentForWidth`) change nothing for windows — they are consumed only by the stack walkers
    the window overrides.
  - **Ctor quirk:** `super nil, nil, 40, true` hands the stack `padding = 40`, immediately overwritten by
    `@padding = 5` — the super args are effectively noise; only `@constrainContentWidth = true` survives.
  - **Contrast (worked precedent):** `MenuRowsPanelWdgt` (container arc §5.2e, landed 2026-07-19) is what
    a *genuine* stack client looks like — it keeps the stack's arrange/measures and overrides only the
    small policy hooks (`interElementGap`, `_childWidthInStack`, hug width). `WindowWdgt` overrides the
    arrange and measures wholesale — the inheritance buys it only the tracking/deferral plumbing, which is
    exactly the part composition can supply.

### 3.2 The "frame + toolbar-slot" pattern already exists (as `StretchableEditableWdgt`)
`StretchableEditableWdgt` (`StretchableEditableWdgt.coffee`, "Generic panel") composes a
`StretchableWidgetContainerWdgt` + an optional `toolsPanel` + the enable/disable-editing machinery, and is
the shared base of `SimpleSlideWdgt`, `DashboardsWdgt`, `ReconfigurablePaintWdgt`, `PatchProgrammingWdgt`.
**This is a proto-`FrameWdgt`-with-toolbar-slot** — the target generalizes it up into `FrameWdgt` and makes
documents/images follow it too, *removing* today's split-brain where `SimpleDocumentWdgt` and
`StretchableEditableWdgt` each roll their own frame+toolbar.

### 3.3 Content widgets today → naked payload vs framed citizen
Today the app "content" classes **fuse** payload + frame + toolbar. The target splits them:

| Content | Naked form self-manipulable? | Today | Target |
|---|---|---|---|
| Text (paragraph/title) | **Yes** | `StringWdgt → TextWdgt → SimplePlainTextWdgt` | naked `SimpleTextWdgt` (role `TitleWdgt`); no frame |
| Document (text flow + toolbar + scroll) | n/a (a document *is* the apparatus) | `SimpleDocumentWdgt` (`apps/`, builds its own toolbar) | framed **`DocumentWdgt`** `extends FrameWdgt`, payload = a flow of `SimpleTextWdgt`/`TitleWdgt`/`ImageWdgt` |
| Image | **No** | `RasterImageWdgt` (`basic-widgets/`, `CanvasWdgt`) — the bitmap | naked `SimpleImageWdgt` payload + framed **`ImageWdgt`** `extends FrameWdgt` |
| Slide | **No** | `SimpleSlideWdgt` (`StretchableEditableWdgt`) | framed **`SlideWdgt`** `extends FrameWdgt` |
| Dashboard | **No** | `DashboardsWdgt` (`StretchableEditableWdgt`) | framed **`DashboardWdgt`** |
| Paint surface | **No** | `ReconfigurablePaintWdgt` (`StretchableEditableWdgt`) + `StretchableCanvasWdgt` | framed **`ImageWdgt`** in edit mode with the paint `ToolbarWdgt` (paint = image editing; §5.D) |
| Spreadsheet | **No** | `SpreadsheetWdgt` (`spreadsheet/`) | framed **`SpreadsheetWdgt`** `extends FrameWdgt` (payload = the cell grid) |

### 3.3a Substrate deltas found by the §5.B re-verification (2026-07-19, src @ `c4cd9d46`)
The table above was written before phases A+C landed and before the deep per-type audit. Facts that
CHANGE how B lands (each woven into the §5.B design):
- **Image barely exists as content.** `RasterImageWdgt` has exactly ONE construction site in all of src:
  `SimpleRasterImageButtonWdgt` uses it as a button FACE. No user flow places a raster image into a
  document/desktop today (test repo: zero references). So "framed `ImageWdgt`" is NEW functionality, not a
  split of an existing fusion — B renames the payload (`SimpleImageWdgt`) and DEFERS the framed citizen to
  phase D, where its consumer (paint-as-image-editing) arrives (structure-without-a-consumer, §5.C case law).
- **The spreadsheet is ALREADY split.** `SpreadsheetWdgt extends Widget` is the naked grid (nil appearance,
  hand-rolled row/col-quantized scroll, no toolbar); the window wrap happens at `SpreadsheetApp`'s
  `openFrameWith`. B's job there is only names + a thin citizen: grid → `SimpleSpreadsheetWdgt`, citizen
  `SpreadsheetWdgt extends FrameWdgt` (D2 locks that name for the citizen).
- **The info-widgets are factories, not real subtypes.** All 10 `extends SimpleDocumentWdgt` only to host a
  static `@createNextTo`/`@create` that builds a PLAIN `new SimpleDocumentWdgt` (sole exception:
  `ReconfigurablePaintInfoWdgt` does `new @`) and hand-wraps it in a `FrameWdgt` via the shared
  `_buildInfoDocNextTo`. No ctor content, no overrides. The E-phase readOnly question is therefore mostly
  moot already; B just re-points the factories at the citizen.
- **The citizen shape already exists in-tree:** `FolderWindowWdgt extends FrameWdgt` builds its own payload
  in its ctor (`@contents = new ScrollPanelWdgt new FolderPanelWdgt; super @contents, …`), overrides
  `representativeIcon` and `closeFromFrameBar` (incl. `new SaveShortcutPromptWdgt @, @` — both args the
  frame itself, proving that prompt handles content == window). (`TemplatesWindowWdgt` is NOT a second
  precedent: despite `extends FrameWdgt` its `@create` returns a plain `new FrameWdgt sdspw` — a
  namespace-only class.)
- **Hierarchy-menu labels derive from the CLASS name** (`toString` → `"a " + constructor.name`, `Wdgt`
  stripped at the drawing sites), NOT from `colloquialName` — so every B rename moves label text AND the
  menu's hugged width (A1 case law). Measured test-repo exposure, per rename: `SimplePlainTextWdgt`
  identifier in 33 test dirs (207 hits) + label `"a SimplePlainText"` in 17 dirs (65 hits);
  `SimpleDocumentScrollPanelWdgt` identifier in 43 files + label in 29 files (why B does NOT rename it —
  §5.B B-ii); `SpreadsheetWdgt` identifier in 36 files, label `"a Spreadsheet"` in 1 dir;
  `SimpleDocumentWdgt` identifier in 6 files; `SimpleSlideWdgt` 1 file; `DashboardsWdgt`/
  `PatchProgrammingWdgt`/`RasterImageWdgt` 0 files; `StretchableEditableWdgt` 2 files (label in 2 dirs).
- **D8 is already implemented by the existing machinery:** `Widget._disableDragsDropsAndEditingNoSettle`
  walks the content's children setting `isEditable = false` (and tears down a caret targeting them), and
  `StringWdgt.mouseClickLeft` gates `@edit()` on `@isEditable` (else escalates). View mode already summons
  no caret. B PRESERVES this path; no new mechanism is needed.

### 3.4 The external-toolbar editing model already exists (for text)
- **Focus pointer:** `WorldWdgt.lastNonTextPropertyChangerButtonClickedOrDropped`, set on every content
  click/drop by `ActivePointerWdgt`, reset on stop-editing. Toolbar buttons + `excludedFromLastFocusTracking`
  opt-outs don't steal it.
- **External buttons:** the `EditorContentPropertyChangerButtonWdgt` family (`buttons/`, `extends IconWdgt`)
  — Bold/Italic/FormatAsCode/ChangeFont/±FontSize/Align — each `mouseClickLeft` feature-tests then calls the
  content API (`toggleWeight`/`setFontName`/`alignLeft`…) on the focus pointer.
- **Floating toolbar:** `ToolbarCreatorButtonWdgt._buildToolWindow` builds a standalone `FrameWdgt` of
  buttons (each creator hand-builds a `ScrollPanelWdgt(new ToolPanelWdgt)` and fills it);
  `TextToolbarCreatorButtonWdgt` fills the text one; **`ToolbarsApp`** is the "Super Toolbar" (a palette
  of the six creator buttons, itself a hand-built ScrollPanel(ToolPanel) wrapped via `openFrameWith`).
- **Embedded toolbar (the duplication to fix — full five-site inventory, re-verified 2026-07-19):**
  every editor owns a `toolsPanel` built by a `_createToolsPanelNoSettle` core — `SimpleDocumentWdgt`
  (a `HorizontalMenuPanelWdgt` strip of the 9 text buttons + `TemplatesButtonWdgt`, docked top, height
  35), `DashboardsWdgt` (ScrollPanel(ToolPanel) of 18 creators/icons, docked left, width 95),
  `PatchProgrammingWdgt` (ScrollPanel(ToolPanel) of 5 node creators, left/95),
  `SimpleSlideWdgt` (`new SlidesToolPanelWdgt` — the ONE already-extracted shared palette class, also
  consumed by `SlidesToolbarCreatorButtonWdgt`; the §5.C precedent), `ReconfigurablePaintWdgt`
  (a `RadioButtonsHolderWdgt` of 4 code-injecting tool toggles bound to `@overlayCanvas` — §3.5, phase
  D's target, NOT a duplicated construction). The base `StretchableEditableWdgt._createToolsPanelNoSettle`
  is empty; its `_reLayoutSelf` carries the shared left-dock arms.
- **Editing is a capability:** `providesAmenitiesForEditing`, `enable/disableDragsDropsAndEditing`,
  `editButtonPressedFromFrameBar` (A1 name; hoisted to the Widget BASE — the three editor classes
  shared it verbatim), `showEditModeInBar`/`showViewModeInBar`,
  `coordinatesDragsDropsAndEditingForChildren`.

### 3.5 The caret + the paint gap (feeds §5.D)
- **Caret:** `CaretWdgt` (`basic-widgets/CaretWdgt.coffee`, `extends BlinkerWdgt`) is a **single world-level
  overlay** (`world.caret`) re-pointed at whatever text is being edited (`world.edit`/`stopEditing`, sole
  member of `world.keyboardEventsReceivers`); `isLayoutInert`, excluded from bounds/hit-test.
- **Paint is NOT on the focus model:** `ReconfigurablePaintWdgt._createToolsPanelNoSettle` binds
  `CodeInjectingSimpleRectangularButtonWdgt`s to **this app's own `@overlayCanvas`** at construction; the
  tools can't act on an arbitrary focused image. The API to fix it exists (`CanvasWdgt.acceptsPenDrawing()`,
  `StretchableCanvasWdgt.getContextForPainting()`), and the focus pointer already tracks dropped/clicked
  images — only the external wiring is missing.

### 3.6 App/launcher
`IconicDesktopSystemWindowedApp` (plain factory) + 14 `*App` subclasses; `buildWindow` calls
`world.openWindowWith(content, …)`. The on-screen app = a `WindowWdgt` wrapping content. (Creation unified
in [`creation-and-templates-plan.md`](creation-and-templates-plan.md).)

---

## 4. Architecture we MUST respect

From `docs/architecture/{layering-naming-convention,layout,transforms,lint-and-static-checks}.md`,
condensed to what this arc touches:
- **Naming/tiers.** Public `name` / `_name` orchestrator / `__name` leaf (rule [I]). New classes `*Wdgt`,
  one class per file, filename == class name; reference by literal `extends X`/`new X`/`@augmentWith X`.
- **⚠ apply-2×2 meaning-swap:** bare `_applyExtent`/`_applyMoveBy`/`_applyMoveTo` are the **polymorphic**
  corners; `*Base` are the override-bypass twins.
- **Notification grid.** Structural events use `(event × perspective × phase)` hooks; a callback is
  settle-neutral (rule [J]); the dispatcher owns the one settle.
- **Settle discipline.** Public mutators `foo: -> @_settleLayoutsAfter => @_fooNoSettle …`; internal
  callers use the core; off-settle handlers **record** via `_invalidateLayout`. Constructors must NOT build
  children inline (`check-constructors-build.js`) — child-building lives in
  `_buildAndConnectChildrenNoSettle` via `@_buildAndConnectChildren()`.
- **Containers.** A size-tracking container defines `_reLayoutChildren` (the re-fit up-edge marker); arrange
  must be **idempotent** (`fg census`/`fg revisits` = 0) and **apply its own bounds first**
  (`check-relayout-bounds-first.js`); no mutate-then-read-back (pure `preferredExtentForWidth`); no manual
  up-notify (`_announce*ToContainer` is deleted, banned by rule [N]). **The toolbar-slot must be a stable
  child present in both modes** (show/hide, not add/remove) so mode-flip doesn't churn the tree.
- **Transforms.** Layout/content code uses the **layout-box** family only; `screen*` names for
  hit-test/damage/paint (two-vocabulary law). Reparent/duplicate take `_enclosingIslandFigure()`.
- **Integer placement** enforced (`NON_INTEGER_GEOMETRY` fails the suite).

---

## 5. The work

**Correctness-first (owner, 2026-07-18):** recapture/serialization/rename churn is **not** a reason to
defer or compromise the target. Phasing below exists **only for verifiability** (prove a shape, then apply
it in batches you can bisect) — never to dodge the right change.

### A. `WindowWdgt` → `FrameWdgt` (rename + de-inherit)
Rename `WindowWdgt` to `FrameWdgt`; stop inheriting `SimpleVerticalStackPanelWdgt`; **compose** the bar +
content-container (with a stable toolbar-slot) instead. Keep the window/card skin derivation (`isInternal`)
and `representativeIcon = content's icon`. `openWindowWith` → a `FrameWdgt` wrap. This is a central,
serialized, colloquial-name-drawn class → recapture expected and accepted.

**A1 (rename sweep) — ✅ LANDED 2026-07-19.** The class family (`WindowWdgt`→`FrameWdgt`,
`WindowContentLayoutSpec`→`FrameContentLayoutSpec`, `WindowContentsPlaceholderText`→
`FrameContentsPlaceholderText`, files `git mv`'d) plus the whole window-named frame protocol
(`isFrame`, `openFrameWith`, `initialiseDefaultFrameContentLayoutSpec`, `ATTACHEDAS_FRAME_CONTENT`,
`editButtonPressedFromFrameBar`, `closeFromFrameBar`, `closeFromContainerFrame` — incl. its
string-dispatched button action in `ErrorsLogViewerWdgt` — `specialFrameReferenceShortcut`,
`_reactToHolderFrameDropped/Grabbed`), swept 1:1 across src (137 refs), the tests repo (348 refs), and
the layering gate's callback grammar (`(Being|Child|HolderWindow)`→`HolderFrame` — the gate encodes the
convention and caught its own coupling on the first build). **Deliberately NOT renamed:** user-facing
"window"/"internal window" strings (skin vocabulary — stays until the card-skin work); the window-skin
subclasses/creators (`TemplatesWindowWdgt`, `FolderWindowWdgt`, `*WindowCreatorButton*`, icon
appearances — Phase B/C); the `buildWindow` app hook (creation arc). Churn (all owner-eyeballed):
3 tests recaptured — 2 inspector tests (the clock's method list draws the renamed
`initialiseDefault…` name) + `macroDuplicateComplexWidgetRidesHand` (the duplicated window rides the
hand 5px left: the hierarchy menu hugs its widest entry, and "a Frame ▸" is narrower than
"a Window ▸", so the duplicate-click lands left — MEASURED pure translation dx=−5 dy=0, residual
133/130500). **⚠ Case law for phases B/C (mass class renames): class-derived MENU LABELS are consumed
by macro LOOKUP STRINGS too** — 3 duplication macros navigated the hierarchy menu by the literal
prefix `"a Window"` and crashed (`undefined.x` in moveToAndClick) until the strings followed the
label; a rename sweep must also grep the tests repo for `"a <OldClass-sans-Wdgt>"` label prefixes.
(Tooling gotcha, same session: `fg recapture` takes ONE test name and silently ignores extras —
recapture serially, one name per invocation, until fg grows an arg loop/guard.)
**Remaining in A: A2 = de-inherit + compose, against the §3.1 inventory — split for verifiability:**
- **A2a — de-inherit by explicit contract (ambition: byte-identical).** `class FrameWdgt extends Widget`
  + reproduce ONLY the live inventory (§3.1): the clipping augment, `_acceptsDrops: true`,
  `releasesRatioConstraintOnGrabbedChildren`, `_resizeToWithoutSpacing()` at the top of the frame's
  `_addNoSettle`, the membership-refit pair inlined (the bare `super` in the frame's
  `_reactToChildDropped` must become the absorb-or-refit body — Widget has no base), stack-pattern
  `_reLayoutChildren`/`_reLayout`/`implementsDeferredLayout false`,
  `initialiseDefaultFrameContentLayoutSpec`, `availableWidthForContents`. Ctor `super nil, nil, 40, true`
  → `super()` (the stack ctor's appearance/padding writes were overwritten by the frame ctor anyway).
  The dead stack walkers fall back to Widget's base. Gates: build + presuite, then full gauntlet;
  revisits/census must stay at their zero baselines (the frame keeps the exact same tracking/deferral
  answers). Serialization shape: windows stop carrying `constrainContentWidth` — accepted, no compat
  obligations. **✅ LANDED 2026-07-19 — byte-identical confirmed: gauntlet 11/11, zero recaptures,
  revisits/census at zero.** (Execution note: the stinks gate rejects history-narrating comments
  ("used to"/"no longer") — write de-inherit why-comments present-tense.)
- **A2b — compose the BAR (`FrameBarWdgt`); the content-container + toolbar-slot land WITH phase C.**
  Decomposition refined after a full seam audit (2026-07-19): the content-container's real jobs — the
  toolbar-slot's occupant and the drags/drops/editing coordination folded up from
  `StretchableEditableWdgt` — both arrive in C/B, so inserting an empty container now would be
  structure-without-a-consumer AND a §5.2d-class parent-chain break (drop targets, content lifecycle
  hooks, spec binding) paid twice. The BAR, by contrast, has its consumer today: one child that owns
  the five title-strip pieces and the window/card skin's title half.
  **Seam audit verdict (the migration's full break-list — everything else is field-reads):**
  - NO positional `children[N]` indexing of a window's chrome exists anywhere, src or tests; every
    external reach (MacroToolkit + ~20 macros) is `win.<field>` → **keep `label`/`closeButton`/
    `editButton`/`collapseUncollapseSwitchButton`/`titlebarBackground` as ALIAS fields on the frame**,
    synced at the three mutation points (build, edit-button destroy on collapse, recreate on
    uncollapse).
  - **Press seams** (the icon-button family deliberately targets ITSELF and asks `@parent` at press
    time — ctor comment in `IconButtonWdgt`): `CloseIconButtonWdgt` asks
    `@parent.closeButtonInBarPressed?()` (else `.close()`); `EditIconButtonWdgt` asks
    `@parent.editButtonInBarPressed?()`; `Collapse/UncollapseIconButtonWdgt` hard-code
    `@parent.parent.contents.collapse()/unCollapse()` (2-hop, window-bar-only constructions). Fix:
    the BAR answers the four-message protocol and forwards to its frame; the frame keeps
    `close/editButtonInBarPressed` and gains `collapse/uncollapseButtonInBarPressed`
    (`-> @contents.collapse()/unCollapse()` — the frame owns what its bar buttons mean); the two
    collapse buttons change to `@parent.parent.<x>ButtonInBarPressed?()` (parent.parent = the bar).
    Non-bar `CloseIconButtonWdgt` uses (PointerWdgt, MenusHelper) keep the `.close()` fallback.
  - **⚠ Drag-by-titlebar constraint:** the grab climb (`findFirstLooseWidget`) stops at a child whose
    parent is a `PanelWdgt` — so `FrameBarWdgt` MUST be a plain non-`PanelWdgt` `Widget` with
    `grabsToParentWhenDragged()` true (the inherited default), or dragging by label /
    titlebarBackground grabs the label instead of the window.
  - The resizer stays a direct frame child (`@target` add-bound). Button colors are all
    self-contained (no parent skin reads). Content→frame protocol (`showEditModeInBar` etc.) reads
    the frame's alias — unaffected.
  **Shape:** `FrameBarWdgt extends Widget`, appearance-less (titlebarBackground draws; explicit-opaque
  default makes the strip a hit-target whose clicks escalate to the frame), holds a bound `@frame`,
  owns piece construction (`_buildAndConnectPiecesNoSettle`, honoring a caller-supplied closeButton —
  FolderWindowWdgt), the strip arrange (the block moved out of the frame's
  `_positionAndResizeChildren`: background inset (1,1)/(−2,−2), close at padding, switch at
  icon+2·padding, label between, edit rightmost with the narrow-width collapse rule), and the
  title-half skin (`_setAppearanceAndColorOfTitleBackground`, `_buildTitlebarBackground`).
  Stack-pattern `_reLayout` (= super + arrange) + `implementsDeferredLayout` pinned false, driven
  synchronously by the frame's arrange as `@bar._reLayout barBounds` (barBounds = top strip at
  `_titlebarHeight()`), exactly as the frame drives its buttons' `_reLayout` today. Paint/hit order
  preserved (bar first, then contents, then resizer). Measure (`_titlebarHeight`/`_chromeHeight`)
  stays on the frame. Serialization: the new child serializes structurally; no compat obligations.
  **Ambition: byte-identical** (same absolute pixel placement, bar draws nothing); gates = presuite,
  then full gauntlet with revisits/census at zero.
  **Two seam finds from execution (both fixed with existing case-law shapes):**
  1. **The bar must be `isTransparentAt -> true`** (the §5.6 Menu/Prompt pattern, NOT an opaque
     hit-target as first designed): an appearance-less opaque bar covers the frame's transparent
     rounded-corner notches, intercepting hits the frame's own appearance reports transparent —
     caught by `macroDesktopShortcutIcons`, whose folder window spawns at the click point and whose
     shortcut icon then wrongly lost its pointer-under (pressed) state. Transparent-everywhere
     restores the exact pre-bar hit surface (pieces opaque, border → frame body, notch → behind).
  2. **The bar must answer `hiddenFromHierarchyMenu -> true`** — the right-click
     hierarchy/disambiguation menu lists the clicked widget's ancestor chain, and the bar would
     appear as a new "a title bar ➜" row (shifting every row below, and re-aiming macros that
     navigate by row position). The exclusion hook already exists for `MenuRowsPanelWdgt`
     (Widget.getHierarchyMenuWidgets): internal structure is not a user-facing target.
  **✅ A2b LANDED 2026-07-19 — byte-identical confirmed: gauntlet 11/11, zero recaptures,
  revisits/census at zero. PHASE A COMPLETE (A1 rename + A2a de-inherit + A2b bar composition).
  NEXT: phase C (one ToolbarWdgt per content type + the toolbar-slot — execution design in §5.C; note the
  content-container was refined from a widget to a body REGION there, C-ii).**

### B. Split fused content classes into naked payload + framed citizen
Per §3.3: introduce `SimpleTextWdgt` (from `SimplePlainTextWdgt`; role `TitleWdgt`), `SimpleImageWdgt`
(from `RasterImageWdgt`), and the framed citizens `DocumentWdgt`/`ImageWdgt`/`SlideWdgt`/`DashboardWdgt`/
`SpreadsheetWdgt` (`extends FrameWdgt`, each thin — the frame does the chrome work). Fold
`StretchableEditableWdgt`'s container+toolsPanel role up into `FrameWdgt`. Apply the intrinsic-framing rule
(§1.1): text stays naked; everything needing a toolbar/handles becomes framed.

**EXECUTION DESIGN (2026-07-19; substrate re-verified against src @ `c4cd9d46` — the verified deltas are
§3.3a and are load-bearing here). The central discovery: the fused middle layers do not need to MOVE their
coordination machinery into the citizens — most of it DISSOLVES, because the protocols it relayed already
compose frame↔payload directly (evidence per seam in B-iii).**

**B-i. The citizen shape (the `FolderWindowWdgt` precedent, §3.3a) + the FrameWdgt substrate it needs.**
A citizen is a THIN `FrameWdgt` subclass: ctor builds its payload and hands it to `super` (the
`FolderWindowWdgt`/`ToolbarWdgt` sanctioned ctor shape), plus per-kind declarations only:
`providesAmenitiesForEditing: true` (class field), `buildToolbar` (its C-phase variant),
`colloquialName` (the kind name: "Docs Maker" etc. — window titles follow via the title hook below),
`representativeIcon` (the kind icon), `closeFromFrameBar` (the save-or-destroy policy, verbatim from the
old middle layer with `SaveShortcutPromptWdgt @, @` per the Folder precedent), and a
`_resetToDefaultContents` override that rebuilds ITS payload kind (a citizen never falls back to the
empty-window placeholder; this is also how the old `_reactToChildPickedUp` container-recreate behaviour
survives — `_beforeChildPickedUp` → reset → fresh payload). NO layout code (FrameWdgt's arrange/measures
are untouched — census safety), NO edit-mode state machine (B-iii).
`FrameWdgt` itself gains exactly FOUR small substrate changes (landing B1), each inert for plain frames:
1. **Edit-button gate consults the citizen too:** `_createAndAddEditButton`'s condition becomes
   `(@providesAmenitiesForEditing or @contents?.providesAmenitiesForEditing) and !@editButton?`. A plain
   `FrameWdgt` reads its own as undefined → falls to the content, byte-identical. (Needed because a
   slide/dashboard citizen's payload is `StretchableWidgetContainerWdgt extends Widget`, which does NOT
   provide amenities — §3.3a; the doc citizen's scroll-panel payload provides via `PanelWdgt`.)
2. **Toolbar declaration consults the citizen first:** the `_buildAndConnectChildrenNoSettle` dispatch
   becomes `@toolbar = @buildToolbar?() ? @contents?.buildToolbar?()` — the VARIANT is per-kind knowledge
   (the payloads are generic/shared), so it lives on the citizen; plain frames keep the content dispatch
   (windows wrapping legacy editors keep working mid-migration).
3. **Title derivation gets ONE hook:** `_titleForContents(aWdgt)` (base = today's inline
   `aWdgt.colloquialName()` + the two "window with an(other) …" special cases, extracted verbatim from the
   ctor and `_addNoSettle`); citizens override to `@colloquialName()` so a doc window titles "Docs Maker"
   from the citizen, not "document" from the payload.
4. **Frame-level enable/disable routes through the payload's own cores:**
   `_enable/_disableDragsDropsAndEditingNoSettle` overrides on FrameWdgt =
   `@contents?._<same>NoSettle @` then `@showEdit/ViewModeInBar()` (self — the frame IS the bar owner; the
   base Widget core would act SHALLOWLY on `@contents` and notify only `@parent`, leaving grandchildren
   unlocked and the own bar unflipped). Public callers like `DegreesConverterApp`'s build-time
   `disableDragsDropsAndEditing()` then work unchanged on a citizen. Frame-level enable/disable has no
   in-tree caller today (`_buildInfoDocNextTo` calls it on the CONTENT), so this is new-surface, not a
   behaviour change.
Also in B1: `WorldWdgt.openFrameWith` gains the isFrame passthrough —
`if contentWidget.isFrame?() then wm = contentWidget else wm = new FrameWdgt contentWidget` — so every
`openFrameWith new <Citizen>…` call site keeps its one-line shape. ⚠ All new classes go in EXISTING
shipped dirs (`src/apps/`, `src/spreadsheet/`) — no new `src/` dir, no `build.py` glob edit (C1 case law).

**B-ii. The per-type map (old → new).**
| Kind | Citizen (new) | Payload | Old fused class | Fate |
|---|---|---|---|---|
| Text | — (naked, §1.1) | `SimpleTextWdgt` ← rename of `SimplePlainTextWdgt`; `TitleWdgt` = thin subclass (D7) | — | pure rename + new role class |
| Document | `DocumentWdgt` | `SimpleDocumentScrollPanelWdgt` (name KEPT — below) | `SimpleDocumentWdgt` | DISSOLVES |
| Slide | `SlideWdgt` | `StretchableWidgetContainerWdgt` (name kept) | `SimpleSlideWdgt` | DISSOLVES |
| Dashboard | `DashboardWdgt` | same container | `DashboardsWdgt` | DISSOLVES |
| Patch | `PatchProgrammingWdgt` (name kept, re-based) | same container | itself | re-based |
| Generic panel | `GenericPanelWdgt` | same container | `StretchableEditableWdgt` (as a product) | base SHRINKS to paint's abstract parent |
| Paint | — (untouched in B) | — | `ReconfigurablePaintWdgt` | stays on the shrunken base until D |
| Image | DEFERRED to D (§3.3a) | `SimpleImageWdgt` ← rename of `RasterImageWdgt` | — | rename only |
| Spreadsheet | `SpreadsheetWdgt` (name MOVES to the citizen, D2) | `SimpleSpreadsheetWdgt` ← rename of the grid | — (already split, §3.3a) | rename + thin citizen |
- **The doc payload keeps the name `SimpleDocumentScrollPanelWdgt`** (owner-ratified option): it already
  wears the `Simple*` naked-capability prefix and is honest about what it is; renaming it (e.g. reusing the
  vacated `SimpleDocumentWdgt`) would churn 43 test files' fixtures + 29 files' label strings (§3.3a) for a
  purely cosmetic gain AND make the vacated name mean a different widget across one commit — the one rename
  this plan rejects on confusion (not churn) grounds.
- **`TitleWdgt`** = `class TitleWdgt extends SimpleTextWdgt` whose ctor bakes in the document-title style
  (centered, georgia stack, font size 48 — byte-what `TemplatesWindowWdgt.create`'s "Title" template sets
  inline today). First consumer: that template (drag-out then serialization/drop identity = "a Title",
  hierarchy label likewise). Other title-ish sites (the info-doc 22px titles) STAY `SimpleTextWdgt` in B —
  byte-parity; adopting `TitleWdgt` there would change their font.
- The `Simple*`-prefix misnomers die with the fusions: `SimpleSlideWdgt`/`SimpleDocumentWdgt` carried
  `Simple*` names while being fused editors — exactly what D6's vocabulary now forbids.

**B-iii. What DISSOLVES (with the composition evidence), vs what MOVES to the payload.**
- **Edit-mode coordination: DISSOLVES.** The chain today: pencil press → frame
  `editButtonInBarPressed` → `@contents.editButtonPressedFromFrameBar?()` → middle layer toggles itself →
  drives the real container's core → each core calls `@parent?.showEdit/ViewModeInBar?()`. With the middle
  gone, `@contents` IS the payload: the press reaches the payload's base-Widget
  `editButtonPressedFromFrameBar` (hoisted, §3.4), the payload's own core does the recursive
  propagation — `ScrollPanelWdgt`'s core notifies `@parent?.show*ModeInBar?()` (verified, ~:876/:892), as
  does `StretchableWidgetContainerWdgt`'s (~:189/:202) — and the parent is now the citizen frame. The
  citizen holds NO mode flag: the payload's `dragsDropsAndEditingEnabled` is canonical, and every frame
  read (`toolbar` born-collapsed, `_beforeChildUnCollapsed` restore, `_createAndAddEditButton` initial
  glyph) already reads `@contents.dragsDropsAndEditingEnabled`. The
  `SimpleVerticalStackScrollPanelWdgt`/container "bubble to coordinator" branches simply never fire (the
  frame declares no `coordinatesDragsDropsAndEditingForChildren`) and fall to their local-work `super` —
  which is exactly the right behaviour.
- **Ratio-keeping: MOVES to the container (two small hooks), the relay dies.** The middle layer's
  `KeepsRatioWhenInVerticalStackMixin` + `_constrainToRatio` + ratio-locked
  `_setWidthSizeHeightAccordingly`/`preferredExtentForWidth` were RELAYS of
  `StretchableWidgetContainerWdgt`'s own ratio machinery (the container already has the ratio-locked
  sizing + the pure measure — verified). The frame's existing arrange/measure recursion
  (`@contents._setWidthSizeHeightAccordingly` / `@contents.preferredExtentForWidth`) reaches the container
  directly. What the container LACKS is the two holder-frame hooks the mixin supplied to the middle layer:
  `_reactToHolderFrameDropped` (→ constrain: `canSetHeightFreely = false` + ratio resize, its own
  `setRatio`-style logic) and `_reactToHolderFrameGrabbed` (→ free + shrink-if-oversized, mirroring the
  mixin's `_freeFromRatioConstraints`). Hand-write those two on the container — do NOT augment the mixin
  there (it would clobber the container's own, better `_setWidthSizeHeightAccordingly`/
  `preferredExtentForWidth` pair).
- **Smart-place: MOVES to the payload.** The smart-placer routes
  `w.isFrame?() and w.contents?.acceptsSmartPlacedWidgets?()` → `w.contents.smartPlace` (§5.C C-ii) — with
  the middle gone, `w.contents` is the payload, so `acceptsSmartPlacedWidgets` (gated on own
  `dragsDropsAndEditingEnabled`) + `smartPlace` move verbatim: doc's (append + scrollToBottom) onto
  `SimpleDocumentScrollPanelWdgt`, the editors' (centre-drop) onto `StretchableWidgetContainerWdgt`.
- **Save-or-destroy close: MOVES to the citizen** (`closeFromFrameBar` override, B-i);
  `hasStartingContentBeenChangedByUser` moves WITH its data: the doc check (single starting paragraph)
  onto the scroll panel (citizen reads `@contents.hasStartingContentBeenChangedByUser()`), the editors'
  (`@contents.ratio?`) inlined in the citizen.
- **Starting-content seeding: stays in the CITIZEN** (`DocumentWdgt` builds the scroll panel AND seeds the
  editable starting paragraph, as the fused class did) — the scroll-panel class stays unseeded, so the 43
  test files constructing bare `SimpleDocumentScrollPanelWdgt` fixtures stay byte-identical.
- **`_reLayout`: DISSOLVES.** The middle layers' only remaining layout job post-C was "give my single child
  my full padded bounds" (doc externalPadding 0; editors likewise via `_reLayoutSelf`) — the frame's
  existing content arrange already does precisely that placement. Zero pixels move (the middle layers draw
  nothing, inset nothing); ambition byte-identical, VERIFIED not assumed (headless probe before/after per
  landing, no-conclusions-before-evidence).
- **D8 (caret gate): NOTHING to build** — already realized (§3.3a last bullet); the landings must merely
  not break the `isEditable`-walk path, which lives entirely in Widget/payload code B doesn't touch. The
  existing guard test (`macroDocsToolbarSlotEditViewToggle`) covers the doc mode-flip end-to-end; its
  fixture moves to `new DocumentWdgt` in B3.
- **Model consequence to ratify (owner):** citizens ARE frames, so `requiresDeliberateEmbedding` → a
  slide/doc dragged into a container now needs the ~450ms DWELL to embed (today the bare middle-layer
  editors embedded instantly). Correct under the model (frames never nest by accident); stated because it
  is a feel-able interaction change. (Tests: no macro drops a slide/doc into a container today — verify at
  execution per landing.)

**B-iv. Landing decomposition (bisectable; one fallout kind each; per-landing gates = `fg presuite`,
diffpage + owner eyeball before ANY recapture, phase-close = full `fg gauntlet` with revisits/census at
zero).**
- **B1 — FrameWdgt citizen substrate.** The four base changes + `openFrameWith` passthrough + the
  `_titleForContents` extraction (B-i). NO consumers yet ⇒ ambition byte-identical, zero test churn.
  **✅ LANDED 2026-07-19 — byte-identical confirmed: presuite 263/263, zero geometry violations.**
- **B2 — the text rename + `TitleWdgt`.** `git mv` `SimplePlainTextWdgt`→`SimpleTextWdgt`, sweep src
  (10 files) + tests (207 identifier hits/33 dirs; 65 `"a SimplePlainText"`→`"a SimpleText"` label
  strings/17 dirs — A1 case law); add `TitleWdgt` + adopt in `TemplatesWindowWdgt`'s Title template.
  Fallout kind: hierarchy-menu label width (narrower) — expect menu-visible screenshots + hand-carried-drop
  positions to shift (measure translation, never eyeball; recapture consciously). The scroll-panel sibling
  classes (`SimplePlainTextScrollPanelWdgt`/`SimplePlainTextPanelWdgt`) rename in the same sweep
  (`SimpleTextScrollPanelWdgt`/`SimpleTextPanelWdgt`) — same-family, same-fallout-kind.
- **B3 — `DocumentWdgt`.** Dissolve `SimpleDocumentWdgt` per B-iii; re-point the 4 app/menu constructors +
  the 10 info-widget factories (they become `extends DocumentWdgt`; `_buildInfoDocNextTo` moves to
  `DocumentWdgt` as the static builder and DROPS its `new FrameWdgt simpleDocument` wrap — the doc IS the
  window; `WelcomeMessageInfoWdgt.create` hand-rewired the same way; readers of the
  `simpleDocumentScrollPanel` field switch to `@contents` — no alias field unless the 6
  tests-repo `SimpleDocumentWdgt` files prove to need one). Update those 6 test fixtures to
  `new DocumentWdgt` (incl. the C-phase guard test — `openFrameWith` passthrough keeps its
  `world.openFrameWith doc, …` line working). Fallout kind: doc-window tree shape — hierarchy menus over
  doc content LOSE the middle row (`"a SimpleDocument ▸"` vanishes; ~10 files use that exact label —
  re-aim per test), menu heights shrink where screenshotted; window pixels themselves ambition-identical
  (B-iii probe).
- **B4 — the container-payload citizens.** `SlideWdgt`/`DashboardWdgt`/`PatchProgrammingWdgt`(re-base)/
  `GenericPanelWdgt`; container gains the two ratio hooks + smart-place + `providesAmenitiesForEditing:
  true`; `StretchableEditableWdgt` shrinks to paint's abstract parent (header-stamped: DELETED in D);
  `GenericPanelApp` opens `GenericPanelWdgt`. Fallout kind: near-zero test surface (§3.3a: 1
  `SimpleSlideWdgt` file, 2 `StretchableEditableWdgt` files, 0 labels for slide/dash/patch) + the ratio
  behaviours (slide-keeps-ratio-in-window/stack) re-verified by the existing window/stack suite.
- **B5 — the spreadsheet split.** Grid `git mv` → `SimpleSpreadsheetWdgt`; new thin
  `SpreadsheetWdgt extends FrameWdgt` citizen (payload = the grid; no toolbar variant exists — slot stays
  empty; `providesAmenitiesForEditing` NOT declared: the grid manages its own editing, the frame shows no
  pencil — parity with today); `SpreadsheetApp` opens the citizen. Sweep the 36 test files' fixtures
  (mechanical, zero-pixel: same class, new name) + 1 `"a Spreadsheet"` label dir. Deferrable if the owner
  wants B closed earlier — nothing later depends on it.
- **B6 — image rename + docs.** `git mv` `RasterImageWdgt`→`SimpleImageWdgt` (1 src site, 0 test refs);
  BACKLOG (ImageWdgt-in-D pointer, DeckWdgt reserved-name note); plan stamps + memory sync.

**B-v. Owner decisions taken INTO this design (present before code):** (1) `ImageWdgt` deferred to D
(§3.3a — deviation from the §3.3 table); (2) doc payload name kept (B-ii); (3) `TitleWdgt` initial style =
the templates "Title" (D7 minimal reading); (4) spreadsheet = last/deferrable landing; (5) the
dwell-to-embed consequence (B-iii last bullet); (6) `GenericPanelWdgt` as the Generic-panel citizen name.

### C. One `ToolbarWdgt` per content TYPE, docked-or-floating; one edit-mode toggle
Make `ToolbarWdgt` the single shared toolbar construction (from `ToolPanelWdgt` + the floating
`FrameWdgt`-of-buttons construction), with **one variant per content type** (text / paint / slide / …), not
per widget instance — the buttons duck-type onto the *focused* widget, so one text toolbar serves every text
widget. A `FrameWdgt` docks the variant matching its content in its toolbar-slot; an editor's in-frame
toolbar becomes a **docked instance of that one construction**, not a parallel build — deleting the
duplicated `_createToolsPanelNoSettle`. Keep the pencil/eye on the frame bar; keep the toolbar-slot present
in both modes.

- **Dock side is a property with a per-type default** (D9): `dockSide ∈ {top, left, right, bottom, float}`,
  defaulting to what today already does — **text → top, paint → left** — user-adjustable per frame.
- **Ejection is possible but gets NO dedicated chrome affordance** (owner, 2026-07-18): a floating toolbar is
  reached by *deliberately summoning* one from the Super Toolbar (`ToolbarsApp`) — the "spans many widgets"
  path — not by an eject button on the frame. Undocking a frame's own toolbar into a float is at most a
  context-menu entry, never a bar button (don't spend UI space on it).

**EXECUTION DESIGN (2026-07-19, substrate re-verified against src @ `10aa3342`; §3.4 holds the five-site
embedded inventory + the six floating creators):**

**C-i. The class: `ToolbarWdgt` + one subclass per palette (new folder `src/toolbars/`).**
`class ToolbarWdgt extends ScrollPanelWdgt`, ctor `super new ToolPanelWdgt` then
`@_buildAndConnectChildren()` — byte-for-byte the PROVEN `SlidesToolPanelWdgt` shape (extraction precedent,
incl. the check-constructors-build contract and the `_addManyNoSettle` batch add, which `ScrollPanelWdgt`
forwards to its contents). The base's build core is empty except that it ends
`@_disableDragsDropsAndEditingNoSettle()` — every toolbar is born LOCKED (today each call site locks after
filling; folding the lock into the build deletes those calls). Colloquial name stays "toolbar" for free
(`ToolPanelWdgt.scrollPanelColloquialName`). Class knobs, one per variant:
- `dockSide` — the D9 property, string, class default per variant. C implements `top` and `left` arrange
  support (the two defaults in use); `right`/`bottom`/`float` are reserved values (BACKLOG).
- `dockThickness` — the strip's cross-axis size when docked: text 40 (thumbnail 30 + 2×5 inner padding —
  the variant overrides its inner panel's `externalPadding` from 10 to 5 so a one-row strip is honest
  ToolPanel geometry; today's HorizontalMenuPanel strip is 35, so the doc toolbar grows 5px — conscious
  recapture), left-dockers 95 (byte-parity with today's `StretchableEditableWdgt._reLayoutSelf` arm).

Variants (each fills itself in `_buildAndConnectChildrenNoSettle` with literal `new X` adds):
`TextToolbarWdgt` (the 9 text buttons + `TemplatesButtonWdgt` — ONE list; today the floating build lacks
Templates, the embedded has it: unify to 10, a small feature-add to the floating one. `new
ChangeFontButtonWdgt @` — the toolbar itself is the font-menu stash home; rename that ctor field from the
now-wrong `simpleDocument` to `fontSelectionMenuHolder`), `SlidesToolbarWdgt` (git mv + re-base of
`SlidesToolPanelWdgt` — it already IS this class in all but name/base), `DashboardsToolbarWdgt` (the
18-item list), `PatchProgrammingToolbarWdgt` (ONE unified 5-item list — today embedded has 5, floating 4:
the floating gains `TextBoxCreatorButtonWdgt`), `PlotsToolbarWdgt` (4 plots), `WindowsToolbarWdgt` (4
window creators), `SuperToolbarWdgt` (the 6 toolbar-creator buttons — `ToolbarsApp.buildWindow` becomes
`world.openFrameWith new SuperToolbarWdgt, …`). **Paint is deliberately NOT a C variant:** its
RadioButtonsHolder toolbar is construction-bound to `@overlayCanvas` (§3.5) and becomes a `ToolbarWdgt`
only when D-1 rebinds it to the focus pointer — C quarantines it (below).
Focus-tracking: the base declares `excludedFromLastFocusTracking -> true` (today only
`HorizontalMenuPanelWdgt` has it — clicking BETWEEN buttons must not steal
`lastNonTextPropertyChangerButtonClickedOrDropped`; the floating toolbars lack it today, a latent
focus-stealing bug this fixes for free).

**C-ii. The frame slot — a stable DIRECT child; NO intermediate content-container widget.**
Design refinement over the §1 diagram, argued from §5.2d case law: the diagram's "content-container" is a
REGION of the frame's body, not a widget. Inserting a physical container between frame and content would
re-break every parent-chain seam A2b just audited (the content's `@parent?.showEditModeInBar?()` climb,
the spec's `@stack.availableWidthForContents()` binding, drop targeting, grab climbs, hierarchy menus) for
zero consumers — and post-B the FrameWdgt subclass itself IS the container (the SimpleDocumentWdgt pattern
hoisted). So: `@toolbar` is a direct frame child like `@bar`/`@resizer` (added `notContent: true`), and the
"slot" is the frame field + the dock region its arrange carves out. If B's drag/drop-coordination fold-up
genuinely needs a container widget, B designs it with that consumer in hand.
- **Capability:** content declares its variant by building it — `buildToolbar: -> new TextToolbarWdgt` on
  `SimpleDocumentWdgt` (etc.); no Widget base default, frame dispatches `@contents.buildToolbar?()`
  (absent ⇒ no toolbar, slot stays empty: Generic panel, clock, folder windows all unaffected).
- **Lifecycle** (mirrors the bar pieces + editButton exactly): built keep-if-exist in
  `_buildAndConnectChildrenNoSettle`; destroyed at the two content-CHANGE points
  (`_reactToChildDropped`, `_resetToDefaultContents`) so the next rebuild makes the new content's variant;
  initial shown/hidden state reads `@contents.dragsDropsAndEditingEnabled` (the `_createAndAddEditButton`
  pattern). Show/hide = `_unCollapseNoSettle`/`_collapseNoSettle` (present-in-both-modes rule §4:
  show/hide, never add/remove), wired into the EXISTING mode protocol the content already drives:
  `showEditModeInBar` also uncollapses the toolbar, `showViewModeInBar` collapses it. Window-collapse:
  `_beforeChildCollapsed(child == @contents)` also collapses the toolbar; `_beforeChildUnCollapsed`
  restores it per the content's edit state (the editButton's destroy/recreate lifecycle, minus the
  destroy).
- **Arrange + measure, in LOCKSTEP (§6.1 rule 1 — this is the phase's central risk):** top-dock shown ⇒
  `_chromeHeight` gains `dockThickness + @padding` and the content's top inset moves below the strip;
  left-dock shown ⇒ `availableWidthForContents` gains `− (dockThickness + @padding)` — the specs consume
  it, so content width follows automatically. **Audit list — every inline `2 * @padding` width term in
  FrameWdgt must route through the shared homes or gain the left-dock term:** `_negotiatedContentWidth`
  (DONT_MIND branch), `_firstPlacementContentWidth` (the getWidthInStack arg), `preferredExtentForWidth`
  (both branches), `preferredExtent` (the hug width), the arrange's hug branch
  (`recommendedElementWidth + @padding * 2`) and its `leftPosition` centring line (centre within the
  region RIGHT of a left-docked toolbar, not the frame width). Introduce `_chromeWidth()` (=
  `@width() − availableWidthForContents()`) as the width sibling of `_chromeHeight` so measure and
  arrange share one home. Toolbar placement: within the padded body — top: (`@left()+@padding`,
  bar-bottom`+@padding`) × (availableWidth × 40); left: same origin × (95 × body height to the resizer
  margin). Net pixels for left-dockers ≈ today's (the 95-column moves from inside the content widget to
  the same screen region as a frame child).
- **What it must NOT be (A2b case-law check, consciously inverted):** the toolbar is a real `PanelWdgt`
  (via ScrollPanelWdgt) and KEEPS panel semantics — the grab climb must stop at its glass-box children
  (template drag-out), it draws its own background (no `isTransparentAt` override — it sits inside the
  padded body, clear of the frame's corner notches), and it APPEARS in hierarchy menus as "a toolbar"
  (parity with today's floating toolbars; it is a user-facing target, unlike the bar). Grab-through
  parity: clicking its background still climbs toolbar → frame → grab the window, same as today's
  embedded strips (SimpleDocumentWdgt/StretchableEditableWdgt are plain Widgets, so the climb passed
  through them identically).
- **Smart-place needs NO frame change:** `WidgetCreatorAndSmartPlacerOnClickMixin` already routes via
  `w.isFrame?() and w.contents?.acceptsSmartPlacedWidgets?()` → `where.contents.smartPlace` — it never
  climbs from the button.
- **Editors deleted down to payload + capability:** `SimpleDocumentWdgt` loses `toolsPanel`, its
  `_createToolsPanelNoSettle`, its `_reLayout`'s toolbar arm (scroll panel takes the full body) and its
  enable/disable create/destroy arms; `StretchableEditableWdgt` (base) loses the same (its
  `_reLayoutSelf` toolsPanel arms die; the container takes the full padded bounds);
  `Dashboards/SimpleSlide/PatchProgramming` keep only `buildToolbar`. ⚠ THE FLAG-HOME MOVE: today
  `dragsDropsAndEditingEnabled = true` at construction is set INSIDE each `_createToolsPanelNoSettle` —
  it becomes a class field default (`dragsDropsAndEditingEnabled: true`: an editor is born editing) on
  the four editors; the base Generic panel stays view-born (its empty create never set it). ⚠ PAINT
  QUARANTINE: `ReconfigurablePaintWdgt` keeps a LOCAL `toolsPanel` field + its own
  `_createToolsPanelNoSettle` + its own `_reLayoutSelf` (already has one) — and the base's
  disable-teardown block (removeFromTree/unselectAll/destroy — it exists FOR paint's radio holder) moves
  INTO paint's own `_disableDragsDropsAndEditingNoSettle` override. D-1 dissolves the quarantine.
  `HorizontalMenuPanelWdgt` loses its only editor use (stays: `MenusHelper.createHorizontalMenuPanelPanel`
  demo).
- **Intermediate-state ruling (pre-B, state to owner):** content grabbed OUT of its frame (a naked
  `SimpleDocumentWdgt` on the desktop) has NO attached toolbar until re-framed — it can still be edited
  via the focus pointer + a summoned floating toolbar. Under the keystone (§1.1) a naked editor is
  exactly the state B abolishes; C accepts the gap rather than keeping a second content-owned toolbar
  path alive. (No test reaches a naked editor's `toolsPanel` — sole test mention is paint's, quarantined.)

**C-iii. Landing decomposition (bisectable; one fallout kind each):**
- **C1 — construction + floating consumers.** New `src/toolbars/` classes; the six creator buttons +
  `ToolbarsApp` consume them (bodies collapse to `@_buildToolWindow new XToolbarWdgt, extent`; Plots keeps
  its documented odd op-order, consuming `new PlotsToolbarWdgt`); embedded dashboards/patch/slides
  `_createToolsPanelNoSettle` bodies become `@toolsPanel = new XToolbarWdgt` (still content-owned).
  Fallout: floating-toolbar pixels only (text +Templates, patch +TextBox; extents may need a nudge —
  they scroll). Rename case law: grep tests for `SlidesToolPanelWdgt` identifiers + label lookup strings.
  **✅ LANDED 2026-07-19 — byte-identical: gauntlet 11/11, zero recaptures, zero tests-repo changes (no
  test opens the floating palettes, so even the +Templates/+TextBox list unifications were pixel-free in
  the suite; the slides/dashboards embedded guards passed untouched). ⚠ EXECUTION GOTCHA (cost one red
  presuite): `buildSystem/build.py`'s shippable-source globs are an EXPLICIT directory list — a new `src/`
  directory ships NOTHING until listed there, the build exits 0 anyway, and the syntax gate consumes the
  same list so it silently skips the dir too; the runtime symptom is `<NewClass> is not defined` at first
  use. `src/toolbars/` is now listed; a shippable-vs-`find src` coverage check is a BACKLOG candidate.**
- **C2 — frame slot + TEXT migration.** All of C-ii on `FrameWdgt`; `SimpleDocumentWdgt` migrated.
  Fallout: document-editing tests (strip 35→40 + ToolPanel styling + hierarchy-menu rows over toolbar
  buttons — grep tests for old-chain label strings per A1 case law).
  **⚠⚠ CENSUS CASE LAW from execution (two red census runs; applies to ANY scroll-panel CHROME child,
  incl. C3's left-docks — both fixes are in and BOTH are needed):** (1) chrome is driven SYNCHRONOUSLY
  via `_reLayout bounds` (the `@bar` drive) — a bare `_applyMoveTo`/`_applyExtent` drive commits the
  viewport but re-fits nothing and no settle re-lay follows, so a frame-width change leaves the inner
  grid at a stale wrap height (census mover: a 2-row 75px ToolPanel frame inside the 40px strip after
  the battery's narrow→wide resize); (2) the base scroll-panel re-fit is MEASURE-THEN-COMMIT (it reads
  the items' APPLIED bounds, commits the contents frame, only then re-places), so a re-WRAP converges
  one pass late — `ToolbarWdgt._positionAndResizeChildren` re-places the grid at the applied viewport
  width FIRST (one-pass fixed point).
  **COVERAGE NOTE:** no suite test displays a SimpleDocumentWdgt edit-mode toolbar (the
  macroSimpleDocument* family drives a bare `SimpleDocumentScrollPanelWdgt`), so the suite is
  byte-green across C2 by GAP, not by proof — functional evidence = the apps smoke + a headless probe
  (Docs opens with the docked strip; eye hides; pencil restores pixel-stably). A macro guard test for
  the slot flip (the `macroDrawingsMakerReEnableEditing` byte-idempotence pattern) is follow-on work.
  **✅ C2 LANDED 2026-07-19 — gauntlet 11/11, census 0 movers, zero recaptures, zero tests-repo
  changes.**
- **C3 — slides/dashboards/patch migration + paint quarantine.** `StretchableEditableWdgt` base arms die;
  paint self-contained. Fallout: slides/dashboards/patch editing tests (near-parity pixels), paint tests
  MUST stay byte-identical (`macroDrawingsMakerReEnableEditing` is the guard).
  **✅ C3 LANDED 2026-07-19 — BYTE-IDENTICAL: gauntlet 11/11, zero recaptures (the frame's left dock
  carves the same screen region the internal split used, so the covered slides/dashboards refs —
  which DO show the tool column — matched exactly; the paint guard passed untouched). Execution
  refinement: the deleted builders' `dragsDropsAndEditingEnabled = true` lines were REDUNDANT — the
  Widget class default is already true, so no per-class field was added (a shadow field would churn
  the doc-inspector test's member list for nothing).**
- **C4 — docs/BACKLOG sync.** BACKLOG: undock context-menu entry (D9 tail); `right`/`bottom` dock
  arranges; `HorizontalMenuPanelWdgt` demo-only fate. Plan stamps.
Gates per landing: `fg presuite`, diffpage + owner eyeball before ANY recapture; close each with
`fg gauntlet` — revisits/census MUST stay at zero (the new dock math must keep the arrange idempotent and
the measures pure — no toolbar-extent read-back in a measure; `dockThickness` is a constant, never a
laid-out size).

### D. Unify PAINT onto the focus model + unify the editing-focus indicators (folds in idea (d))
1. **Paint like text.** Add a paint `ToolbarWdgt` whose buttons read the focus pointer, feature-test
   `acceptsPenDrawing()`/`getContextForPainting()`, and paint into the focused `ImageWdgt`'s canvas —
   replacing the construction-bound `@overlayCanvas` wiring. Spike first (S1) against a free-standing
   `ImageWdgt` to confirm byte-safety; consume the **mapped `pos`** (transform rule).
2. **One editing-focus model.** The text **caret** and the paint **tool-head** are both world-level,
   layout-inert, transient overlays marking "where editing happens" — unify them under one focus
   abstraction (a focused object + an indicator + a selection), with the shared `ToolbarWdgt` binding to the
   focus pointer. This subsumes `world.caret`, `lastNonTextPropertyChangerButtonClickedOrDropped`, paint's
   overlay-bound tool, and `StringWdgt.selection` into one story. (The note's "tool-heads follow the same
   pattern as the Caret.")

### E. Uniform contents protocol + read-only-as-capability
- Content enters a `FrameWdgt` uniformly via `add(startingContent)` (+ a `defaultContents` placeholder),
  retiring special `setContents(x, N)` inits (the *IconicDesktopSystem…AppLauncher* note).
- Replace `info-widgets/* extends SimpleDocumentWdgt` with a **`readOnly` capability** on `DocumentWdgt`
  (the "why do info widgets extend simple document" smell) — read-only-ness is a property, not a subtype.

### Suggested phase order (verifiability, not churn-avoidance)
1. **A** (FrameWdgt rename+compose) — everything else names it.
2. **C** (one ToolbarWdgt + slot) — dedupe the toolbar; card-compose fix.
3. **B** (payload/citizen split) — the big structural batch; land content-type by content-type.
4. **D-1** paint-on-focus spike → build; **D-2** focus-model unification.
5. **E** contents protocol + read-only capability.
Each phase gates on `fg build` then `fg gauntlet`; anything touching input/caret/paint also gates on the
determinism note (`Fizzygum-tests/DETERMINISM.md`). Recapture consciously, with a stated reason, wherever
pixels legitimately move.

### P0 doc (do first, cheap): `architecture/regularity-principles.md`
State the house law once — *"separate the fused axes; the name encodes the role"* — with the four places it
already holds (geometry two-vocabulary law, method tier scheme, notification grid, `*Appearance`) and this
arc's addition (naked capability / manipulable citizen / intrinsic frame). Filing: `architecture/` (it's a
standing convention, already partly true; the frame model itself graduates there once built).

---

## 6. Owner decisions

| # | Decision | Status |
|---|---|---|
| D1 | Superclass name | **`FrameWdgt`** — LOCKED. Skins window/card derived from parentage. |
| D2 | Per-kind names, no forced suffix | **`DocumentWdgt`/`ImageWdgt`/`SlideWdgt`/`DeckWdgt`/`DashboardWdgt`/`SpreadsheetWdgt`** — LOCKED (document is the text-flavoured kind; `ImageDocumentWdgt` rejected). |
| D3 | "plain = manipulable citizen, not necessarily framed" | **ACCEPTED** — LOCKED (owner). |
| D4 | Framing is intrinsic to the content type (not context) | **ACCEPTED** — LOCKED; "frame-on-demand" REJECTED. |
| D5 | Correctness over churn | **ACCEPTED** — LOCKED; no churn-based deferrals; phasing = verifiability only. |
| D6 | `Simple*` vs `Basic*` prefix | **`Simple*`** — LOCKED (owner, 2026-07-19): the established prefix; `basic-widgets/` makes `Basic*` read oddly. |
| D7 | Naked-text class/role | **`TitleWdgt` = a THIN SUBCLASS of `SimpleTextWdgt`** — LOCKED (owner, 2026-07-19): the name encodes the role (hierarchy label "a Title", serialization/drop identity, styling defaults in-class). |
| D8 | Does text-entry (caret) get gated by edit mode inside a `DocumentWdgt`? | **YES** — LOCKED (owner, 2026-07-19): view = published/locked page, clicks summon no caret; the pencil flips into editing (caret + toolbar together). |
| D9 | Toolbar dock side + ejection | **LOCKED** — one `ToolbarWdgt` variant per content type; `dockSide` a property (default text→top, paint→left); ejection possible via the Super Toolbar but **no dedicated eject affordance** (context-menu at most). |

---

## 7. Risks & non-goals
- **Big migration, deliberately.** A/B rename+restructure a central, serialized, name-drawn class family →
  large recapture + serialization surface. Owner accepts this in service of the right structure; land in
  bisectable batches.
- **Determinism** for the caret/tool-head/paint/input paths (`Fizzygum-tests/DETERMINISM.md`).
- **Toolbar-slot must show/hide, not add/remove**, or mode-flip churns the tree (settle cost / flicker).
- **Non-goals here:** the graph-edge + GC model (its own arc, (b)); creation/Factory (its own arc, (c));
  the reference-widget UI (reference plan). "Open in editor" two-way flow stays banked (the note calls it
  DISCOURAGED).
- **Do NOT revive:** frame-on-demand (§1.1); the Tiles/Cassowary dead-ends (§2); the `_announce*ToContainer`
  up-notify seam (banned, rule [N]).

## 8. Cross-links
- Program siblings: [`container-regularization-plan.md`](container-regularization-plan.md) (✅ COMPLETE
  2026-07-19) + its follow-on [`menu-row-conformance-plan.md`](menu-row-conformance-plan.md) (✅ COMPLETE
  2026-07-19 — the §5.2e stack-client precedent cited in §3.1),
  [`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md),
  [`creation-and-templates-plan.md`](creation-and-templates-plan.md),
  [`reference-widgets-plan.md`](reference-widgets-plan.md).
- Architecture: `docs/architecture/{layering-naming-convention,layout,transforms,lint-and-static-checks}.md`.
- Landed history: `docs/archive/drag-embed-implementation-plan.md` (internal/external skin derivation),
  `docs/archive/pencil-eye-edit-mode-toggle-plan.md`, `docs/archive/disable-editing-family-convert-plan.md`,
  `docs/archive/god-class-decomposition-plan.md` (mixins→OO-delegation precedent).
```
