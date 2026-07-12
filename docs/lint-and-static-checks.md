# Fizzygum build-time lint & static-checks — reference

**What this is.** The durable, living reference for Fizzygum's build-time checking system — every gate that
`build_it_please.sh` runs, what each enforces, how they're wired, the predicates and rules they key off, the in-code
markers that exempt a line, the reasoned boundaries (what is deliberately *not* checked, and why), and how to extend or
debug the system. Written to be picked up **cold** by a maintainer with no prior context.

**What this is NOT.** It is not the *why* of the runtime layout architecture — for the flush model, the settle tiers,
the convergence loop, and the invariant these gates protect, see **`docs/layout-system-architecture-assessment.md`**
(the engine) — this doc says *what is checked + how to extend*; that one says *why*. It is also not a to-do: the arc
that built rule [G] and these notes is recorded in **`docs/lint-ratchet-static-checks-plan.md`** (STATUS: EXECUTED),
which now points *here* for current state and keeps only the execution / rejected-transitive history.

> **Orientation.** Fizzygum ships its ~470 class/mixin sources as escaped TEXT and compiles them *in-browser* at boot
> (no module system; every class is a global). The build only runs `coffee` over `src/boot/*`. So a green build had,
> historically, never checked the *syntax* — let alone the *flow soundness* — of the class files; a fault surfaced only
> when a human opened the build in a browser. These gates close that gap at build time. They are **pure tooling**
> (`buildSystem/*.js` is not compiled into the world): editing a gate needs no behaviour rebuild, only a re-run of the
> build to see the verdict; a gate edit *cannot* change a screenshot.

---

## 1. The runtime invariant the layering gate protects (summary)

**THE INVARIANT: one flush per OUTERMOST public mutation; low-level code never settles.** A *public* geometry/structure
mutator (`setExtent`/`setBounds`/`setWidth`/`setHeight`/`moveTo`, the text setters, `add`/`destroy`/`close`/
`fullDestroy`/`collapse`/`unCollapse`/…) leaves the world consistent on return by self-settling through the single
settle tier `_settleLayoutsAfter` (`Widget.coffee`), which sets `world._inLayoutMutation`, runs the mutation's
non-settling core, then flushes `recalculateLayouts()` **exactly once**. Nested public calls must NOT each open their
own flush — internal/low-level code is *forced* onto the non-settling `_<name>NoSettle` cores and the raw/silent
setters, which schedule nothing. (Depth: `docs/layout-system-architecture-assessment.md`.)

**Two RUNTIME backstops** raise this from convention to a checked property — the static gates make the same checks
*exhaustive and preventive*, and catch the name-recognized/direct cases at build time; the throws backstop the
**dynamic/transitive** cases the name-scanner cannot see:

| Runtime throw | Where (grep the symbol; lines drift) | Fires when | Static twin |
|---|---|---|---|
| One-flush re-entrancy | `Widget.coffee` `_settleLayoutsAfter` (~:813) | a public geometry setter is reached on an *attached* widget while `_inLayoutMutation`/`_recalculatingLayouts` is already true | rules **[A]/[G]** (low-level code must not reach the public/wrapper layer) |
| `FLOWRULE_VIOLATION` | `Widget.coffee` `_invalidateLayout` (~:3848) | an immediate-mutator corner/convenience (`_apply*`/`_commit*`/`_move*`) schedules layout during a pass | rule **[E]** |

The gates "cannot be spoofed" (they read all shipped source, not a runtime token) but only see what a NAME scanner can;
the throws see the real dynamic receiver but only on tested paths. They are complementary.

---

## 2. The tier predicates — the single source of truth

The layout-method layering is **formally defined**, once, in `buildSystem/check-layering.js`. Two nested tiers:

```js
// LOW-LEVEL (rule [A]/[G] subject): must not reach UP into the public self-flushing layer.
const isLowLevel = (name) =>
  /^_/.test(name) ||          // any leading underscore — the _ internal + __ leaf private tiers
  /NoSettle$/.test(name);     // the *NoSettle cores
// (the old /^raw[A-Z]/ arm is retired: zero raw* defs exist in src; rule [M] keeps them out)
// the strict INNER subset (rule [E] subject): may MUTATE geometry, never SCHEDULE.
const isImmediateMutator = (name) =>
  /^_apply(Extent|Bounds|Width|Height|MoveBy|MoveTo)$/.test(name) ||            // the polymorphic apply corners (bare _apply*, ex *AndNotify — Tier B; NB _apply*Base is NOT matched)
  /^_commit(Extent|Bounds)AndNotify$/.test(name) ||                             // notify-only corners
  /^_move(LeftSideTo|RightSideTo|TopSideTo|BottomSideTo|ToSideOf|FullCenterTo|Within|InDesktopToFractionalPosition|InStretchablePanelToFractionalPosition)$/.test(name) ||  // convenience movers
  /^_(setWidthSizeHeightAccordingly|setExtentToFractionalExtentInPaneUserHasSet|resizeToWithoutSpacing)$/.test(name);  // convenience setters/resizer
```

`isLowLevel ⊃ isImmediateMutator` (every immediate mutator is `_`-prefixed). **Prose must POINT at these predicates,
never re-define the tiers** — any doc that says "low-level"/"immediate mutator" means *exactly whatever these match*.
The names come from the geometry-apply **2×2** of the naming convention (post-Tier-B REACT × DISPATCH: `__commit*` leaf /
`_apply*Base` override-bypass arrange twin / `_apply*` polymorphic apply / `_commit*AndNotify` notify-only); the old
`raw`/`silent`/`fullRaw` prefixes were
retired (a build-time fragment-ban, rule **[M]**, keeps them out) and the `__` leaf tier has its own no-orchestration
rule **[I]**. Full convention + rationale: `docs/layering-naming-convention.md`.

---

## 3. Gate inventory

All gates are plain Node line-scanners in `buildSystem/` (or, for the test gates, `Fizzygum-tests/scripts/`), wired into
`build_it_please.sh` with the **same shape**: behind `if ! $noSyntaxCheck`, an explicit `$?` check, and a loud
`exit 1` on failure. **Exit codes:** `0` clean · `1` violation · `2` operational error. **Shared escape hatch:**
`--noSyntaxCheck` skips *every* gate (use to bisect a gate bug; never to ship).

| Gate | File | Wired (`build_it_please.sh`) | Enforces | Ratchet mechanism |
|---|---|---|---|---|
| syntax | `buildSystem/check-coffee-syntax.js` | ~:257 | CoffeeScript *parse* errors, compiled the **fragmented** way the browser does | — |
| **layering** | **`buildSystem/check-layering.js`** | **~:279** | **flow soundness + the naming convention — rules [A]–[O] (§4)** | per-method `# layout-apply-sanctioned` [F] / `# nosettle-sanctioned` [G] / `# early-return-sanctioned` [H] markers |
| dead-method | `buildSystem/check-dead-methods.js` | ~:297 | a method defined in src but referenced nowhere (src + harness + macro `.js`) | allowlist `dead-method-allowlist.txt`; fails only on a NEW dead method |
| stinks | `buildSystem/check-stinks.js` | ~:315 | named smells driven to a baseline COUNT | per-smell inline `baseline`; fails on EXCEEDING it |
| thin-wrap | `buildSystem/check-thin-wraps.js` | ~:333 | a public method owning a `_<name>NoSettle` twin is the ONE canonical mechanical wrap | per-method `# thin-wrap-exempt: <reason>`; SKIPS a twinless `*NoSettle` |
| **constructor-build** | **`buildSystem/check-constructors-build.js`** | **~:353** | a `constructor:` body must not build its own children inline — `@add`/`@addMany`/`@addNoSettle`/`@_addNoSettle`/`@__add`/… on `this` belong in `_buildAndConnectChildrenNoSettle`, reached via the settling wrapper | per-constructor `# constructor-build-exempt: <reason>` (no central allowlist; currently ZERO — the 4 menu/slider-family `@__add` ctors were converted 2026-07-12, `docs/menu-slider-ctor-conversion-plan.md`) |
| **call-separation** | **`buildSystem/check-call-separation.js`** | **~:372** | **rules [S]/[U]: [S] a private method must not `@`-self-call a public COMMAND (settling/effectful callee; queries + `changed`/`fullChanged` stay free); [U] a public method referenced ONLY by `@`-self calls is not external API and must be `_`-tier. Measurement engine: `census-public-private-calls.js`. [U] self-skips without the sibling tests repo** | inline count baselines (`BASELINE_S_*`/`BASELINE_U_*`, the stinks idiom); per-caller `# public-call-sanctioned: <why>` for [S]; `public-api-allowlist.txt` for [U] (deliberate end-user inspector/scripting API) |
| relayout-bounds-first | `buildSystem/check-relayout-bounds-first.js` | ~:394 | a `_reLayout` override must APPLY its own bounds before its first own-geometry read (else children lay out against the previous pass's frame — the "one-cadence-lag" flake) | `# relayout-bounds-first-exempt: <reason>` above the method header |
| relayout-repaints [INV-1] | `buildSystem/check-relayout-repaints.js` | ~:392 | a `_reLayoutSelf` that opens a `disableTrackChanges` suppression frame must issue a covering `fullChanged()` AFTER the last re-enable (scoped to `_reLayoutSelf` by design — see the gate header; runtime twin = the paint-truthfulness audit) | `# relayout-repaint-exempt: <reason>` above the method header |
| test-.js syntax | `Fizzygum-tests/scripts/check-tests-syntax.js` | ~:411 | JS syntax of the macro SystemTest `.js` files, before the build copies them in | — (self-skips on `--homepage`/`--notests`/absent sibling) |
| ref-image integrity | `Fizzygum-tests/scripts/check-refs.js` | ~:429 | >1 `dataHash` per `(test,image,dpr,OS)` or an orphaned `.js`/`.png` reference | — (self-skips like the test gate) |

**Per-gate notes:**

- **syntax (`check-coffee-syntax.js`).** The browser NEVER compiles a whole class file — `src/meta/Class.coffee` splits
  each class into fragments (constructor + every field), strips `@augmentWith`, rewrites every `super` form, and
  compiles each fragment with `{bare:true}`. A whole-file `CoffeeScript.compile(src,{bare:true})` therefore false-fails
  on ~300 of ~500 files. To avoid drift this gate **loads and runs the real `Class.coffee`/`Mixin.coffee`** to compile
  each source the faithful way. Catches PARSE errors only; for load-order/runtime faults boot the build
  (`./build_and_smoke.sh`). **DO NOT "simplify" it to a whole-file compile.**
- **dead-method (`check-dead-methods.js`).** Harvests every identifier used where a method could be CALLED — across src
  `.coffee`, the harness `.coffee`, and the macro `.js` (whose `mainMacroSource` strings carry the verbs they call). A
  name that appears ONLY on its own def header (and comments) is DEAD. Fizzygum's dynamic dispatch is *property*-based
  (DeepCopierMixin walks `@[property]`), not name-built, so the false-positive rate is low; genuine exceptions go in
  `dead-method-allowlist.txt`. `--update-allowlist` re-seeds the baseline. Needs the sibling tests repo for an accurate
  reference set; SKIPS (not false-fails) if it is absent.
- **stinks (`check-stinks.js`).** A "stink" is a smell driven to zero, ratcheted at a `baseline` (max tolerated count)
  that lives **inline** next to the rule (a smell is a count, not a named set — no separate allowlist). Build FAILS when
  a stink EXCEEDS its baseline; when it drops below, tighten the baseline to lock the gain (the gate prints a reminder).
  Baseline 0 = a HARD rule. **Current stinks:** `settle-batch-with-core` (baseline **0**) — using the BATCHING settler
  `_settleLayoutsAfterBatch` with a single `_<name>NoSettle` thunk, which means the core still reaches a nested public
  setter and the batch is masking it; fix = make the core pure, switch to `_settleLayoutsAfter`.
- **thin-wrap (`check-thin-wraps.js`).** For a private `_<name>NoSettle`, the public `<name>` in the SAME class must be,
  after comments/blanks: `[zero+ return if/unless guards]` then `@_settleLayoutsAfter => @_<name>NoSettle <args>` — it
  does no work of its own. Complements `check-layering` (which enforces the CORE reaches no public setter). A twinless
  `_<name>NoSettle` (e.g. `_addInPseudoRandomPositionNoSettle`) is SKIPPED — no public twin to constrain.
- **constructor-build (`check-constructors-build.js`).** Locks in the "all constructors settle" end-state (Topic 4
  part 2): a `constructor:` body must NOT build its own children inline. An `inctor` state machine (set on `constructor:`,
  cleared by the next 2-space class header — so it handles multi-line ctor headers, mirroring the FNR audit awk) scans
  each constructor and FAILS on `@_{0,2}add(Many)?(NoSettle)?` called on `this` (the `__add` structural leaf counts
  too — 2026-07-12; the menu/slider-family ctors that built through it were converted the same day,
  `docs/menu-slider-ctor-conversion-plan.md`). The child-building belongs in
  `_buildAndConnectChildrenNoSettle`, reached from the ctor via the settling wrapper `@_buildAndConnectChildren()` (or
  `@_buildScrollFrame()` for the ScrollPanelWdgt base) — so the settle-tier FLUSHES a top-level `new X()` and AUTO-DEFERS
  one built in-flush (inside a callback). Building INTO a sub-child (`@contents._addNoSettle …`) is NOT matched — that
  `.`-qualified form is not `@`-prefixed. Genuine exceptions carry `# constructor-build-exempt: <reason>` (in the body or
  the comment block directly above the header); no central allowlist.

**Two RUNTIME naming-audit gates (suite-run, NOT build-time).** The naming convention also carries two off-by-default
runtime audits that run over the WHOLE SystemTest suite (not `build_it_please.sh`) — each an injected prelude that wraps
prototypes at boot behind a `WorldWdgt` flag, with a standalone `run-*-gate.sh`, siblings of the end-of-cycle /
paint-readonly gates and wired into `fg gauntlet`:
- **tier-naming** (`Fizzygum-tests/scripts/tier-naming-audit/`, flag `auditTierAndApplyNaming`) — the dynamic twin of
  rules [I]/[K]: HARD-fails a `__commit*` leaf or an arrange `_apply*Base` bypass twin that fires the seam/react at
  runtime; reports the polymorphic `_apply*`→seam coverage as INFORMATIONAL (a runtime observation can't soundly
  distinguish a mislabel from an unexercised seam path — and it is now vacuously 0, the `_announce*` seam having been
  deleted 2026-07-01).
- **notification-settle** (`Fizzygum-tests/scripts/notification-settle-audit/`, flag
  `auditNotificationSettleNeutrality`) — the dynamic twin of rule [J]: HARD-fails a `_reactTo*`/`_before*` callback that
  OPENS A FLUSH — an ATTACHED-receiver `_settleLayoutsAfter` (it would throw) or any `recalculateLayouts`. It PERMITS an
  ORPHAN-receiver `_settleLayoutsAfter` reached in a callback: that is a constructor settling its own orphan (the window
  chrome buttons `WindowWdgt._reactToChildDropped` rebuilds), which provably takes the in-flush+orphan auto-defer branch
  (`return coreThunk() if @isOrphan()`) — it records the change, never flushes/recurses. (The "all constructors settle"
  campaign added this orphan exemption — `docs/all-constructors-settle-plan.md`; it makes the gate PRECISE, since the old
  premise "any nested settle in a callback would re-enter/throw" is false for an orphan. It still catches the INDIRECT
  attached leak the static [J] cannot follow.)

They verify the *behaviour* the names promise (the ground truth the static scanner can't follow through dynamic
dispatch). Full description: `docs/layering-naming-convention.md`.

**One ANALYSIS tool (not a gate).** `buildSystem/census-public-private-calls.js` measures public/private
SELF-call mixing (private→public-command calls, double-settle shapes, and public methods only ever
`@`-self-called, i.e. privatization candidates). It always exits 0 — it is the MEASUREMENT behind the
call-separation rules: `check-call-separation.js` requires it as a module and enforces the [S]/[U] count
baselines on its numbers, and rule [T] (in `check-layering.js`) is the static twin of its narrowed-R2
report. The campaign that owns the drawdown is **`docs/public-private-call-separation-plan.md`** — re-run
the census at every tranche start. Methodology and blind spots are documented in the tool's header. Run
from `Fizzygum/`: `node ./buildSystem/census-public-private-calls.js [--full|--json out.json|--self-test]`.

---

## 4. `check-layering.js` rules

The scanner strips `#` comments and string literals (carrying multi-line state) so a call-regex never matches a name in
a throw-message or comment, groups lines into 2-space-indent methods (`METHOD_HEADER`, now mixin-DSL aware so a method
defined inside a mixin's `onceAddedClassProperties` block is attributed too), and keys call detection off a leading
`@`/`.` + the lowercase public name (so `@setExtent`/`.moveTo` match while `@_applyExtent`/`@_applyExtentBase`/`@_setTextNoSettle`
do NOT — the leading `_` sits between the `@`/`.` and the verb). This co-design with the **naming convention** is why the
lint works at all (§6).

| Rule | Subject | Forbids | Why | Runtime twin | Marker |
|---|---|---|---|---|---|
| **[A]** | `isLowLevel` method | calling a public geometry setter (`setExtent`/`moveTo`/`setBounds`/`setWidth`/`setHeight`), a single-settling text setter (`setText`/`setFontSize`/`setFontName`/`toggleShowBlanks`/`toggleWeight`/`toggleItalic`/`toggleIsPassword`), or `recalculateLayouts` | low-level code mutates immediately and must never reach UP into the self-flushing layer | the one-flush throw | — (fix the code: use the `_<name>NoSettle` core / an apply corner) |
| **[B]** | any method not in `{doOneCycle, _settleLayoutsAfter, _settleLayoutsAfterBatch}` | calling `recalculateLayouts()` | only the frame and the settle tiers may drive a flush | — | — |
| **[C]** | a public geometry setter | calling another public geometry setter | would flush more than once per logical mutation | — | — |
| **[D]** | a SystemTest macro (`Fizzygum-tests/tests/**/*_automationCommands.js`) + the `Macro.fromString` heredocs in `src/macros/MacroToolkit.coffee` | calling a `_private` method or a `raw*` (pixel) accessor | macros must drive only the public surface (the gate that would have caught the original 16-macro mess) | — | — (HARD ban; the construction measure-and-size carve-out is now CLOSED — attach the widget first, then public setters, see §7) |
| **[E]** | `isImmediateMutator` (the `_apply*`/`_commit*` corners + the `_move*`/`_set*`/`_resize*` convenience) | calling `_invalidateLayout` | an immediate mutator may MUTATE geometry, never SCHEDULE a layout — scheduling during a pass re-dirties a container mid-pass and the convergence loop never terminates (the Phase-3b app-freeze) | `FLOWRULE_VIOLATION` (~:3848) | — |
| **[F]** | a method that is NEITHER low-level NOR an immediate mutator (handler / property setter / menu action / gesture / constructor) | calling a container-refit apply (`_reLayoutChildren`/`_positionAndResizeChildren`/`_reLayoutScrollbars`/`_reLayout`) synchronously OFF-settle | such a handler must DEFER (record intent via `_invalidateLayout`; let the cycle apply it), unless the apply is genuinely AT a settle point / a documented determinism-exempt family | — | **`# layout-apply-sanctioned: <why>`** |
| **[G]** | `isLowLevel` method (not a settle tier) | calling a STRUCTURAL self-settling wrapper — discovered structurally as the `_settleLayoutsAfter` callers (`destroy`/`close`/`fullDestroy`/`createReference*`/`grab`/`drop`/`slideBackTo`/`setLabel`/`buildAndConnectChildren`/`resetWorld`/`sizeToTextAndDisableFitting`) — OR the unambiguous self-add `@add` | the structural-wrapper extension of [A]: each wrapper self-settles via `_settleLayoutsAfter`, so reaching one from a core/raw/pass re-enters the flush; low-level code must call the `_<name>NoSettle` core | the one-flush throw | **`# nosettle-sanctioned: <why>`** |
| **[H]** *(WARNING, non-fatal)* | a method that self-settles via `@_settleLayoutsAfter` | a GUARD `return` / `return if\|unless …` BEFORE the settle | a public settle-wrapper should be THIN; that early-return guard belongs INSIDE the `_<name>NoSettle` core (else the "already in this state" skip is split across wrapper + core) | — | **`# early-return-sanctioned: <why>`** |
| **[I]** | a `__` leaf method (HARD-FAIL) | `@`-self-calling the re-fit seam (`_reFitContainer*`/`_announce*`), a react step (`_reLayout*`/`changed`/`fullChanged`), a schedule/settle (`_invalidateLayout`/`recalculateLayouts`/`_settleLayoutsAfter*`), or a public setter | a `__` leaf is a true bottom — it triggers NO orchestration (the lowest tier of the naming convention, §1) | tier-naming runtime audit | — (DENYLIST; `@`-self-scoped) |
| **[J]** | a notification callback (`_reactTo*`/`_before*`) | calling `_settleLayoutsAfter` | a callback is a settle-neutral core; the gesture/structural DISPATCHER owns the one settle | notification-settle runtime audit | — |
| **[K]** | a 2×2 apply CORNER (`_apply<Geom>` polymorphic / `_apply<Geom>Base` override-bypass twin / `_commit<Geom>AndNotify` notify-only) | a `_apply*Base` bypass twin firing the container re-fit seam (`_reFitContainer*`/`_announce*`) or DISPATCHING to its polymorphic `_apply*` sibling; a `_commit*AndNotify` corner reacting (`changed`/`_reLayout*`) | post-Tier-B the corners are REACT × DISPATCH: a `_apply*Base` reacts but must BYPASS the override — not fire the seam, not route the arrange apply back through `_apply*`; the notify-only corner must not react. The two statically-sound NEGATIVES; the old positive "*AndNotify reaches the seam" is retired with the seam (deleted 2026-07-01) | tier-naming runtime audit (now vacuous) | — |
| **[L]** | a notification callback DEF (`_reactTo*`/`_before*`) | a name not matching `_(reactTo\|before)(Being\|Child\|HolderWindow)<Event>`, a `NoSettle` suffix, or a legacy fragment (`childX`/`justBeen`/`iHaveBeen`/`aboutTo`/`prepareTo`) | callbacks follow the derivable (perspective × phase) scheme; the legacy spellings were retired | — | — |
| **[M]** | any method DEF | a retired geometry/structural naming fragment as the name — `raw[A-Z]…` / `^silent[A-Z]` / `^fullRaw`, unconditionally (the raw-PIXEL accessors `rawPixelInfo`/`rawPixelHash`/`rawRGBA` live in the tests-repo harness, never scanned — the old allowlist never matched anything in src and was removed) | the `raw*`/`silent*`/`fullRaw*` geometry+structural prefixes were eliminated (§2 of the convention); lock them out — note `full[A-Z]` stays legitimate (`fullBounds`/`fullPaintInto`/…) | — | — |
| **[N]** | any method DEF | a name matching `/^_announce\w*ToContainer$/` (the retired notify-by-mutation container seam) | the mutation-time re-fit seam was deleted 2026-07-01 and replaced by the settle-time up-edge `_reFitMyTrackingContainerAfterSettle`; this bans reviving the announce-up verbs on the DEF side (the CALL side is already [I]/[K]) | — | — |
| **[O]** | any method NOT in `COALESCED_CALLER_ALLOWLIST` (seeded `{nonFloatDragging}`) | a `[@.]…Coalesced` CALL to a `*Coalesced` entrypoint (`_setMaxDimCoalesced`/`_setExtentCoalesced`/`_moveToCoalesced`/`_setWidthCoalesced`/`_setHeightCoalesced`) | a `*Coalesced` entrypoint DEFERS its layout settle to the ONE end-of-cycle flush — byte-identical (sound) only for a per-event STREAM handler that never reads back the settled layout mid-cycle; a discrete caller must use the self-settling setter. These entrypoints are `_`-private for the same reason (only stream handlers may reach them) | — | — (add a genuine new stream handler's method name to `COALESCED_CALLER_ALLOWLIST`) |
| **[P]** | any method whose name does NOT end `Connector` | a `[@.]_settleLayoutsAfterOrJoinEnclosingPass` CALL | `_settleLayoutsAfterOrJoinEnclosingPass` is the reactive-connection settle lane — reached mid-pass it JOINS the open layout pass instead of throwing (so a wired reactive circuit — the °C↔°F converter — settles once); sound ONLY for a dedicated `_<name>Connector` entrypoint carrying the `connectionsCalculationToken` cycle-guard. A general/internal caller must use the self-settling `_settleLayoutsAfter` (surfaces the flow violation) or a `_<name>NoSettle` core | `Widget._settleLayoutsAfter` throw (§1) | — |
| **[T]** | a method whose own body calls `@_settleLayoutsAfter` (the same textual subject `discoverSettlingWrappers` keys off; the settle tiers in `RECALC_WHITELIST` are exempt) | ALSO `@`-self-calling a settling public method — a geometry setter, a text setter, a discovered settling wrapper (name-qualified via `nearestDefinerKind` like [G]), or the self-add `@add` | two flushes for one logical mutation — the whole-settling-surface generalization of [C]. `@`-self-scoped (a dotted receiver settles ANOTHER widget — untypeable). Branch-exclusive pairs (one flush per path, sound) are textually indistinguishable → marker. At rule birth (2026-07-12) exactly 3 sites, all conscious+marked: `grab` (hand-rolled sequential gesture settles) and `newParentChoice{,WithHorizLayout}` (documented idempotent re-fit flush after `@add`) | the one-flush throw | **`# double-settle-sanctioned: <why>`** |

**[G] specifics.** The wrapper set is **discovered**, never hand-listed: `discoverSettlingWrappers` collects every method
whose body calls `@_settleLayoutsAfter` (the SINGLE-mutation tier only — a `_settleLayoutsAfterBatch` wrapper ABSORBS
nested settles and is safe), minus the geometry/text setters ([A] reports those, sharper) and minus `WRAPPER_EXCLUDED`
(§7). So a NEW single-settling wrapper is auto-covered. The `@add` self-form is checked separately (`SELF_ADD_CALL =
/@\s*add\b/`): inside a Widget method `@` is a Widget, so `@add child` is unambiguously `Widget.add` — the `\b` excludes
`@addMany`/`@_addNoSettle`, and the leading `@` (not `.`) excludes the Point#add-ambiguous member form.

---

## 5. The in-code markers + the two ratchet idioms

**Markers — "the justification lives AT the method, no central allowlist."** Each exempts a single method/line via a
comment, with a *required reason*:

| Marker | Gate / rule | Exempts |
|---|---|---|
| `# layout-apply-sanctioned: <why>` | `check-layering` [F] | a non-mutator method consciously applying a container refit off-settle (an in-pass deferred-seam arm, or a determinism-exempt family: scroll-input / collapse / construction) |
| `# nosettle-sanctioned: <why>` | `check-layering` [G] | a low-level method consciously reaching a settling wrapper / `@add` (e.g. a method mis-tagged low-level, or a genuinely safe outside-any-pass case) |
| `# early-return-sanctioned: <why>` | `check-layering` [H] *(warning)* | a public settle-wrapper that consciously keeps a guard `return` BEFORE its `_settleLayoutsAfter` (suppresses the non-fatal [H] warning) |
| `# double-settle-sanctioned: <why>` | `check-layering` [T] | a directly-settling method that consciously ALSO `@`-calls a settling public method — a deliberate sequential-flush design (`grab`, `newParentChoice`) or a branch-exclusive pair the line scanner cannot tell apart |
| `# public-call-sanctioned: <why>` | `check-call-separation` [S] | a private method consciously `@`-self-calling a public COMMAND (the census subtracts the site; use sparingly — the default fix is rename-to-`_` or the `_<name>NoSettle` core) |
| `# thin-wrap-exempt: <reason>` | `check-thin-wraps` | a public method that owns a `_<name>NoSettle` twin but legitimately cannot be the canonical mechanical wrap |

A marker is detected anywhere in the method's body (it resets at each method header). The reason is mandatory — a bare
marker does not exempt.

**Two ratchet idioms** (a convention that isn't a gate rots; new rules should use one so they land green today and
tighten incrementally):
- **baseline / allowlist** (`check-dead-methods`, `check-stinks`): record the current count/set, fail on *regression*,
  drive the baseline down over time. To drive down: fix occurrences, then tighten the inline `baseline` (stinks) or
  remove from `dead-method-allowlist.txt` (dead-method) to lock the gain. Baseline 0 / empty allowlist = a hard rule.
- **per-method marker** (`# layout-apply-sanctioned`, `# nosettle-sanctioned`, `# early-return-sanctioned`, `# thin-wrap-exempt`): the justification
  lives at the method, no central list; a NEW unmarked violation fails the build. Best when the exception is a property
  of one method, not a count.

---

## 6. The tier / naming convention, co-designed with the lints

`isLowLevel`/`isImmediateMutator` classify by NAME, and the call-detection regexes anchor on `[@.]` + the word-prefix —
so the **naming convention and the lints are co-designed** (the lint works at all only because the name encodes the
behaviour). This section covers just *why the names and the regexes fit together*; the full two-family convention (the
geometry-apply **2×2** + the notification **(perspective × phase)** grid) and its two runtime audits live in
`docs/layering-naming-convention.md`.
- **The geometry-apply tiers are all `_`/`__`-prefixed** — the leaf `__commit<Geom>`, the override-bypass arrange twin
  `_apply<Geom>Base`, the polymorphic apply `_apply<Geom>` (ex `_apply<Geom>AndNotify` — Tier B), the notify-only
  `_commit<Geom>AndNotify`, and the `_move*`/`_set*`/`_resize*` convenience. The leading underscore sits between the
  `@`/`.` and the verb, so `@_applyExtent`/`@_applyExtentBase` do NOT match the public-setter regex `[@.]\s*setExtent`. (`raw*` survives ONLY as the pixel accessors `rawPixelInfo`/`rawPixelHash`/
  `rawRGBA`; rule **[M]** bans any new `raw*`/`silent*`/`fullRaw*` geometry/structural name.)
- **`_<name>NoSettle` cores** — do the mutation + invalidate, never settle ("cores call cores"). The leading `_` makes
  `@_setTextNoSettle` invisible to the `[@.]\s*setText\b` text-setter regex.
- **`NoSettle` suffix = a "non-settling region" signal, TWIN-OPTIONAL** (owner-decided 2026-06-25) — it marks the
  *property* (nothing downstream settles), not "the core of a public/core pair". So a structural core can carry it with
  no public twin (`_addInPseudoRandomPositionNoSettle`); the thin-wrap gate SKIPS a twinless `*NoSettle`. (The
  notification callbacks that once mis-carried `NoSettle` — `_reactToGrabOfNoSettle` &c. — DROPPED it in the naming
  campaign: a callback is a settle-neutral core by rule [J], so the suffix said nothing.) Memory:
  `fizzygum-layering-naming-tiers`.

---

## 7. Documented BOUNDARIES (reasoned gaps, not silent ones)

What the layering gate deliberately does NOT cover, and why — so a maintainer reads a reasoned boundary, never a hole:

- **The `.add` MEMBER form (`expr.add` / `@expr().add`) is excluded; the `@add` SELF form IS covered.** `.add` collides
  with `Point#add`/`Rectangle#add` (vector arithmetic, ubiquitous: `@topLeft().add pt`); a name scanner cannot tell a
  Widget structural add from a Point add on an expression without type inference (29 of 35 census hits were `Point#add`).
  `@add` is unambiguous (self == Widget.add) and IS rule [G]'s `SELF_ADD_CALL`. The runtime throw backstops the member
  form and construction-time `add()` on an orphan.
- **`collapse`/`unCollapse` are now COVERED by [G]** (they were once in `WRAPPER_EXCLUDED`). They appeared in layout
  passes (`WindowWdgt._positionAndResizeChildren`'s editButton/internalExternalSwitchButton;
  `HorizontalMenuPanelWdgt._reLayoutSelf`); the end-of-cycle-flush drawdown convert routed those call-sites to the
  idempotent `_collapseNoSettle`/`_unCollapseNoSettle` cores, so they were removed from `WRAPPER_EXCLUDED` and [G] now
  guards them like any other wrapper. `WRAPPER_EXCLUDED` now holds only `add` (the `Point#add`-ambiguous member form, above).
- **The TRANSITIVE closure of [G] was prototyped and REJECTED as intractable — DO NOT re-attempt.** A name-based
  backward-reachability fixpoint ("a low-level method must not REACH a settling method by any path") balloons to
  ~720–870 names / ~500–710 false hits: `constructor → buildAndConnectChildren → add` is a universal hub reached by
  `new @constructor` / `@constructor.name` everywhere, and the raw setters / `*NoSettle` cores themselves land in the
  set — so it flags the very "cores call cores" pattern it should bless. Name-based reachability cannot model the orphan
  guard (a receiver's attached-ness is dynamic). The DIRECT rule [G] is the maximal SOUND static check; the throw
  backstops the transitive/dynamic cases. Evidence: `docs/lint-ratchet-static-checks-plan.md` (EXECUTED).
- **(DONE) Rule [D] is now a HARD ban with no carve-out.** Forbidding macros from the private/immediate geometry API
  was once held back by the construction "measure-and-size" read-back (size a soft-wrapping text to its wrapped HEIGHT
  at a chosen WIDTH on an orphan). That carve-out is now CLOSED: the fix is to ATTACH the widget first (to its
  destination or the desktop) and use the PUBLIC setters — an attached `setWidth` self-settles, so the text wraps in
  place and its height is then readable. `MACRO_FORBIDDEN_CALL` accordingly bans every `_private` call and every `raw*`
  (now pixel-only) accessor in a macro, with no sanctioned escape; the retired `silent*`/`fullRaw*` arms were dropped
  with the §2 renames.
- **(DONE 2026-06-25) `isLowLevel`'s `/Layout$/` arm was VESTIGIAL — removed.** After the layout-method-family rename
  every real layout pass is `_reLayout*`-prefixed (already caught by `/^_/`), so `/Layout$/` only ever matched non-pass
  methods whose name ends in "Layout": `implementsDeferredLayout` (×3, capability queries), the `*HorizLayout` menu
  actions (`newParentChoiceWithHorizLayout` / `attachWithHorizLayout`), and `countOfChildrenInHorizontalStackLayout` (a
  query) — mis-classifying them as low-level. It was a TWO-PART change (the reason it wasn't a one-liner): reclassifying
  `Widget.implementsDeferredLayout` (`@_reLayout != Widget::_reLayout`, a method-REFERENCE comparison) to non-low-level
  makes it an `[F]` subject, and its `@_reLayout` would false-match `APPLY_CALL`. So the arm removal was PAIRED with a
  second `APPLY_CALL` lookahead that skips a comparison / `is` / `isnt` right after the name (a value compared, never
  applied), and the now-unnecessary `# nosettle-sanctioned` marker on `newParentChoiceWithHorizLayout` was retired.
  Self-tested: `[F]` still flags a real `@_reLayout()` apply, skips `@_reLayout != Widget::_reLayout`. Gate green + suite
  165/165 byte-identical + apps 12/12.

---

## 8. How-to

**Add a new `check-layering` rule.** (1) Add the call-detecting regex/predicate near the other constants, comment the
rule (subject / forbidden / why / runtime twin / marker) the way [A]–[O] are. (2) Add the check inside `checkFile`'s
per-method loop, under the right tier guard (`isLowLevel(method)` / `isImmediateMutator(method)` / the non-mutator
branch). (3) If it needs an escape hatch, add a per-method marker (mirror the `methodNoSettleMarked` logic) rather than a
central allowlist. (4) Update the summary line + the failure footer to name the new letter. (5) **Land it green** — see
self-test below; triage every hit (fix the code, or mark with a reason); record the marker count.

**Add a new gate.** Clone an existing `buildSystem/check-*.js` (line scanner: exit `0`/`1`/`2`; reuse the `stripLine` +
`METHOD_HEADER` parsing from `check-layering.js`), then clone its **wiring block** in `build_it_please.sh`:
```sh
if ! $noSyntaxCheck ; then
  echo "checking <thing> ..."
  node ./buildSystem/check-<thing>.js
  if [ "$?" != "0" ]; then
    tput bel
    echo "!!!!!!!!!!! error: <thing> gate failed -- aborting build." 1>&2
    exit 1
  fi
  echo "... <thing> OK"
fi
```
Place it among the other gates (~:255–390). If it scans the sibling tests, guard it
(`&& ! $homepage && ! $notests && [ -d ../Fizzygum-tests ]`) so a tests-stripped build self-skips.

**Self-test a rule (a lint that can't fail is worthless).** Plant a known violation in a throwaway source file, confirm
the build/gate **aborts loudly** with the right message, confirm the marker exempts it, then **delete the fixture**:
```sh
printf 'class __X extends Widget\n  _someNoSettle: ->\n    @add aChild\n' > src/__X.coffee
node ./buildSystem/check-layering.js   # expect: [G] ... @add ... — exit 1
rm -f src/__X.coffee
node ./buildSystem/check-layering.js   # expect: 0 violations — exit 0
```

**Debug / bisect a gate.** `./build_it_please.sh --noSyntaxCheck` skips *all* gates — use it to confirm a build failure
is the gate and not the build, then run the single gate directly (`node ./buildSystem/check-<x>.js`, exit code +
stderr). A gate edit is pure tooling: re-run the gate, no behaviour rebuild; only re-run the suite if you ALSO moved
source to satisfy a new rule.

---

## Appendix — file:line anchors (grep the symbol; numbers drift)

- `buildSystem/check-layering.js` — `PUBLIC_SETTERS`/`TEXT_SETTERS`/`RECALC_WHITELIST`; `isLowLevel` /
  `isImmediateMutator` (the tier predicates, §2); `SETTLE_CALL`/`WRAPPER_EXCLUDED`/`SELF_ADD_CALL`/`NOSETTLE_MARKER` (the
  [G] constants); `LEAF_FORBIDDEN` ([I]); `APPLY_CORNER`/`K_SEAM_CALL`/`K_REACT_CALL`/`K_POLY_APPLY` ([K]);
  `CALLBACK_PREFIX`/`CALLBACK_SHAPE`/`LEGACY_CALLBACK_FRAGMENT` ([L]); `FRAGMENT_BANNED` ([M]);
  `SEAM_VERB_BANNED` ([N]); `COALESCED_CALL`/`COALESCED_CALLER_ALLOWLIST` ([O]);
  `stripLine` / `METHOD_HEADER` / `methodBoundary` (mixin-DSL aware); `discoverSettlingWrappers`; `checkFile` (rules
  [A]–[O]); `checkMacroFile` (rule [D]); `DOUBLE_SETTLE_MARKER`/`T_SELF_PUB_CALL`/`checkDoubleSettle` ([T]).
- `buildSystem/check-call-separation.js` — `BASELINE_S_SETTLING`/`BASELINE_S_EFFECTFUL` ([S]) +
  `BASELINE_U_EFFECTFUL`/`BASELINE_U_QUERY` ([U]) inline ratchets; reads `public-api-allowlist.txt`;
  requires `census-public-private-calls.js` (`runCensus`, `PUBLIC_CALL_MARKER`).
- `buildSystem/check-thin-wraps.js` — `HEADER`/`GUARD`/`EXEMPT`; twinless skip (`if (!byName.has(base)) continue`).
- `buildSystem/check-constructors-build.js` — `METHOD`/`BUILD`/`EXEMPT`; the `inctor` state machine (multi-line-ctor-header aware).
- `buildSystem/check-dead-methods.js` + `buildSystem/dead-method-allowlist.txt`.
- `buildSystem/check-stinks.js` — the inline `baseline` per stink.
- `buildSystem/check-coffee-syntax.js` — loads `src/meta/Class.coffee`/`Mixin.coffee` to compile fragmented.
- `Fizzygum-tests/scripts/check-tests-syntax.js`, `Fizzygum-tests/scripts/check-refs.js`.
- `build_it_please.sh` — gate wiring (~:255–390), each `if ! $noSyntaxCheck` + `$?`-gated `exit 1`.
- `src/basic-widgets/Widget.coffee` — `_settleLayoutsAfter` (the one-flush throw ~:813); `_invalidateLayout`
  (`FLOWRULE_VIOLATION` ~:3848); the immediate-mutator apply corners (`_apply*`/`_commit*`) + the `_<name>NoSettle` cores.

## See also
- `docs/layering-naming-convention.md` — the full naming convention (the geometry-apply 2×2 + the notification
  (perspective × phase) grid) and its two runtime audit gates; rules [I]/[K]/[L]/[M] (and the [M] fragment-ban) enforce it.
- `docs/layout-system-architecture-assessment.md` — the runtime flush model + the invariant in depth (the *why*).
- `docs/lint-ratchet-static-checks-plan.md` — the arc that built rule [G] (STATUS: EXECUTED); the rejected-transitive record.
- `docs/public-private-call-separation-plan.md` — the AUTHORED (not started) command/query call-separation
  campaign: planned rules [S] (private must not self-call a public command) / [T] (a settling method must not
  call another settling public method) / [U] (self-only public methods must be `_`-tier), sized by
  `buildSystem/census-public-private-calls.js` (the analysis tool noted in §3).
- `docs/end-of-cycle-flush-drawdown-plan.md` / `end-of-cycle-flush-inventory.md` — the campaign that owns the
  collapse/unCollapse convert.
- Memory `fizzygum-layering-naming-tiers` — the tier predicates + the `NoSettle` convention.
