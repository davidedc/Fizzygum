# PLAN — the object inspector on a subject it cannot EDIT (a read-only inspector)

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**

**Mandate:** eliminate the problem, not bury it — an inspector opened on a value it cannot edit
must present a coherent read-only inspector, not a set of controls that throw when clicked.
Churn, screenshot recaptures and legacy support are explicitly NOT constraints (owner direction).

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework rendered on one HTML5 canvas; `InspectorWdgt`
(`src/meta-tools/`, the lazy `meta-tools` part) is its Smalltalk-style object inspector.

**The immediately prior arc (2026-08-21, CLOSED):** an audit retired `world.evaluateString` from
the SystemTest suite and, in reading the mechanism, found `Widget.evaluateString` was DISCARDING
the value it evaluated — `result = eval JSCode` was assigned and never read, so the method
returned its trailing `@_changed()`. Fixed (Fizzygum `efe40f2e`). That made the evaluation menu's
**"inspect selection"** reach `spawnInspector` with a REAL value for the first time, which
immediately threw `TypeError: this.inspectedObject.colloquialName is not a function` for a number,
a string or a Point.

**Phase 1 of the fix is DONE and pushed** (this plan is only what is left): naming became a service
(`Utils.derivedColloquialName` / `Utils.colloquialNameOf`), `Widget.colloquialName` keeps the
derivation as its base answer with all ~50 overrides untouched, and `InspectorWdgt.colloquialName`
asks the service. An inspector now OPENS on any value.

**⭐ THE CRITICAL REFRAME, and it is what makes this plan small:** the inspector's DISPLAY half is
already generic and needs nothing. Measured, not assumed — the census below. What remains is
exactly one thing: the four EDIT controls are offered on subjects that cannot service them.

---

## §1 Measured state (2026-08-21 — re-verify before trusting, but do not re-derive)

### What `InspectorWdgt` demands of its subject

Census over `src/meta-tools/*.coffee` (`grep -o '@inspectedObject[?]*\.\w*' | sort | uniq -c`):

| member | sites | on a primitive |
|---|---|---|
| `constructor` | 13 | ✅ `(42).constructor` is `Number` |
| `__proto__` | 1 | ✅ |
| `hasOwnProperty` | 1 | ✅ |
| `colloquialName` | 1 | ✅ **since Phase 1** (asks `Utils.colloquialNameOf`) |
| `injectProperty` · `removeOwnProperty` · `renameOwnProperty` · `sourceChanged` | 4 | ❌ **this plan** |

### What actually happens today

Driven by `Fizzygum-tests/.scratch/b-inspector-on-nonwidget-probe.js` (re-runnable):

| subject | title | member-list rows | the four verbs | edit path |
|---|---|---|---|---|
| `42` | `Object Inspector (number)` | 20 | all `undefined` | **throws** |
| `"hello"` | `Object Inspector (string)` | 29 | all `undefined` | **throws** |
| `new Point 3, 4` | `Object Inspector (point)` | 50 | all `undefined` | **throws** |
| a `RectangleWdgt` | `Object Inspector (rectangle)` | 19 | all `function` | OK |

⇒ **display and the member list are DONE.** There is no work in them. The only defect left is that
"add…", "rename…", "remove" and "save" are offered to a subject that cannot service them, and
`TypeError: subject.injectProperty is not a function` is what a click gets.

---

## §2 The decision, and why

An inspector has two separable concerns:

- **DISPLAY** — what is this thing, what are its members. Generic; works on any value.
- **EDIT** — change/add/remove a member. A PROTOCOL the subject must implement, and one a number
  genuinely cannot: you cannot inject a property into `42`.

So *a read-only inspector is not a degraded inspector — it is the honest one* for a subject that
does not implement the protocol. That framing is the plan; everything below follows from it.

**Decision A — OMIT the edit controls rather than disable them.** (Owner-approved direction.)
Precedent in this codebase: `WorldWdgt.createDesktop` asks `world.parts.canEverProvideClass` before
drawing each app icon, on the stated reasoning that *an icon whose click could only reject is worse
than no icon*. Same argument, same answer.

**Decision B — ONE capability query, not four.** The four verbs always co-occur (they are all
`Widget` members and arrive together). Probe the concept once and name it for the concept:

```coffee
subjectIsEditable: ->
  @inspectedObject.injectProperty?
```

A capability query, which this codebase prefers over `instanceof` (see the `instanceof-type-test`
stink and `docs/architecture/widget-authoring-guidelines.md`). ⚠ Do NOT probe `instanceof Widget`:
the question is "does it service the edit protocol", and a future non-widget that implements the
four verbs should get an editable inspector.

---

## §3 ⚠⚠ THE HARD PART — the edit row is LOAD-BEARING IN THE LAYOUT

This is the whole reason this is a plan and not a two-line change, and it is easy to miss because
the buttons are built in one tidy block that looks independent.

**The buttons are built contiguously** (`InspectorWdgt`, ~:264–273 — line numbers ROT, grep
`addPropertyButton` and trust the symbol):

```coffee
@addPropertyButton    = new SimpleButtonWdgt @, "addPropertyPopout",    face: "add..."
@renamePropertyButton = new SimpleButtonWdgt @, "renamePropertyPopout", face: "rename..."
@removePropertyButton = new SimpleButtonWdgt @, "removeProperty",       face: "remove"
@saveTextWdgt         = (new StringWdgt "save", …).alignCenter()
@saveButton           = new SimpleButtonWdgt @, "save", face: @saveTextWdgt
```

**…but the layout CHAINS them** (`InspectorWdgt._reLayout`, ~:587–599): each is positioned from
the previous one's `right()` —
`@addPropertyButton._reLayout …` → `@addPropertyButton.right() + @internalPadding` →
`@renamePropertyButton` → `@renamePropertyButton.right()` → `@removePropertyButton` → … →
`@saveButton`.

**…and a SUBCLASS reaches across the row** (`ClassInspectorWdgt`, ~:56–58): it places its own
widget in the gap, reading `@removePropertyButton.right()` and `@saveButton.left()`.

⇒ **Simply not building them null-derefs `_reLayout` and breaks `ClassInspectorWdgt`.** Treat the
edit row as ONE UNIT — built, laid out, and reached-into — and make the whole unit conditional.

**⚠ Check first, do not assume:** is a `ClassInspectorWdgt`'s subject ALWAYS editable? Its subject
is a class, and the meta-system (`src/meta/Class.coffee`) gives classes the edit verbs. If always
editable, its layout code needs no guard and only `InspectorWdgt` branches. **Verify by probing a
real `ClassInspectorWdgt` subject for `injectProperty?` before writing any guard** — if it is
always true, do NOT add a defensive branch there (dead code the dead-method gate will flag).

---

## §4 Fix shape

1. `InspectorWdgt.subjectIsEditable()` as in §2.
2. Extract the edit row into its own build step (`_buildAndConnectEditRow…`, matching the
   `_buildAndConnectObjOwnPropsButton` sibling right above it) and call it only when editable.
3. Guard the matching `_reLayout` span with the same query, so nothing derefs a button that was
   never built. Keep the two guards spelled with the SAME query — a second spelling is a fact
   stated twice, and two facts will disagree.
4. Re-check `ClassInspectorWdgt` per §3's warning.
5. The read-only inspector's bottom row is then empty; decide whether the list should claim the
   freed height or the window simply be shorter. **Look at it before choosing** — this is a pixel
   decision, not an argument.

---

## §5 Verification protocol

- `/Users/davidedellacasa/code/Fizzygum-all/fg build` — the 27 static gates.
- **Promote the probe:** `Fizzygum-tests/.scratch/b-inspector-on-nonwidget-probe.js` already asks
  the right questions. Turn it into an assertion-only SystemTest (no reference images, so it cannot
  become a pixel flake) asserting: an inspector OPENS on `42` / `"hello"` / a `Point` / a widget;
  its title names the KIND; the member list is non-empty; and the edit controls are **absent** on
  the first three and **present** on the widget. That last pair is the whole claim — assert both
  halves or it passes for the wrong reason.
- `fg gauntlet` (18 legs) at the commit point. Inspector screenshots WILL move (a missing button
  row changes pixels); recapture with `fg recapture --auto`, which gates on completeness. Churn is
  explicitly not a constraint here.
- ⚠ `fg menusweep` drives `addPropertyPopout`/`renamePropertyPopout` from a dedicated section
  (they hang off buttons no menu walk reaches). Confirm that section still finds them on an
  EDITABLE fixture and does not now report them missing.

---

## §6 Rejected alternatives (do not re-attempt)

- **Make `InspectorWdgt` tolerant with `?.` at each edit site.** Rejected: it makes the controls
  silently do nothing, which is the same class of defect as the pin-contract bug the house already
  fixed (`fg pinsweep` exists because a `PinSpec` naming a missing setter accepts a wire and
  silently does nothing forever). A control that cannot work should not be offered.
- **Extract `colloquialName` into a service and delete the method** (the obvious Phase 1 move).
  Rejected on measurement: ~50 classes override it, several answering what only that object knows —
  `TransformFrameWdgt` returns its sole content's name, `ShortcutWdgt` its referent's,
  `FrameWdgt`/`ConsoleWdgt` compose one. The polymorphism is load-bearing. Phase 1 shipped the
  two-function split instead (derive-only base + ask-then-derive service).
- **Probe `instanceof Widget` for editability.** Rejected: see §2 Decision B.

---

## §7 References

- `docs/architecture/lint-and-static-checks.md` — the 27 build gates (incl. #27, added by the prior arc).
- `docs/architecture/widget-authoring-guidelines.md` — capability queries vs type tests.
- Memory: `evalstring-audit-and-eval-discipline-gate` — the prior arc, its census, and the ~50-override trap.
- Probes (gitignored, expendable, re-runnable):
  `Fizzygum-tests/.scratch/b-inspector-on-nonwidget-probe.js` (sizes this plan),
  `Fizzygum-tests/.scratch/a1-evaluation-menu-consumers-probe.js` (drives the two evaluation-menu rows end to end).
