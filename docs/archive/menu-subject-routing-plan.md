> **ARCHIVED — COMPLETE (2026-08-16).** P1 landed as shape (a); P2 landed as the two adapters —
> the two menu-dispatch findings left open by `menu-action-wiring-plan.md` about how a
> menu-dispatched verb learns which widget it acts on.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Menu subject routing — how a menu-dispatched verb learns WHICH widget it acts on

**STATUS: COMPLETE (2026-08-16). P1 landed as shape (a); P2 landed as the two adapters.** Two
findings from the menu-action arc
([`../archive/menu-action-wiring-plan.md`](../archive/menu-action-wiring-plan.md)), left open there
on purpose because each needs a small design decision rather than a typo fix. Both are the SAME
question wearing two hats: *a verb wired to a menu needs to know which widget it is about, and the
dispatcher does not reliably tell it.*

**Neither was a crash.** P1 was two dead menu items; P2 is latent — it changes no behaviour, and it
is in this plan because it is the exact shape that made `createOpener` crash.

**As-built, and the three things worth carrying forward** (§5 has the detail):

1. **The dispatcher fact is CONDITIONAL, and the plan below states only half of it.** Slot 1 = the
   `MenuItemWdgt` and slot 2 = the panel's target **only when the panel carries no `environment`**;
   with one, slot 1 is the panel target and slot 2 is that environment. Both branches read the
   panel's `@target` — which has exactly two readers tree-wide, both inside `createMenuItem`.
2. **P1's shape (a) was verified, not assumed**, and the verification is what made it safe: every
   other row of `popUpSecondMenu`'s menu takes `(widgetOpeningThePopUp)` only, so only
   `popUpDevToolsMenu` can see slot 2 change. The result is structurally identical to the site that
   already worked, Widget's own "dev ➜".
3. ⚠⚠ **The sweep's DISTINCT count is not a ratchet** — it fell 519 → 515 on a change that fixed a
   bug and lost no reach. See §5.2: one action enumerates the world's current widget population.

---

## 0. The one fact both items rest on

`ButtonWdgt` dispatches every menu action through a **fixed four-slot** call
(`src/ButtonWdgt.coffee:118`):

```coffee
@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, @argumentToAction1, @argumentToAction2
```

and `MenuRowsPanelWdgt.createMenuItem` (`src/basic-widgets/menu-system/MenuRowsPanelWdgt.coffee:151`)
fills those slots, for an ordinary menu with no environment, as:

| slot | holds |
|---|---|
| 1 | **the `MenuItemWdgt` itself** |
| 2 | **the PANEL's `@target`** — i.e. the widget the *enclosing menu* was built about, NOT the item's own target |
| 3–4 | `arg1` / `arg2` |

⚠ **Slot 2 is the panel's target, not the item's.** That is the whole subtlety: a verb reading slot 2
gets the right widget only when the menu it sits in was built *about* that widget. Reached from a
menu built about something else, it silently gets that something else.

Verify before starting — it is 3 lines and the plan depends on it:

```
sed -n '112,120p' src/ButtonWdgt.coffee
sed -n '148,162p' src/basic-widgets/menu-system/MenuRowsPanelWdgt.coffee
```

## 1. P1 — "dev tools ➜ > inspect" and "> console" are dead

**Symptom.** Both items do nothing. Recorded live by
`Fizzygum-tests/scripts/menu-click-sweep-headless.js` as
`UNRESOLVED_ACTION inspect` / `UNRESOLVED_ACTION createConsole`, and currently sitting in that rig's
`KNOWN` allowlist — **the two entries there are the acceptance test for this phase: delete them and
the sweep must stay green.**

**Diagnosis.** `MenusHelper.popUpDevToolsMenu` (`MenusHelper.coffee:13`) takes its subject from
slot 2:

```coffee
popUpDevToolsMenu: (widgetOpeningThePopUp, widgetThisMenuIsAbout) ->
  menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Dev Tools"
  menu.addMenuItem "inspect", widgetThisMenuIsAbout, "inspect", …
  menu.addMenuItem "console", widgetThisMenuIsAbout, "createConsole", …
```

It has **two wiring sites** that disagree:

| site | enclosing menu's panel target | ⇒ slot 2 | works? |
|---|---|---|---|
| `Widget.coffee:4270` `"dev ➜"` (a widget's own context menu) | the widget | the widget | ✅ |
| `DemoMenus.coffee:760` `"dev tools ➜"` (inside `popUpSecondMenu`) | `@` = `demoMenus` | `demoMenus` | ❌ dead |

And the reason the second is wrong is one signature:

```coffee
DemoMenus.coffee:731   popUpFirstMenu:  (widgetOpeningThePopUp, widgetThisMenuIsAbout) ->
DemoMenus.coffee:751   popUpSecondMenu: (widgetOpeningThePopUp) ->                        # ← drops it
```

Both are wired identically from `testMenu` (`:725` / `:726`), so **both RECEIVE the widget in slot 2;
only `popUpSecondMenu` throws it away.** Its sibling then hands it to items that need it
(`:734 menu.addMenuItem "make pointer", widgetThisMenuIsAbout, "createPointerWdgt"`).

**⚖ The decision, and why it is not a one-liner.** Simply adding the parameter to `popUpSecondMenu`
is not enough: its menu is built `target: @`, so slot 2 for ITS items stays `demoMenus`. Three
shapes, pick one:

- **(a) Build that menu about the widget** — `new MenuWdgt widgetOpeningThePopUp, target: widgetThisMenuIsAbout`.
  Smallest diff. ⚠ Changes slot 2 for **every** item in that menu, so first confirm nothing else there
  reads it: the other items are `popUp*Menu` handlers that take `(widgetOpeningThePopUp)` only, which
  makes this safe — **verify, do not assume.** Note `popUpFirstMenu` keeps `target: @` and works
  because it routes the widget per-item instead.
- **(b) Route per item, the sibling's idiom** — give the dev-tools row the widget some other way.
  ⚠ It cannot be the item's own target (that must stay `menusHelper`, which owns the verb), and
  `arg1` would make `popUpDevToolsMenu` read a third slot — the padding smell the predecessor arc
  removed. Least attractive.
- **(c) Make the subject explicit on the verb** — `popUpDevToolsMenu` stops reading slot 2 and takes
  the widget as a real operand, with the two call sites passing it. Most honest, biggest blast radius.

**Recommendation: (a)**, after verifying the other items ignore slot 2. It is the smallest change
that makes the dispatcher tell the truth, and it leaves `popUpDevToolsMenu`'s contract alone.

## 2. P2 — the edit-mode family receives a `MenuItemWdgt` as `triggeringWidget`

**⚠ LATENT, NOT LIVE. Do not describe this as a bug fix.** Today it changes no behaviour, and that
must be stated in the commit message, because someone will otherwise read the diff as a repair.

**The mechanism.** `BubblesEditModeToCoordinatorMixin` (`src/mixins/BubblesEditModeToCoordinatorMixin.coffee:26,36`):

```coffee
_enableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
  if !triggeringWidget? then triggeringWidget = @          # ← the intended fallback
  …
  if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
```

`triggeringWidget` exists to stop the edit-mode change bubbling back to whoever triggered it. Two
entry points supply it:

- `Widget.editButtonPressedFromFrameBar` (`Widget.coffee:559,561`) — `@disableDragsDropsAndEditing @`.
  **A real widget. This is the meaningful use, and it must keep working.**
- The menu (`Widget.coffee:571,573`, from `_addEditingLockMenuEntries`) — slot 1 arrives, so
  `triggeringWidget` is **the `MenuItemWdgt`**, and `!triggeringWidget?` never fires.

**Why it is harmless today:** the only use is `@parent != triggeringWidget`, and neither a menu item
nor `@` is ever `@parent`, so both spellings take the same branch. **Why fix it anyway:** the guard
is now permanently disarmed on the menu path, and the next person to read `triggeringWidget` as a
real widget gets `createOpener`'s crash. The value should be what the code says it is.

**The fix** is the shape this codebase already settled on — split the adapter from the verb:

```coffee
enableDragsDropsAndEditingFromMenu: -> @enableDragsDropsAndEditing()
disableDragsDropsAndEditingFromMenu: -> @disableDragsDropsAndEditing()
```

point `_addEditingLockMenuEntries` at those, and the `!triggeringWidget?` default fires as designed.

⚠ **Put the adapters on `Widget`** (beside `createReferenceFromMenu`), not on the four overriders —
the base's public verb takes no parameter (`Widget.coffee:4494`) while `FrameWdgt:950`,
`ScrollPanelWdgt:858`, `StretchablePanelWdgt:92`, `StretchableWidgetContainerWdgt:249` each take
`(triggeringWidget)`, so a no-argument call is correct for all five.

⚠ **Do NOT delete the `triggeringWidget` parameter from those four overrides.**
`editButtonPressedFromFrameBar` genuinely passes one.

## 3. Order, and the standing hazards

**P1 then P2** — independent, but P1 has a live symptom and a ready-made acceptance test.

- ⚠⚠ **"I checked the callers" is HALF a sweep** — a signature is owned by its call sites AND its
  `super` sites. `grep -rn "extends <Class>\b" src/`, then RECURSE. This arc's predecessor broke the
  Drawings Maker twice this way.
- ⚠ **Sweep BOTH repos.** A macro is CoffeeScript inside a JS template literal in
  `Fizzygum-tests/tests/**/*_automationCommands.js`; grep by NAME, never by file extension.
- ⚠ **Adding a method to `Widget`'s prototype churns the inspector member list.** P2 adds two, so
  expect `macroDuplicatedInspectorDrivesCopiedTargetOnly` to move — it is the one inspector test that
  SCROLLS its list to a named member. That is benign churn under the owner's standing grant, but
  **prove it by A/B** (remove only the new members, confirm the test passes) before recapturing, and
  use the gated `fg recapture`.
- ⚠ `check-menu-actions.js` runs on the build: an unread parameter on a menu-dispatched verb must be
  NAMED `ignored`/`unused`, and an action must be a string. Both fixes stay inside those rules.

## 4. Verification

`fg presuite` while iterating; **`fg gauntlet` before proposing a commit** — it now carries the
`menusweep` leg, which is P1's acceptance test.

**P1 is done when both `UNRESOLVED_ACTION` entries are DELETED from the rig's `KNOWN` map and the
sweep is still green.** Leaving them in place while "fixing" the cause would hide a regression, so
the deletion is part of the change, not a follow-up.

P2 should be **behaviour-free**: same branch taken either way. Any reference churn beyond the
inspector member-list row means something else moved — find it before recapturing.

---

## 5. As built

### 5.1 What landed

**P1 — shape (a).** `DemoMenus.popUpSecondMenu` takes `(widgetOpeningThePopUp, widgetThisMenuIsAbout)`
and builds its menu `target: widgetThisMenuIsAbout`. Both `UNRESOLVED_ACTION` entries are gone from
`menu-click-sweep-headless.js`'s `KNOWN` map and the sweep is green (5 allowlisted causes → 3), so
"> inspect" and "> console" now RESOLVE and DISPATCH rather than being tolerated.

The precondition the plan demanded be verified rather than assumed, was:

| checked | result |
|---|---|
| every other row of that menu | takes `(widgetOpeningThePopUp)` only — none can observe slot 2 |
| readers of a menu panel's `@target` | exactly two, both in `MenuRowsPanelWdgt.createMenuItem`; `MenuItemWdgt`'s `@target` is the ROW's, not the panel's |
| subclasses of `DemoMenus` / `MenusHelper` | none |
| other callers of `popUpSecondMenu` | none — it is reachable only as a menu action |
| can `widgetThisMenuIsAbout` be absent? | no: `popUpDemoTestMenu`'s two wiring sites are context menus built `target: @`, so it is the world or the widget |

⭐ A free confirmation of the static gate came out of the A/B: reverting the BODY while keeping the
parameter makes the build fail with `check-menu-actions.js: unread parameter 'widgetThisMenuIsAbout'`
— the gate does catch this bug shape, once the signature admits the parameter at all.

**P2 — the two adapters**, `enableDragsDropsAndEditingFromMenu` / `disableDragsDropsAndEditingFromMenu`
on `Widget`, with `_addEditingLockMenuEntries` pointing at them. ⚠ Still **latent**: the only reader
is `@parent != triggeringWidget`, and a menu item and `@` take the same branch. The value is now what
the parameter's name says it is. Two SystemTests drive these items by LABEL, so they were unaffected —
and `macroEditModeTogglePencilEyeGlyph` asserts `image_0 == image_2` (menu-driven enable reproduces
the click-driven pixels exactly), which is a real behavioural check on the path.

### 5.2 ⚠⚠ The sweep's DISTINCT count is coverage BREADTH, not a ratchet

The fix moved it **519 → 515** (items fired 2866 → 2796). A fix that shrinks coverage deserves
suspicion, so it was A/B'd properly — full revert, rebuild, diff the two pair sets — rather than
argued about. The entire delta is **one action**: 7 `<Class>.newParentChoiceWithHorizLayout` pairs
lost, 3 gained. `Widget._attachToChosenParent` builds **one menu row per widget currently in the
world**, each row targeting that widget, so those pairs track the world's population at that instant —
and now that `inspect`/`createConsole` actually RUN, the population differs. `menus walked` is
identical (324) and no reach was lost. The rig now says this in its report, and `--verbose` prints the
pair set so the next move can be diffed instead of debated.

### 5.3 The recapture

One test, `macroDuplicatedInspectorDrivesCopiedTargetOnly`, at both densities — the predicted benign
inspector churn, and the prediction was checked rather than trusted:

- **A/B**: with P1 kept and only P2's two members removed, the test PASSES. So the churn is
  attributable to the two added prototype members, and P1 is proven pixel-neutral.
- **At the pixel** (`fg diffpage`): both member lists shift by exactly one row — two more members
  make the list longer, so the same scroll fraction lands a row lower — while everything the test
  exists to assert is untouched: left inspector `alpha = 0.25`, right `alpha = 0.6`, i.e. the
  inspector still drives the COPIED target only. ⚠ `fg classify` called it REVIEW, not BENIGN?; that
  verdict is advisory and reading the pixels is what settles it.

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

The closed items this plan owned, relocated VERBATIM from `docs/BACKLOG.md` on 2026-08-18 so
that file can go back to being an index of OPEN work only (`docs/README.md` filing rule 2: an
arc's items leave BACKLOG when it closes). Nothing above this line changed; any item of this
arc still OPEN stayed in `docs/BACKLOG.md`.

### Menu-dispatch residue — left by `archive/menu-subject-routing-plan.md`
⚠⚠ **Five items were filed here at the arc's close; on verification TWO were plain wrong and a third
was wrong about its own remedy.** They are kept with their refutations rather than deleted, because a
falsified item silently removed is an item somebody re-files. The common cause of both bad ones: a
defect inferred from the four-slot dispatch fact without reading the CONSUMER — **the dispatch fact
tells you what a slot HOLDS, never whether the receiving parameter is wrong to want it.** One item
remains open (the audit-prelude tag). Law: `architecture/constructor-and-parameter-conventions.md` R3.
- ⛔ **FALSIFIED, do not re-open: `widgetOpeningThePopUp` is NOT a misnomer.** It was filed as one on
      the reasoning that dispatch slot 1 holds a `MenuItemWdgt` — but the consumer settles it the other
      way. `PopUpWdgt` uses the value for exactly one purpose,
      `getParentPopUp: -> @widgetOpeningThePopUp.firstParentThatIsAPopUp()` (`PopUpWdgt.coffee:107`,
      and menus hang off the WORLD rather than their opener, which is why the link must be stored at
      all). For a submenu opened by clicking a row, the menu item IS the widget that opened it, and its
      `firstParentThatIsAPopUp()` is the parent menu — passing "the widget the menu is about" instead
      would break the pop-up parent chain. 103 sites across 31 files, all correct. ⚠ The general
      lesson: **the dispatch fact tells you what slot 1 HOLDS, never whether the receiving parameter is
      WRONG to want it** — check the consumer before calling a name a defect.
- ✅ **DONE (2026-08-16): `triggeringWidget` now exists only where it is read.** It was declared in TEN
      members across FOUR classes and read in exactly ONE place —
      `BubblesEditModeToCoordinatorMixin`'s `@parent != triggeringWidget`, which is the CORE of the two
      Stretchables and of nothing else. Dropped from `FrameWdgt`'s four members and `ScrollPanelWdgt`'s
      four (including its two dead `if !triggeringWidget? then triggeringWidget = @` lines, which
      assigned a value nothing consulted), and the mixin's `super @` became `super()` now that every
      core it can reach takes none. KEPT where live: the mixin's two cores and the four public wrappers
      on the two Stretchables that feed them — and the `@` passed DOWN to `@contents`, which is a
      different value entirely and reaches mixin-cored contents that DO read it. ⚠ The predecessor
      plan's "do NOT delete it from the four overrides, `editButtonPressedFromFrameBar` genuinely
      passes `@`" was only HALF right: the caller does pass `@`, but only a receiver whose core READS
      it can care. Suite 294/294 with no recapture — removing a parameter cannot move the inspector's
      member list, which is also the proof it changed no behaviour.
- ⛔ **FALSIFIED, do not re-open: `menusHelper.testMenuForMacros?()` is not a dead call.** The method
      lives in the TESTS repo (`Automator-and-test-harness-src/MenusHelperTestSupport.coffee:22`) and is
      installed onto `MenusHelper`'s prototype at boot; the `?` soak is the deliberate part-absence
      idiom that makes F2 inert in a build shipping no harness, and the call site says so. ⚠ Filed from
      a `Fizzygum/src`-only grep — the "sweep BOTH repos" rule exists for exactly this.
- ✅ **DONE (2026-08-16), with a stated limit.** The layout-audit prelude tagged
      `Widget.prototype.disableDragsDropsAndEditing`, which all four containers OVERRIDE — and
      `tagWrap` assigns `proto[name]`, so an instance resolved its own override and the wrapper could
      never run. The four overriders are now tagged too. ⚠ **Verified structurally, NOT observably:**
      both SystemTests that drive a container's edit-mode toggle
      (`macroLockedDocumentRejectsDrop`, `macroEditModeTogglePencilEyeGlyph`) produce
      `recs=0` — zero end-of-cycle records — so there is currently nothing on that path to attribute,
      which is the HEALTHY state (it self-settles). The fix costs nothing and removes a blind spot:
      the moment such a record does appear it lands on its trigger instead of in the untagged
      residual, which the survey reads as "Phase-S missed it". ⚠ Safe to change because this prelude
      feeds only the MANUAL survey (`run-audit-loop.sh` / `aggregate-layout-audit.js`) — no gauntlet
      leg and no committed baseline consumes it.
- ✅ **DONE (2026-08-16): stale dead-method allowlist entry removed.** `identifyBlockEnd` sat in
      `buildSystem/dead-method-allowlist.txt` naming a method the conformance arc had already deleted,
      so every build printed `[dead-methods] NOTE — 1 allowlist entry is no longer dead`. ⚠ Worth
      knowing why it was hard to find: the allowlist is a **`.txt`**, so a `--include='*.js'
      --include='*.coffee'` sweep sees nothing and the name looks like it exists nowhere at all.
- ✅ **DONE (2026-08-16): the five `[H] early-return-before-settle` layering warnings are sanctioned,
      not restructured.** Each was read and each guard turned out to belong exactly where it is:
      `StorageSorter.drainPendingSort` runs from `doOneCycle` EVERY cycle and the guard's whole job is
      to stay dark-cheap when nothing is pending; `WorldWdgt.loadWorldSnapshot`'s guards are a format
      check, a user confirm that may decline, and a lazy-part branch that RE-ENTERS the public method
      — none can live in a core that runs only after the teardown they exist to prevent;
      `SimpleSpreadsheetWdgt.startEditAtPointer` guards an address that resolves to no cell on a
      pointer path; `acceptCellEdit`/`cancelCellEdit` are ESCALATION handlers whose documented no-op
      case must not open a settle. All five carry `# early-return-sanctioned: <why>`; the gate is now
      silent with 0 violations. ⭐ A non-fatal warning class can be entirely legitimate — the value of
      [H] was making someone read the five, not that any needed moving.
- ✅ **DONE (2026-08-16), but NOT as filed — and the difference is the point.** Filed as "`fg classify`
      cannot recognise a list SCROLLED by N rows, teach it that shape". ⛔ **That request is wrong and
      must not be re-attempted:** the `BENIGN?(row-shift)` path already exists, and `classify-diff.js`'s
      own MEASURED RECALL header records (probed 2026-07-14, real data, both column edges swept) that
      the real inspector artifact provably does NOT fit it — adding a member makes the list TALLER, so
      the scroll moves by LESS than one row, no whole row cleanly inserts or drops, the re-clipped
      edges show new glyph fragments and the moved selection re-renders interior rows. Making it call
      that BENIGN would invert the tool's founding safety asymmetry (a false REVIEW costs a minute; a
      false BENIGN bakes a regression into the references). **What was actually wrong, and is now
      fixed:** the `INSPECTOR_CHURN_SET` corroboration fired only on the BENIGN path, while real
      inspector churn lands on REVIEW — so the tool knew the test was a member-list renderer and never
      said so. REVIEW now carries that corroboration plus the raw hunk composition, changing NO
      verdict, pinned by four new `classify-diff-selftest.js` checks (the last of which asserts the
      verdict is unchanged — decoration must never move the ship gate).
