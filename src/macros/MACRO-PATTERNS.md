# Macro reuse patterns (the per-mechanic catalogue)

Worked patterns distilled from the migrated macro tests — **what** framework behaviour each exercises,
**which verbs** drive it, the **test** that demonstrates it, and the **gotchas**. This is the detailed
reference; the lean router is `CLAUDE.md`, the migration *workflow* is the `migrate-systemtest` skill
(`../../../Fizzygum-tests/.claude/skills/migrate-systemtest/`), and the verb *signatures* are the
doc-comments in `MacroToolkit.coffee`. "No new verb" means the pattern is pure reuse of existing verbs.

Conventions used below: `@x` = a MacroToolkit helper; `world.x` = the live world; a bare `…_InputEvents_Macro`
call is an L3 verb. Drive every USER input through the event queue (`_InputEvents` verbs); only fixture
construction and genuinely-blocked UI triggers (`hide()/show()`, `toggleSoftWrap()`, `world.evaluateString`)
are called directly. See `CLAUDE.md` for those rules.

---

## Text & caret

- **Caret placement by click** (`macroTextMorph2CaretPlacementByClick`): clicking inside an EDITABLE text places
  `world.caret` at the nearest slot (`StringMorph2.mouseClickLeft`, `:1242`, gated on `@isEditable`). A
  directly-built StringMorph2/TextMorph2 has **`isEditable = false`** (`:43`) — set `txt.isEditable = true` first
  (the demo widgets do). `@moveToAndClickAtFractionOf_InputEvents txt, [fx, fy]` places the caret on the clicked
  line: `[0.02, firstLineFrac]` before the first letter; a click past the last line's end clamps after the last
  letter. Size the widget so the wrapped text FITS (a cropped one opens the "edit:" prompt instead).
- **Caret arrow-key navigation** (`macroCaretArrowKeyNavigation`): once `world.caret` is editing, `CaretMorph.processKeyDown`
  (`:62-68`) maps Arrow* to `goLeft/goRight/goUp/goDown` (Left/Right step a slot, wrapping over the soft break;
  Up/Down keep the column, clamping at first/last line). Place the caret (same `isEditable=true` fixture), then
  `@syntheticEventsShortcutsAndSpecialKeys_InputEvents "ArrowUp"` / `@repeatSpecialKey_InputEvents "ArrowDown", n`.
- **Shift-click extends a selection** (`macroShiftClickExtendsSelection`): a plain click drops a FIXED anchor caret;
  each `@shiftClickAtFractionOf_InputEvents txt, [fx,fy]` grows the selection from the anchor to the click point
  (StringMorph2/TextMorph2.mouseClickLeft reads shiftKey → `startSelectionUpToSlot`/`extendSelectionUpToSlot`).
  Gotchas: TextMorph2 softWrap wraps to the WIDGET width (`@width()`, not `maxTextWidth`) so size it big with
  `rawSetExtent` (tall enough not to crop); a shift-click PAST a line's end clamps to the line-end slot, so two
  clicks past the end produce identical shots — land clicks WITHIN the line text.
- **Double/triple-click selects word/line** (`macroDoubleAndTripleClickThroughCaretMorph`): `@doubleClickAtFractionOf_InputEvents`
  / `@tripleClickAtFractionOf_InputEvents widget, [fx,fy]` enqueue a move + 2/3 consecutive left click-pairs that
  the HAND turns into a double/triple-click; targeting `world.caret` selects word/line at its slot. **Recognition is
  DISABLED in fast playback**, so the test MUST declare `supportsTurboPlayback:false` + `requiresSlowPlayback:true`.
  GOTCHA: a TextMorph2 opens an "edit:" PROMPT (not an inline caret) when its text is CROPPED, so ENLARGE the widget
  so the demo text fits → inline caret.
- **Clipboard cut/copy/paste** (`macroTextMorph2CutCopyPasteBasic`): after a Shift+Arrow selection,
  `clip = @cutSelection_InputEvents()` (or `@copySelection_InputEvents()`) reads + RETURNS the selection synchronously
  and enqueues a `Cut`/`CopyInputEvent`; later `@pasteText_InputEvents clip` enqueues a `PasteInputEvent`. Fizzygum has
  NO internal clipboard — synthetic Meta+x/c/v can't fire the browser's real clipboard EVENTS — so the text rides IN
  the event (a macro-local var), exactly as oncut/oncopy/onpaste → queue → `caret.process{Cut,Copy,Paste}`.
- **Undo** (`macroCaretResizesOKOnUndo`): `@repeatSpecialKey_InputEvents "Meta+z", 4` (the caret's `cmd` handles Meta+a
  and Meta+z). image-before and image-after-undo come out pixel-identical — the round-trip proof the caret resizes back.
- **Text ellipsisation** (`macroStringEllipsisation`): a `StringMorph2` does NOT grow to its text — when too narrow it
  crops to the longest fitting prefix + "…" (`fittingSpecWhenBoundsTooSmall` defaults to `CROP`; SCALEDOWN scales instead,
  the "crop/shrink to fit" item). `new StringMorph2 "long text", fontSize` (give a `backgroundColor` so the bounds show) +
  `rawSetExtent` to a narrow width ellipsises; a narrower extent crops more. The screenshot's settle re-crops.
- **Text alignment** (`macroStringMorph2Alignments`): the converse — a StringMorph2 LARGER than its text doesn't grow it
  either (`fittingSpecWhenBoundsTooLarge` defaults to `FLOAT`); the text floats per `horizontalAlignment` (default LEFT)
  and `verticalAlignment` (default TOP). Drive `str.alignLeft()/alignCenter()/alignRight()` and
  `str.alignTop()/alignMiddle()/alignBottom()` DIRECTLY (the "align …" item methods); a synthetic right-click won't open
  its menu (TextMorph2-family drift). Give it a `backgroundColor` so the float position is visible.
- **Soft-wrap toggle** (`macroSoftWrapTogglesTextReflow`): `textBox.toggleSoftWrap()` DIRECTLY (the "✓ soft wrap" method) —
  a synthetic right-click on a TextMorph2 does NOT open a usable context menu in a macro (it does on plain widgets).
- **Non-wrapping text self-resize** (`macroNonWrappingTextResizesToContent`): a `SimplePlainTextWdgt` (extends TextMorph2)
  resizes its OWN bounds to its text. Its ctor sets `@maxTextWidth = true` (wrap to own width); `@maxTextWidth = nil` then
  `reLayout()` turns wrapping OFF (what "soft wrap off" does, `:111-115`). In that mode `setText` re-lays-out SYNCHRONOUSLY
  (`:126-131 → reLayout :183`): width = LONGEST line, height = lineCount × fontHeight. Drive with `setText` (the clean
  deterministic equivalent of caret typing); multi-line strings via `String.fromCharCode(10)` (no literal newline in the
  backtick source).
- **Edit a button's text label in place** (`macroEditButtonLabelText`): clicking a button TRIGGERS it, so call
  `button.label.edit()` DIRECTLY (`= world.edit label`, sets `world.caret`, no isEditable gate — the "edit" item's method),
  then reuse the caret verbs (`"Meta+a"` → `@syntheticEventsStringKeys_InputEvents "new"`) and `world.stopEditing()` to
  commit. Use an OLD-family label (a `TriggerMorph`/`MenuItemMorph` `TextMorph`, which re-lays-out on setText) — a
  `SimpleButtonMorph`'s `StringMorph2` face crops; for a standalone TriggerMorph give it `centered=true` + a fixed
  `rawSetExtent` and `reLayout()` after each edit.

## Menus & popups

- **Open a menu / click an item**: `@openMenuOf_InputEvents widget` (right-click) then `@moveToItemOfTopMenuAndClick_InputEvents
  "label"`, or the `clickMenuItemOfWidget_InputEvents_Macro widget, "label"` verb (composes both). Pop the WORLD menu at a
  deliberate spot: `@moveToAndClick_InputEvents (new Point X, Y), "right button"`.
- **`getMostRecentlyOpenedMenu()` is fresh-only.** It reads `world.freshlyCreatedPopUps`, which **every mouseUp clears**
  (`ActivePointerWdgt.processMouseUp`). Capture a popup reference RIGHT AFTER it opens and drive its later items through
  `@moveToItemOfMenuAndClick_InputEvents menu, "label"` whenever you touch the popup more than once (e.g. click a
  slider/palette INSIDE a prompt, THEN its "Ok").
- **Item-label matching variants**: exact (`moveToItemOfMenuAndClick_InputEvents`), **PREFIX**
  (`moveToItemStartingWithOfMenuAndClick_InputEvents` — for labels with a variable suffix, e.g. the "attach…"/"choose
  target:" labels are `toString() + " ➜"` like "a RectangleMorph#1 ➜"; match the stable class-name head), **SUBSTRING**
  (`moveToItemContainingOfMenuAndClick_InputEvents` — for a leading decoration, e.g. `"soft wrap".tick()` renders "✓ soft wrap").
- **Hierarchy menu (a non-world child)**: right-clicking a widget whose parent ≠ world opens the framework's ANCESTOR
  HIERARCHY menu (`Widget.buildContextMenu`/`buildHierarchyMenu`) — one "a X ➜" item per ancestor that has a menu (labels are
  `toString().replace("Wdgt","")` so a WindowWdgt reads "a Window ➜"). Navigate to the desired ancestor by class-name PREFIX
  to open ITS own menu (used to resize a content-covered panel, duplicate a nested widget, "pick up" an inspector part, …).
- **Submenu hopping — keep the common chain open** (`macroHoppingBetweenSubMenus`): an arrow item opens a submenu AT the
  clicked point on click (`TriggerMorph.trigger`). Clicking ANY item KEEPS the menus in its ASCENDING hierarchy
  (`PopUpWdgt.hierarchyOfPopUps`) and DISMISSES the DOWNSTREAM submenus — so re-click a world-menu sibling IN THE CHAIN to
  swap the branch under it; the world menu survives every hop until one final desktop click. **OCCLUSION:** a submenu pops at
  the clicked point and covers the sibling triggers, so click each world-menu sibling at its LEFT
  (`@moveToAndClickAtFractionOf_InputEvents sibling, [0.3,0.5]`, further left `[0.1,0.5]` for deeper hops); descend with a
  centre click. Do NOT re-grab a hopped-to submenu via `getMostRecentlyOpenedMenu()` — a hop's deferred auto-close re-clears
  the fresh-popup set; find items directly with `world.topWdgtSuchThat (w) -> w.labelString?.startsWith "demo"`.
- **Menu cascade auto-close on mouse-DOWN** (`macroMenusCloseOnMouseDownOutside`): an open menu (and any submenu) is dismissed
  by a mouse-DOWN on a NON-menu area (the hand's `cleanupMenuWdgts` tears down unpinned popups in
  `world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren`). The dismissal is on the DOWN, not the up, so capture it with
  `@moveToAndMouseDown_InputEvents (point)` (move + press, NO release) → `yield "waitNoInputsOngoing"` → screenshot →
  `@syntheticEventsMouseUp_InputEvents()`. (The same press-and-hold pattern captures a float-dragged morph being DROPPED.)
- **Pin a menu by its header** (`macroMenuPinnedByHeaderClick`): `@clickMenuHeaderToPin_InputEvents menu` clicks the menu's
  title bar (`.label` MenuHeader → `pinPopUp`) — drops the kill-on-click-outside flags (and tightens the shadow), so a later
  desktop click no longer dismisses it. The inverse of cascade auto-close.
- **Pop-up (prompt/menu) shadow on drag** (`macroPromptShadowFollowsOnDrag`): a `PromptMorph` (extends MenuMorph extends
  PopUpWdgt) casts a drop shadow like every pop-up (`PopUpWdgt.popUp → addShadow`, offset (5,5) α0.2). Drag it by its TITLE
  BAR: `@syntheticEventsMouseMovePressDragRelease_InputEvents prompt.label.center(), dest` (a press-drag GRABS the whole
  pop-up; a CLICK on the header would PIN it; dragging the CENTRE hits the inner field/slider). On drop `PopUpWdgt.justDropped`
  re-runs `updatePopUpShadow`, so the shadow renders correctly at every position. Capture `prompt` fresh right after it opens.
- **Pick a colour / set transparency via a popup**: colour: `"color..."` opens a colour-picker menu — capture
  `picker = @getMostRecentlyOpenedMenu()`, click `picker.topWdgtSuchThat((m)-> m instanceof ColorPickerMorph).colorPalette`
  at `[fx,0.5]` (saturated; the palette is `hsl(360·fx,100%,50%)`), then `@moveToItemOfMenuAndClick_InputEvents picker, "Ok"`.
  COLOUR-PICKER TRAP: a `ColorPickerMorph` holds both a hue×lightness `.colorPalette` and a thin `.grayPalette` (a
  GrayPaletteMorph, which SUBCLASSES ColorPaletteMorph) — reach the colour one via the `.colorPalette` accessor, NOT an
  `instanceof ColorPaletteMorph` search. transparency: `"transparency..."` opens a `PromptMorph` —
  `@clickOnSliderTrackAtFraction_InputEvents prompt.topWdgtSuchThat((m)-> m instanceof SliderMorph), [fx,0.5]` then "Ok".

## Windows (chrome + content)

- **Window-chrome buttons** (`macroWindowsEmptyClosing` / `…Collapsing…` / `…Resizing`): reach a window's OWN control by
  reference, not by hunting coordinates — `@closeWindow_InputEvents win` (`.closeButton`, a CloseIconButtonMorph),
  `@collapseOrUncollapseWindow_InputEvents win` (`.collapseUncollapseSwitchButton` — the SAME verb collapses or uncollapses
  per current state), `@dragWindowResizerTo_InputEvents win, (new Point win.right()+dx, win.bottom()+dy)` (`.resizer`, a
  bottom-right HandleMorph, non-float drag → setExtent; use deltas off the live bounds).
- **Internal vs external window drop** (`macroInternalVsExternalWindowDrop`): a `WindowWdgt`'s 4th ctor arg is `internal`
  (default false). `WindowWdgt.rejectsBeingDropped` returns `!@internal`, and `ActivePointerWdgt.drop` forces `target = world`
  for a widget that rejectsBeingDropped (`:242`) — so an EXTERNAL window dropped over a container lands on the desktop (NOT
  nested) while an INTERNAL window nests into the morph under the point (e.g. a PanelWdgt, `_acceptsDrops:true`). Carry on the
  hand with `win.pickUp()` + a no-button `@syntheticEventsMouseMove_InputEvents`, drop with `@syntheticEventsMouseClick_InputEvents()`.
  Prove nesting with `panel.fullMoveTo …` (only the nested internal window travels).
- **Internal window dropped INTO a window → becomes its content** (`macroInternalWindowDroppedIntoWindowFits` /
  `macroResizeWindowContainingInternalWindow`): drop an internal window over an EMPTY external window — `WindowWdgt.add`
  (`:179`) re-parents it `ATTACHEDAS_WINDOW_CONTENT`, `adjustContentsBounds` (`:384`) COUPLES their bounds (the free-floating
  OUTER window sizes itself to WRAP the content + chrome), relabelled "window with an internal window". Then
  `@dragWindowResizerTo_InputEvents` resizes the outer and the inner content stretches to fill (the resizer sits at the inner
  window's corner, `resizerCanOverlapContents`). Shared fixture verbs: `buildExternalAndFreeInternalWindow_Macro()` (`return
  [extWin, intWin]`) + `dropInternalWindowIntoExternalWindow_InputEvents_Macro extWin, intWin` (`return extWin`) — see
  "Composing macros" in CLAUDE.md (one test owns the composite screenshot, the other reuses the fixture without re-shooting).
- **Window resizes to its content** (`macroWindowResizesToTextContent`): an empty `new WindowWdgt nil,nil,nil` adopts a dropped
  widget as content and a free-floating window sizes itself to WRAP it. Drop a wrapping `SimplePlainTextWdgt` via
  `@dragWidgetTo_InputEvents text, window`, then `text.setText longerString` ⇒ window grows, `shorterString` ⇒ shrinks. No caret
  editing — `setText` is enough. The content-driven converse of the handle-driven window resize.
- **Window CONTENT resize — free vs fixed width** (`macroWindowContentResizesFreely` / `macroWindowContentKeepsFixedWidth`): a
  dropped widget becomes `@contents`; on a window resize `WindowWdgt.adjustContentsBounds` (`:384`) resizes it per its
  `WindowContentLayoutSpec`'s `canSetWidthFreely`/`canSetHeightFreely`. A `CircleBoxMorph` has BOTH free → fills both dims; a
  `SliderMorph` keeps a FIXED width (`initialiseDefaultWindowContentLayoutSpec` makes width un-free) → stretches only in height,
  centred. DROP GOTCHA: a CircleBoxMorph drops fine with `@dragWidgetTo_InputEvents circle, win` (centre grab — no sub-widget),
  but a SliderMorph must be dropped with `slider.pickUp()` + a no-button move + `@syntheticEventsMouseClick_InputEvents()`
  (`@dragWidgetTo_InputEvents` would grab the slider's CENTRE = its BUTTON at value 50, moving the button not the slider).

## Scroll & scrollbars

- **ListMorph wheel scroll** (`macroListMorphWheelScroll`): a `ListMorph` (extends ScrollPanelWdgt) is a clipped column of rows.
  Build standalone — `new ListMorph nil, nil, [item strings]` — `rawSetExtent` SHORTER than its content so it overflows + shows
  a scrollbar; `@wheelOn_InputEvents list, deltaY` scrolls it (positive deltaY = DOWN). Tune the delta to the overflow (drop it
  if two later shots stop changing). Row-click highlight is NOT a reliable screenshot signal; scrolling is.
- **Slider/scrollbar TRACK click** (`macroSliderTrackClickMovesButton`): `@clickOnSliderTrackAtFraction_InputEvents doc.vBar,
  [0.5, fy]` clicks a SliderMorph's TRACK (background, OUTSIDE the button) to JUMP the button there — for a ScrollPanelWdgt's
  `@vBar`/`@hBar` this scrolls the content (`SliderMorph.mouseDownLeft` non-float-drags the button to the click when the
  slider's parent is a ScrollPanelWdgt OR PromptMorph; a slider parented to neither IGNORES it — the negative case). Click the
  TRACK not the button (a click ON the button just grabs it) — give enough overflow that the button is small.
- **Nested scroll-panel wheel routing + limit escalation** (`macroNestedScrollPanelsRouteWheel`): the wheel scrolls the INNERMOST
  scrollable under the pointer and ESCALATES to the container once the inner is maxed (`ActivePointerWdgt.processWheel` walks up
  to the nearest `wheel` handler; `ScrollPanelWdgt.wheel` scrolls itself UNLESS at the travel limit, then `escalateEvent 'wheel'`).
  Hold the pointer STILL near the inner's top (one `@syntheticEventsMouseMove_InputEvents (@pointAtFractionOf inner, [0.5,0.15]),
  "no button"`) then fire repeated `@syntheticEventsWheel_InputEvents 0, bigDelta` (the L1 primitive, NOT `wheelOn` which re-moves):
  the 1st bottoms the INNER, the next escalates to the OUTER. Build with a `SimpleDocumentScrollPanelWdgt` (`outer.add inner`
  between two `outer.addNormalParagraph "…"`) holding a fixed-height `ListMorph` (the stack constrains only WIDTH, so the inner
  keeps its height and overflows). FLANK the inner above AND below so it stays VISIBLE when the outer is fully scrolled.
- **Scrollbars track content** (`macroScrollBarsTrackContentChange`): `ScrollPanelWdgt.adjustScrollBars` (`:114`) shows the hBar
  only when `contents.width() >= width()+1` and the vBar only when `contents.height() >= height()+1`, sizing each thumb to the
  viewport/content ratio and positioning it by the scroll offset. Add a wrapping `SimplePlainTextWdgt` as a real SUBMORPH of the
  inner `@contents` (`panel.add text`); NARROW it (`text.rawSetWidth narrower` re-wraps it taller, synchronously, since
  `@maxTextWidth=true`) → vBar appears; MOVE it toward the bottom-right (`text.fullRawMoveTo`) → hBar appears + vBar thumb shrinks;
  re-run `panel.adjustContentsBounds()` + `panel.adjustScrollBars()` after each. TRAP: a single-widget contents (`new
  ScrollPanelWdgt child`) has no submorphs, so `adjustContentsBounds` re-fits it back to the viewport (undoing the overflow) —
  use a real submorph, or call `adjustScrollBars()` only.
- **Edge auto-scroll while dragging** (`macroListMorphAutoScrollsNearDraggedEdge`): a ScrollPanelWdgt auto-scrolls when a
  float-dragged morph it `wantsDropOf` is held near an edge band (≈`scrollBarsThickness*3`). Build a list overflowing BOTH ways,
  `pickUp` a rectangle (don't drop), then `@syntheticEventsMouseMove_InputEvents (a point in an edge band), "no button", …` and
  yield generously. MUSTS: `supportsTurboPlayback:false` (the `autoScroll` 500ms `Date.now()` settle needs real time) and hold
  long enough that the scroll CLAMPS (deterministic).
- **Unplug an inspector scrollbar + the duplicate ASYMMETRY** (`macroInspectorScrollbarUnplugged`): open the OLD small
  `InspectorMorph` via the DIRECT "inspect" item (NOT `bringUpInspector_…_Macro`'s "dev → inspect", which opens InspectorMorph2).
  Capture `scrollbar1 = inspector.list.vBar` BEFORE detaching (the list doesn't rebuild it). Right-click its knob → hierarchy
  "a SliderMorph" → "pick up" → carry + drop CLEAR. It STILL drives the list: `@dragSliderButtonToFraction_InputEvents
  scrollbar1, [0.5, fy]` (`detachesWhenDragged` is false when the button's parent is a SliderMorph). DUPLICATE it ("duplicate"
  instead of "pick up"); `fullCopy` copies the `target` reference so the copy ALSO drives the list. ASYMMETRY: dragging the copy
  scrolls the list and `scrollbar1` FOLLOWS (the list updates its own @vBar via `adjustScrollBars`); dragging `scrollbar1`
  scrolls the list but the copy — which the list has no back-reference to — stays put.

## Drag/drop, attach/detach, duplicate

- **Drag a widget into a container** (`macroSimpleDocumentManualBuildAndScroll`, `macroIconDroppedIntoDocumentFlows`):
  `@dragWidgetTo_InputEvents widget, target` float-grabs at the widget's centre (press-drag past the grab threshold) and drops it
  at a Point or onto a widget's centre. A SimpleDocument's INNER content panel (`SimpleVerticalStackPanelWdgt`,
  `_acceptsDrops:true`) flows arbitrary widgets, so a drop over its content area re-parents the widget as a flowing paragraph —
  no "enable editing" needed (the OUTER scroll panel's `@disableDrops` only gates its chrome). INSERTION INDEX ↔ drop Y:
  `SimpleVerticalStackPanelWdgt.add` (`:34-42`) inserts AFTER the sibling whose vertical span contains the drop Y, APPENDS if the
  Y is in a gap/below all — **index 0 is unreachable**; aim at a sibling's `.center()` for "after it", `lastEl.bottom()+N` to append.
- **`@dragWidgetTo_InputEvents` grabs the CENTRE — which may be a sub-widget.** For a SliderMorph (button at the centre at value 50)
  it grabs/moves the BUTTON, not the slider (the drop silently does nothing). Drop such a widget programmatically: `widget.pickUp()`
  + a no-button `@syntheticEventsMouseMove_InputEvents` + `@syntheticEventsMouseClick_InputEvents()`. A plain shape
  (BoxMorph/CircleBoxMorph/RectangleMorph) has no sub-widget, so `@dragWidgetTo_InputEvents` is fine.
- **Attach to a target** (`macroAttachResizingHandleToMorph`): drop the morph so it OVERLAPS the target (required —
  `Widget.attach` lists only morphs whose bounds INTERSECT it, `world.plausibleTargetAndDestinationMorphs`, excluding self +
  current parent), then `clickMenuItemOfWidget_InputEvents_Macro morph, "attach..."` → capture the "choose target:" menu →
  `@moveToItemStartingWithOfMenuAndClick_InputEvents menu, "a RectangleMorph"` (class-name PREFIX; the menu also lists the World).
  A HandleMorph so attached becomes the target's resize handle → drag it with `@dragResizeMoveHandleTo_InputEvents`.
- **"Attach…" with no targets → a message** (`macroAttachShowsNoTargetsMessage`): a morph alone (nothing overlapping) → `attach`
  pops a `MenuMorph` titled **"no morphs to attach to"** (`:3680`) instead of a target list; that titled, item-less menu IS the
  message. The negative path of attach.
- **Detached morph stays float-draggable** (`macroDetachedMorphStaysFloatDraggable`): float-vs-non-float dragging is computed LIVE
  from the parent, not a stored flag — `Widget.grabsToParentWhenDragged` (`:2513`) is false when the parent is the WORLD (the hand
  grabs the morph itself = float drag) and true when the parent is another morph (dragging grabs the PARENT, so they move
  together). "attach…" re-parents under the chosen target (`Widget.attach → target.add`, `:3657/:3642`); "detaching" = pick up +
  drop on the desktop, which resets the parent to the world. So after attach + detach the morph float-drags independently again.
  GOTCHA: "attach…" is a TOP-LEVEL item, but "pick up" lives in the morph's "a <Class> ➜" HIERARCHY submenu — `clickMenuItemOfWidget
  …, "pick up"` finds nothing and crashes; use `pickUp()` directly or navigate the submenu.
- **Duplicate a widget — copy rides the hand** (`macroDuplicateSimpleWidgetRidesHand` / `…ComplexWidget…`): a normal widget's
  context menu carries a TOP-LEVEL "duplicate" (`Widget.duplicateMenuActionAndPickItUp` = `fullCopy().pickUp()`), so
  `clickMenuItemOfWidget_InputEvents_Macro widget, "duplicate"` makes the COPY ride the hand (already painted on pickup); carry it
  with `@syntheticEventsMouseMove_InputEvents` (a grabbed hand-child follows even a no-button move) and DROP with
  `@syntheticEventsMouseClick_InputEvents()`. **image_1 is taken with NO pointer movement after the click** — the copy must be
  fully painted the instant it is grabbed. Duplicating a COMPLEX/nested widget: right-click it → ancestor hierarchy menu →
  navigate by class-name PREFIX to the desired ancestor's own menu → "duplicate". (A MenuMorph is NOT right-clickable for a
  context menu, so the menu-duplication recordings can't migrate this way — duplicate a normal widget instead.)
- **Locking** (`macroLockToDesktopPreventsDrag` / `macroLockedCompositeWidgetPreventsDrag`):
  `@moveToItemOfMenuAndClick_InputEvents menu, "lock to desktop"` then later `"unlock"` (substring) — the "lock to/unlock from
  <desktop|panel>" items appear only when the morph's parent is a PanelWdgt (the world is one). A locked morph's drag grabs its
  PARENT (`grabsToParentWhenDragged → @isLockingToPanels`), so `@dragWidgetTo_InputEvents` leaves it put; unlock and it moves.

## Controllers (patch-programming)

- **Set target** (`macroPaletteSetTargetRecolorsPanel`): `setControllerTargetToWidgetProperty_InputEvents_Macro controller,
  "a Panel", "color"` — right-click the controller (a ColorPaletteMorph / GrayPaletteMorph / SliderMorph / … with
  `ControllerMixin`) → "set target" (`openTargetSelector` lists only bounds-INTERSECTING widgets, so it MUST OVERLAP the target)
  → pick the target by class-name PREFIX → pick the property; thereafter acting on the controller calls `target[setter](value)`.
  4th arg `controllerMenuFraction` (default `[0.5,0.5]`): pass `[0.5,0.85]` for a SLIDER (its button covers the centre at value
  50, so target the LOWER TRACK). 5th arg `controllerHierarchyPrefix`: pass the controller's class-name prefix when it is INSIDE
  a container (right-clicking a non-world child opens the ancestor hierarchy menu); omit for a world-child.
- **Re-target** (`macroPaletteRetargetsToNewWidget`): run set-target AGAIN — `setTargetAndActionWithOnesPickedFromMenu` OVERWRITES
  `@target`/`@action`; the old target keeps its value but stops following. Put ONE palette over TWO targets of DIFFERENT classes
  (PanelWdgt + RectangleMorph) so each is picked unambiguously by class-name PREFIX; re-target back and forth.
- **Two controllers share one target** (`macroTwoPalettesShareOneTarget`): two ColorPaletteMorphs both set-target'd to the SAME
  panel's "color" (each overlapping the panel but NOT each other); clicking EITHER repaints, both bindings persist (most-recent
  click wins). One palette/many targets ⇒ re-targeting; many palettes/one target ⇒ shared control.
- **Slider drives a target live** (`macroSlidersControlTextMorph`): wire with the 4th/5th args above, then
  `@dragSliderButtonToFraction_InputEvents slider, [0.5, fy]` does a press-drag-release ON the BUTTON (a non-float child drag →
  `SliderButtonMorph.nonFloatDragging → SliderMorph.updateValue → setValue → updateTarget`), driving `target[setter](value)` LIVE
  the whole drag (larger fy = larger value). A slider's property menu lists only NUMERIC setters; `setTargetAndAction` pushes the
  current value on binding. Use the BUTTON-drag verb (not the track-click) for a free-standing controller slider. DUPLICATING a
  controller+target composite (a panel holding a text + its sliders) deep-copies the bindings remapped to the COPY's target.
- **Hover-to-highlight a candidate** (`macroTargetingHighlightsCandidateMorph`): hovering a "choose target:"/"choose new parent:"
  item highlights the morph it represents (`MenuItemMorph.mouseEnter → morphToBeHighlighted.turnOnHighlight()`,
  `MenuItemMorph.coffee:78` → `world.morphsToBeHighlighted` → a `HighlighterMorph` each cycle). Overlap a ColorPaletteMorph with a
  rect, `clickMenuItemOfWidget… "set target"`, grab the menu, find the candidate by prefix, then
  `@syntheticEventsMouseMove_InputEvents item.center(), "no button", …` to HOVER (no click) and screenshot the highlight tint.

## Layout

- **Proportional stack cells** (`macroLayoutBasicProportions`): make a holder a horizontal stack —
  `holder.add cell, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED` per cell + `cell.setMinAndMaxBoundsAndSpreadability(min,
  desired, k*LayoutSpec.SPREADABILITY_MEDIUM)` (k = its share of spare space). Position with `fullMoveTo` BEFORE `world.add`, then
  `new HandleMorph holder` (self-installs at the bottom-right; lone holder ⇒ lone handle). Resize via
  `@dragResizeMoveHandleTo_InputEvents` and the cells redistribute by spreadability. Distilled from the first holder of
  `Widget.setupTestScreen1`.
- **Layout spacer / spring** (`macroLayoutSpacerEatsSpareSpace`): a `LayoutSpacerMorph` is a spring (ctor passes spreadability
  `weight*LayoutSpec.SPREADABILITY_SPACERS` = 1e8, a ~1e6 max that dwarfs any cell's), so in a stack it absorbs almost all spare
  width and the cells stay at DESIRED size. Reuse `Widget.setupTestScreen1()` (8 holders, several `[spacer|adj|green|adj|blue|adj|yellow|adj|spacer(2)]`);
  locate holders as `world.children.filter (c) -> c instanceof RectangleMorph and c.children.length > 0`, each handle a HandleMorph
  among the holder's OWN children. DRIFT: the current layout settles a stretched stack's cells at DESIRED width, so two holders
  match ONLY if their cells share a desired size — pick the two desired-30 holders differing in spreadability (MEDIUM vs NONE).
- **Stack grows with content** (`macroVerticalStackPanelGrowsWithContent`): a `SimpleVerticalStackPanelWdgt`
  (`constrainContentWidth` defaults true) stacks children, constrains each child's WIDTH to the panel, and — being `tight` —
  grows its HEIGHT to the children (`adjustContentsBounds`, `SimpleVerticalStackPanelWdgt.coffee:73-134`: sets each text child's
  `maxTextWidth` to the available width, sums child heights into `rawSetHeight`). Reproduce the demo widgets exactly (`new
  SimpleVerticalStackPanelWdgt` at 370×325 = `Widget.createSimpleVerticalStackPanelWdgt`; each text = `Widget.createNewWrappingSimplePlainTextWdgtWithBackground`,
  a 2-paragraph Lorem + cream bg); DROP each in with `@dragWidgetTo_InputEvents text, panel` (fires `reactToDropOf →
  adjustContentsBounds`), so a second drop ~doubles the height. (A tight EMPTY box taller than one child SHRINKS on the first add
  — start from substantial content.) The reusable fixture for the big `Width*VerticalStackPanel` family.
- **Stack loose when empty, tight when filled — via the resize HANDLE** (`macroStackPanelLooseWhenEmptyTightWhenFilled`): a
  width-constraining `SimpleVerticalStackPanelWdgt` resizes COMPLETELY FREELY (both dims) while EMPTY but only in WIDTH once
  filled (HEIGHT fixed to the wrapped text). `adjustContentsBounds` (`:73`) sums child heights, then `if !@tight or
  childrenNotHandlesNorCarets.length == 0: newHeight = Math.max newHeight, @height()` (`:130-131`) keeps the dragged height ONLY
  when loose or EMPTY. Resize via the real HANDLE: `@openMenuOf_InputEvents panel` → "resize/move..." →
  `@dragResizeMoveHandleTo_InputEvents "resizeBothDimensionsHandle", dest`. KEY: once filled the text COVERS the panel, so bring up
  its handles via the text's "a SimpleVerticalStackPanel ➜" hierarchy submenu. Screenshot WITH the handles showing, then click
  empty desktop to exit. `world.add text` to detach the content and empty the stack.

## Sliders & popovers

- **Slider-button state colours + cross-slider grab** (`macroSliderButtonStateColors`): a `SliderButtonMorph` paints `@color` =
  `normalColor`/`highlightColor`/`pressColor` per state (`mouseEnter → setHiglightedColor`, `mouseDownLeft → setPressedColor`,
  `mouseLeave → setNormalColor`; each early-returns while the hand is dragging). `menusHelper.makeSlidersButtonsStatesBright()`
  (a global MenusHelper) recolours every EXISTING slider button BLACK/BLUE/LIME — call it AFTER `world.add`. HOLD each state:
  hover via a no-button move onto the button (highlighted, persists), then `@moveToAndMouseDown_InputEvents slider.button`
  (pressed, held). GOTCHA: a SliderMorph defaults to `alpha 0.1`, which mutes the colours into greys — set
  `slider.button.alpha = 1` (NOT `slider.alpha = 1`: the track's own colour is BLACK, so an opaque track swallows the black
  button). CROSS-SLIDER GRAB (two sliders): while one is GRABBED, a move with the button HELD (`…, "left button"`) over the OTHER
  handle does NOT highlight it (its mouseEnter early-returns while dragging), and the grabbed button FOLLOWS the hand vertically
  clamped to its own track.
- **Popover stays open while its slider is dragged out** (`macroPopoverStaysOpenWhenSliderDraggedOut`): a pop-up normally closes
  on a mouse-DOWN outside it, but DRAGGING its slider keeps it open even when the pointer leaves its bounds. Pressing a slider
  button whose slider's parent is a `PromptMorph` starts a NON-float drag (`SliderMorph.mouseDownLeft → nonFloatDragWdgtFarAwayToHere`;
  `SliderButtonMorph.detachesWhenDragged` is false while parented to a slider), and on the mouse-UP `cleanupMenuWdgts` is SKIPPED
  while a non-float drag is in progress. Open a RectangleMorph's "transparency..." popover, `prompt = @getMostRecentlyOpenedMenu()`,
  `slider = (prompt.children.filter (c) -> c instanceof SliderMorph)[0]`, then press-drag-release its button to a point far OUTSIDE
  the popover. The alpha commits on "Ok", so only the value FIELD changes live. The INVERSE of dismiss-on-mousedown-outside.

## Rendering & hit-testing

- **Order-dependent transparency compositing** (`macroBoxTransparencyAndColorChanging`): two TRANSLUCENT, differently-coloured
  boxes overlapping a text backdrop blend differently depending on STACKING ORDER (which is in front). Set each box's colour +
  transparency via its "color..."/"transparency..." popups (see Menus), then a left-click on a box raises it
  (`Widget.mouseDownLeft → bringToForeground`), swapping the blend (image_1 green-over-magenta, image_2 magenta-over-green) with
  the text reading through both. Only TWO shots — the one variable that matters is the stacking order; a third would just repeat.
  (Transparency + colour set via a test-local helper in `extraSubroutineSources`.)
- **Composite drop-shadow** (`macroCompositeMorphsHaveCorrectShadow`): a shadow comes from `Widget.add`, NOT `attach` — `world.add
  widget` gives the desktop shadow (`addShadow`, offset (4,4) α0.2, `Widget.coffee:2199`), re-parenting to a non-world parent calls
  `removeShadow` (`:2210`). The shadow paints the recursive silhouette of the whole subtree, so `world.add parent` then
  `parent.add child` makes the parent's shadow outline the WHOLE composite. To force a shadow on a morph that never routed through
  `world.add`, call `widget.addShadow()` explicitly.
- **Shape hit-test / click-through** (`macroRoundedBoxCornerClickThrough`): the pointer resolves to a morph by SHAPE, not bounding
  box — `ActivePointerWdgt.topWdgtUnderPointer` skips any morph that `isTransparentAt` the pointer (`:48`). A `BoxMorph` with a
  large `cornerRadius` is transparent at its corners (`BoxyAppearance.isTransparentAt` outside the rounded arc). Put a
  RectangleMorph backdrop behind a `new BoxMorph 55`, then `@moveToAndClickAtFractionOf_InputEvents box, [0.96,0.96]` (a corner —
  click passes THROUGH, backdrop comes forward) vs `[0.1,0.4]` (the body — box comes forward). The z-order flip on left-click
  (`bringToForeground`) is the observable.
- **Rectangular clipping** (`macroClippingBoxClipsChildAtBounds`): a `ClippingBoxMorph` is an ORDINARY BoxMorph that merely
  `@augmentWith ClippingAtRectangularBoundsMixin` (the whole class body) — the mixin clips children to its bounds. `new
  ClippingBoxMorph` (setColor/rawSetExtent/fullRawMoveTo/world.add), `clipBox.add child`, then move the child
  (`child.fullRawMoveTo …`) to STRADDLE each edge in turn — it's cut off at that edge, proving the clip is the box's fixed
  rectangle on every side.
- **Hide / show + subtree** (`macroHideUnhideMorphChain`): `widget.hide()` / `widget.show()` flip `@isVisible`; the paint
  recursion short-circuits at an invisible morph BEFORE its children (`Widget.preliminaryCheckNothingToDraw`), so hiding a
  mid-chain morph hides its WHOLE subtree, and `show()` restores it. Drive them DIRECTLY — `hide()` is the "hide" item's method,
  and `show()` MUST be programmatic (a hidden morph can't be right-clicked; recordings un-hide via an inspector `show()` eval).
  `show()` no-ops if the morph is already effectively visible (ancestor-chain AND), so a hide→show round-trip is image-identical.
- **Canvas / pen turtle drawing** (`macroSierpinskiInCanvas`): `canvas = new CanvasMorph; canvas.rawSetExtent (new Point W, H)`
  (REQUIRED — CanvasMorph ships no default extent), `canvas.fullRawMoveTo …; world.add canvas`; `pen = new PenMorph; canvas.add
  pen` — a PenMorph draws on its PARENT when that parent is a CanvasMorph (`PenMorph.forward → @parent.drawLine`), so attaching it
  to the canvas wires the turtle to the surface. Place with `pen.fullRawMoveTo …` and call a drawing method DIRECTLY, e.g.
  `pen.sierpinski 400, 40` (synchronous).

## Assertions & eval

- **Non-screenshot assertions** (`macroCheckNumberOfItemsInWorldMenu`, `macroLonelySliderTargetsWorldOnly`): with a menu open,
  `@assertTopMenuItemCount n` and `@assertTopMenuItemStrings ["label", …]` (reads each item's `labelString` via the menu's
  `testItems()`, compares the ordered array) → `world.automator.player.recordMacroAssertion(passed, desc, expected, found)` (the
  generic sink: flips `allTestsPassedSoFar`, records the failing test, logs expected-vs-found, but does NOT stop the macro). These
  MUST be `@assert…` toolkit methods — `recordMacroAssertion` has "Macro" mid-token, which the invocation rewriter would mangle in
  macro SOURCE. `macroLonelySliderTargetsWorldOnly`: a lone controller can only target the WORLD — `openTargetSelector` lists
  bounds-intersecting widgets + always the world (Widget.coffee:846); with nothing overlapping, "a WorldMorph ➜" is the only item.
- **Button-trigger discipline** (`macroButtonTriggersOnlyOnSameMorphMouseUp`): a button fires only when mouse-down AND mouse-up
  land on the SAME morph (`ActivePointerWdgt.processMouseUp` fires only `when w == @mouseDownWdgt`). To show "press then release
  elsewhere does NOT trigger", press on the button and release off it: `@syntheticEventsMouseMovePressDragRelease_InputEvents
  (@pointAtFractionOf button, [0.5,0.5]), (new Point X, Y)`. Parent the button INSIDE a container (window/panel), NOT bare on the
  world (`EmptyButtonMorph.rejectDrags` is false only when the parent is the world, so a loose button float-drags on the press).
- **In-system eval** (`macroEvaluateString`): `world.evaluateString "code"` runs arbitrary CoffeeScript against the live world
  INLINE (compile, run with `@`=world, relayout/repaint) — the macro form of the recorded `AutomatorEventCommandEvaluateString`.
  Do NOT write `@evaluateString` (MacroToolkit's own binds `@` to the toolkit). No new verb; no input events, so just `yield
  "waitNoInputsOngoing"` before a screenshot.

## The verb-establishing pilots

- **`macroBasicWorldMenuAndBubble`** (from 89 cmds): open the world menu, hover "demo", `yield <ms>` for the help bubble, screenshot.
- **`macroAddEditSaveRenameRemoveProperty`** (from 1057 cmds, 5 shots): demo-menu a string, inspect it, then add / set-value+save /
  rename / remove a property via the inspector. INSPECTOR gotchas: context-menu "inspect" opens the OLD `InspectorMorph`; "dev ➜ →
  inspect" opens `InspectorMorph2` (the `*FromTopInspector*` helpers assume InspectorMorph2). A value/detail pane's text (e.g.
  "nil") is a `TextMorph` in a scroll-panel, NOT a text-described StringMorph — locate it by structure (`inspector.detail`) + click
  near its top-left, and `yield ~300` to let a freshly-updated pane lay out before clicking (its `center()` can be undefined).
- **`macroCanMoveAndResizeColorPaletteMorph`** (from 523 cmds): enter resize/move mode (`@openMenuOf_InputEvents` → "resize/move...")
  then drag a corner handle; click empty desktop to exit before the screenshot.
- **`macroSimpleDocumentProgrammaticBuildAndScroll` / `…ManualBuildAndScroll`**: build the SAME scrollable `SimpleDocumentScrollPanelWdgt`
  — one fills it via `doc.add`, the other by DRAGGING two desktop text widgets in (`@dragWidgetTo_InputEvents`) — then wheel-scroll.
  GOTCHA: `SimplePlainTextWdgt` width floors ~330px, so narrow the doc and place draggables SIDE BY SIDE (stacking overlaps them).
