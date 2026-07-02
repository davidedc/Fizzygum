# Plan — layout optimizations + OO cleanup (post-seam-deletion)

**Status: REWRITTEN 2026-07-02 (second rewrite, evening) after a SECOND code-level re-read of the engine at
Fizzygum master `56f25c09` (tree clean). Self-contained; runnable cold — an executor with NO prior context starts
at §0.5.** Everything the morning revision planned is **landed and committed** — Tier A (`3218fb7a`+`cf3dbaa8`),
Tier B (`ad0bf5c7` + tests `c2ed1476`), Tier C (`5a084e51` + tests `03d495d70`) — their outcome records are kept in
§5. **Tier D — the residue OF the seam deletion itself (parameters, helpers and comments whose only reason-to-exist
was the notify-by-mutation seam deleted 2026-07-01, plus debug noise the Widget-scoped Tier A sweep never reached, a
vestigial global, and one dead parameter) — is now ALSO landed and committed (`fa4d95d7` + tests `8d3bfbf9b`,
2026-07-02); its outcome record is in §5, so the plan has no remaining live tiers.** Two candidate items from the
same re-read were **assessed and demoted to the Appendix** (X5: the `*Coalesced` body-collapse, blocked by lint
rule [G]'s auto-discovery; X6: the scroll-arrange double-work, measured-first / default-decline), alongside the
previously banked/falsified/ruled-out X1–X4.

## §0 — Why this now, and what it is NOT

The **proper-layouts / settle-convergence arc is complete** (see `layout-system-architecture-assessment.md`, esp.
§1, §2.6, §4.1): the notify-by-mutation seam was **deleted 2026-07-01** and replaced by the **settle-time up-edge**;
Stage 6 retired the convergence cap to a never-fire assert; the `*AndNotify` rename (Tier B) made every immediate
mutator's name truthful; the handle drags coalesce (Tier C). **There are no remaining deletion targets in the
mandate's sense** — every suppression/convergence boolean is gone.

The morning revision's reassessment declared the engine core clean and collected the rim warts it saw (Tiers A–C,
all landed). **The evening re-read found one class that reassessment missed: leftovers whose rationale DIED with
the seam but whose code survived it.** Concretely:

- the stack arrange still forks on a `parentWillSizeMe` parameter whose two arms became **the same call** when the
  seam died (§1 fact 1) — a "who is arranging me" axis with no remaining behavioural meaning;
- the `_resizeOwn*SkippingChildRelayout` helpers reduce to `_applyExtentBase` plus a redundant unconditional
  cache-break (the exact class Tier A's A6 sub-item 3 already validated removing);
- a vestigial global `window.recalculatingLayouts` is still written every frame yet read by nothing live in `src`
  — and it name-shadows the REAL phase boolean `world._recalculatingLayouts`, a booby-trap for readers;
- ~30 commented `#if !window.recalculatingLayouts then debugger` lines and 6 `#console.log "move N"` breadcrumbs
  survive outside the band Tier A swept;
- `setBounds` still declares the dead `widgetStartingTheChange` parameter A6 removed from the `_apply*` family;
- two comments describe the deleted seam / the completed rename as still pending — actively misleading a cold
  reader about the live mechanism (the code-layer sibling of Tier A's A8 doc repair).

**None of this is the mandate; all of it is optional.** Every item is byte-identical-intended. The one
behaviour-adjacent caveat: D4 removes redundant unconditional `__breakMoveResizeCaches()` calls, which bumps the
clipped-bounds **cache version key** less often (§1 fact 8) — cache misses cost recompute, never values; A6
sub-item 3 (landed, gauntlet + torture clean) is the precedent, and D4 carries a pre-declared fallback.

**Determinism reminder:** anything touching the settle loop / `_reLayout` / an arrange / `_invalidateLayout` / the
up-edge is a **convergence change** → it needs `./fg gauntlet` (dpr1/dpr2/webkit) **and** the danger-config torture
(`RECALC_NONCONVERGENCE` absent + 0 fails), not just the suite. In this tier that means **D4** (and the batch as a
whole, since D4 is in it). See assessment §6.4.

---

## §0.5 — Cold-execution protocol (READ THIS FIRST in a fresh session)

**The workspace.** `Fizzygum-all/` is an umbrella (NOT a git repo) holding three sibling git repos: `Fizzygum/`
(source — the ONLY place you edit code, always under `src/**/*.coffee`, plus `docs/*.md` and `buildSystem/`),
`Fizzygum-tests/` (the SystemTest suite + reference screenshots + audit tooling — item D1 touches ONE file here),
`Fizzygum-builds/` (generated output — **never edit, never grep from the workspace root**; it is ~1.3 GB). All
build/test commands go through the **`./fg` wrapper at the umbrella root** — it is cwd-correct from anywhere, kills
zombie browsers, and gates on real exit codes. Do not hand-chain `cd`s across repos.

**Baseline drift.** This plan's line numbers are exact at Fizzygum `56f25c09`. Before EVERY edit: `grep -n` the
method name (or a distinctive quoted fragment) in the named file and confirm the quoted "before" text matches what
is there. **The method name + the quoted code are authoritative; the line number is only a hint.** If a quoted
"before" does not match at all, STOP and report — do not guess. Within one file, apply a multi-edit item **from the
bottom of the file upward**, so the earlier line-number hints stay valid while you work.

**Scope discipline.** Make ONLY the edits an item's *How* block specifies. If a neighbouring line looks wrong,
note it in your end-of-tier report; do not fix it. In particular: never touch `__breakMoveResizeCaches` itself,
the fullBounds/clippedBounds cache machinery, or anything under `Fizzygum-builds/`.

**CoffeeScript gotchas (this codebase).**
- Indentation IS syntax — reproduce the exact leading spaces of the surrounding code (class methods are indented 2,
  bodies 4, nested bodies 6…). A mis-indented line silently changes scope.
- `nil` means `undefined` (a Fizzygum global) — use it, never `null`/`undefined`, in any code you write.
- One class per file; the filename equals the class name. You are only editing INSIDE existing files here.
- The build syntax-checks every `.coffee` (a fragmented compile — trust `./fg build`, not your own `coffee -c`).

**The per-item loop.** For each item: (1) run the item's pre-flight greps and confirm the expected results;
(2) apply the exact edits from the item's *How* block; (3) run `./fg build` from the umbrella root — PASS = it
prints `0 violations` and `done!!!` (≈1–2 min; `./fg build --keepTestsDirectoryAsIs` is a faster variant fine for
mid-tier iterations). Then move to the next item. Run the suites only at the end of the tier — they are the
expensive part.

**End-of-tier gates.** In order, from the umbrella root:
1. `./fg gauntlet` — build + full suite at dpr1 + dpr2 + webkit + apps smoke + the runtime audit gates.
   PASS = every leg tallies `PASS` (each suite leg = 165/165, `failed tests: 0`). Expect ≈10–15 min; announce an
   ETA and post progress every ~5 min if you are reporting to the owner live.
2. The **short danger torture** — required because D4 touches an arrange + the cache version key. Skip this step
   ONLY if you did not run D4. Run these four, one at a time:
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
fixes beyond what an item specifies.** Two pre-declared narrowings exist for D4 (see the item): sub-item D4f is
droppable alone, and the cache-break dedup has a line-level fallback.

**The one expected benign failure.** If a gauntlet leg's ONLY failure is an inspector member-list test (D4 deletes
two inspector-visible methods on the stack class, which can shift an inspected member list), that is **benign and
pre-authorised**: run `./fg recapture <failingTestName>` (recaptures dpr1+2), then re-run the failed leg to confirm
green. Recaptured reference images live in the **`Fizzygum-tests`** repo — they become a second repo's diff to show
the owner. (Item D1's prelude edit also lands in that repo.)

**Commit protocol (STRICT).** NEVER `git commit` or `git push` on your own — this is a review-driven project. When
the tier is green: present the owner a summary of the full diff (`Fizzygum`, plus `Fizzygum-tests` — D1's prelude
edit and any recapture live there) and a proposed commit message per repo, then WAIT for approval. When approved:
commit via `git commit -F <msgfile>` (never `-m` with backticks/`$()` — bash command-substitutes them and silently
corrupts the message).

**Recommended order within Tier D:** D1 → D2 → D3 → D4 → D5 (rising risk; D4 last-but-one so every cheap item is
already banked before the one that needs the torture; D5 is comment-only and can ride anywhere). A build between
items keeps blame trivially assignable. Any prefix of the order is a legitimate session's work — if you stop early,
report which items landed and which gates ran.

---

## §1 — Evidence bank: what the 2026-07-02 evening re-read verified (do not re-derive)

Each fact below is load-bearing for an item. The greps are cheap — re-run any you rely on and confirm the expected
shape before editing (drift protocol, §0.5).

1. **The `parentWillSizeMe` fork's two arms are the same call.** `SimpleVerticalStackPanelWdgt.coffee` :310–313:
   the true arm is `@_applyExtentBase new Point @width(), newHeight`; the false arm is
   `@_resizeOwnHeightSkippingChildRelayout newHeight`, whose whole body (:129–131) is an unconditional
   `@__breakMoveResizeCaches()` + `@_applyExtentBase new Point(@width(), newHeight or 0)`. Since the 2026-07-01
   seam deletion NOTHING notifies on either path (both end in the same `_applyExtentBase`; the container re-fits at
   settle time via the up-edge regardless of which apply ran) — so the arms differ ONLY by the redundant
   unconditional cache-break (fact 8) and a vacuous `or 0` (`newHeight` is always a computed number there). The
   comment at :309 — "Otherwise notify (the load-bearing cascade)" — is FALSE today.
2. **`_applyExtentBase` has no overrides** — `grep -rn "^\s*_applyExtentBase:" src --include="*.coffee"` prints
   exactly ONE line (`Widget.coffee` :1551). Same for `_applyMoveByBase` (:1228) / `_applyMoveToBase` (:1237). And
   `_applyExtentBase` breaks the caches ITSELF under its own did-anything-change guard (:1551–1556 →
   `__commitExtent` :1531). So inlining a `_resizeOwn*` call to a bare `_applyExtentBase` call changes nothing but
   the unconditional break.
3. **Exactly one caller passes `parentWillSizeMe = true`:** `ScrollPanelWdgt.coffee` :360
   (`@contents._positionAndResizeChildren(true)`). Every other `_positionAndResizeChildren` caller passes no
   argument (verify: `grep -rn "_positionAndResizeChildren(" src --include="*.coffee"` → only the :360 hit has an
   argument). `WindowWdgt` defines its own zero-arg `_positionAndResizeChildren` (:545) — unaffected.
4. **`_resizeOwn*` full census** (`grep -rn "_resizeOwn" src --include="*.coffee"` → 9 hits): the two definitions
   (`SimpleVerticalStackPanelWdgt` :125, :129), three width-calls + one height-call in `WindowWdgt` (:581, :590,
   :612, :667), one height-call in the stack (:313), one comment mention each in `Widget.coffee` (:1620) and
   `ScrollPanelWdgt.coffee` (:135). Nothing in `Fizzygum-tests` references them (grep `.js` included — the
   macro-relocation lesson).
5. **`WindowWdgt` :612 is redundant-or-buggy, never load-bearing.** It re-applies the SAME `windowWidth` already
   applied at :581 or :590 (nothing between changes the window's width — :611 `@contents._applyWidth` sizes the
   CONTENT), so on every reachable path it is a no-op modulo the unconditional cache-break. On the one UNREACHABLE
   path — content spec width `DONT_MIND` combined with height `THIS_ONE_I_HAVE_NOW` — `windowWidth` is never
   assigned, and the call would squash the window to its minimum width. No in-tree spec produces that combination:
   the `new WindowContentLayoutSpec` census is THIS×THIS (`Widget` :265, `SliderWdgt` :77, `MenuWdgt` :49) or
   DONT×DONT (`PaletteWdgt` :29, `SimplePlainTextScrollPanelWdgt` :46, `WindowContentsPlaceholderText` :14) only.
   An inert landmine + a wasted cache-key bump — delete the line (D4f, droppable alone).
6. **`window.recalculatingLayouts` is a vestigial global.** Writers: `WorldWdgt.coffee` :1391 / :1393 only (a
   true/false pair wrapping the `doOneCycle` end-of-cycle `recalculateLayouts()` call). Live readers in `src`:
   ZERO — every other hit of `grep -rn "window.recalculatingLayouts" src --include="*.coffee"` is a COMMENTED
   `#if !window.recalculatingLayouts then debugger` line (30 of them, across 30 files). One reader exists OUTSIDE
   src: `Fizzygum-tests/scripts/end-of-cycle-audit/layout-audit-prelude.js` :143 — an advisory WARN inside a
   snapshot block that is ALREADY gated on the real discriminator (`if (!this._inLayoutMutation)`, :123), so the
   WARN is a cross-check of the very flag being deleted and goes with it. NB the global is NOT
   `world._recalculatingLayouts` (the load-bearing phase boolean) — do not confuse them; only the `window.` global
   is dead.
7. **Six `#console.log "move N"` breadcrumbs survive** outside Tier A's Widget-scoped sweep (`grep -rn
   '#console.log "move' src --include="*.coffee"`): `SimpleVerticalStackPanelWdgt` :317 ("move 15"), `ListWdgt`
   :130 ("move 3"), `ActivePointerWdgt` :709 ("move 2"), `basic-widgets/SliderWdgt` :68 ("move 17"),
   `basic-widgets/ScrollPanelWdgt` :268 ("move 15"), `mixins/ClippingAtRectangularBoundsMixin` :231 ("move 1").
   Each is a standalone comment line.
8. **`numberOfRawMovesAndResizes` is a cache VERSION KEY**, not a stat: `__breakMoveResizeCaches` (`Widget.coffee`
   :1250) increments it, and it is concatenated into the `checkClippedThroughBoundsCache` / `checkClipThroughCache`
   / `checkFullClippedBoundsCache` version strings. Removing a REDUNDANT bump makes those caches invalidate *less
   often* (only on actual change) — the correct discipline; misses cost recompute, never values. Precedent: Tier
   A's A6 sub-item 3 (landed; gauntlet + torture clean).
9. **`setBounds`'s second parameter is dead.** `Widget.coffee` :813 declares `widgetStartingTheChange = nil`; the
   thunk body (:814–828) never references it. Sole src caller: `WorldWdgt.coffee` :367, one argument.
   `Fizzygum-tests` grep (`.js` included): zero `setBounds` callers. Contrast: `setExtent`/`moveTo` KEEP theirs —
   their cores consume it (`changeShouldRememberFractionalGeometry?()`, the handle-drag fractional-memory path).
10. **Two comments assert dead machinery as live/pending** (D3's targets): `Widget.coffee` :1472–1474 still says
    the `*AndNotify` "truthful rename [is] planned" — Tier B landed it the same day (this method IS the renamed
    one); `ScrollPanelWdgt.coffee` :139–140 says "The seam itself still fires for EXTERNAL content changes —
    Intent-1 — until Stage 4/5" — the whole seam was deleted 2026-07-01.
11. **Lint rule [G] auto-discovers settling wrappers** (`buildSystem/check-layering.js` ~:184: every method whose
    body calls `@_settleLayoutsAfter` joins the forbidden-wrapper set; low-level = `_`-prefixed callers of one are
    violations). This is what DEMOTED the `*Coalesced` body-collapse to Appendix X5 — a shared
    `_coalescedOrSettle` helper would be auto-discovered and its five `_`-private callers flagged. D5 therefore
    compresses only the COMMENTS.

---

## §2 — Tier D ✅ LANDED (`fa4d95d7` + tests `8d3bfbf9b`, 2026-07-02)

Seam-deletion residue + noise, shipped as one batch over the §0.5 loop and gates (D1 → D2 → D3 → D4 → D5). The full
per-item execution specs were pruned on landing, per the A/B/C convention; the outcome record — what each item did,
plus the verification — is the **Tier D bullet in §5**. The evidence bank (§1) and cold-execution protocol (§0.5)
are kept for cold-runnability of any follow-up work.

---

## §3 — Verification (commands and pass-criteria in §0.5)

- `./fg build` after every item (blame stays per-item).
- End of tier: `./fg gauntlet` (dpr1/dpr2/webkit 165/165 + apps/tiernaming/settle) — always; **plus** the §0.5
  four-config short torture **iff D4 ran** (arrange + cache-version-key change). D4f is droppable alone; D4's
  cache-break dedup has the line-level fallback spelled out in the item.
- Benign inspector recaptures pre-authorised per §0.5 (D4 deletes two inspector-visible stack methods).
- D1 sub-item 4 + any recapture land in `Fizzygum-tests` — present that repo's diff too.
- **Ask before commit/push**; `git commit -F <file>` (§0.5 commit protocol).

## §4 — Recommended sequencing

1. **Tier D** shipped as one batch (order **D1 → D2 → D3 → D4 → D5**), 2026-07-02 — `fa4d95d7` + tests `8d3bfbf9b`;
   gauntlet (dpr1/dpr2/webkit 165/165 + apps/tiernaming/settle) and the four-config danger torture all green. See §5.
2. Nothing else is live: the engine core needs no work (two re-reads, morning + evening, 2026-07-02), and the
   Appendix items stay closed unless their stated promotion conditions are met.

## §5 — Landed record (2026-07-01 → 07-02, all committed; kept for cold-runnability)

*(This revision pruned the full item-by-item specs of Tiers A/B/C from the live plan — recover them from this
file's git history at `0b96d0ef` or earlier if ever needed. Tier D's specs were likewise pruned when it landed
2026-07-02; its outcome is the §5 entry below + the code commit `fa4d95d7`.)*

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

---

## Appendix — reassessed OUT (banked / falsified / ruled out / demoted)

Kept verbatim-in-substance so the evidence is not re-derived. **Do not promote an item out of this appendix without
new evidence of the same weight that demoted it** (X5/X6 state their promotion conditions explicitly).

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
drifted unified-shadow offsets); the non-layout `debugger` residue (`Widget.coffee` :998 / the cache-check region /
:2581 serialization, `WorldWdgt.coffee` ×4). Pre-existing and orthogonal — fold into a general OO pass on request.
See `docs/oo-smells-refactoring-backlog.md` / `docs/god-class-decomposition-plan.md`.

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

### X6 — Scroll-panel arrange double-work — **MEASURED-FIRST, default-DECLINE (2026-07-02 evening)**
**The two acknowledged redundancies** (both inside ONE settle visit, not extra visits — the re-visit counters
measured near-zero): (i) on a real resize, `ScrollPanelWdgt._reLayout` runs `_reLayoutChildren` right after the
`_applyExtent` override already ran it (`super` applies the extent → the override re-fits; then the `_reLayout`
tail re-fits again — the code itself calls this "redundant … idempotent", :305–317); (ii) each content-sizing
arrange MEASURES every stack child twice — once applied inside `@contents._positionAndResizeChildren()` and again
purely in `subWidgetsMergedPreferredBounds` (:386–401) — and text-wrap measures are the expensive kind.
**Candidate fix shape** (if ever promoted): hand the measured union FORWARD out of the arrange (the established
Path-B hand-the-height-forward convention, extended to the children-union), and/or skip the tail re-fit when the
override's just ran — but the latter smells like a fresh suppression flag, which the standing mandate forbids.
**Why default-decline:** convergence-adjacent (full danger-torture territory), no measurement showing it matters,
and the mandate's history warns against re-adding "did I already do this?" state. **Promotion condition:** a
`coalescing-measurement.md`-style harness shows ≥ milliseconds/frame on a realistic text-heavy scroll arrange;
then design against §6 of the assessment (rules 1–3) and gate with the FULL torture.

### X7 — Evening-re-read reviewed-and-NOT-selected ledger (so no future session re-derives them)
- **`getRecursive*Dim` flush-scoped memo** — already assessed in Tier A's A3: the queries are mutually recursive
  with no memo, fine at real horizontal-stack depths; build the memo only if a profile shows it hot.
- **`getDesiredDim`/`getMinDim` double `isInCollapsedSubtree` check** (wrapper + recursive body both check) —
  trivial, harmless, not worth a diff.
- **`setBounds` lacking a `_setBoundsNoSettle` core** (its thunk is inline, unlike the other four geometry
  setters) — cosmetic asymmetry; no coalesced twin needs the core, and lint [H] is silent on it. Leave.
- **The scroll-topology `instanceof` tests** (`@contents instanceof SimpleVerticalStackPanelWdgt`, `@ instanceof
  SimplePlainText…` etc.) — the type-test-elimination campaign's deferred ε set, Phase-6-entangled; not layout-core.
- **`WindowWdgt._positionAndResizeChildren` first-placement branch structure** — inherently fiddly but its 3
  re-visits are proven irreducible (`window-content-negotiation-residual-plan.md`); D4f trims its one dead line,
  nothing more is warranted.
