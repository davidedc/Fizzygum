# Prompt: review & simplify the AFFINE-TRANSFORMS work committed 2026-07-09 → 2026-07-12

You are an expert code-simplification specialist working on **Fizzygum** — a CoffeeScript GUI
framework rendered on a single HTML5 canvas — focused on enhancing clarity, consistency, and
maintainability while preserving **exact** functionality. In Fizzygum, "exact functionality" has a
mechanical definition: **the 196-test SystemTest screenshot suite must pass byte-identically, at
dpr 1 and dpr 2, under Chrome and WebKit, with zero reference recaptures.** You prioritize
readable, explicit code over compact code, and you treat the project's documented conventions and
its falsification records as binding.

Your target is the **affine-transforms arc** (rotated/scaled widget "islands":
`TransformFrameWdgt` + `TransformSpec`, pointer-plane mapping, halo rotation, drop-IN/pick-OUT
reparent-transparency, serialization, the public geometry API, and the island buffer cache). It
landed in ~30 code commits over three days (2026-07-09 → 2026-07-11), phase by phase, bug-dossier
by bug-dossier — exactly the growth pattern that leaves behind superseded scaffolding, repeated
mapping boilerplate, and special cases that later fixes quietly generalized. Your job: find that
residue and remove it, changing **how** the code does things, never **what** it does.

⚠ This arc is also a minefield of *deliberate* subtlety: several constructs that look redundant
or over-complicated are load-bearing fixes bought with A/B pixel evidence. Section 5 lists them.
When code looks strange here, your first hypothesis must be "documented reason", not "cruft" —
grep the plan doc for the symbol before touching it.

---

## 0. Ground rules (read before anything else)

- Work from `/Users/davidedellacasa/code/Fizzygum-all`. The umbrella is NOT a git repo; the three
  repos `Fizzygum/` (source — the only place you edit), `Fizzygum-tests/`, `Fizzygum-builds/`
  (generated — NEVER edit) are independent siblings. Use `git -C <repo>` instead of `cd`-chains; a
  PreToolUse guard hook blocks cross-repo `cd`-chained commands and points you to the `./fg`
  wrapper (`fg build` · `fg suite` · `fg suite --dpr=2` · `fg suite --browser=webkit` ·
  `fg gauntlet` · `fg test <name>` · `fg homepage`).
- First action: `git -C Fizzygum status`. Expected pre-existing dirt is **docs-only** (modified
  `docs/plans/affine-transforms-plan.md` and dataflow docs, one deleted plan doc, a few untracked plan
  docs). Leave all of it strictly alone. If any `src/**` file is already dirty, STOP and ask.
- **NEVER commit or push.** At the end, present a summary plus a proposed commit message and wait
  for explicit approval. (When approval comes: `git commit -F <file>` — backticks/`$()` in `-m`
  get shell-substituted by the Bash tool.)
- Scope every search. `Fizzygum-builds/latest` is ~1.3 GB; never grep from the workspace root.
- `nil` means `undefined` (project global); one class per file, filename == class name; reference
  other classes with the literal forms `extends X` / `@augmentWith X` / `new X` — the load-order
  finder regex-scans for exactly those.
- **No conclusions before evidence**: never write "byte-identical", "safe", or "no-op" in a
  report, doc, or commit message before the corresponding gate has actually passed.
- **Two-falsification stop rule**: if two shapes of the same simplification fail the gates, your
  model of the code is wrong — stop, write the finding down, move on. Do not try a third variant.

## 1. Scope — the exact commit set

Diff into each of these (`git -C Fizzygum show <hash>`), in phase order. The commit messages are
engineering documents — read them fully; each names the plan § it executes.

**Phases 1–3** (islands, rotation, layout coupling):
`44b42161` `c1d8f17c` (Phase 1: `TransformSpec` + `TransformFrameWdgt`, scale-only + click-through)
· `a5f4ef97` (Phase 2: rotation / the general warp composite) · `707f9720` (Phase 3: `claimsSpace`
layout coupling — assigned to THIS pass, not the layout pass).

**Phase 4 + rough edges R1–R4** (interaction-plane dispatch, halo rotation, property sugar):
`354e6edf` (4A-1 click mapping) · `92e8b77e` (4A-2 drag-delta mapping) · `b84b19d2` (4B halo
rotation) · `07c789cc` (4C property sugar) · `b1017899` (Phase 4 review fixes) · `b9770bb7`
(4B-universal rotate-any-widget) · `b51062e9` (R1 mouseMove mapping) · `a8c4459d` (R2 ephemeral
highlight overlays) · `6ccf1ccc` (R3 `TrackingTransformFrameWdgt`) · `0895b1d5` (R4 slider/palette
nonFloatDragging mapping).

**Phase 4D/4E** (reparenting across planes, serialization):
`cd87222c` (4D-1 drop-IN) · `2dd55413` (4D-2a pick-OUT) · `db01f1af` (4D-2b-i drop-back-INTO) ·
`7d3c7ad8` (4D-2b-ii `_dropPolicyProxy`) · `f3e5ae00` (4E serialize scalars only).

**§7.5 bug dossiers + damage routing**:
`86d3ee5e` (erase removed island-interior widget at its SCREEN footprint) · `baa566c8` (Bug A
tilted-window skin) · `419abf1e` (Bug B rotation survives close→basement→reopen) · `3809b2ea`
(Bugs D+E anchor stability + interaction transparency) · `e9aabe72` (Bug F reparent-transparency:
compensating sugar island on drop, fold + dissolve on pick) · `530a2846` (Bug G pinned-anchor
pick-up normalization) · `619db579` (stray PROTOTYPE dev-marker cleanup).

**Phase 5** (geometry API + island buffer cache):
`05e70b19` (public geometry API — the two-vocabulary law) · `17803fc0` (island buffer cache) ·
`d845a79f` (§4.4 rect-LIST dirty refinement).

Docs-only commits interleave (banner flips, hash records) — read them for the as-built record;
they need no simplification.

**Explicitly OUT of scope:** the June layout campaign and July-7 layout fixes (separate pass);
the perf/SWCanvas-pin/occlusion commits (`1c3daece` etc.); fizzytiles; anything in
`Fizzygum-tests/` beyond reading it for context.

**Primary file footprint** (touch counts from the arc — your hunting ground):
`src/basic-widgets/Widget.coffee` (19 touches — scattered island-awareness is a prime
consolidation candidate), `src/TransformFrameWdgt.coffee` (14), `src/ActivePointerWdgt.coffee`
(10), `src/WorldWdgt.coffee` (5), `src/TransformSpec.coffee` (5),
`src/TrackingTransformFrameWdgt.coffee` (3), `src/macros/MacroToolkit.coffee` (3),
`src/HandleWdgt.coffee` (3), `src/WindowWdgt.coffee`, `src/PaletteWdgt.coffee`,
`src/mixins/BackBufferMixin.coffee`, `src/HighlighterWdgt.coffee`,
`src/basic-widgets/SliderButtonWdgt.coffee`, `src/basic-data-structures/Color.coffee`,
`src/BasementWdgt.coffee`, `src/IconicDesktopSystemWindowedApp.coffee`,
`src/boot/extensions/SWCanvasElement-extensions.coffee`.

## 2. Phase 1 — build the best-practices dossier (before touching anything)

Read, in this order:

1. `Fizzygum/CLAUDE.md` — build/test commands, determinism contract, conventions (including the
   two-vocabulary summary in the integer-placement bullet).
2. `Fizzygum/docs/plans/affine-transforms-plan.md` — **the authority for this arc.** Non-negotiable
   sections: **§4.3** (the matrix math is a complete spec — "do not improvise"), **§4.11** (plane
   purity — the island's two faces), **§4.13** (the two-vocabulary law), **§5** (rejected
   alternatives — DO NOT re-attempt any of them as a "simplification"), **§6** (per-phase as-built
   records), **§7.5** (bug dossiers A–G, including the still-OPEN items), **§8** (the gotchas
   ledger — every entry is a standing constraint on your edits), **§10** (facet dossier).
3. `Fizzygum/docs/archive/affine-geometry-api-plan.md` — the screen-family (`screenBounds` /
   `localPointToScreen` / `rotationDegrees` / `accumulated*` — every name contains `screen`,
   derived, possibly fractional) vs layout-box family (`width`/`bounds`/`center` — plane-local,
   integer). The vocabularies must never blur.
4. `Fizzygum/docs/archive/island-buffer-cache-plan.md` + `island-buffer-cache-rectlist-plan.md` — the
   cache design, its coverage invariant ("byte-identical by construction"), and the two
   A/B-caught bugs its current shape encodes (see §5 below).
5. `Fizzygum/docs/architecture/layering-naming-convention.md` + `docs/architecture/lint-and-static-checks.md` — the
   `_`/`__` tier scheme, the settle tier (`*NoSettle` cores, thin-wrap canonical shape), the
   notification grid, check-layering rules [A]–[P], and the gate inventory. The transforms code
   must speak this dialect too.
6. `Fizzygum/docs/architecture/integer-pixel-placement-and-sizing.md` and `Fizzygum-tests/DETERMINISM.md` —
   read before touching anything near painting, `_reLayout`, or `ActivePointerWdgt`.

Then mine the **undocumented** practices from the code the arc converged on: the
`screenPointToMyPlane` mapping idiom, the pinned-anchor routing through `_anchorFor`/`mapPoint`,
the compensating-wrapper fold/dissolve pattern, `TransformSpec` immutability/copying discipline,
how `@serializationTransients` + the `rebuildDerivedValue` stamp handle derived state, and the
breadcrumb-comment style (⚠ markers, plan-§ references). Write the dossier to a scratch file —
it is your rubric for every edit.

## 3. Phase 2 — archaeology: find the simplification candidates

For each in-scope commit, compare what it added against the current code — the arc's later phases
repeatedly generalized its earlier ones, and bug fixes D→G layered onto the same seams. Build a
candidate list BEFORE editing. Look specifically for:

- **Phase-1 scale-only residue** superseded by the Phase-2 general warp: branches, fast paths, or
  comments that still special-case "scale-only" where the general composite now flows through.
- **Repeated screen↔plane mapping boilerplate.** 4A-1, 4A-2, R1, R4, and the Bug-E fix each added
  point-mapping at a different `ActivePointerWdgt`/`HandleWdgt`/`SliderButtonWdgt`/`PaletteWdgt`
  call site. Is there a shared "map this event position for this receiver" helper the sites can
  converge on? (Constraint from §8: a drag DELTA is mapped by mapping both endpoints and
  subtracting — do NOT invent an `inverseMapVector`.)
- **Bug-fix layering that later fixes subsumed.** Bug G's `_normalizePinnedAnchorNoSettle` runs
  before Bug F's fold — check whether earlier anchor special-cases (Bug D's `_anchorFor` routing,
  the move-primitive rides) still all pull their weight, or whether one seam now covers what two
  used to. Verify with the dossier + tests before concluding anything is redundant.
- **`Widget.coffee` island-awareness scatter.** 19 commits touched it; look for repeated
  `if`-island conditionals that could route through one well-named query or seam without changing
  dispatch order.
- **`TransformFrameWdgt` vs `TrackingTransformFrameWdgt`** — R3 subclassed in a hurry; check for
  copy-paste between them that belongs in the base.
- **Naming-convention drift.** The arc was built fast against a convention the June campaign had
  just locked: check the new methods' tier prefixes match what they DO (a helper that repaints is
  never `__`; settle-neutral cores vs `_settleLayoutsAfter` owners; thin-wrap canonical shape),
  and that new public names carry no leaked internals.
- **Dev-marker stragglers** — `619db579` dropped some PROTOTYPE comment prefixes; find the rest,
  plus stale "not yet"/TODO comments for things a later phase then built.
- **Feature-flag residue** (§4.12) — confirm the flag's current role and remove dead branches
  only if the plan doc says the flag is retired (it may deliberately remain).

Classify every candidate: (a) mechanical/no-pixel-risk, (b) structural but gate-verifiable,
(c) touches inspector-visible members, paint order, or the cache — **propose only, do not apply**
unless the gates can prove it byte-identical.

## 4. Phase 3 — apply, in small verified batches

- One theme per batch, lowest-risk first.
- After every batch: `./fg build` must pass all build gates (syntax, layering [A]–[P],
  dead-method, stinks, thin-wrap, constructor-build, relayout-bounds-first, relayout-repaints,
  test-.js syntax, ref integrity), then `./fg suite` must pass 196/196 with **zero screenshot
  diffs**. **Zero failed screenshots with a stalled shard = an uncaught exception**, not a pass —
  `fg` gates on real exit codes and clears zombie browsers.
- Because this arc's regressions are notoriously engine- and dpr-specific (the buffer-cache
  freeze bug ONLY showed on WebKit; anchor bugs only at dpr-specific rounding), the per-batch bar
  is higher here: any batch touching `TransformSpec`, `TransformFrameWdgt`, `BackBufferMixin`,
  or damage routing must also pass `./fg suite --dpr=2` and `./fg suite --browser=webkit` before
  you move on. Final acceptance for the whole pass: `./fg gauntlet` green (+ `./fg homepage` if
  boot-reachable code was touched).
- **Any screenshot diff means the change was not behavior-preserving. Revert the batch.** The
  single tolerated exception — a *benign inspector member-list recapture* caused by
  deleting/renaming a method of an inspected class — is not yours to decide: flag it, propose it,
  prefer the edit shape that avoids it.
- Transform state participates in duplication/serialization: if you move or rename a cached
  derived field, remember `deepCopy` needs the `rebuildDerivedValue` stamp
  (`@serializationTransients` alone is insufficient) and the 4E scalar-only serialization
  contract must keep holding — the round-trip macros are the oracle.

## 5. Hard constraints — load-bearing "weirdness" you must NOT simplify away

Each of these was bought with pixel-level falsification evidence. Grep the plan doc for the
symbol before touching anything adjacent; if you believe one is newly wrong, write a finding, do
not edit.

- **§5 of the affine plan — rejected alternatives.** Nothing in that list comes back, however
  elegant it looks (per-widget matrices, native-canvas transform reuse, etc. — read it).
- **Island buffer cache, bug 1:** the partial rebuild MUST use a HARD `clipToRectangle` — without
  it, shadows double. Do not relax the clip "since the rect already bounds the draw".
- **Island buffer cache, bug 2:** cache invalidation keys off
  `WorldWdgt.immutableBackBufferGeneration`, NOT `anyTextDirty()` — the "obvious" text-dirty
  check froze async glyph-atlas updates on WebKit. Do not "simplify" the generation counter away.
- **Rect-LIST refinement:** the list collapses past 8 rects / 0.75 area so the worst case equals
  v1, and correctness rests on the coverage invariant — the collapse thresholds and the
  disjointness/coalescing steps are not tunable cruft.
- **Bug F dissolve self-settles at `determineGrabs`, NOT `_deferredSettleDeclare`** — hoisting
  the settle to the non-NoSettle caller was itself a hard-won fix for a careless push.
- **Bug G ordering:** in `_normalizePinnedAnchorNoSettle`, the anchor is nil'ed BEFORE the
  compensating `_applyMoveBy`. The order is the fix.
- **Rotation input is SCREEN-plane** (raw `world.hand.position()` + `island.screenAnchor()`) —
  mapping it in-plane creates a feedback loop; and committed `rotationDegrees` is integer-
  quantized (`_quantizeRotationDegrees`) to absorb `DetTrig.atan2` wobble. Both stay.
- **Trig goes through `DetTrig.cos/sin/atan2` explicitly** (cross-engine determinism; fdlibm
  shim) — never "simplify" to `Math.*`.
- **Damage-on-detach freezes the SCREEN footprint at paint time**
  (`recordDrawnAreaForNextBrokenRects`) because the parent chain is severed before the erase-rect
  is computed — the seemingly redundant stored footprint is the fix (`86d3ee5e`).
- **A screenshot macro cannot catch broken-rect staleness** (`readyForMacroScreenshot` forces a
  full repaint) — the `getImageData` incremental-vs-full pixel-diff assertions in the tests are
  the only coverage for that class of bug; nothing you do may weaken them.
- **CoffeeScript `%%` is banned** (fragmented meta-compile drops its helper → boot
  `ReferenceError`); use the explicit `((x % 360) + 360) % 360` form the codebase uses.
- **Open items are not yours to close in passing:** Bug B's 2 latents, the EXPLICIT-ISLAND CLOSE
  dossier (probe-confirmed, owner decision pending), and the remaining §7.x backlog. If a
  simplification would interact with one, note it and steer around.
- **Naming is LOCKED** (tiers, apply-2×2, `*NoSettle`, notification grid, and the
  screen-vs-layout-box vocabularies). Also keep intact: `# … excluded from the fizzygum homepage
  build` comments, `if Automator?` guards, gate sanction markers, and every ⚠/provenance/plan-§
  breadcrumb comment — **breadcrumbs are a deliverable here**; only remove a comment that
  restates the adjacent line with zero added information.

## 6. Style rubric for the edits themselves

- Explicit beats compact: guard clauses over nesting; a named intermediate over a dense chained
  expression; `switch` or indented `if/else` over nested inline `if/then/else`. Match the
  surrounding file's idiom rather than imposing one.
- New helpers land on the correct tier for what they DO, follow the two-vocabulary law in their
  names (`screen*` iff post-transform), and keep `TransformSpec` math inside `TransformSpec` —
  no matrix arithmetic leaking into widgets.
- Consolidation is welcome; merging things the design keeps distinct is not (screen-family vs
  layout-box family; polymorphic `_apply*` vs `_apply*Base`; grab vs pickUp).
- If an edit invalidates something the affine plan or a cache plan records as as-built (a
  mechanism, a symbol, a call chain), update that doc section in the same batch — the plan docs
  are the arc's memory and their accuracy is part of the deliverable.

## 7. Deliverable

A final report, most-valuable-first:
1. **Applied simplifications** — per item: file:line, what changed, which practice it enforces
   (cite the doc §), and the gate evidence (which runs passed, including dpr2/WebKit where
   required).
2. **Proposed-but-not-applied** — class (c) items and inspector-recapture items, each with a
   concrete diff sketch and why it needs owner sign-off.
3. **Findings** — falsified attempts (with evidence), doc drift discovered (e.g. §7.5 headers
   whose status lags the banners), and any suspected real bugs (report only — this pass fixes
   nothing behavioral).
4. A proposed commit message (subject + a real explanatory body, matching this repo's style).
   Then STOP and wait — no commit, no push.
