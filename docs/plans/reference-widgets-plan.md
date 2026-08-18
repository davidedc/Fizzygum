# Reference-widget UI & desktop lifecycle — shortcuts, minimised bars, folders, trash

**STATUS: AUTHORED 2026-07-18, RE-SCOPED 2026-07-18 — design-stage, exploratory. NO code written yet.
Owner-gated execution.**
Anchor on **symbol names** (verified 2026-07-18); line numbers drift. Self-contained.

**Re-scope note:** the *link/GC* half of this arc moved to
[`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md) (the `@target`→`referencedWidget`
rename, the 3-edge model, the unified collector), and the *launcher/Factory* half moved to
[`creation-and-templates-plan.md`](creation-and-templates-plan.md) (App = Factory). What remains here is the
**visible reference-widget UI and the desktop lifecycle *areas*** — built *on top of* those two mechanisms.
Part of one program with [`onion-widget-composition-plan.md`](onion-widget-composition-plan.md) and
[`container-regularization-plan.md`](container-regularization-plan.md). North star: orthogonalisation,
de-byzantination, regularity.

---

## 1. What this arc now owns

A **reference widget** is the *visible* thing that points at another widget to bring it up. Six desktop
concepts are one visual/interaction family (the *Reference morphs* note's taxonomy), all riding the
`referencedWidget` edge (already landed — see §2):

```
Reference (visible icon/bar pointing via `referencedWidget`)
├─ Minimised      — a widget reduced to a placeholder BAR (distinct from collapse-in-place)
├─ Shortcut       — a persistent icon that re-summons its referent
│   ├─ Folder     — a shortcut whose referent is a container of more references
│   ├─ Trash      — the explicit "move to trash" area
│   └─ RecentlyClosed — the "under the carpet" area a closed widget lands in
└─ Launcher       — a Factory/ScriptRunner (its mechanism lives in arc (c); its icon lives here)
```

This arc is the **UI + the lifecycle areas**; the edges/GC are arc (b); the creation mechanics are arc (c).

---

## 2. Current-state truth (first verified 2026-07-18; the shortcut, folder and storage bullets re-verified against src 2026-08-18)

- **Shortcuts (visible) EXIST:** `WidgetHolderWithCaptionWdgt` (`isDesktopIcon`) → `IconicDesktopSystemLinkWdgt`
  → `IconicDesktopSystemShortcutWdgt` (+ Document/Folder/Script subclasses); `bringUpTarget()` re-summons.
  (Referent link = `referencedWidget` — the rename off the overloaded `@target` LANDED, but through the
  connector campaign's P9 (`34adb216`, 2026-08-16), not through arc (b);
  [`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md) §4.1's version of the item is
  therefore already done.)
- **Folders EXIST:** `FolderWindowWdgt` (`extends FrameWdgt`) + `FolderPanelWdgt`
  (`extends IconicDesktopSystemPanelWdgt`); dropping a real widget makes a reference and files the widget
  itself to the SHELF (`_createReferenceAndCloseNoSettle` — the fresh reference keeps it reachable).
- **Storage = Bin + Shelf (SPLIT since this section was written):** `BasementWdgt` was renamed `BinWdgt`
  and then split — `world.shelfWdgt` (`ShelfWdgt`) holds everything REACHABLE, `world.binWdgt` (`BinWdgt`)
  only what is LOST, kept eagerly by `StorageSorter`'s per-cycle drain (no on-open GC, and no "only show
  lost items" toggle any more). `Widget.close` files the figure via
  `restingContainer._addRestingWidgetNoSettle @_enclosingIslandFigure()` — the bin by default, the shelf
  directly on the save-close path. (`docs/archive/basement-to-bin-plan.md`,
  `docs/archive/bin-shelf-eager-sorting-plan.md`.)
- **MISSING (this arc's work):**
  1. **Minimise-to-a-bar** — today the window title-bar collapse button does **collapse-in-place** (shrink
     to the title bar, stay in the tree). There is **no** placeholder bar / dock and no minimise-as-reference.
  2. **A distinct "recently closed" area** — the Bin/Shelf split above divides storage by REACHABILITY, not
     by the auto-vs-explicit distinction the note wanted (RecentlyClosed = auto on close, Trash = explicit);
     the bin remains one undifferentiated "lost items" store. ⚠ Needs an owner pass before §4.3 is executed:
     does the landed split satisfy this ask, or is the distinction still wanted on top of it?
  3. **The unified reference-widget UI taxonomy** — the classes share the verbose `IconicDesktopSystem*`
     lineage but aren't a clean `Reference*` UI family.
  4. **Duplicate vs duplicate-contents** for references isn't an exposed distinction.

---

## 3. Architecture we MUST respect

- **Builds on arc (b):** references point via `referencedWidget` (landed already, §2); reachability is
  `StorageSorter`'s eager classifier today and the 3-edge collector is arc (b)'s generalisation of it — do
  **not** re-implement either here.
- **⚠ World-level reference/bin/shelf state is test-sensitive** — survives `ResetWorld`, prior
  gate-false-positive case-law (`docs/archive/upedge-endgame-plan.md`); keep teardown honest.
- **Reparent/close take the figure** — `_enclosingIslandFigure()` (as `Widget.close` already does).
- **Close/minimise ride the notification grid** — reuse `Closed`/`Collapsed`/`Removed`/`Destroyed` hooks; a
  dispatcher owns the one settle (rules [J]/[L]).
- **Recapture** — new bars/areas add visible chrome; recapture consciously (correctness-first — churn is not
  a blocker, per the program).
- **`FrameWdgt` interplay:** a minimised/collapsed state is a state of a `FrameWdgt`; its `representativeIcon`
  (the content's icon) is what the reference shows.

---

## 4. Proposals

### 4.1 Name a clean `Reference*` UI family (retire the `IconicDesktopSystem*` prefix). *Naming de-smell.*
Rebase the visible classes onto a `ReferenceWdgt` UI family: `ShortcutReferenceWdgt`,
`FolderReferenceWdgt`, `MinimisedReferenceWdgt`, `LauncherReferenceWdgt` (icon only; mechanism in arc (c)).
Drops the verbose `IconicDesktopSystem*` prefix. Pure naming/structure over the existing behaviour.

### 4.2 Minimise-to-a-bar, distinct from collapse-in-place. *A real new feature.*
Keep **collapse-in-place** (title-bar shrink, stays in tree). **Add minimise** = replace the `FrameWdgt`
with a `MinimisedReferenceWdgt` (a placeholder bar / dock entry) whose `referencedWidget` is the frame, until
restored. Owner decides (R2) whether the title-bar up-triangle *becomes* minimise (the *Overview on windows*
note's literal mapping) or minimise is a separate affordance and the button stays collapse.

### 4.3 RecentlyClosed vs Trash — one store, two views first. *Lifecycle areas.*
Expose a `move to trash` command distinct from `close`; back both by the bin store (`world.binWdgt`) but with
two **views/filters** (RecentlyClosed = auto-on-close, reachable, auto-orphaned when stale; Trash = explicit,
destroyed after empty+orphan+unreferenced). Promote to two real areas only if the single-store UX confuses.
⚠ Re-scope this against the landed Bin/Shelf split first (§2 and §2's MISSING item 2): the eager sorter
already routes anything still reachable to the shelf, so "RecentlyClosed = reachable" partly overlaps it.
**Do not** auto-create a shortcut on every close (the note rejected this as messy) — reachability prevents loss.

### 4.4 Duplicate vs duplicate-contents for references. *Copy semantics.*
Expose two copy semantics on reference widgets: default user **"duplicate"** recursively duplicates the
*referent's contents* (duplicating a folder duplicates what's in it); **"pure duplicate"** (share the same
referent) is **dev-only**. Build on the `Duplicator` engine (`src/duplication/Duplicator.coffee`) +
`docs/archive/duplication-and-save-preserve-transforms-plan.md`;
the reference class overrides the copy hook to choose referent-share vs referent-recurse. (Informed by the
arc-(b) edge model — a "duplicate-contents" is a copy that follows containment+reference edges.)

---

## 5. Owner decisions
| # | Decision | Recommendation |
|---|---|---|
| R1 | Scope for v1 | **4.1** (name the UI family) — concrete, low-risk. 4.2/4.3/4.4 second wave. |
| R2 | Minimise semantics | Recommend minimise as a **separate** affordance (don't repurpose the tested collapse button) — unless owner wants the note's literal up-triangle mapping. |
| R3 | RecentlyClosed vs Trash | **One store, two views** first; split later only if warranted. |

## 6. Risks & non-goals
- **Test-state leaks** (world-level reference/bin/shelf state surviving `ResetWorld`) — top risk.
- **Recapture** for new bars/areas — expected, accepted.
- **Non-goals:** the edge model + GC (arc (b)); the launcher/Factory mechanism (arc (c)).

## 7. Cross-links
- Depends on: [`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md) (edges + GC),
  [`creation-and-templates-plan.md`](creation-and-templates-plan.md) (launcher/Factory).
- Program siblings: [`onion-widget-composition-plan.md`](onion-widget-composition-plan.md),
  [`container-regularization-plan.md`](container-regularization-plan.md).
- Landed history: `docs/archive/duplication-and-save-preserve-transforms-plan.md`,
  `docs/archive/drag-embed-implementation-plan.md`, `docs/archive/upedge-endgame-plan.md`.
```
