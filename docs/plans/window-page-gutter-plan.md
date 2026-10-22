# Window pages — one gutter around a window's page, its bands, and its selection ring

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
**AUTHORED 2026-10-22 — NOT STARTED; owner decisions D1–D5 LOCKED (§2), D6–D8 recommended, confirmed at P0.**
It was written against Fizzygum master `12a439cf` and Fizzygum-tests master `d7fbdd0d7` (suite 335 SystemTests;
`fg gauntlet` 19/19 and `fg homepage` OK on that code). Re-verify §1 against the tree of the day before trusting it.
- Line numbers drift. A quoted method or field name is authoritative: grep it fresh before trusting a `file:line`.
- Keep the STATUS box current at every phase close.

**Mandate: transformation, not a patch.** Fizzygum names the two kinds of window content (a PAGE you work on, a PANE
that is a view), and ONE rule places them. A window keeps ONE gutter around its page and between its page and its
docked bands. A page's selection ring lives in that gutter, painted by the window that owns the space. Every value is
a `Theme` metric read where it is used, never copied into a widget.

---

## STATUS
| Phase | What | State |
|---|---|---|
| P0 | Confirm D6–D8; reference policy; review-sample additions | not started |
| U1 | Page declaration + the host gutter, landed at gutter 0 (pixel-neutral) | not started |
| U2 | The document's spacing split into inset and gap, landed at today's values (pixel-neutral) | not started |
| U3 | The page's selection ring painted by its window, in the gutter (pixel-neutral while the gutter is 0) | not started |
| U4 | A drop in a window's gutter goes to its page | not started |
| V | The flip (gutter 8, document inset 0), owner review, ONE recapture wave | not started |
| Z | Close: docs, BACKLOG, archive | not started |

---

## §0 Orientation (read first)

**Fizzygum** is a CoffeeScript GUI framework, a "web OS" painted on one `<canvas>`. The umbrella `Fizzygum-all/`
holds three sibling repos: `Fizzygum/` (source; edit only `src/**/*.coffee`), `Fizzygum-tests/` (macro SystemTests
and reference PNGs), `Fizzygum-builds/` (generated; never edit). Read first: the root `CLAUDE.md`,
`Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md`, `Fizzygum/src/macros/CLAUDE.md`. Two backends: native canvas (AA,
production) and SWCanvas (non-AA, the suite and the owner's daily use); SWCanvas first. The design system is
`src/Theme.coffee` (`WorldWdgt.theme`), documented in `docs/architecture/visual-design-system.md`; the visual redesign
that built it is archived at `docs/archive/redesign/redesign-plan.md` (with the draft beside it).

**The problem (owner, 2026-10-22).** In the Docs Maker the docked toolbar stands 8 px in from the window, but the
document below it runs from the toolbar's bottom edge to the window's left, right and bottom edges. At rest this is
invisible (the document pads its own paragraphs 8 px), but the 2 px accent selection ring and the menu-hover wash
reveal the document's box hugging the window border and the toolbar. In the Drawings Maker the paper canvas, which
draws its own 1 px border, touches the vertical toolbar and the window edges: 2 px double lines at rest.

**Why it is shaped this way.** The redesign set `Theme.frameBodyMargin = 0` (W1, so that panes such as the Object
Inspector run full width, as the draft draws them) and wrote at W5: "a docked band sits `dockedBandInset` (8) from the
host on its three outer sides and flush with the payload; the payload's own content supplies its spacing (the
document's stack pads 8)". So the band carries its own gutter, the content area carries none, and each content widget
pads itself — the document does, a canvas does not.

**The measured extent (2026-10-22, a live survey of 24 window types; screenshots in
`Fizzygum-tests/.scratch/padding/shots/`):** every window's content area has a 0 px gap on all four sides; only docked
bands are inset. Four groups:
- **Panes, flush by design** (the window's border and its strip's rule are their lines; code comments say so): the
  Object and Class Inspectors, the spreadsheet, the folder window, the bin, the console / script / error-log windows,
  a window holding a plain panel, the empty window's placeholder.
- **Pages beside a docked band:** Docs Maker, Drawings Maker, Slides Maker, Dashboards, Patch programming.
- **Bordered content against the window's lines (2 px double lines):** Draw's canvas, Fizzytiles' three boards, the
  sample slide and dashboard panels.
- **Pages without a band:** Generic panel, How-to-save and the "info" documents, the samples, the C↔F converter.

### ⭐ The critical reframe
Fizzygum has TWO kinds of window content and the redesign gave both the pane treatment:
- a **PANE** is a view whose edges ARE the window's lines (flush is right: the draft's own Inspector);
- a **PAGE** is a surface you work on (a document, a canvas, a slide, a dashboard, a patch board, Fizzytiles' boards).
  The draft's intent for a page is a uniform 8 px gutter: in `desktop-canvas.html` `drawDocsMaker` the toolbar is at
  window + 8 and the first paragraph at window + 8, toolbar bottom + 8, as wide as the toolbar.

The fix names the kinds, gives a page's window ONE gutter (the band's 8, now shared by band and page), takes the
document's own outer inset away (so its paragraphs do not move), and moves a page's selection ring into the gutter.

### The owner's mockups (2026-10-22)
In-page prototypes on the dev build, no src change: `Fizzygum-tests/.scratch/padding/mockups/index.html` (five layout
variants × four apps, at rest and selected) and `.../mockups-outring/index.html` (the chosen layout with the ring
outside). Scripts: `.scratch/padding/mockups.js`, `mockups-outring.js` (they patch ONE window instance in the page:
`win.padding = border + 8`, `win._dockedBandInset = () => 0`, the document's `_takeItemSpacing` → inset 0, gap 8; the
outside ring is a `HighlighterWdgt` laid over the page's box grown by offset + 2). The chosen variant is
"gutter-items-kept" with the "page-outring-2" ring. `.scratch` is gitignored and local.

### §0.5 Cold-execution protocol
1. Orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status`. Read this STATUS box, §0, §2, then the phase.
2. Re-verify §1 on the day's tree (grep each quoted method; re-run `.scratch/padding/page-footprint.js` if needed).
3. P0: confirm D6–D8 with the owner (AskUserQuestion, recommendation first), record the answers in §2.
4. Orchestration (as in the redesign, `docs/archive/redesign/redesign-plan.md` §6): the session's top model is the
   architect and gate; Opus subagents implement ONE bounded unit each, with self-contained briefs that FORBID builds,
   `fg`, commits, docs/BACKLOG/memory edits, `fg killz` and killing browsers they did not launch. Mutating agents run
   one at a time in the real tree, never in a worktree. The orchestrator reads every diff, re-verifies one claim
   empirically, runs every gate itself, and owns docs and commit proposals. After two bounces on a unit, stop
   delegating it.
5. Owner rules: never commit or push without explicit approval (an approval never carries over); `git commit -F
   <file>`, `git -C <abs repo>`; never `git stash`; long ops ONCE in the background with an ETA and status every
   ~5–10 min; never pipe a gating `fg`; `fg` only by absolute path; never `rm -rf` / `find -L` at
   `Fizzygum-builds/latest/js/tests`; ask before going out of scope; recaptures are owner-gated.

---

## §1 Current state (verified 2026-10-22; re-grep before trusting)

### 1.1 How a window lays out its body (`src/FrameWdgt.coffee`)
- The class comment above `_borderInset` states the model: "My BODY is what my border encloses, less my strip … Past
  those edges my payload and my bands keep my BODY MARGIN, and the same margin parts a band from my payload; a band
  also stands its own inset in from those edges (`_dockedBandInset`), on every side but the one it shares with my
  payload."
- `_bodyMargin: -> @padding - @_borderInset()`. `@padding` is set ONCE in the constructor, `@padding =
  @_chromePadding()` = `theme.frameBorderWidth + theme.frameBodyMargin` — a stored (serialized) field, global to every
  frame (windows, cards, docked band frames, pop-ups: `popUpCenteredAtHand`, `PopUpRowsViewportWdgt` read it).
- `_payloadOffset` = `(_bodyEdgeLeft + _leftDockThickness + _bodyMargin, _bodyEdgeTop + _topDockThickness +
  _bodyMargin)`.
- `_chromeHeight(spec)` = `_bodyEdgeTop + _borderInset + 2 * _bodyMargin + top + bottom dock thickness` (+ the grip's
  footprint unless `spec.resizerCanOverlapContents`, which defaults to `true` in `FrameContentLayoutSpec`).
  `_chromeWidth` is the width twin. ONE home for the measure and the arrange: they must agree.
- `_dockThicknessAt(side)` = `_dockedBandInset() + dockedFrame._dockedBandThickness() + _bodyMargin()`.
- `_dockedBandInset: -> WorldWdgt.theme.dockedBandInset` (8). It is counted PAST the body margin (the arrange places
  a band at the body edge + margin + inset; measured: raising the margin to 8 moved the band to 16).
- The arrange is `_positionAndResizeChildren`; its band block computes `bandRun = bodyWidth - 2 * bandInset`,
  `columnTop = bodyTop + _topDockThickness() + bandInset`.
- The grip (`FrameGripWdgt`) sits `frameBorderWidth + frameGripInset` (1 + 3) from the window's outer corner, read from
  the theme, never from the frame's padding; it is 36 px. The corner reserve is by occupancy
  (`bottomRightCornerReachedBy`, `ViewportWdgt.cornerResizerFootprint`).
- Theme metrics: `frameBodyMargin = 0`, `dockedBandInset = 8`, `frameBorderWidth = 1`, `windowCornerRadius = 8`,
  `cardCornerRadius = 6`, `frameGripSize = 36`, `frameGripInset = 3`, `selectionOutlineWidth = 2`,
  `dropOutlineWidth = 2`, `documentItemSpacing = 8`.

### 1.2 The pages and their spacing
- **Docs Maker:** `SimpleDocumentApp` → `DocumentWdgt` (a FrameWdgt) → payload `DocumentViewportWdgt` (extends
  `VerticalStackViewportWdgt`), band `TextToolbarWdgt` (`dockSide: 'top'`). The document's spacing is
  `DocumentViewportWdgt._takeItemSpacing` (called at the top of every arrange): `@extraPadding = spacing;
  @contents?.padding = spacing` with `spacing = theme.documentItemSpacing` — "my stack's padding, which is both its
  inset and its gap — and my content frame keeps the same margin around them (the two must agree)".
  `VerticalStackPanelWdgt` already separates the two roles: `padding` is the inset, `interElementGap()` the gap
  (default: the padding; `CommandPanelWdgt` overrides it to 0). The document's comment says "in a window, the window's
  frame, its strip's rule and a docked band are the page's lines" — this plan makes that false.
- **Draw:** `FizzyPaintApp` → `ImageWdgt` (extends `GenericPanelWdgt` extends FrameWdgt) → payload
  `StretchableWidgetContainerWdgt` around `StretchableCanvasWdgt` (+ `CanvasGlassTopWdgt` overlay); band
  `PaintToolbarWdgt` (`dockSide: 'left'`). The canvas has no padding; it draws a 1 px border.
- **Slides / Dashboards / Patch programming / Generic panel / the samples / C↔F converter:**
  `StretchableWidgetContainerWdgt` around a `StretchablePanelWdgt`; band on the left where present. Comment in
  `StretchablePanelWdgt`: "along a flush side the window's frame, its strip's rule or a docked band is the line".
- **Fizzytiles:** payload `FridgeMagnetsWdgt` (`externalPadding: 0`, `internalPadding: 5`), three bordered boards.

### 1.3 The selection ring and the hover wash
- The editor selection is `world.editorFocusWdgt` (set by a click release and a drop; `WorldWdgt._setEditorFocusNoSettle`
  is the one write). `WorldWdgt._widgetBeingEdited` decides which widget is framed; `_updateEditorSelectionOverlay`
  (once per cycle, before paint) caches it in `_editorSelectedWidget` and calls `_changed()` on the old and new widget
  (cross-invalidation-sanctioned, PULL model); `isEditorSelected(w)` is the public O(1) query.
- The ring is painted by the selected widget itself, INSIDE its own box, after its subtree:
  `Widget._showsSelectionOverlay` → `_paintEditorSelectionOverlayIfSelected` → `_drawSelectionOverlay` →
  `HighlightOutlineAppearance.paintRing ctx, w, h, theme.selectionOutlineWidth, (@cornerRadiiFollowingMyOutline …),
  theme.selectionOutline, …`.
- The menu-hover wash is a `HighlighterWdgt` (`coverTarget`: the target's `clippedThroughBounds`, its corners) — inside
  the target's box; unchanged by this plan.

### 1.4 The gutter's behaviour today (probe `Fizzygum-tests/.scratch/padding/gutter-behaviour.js`, 2026-10-22)
- A press-drag starting in the 8 px gutter beside the Docs Maker's band MOVES THE WINDOW (the press lands on the
  frame's body).
- A widget dropped in that gutter LANDS ON THE DESKTOP (`WorldWdgt`) while it is visually over the window. A gutter
  on every side of every page makes this common: U4 fixes it.

### 1.5 Suite footprint (G's census, `Fizzygum-tests/.scratch/g/r2/census-raw.json`; script
`Fizzygum-tests/.scratch/padding/page-footprint.js`)
- 20 tests / 52 shots (mouse) show a top-level window whose payload is a page (`DocumentViewportWdgt` 20 shots,
  `StretchableWidgetContainerWdgt` 29, `FridgeMagnetsWdgt` 3); all 20 also run under finger. 3 more shots show pages
  only in nested windows. Panes: no change.
- At rest the document's paragraphs do not move (D2). What changes: the page's box (scrolled text clips 8 px inside
  the window; the document's scroll indicator moves 8 px in), every Stretchable page shrinks 16 px in each axis (its
  content letterboxes smaller), Fizzytiles' boards move in, and every selected page's ring.
- Tests and rigs that read page geometry must be grepped at U1 (`DocumentViewportWdgt`, `StretchableWidgetContainerWdgt`,
  `FridgeMagnetsWdgt`, `contents.bounds`, `extentWrappingPayloadAt`, `SpreadsheetApp`/`FolderWindowWdgt` openers that
  size by chrome) in `Fizzygum-tests/tests` (macro sources are CoffeeScript inside JS template literals: grep `.js`) and
  `Fizzygum-tests/scripts`.

---

## §2 Decisions

### Locked by the owner (2026-10-22, after the mockups)
- **D1 — Pages keep a gutter; panes run flush.** One gutter, `G` = 8 (the band's existing inset), on every side of a
  page, including the BOTTOM (the chosen mockup), and between a page and each docked band. A band keeps standing 8 from
  the window on its three outer sides (it does not move).
- **D2 — The gutter replaces the document's own outer inset ("items kept").** The document keeps only the GAP between
  its paragraphs (8); its inset becomes 0. Its paragraphs stay exactly where they are today: as wide as the toolbar,
  8 below it. (Rejected: the document keeping its own 8 inside the gutter — paragraphs at 16, narrower than the
  toolbar, a double top spacing; the owner disliked both.)
- **D3 — A page's selection ring lies OUTSIDE the page, in the gutter, at offset 2:** 2 px of air, then the 2 px
  ring, 4 px left before the window border. It is painted by the WINDOW (the container owns the space and paints what
  lies in it — the seam rule of the redesign §2). Every other selection ring stays INSIDE its widget, as G-D drew it
  (a paragraph's ring inside the paragraph stays aligned with the toolbar; an outside paragraph ring would poke past
  the toolbar's edges and escape the document's clip).
- **D4 — No full-bleed toolbar.** The band stays the draft's inset card (the full-bleed variant did not fix the
  selected page hugging the window and dropped the draft's toolbar).
- **D5 — The page is a declared KIND, not a window setting.** A page keeps the gutter whether or not a band is docked
  (a band floated out, collapsed or switched off leaves the page where it is).

### Recommended, confirm at P0
- **D6 — Membership.** Pages: `DocumentViewportWdgt`, `StretchableWidgetContainerWdgt` (Draw, Slides, Dashboards,
  Patch programming, Generic panel, the samples, the C↔F converter), `FridgeMagnetsWdgt`. Panes (unchanged): the
  Inspectors, the spreadsheet, the folder and bin panes, the code areas, a plain panel or viewport as a window's whole
  content, the empty window's placeholder, the Super toolbar (its window hugs its toolbar).
- **D7 — A drop in the gutter goes to the page** (U4). Today it lands on the desktop. The press-drag that moves the
  window from the gutter stays (it is today's behaviour beside a band).
- **D8 — Paint order of the page ring vs the grip.** Recommended: the ring under the grip (the grip is window chrome
  above content); the mockup showed the ring over it. The owner sees both at V.
- **Reference policy.** Land on master directly, one owner-approved commit pair at V (the redesign's close measured
  that branch-and-squash buys nothing).

---

## §3 The distilled argument
- **Why a declared kind.** Whether content wants a gutter is a fact about the content (a canvas is a page wherever it
  is shown), not about the window, so the payload declares it and the window reads the declaration at every measure.
  A window setting would have to be remembered by every opener.
- **Why ONE gutter shared with the bands.** Two spacing rules (band 8, page 0) are the defect; the band's inset
  becomes the gutter's value, so they cannot drift apart. The band's position does not move: for a page host the
  band's own extra inset past the gutter is `max(0, dockedBandInset − gutter)` = 0.
- **Why the document loses its inset.** A container owns the space around its children (the window's gutter, the
  stack's gap); the content owns none. That is context-free: the document's spacing no longer depends on where it is,
  and the gutter supplies the room the old inset supplied, so nothing at rest moves.
- **Why the window paints the page's ring.** The ring needs room the page no longer has inside itself; the room is the
  window's gutter, so the window paints in it. Nothing escapes a clip (the gutter is inside the window's body).
- **Why two steps** (the redesign's G-E lesson): land each mechanism with the gutter at 0 and the document inset at 8 —
  provably pixel-neutral — then flip `Theme` alone and check the changed set against §1.5.

---

## §4 Units
Each unit is ONE bounded brief with acceptance criteria. Gate every unit with `fg presuite` AND `fg revisits`, plus
its probe (probes under `Fizzygum-tests/.scratch/gutter/`). A hook-path unit (U1, U3) also closes on `fg gauntlet`.

### P0 — Decisions and set-up (orchestrator)
- Confirm D6–D8 and the reference policy; record them in §2.
- Add to `docs/tooling/visual-review-sample.txt`: the Drawings Maker, Fizzytiles and a selected-page test (whichever
  existing tests show them; F0-style grep).

### U1 — The page declaration and the host gutter (pixel-neutral: `Theme.windowPageGutter = 0`)
- A payload declares it is a page through a class-level capability (name it for the GUARANTEE, e.g. "keeps a window's
  page gutter"; never a type test). D6's classes declare it.
- `FrameWdgt` reads the declaration at every measure and arrange (never copied, never serialized):
  - the body margin of a page host is `theme.windowPageGutter`; every other frame keeps `frameBodyMargin` (pop-ups and
    band frames included). Decide whether `_bodyMargin` stops reading the stored `@padding` (preferred: a derived
    margin, read where used), and keep every reader of `@padding` consistent;
  - a page host's band inset past the margin is `max(0, theme.dockedBandInset − margin)`, so the band does not move;
  - `_payloadOffset`, `_chromeWidth`, `_chromeHeight`, `_dockThicknessAt`, the arrange's band block,
    `extentWrappingPayloadAt`, `floatOutOfDock`, `sizeToPayloadNaturalExtent` and the drop-offer geometry
    (`_dockBandsBox` / `dockBandBoxAt`) agree on the same terms.
- New metric `Theme.windowPageGutter` = 0 in this unit.
- Acceptance: presuite failing set unchanged (empty); revisits clean; a probe that sets the gutter to 8 IN-PAGE and
  checks, for each D6 page window: the page 8 from every window edge and 8 from each band; each band where it was;
  panes byte-identical; a band floated out leaves the page at 8; resize keeps the gutter; save/load and duplicate lay
  out with the gutter.

### U2 — The document's spacing split into inset and gap (pixel-neutral)
- `DocumentViewportWdgt._takeItemSpacing` sets the stack's INSET from a new `theme.documentItemInset` (8 in this unit)
  and its GAP from `theme.documentItemSpacing` (8), and the viewport's `extraPadding` from the inset (the two must
  agree). The stack's gap is its own knob (`VerticalStackPanelWdgt.interElementGap`; give the document's stack a way to
  answer it that is not a type test).
- Fix the document's comments that say the window's lines are the page's lines.
- Acceptance: presuite unchanged; a probe with `documentItemInset` 0 and `windowPageGutter` 8 in-page puts the first
  paragraph at exactly today's pixel position in the Docs Maker, How-to-save and a sample document.

### U3 — The page's ring painted by its window, in the gutter (pixel-neutral while the gutter is 0)
- A page in a host whose gutter is > 0 does not paint its own ring (`_showsSelectionOverlay`); its host paints a ring
  around the page's box at `theme.pageSelectionOutlineOffset` (2) out, `selectionOutlineWidth` (2) thick, its corners
  the page's corners grown by offset + width (a square corner stays square), clipped by the window's body, under the
  grip (D8).
- Damage: when the selection moves to or from a page, the gutter must repaint, not only the page's box. Preferred: the
  reconciler (`_updateEditorSelectionOverlay`) also tells the page's host through ONE intent-named public method on
  `FrameWdgt` (the invalidation-privacy rule, gate `check-invalidation-receivers.js`; sanction the call in the comment
  as the reconciler's existing calls are). `world.isEditorSelected(page)` keeps answering true: tests read it.
- Acceptance: presuite unchanged at gutter 0; a probe at gutter 8 in-page: selecting a page draws the ring at offset 2
  in the gutter and nothing inside the page; deselecting leaves the gutter clean (pixels); a selected paragraph keeps
  its inside ring; a tilted window's page ring repaints through the island buffer.

### U4 — A drop in a window's gutter goes to its page (D7)
- Find why a drop over the gutter falls through to the world (the frame declines it; the payload is not under the
  point) and route it to the page the gutter surrounds, by the drop-target resolution's own rules (a page that rejects
  the payload rejects it in its gutter too). Keep the press-drag from the gutter moving the window.
- Acceptance: a probe drops a box in each side's gutter of a Docs Maker (it lands in the document) and of a Drawings
  Maker (it lands where a drop on the canvas lands); the band-gutter case of today is fixed too; presuite unchanged.

### V — The flip, review and ONE recapture wave
1. Flip `Theme`: `windowPageGutter` 8, `documentItemInset` 0.
2. `fg presuite`: the changed set must match §1.5's prediction (≈ 20 tests); every needs-a-fix or AIM MISSED is fixed
   first, never recaptured over.
3. Owner review: `fg diffpage $(grep -v '^#' Fizzygum/docs/tooling/visual-review-sample.txt)` from `Fizzygum-all/`
   plus the changed tests; the live worlds (`Fizzygum-builds/latest/index-sw.html` and `index.html`): open each D6
   app, select its page, select a paragraph, drop into a gutter, resize, float the band out.
4. Recapture (backgrounded, ETA + status): `fg recapture --auto --dprs=1,2`, then `fg recapture --auto
   --pointer=finger --dprs=1,2`. ⚠ A Monitor on a recapture log greps the verdict tokens (`RECAPTURE COMPLETE|
   INCOMPLETE|INCONCLUSIVE|needs-a-fix|UNSTABLE`), never "FAIL". Regenerate the visualisation page of every test edited
   but not recaptured (`node scripts/make-visualisation.js <Test>`).
5. Close gates: `fg gauntlet`, `fg homepage`. Propose the commit pair.

### Z — Close
- Docs: `visual-design-system.md` (a rule "Pages keep the window's gutter; panes run flush", the §5 rows for windows,
  pages and the page ring, §6 "is your content a page?"), `regularity-principles.md` ("The frame model": the gutter),
  `layout.md` §4.2 (it never mentions `EdgeDockLayoutSpec`, the family's sixth member — add it), the stale comments
  (`CodeAreaWdgt`: "windows already add their own inner padding"; `StretchablePanelWdgt` and `DocumentViewportWdgt`
  "the window's lines are the page's lines"; `Theme`'s `frameBodyMargin` / `dockedBandInset` /
  `windowContentPanelStroke` notes).
- BACKLOG: close this plan's line; file the observations below that this plan does not fix.
- `git mv` this plan to `docs/archive/`, stamp it, add an INDEX line; memory note; `/close-arc`.

**Observations from the survey this plan does NOT fix (file them in BACKLOG at Z):** the spreadsheet's last row is
clipped by the window's rounded bottom corners (a pane); the slide/dashboard panel paints its border only when
letterboxed (`StretchablePanelWdgt._insetEdgeRects` judges inset against its container); the selection ring on Draw's
canvas shows only 1 px today (the canvas border covers the outer pixel; moot once the ring is in the gutter).

---

## §5 Central risks
1. **Measure/arrange disagreement** (the frame's chrome terms must agree; `FrameWdgt` comments call this "§6.1 rule
   1"). Mitigation: one derived margin read by all of them; `fg revisits` per unit (a disagreement shows as a settle
   re-visit).
2. **The band moving.** Mitigation: the band's inset past the margin is `max(0, dockedBandInset − margin)`; U1's probe
   checks every band's rect.
3. **Copied state.** `@padding` is stored and serialized. Mitigation: the gutter is read at every measure, never
   copied; U1's probe loads a snapshot saved before the flip.
4. **The ring's damage.** A missed invalidation leaves a ring in the gutter after deselection. Mitigation: U3's
   pixel check after deselect; the gauntlet's paint audit.
5. **Drops.** U4 changes where a drop lands; the drag-embed rules (`docs/specs/drag-embed-interaction-spec.md`) must
   hold for windows dropped near a page window's edge (a window over a gutter dwell-arms a DOCK band first: the band
   tier is checked before container embedding).
6. **Tests that read page geometry.** Grep at U1 (§1.5); re-express by meaning, never bake a changed assertion in.

## §6 Verification protocol
- Per unit: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (expected failing set stated in the unit),
  `fg revisits`, and the unit's probe against a fresh build. U1 and U3 also close on `fg gauntlet`.
- Finger: `node scripts/run-all-headless.js --pointer=finger` from `Fizzygum-tests/` (dpr 1) and `fg finger`.
- Close: `fg gauntlet` (19 legs), `fg homepage`.
- Static gates run in every build (`docs/architecture/lint-and-static-checks.md`); `raw-chrome-color` stays at 0 (new
  values are `Theme` metrics, not colours).

## §7 Rejected alternatives (do not re-attempt)
- **The document keeping its own 8 inside the gutter** (mock "gutter"): paragraphs at 16, narrower than the toolbar,
  16 above the first paragraph against 8 at the bottom. Owner-rejected.
- **A full-bleed toolbar** (mock "fullbleed-band"): the selected page still hugs the window; drops the draft's card.
- **An outside ring on EVERY widget:** a paragraph flush with the document's sides would need its ring to escape the
  document's clip (a new overlay mechanism with a reach limit), and it pokes past the toolbar's edges.
- **Raising `frameBodyMargin` globally:** it is every frame's margin (pop-ups, band frames, cards), and it moves the
  bands (their inset is counted past it).
- **An open bottom** (mock "gutter-open-bottom"): a side band then runs down to the window's edge too, breaking its
  card look.

## §8 References
- `docs/architecture/visual-design-system.md`, `regularity-principles.md` ("The frame model"), `layout.md` §4.2,
  `appearance-paint-convention.md`, `integer-pixel-placement-and-sizing.md`; `docs/specs/drag-embed-interaction-spec.md`.
- The draft: `docs/archive/redesign/UI-guidelines.md` §6.5–§6.6, `desktop-canvas.html` `drawDocsMaker`.
- `docs/archive/redesign/redesign-plan.md` §2 (seams owned by the container), §3a (rounded corners), §4 W1, W5, G-D.
- Mockups and probes: `Fizzygum-tests/.scratch/padding/` (`measure.js`, `mockups.js`, `mockups-outring.js`,
  `gutter-behaviour.js`, `page-footprint.js`, `shots/`, `mockups/`, `mockups-outring/`).
- Memory: `fizzygum-visual-redesign-arc` (G-E: two-step flips, read where used).

## Sizing (estimate)
One to two sessions: P0 + U1 + U2, then U3 + U4 + V + Z. ONE recapture wave of about 20 tests at mouse and finger,
dpr 1 and 2.

## Start prompt for a fresh session
> Run the Fizzygum window-page-gutter plan cold: `Fizzygum/docs/plans/window-page-gutter-plan.md` (authored
> 2026-10-22; owner decisions D1–D5 locked). Orient with `/Users/davidedellacasa/code/Fizzygum-all/fg status`, read the
> plan's STATUS box, §0 and §2, and re-verify §1 against today's tree. Start with P0 (confirm D6–D8 with me), then run
> U1 → U2 → U3 → U4 in orchestration mode (§0.5), each landed pixel-neutral, then V. Never commit, push or recapture
> without my approval.
