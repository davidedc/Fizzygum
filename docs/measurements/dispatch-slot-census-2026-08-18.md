# Dispatch-slot reader census — 2026-08-18

Phase 0 deliverable of `docs/plans/dispatch-slot-protocol-plan.md` (§3). Measured at Fizzygum
`932d1f0a` / Fizzygum-tests `1e92ff051`, against the 2026-08-18 build. The question: for every
reachable (receiver class, action) pair of `ButtonWdgt`'s four-slot dispatch

```coffee
@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, @argumentToAction1, @argumentToAction2
```

what do the verbs' first two parameters DECLARE and READ?

## Instruments and coverage

- **Runtime half** (`Fizzygum-tests/.scratch/dispatch-slot-census-probe.js`): the menusweep walk
  (`scripts/menu-click-sweep-headless.js`) copied verbatim, recording per pair the slot contents at
  dispatch time (identity-classified), the delivery path, and the owning class. Pair-set parity
  with the real rig verified: **identical 631-pair sets**.
- **Static half** (`.scratch/dispatch-slot-census-analyze.js`): per distinct owner.action method,
  the CoffeeScript source resolved via the sanctioned header parser
  (`buildSystem/lib/coffee-method-header.js`), parameters extracted, reads determined on
  comment-stripped bodies. Isolation probe for the one live finding:
  `.scratch/holder-setcolor-isolation-probe.js`.
- **Reach**: 18/18 roots (both world-menu shapes + 16 representative classes), depth ≤ 4,
  3406 menu dispatches + 38 prompt Oks across 407 menus → **631 distinct pairs**, which collapse
  to **208 distinct methods** on 13 owning classes. Same coverage model (and same stated blind
  spots) as the gauntlet's menusweep leg; the 4 skipped actions + 1 skipped prompt are the rig's
  documented headless-hostile set.
- **Honesty items**: bucket (e) statically-unresolvable = **0**. 21/208 methods resolve only from
  the live compiled function — all 21 declare ZERO parameters, so their classification is certain
  regardless (12 are the space-before-colon headers of by-catch finding 1; 9 install from the
  tests repo at boot: `serialiseToMemory` family, `Automator*`, `popUpSystemTestsMenu`). The wire
  cross-tab uses bare-prototype `pins()` (appearance-contributed pins invisible — pinsweep's
  documented split), so wire overlap is a floor, not a ceiling. No method reads `arguments`
  (checked). The pair count is breadth, not a ratchet (the `attach…`-family reshuffle).

## The two structural facts

**1. The two fill configurations partition EXACTLY by delivery family — no verb sees both.**

| family | pairs | slot 1 held | slot 2 held |
|---|---|---|---|
| menu rows (env-absent fill) | 594/594 | the ROW ITSELF (100%) | the rows panel's `@target` — the menu's subject |
| prompt Oks (env-present fill) | 37/37 | the panel target = the RECEIVER itself (100%) | the prompt's environment: `StringFieldWdgt` / `ColorPickerWdgt` |

Zero pairs were reached through both families; zero menu rows used the env-present fill; zero
prompt Oks used the env-absent fill. And the split is statically TOTAL, not just
reachable-practice: the only writers of a rows panel's `environment` in the whole tree are the
three prompt classes (`PromptWdgt:117`, `ColorPromptWdgt:18`, `SaveShortcutPromptWdgt:38`);
no `MenuWdgt` construction site passes one. **The `if !@environment?` crossover in
`MenuRowsPanelWdgt.createMenuItem` is a disguised "am I a prompt or a menu" test.**

**2. Bucket (a) dominates: 173/208 methods (83%) declare no parameters at all.** Only 35 methods
declare anything; 34 of them read at least one slot. Slot positions 3/4
(`argumentToAction1/2`) are populated by exactly ONE reachable pair in the tree
(`Wallpaper.setPatternFromMenu`, arg1 = the pattern name; `PanelWdgt.makeFolderFromMenu` declares
positions 3/4 but the reachable row leaves them undefined).

## Bucket counts (per §3, unit = method; buckets b/c/d overlap)

| bucket | count | composition |
|---|---|---|
| (a) takes nothing | **173** | full list in the appendix |
| (b) reads slot 1 | **31** | 23 menu-family + 8 prompt-family |
| (c) reads slot 2 | **14** | 7 menu-family + 7 prompt-family |
| (d) declares-but-ignores ≥ 1 slot | **6** | every ignored slot is already NAMED `ignored`/`ignored2` |
| (e) unresolvable | **0** | (21 resolved from compiled JS only, all zero-arity) |

**Within each family, every reader already agrees on what each slot means:**

- Menu family, slot 1 (23 readers): ALL read it as **the opening row** — 20 name it
  `widgetOpeningThePopUp` (the pop-up openers; the §2-falsified-ground consumer contract), 3 name
  it `menuItem` (`cornerRadiusPopout`, `transparencyPopout`, `setPatternFromMenu`). No menu verb
  reads slot 1 as anything else.
- Menu family, slot 2 (7 readers): ALL read it as **the menu's subject** (the panel's target) —
  `widgetThisMenuIsAbout` ×3, `targetWidget` ×2, `theWidgetToBeAttached` ×2. (The
  subject-routing law still applies: this is right exactly because each reached row's panel was
  built ABOUT that subject.)
- Prompt family (8 setter methods): ALL follow the documented SHAPE
  `(valueOrWidget, widgetGivingValue)` — slot 2 read first as the value-giving widget, slot 1 the
  fallback value leg — **except the one that doesn't, and it is a live bug** (finding 2 below).
- Wire family (slot 1 = the value, slot 2 = undefined): 2682 pin-setter advertisements over 31
  distinct setter names; **7 census methods overlap it exactly** — precisely the SHAPE setters
  (`setColor`/`setAlphaScaled` families), which is why the SHAPE exists. 12 pins carry a
  `_<setter>Connector` shim (an existing per-pin mechanism that already diverts wire delivery
  away from a shared verb — prior art for option O4).

So the instability the plan set out to measure is **not** per-verb disagreement about slot
meanings. It is one shared dispatch carrying two disjoint sub-protocols, selected by a hidden
conditional, with the four field/parameter names honest for neither.

## The reader table (all 35 methods declaring ≥ 1 parameter — the Phase 2 per-verb checklist)

| method (owner.action) | declared signature | slot 1 | slot 2 | fill(s) seen | via | wire |
|---|---|---|---|---|---|---|
| BoxyAppearance.cornerRadiusPopout | `(menuItem)` | READ as `menuItem` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpArrowsIconsMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpDocumentMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpFirstMenu | `(widgetOpeningThePopUp, widgetThisMenuIsAbout)` | READ as `widgetOpeningThePopUp` | READ as `widgetThisMenuIsAbout` | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpGraphsMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpIconsMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpMapsMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpMore1IconsMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpMore2IconsMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpMore3IconsMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpPatchProgrammingMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpSecondMenu | `(widgetOpeningThePopUp, widgetThisMenuIsAbout)` | READ as `widgetOpeningThePopUp` | READ as `widgetThisMenuIsAbout` | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpShortcutsAndScriptsMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpSimpleTextWdgtMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpSupportDocsMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpVerticalStackMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| DemoMenus.popUpWindowsMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| MenusHelper.popUpDevToolsMenu | `(widgetOpeningThePopUp, widgetThisMenuIsAbout)` | READ as `widgetOpeningThePopUp` | READ as `widgetThisMenuIsAbout` | env-absent (row, target) | menu-row | — |
| PanelWdgt.makeFolderFromMenu | `(ignored, ignored2, name, folderWindow)` | ignored (`ignored`) | ignored (`ignored2`) | env-absent (row, target) | menu-row | — |
| PanelWdgt.setAlphaScaled | `(alphaOrWidgetGivingAlpha, widgetGivingAlpha)` | READ as `alphaOrWidgetGivingAlpha` | READ as `widgetGivingAlpha` | env-present (target, environment) | prompt-ok | YES |
| PanelWdgt.setColor | `(aColorOrAWidgetGivingAColor, widgetGivingColor)` | READ as `aColorOrAWidgetGivingAColor` | READ as `widgetGivingColor` | env-present (target, environment) | prompt-ok | YES |
| ScrollPanelWdgt.setAlphaScaled | `(alphaOrWidgetGivingAlpha, widgetGivingAlpha)` | READ as `alphaOrWidgetGivingAlpha` | READ as `widgetGivingAlpha` | env-present (target, environment) | prompt-ok | YES |
| ScrollPanelWdgt.setColor | `(aColorOrAWidgetGivingAColor, widgetGivingColor)` | READ as `aColorOrAWidgetGivingAColor` | READ as `widgetGivingColor` | env-present (target, environment) | prompt-ok | YES |
| Wallpaper.setPatternFromMenu | `(menuItem, ignored2, thePatternName)` | READ as `menuItem` | ignored (`ignored2`) | env-absent (row, target) | menu-row | — |
| Wallpaper.wallpapersMenu | `(ignored, targetWidget)` | ignored (`ignored`) | READ as `targetWidget` | env-absent (row, target) | menu-row | — |
| Widget.newParentChoice | `(ignored, theWidgetToBeAttached)` | ignored (`ignored`) | READ as `theWidgetToBeAttached` | env-absent (row, target) | menu-row | — |
| Widget.newParentChoiceWithHorizLayout | `(ignored, theWidgetToBeAttached)` | ignored (`ignored`) | READ as `theWidgetToBeAttached` | env-absent (row, target) | menu-row | — |
| Widget.setAlphaScaled | `(alphaOrWidgetGivingAlpha, widgetGivingAlpha)` | READ as `alphaOrWidgetGivingAlpha` | READ as `widgetGivingAlpha` | env-present (target, environment) | prompt-ok | YES |
| Widget.setColor | `(aColorOrAWidgetGivingAColor, widgetGivingColor)` | READ as `aColorOrAWidgetGivingAColor` | READ as `widgetGivingColor` | env-present (target, environment) | prompt-ok | YES |
| Widget.setCornerRadius | `(radiusOrWidgetGivingRadius, widgetGivingRadius)` | READ as `radiusOrWidgetGivingRadius` | READ as `widgetGivingRadius` | env-present (target, environment) | prompt-ok | — |
| Widget.transparencyPopout | `(menuItem)` | READ as `menuItem` | — | env-absent (row, target) | menu-row | — |
| WidgetHolderWithCaptionWdgt.setColor | `(theColor, ignored)` | READ as `theColor` | ignored (`ignored`) | env-present (target, environment) | prompt-ok | YES |
| WorldWdgt.layoutTestsMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| WorldWdgt.popUpDemoMenu | `(widgetOpeningThePopUp)` | READ as `widgetOpeningThePopUp` | — | env-absent (row, target) | menu-row | — |
| WorldWdgt.popUpDemoTestMenu | `(widgetOpeningThePopUp, targetWidget)` | READ as `widgetOpeningThePopUp` | READ as `targetWidget` | env-absent (row, target) | menu-row | — |

## Appendix — the 173 zero-parameter methods, by owning class (`*` = resolved from the live compiled function)

- **Automator** (1): showTestSource*
- **AutomatorPlayer** (4): runAllSystemTestsFastSpeed*, runAllSystemTestsFastestSpeed*, runAllSystemTestsNormalSpeed*, saveFailedScreenshots*
- **DemoMenus** (112): analogClock, create2DAxis, createAlignCenterIconWdgt, createAlignLeftIconWdgt, createAlignRightIconWdgt, createArrowEIconWdgt, createArrowNEIconWdgt, createArrowNIconWdgt, createArrowNWIconWdgt, createArrowSEIconWdgt, createArrowSIconWdgt, createArrowSWIconWdgt, createArrowWIconWdgt, createBinIconWdgt, createBoldIconWdgt, createBrushIconWdgt, createCFDegreesConverterIconWdgt*, createCalculatingPatchNode, createChXIconWdgt, createChXXIconWdgt, createChXXXIconWdgt, createChangeFontIconWdgt*, createCloseIconButtonWdgt, createCollapsedStateIconWdgt, createDecreaseFontSizeIconWdgt, createDestroyIconWdgt, createDiffingPatchNode, createDocumentWdgt, createEmptyInternalWindow, createEmptyWindow, createEraserIconWdgt, createExample3DPlot, createExampleBarPlot, createExampleFunctionPlot, createExampleScatterPlot, createExampleScatterPlotWithAxes, createExternalLinkIconWdgt, createFanout, createFizzygumLogoIconWdgt*, createFizzygumLogoWithTextIconWdgt*, createFloraIconWdgt, createFolderIconWdgt, createFormatAsCodeIconWdgt, createFridgeMagnets, createHeartIconWdgt, createImageWdgt, createIncreaseFontSizeIconWdgt, createInformationIconWdgt, createItalicIconWdgt, createLittleUSAIconWdgt*, createLittleWorldIconWdgt*, createMapPinIconWdgt*, createNewClippingBoxWdgt, createNewNonWrappingSimpleTextWdgtWithBackground, createNewStringWdgtWithBackground, createNewStringWdgtWithoutBackground, createNewTextWdgtWithBackground, createNewWrappingAndNonWrappingSimpleTextWdgtWithBackground, createNewWrappingSimpleTextWdgtWithBackground, createNonWrappingSimpleTextPanelWdgt, createNonWrappingSimpleTextScrollPanelWdgt, createObjectIconWdgt, createPaintBucketIconWdgt, createPencil1IconWdgt, createPencil2IconWdgt, createRasterPicIconWdgt, createRegexSubstitutionPatchNodeWdgt, createSaveIconWdgt*, createScooterIconWdgt, createScratchAreaIconWdgt, createShortcutArrowIconWdgt, createSimpleButton, createSimpleDocumentScrollPanelWdgt, createSimpleLinkWdgt, createSimpleSlideIconWdgt*, createSimpleVerticalStackPanelWdgt, createSimpleVerticalStackPanelWdgtAndScrollPanel, createSimpleVerticalStackPanelWdgtAndScrollPanelFreeContentsWidth, createSimpleVerticalStackPanelWdgtFreeContentsWidth, createSimpleVerticalStackScrollPanelWdgt, createSimpleVerticalStackScrollPanelWdgtFreeContentsWidth, createSimpleVideoLinkWdgt, createSlideWdgt, createSliderWithSmallestValueAtBottomEnd, createStretchablePanel, createSwitchButtonWdgt, createTemplatesIconWdgt, createTextboxIconWdgt, createToolsPanel, createToothpasteIconWdgt, createTypewriterIconWdgt*, createUSAMapIconWdgt, createUncollapsedStateIconWdgt, createUnderCarpetIconWdgt, createVaporwaveBackgroundIconWdgt*, createVaporwaveSunIconWdgt*, createVideoPlayIconWdgt, createWelcomeMessageWindowAndShortcut, createWidgetIconWdgt, createWorldMapIconWdgt, createWrappingAndNonWrappingSimpleTextPanelWdgt, createWrappingAndNonWrappingSimpleTextScrollPanelWdgt, createWrappingSimpleTextPanelWdgt, createWrappingSimpleTextScrollPanelWdgt, makeBouncingParticle, makeEmptyIconWithText, makeFolderWindow, makeGenericObjectIcon, makeGenericReferenceIcon, makeIconWithText, makeSlidersButtonsStatesBright, throwAnError
- **IconicDesktopSystemWindowedApp** (1): createOpener — the sweep's founding bug (`inWhichFolder` receiving a MenuItemWdgt); its fix was to declare nothing
- **MenusHelper** (2): binIconAndText, newScriptWindow
- **PanelWdgt** (1): keepAllSubwidgetsWithin
- **Widget** (24): attach, attachWithHorizLayout, close, closeChildren, collapse, createConsole, createPointerWdgt, createReferenceFromMenu, deserialiseFromMemoryAndAttachToHand*, deserialiseFromMemoryAndAttachToWorld*, duplicateMenuAction, fullDestroy, hide, inspect, makeSpacersOpaque, makeSpacersTransparent, pickUpMenuAction, popUpColorSetter, removeOutputPins, serialiseToMemory*, showOutputPins, showResizeAndMoveHandlesAndLayoutAdjusters, toggleIsLockingToPanels, unCollapse
- **WidgetFactory** (24): createBorderLayoutScaffold, createNewAnimationDemo, createNewBoxWdgt, createNewCanvas, createNewCircleBoxWdgt, createNewColorPaletteWdgt, createNewColorPaletteWdgtInWindow, createNewColorPickerWdgt, createNewGrayPaletteWdgt, createNewGrayPaletteWdgtInWindow, createNewHandle, createNewLayoutElementAdderOrDropletWdgt, createNewPanelWdgt, createNewPenWdgt, createNewRectangleWdgt, createNewScrollPanelWdgt, createNewSliderWdgt, createNewSpeechBubbleWdgt, createNewStackElementsSizeAdjustingWdgt, createNewString, createNewText, createNewToolTipWdgt, setupTestScreen1, underTheCarpet
- **WorldWdgt** (4): createDemoAnalogClock, popUpSystemTestsMenu*, stretchWorldToFillEntirePage, toggleDevMode

## By-catch findings (recorded here; neither is fixed in Phase 0)

**1. `coffee-method-header.js` has a third blind spot: a space before the colon.** 13 live methods
are spelled `name : ->` (12 `DemoMenus.create*IconWdgt` + `WorldWdgt.runOtherTasksStepFunction`),
which neither `METHOD_HEADER` nor the `unseenMethodHeaders` regression guard matches (the guard's
own precondition `/^  [A-Za-z_]\w*: \S/` requires the colon flush against the name). Every gate
consuming the shared lib — the dead-methods census included — has NO RECORD these 13 methods
exist. Same bug class as the two spellings the lib's own header documents (space-required-before-
arrow, wrapped signature); the fix wants the lib + guard extended and the gates' counts
re-baselined.

**2. LIVE BUG — the colour prompt on a `WidgetHolderWithCaptionWdgt` sets the icon's colour to
the WIDGET ITSELF.** `WidgetHolderWithCaptionWdgt.setColor: (theColor, ignored) -> @icon.setColor
theColor` assumes the wire shape (value in slot 1) — but the prompt fill puts the RECEIVER in
slot 1 and the ColorPickerWdgt in slot 2, and the override explicitly ignores slot 2. Confirmed
in ISOLATION on a fresh world (`.scratch/holder-setcolor-isolation-probe.js`): after Ok,
`icon.color === the holder widget` — the picked colour never arrives, and the corrupted colour
paints silently wrong per the invalid-canvas-value rule. Reached in practice via
`IconicDesktopSystemScriptShortcutWdgt > color... > Ok`. This is the seventh live bug of the
family the plan targets, and the exact "wrong-but-non-throwing subject" shape §5 risk 2 predicts
the gates cannot see.

## Go/no-go reading (§3's branches)

- Branch 1 ("slot-2-as-subject and slot-2-as-environment readers BOTH numerous → per-verb
  migration") — **does not apply**: 7 vs 7, both small, and perfectly partitioned by family with
  zero shared verbs. No verb ever needs to disambiguate the two menu/prompt meanings at runtime.
- Branch 3 ("bucket (a) dominates → O4 may beat any grand unification") — **applies**: 83% of
  verbs take nothing; only 35 declare anything.
- The unanticipated stronger fact: the two fill configurations ARE the two delivery families,
  statically and at runtime, with per-family slot meanings already stable and already
  consistently named at every reachable reader. The conditionality is a hidden family tag, not
  per-verb chaos.

**Verdict: GO, and cheaper than any pre-census estimate.** Stabilising the protocol requires
migrating approximately ZERO menu verbs and ZERO prompt verbs — their meanings are already fixed
in practice. What must change is the DISPATCH side: make the family split explicit (§4 O4 — e.g.
the prompt classes fill their own Ok rows, since they are already the only `environment` writers)
so the `MenuRowsPanelWdgt` crossover and the `if !@environment?` fork die, then give each
family's slots their honest fixed names (O1 within each family). The census table above is the
Phase 2 per-verb checklist; the wire family stays its own honest `(value)` convention, bridged
where it overlaps (the 7 SHAPE setters) exactly as today — with finding 2 fixed to the SHAPE it
should have had.
