# Menu subject routing — how a menu-dispatched verb learns WHICH widget it acts on

**STATUS: AUTHORED, not started.** Two findings from the menu-action arc
([`../archive/menu-action-wiring-plan.md`](../archive/menu-action-wiring-plan.md)), left open there
on purpose because each needs a small design decision rather than a typo fix. Both are the SAME
question wearing two hats: *a verb wired to a menu needs to know which widget it is about, and the
dispatcher does not reliably tell it.*

**Neither is a crash.** P1 is two dead menu items; P2 is latent — today it changes no behaviour, and
it is in this plan because it is the exact shape that made `createOpener` crash.

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
