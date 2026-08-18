> **ARCHIVED — COMPLETE (2026-08-02).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# The lazily-populated folder, and the entry points that bypass its readiness protocol

> ## ✅ COMPLETE — executed 2026-08-02, same day it was authored.
> **The §6.1 spike settled the question the plan was written around, and BOTH of §0.2's predictions
> were correct.** The shelf scenario the code documented is unreachable — `world.shelfWdgt` is
> constructed in `globalFunctions.startWorld` and never added to any parent, so there is no shelf UI
> to drag out of. The BIN route is real and was driven end to end on a built `index.html`
> (`Fizzygum-tests/.scratch/spike-folder-reachability.js`): delete the Examples shortcut → the
> storage sorter drains the folder window to the bin → click the bin opener → **the folder is on the
> tree and PAINTED, empty** → a real synthesised mouse drag pulls it onto the desktop, where it stayed
> empty for ever (`populated:false, children:0`, `examples-icons` never fetched, zero console errors).
> So the comment's consolation ("shows empty once; the next bring-up fills it") was false on the only
> reachable path — no shortcut survives it.
>
> ⭐ **The spike also moved the fix.** §4.C (hook the bin's revival path) is not merely awkward but
> INSUFFICIENT: the folder is already painted-empty *inside the bin window*, before any drag. The
> bug's onset is "the bin is opened", not "the drag completes". §4.B was implemented —
> `ExamplesFolderWindowWdgt` registers in `world.steppingWdgts` while it still owes itself content and
> populates from `step` the first time `@root() == world`, unregistering on that one shot.
>
> ⚖ **§1.5's two stated costs both came out smaller than the plan feared.** "Runs every cycle for
> ever" is wrong for this mechanism: stepping is opt-IN via `world.steppingWdgts` (the
> `DataflowSource` precedent), so the cost ends at the first fill and never starts again — and a
> populated folder restored from a snapshot is never registered, because the Serializer already
> records stepping membership. The "visible pop" is also mostly absent: `_playQueuedEvents` runs
> EARLIER IN THE SAME CYCLE than `_runChildrensStepFunction`, both before the paint, so an
> already-fetched part fills the folder in the very frame the drop lands. Only the first-ever open,
> which must fetch, can show a flash.
>
> **Gate (§6.4):** `scripts/parts-lazy-icons-headless.js` (`fg lazyprobe`, gauntlet `parts` leg) grew
> the route as six assertions, and they check BOTH halves — that deleting the shortcut fetches
> NOTHING while the folder is off the tree (which would catch a "fix" that just populated eagerly),
> and that being shown fills it. Proven non-vacuous by a negative control that removes the folder from
> `steppingWdgts` at runtime to reproduce the pre-fix world (`.scratch/spike-negative-control.js`).
>
> ⚠ Both comments and the architecture doc were corrected (§6.5). No SystemTest reference moved, as
> predicted: the harness page builds no desktop, and the fix adds no member to `Widget.prototype`.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.** Everything
needed is embedded here or one named-doc hop away. **Line numbers WILL drift — the quoted symbol or
code fragment is authoritative; re-grep before editing.** Facts verified against `7f5830ef`
(2026-08-02).

**MANDATE: make a lazily-populated folder fill itself no matter what puts it on the tree — or prove
the gap is unreachable and correct the record.** ⚠ The second outcome is a legitimate result of this
plan, not a failure: §0.2 gives concrete reason to doubt the bug as currently documented, and
shipping a fix for an unreachable path is worse than shipping nothing.

---

## §0 Orientation

### §0.1 What Fizzygum is (30 seconds)

A CoffeeScript GUI framework — a "web operating system" on one HTML5 canvas. **No module system**:
every class is a global, shipped as escaped source text, compiled in the browser. One class per file,
filename == class name. `nil` means `undefined`. Root workspace `Fizzygum-all/` holds three sibling
repos: `Fizzygum/` (source), `Fizzygum-tests/` (269 SystemTests), `Fizzygum-builds/` (output).

Layout runs in **settle tiers** that must not re-enter: a public geometry setter self-flushes, and
low-level code must never reach back up into it. That constraint is what makes this plan non-trivial
— see §1.4.

### §0.2 ⚠⚠ THE CRITICAL REFRAME — the bug may not be reachable as written

`src/IconicDesktopSystemShortcutWdgt.coffee` (in `bringUpTarget`) documents the gap like this:

> ⚠ KNOWN LIMIT: this is the bring-up ritual, so it covers the shortcut click — the way a user opens
> a stored thing — but not a window dragged straight out of **the shelf** by hand. That window shows
> empty once; `populated` is still false, so the next bring-up fills it.

**But `ShelfWdgt` says of itself:**

> I am a pure backing store: **no opener, no icon, no window path, no view. I am never on the tree and
> never painted** — residents are re-homed out of me by their revival paths (shortcut click, app
> launch) exactly as they are out of the bin.

If the shelf is never painted and never on the tree, **there is no shelf UI to drag out of**, and the
documented scenario cannot happen. Do not start by building a fix for it.

**The path that probably IS reachable is the BIN**, which unlike the shelf is a real view
(`BinWdgt` is "a VIEW, not a fixed-proportion artifact", wrapped in a window by `BinOpenerWdgt`, with
a scroll panel of its residents). The route would be: *delete the folder's desktop shortcut → the
window becomes LOST → the storage sorter drains it to the bin → the user opens the bin → drags the
window out onto the desktop.* ⚠ And note that in **that** path the consolation in the comment is
false: there is no shortcut left to click, so nothing will ever call `bringUpTarget` and the folder
stays empty **permanently**, not "once".

⇒ **§6 step 1 is a reachability spike, and its result decides everything after it.**

### §0.3 Why this is worth a plan at all

Not for the one folder. The shape is: **a widget with a lazily-populated body has a readiness
protocol that exactly one call path honours.** Any future lazily-populated container inherits the same
hole. The fix worth having makes population depend on *being shown*, not on *which ritual showed it*.

---

## §0.5 Cold-execution protocol

1. **Orient.** `/Users/davidedellacasa/code/Fizzygum-all/fg status` — expect all repos clean.
   Read `docs/architecture/build-and-packaging.md` §2 (the three tiers: boot → open → click) and
   this plan's §1 in full.
2. **Run the §6.1 spike FIRST and report its result before writing any fix.** If no path is
   reachable, the plan's deliverable becomes a corrected comment (§6.5) — stop there and say so.
3. Execute §6 in order; `fg build` after each step.
4. Gate with §7.
5. **Do not commit or push without the owner's approval.** Present a summary + message and wait.
   `git commit -F <file>`, never `-m`.

**Standing working rules:** long ops in the background (`run_in_background`), wait for the
notification — no foreground `until … sleep` pollers, a guard hook blocks them. **Never edit `src/`
or `tests/` while a gauntlet or suite is running.** Absolute paths. **Never `git stash` in this repo.**

---

## §1 Exact current state

### §1.1 The three tiers, and what the middle one actually buys

`docs/architecture/build-and-packaging.md` §2. The Examples folder exists so that:

| moment | what arrives |
|---|---|
| boot | the folder, EMPTY. No icon of its contents, no app class |
| the folder is opened | the `examples-icons` part, and the five openers are built. Still no app |
| an opener is clicked | that one app's one-class part — and no other's |

⚠ Be precise about the middle tier's payoff, because it bounds how much complexity is worth spending
here: the five openers are built from **core** art plus class NAMES, so the ONLY thing the "open" tier
defers is the `examples-icons` part — **the C↔F glyph, ~9.4 KB of source**. That is the entire prize
being protected. A fix costing more machinery than that is a bad trade.

### §1.2 The readiness protocol, and its single caller

`src/ExamplesFolderWindowWdgt.coffee`:

```coffee
populated: false          # SERIALIZED deliberately (see the class comment)

whenReadyToBeBroughtUp: (callback) ->
  return callback() if @populated
  return callback() unless world.parts.isAvailable "examples-icons"
  world.parts.whenAllLoaded ["examples-icons"], =>
    unless @populated          # a second click mid-fetch must not build twice
      @populated = true
      L = IconicDesktopSystemWindowedAppLauncherWdgt
      L.addToFolder @, "DegreesConverterApp", -> new DegreesConverterIconWdgt
      L.addToFolder @, "SampleSlideApp"
      … three more …
    callback()
```

`Widget.whenReadyToBeBroughtUp` is a no-op default (`callback()` inline), so every other widget pays
nothing. **The only caller is `IconicDesktopSystemShortcutWdgt.bringUpTarget`:**

```coffee
@target.whenReadyToBeBroughtUp => @_bringUpTargetNow()
```

⚠ The await is *before* the window is shown — `_bringUpTargetNow` does the `spawnNextTo`. That is why
the click path never shows an empty folder: it fills, **then** appears. Any fix for a path where the
window is *already on screen* cannot reuse that ordering (§4).

### §1.3 How the folder gets to be off-tree in the first place

`PanelWdgt.makeFolder`:

```coffee
newFolderWindow = folderWindow ? new FolderWindowWdgt
newFolderWindow.close()                        # → comes to rest on the SHELF
newFolderWindow.createReference name, @        # → the desktop gets a SHORTCUT
```

`WorldWdgt.createDesktop` calls it as `@makeFolder nil, nil, "Examples", new ExamplesFolderWindowWdgt`.
So the desktop icon is a *shortcut*; the window itself rests off-tree.

### §1.4 ⛔ Why the obvious hook is not available

`Widget._reactToBeingAdded(whereTo, beingDropped)` is the lifecycle hook for "I have been added
somewhere". It is invoked from `_addNoSettle` (`src/basic-widgets/Widget.coffee`, the line
`aWdgt._reactToBeingAdded @, beingDropped`) — i.e. **inside the add's own settle**. Building five
children there re-enters the settle tier. It is not a seam content may be created in, and the base
implementation is just `@_reLayoutSelf()`.

### §1.5 ✅ The seam that IS available

`WorldWdgt.doOneCycle` runs, in order:

```
_updateTimeReferences · error reporting · macro steps · _playQueuedEvents · automator
runOtherTasksStepFunction · progressFramePacedActions · _runChildrensStepFunction
   → recalculateDataflow → recalculateLayouts → repaint
```

`_runChildrensStepFunction` runs **before** the dataflow and layout drains, outside any settle. A
widget's `step` (default `step: noOperation`) can therefore safely create children. This is the
mechanism a deferred population would use.

⚠ Two costs to weigh, not to wave through: a `step` runs **every cycle for ever** to check one
boolean, and populating a cycle *after* the window appears is a visible **pop**.

---

## §2 Why it is shaped this way

The readiness protocol was introduced with the folder's laziness, and `bringUpTarget` is genuinely
*the* way a user opens a stored thing — shortcut click is the ritual the whole desktop metaphor is
built on. Hooking it there was right and remains right. What was never established is whether any
OTHER path can put a lazily-populated window on the tree; the comment names one (the shelf) that
§0.2 suggests does not exist, which is itself evidence the question was reasoned about rather than
tested.

---

## §3 The distilled argument

1. **A readiness protocol honoured by one caller is a latent hole**, whether or not it is reachable
   today: the next lazily-populated container will inherit it.
2. **If the bin path is real, the documented consolation is wrong** — no shortcut survives that
   route, so "shows empty once" is actually "empty for ever" (§0.2).
3. **The prize being protected is small** (~9.4 KB, §1.1), so the fix must be cheap. A new lifecycle
   concept is not justified; a one-shot on an existing seam might be.
4. **Doing nothing is defensible if nothing is reachable** — but then the comment must stop asserting
   a scenario that cannot occur, because a false known-limit is worse than none.

---

## §4 Fix shapes, in the order they should be considered

### §4.A — Correct the record (if §6.1 finds nothing reachable)
Rewrite the `bringUpTarget` comment to state the real invariant: *population happens on the bring-up
ritual, which is the only way a resting widget reaches the tree; the shelf has no view and the bin's
revival paths go through the same ritual.* Cheapest possible outcome, and possibly the correct one.

### §4.B — One-shot populate on the step seam (if a path IS reachable)
`ExamplesFolderWindowWdgt` gets a `step` that, when it finds itself on the tree and not populated,
calls its own `whenReadyToBeBroughtUp -> nil` once and then stops caring. Uses only §1.5's existing
seam; no new lifecycle concept. ⚠ Accepts a visible pop on that path, which is acceptable *for a path
that today shows a permanently empty folder*, and never fires on the click path (already populated
before the window is shown).
⚠ Cost to state honestly: a per-cycle callback on one widget for the life of the world. If that is
judged too much, §4.C.

### §4.C — Populate from the bin's revival path instead
If §6.1 shows the bin is the only reachable route, hook the readiness protocol into whatever re-homes
a resident out of the bin, alongside the existing `bringUpTarget` caller. Narrower than §4.B, no
per-cycle cost, and it keeps "fill, then show" ordering if the revival path has a seam. ⚠ Verify it
actually has one — a drag-drop lands the widget synchronously.

### ⛔ §4.D — Populate directly in `_reactToBeingAdded`
Do not. §1.4: it runs inside the add's settle.

---

## §5 Central risks

- **Determinism.** The suite measures CYCLES, and the harness pages preset
  `FIZZYGUM_EAGER_ALL_PARTS`, so `whenAllLoaded` runs its callback **inline** there. A fix must keep
  the already-loaded path synchronous; anything that defers by a microtask moves an effect a whole
  cycle and shows up as pixel drift. See `Fizzygum-tests/DETERMINISM.md`.
- **The suite cannot see this at all.** `createDesktop` runs only `if world.isIndexPage`, and the
  harness page never builds a desktop. Laziness is observable on exactly one page. Whatever this plan
  changes, the check that proves it is a Node rig (`fg lazyprobe`, `Fizzygum-tests/scripts/`), not a
  SystemTest.
- **Serialization.** `populated` is a serialized boolean by design. Any new state must be serializable
  (⛔ never assign a closure to a widget field — the serializer cannot encode one, and doing it
  crashed the save path once).
- **Scope discipline.** The prize is ~9.4 KB. If the fix starts requiring a new hook in `Widget`,
  stop and re-read §3.4.

---

## §6 Execution steps

### §6.1 SPIKE — establish what is actually reachable (do this first, report before proceeding)
Empirically, on a built `index.html` (a Node rig under `Fizzygum-tests/.scratch/`, which is
gitignored — ⚠ put ad-hoc probes THERE, not in the session scratchpad: Node resolves `require` from
the script's directory):
1. Can a user reach the folder window without `bringUpTarget`? Drive: delete the desktop shortcut,
   confirm the window lands in the bin, open the bin, grab the window out, and observe whether it is
   empty and whether anything ever fills it.
2. Enumerate every caller that can add a `FolderWindowWdgt` to the tree. Start from
   `Widget._addNoSettle`'s callers and from the bin/shelf revival paths.
3. Record the answer in this plan before writing code.

**✅ SPIKE RESULT (2026-08-02).** Driven on a built `index.html` by
`Fizzygum-tests/.scratch/spike-folder-reachability.js`, with a real synthesised mouse drag:

| step | observed |
|---|---|
| boot | folder on the SHELF, off-tree, `populated:false`, 0 children |
| "delete" the desktop shortcut (the generic widget menu binds that entry to `close`) | shortcut AND folder both drain to the BIN; folder still off-tree and unpopulated |
| click the bin opener | bin window on the tree — and the folder is painted **inside it, empty**, chain `ExamplesFolderWindowWdgt → PanelWdgt → ScrollPanelWdgt → BinWdgt → FrameWdgt → WorldWdgt` |
| drag the folder out onto the desktop | on the world tree directly, still `populated:false`, 0 children |
| +5 s | unchanged; `examples-icons` never fetched; 0 console errors |

**Every add-to-tree path for a resting widget, enumerated:** (a) `bringUpTarget` → `spawnNextTo` —
the ritual, HONOURS the protocol; (b) **the hand, grabbing a resident out of the open bin view — the
reachable bypass, and note the folder is already painted-empty in the bin BEFORE the grab**; (c) the
shelf — unreachable, no view, `world.shelfWdgt` is never added to a parent; (d)
`IconicDesktopSystemWindowedApp._launchNow`'s `world.add figure`, reviving a stored app singleton —
a genuine second bypass, but no app window is lazily populated today; (e) `TemplatesButtonWdgt`
reviving `world.simpleEditorTemplates` — same shape, same non-issue today; (f) snapshot restore —
consistent by construction, since `populated` is serialized.

⇒ REACHABLE. ⚠ And because the folder is painted-empty *in the bin* before any drag, **§4.C is not
just awkward but insufficient** — the onset is "the bin is opened", not "the drag completes".

### §6.2 If nothing is reachable → §4.A, then stop
Correct the comment; add a line to `docs/BACKLOG.md`; archive this plan with the spike's evidence.

### §6.3 If something is reachable → implement §4.B or §4.C
Whichever the spike's shape indicates. Keep the already-populated path inline (§5).

### §6.4 Extend the probe into a gate
Whatever the fix, `Fizzygum-tests/scripts/parts-lazy-icons-headless.js` (`fg lazyprobe`, also the
gauntlet's `parts` leg) is where a permanent check belongs — it already asserts the folder is empty at
boot and fills on open. Add the newly-covered path there so it cannot regress.

### §6.5 Docs
`build-and-packaging.md` §2's "KNOWN LIMIT" paragraph and the `bringUpTarget` comment must end up
saying the same, true thing. Then archive this plan per `docs/README.md` (`git mv` to `archive/`,
status stamp, `archive/INDEX.md` line, BACKLOG updated).

---

## §7 Verification protocol

| # | command | must say |
|---|---|---|
| 1 | `fg build` | `BUILD EXIT=0 OK` |
| 2 | `fg gauntlet` | 14/14 |
| 3 | `git -C …/Fizzygum-tests status --short` | only references a change PREDICTED in advance; anything else is a finding. ⚠ Recapture is a consequence, never a constraint — decide the design on merits and recapture what moves |
| 4 | `fg lazyprobe` | `LAZY ICONS OK` |
| 5 | `fg homepage` · `./build_and_smoke.sh --profile lean` | both OK — ⚠ `lean` ships no `examples-icons`, so the folder must still OPEN there (empty), never reject |
| 6 | manual, on `index.html` | the reachable path from §6.1 now fills the folder |

---

## §8 Rejected alternatives — do not re-attempt

- **⛔ Populate in `_reactToBeingAdded`.** Inside the add's settle (§1.4).
- **⛔ Populate the folder eagerly at boot and defer only the C↔F art.** This is the tempting
  simplification and it removes the whole middle tier. It cannot work as stated: the opener for the
  C↔F door needs *an icon widget* at construction time, and its art is the lazy part. A placeholder
  would change what the user sees. The tier exists precisely because the art must be present before
  the icon is built.
- **⛔ Derive `populated` from "is the folder empty?"** Already rejected in the class comment: a user
  who empties the folder means it.
- **⛔ A new general lifecycle hook ("first paint") in `Widget`.** Disproportionate to a ~9.4 KB prize
  (§3.4). If the fix seems to need one, the answer is probably §4.A or §4.C.

---

## §9 References

- `src/ExamplesFolderWindowWdgt.coffee` — the protocol, the three tiers, why the builds sit inside
  the awaited scope.
- `src/IconicDesktopSystemShortcutWdgt.coffee` — `bringUpTarget`, the sole caller, and the KNOWN LIMIT
  comment this plan is auditing.
- `src/ShelfWdgt.coffee` / `src/BinWdgt.coffee` — shelf = no view, bin = a real view. The distinction
  §0.2 turns on.
- `src/basic-widgets/Widget.coffee` — `_reactToBeingAdded` and its invocation inside `_addNoSettle`.
- `src/WorldWdgt.coffee` — `doOneCycle` ordering; `_runChildrensStepFunction` as the settle-safe seam.
- `docs/architecture/build-and-packaging.md` §2 — the boot/open/click tiers, `isAvailable` vs
  `whenAllLoaded`, and why an already-loaded await must stay synchronous.
- `Fizzygum-tests/DETERMINISM.md` — why that last point is correctness, not economy.

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

The closed items this plan owned, relocated VERBATIM from `docs/BACKLOG.md` on 2026-08-18 so
that file can go back to being an index of OPEN work only (`docs/README.md` filing rule 2: an
arc's items leave BACKLOG when it closes). Nothing above this line changed; any item of this
arc still OPEN stayed in `docs/BACKLOG.md`.

### ~~`plans/folder-population-entry-points-plan.md`~~ → `archive/`
- [x] **A lazily-populated folder no longer depends on WHICH ritual showed it.** DONE 2026-08-02. `ExamplesFolderWindowWdgt` registers in `world.steppingWdgts` while it still owes itself content and populates from `step` the first time `@root() == world`, unregistering on that one shot; `whenReadyToBeBroughtUp` (awaited by the shortcut click, so that path still never flashes an empty folder) is unchanged. ⚠⚠ The §6.1 spike found the documented KNOWN LIMIT unreachable *as written* — `world.shelfWdgt` is never added to a parent, so nothing can be dragged out of the shelf — and the route that IS reachable, the BIN, was worse than the comment claimed: delete the folder's shortcut → the storage sorter drains it to the bin → opening the bin paints it EMPTY, with no shortcut left to ever fill it. Driven end to end on `index.html` with a real synthesised drag before any code was written. ⚖ The spike also moved the fix off §4.C: the folder is painted-empty *inside the bin window* before any drag, so hooking the bin's revival path would have been insufficient, not merely awkward. ⚖ Both of the plan's feared costs shrank — stepping is opt-IN, so the per-cycle cost ends at the first fill, and `_playQueuedEvents` runs earlier in the same cycle as the step seam, so an already-fetched part fills the folder before that cycle's paint. Gate: six new assertions in `scripts/parts-lazy-icons-headless.js` (`fg lazyprobe`, gauntlet `parts` leg), proven non-vacuous against a runtime-neutered build.
