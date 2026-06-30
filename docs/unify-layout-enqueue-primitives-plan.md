# Plan — unify the layout-enqueue primitives (one named no-climb push; fold the caret into `_invalidateLayout`)

**Status: ✅ EXECUTED + PUSHED 2026-06-27 (Fizzygum `282ea492` / tests `06ece785a`).** Implemented exactly as designed
below (atom `_markForRelayoutNoClimb` + the inert-receiver branch + `_requestScrollFollow → @_invalidateLayout()`;
`_reFitContainer` left as the named dispatcher). Outcome notes: lint `[E]` needed NO lockstep update (§4.3's risk did
not materialise — the caret's enqueue is not from an immediate-mutator path); one benign inspector recapture
(`macroDuplicatedInspectorDrivesCopiedTargetOnly`, which shows inherited members); dpr2 torture 5 iters / ~825 execs
clean (no RECALC_NONCONVERGENCE); capstone 0; paint-readonly 0. The original cold-plan text is kept below for the record.

**(original) Status: PLAN ONLY (not started). Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Everything needed — what the project is, the three enqueue operations that exist today (with their real code), the
worry that motivates this, why it resolves, the exact target design, what can and cannot fold, the verification
protocol, and all references — is embedded inline or one named-doc hop away. **Line numbers drift: grep the named
symbol, never trust a line number in this doc.**

**One-line goal.** Today there are THREE ways layout work gets enqueued into `world.widgetsThatMaybeChangedLayout`,
and one of them — the caret's — is a *bare open-coded push* that deliberately bypasses `_invalidateLayout` (the
canonical scheduling verb) to avoid its mid-pass throw and its careless-push audit. That bypass is *correct* (see §2),
but it leaves feature/overlay code with two verbs for "schedule my re-layout" and duplicates the bare-push snippet in
three places. **Extract the bare push into ONE named no-climb primitive, and fold the caret into `_invalidateLayout`
via a state-derived branch so the guards PASS (not throw) when they are structurally inapplicable — giving everyone
ONE verb (`_invalidateLayout`) plus one named primitive underneath it.**

**This is a PURITY / layering refinement, not a correctness fix.** The current behaviour is correct and byte-exact.
The win is that "rich scheduling op = bare primitive + climb + guards" becomes *visible in code* instead of folklore,
and the bare push stops being open-coded at a feature call-site. **Treat the bar accordingly: this edits a
determinism-sensitive core (the flow-rule guard + `_invalidateLayout`) AND a build-time lint that encodes the layering
— if it can't be made byte-exact + determinism-clean + lint-green with reasonable effort, leave it; the status quo is
sound and well-documented.**

---

## §0 — Orientation + why this now

**Fizzygum** is a CoffeeScript GUI framework — a "web operating system" (windows, desktop, drag-and-drop, live
in-system editing) rendered on a single HTML5 `<canvas>`, descended from Morphic.js. ~470 `.coffee` classes in
`Fizzygum/src/`; every class is a global compiled in-browser (no `require`/`import`); `nil` == `undefined`; one class
per file, filename == class name. The umbrella `/Users/davidedellacasa/code/Fizzygum-all/` is NOT a git repo; it holds
three sibling git repos that must stay siblings:
- **`Fizzygum/`** — framework source (edit here) + the build script + the layering lint (`buildSystem/check-layering.js`).
- **`Fizzygum-tests/`** — 165 macro SystemTests (drive the live world, compare SWCanvas SHA-256 screenshots
  **byte-exactly**) + the test harness + the audit gates.
- **`Fizzygum-builds/`** — generated build output (never hand-edit).

Commands run via the path-correct `fg` wrapper **from the umbrella root** `/Users/davidedellacasa/code/Fizzygum-all/`:
`./fg build` · `./fg suite` (165 tests, dpr1, ~1.3 min) · `./fg gauntlet` (build + dpr1 + dpr2 + WebKit + 12 apps) ·
`./fg test <name>` · `./fg recapture <name>`. (The `fg` wrapper is local workspace tooling, not committed.)

**Why this now.** This plan is a follow-on to the caret "in-place settle" arc (Fizzygum `20586db1`) and the "Option C"
arc before it (`d60a0710`) — see memory `fizzygum-paint-readonly-caret-resync`. While reviewing those, the owner asked
(via a `/btw` fork) about `CaretWdgt._requestScrollFollow`'s comment, which says the caret *"enqueues ITSELF with the
low-level schedule primitive (push + mark invalid), NOT `_invalidateLayout`."* The worry, verbatim:

> *"why do we have two similar ways to do almost the same thing? … I am worried that this was exactly needed to NOT
> trigger the flow rule, which probably was there FOR GOOD REASON???"*

The worry is the right instinct. §2 shows it doesn't fire here (the guard is *inapplicable*, not silenced), and the
owner greenlit this plan to remove the duplication cleanly.

---

## §1 — The THREE enqueue operations today (the real code)

All in `src/basic-widgets/Widget.coffee` except C. Grep each symbol. The shared atom in all three is the **bare push**:
`if X.layoutIsValid then world.widgetsThatMaybeChangedLayout.push X` then `X.layoutIsValid = false`.

**A — the climbing invalidate `_invalidateLayout` (grep `_invalidateLayout:`).** The canonical "I, a laid-out content
widget, changed; my container may need re-fit, and so may *its* container" verb. Structure (paraphrased; grep the real
body):
```coffee
_invalidateLayout: (triggeringChild = nil) ->
  return if triggeringChild?.isFreeFloating()              # (1) freefloating-CHILD bail: a freefloating child's
                                                           #     change can't affect its parent's layout. NB this
                                                           #     keys off the TRIGGERING CHILD, not the receiver.
  if world?._recalculatingLayouts                          # (2) FLOW-RULE throw: a raw/silent/fullRaw setter that
    throw "FLOWRULE_VIOLATION: ... must not schedule layout (task #17)"   #   schedules layout MID-PASS would re-dirty
                                                           #     ancestors and break until-loop convergence (the
                                                           #     Phase-3b-Slice-2 app-freeze). Lint rule [E] is the
                                                           #     static enforcer; this throw is the runtime tripwire.
  if world?.healingRectanglesPhase and world.auditPaintTimeLayoutScheduling and not @isOrphan()
    (world._paintTimeLayoutSchedules ?= []).push ...       # (3) paint-time audit (paint-read-only gate)
  if @layoutIsValid                                        # (4) THE BARE PUSH (the atom)
    world.widgetsThatMaybeChangedLayout.push @
    if world.auditUndeclaredEndOfCycle and world._coalescedDeclarationDepth == 0 and not world._inLayoutMutation and not @isOrphan()
      (world._undeclaredEndOfCyclePushes ?= []).push ...   # (5) careless-push audit (end-of-cycle capstone gate)
  @layoutIsValid = false
  @parent?._invalidateLayout(@)                            # (6) THE CLIMB: tell my parent a child changed
```
So `_invalidateLayout` = **bail + throw + paint-audit + bare-push + careless-audit + climb**. The throw (2), the
careless-audit (5), and the climb (6) are the parts a free-floating inert overlay must NOT engage.

**B — the phase-dispatch seam `_reFitContainer` (grep `_reFitContainer:`).** "Re-fit ONE directly-affected container at
the next settle point." It is *already a dispatcher* between an in-pass bare push and off-pass `_invalidateLayout`:
```coffee
_reFitContainer: (container = @) ->
  return unless container?._reLayoutChildren?              # only a tracking container (Window/Stack/ScrollPanel) reacts
  return if container._adjustingContentsBounds             # skip if the container is mid its OWN child-layout pass
  if world?._recalculatingLayouts
    if container.layoutIsValid                             # <-- THE BARE PUSH (in-pass arm), no climb, no throw
      world.widgetsThatMaybeChangedLayout.push container
    container.layoutIsValid = false
  else
    container._invalidateLayout()                          # <-- off-pass arm: the canonical climbing verb
```
Its header comment states the rule explicitly: *"Enqueuing is legal mid-pass — unlike `_invalidateLayout` it neither
throws (the freeze guard) nor climbs to ancestors; it enqueues only the directly-affected container."* The
immediate-mutator raw-geometry seam reaches B via `_reFitContainerAfterRawGeometryChange` (grep it), which **bails on
`isLayoutInert`** (`return if @isLayoutInert?()`) — so overlay chrome (carets, handles) never trips a container re-fit.

**C — the caret's self-schedule `CaretWdgt._requestScrollFollow` (grep it in `src/basic-widgets/CaretWdgt.coffee`).**
```coffee
_requestScrollFollow: ->
  if @layoutIsValid then world.widgetsThatMaybeChangedLayout.push @   # <-- THE BARE PUSH, open-coded at a feature site
  @layoutIsValid = false
```
The caret is `isLayoutInert: -> true` and free-floating (`ATTACHEDAS_FREEFLOATING`). It enqueues ONLY itself (no climb)
and its `_reLayout` runs the scroll-follow. Its comment documents *why* it uses the bare push not `_invalidateLayout`
(no parent layout to climb; the throw + audit target content mutators that forgot to self-settle — which a deliberate
overlay self-schedule is not). **C is the only genuinely loose open-coding of the bare-push atom** — A and B both own
it legitimately (A is the canonical verb; B is the documented phase dispatcher).

---

## §2 — The worry, and why it resolves (read this before touching anything)

**Worry:** the caret's bare push exists *specifically to dodge the flow-rule throw, which is there for a good reason* —
so the bypass might be hiding a real hazard.

**Resolution: the flow-rule guards the CLIMB, and the climb is structurally impossible for the caret. The guard is
inapplicable, not silenced.** Point by point:
1. **What the throw protects is convergence, and the specific danger is the climb.** The `FLOWRULE_VIOLATION` fires when
   `_invalidateLayout` is reached mid-pass; its stated hazard (grep the comment) is "a container resizing its children
   climbed an invalidate back into itself, so the until-loop never converged" (Phase-3b-Slice-2 freeze). The thing being
   protected is the until-loop; the thing that breaks it is a **climbing** reschedule re-dirtying ancestors mid-pass.
2. **`_invalidateLayout` is layered; the caret wants only its bottom layer.** Its body is bail → throw → paint-audit →
   **bare push** → careless-audit → **climb**. The caret wants the bare push and nothing else: it is free-floating, so it
   has no parent layout to climb into — `_invalidateLayout`'s *very first line* already bails on a free-floating
   *trigger*. The throw was firing on the wrong primitive, not catching a real caret hazard.
3. **The bare push is the framework's OWN in-pass primitive, not a caret invention.** B (`_reFitContainer`) does the
   identical thing in-pass and documents it as legal. The whole deferred-layout system is **in-pass → bare push;
   off-pass → `_invalidateLayout`**.
4. **The caret cannot create the hazard the rule guards.** Its follow chain moves geometry through RAW setters only
   (`fullRawMove*` in `CaretWdgt._oneScrollCaretIntoViewPassNoSettle` and `ScrollPanelWdgt.scrollCaretIntoView` /
   `keepContentsInScrollPanelWdgt`) — no re-entrant public settle. It enqueues only itself (no climb). It is excluded
   from every container's content-bounds, so `_reFitContainerAfterRawGeometryChange` bails for it (`isLayoutInert`) —
   re-running its `_reLayout` re-fits no ancestor. The genuine vertical scroll moves the panel's (non-inert) `@contents`,
   which enqueues the panel via B's *sanctioned* in-pass arm, and the until-loop re-runs the caret after the panel
   settles.
5. **Convergence is backstopped regardless** by `recalcIterationsCap → RECALC_NONCONVERGENCE` (loud, never a silent
   freeze; the dpr2 torture greps for it).

**Where the worry IS legitimate, and must stay guarded after this change:** if the bare-push primitive ever spread to
an ordinary **content** widget (which *does* climb and *does* need the guard), that would be the real smell. The fix
keeps that fenced: the only blessed receivers of the no-climb push are (a) a container B is dispatching in-pass, and
(b) an inert + free-floating overlay. **The extracted primitive must ASSERT this** (see §3 step 1).

---

## §3 — The target design (the owner-greenlit shape)

Three moves. Do them in order; build + verify after each (§7).

**Step 1 — extract ONE named no-climb push primitive.** A single Widget method holding the bare-push atom, with an
invariant assertion that its receiver is a legal no-climb target. Suggested name: `_markForRelayoutNoClimb` (pick a name
that reads as "enqueue me/this, do NOT climb"; the `NoClimb` suffix mirrors the existing `NoSettle` "non-settling
region" signal — see memory `fizzygum-layering-naming-tiers`). Sketch:
```coffee
# The bare layout-enqueue ATOM: put a widget into the recalculateLayouts until-loop WITHOUT climbing to ancestors and
# WITHOUT the flow-rule throw / careless-push audit that _invalidateLayout carries for the climbing content-widget case.
# Legal ONLY for a no-climb receiver: a tracking container being re-fit in-pass by its own seam (_reFitContainer), or an
# inert + free-floating overlay (caret / handle) that has no parent layout to climb. NEVER call this on a plain content
# widget -- it must use _invalidateLayout (which climbs + guards). (See §2 of the unify-enqueue plan for why.)
_markForRelayoutNoClimb: ->
  if @layoutIsValid then world.widgetsThatMaybeChangedLayout.push @
  @layoutIsValid = false
```
Then route the three existing bare pushes through it:
- `_invalidateLayout`'s own enqueue step (4) becomes `@_markForRelayoutNoClimb()` (it then still runs the careless-audit
  and climb around it — careful: the audit (5) currently sits BETWEEN the push and `@layoutIsValid = false`. Keep the
  audit in `_invalidateLayout`, not in the atom — the atom is audit-free by definition. So `_invalidateLayout` calls the
  atom, then the climb; the careless-audit either moves just before the atom call or stays inline. Verify the capstone
  gate still records the same content-widget pushes — see §7.)
- `_reFitContainer`'s in-pass arm becomes `container._markForRelayoutNoClimb()`.
- `CaretWdgt._requestScrollFollow` becomes `@_markForRelayoutNoClimb()` (or is deleted in step 2).

**⚠ Naming/lint caveat:** `_markForRelayoutNoClimb` is `_`-prefixed ⇒ the lint classifies it low-level (`isLowLevel`).
Low-level methods may push to the queue (the atom is exactly that), but re-check rules [A]/[B]/[E]/[G] after adding it
(grep `check-layering.js`): it must NOT call `recalculateLayouts`, a public setter, a self-settling wrapper, or
`_invalidateLayout`. It only does the push — so it should be clean, but BUILD to confirm.

**Step 2 — fold the caret (C) into `_invalidateLayout` via a state-derived branch.** Add, at the TOP of
`_invalidateLayout` (BEFORE the throw/paint-audit/careless-audit/climb), a branch for a no-climb *receiver*:
```coffee
_invalidateLayout: (triggeringChild = nil) ->
  return if triggeringChild?.isFreeFloating()
  # A free-floating + inert receiver (caret / handle overlay) has no parent layout to climb and cannot re-dirty any
  # ancestor (it is excluded from every container's content-bounds), so the climb + the flow-rule throw + the
  # careless-push audit are all structurally INAPPLICABLE -- they PASS, they are not silenced (§2). Enqueue just me.
  if @isFreeFloating() and @isLayoutInert?()              # gate on BOTH predicates -- no content widget may slip through
    @_markForRelayoutNoClimb()
    return
  ...rest unchanged (throw / paint-audit / bare-push+careless-audit / climb)...
```
Then make `CaretWdgt._requestScrollFollow` call `@_invalidateLayout()` (or delete it and have callers use
`@_invalidateLayout()` directly — but keeping the well-named `_requestScrollFollow` wrapper around `@_invalidateLayout()`
is arguably clearer at the caret's call sites; decide on read). Now feature/overlay code has ONE verb.

**Two subtleties that MUST hold (verify, do not assume):**
- **The new branch returns BEFORE the careless-push audit**, so the caret is STILL not recorded in
  `_undeclaredEndOfCyclePushes`. The end-of-cycle capstone gate must stay 0 (it is 0 today precisely because the caret
  bypasses `_invalidateLayout`; the branch preserves that by returning early).
- **The new branch returns BEFORE the flow-rule throw**, so an inert+free-floating receiver never throws even mid-pass —
  which is the whole point ("guards pass when inapplicable"). Confirm no in-pass caret enqueue now throws (it didn't
  before because it bypassed `_invalidateLayout`; the branch keeps it non-throwing).

**Step 3 — leave B (`_reFitContainer`) as the named dispatcher.** It cannot fold into `_invalidateLayout`: its
"don't climb / don't throw" is a property of the **calling context** (we are inside a controlled pass, enqueue just this
one container and let its own seam re-fire to propagate up), NOT of the receiver's state (the container is a normal
laid-out widget — not free-floating, not inert). `_invalidateLayout` cannot derive "we're in a controlled pass, skip the
climb" from the receiver. A `{climb:false}` flag would be *worse* than a named dispatcher (a boolean that silently flips
climb+throw+audit hides which behaviour you got; the named seam makes it legible). So B stays — but after step 1 it
shares the atom, so the duplication is gone and the relationship is visible.

**Net end-state:** one verb (`_invalidateLayout`) for everyone who schedules layout; one named no-climb atom
(`_markForRelayoutNoClimb`) underneath it, used by `_invalidateLayout` + `_reFitContainer` + the caret; the guards PASS
for the provably-safe inert+free-floating case; B remains the honest "two modes, named on the seam" dispatcher.

---

## §4 — The DECISIVE first checks (before writing step 2)

1. **Confirm the receiver predicates exist and are cheap.** Grep `isFreeFloating:` (Widget.coffee) and `isLayoutInert`
   (it is a capability `?()` — defined `-> true` on `CaretWdgt` and the resize handles, absent elsewhere; call it
   `@isLayoutInert?()`, never assume a Widget base default — type-test-elimination convention). Confirm the ONLY widgets
   that are BOTH free-floating AND inert are the caret + handles (grep `isLayoutInert: -> true` across `src/`). If any
   non-overlay is both, the branch would wrongly skip its climb — STOP and reconsider the gate.
2. **Census the bare-push sites.** Grep `widgetsThatMaybeChangedLayout.push` across `src/` — confirm exactly the three
   sites in §1 (A `_invalidateLayout`, B `_reFitContainer`, C `_requestScrollFollow`) plus the until-loop's own pops in
   `WorldWdgt._recalculateLayoutsBody` (not pushes). If there is a FOURTH open-coded push, classify it (is it a no-climb
   container/overlay case the atom should serve, or a content widget that should use `_invalidateLayout`?).
3. **Read lint rule [E] and the careless-audit.** Grep `\[E\]` and `isImmediateMutator` in
   `buildSystem/check-layering.js`: [E] flags an immediate mutator (`raw*`/`silent*`/`fullRaw*`) that calls
   `_invalidateLayout`. The caret's enqueue is NOT from an immediate mutator (`_requestScrollFollow` /
   `_gotoSlotNoSettle`), so folding it should not trip [E] — but the moment `_invalidateLayout` gains an inert branch,
   re-run the build: if ANY immediate-mutator path now reaches `_invalidateLayout` for an inert receiver and [E] fires,
   the lint must learn the inert-receiver exemption IN LOCKSTEP (or the build breaks). Treat this as "verify
   empirically," not "definitely needed."

---

## §5 — Verification protocol (MANDATORY — determinism-sensitive core + lint change)

Run the FULL set; this touches `_invalidateLayout`, the flow-rule guard, and the enqueue atom — the most
convergence-critical code in the system. `fg` runs from any cwd but lives at the umbrella root.
1. `./fg build` — **0 violations, 0 warnings** (lints A–H + dead-method + thin-wrap + CoffeeScript syntax). If [E]/[F]/[G]
   fire, resolve in lockstep (see §4.3) — do NOT blanket-sanction; understand each hit.
2. `./fg suite` — dpr1 **165/165**. On a pixel failure, dump + LOOK (don't recapture blindly):
   `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/run-macro-test-headless.js
   SystemTest_<name> --dpr=1 --dump-failures=.scratch/x`, then Read the dumped `.png` vs the committed reference.
3. `./fg gauntlet` — dpr1 / dpr2 / WebKit **165/165** + **apps 12/12**.
4. **dpr2 torture — THE GOLD GATE** (convergence + cadence): `cd .../Fizzygum-tests && node scripts/torture-headless.js
   --dprs=2 --speeds=fastest --shards=4 --minutes=10 --out=.scratch/torture-unify` → REPORT.md must say "No
   nondeterminism observed", failures dir empty, **and grep the run for `RECALC_NONCONVERGENCE` (must be absent)** — this
   is the single most important signal for THIS change (the guard you are relaxing exists to protect convergence).
   GOTCHA: `pkill -9 -f "Chrome for Testing"` before torture; rebuild first (the stale-build canary refuses an old build).
5. **End-of-cycle capstone gate stays 0:** `cd .../Fizzygum-tests && bash scripts/end-of-cycle-audit/run-capstone-gate.sh
   > /tmp/cap.log 2>&1 ; echo "EXIT $status" ; tail -6 /tmp/cap.log`. **DO NOT pipe the gate into `tail`/`grep`
   directly — the pipe masks the script's real exit code** (a pipe-to-`tail` once reported exit 0 on a FAILED gate). Must
   print "✓ CAPSTONE GATE PASSED". *(Critical for this change: the inert-receiver branch returns before the careless
   audit, so the caret must stay unaudited and the count must stay 0 — a regression here means the branch is mis-placed.)*
6. **Paint-read-only gate stays 0:** same no-pipe pattern with `scripts/paint-readonly-audit/run-paint-readonly-gate.sh`.

**Recapture note:** the change adds `_markForRelayoutNoClimb` to the Widget base (inspector-SAFE — adding a method to a
common base is zero-recapture, per memory `oo-smells-backlog`) and may remove/rename `CaretWdgt._requestScrollFollow`.
The 3 inspector tests (`macroAddEditSaveRenameRemoveProperty`, `macroInspectorScrollbarUnplugged`,
`macroMovingSlidersSidewaysDoesntCauseContentToMoveSideways`) inspect a **StringWdgt**, not a caret, so a CaretWdgt-only
method change should NOT recapture them — but if a shared-base member-list shifts, a benign inspector recapture is the one
pre-authorized class (just `./fg recapture <name>` at dpr1+dpr2; it is NOT a behaviour change). Confirm by dumping +
looking before recapturing. Determinism contract + bug-class case law: `Fizzygum-tests/DETERMINISM.md`.

---

## §6 — Owner principles + workflow (honour these)

- **Guards PASS when structurally inapplicable; they are not silenced.** The inert+free-floating branch must be gated on
  BOTH predicates and documented as "the climb/throw/audit are inapplicable here," never as "skip the guard." If you
  cannot prove inapplicability for a receiver, it does NOT get the branch.
- **No `{climb:false}` boolean.** A flag that flips climb+throw+audit is worse than the named seam (B). Keep B named.
- **One verb for feature code.** After this, feature/overlay code schedules layout via `_invalidateLayout` only; the atom
  is an internal primitive (3 blessed callers), not a feature-facing API.
- **Clean/elegant code is the standing priority** over avoiding a benign inspector member-list recapture (just recapture;
  never contort code to dodge it).
- **Review-driven; run straight through then present ONE end-of-arc review.** Present the §4 checks + the diff + full §5
  verification in a single review. **ASK before each commit AND push** — present the diff + proposed message, wait for
  explicit approval. Use `git commit -F <file>` — NEVER backticks / `$()` in `git commit -m` (the Bash tool runs bash
  semantics and command-substitutes them, silently corrupting the message). Verify with `git log -1 --format=%B`. End
  every commit message with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Push from the repo's
  own dir.
- **Shell gotchas:** the Bash tool runs FISH; cwd may reset (use `cd /abs/... && …`; `$status` not `$?`). A PreToolUse
  guard BLOCKS a command that `cd`s into a non-`Fizzygum-tests` dir then runs a `Fizzygum-tests/scripts` node script —
  run those FROM `Fizzygum-tests` or via `fg`. Kill orphan `Chrome for Testing` before any suite/torture/audit. NEVER
  pipe a build/gate whose exit code you need into `tail`/`grep`.

---

## §7 — Anchors & references (grep the symbol; numbers drift)

- **The primitives (what you're changing):** `src/basic-widgets/Widget.coffee` — `_invalidateLayout` (the climbing verb:
  freefloating-child bail, FLOWRULE_VIOLATION throw, paint-audit, bare-push + careless-audit `_undeclaredEndOfCyclePushes`,
  climb), `_reFitContainer` (the phase dispatcher: in-pass bare-push arm vs off-pass `_invalidateLayout`),
  `_reFitContainerAfterRawGeometryChange` (the raw-geometry seam; `isLayoutInert?()` bail), `isFreeFloating`,
  `widgetsThatMaybeChangedLayout`. `src/basic-widgets/CaretWdgt.coffee` — `_requestScrollFollow` (the open-coded bare
  push, C), `isLayoutInert`, `_reLayout` (the caret's scroll-follow layout step), `_settleScrollFollow` (the in-place
  drain from the prior arc — unaffected by this change, but read it to see how the caret is enqueued + drained).
  `src/WorldWdgt.coffee` — `_recalculateLayoutsBody` (the until-loop + `recalcIterationsCap` → `RECALC_NONCONVERGENCE`),
  `_recalculatingLayouts`, `_inLayoutMutation`, `auditUndeclaredEndOfCycle`, `auditPaintTimeLayoutScheduling`.
- **The lint (must stay green / update in lockstep):** `buildSystem/check-layering.js` — rules **[E]** (immediate mutator
  must not call `_invalidateLayout`), **[F]** (off-settle synchronous apply), **[G]** (low-level must not call a
  structural self-settling wrapper), `isLowLevel`, `isImmediateMutator`, the `# layout-apply-sanctioned` /
  `# nosettle-sanctioned` markers. Read the header block — it documents the schedule/apply layering this change touches.
- **The gates:** `Fizzygum-tests/scripts/end-of-cycle-audit/run-capstone-gate.sh` (careless-push = 0),
  `Fizzygum-tests/scripts/paint-readonly-audit/run-paint-readonly-gate.sh` (paint schedules = 0),
  `Fizzygum-tests/scripts/torture-headless.js` (nondeterminism + RECALC_NONCONVERGENCE).
- **Prior-arc records (read for context):** memory `fizzygum-paint-readonly-caret-resync` (the caret in-place-settle +
  Option C arcs — the `/btw` worry that spawned this plan is recorded there; commits Fizzygum `20586db1` / `d60a0710`),
  memory `fizzygum-end-of-cycle-flush-drawdown` (the capstone gate + the careless-push audit mechanism),
  memory `fizzygum-deferred-layout-plan` (the deferred-layout model: in-pass enqueue vs off-pass invalidate; the
  `_reFitContainer` seam), memory `fizzygum-layering-naming-tiers` (the `NoSettle`/tier naming; rules [E]/[F]/[G]).
  `Fizzygum/docs/deferred-layout-OVERVIEW.md` §11 (the immediate-mutator seam + the determinism-exempt in-pass enqueue).
  `Fizzygum-tests/DETERMINISM.md` (byte-exact contract + convergence bug-class case law).

---

**One honest caveat (carry into the new session):** this relaxes a guard that exists to protect until-loop convergence.
§2's argument that it is inapplicable to inert+free-floating receivers is sound *as the code stands today* (raw-only
geometry, no climb, content-bounds exclusion), but the proof rests on those invariants holding — re-verify them (§4.1) at
execution time, and lean hard on the dpr2 torture's `RECALC_NONCONVERGENCE` check (§5.4) as the empirical backstop. If
the lint fights back or torture finds any non-convergence, **leave the status quo** — the three-way split is correct and
documented today; the only thing lost by not doing this is one open-coded push and a bit of folklore.
