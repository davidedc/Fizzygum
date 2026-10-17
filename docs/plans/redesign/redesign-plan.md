# Fizzygum visual redesign — the plan

**AUTHORED + OWNER-APPROVED 2026-10-16; P0, R0, T and F done; next: S1c, the corner path the owner confirmed (§3 #4), then W1.** It is written to be executed COLD, over many sessions, by an LLM or engineer with ZERO prior context.
- This file is the living plan. Keep its STATUS box current at every phase close. The design input it executes sits beside it in this directory.
- Line numbers below drift. The quoted method or field name is authoritative: grep it fresh before trusting a `file:line`.

**Mandate: transformation, not a reskin-by-patches.**
- Fizzygum ends up with ONE visual design system: named tokens, rules and primitives. Every widget's look is derived from that system, not from per-class literals.
- The draft's look is reached through that system, surface by surface.
- The test suite is made layout-resilient FIRST, so that moving to the new look breaks pixels and not test intent.

---

## STATUS
| Phase | What | State |
|---|---|---|
| P0 | Copy the plan into the repo; add BACKLOG pointers (branches are created at W1) | DONE 2026-10-16 |
| R0 | Recapture tooling: batch finger recapture + throughput | DONE 2026-10-16 (~1 h per full wave, was ~7 h) |
| T | Tests aim by meaning; aims verify their hit (zero recapture) | DONE 2026-10-16 — every widget-aimed press verified ("AIM MISSED"); 9 never-delivered tests found, fixed and recaptured (owner-approved; Fizzygum b408f0c7, Fizzygum-tests 80ee6ca92) |
| F | Tokens (`Theme`), primitives, spikes S1–S3 (zero recapture) | DONE 2026-10-17 — `Theme` + the primitives, each default-neutral; spikes measured. The one benign inspector recapture owner-approved. Corners (§3 #4): owner CONFIRMED S1c 2026-10-17 (optimise SWCanvas's clip tiers, re-measure; adopt the clip iff ≤ 3 %) — NEXT, before W1 |
| W1 | Global surface + all persistent frames (windows, cards, bands) | not started |
| W2 | Menus, lists, scrollbars, prompts, tooltips | not started |
| W3 | Controls + Object Inspector re-layout | not started |
| W4 | Desktop: tiles, plates, grid, size knob, clock, bin, icons | not started |
| W5 | Docs Maker: tool buttons, paragraph items, caret | not started |
| W6 | Wording (sentence case, human names, "…") | not started |
| G | Generalisation sweeps, family by family | not started |
| Z | Close: squash-merge, docs, archive | not started |

---

## §0 Orientation (read first)

**What Fizzygum is.** A CoffeeScript GUI framework, a "web OS" painted on one `<canvas>`. The umbrella `Fizzygum-all/` holds three sibling repos:
- `Fizzygum/`: source. Edit only `src/**/*.coffee`.
- `Fizzygum-tests/`: 334 macro SystemTests, plus 3808 reference PNGs, each with a `.js` twin.
- `Fizzygum-builds/`: generated. Never edit it.

Read in order: the root `CLAUDE.md`, `Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md`, `Fizzygum/src/macros/CLAUDE.md`.

**There are two rendering backends.**
- Native canvas, which anti-aliases (AA). It is what production uses.
- SWCanvas, a NON-AA software rasterizer. The test suite and the owner's daily use run on it. Every reference image is SWCanvas.

Everything in this plan must look right on SWCanvas first.

**The design input** lives in `Fizzygum/docs/plans/redesign/`:
- `UI-guidelines.md`: the rules and tokens. ⭐ Read all of it.
- `desktop-canvas.html`: a flat Canvas-2D reference drawing.
- `2 · Proposed restyle@1x.png`: the target.
- `original-design.png`: the same scene as Fizzygum draws it today.

**⭐ The critical reframe: today's structure already matches the draft.** It was measured on 2026-10-16:
- The window title strip is already a 44 px icon slot. Close and collapse already sit on the LEFT, the pencil on the right, and the title is centred (`FrameWdgt._barSpec`).
- Menu rows are already 44 px (`menuRowHeight`, a `Theme` metric since F1).
- Scrollbars are already 4 px overlay thumbs (`ViewportWdgt`, `scrollIndicatorThickness`).
- Frames already cast ONE solid silhouette shadow with no blur (`ShadowInfo` has no blur parameter).
- The Docs Maker's toolbar is already a docked `FrameWdgt` with a vertical strip carrying only collapse (`FrameWdgt` + `EdgeDockLayoutSpec`).
- Menus, windows, cards and docked bands are ONE class, `FrameWdgt`. Each skin is derived from two facts: lifetime (transient or persistent) and parentage (`docs/architecture/regularity-principles.md` "The frame model").

So the redesign is mostly SURFACE: tokens, glyphs, rules, radii and shadows. There are five structural exceptions:
1. The Object Inspector's layout.
2. Desktop icon tiles and label plates.
3. A token layer, which does not exist today.
4. Self-sizing buttons, toggles and chips.
5. Menu chevrons, which are typed into label strings today.

**Measured gaps** (from 3 research sweeps, 2026-10-16):
- **No token layer** (F1 built it: `Theme`, §4 F). Chrome colours lived in about 14 `PreferencesAndSettings` fields (`src/PreferencesAndSettings.coffee:140-233`) plus about 30 hard-coded sites (frame 125/248, menu 238/186, buttons 245/196, handle 150, slider black α0.4, inspector colours, the clock's `#325FA2`, …). There are 111 `Color.create` sites in `src`.
- **No focus state.** Only z-order exists (`Widget.bringToForeground`, `isInForeground`).
- **External frames stroke BEFORE their children.** `BoxyAppearance` has no `paintStroke`. `ClippingAtRectangularBoundsMixin` re-strokes after children only for appearances that do (`RectangularAppearance`).
- **Clipping is rectangular only.** SWCanvas does support `clip(path)`: `vendor/swcanvas/swcanvas.js` `clip(path, rule)`, a 1-bit stencil.
- **The bar strip and the body margin are fused.** `thickness = barIconSize + 2*barPadding` = 50, and `barPadding` = 3 is ALSO the body margin around the content (`FrameWdgt._barSpec`; the metrics live in `Theme` since F1).
- **Desktop icon holder.** `WidgetHolderWithCaptionWdgt` is 95×92: a 60 px icon band plus a 32 px band holding a white caption with a black outline. There is no tile, no plate and no selection state. The grid is `IconGridPanelWdgt`, column-major, 5 per column, pitch literals 105/102.
  - ⚠ Test worlds have NO desktop icons (`createDesktop` runs only `if theWorld.isIndexPage`, `src/boot/globalFunctions.coffee:485`).
- **Icons.** 9 of the ~89 icon appearances are size-aware (`src/icons/*` extending `SizeAwareIconAppearance`); 80 are legacy. Chrome glyphs (`Close`/`Collapse`/`Uncollapse`/`Pencil`/`Eye`/`OverflowChevron`) are all legacy rings and beziers in a 200-unit space, painted at `barGlyphSize` 24.
  - `SizeAwareIconAppearance._paintColoredIcon` IGNORES `@widget.glyphSize`, unlike legacy `IconAppearance.calculateRectangleOfIcon`.
- **SWCanvas has no `Path2D` and cannot parse SVG path strings.** A native `Path2D` handed to it silently draws the CURRENT path. ⇒ The draft's SVG icon geometry must be hand-translated into ctx calls, which is the size-aware skill's discipline anyway.
- **SWCanvas text.** Text comes from pre-rendered atlases (`Fizzygum/font-assets/`). They cover only Arial, Courier New and Times New Roman, at normal or bold × normal or italic, sizes 9–96 in 0.5 steps, dpr 1 and 2.
  - There are no weights 500/600 and no letter-spacing.
  - A glyph missing from the atlas paints a black box. The `➜` arrow is already known to be missing at 12 px.
  - Atlases are generated by the sibling repo `~/code/BitmapText.js` (`font-sets/*.json`).
- **The Inspector.** `InspectorWdgt._reLayout` is hand-written with fixed numbers:
  - The hierarchy is a diagonal staircase of `SimpleButtonWdgt`s plus angled arrows.
  - The toggles are `ToggleButtonWdgt` pairs reading "methods: on"/"methods: off".
  - The list (1/3) and the code pane (2/3) are two separately bordered viewports with a 5 px gap.
  - The footer buttons are 15 px tall.
- **Buttons.** `SimpleButtonWdgt`/`ButtonWdgt` have no intrinsic size; the parent dictates it.

**Test-delivery census** (the basis of phase T):
- 298 tests take screenshots. **160 of them assert no values**, so a click on the wrong target there shows up ONLY as changed pixels, which a recapture would then bake in.
- 162 tests contain no literal or relative aims. About 54 aim by offsets relative to a widget (`top()+12`, `.add new Point`). About 23 use chrome-assuming fractions (`win.bar [0.8,0.5]`, `win [0.5,0.02]`). 25 use off-centre fractions into TEXT, which are font-dependent.
- 4 numeric assertions encode chrome or font geometry: `CheckNumberOfItemsInWorldMenu` count 16, `ToolbarChevronPopsOverflow`, `SpreadsheetResizeViewport` `"20@10"`, and `TextWdgtCaretKeepsCorrectAlignment` 721×436.
- No test hits a chrome element by absolute coordinate. 37 right-click bare desktop at authored spots, which are placements, and fine.
- **Every widget-aimed press is now VERIFIED** (phase T, §4 T): it must land on the widget it means, or the test fails with "AIM MISSED"; a raw-Point press declares its receiver (`@pressMustLandOn`). Before T only `openOwnMenuOf`, `sliderButtonPressPoint` and `clickOnListItem` checked their aim — and 9 tests turned out to have never delivered their intent, a recapture having baked the misdelivery in.
- **Labels.** 104 tests find menu rows by EXACT label text (355 strings). The toolkit itself hard-codes `"dev ➜"`, `"inspect"`, `"connect ➜"`, `"connect to ➜"`, `"bind ⇄"` and `"disconnect"`. A missing label THROWS, so it fails loudly.

**Recapture cost** (the basis of phase R0):
- `fg recapture --auto` is mouse-only. Finger references can only be captured per test (`capture-macro-test-references.js <name> --pointer=finger`), and there are 1864 of them across 288 tests.
- Mass recapture runs at about 0.5–0.8 tests/min, about 7 h for the 3800-reference wave. It is serialized behind single-threaded zopflipng (open BACKLOG item "Mass recapture is serialized behind single-threaded zopflipng").
- Each full wave adds about 300 MB of git blobs. `Fizzygum-tests/.git` is already 3.1 GB.

---

## §0.5 Owner decisions — LOCKED 2026-10-16 (do not re-litigate)
1. **Fonts: map onto the existing atlases.**
   - Sans → `Arial, sans-serif`. Weight 600 → bold. Weight 500 → regular.
   - Mono → Courier New, keeping the existing `monoFontStack`.
   - Serif B/I → Times.
   - Letter-spacing is DROPPED.
   - The Snell Roundhand script "A" is DRAWN as an icon (size-aware), not typed.
   - Both backends use the same families.
2. **Focus: there is no focused-window state in this arc.** ALL windows wear the draft's BACKGROUND look:
   - `chrome` bar, `muted` regular 13 px title, a 1 px `line` rule under the bar, a `frame`-coloured border, and a 12% shadow.
   - The dark focused look (`chromeDark`, 16% shadow, white glyphs), and the desktop icon "selected" accent that implies a selection model, are a FUTURE focus arc. File them in BACKLOG at P0.
   - Keep ONE derivation point for the frame look (`FrameWdgt._frameLook()` or equivalent) so that arc plugs in.
3. **References live on redesign branches and are squashed at the end.**
   - Visual waves W1–G are committed on a `redesign` branch in BOTH repos, one commit per phase, each with owner approval.
   - Zero-pixel phases (R0, T, F) land on `master` normally.
   - At Z, `Fizzygum-tests`' branch is `git merge --squash`ed into master as ONE commit, so only the final references enter master history.
   - The tests branch MAY be pushed to origin for backup, but it MUST be deleted from origin after the squash. Clones never fetch unreachable objects.
   - `Fizzygum`'s branch merges normally.
   - Master stays green throughout: the two repos' `redesign` branches always pair with each other, and the two masters always pair with each other.
4. **Wording: ADOPT the draft's wording, as a SEPARATE late phase (W6)**: sentence case, human names instead of class names, and "…" on rows that open a dialog.
   - The menu's STRUCTURE (row order and groups) is NOT reorganised.
   - "Delete all" is NOT coloured red. It does not gain "…", because it opens no confirmation.
   - Until W6, labels stay byte-verbatim. The only exception is the trailing `" ➜"`, which becomes a drawn chevron in W2 (see §3).

---

## §1 Mapping the flat draft onto Fizzygum's widget TREE (owner note 1)

The draft paints in flat, page order (`desktop-canvas.html` §6: "titleBar drawn on top of the window"). Fizzygum paints a TREE: parent first, then children. Each pixel of the draft must therefore have exactly ONE owning widget.

| Draft element | Owner in the Fizzygum tree | Note |
|---|---|---|
| Window shadow, fill, 1 px frame "stroked last" | `FrameWdgt` body appearance (`BoxyAppearance`) | F2a: `BoxyAppearance.strokesOverChildren` makes the clipping mixin stroke the outline after the children (off until a wave switches it on). The shadow is `ShadowInfo`. |
| Title bar fill `[7,7,0,0]` + bottom rule | `FrameBarWdgt`'s `titlebarBackground` child | The rule is the BAND'S OWN edge (§2 rule D): the bar paints its bottom rule. Corners: 7 = 8 − 1 (frame radius minus the border), so the bar sits inside the 1 px frame. |
| × / − glyphs in 44×44 targets, left edge | `CloseIconButtonWdgt`, `CollapseIconButtonWdgt` (in a `SwitchButtonWdgt`), children of `FrameBarWdgt` | Already left. New size-aware glyph art, drawn at `glyphSize` 14. |
| Title text centred between 88 px insets | `FrameBarWdgt` label `StringWdgt` | 88 = 2×44 falls out by itself once the bar's inner padding is 0 (today it is 97 = 3 + 2×47). |
| Pencil | `EditIconButtonWdgt` (trailing piece) | — |
| Resize grip 36, 3 px in from the corner | `HandleWdgt` child of the frame (`CornerInternalLayoutSpec 'bottomRight'`) + `HandleAppearance` | — |
| Embedded toolbar with a left title strip | A docked `FrameWdgt` (card) holding `TextToolbarWdgt`; its `FrameBarWdgt` runs vertically | Already this structure. |
| Paragraph item block | `SimpleTextWdgt` paragraphs in `DocumentViewportWdgt` (vertical stack) | Background, radius and padding become tokens. |
| Menu container / header / rows / group rules | `MenuWdgt` (transient `FrameWdgt`) → bar (header) → `PopUpRowsViewportWdgt` → `CommandPanelWdgt` → `MenuItemWdgt` rows + `DividerWdgt` | Group rules = `DividerWdgt` restyled. Remove the per-row hairline. |
| Inspector bands and list\|code line | `InspectorWdgt` children; the rules are CONTAINER-owned seams (§2) | — |
| Desktop tile + glyph + label plate | `WidgetHolderWithCaptionWdgt` (icon band + caption band) | The tile and plate are painted by the holder's own appearance (new). The glyph is the icon widget. The caption is the `TextWdgt` on the plate. |
| Clock | `AnalogClockWdgt` + `AnalogClockAppearance` | The face becomes an opaque paper disc, so the shadow is one disc. |

---

## §2 The single thin line between panes (owner note 9): the answer

**The question.** The draft shows ONE 1 px line between the list and the code pane, one under the bands and one above the footer. Do the panes keep their own borders, sized so the borders coincide? Or does something else draw the lines?

**The options weighed.**
- **A. Each pane keeps its border, and the panes overlap by 1 px** so that two borders land on one line.
  - ✗ Rejected. Each seam pixel is then owned by two widgets, which breaks hit-test and damage ownership.
  - Under AA the double-painted line darkens.
  - Correctness depends on z-order and on both panes using the same colour.
  - Every resize must keep re-establishing the overlap.
- **B. The CONTAINER owns the seams.** Panes are borderless. The container's layout places adjacent children exactly 1 px apart, and the container's appearance fills those 1 px gaps with the `chrome` token.
  - One line per seam BY CONSTRUCTION, at every size. Every pixel has exactly one owner.
  - A pane reused elsewhere carries no stray line.
  - This is what CSS `gap` + background, `NSSplitView` (which draws its own divider) and Fizzygum's own border-layout composition (`docs/architecture/layout.md` §4.2: "dividers at the seams") all do.
- **C. An explicit 1 px divider widget between the panes.**
  - Inspectable, but it adds a tree node per seam for paint alone.
  - A 1 px widget can never be a ≥44 touch target, so it cannot also be the drag handle.
- **D. A band paints its own edge rule** (CSS `border-bottom`).
  - Right when the line is part of the band's OWN look whatever its neighbour is, e.g. the title bar's bottom rule or the menu header's rule.
  - Wrong for a seam between siblings: the line would move with the pane.

**Decision.**
- **B for every seam between siblings. D only for a band's own edge.** Both rules go into the design-system doc.
- **The mechanism (F2d):** a container declares its seams as a list of local rectangles (`_seamRects()`), and its appearance fills them with the `rule` token AFTER its own fill and BEFORE its children. The seams are gaps, so the paint order is never contested.
  - The Inspector's hand `_reLayout` computes its seams directly: it places the panes 1 px apart instead of 5.
  - `StackLayoutEngine` containers can offer the same knob generically from their gaps. That generic knob is built in G only when a second composite needs it. The Inspector stays a hand layout for now: lower risk, 18 tests.
- **Resizing the split stays a halo affordance.** The halo already inserts `StackElementsSizeAdjustingWdgt` dividers at division seams. A permanent ≥44 drag target cannot hide inside a 1 px line ("a target never extends beyond the widget that owns it").
- **Simplest, too.** For the Inspector, B is three edits: drop both pane borders, use 1 px gaps instead of 5, and paint the seam rectangles. There is no new widget and no layout-engine change.

---

## §3 Design-to-capability trade-offs (owner note 8). Defaults chosen; the owner reviews them visually at each wave

| # | Draft wants | Fizzygum reality | Decision |
|---|---|---|---|
| 1 | Menu header 32 px | Tapping the header PINS the menu; the 44 floor is deliberate (`FrameWdgt._transientBarSpec`) | **Keep 44**. The draft's own §4 says every target is ≥44. Restyle it flat: paper fill, 11 px `muted2`, 1 px `chrome` rule. |
| 2 | `›` chevron, right-aligned | `" ➜"` is typed into 31+ label strings, and SWCanvas lacks the glyph at small sizes | By §3b it is an ICON (a row indicator, not label text). **W2:** a row flag (`opensSubmenu`), set where the submenu row is built, plus a DRAWN size-aware chevron. The `" ➜"` leaves the label. The 26 tests' strings and the toolkit's labels are swept in the same phase; a stale label fails loudly. |
| 3 | `×`, `−`, `›`, `»`, `…`, `—`, `✓` | Mixed today: some typed into text, some drawn | **Classified by meaning, §3b.** Control faces and indicators are icons. Characters that belong to a label's text are glyphs, sourced from an atlas. |
| 4 | Content flush to rounded window corners | Rectangular clip only; opaque flush content leaves "ears" outside the radius-8 corners | **§3a.** Top corners: per-corner bar radii (solved). Bottom corners: the host imposes its corner radii on flush content, painted with per-corner fills (no clip). Spike S1's census decides whether a corner-square clip is also needed as a backstop. **Measured in F (§4 F, S1/S1b): (d) alone covers only 19 of 71 content groups; the corner-square clip (a) works and is deterministic but costs +7 % (dpr 1) / +12 % (dpr 2) suite time because of SWCanvas's canvas-sized clip masks — **OWNER DECISION (2026-10-17, confirmed): S1c — optimise SWCanvas's clip tiers, re-measure with the S1b harness, adopt the frame's rounded child clip iff ≤ 3 % at dpr 1 and 2.** Per-corner radii alone were weighed and set aside: they cover only content whose corner pixels are its OWN background (option (d), 19 of 71 groups); scrolled viewport content, children on the corner, the spreadsheet and palettes need a clip or an inset. The rejected alternatives: a hybrid (per-corner radii + a 3 px bottom-corner inset for edge-painting content: loses the flush look on viewports, the commonest content, and every new content widget must cooperate) and (e) square bottom corners. They return only if S1c misses the 3 % bar. |
| 5 | Grip hit area = its 36×36 square | Today's hit area is a triangle (`HandleWdgt` `x/w+y/h ≥ 1`) | **Square per the draft.** T makes the toolkit's resizer aim ask the handle's own hit test, so the shape change is safe. |
| 6 | Icon grid rows as tall as their tallest icon | `IconGridPanelWdgt` places each icon incrementally (`n%5` arithmetic) | **W4 decides.** Default: a uniform row pitch sized for two-line labels (simple). Per-row heights need a whole-grid re-layout on add; do it only if the owner asks at review. |
| 7 | Tool buttons spread space-between | `ToolPanelWdgt` cell grid | **W5:** check the capability first; fall back to fixed 8 px gaps. |
| 8 | Hover looks (not in the draft) | Today: orange or red glyph recolour, SILVER/GRAY rows | Propose: menu row hover = `desk` rounded 6; button pressed = `chrome`; bar glyph hover = `ink` glyph on a `desk` rounded-6 plate. These are tokens, reviewed at W1/W2. |
| 9 | Uncollapse glyph (not drawn) | `UncollapseIconAppearance` | Propose a plain `+` (14 px, 2 px stroke); owner review. |
| 10 | Inset stroke rule `r − b/2` | House crisp spelling: `strokeRoundRect 0.5,0.5,w-1,h-1,r`, same `r` (one crisp spelling, SWCanvas fast path) | **Keep the house spelling.** The half-pixel radius difference is invisible on SWCanvas. |
| 11 | Desktop selected icon (accent) | No selection model | Deferred with focus (§0.5.2). |
| 12 | Plain `desk` wallpaper | The homepage default is the "dots" pattern on (244,243,244) | **Plain `desk` by default** (the draft). Wallpaper choices are unchanged. The test world's 205 grey becomes `desk` in W1. |
| 13 | 44×44 targets "everywhere" | Content widgets (spreadsheet cells, patch pins, sliders inside content) are smaller by nature | **The 44 rule binds CHROME**: bars, menus, toolbars, buttons, handles. Content keeps its own sizes ("keep the original's structure", draft §10). G records this in the design-system doc. |
| 14 | Icon stroke 2 units at 40 px = 1.82 px | The skill's line unit `t = max(1, round(S/32))` gives 1 px at 40 | **W4:** the redesign family uses a weight-matched unit, `t = max(1, round(S/22))` (2 px at 40, 4 at 80, 3 at 60). The owner approves the weight at the flagship size, and that becomes the unit floor (skill lesson 27). |

### §3a Rounded window corners vs rectangular clipping: the risk in detail

**What happens.**
- The draft's window is a radius-8 rounded box with a 1 px frame, and its content runs FLUSH to the frame. For example, the Inspector's seams and bands span the full width.
- In Fizzygum the content is a CHILD widget with its own RECTANGULAR bounds. Its background is often opaque: viewports, panels, the document viewport, the spreadsheet grid, an image.
- A frame clips its children to its bounding RECTANGLE (`ClippingAtRectangularBoundsMixin`). That rectangle does not follow the radius, so a flush child's square bottom corners paint OUTSIDE the window's rounded outline, onto pixels that should show the desktop or the wallpaper behind the window.
- Measured on pixel centres, for outer radius 8 and a child inset 1 (just inside the border): 3 pixels per bottom corner land outside the outer curve.
  - On non-AA SWCanvas that is a small staircase "ear" of content colour against the wallpaper, on EVERY window with opaque flush content.
  - It is baked into every reference.
  - The pixels between radius 7 and 8 overlap the border ring; the stroke-last frame (F2a) repaints those.
- Hit-testing has the same flaw. The frame's own corners are pointer-through today (`BoxyAppearance.shapeContainsPoint`, pinned by `SystemTest_macroRoundedBoxCornerClickThrough`). A flush rectangular child would catch presses in those notches.

**Why today is fine.** The body margin is 3 and the radius is 4. A child inset 3 has its corner-pixel centre at distance (7.5−3)·√2 ≈ 6.4 ≤ 7 from the inner curve's centre, so it stays inside the border at radius 8 too.

**Why the draft never hits it.**
- It never lets a child fill reach a corner.
- The title bar carries its own `[7,7,0,0]` radii, so the top corners are solved by the CHILD rounding itself.
- The footer has no fill of its own.
- Fizzygum cannot rely on that: content types are open-ended.

**What per-corner radii change** (SWCanvas `60e7e3e`, Fizzygum pin `b6b221bd`, 2026-10-15: HTML5 per-corner radii on every roundRect entry point, plus the standard `ctx.roundRect()` path method, with an axis-aligned direct fast path):
- **The TOP corners are solved outright.** The bar background paints `[7,7,0,0]`, a collapsed bar `[7,7,7,7]`, and a docked strip `[5,0,0,5]`. These are plain fast-path fills, the draft's own technique. This is exactly the follow-up that arc deferred to "a larger redesign".
- **Option (d) below becomes cheap and crisp.** A flush child whose only corner-reaching pixels are its BACKGROUND (viewports, panels, the Inspector's panes, the document viewport) paints that background with the host's bottom radii, e.g. `[0,0,7,7]`. That is one direct per-corner fill on SWCanvas: no clip, no stencil, byte-deterministic.
- **Under a tilt** (transform islands) per-corner FILLS cost nothing extra, because tilted fills take the generic pipeline whatever the radii. Only per-corner STROKES slow down (~8×, 1 px up to ~70×, per the header of SWCanvas's `RoundedRectOpsRot`), and no element of the design strokes per-corner: the frame, card and chip outlines are uniform.
- **It does NOT change two things.**
  - Content that paints its OWN pixels into the corner squares still escapes a rounded background: an image, a canvas, spreadsheet cells, text that runs to the edge.
  - The cost of a true clip is unchanged. A per-corner clip path is now ONE `roundRect` call, but SWCanvas still rasterizes any path clip through its 1-bit stencil rather than its fast rectangle tier.
- **Hit-testing must follow the same shape.** `BoxyAppearance.shapeContainsPoint` uses ONE radius for all four corners today; it must read per-corner radii (F2a).

**The options.**
- **(a) The frame clips its body to its rounded shape**, as CSS `overflow:hidden` + `border-radius` does. One mechanism in one place; no content cooperation needed. SWCanvas supports `clip(path)` through a 1-bit stencil; native clips with AA.
  - **Cost:** a path clip leaves SWCanvas's fast rectangle-clip tier and may defeat its direct dispatchers for every fill under it.
  - **Mitigation:** clip only the corner SQUARES (8×8 at radius 8) a damage rectangle touches. Most repaints inside a window touch no corner and keep today's rectangular path. Child hit-testing must be clipped to the same shape. Since per-corner radii, (a) is the BACKSTOP behind (d), not the default (decision procedure below).
  - Must stay byte-deterministic, and must work through `BackBufferMixin` and the transform-island buffer cache.
- **(d) The host imposes corner radii on its content.** The frame tells a flush child "your bottom corners are r 7" through its layout spec, and the child's background paints a per-corner rounded rectangle (F2a).
  - No clip, but it only fixes content whose corner pixels are its BACKGROUND.
  - An image, a canvas, a spreadsheet grid or a scrolled document painting text to its edge still escapes.
  - That makes it a partial-sweep risk.
- **(b) Keep a 3 px body inset.** Zero mechanism. But rules and backgrounds stop 3 px short of the frame, which shows as a gap at the ends of every seam: the draft's flush look is lost.
- **(e) Square bottom corners** (round only the top). Simplest, but a design deviation. It is the owner's call if (a) fails.

**Decision procedure (spike S1, before W1).** Per-corner radii reorder it: (d) is now the cheap default, and the question is how much content it leaves uncovered.
1. **Census first.** Lay every content type that can sit flush in a frame (each `FrameWdgt` payload class: viewports, panels, documents, the Inspector, the spreadsheet, images, canvases, plots, patch panels, folder windows) at margin 0, in a radius-8 frame. Record which ones paint non-background pixels inside the bottom corner squares. Probe on SWCanvas at dpr 1 and dpr 2.
2. **If that set is empty, or each member can keep an inner padding of its own:** adopt (d) alone.
   - The frame imposes its bottom corner radii on its flush content through the content's layout spec (`FrameContentLayoutSpec`).
   - The content's background appearance paints with them.
   - There is no clip machinery, and the body margin goes to 0 in W1.
3. **Otherwise,** add (a) as the backstop for that set only.
   - The frame clips the corner SQUARES (not the whole damage rectangle) with the rounded path: split a corner-touching damage rectangle into its corner squares, clipped, plus the rest, rectangle-clipped. The stencil cost is then proportional to 4×64 px, not to the window.
   - Measure dpr1/dpr2 suite wall time (adopt if ≤ 3% slower), byte-determinism (run twice; the gauntlet's dpr2 leg), the back-buffer and island paths, and notch hit-testing.
4. If neither holds, bring (b) or (e) to the owner with the numbers.

### §3b Symbols: a text glyph or an icon? (owner principle, 2026-10-16)

Classify every symbol by its MEANING, never by how the web usually draws it. Fonts are not a vector-graphics format: no icon fonts, and no glyphs standing in for icons.

- **An ICON** is a symbol that stands on its own, as a control's face or as an indicator of state or behaviour. It is a size-aware `IconAppearance`, never typed into a string.
  - × − + (close, minimise, restore)
  - › (submenu chevron, breadcrumb separator)
  - » (overflow)
  - ✓ (a ticked row)
  - the grip
  - the toolbar's B / I / `</>` / script-A faces. These are already `BoldIconAppearance`, `ItalicIconAppearance`, `FormatAsCodeIconAppearance` and `ChangeFontIconAppearance` in `src/authoring-icons/`, restyled in W5.
  - ⚠ Two of these are typed into label text TODAY and move out in W2: `" ➜"` (31+ sites) and the tick prefix `"✓ "` (`src/boot/extensions/String-extensions.coffee`, `MenuRowReflectionSpec`). Each becomes a row flag plus a drawn icon. `MacroToolkit.tickedRowLabelOfMenu` then reads a plain label.
- **A GLYPH** is a character that is part of a label's or text's OWN wording. It would be copied with the text, and it is part of the string's identity.
  - "…" in "Save world snapshot…"
  - "—" in "Object Inspector — Docs Maker"
  - the `fn`/`var` tags
  - "⇄" in "bind ⇄", if W6 keeps it in the wording

  A glyph renders from a font atlas. Where an atlas lacks it, ADD it; never substitute an icon. There are two homes:
  - **The font's own atlas (font-specific).** For typographic characters of a font's repertoire (… — – ‘ ’ “ ” • ‹ ›): they must match the font's weight, style, metrics and kerning, and exist in its bold and italic variants.
    - BitmapText's standard set is ASCII + a CP-1252 subset + Latin-1 Supplement (`~/code/BitmapText.js/docs/FONT_SET_FORMAT.md`), so … and — are probably present already. "save world snapshot…" renders correctly today.
    - Adding one means extending the standard set in `src/builder/create-glyphs.js`, regenerating, and re-vendoring through `Fizzygum/scripts/vendor-swcanvas-fonts.sh`.
  - **The dedicated symbols atlas.** For font-independent symbols that can sit inside text but which no text font supplies consistently: arrows like ⇄ ↗, ✔, box-drawing.
    - It already exists: `BitmapTextInvariant`, which holds ☺☹♠♡♦♣│─├└▶▼▲◀✔✘≠↗ and redirects to them at runtime whatever the base font (`SWCanvasElement-extensions.coffee` loads it as a companion).
    - A new symbol extends its predefined set in the same `create-glyphs.js`.
- The spike S2 inventory applies this classification to every non-ASCII character in src label strings, test strings and the draft. It records glyph-or-icon for each, checks atlas coverage, and lists the atlas additions (font-specific or invariant) as a W2/W6 unit.

---

## §4 Phases

Every phase lists its units. Each unit is ONE bounded, delegable brief with acceptance criteria (see §6 Orchestration).

### P0 — Set up (docs only; ask before every commit)
1. Commit this plan together with the four design files beside it (untracked until P0).
2. Add a `docs/BACKLOG.md` pointer to the plan. File the deferred focus arc there (focused look + icon selection).
3. Do NOT create the `redesign` branches until W1 starts. R0, T and F land on master.

### R0 — Recapture tooling (tests repo; zero pixel change) — ✅ DONE 2026-10-16
The arc recaptures 7–10 times, so this came first. As executed (both runs below are reproducible from `Fizzygum-tests/.scratch/r0/`):
- **R0.1 Batch finger recapture.** `scripts/recapture.js --pointer=finger` (through `fg recapture`, which passes flags straight on). A run handles ONE pointer kind end to end: the clean, every capture and verify, and the suite gate are scoped to it. A mouse-only test (`pointerKinds`) is passed over as TEST SKIPPED, never counted as a capture failure. A full wave is `fg recapture --auto --dprs=1,2`, then the same with `--pointer=finger`.
  - Proof: 3 tests recaptured for each kind (one of them mouse-only, correctly skipped for finger), with the gate green at dpr 1 and 2. Every recaptured filename (which names its pixel hash) came back identical.
- **R0.2 Throughput.** Captures run `--jobs` at a time (default 6; each its own browser, launches staggered 1.5 s apart against the boot-storm flake). The test manifests are generated ONCE after the clean and kept by every capture (`--keep-manifests`), and no capture kills a sibling's browser (`FIZZYGUM_KEEP_STALE_BROWSERS`). The captures skip their own recompress; the files they wrote are recompressed afterwards in ONE pass, `scripts/recompress-swcanvas-references.js <files…> --jobs <cores−2>`.
  - **Measured** (20 of the heaviest tests, 212 references): captures 66 s, recompress 65 s, gate 77 s + 87 s. A full wave projects to ~30 min per pointer kind, ~1 h for both, against ~7 h serial before.
  - **Found and fixed on the way: fresh captures were committed UN-optimized.** Since the 2026-08-25 switch to the native PNG encoder, a capture is ~40–100 KB. The recompress DIRECTORY scan skips anything under its 100 KB "already small" threshold, so 1462 of 3808 committed references are ~10× larger than zopflipng makes them (e.g. 38.8 KB → 3.5 KB). Every capture path now NAMES the files it wrote, which a size threshold never skips.
  - **zopflipng rejects some valid Chrome PNGs** ("invalid ADLER32" on a stream Node's zlib verifies); such a file is now retried with optipng (137 KB → 12 KB), pixels re-verified.
  - **Owner decision (2026-10-16): the 1462 oversized references are NOT shrunk now.** The visual waves' recaptures rewrite nearly all of them through the fixed capture paths. A one-off `--min-size 0` pass over whatever survives to Z is the owner's call then.
- **R0.3 Review sample.** `docs/plans/redesign/review-sample.txt`: 23 tests covering every surface. Every wave's owner review runs `fg diffpage $(grep -v '^#' Fizzygum/docs/plans/redesign/review-sample.txt)` before any recapture.
- Gates: `npm run selftest` and `fg lint` green; the recompress `--check-only` gate still verifies all 3808 references.

### T — Tests aim by meaning, and every aim verifies its hit — ✅ DONE 2026-10-16 (its 9 never-delivered tests are fixed in source and recaptured with owner approval — see "Findings")
The goal: a geometry change can break PIXELS, never DELIVERY. As executed (probes, data and briefs under `Fizzygum-tests/.scratch/{t1,t2-research,t3}/`):
- **T1 Verifying aims — the runtime gate.** Every verb that knows the WIDGET it aims at runs its gesture inside `MacroToolkit._aimingAt`; every press the toolkit queues goes through ONE door, `_queuePress`, which puts an `AimCheckInputEvent` (new, `src/macros/`) in front of the first press that finds an expectation pending. The check DRAINS immediately before the press, so it reads the world the press meets (`verifyPressLanding`); a miss is recorded as "AIM MISSED" (an assertion failure — the macro runs on). A macro declares the receiver of a raw-Point press with `@pressMustLandOn widget` (also the click-THROUGH form); the legitimate literal kinds are `clickOnDesktopAt_InputEvents` (verified: bare desktop) and `dropCarriedWidgetAt_InputEvents` (deliberately unchecked; a drop INTO a container is followed by a landing assertion).
  - **Measured first** with an in-page REPORT-mode twin (`.scratch/t1/aim-audit-prelude.js`) over the whole suite at both pointers: checking at queue time and checking at drain time differ in exactly ONE mechanism — the pointer's ARRIVAL fattens a thin scroll indicator (a mouse's approach before its press; a finger's down WITH it). So the check runs at drain time, and for a touch press `_widgetAPressMeets` asks the product's own arrival derivation (`ViewportWdgt.barScreenFrameOnArrival` / `buttonScreenBoxOnArrival`). Result: 983 + 914 widget-aimed presses OK; the misses were 2 deliberate click-throughs and 1 mis-named strip piece (now declared), and 1 test that never delivered its intent.
  - ⚠ An aim-check label must never equal the verb's own method name: `check-dead-methods` counts any string as a reference, so a verb naming itself could never be reported dead (found when `shiftClickAtFractionOf` lost its last caller; it is deleted).
- **T2 Meaning verbs** (`MacroToolkit`; each a side-effect-free locator that KEEPS a caller's working point and otherwise asks the product's own hit test):
  - windows: `titleGrabPoint frame[, preferred]` → `{point, piece}` (the title or the strip background, never a button; `FrameBarWdgt.catchesPointerAt` is false, so a press never meets the bar itself), `dragWindowByTitleBy/To_InputEvents` ("To" = the frame's TOP-LEFT, so the press point does not matter; a no-hold chrome drag under finger), `dwellDragWindowByTitleToEmbed_InputEvents_Macro frame, dropPoint[, topLeft]`, `contentPointOf frame`, `screenTopLeftOf`;
  - handles: `_handlePressPoint` (keeps today's quarter-box-deeper corner point while a press there meets the handle, else scans from the anchored corner; a rotate handle's point is never moved), `resizeWindowBy/To_InputEvents`, `resizeWidgetBy_InputEvents` (the EXTENT change, independent of the grip's size and inset);
  - lists: rows found by IDENTITY (`labelString`), aimed through `row.label` as before; the scroll pitch from two rows (top-to-top) and the rows panel's padding;
  - text: `textSlotScreenPoint text, slot` (verified with the text's own `slotAt`) and `clickOnTextSlot` / `doubleClickOnTextSlot` / `tripleClickOnTextSlot` / `shiftClickOnTextSlot`;
  - carrying: `pressToCarry_InputEvents` — the press of a split press-then-carry (a mouse's `moveToAndMouseDown`; a finger's HOLD, since a plain finger drag over a scrolling pane scrolls it);
  - `spreadsheetCellAt sheet, address` (the cell widget, by its address and the capability a cell answers — no type test, no edge into the lazy spreadsheet part);
  - `autoScrollBandPointOf viewport, side, depth`; `buildOverflowingViewportWithText` keeps its AUTHORED 270×200 / 185 / +12 inputs (from the recorded test it migrated — no measured formula yields them) and ASSERTS the overflow it exists for.
- **T3 Conversions** (each pixel-identical by construction or by measurement; gated at mouse + finger × dpr 1 + 2): ~20 title-strip drags, every bare-desktop press (`clickOnDesktopAt`, 95) and named drop (24), every other raw-Point press onto a widget declared or rewritten (181 presses in 101 tests), 28 text clicks onto slots with caret/selection assertions, 53 resize drags by EXTENT (`resizeWindowBy` / `resizeWidgetBy`, the measured exact deltas). The metadata of every converted test was then made true again (42 files: resize amounts quoted from where the old verbs dropped the grip's centre were ~25 px off, and stale spreadsheet grid numbers). Left by design: right-clicks into text (the menu opens AT the pointer), clicks that open the cropped-string prompt, `macroTextWdgtCaretPlacementUnderAlignments` (its subject IS the fraction under two alignments), transform-island tests (their subject is the screen→plane mapping), and the 4 numeric assertions — those already fail LOUDLY on a geometry change (a count of hidden toolbar cells, an asserted extent), which is the property T wants; re-expressing them would only save a later edit.
- **T4** `Fizzygum-tests/scripts/aim-census.js` — a measurement: categories per site, `verified` per site, and the work list (flagged and not verified, plus every text fraction: verification proves the widget, not the slot).
- **Findings — tests that never delivered their intent** (each passed, because a recapture had baked the misdelivery into its references; each is now fixed in source, with value assertions of the intent, and its references were recaptured with owner approval):
  - `macroPinnedMenuKeepsCorrectShadowWhenBroughtToForeground`: its raises aimed at `menu.label`, a hidden StringWdgt left at (0,0) on a pinned menu → clicked the desktop (committed image_4 == image_3); its rectangle was dropped wholly inside the menu, so the overlap it tests never existed.
  - `macroDragEmbedRepositionNestedWindowStaysWithoutDwell`: every drag aimed at a collapsed title's stale centre and dragged the PANEL; legs B and C (detach, land on world) never ran.
  - `macroPromptShadowFollowsOnDrag`: after the first grab the title was collapsed off-screen; two drags met nothing.
  - `macroMenusAndSubMenusRemainOpenWhileDraggingMenusOnly` (finger): the hold-then-drag translation of a title-strip drag opened the strip's context menu and tore the cascade down.
  - `macroScrollPanelUpdatesCorrectlyOnCollapsingAndUncollapsingAndClosingWindow`: a drag pressed the uncollapse glyph (mouse image_4); and found at the owner's review of the new pictures, its "parked fully inside the viewport — no scrollbars" bar overhung the viewport by 7×5 px (both thin scrollbars showing at images 4 and 6, in the old references too): the park spot was a literal written for an older bar size. It now parks the bar its own extent in from the pane's corner and asserts the scrollability at images 4–6. ⚠ A placement, not a press — no aim check sees it; only a value assertion does.
  - `macroMenuPinnedInScrollPanel`: its "dismiss the world menu" click landed on the "wallpapers ➜" row and opened that submenu.
  - `macroSubMenuDroppedIntoPanelPinsItself`: its "bare desktop" click landed inside the world menu (menus had grown 44 px rows since the test was written); the menu was never dismissed.
  - `macroTextWdgtCaretResizing`: its "resize" drag pressed the ROTATE handle — since the 1920×880 recapture (Fizzygum-tests 530b49d4e) baked a small rotated box in; the caret-grows-with-font claims were never exercised. Re-authored against the 905×386 extent its carves were written for (from the pre-1920 references); its metadata claimed fonts "~20→30→60→90 px", the measured truth is 24→56→96→96 (SWCanvas caps a fit at 96).
  - `macroCompositeDragsAsUnitIntoScrollPanel` (finger): split press + carry primitives are a plain finger drag, which SCROLLS a pane instead of lifting; `pressToCarry_InputEvents` says "carry" (a hold under a finger) — and the fixed finger images are byte-identical to the mouse references. A scan of 25 sibling split-carry tests found no other.
  - ⭐⭐⭐ The lesson: a green screenshot test whose aim is not verified certifies only that the pixels are what they were — a recapture after any geometry change converts a misdelivery into the reference. T1 is the gate that makes that impossible from now on.
- Gates: `fg presuite` per unit; at close `fg gauntlet`, `fg finger`, the finger dpr1 suite.

### F — Foundations: tokens, primitives, spikes — ✅ DONE 2026-10-17 (zero recapture except ONE benign inspector member-list shift, recaptured with owner approval — see "Findings")
The system's look now has ONE home, and every primitive the waves need exists, each landed pixel-neutral. As executed (research data, probes and briefs under `Fizzygum-tests/.scratch/{f1,f2b,f2c,f2a,f2d,f2e,f2f,s1,s1b,s2,s3}/`; the living description is [`../../architecture/visual-design-system.md`](../../architecture/visual-design-system.md)):
- **F1 `Theme`** (`src/Theme.coffee`, `WorldWdgt.theme`, built with each world, never saved in a snapshot). Five sections: PALETTE (the draft's 22 colours at draft values; read by nothing yet except `seamRule`), ROLES (~90, one per SURFACE at today's exact value — two surfaces sharing a value hold two roles), FONT ROLES (`@fonts`, plain `{family, size, bold}`: menuRow, menuHeader, windowTitle, buttonLabel, defaultText, tooltip, speechBubble, prompt, desktopCaption), METRICS (the chrome metric fields, same names), SHADOWS (desktop / pop-up / drag-lift offset+alpha, `shadowColor`).
  - **Census first** (read-only): 313 colour literals in src — CHROME 133 (the plan's "~30" was 120 outside the prefs), CONTENT 84, ICON 45, OTHER 28, BORDERLINE 23.
  - **F1a** moved every VISUAL `PreferencesAndSettings` field (14 colours, 13 fonts, 13 metrics) onto Theme and swapped ~150 readers in both repos (the serialization rig's prefs assertion now reads the theme); prefs keep behaviour only. A field read by several surfaces SPLIT into one role per surface (tooltip / speech-bubble fill and stroke, plot background).
  - **F1b** moved every instance-level chrome literal (75 lines, 38 files) onto 66 new roles, plus the three shadows, the menu/tooltip/speech-bubble radii and the chrome font families. **F1c**: every shadow silhouette reads `shadowColor` (the boot primitive takes it as an ARGUMENT — boot code knows no world); the `raw-chrome-color` stink (`check-stinks.js`: per-stink `exclude` path prefixes + `stringAware`) baselined at **98**.
  - **Left on purpose, counted by the ratchet** (each moves with its family's wave): the 29 CLASS-LEVEL / mixin state colours (a class-level declaration may not reference another class, the state machines copy them, and `HighlightableMixin.color_hover` is the subject of a mixin-editing test), the 12 wallpaper-pattern strings (a wallpaper design's own colours, not a role — §3 #12), 4 transparent clears, the clock's `'#D40000'` (its `drawSecondsHand` source is SHOWN in `macroAnalogClockInspectEdit`'s inspector: any text change moves pixels) and two dead clock colour arguments, the spreadsheet's 7 look colours (G family), and 41 non-chrome literals in counted files (palette data, the paint tools' source strings, debug/DOM sites).
- **F2a** `BoxyAppearance`: per-corner radii (`cornerRadius` = a number or an HTML5 `[tl, tr, br, bl]` array; ONE normaliser; a uniform radius still reaches `fillRoundRect` as the same scalar), `shapeContainsPoint` per corner AND corrected to the FILLED pixels (pixel centre inside the outline — it was asymmetric: an r4 corner caught 6/10 notch points at bottom-left and 9/10 at bottom-right), and a `paintStroke` after-children entry behind the knob `strokesOverChildren` (default OFF ⇒ today's order exactly). ⚠ The plan's premise "today's content is inset 3 and never overlaps the stroke" is FALSE for pop-ups (padding 0, rows at inset 2): with the knob ON, a titled pop-up changes 2 px at dpr 2, a pinned menu 24 px, an overflowing pop-up hundreds at both dprs (scrolled rows and the thin bar under the ring) — the overlap table W1/W2 should expect when they switch it on (`.scratch/f2a/overlap-analysis.js`). Windows are neutral only because `windowBarFill` = `windowFrameStroke` = 125 today.
- **F2b** `SizeAwareIconAppearance` honours `glyphSize`: `_paintBoxInDevicePx` gives a glyphSize'd widget the centred g×g square (integer, clipped to it); the unset path is untouched — ⚠ it must keep today's FLOOR centring, since a desktop icon's box is a NON-square 95×60 and `calculateRectangleOfIcon`'s rounding would move every desktop icon 1 px. Golden master (all 9 size-aware icons × 27 ladder sizes × 2 backends, square AND non-square boxes, 810 renders): byte-identical before/after.
- **F2c** seven chrome icons as new size-aware classes, named for their SHAPE (the button carries the meaning): `Cross`, `Minus`, `Plus`, `ChevronRight`, `DoubleChevronRight`, `Tick`, `Grip` `IconAppearance`s — the draft's SVG paths hand-translated (no Path2D on SWCanvas); line unit = the 45° stroke's row RUN, ends n/4 inside pixel corners (a round-cap tie fix measured on SWCanvas); the tick is our own design (the draft has none). Node renders 217/217, browser 434/434 (SWCanvas byte-identical to node). Preview for the owner's review at W1/W2: `.scratch/f2c/preview.html`. ⇒ **W1 does NOT rewrite the legacy Close/Collapse/Uncollapse appearances in place**: the buttons wear the new shape-named classes and the legacy appearances are deleted.
- **F2d** seams: `Widget._seamRects()` (none by default) + `Appearance._paintSeamRules`, called by `RectangularAppearance` and `BoxyAppearance` after the fill and before the children, in `seamRule` (= palette `chrome`).
- **F2e** font roles: `StringWdgt` takes `opts.fontRole` (explicit fontName/fontSize/bold still win; no role = `fonts.defaultText`); `LabelButtonWdgt`, `MenuItemWdgt`, `StringFieldWdgt` forward it; 20 chrome construction sites converted. No `fonts.code` yet: the mono sites set only the family after construction (`_setFontNameNoSettle`) at TextAreaWdgt's default size — W3 (the Inspector's code pane) gives them the role.
- **F2f** `FrameWdgt._frameLook()`: ONE pure query answering the whole frame look (manifestation, body appearance/fill/stroke/rounding, strip background appearance/colours/rounding, title ink and background, shadow) from lifetime × parentage; every skin consumer reads it; collapsed and docked are not inputs; a focus state would enter there (§0.5.2).
- **Spikes.**
  - **S1** (`.scratch/s1/corner-census.md`): option (d) alone does NOT suffice — 52 of 71 measured (content × frame) groups paint non-background pixels outside the radius-7 inner curve at margin 0: the viewport family's own border and plane (A), a bordered panel in the corner (B), a button on the corner (C), palettes (D), the spreadsheet (E), menus at r9 (F), cards/bands (G); the resize handle at inset 2 (H; keep it ≥ 3). An occupant inset ≥ 3 can never reach an outside pixel for r ≤ 9. ⇒ §3a step 3: spike S1b.
  - **S1b** (option (a), the frame's rounded CHILD clip; `.scratch/s1b/`): built behind two `FrameWdgt` switches, both OFF (`clipsChildrenToRoundedOutline`, and `roundedChildClipIsOnePathClip` for the one-clip variant) — with them off a frame runs exactly the clipping mixin's code. On: the damage is split into bands (painted as today) and the parts inside the rounded corner squares, which paint their children under `BoxyAppearance.clipToOutline` (the outline traced under the fill's own matrix, so back buffers, island buffers and the shadow pass need nothing special); `Widget.isPointerTargetAt` lets a press in a clipping ancestor's notch fall through. Proven: node proof (outline exact, 41,674 interior + 176 notch hit points), browser notch probe (screen, presses, offscreen render and a tilted island all clean at dpr 1 and 2; the clip-off control shows the ears), and a suite-wide measurement under a flush-geometry prelude (margin 0, radius 8), 3 interleaved rounds per configuration: deterministic, split ≡ single shot for shot. **Cost: dpr 1 +6.9 %, dpr 2 +12.1 % suite wall time** (the runner reports in 5 s steps, identical every round: dpr 2 is at least one full step slower, ≥ ~6 %) — over the 3 % bar. The cost is SWCanvas's, not the clip's design: once a non-rectangular clip is active, every later `clip()` — even a child's plain rectangle — builds a canvas-sized bitmask, and `save()` clones it (`vendor/swcanvas/swcanvas.js` `clip`), so the split saves nothing. ⇒ §3a step 4: **owner decision (2026-10-17, confirmed after weighing per-corner radii alone): S1c — optimise SWCanvas (a rect clip under a mask kept as a tracked rect, the mask shared copy-on-write across `save()`) and re-measure with the same harness** (`.scratch/s1b/measure.sh`; adopt iff ≤ 3 %): one mechanism, correct for every content type. Only if that still fails: (b) a 3 px body inset (S1: an occupant inset ≥ 3 never reaches an outside pixel for r ≤ 9) or (e) square bottom corners. The switches stay off and the code stays as the re-measurement instrument.
  - **S2** (`.scratch/s2/symbol-inventory.md`): coverage is per CHARACTER (every family/size/density alike). `➜` (U+279C) and `✓` (U+2713) are in NO atlas: every submenu row and every ticked row paints a placeholder box on SWCanvas TODAY — W2's chevron and tick icons fix a live defect. Also boxes today: the text menu's alignment pictograms (← → ↑ ↓ ∸ ⍿ ☓ ⋯), ⇄, ↵, ☐ ☒, ° ¹ ² “ ” ―, the video face symbols, most of the Templates "useful characters" palette, and a cropped multi-line text's newline. Safe: … — – • ’ − € £ § and Latin-1. Icon list adds pause/play/‹ (video, G), a wire-direction indicator (`ControllerMixin` " ➜"/" ⇄" rows — not a chevron), and drops `HandleWdgt`'s attach-row " ➜" (not a submenu). Atlas additions: ° ¹ ² “ ” ‘ ― (font sets) and ↔ → ↵ (+ ⇄ if W6 keeps it) (BitmapTextInvariant) — in `~/code/BitmapText.js/src/runtime/CharacterSets.js`; SWCanvas embeds its own copy of the sets and throws on a mismatch, so engine and fonts are re-vendored together.
  - **S3**: the probe ladder gained 14, 28, 36, 40, 44, 72, 80 at dpr 1 and 14, 20, 40, 44 at dpr 2; the skill's stale size lines fixed (desktop icon S = 60 in a 95×60 band, chrome glyph 24 in a 44 slot). At the new sizes: Toolbars and GenericPanel draw SOLID tool boxes at 72 (their line unit steps to 2 at S ≥ 68) — relevant to W4's tile size; GenericPanel and Typewriter degenerate at 14; Bin draws lopsided ridges at S = 18/22/26/28/32 (pre-existing).
- **Findings.**
  - ⚠ **One benign inspector shift (recaptured, owner-approved):** `Widget._seamRects` joins the inherited-member list `macroDuplicatedInspectorDrivesCopiedTargetOnly` shows (both inspectors' scrolled lists sit one entry later; nothing else changes) — images 2 and 3, mouse + finger, dpr 1 + 2.
  - Tooling consequence of moving the prefs: the icon skill's probe template (and every scratch copy) waited for `preferencesAndSettings.outlineColorString`; they now wait for `WorldWdgt.theme.iconOutline`.
  - A SWCanvas defect (not ours to fix here): a thick rounded-rect stroke whose outer left edge sits at a negative device x loses EVERY row with a negative left extent (`swcanvas.js` `if (outer.leftX < 0) continue` colliding with `_getXExtent`'s `{leftX: -1}` sentinel) — a Boxy-stroked widget dragged past the world's left edge at dpr 2 (BACKLOG).
  - On native, the plain Dashboards icon is not translation-invariant (1–3 AA px between whole-pixel offsets) — native rasterisation, not a geometry defect.
- Gates: `fg presuite` after every 1–2 units (5 gates); `fg homepage` (Theme is core); the serialization rig; every unit's acceptance probe on the fresh build. At close, after the owner-approved recapture of the one inspector test: `fg gauntlet` green on all 18 legs (no load-flake), the finger dpr1 suite 321/321, `fg homepage` OK; `check-visualisations --strict` OK.

### Visual waves: a common procedure (every phase W1–G)
1. Implement the units.
2. `fg presuite` → expect pixel failures. Classify them with `recapture.js`'s classification. **Every needs-a-fix or AIM MISSED is a bug to fix before recapture. Never recapture over one.**
3. Owner review:
   - `fg diffpage $(cat docs/plans/redesign/review-sample.txt)` on the wave's surfaces;
   - plus `open …/Fizzygum-builds/latest/index-sw.html` (SWCanvas) and `index.html` (native AA), so the owner can drive the live world;
   - plus, for icons, the skill's HTML preview ladder.
   - Iterate until the owner says go.
4. Recapture: `fg recapture --auto --dprs=1,2` (mouse), then the R0.1 finger equivalent. Both are backgrounded, with ETA and status every ~5–10 min.
5. Close gates: `fg gauntlet`, `fg finger`, and `fg homepage` (desktop or production visuals). Grep `Fizzygum-tests/scripts/` for anything the wave renamed or re-sized: the apps/parts/menusweep rigs read widget internals and labels.
6. Propose the commit message for BOTH `redesign` branches; wait for approval. Update the STATUS box and BACKLOG.

### W1 — Global surface + every persistent frame (≈ all 298 screenshot tests change)
Create the `redesign` branches here (owner approval).
- **The desk.** World and test-world background → `desk` (#ECECE8). The homepage default wallpaper → plain.
- **Shadows.** Every desktop object → (2,2) α0.12 (one token). The drag "lift" shadow is a separate token, kept; owner review.
- **Window frame.** Radius 8, a 1 px `frame` stroke painted last (switch on F2a's `strokesOverChildren` — through `_frameLook()`), `paper` body fill. The frame look (F2f) decides it; also decide there whether a pinned menu takes the window body look (today it keeps the colours it was born with) and whether a strip's background radius follows re-parenting (today it is set only when the strip is built).
- **Bar.**
  - Strip thickness = 44, plus the band's own 1 px `line` bottom rule. Bar inner padding 0, so pieces sit at x 0–44 and 44–88, and the title is centred between 88 px insets.
  - The body margin is decoupled from bar padding: split `barPadding` into two theme metrics. The body margin is 0 if S1 passes, else 3.
  - Corners `[7,7,0,0]`; `chrome` fill; title 13 px regular `muted`.
- **Glyphs** (F2c/F2b): ×, − and + at 14 px, and the pencil/eye at 20 px, in `muted`. The legacy rings go. The bar buttons (`CloseIconButtonWdgt`, `CollapseIconButtonWdgt`, `UncollapseIconButtonWdgt`) wear F2c's shape-named size-aware classes (`CrossIconAppearance`, `MinusIconAppearance`, `PlusIconAppearance`) at `glyphSize` 14, and the legacy `Close`/`Collapse`/`UncollapseIconAppearance` are deleted (the button carries the meaning, the appearance the shape).
- **Grip.** 36 px, 3 diagonal strokes 1.5 units wide in `grip`, inset 3, square hit area (§3 #5).
- **Collapsed frames.** The bar alone; owner review of the corner treatment.
- **Cards** (internal windows) and **docked bands.** The draft's embedded-toolbar skin: 1 px `line` border, radius 6, `paper`; the strip is 44 wide, `chrome`, `[5,0,0,5]`, with a 1 px `line` divider.
- Menus and prompts are NOT restyled here, beyond inheriting the shadow token.

### W2 — Menus, lists, scrollbars, prompts, tooltips
- **Menu body.** `paper`, a 1 px `frame` stroke, radius 10, 4 px side padding (`menuRowsBorder`, a theme metric). Switching on `strokesOverChildren` for menus changes the pixels F2a's overlap table lists (titled pop-up, pinned menu, overflowing pop-up — `.scratch/f2a/overlap-analysis.js`).
- **Header.** 44 tall (§3 #1), flat `paper`, 11 px `muted2`, a 1 px `chrome` rule (band-owned, rule D).
- **Rows.** 15 px `ink`, 10 px side inset; hover is a `desk` rounded-6 plate; DROP the per-row hairline (`LabelButtonAppearance` / `CommandPanelWdgt._deriveRowSeparators`). Two facts F found: `MenuItemWdgt._createLabel` never passes bold to its label (a bold `menuRow` role would not render), and the alpha-0 `CommandPanelWdgt` still CATCHES presses in a menu's corner notches although `PopUpRowsViewportWdgt` is pointer-through (S1).
- **Groups.** `DividerWdgt` becomes a 9 px band (4 + a 1 px `chrome` rule + 4). The 16-count assertion is already relational after T3.
- **Chevron** (§3 #2) — this also fixes a live defect: `➜` and `✓` are in no SWCanvas atlas, so today every submenu row and every ticked row paints a placeholder box (S2):
  - Add a row flag plus the drawn `›` in 16 px-equivalent `muted3`, 10 px from the right edge.
  - Strip `" ➜"` from every src label.
  - Sweep the 26 tests, the toolkit's hard-coded labels, `scripts/` (menu-click-sweep KNOWN/SKIP lists) and docs.
- **Tick** (§3b): the `"✓ "` prefix (`String-extensions.coffee`, `MenuRowReflectionSpec`) becomes a `ticked` row flag plus the drawn check icon, using the same row-indicator mechanism as the chevron. Update `MacroToolkit.tickedRowLabelOfMenu` and its tests.
- **Glyph additions** from S2 (font-specific or `BitmapTextInvariant`), if any label glyph is missing.
- **Lists** (`ListWdgt` rows are `MenuItemWdgt`s): the same row look, except the Inspector's member list, which is done in W3.
- **Scrollbar thumb.** `scrollbar` token rgba(30,30,28,.35), inset 2 from the edge (`ViewportWdgt._barFrameAt`).
- **Prompts** (`PromptWdgt`, a transient frame): the menu skin. Their buttons wait for W3.
- **Tooltips** (`BubblyAppearance`): `plate` fill, radius 8, 12 px; owner review.

### W3 — Controls + Object Inspector
- **Buttons.**
  - `SimpleButtonWdgt` gains an intrinsic `preferredExtent`: 36 tall, with width = measured label + 2 × padding (14) + 2.
  - Radius 6, `line` border, `paper` fill; pressed = `chrome`.
  - A real DISABLED state: no fill, a `chrome` outline, `disabledText`.
  - A primary-action variant (padding 18).
  - Keep the class; there are 32 sites.
- **Toggle.** A single bordered toggle with a FIXED label ("Methods") whose fill shows the state: `accentTint` + `accent` border and text when on, `line`/`text2` when off. It replaces `ToggleButtonWdgt`'s two-label switch, or `ToggleButtonWdgt` is rewritten in place. Tests find it by reference (`inspector.showInheritedToggle`).
- **Chip.** 32 tall, radius 16, `chip` border, `text2`; current = `accentTint`.
- **Tool button.** 44, radius 6, `desk` when active.
- **Inspector re-layout** (`src/meta-tools/InspectorWdgt.coffee`, and `ClassInspectorWdgt` alike; its code pane, the code areas and the mono text panels take a `fonts.code` role here — F2e left them setting only the family, via `_setFontNameNoSettle`, after construction):
  - A breadcrumb band, 44 incl. its seam: "Class" in `muted2`, then the hierarchy chips with drawn `›` separators, wrapping to more rows when long. The current class is the accent chip. The mixin-donor and "this object" labels get a place; owner review.
  - A toggles band, 48.
  - The body: list \| code, 1 px apart, with the seams painted (§2).
  - A footer, 52: Add / Rename / Remove, then Save on the right, with 44 px kept clear for the grip.
  - Member rows: 40 tall, 2 px gap, 4 px list padding, an 18 px kind-tag column (`fn`/`var`, 10 px bold, `muted2`; `accent` when selected), the name in 13 px mono with an ellipsis, and an `accentTint` rounded-6 selection.
  - The code pane: 12 px mono, line-height 18, padding 12. The window body is `panel` (#FAFAF8).
  - The footer buttons get their labels' W6 wording later. Until then, "add…"/"rename…"/"remove"/"save" stay.

### W4 — Desktop and icons (small suite footprint: ~5 tests + the homepage/apps/parts rigs)
- **The holder** (`WidgetHolderWithCaptionWdgt` and its subclasses `DesktopLinkWdgt`, `AppLauncherWdgt`, `BinOpenerWdgt`, `ShortcutWdgt`, `FolderShortcutWdgt`):
  - A `paper` tile, radius 16 at 64 (it scales with the tile), with a 1 px `line` border and the shared shadow.
  - The glyph is centred at tile × 40/64.
  - A `plate` label plate: radius 8, 1/7 padding, 12 px text with line-height 16, word-wrapping to the cell width minus 14 (two-line plates span the cell), and its own shadow. It replaces the white-with-outline caption.
- **⭐ ONE size knob (owner note 4).** `Theme.desktopIconTile` (default chosen at W4 from the S3 ladder: 64, 72 or 80 — ⚠ S3 measured that at 72 the Toolbars and GenericPanel icons draw SOLID tool boxes, their line unit stepping to 2 at S ≥ 68). Everything derives from it:
  - the glyph size, the cell width (tile + 32), the grid pitch and the folder-window size;
  - `standardDesktopIconExtent`'s 95×92 and its six readers;
  - `IconGridPanelWdgt` 105/102/5;
  - `FolderWindowWdgt` 340×300;
  - `GenericShortcutIconWdgt`/`GenericObjectIconWdgt` 95×95.

  Choose the knob's value by looking at the icons on SWCanvas at dpr 1. That is where a 40 px glyph may prove too small.
- **The grid.** 2 columns, keeping today's column-major order (it is already the draft's order), origin (16,14), 8 px column gap, 10 px row gap (§3 #6).
- **Icons, via `/convert-icon-size-aware`.** One at a time, each with owner review rounds (1–4 each). Use the redesign family's line unit (§3 #14). Retune `_pxSlideCard`'s 5 constants to the shared motif (34×24 r4 at (5,10)/44 → L .114, T .227, R .886, B .773, r .091); patch, panel and slides share it.
  - **Redesign in place** (already size-aware): Typewriter (Docs), PatchProgramming, GenericPanel, Toolbars (Super toolbar: column + 3 stars, the hybrid bezier dropped), SimpleSlide, Dashboards (4 tiles, no card), Folder (Examples), Bin.
  - **New size-aware bodies:** FloppyDisk (How to save?), FridgeMagnets (Fizzytiles), and Draw's spray can. The spray can is a new drawing, so it gets a new class; `PaintBucketIconWdgt`'s catalog entry in `AppCatalog.coffee` moves to it.
- **Clock** (`AnalogClockAppearance`; its second hand and centre dot `'#D40000'` and two dead colour arguments are still literals — F1b left them because `macroAnalogClockInspectEdit` shows `drawSecondsHand`'s source — they move onto roles here):
  - An opaque `paper` disc, no border, 4 `#9A9A95` dots;
  - hands: hour 6 / minute 4 in `ink`, second 2 in `accent`, all with round caps; the centre dot in `accent`.
  - Integer-ise the widths per size, holding a minimum width at dpr 1 (second hand ≥ 1 px; never a 1↔2 px wobble).
  - The clock ANIMATES: tests freeze it (`DETERMINISM.md` §4, the desktop clock trap).

### W5 — Docs Maker and toolbars
- **Tool buttons.** 44, radius 6, `desk` when active; space-between with 8 px side padding if `ToolPanelWdgt` can do it (§3 #7).
- **Glyphs.** The script "A" as a size-aware icon (skill; owner review). B and I in Times bold/italic 20; `</>` in Courier 15; `»` as the drawn chevron pair.
- **Paragraph items.** `item` fill, radius 6, padding 6/10, 15 px `ink`, line-height 22; 8 px insets from the window; 8 px gaps.
- **Caret.** `accent`, 2 px wide.
- The embedded toolbar is inset 8 from the host (the card skin is already done in W1).

### W6 — Wording (owner decision §0.5.4)
- Sentence case on every menu row and button label.
- Human names instead of class names: menu headers and hierarchy rows use colloquial names (the `colloquialName` machinery; header uppercase is applied at render).
- "…" (U+2026, if S2 confirms the glyph) on rows that open a dialog or prompt.
- Inspector title "Object Inspector — <name>".
- Open question to put to the owner at W6 start: does "Colour…" (the draft's UK spelling) replace the codebase's "color"?
- **Sweep, with a mapping table** `old → new` generated from src. Apply it to:
  - the ~104 tests' 355 strings;
  - the toolkit's hard-coded labels;
  - `Fizzygum-tests/scripts/` (menusweep KNOWN/SKIP, the apps rigs);
  - `check-menu-actions.js` if it is label-keyed;
  - docs and MACRO-PATTERNS.

  Edit by hand, or parse-and-re-emit and READ the diff. Never run a blanket regex over CoffeeScript or JS (memory: perl -pi de-indents CoffeeScript).

### G — Generalisation (owner note 5): one unit and one small wave per family, ordered by suite footprint
Families:
- prompts' fields;
- sliders and the colour picker;
- spreadsheet chrome;
- patch-programming nodes, pins and wires;
- plots and dashboards chrome; slides; folder windows;
- halo resize/move handles;
- drag-and-drop feedback (dock band outline → `accent`);
- the selection overlay (38,166,154 → `accentTint`);
- text selection;
- the error console; Fizzytiles chrome; the video player; demos.

For each family:
1. Census its colour literals and appearances.
2. Map them to roles.
3. Apply the rules (seams, borders mean pressable, drawn symbols, the 44 rule for chrome only).
4. Run a wave.

Legacy icons shown on any redesigned surface are converted with the skill. Every other legacy icon becomes a per-icon BACKLOG line under `pixel-icons-plan.md` §5b. The `raw-chrome-color` ratchet reaches 0. `visual-design-system.md` is completed.

### Z — Close
1. Final `fg gauntlet` + `fg finger` + `fg homepage`.
2. Then, with approval for each:
   - `git -C Fizzygum-tests checkout master && git merge --squash redesign`, as ONE commit;
   - `Fizzygum` merges its branch;
   - push both;
   - delete the tests `redesign` branch locally and on origin;
   - `git gc`.
3. `git mv` this plan into `docs/archive/` (stamp it, add an INDEX line). Update BACKLOG (the focus arc stays open) and the memory note. Run `/close-arc`.

---

## §5 Central risks
1. **Silent intent drift baked in by a recapture** (160 tests assert no values). Mitigation: T1's verifying aims, T3's value assertions, and the owner's review sample before every recapture.
2. **Font-metric shifts move text** (menu 17→15, title 15→13, documents 13→15). Mitigation: T3 converts every text aim to slots before W1.
3. **Rounded corners vs rectangular clip** (§3a): content "ears" outside the corners, and notch hit-testing. Spike S1, with its stated fallbacks.
4. **SWCanvas glyph gaps** (black boxes). The S2 inventory, classified per §3b. Icons are drawn; missing label glyphs are added to their atlas (font-specific or `BitmapTextInvariant`).
5. **Determinism.** New paint must be a pure function of the event stream and final geometry: no timers, and no hover plates that depend on wall-clock time (`Fizzygum-tests/DETERMINISM.md`). If the focus arc lands later, focus derives from z-order only.
6. **Rigs that read internals** (`smoke-apps-headless.js`, `parts-lazy-icons-headless.js`, menu-click-sweep). Grep `Fizzygum-tests/scripts/` at every wave (memory: a cross-repo rename MUST grep `scripts/`).
7. **Time and repo size.** R0 (≤ 90 min per wave) and the squash strategy (§0.5.3).
8. **Layout capability gaps:** the icon grid's row heights, tool spacing, and breadcrumb wrapping (§3). Each has a stated fallback.

## §6 Execution protocol (cold sessions; orchestration mode)
- Orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status`. Read this plan's STATUS box, then the phase. Verify on disk before trusting the box (`/resume-arc`).
- **Orchestration.**
  - The session's top model is the architect and the gate. Opus subagents (`subagent_type "general-purpose"`, `model "opus"`) implement ONE bounded unit each.
  - Briefs are self-contained:
    - absolute paths; `fg` only by absolute path; Node probes under `Fizzygum-tests/.scratch/`;
    - Edit tool only on `.coffee`; one class per file; `undefined` is the only absence value; comments are present-tense constraints.
  - Briefs FORBID: builds, fg, commits, and doc/BACKLOG/memory edits. They also forbid `fg killz` and killing browsers the agent did not launch.
  - Read-only research and spikes may run in parallel. Mutating agents run one at a time, in the real tree; never in a worktree, because the build hard-codes the sibling layout.
  - The orchestrator reads every diff, re-verifies one claim empirically, runs the gates itself, and owns all docs, commit messages and commit proposals.
  - After two bounces on the same unit, stop delegating it.
- **Owner rules.**
  - Never commit or push without explicit approval; an approval never carries over. Use `git commit -F <file>` and `git -C <abs repo>`.
  - Launch long ops ONCE in the background, logged, with an upfront ETA and status every ~5–10 min. Never pipe a gating `fg` call through `| tail`.
  - Recaptures are owner-gated (the per-wave review).
  - Never `git stash`.
  - Never `rm -rf`/`find -L` at `Fizzygum-builds/latest/js/tests`.
  - Ask before going out of scope.
- **Verification commands.** `fg presuite` (inner loop, ~3 min); `fg gauntlet` (phase close, 18 legs); `fg finger`; `fg homepage`; `node scripts/run-all-headless.js --pointer=finger` (finger dpr1, ~2 min); `fg diffpage <tests…>`; `fg recapture --auto --dprs=1,2`; `npm run selftest`; `fg lint`.

## §7 Sizing (estimate)
| Phase | Sessions | Recapture waves |
|---|---|---|
| R0 | 1 | 0 |
| T | 2 | 0 |
| F | 1–2 | 0 |
| W1 | 2 | 1 (full) |
| W2 | 1–2 | 1 (large) |
| W3 | 2 | 1 (medium: Inspector 18, prompts 37) |
| W4 | 3–5 | 1 (small). Icon review rounds dominate. |
| W5 | 1 | 1 (~27 document tests) |
| W6 | 1–2 | 1 (~104 tests) |
| G | 3–6 | 3–5 (small) |
| **Total** | **≈ 17–25 sessions** | **≈ 9–12 waves** (≤ 90 min each after R0; ~7 h before) |

## §8 Rejected alternatives (do not re-attempt)
- **Overlapping pane borders** for single lines (§2 A): double ownership, breaks under AA and on resize.
- **Replaying the draft's SVG `d` strings through `Path2D`:** SWCanvas has no `Path2D` and no SVG parser, and a native `Path2D` silently draws the current path instead.
- **Using font glyphs as icons (the web's icon-font habit):** semantically wrong (§3b), and a missing atlas glyph paints a black box. The converse holds too: a label's own character is never swapped for an icon. A missing glyph is added to its atlas.
- **Numeric font weights 500/600 on SWCanvas:** no atlases; `"600"` is silently ignored (§0.5.1).
- **A per-test literal-coordinate static gate:** an aim's legitimacy needs runtime knowledge. The runtime verifying aim (T1) is the gate; the census is a measurement.

## §9 References
- Design input: `Fizzygum/docs/plans/redesign/{UI-guidelines.md, desktop-canvas.html, 2 · Proposed restyle@1x.png, original-design.png}`.
- `docs/architecture/{regularity-principles.md (frame model), layout.md §4.2 (layout specs, border layout), appearance-paint-convention.md, integer-pixel-placement-and-sizing.md, widget-authoring-guidelines.md, input-and-gestures.md}`.
- `docs/plans/pixel-icons-plan.md` §5b (31 icon lessons); the skill `.claude/skills/convert-icon-size-aware/`.
- `Fizzygum-tests/DETERMINISM.md`; `src/macros/{CLAUDE.md, MACRO-PATTERNS.md}`; `Fizzygum-tests/.claude/skills/author-macro-test/SKILL.md` ("locate every target by MEANING").
- Memory notes: `residue-followups-arc-2026-10-16` (twin-prelude blast radius, visualisation staleness), `residue-arc-aim-means-what-it-says`, `swcanvas-reproduces-what-native-hides`, `recapture-tool-false-green-defects`.

## Start prompt for a fresh session
> Run the Fizzygum visual redesign plan cold: `Fizzygum/docs/plans/redesign/redesign-plan.md`. Orient with `/Users/davidedellacasa/code/Fizzygum-all/fg status`, read the plan's STATUS box and §0–§0.5, verify the state on disk, then execute the next unstarted phase in orchestration mode (§6). Owner decisions in §0.5 are locked. Never commit, push or recapture without my approval.

---

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] R0: batch finger recapture + mass-recapture throughput (also closes the zopflipng item above)
      **DONE 2026-10-16** (§4 R0): `recapture.js --pointer=finger` + parallel `--jobs` captures + one
      batched parallel recompress of the files written; a full wave projects to ~1 h, was ~7 h.
- [x] **Mass recapture is serialized behind single-threaded zopflipng** (coordinator-filed 2026-08-25, from Plan 3's wave): capturing 3,800 references at the 1920x880 world ran at ~0.5-0.8 tests/min (~7 h for the full wave) with ONE zopflipng process pinned at 98% CPU and machine load 2.6 -- the optimizer dominates at 4x pixel area and the capture is serialized behind it. The suite itself stays in envelope (~2 min parallel dpr1); this is recapture-only cost. Fix candidates: parallelize the zopflipng passes across cores; or capture with cheap PNG encoding and re-optimize asynchronously/in a follow-up pass; or lower optimizer effort for reference PNGs (they are hash-compared, not size-critical -- though repo size argues for keeping good compression somewhere in the loop). NOTE 2026-08-25: the IN-PAGE half of capture cost was separately fixed (SWCanvas JS PngEncoder -> native blit, see the resolved retention entry above); zopflipng remains the sole wall-time term for mass recapture.
      **DONE 2026-10-16** by this plan's R0: captures run in parallel (`recapture.js --jobs`, default 6)
      and the files they wrote are recompressed in ONE pass with `--jobs` zopflipng processes. Measured
      on 20 heavy tests: captures 66 s + recompress 65 s for 212 references. Also fixed: the capture
      paths' directory-scan recompress skipped native-encoder captures (<100 KB) as already optimized,
      leaving 1462 of 3808 committed references ~10× oversized; the capture paths now name the files
      they wrote.
- [x] T: tests aim by meaning; every widget aim verifies its hit (zero recapture)
      **DONE 2026-10-16** (§4 T): the runtime aim check (`AimCheckInputEvent`, "AIM MISSED"), the meaning verbs,
      the census conversions, `scripts/aim-census.js`; 9 tests found that never delivered their intent, fixed in
      source with value assertions, then recaptured (owner-approved).
- [x] F: `Theme` tokens at today's values, primitives F2a–F2f, spikes S1 (rounded corners, §3a) / S2 (symbol inventory, §3b) / S3 (icon ladder)
      **DONE 2026-10-17** (§4 F): `Theme` (palette, per-surface roles, font roles, metrics, shadows) with the `raw-chrome-color`
      ratchet; per-corner radii + filled-pixel hit shape + stroke-over-children knob; size-aware icons honour `glyphSize`; seven
      shape-named chrome icons; container-owned seams; `fontRole`; `FrameWdgt._frameLook()`; the rounded child clip (off). Spikes
      measured; the corner decision went to S1c.
