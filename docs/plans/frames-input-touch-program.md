# Frames · input · touch — the program doc

**THIS IS A PROGRAM DOC, NOT A PLAN.** It has no phases and nothing to execute. It is the one
place that holds, for a family of four sibling plans: the **decision ledger** (owner rulings no
plan may re-litigate), the **sequencing** and its hard constraints, the **recapture policy**, and
the **tail ledger** (every deferred item from every arc, with a destination). Authored 2026-08-23
from a design session with the owner; facts verified against Fizzygum `8d9ff3e3` / tests
`466109712` (gauntlet 18/18 green). When the tail ledger is empty and every plan below is
archived, this doc moves to `docs/archive/` with an `INDEX.md` entry.

**STATUS BOX** (one line per arc; plans are authored JUST-IN-TIME — see §6)
- Plan 1 `frame-lifetime-and-docking-plan.md` — AUTHORED 2026-08-23, not started.
- Plan 2 Pointer Events — not authored (author when Plan 1 closes).
- Plan 3 visual wave — not authored (author when Plan 2 closes).
- Plan 4 gesture grammar + finger harness — not authored (author when Plan 3 closes).

---

## §1 What this program is

One session's question — "should `FrameWdgt` (windows), `PopUpWdgt` (menus/prompts) and
`ToolbarWdgt` be one container that manifests differently?" — pulled a chain: containers →
what a toolbar's title bar is → whether the answers hold at touch target sizes → the input event
model → how a tablet is tested. The chain is **three spines that share almost no code**, plus
one cross-cutting visual event:

- **Spine I — chrome.** Container unification, bar orientation, docking generalisation, the
  chrome-constants discipline. Lives in `FrameWdgt` / its bar / the pop-ups / the toolbars.
- **Spine II — input.** Pointer Events migration, then the gesture grammar (hold → menu,
  hold-then-move → lift, plain drag → scroll). Lives in `src/events-input/` and the hand.
- **Spine III — harness.** A finger pointer kind in the macro toolkit, intent translation, a
  pointer-kind reference axis, a `finger` gauntlet leg. Lives in `Fizzygum-tests/`.
- **The visual wave.** One geometry for mouse and finger (touch-capable targets), indicator
  scrollbars, the test-world extent scaled with the geometry. ONE pixel event.

Widgets never see input events; the hand sees widgets only through capability queries. The one
real seam is the pop-up **dismissal code living in `ActivePointerWdgt`** (`cleanupMenuWdgts`,
the `isMenu?()` check at its `processMouseDown`, `hierarchyOfClickedMenus`): Spine I rewrites
its *logic*, Spine II rewrites its *plumbing*. That is a merge hazard, not a design hazard —
hence the "never concurrent" constraint in §3.

Every cut point in §3 leaves a shippable, self-justifying system: the container arc is a
complete improvement without touch sizes; Pointer Events are a complete improvement without
the grammar. Nothing in the program depends on a later arc to make sense.

---

## §2 Decision ledger — owner rulings, 2026-08-23

Each row is a ruling. A plan cites the ID; it does not re-derive or re-argue the decision. A
later owner ruling may overturn a row — record the overturn here (date + reason), never in a
plan. "Rec." rows are the executor's recommendation still awaiting a ruling.

### 2.1 The container (Plan 1)

| ID | Ruling | Reason (one line) |
|---|---|---|
| **C1** | `FrameWdgt` is THE one chrome container and **keeps its name**. Window, card, menu, docked strip are *manifestations* of a frame, never classes. `PopUpWdgt` is deleted. | The docs already define frame = the manipulation chrome; "window" names one manifestation (the `ScrollFrame` lesson). |
| **C2** | ONE runtime state: **`lifetime: 'transient' \| 'persistent'`**, set through `setLifetime`. It replaces the two kill flags (`killThisPopUpIfClickOutsideDescendants` / `…OnDescendantsTriggers`), which encode one bit in practice (no call site ever sets them independently). | Bloch Item 34; the `scrollPolicy` precedent (policy over structure). The tag changes mid-life, so a class hierarchy cannot express it (GoF State; not Bloch's tagged-class case). |
| **C3** | `pin` = `setLifetime 'persistent'` and stays the user-facing verb (menu row, header tap). **No "unpin" gesture**; the API is symmetric, the UX is one-directional. | A reverse row is menu rent nothing asks for (the P2 bind-row lesson). |
| **C4** | **Skin = f(lifetime, parentage)** → exactly THREE manifestations: *menu* (transient — always a world child), *window* (persistent on the world), *card* (persistent, nested). **There is no "pinned menu" skin**: a pinned menu IS a window (bar with close + collapse + title; no pencil, no resizer — both derived from the rows payload). | A fourth skin would key on HISTORY ("was once a menu"), the one input a derived skin may never take. |
| **C5** | **Bar roster is DERIVED**, never classed: transient → title only (tap pins); persistent → close + collapse + title; pencil iff payload `providesAmenitiesForEditing`; resizer iff payload sizes freely AND **C6**. `FrameBarWdgt` + `MenuHeader` become one bar class with a roster and per-manifestation metrics. | One drag idiom, one close idiom, one title class. |
| **C6** | **Close button and resizer show iff `isFreeFloating()`** (the predicate the handles already use). A host that owns placement (edge spec, stack spec, window-content spec) owns membership — you leave by dragging out. Consequence accepted by the owner: **an internal window (window as window content) loses its close button**, and the `UNLESS we are an internal window` exception in `Widget._closeNoSettle` is deleted. Cards in stretchable containers keep close (follower spec ⇒ free-floating). Right-click → close remains the universal fallback. | A close control you can hit while reaching for a grip is the thing to avoid; "no toolbar exception" — a docked document loses close for the same reason. |
| **C7** | **Drop a persistent menu into an empty window: NEST, never merge.** One rule: a frame dropped into a frame nests (dwell-armed). | Merge is a type test in gesture form and destroys an object the user made. |
| **C8** | **Grab pins.** Grabbing a transient frame sets it persistent at the grab, not at the drop. (Today `PopUpWdgt._reactToBeingDropped` pins only for a non-world drop, so a menu dragged onto the desktop still evaporates on the next click — verified by reading; Plan 1 P0 verifies by running.) | "You moved it, it stays" (Squeak: dragging a menu makes it stay up). |
| **C9** | **Transient ⇒ world child, always** — a stated invariant; any reparent ⇒ persistent is its consequence. | Already true in practice (z-order / unocclusion). |
| **C10** | **"Never bigger than the world" is a property of hugging payloads, not of lifetime**: the rows-viewport cap (and the `POPUP_LARGER_THAN_WORLD` guard) holds in both lifetimes. | Fewer branches; a persistent rows frame that grows via `addMenuItem` stays reachable. |
| **C11** | **`ToolbarWdgt` stays a PAYLOAD** (a viewport over a tool grid). It is not a container peer. | Fusing payload and chrome is the fusion the Frame-model arc removed. |
| **C12** | **Docked = a nested frame under a host-owned EDGE layout spec** — card skin, bar = grip + collapse (+ title when horizontal), **no close, no resizer** (C6). **Four edge slots per host**, one per side. The slot accepts **any frame** (no type test); cross-axis thickness = the payload's declared `dockThickness` if it declares one, else the frame's cross extent at dock time. Docking = dwell-armed drop on an edge band; undocking = drag the grip out. `floatToolbar` / the fresh-variant re-dock are dissolved. | `QDockWidget`'s rule; a grip skin would be a manifestation keyed on position, which parentage + spec already express. |
| **C13** | **Bar orientation**: an expanded docked frame's bar runs ACROSS the strip at its leading end (vertical at the left end of a top/bottom dock, horizontal at the top of a left/right dock); a **collapsed frame is its bar, spanning the axis it keeps** (for a dock: along the edge — a full-width band for a top dock, a full-height sliver for a side dock). No flip: the frame's shape changes and the bar is laid out for the shape. **Text only on horizontal bars.** Expanded dock thickness = payload `dockThickness` exactly (the bar adds nothing to it); collapsed = bar thickness (not 0 — there must be something to tap). | Qt `DockWidgetVerticalTitleBar` precedent; compactness without a new skin. |
| **C14** | `MenuWdgt` and `PromptWdgt` become **framed citizens** (`extends FrameWdgt`, the §5.B pattern `DocumentWdgt` uses): ctor builds the rows-viewport payload, sets `lifetime: 'transient'`, keeps the delegated row API untouched (`new MenuWdgt` ×45, `addMenuItem`/`prependMenuItem` ×315 call sites). | "A menu IS its frame" exactly as "a document IS its window". |
| **C15** | **Free windows keep the bar on TOP, always.** No per-frame `barSide` knob. | A per-frame orientation choice on free windows costs predictability. |
| **C16** | Toolbar ⇄ menu (column-of-labels vs grid-of-icons) is a **payload-arrangement axis, OUT of Plan 1** → tail ledger T1. | Different axis; mixing it in re-fuses payload and chrome. |
| **Rec. C17** | *Whole bar tappable to expand a collapsed frame* (not just the collapse button). Recommended; needs a ruling before Plan 1 P5. At touch scale a 50 px sliver with one 44 px button at the end wastes its own target area. | — |

### 2.2 Geometry, scrollbars, the single interface (Plan 3)

| ID | Ruling | Reason |
|---|---|---|
| **G1** | **ONE geometry for mouse and finger. No per-device redraw.** (`setTouchInputMode` has ZERO callers today — verified — and stays dead on principle.) Only the gesture→intent mapping differs per input, and it is kept as small as possible. | Owner preference; a finger has no wheel/hover/second button, so gestures MUST differ — nothing else may. |
| **G2** | **Every chrome dimension is a named preference; every thickness is a formula over preferences; no literal in a layout method.** (`CLOSE_ICON_SIZE`, the frame's `padding = 5`, `MenuHeader`'s `super 3`, the rows panel's `padding: 2`, `ToolPanelWdgt`'s 30/5/10, `ToolbarWdgt.dockThickness: 95` are the literals; `dockThickness` must become `rows · (thumb + gap) + 2·externalPadding`.) Lands in Plan 1 Phase 0, pixel-identical. | Makes the single geometry a one-block edit later; §6.1 rule 1 (pure constants, no laid-out extents) still holds. |
| **G3** | **Three dials, not one**: *targets* ≥ 44 (bar buttons, thumbs, handles), *glyphs* ~24 inset in the target box, *indicators* thin (scrollbars are NOT targets). A widget's hit box may be larger than what it paints (the bar arrange must never equate glyph with box; equal on the desk profile so today's pixels don't move). | Uniform scaling is what looks silly; the HIG scales three kinds of thing differently. |
| **G4** | **Scrollbars become overlay INDICATORS**: thin, appear during scroll, fade, fatten under a hovering pointer (macOS since Lion). The frame's thickness formulas never add `scrollBarsThickness` (bars overlay the plane — verified in `ViewportWdgt._reLayoutScrollbars`). | The single-interface answer; a fat bar is the per-device one. |
| **G5** | Targets 44; **menu row height is the one dial the owner sets by taste** (44 per HIG; 40 is the floor — Fluent's touch minimum). The cap-to-world + scroll rule (C10) carries long menus either way. | — |
| **G6** | **The visual wave scales the test-world extent with the geometry** so the suite keeps its meaning (at 44 px rows a ten-row menu is the whole 440 px test world). | — |
| **G7** | The wave is preceded by a **probe page** — one window, one menu, one docked toolbar at the proposed sizes — for the owner's eyes, before anything is recaptured. | The single geometry is the program's one decision that feels irreversible. |

### 2.3 Input and harness (Plans 2 and 4)

| ID | Ruling | Reason |
|---|---|---|
| **I1** | **Migrate to W3C Pointer Events**: a `PointerInputEvent` family (down/move/up/**cancel**) carrying `pointerType / pointerId / isPrimary / pressure / position`; the six `Mouse*`/`Touch*` adapters deleted; `touch-action: none` on the canvas (with pointer events, `preventDefault` does NOT stop browser panning — the CSS property does); `setPointerCapture` on down; position taken from the down itself (resolves the TODO at `MousedownInputEvent.coffee:3`); a `pointercancel` abort path on the hand (today there is no `touchcancel` listener at all). `contextmenu` listener kept (preventDefault). Safari's proprietary `gesturestart/gesturechange` may stay beside the pointer listeners until pinch is derived from two `pointerId`s. | Per-EVENT `pointerType` keys the grammar per stroke (hybrids get it right); one adapter family; `pointercancel` is new correctness. |
| **I2** | **The gesture grammar**, keyed on `pointerType`: plain drag scrolls; press-and-hold lifts (hold without moving → context menu; hold, then move → the item lifts and the menu goes away). Lift delay = 0 for a pointer (today's mouse behaviour unchanged: drag lifts, wheel scrolls), ~500 ms for a finger. **Hold is required only where a plain drag already means scroll**; chrome drags (grip, bar, handle, slider) need no hold on either device. Text selection by drag is the same kind of surface (hold → select). Timings are EVENT-time, never wall-clock (the multi-click lesson). | iOS's system-wide drag-and-drop grammar; one rule for toolbar thumbs, pinned-menu rows, list rows, loose content. Today a finger cannot open a context menu at all. |
| **I3** | Not axis-locking, not scroll-by-background, not two-finger scroll. | Axis lock breaks on 2-D grids and menus and would change mouse behaviour; gaps are 8 px; `touches[0]` only and undiscoverable. |
| **H1** | **The harness's finger IS the product's touch path**: a `PointerInputEvent` with `pointerType: 'touch'` constructed by the same class the browser listener constructs. Boot-smoke proof: synthetic `PointerEvent` at the canvas → the hand received the same `PointerInputEvent`. | An injector must PROVE injection; booting is not exercising. |
| **H2** | The macro toolkit's **intent verbs translate per pointer kind** (click → tap; right-click → hold; lift/drag-out → hold-then-drag; scroll → plain drag; hover → no equivalent), so most existing macros replay under the finger. Finger runs get their **own reference axis** (a pointer-kind term in the reference filename grammar, like `dpr`), because hover pixels differ and some tests are mouse-only by meaning (declared per test). Plus finger-ONLY tests for the grammar itself, tablet-extent tests, and a **`finger` gauntlet leg = webkit + dpr2 + finger** (for this suite's purposes, an iPad). | — |

---

## §3 Sequencing and hard constraints

```
0  Lock decisions → this doc + Plan 1 (DONE 2026-08-23)
1  Plan 1  Frame lifetime + docking (constants discipline as its P0)   [chrome, the big one]
   └ tail 1
2  Plan 2  Pointer Events                                               [input, mechanical]
   └ tail 2
3  Plan 3  Probe page → visual wave                                     [THE one recapture]
   └ tail 3
4  Plan 4  Gesture grammar + finger harness                             [input + harness]
   └ tail 4
5  Follow-ons (tail ledger, unsequenced)
```

**Hard constraints** (everything else is preference):
- **1 → 2 never concurrent.** Both touch `ActivePointerWdgt` (Plan 1 the dismissal logic, Plan 2 the plumbing). If a sibling session wants Plan 2 earlier, it goes *before* Plan 1, never alongside.
- **2 → 4** (the grammar branches on `pointerType`).
- **3 → 4** (finger tests are born at final geometry).
- **All deliberate pixel change lands in Plan 3**, except where the structure itself is a visible affordance (Plan 1 P2's inner close button vanishing; Plan 1 P5's docked grip appearing) — those land as their own reviewed recapture sets, each counted in Plan 1 P0.
- **Each plan is authored against the tree as it stands when its arc starts** (§6).

**Rough sizes** (the owner wants ETAs up front; sessions, not calendar): Plan 1 ≈ 5–7 session-days
(its P0 ½, P1 ½, P2 1, P3 1–1.5, P4 ½, P5 1.5–2, P6 ½) + tail; Plan 2 ≈ 1 + tail; Plan 3 ≈ 1 + owner
review + tail; Plan 4 ≈ 2–3 + tail. The viewport role-architecture arc (six phases, ~1,000 lines
across two classes) took one session-day; Plan 1 is roughly three to four of those.

---

## §4 Recapture policy

Nearly every SystemTest shows chrome, so an unreviewed pixel drift in a structural phase turns the
suite from a safety net into noise (a recapture is a decision to BELIEVE the pixels). Therefore:

1. **Structural phases gate on ZERO recaptures** (`fg presuite` byte-identical at dpr1; `fg gauntlet`
   at phase close). A phase that needs a recapture to go green has either a bug or an undeclared
   visible change — find out which before recapturing.
2. **Declared visible changes** (ledger §3) land as their own reviewed set: `fg build` → `fg diffpage
   <names>` → eyeball CONSEQUENCE pixels (never "benign churn") → `fg recapture --auto` → the
   INCOMPLETE/COMPLETE verdict. The set's size is measured in P0, not discovered at the gate.
3. **Plan 3 is the one wave**: every other pixel change in the program rides it. Preceded by the probe
   page (G7); the test world scales with it (G6); reviewed with `fg diffpage` + `fg classify`.
4. ⚠ `fg recapture --auto` discovers against the EXISTING build — build first, never edit mid-run.

---

## §5 Tail rules and the tail ledger

Tails grow because "for later" has no address. Two rules bind every plan in this program:

1. **No deferral without a destination.** A plan may defer an item only as: *absorbed by Plan N of this
   program* (with the phase), *filed in `docs/BACKLOG.md`* (with the reason it is not in this program),
   or *killed* (with the evidence). "Postponed"/"kick down the road" with no address is a plan-review
   failure, checked at the close-arc ritual.
2. **Drain the tail before the next arc starts** — `arc N → tail N → arc N+1`, never `arcs → tails`.
   Tail items are hypotheses about a tree the next arc will change; drained warm they cost a day,
   drained at the end they are re-investigations. Each tail gets its own ETA line.

**Tail ledger** — every deferred item from every arc, with origin, destination, status. The program
closes when this table is EMPTY (not when the last plan's gate passes). Pre-filed from the design
session:

| ID | Item | Origin | Destination | Status |
|---|---|---|---|---|
| T1 | **Command-panel arrangement** — `MenuRowsPanelWdgt` (column of labels) and `ToolPanelWdgt` (grid of icons) become one command panel with an arrangement policy `'column' \| 'grid'` whose buttons answer both a label and an icon (the toolbar ⇄ menu axis, C16). | session | BACKLOG after Plan 1 (pure payload work once the container is indifferent) | open |
| T2 | **Overflow chevron** — a docked strip showing as many items as fit + an overflow button popping the rest as a menu (macOS/iPad toolbar convention; T1 from the other side). | session | BACKLOG, after T1 | open |
| T3 | **Resize handle: small glyph, large hit zone** (or edge-grab resizing). | session | BACKLOG; revisit in Plan 3's probe page | open |
| T4 | **Multi-pointer** (pinch from two `pointerId`s; retire `gesturestart/gesturechange`). | session | BACKLOG after Plan 2 | open |
| T5 | **Desktop-edge docking** (the world's edges as dock slots — a taskbar strip); free consequence of a generic edge spec, not a commitment. | session | Plan 1 P5 decides whether the edge spec is world-capable; else BACKLOG | open |
| T6 | **Hover-dependent affordances on touch** — toolbar thumbnail tooltips (`GlassBoxTopWdgt.toolTipMessage`), hover highlights, the pointer-under state. | session | Plan 4 (the hold-menu's title can name the widget; rest declared out) | open |
| T7 | **Virtual keyboard keyed on the `pointerType` of the tap that started the edit** (today keyed on the session-level `isTouchDevice`). | session | Plan 4 tail | open |
| T8 | **`firstParentThatIsAPopUp` naming** (14 refs) — after C1 it climbs to the enclosing FRAME; rename in Plan 1 P6's sweep or file. | session | Plan 1 P6 | open |
| T9 | **Stale comment** in `PromptWdgt` ("the three isMenu? sites … Wallpaper / StringWdgt tick refresh") — there is ONE consumer (`ActivePointerWdgt:660`). | session | Plan 1 P3 (fix in passing) | open |
| T10 | **`FrameWdgt.tight`** — set in the ctor, read by nobody on the frame (only `VerticalStackPanelWdgt` reads `@tight`). | session | Plan 1 P1 (delete) | open |

---

## §6 Plan roster and the just-in-time rule

| Plan | File | Authored | Why not earlier |
|---|---|---|---|
| 1 | `docs/plans/frame-lifetime-and-docking-plan.md` | 2026-08-23 | — |
| 2 | `docs/plans/pointer-events-plan.md` | when Plan 1 closes | Plan 1 edits the hand's dismissal paths; a plan authored now would cite lines Plan 1 moves. |
| 3 | `docs/plans/single-geometry-visual-wave-plan.md` | when Plan 2 closes | The bar/dock metrics it retunes are Plan 1's output. |
| 4 | `docs/plans/gesture-grammar-and-finger-harness-plan.md` | when Plan 3 closes | Cites the `PointerInputEvent` family (Plan 2) and captures at final geometry (Plan 3). |

A plan's premises are hypotheses (case law: a freshly-authored plan had three wrong premises
the same day). A plan authored against a tree that an earlier arc is about to change would cite
class names (`PopUpWdgt`), flags and adapters that no longer exist when it is executed. Each plan
is therefore written **against the tree as it stands when its arc starts**, by the `author-plan`
skill, with this ledger as its decisions input — the author fact-checks the tree, not this doc.

---

## §7 References

- Plan 1: [`frame-lifetime-and-docking-plan.md`](frame-lifetime-and-docking-plan.md).
- Architecture (living truth): [`../architecture/regularity-principles.md`](../architecture/regularity-principles.md)
  (the frame model: content vs chrome; window vs card by parentage), [`../architecture/widget-citizenship.md`](../architecture/widget-citizenship.md)
  (point 5: parts come OUT — the row-extraction opt-in), [`../architecture/viewports-and-planes.md`](../architecture/viewports-and-planes.md)
  (the viewport role architecture this program extends to frames), [`../architecture/layout.md`](../architecture/layout.md),
  [`../architecture/layering-naming-convention.md`](../architecture/layering-naming-convention.md),
  [`../architecture/lint-and-static-checks.md`](../architecture/lint-and-static-checks.md).
- Specs: [`../specs/drag-embed-interaction-spec.md`](../specs/drag-embed-interaction-spec.md) (dwell-to-arm; the
  window-payload rule C12's docking rides).
- Case law (archive): [`../archive/onion-widget-composition-plan.md`](../archive/onion-widget-composition-plan.md)
  (the Frame-model flagship: framed citizens §5.B, the toolbar slot §5.C/D9, close policy §5.E),
  [`../archive/scroll-frame-role-architecture-plan.md`](../archive/scroll-frame-role-architecture-plan.md) (the
  `scrollPolicy` precedent: policy over structure; "a role name, not a manifestation name"),
  [`../archive/menu-sandwich-dissolution-plan.md`](../archive/menu-sandwich-dissolution-plan.md) (the rows panel
  IS the rows viewport's plane; why the two-writer fight is dissolved, not mediated).
- Precedents outside the repo, cited in the rulings: Qt `QDockWidget` (same object docks/floats; `DockWidgetVerticalTitleBar`),
  Cocoa `NSPanel` (a window with behaviour flags), Squeak `MenuMorph stayUp:` (the same menu pins in place),
  tear-off menus (Tk/Motif/GTK2/Qt — conversion, the regretted pattern), Apple HIG (44 pt targets, 50 pt iPad bars,
  indicator scrollbars), W3C Pointer Events (Safari 13+).
