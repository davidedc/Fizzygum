# Frame lifetime and docking — one chrome container, three manifestations

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-23 against Fizzygum `8d9ff3e3` / Fizzygum-tests `466109712` (gauntlet 18/18
green, 309 SystemTests). Every `file:line` was verified on that date — **line numbers DRIFT; the
method name / quoted code is authoritative, so `grep` before trusting a number.** Plan 1 of the
program [`frames-input-touch-program.md`](frames-input-touch-program.md): the decisions this
plan implements are **owner rulings recorded there (IDs C1–C16, G2, G3)** — cite them, do not
re-argue them.

**STATUS BOX** (fill per phase as executed)
- P0 re-verification + spikes: **DONE 2026-08-23** (coordinator + 4 Sonnet counts + 1 Opus spike worker;
  baseline = the 18/18 gauntlet of 2026-08-22 18:45 on the same code tree — docs-only commits since;
  probes in `Fizzygum-tests/.scratch/{h1-menu-dragged-to-desktop,s1-rowsviewport-as-frame-content,
  s1b-rowsviewport-with-p3-measure,s1c-absorb-residue,s2-toolbar-detach}-probe.js`; nothing committed).
  - **Facts:** 11/14 HOLD verbatim. F8 count 48 → ~46 (method-dependent; amended). F10 script list
    amended (`smoke-boot-headless.js` does not name `FrameWdgt`). **F13 FALSIFIED**: `setTouchInputMode`
    has a live caller — the world menu's "touch screen settings" row (`WorldWdgt.coffee:3205`) → program G1's
    premise corrected, ruling unchanged, deletion filed as tail **T11** (Plan 3).
  - **H1 (C8's premise), run:** a menu dragged by its header and dropped on the WORLD **evaporates** on
    the next click (`isPopUpPinned()` false after the drop; `findRootForGrab` from the header = the menu).
    C8 stands; the P4 test `macroGrabbedMenuStaysOnDesktop` is genuinely new.
  - **S1: PASS-WITH-RESIDUE → P3 is GO** with two §2.4 amendments landed: (1) the membership absorb
    (`_reLayOutAfterContainedPanelChange`) STAYS on the viewport and needs `firstParentThatIsAPopUp` to stop
    at the frame — with both, grow/shrink converge in ONE cycle, 0 re-visits; (2) the measure caps at
    world − chrome, not world (else the frame overflows by its chrome and the guard fires). (i) hug both
    axes PASS. Also measured: the viewport needs the spec + measure to hug at all (a bare one sits at 50×40).
  - **S2: PASS → P5 is GO.** One `wantsDetachOfChild` declaration lifts the docked toolbar out (today the
    drag moves the window); no build gate objects. Carry: the host must clear its slot on detach (§2.5).
  - **Recapture budgets (program §4 rule 2):**
    **P2 / 4a = 8** — `macroClosingInnerWindowKeepsOuter` ⚠macro clicks the vanishing button (rework),
    `macroInternalWindowDroppedIntoWindowFits`, `macroResizeWindowContainingInternalWindow`,
    `macroWindowsNestedCollapsingUncollapsing`, `macroWindowWithAClockInAWindowConstructionTwo`,
    `macroMenuInWindowInScrollStackStaysLive` (images 2–4), `macroWindowCellsInConstrainedScrollStackReflow`
    ⚠macro clicks both cells' close buttons (rework), `macroSimpleDocumentHandlesOldInspector` (image_2).
    NOT in the set (C6 by the spec, not by nesting): a window dropped into a bare `PanelWdgt` gets NO
    layout spec → stays free-floating → keeps close (`macroInternalVsExternalWindowDrop`,
    `macroScrollPanelUpdatesCorrectlyOnCollapsingAndUncollapsingAndClosingWindow`, the DragEmbed family).
    **P3 / 4b = 3** (plan guessed ~5) — `macroInspectorWorkAreaEvaluatesCoffeeScript`,
    `macroMixinEditDonorAndOverride`, `macroMixinFieldEditDonorAndOverride` (the only `inform`s any test
    screenshots; `prompt()` and "no widgets to attach to" use `popUpAtHand` — unaffected).
    **P5 / 4c = 7** (seed 24 files/16 tests, not ~29 — "Patch" over-matched) — `macroDocsToolbarDockSidesAndFloat`
    (also the only float/re-dock test), `macroDocsToolbarSlotEditViewToggle`, `macroDrawingsMakerReEnableEditing`,
    `macroEditModeTogglePencilEyeGlyph`, `macroSelectionOverlaySurvivesBringToFront`,
    `macroSaveAsPromptAboveTiltedWindow` (image_1), `macroSampleSlideEditViewToggle` (image_1). Makers open
    in EDIT mode with the toolbar docked (the three `Sample*App` doors open in VIEW mode). ⚠ Dashboards and
    Patch Makers have ZERO docked-toolbar-in-edit-mode coverage — P5's grip has no witness there.
    **P4 / 4d (grab pins — a set the plan did not list):** a pinned pop-up on the world takes the (3,3)/0.3
    shadow (`PopUpWdgt.addShadow`), so every test that header-drags a transient pop-up onto the desktop and
    screenshots after the drop changes — measured list: see the next line.
  - **P4 / 4d = 3** (14 candidates read; 24 more menu/prompt tests swept, no drag-by-header) —
    `macroMenuShadowCorrectWhileAndAfterDrag` (image_3), `macroPromptShadowFollowsOnDrag` (images 2–4),
    `macroMenusAndSubMenusRemainOpenWhileDraggingMenusOnly` (images 1–4: ⚠ a PRESENCE change, not a shadow
    change — `pinPopUp` leaves `world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren`, so the two dragged menus
    SURVIVE the dismissal click that today wipes the cascade; that is C8's intent, so its assertions/description
    are rewritten, not just recaptured). Since P4 runs after P2/P3, a grab-pinned pop-up on the world shows the
    WINDOW manifestation (C4), so these three change more than their shadow. Excluded: the three drop-into-
    container tests (pin at grab vs at drop is pixel-identical there), header-CLICK pins, duplicate pins.
- P1 `lifetime`: **DONE 2026-08-23** (Opus worker; `fg build` OK, `fg presuite` byte-identical — 309/0 failed,
  paint 0 offenders — both serialization rigs green: 53 native + 69 SWCanvas + 7 file checks; zero recaptures).
  `lifetime` literal branch sites: 4 (§3 threshold ~8). Findings: (1) F10's script list was incomplete —
  `serialization-roundtrip-headless.js:1265` WROTE the kill flags to fake a pinned menu (now
  `_setLifetimeNoSettle 'persistent'`); (2) `fullCopy` sets the field directly — routing it through the
  entry would strip the orphan copy's shadow (a pixel change); (3) `constructor-and-parameter-conventions.md`
  used `opts.killOutside` as its worked example (swapped for `closesUnpinnedPopUps`); (4) ⚠ **the pop-up's own
  "pin" context-menu row has been DEAD since 2018-02-09** (`db62bddf` renamed `pin` → `pinPopUp`, the action
  string stayed `"pin"` → `TypeError` on click): a THIRD `check-menu-actions` blind spot (a string action the
  target does not define) that `menusweep` cannot see either — it sweeps no pop-up root. Fixed as P1's
  follow-on commit (action → `"pinPopUp"`, `MenuWdgt`/`PromptWdgt` roots in `menu-click-sweep-headless.js`
  proven by plant — and the rig now RESOLVES every row's action before its liveness skip, so the 55+ rows
  a green sweep skips as stale are resolution-checked too); the static rule is tail T12. The two new
  roots then exposed **T13**, a real crash (deleting a pop-up "attach…"ed into its own shortcut icon
  recursed forever) — fixed in the same commit (closed in the ledger). Residual prose:
  `SystemTest_macroMenuPinnedByHeaderClick`'s `intent` still names the kill flags (P6 sweep, with its
  `visualisation.html`).
- P2 constants sub-step (G2): **DONE 2026-08-23** (Sonnet; `fg build` OK, `fg census` 0 movers, `fg presuite`
  byte-identical 310/0). Preferences landed in `setMouseInputMode` only: `barIconSize 16`, `barPadding 5`,
  `barGlyphSize 16`, `menuHeaderCornerRadius 3` (⚠ F13 mislabelled `MenuHeader`'s `super 3` a padding — it is
  `BoxWdgt`'s corner radius; named for what it IS), `menuRowsBorder 2`, `toolThumbnailSize 30`,
  `toolInternalPadding 5`, `toolExternalPadding 10`, `toolRows 2`, and **`toolbarDockThickness 95` as a
  RESIDUE**: no formula over the grid metrics reproduces 95 (the plan's sketch gives 90; the honest grid
  formula 2·30 + 1·5 + 2·10 gives 85; the 95 is byte-parity with a `StretchableEditableWdgt` arm that no
  longer exists — `docs/archive/onion-widget-composition-plan.md:708`). `FrameWdgt.CLOSE_ICON_SIZE` static
  deleted (3 readers → the preference). `ToolbarWdgt.dockThickness` is ctor-initialised from the preference
  unless a variant declares its own (`TextToolbarWdgt` 40, `PaintToolbarWdgt` 103). → P5 decides the dock
  thickness when the docked frame declares it (C12/C13); `barGlyphSize`/`toolRows` have no consumer until
  the bar spec / P5.
- P2 bar + C6: **DONE 2026-08-23** (Opus; `fg build` OK, `fg recapture` of the 4a set COMPLETE at dpr 1+2,
  `fg presuite` 310/0, `fg menusweep` OK, `fg census` 0 movers). `FrameWdgt._barSpec()` (11 fields: pieces,
  resizer, axis, showsText, naturalWidth, thickness, slotSize, glyphSize, padding, textHeight, fontSize) feeds
  the bar's build AND arrange; roster re-derived at every (re)parenting and `_setLayoutSpec`
  (`_reDeriveBarRosterNoSettle`); the transient row is defined, not wired (P3). Recaptured EXACTLY the 8
  tests of 4a (consequence pixels eyeballed by the coordinator: inner bar loses ⊗, collapse+title slide one
  slot; `macroSimpleDocumentHandlesOldInspector` img3's re-ejected window sits 11 px right because the drag
  grabs the label whose centre moved). ⚠ **Ruling C6 AMENDED** (owner, ruling B): the `!@isFrame?()`
  conjunct in `Widget._closeNoSettle`/`_moveToTrashNoSettle`/`_wouldTrashSeverAnything` STAYS — it is close
  SEMANTICS (a nested frame closes alone), not the button; deleting it sent the whole assembly to the bin
  and falsified "right-click → close is the universal fallback". The two 4a macros that clicked the vanished
  button now close through the hierarchy menu. Residue for P4/P6: `FrameBarWdgt._destroyEditButtonNoSettle`
  uses `_destroyNoSettle` on an icon button owning a `face` widget — the shape that leaked (88
  `WORLD_INVENTORY` tokens) when the close piece was retired the same way; `closeFromFrameBar` needed a
  `public-api-allowlist.txt` entry ([U] sees it as self-only once no prose names it).
- P3 citizens: not started (S1 GO).
- P4 skin/shadow/grab: not started (budget = the 4d set + the new test + the one changed macro). · P5 docking: not started (S2 GO; C17 ruling still needed). · P6 Liskov walk + docs: not started.
- Tail (program §5): not started.

**MANDATE: complete elimination of the underlying problem, not mitigation.** The problem is that
one role — the manipulation chrome around a payload — is expressed as two parallel class
hierarchies (`FrameWdgt` vs `PopUpWdgt`→`MenuWdgt`/`PromptWdgt`) plus a third thing
(`ToolbarWdgt`) that gets a container bolted on and off around it by conversion. Every axis on
which the families differ is runtime STATE, CONTEXT, or DERIVED — none is intrinsic to a type
(§3). The plan removes the second hierarchy (not wraps it), replaces the two boolean flags with
the one state they encode (not documents them), derives the bar roster/skin/shadow from state +
context (not adds a fourth case), and makes docking a placement (not a rebuild). Owner has
waived churn, screenshot recaptures, legacy support and serialized-world compatibility —
decisions are made on architecture alone; NO phase may keep a wart for compatibility's sake.

---

## §0 Orientation

**The project.** Fizzygum is a CoffeeScript GUI framework ("web operating system") rendered on
one HTML5 canvas, descended from Morphic.js. Three sibling repos under `Fizzygum-all/`:
`Fizzygum/` (source — the only repo this plan edits besides tests), `Fizzygum-tests/` (the
SystemTest suite, served through the `latest/js/tests` symlink — test edits need NO rebuild),
`Fizzygum-builds/` (generated, never edited). Every build/test command goes through the wrapper
`/Users/davidedellacasa/code/Fizzygum-all/fg` (ABSOLUTE path, never `./fg`); bare `fg` prints the
current subcommand roster. Read the root `CLAUDE.md` and `Fizzygum/CLAUDE.md` before touching
anything. No module system: every class is a global; one class per file, filename = class name.

**The vocabulary, stated up front** (it is the trap of this area):
- `FrameWdgt` = **the WINDOW class** (title bar, close, collapse, resizer, one payload called
  `@contents`). Its subclasses are the *framed citizens* (`DocumentWdgt`, `SpreadsheetWdgt`,
  `GenericPanelWdgt` and its slide/dashboard/patch/image family, `FolderWindowWdgt`,
  `TemplatesWindowWdgt`) — "a document IS its window" (Frame-model §5.B).
- `PopUpWdgt` = the transient-container base of `MenuWdgt` (menus) and `PromptWdgt` (the
  text/number/colour/save prompts). It draws only a shadow; its body is a `MenuRowsPanelWdgt`
  inside a `PopUpRowsViewportWdgt`.
- `ToolbarWdgt` = a `ViewportWdgt` over a `ToolPanelWdgt` grid of template thumbnails. It is a
  PAYLOAD: docked it sits in a `FrameWdgt`'s *toolbar slot*; floating it is a `FrameWdgt`'s content.
- `PanelWdgt` / `ViewportWdgt` = the plain clipping container / the scrolling viewport — the
  subject of the IMMEDIATELY PRIOR arc (below), not of this one.
- "Frame" in prose below ALWAYS means `FrameWdgt`; "pop-up" means a transient frame, never a class.

**The immediately prior arc and why this plan exists now.** On 2026-08-19/20 the owner asked the
same question of `PanelWdgt` vs `ScrollPanelWdgt` that this plan answers for windows/menus/
toolbars. The result (archived: `docs/archive/scroll-frame-role-architecture-plan.md`,
`menu-sandwich-dissolution-plan.md`; living truth `docs/architecture/viewports-and-planes.md`):
`ViewportWdgt` with a runtime `scrollPolicy: 'auto' | 'never'` — **policy over structure; the
name encodes the ROLE, not the manifestation**. A week later the owner raised windows vs menus
vs toolbars ("the three should be reorganised similarly"), and the design session of 2026-08-23
established (§3) that the same verdict applies, with one correction: the toolbar is not a
container peer.

**Critical reframes — do not lose these:**
1. **The precedent the owner wants already exists — twice, separately.** A window already
   changes manifestation at runtime with no tree change (window ↔ card, derived from parentage:
   `FrameWdgt.isInternal` / `_deriveAndSetBodyAppearance`). A pop-up already changes lifetime at
   runtime (pin) and manifestation by parentage (shadow off when pinned into a non-world
   parent: `PopUpWdgt._updatePopUpShadow`). Each family invented "derive from context" on its own;
   neither shares it. That is the smell — not the mechanism.
2. **The pop-up's two flags encode ONE bit.** `killThisPopUpIfClickOutsideDescendants` ×
   `killThisPopUpIfClickOnDescendantsTriggers` is a 4-state space; `isPopUpPinned` is "both
   false"; **no call site anywhere sets the two independently** (verified: `grep -rn
   "killOutside\|killOnTriggers" src` outside the two base classes → one comment in `ListWdgt`).
3. **`ToolbarWdgt` is a payload.** "Toolbar ⇄ menu" is a payload-arrangement question (column of
   labels vs grid of icons) and is OUT of this plan (ruling C16 → tail T1). What this plan gives
   the toolbar is the `QDockWidget` treatment: the *same* object docks and floats; the chrome
   flips with its parent.
4. **Docked is not a fourth skin.** A docked frame is a CARD (persistent, nested) under a
   host-owned edge spec. Its "grip" is the ordinary bar with a derived roster minus close/resizer
   (C6) and an orientation derived from the spec (C13). No grip class, no grip skin.

---

## §0.5 Cold-execution protocol

**Who executes (owner ruling, program §3.1):** this plan is run by a **COORDINATOR** (the expensive
session model) that **delegates every phase to a WORKER on a cheaper model** — Opus for phase
execution, Sonnet for the mechanical sub-steps — through the `Agent` tool (`subagent_type:
general-purpose`, `model: "opus"` / `"sonnet"`; never `fork`, never `isolation: worktree`). §9 is
the delegation map: per phase, the worker model, what the brief contains, the stop rules, the
report, and what the coordinator checks. The steps below are written for the WORKER (it is the one
reading files and running gates); the coordinator runs step 1, briefs per §9, reads reports, and
decides at every gate. **The coordinator does not edit source or run suites itself.**

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — orient (heads, build freshness, test
   count, zombie browsers → `fg killz`). Expect heads at or after the ones in the header.
2. Read this plan in full, then the program doc's §2 ledger. Then read, in this order (all under
   `Fizzygum/`): `src/PopUpWdgt.coffee` (337 lines — the whole thing), `src/basic-widgets/menu-system/
   MenuWdgt.coffee` (141), `src/PromptWdgt.coffee` (~200), `src/basic-widgets/menu-system/MenuHeader.coffee`
   (~62), `src/FrameBarWdgt.coffee` (245), `src/FrameWdgt.coffee` (1195 — read ALL of it; its
   width/height negotiation, ~lines 150–260 and 1030–1195, is where P3's risk lives),
   `src/app-kit/ToolbarWdgt.coffee` (78), `src/app-kit/ToolPanelWdgt.coffee` (head), `src/basic-widgets/
   menu-system/PopUpRowsViewportWdgt.coffee`, `MenuRowsPanelWdgt.coffee`; then `docs/architecture/
   regularity-principles.md` (the frame model), `layering-naming-convention.md`, `layout.md` (settle
   tiers, the notification grid), `lint-and-static-checks.md` (the 28 build gates — several phases
   WILL trip them if ignored; §8 lists which), `docs/specs/drag-embed-interaction-spec.md` (§4
   payload classes, §6 dwell), and `Fizzygum-tests/CLAUDE.md` + `src/macros/MACRO-PATTERNS.md`
   (how a macro test is written and captured).
3. Execute phases IN ORDER, P0 → P6. Each phase ends with its own gate (§8) and a proposed
   commit. **Owner preference: ask before every commit/push — present a summary and the proposed
   message (`git commit -F <file>`, never backticks in a `-m`), then wait.** Do not start a later
   phase in the same session as an earlier phase's un-gated changes.
4. Long ops (`fg gauntlet`, `fg presuite`): launch ONCE with the Bash tool's `run_in_background`
   redirected to a log; peek `cat /tmp/fg-<cmd>.verdict` at a ~5-min cadence; never pipe the gating
   call through `| tail`/`| grep`; never edit `fg`, src or tests while a run is in flight.
5. If a fix shape is falsified twice, STOP and re-frame — never a third variant (owner rule).
6. Comments you write must state what IS, never history ("used to", "was", "replaced") — the
   comment-smell ratchet (`check-stinks.js`) fails the build on narration. Present tense only.
7. `undefined` is the one absence value; `null` only where a foreign API demands it; `nil` is
   retired and gated.
8. When this plan defers anything, it goes into the program doc's tail ledger with a destination
   (program §5) — never a "for later" in this file.

---

## §1 The system as it stands (verified 2026-08-23)

### 1.1 The three families

| | `FrameWdgt` (1195 lines) | `PopUpWdgt` (337) + `MenuWdgt` (141) / `PromptWdgt` (~200) | `ToolbarWdgt` (78) + 7 subclasses |
|---|---|---|---|
| Is a | container: ONE payload `@contents` + chrome | container: ONE payload (`@rowsViewport` over `@rowsPanel`) + shadow only | **payload** (`extends ViewportWdgt` over `ToolPanelWdgt`) |
| Chrome | `@bar` (`FrameBarWdgt`: `titlebarBackground`, `label`, `closeButton`, `collapseUncollapseSwitchButton`, `editButton`), `@resizer` (`HandleWdgt`, corner-internal), `@toolbar` slot, `@defaultContents` placeholder | `MenuHeader` = child 0 of the rows panel (title text; click = pin; the drag handle) | none docked; floating = somebody else's `FrameWdgt` |
| Lifetime | always persistent | the two kill flags; `isPopUpPinned` = both false; flips mid-life | n/a |
| Skin by context | window vs card, from parentage (`isInternal` `:343`, `_deriveAndSetBodyAppearance` `:894`, `FrameBarWdgt._setAppearanceAndColorOfTitleBackground` `:152`) | 3 shadows from pin × parentage (`_updatePopUpShadow` `:257`, `addShadow` `:270`) | — |
| Close | → bin (`Widget._closeNoSettle`) | transient → `_fullDestroyNoSettle`; pinned → bin (`PopUpWdgt._closeNoSettle` `:330`) | — |
| Registries | none | `world.openPopUps` / `freshlyCreatedPopUps` / `popUpsMarkedForClosure` / `wdgtsDetectingClickOutsideMeOrAnyOfMeChildren` | — |
| Sizing | ~400 lines of width/height negotiation against the payload's `FrameContentLayoutSpec` | hug the rows, capped to the world (`_refitRowsViewportNoSettle` `:84`, `_assertFitsInTheWorld` `:135`) | constant `dockThickness: 95` (`ToolbarWdgt.coffee:30`) |
| Hit test | claims its shaped box (BoxyAppearance / RectangularAppearance) | `catchesPointerAt: false` on `MenuWdgt` `:56`, `PromptWdgt`, `PopUpRowsViewportWdgt` (the rows PANEL holds `MenuAppearance` and is the hit target) | — |

### 1.2 Facts that shape the plan (each verified; re-verify in P0)

- **F1** The two kill flags are never set independently (§0 reframe 2). `killThis*` has 13 text refs;
  `isPopUpPinned` 7; `pinPopUp` callers: `MenuHeader.mouseClickLeft` (`:58`), the "pin" menu row
  (`PopUpWdgt.addWidgetSpecificMenuEntries` `:241`), `PopUpWdgt._reactToBeingDropped` (`:246`, non-world
  drop only), and `fullCopy` (`:233`, a duplicated pop-up is born pinned — test
  `SystemTest_macroDuplicatedMenuAutoPinsOnDesktop`).
- **F2** A menu already knows how to be window content: `MenuWdgt.initialiseDefaultFrameContentLayoutSpec`
  (`MenuWdgt.coffee:102`) declares `THIS_ONE_I_HAVE_NOW` ×2, `canSetHeightFreely = false` — the hug spec
  the frame's negotiation consumes. Test `SystemTest_macroMenuInWindowInScrollStackStaysLive` exercises a
  pinned menu as window content (today: double chrome — window bar + menu header).
- **F3** `FrameWdgt.floatToolbar` (`:797`) builds a NEW `FrameWdgt` around the docked strip; re-docking
  (`dockToolbarMenu` `:747`, `_dockToolbarAtNoSettle` `:777`) builds a FRESH variant ("toolbars are
  identity-free by design"). Conversion, not role change. Readers of `@toolbar` outside `FrameWdgt`: none.
  `_dockedToolbarShowing` has 10 refs, all in `FrameWdgt`. `buildToolbar` implementors: `ImageWdgt`,
  `SlideWdgt`, `PatchProgrammingWdgt`, `DashboardWdgt`, `DocumentWdgt` (all citizens, `src/authoring/`).
- **F4** `FrameWdgt.coffee:1` opens with a TODO by the owner: "windows should really be able to
  accommodate any extent always … stackable and dockable in any place". Same instinct; the plan
  resolves the TODO (delete it in P5 with a present-tense statement of what IS).
- **F5** Dead: `@tight = true` (`FrameWdgt.coffee:267`) — only `VerticalStackPanelWdgt` reads `@tight`.
  Stale: `PromptWdgt`'s comment claims "the three isMenu? sites … Wallpaper / StringWdgt tick refresh";
  `isMenu?()` has exactly ONE consumer, `ActivePointerWdgt.coffee:660`.
- **F6** The pop-up dismissal logic lives in the HAND: `ActivePointerWdgt.processMouseDown` (`:660`
  `if !(w.firstParentThatIsAPopUp()?.isMenu?()) → @cleanupMenuWdgts w, alsoKillFreshMenus: true`),
  `cleanupMenuWdgts` (`:860–901`: `closePopUpsMarkedForClosure`, `hierarchyOfClickedWdgts`,
  `hierarchyOfClickedMenus` via `hierarchyOfPopUps`, then the click-outside callbacks skipping
  `freshlyCreatedPopUps`), `processMouseUp` (`:699` clears `freshlyCreatedPopUps`), and `:600` (the
  caret-accept branch asks `world.mostRecentlyCreatedPopUp()`).
- **F7** `firstParentThatIsAPopUp` (14 refs): `Widget` climbs to the ROOT (`Widget.coffee:4113`);
  `PopUpWdgt` overrides to stop at itself unless marked for closure (`:193`). Consumers that turn on it:
  `MenuRowsPanelWdgt.wantsDetachOfChild` (`:89` — rows extractable iff the pop-up is pinned),
  `PopUpRowsViewportWdgt._reLayOutAfterContainedPanelChange` (`:52`), `MenuHeader.mouseClickLeft`,
  the hand (`:660`, `:879`).
- **F8** `popUp(pos, widgetToAttachTo)` (`PopUpWdgt.coffee:285`): ~46 `popUp*` call sites (44 by
  `grep -rnE "\.popUpAtHand\b|\.popUpCenteredAtHand\b|\.popUp\b" src`, excluding the `popUpsMarkedForClosure`
  names — the count depends on the method; P0 re-measured 2026-08-23); the only direct
  `.popUp` callers pass `world` (`ChangeFontButtonWdgt.coffee:31,44`); `popUpAtHand`/`popUpCenteredAtHand`
  attach to `world`. ⇒ C9 ("transient ⇒ world child") is already true.
- **F9** `popUpCenteredAtHand` centres `@extent()` BEFORE layout, and a menu's pre-layout extent is ZERO
  (`MenuWdgt.coffee:90` comment: "a zero pre-layout extent centres my TOP-LEFT at the hand, byte-identical
  to the old menu"). Callers: `Widget.inform` (`Widget.coffee:4326`), `BinWdgt.coffee:72`. Under a frame the
  extent is known at popUp ⇒ genuine centring ⇒ a DELIBERATE pixel change for the ~5 tests that `inform`.
- **F10** Tests-repo reach (counts of `tests/*/SystemTest_*.js`): `getMostRecentlyOpenedMenu` 74 (the
  toolkit reads `Array.from(world.freshlyCreatedPopUps).pop()`, `MacroToolkit.coffee:688`); `.label` 24
  (`menu.label` / `win.label` — both aliases of the bar's title piece); `closeButton` 7; `editButton` 4;
  `"pin"`/`pinPopUp` 8; `titlebarBackground` 1; `collapseUncollapseSwitchButton` 1; toolbar dock/float 2
  (`SystemTest_macroDocsToolbarDockSidesAndFloat`, `SystemTest_macroDocsToolbarSlotEditViewToggle`).
  Scripts: `serialization-roundtrip-headless.js` reads `world.openPopUps` / `freshlyCreatedPopUps` /
  `popUpsMarkedForClosure` by name (`:133`, `:1336`, `:1370`) and `isTransientPopUp` (`:1251`);
  `revisit-gate.js` (`:78`), `staleness-census.js` (`:30`, `:105`) and `audit-preludes/revisit-trace-prelude.js`
  name `FrameWdgt` (the class survives — no impact; `smoke-boot-headless.js` does NOT — its one hit is the
  substring in `TransformFrameWdgt`). **⚠ A cross-repo rename MUST grep `Fizzygum-tests/scripts/`.**
- **F11** Serialization: `Serializer.coffee:126` drops `child.isTransientPopUp?()` from a world snapshot;
  `:347` writes an `"openPopUp"` marker for `world.openPopUps` members, `Deserializer.coffee:124` restores
  it; `PopUpWdgt.@serializationTransients = ["isPopUpMarkedForClosure"]`.
- **F12** The grab climb: `Widget.grabsToParentWhenDragged` (`Widget.coffee:3975–3996`) — a child of a
  non-panel parent stays solid with it UNLESS the parent answers `wantsDetachOfChild(child)` (implementors:
  `MenuRowsPanelWdgt`, `CellWdgt`). `FrameBarWdgt` must stay a plain Widget (grabs to parent) so a title
  drag grabs the FRAME (`FrameBarWdgt.coffee` header comment). `HandleWdgt.updateVisibility` (`:112`)
  shows/hides the resizer on `@parent.isFreeFloating()`; `isFreeFloating` = no spec or a follower spec
  (`StretchLayoutSpec.ownsPlacement → false`, `LayoutSpec.ownsPlacement → true`).
- **F13** Chrome literals (ruling G2): `FrameWdgt.@CLOSE_ICON_SIZE: 16` (`:88`, 4 refs), `@padding = 5`
  (`:284` — ONE number serving both the bar height `16 + 2·5 = 26` and the body padding), `MenuHeader`
  `super 3` (`:6`), `MenuRowsPanelWdgt` `super padding: 2` (`:97`), `ToolPanelWdgt` `internalPadding 5 /
  externalPadding 10 / thumbnailSize 30` (`:3–5`), `ToolbarWdgt.dockThickness: 95` (`:30`). Preferences
  already hold `titleBarTextFontSize 12`, `titleBarTextHeight 15`, `handleSize 15`, `scrollBarsThickness 10`,
  `menuFontSize 12`, `menuHeaderFontSize 12` (`PreferencesAndSettings.coffee:150–200`). `setTouchInputMode`
  (`:208`) has ONE live caller: `toggleInputMode` (`:108`), wired as the world menu's "touch screen settings"
  row (`WorldWdgt.coffee:3205`, a reflecting toggle row — not dev-gated). ⚠ P0 (2026-08-23) falsified the
  "zero callers" claim this plan and ruling G1 carried; the per-device redraw mechanism is LIVE today and
  G1 schedules its deletion (program tail T11). Nothing in Plan 1 reads `inputMode`.
- **F14** Frame chrome accounting that P5 generalises: `_titlebarHeight` (`:92`), `_chromeHeight` (`:103`),
  `_chromeWidth` (`:154`), `_topDockThickness`/`_left…`/`_right…`/`_bottom…` (each tests
  `@toolbar.dockSide == side`), the slot placement in `_positionAndResizeChildren` (`:1030`, the
  `switch @toolbar.dockSide` tail), collapse/uncollapse of the slot with the content's mode
  (`showEditModeInBar`/`showViewModeInBar`, `_beforeChildCollapsed`).

### 1.3 Why it is shaped this way

The two hierarchies are inherited: Smalltalk-80 had pop-up menus and system windows as unrelated
things (menus were transient by construction), Squeak Morphic kept `MenuMorph` (with `stayUp:` —
the ancestor of Fizzygum's pin) apart from `SystemWindow`, and morphic.js had only `MenuMorph`.
Fizzygum's `FrameWdgt` grew separately and the 2026-07 Frame-model arc (`docs/archive/
onion-widget-composition-plan.md`) made it the ONE manipulation chrome for payloads — but left
`PopUpWdgt` untouched and added the toolbar as a *slot* in the frame (§5.C, ruling D9), which is
why floating a toolbar is a rebuild. The menu side was cleaned in 2026-07/08 (rows panel as a
stack client, rows viewport always present, the sandwich dissolved) — all of it inside the
pop-up family. Nobody asked whether the family should exist.

---

## §2 The mechanism this plan installs (target design)

Everything below is the rulings applied; each bullet names its ruling.

### 2.1 One state — `lifetime` (C2, C3, C8, C9)

- `FrameWdgt::lifetime: 'persistent'` (class default; windows are born persistent).
  `MenuWdgt`/`PromptWdgt` ctors set `'transient'`.
- `setLifetime(v)` — public, self-settling (the roster/skin/shadow change re-lays the bar);
  `_setLifetimeNoSettle(v)` — the core. Entering `'transient'`: join `world.openPopUps`
  (+ `freshlyCreatedPopUps` at construction, as today), register click-outside ("close"). Entering
  `'persistent'`: `onClickOutsideMeOrAnyOfMyChildren undefined`, the closure propagation that
  `pinPopUp` does today (mark + close the opener chain's unpinned pop-ups), shadow re-derive
  (§2.3), bar re-derive (§2.2), `_invalidateRowsAfterPinChange` (rows re-read the grip fact).
- `pinPopUp(pinMenuItem)` keeps its name and its two branches (menu-row path with settle,
  no-arg drop path NoSettle — see the sanctioned comment at `:249`) and is implemented over
  `_setLifetimeNoSettle 'persistent'`. The "pin" menu row is offered iff transient.
- **Grab pins (C8):** `FrameWdgt._reactToBeingGrabbed` (`:853`, exists — relays to contents) gains
  `@_setLifetimeNoSettle 'persistent' if @lifetime is 'transient'` (a notification callback: NoSettle
  tier only — layering rule [J]). `_reactToBeingDropped` keeps only the shadow re-derive.
- `isPopUpPinned()` → `@lifetime is 'persistent'`; `isTransientPopUp()` → `@lifetime is 'transient'`
  (the serializer's query, F11 — keep the name in P1; P6 may rename with a tests-script sweep).
- `fullCopy` (`:233`) → the copy is persistent (unchanged semantics).
- Close: `FrameWdgt._closeNoSettle` (new override) — transient → `_fullDestroyNoSettle`, persistent →
  `super` (bin); leave `world.openPopUps` in both (the body of today's `PopUpWdgt._closeNoSettle`).
  `_destroyNoSettle` leaves the set (today `:317`).
- The opener link `widgetOpeningThePopUp` (105 refs) keeps its name and its field on `FrameWdgt`
  (undefined for windows); `getParentPopUp` / `hierarchyOfPopUps` / `propagateKillPopUps` /
  `_markPopUpForClosure` / `isPopUpMarkedForClosure` (+ its `serializationTransients` entry) move
  verbatim onto `FrameWdgt`. `getParentPopUp` already answers `@parent` when persistent.
- `firstParentThatIsAPopUp`: `FrameWdgt` takes `PopUpWdgt`'s override (stop at me unless marked).
  A persistent window now answers for its subtree — which is CORRECT for every consumer (F7):
  `wantsDetachOfChild` asks `isPopUpPinned?()` → persistent → rows extractable; the hand asks
  `isMenu?()` → a plain window answers undefined → cleanup runs, as today when the climb reached
  the world. Rename is tail T8.
- **The cap (C10):** `_assertFitsInTheWorld` and the world-cap in the rows viewport's measure hold
  regardless of lifetime.

### 2.2 One bar with a derived roster (C5, C6, C13, C15, G2, G3)

`FrameBarWdgt` absorbs `MenuHeader`. The bar is laid out from a **bar spec** the frame derives:

| input | transient | persistent, free-floating | persistent, host-owned (card / stack / docked) |
|---|---|---|---|
| roster | title (tap = pin) | close · collapse · title · pencil (iff payload `providesAmenitiesForEditing`) | collapse · title · pencil (iff …) — **no close** |
| resizer (`HandleWdgt`) | none (rows hug) | iff payload sizes freely (`contentsRecursivelyCanSetHeightFreely` family) | none (`isFreeFloating()` false — the handle already hides itself) |
| metrics (desk profile) | today's `MenuHeader` numbers (text + 2, header colour, corner 3) | today's external bar numbers (`barIconSize + 2·barPadding` = 26, external colours) | today's internal bar numbers (flat skin, internal colours) |
| natural width | title text + 2 (participates in the hug — a menu widens for its title, as today) | 0 (label is FIT_TEXT_TO_BOX) | 0 |
| axis | horizontal | horizontal (C15) | expanded dock: ACROSS the strip at the leading end; collapsed: ALONG the kept axis; otherwise horizontal (C13) |
| text | yes | yes | only when the bar is horizontal |

- The `win.label` / `menu.label` / `win.closeButton` / `editButton` / `collapseUncollapseSwitchButton` /
  `titlebarBackground` aliases stay (F10: 24 + 7 + 4 + 1 + 1 tests). A menu's `label` IS the bar's
  title piece (today it is the `MenuHeader`; `menu.label.center()` must keep tracking live).
- Hit-testing: the bar stays a plain, appearance-less Widget (F12) with `catchesPointerAt: false` (the
  pieces are shaped where drawn); the FRAME's appearance shapes the box (§2.3), so the rounded-corner
  fall-through that `MenuWdgt`/`PromptWdgt`/`PopUpRowsViewportWdgt` declare today comes from the shape
  and those three `catchesPointerAt: false` overrides are DELETED.
- Pieces lay out as BOXES of `barTargetSize`; glyphs paint at `barGlyphSize` inset (G3). Both 16 on the
  desk profile, so pixels do not move.
- **Every metric is a preference read through ONE `_barSpec()` derivation** — no literal in the arrange.

### 2.3 Skin and shadow derived (C4)

- `_deriveAndSetBodyAppearance` (`:894`) becomes `f(lifetime, parentage)`: transient → the menu box
  (today's `MenuAppearance`, moved to paint the FRAME: grey fill, menu stroke, corner radius
  `title? 5 : 0` honouring `isFlat`); persistent on world → `BoxyAppearance`; persistent nested →
  `RectangularAppearance`. The rows panel becomes the untitled plain square stack `ListWdgt` already
  builds (no `MenuAppearance`, no `cornerRadius`, no header child).
- Shadow: today's `_updatePopUpShadow` + `addShadow` override (`:257–276`) move onto `FrameWdgt`,
  keyed on `lifetime` × `@parent == world` × dragging. Windows keep their drag-time shadow.
- `colloquialName`: transient → `"menu"` / `"\"title\" menu"` / `"prompt"` (the citizens' own, as
  today); persistent → `"window"` / `"internal window"` (the frame's). Titles via `_titleForContents`
  (citizens override — `MenuWdgt` titles from `@title`).
- Re-derived at every (re)parenting (`_reactToBeingAdded` `:867`, skipping the hand) AND at every
  `setLifetime`.

### 2.4 The rows payload as frame content (C14, C10)

- `MenuWdgt` / `PromptWdgt` `extends FrameWdgt`; their ctors build `@rowsPanel` (untitled) inside a
  `PopUpRowsViewportWdgt` and pass it as `contents`; `lifetime = 'transient'`; the row API stays
  delegated to the panel (`addMenuItem` … unchanged for the 315 sites).
- `PopUpRowsViewportWdgt.initialiseDefaultFrameContentLayoutSpec` declares THIS_ONE_I_HAVE_NOW ×2,
  `canSetHeightFreely = false` (moved from `MenuWdgt.coffee:102`), and its pure measure
  (`preferredExtentForWidth`) answers `min(panel hug, world − the frame's own chrome)` on both axes —
  the cap (today's `_refitRowsViewportNoSettle` arithmetic). ⚠ S1(iii) measured: capping at the bare
  world extent makes the FRAME (viewport + chrome) overflow the world and `_assertFitsInTheWorld` fires
  (`78x476 in a 960x440 world`); capping at world − chrome (the frame is 10 wide / 36 high on the desk
  profile) keeps the frame at exactly the world height with the scrollbar showing and the guard silent.
  The frame's first-placement branch then hugs it (S1(i) PASS: panel 42×79 → frame 52×115 = viewport +
  chrome, both axes). **A row membership change does NOT re-fit through the frame's standard
  `_reactToChildRemoved` / `_reFitContainer` path** — S1(ii) measured a bare frame stuck at the
  latched `THIS_ONE_I_HAVE_NOW` width through three settles after `addMenuItem` — so the viewport's
  `_reLayOutAfterContainedPanelChange` absorb STAYS (re-lay the panel → re-fit the viewport to its
  measure → re-take the frame's extent → re-arm the one-shot), and it works only because
  `firstParentThatIsAPopUp` stops AT the frame (§2.1's override, which P3 lands together with this —
  a plain `FrameWdgt` climbs to the world and the absorb answers `false`). With both, grow and shrink
  each converge in ONE `doOneCycle`, zero re-visits (`.scratch/s1c-absorb-residue-probe.js`).
  `PopUpWdgt._reLayOutAfterContainedPanelChange` itself folds into the viewport's override.
- The ctor's closing `@setExtent new Point 300, 300` (`:301`) becomes a hook (`_initialExtent()`,
  300×300 for windows; the menu citizens answer their hugged extent) — a transient frame is sized at
  construction, so `popUpCenteredAtHand` genuinely centres (F9: deliberate pixel change, ~5 tests).
- `popUp(pos, where)`, `popUpAtHand`, `popUpCenteredAtHand` move onto `FrameWdgt` as placement verbs
  (cap-then-clamp: the content measure caps, `_moveWithin world` clamps, then `addShadow`).
- `MenuWdgt` keeps `actsAsEditorChrome` / `excludedFromEditorFocusTracking` / `isMenu` / the
  `isLockingToPanels = false`; `PromptWdgt` keeps its editor hooks and `tempPromptEntryField`.
- A transient frame has `requiresDeliberateEmbedding → true` like every frame: dropping a (now
  persistent-at-grab) ex-menu into a panel is dwell-armed. Accepted consequence of one rule;
  `SystemTest_macroSubMenuDroppedIntoPanelPinsItself` changes (its drop gains the dwell).

### 2.5 Docking as placement (C11, C12, C13, C6)

- New `EdgeDockLayoutSpec extends LayoutSpec` (`ownsPlacement → true`; template: `CornerInternalLayoutSpec`):
  `side: 'top'|'left'|'right'|'bottom'`, `thickness` (the docked frame's cross extent: the payload's
  `dockThickness?()` if declared, else captured at dock time), `engaged: true` (host mode flag — see below).
- The host frame: `@toolbar` → `@dockedFrames` (a `side → FrameWdgt` map, at most one per side);
  `_dockedToolbarShowing` → `_dockedFrameAt(side)` (present, engaged); the four `_<side>DockThickness`
  read the docked frame's contribution: expanded → `spec.thickness` (+ padding, as today); collapsed →
  the bar thickness (C13 — not 0); disengaged → 0. `_chromeHeight`/`_chromeWidth` unchanged in shape.
- Placement: the `switch @toolbar.dockSide` tail of `_positionAndResizeChildren` (`:1030`) becomes a loop
  over the four slots driving each docked frame's `_reLayout bounds` (a frame's `_reLayout` applies its
  bounds then re-fits chrome + content — same drive as `@bar` today). The docked frame's bar axis and
  roster come from §2.2 (its spec says docked; its `isFreeFloating()` is false).
- **Host mode (view/edit)**: the host sets `spec.engaged = false` for every docked frame in view mode and
  `true` in edit mode (today: collapse/uncollapse of the toolbar, `showEditModeInBar`/`showViewModeInBar`).
  A disengaged dock contributes 0 and is hidden — **the spec decides, visibility follows** (the GHOST
  principle: visibility is never a layout input). A user's own collapse state is the frame's and survives
  a mode round-trip, as the toolbar's collapsed flag does today.
- **Undock by grip drag**: the host answers `wantsDetachOfChild(child) → child is one of my docked
  frames` (F12 — the spreadsheet-cell mechanism; one declaration). The grab pins nothing (already
  persistent) and the frame leaves the slot → `_reactToChildRemoved` re-fits the host AND clears the
  slot entry in `dockedFrames` (S2 measured that the grab alone leaves the host's slot pointer aimed
  at the departed child — `win.toolbar` still pointed at the strip on the desktop); on the world it
  is a window (skin by parentage; close + resizer return by C6). S2 PASS (2026-08-23): the one
  declaration flips `findRootForGrab` from the host frame to the docked child and the real drag lifts
  it out while the host stays put; no build gate objects (`.scratch/s2-toolbar-detach-probe.js`).
- **Dock by drop**: the host's edge BANDS (band width = a preference, ≥ the bar thickness) are drop
  candidates for a frame payload: `wantsDropOfChild` + a new `dockSideAt(point)` query the hand's
  drop-target resolution consults; a frame payload is dwell-armed (spec §4/§6 — a frame
  `requiresDeliberateEmbedding`); release → `_dockFrameNoSettle(frame, side)` which adds the frame with
  an `EdgeDockLayoutSpec` (`defaultLayoutSpecWhenAddedTo` is NOT used — the side is the drop's).
  Candidate highlight = the whole band (the drag-embed ring idiom).
- **Menus**: the docked frame's own context menu offers "dock ➜ <the other three sides>" (re-side =
  `spec.side` change + host invalidate) and "float" (= undock to the world at the strip's position — the
  one programmatic undock, for keyboard-free use). The host's context menu offers "toolbar ➜ top/left/
  right/bottom" iff its content declares `buildToolbar` and no docked frame holds that variant — it
  builds `new FrameWdgt(@contents.buildToolbar())` docked there. `floatToolbar`, `dockToolbarMenu`,
  `dockToolbarTop/Left/Right/Bottom`, `_dockToolbarAtNoSettle`, `_canDockAFreshToolbar`,
  `_destroyToolbarNoSettle` are DELETED. `check-menu-actions` + `fg menusweep` gate the new rows.
- `ToolbarWdgt.dockSide` stays as the payload's *default side* the citizen's `buildToolbar` path uses;
  `dockThickness` becomes the G2 formula `rows · (thumbnailSize + internalPadding) + 2·externalPadding`
  over `ToolPanelWdgt`'s (now preference-backed) constants, with `rows` a preference (2 today).
- World edges (tail T5): the spec is written parent-agnostic; whether `WorldWdgt` grows dock slots is
  decided in P5 and recorded in the ledger either way.

### 2.6 What happens to every `PopUpWdgt` member (disposition table)

| member (`PopUpWdgt.coffee`) | disposition |
|---|---|
| `killThisPopUpIf…` ×2, `isPopUpPinned` | → `lifetime` (§2.1) |
| `isPopUpMarkedForClosure` + `serializationTransients`, `_markPopUpForClosure`, `propagateKillPopUps`, `hierarchyOfPopUps`, `getParentPopUp`, `firstParentThatIsAPopUp`, `widgetOpeningThePopUp` | → `FrameWdgt`, verbatim |
| `rowsPanel`, `rowsViewport` | → the citizens (`MenuWdgt`/`PromptWdgt`); the viewport IS `@contents` |
| `_layOutAndHugRowsPanel`, `_refitRowsViewportNoSettle`, `_buildRowsViewportNoSettle`, `_reLayOutAfterContainedPanelChange` | → the rows viewport's capped measure (world − chrome) for the hug; the membership absorb STAYS as the viewport's `_reLayOutAfterContainedPanelChange` override (S1(ii): the frame's standard re-fit does NOT re-hug a latched width); `_buildRowsViewportNoSettle` → the citizens' ctor |
| `_assertFitsInTheWorld` | → `FrameWdgt` (C10) |
| `pinPopUp`, `_invalidateRowsAfterPinChange`, `isTransientPopUp`, `fullCopy`, `addWidgetSpecificMenuEntries` ("pin" row iff transient) | → `FrameWdgt` (§2.1) |
| `_reactToBeingDropped`, `_updatePopUpShadow`, `addShadow` | → `FrameWdgt` skin/shadow derivation (§2.3) |
| `popUpCenteredAtHand`, `popUpAtHand`, `popUp` | → `FrameWdgt` placement verbs (§2.4) |
| `_destroyNoSettle`, `_closeNoSettle` | → `FrameWdgt` overrides (§2.1) |
| the class, the file | DELETED (P3) |

---

## §3 The axes (why no manifestation is a type)

| axis | today | classification | changes mid-life? |
|---|---|---|---|
| transient vs persistent | class + 2 flags | STATE (`lifetime`) | yes — pin, grab, duplicate |
| window vs card skin | derived from parentage | CONTEXT | yes — drag in/out |
| shadow | derived from pin × parentage × dragging | CONTEXT | yes |
| bar roster | class: bar vs header | DERIVED from lifetime + payload capabilities (+ `isFreeFloating`) | yes |
| resizer | class | DERIVED from payload + `isFreeFloating` | yes |
| corner fall-through | class (`catchesPointerAt false`) | the appearance's SHAPE | — |
| placement (`popUp` vs caller-placed) | class | a VERB | — |
| submenu logical parent | ctor operand | part of the transient policy | — |
| registries + click-outside | class | transient-policy bookkeeping | yes — leave at pin |
| close → destroy vs bin | class + pin branch | lifetime | yes |
| snapshot inclusion | `isTransientPopUp?()` | lifetime | yes |
| dock side / thickness | on the toolbar payload | payload preference, consumed by the host | no |
| column-of-labels vs grid-of-icons | two payload classes | PAYLOAD ARRANGEMENT — out (C16) | — |

A class hierarchy can only express axes that never change during an object's life. None of the
container axes qualifies. Bloch Item 23 (hierarchies over tagged classes) does not apply — the tag
changes at runtime, which is the State pattern's case; with ~six branch sites, an enum-valued field
consulted at the branches (the `scrollPolicy` precedent) beats a policy-object hierarchy. Promote to
policy objects only if the branch sites exceed ~eight (record the count at P6).

---

## §4 The distilled argument

- **Why this approach:** one container + one state + derived manifestations is the *only* shape in
  which every transition the owner wants (pin, nest, undock, re-dock, duplicate) is a state or a
  reparent rather than a rebuild. It is also the shape the codebase already half-uses (two separate
  "derive from context" mechanisms; the framed-citizen pattern; the `scrollPolicy` precedent).
- **Why now:** the viewport arc just established the vocabulary and the method (role name, runtime
  policy, capability queries instead of type tests, zero-recapture structural phases), and the menu
  side was just flattened to "one rows panel in one rows viewport" — the exact payload a frame wants.
- **Why prior attempts did not do it:** nobody attempted it; the Frame-model arc stopped at "windows
  and citizens" and added the toolbar as a slot, which is where `floatToolbar`'s rebuild came from.
- **Conceptual weight**: today a user learns three drag idioms (bar / header / none), three close
  idioms (close button / click-outside / none), two placement APIs, two registries, two title classes.
  After: one container, one bar, one `popUp` verb, one lifetime state, one drop rule. That argument
  survives even if every pixel stays identical.

---

## §5 Phases

Each phase: goal · steps · expected pixel impact · gate · commit. P0's counts are inputs to the
gates of P2/P3/P5.

### P0 — Re-verification, counts, spikes (½ day)

1. `fg status`; `fg gauntlet` baseline (background, log to `/tmp/fg-gauntlet-run.log`) — must be
   18/18 before anything is edited.
2. Re-verify §1.2 F1–F14 by grep (the commands are in the facts). Any drift → update §1 first.
3. **Run, don't read:** H1 (C8's premise) — `fg test SystemTest_macroMenuPinnedByHeaderClick` as a
   baseline, then a scratch probe under `Fizzygum-tests/.scratch/` (NOT the session scratchpad — Node
   resolves `require` from the script's directory) that opens a menu, drags it by its header to an empty
   desktop spot, clicks elsewhere, and asserts whether the menu survives. Record the answer in the
   STATUS box. Either way C8 stands; the probe tells you whether a reference changes.
4. **Measure the declared recapture sets** (program §4 rule 2): (a) tests rendering a nested/internal
   window (P2: the inner close button vanishes) — seed: `grep -rliE "internal window|InternalWindow"
   Fizzygum-tests/tests/*/SystemTest_*.js` → ~24 on 2026-08-23, then confirm by reading which actually
   SHOW a nested bar; (b) tests that `inform` (P3 centring, F9) — ~5; (c) tests rendering a Maker app in
   EDIT mode with a docked toolbar (P5: the grip appears) — seed ~29 (`grep -rlE "Docs Maker|Slides
   Maker|Dashboards Maker|Drawings Maker|Patch"`), confirm by reading. Write the three lists into the
   STATUS box; they are the P2/P3/P5 recapture budgets — anything outside them is a bug.
5. **Spike S1 (P3's risk, must PASS before P3):** in a scratch probe, wrap a `PopUpRowsViewportWdgt`
   over an untitled `MenuRowsPanelWdgt` with a few rows in a plain `new FrameWdgt`, `world.add` it, and
   assert: (i) the window hugs the viewport on BOTH axes at first placement; (ii) after
   `panel.addMenuItem`/`removeMenuItem` the window re-hugs height in ONE settle with no re-visit
   (`fg revisits` semantics — run the probe under the revisit prelude or assert `layoutIsValid` after one
   `doOneCycle`); (iii) a panel taller than the world yields a viewport capped to the world with a
   scrollbar and `_assertFitsInTheWorld` silent. Today `SystemTest_macroMenuInWindowInScrollStackStaysLive`
   covers the nested case — read its macro and reference first. If (ii) re-visits, the residue is the
   viewport's `_reLayOutAfterContainedPanelChange` absorb — keep it and record why.
6. **Spike S2 (P5's risk):** give `FrameWdgt` a temporary `wantsDetachOfChild: (c) -> c is @toolbar`
   in a scratch build and verify a drag on the docked `ToolbarWdgt`'s strip background lifts the toolbar
   out of the frame (today it cannot be grabbed at all — the `findRootForGrab` climb stops at the
   frame). Revert. This proves the one declaration P5 relies on.
7. Write the answers into the STATUS box. Commit nothing (P0 is read-only except scratch files).

**Delegation (§9):** steps 2 and 4 → Sonnet (read-only, parallelisable with each other); step 3 and spikes S1/S2 → ONE Opus worker in sequence (S2 needs a scratch build); the go/no-go on S1/S2 and any §1 amendment → the coordinator.

### P1 — `lifetime` replaces the two flags (½ day; pixel-identical)

- Add `lifetime` + `setLifetime`/`_setLifetimeNoSettle` on `PopUpWdgt` FIRST (the class still exists in
  P1 — smallest diff): `isPopUpPinned` → `@lifetime is 'persistent'`; `isTransientPopUp` likewise;
  `pinPopUp` over the core; `MenuWdgt`'s ctor `opts.killOutside`/`killOnTriggers` DELETED (no caller
  passes them, F1) — the ctor sets `lifetime: 'transient'`; `fullCopy` sets `'persistent'`;
  `_reactToBeingDropped`'s non-world pin stays for now (C8 lands in P4 with the grab hook).
- Delete `FrameWdgt.tight` (T10). Resolve T9 (the stale `PromptWdgt` comment — present tense: "the one
  `isMenu?()` consumer is the hand's click-outside dismissal").
- Tests-repo: `serialization-roundtrip-headless.js:1251` reads `isTransientPopUp` — unchanged API.
- **Gate:** `fg presuite` byte-identical (zero recaptures); the two serialization rigs green — there is NO
  `fg serialization` subcommand (it is a gauntlet leg): `cd Fizzygum-tests && node scripts/serialization-roundtrip-headless.js
  && node scripts/serialization-file-roundtrip-headless.js` (exit 0 each; the first prints its own check count).
- Commit: "PopUpWdgt: one `lifetime` state replaces the two kill flags (program C2/C3)".
- **Delegation (§9):** one Opus worker, whole phase. Budget: zero recaptures.

### P2 — One bar, derived roster, close iff free-floating (1 day; ONE declared recapture set)

- Phase 0 of G2 first, inside this phase: `barIconSize` (16), `barPadding` (5), `barGlyphSize` (16),
  `menuHeaderPadding`, `menuRowsBorder` (2), `toolThumbnailSize` (30), `toolInternalPadding` (5),
  `toolExternalPadding` (10), `toolRows` (2) as preferences; `FrameWdgt.CLOSE_ICON_SIZE` and every literal
  in F13 read through them; `ToolbarWdgt.dockThickness` becomes the formula. `fg census` must stay green
  (arrange idempotence) and `fg presuite` byte-identical — this sub-step is its own commit.
- `FrameBarWdgt` gains the bar-spec-driven roster + metrics + axis parameter (§2.2); `MenuHeader`'s
  text/colour/click-to-pin behaviour moves in as the transient spec; `MenuHeader.coffee` is deleted in P3
  (P2 keeps it alive for the still-separate pop-ups — the bar supports both specs now, proven by the
  frame side only).
- **C6:** the close piece is built/shown iff `@isFreeFloating()`; the resizer already hides itself.
  Re-derive at `_reactToBeingAdded` and at `_setLayoutSpec` (a spec change flips free-floating — the
  same trigger `HandleWdgt.updateVisibility` uses). The `!@isFrame?()` conjunct in `Widget._closeNoSettle`
  (`:603`) and its twins in `_moveToTrashNoSettle` (`:641`) / `_wouldTrashSeverAnything` (`:655`) STAY
  (C6 as amended 2026-08-23: they are close SEMANTICS — a nested frame closes alone — not the button);
  their comments state that in the present tense.
- **Expected pixels:** ONLY the P0(4a) set (inner close buttons vanish). `fg diffpage <set>`; eyeball
  each; `fg recapture` the set; COMPLETE.
- **Gate:** `fg presuite` green with exactly that set recaptured; `fg census`; `fg menusweep` (no menu
  action wiring changes yet, but the bar's pieces are menu-reachable).
- Commit (two): the constants sub-step; then "FrameBarWdgt: roster, metrics and axis derived from a bar
  spec; close iff free-floating (program C5/C6/G2)".
- **Delegation (§9):** the constants sub-step → Sonnet from the F13 literal→preference table (gate: `fg presuite` byte-identical + `fg census`); the bar + C6 → one Opus worker. Budget: the P0(4a) list only; the coordinator eyeballs the `fg diffpage` output before approving the recapture.

### P3 — `MenuWdgt`/`PromptWdgt` as framed citizens; `PopUpWdgt` deleted (1–1.5 days)

- Precondition: S1 passed.
- `FrameWdgt` takes every row of §2.6 marked "→ `FrameWdgt`"; `PopUpRowsViewportWdgt` takes the spec
  + capped measure; `MenuWdgt`/`PromptWdgt` re-base on `FrameWdgt` (§2.4); `_initialExtent()` hook;
  `MenuAppearance` paints the frame; the rows panel loses `title`/`cornerRadius`/header; the three
  `catchesPointerAt: false` overrides go; `PopUpWdgt.coffee` and `MenuHeader.coffee` deleted; the
  `_buildRowsViewportNoSettle` comment's reasoning (why the viewport is unconditional) is preserved as a
  present-tense statement on the viewport class.
- The hand (F6) is touched ONLY where a name changes; its logic is unchanged in P3.
- `MACRO-PATTERNS.md:544` ("a PromptWdgt (extends MenuWdgt extends …)") corrected.
- **Pixel target: byte-identical for every menu/prompt test at dpr1 AND dpr2** except the P0(4b) inform
  set (genuine centring). The transient bar spec reproduces `MenuHeader`'s metrics and the frame's
  `MenuAppearance` reproduces the panel's box; iterate with `fg diffpage` on a handful of menu tests
  before running the suite. **Escape hatch, owner-decided at the time:** if identity proves unreasonable
  after two honest attempts (rule 5 of §0.5), a UNIFORM, explained metric offset across all menu tests
  may land as a reviewed recapture — never an unexplained one.
- **Gate:** `fg gauntlet` 18/18 (this is a phase close — its `serialization` leg runs both rigs); `fg storage` (transient →
  destroy, persistent → bin); `fg vmtruth` (the deleted class must leave no retained closures);
  `fg menusweep` + `fg pinsweep`.
- Commit: "Menus and prompts are framed citizens; PopUpWdgt deleted (program C1/C14)".
- **Delegation (§9):** one Opus worker, the whole phase, in TWO briefs if it runs long (a: `FrameWdgt` takes §2.6 + the viewport spec/measure + the citizens re-base, gate `fg presuite`; b: appearance/bar-spec pixel identity + deletions + gauntlet). The escape hatch is the coordinator's to invoke with the owner — the worker reports the residual diff, it never recaptures. Budget: the P0(4b) inform set only.

### P4 — Skin + shadow derivation unified; grab pins (½ day; pixel-identical)

- `_deriveAndSetBodyAppearance` → `f(lifetime, parentage)`; the shadow policy keyed the same way; both
  re-derived at `_setLifetimeNoSettle` and `_reactToBeingAdded`.
- **C8:** the grab hook pins; `_reactToBeingDropped` reduced to the shadow re-derive. New test
  `SystemTest_macroGrabbedMenuStaysOnDesktop` (drag by header to the desktop, click elsewhere, the menu
  persists with the window roster). `SystemTest_macroSubMenuDroppedIntoPanelPinsItself` gains the dwell
  (its macro changes; its reference likely not).
- **Gate:** `fg presuite` byte-identical except the one new/changed test; `fg revisits`.
- Commit: "Frame skin and shadow derived from lifetime × parentage; grabbing a transient frame pins it
  (program C4/C8)".
- **Delegation (§9):** one Opus worker; the new macro test may be a Sonnet sub-brief from the step list above. Budget: the P0(4d) set + the one new test + the one changed macro.

### P5 — Docking as placement (1.5–2 days; ONE declared recapture set)

- Precondition: S2 passed; ruling on Rec. C17 obtained (ask the owner at P5 start; default if
  unanswered: NOT implemented, filed in the ledger).
- `EdgeDockLayoutSpec`; host `dockedFrames`; thickness/placement/engaged (§2.5); `wantsDetachOfChild`;
  edge-band drop candidates + `dockSideAt` in the hand's drop resolution (read the drag-embed state
  machine at `ActivePointerWdgt.coffee:190–260` first; a frame payload is dwell-armed already); the new
  menu rows; the deletions; `buildToolbar` callers now build a docked FRAME; `ToolbarWdgt.dockSide` as
  default side; the `FrameWdgt.coffee:1` TODO deleted.
- Bar axis (C13): the bar's arrange gains the vertical layout of its pieces; text suppressed when
  vertical; collapsed docked frame = bar along the edge, thickness = bar thickness.
- Tests: `SystemTest_macroDocsToolbarDockSidesAndFloat` and `…SlotEditViewToggle` rewritten for the new
  gestures (float = grip drag to the desktop; re-dock = drop on a band; four sides); NEW:
  `macroDockedFrameHasNoCloseNoResizer`, `macroCollapsedDockIsAnEdgeSliver`, `macroDockAnyFrame` (a
  document window docked at a window's left), `macroViewModeDisengagesDocks`.
- **Expected pixels:** ONLY the P0(4c) set (the grip appears on every edit-mode docked toolbar) + the
  two rewritten tests. Review with `fg diffpage`; recapture; COMPLETE.
- **Gate:** `fg gauntlet` 18/18; `fg census` (the new arrange must be idempotent — the toolbar re-wrap
  fixed point at `ToolbarWdgt._positionAndResizeChildren` must survive being driven through a frame);
  `fg menusweep` (every new row wired).
- Commit: "Docked frames: an edge layout spec, four slots, grip drag-out, drop-to-dock; floatToolbar
  dissolved (program C11/C12/C13)".
- **Delegation (§9):** the coordinator obtains the C17 ruling FIRST, then one Opus worker in three briefs: (a) `EdgeDockLayoutSpec` + host slots/thickness/placement/engaged + `wantsDetachOfChild`, replacing the slot machinery, gate `fg presuite` + `fg census` (the grip does not exist yet — bar axis still horizontal, so this brief is NOT pixel-identical: the docked bar appears; budget = P0(4c)); (b) the bar axis + collapsed-dock geometry; (c) drop-to-dock in the hand + the menu rows + the deletions + the tests (the four new macro tests → Sonnet sub-briefs from step lists the Opus worker writes). Gauntlet after (c).

### P6 — The Liskov walk, names, docs (½ day)

- Walk every `isFrame?()` consumer (9: `Widget.coffee:603/641/655/4580`, `WorldWdgt.coffee:3240`,
  `WidgetCreatorAndSmartPlacerOnClickMixin.coffee:26`, the two inside `FrameWdgt`, the spec comment)
  and every `firstParentThatIsAPopUp` consumer (14) with a menu citizen in mind; record each verdict in
  the STATUS box. Known-correct on 2026-08-23 reasoning (re-verify): the content→window close redirect
  is right for a menu citizen (closing its rows viewport closes the menu); the "close" vs "delete" menu
  label now says "close" for menus; the smart placer asks `contents.acceptsSmartPlacedWidgets?()` → the
  rows viewport does not.
- Name sweep (T8 — `firstParentThatIsAPopUp` → a frame-vocabulary name, if the owner wants it; grep
  `Fizzygum-tests/scripts/` + `MacroToolkit` + `MACRO-PATTERNS.md` too). Count the `lifetime` branch
  sites (§3's ~8 threshold) and record.
- Docs (present tense, woven in — never appended notes): `docs/architecture/regularity-principles.md`
  (the frame model gains: lifetime; three manifestations; docked = card + edge spec; bar roster/close
  rule), `widget-citizenship.md` point 5 ("dragged off a PERSISTENT frame"), `viewports-and-planes.md`
  (rows viewport as frame content; `PopUpWdgt` mentions), `layering-naming-convention.md` and
  `lint-and-static-checks.md` (`PopUpWdgt` mentions), `serialization-duplication-reference.md`
  (`lifetime`, the transient drop), `docs/specs/drag-embed-interaction-spec.md` (the dock bands as a
  receptivity tier), `src/macros/MACRO-PATTERNS.md`, `Fizzygum-tests/CLAUDE.md`, root/`Fizzygum/CLAUDE.md`
  if they name the pop-up family; `docs/BACKLOG.md` (T1–T5 entries); the program doc's STATUS box + tail
  ledger. Run `fg doc-narration`.
- **Gate:** `fg gauntlet` 18/18; `fg homepage` (the production profile round-trip — the only
  production-tree snapshot gate).
- Then the **close-arc ritual** (the `close-arc` skill): final gate, memory note, end-of-arc review,
  proposed commit messages, wait. Then the **tail session** (program §5).
- **Delegation (§9):** the Liskov walk → Opus (it returns a verdict table, one row per site, with the quoted code); the docs weaving → Sonnet, one brief per doc file, parallel (disjoint files), each brief quoting the exact target section and the present-tense paragraph to weave; the close-arc ritual and the review → the coordinator; the tail → per-item briefs from the ledger.

---

## §6 Central risks and how each is bounded

| risk | where | bound |
|---|---|---|
| The rows viewport misbehaves as frame content (two-writer fight, re-visits, wrong hug) | P3 | S1 in P0 is the go/no-go; the menu-sandwich dissolution's case law (the measure IS the frame, `scrolledContentMeasureIsMyFrame`) is the mechanism that makes a hugging plane legal as direct contents |
| Pixel drift on menus masks regressions (menus appear in most tests) | P3 | byte-identity target + the explicit, owner-decided escape hatch; never a silent recapture |
| Settle-tier violations (pin inside a drop's settle; grab hook settling) | P1/P4 | keep `pinPopUp`'s two-branch shape; hooks on the NoSettle tier; `fg tiernaming` + `fg settle` legs |
| The hand's dismissal logic regresses | P3 | names only; logic untouched; `SystemTest_macroHoppingBetweenSubMenus` + the `menusweep` leg |
| Docked arrange not idempotent (the toolbar's re-wrap fixed point driven through a frame) | P5 | `fg census` after every P5 step; the existing comment at `ToolbarWdgt._positionAndResizeChildren` explains the fixed point — keep it true |
| Drop-to-dock competes with drop-into-content on the same host | P5 | the band is consulted FIRST and only for a frame payload; content drop unchanged otherwise; dwell on both |
| `wantsDetachOfChild` lets the wrong child out | P5 | the host answers only for members of `dockedFrames` |
| Cross-repo name drift (scripts read registry names) | P1/P3/P6 | F10's list; grep `Fizzygum-tests/scripts/` in every rename commit |
| Deleted class leaves retained closures / registry corpses | P3 | `fg vmtruth`; `world.resetWorld`'s registry clears (`WorldWdgt.coffee:3053–3055`) already cover the sets |

---

## §7 Verification protocol

- Inner loop per step: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (build + dpr1 suite ∥ paint
  audit ∥ fracplane). Byte-identical = the gate for every structural step.
- Declared pixel sets: `fg build` → `fg diffpage <names>` → read the page → `fg recapture <names>` →
  COMPLETE; then `fg presuite` again.
- Arrange changes (P2 constants, P5): `fg census` additionally.
- Phase close (P3, P5, P6): `fg gauntlet` (18 legs, ~5–6 min) in the background; `cat
  /tmp/fg-gauntlet.verdict` at a 5-min cadence. A `[shard N] did not start within 90s` is the boot-storm
  flake, not a bug; a leg that passes on its serial retry is a load-flake warning, not a FAIL.
- Gates that WILL fire and what to do: `check-menu-actions` (P5's rows — wire the verb, no string
  targets), `check-call-separation` rule [U] (`setLifetime`, `popUp`, `dockSideAt` are deliberate public
  API → `buildSystem/public-api-allowlist.txt`), `check-dead-methods` (the deleted `floatToolbar` family
  must vanish from tests/scripts too), `check-unresolved-sends` (renames), `check-thin-wraps`
  (`setLifetime`/`_setLifetimeNoSettle` must be a proper twin), `check-constructors-build` (no inline
  `add` in ctors — the citizens build through `_buildAndConnectChildren`), `check-stinks` comment-smell
  (no narration), the constructor-hole gate (floor 2 — don't add holes), `check-layering` [J]/[G]
  (hooks never settle; low-level never calls a settling wrapper), `check-plane-discipline` (read the
  mapped `pos` in any new hit/drop code — never raw pointer reads).
- Probes: `Fizzygum-tests/.scratch/` only.

---

## §8 Rejected alternatives — do not re-attempt

- **Merge-on-drop** (a window adopts a dropped menu's rows): a type test in gesture form; destroys the
  user's object; irreversible. C7 — nest.
- **A "pinned menu" / "docked" skin**: keyed on history / position, which parentage + spec already
  express. C4/C12.
- **A grip class for docked frames**: same as above; the bar with a derived roster IS the grip.
- **Close button on a docked toolbar** (or any host-owned frame): disruptive at touch scale; the host
  owns membership. C6 — and it buys the deletion of the internal-window exception.
- **Restricting the dock slot to toolbar payloads**: a type test; `QDockWidget` accepts anything. C12.
- **Renaming `FrameWdgt` to `WindowWdgt`**: names one manifestation (the `ScrollFrame` lesson). C1.
- **A lifetime policy-object hierarchy now**: ~six branch sites; the `scrollPolicy` precedent; promote
  only past ~eight (§3).
- **An "unpin" gesture**: menu rent nothing asks for. C3.
- **Keeping `PopUpWdgt` as a mixin the frame wears**: a mixin that exists to be worn by ONE class is
  the hierarchy in disguise; and mixin edits leak across suite tests (memory: `duplicator-engine-conversion`).
- **Conversion on undock (today's `floatToolbar`)**: the regretted tear-off-menu pattern; the same object
  must move. C12.
- **Hiding a docked frame via `hide()` for view mode and reading visibility in the host's thickness**:
  visibility is never a layout input (the GHOST principle, Bin/Shelf arc) — the spec's `engaged` flag
  decides and visibility follows.
- **Toolbar ⇄ menu inside this arc**: a payload axis; would re-fuse payload and chrome. C16 → T1.

---

## §9 Delegation map — coordinator and workers (program §3.1)

The coordinator (the session) never edits source or runs suites; it briefs, reads reports, checks
verdict files, decides at gates, and talks to the owner. Workers are fresh agents with no
conversation context: `Agent` with `subagent_type: general-purpose`, `model: "opus"` (phase work)
or `"sonnet"` (mechanical work). ⛔ Never `fork` (inherits the expensive model), never
`isolation: worktree` (the build needs the `Fizzygum-all/` sibling layout + the tests symlink).
**One code worker at a time** — one tree, one build output. Parallel workers only for read-only
work and for docs edits to disjoint files.

### 9.1 Per-phase map

| phase | worker | parallel? | brief = plan section + | gate the worker runs | coordinator decides |
|---|---|---|---|---|---|
| P0 counts + F-facts | Sonnet ×2–3 | yes (read-only) | the F1–F14 grep commands; the three P0(4) seed greps | none | records counts into the STATUS box |
| P0 H1 probe, S1, S2 | Opus ×1 | no (S2 builds) | the assertion lists of P0 steps 3, 5, 6 | `fg test …`, scratch builds, `fg revisits` semantics for S1(ii) | go/no-go for P3 (S1) and P5 (S2); §1 amendments |
| P1 | Opus ×1 | no | §2.1 + F1, F11; tests-scripts file list F10 | `fg presuite` byte-identical; the two serialization rigs (from `Fizzygum-tests/`) | commit proposal |
| P2 constants | Sonnet ×1 | no | the F13 literal→preference table, G2/G3 | `fg presuite` byte-identical; `fg census` | commit proposal |
| P2 bar + C6 | Opus ×1 | no | §2.2; the P0(4a) list as the ONLY allowed pixel set | `fg presuite`; `fg diffpage <4a list>`; `fg menusweep` | eyeballs the diffpage; approves `fg recapture`; commit |
| P3 | Opus ×1 (two briefs) | no | §2.4, §2.6, S1's findings; the P0(4b) list | `fg presuite` per brief; `fg gauntlet` at close; `fg storage`, `fg vmtruth`, `fg menusweep`, `fg pinsweep` | the escape hatch (with the owner); commit |
| P4 | Opus ×1 (+ Sonnet for the test) | no | §2.3, C8; the macro step list for the new test | `fg presuite`; `fg revisits` | commit |
| P5 | Opus ×1 (three briefs) + Sonnet for 4 tests | no | §2.5, C12/C13/C17 ruling, S2's findings; the P0(4c) list | `fg presuite` + `fg census` per brief; `fg gauntlet` after (c); `fg menusweep` | C17 ruling obtained first; eyeballs P0(4c) diffpage; commit |
| P6 Liskov walk | Opus ×1 | no | the 9 + 14 consumer sites | builds only | reads the verdict table |
| P6 docs | Sonnet ×N | yes (disjoint files) | per file: the section to edit + the present-tense paragraph | `fg doc-narration` | reviews the diffs |
| P6 close | coordinator | — | — | `fg gauntlet`, `fg homepage` | close-arc ritual, memory, owner |
| tail | per item | per item | the ledger row + its destination | as the item needs | ledger bookkeeping |

### 9.2 The worker brief (template — copy, fill the ⟨⟩, nothing else)

```
You are executing ⟨phase/sub-step⟩ of Fizzygum/docs/plans/frame-lifetime-and-docking-plan.md.
Read that plan's §0, §0.5 and §⟨phase⟩ in full, then Fizzygum/docs/plans/frames-input-touch-program.md
§2 for rulings ⟨IDs⟩. Also read Fizzygum-all/CLAUDE.md and Fizzygum/CLAUDE.md. All commands through
/Users/davidedellacasa/code/Fizzygum-all/fg by absolute path. Probes under Fizzygum-tests/.scratch/.
Do: ⟨the phase's step list, or "every step of §⟨phase⟩"⟩.
Gate: ⟨exact fg command(s)⟩ → expected ⟨verdict⟩. Launch long ops with run_in_background and wait for
the notification; never poll; never pipe the gating call.
Pixel budget: ONLY these tests may change: ⟨list or "none"⟩. Any other diff = STOP (rule 3).
Stop and report (do not improvise) if: a §1 fact is false; a fix shape is falsified twice; a gate
fails for a reason you cannot state in one sentence; a diff appears outside the budget; you need a
decision the ledger does not cover. Never recapture, never commit, never push.
Comments you write: present tense only, no history narration (the build's comment-smell ratchet fails
on it). `undefined` is the one absence value.
Report (≤ 60 lines): files changed (git diff --stat); each gate's literal /tmp/fg-<cmd>.verdict line;
counts measured; tests added/changed; open questions; which stop rule fired, if any.
```

### 9.3 What the coordinator checks on every report (cheap, never a re-do)

1. `cat /tmp/fg-<cmd>.verdict` for each gate the report claims — the literal line, not the prose.
2. `git -C <repo> status --short` and `git diff --stat` — the changed-file list matches the phase.
3. If the report names a pixel diff: `fg diffpage` was produced → look at it (this is the one
   visual judgement the coordinator keeps).
4. If a stop rule fired: read ONLY the evidence the report quotes; amend §1 or the brief; re-brief.
   Two stops on the same step → re-frame (rule 5 of §0.5 applies to the coordinator too).
5. Then: commit proposal to the owner, or the next brief.

## §10 References

- Program: [`frames-input-touch-program.md`](frames-input-touch-program.md) — rulings, sequencing,
  recapture policy, tail ledger, **§3.1 the execution model this §9 instantiates**.
- Living truth to update at P6: [`../architecture/regularity-principles.md`](../architecture/regularity-principles.md),
  [`../architecture/widget-citizenship.md`](../architecture/widget-citizenship.md),
  [`../architecture/viewports-and-planes.md`](../architecture/viewports-and-planes.md),
  [`../architecture/layout.md`](../architecture/layout.md) (settle tiers; `_reLayout`/`_reLayoutChildren`),
  [`../architecture/layering-naming-convention.md`](../architecture/layering-naming-convention.md),
  [`../architecture/lint-and-static-checks.md`](../architecture/lint-and-static-checks.md),
  [`../architecture/serialization-duplication-reference.md`](../architecture/serialization-duplication-reference.md),
  [`../specs/drag-embed-interaction-spec.md`](../specs/drag-embed-interaction-spec.md).
- Case law: [`../archive/onion-widget-composition-plan.md`](../archive/onion-widget-composition-plan.md)
  (§5.B framed citizens; §5.C the toolbar slot, D9; §5.E close policy), [`../archive/
  scroll-frame-role-architecture-plan.md`](../archive/scroll-frame-role-architecture-plan.md) (policy over
  structure; P3's "a deleted hook can still have subclass `super` callers" lesson — grep every OVERRIDER
  before deleting a member), [`../archive/menu-sandwich-dissolution-plan.md`](../archive/menu-sandwich-dissolution-plan.md)
  (the rows panel as the viewport's direct plane), [`../archive/menu-row-conformance-plan.md`](../archive/menu-row-conformance-plan.md)
  (the rows panel as a stack client; `menuEntryPreferredWidth` incl. the header's), [`../archive/
  drag-embed-implementation-plan.md`](../archive/drag-embed-implementation-plan.md) (dwell-to-arm as built).
- Memory notes the executor should know exist (the owner's auto-memory index): ask-before-commit/push;
  long-op ETA + status every ~5 min; no conclusions before evidence; stop after two falsified fixes;
  comments/docs are a deliverable; recapture churn must not dictate design; a cross-repo rename must
  grep the tests scripts; perl/sed blanket edits de-indent `.coffee` — use the Edit tool.
