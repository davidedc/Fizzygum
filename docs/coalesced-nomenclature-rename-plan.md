# Coalesced-nomenclature rename plan

Free the contested vocabulary — above all the word **"coalesced"** — before the dataflow
(calculation) engine work begins, so that the two adjacent per-cycle drains
(`recalculateLayouts`, upcoming `recalculateDataflow`) never share ambiguous words in code,
comments or docs. Companion documents: `NOMENCLATURE.md` (the resulting vocabulary registry,
lands with this plan) and `docs/specs/dataflow-engine-spec.md` (the consumer of the freed
vocabulary).

**Zero behavior change.** This plan renames identifiers, comments and living docs only.
Verification is the full gate: syntax check + `./build_and_smoke.sh` + `./build_and_test.sh`
(all 160 SystemTests pixel-identical — comments and identifier names ship inside the
source-as-text batches, but compile away and cannot affect pixels).

## 1. Inventory (verified 2026-07-04)

"coalesc" appears 314 times across `src`, `buildSystem` and `docs`. Three distinct meanings:

### 1a. The layout deferred-settle tier — the real rename target
Identifier family (all in `src/basic-widgets/Widget.coffee` plus call sites in
`CaretWdgt`, `ScrollPanelWdgt`, `HandleWdgt`, `StackElementsSizeAdjustingWdgt`,
`SimplePlainTextPanelWdgt`, `SimplePlainTextScrollPanelWdgt`, `WorldWdgt`):

| Current | Meaning |
|---|---|
| `_moveToCoalesced`, `_setExtentCoalesced`, `_setWidthCoalesced`, `_setHeightCoalesced`, `_setMaxDimCoalesced` | the five geometry entrypoints that defer their settle to the ONE end-of-cycle flush (stream handlers only; rule [O] allowlist) |
| `_coalescedDeclare` | wraps a NoSettle core and declares the end-of-cycle mutation |
| `_coalescedDeclarationDepth` (world) | declaration-depth counter for the audit |
| `world.coalescingEnabled` | the A/B switch (both branches reach the NoSettle core) |

Enforced/known by `buildSystem/check-layering.js` (rule [O] caller allowlist; the
auto-declared treatment of `*Coalesced` calls) — the lint's patterns and rule text must be
updated **in the same commit** as the identifier sweep so the gate never goes red.

### 1b. The menu-takeover meaning — unrelated, renamed for full de-collision
`takesOverAndCoalescesChildrensMenus` (+ the macro helper reference
`macroScrollPanelCoalescesChildMenu` in `src/macros/`): a scroll panel presenting its
children's menu entries as its own. Semantically "merges", not "coalesces".

### 1c. Prose and docs
~270 comment/doc occurrences describing the end-of-cycle flush and "coalesced streams":
`src` comments, `src/macros/MACRO-PATTERNS.md` (4), `docs/coalescing-measurement.md` (19)
and the `docs/end-of-cycle-*` / `deferred-layout-*` families. `CLAUDE.md`: zero (already clean).

### 1d. Other contested words (no rename needed — rulings only)
- **stale** — ~150 occurrences, all plain-English comments (often uppercase for emphasis);
  no identifiers. Dataflow may claim identifier-level "stale". No sweep.
- **dirty** — identifiers exist but all in the repaint/canvas/text domain
  (`extentWhenCanvasGotDirty`, `anyTextDirty`); stays there. No sweep.
- **flush / drain / announce / fire / settle / token** — rulings recorded in
  `NOMENCLATURE.md`; prose qualification going forward; no retro sweep of code comments
  beyond the coalesced-family files already being touched.

## 2. Decided renames

### Identifiers (1a) — the `DeferredSettle` family
Chosen to align with the established "deferred layout" campaign vocabulary; the docs'
long-standing term "end-of-cycle flush" remains the name of the drain itself.

| Old | New |
|---|---|
| `_moveToCoalesced` | `_moveToDeferredSettle` |
| `_setExtentCoalesced` | `_setExtentDeferredSettle` |
| `_setWidthCoalesced` | `_setWidthDeferredSettle` |
| `_setHeightCoalesced` | `_setHeightDeferredSettle` |
| `_setMaxDimCoalesced` | `_setMaxDimDeferredSettle` |
| `_coalescedDeclare` | `_deferredSettleDeclare` |
| `_coalescedDeclarationDepth` | `_deferredSettleDeclarationDepth` |
| `world.coalescingEnabled` | `world.deferredSettlingEnabled` |

(Considered and rejected: `*EndOfCycle` suffix — describes *when*, not *what*, and reads
worse on the declare/depth members; `*Streamed` — conflates the caller's nature with the
mechanism.)

### Identifiers (1b)
| Old | New |
|---|---|
| `takesOverAndCoalescesChildrensMenus` | `takesOverAndMergesChildrensMenus` |
| `macroScrollPanelCoalescesChildMenu` (macro verb) | `macroScrollPanelMergesChildMenu` — **note**: macro verbs are recorded in SystemTest macro scripts in `Fizzygum-tests`; rename only with its cross-repo step (§4), or keep the old verb as an alias until then. |

### Prose (1c)
| Old phrase | New phrase |
|---|---|
| "coalesced flush", "the coalesced end-of-cycle flush" | "the end-of-cycle flush" |
| "coalesced stream", "coalesced input" | "deferred-settle stream(ed input)" |
| "coalescing" (the mechanism) | "deferred settling" |

Living docs swept: `src/**` comments in the touched files, `src/macros/MACRO-PATTERNS.md`,
`buildSystem/check-layering.js` rule text. **Historical plan/measurement docs in `docs/`
(`coalescing-measurement.md`, `end-of-cycle-*`, `deferred-layout-*`, etc.) are records and
are NOT retro-edited**; `NOMENCLATURE.md` notes that pre-rename docs use old vocabulary.

## 3. Execution steps

1. Land `NOMENCLATURE.md` + this plan (docs-only commit — this commit).
2. Identifier sweep 1a + `check-layering.js` update, one commit. Mechanical global rename;
   the class sources ship as text, so the sweep is a plain textual rename across `src/`
   with no serialization concerns (none of these names appear in saved documents).
3. Identifier sweep 1b (menu merge rename) + prose sweep 1c, one commit. If the macro verb
   is exercised by existing SystemTests, keep `macroScrollPanelCoalescesChildMenu` as an
   alias delegating to the new name until §4 completes.
4. Cross-repo step (separate PR in `Fizzygum-tests`, NOT part of this repo's sweep — noted
   here per plan scope): update `DETERMINISM.md` vocabulary ("coalesced" phrasing around the
   end-of-cycle flush), the tests-repo `CLAUDE.md`, and any macro scripts using the renamed
   macro verb; then drop the alias from step 3. (The sibling repo is not present in this
   checkout; occurrences inferred from references in this repo's `CLAUDE.md` and
   `src/macros/MACRO-PATTERNS.md` — verify by grep there before executing.)
5. Verification after each code commit: `./build_it_please.sh` (syntax gate),
   `./build_and_smoke.sh`, `./build_and_test.sh` (full suite; expect zero pixel diffs).

## 4. Risks / notes

- The five deferred-settle entrypoints are `_`-private and allowlisted by rule [O]; the
  lint update and the rename must be atomic or the build gate fails (that is the gate
  working as intended).
- `world.coalescingEnabled` is an A/B switch that may be referenced from console/debug
  workflows; grep for string references (none found in `src`) and mention in the commit
  message.
- After step 4 completes, "coalesced" should have zero occurrences outside historical
  `docs/` records; at that point the word becomes banned-for-identifiers per
  `NOMENCLATURE.md`.
