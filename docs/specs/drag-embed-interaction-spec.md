# Drag-embed interaction spec — replacing the two-toggle window-drop gate with dwell-to-arm

**Status: ✅ IMPLEMENTED (2026-07-06).** Built across the drag-embed arc's Phases 1–3, 3.5, 5, and 6 (Phase 4
rejected); per-phase landed status + commit hashes live in `docs/archive/drag-embed-implementation-plan.md`. Every
file:line anchor below was verified at implementation time, but **line numbers drift — grep the named symbol.**

**Deviations from this spec, as-built** (all owner-approved during execution; the plan's per-phase LANDED boxes
carry the detail):
- **§8 land-and-offer pill + §9 teaching hint — DROPPED** (owner-rejected 2026-07-06, Phase 4: too intrusive).
  A reluctant, or merely unarmed, release now just lands the payload on the world at the release point (§7). So
  decision 7's "one interactable element (the pill)" is moot — EVERY drag visual is now an ephemeral.
- **Internal/external SWITCH BUTTON deleted; eject button never built; pencil↔eye glyph swap deferred** (Phase 5,
  slimmed). A window's internal-ness is DERIVED from its parentage (`FrameWdgt.isInternal`) and the whole-window
  skin (body + title bar) is re-derived on every re-parenting; the manual switch is deleted. Drag-OUT already
  ejects a nested window (Phase 3's rule flip), so there is no eject button. The pencil↔eye edit-mode glyph was
  cut from this arc and extracted to its own owner-requested follow-up plan (separate, not part of this spec).
  §10 is the as-built title-bar record.
- **Decision 4 (dashboards default edit-ON) — REVERSED** (owner "keep view-locked" 2026-07-06): `SampleDashboardApp`
  stays view-locked at construction. Only the payload-class dwell rule changed, not app editing defaults.
- **§8's OFFSET_LANDING_PX landing offset — DROPPED** with the pill: the payload lands normally where released.
- **§6 charge mechanic — REVISED** (2026-07-06, the single pre-authorized reframe): the per-event GAP-CREDIT
  accumulator was FALSIFIED by the S2 hardware spike → replaced by a pure elapsed-event-time decision + a
  clock-pattern ring feedback (revision record in §6). Falsification budget: 1 of 2 spent.

Owner decisions baked in (2026-07-05; **items 4 and 7 were later revised — see the deviations above**):

1. **Anchor point for "over" = the cursor** (not the dragged window's center/bounds).
2. **Drag-OUT of view-mode containers stays blocked forever** ("solid to read" is a permanent promise; this
   spec changes drop-IN only).
3. **Nesting depth: uniform rule at all depths** — recommended and specified in §5/§6 (innermost receptive
   candidate, per-candidate dwell, no depth-dependent timings).
4. **Dashboards default to edit-ON at construction** (slides/documents keep their current defaults).
5. **§4's payload-class rule is APPROVED (owner sign-off 2026-07-05)** — dwell applies only to *window*
   payloads; plain-widget drops into editable containers stay instant, as today. (Rationale: without it, every
   paragraph/snippet drop in the Docs Maker authoring loop would inherit the dwell friction, and ~6 existing
   SystemTests would change semantics for no protective gain.)
6. **Wheel-scrolling a destination mid-drag is supported and composes with the dwell** — owner-raised
   question, answered in §6.1. (§6's charge mechanic was REVISED 2026-07-06 after the S2 hardware spike:
   elapsed event-time decision + clock-pattern ring feedback; see the revision record in §6.)
7. **All non-interactable visuals ride the EPHEMERAL overlay system** (owner direction 2026-07-06) — the
   existing declare-and-reconcile highlighting/pinouting mechanism (§2 receipts, §11 per-element mapping).
   The one interactable element (the §8 pill) is explicitly NOT an ephemeral.

---

## §0 — Orientation (self-contained)

**Fizzygum** = CoffeeScript GUI framework on one `<canvas>` (Morphic.js descendant); "web operating system"
with windows, desktop, drag-and-drop, live in-system editing. Umbrella `/Users/davidedellacasa/code/Fizzygum-all/`
(NOT a git repo) holds sibling repos `Fizzygum/` (source, ~470 `.coffee`), `Fizzygum-tests/` (~180 byte-exact
screenshot macro SystemTests), `Fizzygum-builds/` (generated — never edit). `nil` == `undefined`; one class per
file; no imports (every class a global). Commands via `./fg` from the umbrella root: `./fg build` · `./fg suite`
· `./fg gauntlet` (build + dpr1 + dpr2 + webkit + apps + gates) · `./fg test <name>`. Determinism doctrine:
render/layout/input must be a pure function of the **event stream** — never wall-clock (`Fizzygum-tests/DETERMINISM.md`).

## §1 — Problem, goals, non-goals

**Problem.** Embedding a window (e.g. a plot) into a container (e.g. a slide) currently requires TWO persistent
toggles to be pre-set on two different objects: the dragged window must be "internal" (droppable — the
internal/external switch, upper right of its title bar) AND the destination's content must be in edit mode (the
pencil). Both controls are cryptic, their conjunction is invisible, and **refusal is indistinguishable from
success**: a refused drop lands on the world *on top of* the target, looking embedded
(`SystemTest_macroLockedDocumentRejectsDrop` asserts exactly this). Yet both protections guard real things:
windows are moved constantly and must not nest by accident; view mode is the "reading is safe" promise.

**Goals.** (a) Express embed-intent **in the gesture** (a quasimode held during the drag), not as standing
configuration; (b) make the would-be outcome visible *before* release; (c) make refusal visibly different from
success; (d) teach the destination's edit/view gate in context; (e) keep the common gesture — moving a window —
exactly as cheap as today; (f) stay deterministic (event-time, byte-exact screenshots).

**Non-goals.** Drag-out of view-mode containers (owner decision 2: stays blocked — no long-press-to-tear).
Ghost/preview insertion (feedforward rendering of the embedded result) — good future work, out of scope.
Menu-verb channels ("embed into…") — compatible, separate work. No global world edit mode.

**Design principle** (the one rule everything below instantiates): **permission scales with demonstrated intent
strength.** Flick-drag < drag-release < drag-linger-release < explicit click on a pill/menu — matched against
how much the destination has to lose.

## §2 — Current-mechanism receipts (verify anchors by grepping the symbol)

| Mechanism | Where (2026-07-05) |
|---|---|
| Self drop-gate: `wantsToBeDropped()` → `@internal`; base default true | `FrameWdgt.coffee:256` · `Widget.coffee:2910` |
| Drop routing: if `!wantsToBeDropped()` → target forced to `world`, else climb | `ActivePointerWdgt.drop`, `ActivePointerWdgt.coffee:247-287` |
| Target resolution: cursor hit-test then parent-climb until `wantsDropOfChild` | `ActivePointerWdgt.dropTargetFor` `:154-158`, `topWdgtUnderPointer` `:87-110` |
| Accept predicate: `wantsDropOfChild` → `@_acceptsDrops` (default false; `enableDrops`/`disableDrops`) | `Widget.coffee:2904-2917` |
| Edit/view toggle: pencil → window relay → content `dragsDropsAndEditingEnabled` | `EditIconButtonWdgt` → `FrameBarWdgt` → `FrameWdgt.editButtonInBarPressed` → the content's base `Widget.editButtonPressedFromFrameBar` (the fused editor middle layer dissolved — Frame-model §5.B/§5.D) |
| Edit-off cascades a drops-lock into the citizen's container + hides the docked toolbar | `StretchableWidgetContainerWdgt._disableDragsDropsAndEditingNoSettle` → `FrameWdgt.showViewModeInBar` (toolbar-slot collapse) |
| Pencil state shown by color only | `FrameWdgt.makePencilYellow/makePencilClear` `:536-548` |
| Internal/external switch + `makeInternal`/`makeExternal` (re-skin, unlock, reparent to world) | `FrameWdgt.coffee:177-202, 525-534` |
| Windows accept drops only while EMPTY ("Drop a widget in here" placeholder) | `FrameWdgt.coffee:398` (enable) · `:421` (disable on child landed) · `FrameContentsPlaceholderText` |
| Drag-hover hooks exist, dispatched every move, **implemented by nobody** | `dispatchEventsFollowingMouseMove`, `ActivePointerWdgt.coffee:933-963` (`mouseEnterfloatDragging`/`mouseLeavefloatDragging`) |
| Grab origin recorded at grab (return-anchor candidate) | `ActivePointerWdgt.coffee:196` (`grabOrigin = aWdgt.situation()`) |
| Existing dwell precedents: 500ms autoscroll (wall-clock — the documented anomaly, do NOT copy) · 300ms multi-click (event-time — the template) | `ScrollPanelWdgt.coffee:709` · `doubleClickWindowMs`, `ActivePointerWdgt.coffee:28` |
| Drag threshold 7px (also the linger radius we reuse) | `PreferencesAndSettings.coffee:54` (`grabDragThreshold`) |
| Wheel routing: to first `wheel`-implementing widget on the climb from the cursor hit — **no drag gate**, so wheel-during-drag already scrolls the destination today (the carried widget rides on the hand, outside the world tree, and cannot swallow it) | `ActivePointerWdgt.processWheel` `:721-726` |
| Wheel scroll-chaining: an inner panel at its limit escalates the wheel to an outer scroll panel (can move the candidate away from under a stationary cursor) | `ScrollPanelWdgt.wheel`, `ScrollPanelWdgt.coffee:812-823` (`escalateEvent 'wheel'`) |
| **EPHEMERALS** (owner's term; in code: the highlighting/pinouting overlay system): declarative sets `world.widgetsToBeHighlighted`/`widgetsToBePinouted`, reconciled ONCE PER CYCLE just before paint — diff-based create / reposition-if-target-bounds-changed / destroy-when-undeclared | `WorldWdgt.addHighlightingWidgets` `:1272-1292` + `addPinoutingWidgets` `:1245-1269` (homepage-EXCLUDED, debug-only), called at `WorldWdgt.coffee:1442-1444` immediately before `updateBroken()` |
| Ephemeral properties: hit-test-EXCLUDED via marker predicates (→ non-interactable, click-through, can never steal mouseEnter/drops); shadow-free (`skipsAddShadowManagement -> true` — "not anything material"); world children added last (always on top); lifecycle wholly reconciler-owned | `ActivePointerWdgt.coffee:105-106` (`!m.wdgtThisWdgtIsHighlighting?`/`!m.wdgtThisWdgtIsPinouting?`) · `HighlighterWdgt.coffee:21-26` |
| Producer API precedent: declare/undeclare only — `turnOnHighlight`/`turnOffHighlight` mutate the desired set, nothing touches the overlay directly (menu "represents a widget" hover-highlight is the existing consumer) | `Widget.coffee:1845-1855` · `MenuItemWdgt.coffee:6` |
| Text-ephemeral precedent: the pinout readout is a `StringWdgt` overlay anchored at `target.right()+10, top()` | `WorldWdgt.coffee:1261-1267` |

## §3 — The model in one paragraph

Destinations alone decide whether a drop may nest (the internal/external *source-side* precondition is
deleted; `@internal` becomes derived state = "am I currently nested?"). Destinations fall into four
**receptivity tiers** (§4). The **payload class** decides whether arming friction applies: a *window* payload
must be **armed by lingering** (~450ms within a 7px radius) over the candidate before a release embeds; a
*plain-widget* payload embeds instantly into any receptive destination, exactly as today. While dragging, the
live candidate is continuously resolved (cursor anchor, innermost receptive — §5) and highlighted; the armed
state is loud and labelled ("Drop to insert into '<title>'"). View-mode destinations never accept mid-drag:
they show a lock cue, and a release near them lands the payload visibly OFFSET with a one-click
**land-and-offer pill** ("Insert" / "Edit & insert") so the intent completes without abort-toggle-redrag.

## §4 — Payload classes × destination tiers

**Payload classes.**
- **Window class** (deliberate-embed): any `FrameWdgt` (and subclasses). Protocol: a new predicate on Widget,
  suggested `requiresDeliberateEmbedding()` — base returns false, `FrameWdgt` overrides true. (Do NOT key off
  `isFrame` at call sites — capability, not type test, per the type-test-elimination convention.)
- **Plain class**: everything else (icons, text snippets, composites, sub-menus, clocks…). Behavior unchanged
  from today in every accept case.

**Destination tiers** (a classification of the widget that would win the §5 climb):

| Tier | Members | Window payload | Plain payload | Visual while hovered (drag in progress) |
|---|---|---|---|---|
| **Eager** | empty `FrameWdgt` (placeholder showing), `SimpleDropletWdgt`, `LayoutElementAdderOrDropletWdgt` | dwell-to-arm (no exception — empty windows are exactly where accidental window-nesting happens) | instant accept | bright invite highlight, immediate |
| **Willing** | edit-mode framed-citizen containers (slides, dashboards, patch, the Drawings Maker `ImageWdgt` — their `StretchableWidgetContainerWdgt` payload), edit-mode `DocumentWdgt` scroll panel, edit-mode `PanelWdgt`/stacks/scroll panels (anything whose `wantsDropOfChild` is true) | dwell-to-arm | instant accept | candidate highlight; ring while charging (window payload only) |
| **Reluctant** | the same widgets in VIEW mode (`providesAmenitiesForEditing` true, `dragsDropsAndEditingEnabled` false) | never accepts mid-drag → lock cue; land-and-offer on release (§8) | same | neutral outline + lock badge + eye pulses amber |
| **Refusing** | inspector panes, plot glass, full windows' chrome, anything `_acceptsDrops` false without editing amenities | inert (no cue) | inert | none |

Tier membership is *computed*, not a new stored flag: eager/willing = `wantsDropOfChild` true (the existing
predicate); reluctant = the §5 climb found no acceptor but passed a widget with
`providesAmenitiesForEditing and !dragsDropsAndEditingEnabled`; refusing = neither.

**Owner decision 4 lands here:** dashboards default to edit-ON. Concretely: the dashboard construction path
stops calling `disableDragsDropsAndEditing()` at build time (grep `SampleDashboardApp` — the call is in its
window-assembly tail, ~`SampleDashboardApp.coffee:113-120`), while `SampleSlideApp.coffee:73` and
`InfoDocs._buildInfoDocNextTo` (the shared info-doc builder) keep theirs (slides/docs still open in view mode).

## §5 — Candidate resolution (owner decisions 1 + 3)

Runs on every pointer move while float-dragging (hook: `dispatchEventsFollowingMouseMove` — the existing,
currently-unimplemented `mouseEnterfloatDragging`/`mouseLeavefloatDragging` dispatch site; the resolver is the
same climb `dropTargetFor` does at release, so move-time preview and release-time outcome CANNOT disagree).

- **Anchor = the cursor point** (decision 1). The hit-test is `topWdgtUnderPointer()`; the dragged widget's own
  bounds/center are irrelevant. A huge window dragged by its corner embeds only if the *cursor* is over the
  destination — predictable, matches every OS; the highlight communicates it.
- **Candidate = the innermost receptive widget on the parent-climb from the hit** (decision 3, uniform at all
  depths): climb until `wantsDropOfChild(payload)` is true, exactly as `dropTargetFor` — with TWO additions:
  1. **The world is never a "candidate"** for embed UX. If the climb reaches `world`, there is no candidate: no
     highlight, no dwell, release lands on the desktop (today's behavior, untouched).
  2. The climb also records the innermost **reluctant** widget it passed (for the lock cue + §8 pill). If an
     acceptor exists BELOW a reluctant ancestor, the acceptor wins and the reluctant ancestor is ignored.
- **Per-candidate dwell; candidate change = full reset.** The charge accumulator, armed state, and all visuals
  belong to the current candidate. When the resolved candidate changes (deeper container entered, target left,
  view/edit differs), charge drops to zero and arming restarts. No depth-scaled timings, no dwell-to-descend,
  no escalation-outward — one rule everywhere, learnable in one encounter. Transiently crossing a nested willing
  widget while repositioning inside an armed slide WILL disarm; accepted simplicity — the always-visible
  highlight + label make the current candidate unambiguous, which is the actual safety property.
- Special-case preserved: `BasementOpenerWdgt` keeps its `wantsToBeDropped`-style world-forcing; the base
  `wantsToBeDropped` protocol survives for such widgets even though `FrameWdgt` stops overriding it.

## §6 — State machine + timing constants (window payloads; plain payloads skip CHARGING and are armed on entry)

States, per drag: `FREE` (no candidate) → `CANDIDATE` (over an eager/willing target, charge 0) →
`CHARGING` (pointer lingering: stays within LINGER_RADIUS_PX of the linger origin) → `ARMED` →
(release = embed). Parallel state `LOCKED_CUE` while the resolution yields only a reluctant widget.

Transitions:
- `CANDIDATE → CHARGING`: immediately (linger origin = entry pointer position + THAT event's timestamp).
- **ARMED decision = pure event-time ELAPSED: `event.time − lingerOrigin.time ≥ DWELL_ARM_MS`,** evaluated at
  EVERY input event over the candidate — pointer moves within the radius, wheel events, and the RELEASE
  itself. No accumulator, no per-event credit. Any pointer-move event landing beyond LINGER_RADIUS_PX of the
  origin RE-ANCHORS the origin (position + timestamp), so a transit across a big target never arms no matter
  how slow — arming requires one unbroken ≥450ms stay inside a 7px circle, and between events the pointer
  cannot move, so per-event checking is exact. (Never wall-clock in the decision — the `doubleClickWindowMs`
  pattern; the 500ms autoscroll `Date.now()` remains the one anomaly, not copied.)
  - A genuinely FROZEN hold arms correctly: the release event sees the full elapsed time. This is the
    S2-VALIDATED case — spike telemetry (plan §2) measured real still-holds of 3644/3762ms purely from event
    timestamps, while proving the mouse emits ZERO move events when truly still.
  - ⚠ REVISION RECORD (2026-07-06): v1 of this section specced a per-event GAP-CREDIT accumulator
    (`min(gap,100ms)` per event), premised on hand-tremor event streams during "still" hovers. The S2
    hardware spike FALSIFIED the premise (zero events while still → credit freezes; release top-up made
    outcomes inconsistent). This elapsed-time decision + clock-driven feedback (next bullet) is the single
    pre-authorized reframe; the falsified accumulator is not to be re-attempted.
- **Ring feedback is PRESENTATION, driven by the established time-animated-widget pattern** (the analog
  clock precedent, `src/apps/AnalogClockWdgt.coffee:99-108`): the charging-ring ephemeral steps on
  `world.steppingWdgts`, filling over wall time from the linger origin (quantized to RING_STEPS), and under
  `Automator.animationsPacingControl` follows the harness's virtual pacing exactly as live clocks already do
  in byte-exact tests. The decision NEVER reads ring state; production users always SEE the ring fill during
  a sincere hold (cycles never stop), so an armed release is never a surprise — the loud-armed-state promise
  is kept by feedback, not by crippling the decision rule.
- `CHARGING → ARMED`: the elapsed predicate above, evaluated per event; the ARMED state then LATCHES while
  the cursor stays within the same candidate's bounds (aiming movement no longer re-anchors — see below).
- **`ARMED` persists while the cursor stays within the SAME candidate's bounds** — the linger requirement
  applies only to arming; after arming, the user must be free to move to aim the drop point. Leaving the
  candidate (or candidate change) → instant disarm → `FREE`/`CANDIDATE` for the new resolution.
- Any state, release: see §7. Esc during drag: cancel to `grabOrigin` (VERIFY current Esc-cancel behavior at
  implementation; `grabOrigin` is recorded at `ActivePointerWdgt.coffee:196`).

| Constant | Value | Rationale |
|---|---|---|
| `DWELL_ARM_MS` | 450 | Snappy end of the spring-loaded-folder range; consistent with the codebase's two 500ms dwells |
| `LINGER_RADIUS_PX` | 7 | = `grabDragThreshold` — reuse the constant, one notion of "stationary" |
| `RING_STEPS` | 5 | quantized progress (90ms/step) — discrete steps; ring animates via stepping (clock pattern), decision is event-time |
| `OFFSET_LANDING_PX` | 24 | §8 refused-drop offset — big enough to read as "outside", small enough to stay local |

Optional refinement, banked not specced: a size sanity check (window payload ≤ ~⅔ of candidate area to arm).
Deterministic and cheap; add only if real-world accidents demand it.

### §6.1 — Wheel-scrolling the destination mid-drag (owner decision 6)

Wheel-during-drag **already works today**: `processWheel` routes to the first `wheel`-implementing widget on
the climb from the cursor hit with no drag gate, and the carried widget rides on the hand outside the world
tree, so it cannot intercept (§2 receipts). This spec KEEPS it and promotes it to the first-class way of
reaching an off-view insertion point — for window payloads it is the ONLY scroll channel, since §12 gates
edge-auto-scroll OFF for them (explicit intent replaces implicit surprise). Rules:

1. **Wheel never resets the linger.** The linger radius tests *pointer* position only; wheel/trackpad
   scrolling doesn't move the pointer, so this falls out naturally — stated here so nobody ever "hardens" the
   reset to any-input.
2. **Wheel events are evaluation points for the elapsed-time decision** (§6): they don't move the pointer,
   so the linger origin stands and elapsed keeps growing through a scroll — a user who scrolls to find the
   spot typically arrives already armed, and each wheel event lets the logical armed bit flip visibly
   mid-scroll. (Deliberately NOT instant-arm-on-wheel: trackpad momentum deltas can arrive un-aimed during
   transit; banked as a possible accelerator, like the modifier key.)
3. **Candidate identity governs, re-resolved per event, and scrolling usually preserves it.** Content sliding
   under the stationary cursor changes what the hit-test returns, but the climb resolves to the same
   container → charge/armed persist. Two genuine candidate changes, both handled by the general
   reset-on-candidate-change rule (the highlight announces them):
   - a *nested* receptive container scrolls under the cursor → candidate switches to it, charge resets;
   - **scroll-chaining** (inner panel at limit escalates to an outer panel, §2) physically moves the candidate
     away from under the cursor → disarm. Correct: the thing being aimed at literally left.
4. **View-mode (reluctant) destinations still scroll.** View mode locks *editing*, not reading; wheel over
   them behaves as today, with the lock cue simply staying up.
5. In flowing documents the insertion point at release follows the cursor position within the (now scrolled)
   flow — existing behavior, nothing new needed.

## §7 — Release-outcome matrix (window payload)

| Release while… | Outcome |
|---|---|
| `FREE` (no candidate / over world) | Lands on world at release point. Today's move-over, byte-for-byte the goal. |
| `CANDIDATE`/`CHARGING` (not yet armed) | Lands on world at release point (it IS the common move-over — no bounce, no scold). **EXCEPTION — sticky re-embed (owner-approved 2026-07-06, plan Phase 3.5):** if the resolved container IS the payload's CURRENT parent (a nested window merely being repositioned within its own container), it STAYS nested with no dwell — only embedding into a NEW container requires arming. |
| `ARMED` | Embeds: same call sequence as today's accepted drop (`_beforeChildDropped` → `add` → settle → `_reactToChildDropped`/`_reactToBeingDropped`, `ActivePointerWdgt.drop`). |
| `LOCKED_CUE` (over reluctant only) | Lands on world at the release point — a plain move-over, NO offset. (An earlier draft offset the landing + offered a pill, §8; both were DROPPED 2026-07-06 — the payload just lands normally where released.) |

Plain payloads: unchanged accept behavior (instant embed over eager/willing); over a reluctant (view-mode)
container they land on the world at the release point, same as a window (the container refuses the drop, so the
payload stays on the desktop where it was released).

## §8 — The land-and-offer pill (reluctant destinations) — ❌ DROPPED 2026-07-06

> **NOT IMPLEMENTED / owner-rejected 2026-07-06.** The pill was built and working (a MenuWdgt transient with
> Insert / Edit & insert) but the owner found the popup too intrusive. A reluctant drop now simply lands the
> payload on the world at the release point (§7). The design below is kept as a record, not a spec to build.

A small transient widget placed adjacent to the landed payload (world child, above it):

> **"NYC: traffic" is in view mode** — [ **Insert** ] [ ✎ **Edit & insert** ]

- **Insert**: embeds programmatically (same reaction sequence as an accepted drop); destination STAYS in view
  mode. (Programmatic `add` does not consult `wantsDropOfChild` — only the hand's climb does — so this is
  mechanically clean; VERIFY against the slide container's add path at implementation.)
- **Edit & insert**: calls the content's `enableDragsDropsAndEditing` (pencil→eye flips, tools palette appears),
  then embeds. Leaves the destination open for follow-up arranging.
- **Dismissal is event-driven, never timed** (determinism): next pointer-down outside the pill, Esc, or
  grabbing the landed widget again. No auto-fade timeout.
- The pill is **NOT an ephemeral** (its buttons must receive clicks, so it CANNOT be hit-test-excluded — an
  earlier draft of this spec got that wrong). It is a real transient widget of the MENU family, which already
  owns the dismiss-on-outside-click behavior. It IS excluded from world-snapshot serialization (follow
  whatever transient-exclusion pattern menus/tooltips use — VERIFY in `src/serialization/`).

This replaces "abort drag → find pencil → click → re-drag" with one click, without ever letting a timer pierce
the view-mode promise: modifying a view-mode container always requires an explicit click.

## §9 — Unarmed-release teaching hint — ❌ DROPPED 2026-07-06

> **NOT IMPLEMENTED / owner-rejected 2026-07-06.** The hint was built and working (a click-through text
> ephemeral) but it fired on EVERY unarmed window release over a container — far too often. An unarmed release
> now just lands on the world (§7) with no hint. The design below is kept as a record, not a spec to build.

Releasing a window payload over a willing candidate *before* armed is ambiguous (move-over vs. failed embed
attempt by someone who doesn't know the dwell). The drop behaves as move-over (§7) — but show a small
non-blocking hint near the landing: *"On desktop — to insert into 'NYC: traffic', hold still over it while
dragging."* Same event-driven dismissal as the pill (next pointer-down), no timeout, purely informational, no
buttons. This is the discoverability backstop: the mechanic explains itself at the exact moment of failed
intent, at zero cost to deliberate move-over users (who click next and never parse it).

## §10 — Title-bar changes (Phase 5 as-built — SLIMMED)

The internal/external switch button is DELETED outright (not repurposed). A window's internal-ness is now
DERIVED from parentage (`FrameWdgt.isInternal` = "am I nested" = my parent is neither the world nor the hand),
and the whole-window skin (body appearance + title-bar appearance/colors) FOLLOWS it automatically on every
re-parenting (`_reactToBeingAdded` re-applies it, skipping the transient pick-up by the hand): drag a window into
a container → flat internal skin; out to the desktop → boxy external skin. So the manual toggle has no job left.
(A window built `internal=true` and then nested via `container.add` — a dashboard/document plot — ends up
byte-identical to the old stored-flag path, because the full skin re-derives to internal on that add.)

1. **Internal/external switch → DELETED.** `wantsToBeDropped` (the `@internal` self-gate), `makeInternal`,
   `makeExternal`, `createAndAddInternalExternalSwitchButton`, the `internalExternalSwitchButton` field, the
   `alwaysShowInternalExternalButton` handling, and the whole internal/external icon family (the two icon-button
   classes + their icon widgets + their appearances) are all removed, plus the now-dead
   `KeepsRatioWhenInVerticalStackMixin.holderWindowMadeIntoExternal`. **No eject button:** dragging a nested
   window OUT to the desktop already ejects it (Phase 3's rule flip — an unarmed release over the world detaches;
   sticky re-embed only keeps it nested when released over its own container). The `internal` /
   `alwaysShowInternalExternalButton` constructor args (4th/5th at every `new FrameWdgt …, true, true` site)
   become INERT (retirement is a deferred sweep); deserialization ignores any stored `internal`.
2. **Edit button (pencil) unchanged in kind, moved in place.** NO pencil↔eye glyph swap (owner cut it 2026-07-06);
   `makePencilYellow`/`makePencilClear` stay (yellow = editing, clear = view). With the switch gone, the pencil
   simply takes the now-vacant rightmost title-bar slot (the label extends by one slot; the pencil's collapse
   threshold retightens to match).
3. Not done: the optional edit-mode title-bar tint (deferred).

## §11 — Visuals: nearly everything is an EPHEMERAL (owner direction 2026-07-06)

**The delivery mechanism for all non-interactable visuals is the existing ephemeral/overlay system (§2
receipts): declare desired state; the per-cycle reconciler (runs after events + layout flush + hover re-sync,
immediately before paint) creates/moves/destroys the overlay widgets.** Nothing is baked into any target's
back-buffer (the unified-shadow doctrine holds for free — `skipsAddShadowManagement` is literally its
expression here), nothing can intercept input (hit-test-excluded by construction), and no widget being
highlighted/decorated carries any state about its own decoration. Per element:

| Element | Mechanism | Spec |
|---|---|---|
| Candidate highlight | **EPHEMERAL — the existing `HighlighterWdgt` flow, almost verbatim** (`widgetsToBeHighlighted.add candidate` on resolution, remove on candidate change) | 2px (logical) rounded outline just inside the candidate's `clippedThroughBounds`; accent tone (suggest pencil-yellow family `248,188,58`, reduced alpha for willing / full for eager). Needs a STYLE CHANNEL the current mechanism lacks (today: hardcoded blue fill, alpha 50) — either per-target style descriptors (Set → Map target→style) or distinct ephemeral declaration sets per style; owner/implementation choice |
| Charging ring (the radial timeout) | **EPHEMERAL — new cursor-anchored type, and a STEPPING one** (the analog-clock pattern, `AnalogClockWdgt.coffee:99-108`): fills over wall time from the linger origin in production; under `Automator.animationsPacingControl` follows the harness's virtual pacing like the clocks already do in byte-exact tests. Reconciler positions it at hand + (16,16); repaints only on quantized step change | Radius ~9px; RING_STEPS discrete segments; PRESENTATION ONLY — the armed decision is §6's event-time elapsed check and never reads ring state |
| Armed label | **EPHEMERAL — text type** (the pinout `StringWdgt` readout is the in-code precedent) | Near cursor: "Drop to insert into '<title>'" (title truncated ~24 chars) |
| Lock badge + eye pulse (reluctant) | **EPHEMERAL(s) anchored to the destination's title-bar / eye-button bounds** — deliberately NOT a state change of the real eye button: the pulse never leaks state into `FrameWdgt`/button rendering, and vanishes by undeclaration | Neutral gray outline on the destination + small lock badge at title-bar right; amber pulse over the eye button in 2 quantized steps |
| §9 teaching hint | **EPHEMERAL — text type.** Non-interactability is exactly right here: it is click-THROUGH (the next click acts on the world AND dismisses it — the pointer-down handler drops the declaration) | One line near the landing; no buttons, no timeout |
| §8 land-and-offer pill | **NOT an ephemeral — it has buttons.** Interactability violates the ephemeral definition; it is a real transient widget of the menu family (menus already own dismiss-on-outside-click) | See §8 |
| Refused-landing nudge | **Neither** — a transient movement of the real landed widget (2-frame quantized), not an overlay | OFFSET_LANDING_PX displacement (§7) |

Implementation note (when code opens up): the drag ephemerals are PRODUCT features — they must follow the
`addHighlightingWidgets` shipped path, NOT the homepage-excluded `addPinoutingWidgets` debug path.

## §12 — Engineering + determinism notes

- **Hook point**: candidate resolution + state machine live off `dispatchEventsFollowingMouseMove`
  (`ActivePointerWdgt.coffee:933-963`); the hit-test already runs there every move, so the added cost is the
  short parent-climb. `drop()` (`:247`) loses the `wantsToBeDropped`→world forcing branch for windows (keeps it
  for `BasementOpenerWdgt`-style widgets) and gains the ARMED/unarmed branch.
- **Sticky re-embed (§7 exception, Phase 3.5): identify the window's OWN container by the pre-grab parent, not
  the live parent.** While float-dragging, the payload's `.parent` is the HAND (`grab()` reparents it to the
  hand via `@add`), so `wdgtToDrop.parent` at drop time is useless for "is this the same container it came
  from?". Instead read **`@grabOrigin.origin`** — `situation()` records `{origin: @parent, …}` at grab time
  (`ActivePointerWdgt.coffee`, in `grab()` just BEFORE `@add aWdgt`), so it is exactly the PRE-grab container.
  In the window / not-armed branch: `stickyTarget = @dropTargetFor wdgtToDrop` (the same climb the preview and
  the armed branch use); if `stickyTarget isnt world and stickyTarget is @grabOrigin.origin`, nest there (no
  dwell, no offset) instead of defaulting to world. This turned `grabOrigin` from write-only dead state into a
  live read; it is set on every hand-grab path (direct `grab()`, and `pickUp()` → `grab()`) and overwritten by
  each grab, so it is always the current payload's origin at `drop()`. `world.hand` is not in `world.children`,
  so the dragged payload is excluded from `topWdgtUnderPointer`/`dropTargetFor` — the climb resolves to the real
  container under the cursor, never the payload itself.
- **Ephemerals: separation of concerns + a free synergy.** The state machine (§6) only mutates declarative
  state (which candidate, which charge step, armed?, lock cue?); the reconciler turns state into pixels once
  per cycle pre-paint. Because the reconciler already repositions overlays when the target's paint bounds
  change (`hasMaybeChangedPaintBounds` → re-apply `clippedThroughBounds`), the candidate highlight tracks the
  destination through §6.1 wheel-scrolling and through any layout settle FOR FREE — no per-event visual
  bookkeeping. And since ephemerals are hit-test-excluded, no overlay can ever perturb candidate resolution,
  `mouseEnter` dispatch, or the drop climb (no feedback loops between feedback and input).
- **Proposed unification (small refactor, when code opens up): an `isEphemeral` capability** (base class or
  mixin adopting the owner's term). Today `topWdgtUnderPointer` enumerates per-type marker predicates
  (`wdgtThisWdgtIsHighlighting?` / `wdgtThisWdgtIsPinouting?`, `ActivePointerWdgt.coffee:105-106`); this spec
  adds ~4 new ephemeral types (ring, label, badge, hint), which would grow that list per type. One capability
  check consolidates: hit-test exclusion + `skipsAddShadowManagement` + serialization exclusion + "reconciler-
  owned lifecycle" in one place. (Capability, not `instanceof` — per the type-test-elimination convention.)
- **Event-time decision, clock-driven feedback**: the arming DECISION derives only from input-event
  timestamps (macro tests synthesize them, so arm/re-anchor/disarm are exactly testable at `speed=fastest`
  with speed-invariant references); the ring/pulse ANIMATIONS ride the stepping + `animationsPacingControl`
  pattern that already keeps live clocks byte-exact in the suite.
- **Auto-scroll interaction** (behavior change to gate): with windows always droppable,
  `maybeStartAutoScrollForDraggedWidget` would begin edge-scrolling scroll panels during window drags (today
  external windows skip it — `ActivePointerWdgt.coffee:957`). Gate edge-auto-scroll OFF for window payloads
  (dragging a window across a big scroll panel must not scroll it).
- **Serialization/migration**: `@internal` is currently real state (constructor arg, presumably serialized).
  On load of old snapshots: ignore the stored value, derive from parentage. VERIFY against
  `docs/architecture/serialization-duplication-reference.md` for how retired props are handled.
- **Homepage build**: all of this is product code (no `if Automator?` guards needed except in any test-only
  instrumentation).

## §13 — Behavior-change + SystemTest inventory

**Semantics CHANGED (tests need rework, not just recapture):**
- `macroInternalVsExternalWindowDrop` — the internal/external distinction disappears; rewrite as the new pair:
  armed-drop nests vs. unarmed-drop lands on world (same "move the panel, see who travels" assertion style).
- `macroLockedDocumentRejectsDrop` — refused drop now lands OFFSET + pill; extend to click **Insert** and
  assert the embed.
- `macroInternalWindowDroppedIntoWindowFits`, `macroWindowWithAClockInAWindowConstructionTwo`,
  `macroResizeWindowContainingInternalWindow`, `macroClosingInnerWindowKeepsOuter` — wherever the macro drops a
  window, insert a linger (synthesized stationary time ≥ DWELL_ARM_MS) before release. VERIFY which of these
  construct programmatically vs. by drop.
- Sample apps: dashboard opens edit-ON (pixel change: tools palette visible → recapture + intent update).

**Semantics UNCHANGED (plain payloads — the payload-class rule is what protects these):**
`macroIconDroppedIntoDocumentFlows`, `macroDocumentPreservesDroppedWidgetSizes`,
`macroConstrainingStackForcesDroppedWidgetsToFullWidth`, `macroCompositeDragsAsUnitIntoScrollPanel`,
`macroSubMenuDroppedIntoPanelPinsItself`, `macroInspectorRejectsDrops`.

**NEW macros — as-built status** (Phase 6 closeout, 2026-07-06):

- ✅ **AUTHORED** (spec name = actual `SystemTest_macro…` name): linger-arms-then-drop-embeds =
  `DragEmbedWindowLingerArms` · slow-transit-never-arms (= slow-transit-re-anchors-never-arms) =
  `DragEmbedWindowTransitNeverArms` · release-while-charging-lands-on-world =
  `DragEmbedReleaseWhileChargingLandsOnWorld` · armed-persists-while-aiming-within-candidate =
  `DragEmbedArmedPersistsWhileAiming` · candidate-change-resets = `DragEmbedCandidateChangeResets` ·
  still-hold-then-release-ARMS = `DragEmbedStillHoldReleaseArms` (Phase 6) ·
  window-drag-does-not-autoscroll-scrollpanel = `DragEmbedWindowDoesNotAutoscrollPanel` (Phase 6). Drag-OUT
  ejection (what the cut eject-button did) is covered by `DragEmbedRepositionNestedWindowStaysWithoutDwell`
  case B (Phase 3.5); the internal/external rework is `InternalVsExternalWindowDrop` (armed-nests vs
  unarmed-lands, Phase 3).
- ❌ **MOOT** (feature cut/rejected — nothing to author): view-mode-cue + pill-Insert · pill-Edit&insert
  (pencil→eye + tools palette) · eject-button-pops-out-nested-window · dashboard-edit-on · the "+hint" on
  release-while-charging. (§8/§9 dropped; pencil↔eye / eject / switch cut in Phase 5; dashboards kept view-locked.)
- ⏸ **NOT AUTHORED — deliberate, documented** (not silent): **eager-empty-window-still-requires-dwell-for-window-
  payload** — skipped as a duplicate: its code path is identical to release-while-charging-lands-on-world (an
  unarmed window → sticky-fail → lands on world), differing only in the target widget's appearance (empty window
  vs panel), so it adds no mechanism coverage. **wheel-mid-drag-scrolls-destination-while-elapsed-grows** and
  **scroll-chaining-mid-drag-disarms** — deferred: the underlying wheel-during-drag behavior is pre-existing
  (§6.1 receipts, unchanged by this arc), and a byte-exact screenshot test needs heavy nested-panel /
  scroll-chaining fixtures with real determinism risk for low marginal assurance. Banked for a future session.

## §14 — Open items

**EXECUTION PLAN: `docs/archive/drag-embed-implementation-plan.md`** (2026-07-06) — spikes S1-S3 + Phases 1-6, fresh
anchor table verified on `b91cd9b5`.

- ~~NEEDS OWNER SIGN-OFF: the §4 payload-class rule~~ → **APPROVED 2026-07-05** (header decision 5). All
  design decisions are now owner-settled.
- VERIFY items CLOSED 2026-07-06 (receipts in the plan §1): **Esc-cancel of drags does NOT exist**
  (snap-back would be NEW functionality; out of scope, offset landing suffices — NOTE: `grabOrigin` WAS
  write-only dead state as of this verify, but Phase 3.5 now READS `grabOrigin.origin` for the sticky-re-embed
  parent check, §12; it is still not used for any Esc-cancel/snap-back); **the world serializer walks ALL world
  children as snapshot roots** → live ephemerals are NOT
  auto-excluded; the plan's Phase 1 adds explicit exclusion via the `isEphemeral` capability + witness probe.
- VERIFY items remaining (owned by plan phases): programmatic-add path into slide containers for the pill's
  Insert (Phase 4); which changed-tests construct vs. drop (spike S3); whether real-mouse hover event streams
  fill the gap-credit (spike S2 — THE critical empirical unknown, fallback pre-selected).
- Deferred, deliberately: ghost/preview insertion (feedforward); "embed into…" menu verb; modifier-key
  dwell-skip accelerator; the size sanity check (§6); long-press-to-tear (rejected for now by owner decision 2);
  retiring the `FrameWdgt` constructor's `internal`/`alwaysShowInternalExternalButton` args (follow-up sweep).
