# Damage-vocabulary unification — pixels say "damage", layout says "dirty"

**EXECUTED IN FULL + CLOSED 2026-08-18 (all three phases, same session as authoring). Kept as the rename ledger.**

**Mandate: eliminate the vocabulary split, not catalogue it.** After this arc, a pixel region
needing repaint is called **damage** everywhere — the world's per-cycle rect machinery, the
in-flight paint clip, and the island-buffer cache — and **dirty** survives ONLY as the layout
engine's invalidation vocabulary. No synonym map, no "layering" apologia: the map dies because
the split dies.

---

## §0 Orientation

Fizzygum (CoffeeScript GUI framework, one `<canvas>`, ~470 classes as `SourceVault` text compiled
in-browser; umbrella `Fizzygum-all/` holds the three sibling repos; all commands via
`/Users/davidedellacasa/code/Fizzygum-all/fg`). Rendering is a damage-rectangles repaint loop:
widgets mark themselves via the PRIVATE `_changed()`/`_fullChanged()`, the world derives concrete
rects per cycle and repaints them.

**Why now:** the naming-gloss audit (BACKLOG § "Naming-gloss audit 2026-08-18", closed at Fizzygum
`20dbb747`) measured three words for the repaint region — `broken` (169, the Morphic.js stratum),
`dirty` (76, the generic word every newer subsystem reached for), `damage` (66, the recent
appearance-paint vocabulary) — and established the split is **era stratification, not design**: the
three biggest files mix all three (WorldWdgt b=160/d=39/dmg=14, Widget b=38/d=22/dmg=25,
TransformFrameWdgt b=7/d=38/dmg=17). The owner ruled: unify (this plan), rather than document the
strata.

**The critical reframe:** there IS one distinction worth a vocabulary boundary, and it exists today
only by accident — **pixels vs layout**. `hasDirtyDescendant`/`dirtyRoots` (layout invalidation)
are a genuinely different concept from every damage rect, and after this arc "dirty" means exactly
that and nothing else. The unification is not tidying; it *creates* a meaningful two-word
vocabulary.

## §1 The law (write this into the code-facing doc in Phase 3)

- **damage** = a pixel REGION needing repaint, in any of its three lives: the world's per-cycle
  rect list (derived by flesh-out, repainted by the paint station), the in-flight clip descending
  the paint recursion (`damageBox`/`localDamageBox`), and a kept surface's invalidated regions
  (the island buffer's rect list).
- **dirty** = layout-engine invalidation state (`hasDirtyDescendant`, `dirtyRoots`,
  `__flagHasDirtyDescendantUpwards`, `_widgetsFlaggedHasDirtyDescendant`). Nothing else.
- Deliberately NEITHER (scoped out, do not rename): the text-atlas settle-gate booleans
  (`anyTextDirty`/`swCanvasAnyTextDirty`/`textDirty` — "needs recomposite" state wired into
  DETERMINISM.md §3g, the screenshot-ready gate and `fg fuzz`; 7 src + ~38 tests sites; renaming
  churns a safety-critical vocabulary for zero clarity); `StretchableCanvasWdgt.extentWhenCanvasGotDirty`
  (an app's content-change extent memo, not a repaint region); `SWCanvasBrokenTests`/`brokenTestNames`
  in the tests repo (broken = FAILING, a different word entirely); English prose "is broken"
  (e.g. TransformFrameWdgt's two `alert "... is broken (island)"`).

## §2 Exact current state (measured 2026-08-18 at Fizzygum `20dbb747` / tests `69c9693de`)

Line numbers drift — the NAME is authoritative, re-grep before trusting a line.

**World machinery (WorldWdgt + Widget + duplication):** `broken: undefined` (WorldWdgt:293,
per-cycle: `_updateBroken` starts `@broken = []`, so it is NOT a cross-cycle queue — do not name it
one); `_updateBroken` (the paint station: flesh-out → dedupe → repaint; 12 src + **26 tests-repo**
sites incl. the paint-truthfulness gate); `_fleshOutBroken`/`_fleshOutFullBroken`;
`_pushBrokenRect`; `_mergeBrokenRectsIfCloseOrPushBoth`; `_rectAlreadyIncludedInParentBrokenWidget`;
`_resetDataStructuresForBrokenRects`; `_recordDrawnAreaForNextBrokenRects` (WorldWdgt) +
`recordDrawnAreaForNextBrokenRects` (Widget, public); `_showBrokenRects` (dev overlay);
`eachBrokenRect`; `alignCopiedWidgetToBrokenInfoDataStructures` (Widget deep-copy hook →
`world.noteWidgetCopied`); `srcBrokenRectIndex`/`dstBrokenRectIndex` (Widget fields, INDICES into
`world.broken`; in `@serializationTransients` as STRING literals in Widget.coffee AND
`Fizzygum-tests/Automator-and-test-harness-src/WorldTestSupport.coffee` AND
`Fizzygum-tests/scripts/serialization-roundtrip-headless.js` — the three-way sync point);
`brokenRectMargin` (WorldWdgt+TransformFrameWdgt; 14 tests-repo sites + 6 shadow tests' metadata);
locals `brokenWidget` (72)/`brokenWidgetAncestor` (16)/`sourceBroken`/`destinationBroken` (16 each,
they hold RECTS)/`mergedBrokenRect`(+Area); `duplicatedBrokenRectsTracker`/
`numberOfDuplicatedBrokenRects`; class switch `@dirtyRectListEnabled: true` (WorldWdgt:227, read by
TransformFrameWdgt:466; 6 tests-repo sites).

**Island buffer + occlusion (dirty-for-pixels):** `_islandBufferDirtyRect` (TransformFrameWdgt:38 —
`undefined | Array<Rectangle> | "all"`, a LIST named singular; ALSO a string in TransformFrameWdgt's
own `serializationTransients` at :64); `_depositIslandBufferDirtyRect`; `_coalesceDirtyList`;
`ISLAND_DIRTY_MAX_RECTS`/`ISLAND_DIRTY_AREA_FRACTION`; `mapRectToScreen`'s boolean param
`depositBufferDirty` (Widget:1407, comments in WorldWdgt ~:981/:1032); occlusion/clipping locals
`dirtyPart` (7)/`dirtyPartOfFrame` (8)/`dirtyRect` (2, incl. the TransformFrameWdgt:510 loop var).

**Prose carrying the old words (Phase 3):** root umbrella `CLAUDE.md` + `Fizzygum/CLAUDE.md`
("broken-rectangles (dirty-region) repaint loop", `_updateBroken` mentions),
`Fizzygum-tests/DETERMINISM.md`, `docs/architecture/serialization-duplication-reference.md`
("per-frame broken-rect bookkeeping" row), `docs/architecture/transforms.md` (§4.4 "dirty
coalescing", §8.1), `docs/plans/occlusion-culling-plan.md` (ACTIVE plan → must stay true),
`buildSystem/check-invalidation-receivers.js` header comment ("The paint executor `_updateBroken`"),
`src/macros/MACRO-PATTERNS.md`, present-tense code comments across src (~80 bare `broken` + ~59
bare `dirty`, each needing a pixel-vs-layout-vs-neither read), and the `"brokenRects"` string in
7 island/shadow tests' metadata (`SystemTest_macro*.js` line ~15) whose `visualisation.html` files
are GENERATED — regenerate, never hand-edit. `docs/archive/**` and memory notes stay verbatim
(historical record).

**Gates that reference the names:** none structurally — only the check-invalidation-receivers.js
COMMENT. No dead-method-allowlist entries (verified by grep).

## §3 Why it is shaped this way

`broken` is inherited Morphic.js vocabulary (the framework's ancestor called damage regions "broken
rects"); `dirty` is the industry-generic word each newer arc (island buffers 2026, ordered
down-walk layout, occlusion culling) reached for independently; `damage` entered with the 2026
appearance-paint convention (`localDamageBox`) and was reinforced by the naming-gloss audit's
`damageBox` tuple rename. Nobody chose the split; each stratum was locally consistent.

## §4 The name table (LOCKED — the whole mechanical surface)

| old | new | note |
|---|---|---|
| `world.broken` / `@broken` | `@damageRects` | per-cycle list, NOT a queue |
| `_updateBroken` | `_repaintDamagedRects` | the paint station: derive + repaint |
| `_fleshOutBroken` / `_fleshOutFullBroken` | `_fleshOutDamage` / `_fleshOutFullDamage` | |
| `_pushBrokenRect` | `_pushDamageRect` | |
| `_mergeBrokenRectsIfCloseOrPushBoth` | `_mergeDamageRectsIfCloseOrPushBoth` | |
| `_rectAlreadyIncludedInParentBrokenWidget` | `_rectAlreadyIncludedInParentDamagedWidget` | |
| `_resetDataStructuresForBrokenRects` | `_resetDataStructuresForDamageRects` | |
| `(_)recordDrawnAreaForNextBrokenRects` | `…ForNextDamageRects` (both) | Widget's is PUBLIC → inspector-visible |
| `_showBrokenRects` | `_showDamageRects` | dev overlay |
| `eachBrokenRect` | `eachDamageRect` | |
| `alignCopiedWidgetToBrokenInfoDataStructures` | `alignCopiedWidgetToDamageInfoDataStructures` | minimal-change; inspector-visible ('a…' sorts to the top of member lists) |
| `srcBrokenRectIndex` / `dstBrokenRectIndex` | `srcDamageRectIndex` / `dstDamageRectIndex` | + the STRING literals in all three transients lists (both repos) |
| `brokenRectMargin` | `damageRectMargin` | + 6 shadow tests' metadata, regen visualisations |
| `brokenWidget` / `brokenWidgetAncestor` | `damagedWidget` / `damagedWidgetAncestor` | 88 local/param sites |
| `sourceBroken` / `destinationBroken` | `sourceDamageRect` / `destinationDamageRect` | they hold rects — name the type truthfully |
| `mergedBrokenRect`(`Area`) | `mergedDamageRect`(`Area`) | |
| `duplicatedBrokenRectsTracker` / `numberOfDuplicatedBrokenRects` | `duplicatedDamageRectsTracker` / `numberOfDuplicatedDamageRects` | |
| `@dirtyRectListEnabled` | `@damageRectListEnabled` | class-level switch; 6 tests sites |
| `_islandBufferDirtyRect` | `_islandBufferDamageRects` | fixes the singular-list lie too; + TransformFrameWdgt's OWN transients string |
| `_depositIslandBufferDirtyRect` | `_depositIslandBufferDamageRect` | deposits ONE rect — singular is honest |
| `_coalesceDirtyList` | `_coalesceDamageList` | |
| `ISLAND_DIRTY_MAX_RECTS` / `ISLAND_DIRTY_AREA_FRACTION` | `ISLAND_DAMAGE_MAX_RECTS` / `ISLAND_DAMAGE_AREA_FRACTION` | |
| `depositBufferDirty` (param) | `depositBufferDamage` | `Widget.mapRectToScreen` |
| locals `dirtyPart` / `dirtyPartOfFrame` / `dirtyRect` | `damagedPart` / `damagedPartOfFrame` / `damageRect` | occlusion + island loops |

**KEEP:** the four layout-dirty names (§1) and everything in §1's scoped-out list.

## §5 Central risks

1. **Two-repo atomicity.** The tests harness CALLS the renamed internals (`world._updateBroken()`
   ×26, `recordDrawnAreaForNextBrokenRects` ×4, `_fleshOutFullBroken` ×2, `dirtyRectListEnabled`
   ×6, `world.broken` reads) and the three transients string lists must match Widget's field names
   or the serialization gauntlet leg fails. Edit BOTH repos before running ANY suite; commit as one
   pair.
2. **Inspector member-list churn → screenshot recaptures.** Two PUBLIC Widget methods rename
   (`recordDrawnAreaForNextDamageRects`, `alignCopiedWidgetToDamageInfoDataStructures` — the
   latter alphabetically near the top, likely inside captured inspector crops). Expect a small
   recapture set (C2 precedent: a Widget member ≈ 2 recaptures). Protocol: gauntlet → `fg diffpage`
   each failure → NAME the difference (must be exactly a member-list row change) → fresh build →
   `fg recapture --auto`.
3. **The bare-word prose sweep is NOT mechanical.** ~80 `broken` + ~59 `dirty` bare-word comment
   uses each need a pixel/layout/neither read ("is broken (island)" alerts, "broken tests",
   layout-dirty prose must survive). Do it file-by-file with the diff read before writing, never a
   blanket substitution (the perl-deindent/blanket-edit memory).
4. **`\barea\b`-class trap does not recur here** — every renamed identifier is a distinctive token;
   plain whole-word substitution per file list is safe for §4. The bare words are the only manual
   part.

## §6 Phases + verification protocol

- **Phase 1 — the §4 identifier table, both repos in one batch.** Whole-word perl per scoped file
  list; verify ZERO leftovers with ABSOLUTE-path greps (a cwd-vacuous grep reads as success — this
  bit on 2026-08-18); read the git diff (insertions == deletions per file for pure renames).
  Gate: `fg presuite` (background, wait for the notification).
- **Phase 2 — prose + docs.** Present-tense comments in src, the two CLAUDE.mds, DETERMINISM.md,
  the architecture docs + occlusion plan, check-invalidation-receivers.js comment, MACRO-PATTERNS,
  the 7 tests' `"brokenRects"` metadata string + regenerate their visualisations
  (`node scripts/make-visualisation.js <name>` from Fizzygum-tests). Add the §1 law to
  `docs/architecture/appearance-paint-convention.md` (short — the law, not a synonym table).
  Gate: build (the comment stink gates run on it).
- **Phase 3 — full `fg gauntlet`** + risk-2 recapture protocol if inspector tests fail.
- **Close:** BACKLOG (mark the owner-gated vocabulary item EXECUTED, pointing here), archive this
  plan per docs/README.md loop, memory note update.

## §7 Rejected alternatives (do not re-attempt)

- **The synonym map / "declare the layering deliberate"** — REJECTED BY MEASUREMENT 2026-08-18:
  the strata are era-correlated, not subsystem-correlated (the three core files mix all three
  words), so a map would rationalise noise. Owner chose unification.
- **Renaming the text-atlas `*Dirty` flags into the law** — do not: they are settle-gate STATE
  (§1), and that vocabulary is load-bearing across DETERMINISM.md §3g/§3i, the fuzz tool and ~38
  harness sites.
- **`@damageQueue` for `world.broken`** — wrong: the list is rebuilt from scratch inside the paint
  station each cycle (`@broken = []` first line), nothing queues across cycles.

## §8 References

`docs/BACKLOG.md` § "Naming-gloss audit 2026-08-18" (the audit that measured the split; its
detectors live in `Fizzygum-tests/.scratch/naming-gloss-audit.js` + `naming-dup-comments.js`) ·
`docs/architecture/appearance-paint-convention.md` (the damage-box law this vocabulary joins) ·
`docs/architecture/transforms.md` §4.4/§8.1 (island buffer) · memory notes
`naming-gloss-audit-arc`, `pin-contract-sweep-c2` (inspector-churn precedent).

## §9 STATUS BOX (update as phases land)

- Phase 1: DONE 2026-08-18 (identifiers, both repos; presuite green 112s).
- Phase 2: DONE 2026-08-18 (prose + docs + the law in appearance-paint-convention.md + 12 visualisations regenerated).
- Phase 3: DONE 2026-08-18 — gauntlet 16/16 EXIT=0 (378s), ZERO recaptures (the inspector-churn risk never materialised: neither renamed public Widget method sits in a captured crop); the serialization leg failed IN-WAVE with the boot-storm infra flake (world not ready in 30s, before any check ran) and PASSED alone — the full 80+ checks incl. the renamed transients ran green serially.

## §10 Cold-start prompt (paste into a fresh session to continue)

> Continue `Fizzygum/docs/plans/damage-vocabulary-unification-plan.md`. Orient: `fg status`
> (both repos must be clean unless §9 says Phase 1 landed uncommitted); read §9 for what's done;
> re-grep any §2 name before trusting it. Execute the remaining phases in order with their gates;
> both repos edit together, commit as one pair, present commit messages and WAIT for owner
> approval. Working rules: absolute paths, `git -C`, `git commit -F`, long ops in background
> awaiting the notification, no `git stash`, recaptures only after a fresh build and a named
> diffpage review.
