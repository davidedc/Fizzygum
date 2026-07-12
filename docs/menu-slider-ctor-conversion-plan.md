# Menu/slider-family constructor conversion — plan

**STATUS: ✅ COMPLETE 2026-07-12 — all four sites CONVERTED (verdict 1), exemption count 0,
byte-identical, zero recaptures. See §8.**

## 0.5 P0 verification findings (2026-07-12, current-tree evidence)

- §3 delta table verified verbatim against `Widget.coffee` `_addNoSettle` (~:3038) /
  `__add` (~:3106).
- **`calculateAndUpdateExtent` delta**: `grep -rn "calculateAndUpdateExtent" src/` shows
  ONLY `StringFieldWdgt` (~:44) overrides it (measures text, applies width ≥ minTextWidth).
  Base `Widget.calculateAndUpdateExtent` (~:3104) is an EMPTY no-op ⇒ the delta VANISHES
  for P1 (SliderButtonWdgt) and P2 (MenuHeader); it is REAL only for P3 (both prompts'
  `@tempPromptEntryField`).
- **`setLayoutSpec` delta DEFUSED**: the default spec arg (`defaultLayoutSpecWhenAddedTo` ⇒
  `LayoutSpec.ATTACHEDAS_FREEFLOATING`, Widget ~:3010) equals Widget's FIELD default
  (~:264), and `setLayoutSpec` (~:638) early-returns on equality ⇒ no-op at all 4 sites.
- **Hook deltas (the plan under-weighted these)**: base `Widget._reactToBeingAdded`
  (~:2988) runs `@_reLayoutSelf()` on the added CHILD. So `_addNoSettle` triggers, at ctor
  time: SliderButtonWdgt._reLayoutSelf (parent-guarded, geometry fully derived from the
  parent slider — idempotent, recomputed on every later _reLayoutSelfAndButton);
  MenuHeader → Widget's no-op; StringFieldWdgt → its lazy `@text` build (P3!). SliderWdgt
  itself overrides it (`_reLayoutSelfAndButton`) — fires when a PROMPT adds its slider (P3).
  `_reactToChildAdded`: menu family extends PopUpWdgt extends **Widget** (not PanelWdgt) ⇒
  none defined ⇒ skipped; slider extends CircleBoxWdgt ⇒ same.
- **Ctor-time settle now FLUSHES**: `_settleLayoutsAfter` (~:778) on a top-level `new X()`
  opens the mutation window and runs `world.recalculateLayouts()` (the orphan-receiver
  DEFER arm only applies inside an enclosing flush). So conversion adds one ctor-time
  relayout of the orphan subtree that today happens at popup/attach — extra idempotent
  work; `Widget.coffee` ~:3022 documents `_addNoSettle` as byte-identical to `add()` for
  fresh non-world children (no-op removeShadow, skipped fractional step).
- **P1-1 answered**: nothing in SliderWdgt's super chain reads `@button` — Widget's ctor
  sizes via `_commitBounds` → `__commitExtent` (commit LEAVES, no `_applyExtent` dispatch),
  CircleBoxWdgt's via `__commitExtent`. The pre-super placement was legacy style.
- **P0-2 inspector-pin check**: the 10 inspector macros inspect RectangleWdgt / StringWdgt /
  AnalogClockWdgt — none pins a menu/slider/prompt member list ⇒ ZERO benign recaptures
  expected. (`macroInspectorScrollbarUnplugged` screenshots detached SliderWdgt PIXELS —
  byte-identity coverage, not a member list.)

## 0. Goal, non-goals, honest possible verdicts

**Goal.** Retire the four `# constructor-build-exempt:` markers added 2026-07-12 when
`check-constructors-build.js` learned to see `@__add` — by CONVERTING each constructor to the
canonical all-constructors-settle pattern (`ctor → @_buildAndConnectChildren()` wrapper →
`_buildAndConnectChildrenNoSettle` core) **where the conversion is byte-identical**, and by
recording an evidence-backed by-design verdict where it is not.

**Acceptance for the arc**: suite 243/243 byte-identical at dpr1+dpr2, Chrome+WebKit, full
`fg gauntlet` + `fg homepage` green; ZERO reference recaptures expected (a benign inspector
member-list recapture is tolerable ONLY if an inspector macro turns out to pin MenuWdgt /
SliderWdgt / prompt member lists — see P0-2); ctor-build gate green with the converted sites'
markers REMOVED (`[ctor-build] N marked-exempt` count drops accordingly).

**Non-goals**: no renames of the locked tier names; no change to `__add` / `_addNoSettle`
themselves; no menu look/behaviour change; the WorldWdgt dev-menu "show all"/"hide all"
removal is a SEPARATE parked item (12-macro recapture — see the TODO at the site).

**Honest possible verdicts per site** (all three are acceptable outcomes):
1. CONVERTED — canonical pattern, marker removed, byte-identical.
2. PARTIALLY CONVERTED — e.g. structure moved into a core but the settle wrapper shape
   differs; marker replaced by a narrower, factual one.
3. BY-DESIGN — two falsified conversion shapes (stop rule) ⇒ the exemption is the correct
   end-state; reword the marker from "predates the pattern" to "by design because <evidence>".

## 1. How we got here (context for a cold start)

- The all-constructors-settle campaign (2026-06-30, `08bbb29d`; doc
  `docs/all-constructors-settle-plan.md`) converted the 13 inline-building constructors it
  could SEE to: ctor calls settling `@_buildAndConnectChildren()`, children built in
  `_buildAndConnectChildrenNoSettle` via `@_addNoSettle`. The gate
  `buildSystem/check-constructors-build.js` locks this in.
- Its `BUILD` regex was `/@_?add(Many)?(NoSettle)?[ (]/` — it could not match `@__add`
  (double underscore), so four constructors that build children through the `__add`
  STRUCTURAL LEAF passed invisibly.
- 2026-07-12 (simplification follow-ons): the regex was widened to `/@_{0,2}add…/`
  (self-tested), `ColorPickerWdgt`'s one-hop `buildSubwidgets` indirection was properly
  converted, and the four `@__add` sites got factual `# constructor-build-exempt:` markers.
  The owner then asked for THIS plan: convert them for real, as a dedicated verified arc.

## 2. The four sites (verbatim state at authoring, post-marker)

1. **`src/basic-widgets/SliderWdgt.coffee` ctor** (~:32-45):
   `@button = new SliderButtonWdgt` BEFORE `super`; after super: `@alpha = 0.1`,
   `@__commitExtent new Point 20, 100`, `@__add @button`.
   NB `VideoScrubberWdgt extends SliderWdgt` inherits this ctor path.
2. **`src/basic-widgets/menu-system/MenuWdgt.coffee` ctor** (~:24-41): after super +
   appearance setup, `unless @isListContents: if @title then @createLabel(); @__add @label`.
   `createLabel` (~:68) sets `@label = new MenuHeader @title` — and is ALSO called from the
   label-REBUILD path (title changes), so the build logic is already shared post-ctor.
3. **`src/PromptWdgt.coffee` ctor** (~:23-64): builds `@tempPromptEntryField`
   (a `StringFieldWdgt`) BEFORE `super`; after super: `@__add @tempPromptEntryField`,
   optionally builds a `SliderWdgt` (sets colors, `slider.__commitHeight …`, target/action)
   and `@__add slider`; then `@addLine 2`, two `@addMenuItem`, trailing `@_reLayoutSelf()`.
4. **`src/SaveShortcutPromptWdgt.coffee` ctor** (~:16-42): same shape as PromptWdgt minus
   the slider; tail is `@_reLayoutSelf()`, `@_applyWidth 150`,
   `@tempPromptEntryField.text.edit()`.

Menu family tree: `MenuWdgt` ← `PromptWdgt`, `SaveShortcutPromptWdgt` (grep
`extends MenuWdgt`). Menus are ALSO reused as list contents (`@isListContents` branch —
ListWdgt's contents is a MenuWdgt) — any ctor change must hold for BOTH branches.

## 3. THE core engineering fact — what `@__add` does vs what `@_addNoSettle` would do

(Read both bodies before executing; anchors: `Widget.__add` ~:3106, `Widget._addNoSettle`
~:3038. Line numbers drift — grep the symbol.)

| step | `__add aWdgt` (bare, as the 4 sites call it) | `_addNoSettle aWdgt` |
|---|---|---|
| ancestor-cycle guard | no | yes (`return nil if aWdgt.isAncestorOf @`) |
| detach from old parent | `removeChild` only, NO old-parent hooks | old parent `_invalidateLayout(aWdgt)` + `_reactToChildRemoved` |
| shadow management | NONE | `addShadow` (if world) / `removeShadow` (else), unless `skipsAddShadowManagement`; tooltip cancel |
| layout spec | NOT touched | `setLayoutSpec` (default `defaultLayoutSpecWhenAddedTo(@)`) |
| layout invalidation | NONE | old parent + new parent `_invalidateLayout(aWdgt)` |
| repaints | NONE | `fullChangedIncludingShadowOwner()` + `fullChanged()` |
| notification hooks | NONE | `_reactToBeingAdded` / `_reactToChildAdded` / old-parent `_reactToChildRemoved` |
| child extent recalc | **`calculateAndUpdateExtent()` RUNS** (2nd arg falsy) | **SKIPPED** (`@__add aWdgt, true, position`) |
| fractional recording | no | if parent is world |

⚠ TWO deltas cut in OPPOSITE directions: `_addNoSettle` ADDS spec/shadow/invalidate/hooks
the menu family never ran, and it REMOVES the `calculateAndUpdateExtent()` the bare `__add`
DID run on the child. A conversion is NOT a mechanical verb swap: each site must account for
where the child's extent calculation happens post-conversion, and must show the added
semantics are no-ops here (fresh orphan child ⇒ removeShadow no-op; ctor tail already
invalidates/re-lays; hooks mostly undefined on these children — verify per child class).

## 4. Why the panel pattern doesn't just drop in

- **Dynamic composition**: a plain MenuWdgt's ITEMS are composed by the OPENER after
  construction (`addMenuItem`/`addLine`, which use `__add` internally at ~:58/:62/:108/:113 —
  those are NOT ctor sites and are OUT OF SCOPE). Only the LABEL is ctor-built. The prompts,
  by contrast, compose everything in-ctor — they are the truest conversion candidates.
- **Ctor-param binding**: CoffeeScript binds subclass `@`-ctor-params only AFTER `super()` —
  the reason ScrollPanelWdgt uses a DISTINCT `_buildScrollFrame` name (see
  `check-constructors-build.js` header + `docs/all-constructors-settle-plan.md`). PromptWdgt
  builds `@tempPromptEntryField` from ctor params BEFORE super on purpose (it passes it TO
  super as the menu's `environment`-slot arg... verify: `super widgetOpeningThePopUp, false,
  @target, true, true, @msg or "", @tempPromptEntryField`). A hoisted
  `_buildAndConnectChildrenNoSettle` called from the BASE ctor would run before the
  subclass params it reads are bound — the same trap. Any conversion must keep the build
  call in the SUBCLASS ctor (or use a distinct per-class core name), never hoist it to
  MenuWdgt's ctor.
- **Popup-time layout**: menus re-lay via `_reLayoutSelf` at popup; the prompt ctors'
  trailing `@_reLayoutSelf()` is the old defer-to-attach style the gate header calls out.
  Whether replacing that tail with the settling wrapper is byte-identical is an EMPIRICAL
  question (the settle flushes; `_reLayoutSelf` direct-applies).
- **`beforeBeingOpenedByPopUpper` / popup machinery** may assume the ctor-time child set —
  check `PopUpWdgt`/`MenuWdgt` popup path before moving builds later.

## 5. Phases (smallest, best-covered blast radius first; ONE phase per commit point)

**P0 — preliminaries (no edits)**
1. Baseline: `fg status` clean; last gauntlet green.
2. Inspector-pin check: grep the test corpus for inspector macros whose TARGET is a menu,
   slider, or prompt (member-list shots). Expected none (the known member-list pinner
   inspects a rectangle; Widget-level changes are not in play here — these are subclass
   members). If one exists, budget the benign recapture and note it in the phase.
3. Re-read the two bodies in §3 in the CURRENT tree (they moved 2026-07-12: `_addNoSettle`
   now calls `fullChangedIncludingShadowOwner`).

**P1 — SliderWdgt** (one child; enormous incidental pixel coverage — every scrollbar is a
SliderWdgt via ScrollPanelWdgt's `@hBar`/`@vBar`, plus the slider macros; 29 test files
reference prompts/sliders)
1. Investigate WHY `@button = new SliderButtonWdgt` precedes `super` (does anything in the
   Widget ctor chain read `@button`? grep SliderWdgt for overrides called during ctor —
   e.g. appearance/orientation code). Record the answer in this doc.
2. Shape A: ctor → `@_buildAndConnectChildren()`;
   `_buildAndConnectChildrenNoSettle: -> @button = new SliderButtonWdgt; @_addNoSettle @button`
   with `@__commitExtent new Point 20, 100` staying in the ctor (it is geometry, not
   child-building). Account for the §3 deltas: button is fresh+orphan (shadow no-op);
   `setLayoutSpec` on the button — CHECK what spec the button carries today (nil?) and
   whether SliderWdgt/ScrollPanelWdgt layout reads it; `calculateAndUpdateExtent` — check
   `SliderButtonWdgt.calculateAndUpdateExtent` (base Widget's is a no-op ~:3104; if the
   button's IS a no-op the delta vanishes).
3. `fg lint` + `fg presuite`; any diff ⇒ revert, try Shape B (keep `@__add` but wrap build
   in the core — partial verdict 2). Two failed shapes ⇒ STOP, verdict 3 with evidence.
4. Remove SliderWdgt's marker; gate must stay green (count 4→3).

**P2 — MenuWdgt label**
1. The only ctor-built child is `@label` (title menus, non-list branch). Shape A: move
   `if @title then @createLabel(); @__add @label` into `_buildAndConnectChildrenNoSettle`
   guarded `unless @isListContents`, ctor → wrapper. ⚠ `createLabel` is also the REBUILD
   path — keep it intact and reuse it from the core (breadcrumb: reuse over duplication).
2. Verify the §3 deltas for a `MenuHeader`: spec assignment (menus position the label in
   `_reLayoutSelf` ~:170 by direct `_applyMoveTo` — does a set spec change that?), and
   `MenuHeader.calculateAndUpdateExtent` existence/behaviour (`__add` bare RUNS it today —
   the label's extent may DEPEND on this call; if so `_addNoSettle` skipping it will show
   as a wrong-width header in the very first menu shot).
3. Coverage: the 12 menu macros (list recorded in the WorldWdgt dev-menu TODO probe,
   2026-07-12: BasicWorldMenuAndBubble, CheckNumberOfItemsInWorldMenu,
   DuplicatedMenuAutoPinsOnDesktop, HoppingBetweenSubMenus, MenuPinnedByHeaderClick,
   MenuRepositionsToStayOnScreen, MenuShadowCorrectWhileAndAfterDrag,
   MenusAndSubMenusRemainOpenWhileDraggingMenusOnly, MenusCloseOnMouseDownOutside,
   PinnedMenuKeepsCorrectShadowWhenBroughtToForeground, RightClickClosesDownstreamSubMenus,
   SubMenuDroppedIntoPanelPinsItself) + every menu-driving macro incidentally.
4. Same verify/stop protocol as P1. Remove MenuWdgt's marker on success (count →2).

**P3 — PromptWdgt, then SaveShortcutPromptWdgt** (do PromptWdgt first — superset shape)
1. These compose EVERYTHING in-ctor (fields, optional slider, buttons via `addMenuItem`,
   trailing `_reLayoutSelf`) — the truest fit for the pattern, but the most moving parts:
   - keep `@tempPromptEntryField` construction pre-super (it is PASSED to super);
   - move the two `@__add` calls + the slider build into `_buildAndConnectChildrenNoSettle`;
   - decide where `@addLine`/`@addMenuItem` live: they are the menu-family PUBLIC
     composition API, self-contained — leaving them in the ctor after the wrapper call is
     acceptable (they are not `@add` family and not gate-relevant); moving them into the
     core is optional tidiness — prefer the minimal diff;
   - the tail `@_reLayoutSelf()` (+ `@_applyWidth 150` + `.edit()` in SaveShortcut): test
     whether the wrapper's settle makes the explicit `_reLayoutSelf()` redundant — REMOVE
     ONLY on byte-identical evidence, else keep (it is not gate-relevant).
2. Coverage: prompt macros (rename/property prompts, save-shortcut flow — grep tests for
   `PromptWdgt`/`SaveShortcutPrompt`/"save as"); `_takeSliderValueConnector` ([P] lane)
   must keep working — the slider's target/action wiring moves verbatim.
3. Same verify/stop protocol. Remove both markers on success (count →0).

**P4 — closeout**
1. `check-constructors-build.js`: delete the "menu/slider family carries explicit exemption
   markers" clause from the BUILD-regex comment if all four converted (or update the count).
2. Sync `docs/lint-and-static-checks.md` (constructor-build row mentions "4 menu/slider-
   family ctors carry it" — update) and `docs/all-constructors-settle-plan.md` (add a
   completion note: the __add blind spot + this arc).
3. Full `fg gauntlet` + `fg homepage`. Update THIS doc's status ledger. Present for commit.

## 6. Verification protocol (every phase)

- `fg lint` (2 s) → `fg presuite` (~3.5 min, background + verdict file) after EVERY shape.
- Byte-identity is the acceptance: ANY screenshot diff ⇒ the shape is wrong ⇒ revert
  (never recapture your way past a conversion diff — unlike member-list churn, a menu/
  slider/prompt pixel diff means the semantics moved).
- Stop rule: two falsified shapes on one site ⇒ verdict 3 (by-design), write the evidence
  into §8, move on. Do not try a third variant.
- Arc end: full `fg gauntlet` (dpr1+dpr2+WebKit+apps+audits) + `fg homepage`.

## 7. Landmines (each bought with evidence — do not rediscover)

- **`avoidExtentCalculation` delta** (§3): the single most likely silent-diff source.
  `@__add x` (bare) runs `x.calculateAndUpdateExtent()`; `_addNoSettle` skips it.
- **`setLayoutSpec` delta**: `_addNoSettle` assigns a layout spec the menu family's
  children never had; menu layout (`_reLayoutSelf` ~:135-183) walks children skipping
  `@label` by identity, not by spec — but spec-driven code elsewhere (window embedding,
  pinning a menu into a panel — `macroSubMenuDroppedIntoPanelPinsItself`) may read it.
- **Ctor-param binding after super** (§4) — keep build calls in the subclass ctor;
  the ScrollPanelWdgt `_buildScrollFrame` distinct-name precedent is the escape hatch.
- **Menus are list contents** (`@isListContents`): ListWdgt reuses MenuWdgt with the label
  branch OFF and popup bookkeeping deleted — every MenuWdgt ctor change must be probed with
  a ListWdgt fixture too (`macroAddingWidgetToListUpdatesScroll`, `macroListWdgtWheelScroll`).
- **Prompt slider wiring**: `slider.target = @; slider.action = "takeSliderValue"` feeds
  both the public path and the `_takeSliderValueConnector` [P]-lane — move verbatim.
- **2026-07-02 MEANING SWAP**: pre-swap history reading `_applyExtent` means today's
  `_applyExtentBase` — beware when reading old menu-family commits.
- **The gate's own header** documents the inctor state machine and marker semantics — a
  marker is detected in the comment block directly above the ctor OR in its body; reason
  text mandatory.

## 8. Status ledger

- 2026-07-12: AUTHORED (this doc). No code changes. Current exemption count: 4
  (MenuWdgt, PromptWdgt, SaveShortcutPromptWdgt, SliderWdgt), all marked factually.
- P1 SliderWdgt: ✅ CONVERTED (verdict 1) 2026-07-12, Shape A first try — `@button` build moved
  into `_buildAndConnectChildrenNoSettle` (with the P1-1 answer as a breadcrumb), marker
  removed, gate count 4→3, `fg lint` + presuite dpr1 243/243 byte-identical + paint audit
  green (20:00:42).
- P2 MenuWdgt: ✅ CONVERTED (verdict 1) 2026-07-12, Shape A first try — label build moved into
  a core reusing `createLabel`; the pair is named `_buildMenuLabel`/`_buildMenuLabelNoSettle`
  (DISTINCT name, the ScrollPanelWdgt `_buildScrollFrame` precedent: MenuWdgt is a base whose
  prompt subclasses build children, so the canonical virtual name from the base ctor would
  dispatch into their cores too early). Marker removed, gate count 3→2, presuite dpr1
  243/243 byte-identical + paint audit green (20:04:52).
- P3 prompts: ✅ BOTH CONVERTED (verdict 1) 2026-07-12, Shape A first try — field build stays
  pre-super (passed TO super); the two `__add`s + PromptWdgt's slider build moved into
  canonical-named cores (both prompts are LEAF classes, so the virtual-name trap doesn't
  apply); the ONE real semantic delta preserved by an explicit
  `@tempPromptEntryField.calculateAndUpdateExtent()` after `_addNoSettle` (bare `__add` ran
  it; StringFieldWdgt's is the tree's only override — measures text, applies width). The
  `addLine`/`addMenuItem` tails + trailing `_reLayoutSelf()` (+ `_applyWidth 150`/`.edit()`
  in SaveShortcut) kept in the ctor verbatim (minimal diff; they are not gate-relevant).
  Markers removed, gate count 2→0, presuite dpr1 243/243 byte-identical + paint audit green
  (20:08:14).
- P4 closeout: ✅ 2026-07-12 — gate BUILD-regex comment updated (exemption clause →
  conversion pointer); `docs/lint-and-static-checks.md` §3 row + §long-form synced (count
  ZERO); `docs/all-constructors-settle-plan.md` completion note added (the `__add` blind
  spot + this arc). Full gauntlet EXIT=0 (20:15:15): dpr1/dpr2/apps/paint/tiernaming/
  settle/capstone PASS in-wave; the WEBKIT leg was PASS-serial-only — its one in-wave
  failure was `macroClosingRotatedIslandChildClearsFootprint` (the broken-rect-staleness
  canary, the suite's most load-sensitive incremental-repaint assertion), characterized as
  a LOAD-FLAKE with evidence: it passed WebKit serially, passed a standalone 8-shard
  parallel WebKit re-run 243/243 (20:17:58), and passed both Chrome legs with the same
  code. `fg homepage` green (20:15:40). Suite BYTE-IDENTICAL throughout the arc — zero
  recaptures, zero reference changes.
