# NOMENCLATURE.md — reserved vocabulary registry

Fizzygum has several interacting engines (layout settling, repainting, input, connections,
and — upcoming — the dataflow/calculation engine). Several of them independently reached for
the same generic words ("coalesced", "flush", "dirty", "stale"), which makes code, comments
and docs ambiguous exactly where precision matters most.

This file is the registry of who owns which word. **Rule: before naming a new mechanism,
check this file. If the word is owned by another domain, qualify it or pick another word,
and record the decision here.** Historical docs in `docs/` predating this file may use old
vocabulary; they are records and are not retro-edited (see
`docs/coalesced-nomenclature-rename-plan.md`).

## Domain vocabularies

### Layout / settle domain
The deferred-layout system: `_reLayout`, `recalculateLayouts`, settle tiers.

| Term | Meaning |
|---|---|
| **settle** | bringing layouts to a fixed point; owned exclusively by layout. Dataflow never "settles". |
| **invalidate** (layout) | `_invalidateLayout` — the climbing invalidation verb |
| **`__markForRelayout`** | the bare no-climb enqueue atom |
| **end-of-cycle flush** | the `recalculateLayouts` drain in `doOneCycle` (formerly "coalesced flush") |
| **in-place / per-event settle** | a discrete event settling immediately via `_settleLayoutsAfter` |
| **deferred-settle** (family) | geometry entrypoints that ride the end-of-cycle flush (formerly the `*Coalesced` family — see rename plan) |
| **arrange, re-fit, up-edge** | container child-placement; content→container re-fit after settle |

### Repaint domain
| Term | Meaning |
|---|---|
| **broken (rects)** | invalidated screen regions (`pushBrokenRect`, `updateBroken`) |
| **dirty** | canvas/backbuffer/text-measure invalidation (`extentWhenCanvasGotDirty`, `anyTextDirty`). NOT used by dataflow. |
| **changed / fullChanged** | widget repaint invalidation verbs |

### Input & stepping domain
| Term | Meaning |
|---|---|
| **event queue / play** | `inputEventsQueue`, `playQueuedEvents` |
| **step / stepping / fps** | the `steppingWdgts` per-cycle callback machinery |
| **cycle / frame** | one `doOneCycle` run; `WorldWdgt.frameCount` |

### Connection domain (patch-programming wiring — ported onto the dataflow engine, Phase 6)
`fire` / `wire` / `target` / `action` SURVIVE into the dataflow domain (a wire declares an edge). The
token / cascade cycle-guard machinery was DELETED in Phase 6d — the engine's visit-once recompute pass +
equal-value cutoff terminate a cascade instead. Do not reintroduce the retired terms.

| Term | Meaning |
|---|---|
| **fire / `_fireConnection`** | a wire's producer marks ITSELF stale (derives its edge from `@target`/`@action`, then `markStale`); the drain PULLS the value and delivers it — no value travels on the fire |
| **connection (calculation) token** | RETIRED (Phase 6d): the `_acceptsConnectionToken` cycle-guard stamps, DELETED — the engine's visit-once + equal-value cutoff replace them |
| **cascade** | RETIRED (Phase 6d): a token-stamped chain of connection firings — now a dataflow recompute pass |
| **wire, target, action** | these SURVIVE into the dataflow domain (a wire declares an edge) |

### Dataflow domain (NEW — the calculation engine; see `docs/specs/dataflow-engine-spec.md`)
| Term | Meaning |
|---|---|
| **stale** | a node whose value may be outdated. Identifier-level "stale" belongs to dataflow. (Pre-existing *comments* using "stale" as plain English remain fine.) |
| **stale pool** | the accumulator of stale nodes awaiting the drain |
| **`markStale` / `__poolStale`** | public policy-aware verb / bare pool-push atom (mirrors `_invalidateLayout` / `__markForRelayout`) |
| **`recalculateDataflow` / dataflow drain** | the once-per-cycle drain station (deliberately parallel to `recalculateLayouts`) |
| **recompute pass** | one visit-once batch over the stale set's downstream |
| **dataflow source / sink / edge / index** | the graph roles; the index is derived and disposable |
| **node protocol (`dataflowRecompute` / `dataflowValue` / `dataflowApply`)** | the duck-typed members a node (or edge record) may implement: recompute thunk / current-value reader / sink-application hook |
| **echo** | the redundant self-marking a legacy controller's unconditional onward-fire tail emits while the engine is applying that very node; dropped by `markStale` during application |
| **`firesPerEvent`** | per-wire delivery policy (per-event mini-pass vs pooled) |
| **equal-value cutoff** | don't propagate staleness when the recomputed value equals the old one |
| **`DATAFLOW_NONCONVERGENCE`** | the never-fire pass-count assert |

### Serialization domain
| Term | Meaning |
|---|---|
| **`{"$r": n}` / `{"$wk": key}`** | in-structure reference / well-known-object symbolic reference (`src/serialization/`) |
| **well-known object** | a per-world singleton re-bound by key on restore (`WellKnownObjects`) |
| **compact serialized form** | an immutable value's minimal record restored via its factory (e.g. Color) |

### Source-text domain
| Term | Meaning |
|---|---|
| **source** (bare) | CoffeeScript source text (`window.Foo_coffeSource`, `*_source` fields, `sourceChanged`). The dominant, pre-existing meaning. Dataflow prose must qualify ("dataflow source", "time source"); class names like `SecondsSource` are sufficiently qualified. |

### Spreadsheet domain (NEW)
| Term | Meaning |
|---|---|
| **cell / formula / commit** | a grid slot; its CoffeeScript source; the moment an edit is accepted |
| **exported value** | the principal value a widget offers to references (`exportedValue()`) |
| **presenter / `cellPresenter`** | the widget chosen to display a value; one-way glass |
| **cell widget (`CellWdgt`)** | the per-VISIBLE-cell widget: renders the value (painted scalar / hosted value-widget / presenter), its own grid edges + selection ring + overlay editor (F2/F5), + is the connection target (`cellInput`). Phase 8 generalised the Phase-4 **socket** (`CellSocketWdgt`, one per RICH cell) into this |
| **header cell (`SheetHeaderCellWdgt`)** | the per-header-cell widget (kind column / row / corner): paints its strip fill, its own edges, its letter/number label (F5). DERIVED chrome — rebuilt on restore, never adopted |
| **cells panel (`SheetCellsPanelWdgt`)** | the transparent `PanelWdgt` subclass spanning the data region (sized with the sheet, F6) and hosting the `CellWdgt`s (F5); its bounds-clipping crops the partial edge CELLS (load-bearing since F6; pre-F6 a standing guard) |
| **edge ownership (top+left)** | every grid widget strokes its OWN top + left edge segments, nobody strokes right/bottom (F5; the old outermost strokes were clipped invisible) |
| **the crossing rule** | per widget, the grid-coloured edge strokes BEFORE the dark (`headerBorderColor`) edge, so dark wins every crossing pixel — the per-widget re-statement of the old "gridlines first, darker borders last" global order (F5 receipt A; byte-identical) |
| **viewport / view origin** | the window of materialised cells over the `sheetCols`×`sheetRows` LOGICAL sheet — DERIVED from the sheet's applied extent since F6 (the `_viewportCols/Rows*` ceil/floor derivation pairs; `defaultViewportCols/Rows` = the 6×14 default open size); the origin (`viewOriginCol/Row`, sheet-space, cell-quantized) is the viewport's top-left address — DOCUMENT state, prototype-default 0 (F1) |
| **partial edge cell** | the last visible column/row when the granted extent is not cell-quantized (F6): counts as on-screen (the PARTIAL/ceil derivations), is clipped by the panel/sheet clips, selectable by click — but scroll clamps and scroll-follow use FULL (floor) counts, so the selection and the overlay editor always land on fully-visible cells, and at the max origin the partial slot shows BACKDROP |
| **materialise / recycle** | the viewport reconcile's two moves (F1): create + route a `CellWdgt` for an address entering the viewport / destroy one leaving it — EXCEPT a widget-VALUED cell, which `__hide`s in place so its hosted widget's runtime state keeps riding the tree (the hidden-rich-cell exemption, spec §13 extended to scroll) |
| **widget entry (`widgetEntry`)** | the F4 entry kind: a desktop widget DROPPED into a cell IS the cell's value (persistent `$r` field on `SheetCellRecord`, prototype-default nil; blank source; recompute checks it FIRST). Lifecycle owned by the GESTURES (drop sets; edit-commit and drag-out clear), never by `FormulaCompiler.commit` |

## Contested words — explicit rulings

| Word | Ruling |
|---|---|
| **coalesced** | Historically layout's (the `*Coalesced` setters) AND menus' (`takesOverAndCoalescesChildrensMenus`). Being renamed out of both (see rename plan). Afterwards: **banned** as an identifier everywhere; too ambiguous. |
| **flush** | Generic; in prose always qualify: "end-of-cycle flush" (layout) vs "dataflow drain". No new identifiers named `*flush*`. |
| **drain** | Prose word for work-list consumption in both domains; qualify in prose. Identifier use: dataflow only. |
| **dirty** | Repaint/canvas/text domain only. Dataflow uses **stale**. |
| **stale** | Dataflow identifiers. Generic comment English tolerated elsewhere. |
| **announce** | Banned as a term of art (was used loosely in design discussions). The verbs are `markStale` / `__poolStale`. |
| **settle** | Layout only. Dataflow "recomputes", never "settles". |
| **fire** | Wire-level delivery only (`firesPerEvent`, a wire fires). Never used for layout or repaint. |
| **volatile** | Banned. There is no volatile-cell concept: a "ticking" cell is an ordinary node with an edge from a time source. |
| **recalculate\*** | Shared verb prefix, one per domain: `recalculateLayouts`, `recalculateDataflow`. The parallel naming is deliberate — it documents the adjacent stations in `doOneCycle`. |
| **token** | Legacy connection domain, RETIRED (Phase 6d — the `connectionsCalculationToken` machinery was deleted). Not reused. |
