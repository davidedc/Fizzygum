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
| `tooling/` | How-tos for dev tooling (duplication detection, audit tooling), and the inputs those tools read (the owner-review sample for a change to the look). | present |
| `profiling/` | Profiling harness scripts + result sets. | — |
| `explainers/` | Self-contained HTML visual walkthroughs for human readers with light context (diagrams, generic→specific). May describe a program's target state — each states which plan owns it; updated or retired when plans land. See `explainers/README.md`. | present + planned |

Top-level files: `README.md` (this map) and `BACKLOG.md` (every open item across
all arcs, each linking to the plan section that owns the detail).

## Filing rules (keep the split honest)

1. **New arc → new file in `plans/`.** Plans are self-contained: embed the
   history and concrete facts needed to execute cold. A plan that executes an
   external design input lives in its own directory beside that input
   (as `archive/redesign/` was: the plan plus the draft it implemented), and
   the whole directory moves to `archive/` when the arc closes.
2. **Arc closes → `git mv` the plan to `archive/`**, stamp a status header
   (COMPLETE/FALSIFIED/PARKED/STOPPED + date + one line), add its line to
   `archive/INDEX.md`, and remove its items from `BACKLOG.md` — closed entries
   move VERBATIM into the `## BACKLOG ledger (closed items, moved from
   docs/BACKLOG.md)` section near the end of the plan that CLOSED them, beside
   how they closed, naming the section an item was filed under when that is
   another plan's. An item whose full text sits in a `## BACKLOG detail`
   section (rule 5) moves from there, and its one index line is deleted. An
   item closed without
   a plan of its own goes to the plan whose section held it; one whose arc
   never had a plan, into `archive/backlog-closed-items-ledger.md`. A SURVEY
   (a ranked list of candidate arcs, executed by a loop) is closed when its
   loop stops: what it left behind is BACKLOG lines pointing at its sections.
3. **Durable residue goes to `architecture/`.** If an arc changed how a
   subsystem works, update that subsystem's architecture doc in the same arc —
   present tense, no changelog prose. The plan keeps the history; the
   architecture doc keeps only the current truth.
4. **Never file by topic into two buckets.** An analysis that grew a plan is a
   plan; an analysis whose findings are still-current truth belongs in
   `architecture/` (rewritten present-tense) with the original archived.
5. **Deferred/open items always have a `BACKLOG.md` line** pointing at the
   owning plan section — including items whose plan is archived (PARKED).
   The file is an INDEX: an item is ONE line — what is wrong or what is to
   do, then its reach or severity — and its full text lives in a trailing
   `## BACKLOG detail (open items, moved from docs/BACKLOG.md)` section of the
   plan its BACKLOG section names (an arc with no plan file:
   `archive/backlog-open-items-detail.md`), under a heading equal to the
   item's bold title; the line ends in `→` and the file, or the quoted
   heading, only where either differs. An item whose whole text fits one line
   is only that line (its plan's own section holds the rest), and a section
   with no open item left leaves the index, its note moving to its plan's
   ledger. `check-doc-narration` holds an item's length to a ceiling
   (`BACKLOG_ITEM_TOO_LONG`). **The bar (owner,
   2026-11-11):** an item is filed only if a person reaches it through the
   product (a gesture, or a file a save writes) and would notice the
   consequence, or if it is medium or worse whatever its reach (a crash or a
   hang, lost work, code run unasked, a gate or rig that can hang or flake or
   whose bite is unproven). A low finding nobody reaches gets one line in the
   owning plan's `## BACKLOG ledger`, "noted, not queued", never a backlog line.
6. **Archive is immutable.** Don't edit archived docs except to correct a
   status stamp, to receive closed items under rule 2, or to receive an open
   item's detail, a BACKLOG section's note or a "noted, not queued" line
   under rule 5; supersede, don't rewrite.

## Architecture docs

`architecture/` is deliberately coarse — a handful of subsystem docs, verified
against `src/` when written. If a statement there contradicts the code, the code
wins; fix the doc in the same change that proved it stale.
