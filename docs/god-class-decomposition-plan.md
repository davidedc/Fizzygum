# God-Class decomposition — a self-contained Phase 6 plan

Detailed execution plan for **Phase 6** of the OO code-smell backlog
(`oo-smells-refactoring-backlog.md`): split the three God classes — `Widget`
(4725 L), `WorldWdgt` (2224 L), `MenusHelper` (1170 L) — into delegated
collaborators/factory classes, following the **mixins → plain-OO delegation**
direction the codebase already set (`MacroToolkit` was split out of `WorldWdgt`).

It is meant to be executable cold: it embeds the history, the guardrails (esp. a
recapture reality that *corrects the backlog*), the study findings with `file:line`,
the risk-ascending sub-arc, and which deferred Phase-5 checks each step dissolves.

**Status: PLAN ONLY — no code yet.** Phase 6 needs explicit owner go-ahead per step.

---

## Why this, why now (history)

- **Phases 0–4 DONE** (dead code, sibling-family base extraction, icon-shell
  thinning, paint dedup, `MenuItemSpec`). **Phase 5 (decouple `Widget` from
  subclass identity) DONE for the clean cases:** 5a (smart-placer), 5b
  (`isWindow?()`/`isLayoutDecoration?()`), the `childGeometryChanged` exemplar,
  Cluster A (`reLayOutAfterContainedPanelChange` notify-hook + delete dead
  `amIPanelOfScrollPanelWdgt`), Cluster C (`refitContentsAndScrollBars` +
  soak-dispatch). State at this plan: **Fizzygum master `4c684991`**,
  Fizzygum-tests `a6b125db5`.
- **Phase 5 deliberately DEFERRED its remaining clusters to Phase 6** (owner
  decision 2026-06-17). Those are the *scroll-structure topology* checks
  (Cluster B `amIDirectlyInside*`, E `grabsToParentWhenDragged`, F hierarchy-menu)
  and the *leaf-role filters* (Cluster G: adder/droplet, entry-fields, shortcut,
  tooltip/handle/caret). The reason is the thesis of Phase 6: **`Widget`
  interrogates subclass identity *because* it holds responsibilities (layout,
  scroll coordination, menu building, demo factories) that belong elsewhere.**
  Move the responsibility out and the identity-check either dissolves or becomes a
  legitimate local filter on the new owner. See the dissolution map below.
- **Direction set by precedent:** `MacroToolkit` (`src/macros/MacroToolkit.coffee`,
  reached as `world.macroToolkit`) is the model — a cohesive responsibility lifted
  off a God class into a plain collaborator object constructed in the God class's
  ctor and delegated to. Mixins (`@augmentWith`) remain available where a behaviour
  must be *injected into* the widget rather than *delegated out*.

---

## Guardrails & established facts (read before any step)

1. **RECAPTURE REALITY — this corrects the backlog.** The backlog's "Recapture:
   ZERO for pure moves" is **WRONG for `Widget`/`WorldWdgt` method moves.** Cluster
   A proved (2026-06-17) that *removing* an inspector-visible `Widget` method
   recaptures the one test whose macro opens an Object Inspector listing Widget's
   methods alphabetically (`SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly`).
   **Moving any method OFF `Widget` shrinks that list → the same recapture.** So:
   - **MenusHelper moves: ~ZERO recapture** — it's a separate global singleton
     (`window.menusHelper`), not in any inspected widget's method pane. Safest tier.
   - **`Widget` method moves: expect to recapture the inspector test(s)** every
     sub-step (one test today; confirm the set each time). Handle deliberately, as
     in Cluster A: verify the pixel delta is *only* the moved method-names
     disappearing, then regenerate
     (`node scripts/capture-macro-test-references.js <name> --clean --dprs=1,2`).
   - **`WorldWdgt` method moves: recapture IFF a test inspects the World / a
     WorldWdgt instance** — check per sub-step (grep tests for inspector macros over
     `world`); likely small but not assumed zero.
   This makes "zero recapture" no longer the pass/fail oracle for Phase 6; the
   oracle is "the only delta is the moved method-name rows." Budget for regen.
2. **DETERMINISM contract (`Fizzygum-tests/DETERMINISM.md`).** The render loop,
   input recognition, layout (`doLayout`) and geometry must stay **pure functions
   of the event stream + final geometry** — never of wall-clock/frame counts/
   intermediate passes (diverge at dpr 2 under parallel load). The DET cores are
   the **late capstone**, not early sub-steps. Read DETERMINISM.md before touching
   them; dpr 2 + WebKit mandatory there.
3. **MacroToolkit extraction recipe** (the template for a collaborator): declare a
   field, construct it in the God class's ctor (guarded `if Collaborator?` if it's
   test/experimental), move the cohesive methods + their private state onto it,
   leave thin delegators (or update call sites) on the God class. Keep
   homepage-exclusion guards (`»>>` … `<<«`, `if Automator?`) intact across the move.
4. **Verify recipe (per sub-step, from `Fizzygum/`):** `./build_and_test.sh` (dpr1)
   → `cd ../Fizzygum-tests && node scripts/run-all-headless.js --dpr=2` →
   `… --browser=webkit` → the `--homepage` boot leg (3-step cd sequence). A dpr-2
   "SUITE FAILED" with no `failed tests (N)` line is a shard *disconnect* (re-run).
   Recapture is EXPECTED for Widget moves (guardrail 1) — not a red flag, but
   confirm the delta before regenerating.
5. **Cadence:** one sub-step (one collaborator / one app) per commit, individually
   verified; ask before commit/push (review-driven). NOT one mega-commit.
6. **The fragmenter** rejects a method placed before a class-level `@augmentWith`
   and a one-line `constructor: -> super …`; keep new methods in the methods region
   and constructors multi-line. Commit messages: plain identifiers, no backticks.
7. **A collaborator that becomes a menu string-action TARGET must survive deep-copy
   as a kept singleton** (the deep-copy guardrail; found in 6a.3). Menu items store
   `(target, "methodNameString")`, and duplicating a menu (`Widget.fullCopy` →
   `DeepCopierMixin`) deep-copies each item's `target`. The copier keeps EXTERNAL
   *Widget* references by reference (returns `@`) but tries to `.deepCopy()` any
   other object — so a plain collaborator with no `deepCopy` THROWS
   (`this[property].deepCopy is not a function`). Hit in 6a.3: duplicating the world
   menu, whose "wallpapers" item now targets `world.wallpaper`, crashed
   `SystemTest_macroDuplicatedMenuAutoPinsOnDesktop`. **FIX (declarative flag):** the
   collaborator declares `keptByReferenceOnDeepCopy: true`, and `DeepCopierMixin`
   (`recursivelyCloneContent`) honors it — keeping the reference instead of cloning,
   and emitting a `$EXTERNAL` token on serialize — right next to its external-Widget
   rule. One self-documenting boolean per class; the mechanics live once, in the
   copier that owns copy-policy. Applied to BOTH `Wallpaper` and `WidgetFactory` (the
   latter's latent 6a.2 exposure — its demo-menu items target `world.widgetFactory` —
   hardened at the same time). Any future world-collaborator used as a menu target
   should set the same flag.

---

## The three targets — study findings (2026-06-17, full read of all three files)

### A. `Widget` (4725 L) — one DET-heavy core + a liftable rim

Only `@augmentWith DeepCopierMixin` (L14); everything tree-related comes from
`extends TreeNode`. ~30 cohesive clusters. The **DET core** (do NOT touch early):
geometry getters/mutators + fractional-in-panel (C2/C3/C4, ~840 L), full/clipped
bounds + caches (C5), visibility/collapse (C6), paint/render coordination (C7),
image+screenshot capture (C8, the SystemTest hash source), shadow (C9),
change-tracking (C10), add/remove (C12), drag/grab (C14), **scroll-structure
queries (C15)**, focus/pop-up/keyboard + mouse entry (C17/C18), and **the layout
engine `doLayout` + dim solver (C28, `:4213`, ~520 L incl. `addOrRemoveAdders`
`:4401`)**.

The **liftable rim** (lower DET risk; each move recaptures the inspector test per
guardrail 1):

| Cluster | What | Lines | Notes for moving |
|---|---|---|---|
| C22 | Demo/factory `create…` menu actions + `@setupTestScreen1` (`:4469`, ~256 L) | ~900 | Largest by volume; **almost all homepage-excluded scaffolding**. Many are `menusHelper` string-action targets → rebind call sites (see MenusHelper coupling). Houses the `1960` shortcut-dedup filter. |
| C20 | Setter-introspection (`colorSetters`/`stringSetters`/`numericalSetters`/`allSetters` `:3781-3809`) | ~110 | Pure (builds string/fn-name arrays). Soak-delegates `addShapeSpecific*` to `@appearance` already. |
| C23 | Inspector/console/prompt/dialog spawning (`spawnInspector` `:2858`, `inform`/`prompt`/`pickColor` `:2798-2830`) | ~130 | Opens `InspectorWdgt`/`PromptWdgt`/etc. Behaviour-touching but cohesive. |
| C25 | Code injection / `eval` (`injectProperty`/`injectProperties` `:2450-2460`, `evaluateString` `:3904`) | ~50 | Patch-programming eval; ends in `reLayout`+`changed`. |
| C21 | Context-menu construction (`buildContextMenu` `:2888`, `buildBaseWidgetClassContextMenu` `:3426`, hierarchy menu `:2925-2965`) | ~250 | Houses the `2903`/`2952-2954`/`3455-3456` menu filters. **`Wdgt`-label-stripping hazard** (menu labels drift → screenshots) — verify carefully. |
| C19 | Entry-field tab navigation (`allEntryFields` `:3824`, `next/previousEntryField`) | ~25 | Houses the `3827-3828` text-type filter. |
| C24 | Serialization/copy wrappers (`fullCopy`/`serialize`/`deserialize` `:2340-2406`, align* `:2312-2329`) | ~150 | Deep-copy core already in `DeepCopierMixin`; these are call-sites + world-structure re-registration. SWCanvas image-decode branch in `deserialize` is backend-sensitive. |

**Cross-cluster coupling to respect:** `@changed()`/`@fullChanged()` (C10) is called
from nearly every mutator; `invalidateLayout()` (C28) from C3/C6/C12/C27; the
`world.widgetsThatMaybeChanged*` / `WorldWdgt.numberOf*` counters tie C5/C6/C10/C12;
the `@parent.parent.adjust*` scroll reach-through (C15) is invoked from inside C3's
`fullRawMoveBy`/`silentRawSetExtent`.

### B. `WorldWdgt` (2224 L) — already-thinned; a DET machine + a clean rim

**Already delegated (do NOT re-plan):** `MacroToolkit` (`@macroToolkit`), `Automator`
(`@automator`), `DesktopAppearance` (`@appearance`), `ActivePointerWdgt` (`@hand` —
incl. input *recognition*), `PreferencesAndSettings` (static), `InputEventsQueue`
(`@inputEventsQueue`), `CaretWdgt` (`@caret`), and desktop-icon creation (global
`menusHelper`). Two mixins: `GridPositioningOfAddedShortcutsMixin` (L4),
`KeepIconicDesktopSystemLinksBackMixin` (L5) — scenegraph lifecycle hooks, not in
scope.

**DET core (the late capstone — one tightly-bound machine):** DOM listener wiring
(`init*EventListeners` ~L1415-1698), the cycle loop (`doOneCycle` `:1216`,
`playQueuedEvents` `:1154` — explicitly event-time gated), the broken-rectangles
render loop (`updateBroken` `:926` + ~17 helpers, ~440 L), repaint error recovery
(`:1028-1080`), SWCanvas blit (`:1001-1022`), and per-frame highlight/pinout overlays
(`:1092-1119`). DETERMINISM.md gates all of this.

**Clean liftable rim (mirrors MacroToolkit best):**

| Candidate collaborator | Methods (line) | Lines | Class. |
|---|---|---|---|
| **Untitled-naming service** | `getNextUntitledShortcutName` (405), `getNextUntitledFolderShortcutName` (414); counters `howManyUntitled*` L224-225 | ~30 | PURE-MOVE, self-contained — the cleanest first World move. NB `colloquialName` (376) is NOT part of this — it's a polymorphic LABEL override (base `Widget:1932`, 65 overrides) and STAYS. Call sites to rewire: `SaveShortcutPromptWdgt:14`, `PanelWdgt:36`, and the raw field-bump `PanelWdgt:37` `world.howManyUntitledShortcuts++` (encapsulate as a method). |
| **Widget factory ("parts bin")** | `create` (1961) + ~24 `createNew*` (1965-2091), `underTheCarpet`, `draftRunVideoPlayer` | ~310 | PURE-MOVE, uniform (`@create new XxxWdgt` → `pickUp`); low coupling (`@hand`,`@add`) |
| **Menu/wallpaper UI builders** | `buildContextMenu` (1831), `popUp*Menu` (1948-2150), `wallpapersMenu`/`setPattern`/`makePrettier` (379-1917) | ~305 | PURE-MOVE but cross-reference each other + many *inherited* methods; mostly homepage-excluded |
| **Popup/tooltip lifecycle** | `mostRecentlyCreatedPopUp` (553), `closePopUpsMarkedForClosure` (589), `destroyToolTips` (1818) + the Sets L132-138 | ~55 | BEHAVIOUR-TOUCHING (external callers mutate the Sets) |
| GC cross-ref | `anyReferenceToWdgt` (2216) | ~10 | PURE-MOVE |

**Shared seams to decide explicitly:** `createErrorConsole` (startup vs error-recovery),
`initVirtualKeyboard` (listener-wiring vs caret-focus), `syncRenderCanvasToWorldCanvas`
(blit vs sizing), the `widgetsThatMaybeChanged*` arrays (loop vs render). **Serialization
caveat:** relocating *stateful* World fields onto a collaborator changes what
`DeepCopierMixin` snapshots — check serialization fixtures before moving stateful
clusters (popups, caret, overlays).

### C. `MenusHelper` (1170 L, 132 methods) — the Divergent-Change magnet; SAFEST recapture-wise, but reflection-coupled

**Access pattern:** eager global singleton `window.menusHelper`
(`src/boot/globalFunctions.coffee:419`). No `world.menusHelper`, no mixin, no
statics. **122 of 132 methods are builders/factories:** 7 heavyweight window builders
(a1: `createNewTemplatesWindow` `:321`; `createSampleSlideWindow…` `:832`;
`createSampleDashboardWindow…` `:920`; `createDegreesConverterWindow…` `:1045`; +3
thin), 7 launch-app (a2 `:168-287`), 5 thin launch delegators (a3), 12 launcher/opener
factories (a4), 29 single-widget demos (a5), **62 trivial icon factories** (a6, ~2 L
each), 8 `popUp*Menu` sub-menu builders (b). The remaining: `makeSlidersButtonsStatesBright`,
`throwAnError`. **No generic menu infra lives here** (`addMenuItem` is on `MenuWdgt`,
`popUpAtHand` on `PopUpWdgt`).

**THE defining risk — string-action reflection coupling.** Menu actions are stored as
`menu.addMenuItem "<label>", true, menusHelper, "<methodName>"` and invoked by
reflection as `target[action]()`. The `target` is the `menusHelper` instance; the
`action` is a **method-name string**. Call sites are mostly in `Widget.coffee`
(~3261-3475, cluster C22) plus direct `WorldWdgt` bootstrap calls (`:464-478`) and 3
button widgets. **A compiler will NOT catch a missed rebind** — only runtime/
SystemTests will. So moving a builder out is *not* a pure symbol move: its `(target,
"action")` call sites must move in lockstep. **Keep each launcher + its `launch*` + its
`create*Window*` as ONE unit** (they're bound by the target/action pairing). Shared
skeleton across builders (`new WindowWdgt …; setExtent; fullRawMoveTo;
fullRawMoveWithin world; world.add`) + the a1 "bring-up-if-already-created" singleton
guard (`world.<name>Window`) + a `closeFromContainerWindow` monkey-patch — a shared
base for the extracted `*Window` classes should wrap these. Not [DET]-timer-sensitive,
but **preserve geometry + statement order** (fixed positions/extents) or screenshots
shift.

---

## Dissolution map — which deferred Phase-5 check each Phase-6 move resolves

| Deferred Phase-5 check (Widget line) | Cluster | Dissolves when… |
|---|---|---|
| `1960` shortcut-dedup (G) | C22 demo/factory | C22 moves to a widget factory → the filter leaves Widget (becomes a local search in the factory) |
| `3827-3828` entry-field text-type (G) | C19 | entry-field nav moves to a focus/tab collaborator |
| `2903`, `2952-2954`, `3455-3456` menu filters (F) | C21 | context-menu construction moves to a menu-builder collaborator |
| `amIDirectlyInside*` (B, `2579-2591`), `grabsToParentWhenDragged` (E, `2519`) | C14/C15 | **only the DET capstone** — when scroll/drag coordination moves out of `Widget`; high-risk, late |
| `addOrRemoveAdders` `LayoutElementAdderOrDropletWdgt` ×5 (G) | C28 | **only the DET capstone** — when layout-adder management moves out of the layout engine |

**Honest note:** the *cheap* Phase-6 moves (naming, factory, demo scaffolding, menus)
shrink the God classes and dissolve the **filter** checks (G) and **menu** checks (F),
but the **scroll-structure topology** checks (B/E) and the **adder** filter dissolve
only in the **DET capstone** (layout/scroll coordination extraction), which is the
riskiest, last sub-arc. Decoupling Widget from scroll identity "completely" is
therefore gated on that capstone — it should likely get its own mini-plan when reached.

---

## Proposed sub-arc — risk-ascending (each = one collaborator/app, one commit)

**Tier 1 — MenusHelper → per-app window-builder classes (6c).** Safest on
recapture (separate singleton; ~zero inspector churn). **ARCHITECTURE DECIDED (open
decision #4): per-app `*Wdgt` classes hosting the heavy builder as a static `@create`
factory — NOT a grouped `WindowFactory` (which would just relocate the God-class-ness
and re-introduce a deep-copy/menu target).** This is already the house pattern:
`menusHelper.createSampleDocWindowOrBringItUpIfAlreadyCreated` is just a singleton-guard
that calls `SimpleDocumentSampleWdgt.create()` (`src/apps/`), and `WelcomeMessageInfoWdgt`
/ `HowToSaveMessageInfoWdg` are the same shape — so 6c is "do to the other windows what
was already done to Sample Doc." **Keep the thin launch/opener/singleton-guard glue on
`menusHelper`** (it's tiny and reflection-bound): then the reflection string-action
targets and the launcher `@target` do NOT move → no rebind, no deep-copy change for the
sample-window steps. **EVOLVED 2026-06-18 (owner chose the richer abstraction):** the
launch/opener/bring-up apparatus was found duplicated across **12 desktop apps** in two
families (7 fresh-window desktop launchers that build a new window per click + spawn a
`*InfoWdgt`; 5 examples-folder singletons that bring-up-or-create via a `world.<slot>`).
So rather than leave thin glue on `menusHelper`, a base class
**`IconicDesktopSystemWindowedApp`** (`src/IconicDesktopSystemWindowedApp.coffee`) now OWNS
the apparatus -- `createOpener(folder)` (a single `if folder?` branch is byte-faithful to
both the in-folder and desktop opener variants) and `launch()` (slot set => bring-up-or-
create; else build + `windowOpened` hook) -- and each app is a small subclass declaring
`title`/`slot`/`toolTip` + `buildIcon`/`buildWindow`/`windowOpened`. The launcher's
reflection target moves `menusHelper` => the app instance (uniform action `"launch"`); the
app sets `keptByReferenceOnDeepCopy: true` (guardrail #7, proven via a `fullCopy` probe).
Non-launcher builders reached by a direct code call (Templates) still become a standalone
`*Wdgt.create()`. One sub-step per app/group:
  - **6c.1 Templates — DONE.** Lifted `MenusHelper.createNewTemplatesWindow` (~119 L,
    a *pure* builder: no `@`, no `world`) verbatim into a new
    `src/apps/TemplatesWindowWdgt.coffee` (`class … extends WindowWdgt` with a static
    `@create: ->`, factory-namespace like `SimpleDocumentSampleWdgt`). It is the
    degenerate case — **NOT a menu/launcher target** (its 3 callers are direct *code*
    calls: `UsefulTextSnippetsToolbarCreatorButtonWdgt:8`, `TemplatesButtonWdgt:18,26`,
    all repointed to `TemplatesWindowWdgt.create()`), so no reflection rebind and **no
    deep-copy guardrail (#7) needed**. Core/homepage-shipped (no strip-marker move). Body
    verified byte-identical to HEAD before deletion (the Unicode special-chars paragraph
    + the Malraux curly-quote line). 165/165 dpr1+dpr2+WebKit + `--homepage` boot, zero
    recapture.
  - **6c.2 SampleSlide -- DONE (Stage 1 of the app framework).** Created the base
    `IconicDesktopSystemWindowedApp` + the first subclass `src/apps/SampleSlideApp.coffee`
    (singleton, slot `sampleSlideWindow`; the NYC-slide `buildWindow` body lifted verbatim
    from MenusHelper L719-781, byte-verified, ending `return wm` -- the old final
    `world.<slot> = wm` is now done by the base's `launch`). Removed the 3 SampleSlide
    methods from MenusHelper (-92 L, now 955); rewired `WorldWdgt:458` to
    `(new SampleSlideApp).createOpener exampleDocsFolder`. 165/165 dpr1+dpr2+WebKit +
    `--homepage`; a targeted headless check confirms launch builds `world.sampleSlideWindow`
    ("Sample slide"), re-launch reuses it, `launcher.target`=app / callback `"launch"`, and
    `fullCopy` keeps the app by reference (no throw). Zero recapture.
  - **Remaining (port onto the base, in batches):** the 4 examples-folder singletons
    SampleDashboard / SampleDoc / DegreesConverter / HowToSave (SampleDoc & HowToSave
    already have extracted builders, so their `buildWindow` just calls
    `SimpleDocumentSampleWdgt.create()` / `HowToSaveMessageInfoWdg.create()`); then the 7
    fresh-window desktop launchers (Family 1 -- `buildWindow` builds+adds the window,
    `windowOpened` does `*InfoWdgt.createNextTo`); then the a5/a6 demo+icon factories (bulk,
    mostly homepage-stripped, L18-150/442-755) and the `popUp*Menu` builders (NOT apps --
    separate treatment). Each batch rebinds its `WorldWdgt:447-460` bootstrap calls in
    lockstep and verifies with the recipe + a targeted check.
  Verify: full recipe. **REFINEMENT (found in 6c.1):** the suite + boot-smoke do NOT
  exercise the window-builder paths — **zero** SystemTests touch them (only one test
  references `menusHelper` at all, for `makeSlidersButtonsStatesBright`), and these
  windows aren't built at boot (the openers are, at `WorldWdgt:447-460`, so boot covers
  *opener* construction only). So the plan's earlier "suite catches missed rebinds" is
  **overstated for window-builder bodies** — add a **targeted headless check** per step
  (boot the build, invoke the moved factory, assert the right window + no console error),
  as done for 6c.1. Expect ~zero recapture (confirmed for 6c.1).

**Tier 2 — `WorldWdgt` clean rim (6a).** One collaborator per sub-step, MacroToolkit-style:
  - **6a.1 NamingService — DONE 2026-06-17** (`UntitledNamingService`; 2 methods +
    2 counters off WorldWdgt, 3 call sites rewired incl. encapsulating a raw field-bump
    as `noteShortcutCreated`; `colloquialName` correctly left in place). **Zero recapture
    confirmed** — no SystemTest inspects the World, so a WorldWdgt method-move is clean
    (answers the open question for Tier 2; the recapture tax is a `Widget`-base concern).
    · **6a.2 WidgetFactory — DONE 2026-06-17** (23 `createNew*`/`underTheCarpet` demo
    builders → `world.widgetFactory`, a whole-file homepage-stripped collaborator,
    guarded `if WidgetFactory?` ctor; the `create` pickUp helper STAYS on world as
    public API; 27 `createNew*` + 1 `underTheCarpet` demo-menu string-action targets
    rebound `@`→`@widgetFactory` via a replace-all that caught 2 items in a *second*
    menu (`layoutTestsMenu`) a manual sweep would have missed; the German Loreley
    text in `createNewText` verified byte-exact vs HEAD before the move; zero
    recapture) · **6a.3 Wallpaper — DONE 2026-06-17** (NARROWED per study: only the wallpaper
    cluster — `wallpapersMenu`/`setPattern`/`updatePatternsMenuEntriesTicks` + the 8
    `pattern*` fields + `patternName` → a core `Wallpaper` collaborator
    `world.wallpaper`; `DesktopAppearance` now reads `@widget.wallpaper.pattern*`;
    named `Wallpaper` not `WallpaperManager` per owner. Context-menu builders LEFT on
    WorldWdgt — see note below. **Surfaced + fixed a deep-copy hazard**, guardrail #7.)
    · 6a.4 popup/tooltip lifecycle (stateful — check serialization) · 6a.5
    `anyReferenceToWdgt`.
- **The world's CONTEXT-MENU builders are NOT clean extraction targets** (finding
  from 6a.3): `buildContextMenu` + the dev `popUp*Menu`/`layoutTestsMenu` dispatch by
  reflection string-action to `@`=world's own AND *inherited* Widget methods
  (`makeFolder`, `testMenu`, `popUpColorSetter`, `noOperation`). Moving them to a
  plain collaborator breaks every such target; they are the world's own UI, not a
  separable responsibility — leave them on WorldWdgt.
  Verify: full recipe; recapture only if a test inspects the World (check first).

**Tier 3 — `Widget` liftable rim (6b, non-DET).** Each moves methods off Widget →
**expect the inspector recapture** (guardrail 1); handle per Cluster A.
  - 6b.1 C22 demo/factory + `@setupTestScreen1` (huge, mostly homepage-excluded; also
    finishes 6c's call-site story) · 6b.2 C20 setter-introspection · 6b.3 C23
    inspector/prompt spawning · 6b.4 C25 eval · 6b.5 C21 menu construction (Wdgt-label
    hazard — verify) — dissolves F · 6b.6 C19 entry-field nav — dissolves G(text).

**Tier 4 — the DET capstone (6b late + 6a DET core).** HIGHEST risk; its own
mini-plan when reached. Read DETERMINISM.md; dpr2+WebKit mandatory; recapture expected.
  - scroll/drag coordination off Widget (dissolves B/E) · layout-adder management off
    the layout engine (dissolves the adder filter) · (optionally) factor the WorldWdgt
    render/input machine into a renderer/input-loop object — only if a clean seam exists
    without perturbing event-time/broken-rect determinism.

---

## Open decisions for the owner (before coding)

1. **Start tier:** Tier 1 (MenusHelper, safest recapture, but reflection rebind) vs
   Tier 2 (WorldWdgt naming, tiny + clean) as the first sub-step. *(Recommendation:
   6a.1 NamingService as a 1-collaborator proof, then Tier 1 in bulk.)*
2. **Recapture budget:** confirm you're OK regenerating the inspector test(s) on each
   Tier-3 Widget move (it's expected, per guardrail 1) — or whether to batch all
   Widget moves so the inspector recaptures once.
3. **DET capstone scope:** whether Tier 4 (and thus "completely" decoupling Widget
   from scroll identity) is in-scope now or deferred to a dedicated later effort.
4. **MenusHelper home: DECIDED — per-app `*Wdgt` classes with a static `@create`
   factory** (mirroring the existing `SimpleDocumentSampleWdgt`/`WelcomeMessageInfoWdgt`
   precedent), NOT a grouped `WindowFactory`. **EVOLVED 2026-06-18:** for the launcher
   apps the launch/opener/bring-up apparatus is owned by a base class
   `IconicDesktopSystemWindowedApp` with one small subclass per app, NOT left as glue on
   `menusHelper`. See Tier 1 above. (Non-launcher builders reached by a direct code call,
   like Templates, stay standalone `*Wdgt.create()`: 6c.1 `TemplatesWindowWdgt`; 6c.2
   `SampleSlideApp` + the base.)
