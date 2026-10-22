# Focus and selection — the focused window and the selected desktop icon

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
**AUTHORED 2026-10-22 — NOT STARTED.** It was written against Fizzygum master `1f001744` and Fizzygum-tests master
`d7fbdd0d7` (suite 335 SystemTests; `fg gauntlet` 19/19 and `fg homepage` OK on that tree). The owner may not run
it next: when a session picks it up, re-verify §1 against the tree of that day before trusting it.
- Line numbers drift. A quoted method or field name is authoritative: grep it fresh before trusting a `file:line`.
- Keep the STATUS box below current at every phase close.

**Mandate: transformation, not a patch.** Focus and selection become two DERIVED facts of the world: one definition
each, one per-cycle place that decides each, one public query each, and every look that depends on them read from
`Theme` roles. There is no per-widget "focused" flag and no new stored state that every reordering path would have to
remember to update.

---

## STATUS
| Phase | What | State |
|---|---|---|
| P0 | Owner decisions D1–D10 (§2) locked; reference policy; review-sample additions | not started |
| F0 | Spike: the predicted focus set, per shot, from a twin prelude | not started |
| F1 | The focus mechanism, pixel-neutral (roles at today's values) | not started |
| F2 | The title's weight and fit | not started |
| S1 | The selected-icon mechanism, pixel-neutral | not started |
| S2 | Finger parity for selection | not started |
| V | The flip to the draft's values, owner review, ONE recapture wave | not started |
| Z | Close: docs, BACKLOG, archive | not started |

---

## §0 Orientation (read first)

**Fizzygum** is a CoffeeScript GUI framework, a "web OS" painted on one `<canvas>`. The umbrella `Fizzygum-all/`
holds three sibling repos: `Fizzygum/` (source; edit only `src/**/*.coffee`), `Fizzygum-tests/` (the macro
SystemTests and their reference PNGs), `Fizzygum-builds/` (generated; never edit). Read in order: the root
`CLAUDE.md`, `Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md`, `Fizzygum/src/macros/CLAUDE.md`. Two rendering
backends: native canvas (anti-aliased, production) and SWCanvas (non-AA, the suite and the owner's daily use).
Everything must look right on SWCanvas first.

**The immediately-prior arc.** The visual redesign (CLOSED 2026-10-22, `docs/archive/redesign/redesign-plan.md`)
gave Fizzygum ONE visual design system: `src/Theme.coffee` (reached as `WorldWdgt.theme`), documented present-tense
in `docs/architecture/visual-design-system.md`. Its owner decision §0.5.2 deferred two things to THIS arc:
- the draft's **focused window** look: every window today wears the draft's BACKGROUND look;
- the draft's **selected desktop icon** look, which "implies a selection model".

The redesign kept ONE derivation point for the frame look, `FrameWdgt._frameLook()`, as the hook for this arc (its
comment: "A FOCUS state would enter here, and only here"). Its risks section said: "If the focus arc lands later,
focus derives from z-order only."

**The design input** is archived beside the redesign plan: `docs/archive/redesign/UI-guidelines.md` and the
reference drawing `desktop-canvas.html` (functions `windowFrame`, `titleBar`, `windowControls`, `drawDocsMaker`,
`desktopIcon`). What it specifies:

| | Focused window (`drawDocsMaker`) | Background window (today, every window) |
|---|---|---|
| Bar fill | `chromeDark` #4A4A46 | `chrome` #E2E2DE |
| Rule under the bar | none | 1 px `line` #C9C9C4 |
| × − glyphs, pencil | `paper` #FFFFFF | `muted` #6A6A66 |
| Title | `paper`, 13 px, weight 600 (= bold on the SWCanvas atlases, redesign §0.5.1) | `muted`, 13 px, weight 500 (= regular) |
| Frame stroke | `chromeDark` | `frame` #B9B9B4 |
| Shadow | (2,2) at 16 % | (2,2) at 12 % |

- "Focus is the **only** difference between the two" (UI-guidelines §6.2).
- A docked toolbar inside the focused window keeps its light strip (`drawDocsMaker`'s embedded toolbar is `chrome`).
- Selected desktop icon (UI-guidelines §5.2, §5.3; `desktopIcon({selected})`): the tile's 1 px `line` border becomes a
  **2 px `accent`** (#2F5BEA) border; the label plate becomes an **`accent` fill with `paper` text**. The glyph does
  not change. The draft's scene shows the Docs Maker icon SELECTED while the Docs Maker window is FOCUSED.
- The draft gives no hover or pressed ink for glyphs on the dark bar (see D5).

### ⭐ The critical reframes (measured 2026-10-22)
1. **Focus needs no new state.** The event stream already maintains z-order: a left press anywhere in a window raises
   it (`Widget.pressBegan` → `bringToForeground`, which moves the window's z-order root last in `world.children`,
   back-to-front). "The focused window" is a PURE FUNCTION of that order: the frontmost eligible frame. One derivation,
   run once per cycle at a fixed point, is complete by construction. A stored flag would have to be updated by 23
   raise sites, raw child splices, every `world.add`, every close and every snapshot load, and would drift.
2. **The selection model already exists.** `world.editorFocusWdgt` is the one "last content clicked or dropped"
   widget. It is set by every click release (left AND right) and by a drop, and cleared by a click on the bare desktop.
   It is not serialized. A click on a desktop tile already makes the icon the editor focus (and opens its app at once).
   So the selected icon is that existing selection, drawn the icon's own way. The draft's own scene (icon selected,
   its window focused) is exactly what Fizzygum's single-click-opens plus the editor focus produce.
3. **The footprint is a third of the suite, not all of it.** In G's census of 298 screenshot tests and 972 shots
   (`Fizzygum-tests/.scratch/g/r2/census-raw.json`; analysis script `Fizzygum-tests/.scratch/focus/footprint.js`):
   88 tests and 255 shots show at least one top-level window, and only those can change. 24 shots show two or more
   windows, where only the frontmost goes dark. 8 tests carry a frame in the hand. Desktop icons appear in only 3
   tests, and one shot (`macroDesktopShortcutIcons` image_1) shows a clicked icon.
4. **⚠ The trap: frame looks are COPIED, and the title is a LAYOUT input.**
   - Every frame look value is copied into fields when the look is derived, and those fields are serialized. The full
     body derivation (`FrameWdgt._deriveAndSetBodyAppearance`) also wipes a hand-set body colour and corner radius. So
     a focus flip must take a NARROW re-skin path, never the full one.
   - A bold title is wider, and whether a title shows at all is decided at ARRANGE time
     (`FrameBarWdgt._titleReadsWellEnough` → `@label.numberOfCharactersThatFit()`). So a focus flip can change
     geometry, and the place that decides focus must run BEFORE the cycle's geometry settle, not in the pre-paint
     reconcilers.

### §0.5 Cold-execution protocol
1. Orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status`. Read this STATUS box, §0, §2 and the phase you
   run.
2. Re-verify §1 on the day's tree: grep each quoted method, and re-run `.scratch/focus/footprint.js` if the census
   is stale. (Re-capturing the census itself: `Fizzygum-tests/.scratch/g/r2/probe-footprint.js` produced it.)
3. P0 first: put every §2 decision to the owner (AskUserQuestion, recommendation first) and record the answers in §2.
   Nothing else starts before D1–D10 are locked.
4. Orchestration (as in the redesign, `docs/archive/redesign/redesign-plan.md` §6). The session's top model is the
   architect and gate. Opus subagents implement ONE bounded unit each, with self-contained briefs that FORBID builds,
   `fg`, commits, docs/BACKLOG/memory edits, `fg killz` and killing browsers they did not launch. Read-only spikes may
   run in parallel. Mutating agents run one at a time in the real tree, never in a worktree.
5. Owner rules: never commit or push without explicit approval, and an approval never carries over. Use
   `git commit -F <file>` and `git -C <abs repo>`. Never `git stash`. Launch long ops ONCE in the background, with an
   ETA and status every ~5–10 min, and never pipe a gating `fg` through a filter. Never `rm -rf` or `find -L` at
   `Fizzygum-builds/latest/js/tests`. Ask before going out of scope. Recaptures are owner-gated.

---

## §1 Current state (verified 2026-10-22; re-grep before trusting)

### 1.1 Z-order and raising
- `world.children` is back-to-front: the last child is topmost (`WorldWdgt`). The hand (`world.hand`) is NOT a world
  child; it paints last.
- `Widget.rootForFocus` climbs to the world child. Despite its name, it is a z-order root, not focus.
  `Widget.bringToForeground` moves that root last (`TreeNode.moveAsLastChild`), re-raises the transient pop-up band
  above it (`_transientPopUpsAboveMe`), then calls `root._fullChanged()`. `isInForeground` asks "nothing above my
  root but the pop-up band". Its only reader is `VideoPlayerWdgt`.
- **When a window comes to the front:**
  - **A left press anywhere in it.** `ActivePointerWdgt` dispatches `pressBegan`; `Widget.pressBegan` does
    `@bringToForeground()`, then escalates. Bar and button presses raise too.
  - **Presses that do not raise:**
    - a right press (`Widget`, commented out: "that's not how OSX works");
    - `PaletteWdgt.pressBegan`;
    - `SliderWdgt`'s jump-drag;
    - a selectable `StringWdgt.pressBegan`, which raises on release instead;
    - `ViewportWdgt.pressBegan`.
  - **Opened or added:** `world.add` pushes the window last, so a new window is topmost.
  - **A drop:** `drop` → `target.add` lands the payload last.
  - **Never at drag start:** the frame goes into the hand.
  - **Collapse and uncollapse do not raise.**
  - **Other raise sites (23 in src):** among them `WindowedApp`, `ErrorsLogViewerWdgt`, `HandleWdgt`
    (`@target.bringToForeground()`), `PanelWdgt.activated`, `StringFieldWdgt`, and `WorldWdgt.switchTextFieldFocus`
    (Tab).
- **Other reorderers:** `DesktopLinkWdgt.moveOnTopOfTopReference` raw-splices icons; `IconGridPanelWdgt`'s
  `_reactToChildAdded` / `_reactToChildMovedToFront` (WorldWdgt extends IconGridPanelWdgt).
- **There is no active, key or current window anywhere.** Existing "focus" words mean other things:
  - `world.editorFocusWdgt` (§1.5);
  - `world.keyboardEventsReceivers` (the caret, the spreadsheet, the video player);
  - `world.caret`, `world.lastEditedText`.

### 1.2 The frame look today
- **`FrameWdgt._frameLook()`** is a pure query.
  - Inputs: `@isTransientPopUp()`, `@isInternal()`, `preferencesAndSettings.isFlat`.
  - Fields it returns: `manifestation`, `bodyAppearance`, `bodyFill`, `bodyStroke`, `bodyCornerRadius`,
    `bodyStrokesOverChildren`, `bodyClipsChildrenToOutline`, `barAppearance`, `barFill`, `barStroke`,
    `barCornerRadius`, `barRule`, `barGlyph`, `barGlyphActive`, `titleText`, `shadowOffset`, `shadowAlpha`. There is
    no title weight field.
  - Readers: `FrameWdgt.addShadow`, `FrameWdgt._deriveAndSetBodyAppearance`, `FrameBarWdgt._buildTitleNoSettle`,
    `_buildTitlebarBackground`, `_deriveAndSetStripSkin`, `_inkGlyphButtons`.
- **Re-derivation** is `FrameWdgt._deriveAndSetSkin` (body + `@bar?._deriveAndSetStripSkin()` + `@_changed()`).
  - It runs at construction (body only), from `_reactToBeingAdded` (skipped while in the hand), from
    `_setLifetimeNoSettle` (pinning), from `fullCopy` (only on a lifetime change), and from
    `TransformFrameWdgt._reactToBeingAdded`.
  - It does NOT re-apply the shadow. That is `_updatePopUpShadow` → `addShadow`.
  - ⚠ `_deriveAndSetBodyAppearance` replaces `@appearance`, `@color`, `@strokeColor` and `@cornerRadius`. Its own
    comment says a hand-set body colour or radius "lasts until I next change parent or lifetime", so it must not run on
    every focus flip.
- **Every look value is COPIED** at derive time, none is read at paint, and all of them are serialized:

  | Piece | How it is set today | Theme role (value) |
  |---|---|---|
  | Bar fill | `background.setColor look.barFill` | `windowBarFill` = `cardBarFill` = chrome |
  | Bar rule | `appearance.ruleColor` on a fresh `BoxyAppearance`; painted only if `ruledEdge? and ruleColor?`, so an undefined rule means no rule | `barRule` (line) |
  | Frame stroke | `@strokeColor`; `BoxyAppearance` reads `@widget.strokeColor ? @widget._surfaceStroke?()` | `windowFrameStroke` (frame); `cardFrameStroke` (line) |
  | Shadow | `new ShadowInfo offset, alpha` in `@shadowInfo` at `addShadow` | `desktopShadowAlpha` 0.12, offset (2,2) |
  | Title ink | `title.color = look.titleText` at build, `@label?.setColor` at derive | `windowTitleText` (muted) |
  | Title weight | copied at construction, `@isBold = opts.bold ? fontRole.bold` | `fonts.windowTitle` (Arial 13, `bold: false`) |
  | Glyphs × − + and pencil / eye | `IconButtonWdgt.setGlyphInk` copies into `color_normal` / `color_hover` / `color_pressed`; the bar caches `glyphInk` / `activeGlyphInk`; `EditIconButtonWdgt._updateColor` swaps pencil and eye | `windowBarGlyph` (muted), `cardBarGlyph` (text2), `barGlyphActive` (ink) |
  | Grip | `@color = theme.frameGripInk` in `FrameGripWdgt`'s constructor | grip |
- `Theme`'s palette already has `chromeDark` (#4A4A46), and no role uses it. `paper`, `accent` and `accentTint` exist.
- **Caches.**
  - The only back buffer in the frame chain is the title's (`StringWdgt` / BackBufferMixin). Its key includes the
    colour and the canvas font (bold), so a flip re-renders it, and flipping back is an LRU hit
    (`world.cacheForImmutableBackBuffers`).
  - A tilted window's `TransformFrameWdgt` island buffer is damage-driven: descendant `_changed` deposits plus the
    `immutableBackBufferGeneration` epoch.
- **Snapshot load** re-adds top-level children in saved order through `_addNoSettle`, each re-deriving its skin; each
  child is the last child at its own add. Nested frames keep their saved look.

### 1.3 Focus-eligibility predicates (`FrameWdgt`)
- `isTransientPopUp` / `isPersistent`: `lifetime is 'transient' | 'persistent'`. Menus and prompts are transient. A
  pinned menu is a persistent `MenuWdgt` that wears the window look.
- `isInternal`: parent (through islands) is neither the world nor the hand. That makes cards and docked bands
  (`EdgeDockLayoutSpec`).
- `enclosingFrame`, `_parentThroughIslands`, `Widget.isVisible` (a boolean FIELD, not a method; the query is
  `visibleBasedOnIsVisibleProperty()`), `collapsed`.
- **A tilted window:** its world child is a `TransformFrameWdgt` island holding the frame.
- **A frame in the hand:** `parent = world.hand`; its skin is frozen until it lands.
- **The error console** is a HIDDEN world-child `FrameWdgt`.
- **The bin:** `BinOpenerWdgt` opens a `FrameWdgt`.
- **Folder windows:** `FolderWindowWdgt extends FrameWdgt`.
- **The Inspector** is either framed or a naked `world.add new InspectorWdgt` (not a frame).
- Non-frame world children (icons, the clock, tooltips, loose widgets) are interleaved with frames.

### 1.4 The world cycle (`WorldWdgt.doOneCycle`), in order
1. events: `_playQueuedEvents`, then replayed test commands;
2. `_runChildrensStepFunction`;
3. `dataflow.recalculateDataflow`;
4. `storageSorter.drainPendingSort`;
5. `_drainPendingFractionalBookkeepingSeeds`;
6. **`recalculateLayouts`**;
7. the hover re-sync;
8. `pinouts?.reconcile`, `addHighlightingWidgets`;
9. **`_updateEditorSelectionOverlay`**: a PULL reconciler, once per cycle, before paint;
10. `addDragAffordanceWidgets`;
11. `_repaintDamagedRects`.

The selection reconciler is the precedent for a per-cycle derived fact. It caches `_editorSelectedWidget`, calls
`_changed()` on the old and new widget (cross-invalidation-sanctioned, PULL model), and answers the public O(1) query
`isEditorSelected`.

### 1.5 The existing selection (editor focus)
- `world.editorFocusWdgt` holds one widget (a TODO at `WorldWdgt` mentions a future list). Its one write is
  `WorldWdgt._setEditorFocusNoSettle`.
- **Who sets and clears it:**
  - `ActivePointerWdgt`: the release of a click that pressed and released on the same widget, for BOTH `activated`
    and `contextMenuRequested`, unless `_excludedFromEditorFocusTrackingByAncestry`;
  - a drop (the dropped widget);
  - `Widget`'s destroy, which clears it;
  - `_softResetWorld`, which clears it.
- **What does not set it:** a finger hold or a finger plain drag (that is the BACKLOG item "a finger does not select
  what a mouse selects"). No keyboard path sets it, and Escape does not clear it.
- Clicking the bare desktop sets focus = world, which reads as "no selection".
- Chrome opts out with `excludedFromEditorFocusTracking`: `FrameBarWdgt`, `IconButtonWdgt`, `MenuWdgt`, `HandleWdgt`,
  `LayoutChromeWdgt`, `SimpleButtonWdgt`, `SliderWdgt`, `SliderButtonWdgt`, `ToolbarWdgt`, … No desktop-icon class
  opts out.
- **The ring.** `_widgetBeingEdited` decides which widget is framed by the 2 px accent ring
  (`HighlightOutlineAppearance.paintRing`, via `Widget._paintEditorSelectionOverlayIfSelected`). It returns nothing
  for a bare desktop selection and nothing while a caret is in the focus. So today:
  - an icon on the desktop shows NO ring when selected;
  - an icon inside a folder window gets the generic SQUARE ring around its whole cell box, because `FolderPanelWdgt`
    inherits `PanelWdgt`'s editing amenities. No test shows this.
- Other "selected" notions are local and stay as they are: `ListWdgt.selected`, the sheet's selected cell, text marks,
  `ChipWdgt.isCurrent`, member rows, the armed paint tool.

### 1.6 Desktop icons
- **Classes:** `WidgetHolderWithCaptionWdgt` → `DesktopLinkWdgt` (adds `HighlightableMixin`; `_showsChildAsAPicture`
  makes the glyph a picture, so presses reach the holder) → `AppLauncherWdgt`, `BinOpenerWdgt`, `ShortcutWdgt` →
  `DocumentShortcutWdgt`, `FolderShortcutWdgt`, `ScriptShortcutWdgt`.
- **Where they live:** desktop icons exist only on the index page (`createDesktop`, guarded by
  `theWorld.isIndexPage`). Test worlds have none unless a test makes them.
- **Input:**
  - A click or tap on the tile opens at once (`_activateMyTile`); a double click is swallowed (it acts once).
  - A click on the plate starts a rename (a caret in the caption).
  - A press and drag MOVES the icon; a finger arms at once on the desktop.
  - A right-click or finger hold opens the context menu.
  - Hover gives the `desk` tile (`HighlightableMixin` `state`).
- **`DesktopIconAppearance`:**
  - The tile fill and the tile border are read at paint by state (`_fillForMyState`, `_strokeForMyState`), with
    `ctx.lineWidth = 1` HARD-CODED.
  - The plate fill is read at paint (`desktopIconPlateFill`, plate).
  - The caption ink is COPIED at build (`@label.color = theme.desktopCaptionText`) and is part of the label's
    back-buffer key.
  - The glyph ink is copied at build.
- **Precedent for white on accent:** `textSelectionFill = accent`, `textSelectionText = paper`.
- ⚠ `visual-design-system.md` §4.8 says "Selected and 'on' controls use the `accentTint` fill with an `accent`
  border and text". The draft's SOLID accent plate departs from that (D8).

### 1.7 Tests and rigs that read what this arc changes
- **The 88 window tests** of reframe 3. F0 replaces the census estimate with an exact per-shot list.
- **Assertions on frame look values:** `macroTiltingWindowKeepsInternalExternalSkin` asserts
  `w.strokeColor.equals(theme.windowFrameStroke)`, which a focused window fails. Re-express it by meaning: the window
  skin is "the look `_frameLook()` answers", or name the focused role.
- **Z-order and shadow tests to re-read:** `macroPinnedMenuKeepsCorrectShadowWhenBroughtToForeground` (a focused
  pinned menu's shadow becomes 16 % under D1),
  `macroSelectionOverlaySurvivesBringToFront`, `macroSaveAsPromptAboveTiltedWindow`.
- **Selection assertions:** `macroEditorFocusIndicatorTracksEditedWidget` (5 `isEditorSelected` asserts) and
  `macroSelectionOverlaySurvivesBringToFront` (2).
- **Icons:** `macroDesktopShortcutIcons` (clicks the folder icon before image_1), `macroSavedDocumentShortcutIcon`,
  `macroDeletingMenuNestedInShortcutIconTerminates` (assertions only).
- **Rigs that click icons:** `smoke-apps-headless.js`, `parts-lazy-icons-headless.js`, `parts-lazy-load-headless.js`
  and `staleness-census.js` call `icon.activated()` with no position, which never sets the editor focus. They would
  break only if a click came to mean "select" instead of "open", which this plan does not do. No rig reads a frame look
  role (checked: `_frameLook`, `windowBarFill`, `windowTitleText`, `windowFrameStroke`, `desktopShadowAlpha`,
  `barGlyph`).
- **A doc contradiction found while researching:** `docs/architecture/regularity-principles.md` ("The frame model")
  says a pinned menu "keeps the body colours it was born with". The code (`FrameWdgt`, the pinned-menu branch) and
  `visual-design-system.md` §5 say a pinned menu wears the window's skin. Fix the doc in this arc (Z).

---

## §2 Owner decisions to lock at P0 (recommendations first)

- **D1 — Which frames can be focused.**
  - Recommended: a visible, persistent, non-internal `FrameWdgt` that is a world child, or the frame inside a world
    child transform island. That covers windows, folder and bin windows, and pinned menus (they wear the window look).
  - Never: transient menus and prompts (a menu over a window leaves the window focused, as on macOS), cards, docked
    bands, the hidden error console, or non-frames.
  - The focused frame is the FRONTMOST eligible one. If none is eligible, nothing is focused.
- **D2 — A window being dragged.**
  - Recommended: a persistent frame in the hand IS the focused frame for the whole carry. A press raised it before the
    grab, so it was already focused.
  - The alternative, the frontmost world child, flips focus to the window behind for the length of every drag and back
    on drop: two repaints of two windows and a visible flicker. 8 tests carry a frame.
- **D3 — A press on the bare desktop.**
  - Recommended: it changes nothing. Focus follows z-order, and a desktop press raises nothing; it clears the
    SELECTION, not the focus.
  - The alternative, "the desktop takes focus and every window turns light", needs stored state (a stored "desktop is
    focused" flag) and the event paths to clear it. Rejected unless the owner wants macOS's Finder behaviour.
- **D4 — The title's weight and fit.**
  - Recommended: the focused title is bold (the draft's 600), and a title's fit is ALWAYS measured in the focused
    weight. A title then shows the same characters whether or not its window is focused, and a focus flip never makes
    a title appear or disappear. The cost: a borderline background title loses a character or two, changing a few
    shots, which F2 measures first.
  - Alternative (b): re-fit on every flip, so a title can shorten or vanish when focused.
  - Alternative (c): no weight change, so focus is colour only (a deviation from the draft).
- **D5 — Glyph hover on the dark bar.** The light bar's hover ink is `ink`, which is invisible on `chromeDark`, and the
  draft defines nothing.
  - (i) Recommended: rest `chrome` #E2E2DE, hover and pressed `paper`. That is a small deviation from the draft's
    `paper` at rest, and keeps W1's ruling "hover = recolour, no plate".
  - (ii) Rest `paper` as drawn, with hover and pressed drawing a `muted` rounded-6 plate behind the glyph. That needs a
    plate mechanism the bar does not have.
  - The owner decides on the live preview at V.
- **D6 — Which icon is "selected".**
  - Recommended: the holder that is `world.editorFocusWdgt`, on the desktop or in a folder or bin window. A tile click
    therefore selects the icon AND opens it (single click keeps opening). A right-click or menu selects it, and a drop
    selects it. A click elsewhere moves the selection; a desktop click clears it.
  - The generic ring is suppressed on holders: the icon's own selected look replaces it.
- **D7 — The caption being renamed.**
  - Recommended: no selected look while a caret is in the caption, the same rule as the ring ("none while a caret is
    in it"). The plate stays `plate` with ink text, so the caret stays readable.
- **D8 — The selected plate.**
  - Recommended: follow the draft, a solid `accent` plate with `paper` text, and reconcile `visual-design-system.md`
    §4.8: "a selected LABEL reads like selected text (solid `accent`, `paper` ink), the text-selection precedent; a
    selected CONTROL uses `accentTint`".
  - The alternative is an `accentTint` plate with `accent` text.
- **D9 — Finger parity.**
  - Recommended: a finger HOLD that opens a context menu sets the editor focus exactly as a right-click release does,
    so a finger user sees which icon or widget the menu acts on.
  - A finger plain DRAG on a canvas or scroll pane stays non-selecting, because it scrolls (the mouse-drag-selects half
    of the BACKLOG item stays there, its own decision).
- **D10 — Where the references land.**
  - Recommended: on master directly, both repos, one owner-approved commit pair per phase that changes pixels. The
    redesign's close measured that a whole multi-wave tests branch cost 78 MB, so a branch-and-squash buys nothing
    here.
  - The alternative: `focus` branches in both repos, merged whole at Z, as the redesign did.
- **Also at P0:** add to `docs/tooling/visual-review-sample.txt` the tests that show two windows (the focus contrast)
  and `macroDesktopShortcutIcons`.

---

## §3 The distilled argument
- **Why derive.** Every way a window can become frontmost (press, open, drop, close of the one in front, Tab, a
  handle, a snapshot load) already ends in `world.children`'s order. Reading the order once per cycle gives the right
  answer for all of them, including the paths nobody listed. A stored flag would be right only on the paths someone
  remembered.
- **Why once per cycle, before layout.** A snapshot load adds windows one by one, each the last at its own add, so a
  decision made at add time would focus each window in turn. The cycle's fixed point sees the final order. Placing the
  decision before `recalculateLayouts` lets a weight change re-arrange the title in the same cycle, so paint never sees
  a half-flipped strip. It is a pure function of the event stream, which is the determinism contract
  (`Fizzygum-tests/DETERMINISM.md` §3).
- **Why a narrow re-skin.** The full body derivation is the parentage/lifetime derivation, and it owns resetting
  hand-set looks. Focus changes only the bar strip, the frame stroke and the shadow, so a flip touches exactly those.
- **Why reuse the editor focus.** It is already the user's "the thing I last touched", and it is set by exactly the
  gestures the draft's selected icon implies. A second selection model would disagree with it.
- **Why two steps for each flip** (the redesign's G-E lesson): land the mechanism with every new role at the value
  that shows today. Prove it pixel-neutral, with the suite's failing set unchanged and a probe that byte-compares
  surfaces with a pre-change dump. Then flip `Theme` alone and check the changed set against the predicted one.

---

## §4 Phases and units
Each unit is ONE bounded brief with acceptance criteria. Gate every unit with `fg presuite` AND `fg revisits` (the
redesign learned that a pixel-clean presuite can hide re-visits), plus its probe. Probes go under
`Fizzygum-tests/.scratch/focus/`.

### P0 — Decisions and set-up (orchestrator)
- Lock D1–D10 with the owner. Record the answers inline in §2.
- Apply D10's reference policy.
- Add the review-sample tests.
- Fix nothing yet.

### F0 — Spike: the predicted focus set (read-only research agent; browsers against the existing build allowed)
- **Write an in-page TWIN prelude.** It computes D1+D2's focused frame at every screenshot without changing src, using
  the twin-prelude method (memory note `residue-followups-arc-2026-10-16`: `PRELUDE_JS` with
  `run-macro-test-headless.js`, or `AUDIT_PRELUDE` + `AUDIT_ECHO=1` with the parallel runner). Run it over the suite
  at mouse and finger, dpr 1.
- **Output, per test and shot:** the focused frame (class and title), the number of eligible frames, any shot where
  the focus differs between consecutive shots with no press in between, and any shot whose focused frame is
  hand-carried.
- **Also measure D4:** for every title in every shot, does it keep the same characters when its fit is measured in
  bold?
- **Acceptance:** an exact predicted set (tests and shots) for F's flip and for D4, and a list of "surprising" focus
  answers for the owner.

### F1 — The focus mechanism, pixel-neutral
- **`WorldWdgt`:**
  - a cache `_focusedFrame` and a pure query `_deriveFocusedFrame()`. Per D2, the hand's carried persistent frame
    wins. Otherwise walk `@children` from last to first: skip invisible widgets and non-frames, unwrap a
    `TransformFrameWdgt` island to its frame, skip transient and internal frames, and return the first match;
  - a public O(1) query `isFocusedFrame(f)`, the `isEditorSelected` pattern;
  - a station `_updateFocusedFrameNoSettle()`, called ONCE in `doOneCycle` right BEFORE `@recalculateLayouts()`
    (after `_drainPendingFractionalBookkeepingSeeds`), with a comment stating why it sits there (reframe 4).
  - On a change, the station asks the previous frame (if it is still in this world) and the new one to re-skin,
    through ONE intent-named public method on `FrameWdgt` (the invalidation-privacy rule, gate
    `check-invalidation-receivers.js`).
- **`FrameWdgt`:**
  - `_frameLook()` takes focus as an input (`world.isFocusedFrame @`). Its persistent-window branch answers the
    focused roles when focused: bar fill, bar rule (undefined means none), bar glyph, active glyph, title ink, a NEW
    title-weight field, body stroke, shadow alpha.
  - The narrow re-skin: `@bar?._deriveAndSetStripSkin()`, the body stroke only, and the shadow (re-applied with the
    look's alpha through `addShadow`'s path). NEVER `_deriveAndSetBodyAppearance`. Each part self-invalidates, and
    the strip re-arranges if the title weight changed.
- **`FrameBarWdgt`:** the title takes its weight from the look, at build and at re-skin.
- **`Theme`:** new roles, all at TODAY's values in this unit: `focusedWindowBarFill` (chrome),
  `focusedWindowBarRule` (line), `focusedWindowBarGlyph` (muted), `focusedWindowBarGlyphActive` (ink),
  `focusedWindowTitleText` (muted), a focused title font role (bold false), `focusedWindowFrameStroke` (frame),
  `focusedWindowShadowAlpha` (0.12). Name them for the surface, in the redesign's style.
- **Acceptance:**
  - presuite: the failing set unchanged (empty), revisits clean;
  - the F1 probe passes every scenario below, asserting `world.isFocusedFrame`. In a second pass it flips the
    roles in-page to the draft values and checks the pixels of BOTH the newly focused and the newly unfocused frame:
    1. two windows: the later-opened one is focused; a press on the other's body moves focus, and the first one
       re-skins light;
    2. a menu over the focused window leaves it focused; pinning the menu focuses the pinned menu (D1);
    3. dragging a window by its bar: it stays focused while carried (D2) and when dropped;
    4. closing the focused window focuses the next eligible one;
    5. collapsing the focused window keeps it focused (a dark collapsed strip, all corners rounded, no rule);
    6. a tilted window is focused through its island, and its island buffer repaints on a flip;
    7. pressing a card or a docked toolbar inside window A focuses A, never the card or the band;
    8. the hidden error console is never focused, and a world with no frame focuses nothing;
    9. a desktop press leaves focus unchanged (D3);
    10. save and load a world with three windows: after the load only the topmost is focused, in its pixels too;
    11. `fullCopy` of a window: the copy lands topmost and focused, and the original re-skins;
    12. a hand-set body colour on a window survives three focus flips.
  - Under these Theme roles nothing changes in the suite. A new station is a hook path, so F1 also closes on a full
    `fg gauntlet` (its settle and capstone legs see what presuite cannot).
- **⚠ Hand-set looks:** a hand-set frame STROKE colour is lost on a flip unless the stroke reads its focus role at
  paint. The unit decides: either the frame holds no stroke (`strokeColor` undefined) and answers `_surfaceStroke`
  from the look at paint (the G-E pattern), or the loss is documented beside `_deriveAndSetBodyAppearance`'s
  existing note. Prefer the paint-time read.

### F2 — The title's weight and fit (after F1; D4)
- Implement D4. Recommended: `FrameBarWdgt._titleReadsWellEnough` and the title's ellipsis fit use the focused weight
  ALWAYS, and the label's drawn weight follows the look.
- **Acceptance:** presuite changes exactly F0's D4-predicted set (an empty set is possible) and nothing else; revisits
  clean.
- If the set is non-empty, it joins V's review and recapture.

### S1 — The selected-icon mechanism, pixel-neutral (after F1; independent of F2)
- **`WorldWdgt`:** in `_updateEditorSelectionOverlay` (the pre-paint PULL reconciler; selection changes paint only),
  also cache `_selectedIcon` = the holder that is `editorFocusWdgt` (D6, D7), invalidating the old and new holder.
  Add a public query `isSelectedIcon(holder)`.
- **Holders** (`WidgetHolderWithCaptionWdgt` family): opt out of the generic ring (`_showsSelectionOverlay` false, or
  the walk skips them), and paint their own selected look:
  - **tile border:** a role colour and a role WIDTH, replacing the hard-coded `ctx.lineWidth = 1`. Draw it through the
    shared ring painter `HighlightOutlineAppearance.paintRing` (one ring painter; on SWCanvas a rounded outline that
    must hug a fill is drawn as a FILL, the redesign's G-C/G-D lessons);
  - **plate fill:** a role;
  - **caption ink:** READ AT PAINT through a hook asking the holder (the label holds no colour), keyed into the
    label's back-buffer key, as the redesign's E2 did for the default text ink.
  - The tile's state fill (rest, hover, pressed) and the selection border combine; the selection decides the border
    and the plate.
- **`Theme`:** `desktopIconTileSelectedStroke` (line), `desktopIconTileSelectedStrokeWidth` (1),
  `desktopIconPlateSelectedFill` (plate), `desktopIconCaptionSelectedText` (the caption's ink): all at today's values.
- **Acceptance:**
  - presuite failing set unchanged. Expected empty: the only folder-window ring that would vanish is in no test.
    Verify that.
  - a probe on the index page and in a folder window: click an icon → `isSelectedIcon`; desktop click → cleared;
    rename → no selected look; drop an icon → selected; right-click → selected. Run a second pass with the roles
    flipped in-page to the draft values, with pixel checks.

### S2 — Finger parity (after S1; D9)
- A finger hold that dispatches `contextMenuRequested` (`ActivePointerWdgt`'s hold path) sets the editor focus through
  `_setEditorFocusNoSettle` under the same ancestry opt-out as the click path.
- **Acceptance:** presuite at `--pointer=finger` (`node scripts/run-all-headless.js --pointer=finger` from
  `Fizzygum-tests/`, plus `fg finger`). The finger references that change are exactly the shots where a hold now
  selects; F0's prelude can list them first. Each is a picture to eyeball before the recapture, not a fix.
- Update the BACKLOG item "a finger does not select what a mouse selects" (its hold half is done here; its drag half
  stays).

### V — The flip, review and ONE recapture wave
1. **Flip `Theme`** to the draft's values:
   - focused window: bar `chromeDark`, no rule, glyphs and title per D5 and D4, stroke `chromeDark`, shadow 0.16;
   - selected icon: border `accent` 2 px, plate `accent`, caption `paper`.

   Re-express `macroTiltingWindowKeepsInternalExternalSkin`'s skin predicate by meaning. Re-read the §1.7 tests and
   update their prose and assertions where the focus look is now part of what they state.
2. `fg presuite`: the changed set must equal F0's prediction plus F2 and S2's sets. Every needs-a-fix or AIM MISSED
   is fixed first; never recapture over one.
3. **Owner review:**
   - `fg diffpage $(grep -v '^#' Fizzygum/docs/tooling/visual-review-sample.txt)` from `Fizzygum-all/`, plus the
     focus tests;
   - the live worlds: `Fizzygum-builds/latest/index-sw.html` (SWCanvas) and `index.html` (native). Open two windows
     and click between them, drag one, pin a menu, tilt a window, collapse one, and click and right-click desktop
     icons.
   - The owner settles D5 here.
4. **Recapture**, backgrounded, with ETA and status: `fg recapture --auto --dprs=1,2`, then the finger equivalent.
   ⚠ A Monitor on a recapture log must grep the verdict tokens (`RECAPTURE COMPLETE|INCOMPLETE|INCONCLUSIVE|
   needs-a-fix|UNSTABLE`), never "FAIL": the discovery pass prints "STILL FAILS single-process" per stale test.
   Regenerate the visualisation page of every test edited but not recaptured (`node scripts/make-visualisation.js
   <Test>`).
5. **Close gates:** `fg gauntlet`, `fg homepage`. Then propose the commit pair (D10).

### Z — Close
- **Docs:**
  - `visual-design-system.md`: §2 (`chromeDark` in use), §4.8 (D8's reconciliation), §5 rows for the focused window
    and the selected icon, §6 ("does my surface depend on focus or selection?");
  - `regularity-principles.md` "The frame model": focus as a derived input of the frame look, and fix the pinned-menu
    contradiction of §1.7;
  - `input-and-gestures.md`: the finger hold selects;
  - `widget-authoring-guidelines.md`, if a new hook is part of the authoring surface.
- **BACKLOG:** close this plan's items, and move the closed ones into a trailing ledger here.
- `git mv` this plan to `docs/archive/`, stamp it, and add an INDEX line.
- Update the memory note and run `/close-arc`.

---

## §5 Central risks
1. **A stale look after a flip.** If the previous frame is not re-skinned, two windows look focused. Mitigation: the
   station always re-skins both, and probe scenarios 1, 4, 10 and 11 check both frames' pixels. The gauntlet's paint
   audit catches a missed invalidation.
2. **Focus flicker.** Focus moving during a drag, a menu or a load. Mitigation: D1, D2, the fixed-point station, and
   F0's "focus changed with no press" report.
3. **Layout coupling.** A weight flip re-arranges the bar. Mitigation: the station runs before `recalculateLayouts`;
   `fg revisits` per unit, and the gauntlet's settle and capstone legs.
4. **Copied looks.** A saved world carries the focused look of whatever was frontmost. Mitigation: load re-derives
   top-level frames and the station corrects the same cycle (probe scenario 10). Add a check to the serialization rig
   (`Fizzygum-tests/scripts/serialization-roundtrip-headless.js`): save two windows, load, and assert exactly one
   focused.
5. **Hand-set looks wiped** by a flip. Mitigation: the narrow re-skin; probe scenario 12.
6. **Determinism.** The station reads only z-order, which is event-driven: no timers, no cycle counts. The gauntlet's
   dpr 2 and WebKit legs under parallel load are the proof.
7. **Tests whose meaning involves focus** (§1.7). Re-express them by meaning before the recapture; never bake a
   changed assertion in with pixels.
8. **Rigs.** Grep `Fizzygum-tests/scripts/` for every renamed or new role at each unit (the redesign's "a
   cross-repo rename MUST grep scripts/" lesson).

---

## §6 Verification protocol
- **Per unit:** `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (expected failing set stated in the unit),
  `fg revisits`, and the unit's probe against a fresh build. F1 also closes on `fg gauntlet`: its settle and capstone
  legs are not standalone `fg` subcommands.
- **Finger:** `node scripts/run-all-headless.js --pointer=finger` from `Fizzygum-tests/` (dpr 1, ~2 min) and
  `fg finger`.
- **Phase close:** `fg gauntlet` (19 legs) and `fg homepage`.
- **Recapture:** `fg recapture --auto --dprs=1,2` and the finger wave. ⚠ Build first: the discovery pass runs the
  suite against the existing build.
- Static gates run in every build (`docs/architecture/lint-and-static-checks.md`). Expect `raw-chrome-color` to stay
  at 0: every new colour is a `Theme` role.

## §7 Rejected alternatives (do not re-attempt)
- **A stored focus flag or a `world.focusedWindow` field set by event handlers.** It must be updated on 23 raise sites,
  raw splices, adds, drops, closes and loads, and it drifts; the derivation is complete by construction (reframe 1).
- **Deciding focus at add time or inside `bringToForeground`.** It misses closes (the next window must become focused)
  and loads (each child is last at its own add).
- **Deciding focus in the pre-paint reconcilers.** A weight change is a layout input (reframe 4).
- **Re-skinning through `_deriveAndSetBodyAppearance`.** It wipes hand-set body colour and radius on every flip.
- **The accent for window focus.** The draft's window focus is `chromeDark`. The accent is for focused or selected
  CONTROLS and the selected icon.
- **The generic 2 px ring for a selected icon.** It is square around the whole cell box and wraps the plate; the draft
  gives icons their own look.
- **Select-on-click, open-on-double-click for icons.** It is a behaviour change outside this arc's surface ("keep the
  original's structure and fix its surface", UI-guidelines §10). The rigs open icons with a positionless
  `activated()`, and the draft's scene is consistent with single-click-opens. The owner may open it as its own arc.
- **Multi-selection or a rubber band.** Out of scope. `WorldWdgt`'s TODO about a list of selected widgets stays as is.

## §8 References
- `docs/archive/redesign/redesign-plan.md` (§0.5.2, §5 risk 5, the W1 decisions: bar hover = recolour, pinned menu =
  window look); `docs/archive/redesign/UI-guidelines.md` §1, §2, §3, §5.2, §5.3, §6.1, §6.2;
  `docs/archive/redesign/desktop-canvas.html` (`windowFrame`, `titleBar`, `windowControls`, `drawDocsMaker`,
  `desktopIcon`).
- `docs/architecture/visual-design-system.md`, `regularity-principles.md` ("The frame model"),
  `input-and-gestures.md`, `appearance-paint-convention.md`, `layout.md` (settle tiers),
  `lint-and-static-checks.md`.
- `Fizzygum-tests/DETERMINISM.md`; `docs/tooling/visual-review-sample.txt`.
- Measurement: `Fizzygum-tests/.scratch/focus/footprint.js` over `Fizzygum-tests/.scratch/g/r2/census-raw.json`
  (`.scratch` is gitignored and local: if it is gone, re-run the census with `.scratch/g/r2/probe-footprint.js`'s
  method).
- Memory notes: `fizzygum-visual-redesign-arc` (its G-E lessons: two-step flips, read where used),
  `residue-followups-arc-2026-10-16` (the twin prelude), `swcanvas-reproduces-what-native-hides`.

## Sizing (estimate)
2–3 sessions: P0 + F0 + F1, then F2 + S1 + S2, then V + Z. ONE recapture wave of about 90 tests at mouse and finger,
dpr 1 and 2 (about an hour since R0).

## Start prompt for a fresh session
> Run the Fizzygum focus-and-selection plan cold: `Fizzygum/docs/plans/focus-and-selection-plan.md` (authored
> 2026-10-22, not started). Orient with `/Users/davidedellacasa/code/Fizzygum-all/fg status`, read the plan's STATUS
> box, §0 and §2, and re-verify §1 against today's tree (it was written against Fizzygum `1f001744` / Fizzygum-tests
> `d7fbdd0d7`). Start with P0: put decisions D1–D10 to me, recommendation first, and record the answers in §2. Then
> run F0 and the next unstarted units in orchestration mode (§0.5). Never commit, push or recapture without my
> approval.
