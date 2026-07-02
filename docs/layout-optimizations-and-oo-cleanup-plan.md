# Plan — layout optimizations + OO cleanup (post-seam-deletion)

**Status: REWRITTEN 2026-07-02 (third rewrite, night) after a THIRD code-level re-read of the engine at
Fizzygum master `85ba908e` (tree clean). Self-contained; runnable cold — an executor with NO prior context starts
at §0.5.** Tiers A–E are **all landed and committed** — Tier A (`3218fb7a`+`cf3dbaa8`), Tier B (`ad0bf5c7` + tests
`c2ed1476`), Tier C (`5a084e51` + tests `03d495d70`), Tier D (`fa4d95d7` + tests `8d3bfbf9b`), Tier E (`85ba908e`)
— their outcome records are kept in §5, and their per-item specs are pruned per this doc's convention (recover from
git history if ever needed; the Tier-D evidence bank likewise lives at `56f25c09` and earlier).

**This revision adds two NEW live tiers** from an owner-directed wart hunt ("find NEW warts; the resulting layout
engine should be efficient, clear and minimal code"): **Tier F** — behaviour-preserving code fixes (9 items, F1–F9,
ordered cheap→risky) — and **Tier G** — truth repairs (6 items, G1–G6: comments and docs that still describe deleted
machinery as live, plus a debug-residue sweep). Every item was checked against the Appendix (X1–X7), the falsified
list, and the assessment's "do not revisit" set — none is a re-proposal. Items reviewed on the same pass and
deliberately NOT selected are banked in the new **Appendix X8** so no future session re-derives them.

**⟢ UPDATE 2026-07-02 (LANDED + PUSHED to master — Fizzygum `cd8fc978`, tests `2a73a81b8`).** Tier F items
**F1, F2, F3, F4, F5, F7** and **all of Tier G (G1–G6)** landed. **G4 was ESCALATED by the owner** from a
comment-only marker repair into the actual **one-cadence-lag `_reLayout` FIX**: an audit of all 33 `_reLayout`
overrides found **11 SMELLY** (they positioned children from their OWN geometry before applying their own bounds,
so children lagged one cadence on a resize/move); each was FIXED to apply its bounds first (the
`FanoutWdgt`/`InspectorWdgt` shape). A **NEW build gate** `buildSystem/check-relayout-bounds-first.js` (wired in
`build_it_please.sh`) now FAILS the build on any `_reLayout` that reads own geometry before applying own bounds.
**F6 is folded in** — its 3 patch nodes were among the 11 fixed. Verified: gauntlet dpr1/dpr2/webkit 165/165 +
four-config torture (RECALC-0); the 11 fixes are steady-state byte-identical (0 recaptures) + 1 benign inspector
recapture (F7). **The ONLY live items remaining are F8 and F9.** Full record in §5.

## §0 — Why this now, and what it is NOT

The **proper-layouts mandate is complete** (see `layout-system-architecture-assessment.md` §1/§2.6/§4.1): the
notify-by-mutation seam was deleted 2026-07-01 and replaced by the settle-time up-edge; the convergence cap retired
to a never-fire assert; the `*AndNotify` rename made every immediate mutator's name truthful; Tiers A–E swept the
residue. **Nothing below is the mandate; all of it is optional polish** under the owner's standing quality bar:
*efficient, clear, minimal*.

The night re-read hunted specifically for classes of wart the earlier reassessments did not target:

- **Fragile mirrors** — the same formula hand-copied into a measure and its arrange, which MUST agree (F5 found a
  real parse-level divergence between the two copies, masked only by integer padding);
- **Known-bug patterns replicated in un-swept files** — the InspectorWdgt one-cadence-lag `_reLayout` shape, fixed
  in the inspector 2026-06-16, still present in three patch-programming nodes (F6);
- **The last container outside the settle architecture** — `ToolPanelWdgt` still has no wrapper/core split and a
  hand-rolled `dontLayout` batching flag (F9);
- **Duplication with a single-home fix** — the Slider re-layout couplet, the three `getRecursive*Dim` walkers,
  the five-constant corner-spec disjunction written twice, the four-counter cache key string-concatenated at ~15
  sites (F2, F7, F4, F8);
- **Comments/docs that lie about the live mechanism** — the stack arrange still documents the deleted seam as live
  and load-bearing; a throw message still uses the lint-[M]-banned "raw/silent setters" vocabulary; the macro
  docs teach a renamed-away API (G1–G5).

**Behaviour intent:** every Tier-F item is byte-identical-intended, with two flagged exceptions: **F6** can
legitimately shift mid-gesture pixels in a patch-node test (it *fixes* a lag — see the item's recapture note), and
**F9** could surface a latent flow-violation throw in an untested caller (the gates exist to catch exactly that).
Tier G is comment/doc-only except **G2**, which rewords one error-message string (behaviour-invisible; nothing greps
it — §1 fact 13).

**Determinism reminder:** anything touching the settle loop / `_reLayout` / an arrange / `_invalidateLayout` / the
up-edge / the geometry caches is a **convergence-or-cadence change** → the tier needs `./fg gauntlet`
(dpr1/dpr2/webkit) **and** the four-config danger torture (`RECALC_NONCONVERGENCE` absent + 0 fails), not just the
dpr1 suite. In Tier F that means **F6, F8 and F9** (and therefore the tier as a whole if any of them ran). See
assessment §6.4.

---

## §0.5 — Cold-execution protocol (READ THIS FIRST in a fresh session)

**The workspace.** `Fizzygum-all/` is an umbrella (NOT a git repo) holding three sibling git repos: `Fizzygum/`
(source — the ONLY place you edit code, always under `src/**/*.coffee`, plus `docs/*.md` and `buildSystem/`),
`Fizzygum-tests/` (the SystemTest suite + reference screenshots + audit tooling — no edits planned there in these
tiers, but recaptured reference images land there), `Fizzygum-builds/` (generated output — **never edit, never grep
from the workspace root**; it is ~1.3 GB). All build/test commands go through the **`./fg` wrapper at the umbrella
root** — it is cwd-correct from anywhere, kills zombie browsers, and gates on real exit codes. Do not hand-chain
`cd`s across repos.

**Baseline drift.** This plan's line numbers are exact at Fizzygum `85ba908e`. Before EVERY edit: `grep -n` the
method name (or a distinctive quoted fragment) in the named file and confirm the quoted "before" text matches what
is there. **The method name + the quoted code are authoritative; the line number is only a hint.** If a quoted
"before" does not match at all, STOP and report — do not guess. Some quoted blocks are shown without the file's
leading indentation — when applying, always reproduce the indentation the file actually uses at that spot
(CoffeeScript scoping depends on it). Within one file, apply a multi-edit item **from the
bottom of the file upward**, so the earlier line-number hints stay valid while you work.

**Scope discipline.** Make ONLY the edits an item's *How* block specifies. If a neighbouring line looks wrong,
note it in your end-of-tier report; do not fix it. Never edit anything under `Fizzygum-builds/`.

**CoffeeScript gotchas (this codebase — read all of these, they bite).**
- Indentation IS syntax — reproduce the exact leading spaces of the surrounding code (class methods are indented 2,
  bodies 4, nested bodies 6…). A mis-indented line silently changes scope.
- **The implicit-call trap:** `Math.round (a) + b` parses as `Math.round((a) + b)` (the space before the paren makes
  the whole expression the argument), while `Math.round(a) + b` (no space) rounds only `a`. This exact trap is the
  subject of item F5 — when writing arithmetic, always use the **no-space explicit call** form.
- `nil` means `undefined` (a Fizzygum global) — use it, never `null`/`undefined`, in any code you write.
- One class per file; the filename equals the class name. You are only editing INSIDE existing files here.
- A bare `for … in …` loop at the end of a method builds and returns a comprehension array — add an explicit
  `return` after such a loop when the return value is not meant (F9's `addMany` does this).
- The build syntax-checks every `.coffee` the fragmented way the browser compiles (trust `./fg build`, not your own
  `coffee -c` on a whole file).

**The per-item loop.** For each item: (1) run the item's pre-flight greps and confirm the expected results;
(2) apply the exact edits from the item's *How* block (use the Edit tool with exact quoted old/new text);
(3) run `./fg build` from the umbrella root — PASS = it prints `0 violations` and `done!!!` (≈1–2 min;
`./fg build --keepTestsDirectoryAsIs` is a faster variant fine for mid-tier iterations). Then move to the next
item. Run the suites only at the end of the tier — they are the expensive part.

**End-of-tier gates.** In order, from the umbrella root:
1. `./fg gauntlet` — build + full suite at dpr1 + dpr2 + webkit + apps smoke + the runtime audit gates.
   PASS = every leg tallies `PASS` (each suite leg = 165/165, `failed tests: 0`). Expect ≈10–15 min; announce an
   ETA and post progress every ~5 min if you are reporting to the owner live.
2. The **short danger torture** — required iff **F6, F8 or F9** ran in this session (skip after a comments-only or
   F1–F5/F7-only session). Run these four, one at a time:
   ```sh
   ./fg suite --dpr=2 --shards=8                 # config dpr2-fastest-s8
   ./fg suite --dpr=2 --shards=8 --speed=fast    # config dpr2-fast-s8
   ./fg suite --shards=8                         # config dpr1-fastest-s8
   ./fg suite --dpr=2 --shards=4                 # config dpr2-fastest-s4
   ```
   PASS per run = the `SUITE OK` banner, `failed tests: 0`, **and the string `RECALC_NONCONVERGENCE` appears
   nowhere in the output**. (dpr2 runs are heavy — several minutes each.)
3. **A run that stalls is a FAILURE even with 0 failed screenshots** — an uncaught error gives `completed:false`
   and a shard stall. Treat it as a real breakage of the last item, not as flakiness; do not blindly re-run.

**If a gate fails.** The items are independent — revert them one at a time from the last (`cd Fizzygum &&
git diff` to see changes; `git checkout -- <file>` reverts a whole file, or re-apply the quoted "before" text for
just that item), re-run the failing gate, and report what failed and what you reverted. **Do not invent alternative
fixes beyond what an item specifies.** Items with pre-declared narrowings say so inline (F2's site list, F3's
droppable sub-item b, F6's per-file independence, F8's whole-item revert).

**Expected benign/legit failures — two kinds, don't confuse them:**
- **Benign inspector member-list shift.** F2/F4/F5/F7/F9 ADD methods (adding has historically been zero-recapture;
  no item DELETES an inspector-visible method) — but if a gauntlet leg's ONLY failure is an inspector member-list
  test, that is benign and pre-authorised: `./fg recapture <failingTestName>` (recaptures dpr1+2), then re-run the
  failed leg. Recaptured reference images live in the **`Fizzygum-tests`** repo — a second repo's diff to show the
  owner.
- **F6's legit-improvement shift.** If, and only if, F6 ran and the failing tests are patch-programming-node tests
  (names contain `Patch`/`Fanout`/`Calculating`/`Diffing`/`Regex`), the diff may be the lag fix itself showing up
  mid-gesture. Do NOT auto-recapture: dump the failing screenshots (`./fg test <name>` then inspect), confirm the
  only difference is the node's own frame catching up one frame earlier, report to the owner, and recapture only
  on their say-so.

**Commit protocol (STRICT).** NEVER `git commit` or `git push` on your own — this is a review-driven project. When
the tier is green: present the owner a summary of the full diff (`Fizzygum`, plus `Fizzygum-tests` if any recapture
landed) and a proposed commit message per repo, then WAIT for approval. When approved: commit via
`git commit -F <msgfile>` (never `-m` with backticks/`$()` — bash command-substitutes them and silently corrupts
the message).

**Recommended order.** Tier F first (F1 → F2 → F3 → F4 → F5 → F6 → F7 → F8 → F9 — rising risk, so every cheap item
is banked before the ones that need the torture), then Tier G (G1 → G6, any order). **Any prefix of the order is a
legitimate session's work** — if you stop early, report which items landed and which gates ran. A session may also
run Tier G alone (build per item + one `./fg suite` at the end, no torture).

---

## §1 — Evidence bank: what the 2026-07-02 night re-read verified (do not re-derive)

Each fact below is load-bearing for an item. The greps are cheap — re-run any you rely on and confirm the expected
shape before editing (drift protocol, §0.5).

1. **The window chrome formula is duplicated with a parse-level divergence.** `WindowWdgt.coffee`: the measure
   `preferredExtentForWidth` declares a local `closeIconSize = 16` (:62) and computes
   `chrome = Math.round(closeIconSize + @padding + @padding) + 2 * @padding` (:69, explicit call — rounds ONLY the
   titlebar) or the `+ 3 * @padding + WorldWdgt.preferencesAndSettings.handleSize` variant (:71); the arrange
   `_positionAndResizeChildren` declares its own `closeIconSize = 16` (:547) and computes
   `partOfHeightUsedUp = Math.round (closeIconSize + @padding + @padding) + 2 * @padding` (:600, **implicit call —
   the space makes CoffeeScript round the WHOLE sum**) and the same variant (:602). Compiler-verified:
   `coffee -bpe` turns the first into `Math.round(c+p+p) + 2*p` and the second into `Math.round((c+p+p) + 2*p)`.
   The collapsed branches diverge the same way: measure :79 `Math.round(closeIconSize) + @padding + @padding` vs
   arrange :661 `Math.round closeIconSize + @padding + @padding` (whole-sum). All copies agree **only because
   `@padding = 5` is an integer**. The measure's own comment (:44–46) claims the branches "mirror
   _positionAndResizeChildren's chrome calc exactly" — false at the parse level.
2. **The chrome constant/quantity has exactly these consumers** (`grep -n "closeIconSize" src/WindowWdgt.coffee`):
   the two locals (:62, :547), the chrome calcs (:69, :71, :600, :602), the collapsed forms (:79, :661), and the
   arrange's button/label/titlebar placement math (:551–:711 band) — the placement math is NOT part of the mirror
   and stays on the local.
3. **Three patch-programming nodes have the pre-fix InspectorWdgt lag shape.** `DiffingPatchNodeWdgt.coffee` :202,
   `CalculatingPatchNodeWdgt.coffee` :221, `RegexSubstitutionPatchNodeWdgt.coffee` :231 — each `_reLayout`
   goes straight from `if @_handleCollapsedStateShouldWeReturn() then return` to positioning children from
   `@left()/@top()/@width()/@height()`, applying its OWN new bounds only via the trailing `super` — so children lag
   the node's frame by one pass (the exact dpr2 flake fixed in InspectorWdgt 2026-06-16: "a custom layout
   positioning children from @width() must apply its OWN new bounds FIRST"). Sibling `FanoutWdgt.coffee` :66–:75 is
   already fixed (it hoists `__calculateNewBoundsWhenDoingLayout` + `@_applyBounds` before arranging). The trailing
   `super` is idempotent after the hoist: `@desired*` are consumed by the hoisted calc, so super's own calc falls
   back to the just-applied `@extent()`/`@position()` — a no-op re-commit (this is exactly FanoutWdgt's shape).
4. **`ToolPanelWdgt` is the last container outside the wrapper/core convention.** `ToolPanelWdgt.coffee`: public
   `add` (:14) carries a 7th parameter `dontLayout` and ends `unless dontLayout` → `@_invalidateLayout()` (:70–71);
   `addMany` (:9) loops `@add eachWidget, nil, nil, nil, nil, nil, true` then one bare `@_invalidateLayout()` (:12).
   There is no `_addNoSettle` and no `_settleLayoutsAfter` in the file. `grep -rn "dontLayout" src` → exactly the
   2 ToolPanelWdgt hits (the flag is internal-only, deletable). `super` inside a ToolPanelWdgt `_addNoSettle` will
   resolve to `Widget::_addNoSettle` — PanelWdgt defines neither `add:` nor `_addNoSettle:`
   (`grep -n "^  add:\|^  _addNoSettle:" src/basic-widgets/PanelWdgt.coffee` → no hits).
5. **The self-settling `add` shape is drop-safe by precedent.** `SimpleVerticalStackPanelWdgt.add` (:25–26) is the
   exact target shape (`@_settleLayoutsAfter => @_addNoSettle …`) and every drop path exercises it suite-green —
   the drop dispatcher's `target.add wdgtToDrop, nil, nil, true, nil, @position()` (`ActivePointerWdgt.coffee` :230)
   reaches the public wrapper as the outermost mutation. Toolbars are built as orphans
   (`new ScrollPanelWdgt new ToolPanelWdgt` in the toolbar creator buttons / MenusHelper :192), so construction-time
   `addMany` either flushes the orphan subtree (top-level) or auto-defers (inside an enclosing settle) — the
   standard orphan-settledness behaviour.
6. **The Slider re-layout couplet.** `SliderWdgt.coffee` — the exact triplet `@_reLayoutSelf()` +
   `@button._reLayoutSelf()` + `@changed()` appears at :55–64 (`_reactToBeingAdded`, with the deserialization
   guard `if @button? and @button instanceof SliderButtonWdgt`), :102–106 (`updateHandlePosition`), :111–119
   (`setValue`), :242–248, :262–268, :298–304. Two sites are NOT the triplet and must be left alone: :66–72
   (`_applyExtent` — button only, no self/changed) and :214–218 (`updateSpecs`-family — no `@changed()`, a
   conditional `fullChanged` follows). `setValue` (:111–119) additionally duplicates `updateHandlePosition`'s body
   under a stale TODO (:108–110: "should call updateHandlePosition … however the tests are in a precarious
   condition" — written before the 165-test headless gauntlet existed).
7. **`__commitWidth`/`__commitHeight` are the last commit leaves with an UNCONDITIONAL cache-break.**
   `Widget.coffee` :1660–1663 / :1695–1698: both call `@__breakMoveResizeCaches()` FIRST, then assign `@bounds`
   with no did-anything-change guard — the discipline D4/E1 already applied to `__commitExtent` (guarded,
   :1525–1536) and `__commitMoveTo`. Callers are cold construction paths only (`PromptWdgt` :45, `ToolTipWdgt`
   :94/:95/:114/:115, `MenuItemWdgt` :67) — this is consistency, not measured perf. Do NOT fold them into
   `__commitExtent`: it min-clamps (`@minimumExtent`), they don't — unifying would change behaviour.
8. **The four geometry-cache counters back three DISTINCT key shapes.** Declared `WorldWdgt.coffee` :188–191
   (`numberOfAddsAndRemoves` / `numberOfVisibilityFlagsChanges` / `numberOfCollapseFlagsChanges` /
   `numberOfRawMovesAndResizes`, all statics). Bump sites: adds/removes ×7 (`TreeNode.coffee` :69, :122;
   `Widget.coffee` :528, :576, :590, :606, :2075), visibility ×3 (`Widget.coffee` :1960, :1989, :2001), collapse ×2
   (`Widget.coffee` :2025, :2053), raw moves/resizes ×1 (`Widget.coffee` :1256, inside `__breakMoveResizeCaches`,
   below the hand-with-no-children skip). Key shapes and their compare/write sites:
   - **4-counter key** (`adds+"-"+vis+"-"+collapse+"-"+moves`): `Widget.coffee` :1118, :1140 (`fullClippedBounds`),
     :1152, :1161, :1165 (`clippedThroughBounds`), :1181, :1190, :1198 (`clipThrough`); `WorldWdgt.coffee` :669,
     :677; `ActivePointerWdgt.coffee` :48, :53; `ClippingAtRectangularBoundsMixin.coffee` :97, :112.
   - **3-counter key** (`adds+"-"+vis+"-"+collapse`): the three `checkVisibleBasedOnIsVisiblePropertyCache` sites in
     `Widget.coffee` `visibleBasedOnIsVisibleProperty` (:970, :977, :982 — grep the field name, expect exactly 3
     formula lines).
   - **1-counter key** (`adds` alone): `TreeNode.coffee` :183/:192 (`root` cache) and :493/:512
     (`firstParentClippingAtBounds` cache).
   Every check REBUILDS the concatenated string (4 number→string conversions + 3 concats) just to compare it — on
   the hot bounds queries paint runs per broken-rect per frame. Three derived INTEGER versions bumped at the same
   event sites invalidate in exactly the same situations (each event bumps every version whose caches it could
   invalidate), so hit/miss behaviour is identical. `fullBounds`' cache is invalidated explicitly
   (`invalidateFullBoundsCache`), NOT by these keys — leave it alone.
9. **Nothing outside `src` reads the counters or the reworded strings.** `grep -rn` in `Fizzygum-tests` (`.js` and
   `.md`) for the four counter names, for `raw/silent`, and for `SUPER_IN_DO_LAYOUT`/`SUPER_SHOULD` → **zero hits**
   (verified 2026-07-02). The audit preludes patch `_invalidateLayout`/settle machinery, not these.
10. **The `getRecursive*Dim` triplication.** `Widget.coffee` :3896–3972: three ~25-line walkers over
    `ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED` children, identical in shape (width SUMS, height
    MAXES, own-field fallback when no stack children, desired/min clamp `.min @getRecursiveMaxDim()`, max no
    clamp), but written with INCONSISTENT idioms (the desired walker null-checks `desiredWidth?`, the other two use
    `gotA*` flags — semantically equivalent). The whole band sits INSIDE a homepage-excluded region (the `<<«`
    closer is at :3982) — new code for it must stay inside the same band. The wrappers `getDesiredDim`/`getMinDim`
    (:3878–3883) and the callers are untouched by the collapse.
11. **The corner-internal 5-way disjunction is written out twice.** `Widget.coffee` :4049 (the `if @layoutSpec ==
    … or …` chain in `_reLayout`) and :4174 (the same 5-way chain inside `@children.filter`). The five constants
    live in `LayoutSpec.coffee` :35–39, OUTSIDE the homepage-excluded band (which starts at :42) — a predicate
    added next to them ships in every build.
12. **The stack arrange's fork comments describe the deleted seam as live.** `SimpleVerticalStackPanelWdgt.coffee`
    `_positionAndResizeChildren`: the block at :230–248 (two stacked generations of comment) says a
    tracking-container child "KEEPS the seam-firing `_setWidthSizeHeightAccordingly`: its child-resize re-enqueue is
    LOAD-BEARING … That converts only in Stage 3, once the convergence is structural"; the move-fork block at
    :266–270 says the same about "the seam-firing `_applyMoveTo` … it converts only in Stage 3". The seam was
    deleted 2026-07-01 and §4.2 Stage 3 landed 2026-06-29 — neither call "fires" anything today, and the fork
    survives for OTHER, real reasons (fact 12b). A cold reader is actively misled about the live mechanism.
    **12b — why the forks genuinely stay:** (resize) a tracking-container child must ARRANGE ITS OWN SUBTREE at the
    new width — a pure measure cannot apply that — and `_setWidthSizeHeightAccordingly` hands the resulting height
    forward (Path B, no read-back); (move) `_applyMoveTo` is the polymorphic move corner —
    `ClippingAtRectangularBoundsMixin` overrides dispatch through it — so switching LEAVES onto it would engage the
    clipping override for clipping leaf panels (a repaint-path change), and switching CONTAINERS onto
    `_applyMoveToBase` would bypass theirs (the 2026-07-01 twin-collapse verdict, `Widget.coffee` :1208–1218).
13. **One throw + comment still use the retired "raw/silent" vocabulary.** `WorldWdgt.coffee` :918–923:
    the `recalculateLayouts` re-entrancy guard's comment says "Internal layout must use the raw/silent setters" and
    the thrown Error string ends "…must use the raw/silent setters, not the public deferred API." The naming
    campaign retired that category-noun (lint [M] bans the prefixes in method names); the sibling throw in
    `Widget._settleLayoutsAfter` (:797) was already reworded to "immediate (geometry) mutators". Nothing greps the
    old string (fact 9).
14. **`TextWdgt.preferredExtentForWidth`'s header claims it has no consumer.** `TextWdgt.coffee` :357–359: "NO
    production consumer yet -- Stage A lands the measure alone; the vertical-stack/window/scroll arranges consume
    it (and shed their mutate-then-read-back) in later stages." The later stages landed 2026-06-28/29 — live
    consumers: `SimpleVerticalStackPanelWdgt.coffee` :149/:179/:252, `WindowWdgt.coffee` :76,
    `ScrollPanelWdgt.coffee` :397/:399 (via `subWidgetsMergedPreferredBounds`), `Widget.coffee` :1078.
15. **27 files carry the 2023 `DO_LAYOUT` TODO markers.** The exact pair
    `# TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023` +
    `# TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023` sits above `_reLayout` overrides across 27 files
    (`grep -rln "SUPER_IN_DO_LAYOUT" src` for the list). `doLayout` was renamed to `_reLayout` 2026-06-22; the ids
    are referenced nowhere else (fact 9). The smell they name is real (fact 3) — the markers should keep the
    information but name the live method.
16. **The macro docs teach the renamed-away API.** `src/macros/MACRO-PATTERNS.md` names `_applyExtentAndNotify` /
    `_applyMoveToAndNotify` / `_applyWidthAndNotify` / `_applyHeightAndNotify` on ~26 lines and `doLayout` on 6
    lines (`grep -n "AndNotify\|doLayout" src/macros/MACRO-PATTERNS.md`); `src/macros/CLAUDE.md` :181–182 names
    `_applyMoveToAndNotify`. Tier B's MEANING-SWAP made the suffix-strip the correct mapping: the old `*AndNotify`
    polymorphic corners ARE today's bare `_applyExtent`/`_applyMoveTo`/`_applyWidth`/`_applyHeight`. The macro
    `.js` tests themselves already use the new names (the suite is green); only the docs are stale.
17. **`MenuWdgt.adjustWidthsOfMenuEntries` toggles track-changes once per child.** `MenuWdgt.coffee` :218–226: the
    `world.disableTrackChanges()` / `world.maybeEnableTrackChanges()` pair sits INSIDE the `@children.forEach`
    around only `item._applyWidth w` — nothing executes between iterations outside the pair, so hoisting the pair
    around the whole loop is equivalent (the flag is a push/pop stack; one push/pop replaces N).
18. **`ScrollPanelWdgt.setContents` clobbers the `extraPadding` default.** `PanelWdgt.coffee` :11 declares
    `extraPadding: 0`; `ScrollPanelWdgt.setContents (aWdgt, extraPadding) ->` (:256–257) assigns the parameter
    unconditionally, so a call without the 2nd argument writes `undefined` and
    `_positionAndResizeChildren`'s `padding = Math.floor @extraPadding + @padding` (:350) goes NaN. All ~18 current
    callers pass a value (`grep -rn "setContents" src` — the info-widgets/apps pass `5`,
    `SimplePlainTextScrollPanelWdgt` passes its ctor `padding`, itself always given) — a landmine, not a live bug.
19. **A live, unreachable `debugger` sits in `clipThrough`.** `Widget.coffee` :1178–1179:
    `if @ == Window` / `debugger` — compares a widget INSTANCE to the global `Window` class object, never true;
    dead debug residue in live code. (The `debugger`+`alert` pairs guarded by
    `world.doubleCheckCachedMethodsResults` throughout the cache region are INTENTIONAL default-off assertions —
    never touch those.)

---

## §2 — Tier F (LIVE): behaviour-preserving layout code fixes

Ordered cheap→risky. Each item: pre-flight → How → gate note. Build (`./fg build`) after every item.

### F1 — `setContents` defensive default (ScrollPanelWdgt) — trivial

*Why:* §1 fact 18 — an omitted 2nd argument poisons the arrange with NaN. One token removes the landmine;
behaviour today is unchanged (every caller passes a value).
*Pre-flight:* `grep -n "setContents: (aWdgt, extraPadding)" src/basic-widgets/ScrollPanelWdgt.coffee` → 1 hit.
*How:* in `src/basic-widgets/ScrollPanelWdgt.coffee`, change
```coffee
  setContents: (aWdgt, extraPadding) ->
```
to
```coffee
  setContents: (aWdgt, extraPadding = 0) ->
```
*Gate:* build.

### F2 — Slider re-layout couplet → one helper; `setValue` stops duplicating `updateHandlePosition` — small

*Why:* §1 fact 6 — the same 3-line triplet six times, one of them under a TODO whose "tests are precarious" excuse
predates the headless gauntlet.
*Pre-flight:* `grep -n "_reLayoutSelf()" src/basic-widgets/SliderWdgt.coffee` → expect call sites matching fact 6's
list. Verify each site you are about to convert matches the triplet EXACTLY (self + button + `@changed()`);
**leave `_applyExtent` (button-only) and the no-`@changed()` site (~:214) alone.**
*How (all in `src/basic-widgets/SliderWdgt.coffee`):*
1. Add the helper right after `_reactToBeingAdded` (keep 2-space method indent):
```coffee
  # Re-lay-out me and my thumb, then repaint -- the couplet every value/geometry change
  # ends with. The button guard covers deserialization, where @button can still be a
  # string reference (see unitSize).
  _reLayoutSelfAndButton: ->
    @_reLayoutSelf()
    if @button? and @button instanceof SliderButtonWdgt
      @button._reLayoutSelf()
    @changed()
```
2. Replace `_reactToBeingAdded`'s whole body (the triplet WITH its guard and the comment lines) with
   `@_reLayoutSelfAndButton()`.
3. `updateHandlePosition` becomes:
```coffee
  updateHandlePosition: (newvalue) ->
    @value = Number(newvalue)
    @_reLayoutSelfAndButton()
```
4. `setValue`: DELETE the stale TODO comment block ("TODO this should call updateHandlePosition above … don't want
   to break anything") and replace the body after the connections-token guard line (keep that line byte-identical)
   with:
```coffee
    @value = Number(newvalue)
    @updateTarget()
    @_reLayoutSelfAndButton()
```
   (Order preserved: value → target → re-layout, exactly as before.)
5. Convert the remaining three exact-triplet sites (~:242–248, ~:262–268, ~:298–304) to
   `@_reLayoutSelfAndButton()` — for each, first confirm the site is `_reLayoutSelf` + `button._reLayoutSelf` +
   `@changed()` with nothing interleaved; if anything differs, leave that site and note it.
*Note:* the helper adds the deserialization guard at sites that lacked it — strictly safer, unreachable in tests.
*Narrowing:* any individual site can be left unconverted; the helper + `setValue` delegation alone is worth it.
*Gate:* build.

### F3 — Commit-leaf guard discipline + MenuWdgt toggle hoist — small

*Why:* §1 facts 7 and 17 — the last two `__commit*` leaves violating the D4/E1 "break caches only on actual
change" discipline, and a per-item stack push/pop that wants hoisting.
*How, sub-item a (in `src/basic-widgets/Widget.coffee`):* replace
```coffee
  __commitWidth: (width) ->
    @__breakMoveResizeCaches()
    w = Math.max Math.round(width or 0), 0
    @bounds = new Rectangle @bounds.origin, new Point @bounds.origin.x + w, @bounds.corner.y
```
with
```coffee
  __commitWidth: (width) ->
    w = Math.max Math.round(width or 0), 0
    newBounds = new Rectangle @bounds.origin, new Point @bounds.origin.x + w, @bounds.corner.y
    return if @bounds.equals newBounds
    @bounds = newBounds
    # cache-break under the did-anything-change guard, like __commitExtent (the D4/E1 discipline)
    @__breakMoveResizeCaches()
```
and replace
```coffee
  __commitHeight: (height) ->
    @__breakMoveResizeCaches()
    h = Math.max Math.round(height or 0), 0
    @bounds = new Rectangle @bounds.origin, new Point @bounds.corner.x, @bounds.origin.y + h
```
with
```coffee
  __commitHeight: (height) ->
    h = Math.max Math.round(height or 0), 0
    newBounds = new Rectangle @bounds.origin, new Point @bounds.corner.x, @bounds.origin.y + h
    return if @bounds.equals newBounds
    @bounds = newBounds
    # cache-break under the did-anything-change guard, like __commitExtent (the D4/E1 discipline)
    @__breakMoveResizeCaches()
```
Do NOT add a min-extent clamp (that is `__commitExtent`'s behaviour, not theirs).
*How, sub-item b (droppable alone; in `src/basic-widgets/menu-system/MenuWdgt.coffee`,
`adjustWidthsOfMenuEntries`):* hoist the pair out of the loop —
```coffee
    @children.forEach (item) =>
      world.disableTrackChanges()
      item._applyWidth w
      #console.log "new width of " + item + " : " + item.width()
      world.maybeEnableTrackChanges()
```
becomes
```coffee
    world.disableTrackChanges()
    @children.forEach (item) =>
      item._applyWidth w
    world.maybeEnableTrackChanges()
```
(the commented log line goes — it is G6-class residue in the same lines).
*Gate:* build.

### F4 — `LayoutSpec.isCornerOrEdgeInternal` predicate — small

*Why:* §1 fact 11 — the 5-constant disjunction written out twice in `Widget._reLayout`.
*How:* in `src/LayoutSpec.coffee`, immediately after the `@ATTACHEDAS_CORNER_INTERNAL_BOTTOM: 100018` line (and
BEFORE the homepage-excluded band that starts at the `# »>>` marker), add:
```coffee

  # TRUE iff `spec` is one of the five corner/edge-internal attachment specs above -- a
  # child placed by base Widget._reLayout's corner pass (handles etc.). ONE home for the
  # five-way test Widget._reLayout used to write out twice.
  @isCornerOrEdgeInternal: (spec) ->
    spec == @ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT or
    spec == @ATTACHEDAS_CORNER_INTERNAL_TOPLEFT or
    spec == @ATTACHEDAS_CORNER_INTERNAL_BOTTOMRIGHT or
    spec == @ATTACHEDAS_CORNER_INTERNAL_RIGHT or
    spec == @ATTACHEDAS_CORNER_INTERNAL_BOTTOM
```
Then in `src/basic-widgets/Widget.coffee` (edit the LOWER site first — drift protocol):
- the `allCornerLayoutedChildren = @children.filter (m) -> m.layoutSpec == …or…or…` line (~:4174) becomes
  `allCornerLayoutedChildren = @children.filter (m) -> LayoutSpec.isCornerOrEdgeInternal m.layoutSpec`
- the `if @layoutSpec == LayoutSpec.ATTACHEDAS_CORNER_INTERNAL_TOPLEFT or …` chain (~:4049) becomes
  `if LayoutSpec.isCornerOrEdgeInternal @layoutSpec`
*Gate:* build.

### F5 — Window chrome: one home for the measure↔arrange mirror — medium

*Why:* §1 facts 1–2 — a duplicated formula that MUST agree between measure and arrange (assessment §6.1 rule 1)
has already drifted at the parse level; only integer padding masks it.
*Pre-flight:* `grep -n "closeIconSize" src/WindowWdgt.coffee` and match fact 2's census. Confirm the four chrome
sites' quoted text below.
*How (all in `src/WindowWdgt.coffee`; apply bottom-up):*
1. Add, right before `preferredExtentForWidth` (after the big comment block that precedes it, at class-member
   indent):
```coffee
  # The titlebar icon square (close / collapse / edit buttons) -- ONE home for the
  # literal 16 the measure and the arrange both used to declare locally.
  @CLOSE_ICON_SIZE: 16

  # Height of the titlebar strip: icon square + a padding above and below. (Rounding the
  # whole sum -- identical to every historical inline form for any integer @padding.)
  _titlebarHeight: ->
    Math.round(WindowWdgt.CLOSE_ICON_SIZE + @padding + @padding)

  # Window chrome height -- everything that is NOT content: the titlebar strip plus the
  # bottom margin, which depends on whether the resizer may overlap the contents. ONE home
  # for the calc the measure (preferredExtentForWidth) and the arrange
  # (_positionAndResizeChildren) both used to write out inline: they MUST agree, or the
  # window's measure diverges from what its arrange then applies (assessment §6.1 rule 1).
  # The two inline copies had in fact drifted at the PARSE level -- one rounded only the
  # titlebar, the other (via CoffeeScript's implicit call in `Math.round (a) + b`) the
  # whole sum -- identical only while @padding is an integer.
  _chromeHeight: (spec) ->
    if spec.resizerCanOverlapContents
      @_titlebarHeight() + 2 * @padding
    else
      @_titlebarHeight() + 3 * @padding + WorldWdgt.preferencesAndSettings.handleSize
```
2. In `_positionAndResizeChildren`: the collapsed branch
   `partOfHeightUsedUp = Math.round closeIconSize + @padding + @padding` (~:661) becomes
   `partOfHeightUsedUp = @_titlebarHeight()`; the chrome fork (~:599–602)
```coffee
      if @contents.layoutSpecDetails.resizerCanOverlapContents
        partOfHeightUsedUp = Math.round (closeIconSize + @padding + @padding) + 2 * @padding
      else
        partOfHeightUsedUp = Math.round (closeIconSize + @padding + @padding) + 3 * @padding + WorldWdgt.preferencesAndSettings.handleSize
```
   becomes
```coffee
      partOfHeightUsedUp = @_chromeHeight @contents.layoutSpecDetails
```
   and the method's local `closeIconSize = 16` (~:547) becomes
   `closeIconSize = WindowWdgt.CLOSE_ICON_SIZE` (the button/label placement math keeps using the local).
3. In `preferredExtentForWidth`: the collapsed branch
   `return new Point availW, Math.round(closeIconSize) + @padding + @padding` (~:79) becomes
   `return new Point availW, @_titlebarHeight()`; the chrome fork (~:68–71)
```coffee
      if spec.resizerCanOverlapContents
        chrome = Math.round(closeIconSize + @padding + @padding) + 2 * @padding
      else
        chrome = Math.round(closeIconSize + @padding + @padding) + 3 * @padding + WorldWdgt.preferencesAndSettings.handleSize
```
   becomes
```coffee
      chrome = @_chromeHeight spec
```
   then DELETE the now-unused local `closeIconSize = 16` (~:62). Also fix the header comment (~:44–46): change
   "the two branches mirror _positionAndResizeChildren's chrome calc exactly" to "chrome comes from the shared
   `_chromeHeight` (one home for the measure and the arrange)".
*Byte-safety:* all replaced forms are numerically identical for integer `@padding` (always today: `@padding = 5`);
the helper standardises on whole-sum rounding.
*Gate:* build; adds 2 methods + 1 static to WindowWdgt → watch for the benign inspector recapture (§0.5).

### F6 — Patch-node `_reLayout` lag fix (3 files) — medium; possible LEGIT recapture

**✅ DONE 2026-07-02 — FOLDED into the escalated G4 (§5, `cd8fc978`).** The 3 patch nodes were among the 11
`_reLayout` overrides fixed apply-bounds-first (a codebase-wide audit superset of this 3-file item), and the new
`buildSystem/check-relayout-bounds-first.js` gate now enforces the shape. The spec below is the original 3-file
plan, kept for reference.

*Why:* §1 fact 3 — the InspectorWdgt one-cadence-lag bug pattern, alive in three files while their sibling is fixed.
*Pre-flight:* in each of `src/patch-programming/DiffingPatchNodeWdgt.coffee`,
`src/patch-programming/CalculatingPatchNodeWdgt.coffee`, `src/patch-programming/RegexSubstitutionPatchNodeWdgt.coffee`,
grep `_reLayout: (newBoundsForThisLayout) ->` and confirm the body starts with
`if @_handleCollapsedStateShouldWeReturn() then return` and ends with `super` + `@markLayoutAsFixed()`.
Compare with the fixed shape in `src/patch-programming/FanoutWdgt.coffee` (~:66–75).
*How (same edit in each of the three files):* replace
```coffee
  _reLayout: (newBoundsForThisLayout) ->

    if @_handleCollapsedStateShouldWeReturn() then return
```
with
```coffee
  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN new bounds FIRST, so the children below are positioned against my
    # CURRENT frame, not the previous pass's (the InspectorWdgt one-cadence-lag fix,
    # 2026-06-16; FanoutWdgt already does this). The trailing `super` re-applies
    # idempotently: @desired* were consumed above, so its own calc falls back to the
    # just-applied extent/position -- a no-op re-commit.
    @_applyBounds newBoundsForThisLayout
```
Leave the trailing `super` + `markLayoutAsFixed()` untouched. Also rewrite each file's stale marker pair (the two
`TODO id: SUPER_*DO_LAYOUT*` lines above the method) to the single G4 replacement line — these three files then
don't need the G4 sweep.
*Gate:* build; tier-end gauntlet + torture (this touches `_reLayout` bodies). The three files are independent —
revert per-file on failure. If patch-node tests diff, follow §0.5's **F6 legit-improvement** protocol (inspect,
report, recapture only on owner approval).

### F7 — Collapse the three `getRecursive*Dim` walkers onto one — medium

*Why:* §1 fact 10 — one walker written three times with inconsistent idioms; ~75 lines → ~40.
*Pre-flight:* grep `getRecursiveDesiredDim:` in `src/basic-widgets/Widget.coffee`; confirm the three bodies match
fact 10's description and that all three sit ABOVE the `# this part is excluded from the fizzygum homepage build <<«`
closer (~:3982) — the new helper must stay inside that same excluded band.
*How (in `src/basic-widgets/Widget.coffee`):* replace the three method bodies (keep the `# NB the .height() halves…`
comment block that precedes `getRecursiveDesiredDim` — it is still true) with:
```coffee
  # ONE recursive walker for the three min/desired/max queries below. They differed only
  # in WHICH per-child query recurses and WHICH own-field pair backstops a widget with no
  # horizontal-stack children (plus the desired/min clamp, applied by the wrappers below).
  # Width SUMS across the stack children; height takes the MAX.
  _getRecursiveStackDim: (childQueryName, ownWidth, ownHeight) ->
    width = 0
    height = 0
    gotAWidth = false
    gotAHeight = false
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C[childQueryName]()
        gotAWidth = true
        width += childSize.width()
        if height < childSize.height()
          gotAHeight = true
          height = childSize.height()
    width = ownWidth unless gotAWidth
    height = ownHeight unless gotAHeight
    new Point width, height

  getRecursiveDesiredDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    (@_getRecursiveStackDim "getDesiredDim", @desiredWidth, @desiredHeight).min @getRecursiveMaxDim()

  getRecursiveMinDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    # the user might have forced the "desired" to be smaller than the widget's standard minimum
    (@_getRecursiveStackDim "getMinDim", @minWidth, @minHeight).min @getRecursiveMaxDim()

  getRecursiveMaxDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    @_getRecursiveStackDim "getMaxDim", @maxWidth, @maxHeight
```
*Byte-safety:* the desired walker's `desiredWidth = nil` / `if !desiredWidth? then desiredWidth = 0` idiom and the
flag idiom are semantically identical; per-child queries, fallbacks and clamps map 1:1.
*Gate:* build; rides the tier gauntlet.

### F8 — Geometry-cache version keys: four counters + string concat → three integers — medium-large

*Why:* §1 fact 8 — the hot bounds queries rebuild and compare a concatenated string on every call, and the formula
is copy-pasted at ~15 sites. Integer versions with identical invalidation semantics: no per-query allocation, one
home. Includes deleting fact 19's unreachable `debugger`.
*Pre-flight:* re-run fact 8's site census (grep each counter name across `src`); confirm fact 9 (zero hits in
`Fizzygum-tests`). Any extra site beyond the census → STOP and report.
*How:*
1. `src/WorldWdgt.coffee` — replace the four declarations (~:188–191) with:
```coffee
  # Monotonic GEOMETRY-CACHE VERSIONS (integers; replaced the four numberOf* counters
  # whose string-concatenated key was rebuilt on every bounds query, Tier F 2026-07-02):
  #   structureVersion  -- bumped on tree adds/removes only
  #   visibilityVersion -- bumped on adds/removes + visibility flips + collapse flips
  #   geometryVersion   -- bumped on all of the above + raw moves/resizes
  # A cache stamps the version it was computed at and is valid iff it is unchanged; each
  # event bumps every version whose caches it could invalidate, so hit/miss behaviour is
  # IDENTICAL to the old concatenated keys (misses cost recompute, never values).
  @structureVersion: 0
  @visibilityVersion: 0
  @geometryVersion: 0

  @noteStructureChange: ->
    @structureVersion++
    @visibilityVersion++
    @geometryVersion++

  @noteVisibilityOrCollapseChange: ->
    @visibilityVersion++
    @geometryVersion++
```
2. Bump-site replacements (mechanical, per fact 8's census):
   - every `WorldWdgt.numberOfAddsAndRemoves++` → `WorldWdgt.noteStructureChange()` (7 sites)
   - every `WorldWdgt.numberOfVisibilityFlagsChanges++` and `WorldWdgt.numberOfCollapseFlagsChanges++` →
     `WorldWdgt.noteVisibilityOrCollapseChange()` (3 + 2 sites)
   - the one `WorldWdgt.numberOfRawMovesAndResizes++` (in `__breakMoveResizeCaches`) →
     `WorldWdgt.geometryVersion++`
3. Key-site replacements (compare AND write sites — the formula is the same text on both):
   - every 4-counter formula (`…numberOfAddsAndRemoves + "-" + … + "-" + …numberOfRawMovesAndResizes`) →
     `WorldWdgt.geometryVersion` — in `Widget.coffee` (`fullClippedBounds` / `clippedThroughBounds` / `clipThrough`),
     `WorldWdgt.coffee`, `ActivePointerWdgt.coffee`, `ClippingAtRectangularBoundsMixin.coffee`
   - every 3-counter formula (ends at `…numberOfCollapseFlagsChanges`) → `WorldWdgt.visibilityVersion` — the three
     `checkVisibleBasedOnIsVisiblePropertyCache` lines in `Widget.coffee`
   - every bare `WorldWdgt.numberOfAddsAndRemoves` key (no `+`) → `WorldWdgt.structureVersion` — the four
     `TreeNode.coffee` sites (`rootCacheChecker` ×2, `checkFirstParentClippingAtBoundsCache` ×2)
4. While in the `clipThrough` region of `Widget.coffee`: DELETE the two lines `if @ == Window` / `debugger`
   (fact 19), and DELETE the commented `#console.log "cache hit …"` / `#console.log "cache miss …"` /
   `#  #console.log …` / `#  #debugger` residue lines inside `clippedThroughBounds` / `clipThrough` /
   `visibleBasedOnIsVisibleProperty` (they quote the old key formula). Do NOT touch the
   `world.doubleCheckCachedMethodsResults` blocks.
5. Post-edit proof: `grep -rn "numberOfAddsAndRemoves\|numberOfVisibilityFlagsChanges\|numberOfCollapseFlagsChanges\|numberOfRawMovesAndResizes" src --include="*.coffee"`
   → **zero hits**.
*Byte-safety:* stale-cache bugs from a missed site fail the suite deterministically (wrong clip/broken rects), and
the `doubleCheckCachedMethodsResults` debug flag exists for interactive diagnosis if ever needed.
*Gate:* build; tier-end gauntlet + torture (cache-key change — the D4/E1 precedent class). Revert as a whole item
if red.

### F9 — Bring `ToolPanelWdgt` into the settle architecture — the risky one, LAST

*Why:* §1 facts 4–5 — the last container with no wrapper/core split, a hand-rolled `dontLayout` batching flag, and
trailing bare `_invalidateLayout()` pushes riding the end-of-cycle flush (orphan-excluded today, statically the
`newParentChoice` CONVERT pattern). Target shape = `SimpleVerticalStackPanelWdgt.add`, proven drop-safe.
*Pre-flight:* `grep -rn "dontLayout" src` → only the 2 ToolPanelWdgt hits. `grep -rn "\.addMany" src` and confirm
ToolPanel-bound `addMany` callers are construction-time builders (toolbar creator buttons / apps / MenusHelper —
fact 5). Confirm PanelWdgt still defines neither `add:` nor `_addNoSettle:`.
*How (all in `src/ToolPanelWdgt.coffee`):*
1. Rename the existing `add` to `_addNoSettle`, dropping the `dontLayout` parameter, keeping the body IDENTICAL
   except the tail — the signature becomes
```coffee
  _addNoSettle: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped, unused, positionOnScreen) ->
```
   and the tail
```coffee
      unless dontLayout
        @_invalidateLayout()
```
   becomes a plain
```coffee
      @_invalidateLayout()
```
   The `super` calls inside now resolve to `Widget::_addNoSettle` (PanelWdgt defines no `_addNoSettle` — fact 4),
   which is exactly the non-settling core we want. **Leave the two `glassBoxBottom.add …` calls untouched** — the
   glass box is an orphan mid-build, so its public `add` auto-defers inside our settle (orphan-settledness); do not
   "improve" them to cores.
2. Add the public wrapper above it, plus a short header:
```coffee
  # Public add self-settles over the non-settling core (the Widget /
  # SimpleVerticalStackPanelWdgt add/_addNoSettle pattern). Was: a public add ending in a
  # bare _invalidateLayout() that rode the end-of-cycle flush, plus a hand-rolled
  # `dontLayout` batching flag -- the pre-convert shape everywhere else already left.
  add: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped, unused, positionOnScreen) ->
    @_settleLayoutsAfter => @_addNoSettle aWdgt, position, layoutSpec, beingDropped, unused, positionOnScreen
```
3. Replace `addMany` entirely:
```coffee
  # ONE settle over the whole bundle; each core's _invalidateLayout is deduped by
  # layoutIsValid, so N adds still cost one flush.
  addMany: (widgetsToBeAdded) ->
    @_settleLayoutsAfter =>
      for eachWidget in widgetsToBeAdded
        @_addNoSettle eachWidget
      return
```
*Failure mode to expect:* if the suite throws the `_settleLayoutsAfter` flow-violation ("a public geometry setter
was reached during a layout flush/pass"), some caller reaches `ToolPanelWdgt.add`/`addMany` on an ATTACHED panel
inside an enclosing settle. Do NOT improvise: capture the stack (the throw names it), report it, and revert the
item — routing that caller to the core is a follow-up decision for the owner.
*Gate:* build; tier-end gauntlet + torture. Revert as a whole item if red.

---

## §3 — Tier G (LIVE): truth repairs (comments + docs + residue)

Zero behaviour intent (G2 rewords one never-tested string). Build after each item; one `./fg suite` at tier end
(no torture needed for a G-only session).

### G1 — Re-ground the stack arrange's fork comments (the seam is dead; the forks live for other reasons)

*Why:* §1 facts 12/12b — the heart of the engine documents a deleted mechanism as live and load-bearing.
*How (in `src/SimpleVerticalStackPanelWdgt.coffee`, `_positionAndResizeChildren`; edit the LOWER block first):*
1. Replace the move-fork comment block (~:266–270, the lines starting `# §4.2 Stage 1: move via the NON-notifying
   arrange twin …` through `… Same discriminator as the resize.`) with:
```coffee
      # Move the child -- same discriminator as the resize above, DIFFERENT reason (nothing
      # notifies anything anymore; the notify-by-mutation seam was deleted 2026-07-01):
      # _applyMoveTo is the POLYMORPHIC move corner (ClippingAtRectangularBoundsMixin's
      # scroll-optimization override dispatches through it), _applyMoveToBase the uniform
      # base translate. Each child KIND keeps the path it has always taken: a tracking
      # container (a clipping widget) keeps its override's repaint behaviour, a leaf keeps
      # the base translate. Unifying onto either name is a REPAINT-PATH change (e.g. a
      # clipping leaf panel would gain the override), not a free cleanup -- see the
      # twin-collapse verdict on Widget._applyMoveBy.
```
2. Replace the resize-fork double comment block (~:230–248 — BOTH stacked generations, from `# §4.2 Stage 1
   (structural arrange): MEASURE the child's preferred extent …` through `… and a leaf has no inner convergence to
   drive.`) with:
```coffee
        # Size the child at the recommended width -- two paths by child KIND, neither of
        # which notifies anyone (the notify-by-mutation seam was deleted 2026-07-01; my
        # container re-fits at settle time via the up-edge):
        #  - a TRACKING-CONTAINER child (`_reLayoutChildren?` -- Window / Stack / ScrollPanel)
        #    goes through _setWidthSizeHeightAccordingly: applying its width must ALSO
        #    arrange its own subtree at that width (a pure measure cannot apply a subtree
        #    arrange), and the call HANDS the resulting height forward (Path B), so I never
        #    read the child's geometry back.
        #  - a LEAF child (text / clock / box) is sized by the PURE measure
        #    preferredExtentForWidth -- it carries each type's width->height sizing (wrapped
        #    text / clock square / ratio), proven byte-exact vs the old mutate-and-read-back
        #    by the §4.1 Stage-A/B differential probes -- applied through the
        #    override-bypassing _applyExtentBase.
        # (NB do NOT use `implementsDeferredLayout()` as the discriminator -- it is pinned
        # false on Window/Stack/Scroll precisely so it doesn't flip their read sites, so it
        # would mis-route them to the leaf branch.)
```
*Care:* keep the CODE lines between/after the blocks byte-identical (the `if widget._reLayoutChildren?` forks, the
FIT_BOX_TO_TEXT block, `leftPosition = …`); only comment lines change.
*Gate:* build.

### G2 — Retire "raw/silent setters" from the re-entrancy guard (comment + throw string)

*Why:* §1 fact 13. *Pre-flight:* `grep -rn "raw/silent" src` → exactly the 2 WorldWdgt lines; fact 9 says nothing
greps the string.
*How (in `src/WorldWdgt.coffee`):* in the comment above the `recalculateLayouts` re-entrancy guard, change
"Internal layout must use the raw/silent setters, never the public deferred API." to
"Internal layout must use the immediate (geometry) mutators, never the public deferred API."; and in the throw,
change "Internal layout code must use the raw/silent setters, not the public deferred API." to
"Internal layout code must use the immediate (geometry) mutators, not the public deferred API."
*Gate:* build.

### G3 — Fix `TextWdgt.preferredExtentForWidth`'s "no consumer yet" header

*Why:* §1 fact 14. *How (in `src/basic-widgets/TextWdgt.coffee`):* replace the final sentence of the method's
header comment —
```
# byte-matches what _reLayoutSelf commits when the box is later sized to availW (proven
# suite-wide: 4022 measure-vs-commit differentials, 0 mismatches). NO production consumer
# yet -- Stage A lands the measure alone; the vertical-stack/window/scroll arranges consume
# it (and shed their mutate-then-read-back) in later stages.
```
with
```
# byte-matches what _reLayoutSelf commits when the box is later sized to availW (proven
# suite-wide: 4022 measure-vs-commit differentials, 0 mismatches). CONSUMED since §4.1
# Stage C by the vertical-stack / window / scroll arranges (leaf-child sizing + the
# content-frame measure via subWidgetsMergedPreferredBounds), which shed their
# mutate-then-read-back against it.
```
*Gate:* build.

### G4 — Retire the 2023 `DO_LAYOUT` TODO markers (24 files after F6)

**✅ ESCALATED + DONE 2026-07-02 (owner-directed — §5, `cd8fc978`).** Rather than the comment-only marker retire
described below, the owner asked to actually FIX the smell: all 33 `_reLayout` overrides were audited, the 11
SMELLY ones FIXED apply-bounds-first (F6 folded in), the 2023 `SUPER_*DO_LAYOUT*` markers retired from all 29
files (the 3 `src/video-player/` files' variant forms conventionalised first), and a new build gate
`check-relayout-bounds-first.js` added to keep it fixed. The spec below is the original comment-only plan.

*Why:* §1 facts 15 + 3 — the markers flag a real smell but name a method deleted in the rename campaign.
*Pre-flight:* `grep -rln "SUPER_IN_DO_LAYOUT" src` for the current file list (27 minus any F6 already rewrote).
*How:* in each file, replace the exact pair
```
  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
```
with the single line
```
  # TODO super (the base _reLayout, which applies my own bounds) runs at the BOTTOM here -- the one-cadence-lag smell; when touching this method, apply own bounds FIRST (see InspectorWdgt._reLayout / FanoutWdgt._reLayout for the fixed shape)
```
(match the pair's existing indentation; some files may have the two lines at 2-space indent). Post-edit:
`grep -rn "DO_LAYOUT" src` → zero hits.
*Gate:* build.

### G5 — Macro docs: rename the deleted fixture API to the live names

*Why:* §1 fact 16 — `src/macros/MACRO-PATTERNS.md` + `src/macros/CLAUDE.md` teach `_apply*AndNotify` / `doLayout`;
a macro authored from them calls methods that no longer exist.
*How:* in those two files ONLY, apply the née map (Tier B's meaning-swap makes the suffix-strip correct — the old
`*AndNotify` polymorphic corners ARE today's bare names):
`_applyExtentAndNotify`→`_applyExtent` · `_applyMoveToAndNotify`→`_applyMoveTo` ·
`_applyWidthAndNotify`→`_applyWidth` · `_applyHeightAndNotify`→`_applyHeight` ·
`doLayout`→`_reLayout` (for the `doLayout` lines, READ each: `InspectorWdgt.doLayout` → `InspectorWdgt._reLayout`;
a phrase like "doLayout's three stack-distribution loops" → "_reLayout's three stack-distribution loops").
Pre-verify each NEW name exists: `grep -n "_applyExtent:\|_applyMoveTo:\|_applyWidth:\|_applyHeight:"
src/basic-widgets/Widget.coffee`. Post-edit: `grep -rn "AndNotify\|doLayout" src/macros` → zero hits.
*Gate:* build (docs don't compile, but keep the loop uniform).

### G6 — Debug-residue sweep in layout-related files

*Why:* commented-out debug prints inside live layout methods, outside the bands Tiers A/D swept.
*Scope (ONLY these files):* `src/basic-widgets/StringWdgt.coffee` (the fitting/reflow band — ~16 lines),
`src/basic-widgets/TextWdgt.coffee`, `src/StackElementsSizeAdjustingWdgt.coffee`,
`src/StretchableWidgetContainerWdgt.coffee`, `src/basic-widgets/menu-system/MenuWdgt.coffee`,
`src/mixins/ClippingAtRectangularBoundsMixin.coffee` (:229 and the `#  debugger` pair ~:68–69),
`src/basic-widgets/CaretWdgt.coffee` (:132, :137), `src/HandleWdgt.coffee` (:274, :279), `src/ListWdgt.coffee`
(:46, :92), plus any `Widget.coffee` cache-region lines F8 did not already remove.
*Rule:* delete ONLY whole lines that are a commented-out debug print or breakpoint — `#console.log …`,
`# console.log …`, `#  #console.log …`, `#debugger`, `#  #debugger`. NEVER delete: live code (even odd-looking),
anything inside a `world.doubleCheckCachedMethodsResults` block, the live `if !key? then debugger` in
`CaretWdgt.processKeyDown`, or prose comments. When a `#console.log` shares a comment block with prose, delete only
the log line. Find them per file with `grep -n "#console.log\|# console.log\|#debugger" <file>`.
*Gate:* build; the tier-end suite proves the sweep touched nothing live.

---

## §4 — Verification & sequencing

- **Per item:** pre-flight greps → exact edits → `./fg build` (PASS = `0 violations` + `done!!!`).
- **Tier F end:** `./fg gauntlet`; **plus the four-config danger torture iff F6/F8/F9 ran** (§0.5 gate 2).
  Benign-vs-legit failure triage per §0.5. Tier F items are independent; revert from the last on red.
- **Tier G end:** one `./fg suite` (dpr1). If G ran in the same session as F, the F gates cover it.
- **Sequencing:** F1 → F2 → F3 → F4 → F5 → F6 → F7 → F8 → F9, then G1 → G6. Any prefix is a legitimate session.
  A comments-only session (Tier G alone) is also fine and needs no torture.
- **Recommended split for a fresh session:** land F1–F5 + F7 (cheap, no torture) and all of Tier G first; take
  F6, F8, F9 (each independently) only when there is time to run the full gauntlet + torture and triage.
- **✅ STATUS (2026-07-02, `cd8fc978`):** F1–F5, F7 and G1–G6 LANDED; **F6 folded into the escalated G4** (§5 +
  the new `check-relayout-bounds-first.js` gate). **The only live items left are F8 and F9** — both torture-gated,
  each independent.

## §5 — Landed record (2026-07-01 → 07-02, all committed; kept for cold-runnability)

*(Per this doc's convention the full item-by-item specs of landed tiers are pruned — recover them from git history:
Tiers A/B/C at `0b96d0ef`, Tier D + its evidence bank at `56f25c09`, Tier E in commit `85ba908e` itself.)*

- **Opt-2 — freefloating walk-up TODO ✅ (`06b1ae53`).** The settle loop's walk-up climbs to the LAST-invalid
  widget (`WorldWdgt._recalculateLayoutsBody`), so a freefloating child is no longer laid out first against a stale
  parent size and again after. Byte-exact (gauntlet ×3 engines + danger torture). Sound because the settled layout
  is an **order-independent fixpoint** (the Opt-1 probe's durable result, Appendix X1).
- **Twin collapse ✅ (`8aefa53f`).** `_commitExtentAndNotify` folded into the `__commitExtent` leaf;
  `_commitBoundsAndNotify` + the old `_applyBounds` folded into one `_commitBounds`. The **move twins are NOT
  collapsible**: the polymorphic move-apply is the dispatch point for the `ClippingAtRectangularBoundsMixin` /
  `ActivePointerWdgt` overrides, the `*Base` twin the uniform base translate — merging would reroute arrange moves
  through the overrides.
- **Opt-4 → lint rule `[N]` ✅ (2026-07-01).** `SEAM_VERB_BANNED = /^_announce\w*ToContainer$/` at each method def
  bans reviving the deleted seam verbs (DEF side; CALL side covered by [I]/[K]).
- **OO-1 seam comment-residue prune ✅ / OO-3 dead-code sweep ✅ (confirm-only)** (2026-07-01).
- **Tier A ✅ (`3218fb7a` + `cf3dbaa8`, 2026-07-02).** Dead-block/breadcrumb deletion in `Widget.coffee` (the 17
  `if false and` blocks + 8 "move N" lines), horizontal-distribution debug cleanup (+ `ssss` →
  `fillByDesiredFraction`), dim-cache scaffolding removal + the `getRecursiveDesiredDim` child-height fix, the
  `"enter"`→`"center"` typo in `VerticalStackLayoutSpec`, `_applyExtentAndNotify` → pass-through + dead-param
  removal + double cache-break dedup (sub-item 3 = the D4 precedent), the stack `@padding` default-param (arrange
  no longer mutates configuration), and the `layering-naming-convention.md` §2.5/§2.6/[N] repair. ~136 lines net
  deletion; byte-identical (gauntlet ×3 + torture, no recapture).
- **Tier B ✅ (`ad0bf5c7` + tests `c2ed1476`, 2026-07-02).** The `*AndNotify` truthful-name rename + **MEANING
  SWAP**: polymorphic corners → bare `_apply*`, override-bypass twins → `_apply*Base`; rider
  `_reflowContainedTextThenAnnounce` → `_reflowContainedTextThenInvalidateLayout`. Lint [K] re-derived to the
  override-bypass negative; `_apply*AndNotify` joined the [M] retired-fragment ban; convention-doc Family 1
  rewritten to REACT×DISPATCH; assessment §5 carries the explicit MEANING-SWAP ledger line. 111 src files
  (+623/−622); 11 benign inspector recaptures; gauntlet ×3 + torture clean.
- **Tier C ✅ (`5a084e51` + tests `03d495d70`, 2026-07-02).** Coalesced the resize/move handle drags: non-settling
  `_<x>NoSettle` cores factored out of `setExtent`/`moveTo`/`setWidth`/`setHeight`; four `_`-PRIVATE `*Coalesced`
  entrypoints (+ `setMaxDimCoalesced` → `_setMaxDimCoalesced` for family consistency); the four
  `HandleWdgt.nonFloatDragging` arms switched over, so N per-frame drag settles collapse into the ONE end-of-cycle
  flush. New lint rule **[O]**: a `*Coalesced` CALL only inside an allowlisted stream handler
  (`COALESCED_CALLER_ALLOWLIST = {nonFloatDragging}`); proven to bite a planted violation. Docs: [O] rows added;
  `coalescing-measurement.md` updated. Byte-identical (gauntlet ×3 + apps/tiernaming/settle + four-config torture);
  one benign inspector recapture. Measurement that justified it: drag-start bursts to ~40 muts/frame over a
  44-widget settle ≈ 9–12 ms in one frame, collapsing to ~0.2 ms.
- **Tier D ✅ (`fa4d95d7` + tests `8d3bfbf9b`, 2026-07-02).** Seam-deletion residue + noise, one batch. **D1** —
  deleted the vestigial `window.recalculatingLayouts` global (written every frame, read by nothing live in `src`;
  it name-shadowed the real `world._recalculatingLayouts` phase boolean) + its 30 dead
  `#if !window.recalculatingLayouts then debugger` comment lines + the 6 surviving `#console.log "move N"`
  breadcrumbs Tier A's Widget-scoped sweep missed + the `Fizzygum-tests` layout-audit `LAYOUTAUDIT_WARN`
  cross-check (already gated on the real `!this._inLayoutMutation` discriminator). **D2** — deleted `setBounds`'s
  dead `widgetStartingTheChange` parameter (`setExtent`/`moveTo` keep theirs — their cores consume it). **D3** —
  repaired two comments that still described the deleted notify-by-mutation seam / the landed `*AndNotify` rename as
  live/pending. **D4** (the substantive one) — retired the dead `parentWillSizeMe` axis + the
  `_resizeOwn*SkippingChildRelayout` helpers: post seam-deletion both fork arms were the same `_applyExtentBase`
  call bar a redundant unconditional cache-break, so collapsed onto uniform `_applyExtentBase` calls and deleted the
  parameter/fork/both helpers + the redundant-or-buggy `WindowWdgt` `windowWidth` re-apply (D4f); fewer
  unconditional `__breakMoveResizeCaches()` (caches invalidate less often, values unchanged — the Tier-A A6
  precedent). **D5** — compressed the five near-identical `*Coalesced` comment blocks to one canonical family
  comment (`_setMaxDimCoalesced`) + four one-line pointers (bodies unchanged — a shared helper trips lint [G]).
  ~68 lines net deletion (`src` + docs); byte-identical (gauntlet dpr1/dpr2/webkit 165/165 + apps/tiernaming/settle
  + the four-config danger torture, `RECALC_NONCONVERGENCE` absent); no recapture. Doc riders:
  `layout-system-architecture-assessment.md` §4.1/§5 + `end-of-cycle-flush-inventory.md`.
- **Tier E ✅ (`85ba908e`, 2026-07-02).** **E1** — deleted 6 redundant unconditional `__breakMoveResizeCaches()`
  calls in the apply/commit family (`_applyExtentBase`, `__commitMoveTo`, and the SimpleVerticalStackPanelWdgt /
  ScrollPanelWdgt / ListWdgt / SliderWdgt `_applyExtent` overrides) — each covered by `__commitExtent` /
  `__commitMoveBy`'s did-anything-change-guarded break, so the clipped-bounds cache version key bumps only on
  actual geometry change (the D4 discipline; F3 finishes the family with `__commitWidth`/`__commitHeight`).
  **E2** — Appendix X6 MEASURED per its promotion condition → promotion NOT met, decline now data-backed (numbers
  in X6). **E3** — the stack's per-child sizing policy (recommended width + alignment→left), previously written
  three times across `preferredExtentForWidth` / `subWidgetsMergedPreferredBounds` / `_positionAndResizeChildren`,
  now lives in the two helpers `_childWidthInStack` / `_childLeftInStack`. Byte-identical (gauntlet ×3 +
  apps/tiernaming/settle + four-config torture; no recaptures).
- **Tier F (F1–F5, F7) + Tier G (G1–G6) + escalated-G4 one-cadence-lag FIX + new build gate ✅ (`cd8fc978` +
  tests `2a73a81b8`, 2026-07-02, pushed to master).** F1 (`ScrollPanelWdgt.setContents` `extraPadding = 0`
  default), F2 (Slider's six re-layout triplets → `_reLayoutSelfAndButton`; `setValue` stops duplicating
  `updateHandlePosition`), F3 (`__commitWidth`/`__commitHeight` cache-break under a did-anything-change guard —
  finishes the D4/E1 family — + `MenuWdgt.adjustWidthsOfMenuEntries` track-changes hoist), F4
  (`LayoutSpec.isCornerOrEdgeInternal`), F5 (WindowWdgt chrome `@CLOSE_ICON_SIZE`/`_titlebarHeight`/`_chromeHeight`
  measure↔arrange mirror — fixed the parse-level `Math.round (a)+b` scope divergence), F7 (three `getRecursive*Dim`
  walkers → one `_getRecursiveStackDim` + wrappers). Tier G: G1 (stack fork comments re-grounded), G2
  ("raw/silent setters" → "immediate (geometry) mutators"), G3 (`TextWdgt.preferredExtentForWidth` header), G5
  (macro-doc renames incl. the residual `_commitExtentAndNotify` → `__commitExtent`), G6 (62-line
  `#console.log`/`#debugger` sweep across 10 files). **G4 ESCALATED (owner-directed):** instead of the planned
  comment-only marker retire, an audit of all **33 `_reLayout` overrides** classified 11 SMELLY / 17 already-fixed /
  1 no-child / 4 param-driven-or-super-first; the **11 SMELLY were actually FIXED** (apply bounds first: the 3
  patch nodes Diffing/Calculating/RegexSubstitution + ScriptWdgt, SimpleLinkWdgt, CodePromptWdgt, ConsoleWdgt,
  FridgeMagnetsWdgt, SimpleDocumentWdgt, ToolPanelWdgt, SpeechBubbleWdgt) — this **SUPERSEDES/folds in F6**. The
  stale 2023 `SUPER_*DO_LAYOUT*` markers were retired from all 29 files. **NEW build gate**
  `buildSystem/check-relayout-bounds-first.js` (wired in `build_it_please.sh`; `# relayout-bounds-first-exempt:
  <reason>` escape hatch; base `Widget::_reLayout` skipped) — proven to pass AND bite. Gates: build 0 violations
  (incl. the new gate); gauntlet dpr1/dpr2/webkit 165/165 failed:0 + apps + tier-naming + settle; four-config
  danger torture (RECALC_NONCONVERGENCE absent, 0 fails — **NB** the local `fg` wrapper had hardcoded `--shards=5`
  ahead of user flags [first-wins parse], so the torture actually ran at s5 not the §0.5 s8/s8/s8/s4; `fg` since
  fixed so `fg suite --shards=N` is honoured). The 11 fixes are **steady-state byte-identical (0 recaptures)** —
  the lag only manifests mid-gesture, which no test screenshots; ONE benign inspector member-list recapture (F7's
  new inherited `Widget._getRecursiveStackDim` shifts `macroDuplicatedInspectorDrivesCopiedTargetOnly`'s
  scroll-to-alpha by one row → tests `2a73a81b8`). **G4 drift note:** the plan expected 27 files with the 2-line
  marker; reality was 29 (the 3 `src/video-player/` files carried variant forms — a `definition:` legend + 2
  singletons — conventionalised first). **Remaining live: F8, F9** (F9's `ToolPanelWdgt` got the smell fix but NOT
  the add/addMany settle-architecture wrapper). Pre-existing wart left flagged, NOT fixed: several already-fixed
  `_reLayout` still carry a misleading `# TODO shouldn't be calling this _applyBounds from here, rather use super`
  comment (using `super` would REINTRODUCE the lag).

---

## Appendix — reassessed OUT (banked / falsified / ruled out / demoted)

Kept verbatim-in-substance so the evidence is not re-derived. **Do not promote an item out of this appendix without
new evidence of the same weight that demoted it** (X5/X6/X8 state their promotion conditions explicitly).

### X1 — Opt-1: two-flag dirty tracking + walk-DOWN settle loop — **BANKED**
**Original pitch** (assessment §4.4): replace `layoutIsValid` + climb-and-enqueue with the browser/React pair
`needsLayout` + `hasDirtyDescendant`; O(1) enqueues; walk down from dirty roots.
**⚠ FEASIBILITY FINDING (2026-07-02, fail-fast probe — reverted).** A ~2-line probe reversed the loop's processing
order (head-scan/FIFO for tail-scan/LIFO): **byte-exact 165/165 at dpr1/dpr2/webkit** ⇒ the settled layout is an
**order-independent unique fixpoint** — the durable result (cited in the Opt-2 code comment). **BUT** the two-flag
design itself is a **semantic flow-change, not a clean refactor**: Fizzygum's `_invalidateLayout` climbs
container-first, the React two-flag is child-first. Two honest builds, neither a win: **(C)** child-first = a
rewrite of the invalidation model, real breakage risk; **(B)** climb-keeping walk-down = the current loop plus a
flag whose CLEARING logic is a fresh bug surface. Also: `__markForRelayout` already dedups the work-list (push only
if `layoutIsValid`), Opt-2 shipped independently, and the flush is not a measured bottleneck. **Verdict: stays
BANKED.** If ever revisited, do (C) empirically (gauntlet is the gate) and abandon on any non-byte-exact.

### X2 — Opt-3: flush-count hygiene in multi-mutation handlers — **RETIRED (premise falsified 2026-07-02)**
**Original pitch** (assessment §4.6): a handler doing several geometry mutations self-settles once each; prefer the
compound `setBounds`. **Falsification.** The named exemplar `HandleWdgt.nonFloatDragging` is a **`switch`** — each
drag event executes exactly ONE public setter. A code sweep found only **cold one-shot builders** calling two
geometry setters in sequence — construction-time code where the orphan guard already defers the flushes. **There
is no hot-path multi-mutation handler in the tree.** The real per-frame item was the handle-drag STREAM — a
COALESCE question, shipped as Tier C.

### X3 — assessment §4.3 "encapsulate the engine state in a `layoutEngine` object" — **RULED OUT (owner)**
The owner has ruled this out (the `proper-layouts-elimination-goal` standing direction: relocating a boolean into
an engine object is "bury it deeper," not the goal). The 2 remaining phase booleans (`_recalculatingLayouts`,
`_inLayoutMutation`) are load-bearing re-entrancy/dispatch flags, not convergence devices; they stay. Do not do §4.3.

### X4 — OO-2: general OO-smells backlog remnants — **out of scope (not layout)**
Constant-naming "0b"; the `arg1..arg9` splat cleanup; the tiny optional 7f `GlassBox`; Phase-8 opportunistic (the
drifted unified-shadow offsets); the non-layout `debugger` residue (`Widget.coffee` :998 / :2581 serialization,
`WorldWdgt.coffee` ×4). Pre-existing and orthogonal — fold into a general OO pass on request.
See `docs/oo-smells-refactoring-backlog.md` / `docs/god-class-decomposition-plan.md`. *(The cache-region debug
residue formerly listed here was promoted into F8/G6, 2026-07-02 night — it sits inside layout-geometry methods.)*

### X5 — `*Coalesced` BODY-collapse onto a shared `_coalescedOrSettle` helper — **ASSESSED & DECLINED (2026-07-02 evening)**
**Pitch.** The five `*Coalesced` entrypoints repeat the same 5-line `if world?.coalescingEnabled then
@_coalescedDeclare => core else @_settleLayoutsAfter => core` fork — collapse it into one helper (~10 lines saved,
single home for the A/B switch).
**Why declined.** Lint rule **[G] auto-discovers** every method whose body calls `@_settleLayoutsAfter` as a
settling wrapper and flags any **low-level** (`_`-prefixed) caller of one. The helper would be auto-discovered, and
its five callers are all `_`-private ⇒ **five [G] violations by construction**. Dodging that costs real lint
machinery — a `WRAPPER_EXCLUDED` entry plus a new caller-guard so the exclusion doesn't open a hole for a rogue
low-level `_coalescedOrSettle` caller (neither [O] nor [G] would then cover it) — which outweighs the ~10 lines.
Today's shape is [G]-clean precisely because each entrypoint IS the discovered wrapper, called only from
non-low-level stream handlers. **Promotion condition:** someone designs the [G] carve-out + companion caller-guard
and the owner wants it; otherwise D5's comment compression captures most of the readability value at zero risk.

### X6 — Scroll-panel arrange double-work — **MEASURED (Tier E) — promotion condition NOT met; DECLINED**
**The two acknowledged redundancies** (both inside ONE settle visit, not extra visits — the re-visit counters
measured near-zero): (i) on a real resize, `ScrollPanelWdgt._reLayout` runs `_reLayoutChildren` right after the
`_applyExtent` override already ran it (the code itself calls this "redundant … idempotent"); (ii) each
content-sizing arrange MEASURES every stack child twice — once applied inside
`@contents._positionAndResizeChildren()` and again purely in `subWidgetsMergedPreferredBounds` — and text-wrap
measures are the expensive kind.
**Candidate fix shape** (if ever promoted): hand the measured union FORWARD out of the arrange (the established
Path-B hand-the-height-forward convention, extended to the children-union), and/or skip the tail re-fit when the
override's just ran — but the latter smells like a fresh suppression flag, which the standing mandate forbids.
**⛔ MEASURED 2026-07-02 (evening, Tier E) — DECLINE is data-backed.** A throwaway observation prelude (off-instance
wrappers timing `_reLayoutChildren` runs-per-`_reLayout`-visit, `subWidgetsMergedPreferredBounds`, and
`TextWdgt.preferredExtentForWidth`) over four realistic text-heavy scenarios at `--speed=normal`, dpr 1, all tests
PASS under the probe:
- *text-window resize drag* (`macroBareTextWdgtAsWindowContentReflowsOnResize`): 104 visits → 204 child re-fits — the
  (i) double-run is REAL in count (100 redundant runs) — but the redundant half cost **1.3 ms over the whole gesture**
  (≈0.013 ms/frame, peak 0.10 ms/frame): the second run's `unless aPoint.equals @extent()` guards short-circuit it.
- *document scroll* (`macroDocumentScrollsMixedTextAndClocks`): redundant 0.10 ms total; the (ii) pure re-measure
  0.5 ms total (peak 0.4 ms/frame).
- *constrained scroll-stack reflow* (`macroWindowCellsInConstrainedScrollStackReflow`): 76 redundant runs = **1.0 ms
  total** (peak 0.3 ms/frame).
- *typing into a scrolling text input* (`macroMultilineTextInputScrollsWell`): 1575 measure calls ≈ 1.6 µs each
  (wrap-cache-cheap); mergedPref 4.0 ms + text measures 2.5 ms over the whole gesture (peak frame 1.8 + 1.3 ms — but
  that is the LOAD-BEARING frame-sizing measure, not the duplicate); strictly-redundant re-fit cost 0.6 ms total.
Worst-case strictly-redundant cost ≈ **0.3–0.6 ms in a single frame, ~1 ms per whole gesture** — an order of magnitude
under the ms/frame bar. The idempotent-guard architecture already neutralizes the double-work; both fix shapes stay
unbuilt. Re-measure only if a future layout makes the second visit's guards miss (e.g. a non-idempotent arrange).

### X7 — Evening-re-read reviewed-and-NOT-selected ledger (so no future session re-derives them)
- **`getRecursive*Dim` flush-scoped memo** — already assessed in Tier A's A3: the queries are mutually recursive
  with no memo, fine at real horizontal-stack depths; build the memo only if a profile shows it hot. *(NB the
  night re-read's F7 is the DRY collapse of the three walkers — a different, orthogonal change; the memo stays
  declined.)*
- **`getDesiredDim`/`getMinDim` double `isInCollapsedSubtree` check** (wrapper + recursive body both check) —
  trivial, harmless, not worth a diff.
- **`setBounds` lacking a `_setBoundsNoSettle` core** (its thunk is inline, unlike the other four geometry
  setters) — cosmetic asymmetry; no coalesced twin needs the core, and lint [H] is silent on it. Leave.
- **The scroll-topology `instanceof` tests** (`@contents instanceof SimpleVerticalStackPanelWdgt`, `@ instanceof
  SimplePlainText…` etc.) — the type-test-elimination campaign's deferred ε set, Phase-6-entangled; not layout-core.
- **`WindowWdgt._positionAndResizeChildren` first-placement branch structure** — inherently fiddly but its 3
  re-visits are proven irreducible (`window-content-negotiation-residual-plan.md`); D4f trimmed its one dead line,
  nothing more is warranted.

### X8 — Night-re-read (2026-07-02) reviewed-and-NOT-selected ledger
- **`ScrollPanelWdgt._reLayoutChildrenAndScrollbars` one-line alias** — looks vestigial but doubles as the
  ScrollPanel-only CAPABILITY MARKER (`if @_reLayoutChildrenAndScrollbars?` gates the `newParentChoice*` re-fit,
  `Widget.coffee` ~:3341/:3350). Collapsing it would need a new marker; leave.
- **`keepContentsInScrollPanelWdgt` single caller** — a well-named 8-line clamp with one call site; the name IS the
  documentation. Inlining saves nothing. Leave.
- **`scrollX`/`scrollY` axis-mirror dedup + the hBar/vBar "visible and not collapsed" predicate repeated ×8 in
  `ScrollPanelWdgt.mouseDownLeft`/`wheel`** — pure-refactor candidates, but they sit in the MOST
  determinism-sensitive gesture code in the tree (the cadence-collapse / momentum-glide case law lives in those
  exact lines). Blast radius outweighs the line savings. **Promotion condition:** the next time that gesture code is
  opened for a real behaviour fix, fold the predicate helpers in then.
- **`GenericShortcutIconWdgt`/`GenericObjectIconWdgt` square-centering duplication** — real ~15-line dup, but
  icon-family, not engine; fold into a general OO pass (X4's bucket).
- **`ToggleButtonWdgt.setToggleState` / `SwitchButtonWdgt.resetSwitchButton` / `StretchableWidgetContainerWdgt.resetRatio`
  / the two app-level `disableDragsDropsAndEditing`** — public-ish mode setters with bare `_invalidateLayout()`;
  event-handler-driven, end-of-cycle-acceptable, and each needs its own disable-probe to classify
  (CONVERT vs ELIMINATE). Not batched into Tier F; probe individually only if the EOC gate ever flags one.
- **`LayoutSpec`'s own TODOs** (split `ATTACHEDAS_FREEFLOATING` into two constants; move `SPREADABILITY_*` out) —
  vocabulary redesign with serialization/inspector surface; out of a warts tier's scope.
- **`ToolPanelWdgt._reLayout`'s `@parent instanceof ScrollPanelWdgt`** — the type-test ε set (X7 bullet 4); not
  F9's business.
- **`CaretWdgt`/`ScrollPanelWdgt.scrollCaretIntoView` double `_positionAndResizeChildren`** — the caret follow's
  pre/post re-fit pair; determinism-exempt family (residuals-audit fam 1), measured-cheap (X6's data), and the
  caret arc just closed at single-pass. Leave.
