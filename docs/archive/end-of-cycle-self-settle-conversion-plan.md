> **ARCHIVED — COMPLETE (2026-07-17 restructure).** EXECUTED & VERIFIED 2026-06-23 — freefloating-skip + self-settling teardown shipped.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Conversion plan — make widget teardown self-settle (+ freefloating-skip)

> ## ✅ EXECUTED & VERIFIED (2026-06-23) — the corrected approach worked
> The freefloating-skip on `destroy`/`removeFromTree`/`_addCore` **plus** making the dependent public methods
> self-settle shipped and passed every gate: **`fg gauntlet` 165/165 (dpr1/dpr2/WebKit/apps)** + an **18-min torture
> soak** (12× dpr2-fastest-s8, ~1,980 executions, **zero nondeterminism**) + the **end-of-cycle audit dropped
> −55%** (1244 → 564 interaction records; `Widget.destroy` 505 → 16) with prelude-neutrality intact (165/165).
> **The §0b "blanket change is not safe" finding still stands as written** — the resolution was NOT to abandon the
> skip but to first make the public methods it exposed self-settle. Two were found & fixed: `TextWdgt`/`StringWdgt.
> sizeToTextAndDisableFitting` (chrome-label re-hug — was silent, re-fit the button only via the caret-destroy
> accident) and `LabelButtonWdgt.setLabel`. Diff: 4 files, +60/−26 (`Widget.coffee`, `TextWdgt.coffee`,
> `StringWdgt.coffee`, `LabelButtonWdgt.coffee`). Forward work split into two follow-on plans:
> `freefloating-invalidation-skip-centralization-plan.md` (bake the skip into one primitive) and
> `end-of-cycle-flush-drawdown-plan.md` (repeat this playbook down the remaining inventory).

**Status: PLAN ONLY (design + verification protocol).** A follow-on to the end-of-cycle survey
(`end-of-cycle-flush-inventory.md` §5b). Changes *shipped* behaviour, so it is gated on the full determinism
gauntlet and on owner approval before/after implementation. Written to be executed cold.

## 0. Context — why

The survey found `Widget.destroy`/teardown is the **#1 end-of-cycle contributor** (505 records, 94 tests). The
first pass classified it "LEAVE" on settle-count grounds. Owner review overturned that on two arguments:
1. **Consistency-on-return** — a public mutation must leave the world consistent when it returns. After
   `widget.destroy()` (or `fullDestroy`) of a widget that lived in a stack / scroll-panel, the container should
   already reflect the removal, exactly as it does after the self-settling `add`. Today teardown *defers* the
   parent re-fit to the end-of-cycle flush, leaving an observable window of inconsistency.
2. **Add/remove symmetry** — a tooltip is *added* on hover via the self-settling `add` and *destroyed* on
   mouse-leave via the deferring `destroy`. The add side already self-settles per-call without issue, so the
   remove side should too.

And it surfaced a **bigger efficiency lever**: teardown invalidates the parent **unconditionally**, even for
**freefloating** widgets whose removal cannot affect the parent's layout — wasted work that is the bulk of the
traffic.

**Goal:** `close` / `destroy` / `fullDestroy` are public and self-settle like `add`, *without* (a) re-laying-out a
parent that doesn't depend on the removed widget, or (b) settling N times while tearing down an N-node subtree.

## 0b. Execution attempt 1 — FINDINGS (the blanket change is NOT safe; do not re-attempt as-is)

Tried on `Widget.coffee` (reverted to baseline after measuring). dpr1 suite results:

| change | result |
|---|---|
| **Step 1** — `_addCore:2412` old-parent freefloating-skip (site iii) | **165/165 PASS** (suite-clean) |
| **Part 1** — freefloating-skip on `destroy`/`removeFromTree` (sites i, ii) | **FAILS** `macroEditButtonLabelText` |
| **Part 2** — self-settle `destroy`/`fullDestroy` (survivor-anchored `settleLayoutsOnceAfter`) | **FAILS** `macroEditButtonLabelText` + `macroDuplicatedInspectorDrivesCopiedTargetOnly` |

**Both failures trace to ONE root cause: internal "destroy-then-recreate" callers that rely on the deferred
end-of-cycle settle to finalize.** Concrete counterexample — `LabelButtonWdgt.setLabel`:
```coffee
setLabel: (@labelString) ->
  if @label? then @label = @label.fullDestroy()   # label is FREEFLOATING (@_addCore default spec)
  @_reLayoutSelf()                                  # centres the label: @label.fullRawMoveTo @center()...
```
The button **manually lays out its freefloating label** (`_reLayoutSelf` centres it), and the final centring
**depends on the button re-laying-out a second time** — which today is triggered by the destroy's *unconditional*
parent-invalidate landing at end-of-cycle. Verified visually: with the freefloating-skip the label renders
**off-centre and clipped** ("Create widget" overflowing the button) vs. the centred reference — a **real
regression, not a benign recapture**.

**Two premises falsified:**
1. *"Removing a freefloating child can't affect the parent's layout"* is **FALSE** for a container that manually
   positions its freefloating child (`LabelButton`; likely others). The freefloating-skip is therefore **not
   blanket-safe** on the teardown side — even though `add`'s mirror skip (`:2425`) ships, because on the *add* side
   the caller follows up with an explicit layout, whereas on teardown the only re-layout was the one we removed.
2. *"Self-settle is just wrap + audit callers"* — the audit reveals callers (`setLabel`, inspector duplication)
   whose destroy-then-recreate **self-settles an intermediate state** (re-layout fires while `@label` still points
   at the dying label), changing the result.

**Corrected approach (the real prerequisite):** before any teardown change, **make the destroy-then-recreate
callers self-contained** — each must finalize its own layout in its explicit re-layout (or batch the whole rebuild
in `settleLayoutsOnceAfter`), instead of leaning on the destroy-triggered end-of-cycle settle. Candidates to fix
first: `LabelButtonWdgt.setLabel`, the inspector-duplication path, `WindowWdgt` titlebar/label rebuild,
`WorldWdgt.edit/stopEditing` caret swap. **Only after those are robust** do Parts 1–2 become safe. Net: the
numbers *would* drop (the ~261 `WorldWdgt`-from-`destroy` is real wasted work), but not via a blanket edit — the
caller-robustness work is the gating effort, and it is larger than this plan first assumed.

`_addCore:2412` (Step 1) stands apart: it was **suite-clean** because no managed-freefloating-child is *re-parented*
in the suite (only destroyed) — but its premise is the same suspect one, so treat it as unproven beyond the suite.

## 1. The model today (verified)

| method | recurses? | parent re-fit | settles? | file:line |
|---|---|---|---|---|
| `close()` | no (moves subtree as a unit to the basement) | via `add` to basement (+ old parent via `_addCore`) | **YES — self-settles** | `Widget.coffee:475` |
| `destroy()` | no (single node; clears own `@children`) | `@parent?.invalidateLayout()` **unconditional** | **NO — defers** | `Widget.coffee:500` (invalidate :519) |
| `removeFromTree()` | no | `@parent?.invalidateLayout()` **unconditional** | **NO — defers** | `Widget.coffee:2080` |
| `fullDestroy()` | **yes** (`@children[0].fullDestroy()` until empty, then `@destroy()`) | each node's `destroy()` | **NO — defers, ×N** | `Widget.coffee:566` |

`close()` is already correct → **no work**. The two facts that drive the plan:
- **Freefloating principle exists but is bypassed by teardown.** `invalidateLayout`'s climb-guard
  (`Widget.coffee:3766`) skips the parent when `@layoutSpec == ATTACHEDAS_FREEFLOATING`, and the settle drain loop
  treats a freefloating widget as a layout *root* (`WorldWdgt.coffee:914`, `break`s the walk-up at freefloating).
  But `destroy`/`removeFromTree` call `@parent.invalidateLayout()` **directly**, sidestepping the guard — so a
  freefloating menu/tooltip teardown schedules a parent (`world`) re-layout that **runs and changes nothing**.
- **The settle wrappers already exist** (`Widget.mutateGeometryThenSettle` :748, `settleLayoutsOnceAfter` :795),
  with orphan/batch/re-entrancy guards — the same machinery `add` uses.

## 2. Part 1 — freefloating-skip (do FIRST; the big lever, de-risks Part 2)

**Change:** apply the freefloating remove-side skip consistently at **all three** sites that invalidate a parent
when a widget *leaves* it — each keyed on **how the widget was attached in the parent it is leaving**:

```coffee
# (i) Widget.destroy (~:519)  and  (ii) Widget.removeFromTree (~:2081):  replace
@parent?.invalidateLayout()
# with
@parent?.invalidateLayout() unless @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING

# (iii) _addCore (~:2412), the re-parent OLD-parent invalidate:  replace
aWdgt.parent?.invalidateLayout()
# with  (NB: aWdgt.layoutSpec — the OLD spec, read BEFORE setLayoutSpec — NOT the layoutSpec param)
aWdgt.parent?.invalidateLayout() unless aWdgt.layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING
```

**The (iii) subtlety is load-bearing — do NOT reuse the `layoutSpec` parameter.** The old-parent invalidate runs
*before* `setLayoutSpec`, so `aWdgt.layoutSpec` is still the widget's spec **in the old parent** — the spec that
decides whether the *old* parent's layout changes. The `layoutSpec` *param* is the **new** spec for the **new**
container (correctly used by the existing `:2425` check). Using the param for the old-parent check breaks both
directions: *stack-element → freefloating* would wrongly skip a needed old-parent re-fit (stale gap); *freefloating
→ stack-element* would wrongly invalidate the old parent (the bug we're removing).

**Why it's sound (decisive — `add` already does exactly this):** `_addCore` (`Widget.coffee:2425`) invalidates the
receiving container **only** for non-freefloating children:
```coffee
if layoutSpec != LayoutSpec.ATTACHEDAS_FREEFLOATING
  @invalidateLayout()          # add a freefloating child -> container is NOT invalidated
```
So the *add* side already skips the container re-fit for freefloating children. `destroy`/`removeFromTree` are
simply the **inconsistent** twin — they invalidate the parent unconditionally. Part 1 is therefore not a new
optimization but **restoring the symmetry `add` already ships**: `ATTACHEDAS_FREEFLOATING` means "positioned
absolutely, not laid out by the parent," and the settle loop already treats it as a layout root. The re-parent
old-parent invalidate (`_addCore:2412`) is the same remove-side case and is included above as site (iii) — staged
separately (§6) because the re-parent path (drag-drop, `close()→basement`) is more central/higher-frequency.

**Effect:** eliminates the dominant teardown traffic — the ~261 `WorldWdgt`-from-`destroy` records (menus,
tooltips, free-dragged windows on the desktop) — and removes them from the hot hover/menu path entirely. It also
de-risks Part 2: the high-frequency overlay teardown now schedules *nothing*, so there is nothing to settle there.

**Caveats to verify (the gauntlet decides):**
- **Aggregate-property containers.** If any container's layout/scroll-extent *does* read its freefloating children
  (rather than treating them as absolute), skipping would under-invalidate it. The audit shows freefloating
  teardown was world/desktop-parented (no such dependency); confirm no scroll-panel/stack computes extent over
  freefloating children. If one does, scope Part 1 to world-parented freefloating first.
- **Repaint vs layout.** `destroy` already handles the shadow/repaint separately (`firstParentOwningMyShadow`/
  `fullChanged`); Part 1 touches *layout* scheduling only, so the visual removal still repaints. Confirm no test
  relied on the parent's *layout* pass to trigger an unrelated repaint.

## 3. Part 2 — self-settle the residual (non-freefloating) teardown

For a widget that **does** participate in a container's layout (in a stack / scroll-panel), make teardown
consistent-on-return.

**Recommended primitive: survivor-anchored `settleLayoutsOnceAfter` for BOTH `destroy` and `fullDestroy`**
(this refines inventory §5b, which floated `mutateGeometryThenSettle` for the single case):

```coffee
# fullDestroy: batch the whole recursion into ONE settle, anchored on a SURVIVOR.
fullDestroy: ->
  parent = @parent                        # capture BEFORE teardown detaches us
  (parent ? world).settleLayoutsOnceAfter =>
    @_fullDestroyCore()                    # the existing recursion + @destroy()
  return nil
```

Three reasons `settleLayoutsOnceAfter` beats `mutateGeometryThenSettle` here:
1. **Batches the recursion.** N descendant `destroy`s (each invalidating its now-doomed parent) collapse to one
   settle of the surviving container. (Only the root's *external* parent actually needs re-layout; the internal
   parents are themselves being destroyed, so their invalidations are moot by the time the batch flushes.)
2. **Defers gracefully when nested — no throw.** `mutateGeometryThenSettle` **throws** if reached while
   `world._inLayoutMutation` (e.g. teardown invoked from inside an `add`'s flush, as the rebuild
   `buildAndConnectChildren → fullDestroyChildren` paths are). `settleLayoutsOnceAfter` instead **skips its tail
   flush** under `_inLayoutMutation`/`_recalculatingLayouts` (`Widget.coffee:805`) and lets the outer flush settle
   — graceful, and still consistent-on-return for the outer public call.
3. **Self-settles when top-level.** When *not* nested, it runs the thunk then `recalculateLayouts()` before
   returning — exactly the contract we want.

**THE survivor-anchor gotcha (do not get this wrong):** `settleLayoutsOnceAfter` orphan-checks **at the tail**
(`unless @isOrphan() …`, `Widget.coffee:805`). If you anchor on `@` (the widget being torn down), then *after* the
thunk `@` is detached → `@isOrphan()` is true → **the flush is silently skipped** (looks like it works, doesn't
settle). So anchor on a **survivor**: the captured `parent`, or `world` (which is never orphan). For single
`destroy`, same treatment: `(@parent ? world).settleLayoutsOnceAfter => @_destroyCore()`.

Keep `close()` as-is (already self-settling).

## 4. Caller audit (must classify each by execution context)

The wrappers' re-entrancy rules mean the conversion is **wrap + audit callers**, not just wrap. Classify each
caller: **[E] event-dispatch / top-level** (safe — settles immediately), **[C] construction / nested-in-a-flush**
(safe — defers to the outer flush), **[L] reachable from a layout pass** (MUST FIX — `invalidateLayout` itself
throws mid-pass, `Widget.coffee:3761`, independent of this change).

- **`destroy()` — 15 sites:** `WindowWdgt` (own switch/edit buttons), `ToolTipWdgt` (contents), `StretchableEditableWdgt`/`SimpleDocumentWdgt` (`toolsPanel`), info-widgets ×8 (`containerWindow.destroy()` — window close, [E]), `Widget` (internal). Mostly [E]; the sub-button teardowns inside `_buildAndConnectChildren*` are [C].
- **`removeFromTree()` — 2 sites:** `BasementWdgt`, `Widget` (internal). [E].
- **`fullDestroy()` — 19 sites:** window hard-close (`closeFromContainerWindow` overrides) [E]; `BasementWdgt.empty` [E]; transient overlays — `WorldWdgt.destroyToolTips`/`addHighlightingWidgets`/`addPinoutingWidgets`, `ActivePointerWdgt.destroyTemporaryHandles…` (**Part 1 makes these no-ops for layout** — freefloating); rebuild — `LabelButtonWdgt.setLabel`, `WindowWdgt.buildTitlebarBackground`/`_buildAndConnectChildrenCore`, `WorldWdgt.edit`/`stopEditing` (caret) — **verify [C] vs [L]**; droplet `reactToDropOf` [E]; `MenuWdgt.removeMenuItem` [E]; `WorldWdgt.resetWorld` [E].
- **`fullDestroyChildren` — 6, `closeChildren` — 1:** the `buildAndConnectChildren` ones are [C]; `BasementWdgt.empty`/`resetWorld`/`ScrollPanelWdgt.setContents` are [E].

The **only worrying class is [L]** — a teardown reachable from inside `_reLayout`. Start by grepping rebuild paths
(`setLabel`, titlebar) for layout-pass reachability; the re-entrancy throw will loudly surface any missed one in
the gauntlet rather than failing silently.

## 5. Verification protocol (mandatory)

1. **Part 1 alone, full gauntlet:** build + dpr1 suite + dpr2 suite + WebKit suite + app smoke (165/165 each).
   Re-run the survey audit prelude (`Fizzygum-tests/scripts/.scratch/`) and confirm the `WorldWdgt`-from-`destroy`
   group **disappears** and no *new* end-of-cycle origins appear. Recapture only tests whose post-state genuinely
   improved (there should be none — freefloating removal changes no laid-out geometry).
2. **Part 2 on top, full gauntlet + torture soak** (`torture-headless.js`, the dpr2-fastest-s8 regime that catches
   settle-count/order nondeterminism). This is the determinism-sensitive step: self-settling changes *when* and
   *how many* settles happen per frame.
3. **Consistency spot-check:** a new/extended macro test that destroys a widget inside a constrained stack /
   scroll-panel and asserts the container's geometry **in the same step** (not a frame later) — proves
   consistency-on-return.
4. **Re-entrancy:** confirm no test trips the `mutateGeometryThenSettle`/`invalidateLayout` mid-pass throw (a green
   suite is the proof; a thrown error shows up as a failed/`completed:false` test).

## 6. Staging & rollback

- **Stage 1a: Part 1 teardown** — freefloating-skip at `destroy:519` + `removeFromTree:2081` (sites i, ii). Small,
  principled, independently valuable; ship + verify first.
- **Stage 1b: Part 1 re-parent** — freefloating-skip at `_addCore:2412` (site iii, old-spec keyed). Separate stage:
  the re-parent path (drag-drop, `close()→basement`) is more central, so verify it on its own.
- **Stage 2: Part 2 `fullDestroy`** (survivor-anchored `settleLayoutsOnceAfter`) — the recursive batch.
- **Stage 3: Part 2 `destroy`/`removeFromTree`** (same wrapper) — the single-node case.
- Optional **Stage 4:** the `VerticalStackLayoutSpec` setters + `newParentChoice` micro-conversions (unrelated, can
  ride along).
Each stage independently revertable (one wrapper / one guard). Rollback = drop the wrapper; behaviour returns to
deferred-but-correct.

## 7. Open questions to resolve during implementation

- **Scope of Part 1:** all freefloating, or world-parented-freefloating first? (Decide from the §2 aggregate-property
  check.)
- **`removeFromTree` semantics:** it's the bare detach (used by basement). Does it want self-settle, or is it a
  deliberately-raw primitive? (Likely give it the freefloating-skip but leave the settle to its callers — confirm.)
- **Anchor choice:** captured `parent` vs `world`. `world` is simplest (never orphan) and always settles the whole
  tree; the parent is tighter but null after detach. Recommend `(@parent ? world)`.
- **Does the gauntlet force recaptures?** Expectation: Part 1 = none; Part 2 = none (same final geometry, earlier
  timing). Any recapture is a signal to investigate, not rubber-stamp.

---

*Cross-refs:* `end-of-cycle-flush-inventory.md` (§5b verdict), `deferred-layout-OVERVIEW.md` (the settle engine +
determinism regime), `DETERMINISM.md` (the byte-exact contract + torture playbook).
