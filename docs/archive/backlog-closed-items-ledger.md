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
