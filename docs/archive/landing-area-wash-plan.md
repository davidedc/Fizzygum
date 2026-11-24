# Landing areas are washes, things are rings — the dock preview and the highlight vocabulary

**Status: COMPLETE 2026-11-24.** Authored 2026-11-24 from the owner's direction of that day (a survey of every
highlight the system draws, three prototypes measured against the whole suite, rendered looks), ruled the same day
(L1–L3, every recommendation taken) and executed the same day in one commit pair; the ledger at the end records
the deviations. The living truth is `HighlighterWdgt`'s header, `docs/architecture/visual-design-system.md`
(§4's highlight rule, §5's Drag feedback and Hover wash rows) and `docs/architecture/toolbars.md` §2. Below, the
plan as it was executed.

**Mandate: transformation, not accommodation.** After this plan, which of its two forms a highlight takes is
decided in ONE place, by what the highlight MARKS, and the form-named entry point that let a producer pick a form
is gone. The dock preview is a wash because it marks a place where nothing stands yet, not because a producer
was told to wash it. No producer passes a colour or a form to the highlight channel.

**Size:** about +15 / −10 code lines (one style factory renamed by meaning, one added, one theme role, one call
site), a test renamed, three tests' pictures recaptured (§7, the predicted set), five docs reworded.

---

## §0 Orientation

### What this workspace is (one hop each)

Fizzygum is a CoffeeScript GUI framework drawn on one `<canvas>`. Three sibling repos under
`/Users/davidedellacasa/code/Fizzygum-all/`: `Fizzygum/` (source; the only place behaviour is edited),
`Fizzygum-tests/` (the SystemTest suite and its references), `Fizzygum-builds/` (generated; never edited).
Read `Fizzygum-all/CLAUDE.md`, `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` before the first command.
Every build and test command goes through the wrapper, by ABSOLUTE path:
`/Users/davidedellacasa/code/Fizzygum-all/fg <cmd>` (bare `fg` prints the roster).

### The owner's direction (2026-11-24, verbatim)

> I noticed that the prospective / anticipated landing area for a drop into a dock is shown as a border [...]
> I think a border looks like a selection _of something_ - I think would work best in terms of prospective /
> anticipated landing areas is a filled semitransparent highlight. While borders work better as selection /
> highlight of something that exists already.
> Survey how the new direction I layed out above would apply beyond this drop-into-dock case, and plan a
> solution that fits the clean and orthogonal architecture of Fizzygum.

The picture the owner sent: a Docs Maker with a toolbar window carried over its left dock offer; the band the
release would make is shown as a 2 px accent ring over the page, which reads as "this strip of the page is
selected".

### The critical reframe

The rule is about what a highlight MARKS, and the system already has exactly two forms for it:

- a **ring** marks a THING that is there to see and plays a part in the gesture: the receiver a release
  reaches, a receiver that declines, the window a grip resizes, the selected widget;
- a **wash** marks a PLACE where nothing stands yet: where a release would put what the hand carries.

`HighlighterWdgt` draws both (its outline form and its fill form), but its producers choose the FORM: the dock
preview asks for `candidateOutlineStyle()` because the drag-embed spec gave it "the same candidate-accent outline
style as the row above", for uniformity; and the menu-row hover asks for `fillStyle(colour)`, a form with a
colour. So the fix is not "make the dock band blue-filled"; it is to name each style by its MEANING, let the
meaning decide the form, and point the dock preview at the meaning it has: a landing area.

### What the survey found (§2 has the table)

Of the eleven highlight looks the system draws, exactly ONE marks a place where nothing stands: the dock
preview. It is the only one the rule changes. Every ring already marks a thing. One look is the mirror case —
a wash on a thing, the hover highlight of the widget a menu row names — and the prototype of a ring there
collides with the selection ring (§6, L2): that one is the owner's call, and the recommendation is to keep it.

---

## §1 The mandate, restated as checks

After execution:

1. `HighlighterWdgt`'s header states the rule (ring = a thing, wash = a place), and its class methods are the
   only style factories, each named by what it marks; `HighlighterWdgt.fillStyle` (form-named, colour-taking)
   no longer exists: `grep -rn "HighlighterWdgt.fillStyle\|@fillStyle:" Fizzygum/src` answers nothing.
2. The dock preview's highlighter is built with `HighlighterWdgt.landingAreaStyle()` and wears
   `HighlightWashAppearance`; a new assertion in the renamed dock test says so, and a plant restoring the ring
   makes exactly that assertion fail.
3. Every live doc that describes the dock preview says "wash", none says "outline" for it (archived docs keep
   their words: they are records).
4. `fg gauntlet` 20/20, `fg homepage` OK; the recaptured pictures are the predicted set and no other.

---

## §2 The survey: every highlight the system draws

A HIGHLIGHT here is a look laid over or around a widget by something other than the widget's own state paint.
Found by reading every producer of the world's highlight channel (`world.widgetsToBeHighlighted.set`), every
`HighlighterWdgt` the world builds, the paint-time selection overlays, and the drag-embed affordances
(`ActivePointerWdgt._declareDragEmbedEphemerals`, `WorldWdgt.addDragAffordanceWidgets`).

| # | Look | What it marks | Today | Rule | Verdict |
|---|------|---------------|-------|------|---------|
| 1 | Dock preview (`WorldWdgt.addDragAffordanceWidgets`, box from `FrameWdgt.bandBoxIfDocked`) | the band a release would MAKE: nothing stands there | 2 px accent ring | wash | **change** (the owner's case) |
| 2 | Drop candidate (`ActivePointerWdgt._declareDragEmbedEphemerals`, `candidateOutlineStyle`) | the receiver a release reaches | accent ring | ring | keep |
| 3 | Reluctant target (same site, `reluctantOutlineStyle`) + "view-only" badge | a receiver in view mode that declines | `line` ring | ring | keep |
| 4 | Resize target (`FrameGripWdgt`, `resizeTargetOutlineStyle`) | the window a grip resizes | accent ring | ring | keep |
| 5 | Menu-row hover (`Widget.turnOnHighlight` from `MenuItemWdgt`, `fillStyle hoverHighlightWash`) | the widget a hovered row NAMES (hierarchy menu, Attach chooser, wire rows) | `accentTint` wash | ring, literally | **owner: L2** (recommend keep) |
| 6 | Editor selection ring (`Widget._drawSelectionOverlay`, `FrameWdgt._paintPageSelectionRing`, `ViewportWdgt._drawSelectionOverlay`) | the selected widget | accent ring | ring | keep |
| 7 | A sheet's selected cell (`CellAppearance`, `spreadsheetSelectionRing`) | the selected cell | accent ring | ring | keep |
| 8 | An icon holder's empty slot (`SimpleDropletWdgt`, `SimpleDropletAppearance`) | a standing place to drop into | borderless `desk` well | fill | already conforms |
| 9 | Drag over a standing slot (#8, or an "Edit layout" drop slot, `LayoutElementAdderOrDropletWdgt`) | the slot that receives, which is also where the payload lands | accent ring (as #2) | either | **owner: L3** (recommend keep) |
| 10 | Dwell ring, armed label | the dwell's progress, the release's outcome in words | — | n/a | not a highlight |
| 11 | Paint tools' feedback on the glass (`CanvasGlassTopWdgt`) | the stroke being drawn | the stroke | n/a | not a highlight |

Left out on purpose, with the reason: a control's OWN state paint — a menu row's hover plate, a list row's
selected plate (`listRowSelectedFill`), a toggle's on fill, a selected desktop icon's plate, a text selection —
is the control saying what state it is in, not a highlight laid over a widget, and follows the platform's
convention (a selected row is a filled plate everywhere). The "Edit layout" chrome (`LayoutChromeWdgt`: adders,
drop slots, spacers, adjusters) is a family of CONTROLS (a click on a drop slot adds another), drawn as plates in
a `line` border like every control; its drop slots are not previews.

Not present today, and where the rule applies when they are added: an insertion marker in a stack, a document's
flow or a toolbar while something is carried over it (today the release just lands there; nothing previews the
slot). Such a marker marks a place, so it is a wash, built with `landingAreaStyle()`.

### Measured: what each change costs (suite under a prototype prelude, no source change)

Prototypes: `Fizzygum-tests/.scratch/landing-wash/proto-a-dock-band-wash.js` (#1 as a wash, accent at 20 %),
`proto-b-menu-hover-ring.js` (#5 as an accent ring). Each printed its `installed` line in 8/8 shards.

| Prototype | Run | Failing tests | Kind |
|-----------|-----|---------------|------|
| A, dock preview as a wash | dpr 1, mouse | `macroDockOutlineIsTheBandItMakes` (images 0, 1), `macroSecondBandJoinsItsSide` (image 0), `macroToolbarDocksAtTheDepthItFloatsAt` (image 0) | pictures only |
| A | dpr 1, finger | the same three tests, the same four images | pictures only |
| A | dpr 2, mouse | the same three tests, the same four images | pictures only |
| B, menu hover as a ring | dpr 1, mouse | `macroHierarchyMenuHoverHighlightsExactSubtree` (images 2–4), `macroHighlightTracksRotatedIslandTarget` (images 1, 2), `macroTargetingHighlightsCandidateWidget` (images 2, 3) | pictures only |

Rendered looks for the owner: `Fizzygum-tests/.scratch/landing-wash/review.html` (renders by
`probe-renders.js`, dpr 2).

---

## §3 The mechanism today (lines drift: grep the quoted symbol, not the number)

- `src/HighlighterWdgt.coffee` — `class HighlighterWdgt extends RectangleWdgt`, an ephemeral overlay. Its style
  descriptors, plain records: `@fillStyle: (color) -> {form: "fill", color: color}` (~line 59);
  `@candidateOutlineStyle`, `@reluctantOutlineStyle`, `@resizeTargetOutlineStyle` (~65–68), each
  `{form: "outline", color: WorldWdgt.theme.<role>, alpha: 1}`. `applyHighlightStyle: (style)` (~76) gives a
  highlighter its appearance by form: `HighlightOutlineAppearance` (a `dropOutlineWidth` ring inside the box) or
  `HighlightWashAppearance` (the box filled once in `@color`, translucent by the colour's own alpha). Both round
  their corners at `outlineRadii` (set by `coverBox`/`coverTarget`, from `Widget.cornerRadiiFollowingMyOutline`).
- `src/basic-widgets/Widget.coffee` — `turnOnHighlight` (~2954):
  `world.widgetsToBeHighlighted.set @, HighlighterWdgt.fillStyle WorldWdgt.theme.hoverHighlightWash`. Called by
  `MenuItemWdgt` (~533, `@representedWidget()?.turnOnHighlight()`) as a row that names a widget is hovered.
- `src/ActivePointerWdgt.coffee` — `_declareDragEmbedEphemerals` (~511): over a dock offer it declares
  `world.dragEmbedDockBandDeclared = {host, box: host.bandBoxIfDocked(...)}` and stands the per-widget outline
  down; otherwise it sets the candidate's or the reluctant target's outline style into the channel (~532).
- `src/WorldWdgt.coffee` — `_addHighlightingWidgets` (~1730) reconciles the per-widget channel; 
  `addDragAffordanceWidgets` (~1775) builds the dock preview: `@dragEmbedDockBandWdgt = new HighlighterWdgt`,
  then `@dragEmbedDockBandWdgt.applyHighlightStyle HighlighterWdgt.candidateOutlineStyle()` (~1829), then
  `coverBox (bandHost.mapRectToScreen bandBox), bandRadii`.
- `src/FrameGripWdgt.coffee` (~150) — `resizeTargetOutlineStyle()` into the channel.
- `src/Theme.coffee` — `@accentTint` (~45: the accent at alpha `0x1F/255`, 12 %); `@dropCandidateOutline`
  (~428), `@dropReluctantOutline`, `@resizeTargetOutline`, `@hoverHighlightWash = @accentTint` (~442), each with a
  comment saying what it is for; `@dropOutlineWidth = 2` (~1127).

## §4 Why it is shaped this way

The drag-embed spec (`docs/specs/drag-embed-interaction-spec.md` §11) replaced the old candidate highlight, a
"hardcoded blue fill, alpha 50" over the whole receiver, with a 2 px accent ring: a wash over a whole receiver
was "far too loud for a drag affordance" (the reason `HighlighterWdgt`'s comment still gives). That decision fits
the owner's new rule exactly: the receiver is a thing, so a ring. When dock bands arrived
(`docs/archive/frame-lifetime-and-docking-plan.md`, spec §4.1), the band's preview took "the SAME
candidate-accent style §11's highlight row already specifies", for uniformity with the receiver's ring; nobody
asked then whether a band that does not exist yet is a thing. The menu-row hover kept the old channel's fill
form, recoloured to `accentTint` by the visual redesign.

## §5 The distilled argument

- The two forms already exist and already paint every case correctly (corners, planes, islands, both
  backends); what is missing is the RULE that picks between them, stated once. Producers name a meaning; the
  meaning names the form. Nothing new is drawn and no new mechanism is added.
- The dock preview is the only highlight that marks a place, so the rule changes one look today, and gives
  every future landing-area preview (an insertion marker) its look without a decision.
- The mirror case is measured, not assumed: a ring on the widget a menu row names lands beside or on the
  selection ring, which is the same accent ring on a thing (renders `hover-*-ring-*.png`): hovering the row for
  the selected page draws a double line; hovering the row for its window draws two identical rings, and which one
  the row names cannot be told. A wash cannot be confused with a ring. Hence L2's recommendation.

---

## §6 Owner decisions — RULED 2026-11-24: L1 = 20 %, L2 = (a) keep the wash, L3 = (a) keep the ring

The owner took every recommendation below ("go ahead with your recommendations").

**L1 — how strong the wash is.** The accent at 12 % (`accentTint`, the menu hover's wash), 20 %, 30 % or 40 %
(renders `dock-wash-12/20/30/40.png`, beside today's ring `dock-today.png`). At 12 % the band nearly vanishes over
a paragraph's grey plate; 40 % starts to compete with the text under it. **Recommended: 20 %** — clearly a
band over both the page's white and a paragraph's plate, the text under it reads as before, and it stays
distinct from the 12 % hover wash (#5), which marks a different thing.

**L2 — the widget a hovered menu row names (#5).** Read literally, the rule says ring: it is a thing.
- (a) **Keep the wash** — the rule's one stated exception, its reason written beside it: the ring on a thing is
  already the selection ring's, and the row's identification must not be mistaken for a selection. Zero code;
  the style is renamed by meaning (`namedByARowStyle`). **Recommended.**
- (b) An accent ring (prototype B) — measured 3 tests, pictures only; renders show the double line and the two
  identical rings.
- (c) A ring in the neutral `line` colour — renders `hover-*-ring-line.png`: still a double line beside the
  selection ring.
- (d) A ring, and the selection ring stands down while a row names a widget — one ring at a time, but the
  selection overlays are paint-time (`Widget._drawSelectionOverlay` and two host painters), so standing down means
  a new world state those three read and repaint on, about +25 lines; not prototyped.

**L3 — a drag over a standing slot (#9).** The slot is a thing (it is drawn: a well, a plate) AND where the
payload lands. (a) **Keep the ring** — it is visible, and the ring says "this one receives", as for any receiver.
**Recommended.** (b) A wash over the slot: a capability on the receiver, "where would this payload land"
(`landingBoxFor`), answered by the slots, which the hand would wash in place of ringing the receiver, generalising
the dock preview's own slot (`world.dragEmbedDockBandDeclared`) into a landing-area slot; about +20 lines, not
measured. Defer until a second landing-area preview (an insertion marker) gives the capability a reason to exist.

---

## §7 The fix shape

### Phase 1 — the rule, in `HighlighterWdgt` and the theme

1. In `src/HighlighterWdgt.coffee`'s header, replace the opening description with the rule, present tense: a
   highlighter marks either a THING, with a ring (its outline form), or a PLACE where nothing stands yet, a
   landing area, with a wash (its fill form); a producer names what it marks through one of the class's style
   factories and never a form or a colour. Then (L2 a) the one exception, with its reason: the widget a hovered
   menu row names is washed, since the ring on a thing is the selection ring's.
2. Style factories, each named by what it marks:
   - add `@landingAreaStyle: -> {form: "fill", color: WorldWdgt.theme.dropLandingWash}`;
   - keep `@candidateOutlineStyle`, `@reluctantOutlineStyle`, `@resizeTargetOutlineStyle` (already named by
     meaning);
   - replace `@fillStyle: (color)` with (L2 a) `@namedByARowStyle: -> {form: "fill", color:
     WorldWdgt.theme.hoverHighlightWash}` — or, under L2 b/c, `{form: "outline", color: <the role>, alpha: 1}` and
     its theme role; under L2 d, stop and re-plan that half.
   - Fix the comment block above them (it says "Two forms: ... (menu hover-highlight) ... (drag candidate/
     reluctant affordance)"): the forms are now said by the rule.
3. `src/Theme.coffee`: add `@dropLandingWash` beside `@dropCandidateOutline` — the accent at the L1 alpha
   (L1 = 20 %: `Color.create 0x2F, 0x5B, 0xEA, 0x33 / 255`; if L1 = 12 %, `@dropLandingWash = @accentTint`).
   Its comment: "the WASH laid over a place a release would put what the hand carries, where nothing stands yet
   (the band a dock would make): the accent, translucent by its own alpha". Reword the `dropCandidateOutline`
   comment, which says "(and a dock band)".
4. `src/basic-widgets/Widget.coffee` `turnOnHighlight`: `HighlighterWdgt.namedByARowStyle()`; its comment.

### Phase 2 — the dock preview

1. `src/WorldWdgt.coffee` `addDragAffordanceWidgets`: `@dragEmbedDockBandWdgt.applyHighlightStyle
   HighlighterWdgt.landingAreaStyle()`; reword its comment ("outlined in the candidate accent" → washed: it marks
   a place nothing stands in yet).
2. `src/ActivePointerWdgt.coffee` `_declareDragEmbedEphemerals`, comment "0. the DOCK BAND, outlined as the dock
   would MAKE it": washed. The code is unchanged: the host's per-widget ring still stands down while a band is
   offered (one highlight at a time).
3. `src/HighlightWashAppearance.coffee` and `src/HighlightOutlineAppearance.coffee` headers: the wash paints a
   landing area (the dock preview) and the widget a hovered row names; the ring no longer lists "a dock band".
4. `fg build`. Then a quick look: `node Fizzygum-tests/.scratch/landing-wash/probe-renders.js --dpr=2
   --only=dock-today` renders today's look through the built code (no prelude), which must now match
   `dock-wash-20.png` (for L1 = 20 %).

### Phase 3 — tests

1. **Rename** `SystemTest_macroDockOutlineIsTheBandItMakes` → `SystemTest_macroDockPreviewIsTheBandItMakes`: `git mv`
   the directory; rename both files and the two `var` names inside them; `takeScreenshot` names inside the macro;
   delete its old references (`automation-assets/`, they carry the old name and the old pictures); update the live
   mentions (`docs/architecture/toolbars.md` §2 test list, `src/macros/MACRO-PATTERNS.md`; grep the old name in both
   repos, leaving `docs/archive/` as it is). Reword its prose: description, intent, assertions ("outline" → the
   preview, a wash) and its macro comments; the assertion "...and a band is outlined" → "...and the band is
   previewed".
2. **Add one assertion** to it, at the first hold: the preview is a wash —
   `world.dragEmbedDockBandWdgt.appearance instanceof HighlightWashAppearance` — and a plant
   (`Fizzygum-tests/.scratch/landing-wash/plants/p1-the-dock-preview-is-a-ring.js`, patching
   `addDragAffordanceWidgets`' style back to `candidateOutlineStyle()` through `HighlighterWdgt.prototype.
   applyHighlightStyle`, as `proto-a` patches it the other way) must fail exactly that line, under both pointers.
   Record the plant in the test's provenance.
3. **Recapture the predicted set**, and only it, on both pointers at dpr 1 and 2 (§2 measured the same set on
   each): the renamed test (all three images: images 0 and 1 change, image 2 keeps its pixels under its new name),
   `macroSecondBandJoinsItsSide` image 0 and `macroToolbarDocksAtTheDepthItFloatsAt` image 0. First LOOK at each new picture (`fg diffpage <test>`): the band is a wash at the
   place the ring was, and nothing else moved. Then `fg recapture --auto --dprs=1,2` and
   `fg recapture --auto --pointer=finger --dprs=1,2`; compare the recaptured list with the predicted list by script
   (a written list, diffed), never by eye.
4. Under L2 b/c only: the three tests of prototype B too, and their prose ("washes" → "rings").

### Phase 4 — the living docs (present tense, no history)

- `docs/architecture/visual-design-system.md`: the overlay bullet in §4 ("An overlay laid over a widget — a menu
  row's hover wash, the drag's outline around a target..."), the §5 rows "Drag feedback" (it lists the band among
  the outlines, `dropCandidateOutline` "for a candidate or a band") and "Hover wash"; add the rule once, in the
  "Drag feedback" row or beside it: a ring marks a thing, a wash a place, with `dropLandingWash`.
- `docs/specs/drag-embed-interaction-spec.md`: §4.1's "Candidate highlight = the band the release would MAKE"
  paragraph (it names `candidateOutlineStyle` for the band) and §11's "Dock band highlight" row: a wash,
  `HighlighterWdgt.landingAreaStyle`, `dropLandingWash`; say why in one clause (it marks a place nothing stands
  in yet, where the candidate's ring marks a thing). A spec is a contract: reword it to the contract that holds.
- `docs/architecture/toolbars.md` §2: the bullet "**The outline of a dock is the band it would make.**" → the
  preview of a dock; "the hand outlines" → "the hand washes"; the test list line.
- `src/macros/MACRO-PATTERNS.md`: the entry citing the dock test (grep its old name and "outline" near "dock").
- `docs/BACKLOG.md`: this plan's section and items (filed at authoring) close per `docs/README.md` rule 2 when the
  plan closes.

### Phase 5 — gates

`/Users/davidedellacasa/code/Fizzygum-all/fg presuite` after Phase 2 (it must fail exactly the predicted set,
pictures only, plus nothing); after Phase 3, `fg gauntlet` (20/20; a leg retried and green is a load-flake to
report, not a pass to bury) and `fg homepage` (the change is shipping code). Run each long op in the background,
log to `/tmp/fg-<cmd>-run.log`, and never pipe a gating `fg` call through a filter.

---

## §8 Risks

- **A turned host.** Inside a rotated or scaled island the reconciler covers the band's SCREEN bounding box, so a
  wash there tints a turned rectangle's bounding box, a larger area than the band (today's ring has the same
  geometry, square: `addDragAffordanceWidgets` passes no radii when `bandHost.isVisuallyTransformed()`). Accept,
  as today; no test turns a host and docks into it with a picture (check: grep the dock tests for
  `setRotationDegrees`).
- **The predicted set under other axes.** §2 lists what was measured; the gauntlet's webkit leg reuses the dpr-1
  references (SWCanvas pixels are engine-independent), so it needs no capture of its own. Anything else that
  fails is a finding: read it before recapturing anything.
- **A wash over the payload.** The hand paints above every overlay, so the carried frame covers the wash where
  they overlap, as it covers the ring today (renders). No change.
- **Two washes meaning different things.** Under L2 a and L1 = 12 %, the dock preview and the row hover would be
  one look for two meanings; they never show at once (a drag and an open menu exclude each other), but L1's
  recommendation (20 %) keeps them apart anyway.

## §9 Cold-execution protocol

1. `fg status` (clean trees, build FRESH or stale is fine: Phase 2 builds). Read this plan whole, then §6's
   rulings as the owner gave them (they are written into §6 when ruled: if §6 still says "open", stop and ask).
2. Phases 1 → 5 in order, one commit pair at the end (Fizzygum, then Fizzygum-tests), and ONLY after the owner
   has seen the summary and the proposed messages (`git commit -F <file>`: backticks in a `-m` are mangled).
3. Stop and report, rather than improvise, if: the presuite's failing set differs from the predicted one; a
   recaptured picture shows anything but the wash where the ring was; any gate fails twice.

## §10 Rejected alternatives (do not re-attempt without new evidence)

- **A wash over the whole RECEIVER** (#2): the drag-embed spec's original highlight, replaced by the ring because a
  whole-target fill was "far too loud" (spec §11, `HighlighterWdgt`'s comment). The receiver is a thing; the rule
  agrees with that decision.
- **The menu-row hover as an accent ring** (L2 b): measured, renders `hover-page-ring-accent.png`,
  `hover-maker-ring-accent.png`: a double line on the selected widget, and two indistinguishable rings when the row
  names its window.
- **The same in the neutral `line` colour** (L2 c): renders `hover-*-ring-line.png`: still a double line.
- **A dashed or thinner ring for a landing area**: still a border, which is what reads as "a selection of
  something" (the owner's own reason).
- **A producer-chosen form** (keeping `fillStyle(color)` beside meaning-named factories): two ways to ask for a
  look, the drift this plan removes.

## §11 References

- The living docs this plan rewords: `docs/architecture/visual-design-system.md` (the roles, §4–§5), the
  drag-embed spec (`docs/specs/drag-embed-interaction-spec.md` §4.1, §11), `docs/architecture/toolbars.md` §2.
- Prototypes, renders and logs: `Fizzygum-tests/.scratch/landing-wash/` (`proto-a-dock-band-wash.js`,
  `proto-b-menu-hover-ring.js`, `probe-renders.js` with `--only=<prefix>`, `renders/`, `review.html`,
  `suite-*.log`).
- The arcs this builds on: the several-bands plan (`docs/archive/several-bands-per-side-plan.md`: bands, the
  preview's box), the visual redesign (`Theme`, one design system).

---

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] §7 Phases 1–5: the dock preview, a place nothing stands in yet, becomes a wash, at 20 %; the styles are named by what they mark; a menu row's hover keeps its wash (§6 L2). — CLOSED 2026-11-24: landed as written, with the deviations below.

Deviations from the plan as written:

- The 20 % wash is a palette primitive, `accentWash` (beside `accentTint`, and in the design system's palette
  table), which the role `dropLandingWash` names, rather than a literal in the role.
- More comments said "outline" of the dock preview than §7 listed: `FrameWdgt` (`dockBandBoxAt`,
  `bandBoxIfDocked`, `_edgeDockSpecFor`), `Widget.isVisuallyTransformed`, and `docs/architecture/
  input-and-gestures.md`; each now says "wash" or "preview".
- Measured as predicted: the recapture wrote exactly the 20 predicted references (the renamed test's three
  images and two images of two other tests, dpr 1 and 2, mouse and finger), compared by script; the renamed test's
  image 2 kept its pixels. The plant restoring the ring failed exactly the new wash assertion, at each of the four
  holds, under both pointers.
