# Window pages — one gutter around a window's page, its bands, and its selection ring

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
**AUTHORED 2026-10-22 — ✅ CLOSED 2026-10-23 (Fizzygum 6e4946cd + the Z docs commit, Fizzygum-tests cc9aa0e1e; pushed). Owner decisions D1–D11 and the reference policy in §2. ARCHIVED: the living rule is `architecture/visual-design-system.md` §4.10.**
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
| P0 | Confirm D6–D8; reference policy; review-sample additions | DONE 2026-10-22 (all four recommendations taken; U2 reshaped by R1's bare-document finding; the selected-page test is new, in U3) |
| U1 | Page declaration + the host gutter, landed at gutter 0 (pixel-neutral) | LANDED (uncommitted) 2026-10-22: presuite OK (failing set empty); probe `.scratch/gutter/u1-probe.js` all PASS (19 targets; a band's rect identical at G=8, panes byte-identical, float/resize/duplicate/world snapshot keep the gutter); gauntlet 19/19 OK(warn: paint + serialization serial-only, launched at load 20.8/16) |
| U2 | The document's spacing split into inset and gap, landed at today's values (pixel-neutral) | LANDED (uncommitted) 2026-10-22: inset = max(0, spacing − `FrameWdgt.pageGutterAround`), gap through the plane (`interElementGapOfPlane`), a re-parented document re-takes its inset (`_reactToBeingAdded`, phase valve; load-bearing for a move out of a window, measured); presuite OK, revisits OK; probe `.scratch/gutter/u2-probe.js` all PASS (paragraphs identical at G=0/G=8 in 3 page windows, a bare document unchanged, duplicate/snapshot/move in and out) |
| U3 | The page's selection ring painted by its window, in the gutter (pixel-neutral while the gutter is 0) | LANDED (uncommitted) 2026-10-22, gauntlet 19/19 OK(warn: storage serial-only = the known shard-0 `DragEmbedReleaseWhileChargingLandsOnWorld` one-off, 4th sighting, log `.scratch/gutter/u3-gauntlet-storage-parallel-fail.log`): host derived per cycle (`hostsSelectionRingOf`, the ring box tracked too, so a band floated/collapsed inside an unchanged window repaints it), painted before children (under the grip), hosted only while the ring fits the gutter; presuite OK, revisits OK, probe `.scratch/gutter/u3-probe.js` 132/132 (Docs/Draw/Slides, paragraph, deselect, resize, band collapse/uncollapse/float, tilted island). New test staged at `.scratch/gutter/u3-new-test/` (captured at V) |
| U4 | A drop in a window's gutter goes to its page | LANDED (uncommitted) 2026-10-22: the drop climb starts at `ActivePointerWdgt._dropClimbStart` (a page window names its page's receiver for points on its own body: `dropReceiverForPointsOnMyBody` / `receiverOfDropsAroundMe`), a gutter drop is moved inside the receiver's visible box; presuite OK (pixel-neutral at G=0), revisits OK; probe `.scratch/gutter/u4-probe.js` 348/348 (real drops vs an in-page TODAY control: Docs/Draw/Slides gutter drops land in the page; bar, grip, desktop, panes, Fizzytiles, the dock tier and the gutter press-drag unchanged) |
| V | The flip (gutter 8, document inset 0), owner review, ONE recapture wave | DONE 2026-10-23: flipped; presuite 12 failed, all predicted, pixel-only; owner review → D9–D11 (unit W); new test captured; recapture COMPLETE at mouse and finger (13 tests); gauntlet 19/19 OK(warn: serialization serial-only, the file round-trip rig race, BACKLOG), homepage OK; COMMITTED + PUSHED Fizzygum 6e4946cd, Fizzygum-tests cc9aa0e1e |
| W | The review's follow-ups D9–D11 | LANDED (uncommitted) 2026-10-22: Stretchable page edges on all four sides in a gutter, the document's caret scroll margin (`_caretScrollMargin`), letterbox-margin drops to the panel; presuite failing set 13 ⊂ predicted 21 (pixel-only), revisits 0 re-visits at G=8 (judged on the audit dir: the suite itself still failed on pixels), probe `.scratch/gutter/w-probe.js` 283/283 |
| Z | Close: docs, BACKLOG, archive | DONE 2026-10-23: `visual-design-system.md` §4.10 + §5 rows + §6 step 9, `regularity-principles.md` (the frame model), `layout.md` §4.2 (EdgeDockLayoutSpec), `appearance-paint-convention.md`, `drag-embed-interaction-spec.md`, `CodeAreaWdgt` comment; BACKLOG closed with its residue; archived |

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
  only in nested windows. Panes: no change. Pages with no window around them — 16 tests / 60 shots of a bare
  `DocumentViewportWdgt`, 1 test of a bare `StretchableWidgetContainerWdgt`, 3 tests of pages in a transform island
  (R1, P0) — do not change either (U2's inset rule).
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

### Confirmed by the owner at P0 (2026-10-22)
- **D6 — Membership.** Pages: `DocumentViewportWdgt`, `StretchableWidgetContainerWdgt` (Draw, Slides, Dashboards,
  Patch programming, Generic panel, the samples, the C↔F converter), `FridgeMagnetsWdgt`. Panes (unchanged): the
  Inspectors, the spreadsheet, the folder and bin panes, the code areas, a plain panel or viewport as a window's whole
  content, the empty window's placeholder, the Super toolbar (its window hugs its toolbar).
- **D7 — A drop in the gutter goes to the page** (U4). Today it lands on the desktop. The press-drag that moves the
  window from the gutter stays (it is today's behaviour beside a band).
- **D8 — The page ring paints UNDER the grip** (the grip is window chrome above content; the mockup showed the ring
  over it). The owner sees it at V.
- **Reference policy.** Land on master directly, one owner-approved commit pair at V (the redesign's close measured
  that branch-and-squash buys nothing).

### Decided by the owner at V's review (2026-10-22, "the Right Thing, ignoring churn")
- **D9 — A Stretchable page in a gutter paints its edge on all four sides.** Its edge marks the sheet's extent (what
  a slide or dashboard presents); window body, gutter and page are all `paper`, so a side without its edge has no
  boundary at all. The flush-side exemption held only while the window's own line was that boundary; outside a gutter
  (a bare container, gutter 0) the letterbox-only rule stays. Matches Draw's canvas, which always draws its border.
- **D10 — A document's caret scroll margin is its own (scroll padding), not its inset**: it stays
  `documentItemSpacing` (8) in a page window, so a caret brought into view keeps its line's context. Its overlay
  scroll indicator over the items' right edge is ACCEPTED (overlay thumbs lie over content in every viewport; at rest
  the thumb sits inside the item's 10 px text padding).
- **D11 — A drop on a letterboxed Stretchable page's own margin goes to its panel** (the U4 rule extended to the
  container's own body), moved inside the panel.

---

## §3 The distilled argument
- **Why a declared kind.** Whether content wants a gutter is a fact about the content (a canvas is a page wherever it
  is shown), not about the window, so the payload declares it and the window reads the declaration at every measure.
  A window setting would have to be remembered by every opener.
- **Why ONE gutter shared with the bands.** Two spacing rules (band 8, page 0) are the defect; the band's inset
  becomes the gutter's value, so they cannot drift apart. The band's position does not move: for a page host the
  band's own extra inset past the gutter is `max(0, dockedBandInset − gutter)` = 0.
- **Why the document gives up its inset IN a page window.** A container owns the space around its children (the
  window's gutter, the stack's gap). Where a window keeps a gutter around the document, the gutter supplies the room
  the inset supplied, so the inset yields to it — the same rule as the band: an item stands `documentItemSpacing` from
  the window's body edge, the gutter counted toward it. A document with no gutter around it (bare on the desktop, in a
  transform island) keeps its own inset, so nothing at rest moves anywhere.
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
  existing tests show them; F0-style grep). Found at P0 (R1's runtime probe, `.scratch/gutter/r1/`): the Drawings Maker
  and Fizzytiles tests are already listed; NO existing shot (mouse or finger) shows a page as the editor-selected
  widget, so U3 has no suite footprint and its ring is pinned by a NEW test written in U3 (a Docs Maker and a Drawings
  Maker page selected, then deselected), captured in V's wave and added to the sample.
- Also from R1: no test or rig reads `_bodyMargin` / `frameBodyMargin` / `dockedBandInset` / `_payloadOffset` /
  `extentWrappingPayloadAt` / a window's `padding`; no numeric assertion changes at the flip. Watch at V:
  `DegreesConverterFourWayDrive` (slider drags by fraction on a page that shrinks: its °C/°F values in image 0/1 may
  round differently) and `DocsToolbarDockSidesAndFloat` (its dwell-dock point lies 7 px inside the page at the flip:
  the band tier must stay ahead of U4's gutter routing).

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
- ⚠ P0 finding (R1, 2026-10-22): 17 tests (≈ 60 shots) show a document BARE on the desktop (no window) or in a
  transform island. A global inset of 0 would move their paragraphs 8 px up-left — against D2's "paragraphs stay put".
  So the inset is NOT a flipped metric: it is the BAND RULE applied to items. A document's items stand
  `documentItemSpacing` from the document's edges LESS the gutter its window keeps around it:
  `inset = max(0, documentItemSpacing − gutter)`, the gutter asked of the parent through ONE capability query that a
  page-hosting `FrameWdgt` answers (dispatched `?()`, 0 when nobody answers). A bare document keeps 8; a document in a
  page window keeps 8 at gutter 0 and 0 at gutter 8; no `documentItemInset` metric exists, and V flips ONE value.
- `DocumentViewportWdgt._takeItemSpacing` sets the stack's INSET (`padding`) and the viewport's `extraPadding` from that
  inset (the two must agree), and `setContents` uses the same inset. The stack's GAP is `documentItemSpacing`, asked
  through the plane as `itemShapeOfTextOnPlane` is (`VerticalStackPanelWdgt.interElementGap` asks its parent, falling
  back to its padding; `CommandPanelWdgt` keeps its own 0).
- Fix the document's comments that say the window's lines are the page's lines.
- Acceptance: presuite unchanged; a probe with `windowPageGutter` 8 in-page puts the first paragraph at exactly today's
  pixel position in the Docs Maker, How-to-save and a sample document, and a bare document's paragraphs do not move.

### U3 — The page's ring painted by its window, in the gutter (pixel-neutral while the gutter is 0)
- ⚠ R2 finding (2026-10-22, `.scratch/gutter/r2/probe1-2.js`): a click on a page NEVER selects the page widget. It
  selects a child covering it exactly: the document's stack, Draw's `CanvasGlassTopWdgt`, a Stretchable page's
  `StretchablePanelWdgt` (Fizzytiles: a sub-board, smaller). So THE PAGE RING is the ring of the selected widget whose
  visible box (`clippedThroughBounds`) IS its window's page box — the page itself or a descendant filling it — in a
  window whose gutter is > 0. The window that hosts it is DERIVED once per cycle in `_updateEditorSelectionOverlay`
  (it can change while the selection does not: a resize, the flip) and cached beside `_editorSelectedWidget` (cleared
  with it at teardown). A letterboxed slide panel or a Fizzytiles board keeps its inside ring (it is an item on the
  page). Paint: the window overrides its own `paintIntoAreaOrBlitFromBackBuffer` (normal pass, after its fill, before
  its children: nothing overlaps a ring 2..4 px outside the page, and the grip, its last child, paints over it — D8).
  Damage: `previousHost?.notePageSelectionRingChanged()` / `host?.…` → the window's own `_changed()` (a page's own
  damage covers only its right and bottom ring sides: measured 1240 of 2508 accent pixels).
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
- R2 finding (2026-10-22, `.scratch/gutter/r2/probe3.js`): a gutter point's top widget is the frame itself, which
  declines (an occupied frame `disableDrops`), so the climb `dropTargetFor` / `resolveDragEmbedCandidates` goes
  frame → world. Shape: the climb STARTS at what the top widget names for points on its own body
  (`FrameWdgt` answers its page's drop receiver when it hosts a page; the document and the Stretchable page name their
  receiving child), so a drop on the bar, the grip or a band is unchanged and the dock tier (checked first) is
  untouched; the grab path (`findRootForGrab`) is untouched. Architect decision: a widget dropped through a gutter is
  moved by the least offset that brings its box inside the receiver's visible box before the add — otherwise a box
  released in a band's outer gutter lands wholly outside a free-placement page, invisible (measured on Slides).
- Find why a drop over the gutter falls through to the world (the frame declines it; the payload is not under the
  point) and route it to the page the gutter surrounds, by the drop-target resolution's own rules (a page that rejects
  the payload rejects it in its gutter too). Keep the press-drag from the gutter moving the window.
- Acceptance: a probe drops a box in each side's gutter of a Docs Maker (it lands in the document) and of a Drawings
  Maker (it lands where a drop on the canvas lands); the band-gutter case of today is fixed too; presuite unchanged.

### W — The review's follow-ups (D9–D11), after the flip and before the recapture
- `StretchablePanelWdgt._insetEdgeRects`: all four edges while its container stands in a window's page gutter
  (asked of the container, which asks its parent `pageGutterAround`), else today's letterbox-only rule.
- `ViewportWdgt` reads its caret scroll margin from one query (default: its inset, padding + extraPadding);
  `DocumentViewportWdgt` answers `documentItemSpacing`.
- `StretchableWidgetContainerWdgt` answers `dropReceiverForPointsOnMyBody` (its panel), so a drop on its letterbox
  margin goes to the panel, moved inside it.
- Gates: presuite (the failing set stays the 12 + the shots of D9), revisits, a probe; then the owner sees the
  Stretchable shots again before the recapture.

### V — The flip, review and ONE recapture wave
1. Flip `Theme`: `windowPageGutter` 8 (the document's inset follows by the U2 rule).
2. `fg presuite`: the changed set must match §1.5's prediction (≈ 20 tests); every needs-a-fix or AIM MISSED is fixed
   first, never recaptured over.
3. Owner review: `fg diffpage $(grep -v '^#' Fizzygum/docs/tooling/visual-review-sample.txt)` from `Fizzygum-all/`
   plus the changed tests; the live worlds (`Fizzygum-builds/latest/index-sw.html` and `index.html`): open each D6
   app, select its page, select a paragraph, drop into a gutter, resize, float the band out. Put these consequences,
   measured at U1–U2, to the owner explicitly:
   - a document's overlay scroll indicator (4 px at edge inset 2, `ViewportWdgt._barFrameAt`) sat in the page's own
     8 px right margin; with the inset at 0 it overlays the right 6 px of the item blocks when the document overflows;
   - the caret's scroll-into-view margin (`ViewportWdgt` `marginAroundCaret` = padding + extraPadding) becomes 0 in a
     page window: a caret scrolled into view lands flush with the page's edge (still 8 from the window's border);
   - a Stretchable page's panel paints its 1 px edge only where it is letterboxed (`StretchablePanelWdgt._insetEdgeRects`);
     along a flush side the gutter, not a window line, now meets it — does a flush side need its edge?
   - `TemplatesWindowWdgt` holds a document, so it becomes a page window too;
   - the scrollbar corner reserve stays the grip's full footprint although the page's corner is 8 in (safe, 8 px
     short of exact);
   - (U4) a drop on a LETTERBOXED slide's own margin (inside the page, outside the panel: the container is the top
     widget) still goes to the desktop while a drop in the window's gutter goes into the slide — extend the same
     capability to `StretchableWidgetContainerWdgt` (its margin's points go to its panel)? Not done: beyond D7's
     wording;
   - (U4) a window nested in container C, released unarmed over the gutter of a sibling page window P in C, is now
     ejected (as a release over P's page is), where it used to stay in C; a window nested in a page, released in its
     host window's gutter, now stays nested; hovering a gutter now outlines the page's receiver.
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
- Also from the units: `appearance-paint-convention.md` device-space exceptions gain `FrameWdgt._paintPageSelectionRing`
  beside `Widget._drawSelectionOverlay`; `visual-design-system.md` §4.8 (the selection ring lies inside its widget,
  a page's excepted, painted by its window: `hostsSelectionRingOf` / `editorSelectionRingHost`); `layout.md` or the
  document's architecture note: a document's item inset yields to its window's gutter (`pageGutterAround`), its gap
  is asked through the plane (`interElementGapOfPlane`). `docs/specs/drag-embed-interaction-spec.md` (~:86 "cursor
  hit-test then parent-climb", ~:195–198 "Candidate = … parent-climb from the hit"): the climb starts at
  `ActivePointerWdgt._dropClimbStart` (a window's gutter hands its points to its page's receiver), and a gutter drop is
  moved inside the receiver's visible box.
- BACKLOG: close this plan's line; file the observations below that this plan does not fix.
- `git mv` this plan to `docs/archive/`, stamp it, add an INDEX line; memory note; `/close-arc`.

**Observations from the survey this plan does NOT fix (file them in BACKLOG at Z):** the spreadsheet's last row is
clipped by the window's rounded bottom corners (a pane); the slide/dashboard panel paints its border only when
letterboxed (`StretchablePanelWdgt._insetEdgeRects` judges inset against its container); the selection ring on Draw's
canvas shows only 1 px today (the canvas border covers the outer pixel; moot once the ring is in the gutter).
Also found during the units (2026-10-22): a world snapshot restores bounds as saved and re-lays nothing, so a window
saved under another theme shows its old geometry until something re-lays it (U1/U2 probes, INFO); a single window's
`serialize()` refuses a window holding real content (its off-tree `defaultContents` placeholder is "outside the
serialized structure"; only a world snapshot captures it); the gauntlet's `serialization` leg failed in parallel at
load 20.8/16 on the FILE round-trip (`file.saveByteExact` download ≠ in-memory, `saveValidEnvelope` unparseable,
`dropPixelParity`) and passed serially — first sighting, log `Fizzygum-tests/.scratch/gutter/u1-gauntlet-serialization-parallel-fail.log`.

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
