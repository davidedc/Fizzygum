# Desktop corner-spec dissolution — the last type-test placement dies

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-06; every fact below verified same day against Fizzygum `76130d2f` /
Fizzygum-tests `c8a2b8775` (the kept-spec knob-model arc's close — its landed state is this
plan's starting point; suite 282, gauntlet 14/14). ⚠ Line numbers drift — quoted
method/class names are authoritative; re-grep before trusting a line.

**MANDATE.** `WorldWdgt._reLayoutDesktop`'s bin-opener/clock special-casing — the LAST place
a layout strategy is chosen by `instanceof` — is ELIMINATED, not wrapped: the two widgets
join the spec family's corner idiom, "corner-anchored until the user intervenes" becomes
WHICH-SPEC-IS-ARMED (the family lifecycle verbatim), and the `userMovedThisFromComputedPosition`
flag is DELETED (it is a hand-rolled shadow of exactly that state). Right-Thing policy:
no legacy accommodation, no behavior flags; clean uniform flow.

## §0 Orientation

**Fizzygum** — CoffeeScript canvas GUI framework; ~470 classes, all globals; build + test
via the `fg` wrapper from ANY cwd (`fg build` · `fg presuite` ~2 min · `fg gauntlet` ~5 min
· `fg apps` · `fg homepage`). Long ops: `run_in_background` + log + `/tmp/fg-<cmd>.verdict`;
never overlap two live fg wrappers. Read first: `Fizzygum/CLAUDE.md`,
`docs/architecture/layout.md` §4.2 (the spec family — five members, TWO lifecycle kinds:
carrier-owned KNOB vs per-attachment RECORD, armed into `Widget.layoutSpec` at attachment).

**Why now.** The 2026-08 spec-family program closed with the kept-spec fold
(`docs/archive/kept-layout-spec-unification-plan.md`); this item was filed at the stretch
arc's close (`docs/archive/stretch-layout-spec-unification-plan.md` §4 D10 follow-on;
`docs/BACKLOG.md` carries the open line). It is the family program's last residual: every
other placement strategy is spec-kind dispatched; the desktop's two special cases are
`instanceof` + a boolean flag.

**CRITICAL REFRAME.** "Corner-anchored until the user intervenes" is not a policy that
needs a FLAG — it is the family's normal lifecycle: an ARMED corner spec places the widget;
a grab DISARMS (nils the slot, `Widget._beforeBeingGrabbed`); nothing re-arms it, so the
widget is free-floating (clamped, and — if consumed by the membership rule — stretch-seeded)
forever after. The flag, the two `instanceof` searches, the duplicated corner arithmetic,
and the clock's magic `80` all exist because the placement predates the family.

## §1 Current state (verified 2026-08-06 at `76130d2f`)

- **`WorldWdgt._reLayoutDesktop` (~:1988-2020)** — called from the browser-resize handler
  (~:1935, right after the world's `_applyExtent`; NOT from a world `_reLayout`). Three
  parts: (1) `firstChildSuchThat (w) -> w instanceof BinOpenerWdgt` → if
  `userMovedThisFromComputedPosition` then `_moveInDesktopToFractionalPosition()` + clamp,
  else `_applyMoveTo @bottomRight().subtract binOpenerWdgt.extent().add @desktopSidesPadding`;
  (2) the same shape for `instanceof AnalogClockWdgt`, computed position
  `new Point @right() - 80 - @desktopSidesPadding, @top() + @desktopSidesPadding`
  (the `80` is a magic constant = the clock's width); (3) the generic consumed-children
  loop, which EXCLUDES the two by identity (`child != binOpenerWdgt and child !=
  analogClockWdgt and @consumesFractionalGeometryOf child`).
- **`userMovedThisFromComputedPosition` — the COMPLETE census (6 sites, 4 files):**
  `Widget:~334` prototype decl (its comment speaks of "references" — no reference flow
  reads it; vestigial prose); `Widget._beforeBeingGrabbed` (~:4488) sets it true on EVERY
  grab; `BinOpenerWdgt:17` reads it in `_reactToBeingAdded` (guarding a DUPLICATE of the
  corner formula: `@_applyMoveTo world.bottomRight().subtract @extent().add
  world.desktopSidesPadding` — the same arithmetic as `_reLayoutDesktop`'s, maintained
  twice); `BinOpenerWdgt:27` sets it in `_reactToBeingDropped(world)`; the two
  `_reLayoutDesktop` reads. NO OTHER READERS.
- **The corner idiom that already exists:** `CornerInternalLayoutSpec` (anchor +
  `proportionOfParent`/`fixedSize`/`inset`); base `Widget._reLayout`'s corner branch
  (~:5044-5067) sizes the carrier SQUARE — `minDim = round(min(parentW,parentH) *
  proportionOfParent + fixedSize)`, `__commitExtent (minDim, minDim)` — then anchors:
  `topRight` → `(parent.right() - minDim - inset.x, parent.top() + inset.y)`;
  `bottomRight` → `(parent.right() - minDim - inset.x, parent.bottom() - minDim -
  inset.y)`. Containers re-place corner children via `_reLayoutCornerInternalChildren()`
  (~:5088 — filters `layoutSpec?.isCornerInternal?()`, re-lays each). The carrier-field
  arming precedent is `HandleWdgt.cornerSpec` (:42) + `defaultLayoutSpecWhenAddedTo`
  (world/hand → nil, else the spec).
- **Membership facts that make the fold fall out naturally:** `BinOpenerWdgt` extends
  `IconicDesktopSystemLinkWdgt` → `WidgetHolderWithCaptionWdgt.isDesktopIcon` true → the
  desktop's `consumesFractionalGeometryOf` EXCLUDES it (never stretch-seeded; its
  post-grab life is clamp-only — `_moveWithin`). `AnalogClockWdgt` is NOT an icon →
  consumed → seeded → post-grab it proportionally tracks. Both special-case blocks
  re-implement exactly what the generic loop would do for each.
- **The clock's creation:** `WorldWdgt.createDesktop` (~:615): `acm = new AnalogClockWdgt;
  acm._applyBounds (new Point @right()-80-@desktopSidesPadding, @top() +
  @desktopSidesPadding), new Point 80, 80; @add acm` — extent IS (80, 80), so
  extent-derived anchoring is BYTE-EQUAL to the magic `80`.
- **Test visibility: NONE.** `createDesktop` runs only on `index.html`
  (`world.isIndexPage`); the harness page has no desktop, so NO SystemTest sees any of
  this. The gates are the headless rigs: `fg apps`, `fg homepage` (+ smoke), the `parts`
  leg's icon probes — plus `fg gauntlet` for the no-regression envelope.

## §2 Why it is shaped this way

The two placements predate the spec family: the desktop hand-placed its furniture, and the
"until the user moves it" memory was a boolean because there was nothing else to carry it.
The corner spec arrived later (for handles) with SIZING built in — its carriers were always
square chrome — so the furniture never migrated. The kept-spec arc's D10 review named the
dissolution but deferred it precisely because of that sizing coupling.

## §3 The distilled argument

Every piece of the special-casing is a shadow of family machinery that now exists: the flag
shadows "which spec is armed"; the `instanceof` searches shadow capability dispatch; the
duplicated corner arithmetic (BinOpenerWdgt + _reLayoutDesktop, and createDesktop's magic
`80`) shadows the corner pass; the identity-exclusions in the generic loop shadow the
membership rule already excluding/including each widget correctly. Deleting the shadow
leaves ONE mechanism, and the post-grab behaviors (opener: clamp-only; clock: proportional
tracking) fall out of the ONE `consumesFractionalGeometryOf` rule with no code at all.

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — Fizzygum at/past `76130d2f`,
   tests at/past `c8a2b8775`, 282 SystemTests, last gauntlet green. If not, STOP and
   re-orient (resume-arc skill).
2. Read this plan in full; then `docs/architecture/layout.md` §4.2; then in src:
   `CornerInternalLayoutSpec.coffee` (whole file, small), the base corner branch
   (`Widget._reLayout`'s `isCornerInternal` arm + `_reLayoutCornerInternalChildren`),
   `HandleWdgt` :40-60 (the carrier idiom), `WorldWdgt._reLayoutDesktop` + the resize
   caller + `createDesktop`'s clock/bin-opener regions, `BinOpenerWdgt` in full (small).
3. Execute P1 (one batch), gate per §6, ledger, then P2 (deletion sweep), gate, close.
4. Commits: present messages (`git commit -F <file>`); never commit/push without the
   owner's word.

## §4 Design decisions (RECOMMENDED — execute as decided unless falsified in-flight)

D1. **Sizing becomes OPTIONAL on the corner spec — "a spec that declares no size does not
    size its carrier."** The corner branch's sizing/placement split: if
    `proportionOfParent == 0 and fixedSize == 0` (the degenerate combo, today producing a
    broken size-0 square — VERIFIED UNUSED: HandleWdgt uses (0, handleSize), the badges
    use (proportion, 0)), the pass SKIPS `__commitExtent` and the anchor formulas use the
    carrier's own PER-AXIS extent (`@width()`/`@height()`) in place of `minDim`. No new
    field, no mode flag; the degenerate case becomes meaningful instead of broken.
    (Rejected: a `resizesCarrier` boolean — a mode flag duplicating what the zero-size
    declaration already says.) ⚠ Keep the sized path's arithmetic byte-identical for
    handles/badges (same rounding, same `minDim` in the formulas).
D2. **The two widgets carry corner KNOBS, armed at creation:** `createDesktop` arms
    explicitly — `@add acm, nil, acm.cornerSpec-door` style, mirroring the
    `divisionBox()` public-door idiom (add a tiny `BinOpenerWdgt`/`AnalogClockWdgt`
    carrier field + door, or set a `cornerSpec` field in their constructors like
    HandleWdgt — executor's call, keep it uniform with HandleWdgt's naming). Anchors:
    opener `bottomRight`, clock `topRight`, both `inset = (desktopSidesPadding,
    desktopSidesPadding)` — VERIFIED byte-equal to today's computed positions (opener:
    BR − extent − padding; clock: right − 80 − padding with width 80). The clock's
    createDesktop `_applyBounds` keeps the (80, 80) extent but drops the hand-computed
    position (the corner pass places it).
    ⚠ Do NOT route the default through `defaultLayoutSpecWhenAddedTo(world)`: a USER
    re-drop resolves the default too, and would re-anchor — the arming must be the
    CREATOR's explicit act, so a drop's nil-resolution leaves the widget free (then the
    membership rule decides seeding). This is the lifecycle carrying the "until the user
    intervenes" semantics.
D3. **`_reLayoutDesktop` shrinks to the generic loop + one corner-pass line:** both
    special-case blocks DELETED; `@_reLayoutCornerInternalChildren()` added (the world's
    resize path does not run a base `_reLayout`, so the desktop reflow calls the pass
    directly); the generic loop drops the two identity-exclusions (a corner-ARMED child
    is skipped by it naturally: `consumesFractionalGeometryOf` excludes the icon opener
    outright, and the clock-while-anchored... VERIFY in P1: a corner-armed clock must not
    be stretch-imposed by the loop — `isStretchElement?()` on a corner spec answers
    undefined so `_moveInDesktopToFractionalPosition` is skipped, and the `_moveWithin`
    clamp is harmless for an in-corner widget — confirm, don't assume).
D4. **`userMovedThisFromComputedPosition` DELETED everywhere** (decl + the
    `_beforeBeingGrabbed` set + BinOpenerWdgt's read/set + the two desktop reads);
    `BinOpenerWdgt._reactToBeingAdded`'s duplicate positioning and
    `_reactToBeingDropped`'s flag-set DELETED (the knob + the corner pass own placement;
    a grab-out disarms via the standard `_beforeBeingGrabbed`). ⚠ The field serializes
    today as an own-prop on every ever-grabbed widget — no migration (standing no-compat
    rule); old snapshots' residue is inert.
D5. **Expected churn: suite ZERO (structurally — no test sees the desktop); rigs must
    stay green with the corner placement byte-equal.** Inspector own-prop churn possible
    ONLY if some test grabs a widget and shows its own-props (the flag row vanishes) —
    if the suite shows any failure, diffpage + eyeball + the benign-class recapture
    protocol, per the kept-spec arc precedent.

## §5 Phases

P1 — the mechanism, one batch: D1 corner-pass sizing opt-out + D2 knobs/arming + D3
     `_reLayoutDesktop` shrink. Verify with a small in-page probe
     (`Fizzygum-tests/.scratch/`, headless-boot `index.html`): opener/clock at
     byte-identical positions pre/post fold at two window sizes; grab-simulate
     (`_beforeBeingGrabbed()` + world re-add + move) → browser-resize → opener stays
     put (clamped), clock proportionally tracks; snapshot round-trip preserves the armed
     corner spec. Gates: `fg presuite`, `fg apps`, `fg homepage`.
P2 — D4 deletion sweep + docs (layout.md §4.2 gains the furniture example in the corner
     entry; `CornerInternalLayoutSpec.coffee` header notes optional sizing) + BACKLOG
     line closed + archive + INDEX + memory. Gates: `fg presuite`, `fg gauntlet`,
     both serialization rigs ride the gauntlet; `fg homepage` again (the production
     desktop IS the surface under change).

## §6 Verification protocol

`fg presuite` per batch; `fg gauntlet` at close; `fg apps` + `fg homepage` at BOTH phases
(the desktop only exists on `index.html` — the homepage rig's boot + snapshot round-trip is
the primary oracle); the P1 probe is the placement oracle (byte-equal positions, lifecycle
transitions). Any suite failure: diffpage + eyeball before any recapture.

## §7 Rejected / do-not-re-attempt

- **A `resizesCarrier` mode flag** — the zero-size declaration already carries the fact
  (D1); a boolean would be a second source of truth.
- **Routing the corner default through `defaultLayoutSpecWhenAddedTo(world)`** — re-arms
  on every user drop; the flag would be reborn to suppress it. The creator arms, period.
- **Keeping the flag "for references"** — the census shows zero reference-flow readers;
  the decl comment is vestigial prose.
- **A new `AnchorLayoutSpec` family member** — the corner spec IS the anchor concept;
  a sixth member would duplicate the five-anchor vocabulary for the sizing bit D1 removes.

## §8 References + execution ledger

`docs/archive/stretch-layout-spec-unification-plan.md` §4 D10 (the follow-on's origin) ·
`docs/archive/kept-layout-spec-unification-plan.md` (the knob model + case law: a mechanism
whose only purpose is preserving behavior is a backcompat smell) ·
`docs/architecture/layout.md` §4.2 · memory: `kept-layout-spec-unification-arc`,
`ask-before-commit-push`, `no-serialization-compat-obligations`.

### Execution ledger (append per phase; empty at authoring)
