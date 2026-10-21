# Fizzygum visual redesign — the plan

**AUTHORED + OWNER-APPROVED 2026-10-16; P0, R0, T and F done; S1c done (the rounded child clip passes the 3 % bar, §3 #4); W1 done and committed on `redesign` (Fizzygum 495e67ed, Fizzygum-tests 15320404e; both branches pushed to origin); W2 done and committed on `redesign` (Fizzygum e7b2d6eb, Fizzygum-tests 9c5d28d9d; pushed); W3 done and committed on `redesign` (Fizzygum 0e9a13a3, Fizzygum-tests 5142aa05e; pushed); W4 done and committed on `redesign` (Fizzygum 9778d12c, Fizzygum-tests 4395e90b7; pushed); W5 done and committed on `redesign` (Fizzygum c97f1e09, Fizzygum-tests d55a20adb; pushed); W6 done and committed on `redesign` (Fizzygum 45e1bf22, Fizzygum-tests 55b357e9c; pushed); G next.** It is written to be executed COLD, over many sessions, by an LLM or engineer with ZERO prior context.
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
| F | Tokens (`Theme`), primitives, spikes S1–S3 (zero recapture) | DONE 2026-10-17 — `Theme` + the primitives, each default-neutral; spikes measured. The one benign inspector recapture owner-approved (Fizzygum fd0165b3, Fizzygum-tests 417d0a6e4). Corners (§3 #4): S1c DONE 2026-10-17. SWCanvas's clip model is rebuilt (§4 F, S1c), and the rounded child clip now costs +0.2 % (dpr 1) / +1.9 % (dpr 2) of suite time, so it is ADOPTED for W1, as the single path clip (owner). Committed: SWCanvas 1b482fe (pushed); the Fizzygum pin bump is the commit carrying this line. |
| W1 | Global surface + all persistent frames (windows, cards, bands) | DONE 2026-10-17 on the `redesign` branches (both repos, from Fizzygum e3032d72 and Fizzygum-tests 417d0a6e4), committed as Fizzygum 495e67ed and Fizzygum-tests 15320404e, both branches pushed to origin (the tests branch is deleted from origin after the Z squash). Units: W1a desk + plain wallpaper + one shadow; W1b body look; W1c the draft's geometry; W1d strip skin + island re-derivation; W1e strip glyphs; W1f the resize grip (`FrameGripWdgt`); plus the retitle fix the census found (`FrameWdgt._retitleNoSettle`). Each unit gated pixel-only before the recapture. Owner reviewed the sample; recaptured mouse (1942 refs / 297 tests) and finger (1862 / 287) at dpr 1,2. Close gates: `fg gauntlet` 19/19 (census serial-only: a boot-storm compile flake in parallel), `fg homepage` OK, `check-visualisations --strict` OK. Open review points: §4 W1. NEXT: W2. |
| W2 | Menus, lists, scrollbars, prompts, tooltips | DONE 2026-10-18 on the `redesign` branches, committed as Fizzygum e7b2d6eb and Fizzygum-tests 9c5d28d9d, both pushed to origin. Units: W2a the pop-up frame (paper body r10, the rounded clip and stroke-last for pop-ups, the 44+1 header band, the content padding); W2b menu rows (15 px ink, the desk/chrome r6 plate, no hairline) and the 9 px group band; W2c+W2d the drawn chevron (`opensSubmenu`) and tick, with the label sweep across src, toolkit, tests, scripts and docs (`fg menusweep` proves every flag); W2e the scroll indicator (the `scrollbar` token, thin inset 2); W2f the tooltip plate. Lists and magnets keep their look (W3/G). Each unit gated pixel-only. Owner reviewed the sample; recaptured mouse (604 refs / 107 tests) and finger (536 / 98) at dpr 1,2. Close gates: `fg gauntlet` 19/19, `fg homepage` OK, `check-visualisations --strict` OK. Open review points: §4 W2. NEXT: W3. |
| W3 | Controls + Object Inspector re-layout | DONE 2026-10-18 on the `redesign` branches, committed as Fizzygum 0e9a13a3 and Fizzygum-tests 5142aa05e, both pushed to origin. Units, each gated pixel-only: W3a the button (`SimpleButtonWdgt`: the themed state look, a real disabled state, the primary variant, an intrinsic size, the face centred on its line); W3b footer bands for the code windows and the bin (`FooterBandLayout`, `SeamRulesAppearance`); W3c prompt buttons (`PromptButtonsRowWdgt`, the toolkit's `clickPromptButton`, `fg menusweep`'s Ok-by-meaning plus its prompt floor); W3d the Inspector's bands, `panel` body, seams, borderless panes, footer and its own clip; W3e the fixed-label toggle (`LabelledToggleWdgt`) and re-filter-instead-of-rebuild; W3f the breadcrumb (`ChipWdgt`, the drawn separators, the donor label) and a new assertion-only test; W3g the member rows (`MemberRowWdgt`) and the double-click fix; W3h code panes (`fonts.code`). Owner reviewed the sample (eight W3 surfaces added; accepted the transparency test's alpha shift); recaptured mouse (164 refs / 30 tests) and finger (164 / 30) at dpr 1,2. Close gates: `fg gauntlet` 19/19 (menusweep and storage passed only on their serial retries: a boot-storm page and the recurring `macroDragEmbedReleaseWhileChargingLandsOnWorld` one-off, BACKLOG), `fg homepage` OK, `check-visualisations --strict` OK. Ratchets: raw-chrome-color 91 -> 90, call-separation [U] query 120 -> 118, plane-discipline B 36 -> 28. Open review points: §4 W3. NEXT: W4. |
| W4 | Desktop: tiles, plates, grid, size knob, clock, bin, icons | DONE 2026-10-19 on the `redesign` branches, committed as Fizzygum 9778d12c and Fizzygum-tests 4395e90b7, both pushed to origin. Research R1–R3 done, decisions settled (§4 W4); the structural units LANDED, each gated pixel-only (W4a the knob and its geometry, W4b the holder's look, W4c icons added later on the grid's next free slot, W4d the clock); the 11 icons redrawn as one family (W4-I1..I11), each owner-approved, every untouched icon byte-identical through the golden masters. Presuite pixel-only (16 tests); owner reviewed the diff page and the live desktops and said go; 192 references recaptured at dpr 1 and 2 (96 mouse, 96 finger, 16 tests each), both completeness gates green; gauntlet 19/19, homepage OK, visualisations strict OK. |
| W5 | Docs Maker: tool buttons, paragraph items, caret | DONE 2026-10-20 on the `redesign` branches, committed as Fizzygum c97f1e09 and Fizzygum-tests d55a20adb, both pushed to origin. Research R1–R3 done, decisions settled (§4 W5). Units, each gated pixel-only: W5a the text line box (default-neutral), W5c toolbar geometry + the 8 px band inset (2 bounces: the grip reserve, the re-side staleness), W5h the document, W5j the item shape, W5b the caret, W5e the tool cell look, W5f the typed B / I / `</>`, W5g the text tools' active mirror, W5i the line heights (code 18, caption 16, tooltip 16), W5-I1 the script A (owner-approved round 1). Presuite pixel-only (113 tests); owner reviewed the diff page (132 tests) and the live worlds and said go; recaptured mouse 113 tests and finger 109 at dpr 1 and 2, both completeness gates green; gauntlet, homepage, visualisations strict. Ratchets raw-chrome-color 82 -> 72, comment-narration 92 -> 91, instanceof 76 -> 75, [U] query 116 -> 115. |
| W6 | Wording (sentence case, human names, "…") | DONE 2026-10-20 on the `redesign` branches, committed as Fizzygum 45e1bf22 and Fizzygum-tests 55b357e9c, both pushed to origin. Research R1–R4 done, decisions settled (§4 W6; three owner rounds). Units, each gated pixel-only (presuite, probe, the unit rigs and revisits): W6a the title display case and header names; W6b title wording and human-name overrides; W6c wording rows, src + a dedicated test sweep gated together; W6d rows that name a widget (one helper; tests find them by the widget; the prefix and substring row lookups deleted); W6e the symbols atlas (➜ ⇄ ← → ↑ ↓ ∸ ⍿ ☓ ⋯ ↔ ° appended; rehearsed in sibling worktrees, byte-stable for every existing glyph; owner-approved chain: BitmapText main fast-forwarded through the metrics-guard fix to c5cdd59 and the release font-assets-2026-10-20 published as latest, SWCanvas 149a51c, Fizzygum's two pins); W6f menusweep's wording proofs; plus the ListWdgt snapshot fix (owner) and the transform island's "Transform" row (owner). Presuite pixel-only (116 tests); owner reviewed the diff page (134 tests, 0 INVALID), the live worlds and the atlas sheets (1x and magnified) and said go; recaptured mouse 116 tests and finger 112 at dpr 1 and 2, both completeness gates green; gauntlet 19/19 (915 s, no retries), homepage OK, visualisations strict OK. Ratchet: [U] query 115 -> 113. |
| G | Generalisation sweeps, family by family | IN PROGRESS (started 2026-10-20) on the `redesign` branches. Research R1–R3 done; decisions settled (§4 G, four owner rounds); five waves G-A … G-E planned. **G-A (apps' chrome)**: units A1 spreadsheet, A2 patch nodes, A3 the error log's Pause toggle, A4 plots + Makers' page + folder window, A5 Fizzytiles (+ A5b the boxed code pane, owner), and the six composite icons (designed offline, owner round 1, ported byte-exact), each gated pixel-only; presuite 42 tests / 90 shots; diff page 92 tests, 0 INVALID; owner go; recaptured mouse 42 tests and finger 39 at dpr 1 and 2, both completeness gates green; gauntlet 19/19 (913 s, no retries), homepage OK, visualisations strict OK. Ratchets raw-chrome-color 72 → 65, comment-narration 91 → 90. NEXT: G-B (halo and drag feedback). |
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
| 4 | Content flush to rounded window corners | Rectangular clip only; opaque flush content leaves "ears" outside the radius-8 corners | **§3a.** Top corners: per-corner bar radii (solved). Bottom corners: the host imposes its corner radii on flush content, painted with per-corner fills (no clip). Spike S1's census decides whether a corner-square clip is also needed as a backstop. **Measured in F (§4 F, S1/S1b): (d) alone covers only 19 of 71 content groups; the corner-square clip (a) works and is deterministic but costs +7 % (dpr 1) / +12 % (dpr 2) suite time because of SWCanvas's canvas-sized clip masks — **OWNER DECISION (2026-10-17, confirmed): S1c — optimise SWCanvas's clip tiers, re-measure with the S1b harness, adopt the frame's rounded child clip iff ≤ 3 % at dpr 1 and 2.** Per-corner radii alone were weighed and set aside: they cover only content whose corner pixels are its OWN background (option (d), 19 of 71 groups); scrolled viewport content, children on the corner, the spreadsheet and palettes need a clip or an inset. The rejected alternatives: a hybrid (per-corner radii + a 3 px bottom-corner inset for edge-painting content: loses the flush look on viewports, the commonest content, and every new content widget must cooperate) and (e) square bottom corners. They return only if S1c misses the 3 % bar. **S1c RESULT (2026-10-17): the bar is met, and (a) is ADOPTED.** With the clip on, suite busy time is +0.16 % (dpr 1) / +1.87 % (dpr 2), down from +7 % / +12 %. The pixels are identical to the old engine's. The frame's rounded child clip goes on in W1, and the body margin goes to 0 (§4 F, S1c). |
| 5 | Grip hit area = its 36×36 square | Today's hit area is a triangle (`HandleWdgt` `x/w+y/h ≥ 1`) | **Square per the draft.** T makes the toolkit's resizer aim ask the handle's own hit test, so the shape change is safe. |
| 6 | Icon grid rows as tall as their tallest icon | `IconGridPanelWdgt` places each icon incrementally (`n%5` arithmetic) | **W4 decides.** Default: a uniform row pitch sized for two-line labels (simple). Per-row heights need a whole-grid re-layout on add; do it only if the owner asks at review. |
| 7 | Tool buttons spread space-between | `ToolPanelWdgt` cell grid | **W5:** check the capability first; fall back to fixed 8 px gaps. |
| 8 | Hover looks (not in the draft) | Today: orange or red glyph recolour, SILVER/GRAY rows | Propose: menu row hover = `desk` rounded 6; button pressed = `chrome`; bar glyph hover = `ink` glyph on a `desk` rounded-6 plate. These are tokens, reviewed at W1/W2. |
| 9 | Uncollapse glyph (not drawn) | `UncollapseIconAppearance` | Propose a plain `+` (14 px, 2 px stroke); owner review. |
| 10 | Inset stroke rule `r − b/2` | House crisp spelling: `strokeRoundRect 0.5,0.5,w-1,h-1,r`, same `r` (one crisp spelling, SWCanvas fast path) | **Keep the house spelling.** The half-pixel radius difference is invisible on SWCanvas. |
| 11 | Desktop selected icon (accent) | No selection model | Deferred with focus (§0.5.2). |
| 12 | Plain `desk` wallpaper | The homepage default is the "dots" pattern on (244,243,244) | **Plain `desk` by default** (the draft). Wallpaper choices are unchanged. The test world's 205 grey becomes `desk` in W1. |
| 13 | 44×44 targets "everywhere" | Content widgets (spreadsheet cells, patch pins, sliders inside content) are smaller by nature | **The 44 rule binds CHROME**: bars, menus, toolbars, buttons, handles. Content keeps its own sizes ("keep the original's structure", draft §10). G records this in the design-system doc. |
| 14 | Icon stroke 2 units at 40 px = 1.82 px | The skill's line unit `t = max(1, round(S/32))` gives 1 px at 40 | **W4:** proposed a weight-matched unit, `t = max(1, round(S/22))` (2 px at 40). **Owner, at the flagship (Examples, 2026-10-19): lighter, and no floor** ⇒ the family's unit is ONE draft unit, `t = max(1, round(S/44))`: 1 px at 40, 2 px at 80 (dpr 2). |

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
  - **S1c** (the corner path the owner confirmed; SWCanvas repo plus `.scratch/s1b/` and `.scratch/s1c/`).
    - **What changed.** SWCanvas's clip is now an optional IMMUTABLE mask AND an always-tracked rect (SWCanvas `DIRECT-RENDERING-SUMMARY.MD` §9 entry 18; `ARCHITECTURE.md` "Clip State"):
      - a rect clip never touches the mask;
      - a non-rect clip is rasterised only inside the current rect;
      - `save()` shares the mask by reference;
      - a draw takes the rect and the mask separately, or one cached combined mask.
    - **Profiled first.** The cost the S1b note blamed (rect clips under a mask, and save clones) was only 28–44 % of the clip work. The FIRST outline clip was 48–63 %: the damage rect materialised as a canvas-sized mask, the whole outline rasterised, then a canvas-sized AND.
    - **Byte identity.**
      - SWCanvas tests/core 073–074 check against a pure-mask oracle. Their 888 renders also equal the pre-change bundle.
      - The Fizzygum suite with the clip ON (972 shots × off/split/single × dpr 1 and 2) is identical to the old engine, shot for shot.
      - The gauntlet is green with the clip off.
    - **Re-measured with the same harness**, 3 interleaved rounds. A page-clock play span was added, because wall time moves in 5 s steps.
      - Suite busy time with the clip on: **+0.16 % (dpr 1) / +1.87 % (dpr 2)**. The single path clip reads +0.08 % / +0.76 %, within noise of the split.
      - Wall time: +0.06 % / +0.07 % (it was +6.9 % / +12.1 %).
      - In-page paint: +6.3 % / +9.7 % (it was +40 % / +87 %).
      - Deterministic; split ≡ single.
      - Notch probe clean at dpr 1 and 2.
    - **⇒ (a) is ADOPTED** (§3a step 3). W1 turns the clip on through `_frameLook()` and takes the body margin to 0.
    - **OWNER DECISION (2026-10-17): keep the single path clip and delete the split variant.** The two are pixel-identical and both under the bar, and the single clip is simpler: no damage banding, at a cost within noise of the split. So `roundedChildClipIsOnePathClip` and the band cutter go. Damage that reaches a corner square paints its children under ONE rounded clip; any other damage paints them exactly as a rectangular clip does.
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
- **Window frame.** Radius 8, a 1 px `frame` stroke painted last (switch on F2a's `strokesOverChildren` — through `_frameLook()`), `paper` body fill, and the rounded child clip ON (S1c passed: `clipsChildrenToRoundedOutline`, through `_frameLook()`; the single path clip, owner decision, §4 F S1c). The frame look (F2f) decides it; also decide there whether a pinned menu takes the window body look (today it keeps the colours it was born with) and whether a strip's background radius follows re-parenting (today it is set only when the strip is built).
- **Bar.**
  - Strip thickness = 44, plus the band's own 1 px `line` bottom rule. Bar inner padding 0, so pieces sit at x 0–44 and 44–88, and the title is centred between 88 px insets.
  - The body margin is decoupled from bar padding: split `barPadding` into two theme metrics. The body margin is 0 (S1c passed the 3 % bar).
  - Corners `[7,7,0,0]`; `chrome` fill; title 13 px regular `muted`.
- **Glyphs** (F2c/F2b): ×, − and + at 14 px, and the pencil/eye at 20 px, in `muted`. The legacy rings go. The bar buttons (`CloseIconButtonWdgt`, `CollapseIconButtonWdgt`, `UncollapseIconButtonWdgt`) wear F2c's shape-named size-aware classes (`CrossIconAppearance`, `MinusIconAppearance`, `PlusIconAppearance`) at `glyphSize` 14, and the legacy `Close`/`Collapse`/`UncollapseIconAppearance` are deleted (the button carries the meaning, the appearance the shape).
- **Grip.** 36 px, 3 diagonal strokes 1.5 units wide in `grip`, inset 3, square hit area (§3 #5).
- **Collapsed frames.** The bar alone; owner review of the corner treatment.
- **Cards** (internal windows) and **docked bands.** The draft's embedded-toolbar skin: 1 px `line` border, radius 6, `paper`; the strip is 44 wide, `chrome`, `[5,0,0,5]`, with a 1 px `line` divider.
- Menus and prompts are NOT restyled here, beyond inheriting the shadow token.
- **Decisions settled at W1's start (2026-10-17), from research R1/R2 (`Fizzygum-tests/.scratch/w1/`):**
  - **Geometry is the draft's exactly** (orchestrator, from UI-guidelines §6.1 "the 1px frame sits outside [the content area]"). Every draft number is measured from the content box INSIDE the 1 px frame:
    - the strip is 44 plus its 1 px `line` rule, inside the border, so a window's top chrome is 46;
    - the pieces sit at 1–45 and 45–89 from the frame's outer edge, the pencil at W−45..W−1, and the title centres between 89 px insets;
    - content sits flush to the border's INNER edge, so the body margin equals the border width (1), not 0 from the outer bounds. Flush to the outer bounds (S1b's measured geometry) would hide content's outer ring under the stroke-last frame, and a press on the border would hit content.
  - **Metrics split** (`barPadding` was four dials at once): the frame border width, the strip's edge inset / inter-piece gap / cross inset, the body margin, and the dock-band inset. `barGlyphSize` 24 keeps its value for its menu readers (menu rows, `InertIconHolderWdgt`, the overflow chevron: W2's) under the name `menuRowGlyphSize`, and the bar gets its own glyph sizes, `barControlGlyphSize` 14 for × − + and `barActionGlyphSize` 20 for the pencil/eye. The grip gets its own size 36 and inset; `handleSize` stays for its non-handle readers.
  - **Bar hover** (owner): a bar glyph recolours from `muted` to `ink` on hover and press, through the existing state machine, with no plate. Close is no exception, and the pencil's next-mode preview goes `ink` too (no yellow).
  - **Pinned menus** (owner): a pinned menu takes the window look. The look is re-applied on EVERY derivation (construction, lifetime change, re-parenting), for persistent and transient frames alike. A user-set corner radius therefore resets when a window changes parent.
  - **Test values** (owner): the assertions that encode today's look are re-expressed by meaning, never recaptured over: `macroTiltedFigureShadowAsDarkAsStraight` (darkness relative to the backdrop × alpha), `macroColoredCastersShadowNeutralBlack` (shadowed ≈ bare × (1−α) per channel; the desk is not neutral grey), `macroSpreadsheetResizeViewport` and `macroSpreadsheetSelection` keep their assertions as written. The fault is in the product: `SpreadsheetApp` opens at a literal OUTER extent chosen to grant its content "exactly the default grid". The app now derives its window extent from that content extent plus the frame's live chrome, so the grid is the same under any chrome.
  - **One shadow** (2,2) α0.12 for every desktop object, pop-ups included (the draft's "shared shadow"). The pop-up tokens go; the drag lift keeps its own.
  - **Strip skin.** The strip is always a rounded box with no stroke. It rounds exactly the corners it shares with the body's outline (radius = body radius − border): a top strip [r,r,0,0], a left strip [r,0,0,r], and a collapsed strip, which IS the frame, all four. Its rule (rule D) is a 1 px `line` rule along its content-facing edge. The corners are re-applied at layout, since the axis and the collapsed state change without a re-derivation.
  - **Glyph ink** comes from the look: `muted` on a window strip, `text2` on a card's or band's strip (the draft's docked strip).
  - **The rounded child clip** is on for every ROUNDED persistent frame (windows, cards, bands), and off for transient pop-ups (W2 decides theirs).
  - **Band inset** = the host's body margin. The embedded toolbar's 8 px inset is W5's.
  - **Grip**: 36, 3 px in from the content area (4 from the outer bounds), a square hit area, on the FRAME's resizer only. The halo, naked-inspector and demo handles keep their look, about 35 tests.
- **Open review points from the W1 owner review (2026-10-17).** The owner approved the recapture without ruling on these, so each is still open. Each is a later unit's call, or the owner's:
  - A collapsed strip rounds all four corners, and its bottom arcs sit 1 px below the border's inner curve. The collapsed-corner treatment awaits the owner's review.
  - Inside a window's bottom corners, a thin crescent of the body's `paper` shows between the clipped content and the border: the clip radius vs the stroke's inner edge.
  - A card nested flush under its host's strip shows the host's `paper` in its rounded top corners.
  - A pinned menu's rows sit flush under its border (W2's).
  - The grip's square covers whatever content lies under it; the default spreadsheet's bottom-right cell is pressable only on its left part (`MacroToolkit.pressPointOf` aims there).
  - Every non-float drag (handles, sliders) records its grab offset at the move that crosses the drag threshold, not at the press, so a resize lags the pointer by that first step (`ActivePointerWdgt`, "if we ever will need to compensate for the grab/drag threshold"). Should the grip compensate?
  - Naming: ruling C12 calls a docked band's strip "a grip", which collides with `FrameGripWdgt`.

### W2 — Menus, lists, scrollbars, prompts, tooltips
- **Menu body.** `paper`, a 1 px `frame` stroke, radius 10, 4 px side padding (`menuContentPadding`, a theme metric). Switching on `strokesOverChildren` for menus changes the pixels F2a's overlap table lists (titled pop-up, pinned menu, overflowing pop-up — `.scratch/f2a/overlap-analysis.js`).
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
- **Tooltips** (`ToolTipWdgt`, on `BubblyAppearance` until W2): `plate` fill, radius 8, 12 px; owner review.
- **Decisions settled at W2's start (2026-10-18), from research R1–R3 (`Fizzygum-tests/.scratch/w2/R{1,2,3}-report.md`):**
  - **Geometry is the draft's exactly, measured inside the 1 px border** (as in W1):
    - rows sit 4 px inside the border on both sides (x 5 from the outer edge);
    - the header band (44 tall, §3 #1) sits inside the border and spans the content box; its own 1 px `chrome` rule (rule D) is its bottom edge, so the rule spans the content width, not the frame;
    - the first row sits 4 below the header rule (an untitled menu: 4 below the border), and the last row ends 4 above the border.
  - **`menuRowsBorder` was four dials at once** (the panel padding on every side, the header-box inset, a term of `popUpCenteredAtHand`, list padding): split into metrics with one meaning each.
  - **Pop-ups (menus and prompts) clip and stroke last.** The rounded child clip and the stroke-last border are ON for transient frames too. The clip is the only fix covering every case: the alpha-0 rows panel catches presses in the corner notches, and an overflowing menu has no notch at all and paints its scrolled rows and thin thumb over its border. A pinned menu keeps the window look (W1). Its rows panel brings its own 4 px padding, so its rows no longer sit flush under the border (W1 open point).
  - **Rows** (`MenuItemWdgt` in a menu or a prompt):
    - 15 px `ink`, side inset 10 (`menuRowSideInset`, split from the icon-to-label gap `menuRowIconGap`);
    - a `paper` rest fill over the row box (invisible on the paper body; a standalone row keeps a paper box);
    - hover = a `desk` plate with radius 6 over the full row box (the draft's container gives the inset);
    - pressed = a `chrome` plate;
    - the per-row hairline is deleted;
    - a pinned menu's liftable grip stays, in the `grip` token.
  - **Lists and magnets keep today's look.** The only `ListWdgt` in src is the Inspector's member list, and the draft's list rows are another look (40 tall, an `accentTint` selection, kind tags), so lists move with the Inspector in W3. Fizzytiles magnets (`MagnetWdgt` = `LabelButtonWdgt` defaults) are G's. The new row look is therefore keyed on the row living in a pop-up or a menu, never on the class.
  - **Prompts** (owner): their Ok/Close are menu rows and take the row look now; W3 decides whether prompts get real buttons. Their field, slider and colour picker are G's.
  - **Groups:** `DividerWdgt` is a 9 px band painting its own centred 1 px `chrome` rule, spanning the content width.
  - **Header text** (owner): uppercase waits for W6 and its human names. W2 renders 11 px `muted2` (`Arial, sans-serif`) in today's wording, LEFT-aligned 10 px into the content box like the row labels (the draft's `textInBand('DESKTOP', x + 10, …)`; today it is centred).
  - **Chevron:**
    - an explicit `opensSubmenu` row option (`CommandSpec` → `MenuItemWdgt`, an own field so a duplicated or saved row keeps it), set on EVERY row that opens a menu, including the five that carry no `➜` today (`attach...`, `attach with horizontal layout` ×2, `bind ⇄`, the wire rows);
    - structural derivation was measured unsound: an action-name regex has 25 false positives;
    - `fg menusweep` gains the runtime proof: per dispatched row, "opened a fresh transient menu that is not a message" equals the flag (`SUBMENU_FLAG_MISMATCH`; `SUBMENU_FLAG_CHECK_VACUOUS` if no flagged row was judged). Its allowlist `CONDITIONAL_OPENERS` (keyed `<receiverClass>.<action>`, one direction per entry) holds `HandleWdgt.attach` (no target, no menu), `WorldWdgt.popUpDemoTestMenu` (asynchronous on a lazy page) and `OverflowChevronButtonWdgt.triggerToolFromMenu` (a tool row, unflagged, that opens a menu when its tool does);
    - the indicator is a pointer-transparent child of the row, mirroring the left `icon` slot, wearing `ChevronRightIconAppearance` in `muted3`, and the menu's width hug counts its column;
    - `HandleWdgt`'s attach row is terminal: it just loses its `" ➜"`.
  - **Tick** (owner: `ink`):
    - `MenuRowReflectionSpec` yields a boolean `ticked`; the label stays plain (the 4-space `untick` placeholder goes too);
    - the tick is drawn in a leading column reserved in every row of a menu that has any ticking row, so labels stay aligned;
    - the soft-wrap rows `☐`/`☒` become one ticked row;
    - `MacroToolkit.tickedRowLabelOfMenu` reads the flag.
  - **Typed direction symbols wait for W6:** the wire rows' `" ➜"`/`" ⇄"`, `bind ⇄`, and the text menu's alignment pictograms. They are wording (§3b), so the atlas additions (S2) wait until W6 decides which survive; until then they keep painting placeholder boxes.
  - **Scroll thumb:**
    - the `scrollbar` token, 4 wide, radius 2 (already the stadium), inset 2 from the edge on the THIN look only: hit areas, the hover band, the auto-scroll band, the corner reserve and every toolkit aim (derived from the fat frame) are unchanged;
    - the fat look takes its colours from theme roles too;
    - the indicator presentation imposes the colours (`showAsScrollIndicatorThumb`), so content sliders keep theirs until G;
    - no minimum-length change.
  - **Tooltip** (owner): a plate. `plate` fill, radius 8, no border, no tail, 12 px regular `ink`, padding 7/1, the margin decoupled from the radius, placement as today. The speech bubble is content and keeps `BubblyAppearance` until G. Creation stays synchronous under the Automator's pacing.

- **Open review points from the W2 owner review (2026-10-18).** The owner approved the recapture without ruling on these; each is a later unit's call, or the owner's:
  - The wire rows keep their typed direction suffix (`" ➜"`/`" ⇄"`, a placeholder box on SWCanvas) AND show the chevron, until W6 decides the wording.
  - The fat scroll indicator's look (a faint `ink` track, the thumb `ink` α .5 / .6 on hover / press) is the orchestrator's choice: the draft defines no fat look.
  - The tooltip keeps today's placement (its bottom-left 8 px left of the invoker's top-right), so it can overlap the menu it explains.
  - A ticking menu reserves a 20 px tick column, so its labels start at x 30.
  - Narrow pinned menus (now commoner with 15 px rows) still hide their title and centre close/collapse (W1).
  - A prompt slider's thumb returns to black after one hover: `SliderButtonWdgt.setColorScheme` never sets `normalColor` (G's slider family).
  - `MenuItemWdgt._createLabel` forwards no bold/italic, so a list's `format` bold/italic never renders (W3's list rows).

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
- **Decisions settled at W3's start (2026-10-18), from research R1 (controls) and R2 (Inspector), `Fizzygum-tests/.scratch/w3/R{1,2}-report.md`:**
  - **Owner:**
    - **Breadcrumb labels.** The words "this object" / "this class" go: the current chip (accent) is the object's class, or a class inspector's own class. The mixin-donor label ("from HighlightableMixin", while a mixin-donated member is selected) sits right after the chips in the breadcrumb band, `muted2` 12 px, no border. It wraps with the band. Today all three labels paint NOTHING (13 px text in a 15 px box crops to ""), although `macroMixinEditDonorAndOverride` says the donor shows.
    - **Prompts get real buttons now:** a right-aligned footer, [Close] [Ok], with Ok the primary action (padding 18); a save-shortcut prompt has [Don't save] [Cancel] [Ok]. The toolkit gains a by-meaning verb for a prompt's buttons. `fg menusweep` finds the Ok button by meaning and FAILS when it drives fewer prompts than it does today: its finder skips a prompt with no Ok row, so without a floor the conversion would make it vacuous. `Widget.inform` stays a menu (it is not a prompt).
    - **A real disabled state** (the draft's look: no fill, a `chrome` outline, `disabledText`; the press is caught and does nothing). The Inspector's Save is disabled until the code is edited, and so is the code prompt's save (whose "unmodified" look is wrong at open today). Rename and Remove are disabled while no member is selected (today they inform "select a property first").
    - **Inherited members are dimmed:** the same `fn`/`var` tag, an own member's name in `ink`, an inherited one's in `muted`. The green/blue name colours go.
  - **Orchestrator:**
    - **Buttons size themselves.** `preferredExtent` is 36 tall and `max(44, label + 2 × 14 + 2)` wide (primary: padding 18); the construction extent is unchanged. The face is placed draft-exact: a one-line label at `floor((h − lineHeight) / 2)`, which is identical to today in the 15-tall rows. The look is `paper` / `line` at radius 6, hover `desk`, pressed `chrome` with a `frame` border (the draft's "darker border"), text `ink`. The colour is re-derived from the button's state at every transition, so no hover leaves the mixin's 245 behind.
    - **Every host's button row is a footer band:** 52 tall including its 1 px `chrome` top rule (a container seam, §2 rule B); buttons at their intrinsic size, 12 px from the edge, 8 apart; 44 kept clear for the grip. That covers the Inspector, the code prompt, the script window, the console, the error log and the bin. `macroErrorConsolePopsClean`'s equal-width VALUE assertions are re-expressed by meaning.
    - **The two mixin tests keep proving a live mixin edit.** Each hovers a fixture that wears `HighlightableMixin`'s colours. If `SimpleButtonWdgt` no longer does, the fixture becomes a widget that does.
    - **The toggle is a new fixed-label class** (rewriting `ToggleButtonWdgt` in place breaks `macroSliderDrivesAToggleButton` and the pause / play pairs). `SwitchButtonWdgt` / `ToggleButtonWdgt` stay for the icon switch and the two-label pairs. Labels keep today's words without the state suffix ("methods", "fields", "inherited", "obj own props only") until W6. The toggle's state is the Inspector's `showing*` field. A click RE-FILTERS the list: the toggles and the other children stay. Today it rebuilds the whole Inspector, and the rebuilt face sticks highlighted under the pointer.
    - **The chip:** a new class, 32 tall, padding 10, radius 16, `chip` / `text2`, current `accentTint` / `accent`. The separators are drawn `ChevronRightIconAppearance` icons in `muted3` (a typed `›` paints a placeholder box), all 4 apart, after "Class" in `muted2`. Every chip, the current one included, opens its class's ClassInspector (`openClassInspector`, as today). The band wraps to more rows when the chain is wider than the band, each row 36 more. (R2's "113 of 508 classes wrap" measured a typed `›` placeholder box, 7 px, against a 534 limit; the drawn separator puts chips 12 apart and the limit is the band's width less its 12 px inset, so at the default 558 even `MenuItemWdgt`'s 5-class chain fits one row.)
    - **The window stays 560×410:** the draft was drawn at that size, and its bands (44 + 48 + 52) leave the draft's 219 px body. The list column is 238 (4 + 230 + 4) but never more than half the width. Below the bands' width, controls keep their size and the window clips them; Save then follows the left group instead of overlapping it.
    - **The panes are borderless** on the `panel` body, painted by the Inspector in both modes (windowed it paints nothing today, and the window's `paper` shows). The list | code line and the band rules are the Inspector's seams (`_seamRects`). The code pane no longer reaches the grip's corner; the footer does.
    - **Member rows:** 42 tall and flush, with no layout gap (no dead zone between targets, ruling G5); the 40 px `accentTint` radius-6 plate is drawn at the row's top, so the pixels are the draft's. Padding 4. Rows are as wide as the list; today they hug the widest name and scroll sideways. The kind tag (`fn` for a function, else `var`) is 10 px bold `muted2` in an 18 px column (`accent` when selected); the name is 13 px mono, cut off with "…". There is no hairline and no teal editor-selection outline. The look is keyed on the Inspector's list, so the five standalone `ListWdgt` tests keep theirs.
    - **The double-click fix:** the inspector's double-click handler is a method named by string (today a closure that `ButtonWdgt.triggerDoubleClick` cannot dispatch: a double-click on a member row throws).
    - **Code panes take `fonts.code`** (12 px mono, the `code` colour, padding 12): the Inspector, the editable code areas (script, code prompt), the mono text panels (console, error log, patch nodes). The line pitch stays Fizzygum's `ceil(1.2 × size)` = 15. The draft's 18 needs a text line-height knob, which W5's documents (line-height 22) need too.
    - **Kept:** the overlay thumb's inset 2 (W2), the naked inspector's own resize handle (W1), and the typed video-player faces (❮ ❯ ❙ paint boxes; the part is not built and no test shows it: G).
- **Findings while landing W3** (each fixed in the unit, gated):
  - `PromptWdgt.closeButton` collided with `FrameWdgt.closeButton`, the strip's × alias: pinning a prompt re-pointed the field at the strip's ×, and on a transient prompt `closeButton?` answered true against FrameWdgt's contract. The row's Close is `dismissButton`.
  - The Inspector's "this object", "this class" and donor labels never painted (13 px text in a 15 px box crops to nothing); the donor label now paints, in the breadcrumb.
  - A double-click on a member row threw: the list handed `ButtonWdgt.triggerDoubleClick` a closure it dispatches by name. Every double-click is now a string action through the four-slot dispatch.
  - `macroWrappingTextFieldResizesOK`'s image_1 claim ("the vertical scrollbar is out") stopped holding with the 12 px code pane (it had probably stopped since W3d's shorter body). The test types 15 repeats instead of 10, and all three of its claims hold, measured.
  - The breadcrumb's wrap estimate (R2: 113 of 508 classes) measured a typed `›` placeholder; with the drawn separator, a 5-class chain fits one row at the default width.
- **Open review points (W3):** each is a later unit's call, or the owner's.
  - An instance's own added property renders dimmed, like an inherited member. That is today's rule: "own" means declared on the object's class (it was blue, like inherited).
  - The code pane's line pitch is 15, not the draft's 18: there is no line-height knob, and W5's documents (line-height 22) need one too.
  - The hover and press looks of the toggle (off: `desk` / `chrome` + `frame`; on: unchanged) and of the chip (`desk` / `chrome`; the current chip unchanged) are the orchestrator's choice: the draft gives none.
  - A prompt's buttons sit flush to its content box's right edge, 8 apart, in a 44 px row after the group divider: the orchestrator's choice (the draft has no prompt).
  - A wrapped breadcrumb's later rows start at the first chip's x, under the chips, not under "Class".
  - A list or code pane taken out of an inspector keeps its cleared look: it is transparent on the desk.
  - A disabled button standing directly on the desktop casts the desktop shadow, which shows through its unfilled interior (no src site puts a button on the desktop).
  - Removing or renaming `injectProperty` on a prototype in the inspected chain makes the subject read-only without dropping the footer (the re-filter does not rebuild the bands).
  - The error log's pause control stays a two-label `ToggleButtonWdgt` ("pause" / "un-pause") wearing the button look.
  - An inspector could not be snapshotted: `ListWdgt.labelGetter` was an own function-valued field. Resolved in W6 (the option went; `ListWdgt.labelOf`).

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
- **Decisions settled at W4's start (2026-10-18), from research R1 (holder, grid, knob), R2 (icons, with the knob preview) and R3 (clock), `Fizzygum-tests/.scratch/w4/R{1,2,3}-report.md`:**
  - **Owner:**
    - **The knob is 64** (`Theme.desktopIconTile`), the draft's own value, chosen from the SWCanvas preview (`.scratch/w4/r2/knob-preview.html`). The glyph is 40 at an exact 12 px offset, the cell 96, the tile radius 16. It is one value, so it can be raised later if a redrawn icon proves too small at dpr 1.
    - **A uniform two-line row pitch.** Every row is tall enough for a two-line plate (only "Patch programming" wraps, at every tile size); the grid keeps its incremental column-major placement, 5 per column, and only its numbers derive from the knob.
    - **Icons added later go through the grid.** "Create shortcut", filing, the save prompt's Ok and drops into a folder land in the next free slot at the knob's size. Today they land a 75×75 icon at world (0,0) (`Widget._createReferenceNoSettle`), and a filed icon in a folder window lands off its panel, which then grows scroll bars.
    - **A clock in a window shows its dots and hands only:** the paper face has no border anywhere, so on a paper window body only its shadowless content shows.
    - **Icon order, one at a time through the skill:** Examples (the flagship, where the owner approves the stroke weight at the 40 px glyph, which then becomes the family's floor), Bin, How to save?, Fizzytiles, Draw (spray can); Patch programming with the shared card retune, Slides, Generic panel; Dashboards, Super toolbar, Docs Maker.
    - **The spray can is Draw's icon everywhere:** the launcher, Draw's info doc and a drawing's shortcut icon (`ImageWdgt.representativeIcon`). The paint bucket keeps only its demo-menu row.
    - **The composites go to G** (the shortcut arrow badge, the legacy Object/Widget/Script icons), with the C-F converter's icon and a spreadsheet icon of its own (it wears the typewriter today): BACKLOG.
    - **The owner's review of the draft's icons replayed naively on SWCanvas** (`.scratch/w4/r2/draft-icons.html`: the draft's 2-unit stroke is 1.82 px at a 40 px glyph, so walls come out 1 or 2 px). Each point is an acceptance criterion of its icon's unit, and a standing assertion of its structural sweep:
      - every wall of a shape has ONE thickness, horizontal and vertical alike: the shared card of Slides, Patch programming and Generic panel, and Slides' inner lines against its bars;
      - the Bin's oblique walls are connected (no break where a slanted wall steps);
      - the typewriter's keys are bigger and heavier than the draft's dots (r 1.3 units, 2.4 px at 40);
      - the spray can's spray is bigger and heavier than the draft's dots (r 1.2 units).
    - **Each redraw starts from today's size-aware icon, not from the draft's raw geometry** (owner): the landed icons already render correctly on SWCanvas through the `convert-icon-size-aware` skill's discipline, so a unit keeps what works and changes the drawing toward the draft. Today's painters already solve these points: one line unit `t` for every wall (`_pxPanel` / `_pxBorder` / `_pxSlideCard`: the card's walls are one thickness on all four sides), the Bin's tapered walls as two parallel trapezoid edges that share one slope (connected, a uniform wall), the Typewriter's keys tiered by size (rings, squares, dots, held by `tc`), SimpleSlide's rows and bars at one `tc`, the dot clamps of Dashboards. The three legacy icons (FloppyDisk, FridgeMagnets, and the spray can that replaces PaintBucket) borrow the same painters from the landed icon nearest in shape.
  - **Orchestrator:**
    - **What the knob drives:** the glyph (T × 40/64), the cell width (T + 32), the tile radius (T/4), `standardDesktopIconExtent` (cell × the two-line row height: 6 + T + 6 + 34 + 6 = 116), the grid pitch (cell + 8 across, row + 10 down), the folder window's size (3 columns × 2 rows of icons visible), the composite icons' construction extents and the 75×75 shortcut literal. Fixed at the draft's values: padding 6, tile-to-plate gap 6, plate padding 1/7, plate radius 8, caption 12 px, column gap 8, row gap 10, origin (16, 14).
    - **The holder paints its own tile and plate** (a new appearance: `paper` tile with a 1 px `line` border, `plate` plate with none). Its icon widget is the glyph square centred in the tile, its caption the `TextWdgt` on the plate's text area in `ink`. The white outlined caption goes, and with it the halo machinery that had no other user (`hasDarkOutline`, `desktopCaptionHalo`). The holder keeps its children as they are (`icon` is the art, `label` the caption): the rigs read them by name.
    - **Its hit shape is the tile and the plate** (draft §4: a target never extends beyond its widget): a press or a drop in a cell's empty corners or in the gap reaches the desktop.
    - **Its shadow is the shared desktop shadow of its own silhouette only** (tile + plate, children skipped), so the drag lift stays two clean shapes.
    - **Hover and press follow the button rule** (W3): hover `desk` tile fill, pressed `chrome` fill with a `frame` border; the glyph stays `ink` (the draft's ink, read from a desktop role; legacy surfaces keep `iconInk`). `DesktopLinkWdgt`'s three class-level colours go.
    - **The plate's line pitch:** plate heights are the draft's (16 per line + 2: 18 and 34), the caption keeps Fizzygum's 15 px line pitch inside them, so a one-line plate is draft-exact and a two-line plate's second baseline sits 1 px high. A text line-height knob is W5's (documents need 22; W3's code pane wanted 18). The caption keeps today's two-line cap with "…".
    - **The holder re-derives its geometry from the theme at every arrange**, so a snapshot's saved bounds never pin an old look (no compatibility obligation).
    - **The bin** keeps its own corner spec, at the draft's spot as nearly as fits: its cell stays inside the world (the draft's places it 2 px past the edge).
    - **The clock:** 88×88 at the draft's corner inset (15 from the right, 14 from the top), on its own theme metrics (not the bin's shared padding); an opaque `paper` disc with a whole-pixel diameter of the device size's parity, no border; four `clockMark` (#9A9A95, a role at the draft's literal) dots; hour and minute hands in `ink`, the second hand and the centre dot in `accent`. Widths are whole device pixels whose parity matches the centre's (an odd width on a whole-pixel centre loses a pixel pointing left, and a 1 px hand vanishes at :45), and a hand of 1 px is a direct butt line. Its hit shape is the disc.
    - **The frozen test time moves from 00:00:00 to 10:08:37** (`new Date 2011,10,30,10,8,37`, without brackets: the `wall-clock` stink matches `new Date(`). At 00:00:00 all three hands lie stacked on 12, so `macroAnalogClockInspectEdit`'s and `macroNakedInspectorRendersResizesAndEdits`' "the seconds hand is mirrored" never showed (0 bytes differ; measured). `drawSecondsHand` keeps its `@_drawHand context, squareDim, @secondsHandAngle` prefix, so their typed edit still lands.
    - **The icons' line weight (owner, at the Examples flagship, round 1):** LIGHTER than the draft's 2-unit stroke: 1 px at the 40 px glyph, with no floor. The family's line unit is therefore ONE draft unit, `max(1, round(S/44))`: 1 px at 40, 2 px at 80 (dpr 2, exactly double), 2 px from S 66 (§3 #14's `round(S/22)` was the draft's weight; the owner judged it heavy). The interiors stay `paper` (owner).
    - **Icons (orchestrator):** its light interiors are `paper` with no halo envelope, through a new role (the legacy `iconOutline` halo stays for legacy icons). The shared card follows the draft's INK extent (L .091, T .205, R .909, B .795, outer radius .114): the fractions quoted above are the stroke's centre line, which would draw the card 1–2 px small per side.
- **Findings while landing W4** (each fixed or filed in its unit, gated):
  - **The structural units (W4a–d) as built:** the knob and its metrics in `Theme`; a 96 × 116 cell (two-line pitch); the grid from (16, 14) one cell plus a gap apart; folder windows sized from the grid and the frame's own chrome (338 × 317 at 64); the holder's `DesktopIconAppearance` (tile, plate, hit shape and silhouette); icons added later on the grid's NEXT FREE SLOT (the never-decremented, serialized icon counter is gone: placement reads where the icons are); the clock redrawn whole-pixel.
  - **A click on a desktop icon's glyph left its tile pressed** until the pointer left: `pressBegan` escalates from a child (`Widget.pressBegan`), `pressEnded` goes only to the widget the click landed on. A desktop link's glyph is now a PICTURE, never a pointer target (`_showsChildAsAPicture`, asked by `Widget.isPointerTargetAt` on its ancestor walk), so the holder takes the press, the release and the click together.
  - **A drop into an open folder window and a drop onto its icon disagreed for an app launcher**: into the window it was wrapped in an "app launcher" document shortcut, onto the icon it moved in at its stale position. Now any desktop icon dropped into an open window stays where it was dropped, and one dropped onto a folder's icon takes the folder's next free slot. `ShortcutWdgt.isDesktopShortcut` is then read only by two index-page rigs, so it is allowlisted for them (index.html carries no harness).
  - **Every clock test froze the clock at 00:00:00**, all three hands stacked on 12, so the two inspector tests' "the seconds hand is mirrored" never showed. The freeze is now 10:08:37, and the mirror shows; the inspector test's fossil scroll target (`"context.restore()"`, a string the method no longer holds) names `@secondsHandAngle`.
  - **SWCanvas leaves a round-capped stroke's self-overlap unpainted** (two round-capped subpaths in one `stroke()` meeting in a T leave a hole), found replaying the draft's bin: BACKLOG; a W4 icon never strokes overlapping round-capped subpaths in one call.
  - **The white caption's dark outline machinery** (`hasDarkOutline`, the halo margin in fitting and positioning) had one user, the old caption, and is gone with it.
  - **Benign picture changes beyond the desktop:** six inspector tests' member lists scroll a few px differently (`StringWdgt` lost two members); `macroMixinFieldEditDonorAndOverride`'s "(N consumer classes updated)" counts one more (`DesktopLinkWdgt` no longer shadows `color_hover`).
  - **The 11 icons (W4-I1..I11), each owner-approved in 1–3 rounds** in the order the owner set (the Examples folder as flagship, then simplest first, Docs Maker last). Owner turns, beyond the line weight: the Fizzytiles magnets keep their handles; the slides' bars are two line units wide; Dashboards is four graphs, without their own outlines, inside the shared content card, its scatter dots clear of the card's wall; the Super toolbar's stars lean as in the draft; Docs Maker's keys are bigger and heavier than the draft's dots (3.5 units: 3 × 3 squares at 40, 6 px dots at 80). Each round was a sweep over every S 14–130 plus dpr 2 (walls measured, defects planted to prove each assertion), and a golden master after every base change kept every untouched class byte-identical. The redraws left `_pxSlideCard`, `_useDetail` and `_pxBorder` without callers, and they are deleted; the paint bucket moves to `src/demos-icons/`, the spray can replacing it wherever Draw shows.
  - **SWCanvas's `fillCircle` under-fills at some diameters** (2, 3, 6, 8–10, 12–14, 16 px; exact at 4, 5, 7, 11, 15): BACKLOG. The icons' sweeps measure discs rather than predict them, and a part that must touch a circle stands on the pixel every circle inks (the middle of its top row).
  - **Ratchets banked:** `raw-chrome-color` 90 → 82 (the desktop link's three state colours and the clock's five literals now read roles); `comment-narration` 96 → 92; call-separation `BASELINE_U_QUERY` 118 → 116 (`TextWdgt.getParagraphs` and `getTextWrappingData` gained a real external caller, the holder's caption measurement).

### W5 — Docs Maker and toolbars
- **Tool buttons.** 44, radius 6, `desk` when active; space-between with 8 px side padding if `ToolPanelWdgt` can do it (§3 #7).
- **Glyphs.** The script "A" as a size-aware icon (skill; owner review). B and I in Times bold/italic 20; `</>` in Courier 15; `»` as the drawn chevron pair.
- **Paragraph items.** `item` fill, radius 6, padding 6/10, 15 px `ink`, line-height 22; 8 px insets from the window; 8 px gaps.
- **Caret.** `accent`, 2 px wide.
- The embedded toolbar is inset 8 from the host (the card skin is already done in W1).
- **Decisions settled at W5's start (2026-10-19)**, from research R1 (structure, toolbars, documents), R2 (text engine, caret, glyphs, atlases) and R3 (tests, aims, rigs), `Fizzygum-tests/.scratch/w5/R{1,2,3}-report.md`:
  - **Owner:**
    - **Every toolbar wears one look** (the draft: "never special-case how a toolbar looks"): the eight `ToolPanelWdgt` toolbars (text, paint, slides, dashboards, patch programming, super, windows, plots) get bare 44×44 cells at radius 6 with no glass plate, a 56 px cross extent (44 + 2 × 6; it was 64), and every docked band sits 8 from its host. The side bands of Slides, Dashboards, Patch programming and Draw narrow from 66 to 58. The suite shows only the text, paint and slides toolbars and one bare toolbar, so the owner reviews the others live.
    - **Tools are spread space-between**, draft-exact: 8 px from each end of the strip, the leftover shared evenly between cells, at least 6 px apart (the fit count). Side-docked columns spread down their whole height too. At the default Docs Maker width this shows 4 tools and `»` (it shows 5 today); the font-size button moves behind `»`, as in the draft.
    - **Tool states:** at rest no fill and no border; hovered `desk`; pressed `chrome`; ACTIVE `desk` (the draft). A hovered tool looks like the active one while the pointer is on it (menu rows, W2, do the same).
    - **Text tools mirror the edited text:** B is active while the text being edited is bold, I while it is italic, `</>` while it is monospaced. The focus-change sites gain ONE announcement point so the toolbar follows deterministically. Draw's armed paint tool shows active the same way (`desk`, no orange).
    - **The line-height knob serves four surfaces, at the draft's values:** documents 22, code panes 18, the desktop caption 16, the tooltip 16. Unset, a text keeps today's pixels exactly.
    - **One caret look for every caret** (documents, prompt fields, code panes, cell editors, caption renames): `accent`, 2 px wide, as tall as the font's own box, 1 px after the slot boundary; a caret at a clipping field's right edge stays visible.
    - **The editable-text-item role takes the `item` colour** for every reader (one role, one meaning), the empty window's "Drop a widget in here" placeholder included; only document items also take the item SHAPE (radius 6, padding 6/10, 15 px `ink` on 22 px lines).
    - **The document's drop rule is fixed in W5:** a widget dropped into a document goes BEFORE the first item whose middle is below the drop point (the top, the gaps and the bottom all work; today it goes after the item under the point, so the top is unreachable and a drop in a gap appends at the END). `macroIconDroppedIntoDocumentFlows` then delivers its stated intent ("at the TOP, above the text"; today it lands below the first paragraph), with an order assertion added before the recapture.
  - **Orchestrator:**
    - **Geometry is the draft's, measured inside the 1 px border** (as in W1): the Docs Maker's band at (9, 54) 352 × 58 (the draft's "8 below the bar" counts from the strip's rule, so 46 + 8); its strip 45 × 56; the tool cells at y 61; the first paragraph at (9, 120), 352 wide.
    - **The band inset is its own metric** (`dockedBandInset` 8), not the body margin: `FrameWdgt._bodyMargin` is both a band's inset and the band-to-payload gap today, and it is global (every frame's payload, pop-ups included). A docked band sits `dockedBandInset` from the host's content box on its three outer sides and flush with the payload; the payload's own content supplies its spacing (the document's stack pads 8).
    - **The tool grid's padding splits by axis:** along the strip 8 (the side padding), across it 6 (so a band is 56 + 2 = 58); the 6 px minimum gap sets how many cells fit; each slot's position is rounded (a 17.25 px gap would trip `NON_INTEGER_GEOMETRY`). The grid reads its metrics from the theme at every arrange (W4's pattern: a snapshot or a duplicate never pins an old look; today the cell metrics, `dockThickness` and the dock spec's thickness are copied into instances and serialized).
    - **One line per edge.** Every line in today's Docs Maker is doubled (the strip's rule and the toolbar's border, the band's border and the toolbar's, the band's bottom and the document viewport's border, the frame and the viewport's sides). The toolbar (`ToolbarWdgt`, `ToolPanelWdgt`) is borderless and unfilled inside its frame; the document viewport is borderless on the window's `paper`.
    - **The cell's look is re-derived from its state at every transition**, from roles: two cells keep a different rest look after the first pointer visit today (the lid-covered thumbnails 239 → 247, the paint tools 230 → 240).
    - **Toolbar glyphs are `ink`**, through a toolbar glyph role (the 38 other `iconInk` readers keep theirs).
    - **`»`** is the size-aware `DoubleChevronRightIconAppearance` (F2c, unused so far) at `glyphSize` 16, which matches the draft's ink exactly; the legacy `OverflowChevronIconAppearance` goes if nothing else wears it. Its orange hover goes: the cell's `desk` plate is the hover.
    - **B, I and `</>` are TYPED** from the atlas (§0.5.1: "Serif B/I → Times"): an appearance paints the letter in a logical-pixel scope at an integer translate (in a size-aware device-pixel body a typed glyph comes out half size at dpr 2; under the legacy icon transform it is resampled), in the literal families `Times New Roman` (bold 20, italic 20) and `Courier New` (15), so both backends draw the same faces, centred as the draft centres them (by advance and font box, §1.1 "a line centred in a taller box"). The size scales with the box (20 at 44), for the overflow menu's 24 px pictures.
    - **The script A** is a size-aware icon through the `convert-icon-size-aware` skill, with owner rounds; the probe ladder gains 34@1 and 34@2 (the draft's 34 px box). The align and font-size tools keep their legacy art in the new ink until G (BACKLOG).
    - **The line box** is a font-role member `lineHeight`, copied to the text widget like the role's other members: unset, today's arithmetic (pitch `ceil(1.2 × size)`, baseline at row top + pitch − descent) byte-identical; set, the draft's §1.1 (`baseline = top + floor((lineHeight − (A + D)) / 2) + A`, A and D the font's rounded ascent and descent from the backend's own measuring context), all in integer logical pixels. ONE home computes the pitch, the baseline in the line and the caret's box; wrapping, painting, measuring, selection, `slotCoordinates`, `slotAt`, the caret and the toolkit's text aims all read it, and the pitch enters the wrap and back-buffer cache keys. The draft's formula is never the default: at the default pitch it puts every baseline 1 px higher (measured on 11 fonts). The role states its line height AT ITS SIZE; at any other size (a user enlarging a document's text) the pitch scales with the font's em box, `round(lineHeight × fontHeight(size) / fontHeight(statedSize))`, so a line box is never shorter than its em box (scaling by the raw size gave a 0 px pitch at size 0, which the fitting search probes). A selection in a set line box spans the whole line, so a multi-line selection has no gaps. The Theme slot metrics that fake a line height from outside (`tooltipLineHeight`, `desktopIconPlateLineHeight`) give way to the role.
    - **The caret's box is the font's em box in its line**, [baseline + D − P, baseline + D): today's row exactly when the knob is unset (so `macroTextWdgtCaretResizing`'s "as tall as the font's line" holds), and the draft's 18 px ending 3 below the baseline at 15/22.
    - **The paragraph is still the `SimpleTextWdgt`**, with no wrapper (7 tests read `childrenNotHandlesNorCarets()[0].text`; dragging a paragraph already works and keeps working): it paints its rounded `item` background and insets its text by its own padding. The document's stack pads 8 (insets and gaps alike). The view-mode blend (the item melts into the page) is done through roles, not by comparing colour values.
- **Units (one Opus implementer each, gated pixel-only unless stated):** W5a the line-box knob, default-neutral (zero pixel change); W5b the caret look; W5c the toolbar geometry (axis paddings, space-between, cross 56, theme-derived, borderless toolbar) with W5d the band inset in the same unit (a band's thickness and its inset are one placement: apart, the band would move twice); W5e the tool cell look (states, roles, `»`, the rest-look drift); W5f the typed B / I / `</>`; W5g text tools mirror the edited text (and the paint tool's active look); W5h the document (`fonts.document`, the item colour, the stack, the viewport, the blend, the drop rule and its test); W5j the item SHAPE (radius 6 and the 6 / 10 text inset inside a paragraph: slot geometry, wrapping, caret and selection all inset); W5i the knob's other surfaces (code 18, caption 16, tooltip 16); W5-I1 the script A (skill, owner rounds).
- **Findings while landing W5** (each fixed in its unit, gated):
  - **The line box (W5a) is one home on `StringWdgt`** and default-neutral: with no line height set, 846,303 before/after expression pairs are identical; the only picture change is the Object Inspector's member list (the class gained methods). A set pitch scales with the font's EM BOX, not the raw size: scaling by size gave a 0 px pitch at the fitting search's size-0 probe.
  - **Space-between put the last tool under a resize grip** (W5c): in a floating toolbar the strip's far end is the window's bottom-right corner, so the `»` landed under the frame grip and its click missed (the leftover space at the end had kept it clear by luck). The strip now keeps its far end clear of a resizer over its corner, by the reserve the scroll bars already take (`ViewportWdgt.cornerResizerFootprint`). And re-siding a docked band (top ↔ bottom, both 352 × 58) left its strip laid out for the old side: a side change now tells the corner chain (`Widget.noteCornerChainChanged`, the walk the grip already used), which also fixes the same staleness for scroll-bar reserves.
  - **The drop rule's consequences (W5h/W5j):** with tall items, a paragraph's middle can lie below the view, so "after it" needs a drop below a middle the user cannot reach without scrolling. Seven tests re-aimed by meaning (drop "before X" on X's upper part, "append" at the view's foot), each with an order assertion; two of them had UNCHECKED drops that fell on the desktop at the new geometry (`macroResizingScrollFrame…`, `macroSimpleDocumentRemovingLastParagraph…`), and two right-clicks / wheels aimed at centres below the view (AIM MISSED). `macroIconDroppedIntoDocumentFlows` now delivers its stated "at the TOP" (it never could: index 0 was unreachable).
  - **A finger never delivered `macroNestedScrollPanelsRouteWheel`'s intent:** the toolkit translates a wheel into a PAN, routed by `claimsPlainDragsForScrolling`, and a `ListWdgt` (its rows take drags) claims none, so the pan scrolled the OUTER document; the committed finger image_2 showed the opposite of its claim. The test is mouse-only by meaning (a wheel's edge escalation) and declares it; its finger references are removed.
  - **The line box serves its four surfaces (W5i):** code at 18 (baseline 12), the desktop caption and the tooltip at 16; W3's "line pitch stays 15" and W4's "the caption keeps Fizzygum's 15 px pitch" are superseded, and the Theme stand-ins `tooltipLineHeight` / `desktopIconPlateLineHeight` are gone (each reader asks the text's own line box). A two-line caption's second baseline is the draft's 28; tooltips are pixel-identical.
  - **The text tools mirror the edited text (W5g)** through ONE editor-focus write (`WorldWdgt._setEditorFocusNoSettle`) and a style announcement (`noteStyleChanged`), heard by each text toolbar over one dataflow edge; a context menu's row click moves the focus (menus are not editor chrome), so after one nothing is active.
  - **A typed face cannot be photographed (W5f):** the `»` menu's picture of a tool was a raster of a throwaway copy, so a face typed while its atlas was still cold kept placeholder boxes for good (and a reference would depend on which test warmed the atlas first); a typed face's picture is now a live copy, retyped when the atlas arrives.
  - **The caret's band clamp cost a settle re-visit (W5b, caught only by the wave-close gauntlet's `revisits` leg):** the pass a keystroke runs inline measured its text before the re-fit, and inside a scrolling viewport the clamp's band disagreed with the viewport's own follow by `viewPadding`; every follow pass now reads its text re-fitted, and inside a viewport's plane the viewport's follow alone keeps the caret in view.
  - **The SWCanvas font mapper keys on generic words** (`mapFontStackToSWCanvasFamily`: "serif" → Times, "courier"/"monospace" → Courier, anything else → Arial), so a bare `"Times New Roman"` would render Arial: a face names its literal family first and ends in the generic.

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
- **Decisions settled at W6's start (2026-10-20)**, from research R1 (the src label census and mapping), R2 (every label consumer outside src) and R3 (pixels, widths, glyphs, the footprint), `Fizzygum-tests/.scratch/w6/R{1,2,3}-report.md` (+ `r1/label-map.tsv`, `r2/test-label-strings.tsv`, `r3/footprint.tsv`):
  - **Owner:**
    - **Every window title is in sentence case**, capitalised at DISPLAY: a window's stored name stays the lowercase words `colloquialName` answers (they go mid-sentence elsewhere), and the bar shows "Rectangle", "Spreadsheet", "Empty window", "Error log"; proper names are unchanged.
    - **US spelling stays** ("Color…", "Align center", "gray scale palette"); only the case and the "…" change.
    - **Only headers that NAME something are UPPERCASE**, at display: a widget's menu (its human name: RECTANGLE), DESKTOP, FONTS, WALLPAPERS, the demo sections; the choosers take noun names (NEW PARENT, TARGET, TARGET PROPERTY, CONNECT, BIND WITH). Messages (informs, "No widgets to attach to"), prompt questions and the bin's confirmation keep sentence case.
    - **The direction symbols stay, and the text menu's pictograms stay**: "Bind ⇄"; the wire rows keep their ➜ / ⇄ (the arrow is the row's reading of direction); the alignment and fitting rows keep ← → ↑ ↓ ∸ ⍿ ☓ ⋯. Each is ADDED to the atlases (§3b), with ↔ and ° for the "°C ↔ °F converter" title: a cross-repo unit (BitmapText.js, the SWCanvas checkout, Fizzygum's re-vendor and pin bump), each commit owner-approved. The bind chooser's rows drop their redundant " ⇄" (the header says it).
    - **The atlas additions (round 3, from R4, `Fizzygum-tests/.scratch/w6/R4-report.md`)**: all twelve (➜ ⇄ ← → ↑ ↓ ∸ ⍿ ☓ ⋯ ↔ °) are APPENDED to the font-independent symbols set (`BitmapText.js` `CharacterSets.FONT_INVARIANT_CHARS`), never prepended or sorted (the set's baseline is its first character's); ° there too, though it is a typographic character (Arial's own ° would mean regenerating all ~4,200 font atlases). Generated on this Mac with BitmapText's own Playwright at `--batch-size=24`, after a pristine control regeneration matches the release (R4 measured 0 diffs over every existing glyph that way; the default batch moves dpr-2 glyphs at 91–96 px). BitmapText merges its metrics-guard fix branch (which SWCanvas pins) into `main` first and takes the symbols on `main`; SWCanvas takes them on `main` in a worktree (its checkout stays on its own branch); Fizzygum vendors fonts with `--atlas-max-size 96` (the default 24 would leave stale symbol images above 24 px under new positioning data, garbled silently). No generator runs while an `fg` operation runs (`fg` kills every webkit process). A name row quotes a text's start with straight quotes (the font atlases have no curly ones).
    - **A row that names a widget reads its human name**, disambiguated: "Rectangle", a text by its start, a window by its title, and a number only when two rows would still read the same. ONE helper replaces today's seven `toString()` sites (the hierarchy menu, the parent and target choosers, the handle's attach, the bind chooser, the wire rows and their menu's header). Tests find these rows by the widget they stand for.
    - **"…" means "the command needs more from you before it completes"**: a prompt, a colour prompt, a code prompt, the file chooser, a download ("Save world snapshot…", "Save to file…"), a confirmation ("Empty bin…") and the resize handles ("Resize/move…"). The Inspector's footer reads "Add…", "Rename…", "Remove", "Save". A submenu row never has dots ("Attach": its chevron says it); a row that opens a window has none ("Inspect", "Edit script"). "Delete all" has none (§0.5 #4). ASCII "..." ends no label.
    - **The bundle** (accepted as recommended): "OK" (not "Ok") on every prompt, inform and footer button; the Inspector's title "Object Inspector — <name>", the name as stored ("— analog clock", "— Docs Maker"), "Class Inspector — <Class>", "Console — <name>" (no forced lowercase); app names follow the draft's captions, "Patch programming" and "Super toolbar" (window, caption, info doc), the Makers keep "Docs Maker", "Slides Maker", "Dashboards Maker", "Drawings Maker"; toggles "Methods", "Fields", "Inherited", "Own props only" (the error log's pause / un-pause toggle is G's); a row whose label is a VALUE (dock sides, wallpapers, the property chooser's pin names, the overflow rows built from tooltips) is capitalised at the row and the value stays; font names, member names, class names and Fizzytiles' code tokens are never re-cased; messages over empty menus in sentence case ("No widgets to attach to"); a derived name that reads badly gets a human override where it shows (a slider's knob "circle-box", a list "viewport"); new folders "New folder 2", like "Untitled 2"; tooltips are out of scope except where one IS an overflow row; the live defects found are fixed (the four layout prompts titled "undefined\nbase width:", "More Icons 2" titled twice, the dev-mode desktop header "WorldWdgt").
  - **Orchestrator:**
    - **Case is a DISPLAY transform of the bar's title text**, never stored: `StringWdgt.transformTextOneToOne` (the hook passwords use) gains a case mode, so measuring, fitting, wrapping and painting all see the shown form and the hug stays exact. Stored text stays the name: a pinned menu carries its header's STORED text into its window title (`FrameBarWdgt._reDeriveRosterNoSettle`), `CommandPanelWdgt.promptTitleAsking` builds prompt titles from the menu's title, and `colloquialName` names saved files, so an uppercase written into any of them would leak. A transform that paints but does not measure would shrink the header (it hugs its text) to fit.
    - **Pin labels, dock sides, wallpaper names and member names are identity**: `pinLabelled` / `principalPinLabel` / `sliderRangeForPin`, `DesktopAppearance`'s switch and the serialized `wallpaperPatternName`, the Inspector's property names, Fizzytiles' generated code. Capitalising happens where a row is built, never inside `MenuItemWdgt` or `LabelButtonWdgt`.
    - **Labels used as keys move with their wording in the same unit**: `SimpleTextWdgt` removes ten rows BY EXACT LABEL (a stale key fails silently: the row stays), and a reflecting row's label is passed twice.
    - **Tests**: wording rows are found by EXACT label (the 121 prefix and substring lookups all start lowercase, so sentence case breaks every one; they become exact); name rows by the widget they stand for. `macroMenuPinnedInScrollPanel`'s prefix "color palette" hits "color palette in window" (its image_4 shows the wrong palette), so it gets an exact label; `macroBoxTransparencyAndColorChanging` (aims into prompts by fractions, asserts nothing) gains value assertions before any recapture.
    - **`fg menusweep` proves the rules at runtime**, as it proves `opensSubmenu` (W2): a dispatched row ends in "…" exactly when it opened a prompt / a code prompt / the file chooser / a download / a confirmation / the handles (`ELLIPSIS_MISMATCH`); every row label starts with a capital or a non-letter (`SENTENCE_CASE`), data rows declared.
- **Units** (one Opus implementer each; a src unit and its test-and-script sweep are gated TOGETHER, since a stale label throws): W6a the title display case (UPPER for name headers, sentence for every other bar title) with the header names, the choosers' noun headers, the message headers and the untitled layout submenus; W6b titles' wording (the Inspector, the class inspector, the console, app names, info docs, new folders, the bad derived names); W6c the wording rows and buttons (sentence case, "…", "OK", value rows, overflow rows, the label keys, the toolkit's labels, then the tests, scripts and docs); W6d the name rows (one helper, the toolkit's widget-identity row verb, the tests); W6e the atlas additions (➜ ⇄ ↔ ← → ↑ ↓ ∸ ⍿ ☓ ⋯ °), researched first (R4); W6f the two menusweep proofs.
- **Findings while landing W6** (each fixed in its unit, gated):
  - **Case is a display transform, and it must measure too (W6a).** `StringWdgt.displayCase` applies in `transformTextOneToOne`, which measuring, fitting, wrapping, the back-buffer key and painting all read; a header hugs its text, so a paint-only uppercase would have shrunk it. The bar decides each title's case in one place (`FrameWdgt._titleDisplayCase`), and a menu whose title is a message says so (`titleIsAMessage`). The stored words never change: pinning a menu carries its header's STORED text into its window title, and prompt titles are built from the menu's (`CommandPanelWdgt.promptTitleAsking`, which also fixed the four layout prompts titled "undefined\nbase width:", opened from untitled submenus).
  - **Widget menus are dev-mode only** (`Widget.buildContextMenu` returns nothing in user mode), so a human name that "shows" in a header or a hierarchy row shows to a developer; the overrides (W6b) follow that.
  - **Every prefix lookup was a latent misdelivery (W6c).** All 121 prefix and substring row lookups started lowercase, so sentence case broke every one; one already clicked the wrong row (`macroMenuPinnedInScrollPanel`'s "color palette" also matched "color palette in window": its image_4 showed a palette in a window, not the bare palette it describes). The toolkit now finds a row only by its EXACT label or by the widget it stands for (`rowOfMenuStandingFor`, W6d); the prefix and substring verbs and `rowOpensSubmenu` are deleted (they went dead, and the dead-methods gate caught it).
  - **Labels are keys in a few places** and moved with their wording: `SimpleTextWdgt` removes ten rows by exact label (a stale key fails SILENTLY); a reflecting row's label is passed twice; value rows (dock sides, wallpapers, pins, overflow tools) are capitalised where the row is built (`CommandPanelWdgt.rowLabelOfValue`) so the value stays.
  - **One naming home for rows that name a widget (W6d)**: `Widget.rowName` + `CommandPanelWdgt.rowLabelsNaming` replace seven inconsistent `toString()` sites (one leaked "Wdgt"); the Automator's id-hiding hooks stay, since `toString` still feeds the bin's placement hash and dev displays. Wire rows now carry the wire's target, not the wire record, so hovering one highlights its target.
  - **The symbols atlas grows without moving an existing pixel (W6e, R4)**: appending to `FONT_INVARIANT_CHARS` and generating at `--batch-size=24` on this Mac gave 0 diffs over every existing glyph; the default batch (72) moves dpr-2 glyphs at 91–96 px. `fg` kills every webkit process, so a generator must not run during an `fg` operation. Found in passing: 124 dpr-2 bold/italic font atlases at 73–84.5 px in the shipped release carry single-row images under two-row positioning (BACKLOG).
  - **The "…" proof found a product bug by dispatching the file rows for the first time (W6f)**: any world with a list on screen (an Object Inspector) could not be saved as a snapshot, because `ListWdgt` stored a function as an own field (`labelGetter`, never passed by any caller). The option went; a list labels its rows through the static `ListWdgt.labelOf` (owner: fix now). The sweep stubs the file chooser and downloads in its page, so the three file rows are dispatched, not skipped.

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

- **Research (2026-10-20)**, `Fizzygum-tests/.scratch/g/R{1,2,3}-report.md`: R1 the per-family census in src (`r1/looks.tsv`: 384 look decisions; `r1/ratchet-tail.tsv`: the 72 sites; `r1/predesign-roles.tsv`: 62 of 150 roles not on the palette; live shots of every family), R2 the suite footprint measured by playing the whole suite in one page (`r2/census-raw.json`, `r2/footprint.tsv`, the aims, assertions and rigs at risk), R3 the open points owed to G, the legacy icons and a wave grouping. Facts that shape the units:
  - **The draft is silent on every G family** except plain lists (§7.1) and "selected" (§2: an `accentTint` fill with an accent border and text, never a solid dark fill).
  - **Measured footprint** (tests / mouse dpr-1 shots): video player 0 / 0 (not in the dev build), error console 2 / 2, Fizzytiles 2 / 3, patch programming 1 / 4, demos 10 / 30, prompts' fields 6 / 11, plots + dashboards + slides + folders 8 / 18, drag feedback 18 / 32, text selection 7 / 34 (all inside the focus frame's), spreadsheet 19 / 37, halo handles 20 / 47, generic leftovers 19 / 54, sliders + the colour picker 44 / 129, the editor-focus frame 79 / 200.
  - **The `raw-chrome-color` gate excludes by path only**, and whole directories as content (`demos/`, `graphs-plots-charts/`, `fizzytiles/`, `video-player/`, …): chrome living there (plot axes, magnets) is censused by hand, and the 36 sites that are not chrome (palette data, paint-tool colours, wallpapers, the debug overlay, the keyboard input, pixel reads, transparent clears) cannot be excluded one by one today.
  - **Look values copied into instance fields ride every snapshot** (the spreadsheet's 7 colours — the sheet rebuilds its cells from them on load —, every panel's fill and stroke, a text's ink and selection colours, slider, magnet and handle colours).
  - **One generic panel default** (`panelFill` 249, `panelStroke` 198) is the visible body of the patch canvas, the Makers' pages, the folder panel, every code pane's plane, Fizzytiles' panes and a plain list; `Widget`'s default 80 grey paints chrome by accident in three places (the halo's split adjuster, plot axes, the code pane's "modified" triangle).
  - **Non-pixel risks**: the spreadsheet's tests and the serialization rig assert its grid SHAPE (row and column pitch, child counts, the cell text inset); a slider track right-click at `[0.5, 0.85]` is verified only as "on the slider or inside it", so a thumb that grew would misdeliver silently; palette picks at fractions take their colour from the palette's geometry; `HighlightTracksRotatedIslandTarget` asserts the highlighter's bounds; the dock-band tests assert the band's depth; the folder window's structure is read by the apps, parts and graph rigs; `ErrorConsolePopsClean` reads the pause toggle.
  - **Live defects found**: Fizzytiles' four pane captions paint nothing (13 px text in a 15 px band); a `FanoutWdgt` throws on paint (its constructor takes a colour no caller passes); the save-shortcut prompt's title reads "save as..." (a leading space takes the display case's capital; ASCII dots); off-strip demo close / collapse buttons draw white glyphs that turn red / orange on hover; a bare `TextAreaWdgt` paints a yellow plate behind its text; the prompt slider's thumb turns black after one hover (`setColorScheme` never sets `normalColor`).
- **Decisions settled at G's start (2026-10-20; four owner rounds, every answer the recommended option)**:
  - **Owner:**
    - **Five small waves**, in this order: G-A apps' chrome, G-B halo and drag feedback, G-C values, G-D selected and editing, G-E leftovers and close.
    - **The generic panel default moves onto the palette** in G-E (`panel` fill, `line` border); the window bar's pencil / eye stay legacy and become a BACKLOG icon line.
    - **The editor-focus frame**: none while a caret is in the widget (the accent caret says "focus"); a SELECTED non-text item gets a 2 px `accent` outline that follows its own shape (rounded where it is rounded).
    - **Text selection**: a solid `accent` plate with `paper` text (the draft's selected label plate).
    - **Spreadsheet**: header fill `desk`, header text `muted2`, header rule `line`, gridlines `chrome`, the selection a 2 px `accent` ring, values `ink`, errors `danger` (§4.8 of the design doc gains "and error states"); the sheet's doubled outer edges go; read at paint time, so a saved sheet wears it; geometry unchanged.
    - **The apps' pages** (Slides, Dashboards, Generic panel, Patch programming), the folder window's panel and the code panes' planes: `paper`, each on its own role, with no inner border where the window frame already draws the line; a plot's area `paper`, its axes, ticks and labels `muted2`, its box `line`; series colours untouched.
    - **Fizzytiles**: magnets in the button look with code-font labels; the panes keep their geometry, on `paper` with `line` borders; the code pane in the code role; the captions fixed so they show (`muted2`).
    - **Icons redrawn in G** (each with owner rounds through the skill): W4's composites (the shortcut arrow, the object / widget / script frames, the C-F converter, a new spreadsheet icon), W5's text-toolbar align trio, font-size pair and Templates, and the halo's move / resize / rotate (the rotate glyph is the owner's four-swirlies square). Every other legacy icon becomes one BACKLOG line under `pixel-icons-plan.md` §5b.
    - **Halo handles and layout chrome**: each handle a `paper` rounded-6 plate with a `line` border and an `ink` size-aware glyph (move: four-way arrows; horizontal / vertical: double arrows; rotate: the four-swirlies square; the corner: the frame grip's strokes with a square hit area); adders, spacers and split adjusters the same look; targets stay 44; reviewed together with the pending halo feel-check (G2).
    - **Drag feedback**: the drop candidate and the dock band outlined 2 px `accent`, following the target's own corners; a reluctant target `line`; the dwell ring `accent` filling over an opaque `line` track; the armed label `ink`; the lift shadow keeps its own token.
    - **Sliders** (content and prompt): the thumb in the button look (`paper` inside a `line` border; hovered `desk`; pressed `chrome` inside a `frame` border), the track an opaque borderless `chrome` groove; geometry unchanged; the scroll indicators keep W2's look; the prompt slider's `normalColor` bug fixed. The palettes' choice marker stays a two-tone ring (`ink` + `paper` roles); the palettes' gradients are data.
    - **The prompt's text field**: the `item` fill, radius 6, no border, its size unchanged; a bare `TextAreaWdgt` loses its yellow default (the tests that pass that yellow themselves keep it: it is their fixture).
    - **Plain lists** (outside the Inspector): the draft's §7.1 list, as W3 gave the member list (40 px rows at radius 6, 2 px gaps, 4 px padding, an `accentTint` selected row, no hairlines, no panel fill).
    - **Defaults**: the ink of a text with no colour of its own becomes `ink` (a role); a new shape's 80 grey stays a declared content default, and where it paints chrome by accident (the split adjuster, plot axes, the "modified" triangle) that chrome gets its own role in its family.
    - **Small marks**: the header-line rule `chrome`; the code pane's "modified" corner triangle `muted3`; the speech bubble a `plate` fill with a `line` stroke, keeping its tail, 12 px `ink`.
    - **The error log's pause control**: a fixed-label "Pause" toggle (`LabelledToggleWdgt`, on while paused); the toggle class moves from the lazy `meta-tools` part into core.
  - **Orchestrator:**
    - **G changes surface, not structure** (draft §10): colours, borders, corner radii, drawn glyphs. Geometry stays except where a decision above moves it (the plain list rows, the corner handle's square hit area, the Fizzytiles caption bands), and each such move re-expresses its tests' aims and assertions by meaning before any recapture.
    - **Every look is read where it is used** (arrange, paint, state derivation), never copied into an instance at construction, so a saved world wears the new look (the W4 / W5 pattern). Class-level state colours become reads of roles at each state change.
    - **A role per surface**: a family's unit gives its own surfaces their roles and never changes a shared default; the shared defaults move once, in G-E.
    - **The ratchet's non-chrome sites are DECLARED**: the gate gains a list of sanctioned sites (file and member, each with its reason; an entry that no longer matches fails), so the ratchet can reach 0 without blinding a whole file. The gate edit is the orchestrator's (G-E).
    - **Filed, not waved**: the video player (no dev build ships it, no test shows it); the spreadsheet's grip over its bottom-right cell; a resize grab-offset compensation; the patch node's text padding (kept at 5); the demos' wording; the W1–W3 open points on done surfaces, unless a G diff page shows them.
    - **Fixed in their family's unit**: the Fanout paint crash (G-A), the Fizzytiles captions (G-A), the folder window's title "Folder — Examples" (§4.9's dash rule; G-A), the save prompt's "Save as…" title (G-C), the off-strip close / collapse glyphs (G-E), the prompt slider's thumb (G-C).
    - **The six W4 composites (owner, round 1 on the design agent's preview, `Fizzygum-tests/.scratch/g/ai/composites-preview.html`; every proposal swept at every size)**: the shortcut badge a paper box with an ink frame and a one-line paper knockout ring around it, holding a straight 45° arrow (shaft and two head arms), its line the host glyph's; the object frame the family's PAGE with a folded corner (a shared page helper on the base); the script frame the same page with indented code lines and a round run badge; the generic widget picture the 2×2 square / triangle / circle / square on the family's line; the C-F converter a thermometer between a C and an F, its degree signs dots at 40 px (the round-feature rule) and rings from 59; the spreadsheet's own icon the content card ruled as a grid with a header row and column, in core `src/icons`, named by `AppCatalog` and the spreadsheet window's `representativeIcon`.
    - **The hierarchy menu's hover wash** (pure blue at alpha 50, marking the widget a row stands for) becomes an `accentTint` wash (G-D); owner review at the wave.
- **Waves and units** (one Opus implementer per unit; a unit — or two small units with disjoint footprints, gated together — passes its presuite pixel-only, its probe and the unit rigs before the next starts; icons run as an owner-review track, as in W4):
  - **G-A — apps' chrome.** A1 spreadsheet; A2 patch-programming nodes (field labels, text boxes, the pinout label, the Fanout crash); A3 the error log's "Pause" toggle; A4 plot chrome, the Makers' page (the patch canvas included) and the folder window (panel, title); A5 Fizzytiles; icons: the six W4 composites.
  - **G-B — halo and drag feedback.** B1 the handles' plates and glyphs (three new icons through the skill, the grip reused, the square corner hit area); B2 the layout chrome (adders, spacers, split adjusters, droplets); B3 drag feedback (outlines, the ring, the label).
  - **G-C — values.** C1 the slider (content and prompt); C2 the colour picker; C3 the prompt's field, the text area's default and the "Save as…" title.
  - **G-D — selected and editing.** D1 the focus frame; D2 text selection (`StringWdgt.blanksColor` deleted: no reader); D3 the hover wash; D4 plain lists.
  - **G-E — leftovers and close.** E1 state colours read from roles (`HighlightableMixin`'s consumers, `SwitchButtonWdgt`'s unread colours deleted, `ButtonWdgt`, `CanvasWdgt`, the icon buttons' hovers); E2 the default text ink; E3 the small marks; E4 the generic panel default (and every panel / viewport fill and stroke read where it is painted, a surface's own role overriding it — today they are copied into the widget at construction, as G-A2's patch-node boxes still are); E5 the text-toolbar icons (and the Templates characters palette: trim or extend, asked at G-E); E6 the gate's declared sanctions and the ratchet to 0; E7 `visual-design-system.md` completed.
- **Findings while landing G-A** (each fixed in its unit, gated):
  - **A look read where it is used needs a hook, not a copied field (A4, A5).** The generic panel copies `panelFill` / `panelStroke` into each panel's own fields at construction, so a surface that wears a role instead holds NO colour of its own and answers a paint-time hook: `RectangularAppearance._fillColor` (`widget.color ? widget._surfaceFill?()`) and `_borderColor` (`strokeColor ? _surfaceStroke?()`), a viewport's `_surfaceFill` forwarding its contents', a text's `_backgroundFill` (`backgroundColor ? _surfaceBackgroundFill?()`). A Maker's page, a folder's panel, a plot's surround and Fizzytiles' panes use them; G-E generalises the pattern to the generic panel default.
  - **A Maker's page draws its edge only where it is letterboxed** (`StretchablePanelWdgt._insetEdgeRects`, from where it stands in its container), so a page flush with the window doubles no line and a crystallized slide still shows its boundary.
  - **A class gaining a method shows in an Object Inspector**: StringWdgt's new `_backgroundFill` shifted six inspector member lists by one row (the diff page's classifier: pure vertical translations, 0 px residual). Benign, recaptured.
  - **The spreadsheet's look moved from saved fields to paint time**: the sheet rebuilt its cells from seven serialized colour fields; the fields are gone and every reader asks the theme, so a saved sheet wears the current look.
  - **Live defects fixed**: Fizzytiles' four pane captions painted nothing (13 px text in a 15 px band; now 12 px, `fizzytilesCaption`); a Fanout node threw on its first paint (a `(@color)` constructor nobody passed a colour to); the folder window titled "folder: Examples" (`setTitle` now joins with a dash).
  - **Icons designed offline, then ported**: a read-only design agent drew the six composites with the vendored SWCanvas in plain Node (calibrated: its ports of two approved icons rendered 64 / 64 byte-identical to the build), the owner chose from a preview page, and the port matched the approved renders byte for byte on the live build (`SizeAwareIconAppearance` lost `_useLight` and `_pxPanel`, whose only caller was the old badge, and gained the shared page).
  - **Owner review**: the Fizzytiles code pane was boxed like the other three panes (A5b: a `fizzytilesCodePaneStroke` ring read at paint, its text inset by `codePanePadding`).

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
      measured; the corner decision went to S1c, which passed (the rounded child clip is adopted for W1).
