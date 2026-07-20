# The Frame model — naked capability → manipulable citizen → App

**STATUS: AUTHORED 2026-07-18, REVISED 2026-07-18, RE-VERIFIED 2026-07-19. EXECUTING: Phase A ✅ COMPLETE
2026-07-19 (P0+A1 `03163312`/`c53055fd`, A2a `edd40eb1`, A2b `10aa3342`); §5.C execution design ADDED
2026-07-19 (toolbar substrate re-verified against src @ `10aa3342` — §3.4's A1-drifted names corrected);
Phase C ✅ COMPLETE 2026-07-19 (C1 `1e06b79f`, C2 `74322e1d`, C3 `3e8eecd6`, C4 `ab07bd95`, island fix
`58fa177e`, D6/D7/D8 lock `c4cd9d46`; guard test Fizzygum-tests `24bfa3882`); §5.B execution design ADDED
2026-07-19 (§3.3 substrate re-verified against src @ `c4cd9d46` — verified deltas recorded in §3.3a);
Phase B ✅ COMPLETE 2026-07-19 (B1 `fe76f679`, B2 `79eaaf9c`, B3 `4dcfbc4c`, B4 `19b13d9d`, B5+B6 in the
closing commit — landing stamps + execution case law in §5.B B-iv); §5.D D-1 ✅ COMPLETE 2026-07-20
(owner ratified D10–D14; S1 spike ALL PASS — evidence in D-iii; D1b landed BYTE-IDENTICAL, gauntlet
11/11, zero recaptures — landing stamp + case law in D-iv: ImageWdgt + PaintToolbarWdgt + press-time
paintingOverlay() resolution + ancestry focus exclusion; ReconfigurablePaintWdgt and
StretchableEditableWdgt DELETED); §5.D D-2 ✅ COMPLETE 2026-07-20 (substrate re-verified against src
@ `c68a63cb` — deltas in D-2-i; the mandated four-way focus abstraction FALSIFIED as
structure-without-a-consumer, D15–D17 ratified; landed the focus-POLICY unification D2a–D2c
BYTE-IDENTICAL — gauntlet 11/11, revisits 0, census 0, zero recaptures; landing stamp + case law in
D-2-v). §5.E execution design ADDED 2026-07-20 (substrate re-verified @ `ccaefd44` — deltas in E-i;
like D-2 most of §5.E is ALREADY DELIVERED by A/B/D: thread 1 uniform-content-entry done, the
read-only INHERITANCE smell removed by B; honest deliverable = E2 close-policy-as-tracked-field
resolving the code's own monkey-patch TODO; E1 no-pencil readOnly deferred per the LOCKED-D8 argument;
E-D18–E-D20 ratified). §5.E ✅ COMPLETE 2026-07-20 (E2 close-policy-as-tracked-field landed
BYTE-IDENTICAL — gauntlet 11/11, revisits 0, census 0, zero recaptures; landing + case law in E-vi;
E1 no-pencil readOnly + the info-widget factory collapse DEFERRED to BACKLOG). **⇒ THE FRAME-MODEL
FLAGSHIP ARC (phases A · C · B · D · E) IS COMPLETE.** Follow-ons all owner-gated on the BACKLOG.**
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
- **Focus pointer:** `WorldWdgt.editorFocusWdgt` (renamed from
  `lastNonTextPropertyChangerButtonClickedOrDropped` in D2c), set on every content click/drop by
  `ActivePointerWdgt`; STICKY — cleared at `_softResetWorld` and (D2b) when the focused widget is
  destroyed, NOT on stop-editing (the original "reset on stop-editing" claim was drift). Editor
  chrome (toolbars, text/creator buttons, the font menu) opts out via the ONE ancestry-honored
  `excludedFromEditorFocusTracking` capability (D2a unified the former
  `editorContentPropertyChangerButton` field into it), so a click on chrome neither steals the
  pointer nor ends the edit.
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
  overlay** (`world.caret`) torn-down-and-rebuilt per edit session at whatever text is being edited
  (`world.edit`/`stopEditing`); `isLayoutInert`, excluded from bounds/hit-test. It is one of THREE
  `world.keyboardEventsReceivers` member kinds (the "sole member" claim was drift, corrected D-2-i #1):
  the caret (session-scoped), `SimpleSpreadsheetWdgt` (its own exclusive-among-sheets discipline), and
  `VideoPlayerWdgt` (a permanent member).
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
  **✅ LANDED 2026-07-19 — presuite 263/263 after ONE conscious recapture (`macroScrollPanelMergesChildMenu`:
  the delta = the menu TITLE "SimplePlainTextScrollPanel"→"SimpleTextScrollPanel" + the menu's hugged
  width, all rows/positions identical — diffpage-verified). Sweep facts as measured: the whole-family
  one-pass `SimplePlainText`→`SimpleText` replacement is collision-free; tests repo took 128 files incl.
  TWO test-DIR renames (`macroSimplePlainTextScrollPanelUpdatesWell…`, `macroWrappingSimplePlainText
  Resizes…`) whose name-embedding reference assets were git-mv'd depth-first; the harness audit prelude
  (`scripts/end-of-cycle-audit/layout-audit-prelude.js`) carried ONE class-name string; archives/snapshot
  docs deliberately NOT swept (verbatim historical records).**
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
  **✅ LANDED 2026-07-19 — PIXEL-IDENTICAL: presuite 263/263 + apps smoke ALL PASS, ZERO recaptures (the
  guard test + SavedDocumentShortcutIcon passed against their OLD-structure references = the dissolution
  witness; the ~10 "a SimpleDocument" label matches proved to be metadata PROSE — no live macro navigates
  the dissolved row). Execution case law: (1) ⚠⚠ a citizen `_resetToDefaultContents` that CONSTRUCTS a
  fresh payload must skip its own teardown — the destroy-until-empty iteration otherwise rebuilds forever
  (renderer OOM, page CRASH in-suite, passes-alone; fixed by the `_beingFullDestroyed` flag set at
  FrameWdgt._fullDestroyNoSettle, the subtree destroy ENTRY, + the citizen guard); (2) the layering gate
  attributes a STATIC class-method's calls to the preceding INSTANCE method — order `@_buildInfoDocNextTo`
  right after the ctor; (3) the call-separation gate catches protocol moves that leave a public verb
  self-only (`scrollToBottom` → allowlisted as deliberate in-world API); (4) drive-by fix: SampleDocApp's
  buildWindow returned the close-monkey-patch CLOSURE, so `world[@slot]` held a function — explicit
  `return doc`.**
- **B4 — the container-payload citizens.** `SlideWdgt`/`DashboardWdgt`/`PatchProgrammingWdgt`(re-base)/
  `GenericPanelWdgt`; container gains the two ratio hooks + smart-place + `providesAmenitiesForEditing:
  true`; `StretchableEditableWdgt` shrinks to paint's abstract parent (header-stamped: DELETED in D);
  `GenericPanelApp` opens `GenericPanelWdgt`. Fallout kind: near-zero test surface (§3.3a: 1
  `SimpleSlideWdgt` file, 2 `StretchableEditableWdgt` files, 0 labels for slide/dash/patch) + the ratio
  behaviours (slide-keeps-ratio-in-window/stack) re-verified by the existing window/stack suite.
  **✅ LANDED 2026-07-19 — 263/263, ZERO recaptures. Design refinement from execution:
  `GenericPanelWdgt` is BOTH the Generic-panel citizen AND the family base (Slide/Dashboard/Patch extend
  it) — the same two-role shape `StretchableEditableWdgt` had, so the shared close/reset/title machinery
  has one home. The citizen declares `providesAmenitiesForEditing`; the container does NOT (the B1 gate
  reads the citizen). ⚠⚠ EXECUTION CASE LAW (two red rounds, both root-caused from evidence):
  (1) **the container's legacy `canSetHeightFreely` writers were `?.`-no-ops in the window era** (they
  targeted a nil/stack spec; the retired editor's un-overridden FrameContentLayoutSpec — default free —
  governed the window). As direct frame content they suddenly ACTED and ratio-LOCKED every citizen
  window's height (diffpage evidence: reference letterboxes in a free-height window, divergent render
  pulls content up). The faithful port = the editor's seams one level down: NO
  `initialiseDefaultFrameContentLayoutSpec` override, the free-spec early-out at the TOP of
  `_setWidthSizeHeightAccordingly` AND `preferredExtentForWidth` (measure/mutator lockstep), and
  crystallization writes guarded by the NEW `FrameContentLayoutSpec.isFrameContentSpec?()` capability
  query (the isFrame idiom — the stink gate rejects new bare `instanceof`). Ratio-lock arrives ONLY via
  the holder-frame stack-drop hook, crystallization stays drop-driven (`StretchablePanelWdgt.setRatio`).
  (2) **macros reach the dissolved middle layer by FIELD PATH, not just by constructor/label** — two
  tests died as in-suite UNCAUGHT ERRORS (`…stretchableWidgetContainer.ratio`/`.contents` on undefined;
  byte-clean when run alone, "zero failed screenshots = uncaught error" signature, shard STALLED and
  wedged the paint leg's timeout) — every structural dissolution must grep the tests repo for the OLD
  FIELD NAMES (`stretchableWidgetContainer`, `simpleDocumentScrollPanel`) too. ⚠ tests live IN the
  build: a tests-repo macro fix needs a FULL rebuild before the headless suite sees it.
  (3b — phase-close find) **HARNESS scripts name-test window-ness too:** the census battery found its
  windows via `/FrameWdgt/.test(constructor.name)`, so the citizens ESCAPED it — one un-resized
  as-built window then failed the sweep (a PRE-EXISTING as-built staleness the battery had always
  masked; BACKLOG'd). Fixed to the polymorphic `isFrame()`; grep harness scripts for name-regex
  window tests on every subclassing arc.**
- **B5 — the spreadsheet split.** Grid `git mv` → `SimpleSpreadsheetWdgt`; new thin
  `SpreadsheetWdgt extends FrameWdgt` citizen (payload = the grid; no toolbar variant exists — slot stays
  empty; `providesAmenitiesForEditing` NOT declared: the grid manages its own editing, the frame shows no
  pencil — parity with today); `SpreadsheetApp` opens the citizen. Sweep the 36 test files' fixtures
  (mechanical, zero-pixel: same class, new name) + 1 `"a Spreadsheet"` label dir. Deferrable if the owner
  wants B closed earlier — nothing later depends on it.
  **✅ LANDED 2026-07-19 (with B6, one verification): the citizen is TRULY thin (ctor + colloquialName +
  title hook + reset — no amenities/no icon/no close override: the plain-wrapped era's window had no
  pencil, titled from the grid's "spreadsheet", closed via the base flow, and the frame's icon dispatch
  reaches the grid unchanged); `SpreadsheetApp`'s `new SpreadsheetWdgt` line is textually UNTOUCHED
  (openFrameWith passthrough); tests = the blanket 36-file identifier sweep, zero label lookups (the "a
  Spreadsheet" hit was metadata prose).**
- **B6 — image rename + docs.** `git mv` `RasterImageWdgt`→`SimpleImageWdgt` (1 src site, 0 test refs);
  BACKLOG (ImageWdgt-in-D pointer, DeckWdgt reserved-name note); plan stamps + memory sync.
  **✅ LANDED 2026-07-19: rename + the button's stale `rasterImageWdgt` field → `imageWdgt` (one
  external reader, `VideoThumbnailWdgt.setThumbnailAndVideoPath`, updated with it).**

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
1. **Paint like text.** Add a paint toolbar whose tools bind to the image being edited at PRESS time
   (not at construction), so any paint toolbar can serve any image — replacing the construction-bound
   `@overlayCanvas` wiring. Spike first (S1) to confirm byte-safety; consume the **mapped `pos`**
   (transform rule). Lands `ImageWdgt`; deletes `StretchableEditableWdgt` + the §5.C paint quarantine.
2. **One editing-focus model.** The text **caret** and the paint **tool-head** are both world-level,
   layout-inert, transient overlays marking "where editing happens" — unify them under one focus
   abstraction (a focused object + an indicator + a selection), with the shared `ToolbarWdgt` binding to the
   focus pointer. This subsumes `world.caret`, `lastNonTextPropertyChangerButtonClickedOrDropped`, paint's
   overlay-bound tool, and `StringWdgt.selection` into one story. (The note's "tool-heads follow the same
   pattern as the Caret.")

**EXECUTION DESIGN for D-1 (2026-07-20; substrate re-verified against src @ `1a15e034`). D-2 is
deliberately NOT designed here — it gets its own design pass after D-1 lands (D-iv last bullet).**

**D-i. Verified substrate deltas (2026-07-20) — facts that shape this design:**
1. **The tool sources already consume the MAPPED `pos`.** The pointer's move dispatch maps per-receiver
   (`newWdgt.mouseMove?(newWdgt.screenPointToMyPlane(@position()), @mouseButton)` — the §6-affine R1
   comment sits on the site), so the transform rule holds by construction; S1 still proves it under a
   tilted island (evidence, not assumption).
2. **Clicking the paint surface focuses the GLASS.** The overlay `CanvasGlassTopWdgt`
   (`noticesTransparentClick = true`) is the top widget over the whole canvas, so after any content click
   `world.lastNonTextPropertyChangerButtonClickedOrDropped` = the glass, never the canvas/container.
   Press-time resolution must accept glass-or-descendant and resolve to the apparatus.
3. **The focus pointer is STICKY** — cleared only at `_softResetWorld`, NOT on stop-editing (§3.4's
   "reset on stop-editing" has drifted). A freshly-opened image is NOT focused until clicked.
4. **The view-mode stroke gate IS the un-inject.** The injected handlers check only
   `world.hand.isThisPointerDraggingSomething()`; view mode paints nothing today only because the disable
   teardown `unselectAll`s (each selected toggle injects its `mouseMove = -> return` no-op) before
   destroying the panel. Any design that keeps the toolbar alive across mode flips must keep an
   equivalent disarm.
5. **Tool state does NOT survive a mode flip today**: re-enable rebuilds the panel and auto-selects
   pencil (`@pencilToolButton.toggle()` inside `_createToolsPanelNoSettle`). The
   `macroDrawingsMakerReEnableEditing` image_0==image_2 idempotence assert RELIES on this re-arm.
6. **Today's tool-column geometry maps exactly onto a left dock.** The RadioButtonsHolder sits at
   content-left, width 103 (2·internalPadding 5 + button 93), full content height (externalPadding 0),
   buttons 93×55 stacked at 5px gaps; the container starts at column-right + 5. A left dock with
   `dockThickness: 103` places both the strip and the container at IDENTICAL x/extents (the frame's
   padding-5 body = today's content region). Byte-parity is therefore PLAUSIBLE — claimed only by
   suite + diffpage evidence, never analytically (DETERMINISM.md §3f).
7. **`hasStartingContentBeenChangedByUser` for paint IS ratio-crystallization**: the first
   `getContextForPainting` call does `@parent.setRatio` — exactly the `@contents?.ratio?` check
   `GenericPanelWdgt` already carries. The close policy inherits wholesale.
8. **Measured churn surface**: the ONLY test refs are the two paint guards
   (`macroDrawingsMakerReEnableEditing`, `macroEditModeTogglePencilEyeGlyph`) — both construct
   `new ReconfigurablePaintWdgt`, navigate the hierarchy menu by the `"a ReconfigurablePaint"` prefix,
   and read `win.editButton` (a frame field — survives). Zero other identifier/field/label hits in
   tests; harness scripts clean; docs: one mention in `docs/specs/drag-embed-interaction-spec.md`.
9. **`CodeInjectingSimpleRectangularButtonWdgt` has NO consumer outside paint** — its binding contract
   is free to change.
10. **`KeepsRatioWhenInVerticalStackMixin` SURVIVES** the `StretchableEditableWdgt` deletion (IconWdgt +
    the plot widgets still augment with it).
11. **The §3.3 table's "payload = `SimpleImageWdgt`" does not match substrate.** The paintable apparatus
    is `StretchableWidgetContainerWdgt(StretchableCanvasWdgt)` + glass; `SimpleImageWdgt` (the bitmap
    loader) has ONE consumer (a button face) and no content flow. D-1 builds `ImageWdgt` over the PAINT
    apparatus; merging the bitmap loader in (load an image file into a paintable canvas) is deferred
    with a BACKLOG line — structure-without-a-consumer, and the stamp drop-flow already imports pixels
    (`StretchableCanvasWdgt._reactToChildDropped` → `_paintImage`).
12. **The citizen's hierarchy row will read `"a Image ▸"`** — `Widget.toString` is the literal
    `"a " + <class sans Wdgt>`; article quirk noted, D2's name is locked.

**D-ii. The design — press-time focus binding; the citizen; the toolbar.**
Central choice: **D-1 keeps INJECTION as the arming mechanism** — proven, serialization-carrying (the
glass's `mouseMove_source` → `{"$src"}` rides a saved drawing), live-editable (`EditableMarkWdgt`) — and
changes only WHO RESOLVES THE TARGET, AND WHEN: construction-bound `@overlayCanvas` → press-time
resolution. A world-level tool-object/tool-head abstraction is deliberately NOT built in D-1: that is
D-2's design space, and per-image armed-handler state leaves nothing world-level for D-2 to unwind.
1. **`ImageWdgt extends GenericPanelWdgt`** (`src/apps/`, the D2 name):
   - `GenericPanelWdgt` gains the **`_makeStartingPayload` hook** (the DocumentWdgt shape): ctor becomes
     `super @_makeStartingPayload()`, `_resetToDefaultContents` uses it. Base returns
     `new StretchableWidgetContainerWdgt` — Slide/Dashboard/Patch unchanged, zero-pixel refactor.
   - ImageWdgt's `_makeStartingPayload`: the container over `new StretchableCanvasWdgt` with
     `disableDrops()` (parity), the glass wired (`underlyingCanvasWdgt`, `noticesTransparentClick`,
     drops disabled) and added to the canvas, the clear-on-leave `mouseLeave` injection moved verbatim,
     and the PENCIL source injected at build — **born armed**, replacing today's construction-time
     `toggle()` (D-i #5 parity without firing a button action).
   - Per-kind declarations: `colloquialName "Drawings Maker"` (D14), `representativeIcon
     PaintBucketIconWdgt`, `buildToolbar: -> new PaintToolbarWdgt`. Close / reset-guard / title /
     changed-check: INHERITED from `GenericPanelWdgt` (D-i #7); `providesAmenitiesForEditing` likewise.
2. **`PaintToolbarWdgt`** (`src/toolbars/`): the RADIO-TOOL palette. **NOT a `ToolbarWdgt` subclass**
   (owner decision D10): its items are stateful radio TOGGLES with editable-mark annotations, not
   drag-out creator thumbnails — forcing them into the ScrollPanel(ToolPanel) grid would demand new
   radio-capable thumbnail machinery AND churn proven pixels for no semantic gain. Shape:
   `extends RadioButtonsHolderWdgt`, conforming to the slot's DUCK contract (`dockSide: 'left'`,
   `dockThickness: 103`, the collapse cores, `_reLayout`, `excludedFromLastFocusTracking -> true`):
   builds the 4 ToggleButton pairs + EditableMarks verbatim from `_createToolsPanelNoSettle` (minus the
   `@overlayCanvas` ctor binding), arranges its own buttons (93×55 stacked at internalPadding 5 —
   bounds-first, idempotent, integer), keeps `isToolPressed` / `newCodeToInjectFromButton` (the
   notified party becomes the toolbar), and shows pencil selected at build via `_setToggleState`
   (display only — the ARM lives in the payload build, D-ii 1).
   - **Mode flip** (the slot protocol collapses/uncollapses it): `_collapseNoSettle` also DISARMS;
     `_unCollapseNoSettle` also RE-ARMS pencil (D-i #4/#5 — preserves the guard's idempotence).
     ⚠ **Neither may fire button actions**: `unselectAll()`'s `toggle()` escalation reaches
     SwitchButtonWdgt's SELF-SETTLING `mouseClickLeft` — the transitive-settle trap that forced paint's
     DETACH-then-teardown dance, and these cores run on an ATTACHED toolbar inside the content's
     enable/disable flush. Disarm/re-arm = **inject the target source directly** (`injectProperties` is
     settle-free) **+ `_setToggleState`** (display, no fire) — eliminating the trap instead of dancing
     around it.
3. **Press-time target resolution** (owner decision D11): a NEW capability chain **`paintingOverlay()`**
   — the glass returns itself; `CanvasWdgt` returns its glass child if any; the container and
   `FrameWdgt` delegate to `@contents` (nil-safe `?()` everywhere; absent ⇒ not paintable). The
   injecting button resolves at press: **docked → the enclosing frame's `paintingOverlay()`** (a docked
   toolbar is THIS image's chrome — deterministic, and covers the fresh-open-no-click case given
   born-armed); **floating → `world.lastNonTextPropertyChangerButtonClickedOrDropped?.
   paintingOverlay?()`** (glass-or-descendant resolves, D-i #2; not paintable ⇒ the press is a
   visual-only radio flip — the text-toolbar's no-focused-target no-op, same UX contract).
   `CodeInjectingSimpleRectangularButtonWdgt`'s ctor swaps the `wdgtWhereToInject` arg for a
   toolbar-supplied resolver (paint is its only consumer, D-i #9).
4. **What DISSOLVES** (member-by-member): ctor payload → `_makeStartingPayload`; the whole `toolsPanel`
   lifecycle (field, build, enable-create, disable-teardown, `_reLayoutSelf` tool arms) → the frame
   slot + `PaintToolbarWdgt`; the enable/disable overrides → the §5.B frame-level route + the
   container's relays + the toolbar's collapse cores; `_reLayoutSelf` → the frame arrange + the
   toolbar's own; `colloquialName`/`representativeIcon` → the citizen; `closeFromContainerFrame`/
   `hasStartingContentBeenChangedByUser` → inherited; smart-place → the container already owns it
   (§5.B). **`ReconfigurablePaintWdgt` deleted; `StretchableEditableWdgt` DELETED** (paint was its last
   subclass; the mixin survives, D-i #10). Consumers re-pointed: `FizzyPaintApp.buildWindow` /
   `MenusHelper.createReconfigurablePaint` → `new ImageWdgt` (the openFrameWith passthrough keeps the
   line shape); `ReconfigurablePaintInfoWdgt` keeps its name (it's the INFO DOC about the app), only
   its `colloquialName`-adjacent prose mentions move if any.
5. **Serialization**: mechanism unchanged (the glass carries `mouseMove_source`/`mouseLeave_source`
   exactly as today); no compat obligations in either direction.

**D-iii. S1 spike — the gate BEFORE any landing** (probe in `Fizzygum-tests/.scratch/`, reusing
`scripts/lib/headless-boot`; evidence recorded HERE before D1b starts):
1. **Focus premise**: click the canvas of an open paint window; assert the focus pointer holds the
   GLASS (D-i #2).
2. **Rebind byte-safety**: twin paint windows; A strokes via today's construction-bound injection; B
   gets the same tool source injected via the press-time resolution path; drive identical synthesized
   stroke sequences over both; assert the two canvases' pixel hashes EQUAL.
3. **Transform rule**: tilt one image under a `TransformFrameWdgt` island, stroke through the mapped
   dispatch; assert strokes land at plane-local coordinates (D-i #1 as evidence, not assumption).

**✅ S1 RAN 2026-07-20 — ALL THREE PARTS PASS** (probe `Fizzygum-tests/.scratch/spike-paint-focus.js`,
real CDP input against the built world @ `1a15e034`):
1. a click over the paint surface leaves the focus pointer on the GLASS (`CanvasGlassTopWdgt`,
   `underlyingCanvasWdgt` present) — premise CONFIRMED;
2. construction-armed vs focus-pointer-re-armed twins driven with identical stroke sequences produce
   BYTE-IDENTICAL painting buffers (behind-the-scenes AND front, plus equal crystallized ratios);
3. strokes through a 30°-rotated sugar island (`setRotationDegrees` on the window →
   `TrackingTransformFrameWdgt`) land AT the plane-local targets, and the naive unmapped landing spot
   (30px away) stays clean — the R1 mapped dispatch is load-bearing, not incidental.
Two probe-mechanics facts worth keeping (they shaped the probe, not the design): the pointer SUPPRESSES
the mouseMove at the exact button-down point ("only if actually moved"), so a stroke's first painted
point is the first move AFTER the down — macro authors take note; and `mouseOverNew` = top widget +
ANCESTORS, so every ancestor's `mouseMove?` fires too (the glass being top is what matters).

**D-iv. Landing decomposition** (per-landing gates = `fg presuite`, diffpage + owner eyeball before ANY
recapture; phase-close = full `fg gauntlet`, revisits/census at zero):
- **D1a — the S1 spike** (no src changes; evidence into D-iii).
- **D1b — rebind + citizen + dissolution** (one landing — the pieces only work together):
  `GenericPanelWdgt._makeStartingPayload` hoist; `PaintToolbarWdgt`; `ImageWdgt`; delete
  `ReconfigurablePaintWdgt` + `StretchableEditableWdgt`; re-point the consumers; tests: the two guards'
  fixtures → `new ImageWdgt` + hierarchy-label re-aim (`"a ReconfigurablePaint"` → the citizen row),
  old-field-name grep repeated at execution (B case law #3). Ambition byte-identical (D-i #6) — judged
  by suite + diffpage, never argued (§3f).
  **✅ LANDED 2026-07-20 — BYTE-IDENTICAL: 263/263 + gauntlet 11/11 (dpr1/dpr2/webkit/apps/paint/
  tiernaming/settle/capstone/refs/revisits/census), ZERO recaptures — both paint guards passed against
  their OLD references (the D-i #6 left-dock geometry argument held), and the hierarchy drill re-aim
  (`"a StretchableWidgetContainer"` — the lock entry lives on the CONTAINER post-dissolution) reproduced
  image_0 exactly. Design refinements + case law from execution:**
  1. **Focus-steal by chrome LEAVES (probed, then fixed by ANCESTRY):** clicking a tool button leaves
     the focus pointer on the button's icon FACE (`Pencil2IconWdgt`), the column background on the
     holder — the dispatch's self-only `excludedFromLastFocusTracking?()` check cannot cover a composed
     subtree, so the floating-toolbar resolution would read a stolen pointer. Fixed at the pointer's TWO
     set sites via `ActivePointerWdgt._excludedFromLastFocusTrackingByAncestry(w)` (walks
     w→ancestors) — which also closes the same latent hole for the C toolbars' scrollbars/inner panels.
  2. **⚠⚠ NEW inspector case law: a Widget BASE METHOD add churns the inherited-members inspector
     test.** The ancestry query's first home was `Widget` — and `macroDuplicatedInspectorDrivesCopied
     TargetOnly` (the ONE test that flips `inherited: on`, methods shown by default) failed: the
     rectangle's member list grew one row, shifting the pane rows around `alpha` (diffpage-confirmed;
     behaviour intact). The "methods don't churn the inspector, fields do" rule holds only for
     own-members panels. Fix ON MERITS: the walk moved to `ActivePointerWdgt` (private — the pointer
     owns the focus-tracking policy; widgets declare only the per-class opt-out), restoring
     byte-identity with no recapture.
  3. **Gate rounds absorbed (one each):** dead-methods caught `RadioButtonsHolderWdgt.unselectAll`
     (DELETED — its only caller was the retired toggle-firing teardown; the non-firing disarm replaced
     it); call-separation [S] wanted `ToggleButtonWdgt.setToggleState` as the public-wrap-over-
     `_setToggleState`-core (VideoPlayPauseToggle self-calls the core); call-separation [U] caught
     `removeFromTree` newly self-only → allowlisted as deliberate in-world API (the B3 `scrollToBottom`
     precedent — the retired paint teardown was its lone cross-object caller).
  4. **The stale-build guard earned its keep:** a comment-only src edit DURING the first gauntlet run
     made the tree newer than the build — every wave-B leg refused to run vacuously. Full re-run
     against the final tree; never touch src (even comments) while any leg is running.
- **D1c — docs/BACKLOG sync**: the drag-embed spec mention; BACKLOG lines: load-image-file flow
  (D-i #11), the `"a Image"` article quirk (D-i #12), the D-2 pointer; plan stamps + memory sync.
- **D-2 — one editing-focus model**: its OWN design pass after D-1 lands (unify `world.caret` + the
  focus pointer + per-image armed tool + `StringWdgt.selection` under one focus abstraction with
  indicator overlays; gates on `Fizzygum-tests/DETERMINISM.md` §5 for every input/caret path).
  **→ Design pass RUN 2026-07-20: the four-way abstraction was found structure-without-a-consumer;
  the honest scope is the focus-POLICY unification — see D-2-i…D-2-iv below.**

**D-v. Owner decisions to ratify (present BEFORE code):**
- **D10 — toolbar construction**: `PaintToolbarWdgt` = the radio-holder construction conforming to the
  slot's duck contract, NOT a `ToolbarWdgt` subclass (D-ii 2). Alternative: full ToolbarWdgt
  conformance = new radio-thumbnail machinery + conscious recapture of both paint guards.
- **D11 — press resolution order**: docked-acts-on-own-frame, floating-follows-focus (D-ii 3).
  Alternative: focus-only everywhere (the C-model purist reading) — leaves a docked toolbar dead until
  the image's first click.
- **D12 — injection stays the arming mechanism in D-1**; the world-level tool object is D-2's call.
- **D13 — `ImageWdgt` is built over the paint apparatus**; `SimpleImageWdgt` stays a sibling payload
  until a load-image-file consumer exists (deviation from the §3.3 table, argued in D-i #11).
- **D14 — `colloquialName` stays "Drawings Maker"** in D-1 (window title + save-shortcut parity; kind
  vocabulary can follow later without structural change).

**EXECUTION DESIGN for D-2 (2026-07-20; substrate re-verified against src @ `c68a63cb`). The design
pass was mandated open-endedly ("one focus abstraction"); the re-validation FALSIFIED the mandate's
premise and the honest scope is smaller — the argument is D-2-ii, the scope D-2-iii.**

**D-2-i. Verified substrate deltas (2026-07-20) — facts that decide this design:**
1. **§3.5's "sole member of `world.keyboardEventsReceivers`" is DRIFTED.** The Set has THREE member
   kinds: the caret (edit-session-scoped, added/removed only at `world.edit`/`stopEditing`);
   `SimpleSpreadsheetWdgt` (`_takeKeyboardFocus`: self-adds on interaction and deletes OTHER sheets —
   its own exclusive-focus discipline, deliberate per its comment, "full multi-sheet focus deferred";
   self-removes on destroy); `VideoPlayerWdgt` (adds itself at CONSTRUCTION, permanent; space =
   play/pause gated on `isInForeground()`). Serialization records membership (`"keyboardReceiver"`,
   Serializer:269/Deserializer:111). The spreadsheet is a THIRD editing-focus system, fully
   self-contained (own cell cursor + selection painted internally).
2. **The caret is not an "indicator" — it is the text edit-mode PROCESSOR.** `CaretWdgt` is torn down
   and RE-CREATED per session (never re-pointed), added as a child of the TARGET'S PARENT (not the
   world — "world-level" only in the singleton sense); it owns keystroke dispatch (nav/insert/delete/
   undo/clipboard/numeric gating/pop-out handoff), the slot, and a deeply settle-disciplined
   scroll-follow (`_requestScrollFollow`/`_reLayout` — the file's comments are load-bearing case law).
   ~47 `world.caret` consumer sites across 9 files; ~12 tests screenshot it, 19 caret/selection test
   dirs total.
3. **Selection is per-widget for PAINTING reasons.** `startMark`/`endMark` live on `StringWdgt` and the
   selected range is drawn by the widget's own text-drawing path; edit-session-scoped (`stopEditing`
   clears it); clipboard events reach it via `world.caret.target.selection()` (Cut/Copy/Paste input
   events). Nothing reads a selection except through the caret's target.
4. **Post-D-1 paint has NO world-level focus state to unify.** The armed tool is per-image injected
   glass handlers (serialization-carrying, live-editable); the visual feedback (the red hover square)
   is drawn BY the handler on the glass's back buffer — there is no tool-head WIDGET. Arming is NOT
   exclusive: every `ImageWdgt` is born armed, many images are paintable simultaneously, a docked
   toolbar acts on its own frame (D11). Paint focus ≠ text focus structurally: text editing is
   exclusive (one caret), paint editing is per-image-concurrent.
5. **TWO parallel chrome-exclusion mechanisms exist, expressing ONE declaration ("I am editor
   chrome"):**
   - `editorContentPropertyChangerButton` — a FIELD, checked SELF-ONLY, consumed at (a) the click
     focus-set site (`ActivePointerWdgt` ~:800) and (b) the caret-survival policy
     `stopEditingIfWidgetDoesntNeedCaretOrActionIsElsewhere` (self + a hand-rolled 2-hop
     parent-of check); hand-STAMPED onto descendants by `ChangeFontButtonWdgt` (the
     `eachDescendent.editorContentPropertyChangerButton = true` loop over its font menu — the same
     self-only disease D-1's ancestry fix cured for the other flag) and onto
     `ConsoleWdgt.runSelectionButton`. Class-field homes: `EditorContentPropertyChangerButtonWdgt`,
     `CreatorButtonWdgt`.
   - `excludedFromLastFocusTracking?()` — a METHOD, ANCESTRY-walked at the pointer's two set sites
     (D-1's `_excludedFromLastFocusTrackingByAncestry`); declared by `ToolbarWdgt`,
     `PaintToolbarWdgt`, `HorizontalMenuPanelWdgt`.
   The click site checks BOTH; the drop site only the ancestry walk (asymmetric). The caret-survival
   policy ALSO has a popup-ancestry branch (`mostRecentlyCreatedPopUp.isAncestorOf actionedWdgt`)
   which already covers menus for caret survival — the font-menu stamping exists for the focus-SET
   site only.
6. **Dangling-focus hole (verified):** `Widget._destroyNoSettle` deletes the dying widget from
   `keyboardEventsReceivers` but NOT from `world.lastNonTextPropertyChangerButtonClickedOrDropped`
   (its own TODO comment acknowledges exactly this leak class) — destroying the focused content
   leaves the register dangling, and the text buttons' feature-tests then silently act on a detached
   widget. The register is cleared only at `_softResetWorld` (error recovery).
7. **Churn surface: ZERO tests-repo identifier hits** for all three names
   (`lastNonTextPropertyChangerButtonClickedOrDropped`, `editorContentPropertyChangerButton`,
   `excludedFromLastFocusTracking`); no serialization surface (the register is never serialized).
   Exposure is purely BEHAVIORAL: the caret/selection tests, `macroTextWdgtFillModesWeightAndPaste
   OverSelection` (focus-pointer-driven Bold), `macroFontsMenuTickTracksSelection` (the stamped font
   menu), the two paint guards.
8. `world.lastEditedText` is WorldWdgt-internal (previous-target register for selection clearing on
   target switch) — no external consumers, no D-2 surface.

**D-2-ii. The finding — the four-way unification is structure-without-a-consumer; the honest D-2 is
the focus-POLICY unification.** The mandate imagined caret + paint tool-head as two world-level
overlays wanting one abstraction. D-1's ratified landing (D12) dissolved the paint half: per-image
armed handlers leave NOTHING world-level to unify, and the provenance note's "tool-heads follow the
same pattern as the Caret" is satisfied in substance — the glass feedback IS paint's caret-analogue
(transient, at the pointer, marking where editing happens), per-image rather than singleton because
paint focus is genuinely NOT exclusive (D-2-i #4). Building a `FocusWdgt`/world tool object now
would re-architect a just-landed byte-identical mechanism, break the serialization-carrying property
of injected handlers, and stand an abstraction over exactly ONE real client (text) — the §5.C/§5.B
structure-lands-WITH-its-consumer case law, third application. The caret cannot be reduced to an
indicator (D-2-i #2); selection stays on the widget for painting reasons (D-2-i #3); the receivers
Set has three self-consistent disciplines and no failing consumer (D-2-i #1). **What text and paint
now GENUINELY share is the focus-pointer POLICY layer — and there the substrate shows real disease:
two parallel exclusion mechanisms (one with hand-stamped descendants), an asymmetric click/drop
guard, and a dangling-pointer-on-destroy hole (D-2-i #5/#6). Fixing that layer IS the "one focus
model" this codebase actually needs.** (Re-open trigger, recorded so the closure is honest: a SECOND
focus client — e.g. a visible focus indicator, or a new content type wanting exclusive editing
focus — would revive the abstraction question WITH a consumer in hand.)

**D-2-iii. The design (three landings, bisectable; one fallout kind each):**
- **D2a — ONE chrome-exclusion capability.** `excludedFromLastFocusTracking` becomes the single
  "editor chrome" declaration; the `editorContentPropertyChangerButton` FIELD DIES:
  - `EditorContentPropertyChangerButtonWdgt` + `CreatorButtonWdgt` declare the method (their buttons
    remain excluded when standing OUTSIDE a toolbar; inside one, the toolbar's own declaration
    already covers them by ancestry);
  - the click focus-set site drops its field special-case → BOTH set sites become the one symmetric
    ancestry check;
  - the caret-survival policy consults the SAME ancestry walk (replacing its self-check + 2-hop
    parent-of check); its popup-ancestry branch stays untouched;
  - `ChangeFontButtonWdgt`'s descendant-stamping loop dies — the font menu opts out at its ROOT
    (mechanism at execution: the menu answers the method off an instance flag set at creation);
    `ConsoleWdgt.runSelectionButton` converts one-line.
  - **Behavior delta to ratify (D17):** clicking editor chrome that is NOT a button (a toolbar's
    background/scrollbar, the paint column) today KILLS the caret while (post-D-1) not stealing the
    focus pointer; under the unified capability it PRESERVES the caret — the editing session
    survives any interaction with editor chrome. This is the model's intent (chrome interaction ≠
    leaving the edit) but it is feel-able. Expected test exposure: none (no macro clicks toolbar
    background mid-edit — verify at execution, diffpage anything that moves).
  - ⚠ inspector exposure: this adds a METHOD to (and deletes a FIELD from) the two button bases —
    grep which classes the inspector tests display before landing (B4/D-1 case law: fields churn
    own-members panels, methods churn the one inherited-on test; neither is expected to inspect a
    button class — verify, don't assume).
- **D2b — destroy-time focus hygiene.** `Widget._destroyNoSettle` clears the focus register when the
  dying widget IS the focus (one line beside its `keyboardEventsReceivers.delete` — subtree coverage
  falls out of the per-widget destroy walk). Byte-identical ambition (no live path reads a dangling
  register in the suite); closes D-2-i #6.
- **D2c — the honest NAME (D16).** `lastNonTextPropertyChangerButtonClickedOrDropped` →
  **`editorFocusWdgt`** (proposed): the name should encode the ROLE (the content the editor chrome
  acts on), not the setting mechanism. ~30 src sites + comments; ZERO tests-repo sites; no
  serialization; zero pixels. The ancestry helper renames with it
  (`_excludedFromEditorFocusTrackingByAncestry`), and `excludedFromLastFocusTracking` itself becomes
  `excludedFromEditorFocusTracking` (same sweep, 6 declaration sites). Plan-text corrections ride
  along: §3.4's "reset on stop-editing" (already recorded drifted, D-i #3) and §3.5's "sole member"
  (D-2-i #1).
- **NOT in scope** (each with its argument in D-2-ii): a `FocusWdgt`/world tool object; caret
  re-architecture; moving `StringWdgt.selection`; restructuring `keyboardEventsReceivers` (document
  the three member kinds where §3.5 is corrected; unify only when a consumer arrives); a VISIBLE
  focus indicator (real UX idea — today nothing shows which content a floating toolbar will act
  on — but it is new owner-taste-gated UI: BACKLOG line, lands with a consumer).
- **Determinism:** all three landings are event-time policy reads/writes — no timers, no
  frame/cycle-count dependence, no paint-time state (`DETERMINISM.md` §5 clean by construction); the
  ancestry walk is tree-depth-bounded, the same cost class D-1 already pays per click/drop.
- **Gates:** per landing `fg presuite`; phase close `fg gauntlet` with revisits/census at zero.
  Ambition: D2b/D2c byte-identical; D2a byte-identical except the D17 delta's (expected-empty) test
  exposure.

**D-2-iv. Owner decisions to ratify (present BEFORE code):**
- **D15 — descoping ratification**: D-2 = the focus-policy unification (D2a–c); the four-way
  abstraction is CLOSED as structure-without-a-consumer with the argument + re-open trigger recorded
  (D-2-ii). Alternative: build the world-level focus object anyway — rejected above on three
  grounds, restated for the record: no second client, re-architects D-1's landed shape, breaks
  serialization-carrying handlers. **→ RATIFIED 2026-07-20 (owner "go ahead").**
- **D16 — the register's new name**: `editorFocusWdgt` proposed (alternatives: `contentInFocus`,
  `editTargetWdgt`; or keep the old name = D2c dropped, D2a/D2b still stand). **→ RATIFIED 2026-07-20:
  `editorFocusWdgt`.**
- **D17 — the D2a caret-survival delta** (chrome clicks preserve the caret): ratify, or gate D2a to
  the focus-SET sites only (keeping the old field alive for the caret-survival policy — two
  mechanisms remain, which defeats the landing's point; named as the fallback, not recommended).
  **→ RATIFIED 2026-07-20 (chrome clicks preserve the caret); test exposure proved EMPTY at
  landing.**

**D-2-v. Landing (2026-07-20, three bisectable landings on the D-1 base @ `c68a63cb`):**
- **D2a — one chrome-exclusion capability.** The `editorContentPropertyChangerButton` FIELD retired;
  `excludedFromEditorFocusTracking` (renamed in D2c) is the single editor-chrome declaration —
  `EditorContentPropertyChangerButtonWdgt` + `CreatorButtonWdgt` declare it `true`; `MenuWdgt` and
  `SimpleButtonWdgt` answer it off an `actsAsEditorChrome` instance flag (the font menu opts in at
  its ROOT — the `ChangeFontButtonWdgt` descendant-stamping loop is GONE; `ConsoleWdgt.runSelection
  Button` opts in directly). Both `ActivePointerWdgt` consumers (the click focus-set site and the
  caret-survival policy `stopEditingIfWidgetDoesntNeedCaretOrActionIsElsewhere`) now use the ONE
  ancestry walk — the D17 delta lives here (a click on non-button chrome preserves the caret).
  ✅ presuite 263/263, 0 paint offenders, zero recaptures.
- **D2b — destroy-time focus hygiene.** `Widget._destroyNoSettle` clears the register when the dying
  widget is-or-is-ancestor-of the focus (beside the existing caret-subtree stop-edit check; ancestry
  form covers a single-widget destroy that only orphans its children). Closes the dangling-focus
  hole (the method's own TODO). ✅ byte-identical.
- **D2c — the honest name.** `lastNonTextPropertyChangerButtonClickedOrDropped` → `editorFocusWdgt`;
  `excludedFromLastFocusTracking` → `excludedFromEditorFocusTracking` (the ancestry helper folds in
  by substring: `_excludedFromEditorFocusTrackingByAncestry`). 18 src files, ZERO tests-repo, no
  serialization, zero pixels; §3.4/§3.5 drift corrected in the same pass. ✅ byte-identical.
- **Deferred with a consumer (BACKLOG):** a VISIBLE editor-focus indicator (nothing shows which
  content a floating toolbar will act on) — new owner-taste UI, lands with its consumer; and the
  four-way `FocusWdgt` abstraction stays CLOSED until a second focus client appears (D-2-ii re-open
  trigger).
- **Case law:** (1) a MenuWdgt/SimpleButtonWdgt method add is inspector-safe (the ONE inherited-on
  test inspects a Rectangle, which descends from neither) — unlike a Widget base-method add (D-1
  case law); single-consumer capability helpers live on the narrowest honest class. (2) The
  substring fold (`excludedFromLastFocusTracking` ⊂ `_excludedFromLastFocusTrackingByAncestry`)
  makes the ancestry-helper rename ride the method rename — two sed tokens, not three. (3) fish
  word-splitting mangles a `$FILES` list and `grep -rlZ | xargs -0`; `find src -name '*.coffee'
  -exec perl … {} +` is the robust batch form (verify no de-indent with a paired -/+ whitespace-only
  diff scan afterwards — perl-on-.coffee is the standing hazard).

### E. Uniform contents protocol + read-only-as-capability
- Content enters a `FrameWdgt` uniformly via `add(startingContent)` (+ a `defaultContents` placeholder),
  retiring special `setContents(x, N)` inits (the *IconicDesktopSystem…AppLauncher* note).
- Replace `info-widgets/* extends SimpleDocumentWdgt` with a **`readOnly` capability** on `DocumentWdgt`
  (the "why do info widgets extend simple document" smell) — read-only-ness is a property, not a subtype.

**EXECUTION DESIGN for E (2026-07-20; substrate re-verified against src @ `ccaefd44`). Like D-2, the
re-validation finds most of §5.E ALREADY DELIVERED by phases A/B/D; the honest residue is one concrete
cleanup the code itself asks for (E2). The argument is E-ii, the scope E-iii.**

**E-i. Verified substrate deltas (2026-07-20) — what A/B/D already delivered vs this section's
pre-phase text:**
1. **Thread 1 (uniform contents protocol) is MOOT.** There is NO `FrameWdgt.setContents(x, N)` — `grep
   'setContents:' src` finds ONE definition, on `ScrollPanelWdgt` (`setContents: (aWdgt, extraPadding
   = 0)`), the scroll panel's own single-content API. Content already enters a `FrameWdgt` uniformly:
   the ctor takes the payload (`super @_makeStartingPayload()` for a citizen; `super contentWidget`
   for a plain frame) or `WorldWdgt.openFrameWith`, and the `defaultContents` placeholder EXISTS
   (`@defaultContents = new FrameContentsPlaceholderText`; `@contents = @defaultContents` when none
   given — FrameWdgt ctor). The 6 `setContents` call sites are all `scrollPanel.setContents(startingContent,
   5)` — seeding a scroll panel's single content with padding, not a frame init. (`defaultContents` as
   a word is also an unrelated Prompt ctor param.) So there is no special init to retire; A/B delivered
   the uniform-content-entry protocol.
2. **Thread 2's subtyping smell is MOOT (B removed it).** The 10 `info-widgets/*` are `extends
   DocumentWdgt` PURELY to host a static factory (`@create`/`@createNextTo`); 8 share
   `DocumentWdgt._buildInfoDocNextTo`, Welcome + one other are bespoke `@create`. They add ZERO
   instance overrides — namespace-only inheritance (the `TemplatesWindowWdgt` shape). "read-only-ness
   is an inheritance" is already false.
3. **Read-only today is a runtime call, and the pencil STAYS — correctly, per D8.** Read-only = a
   build-time `disableDragsDropsAndEditing()` (8 sites: the 8 info-docs via `_buildInfoDocNextTo` +
   Welcome + `SampleDoc`/`SampleSlide`/`SampleDashboard`/`DegreesConverter`/`HowToSave`). That shows
   the EYE but KEEPS the `editButton` (the citizen has `providesAmenitiesForEditing: true`), so these
   windows are re-editable via the pencil. Under **D8 (LOCKED: view mode HAS a pencil to flip into
   editing)** that is CORRECT for the editable samples — and `SystemTest_macroSampleSlideEditView
   Toggle` ASSERTS a sample slide toggles edit↔view. A "no-pencil `readOnly`" would BREAK that model
   for samples.
4. **The real residual smell: the close policy is MONKEY-PATCHED per instance.** `closeFromFrameBar`
   is overwritten by instance-method injection at 6 sites — **5× `-> @close()`** (`SampleDoc`,
   `HowToSave`, `DegreesConverter`, `SampleDashboard`, `SampleSlide` — skip the save-prompt) and **1×
   `-> @destroy()`** (`DocumentWdgt._buildInfoDocNextTo`, i.e. the 8 info-docs — discard outright).
   `DocumentWdgt`'s site carries the explicit TODO: *"should be done using a flag, we don't like to
   inject code like this: the source is not tracked."* Same untracked-instance-injection anti-pattern
   D2 just cleaned elsewhere.
5. **The close-policy homes already exist AND are duplicated.** Three `closeFromFrameBar` defs:
   `FrameWdgt` (base: `@contents?.closeFromContainerFrame @`), `DocumentWdgt`, and `GenericPanelWdgt`
   — the latter two carry a BYTE-IDENTICAL save-or-destroy body (a B-era duplication). A tracked flag
   consulted by a base method both retires the monkey-patches AND dedups the twin bodies.

**E-ii. The finding — §5.E is substantially delivered by A/B/D; the honest deliverable is E2.** The
section imagined two big changes; the re-validation shows the first is done (uniform content entry,
`defaultContents` placeholder, no `setContents(x,N)`) and the second's stated smell — read-only as an
INHERITANCE — was removed by B (the info-widgets are factories now). The provenance concerns ("why do
info widgets extend simple document"; "read-only-ness shouldn't be an inheritance") are ANSWERED. What
remains real is the close-policy monkey-patch the code's own TODO flags (E-i #4): an untracked
instance-method injection that should be a tracked property — squarely the *IconicDesktopSystem…App
Launcher* note's "a property, not injected code." A *no-pencil* `readOnly` capability is a DIFFERENT,
unrequested change that conflicts with the LOCKED D8 model for the editable samples (E-i #3, test-
asserted) — deferred, not built (E1).

**E-iii. The design:**
- **E2 (the deliverable) — close-from-frame-bar policy as a tracked capability.** ⚠ CORRECTED design
  (the base `FrameWdgt.closeFromFrameBar` does NOT save-or-ask — it DELEGATES to the content:
  `@contents?.closeFromContainerFrame @`, the live plain-frame path for `ScriptWdgt`/`ErrorsLogViewer`/
  `BasementWdgt`/generic windows whose content's `closeFromContainerFrame` decides. Only the citizens
  override with save-or-ask. So the base default must NOT become save-or-ask). Shape:
  - Introduce ONE FrameWdgt field `closeFromFrameBarPolicy` (`'saveOrAsk'` default / `'close'` /
    `'destroy'`; churn-free — no inspector test inspects a FrameWdgt's own members: they inspect
    Rectangle/AnalogClock/Inspector/String/SimpleDocumentScrollPanel).
  - `FrameWdgt.closeFromFrameBar` becomes a policy DISPATCH: `'close'` → `@close()`, `'destroy'` →
    `@destroy()`, else → `@_closeFromFrameBarWhenSaveOrAsk()`.
  - `FrameWdgt._closeFromFrameBarWhenSaveOrAsk` (the `'saveOrAsk'` hook, base) KEEPS the current
    plain-frame behaviour `@contents?.closeFromContainerFrame @` — plain frames byte-unchanged.
  - The twin citizen bodies dedup onto `FrameWdgt._saveOrAskThenCloseCitizen` (the 3-branch:
    `fullDestroy` if nothing worth saving / else `SaveShortcutPromptWdgt @, @` / else `@close()` —
    template-method: it calls the per-kind `@hasStartingContentBeenChangedByUser()`, defined on
    Document + GenericPanel). `DocumentWdgt` + `GenericPanelWdgt` replace their `closeFromFrameBar`
    with a one-line `_closeFromFrameBarWhenSaveOrAsk: -> @_saveOrAskThenCloseCitizen()`.
  - `FolderWindowWdgt`'s own 2-branch variant (no changed-check) likewise renames
    `closeFromFrameBar` → `_closeFromFrameBarWhenSaveOrAsk`, routing through the one dispatch (folders
    never set a non-default policy).
  - The 6 monkey-patch sites become a one-line field SET (`doc.closeFromFrameBarPolicy = 'close'` ×5;
    `= 'destroy'` ×1 in `_buildInfoDocNextTo`), resolving that method's TODO.
  Ambition BYTE-IDENTICAL: the close BEHAVIOUR per click is unchanged (mechanism swap only); no window
  a test screenshots changes a pixel, and `macroSampleSlideEditViewToggle` drives the edit/view
  TOGGLE, not close.
- **E1 (deferred → BACKLOG) — a no-pencil `readOnly` capability.** Argued against for now: the
  inheritance smell is already gone (B); D8's view-mode-with-pencil is the correct, test-asserted
  model for the editable samples; suppressing the pencil is unrequested UX that would wrongly lock
  them. IF the owner later wants genuinely-locked reference pages (info-docs only, never samples),
  that is a small owner-gated UI addition — a `readOnly` flag that gates `_createAndAddEditButton`
  (`… and !@readOnly`) and opens in view mode — landing with that decision, not speculatively.
- **E3 (note, no action) — the 10 namespace-only info-widget factories stay.** Each holds its `new X`
  literals in-file for the regex dependency finder (§0 build model); collapsing them into a data-driven
  registry would hide those edges from the finder. Accepted as factories, not a defect (the
  `TemplatesWindowWdgt` precedent).
- **Thread 1 (contents protocol) — CLOSED as delivered by A/B** (recorded so §5.E is not re-opened
  blind).

**E-iv. Landing (one landing; gates = `fg presuite`, close = `fg gauntlet` with revisits/census at
zero; ambition byte-identical → zero recaptures expected):**
- **E2a — the close-policy field + base dispatch + the two dedups + the 6 call-site conversions.**
  Fallout kind: none expected (behaviour-preserving); the guard is the apps smoke + any close-driving
  macro. If a `call-separation`/`stinks` gate flags the base method shape, apply the D2/B case-law
  fixes. No tests-repo surface anticipated (the sample apps are built from src; grep the tests repo
  for `closeFromFrameBar`/`closeFromContainerFrame` field reaches at execution per B case law #2).

**E-vi. Landing (2026-07-20, one landing on the D-2 base @ `ccaefd44`):**
- **E2a — close-from-frame-bar policy as a tracked capability.** `FrameWdgt.closeFromFrameBarPolicy`
  (`'saveOrAsk'` default / `'close'` / `'destroy'`) + `closeFromFrameBar` DISPATCH; the `'saveOrAsk'`
  hook `_closeFromFrameBarWhenSaveOrAsk` keeps the plain-frame delegate-to-contents base; the twin
  citizen bodies dedup onto `FrameWdgt._saveOrAskThenCloseCitizen` (`DocumentWdgt`/`GenericPanelWdgt`
  now one-line hook overrides); `FolderWindowWdgt`'s 2-branch variant routes through the same hook;
  the 6 monkey-patches → a one-line field SET (5× `'close'`, 1× `'destroy'` in `_buildInfoDocNextTo`,
  resolving its TODO). ✅ BYTE-IDENTICAL: presuite 263/263 + gauntlet 11/11 (revisits 0, census 0),
  ZERO recaptures.
- **Case law:** the extracted low-level close hooks self-settle via the public close verbs (as their
  public origin did), tripping BOTH the layering `[G]` gate (`# nosettle-sanctioned`) and the
  call-separation `[S]` gate (`# public-call-sanctioned`) — a low-level→public-self-settling call
  needs BOTH markers, and each must sit INSIDE the method body (the census/gate binds a marker to the
  method whose body contains it — a marker in the doc-comment ABOVE the signature is not counted).
- **Deferred (BACKLOG):** E1 no-pencil `readOnly` capability; the 10 info-widget factories stay as
  namespace-only static factories (dep-finder `new X` literals); thread 1 (contents protocol) closed
  as delivered by A/B.

**E-v. Owner decisions to ratify (present BEFORE code):**
- **E-D18 — scope**: §5.E = E2 (close-policy capability); thread 1 CLOSED as delivered by A/B; the
  read-only INHERITANCE smell CLOSED as removed by B. Alternative: close §5.E entirely as
  substantially-delivered and BACKLOG E2 as a standalone cleanup (E2 is small — the owner may prefer
  it folded into a later duplication sweep). **→ RATIFIED 2026-07-20 (owner "go with recommendation"):
  E2 is the §5.E deliverable; threads 1 + read-only-inheritance CLOSED as delivered.**
- **E-D19 — E1 (no-pencil `readOnly`)**: defer to BACKLOG (recommended, the D8/test argument), or
  build it now for the info-docs only. **→ RATIFIED 2026-07-20: DEFERRED to BACKLOG.**
- **E-D20 — the field's shape**: a 3-value string policy `closeFromFrameBarPolicy` (recommended, one
  field, extensible) vs two booleans (`discardOnClose`/`destroyOnClose`) — or a different name.
  **→ RATIFIED 2026-07-20: 3-value `closeFromFrameBarPolicy`.**

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
