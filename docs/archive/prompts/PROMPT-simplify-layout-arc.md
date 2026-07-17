# Prompt: review & simplify the LAYOUT work committed 2026-06-27 → 2026-07-08

You are an expert code-simplification specialist working on **Fizzygum** — a CoffeeScript GUI
framework rendered on a single HTML5 canvas — focused on enhancing clarity, consistency, and
maintainability while preserving **exact** functionality. In Fizzygum, "exact functionality" has a
mechanical definition: **the 196-test SystemTest screenshot suite must pass byte-identically, at
dpr 1 and dpr 2, under Chrome and WebKit, with zero reference recaptures.** You prioritize
readable, explicit code over compact code, and you treat the project's documented conventions as
binding, not advisory.

Your target is the **layout-engine campaign** committed to the `Fizzygum` repo between
**2026-06-27 and 2026-07-08**. It landed fast, in ~45 commits over a few days, and has since been
proven correct by the gates — which makes it exactly the kind of code where transitional
scaffolding, duplicated fix patterns, stale prose, and single-caller indirections tend to linger.
Your job: find that residue and remove it, changing **how** the code does things, never **what**
it does.

---

## 0. Ground rules (read before anything else)

- Work from `/Users/davidedellacasa/code/Fizzygum-all`. The umbrella is NOT a git repo; the three
  repos `Fizzygum/` (source — the only place you edit), `Fizzygum-tests/`, `Fizzygum-builds/`
  (generated — NEVER edit) are independent siblings. Use `git -C <repo>` instead of `cd`-chains; a
  PreToolUse guard hook blocks cross-repo `cd`-chained commands and points you to the `./fg`
  wrapper (`fg build` · `fg suite` · `fg gauntlet` · `fg test <name>` · `fg homepage`).
- First action: `git -C Fizzygum status`. Expected pre-existing dirt is **docs-only** (modified
  `docs/plans/affine-transforms-plan.md`, dataflow docs, one deleted plan doc, a few untracked plan
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

Diff into each of these (`git -C Fizzygum show <hash>`), in order. Read the commit messages
carefully — in this codebase they are engineering documents that encode intent and constraints.

**The June campaign (2026-06-27 → 2026-06-30)** — end-of-cycle flush drawdown, caret settle,
layout-enqueue unification, proper-layouts §4.1/§4.2, the layering/naming rename sweeps, the
notification-grid rename, constructors-settle:

```
961ec63d 7e45f4e9 778a7db5 a424cdb4 d60a0710 20586db1 282ea492 3a1fb165
b52a0d6f a5e89d1b a07f534a ea9ffcef 20b37277 85d0c186 cf37fa3a aca12a07
c8098e6d 838ff6e9 467644a5 95a131b2 06578419 5f923847 a1eb3d0f 921be76f
150a86a4 f321394c 81e835d3 ceef0dd7 dd3a5510 f5387a68 e473f57e 362f07ea
d3080767 41596ec8 8fd33286 08bbb29d c5ae7697 29208117 d2c90cc3 8bf7f204
```

**The July 7–8 layout-regression fixes** (edit/view ghosts, icon/plot re-lay on resize, sample
slide, scrollTo, and the INV-1 lint):

```
a88a1673 6ee377d2 0e3a5939 126e9999 5688ccd8 97e4ea97 8331309a
```

**Explicitly OUT of scope:** the affine-transforms arc (2026-07-09 → 07-11, incl. `707f9720`
claimsSpace — it touches layout but belongs to the transforms simplification pass, run
separately); the perf/SWCanvas commits; the dataflow/spreadsheet/drag-embed work (07-01 → 07-06);
anything in `Fizzygum-tests/` beyond reading it for context.

**Primary file footprint** (where the arc concentrated — your hunting ground):
`src/basic-widgets/Widget.coffee` (26 commits touched it), `src/basic-widgets/ScrollPanelWdgt.coffee`,
`src/SimpleVerticalStackPanelWdgt.coffee`, `src/WorldWdgt.coffee`, `src/WindowWdgt.coffee`,
`src/basic-widgets/CaretWdgt.coffee`, `src/ActivePointerWdgt.coffee`,
`src/basic-widgets/SliderWdgt.coffee`, `src/BasementWdgt.coffee`, plus the July-fix files:
`src/StretchableEditableWdgt.coffee`, `src/apps/{DashboardsWdgt,PatchProgrammingWdgt,ReconfigurablePaintWdgt,SimpleSlideWdgt,SampleSlideApp}.coffee`,
`src/icons/{GenericObjectIconWdgt,GenericShortcutIconWdgt}.coffee`,
`src/graphs-plots-charts/PlotWithAxesWdgt.coffee`, and `buildSystem/check-relayout-repaints.js`.

## 2. Phase 1 — build the best-practices dossier (before touching anything)

The best practices here are unusually well documented. Read, in this order:

1. `Fizzygum/CLAUDE.md` — build/test commands, determinism contract, conventions.
2. `Fizzygum/docs/architecture/layering-naming-convention.md` — **the binding naming law**: the `_`/`__` tier
   scheme (tier depth strictly increases down a call chain; `__` leaves obey a no-orchestration
   DENYLIST), the geometry-apply 2×2 (`__commit*` / `_commitBounds` / `_apply*` polymorphic /
   `_apply*Base` bypass / public setters), the settle tier (`_settleLayoutsAfter`, `*NoSettle`
   cores, the `*Connector` join lane), the notification grid
   (`wantsToBe<Event>ed` / `_beforeBeing<Event>ed` / `_reactToChild<Event>ed` …), and PaintBounds
   vs Layout vs GeometryChange vocabularies.
3. `Fizzygum/docs/architecture/lint-and-static-checks.md` — the gate inventory: check-layering rules [A]–[P],
   dead-method, stinks (ratcheted baselines), thin-wrap (the ONE canonical wrap shape:
   `[guards] then @_settleLayoutsAfter => @_<name>NoSettle <args>`), constructor-build, the
   [INV-1] relayout-repaints gate, and the in-code sanction markers
   (`# layout-apply-sanctioned` / `# nosettle-sanctioned` / `# early-return-sanctioned` /
   `# thin-wrap-exempt:` / `# constructor-build-exempt:`).
4. `Fizzygum/docs/archive/layout-system-architecture-assessment.md` — the flush model and convergence
   invariant (re-grounded 2026-06-30 to `c5ae7697`).
5. The campaign plan docs the commits execute — skim §s the commits cite:
   `proper-layouts-4.1-pure-measure-campaign-plan.md`, `proper-layouts-4.2-structural-arrange-plan.md`,
   `proper-layouts-4.4-ordered-downwalk-plan.md` (**§8 is a binding record of what was falsified**),
   `proper-layouts-eliminate-suppression-booleans-plan.md` (standing owner direction),
   `unify-layout-enqueue-primitives-plan.md`, `end-of-cycle-flush-drawdown-plan.md` (+
   `end-of-cycle-catalog.md`, `end-of-cycle-audit-tooling.md`),
   `caret-follow-in-place-settle-plan.md`, `paint-time-caret-resync-plan.md`,
   `all-constructors-settle-plan.md`, `layout-optimizations-and-oo-cleanup-plan.md` (§3 rename
   history; **Appendix X9 lists ideas considered and NOT selected — do not resurrect them as
   "simplifications"**), `integer-pixel-placement-and-sizing.md`.
6. `Fizzygum-tests/DETERMINISM.md` — read before touching anything near `_reLayout`, the
   rendering loop, or `ActivePointerWdgt`.

Then mine the **undocumented** practices: read the current bodies of the touched files and
extract the idioms the campaign converged on (e.g. the public/`_<name>NoSettle` twin shape; the
`_buildAndConnectChildrenNoSettle` constructor pattern; guard-clause style; how `# ⚠` warning
comments and plan-doc references are used as breadcrumbs). Write the dossier to a scratch file —
it is your rubric for every edit.

## 3. Phase 2 — archaeology: find the simplification candidates

For each in-scope commit, compare **what it added** against **what the code looks like now**
(later commits may have superseded parts of it). Build a candidate list BEFORE editing anything.
Look specifically for:

- **The July-7 repeated-fix pattern.** `a88a1673` added the same one-line repaint to 5
  `_reLayoutSelf` bodies; `6ee377d2` added ~12 similar lines to each of two icon classes;
  `0e3a5939` (PlotWithAxes) and `126e9999` (SampleSlideApp) solve adjacent problems. Is there a
  shared hook/base-class home for "a `_reLayoutSelf` that moves children must repaint them" that
  the [INV-1] gate (`buildSystem/check-relayout-repaints.js`) would still recognize? If yes, one
  helper + 7 call sites beats 7 hand-rolled copies. If the gate's line-scanner cannot see through
  the helper, that is a real constraint — record it and leave the copies.
- **Campaign scaffolding now dead.** Single-caller `_` orchestrators introduced mid-campaign whose
  only remaining caller is trivial; compatibility shims from the rename sweeps; branches guarded
  by conditions that deleted booleans (`@_adjustingContentsBounds` is gone) made constant.
- **Stale prose.** Comments still speaking the pre-rename vocabulary (`rawSet*`, `fullMoveTo`,
  `silent*`, `*AndNotify`, "announce up") — `c5ae7697` did one sweep; find stragglers in the
  touched files. Also comments referring to plan-§ numbers that were since renumbered.
- **Duplicated guard/enqueue patterns** around `_invalidateLayout` / `__markForRelayout` /
  `_settleLayoutsAfter` that the unification commit (`282ea492`) intended to centralize but that
  later fixes re-hand-rolled.
- **Thin wraps drifted from the canonical shape** — check-thin-wraps enforces it; wraps carrying
  incidental extra work are candidates to re-canonicalize (move the work into the core).
- **Dead methods orphaned by the campaign** that predate the dead-method gate's baseline (the
  allowlist `buildSystem/dead-method-allowlist.txt` may shelter methods that are now deletable —
  propose, don't bulk-delete).

Classify every candidate: (a) mechanical/no-pixel-risk, (b) structural but gate-verifiable,
(c) touches inspector-visible members or rendering order → **propose only, do not apply**.

## 4. Phase 3 — apply, in small verified batches

- One theme per batch (e.g. "consolidate the 7 relayout-repaint copies"), lowest-risk first.
- After every batch: `./fg build` must pass **all** build gates (syntax, layering [A]–[P],
  dead-method, stinks, thin-wrap, constructor-build, relayout-bounds-first, relayout-repaints
  [INV-1], test-.js syntax, ref integrity), then `./fg suite` must pass 196/196 with **zero
  screenshot diffs**. Remember: **zero failed screenshots with a stalled shard = an uncaught
  exception**, not a pass — `fg` fails loudly on real exit codes and clears zombie browsers.
- Final acceptance for the whole pass: `./fg gauntlet` (build + dpr1 + dpr2 + WebKit + apps)
  green, plus `./fg homepage` if you touched anything boot-reachable.
- **Any screenshot diff means the change was not behavior-preserving. Revert the batch** and
  reclassify the candidate. The single tolerated exception: deleting/renaming a method of a class
  an inspector test displays changes its member list — a *benign inspector recapture* is
  acceptable to the owner **but is not yours to decide**: flag it, propose it, and prefer the
  variant of the edit that avoids it.
- A new dead-method-gate failure after a deletion usually means you orphaned a helper — deleting
  the orphan too is the better simplification; verify it isn't reached dynamically first
  (macro `.js` strings and the harness count as references; the gate already scans them).

## 5. Hard constraints — things that look like simplification targets but are NOT

These were each bought with falsification evidence. Do not re-attempt; if you think one is newly
wrong, write it up as a finding instead of editing.

- **The container re-fit seam stays.** Its deletion was attempted and FALSIFIED (`c8098e6d`;
  binding record in `proper-layouts-4.4-ordered-downwalk-plan.md` §8). The settle-time up-edge
  (`_reFitMyTrackingContainerAfterSettle` → `_reFitContainer` valve) is the landed design.
- **The announce-up verbs are banned** (rule [N]) — never revive `_announce*ToContainer`, even as
  a "cleaner" refactor of the up-edge.
- **The bounds caches cleared by `__breakMoveResizeCaches` are LIVE** — do not delete them.
- **`_settleLayoutsAfterBatch` was deleted deliberately** — do not reintroduce a batching settle.
- **Naming is LOCKED.** The `_`/`__` tiers, the apply-2×2 corner names, `*NoSettle`, `*Base`,
  `*Connector`, and the notification-grid shapes are convention, co-designed with the lints. A
  rename is out of scope even if you'd prefer another name. (Beware the 2026-07-02 MEANING SWAP:
  in pre-swap history `_applyExtent` named what is now `_applyExtentBase`.)
- **`check-coffee-syntax.js` must never become a whole-file compile** — the browser compiles
  fragment-wise; whole-file false-fails ~300 of ~500 sources.
- **Determinism idioms are load-bearing**: no wall-clock (`Date.now`/`setTimeout`) in
  layout/render/input logic; event-time only. CoffeeScript `%%` is banned repo-wide (the
  fragmented meta-compile drops its helper → boot-time `ReferenceError`).
- Keep intact: `# … excluded from the fizzygum homepage build` comments, `if Automator?` guards,
  every gate sanction marker, and every `⚠`/provenance/plan-reference comment. **In this codebase
  breadcrumb comments are a deliverable**, not noise — only remove a comment that restates the
  adjacent line with zero added information; when in doubt, keep it.

## 6. Style rubric for the edits themselves

- Explicit beats compact: guard clauses (`return unless …`) over nesting; a named intermediate
  over a dense chained expression; `switch` or indented `if/else` over nested inline
  `if/then/else`. Match the surrounding file's idiom (comprehension vs loop) rather than imposing
  one.
- New helpers must land on the correct tier for what they DO (a helper that repaints can never be
  `__`; rule [I] is a hard gate) and follow the family vocabulary where one exists.
- Consolidation is welcome where the convention supports it — `aca12a07` ("DRY the move twins")
  is in-repo precedent — but never merge methods the convention keeps distinct (e.g. grab ≠
  pickUp; polymorphic `_apply*` ≠ `_apply*Base`).
- If an edit invalidates something a plan doc records as as-built (a mechanism, a call chain),
  update that doc section in the same batch — doc accuracy is part of the deliverable.

## 7. Deliverable

A final report, most-valuable-first:
1. **Applied simplifications** — per item: file:line, what changed, which practice it enforces
   (cite the doc §), and the gate evidence (which runs passed).
2. **Proposed-but-not-applied** — class (c) items, inspector-recapture items, allowlist
   deletions: each with a concrete diff sketch and why it needs owner sign-off.
3. **Findings** — falsified attempts (with evidence), doc drift discovered, and any suspected
   real bugs (report only — this pass fixes nothing behavioral).
4. A proposed commit message (conventional to this repo's style: subject + a real explanatory
   body). Then STOP and wait — no commit, no push.
