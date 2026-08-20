# Fizzygum build-time lint & static-checks — reference

**What this is.** The durable, living reference for Fizzygum's build-time checking system — every gate that
`build_it_please.sh` runs, what each enforces, how they're wired, the predicates and rules they key off, the in-code
markers that exempt a line, the reasoned boundaries (what is deliberately *not* checked, and why), and how to extend or
debug the system. Written to be picked up **cold** by a maintainer with no prior context.

**What this is NOT.** It is not the *why* of the runtime layout architecture — for the flush model, the settle tiers,
the convergence loop, and the invariant these gates protect, see **`docs/archive/layout-system-architecture-assessment.md`**
(the engine) — this doc says *what is checked + how to extend*; that one says *why*. It is also not a to-do: the arc
that built rule [G] and these notes is recorded in **`docs/archive/lint-ratchet-static-checks-plan.md`** (STATUS: EXECUTED),
which now points *here* for current state and keeps only the execution / rejected-transitive history.

> **Orientation.** Fizzygum ships its ~490 class/mixin sources as escaped TEXT and compiles them *in-browser* at boot
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
setters, which schedule nothing. (Depth: `docs/archive/layout-system-architecture-assessment.md`.)

**Two RUNTIME backstops** raise this from convention to a checked property — the static gates make the same checks
*exhaustive and preventive*, and catch the name-recognized/direct cases at build time; the throws backstop the
**dynamic/transitive** cases the name-scanner cannot see:

| Runtime throw | Where (grep the symbol; lines drift) | Fires when | Static twin |
|---|---|---|---|
| One-flush re-entrancy | `Widget.coffee` `_settleLayoutsAfter` (~:928) | a public geometry setter is reached on an *attached* widget while `_inLayoutMutation`/`_recalculatingLayouts` is already true | rules **[A]/[G]** (low-level code must not reach the public/wrapper layer) |
| `FLOWRULE_VIOLATION` | `Widget.coffee` `_invalidateLayout` (~:4919) | an immediate-mutator corner/convenience (`_apply*`/`_commit*`/`_move*`) schedules layout during a pass | rule **[E]** |

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
rule **[I]**. Full convention + rationale: `docs/architecture/layering-naming-convention.md`.

---

## 3. Gate inventory

All gates are plain Node line-scanners in `buildSystem/` (or, for the test gates, `Fizzygum-tests/scripts/`), wired into
`build_it_please.sh` with the **same shape**: behind `if ! $noSyntaxCheck`, an explicit `$?` check, and a loud
`exit 1` on failure. (Most carry their own `if` block; the seven small ones from trailing-whitespace to part-edges share
one — the per-gate `$?`/`exit 1` is the invariant, the block boundary is not.) **Exit codes:** `0` clean · `1` violation
· `2` operational error. **Shared escape hatch:**
`--noSyntaxCheck` skips *every* gate (use to bisect a gate bug; never to ship).

| Gate | File | Wired (`build_it_please.sh` — grep `check-<name>.js`; lines drift) | Enforces | Ratchet mechanism |
|---|---|---|---|---|
| syntax | `buildSystem/check-coffee-syntax.js` | ~:343 | CoffeeScript *parse* errors, compiled the **fragmented** way the browser does | — |
| shippable-coverage | `buildSystem/check-shippable-coverage.js` | ~:366 | every `src/` subdirectory holding `.coffee` files is CLAIMED BY A PART in `parts.json` — a dir no part claims ships NOTHING, exits 0, and surfaces only as a runtime `<NewClass> is not defined` | in-file `ALLOWLIST_PREFIXES`, now down to `src/boot/` alone (compiled by name from the shell script, never globbed) |
| **layering** | **`buildSystem/check-layering.js`** | **~:388** | **flow soundness + the naming convention — rules [A]–[T] (§4)** | per-method `# layout-apply-sanctioned` [F] / `# nosettle-sanctioned` [G] / `# early-return-sanctioned` [H] markers; per-line `# macro-private-call-sanctioned: <reason>` [D] for a test ORACLE that must call a private verb (the `world._fullChanged()` ground-truth repaints) |
| **invalidation-receivers** | **`buildSystem/check-invalidation-receivers.js`** | **~:407** | **widget-citizenship point 2: invalidation is SELF-invalidation, and PRIVATE (`_changed`/`_fullChanged` since 2026-07-22) — no `<expr>._changed()`/`<expr>._fullChanged()` on another widget (if A's action affects B, B marks itself changed in the method A invoked on it). The ONLY allowed receiver is `@` (dotless, never matches); the singletons are NOT exempt — cross-object repaint goes through their intent-named public methods (`noteWallpaperChanged`/`resetImmutableBackBuffersCache`/`noteTextChanged`/`noteCarriedWidgetChanged`); there is NO general-purpose public repaint verb. The paint executor `_repaintDamagedRects` (the world's once-per-cycle damage-rect flush) is in the same gated private family. Matches the legacy public spellings too, so they cannot slip back in** | `# cross-invalidation-sanctioned: <reason>` on or directly above the line (11 sites: the structural add/drop/z-order/shadow dispatchers, the world's atlas-warm orchestration and its selection-overlay reconciler, FileLoading's async-asset repaint, and the own-sub-part marks in MenuItemWdgt and PopUpWdgt) |
| dead-method | `buildSystem/check-dead-methods.js` | ~:425 | a method defined in src but referenced nowhere (src + harness + macro `.js`) | allowlist `dead-method-allowlist.txt`; fails only on a NEW dead method |
| **unresolved-sends** | **`buildSystem/check-unresolved-sends.js`** | **~:446** | the INVERSE of dead-method: a CALL `[@.]name(` in src+harness that NOBODY implements — a guaranteed runtime `TypeError` on any path reaching it | allowlist `unresolved-sends-allowlist.txt` (vendor + dynamic, `name # reason`); in-file `BUILTINS` for platform API |
| stinks | `buildSystem/check-stinks.js` | ~:465 | named smells driven to a baseline COUNT | per-smell inline `baseline`; fails on EXCEEDING it |
| argument-holes | `buildSystem/check-argument-holes.js` | ~:486 | calls punching a bare `undefined` through to a later argument (R3) — the decisive **hole test** of [`constructor-and-parameter-conventions.md`](constructor-and-parameter-conventions.md). Shares `census-call-arity.js`'s parser, so gate and census cannot disagree. `src/` only, deliberately: the tests repo's `SystemTest_*.js` metadata is PROSE in string literals, and a doc edit must never break a build | inline `BASELINE = 2` (the measured floor of the conformance arc). ⚠ It is a REGRESSION alarm, not an inventory — the honest tree-wide count is `census-call-arity.js --holes` (§3c) |
| **menu-actions** | **`buildSystem/check-menu-actions.js`** | **~:509** | **menu-item wiring. A menu action is dispatched through ButtonWdgt's fixed four-slot convention (`@target[@action].call @target, menuItem, panelTarget, arg1, arg2`), which the call site never names. HARD (sound): a function literal in the action slot (`@target[@action]` coerces it to a string key, so the click throws) and a string literal where `opts` goes. RATCHET at 0: an UNREAD parameter on a menu-dispatched verb must be NAMED as unread (`ignored`/`unused`) — padding a signature to reach the slot you want puts widgets into parameters whose names promise otherwise, and forces every other caller to punch `undefined` through.** ⚠ TWO blind spots, both structural: it cannot see whether a parameter that IS read is read as the right THING, and it cannot see a parameter that is MISSING — a verb needing a subject it never declares reads as clean, because there is nothing unread to flag. Both are the class of bug only a rig that CLICKS the item can catch, which is why `fg menusweep` exists beside it. ⓘ RULE 1 has TWO DOORS: besides `addMenuItem`/`prependMenuItem`, `prompt`/`textPrompt` take a `callback` that `PromptWdgt` hands to a menu item verbatim (`panel.addMenuItem "Ok", @target, @callback`) — same slot one hop later, so the same proof applies, and those callbacks count as menu-dispatched verbs for the RULE 3 ratchet too | rules 1–2 are HARD; the unread-parameter rule is the inline `RULE3_BASELINE = 0` ratchet |
| thin-wrap | `buildSystem/check-thin-wraps.js` | ~:527 | a method owning a `_<name>NoSettle` twin — public `<name>` or private `_<name>` — is the ONE canonical mechanical wrap | per-method `# thin-wrap-exempt: <reason>`; SKIPS a twinless `*NoSettle` |
| trailing-whitespace | `buildSystem/check-trailing-whitespace.js` | ~:546 | no trailing whitespace on a line that has CONTENT (`/\S[ \t]+$/`) — a trailing space after a bare `super` once silently dropped forwarded args | — (whitespace-only lines are deliberately NOT flagged: invisible, harmless, and in the hundreds) |
| scheduled-checks | `buildSystem/check-scheduled-checks.js` | ~:555 | a `# CHECK AFTER <date>` time-bomb reminder must not be OVERDUE — nor unparseable, since one that can never fire defeats the purpose | — (act on it, then delete the marker or push the date forward) |
| stringified-scripts | `buildSystem/check-stringified-scripts.js` | ~:564 | `new ScriptWdgt """…"""` stringified code belongs in USER code, not the core framework; core is at 0 and stays there | `# stringified-script-sanctioned: <reason>` on the line or in the comment block directly above |
| region-markers [tombstone] | `buildSystem/check-region-markers.js` | ~:573 | the per-REGION `# »>>` text-exclusion mechanism (retired in arc 3, after it was found stripping PRODUCT code out of production) must stay at zero, and an opener must never be unpaired | inline per-kind `baseline`, all three at 0 = HARD |
| source-vault [tombstone] | `buildSystem/check-source-vault.js` | ~:582 | the retired per-class `window.<Name>_coffeSource` global + the `Object.keys(window)` suffix scan in `src/boot/**` (arc 4) must not return; sources arrive only through `SourceVault.store` | — (forbidden outright, comments included — the conversion completed inside its own phase) |
| whole-file-markers [tombstone] | `buildSystem/check-whole-file-markers.js` | ~:591 | the per-FILE exclusion comments (`# this file is excluded from the fizzygum homepage build`, the Macros and VideoPlayer twins) must stay at zero (arc 4); parts + profiles say the same thing visibly and at slice granularity | inline per-kind `baseline`, all three at 0 = HARD. ⛔ Do not invent a replacement marker syntax |
| part-edges | `buildSystem/check-part-edges.js` | ~:603 | CORE must never name a PART's class unguarded — the one structural defence for an artifact built without that part (the suite runs the harness page, which carries every part; the smoke never opens the menu item that would throw). A REFERENCE is fixable in place (`if DemoMenus?` / `world.pinouts?.…` / an `ensureLoaded` await); `extends`/`@augmentWith` is not guardable at all and means the PARTITION is wrong | `buildSystem/lib/part-edge-scan.js` is the shared scanner; a guard IS the exemption, and an eager part's `declaredRequires` discounts the parts it legitimately depends on |
| **constructor-build** | **`buildSystem/check-constructors-build.js`** | **~:623** | a `constructor:` body must not build its own children inline — `@add`/`@addMany`/`@addNoSettle`/`@_addNoSettle`/`@__add`/… on `this` belong in `_buildAndConnectChildrenNoSettle`, reached via the settling wrapper | per-constructor `# constructor-build-exempt: <reason>` (no central allowlist; currently ZERO — the 4 menu/slider-family `@__add` ctors were converted 2026-07-12, `docs/archive/menu-slider-ctor-conversion-plan.md`) |
| **call-separation** | **`buildSystem/check-call-separation.js`** | **~:645** | **rules [S]/[U]: [S] a private method must not `@`-self-call a public COMMAND (settling/effectful callee; queries + `changed`/`fullChanged` stay free); [U] a public method referenced ONLY by `@`-self calls is not external API and must be `_`-tier. Measurement engine: `census-public-private-calls.js`. [U] self-skips without the sibling tests repo** | inline count baselines (`BASELINE_S_*`/`BASELINE_U_*`, the stinks idiom); per-caller `# public-call-sanctioned: <why>` for [S]; `public-api-allowlist.txt` for [U] (deliberate end-user inspector/scripting API) |
| relayout-bounds-first | `buildSystem/check-relayout-bounds-first.js` | ~:664 | a `_reLayout` override must APPLY its own bounds before its first own-geometry read (else children lay out against the previous pass's frame — the "one-cadence-lag" flake). Also follows the own-contents TEMPLATE: a `_reLayout` delegating to `Widget._reLayoutWithOwnContents` is apply-first by construction (counted separately, never as "positions no children"), and a `_layOutOwnContents` reading own geometry without that delegation is a violation. ⚠ Blind to a file defining the hook and NO `_reLayout` — it inherits one this line-scanner cannot follow | `# relayout-bounds-first-exempt: <reason>` above the method header |
| widget-conformance `--gate` | `buildSystem/census-widget-conformance.js --gate` | ~:686 | the two OBJECTIVE facets of the widget-practices survey: **instance fields written but never DECLARED at class level** (until declared, a lazily-initialised field is invisible to duplication, serialization and the inspector) and **`_reLayout` prologue copies** (classes not taking `Widget._reLayoutWithOwnContents`). Mixin-aware: a field a mixin donates counts as declared, and re-declaring it in the class body would CLOBBER the donated value. Its default, gate-less run is the advisory census (§3c) | inline `BASELINE_UNDECLARED_CLASSES`/`_FIELDS` = **0/0** and `BASELINE_PROLOGUE_COPIES` = **8**. ⚠ **A BASELINE HERE IS A FLOOR, NOT A ZERO** — undeclared fields reached a true 0/0, so that one IS an inventory; prologue copies stay at 8 (two deliberate non-conversions plus six genuinely different shapes), each named in the script |
| relayout-repaints [INV-1 tombstone] | `buildSystem/check-relayout-repaints.js` | ~:710 | the RETIRED paired suppression verbs (`disableTrackChanges`/`maybeEnableTrackChanges` — the arc that removed them is [`../archive/repaint-as-one-unit-plan.md`](../archive/repaint-as-one-unit-plan.md)) must not reappear in src or harness src — [INV-1]'s covering-repaint obligation is now STRUCTURAL in `Widget._repaintAsOneUnit` (the `finally` restores the suppression depth and fires the covering `_fullChanged` — skipped only when provably vacuous: zero suppressed mark attempts inside the unit and fn completed; runtime twin = the paint-truthfulness audit, unchanged) | — (no exemption: a suppression window IS `@_repaintAsOneUnit`) |
| raw-pointer-reads | `buildSystem/check-raw-pointer-reads.js` | ~:731 | a pointer-event HANDLER body (`mouse*`/`wheel`/`nonFloatDragging`/…, closures included) must not consume the raw SCREEN-plane `world.hand.position()` unmapped — consume the plane-mapped `pos` PARAMETER the dispatcher hands every handler (affine 4A), or map the sample at the read site (`screenPointToMyPlane` on the same line, the drag-scroll idiom). Off-island the mapped point IS the raw point, so the bug class is invisible until a widget is TILTED (the 2026-07-17 spreadsheet tilted-selection bug). Helpers a handler calls are NOT scanned (heuristic tripwire — the deliberate raw-screen rotate-angle helper lives in one); `ActivePointerWdgt` itself skipped | `# raw-screen-pointer-sanctioned: <reason>` above the handler header (currently ZERO sites) |
| plane-discipline | `buildSystem/check-plane-discipline.js` | ~:740 | the three statically-checkable rules of the paint-time scroll model ([`viewports-and-planes.md`](viewports-and-planes.md)): **A)** `scrollOffsetX/Y` assigned ONLY inside `_writeScrollOffset` (a bare write skips the `geometryVersion` bump — the measured hit-invisible-scrolled-row class); **B)** a count RATCHET over lines mixing two DISTINCT receivers' POSITIONAL geometry (`position`/`left`/`top`/`center`/`bounds`/… — plane-relative, unlike the plane-invariant extents) with no mapping call on the line — the silent dormant-at-offset-0/identity class every hard bug of the scroll arc belonged to; same-plane-by-construction sites are legitimate, so new lines are CLASSIFIED (map, or raise the baseline with a reason) and drops ratchet down; **C)** a positional pointer handler on a `scrollTranslationOfChild` provider (transitive via `extends`) must re-derive its `pos` through `screenPointToMyPlane` — `escalateEvent` forwards descendant-plane args verbatim (the measured stationary-click-slams-to-clamp defect; `wheel` exempt, deltas). ⚠ Blind by design to CROSS-LINE flows: a positional value stored in one method and consumed in another plane elsewhere, or forwarded through an opts key — those are the deep-audit's job (the 2026-08-20 review census), not a line scanner's | A/C: hard zero; B: inline `CROSS_PLANE_MIX_BASELINE` (47); C: `# escalated-pos-sanctioned: <reason>` above the handler header (currently ZERO sites) |
| test-.js syntax | `Fizzygum-tests/scripts/check-tests-syntax.js` | ~:750 | JS syntax of the macro SystemTest `.js` files the build is about to serve | — (self-skips unless `$PROFILE_SHIPS_TESTS`, or when the sibling repo is absent) |
| ref-image integrity | `Fizzygum-tests/scripts/check-refs.js` | ~:773 | >1 `dataHash` per `(test,image,dpr,OS)` or an orphaned `.js`/`.png` reference | — (self-skips like the test gate). Its PIXEL half, `--pixels`, is deliberately NOT on the build: it runs as the gauntlet's `refs` leg |

**Per-gate notes:**

- **syntax (`check-coffee-syntax.js`).** The browser NEVER compiles a whole class file — `src/meta/Class.coffee` splits
  each class into fragments (constructor + every field), strips `@augmentWith`, rewrites every `super` form, and
  compiles each fragment with `{bare:true}`. A whole-file `CoffeeScript.compile(src,{bare:true})` therefore false-fails
  on ~300 of ~500 files. To avoid drift this gate **loads and runs the real `Class.coffee`/`Mixin.coffee`** to compile
  each source the faithful way. Catches PARSE errors only; for load-order/runtime faults boot the build
  (`./build_and_smoke.sh`). **DO NOT "simplify" it to a whole-file compile.**
- **invalidation-receivers (`check-invalidation-receivers.js`).** Enforces widget-citizenship contract point 2 after the
  2026-07-22 audit fixed the 17 feature-code deviations it found (37 cross-receiver sites total: 15 category-C fixed, 4
  redundant own-sub-part deleted, 9 singleton-allowed, 9 sanctioned). The redundancy argument the fixes rest on: broken
  rects are fleshed out at the END-of-cycle flush — source from `*clippedBoundsWhenLastPainted` (recorded at paint time),
  destination from current bounds read at flush — so ONE `_fullChanged()` anywhere in the cycle (e.g. the one inside
  `_addNoSettle`) covers every same-cycle geometry mutation, and a trailing `w._fullChanged()` after `add w` +
  `setExtent` is dead weight. The conforming shape for a genuine repaint need is receiver-side: the method A invokes on B
  ends with `@_changed()` (e.g. `StretchableCanvasWdgt.getContextForPainting` marks its own canvas; the paint-tool
  sources no longer reach back). Scanner is line-based (naive comment strip, same trade as the raw-pointer gate); `@_changed()`
  self-calls are dotless and never match, so only dotted receivers are judged. Harvests every identifier used where a method could be CALLED — across src
  `.coffee`, the harness `.coffee`, and the macro `.js` (whose `mainMacroSource` strings carry the verbs they call). A
  name that appears ONLY on its own def header (and comments) is DEAD. Fizzygum's dynamic dispatch is *property*-based
  (the `Duplicator` engine walks `@[property]`), not name-built, so the false-positive rate is low; genuine exceptions go in
  `dead-method-allowlist.txt`. `--update-allowlist` re-seeds the baseline. Needs the sibling tests repo for an accurate
  reference set; SKIPS (not false-fails) if it is absent.
- **unresolved-sends (`check-unresolved-sends.js`).** The exact INVERSE of the dead-method gate (that one: defined but
  never sent; this one: sent but never defined). Pharo's `ReSentNotImplementedRule`, carried over 2026-07-15. It harvests
  every call-shaped `[@.]name(` across src + the harness and fails on any name that NOTHING in that universe implements.
  Like dead-method it **SKIPS** (exit 0 + a loud note) when the sibling tests repo is absent — the harness is part of the
  definition universe (src calls into it behind `if Automator?`). It landed green on day one (7046 calls, 0 unresolved,
  ~0.1 s).
  It is deliberately built for **ZERO false positives at the cost of reach** — a false FAIL breaks the build on correct
  code, while a miss merely leaves a fault for the boot smoke / SystemTests. That trade is an ASYMMETRY in masking, and
  both halves err toward "fewer flags": **defs are OVER-approximated** (naive `#{`-aware comment strip that KEEPS
  strings; the last def-form counts ANY `name:`/`name =` key, since a property may hold a closure), while **calls are
  UNDER-approximated** (`stripLine`-grade — strings and comments masked, `#{…}` interpolation kept as the code it is).
  Keeping the naive strip on the DEF side is load-bearing, not laziness: `TRIPLE_QUOTES = ///'''///`
  (`src/boot/dependencies-finding.coffee:59`) is a BLOCK REGEX whose `'''` reads to `stripLine` as an unterminated
  heredoc and blanks the rest of that file — blanked *defs* would cause false POSITIVES, blanked *calls* only cost
  coverage.
  Accepted reach limits (each a miss, never a false-fail): paren-calls only (paren-less `@foo arg` is too noisy to gate
  on — §8.7 of the carryover plan); string-dispatched sends are invisible (menu/button actions — that hole needs the
  action-string checker); capital-initial names are skipped (the boot dependency finder's jurisdiction); macro `.js` is
  not scanned (rule [D] polices it); no receiver typing, so a name defined ANYWHERE resolves a call EVERYWHERE.
  **Two exemption lists, on purpose:** the in-file `BUILTINS` set is a fact about the PLATFORM (JS/DOM/canvas), while
  `unresolved-sends-allowlist.txt` is a fact about Fizzygum's VENDOR dependencies — one named API we reach at a few
  sites, where the recorded reason is worth more than the suppression (JSZip, WebCrypto, the LCL event router, the
  SWCanvas bitmapText API, a Firefox-legacy guarded `toSource`). Seeded at exactly 9 entries, each triaged against its
  real call site.
- **stinks (`check-stinks.js`).** A "stink" is a smell driven to zero, ratcheted at a `baseline` (max tolerated count)
  that lives **inline** next to the rule (a smell is a count, not a named set — no separate allowlist). Build FAILS when
  a stink EXCEEDS its baseline; when it drops below, tighten the baseline to lock the gain (the gate prints a reminder;
  `fg critique` resurfaces it). Baseline 0 = a HARD rule. Scans `src/` only (not the harness — a stink is a statement
  about the SHIPPED framework's idiom), per-LINE, over `#`-comment-stripped lines — except a stink declaring
  `scope: 'comments'`, which matches the COMMENT part of each line instead (the comment-hygiene ratchets).
  **Current stinks — thirteen: seven seeded 2026-07-15** (the original `settle-batch-with-core` stink was retired when its
  target `_settleLayoutsAfterBatch` was deleted, leaving the table empty until then), **three comment-hygiene
  ratchets added at the 2026-07-17 comments cleanup**, `comment-past-receipt` (2026-08-09), `positional-hole`
  (2026-08-15) and `helper-compiling-operator` (2026-08-17). One of the original
  seven, `undefined-literal`, has since been REPLACED rather than removed — see `nil-literal` below. Every baseline was MEASURED by the engine on its seeding day and
  every stink spot-checked against its real hits; they are ratchets recording that day's count, not verdicts — driving
  any of them down is a future arc:

  | stink | baseline | why |
  |---|---|---|
  | `debugger-statement` | 33 | left-in debug cruft; hard-stops execution whenever devtools are open (Pharo: `ReCodeCruftLeftInMethodsRule`) |
  | `nil-literal` | 0 | HARD: the `nil = undefined` global is RETIRED (`archive/nil-global-retirement.md`), so a `nil` is a ReferenceError waiting to happen. Replaced `undefined-literal` (baseline 83), which enforced the now-inverted convention |
  | `null-literal` | 8 | `undefined` is the ONE absence value; the JS-interop sites (`JSON.stringify`'s arg, `onload = null`) are the tolerated tail |
  | `wall-clock` | 19 | `Date.now()`/`new Date()` breaks event-stream determinism (DETERMINISM.md — recognition keys off EVENT timestamps) |
  | `timer` | 4 | `setTimeout`/`setInterval` diverge at dpr2 under parallel load (bug-class B); the cycle/step machinery is the sanctioned clock |
  | `math-random` | 5 | breaks byte-exact screenshot determinism in render/layout/input code |
  | `instanceof-type-test` | 87 | locks the type-test-elimination campaign's tail against regrowth — prefer polymorphism (Pharo: `ReBadMessageRule`) |
  | `positional-hole` | **0 (HARD)** | a call punching `undefined` through to reach a later argument PROVES the skipped parameter is configuration rather than identity — the decisive **hole test** (R3) of [`constructor-and-parameter-conventions.md`](constructor-and-parameter-conventions.md). Driven 51 → 0 family by family by [`../archive/constructor-parameter-conformance-plan.md`](../archive/constructor-parameter-conformance-plan.md). ⚠ A PASS is a FLOOR, not an inventory: the regex needs two `undefined`s adjacent on ONE line, so it is blind to a single-`undefined` hole and to one spread over a multi-line call — sweep a converted family by METHOD NAME across both repos instead. ⚠⚠ It also walks `Fizzygum/src/**/*.coffee` ONLY. So does `check-argument-holes.js`, deliberately (see its header) — which means **NO automatic check sees a hole in the sibling tests repo**, and the manual `census-call-arity.js --holes` that does see them is noisy enough there (test METADATA is prose in string literals, which the identifier sweep over-matches) that it is not run routinely. Measured 2026-08-17 (connector §P4): `PaletteWdgt`'s leading `target` parameter had ELEVEN live `new ColorPaletteWdgt undefined, …` holes in macro sources; both gates read clean, and the census would have listed all eleven had anyone run it. ⇒ after changing a constructor, run the census by hand — the gates cover `src/` only |
  | `helper-compiling-operator` | **0 (HARD)** | CoffeeScript's `%%` compiles to a `modulo` HELPER FUNCTION in the emitted `var` block, and the meta-system STRIPS that block out of every member it compiles (`src/meta/Class.coffee` `_removeHelperFunctions`) — so the operator becomes a call to something that does not exist. **Nothing else catches it:** it parses, so the syntax gate passes it, and the strip's own runtime guard enumerates three helper names (`indexOf`/`hasProp`/`slice`) and does not know this one. The failure surfaces as a widget BANNED FROM REPAINTING with a `ReferenceError` in the error log — i.e. as a screenshot diff, which a mass recapture would bake in. Spell the wrap out (`x += 6 if x < 0`). Found the hard way in connector-arc P6 |
  | `comment-meta-edit` | 0 | HARD: a comment arguing with itself ("the below is actually correct", "to be clear,") is process residue — state the surviving constraint once |
  | `comment-narration` | 103 | history narration in comments ("used to", "previously", "no longer", "in the old model") — history's home is `docs/archive/` + a pointer; a comment states what IS | <!-- narration-ok: this row DEFINES the narration rule, so it must quote its own trigger words -->
  | `commented-out-debug` | 0 | HARD: commented-out `alert(`/`debugger`/`console.log` is dead debug cruft — delete it; git remembers |
  | `comment-past-receipt` | 0 | HARD: a `was <old code>` conversion receipt narrates history — state the surviving present-tense contract (what the predicate answers, or why this spelling) and let `docs/archive/` keep the before-picture |

  ⚠ The engine's `stripComment` is a naive `#` cut that does **not** mask STRINGS, so e.g. `null-literal` counts the
  `"null"` inside a string as readily as a real `null`. That is ACCEPTED, not a bug: a ratchet measures REGRESSION, not an absolute. (Upgrading it
  to the shared `stripLine` masking is banked as §8.8 of the carryover plan.) There is also no multi-line matcher — an
  empty-catch stink would need one (§8.9).
- **thin-wrap (`check-thin-wraps.js`).** For a private `_<name>NoSettle`, its settling twin in the SAME class — the
  public `<name>` (e.g. `setLabel`) OR a private `_<name>` (e.g. the construction wrapper `_buildAndConnectChildren`,
  which is exactly what the constructor-build gate sends every widget author to) — must be, after comments/blanks:
  `[zero+ return if/unless guards]` then `@_settleLayoutsAfter => @_<name>NoSettle <args>` — it does no work of its own.
  Complements `check-layering` (which enforces the CORE reaches no public setter). A twinless
  `_<name>NoSettle` (e.g. `_addInPseudoRandomPositionNoSettle`) is SKIPPED — no twin to constrain.
- **constructor-build (`check-constructors-build.js`).** Locks in the "all constructors settle" end-state (Topic 4
  part 2): a `constructor:` body must NOT build its own children inline. An `inctor` state machine (set on `constructor:`,
  cleared by the next 2-space class header — so it handles multi-line ctor headers, mirroring the FNR audit awk) scans
  each constructor and FAILS on `@_{0,2}add(Many)?(NoSettle)?` called on `this` (the `__add` structural leaf counts
  too — 2026-07-12; the menu/slider-family ctors that built through it were converted the same day,
  `docs/archive/menu-slider-ctor-conversion-plan.md`). The child-building belongs in
  `_buildAndConnectChildrenNoSettle`, reached from the ctor via the settling wrapper `@_buildAndConnectChildren()` (or
  `@_buildViewportChrome()` for the ViewportWdgt base) — so the settle-tier FLUSHES a top-level `new X()` and AUTO-DEFERS
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
  chrome buttons `FrameWdgt._reactToChildDropped` rebuilds), which provably takes the in-flush+orphan auto-defer branch
  (`return coreThunk() if @isOrphan()`) — it records the change, never flushes/recurses. (The "all constructors settle"
  campaign added this orphan exemption — `docs/archive/all-constructors-settle-plan.md`; it makes the gate PRECISE, since the old
  premise "any nested settle in a callback would re-enter/throw" is false for an orphan. It still catches the INDIRECT
  attached leak the static [J] cannot follow.)

**Two RUNTIME WIRING sweeps (on-demand / gauntlet legs, NOT build-time).** Where the audits above wrap prototypes over
the whole suite, these BOOT A PAGE and drive one mechanism to exhaustion — each the runtime half of a static gate whose
blind spot is structural:
- **menu sweep** (`Fizzygum-tests/scripts/menu-click-sweep-headless.js`, `npm run menu-sweep`, `fg menusweep`) —
  DISPATCHES EVERY MENU ACTION **and presses every prompt's Ok**, failing on a throw from either; the other half of
  `check-menu-actions.js`, which cannot see a parameter that is read as the wrong THING. ⭐ The prompt step is the one
  that matters for an item ending in `"..."`: such an item does its real work in the prompt's callback, dispatched as
  `@target[@callback].call` with NO `?.`, so a rig that stops at the menu action covers it only as far as the prompt
  APPEARING — which is the point at which everything still looks fine. A prompt is not a `MenuWdgt` (both descend from
  `PopUpWdgt`), so the submenu walk cannot reach one and it needs its own query. Ok is pressed with the prompt's own
  default contents, so this asks "does the callback resolve and run", never "is this a good value".
  ⚠ Its coverage model is REPRESENTATIVES, not exhaustion: 20 roots (two world roots, 16 representative widget classes,
  the inspector pair — whose prompts open from a BUTTON row no menu walk can reach), so a class not among them is
  unreached. That is why
  it and the pin sweep are complementary rather than redundant — with the corner-radius defect planted back in, this rig
  catches 2 of the 16 affected classes and the pin sweep catches all 16.
  ⚠⚠ **A menu built behind a BRANCH is only swept in the branch the rig happens to be standing in**, and an action can
  flip the very flag that decides the shape (`switch to user mode` dispatches `toggleDevMode`) — so `sweepRoot` restores
  `isDevMode`/`isIndexPage` per root; without that, one root's click left every later widget menu EMPTY and was reported
  as "no menu returned". The desktop menu is now ONE list gated per item (`@isDevMode`, `world.parts.isAvailable
  "demos"`, `Automator?`) rather than forked on which page booted the world, and the rig sweeps it as two roots
  (`world[product]`, `world[desktop]`) so both dev-mode shapes are walked. ⇒ **when a rig STATES a coverage, check the
  statement**: for as long as the desktop menu forked on `isIndexPage`, the world root walked 4 of its 13 rows while the
  rig's own comment called it "the door to the demo tree" — which is how a dispatch to `WorldWdgt.about`, a method
  deleted in 2017 whose menu row stayed, survived nine years in the first menu anyone opens.
- **pin sweep** (`Fizzygum-tests/scripts/pin-sweep-headless.js`, `npm run pin-sweep`, `fg pinsweep`; a gauntlet wave-A
  leg beside `menusweep`) — EVERY PIN A CLASS ADVERTISES
  MUST BE SERVICEABLE. A `PinSpec` names its setter/getter by STRING and the dataflow dispatches them as
  `consumer[name]?.call`, so an unresolved one is offered in the choose-target-property menu, accepts a wire, and
  silently does nothing forever. It is a sweep rather than a scan for the same reason the menu one is: `pins()` is
  COMPOSED (`super().concat @_inputPins()`) and a subclass can NARROW it, so a textual analysis reports pins a class does
  not have. The rule resolves DOWNWARD with no `isAbstract` marker — a pin must resolve on every class that is a LEAF or
  is somewhere `new`-ed, so a base declaring pins for its subclasses is skipped by what the class graph already states.
  Two extra sections: appearance-contributed pins (invisible to a bare prototype, since `@appearance` is assigned in a
  constructor) checked on the classes that WEAR the appearance; and `announces`, checked by a per-pin FIXTURE that drives
  the setter and watches for a dataflow mark — a NECESSARY condition, never a proof, since no analysis can enumerate a
  pin's write paths. ⭐ Its first run found `corner radius` advertised by 16 classes with no `setCornerRadius`, which was
  also a hard THROW in the shape's own prompt.

They verify the *behaviour* the names promise (the ground truth the static scanner can't follow through dynamic
dispatch). Full description: `docs/architecture/layering-naming-convention.md`.

**The ALWAYS-ON runtime asserts (no flag, no prelude).** A handful of invariants are cheap enough to check
inline and are caught nowhere else, so they `console.error` a TOKEN that both headless runners fail on
(`run-all-headless.js`, `run-macro-test-headless.js` — seven tokens on that gate today). Each exists because
the screenshot suite structurally cannot see the violation:
- `NON_FINITE_GEOMETRY` / `NON_INTEGER_GEOMETRY` — `Widget._assertBoundsWellFormed`, see
  [`integer-pixel-placement-and-sizing.md`](integer-pixel-placement-and-sizing.md).
- `POPUP_LARGER_THAN_WORLD` — `PopUpWdgt._assertFitsInTheWorld`: a pop-up bigger than the world has rows
  nothing can click. A reference image disagrees only if a macro happens to click the row that went
  missing, which is exactly why menus shipped rows off the bottom edge unnoticed for years — so the
  invariant is asserted rather than left to be noticed.
- `DOWNWALK_UNREACHABLE_CHAINTOP` — `WorldWdgt`: a settle round made no progress with widgets still
  invalid; the convergence loop's own non-termination alarm.
- `DAMAGE_SUPPRESSION_UNBALANCED` — `WorldWdgt`: a non-zero `_damageSuppressionDepth` at cycle end. The
  structural half of [INV-1] lives in `Widget._repaintAsOneUnit`'s `finally`; this is the tripwire that
  says it was bypassed.
- `STORAGE_INVARIANT` — `StorageSorter`: a destroyed / misclassified / parent-desynced resident in the bin
  or on the shelf (its from-scratch twin is the gauntlet's `storage` leg).

⚠ One more token rides the same fail-gate but is NOT shipping code: `RESETWORLD_INCOMPLETE`, the
world-teardown completeness ratchet, lives in
`Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee` (arc 3 moved the test-only teardown
out of core), so it fires only on a build whose profile ships the `harness` part. A leak bites the NEXT test
in the shard, so no single test's pixels reveal it.

---

## 3b. The THREE tiers, and which one a new rule belongs in (severity policy)

Make the implicit explicit — the tier is decided by the SIGNAL's soundness, never by how much we care:

- **A sound NEGATIVE ⇒ a HARD GATE.** If a true finding is *provably* wrong code and the checker cannot produce a false
  positive, fail the build (`check-layering`, `check-unresolved-sends`, the syntax gate). Land it green.
- **A count-shaped smell ⇒ a RATCHETED stink/baseline.** Real but tolerated-at-today's-count, driven down over time
  (`check-stinks`, `check-call-separation`'s `BASELINE_*`, the dead-method allowlist).
- **A SUSPECTED / heuristic signal ⇒ an ADVISORY exit-0 census.** If the finding needs a human to confirm it, it must
  never gate (`census-*.js`).

**An unsound signal must never gate.** The asymmetry is the point: a false gate-FAIL blocks correct work and trains
people to reach for `--noSyntaxCheck`, and — worse — a false gate-PASS bakes regressions into byte-exact references.
The same safety asymmetry is documented for `fg classify` (a BENIGN? verdict is a hint for reading a diff faster, never
permission to recapture). When in doubt, ship the rule one tier weaker and promote it once the evidence is in.

## 3b-docs. The DOCS ratchet — `check-doc-narration.js` (`fg doc-narration`)

The docs-side twin of the `comment-narration` stink. `docs/README.md` files every doc by what it IS,
and each bucket carries a TENSE; filing rule 3 requires durable residue to land in `architecture/`
"present tense, no changelog prose. The plan keeps the history; the architecture doc keeps only the
current truth." Nothing enforced that, so a doc could drift into explaining a live mechanism by naming
the dead one it replaced — and eventually contradict itself, one section stating a change landed while
another still proposed it.

**Scope is deliberately narrow.** It scans `architecture/` + `tooling/` (present tense by definition)
and NOTHING else: `specs/` is excluded because a spec's change/landing statements are load-bearing
(owner direction), and `plans/`, `archive/` and `measurements/` are chronological BY DESIGN — archive
is immutable past tense, plans are future tense, measurements are dated snapshots.

**It is a RATCHET, not a zero-baseline gate** (same shape as `check-stinks.js`): a per-file baseline in
`buildSystem/check-doc-narration-baseline.json`, failing only when a file's count RISES or a new file
starts narrating. Accretion stops immediately; the pre-existing debt — concentrated in this doc and
`layering-naming-convention.md`, where a ban is often explained by narrating what it removed — burns
down deliberately, banked with `--write-baseline`. A provenance stamp ("verified against `src/` <date>")
is NOT narration and is skipped; `<!-- narration-ok: reason -->` exempts a line that must quote the
trigger words. Fenced blocks and inline code are stripped before matching, so file paths and SHAs
cannot trip it. Not on the build — docs prose should not block a build; run it with `fg doc-narration`.

## 3c. The ANALYSIS tools (advisory censuses — never gates)

**§3 is everything that can fail your build; this section is everything that cannot** — the split that §3b's severity
policy prescribes. Five read-only censuses, all exit 0 (2 on operational error), all ≲1 s. Four are `--json`-capable and print
SUMMARY COUNTS by default, with `--full` for the lists; `census-call-arity.js` is the exception — it is query-shaped
(`--holes` / `--call=` / `--super=` / bare `new <Class>` names) and prints only what you asked for. One of them,
`census-widget-conformance.js`, ALSO has a `--gate` mode that the build runs — that half is a gate and lives in §3's
table. Run them from `Fizzygum/`
— or all at once, with every ratchet's "tighten me" note, via **`fg critique`** (~5 s, read-only). It deliberately
excludes jscpd/jsinspect (minutes-slow — those stay on-demand behind `./find_duplicated_code.sh` /
`./find_similar_code.sh`).

⚠ **`fg` is LOCAL workspace tooling and is committed to NO repo** (the umbrella `Fizzygum-all/` is not a git repo), so
`fg critique` does not exist in a fresh checkout — only the `node ./buildSystem/census-*.js` commands below do. That is
by design, but it means this doc, not `fg`, is the durable description. `fg critique` runs, in order: `check-stinks`,
`check-dead-methods`, `check-unresolved-sends`, `check-call-separation` (reprinting only each one's `UNDER` / stale-entry
NOTE), then the FIVE censuses' summary counts — `census-public-private-calls`, `census-hierarchy-duplication`,
`census-property-placement`, `census-widget-conformance` (its advisory view), and `census-call-arity --holes`, the honest
hole count the `positional-hole` stink cannot see — then an advisory-only footer.

**When do these run?** The GATES run automatically on every build (any `build_it_please.sh`, `fg build/presuite/gauntlet`,
`build_and_test.sh`, the save-watcher) — there is no CI here, so "automatic" means the build on your machine, and
`--noSyntaxCheck` skips all of them. The CENSUSES never run automatically: they are advisory, so they run only when a
human asks (`fg critique`, or directly). The clone scanners are on-demand only (minutes).

| Census | Measures | Notes |
|---|---|---|
| `census-public-private-calls.js` | public/private SELF-call mixing (R1–R4) | ALSO the measurement ENGINE behind the [S]/[U] gate. Its `runCensus()` exports the whole-system **class model** (`classInfo` / `chainOf` / `resolve` — parent + `@augmentWith` mixins + methods + resolution order) and `maskLine`; the two censuses below REUSE it rather than re-implement it. |
| `census-hierarchy-duplication.js` | overrides that add nothing: `IDENTICAL-TO-INHERITED`, `SHADOWS-MIXIN`, `JUST-SENDS-SUPER` | Pharo `ReEquivalentSuperclassMethods`/`ReJustSendsSuper`/`ReLocalMethodsSameThanTrait`. The hierarchy-aware complement to jscpd/jsinspect, which know nothing of inheritance and so can never say "REMOVABLE". |
| `census-property-placement.js` | properties at the wrong level (`PULL-UP`) or wrong scope (`DEMOTE`) | Pharo `ReInstVarInSubclasses`/`ReVariableReferencedOnce`. |
| `census-widget-conformance.js` | the mechanical facets of `measurements/widget-practices-survey-2026-08-14.md`, so that survey is re-runnable rather than a one-off | Its ADVISORY run (exit 0, `--json`) prints six facets; the two OBJECTIVE ones are what `--gate` ratchets on the build (§3). ⚠ Facets 3–6 are heuristics with real exceptions and must NEVER gate — and facet 3 in particular is **not a gap count**: since the widget arc's W7 made `colloquialName` DERIVE from the class name, a class declaring none still answers a true name, so the number says how much of the tree the derivation carries, not how much work is left. On the gated pair: green means "nothing got worse"; only a baseline of 0 also means "nothing is left" |
| `census-call-arity.js` | call sites + top-level argument arity; `--holes` lists calls punching a bare `undefined` through to a later argument (R3) | ⚠⚠ **The real hole count — `positional-hole` sees only the two-adjacent-`undefined` subset and reads 0 while 50 stand.** Paren/quote-aware, joins continuation lines, scans BOTH repos. `--call=<method>` / `--super=<class>` / `new <Class>` modes; excludes `.call`/`.apply`/`.bind`, where `undefined` is a foreign API's *this*-arg. |

**Why the hierarchy-duplication and property-placement censuses can never be promoted to gates** — the reasons are
specific, not ceremonial:
- **`super` is META-COMPILED** (`src/meta/Class.coffee` `_equivalentforSuper` rewrites every super form at fragment
  compile time; a trailing space after a bare `super` once silently dropped forwarded args — the reason
  `check-trailing-whitespace.js` exists). So textual body equivalence is **not** dispatch equivalence.
- **Property access is partly DYNAMIC** (the `Duplicator` engine walks `@[property]`; serialization drives off name
  STRINGS), so "unused" is never statically provable.

Both censuses therefore carry SOUNDNESS RULES earned from false positives they actually produced — documented in their
headers and in the `duplication-report/triage-report.md` ROUND-4/4b sections. Do not "simplify" them away: the method
SIGNATURE is compared, not just the body (`(@color) -> super` is not removable); occurrences outside any method body
count as a distinct user (a multi-line ctor param list is public API); a `.name` member read from another file vetoes
a DEMOTE (22 `PreferencesAndSettings` fields looked local but are the global settings surface); and a WRITE-ONLY
property is never a DEMOTE (it is presumed enumeration payload — see the fix note below). Findings withheld by those
last two rules are COUNTED and printed **separately**, never dropped silently.

**Findings land in the triage ledger, not in a commit:** `duplication-report/triage-report.md` (gitignored working
state; conventions in `docs/tooling/duplicated-code-detection.md`). The report IS the deliverable — acting on it is a separate,
verified arc. The closed round-4 record + its case law: `docs/archive/duplication-triage-2026-07-15-hierarchy-round4.md`.
**The findings have their own plan — now CLOSED: `docs/archive/census-findings-triage-plan.md`.** Phase 0 (fix the write-only
DEMOTE bug) DONE; Phase 3 DONE (13 of 20 actioned, DEMOTE 20 → 7 → 4, zero recaptures); Phase 1 DONE
(`BubblyAppearance.constructor` deleted ⇒ **`census-hierarchy-duplication` is now ZERO on all three of its reports**);
**Phase 2 CLOSED with ZERO actionable — all 10 PULL-UP findings falsified or forbidden.** Read it before acting on ANY
finding.

⚠⚠ **A non-zero census count is not a backlog, and both censuses' most-recommended items were FALSE POSITIVES.**
Across the arc they produced **26 findings that were technically true and wrong to act on** (16 write-only, 10
pull-up) against **13 worth taking**. PULL-UP's own strongest finding — 3 verbatim-identical colour defaults —
would have turned the desktop icons near-white, because each subclass `@augmentWith`es a mixin that injects the same
properties **onto the subclass prototype**, so the class-body default exists to OVERRIDE the mixin, not to duplicate
the parent (`Object-extensions.coffee:18` writes `@::[key] = value`; `meta/Class.coffee:350-373` emits all
`augmentWith` before all class-body fields). The other rejections: dynamic `@[name + "IsConnected"]` access
(`ControllerMixin:32-33`), whole-object enumeration, and deliberate per-family conventions. None is visible to a name
scanner — which is exactly why these are advisory and can never be gates. **Treat a finding as a question, never an
instruction.** Full case law (14 entries): `docs/archive/duplication-triage-2026-07-15-hierarchy-round4.md`.

**The DEMOTE rule requires the property to be READ.** As
originally shipped it did not, so a **WRITE-ONLY** field was reported as demotable. That was wrong twice: demoting a
write-only field makes it **dead**, not local; and a write-only field is usually **enumeration payload** — reached by
`JSON.stringify(obj)` / the `Duplicator` engine's `@[property]` walk / the serializer, none of which a name scanner sees
(the census's KNOWN BLIND SPOT, now stated in its header). It cost **16 false positives out of 36 findings**, of which
**12 were `SystemInfo` fields that ARE the reference-image identity** — `SystemTestsReferenceImage.coffee:31` hashes
`JSON.stringify(@systemInfo)` into every reference filename's `systemInfoHash`, so acting on them would have
invalidated the entire committed reference set. The fix is **exclusion 4**: at least one occurrence must be a
non-assignment. **DEMOTE 36 → 20**; PULL-UP unaffected (byte-identical).

⚠ The test is *"at least one NON-ASSIGNMENT occurrence"*, **not** the `uses >= 2` originally proposed: `@x = 0` followed
by `@x += 1` is two uses and still write-only in effect. Compound assignments count as writes here, deliberately, to
keep the census conservative.

⚠ **The fix also corrected a misleading statistic** — exclusion 3's withheld count fell **49 → 3** (write-only is now
tested first). The `.name` member-read veto was being *blamed* for withholding 49 findings when its true cost is **3**:
the other 46 were write-only false positives it happened to suppress for the wrong reason. Both counts are printed
separately, so neither exclusion can hide behind the other again. The write-only bucket (62) is **not a backlog**:
separating dead state from enumeration payload needs exactly the analysis a name scanner cannot do.

**Considered and REJECTED** (so they are not re-proposed):
- A **`constructor.name` stink** — `new @constructor` / `@constructor.name` is a legitimate universal idiom here, so it
  would ratchet an idiom, not a smell.
- A **`console.log` stink, and `drop_console` in the production build — both rejected 2026-07-15, decided, do not
  re-open without new evidence.** It is true that console.logs are NOT stripped from production (`drop_console` appears
  nowhere in `build_it_please.sh`; `terser --compress` keeps `console.*`), but that fact is operationally empty: of 224
  non-comment sites, **201 are behind an explicit debug flag** (`@detailedDebug`, `window.srcLoadCompileDebugWrites`)
  and all 23 others are multi-line guards, audit blocks, Automator-only paths, or error handlers — **nothing logs in
  normal operation**. `drop_console` would be actively HARMFUL (it strips the error diagnostics we want in prod), and it
  could not shrink the bundle anyway: class sources ship as escaped TEXT and compile in-browser, so terser never sees
  them. A stink at ~213 would ratchet a disciplined idiom — the `constructor.name` mistake again. The one real finding
  inside the item (6 error paths using `console.log` where `console.error` is the verb the gates key off) was fixed.
  Full evidence: carryover plan §8.6.
- Anything **TRANSITIVE** — already rejected as intractable, see §7.

**On `census-public-private-calls.js` specifically** (the oldest of the five, and the only one that is also a gate
ENGINE): it measures public/private SELF-call mixing — private→public-command calls, double-settle shapes, and public
methods only ever `@`-self-called (privatization candidates). `check-call-separation.js` requires it as a module and
enforces the [S]/[U] count baselines on its numbers, and rule [T] (in `check-layering.js`) is the static twin of its
narrowed-R2 report. The campaign that owns the drawdown is **`docs/archive/public-private-call-separation-plan.md`** — re-run
the census at every tranche start. Methodology and blind spots are in the tool's header. Run from `Fizzygum/`:
`node ./buildSystem/census-public-private-calls.js [--full|--json out.json|--self-test]`.

⚠ **One blind spot worth knowing before you chase a phantom [U] NOTE: naming a method inside a macro
source's COMMENT counts as a reference to it.** R4's reference set is harvested from the sibling tests
repo, and a macro lives inside a JS template literal — so from the `.js` file's point of view the
whole CoffeeScript body, `#` comments included, is string content, which is exactly what R4 must scan
(a real call in a macro is string content too). The symptom is a `[U] allowlist entry is no longer
self-only-public` NOTE appearing on a commit that added only a test. It is advisory, never a build
failure — but the honest fix is to reword the comment, not to delete the allowlist entry.

⚠⚠ **The same harvesting rule gives `check-dead-methods` a blind spot it cannot close: a method whose
NAME is an ordinary English word is effectively unkillable.** The gate is NAME-keyed — it has to be,
since a computed-name dispatch can name any method — and it harvests every identifier from every line
of `src/`, the harness and the test `.js` files, with comments NOT stripped on the `.js` side. So a
sentence like *"toggle its window-bar edit button OFF then ON"* in a test's `description` counts as a
reference to `toggle`, and `ToggleButtonWdgt.toggle`/`.select` sat dead and invisible until they were
found by hand (2026-08-18, connector §P10(d)). There is a second, independent half: the gate keys on
the NAME alone, so it cannot tell two same-named methods on unrelated classes apart — a LIVE
`ListWdgt.select` covers a DEAD `ToggleButtonWdgt.select` on its own. ⇒ **the gate is sound in the
direction it claims** (what it flags really is dead) **and silently incomplete in the other**; do not
read a green run as "no dead methods". Making it class-aware is not obviously right — the dynamic
dispatch that forces name-keying would then start producing false positives — so this is recorded as
a stated blind spot rather than a defect to fix blind — a conclusion now MEASURED rather than
assumed (the measurement is in `../archive/connector-ubiquity-and-reflection-plan.md`'s BACKLOG
ledger): only 10% of references to a colliding name carry any class information,
so class-awareness would flag 543 pairs to find a handful; and excluding prose reveals nothing,
because the real survivors are LOCAL VARIABLES sharing a method's name (`for toggle in …`) and
human-readable strings sitting exactly where a string dispatch sits.
⭐⭐ **What makes that the right answer rather than a shrug: the methods a static reference scan
cannot see are precisely the ones the two RUNTIME sweeps above already cover.** Every one of the 21
methods reachable only by a bare word is string-dispatched — a `PinSpec` setter or an
`addMenuItem`/`wireTo` action — and the pin sweep proves those setters RESOLVE while the menu sweep
proves those actions do. "It resolves when dispatched" is strictly stronger than "the name appears
somewhere in the tree", so the coverage is not merely equivalent, it is better, and it lives in the
place that can actually establish it.

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
| **[B]** | any method not in `RECALC_WHITELIST` = `{doOneCycle, _settleLayoutsAfter, _settleLayoutsAfterOrJoinEnclosingPass}` | calling `recalculateLayouts()` | only the frame and the two settle tiers — the single-mutation tier and the reactive-connection lane (rule [P]) — may drive a flush | — | — |
| **[C]** | a public geometry setter | calling another public geometry setter | would flush more than once per logical mutation | — | — |
| **[D]** | a SystemTest macro (`Fizzygum-tests/tests/**/*_automationCommands.js`) + the `Macro.fromString` heredocs in `src/macros/MacroToolkit.coffee` | calling a `_private` method or a `raw*` (pixel) accessor | macros must drive only the public surface (the gate that would have caught the original 16-macro mess) | — | — (HARD ban; the construction measure-and-size carve-out is now CLOSED — attach the widget first, then public setters, see §7) |
| **[E]** | `isImmediateMutator` (the `_apply*`/`_commit*` corners + the `_move*`/`_set*`/`_resize*` convenience) | calling `_invalidateLayout` | an immediate mutator may MUTATE geometry, never SCHEDULE a layout — scheduling during a pass re-dirties a container mid-pass and the convergence loop never terminates (the Phase-3b app-freeze) | `FLOWRULE_VIOLATION` (`Widget._invalidateLayout`) | — |
| **[F]** | a method that is NEITHER low-level NOR an immediate mutator (handler / property setter / menu action / gesture / constructor) | calling a container-refit apply (`_reLayoutChildren`/`_positionAndResizeChildren`/`_reLayoutScrollbars`/`_reLayout`) synchronously OFF-settle | such a handler must DEFER (record intent via `_invalidateLayout`; let the cycle apply it), unless the apply is genuinely AT a settle point / a documented determinism-exempt family | — | **`# layout-apply-sanctioned: <why>`** |
| **[G]** | `isLowLevel` method (not a settle tier) | calling a STRUCTURAL self-settling wrapper — discovered structurally as the `_settleLayoutsAfter` callers (`destroy`/`close`/`fullDestroy`/`createReference*`/`grab`/`drop`/`slideBackTo`/`setLabel`/`buildAndConnectChildren`/`resetWorld`/`sizeToTextAndDisableFitting`) — OR the unambiguous self-add `@add` | the structural-wrapper extension of [A]: each wrapper self-settles via `_settleLayoutsAfter`, so reaching one from a core/raw/pass re-enters the flush; low-level code must call the `_<name>NoSettle` core | the one-flush throw | **`# nosettle-sanctioned: <why>`** |
| **[H]** *(WARNING, non-fatal)* | a method that self-settles via `@_settleLayoutsAfter` | a GUARD `return` / `return if\|unless …` BEFORE the settle | a public settle-wrapper should be THIN; that early-return guard belongs INSIDE the `_<name>NoSettle` core (else the "already in this state" skip is split across wrapper + core) | — | **`# early-return-sanctioned: <why>`** |
| **[I]** | a `__` leaf method (HARD-FAIL) | `@`-self-calling the re-fit seam (`_reFitContainer*`/`_announce*`), a react step (`_reLayout*`/`changed`/`fullChanged`), a schedule/settle (`_invalidateLayout`/`recalculateLayouts`/`_settleLayoutsAfter*`), or a public setter | a `__` leaf is a true bottom — it triggers NO orchestration (the lowest tier of the naming convention, §1) | tier-naming runtime audit | — (DENYLIST; `@`-self-scoped) |
| **[J]** | a notification callback (`_reactTo*`/`_before*`) | calling `_settleLayoutsAfter` | a callback is a settle-neutral core; the gesture/structural DISPATCHER owns the one settle | notification-settle runtime audit | — |
| **[K]** | a 2×2 apply CORNER (`_apply<Geom>` polymorphic / `_apply<Geom>Base` override-bypass twin / `_commit<Geom>AndNotify` notify-only) | a `_apply*Base` bypass twin firing the container re-fit seam (`_reFitContainer*`/`_announce*`) or DISPATCHING to its polymorphic `_apply*` sibling; a `_commit*AndNotify` corner reacting (`changed`/`_reLayout*`) | post-Tier-B the corners are REACT × DISPATCH: a `_apply*Base` reacts but must BYPASS the override — not fire the seam, not route the arrange apply back through `_apply*`; the notify-only corner must not react. The two statically-sound NEGATIVES; the old positive "*AndNotify reaches the seam" is retired with the seam (deleted 2026-07-01) | tier-naming runtime audit (now vacuous) | — |
| **[L]** | a notification callback DEF (`_reactTo*`/`_before*`) | a name not matching `_(reactTo\|before)(Being\|Child\|HolderFrame)<Event>`, a `NoSettle` suffix, or a legacy fragment (`childX`/`justBeen`/`iHaveBeen`/`aboutTo`/`prepareTo`) | callbacks follow the derivable (perspective × phase) scheme; the legacy spellings were retired | — | — |
| **[M]** | any method DEF | a retired geometry/structural naming fragment as the name — `raw[A-Z]…` / `^silent[A-Z]` / `^fullRaw`, unconditionally (the raw-PIXEL accessors `rawPixelInfo`/`rawPixelHash`/`rawRGBA` live in the tests-repo harness, never scanned — the old allowlist never matched anything in src and was removed) | the `raw*`/`silent*`/`fullRaw*` geometry+structural prefixes were eliminated (§2 of the convention); lock them out — note `full[A-Z]` stays legitimate (`fullBounds`/`fullPaintInto`/…) | — | — |
| **[N]** | any method DEF | a name matching `/^_announce\w*ToContainer$/` (the retired notify-by-mutation container seam) | the mutation-time re-fit seam was deleted 2026-07-01 and replaced by the settle-time up-edge `_reFitMyTrackingContainerAfterSettle`; this bans reviving the announce-up verbs on the DEF side (the CALL side is already [I]/[K]) | — | — |
| **[O]** | any method NOT in `COALESCED_CALLER_ALLOWLIST` (seeded `{nonFloatDragging}`) | a `[@.]…Coalesced` CALL to a `*Coalesced` entrypoint (`_setMaxDimCoalesced`/`_setExtentCoalesced`/`_moveToCoalesced`/`_setWidthCoalesced`/`_setHeightCoalesced`) | a `*Coalesced` entrypoint DEFERS its layout settle to the ONE end-of-cycle flush — byte-identical (sound) only for a per-event STREAM handler that never reads back the settled layout mid-cycle; a discrete caller must use the self-settling setter. These entrypoints are `_`-private for the same reason (only stream handlers may reach them) | — | — (add a genuine new stream handler's method name to `COALESCED_CALLER_ALLOWLIST`) |
| **[P]** | any method whose name does NOT end `Connector` | a `[@.]_settleLayoutsAfterOrJoinEnclosingPass` CALL | `_settleLayoutsAfterOrJoinEnclosingPass` is the reactive-connection settle lane — reached mid-pass it JOINS the open layout pass instead of throwing (so a wired reactive circuit — the °C↔°F converter — settles once); sound ONLY for a dedicated `_<name>Connector` entrypoint carrying the `connectionsCalculationToken` cycle-guard. A general/internal caller must use the self-settling `_settleLayoutsAfter` (surfaces the flow violation) or a `_<name>NoSettle` core | `Widget._settleLayoutsAfter` throw (§1) | — |
| **[Q]** | any method NOT in `CONNECTOR_CALLER_ALLOWLIST` (seeded `{recalculateOutput}`) | a hard-coded textual `[@.]_<name>Connector(` CALL | the connector lane JOINS an already-open pass instead of throwing ([P]), so a textual call to one smuggles a never-throwing setter past the flow guard. The reactive dispatch resolves the connector name at RUNTIME and needs no textual call — only a sanctioned mid-cascade self-render (a patch node's `recalculateOutput`) may call one directly | `Widget._settleLayoutsAfter` throw (§1) | — (add a genuine mid-cascade render's method name to `CONNECTOR_CALLER_ALLOWLIST`) |
| **[R]** | a method in a `USERLAND_FILES` file (the standard-user-use exemplars: the menu-built windows/panels of `MenusHelper`) | calling another widget's immediate cores (`<recv>._apply*`/`._move*` — a `@`-self call has no identifier+dot and is not matched) | userland is the worked example of the PUBLIC self-settling API (`setBounds`/`moveTo`/`setExtent`/`setWidth`/`setHeight`/`moveWithin`); the immediate cores are reserved for low-level / in-pass code | — | **`# private-use-sanctioned: <why>`** (per LINE) |
| **[T]** | a method whose own body calls `@_settleLayoutsAfter` (the same textual subject `discoverSettlingWrappers` keys off; the settle tiers in `RECALC_WHITELIST` are exempt) | ALSO `@`-self-calling a settling public method — a geometry setter, a text setter, a discovered settling wrapper (name-qualified via `nearestDefinerKind` like [G]), or the self-add `@add` | two flushes for one logical mutation — the whole-settling-surface generalization of [C]. `@`-self-scoped (a dotted receiver settles ANOTHER widget — untypeable). Branch-exclusive pairs (one flush per path, sound) are textually indistinguishable → marker. At rule birth (2026-07-12) exactly 3 sites, all conscious+marked: `grab` (hand-rolled sequential gesture settles) and `newParentChoice{,WithHorizLayout}` (documented idempotent re-fit flush after `@add`) | the one-flush throw | **`# double-settle-sanctioned: <why>`** |

**[G] specifics.** The wrapper set is **discovered**, never hand-listed: `discoverSettlingWrappers` collects every method
whose body calls `@_settleLayoutsAfter` (`SETTLE_CALL` anchors on that exact name, so the reactive-connection
`…OrJoinEnclosingPass` lane is not swept in), minus the geometry/text setters ([A] reports those, sharper) and minus
`WRAPPER_EXCLUDED` (§7). So a NEW single-settling wrapper is auto-covered. The `@add` self-form is checked separately (`SELF_ADD_CALL =
/@\s*add\b/`): inside a Widget method `@` is a Widget, so `@add child` is unambiguously `Widget.add` — the `\b` excludes
`@addMany`/`@_addNoSettle`, and the leading `@` (not `.`) excludes the Point#add-ambiguous member form.

---

## 5. The in-code markers + the two ratchet idioms

**Markers — "the justification lives AT the method, no central allowlist."** Each exempts a single method/line via a
comment carrying a reason. All fourteen, in one place:

| Marker | Gate / rule | Exempts |
|---|---|---|
| `# layout-apply-sanctioned: <why>` | `check-layering` [F] | a non-mutator method consciously applying a container refit off-settle (an in-pass deferred-seam arm, or a determinism-exempt family: scroll-input / collapse / construction) |
| `# nosettle-sanctioned: <why>` | `check-layering` [G] | a low-level method consciously reaching a settling wrapper / `@add` (e.g. a method mis-tagged low-level, or a genuinely safe outside-any-pass case) |
| `# early-return-sanctioned: <why>` | `check-layering` [H] *(warning)* | a public settle-wrapper that consciously keeps a guard `return` BEFORE its `_settleLayoutsAfter` (suppresses the non-fatal [H] warning) |
| `# double-settle-sanctioned: <why>` | `check-layering` [T] | a directly-settling method that consciously ALSO `@`-calls a settling public method — a deliberate sequential-flush design (`grab`, `newParentChoice`) or a branch-exclusive pair the line scanner cannot tell apart |
| `# public-call-sanctioned: <why>` | `check-call-separation` [S] | a private method consciously `@`-self-calling a public COMMAND (the census subtracts the site; use sparingly — the default fix is rename-to-`_` or the `_<name>NoSettle` core) |
| `# macro-private-call-sanctioned: <reason>` | `check-layering` [D] | one macro/heredoc LINE calling a `_private` verb — a test ORACLE that must reach ground truth (`world._fullChanged()`) |
| `# private-use-sanctioned: <why>` | `check-layering` [R] | one line in a userland exemplar file reaching another widget's private core |
| `# thin-wrap-exempt: <reason>` | `check-thin-wraps` | a method that owns a `_<name>NoSettle` twin but legitimately cannot be the canonical mechanical wrap |
| `# cross-invalidation-sanctioned: <reason>` | `check-invalidation-receivers` | one line marking ANOTHER widget changed (the structural dispatchers, the world's atlas-warm and selection-overlay reconcilers, an async-asset repaint, own-sub-part marks) |
| `# relayout-bounds-first-exempt: <reason>` | `check-relayout-bounds-first` | a `_reLayout` that consciously reads its own geometry before applying its own bounds |
| `# raw-screen-pointer-sanctioned: <reason>` | `check-raw-pointer-reads` | a pointer handler that genuinely wants the raw SCREEN-plane sample (currently ZERO sites) |
| `# escalated-pos-sanctioned: <reason>` | `check-plane-discipline` (C) | a pos-reading pointer handler on a scroll-translation provider that deliberately consumes a descendant-plane pos (currently ZERO sites) |
| `# constructor-build-exempt: <reason>` | `check-constructors-build` | a `constructor:` that legitimately must build its children inline (currently ZERO) |
| `# stringified-script-sanctioned: <reason>` | `check-stringified-scripts` | one `new ScriptWdgt """…"""` line in core |
| `<!-- narration-ok: reason -->` | `check-doc-narration` | one docs LINE that must quote the narration trigger words (this doc's stink table does) |

**Placement is per-gate, and it is not decorative.** The `check-layering` per-method markers ([F]/[G]/[H]/[T]) and
`# public-call-sanctioned` are detected anywhere in the method's body and reset at each method header.
`# thin-wrap-exempt`, `# relayout-bounds-first-exempt` and `# raw-screen-pointer-sanctioned` are read ONLY from the
contiguous comment block *directly above the header* — one in the body does not exempt; `# constructor-build-exempt`
is read from either. The rest are per-LINE: `# cross-invalidation-sanctioned`, `# macro-private-call-sanctioned` and
`# stringified-script-sanctioned` on the line or the comment line(s) directly above it, `# private-use-sanctioned` and
`<!-- narration-ok -->` on the line itself.

⚠ **The reason is required by convention everywhere, but only some gates enforce it.** Seven match
`<marker>:\s*\S` and so reject a bare marker (thin-wrap, relayout-bounds-first, raw-screen-pointer,
constructor-build, cross-invalidation, stringified-script, and [D]'s macro marker); the six `check-layering`/
call-separation per-method markers match the bare string, so nothing but review makes you write the *why*.
Write it anyway — a marker without a reason is exactly the silent allowlist this idiom exists to avoid.

**Two ratchet idioms** (a convention that isn't a gate rots; new rules should use one so they land green today and
tighten incrementally):
- **baseline / allowlist** (`check-dead-methods`, `check-stinks`, `check-unresolved-sends`, `check-call-separation`):
  record the current count/set, fail on *regression*, drive the baseline down over time. To drive down: fix occurrences,
  then tighten the inline `baseline` (stinks, call-separation) or remove from `dead-method-allowlist.txt` /
  `unresolved-sends-allowlist.txt` to lock the gain. Baseline 0 / empty allowlist = a hard rule.
  **The central allowlist files** (each `name # reason`, one per line, `#` comments):
  `buildSystem/dead-method-allowlist.txt` (dead-method) · `buildSystem/unresolved-sends-allowlist.txt`
  (unresolved-sends: vendor + genuinely-dynamic names; platform API goes in that checker's in-file `BUILTINS` instead) ·
  `buildSystem/public-api-allowlist.txt` (call-separation [U]: deliberate end-user inspector/scripting API).
  Each of those gates prints a **stale-entry NOTE** when an entry stops being needed — `fg critique` is the one place
  that resurfaces every such note at once.
- **per-method / per-line marker** (the thirteen in-code markers tabled above): the justification
  lives at the method, no central list; a NEW unmarked violation fails the build. Best when the exception is a property
  of one method or one line, not a count.

---

## 6. The tier / naming convention, co-designed with the lints

`isLowLevel`/`isImmediateMutator` classify by NAME, and the call-detection regexes anchor on `[@.]` + the word-prefix —
so the **naming convention and the lints are co-designed** (the lint works at all only because the name encodes the
behaviour). This section covers just *why the names and the regexes fit together*; the full two-family convention (the
geometry-apply **2×2** + the notification **(perspective × phase)** grid) and its two runtime audits live in
`docs/architecture/layering-naming-convention.md`.
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

## 6b. What "this line defines a method" means — ONE shared matcher, and its guard

Seven gates group a `.coffee` file into methods: `census-public-private-calls`, `check-dead-methods`,
`check-raw-pointer-reads`, `check-layering`, `check-relayout-bounds-first`, `check-thin-wraps`,
`check-menu-actions`. They all
take that definition from **`buildSystem/lib/coffee-method-header.js`** (`METHOD_HEADER` /
`MIXIN_METHOD_HEADER`). Do not re-declare it locally — the module exists because six copies of one regex
had drifted into a shared blind spot nobody could see.

A header is either **closed on the line** (`foo: ->`, `foo: (a, b) ->`, `foo: (a)->`, `foo: (a) =>`) or
**opens a wrapped parameter list** (`foo: (` with nothing after the paren; the continuation lines are
ordinary body lines to every gate, which is correct — they are the signature).

⚠ **The failure mode this protects against is silence, not noise.** A gate that cannot see a method does
not warn about it — it reports nothing, so its output looks healthy and its counts look stable. Both
spellings above escaped every gate until a reformatted signature moved the census's method total by
exactly two; the module's own header comment carries that account. What widening the matcher surfaced:

| revealed | what it was |
|---|---|
| `Widget.paintRectangle` | dead — a ~30-line legacy device-space paint helper with zero callers anywhere |
| 2 rule `[S]` sites | `PopUpWdgt._reactToBeingDropped → @pinPopUp`, `Widget._destroyNoSettle → @onClickOutsideMeOrAnyOfMyChildren` — both conscious and correct, now carrying the `# public-call-sanctioned:` marker they could never be asked for |
| 1 rule `[U]` site | `InspectorWdgt.filterProperties`, an internal helper wearing a public name — renamed `_filterProperties` |
| +1 handler body | one pointer handler had never been scanned by `check-raw-pointer-reads` at all |

`unseenMethodHeaders()` in the same module is the **regression guard**: `check-dead-methods` (which owns
the method inventory) FAILS on any class-level line that ends in an arrow, or opens an unbalanced paren
list, that `METHOD_HEADER` does not match. A future spelling therefore becomes a build error that names
its own fix, instead of another silent hole.

## 7. Documented BOUNDARIES (reasoned gaps, not silent ones)

What the layering gate deliberately does NOT cover, and why — so a maintainer reads a reasoned boundary, never a hole:

- **`escalateEvent`'s plane-local arguments have NO gate — the discipline is a stated rule, enforced by review.**
  Base `Widget.mouseDownLeft`/`mouseClickLeft` escalate their `pos` up the parent chain verbatim, so a pos that
  crosses a mapped-plane boundary (out of a scrolled pane or an island) is still plane-local to the SENDER; a
  pos-consuming handler on a plane's ancestor must re-derive its point (`@screenPointToMyPlane
  world.hand.position()`, as `ViewportWdgt.mouseDownLeft` does — the paint-time-scroll arc's case law: a
  stationary click on scrolled content slammed the drag-to-scroll to its clamp). No sound static check exists:
  whether a handler consumes `pos` GEOMETRICALLY (vs ignoring it, vs plane-safe same-plane use) is semantic, and
  the receiver set ("can this class sit above a mapped plane?") is a tree property no text scan sees. The rule
  lives in `docs/architecture/viewports-and-planes.md` (Boundaries and horizons); the raw-pointer lint covers the
  adjacent-but-different shape (raw `hand.position()` reads at band/containment sites).

- **The `.add` MEMBER form (`expr.add` / `@expr().add`) is excluded; the `@add` SELF form IS covered.** `.add` collides
  with `Point#add`/`Rectangle#add` (vector arithmetic, ubiquitous: `@topLeft().add pt`); a name scanner cannot tell a
  Widget structural add from a Point add on an expression without type inference (29 of 35 census hits were `Point#add`).
  `@add` is unambiguous (self == Widget.add) and IS rule [G]'s `SELF_ADD_CALL`. The runtime throw backstops the member
  form and construction-time `add()` on an orphan.
- **`collapse`/`unCollapse` are now COVERED by [G]** (they were once in `WRAPPER_EXCLUDED`). They appeared in layout
  passes (`FrameWdgt._positionAndResizeChildren`'s editButton/internalExternalSwitchButton); the end-of-cycle-flush drawdown convert routed those call-sites to the
  idempotent `_collapseNoSettle`/`_unCollapseNoSettle` cores, so they were removed from `WRAPPER_EXCLUDED` and [G] now
  guards them like any other wrapper. `WRAPPER_EXCLUDED` now holds only `add` (the `Point#add`-ambiguous member form, above).
- **The TRANSITIVE closure of [G] was prototyped and REJECTED as intractable — DO NOT re-attempt.** A name-based
  backward-reachability fixpoint ("a low-level method must not REACH a settling method by any path") balloons to
  ~720–870 names / ~500–710 false hits: `constructor → buildAndConnectChildren → add` is a universal hub reached by
  `new @constructor` / `@constructor.name` everywhere, and the raw setters / `*NoSettle` cores themselves land in the
  set — so it flags the very "cores call cores" pattern it should bless. Name-based reachability cannot model the orphan
  guard (a receiver's attached-ness is dynamic). The DIRECT rule [G] is the maximal SOUND static check; the throw
  backstops the transitive/dynamic cases. Evidence: `docs/archive/lint-ratchet-static-checks-plan.md` (EXECUTED).
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
rule (subject / forbidden / why / runtime twin / marker) the way [A]–[T] are. (2) Add the check inside `checkFile`'s
per-method loop, under the right tier guard (`isLowLevel(method)` / `isImmediateMutator(method)` / the non-mutator
branch). (3) If it needs an escape hatch, add a per-method marker (mirror the `methodNoSettleMarked` logic) rather than a
central allowlist. (4) Update the summary line + the failure footer to name the new letter. (5) **Land it green** — see
self-test below; triage every hit (fix the code, or mark with a reason); record the marker count.

**Add a new rule — pick the TIER first (§3b): sound negative ⇒ gate · count-shaped ⇒ ratcheted stink ⇒ heuristic ⇒
advisory census.** Shipping a heuristic as a gate is the one mistake this system cannot absorb.

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
Place it among the other gates (~:337–780). If it scans the sibling tests, guard it
(`&& $PROFILE_SHIPS_TESTS && [ -d ../Fizzygum-tests ]`) so a build whose profile omits the `harness` part self-skips —
that derived fact is the same one that writes `BUILDFLAG_LOAD_TESTS`, so gate and world can never disagree about
whether this build has tests.

**Add an advisory census.** `require('./census-public-private-calls.js')` and call `runCensus()` — it hands you the
whole-system class model (`classInfo` / `chainOf` / `resolve`), `allMethods` with per-method body lines and markers, and
`maskLine`. Do NOT re-implement the parse: Fizzygum is image-like (no module system, one class per file, every class a
global), so that model is the subtle part and a second copy would drift. Then: always exit 0 (2 on operational error),
support `--json <file>`, print SUMMARY COUNTS by default with `--full` for the lists, add a step to `fg critique`, and
write findings to the `duplication-report/triage-report.md` ledger rather than to a commit.
⚠ `runCensus()`'s `bodyLines` carry STRING-STRIPPED code (fine for call extraction, wrong for comparing bodies) — if
you need text with strings intact, re-read the source and cut comments with `maskLine`, as
`census-hierarchy-duplication.js` does.

**`compile-fragment.js` — the hand tool beside the syntax gate.** `check-coffee-syntax.js` drives
every *shipped source* through the real `Class.coffee`; `compile-fragment.js` compiles ONE pasted
fragment the same fragmented way, for the question "what does this signature/call actually become".
Use it before converting a parameter list — especially to confirm a trailing `key: value` lands as a
SEPARATE final argument. ⚠ `coffee -bcp <wholefile>` is NOT a substitute: it applies ES-class
semantics (parameters bound after `super`, bare `super` illegal as a statement) that this tree's
emit does not have, and false-fails on most files.

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
  `CONNECTOR_CALL`/`CONNECTOR_CALLER_ALLOWLIST` ([Q]); `USERLAND_FILES`/`USERLAND_PRIVATE_CALL`/`PRIVATE_USE_MARKER`
  ([R]);
  `stripLine` / `METHOD_HEADER` / `methodBoundary` (mixin-DSL aware); `discoverSettlingWrappers`; `checkFile` (rules
  [A]–[T]); `checkMacroFile` (rule [D]); `DOUBLE_SETTLE_MARKER`/`T_SELF_PUB_CALL`/`checkDoubleSettle` ([T]).
- `buildSystem/check-call-separation.js` — `BASELINE_S_SETTLING`/`BASELINE_S_EFFECTFUL` ([S]) +
  `BASELINE_U_EFFECTFUL`/`BASELINE_U_QUERY` ([U]) inline ratchets; reads `public-api-allowlist.txt`;
  requires `census-public-private-calls.js` (`runCensus`, `PUBLIC_CALL_MARKER`).
- `buildSystem/check-thin-wraps.js` — `HEADER`/`GUARD`/`EXEMPT`; twinless skip (`if (!byName.has(base)) continue`).
- `buildSystem/check-constructors-build.js` — `METHOD`/`BUILD`/`EXEMPT`; the `inctor` state machine (multi-line-ctor-header aware).
- `buildSystem/check-dead-methods.js` + `buildSystem/dead-method-allowlist.txt`.
- `buildSystem/check-unresolved-sends.js` + `buildSystem/unresolved-sends-allowlist.txt` — `DEF_FORMS` (the
  over-approximated implementor harvest) / `CALL_RE` / `BUILTINS` / `stripLine` + `interpolatedCode`; `--self-test`.
- `buildSystem/check-stinks.js` — the inline `baseline` per stink; `--list <id>` enumerates one stink's sites.
- `buildSystem/check-part-edges.js` + `buildSystem/lib/part-edge-scan.js` — `codePartOf` / `guardedPartsPerLine` /
  `declaredRequires` (the eager-vs-lazy discount).
- the three retirement tombstones — `buildSystem/check-region-markers.js` (`# »>>`), `check-source-vault.js`
  (`_coffeSource` + boot-layer `Object.keys(window)`), `check-whole-file-markers.js` (the per-file exclusion comments):
  each an inline per-kind `baseline`, all at 0.
- `buildSystem/check-shippable-coverage.js` — `ALLOWLIST_PREFIXES`; shells `build.py --list-shippable` for the
  partition's own answer.
- `buildSystem/census-hierarchy-duplication.js` — `bodyTextOf` / `signatureOf` / `signatureHasEffect`.
- `buildSystem/census-property-placement.js` — `STRING_WORDS` / `MEMBER_FILES` + `readAsMemberElsewhere` (the three
  exclusions); `lineOwnerOf` (the `@classlevel` attribution).
- `buildSystem/check-coffee-syntax.js` — loads `src/meta/Class.coffee`/`Mixin.coffee` to compile fragmented.
- `Fizzygum-tests/scripts/check-tests-syntax.js`, `Fizzygum-tests/scripts/check-refs.js`.
- `build_it_please.sh` — gate wiring (~:337–780), each `if ! $noSyntaxCheck` + `$?`-gated `exit 1`; the two test gates
  additionally `&& $PROFILE_SHIPS_TESTS && [ -d ../Fizzygum-tests ]`.
- `src/basic-widgets/Widget.coffee` — `_settleLayoutsAfter` (~:928; the one-flush throw ~:952); `_invalidateLayout`
  (~:4919; `FLOWRULE_VIOLATION` ~:4959); the immediate-mutator apply corners (`_apply*`/`_commit*`) + the `_<name>NoSettle` cores.

## See also
- `docs/architecture/layering-naming-convention.md` — the full naming convention (the geometry-apply 2×2 + the notification
  (perspective × phase) grid) and its two runtime audit gates; rules [I]/[K]/[L]/[M] (and the [M] fragment-ban) enforce it.
- `docs/archive/layout-system-architecture-assessment.md` — the runtime flush model + the invariant in depth (the *why*).
- `docs/archive/lint-ratchet-static-checks-plan.md` — the arc that built rule [G] (STATUS: EXECUTED); the rejected-transitive record.
- `docs/archive/lint-generic-rules-carryover-plan.md` — the arc that carried over the generic (Pharo SmallLint/Renraku) rules:
  the unresolved-sends gate, the seven stinks, the two advisory censuses, `fg critique`. Its §8 is the surveyed-but-
  DEFERRED backlog (action-string resolution, must-call-super, paired-method contracts, dead classes, metrics ratchet,
  the console.log decision, paren-less call harvesting, the stink-masking upgrade, empty-catch).
- `docs/tooling/duplicated-code-detection.md` — the two clone scanners + the triage-ledger cycle the censuses feed.
- `docs/archive/public-private-call-separation-plan.md` — the AUTHORED (not started) command/query call-separation
  campaign: planned rules [S] (private must not self-call a public command) / [T] (a settling method must not
  call another settling public method) / [U] (self-only public methods must be `_`-tier), sized by
  `buildSystem/census-public-private-calls.js` (the analysis tool noted in §3c).
- `docs/archive/end-of-cycle-flush-drawdown-plan.md` / `end-of-cycle-flush-inventory.md` — the campaign that owns the
  collapse/unCollapse convert.
- Memory `fizzygum-layering-naming-tiers` — the tier predicates + the `NoSettle` convention.
