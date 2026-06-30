# Plan — fold the caret's scroll-follow into an IN-PLACE (per-event) settle, before the end-of-cycle flush

**Status: PLAN ONLY (not started). Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Everything needed — what the project is, the cycle architecture, the just-completed prior arc, the exact current
state of the caret code, the one central constraint, the decisive first step, the verification protocol, and all
references — is embedded inline or one named-doc hop away. **Line numbers drift: grep the named symbol, never trust a
line number in this doc.**

**One-line goal.** Today the caret's scroll-into-view ("scroll-follow") settles in *two different places* depending on
how the caret moved: a **click / arrow / Home-End / undo-restore** move settles it **IN-PLACE during the event**
(good); **typing and delete** defer it to a *later* flush (the keystroke's `reactToKeystroke` re-fit, or the
end-of-cycle `recalculateLayouts` flush). **Make typing/delete settle the follow in-place too — during the keystroke
event, after the final re-fit — so the caret's follow is uniformly a per-event ("step by step") settle and never rides
the end-of-cycle coalesced flush.** The caret does **not** coalesce, so it philosophically belongs in the per-event
settle, not the coalesced flush.

**This is a PURITY refinement, not a correctness fix.** The current behaviour is correct and byte-exact. The win is
architectural consistency: the end-of-cycle flush becomes purely for genuinely-coalesced streams (drag/scroll), and the
caret follow is uniformly "fixed step by step" per the owner's cycle invariant (below). Treat the bar accordingly:
if it can't be made byte-exact + determinism-clean with reasonable effort, **leave it** — the status quo is fine.

---

## §0 — Orientation + why this now

**Fizzygum** is a CoffeeScript GUI framework — a "web operating system" (windows, desktop, drag-and-drop, live
in-system editing) rendered on a single HTML5 `<canvas>`, descended from Morphic.js. ~470 `.coffee` classes in
`Fizzygum/src/`; every class is a global compiled in-browser (no `require`/`import`); `nil` == `undefined`; one class
per file, filename == class name. The umbrella `/Users/davidedellacasa/code/Fizzygum-all/` is NOT a git repo; it holds
three sibling git repos that must stay siblings:
- **`Fizzygum/`** — framework source (edit here) + the build script.
- **`Fizzygum-tests/`** — 165 macro SystemTests (drive the live world, compare SWCanvas SHA-256 screenshots
  **byte-exactly**) + the test harness.
- **`Fizzygum-builds/`** — generated build output (never hand-edit).

Commands run via the path-correct `fg` wrapper **from the umbrella root** `/Users/davidedellacasa/code/Fizzygum-all/`:
`./fg build` · `./fg suite` (165 tests, dpr1, ~1.3 min) · `./fg gauntlet` (build + dpr1 + dpr2 + WebKit + 12 apps) ·
`./fg test <name>` · `./fg recapture <name>`. (The `fg` wrapper is local workspace tooling, not committed.)

**Why this now — the immediately-prior arc (just landed, commit `d60a0710` in Fizzygum / `f228f343b` in Fizzygum-tests).**
The "Option C" arc folded the caret's scroll-follow **into the end-of-cycle flush**: a caret move enqueues the caret,
and the caret's `_reLayout` runs the follow, converging through the flush's until-loop. Before that, the follow ran as a
dedicated post-flush step in `WorldWdgt.doOneCycle` (a hand-iterated convergence loop) — a *third* settling mechanism.
Option C deleted that step + loop, so `doOneCycle` is now purely **process events → fix coalesced layouts → paint**,
with no caret special-case. (Full record: memory `fizzygum-paint-readonly-caret-resync`, and the body of this plan.)

While reviewing Option C, the owner asked: *"can we further fold the scroll settle into an in-place settle, i.e. before
the end-of-cycle flush?"* The answer is **yes, plausibly, and it's already half-true** — which is what this plan is for.

---

## §1 — The architecture: the cycle and the TWO settle mechanisms

**`WorldWdgt.doOneCycle`** (`src/WorldWdgt.coffee`, grep `doOneCycle:`) runs once per frame:
1. `@playQueuedEvents()` — **PROCESS EVENTS.** Each queued input event's handler runs. A public geometry/structural
   mutator reached here **self-settles in-place** via `Widget._settleLayoutsAfter` (see §2): it runs a non-settling
   core, then immediately calls `recalculateLayouts()` once — so its layout is fixed *during the event*, "step by step."
2. step functions; hand mouse-enter/leave re-check.
3. `window.recalculatingLayouts = true`; **`@recalculateLayouts()`**; `window.recalculatingLayouts = false`. — **THE
   END-OF-CYCLE FLUSH.** Drains `world.widgetsThatMaybeChangedLayout` (the COALESCED queue — anything deferred during
   the cycle, e.g. ~50/frame drag/scroll streams that declared coalescing).
4. `addPinoutingWidgets`, `addHighlightingWidgets`.
5. **`@updateBroken()`** — **PAINT** (read-only; `@healingRectanglesPhase = true` around it). *(The caret's paint-time
   re-sync was made read-only in an earlier arc — see memory `fizzygum-paint-readonly-caret-resync`; do NOT reintroduce
   layout mutation at paint.)*
6. `WorldWdgt.frameCount++`.

**The owner's CYCLE INVARIANT (verbatim):** *"Doonecycle should process events, fixing layouts step by step except
coalesced, then fix coalesced layouts, then paint."* So there are exactly two settle mechanisms:
- **IN-PLACE per-event settle** = `_settleLayoutsAfter` during step 1 ("fixing layouts step by step"). For discrete,
  non-coalesced changes.
- **END-OF-CYCLE flush** = `recalculateLayouts` at step 3 ("fix coalesced layouts"). For coalesced/deferred changes.

**The caret does NOT coalesce.** Per-keystroke caret navigation is not a ~50/frame stream; each discrete move should
settle per-event. (Owner principle, reaffirmed across arcs: a prior attempt to declare-coalesce the caret was wrong and
corrected. Do NOT reach for coalescing here.) **Therefore the caret follow philosophically belongs in the IN-PLACE
settle, not the end-of-cycle flush.** This plan completes that.

**`recalculateLayouts` / `_recalculateLayoutsBody`** (grep both in `WorldWdgt.coffee`): the FLUSH primitive, used by
BOTH mechanisms (the in-place `_settleLayoutsAfter` calls it once; the end-of-cycle step calls it once). It drains
`widgetsThatMaybeChangedLayout` in an `until @widgetsThatMaybeChangedLayout.length == 0` loop, climbing each broken
widget to its top-most invalid ancestor (stopping the climb at a free-floating widget), calling `_reLayout()` (which
must end in `markLayoutAsFixed()` so the widget is popped). Backstop: `recalcIterationsCap = 100000` → logs
`RECALC_NONCONVERGENCE` and bails instead of hanging. `world._recalculatingLayouts` is true only inside this body.

---

## §2 — `_settleLayoutsAfter`: the in-place settle (the key mechanism)

`Widget._settleLayoutsAfter` (`src/basic-widgets/Widget.coffee`, grep `_settleLayoutsAfter:`) is the in-place per-event
settle. Current body (paraphrased; grep for the real one):

```coffee
_settleLayoutsAfter: (coreThunk) ->
  unless world? then return coreThunk()                 # early bootstrap
  if @isOrphan() then return coreThunk()                # off-world widget defers, settles when attached
  if world._inLayoutMutation or world._recalculatingLayouts
    throw "...public geometry setter during a layout flush/pass — use raw/silent setters..."   # flow-rule
  if world._batchingLayoutSettling then return coreThunk()
  world._inLayoutMutation = true
  try
    result = coreThunk()
    world.recalculateLayouts()        # <-- THE in-place flush: drains the queue NOW, during the event
    return result
  finally
    world._inLayoutMutation = false
```

**The crucial consequence (this is the whole basis of the plan):** if a core thunk *enqueues* a widget into
`widgetsThatMaybeChangedLayout`, the very next line (`recalculateLayouts()`) drains it — **in-place, during the event.**
So a caret move that (a) is wrapped in `_settleLayoutsAfter` and (b) enqueues the caret in its core gets its follow
converged in-place, before control returns to the event loop and long before the end-of-cycle flush.

---

## §3 — Current state of the caret follow (what Option C left)

All in `src/basic-widgets/CaretWdgt.coffee` (the caret is `isLayoutInert: -> true` and free-floating). Grep each name.

**The public moves are wrapped in `_settleLayoutsAfter`:**
```coffee
gotoSlot: (slot, becauseOfMouseClick) -> @_settleLayoutsAfter => @_gotoSlotNoSettle slot, becauseOfMouseClick
goLeft:   (shift)          -> @_settleLayoutsAfter => @_goLeftNoSettle shift
goRight:  (shift, howMany) -> @_settleLayoutsAfter => @_goRightNoSettle shift, howMany
# goUp/goDown/goHome/goEnd have NO internal callers, so they self-settle inline via gotoSlot.
```

**The core enqueues the caret + does one best-effort inline pass:**
```coffee
_gotoSlotNoSettle: (slot, becauseOfMouseClick) ->
  length = @target.text.length
  @slot = (clamp slot to [0, length])
  @_oneScrollCaretIntoViewPassNoSettle()   # ONE inline pass DURING the event — load-bearing for byte-exact typing (§4)
  @_requestScrollFollow()                  # enqueue the caret for the converging follow
  if becauseOfMouseClick and @target.undoHistory?.length == 0 then @target.pushUndoState? @slot, true

_requestScrollFollow: ->                   # the caret SELF-SCHEDULES (direct push; it is inert+free-floating, no climb)
  if @layoutIsValid then world.widgetsThatMaybeChangedLayout.push @
  @layoutIsValid = false

_reLayout: ->                              # the caret's layout step IS the scroll-follow (one pass; converge via until-loop)
  beforeT = @top() ; beforeL = @left() ; beforeParentT = @parent?.top() ; beforeParentL = @parent?.left()
  @_oneScrollCaretIntoViewPassNoSettle()
  stable = (caret + parent didn't move on the last pass)
  if stable then @markLayoutAsFixed()
  # else: stay layoutIsValid==false → until-loop re-runs us after the just-enqueued panel settles
```
`_oneScrollCaretIntoViewPassNoSettle` (grep it) does ONE follow pass: re-derives the caret pixel from
`@target.slotCoordinates @slot` (now PURE — see prior arc), scrolls `@target` horizontally and/or asks the enclosing
`ScrollPanelWdgt.scrollCaretIntoView` (grep it) to scroll vertically. `scrollCaretIntoView` is **CONVERGENT**: its
trailing `keepContentsInScrollPanelWdgt` clamp advances `@contents` only PARTWAY per call, so the follow reaches its
mark over a *few* passes — which is why a single pass isn't enough and convergence (the until-loop) is needed.

**Where the follow ACTUALLY settles today (the key observation):**
- **Click / arrow / Home-End / undo-restore** → go through `gotoSlot`/`goLeft`/`goRight` → `_settleLayoutsAfter`. The
  core enqueues the caret; `_settleLayoutsAfter`'s immediate `recalculateLayouts()` drains it. **⇒ follow converges
  IN-PLACE during the event. The end-of-cycle flush never sees these.** ✅ already in-place.
- **Typing and delete** → `insert` / `deleteLeft` / `deleteRight` call the **NoSettle** advance
  (`_goRightNoSettle` / `_goLeftNoSettle`), NOT the wrapped public `goRight`/`goLeft`. That advance is **deliberately
  off-settle** (see §4). So `_gotoSlotNoSettle`'s `_requestScrollFollow` enqueues the caret with NO immediately-following
  flush. The enqueued caret is therefore drained by *whatever flush comes next*: possibly the keystroke's
  `reactToKeystroke` re-fit (if that self-settles), otherwise the end-of-cycle flush. **⇒ NOT cleanly in-place; this is
  the gap this plan closes.**

The typing flow (grep `insert:` and `processKeyDown:` in `CaretWdgt.coffee`):
```coffee
insert: (key, shiftKey) ->
  ... @target.pushUndoState? @slot ; (delete selection if any) ...
  text = (text with key inserted at @slot)
  @target.setText text, nil, nil                          # SELF-SETTLES (flush A: re-fits the string)
  return if @target.handOffToPopoutEditorIfOverflowing()  # overflow → pop-out editor (prior arc)
  @_goRightNoSettle false, key.length                     # OFF-SETTLE advance (enqueues caret, no flush here)
  @updateDimension()
  @target.pushUndoState? @slot

processKeyDown: (key, ...) ->
  ... dispatch: insert / goLeft / goRight / deleteLeft / deleteRight / goUp ... ...
  @target.escalateEvent "reactToKeystroke", key, code, shiftKey, ctrlKey, altKey, metaKey   # FINAL re-fit (may self-settle)
  @updateDimension()
```

---

## §4 — The ONE central constraint: typing byte-exactness (do not break this)

The single regression the Option-C arc had to chase (and the paint-time arc before it) was **byte-exact in-place
typing**, tripwire test **`SystemTest_macroStringWdgtInlineTypingRefitsUnderFittingModes`**. It depends on the advance
scroll happening **synchronously, BEFORE** the keystroke's `escalateEvent "reactToKeystroke"` re-fit — which is exactly
why the typing advance uses the **NoSettle** core (`_goRightNoSettle`) and the inline pass
(`_oneScrollCaretIntoViewPassNoSettle` inside `_gotoSlotNoSettle`) runs during the event, *before* `reactToKeystroke`.
The comment in `goLeft/goRight` (grep it) records: *"self-settling it early reorders the fit … it broke
macroStringWdgtInlineTypingRefitsUnderFittingModes."*

So the **scroll itself** must precede `reactToKeystroke`, but the **convergence of the scroll-panel follow** needs the
**final** geometry — which only exists *after* `reactToKeystroke`. These two facts are the entire design tension:
- inline pass (pre-`reactToKeystroke`) = the byte-exact advance scroll.
- the converging follow (post-`reactToKeystroke`) = bring the caret fully into view on settled geometry.

**Any in-place fix must keep the inline pass where it is (pre-`reactToKeystroke`) and run the *converging* follow AFTER
`reactToKeystroke`.** Breaking this order brings back the one-char shift in the tripwire test.

---

## §5 — The DECISIVE first step (≈15 min): determine where typing's caret actually drains TODAY

Do NOT write the fix first. The whole shape depends on one empirical fact: **does the typing-path caret get drained by
`reactToKeystroke`'s self-settle (already in-place, just implicit/incidental), or does it fall through to the end-of-cycle
flush?** This single fact scopes the work:
- If `reactToKeystroke` already drains it → typing's follow is *already* in-place but **incidental and inconsistent**
  (depends on whether the specific target's `reactToKeystroke` self-settles). The fix is to make it **explicit and
  guaranteed** (a small, low-risk change).
- If it falls through to the end-of-cycle flush → typing's follow is genuinely on the coalesced flush, and the fix is a
  real relocation.

**How to trace (the reliable technique — Puppeteer drops early-frame `console.log` under flood):** route trace messages
through `SystemTestsControlPanelUpdater?.addMessageToSystemTestsConsole "..."` — the headless runner reads that DOM div
synchronously at test end (last ~15 lines). Instrument three spots and run a single typing test:
1. In `CaretWdgt._requestScrollFollow`, log `"caret ENQUEUE _inLayoutMutation=" + world._inLayoutMutation + " _recalc=" + world._recalculatingLayouts`.
2. In `CaretWdgt._reLayout` (top), log `"caret FOLLOW runs; _recalc=" + world._recalculatingLayouts + " inMut=" + world._inLayoutMutation`.
3. In `WorldWdgt.doOneCycle`, just before step 3's `recalculateLayouts()`, log `"END-OF-CYCLE FLUSH begins; queue=" + @widgetsThatMaybeChangedLayout.length`.

Run: `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/run-macro-test-headless.js
SystemTest_macroStringWdgtInlineTypingRefitsUnderFittingModes --dpr=1` and read the captured console. The ordering of
"caret FOLLOW runs" relative to "END-OF-CYCLE FLUSH begins" tells you which case you're in. **Revert the instrumentation
before building anything real.**

*(Note for the cold reader: `_settleLayoutsAfter` sets `world._inLayoutMutation=true` during a per-event settle and
`recalculateLayouts` sets `world._recalculatingLayouts=true` during ANY flush. So "FOLLOW runs with `_inLayoutMutation`
true and before the END-OF-CYCLE log" ⇒ in-place; "FOLLOW runs after the END-OF-CYCLE log" ⇒ end-of-cycle.)*

---

## §6 — The fix shape (after §5 tells you the case)

**Target design:** after a keystroke is *fully* processed (i.e. after `processKeyDown`'s `reactToKeystroke` +
`updateDimension`, when the target geometry is final), drain the enqueued caret with ONE in-place flush — so typing's
follow converges in-place, during the event, exactly like click/arrow already do.

The natural hook is the **tail of `processKeyDown`** (it is the per-keystroke event handler; `reactToKeystroke` is its
last geometry-affecting step). Sketch (grep for the real method; keep the inline pass + the NoSettle advance untouched —
§4):

```coffee
processKeyDown: (key, ...) ->
  ... existing dispatch ...
  @target.escalateEvent "reactToKeystroke", ...     # final re-fit (unchanged)
  @updateDimension()
  # NEW: converge the caret's scroll-follow IN-PLACE now, on the final geometry, instead of leaving the enqueued
  # caret to a later/ the end-of-cycle flush. Only flush if a move actually enqueued the caret this keystroke.
  @_settleFollowInPlaceIfPending()
```
where `_settleFollowInPlaceIfPending` runs an in-place flush **only if the caret is enqueued** (`@layoutIsValid` is
false / caret is in `world.widgetsThatMaybeChangedLayout`) and **only if not already inside a flush**
(`world._recalculatingLayouts` / `world._inLayoutMutation` false — guard against re-entrancy / the flow-rule throw).
Reuse the existing `recalculateLayouts()` for convergence (do NOT hand-roll a loop — Option C deliberately removed the
hand-rolled loop; the until-loop is the convergence machinery).

**Subtleties to handle:**
- **Re-entrancy / flow-rule.** `recalculateLayouts` throws if called while `_recalculatingLayouts` is already true. If
  `reactToKeystroke` self-settles (case "already drains"), the caret may already be drained by the time you reach the
  tail — so the in-place flush must no-op when the queue has no caret (cheap: check `@layoutIsValid`). Mirror
  `_settleLayoutsAfter`'s guards (`world?`, `isOrphan`, `_inLayoutMutation`, `_recalculatingLayouts`, `_batchingLayoutSettling`).
- **Don't double-settle.** If `reactToKeystroke` already drained the caret in-place, the tail flush should be a no-op,
  not a second redundant follow.
- **delete paths.** `deleteLeft`/`deleteRight` also use the NoSettle advance and go through `processKeyDown` → the same
  tail hook covers them. Verify (the `processCut` → `deleteLeft` path too).
- **Non-`processKeyDown` callers.** Check there is no caret text-growth/move path that bypasses `processKeyDown` and
  relies on the end-of-cycle flush for its follow (grep callers of `_goRightNoSettle`/`_goLeftNoSettle`/`_gotoSlotNoSettle`).
  If one exists, it needs the same in-place drain at its own event boundary.

**If §5 says "already drains via reactToKeystroke":** the change is even smaller — possibly just *guaranteeing* a tail
flush so the drain is consistent (not dependent on whether a given target's `reactToKeystroke` happens to self-settle),
plus a comment documenting that the caret follow is uniformly in-place. Confirm there is no case where the caret stays
enqueued past `processKeyDown` (which would still ride the end-of-cycle flush).

**What you should be able to assert at the end:** `world.widgetsThatMaybeChangedLayout` never contains the caret at the
start of `doOneCycle` step 3 (the end-of-cycle flush) — i.e. the caret follow is *always* settled in-place by the time
the coalesced flush runs. A temporary assertion/log at the top of step 3 (`@caret? and not @caret.layoutIsValid` ⇒ warn)
is a good acceptance probe (remove before commit).

---

## §7 — Verification protocol (MANDATORY — determinism-sensitive; the caret/typing/scroll path is the most byte-exact-fragile code in the system)

Run the FULL set for any change. `fg` runs from any cwd but lives at the umbrella root.
1. `./fg build` — 0 violations (lints A–G + dead-method + thin-wrap + CoffeeScript syntax gates).
2. `./fg suite` — dpr1 **165/165**. On a pixel failure, dump + LOOK (don't recapture blindly):
   `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/run-macro-test-headless.js
   SystemTest_<name> --dpr=1 --dump-failures=.scratch/x`, then Read the dumped `.png` vs the committed reference under
   `tests/SystemTest_<name>/automation-assets/**/SWCanvas/ceilPixRatio_1/`.
3. `./fg gauntlet` — dpr1 / dpr2 / WebKit **165/165** + **apps 12/12**.
4. **dpr2 torture — THE GOLD GATE** (timing/cadence bugs only show under parallel load):
   `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/torture-headless.js --dprs=2
   --speeds=fastest --shards=4 --minutes=10 --out=.scratch/torture-caret-inplace` → `REPORT.md` must say
   "No nondeterminism observed", failures dir empty, **and grep the run for `RECALC_NONCONVERGENCE` (must be absent)**.
   GOTCHA: `pkill -9 -f "Chrome for Testing"` before torture (zombie browsers crash-loop the run); rebuild first (the
   stale-build canary refuses an old build).
5. **End-of-cycle capstone gate stays 0:** `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && bash
   scripts/end-of-cycle-audit/run-capstone-gate.sh ; echo "EXIT $?"`. **DO NOT pipe this to `tail`/`grep` — the pipe
   masks the script's real exit code** (learned the hard way: a pipe-to-`tail` reported exit 0 on a FAILED gate). It
   must print "✓ CAPSTONE GATE PASSED — zero careless end-of-cycle pushes". *(An in-place fix should keep this at 0 — the
   caret already self-schedules with the low-level direct-push primitive, which is not audited; see §8.)*
6. **Paint-read-only gate stays 0:** `bash scripts/paint-readonly-audit/run-paint-readonly-gate.sh ; echo "EXIT $?"`
   (same no-pipe caveat). Must print "✓ PAINT-READ-ONLY GATE PASSED".

**Determinism contract:** render/layout/input must be a pure function of the EVENT STREAM + final geometry — never
wall-clock / frame-count / intermediate-pass. A green dpr1 suite is NOT sufficient; finish with gauntlet + torture.
Full contract + bug-class case law: `Fizzygum-tests/DETERMINISM.md`.

**Recapture note:** an in-place fix that is byte-exact needs NO recapture. If it shifts pixels *deliberately*, that is a
behaviour change requiring owner approval before `./fg recapture <name>`. A benign inspector member-list shift (from
adding/renaming an inspected method) is the one pre-authorized recapture class — but this plan adds no inspected method
on a content widget, so none is expected.

---

## §8 — Owner principles + workflow (honour these)

- **No new settle tier.** The whole point is to use the EXISTING in-place settle (`_settleLayoutsAfter` /
  `recalculateLayouts`), not invent a third mechanism. The owner has rejected extra `_settleLayoutsAfter` variants and
  `try/finally` flag toggles in prior arcs. Reuse the until-loop for convergence; do NOT hand-roll a loop (Option C
  removed one).
- **The caret does NOT coalesce.** Do not declare-coalesce it (`setMaxDimCoalesced` is for ~50/frame streams only).
- **The caret self-schedules with the LOW-LEVEL primitive, not `_invalidateLayout`.** `_requestScrollFollow` does
  `push @ + @layoutIsValid=false` directly — because the caret is inert + free-floating (no parent layout to
  climb-and-invalidate, which is `_invalidateLayout`'s whole job), and a deliberate overlay self-schedule is NOT the
  careless-content-mutator class that `_invalidateLayout`'s flow-rule throw + the capstone audit target. (Using
  `_invalidateLayout` was a trap an earlier probe fell into: in-pass it threw the flow-rule, off-pass it registered as
  hundreds of "careless end-of-cycle pushes".) Keep using the direct primitive.
- **Clean/elegant code is the standing priority** over avoiding a benign inspector member-list recapture (just
  recapture; never contort code to dodge it). But this fix shouldn't trigger one.
- **Review-driven; run straight through then present ONE end-of-arc review.** Present the §5 trace evidence + the fix +
  full §7 verification in a single review. **ASK before each commit AND push** — present the diff + proposed message,
  wait for explicit approval. Use `git commit -F <file>` — NEVER backticks / `$()` in `git commit -m` (the Bash tool
  runs bash semantics and command-substitutes them, silently corrupting the message). Verify a multi-paragraph message
  with `git log -1 --format=%B`. End every commit message with:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Push each repo from its OWN dir.
- **Shell gotchas:** the Bash tool runs FISH; cwd may reset (use `cd /abs/... && …` single-line; `$status` not `$?`).
  A PreToolUse guard BLOCKS a command that `cd`s into a non-`Fizzygum-tests` dir then runs a `Fizzygum-tests/scripts`
  node script (→ MODULE_NOT_FOUND) — run such single-lines *from* `Fizzygum-tests`, or via `fg`. Kill orphan
  `Chrome for Testing` before any suite/torture/audit. NEVER pipe a build/gate whose exit code you need into
  `tail`/`grep` (it masks the exit code).

---

## §9 — Anchors & references (grep the symbol; numbers drift)

- **The caret (what you're changing):** `src/basic-widgets/CaretWdgt.coffee` — `processKeyDown` (the keystroke handler;
  ends with `escalateEvent "reactToKeystroke"` + `updateDimension` — the in-place hook goes after these), `insert` /
  `deleteLeft` / `deleteRight` / `processCut` (the typing/delete paths, which use the NoSettle advance), `gotoSlot` /
  `goLeft` / `goRight` (the wrapped public moves — already in-place via `_settleLayoutsAfter`), `_gotoSlotNoSettle`,
  `_goLeftNoSettle` / `_goRightNoSettle` (off-settle internal advance — keep off-settle, §4), `_requestScrollFollow`
  (direct self-schedule), `_reLayout` (the follow), `_oneScrollCaretIntoViewPassNoSettle` (one follow pass; keep the
  inline call in `_gotoSlotNoSettle` pre-`reactToKeystroke`, §4), `isLayoutInert`.
- **The settle machinery:** `src/basic-widgets/Widget.coffee` — `_settleLayoutsAfter` (the in-place settle; copy its
  guard set for any new in-place flush), `markLayoutAsFixed` / `layoutIsValid` / `isFreeFloating`,
  `_invalidateLayout` (do NOT use it for the caret — §8). `src/WorldWdgt.coffee` — `doOneCycle` (the cycle; step 3 is
  the end-of-cycle flush), `recalculateLayouts` / `_recalculateLayoutsBody` (the flush + until-loop + climb +
  `recalcIterationsCap`), `widgetsThatMaybeChangedLayout`, `_recalculatingLayouts`, `_inLayoutMutation`,
  `_batchingLayoutSettling`, `healingRectanglesPhase`.
- **The follow worker:** `src/basic-widgets/ScrollPanelWdgt.coffee` — `scrollCaretIntoView`,
  `keepContentsInScrollPanelWdgt` (the partway clamp → why convergence needs several passes).
- **The byte-exact tripwire:** `SystemTest_macroStringWdgtInlineTypingRefitsUnderFittingModes` (typing under fitting
  modes). Heavy typing/scroll stressors to watch: `macroWrappingTextFieldResizesOK`,
  `macroTextWdgtNoJumpsInLayoutOfLongLine`, `macroSoftWrapping`, `macroTextWdgtCutCopyPasteBasic`.
- **Prior-arc records (read for context):** memory `fizzygum-paint-readonly-caret-resync` (the Option-C arc that landed
  the flush-based follow — this plan is its named follow-on; commits Fizzygum `d60a0710` / tests `f228f343b`), memory
  `fizzygum-end-of-cycle-flush-drawdown` (the capstone gate + convert/eliminate/leave principle + the stack-probe /
  disable-probe techniques), memory `fizzygum-deferred-layout-plan` (family-5 = "Caret↔Text settle" — Option C was the
  long-deferred "caret joins the settle pass"; this plan is the in-place refinement on top). `Fizzygum/docs/
  deferred-layout-OVERVIEW.md` (the render/layout separation model). `Fizzygum-tests/DETERMINISM.md` (byte-exact
  contract + bug-class case law + diagnosis playbook). `Fizzygum/CLAUDE.md` + `Fizzygum-tests/CLAUDE.md` (build/test
  specifics).
- **Tooling:** `Fizzygum-tests/scripts/end-of-cycle-audit/run-capstone-gate.sh` (+ `eoc-production-probe.js` for enqueue
  stacks), `Fizzygum-tests/scripts/paint-readonly-audit/run-paint-readonly-gate.sh`,
  `Fizzygum-tests/scripts/torture-headless.js`, `Fizzygum-tests/scripts/run-macro-test-headless.js`. Reliable in-browser
  trace channel under the per-frame flood: `SystemTestsControlPanelUpdater?.addMessageToSystemTestsConsole "..."`.

---

**One honest caveat (carry into the new session):** the "click/arrow already settle in-place; typing/delete defer"
characterisation in §3 is reasoned from the code structure (the wrapped vs NoSettle move split) — it is HIGH-confidence
but NOT yet empirically traced. **§5 is exactly the step that turns it into ground truth**, and its outcome decides
whether this is a tiny "make it explicit/consistent" change or a small relocation. Either way the bar is byte-exact +
determinism-clean (§7); if the typing case can't meet it without churn, **leave the status quo** — it is correct today.
