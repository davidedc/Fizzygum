# Plan — fix the connection-cascade flow-violation throw (C↔F converter et al.)

**Status: NEW 2026-07-03. Self-contained; runnable COLD by an executor with NO prior context — start at §0.5.**
This plan fixes ONE pre-existing defect (a few days old): in reactive "patch-programming" circuits — most
visibly the **°C ↔ °F converter** desktop app — moving a slider handle or editing a connected text box throws

> `Error: Fizzygum: a public geometry setter was reached during a layout flush/pass -- internal layout code
> (_reLayout / _reLayoutSelf / ...) must use the immediate (geometry) mutators, not the public deferred API
> (see buildSystem/check-layering.js).`

instead of propagating the conversion around the circuit. It is UNRELATED to any other in-flight work.

**REVIEW 2026-07-03 (fact-check pass): every `file:line` fact below was re-verified against source @ `8a3367a8`,
and the §5a repro was re-run against the current build — the THROW reproduces verbatim. Amendments folded in
(each marked "REVIEW"):**
- **Step 1 narrowed:** the join primitive joins ONLY the settle's MUTATION WINDOW; reached inside the flush walk
  (`world._recalculatingLayouts`) it keeps the strict lane's orphan-defer + throw (§2 box) — strictly safer, and
  costs the cascade use-case nothing (a cascade never runs during a flush).
- **Step 3 consolidated:** ONE `ControllerMixin._fireConnection` helper instead of 8 copies of the routed-dispatch
  incantation; `Widget._connectorVariantOr` dropped (inlined there). All 8 dispatch classes carry the mixin (verified).
- **Step 4 corrected:** the 3 patch-node renders call `_setTextConnector`, NOT the bare `_setTextNoSettle` —
  fact 9's "mid-cascade ⇒ a settle is already open" had two reachable counter-examples (fact 9, corrected).
- **NEW step 2b:** a complete census (fact 13) shows `setFontSize` is the ONLY other self-settling wireable
  action — extract its core + add its connector, closing the whole bug class, not just the converter's instance.
- **NEW step 6 + §7:** flip the three PLANNED doc rows as part of the fix; related cleansing side-quests
  (token-guard ×33 extraction, `openTargetPropertySelector` ×8 consolidation, …) recorded for separate passes.
- Fact fixes: fact 3 (the core's last line is the reflow; `updateTarget` is second-to-last) and fact 11
  (`LEAF_FORBIDDEN` backs rule `[I]`, not `[E]`).

---

## §0 — Why this now, and what it is

Fizzygum's layout engine has a **flow-soundness guard**: a *public* geometry/text setter that self-settles
(`@_settleLayoutsAfter => @_xxxNoSettle …`) THROWS if it is reached while a layout flush/pass is already open on an
*attached* widget (`Widget._settleLayoutsAfter`, the `throw` at `src/basic-widgets/Widget.coffee:797`). The guard
was added during the 2026-07-01 "proper-layouts" seam-deletion campaign; before it, such a reach was silently
deferred. `StringWdgt.setText`'s own header comment (`src/basic-widgets/StringWdgt.coffee:1264-1272`) *predicted* the
exact caller that now trips it:

> "…if some future caller (e.g. **a connection's updateTarget dynamically dispatching to setText**) reaches it
> mid-pass, it SURFACES the violation rather than silently deferring it."

That "future caller" is the reactive **connection cascade**. When a value propagates around a wired circuit, each
node's update can call a *self-settling* public setter (`setText`); the FIRST such call opens a settle, and a LATER
one — reached deeper in the same synchronous cascade, on an attached widget — hits the guard and throws.

**The fix is a new, dedicated "connector" settle-lane**, parallel to the existing lanes, so the whole cascade
settles ONCE. This is the owner's design (see §2): *one settle-mechanism per use-case*.

**Behaviour intent:** BEHAVIOUR CHANGE — the converter (and any similar circuit) must now propagate instead of
throwing. All 165 SystemTests must stay byte-identical (the converter apps are NOT in the suite; see §5), and the
determinism battery must stay clean.

**Tooling — how this was detected and how it is verified (code links):**
- **Detection:** the runtime flow-violation guard `Widget._settleLayoutsAfter` (`src/basic-widgets/Widget.coffee`, the
  `throw` ~:797) surfaced the error in `src/apps/DegreesConverterApp.coffee`; it was reproduced + stack-traced
  headlessly against the built world (`Fizzygum-builds/latest/index.html`) with a `puppeteer` probe (distilled in §5a)
  that opens the converter, drives `slider.setValue(30)`, and catches the throw. The cascade it rides is
  `ControllerMixin.setTargetAndActionWithOnesPickedFromMenu` (`src/mixins/ControllerMixin.coffee:29`) → the 8
  `@target[@action]` dispatch sites (§1 fact 7).
- **Static gate:** `buildSystem/check-layering.js` — its rule `[O]` (`COALESCED_CALLER_ALLOWLIST`) is the template for
  the new `[P]` (§3 step 5); reference docs: `docs/lint-and-static-checks.md` §4 + `docs/layering-naming-convention.md`
  §4 (both carry the `[P]` row, marked PLANNED, pointing back here).
- **Behavioural gate:** `./fg gauntlet` (dpr1/dpr2/webkit + apps smoke + audit gates) + the four-config torture (§5b),
  plus the §5a acceptance probe. The new settle-lane is documented in `docs/layout-system-architecture-assessment.md`
  §2.2 and `docs/layering-naming-convention.md` §2.5.

---

## §0.5 — Cold-execution protocol (READ THIS FIRST in a fresh session)

**The workspace.** `Fizzygum-all/` is an umbrella dir (NOT a git repo) holding three sibling git repos:
`Fizzygum/` (source — the ONLY place you edit; code under `src/**/*.coffee`, docs under `docs/*.md`, build gates
under `buildSystem/*.js`), `Fizzygum-tests/` (the SystemTest suite + headless harness — no edits planned here),
`Fizzygum-builds/` (generated output — **never edit, never grep from the workspace root**; ~1.3 GB). All build/test
commands go through the **`./fg` wrapper at the umbrella root** — it is cwd-correct from anywhere, kills zombie
headless browsers, and gates on real exit codes. Do NOT hand-chain `cd`s across repos.

**How the framework compiles (why the fix looks the way it does).** There is no module system; every class is a
global compiled in-browser at boot from its source-as-text. Reference another class just by naming it. `nil` means
`undefined` (a Fizzygum global) — use it, never `null`/`undefined`.

**Baseline drift.** Every `file:line` below was exact at the time of writing (Fizzygum master shortly after commit
`8a3367a8`). Line numbers drift as files change. **Before EVERY edit: `grep -n` the method name / a distinctive
quoted fragment and confirm the quoted "before" text matches what is there. The method name + the quoted code are
authoritative; the line number is only a hint.** If a quoted "before" does not match at all, STOP and report.

**CoffeeScript gotchas (this codebase — they bite).**
- Indentation IS syntax; reproduce the exact leading spaces of the surrounding code (class methods indent 2, bodies
  4, nested 6…).
- `#{expr}` is string interpolation inside `"…"`.
- `x?` is an existence check (`x != null`); `obj[name]?` tests the property; `obj.meth?()` calls only if present.
- Trust `./fg build` (it compiles each source the fragmented way the browser does), NOT your own `coffee -c` on a
  whole file (that false-fails on most files).

**The per-item loop.** For each step: (1) run its pre-flight grep; (2) apply the exact edit; (3) `./fg build` from
the umbrella root — PASS = it prints `0 violations` and `done!!!` (≈1–2 min). Then the next step. Run the suites
only at the very end (§5) — they are the expensive part.

**Commit protocol (STRICT).** NEVER `git commit`/`git push` on your own — this is a review-driven project. When
green, present a per-repo diff summary + a proposed commit message and WAIT for approval. When approved, commit via
`git commit -F <msgfile>` (never `-m` with backticks/`$()` — bash command-substitutes them and corrupts the message).
End the commit message with the EXECUTING session's attribution trailer (model + session link — the pair below is
the DRAFTING session's; substitute your own):
```
Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_013zcRWwBpenKieFjgnpjpGj
```

---

## §1 — Evidence bank: the exact mechanism (do not re-derive)

**Reproduced headlessly; the stack trace and every fact below are verbatim from the running build.**

1. **The circuit.** `DegreesConverterApp.buildWindow` (`src/apps/DegreesConverterApp.coffee:68-73`) wires, with
   HARD-CODED action strings:
   ```
   slider1 ──"setText"──▶ cText ──"setInput1"──▶ calc1 ──"setText"──▶ fText ──"setValue"──▶ slider2 ──"setInput1"──▶ calc2 ──"setValue"──▶ slider1
   ```
   (`cText`/`fText` are `TextWdgt`; `calc1`/`calc2` are `CalculatingPatchNodeWdgt`; the sliders are `SliderWdgt`.)
2. **Connections propagate through `updateTarget`.** A controller widget, when its value changes, calls
   `@target[@action].call @target, <value>, <arg>, @connectionsCalculationToken`. That dynamic dispatch IS the wire.
3. **`setText` self-settles AND propagates.** `StringWdgt.setText` (`:1274-1282`) is
   `@_settleLayoutsAfter => @_setTextNoSettle theTextContent`; its core `_setTextNoSettle` (`:1239-1259`) fires
   `@updateTarget()` (`:1258`, second-to-last line — the last is `@_reflowContainedTextThenInvalidateLayout()`) — so
   setting a text box's text fires the next node in the circuit.
4. **The cycle-guard lives in the PUBLIC setter, not the core.** `setText`'s first line (`:1275`) is the
   `connectionsCalculationToken` guard: `if !superCall and connectionsCalculationToken == @connectionsCalculationToken
   then return …`. `_setTextNoSettle` has **no token parameter at all** and does no guarding. (Same pattern in
   `SliderWdgt.setValue :107`, `CalculatingPatchNodeWdgt.setInput1 :56`.) So dispatching a cascade to the raw
   `_setTextNoSettle` core would DROP cycle-detection → infinite loop.
5. **The throw — verbatim stack (moving slider1):**
   ```
   probe → slider1.setValue(30) → slider1.updateTarget
     → cText.setText("30")                  [setText #0, world._inLayoutMutation=false → OPENS the settle]
       → _settleLayoutsAfter → cText._setTextNoSettle
         → cText.updateTarget → calc1.setInput1("30")
           → calc1.updateTarget → recalculateOutput()   (computes 30°C → 86°F)
             → calc1.outputTextAreaText.setText("86")    [setText #1, world._inLayoutMutation=TRUE]
               → _settleLayoutsAfter  → THROW  (attached widget, mid-pass)
   ```
   Instrumentation confirmed exactly two `setText` before the throw, on DIFFERENT widgets — `cText` (the °C input
   display) and `calc1.outputTextAreaText` (calc1's own result display). It is a **single forward pass**, NOT a
   re-visit of a node; the token-guard IS working (it stops the loop when it later reaches slider1 — but the throw
   fires first).
6. **The calc node does TWO text-writes per reaction.** `CalculatingPatchNodeWdgt.updateTarget`
   (`src/patch-programming/CalculatingPatchNodeWdgt.coffee:90-128`) calls, in order: (a) `recalculateOutput()`
   (`:119`) which RENDERS its own result via `@outputTextAreaText.setText @output + ""` (`:152`, a DIRECT call), then
   (b) `fireOutputToTarget()` (`:126`) which PROPAGATES to the next wired widget via
   `@target[@action].call @target, @output, nil, @connectionsCalculationToken` (`:139`) → `fText.setText`. **Both**
   are self-settling `setText` reached mid-pass; #1 above is (a). Empirically, fixing only (a) to use the core moves
   the throw to (b) (`fText.setText`, via `fireOutputToTarget`) — proven by a throwaway probe.
7. **The 8 reactive dispatch sites** (each does `@target[@action].call @target, …, @connectionsCalculationToken`):
   `PaletteWdgt.coffee:96`, `SimplePlainTextWdgt.coffee:172`, `basic-widgets/StringWdgt.coffee:1341`,
   `basic-widgets/SliderWdgt.coffee:154`, `patch-programming/FanoutPinWdgt.coffee:54`,
   `patch-programming/DiffingPatchNodeWdgt.coffee:142`, `patch-programming/RegexSubstitutionPatchNodeWdgt.coffee:141`,
   `patch-programming/CalculatingPatchNodeWdgt.coffee:139`. (`ButtonWdgt.coffee:110` and `ListWdgt.coffee:122` also do
   `@target[@action].call` but pass NO token — a different, non-cascade mechanism; LEAVE them.)
8. **All 3 patch nodes render output via `setText`** (direct calls, all reached only mid-cascade — see fact 9):
   `CalculatingPatchNodeWdgt.coffee:152` `@outputTextAreaText.setText @output + ""`;
   `DiffingPatchNodeWdgt.coffee:152` `@textWidget.setText @output`;
   `RegexSubstitutionPatchNodeWdgt.coffee:162` `@outputTextAreaText.setText @output`.
9. **`recalculateOutput` is only ever reached mid-cascade — but a cascade does NOT always carry an open settle.**
   It is called ONLY from `updateTarget` (`:119`; verified codebase-wide — the analogous single call sites in the
   Diffing/Regex nodes are their `:119`/`:121`), reached via `setInput1..4` and `bang` — and `bang` sets
   `fireBecauseBang=true`, which SKIPS `recalculateOutput` (`:114`
   `if allConnectedInputsAreFresh and !fireBecauseBang`). Construction / first-connection goes through
   `reactToTargetConnection → fireOutputToTarget` (`:141-145`), NOT `recalculateOutput`.
   **REVIEW CORRECTION (2026-07-03): a settle is open only when an UPSTREAM hop was a self-settling setter.** Two
   REACHABLE cascades hit the render with NO settle open: (a) live wiring text→calc.in1 from the menu —
   `setTargetAndActionWithOnesPickedFromMenu → reactToTargetConnection → updateTarget → setInput1 → updateTarget →
   recalculateOutput`, nothing upstream settles; (b) any circuit headed by immediate-only setters, e.g.
   slider→calc→slider (`setValue`/`setInput1` never settle). TODAY the render's `setText` OPENS a settle in those
   cases; the bare `_setTextNoSettle` would instead leave an OFF-SETTLE careless push riding the end-of-cycle flush
   (the exact class `auditUndeclaredEndOfCycle` exists to catch, driven to 0 by the flush-drawdown campaign) AND
   would skip the fresh-token mint today's direct `setText` performs (a stale token would then ride any onward wire
   a user later attaches to the display). Hence §3 step 4 uses `_setTextConnector` (join-or-OPEN ≡ today's render
   minus the throw), not the bare core. The calc's `outputTextAreaText` is a leaf display wired to nothing, so its
   `@updateTarget()` stays a no-op either way.
10. **The self-settle primitive to mirror.** `Widget._settleLayoutsAfter` (`src/basic-widgets/Widget.coffee:773-811`):
    early-return if `!world?`; if mid-pass (`world._inLayoutMutation or world._recalculatingLayouts`) then defer for an
    orphan else THROW; otherwise set `world._inLayoutMutation = true`, run the thunk, `world.recalculateLayouts()`,
    reset the flag in `finally`.
11. **Lint scaffolding.** `buildSystem/check-layering.js` scans each method body with regexes and per-method markers.
    The template to copy is rule **[O]** (`:287-302, :519-523`): `const COALESCED_CALL = /[@.]\s*(\w+Coalesced)\b/;`
    + `const COALESCED_CALLER_ALLOWLIST = new Set([…]);` + in the per-method loop
    `const m = code.match(COALESCED_CALL); if (m && !ALLOWLIST.has(method)) violations.push('[O] …');`. Note
    `PUBLIC_SETTERS = ['setExtent','moveTo','setBounds','setWidth','setHeight']` (`:55`) does NOT include `setText` or
    any `_`-name, and the `[G]/[H]` wrapper rules key on `SETTLE_CALL = /[@.]\s*_settleLayoutsAfter\b/` (`:212`) whose
    trailing `\b` will NOT match `_settleLayoutsAfterOrJoinEnclosingPass` (no word-boundary after "After"). So the new
    connector methods will not trip `[A]/[C]/[G]/[H]`. (`LEAF_FORBIDDEN`, `:218`, does contain `_settleLayoutsAfter\w*`
    and so matches the new name — but it backs rule `[I]`, which scans ONLY `__`-prefixed leaf methods (`:502`
    `if (/^__/.test(method))`), so the single-`_` connectors are never scanned by it.)
12. *(REVIEW)* **The render receivers are `SimplePlainTextWdgt`s, and the `setText` overrides are accounted for.**
    All three patch-node displays are the `textWdgt` of a `SimplePlainTextScrollPanelWdgt` (= a `SimplePlainTextWdgt`,
    `SimplePlainTextScrollPanelWdgt.coffee:30`). `TextWdgt` does NOT override `setText` (so the converter's
    `cText`/`fText` run StringWdgt's, exactly as fact 5's stack shows). `SimplePlainTextWdgt` DOES
    (`SimplePlainTextWdgt.coffee:165-168`: its own token guard + `super …, true` + a TRAILING `@updateTarget()`) —
    but that trailing fire is a DUPLICATE of the one `_setTextNoSettle` already made (`StringWdgt:1258`), with the
    SAME token, absorbed by the receiver's token guard. So the single inherited `_setTextConnector` is faithful for
    every StringWdgt-family receiver — it merely skips a token-deduped no-op (§7 side-quest d). And
    `_setTextNoSettle` has exactly ONE definition codebase-wide (`StringWdgt:1239`, zero overrides), so the
    connector's core dispatch is unambiguous.
13. *(REVIEW)* **Complete census of SELF-SETTLING wireable actions: `setText` and `setFontSize` — nothing else.**
    Every action offered by every `stringSetters`/`numericalSetters`/`colorSetters`/`allSetters` override was
    classified: `setValue`/`setStart`/`setStop`/`setSize` (Slider), `setInput1..4`(+`Hot`)/`setInput`/`bang`
    (nodes/pins/fanout), `setColor` (×7 overrides)/`setBackgroundColor`/`setAlphaScaled`/`setPadding*` (Widget),
    `setParameter` (Example3DPlot) are ALL immediate (mutate + `changed()`/`_reLayoutSelf*`-style, no settle). The
    base menu ALREADY routes "width"/"height" to the IMMEDIATE `_applyWidth`/`_applyHeight` (`Widget.coffee:3524`)
    — precedent that wired geometry deliberately bypasses the settling lane. `setFontSize` (`StringWdgt:1294`, menu
    entry "font size" in `StringWdgt.numericalSetters:1330`, reachable from any numerical controller and from a
    FanoutPin's `allSetters`) IS `@_settleLayoutsAfter`-wrapped → the SAME throw is one wire away (e.g.
    slider ─"setText"→ text ─"setFontSize"→ another text). It has NO `NoSettle` core (inline settle body) and NO
    token guard — it is a SINK (never calls `updateTarget`), so no cycle risk. Step 2b closes it.
14. *(REVIEW)* **The token-guard one-liner is 33× duplicated** (the exact
    `if !superCall and connectionsCalculationToken == @… then return else …` line: StringWdgt, SimplePlainTextWdgt ×2,
    Slider ×2, Widget ×2 (`setColor`/`setBackgroundColor`), Palette, FanoutPin ×2, FanoutWdgt, Calculating ×5,
    Diffing ×5, Regex ×5, GlassBoxTopWdgt, PanelWdgt, ScrollPanelWdgt, WidgetHolderWithCaptionWdgt, Example3DPlot,
    ChildrenStainerMixin, ParentStainerMixin). Step 2 adds copy #34 — deliberately verbatim; the 34→1 extraction is
    §7 side-quest (b), NOT this fix. `Widget.connectionsCalculationToken` defaults to `0` (`Widget.coffee:262`),
    which is why a token-less direct call never false-early-returns (`undefined == 0` is false — CoffeeScript `==`
    compiles to JS `===`).

---

## §2 — The design: a dedicated "connector" settle-lane

**Owner's principle: one settle-mechanism per use-case, all over the same `_xxxNoSettle` core.**

| Use case | Public entrypoint | Settle discipline | Build-gate |
|---|---|---|---|
| general/programmatic API | `setText` | `_settleLayoutsAfter` — self-settles; THROWS if reached mid-pass | `[A]/[G]` |
| per-event stream (drag/scroll) | `_setTextCoalesced` *(none needed yet)* | coalesce → the ONE end-of-cycle flush | `[O]` |
| **reactive connector (NEW)** | **`_setTextConnector`** | **`_settleLayoutsAfterOrJoinEnclosingPass`** — self-settles OR **joins** an already-open pass | **`[P]` (new)** |

**Why a NEW primitive (not `_setTextNoSettle`, and not relaxing `_settleLayoutsAfter`).** The connector lane must:
(a) keep the cycle-guard (fact 4) — so it wraps the SAME token-guarded body as `setText`, not the bare core; and
(b) settle correctly whether it is the FIRST hop (fact 5: `world._inLayoutMutation=false` — it must OPEN the settle)
or a LATER hop (must JOIN, not open a nested settle → not throw). `_settleLayoutsAfterOrJoinEnclosingPass` is
`_settleLayoutsAfter` minus the MUTATION-WINDOW throw: inside an enclosing settle's mutation window it runs the
thunk (joins) for ANY receiver; inside the flush walk it keeps the orphan-defer + throw (REVIEW box below);
otherwise it opens the settle exactly like `_settleLayoutsAfter`. Relaxing `_settleLayoutsAfter` itself is rejected —
that guard must keep throwing for genuine internal-layout misuse; only OPT-IN connector methods join.

**Routing (the "add a suffix at the dispatch" idea, corrected to `Connector`).** The 8 reactive dispatch sites
(fact 7) resolve, per call, the target's dedicated connector variant when it exists: `_<action>Connector` if
`target["_<action>Connector"]?`, else the public `@action` unchanged — centralized in ONE
`ControllerMixin._fireConnection` helper (§3 step 3; all 8 dispatch classes `@augmentWith ControllerMixin`,
verified). Consequences:
- `@action` stays the menu-friendly name (`"setText"`), so the connection menu, the hard-wired app connections
  (fact 1), and any `<action>IsConnected` flags need **NO change**.
- Self-settling targets (`setText`; `setFontSize` after step 2b) route to their connector → join the one settle.
  Non-self-settling targets (`setValue`, `setInput1` — they use immediate `_reLayoutSelf`/`updateTarget`, never open
  a settle; the complete census is fact 13) have no connector and stay public — harmless (they never nest a settle).

**Direct internal renders** (fact 8 — a patch node rendering its OWN result) are NOT dynamic dispatch, but they get
the SAME connector treatment (`_setTextConnector`, §3 step 4): a cascade does not always carry an open settle
(fact 9's review correction), and the connector is byte-faithful to today's direct `setText` render — same token
guard, same fresh-token mint, same core — in BOTH situations: it JOINS when a settle is open, OPENS one when not.

**Join-scope (REVIEW 2026-07-03, folded into step 1).** The primitive joins ONLY the settle's MUTATION WINDOW
(`world._inLayoutMutation` — the phase the whole cascade runs in; the flush starts only after the outermost
connector's thunk returns). Reached from INSIDE the flush walk itself (`world._recalculatingLayouts` — only
reachable from layout code, e.g. a wired AxisWdgt tick label re-titled by its `_reLayout` firing its connection),
it KEEPS `_settleLayoutsAfter`'s orphan-defer + throw: that is a genuine flow violation today and stays one. This
is strictly safer than the symmetric join-both-flags sketch (Appendix) and costs the cascade use-case nothing.

Net: the FIRST connector entrypoint in a cascade opens ONE settle; the patch-node renders and every later wired hop
(all connectors) JOIN it; the whole conversion settles once when the first connector returns.

---

## §3 — Implementation (exact edits; build after each)

### Step 1 — the join primitive `_settleLayoutsAfterOrJoinEnclosingPass` (Widget)

*Pre-flight:* `grep -n "_settleLayoutsAfter: (coreThunk)" src/basic-widgets/Widget.coffee` → 1 hit (~:773).
*How:* in `src/basic-widgets/Widget.coffee`, immediately AFTER the `_settleLayoutsAfter` method's `finally` block
(the `world._inLayoutMutation = false` line, ~:811), add at 2-space method indent:
```coffee

  # The REACTIVE-CONNECTOR settle lane: like _settleLayoutsAfter, but when an enclosing settle's MUTATION WINDOW
  # is already open (world._inLayoutMutation) it JOINS it (runs the core in it) instead of throwing. A connection
  # cascade (a wired reactive circuit) legitimately reaches a self-settling connector entrypoint mid-window --
  # e.g. the C<->F converter: cText's connector opens the settle, and the calc renders + fText's connector hops
  # run inside it -- so the whole cascade settles ONCE, when the OUTERMOST connector returns.
  # Reached from INSIDE the flush walk itself (world._recalculatingLayouts -- only layout code can get here, e.g.
  # a wired AxisWdgt tick label re-titled by its _reLayout firing its connection) it KEEPS the strict lane's
  # orphan-defer + flow-violation throw: layout code must not fire settling entrypoints, cascade or not.
  # RESTRICTED to _<name>Connector callers by check-layering rule [P] -- general/internal code must keep using
  # _settleLayoutsAfter (which also throws mid-WINDOW, surfacing the violation) or a _<name>NoSettle core.
  _settleLayoutsAfterOrJoinEnclosingPass: (coreThunk) ->
    unless world?
      return coreThunk()
    if world._recalculatingLayouts
      return coreThunk() if @isOrphan()
      throw new Error "Fizzygum: a connector entrypoint was reached from inside the layout flush walk -- layout code (_reLayout / _reLayoutSelf / ...) must not fire a connection's settling entrypoint (see buildSystem/check-layering.js, rule [P])."
    if world._inLayoutMutation
      return coreThunk()          # JOIN the enclosing settle's mutation window (no nested settle, no throw)
    world._inLayoutMutation = true
    try
      result = coreThunk()
      world.recalculateLayouts()
      return result
    finally
      world._inLayoutMutation = false
```
*(REVIEW: narrowed from the original join-both-flags sketch — see the §2 join-scope box; the Appendix records the
symmetric variant as superseded. `_connectorVariantOr` was dropped — its resolution now lives inside
`ControllerMixin._fireConnection`, §3 step 3.)*
*Gate:* build.

### Step 2 — the `_setTextConnector` entrypoint (StringWdgt)

*Pre-flight:* `grep -n "setText: (theTextContent" src/basic-widgets/StringWdgt.coffee` → 1 hit (~:1274). Confirm its
body is the token-guard line + the `if stringFieldWidget?` decode + `@_settleLayoutsAfter => @_setTextNoSettle
theTextContent`.
*How:* in `src/basic-widgets/StringWdgt.coffee`, immediately AFTER the public `setText` method (after its
`@_settleLayoutsAfter => @_setTextNoSettle theTextContent`, ~:1282), add at 2-space method indent:
```coffee

  # The reactive-CONNECTOR entrypoint for setText (the connection lane -- see Widget.
  # _settleLayoutsAfterOrJoinEnclosingPass and check-layering [P]). IDENTICAL to the public setText -- same
  # connectionsCalculationToken cycle-guard, same stringFieldWidget decode -- EXCEPT it JOINS an already-open layout
  # pass instead of opening a nested settle (which the public setText's _settleLayoutsAfter would reject mid-pass).
  # The reactive dispatch (Widget._connectorVariantOr) routes wired "setText" connections here; direct/API callers
  # keep using the public setText.
  _setTextConnector: (theTextContent, stringFieldWidget, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken
    if stringFieldWidget?
      theTextContent = stringFieldWidget.text.text
    @_settleLayoutsAfterOrJoinEnclosingPass =>
      @_setTextNoSettle theTextContent
```
*Note:* the token-guard line is copied VERBATIM from `setText:1275` — grep both and confirm byte-identical. (The
copy is deliberate — the 34→1 guard-helper extraction is §7 side-quest (b), a separate pass.)
*Fidelity (REVIEW, fact 12):* receivers include `SimplePlainTextWdgt` (the patch-node displays) — the inherited
connector skips only SPTW's trailing token-deduped duplicate `updateTarget`, a no-op; `TextWdgt` adds no override;
`_setTextNoSettle` has no overrides. One connector on StringWdgt covers the whole family faithfully.
*Gate:* build.

### Step 2b — the `_setFontSizeConnector` entrypoint (StringWdgt) — closes the LAST self-settling wireable action

*(REVIEW addition.)* *Why:* fact 13 — `setFontSize` is the only OTHER wireable self-settling action; without this,
the same throw is one "font size" wire away. (Separable if the owner prefers the minimal converter fix — but it is
~15 lines and closes the class, and the routing helper picks it up with zero further changes.)
*Pre-flight:* `grep -n "setFontSize: (sizeOrWidgetGivingSize" src/basic-widgets/StringWdgt.coffee` → 1 hit
(~:1294; the ONLY definition codebase-wide — verified). Confirm its body is `@_settleLayoutsAfter =>` wrapping the
size-decode + clamp + apply INLINE (no separate core yet).
*How:* two mechanical moves in `src/basic-widgets/StringWdgt.coffee`:
1. Extract the core: move `setFontSize`'s whole thunk body into a new
   `_setFontSizeNoSettle: (sizeOrWidgetGivingSize, widgetGivingSize) ->` directly above it (same body, one settle
   indent removed), and make the public method the bare canonical wrap:
   `setFontSize: (sizeOrWidgetGivingSize, widgetGivingSize) -> @_settleLayoutsAfter => @_setFontSizeNoSettle sizeOrWidgetGivingSize, widgetGivingSize`
   (byte-identical behaviour; the standard public-wrapper-over-core shape).
2. Add the connector below the public method:
```coffee

  # The reactive-CONNECTOR entrypoint for setFontSize (see _setTextConnector above / check-layering [P]).
  # NO connectionsCalculationToken guard: setFontSize is a SINK -- it never calls updateTarget, so a circuit
  # cannot cycle through it; the dispatch's extra (token) argument is simply ignored, exactly as the public
  # setter ignores it today.
  _setFontSizeConnector: (sizeOrWidgetGivingSize, widgetGivingSize) ->
    @_settleLayoutsAfterOrJoinEnclosingPass =>
      @_setFontSizeNoSettle sizeOrWidgetGivingSize, widgetGivingSize
```
*Gate:* build (the extraction turns `setFontSize` into the bare wrap — the `[G]/[H]` wrapper rules and the
`TEXT_SETTERS` exclusion list (`check-layering.js:76`) already know the name; the build confirms).

### Step 3 — ONE dispatch helper in ControllerMixin; the 8 reactive sites shrink to one-liners

*(REVIEW 2026-07-03: consolidated — the original per-site `@target[@_connectorVariantOr @target, @action]`
transform would have left 8 copies of a longer incantation. All 8 dispatch classes `@augmentWith ControllerMixin`
— verified — so the mixin, which already owns `setTargetAndActionWithOnesPickedFromMenu`, is the cohesive home,
and a future dispatch site cannot forget the routing.)*

*Pre-flight:* `grep -n "setTargetAndActionWithOnesPickedFromMenu" src/mixins/ControllerMixin.coffee` → the method
at ~:29. Add after it, at the same 6-space key indent inside `addInstanceProperties fromClass,`:
```coffee

      # The ONE reactive-connection dispatch: fire @action on @target with `value` (+ the optional per-connection
      # argument), routing to the target's dedicated _<action>Connector variant when it defines one (the reactive
      # settle lane that JOINS an enclosing settle -- Widget._settleLayoutsAfterOrJoinEnclosingPass /
      # check-layering [P]) and to the public @action otherwise (setValue / setInput1 / setColor / ... never open
      # a settle, so the public name is already sound -- census: connection-cascade-settle-fix-plan.md fact 13).
      # Resolving HERE -- not at the call sites -- keeps @action the menu-friendly public name everywhere
      # (menus, <action>IsConnected flags, hard-wired app circuits) and gives the routing a single home.
      _fireConnection: (value, argumentToAction = nil) ->
        return unless @target? and @action and @action != ""
        connectorName = "_#{@action}Connector"
        actionToCall = if @target[connectorName]? then connectorName else @action
        @target[actionToCall].call @target, value, argumentToAction, @connectionsCalculationToken
```
Then each of the 8 sites (§1 fact 7) keeps its method shape and swaps its guarded dispatch for the helper call
(grep the quoted "before" dispatch line in each file; the `if @action and @action != ""` guard around it is
absorbed by the helper — delete it with the dispatch it guards):
- `src/basic-widgets/StringWdgt.coffee:1341` and `src/SimplePlainTextWdgt.coffee:172` — `updateTarget`'s
  `@target[@action].call @target, @text, nil, @connectionsCalculationToken` (+ its guard) → `@_fireConnection @text`
- `src/basic-widgets/SliderWdgt.coffee:154` — `…, @value, @argumentToAction, …` → `@_fireConnection @value, @argumentToAction`
- `src/patch-programming/FanoutPinWdgt.coffee:54` — `…, @inputValue, nil, …` → `@_fireConnection @inputValue`
- `src/PaletteWdgt.coffee:96` — KEEP the `if !@target? then return` + `@action = "setColor"` defaulting lines,
  swap only the dispatch line → `@_fireConnection @choice`
- the three `fireOutputToTarget` (`DiffingPatchNodeWdgt.coffee:142`, `RegexSubstitutionPatchNodeWdgt.coffee:141`,
  `CalculatingPatchNodeWdgt.coffee:139`) — KEEP the token-reassign line + its comment, swap the guarded dispatch
  → `@_fireConnection @output`

(The helper's `@target?` guard is new only for the 7 non-Palette sites, where a nil target with a set action would
TODAY TypeError — unreachable via the menus, which always set both; the guard just makes the helper total.)
**Do NOT touch `ButtonWdgt.coffee:110` or `ListWdgt.coffee:122`** (no token — not the cascade), **nor
`FanoutWdgt.updateTarget`** (`:41-45` — a STATIC forward to its pins' immediate `setInput`, no dynamic `@action`).
*Gate:* build after all 8.

### Step 4 — patch-node self-renders use the CONNECTOR (§1 facts 8, 9, 12)

*(REVIEW 2026-07-03: was `_setTextNoSettle`; changed because fact 9's "always inside a settle" was falsified — in
the two no-settle-open cascades the bare core would leave an off-settle careless push riding the end-of-cycle
flush AND skip today's fresh-token mint. The connector is byte-faithful to today's `setText` render — same guard,
same mint, same core — and simply joins instead of throwing when a settle IS open.)*

Three one-token edits (each a DIRECT render of the node's own output, always mid-cascade):
- `src/patch-programming/CalculatingPatchNodeWdgt.coffee:152`
  `@outputTextAreaText.setText @output + ""` → `@outputTextAreaText._setTextConnector @output + ""`
- `src/patch-programming/DiffingPatchNodeWdgt.coffee:152`
  `@textWidget.setText @output` → `@textWidget._setTextConnector @output`
- `src/patch-programming/RegexSubstitutionPatchNodeWdgt.coffee:162`
  `@outputTextAreaText.setText @output` → `@outputTextAreaText._setTextConnector @output`
*Gate:* build.

### Step 5 — the `[P]` build-gate (restrict the join primitive to `_*Connector` callers)

*Why:* the join primitive relaxes the flow-violation throw; only opt-in connector entrypoints may use it.
*How (in `buildSystem/check-layering.js`), modelled on rule `[O]` (§1 fact 11):*
1. Near the other `const … = /…/` rule regexes (by `COALESCED_CALL`, ~:302), add:
```js
// [P] the connector-join caller rule (docs/connection-cascade-settle-fix-plan.md). _settleLayoutsAfterOrJoinEnclosingPass
// JOINS an enclosing settle's mutation window instead of throwing (it is the reactive-connection settle lane) -- sound
// ONLY for a dedicated _<name>Connector entrypoint (which carries the connectionsCalculationToken cycle-guard whenever
// its action can propagate onward; a sink connector like _setFontSizeConnector needs none). Any other caller must
// use the self-settling _settleLayoutsAfter (which surfaces the flow violation) or a _<name>NoSettle core.
const JOIN_CALL = /[@.]\s*_settleLayoutsAfterOrJoinEnclosingPass\b/;
```
2. In the per-method scan loop (by the `[O]` check, ~:521), add:
```js
    const join = code.match(JOIN_CALL);
    if (join && !/Connector$/.test(method)) {
      violations.push(`[P] ${method}() calls _settleLayoutsAfterOrJoinEnclosingPass() but is not a _<name>Connector entrypoint — the connector settle lane JOINS an open layout pass (it does NOT throw the flow-violation guard), sound only for a dedicated reactive-connection entrypoint carrying the connectionsCalculationToken cycle-guard. Use the self-settling _settleLayoutsAfter or a _<name>NoSettle core instead (connection-cascade-settle-fix-plan.md)  — ${at}`);
    }
```
   (Use the same `method`, `code`, `at` locals the surrounding `[O]` block uses. If a `[P]` letter is already taken,
   pick the next free letter and keep the message.)
3. If the gate prints a short legend of rules at the end (grep `console.error('O:`), add a matching one-liner for
   `[P]`.
*Scope note (REVIEW):* `[P]` keys on calls to the JOIN PRIMITIVE, not on calls to `_*Connector` methods — so
step 4's textual `_setTextConnector` calls from `recalculateOutput` do not touch this rule. An optional caller-side
fence for the connectors themselves is §7 side-quest (e).
*Verify the gate BOTH passes and bites:* after step 5, `./fg build` must still print `0 violations`. Then TEMPORARILY
add a `@_settleLayoutsAfterOrJoinEnclosingPass => 1` line to some non-`Connector` method, `./fg build`, confirm it
reports a `[P]` violation, then REVERT that line and rebuild clean.
*Gate:* build.

### Step 6 — flip the three doc rows from PLANNED to live (docs are part of the deliverable)

*(REVIEW addition.)* The three docs ALREADY carry the `[P]`/connector rows marked
*(PLANNED — `connection-cascade-settle-fix-plan.md`)* as UNCOMMITTED working-tree edits (verify:
`git -C Fizzygum status --short docs/`): `docs/lint-and-static-checks.md` (~:177),
`docs/layering-naming-convention.md` (§2.5 ~:113-123 + §4 ~:225), `docs/layout-system-architecture-assessment.md`
(§2.2 ~:175-187). After step 5 is green: remove the PLANNED markers AND update their prose to the amended shape —
they still describe `Widget._connectorVariantOr` (now `ControllerMixin._fireConnection`, step 3) and the symmetric
join (now: joins the MUTATION WINDOW only; the flush walk keeps the orphan-defer + throw, §2 box). Include them in
the commit.

---

## §4 — Sequencing

Steps 1, 2, 2b, 3, 4, 5, 6 in order, `./fg build` after each (each must print `0 violations` + `done!!!`). The fix
is not "live" until step 3 (routing) + step 4 (renders) are both in; steps 1-2-2b add unused code (harmless),
step 5 locks it down, step 6 is docs-only. If a build fails, the steps are independent enough to revert the last
one (`cd Fizzygum && git diff` to see; `git checkout -- <file>` reverts a whole file) and report.

---

## §5 — Verification

### 5a — headless repro (the acceptance test)

The converter apps are NOT covered by any SystemTest (that is why the bug shipped), so verify with a headless probe.
Write `/tmp/probe-converter.js` (adapt the path; it `require`s the tests repo's puppeteer):
```js
'use strict';
const path = require('path');
const puppeteer = require('/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/node_modules/puppeteer');
const fileUrl = 'file://' + path.resolve('/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-builds/latest/index.html');
function waitReady(ms){return new Promise((res)=>{const t0=Date.now();const tick=()=>{const w=window.world;const ready=!!(w&&w.worldRenderCanvas&&w.worldCanvas&&w.worldCanvasContext);const settled=ready&&(typeof w.anyTextDirty!=='function'||w.anyTextDirty()===false);if((ready&&settled)||(Date.now()-t0)>ms)res(ready);else setTimeout(tick,100);};tick();});}
function probe(){
  const L=[];
  const wm = new window.DegreesConverterApp().buildWindow();
  if (world.recalculateLayouts) world.recalculateLayouts();
  const all=[]; (function rec(w){ if(!w) return; all.push(w); (w.children||[]).forEach(rec); })(wm);
  const s = all.filter(w => w.constructor && w.constructor.name === 'SliderWdgt')[0];
  const texts = all.filter(w => w.constructor && w.constructor.name === 'TextWdgt');
  try {
    s.setValue(30, null, null);                      // == dragging slider1's handle to 30 °C
    if (world.recalculateLayouts) world.recalculateLayouts();
    L.push('NO THROW — conversion propagated');
    L.push('  text boxes now: ' + texts.map(t=>JSON.stringify(t.text)).join(', '));  // expect a "30" and an "86"
  } catch(e){ L.push('THROW: ' + e.message); }
  return L.join('\n');
}
(async () => {
  const b = await puppeteer.launch({ headless:'new', args:['--allow-file-access-from-files','--no-sandbox'] });
  try { const p = await b.newPage(); await p.setViewport({width:1200,height:900,deviceScaleFactor:1});
    await p.goto(fileUrl,{waitUntil:'load',timeout:30000}); await p.evaluate(waitReady,15000);
    console.log(await p.evaluate(probe)); await p.close(); } finally { await b.close(); }
})().catch(e=>{console.error(e);process.exit(1);});
```
Run `node /tmp/probe-converter.js` after a build. **PASS = "NO THROW — conversion propagated"** and the text boxes
read `"30"` (°C) and `"86"` (°F, = round(30·9/5+32)). BEFORE the fix this same probe prints `THROW: … a public
geometry setter was reached during a layout flush/pass …`. (If a torture/suite is running concurrently, the `./fg
suite` runner's `kill_browsers` will kill this puppeteer — run the probe when no suite is running.)
*(REVIEW 2026-07-03: this probe was re-run verbatim against the build @ `8a3367a8` — it prints the THROW exactly
as quoted; the repro stands.)*
**Step 2b acceptance (one extra headless check):** in the same probe, BEFORE `s.setValue(30, …)`, re-wire
`texts[0].setTargetAndActionWithOnesPickedFromMenu(null, null, texts[1], "setFontSize")` (this re-targets cText's
single wire — fine for a probe) and move the slider: PASS = still no throw AND `texts[1]`'s font size becomes 30 —
i.e. a mid-cascade "font size" hop JOINS instead of throwing.

### 5b — the full battery (this touches the settle machinery + a base primitive → run everything)

From the umbrella root, in order:
1. `./fg gauntlet` — build + full suite at dpr1 + dpr2 + webkit + apps smoke + audit gates. PASS = the final banner
   `GAUNTLET OK — dpr1:PASS dpr2:PASS webkit:PASS apps:PASS tiernaming:PASS settle:PASS` (each suite leg 165/165,
   `failed tests: 0`). ETA ≈10–15 min.
2. The four-config danger torture (settle-machinery change → required), one at a time:
   ```sh
   ./fg suite --dpr=2 --shards=8
   ./fg suite --dpr=2 --shards=8 --speed=fast
   ./fg suite --shards=8
   ./fg suite --dpr=2 --shards=4
   ```
   PASS per run = the `SUITE OK` banner, `failed tests: 0`, **and the string `RECALC_NONCONVERGENCE` appears nowhere**.
   (dpr2 runs are several minutes each.) A run that STALLS (`completed:false` / shards not all N/N) is a FAILURE even
   with 0 failed screenshots — treat it as a real breakage; if it recurs, `pkill -9 -f "Chrome for Testing|chrome-headless|puppeteer|webkit"`
   and re-run once to rule out a browser-boot flake (a single shard failing to load with `ReferenceError: CoffeeScript
   is not defined` is a known transient, not a code fault).
3. **Expected recaptures: NONE.** No SystemTest exercises these apps; the suite must stay byte-identical. If a
   gauntlet leg's ONLY failure is an inspector member-list test, that is the standard benign shift: `./fg recapture
   <failingTestName>` then re-run the leg, and note the `Fizzygum-tests` recapture in the review.

---

## §6 — Commit

One commit in `Fizzygum` (no `Fizzygum-tests` change expected). Suggested subject:
`fix(layout): reactive connection cascades settle once (connector lane) — C↔F converter no longer throws`.
Body: summarize §1 (the mechanism) + §2 (the connector lane) + the touch-list + the verification. Touch-list:
`Widget.coffee` (join primitive), `StringWdgt.coffee` (`_setTextConnector`, `_setFontSizeNoSettle`+Connector),
`ControllerMixin.coffee` (`_fireConnection`), the 8 dispatch-site files, `buildSystem/check-layering.js` (`[P]`),
the three step-6 docs, and this plan. Follow §0.5's commit protocol (present the diff + message, WAIT for
approval, `git commit -F`).

---

## §7 — Cleansing side-quests (REVIEW 2026-07-03; related, separable — each its own pass, NOT bundled here)

Recorded so the cleanliness debt around this machinery is visible; ordered by value.

- **(a) FOLDED INTO STEP 3** — the one-dispatch-helper consolidation (`ControllerMixin._fireConnection`) replaced
  8 copies of the guarded `@target[@action].call …` incantation.
- **(b) Extract the token-guard one-liner (34 copies → 1 helper).** Fact 14. Shape: a Widget-level
  `_acceptsConnectionToken: (token, superCall, tokenField = "connectionsCalculationToken") ->` returning
  false-to-reject (and minting/adopting the token otherwise); callers become
  `return unless @_acceptsConnectionToken connectionsCalculationToken, superCall` (per-input variants pass
  `"input1connectionsCalculationToken"` …). Behaviour-identical mechanical sweep across ~17 files; expect a
  byte-identical suite. High readability payoff — the current line is the least readable idiom in the dataflow code.
- **(c) Consolidate `openTargetPropertySelector` (8 near-identical copies).** `StringWdgt:1318`,
  `SimplePlainTextWdgt:63`, `SliderWdgt:288`, `PaletteWdgt:113`, `FanoutPinWdgt` (allSetters), `Calculating:81`,
  `Diffing:78`, `Regex:84` — the SAME menu-builder body differing ONLY in which setter table is consulted. Shape:
  ONE ControllerMixin builder taking the table (or a per-class `connectionSetterTableFor: (theTarget) ->` hook);
  `PaletteWdgt.addBangSetter` is the in-file precedent for exactly this de-triplication. Menu output byte-identical.
- **(d) Delete `SimplePlainTextWdgt.setText`'s trailing `@updateTarget()`** (`:168`) — a duplicate fire with the
  SAME token, always absorbed by the receiver's token guard (fact 12); `_setTextNoSettle` already fired it. One
  line + a breadcrumb; verify with the suite (expect byte-identical).
- **(e) Optional `[P]` caller-side clause** — mirror `[O]`'s caller allowlist for TEXTUAL calls of `_*Connector`
  methods (allowlist `recalculateOutput`; `_fireConnection`'s dispatch is dynamic and invisible to the name-scanner
  regardless). Keeps someone from hand-calling `_setTextConnector` as "a setText that never throws". Cheap; add
  when/if a second textual caller class appears.
- **(f) Docs de-PLAN** — folded into step 6.

---

## Appendix — rejected alternatives (do not re-propose without new evidence)

- **Make the public `setText` ride the enclosing settle when mid-pass** (a one-method fix). Rejected by the owner:
  it would relax the flow-violation guard for the general `setText`, hiding genuine internal-layout misuse. The
  connector lane keeps `setText`'s throw intact and opts IN per-entrypoint instead.
- **Dispatch the cascade to the raw `_setTextNoSettle` core** ("add `_` prefix + `NoSettle` suffix"). Rejected on
  evidence: the core has NO `connectionsCalculationToken` parameter and does no cycle-guard (§1 fact 4) → the circuit
  would never break → infinite loop; and it never opens a settle, so the FIRST hop (§1 fact 5,
  `world._inLayoutMutation=false`) would leave the cascade unsettled. `_setTextConnector` = the core + the token-guard
  + settle-OR-join, which is exactly why it is a distinct thin entrypoint.
- **Fix only the calc's own render (`recalculateOutput` → core), no connector.** Rejected on evidence: a throwaway
  probe showed the throw simply MOVES one hop to `fText.setText` via `fireOutputToTarget`'s dynamic dispatch (§1
  fact 6) — the wired hops still self-settle. (And at review the render edit itself moved OFF the bare core onto
  `_setTextConnector` — fact 9's correction: a cascade does not always carry an open settle, and the bare core
  would also skip today's fresh-token mint. The throwaway-probe evidence above is unaffected.)
- **Store the connector name in the menu (`stringSetters` maps "text" → "_setTextConnector")** instead of the
  dispatch transform. Workable (there is no `setTextIsConnected` flag to break), but the dispatch transform (§3
  step 3) is preferred: it keeps `@action` = the friendly public name, needs no change to the menu tables or the
  app's hard-wired connections, and auto-covers every current and future reactive dispatch site uniformly.
- *(REVIEW)* **Token-keyed lane switch inside the public `setText`** (`if connectionsCalculationToken? then join
  else strict` — only cascade dispatch ever passes a token, so plain API callers would keep the throw). Smaller
  (no step 3, no connector methods) but DECLINED: it hides the lane in a data condition instead of a greppable
  entrypoint name, forces rule `[P]` to allowlist `setText` itself (weakening "only `_*Connector` may join" to an
  exception list), and contradicts the owner's one-mechanism-per-use-case lane table (§2).
- *(REVIEW)* **Deferred/queued propagation** (`updateTarget` enqueues the hop; the queue drains after the settle /
  at end-of-cycle). DECLINED: it changes the circuits' SYNCHRONOUS semantics (today a caller observes all wired
  values updated on return) for zero benefit over the join lane, and adds a scheduling surface to the determinism
  contract for nothing.
- *(REVIEW)* **Symmetric join (the original step-1 sketch: also join during `world._recalculatingLayouts`).**
  Superseded by the narrowed variant (§2 box / step 1): a cascade only ever runs in the settle's MUTATION WINDOW —
  the flush starts after the outermost connector returns — so joining the flush walk would only ever license
  layout-code-initiated firings (e.g. a wired `_reLayout`-re-titled tick label), which are genuine flow violations
  today and must keep throwing.
