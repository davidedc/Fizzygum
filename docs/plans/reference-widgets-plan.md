# Reference-widget UI & desktop lifecycle — shortcuts, minimised bars, folders, trash

**STATUS: AUTHORED 2026-07-18, RE-SCOPED 2026-07-18. §4.3 (trash = sever + close) EXECUTED
2026-08-19 along with the R3 rename — see the as-executed block in §4.3. §4.1 (family rename)
EXECUTED 2026-08-19 — see its as-executed block. §4.4 (the arrow contract) EXECUTED 2026-08-19
— see its as-executed block. §4.2 (minimise-to-a-bar) is the ONE remaining item, design-stage,
owner-gated (R2 open).**
Anchor on **symbol names** (verified 2026-07-18); line numbers drift. Self-contained.

**Re-scope note:** the *link/GC* half of this arc moved to
[`graph-edges-and-lifecycle-plan.md`](../archive/graph-edges-and-lifecycle-plan.md) (the `@target`→`referencedWidget`
rename, the 3-edge model, the unified collector), and the *launcher/Factory* half moved to
[`creation-and-templates-plan.md`](creation-and-templates-plan.md) (App = Factory). What remains here is the
**visible reference-widget UI and the desktop lifecycle *areas*** — built *on top of* those two mechanisms.
Part of one program with [`onion-widget-composition-plan.md`](../archive/onion-widget-composition-plan.md) and
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

- **Shortcuts (visible) EXIST:** `WidgetHolderWithCaptionWdgt` (`isDesktopIcon`) → `DesktopLinkWdgt`
  → `ShortcutWdgt` (+ Document/Folder/Script subclasses); `bringUpReferencedWidget()`
  re-summons (the R3 residue rename off `bringUpTarget`, landed with §4.3's execution).
  (Referent link = `referencedWidget` — the rename off the overloaded `@target` LANDED, but through the
  connector campaign's P9 (`34adb216`, 2026-08-16), not through arc (b);
  [`graph-edges-and-lifecycle-plan.md`](../archive/graph-edges-and-lifecycle-plan.md) §4.1's version of the item is
  therefore already done.)
- **Folders EXIST:** `FolderWindowWdgt` (`extends FrameWdgt`) + `FolderPanelWdgt`
  (`extends IconGridPanelWdgt`); dropping a real widget makes a reference and files the widget
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
     by the auto-vs-explicit distinction the note wanted (RecentlyClosed = auto on close, Trash = explicit).
     ✅ **The owner pass happened (2026-08-18) and the answer is in §4.3 below**: the two axes are
     ORTHOGONAL, the conflict quadrant (explicitly trashed + still referenced) is unexpressible under
     the landed invariant, and the ratified design is sever-and-close with the bin as the one store.
  3. ✅ **The naming taxonomy — RESOLVED by §4.1's execution (2026-08-19)**: the
     `IconicDesktopSystem*` prefix is retired for short role names (`ShortcutWdgt`,
     `AppLauncherWdgt`, …). The `Reference*`-family sketch was rejected at ratification —
     see §4.1's as-executed block for the table and the argument.
  4. ✅ **Duplicate vs duplicate-contents — RESOLVED by §4.4's execution (2026-08-19)**: the
     distinction is not a second verb but the icon's own per-instance arrow-contract
     declaration — one "duplicate" action, whose depth the glyph already states.

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

### 4.1 Retire the `IconicDesktopSystem*` prefix. *Naming de-smell — EXECUTED 2026-08-19.*
The sketch here originally proposed a `*ReferenceWdgt` family (`ShortcutReferenceWdgt`,
`FolderReferenceWdgt`, `LauncherReferenceWdgt`, …). **Rejected at ratification**: `LauncherReferenceWdgt`
names the launcher a reference, which the landed doctrine explicitly denies (a launcher spawns
independent instances — the ShortcutWdgt header's contrast, protected by the P9 `@target` →
`referencedWidget` de-overload), and `ShortcutReference` is redundant ("shortcut" already means
widget-reference here: `isDesktopShortcut`, `isShortcutTo`, the "create shortcut" row).

**✅ EXECUTED 2026-08-19 — as landed (owner-ratified short role names):**
| was | is |
|---|---|
| `IconicDesktopSystemLinkWdgt` | `DesktopLinkWdgt` |
| `IconicDesktopSystemShortcutWdgt` | `ShortcutWdgt` |
| `IconicDesktopSystemDocumentShortcutWdgt` | `DocumentShortcutWdgt` |
| `IconicDesktopSystemFolderShortcutWdgt` | `FolderShortcutWdgt` |
| `IconicDesktopSystemScriptShortcutWdgt` | `ScriptShortcutWdgt` |
| `IconicDesktopSystemWindowedAppLauncherWdgt` | `AppLauncherWdgt` |
| `IconicDesktopSystemPanelWdgt` | `IconGridPanelWdgt` |
| `IconicDesktopSystemWindowedApp` (app-kit) | `WindowedApp` |

`WidgetHolderWithCaptionWdgt` and `BinOpenerWdgt` keep their names (descriptive, unprefixed).
Swept: src (files `git mv`ed; filename = class name), buildSystem gate configs and part/profile
doc-strings, live docs, both repos' CLAUDE.mds, tests-repo macro sources and scripts (the P9
lesson). NOT swept: `docs/archive/` and `docs/measurements/` (dated snapshots stay verbatim);
retired-mixin names in `mixins.md`'s where-each-went inventory (they name dead classes —
renaming them would falsify history). §4.2's future minimised-bar class is named when it lands,
under this same role-name scheme.

### 4.2 Minimise-to-a-bar, distinct from collapse-in-place. *A real new feature.*
Keep **collapse-in-place** (title-bar shrink, stays in tree). **Add minimise** = replace the `FrameWdgt`
with a `MinimisedReferenceWdgt` (a placeholder bar / dock entry) whose `referencedWidget` is the frame, until
restored. Owner decides (R2) whether the title-bar up-triangle *becomes* minimise (the *Overview on windows*
note's literal mapping) or minimise is a separate affordance and the button stays collapse.

### 4.3 Trash = sever + close; the bin is the one store. *Lifecycle areas — RATIFIED 2026-08-18.*
The reconciliation against the landed Bin/Shelf split resolved this (owner-ratified). The landed axis
(reachability, automatic) and the note's axis (intent: auto-close vs explicit trash) are ORTHOGONAL, and
the conflict quadrant — *explicitly trashed but still referenced* — is structurally unexpressible: as long
as a reference lives, the eager sorter re-files the resident to the shelf every drain, and forcing it
binward would break the gated `STORAGE_INVARIANT` (reachable-in-bin). So:
- **`move to trash` = sever inbound reference edges + close.** The widget becomes genuinely lost and lands
  in the bin *by graph truth* — no intent tag, no invariant carve-out, no second store. (Severing needs
  "who references me": the tracker scan `world.widgetsReferencingOtherWidgets` still answers that directly;
  note the close paths' park-vs-destroy question is since graph-edges §4.3 the walk-based
  `world.anyReferenceOrWireIntoWdgt` — trash's sever should stay consistent with it.)
- **"RecentlyClosed" is not an area and not a view-filter — it is the bin's arrival ordering.** With sever
  semantics no residual trashed-vs-closed-and-lost distinction is worth machinery; if auto-purge is ever
  wanted, an intent tag can be added then, with a use case in hand.
- **Retention: manual empty only** — destruction stays a user act (aligned with graph-edges G6).
**Do not** auto-create a shortcut on every close (the note rejected this as messy) — reachability prevents loss.
Rejected: intent tags + two views over one store ("I trashed it but it's not in the trash" at the conflict
quadrant); two real intent areas (re-litigates the landed, gated split).

**✅ EXECUTED 2026-08-19 — as landed:**
- **`Widget.moveToTrash`** (public, self-settling) → `_moveToTrashNoSettle`: the same one-step
  contents-to-window redirect `_closeNoSettle` makes, then sever + close in one settle batch.
- **The sever rides the query's own walk.** `WorldWdgt.anyReferenceOrWireIntoWdgt` and
  `WorldWdgt._severLivenessEdgesIntoWdgtNoSettle` both consume ONE enumeration
  (`_livenessEdgesIntoWdgt`, returning `{holder, edge}` pairs), so they structurally cannot
  disagree about which edges exist — whatever the query counts is exactly what the sever cuts,
  which is what makes the bin filing stick by graph truth. A flow edge is revoked through the
  holder's own wire records via `unwireFrom`; only edges INTO the trashed figure go — the
  holder's other wires survive.
- **A severed shortcut DIES, it is not blanked** — `ShortcutWdgt.
  _severReferenceEdgeToNoSettle` (a blanked shortcut would be a lying icon whose click can only
  apologise). Dispatched WITHOUT `?.` at both sever chokepoints, so a future reference-emitting
  class must choose its own sever behaviour rather than silently inherit destruction.
- **Referent DEATH severs its dangling shortcuts too** — `Widget._destroyNoSettle` runs the
  reference half of "no edge outlives its target", the twin of
  `DataflowEngine.severWiresIntoDyingNode`. Enumerated over the tracker (total — orphans and
  storage residents included, where the trash walk is deliberately attached-only). Terminates
  because a referent is ctor-fixed: every reference edge points at an older widget, so the
  reference graph is a DAG; a destroyed-holder guard covers diamonds.
- **The menu row is CONDITIONAL** — `"move to trash"` appears (beside close/delete, via
  `Widget._wouldTrashSeverAnything`, which redirects like the close core) only when an inbound
  liveness edge makes it differ from plain close: with no such edge, close/delete already files
  binward and the drain keeps it there, so an always-on row would be a synonym paying menu rent
  (the P2 bind-row lesson).
- **Retention was already landed:** `BinWdgt`'s "Empty bin" button (confirm-menu → destroy) IS
  the manual-empty policy; nothing was added.
- **Gate:** `fg graph` (gauntlet leg #17) section 5 — 10 new checks: sever both-kinds precision
  (the bystander wire survives), bin filing sticks across the drain, the menu condition both
  ways, referent-death sever, tracker corpse-freedom; 31 checks total, STORAGE_INVARIANT and
  console clean throughout.

### 4.4 The arrow contract: glyph = copy semantics. *RATIFIED 2026-08-19, pressure-tested same day — EXECUTED same day (as-executed block at the end of this section).*

**The owner-ratified model (supersedes the original "flip the default + dev-only pure duplicate"
sketch, which is RETIRED — the default was only ever wrong on icons that should not have presented
as shortcuts):** the little arrow badge is a SEMANTIC CONTRACT, exactly as on Windows/mac.
- **Arrow ⇒ the icon is a reference** (a shortcut): duplicating it duplicates the REFERENCE only —
  both copies point at the same referent. This is today's behaviour and today's doctrine
  (`ShortcutWdgt`'s header); it does not change.
- **No arrow ⇒ the icon IS the thing** (it represents the actual contents): duplicating it
  duplicates the CONTENTS — for the reference-implemented desktop/folder icons that means
  following the `referencedWidget` edge into the copy.
- **The bin gets no arrow and refuses duplication** (one singleton; `BinOpenerWdgt` is already
  outside the reference tracker).
- **Launchers get no arrow and need no declaration** — they hold no `referencedWidget` at all;
  duplicating one yields another independent factory (already correct:
  `WindowedApp.keptByReferenceOnDeepCopy: true` shares the app singleton on copy, and the lazy
  mode copies a class-name string).

**Current-state census (2026-08-19): 6 of the fresh world's 16 icons wear the arrow, and all six
are WRONG under this model** — the bin, the folder, and the four wrapped Examples doors
(`AppCatalog`'s `GenericShortcutIconWdgt`-wrapped entries), while the 9 desktop Makers are
already bare. The badge today tracks which section of AppCatalog built the icon — provenance,
not meaning. A fresh world under this model shows ZERO arrows; the badge appears only when a
user creates a shortcut. (One extra glyph liar to sweep: DemoMenus' "Welcome" icon is a
`DocumentShortcutWdgt` — a real reference — built with a bare icon.)

**The declaration is PER-INSTANCE, set at creation — not a class split.** Both kinds of
in-folder icon are the same class today, built through two different paths: dropping a real
widget into a folder FILES it (`_createReferenceAndCloseNoSettle` — widget to the shelf, icon
left behind ⇒ presents as CONTENT, no arrow, deep copy), while "create shortcut"
(`createReference`) makes a deliberate alias (⇒ arrow, shallow copy). One boolean field (e.g.
`representsContents`), assigned in the constructor from the creation path, drives BOTH the icon
assembly (arrow'd `GenericShortcutIconWdgt` composite vs bare inner icon — the 9 Makers prove
the bare path) and the copy closure below. An own field, so it rides serialization and
duplication untouched. The primary folder icon and the bin opener declare content at their
creation sites. ⛔ The declaration must NEVER feed liveness: to the storage classifier, the
close-path query and the trash sever, a content-presenting icon is an ordinary reference edge
(verified composition: trashing an open folder window severs its content-presenting desktop
icon — the representation dies with the thing, correctly).

**Mechanics (pressure-tested against the engines 2026-08-19 — no engine changes needed):**
- `Widget.fullCopy` is `new Duplicator(@allChildrenBottomToTop()).duplicate @`, and the
  Duplicator's own contract is: a Widget OUTSIDE `widgetsInStructure` is kept as a live shared
  pointer, one inside CLONES, and `alignCopiedWidgetToReferenceTracker` enrolls fresh references
  automatically. Shallow-vs-deep is therefore purely WHICH WIDGETS JOIN THE SET before the walk:
  deep = *subtree ∪ (each in-structure icon that presents-as-content contributes its referent's
  figure, recursively)*. In-folder arrow'd shortcuts need no special case — their referents stay
  outside the set, so the copied folder shares them, per their own glyph.
- ⭐ The closure computation needs a VISITED-SET fixpoint of its own (folder-in-folder filings
  make reference-through-containment cycles constructible; the Duplicator's identity map handles
  cycles inside the walk, not in the set computation before it).
- ⭐ **Placement rule: the referent's copy is explicitly FILED to the shelf** after the
  duplicate — the drain will not home it (a reachable orphan is homeless, not misfiled), and the
  folder copy must not appear open on the desktop even when the original's window is open. The
  icon copy lands wherever the gesture puts it, as today.
- **The same closure should feed `Serializer.serializeWidget`'s structure**: today the
  Serializer HARD-FAILS on any external non-well-known widget, and `saveToFile` shows that as a
  friendly error — so "save to file…" on any shortcut, or any figure containing one, simply
  errors today. With the closure, content-presenting figures become genuinely saveable
  (referents embedded). Saving an ARROW'D shortcut stays an error for now — Fizzygum has no
  cross-file identity that would make a dangling-`.lnk` restore meaningful — filed as its own
  follow-up decision, not solved in this arc.

**Known-and-accepted (pre-existing, noted during the pressure test, NOT this arc's scope):**
deleting a filed icon parks the ICON in the bin (its document rests on the shelf, reachable
through it); emptying the bin destroys the icon, the document becomes lost, and it surfaces in
the just-emptied bin. Graph-honest and data-protective — the document was never explicitly
condemned — but worth knowing.

Verification: extend `fg graph` with a §6 (deep copy of a folder ⇒ fresh referent copies on the
shelf + fresh tracker enrollments + the original untouched; shallow copy of an arrow'd shortcut
⇒ shared referent; bin opener refuses duplication), plus the intended glyph recapture (the 6
de-arrowed icons churn every screenshot showing them).

**✅ EXECUTED 2026-08-19 — as landed:**
- **The declaration**: `ShortcutWdgt.representsContents` (class default `false`, own-assigned in
  the constructor from `opts.representsContents`). The constructor is THE ONE icon-assembly
  site: `innerIcon = opts.icon ? @_defaultInnerIcon()`, then content ⇒ the bare inner art,
  reference ⇒ `new GenericShortcutIconWdgt innerIcon` — so the glyph structurally cannot lie,
  even for a caller-supplied inner icon. `_defaultInnerIcon` is the subclass seam
  (base/Document: the `GenericObjectIconWdgt` object composite around
  `@referencedWidget.representativeIcon()`; Folder: `FolderIconWdgt`; Script: `ScriptIconWdgt`)
  — the three subclass constructors and their triplicated wrap logic are DELETED. The family
  ctor is `(referencedWidget, title, opts = {})` (`opts.icon`, `opts.representsContents` — no
  positional holes).
- **The threading**: the `createReference` family gained a trailing `opts` —
  `Widget.createReference/_createReferenceNoSettle`, `FolderWindowWdgt.createReference`,
  `FrameWdgt.createReference` (rides through to super). The FILING rituals pass
  `representsContents: true`: `_createReferenceAndCloseNoSettle` (covering folder drops AND the
  SaveShortcutPromptWdgt "Ok" path, which routes through `createReferenceAndClose`) and
  `PanelWdgt.makeFolder` (close + reference = filing). The menu's "create shortcut"
  (`createReferenceFromMenu`) defaults to the arrow'd alias. `ScriptWdgt`'s special shortcut
  stays an alias (menu-only path).
- **The six de-arrows**: the four `AppCatalog` Examples entries draw bare art; `BinOpenerWdgt`
  passes bare `BinIconWdgt`; `FolderWindowWdgt.representativeIcon` is bare `FolderIconWdgt`
  (representativeIcon = the content's ART, never a badge decision); the makeFolder folder icon
  is content-presenting (covers the desktop's Examples folder). DemoMenus' "Welcome" is
  DECLARED content (`representsContents: true`) — its bare `WelcomeIconWdgt` pixels were
  already right, only the declaration was missing.
- **The copy closure**: `Widget.allWidgetsInStructureForCopy` — subtree ∪ (each in-structure
  content icon contributes `referencedWidget._enclosingIslandFigure()`'s subtree), visited-set
  fixpoint, returning `{structure, referentFigures}`. `fullCopy` feeds `structure` to the
  Duplicator and then files each contributed figure's clone to the SHELF
  (`_fileCopiedReferentFiguresToShelfNoSettle`, settle-wrapped, via the new
  `Duplicator.cloneOf`) — no Duplicator engine change; tracker enrollment is the existing
  `alignCopiedWidgetToReferenceTracker` hook. The clone's copied `parent` pointer needs no
  surgery: `_addRestingWidgetNoSettle`'s add chain re-homes it, exactly as `world.add` does
  for every ordinary duplicate's root today.
- **The save closure**: `Serializer.buildEnvelope` consumes THE SAME closure — contributed
  referent figures ride the envelope as embedded DETACHED second roots (`_buildObjectTable`'s
  `root` param generalized to a `detachRoots` set; each serializes `parent: null` like the
  envelope root). The restore half is `ShortcutWdgt._afterDeserialization`: an
  attached-in-truth check (`parent` unset, or parent's children don't contain the figure) homes
  the restored figure to the shelf + marks the storage sort — a no-op in world-snapshot
  restores, idempotent across two icons sharing a referent. Tracker re-entry was already
  handled (the `referenceTracker` membership rejoin). ONE ill-posed shape is refused up front
  with a clear SerializationError: an icon saved from INSIDE the container it presents
  (`buildEnvelope`'s ancestor guard — duplication handles that same shape fine, a copy is one
  live structure, not two envelope roots). An ARROW'D shortcut's save still errors (external
  referent — the friendly `saveToFile` dialog; cross-file identity = BACKLOG).
- **Bin refuses duplication**: `BinOpenerWdgt._refusesDuplication` (an opt-out capability,
  `?()`-dispatched, nothing on Widget) suppresses the "duplicate" row in
  `Widget.buildBaseWidgetClassContextMenu`.
- **The shortcut-class SEAM (same-day follow-up, found in the execution's caller census)**:
  `Widget._buildShortcutWidget(referenceName, opts)` — THE ONE place deciding which shortcut
  class represents a widget, consulted by `_createReferenceNoSettle` — so the answer holds on
  EVERY creation path. Overridden by `FrameWdgt` (consults the content's
  `specialFrameReferenceShortcut`, now opts-threaded) and `FolderWindowWdgt` (a folder
  shortcut; its public `createReference` routes through the seam too, so the class fact is
  stated once). This closes a pre-existing gap: the filing paths
  (`_createReferenceAndCloseNoSettle` — folder drops AND the save-close prompt) bypassed the
  public `FrameWdgt.createReference` override, so a filed script window became a plain
  document shortcut, losing its run-on-double-click script-ness; a folder window filed into
  another folder likewise fell to a document shortcut, losing the drop-into-me affordance.
  The menu path's 95×92 sizing and the core's 75×75 are deliberately untouched (the
  filed-icon size matches every other filed icon; `macroSavedDocumentShortcutIcon`'s prose
  pins the 75×75 raw-resize).
- **Liveness untouched, verified**: the declaration is read ONLY by the icon assembly and the
  closure — `graphEdgesOut`, the classifier, the close query and the trash sever never see it
  (gate §6 proves deep-copied referent figures STAY on the shelf across a real drain, i.e. the
  copies are kept by their reference edges, not by the declaration). Doc:
  `widget-authoring-guidelines.md` §"Declaring a graph edge" now states the
  presentation-must-not-feed-liveness rule; `serialization-duplication-reference.md` §2/§4
  document the closure + detach-roots.
- **Gates**: build green (25 static gates); `fg graph` grew 36 → **55 checks** (§6: glyph +
  declaration both ways, deep copy with the transitive in-folder hop, shelf filing, tracker
  growth exactly +2, original untouched, drain stability, shared-referent shallow copy, the
  bin's menu suppression vs a plain widget's row); the serialization rig grew 48 → **52** and
  64 → **68** checks (content-icon save embeds the referent, restore homes it to the shelf +
  re-enrolls the tracker, arrow'd-alias save still errors — both backends). Suite churn was
  exactly TWO tests, pixel-verified via diffpage before recapture: the intended
  `SystemTest_macroDesktopShortcutIcons` de-arrow (its five fixture icons — prose re-pointed;
  the arrow composite's D1 raw-resize guard rests with `SystemTest_macroSavedDocumentShortcutIcon`,
  whose created-shortcut icon rightly keeps the badge and did not churn) and the benign
  known-class inspector list shift (`allWidgetsInStructureForCopy` sorts directly above the
  `alpha` row `macroDuplicatedInspectorDrivesCopiedTargetOnly` selects).

---

## 5. Owner decisions
| # | Decision | Recommendation |
|---|---|---|
| R1 | Scope for v1 | ✅ **RESOLVED 2026-08-19: §4.3 landed first (its semantics were ratified first), §4.1 same day with the owner-ratified short role names** (the `Reference*` sketch rejected — see §4.1). Remaining wave: §4.2 (needs R2), §4.4. |
| R2 | Minimise semantics | Recommend minimise as a **separate** affordance (don't repurpose the tested collapse button) — unless owner wants the note's literal up-triangle mapping. |
| R4 | §4.4 copy semantics | ✅ **RATIFIED 2026-08-19: the arrow contract** (arrow = reference, copy shares; no arrow = the thing itself, copy deepens; bin arrow-less + duplication refused; launchers arrow-less, no declaration needed). Per-instance declaration set at creation (filed vs created-shortcut). **EXECUTED same day — see §4.4's as-executed block.** |
| R5 | Drop into the open bin | ✅ **RATIFIED 2026-08-19: (b) — an explicit drop into the bin window carries trash intent** and runs the same sever as the `move to trash` row, so the drop STICKS instead of the drain re-filing the widget shelf-ward. (Alternatives weighed: status quo — drop is silently overridden; refuse-with-inform — a nag that kicks the decision down the road. Undo/redo, when it lands, further de-risks the severed-shortcut cost.) |
| R3 | RecentlyClosed vs Trash | ✅ **RATIFIED 2026-08-18: sever + close, one store, no views** — and **EXECUTED 2026-08-19** together with the residue rename `bringUpTarget` → `bringUpReferencedWidget` (cross-repo sweep per the P9 lesson, incl. `Fizzygum-tests/scripts/` and the call-separation allowlist). See §4.3's as-executed block. |

## 6. Risks & non-goals
- **Test-state leaks** (world-level reference/bin/shelf state surviving `ResetWorld`) — top risk.
- **Recapture** for new bars/areas — expected, accepted.
- **Non-goals:** the edge model + GC (arc (b)); the launcher/Factory mechanism (arc (c)).

## 7. Cross-links
- Depends on: [`graph-edges-and-lifecycle-plan.md`](../archive/graph-edges-and-lifecycle-plan.md) (edges + GC),
  [`creation-and-templates-plan.md`](creation-and-templates-plan.md) (launcher/Factory).
- Program siblings: [`onion-widget-composition-plan.md`](../archive/onion-widget-composition-plan.md),
  [`container-regularization-plan.md`](container-regularization-plan.md).
- Landed history: `docs/archive/duplication-and-save-preserve-transforms-plan.md`,
  `docs/archive/drag-embed-implementation-plan.md`, `docs/archive/upedge-endgame-plan.md`.
```
