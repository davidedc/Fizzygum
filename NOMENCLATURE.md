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

### Connection domain (LEGACY — retiring with the dataflow migration)
Do not use these terms for new mechanisms; they name the pre-dataflow wiring machinery.

| Term | Meaning |
|---|---|
| **fire / `_fireConnection`** | delivering a value along a wire to `@target[@action]` |
| **connection (calculation) token** | the cycle-guard stamps (`_acceptsConnectionToken`) — subsumed by dataflow passes |
| **cascade** | a token-stamped chain of connection firings — subsumed by dataflow passes |
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
| **socket** | the cell's widget host: presenter mount + connection target |

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
| **token** | Legacy connection domain; retires with the migration. Not reused. |
