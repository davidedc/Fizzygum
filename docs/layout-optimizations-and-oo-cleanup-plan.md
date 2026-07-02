# Plan — layout optimizations + OO cleanup (post-seam-deletion)

**Status: REWRITTEN 2026-07-02 after a code-level reassessment. Self-contained; runnable cold — an executor with NO
prior context starts at §0.5.** Fizzygum master **`06b1ae53`** (tree clean). The original cheap tier is **landed and
committed** — Opt-4 rule `[N]` + OO-1 + OO-3, the twin collapse (`8aefa53f`), and Opt-2 (`06b1ae53`); their outcome
records are kept in §6. The live plan is three tiers found by re-reading the engine source itself: **Tier A** (§2 —
dead weight + inert defects + a stale-doc repair, one cheap batch), **Tier B** (§3 — the `*AndNotify` truthful-name
rename **plus the Family-1 rewrite of `layering-naming-convention.md` it entails**, owner sign-off needed on names),
**Tier C** (§4 — optional handle-drag coalescing, default-decline). The previous plan's two remaining open items did
**not** survive the reassessment: **Opt-1 is BANKED** and **Opt-3 is RETIRED (premise falsified)** — both moved, with
the evidence, to the Appendix alongside the owner-ruled-out §4.3 and the non-layout OO-2.

## §0 — Why this now, and what it is NOT

The **proper-layouts / settle-convergence arc is complete** (see `layout-system-architecture-assessment.md`, esp. §1,
§2.6, §4.1): the notify-by-mutation seam was **deleted 2026-07-01** and replaced by the **settle-time up-edge**; Stage 6
retired the convergence cap to a never-fire assert; the caret scroll-follow and the window→stack re-fit are
single-pass; the dead batch tier is gone. **There are no remaining deletion targets** — every suppression/convergence
boolean the standing mandate targeted is gone, and the two residual convergences (nested-window first-placement;
aspect-locked cycles, broken by `elasticity 0`) are proven irreducible.

**The 2026-07-02 reassessment** re-read the engine source end-to-end against the goal *efficient, clear, minimal code*:
the settle loop (`WorldWdgt._recalculateLayoutsBody`), the enqueue primitives (`_invalidateLayout` /
`__markForRelayout`), the flush wrapper (`_settleLayoutsAfter`), the up-edge pair (`_reFitMyTrackingContainerAfterSettle`
/ `_reFitContainer`), the whole immediate-mutator family, base `_reLayout`'s horizontal distribution, the recursive
dim queries, the stack arrange, `VerticalStackLayoutSpec`, and `HandleWdgt.nonFloatDragging`. Verdict: **the engine
core is clean — no structural work is warranted** (which is why Opt-1 stays banked). The warts live at the **rim**:
dead code and lying names in the immediate-mutator family, debug residue in the horizontal path, and two inert
defects. This plan collects exactly those.

**None of this is the mandate; all of it is optional.** Every item is byte-identical-intended except the two inert-bug
fixes (A4, A5), which are pixel-invisible for reasons each entry proves. Pick by ROI; the recommended order is §7.

**Determinism reminder:** anything touching the settle loop / `_reLayout` / an arrange / `_invalidateLayout` / the
up-edge is a **convergence change** → it needs `./fg gauntlet` (dpr1/dpr2/webkit) **and** the danger-config torture
(`RECALC_NONCONVERGENCE` absent + 0 fails), not just the suite. See assessment §6.4.

---

## §0.5 — Cold-execution protocol (READ THIS FIRST in a fresh session)

**The workspace.** `Fizzygum-all/` is an umbrella (NOT a git repo) holding three sibling git repos: `Fizzygum/`
(source — the ONLY place you edit code, always under `src/**/*.coffee`), `Fizzygum-tests/` (the SystemTest suite +
reference screenshots), `Fizzygum-builds/` (generated output — **never edit, never grep from the workspace root**;
it is ~1.3 GB). All build/test commands go through the **`./fg` wrapper at the umbrella root** — it is cwd-correct
from anywhere, kills zombie browsers, and gates on real exit codes. Do not hand-chain `cd`s across repos.

**Baseline drift.** This plan's line numbers are exact at Fizzygum `06b1ae53`. Before EVERY edit: `grep -n` the method
name in the named file and confirm the quoted "before" text matches what is there. **The method name + the quoted code
are authoritative; the line number is only a hint.** If a quoted "before" does not match at all, STOP and report —
do not guess.

**CoffeeScript gotchas (this codebase).**
- Indentation IS syntax — reproduce the exact leading spaces of the surrounding code (class methods are indented 2,
  bodies 4, nested bodies 6…). A mis-indented line silently changes scope.
- `nil` means `undefined` (a Fizzygum global) — use it, never `null`/`undefined`, in any code you write.
- One class per file; the filename equals the class name. You are only editing INSIDE existing files here.
- The build syntax-checks every `.coffee` (a fragmented compile — trust `./fg build`, not your own `coffee -c`).

**The per-item loop.** For each code item: (1) re-grep + confirm the "before" text; (2) apply the exact edit from the
item's *How* block; (3) run `./fg build` from the umbrella root — PASS = it prints `0 violations` and `done!!!`
(≈1–2 min; `./fg build --keepTestsDirectoryAsIs` is a faster variant fine for mid-tier iterations). Then move to the
next item. Run the suites only at the end of the tier (next paragraph) — they are the expensive part.

**End-of-tier gates (Tier A).** In order, from the umbrella root:
1. `./fg gauntlet` — build + full suite at dpr1 + dpr2 + webkit + apps smoke + the two runtime audit gates.
   PASS = every leg tallies `PASS` (each suite leg = 165/165, `failed tests: 0`). Expect ≈10–15 min; announce an ETA
   and post progress if you are reporting to the owner live.
2. The **short danger torture** (needed because A6/A7 touch mutators/an arrange). Run these four, one at a time:
   ```sh
   ./fg suite --dpr=2 --shards=8                 # config dpr2-fastest-s8
   ./fg suite --dpr=2 --shards=8 --speed=fast    # config dpr2-fast-s8
   ./fg suite --shards=8                         # config dpr1-fastest-s8
   ./fg suite --dpr=2 --shards=4                 # config dpr2-fastest-s4
   ```
   PASS per run = the `SUITE OK` banner, `failed tests: 0`, **and the string `RECALC_NONCONVERGENCE` appears nowhere
   in the output**. (dpr2 runs are heavy — several minutes each.)
3. **A run that stalls is a FAILURE even with 0 failed screenshots** — an uncaught error gives `completed:false` and a
   shard stall. Treat it as a real breakage of the last item, not as flakiness; do not blindly re-run.

**If a gate fails.** Identify the item responsible (the items are independent — revert them one at a time from the
last: `cd Fizzygum && git diff` to see changes, `git checkout -- <file>` reverts a whole file, or re-apply the
"before" text for just that item). Re-run the failing gate. Report what failed and what you reverted; **do not invent
alternative fixes beyond what the item specifies.** Special case: A6 sub-item 3 is pre-declared droppable alone (its
item says so).

**The one expected benign failure.** If the gauntlet's ONLY failure is `macroDuplicatedInspectorDrivesCopiedTargetOnly`
(the inspector member-list test — A3 deletes lazily-created fields, which can shift an inspected member list), that is
**benign and pre-authorised**: run `./fg recapture macroDuplicatedInspectorDrivesCopiedTargetOnly` (recaptures dpr1+2),
then re-run the failed leg to confirm green. Recaptured reference images live in the **`Fizzygum-tests`** repo — they
become a second repo's diff to show the owner.

**Commit protocol (STRICT).** NEVER `git commit` or `git push` on your own — this is a review-driven project. When the
tier is green: present the owner a summary of the full diff (`Fizzygum`, plus `Fizzygum-tests` if a recapture
happened) and a proposed commit message, then WAIT for approval. When approved: commit via `git commit -F <msgfile>`
(never `-m` with backticks/`$()` — bash command-substitutes them and silently corrupts the message).

**Recommended order within Tier A:** A1 → A2 → A5 → A3+A4 (together — same methods) → A6 → A7 → A8 (doc-only) →
end-of-tier gates. A build between items keeps blame trivially assignable.

---

## §1 — What the reassessment verified (so it is not re-derived)

- **Opt-2 is real and correct in source** — the climb-to-topmost-invalid walk-up with its order-independent-fixpoint
  rationale comment (`WorldWdgt.coffee` :968–985).
- **The twin collapse is real** — `__commitExtent` absorbed `_commitExtentAndNotify` (comment at `Widget.coffee`
  :1565–1571), `_commitBounds` absorbed the bounds pair (:835–840); the collapsed names survive only in 3 comment
  mentions (`Widget.coffee` :1228, :1568).
- **`__markForRelayout` already dedups the work-list** (:3756–3758: push only if `layoutIsValid`) — a fact that
  further weakens Opt-1's "O(1) enqueue" benefit (Appendix X1).
- **`HandleWdgt.nonFloatDragging` makes exactly ONE public-setter call per drag event** (a `switch` with mutually
  exclusive arms, :252–269) — the fact that falsifies Opt-3 (Appendix X2).
- **No caller anywhere passes `_applyExtentAndNotify`'s second argument** (`widgetStartingTheChange`) — every one of
  its ~270 call sites passes a single `Point` (basis of A6).
- **`numberOfRawMovesAndResizes` is a cache VERSION KEY**, not a stat: it is concatenated into
  `checkClippedThroughBoundsCache` / `checkClipThroughCache` / `checkFullClippedBoundsCache` version strings
  (`WorldWdgt.coffee` :667/:675, `Widget.coffee` :1128–:1208, `ClippingAtRectangularBoundsMixin.coffee` :98/:112) —
  the caveat that gates A6's double-break dedup.
- **A7's callers/subclasses census:** `new SimpleVerticalStackPanelWdgt` is called with no args (`MenusHelper.coffee`
  :480, `SimpleVerticalStackScrollPanelWdgt.coffee` :4) or with `null, null, null, false` (`MenusHelper.coffee` :498);
  subclass `WindowWdgt` has its own constructor signature (`WindowWdgt.coffee` :86) and assigns `@padding = 5` itself
  (:101); subclass `SimpleDocumentPanelWdgt` adds no constructor. CoffeeScript default parameters fire on BOTH
  `undefined` and `null` (they compile to `if (param == null)`, a loose check) — so a `@padding = 5` default covers
  every existing caller, including the explicit-`null` one.

---

## §2 — Tier A: dead weight + inert defects (one cheap batch, ~150 lines net deletion + one doc repair)

All in-scope files: `src/basic-widgets/Widget.coffee`, `src/SimpleVerticalStackPanelWdgt.coffee`,
`src/VerticalStackLayoutSpec.coffee`, plus — A8, doc-only — `docs/layering-naming-convention.md`. Run as ONE batch
over the §0.5 loop and gates. **Do not make any edit beyond what an item's *How* block specifies** — in particular,
never touch `__breakMoveResizeCaches` itself or the fullBounds/clippedBounds caches (they are LIVE — the convention
doc §2.4 warns explicitly), and never edit anything under `Fizzygum-builds/`.

### A1 — Delete the 17 `if false and !window.recalculatingLayouts` dead blocks
**What.** Seventeen identical dead blocks in `Widget.coffee` (grep `if false and` — 17 hits, :749, :843, :1258, :1316,
:1373, :1384, :1392, :1400, :1408, :1416, :1425, :1434, :1522, :1677, :1702, :1713, :1738), in the methods:
`_applyBoundsAndNotify`, `_commitBounds`, `__commitMoveBy`, `_applyMoveToAndNotify`, `__commitMoveTo`,
`_moveLeftSideTo`, `_moveRightSideTo`, `_moveTopSideTo`, `_moveBottomSideTo`, `_moveToSideOf`, `_moveFullCenterTo`,
`_moveWithin`, `_applyExtentAndNotify`, `_applyWidthAndNotify`, `__commitWidth`, `_applyHeightAndNotify`,
`__commitHeight`.
**Why.** ~80 lines of pure noise in the single most-read band of the layout system. The "TODO" these blocks gesture at
is long since resolved for real — the tier discipline is enforced by lint rules [A]–[N] + the runtime FLOWRULE throws.
**How (exact edits).** Every block has this exact 4-line shape (delete all 4 lines, everywhere it appears):
```coffee
    # TODO in theory the low-level APIs should only be
    # in the "recalculateLayouts" phase
    if false and !window.recalculatingLayouts
      debugger
```
Also delete the 8 stale numbered breadcrumb lines in the same family (grep `#console.log "move` in `Widget.coffee` —
:1261 "move 5", :1322 "move 6", :1376 "move 7", :1525 "move 8", :1680 "move 10", :1705 "move 11", :1716 "move 12",
:1741 "move 13" — delete each whole line).
**Done-check.** `grep -c "if false and" src/basic-widgets/Widget.coffee` → `0`;
`grep -c '#console.log "move' src/basic-widgets/Widget.coffee` → `0`. Then `./fg build`.
**Risk / gate.** None beyond a typo — dead code only. Build + (end-of-tier) suite.
*(Note: A6 rewrites four of these methods wholesale — if you do A1 first as recommended, A6's "after" bodies below
already assume these blocks are gone.)*

### A2 — Delete the live debug residue in the horizontal distribution (base `_reLayout`)
**What/Why.** The 3-case horizontal-stack distribution (`Widget.coffee` :4146–4244, inside the homepage-excluded
block) still carries live `console.log`s that actually fire (for any horizontal-stack panel sitting directly on the
world), bare `debugger` statements, and a cryptic one-letter flag.
**How (exact edits, six spots).**
1. :4157 — delete the whole line: `if @parent == world then console.log "case 1"`
2. :4187 — delete the whole line: `if @parent == world then console.log "case 2"`
3. :4217 — delete the whole line: `if @parent == world then console.log "case 3 maxMargin: " + maxMargin`
4. :4214–4216 — keep the check, demote log, drop debugger. Before:
   ```coffee
        if extraSpace < 0
          console.log "this shouldn't happen, extraSpace is negative: " + extraSpace
          debugger
   ```
   After:
   ```coffee
        if extraSpace < 0
          console.error "this shouldn't happen, extraSpace is negative: " + extraSpace
   ```
5. :4221–4225 — same treatment. Before:
   ```coffee
        else
          console.log "this shouldn't happen, maxMargin negative: " + maxMargin + " max.width(): " + max.width() + " desired.width(): " + desired.width()
          debugger
   ```
   After (keep the `else`, keep the message, `console.log` → `console.error`, delete the `debugger` line).
6. :4242–4243 — a debugger-only guard; keep the signal, lose the debugger. Before:
   ```coffee
          if childLeft > newBoundsForThisLayout.right() + 5
            debugger
   ```
   After:
   ```coffee
          if childLeft > newBoundsForThisLayout.right() + 5
            console.error "horizontal stack distribution overflowed its allocated width by " + (childLeft - newBoundsForThisLayout.right())
   ```
7. Rename the cryptic `ssss` (:4219–4222, used again :4239) → `fillByDesiredFraction` (it is the case-3 "no
   max-margin ⇒ redistribute the leftover ∝ desired width" switch: 0 when `maxMargin > 0`, 1 when `maxMargin == 0`).
   Three occurrences, same method, plain find-replace.
8. *(Optional, comment hygiene)* delete the commented-out freefloating early-return block (:4095–4097) and the stale
   "TODO should we do a fullChanged here?" musing (:4099–4101).
**Scope note.** The OTHER bare `debugger`s in `Widget.coffee` (:998, the :1101–:1189 cache-check region, :2581
serialization) and `WorldWdgt.coffee` (:688, :717, :731, :1487) are **not** layout code — LEAVE THEM; they belong to a
general OO pass (Appendix X4).
**Risk / gate.** Log/name-level edits in a dev-build-only block. Build + (end-of-tier) suite.

### A3 — Delete the dim-cache scaffolding (it is a trap, not a dormant optimization)
**What.** `getRecursiveDesiredDim` / `getRecursiveMinDim` / `getRecursiveMaxDim` (`Widget.coffee` :3932–4036) each
write a cache they never read: the reads are commented out ("TBD the exact shape of …") while the flag + cache writes
run every call.
**Why (the sharp part).** **Nothing anywhere resets the `check*DimCache` flags** (grep: zero writers besides the three
`= true` sites), so uncommenting the reads as scaffolded would serve **permanently stale** sizes after the first
query. It is a loaded gun for a future editor, plus two dead field-writes per call. Do NOT confuse these with the
`__breakMoveResizeCaches` bounds caches — those are LIVE and out of scope.
**If the re-walk ever matters.** The three queries are mutually recursive (desired→max→desired via `getMaxDim`'s
clamp) with no memoization — fine at the shallow horizontal-stack depths in actual use. If a profile ever shows it
hot, the correct tool is a **flush-scoped memo** (keyed per `_recalculateLayoutsBody` run, no invalidation protocol
needed) — build it then, not now.
**How.** Done together with A4 — the complete replacement bodies are in A4's *How* below (they ARE the edit for both
items).
**Risk / gate.** Deleting lazily-created instance fields can shift an inspected member list — the §0.5 benign-recapture
protocol covers it. End-of-tier gauntlet.

### A4 — Fix the unreachable child-height accumulation in `getRecursiveDesiredDim` (inert bug)
**What.** :3939–3948: `desiredHeight` is initialised to `nil`, and the accumulation guard is
`if desiredHeight < childSize.height()` — but `undefined < h` is **always false** in JS, so the branch (including its
own `if !desiredHeight? then desiredHeight = 0`) is unreachable, and `desiredHeight` always falls through to the
`@desiredHeight` fallback. Its sibling `getRecursiveMinDim` does this correctly (init 0 + a `gotAMinHeight` flag).
**Why it is pixel-invisible today (and why fix it anyway).** Every consumer of the min/desired/max lattice reads only
`.width()`: the 3-case distribution (`Widget.coffee` :4156, :4186–4188, :4211–4213, per-child :4175, :4196–4197,
:4230–4231) and the divider drag (`StackElementsSizeAdjustingWdgt.coffee` :42–43, :59, :79–80 — all `.x`). Heights
circulate only among the three queries' cross-clamps and never exit. So the fix is byte-identical **today** — and that
is precisely the window in which to defuse it, before some future consumer reads a height and inherits the landmine.
**How (exact edits — replaces A3+A4 in one go).** Replace the three methods **wholesale** (everything from the
`getRecursiveDesiredDim:` line at :3932 through the end of `getRecursiveMaxDim` at :4036) with exactly:
```coffee
  # NB the .height() halves of the three getRecursive*Dim queries are currently CONSUMED NOWHERE outside the
  # queries' own cross-clamps -- every external reader takes .width() only (the horizontal 3-case distribution
  # in Widget._reLayout, and the stack-divider drag). Kept correct anyway: desiredHeight used to init to nil,
  # and `nil < h` is always false in JS, so the child-height max never accumulated (fixed with the dim-cache
  # scaffolding removal -- the caches were written but never read, and NOTHING ever reset their check-flags,
  # so enabling the commented-out reads would have served permanently stale sizes).
  getRecursiveDesiredDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0

    desiredWidth = nil
    desiredHeight = 0
    gotADesiredHeight = false
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C.getDesiredDim()
        if !desiredWidth? then desiredWidth = 0
        desiredWidth += childSize.width()
        if desiredHeight < childSize.height()
          gotADesiredHeight = true
          desiredHeight = childSize.height()

    if !desiredWidth?
      desiredWidth = @desiredWidth

    if !gotADesiredHeight
      desiredHeight = @desiredHeight

    return (new Point desiredWidth, desiredHeight).min @getRecursiveMaxDim()


  getRecursiveMinDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0

    minWidth = 0
    minHeight = 0
    gotAMinWidth = false
    gotAMinHeight = false
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C.getMinDim()
        gotAMinWidth = true
        minWidth += childSize.width()
        if minHeight < childSize.height()
          gotAMinHeight = true
          minHeight = childSize.height()

    if !gotAMinWidth
      minWidth = @minWidth

    if !gotAMinHeight
      minHeight = @minHeight

    # the user might have forced the "desired" to
    # be smaller than the standard minimum set by
    # the widget
    return (new Point minWidth, minHeight).min @getRecursiveMaxDim()

  getRecursiveMaxDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0

    maxWidth = 0
    maxHeight = 0
    gotAMaxWidth = false
    gotAMaxHeight = false
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C.getMaxDim()
        gotAMaxWidth = true
        maxWidth += childSize.width()
        if maxHeight < childSize.height()
          gotAMaxHeight = true
          maxHeight = childSize.height()

    if !gotAMaxWidth
      maxWidth = @maxWidth

    if !gotAMaxHeight
      maxHeight = @maxHeight

    # the user might have forced the "desired" to
    # be bigger than the standard maximum set by
    # the widget
    return new Point maxWidth, maxHeight
```
**Done-check.** `grep -c "DimCache" src/basic-widgets/Widget.coffee` → `0`. Then `./fg build`.
**Risk / gate.** End-of-tier gauntlet (byte-identical expected per the consumption census above).

### A5 — Fix the `"enter"` → `"center"` typo in `VerticalStackLayoutSpec`
**What/Why.** `_setAlignmentToCenterNoSettle` (`VerticalStackLayoutSpec.coffee` :88–91) guards on
`if @alignment isnt "enter"` — so the already-in-this-state guard the block comment above (:55–66) promises has never
worked for center: re-centering an already-centered element re-invalidates and re-settles for nothing. Pixel-invisible
(the settle converges to the same layout either way; the menu even hides "align center" when already centered).
**How.** One character. Before: `if @alignment isnt "enter"` → After: `if @alignment isnt "center"`.
**Risk / gate.** Build + (end-of-tier) suite.

### A6 — Collapse `_applyExtentAndNotify`'s dead parameter; make the base a pass-through; dedup the double cache-breaks
**What (three sub-items, one method family).** (1) `Widget._applyExtentAndNotify`'s second parameter
`widgetStartingTheChange` is passed by no caller — its guard and never-read assignment are dead. (2) With those gone,
its body is identical to `_applyExtent` — reduce the base to a pass-through, mirroring how base
`_applyMoveByAndNotify` (:1229–1230) already is one. (3) Four methods break the move/resize caches immediately before
delegating to a callee that breaks them again — remove the outer, redundant break.
**Pre-flight verify-greps (run both; expected results shown).**
```sh
# 1) no two-arg callers of _applyExtentAndNotify anywhere (every call passes one Point):
grep -rn "_applyExtentAndNotify" src --include="*.coffee" | grep -vE "_applyExtentAndNotify:" | grep -E "_applyExtentAndNotify.*(Point|extent|\().*," | grep -vE "new Point [^,]+, [^,)]+\)?$|new Point\("
#    -> inspect any hits by eye: the comma must belong to `new Point a, b`, never to a 2nd argument.
# 2) the bare twin has NO overrides (must print exactly ONE line, in Widget.coffee):
grep -rn "^\s*_applyExtent:" src --include="*.coffee"
```
**How (exact edits).**
1. Replace `Widget._applyExtentAndNotify` (:1519–1536; after A1 its dead block is already gone) — the whole method,
   including the guard lines `if @ == widgetStartingTheChange` / `if !widgetStartingTheChange?` and the duplicated
   commit+changed+relayout body — with:
   ```coffee
     # The polymorphic extent-apply -- the override DISPATCH POINT (SimpleVerticalStackPanelWdgt / ScrollPanelWdgt /
     # TextWdgt / SliderWdgt / ListWdgt / the stretchables specialize it). The base is a pure pass-through to
     # _applyExtent, exactly like _applyMoveByAndNotify -> _applyMoveBy: ONE body per behaviour, two names for
     # dispatch (the bare twin is the override-BYPASSING base apply the top-down arrange uses). "AndNotify" is
     # historical -- the notify seam was deleted 2026-07-01, nothing notifies; truthful rename planned
     # (docs/layout-optimizations-and-oo-cleanup-plan.md §3).
     _applyExtentAndNotify: (aPoint) ->
       @_applyExtent aPoint
   ```
2. Update the now-stale comment above `_applyExtent` (:1585–1591 — it says "the same body as
   Widget::_applyExtentAndNotify minus its widgetStartingTheChange guard"). Replace that comment block with:
   ```coffee
     # Base extent-apply WITHOUT the polymorphic override: commit @bounds + @changed repaint + @_reLayoutSelf. THE
     # single body of the extent-apply pair -- the polymorphic _applyExtentAndNotify base is a pure pass-through to
     # this. A container arranging a child top-down uses this to apply the child's measured extent while BYPASSING
     # the child's own _applyExtentAndNotify override (e.g. SimpleVerticalStackPanelWdgt applies its arranged height
     # via _applyExtent so it does NOT re-enter its own _reLayoutChildren -- the frame commit that follows handles
     # that). The re-fit seam this pair used to differ on is gone (2026-07-01); the override-bypass keeps the two
     # NAMES distinct.
   ```
3. `SimpleVerticalStackPanelWdgt.coffee` :127 and :131 — the explicit base-calls become plain bare-twin calls:
   ```coffee
   # before (:127):  Widget::_applyExtentAndNotify.call @, new Point(newWidth or 0, @height())
   # after:          @_applyExtent new Point(newWidth or 0, @height())
   # before (:131):  Widget::_applyExtentAndNotify.call @, new Point(@width(), newHeight or 0)
   # after:          @_applyExtent new Point(@width(), newHeight or 0)
   ```
   (Equivalent by the pre-flight greps: `_applyExtent` has no overrides, so `@_applyExtent` IS the base body. Update
   the adjacent comment if it names the old `.call` form.)
4. Sub-item 3, the double breaks — final bodies (after A1 removed their dead blocks/breadcrumbs):
   ```coffee
     _applyWidthAndNotify: (width) ->
       @_applyExtentAndNotify new Point(width or 0, @height())

     _applyHeightAndNotify: (height) ->
       @_applyExtentAndNotify new Point(@width(), height or 0)

     _applyMoveTo: (aPoint) ->
       aPoint.debugIfFloats()
       delta = aPoint.toLocalCoordinatesOf @
       if !delta.isZero()
         @_applyMoveBy delta
       @bounds.debugIfFloats()

     # this one actually immediately changes the position and
     # bounds of widgets
     _applyMoveToAndNotify: (aPoint) ->
       aPoint.debugIfFloats()
       delta = aPoint.toLocalCoordinatesOf @
       if !delta.isZero()
         @_applyMoveByAndNotify delta
       @bounds.debugIfFloats()
   ```
   (The change in each: the `@__breakMoveResizeCaches()` line that preceded the delegation is gone — the callee
   breaks the caches itself, under its own did-anything-change guard. Do not touch the overrides of
   `_applyWidthAndNotify` in `MenuHeader`/`StringFieldWdgt` — base-only edit.)
**⚠ The sub-item-3 caveat.** `__breakMoveResizeCaches` increments `WorldWdgt.numberOfRawMovesAndResizes`, which is a
**cache version key** (§1) — so the dedup makes the clipped-bounds caches invalidate *less often* (only on actual
change). That is the correct discipline (a no-change apply invalidates nothing), and cache misses only cost recompute,
never values — but it is exactly the kind of change the gauntlet + short torture must clear. **If any flake appears,
drop sub-item 3 alone** (restore the pre-delegation `@__breakMoveResizeCaches()` lines; keep sub-items 1–2).
**Risk / gate.** Immediate-mutator family → end-of-tier `./fg gauntlet` + the §0.5 short torture.

### A7 — Stack `@padding`: stop mutating configuration inside the arrange
**What/Why.** `SimpleVerticalStackPanelWdgt._positionAndResizeChildren` hard-resets `@padding = 5` at the top of
**every** arrange pass (:213), yet `@padding` is a **constructor parameter** (:61) — so a custom padding could never
survive the first arrange. No caller passes one anyway (§1 census), making the arrange line a de-facto initializer in
the wrong place. A default parameter is the safe fix: CoffeeScript defaults fire on both `undefined` and `null` (§1),
so even the one explicit-`null` caller gets 5, identically to today.
**How (exact edits, `SimpleVerticalStackPanelWdgt.coffee`).**
1. :61 — Before: `constructor: (extent, color, @padding, @constrainContentWidth = true) ->`
   After: `constructor: (extent, color, @padding = 5, @constrainContentWidth = true) ->`
2. :213 — delete the line `@padding = 5` (first line of `_positionAndResizeChildren`; leave the rest of the method).
3. :293–297 — rename the local `moveTo` (it shadows the `moveTo` method name). Before:
   ```coffee
         moveTo = new Point leftPosition, @top() + verticalPadding + stackHeight
         if widget._reLayoutChildren?
           widget._applyMoveToAndNotify moveTo
         else
           widget._applyMoveTo moveTo
   ```
   After: same lines with `moveTo` → `targetPos` (3 occurrences; do NOT rename the `_applyMoveTo*` method calls).
**Subclass safety (verified, §1).** `WindowWdgt` has its own constructor signature and assigns `@padding = 5` itself
(:101) — unaffected. `SimpleDocumentPanelWdgt` inherits and is fine with the default. Bonus: this closes the
pre-first-arrange window where the pure measure (`preferredExtentForWidth`, :143 `availW - 2 * @padding`) computed
with an undefined padding.
**Risk / gate.** Touches an arrange → end-of-tier `./fg gauntlet` + the §0.5 short torture (byte-identical expected:
post-first-arrange the value is 5 either way, and no caller ever passed a custom padding).

### A8 — Repair the stale sections of `layering-naming-convention.md` (doc-only; wrong TODAY, independent of Tier B)
**What.** Three places in the convention doc contradict the tree at `06b1ae53` (its §2.2 post-seam-deletion note was
updated at the twin collapse, but these were missed):
- **§2.6 presents the deleted seam as live** — "The re-fit seam — one announce verb (**mechanism unchanged**)" /
  "proven irreducible", listing `_announceGeometryChangeToContainer` / `_announceLayoutPropertyChangeToContainer` as
  the current mechanism. Both verbs were **deleted 2026-07-01** (the settle-time up-edge replaced them), and lint rule
  **[N]** now **BANS re-defining those very names** — the doc instructs the reader to build a shape the build rejects.
  Rewrite §2.6 around the up-edge: after a chain-top settles, the settle loop calls
  `_reFitMyTrackingContainerAfterSettle`, which dispatches through the kept `_reFitContainer` valve (in-pass →
  `__markForRelayout`, off-pass → `_invalidateLayout`) into the container's `_reLayoutChildren`. **Before writing,
  read `layout-system-architecture-assessment.md` §2.3 and §4.1** — they are the canonical description; mirror them,
  do not improvise. The third listed verb, `_reflowContainedTextThenAnnounce`, IS still live (`StringWdgt` :992 + ~7
  more sites) — keep it listed, but note its "Announce" tail now means the dirty-tree climb (a Tier B rename rider,
  §3).
- **§2.5 lists `_settleLayoutsAfterBatch` as a live settle tier** — deleted 2026-07-01, zero callers. Trim §2.5 to
  `_settleLayoutsAfter` only, with a one-line "batch tier deleted 2026-07-01; reintroduce from git history if ever
  needed" note.
- **§0 ("What this is NOT") and §4 describe the rule list as [A]–[M]** — rule **[N]** exists (Opt-4, §6 below).
  Update the ranges, and annotate the [K] row: its anti-seam half is vacuous post-deletion (kept only as
  belt-and-braces beside [N]) until Tier B re-derives the rule (§3).
**Why now, not inside Tier B.** These statements are wrong regardless of whether the rename ever happens — a newcomer
following §2.6 today would fail the build on rule [N]. Tier B then *rewrites* what A8 has first made *true*.
**Risk / gate.** Doc-only; no runtime gate. Cross-read the rewrite against assessment §2.3/§4.1 for consistency.

---

## §3 — Tier B: the `*AndNotify` truthful-name rename (owner sign-off on names FIRST)

> **Cold-session guard: DO NOT START Tier B unless the owner's instructions for the session explicitly state the
> chosen name pair AND the meaning-swap decision (⚠ below).** Absent that, Tier B is not runnable — stop after Tier A.

**The wart.** Since the 2026-07-01 seam deletion, **nothing in the `_apply*AndNotify` family notifies anything** — the
announce-verbs are deleted and the immediate mutators are pure geometry (assessment §2.3/§4.1). The suffix now asserts
a mechanism that does not exist, **on the most-called API in the layout system**. The real, live distinction the pair
encodes is:

- **`_apply*AndNotify`** = the **polymorphic apply** — the override dispatch point. Live overrides:
  `_applyExtentAndNotify` ×9 (`StretchablePanelWdgt` :25, `StretchableEditableWdgt` :90,
  `SimpleVerticalStackPanelWdgt` :316, `StretchableCanvasWdgt` :101, `ListWdgt` :128,
  `StretchableWidgetContainerWdgt` :98, `TextWdgt` :471, `SliderWdgt` :66, `ScrollPanelWdgt` :266);
  `_applyWidthAndNotify` ×2 (`MenuHeader` :34, `StringFieldWdgt` :39); `_applyMoveByAndNotify` ×2
  (`ActivePointerWdgt` :706, `ClippingAtRectangularBoundsMixin` :228).
- **bare `_apply*`** = the **base apply, override-bypassed** — defined only on `Widget`, used by the top-down arrange
  precisely to skip the subclass specialization (the §4.2 non-notifying-twin story, whose *seam* half is now moot but
  whose *dispatch* half is load-bearing — the reason the move twins were found NOT collapsible, §6 twin-collapse
  record).

**Size (corrects the twin-collapse record's estimate).** The collapse entry deferred this rename citing "~100 call
sites + ~10 overrides"; the real count at `06b1ae53` is **~590 textual occurrences across ~115 files**:
`_applyExtentAndNotify` 280, `_applyMoveToAndNotify` 225, `_applyBoundsAndNotify` 38, `_applyWidthAndNotify` 23,
`_applyMoveByAndNotify` 12, `_applyHeightAndNotify` 10 (defs + calls + comments; re-enumerate in-session with
`grep -rno "_apply\w*AndNotify" src --include="*.coffee" | awk -F: '{print $NF}' | sort | uniq -c`). Bigger — but
purely mechanical, with the fourth-wave naming-campaign playbook and the lint/gate machinery to hold it.

**Name proposal (owner to confirm or override before any edit).** Give the clean name to the common polymorphic form
and a `Base` marker to the bypass twin:
- `_applyExtentAndNotify` → `_applyExtent` · `_applyMoveToAndNotify` → `_applyMoveTo` ·
  `_applyMoveByAndNotify` → `_applyMoveBy` · `_applyBoundsAndNotify` → `_applyBounds` ·
  `_applyWidthAndNotify` → `_applyWidth` · `_applyHeightAndNotify` → `_applyHeight`
- bare `_applyExtent` → `_applyExtentBase` · `_applyMoveBy` → `_applyMoveByBase` · `_applyMoveTo` → `_applyMoveToBase`
  (suffix bikeshed open: `*Base` vs `*Uniform` vs the Smalltalk-ancestry `_basicApply*` — Morphic heritage, where
  `basic*` is precisely "the non-overridable primitive"; the docs already describe the bare twin as "the uniform base
  translate").
- **Rider:** `StringWdgt._reflowContainedTextThenAnnounce` (def + ~8 sites) — its "Announce" tail names the deleted
  mechanism too (the body now ends in the dirty-tree climb); rename in the same sweep (e.g.
  `_reflowContainedTextThenInvalidateLayout`).

**⚠ The meaning-swap hazard (part of the sign-off, not a detail).** The proposal RE-USES live names with a different
meaning: bare `_applyExtent` / `_applyMoveBy` / `_applyMoveTo` today name the **bypass** corner, and would come to
name the **polymorphic** form. The `(né …)` history convention expresses *renames*, not *meaning swaps* — after the
sweep, an older memory / plan / git-history hit reading `_applyExtent` silently means the OTHER method. The two-step
procedure below is mechanically swap-safe; the residual risk is historical/human. Options:
- **(a) accept the swap (recommended):** the common form (~517 of ~590 uses) gets the clean name; record an explicit
  **"MEANING SWAPPED 2026-07-xx"** ledger line in the assessment §5 code map AND in the convention doc's Family-1
  table — a plain `(né …)` entry is NOT sufficient here.
- **(b) no-reuse scheme:** leave the bare names untouched (they keep meaning the bypass corner) and rename only the
  `*AndNotify` side to a fresh, non-colliding name. Swap-free history — but every candidate fresh name for the
  polymorphic form is worse forever (`_applyExtentOverridable`-class ugliness; `full*` is reserved subtree
  vocabulary, rule [M] note), which is why (a) is recommended.

**Convention-doc impact — Tier B rewrites Family 1 of `layering-naming-convention.md`, it does not just touch it.**
That doc organizes the whole geometry-apply family as a NOTIFY × REACT 2×2 whose NOTIFY axis IS the `…AndNotify`
suffix (its §2.1–2.2) — and its own post-seam-deletion note already concedes the axis is dead ("the suffix no longer
notifies … keep … for now"). Dropping the suffix therefore retires an **axis** of the doc's central scheme, not a row
of its table:
- **§2.1–2.2 rewrite:** the lattice becomes REACT (`commit*` vs `apply*`) × **DISPATCH** (polymorphic vs `*Base`
  bypass), the new axis carrying its own statically-checkable negatives: a `*Base` twin must not call its polymorphic
  sibling (the override-bypass invariant — today [K]'s "an arrange `_apply*` must not call an `*AndNotify`"), and
  **only `Widget` defines a `*Base`** (no subclass overrides — that is the point of the bypass twin; new lint-able
  shape).
- **Rule [K] re-derivation** (`buildSystem/check-layering.js`): of [K]'s two negatives, the anti-seam half and the
  `_commit*AndNotify` half are ALREADY vacuous (seam deleted; corner collapsed — A8 annotates this) — the surviving
  load-bearing half is exactly the override-bypass invariant, re-derived in the new names.
- **§5.1 audit re-derivation:** `auditTierAndApplyNaming` wraps the deleted `_announce*` seam and reports
  "`*AndNotify` corners reaching the seam" as its informational metric — both halves dead post-seam. Re-derive the
  audit + its self-test around the new negatives (the tier-naming gate rides `fg gauntlet`, so a stale wrap list
  fails loudly rather than silently passing).

**Procedure (swap-safe two-step; A6 first shrinks the surface).**
1. **Step 1 — vacate the bare names:** rename the 3 bare twins → `*Base` (small population: definitions + the
   arrange/scroll/stack call sites; enumerate in-session with `grep -rn "_applyExtent\b\|_applyMoveBy\b\|_applyMoveTo\b"
   src --include="*.coffee"` and update every hit). `./fg build` + `./fg suite` green before proceeding.
2. **Step 2 — drop the suffix:** rename all `_apply*AndNotify` → the vacated bare names, overrides included
   (mechanical global replace per name, then `grep -rn "AndNotify" src --include="*.coffee"` must return only
   deliberate history comments, ideally zero).
3. **Same commits, collateral:** `buildSystem/check-layering.js` — the `isImmediateMutator` predicate (:141) must
   track the new lattice, rule **[K]** is re-derived (not re-spelled) per the convention-doc impact block above, and
   `AndNotify` joins the rule-[M] retired-fragment ban (exactly as `silent*`/`raw*`/`fullRaw` were banned) so the old
   suffix cannot come back; confirm rule [N] unaffected. Re-derive `WorldWdgt.auditTierAndApplyNaming` (~:117) + its
   gate prelude/self-test (same block). **Rewrite** `layering-naming-convention.md` Family 1 (§2.1–2.2 axes, [K] row,
   §5.1) — on top of A8's repair, which must land first. Update the assessment's §5 code map: `(né …)` entries for
   the pure renames PLUS the explicit **meaning-swap ledger line** for the re-used bare names (a né entry alone
   cannot express a swap).
4. **Cross-repo grep (the relocation-gotchas lesson):** grep `Fizzygum-tests` **`.js` included** for every renamed
   symbol — macro tests reach framework methods via `world.<m>()` and a `.coffee`-only grep misses them:
   `grep -rn "AndNotify\|_applyExtent\|_applyMoveBy\|_applyMoveTo" ../Fizzygum-tests --include="*.js" --include="*.coffee"`.
**Expected fallout.** Renaming inspector-visible `Widget` methods shifts the inspector member list →
`macroDuplicatedInspectorDrivesCopiedTargetOnly` recaptures (benign, pre-authorised — §0.5 protocol). Otherwise
byte-identical.
**Risk / gate.** Pure rename; `./fg gauntlet` after each step. No torture needed (no logic change) — but cheap
insurance to run one round after step 2 since the diff is wide.

---

## §4 — Tier C (✅ GREENLIT — do it NEXT session): coalesce the resize/move handle drags

> **Status (2026-07-02): APPROVED by the owner. The measurement gate ran (below) and the owner elected to PROCEED.**
> Scheduled for a dedicated next session; NOT yet implemented. The whole change is ONE commit: the four `*Coalesced`
> entrypoints + the switched handle arms + the caller-allowlist static guard (all required together).

**What.** `HandleWdgt.nonFloatDragging` (`HandleWdgt.coffee` :252–269) issues one self-settling public setter per drag
event (`setExtent` :261 / `moveTo` :263 / `setWidth` :265 / `setHeight` :269, mutually exclusive by handle type) — so N
drag events landing in one heavy frame cost N full settles of the target subtree. The established remedy is a
**declared coalesced entrypoint** per stream (the `setMaxDimCoalesced` precedent — `Widget.coffee` :3769-3773 →
`_coalescedDeclare` :3779 → the `_<x>NoSettle` core; assessment §2.7): add `setExtentCoalesced` / `moveToCoalesced` /
`setWidthCoalesced` / `setHeightCoalesced` and switch the four `nonFloatDragging` arms to them. Each new twin mirrors
`setMaxDimCoalesced` verbatim — `if world?.coalescingEnabled then @_coalescedDeclare => @<core> else @<publicSetter>`.
**FIRST implementation step:** read each public setter's `_settleLayoutsAfter => <core>` body (`setExtent` etc. are the
5 inline-thunk pure-geometry setters, assessment §5) to identify the core to wrap, and confirm it invalidates for the
end-of-cycle flush the way `_setMaxDimNoSettle`'s `@_invalidateLayout()` (:3800) does — since Tier B the extent core is
the polymorphic `_applyExtent`, so verify its reaction reaches the end-of-cycle settle before wiring the coalesced twin.

**Why it is sound.** Render happens once per frame after all events, so coalesced-vs-self-settle is byte-identical by
construction; and the handler's arithmetic reads only the mouse position + geometry the gesture does not mutate
(`@target.position()`/`@extent()`/`@bounds` under a resize — set SYNCHRONOUSLY by the apply core, NOT by the deferred
settle; the fixed grab-offset under a move) — no read of the target's *settled layout* between events, so deferring the
settle cannot skew the stream.

**Measurement (2026-07-02 — `coalescing-measure/` + a frame-time prelude, on `macroNakedInspectorRendersResizesAndEdits`,
a heavy inspector-window resize-handle drag).** 1 setter per move (mutually-exclusive arms) ⇒ muts/frame ≈ moves/frame,
bursty: at **normal** speed median 2 but a ~4-frame opening burst to **40/frame**, over a **44-widget** settle. Wall-ms
of the self-settles coalescing would collapse: **peak ~9 ms in one frame** at normal (~12 ms at fastest), tapering to
<1 ms/frame; with coalescing that peak frame drops to ~1 flush ≈ 0.2 ms. 9 ms is ~half a 60fps budget (no dropped frame
on the dev box) and scales ~linearly with target size — a resize re-settling ~80+ widgets, or a slower machine, reaches
a dropped frame at drag start. **Decision: PROCEED** — the settle-count collapse is proven-cheap (the `setMaxDim`
precedent) and the win grows with heavier resizable content.

**REQUIRED — the `*Coalesced` caller-allowlist STATIC guard (same commit).** TODAY there is NO check that a `*Coalesced`
method is only called from a per-event stream: the `_coalescedDeclarationDepth` / `auditUndeclaredEndOfCycle` machinery
(`WorldWdgt` :90-98, `Widget` :3713) enforces the CONVERSE — that end-of-cycle mutations are *declared* — and treats any
`*Coalesced` call as auto-declared regardless of caller. Since `*Coalesced` defers only the LAYOUT SETTLE (the field
write is synchronous), it is unsound only for a caller that reads back the *settled* layout within the cycle — which a
discrete/programmatic caller might, and a stream handler never does. So add a `check-layering.js` rule: a call matching
`[@.]\w+Coalesced\b` may appear ONLY inside a method whose name is in a small `COALESCED_CALLER_ALLOWLIST` (the stream
handlers: `nonFloatDragging`, the wheel/scroll handler, any key-repeat handler); a call from any other method is a
violation. It drops into the existing per-method call-scanning shape ([K]/[F]/[G]) and is `@`-self / `.`-receiver scoped
(sufficient — the callers are always direct). Seed the allowlist with `StackElementsSizeAdjustingWdgt.nonFloatDragging`
(the existing caller) + `HandleWdgt.nonFloatDragging` (this tier's new callers). *(A dynamic twin — a
`_dispatchingInputEvent` boolean set around `playQueuedEvents`'s per-event dispatch, asserted in a prelude, keyed off
`WorldWdgt.timeOfEventBeingProcessed` :80 — is possible but heavier and only covers dynamic dispatch the direct pattern
lacks; the static rule is the ask.)*

**Risk / gate.** Byte-identical by construction, but the diff touches the drag stream → `./fg gauntlet` + the full
danger torture; expect no recapture. The static guard is build-time (`./fg build` — verify it FAILS a planted
out-of-allowlist `*Coalesced` call, then passes clean).

---

## §5 — Verification (per tier; commands and pass-criteria in §0.5)

- **Tier A** (one batch): `./fg build` after every item; at the end `./fg gauntlet` (dpr1/dpr2/webkit 165/165 +
  apps/tiernaming/settle) **plus** the §0.5 four-config short torture (`RECALC_NONCONVERGENCE` absent + 0 fails) —
  needed because A6/A7 are mutator/arrange-adjacent. A6 sub-item 3 is droppable alone on any flake. Benign inspector
  recaptures pre-authorised per §0.5 (A3 field deletions, if the member list shifts). A8 is doc-only — no runtime
  gate; review it against assessment §2.3/§4.1.
- **Tier B**: `./fg gauntlet` after each of the two rename steps; expect the benign inspector recapture; one torture
  round after step 2 as insurance.
- **Tier C** (next session): measurement already done (§4). One commit = 4 `*Coalesced` entrypoints + switched handle
  arms + the caller-allowlist static guard; `./fg build` (guard: plant an out-of-allowlist call → must fail, then clean)
  + `./fg gauntlet` + full danger torture; expect no recapture.
- **Ask before commit/push**; `git commit -F <file>` (§0.5 commit protocol).

## §6 — Landed record (2026-07-01 → 07-02, all committed; kept for cold-runnability)

- **Opt-2 — freefloating walk-up TODO ✅ (`06b1ae53`).** The settle loop's walk-up now climbs while the parent is
  invalid and stops at the LAST-invalid widget (`WorldWdgt._recalculateLayoutsBody` :984), so a freefloating child is
  no longer laid out first against a stale parent size and again after — the long-standing TODO, implemented.
  Byte-exact (gauntlet ×3 engines + danger torture, 0 recaptures). Sound because the settled layout is an
  **order-independent fixpoint** (the Opt-1 probe's durable result, Appendix X1).
- **Twin collapse ✅ (`8aefa53f`).** `_commitExtentAndNotify` folded into the `__commitExtent` leaf;
  `_commitBoundsAndNotify` + `_applyBounds` folded into one `_commitBounds`. The **move twins are NOT collapsible**:
  `_applyMoveByAndNotify` is the polymorphic dispatch point for the `ClippingAtRectangularBoundsMixin` /
  `ActivePointerWdgt` overrides (repaint via `@changed`, not `@fullChanged`), bare `_applyMoveBy` the uniform base
  translate — merging would reroute arrange moves through the overrides. Byte-identical; gauntlet + torture. *(Its
  "~100 call sites" estimate for the deferred `*AndNotify` rename is corrected — ~6× under — in §3.)*
- **Opt-4 → lint rule `[N]` ✅ (2026-07-01).** The sound both-direction-edge lint was found infeasible in the
  line-scanner (cross-method data-flow signal); the narrow sound slice shipped instead:
  `SEAM_VERB_BANNED = /^_announce\w*ToContainer$/` at each method def bans reviving the deleted seam verbs (DEF side;
  CALL side already covered by [I]/[K]). Verified with an injected dummy def; 0 false positives.
- **OO-1 — seam comment-residue prune ✅ (2026-07-01).** 15 → 6 mentions; 4 were misleading-stale (asserted a deleted
  method as the live mechanism) and were corrected to the real dirty-tree/up-edge story; survivors are the canonical
  mechanism docs.
- **OO-3 — dead-code sweep ✅ (confirm-only, 2026-07-01).** Nothing to delete: `_reFitContainer` has ~9 callers with
  both dispatch arms live; `_amIDirectlyInsideNonTextWrappingScrollPanelWdgt` used by `WindowWdgt` ×2 + the up-edge;
  `_batchingLayoutSettling` fully gone; dead-methods gate 0 new.
- **Tier A ✅ (`3218fb7a` + `cf3dbaa8`, 2026-07-02).** Items A1–A8 (§2): dead-block/breadcrumb deletion,
  horizontal-distribution debug cleanup, dim-cache scaffolding removal + the child-height fix, the `"enter"`→`"center"`
  typo, `_applyExtentAndNotify`→pass-through + double-break dedup, the stack `@padding` default-param, and the
  `layering-naming-convention.md` §2.5/§2.6/[N] repair. ~136 lines net deletion; byte-identical (gauntlet ×3 + torture,
  no recapture).
- **Tier B ✅ (`ad0bf5c7` + tests `c2ed1476`, 2026-07-02).** The `*AndNotify` truthful-name rename + **MEANING SWAP**
  (§3): the polymorphic `_apply*AndNotify` corners drop the suffix → bare `_apply*`, the override-bypass twins take a
  `Base` suffix → `_apply*Base`, rider `_reflowContainedTextThenAnnounce` → `_reflowContainedTextThenInvalidateLayout`.
  `check-layering.js` [K] re-derived to the surviving override-bypass negative (a `*Base` must not fire the container
  re-fit nor dispatch to its polymorphic `_apply*` sibling); `_apply*AndNotify` joins the [M] retired-fragment ban; the
  runtime tier-naming prelude's classifiers re-derived; convention-doc Family 1 rewritten to REACT×DISPATCH; assessment
  §5 code map carries the explicit MEANING-SWAP ledger line (not a plain `(née …)`). 111 src files (+623/−622, pure
  rename); 11 benign inspector-member-list recaptures. Gauntlet dpr1/dpr2/webkit 165/165 + apps + tiernaming + settle
  green; dpr2-fastest-s8 torture clean, `RECALC_NONCONVERGENCE` absent.

## §7 — Recommended sequencing

1. **Tier A ✅ DONE (2026-07-02, `3218fb7a`+`cf3dbaa8`)** as one batch, in the §0.5 order
   (A1 → A2 → A5 → A3+A4 → A6 → A7 → A8); biggest legibility win per unit risk; ~136 lines net deletion; one gauntlet +
   short torture at the end.
2. **Tier B ✅ DONE (2026-07-02, `ad0bf5c7` + tests `c2ed1476`)** — the owner confirmed the name pair + accepted the
   meaning swap (§3 ⚠); ran after A6 (pre-shrank the surface) and A8 (de-staled the convention doc, which Tier B then
   rewrote). Two mechanical steps, each gated. See §6.
3. **Tier C ✅ GREENLIT (owner, 2026-07-02, measurement done)** — do it next session as ONE commit: the four
   `*Coalesced` entrypoints + the switched `HandleWdgt.nonFloatDragging` arms + the `*Coalesced` caller-allowlist static
   guard (`check-layering.js`). See §4 for scope, the frame-time numbers, and the guard spec.
4. Nothing else: the engine core needs no work (§1), and the Appendix items stay closed.

---

## Appendix — reassessed OUT (banked / falsified / ruled out / out of scope)

Kept verbatim-in-substance so the evidence is not re-derived. **Do not promote an item out of this appendix without
new evidence of the same weight that demoted it.**

### X1 — Opt-1: two-flag dirty tracking + walk-DOWN settle loop — **BANKED**
**Original pitch** (assessment §4.4): replace `layoutIsValid` + climb-and-enqueue with the browser/React pair
`needsLayout` + `hasDirtyDescendant`; O(1) enqueues; walk down from dirty roots; Opt-2 falls out free; closest thing
to structural convergence.
**⚠ FEASIBILITY FINDING (2026-07-02, fail-fast probe — reverted).** A ~2-line probe reversed the loop's processing
order (head-scan/FIFO for tail-scan/LIFO): **byte-exact 165/165 at dpr1/dpr2/webkit** ⇒ the settled layout is an
**order-independent unique fixpoint** — the durable result (it de-risked Opt-2 and any future order-level loop work;
now cited in the Opt-2 code comment). **BUT** the two-flag design itself is a **semantic flow-change, not a clean
refactor**: Fizzygum's `_invalidateLayout` climbs container-first (the chain-top arranges its subtree in one
`_reLayout`), whereas the React two-flag is child-first (ancestors get only `hasDirtyDescendant`; the container
re-arranges via the up-edge). Two honest builds, neither a win: **(C)** child-first = a rewrite of the invalidation
model, real breakage risk, byte-exactness only empirically checkable; **(B)** climb-keeping walk-down = the current
loop plus a flag whose CLEARING logic is a fresh bug surface — arguably *more* complex.
**2026-07-02 reassessment adds:** `__markForRelayout` already pushes only still-valid widgets (:3756–3758), so the
work-list is deduped and the "O(1) enqueue" gain is against an O(valid-ancestors) walk on shallow trees; Opt-2 — the
one concrete waste the two-flag would have subsumed — already shipped independently; and the loop, with Opt-2's
comment, is now short and legible. The flush is not a measured bottleneck. **Verdict: stays BANKED.** If ever
revisited, do (C) empirically (gauntlet is the gate) and abandon on any non-byte-exact.

### X2 — Opt-3: flush-count hygiene in multi-mutation handlers — **RETIRED (premise falsified 2026-07-02)**
**Original pitch** (assessment §4.6): a handler doing several geometry mutations self-settles once each; prefer the
compound `setBounds` (one flush) over `setExtent` + `moveTo` (two); "start at `HandleWdgt.nonFloatDragging`".
**Falsification.** The named exemplar is a **`switch`** — each drag event executes exactly **one** public setter (the
four names are mutually exclusive arms, `HandleWdgt.coffee` :252–269), so there is nothing to compound. A code sweep
for methods actually calling two public geometry setters in sequence found only **cold one-shot builders**
(`WidgetFactory.setupTestScreen1`, `WorldWdgt.createErrorConsole` / `draftRunVideoPlayer`) — construction-time code
where the orphan guard already defers/frees the flushes and where a saved settle is noise. **There is no hot-path
multi-mutation handler in the tree.** The real per-frame item in this territory is the handle-drag **stream** (N
events/frame, each one flush) — which is a COALESCE question, not a compound-setter question, and lives as Tier C
(§4) with its measurement gate.

### X3 — assessment §4.3 "encapsulate the engine state in a `layoutEngine` object" — **RULED OUT (owner)**
The assessment §4.3 proposes moving the work-list + phase booleans + `_reFitContainer` dispatch into one
`world.layoutEngine` with a phase enum. **The owner has ruled this out** (the `proper-layouts-elimination-goal`
standing direction: relocating a boolean into an engine object is "bury it deeper," not the goal). The 2 remaining
phase booleans (`_recalculatingLayouts`, `_inLayoutMutation`) are load-bearing re-entrancy/dispatch flags, not
convergence devices; they stay where they are. Do not do §4.3.

### X4 — OO-2: general OO-smells backlog remnants — **out of scope (not layout)**
From the `oo-smells-backlog`: constant-naming "0b"; the `arg1..arg9` splat cleanup; the tiny optional 7f `GlassBox`;
Phase-8 opportunistic (the drifted unified-shadow offsets `4,4`/`5,5`/`7,7`/`6,6`). Pre-existing and orthogonal to the
layout arc — fold into a general OO pass on request. The non-layout `debugger` residue noted in A2's scope note
belongs there too. See `docs/oo-smells-refactoring-backlog.md` / `docs/god-class-decomposition-plan.md`.
