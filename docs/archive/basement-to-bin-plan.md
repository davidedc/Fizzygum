> **ARCHIVED — ✅ EXECUTED IN FULL + CLOSED (2026-07-22, same day it was authored).** All five phases
> landed and gated: `BasementWdgt` renamed to `BinWdgt` (+ `BinOpenerWdgt`/`BinIcon*`/`world.binWdgt`/
> `isInBin*`/`R.binCount`, both repos patched together); the all-items view deleted outright (no
> dev-mode escape hatch); `TrashcanIconWdgt` + appearance removed.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Basement → Bin conversion

**STATUS: EXECUTED IN FULL + CLOSED 2026-07-22 (same day it was authored).** All five phases
landed and gated (presuite per phase, serialization rigs + a `.scratch/bin-oracle-probe.js`
functional probe at Phases 2/3/4b, full gauntlet green after Phase 3 and again at arc close).
Owner decisions, collected live: Empty bin CONFIRMS first (in-world transient menu); the
all-items view is DELETED OUTRIGHT (no dev-mode escape hatch — §4 Phase 3b's recommendation
was declined); scatter presentation kept (grid deferred); Phase 4b renames APPROVED and done
(BinWdgt / BinOpenerWdgt / BinIcon* / world.binWdgt / isInBin* / WellKnownObjects+InfoDocs
keys / R.binCount, files git-mv'd, both repos patched together); Phase 5 APPROVED and done
(TrashcanIconWdgt + appearance + catalog entry deleted). Deviations from the plan text:
`PopUpWdgt.close` was DELETED rather than kept (the thin-wrap gate demanded the canonical
shape; the `openPopUps` bookkeeping moved into the `_closeNoSettle` override, which also
fixes the pre-existing NoSettle-drain leak), and the lost-only filter became the symmetric
public `refreshLostOnlyView` (hide reachable AND re-show lost — with the toggle gone, an
item going lost while hidden had no other path back to visible).

**Mandate:** eliminate the Basement's role conflation at the root — transient UI must *die* on
dismissal instead of being warehoused, the user-facing artifact must become an honest recycle
Bin (lost items only, emptiable), and the backing-store role must become invisible
infrastructure. No half-measures like "hide the junk better" or "add a second filter."

Line numbers below were verified 2026-07-22 and WILL drift — the quoted method names and code
snippets are authoritative; re-grep before trusting any `file:line`.

---

## §0 Orientation

Fizzygum (repo `Fizzygum/`, CoffeeScript, ~470 one-class-per-file sources, no module system,
built by `./build_it_please.sh` into `../Fizzygum-builds/latest`) is a canvas "web OS":
desktop, windows, drag-and-drop. Verification is the 196-test screenshot-diff SystemTest suite
in the sibling `Fizzygum-tests/` repo, run via the umbrella `fg` wrapper
(`/Users/davidedellacasa/code/Fizzygum-all/fg`). Read the root and `Fizzygum/CLAUDE.md` first.

**The Basement** (`src/BasementWdgt.coffee`) is a BoxWdgt, created at boot
(`src/boot/globalFunctions.coffee`, `world.basementWdgt = new BasementWdgt` inside
`startWorld`), held OFF-TREE (it is not a world child; it gets wrapped in a `FrameWdgt` window
only when the user clicks the desktop's Basement icon, `src/BasementOpenerWdgt.coffee`
`mouseClickLeft`). Today it conflates THREE roles:

1. **The disk (keep, make invisible).** The simulated file system is "a network of pointers to
   stuff that *rests* in the basement" — stated verbatim in the `FolderPanelWdgt.coffee` header
   comment. Referenced documents (save-on-close via
   `Widget._createReferenceAndCloseNoSettle`), widgets dropped into folders
   (`CreateShortcutOfDroppedItemsMixin`), closed singleton app windows
   (`IconicDesktopSystemWindowedApp.launch` re-fetches them), and the templates window
   (`TemplatesButtonWdgt.mouseClickLeft`) all rest here.
2. **The trash (keep, make THE user-facing identity).** Widgets closed without a reference are
   "lost": `BasementWdgt.doGC` mark-and-sweeps reachability from the shortcut tracker
   `world.widgetsReferencingOtherWidgets`; the "☐ only show lost items" toggle
   (`hideUsedWidgets` / `showAllWidgets`) hides the referenced ones.
3. **The landfill (ELIMINATE).** Every dismissed unpinned menu, prompt, and `inform` box:
   `PopUpWdgt.close` → `Widget._closeNoSettle` → `world.basementWdgt._addLostWidgetNoSettle`.
   Nothing ever revives them; every menu is built fresh (`new MenuWdgt` everywhere). They
   accumulate unboundedly (no production purge exists — `BasementWdgt.empty()` is inside
   homepage-build exclusion markers, test-only) and they ride every saved world snapshot
   (`Serializer.serializeWorld` roots include `theWorld.basementWdgt`).

**Critical reframe (don't bury this):** the close-button flow already triages documents
correctly — `FrameWdgt._saveOrAskThenCloseCitizen`: unchanged+unreferenced → `fullDestroy`;
changed+unreferenced → save prompt; referenced → basement. So once transient pop-ups stop
being warehoused, the "lost" population is *exactly* bin-shaped: things the user closed
without saving a reference, and things orphaned when their last shortcut died. The Bin is not
a new mechanism — it is the existing lost-items view made permanent, honest, and emptiable.

**Why now:** the BasementIconAppearance was owner-redesigned 2026-07-22 as a literal BIN
(size-aware arc, Fizzygum `d1058c9a`) — the icon already promises bin semantics the widget
doesn't deliver. And the InfoDocs basement blurb already *claims* "items that can't be used
again are automatically recycled", which is currently false — this plan makes it true.

**Prior related arcs** (case law lives in `docs/archive/INDEX.md` and the memory notes):
serialization-damage-bookkeeping fix 2026-07-22 (established that closed widgets ride
snapshots via the basement — the rig code-comments say "the trash" already); §7.5 island
figure re-homing (close re-homes the enclosing island FIGURE, not the bare widget); the
owner's standing "NO serialization compat obligations" ruling (2026-07-17: zero saved
documents need to keep loading — rename keys/flags freely, never build shims).

---

## §0.5 Cold-execution protocol

1. Read this doc top to bottom. Then read, in the live tree: `src/BasementWdgt.coffee`,
   `src/PopUpWdgt.coffee`, `src/BasementOpenerWdgt.coffee`, `Widget.close`/`_closeNoSettle`/
   `destroy`/`_destroyNoSettle`/`fullDestroy`/`_fullDestroyNoSettle` in
   `src/basic-widgets/Widget.coffee`, `WorldWdgt.closePopUpsMarkedForClosure` (+ NoSettle
   twin), `ActivePointerWdgt` around the `closePopUpsMarkedForClosure()` call, and
   `Fizzygum-tests/scripts/serialization-roundtrip-headless.js` (search `basementCount` and
   `pinnedInEnvelope`).
2. Re-verify every §1 claim by grep before coding — this doc's line refs are 2026-07-22.
3. Execute phases IN ORDER. Phase 2 MUST land before Phase 3 (see the Phase-2 rationale —
   skipping it makes "Empty bin" able to destroy system furniture).
4. Gate every phase with §7's commands. Never edit src mid-suite (standing ⚠⚠). Use
   `run_in_background: true` for gauntlet/suite runs; never foreground-poll.
5. Owner gates: Phase 3 UX choices (marked), Phase 4b class renames, Phase 5 deletion.
   Ask before any commit/push (standing owner preference). One end-of-arc review at the end,
   not per-phase.

---

## §1 Exact current state (all verified 2026-07-22)

### The dismissal machinery (what Phase 1 changes)

- `MenuWdgt` (src/basic-widgets/menu-system/MenuWdgt.coffee) ctor: if
  `killThisPopUpIfClickOutsideDescendants` → `@onClickOutsideMeOrAnyOfMyChildren "close"` —
  the click-outside dispatcher (`ActivePointerWdgt`, the
  `wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.forEach` near line ~872) invokes that method
  NAME on the popup. So click-outside dismissal calls `close()`.
- Item-trigger dismissal: `MenuItemWdgt` click → `propagateKillPopUps` → popups added to
  `world.popUpsMarkedForClosure` → drained AFTER the click's actions by
  `world.closePopUpsMarkedForClosure()` (ActivePointerWdgt ~841; also `PopUpWdgt.pinPopUp`) →
  `eachWidget.close()`. Drop path drains via `world._closePopUpsMarkedForClosureNoSettle()` →
  `eachWidget._closeNoSettle()`. The ActivePointerWdgt comment above the drain (~833) already
  documents WHY dismissal is deferred to post-action ("if we destroyed menus earlier, the
  actions … might be mangled") — keep that deferral, change only what the drain DOES.
- Only popups that were unpinned at marking time ever enter `popUpsMarkedForClosure`
  (`propagateKillPopUps` is gated on `killThisPopUpIfClickOnDescendantsTriggers`, which
  pinning sets false first).
- `Widget.close` = `@_settleLayoutsAfter => @_closeNoSettle()`. `_closeNoSettle`: non-frame
  content inside a frame forwards to the frame's `_closeNoSettle`; then
  `world.basementWdgt._addLostWidgetNoSettle @_enclosingIslandFigure()` (re-homes the whole
  island FIGURE — §7.5 Bug B; else `world.inform "There is no\nbasement to go in!"`).
- `PopUpWdgt.close`/`destroy` both also `world.openPopUps.delete @`.
- Destroy family: `destroy` → `_destroyNoSettle` (removes from stepping/keyboard/dataflow/
  click-outside sets, clears caret+editor-focus if inside, detaches; children kept);
  `fullDestroy` → `_fullDestroyNoSettle` (bottom-up recursive). Tooltips already die:
  `WorldWdgt.destroyToolTips` → `tooltip.fullDestroy()`, with the comment "we are not
  expecting anybody to revive them once they are gone (as opposed to menus)" — the "(as
  opposed to menus)" clause is the fossil this plan removes.
- `world.inform` builds an unpinned `MenuWdgt` with one "Ok" item → currently basement junk.
- `PromptWdgt` "Close" and `SaveShortcutPromptWdgt` "Cancel" buttons → `@close` on the prompt
  (an unpinned popup) → currently basement junk.
- `ToolTipWdgt extends Widget` (NOT MenuWdgt) — untouched by a PopUpWdgt override.
- `PopUpWdgt.isTransientPopUp()` = `not @isPopUpPinned()` already exists (serializer uses it).

### The GC / "lost" oracle (what Phase 2 fixes)

- `BasementWdgt.doGC`: increments `world.incrementalGcSessionId`; pass 1 marks ORPHAN
  references visited (unreachable by definition, since the basement is on-screen when this
  runs); pass 2 marks targets of non-orphan non-basement references (+parents) reachable
  (`TreeNode.markItAndItsParentsAsReachable`); pass 3 iterates basement-held references to a
  fixpoint (`isInBasementButReachable`). Reachability derives ONLY from
  `world.widgetsReferencingOtherWidgets` — the Set that `IconicDesktopSystemShortcutWdgt`
  (and subclasses: document/folder/script shortcuts) register into.
- **False-lost furniture:** app launchers hold the APP OBJECT
  (`IconicDesktopSystemWindowedAppLauncherWdgt` target = the `IconicDesktopSystemWindowedApp`
  singleton, "launch" action) and are NOT in the tracker; `world.simpleEditorTemplates` is a
  bare world field. So a closed singleton app window (world slots, see
  `Serializer.WORLD_APP_SLOTS`: `degreesConverterWindow`, `howToSaveDocWindow`,
  `sampleDashboardWindow`, `sampleSlideWindow`, `sampleDocWindow`) and the parked templates
  window are classified LOST today. Harmless while "lost" is just a view filter; fatal once
  the Bin can be EMPTIED (the user would destroy revivable system furniture).
- `hideUsedWidgets` (action string of the "☒/☐ only show lost items" `ToggleButtonWdgt`):
  runs `doGC`, then **hides** each basement child that IS reachable. `showAllWidgets` shows
  all. `showingLostItemsOnly` is a plain serialized field. `_reactToChildAddedInScrollPanel`
  re-applies whichever filter is active when something new lands.
- **The hidden-state landmine:** re-open paths must un-hide what the filter hid.
  `IconicDesktopSystemShortcutWdgt.bringUpTarget` already calls `@target.show()` +
  `whatToBringUp.show()` (its comment names the basement filter as the reason). But
  `TemplatesButtonWdgt.mouseClickLeft` (`world.add world.simpleEditorTemplates`) and
  `IconicDesktopSystemWindowedApp.launch` (`world.add figure`) do NOT call `show()`. Today
  that never bites — precisely BECAUSE the oracle misclassifies that furniture as lost (lost
  ⇒ never hidden). Phase 2 flips them to reachable ⇒ hidden under the filter ⇒ these two
  paths MUST gain `show()` in the same commit, and Phase 3 (permanent filter) hard-depends
  on it.

### Serialization surface

- `Serializer.serializeWorld`: transient (unpinned) popups + ephemerals are filtered from
  `section.children`/roots — but ONLY at the world-children level; the basement is a full
  root, so everything warehoused in it (today: every dismissed menu of the session) rides
  every snapshot. `section.basement = ref(...)`; `WellKnownObjects` key `"basement"`.
- Rig `Fizzygum-tests/scripts/serialization-roundtrip-headless.js` (a gauntlet leg since
  2026-07-22, together with `serialization-file-roundtrip-headless.js`):
  - `world.samePage.statePreserved` asserts `R.basementCount()` is preserved across a
    round-trip (count-neutral to this plan — it compares before/after on the same session).
  - `world.transientPopUp.excludedFromSnapshot` asserts a menu saved MID-GESTURE leaves zero
    `MenuWdgt`/`MenuRowsPanelWdgt` records (menu still a world child at save time — unaffected).
  - `world.pinnedPopUp.survivesSnapshot` counts envelope `MenuWdgt`s with
    `title === 'Pinned'` and expects exactly 1; its code comment explains the earlier closed
    'Desktop' menu "was re-homed to the basement (the trash), so it legitimately rides the
    snapshot there". After Phase 1 the closed menu leaves NO records — the assertion still
    passes (it filters by title), but that comment becomes false and MUST be rewritten
    (present-tense, per the comment rubric: no "used to / no longer" phrasing).
  - `world.pinnedPopUp.*` requires pinned menus to KEEP being serialized and restorable —
    Phase 1 must not touch pinned-popup close semantics.

### UI / naming surface (Phase 4 scope, all verified)

- `BasementWdgt.colloquialName` → `"Basement"` (window title derives from it).
- `BasementOpenerWdgt` ctor: `super "Basement", new GenericShortcutIconWdgt new
  BasementIconWdgt` (the desktop caption); created by `MenusHelper.basementIconAndText`
  (called from `WorldWdgt.createDesktop`, which only runs on the index page — the SystemTest
  harness world has NO desktop icons, so caption changes churn no test screenshots); also
  reachable via the desktop menu item `"basement shortcut"`.
- `Widget._closeNoSettle` fallback message: `"There is no\nbasement to go in!"`.
- `InfoDocs.REGISTRY.basement`: flag `infoDoc_basement_created`, title `"Basement"`,
  windowTitle `"Basement info"`, body "Drag things in here to recycle them.\n\nClosed or
  invisible items also end up in here, and the items that can't be used again are
  automatically recycled." Spawned once on first basement open
  (`BasementOpenerWdgt.mouseClickLeft` → `InfoDocs.createNextTo "basement", …`).
- Icon-catalog menu items in `MenusHelper`: `"Basement icon"` → `createBasementIconWdgt`,
  and `"Trashcan icon"` → `createTrashcanIconWdgt` (`world.create new TrashcanIconWdgt`).
- `TrashcanIconWdgt`/`TrashcanIconAppearance` (src/icons/): used NOWHERE else — not in the
  rest of src, not in Fizzygum-tests (tests + `Automator-and-test-harness-src/` both grepped
  clean 2026-07-22). It is a purely decorative spawnable catalog icon.
- `BasementIconAppearance`: already a size-aware BIN glyph (owner-redesigned 2026-07-22).
- Dropping a widget ONTO the desktop Basement icon already files it into the basement
  (`BasementOpenerWdgt._reactToChildDropped`) — i.e. "drop on the bin to throw away" already
  works and gains honest semantics for free.

### Test exposure

- Exactly 3 SystemTests reference the basement, all via `world.basementWdgt.holds` /
  close-reopen parking assertions (`SystemTest_macroTiltedWindowKeepsRotationThroughCloseReopen`,
  `SystemTest_macroExplicitIslandTravelsWholeThroughCloseReopen`,
  `SystemTest_macroClosingRotatedIslandChildClearsFootprint` — the last one comment-only).
  They park DOCUMENTS/figures, not menus → unaffected by Phases 1–3. Phase 4b (renaming the
  `world.basementWdgt` field, if taken) breaks the first two and must patch them in the same
  arc.
- No SystemTest opens the basement window or screenshots its contents.
- `MacroToolkit.getMostRecentlyOpenedMenu` reads `world.freshlyCreatedPopUps` while menus are
  OPEN — dismissal-time changes don't touch it.
- Memory ⚠⚠: any new method on `Widget` itself churns
  `macroDuplicatedInspectorDrivesCopiedTargetOnly` (inherited-methods list scroll). This plan
  adds methods only on `PopUpWdgt`/`BasementWdgt` — expected safe, but if that test diffs,
  recapture, don't chase.

---

## §2 Why it is shaped this way

Morphic heritage: in Morphic-descended systems "close" was the universal soft-delete, and the
original Fizzygum design imagined menus as revivable (the `destroyToolTips` comment says so
explicitly). Revival for unpinned menus was never built — menus are composed fresh by their
opener on every popup (`MenusHelper` and ~380 `addMenuItem` sites) — but the warehouse-on-close
default survived because nothing forced the issue: the basement is off-screen, so the junk was
invisible until (a) snapshots started riding it and (b) the owner looked inside.

The basement-as-disk role, by contrast, is deliberate and GOOD design (the FolderPanelWdgt
header is a mini-spec of it): pointers in folders, payloads at rest, pulled in and out as the
user works. This plan does not weaken it — it stops making the user LOOK at it.

---

## §3 The distilled argument

- Dismissed transient popups have **zero revival value** (rebuilt fresh, unreferenceable once
  dismissal starts) and **nonzero cost** (unbounded in-session growth; dozens of widgets per
  menu baked into every world snapshot). Tooltips already set the destroy precedent. The one
  historical reason to warehouse them (imagined revival) is documented dead.
- With the landfill gone, "lost items" is exactly what a user means by a bin, and the
  machinery (doGC, the lost-only filter, hide/show, `bringUpTarget`'s un-hide) already
  exists. The conversion is mostly *subtraction*: delete the toggle, make the filter
  permanent, add the one genuinely missing operation (Empty bin).
- The disk role needs no user-facing view: shortcuts/folders ARE the finder. Anyone needing
  the raw heap (debugging) keeps it via dev mode (owner call, Phase 3).
- The lazy classification (lost computed at view time, no migration bookkeeping) is the
  quiet elegance of the current design — every alternative below that abandons it was
  rejected for that reason (§6).

---

## §4 Phases

### Phase 1 — transient pop-ups die on dismissal (the landfill fix)

**Change (one chokepoint):** override `_closeNoSettle` on `PopUpWdgt`:

```coffee
  # Dismissal policy: a PINNED pop-up is desktop furniture -- closing it is the ordinary
  # widget close (to the bin, revivable via a shortcut like any widget). An UNPINNED
  # pop-up is mid-gesture UI (menus, prompts, informs): dismissal destroys it outright,
  # like tooltips -- it is rebuilt fresh by its opener every time, so warehousing it
  # would only grow the bin and every world snapshot.
  _closeNoSettle: ->
    if @isPopUpPinned()
      super
    else
      @_fullDestroyNoSettle()
```

Because `close()` is just the settle wrapper over `_closeNoSettle`, this single override
covers ALL four dismissal paths (click-outside "close" dispatch, both closure drains, direct
`@close` on prompts) with zero call-site edits. `PopUpWdgt.close`'s `openPopUps.delete` stays;
the destroy path deletes from `openPopUps` too (`PopUpWdgt.destroy`).

Also in this phase:
- Add idempotence: early-`return if @destroyed` at the top of the override (a stale
  `widgetOpeningThePopUp` chain can re-mark an already-destroyed menu; today's re-home path
  absorbed that quirk, the destroy path should explicitly no-op).
- Rewrite the fossil comments IN PRESENT TENSE (comment rubric: never "used to/previously"):
  `destroyToolTips`'s "(as opposed to menus)" clause; the serialization rig's
  `pinnedInEnvelope` comment (`serialization-roundtrip-headless.js`, search "re-homed to the
  basement") — it must now say the closed menu is destroyed and leaves no records; check
  `PopUpWdgt`/`ActivePointerWdgt` comments that mention menus going to the basement.
- Grep sweep for other prose claiming menus rest in the basement:
  `grep -rn "basement" Fizzygum/src Fizzygum-tests/scripts Fizzygum/docs/architecture` and fix
  what Phase 1 falsifies (notably
  `docs/architecture/serialization-duplication-reference.md` if it mentions pop-up close).

**Risks:** a macro that dismisses a menu and later touches it (none known — the drain already
runs post-action, and `MacroToolkit` grabs menus while open); settle/damage-path differences
between re-home and destroy showing up as pixel diffs at dpr2 (suite will say; recapture only
after eyeballing benign). The `world.pinnedPopUp.*` rig checks guard the pinned branch.

**Gate:** `fg presuite`, then both serialization rigs explicitly (they run inside
`fg gauntlet`; for the inner loop:
`cd Fizzygum-tests && node scripts/serialization-roundtrip-headless.js` and
`node scripts/serialization-file-roundtrip-headless.js`).

### Phase 2 — fix the reachability oracle (system furniture is never "lost")

**Change:** in `BasementWdgt.doGC`, after the existing reference passes, mark the world-slot
furniture reachable for this GC session:

```coffee
    # system furniture parked in the basement is reachable through WORLD FIELDS, not
    # through the shortcut tracker: the app singletons (world[slot], revived by their
    # desktop launchers) and the editor templates window (revived by TemplatesButtonWdgt).
    # Without this they'd classify as lost -- and be shown in, and destroyable from, the bin.
    for slot in Serializer.WORLD_APP_SLOTS
      world[slot]?.markItAndItsParentsAsReachable newGcSessionId
    world.simpleEditorTemplates?.markItAndItsParentsAsReachable newGcSessionId
```

(`markItAndItsParentsAsReachable` climbs parents, so marking the window also marks its
enclosing island figure — the basement child that `hideUsedWidgets` inspects.)

**Mandatory companion (the §1 landmine):** add the missing un-hide to both furniture re-open
paths — `TemplatesButtonWdgt.mouseClickLeft` (the `world.basementWdgt.holds` branch:
`world.simpleEditorTemplates.show()` before/with the `world.add`) and
`IconicDesktopSystemWindowedApp.launch` (`figure.show()` in the re-home branch). Mirror
`bringUpTarget`'s existing idiom and comment.

**Gate:** `fg presuite`. Manual probe (or a tiny headless script in
`Fizzygum-tests/.scratch/`): close the degrees-converter window, open the basement, press
"only show lost items" → the parked converter must now HIDE (it shows today); click its
desktop launcher → it must come back visible.

### Phase 3 — the Bin: permanent lost-only view + Empty bin  ⚠ owner-gated UX choices

**Changes in `BasementWdgt`:**
- Delete the `hideUsedWdgtsToggle` (both `SimpleButtonWdgt`s, the `ToggleButtonWdgt`, the
  `showingLostItemsOnly` field, and `showAllWidgets`). The lost-only filter becomes the only
  mode: rename `hideUsedWidgets` to a private `_applyLostOnlyFilter` EXCEPT it can no longer
  be a button-action string (those must stay public un-underscored — standing rule) — since
  the button goes away this is fine; `_reactToChildAddedInScrollPanel` calls it
  unconditionally.
- Re-filter **on open**: `BasementOpenerWdgt.mouseClickLeft` runs the filter after spawning /
  re-fronting the window (references die while the bin is closed; the view must be fresh at
  open). Child-adds while open are already covered by `_reactToChildAddedInScrollPanel`.
- **Empty bin:** new method on `BasementWdgt`, surfaced as a `SimpleButtonWdgt` in the layout
  slot the toggle vacates (the `_reLayout` geometry for the toggle row is reusable as-is):

```coffee
  emptyBin: ->
    newGcSessionId = @doGC()
    lostOnes = (w for w in @scrollPanel.contents.children when !w.isInBasementButReachable newGcSessionId)
    for w in lostOnes
      w.fullDestroy()
```

  Compute the lost set ONCE from a single `doGC`, then destroy — never recompute mid-loop
  (destroying a binned shortcut can make its target newly lost; that target is already in
  THIS session's lost set if and only if it was unreachable, which is the correct
  semantics: binning the last link binned the document). Note `doGC`'s stated precondition
  (basement on-screen) holds here — the button lives in the open bin window.
- Shortcut-revival of referenced items keeps working untouched (`bringUpTarget` un-hides).

**Owner decisions to collect at phase start:**
  a. Confirmation before Empty bin? (recommend: yes, a `world.prompt`/inform-style confirm —
     it is the framework's only bulk-destructive user action).
  b. Keep a dev-mode-only "show everything" escape hatch (a menu entry on the bin window when
     `world.isDevMode`), or delete the all-items view outright? (recommend: dev-mode entry —
     it IS the debugging window into the disk role).
  c. Presentation: keep the pseudo-random scatter (`_addInPseudoRandomPositionNoSettle`) or
     switch to a `representativeIcon` grid? (recommend: defer the grid to a follow-up; it is
     cosmetic and this arc is semantics.)

**Gate:** `fg presuite`; serialization rigs (the `world.samePage.statePreserved` leg counts
basement children before/after a round-trip — still count-neutral). Then `fg gauntlet` to
close Phases 1–3 as a commit point.

### Phase 4 — naming & copy (user-visible), then optional class renames  ⚠ 4b owner-gated

**4a — copy (safe, no test screenshots show any of it — the harness world builds no desktop):**
- `BasementWdgt.colloquialName` → `"Bin"`.
- `BasementOpenerWdgt` caption arg → `"Bin"`.
- `Widget._closeNoSettle` fallback inform → `"There is no\nbin to go in!"`.
- `InfoDocs.REGISTRY.basement` → title `"Bin"`, windowTitle `"Bin info"`, body rewritten to
  the now-true semantics (drop things here / closed unreferenced things land here / referenced
  documents live behind their shortcuts / Empty bin destroys what's inside). Rename the flag
  `infoDoc_basement_created` → `infoDoc_bin_created` (serialized in the world section's
  infoDoc* scan; the no-compat ruling applies — do NOT shim the old flag).
- `MenusHelper`: `"basement shortcut"` menu label → `"bin shortcut"`; `"Basement icon"`
  catalog label → `"Bin icon"`.
- Prose sweep: `grep -rni basement Fizzygum/src` and update comments to bin vocabulary where
  they describe the USER-FACING artifact; comments describing the resting/disk role should
  say so honestly (it still exists internally).

**4b — identifier/class renames (owner-gated, separate commit):** `BasementWdgt`→`BinWdgt`,
`BasementOpenerWdgt`→`BinOpenerWdgt`, `BasementIconWdgt`/`BasementIconAppearance`→`BinIcon*`,
`world.basementWdgt`→`world.binWdgt`, `TreeNode.isInBasement`/`isDirectlyInBasement`/
`isInBasementButReachable`→ bin names, `_addLostWidgetNoSettle` stays (already honest),
`WellKnownObjects` key `"basement"`→`"bin"` (no-compat ruling), `InfoDocs.REGISTRY` key.
Per repo conventions each rename is a whole-tree identifier+file sweep; **it also touches
Fizzygum-tests**: the two close/reopen tests assert `world.basementWdgt.holds` and the
serialization rig defines `R.basementCount` — patch both repos in the same arc. Renames can
shift drawn labels (colloquial names in inspector/hierarchy views) → run the full suite and
recapture what's benign (`fg recapture --auto` on a FRESH build — standing ⚠⚠).

**Gate:** `fg presuite` after 4a; full `fg gauntlet` after 4b (or after 4a if 4b is declined).

### Phase 5 — retire `TrashcanIconWdgt`  ⚠ owner-gated deletion

It is a decorative catalog icon used only by `MenusHelper.createTrashcanIconWdgt` + its
`"Trashcan icon"` menu entry (verified: zero other uses in src, tests, or harness src — the
dead-code-gate memory rule's harness grep is already done, re-run it before deleting).
Recommend: delete class + appearance + the two MenusHelper lines — with the Basement icon now
a bin, two bin glyphs in the catalog is confusion. Removing the menu entry re-flows that
icons submenu, so any SystemTest that screenshots it will diff → run the suite, recapture
after eyeballing. If the owner prefers keeping a decorative trashcan, do nothing.

---

## §5 Central risks

1. **Destroy-at-dismissal timing.** The drain runs post-action by design; the risk is a code
   path holding a menu ref ACROSS gestures (e.g. `widgetOpeningThePopUp` chains,
   `firstParentThatIsAPopUp` walks). Mitigations: the `@destroyed` guard (Phase 1), the
   existing suite (196 tests exercise menus heavily), the pinned-popup rig checks.
2. **The hidden-furniture landmine** (§1): Phase 2's `show()` companions are NOT optional;
   land them in the same commit as the oracle change.
3. **Empty bin destroying too much.** Guarded by Phase ordering (2 before 3) and the
   single-doGC lost-set rule. The semantics "binned last shortcut ⇒ document dies with the
   bin" is intended — surface it in the confirm text (Phase 3a).
4. **Screenshot churn.** Expected near-zero for Phases 1–3 (basement invisible in tests,
   no desktop icons in the harness world); possible inspector churn if any method lands on
   `Widget` itself (avoid; nothing in this plan needs it); Phase 4b/5 churn is real but
   bounded — recapture, don't chase (standing rule).
5. **Snapshot-content drift.** Snapshots get SMALLER (no warehoused menus). The rig's
   count-based checks are before/after-same-session and title-filtered — verified unaffected;
   still, run both rigs at every phase gate since they are the sharpest observers of this
   surface.

---

## §6 Rejected alternatives (do not re-attempt without new evidence)

- **Physically split the roles: a registry-of-orphans "disk" + a real bin container.**
  Rejected: abandons the lazy lost-classification (needs became-lost migration bookkeeping),
  adds a serialization root, and buys no UX over the filtered view. The single-place model
  with a permanent filter delivers the same user experience with strictly less mechanism.
- **Destroy popups at mark time (inside `propagateKillPopUps`) instead of at the drain.**
  The ActivePointerWdgt comment documents the hazard (actions running after the click would
  touch destroyed menus); the deferred drain exists precisely for this. Keep the drain,
  change its verb.
- **Filter menus out at serialization time instead of destroying them.** Treats the symptom:
  the in-session unbounded growth and the dead-weight GC scans remain, and the serializer
  grows a second popup filter to maintain. The junk should not exist, not be hidden better.
- **Auto-empty the bin at snapshot/quit.** Deferred, not rejected: it changes recoverability
  expectations and `doGC` has an on-screen precondition. Revisit only after the Bin has been
  lived-with (add a BACKLOG line at arc close if the owner wants it).

---

## §7 Verification protocol

Everything through the umbrella wrapper, absolute path, backgrounded for long ops:

- Inner loop per phase: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (~3.5 min).
- Serialization rigs directly (fast, sharpest for this arc):
  `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/serialization-roundtrip-headless.js`
  then `node scripts/serialization-file-roundtrip-headless.js` (needs a FRESH `fg build`).
- Phase-close / commit points: `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet`
  (~4.5–5 min, 12 legs incl. both rigs, revisits, census; `run_in_background: true`, read
  `/tmp/fg-gauntlet.verdict`). A leg failing then passing its serial retry = load-flake
  (loud warning, exit 0); `[shard N] did not start within 90s` / `CoffeeScript is not
  defined` = boot-storm infra flake, not code.
- Recaptures: `/Users/davidedellacasa/code/Fizzygum-all/fg recapture --auto` on a FRESH
  build only (stale build ⇒ false "zero recaptures"); it re-runs the full suite at each dpr
  and prints COMPLETE/INCOMPLETE.
- Manual eyeball (owner or session): build, open
  `Fizzygum-builds/latest/index.html`, exercise: open/dismiss menus → open Bin → must be
  empty; close an unsaved doc → appears in Bin; save-on-close a doc → does NOT appear;
  delete the doc's shortcut → doc appears; Empty bin → gone; templates button + degrees
  converter close/reopen cycles.

---

## §8 References

- This plan's study: session 2026-07-22 (owner brainstorm "We need to talk about the
  basement"). Key evidentiary sites are all cited inline in §1.
- `docs/architecture/serialization-duplication-reference.md` — snapshot roots/filters.
- `docs/archive/INDEX.md` ⚖ bullets: §7.5 island-figure re-homing case law (close must
  re-home/destroy the FIGURE); serialization-damage-bookkeeping arc (2026-07-22).
- Memory notes (umbrella memory dir): `no-serialization-compat-obligations`,
  `serialization-damage-bookkeeping-fix`, `typewriter-size-aware-experiment` (bin icon),
  `ask-before-commit-push`, `owner-workflow-long-arcs` (one end-of-arc review),
  `dont-let-recapture-churn-dictate-design`.
- Comment rubric: umbrella `.claude/comment-rubric.md` (present-tense comments; no
  "used to/no longer" phrasing — enforced by the comment-stink gate).
