> **ARCHIVED — LEDGER (2026-08-18).** Closed BACKLOG items whose owning arc has no plan file; moved here per docs/README.md rule 2.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# BACKLOG closed-items ledger — arcs that never had a plan doc

`docs/BACKLOG.md` is an index of OPEN work only, so an item leaves it when its arc closes and
lands in the plan file that owns it (`docs/README.md` filing rule 2). A handful of closed items
had no such file to go to: session-scoped audits, owner-directed one-off fixes, and findings that
were raised, decided and executed inside another arc without ever growing a plan of their own.
They are collected here VERBATIM, in the order they stood in `docs/BACKLOG.md` on 2026-08-18,
with their original BACKLOG headings and context kept so each entry still reads with the framing
it was written under. Two of the naming-gloss entries did grow plans of their own in execution and
say so inline — `archive/dispatch-slot-protocol-plan.md` and
`archive/damage-vocabulary-unification-plan.md` are the executable records; the lines below are
the audit's own ledger of what it filed and what became of it. Nothing here is open work; the one
naming-gloss item still open (the glyph-drawing duplication) stayed in `docs/BACKLOG.md`.

### Naming-gloss audit 2026-08-18 — names the comments had to apologise for
Session-scoped audit (no plan doc; detectors in `Fizzygum-tests/.scratch/naming-gloss-audit.js` +
`naming-dup-comments.js`), prompted by the `localArea` → `localDamageBox` rename: a comment that
must TRANSLATE a name into a different noun phrase at the point of use is a vote that the phrase
is right and the name is not — and the strongest signature is the WARNING comment ("X is NOT the
Y"). Eleven detectors over the 20k comment lines; 234 glossed identifiers triaged, most glosses
being legitimate role-explanations rather than name-apologies. Discipline: per the
menu-dispatch-residue lesson, every candidate's CONSUMER was read before calling the name a defect.
- [x] **✅ EXECUTED 2026-08-18 — seven renames, both repos, zero recaptures expected (no pixels move):**
      `srcBrokenRect`/`dstBrokenRect` → `srcBrokenRectIndex`/`dstBrokenRectIndex` (they hold INDICES
      into `world.broken` — the assignment `= @broken.length`, every read `@broken[w.srcBrokenRectIndex]`,
      and the transients comment's own "the src/dst indices" all said so; a field named `Rect` holding
      an integer is a type-lie); `maxShadowSize` → `brokenRectMargin` (its own comment warned it "need
      not capture the biggest shadow" — it is the flat margin every damage rect is grown by; shadows
      are covered exactly by `shadowExtendedRect`); `checkDraggingTreshold` → `checkDraggingThreshold`
      (typo — the same file spells `displacementDueToGrabDragThreshold` correctly); `SliderButtonWdgt
      @offset` → `@dragTargetPosition` (two comments in the file both glossed it "a plane-local
      position": it is pointer-in-my-plane minus the within-thumb grab point, i.e. where the thumb
      should go); `world._dirtyDescendantFlagged` → `_widgetsFlaggedHasDirtyDescendant` (read as a
      boolean flag, holds the LIST of flagged nodes); `SheetHeaderCellWdgt @index` → `@viewportSlot`
      (the comment had to warn "the viewport SLOT" — the name was true only at scroll origin 0);
      and `area` → `damageBox` through the `calculateKeyValues` tuple at all 14 destructure sites
      (it IS `localDamageBox` before the translate — the sanctioned rename's source, completing it).
      The device-px `sl,st,al,at` stay terse: blit-geometry idiom, documented at use, never seen by
      paint bodies.
- [x] **✅ EXECUTED IN FULL 2026-08-18 — the dispatch-slot protocol is FIXED; the conditionality
      is dead.** Phase 0 (the reader census, `measurements/dispatch-slot-census-2026-08-18.md`:
      631 reachable pairs → 208 methods, bucket (e)=0) found the decisive structure nobody had
      measured: the two fill configurations partitioned EXACTLY by delivery family (menu rows
      594/594 env-absent, prompt Oks 37/37 env-present, zero shared verbs, statically total — only
      the three prompt classes ever wrote `environment`), and 83% of verbs declared no parameters.
      The owner chose O4 + value-delivery convergence, executed same-day
      (`archive/dispatch-slot-protocol-plan.md`): prompts deliver the VALUE
      (`PromptWdgt.deliverValue` → `@target[@callback] value`; per-subclass `_promptValue`), every
      pin setter takes ONE argument (33 giver-shaped headers + the `ignored`-named overrides
      collapsed; the ⚠ SHAPE convention and its three-leg interrogation are deleted;
      `widget-authoring-guidelines.md` §11 rewritten), and `ButtonWdgt.trigger` passes ITSELF as
      slot 1 with slot 2 the panel-filled `@subjectOfAction` — the crossover, the
      `if !@environment?` fork, and `environment` on `MenuWdgt`/`MenuRowsPanelWdgt` are deleted.
      Zero reachable verbs migrated (the census proved their readings already matched). By-catch:
      a LIVE user-facing bug (the colour prompt on `WidgetHolderWithCaptionWdgt` set `icon.color`
      to the widget itself — confirmed in isolation, fixed), and the header lib's
      space-before-colon blind spot (13 methods invisible to every gate; normalized + guard
      extended). Phase 3: menusweep now fails on a prompt callback declaring >1 parameter
      (PROMPT_CALLBACK_ARITY, proven on a planted violation). `argumentToAction1/2` STAY — the
      census's collapse idea fell to two real two-payload consumers behind the choose-target UI.
      ⚠ `widgetOpeningThePopUp` stays ⛔ FALSIFIED and is untouched — under the fixed protocol its
      name is simply TRUE at every dispatch.
- [x] **✅ EXECUTED 2026-08-18 (owner-directed, same day): the three-word repaint-region split is
      UNIFIED — pixels say "damage", layout says "dirty".** Measurement first overturned this
      item's own "cleanly layered" framing: the strata are ERA-correlated, not
      subsystem-correlated (WorldWdgt mixed b=160/d=39/dmg=14, Widget b=38/d=22/dmg=25,
      TransformFrameWdgt b=7/d=38/dmg=17), so the synonym-map option would have rationalised
      noise, and the owner chose unification. Plan + locked name table + the law:
      `archive/damage-vocabulary-unification-plan.md` (33 identifiers incl. `world.broken` →
      `@damageRects`, `_updateBroken` → `_repaintDamagedRects`, the island buffer's
      `_islandBufferDirtyRect` → `_islandBufferDamageRects` — fixing its singular-list lie —
      and `brokenRectMargin` → `damageRectMargin`; the layout-dirty family and the text-atlas
      settle-gate booleans deliberately KEPT). The law now lives in
      `architecture/appearance-paint-convention.md` § "The vocabulary law". ⚠ The one
      distinction worth a boundary — pixels vs layout — existed before only by accident; the
      unification is what makes "dirty" mean exactly one thing.
- [x] **✅ EXECUTED 2026-08-18 (owner-directed): the `p0` idiom is GONE — every block became one
      well-named expression.** The filing's "×4" was an UNDERCOUNT: the detector only saw blocks
      carrying the literal "p0 is the origin" gloss; the idiom lived in TEN blocks across NINE
      files (`SimpleDropletAppearance`, `LayoutElementAdderOrDropletWdgt` ×2 — the arrow block
      continued the cursor — `StretchableWidgetContainerWdgt`, `GenericObjectIconWdgt`,
      `WidgetHolderWithCaptionWdgt`, `HandleAppearance` ×2, `LayoutSpacerWdgt`,
      `GenericShortcutIconWdgt`, `FanoutWdgt`). Shape: mutating cursor-walks collapse to a single
      arithmetically-identical expression named for where the point IS
      (`inscribedSquareLeftMiddle`, `inscribedSquareLeftAtThirdHeight`, `inscribedSquareTopLeft`,
      `contentsTopLeft`, `leftEdgeMiddle`, `bottomMiddle`, `squareTopLeft`, `arrowRowLeft`);
      no-mutation aliases rename or inline. ⚠ The refactor caught a LYING narration comment:
      `LayoutElementAdderOrDropletWdgt`'s second hop claimed "now the origin is in the middle
      height" while the arithmetic put it at one-THIRD height — copy-paste residue from the
      droplet sibling, exactly the failure mode a narrated cursor invites. The tests-repo macro
      `p0..p3` corner quartet (`macroGeometryApiTwoVocabularies`) is a fine name in context and
      stays.
- [x] **✅ F3 re-sweep 2026-08-18 (post-dispatch-slot-arc): the slot-1 reader naming split is a
      MEASURED KEEP; the popout VERB family is unified.** The question was whether
      `widgetOpeningThePopUp` vs `menuItem` (both receiving trigger's slot 1, the fired button)
      should unify. Measured: they mark two GENUINE consumer roles — the pop-up openers pass the
      value onward as the next pop-up's opener (the ⛔-falsified consumer contract), while the 12
      `menuItem` readers (the census saw only 3 — its roots bounded the count, rule 4 again) use
      it AS a menu row (`menuItem.parent.title` for the prompt's message, or menu context) and
      never as an opener (`Widget.prompt` passes `@` for that). Each verb is named for the role it
      actually reads; unification would REDUCE honesty. KEEP both. ⚠ The sweep instead exposed a
      real drift among the popout verb NAMES — 8× `*Popout`, 2× `*Popup`, 3× `promptFor*`, three
      spellings for one role — unified onto the dominant `*Popout`: `fontSizePopup`→
      `fontSizePopout`, `editPopup`→`editPopout`, `promptForFloor`→`floorPopout`,
      `promptForCeiling`→`ceilingPopout`, `promptForButtonSize`→`buttonSizePopout` (labels
      untouched, zero pixels). Fresh-drift sweep over the dispatch arc's ~30 touched files:
      clean (the three NOT-warnings there are true structural facts on good names).
- Declined, with reasons (do not re-file): `island`/`action`/`pin`/`gotoSlot`/`enableDrops`/
  `footprint` — their glosses are role-explanations or gate-sanctions on good vocabulary;
  `TreeNode.atIndex` — the comment IS the record of a deliberate rename (R4); icon-geometry terse
  names (`cxc`, `S`, `td`) — dense local math with adjacent glosses; `checkIfTextContentWasModifiedFromTextAtStart`
  — `check` as a query verb, conventional; the scare-quoted-concept sweep came back dry (every
  recurring phrase already has an identifier).

### From the flat "Residual / parked items" list — no owning plan named

These stood as one-liners in `BACKLOG.md`'s flat residual list, where every other line names the
archived plan and section that owns it. These five name none, because none exists: each was raised,
decided and executed on its own. Kept verbatim, in their BACKLOG order.

- [x] `Fizzygum-tests/scripts/serialization-file-roundtrip-headless.js`: `dropPixelParity` settled by rAF frame COUNT — cadence-sensitive under parallel gauntlet load (one in-wave hash mismatch 2026-07-27; serial + standalone green). DONE 2026-07-27, owner-directed: every pixel-parity capture in BOTH rigs now uses a convergence capture (`captureSettled`/`captureWorldMaskedSettled` — sample per frame until two consecutive hashes match, capped) instead of a fixed frame count; both rigs green standalone and under suite load.
- [x] **`SliderWdgt` converted to the HYBRID constructor — DONE 2026-08-14.** `constructor: (@start = 1, @stop = 100, @value = 50, @size = 10, opts = {})`, with `color`/`smallestValueIsAtBottomEnd` read from `opts`, assigned before the super call (preserving the order the all-`@param` form compiled to) via `?` so an explicit `null` reads as absence. All 8 hole-passing sites gone — they now restate the numbers they want: `new SliderWdgt 1, 100, 50, 10, smallestValueIsAtBottomEnd: true`. ⚠ **Option A (full opts) landed FIRST (`025ec563` / tests `afa7af7c1`) and was then SUPERSEDED**: the owner reconsidered, so the four numbers went back to positional everywhere. Those commits are historical; the hybrid ships. The reason B won: the numbers are the USER-FACING spelling — a spreadsheet cell accepts typed CoffeeScript, so `new SliderWdgt 0, 100, 30, 10` is a formula users enter (`FormulaCompiler`) and the documented idiom in `MACRO-PATTERNS.md` — so keeping them positional leaves every existing formula working, while the two FLAG knobs, which is what the holes existed to reach, move into `opts`. Cost of B: those 8 sites won't track a future change to the defaults. ⭐ The A→B revert was byte-clean because the A conversion had been scripted, so its inverse was too. Zero reference churn either way. Gauntlet 14/14. Original analysis follows.
- [x] **~~`SliderWdgt`'s trailing two params want to be an options object — OWNER DECISION PENDING on the shape.~~** Found during `archive/nil-global-retirement.md` step 1. Its ctor is six positionals — `(@start = 1, @stop = 100, @value = 50, @size = 10, @color = Color.BLACK, @smallestValueIsAtBottomEnd = false)` — and 8 sites pass holes to reach a trailing one, in two groups with DISJOINT tails: 6 want only `smallestValueIsAtBottomEnd` (`SliderNodeCreatorButtonWdgt`, `SampleDocApp`, `DegreesConverterApp` ×2, `SampleDashboardApp`, `DemoMenus`) and 2 want only `color` (`ScrollPanelWdgt`'s `@hBar`/`@vBar`). ⛔ No REORDERING can fix it — disjoint wants mean any order leaves one group filling holes. ⚠⚠ **But full-opts is NOT obviously right, and an earlier version of this entry said it was, on `src`-only evidence.** The positional form is **user-facing product surface**: spreadsheet cells accept typed CoffeeScript and `"new SliderWdgt 0, 100, 30, 10"` is a FORMULA users enter (`FormulaCompiler`), it is the documented idiom in `src/macros/MACRO-PATTERNS.md`, and ~25 further positional constructions live in `Fizzygum-tests`. Options: **(A)** full `(opts = {})` — kills all 8 holes, breaks the formula idiom + ~25 test sites + docs; **(B, recommended)** hybrid `(@start = 1, @stop = 100, @value = 50, @size = 10, opts = {})` with `color`/`smallestValueIsAtBottomEnd` in `opts` — the four numbers are a natural ordered tuple and stay the user-facing spelling, so zero test/formula churn, and the 8 sites become `new SliderWdgt 1, 100, 50, 10, smallestValueIsAtBottomEnd: true` (cost: those sites restate the defaults, so they won't track a future change to them); **(C)** leave it. ✅ Safe either way: `Deserializer` builds shells with the **constructor NOT run**, and the bare `super` forwards to `CircleBoxWdgt.constructor: ->`, which takes no params and reads no `arguments`.
- [x] **The `add` family's 5th positional slot meant two different things — HUNT DONE 2026-08-13, NO LIVE BUG, naming fixed.** `SimpleVerticalStackPanelWdgt` / `ScrollPanelWdgt` / `ToolPanelWdgt` named slot 5 `unused` while `FrameWdgt.add` gave that SAME slot the meaning `notContent`, so one positional call meant different things per receiver. The hunt: only two sites pass a 5th arg (`ActivePointerWdgt:484`, `ScrollPanelWdgt:234`) and **both pass `undefined`**, so on a FrameWdgt receiver it lands as a falsy `notContent` (content treatment — correct for a widget dropped into a window) and on the panels in a parameter nothing reads. Nothing was mis-set. Latent hazard removed anyway by renaming `unused` → `notContent` in all three (a parameter nothing reads, so a no-op) + the family's positional contract documented at `SimpleVerticalStackPanelWdgt.add`. ⚖ **The slot-3 divergence flagged in this entry's first draft is REAL but INTENTIONAL, not a defect:** `Widget._addNoSettle` resolves `opts.layoutSpec ? aWdgt.defaultLayoutSpecWhenAddedTo(@)` while the stack/tool/frame cores deliberately leave it absent, because their *arrange* assigns the spec (`initialiseDefaultVerticalStackLayoutSpec` adopts spec-less children) — a container with its own layout regime does not want the generic default.
- [x] **`Widget.add`'s redundant `layoutSpec` signature default DELETED — DONE 2026-08-13.** It duplicated what its own core already does (`_addNoSettle` applies `opts.layoutSpec ? aWdgt.defaultLayoutSpecWhenAddedTo(@)`), so the fallback was stated in two places while only the core one always runs. ⭐ This entry's first draft said "the default fires, gets passed in, and the core's `?` then sees a value" — WRONG for the common path: `Widget.defaultLayoutSpecWhenAddedTo` returns **undefined** (a plain widget is free-floating), so the core's `?` saw the undefined the signature default had just produced and resolved it a SECOND time. Two calls per ordinary `parent.add child`, across 434 call sites, same answer both times. Deleting the signature default leaves one resolver and one call; identical in every case (the `null` and `undefined` routes both end at the same value), and the base signature now matches all six overrides, none of which carry a default. Both implementations verified pure (base returns a literal; `HandleWdgt`'s compares the destination and reads `@cornerSpec`), discharging the side-effect caveat. Gauntlet 14/14.

### SliderTrackClickMovesButton side-problems arc 2026-10-15 — residue (no plan doc; case law in `../../Fizzygum-tests/DETERMINISM.md` §3j)

- [x] **A finger stroke can leave a scrollbar thumb's HOVER HIGHLIGHT stuck.** A finger has no hover and the
      stroke's end dissolves it, yet in `macroMultilineTextInputScrollsWell` (finger) one thin indicator's
      thumb (the 5×5 one at 272,227) is in `SliderButtonWdgt` state 1 (highlighted, colour 110,110,110) at
      both captures, before any drag — and its finger references bake it. Measured with a capture-time state
      probe (`Fizzygum-tests/.scratch/finger-p4/capture-state.js`, PRELUDE_JS). The same arc's thumb re-lay
      (`SliderWdgt.showAsScrollIndicator`) cured the DRAGGED bar's identical stuck highlight in that test and
      in `macroMenuPinnedInScrollPanel` — consistent with a hover-exit computed against a thumb laid for the
      other look; this one survives it, so the mechanism is still to be found. Fixing it moves finger references.
      **DONE 2026-10-15 — the dissolution ran with the stroke's drag still standing.** Traced: the thumb is the
      inspector member list's vertical bar, which `bringInViewAndClickOnListItem` drags with the finger. At the
      up, `endOfNonFloatDrag` set it normal, the release (a click ON the thumb the stroke pressed) fired
      `SliderButtonWdgt.activated`, which lit it, and then `_dissolveHoverStateOfTouchStroke` sent its
      `hoverExited` while `@nonFloatDraggedWdgt` was still set — so the thumb's "hand is dragging" guard
      ignored the one exit that could put it out. The re-lay "cure" above was the same mechanism seen
      from the other side, measured with the re-lay switched off in-page: the stale inset left the DRAGGED
      bar's fattened thumb 12 px wide, so the finger's press landed ON it and the release fired `activated`
      (image_2 state 1 with the old order, 0 with the fix); laid right, the thumb is narrower, the press
      lands on the track beside it, and no click reaches the thumb at all. A capture-time census
      found it was never one thumb: 20 finger tests (~51 captures per density) showed a slider or scrollbar
      thumb lit with the finger gone — every finger drag of a thumb that ended on the thumb, plain sliders
      included; the mouse census found no highlight without a pointer on it. Fix (`ActivePointerWdgt`): both
      the up and the cancel clear the press and the drag BEFORE the dissolution, the stroke's last act
      (contract in `architecture/input-and-gestures.md` §"Touch hover dissolution"); the cancel already
      cleared the drag first. The size adjuster's cursor (`StackElementsSizeAdjustingWdgt.hoverExited`,
      the other drag-deferring exit) rides the same fix. Pinned by `SystemTest_macroThumbHighlightOnlyUnderAPointer`
      (assertion-only, both pointer kinds; fails under a finger with the old order restored in-page).
      Mouse references are untouched except `macroFingerChromeDragNeedsNoHold`, which synthesizes touch.
- [x] **A finger pressing a THIN scroll indicator's thumb shows it HIGHLIGHTED, not pressed, for the whole
      drag** (found 2026-10-15 while tracing the stuck finger highlight). The finger's arrival move builds the
      over-list while the bar is still thin and intangible, so the thumb enters it only at the next cycle's
      hover re-sync — AFTER the press (`setPressedColor 0->2`, then `hoverEntered 2->1` from
      `reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges`). `SliderButtonWdgt.hoverEntered`
      guarded only "the hand is dragging", which is not yet true below the grab threshold, so the enter
      overwrote PRESSED; `hoverMoved` carried the PRESSED guard its own comment states for both. A mouse
      enters the thumb before pressing, so it never sees this.
      **DONE 2026-10-15 (owner: fix in this arc)** — `hoverEntered` carries the PRESSED guard too. The filed
      caveat (a thumb pressed then left below the threshold staying PRESSED on a re-entry) does not hold by
      the code: below the threshold the hand is not dragging, so the exit resets the thumb to normal and a
      re-entry finds it normal. Pixel-inert in both suites (the failure sets did not change). Pinned by
      `SystemTest_macroThumbHighlightOnlyUnderAPointer`'s held press on a thin indicator (fails under a
      finger with the guard removed in-page: found 1, expected 2).
- [x] **`dragSliderButtonToFraction` under a finger can press the TRACK beside a scroll indicator's thumb**
      (found 2026-10-15, same trace). It aimed at the thumb's centre in its THIN look; the pointer's arrival
      fattens the bar, which widens and moves the thumb, and the thin centre can fall just outside the fat
      thumb (measured: thin thumb `[276@60 | 5@27]`, press at x 279, fat thumb spans x 269–278; also the
      finger drag of the detail pane's bar in `macroMultilineTextInputScrollsWell`). The press then landed on
      `SliderWdgt`, which teleports the thumb under the pointer, so the drag still moved it — but as a track
      press, not a grab of the button the verb names, and with no click on the thumb.
      **DONE 2026-10-15 (owner: fix in this arc, as a high-level helper modelled on openOwnMenuOf).**
      `MacroToolkit.sliderButtonPressPoint slider[, preferred]` is the one answer to "where does a press take
      this button": it keeps the caller's point whenever a press there takes the button (a plain slider:
      the product's hit test, with `_exposedScreenPointOf`'s fallback), and for a thin indicator asks
      `ViewportWdgt.buttonScreenBoxOnArrival` — the fat box, from the same derivations the arrange commits
      (`ViewportWdgt._barFrameAt`, `SliderButtonWdgt.boxInSliderFrame`), so the toolkit re-derives no
      geometry. The four thumb-pressing verbs aim through it (`dragSliderButtonToFraction`,
      `scrollInspectorListItemIntoView`, `nudgeListTowardItem`, `bringcodeStringFromTopInspectorInView`),
      each keeping the drag displacement it computes. "Mouse not measured" above: it IS mouse too — with the
      aim switched off in-page the pin's "the press took the thumb" fails under BOTH pointers, because a
      mouse's approach fattens the bar exactly as a finger's down does. Contract in
      `architecture/viewports-and-planes.md` §"Scroll indicators".
- [x] **A `TextWdgt` sized to its text forgot it hugs it** (found and fixed 2026-10-15, same arc, owner: keep it).
      `TextWdgt` overrides `_sizeToTextAndDisableFittingNoSettle` (the multi-line box-hug) and the override
      dropped the line `StringWdgt`'s core opens with, `@autoSizeBoxToText = true`, so a later
      `setFontSize`/`setText` fitted the new size into the box sized for the old one instead of re-hugging.
      Measured in `macroSlidersControlTextWidget`: the font-size wire moved the value 50→93 while the rendered
      size stayed 22. The override now remembers the hug. It moved two more tests, under both pointers, both
      for the better: in `macroFontsMenuFollowsAnApiChange` / `macroWallpaperMenuFollowsAnApiChange` the row
      whose tick moved away was drawn smaller than its siblings (its new label fitted into the box of the
      ticked one) and now matches them.
- [x] **A thin scroll indicator's thumb was 5 px on a 4 px bar** (found 2026-10-15). `SliderButtonWdgt` kept
      `Widget`'s default `minimumExtent` of 5×5, so `__commitExtent` widened a thumb derived at 4 px to 5 — it
      poked 1 px past its bar and the viewport's edge, and a thumb whose length derived under 5 was lengthened.
      **DONE 2026-10-15 (owner: fix it).** The thumb lowers its own minimum to 1×1, as `SliderWdgt` does for
      itself: its extent is its slider's to derive (`boxInSliderFrame`, which `buttonScreenBoxOnArrival` shares,
      so the press-point derivation follows). Measured before recapturing, with a capture-time census of every
      thumb whose box the minimum changes: it moved 21 tests at dpr1 and 67 at dpr2 (mouse), 21 and 62
      (finger), every failing test a flagged one, and every moved pixel inside a thumb's old ∪ new rect except
      four traced causes — (1) `scrollInspectorListItemIntoView` derives its drag from the thin thumb, so two
      lists landed on other rows (filed); (2) `macroInspectorScrollbarUnplugged`'s bars, picked up while thin,
      are 4 px PLAIN sliders whose thumbs derive at 2×2 (owner: accept); (3) a census blind spot, a menu riding
      the hand (proved inside once the hand is walked); (4) `macroMovingSlidersSidewaysDoesntCauseContentToMoveSideways`
      had NOT delivered its intent in any committed reference — its presses aimed at the thin thumb's centre,
      which lay just outside the fat thumb, so they took the track and a list row, and image_3 showed the list
      panned 100 px SIDEWAYS and not scrolled (read as values with the 5 px floor switched back on in-page). The
      test now aims with `sliderButtonPressPoint` and asserts the scroll offsets. Also gone: a stray 5×5 dot
      that ~1 px-long thin bars painted in single-line fields (the bars themselves: filed).
- [x] **Audit the tests that DUPLICATE and then "carry" the copy** (found 2026-10-15). **DONE 2026-10-15**, by a
      capture-time census over the whole suite under both pointers: every copy path wrapped (`duplicateMenuAction`,
      `duplicateAndPickItUp`, any `fullCopy`), each copy's offset/stacking/hand logged at every capture, every
      press and wheel attributed to copy, original or neither, plus an untagged pass for same-class pairs offset
      by +10,+10. Fifteen tests make a copy; no copy stands stacked where it does harm, no press meant for an
      original lands on its copy or the reverse, and the only stacked captures are the two deliberate birth
      frames (`macroDuplicateSimpleWidgetPaintsCleanly`, `macroDuplicateComplexWidgetPaintsCleanly`). It found one
      defect of another kind: under a FINGER, `macroDuplicateAndPickItUpRidesHand`'s park was a buttonless move,
      which emits nothing, so the copy rode a hand still at (0,0) and the committed finger image_1 showed it on
      the canvas corner; the value check passed because it compared the copy with the hand, not with the park.
      The park now ends in a click (a tap), and the hand position is asserted. Stale "duplicate puts the copy on
      the hand" text corrected in three tests' metadata and three places in `src/macros/MACRO-PATTERNS.md`.
- [x] **A finger re-touching where its last stroke began arrived with no hover move** (found and fixed
      2026-10-15, the thin-thumb arc; owner: keep it). `dispatchEventsFollowingMouseMove` sends a move only "if
      the pointer actually moved", measured against `@mouseDownPosition` — which still held the PREVIOUS
      stroke's down when a new down's position head ran. So a finger landing on that exact spot got no hover
      move on arrival: a thin scroll indicator under it stayed thin and the press fell through to the content
      (`macroMovingSlidersSidewaysDoesntCauseContentToMoveSideways`' second press, finger), and an armed text
      selection opened an edit (a caret from a plain scroll swipe, baked into the finger references of
      `macroDocumentScrollsMixedTextAndClocks` and `macroNestedScrollPanelsRouteWheel`). A press beginning now
      drops the previous stroke's down position before its position head (`ActivePointerWdgt.processPointerDown`);
      a mouse stroke's down never runs that head (a move always precedes it; a synthesised one states no
      place), so no mouse stroke is touched. Measured in-page first: ~60 same-spot
      arrivals across the finger suite, pixels moved in those two tests only. Pin: the MovingSliders test's
      value assertions fail under a finger without it. Contract in `architecture/input-and-gestures.md`
      §"Touch hover dissolution".

### Residue arc 2026-10-16 — the three measured residue items (no plan doc; owner: address all three)
- [x] **`scrollInspectorListItemIntoView` derived its drag from the THIN thumb** (filed 2026-10-15). **DONE
      2026-10-16.** The latent fault was proved first, in-page: dragging from the top of the 235-row member
      list, the click verb RAISED for rows ~180–220 (mouse) and ~160–220 (finger). The thin thumb is 4 px on
      a 140 px bar, the fat thumb a press meets is 10 px, so the drag overshot by a share that grows with the
      distance dragged, past what the three ±1 px nudges recover. Chained calls (each starting near the last
      row) hid it, so no test raised. The verb now measures the travel in the look the press meets:
      `ViewportWdgt.barScreenFrameOnArrival` (new, beside `buttonScreenBoxOnArrival`) via
      `MacroToolkit._sliderFrameAndButtonAsPressed` and `_dragVerticalSliderButtonToTravelFraction_InputEvents`.
      Every call in both pointers' suites now lands within one row of its intended top with zero nudges.
      Two things found on the way:
      - The old aim added an unfloored `L/2` to a floored `center()`, a half-pixel destination for odd
        thumb lengths. A mouse drag rounded it away, but a finger, released AT the destination, carried
        it: that alone moved five finger-only tests.
      - `bringcodeStringFromTopInspectorInView`, the verb's sibling on the same thin-geometry math, ran
        in its only caller (`macroAnalogClockInspectEdit`) on a detail pane that does not overflow
        vertically. Under the mouse its drag pressed the pane itself and float-dragged the whole
        inspector window 88 px down, and the committed reference showed that displaced window. On a pane
        with no vertical bar the verb now presses nothing.
      Pin: `macroAddEditSaveRenameRemoveProperty` ends with a value assertion that a row ~85% down the
      list, brought into view from the top, is the one selected (on the old verb, the click raises).
- [x] **A sampled move landed up to a pixel SHORT of its destination** (filed 2026-10-15). **DONE 2026-10-16.**
      `MacroToolkit.expoOut` gains easeOutExpo's `t == d` endpoint case and `_sampleMovePath` samples 0…n
      inclusive, so every sampled move (mouse moves and drags, finger carries and drags) ends ON its
      destination. `macroDuplicateAndPickItUpRidesHand` now asserts the hand at exactly 620@130 (the old
      sampler fails it at 619@130). The corner-handle press keeps its quarter-box offset in
      `_handlePressAndDropPoints`, re-justified by the corner being the triangle's boundary alone.
- [x] **~1 px scrollbars in short viewports** (filed 2026-10-15). **DONE 2026-10-16**, in the three steps filed:
      - (a) **Root cause** (a read-only Opus spike, re-verified): neither overflow came from the scroll
        machinery.
        - `DegreesConverterApp` hard-coded its calc frames at 241×167, and `CalculatingPatchNodeWdgt`
          splits its height 2:1 without looking at the text. After the 2026-08-25 touch-geometry change
          (`5a45a135`: 20 px more window chrome, a 16 px line), the one-line output box got 21 px for
          26 px of text. The frames are now 241×186 (output 27/27, formula 53/53).
        - A toolbar band undocked by dragging its GRIP kept the band's outer size while its 50 px side
          grip became a 50 px title bar, squeezing the payload to 14 px. The "float" menu item re-wrapped
          the payload instead. Both now share one rule (`FrameWdgt._extentWrappingPayloadAt`). The grip
          path reads the extent while the band still grants it (`_beforeBeingGrabbed`) and applies it on
          the hand (`_reactToBeingGrabbed`). Resizing while still the host's child made the host re-fit
          mid-pass, and the settle re-visit gate caught that as a re-visit.
      - (b) **A bar whose frame has no room for its thumb is hidden**
        (`ViewportWdgt._barFrameHasRoomForThumb`). Measured pixel-inert across both suites; zero
        degenerate bars remain.
      - (c) **The corner reserve is what OCCUPIES the corner** (`_cornerReserveFor`):
        - a resizer, `max(scrollBarsThickness, handleSize)`;
        - else the other bar where it crosses, `scrollBarsThickness`;
        - else 0.
        Both are asked of structure:
        - the other bar by its axis's overflow;
        - the resizer by climbing a corner chain: containers name the child that reaches their
          bottom-right corner (`bottomRightCornerReachedBy` on FrameWdgt, InspectorWdgt and the three
          patch nodes), and `HandleWdgt.wouldShow` is the resizer's showing as a query. When a resizer
          flips, its owner tells the viewports down the chain (`noteCornerResizerChanged`, deferred
          through the phase valve).
        It was measured at design time by a second spike before the owner re-confirmed it at the larger
        blast radius. A capture-time cross-check (every shown bar against every visible handle) found
        two cases:
        - one limit: the temporary resize/move halo is not a declared occupant (filed);
        - one false positive: two overlapping windows.
- [x] **`macroTextWdgtCaretKeepsCorrectAlignment` never delivered its image_2 claim** (found 2026-10-16, while
      eyeballing item 2's movers). Its "Enter before the trailing I" click was a recorded fraction that landed
      AFTER the 'I', in every committed reference on both pointers, and its stated carved text was already
      wrong. The click now aims at the slot before the 'I' through the text's own slot geometry, five value
      assertions pin the slot story, and the stated text matches the frames.

### Residue arc 2026-10-16 — its six follow-ups (no plan doc; owner: address all six, any order)
- [x] **Two gate ratchets had slack to bank** (seen 2026-10-16). **DONE 2026-10-16.** Both gains were found
      before writing their reason:
      - `check-stinks.js` `instanceof-type-test` 80 → 77: gesture grammar P3 (`232cbb23`, 2026-08-26) gave
        the macro toolkit `_widgetOfTarget`, which replaced four inline `instanceof Array` identifier tests
        with one.
      - `check-call-separation.js` `BASELINE_U_QUERY` 121 → 120: the census rebuilt at the commit that set
        121 (`97a7a647` + tests `b6912bc54`) and diffed against today. The stuck-thumb-highlight arc
        (`4cc3ec71`, 2026-10-15) made `SliderButtonWdgt` place its thumb from its slider's `rangeSize()`,
        so `SliderWdgt.rangeSize` gained an external caller. Two moves on 2026-08-26 cancel inside the
        span: `ActivePointerWdgt.checkDraggingThreshold` gained a test reference while
        `MacroToolkit.fingerMode` was born @-self-only public.
- [x] **`ListWdgt.selected`'s comment said "actual element"; it holds the ROW** (2026-10-16). **DONE
      2026-10-16.** Measured in-page under both pointers: slot 1 of a row's `select` dispatch is the
      `MenuItemWdgt` (every reader, four in the inspectors and one test, reads `.labelString` off it), and
      slot 2 is always the `ListWdgt` itself (the rows' panel targets the list). `active` stored that slot
      and nothing in either repo read it: owner-directed, it is deleted and `select` takes the row alone.
- [x] **The patch nodes passed a dead constructor argument and split their height without reading their
      text** (spike-found 2026-10-16). **DONE 2026-10-16.**
      - `super new Point 200,400` → `super()` in all three. Measured first: a frame is born 300×300 whatever
        its payload's extent and every product path frames a node at an explicit extent (460×400, 260×265,
        241×186), so honouring the argument would have reached only a node no one frames.
      - `PatchNodeWdgt._heightsSplitByWeights` splits a height by weights, floors each box at
        `TextAreaWdgt.heightShowingOneLine()` (one line at the box's font plus its content inset — a new,
        separately named query, not a `preferredExtentForWidth` override) while the floors fit, and rounds
        at cumulative edges so the boxes sum exactly. The Regex node's ¼/¼/½ split had also overshot its
        node by 1 px at half of all heights (independent rounding: 84+84+167+10 = 345 at the demo's 344);
        at node heights 88–114 its two entry boxes now keep one whole line. The calc node's 2:1 split uses
        the same helper and is identical at every size a test uses (it differs only at node heights
        95–106).
- [x] **`FrameWdgt.floatOutOfDock` placed the frame ignoring its OWN docks** (spike-found 2026-10-16).
      **DONE 2026-10-16.** The position line now subtracts the frame's own left/top dock thickness and a
      side bar's width as well as the padding and title bar. Measured in-page over 12 cases (a Docs frame
      with its toolbar on top, the same with its toolbar on its left, and a toolbar band; each docked at
      every side): the payload's screen top-left is unchanged by the float, where a Docs frame had jumped
      73 px on every side. Pin (owner-placed): `macroDockAnyFrame` floats the docked document window
      through its own menu after its last shot and asserts it popped out in place (the old method fails
      it: 66@224 expected, 66@297 found, both pointers).
- [x] **A finger's corrective list nudge carried less than a mouse's** (measured 2026-10-16). **DONE
      2026-10-16.** Root cause (a read-only Opus spike, re-verified): a touch-down that re-lands on the
      exact pixel the previous stroke lifted from skipped `processPointerDown`'s position head (the down's
      position equalled the hand's), so the thin scroll indicator the lift had emptied stayed thin and the
      press fell through onto the row beneath — moving the list 1 px the wrong way and selecting that row.
      A one-pixel nudge lifts exactly where the next one presses, so every second finger nudge was lost.
      An ABSENT pointer now always runs the head. Blast radius measured in-page before the edit: the head
      fired 129 times across 60 finger tests and all 321 passed; mouse paths cannot reach it (synthetic
      mouse downs state no place). Pin: `macroAddEditSaveRenameRemoveProperty` ends with two nudges that
      must each scroll toward the row and select nothing (the old head fails it under a finger).
- [x] **`macroTextWdgtCaretKeepsCorrectAlignment` aimed two gestures by recorded coordinates** (2026-10-16).
      **DONE 2026-10-16, no recapture.** Measured first: the recorded corner drag grew the box to exactly
      721×436 and the recorded caret fraction landed on the slot after "elit. I", under both pointers. The
      box is now grown to that EXTENT (`dragResizeMoveHandleTo`, the handle's centre moved by the wanted
      growth) and the caret aimed at that SLOT (`slotCoordinates`), each asserted; the desktop menu opens by
      meaning (`openOwnMenuOf world`) and the bare-desktop click that ends the resize mode is asserted by the
      handle count. The drop spot stays as recorded (it places the box, not its lines). Every reference
      still matches at both pointers and both dprs.

### Findings arc 2026-10-24 — fixes that were never BACKLOG lines (no plan doc)
The arc that worked the focus-residue arc's findings also fixed what its research measured on the way (owner-approved):
- [x] A world snapshot could not be saved while Patch Programming was open ("unrecognized type (LinearGradient)"): four
      gradient icon appearances cached a canvas gradient in a serialized field — now `@serializationTransients`; the rig's
      `world.everyAppSnapshot.*` opens every desktop app and saves the world.
- [x] A widget destroyed mid-stroke was grabbed again by the next pressed move and dropped into the tree: the death funnel
      (`Widget._destroyNoSettle`) tells the hand (`noteWidgetDestroyed`), which forgets every booking the dying widget is or
      contains. Pinned by `SystemTest_macroWidgetDestroyedMidStrokeIsNotPickedUpAgain`.
- [x] `allClassFunctions` missed `InputEvent` (see the `classNamed` line in `archive/world-inventory-instruments-plan.md`).
- [x] A resize grip's fractional re-record rode `pressEnded` and was skipped when the release landed elsewhere —
      `SystemTest_macroStretchChildHandleResizeSurvivesReflow` image_1's reference showed the snapped-back plot its own
      assertion calls the planted failure; the re-record moved to `endOfNonFloatDrag` and the reference was recaptured.
- [x] The browser single-test path (`loadAndRunSingleTestFromName`) loaded the wrong test under a selection, a finger filter
      or groups: the loader identifies one test's files by NAME.

### Findings arc 2026-10-24 — residue, closed by the residue arc 2026-10-24 (no plan doc)
The eight items the findings arc left in BACKLOG, assessed in parallel, decided once (the owner, on the three calls: "Do The Right Thing regardless of churn"), executed one unit at a time, each gated; the whole-suite twin prediction matched the rebuilt suite every time.
- [x] **A list row pressed, dragged OFF and released elsewhere kept PRESSED** (the list lost its visible selection while
      `list.selected` was unchanged). **DONE 2026-10-24, no recapture.** A list row's look of being its list's selection is no
      longer a state it keeps: it reads the list's model as it paints (`MenuItemWdgt._shownState` →
      `CommandPanelWdgt.showsAsItsSelection`), so no way of ending a press can leave the look and the model disagreeing.
      `reShowListSelection`, `unselectAllItems`, `unselect`, `showAsSelected`, `_inkMyTag` and five member-row overrides are
      gone; a member row's kind-tag ink is answered at paint (`inkForChildText`). Pinned by
      `SystemTest_macroEveryPressIsToldItsEnding` scene (e), whose two selection checks now read the model.
- [x] **A carried window CLOSED (sent to the bin) mid-stroke was lifted back out of the bin** by the next pressed move.
      **DONE 2026-10-24, no recapture.** A close is the death funnel's twin: `Widget._closeNoSettle` tells the hand the figure
      being put away (`ActivePointerWdgt.noteWidgetClosed`, sharing `_forgetBookingsLeavingWith` with `noteWidgetDestroyed`),
      which cancels the audience members inside it and ends a non-float drag it holds. The bin-icon drop now IS Move to trash
      (through the funnel); the storage sorter and the bin's own window-close state the fact where they happen. Reachable by real
      input only through a user program (a formula fed by the stroke's own slider). Pinned by the renamed
      `SystemTest_macroWidgetDestroyedOrClosedMidStrokeIsNotPickedUpAgain` (sections E–K; K reads the divider's DOM cursor).
- [x] **`MacroToolkit._swipeBoxOf` bounded a translated wheel's swipes by the pane's FULL box** where an enclosing pane clips
      it. **DONE 2026-10-24, no recapture.** The box is the part that shows (`clippedThroughBounds`); no suite swipe box is
      clipped today (29 measured). `macroNestedScrollPanelsRouteWheel` stays mouse-only for its own stated reason (the first
      wheel's later swipes carry the document too).
- [x] **Test metadata `"grabDragThreshold": true` coerced to 1 px** — the premise was FALSE: every test opens with ResetWorld,
      which builds a fresh `PreferencesAndSettings`, so the value never reached the hand; only the key's PRESENCE switched off a
      test-only branch in `ActivePointerWdgt.checkDraggingThreshold` that skipped the threshold for mouse strokes during
      playback. **DONE 2026-10-24.** The key AND the branch are retired (playback runs the product's threshold; the harness
      refuses the key, `checkNoRetiredMetadataKeys`), and the one test the retirement moved exposed a REAL product bug: a widget
      dragged out of a layout host (a document's flow) rode the hand off by the threshold travel, because `grab` applied its
      correction before the release settle re-placed the widget. Every placement relative to the hand now follows that settle.
      `SystemTest_macroSimpleDocumentHandlesOldInspector` gains value assertions (the window lands exactly on the drag's target);
      its FINGER image_3 references (dpr 1+2) had baked the lag in and were recaptured (owner-approved, RECAPTURE COMPLETE).
- [x] **`Example3DPlotWdgt.previousMousePoint` was never reset between strokes.** **DONE 2026-10-24, no recapture.** The spin is
      a fact of one press: anchored at `pressBegan` (`_lastPressedPoint`), dropped at either ending; a drag begun on another
      plot no longer spins this one (measured 199 → 0), and `hoverExited` no longer restarts the auto-rotation while the plot's
      own press is live (measured 47 + 51 steps → 0). Pinned by `SystemTest_macroPlotSpinIsOnePressFact`.
- [x] **A plain `CanvasWdgt`'s drawn pixels may not survive a save** — MEASURED first: they did not (a file save and a world
      snapshot both restored blank paper; a Duplicate kept them), and the measurement found three more: a restored FizzyPaint
      canvas could not be painted on (`TypeError … setTransform` in `getContextForPainting`), a duplicate drew every later line
      at half size at dpr 2, and a restored canvas's saved raster decoded through the widget's scaled context (2× at dpr 2).
      **DONE 2026-10-24, no recapture.** A drawn raster is content: `CanvasWdgt` also holds it as `drawnRaster` (set only by
      `drawLine`/`clear`, so an undrawn canvas and every cache-raster subclass cost a file nothing) and takes it back as its back
      buffer after a restore; `drawLine` re-lays the pixel ratio on its context; `StretchableCanvasWdgt._afterDeserialization`
      rebuilds the painting's context; the `Deserializer` decodes a `$Canvas` at the identity transform. Pinned by five new rig
      checks (`canvas.drawnRasterRoundtrip`, `world.drawnCanvasSurvives`, `canvas.duplicateDrawsAtPixelRatio` and
      `stretchable.paintableAfterRestore` on a page pinned to dpr 2, `file.drawnCanvasPixels`), each failing on the old code.
- [x] **A selectable `StringWdgt`'s press during a drag-scroll** (owner call). **DONE 2026-10-24, no recapture.** An un-armed
      finger press on selectable text passes the press on (`StringWdgt.pressBegan` asks `strokeMeansMouseDrag()`), so a swipe
      over text scrolls the pane under it, as iOS and Android do; mouse, pen and an armed finger still keep it. The text's
      selectable flag is disarmed by a hover move — a mouse's notion — and could not decide a finger stroke. Pinned by
      `SystemTest_macroFingerSwipeOverSelectableTextScrolls`.
- [x] **`check-raw-pointer-reads` did not scan MIXIN bodies.** **DONE 2026-10-24.** The shared
      `buildSystem/lib/coffee-method-header.js` owns the grouping too (`methodBoundary` / `methodSpans`, mixin-DSL aware), and
      nine gates and censuses use it (three private copies deleted): +6 handler bodies scanned, +32 dead-method names, 8 mixins
      under plane-discipline C, +9 menu verbs — zero findings; a planted mixin raw read fails the gate and passed the old one.
      Also fixed: an exemption marker inside the previous method's body no longer exempts the next handler.

### Residue arc 2026-10-24 — residue, closed by the residue-2 arc 2026-10-25 (no plan doc)
The five items the residue arc left in BACKLOG, assessed in parallel by three read-only agents, decided once (the owner took every recommendation), executed one unit at a time, each gated; every whole-suite twin prediction matched the rebuilt suite (no recapture in the whole arc).
- [x] **A `SimpleImageWdgt` restored from a file or a snapshot painted BLACK.** **DONE 2026-10-25, no recapture.** A widget
      keeps no memo of its back buffer: the image widget paints on every NEW raster `CanvasWdgt` hands it (it compares its back
      buffer before and after `super`), lays black paper under every paint (a scaled SWCanvas draw leaves part-transparent edge
      pixels), and holds its image path as its one saved truth — `img`/`imageLoaded` are transients reloaded by
      `_afterDeserialization` (a memo-only fix still lost the slow-image race: black forever natively, a thrown first paint and a
      hidden widget under SWCanvas). The same defect, measured live, in `VideoPlayerCanvasWdgt` (its letterbox restored in its
      paper colour) — fixed the same way. Both classes ship only with `--includeVideoPlayer`, so no suite, rig or smoke can reach
      them: the cover is a new build gate, `buildSystem/check-back-buffer-memos.js` (every field a back-buffer builder writes is a
      transient of the class chain or declared `# saved-content:`), which reads every part; it fails on HEAD's two classes and on a
      stripped marker.
- [x] **A drawn raster saved at one pixel ratio and loaded at another was copied 1:1.** **DONE 2026-10-25, no recapture.** Worse
      than filed: through the SWCanvas file door the drawing was lost outright (the door attaches before the decode, and the
      first paint's resize copied the still-empty canvas). FizzyPaint's half (filed INFERRED) measured TRUE, and a third carrier
      was found: a pinned menu's row icons (`InertIconHolderWdgt.raster`). The `$Canvas` record now states the ratio its physical
      pixels were made at (`pr`), and the Deserializer builds the canvas at this page's size and resamples at the DECODE
      (smoothing when it shrinks, pixel replication when it enlarges, so 1 → 2 → 1 is exact); equal ratios stay byte-identical.
      Seven new rig checks over three pages pinned to ratios 2, 1, 2; each fails on the old code.
- [x] **SWCanvas encoded `toDataURL` as an UNCOMPRESSED PNG.** **DONE 2026-10-25, no recapture.** SWCanvas `031f828` (branch
      `png-deflate` off `main`, in its own worktree): per-row PNG filters by minimum sum of absolute residuals + LZ77 with FIXED
      Huffman codes (`compressionLevel` 0–9, default 6; level 0 = the old stored bytes exactly); lossless, synchronous, identical
      bytes on V8 and JSC; 0.89–1.20× the browser's own size on the two measured drawings and ~2× faster than the stored encoder
      on real rasters; dynamic codes measured not worth it. A golden-hash core test pins it; 176 committed SWCanvas PNGs
      regenerated, all pixel-identical (34.95 MB → 0.50 MB). Fizzygum's pin bumped `149a51c` → `031f828`: the whole suite green
      at both pointers × both ratios, both rigs green; a drawn dpr-2 canvas now saves as a ~5 KB file (was ~230 KB). ⚠ The filed
      vendoring premise was wrong: the SWCanvas checkout's 6 `sw3d` commits sit on a branch that DIVERGED before the pinned
      font-symbols commit, so vendoring from it would have dropped that commit; the sw3d work is a separate bump.
- [x] **`MacroToolkit._touchScrollBy` read the swipe box ONCE per wheel call.** **DONE 2026-10-25, no recapture.** The research
      found a PRODUCT defect behind it: a drag-scroll stroke's release flush was paid by the first FRAME after the release, so a
      frame that drained one stroke's release and the next press let that press stop the step before it paid — the first
      stroke's tail lost, by an amount set by cadence (`Fizzygum-tests/DETERMINISM.md` §3l). The stroke now ends at its own
      event (`ViewportWdgt.pressEnded`/`pressCancelled` pay the flush; frames only sample while the stroke lasts). The toolkit
      holds a translated wheel's later swipes and the macro pump queues each once the one before it has drained, re-reading the
      box and aim-checking it on the pane. Pinned by `SystemTest_macroWheelOverAPaneAtItsEndScrollsTheEnclosingPane` (fails on
      the old toolkit under a finger) and `SystemTest_macroTwoScrollStrokesInOneFrameKeepBothTravels` (makes the shared frame BY
      CONSTRUCTION; reads 18 against 58 on the old ViewportWdgt), both assertion-only, both pointers.
- [x] **Two build scripts kept their own method grouping.** **DONE 2026-10-25.** `check-stinks.js` keys a mixin member at the
      indent the shared grouping locks (`mixinMemberIndent` — two mixins are 4-space, 55 lines had been attributed to
      `onceAddedClassProperties`); `census-widget-conformance.js` facet 5 reads methods through `methodSpans` (a mixin setter
      counts; 78 → 79). Folded in, the shared parser's own blind spot: it had no rule for a 2-space class-side `@name:` key, so 109
      static methods were nobody's (422 of their lines credited to the instance method above). A class-side method is now a span
      of its own (`static: true`); `check-layering` reads its tier from the bare name and `check-dead-methods` inventories it.
      What that exposed, fixed structurally: `FooterBandLayout.@arrange` → `@_arrange` (rule `[F]`: an in-pass placement wearing
      a public name), `InfoDocs.@_buildInfoDocNextTo` folded into its single caller `@createNextTo` (rule `[G]` ×4), and the dead
      `StackElementsSizeAdjustingWdgt.@includeInNewWidgetMenu` deleted (`lint-and-static-checks.md` §6b, "a FOURTH time").

### Save/restore-fidelity arc 2026-10-25 — five items closed (no plan doc)
Two items from the redesign section and three from the residue-2 arc's residue, assessed in parallel by three read-only agents, decided once (the owner took every recommendation, and extended the scope to two video-player classes for item 4), executed one unit at a time, each gated; every whole-suite twin prediction matched the rebuilt suite to the screenshot hash. One recapture (54 references, owner-approved, by name).
- [x] **"Save to file…" on a window that holds content was refused** (redesign W6 follow-up) **and the Examples folder's desktop
      icon could not be serialized on its own** (redesign W4 R1). **DONE 2026-10-25, no recapture.** One root: a window kept its
      empty-state placeholder OFF its tree while it held content, so a single-widget save met a widget outside its structure (a
      world snapshot passed only because its policy CAPTURES what a widget save refuses). Wider than filed: any folder or
      document icon whose window holds content, and nested windows, were refused too; and a COPY of such a window SHARED the
      original's placeholder (the Duplicator keeps an outside widget by reference) — destroying the copy destroyed it, and
      emptying the original then mounted a destroyed widget, unseen by the inventory. The fix makes the options unnecessary: a
      frame's placeholder exists only while it is shown (built when the frame empties, destroyed when contents arrive), so no
      widget is kept off-tree and `@offTreeOwnedWidgetFields` and the inventory's walk of it are deleted. Accepted cost (owner):
      a customized hint reverts to "Drop a widget in here" after a fill/empty cycle. Covered by four rig checks
      (`window.holdingContentSerializes`, `window.holdingContentRestoredEmptiesToPlaceholder`,
      `duplicate.windowOwnsItsPlaceholder`, `examples.iconSerializesAlone`), two file-door checks
      (`file.windowHoldingContentSaves`, `file.examplesIconSaves`) and the rewritten
      `world.teardownHygiene.loadLeavesNoOrphanedWidgets` ("no frame keeps a placeholder it does not show"), each failing on the
      old code.
- [x] **A restored pinned menu did not match a freshly built one at the same ratio.** **DONE 2026-10-25, no recapture.** The
      filed ~5,097 px was a PROBE artifact — the fresh menu, popped up last, was the focused frame (equal focus: 0 px at both
      ratios, both pages). But the restore WAS unfaithful another way, which a later unit found: a menu whose title is wider than
      its rows pinned at its pop-up width and re-laid to its rows at any later add (a drop, a restore, a duplicate), and a pinned
      prompt never re-took its width at all. The rule stays (a pop-up widens for its title; a window — a pinned menu — takes its
      rows' width and crops or hides its title), and the width is re-taken at the lifetime change itself
      (`FrameWdgt._setLifetimeNoSettle`, and `fullCopy` for a copy born furniture) — a function of rows, title and lifetime,
      never of history. Covered by `pinnedMenu.sameRatioMatchesFresh` (+ `.longTitle`), `pinnedMenu.longTitleWidthIsItsOwn`,
      `pinnedPrompt.longTitleWidthIsItsOwn` and the assertion-only `SystemTest_macroPinnedMenuKeepsItsWidthWhenMoved`.
- [x] **A `$Image` record stored the ABSOLUTE `file://` path.** **DONE 2026-10-25, no recapture.** Stale as filed for images (the
      image widget's element was already a transient); the live carriers were `$Video` (absolute src, no path field) and a
      duplicate race (a copy claimed a load it never made). Decided: an element the page loads is a PAGE FACT derived from its
      holder's own path — the Serializer has no element encoder and refuses one in a saved field, the Duplicator leaves it
      `undefined`, the holder re-makes it after a restore and a copy, and `whenReady` awaits a hook's load; `SimpleImageWdgt` and
      `VideoPlayerCanvasWdgt` (scope extended by the owner) follow it, and gate #30 `check-page-loaded-elements.js` holds every
      part to it. Rig checks `image.elementInAFieldRefused` / `video.elementInAFieldRefused` fail on the old code.
- [x] **A fresh overflowing viewport's first drag-scroll "re-fit its contents"** (40 px → offset 28). **DONE 2026-10-25,
      recapture 54 references (owner-approved).** The premise was half wrong: on-screen travel was always exact; the plane's
      frame (content ∪ visible window) retreated past the vacant strip above the content once the window left it, so the offset
      was renumbered and the strip could never be scrolled back to (40 up + 40 down left the text 12 px short; an overflow
      smaller than the strip left the pane stuck; the thumb jumped). The frame now also covers the viewport's own box, the
      window at rest. Pinned by the assertion-only `SystemTest_macroScrollingBackReturnsContentToWhereItRested` (6 assertions
      fail on the old code, both pointers); the two-strokes test's control reads 40 and 70. The recapture: 9 mouse + 6 finger
      tests at both ratios, 8 of them a 4 px scroll-thumb column, `MenuPinnedInScrollPanel` ~3 px of content.

### SWCanvas correctness arc 2026-10-27 — the residue-2 arc's three SWCanvas items, and fixes that were never BACKLOG lines (no plan doc)
The arc fixed SWCanvas's queued defects (six of them filed in the redesign section; those closures are in the redesign
plan's ledger) and, under the owner's triage rule (fix what reaches Fizzygum's tests or usage, or is egregious; the minors
go to BACKLOG), the egregious ones it found. One SWCanvas commit (`85a18e8`), one pin bump, one recapture (mouse and
finger, dpr 1 and 2: 1,282 references in 199 tests, predicted hash-exactly by a whole-suite twin and attributed fix by fix).
The decision records are SWCanvas `DIRECT-RENDERING-SUMMARY.MD` §9 entries 19–31.
- [x] **SWCanvas's scaled `drawImage` sampled outside the source as TRANSPARENT.** **DONE 2026-10-27**: `drawImage` follows
      HTML5's rectangle and filtering rules — the bilinear taps clamp to the edge texel, a source rect reaching outside the
      image is clipped to it (and the destination in proportion), negative sizes name the same rect from the opposite corner
      (§9 entry 25; core tests 083, 084). It moved the rims of rotated, tilted and zoomed islands (70 shots in 38 tests,
      faded → solid). The same unit made patterns sample by the same rule (owner: one image-sampling rule), and a follow-up
      put both at the pixel CENTRE (`Rasterizer.centreTranslation`): a plain blit under a non-power-of-two scale (dpr 3, a
      3× zoom) picked wrong texels in 250 of 282 draws at scale 3 (core test 093; 0 Fizzygum references moved at dpr 1/2).
- [x] **SWCanvas's radial gradient ignored `ctx.scale`.** **DONE 2026-10-27**, wider than filed: gradients AND patterns are
      evaluated in paint space — each device pixel centre mapped through the inverse CTM — so they transform under any
      affine, and the radial gradient is HTML5's two-circle cone (§9 entries 25–26; core tests 085, 086, visual 214). It
      moved the colour palette (12 shots in 4 tests).
- [x] **SWCanvas committed 5 PNGs nothing regenerated.** **DONE 2026-10-27**: the runner set `global.SWCanvas` after the
      visual tests ran, so the two isPointIn path2d tests failed silently (it now sets it first, and their PNGs regenerate);
      `139-shadow-basic-test`/`140-shadow-stroke-test` are deleted; the debug scripts write next to themselves into the
      git-ignored `debug/`; and `npm test` now fails on a visual test that cannot render or write its PNG, a core test whose
      `savePNG` cannot write, and any committed PNG no test wrote in the run (an orphan, in `tests/output/` or
      `tests/dist/output/`).
- [x] Never a BACKLOG line — found by the arc, egregious, fixed: the filler skipped edges with 0 < |dy| < 1e-10, losing a
      WHOLE ROW (a 2e-15 nudge did it; §9 entry 21, core 090); a cubic whose ends coincide painted nothing and a point-sized
      quadratic overflowed the stack (§9 entry 28, core 091–092); a Path2D `ellipse()` opening a subpath left `closePath()`
      stroking to (0, 0) (same entry); `strokeLine`/rotated `strokeRect` sampled pixel CORNERS, so the clock's butt hands
      sat half a pixel off and moved with position (§9 entry 20, core 095); round caps and joins were flattened at a fixed
      π/4 step (icon caps ≥ 48 device px off by 4–8 px; core 096); shadows were alpha ×8 (a 0.5-alpha shadow painted 255,
      HTML5 128) and their blur lost coverage (§9 entry 29, core 097); `drawImage` under `copy` and the other canvas-wide
      composites kept stale pixels outside the image (§9 entry 30, core 098); source-over and destination-over onto
      TRANSLUCENT pixels mixed the colours as if the destination were opaque (§9 entry 31, core 099); the filler visited
      every edge on every row (now an active-edge table, byte-identical, §9 entry 21); and the browser test page could not
      run the core tests or load fonts — it now runs the same core and visual registries as Node and is gated headless
      (`npm run test:browser`, Chromium and WebKit: every render byte-identical to Node's).
- Decided, not bugs: an image drawn piecewise equals the whole up to 1 level of float rounding at 8-bit ties;
  `isPointInPath` counts edge points as inside (the spec); unknown fill-rule strings stay lenient (nonzero); a draw that is
  only a fractional TRANSLATION samples nearest-neighbour (no resampling); opaque `fillStrokeRoundRect` +2–5% (owner-accepted).

### SWCanvas correctness arc, follow-ons 2026-10-28 (no plan doc)
Four items the owner picked after the arc's commit: two SWCanvas fixes stacked on `85a18e8` (same branch, SWCanvas
`ccfd6ab`, one more pin bump), two Fizzygum-side defects, and the Fizzygum half of the tie item (the folder icon).
A whole-suite twin predicted the pin bump's footprint before anything was rebuilt: one shot, at dpr 2 on both pointers.
- [x] **`scripts/recapture.js` contradicted itself and exited 0** (Fizzygum-tests). **DONE 2026-10-28**: a name that is
      not a test is refused (exit 2) before anything is cleaned or run, and a capture that failed twice now fails the
      verdict (`❌ RECAPTURE INCOMPLETE`, exit 1, listed under "FAILED TO CAPTURE") whatever the suite says. The suite
      alone could not see one for a test it does not run at that density or pointer kind (an `SWCanvasBrokenTests`
      entry, a pointer filter), which also answers the item's open question: a REAL test could reach the same false
      green that way. Proven with a stubbed run (captures failing, suite green → INCOMPLETE, exit 1; captures passing →
      COMPLETE, exit 0).
- [x] **The demo Test menu dispatched harness-only verbs on a build without the harness** (G-B finding, wider than
      filed). **DONE 2026-10-28**: not only the two spacer rows — five of `DemoMenus.testMenu`'s rows ("Serialise widget
      to memory", both "Deserialize from memory…", "Make spacers transparent/opaque") named methods only
      `WidgetTestSupport` installs, so on `--profile dev-notests` all five resolved to nothing, and
      `LayoutSpacerWdgt`'s two methods threw on their bare `super`. The menu offers those rows only `if
      WidgetTestSupport?`, and a spacer (a leaf: it takes no drops and builds no children) no longer calls up into the
      harness's subtree sweep. Measured with an in-page probe on both trees: dev-notests 14 rows / 5 unresolved / both
      spacer methods throwing → 9 rows / 0 / both working; the harness page keeps all 14 rows, all resolving. ⚠
      `check-menu-actions.js` and `check-unresolved-sends.js` resolve against `src` AND the harness source together, so
      a SHIPPING caller of a member only the harness installs is invisible to them; this was found by reading, and a
      `dev-notests` boot is the only place it shows (filed in BACKLOG).
- [x] **A stroke's pixel at an exact tie depended on where it was drawn** (the "anchor" item, its STROKE half). **DONE
      2026-10-28**: `StrokeGenerator` strokes a path relative to the floor of its first point and `PolygonFiller` fills
      the parts in their device frame; `strokeLine` and `isPointInStroke` take the same frame (SWCanvas §9 entry 32,
      core test 100). Position-dependent tie pixels went to 0 for every join and cap kind at scale 1 and 2 (from ~2400
      per join kind, 1887–1947 butt caps, 570–648 square, 330 round), the clock's butt hands stopped depending on
      position, and 5 SWCanvas PNGs moved (118 px, every one within 1e-9 px of an edge). FILLS were measured and kept
      on absolute arithmetic: a frame there made `FolderIconAppearance` depend on position on the desktop, because the
      icon computed its slant at the device position — the fill half stays open in BACKLOG. Fizzygum: one shot, the
      Dots wallpaper's tile (a 45° butt stroke whose ends pass exactly through pixel centres) at dpr 2, mouse and finger:
      2 tile pixels flip; neither tile matches exact geometry (the corners are irrational), and the new one is the same
      wherever it is drawn.
- [x] **Round joins never emitted the inner triangle.** **DONE 2026-10-28**: a round join adds it under the miter and
      bevel rule (`_innerTriangleUncovered`), so a thick stroke on a tight curve is the same on its inner side whatever
      the join (missing inner px vs the polyline sweep, round: arc 6249 → 2566, ellipse 3716 → 2237, cubic 4051 → 268,
      arcTo 2328 → 8, each now equal to miter). SWCanvas §9 entry 33, core test 101; 0 SWCanvas PNGs, 0 Fizzygum shots.
- [x] **`FolderIconAppearance`'s art depended on where it was painted** (G-A finding). **DONE 2026-10-28**, and not an
      engine tie as filed: the icon computed its slant's inset vertex at its box's absolute device position, a
      non-dyadic run/rise (5/7) along a row, so the INPUT already differed by position — desktop and translated paints
      re-round it at that same magnitude and agreed with themselves, but a back buffer or a drag image (translated by
      −x0, −y0) did not (22 sizes at dpr 1, 12 at dpr 2; S 80 at dpr 2 is the desktop glyph). It now computes with its
      box at (0, 0) and translates there. Replica on the new engine: 0 position-dependent pixels in all three paints at
      dpr 1 and 2, and the three agree; desktop paints change 0 px. Whole-suite twin: 0 shots move.
