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
`referencedWidget` edge from arc (b):

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

## 2. Current-state truth (verified 2026-07-18)

- **Shortcuts (visible) EXIST:** `WidgetHolderWithCaptionWdgt` (`isDesktopIcon`) → `IconicDesktopSystemLinkWdgt`
  → `IconicDesktopSystemShortcutWdgt` (+ Document/Folder/Script subclasses); `bringUpTarget()` re-summons.
  (Referent link = the overloaded `@target` today → becomes `referencedWidget` in arc (b).)
- **Folders EXIST:** `FolderWindowWdgt` (`extends WindowWdgt`) + `FolderPanelWdgt` (`extends PanelWdgt`);
  dropping a widget makes a reference and moves the real widget to the basement.
- **Basement = trash/"under the carpet" (unified today):** `BasementWdgt` (`extends BoxWdgt`) holds
  closed/"lost" widgets + an incremental GC + a "only show lost items" toggle; `Widget.close` scatters a
  widget here via `world.basementWdgt._addLostWidgetNoSettle @_enclosingIslandFigure()`.
- **MISSING (this arc's work):**
  1. **Minimise-to-a-bar** — today the window title-bar collapse button does **collapse-in-place** (shrink
     to the title bar, stay in the tree). There is **no** placeholder bar / dock and no minimise-as-reference.
  2. **A distinct "recently closed" area** — closing scatters into the single `BasementWdgt`; the note wanted
     RecentlyClosed (auto, on close) and Trash (explicit) as separate areas (or at least distinct views).
  3. **The unified reference-widget UI taxonomy** — the classes share the verbose `IconicDesktopSystem*`
     lineage but aren't a clean `Reference*` UI family.
  4. **Duplicate vs duplicate-contents** for references isn't an exposed distinction.

---

## 3. Architecture we MUST respect

- **Builds on arc (b):** references point via `referencedWidget`; reachability/GC is the 3-edge collector —
  do **not** re-implement GC here.
- **⚠ World-level reference/basement state is test-sensitive** — survives `ResetWorld`, prior
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
Expose a `move to trash` command distinct from `close`; back both by the `BasementWdgt` store but with two
**views/filters** (RecentlyClosed = auto-on-close, reachable, auto-orphaned when stale; Trash = explicit,
destroyed after empty+orphan+unreferenced). Promote to two real areas only if the single-store UX confuses.
**Do not** auto-create a shortcut on every close (the note rejected this as messy) — reachability prevents loss.

### 4.4 Duplicate vs duplicate-contents for references. *Copy semantics.*
Expose two copy semantics on reference widgets: default user **"duplicate"** recursively duplicates the
*referent's contents* (duplicating a folder duplicates what's in it); **"pure duplicate"** (share the same
referent) is **dev-only**. Build on `DeepCopierMixin` + `docs/archive/duplication-and-save-preserve-transforms-plan.md`;
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
- **Test-state leaks** (world-level reference/basement state surviving `ResetWorld`) — top risk.
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
