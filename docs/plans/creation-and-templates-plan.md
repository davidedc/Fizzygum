# Creation & templates — one way things come into being

**STATUS: AUTHORED 2026-07-18 — design-stage, exploratory. NO code written yet. Owner-gated execution.**
Anchor on **symbol names** (verified 2026-07-18); line numbers drift. Self-contained.

Part of one program with [`onion-widget-composition-plan.md`](onion-widget-composition-plan.md),
[`container-regularization-plan.md`](container-regularization-plan.md),
[`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md), and
[`reference-widgets-plan.md`](reference-widgets-plan.md). **This arc supersedes the launcher/Factory section
of the reference plan.** North star: orthogonalisation, de-byzantination, regularity.

---

## 1. The idea

Today, new widgets come into being through a **zoo of bespoke creation paths**. Unify them into exactly two
mechanisms, from the *Reference morphs* note's Apps-vs-Files framing:

> **Creating anything = duplicate a pristine *template*, or run an *assembler script*. Nothing else.**

- **Factory** — duplicates a pristine, data-empty **template** object (e.g. "new empty text", "new empty
  slide"). The `isTemplate` field already exists on `Widget`.
- **ScriptRunner** — runs a script that *assembles* an object (e.g. a script that wires up a temperature
  converter, or instantiates an Inspector).

And the definition we settled in the Frame model: **an "App" is just a Factory that opens an empty framed
`*Wdgt` in edit mode** (per [`onion-widget-composition-plan.md`](onion-widget-composition-plan.md) §1.3).

The *Reference morphs* note's "Apps vs Files" observation is the frame: everything is an object with its own
methods, so the App/File distinction is a convenience — a "File" is classic user data; an "App" is a
Factory (duplicate-a-pristine-object) or a ScriptRunner (assemble-via-script). One creation model serves
both.

---

## 2. Current-state truth (verified 2026-07-18)

Creation is scattered across at least five bespoke paths:

- **App launchers:** `IconicDesktopSystemWindowedApp` (plain factory base) + 14 `*App` subclasses; each
  `buildWindow` news-up a content widget and calls `world.openWindowWith(...)`. The desktop launcher widget
  is `IconicDesktopSystemWindowedAppLauncherWdgt` (double-click → `app.launch()`).
- **Creator buttons:** `CreatorButtonWdgt` (`buttons/`, `extends Widget`) + subclasses (the
  `*CreatorButtonWdgt` "switcheroo" creators, the `ToolbarCreatorButtonWdgt` family) that spawn widgets on
  click.
- **`WidgetFactory`** (`WidgetFactory.coffee`) — a direct construction helper.
- **`MenusHelper`** — "new X" / `createEmptyWindow*` menu entries (already God-class-split out of
  `WorldWdgt`, `docs/archive/god-class-decomposition-plan.md`).
- **Paint tool injection** — `CodeInjectingSimpleRectangularButtonWdgt` injects behaviour into a target
  (a different, code-injection flavour of "make something new happen").

Substrate that already supports the unification:
- **`Widget.isTemplate`** exists (a pristine-object marker).
- **`DeepCopierMixin`** is the one graph copier (`@augmentWith`) used for duplication + serialization — so
  "duplicate a template" already has its engine.
- **`Widget.fullCopy`** / the serialization pair produce a clean object graph.

**Gaps:** no single "create = duplicate-template | run-assembler" contract; `isTemplate` is under-used; the
launcher/creator/factory paths don't share a base; "App" isn't formally "a Factory over an empty framed
`*Wdgt` in edit mode."

---

## 3. Architecture we MUST respect

- **Duplication goes through `DeepCopierMixin`** (property-based graph copy, cycle-safe) + the
  `Serializer`/`Deserializer` pair; a template duplication is a `fullCopy` of a pristine object. A class
  with transient/derived fields must declare `@serializationTransients` and/or stamp `rebuildDerivedValue`
  (the two don't cover each other). See `docs/architecture/serialization-duplication-reference.md`.
- **Settle/constructor rules** (`check-constructors-build.js`): a Factory that builds an object must go
  through the self-settling `_buildAndConnectChildren` path, not inline construction.
- **Determinism:** creation must be a pure function of the event stream (no wall-clock in what gets built
  or its ids); id assignment already flows through `assignUniqueID`/`idCounters` (serialized).
- **This arc pairs with the graph-edge model** ([`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md)):
  a Factory/launcher on the desktop is itself a **reference** (a launcher points at what it creates), and a
  freshly-created object enters the graph as a new containment root — so creation and lifecycle share the
  edge vocabulary.

---

## 4. Proposals

### 4.1 Name the two creation primitives. *Contract first.*
Introduce **`FactoryWdgt`** (duplicates a pristine `isTemplate` object via `DeepCopierMixin`) and
**`ScriptRunnerWdgt`** (runs an assembler script) as the two sanctioned creation widgets — or as a shared
`CreatorWdgt` base with those two modes. Both are **reference-family** widgets (they point at a
template/script). Document the contract: *create = duplicate-template | run-assembler*.

### 4.2 Redefine "App" as a Factory over an empty framed `*Wdgt` in edit mode.
Re-express `IconicDesktopSystemWindowedApp` as a **Factory** whose template is an empty framed `*Wdgt`
(`DocumentWdgt`/`ImageWdgt`/`SlideWdgt`/…) and whose post-create step is "open in edit mode." The 14 `*App`
subclasses become thin Factory declarations (template + icon + title). This ties the Frame model's
"App = launcher" definition to a real mechanism.

### 4.3 Route the creator zoo through the two primitives.
Fold `CreatorButtonWdgt`/`*CreatorButtonWdgt`, `WidgetFactory`, and `MenusHelper`'s "new X" entries onto
`FactoryWdgt`/`ScriptRunnerWdgt` (a creator button *is* a Factory or ScriptRunner with a click affordance).
Retire the bespoke paths as each is proven equivalent. The paint code-injection stays separate (it mutates
an existing target, not "creation") unless it fits the ScriptRunner shape.

### 4.4 (bank) Templates as first-class, editable objects.
Make `isTemplate` objects first-class: a template is a pristine object you can *inspect and edit* (change
the "new empty text" defaults), and a Factory always stamps the current template. Pairs with the
"Grouped webs of classes" idea (duplicating a class-web to edit it live) — banked, not scoped here.

---

## 5. Owner decisions
| # | Decision | Recommendation |
|---|---|---|
| K1 | Scope for v1 | **4.1 + 4.2** (name the primitives; App = Factory) — high-clarity, moderate risk. 4.3 (fold the zoo) is the second wave. |
| K2 | `FactoryWdgt`/`ScriptRunnerWdgt` vs one `CreatorWdgt`+modes | Lean two named classes (clearer), sharing a reference-family base. |
| K3 | Does paint code-injection fold in? | Probably not (it's mutation, not creation) — leave unless it's cleanly a ScriptRunner. |

## 6. Risks & non-goals
- **Serialization/duplication correctness** — a Factory is a `fullCopy` of a template; transient/derived
  fields must be declared or the copy is subtly wrong.
- **Determinism** — created ids/content must be event-time-pure.
- **Non-goals:** the reference-widget *UI* taxonomy (reference plan); the graph-edge/GC mechanics (arc (b));
  live class-web duplication (banked, 4.4).

## 7. Cross-links
- Supersedes: reference-plan launcher/Factory section (see [`reference-widgets-plan.md`](reference-widgets-plan.md)).
- Program siblings: [`onion-widget-composition-plan.md`](onion-widget-composition-plan.md) (App = Factory over
  an empty framed `*Wdgt`), [`graph-edges-and-lifecycle-plan.md`](graph-edges-and-lifecycle-plan.md) (a
  Factory is a reference; creation enters the graph),
  [`container-regularization-plan.md`](container-regularization-plan.md).
- Architecture: `docs/architecture/serialization-duplication-reference.md`; determinism:
  `Fizzygum-tests/DETERMINISM.md`.
```
