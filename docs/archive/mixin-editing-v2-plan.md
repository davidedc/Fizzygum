> **ARCHIVED — EXECUTED IN FULL (2026-07-26).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Mixin editing v2 — plan (authored 2026-07-26; owner-approved scope: all 5 points)

> **Status: EXECUTED IN FULL + CLOSED 2026-07-26** — all 5 points (P1–P5) plus the
> closing SystemTest (`SystemTest_macroMixinEditDonorAndOverride`) landed the same day
> the plan was authored; full gauntlet green (13 legs), 35-check functional probe
> green, the P2 donor-label churn (3 tests) recaptured via the gated recapture.
> One residual banked: FIELD-parity for donor attribution (see "Residual discovered
> during T" + `docs/BACKLOG.md`). As-built truth: `docs/architecture/mixins.md` §2 and
> `docs/architecture/serialization-duplication-reference.md` §12.
>
> Original status box: ACTIVE, not started. Self-contained: executable cold with zero
> session context. Prerequisite state (ALL PUSHED 2026-07-26): the 5 misfiled mixins
> folded (`194e252d`), DeepCopierMixin → `Duplicator` engine (`a70efe23`), and mixin
> editing **v1** (`8fc41920`). Read `docs/architecture/mixins.md` §2 ("meta-system
> status") and `docs/architecture/serialization-duplication-reference.md` §12 (three
> edit scopes) BEFORE starting — they describe the as-built v1 this plan extends.

## 0. The v1 baseline (what already works, and where)

- 7 mixins remain (`src/mixins/`), all genuine-MI; inventory in `mixins.md` §3.
- **View + edit attribution**: `InspectorWdgt._mixinProvidingMember(theClass, selected)`
  finds the donor Mixin; `selectionFromList` shows its
  `nonStaticPropertiesSources[selected]` and remembers the donor in
  `@currentPropertySourceMixin` (nil when the source came from instance/class chain).
- **Donor editing**: `ClassInspectorWdgt.applyPropertyEdit` routes a mixin-attributed
  member to `Mixin.applyMemberEdit(name, source)` (`src/meta/Mixin.coffee`), which:
  updates `nonStaticPropertiesSources` (the store the view reads), rejects `/super\(/`
  with a message, compiles `"window.__fzEditedMixinMember = " + @_equivalentforSuper(source)`
  via `compileFGCode` + `_removeHelperFunctions` + `eval.call window`, restores the
  function's `.name` via `Object.defineProperty` (the fake-super companion lookup keys
  off `arguments.callee.name`), then re-injects into every consumer class EXCEPT those
  whose `theClass.class.nonStaticPropertiesSources[memberName]` exists (the SHADOW
  GUARD — class body won at boot and keeps winning), calling each consumer's
  `notifyInstancesOfSourceChange`. Returns the updated-consumer count.
- **Consumer list**: `Object::augmentWith` (`src/boot/extensions/Object-extensions.coffee`)
  records `(obj.consumerClassNames ?= []).push (fromClass or @name)` on the mixin
  LITERAL (`window.<Name>Mixin`); `consumerClassNames` is in `MixedClassKeywords`
  (`src/boot/globalFunctions.coffee`) so the class-side copy loop skips it.
  `Mixin::_consumerClassNames` reads it back via `window[@name + "Mixin"]`.
- **Persistence**: `SourceEditsRegistry` (`src/serialization/`) scope `"mixin"` records
  `{scope, mixinName, propertyName, source}`; `WorldWdgt.loadWorldSnapshot` calls
  `replayMixinEdits()` BEFORE `replayClassEdits()` (boot-order analogy).
- **Functional probe**: `Fizzygum-tests/.scratch/mixin-edit-probe.js` (gitignored) — 15
  checks; EXTEND it per phase below and keep it green. Run:
  `cd Fizzygum-tests && node .scratch/mixin-edit-probe.js` (needs a fresh build).
- Verification loop: `fg presuite` to iterate, `fg gauntlet` to close a phase; recapture
  ONLY via `fg recapture <names>` / `--auto` (gated). Long ops: background + verdict
  files, never foreground-poll (root CLAUDE.md).

## Phases (each lands + gauntlets independently; commit per phase or per pair)

### P1 — receiver-side "override in this class" gesture
When a mixin-donated member is selected in a CLASS inspector, offer an explicit second
action that creates a live class-level override (this class only) instead of editing the
donor.
- UI (owner-decided 2026-07-26): a `SimpleButtonWdgt` labelled **"override in this
  class"**, placed **left of the save button** (the bottom-right row under the detail
  pane; save layout is in `_reLayout` ~line 549), VISIBLE ONLY in `ClassInspectorWdgt`
  and only when `@currentPropertySourceMixin?` — hide/show on `selectionFromList`.
- Action: run the EXISTING class-edit body (`@target.evaluateString "@name = " + txt` +
  `_source` sibling + `recordClassEdit` + `notifyInstancesOfSourceChange`) — i.e. the
  current `applyPropertyEdit` else-branch, extracted into a named method both paths call.
  After the override, the class's prototype member no longer equals the mixin's; note
  the attribution walk still shows CLASS source only if `nonStaticPropertiesSources`
  gains the member — a LIVE override sets `<name>_source` on the prototype, which the
  `selectionFromList` FIRST branch (`@target[selected + "_source"]`) already prefers, so
  the view is correct with no further work. The shadow guard in `applyMemberEdit` keys
  off CLASS-BODY sources, NOT live overrides — v2 must ALSO skip consumers whose
  prototype carries an own `<name>_source` (add that second guard clause + probe check).
- ⚠ Pixel churn: a new button changes every CLASS-inspector reference. Find affected
  tests with `fg diffpage` after the suite run; recapture via `fg recapture --auto`.

### P2 — persistent donor label in the detail pane
Show "from <Name>Mixin" when a mixin-donated member is selected.
- Render only when `@currentPropertySourceMixin?` — so ordinary members' pixels are
  untouched. Cheapest shape: prepend a one-line header to the detail pane's TEXT? NO —
  the text is what gets saved back (fragile strip-on-save). Instead a small separate
  `StringWdgt` label above/below the detail pane, empty-string when not mixin-attributed
  (zero-size → zero churn for non-mixin selections; verify with the suite).
- Churn expectation: only tests whose references show a MIXIN member selected. Possibly
  zero; `fg diffpage` + gated recapture if any.

### P3 — add/remove mixin members from the inspector
- ADD (owner-decided 2026-07-26): `applyMemberEdit` already handles a NEW name (it
  writes `nonStaticPropertiesSources[name]` and injects — no pre-existence
  requirement). The work is UI: the class inspector's `addPropertyPopout` flow gains a
  **destination step** — "add to: <Class> / <X>Mixin / …" — shown only when the class
  has augmentations; unaugmented classes keep the single-step prompt (no new pixels).
- REMOVE: new `Mixin.removeMember(name)` — delete from `nonStaticPropertiesSources`,
  delete the prototype member + `<name>_class_injected_in` companion from every
  non-shadowing consumer (BOTH guards, as P1), notify; registry needs a deletion record
  — extend scope "mixin" records with `deleted: true` and make `replayMixinEdits`
  dispatch on it. Wire into `removeProperty` (button-action string — NEVER rename it;
  `public-private-call-separation` case law).
- Probe checks: add-new-member visible on consumers + survives replay; remove restores
  inherited/undefined and survives replay.

### P4 — mixin class-side statics: view + edit
- TODAY: `Mixin.@staticPropertiesSources` is initialized `{}` and NEVER filled — the
  parser regex (`Mixin.coffee` ctor, 6-space fields) only captures instance members
  inside the `addInstanceProperties` block. Class-side keys (2-space keys of the literal,
  copied onto consumer CONSTRUCTORS by `augmentWith`'s for-loop) are unparsed.
- Work: a second parse pass for 2-space keys (excluding `onceAddedClassProperties`);
  surface them in the inspector's statics leg (mirror how Class statics show — see
  `selectionFromList`'s non-function/static branch); `applyStaticEdit` on Mixin
  (recompile + re-copy onto consumer constructors, shadow-guarded by class-side
  `staticPropertiesSources`); registry scope reuse with `static: true`.
- NOTE: all 7 current mixins declare "class properties here: none" — build the machinery
  against a THROWAWAY test mixin in the probe (define a literal at runtime), since no
  shipped mixin exercises it. Keep it small; this is the lowest-value point — if it
  balloons, STOP and re-scope with the owner.

### P5 — `super()` / `super(args)` support in the mixin rewriter
- `Mixin._equivalentforSuper` today handles only bare `super` (EOL, comment-tolerant)
  and `super args`. Add the two missing rules MIRRORING `Class._equivalentforSuper`
  (`src/meta/Class.coffee` ~line 80: ORDER IS LOAD-BEARING — `super()` FIRST, then
  bare-super-at-EOL, then `super(`, then `super `):
  `super()` → `<mixinSuperBase>.call(this)` and `super(` → `<mixinSuperBase>.call(this, `.
- Remove the v1 `/super\(/` rejection in `applyMemberEdit`; delete the TODO in
  `Mixin.coffee`; update `mixins.md` §2 constraint bullet + §7 ledger + §8 item.
- ⚠ the rewrite rules are order-sensitive TEXT substitutions — the "thin vertical slice"
  bug class (`cbb90457`). Probe: a member using each of the 4 forms compiles and its
  super reaches the consumer's real superclass method (assert via a marker on a stub
  superclass in the probe page).
- The build-time syntax gate loads the REAL Mixin.coffee — no gate change needed.

### Residual discovered during T (out of scope, banked for a future arc)
> **ADDENDUM: executed later the same day (2026-07-26), owner-directed.** Field parity
> landed as described below: `ClassInspectorWdgt._sourceForFieldMember` (prototype-level
> truth in boot order of authority; object inspectors keep showing instance VALUES),
> `Class.applyMemberEdit` keeps `<name>_source` for every member kind, class-scope
> registry records cover fields, and the plan's ORIGINAL `color_hover` T scenario became
> implementable as `SystemTest_macroMixinFieldEditDonorAndOverride` (the field sibling).
> The closing gauntlet then surfaced two real defects, both fixed in the same batch:
> (1) mixin/class edits LEAK across suite tests — the parsed mixin store and consumer
> prototypes outlive `resetWorld`, so the field test inherited the method sibling's
> edited `mouseEnter` in-shard (passes-alone-fails-in-suite; reproduced with
> `run-sequence-headless.js`); both mixin tests now RESTORE the pristine donor source
> in their macro tail (MACRO-PATTERNS records the pattern as mandatory for any future
> editing test); (2) `Widget.evaluateString` on a PROTOTYPE receiver stamps
> widget-lifecycle fields as prototype own properties (ancient — the pre-v2 class-save
> path always did it); `Class.applyMemberEdit` now compiles via the bare
> global-assignment eval, the `Mixin.applyMemberEdit` shape.
Donor attribution covers mixin METHODS only: `selectionFromList`'s mixin walk runs in the
`Utils.isFunction` branch, so a mixin-donated FIELD (e.g. `color_hover`) shows its plain
VALUE un-attributed — no donor label, no override button, and a save takes the plain
class-edit path. Extending parity to fields needs real design: class-inspector field
views would show SOURCES instead of values (object inspectors must keep showing the
instance VALUE), `Class.applyMemberEdit` would need to keep `<name>_source` for
non-functions (today functions only — it is both the view's attribution key and the
live-override shadow guard), and the class-scope registry would need to record field
edits. `Mixin.applyMemberEdit`/`removeMember` already handle fields — only the
inspector's attribution/view layer is method-scoped. → `docs/BACKLOG.md`.

### T — SystemTest for the edit flow (after P1/P2 land)
Macro: open a class inspector on a `ButtonWdgt` (Highlightable consumer), select
`color_hover`, edit source to a distinctive colour, save (donor path), hover the button,
screenshot; then P1's override gesture on a second class and re-screenshot. Author with
the `/author-macro-test` skill (Fizzygum-tests repo). This pins the save popup, the P2
label, and the P1 button pixels.

## Standing constraints
- Ratchet gates: new code must not raise `instanceof-type-test` / `undefined-literal` /
  call-separation counts — factor, don't baseline-bump (see the Duplicator arc memory).
- Owner gates: RESOLVED 2026-07-26 — P1 label = "override in this class", left of the
  save button; P3 add gesture = destination step in the existing `add…` popout. All 5
  points pre-approved.
- Docs to touch at close: `mixins.md` §2/§7/§8, reference doc §12, this plan → archive.

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

The closed items this plan owned, relocated VERBATIM from `docs/BACKLOG.md` on 2026-08-18 so
that file can go back to being an index of OPEN work only (`docs/README.md` filing rule 2: an
arc's items leave BACKLOG when it closes). Nothing above this line changed; any item of this
arc still OPEN stayed in `docs/BACKLOG.md`.

- [x] `archive/mixin-editing-v2-plan.md` "Residual discovered during T": field parity for donor attribution — DONE 2026-07-26, owner-directed (ClassInspectorWdgt._sourceForFieldMember; Class.applyMemberEdit keeps `<name>_source` for every member kind; class-scope field records; SystemTest_macroMixinFieldEditDonorAndOverride).
