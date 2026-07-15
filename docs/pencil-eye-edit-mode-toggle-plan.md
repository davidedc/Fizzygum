# Plan — pencil ↔ eye: the window-bar edit-mode toggle shows the CURRENT MODE as a glyph

**Status: ✅ IMPLEMENTED + PUSHED.** The state glyph (§1–§7) shipped 2026-07-06 (Fizzygum `6f6c834e` / tests
`7214a8193`); the **§8 HOVER-FEEDFORWARD REFINEMENT** (monochrome-at-rest + next-state-on-hover-in-yellow +
immediate tooltip, owner-driven) landed 2026-07-15 — **see §8, which supersedes §1's resting colour.** History below.

**(Original 2026-07-06 status.)** Executed by the drag-embed
executor session as its next step after the drag-embed arc landed (Fizzygum `5e8d152e` / tests `276b26b84`),
per §6's recommendation. Built exactly per §4 (the §2 one-button appearance-swap design, NOT a SwitchButtonWdgt);
§1 STATE semantics kept (owner saw the eye live at the eyeball checkpoint and approved: "Proceed"). The eye glyph
(§4a, drafted blind) reads as an eye at both densities with NO coordinate adjustment. **Blast radius was TINY —
2 tests / 5 view-mode frames** (`macroDrawingsMakerReEnableEditing` ×1, `macroDegreesConverterFourWayDrive` ×4),
NOT the "majority of window frames" §5 feared: the pencil (edit mode) is byte-identical; only the clear-pencil →
clear-eye view-mode frames changed. New macro `macroEditModeTogglePencilEyeGlyph` (suite 189 → 190). GATE RESULTS
in the LANDED box at the end of §5.

Authored 2026-07-06 against the tree at Fizzygum `55043033` (the drag-embed executor's Phase-5 switch-deletion
commit). Owner-requested extraction: this plan REPLACED the "Edit button → SwitchButtonWdgt [pencil, eye]" bullet of
`docs/drag-embed-implementation-plan.md` §3 Phase 5 — the drag-embed executor did NOT implement that bullet. Everything
else in drag-embed Phase 5 (eject/derived-internal — landed as `55043033` — and the dashboard default) stayed there.

## §0 — Orientation + working contract (self-contained)

**Fizzygum** = CoffeeScript GUI framework on one `<canvas>`. Umbrella `/Users/davidedellacasa/code/Fizzygum-all/`
(NOT a git repo) holds siblings `Fizzygum/` (source — the ONLY place behavior changes), `Fizzygum-tests/`
(byte-exact screenshot macro SystemTests; count was 181 pre-drag-embed-arc and is GROWING — read the current
number off a suite run), `Fizzygum-builds/` (generated, never edit). `nil`==`undefined`; one class per file,
filename = class name; no imports (classes are globals; the dependency finder regex-scans for literal
`extends X` / `new X` forms — use them). Commands from the umbrella root: `./fg build` · `./fg suite` ·
`./fg gauntlet` (build + dpr1 + dpr2 + webkit + apps + gates) · `./fg test <name>` · `./fg recapture <name>`
(FULL flow only — never hand-rolled `--no-build`; re-verify the webkit leg after ANY recapture). NEVER commit
or push without explicit owner approval; commit messages via `git commit -F <file>`; lockstep commits when
both repos change. No conclusions before evidence: claims like "byte-identical" appear ONLY after the gate
that proves them has passed. New SystemTests via the `/author-macro-test` skill in `Fizzygum-tests`.

## §1 — THE UX DECISION (owner asked: which glyph in which mode?)

**DECIDED: STATE semantics — the glyph names the mode the content is in NOW.**
- **Edit mode → PENCIL shown** (in today's editing-yellow `248,188,58`); click → switch to view mode.
- **View mode → EYE shown** (in today's clear `245,244,245`); click → switch to edit mode.
- Tooltips carry the ACTION (they always describe what a click does): pencil-state tooltip
  **"switch to view mode"**; eye-state tooltip **"edit contents"** (the existing string, kept).

Why state semantics and not action semantics (icon-shows-what-click-does, the play/pause convention):

1. **The button is primarily a mode INDICATOR here.** The pencil already works this way today (yellow =
   editing NOW), and the whole editing family drives it through state-reflection callbacks
   (`makePencilYellow`/`makePencilClear` fire from enable/disable, not from clicks — 8 caller classes, §3).
   The glyph swap upgrades a color-only state display into a shape+color state display; changing the
   semantics direction at the same time would break every existing user's reading of the control.
2. **The drag-embed arc points AT this button to teach mode.** Its lock-cue pulses the edit button when a
   drag hovers a view-mode destination, saying "this window is in VIEW mode — here's the control". That
   sentence only parses if the glyph shown in view mode IS the eye. Under action semantics the cue would
   pulse a pencil on a view-mode window — "pencil = not editable" is incoherent.
3. **Cross-window scanning.** "Which of these windows is editable right now?" is answered at a glance only
   if the glyph names the current state; the tools palette corroborates it in situ, resolving the classic
   toggle-ambiguity (the state is visible twice, consistently).
4. **The honest counter-case** (why the owner's uncertainty is legitimate): the password-field eye primes
   "eye = click to reveal" (action), and OS title-bar buttons (minimize, and Fizzygum's own
   collapse/uncollapse pair) use action semantics. Mitigations: those are momentary COMMANDS, not modes; the
   tooltip states the action; and a wrong first guess on a 2-state toggle costs one click and permanently
   teaches the mapping. **If the owner reverses after seeing it live, the flip is 2 swapped appearance
   assignments + 2 tooltip strings in §4's `showEditModeInBar`/`showViewModeInBar` — nothing else moves.**

## §2 — DESIGN DEVIATION from drag-embed spec §10 (flagged for owner approval)

Spec §10 said "edit button becomes a `SwitchButtonWdgt [pencil, eye]`". **This plan REJECTS the
SwitchButtonWdgt and keeps the ONE `EditIconButtonWdgt`, swapping its APPEARANCE.** Reasons, discovered by
reading the code (2026-07-06):
- `SwitchButtonWdgt.mouseClickLeft` SELF-INCREMENTS `buttonShown` on every click — a second source of truth
  next to `dragsDropsAndEditingEnabled`, needing bidirectional sync (mode also changes via the context menu
  "enable/disable editing" and programmatically from 8 classes). The existing callback channel already IS
  the sync mechanism for a single stateful button; a switch adds the classic desync bug farm for zero gain.
- Runtime appearance swap is the established re-skin idiom (`WindowWdgt.setAppearanceAndColorOfTitleBackground`
  re-skins the title bar the same way; `IconButtonWdgt` assigns `@appearance = @createAppearance()` at build).
- The button keeps its identity, layout slot, narrow-window collapse handling, and the drag-embed lock-cue
  anchor (`@editButton` bounds) untouched.

## §3 — Code facts (verified 2026-07-06 on `55043033`; grep the symbols, lines omitted)

- **`EditIconButtonWdgt`** (`src/buttons/EditIconButtonWdgt.coffee`): `extends IconButtonWdgt`;
  `iconToolTipMessage: "edit contents"`; `createAppearance: -> new PencilIconAppearance @`;
  `actOnClick: -> @parent?.editButtonInBarPressed?()`.
- **`IconButtonWdgt`** (`src/buttons/IconButtonWdgt.coffee`): the family base — subclass supplies
  `createAppearance` / `iconToolTipMessage` / `actOnClick` (+ optional `iconHoverColor`). Constructor copies
  `@toolTipMessage = @iconToolTipMessage` AFTER super (a plain prototype override would be clobbered) — so a
  runtime tooltip swap assigns `@toolTipMessage` directly.
- **`IconAppearance`** (`src/icons/IconAppearance.coffee`): `paintFunction (context)` draws in a
  `specificationSize: 200×200` space, aspect-fit-centered into the widget; helpers `oval`/`circle`/`arc`;
  `PencilIconAppearance.paintFunction` fills with `@widget.color` — which is what the yellow/clear recolor
  drives. `PencilIconWdgt` = 3-line `extends IconWdgt` wrapper.
- **`WindowWdgt`**: `createAndAddEditButton` (gated on `@contents?.providesAmenitiesForEditing`; initial
  state read from `@contents.dragsDropsAndEditingEnabled`); `makePencilYellow` / `makePencilClear` (set
  `color_normal` + `setColor` + `changed()` on `@editButton` — yellow `248,188,58` / clear `245,244,245`);
  `editButtonInBarPressed -> @contents?.editButtonPressedFromWindowBar?()`. Post-`55043033` the edit button
  is the RIGHTMOST title-bar button and collapses below `3*(closeIconSize+@padding)+@padding` width.
- **The 8 state-reflection callers of `makePencilYellow`/`makePencilClear`** (each has one enable-side and
  one disable-side call of the form `@parent?.makePencilYellow?()`): `StretchableEditableWdgt` ·
  `StretchableWidgetContainerWdgt` · `StretchablePanelWdgt` · `SimpleVerticalStackScrollPanelWdgt` ·
  `basic-widgets/Widget.coffee` (the base enable/disable family) · `basic-widgets/ScrollPanelWdgt` ·
  `apps/SimpleDocumentWdgt`. (WindowWdgt itself = the 8th, definition + initial-state call.) The drag-embed
  plan's "only 2 callers" note was WRONG — trust this grep-verified list, then re-grep anyway.

## §4 — Implementation

### 4a. NEW `src/icons/EyeIconAppearance.coffee` (full code — DRAFTED BLIND, §5 gate includes an eyeball pass)

Same idiom as `PencilIconAppearance`: single fill from `@widget.color`, 200×200 space. Glyph = almond
outline band + filled pupil (reads at title-bar size; no thin strokes). The almond band is one path whose
outer contour is traced TOP-first and inner contour BOTTOM-first (opposite windings → nonzero-rule ring,
same trick as the base `IconAppearance` donut); the pupil is a separate filled subpath.

```coffee
# The "view mode" eye shown in a window's title bar when its content has
# editing disabled (see EditIconButtonWdgt / WindowWdgt.showViewModeInBar).
# Same single-fill idiom as PencilIconAppearance: the glyph takes the
# widget's color, so the existing yellow/clear recoloring keeps working.

class EyeIconAppearance extends IconAppearance

  paintFunction: (context) ->
    fillColor = @widget.color

    context.save()

    # almond outline band: outer contour top-first, inner contour
    # bottom-first -- opposite windings, so the nonzero fill rule leaves
    # the band between them (cf. the donut in IconAppearance.paintFunction)
    context.beginPath()
    context.moveTo 8, 100
    context.bezierCurveTo 38, 34, 162, 34, 192, 100
    context.bezierCurveTo 162, 166, 38, 166, 8, 100
    context.closePath()
    context.moveTo 30, 100
    context.bezierCurveTo 56, 144, 144, 144, 170, 100
    context.bezierCurveTo 144, 56, 56, 56, 30, 100
    context.closePath()
    # pupil (its own subpath; any winding, it doesn't overlap the band)
    @circle context, 100, 100, 27
    context.fillStyle = fillColor.toString()
    context.fill()

    context.restore()
```

### 4b. NEW `src/icons/EyeIconWdgt.coffee` (parity with `PencilIconWdgt`; also usable as palette art)

```coffee
class EyeIconWdgt extends IconWdgt

  createAppearance: -> new EyeIconAppearance @
```

(If nothing references it at first, that is fine — every class ships regardless; the appearance itself is
reached via the literal `new EyeIconAppearance @` forms so the dependency finder sees the edge.)

### 4c. `EditIconButtonWdgt` — glyph-swap methods (the button owns its appearance + tooltip)

```coffee
  # STATE-semantics glyph swap (docs/pencil-eye-edit-mode-toggle-plan.md §1):
  # pencil = content is in edit mode now; eye = content is in view mode now.
  # The tooltip always states the ACTION a click performs.
  showPencilGlyph: ->
    @appearance = new PencilIconAppearance @
    @toolTipMessage = "switch to view mode"
    @changed()

  showEyeGlyph: ->
    @appearance = new EyeIconAppearance @
    @toolTipMessage = "edit contents"
    @changed()
```

(`iconToolTipMessage: "edit contents"` stays as the constructor-time default, matching the eye/initial-view
case; `createAppearance` keeps returning the pencil — `createAndAddEditButton`'s initial-state branch (4d)
immediately shows the right glyph either way.)

### 4d. `WindowWdgt` — rename the state-reflection pair and fold in the glyph

`makePencilYellow` → **`showEditModeInBar`** (pencil glyph + the existing yellow), `makePencilClear` →
**`showViewModeInBar`** (eye glyph + the existing clear):

```coffee
  showEditModeInBar: ->
      @editButton?.showPencilGlyph()
      # TODO assigning to color_normal is not enough
      # there should be a way to do these two lines with one line
      @editButton?.color_normal = Color.create 248, 188, 58
      @editButton?.setColor Color.create 248, 188, 58
      @editButton?.changed()

  showViewModeInBar: ->
      @editButton?.showEyeGlyph()
      # TODO assigning to color_normal is not enough
      # there should be a way to do these two lines with one line
      @editButton?.color_normal = Color.create 245, 244, 245
      @editButton?.setColor Color.create 245, 244, 245
      @editButton?.changed()
```

`createAndAddEditButton`'s initial-state branch calls the renamed pair. Colors stay EXACTLY today's two
values on purpose — the glyph is the new information channel; recolor tuning (e.g. a darker eye for
legibility on light title bars) is a separate owner call after seeing it live.

### 4e. The 8 caller classes — mechanical rename (16 call lines)

Every `@parent?.makePencilYellow?()` → `@parent?.showEditModeInBar?()`, every
`@parent?.makePencilClear?()` → `@parent?.showViewModeInBar?()`, in the §3 list. Then
`grep -rn "makePencil" src` MUST return zero.

## §5 — Gates + test impact

1. `./fg gauntlet` (all densities + webkit + apps + gates). **Expected pixel impact: every reference frame
   showing a VIEW-mode edit button changes (clear pencil → clear eye) — likely the majority of window-bearing
   frames, a LARGE recapture batch. Frames showing the EDITING state should be unchanged (same
   PencilIconAppearance, same yellow) — VERIFY that claim from the actual failure list, don't assume it.**
   Enumerate empirically: run the suite once after the change; the failure list IS the recapture set; spot-check
   diffs are glyph-only before recapturing; full `./fg recapture` flow; webkit re-verify after.
2. **Eyeball pass on the drafted glyph (mandatory — the 4a coordinates were authored without a build):**
   build, open `Fizzygum-builds/latest/index.html`, view a doc/slide window in both modes at real title-bar
   size, dpr 1 AND 2. Adjust the almond/pupil coordinates if muddy; the acceptance bar is "reads as an eye at
   ~14px". (Coordinate with the drag-embed executor session before building — shared tree.)
3. **Both serialization legs** (world snapshot + duplication): a window saved in view mode must restore
   showing the eye. If chrome children serialize with their appearance objects this is free; if restore
   re-runs the initial-state branch it is also free — but VERIFY by running the legs, and check
   `docs/serialization-duplication-reference.md` if either leg fails.
4. **NEW macro** (via `/author-macro-test`): `macroEditModeTogglePencilEyeGlyph` — open a document window;
   assert initial glyph matches its initial mode; click the button → glyph+mode flip (tools palette
   appears/disappears with it); flip back via the CONTEXT-MENU "enable editing"/"disable editing" path →
   glyph follows (proves the callback channel, not just the click path, drives the glyph).
5. **Drag-embed interaction check:** the lock-cue overlay (drag-embed Phase 2) anchors to `@editButton`
   bounds — unchanged by this plan, but run one drag-over-view-mode-window by hand (or its macro) to confirm
   the pulse now reads "amber pulse on an EYE", which is the composition §1 point 2 promised.

## §6 — Coordination, sequencing, out-of-scope

- **The drag-embed executor session owns the tree.** Execute this plan EITHER as that session's next phase
  (recommended — it already holds the working context and the recapture cadence) OR strictly after its arc
  lands; never concurrently in a second working tree without owner arbitration.
- Out-of-scope here (stay in the drag-embed plan): dashboard edit-ON default; eject button polish; any
  view-mode drop semantics; recolor tuning beyond keeping today's two colors; `Pencil2IconAppearance` and the
  paint-app pencils (unrelated art — do not touch).
- Rough size: ~0.5 day of code + the recapture batch (the wall-clock wildcard) + 1 new macro.

## §7 — LANDED STATUS (2026-07-06, Opus — awaiting owner review + commit)

**WHAT LANDED (Fizzygum source):**
- NEW `src/icons/EyeIconAppearance.coffee` (§4a verbatim) + `src/icons/EyeIconWdgt.coffee` (§4b). The eye glyph
  read as an eye at dpr 1 AND 2 with NO coordinate adjustment (eyeball pass on a dumped `macroDrawingsMakerReEnableEditing`
  view-mode frame; owner approved it live at the checkpoint).
- `src/buttons/EditIconButtonWdgt.coffee` — added `showPencilGlyph` / `showEyeGlyph` (appearance + tooltip swap).
- `src/WindowWdgt.coffee` — `makePencilYellow` → `showEditModeInBar` (pencil + yellow), `makePencilClear` →
  `showViewModeInBar` (eye + clear); `createAndAddEditButton`'s initial-state branch calls the renamed pair.
- The 7 external state-reflection callers renamed (14 call lines): `SimpleDocumentWdgt`, `ScrollPanelWdgt`,
  `basic-widgets/Widget`, `SimpleVerticalStackScrollPanelWdgt`, `StretchableEditableWdgt`, `StretchablePanelWdgt`,
  `StretchableWidgetContainerWdgt`. `grep -rn makePencil src` → 0.

**TESTS (Fizzygum-tests):** recaptured the 2 affected tests (dpr 1+2, benign clear-pencil → clear-eye, webkit
re-verified): `macroDrawingsMakerReEnableEditing` (1 frame) + `macroDegreesConverterFourWayDrive` (4 frames). NEW
`macroEditModeTogglePencilEyeGlyph` (§5.4) — proves the glyph follows the mode via BOTH the button CLICK (→ eye) and
the context-menu "enable editing" (→ pencil), with the tools palette flipping in lockstep; image_0 == image_2
(menu round-trip is pixel-identical to the opening edit frame). Suite 189 → 190.

**DEVIATION from spec §10, as-built:** kept the ONE `EditIconButtonWdgt` and swapped its appearance (§2), rejecting
the `SwitchButtonWdgt [pencil, eye]` the drag-embed spec named — no second source of truth, no desync farm.

**GATES ALL GREEN:** `fg gauntlet` — dpr1 190/0 · dpr2 190/0 · **webkit 190/0** (recaptures carry no baked-crash
frame) · apps · tiernaming (0 leaks) · settle (0) · capstone (0) — + serialization world-roundtrip (native 24 +
SWCanvas 36) + file-roundtrip (7) + `fg homepage` boot OK. §5.3 (view-mode window restores with the eye): the
serialization legs round-trip windows pixel-identically, and the edit button's appearance survives restore the same
way the pencil already did — so the eye is free (no regression). §5.5 (drag-embed lock-cue): the cue anchors to
`@editButton` BOUNDS, which this change does not touch (only the button's appearance/tooltip), so the amber
pulse-on-an-eye composition follows automatically — confirmed by inspection, no bounds/layout change.

## §8 — HOVER-FEEDFORWARD REFINEMENT (2026-07-15, owner-driven; supersedes §1's rest colouring)

A follow-up UX pass, brainstormed + prototyped live with the owner (eyeball board, teal/green/yellow compared),
then locked in. It re-splits the two jobs of the button — INDICATE the current mode vs AFFORD switching it —
across the two interaction states:

- **MONOCHROME AT REST.** The resting glyph is uncoloured (near-white on the gray bar) for BOTH modes; the SHAPE
  alone names the current mode (pencil = editing, eye = viewing). The editing-yellow of §1 is dropped at rest —
  rest becomes a calm pure-status indicator, reading like the close/collapse icon family. (Accepted tradeoff: the
  cross-window "which is editable?" scan now needs a look, not a glance; the owner chose calm over pop.)
- **FEEDFORWARD ON HOVER.** While hovered (or pressed) the button morphs to the glyph of the mode a click switches
  TO, in a single **"this button does something" YELLOW** (owner decision: NOT a mode-specific teal/green — the
  shape carries the meaning, the colour just says "active"). Rest = status (shape); hover = control (next glyph +
  affordance colour + text). The colour arriving on hover is itself the "this is a preview" cue.
- **IMMEDIATE tooltip.** The action bubble ("switch to view mode" / "edit contents") pops on hover with ~no delay
  (next frame) instead of the shipped 500ms, so the text explanation lands with the visual preview.

**As-built (Fizzygum):**
- `EditIconButtonWdgt` owns all its rest/hover appearance now: `restColor` (near-white) + `hoverColor` (yellow);
  `_updateColor` (overriding the `HighlightableMixin` colour hook) swaps BOTH the glyph and the colour by state —
  rest = current-mode glyph mono, highlighted/pressed = OTHER-mode glyph in yellow. `showPencilGlyph`/`showEyeGlyph`
  just set `@_editModeNow` and re-derive. The `_updateColor → @setColor` call is `# public-call-sanctioned` (it
  mirrors the mixin method it overrides; setColor is the pure paint-colour setter, no settle).
- `startCountdownForBubbleHelp` overridden to pass delay `1` (≈ next frame). Edit-button-specific — other buttons
  keep the 500ms. (SystemTests already bypass the delay, so this changes only the live/interactive timing.)
- `WindowWdgt.showEditModeInBar`/`showViewModeInBar` simplified to just call the button's glyph setter (the button
  owns the colour now; the old `color_normal`/`setColor` yellow/clear lines are gone).

**Tests:** blast radius = **7 tests** (the edit-mode pencil went yellow→white; view-mode eye was already near-white,
unchanged): `macroDesktopShortcutIcons`, `macroDrawingsMakerReEnableEditing`, `macroEditModeTogglePencilEyeGlyph`
(also EXTENDED with an image_3 hover frame covering the yellow-eye feedforward + immediate tooltip),
`macroSampleSlideEditViewToggle`, `macroSaveAsPromptAboveTiltedWindow`, `macroWindowCellsInConstrainedScrollStackReflow`,
`macroWindowWithSimpleVerticalPanelResizesAsContentChanges`. All benign glyph-colour recaptures.

**GATES ALL GREEN:** `fg gauntlet` — dpr1 248/0 · dpr2 248/0 · **webkit 248/0** · apps · paint · tiernaming/settle/
capstone (0 each) — + serialization world-roundtrip (SWCanvas 36) + file-roundtrip (7) + `fg homepage` boot OK.

**⚠ CLICK-THEN-PARK (case law):** the feedforward means the edit button, still under the pointer right after a
click, shows the NEXT-state preview glyph — so any test that clicks the edit button and screenshots a "resting"
mode must first move the pointer OFF it. Three tests needed a park added (`macroDrawingsMakerReEnableEditing`,
`macroEditModeTogglePencilEyeGlyph`, `macroSampleSlideEditViewToggle`); the DrawingsMaker `image_0==image_2`
idempotency assert broke until parked. **⚠ Also:** the churn had DELETED `AutomatorEventCommandTurnOnAlignmentOf
WidgetIDsMechanism`; a stale rewrite of `macroEditModeTogglePencilEyeGlyph` re-added it and threw at setup
(`Cannot read properties of undefined (reading 'prototype')`) — grep the harness for a command before using it.
