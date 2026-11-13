# MIGRATION-PLAN.md — one-off triage of ALL remaining recorded tests

**✅ PLAN CLOSED 2026-06-12 (closure commit = Batch 63).** Every item is ticked, every follow-up
executed: `tests/` holds **160 macro tests and zero recorded tests**, the
`completely-broken-tests-21-Jun-2023/` folder is gone (its five recordings triaged and
resolved in the post-migration addendum), the `SWCanvasBrokenTests` skip-lists are empty,
and `migrated-originals/` caches all 220 retired originals. This file stays as the
historical record of every verdict and its evidence; the living documentation is
`../Fizzygum/src/macros/MACRO-PATTERNS.md` (one entry per mechanic) and
`../Fizzygum/src/macros/CLAUDE.md`. New tests are authored as macros directly — use the
`/author-macro-test` skill. **NOTE (post-closure):** the test recorder and all migration
tooling (`thin-systemtest.js`, `make-migration-comparison.js`, `README-migration.md`, the
`migrate-systemtest` skill) have since been **removed** from the tree, so the references to
them in the body below are historical. Restoring/replaying a `migrated-originals/` original
now requires a pre-removal checkout of both repos — see `migrated-originals/README.md`.

Drawn up 2026-06-10 from the v2 thinner digests of all **114 remaining recorded tests**,
cross-referenced against the **114 shipped macros** and `../Fizzygum/src/macros/MACRO-PATTERNS.md`.
Purpose: stop re-triaging the whole corpus every batch — each batch just takes the next
items off this list, and updates the checkboxes. (Per-test details: regenerate a digest any
time with `node scripts/thin-systemtest.js SystemTest_<name>`.)

## How to consume this plan (per batch)

1. Take the next 2–3 unchecked items from **MIGRATE** (top to bottom; they are roughly
   ordered easiest-first within each cluster). Then proceed per `/migrate-systemtest`.
2. For a **MIGRATE-REP** item, the macro should state in `provenance` that it represents its
   listed siblings; when it ships, retire the siblings (they are pre-listed under DROP with
   "covered by REP" notes).
3. **DROP items**: before retiring one, spend ~2 minutes glancing at its reference
   screenshots (`automation-assets/**/SWCanvas/**.png`, or its digest's `Δprev` lines) to
   confirm the covered-by note — if the shots show a beat no macro covers, promote it back
   to MIGRATE. Retirement = `git mv`-style move into `migrated-originals/` (gitignored local
   cache) + `git rm` from `tests/` — see `scripts/README-migration.md`.
4. **DEEP-DIVE items** are last: each needs framework-source investigation or a split
   decision before any authoring. Do at most one per batch, alongside easy items.

Verdict legend:
- **MIGRATE** — novel mechanic, approachable now; one macro per item.
- **MIGRATE-REP** — migrate as the representative of a family; siblings then DROP.
- **DROP** — retire without a macro: the specific behaviour is already covered by a
  **simple, DEDICATED** shipped macro (named in the note) or by a REP above it; or it
  verifies nothing. Needs the 2-minute screenshot glance first.
- **DEEP-DIVE** — tricky/omnibus; needs investigation, a split, or an owner call.

**The dedicated-coverage bar (owner rule):** a DROP is only valid when a simple macro is
DEDICATED to that behaviour — i.e. the behaviour is in that macro's `assertions`, not merely
exercised. "Covered by a combination of N macros", "exercised by fixtures", or "one omnibus
macro touches it" do NOT qualify — in those cases author a small dedicated macro instead
(flip to MIGRATE/MIGRATE-REP). Recorded tests were expensive to create so several are
omnibuses; macros are cheap, so coverage should be one-behaviour-per-macro.

Status: 114 tests = 17 MIGRATE · 11 MIGRATE-REP · 76 DROP (incl. follow-the-REP siblings) · 10 DEEP-DIVE.
(Revised 2026-06-10 under the dedicated-coverage bar: 9 former DROPs whose coverage was
combination/omnibus/fixture-only were flipped to MIGRATE or MIGRATE-REP.)
After Batch 38 (first DROP-glance sweep, 17 glanced): 98 tests remain under `tests/` —
unchecked: 17 MIGRATE (14 + 3 promoted: WindowWithPlainWrappingTextResizingFollowsContentSize,
tripleClickSelection, softWrapping) · 11 MIGRATE-REP · 60 DROP (76 − 13 retired − 3 promoted;
stringMorph2ShiftClickSelections found REP-blocked, see its note) · 10 DEEP-DIVE.
After Batch 39 (3 Cluster A migrations shipped + originals retired): 95 tests remain —
unchecked: 14 MIGRATE · 11 MIGRATE-REP · 60 DROP · 10 DEEP-DIVE; 117 macros shipped.
After Batch 40 (the Cluster B MIGRATE trio shipped + originals retired): 92 tests remain —
unchecked: 11 MIGRATE · 11 MIGRATE-REP · 60 DROP · 10 DEEP-DIVE; 120 macros shipped.
After Batch 41 (the Cluster C MIGRATE trio shipped + originals retired — the two windows/scroll
items plus the Batch-38 promotion WindowWithPlainWrappingTextResizingFollowsContentSize):
89 tests remain — unchecked: 8 MIGRATE · 11 MIGRATE-REP · 60 DROP · 10 DEEP-DIVE; 123 macros shipped.
After Batch 42 (the Cluster D text trio shipped + originals retired — textRelayoutsCorrectlyOnResize
plus the two Batch-38 promotions tripleClickSelection and softWrapping):
86 tests remain — unchecked: 5 MIGRATE · 11 MIGRATE-REP · 60 DROP · 10 DEEP-DIVE; 126 macros shipped.
After Batch 43 (the Cluster E inspector trio shipped + originals retired —
inspectorResizingOKEvenWhenTakenApart, wrappingTextFieldResizesOK, multilineTextInputScrollsWell;
multilineTextInputScrollsWell also came OFF the SWCanvasBrokenTests list at both densities — its
macro restores SWCanvas coverage; rider: AutomatorLoader.loadAndRunSingleTestFromName had the
retired test's name HARDCODED plus debugger leftovers, fixed to use its testName parameter):
83 tests remain — unchecked: 2 MIGRATE · 11 MIGRATE-REP · 60 DROP · 10 DEEP-DIVE; 129 macros shipped.
After Batch 44 (the FINAL 2 MIGRATE items shipped + originals retired —
resizingScrollFrameThenImmediatelyScrollingTheHandlesDontStickToScrollPanelContent (Cluster F),
stringMorph2AndTextMorph2ResizingInLayout (Cluster G)): 81 tests remain — unchecked:
0 MIGRATE · 11 MIGRATE-REP · 60 DROP · 10 DEEP-DIVE; 131 macros shipped. The plain-MIGRATE
phase is COMPLETE — next up are the MIGRATE-REP items (each absorbing its DROP siblings).
After Batch 45 (the FIRST 3 MIGRATE-REP items shipped, each macro absorbing its glanced DROP
siblings, all retired together — WindowWithAClockInAWindowConstructionTwo (+ ConstructionOne),
WindowWithSimpleVerticalPanelResizesAsContentChanges (+ its 3 scroll/wrapping-panel siblings,
with a folded edit beat and a folded scroll-panel no-grow contrast beat),
textMorph2CaretKeepsCorrectAlignment (+ KeepsAlignedWithStyleChanges, italic beat folded in)):
73 tests remain — unchecked: 0 MIGRATE · 8 MIGRATE-REP · 55 DROP · 10 DEEP-DIVE; 134 macros
shipped.
After Batch 46 (2 MIGRATE-REPs in Cluster D — textMorph2CaretResizing (+ its single-line DROP
sibling, glanced) and stringMorph2ImprovedSelection (+ PartTwo and PartThree, glanced, their
cancellation/flip/edge-collapse axes folded in as 7 extra beats incl. the required Meta+A
select-all) — which UNBLOCKED the REP-BLOCKED stringMorph2ShiftClickSelections (its 11 blocked
shots re-glanced against the shipped REP, retired in the same batch)): 67 tests remain —
unchecked: 0 MIGRATE · 6 MIGRATE-REP · 51 DROP · 10 DEEP-DIVE; 136 macros shipped.
After Batch 47 (2 MIGRATE-REPs — layoutsAndVisibility (no DROP siblings; 4 intermediate beats
folded in, incl. a byte-equal hide/show round-trip; the plan note's "redistributes space" was
WRONG — the layout is visibility-blind, the hidden cell's slot is KEPT; fixture authored for
reuse by the layoutsAndCollapsing deep-dive, whose collapse-DOES-redistribute contrast is
already source-verified) and SimpleDocumentAllReflowsCorrectlyAsIChangeFontSize (+ its 3
Width*StackPanel/ScrollStack DROP siblings, glanced shot-by-shot; the scroll-stack sibling's
font-SHRINK axis folded in as a byte-equal back-to-default-12 coda)): 62 tests remain —
unchecked: 0 MIGRATE · 4 MIGRATE-REP · 48 DROP · 10 DEEP-DIVE; 138 macros shipped.
After Batch 48 (the layoutsAndCollapsing DEEP-DIVE shipped — the visibility macro's fixture
reused verbatim, collapse()/unCollapse() driven directly; its image_1/image_5 came out
BYTE-IDENTICAL to macroLayoutsAndVisibility's at both dprs, so the contrast pair shares exact
endpoints; both SWCanvasBrokenTests entries removed, restoring SWCanvas coverage — plus 1
MIGRATE-REP, SimpleDocumentRemovingLastParagraphUpdatesScrollbarAndLeavesViewportAtEndOfDocument
(+ its 3 add-at-the-end/WNS DROP siblings, glanced shot-by-shot; the add-at-the-end beat folded
in as a drop-while-scrolled-at-the-end, the Enter-typing caret-follow half credited to
macroDocumentCaretBroughtIntoViewWhenMoved)): 57 tests remain — unchecked: 0 MIGRATE ·
3 MIGRATE-REP · 45 DROP · 9 DEEP-DIVE; 140 macros shipped.
After Batch 49 (2 MIGRATE-REPs, both "while scrolled at the bottom" twists on the SAME
'simple plain text scrollpanel wrapping' demo fixture (shared verbatim, so their pristine
image_1s are byte-identical cross-test): WrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo
(font 12→28→12 with the shrink END-SCROLLED → top re-anchor + bar hidden, image_4 ≡ image_1
byte-for-byte; + its NonWrapping DROP sibling glanced — its own image_4 ≡ image_1 equality is
the same wrap-agnostic clamp) and SimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent
(clipboard-quadrupled content, caret-follow lands the end-clamp, softWrapOff/On through the
panel's COALESCED menu — NOT TextMorph2.toggleSoftWrap, and the in-panel menu DOES open for
synthetic right-clicks; image_5 ≡ image_2; the macro reproduced the recording's reference
pixels hash-for-hash at both dprs; + its SwitchingWrappingOnAndOff DROP sibling glanced)):
53 tests remain — unchecked: 0 MIGRATE · 1 MIGRATE-REP · 43 DROP · 9 DEEP-DIVE; 142 macros
shipped.
After Batch 50 (the LAST MIGRATE-REP — the REP phase is CLOSED:
WrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved, the bare-wrap reLayout law
(width KEPT, height = lineCount × fontHeight) driven entirely by direct setText/setFontSize
per the banked bare-text convention — 6 shots, 4 of them byte-identical to retired
recordings' shots at both dprs (pristine ≡ restore ≡ font-round-trip ≡ the recordings'
shared pristine; the setFontSize-17 beat reproduced the font sibling's prompt-driven final
shot hash-for-hash, proving prompt-string and direct-numeric setFontSize land identically);
+ its 2 DROP siblings glanced shot-by-shot: LinesAreDeleted (its one-line-strip end state is
the macro's image_3) and TexSizeIsChanged (folded as the font beat — 17 not its 20, keeping
the grown bottom edge in frame — plus the back-to-12 coda it never shot)): 50 tests remain —
unchecked: 0 MIGRATE · 0 MIGRATE-REP · 41 DROP · 9 DEEP-DIVE; 143 macros shipped.
After Batch 51 (second DROP-glance sweep, 26 glanced — everything before the
text/scroll-panel block: the 3 early scroll-panel items (auto-scroll edges ≡
macroListWdgtAutoScrollsNearDraggedEdge's four-edge assertion; bars-track-dimension and
bars-track-position ≡ macroScrollBarsTrackContentChange) + the whole 23-item covered-matrix
block (SimpleDocument/Width*StackPanel/ScrollStack reflow-grow-shrink, icon-in-flow,
centered-stays-centered, indent narrow+push-right, dropped-sizes-preserved incl. the
WC-scales vs WNC-clips contrast, contents-locking, caret-into-view-only-when-moved,
elements-deleted, and the NonWrapping bare-text trio onto
macroNonWrappingTextResizesToContent) — every shot landed in the named macro's `assertions`;
0 promotions; filename harvest: ContentsLocking image_3 ≡ image_4 is the locked no-op drag,
ScrollStack-ElementsDeleted image_4 ≡ image_1 is an exact delete round trip. THREE
SWCanvasBrokenTests entries removed with their tests: NonWrapping…TexSizeIsChanged (dpi1+dpi2,
the known double listing) and ScrollPanelUpdates…PartTwo (dpi2 — found by the pre-retirement
grep; its digest's 5-not-6 refs were the tell)): 24 tests remain — unchecked: 0 MIGRATE ·
0 MIGRATE-REP · 15 DROP · 9 DEEP-DIVE; 143 macros shipped (none added — pure retirement).
After Batch 52 (third DROP-glance sweep, 10 glanced — ALL remaining independent DROPs: the
7-item text/scroll-panel block (bar-iff-overflow per axis, thumb size/position tracking,
wrap width-KEPT vs no-wrap width=longest-line reflow, end-clamp resolution, caret-follow ≡
macroScrollBarsTrackContentChange + the two Batch-49 PTS REPs + the caret-into-view and
no-wrap macros; filename harvest: all 4 NonWrapping image_1 share the a376f4dc pristine, all
3 Wrapping image_1 share 0f3c6b7c — the very hashes the REP macros' metadata cite — and
Wrapping…TexSizeIsChangedPartOne's image_4 ≡ image_1 is the font round-trip restore, the REP's
image_4=image_1 law minus the end-scroll twist) + the 3 late leftovers: basicResize
(grow+shrink multi-drag ≡ macroTextRelayoutsCorrectlyOnResize, post-exit handles-gone shot ≡
macroCanMoveAndResizeColorPaletteWdgt image_2 / macroHandleWdgtIsItselfResizable image_4),
attachingTextMorphToPanelAndScrollPanel (a misnomer — no attach… menu, pure drop-based
re-parenting: in/out ≡ macroCompositeDragsAsUnitIntoScrollPanel, bars ≡
macroScrollBarsTrackContentChange, thumb-drag-scrolls ≡ macroMultilineTextInputScrollsWell
image_2 / macroInspectorScrollbarUnplugged) and transparencyAndColorOfPanelAndScrollPanel
(every rule ≡ macroBoxTransparencyAndColorChanging + macroPanelInPanelTransparencyAndStroke +
the slider-prompt macros; the omnibus only adds breadth) — every shot landed in a named
macro's `assertions`; 0 promotions; no harness entries (clean pre-retirement grep). The
independent-DROP phase is CLOSED: 14 tests remain — unchecked: 0 MIGRATE · 0 MIGRATE-REP ·
5 DROP (all nested under DEEP-DIVE decisions) · 9 DEEP-DIVE; 143 macros shipped (none added —
pure retirement).
After Batch 53 (FIRST deep-dive: fiddlingWithResizerHandles, 1375 cmds, 33 steps, 6 shots →
MIGRATED as the FRESH 4-shot macroResizeMoveModeIsLosslessAndReenterable, not a translation:
the five drags are covered resize ground (grow/shrink ≡ macroTextRelayoutsCorrectlyOnResize /
macroCanMoveAndResizeColorPaletteWdgt / macroResizingButtonDoesntCauseItToClick + their
post-exit handles-gone shots) and no min-size crossing exists (smallest state ~90×80), but
TWO lifecycle beats were asserted nowhere: the no-op enter/exit round-trip (recording image_4
≡ image_3 byte-identical in all six reference families) and mode RE-ENTRY (5 sessions; every
shipped macro entered the mode at most once per widget). The macro asserts both: image_2's
captured reference is pixel-identical to image_1's — equal dataHash at BOTH dprs (f513288f…
dpr-1, 432a0be5… dpr-2) — and sessions 2/3 re-enter to grow then shrink. No new verb; clean
harness grep): 13 tests remain — unchecked: 0 MIGRATE · 0 MIGRATE-REP · 5 DROP (all nested
under DEEP-DIVE decisions) · 8 DEEP-DIVE; 144 macros shipped.
After Batch 54 (deep-dive: duplicationOfLinkedInspector, 957 cmds, 30 steps, 3 shots →
MIGRATED as the fresh 3-shot macroDuplicatedInspectorDrivesCopiedTargetOnly, 3 beats 1:1.
The duplicate mechanics and the controller-binding remap are covered ground
(macroDuplicateComplexWidgetRidesHand, macroSlidersControlTextWidget), and
macroDuplicatedInspectorsCloseIndependently's inspected target sits OUTSIDE its copied
subtree — so the INSPECTOR @target remap (InspectorMorph.coffee:21; save at :454-462 runs
@target.evaluateString "this.<prop> = <txt>") was asserted nowhere; the recording's
Δ-regions show a left-only then right-only alpha change, exactly the remap law. The macro
probes both directions: original edit 1→0.25 fades only the left rectangle, copy edit 1→0.6
only the right. GOTCHA banked: clicking a SHORT detail value ("1") with the +14px idiom
lands past the line end and crashes slotAt (TextMorph.coffee:283 — the documented empty-text
trap generalises to any past-the-end click); aim at slot 0 (valueText.topLeft() + 3px), like
the recording's frac-0.032 left-edge click. No new verb; clean harness grep): 12 tests
remain — unchecked: 0 MIGRATE · 0 MIGRATE-REP · 5 DROP (all nested under DEEP-DIVE
decisions) · 7 DEEP-DIVE; 145 macros shipped.
After Batch 55 (deep-dive: morphsHighlighting, 1162 cmds, 28 steps, 18 shots — only 13
unique states, images 3-8 are SIX byte-identical shots → MIGRATED as the FRESH 5-shot
macroHierarchyMenuHoverHighlightsExactSubtree, not a translation. The hover-highlight
TRIGGER (MenuItemMorph.coffee:70-78 mouseEnter → turnOnHighlight when representsAMorph) is
macroTargetingHighlightsCandidateWidget's asserted ground on a FLAT candidate; unasserted
were the GEOMETRY on a nested composite — the highlight covers exactly the hovered
ancestor's SUBTREE, each step up the ladder strictly larger (the recording's detail-pane
trio: pane-only 33% → whole-inspector 54% → cleared) — and the LIFECYCLE (hover-tracking
between items; mouseLeave clears while the menu stays). The macro distills those on an
authored panel>box>rectangle nest: menu-open baseline → rect-only → box subtree → whole
panel → hover-off, with image_5 ≡ image_1 (equal dataHash at both dprs: 17cb65ad… dpr-1,
ee140ebb… dpr-2 — the Batch-53 identity idiom asserting the no-trace clear). The dropped
alt-keys were inert chatter. No new verb; clean harness grep): 11 tests remain — unchecked:
0 MIGRATE · 0 MIGRATE-REP · 5 DROP (all nested under DEEP-DIVE decisions) · 6 DEEP-DIVE;
146 macros shipped.
After Batch 56 (deep-dive: buildAllMorphs, 2478 cmds, 70 steps, 1 shot → authored FRESH per
the pre-framed plan decision as the 1-shot macroDemoMenuCatalogueParade: every STATIC item
of today's demo menu built through the REAL menu path (a makeDemoWidget per-test helper:
right-click the reserved bare menu-home spot → "demo ➜" → item → carry → drop at an
authored grid spot), 17 widgets / 16 items on a legible grid — speech bubble ADDED
(post-recording catalogue addition), "animation demo" EXCLUDED with reason (live
BouncerMorphs keep moving after the drop — the single reference would be a function of
cycle count), texts dropped INTO both panel flavors (the scroll panel clips ✓) and the pen
onto the canvas, exactly the recording's nesting trick. First-try capture green at both
dprs. Also refreshed AutomatorLoader's stale example comments (they named buildAllMorphs +
the long-retired compositeMorphsHaveCorrectShadow). No new verb; harness grep hits were
comments only): 10 tests remain — unchecked: 0 MIGRATE · 0 MIGRATE-REP · 5 DROP (all
nested under DEEP-DIVE decisions) · 5 DEEP-DIVE; 147 macros shipped.
After Batch 57 (deep-dive: SimpleDocumentCanHandleOldInspector, 2338 cmds, 16 shots →
MIGRATED as the fresh 7-shot macroSimpleDocumentHandlesOldInspector — the hosted
deferred-layout composite's full lifecycle: drop-in at own size, ctor resizer works after
every exit (the owner-note beat), oversized re-entry clipped at the doc edge, doc
resize/move reflows the in-document inspector to the new width BOTH ways (sizes preserved
on drop / re-flowed on doc resize — the layout contract's two halves), final exit keeps the
doc-imposed shape; wheel + mid-drag breadth dropped to its asserted ground. The deep-dive
RELEASED its three nested container-flavor DROPs (WidthContraining/WidthNONContraining
stack + scroll-stack CanHandleOldInspector, 38 shots glanced — same script per container;
the constraining-on-drop breadth handed to the AddingWidgets parade decision; the
scroll-stack's thumb-drag ≡ banked ground). GOTCHA banked: two same-type handles alive in
doc-mode — scope the corner lookup to the doc subtree. No new verb; clean harness greps):
6 tests remain — unchecked: 0 MIGRATE · 0 MIGRATE-REP · 2 DROP (nested under the
AddingWidgets parade decision) · 4 DEEP-DIVE; 148 macros shipped.
After Batch 58 (deep-dive: the AddingWidgets parade decision → ONE fresh 2-shot parade,
macroConstrainingStackForcesDroppedWidgetsToFullWidth, releasing all three recordings
(parent 19 shots + SimpleDocument sibling 10 + NON-constraining sibling 21). The deep dive
SHARPENED the law: the constraining stack CAPS the remembered drop width at the content
width and never stretches up (first capture proved it — small widgets kept their sizes;
the recordings grew every widget wider than the stack first). Five oversized kinds →
ONE shared width, text rewrapped; the kept-size half is
macroDocumentPreservesDroppedWidgetSizes' ground. GOTCHA banked: move a bare slider by a
TRACK point — its centre is the value-50 button (non-float drag). No new verb; clean
harness greps): 3 tests remain — unchecked: 0 MIGRATE · 0 MIGRATE-REP · 0 DROP ·
3 DEEP-DIVE; 149 macros shipped. Every remaining recorded test is a deep-dive:
textMorph2LongEditingSession, ScrollPanelVariousScrollingMethods,
WindowContainingCollapsableMenusInScrollStack (last).
After Batch 59 (deep-dive: ScrollPanelVariousScrollingMethods, 4047 cmds, 24 shots →
walked every shot against the macro list: drags/thumb-drags/panel-move all asserted
ground, no wheel/track-click/keyboard in the recording; the ONLY uncovered methods were
the two drag-to-scroll FLAGS (canScrollByDraggingBackground / ...Foreground — bg drag pans
instead of moving the panel; a held drag ON content pans instead of detaching it) →
MIGRATED as the fresh 3-shot macroScrollPanelDragToScrollFlags. Law sharpened en route:
pans CLAMP at the content edge (drag toward the unseen overflow) and the flags are gated
on visible scrollbars (bars hide when content fits again — fixture must overflow
persistently). The recording shipped only 4 reference families (no SWCanvas refs) and sat
in SWCanvasBrokenTests at BOTH densities — both entries removed with it. No new verb.
FLAKINESS ROOT-CAUSED in the same batch (the new macro failed 2-of-3 in Safari): THREE
cadence couplings in ScrollPanelWdgt's drag-to-scroll step, peeled in order. (1) the
POST-RELEASE MOMENTUM glide (friction 0.8 per frame on the last frame's hand delta, its
DISTANCE itself cadence-dependent) → suppressed, with the Date.now() edge auto-scroll,
under Automator.animationsPacingControl (the Blinker/AnalogClock precedent) +
world.wdgtsWithOngoingScrollMomentum gating the macro pump's
noInputsOngoing/readyForMacroScreenshot (the font-atlas-wait idea, defense-in-depth).
(2) RELEASE TRUNCATION — the step samples the hand per FRAME, so the pointer-path tail
playing in the mouse-up's frame was never scrolled (masked before by the glide) → a final
FLUSH in the release branch makes the held-drag total exactly release − press. (3)
MID-RANGE PATH-DEPENDENCE — scrollX/Y clamp against the PREVIOUS frame's contents union
while adjustContentsBounds re-derives it per frame → fixture-level SATURATION RULE: every
pan axis must either saturate (the clamp's unique fixed point) or be exactly zero. The flag
macro's refs were recaptured post-fix (11/11 repeated headless runs green, both dprs); all
other scroll macros pass byte-unchanged; the two remaining recordings have NO
drag-to-scroll beats (digest-checked). Also banked: the panel's bottom strip is the
H-scrollbar — a "background" press there silently does nothing): 2 tests remain —
unchecked: 0 MIGRATE · 0 MIGRATE-REP · 0 DROP · 2 DEEP-DIVE (textMorph2LongEditingSession,
WindowContainingCollapsableMenusInScrollStack); 150 macros shipped.
After Batch 60 (deep-dive: textMorph2LongEditingSession, 6578 cmds, 41 shots — the
endurance omnibus → walked every shot: the expand-to-fill auto-rescaling spine plus
selections/clipboard/alignments/styles all mapped to shipped macros' assertions; the FOUR
laws asserted nowhere — fill-mode switching incl. vertical-axis SCALEDOWN, bold + its
zero-residue round-trip, paste-over-selection, TextMorph2 bottom alignment — distilled
into the fresh 9-shot macroTextWdgtFillModesWeightAndPasteOverSelection (image_7
byte-identical to image_5; owner chose DROP + residue macro over a translated marathon).
The recording's stray "edit:" prompt at its image_21 explained: a click on a CROPPED
TextMorph2 opens the edit prompt — its 18th paste had overflowed the box under default
CROP. Recording retired; both SWCanvasBrokenTests entries removed with it; no new verb):
1 test remains — unchecked: 0 MIGRATE · 0 MIGRATE-REP · 0 DROP · 1 DEEP-DIVE
(WindowContainingCollapsableMenusInScrollStack, the composite omnibus, last); 151 macros
shipped.
After Batch 61 (deep-dive: WindowContainingCollapsableMenusInScrollStack, 3809 cmds, 25
shots — the composite omnibus and the LAST recorded test → walked every shot; the
windows-as-stack-cells / menus-as-window-content composition split THREE ways into the
fresh macroWindowCellsInConstrainedScrollStackReflow (the stack branch of the window
lifecycle helper + live width tracking, two byte-identity anchors),
macroMenuInWindowInScrollStackStaysLive (menu liveness through double wrapping) and
macroDuplicatedCollapsedWindowKeepsStateAndContent (a window duplicate preserves chrome
state, extent and content); everything else mapped to shipped macros' assertions. No new
verb; no skip-list entries to remove):
**0 recorded tests remain — THE MIGRATION IS COMPLETE.** 154 macros shipped across the
plan; tests/ holds 157 macro tests and nothing else; migrated-originals/ caches all 215
retired originals.

---

## Cluster A — quick wins: small, novel, assert-friendly (MIGRATE)

- [x] MIGRATE **lonelySliderCantBeAttachedToAnything** (302 cmds, 0 shots, menu-asserts only) —
  attach-menu of an overlap-free slider offers NOTHING (0 items — attach excludes the parent,
  i.e. the world; set-target keeps it). Sibling of `macroLonelySliderTargetsWorldOnly`
  (set-target); reused its fixture + `@assertTopMenuItem*`. → `macroLonelySliderCantBeAttachedToAnything` (Batch 37)
- [x] MIGRATE **uniqueTargetAndPropertyAreStillPresented** (391 cmds, 12 steps, 3 shots) — when only
  ONE plausible target/property exists, the set-target chooser still presents it (no silent
  skip). Complements the lonely-slider negative. → `macroUniqueTargetAndPropertyAreStillPresented` (Batch 37)
- [x] MIGRATE **handleAttachedToNothing** (247 cmds, 7 steps, 2 shots) — what a HandleMorph attached
  to nothing does. Completes the attach family (`macroAttachShowsNoTargetsMessage`,
  `macroAttachResizingHandleToWidget`, `macroHandleWdgtIsItselfResizable`). → `macroHandleAttachedToNothing` (Batch 37)
- [x] MIGRATE **movingSlidersSidewaysDoesntCauseContentToMoveSideways** (935 cmds, 11 steps, 3 shots)
  — dragging a vertical scrollbar button SIDEWAYS must not pan content. The digest's
  `dragNonFloat … press→release px` lines now state the exact gesture.
  → `macroMovingSlidersSidewaysDoesntCauseContentToMoveSideways` (Batch 39; the image_1==image_2
  byte-equality is kept as the central assertion, pointer parked before every shot)
- [x] MIGRATE **textMorph2PointingAtLastRow** (745 cmds, 12 clicks → 12 shots) — caret placement
  clicking at/past the LAST row. Extends the caret-placement family with an edge case.
  → `macroTextWdgtPointingAtLastRow` (Batch 39; 12 shots distilled to 5, keeping the recording's
  image_10==image_12 equality: a below-the-text click parks the caret at the END slot, x ignored)
- [x] MIGRATE **textMorph2NoJumpsInLayoutOfLongLine** (881 cmds, type:19 → 21 shots) — layout
  stability while typing a long line (no reflow jumps). Novel "stability-under-typing" beat.
  → `macroTextWdgtNoJumpsInLayoutOfLongLine` (Batch 39; 21 shots distilled to 6 across the SCALEUP
  font-tracking arc; the min-font→crop→"edit:" popup tail deliberately not migrated; also removed
  from SWCanvasBrokenTests dpr-1 — the macro is SWCanvas-referenced natively)

## Cluster B — menus & shadows

- [x] MIGRATE **menusAndSubMenusRemainOpenWhileDraggingMenusOnly** (1043 cmds, 15 steps,
  4 shots; flags `midDragStep`,`heldButtonScreenshot`) — float-dragging a MENU keeps the
  open chain (vs `macroMenusCloseOnMouseDownOutside`: a press on a non-menu closes it).
  The held/mid-drag screenshot annotations now make its beats explicit.
  → `macroMenusAndSubMenusRemainOpenWhileDraggingMenusOnly` (Batch 40; two header drags keep
  the 4-menu cascade, then the held press on a rectangle kills it and drags the rect)
- [x] MIGRATE **menuPinnedInScrollPanel** (958 cmds, 18 steps, 2 shots) — a pinned menu
  living INSIDE a scroll panel. Dupe-check first against `macroSubMenuDroppedIntoPanelPinsItself`
  (panel, not scroll panel) — if shots show the same beat, demote to DROP.
  → `macroMenuPinnedInScrollPanel` (Batch 40; dupe-check done — NOT a dupe: the scroll-panel
  axis is distinct (viewport clip + scrollbar, content travel, scroll, item-still-fires);
  the recording's panel-narrowing resize skipped as look-only)
- [x] MIGRATE **pinnedMenuKeepsCorrectShadowWhenBroughtToForeground** (798 cmds, 16 steps,
  2 shots) — pinned-menu shadow correct after bringToForeground. Completes the shadow trio
  with `macroMenuShadowCorrectWhileAndAfterDrag` / `macroPromptShadowFollowsOnDrag`.
  → `macroPinnedMenuKeepsCorrectShadowWhenBroughtToForeground` (Batch 40; the recording's
  console-eval raise replaced by the header-click user path — same Widget.bringToForeground —
  keeping the no-change byte-equality and adding an overlap beat so the raise is observable)
- [x] DROP **pinnedMenuShadowWhenDragged** — dedicated coverage verified in macro metadata:
  `macroMenuShadowCorrectWhileAndAfterDrag` asserts the drag-shadow beats, and
  `macroMenuPinnedByHeaderClick`'s image_2 explicitly asserts the pinned shadow tighten.
  (retired Batch 38 — glance confirmed: pin-tighten + mid-drag lift + drop-restore, nothing else)
- [x] DROP **simpleMenuPinningTwo** — pins a second menu next to a first; pin mechanic =
  `macroMenuPinnedByHeaderClick`; the two-at-once twist adds no new rule.
  (retired Batch 38 — glance confirmed: image_2 is pin + pinned-survival, both asserted there)
- [x] DROP **duplicatedMenuIsAutomaticallyPinnedTwo** — covered by the trio
  `macroDuplicatedMenuAutoPinsOnDesktop` + `macroMenuItemDuplicatesToStandaloneWidget` +
  `macroEmbeddedDuplicateButtonReduplicates` (digest shows exactly those beats; its image_3
  `Δprev: 0%` is the auto-pinned-survival assertion those macros already make).
  (retired Batch 38 — glance confirmed: all 4 shots decompose into the trio's asserted beats)
- [x] DROP **shadowOnPromptKeepsSameIntensity** (11 drags → 11 shots of constant shadow) —
  covered by `macroPromptShadowFollowsOnDrag`; glance to confirm no extra beat.
  (retired Batch 38 — glance confirmed: shots 1/6/11 identical shadow at each drop, no extra beat)
- [x] DROP **alignmentOfMouseIndicator** — **zero screenshots, zero asserts**: replay
  verifies nothing (it was a manual-eyeball recording of the playback pointer overlay).
  Nothing to migrate; retire. (retired Batch 38 — digest confirms: 21 steps, no screenshot lines)

## Cluster C — windows

- [x] MIGRATE **WindowsNestedCollapsingUncollapsing** (1915 cmds, 47 steps, 16 shots) —
  collapse/uncollapse of NESTED windows (outer/inner interplay); novel vs the empty-window
  trio. 16 shots will distill to ~5–6 beats.
  → `macroWindowsNestedCollapsingUncollapsing` (Batch 41; 13 shots after a review rework:
  resizes the EXTERNAL window in all four outer×inner collapse combinations, each followed by
  the complete step-by-step uncollapsing — the recording resized in only two of the four;
  uncollapsed resizes persist + re-wrap, collapsed resizes touch only the bar and revert; the
  recording's 9-distinct-of-16 repeat-cycle equalities distilled to two same-click
  byte-equalities, image_12==image_5 and image_13==image_8)
- [x] MIGRATE **ScrollPanelUpdatesCorrectlyOnCollapsingAndUncollapsingAndClosingWindow**
  (1555 cmds, 25 steps, 7 shots) — a scroll panel as window content stays consistent across
  collapse/uncollapse/close. Composite of covered mechanics but the interaction is novel.
  → `macroScrollPanelUpdatesCorrectlyOnCollapsingAndUncollapsingAndClosingWindow` (Batch 41;
  8 shots; NOTE the one-liner above had the nesting inverted — the recording nests the WINDOW
  inside the SCROLL PANEL, and the mechanic is the window's collapse hooks ending with
  _announceLayoutPropertyChangeToContainer; byte-equality anchored on the two
  uncollapsed shots, image_5==image_7)
- [x] DROP **WindowAndInternalWindowOpening** — opening/placing both window kinds is the
  fixture of `macroInternalVsExternalWindowDrop` + the WindowsEmpty trio.
  (retired Batch 38 — glance confirmed: 1 shot, both kinds open side by side, pure fixture)
- [x] DROP **WindowCantBeDroppedIntoOtherWidgets** — literally
  `macroInternalVsExternalWindowDrop`'s external-window half (`wantsToBeDropped`).
  (retired Batch 38 — glance confirmed: refuses to nest into a window AND a panel; same
  dragged-window-side rule that macro's image_1 asserts)
- [x] MIGRATE-REP **WindowWithAClockInAWindowConstructionTwo** — the construction-ORDER
  variant: only ONE assembly order has a dedicated macro (`macroInternalWindowDroppedIntoWindowFits`
  drops the inner window into the outer). Check both originals' shots to see which order
  that is, and migrate the OTHER one (One and Two are the two orders). Represents:
  - [x] DROP **WindowWithAClockInAWindowConstructionOne** (its order is the one already
    covered by `macroInternalWindowDroppedIntoWindowFits` + `macroClockInWindowKeepsSquareOnResize`
    + `macroResizeWindowContainingInternalWindow` — swap with Two if the shots say otherwise).
  → `macroWindowWithAClockInAWindowConstructionTwo` (Batch 45; 6 shots 1:1). The order check
  CONFIRMED the plan's assignment: Two's unique beat is dropping the clock into the ALREADY-NESTED
  internal window (the drop gate only closes once content is real — WindowWdgt ctor :65-68 /
  reactToDropOf :264-268) plus square-through-two-layers resizes; One's 5 shots (glanced) decompose
  exactly into the three existing macros' beats (clock→free-window relabel/wrap/square;
  window-adopts-window; loaded-composite resize), so One retired with the REP. Fixture reuses the
  shared window-in-window verbs + a frozen AnalogClockWdgt; the recordings' pinned 'others' menu
  (creation scaffolding) dropped — the one expected qualitative diff.
- [x] MIGRATE **WindowWithPlainWrappingTextResizingFollowsContentSize** — PROMOTED from DROP
  (Batch 38 glance): images 4–5 show handle-resizing the window re-wraps the text to the new
  width and the window HEIGHT then follows the re-wrapped content (image_5's narrow window
  grew far taller than the handle drag specified). `macroWindowResizesToTextContent` only
  asserts the content-change axis; `macroWindowContentResizesFreely`/`…KeepsFixedWidth` use
  non-text content. The width-from-user / height-from-content interplay needs its own macro.
  → `macroWindowWithPlainWrappingTextResizingFollowsContentSize` (Batch 41; 5 shots, 1:1 with
  the recording; fixture reuses createNewWrappingSimplePlainTextWdgtWithBackground verbatim)
- [x] MIGRATE-REP **WindowWithSimpleVerticalPanelResizesAsContentChanges** — window with
  COMPOSITE content (a vertical stack) follows the content's growth/shrink. No dedicated
  macro covers composite content: `macroWindowResizesToTextContent` is a single text widget,
  `macroWindowContentResizesFreely` is a CircleBoxMorph. One macro for the family; include
  a scroll-panel-content beat if cheap. Represents:
  - [x] DROP **WindowWithSimpleVerticalPanelWithSimpleWrappingTextResizingFollowsContentResizing**
    (same rule one nesting deeper)
  - [x] DROP **WindowWithSimpleVerticalStackScrollPanel** (same family, scroll-stack content)
  - [x] DROP **WindowWithSimplePlainTextScrollPanel** (same family, text-scroll-panel content
    — the REP's scroll-panel beat covers it; promote back if its 8 shots show more)
  → `macroWindowWithSimpleVerticalPanelResizesAsContentChanges` (Batch 45; 10 shots = the
  original's 7 mapped 1:1 to images 1-6+8, PLUS two folded beats). Folded in: an Enter×3
  text-edit beat (image_7 — sibling 1's grow-by-edit axis; its Backspace-shrink is the same
  chain covered by the delete-collapse beat, its resize-rewraps-nested-text axis is
  macroWindowWithPlainWrappingTextResizingFollowsContentSize + the Batch-44 stack-cell rewrap)
  and a scroll-panel CONTRAST pair (images 9-10 — a second window with a
  SimpleVerticalStackScrollPanelWdgt content takes a big lorem and its bounds stay IDENTICAL:
  siblings 2/3's core no-grow rule). All 3 siblings glanced shot-by-shot (sibling 3's full 8):
  their remaining beats (caret-into-view, bars-track-content, selection rendering in a windowed
  panel) are the shipped scroll/caret/selection families' rules — nothing uncovered, no
  promotion needed. Fixture via the very creator methods the menu items call
  (createSimpleVerticalStackPanelWdgt / ...StackScrollPanelWdgt /
  createNewWrappingSimplePlainTextWdgtWithBackground / world.create new HeartIconMorph).

## Cluster D — text caret / selection (StringMorph2 · TextMorph2)

- [x] MIGRATE-REP **textMorph2CaretKeepsCorrectAlignment** (994 cmds, 29 steps, 3 shots) —
  the caret stays glued to its slot as alignment changes. Represents:
  - [x] DROP **textMorph2CaretKeepsAlignedWithStyleChanges** (same rule, style axis — fold
    one style change INTO the rep macro if cheap).
  → `macroTextWdgtCaretKeepsCorrectAlignment` (Batch 45; 4 shots = the original's 3 1:1 +
  the folded italic beat as image_4, per the note — folded on the harder center/middle fixture;
  the sibling's bold beat is the same metrics-change rule; its 4 shots glanced, nothing else).
  Geometry-faithful on purpose: the wrap layout decides where the count-based Shift+Arrow
  selection ends, so the demo drop spot AND the corner-handle grab FRACTION + destination are
  kept verbatim (HandleMorph.nonFloatDragging is grab-offset-preserving → recorded extent to
  the pixel; the trick is banked in MACRO-PATTERNS). Also banks the font-size PromptMorph idiom
  (select old 2-digit value with Shift+ArrowLeft×2, overtype, Ok on the captured prompt).
- [x] MIGRATE-REP **textMorph2CaretResizing** (470 cmds, 25 steps, 4 shots) — the caret
  resizes with font-size changes. Represents:
  - [x] DROP **stringMorph2CaretResizing** (single-line sibling, same rule).
  → `macroTextWdgtCaretResizing` (Batch 46; 4 shots, 1:1). The real mechanic (grounded on
  the shots — there is NO font-size step): the demo TextMorph2 defaults to SCALEUP
  (TextMorph2.coffee:52, "expand to fill"), so each Shift+Arrow-select + Backspace deletion
  lets searchLargestFittingFont grow the font to re-fill the box — and the caret grows with it
  (CaretMorph.updateDimension sizes it from actualFontSizeUsedInRendering), glued to its slot
  through three monotone refits (~20→30→60→90px). Geometry-faithful fixture (the Batch-45
  handle-fraction trick) since wrap layout decides where the count-based selections end.
  Sibling glanced (all 4 shots): single-line StringMorph2, enables "←→ expand to fill" via the
  menu — the SAME togglefittingSpecWhenBoundsTooLarge that macroTextWdgtCaretKeepsCorrectAlignment
  asserts OFF-ward — then same caret-grows-with-font rule (shared StringMorph2/CaretMorph code);
  nothing uncovered, no fold needed. Original + sibling retired into migrated-originals/.
- [x] DROP **stringMorph2ShiftClickSelections** — `macroShiftClickExtendsSelection` (was
  migrated from the TextMorph2 sibling; same `mouseClickLeft`-reads-shiftKey rule).
  **REP-BLOCKED (Batch 38 glance):** beyond the covered shift-clicks, images 9/13/20–27 are
  Shift+Arrow KEYBOARD selections and image_5 is a Meta+A select-all — exactly the
  `stringMorph2ImprovedSelection` REP's rule (no dedicated macro yet; select-all appears only
  as fixture elsewhere). Retire only after that REP ships; fold a select-all beat into it.
  (UNBLOCKED + retired Batch 46: the REP shipped with the required Meta+A beat (image_19 —
  same caret-line-inside-the-highlight rendering as its image_5) plus the through-the-anchor
  cross (images 15-16 = its images 22-27); all 11 blocked shots re-glanced against the shipped
  REP — keyboard growth off collapsed carets, mid-text collapses, the 1-slot flips — every one
  a REP rule; the shift-click beats were already macroShiftClickExtendsSelection's.)
- [x] MIGRATE-REP **stringMorph2ImprovedSelection** — KEYBOARD selection (Shift+Arrow*)
  rendering as the asserted behaviour. No dedicated macro exists: `macroShiftClickExtendsSelection`
  is click-based, `macroCaretArrowKeyNavigation` moves the caret WITHOUT selecting, and
  `macroTextWdgtCutCopyPasteBasic` uses Shift+arrow selection only as fixture. Represents:
  - [x] DROP **stringMorph2ImprovedSelectionPartTwo** (same rule, more sequences)
  - [x] DROP **stringMorph2ImprovedSelectionPartThree** (same rule; glance its 14 shots —
    if a selection-rendering edge appears that the REP doesn't show, fold it in)
  → `macroStringWdgtImprovedSelection` (Batch 46; 19 shots = the original's 12 mapped 1:1 —
  incl. its own image_8 == image_11 byte-equality — PLUS 7 folded beats). The anchor model:
  Shift+Arrows grow a selection, plain arrows collapse to its left/right EDGE, bare Up/Down =
  Home/End single-line. Folded in: PartTwo's cancellation axis (image_13 grow-3-shrink-3 then
  typing INSERTS; image_14 a no-op arrow round-trip BYTE-IDENTICAL to image_13 — its images
  6==7) — all 7 of its shots glanced, the boundary-cancellation variants are the same anchor
  arithmetic; PartThree's axes (images 15-16 the moving end crossing THROUGH the anchor;
  images 17-18 plain Up/Down with a MID-TEXT selection collapsing to its edges — its
  byte-equal images 2==6==8 rule, and the capture reproduced the three-routes equality:
  images 13==14==17 share one dataHash) — all 14 of its shots glanced, its Shift+Up/Down
  extremes are the REP's own images 7-9/11; and the REQUIRED Meta+A select-all (image_19),
  which unblocked stringMorph2ShiftClickSelections above. Geometry-faithful fixture (drop
  spot, handle fraction, font-size prompt "3"→32, click fraction all verbatim — the counts
  hang off the one clicked slot). Original + both siblings retired into migrated-originals/.
- [x] DROP **stringMorph2ImprovedCaretPositioning** (27 shots of click→caret) — covered by
  `macroTextWdgtCaretPlacementByClick` + `…UnderAlignments` (this is the single-line case).
  (retired Batch 38 — glance confirmed: 26 clicks marching the caret along one giant-font line;
  the 0%-identical frames are nearest-slot rounding — same placement rule, denser sampling)
- [x] MIGRATE **tripleClickSelection** — PROMOTED from DROP (Batch 38 glance):
  `macroDoubleAndTripleClickThroughCaretWdgt`'s fixture is the one-line text "aa aa", so its
  "triple = whole line" cannot distinguish line-scoped from whole-text selection; this
  recording's images 5+ triple-click a WRAPPED multi-line TextMorph2 and select ONLY the
  clicked visual line (image_6: one mid-paragraph line highlighted). The per-visual-line
  scoping of TRIPLE-click in wrapped text is unasserted (`macroDoubleClickSelectsWord` does
  per-line for double only). Tiny macro: wrapped text, triple two different lines.
  → `macroTripleClickSelection` (Batch 42; 11 shots — the recording's 13 held 10 distinct).
  Grew past "tiny" because the recording asserts MORE than the wrapped-line beat: StringMorph2's
  own mouseTripleClick is selectAll (images 2-4), the empty separator line selects just its
  newline (image_8), and after "✓ soft wrap" + "→← shrink to fit" the unit becomes the LOGICAL
  line/paragraph (images 12-13) — all kept. Two byte-equality pairs distill the originals'
  x-irrelevance repeats (image_3==2 selectAll; image_6==5 same wrapped line, two click points —
  safe across click points because text morphs add no hover pixels). Fixture mirrors
  macroDoubleClickSelectsWord but keeps two (trimmed) paragraphs; toggles via direct
  toggleSoftWrap()/togglefittingSpecWhenBoundsTooSmall() (TextMorph2 menu not synthetically
  reachable; the CROP→SCALEDOWN shrink load-bearing — a cropped TextMorph2 opens the "edit:"
  prompt instead of an inline caret). supportsTurboPlayback:false + requiresSlowPlayback:true.
  Original retired into migrated-originals/.
- [x] DROP **textMorph2CutCopyPastePartTwo** (35 shortcuts/32 pastes) — torture-length
  variant of `macroTextWdgtCutCopyPasteBasic`; no new rule.
  (retired Batch 38 — glance confirmed: repeated Meta+x/Meta+v of the asserted mechanics;
  also a native-only-references straggler, no SWCanvas refs)
- [x] DROP **stringSelectionBasic** — NOT covered-by-macro: drop-as-OBSOLETE (legacy old
  StringMorph selection; the StringMorph2 family superseded it). Owner confirms this one.
  (retired Batch 38 — glance confirmed: digest shows legacy `StringMorph#4001`, not StringMorph2)
- [x] MIGRATE **textRelayoutsCorrectlyOnResize** (721 cmds, 11 steps, 3 shots) — text
  re-wraps when its widget is resized via handles. No DEDICATED macro asserts this (it is
  only exercised incidentally by fixtures that resize a TextMorph2); tiny, so author the
  dedicated macro: resize handle drag → reflow shot, twice.
  → `macroTextRelayoutsCorrectlyOnResize` (Batch 42; 3 shots, 1:1). NB the recording's widget
  is the OLD TextMorph family (the demo "text" Lorelei, maxTextWidth 300) — making this the
  suite's only dedicated old-TextMorph assertion: _applyExtentAndNotify keeps only the drag's x
  (→ maxTextWidth, TextMorph.coffee:235) and reLayout re-derives height from the line count
  (:118-131), so both releases' y are deliberately absurd (30px under the top; 220 with the
  column running far past) and both times height follows content. Real user path throughout
  (world menu create + carry-drop + resize/move… corner-handle drags, mode kept on so the
  handles show as recorded). Original retired into migrated-originals/.
- [x] MIGRATE **softWrapping** — PROMOTED from DROP (Batch 38 glance): the toggle beat IS
  covered (`macroSoftWrapTogglesTextReflow`), but images 7–10 show the no-wrap box growing /
  shifting LEFT to x=0 after line-join edits, with line fragments clipped at BOTH edges and
  the caret far right — a no-wrap box-growth / on-screen-repositioning / caret-visibility
  interplay no macro asserts (the caret-into-view macros are scroll-panel ones;
  `macroNonWrappingTextResizesToContent` only asserts box-follows-content). Needs a
  framework-source check of what drives the leftward growth before authoring.
  → `macroSoftWrapping` (Batch 42; 5 shots distilling the 10). The source check root-caused
  the "growth": the box extent NEVER changes — it is CaretMorph.gotoSlot's desktop
  caret-into-view SLIDING the whole morph (CaretMorph.coffee:128-142, the non-scroll-panel
  branch; _moveLeftSideTo), triggered when an edit/navigation parks the caret beyond the
  world's padded view (in the recording via clicks BELOW the text — slotAtRow's row-overflow
  guard clamps those to the text END — and line-joins), reversed when the caret lands near a
  line start; SCALEDOWN meanwhile re-fits the FONT each edit, and some "clipped-at-both-edges
  fragments" are simply real split fragments. Macro beats: wrapped baseline → truncate +
  no-wrap + shrink-to-fit single clipped line (box unchanged) → two Backspace/Enter splits →
  ArrowDown-on-last-line (downFrom clamps to text end) slides the box off-canvas left, caret
  at the world's right edge beyond the box's painted width → Enter slides it all back.
  Choreography is font-refit-robust (one live-point click on line 1; keys for the rest; tail
  sized to overshoot the world edge yet keep the slid box partly visible). Also corrected
  macroSoftWrapTogglesTextReflow's prose en passant (its image_2 box does NOT grow — the
  no-wrap line CROPS with an ellipsis; reference unchanged). Original retired into
  migrated-originals/.
- [x] DEEP-DIVE **textMorph2LongEditingSession** (6578 cmds, 262 steps, 41 shots!) — the
  endurance omnibus: typing, shortcuts, paste, double/triple-click, menus. Deep-dived
  (Batch 60) → walked all 41 native dpr-1 shots (the recording shipped only 4 reference
  families, no SWCanvas; it sat in SWCanvasBrokenTests at BOTH densities — both entries
  removed with it). The session's spine: the fixture lives in EXPAND-TO-FILL (SCALEUP), so
  the font auto-rescales all session (down on growth, up after mass deletes) while the
  recording tours selections, clipboard, all six alignments, the fill-mode trio and
  bold/italic. Every endurance beat mapped to a shipped macro's assertions (CaretResizing,
  CutCopyPasteBasic, DoubleClickSelectsWord, TripleClickSelection, ShiftClickExtends-
  Selection, StringMorph2ImprovedSelection, CaretArrowKeyNavigation, StringMorph2Alignments,
  CaretPlacementUnderAlignments, CaretKeepsCorrectAlignment, CaretResizesOKOnUndo,
  ShrinksToFitLongToken) EXCEPT four residue laws asserted nowhere: (1) mid-session
  fill-mode SWITCHING (togglefittingSpecWhenBoundsTooLarge SCALEUP→FLOAT snap; SCALEDOWN
  armed on the VERTICAL-overflow axis — ShrinksToFitLongToken is the width axis), (2) BOLD
  pixels + the bold/normal-weight round-trip (only ITALIC was asserted), (3) PASTE-OVER-
  SELECTION (CaretMorph insert deleteSelection()s first; CutCopyPasteBasic pastes only at a
  bare caret), (4) TextMorph2 block BOTTOM vertical alignment. Owner call taken: DROP the
  recording + author the residues FRESH → the 9-shot
  **macroTextWdgtFillModesWeightAndPasteOverSelection** (image_7 byte-IDENTICAL to
  image_5 — the weight round-trip leaves zero residue, the no-op idiom). Mystery solved en
  route: the recording's image_21 shows a stray "edit:" PromptMorph — its 18th paste
  overflowed the box under default CROP, and a click on a CROPPED TextMorph2 opens the edit
  prompt instead of an inline caret; the macro arms SCALEDOWN before overflowing, so it
  explains the accident rather than reproducing it. No new verb; 6/6 repeated headless runs
  green across both dprs. Original retired into migrated-originals/.

## Cluster E — inspector

- [x] DEEP-DIVE **duplicationOfLinkedInspector** (957 cmds, 30 steps, 3 shots) — duplicate
  an inspector that is LINKED to a target; which links the copy keeps is genuinely novel
  semantics. Deep-dived (Batch 54) → MIGRATED as the fresh
  **macroDuplicatedInspectorDrivesCopiedTargetOnly** (3 shots, beats 1:1). Source reading
  done: InspectorMorph.coffee:21 (@target is the ctor arg), :454-462 (save evaluates
  "this.<prop> = <txt>" against @target) — so WHICH rectangle fades on an alpha edit probes
  the link directly. The duplicate-with-inspector composite and the controller remap are
  covered (macroDuplicateComplexWidgetRidesHand, macroSlidersControlTextWidget), but the
  inspector @target remap was asserted nowhere (macroDuplicatedInspectorsCloseIndependently
  duplicates an inspector whose target is OUTSIDE the copied subtree). The macro: panel +
  rectangle + old inspector (opened via the rectangle's hierarchy menu, moved into the
  panel), duplicate the panel, edit alpha through EACH inspector — left-only (0.25) then
  right-only (0.6) changes prove the remap in both directions. Retired.
- [x] DEEP-DIVE **morphsHighlighting** (1162 cmds, 28 steps, **18 shots**) — the
  hover/highlight state corpus. `macroTargetingHighlightsCandidateWidget` covers the
  targeting hover only. Deep-dived (Batch 55) → MIGRATED as the FRESH 5-beat
  **macroHierarchyMenuHoverHighlightsExactSubtree**. Only 13 unique states (images 3-8 are
  six byte-identical shots; the dropped alt-keys were inert). The recording: the world's
  old inspector grown huge, four right-click origins (title text, list row, slider button,
  footer label), hovering the ▪-marked hierarchy-menu items — its Δ-ladder (detail-pane
  trio: ScrollPanel-only 33% → whole-inspector 54% → cleared 85%) is the law. The TRIGGER
  is the covered macro's exact path (MenuItemMorph.coffee:70-78/85-94); unasserted were the
  subtree-exact GEOMETRY on a nested composite, hover-tracking between items, and
  clear-on-leave. The macro asserts all three on an authored panel>box>rectangle nest
  (terracotta rect so every level reads), closing with image_5 ≡ image_1 — the no-trace
  clear, byte-identical at both dprs. Retired.
- [x] DROP **attachRectangleToPartsOfInspector** — attach mechanics fully covered
  (`macroAttachResizingHandleToWidget`, overlap rule, choose-by-prefix); aiming at inspector
  parts adds fixture, not rules. (retired Batch 38 — glance confirmed: attach to the
  inspector then to its ListMorph part, composite drags as a unit; all asserted elsewhere)
- [x] MIGRATE **inspectorResizingOKEvenWhenTakenApart** — the COMPOSITE rule (resizing
  still works AFTER parts were picked out) is exactly what neither dedicated macro asserts
  (`macroResizingPristineInspector` resizes a pristine one; `macroPickingUpPartsFromInspector`
  takes apart without resizing). Cheap to author: compose those two proven patterns.
  → `macroInspectorResizingOKEvenWhenTakenApart` (Batch 43; 6 shots, 1:1). The mechanic is
  doLayout's per-part `parent == @` guards + the list→detail and close-button wiring running on
  object references (detached parts keep working; the detached close button still closes the
  gutted body). GOTCHA banked in MACRO-PATTERNS: mode handles attach to their TARGET and every
  handle drag runs target.bringToForeground(), so after a body-resizer drag the global
  topmost-first handle lookup grabs the BODY's resizer — scope the mode-handle lookup to the
  target's subtree (the first capture grew the body right over the list this way).
- [x] DROP **moreUnpluggingOfInspectorParts** — "more of" `macroInspectorScrollbarUnplugged`
  + `macroPickingUpPartsFromInspector`. (retired Batch 38 — glance confirmed: pick-out,
  unplugged/duplicated sliders driving the list, and the duplicated-close-fires beat = the
  duplicated-part-keeps-its-target wiring `macroInspectorScrollbarUnplugged` image_3 asserts)
- [x] DROP **longTextScrollsWell** — long text in the inspector detail pane scrolls; scroll
  mechanics are the most-covered family in the suite. (retired Batch 38 — glance confirmed:
  list + detail-pane bar-drag scrolls only, tiny local Δprev boxes, no novel rule)
- [x] MIGRATE **wrappingTextFieldResizesOK** — a wrapping StringFieldMorph (text FIELD)
  resizing/re-wrapping. No dedicated macro: fields appear only as fixture inside prompt
  popovers. Author the small dedicated macro.
  → `macroWrappingTextFieldResizesOK` (Batch 43; 6 shots — the recording's 7 minus its 9px
  nudge-resize near-duplicate). CORRECTION to this note: the PNGs show NO StringFieldMorph —
  the "wrapping text fields" are the OLD inspector's detail + work panes (isTextLineWrapping
  ScrollPanelWdgts holding editable old TextMorphs) typed full and resized 5 times via the
  inspector's own corner resizer; the rule is the _applyExtentAndNotify → adjustContentsBounds re-wrap
  (+ scrollbars exactly when the text outgrows its pane). GOTCHA banked: clicking an EMPTY old
  TextMorph crashes under SWCanvas (slotAt has no row/col guard → measureText(undefined)) —
  focus with a direct edit() call; the first capture shipped an Error-log window into the
  references and still "verified" (deterministic crash = self-consistent), the eyeball caught it.
- [x] MIGRATE **multilineTextInputScrollsWell** — typing multiline text auto-scrolls the
  input area. No dedicated macro asserts the auto-scroll-while-typing behaviour
  (`macroInspectorWorkAreaEvaluatesCoffeeScript` edits without asserting scroll). Author it.
  → `macroMultilineTextInputScrollsWell` (Batch 43; 2 shots, 1:1 — the recording's own seven
  typed lines). The growth variant of the caret-into-view family: typing Enters grows the text
  past the ~3-line work pane and gotoSlot's scroll-panel branch tracks the tail; the bar-drag
  back up does NOT recall the caret. The recorded original was SWCanvas-BROKEN at both
  densities precisely because its click into the empty work-pane TextMorph hits the slotAt
  measureText crash (native canvas survives by coercing undefined) — the edit()-focused macro
  RESTORES SWCanvas coverage; its two SWCanvasBrokenTests entries removed with the retirement.
  Grounded on the original's native dpr-1 refs (cross-backend, qualitative).

## Cluster F — scroll panels misc

- [x] MIGRATE **resizingScrollFrameThenImmediatelyScrollingTheHandlesDontStickToScrollPanelContent**
  (989 cmds, 20 steps, 3 shots) — regression: after resizing a scroll frame, immediate
  scrolling must not leave the handles stuck to content. Crisp and novel.
  DONE (Batch 44) → `macroResizingScrollFrameThenImmediatelyScrollingTheHandlesDontStickToScrollPanelContent`,
  3 shots 1:1. The guard verified in src: ScrollPanelWdgt.wheel's FIRST act destroys
  world.temporaryHandlesAndLayoutAdjusters (ScrollPanelWdgt.coffee:540-542 — the src comment
  names the regression verbatim); the handles park on the FRAME ("resize/move..." recurses up
  from a non-freefloating widget, and ScrollPanelWdgt.add's HandleMorph carve-out keeps them out
  of the scrolled contents), so image_3 = handles GONE + view clamped at the content bottom.
  Fixture built via the very creator methods the recording's pinned test menu called
  (createSimpleDocumentScrollPanelWdgt + 2× createNewWrappingSimplePlainTextWdgtWithBackground,
  dragged in with real input drags) — image_1 came out BYTE-IDENTICAL to the original's
  reference; the recording's pinned 'others' menu (creation scaffolding only) is the one
  qualitative difference. Menu gotcha banked in MACRO-PATTERNS: the doc's full-width cells make
  any in-doc right-click open the hierarchy menu (the recording threaded the inter-cell gap) —
  navigate it ("a SimpleDocumentScrollPanel" → resize/move...) instead.
- [x] DROP **autoScrollingForScrollPanels** — `macroListWdgtAutoScrollsNearDraggedEdge`
  (ListMorph IS a ScrollPanelWdgt; same `scrollBarsThickness*3` edge rule).
  Glanced (Batch 51, 6 shots): carried rectangle held near each edge of an overflowing text
  scroll panel, content panning toward the held edge with thumbs tracking — the macro's
  four-edge assertion verbatim, generic-panel instance.
- [x] DROP **ScrollPanelResizesCorrectlyWithChangingTextInside** — `macroScrollBarsTrackContentChange`.
  Glanced (Batch 51, 3 shots): string grown by typing → h-bar appears/thumb resizes; tall
  text added → v-bar appears — the bars-appear-on-overflow + thumb-tracks-dimension assertion.
- [x] DROP **ScrollPanelUpdatesScrollBarsWhenContentInsideChangesDimensionOrPositionPartTwo**
  — PartOne already migrated to `macroScrollBarsTrackContentChange`.
  Glanced (Batch 51, 5 shots): font-90 growth (dimension) + the text widget dragged to the
  bottom-right corner (position, the macro's own image_3 beat). Its dpi2 SWCanvasBrokenTests
  entry (line 51 — found by the pre-retirement grep; the digest's 5-not-6 refs were the tell)
  removed in the same commit.
- [x] DEEP-DIVE **ScrollPanelVariousScrollingMethods** (4047 cmds, 79 steps, **24 shots**) —
  the scrolling omnibus. Deep-dived (Batch 59) → walked all 24 shots: drop-in/out and
  in-panel drags ≡ macroCompositeDragsAsUnitIntoScrollPanel; V+H scrollbar-button drags ≡
  the thumb-drag ground (macroMultilineTextInputScrollsWell image_2,
  macroInspectorScrollbarUnplugged); the panel float-move ≡
  macroScrollPanelNotMovedViaNonFloatDragChild; NO wheel/track-click/keyboard scrolling in
  the recording (its 46 keypresses were inspector-eval typing). The ONLY uncovered methods:
  the two drag-to-scroll FLAGS the recording switched on via the inspector work-area eval —
  canScrollByDraggingBackground (bg drag PANS instead of moving the panel; distinct from
  the LOCK path) and canScrollByDraggingForeground (a held drag ON a content widget pans
  instead of float-dragging it out), ScrollPanelWdgt.coffee:23-24 / PanelWdgt.coffee:143 /
  Widget.coffee:2520 → MIGRATED as the fresh 3-shot
  **macroScrollPanelDragToScrollFlags** (flags set directly per the established idiom; both
  pans driven by real held drags; both flags gated on visible scrollbars, so the fixture
  rect is BIGGER than the viewport — a first capture with a smaller rect taught that pans
  clamp at the content edge and bars hide when the content fits again). The recording had
  only 4 reference families (no SWCanvas refs — it sat in SWCanvasBrokenTests at BOTH
  densities; both entries removed with it). Retired.

## Cluster G — layout

- [x] MIGRATE-REP **layoutsAndVisibility** (1233 cmds, 21 steps, 1 shot) — hide/show of
  cells inside a stack redistributes space (`macroHideUnhideWidgetChain` covers hide/show
  alone; the layout interplay is new). Single screenshot = single crisp assertion.
  DONE (Batch 47) → `macroLayoutsAndVisibility`, 5 shots (the recorded final shot + 4 folded
  intermediates the original couldn't show). The plan note above was WRONG (the Batch-46
  lesson again — grounded on src before authoring): hide does NOT redistribute — the stack
  layout is visibility-blind (`doLayout`'s three distribution loops filter by layoutSpec only,
  Widget.coffee:4334/4358/4392; `hide()`/`show()` never call invalidateLayout) so the hidden
  cell's slot is KEPT (the holder's grey background shows through), it keeps receiving its
  share when the holder is resized while hidden, and show() paints straight back into the kept
  slot — hide/show at a fixed size is BYTE-EQUAL (image_3 ≡ image_1, both dprs), and
  hide→resize→show ends as if never hidden (image_5 ≈ the original's single shot). Fixture =
  setupTestScreen1's SECOND holder built directly (green|divider|blue, equal spreadability,
  lone HandleMorph — the macroLayoutBasicProportions distillation); blue.hide()/show() driven
  directly (the macroHideUnhideWidgetChain convention; the recording's inspector-eval show()
  detour and its pinned-gallery drag dropped as scaffolding). Was in BOTH SWCanvasBrokenTests
  density lists (hence native-only old refs — cross-backend comparison page); both entries
  removed with the retirement.
- [x] DEEP-DIVE **layoutsAndCollapsing** (1991 cmds, 35 steps, 4 shots) — collapsing
  morphs inside layouts. Sibling of the visibility rep — do it right after, reusing the
  fixture; deep-dive only because collapse-in-layout needs a framework-source check.
  NOTE (Batch 47): the framework-source check is effectively DONE — `getDesiredDim`/
  `getMinDim`/`getMaxDim` gate on `isCollapsed()` (Widget.coffee:4089-4098, zeroing the dims),
  so collapse DOES redistribute, the exact contrast to the visibility REP; and
  `macroLayoutsAndVisibility`'s fixture block was written to be reused verbatim. Strong
  Batch-48 candidate.
  DONE (Batch 48) → `macroLayoutsAndCollapsing`, 5 shots mirroring the visibility macro's arc
  shot-for-shot (fixture reused VERBATIM): collapse → green takes the WHOLE width (recorded
  image_1's mechanic — the divider rides to the right edge, no gap), unCollapse → BYTE-EQUAL
  to the baseline (image_3 ≡ image_1, both dprs), collapse + resize-while-collapsed → still
  all-green at the new size (recorded image_3), unCollapse → split at the new size (recorded
  image_4). Deep-dive resolution: collapse()/unCollapse() (Widget.coffee:1883/1895) BOTH call
  invalidateLayout() — the other half of the contrast with hide()/show(), which call neither.
  VERIFIED CROSS-TEST: image_1/image_5 byte-identical (same dataHash, both dprs) to
  macroLayoutsAndVisibility's image_1/image_5 — the contrast pair shares exact endpoints.
  collapse()/unCollapse() driven directly (the very methods the context 'test menu' items
  call, Widget.coffee:3284-3288; the recording's inspector-eval unCollapse + gallery drag
  dropped as scaffolding). Was in BOTH SWCanvasBrokenTests density lists (native-only old
  refs — cross-backend comparison page); both entries removed with the retirement.
- [x] MIGRATE **stringMorph2AndTextMorph2ResizingInLayout** (50 steps, 7 shots) — text
  widgets resizing/reflowing INSIDE stack layouts. No dedicated macro: the layout macros use
  plain rectangles as cells, the text-resize macros run outside layouts. Distill to one
  stack with a StringMorph2 + a TextMorph2 cell, resize the holder, assert the reflow.
  DONE (Batch 44) → `macroStringWdgtAndTextWdgtResizingInLayout`, 7 shots 1:1 — the
  recording already WAS the plan's distillation (the demo rectangle is the holder). Mechanic
  verified in src: "attach with horizontal layout" (Widget.attachWithHorizLayout:3684 →
  newParentChoiceWithHorizLayout → holder.add child, ATTACHEDAS_STACK_HORIZONTAL_*) turns the
  rectangle into a horizontal stack; holder resizes through the real corner handle re-wrap the
  TextMorph2 to its half-width cell (font re-fits smaller when narrowed); StringMorph2 cell
  honours align center/middle + shrink-to-fit (decorated labels → substring match) and in-place
  caret editing (the recording's [0.466,0.513] click + Shift+ArrowRight×3 + "AAA" reproduced the
  IDENTICAL edit result). Fixture through the REAL demo/test menus (world.create rides the hand;
  drop spots verbatim — the corner overlaps make the rectangle an attach target); images 1-3
  came out BYTE-IDENTICAL to the original's references, 4-7 differ only by the handle
  grab-point delta. Locator gotcha: TextMorph2 extends StringMorph2 — exclude it when grabbing
  the string ref.

## Cluster H — the stack/document reflow cross-product (~30 tests)

These are one mechanic family replayed across containers: SimpleDocument (SD),
width-CONSTRAINING stack (WC), width-NON-constraining stack (WN), NON-constraining SCROLL
stack (WNS), bare SimplePlainText (PT), SimplePlainText SCROLL panel (PTS). The mechanic
kernels already shipped: grows-with-content, shrinks-on-removal, icon-in-flow, indented
paragraph, centered-when-alone, caret-into-view, dropped-widgets-keep-size, bars-track-content.
Plan: migrate the four UNCOVERED mechanics once each (container choice noted), then retire
the rest of the matrix as covered. **REP macros should note "representative for <siblings>"
in provenance.**

New-mechanic representatives:
- [x] MIGRATE-REP **SimpleDocumentAllReflowsCorrectlyAsIChangeFontSize** — reflow on
  font-size change in a flow container (no macro covers font-size reflow). Represents:
  DONE (Batch 47) → `macroSimpleDocumentAllReflowsCorrectlyAsIChangeFontSize`, 8 shots =
  the recorded 6 beat-for-beat (document demo built directly with its default paragraph,
  two wrapping-lorem demos dropped in + the recording's own REORDER drag → lorem/small/lorem
  reproduced line-for-line; 'font size...' prompt Meta+a-overtype to 90; 3-wheel tour of the
  reflowed flow to the clamped end) + a 2-shot folded coda: wheel back to top (image_7 ≡
  image_3 BY BYTE-EQUALITY — the tour round-trips exactly) and font back to the
  SimplePlainTextWdgt DEFAULT 12 (image_8 ≡ image_2 BY BYTE-EQUALITY — the reflow is exactly
  reversible; absorbs the scroll-stack sibling's shrink axis). The recording's pinned
  'others 2' menu (in every original shot) dropped as scaffolding.
  - [x] DROP **WidthContrainingVerticalStackPanelAllReflowsCorrectlyAsIChangeFontSize**
    — glanced (6 shots): same wrap-to-width font reflow in the GROWING bare stack + a
    stack-resize re-wrap; growth-on-content-change = macroVerticalStackPanelGrowsWithContent,
    resize-re-wrap = macroStringWdgtAndTextWdgtResizingInLayout, the font trigger = the REP.
  - [x] DROP **WidthNONContrainingVerticalStackPanelAllReflowsCorrectlyAsIChangeFontSize**
    — glanced (6 shots): free-width stack, non-wrapping lorems — the font change makes the
    text wider and it CLIPS at the stack bounds (no re-wrap); free-width premise =
    macroFreeWidthScrollStackShowsHorizontalScrollbar, trigger = the REP. (Its font prompt
    driven via the prompt's SLIDER — the same PromptMorph slider machinery the
    transparency-prompt macro drives.)
  - [x] DROP **WidthNONContrainingVerticalScrollStackAllReflowsCorrectlyAsIChangeFontSize**
    — glanced (8 shots): scrollbars (incl. the free-width H-scrollbar) tracking font-driven
    growth AND shrink-back; bars-track-content = macroScrollBarsTrackContentChange +
    macroFreeWidthScrollStackShowsHorizontalScrollbar; the SHRINK axis folded into the REP's
    byte-equal back-to-default coda.
- [x] MIGRATE-REP **SimpleDocumentRemovingLastParagraphUpdatesScrollbarAndLeavesViewportAtEndOfDocument**
  — viewport/scrollbar behaviour at the END of the document on removal; pair it with the
  add-at-end beat in ONE macro (add-then-remove arc). Represents (and retires) both:
  DONE (Batch 48) → `macroSimpleDocumentRemovingLastParagraphUpdatesScrollbarAndLeavesViewportAtEndOfDocument`,
  7 shots = the recorded 5 beat-for-beat (doc recipe + identical lorems; wheel clamps at the
  end; remove-last while end-anchored → the doc region (text AND thumb) returns EXACTLY to
  the pre-add state, the freed paragraph keeps the doc's wrap width on the desktop;
  remove-until-fits → scrollbar GONE + re-anchored top; down to the bare default paragraph)
  + the folded add-at-the-end beat (a 3rd identical lorem dropped into the last visible
  paragraph's span while scrolled at the end → scrollbar-only delta, then wheel to the new
  end → viewport text pixel-identical to the old end, smaller thumb). Mechanic verified in
  src: reactToDropOf/reactToGrabOf (ScrollPanelWdgt.coffee:236/240) re-run
  adjustContentsBounds (:244, whose :277-290 comment NAMES the remove-at-the-bottom
  scenario — shrink-wrap the stack) + keepContentsInScrollPanelWdgt (:328 — bottom-clamp
  pins an end-anchored view to the end; grow-to-viewport :302 + top-clamp re-anchors at the
  top once content fits) + adjustScrollBars (hides the bar when nothing overflows). The
  recording's pinned 'others 2' menu dropped as scaffolding. NOTE (vs the plan's one-liner):
  a SimpleDocument paragraph IS directly float-draggable (the recording's own dragFloats;
  Batch 47's reorder gesture) — pickUpPartToDesktop was NOT needed, so its 5th-copy
  promotion question did not arise this batch.
  - [x] DROP **SimpleDocumentScrollbarUpdatesAndFollowsContentAddedAtTheEnd** (absorbed as
    the REP macro's add-at-end beat) — glanced (5 shots): doc + 2 lorems, wheel to end,
    caret clicked into the last paragraph, Enter ×7 then ×11 → the doc grows at the end,
    the thumb shrinks, and the view FOLLOWS the caret down. The scrollbar-updates-on-add
    half is the REP's images 3-4; the follow-the-caret half is scrollCaretIntoView =
    macroDocumentCaretBroughtIntoViewWhenMoved's dedicated mechanic (typing moves the caret
    → gotoSlot → scrollCaretIntoView).
  - [x] DROP **WidthNONContrainingVerticalScrollStackRemovingLastParagraphUpdatesScrollbarAndLeavesViewportAtEndOfDocument**
    — glanced (4 shots): the same end-anchored removal arc in the free-width scroll stack
    (2 lorems kept at their 500px staged width, H-scrollbar present throughout; remove-last
    while at the end → content fits → re-anchored top, V-bar gone, freed paragraph keeps its
    width). End-anchoring = the REP; the free-width premise (kept width + H-scrollbar) =
    macroFreeWidthScrollStackShowsHorizontalScrollbar.
  - [x] DROP **WidthNONContrainingVerticalScrollStackScrollbarUpdatesAndFollowsContentAddedAtTheEnd**
    — glanced (6 shots): adds-update-the-V-scrollbar in the free-width stack (lorem1 then
    lorem2 dropped in, thumb shrinks each time), wheel to end, then a PAN by dragging the
    HORIZONTAL thumb right + wheel back up. Adds/end-anchoring = the REP; free-width +
    H-scrollbar = macroFreeWidthScrollStackShowsHorizontalScrollbar (which pans by
    horizontal WHEEL; the thumb-DRAG is the same SliderMorph→scrollX offset machinery,
    and the thumb-drag gesture itself is dedicated ground of
    macroSliderTrackClickMovesButton / the V-bar drag entries).
- [x] MIGRATE-REP **WrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo**
  (desc: "enlarge then shrink the font *when completely scrolled down*") — font-size change
  while scrolled to the bottom keeps the viewport sane.
  DONE (Batch 49) → `macroWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo`,
  4 shots = recorded 3 beat-for-beat + an explicit pristine baseline (justified by the
  recording's own filenames: its final image_3 dataHash = the WrappingUnwrapping recording's
  pristine image_1 = the untouched fixture). The slider-dragged enlarge became the
  deterministic banked prompt dance (Meta+a + "28" + Ok); 'font size...' sits at TOP level
  (the panel's takesOverAndCoalescesChildrensMenus coalesces the locked text's items — no
  hierarchy descent). image_4 ≡ image_1 byte-for-byte at both dprs (the end-scrolled shrink
  re-anchors at top + hides the bar — content fits again), and image_1/image_4 reproduced the
  recorded pristine dataHashes exactly. Represents:
  - [x] DROP **NonWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo** (same twist, no-wrap)
    — glanced (4 shots): no-wrap fixture (2 giant clipped lines, H-bar) → huge slider enlarge
    (both bars) → wheel to V-end → overtype 12 at the bottom, its image_4 ≡ image_1
    (dataHash a376f4dc…, the same wrap-agnostic clamp restore as the REP's image_4≡image_1);
    the no-wrap premise (unbounded lines, H-overflow bars) is macroNonWrappingTextResizesToContent's
    + macroScrollBarsTrackContentChange's dedicated ground.
- [x] MIGRATE-REP **SimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent**
  — toggling wrap while scrolled at the bottom (uses paste+shortcuts; clipboard verbs exist).
  DONE (Batch 49) → `macroSimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent`,
  5 shots beat-for-beat, fixture block shared VERBATIM with the font REP (their image_1s are
  byte-identical cross-test). Clipboard quadrupling (Meta+a / copySelection / ArrowRight /
  pasteText ×3 — caret-follow lands the end-clamp, no wheel) then the toggles through the REAL
  coalesced menu: the items are SimplePlainTextWdgt's OWN softWrapOff/softWrapOn
  (:103-117, lone-child gate :90-98) — NOT TextMorph2.toggleSoftWrap, and the in-panel
  synthetic right-click DOES open the menu (the bare-TextMorph2 drift doesn't apply; matched
  by substring for the ☒/☐ decoration). image_5 ≡ image_2 byte-for-byte; ALL FIVE shots
  reproduced the recording's reference dataHashes at both dprs (pixel-exact migration).
  Represents:
  - [x] DROP **PlainTextScrollPanelSwitchingWrappingOnAndOff** (the plain toggle, mid-content)
    — glanced (3 shots): the dual wrapping+non-wrapping panel pair, both wrap states swapped
    then swapped back at the top of content, image_3 ≡ image_1 (dataHash 5ab48df0…). The
    toggle-reflows-now law is macroSoftWrapTogglesTextReflow's dedicated ground; the bar swap
    on unwrap and the exact-restore round trip are the REP's image_3 / image_5≡image_2.

Covered-matrix retirements (each: 2-minute glance, then move to `migrated-originals/`):
- [x] DROP **SimpleDocumentAllReflowsCorrectlyAsIAddAndRemoveTextContent** — grows/shrinks +
  caret-edit reflow covered (`macroVerticalStackPanelGrowsWithContent`/`…ShrinksOnParagraphRemoval`).
  Glanced (Batch 51, 7 shots): a sentence typed mid-paragraph pushes the flow down, a
  selection-deleted paragraph pulls it back up — grow/shrink via the caret trigger.
- [x] DROP **SimpleDocumentCanAddCenteredIconInMyText** — `macroIconDroppedIntoDocumentFlows`
  + `macroCenteredWidgetStaysCenteredWhenAlone`.
  Glanced (Batch 51, 3 shots): heart in flow below text → repositioned to top → centered;
  both named assertions, nothing else.
- [x] DROP **SimpleDocumentUpdatesCorrectlyWhenElementsAreDeleted** — element deletion ≈
  shrinks-on-removal; `macroVerticalStackPanelShrinksOnParagraphRemoval`.
  Glanced (Batch 51, 6 shots, image_2 ≡ image_3): strings and paragraphs deleted one by one,
  the flow re-stacking up each time — the shrink law via the delete trigger.
- [x] DROP **WidthContrainingVerticalStackPanelAllReflowsCorrectlyAsIAddAndRemoveTextContent**,
- [x] DROP **WidthNONContrainingVerticalStackPanelAllReflowsCorrectlyAsIAddAndRemoveTextContent**,
- [x] DROP **WidthNONContrainingVerticalScrollStackAllReflowsCorrectlyAsIAddAndRemoveTextContent**
  — same add/remove reflow, other containers.
  Glanced (Batch 51, 3+6+6 shots): typed growth pushing each stack down, deletions collapsing
  cells to strips; the scroll-stack variant adds bars resizing with content
  (`macroScrollBarsTrackContentChange`'s ground). All three pure grow/shrink instances.
- [x] DROP **WidthContrainingVerticalStackPanelCanAddIconInMyText**,
- [x] DROP **WidthContrainingVerticalStackPanelCanAddCenteredIconInMyText**,
- [x] DROP **WidthNONContrainingVerticalStackPanelCanAddIcon**,
- [x] DROP **WidthNONContrainingVerticalScrollStackCanAddIcon** — icon-in-flow covered
  (`macroIconDroppedIntoDocumentFlows`; WC variant adds wrapping, already proven by
  `macroVerticalStackPanelGrowsWithContent` fixtures).
  Glanced (Batch 51, 3+4+6+3 shots): heart flows into each container; the WC-centered variant
  re-centers through a panel-resize re-wrap (the centering invariant + the WC width-constraint
  scaling the icon); the WNC variant's narrow-resize CLIPS the cells, icon staying in flow.
- [x] DROP **WidthContrainingVerticalStackPanelCanAddIndentedParagraph** —
  `macroSimpleDocumentCanAddIndentedParagraph`.
  Glanced (Batch 51, 4 shots): paragraph narrowed then pushed to the right edge with the
  stack reflowing below — the macro's image_2/image_3 choreography in the WC stack.
- [x] DROP **widgetsCenteredInWidthContrainingVerticalStackPanelRemainCenteredWhenAlone** —
  `macroCenteredWidgetStaysCenteredWhenAlone`.
  Glanced (Batch 51, 3 shots): lorem dragged out leaves the centered heart ALONE and still
  centered — the macro's literal assertion.
- [x] DROP **widgetsDroppedInWidthContrainingVerticalStackPanelTakeTheEffectiveSizeTheyHadWhenDropped**,
- [x] DROP **widgetsDroppedInWidthNONConstrainingVerticalStackPanelTakeTheEffectiveSizeTheyHadWhenDropped**,
- [x] DROP **widgetsDroppedInWidthNONContrainingVerticalScrollStackTakeTheEffectiveSizeTheyHadWhenDropped**
  — `macroDocumentPreservesDroppedWidgetSizes`.
  Glanced (Batch 51, 4+7+6 shots): distinct-size hearts keep their dropped sizes in all three
  containers (the macro's distinct-sizes assertion); panel resizes then show the contrast —
  WC scales children with the panel, WNC clips without touching them.
- [x] DROP **WidthNONConstrainingVerticalStackPanelExpandsWhenContentAddedAtTheEnd** —
  `macroVerticalStackPanelGrowsWithContent` (the WC original of this very name was its source).
  Glanced (Batch 51, 7 shots): paragraphs appended at the end grow the panel each time —
  the macro's expansion assertion.
- [x] DROP **WidthNONContrainingVerticalStackPanelShrinksWhenRemovingLastParagraph** —
  `macroVerticalStackPanelShrinksOnParagraphRemoval`.
  Glanced (Batch 51, 5 shots): paragraphs dragged out float free and the stack shrinks to
  the remainder — the macro's assertion verbatim.
- [x] DROP **WidthNONConstrainingVerticalScrollStackContentsLocking** —
  `macroLockedDocumentRejectsDrop` + `macroLockedScrollPanelScrollsWhenDragged` (the
  SimpleDocumentContentsLocking original already migrated).
  Glanced (Batch 51, 7 shots, image_3 ≡ image_4 — the locked content-drag NO-OP, byte-equal):
  locked cells can't be dragged out, drags act on the parent panel instead — the lock-family
  laws the named pair asserts.
- [x] DROP **WidthNONContrainingVerticalScrollStackCaretBroughtIntoViewOnlyWhenMoved** —
  `macroDocumentCaretBroughtIntoViewWhenMoved` + `macroScrollPanelCaretBroughtIntoViewWhenMoved`.
  Glanced (Batch 51, 5 shots): caret placed at top, scrolled out of view (NOT brought back),
  one arrow-move scrolls it back in — the scroll-vs-move contrast both macros assert.
- [x] DROP **WidthNONContrainingVerticalScrollStackUpdatesCorrectlyWhenElementsAreDeleted** —
  as the SD elements-deleted drop above.
  Glanced (Batch 51, 5 shots, image_4 ≡ image_1 — an exact delete round trip back to the
  strings-only pristine): deletions pull the flow up and the scrollbar vanishes once content
  fits (`macroScrollBarsTrackContentChange`'s no-overflow ground).
- [x] DROP **NonWrappingSimplePlainTextResizesCorrectlyAsLinesAreBroken**,
- [x] DROP **NonWrappingSimplePlainTextResizesCorrectlyAsLinesAreDeleted**,
- [x] DROP **NonWrappingSimplePlainTextResizesCorrectlyAsTexSizeIsChanged** —
  `macroNonWrappingTextResizesToContent` (width=longest line, height=line count; the
  caret-edit and font-size variants change the trigger, not the rule).
  Glanced (Batch 51, 3+2+3 shots — TexSizeIsChanged native-only, it has no SWCanvas refs):
  Enter-broken lines re-fit BOTH dimensions (taller, narrower as the longest line shortens);
  deletions shrink both ways; font grow/shrink re-measures the same law. TexSizeIsChanged's
  TWO SWCanvasBrokenTests entries (dpi1 line 31 + dpi2 line 52) removed in the same commit.
- [x] MIGRATE-REP **WrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved** — a
  BARE wrapping text widget resizes its height to its content. Only indirectly covered
  (`macroWindowResizesToTextContent` asserts the WINDOW following; `macroNonWrappingTextResizesToContent`
  is the no-wrap rule). Author the bare-wrap dedicated macro, folding a font-size beat.
  DONE (Batch 50) → `macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved`,
  6 shots, all direct setText/setFontSize (the recorded caret edits change the trigger, not
  the rule — the same adjudication as the NonWrapping family). Fixture via the menu item's
  own creator (`world.createNewWrappingSimplePlainTextWdgtWithBackground`), so image_1
  reproduced the recordings' shared pristine hash-for-hash at both dprs; the setText round
  trip (image_4) and the font round trip (image_6) land on that SAME hash — the exact codas
  the recording missed (its own image_3 ≠ image_1: it deleted a click-to-shift-click chunk
  of the LAST paragraph, not what it added). image_3 is the one-line-strip-at-kept-width
  shot (the wrap/no-wrap branch discriminator). Retired with both siblings.
  Represents:
  - [x] DROP **WrappingSimplePlainTextResizesCorrectlyAsLinesAreDeleted** (same rule, delete axis)
    — glanced shot-by-shot (Batch 50): pristine (byte-identical to the REP recording's —
    shared creator) then three progressive Shift+ArrowUp selection-deletes, 2 paragraphs →
    1.5 → 3 lines → ONE line at the full kept 500px width; that distinctive end state is the
    macro's image_3 ('odio, ac finibus nisi.'). Retired.
  - [x] DROP **WrappingSimplePlainTextResizesCorrectlyAsTexSizeIsChanged** (same rule,
    font-size axis — folded into the REP as a beat) — glanced shot-by-shot (Batch 50): font
    20 via the prompt (the widget grew PAST the canvas bottom, edge hidden off-frame), then
    17 (fits, bottom ~378). Folded as the macro's setFontSize-17 beat (image_5 reproduced
    this recording's final shot hash-for-hash at both dprs — prompt-string "17" and direct
    numeric 17 land on the identical originallySetFontSize) plus the back-to-12 coda it
    never shot; 17 chosen over 20 to keep the moving bottom edge in frame. Retired.
- [x] DROP **NonWrappingSimpleTextScrollPanelResizesCorrectlyAsLinesAreBroken**
  (glanced Batch 52, 2 shots: mid-line Enters shorten the longest line and the H-bar
  VANISHES — bar-iff-overflow on the no-wrap width=longest-line law),
- [x] DROP **NonWrappingSimpleTextScrollPanelResizesCorrectlyAsLinesAreDeleted**
  (glanced Batch 52, 5 shots: deletes shrink the band; the line-join backspace drags the
  caret-into-view scroll RIGHT — H-thumb tracks offset; full delete → empty, NO bars),
- [x] DROP **NonWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChanged**
  (glanced Batch 52, 3 shots: font 20 → H-thumb shrinks, font 6 → thumb nearly track-wide —
  thumb size = viewport/content ratio under font-driven reflow),
- [x] DROP **NonWrappingSimpleTextScrollPanelResizesCorrectlyAsTextIsAddedAndRemoved**
  (glanced Batch 52, 4 shots: typing grows the line + caret-follow scrolls right; deletes
  re-anchor left; the 60-char delete makes both lines fit → H-bar GONE),
- [x] DROP **WrappingSimpleTextScrollPanelResizesCorrectlyAsLinesAreDeleted**
  (glanced Batch 52, 5 shots: 10 Enters overflow → V-bar, end-scrolled; 3-line deletes
  shrink with the clamp tracking; the last delete fits → V-bar gone, view re-anchored at
  the top — the REP's end-clamp resolution on the delete axis),
- [x] DROP **WrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartOne**
  (glanced Batch 52, 4 shots: 12→30→15→12 top-anchored font reflow at width KEPT; image_4 ≡
  image_1, dataHash 0f3c6b7c — the round-trip restore, the REP's image_4=image_1 law minus
  the end-scroll twist),
- [x] DROP **WrappingSimpleTextScrollPanelResizesCorrectlyAsTextIsAddedAndRemoved**
  (glanced Batch 52, 3 shots: typed paragraphs overflow → V-bar appears + caret-follow;
  deleting them re-fits the content → bar gone) —
  text-in-scroll-panel tracking content: `macroScrollBarsTrackContentChange` + the two PTS
  REPs above (font-size-while-scrolled, wrap-toggle). Filename harvest: all 4 NonWrapping
  image_1 ≡ a376f4dc (the no-wrap pristine the REP provenance cites), all 3 Wrapping
  image_1 ≡ 0f3c6b7c (the REP macros' own byte-identical baseline).

Old-inspector-inside-flows sub-family (deferred layout in a flow container):
- [x] DEEP-DIVE **SimpleDocumentCanHandleOldInspector** (2338 cmds, 16 shots; owner note:
  "the old inspector uses deferred layout… pay attention to the resizer") — ONE deep dive
  for the whole sub-family. Deep-dived (Batch 57) → MIGRATED as the fresh 7-shot
  **macroSimpleDocumentHandlesOldInspector** (the recording's three in/out round-trips,
  16 shots → every distinct law in 7): drop-in keeps the inspector's own size (the
  macroDocumentPreservesDroppedWidgetSizes law on a deferred-layout composite); the
  OWNER-NOTE beat — the ctor resizer still grows it after each exit; re-entry wider than
  the doc → CLIPPED at the doc edge; doc resize/move WIDEN/NARROW → the in-document
  inspector FOLLOWS the doc width both ways (recording images 13/14 — sizes preserved on
  DROP but re-flowed on DOC resize, the two halves of the layout contract); final exit
  keeps the doc-imposed shape. Dropped breadth: the wheel beats (doc-scroll macros'
  ground), the three MID-DRAG shots (macroDuplicateComplexWidgetRidesHand carries the same
  inspector on the hand). GOTCHA banked: in doc-mode TWO resizeBothDimensionsHandles are
  alive (mode corner + the hosted inspector's ctor resizer) — scope the lookup to the doc
  subtree, the mode handles are created last/frontmost. Filename harvest: the macro's
  image_2 reproduced the recording's image_2 BYTE-IDENTICAL at both dprs (git staged them
  as R100 renames) — the stack flow normalizes the drop, so the hosted state is
  position-independent. Retired. Represents:
  - [x] DROP **WidthContrainingVerticalStackPanelCanHandleOldInspector** — glanced
    (Batch 57, 17 shots): same script on the width-CONSTRAINING stack — hosted-inspector
    round-trips + ctor-resizer grow ≡ the new macro; its fixture shots show the
    constraining stack WRAPPING the lorem to its width on drop — that on-drop
    width-forcing breadth lands in the AddingWidgetsTakingFullDocWidthPartOne parade
    decision below. Retired.
  - [x] DROP **WidthNONContrainingVerticalStackPanelCanHandleOldInspector** — glanced
    (Batch 57, 10 shots): NON-constraining stack keeps children's natural width and CLIPS
    at its edge (the one-line lorem strips) ≡ macroDocumentPreservesDroppedWidgetSizes +
    the new macro's clipped-host beat; round-trips/resizer ≡ the new macro; its
    resize/move-mode beat on the stack ≡ the new macro's doc-mode beat. Retired.
  - [x] DROP **WidthNONContrainingVerticalScrollStackCanHandleOldInspector** — glanced
    (Batch 57, 11 shots): the scroll-stack flavor adds only scrollbar-button drags
    scrolling the hosted inspector through the viewport ≡ the thumb-drag-scrolls ground
    (macroMultilineTextInputScrollsWell image_2, macroInspectorScrollbarUnplugged);
    hosting/round-trips/resizer ≡ the new macro. Retired.

Omnibus widget-parade sub-family (5–6.7k cmds each, 9–20 shots):
- [x] DEEP-DIVE **WidthContrainingVerticalStackPanelAddingWidgetsTakingFullDocWidthPartOne**
  — decide ONE parade macro ("drop one of each widget kind into a constraining stack,
  N beats") or DROP all three. Deep-dived (Batch 58) → ONE fresh compact parade:
  **macroConstrainingStackForcesDroppedWidgetsToFullWidth** (2 shots, 5 widget kinds). The
  recording's per-kind dressing (demo-create, color…, resize/move-grow, drop) is asserted
  ground; the ONE unasserted law (handed here by Batch 57) is the constraining-on-drop
  width contract — and the deep dive sharpened it: getWidthInStack CAPS the remembered
  drop width AT the content width, it NEVER stretches up (the macro's first capture proved
  it empirically — small widgets kept their sizes; the recording GREW each widget wider
  than the stack before dropping, which is what "taking full doc width" meant). The macro
  drops five OVERSIZED kinds (rect/box/circle-band/horizontal slider/text) into a narrow
  constraining stack → all capped to ONE shared width, the text rewrapped
  (maxTextWidth). GOTCHA banked: a slider's centre press lands on the value-50 BUTTON and
  non-float-drags it — grab a bare slider by a clear TRACK point to move it. Retired.
  - [x] DROP **SimpleDocumentAddingMorphsTakingFullDocWidthPartOne** (followed the
    decision, Batch 58, 10 shots) — the same parade into a SimpleDocument: the doc's
    on-drop width law (preserve below the cap / cap above it) is
    macroDocumentPreservesDroppedWidgetSizes' + the new macro's asserted ground; the
    per-kind dressing is covered. Retired.
  - [x] DROP **WidthNONContrainingVerticalStackPanelAddingWidgetsPartOne** (followed the
    decision, Batch 58, 21 shots) — the NON-constraining flavor keeps natural widths
    left-aligned (SimpleVerticalStackPanelWdgt.coffee:92-103) ≡ the kept-size ground
    (macroDocumentPreservesDroppedWidgetSizes, the Batch-57 trio glance); the parade adds
    breadth only. Retired.

## Cluster I — leftovers

- [x] DROP **basicResize** — handle-resize covered (`macroCanMoveAndResizeColorPaletteWdgt`,
  window/stack resize macros); this is the minimal circle-box version. Glanced (Batch 52,
  6 shots): pill→wide→near-circle→tall→tiny across 4 drags in ONE resize/move session
  (grow+shrink multi-drag ≡ macroTextRelayoutsCorrectlyOnResize's two-drag session); image_6
  is the morph ALONE post-exit — handles gone (≡ macroCanMoveAndResizeColorPaletteWdgt
  image_2, which shoots AFTER the desktop click, and macroHandleWdgtIsItselfResizable
  image_4 "the enlarged handle alone"). Retired.
- [x] DROP **attachingTextMorphToPanelAndScrollPanel** (1038 cmds, 26 steps, 5 shots) — the
  attach mechanic (overlap rule, choose-by-prefix) and drop-into-panel/scroll-panel
  re-parenting are covered (`macroAttachResizingHandleToWidget`,
  `macroCompositeDragsAsUnitIntoScrollPanel`); attaching a TEXT adds fixture, not rules.
  Glanced (Batch 52, 5 shots): the name is a misnomer — NO attach… menu anywhere in the
  recording, pure drop-based re-parenting. Drop-in re-parent+clip + bars appear (image_1) ≡
  macroCompositeDragsAsUnitIntoScrollPanel image_3 + macroScrollBarsTrackContentChange;
  thumb-drag scrolls the text into view (image_2) ≡ macroMultilineTextInputScrollsWell
  image_2 / macroInspectorScrollbarUnplugged; in-panel move → both bars (image_3) ≡
  macroScrollBarsTrackContentChange image_3; drag-out intact with shadow restored, bars
  vanish (image_4/5) ≡ macroCompositeDragsAsUnitIntoScrollPanel image_6. Retired.
- [x] DEEP-DIVE **fiddlingWithResizerHandles** (1375 cmds, 33 steps, 6 shots) — handle edge
  cases (5 distinct nonFloatDrags). Deep-dived (Batch 53) → MIGRATED as the FRESH
  **macroResizeMoveModeIsLosslessAndReenterable** (4 shots, not a translation). The five
  drags (grow 80px/16px, shrink 33px, big-grow 292px, big-shrink 213px — all the
  bottom-right resizer on one demo rectangle, ONE mode session each) are covered resize
  ground, and no min-size crossing exists anywhere (smallest state ~90×80); but TWO
  lifecycle beats were asserted nowhere: the no-op enter/exit round-trip (image_4 ≡ image_3
  BYTE-IDENTICAL in all six reference families — native/SWCanvas/Windows × dpr 1/2) and
  mode RE-ENTRY (5 separate sessions, fresh handles each — every shipped macro entered the
  mode at most once per widget). The macro distills exactly those: baseline → no-op session
  (its reference is pixel-identical to the baseline's, equal dataHash at both dprs) →
  re-enter+GROW → re-enter+SHRINK. No new verb. Retired.
- [x] DEEP-DIVE **buildAllMorphs** (2478 cmds, 70 steps, **1 shot**) — builds every demo
  widget, one final screenshot. As a macro this is a cheap whole-catalogue smoke test
  (fixture parade + 1 capture). Deep-dived (Batch 56) → authored FRESH (per the pre-framed
  decision) as **macroDemoMenuCatalogueParade**: 17 widgets / 16 static catalogue items via
  the REAL world-menu path on a legible authored grid (the recording's cramped overlap
  cluster untangled, keeping its nesting trick — texts into both panel flavors with the
  scroll panel clipping, pen onto the canvas). speech bubble added (post-recording menu
  addition); "animation demo" excluded — its live BouncerMorphs (speed 3) keep moving after
  the drop, so the single reference would depend on cycle count; layout-tests submenu and
  under-the-carpet out of catalogue scope; the recording's stray color-picker click dropped
  (color picking asserted elsewhere). One reference now asserts every catalogue widget's
  constructor, defaults and first paint at once. Retired.
- [x] DROP **transparencyAndColorOfPanelAndScrollPanel** (62 steps omnibus) —
  `macroBoxTransparencyAndColorChanging` + `macroPanelInPanelTransparencyAndStroke` +
  `macroSliderTrackClickMovesButton`'s prompt patterns cover color/transparency flows.
  Glanced (Batch 52, 5 shots): color… recolors BOTH panel flavors (scrollable + plain, each
  with a rectangle child overlapping a dark box); transparency… lets the box show through
  the overlaps with children and the scroll panel's scrollbar chrome compositing in the
  panel's alpha; image_4 is the alpha PromptMorph itself open ("ScrollPanel alpha value:"),
  image_5 the opposite-direction alpha change. Every rule is a dedicated macro's asserted
  ground; the two-of-each-twice combination adds breadth only. Retired.
- [x] DEEP-DIVE **WindowContainingCollapsableMenusInScrollStack** (3809 cmds, 80 steps,
  **25 shots**, every flag) — the composite omnibus: collapsible menus, in a scroll stack,
  in a window. Deep-dived (Batch 61, the LAST recorded test) → walked all 25 SWCanvas dpr-1
  shots; split THREE ways per the pre-framed decision. The arc: pinned menus adopted as
  window content → those windows dropped as cells of the constrained-width
  SimpleVerticalStackScrollPanelWdgt (itself adopted by an outer window) → squeeze/widen via
  the outer window → collapse/uncollapse reflows the stack → a collapsed cell duplicated via
  the hierarchy menu into a third cell → wheel-scrolling through cells → an in-stack menu
  item still makes a morph → closing all cells empties the stack. Asserted-ground mapping:
  scroll-panel-branch window lifecycle (macroScrollPanelUpdatesCorrectlyOnCollapsingAnd-
  UncollapsingAndClosingWindow), the width-cap law (macroConstrainingStackForcesDropped-
  WidgetsToFullWidth), adoption+relabel (macroWindowResizesToTextContent), pin-on-drop +
  in-panel menu liveness (macroSubMenuDroppedIntoPanelPinsItself, macroMenuPinnedInScroll-
  Panel), closing inner keeps outer (macroClosingInnerWindowKeepsOuter), nested collapse
  matrix (macroWindowsNestedCollapsingUncollapsing), duplicate/carry-drop pattern, hierarchy
  delete, wheel routing. The UNASSERTED laws → three fresh macros:
  **macroWindowCellsInConstrainedScrollStackReflow** (8 shots — the SimpleVerticalStack-
  PanelWdgt branch of _announceLayoutPropertyChangeToContainer, Widget.coffee:1485-90,
  asserted only on its scroll-panel branch before + window cells tracking the LIVE stack
  width both ways; TWO byte-identity anchors: squeeze/widen image_3==image_1, second
  collapse round trip image_6==image_5 — the FIRST restore differs from pristine by exactly
  the banked HighlightableMixin pristine-vs-repaint glyph rule),
  **macroMenuInWindowInScrollStackStaysLive** (4 shots — menu liveness through DOUBLE
  wrapping: scrolls as stack content, its 'rectangle' item still creates a morph; gotchas
  banked: a header-drag release over the open cascade silently re-absorbs the dragged menu,
  and the adopting window WRAPS around a menu, discarding its preset extent),
  **macroDuplicatedCollapsedWindowKeepsStateAndContent** (3 shots — the copy is born
  collapsed with the deep-copied content and stored pre-collapse extent, independent of the
  original). All three: no new verb; staged fixtures (the desktop is too small to park
  everything — grabs target widget centres, so staging order matters). Recording retired
  into migrated-originals/; it sat in NO skip list (6 reference families, full coverage).
  **THE MIGRATION IS COMPLETE: tests/ holds macros only.**

---

## Post-migration addendum — triage of `completely-broken-tests-21-Jun-2023/` (Batch 62 queue)

Five 2021-era StringMorph2 recordings, moved out of `tests/` on 21-Jun-2023 because they no
longer replay at all (that is what the folder convention means — membership in `tests/` IS
the enabled set). Triaged 2026-06-12 with the standard digest+glance method (digests
generated in-place via temporary `tests/` symlinks; each test ships only 4 NATIVE reference
families — no SWCanvas refs, 2021 Chrome captures — so grounding is native dpr-1 and any
fresh macro's shots compare to them qualitatively only). Being unreplayable changes
NOTHING about the method: deep-dives never replay the original anyway — the digest + the
reference PNGs carry what each test asserted. The recordings' demo fixture text ("Hello
World! ⎲ƒ⎳⎷ ⎸⎹ aaa") carries glyphs absent from the SWCanvas bitmap font — fresh macros use
clean ASCII (the macroDoubleClickSelectsWord precedent). Retirement = the usual move into
`migrated-originals/`; when all five retire, the folder itself disappears.

The five verdicts (two genuine law-gaps found, both StringMorph2-only):

- [x] MIGRATE **editingStringMorph2DeferredToPromptPartOne** (1161 cmds, 40 steps, 8 shots;
  no PartTwo was ever shipped) → fresh **macroStringWdgtEditDefersToPromptWhenCropped**.
  THE flagship gap: a click on a CROPPED/ellipsised StringMorph2 does not place an inline
  caret — editing is DEFERRED to the "edit:" PromptMorph (field preloaded with the FULL
  text; type at the prompt caret, "Ok" commits to the morph, "Cancel" discards), while the
  same click on a FITTING string edits inline. This is the mechanic two shipped macros
  explicitly declined to assert (macroTextWdgtNoJumpsInLayoutOfLongLine's provenance;
  the cropped-text trap note in macroTextWdgtCutCopyPasteBasic) and the retired
  endurance omnibus hit by accident at its image_21. Recording walk: cropped→prompt→"AA"
  at a clicked prompt slot→Ok (its images 2-3), widened→INLINE typing (image 5), prompt
  caret-nav (ArrowRight/Left) + insert + Ok (image 6), shrink-to-fit interplay (7-8).
- [x] MIGRATE-REP **resizingAndEditingStringMorph2PartOne** (3867 cmds, 105 steps, 23
  shots) → fresh **macroStringWdgtInlineTypingRefitsUnderFittingModes**, representing
  PartTwo and the matrix beats of this recording. The other gap: the FITTING-MODE × LIVE
  TYPING matrix on a single-line StringMorph2 — inline typing under SCALEUP (the
  "←→ expand to fill" toggle on a StringMorph2, whose DEFAULT is FLOAT — every shipped
  SCALEUP macro is TextMorph2-based) refits the font as the text grows; under SCALEDOWN
  ("→← shrink to fit") it shrinks; under FLOAT/CROP the overflow ellipsises and the NEXT
  click hands off to the edit prompt (asserted in the sibling macro above). Fold in ONE
  residue shot from the caret-positioning DROP below: the caret placed by click in a
  vertically MIDDLE/BOTTOM-floated string (caret rides the float). Its prompt-edit beats
  (images 2, 16-17, 21-23) are the sibling's subject; selections/mass-delete are
  macroStringWdgtImprovedSelection's.
- [x] DROP **resizingAndEditingStringMorph2PartTwo** (909 cmds, 30 steps, 6 shots) —
  covered by the two macros above once they ship: font-size-prompt typing (the banked
  prompt dance, asserted on the document font-size macro), StringMorph2 SCALEUP at tiny
  font + inline typing refits (the REP's matrix), prompt caret-nav + commit (the
  flagship's). Glanced: no beat outside those.
- [x] DROP **stringMorph2CaretPositioningAllAlignments** (2724 cmds, 106 steps, 37 shots!)
  — 37 shots of click-places-caret across the H×V alignment grid at font 70. The two laws
  are asserted: the alignment-aware click resolution lives in single-line StringMorph2
  code (slotAtSingleLineString, StringMorph2.coffee:791) and is asserted by
  macroTextWdgtCaretPlacementUnderAlignments (which cites those very lines; TextMorph2
  inherits it per visual line), and the 3x3 alignment float is macroStringWdgtAlignments'
  9-shot grid. The one nuance with no asserted pixels — the CARET sitting in a vertically
  floated (middle/bottom) string — folds into the REP macro as one shot. Glanced
  (image_13: caret after "Hello World!" in a middle+right float): nothing else novel.
- [x] MIGRATE **stringMorph2TextTransformationBasic** (1033 cmds, 61 steps, 7 shots) →
  fresh **macroStringWdgtHideCharactersMasksTextNotEditing**. The isPassword law,
  asserted nowhere: "hide characters" (toggleIsPassword, StringMorph2.coffee:1046-1048;
  the item label flips to "show characters") renders the string as a run of ASTERISKS
  (glanced image_2), while the REAL text keeps driving everything underneath — the
  recording clicks a caret into the MASKED string, keyboard-selects, Meta+c copies the
  real characters ("el", not asterisks), pastes them back 12x (the masked run grows), and
  "show characters" reveals the edited text; a second hide round-trips. Note
  toggleIsPassword calls world.stopEditing() (the fitting-toggle precedent). Its
  edit-prompt beats (images 4-6) are the flagship's subject.

Follow-up flagged during the triage — EXECUTED at closure (Batch 63, owner-approved via
"complete closure of the plan"): with zero recorded tests left in `tests/`, every entry in
`SWCanvasBrokenTests.coffee`'s two per-density lists named a retired recording, so both
lists are now EMPTY (the documented skip mechanism stays in place for future use; macro
tests locate targets in the live world, so the SWCanvas font-metric shifts that broke
recordings cannot move their clicks).

Batch 62 (executed the addendum): all three fresh macros shipped —
**macroStringWdgtEditDefersToPromptWhenCropped** (5 shots; the edit()-deferral decision
rule, with the Cancel path byte-anchored image_4==image_3),
**macroStringWdgtInlineTypingRefitsUnderFittingModes** (5 shots; the SCALEUP/SCALEDOWN/
CROP live-typing matrix — capture surfaced a BONUS law now asserted: the keystroke that
makes the text no longer fit hands editing off to the "edit:" prompt MID-TYPING, the run's
tail landing in the prompt field; plus the folded caret-on-a-bottom-floated-line residue),
**macroStringWdgtHideCharactersMasksTextNotEditing** (5 shots; asterisk masking with the
clipboard copying the REAL characters under the mask — the blind 'el' x3 paste reveals as
'Helelelello World'). All five originals retired into migrated-originals/ (with their
digest pairs and the 2021 screen-recording timestamps file); the
completely-broken-tests-21-Jun-2023/ folder is GONE. No new verb; 15/15 repeated headless
runs green across both dprs. tests/ holds 160 macro tests; migrated-originals/ caches 220
retired originals.

---

## Standing rules

- A REP macro's `provenance` must name the siblings it represents (so the coverage chain
  stays auditable after the originals are retired).
- Every retirement (DROP or post-migration) moves the folder into `migrated-originals/`
  (with its `.digest.*` if generated) and `git rm`s it from `tests/` — never plain deletion.
- When a DROP's screenshot-glance contradicts its covered-by note, flip it to MIGRATE here
  (edit this file in the same commit as the batch).
- Keep `MACRO-PATTERNS.md` and this file in sync: a new macro = a new pattern entry + a
  checked box here.
