# Menu-action wiring — the four-slot convention, and the four live bugs it hid

> **ARCHIVED 2026-08-16 — COMPLETE, authored and executed the same day.** A short successor to
> [`constructor-parameter-conformance-plan.md`](constructor-parameter-conformance-plan.md), which
> closed with the observation that ONE menu item had shaped six `createReference` signatures. This
> arc asked the obvious next question — *how many other verbs are wired straight at a menu?* — and
> found four live user-facing bugs. The standing mechanism is `buildSystem/check-menu-actions.js`;
> the law it serves is
> [`../architecture/constructor-and-parameter-conventions.md`](../architecture/constructor-and-parameter-conventions.md).

## 0. The convention, and why it goes wrong silently

`ButtonWdgt` dispatches every menu action through a **fixed four-slot** call:

```coffee
@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, @argumentToAction1, @argumentToAction2
```

and for an ordinary menu (`MenuRowsPanelWdgt.createMenuItem`, no environment) the slots are:

| slot | what it actually holds |
|---|---|
| 1 | **the MenuItemWdgt itself** |
| 2 | the widget the menu is about (the panel's `@target`) |
| 3–4 | `arg1` / `arg2`, usually absent |

**Nothing at the call site says any of this.** `menu.addMenuItem "label", target, "verb"` names none
of the four arguments `verb` is about to receive. That single fact produces every defect below.

⚠ And the failures are *quiet*: a menu action only runs when a human clicks it. The SystemTest suite
drives menus heavily, but it does not click **every** item, and the ones it never clicks are exactly
where these lived. `ButtonWdgt` even carries a runtime tripwire for the worst case — which had been
firing for nobody, because nothing clicked the items that would trip it.

## 1. The four live bugs

**B1 — `SliderWdgt`'s three range prompts threw on every click.** `"floor..."`, `"ceiling..."` and
`"button size..."` passed a **function literal** as the action. The dispatch is `@target[@action]`,
so a function is coerced to a string key, finds nothing, and throws — `ButtonWdgt`'s own tripwire
says so in as many words. Proven by probe (all three `THROWS`, the sibling `"show value"` with its
string action `NO THROW`), and fixed by naming them: `promptForFloor` / `promptForCeiling` /
`promptForButtonSize`, each reading the menu title from slot 1 exactly as `Widget.transparencyPopout`
already did. ⭐ The closures captured `menu.title`; `menuItem.parent.title` was verified by probe to
be the identical string before the conversion, because that string is drawn.

**B2 — the three demo "…launcher" menu items crashed.**
`menu.addMenuItem "document launcher", (new SimpleDocumentApp), "createOpener"` reaches
`createOpener: (inWhichFolder)`, so `inWhichFolder` received a **MenuItemWdgt** — which passes
`inWhichFolder?` and then runs `inWhichFolder.contents.contents.add`, and a `MenuItemWdgt` has no
`contents` (its chain is `LabelButtonWdgt → ButtonWdgt → Widget`, none of which declares one).
A/B-proven on the real menu: with the old signature all three items throw
`Cannot read properties of undefined (reading 'contents')` and place nothing; with the fix all three
click clean and place three launchers.

⭐ **The fix was to DELETE the parameter, not to add an adapter** — because the in-folder arm turned
out to have **no caller in either repo**, and to duplicate
`IconicDesktopSystemWindowedAppLauncherWdgt.addToFolder`, whose own comment records that it was
"lifted verbatim from `IconicDesktopSystemWindowedApp.createOpener`'s two arms". So the crashing
parameter was dead code. `createOpener: ->` now takes nothing, and **a verb that takes nothing cannot
be mis-fed by the dispatcher** — which is a better outcome than an adapter, and worth reaching for
first.

**B3/B4 — thirteen verbs padded with unread slots.** `showOutputPins: (a,b,c,d) ->
world.pinouts?.show b` is the type specimen. ⭐⭐ **The padding was routing the RECEIVER back in as an
argument**: the menu wires these onto the very widget being pinouted, so slot 2 *is* `@`, and the
whole four-slot signature existed to receive it. `showOutputPins: -> world.pinouts?.show @` says the
same thing and is un-mis-callable. The padding was not cosmetic — it is what made the one macro
caller write `w.showOutputPins undefined, w`, i.e. two of the tests repo's argument holes.

## 2. What landed

| verb | before | after |
|---|---|---|
| `Widget.showOutputPins` / `removeOutputPins` | `(a,b,c,d)` reading only `b` | `->` reading `@` |
| `IconicDesktopSystemWindowedApp.createOpener` | `(inWhichFolder)` — **crashed** | `->` (dead arm deleted) |
| `SliderWdgt` × 3 range prompts | function literals — **threw** | `promptFor…` named methods |
| `DemoMenus.makeFolderWindow` | `(a,b,c,d,e)` reading none | `->` |
| `WorldWdgt.popUpDemoMenu` | `(widgetOpeningThePopUp,b,c,d)` | `(widgetOpeningThePopUp)` |
| `FrameWdgt.dockToolbarMenu` | `(…, targetWidget, a, b, c)` | `(widgetOpeningThePopUp, targetWidget)` |
| `VerticalStackLayoutSpec` / `DivisionStackLayoutSpec` × 6 | `(menuItem,a,b,c,d,e,f)` etc. | trailing padding dropped |
| `StringWdgt.fontsMenu`, `Wallpaper.wallpapersMenu` | `(a, targetWidget)` | `(ignored, targetWidget)` |

⚠ **The last row is the distinction that matters.** A *trailing* unread slot can simply be dropped —
the dispatcher's extra arguments fall away harmlessly. A *leading* one cannot: dropping `a` from
`(a, targetWidget)` slides `targetWidget` into slot 1 and silently retargets the menu. So it stays,
**named for what it is**. That asymmetry is the whole content of the gate's rule 3.

## 3. The gate — `buildSystem/check-menu-actions.js`

Runs on the build beside `check-argument-holes.js`, and reuses `lib/coffee-method-header.js` rather
than growing a seventh copy of the method-header regex (the blind-spot lesson from the predecessor
arc: *a gate blind to a method reports nothing*).

- **Rule 1 (HARD, sound):** a function literal in the action slot.
- **Rule 2 (HARD, sound):** a string literal where the options object goes.
- **Rule 3 (ratchet at 0):** an unread parameter on a menu-dispatched verb that is not *named*
  unread (`ignored` / `ignored2` / `unused` — the spelling `PanelWdgt.makeFolderFromMenu` and
  `StringWdgt.setFontNameFromMenu` already use).

**Proven to FAIL, not merely to pass** — a planted `zzz` parameter and a planted function literal
each abort the real build (exit 1), and both return green on revert. 255 menu-dispatched verbs, 0
violations.

## 4. ⚠ The residual — what this gate CANNOT catch

**Rule 3 would not have caught B2.** `createOpener`'s `inWhichFolder` *was* read; it was read as the
wrong THING. No text scan can see that a parameter holding a `MenuItemWdgt` is being asked for its
`.contents`. The mechanism that catches that class is **a rig that CLICKS every menu item** — the
demo menus in particular, which nothing exercises today and which is where both crash-class bugs
lived.

→ **BACKLOG**: a `menu-click-sweep` rig (open each menu, click each item, fail on a throw or a
console error). It is the natural sibling of `apps` and `parts` in the gauntlet's wave A. Not built
here because it is a test-infrastructure arc rather than a wiring one, and because the two known
crashes are now fixed and gated at the shapes that a scan *can* see.

## 5. Verification

Gauntlet 14/14. Every conversion is pixel-free by construction (no drawn string changes — the one
that could have, `menuItem.parent.title`, was probe-verified identical first). Two argument holes
disappear from the tests repo as a side effect, since the macro no longer has to write
`w.showOutputPins undefined, w`.
