> **ARCHIVED — COMPLETE (2026-07-17 restructure).** RETIRED 2026-07-01 — consolidated into layout-system-architecture-assessment.md, now the canonical doc.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Deferred-layout: OVERVIEW — RETIRED (consolidated into the architecture assessment)

**This doc is retired (2026-07-01).** Its content — the deferral aim/model, the verification gauntlet, the gotchas, and
the maximal SCHEDULE/APPLY invariant + lint `[F]` — has been **consolidated into
[`layout-system-architecture-assessment.md`](layout-system-architecture-assessment.md)**, which is now the single
canonical description of the layout engine and the rulebook for working with it:

- **How the engine works** (the per-frame spine, the flush model, the settle engine, the two sizing philosophies, the
  end-of-cycle taxonomy) — assessment §2.
- **Introducing a new layout — the rules + the static/dynamic checks** (no read-backs; single-pass; the tiers/FLOWRULE;
  the maximal SCHEDULE/APPLY invariant + lint `[F]`; the gauntlet commands; the gotchas) — assessment **§6** (this is
  where the OVERVIEW's §1/§7/§8/§11 now live).
- **What was built and what remains** (the pure measure, the non-notifying arrange, the **2026-07-01 seam deletion**
  via the settle-time up-edge, Stage 6, the caret/window single-pass work; the remaining optimizations) — assessment
  §4 + `layout-optimizations-and-oo-cleanup-plan.md`.

**Why it was retired.** The OVERVIEW was the deferred-layout *campaign's* entry point (last substantively updated
2026-06-22, pre-naming-campaign). The campaign is long complete, and the engine has since been through the
proper-layouts arc and the 2026-07-01 seam deletion — which **overturned** the OVERVIEW's §3 "deferred re-queue is the
mechanism" framing (the notify-by-mutation seam it described is now deleted, replaced by the settle-time up-edge). Rather
than re-ground a second canonical doc in parallel, its durable content moved into the assessment.

**Pre-naming-campaign → current name map** (for grepping older commits — the OVERVIEW used the old names throughout):
`rawSet* / fullRawMove*` → `_apply*AndNotify` · `silentRaw*` → `_commit*AndNotify` · `_arrangeApply*` → bare `_apply*` ·
`_setExtentBoundsNoNotify` → `__commitExtent` · `_markForRelayoutNoClimb` → `__markForRelayout` ·
`rawSetWidthSizeHeightAccordingly` → `_setWidthSizeHeightAccordingly` · `fullMoveTo/fullMoveWithin` → `moveTo/moveWithin` ·
`mutateGeometryThenSettle` → `_settleLayoutsAfter` · `settleLayoutsOnceAfter` → `_settleLayoutsAfterBatch` (since
**deleted**) · `_reFitContainerAfterRawGeometryChange` → `_announceGeometryChangeToContainer` (since **deleted**) ·
`_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` → `_announceLayoutPropertyChangeToContainer` (since **deleted**) ·
`_recalculateLayoutsCore` → `_recalculateLayoutsBody` · `invalidateLayout` → `_invalidateLayout` · `recalcIterationsCap`
→ `layoutIterationsSanityLimit` (Stage 6, never-fire assert). The `_reLayout*` apply-family rename map (`doLayout` →
`_reLayout`, etc.) is in git history at the 2026-06-22 revision of this file.
