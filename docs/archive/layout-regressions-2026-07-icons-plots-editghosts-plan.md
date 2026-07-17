> **ARCHIVED — COMPLETE (2026-07-17 restructure).** D1-D4 fixes + Phase 5 LANDED+PUSHED, gauntlet green; 4 of 6 follow-ups done, 2 deferred with evidence
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Layout regressions 2026-07: shortcut icons, plot collapse, edit/view ghosts, slide scroll drift — triage + fix plan

**Status: Phases 1–4 (the D1–D4 fixes) DONE + COMMITTED 2026-07-07 (not pushed).** Commits
on `master`: `a88a1673` F2 (D2 ghosts) · `6ee377d2` F1 (D1 icons) · `0e3a5939` F3 (D3 plots)
· `126e9999` F4 (D4 scroll). All verified headless (Appendix B probes hit every §5.1 target)
and the full gauntlet is green (190/190 at dpr1 + dpr2 + WebKit, apps smoke, tier-naming /
settle / capstone gates). Two deviations from this plan were needed and are folded into the
commits: (a) the F1/F3 `_applyExtent` overrides are GUARDED (`if @child?...`) — the bare form
crashed at boot because those ctors `_applyExtent` before their children exist; (b) F4's value
is measurement-derived `scrollTo(1364,157)`, not the plan's re-issue of `(1484,246)` (see §8-C).
**Phase 5 (tests + gates) NOT started.** (It was thought to be gated on a plot "content-latency"
fix, but that turned out to be the example plots' intended ANIMATION — proven — so Phase 5 only needs
a one-line freeze fixture in the two plot macros; see §8-A/§8-C.) All remaining work — the optional
FizzyPaint fix, the F4 robust fix, and Phase 5 — is specced cold-executable in **§8**.

Original authoring note (kept for provenance): all four defects were reproduced headlessly,
root-caused to specific commits by git bisect (~35 measured builds across June 2026), and the
ghost fix was proven by runtime monkey-patch (97 021 px of ghost → 0). Everything was measured
against master `6f6c834e` (2026-07-06) with known-good baseline `f494e66c` (2026-06-01).

**This document is written to be executed COLD, with zero prior context.** §0 gives the
environment; §1 the defects and evidence; §2 the shared mechanism; §3 exact fixes with
before/after code; §5 verification + new tests; §6 the phase-by-phase execution order;
§7 the bisect provenance; Appendix B the complete, runnable measurement scripts (they
are the acceptance tests for every phase).

---

## 0. Cold-start context (read once, then execute §6)

**Workspace** (absolute paths used throughout):

- Umbrella: `/Users/davidedellacasa/code/Fizzygum-all/` (NOT a git repo) containing the
  three sibling repos `Fizzygum/` (source — the only place to edit), `Fizzygum-builds/`
  (generated output, never hand-edit), `Fizzygum-tests/` (SystemTest suite + Puppeteer
  in `node_modules`).
- Build: `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum && ./build_it_please.sh`
  → writes `../Fizzygum-builds/latest/`. Prefer the `fg` wrapper in the umbrella root
  (`./fg build`, `./fg suite`, `./fg gauntlet`, `./fg test <name>`) — it is cwd-proof; a
  PreToolUse guard hook blocks wrong-cwd build/test command shapes.
- **Standard verification after any source change:** `./build_and_test.sh` from
  `Fizzygum/` (full build + whole 190-test suite headless, ~1 min). Full pre-push gate:
  `./fg gauntlet` (build + suite at dpr1 + dpr2 + WebKit + apps smoke).
- Run headless probes with Puppeteer from the tests repo:
  `NODE_PATH=/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/node_modules node <script.js>`.
  Save probe scripts in the session scratchpad (or any temp dir), NOT in the repos.

**Repo state this plan was written against:** `Fizzygum` master `6f6c834e`. The working
tree already contains UNRELATED uncommitted owner work (modified `src/WorldWdgt.coffee`,
untracked `src/fizzytiles/FridgeMagnetsApp.coffee`, `src/icons/FridgeMagnetsIcon*.coffee`,
several `docs/*.md` incl. this file). **Do not revert, commit, or fold those into this
work.** All `file:line` anchors below are valid at `6f6c834e`; if the tree has moved,
re-anchor by the quoted code, not the line number.

**Working rules:** never commit/push without explicit owner approval (present a summary
+ proposed message and wait). Run phases in order, verifying each with its acceptance
probe before moving on. Backticks inside `git commit -m` get shell-substituted — use
`git commit -F <file>`.

**Fizzygum facts needed to read the code below:** no module system — every class is a
global; `nil` = `undefined`; one class per file, filename = class name. Rendering is a
dirty-region ("broken rectangles") loop: `changed()` / `fullChanged()` queue a widget's
repaint, BUT both are **silent no-ops while `world.trackChanges` has `false` on top**
(`world.disableTrackChanges()` pushes false, `maybeEnableTrackChanges()` pops —
`src/WorldWdgt.coffee:1077-1081`, `src/basic-widgets/Widget.coffee:2350/2395`). Layout:
`_reLayout(bounds)` = full layout incl. children placement (composite widgets override
it); `_reLayoutSelf()` = self-only hook (no-op in the base, `Widget.coffee:2546`); the
raw geometry cores `_applyExtent/_applyMoveTo/_applyBounds` do NOT invalidate layout and
do NOT re-run a child's `_reLayout` — `_applyExtentBase` (`Widget.coffee:1595-1602`)
commits bounds + `changed()` + `_reLayoutSelf()` ONLY, and only when the extent actually
changed. Public setters (`setExtent` …) self-settle via the deferred-layout machinery
and are FORBIDDEN inside layout passes (layering lint).

---

## 1. The four defects (all reproduced headlessly at `6f6c834e`)

Reproduction: boot `Fizzygum-builds/latest/index.html` headless (Appendix B boot
boilerplate), 1100×800 dpr 1. The desktop shows the broken icons immediately; the apps
are launched programmatically (`new SampleSlideApp().launch()` etc. — classes are
globals, the launch slots are `world.sampleSlideWindow` / `world.sampleDashboardWindow`).

### D1 — shortcut icons broken (folder "examples", sample doc/slide/dashb, Spreadsheet, Basement)

Symptom: every desktop/in-folder icon that carries the little shortcut-arrow badge draws
its inner icon too big and the arrow ~29 px, overflowing the 75×75 holder and colliding
with the label. Widget-tree dump at boot:

```
IconicDesktopSystemFolderShortcutWdgt [75x75 @90,345]        ← holder, correct
  GenericShortcutIconWdgt [75x60 @90,345]                    ← icon slot, correct (75 × 8/10·75)
    FolderIconWdgt [95x95 @90,345]                           ← WRONG: construction size, s/b ~60×60
    ShortcutArrowIconWdgt [29x29 @90,412]                    ← WRONG: 95·3/10 @ +95·7/10, overflows holder
  StringWdgt [75x15 @90,405] text:"examples"
```

`29 = round(95·3/10)`, `412 = 345 + round(95·7/10)` — the children still have the
geometry computed when `GenericShortcutIconWdgt` was constructed at its default 95×95,
before `IconicDesktopSystemWindowedApp.createOpener`
(`src/IconicDesktopSystemWindowedApp.coffee:42/47`) did `launcher.setExtent new Point 75, 75`.
The `setExtent` settle re-runs the **holder's** `_reLayout`
(`src/WidgetHolderWithCaptionWdgt.coffee:65`), which sizes the icon via raw cores
(`:102-103` → `@icon._applyExtent (new Point squareDim, squareDim*8/10).round()`), and a
raw apply never re-runs the icon's own child-placing `_reLayout`
(`src/icons/GenericShortcutIconWdgt.coffee:44`). Identically broken: all four launcher
icons inside the examples folder, and `BasementOpenerWdgt` (bottom-right; its
`GenericShortcutIconWdgt` is 95×76 inside a 75×75 holder).

### D2 — edit/view toggle ghosts (Sample slide, Sample dashboard, Degrees converter, +small: Sample doc)

Symptom: pressing the title-bar pencil/eye leaves "double images" — old-mode pixels stay
on screen under/next to the new layout; toggling back leaves more. Measured on Sample
slide: after toggle→edit, **97 021 px** inside the window differ from a forced truthful
repaint; after toggle→view, **85 351 px**. Crucially the widget TREE after the toggle is
correct (single copy of everything; container moved to x=+100 past the 95 px tools
panel), and the view→edit→view round-trip tree is **byte-identical** to the initial tree
— every artifact is stale paint, not state.

Chain (current source): `WindowWdgt.editButtonInBarPressed` (`src/WindowWdgt.coffee:211`)
→ `StretchableEditableWdgt.editButtonPressedFromWindowBar`
(`src/StretchableEditableWdgt.coffee:111`) → `enable/disableDragsDropsAndEditing` →
settle. The slide's extent does not change, so `_applyExtentBase`'s guarded `changed()`
never fires; the container only moves because `StretchableEditableWdgt._applyExtent`
(`:93-95`) calls `@_reLayoutSelf()` unconditionally. `SimpleSlideWdgt._reLayoutSelf`
(`src/apps/SimpleSlideWdgt.coffee:109`) then moves the tools panel + container with raw
applies inside `world.disableTrackChanges()` … `maybeEnableTrackChanges()` (`:119/:153`)
and — unlike every healthy `_reLayout` in the tree — **never calls `@fullChanged()`**.
The nested `StretchableWidgetContainerWdgt._reLayout` DOES call `@fullChanged()`
(`src/StretchableWidgetContainerWdgt.coffee:160`) but the outer disable frame is still
active at that moment, so the mark is silently dropped, not deferred. Net: zero repaint
marks for the whole moved subtree.

**Fix shape already PROVEN at runtime** (Appendix B.2 `--patch`): appending
`this.fullChanged()` to `_reLayoutSelf` on `StretchableEditableWdgt` + `SimpleSlideWdgt`
drops the ghost to **0 / 0 px**.

### D3 — plots collapse to a tiny top-left corner (dashboard scatter/function/bar; slide "NYC: traffic")

Dump inside the dashboard's scatter window:

```
WindowWdgt [162x162]
  PlotWithAxesWdgt [152x126 @139,195]  spec:ATTACHEDAS_WINDOW_CONTENT   ← correct bounds
    ExampleScatterPlotWdgt [42x33 @141,196]                             ← construction-era size
    AxisWdgt [5x40] / AxisWdgt [50x5]                                   ← construction-era sizes
```

`PlotWithAxesWdgt` gets correct bounds but its children were last laid out by the
construction settle (~50×45 default extent) and only *shifted* since. Chain: any window
resize → `WindowWdgt._positionAndResizeChildren` → `@contents._setWidthSizeHeightAccordingly`
(`src/WindowWdgt.coffee:641/647`) → **the mixin's** implementation
(`src/mixins/KeepsRatioWhenInVerticalStackMixin.coffee:9-12`) → raw `@_applyExtent` →
children never re-laid. Measured child/parent area ratio: 0.70 (good) → **0.089** (slide)
/ **0.072** (dashboard).

Dispatch facts (verified in the live world by comparing `prototype.<m>.toString()`):
`Object::addInstanceProperties` (`src/boot/extensions/Object-extensions.coffee`) copies
mixin methods onto the prototype unconditionally, and in the meta-compiled world
**`PlotWithAxesWdgt` and `IconWdgt` run the MIXIN's `_setWidthSizeHeightAccordingly`**,
while `StretchableEditableWdgt` runs its OWN (its class-body override wins there). This
is why the fix below avoids editing the mixin (it would change `IconWdgt` behavior for
every plain icon) and instead self-protects the composite.

Why the rest of the dashboard looks right: plain children (maps, bubbles, text) are
rescaled by `StretchablePanelWdgt._reLayout`, which correctly calls `w._reLayout()` per
child (`src/StretchablePanelWdgt.coffee:57-66`). Only *window contents* take the raw
mixin path. Note the same defect sits one level deeper: `PlotWithAxesWdgt._reLayout`
sizes its two `AxisWdgt`s (composites: tick rectangles + digit labels) via raw applies
(`src/graphs-plots-charts/PlotWithAxesWdgt.coffee:56-64`).

### D4 — Sample slide opens mis-scrolled (pin + traffic window at the left edge, map area mostly blank)

Metric: map-pin origin minus its clipping scroll frame's origin. Good baseline:
**(89, 23)**. Current: **(−11, 23)** — an exact **−100 px** x-drift = tools panel (95) +
`internalPadding` (5).

`SampleSlideApp.buildWindow` (`src/apps/SampleSlideApp.coffee`) builds all content while
the slide is in EDIT mode (`SimpleSlideWdgt._createToolsPanelNoSettle` sets
`dragsDropsAndEditingEnabled = true` during construction), calls
`windowWithScrollingPanel.contents.scrollTo new Point 1484, 246` (`:34`), and only as the
LAST step disables editing (`slideWdgt.disableDragsDropsAndEditing()`, `:73`) — which
shifts the container 100 px left / 100 px wider. Before `ce21dcf7` the whole build
settled ONCE at `world.add` time in final view-mode geometry; now every mutation settles
synchronously, the scroll offset is crystallized against edit-mode geometry, and the
final mode flip does not re-anchor the viewport.

The "blank map" is NOT a paint bug: the map widget is 1808×1115 but
`IconAppearance.calculateRectangleOfIcon` (`src/icons/IconAppearance.coffee:33`)
aspect-fits the 500×313 spec → the *drawing* is only 1781 px wide, centered, ending at
world x≈330 — exactly where the painted fragment ends; the drifted offset scrolls the
viewport past the drawing's edge. (Verified: after a forced full repaint the render is
unchanged, i.e. truthful.)

### How all this escaped the 190-test suite

No SystemTest opens the sample apps, toggles window edit mode, or screenshots the
desktop icons; the 12-app smoke gate checks *launch console-cleanliness*, not pixels.
§5.2/§5.3 close the hole.

---

## 2. The one underlying story

`817c2ce4` ("Self-settling public geometry API + layering enforcement", 2026-06-19)
converted 12 in-layout call sites from public setters to raw cores — 5 `doLayout` sites
(`AxisWdgt`, `FanoutWdgt`, `GenericObjectIconWdgt`, `GenericShortcutIconWdgt`,
`WidgetHolderWithCaptionWdgt`) and 5 `reLayout` sites (`StretchableEditableWdgt`,
`PatchProgrammingWdgt`, `DashboardsWdgt`, `SimpleSlideWdgt`, `ReconfigurablePaintWdgt`)
+ 2 `WorldWdgt` desktop sites. Correct per the layering rules, but the public setters
had been silently carrying two duties the raw cores don't have:

- **repaint** (the public pipeline marked moved regions) → D2;
- **child re-layout** (the setter's `_invalidateLayout` scheduled a settle that re-laid
  the resized composite's children at final geometry) → D1 / D3 / D4.

The deferred-settle era masked the second class: constructions left layouts invalid, so
a later settle re-laid everything anyway. The orphan-settledness arc — `ce21dcf7`
("orphans + constructors settle synchronously") + `527f6186` ("all constructors
build+settle via the NoSettle core"), both 2026-06-30 — made `new X()` return settled
and `layoutIsValid = true`, removing the accidental healing. (Same lesson family as the
2026-06-16 InspectorWdgt apply-own-bounds-first bug, one ring further out.)

Two invariants this plan enforces:

- **[INV-1]** A `_reLayout`/`_reLayoutSelf` that calls `world.disableTrackChanges()`
  must issue a covering `@fullChanged()` AFTER the matching `maybeEnableTrackChanges()`.
  Nested `fullChanged`s are dropped by design; only the outermost frame's repaint sticks.
  (In-tree precedent: `HorizontalMenuPanelWdgt._reLayoutSelf`.)
- **[INV-2]** Geometry applied raw to a *composite* child (one with its own `_reLayout`
  override) must be followed by that child's `_reLayout` — either the parent calls
  `child._reLayout bounds` (precedents: `WindowWdgt` title-bar buttons at
  `WindowWdgt.coffee:578/584/724`, `StretchableWidgetContainerWdgt.coffee:152/155`,
  `StretchablePanelWdgt.coffee:57-66`) or the composite self-protects with an
  `_applyExtent` override (precedents: `StretchablePanelWdgt.coffee:25-30`,
  `StretchableWidgetContainerWdgt.coffee:98-104`, `ScrollPanelWdgt`).

---

## 3. The fixes (exact edits, before → after)

Small, mechanical, no settle-machinery changes. After EVERY phase:
`cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum && ./build_and_test.sh` must pass
(expect possible reference recaptures ONLY at the places called out in §5.4), plus the
phase's acceptance probe (Appendix B).

### F2 — edit/view ghosts (do FIRST: one-liners, already proven, unblocks eyeballing the rest)

Add `@fullChanged()` right after `world.maybeEnableTrackChanges()` in FIVE
`_reLayoutSelf` bodies. Four share this exact tail — insert the marked line:

```coffee
    world.maybeEnableTrackChanges()
    @fullChanged()                    # <— ADD (INV-1: repaint what the raw applies above moved)
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

    @markLayoutAsFixed()
```

| File | `maybeEnableTrackChanges()` currently at |
|---|---|
| `src/StretchableEditableWdgt.coffee` (`_reLayoutSelf`, method starts :58) | :87 |
| `src/apps/SimpleSlideWdgt.coffee` (:109) | :153 |
| `src/apps/DashboardsWdgt.coffee` (:52) | :96 |
| `src/apps/PatchProgrammingWdgt.coffee` (:34) | :78 |
| `src/apps/ReconfigurablePaintWdgt.coffee` (:445) | :512 |

(All five share that exact tail — `maybeEnableTrackChanges()` → Automator block →
`@markLayoutAsFixed()`; insert immediately after `maybeEnableTrackChanges()`.)

Acceptance (B.2, B.4): Sample slide ghost 97 021/85 351 → **0/0**; Sample dashboard
107 394/102 469 → **0/0**; Degrees converter 110 316/109 479 → **0/0**. Known residuals
NOT fixed by F2 (chase afterwards, see §4): Sample doc 5 444/7 121, Docs Maker 0/1 408,
Generic panel 0/133, Slides Maker 0/61 — `SimpleDocumentWdgt`'s own layout tail already
has the `fullChanged` (`src/apps/SimpleDocumentWdgt.coffee:211-212`), so those come from
another (smaller) path; re-run B.4 after F2 and investigate whatever stays nonzero
(suspects: tools-panel add/remove, scrollbar relayout).

### F1 — shortcut icons (composite self-protection, [INV-2])

Give the two shortcut-icon composites the proven `_applyExtent` self-override (idiom
copied from `src/StretchablePanelWdgt.coffee:25-30`; recursion-safe because
`_reLayout` applies bounds first, so the base `_reLayout`'s own `_applyExtent` call
hits the equal-extent early-return):

In `src/icons/GenericShortcutIconWdgt.coffee` AND `src/icons/GenericObjectIconWdgt.coffee`,
add (anywhere at method level; suggested: right above `_reLayout`):

```coffee
  # Self-protecting resize (INV-2): I am a composite (icon + arrow placed by my
  # _reLayout), but parents size me with the raw _applyExtent core (e.g.
  # WidgetHolderWithCaptionWdgt._reLayout), which alone would leave my children at
  # stale geometry — the 2026-07 broken-shortcut-icons regression. Same idiom as
  # StretchablePanelWdgt./StretchableWidgetContainerWdgt._applyExtent.
  _applyExtent: (extent) ->
    if extent.equals @extent()
      return
    super
    @_reLayout @bounds
```

Notes: the holder's `_reLayout` does `@icon._applyExtent …` THEN `@icon._applyMoveTo p0`
— children are re-laid at the pre-move position and then shifted with the widget by the
move core; that is fine (moves recurse). The icon's own `_reLayout` runs inside the
holder's `disableTrackChanges` window, so its trailing `fullChanged` is dropped — the
holder's own covering `fullChanged` (`WidgetHolderWithCaptionWdgt.coffee:109`) repaints.
Do NOT also convert the holder's `:102-105` raw pairs to `child._reLayout` in the same
phase — one mechanism change at a time; note it as an alternative if anything resists.

Acceptance (B.1): `icons: {n: 2, bad: 0}` at boot (examples folder + Basement), and
after clicking the folder open, all 4 in-folder launcher icons visually correct (arrow
badge ≈ 30% of the icon square at its bottom-left, label clear of it). Also create an
object shortcut (any widget → menu → create shortcut) and resize it — `GenericObjectIconWdgt`
must track (`@icon`/`@objectIcon` raw pairs at `src/icons/GenericObjectIconWdgt.coffee:82-87`
get re-laid via the new override).

### F3 — plot collapse (same self-protection + recursive axes)

1. In `src/graphs-plots-charts/PlotWithAxesWdgt.coffee`, add the SAME `_applyExtent`
   override as F1 (composite: plot + 2 axes placed by `_reLayout`). This heals every
   resize path into the plot — the window-content mixin path (`_setWidthSizeHeightAccordingly`
   → `@_applyExtent`), fractional rescale, everything — WITHOUT touching
   `KeepsRatioWhenInVerticalStackMixin` (whose `_setWidthSizeHeightAccordingly` is also
   live on `IconWdgt` — verified dispatch, §1-D3 — so a mixin edit would have icon-wide
   blast radius; rejected).
2. In `PlotWithAxesWdgt._reLayout` (`:56-64`), the two `AxisWdgt`s are composites
   (ticks + digit labels built by THEIR `_reLayout`); convert the raw pairs to the
   parent-driven idiom, preserving the existing arithmetic verbatim (positions/sizes
   must not change — only the mechanism):

   ```coffee
   # BEFORE (raw pairs -- children of the axes stay stale):
   @vertAxis._applyExtent (new Point width/10 - 4, height).round()
   @vertAxis._applyMoveTo (@position().add new Point 0, -2).subtract((new Point -width/ftft,height/ftft).round())
   # AFTER (INV-2, WindowWdgt-title-button idiom -- same numbers, child _reLayout):
   vertAxisBounds = new Rectangle (@position().add new Point 0, -2).subtract((new Point -width/ftft,height/ftft).round())
   vertAxisBounds = vertAxisBounds.setBoundsWidthAndHeight (new Point width/10 - 4, height).round()
   @vertAxis._reLayout vertAxisBounds
   ```

   …and the same transformation for `@horizAxis` (`:59-61`). The `@plot` child
   (`:63-64`) is a LEAF (`GraphsPlotsChartsWdgt` subclasses paint by bounds), so its raw
   pair can stay. ⚠ `_reLayout(bounds)` sets position AND extent from `bounds` — build
   the rectangle from the SAME moveTo-point and extent expressions as the raw pair it
   replaces, in origin+extent form, and mind the existing `adjustmentX` term which reads
   `@vertAxis.left()` — it must read the vert axis's NEW position, so lay out `@vertAxis`
   before computing `adjustmentX` exactly as the current code order does.
3. `Example3DPlotWdgt` is a leaf (paints by current bounds) — expect it to heal via
   nothing at all (its window content path only needs correct bounds, which it already
   gets); verify visually that the dashboard's slider still rotates the mesh
   (`setParameter` wiring).

Acceptance (B.1): `slidePlotRatio ≥ 0.5` and `dashPlotRatio ≥ 0.5` (good baseline 0.70;
broken 0.089/0.072). Visual: dashboard plots fill their windows incl. axes ticks along
the full edges; dragging a plot window's resize handle keeps the plot filling it.

### F4 — Sample slide scroll drift (build-order fix, NOT machinery)

In `src/apps/SampleSlideApp.coffee` `buildWindow`: the `scrollTo` currently executes in
edit-mode geometry (`:34`, right after the map is added). Move the scroll to AFTER the
final mode flip so it is applied against view-mode geometry — i.e. after
`slideWdgt.disableDragsDropsAndEditing()` (`:73`), as the last content-affecting step
before `return wm`:

```coffee
    slideWdgt.disableDragsDropsAndEditing()
    # Re-anchor the NYC viewport AFTER the mode flip: the container shifts left by
    # toolsPanel(95)+internalPadding(5) when editing turns off, and post-orphan-settledness
    # (ce21dcf7) the offset no longer re-derives -- scrolling last anchors it in the
    # geometry the user actually sees. (2026-07 mis-scrolled-slide regression.)
    windowWithScrollingPanel.contents.scrollTo new Point 1484, 246
```

Keep (or delete) the original `:34` scrollTo — deleting is cleaner; if intermediate
build steps need the panel scrolled (they don't appear to — positions are set in
absolute inner-panel coordinates), keep both. Do NOT hardcode a new magic constant like
1584: re-issuing the ORIGINAL point post-flip is the intent-preserving form; verify the
result against the (89, 23) target and adjust only if measurement says so.

Acceptance (B.3): `nycPinRel = [89, 23]` (broken: `[−11, 23]`). Visual: view mode shows
the pin roughly mid-map with the "NYC: traffic" window mid-frame (matching §1-D4's good
description), map drawing covering the whole frame.

`SampleDashboardApp`/`SampleDocApp`/`SpreadsheetApp` have no scrolled panel in their
build — F4 is slide-only. OPTIONAL follow-on (own arc, do not bundle): decide whether
`ScrollPanelWdgt` should preserve the content-relative viewport through container
resizes in general; probe = scroll any panel, resize its window by the handle, assert
the top-left content point stays put.

---

## 4. Adjacent sweep — measured blast radius (current build, script B.4)

| App (launcher) | Content class | Collapsed composites | Ghost px (→edit / →view) | Verdict |
|---|---|---|---|---|
| Sample slide | SimpleSlideWdgt | PlotWithAxes 0.089 | 97 021 / 85 351 | D1+D2+D3+D4 |
| Sample dashb | DashboardsWdgt | 3× PlotWithAxes 0.072 | 107 394 / 102 469 | D1+D2+D3 |
| °C ↔ °F (Degrees conv.) | PatchProgrammingWdgt | — | 110 316 / 109 479 | D2 |
| sample doc | SimpleDocumentWdgt | — | 5 444 / 7 121 | small ghost, path ≠ F2 sites — audit after F2 |
| Docs Maker | SimpleDocumentWdgt | — | 0 / 1 408 | small ghost (same audit) |
| Generic panel | StretchableEditableWdgt | — | 0 / 133 | trace (empty content) |
| Slides Maker | SimpleSlideWdgt | — | 0 / 61 | trace (empty content) |
| Dashboards / Patch progr. / Draw / Super Toolbar / How to save | various | — | 0 / 0 | clean |
| Spreadsheet / Fizzytiles | SpreadsheetWdgt / FridgeMagnetsWdgt | — | (no edit button) | n/a |

Class audit for future [INV-2] instances (`_reLayout` overriders with NO `_applyExtent`
self-override; risky only if resized raw as window content / holder icon):
`SimpleDocumentWdgt`, `ErrorsLogViewerWdgt`, `ConsoleWdgt`, `ColorPickerWdgt`,
`CodePromptWdgt`, `ScriptWdgt`, `SpeechBubbleWdgt`, `SimpleLinkWdgt`, patch-node
widgets, video-player family. Already self-protecting: `StretchablePanelWdgt`,
`SimpleVerticalStackPanelWdgt`, `StretchableCanvasWdgt`,
`StretchableWidgetContainerWdgt`, `ScrollPanelWdgt`.

---

## 5. Verification & new tests

### 5.1 Per-phase acceptance — the Appendix B probes ARE the acceptance tests

Baselines (pre-fix, master `6f6c834e`) vs targets:

| Probe | Metric | Broken (now) | Target (fixed) |
|---|---|---|---|
| B.1 | `icons.bad` (of `n`=2) | 2 | **0** |
| B.1 | `slidePlotRatio` / `dashPlotRatio` | 0.089 / 0.072 | **≥ 0.5** (baseline 0.70) |
| B.2 | ghost px →edit / →view | 97 021 / 85 351 | **0 / 0** |
| B.3 | `nycPinRel` | [−11, 23] | **[89, 23]** |
| B.4 | per-app table | §4 | all ghost cells 0 (or explained) |

### 5.2 New macro SystemTests (Phase 5; author in `Fizzygum-tests` via the `/author-macro-test` skill)

Three short macros close the coverage hole (screenshot-diff does the asserting):

- **`SystemTest_macroDesktopShortcutIconsAndExamplesFolder`** — boot → screenshot the
  desktop (D1: examples + Basement icons) → click the examples folder shortcut →
  screenshot the opened folder window (D1: the four launcher icons).
- **`SystemTest_macroSampleDashboardPlots`** — open the examples folder → launch Sample
  dashboard from its launcher → settle → screenshot (D3 ×3 plots + 3D plot).
- **`SystemTest_macroSampleSlideEditViewToggle`** — launch Sample slide → screenshot
  (D4: pin/traffic/map correct in view mode) → click the title-bar edit button →
  screenshot (D2 + edit layout) → click again → screenshot; the third reference must be
  pixel-identical to the first (round-trip invariant).

Authoring rules that bit before: drive clicks through macro verbs that ASK the live
world where things are; NO backticks in macro comments (kills the test-`.js` syntax
gate); references are `?speed=`-invariant; capture references ONLY AFTER F1–F4 land,
via the full `scripts/capture-macro-test-references.js` flow (no `--no-build` shortcuts).
Read `Fizzygum/src/macros/CLAUDE.md` + `Fizzygum-tests/CLAUDE.md` before authoring.

### 5.3 Generic "paint truthfulness" gate (catches any future D2 anywhere)

Mechanical, reference-free, deterministic under SWCanvas: render, snapshot the canvas,
`world.fullChanged()`, render, assert zero pixel delta — any delta is a dropped
invalidation. Add to the Automator as an opt-in per-test capstone assertion (precedent:
the end-of-cycle flush-drawdown hard-fail gate), enable on the three new macros first,
then run suite-wide in AUDIT mode (count offenders, no fail) before deciding on a
suite-wide hard gate. Optional lint for [INV-1] (buildSystem/): flag any `_reLayout*`
body containing `disableTrackChanges` with no `fullChanged` after its LAST
`maybeEnableTrackChanges`.

### 5.4 Reference-recapture protocol

F2 changes repaint behavior, so existing references may contain BAKED ghost pixels (any
test that toggles editing or opens these panels); F1 changes desktop-icon pixels in any
test whose screenshots include the desktop. After each phase: `./fg suite`; for each
failing test EYEBALL the diff — the new pixels must be *more* correct (ghost-free, icon
contained); then recapture via the full capture flow. Never contort the fix to preserve
a wrong reference. A failure OUTSIDE the expected blast radius (icons/desktop/sample
apps/edit toggles) means the fix leaked — STOP and re-scope.

---

## 6. Execution order (each phase ends green before the next)

- **Phase 0 — baseline freeze.** `./fg build` (or `cd Fizzygum && ./build_it_please.sh`),
  then run B.1–B.4 against the fresh build and save their JSON outputs (scratchpad is
  fine); they must match §5.1's "broken" column. If they don't, the tree has drifted
  since `6f6c834e` — re-verify §1 before proceeding.
- **Phase 1 — F2** (5 one-line insertions) → B.2 = 0/0, B.4 big ghosts collapse →
  `./build_and_test.sh` → §5.4 recaptures if any.
- **Phase 2 — F1** (2 `_applyExtent` overrides) → B.1 `icons.bad = 0`, visual desktop +
  opened folder + object-shortcut resize → suite.
- **Phase 3 — F3** (1 override + axes conversion) → B.1 ratios ≥ 0.5, visual dashboard
  + slide traffic window + resize-by-handle → suite.
- **Phase 4 — F4** (scrollTo reorder) → B.3 = [89, 23], visual slide view mode → suite.
- **Phase 5 — tests + gates.** Author the three macros (§5.2), capture references, add
  the paint-truthfulness capstone (§5.3) on them; `./fg gauntlet`; audit-mode
  truthfulness sweep (record offender count; file follow-up if > 0); re-run B.4 and
  chase the residual small ghosts (Sample doc / Docs Maker, §4).
- **End of arc:** one review pass over the whole diff; present commit plan to the owner
  (do NOT commit autonomously). Sizes: Phases 1–4 ≈ a handful of lines in ≤ 8 files;
  Phase 5 is the bulk.

---

## 7. Provenance appendix (bisect method + measurement table)

Method: a git worktree of `Fizzygum` checked out per bisect step inside an ISOLATED
umbrella (its own `Fizzygum-builds/`; `Fizzygum-tests` symlinked) so the real
`Fizzygum-builds/latest` is never touched — rebuilding the real one from an old commit
breaks the owner's running copy (it happened mid-investigation; a full rebuild from
master restored it). Per commit: `./build_it_please.sh --notests` **with cwd = the
worktree** (pre-06-19 build scripts have NO self-cd — from the wrong cwd they silently
build the wrong repo), `latest/` fully DELETED first (the build does not clean
stale files; mixed-era leftovers boot the WRONG code with plausible-looking results),
Mousetrap compiled in manually (old `--notests` builds skip it; the oracle also stubs
`window.Mousetrap` pre-boot). Predicates ran off cached per-sha JSON via `git bisect run`.

| Date | Commit | icons.bad | slideRatio | dashRatio | ghostPx | Note |
|---|---|---|---|---|---|---|
| 06-01 | `f494e66c` | 0 | 0.700 | 0.696 | 0 | GOOD baseline (pinRel 89,23) |
| 06-14→18 | `db6bd263`…`fbbefb7c` | 0 | 0.700 | 0.696 | 0 | still clean |
| 06-19 | **`817c2ce4`** | 0 | 0.700 | 0.696 | **13 008** | ghost born (setExtent→rawSetExtent ×5 reLayouts) |
| 06-19 | **`b8165920`** | **1** | 0.700 | 0.696 | 13 008 | Basement icon breaks (add/addRaw self-settling; `BasementOpenerWdgt.iHaveBeenAddedTo`→`fullRawMoveTo`) |
| 06-20 | `f3c2f044` | 1 | 0.700 | **0.441** | 13 001 | intermediate dashboard-plot degradation (not separately bisected; superseded) |
| 06-21→30 | `947ba025`…`d2c90cc3` | 1 | 0.700 | 1* | 0* | *era artifacts — toggle produced no pixel change; not investigated (superseded) |
| 06-30 | **`ce21dcf7`** | 1 | **0.089** | 55.4* | 0* | plots collapse + **pinRel → (−11,23)** (orphan-settledness Phase 1+2) |
| 06-30 | **`527f6186`** | **2** | 0.089 | 55.4* | 0* | examples-folder + launcher icons break (ctors build+settle via NoSettle core) |
| 06-29→07-02 | (`f321394c`→) | 2 | 0.089 | 55.4* | 0* | "thin-slice" era: `super  # comment` meta-compiler bug made app content ~5px wide, masking the ghost metric |
| 07-02 | `cbb90457` | 2 | 0.089 | 0.072 | **1 251** | super-rewriter fix heals thin-slice, UNMASKS the ghost |
| 07-04→06 | `040330e6`…`6f6c834e` | 2 | 0.089 | 0.072 | 1 251 | current state (HEAD at time of writing) |

Honesty notes: (a) the 06-21→06-29 ghost-0 window was not root-caused (interim heal or
no-op toggle — the mid-era world was structurally odd, see `dashRatio` 1/55.4); the D2
mechanism + fix are proven directly against HEAD, so this doesn't affect the plan.
(b) the 06-20 `0.441` intermediate was not separately bisected. (c) the full-range ghost
bisect first returned `cbb90457` (the unmasking commit); the sub-range bisect
`f494e66c..b9164004` pinned the true introduction `817c2ce4`.

---

## Appendix B — the measurement probes (complete, runnable)

Run each as
`NODE_PATH=/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/node_modules node <file>.js`
after a fresh full build. They read the build only — safe against the live repo. If
Puppeteer is missing: `cd Fizzygum-tests && npm i`.

⚠ Two hard-won gotchas baked into these scripts: (1) `page.waitForFunction` CRASHES
against Fizzygum pages (`Cannot read properties of undefined (reading
'onceAddedClassProperties')` — the page patches globals puppeteer's utility world
relies on); poll INSIDE `page.evaluate` instead. (2) settle waits are wall-clock
generous (the world lays out across rAF cycles); don't shrink them below ~2 s.

### B.1 — `oracle.js`: icons containment + plot ratios (+ ghost + dash, all-in-one)

```js
#!/usr/bin/env node
'use strict';
// Prints ONE line: ORACLE_JSON {"boot":true,"icons":{"n":N,"bad":B},"slidePlotRatio":R,
//                               "toggleDiffPx":D,"ghostPx":G,"dashPlotRatio":R2,"errors":[...]}
// icons.bad: shortcut-arrow composites whose children overflow them (target 0)
// *PlotRatio: first PlotWithAxes child area / own area (target >= 0.5)
// ghostPx: pixels that CHANGE when a forced world.fullChanged() repaint follows the
//          edit->view round-trip (target 0; any nonzero = dropped invalidation)
const puppeteer = require('puppeteer');
const INDEX = '/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-builds/latest/index.html';

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--allow-file-access-from-files', '--no-sandbox'] });
  const out = { boot: false, errors: [] };
  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1100, height: 800, deviceScaleFactor: 1 });
    page.on('pageerror', e => out.errors.push('pageerror: ' + String(e.message).slice(0, 150)));
    await page.goto('file://' + INDEX, { waitUntil: 'load', timeout: 45000 });
    out.boot = await page.evaluate(() => new Promise((resolve) => {
      const t0 = Date.now();
      (function tick() {
        const w = window.world;
        if (w && w.worldRenderCanvas && w.worldCanvasContext) resolve(true);
        else if (Date.now() - t0 > 40000) resolve(false);
        else setTimeout(tick, 100);
      })();
    }));
    if (!out.boot) throw new Error('world did not boot');
    await new Promise(r => setTimeout(r, 3500));

    await page.evaluate(() => {
      window.__walk = function walk(w, fn) { fn(w); (w.children || []).forEach(c => walk(c, fn)); };
      window.__ext = w => ({ l: w.bounds.origin.x, t: w.bounds.origin.y,
        w: w.bounds.corner.x - w.bounds.origin.x, h: w.bounds.corner.y - w.bounds.origin.y });
    });

    out.icons = await page.evaluate(() => {
      let n = 0, bad = 0;
      window.__walk(window.world, (w) => {
        if (!(w.children || []).some(c => /ShortcutArrow/.test(c.constructor.name))) return;
        n++;
        const p = window.__ext(w); const slack = 3; let v = false;
        (w.children || []).forEach((c) => {
          const e = window.__ext(c);
          if (e.l < p.l - slack || e.t < p.t - slack ||
              e.l + e.w > p.l + p.w + slack || e.t + e.h > p.t + p.h + slack) v = true;
        });
        if (v) bad++;
      });
      return { n, bad };
    });

    await page.evaluate(() => { new window.SampleSlideApp().launch(); });
    await new Promise(r => setTimeout(r, 3000));
    const plotRatio = (slot) => page.evaluate((s) => {
      const wm = window.world[s];
      if (!wm) return null;
      let p = null;
      window.__walk(wm, (w) => { if (!p && /PlotWithAxes/.test(w.constructor.name)) p = w; });
      if (!p || !p.children || !p.children.length) return null;
      const P = window.__ext(p), C = window.__ext(p.children[0]);
      return (C.w * C.h) / (P.w * P.h);
    }, slot);
    out.slidePlotRatio = await plotRatio('sampleSlideWindow');

    const clip = await page.evaluate(() => {
      const wm = window.world.sampleSlideWindow;
      const e = window.__ext(wm);
      return { x: Math.max(0, e.l - 10), y: Math.max(0, e.t - 10), w: e.w + 40, h: e.h + 40 };
    });
    const snap = () => page.evaluate((c) => {
      const cv = window.world.worldCanvas;
      const d = cv.getContext('2d').getImageData(c.x, c.y,
        Math.min(c.w, cv.width - c.x), Math.min(c.h, cv.height - c.y)).data;
      window.__snapPrev = window.__snapCur || null;
      window.__snapCur = d;
    }, clip);
    const countDiff = () => page.evaluate(() => {
      const a = window.__snapPrev, b = window.__snapCur;
      if (!a || !b || a.length !== b.length) return -1;
      let n = 0;
      for (let i = 0; i < a.length; i += 4)
        if (a[i] !== b[i] || a[i + 1] !== b[i + 1] || a[i + 2] !== b[i + 2]) n++;
      return n;
    });
    const toggle = () => page.evaluate(() => { window.world.sampleSlideWindow.editButtonInBarPressed(); });
    await snap();
    await toggle(); await new Promise(r => setTimeout(r, 2500));
    await toggle(); await new Promise(r => setTimeout(r, 2500));
    await snap();
    out.toggleDiffPx = await countDiff();           // round-trip drift (info only)
    await page.evaluate(() => { window.world.fullChanged(); });
    await new Promise(r => setTimeout(r, 1200));
    await snap();
    out.ghostPx = await countDiff();                // THE D2 metric

    await page.evaluate(() => { new window.SampleDashboardApp().launch(); });
    await new Promise(r => setTimeout(r, 3000));
    out.dashPlotRatio = await plotRatio('sampleDashboardWindow');
  } catch (e) {
    out.errors.push('fatal: ' + String(e.message).slice(0, 200));
  } finally {
    await browser.close();
  }
  console.log('ORACLE_JSON ' + JSON.stringify(out));
})();
```

### B.2 — `probe-ghost-fix.js`: the D2 fix proof (per-toggle ghost, with `--patch`)

```js
#!/usr/bin/env node
'use strict';
// Usage: node probe-ghost-fix.js [--patch]
// Measures ghost px after EACH toggle (not just the round trip). --patch monkey-patches
// the F2 fix shape at runtime (trailing fullChanged on _reLayoutSelf) WITHOUT rebuilding.
// Measured on master 6f6c834e: unpatched {97021, 85351} -> patched {0, 0}.
const puppeteer = require('puppeteer');
const INDEX = '/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-builds/latest/index.html';
const PATCH = process.argv.includes('--patch');

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--allow-file-access-from-files', '--no-sandbox'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 1100, height: 800, deviceScaleFactor: 1 });
  await page.goto('file://' + INDEX, { waitUntil: 'load', timeout: 45000 });
  await page.evaluate(() => new Promise((res) => {
    const t0 = Date.now();
    (function tick() {
      const w = window.world;
      if ((w && w.worldRenderCanvas && w.worldCanvasContext) || Date.now() - t0 > 40000) res();
      else setTimeout(tick, 100);
    })();
  }));
  await new Promise(r => setTimeout(r, 3000));

  if (PATCH) {
    await page.evaluate(() => {
      for (const K of [window.StretchableEditableWdgt, window.SimpleSlideWdgt]) {
        if (!K) continue;
        const orig = K.prototype._reLayoutSelf;
        K.prototype._reLayoutSelf = function () { orig.call(this); this.fullChanged(); };
      }
    });
  }

  await page.evaluate(() => { new window.SampleSlideApp().launch(); });
  await new Promise(r => setTimeout(r, 3000));

  const snap = (nm) => page.evaluate((n) => {
    const wm = window.world.sampleSlideWindow; const cv = window.world.worldCanvas;
    const x = Math.max(0, wm.bounds.origin.x - 10), y = Math.max(0, wm.bounds.origin.y - 10);
    const w = Math.min(wm.bounds.corner.x - wm.bounds.origin.x + 40, cv.width - x);
    const h = Math.min(wm.bounds.corner.y - wm.bounds.origin.y + 40, cv.height - y);
    window['__' + n] = cv.getContext('2d').getImageData(x, y, w, h).data;
  }, nm);
  const diff = (a, b) => page.evaluate((an, bn) => {
    const A = window['__' + an], B = window['__' + bn];
    if (!A || !B || A.length !== B.length) return -1;
    let n = 0;
    for (let i = 0; i < A.length; i += 4)
      if (A[i] !== B[i] || A[i + 1] !== B[i + 1] || A[i + 2] !== B[i + 2]) n++;
    return n;
  }, a, b);
  const toggle = () => page.evaluate(() => { window.world.sampleSlideWindow.editButtonInBarPressed(); });

  await toggle(); await new Promise(r => setTimeout(r, 2500));
  await snap('edit');
  await page.evaluate(() => { window.world.fullChanged(); }); await new Promise(r => setTimeout(r, 1200));
  await snap('editClean');
  const ghostEdit = await diff('edit', 'editClean');

  await toggle(); await new Promise(r => setTimeout(r, 2500));
  await snap('view2');
  await page.evaluate(() => { window.world.fullChanged(); }); await new Promise(r => setTimeout(r, 1200));
  await snap('view2Clean');
  const ghostView = await diff('view2', 'view2Clean');

  console.log(JSON.stringify({ patched: PATCH, ghostEdit, ghostView }));
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
```

### B.3 — `pin-oracle.js`: the D4 scroll-drift metric

```js
#!/usr/bin/env node
'use strict';
// Prints {"nycPinRel":[x,y]}: map-pin origin relative to its clipping scroll frame in
// the freshly-opened Sample slide. Good: [89,23]. Broken (D4): [-11,23].
const puppeteer = require('puppeteer');
const INDEX = '/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-builds/latest/index.html';

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--allow-file-access-from-files', '--no-sandbox'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 1100, height: 800, deviceScaleFactor: 1 });
  await page.goto('file://' + INDEX, { waitUntil: 'load', timeout: 45000 });
  await page.evaluate(() => new Promise((res) => {
    const t0 = Date.now();
    (function tick() {
      const w = window.world;
      if ((w && w.worldRenderCanvas && w.worldCanvasContext) || Date.now() - t0 > 40000) res();
      else setTimeout(tick, 100);
    })();
  }));
  await new Promise(r => setTimeout(r, 3000));
  await page.evaluate(() => { new window.SampleSlideApp().launch(); });
  await new Promise(r => setTimeout(r, 3000));
  const rel = await page.evaluate(() => {
    const wm = window.world.sampleSlideWindow;
    let pin = null;
    (function walk(w) {
      if (!pin && /MapPin/.test(w.constructor.name)) pin = w;
      else (w.children || []).forEach(walk);
    })(wm);
    if (!pin) return null;
    let fr = pin.parent;
    while (fr && !/ScrollPanel|ScrollFrame/.test(fr.constructor.name)) fr = fr.parent;
    if (!fr) return null;
    return [Math.round(pin.bounds.origin.x - fr.bounds.origin.x),
            Math.round(pin.bounds.origin.y - fr.bounds.origin.y)];
  });
  console.log(JSON.stringify({ nycPinRel: rel }));
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
```

### B.4 — `apps-sweep.js`: the §4 per-app table

```js
#!/usr/bin/env node
'use strict';
// For each desktop app, on a FRESH page: launch, scan its window for collapsed
// composites, and (if it has an edit button) measure ghost px after each of two
// toggles via the forced-full-repaint discriminator. Emits one JSON line per app.
const puppeteer = require('puppeteer');
const INDEX = '/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-builds/latest/index.html';
const APPS = ['SampleSlideApp', 'SampleDashboardApp', 'SampleDocApp', 'SpreadsheetApp',
  'DegreesConverterApp', 'SimpleSlideApp', 'SimpleDocumentApp', 'DashboardsApp',
  'GenericPanelApp', 'PatchProgrammingApp', 'FizzyPaintApp', 'ToolbarsApp',
  'FridgeMagnetsApp', 'HowToSaveMessageApp'];

(async () => {
  const browser = await puppeteer.launch({ headless: 'new', args: ['--allow-file-access-from-files', '--no-sandbox'] });
  for (const app of APPS) {
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 900, deviceScaleFactor: 1 });
    let result;
    try {
      await page.goto('file://' + INDEX, { waitUntil: 'load', timeout: 45000 });
      await page.evaluate(() => new Promise((res) => {
        const t0 = Date.now();
        (function tick() {
          const w = window.world;
          if ((w && w.worldRenderCanvas && w.worldCanvasContext) || Date.now() - t0 > 40000) res();
          else setTimeout(tick, 100);
        })();
      }));
      await new Promise(r => setTimeout(r, 3000));
      const info = await page.evaluate((appName) => {
        const K = window[appName];
        if (!K) return { skip: 'no such class' };
        const before = new Set(window.world.children);
        try { new K().launch(); } catch (e) { return { skip: 'launch: ' + String(e.message).slice(0, 100) }; }
        const added = window.world.children.filter(c => !before.has(c));
        const wm = added.find(c => c.constructor.name === 'WindowWdgt') || added[0];
        if (!wm) return { skip: 'no window appeared' };
        window.__wm = wm;
        return { contents: wm.contents ? wm.contents.constructor.name : null };
      }, app);
      if (info.skip) { result = info; }
      else {
        await new Promise(r => setTimeout(r, 2500));
        const collapse = await page.evaluate(() => {
          const findings = [];
          const COMPOSITES = /PlotWithAxes|GenericShortcutIcon|GenericObjectIcon|AxisWdgt/;
          (function walk(w) {
            if (COMPOSITES.test(w.constructor.name) && w.children && w.children.length) {
              const pa = (w.bounds.corner.x - w.bounds.origin.x) * (w.bounds.corner.y - w.bounds.origin.y);
              let cov = 0;
              w.children.forEach(c => {
                cov = Math.max(cov, (c.bounds.corner.x - c.bounds.origin.x) * (c.bounds.corner.y - c.bounds.origin.y));
              });
              if (pa > 400 && cov / pa < 0.3) findings.push(w.constructor.name + ' ratio=' + (cov / pa).toFixed(3));
            }
            (w.children || []).forEach(walk);
          })(window.__wm);
          return findings;
        });
        const hasEdit = await page.evaluate(() =>
          !!(window.__wm.editButton && window.__wm.contents && window.__wm.contents.editButtonPressedFromWindowBar));
        let ghosts = null;
        if (hasEdit) {
          const snap = (nm) => page.evaluate((n) => {
            const wm = window.__wm; const cv = window.world.worldCanvas;
            const x = Math.max(0, wm.bounds.origin.x - 10), y = Math.max(0, wm.bounds.origin.y - 10);
            const w = Math.min(wm.bounds.corner.x - wm.bounds.origin.x + 40, cv.width - x);
            const h = Math.min(wm.bounds.corner.y - wm.bounds.origin.y + 40, cv.height - y);
            window['__s' + n] = cv.getContext('2d').getImageData(x, y, w, h).data;
          }, nm);
          const dif = (a, b) => page.evaluate((an, bn) => {
            const A = window['__s' + an], B = window['__s' + bn];
            if (!A || !B || A.length !== B.length) return -1;
            let n = 0;
            for (let i = 0; i < A.length; i += 4)
              if (A[i] !== B[i] || A[i + 1] !== B[i + 1] || A[i + 2] !== B[i + 2]) n++;
            return n;
          }, a, b);
          const toggle = () => page.evaluate(() => { window.__wm.editButtonInBarPressed(); });
          ghosts = {};
          await toggle(); await new Promise(r => setTimeout(r, 2000));
          await snap('t1');
          await page.evaluate(() => window.world.fullChanged()); await new Promise(r => setTimeout(r, 1000));
          await snap('t1c');
          ghosts.afterToggle1 = await dif('t1', 't1c');
          await toggle(); await new Promise(r => setTimeout(r, 2000));
          await snap('t2');
          await page.evaluate(() => window.world.fullChanged()); await new Promise(r => setTimeout(r, 1000));
          await snap('t2c');
          ghosts.afterToggle2 = await dif('t2', 't2c');
        }
        result = { ...info, collapse, hasEdit, ghosts };
      }
    } catch (e) {
      result = { skip: 'fatal: ' + String(e.message).slice(0, 120) };
    }
    await page.close();
    console.log(app + ': ' + JSON.stringify(result));
  }
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
```

---

## 8. Follow-ups (Phases 1–4 landed; these remain — each written to be executed COLD)

Discovered while executing Phases 1–4 (2026-07-07). **8-A turned out to be mostly a non-issue —
the plot "latency" is intended animation (proven), so Phase 5 (8-C) is NOT blocked on a rendering
fix; it only needs a one-line freeze fixture.** Remaining REAL work: 8-B (F4 robust scroll) and 8-C
(Phase 5); 8-A leaves only an optional minor FizzyPaint fix. The Appendix-B probes plus the extra
probes named below were saved in the session scratchpad during execution; they are short and
re-createable from the descriptions here.

### 8-A. Content "ghost" on the plots — RESOLVED: it is intended ANIMATION, not a bug (do FIRST — reframes Phase 5)

**CORRECTION (2026-07-07, investigated post-commit).** The plot "content-latency" I first flagged
is NOT a paint bug — it is the **example plots' intended live animation.** ExampleBarPlotWdgt
(@fps 0.5), ExampleScatterPlotWdgt (@fps 1) and ExampleFunctionPlotWdgt (@fps 2) each do
`world.steppingWdgts.add @` in their ctor and `step: -> @graphNumber++; @changed()`, and their
`renderingHelper` seeds off `@graphNumber` (`@seed = @graphNumber`) — so every ~0.5–2 s the bars/
points re-randomize (the demo jiggles). The forced-`world.fullChanged()` discriminator simply
caught the animation between frames. PROOF: `plot-idempotence.js` → launch-paint == 1st forced
repaint (`launchVsForced1 = 0`, i.e. the launch render is TRUTHFUL), then a diff appears exactly
one step-interval later; `plot-freeze-test.js` → after `world.steppingWdgts.delete(plot)` the plot
region is fully idempotent (`f1f2 = 0, f2f3 = 0`). **So there is NOTHING to fix for the plots** —
F3 renders them correctly; they animate by design. (The slide-toggle-region result stands: F2's D2
container-move fix is 100 % clean — `windowMinusPlot = 0` — the residual was all animation.)

**Consequence for Phase 5 (see 8-C):** an animated widget cannot have a deterministic reference
screenshot. The two plot macros must FREEZE the plots before each shot — `world.steppingWdgts.delete`
each plot (or pin `graphNumber`) — which ALSO makes them pass the §5.3 paint-truthfulness capstone.
That is the whole "blocker": a one-line fixture step, not a rendering fix. (Confirm whether the
Automator already neutralises `steppingWdgts` under replay; if it does, even that step is unneeded.)

**The ONLY real remaining content-lag — FizzyPaint (optional; non-target app).** ReconfigurablePaintWdgt
does NOT animate (no steppingWdgts), yet its 2nd edit→view toggle leaves a deterministic **1670 px**
stale region (`probe-fizzypaint.js`: idempotent at rest, `ghostToggle2 = 1670`). The toggle removes
the tools panel + widens `@stretchableWidgetContainer` (which holds the paint CANVAS), and the
covering `@fullChanged()` repaints before the canvas bitmap re-rasterizes at the new size. Small,
FizzyPaint is not a D1–D4 target. If worth fixing: look at `StretchableCanvasWdgt`'s resize/bitmap
path — have it issue its own covering repaint after it re-rasterizes at the new extent (INV-1 shape),
or make the re-raster synchronous with the resize. Acceptance: `probe-fizzypaint.js` `ghostToggle2 → 0`;
suite + gauntlet green. **This is the only piece of the original "content re-raster" follow-up that is
a real bug; the plot piece is void.**

### 8-B. F4 robust, constant-free scroll-preservation (the plan's already-named "OPTIONAL follow-on")

**Why:** F4 shipped a measurement-derived magic constant `scrollTo(1364,157)` in
`src/apps/SampleSlideApp.coffee` because `ScrollPanelWdgt.scrollTo` is ABSOLUTE
(`@contents._moveLeftSideTo -whereTo.x` / `_moveTopSideTo -whereTo.y`,
`src/basic-widgets/ScrollPanelWdgt.coffee:505-509`) — the required value is tied to the panel's
final world position, so it re-breaks if the slide's layout shifts. (Re-issuing the natural
edit-mode `(1484,246)` post-flip lands the pin at `[-31,-66]`; the sweep map is
`pinRel = (1453 - whereTo.x, 180 - whereTo.y)`.)

**DONE 2026-07-07 (uncommitted, awaiting owner approval).** Chosen fix — SIMPLER + lower-risk than
the general resize-preservation, because a source-wide grep found **`scrollTo` has exactly ONE caller
(`SampleSlideApp`)** and none in the tests/harness: make **`ScrollPanelWdgt.scrollTo` FRAME-RELATIVE**
(`@contents._moveLeftSideTo @left() - whereTo.x` / `@top() - whereTo.y`) instead of absolute `-whereTo`.
Now `scrollTo(whereTo)` means "content-point `whereTo` at MY top-left" independent of my world
position. Then `SampleSlideApp` scrolls with an **intent-based, constant-free** value:
`pinOffset = mapPin.position() - windowWithScrollingPanel.contents.contents.position();
scrollTo(pinOffset - Point(89,23))` — i.e. "put the pin at viewport (89,23)", which lands there BY
CONSTRUCTION (`pinRel.x = pinOffset.x - (pinOffset.x - 89) = 89`) regardless of frame position/size.
Verified: B.3 `[89,23]`; runtime frame-independence test — moving the whole slide window +200,+150
(frameLeft 153→353) keeps the pin at `[89,23]`; B.1 unchanged; visual identical; gauntlet green.

**NOT done (deliberately — out of scope + higher risk):** the BROADER "any scrolled panel keeps its
viewport when its window is later resized" behavior. That needs the resize/clamp path
(`_positionAndResizeChildren`, used by every folder/text/tool panel) to remember + re-apply the
content-relative anchor — a much larger blast radius, and the slide doesn't need it (it scrolls LAST,
after the flip). If wanted later: remember `(@left()-@contents.left(), @top()-@contents.top())` before
the resize and re-apply (clamped) after, in the resize path; acceptance = the general §3-F4 probe
(scroll a panel, drag-resize its window, top-left content point stays put).

### 8-C. Phase 5 — tests + gates (verbatim §5.2 / §5.3 / §5.4 + §6-Phase-5), with two found obstacles

Do this AFTER 8-A (so the plots paint truthfully). Everything in §5.2/§5.3/§5.4 stands; two additions:
1. **Harness world has no desktop shortcut icons.** After `ResetWorld` the SystemTest world does NOT
   render the desktop icons (that is precisely why F1 needed ZERO reference recaptures). So
   `SystemTest_macroDesktopShortcutIconsAndExamplesFolder` must BUILD the desktop/icons as a macro
   fixture — investigate how `index.html` populates the desktop (likely a `MenusHelper` / `WorldWdgt`
   setup path) and reproduce it, or drop this macro's desktop shot and keep only the opened-folder shot
   built from a fixture. The examples-folder open path is `IconicDesktopSystemFolderShortcutWdgt.mouseClickLeft`
   (single click; `src/IconicDesktopSystemFolderShortcutWdgt.coffee:18`).
2. **The two PLOT macros render ANIMATED plots (see 8-A) → RESOLVED by a clock-pattern freeze
   (DONE 2026-07-07, uncommitted).** `macroSampleDashboardPlots` and `macroSampleSlideEditViewToggle`
   show the live-animated example plots. Rather than a per-macro fixture, the plots now render a FIXED
   frame under replay the SAME way AnalogClockWdgt does: `GraphsPlotsChartsWdgt` gained
   `_animationFrozenForDeterministicReplay()` (`Automator? and Automator.animationsPacingControl and
   Automator.state == Automator.PLAYING`) and a guarded `step()` (freezes @graphNumber under that
   condition; the 3 identical 2D-plot step()s were removed and inherit it); `Example3DPlotWdgt`
   (extends Widget directly, not the base) inlines the same guard in its own step() to freeze
   @currentAngle. The standard preamble's `AutomatorEventCommandTurnOnAnimationsPacingControl` flips
   the condition on, so the plot macros are deterministic + capstone-clean with NO fixture step.
   Verified: without pacing control the dashboard plots animate (8365 px/3 s); with it on they are
   idempotent (0 px). (Files: `src/graphs-plots-charts/{GraphsPlotsChartsWdgt,ExampleBarPlotWdgt,
   ExampleScatterPlotWdgt,ExampleFunctionPlotWdgt,Example3DPlotWdgt}.coffee`.)

Capture references (`scripts/capture-macro-test-references.js`, full flow) only after the plots are
frozen in those two macros (and after 8-A's optional FizzyPaint fix, if you choose to do it).
Model `macroSampleSlideEditViewToggle` on the existing `SystemTest_macroEditModeTogglePencilEyeGlyph`
(same click-editButton → screenshot shape). Read `src/macros/CLAUDE.md` +
`../Fizzygum-tests/CLAUDE.md` first; no backticks in macro comments (kills the test-.js syntax gate).

#### 8-C PROGRESS (2026-07-07) + what remains (cold-executable)

DONE + COMMITTED (unpushed; gauntlet green — 191/191 at dpr1+dpr2+WebKit, all gates):
- **Plot-determinism freeze** — Fizzygum commit **`97e4ea97`** (the automatic replacement for a
  per-macro freeze fixture; see 8-C point 2 above). In `Fizzygum/src/graphs-plots-charts/`. Verified
  (plots animate off pacing-control, idempotent on).
- **`SystemTest_macroSampleSlideEditViewToggle`** — Fizzygum-tests commit **`f7950d03d`** — references
  captured at dpr 1+2, passing (also dpr2 + WebKit in the gauntlet).
  Launches `new SampleSlideApp().launch()` (fixture) → image_0 (view: D3 plot full-size + D4 pin
  mid-map + D2 clean) → click `win.editButton` → image_1 (edit: tools panel, no ghost) → click again →
  image_2 (clean edit→view). ⚠ FINDING: the round-trip is NOT byte-identical — image_0 vs image_2 differ
  by exactly a **1px-wide column at x=443 (235px), the map's vertical scrollbar THUMB** (a re-layout
  rounding on the runtime toggle); ALL content (map/pin/plot/caption/chrome) is byte-identical, so the D2
  ghost fix is proven. So the planned `@assertScreenshotsIdentical image_0,image_2` was DROPPED (kept the
  3 shots as separate deterministic refs). (Optional tiny follow-up: chase the 1px scrollbar-thumb rounding
  so a runtime toggle is byte-exact — cosmetic.) ⚠ CAPTURE GOTCHA relived: `capture-macro-test-references.js`
  runs clean→CAPTURE→rebuild→verify, so the test must be BUILT IN before capturing — run `./fg build` (or
  build_it_please.sh) FIRST, then the capture script (a first-time capture without a prior build "did not
  select exactly one SystemTest").

DONE 2026-07-07 — ✅ COMMITTED + PUSHED to Fizzygum-tests `master`: **`195bf72ed`** (harness: capstone +
audit + slide-macro enable) and **`8afce20dc`** (the 2 new macro tests). Base `f7950d03d`. NO Fizzygum
(framework) commit — all harness-side. Full `./fg gauntlet` GREEN (dpr1 + dpr2 + WebKit 193/193 + apps +
tiernaming/settle/capstone gates). Each verified — suite 193/193 green, audit 193/193 clean:
- **`SystemTest_macroSampleDashboardPlots`** (D3) — `new SampleDashboardApp().launch()` (fixture) → settle
  → ONE screenshot (image_0). Eyeballed: scatter + function plots full-size WITH axes, bar plot top + 3D
  mesh below — no collapse. Refs captured dpr1+2; both PASS. ⚠ FINDING: the 596×592 dashboard window is
  taller than the fixed 960×440 harness viewport, so the shot is the UPPER portion (scatter+function fully
  visible = the strong D3 guard; bar/3D/USA-map clipped at the bottom edge). Metadata says so.
- **`SystemTest_macroDesktopShortcutIcons`** (D1) — chose a cleaner, self-contained shot over the plan's
  original name: `world.makeFolder "examples"` + 4 sample-app `createOpener()` launchers → ONE screenshot of
  five `GenericShortcutIconWdgt` icons (folder + slide/dashboard/doc/spreadsheet), each raw-resized to 75×75
  by its `WidgetHolderWithCaptionWdgt` launcher (the exact F1 path), each showing its arrow badge. Eyeballed:
  all 5 badges correct at bottom-left. Refs captured dpr1+2; both PASS. Deliberately NOT `world.createDesktop`
  (would bake in the owner's uncommitted FridgeMagnetsApp launcher); folder-open dropped (orthogonal to the
  icon-layout fix); the world grid is VERTICAL wrap-5 (`laysIconsHorizontallyInGrid:false`,
  `iconsLayingInGridWrapCount:5`), so the five stack in one left column. `GenericObjectIconWdgt` (F1's twin,
  fixed the same way) needs a document-shortcut fixture — noted as an optional future extra.
- **§5.3 paint-truthfulness capstone + suite-wide audit — BUILT + VALIDATED (all in Fizzygum-tests, no
  framework change).** `AutomatorPlayer` gained `liveCanvasFingerprintNow()` (the same SWCanvas raw-pixel
  SHA-256 / native data-URL `compareScreenshots` uses, reference-free), `checkPaintTruthfulness()` (snapshot →
  `world.fullChanged()` + `world.updateBroken()` [the real doOneCycle paint] → snapshot → `before==after`),
  `assertPaintTruthfulAfterFullRepaint()` (per-test HARD capstone via `recordMacroAssertion`), and a
  `runPaintTruthfulnessAuditForCurrentTest()` tick in `stopTestPlaying` gated on `window.FIZZYGUM_PAINT_AUDIT`
  (counts offenders, never fails). Enabled as a hard capstone on all 3 new macros (dashboard, desktop-icons,
  slide-toggle) — each PASSES (`before==after==` the shot's committed dataHash, e.g. dashboard `deadc460…`).
  New `scripts/run-paint-audit.js` presets the flag + runs the whole suite single-process: **AUDIT RESULT
  193/193 checked, 0 offenders** (a suite-wide hard gate would currently pass). CATCH-PROOF (page.evaluate,
  raw JS — the layering gate's rule **[D]** forbids raw-core calls in MACRO source, and the idle harness
  doesn't wire `world.automator.player`, so a live demo runs one real test first then corrupts): a dropped
  invalidation (`world.color` reassigned WITHOUT `changed()`) makes the capstone return `truthful:false`
  (`differ:true`) while a clean scene returns `true` — non-vacuous, both directions. (`_applyMoveTo` on a
  launcher did NOT ghost — its invalidation is more robust than the CLAUDE gotcha implies.) [INV-1] lint NOT
  added (deferred — the audit already shows 0 suite-wide offenders).
- ⚠ CAPSTONE-vs-LINT NOTE for cold re-runs: do NOT author a dropped-invalidation inside a macro to test the
  capstone — layering rule **[D]** ("macro calls private/low-level `._applyMoveTo()`") aborts the build even
  when the call is inside an `evaluateString` string. Prove the catch from `page.evaluate` after driving a
  real test (see `scratchpad/catch-proof4.js`).

#### 8-C DONE — the whole D1–D4 arc + Phase 5 (tests + capstone/audit) is LANDED + PUSHED. Gauntlet green.

#### 8-C FOLLOW-UPS (2026-07-08) — 4 of 6 DONE + COMMITTED; 2 DEFERRED with evidence.

Session on 2026-07-08 executed the 5 REMAINING items below (owner: "do all the optional follow-ups; if the
tests pass, just commit"). Outcome: the 3 SAFE/verifiable ones + the paint-gate landed; the 2 framework
"own-arc" fixes (§8-A, §8-B) could NOT be verified in a fresh session (their recorded symptoms did not
reproduce), so per evidence-first they were REVERTED and stay deferred. Commits (unpushed unless noted):

1. ✅ **Suite-wide HARD paint-truthfulness gate** — DONE. Fizzygum-tests commit **`b395b3d4c`**:
   `scripts/run-paint-audit.js` now exits non-zero on offenders>0 (the per-test audit tick still never fails
   a test — the SCRIPT is the gate). Wired as a `fg gauntlet` leg (`fg` is umbrella tooling, not committed).
   Audit currently 193/193 = 0 offenders, so the gate passes.
2. ✅ **[INV-1] build lint** — DONE. Fizzygum commit **`8331309a`**: `buildSystem/check-relayout-repaints.js`
   (mirrors check-relayout-bounds-first.js) + wired into `build_it_please.sh`. SCOPED TO `_reLayoutSelf`
   (the covering-repaint owner) after investigation: a `_reLayout*` scope flagged 3 `_reLayout` ORCHESTRATORS
   (BasementWdgt, ErrorsLogViewerWdgt, and the owner's untouchable experimental FridgeMagnetsWdgt) that all
   delegate their tail to `super` (base `Widget::_reLayout`, which issues no blanket `@fullChanged()`) — a
   structurally different shape from the D2 class, all audit-clean, and one un-editable. `_reLayoutSelf` scope
   = the exact proven D2 shape (5 F2 bodies + the HorizontalMenuPanelWdgt precedent), 0 violations, catch-proof
   both ways (neutralise a covering `@fullChanged()` → the lint flags that body). Runtime audit covers the rest.
3. ✅ **`GenericObjectIconWdgt` dedicated guard** — DONE. Fizzygum-tests commit **`5ab1dee16`**: new
   `SystemTest_macroSavedDocumentShortcutIcon`. Fixture is one line — `(new SimpleDocumentWdgt).createReference
   "saved doc", world` — which builds `IconicDesktopSystemDocumentShortcutWdgt` (icon omitted →
   `GenericShortcutIconWdgt(GenericObjectIconWdgt(target.representativeIcon()))`) and raw-`_applyExtent`s it to
   75×75 (Widget.createReference — the exact F1 path, on F1's twin). No file on disk needed ("saving" = a live
   in-memory reference). Refs dpr1+2; capstone-clean.
5. ✅ **`macroDesktopShortcutIcons` folder-open extension** — DONE. Fizzygum-tests commit **`8a3d8e520`**:
   image_1 opens the `examples` folder shortcut (`world.topWdgtSuchThat (w) -> w instanceof
   IconicDesktopSystemFolderShortcutWdgt` → `@moveToAndClick_InputEvents`), screenshots the opened
   FolderWindowWdgt (spawnNextTo-positioned, deterministic), + a 2nd capstone. image_0 stayed byte-identical.

4a. ⛔ **§8-A FizzyPaint 1670px canvas-resize ghost** — DEFERRED (fix identified + reverted). The fix is a
   1-liner in `StretchableCanvasWdgt.createRefreshOrGetBackBuffer` (line 47): re-allocate the front buffer when
   its physical size ≠ `extent.scaleBy ceilPixelRatio` (restore the base `CanvasWdgt` size-mismatch branch this
   override dropped) — mechanically a strict, harmless hardening (a wrong-size backBuffer is never intentional).
   BUT the recorded 1670px ghost DID NOT REPRODUCE in a fresh headless probe: `probe-fizzypaint.js` (open
   FizzyPaint, paint solid content, edit→view→edit→view, then diff the settled incremental canvas vs a forced
   correct re-raster) shows `ghostToggle2 = 0` BOTH pre- and post-fix, via 3 distinct approaches (direct
   `disableDragsDropsAndEditing`, the real `editButtonPressedFromWindowBar`, and cycle-pumped natural settle).
   The bug is NOT a dropped invalidation (the capstone/audit can't see it — a full repaint re-blits the same
   wrong-size buffer), it's a wrong-size-buffer; its trigger is settle-path-specific and I could not hit it.
   Per evidence-first + §8-A's own acceptance ("probe ghostToggle2 → 0" FROM a reproduced 1670), an
   unverifiable fix is not committed. FizzyPaint is a non-target app; NOTHING depends on this. NEXT SESSION to
   pick it up: reproduce the 1670 first (the original session did — likely needs the exact InfoWdgt geometry or
   the real input-event window-resize, not just the edit/view toggle), THEN apply the 1-liner and re-run.
   Probe saved at `<prior-session-scratchpad>/probe-fizzypaint.js`.
4b. ⛔ **§8-B broader ScrollPanel resize-preservation** — DEFERRED (implemented, verified NO-OP, reverted). A
   confined + guarded implementation was written (anchor capture/re-apply INSIDE `ScrollPanelWdgt._applyExtent`
   only — NOT the shared `_positionAndResizeChildren`, so wheel/drag/momentum/caret/scrollbar are untouched —
   gated to non-content-sizing panels that are actually scrolled, so unscrolled panels stay byte-identical). But
   `probe-scroll-preserve.js` (build a non-content-sizing ScrollPanel with 1400×1400 content, scroll to (500,400),
   resize, check the top-left content offset) shows the offset is ALREADY PRESERVED by the COMMITTED code
   (`preserved=true` both pre- and post-fix, shrink AND grow): `_positionAndResizeChildren` retains the contents'
   position and `keepContentsInScrollPanelWdgt` clamps only when the content edge actually crosses the viewport
   edge — so the research's "the anchor is discarded on resize" premise did not hold in a reproducible probe.
   The change made NO observable difference → committing it would add core-scroll-path code for unproven benefit,
   which evidence-first forbids; the prior author's deliberate deferral stands. If a real regression is ever
   found, the confined `_applyExtent` approach + `probe-scroll-preserve.js` are the starting point (both saved in
   the prior-session scratchpad). §3-F4 remains the acceptance.
