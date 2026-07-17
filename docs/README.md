# docs/ — map and filing rules

This directory was restructured on 2026-07-17 (previously: ~90 flat files mixing
plans, analyses, references, and snapshots). Every file now lives in exactly one
bucket, chosen by what the file IS, not by topic:

| Bucket | What belongs here | Tense |
|---|---|---|
| `architecture/` | How a subsystem works NOW — evergreen references and standing conventions/policies. No history, no plans. | present |
| `specs/` | Behaviour contracts for features (what the product must do). | present |
| `plans/` | ACTIVE arcs only: plans with genuinely open, executable work. | future |
| `archive/` | Completed, falsified, or parked plans and analyses — verbatim, status-stamped. The case-law record: rejected alternatives and gotchas live here. See `archive/INDEX.md`. | past |
| `archive/prompts/` | Saved session starting-prompts for arcs (historical). | past |
| `measurements/` | Point-in-time numbers: profiling results, inventories, catalogs, audits. Dated snapshots; never updated, superseded by new snapshots. | past |
| `tooling/` | How-tos for dev tooling (duplication detection, audit tooling). | present |
| `profiling/` | Profiling harness scripts + result sets. | — |

Top-level files: `README.md` (this map) and `BACKLOG.md` (every open item across
all arcs, each linking to the plan section that owns the detail).

## Filing rules (keep the split honest)

1. **New arc → new file in `plans/`.** Plans are self-contained: embed the
   history and concrete facts needed to execute cold.
2. **Arc closes → `git mv` the plan to `archive/`**, stamp a status header
   (COMPLETE/FALSIFIED/PARKED + date + one line), add its line to
   `archive/INDEX.md`, and remove its items from `BACKLOG.md`.
3. **Durable residue goes to `architecture/`.** If an arc changed how a
   subsystem works, update that subsystem's architecture doc in the same arc —
   present tense, no changelog prose. The plan keeps the history; the
   architecture doc keeps only the current truth.
4. **Never file by topic into two buckets.** An analysis that grew a plan is a
   plan; an analysis whose findings are still-current truth belongs in
   `architecture/` (rewritten present-tense) with the original archived.
5. **Deferred/open items always have a `BACKLOG.md` line** pointing at the
   owning plan section — including items whose plan is archived (PARKED).
6. **Archive is immutable.** Don't edit archived docs except to correct a
   status stamp; supersede, don't rewrite.

## Architecture docs

`architecture/` is deliberately coarse — a handful of subsystem docs, verified
against `src/` when written. If a statement there contradicts the code, the code
wins; fix the doc in the same change that proved it stale.
