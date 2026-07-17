> **ARCHIVED — COMPLETE (2026-07-17 restructure).** CAMPAIGN COMPLETE, verified on origin 2026-07-17 (executed 2026-07-13); remaining rows are deliberate LEAVE/DEFER verdicts.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Accidental-Complexity Reduction Plan

**Status: AUTHORED 2026-07-07, RE-VERIFIED 2026-07-12, EXECUTED 2026-07-13, CAMPAIGN COMPLETE — every
actionable item landed and pushed (verified on origin 2026-07-17, when this doc was finally committed as the
historical record). Remaining ⛔ rows are deliberate LEAVE/DEFER verdicts, not pending work; the only open
crumb is the optional `[U]` baseline tightening 150→148 noted in the P5-fam-4 box.**
Every fact below is refreshed to the 2026-07-12 tree unless marked otherwise; the tree has since moved (re-grep before editing).

### Execution status (2026-07-13)
| Plan | Status | Commit(s) |
|---|---|---|
| **P2-T1, P8, P6 (A–D), P1, P9, P2-T2** | ✅ DONE + PUSHED (one low-risk batch) | Fizzygum `3267b0dd` |
| **P6 item E** (virtual-keyboard Keyup wrong-parent bug fix) | ✅ DONE + PUSHED | Fizzygum `3579a399` |
| **P9 openInWindow** (MenusHelper → `world.openWindowWith`) | ✅ DONE + PUSHED | Fizzygum `33cb9877` |
| **P7** (StringWdgt fonts + Deserializer tables; CaretWdgt LEFT AS-IS) | ✅ DONE + PUSHED | Fizzygum `4d6d6854` |
| **P4** (ScrollPanelWdgt scroll-delta) | ⛔ LEAVE-AS-IS (owner-confirmed; blocks differ, determinism-critical) | — |
| **P3** (MultiClickRecognizer + determineGrabs hoist; PointerMode enum DEFERRED) | ✅ DONE + PUSHED | Fizzygum `f6c9c1d3` |
| **P5 families 1–3** (addMenuItem, MenuWdgt ctor, WindowWdgt ctor → arg-objects) | ✅ DONE + PUSHED | Fizzygum `c882a34f` + tests `8b3b56262` |
| **P5 Family 4** (`_addNoSettle` → arg-object; owner chose FULL conversion 2026-07-14) | ✅ DONE + PUSHED — 4 override defs + 24 multi-arg call sites; `unused` placeholder eliminated; gauntlet 8/8 + homepage green | Fizzygum `5fa62bde` |
| **P2-T3** (SourceVault dead-tool cluster; SystemInfo turned out LIVE) | ✅ DONE (deletion) + PUSHED (annotation corrected 2026-07-17: it was on origin all along) — 4-file SourceVault cluster; SystemInfo KEPT (harness base class); gauntlet 8/8 + homepage green | Fizzygum `fcd1bafb` |
| **P2-T3 follow-up** (port 3 worthwhile SourceVault checks → new build gates: #11 CHECK-AFTER, #8 trailing-whitespace, #3 no-stringified-scripts) | ✅ DONE + PUSHED (annotation corrected 2026-07-17) — 3 gates wired into build_it_please.sh; cleaned 26 trailing-ws lines + resolved 2 overdue Jan-2021 CHECK-AFTER markers; gauntlet 8/8 green | Fizzygum `85c49fee` |
| **P7 CaretWdgt keymap**; **P3 PointerMode enum** | ⛔ LEFT/DEFERRED (see those sections) | — |

**✅ P5 Family 4 DONE + PUSHED (2026-07-14, Fizzygum `5fa62bde`):** `_addNoSettle` was NOT the "5 WindowWdgt sites" the raw facts listed — it was a **core settle-axis method with 199 call sites (153 already bare single-arg) and 4 different override signatures** (Widget base / WindowWdgt / ToolPanelWdgt / SimpleVerticalStackPanelWdgt). Owner chose the FULL conversion. As-built: all 4 overrides → `(aWdgt, opts = {})` over ONE vocabulary (`position / layoutSpec / beingDropped / notContent / positionOnScreen`); the dead `unused` positional placeholder eliminated; per-override `layoutSpec` defaults preserved byte-identically via `opts.layoutSpec ? <default>` (nil === undefined); the 6 explicit inter-override super calls + ToolPanel's bare `super` rewritten to explicit opts (bare-super forwarded the *defaulted* param, so it had to become explicit); `add()` stayed positional (separate surface) with its 4 forwarders translating positional→opts; 24 multi-arg call sites converted across 9 files. Gates clean incl. settle-axis [S]/[T]/[U] (allowlist unchanged); `[U]` QUERY 150→148 (eliminated `unused` path). Gauntlet 8/8 + homepage green, 0 diffs. **`[U]` baseline could be tightened 150→148 to lock the gain (optional, deferred).**

**⚠ P5 execution learnings (families 1–3):** (a) ctor-arg reordering is SAFE for BOTH serialization and duplication — `Deserializer` AND `DeepCopierMixin` instantiate via `Object.create` (the constructor is never run), so only explicit `new X(...)` call sites matter. (b) SUBCLASS `super` calls pass the OLD positional signature and MUST be updated with the ctor (FolderWindowWdgt forced `contents=""` → a `.colloquialName()` crash; Prompt/SaveShortcutPrompt for MenuWdgt). (c) a `.method`-anchored transform MISSES `@method` self-calls — grep both. (d) `addMenuItem (expr)…` (paren-less, paren-expression label) ≠ `addMenuItem(` (paren-call) — distinguish by the leading space.

**Behavior contract: every step is behavior-preserving. Expected result of every batch: zero screenshot diffs across the full suite. That expectation is a claim to VERIFY per batch, never to assume.**

## 0. What this is and how it was produced

A structured refactoring plan targeting *accidental* complexity (Brooks: difficulty introduced by implementation choices) while leaving *essential* complexity (the live-coding meta-system, the single-canvas paint/layout model, deterministic screenshot testing) untouched.

Produced 2026-07-07 by a five-dimension parallel audit of all `.coffee` files under `Fizzygum/src` (then 507 files / ~54,663 lines; **now 511 files / 56,417 lines**, re-counted 2026-07-12):

1. Historical leftovers (dead code, commented-out logic, obsolete workarounds)
2. Duplication & bloat (copy-paste siblings, repeated boilerplate)
3. Over-engineering / YAGNI (single-implementation abstractions, unused extensibility)
4. State & control-flow pollution (nesting, boolean-flag machines, god-methods)
5. Inappropriate tooling + mental-model mismatch (stdlib reimplementations, cryptic naming, positional-arg soup)

Line numbers were re-captured 2026-07-12 by a six-agent re-audit (see §0.3 for the tree anchor). The tree moves fast — re-grep before editing anyway.

### 0.1 Exclusions — settled or plan-owned work this plan must NOT touch

- **Layout suppression/convergence machinery** — `world._inLayoutMutation`, `world._recalculatingLayouts`, `layoutIsValid`, `widgetsThatMaybeChangedLayout`, `recalcIterationsCap`, `WorldWdgt._recalculateLayoutsBody` (now `:1067-1164`), the notify-by-mutation seam (`_reFitContainerAfterRawGeometryChange`, `silentRawSetExtent`, `fullRawMoveBy`): all owned by `docs/archive/proper-layouts-eliminate-suppression-booleans-plan.md` and the convergence arc. (`world._batchingLayoutSettling`, listed here in the 07-07 version, **no longer exists** — eliminated by that arc.)
- **The `wEl/wStk` stack fraction** — proven irreducible (3 falsifications).
- **The structural-arrange seam** — arc closed 2026-06-29; seam STAYS (`proper-layouts-4.4-ordered-downwalk-plan.md` §8 binding).
- **Naming-tier work** — `docs/architecture/layering-naming-convention.md` (note: the live doc, there is no `-plan.md`) already owns the `_`/`__` tier scheme, the geometry-apply 2×2, the notification grid, the settle/coalesce axis, and bans `raw*`/`silent*`/`fullRaw*` defs (0 survive). Only two naming items below are NOT in that plan: positional-arg soup (P5) and the `SLOW*` prefix (P8, optional).
- **Public/private call-separation** (NEW 2026-07-12) — `docs/archive/public-private-call-separation-plan.md` (rules [S]/[T]/[U]) owns which methods are `_`-tier. Its T0–T5 rename sweep (~81 renames) is **in the working tree, uncommitted** as of this re-audit — every current line number below was captured WITH that sweep applied. Any rename/extraction this plan does must respect its rules, allowlists, and gates; note button-action strings and `process*` dispatchers are public surface (never `_`-rename them).
- **Menu/slider constructor-build** (NEW 2026-07-12) — `docs/archive/menu-slider-ctor-conversion-plan.md` is COMPLETE (`ba7a0c6b`): all 4 ctor-build exemptions retired; MenuWdgt now builds its label via the `_buildMenuLabel`/`_buildMenuLabelNoSettle` pair. P5's MenuWdgt work must not reintroduce ctor-build patterns that plan retired.
- **Affine-transform plane-mapping** (NEW 2026-07-12) — the affine arc (Phases 4–5 landed) threaded `screenPointToMyPlane`/`_pointerPositionInPlaneOf`/pick-out/re-express calls through `processMouseUp`, `drop`, and `determineGrabs`. P3 restructures *shape only* and must keep these calls at their exact seams (locations pinned in P3's raw facts).
- **Drag-embed dwell state machine** — the `dragEmbed*` fields in `ActivePointerWdgt` are a documented deliberate design (drag-embed interaction spec §6). Additionally (2026-07-12): `drop` now RE-RUNS the dwell SM at its top (`:399-408` — `updateDragEmbedStateMachine()` → capture `wasArmed`/`overReluctantOnly` → `_endDragEmbedInteraction()`); any `drop` extraction must preserve that run-once-then-teardown ordering.
- **`doOneCycle` drain-station sequence** (now `WorldWdgt.coffee:1580-1647`) — documented orchestration spine; long but correct as-is.

### 0.2 Audit non-findings (verified clean — do not re-audit)

- Dead methods in the 4 god-files: **zero** orphaned. (The 07-07 audit's single candidate, `WorldWdgt.removeEventListeners`, was FALSIFIED 2026-07-12: it is called by the test harness — `AutomatorPlayer.coffee:666` tears down world listeners per test.) Method census 2026-07-12: Widget 334, WorldWdgt 100, ActivePointerWdgt 42, StringWdgt 99 (575 total; grew with the affine arc).
- Morphic rename: complete. Prose tokens remaining: `Widget.coffee:4` and `:846` (explanatory comments) + a `morphic.js` URL at `:2798`; BouncerWdgt is clean now. Keep.
- `mixins/`: 14 files; 12 genuinely multi-use (`DeepCopierMixin` **18** sites, `ControllerMixin` 9, `HighlightableMixin` 9, …). Only `ContainerMixin` (dead, → P2) and `CreateShortcutOfDroppedItemsMixin` (single-use, optional inline, → P6) flagged.
- No custom event emitters, no `setInterval` (0 uses), render loop is native `requestAnimationFrame`, only 5 non-render `setTimeout` sites (ToolTipWdgt:51, ActivePointerWdgt:148, boot/loading-and-compiling…:48, SWCanvasElement-extensions:91, FileSaving:30). Scheduling is NOT reinvented (intentional per DETERMINISM.md).
- No reimplementations of `includes`/`flatten`/`padStart`/`assign`/`trim`/`isInteger`/`hypot`. `HhmmssLabelWdgt` uses native `padStart`. `Widget._clampedPositionWithin` is domain geometry (no `Math.clamp` native exists).
- `basic-data-structures/TreeNode.coffee`: `@children` is the single source of truth; no cached count. Clean.
- `serialization/Serializer.coffee`: genuine multi-branch type dispatch, not a single-strategy pattern.
- `events-input/`: legit Command hierarchy, ~15 concrete `InputEvent` subclasses each with distinct `processEvent()`. (Two empty markers excepted, → P6.)
- `maps/SimpleUSAMapIconAppearance.coffee` (2,316 L) / `SimpleWorldMapIconAppearance.coffee` (838 L): irreducible hand-digitized path data; only ~10 lines each of P1 boilerplate. (Re-verified exact 2026-07-12.)
- `GlassBoxTopWdgt` vs `GlassBoxBottomWdgt`: NOT duplicates (different bases, different jobs).
- Getter/setter proliferation: none. `Object.defineProperty` ×3 total; `setColor` overridden in only 5 files (stainer mixins carry the rest).
- `TextEditingState.coffee`: clean 5-field value object, not a state machine.

### 0.3 Re-verification ledger (2026-07-12)

**Tree anchor:** Fizzygum `master @ 0f556e08` **plus 121 uncommitted files** — the public/private call-separation T0–T5 rename sweep (awaiting owner commit approval). Fizzygum-tests `master @ fb93eb1ff` (dirty). Suite = **243** SystemTests. All current line numbers in this doc reflect that working tree, sweep included. Re-audit method: six parallel read-only agents, one per plan area, every count re-grepped.

**Landed independently since 07-07 (drop from scope):**
- P2-T1: WorldWdgt "show all"/"hide all" noOperation menu items — deleted in `c82e0bcc`.
- P2-T2: Widget commented-out `getDesiredDim`/`getMinDim`/`getMaxDim` alternatives — deleted in `87dd5d7c`.

**Falsified "dead" verdicts (removed from P2):**
- `WorldWdgt.removeEventListeners` — LIVE: called by `AutomatorPlayer.coffee:666` (per-test listener teardown). Now at `WorldWdgt.coffee:2107-2134`.
- `LCLTransforms` (351 L) — LIVE: the SW3D port landed (2026-07-08); it is FridgeMagnets3DCanvasWdgt's matrix stack (`FridgeMagnets3DCanvasWdgt.coffee:74` — `@transforms ?= @_markTransient new LCLTransforms @`).
- `Array::chunk` — LIVE in the tests repo: `AutomatorLoader.coffee:224` uses it for shard/group partitioning (P8 row flipped to KEEP).
- `DegreesConverterNodeIconWdgt.coffee` — the file holds class **`DegreesConverterIconWdgt`** (filename ≠ classname!), which IS instantiated (`apps/DegreesConverterApp.coffee:15`). The 07-07 "0 hits" was a grep artifact of the mismatch. Dead-icon row: 18 → **17** classes.

**Caveats resolved:**
- P3 serialization check: the hand is a **well-known object** (`WellKnownObjects.keyFor` → `"hand"`); its own fields are never walked into snapshots (`Serializer.coffee:88`; serialization reference §11). Swapping the multi-click fields for recognizer objects is NOT a snapshot-format change.
- P2 `EyeIconWdgt` warning: it is dead — the pencil/eye title-bar glyph is drawn by `buttons/EditIconButtonWdgt.coffee` (`:8/:22/:27`) using `PencilIconAppearance`/`EyeIconAppearance` directly, driven from `WindowWdgt.coffee:553/561`.
- P8 `Math.getRandomInt` investigation: sole use is `BouncerWdgt.coffee:19` (demo velocity) — NOT `_addInPseudoRandomPosition*`, which uses `hashCode()` (`PanelWdgt.coffee:123,127-128`). No render/layout-path use.

**Sketches amended (details in their sections):** P1 ctor-default shape (`?=` cannot work — the base has prototype-level 200,200 defaults); P3 recognizer needs a `position` field (6-field mirror, not 4); P3 threshold preamble is ×2, not ×3; P4 the three scroll blocks are NOT verbatim (delta source, `Math.round`, in-guard friction decay differ); P5 MenuWdgt real signature is 8 params; P7 the StringWdgt switch is a stack→tick-flag map, not a name→stack lookup; P8 hash consolidation direction flipped (hashCode is now memoized — O2).

**Falsified/typo'd counts:** the 07-07 "94 sites with ≥2 consecutive bare booleans" is internally impossible (≥2 ⊇ ≥3=110); measured ≥2 = 242. The "8 SLOW* defs" is now 17 (Tier-J + affine overrides). MenusHelper method counts drifted (116→123 defs, 51→53 one-liners) though the file is byte-unchanged (874 L) — original-author imprecision.

**New micro-finding:** two `src/icons/` files violate the filename==classname convention (`DegreesConverterNodeIconWdgt.coffee` → `DegreesConverterIconWdgt`; `SliderNodeCalculatingNodeIconWdgt.coffee` → `SliderNodeIconWdgt`). `build.py` and the dependency scanner key off that convention — latent trap. Fix opportunistically in P2-T2 (rename file to match class for the live one; the dead one gets deleted anyway).

## 1. Complexity Diagnostic Summary

- **`icons/` appearance layer = the largest bloat pocket (~570–640 eliminable lines).** 77/89 `*IconAppearance` files repeat an identical ctor; 70 apply a redundant identity `context.scale`; 64 repeat a verbatim color prologue; `CFDegreesConverterIconAppearance` (230 L) is byte-identical to `DegreesConverterIconAppearance` (231 L) except ONE `fillStyle` line. (All re-verified exact 2026-07-12.)
- **Positional-argument soup — top cognitive-load flaw not covered by any campaign.** 242 call sites with ≥2 consecutive bare `true/false/nil`; 110 with ≥3; worst = 12 positional args. `MenuWdgt`'s 3 boolean ctor params constant at 46/47 sites.
- **Input pipeline hand-mirrors state machines.** `ActivePointerWdgt.processMouseUp` (`:702-868`, ~167 L, 8 indent levels): triple-click block is a near-verbatim copy of the double-click block. Pointer drag-mode re-derived from nilable fields at 23 predicate sites (+2 raw-field reads). `ScrollPanelWdgt.mouseDownLeft` (`:554-671`): one scroll-delta skeleton pasted 3× (guards verbatim; deltas/rounding per-copy).
- **~365 lines dead/vestigial certain/likely + ~400 gated (~1.4% combined)**: dead mixin, 17 never-instantiated leaf `*IconWdgt`s (~81 L), ~230 L commented-out code, 2 whole experimental classes (~401 L, verification-gated). (Down from the 07-07 estimate: two rows landed, three "dead" verdicts falsified.)
- **Phantom enums / single-valued spec files**: 2 `FittingSpec*` classes whose second value is self-admittedly "not yet exercised"; `LayoutSpec` dead const + commented-out enum; `PreferredSize` = a file naming 2 sentinels.
- **Duplicate infrastructure**: two value-identical Java-string-hash impls (one now memoized — O2); byte-identical `Number::times` twins; dead `Array::unique`.
- **Branch-shaped data**: 9-arm `switch` on the font stack (tick-flag map); two PARALLEL `switch record.class` tag dispatchers in `Deserializer`; 13+2+2-arm key switches in `CaretWdgt`.
- **Verbatim block multiplication**: scroll-delta skeleton ×3, shortcut bring-up ritual ×3 (byte-identical core), window-open block ×7 (5 full + 2 partial).

Yield if P1–P9 all land: **~1,200–1,300 lines certain/likely removable (~2.2%) + ~400 gated**, plus the input pipeline and menu call sites becoming readable without opening definitions.

---

## 2. The plans

Suggested order (independent, cheapest-risk first):
**P2-Tier1 → P8 → P6 → P1 → P9 → P2-Tier2 → P7 → P4 → P3 → P5.**
P5 last (widest call-site blast radius). Each plan is independently landable and verifiable.

### Universal verification gate (every plan, every batch)

```bash
fg presuite                   # inner loop: lint + build + dpr1 suite ∥ paint audit (~3.5 min)
# end of each landed plan:
fg gauntlet                   # lint + build, then dpr1∥dpr2∥webkit∥apps + paint∥tiernaming∥settle∥capstone (~4.5-5 min)
```

- The suite is **243** tests; expect ZERO screenshot diffs. A `[shard N] did not start` / `CoffeeScript is not defined` in a gauntlet leg log is the boot-storm infra flake, not a code bug (runners retry once).
- Renames/deletions touching symbols must be grepped across BOTH repos — **note the tests repo has NO `src/`**; its CoffeeScript lives in three dirs:
  `grep -rw "<Symbol>" Fizzygum/src Fizzygum-tests/tests Fizzygum-tests/Automator-and-test-harness-src "Fizzygum-tests/helper macros"`
  — test macros reference classes/methods by name; MacroToolkit's "unused in src" methods (`assert*`, `*_InputEvents`, `linkTo`) are exactly that test-facing API. NOT dead. (⚠ Two icon files have filename ≠ classname — grep the CLASS name, not the filename; see §0.3.)
- Never `grep -r` from the workspace root (`Fizzygum-builds/latest` is ~1.3 GB).
- A benign inspector member-list diff = just recapture (owner policy; `fg recapture-inspector`); never contort code to avoid one.
- Zero failed screenshots in a shard can mean an uncaught error → shard STALL: check for it, don't celebrate early.

---

### P1 — Collapse the icon-appearance boilerplate (~570–640 lines)

**Rationale.** Every icon file should be pure path data. Instead each re-declares sizing, an identity transform, and color plumbing that belong on the existing-but-underused base `icons/IconAppearance.coffee`. Pixel output unchanged by construction.

**Raw facts (re-verified 2026-07-12 — all original counts reproduced exactly):**
- `icons/` = 177 files (89 `*IconAppearance` totaling 7,614 L + 88 `*IconWdgt` — the +1 since 07-07 is `GenericCompositeIconWdgt.coffee` from `4673e98e`, a Wdgt-side composite-icon base that absorbs NONE of the Appearance-layer items below).
- 77 `*IconAppearance` files repeat the verbatim ctor `constructor: (@widget) -> super` + `@preferredSize = new Point 100,100`; 70 of those also set `@specificationSize = new Point 100,100` (the other 7: 3 set spec `400,400`, 4 omit spec and inherit the base's `200,200`).
- For the 70, the second `context.scale()` is an identity transform (spec == pref).
- 64 files repeat verbatim in `paintFunction`:
  `if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @widget.color.toString()`
- 38 files also repeat `outlineColorString = WorldWdgt.preferencesAndSettings.outlineColorString`.
- `icons/DegreesConverterIconAppearance.coffee` (231 L) vs `icons/CFDegreesConverterIconAppearance.coffee` (230 L): full diff = exactly 3 hunks (class name, one blank line, one `fillStyle`: `outlineColorString` vs `'rgb(170, 170, 170)'`). All ~226 path-data lines byte-identical. Both classes are live (`CFDegreesConverterIconWdgt` created at `MenusHelper.coffee:271`).
- The base (147 L) has NO constructor and NO color helpers; it declares **prototype-level** `preferredSize: new Point 200, 200` (`:5`) and `specificationSize: new Point 200, 200` (`:9`), and is instantiated DIRECTLY by `IconWdgt.coffee:12` (`createAppearance: -> new IconAppearance @`).
- The 12 non-conforming `*IconAppearance` files = base + `MapPinIconAppearance` (`70,100`) + 10 subclasses that set NOTHING and inherit the base's `200,200` (AngledArrowUpLeft, Brush, Close, Collapse, Eraser, Eye, Pencil2, Pencil, Toothpaste, Uncollapse).
- Arrow family (`Arrow{N,S,E,W,NE,NW,SE,SW}IconAppearance`, 41-43 L each): structure shared (covered by this plan's base-class work), coordinates irreducible. No further collapse.

**⚠ Sketch amendment (2026-07-12).** The 07-07 sketch (`@preferredSize ?= new Point 100,100` in a base ctor) CANNOT work: `?=` reads through the prototype chain, sees the base's prototype `200,200`, and never assigns. And the base's `200,200` cannot be flipped to `100,100` — it is live for direct-base instances (`IconWdgt:12`) and the 10 inheriting subclasses. The working shape is **per-class prototype properties**:

```
[Current]                                    [Proposed]
77× subclass ctor (4 lines):                 77× two prototype lines (or one, see below):
  constructor: (@widget) ->                    preferredSize: new Point 100, 100
    super                                      specificationSize: new Point 100, 100
    @preferredSize = new Point 100,100       (ctor deleted entirely — safe: base Appearance
    @specificationSize = new Point 100,100    ctor is `(@widget, @ownColorInsteadOfWidgetColor) ->`
                                              and a bare `super` forwards all args, so the implicit
                                              ctor is behavior-identical)
70× identity context.scale(spec/pref)        base skips scale when spec equals pref
64× color-prologue in paintFunction          @iconColorString() / @outlineColorString() on base
DegreesConverterIconAppearance   231 L       DegreesConverterIconAppearance  231 L
CFDegreesConverterIconAppearance 230 L        └─ CFDegreesConverter… extends it (~5 L,
(identical except ONE fillStyle line)            overrides outline color only)
```

Optional further squeeze: teach the base `spec = @specificationSize ? @preferredSize` and drop the `specificationSize` line from the 70 identity files (one prototype line each). Decide at edit time; both shapes are behavior-preserving.

**Implementation sketch.**

```coffee
# icons/IconAppearance.coffee  (base gains helpers; prototype defaults stay 200,200)
+ iconColorString: ->
+   (@ownColorInsteadOfWidgetColor ? @widget.color).toString()
+ outlineColorString: ->
+   WorldWdgt.preferencesAndSettings.outlineColorString

# 77× icons/*IconAppearance.coffee — 4-line ctor → 2 (or 1) prototype lines
# 64× inside paintFunction — prologue collapses
- if @ownColorInsteadOfWidgetColor?
-   iconColorString = @ownColorInsteadOfWidgetColor.toString()
- else
-   iconColorString = @widget.color.toString()
+ iconColorString = @iconColorString()

# icons/CFDegreesConverterIconAppearance.coffee — 230 lines → ~5
+ class CFDegreesConverterIconAppearance extends DegreesConverterIconAppearance
+   outlineColorString: -> 'rgb(170, 170, 170)'
```

**Constraints.**
- `extends DegreesConverterIconAppearance` keeps the build's regex dependency-scanner satisfied (class-name token present).
- Mind the syntax gate: fragment-compiled classes — no complex static initializers; `preferredSize: new Point 100, 100` as a prototype property is fine (the base already does exactly this).
- The identity-scale skip lives in the base's `paintIntoAreaOrBlitFromBackBuffer` (scale call ~`:100-101`) — one site.
- The 12 non-conforming files are untouched (base + MapPin keep explicit sizes; the 10 inheritors already have no ctor).

**Batching.** Land in 3 commits-worth of batches: (a) base helpers + CF-collapse, (b) ctor→prototype-prop conversions, (c) color-prologue replacements. `fg presuite` between batches.

---

### P2 — Dead-code purge, three tiers (~193 L certain, ~172 L likely, ~401 gated)

**Rationale.** Dead code costs reading time and search noise while doing nothing. Split by confidence so deletion proceeds without endangering the experimental surface (77 files carry `excluded from the fizzygum homepage build` markers — several "dead" items are experimental-not-yet-wired, marked accordingly).

**Gate for EVERY dead-class candidate X** (note the corrected tests-repo paths, and grep the CLASS name, not the filename):

```bash
grep -rw "X" Fizzygum/src Fizzygum-tests/tests Fizzygum-tests/Automator-and-test-harness-src "Fizzygum-tests/helper macros"
# 0 hits outside its own file → delete
```

#### Tier 1 — CERTAIN (~193 L): unambiguous commented-out code

| File : lines (2026-07-12) | What | ~L |
|---|---|---|
| `basic-widgets/TextWdgt.coffee:121-141` | commented-out word-wrap `while` loop (long-single-word overflow) | 21 |
| `basic-widgets/Widget.coffee:4282-4302` | commented-out JS-syntax `nextTab`/`previousTab` example methods | 21 |
| `fizzytiles/LCLCodePreprocessor.coffee:496-510` | commented-out `adjustPostfixNotations:` method | 15 |
| `fizzytiles/LCLCodePreprocessor.coffee:749-755` | commented `.replace`/`console.log` lines in `transformTimesSyntax` | 7 |
| `fizzytiles/LCLCodePreprocessor.coffee:1486-1495` | commented regex/`return` block | 7 |
| `StackElementsSizeAdjustingWdgt.coffee:109-117` | commented-out `adoptWidgetsColor:` / `cursor:` overrides | 9 |
| `LayoutSpec.coffee:17,22-25,28-32` | commented-out enum consts (`# @STACK_HORIZONTAL_VERTICALALIGNMENTS_*` etc.) | 10 |
| ~34 files scattered | isolated commented-out debug lines — census 2026-07-12: 82 `# console.log` (26 files; top: LCLCodePreprocessor 15, WorldWdgt 9, ActivePointerWdgt 8, dependencies-finding 7, Widget 7) + 16 `# @x =` (12 files) + assorted `# localvar =` singles | ~110-140 |

(The 07-07 row "WorldWdgt noOperation show-all/hide-all items" landed independently in `c82e0bcc` — removed.)

#### Tier 2 — LIKELY (~172 L): grep-verified unreferenced; delete after the two-repo gate

| File | What | ~L |
|---|---|---|
| `mixins/ContainerMixin.coffee` | 0 `augmentWith` sites; header: "THIS MIXIN IS TEMPORARY. JUST STARTED IT." | 44 |
| 17 leaf `*IconWdgt` in `icons/` | never `new`'d anywhere: `AllPlotsIconWdgt`, `BarPlotIconWdgt`, `FunctionPlotIconWdgt`, `Plot3DIconWdgt`, `ScatterPlotIconWdgt`, `CalculatingNodeIconWdgt`, `ColorPalettePatchProgrammingIconWdgt`, `GrayscalePalettePatchProgrammingIconWdgt`, `PatchProgrammingComponentsIconWdgt`, `SliderNodeIconWdgt` (in the mis-named file `SliderNodeCalculatingNodeIconWdgt.coffee`), `ElasticWindowIconWdgt`, `EmptyWindowIconWdgt`, `WindowWithCroppingPanelIconWdgt`, `WindowWithScrollingPanelIconWdgt`, `SlidesToolbarIconWdgt`, `TextToolbarIconWdgt`, `EyeIconWdgt` | ~81 |
| `basic-widgets/Pin.coffee` | patch-programming "Pin" concept, never instantiated/extended; superseded by node-based patch system (its `augmentWith DeepCopierMixin` goes with it) | 25 |
| `ProfilerData.coffee` | empty `class ProfilerData` placeholder | 3 |
| `SimpleDocumentPanelWdgt.coffee` | 9-L class, unreferenced in BOTH repos (thin-subclass exemplar) | 9 |
| `basic-data-structures/Point.coffee:38` | `gt:` unreferenced (`.gt` grep: 0 hits both repos) | 2 |
| `graphs-plots-charts/Point3D.coffee:36` | `rotateZ:` unreferenced (only rotateX/rotateY used, `Example3DPlotWdgt.coffee:255`; the SW3D port's 3D math is `LCLTransforms`, not this) | 8 |
| `icons/DegreesConverterNodeIconWdgt.coffee` | NOT dead (class `DegreesConverterIconWdgt` is live) — but rename the FILE to match the class (filename==classname convention; build keys off it) | 0 |

(07-07 rows removed 2026-07-12: `WorldWdgt.removeEventListeners` — LIVE, called by `AutomatorPlayer.coffee:666`; Widget commented dim-alternatives — already deleted in `87dd5d7c`.)

⚠ Deleting the dead `*IconWdgt`s deletes ONLY the Wdgt files — every paired `*IconAppearance` is separately referenced (each by a `buttons/*CreatorButtonWdgt`, e.g. `AllPlotsIconAppearance` ← `PlotsToolbarCreatorButtonWdgt.coffee:5`; `EyeIconAppearance` ← `EditIconButtonWdgt.coffee:27`). Keep all appearances.
✅ `EyeIconWdgt` verified dead 2026-07-12: the pencil/eye edit-mode glyph is drawn via `EditIconButtonWdgt` + `PencilIconAppearance`/`EyeIconAppearance` (`WindowWdgt.coffee:553/561`), not via `EyeIconWdgt`.

#### Tier 3 — GATED (~401 L): whole experimental/dev-tool classes; verify retirement first

| File | What | ~L | Gate |
|---|---|---|---|
| `SystemInfo.coffee` | ⛔ NOT DEAD — KEEP. The test harness `SystemTestsSystemInfo` (`Fizzygum-tests/Automator-and-test-harness-src/SystemTestsSystemInfo.coffee`) **extends SystemInfo**, is instantiated by `scripts/run-macro-test-headless.js`, and is compiled into every non-homepage build. The 2026-07-12 "0 hits" re-verify only grepped `Fizzygum-tests/{tests,scripts}` and MISSED the harness source dir — deleting SystemInfo broke boot (`window["SystemInfo"].class` undefined at `meta/Class.coffee:116`). | 234 | — |
| `meta/SourceVault.coffee` + cluster | ✅ DELETED 2026-07-14 (`5fa62bde`+1, verifying). The console dev tool `SourceVault.runAllAnalyses()` + its private support cluster, all reachable ONLY from SourceVault: `meta/NonStaticPropertyOfClassSource.coffee` (6 L), `meta/Source.coffee` (13 L), `meta/ExtendableString.coffee` (35 L). 4 files / 221 L. Gate re-run against ALL of Fizzygum-tests incl. the harness dir: 0 refs. | 221 | — |

(07-07 row removed: `fizzytiles/LCLTransforms.coffee` — now LIVE, the SW3D matrix stack; see §0.3.)

**Known keep-list (grep-flagged but NOT dead — do not re-litigate):** `MacroToolkit`/`Macro` test-facing API; `SheetModel.colRowFor`/`valueAt`; `LCLProgramRunner.runProgram`/`runLastWorkingProgram` (subsystem entry points); `WorldWdgt.removeEventListeners` (Automator-called); explanatory-prose blocks at `ActivePointerWdgt.coffee:~161`, `SheetCellRecord.coffee:1-32`, `Widget.coffee:~732`/`2116-2125`-area/`3452-3477`-area, `ScrollPanelWdgt.coffee:378-392`, `VerticalStackLayoutSpec.coffee:55-69`, `meta/Class.coffee:65-79`, `WindowWdgt.coffee:471-476`, `LCLCodePreprocessor.coffee:525-531/923-928/~1558+`; live-code TODO at `Widget.coffee:4651` ("bad kludge").

---

### P3 — Input pipeline: one click-recognizer, one pointer-mode enum

**Rationale.** `processMouseUp` maintains two hand-mirrored copies of one recognition algorithm across six fields; the copy is the accidental part — click recognition itself is essential. The pointer's drag mode is a real tri-state that 23 `if` branches re-derive instead of reading a stored fact.

**Raw facts (re-captured 2026-07-12; none of these methods were `_`-renamed by the call-separation sweep — they are dispatcher/public surface):**
- `ActivePointerWdgt.coffee:702-868` `processMouseUp`: ~167 L, 8 indent levels. Mixes automator fade (`:703-707`), hit-test walk-up `until w[expectedClick]` (`:735-738`), left/right dispatch switch (`:742-746`), double-click recognition (`:748-806`), triple-click recognition (`:808-854`; comment at `:823-824`: "basically the same as the previous one"), click firing (`:847`), menu cleanup (`:857-865`).
- Mirrored state is **SIX fields, not four**: `@doubleClickWdgt`/`@tripleClickWdgt` (`:27-28`), `@doubleClickArmedAtEventTime`/`@tripleClickArmedAtEventTime` (`:32-33`), **plus the undeclared** `@doubleClickPosition`/`@tripleClickPosition` (set `:878/:895` in `_rememberDoubleClickWdgtsForAWhile`/`_rememberTripleClickWdgtsForAWhile`, cleared `:873/:890`, read `:774/:829` for the `< grabDragThreshold` proximity gate). `doubleClickWindowMs: 300` at `:37`. The arm/forget helpers are already `_`-tier: `_forgetDoubleClickWdgts` `:871`, `_rememberDoubleClickWdgtsForAWhile` `:876`, `_forgetTripleClickWdgts` `:888`, `_rememberTripleClickWdgtsForAWhile` `:893`.
- Mode derivation: `{idle | floatDrag | nonFloatDrag}` never stored; re-derived via `@children.length > 0` (float) OR `@nonFloatDraggedWdgt?` (non-float) through 3 predicates — `isThisPointerDraggingSomething` `:384`, `isThisPointerFloatDraggingSomething` `:387`, `isThisPointerNonFloatDraggingSomething` `:390` — consulted at **23 call sites**: ActivePointerWdgt ×11 (`:307,395,653,715,724,969,978,1079,1170,1256,1275`), SliderButtonWdgt ×3 (`:139,145,150`), ScrollPanelWdgt ×3 (`:570,572,702`), Example3DPlotWdgt ×1 (`:209`), ReconfigurablePaintWdgt ×5 (`:88,138,316,333,392`). Plus 2 raw `@nonFloatDraggedWdgt?` reads bypassing the predicates (`ActivePointerWdgt:864`, `Widget:3404`) → 25 total derivation sites.
- `drop` `:394-538` (~145 L, 6 levels — grew since 07-07: drag-embed SM re-run at `:399-408` and affine re-express/unwrap at `:454-510`); `determineGrabs` `:1078-1188` (~111 L) — 3-way `if isTemplate / else if detachesWhenDragged / else nonFloatDrag`, with the `checkDraggingTreshold` preamble (`[skipDragging, displacement]` + early return) duplicated **×2** (`:1092-1093` and `:1101-1102` — the non-float `else` arm has NO preamble; the 07-07 "×3" overcounted). `checkDraggingTreshold` itself at `:1047`.

**Hard constraints (do not violate):**
- Multi-click recognition keys off **EVENT timestamps**, never wall-clock (deterministic replay — see memory `multiclick-event-time-forget`). Preserve the arm/forget semantics exactly, INCLUDING the position-proximity gate.
- The `dragEmbed*` dwell fields (7, `:19-25`) are a documented deliberate state machine (drag-embed spec §6). UNTOUCHED — and `drop`'s run-SM-once-then-teardown ordering at `:399-408` must survive any extraction.
- Affine plane-mapping seams stay put: `@_pointerPositionInPlaneOf(w)` at the click-fire path (`:744,746,847` — untouched by the recognizer extraction); in `drop`, `_reExpressFigureForPlaneOfNoSettle` (`:462`) sits AFTER target choice and BEFORE `add`, with `_unwrapIfIdentitySugar` post-add (`:509-510`); in `determineGrabs`, `_resolvePickOutFigureNoSettle`/unwrap live inside the detaches arm (`:1116,1125-1126`) and plane-mapped offset capture at `:1140-1164`.
- Grab/pickUp vocabulary stays distinct (naming-plan non-goal). New/renamed methods must satisfy the public/private call-separation rules (§0.1).

**Conceptual sketch.**

```
[Current]  processMouseUp :702-868  (~167 L, 8 levels)
  fade → walk-up → L/R switch → [double-click block :748-806]
                              → [triple-click block :808-854 ≈ copy]
  mode read as:  @children.length > 0  OR  @nonFloatDraggedWdgt?   (× 25 sites)

[Proposed]
  processMouseUp (~50 L, ≤3 levels)
    return early unless w is @mouseDownWdgt
    for rec in [@doubleClick, @tripleClick]: rec.onMouseUp w, pos, eventTime
  MultiClickRecognizer: { wdgt, position, armedAtEventTime, clickCount }  # ONE body, ×2 instances
  @pointerMode ∈ {IDLE, FLOAT_DRAG, NON_FLOAT_DRAG}   # written at grab/drop only
  isThisPointerFloatDragging…: -> @pointerMode is FLOAT_DRAG      # predicates become reads
```

**Implementation sketch.**

```coffee
# new file: MultiClickRecognizer.coffee  (plain class; no complex static initializers)
+ class MultiClickRecognizer
+   constructor: (@clickCount) -> @wdgt = nil; @position = nil; @armedAtEventTime = nil
+   arm: (w, pos, eventTime) -> @wdgt = w; @position = pos; @armedAtEventTime = eventTime
+   forget: -> @wdgt = nil; @position = nil; @armedAtEventTime = nil
+   recognizes: (w, pos, eventTime, windowMs, proximityPx) ->
+     w is @wdgt and @armedAtEventTime? and
+       (eventTime - @armedAtEventTime) < windowMs and
+       pos.distanceTo(@position) < proximityPx      # transcribe the exact existing gates

# ActivePointerWdgt.coffee — the 6 mirrored fields collapse into 2 recognizers
+ @doubleClick = new MultiClickRecognizer 2
+ @tripleClick = new MultiClickRecognizer 3

# pointer mode — write at the two transitions…
+ @pointerMode = PointerMode.FLOAT_DRAG / NON_FLOAT_DRAG / IDLE
# …then 25 derivation sites collapse (23 predicate calls keep compiling as reads)

# determineGrabs — hoist the ×2 threshold preamble above the 3-way branch
+ [skipDragging, displacement] = @checkDraggingTreshold …   # once; else-arm ignores it as today
```

**Migration safety.** Keep the three predicate methods as one-line reads of `@pointerMode` during transition (all 23 sites keep compiling); also convert the 2 raw `@nonFloatDraggedWdgt?` reads (`ActivePointerWdgt:864`, `Widget:3404`) to the predicate; flip bodies first, verify suite, THEN inline if desired. ✅ Serialization: RESOLVED 2026-07-12 — the hand is a well-known object; its fields are never snapshotted (`Serializer.coffee:88`, reference §11). Not a snapshot-format change.

---

### P4 — `ScrollPanelWdgt.mouseDownLeft`: extract the triplicated scroll-delta skeleton

**Rationale.** One ~118-line closure mixes per-frame drag sampling, collapsed-drag recovery, release flush, and momentum — and pastes the same guard+scroll skeleton at `:584-593`, `:626-635`, `:657-666`. Three copies of one rule-shape = three places for the next scrollbar change to go wrong.

**Raw facts (re-captured 2026-07-12):** `basic-widgets/ScrollPanelWdgt.coffee:554-671`, ~118 L, 8 indent levels; inline `@step` closure `:570-670`. Related boolean set (NOT layout-suppression; fine to leave): `isScrollingByfloatDragging` (`:7`), `canScrollByDraggingBackground` (`:20`), `canScrollByDraggingForeground` (`:21`). No affine plane-mapping inside this method (`@step` deliberately reads raw screen space via `world.hand.position()`; the `pos` arg is plane-mapped upstream by the dispatcher).

**⚠ RE-DIFF VERDICT (2026-07-12): the three blocks are NOT verbatim copies.** What's shared and what differs:
- **Guards ARE byte-identical ×3**: `if @hBar.visibleBasedOnIsVisibleProperty() and !@hBar.isInCollapsedSubtree()` (+ the vBar twin). (The 07-07 sketch's `@hBar.isVisible`/`@hBarCollapsed` names were approximations — use the real API.)
- **Delta source differs per block**: A (`:584-593`, per-frame sample) `newPos - oldPos`; B (`:626-635`, release flush, one indent deeper) `releasePos - oldPos`; C (`:657-666`, momentum glide) `deltaX * friction`.
- **Block C rounds — A and B do not**: C fires `@scrollX Math.round deltaX`; A/B fire `@scrollX deltaX`. A shared helper that drops the rounding CHANGES glide behavior.
- **Block C's friction decay happens INSIDE the visibility guard** — an invisible bar leaves the delta un-decayed for the next frame. Hoisting the delta computation out of the guard changes that too.

**Conceptual sketch (amended).**

```
[Current] @step closure                      [Proposed]
  ├─ sample drag frame → [skeleton A]         each site keeps computing ITS OWN delta
  ├─ collapsed-recovery → [skeleton B]        (and C its in-guard decay + rounding);
  └─ momentum glide     → [skeleton C]        only the guard + scrollX/scrollY skeleton unifies:
                                              _applyScrollDelta dxFn, dyFn   — or equivalent
```

**Implementation sketch.**

```coffee
# The safe common core is the GUARD + CALL skeleton, not the whole block.
# One workable shape (callbacks so C keeps its in-guard decay + Math.round):
+ _applyScrollDelta: (computeDx, computeDy) ->
+   if @hBar.visibleBasedOnIsVisibleProperty() and !@hBar.isInCollapsedSubtree()
+     dx = computeDx()
+     scrollbarJustChanged ||= @scrollX dx if dx isnt 0     # thread the flag per current code
+   if @vBar.visibleBasedOnIsVisibleProperty() and !@vBar.isInCollapsedSubtree()
+     dy = computeDy()
+     scrollbarJustChanged ||= @scrollY dy if dy isnt 0
# If the callback shape reads worse than the duplication, a legitimate verdict here is
# LEAVE-AS-IS: with the deltas and rounding genuinely differing, the accidental part is
# smaller than the 07-07 audit believed. Decide at edit time; do not force it.
```

⚠ Transcribe the guard conditions and each block's delta/rounding EXACTLY. Momentum/glide behavior is timing-sensitive under `?speed=`; the suite covers it.
⚠ Do not touch `_positionAndResizeChildren` here — layout-owned.

---

### P5 — Retire positional-boolean/nil argument soup (defaults + options objects)

**Rationale.** `addMenuItem label, true, @, 'action', nil,nil,nil,nil,nil, each, nil, true` is write-only code. CoffeeScript has default parameter values and destructured options natively (`({a = 1} = {}) ->`) — this is bloat the language already solves. Highest-payoff item NOT covered by the layering-naming plan (confirmed: arity/positional-args are outside its scope).

**Raw facts (re-captured 2026-07-12):**
- 242 non-comment lines with ≥2 consecutive bare `true/false/nil` args; **110 with ≥3** (the 07-07 "94 for ≥2" was impossible — ≥2 is a superset of ≥3). Top ≥3 offenders: MacroToolkit 13, ChangeFontButtonWdgt 9, StringWdgt 9, MenusHelper 9, TemplatesWindowWdgt 9, Wallpaper 7, WindowWdgt 5, WelcomeMessageInfoWdgt 5, Widget 5.
- Worst sites (12 positional each): `HandleWdgt.coffee:368` — `menu.addMenuItem (each.toString()…) + " ➜", true, @, 'makeHandleSolidWithParentWidget', nil, nil, nil, nil, nil, each, nil, true`; `SimpleRasterImageButtonWdgt.coffee:27` — `super true, target, action, @rasterImageWdgt, nil, nil, nil, nil, argumentToAction1,nil,nil,2`.
- `addMenuItem` (`MenuWdgt.coffee:120`) and `prependMenuItem` (`:125`) are both 12-positional: `(label, ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked, target, action, toolTipMessage, color, bold, italic, doubleClickAction, arg1, arg2, representsAWidget)`. **Partially pre-done:** the internal `createMenuItem` (`:88`) already takes a `MenuItemSpec` object — only the public wrappers remain positional, and a NOTE at `:116-119` says that was deliberate scope-limiting, not a decision against this plan.
- `WindowWdgt` `@_addNoSettle child, nil, nil, nil, true` ×5: `:483` (titlebarBackground), `:518` (label), `:524` (closeButton), `:531` (collapse switch), `:573` (editButton).
- `new WindowWdgt nil, nil, …` — ALL **56** `new WindowWdgt` sites in src start `nil, nil`: WorldWdgt `:567/:1482/:2468`, WidgetFactory `:95/:101`, MenusHelper `:158/:166/:177/:193/:201/:549/:555`, ~16 `buttons/*CreatorButtonWdgt`, MacroToolkit ×2, ~10 `info-widgets/*`, ~14 `apps/*`. (Blast radius is repo-wide, not the 6 sites the 07-07 audit cited.)
- `MenuWdgt.coffee:19` ctor — the REAL current signature (8 params; the 07-07 sketch understated it):
  `constructor: (@widgetOpeningThePopUp, @isListContents = false, @target, @killThisPopUpIfClickOutsideDescendants = true, @killThisPopUpIfClickOnDescendantsTriggers = true, @title = nil, @environment = nil, @fontSize = nil) ->`
  47 `new MenuWdgt` sites; **46 of 47** pass exactly `…, false, …, true, true`; the sole deviation is the listContents build at `ListWdgt.coffee:65` (`new MenuWdgt @, true, @, false, false, nil, nil`). Note `ba7a0c6b` (menu/slider ctor conversion) did NOT change this signature — it only moved the label build into `_buildMenuLabel`/`_buildMenuLabelNoSettle` (`:43/:46`).
- Related (P6 overlap): `PopUpWdgt.coffee:13-15,55` — the two kill-flags are always set as a coordinated pair (`:78-79` pinPopUp, `:98-99` fullCopy) = one `dismissPolicy`.

**Conceptual sketch.**

```
[Current]                                    [Proposed]
addMenuItem(12 positional slots)             addMenuItem label, target, action, opts = {}
                                               (or: expose the EXISTING MenuItemSpec — createMenuItem
                                                already takes one; finish that conversion outward)
new MenuWdgt @, false, @, true, true, …      new MenuWdgt @, target: @, title: … # 3 flags defaulted;
                                                                    # only ListWdgt.coffee:65 overrides
_addNoSettle child, nil,nil,nil, true        _addNoSettle child, silently: true
new WindowWdgt nil, nil, content             new WindowWdgt content: content    # ⚠ 56 sites
```

**Migration order (per-family, `fg presuite` after EACH family):**
1. `addMenuItem`/`prependMenuItem` family (largest site count, no serialization exposure; ride the existing `MenuItemSpec` rather than inventing a second options shape)
2. `MenuWdgt` ctor (47 sites)
3. `WindowWdgt` ctor (56 sites — bigger than the 07-07 estimate; budget accordingly)
4. `_addNoSettle` (⚠ settle-axis method — respect the caller-allowlist gates [O]/[P] in the naming plan AND the call-separation rules [S]/[T]/[U]; the options-object change must not alter which callers are allowlisted)

**Risks.**
- Constructor-arg reordering interacts with `DeepCopierMixin` (18 use sites) and serialization arg order — grep `docs/architecture/serialization-duplication-reference.md` + the Deserializer for per-class ctor-arg assumptions before touching each ctor.
- Button `super …, 2` chains (`SimpleRasterImageButtonWdgt.coffee:27`): converting a base-class signature ripples through every subclass `super` — do the button family as ONE atomic batch.
- MenuWdgt: do not disturb the `_buildMenuLabel` pair or ctor-build behavior (owned by the completed menu/slider ctor-conversion plan).

---

### P6 — Spec-class and marker-class rationalization

**Rationale.** Named-boolean "Spec" classes are a good convention — but single-valued ones make readers load axes that don't exist. **Check first: read each file's header.** (2026-07-12: the two FittingSpec headers carry a "SHIPS in the homepage build — do NOT re-add a homepage-exclusion header" warning — that does NOT block deletion/inlining, it only means the inlined behavior must stay in the homepage build.)

**Findings & actions (all re-verified 2026-07-12):**

| Item | Evidence | Action |
|---|---|---|
| `FittingSpecTextBoxFittingTextTightOrLoose` | 1 ref total: `StringWdgt.coffee:141` (`fittingSpecBoxTightOrLoose: ….TIGHT`); file header admits `.LOOSE` "not yet exercised" | Delete file; inline behavior + breadcrumb comment |
| `FittingSpecTextBoxFittingTextWhichDimensionAdjusts` | 1 ref: `StringWdgt.coffee:142`, only `.HEIGHT_ADJUSTS_TO_WIDTH`; other value "not exercised" | Delete file; inline + breadcrumb |
| `FittingSpecText`, `…InLargerBounds`, `…InSmallerBounds` | both values used in all three (FIT_BOX_TO_TEXT 15/FIT_TEXT_TO_BOX 1; FLOAT 6/SCALEUP 11; CROP 6/SCALEDOWN 13) | KEEP — legit named booleans |
| `LayoutSpec.coffee` (63 L) | `SPREADABILITY_LOW` (`:60`) 0 uses; commented-out enum blocks `:17/:22-25/:28-32`; lone survivor `ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED` (`:21`) 74 uses, still carries phantom-enum baggage in its name | Delete dead const + commented blocks (P2-Tier1); OPTIONAL: rename the survivor (74 sites — owner call; grep tests repo too) |
| `PreferredSize.coffee` (7 L) | 2 consts (`THIS_ONE_I_HAVE_NOW: -1` / `DONT_MIND: -2`); consumers BROADER than the 07-07 note: passed into `new WindowContentLayoutSpec` from 6 classes (Widget:299, SliderWdgt:86, MenuWdgt:60, PaletteWdgt:29, SimplePlainTextScrollPanelWdgt:46, WindowContentsPlaceholderText:14), compared in WindowWdgt `:615/:622/:644/:650` AND inside WindowContentLayoutSpec itself (`:49`) | Fold as statics onto `WindowContentLayoutSpec`; delete file (all consumers use `PreferredSize.X` — mechanical) |
| `extendable-base-classes/` | whole dir = 1 file (`ExtendableString`), 1 subclass (`meta/Source.coffee:3`) | Move `ExtendableString.coffee` next to its sole user; delete the directory (misleading signpost) |
| `InputDOMElementForVirtualKeyboardKeydownInputEvent` / `…KeyupInputEvent` | 1 non-comment line each; **the Keyup one still `extends KeydownInputEvent` — wrong parent** (latent trap, re-verified). Used only at `WorldWdgt.coffee:1838/1856` (`.fromBrowserEvent` construction — no type-tests on the class names) | Either give real behavior (fix the parent!) or replace with a `viaVirtualKeyboard` flag on the base |
| `AlignmentSpecHorizontal` / `AlignmentSpecVertical` | 3 consts each, one shared numbering space (0-2 / 3-5); sole consumers StringWdgt (+TextWdgt `:534/:536`) | OPTIONAL/LOW: merge into one `AlignmentSpec` or statics on StringWdgt — all values used, so only file-count savings. Skip unless passing by |
| `CreateShortcutOfDroppedItemsMixin` | 1 `augmentWith` (`FolderPanelWdgt.coffee:25`) | OPTIONAL/LOW: inline into FolderPanelWdgt if it will never be shared |
| `WidgetFactory.coffee` (415 L) | NOT a factory pattern — flat parts-bin of hardcoded `createNewXxx` + demo scenes (`setupTestScreen1` `:160-415`, 256 L); homepage-excluded | No refactor. OPTIONAL: rename to stop it reading as core infrastructure |

**Implementation sketch (the two deletions).**

```coffee
# StringWdgt.coffee:141-142 — the only reference sites in the codebase
- fittingSpecBoxTightOrLoose: FittingSpecTextBoxFittingTextTightOrLoose.TIGHT
- fittingSpecWhichDimensionAdjusts: FittingSpecTextBoxFittingTextWhichDimensionAdjusts.HEIGHT_ADJUSTS_TO_WIDTH
+ # tight box, height-adjusts-to-width: the only behavior ever built.
+ # (Was a 2-axis FittingSpec pair; re-introduce an axis only when a second value ships.)
# then delete both FittingSpec*.coffee files; grep both repos for the class names first
# (transcribe the real field names/consumer logic at edit time — the two fields are consulted
#  by StringWdgt's fitting logic; behavior must stay in the homepage build per the headers)
```

---

### P7 — Turn branch-shaped data into tables

**Rationale.** A `switch` whose every arm is `value → constant` is data wearing control-flow clothing. Three instances, all behavior-preserving. (Shapes re-characterized 2026-07-12 — read the corrected descriptions before editing.)

| Site | Shape (as actually found 2026-07-12) | Table form |
|---|---|---|
| `basic-widgets/StringWdgt.coffee:1008-1026` | Inside `updateFontsMenuEntriesTicks:` — a 9-arm `switch` on the CURRENT FONT-STACK VALUE (`@fontName` already HOLDS a stack string; the 9 stacks are named instance props at `:160-168`) choosing which of 9 tick-flag variables to set, followed by 9 label-update lines (`:1028-1036`). NOT a name→stack lookup (the 07-07 row mischaracterized it) | An ordered `[stackProp, menuIndex]` pairs table + one loop that compares-and-ticks — kills both the switch AND the 9 label lines |
| `serialization/Deserializer.coffee:70-81` AND `:128-168` | TWO parallel `switch record.class` dispatchers over the tag family `"$Array","$Object","$Set","$Map","$Date","$Image","$Canvas","$Video","Color"`. NOT identical tag sets: pass-1 `@instantiate` (`:128-168`) builds all 9; pass-2 populate/link (`:70-81`) acts on Array/Set/Map and groups the other five as an explicit no-op arm | ONE `TAG_BUILDERS = {tag: {build, populate}}` registry consulted by both sites — kills the parallel-switch drift risk while keeping the asymmetry explicit |
| `basic-widgets/CaretWdgt.coffee:73-121` (+ `_ctrl:` `:488`, `cmd:` `:495`) | Main `switch key` with 13 `when` clauses + `else` (nested `if`s only inside the Tab/Enter arms), guarded by an `if ctrlKey / else if metaKey` at `:68-72`; the ctrl/cmd switches have 2 arms each. (07-07's "17 arms" = 13+2+2 summed across all three) | `KEY_HANDLERS = {ArrowLeft: '_caretLeft', …}` — arms become named methods; nested logic moves into them |

**Left alone (right-sized):** `StringWdgt.coffee:669-675/678-684` 3-arm alignment switches; `Widget._reLayout` corner-chain (layout-owned — see §3); `FridgeMagnetsCanvasWdgt` game logic; `HandleWdgt`/`SpreadsheetWdgt` 8-arm switches (borderline, skip).

**Implementation sketch.**

```coffee
# StringWdgt — the pairs table replaces switch + label lines (mind the fragment-compile
#  gate: keep the class-level initializer a simple literal)
# Deserializer — one registry, two consumers; give populate-side no-op tags an explicit no-op fn
+ TAG_BUILDERS = "$Array": {build: (r) -> …, populate: (r) -> …}, …
```

⚠ CaretWdgt keymap is the riskiest of the three (modifier interactions inside arms) — do it last, arm-by-arm, keeping arm bodies byte-identical inside the named handlers.

---

### P8 — Utility consolidation (small, near-zero-risk)

**Rationale.** Two copies of the same deterministic string hash is a fork waiting to diverge — and it's cache-key/test-reference-filename critical, so divergence would be expensive. The rest is native-replacement housekeeping. (Audit verdict: utilities are otherwise clean — the custom infra that exists is justified.)

| Item | Location (2026-07-12) | Action | Sites |
|---|---|---|---|
| `Object::hashCode` ↔ `HashCalculator.calculateHash` | `Object-extensions.coffee:61-82` / `HashCalculator.coffee:18-99` — same Java string hash BY VALUE; ⚠ **no longer byte-similar**: `hashCode` gained the O2 memoization wrapper (LRU-ish string cache, worth 1.5–5.4% of a busy frame), `calculateHash` is the plain loop (its `& 0xFFFF` and stray `i++` are verified no-ops). Both files still carry TODOs pointing at each other (`:47`/`:10`) | **Direction flipped from 07-07:** keep the memoized `Object::hashCode`; make `calculateHash` delegate to it (or extract one shared plain core the memoized wrapper calls). NEVER `hashCode = -> HashCalculator.calculateHash @` — that would silently drop the O2 memoization. ⚠ determinism-critical: identical VALUES, verify via suite (hashCode drives caches, calculateHash drives test-reference filenames — divergence would be invisible until reference mismatch) | 12 (src) + 2 (tests: `SystemTestsReferenceImage.coffee:30,31`) |
| `Number::times` / `Number::timesWithVariable` | `numbertimes.coffee:43/:35` — byte-identical bodies (re-verified). Consumers are exclusively **fizzytiles LCL TEXT**: preprocessor-generated strings + `.coffee.txt` fixtures; zero direct source calls elsewhere | Alias one to the other; KEEP both spellings (the preprocessor emits both) | fizzytiles-only |
| `Array::chunk` | `Array-extensions.coffee:32-35` | **KEEP — flipped 2026-07-12:** used by the test harness (`AutomatorLoader.coffee:224`, shard/group partitioning). Add a breadcrumb comment naming the consumer | 1 (tests) |
| `Array::unique` | `Array-extensions.coffee:49-52` | DELETE (0 sites both repos; buggy string-key dedup anyway) | 0 |
| `Array::uniqueKeepOrder` | `Array-extensions.coffee:58-62` | → `[...new Set(a)]` (Set preserves insertion order) | 2 (`Widget.coffee:4147,4148`) |
| `Array::shallowCopy` | `Array-extensions.coffee:5-6` (`@concat()`) | → `slice()` at sites; delete ext | 2 live (`TreeNode:393`, `VideoPlayerWithRecommendationsWdgt:64`) + 1 comment |
| `Array::remove` | `Array-extensions.coffee:41-45` | OPTIONAL rename → `removeElement` (collides with `LRUCache.remove`→DoubleLinkedList / DOM `remove` — collision re-confirmed) | 4 (`IconicDesktopSystemLinkWdgt:15,19`, `TreeNode:121,395`) |
| `Utils.isString`/`isObject` | `Utils.coffee:6/:9` | inline as `typeof` (3 + 1 sites). `isFunction` (now ~56 sites) KEEP — readability | 3+1 |
| `String` tick family | `String-extensions.coffee:8-41` — 5 interlocking methods for menu checkmarks | OPTIONAL: consolidate to `setTicked(bool)` + `isTicked`. Note `untick` has **0 callers** (deletable member even if the family stays) | isTicked 2, tick 3, untick 0, isUnticked 1, toggleTick 2 |
| `SLOW*` prefix (**17 defs**, was 8) | Original 8 (TreeNode `:171,478` + Widget `:992,1029,1037,1057,1069,2695`) + 9 overrides added by the Tier-J/affine arcs: TransformFrameWdgt `:630,654,679`, WorldWdgt `:802,805`, ActivePointerWdgt `:69,72`, ClippingAtRectangularBoundsMixin `:48,51` | OPTIONAL rename → `*Uncached`. ⚠ scope grew: 17 defs + ~15 Widget-internal refs; the world+hand SLOW twins now live in MAIN src (WorldWdgt/ActivePointerWdgt overrides), and the tests repo carries only read-only oracle-audit references (2 test `.js` + cache-oracle prelude comments) — still grep it before renaming | — |

**Keep-list (justified custom infra — documented here so it isn't re-flagged):** `Array::deepCopy` + `Date/Map/Set::deepCopy` (prototype-preserving graph copier — `structuredClone` would break class identity and widget share-vs-copy semantics); `extend()` at `globalFunctions.coffee:447` (used by `meta/Class.coffee:342` to assemble hierarchy from runtime-compiled source — the live-editing engine; document rationale in-place, do not remove); vendored `LRUCache`/`DoubleLinkedList` (age/dispose eviction; consumers = `Color._cache` **plus WorldWdgt's 7 text/back-buffer caches** `:487-493` — the 07-07 "sole consumer" note was wrong; `DoubleLinkedList` IS sole-consumed by LRUCache); `Math.getRandomInt` (✅ investigated 2026-07-12: sole use `BouncerWdgt.coffee:19`, a demo — no render/layout-path use; leave); `Number::toRadians`/`toDegrees`.

---

### P9 — Desktop-shell dedup: shortcuts + MenusHelper (~150 lines)

**Rationale.** Three shortcut classes paste the same ~30-line "bring up the target" ritual their shared base could own; `MenusHelper.coffee` (874 L, 123 methods) is 53 one-line `createX: -> world.create new XWdgt` wrappers plus 7 window-open blocks.

**Raw facts (re-verified 2026-07-12 — the ritual core is BYTE-IDENTICAL ×3, confirmed programmatically):**
- The ~30-L ritual (dead-target guard, `isAncestorOf` guard, `@target.show()`, `whatToBringUp = @target.findRootForGrab()` cascade with its comment, `spawnNextTo`/`_rememberFractionalSituationInHoldingPanel()` — note the underscore, renamed by the call-separation sweep — /`setTitle`) appears at: `IconicDesktopSystemDocumentShortcutWdgt` `mouseClickLeft` `:14-47` (core `:18-47`), `IconicDesktopSystemFolderShortcutWdgt` `mouseClickLeft` `:18-51` (core `:22-51`), `IconicDesktopSystemScriptShortcutWdgt` `editScript` `:34-63`. Document/Folder `mouseClickLeft` bodies are byte-identical in full; Script's `editScript` = the same 30-L core minus the leading `doubleClickInvocation` guard (Script also has an extra short guard in its own `mouseClickLeft` `:21-23`). All three extend `IconicDesktopSystemShortcutWdgt` (55 L base — no shared method exists yet; `bringUpTarget` greps 0). The `"The referenced item…"` / `"is dead!"` strings recur across all three (Script ×4/×2).
- `MenusHelper.coffee`: 874 L (byte-unchanged since 07-07), 123 method defs; 73 methods contain `world.create`; **53** are trivial one-liners. **7** window-open blocks at `:158/:166/:177/:193/:201` (full verbatim shape: `new WindowWdgt` + `setExtent` + `moveTo world.hand.position().subtract …` + `moveWithin world` + `world.add wm`) **+ `:549/:555`** (partial variant: no `setExtent`/`moveTo`) — so the helper needs an optional-extent/position shape, not one rigid block.
- String-dispatch risk re-confirmed with live examples: `"createDestroyIconWdgt"` (`MenusHelper.coffee:512`), `"createBrushIconWdgt"` (`:212`), `"makeBouncingParticle"` (`:812`) — menu items dispatch to these BY STRING.

**Conceptual sketch.**

```
[Current]                                        [Proposed]
IconicDesktopSystemShortcutWdgt (base)           base gains bringUpTarget()
 ├─ Document…  mouseClickLeft: [30-L ritual]      ├─ Document…: mouseClickLeft: -> @bringUpTarget()
 ├─ Folder…    mouseClickLeft: [30-L ritual]      ├─ Folder…:   mouseClickLeft: -> @bringUpTarget()
 └─ Script…    editScript:     [30-L ritual]      └─ Script…:   editScript:     -> @bringUpTarget()

MenusHelper: 53 hand-written create methods      CREATABLE table + one generic action
             7× window-open block (5 full/2 partial)  openInWindow(wdgt, extent?) helper ×1
```

**Implementation sketch.**

```coffee
# IconicDesktopSystemShortcutWdgt.coffee
+ bringUpTarget: ->
+   # the ONE canonical copy of the guard/show/findRootForGrab/spawnNextTo cascade,
+   # transcribed byte-faithfully from the Document… variant, incl. its comment.
+   # (Document/Folder keep their doubleClickInvocation guard at the call site;
+   #  Script's editScript calls it directly — re-diff at edit time.)
```

```coffee
# MenusHelper.coffee
- createBarPlotWdgt: -> world.create new BarPlotWdgt          # ×53
+ # table + one generic creator. CRITICAL: keep explicit `new X` / class-name
+ # tokens in the table so the build's regex dependency-scanner still sees
+ # every icon/widget class edge (same constraint that keeps createAppearance
+ # a method — see §3). e.g.:
+ @CREATABLE = 'Bar plot': -> new BarPlotWdgt, …
- wm = new WindowWdgt …; …; world.add wm                      # ×7 (5 full + 2 partial)
+ @openInWindow contents, extent   # extent/moveTo optional to cover the 2 partial sites
```

⚠ Before collapsing MenusHelper methods: menu items dispatch to these by STRING method name — grep each method name as a string across BOTH repos (menus + test macros). Where a name is string-dispatched, keep a thin named method delegating to the table (the one-liner wrap form, per the thin-wraps convention). This also keeps the call-separation plan happy: action strings are public surface.
⚠ New methods on the shortcut base must respect the call-separation rules ([S]/[T]/[U]) — `bringUpTarget` drives public settling API on OTHER widgets, which per that plan's [A]-collision lesson means it stays PUBLIC (allowlist if flagged), not `_`-tier.

---

## 3. Guardrails: deliberately NOT proposed (essential, constrained, or plan-owned)

- **`meta/Class.coffee` (446 L) + `Mixin.coffee`** — runtime per-property source parsing, per-method hot-reload (`notifyInstancesOfSourceChange`), instance registries (`registerThisInstance`, `.instances` Sets), manual `super` text-translation, 3 build modes. This IS the live-coding product. The hand-rolled `extend()` (`globalFunctions.coffee:447`) exists for it. Document, never remove.
- **85 one-liner `createAppearance: -> new XIconAppearance @` subclasses (~630 L)** — knowingly-accepted boilerplate: `IconWdgt.coffee:10-11` documents that `createAppearance` is deliberately a METHOD so the build's dependency-finder sees the `new XIconAppearance` edge for file ordering. Eliminating them = build-tooling change, out of scope.
- **`Widget`'s cache/stamp/`SLOW*`-oracle triplets** — intentional memoization, standardized by the completed Tier-J bounds-cache campaign (one `checkFullBoundsCache` idiom; the SLOW oracle surface has since grown to 17 defs — see P8 — with world+hand+TransformFrame overrides as deliberate coherence mirrors). A generic `memoizedByGeometryVersion(key, fn)` helper is conceivable but interacts with shipped coherence gates — skip unless that area reopens.
- **Everything layout-convergence** (see §0.1). P3/P4 touch only *shape* (nesting, duplication), never settle semantics. `WindowWdgt._positionAndResizeChildren` (`:585-747`, 163 L) and `Widget._reLayout` (`:4633-4788`, 156 L, incl. the `LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_*` chain at `:4677-4687`) are extraction candidates (`_layoutTitleBar`/`_layoutButtons`/`_layoutContents`; corner-dispatch table) but sit ON the plan-owned seam — defer to whenever the proper-layouts arc next touches those methods, then extract opportunistically. (`_reLayoutSelf` is a distinct empty base stub at `Widget.coffee:3103` since `87dd5d7c` — don't confuse the two.)
- **`WorldWdgt.updateBroken` (`:1181-1269`, 89 L)** — broken-rectangles paint loop; since 07-07 this territory also hosts the LANDED occlusion-culling and island-buffer-cache features. Candidate for extracting region-collection from painting, but it is the hot paint path AND now feature-laden: only with the profiler open and those plans' docs beside you, not as part of this plan.
- **Long-but-flat methods (length ≠ complexity):** `InspectorWdgt._buildAndConnectChildrenNoSettle` (`:156-362`, 207 L builder), `MacroToolkit.standardMacroSubroutines` (~212 L registration list), `SystemInfo.constructor` (205 L), `WidgetFactory.setupTestScreen1` (`:160-415`, 256 L demo), `FridgeMagnets3DCanvasWdgt` SW3D setup, `meta/Class.constructor` (186 L parse), `LCLCodePreprocessor` transforms (141/139/156 L string rewrites). Straight-line; leave.
- **`Widget.coffee`'s ~24 boolean fields** — audited: independent base-class flags (isVisible, collapsed, isTemplate, …), NOT an implicit enum. `PreferencesAndSettings` (18) = settings bag. Leave. (Contrast: `PopUpWdgt`'s kill-flag pair IS a lifecycle micro-machine — folded into P5/P6 via the dismissPolicy option.)
- **`apps/ReconfigurablePaintWdgt.coffee`** tops every indentation scan — it's `sourceCodeToBeInjected` heredoc STRING LITERALS, not control flow. Same for `paintFunction` bodies in icons/maps (straight-line canvas calls). Scan artifacts, not findings.

## 4. Sequencing, effort, and verification summary

| Order | Plan | ~Lines | Risk | Verify |
|---|---|---|---|---|
| 1 | P2 Tier 1 (certain dead) | ~193 | none | presuite |
| 2 | P8 utilities | ~30 | near-zero (hash: value-identical, keep the memoized side) | presuite |
| 3 | P6 spec/marker classes | ~60 | low (honor the SHIPS-in-homepage headers) | presuite |
| 4 | P1 icon layer | ~570-640 | low, mechanical, 3 batches (amended prototype-prop sketch) | presuite per batch |
| 5 | P9 shell dedup | ~150 | low (string-dispatch grep; call-separation rules) | presuite |
| 6 | P2 Tier 2 (likely dead) | ~172 | low (two-repo grep gate, corrected paths) | presuite |
| 7 | P7 dispatch tables | ~0 (shape) | low→med (Caret last) | presuite |
| 8 | P4 scroll-delta | ~20 | med (timing-sensitive; blocks NOT verbatim — leave-as-is is a legitimate verdict) | presuite + gauntlet |
| 9 | P3 input pipeline | ~120 | med (event-time + position-proximity semantics; serialization ✅ resolved non-blocking) | presuite + gauntlet |
| 10 | P5 positional args | ~0 (shape) | med-high (ctor/serialization ripple; WindowWdgt = 56 sites) | presuite PER FAMILY + gauntlet |
| — | P2 Tier 3 (gated classes) | ~401 | decision-gated (SystemInfo, SourceVault — owner decision first) | owner decision first |

- Inner-loop runs are cheap (`fg presuite` ≈ 3.5 min; bare `fg build && fg suite` also fine) — run per batch, not per file.
- Finish each landed plan with `fg gauntlet` (parallel, ~4.5-5 min); a recapture is only acceptable for benign inspector member-list diffs (owner policy) — any OTHER pixel diff means the change was NOT behavior-preserving: stop and re-frame (and per owner rule, after 2 falsified fix shapes, stop iterating variants).
- ⚠ Method renames/extractions in inspected classes churn the 15-test inspector set — `fg recapture-inspector` once per batch if flagged.
- If the public/private call-separation sweep is still uncommitted when this plan starts, coordinate: land that first (its ~81 renames move many of the line numbers above) or rebase this plan's greps after it lands.
- Commit policy: present summary + message, wait for explicit approval; never claim "verified"/"pixel-identical" in docs or commit messages before the suite has actually passed.
