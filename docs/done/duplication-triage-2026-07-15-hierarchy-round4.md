# Duplication triage — ROUND 4 / 4b snapshot (hierarchy-aware axis), 2026-07-15 — CLOSED

Committed snapshot of the `duplication-report/triage-report.md` ROUND 4 / 4b sections, per the
lifecycle convention in `docs/duplicated-code-detection.md` ("when a campaign arc closes, snapshot
the ledger to `docs/done/duplication-triage-<date>.md` and commit it" — the ledger is gitignored and
one `git clean -fdx` from oblivion). This file is the durable record; the live ledger stays the
working copy.

**Arc:** the third duplication axis — hierarchy-aware — added by the Pharo generic-rules carryover
(`docs/lint-generic-rules-carryover-plan.md`, EXECUTED 2026-07-15). Commits: `2dbf123d` (censuses
added), `83209869` (Tranche A+B actioned).

---

## Why this axis exists

jscpd finds EXACT clones and jsinspect finds STRUCTURAL ones, but **neither reasons about
inheritance**, so neither can ever say *"this override is REMOVABLE"* — an override and the parent
method it duplicates are not textual twins sitting in one file. Two censuses close that gap:

| Census | Reports | Pharo ancestry |
|---|---|---|
| `buildSystem/census-hierarchy-duplication.js` | `IDENTICAL-TO-INHERITED`, `SHADOWS-MIXIN`, `JUST-SENDS-SUPER` | `ReEquivalentSuperclassMethods` / `ReJustSendsSuper` / `ReLocalMethodsSameThanTrait` |
| `buildSystem/census-property-placement.js` | `PULL-UP`, `DEMOTE` | `ReInstVarInSubclasses` / `ReVariableReferencedOnce` |

Both advisory (exit 0), `--json`, ~0.5 s, and wired into `fg critique`. **Neither can ever be
promoted to a gate**: `super` is meta-compiled (`src/meta/Class.coffee` rewrites every super form at
fragment-compile time), and property access is partly dynamic (`DeepCopierMixin` walks
`@[property]`; serialization drives off name STRINGS). See `docs/lint-and-static-checks.md` §3b/§3c.

## Findings at birth (2026-07-15, 486 classes / 2747 methods / 1652 declared properties)

- **IDENTICAL-TO-INHERITED 10 · SHADOWS-MIXIN 0 · JUST-SENDS-SUPER 0**
- **PULL-UP 10** (7 same-default) · **DEMOTE 37** (+49 withheld by the `.name` member-read veto)
- `SHADOWS-MIXIN = 0` is itself a result: no class re-defines a method its own `@augmentWith` mixin
  already provides. Re-run after any mixin→delegation conversion.
- These are ADDITIVE to the round-3 EXACT/STRUCTURAL baselines — a different axis, not a re-count.

## ✅ ACTIONED — Tranche A+B (`83209869`): 6 overrides + 1 field. Gauntlet 9/9, zero recaptures.

**Tranche A — 6 no-op overrides deleted.** The removability test that made these safe, and the
thing to check first on any future finding: **the subclass already overrides the CORE** (or the
member the parent's body late-binds to), so the parent's public wrapper dispatches back into the
subclass unchanged. Deleting them RESTORES the intended layering rather than merely cutting lines —
the parent owns the ONE public settle-wrapper; subclasses override only cores ("cores call cores").

- `WindowWdgt._reLayoutChildren` — inherited version calls `@_positionAndResizeChildren()`, which
  dispatches to WindowWdgt's OWN override, so the chrome+content re-fit is untouched. Its
  window-specific doc was MOVED onto that override rather than deleted.
- `SimpleVerticalStackScrollPanelWdgt.{enable,disable}DragsDropsAndEditing` — class overrides both
  `_NoSettle` cores; ScrollPanelWdgt's wraps reach them.
- `TextWdgt.sizeToTextAndDisableFitting` — overrides only the core.
- `SimplePlainTextWdgt.{openTargetPropertySelector,reactToTargetConnection}` — StringWdgt's bodies
  late-bind to `stringSetters` / `updateTarget`, both defined in this class.

**Tranche B — `PreferencesAndSettings.outlineColor` field → local.** The one true DEMOTE positive:
assigned in `setMouseInputMode`, read exactly once on the next line to build `@outlineColorString`,
and it is that STRING the whole icon family consumes (`IconAppearance._outlineColorString`).

**Result: IDENTICAL-TO-INHERITED 10 → 4; DEMOTE 37 → 36.** PULL-UP stayed at 10 — the tranche took
nothing from that report (its findings all cost an inspector recapture; see the remainder below).

---

## CASE LAW (the durable part — read before acting on any future finding)

1. **`check-thin-wraps` stays green when a public wrapper is deleted from a class that keeps its
   core.** A twinless `*NoSettle` core is SKIPPED by design: the suffix marks a non-settling REGION
   and is twin-OPTIONAL (owner-decided 2026-06-25).
2. **⚠ Deleting a Widget-family METHOD does NOT churn the 15-test inspector set.** Verified
   empirically 2026-07-15: gauntlet 9/9, zero recaptures, after deleting 6 methods from
   Widget-family classes. The `fg recapture-inspector` cost is a **FIELD** problem, not a method
   problem. (The pre-run worry was the other way round — do not budget a recapture for a
   method-only deletion.)
3. **A `super`-calling override needs a BEHAVIOURAL argument, not a textual one — but that argument
   is often available.** Two textually-identical bodies that both call `super` are NOT the same
   program: `super` binds to the CALLER's hierarchy position, so the subclass copy makes the chain
   run one extra time. Whether that matters depends on whether the extra run is idempotent:
   - `SimplePlainTextWdgt.stringSetters` — appends `["bang!","text"]` that `super` (StringWdgt's)
     already appended; `_appendSettersAndDedup` pushes then dedups via `new Set(...)`, so appending
     a subset and re-deduping is a **no-op** ⇒ removable. Landed 2026-07-15.
   - `WindowWdgt.initialiseDefaultWindowContentLayoutSpec` — sets
     `@layoutSpecDetails.canSetHeightFreely = false` that `super` already set; an idempotent
     assignment ⇒ removable. Landed 2026-07-15.
   The rule is: find the specific reason the extra pass cannot change the result, or leave it alone.
   Verify with the suite regardless — this is the one census category where the textual signal is
   actively misleading.
4. **Compare the SIGNATURE, not just the body.** `(@color) -> super` auto-assigns and is NOT
   removable however bare the body reads (`VideoPlayCreatorButtonWdgt` — an early cut of the census
   called it removable, wrongly). Built into the census; do not simplify it away.
5. **A use outside any method body means public API.** A multi-line ctor parameter list
   (`constructor: (@elements = [], …) ->`, `ListWdgt`) is fed by `new ListWdgt(someElements)`. The
   census attributes such occurrences to a `@classlevel` pseudo-owner so the finding disappears.
6. **A `.name` member read from another file vetoes a DEMOTE.** 22 `PreferencesAndSettings` fields
   looked local (only ASSIGNED in `@setMouseInputMode`) but are the global settings surface, read as
   `WorldWdgt.preferencesAndSettings.<field>` (e.g. `PanelWdgt.coffee:22`). Demoting one would have
   broken rendering.
7. **⚠ Hand spot-checking is NOT a substitute for rule 6.** `InspectorWdgt.textWidget` was
   hand-verified "genuine" by grepping *within InspectorWdgt.coffee* — and that was WRONG:
   `MacroToolkit.coffee:879` reads `inspectorNaked.textWidget`. Only the automated veto caught it.
   Apply the veto to every finding, not just the risky-looking ones.
8. **Deliberate seams stay.** The `_apply*`/`_commit*` corner twins, the `*Base` override-bypass
   twins and the mapRect twins are same-class SIBLINGS, not overrides, so they correctly never
   appear here. `fps` on `DataflowSource` is a documented-deliberate PULL-UP non-finding (the
   parent's own header says "each subclass carries only its own cadence") — do not "fix" it.
9. **`offset` on `CircleBoxWdgt` is a name COLLISION, not a shared concept** — the DEMOTE report
   independently finds `SliderButtonWdgt.offset` is a one-method local. That is what the weak
   differing-defaults PULL-UP tier is for.
10. **⚠⚠ A WRITE-ONLY field is not a local — it is ENUMERATION PAYLOAD until proven otherwise.** The
    DEMOTE rule shipped requiring "first use is an assignment" but never requiring a READ, so a field
    assigned once and never read was reported as demotable. That is wrong twice over: demoting a
    write-only field does not make it a local, it makes it **dead**; and it usually is not dead at all
    — `JSON.stringify(obj)`, `DeepCopierMixin`'s `@[property]` walk and the serializer all reach every
    own property **without naming any of them**, so no name scanner can see those reads.
    **The near-miss:** 16 of 36 findings were write-only, and **12 were `SystemInfo` fields**, assigned
    in the ctor and never read in src — because `SystemTestsReferenceImage.coffee:31` hashes
    `JSON.stringify(@systemInfo)` into the `systemInfoHash` of **every reference-image filename**.
    Acting on that report would have invalidated the whole committed reference set.
    `SystemTestsSystemInfo.coffee` states the mechanism outright — *"cannot just initialise the numbers
    here cause we are going to make a JSON out of this and these would not be picked up"*: class-body
    defaults are PROTOTYPE properties and are not serialized; only the ctor's `@x = …` OWN properties
    are. That is also why those findings read "1 use, has a class-body default" — the default and the
    ctor assignment are **not** redundant, they play different roles.
    Fixed 2026-07-15 as **exclusion 4** (DEMOTE 36 → 20). ⚠ The test is "at least one NON-ASSIGNMENT
    occurrence", NOT the `uses >= 2` first proposed — `@x = 0; @x += 1` is two uses and still
    write-only in effect.
    **Corollary — a suppression that works for the wrong reason hides the real one.** The fix dropped
    exclusion 3's withheld count from **49 to 3**: the `.name` veto had been credited with withholding
    49 findings when its true cost is 3, because 46 were write-only false positives it suppressed by
    luck. Case law 6's example (`SliderButtonWdgt.offset`) survives as one of the real 3. **Report each
    exclusion's cost separately** — a lumped counter let a wrong rule look load-bearing.

## ✅ ACTIONED — Tranche C (2026-07-15): the 3 remaining removable IDENTICAL findings

A second pass took the rest of the IDENTICAL report once each had a specific argument (case law 3):
- `SimplePlainTextWdgt.updateTarget` — **pure duplicate, no `super` at all** (`@_fireConnection @text`).
  A first triage pass mis-grouped it with `stringSetters` as "super-chaining"; reading it settled that.
- `SimplePlainTextWdgt.stringSetters` — the dedup no-op argued in case law 3.
- `WindowWdgt.initialiseDefaultWindowContentLayoutSpec` — the idempotent-assignment argument.

With `openTargetPropertySelector` / `reactToTargetConnection` already gone in Tranche A, **the whole
controller surface of `SimplePlainTextWdgt` is now inherited from StringWdgt** — a plain-text
controller drives its target exactly as a StringWdgt does, so there was nothing to specialise. That
is the coherent end state, and it is documented in the class.

**Result: IDENTICAL-TO-INHERITED 4 → 1.**

## NOT actioned — the deliberate remainder

- **`BubblyAppearance.constructor == BoxyAppearance.constructor`** (`super widget`) — the last
  IDENTICAL finding, deliberately LEFT. It is a CONSTRUCTOR, and constructors here are not ordinary
  methods: `src/meta/Class.coffee` fragments and rewrites them, `check-constructors-build` governs
  them, duplication/serialization go through `Object.create`, and there is recorded case law of a
  subclass-super constructor trap (`WindowWdgt`/`FolderWindowWdgt`). Two lines is not worth entering
  a risk class that has bitten before. Revisit only with a constructor-focused arc.
- **9 PULL-UP**: the real ones are the 3 `IconicDesktopSystemLinkWdgt` colours (`color_normal:
  Color.BLACK` etc., verbatim in all 3 subclasses) and the 2 `PatchNodeWdgt`
  `setInputNIsConnected: false` flags — all Widget-family, so each costs an inspector recapture.
- **23 inspector-visible DEMOTEs**: mostly ctor-built child widgets parked in a field only the
  builder reads (the widget TREE already holds the reference); `InspectorWdgt.show*On/OffButton` is
  the archetype. Low value against a recapture each.
- **49 withheld DEMOTEs**: cannot be proven local (case law 6). ⚠ **Superseded by case law 10** — after
  the write-only fix this bucket splits into **3** genuinely withheld by the `.name` veto (including
  case law 6's own example: `SliderButtonWdgt.offset` IS genuinely local to `@nonFloatDragging`, but
  the other `.offset` reads in src are `appliedShadow.offset`, a different object the scanner cannot
  distinguish — that is the honest cost of the veto) and **46** that were write-only false positives
  all along. Withheld COUNTS are printed rather than hidden, and now printed per-exclusion.
