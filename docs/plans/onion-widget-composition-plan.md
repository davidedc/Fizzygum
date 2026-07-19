# The Frame model — naked capability → manipulable citizen → App

**STATUS: AUTHORED 2026-07-18, REVISED 2026-07-18, RE-VERIFIED 2026-07-19 — design-stage, NO code written yet. Owner-gated execution.**
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
- `WorldWdgt.openWindowWith(contentWidget, extent, position)` is the single fresh-frame wrap.
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

### 3.4 The external-toolbar editing model already exists (for text)
- **Focus pointer:** `WorldWdgt.lastNonTextPropertyChangerButtonClickedOrDropped`, set on every content
  click/drop by `ActivePointerWdgt`, reset on stop-editing. Toolbar buttons + `excludedFromLastFocusTracking`
  opt-outs don't steal it.
- **External buttons:** the `EditorContentPropertyChangerButtonWdgt` family (`buttons/`, `extends IconWdgt`)
  — Bold/Italic/FormatAsCode/ChangeFont/±FontSize/Align — each `mouseClickLeft` feature-tests then calls the
  content API (`toggleWeight`/`setFontName`/`alignLeft`…) on the focus pointer.
- **Floating toolbar:** `ToolbarCreatorButtonWdgt._buildToolWindow` builds a standalone `WindowWdgt` of
  buttons; `TextToolbarCreatorButtonWdgt` fills the text one; **`ToolbarsApp`** is the "Super Toolbar".
- **Embedded toolbar (the duplication to fix):** `SimpleDocumentWdgt._createToolsPanelNoSettle` and
  `StretchableEditableWdgt.toolsPanel` build a toolbar *inside* the editor — a parallel construction to the
  floating one.
- **Editing is a capability:** `providesAmenitiesForEditing`, `enable/disableDragsDropsAndEditing`,
  `editButtonPressedFromWindowBar`, `showEditModeInBar`/`showViewModeInBar`,
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
- **A2b — compose bar + content-container + stable toolbar-slot (design-first, separate landing).**
  The real structural re-shape: a bar child (title/close/collapse/pencil-eye), a content-container
  child with the toolbar-slot, `_positionAndResizeChildren` re-written over the composed parts. Sketch
  the child structure + serialization migration + macro-contract preservation (`.label`,
  `.closeButton`, `.contents` stay reachable as the same instances) in this section BEFORE cutting
  code; expect conscious recapture. Its design intertwines with C (the slot's occupant) — author the
  sketch with C's §5.C in view.

### B. Split fused content classes into naked payload + framed citizen
Per §3.3: introduce `SimpleTextWdgt` (from `SimplePlainTextWdgt`; role `TitleWdgt`), `SimpleImageWdgt`
(from `RasterImageWdgt`), and the framed citizens `DocumentWdgt`/`ImageWdgt`/`SlideWdgt`/`DashboardWdgt`/
`SpreadsheetWdgt` (`extends FrameWdgt`, each thin — the frame does the chrome work). Fold
`StretchableEditableWdgt`'s container+toolsPanel role up into `FrameWdgt`. Apply the intrinsic-framing rule
(§1.1): text stays naked; everything needing a toolbar/handles becomes framed.

### C. One `ToolbarWdgt` per content TYPE, docked-or-floating; one edit-mode toggle
Make `ToolbarWdgt` the single shared toolbar construction (from `ToolPanelWdgt` + the floating
`WindowWdgt`-of-buttons construction), with **one variant per content type** (text / paint / slide / …), not
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
| D6 | `Simple*` vs `Basic*` prefix | Open (lean `Simple*` — the established prefix; `basic-widgets/` folder makes `Basic*` read oddly). |
| D7 | Naked-text class/role | `SimpleTextWdgt` + a `TitleWdgt` role — confirm whether `TitleWdgt` is a thin subclass or just a styled `SimpleTextWdgt`. |
| D8 | Does text-entry (caret) get gated by edit mode inside a `DocumentWdgt`? | Open — recommend yes (view = published/locked; edit = caret + toolbar). |
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
