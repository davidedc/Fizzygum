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
mutator (`setExtent`/`setBounds`/`setWidth`/`setHeight`/`fullMoveTo`, the text setters, `add`/`destroy`/`close`/
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
| `FLOWRULE_VIOLATION` | `Widget.coffee` `_invalidateLayout` (~:3848) | a raw/silent/fullRaw setter schedules layout during a pass | rule **[E]** |

The gates "cannot be spoofed" (they read all shipped source, not a runtime token) but only see what a NAME scanner can;
the throws see the real dynamic receiver but only on tested paths. They are complementary.

---

## 2. The tier predicates — the single source of truth

The layout-method layering is **formally defined**, once, in `buildSystem/check-layering.js`. Two nested tiers:

```js
// LOW-LEVEL (rule [A]/[G] subject): must not reach UP into the public self-flushing layer.
const isLowLevel = (name) =>
  /^raw[A-Z]/.test(name) || /^silent/.test(name) ||   // immediate mutators
  /^_/.test(name) ||                                   // any leading underscore (incl. __)
  /NoSettle$/.test(name) ||                            // the *NoSettle cores
  /Layout$/.test(name);                                // _reLayout & the layout-pass family
// the strict INNER subset (rule [E] subject): may MUTATE, never SCHEDULE.
const isImmediateMutator = (name) => /^(raw[A-Z]|silent|fullRaw)/.test(name);
```

`isLowLevel ⊃ isImmediateMutator`. **Prose must POINT at these predicates, never re-define the tiers** — any doc that
says "low-level"/"immediate mutator" means *exactly whatever these match*. (Known wart: the `/Layout$/` arm is now
vestigial — see §7 Boundaries.)

---

## 3. Gate inventory

All gates are plain Node line-scanners in `buildSystem/` (or, for the test gates, `Fizzygum-tests/scripts/`), wired into
`build_it_please.sh` with the **same shape**: behind `if ! $noSyntaxCheck`, an explicit `$?` check, and a loud
`exit 1` on failure. **Exit codes:** `0` clean · `1` violation · `2` operational error. **Shared escape hatch:**
`--noSyntaxCheck` skips *every* gate (use to bisect a gate bug; never to ship).

| Gate | File | Wired (`build_it_please.sh`) | Enforces | Ratchet mechanism |
|---|---|---|---|---|
| syntax | `buildSystem/check-coffee-syntax.js` | ~:257 | CoffeeScript *parse* errors, compiled the **fragmented** way the browser does | — |
| **layering** | **`buildSystem/check-layering.js`** | **~:279** | **flow soundness — rules [A]–[G] (§4)** | per-method `# layout-apply-sanctioned` [F] / `# nosettle-sanctioned` [G] markers |
| dead-method | `buildSystem/check-dead-methods.js` | ~:297 | a method defined in src but referenced nowhere (src + harness + macro `.js`) | allowlist `dead-method-allowlist.txt`; fails only on a NEW dead method |
| stinks | `buildSystem/check-stinks.js` | ~:315 | named smells driven to a baseline COUNT | per-smell inline `baseline`; fails on EXCEEDING it |
| thin-wrap | `buildSystem/check-thin-wraps.js` | ~:333 | a public method owning a `_<name>NoSettle` twin is the ONE canonical mechanical wrap | per-method `# thin-wrap-exempt: <reason>`; SKIPS a twinless `*NoSettle` |
| test-.js syntax | `Fizzygum-tests/scripts/check-tests-syntax.js` | ~:352 | JS syntax of the macro SystemTest `.js` files, before the build copies them in | — (self-skips on `--homepage`/`--notests`/absent sibling) |
| ref-image integrity | `Fizzygum-tests/scripts/check-refs.js` | ~:370 | >1 `dataHash` per `(test,image,dpr,OS)` or an orphaned `.js`/`.png` reference | — (self-skips like the test gate) |

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

---

## 4. `check-layering.js` rules [A]–[G]

The scanner strips `#` comments and string literals (carrying multi-line state) so a call-regex never matches a name in
a throw-message or comment, groups lines into 2-space-indent methods (`METHOD_HEADER`), and keys call detection off a
leading `@`/`.` + the lowercase public name (so `@setExtent`/`.fullMoveTo` match while `@rawSetExtent`/`@_setTextNoSettle`
do NOT — the `raw`/`silent`/`_` sits between the `@`/`.` and the verb). This co-design with the **naming convention** is
why the lint works at all (§6).

| Rule | Subject | Forbids | Why | Runtime twin | Marker |
|---|---|---|---|---|---|
| **[A]** | `isLowLevel` method | calling a public geometry setter (`setExtent`/`fullMoveTo`/`setBounds`/`setWidth`/`setHeight`), a single-settling text setter (`setText`/`setFontSize`/`setFontName`/`toggleShowBlanks`/`toggleWeight`/`toggleItalic`/`toggleIsPassword`), or `recalculateLayouts` | low-level code mutates immediately and must never reach UP into the self-flushing layer | the one-flush throw | — (fix the code: use the core/raw setter) |
| **[B]** | any method not in `{doOneCycle, _settleLayoutsAfter, _settleLayoutsAfterBatch}` | calling `recalculateLayouts()` | only the frame and the settle tiers may drive a flush | — | — |
| **[C]** | a public geometry setter | calling another public geometry setter | would flush more than once per logical mutation | — | — |
| **[D]** | a SystemTest macro (`Fizzygum-tests/tests/**/*_automationCommands.js`) | calling a `_private` method | macros must drive only the public surface (the gate that would have caught the original 16-macro mess) | — | — (planned raw/silent tightening: NOT-YET-RIPE, see §7) |
| **[E]** | `isImmediateMutator` (`raw*`/`silent*`/`fullRaw*`) | calling `_invalidateLayout` | an immediate mutator may MUTATE geometry, never SCHEDULE a layout — scheduling during a pass re-dirties a container mid-pass and the convergence loop never terminates (the Phase-3b app-freeze) | `FLOWRULE_VIOLATION` (~:3848) | — |
| **[F]** | a method that is NEITHER low-level NOR an immediate mutator (handler / property setter / menu action / gesture / constructor) | calling a container-refit apply (`_reLayoutChildren`/`_positionAndResizeChildren`/`_reLayoutScrollbars`/`_reLayout`) synchronously OFF-settle | such a handler must DEFER (record intent via `_invalidateLayout`; let the cycle apply it), unless the apply is genuinely AT a settle point / a documented determinism-exempt family | — | **`# layout-apply-sanctioned: <why>`** |
| **[G]** | `isLowLevel` method (not a settle tier) | calling a STRUCTURAL self-settling wrapper — discovered structurally as the `_settleLayoutsAfter` callers (`destroy`/`close`/`fullDestroy`/`createReference*`/`grab`/`drop`/`slideBackTo`/`setLabel`/`buildAndConnectChildren`/`resetWorld`/`sizeToTextAndDisableFitting`) — OR the unambiguous self-add `@add` | the structural-wrapper extension of [A]: each wrapper self-settles via `_settleLayoutsAfter`, so reaching one from a core/raw/pass re-enters the flush; low-level code must call the `_<name>NoSettle` core | the one-flush throw | **`# nosettle-sanctioned: <why>`** |

**[G] specifics.** The wrapper set is **discovered**, never hand-listed: `discoverSettlingWrappers` collects every method
whose body calls `@_settleLayoutsAfter` (the SINGLE-mutation tier only — a `_settleLayoutsAfterBatch` wrapper ABSORBS
nested settles and is safe), minus the geometry/text setters ([A] reports those, sharper) and minus `WRAPPER_EXCLUDED`
(§7). So a NEW single-settling wrapper is auto-covered. The `@add` self-form is checked separately (`SELF_ADD_CALL =
/@\s*add\b/`): inside a Widget method `@` is a Widget, so `@add child` is unambiguously `Widget.add` — the `\b` excludes
`@addMany`/`@_addNoSettle`, and the leading `@` (not `.`) excludes the Point#add-ambiguous member form.

---

## 5. The three in-code markers + the two ratchet idioms

**Markers — "the justification lives AT the method, no central allowlist."** Each exempts a single method/line via a
comment, with a *required reason*:

| Marker | Gate / rule | Exempts |
|---|---|---|
| `# layout-apply-sanctioned: <why>` | `check-layering` [F] | a non-mutator method consciously applying a container refit off-settle (an in-pass deferred-seam arm, or a determinism-exempt family: scroll-input / collapse / construction) |
| `# nosettle-sanctioned: <why>` | `check-layering` [G] | a low-level method consciously reaching a settling wrapper / `@add` (e.g. a method mis-tagged low-level, or a genuinely safe outside-any-pass case) |
| `# thin-wrap-exempt: <reason>` | `check-thin-wraps` | a public method that owns a `_<name>NoSettle` twin but legitimately cannot be the canonical mechanical wrap |

A marker is detected anywhere in the method's body (it resets at each method header). The reason is mandatory — a bare
marker does not exempt.

**Two ratchet idioms** (a convention that isn't a gate rots; new rules should use one so they land green today and
tighten incrementally):
- **baseline / allowlist** (`check-dead-methods`, `check-stinks`): record the current count/set, fail on *regression*,
  drive the baseline down over time. To drive down: fix occurrences, then tighten the inline `baseline` (stinks) or
  remove from `dead-method-allowlist.txt` (dead-method) to lock the gain. Baseline 0 / empty allowlist = a hard rule.
- **per-method marker** (`# layout-apply-sanctioned`, `# nosettle-sanctioned`, `# thin-wrap-exempt`): the justification
  lives at the method, no central list; a NEW unmarked violation fails the build. Best when the exception is a property
  of one method, not a count.

---

## 6. The `NoSettle` naming convention, co-designed with the lints

`isLowLevel`/`isImmediateMutator` classify by NAME, and the call-detection regexes anchor on `[@.]` + the word-prefix —
so the **naming convention and the lints are co-designed**:
- **raw / silent / fullRaw** setters — the lowest tier: mutate geometry IMMEDIATELY, schedule nothing. The word sits
  between the `@`/`.` and the verb, so `@rawSetExtent` does NOT match the public-setter regex `[@.]\s*setExtent`.
- **`_<name>NoSettle` cores** — do the mutation + invalidate, never settle ("cores call cores"). The leading `_` makes
  `@_setTextNoSettle` invisible to the `[@.]\s*setText\b` text-setter regex.
- **`NoSettle` suffix = a "non-settling region" signal, TWIN-OPTIONAL** (owner-decided 2026-06-25) — it marks the
  *property* (nothing downstream settles), not "the core of a public/core pair". So a gesture/lifecycle hook that runs
  inside a caller-supplied settle carries it with no public twin (`_reactToGrabOfNoSettle`/`_reactToDropOfNoSettle`/
  `_justDroppedNoSettle`, `_addInPseudoRandomPositionNoSettle`); the thin-wrap gate SKIPS a twinless `*NoSettle`.
  Memory: `fizzygum-layering-naming-tiers`.

---

## 7. Documented BOUNDARIES (reasoned gaps, not silent ones)

What the layering gate deliberately does NOT cover, and why — so a maintainer reads a reasoned boundary, never a hole:

- **The `.add` MEMBER form (`expr.add` / `@expr().add`) is excluded; the `@add` SELF form IS covered.** `.add` collides
  with `Point#add`/`Rectangle#add` (vector arithmetic, ubiquitous: `@topLeft().add pt`); a name scanner cannot tell a
  Widget structural add from a Point add on an expression without type inference (29 of 35 census hits were `Point#add`).
  `@add` is unambiguous (self == Widget.add) and IS rule [G]'s `SELF_ADD_CALL`. The runtime throw backstops the member
  form and construction-time `add()` on an orphan.
- **`collapse`/`unCollapse` excluded** (in `WRAPPER_EXCLUDED`). They appear in layout passes today
  (`WindowWdgt._positionAndResizeChildren`'s editButton/internalExternalSwitchButton; `HorizontalMenuPanelWdgt._reLayoutSelf`)
  — the "SwitchButton-collapse" item OWNED by the end-of-cycle-flush drawdown campaign's OPEN re-probe set. [G] defers
  there rather than rubber-stamp a marker. **When that convert lands** (cores created, call-sites routed), remove
  `collapse`/`unCollapse` from `WRAPPER_EXCLUDED` so [G] covers them.
- **The TRANSITIVE closure of [G] was prototyped and REJECTED as intractable — DO NOT re-attempt.** A name-based
  backward-reachability fixpoint ("a low-level method must not REACH a settling method by any path") balloons to
  ~720–870 names / ~500–710 false hits: `constructor → buildAndConnectChildren → add` is a universal hub reached by
  `new @constructor` / `@constructor.name` everywhere, and the raw setters / `*NoSettle` cores themselves land in the
  set — so it flags the very "cores call cores" pattern it should bless. Name-based reachability cannot model the orphan
  guard (a receiver's attached-ness is dynamic). The DIRECT rule [G] is the maximal SOUND static check; the throw
  backstops the transitive/dynamic cases. Evidence: `docs/lint-ratchet-static-checks-plan.md` (EXECUTED).
- **Rule [D]'s raw/silent/fullRaw tightening is NOT-YET-RIPE.** Forbidding macros from the immediate geometry API was
  assessed: the only remaining macro raw-uses are 6 `silentRawSetWidth/Height` *measure-and-size read-backs* on orphans
  (set width → measure the wrap AT that width → set height) with no behaviour-preserving public alternative. Re-ripens
  only once a public "size to wrapped text at width" construction helper exists.
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
rule (subject / forbidden / why / runtime twin / marker) the way [A]–[G] are. (2) Add the check inside `checkFile`'s
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
Place it among the other gates (~:255–335). If it scans the sibling tests, guard it
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

- `buildSystem/check-layering.js` — `PUBLIC_SETTERS`/`TEXT_SETTERS`/`RECALC_WHITELIST` (~:50–64); `isLowLevel` (~:66),
  `isImmediateMutator` (~:110); `SETTLE_CALL`/`WRAPPER_EXCLUDED`/`SELF_ADD_CALL`/`NOSETTLE_MARKER` (the [G] constants);
  `stripLine` / `METHOD_HEADER`; `discoverSettlingWrappers`; `checkFile` (rules [A]–[G]); `checkMacroFile` (rule [D]).
- `buildSystem/check-thin-wraps.js` — `HEADER`/`GUARD`/`EXEMPT`; twinless skip (`if (!byName.has(base)) continue`).
- `buildSystem/check-dead-methods.js` + `buildSystem/dead-method-allowlist.txt`.
- `buildSystem/check-stinks.js` — the inline `baseline` per stink.
- `buildSystem/check-coffee-syntax.js` — loads `src/meta/Class.coffee`/`Mixin.coffee` to compile fragmented.
- `Fizzygum-tests/scripts/check-tests-syntax.js`, `Fizzygum-tests/scripts/check-refs.js`.
- `build_it_please.sh` — gate wiring (~:255–370), each `if ! $noSyntaxCheck` + `$?`-gated `exit 1`.
- `src/basic-widgets/Widget.coffee` — `_settleLayoutsAfter` (the one-flush throw ~:813); `_invalidateLayout`
  (`FLOWRULE_VIOLATION` ~:3848); the raw/silent setters + the `_<name>NoSettle` cores.

## See also
- `docs/layout-system-architecture-assessment.md` — the runtime flush model + the invariant in depth (the *why*).
- `docs/lint-ratchet-static-checks-plan.md` — the arc that built rule [G] (STATUS: EXECUTED); the rejected-transitive record.
- `docs/end-of-cycle-flush-drawdown-plan.md` / `end-of-cycle-flush-inventory.md` — the campaign that owns the
  collapse/unCollapse convert.
- Memory `fizzygum-layering-naming-tiers` — the tier predicates + the `NoSettle` convention.
