# The shared base layer — getting the last movable classes out of core

> **STATUS: COMPLETE — executed 2026-08-02, in full, as written.** The nine classes are the new LAZY
> `app-kit` part (`src/app-kit/`); ten parts declare `requires: ["app-kit"]`; `dev-tools`'
> `WidgetFactory.createNewSpeechBubbleWdgt` awaits rather than guards (see the deviation below).
> `fg whatpins` went **11 movable → 2**, and *reached from boot stayed at 202* — the invariant §7
> names as the real one. Gauntlet 14/14, `fg lazyprobe` 14/14 icons, `fg homepage` green (it asserts
> `app-kit` absent at boot, all 9 classes arriving on demand, and **0 eager batches dragged in**),
> lean smoke `BOOT OK` and unchanged at 3 desktop children. **Reference churn: ZERO**, as §5.4
> predicted. Durable residue: `docs/architecture/build-and-packaging.md` §2 (the shared-base-layer
> paragraph and the "who names it most is not who owns it" rule) and §5 (the measurement row + the
> `CanvasWdgt`/`PatchNodeWdgt` decision).
>
> **ONE DEVIATION, deliberate.** §4.3 prescribed a *guard* at `WidgetFactory.coffee:83` and told the
> executor to read the method first. Reading it made the guard wrong: `app-kit` is LAZY, and this
> file's own two siblings (`createNewAnimationDemo`, `createNewPenWdgt`) already await
> `whenAllLoaded ["demos"]` for exactly this shape. A guard answers "is it here?" when the question
> is "get it here", so it would have silently swallowed the menu click — the failure mode
> `build-and-packaging.md` §2 names explicitly. The site awaits `whenAllLoaded ["app-kit"]`.
>
> **ONE FINDING, FIXED IN THE SAME ARC (owner-approved):** `check-part-edges.js` applied
> `declaredRequires` to EVERY part and tested it *before* the inheritance check, so an EAGER part's
> `requires` excused both its references and its `extends`/`@augmentWith` edges — which its own header
> says it must not, and which is the exact failure §5.1 leans on it to catch. The fix keeps the real
> distinction: `requires` always promises the other part SHIPS, but promises it has ARRIVED only when
> the OWNER is lazy, so an eager owner's LAZY requirements are dropped and its EAGER ones kept.
> Proven in both directions by planting each shape in `dev-tools`.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.** Everything
needed is embedded here or one named-doc hop away. **Line numbers WILL drift — the quoted symbol,
filename or code fragment is authoritative; re-grep before editing.** Every fact below was verified
against the tree at commit `7f5830ef` (2026-08-02).

**MANDATE: move the classes out of core.** Not "evaluate whether to"; the goal is that production's
`js/pre-compiled.js` stops carrying classes no boot path reaches. Where a class genuinely cannot
move, the plan says so **with the evidence that makes it a decision rather than a gap** — but the
default is: it moves.

⚠⚠ **RECAPTURE IS A CONSEQUENCE, NEVER A CONSTRAINT.** Decide on merits — clean code, honest
layering — then recapture whatever moves. Do not shape a part boundary, keep a class in core, or
preserve a string because changing it would churn a reference image. The useful distinction is
**PREDICTED vs UNPREDICTED** churn: predicted is a recapture, unpredicted is a finding.

---

## §0 Orientation

### What Fizzygum is (30 seconds)

A CoffeeScript GUI framework — a "web operating system" on one HTML5 canvas. ~470 classes, **no
module system**: every class is a global, shipped as escaped source text and compiled in the browser.
One class per file, filename == class name. `nil` means `undefined`. Workspace `Fizzygum-all/` holds
three sibling repos: source `Fizzygum/`, tests `Fizzygum-tests/`, output `Fizzygum-builds/`.

### The mechanism this plan operates on

`buildSystem/parts.json` divides the shipped source into named **parts**; a **profile**
(`buildSystem/profiles/<name>.json`) says which ship. A part is `eager` (in the boot image) or
**lazy** (`"eager": false` — absent from `js/pre-compiled.js`, fetched on demand). Production
(`homepage`) ships `core` plus eleven parts, **all lazy**, so production's eager image IS core.
⇒ **Getting a class out of `core` is exactly what takes it off the production boot image.**
Authoritative reference: `docs/architecture/build-and-packaging.md`, especially §2.

Three rules from that doc that this plan turns on:

1. **A part owns DIRECTORIES, not files** (`dirs`), and a `.coffee` under `src/` that no part claims
   fails the build (`check-shippable-coverage.js`). ⇒ moving a class between parts means **physically
   moving the file**.
2. **`requires` is the ONLY thing that makes cross-part inheritance safe.** For a lazy part,
   `PartsRegistry.ensureLoaded` loads its requirements *fully first*. A per-site await is not enough
   for a base class: `whenAllLoaded [...]` is a `Promise.all`, so the parts arrive concurrently with
   nothing ordering them.
3. ⚠⚠ **`requires` does NOT excuse an EAGER part.** An eager part is running from the first frame, so
   the declaration can only promise the other part *ships*, never that it *arrived*. An eager part
   therefore **cannot extend a lazy part's class at all** — the base must exist at boot.
   `check-part-edges.js` enforces the asymmetry.

### Where this comes from

The **boot-cost arc** (`docs/archive/`… see §9) took production's image from 936,920 to 682,031 bytes.
Its analyser, `buildSystem/what-pins-core.js` (`fg whatpins`), walks out from `src/boot` and reports
what no boot path reaches. Current answer: **11 classes, 14.1 KB of code**, still in core, that
nothing at boot reaches.

### ⚠⚠ THE CRITICAL REFRAME — why these looked immovable, and why they are not

`fg whatpins` proposes `authoring` as the home for all 11, because `authoring` is the part that names
them most. Priced that way every one of them is a bad trade: `plots` would have to declare
`requires: ["authoring"]`, and since `requires` *orders* a lazy load, **opening a chart would first
download and compile the whole Makers part — 225.5 KB of source it does not use.** 6.7 KB off the
image for a recurring toll on a user click. That is where the previous verdict, "movable but none are
free", came from.

**That verdict is wrong, and the mistake is the assumed home.** These classes are not `authoring`'s.
Measured with `fg hypopart`, the 11 carry **52 inheritance edges** from **13 different parts**:

| base class | parts that DERIVE from it |
|---|---|
| `IconicDesktopSystemWindowedApp` | authoring · fizzytiles · example-dashboard · example-degrees-converter · example-doc · example-sheet · example-slide |
| `CreatorButtonWdgt` | authoring · maps · plots |
| `ToolbarWdgt` | authoring · plots |
| `ToolbarCreatorButtonWdgt` | authoring · plots |
| `ParentStainerMixin` | authoring |
| `CanvasWdgt` | authoring · fizzytiles · **video-player (EAGER)** |
| `PatchNodeWdgt` | authoring · **patch-programming-experimental (EAGER)** |

⇒ **They are a shared BASE LAYER that many lazy parts build on.** The right home is therefore not one
consumer, it is **a part of their own** that the consumers `require`. That single change converts the
toll from `authoring`'s 225.5 KB to the new part's ~24 KB — and the objection evaporates. Nine of the
eleven then move with no runtime cost worth naming and exactly **one** guard to add.

The remaining two are blocked by rule 3 above, not by cost, and §5.3 states what it would actually
take to unblock them.

---

## §0.5 Cold-execution protocol

1. **Orient.** `/Users/davidedellacasa/code/Fizzygum-all/fg status` — expect `Fizzygum` and
   `Fizzygum-tests` clean, ahead 0. Read `docs/architecture/build-and-packaging.md` §2 (the `requires`
   rules and the eager/lazy asymmetry). Then run `fg whatpins --list` and confirm §1's table still
   matches; if it has drifted, fix this plan first.
2. **Execute §6 in order**, `fg build` after each step (~15 s, catches a partition error immediately).
3. **Gate with §7.**
4. **Do not commit or push without the owner's approval** — present a summary + proposed message and
   wait. `git commit -F <file>`, never `-m`.

**Working rules:** long ops in the background, wait for the notification (no foreground poll loops —
a guard hook blocks them). **Never edit `src/` or `tests/` while a gauntlet or suite runs** — it trips
the stale-build guard and wastes the run. Absolute paths. **Never `git stash` in this repo.**

---

## §1 Exact current state

`fg whatpins --list`, profile `homepage`: **213 classes in the eager image; 202 reached from boot;
11 NOT reached (14.1 KB code).** The eleven, with what names them:

| # | class | file | KB code | named by |
|---|---|---|---:|---|
| 1 | `GlassBoxTopWdgt` | `src/GlassBoxTopWdgt.coffee` | 2.0* | authoring, demos, plots |
| 2 | `ToolPanelWdgt` | `src/ToolPanelWdgt.coffee` | 2.0* | authoring, demos, plots |
| 3 | `CanvasWdgt` | `src/basic-widgets/CanvasWdgt.coffee` | 2.3 | authoring, dev-tools, fizzytiles, video-player |
| 4 | `PatchNodeWdgt` | `src/patch-programming/PatchNodeWdgt.coffee` | 2.0 | authoring, patch-programming-experimental |
| 5 | `SpeechBubbleWdgt` | `src/SpeechBubbleWdgt.coffee` | 1.8 | authoring, dev-tools, example-dashboard |
| 6 | `IconicDesktopSystemWindowedApp` | `src/IconicDesktopSystemWindowedApp.coffee` | 1.3 | authoring, fizzytiles, all five `example-*` |
| 7 | `ToolbarCreatorButtonWdgt` | `src/buttons/ToolbarCreatorButtonWdgt.coffee` | 0.6* | authoring, plots |
| 8 | `ToolbarWdgt` | `src/toolbars/ToolbarWdgt.coffee` | 0.6* | authoring, plots |
| 9 | `CreatorButtonWdgt` | `src/buttons/CreatorButtonWdgt.coffee` | 0.4* | authoring, maps, plots |
| 10 | `ParentStainerMixin` | `src/mixins/ParentStainerMixin.coffee` | 0.4* | authoring |
| 11 | `WidgetCreatorAndSmartPlacerOnClickMixin` | `src/mixins/WidgetCreatorAndSmartPlacerOnClickMixin.coffee` | 0.7 | authoring, demos, maps, plots |

\* the tool reports these in pairs; the per-class split is approximate. The total is authoritative: 14.1 KB.

### §1.1 The only EAGER edges — this is the whole difficulty

Everything else is lazy→lazy, which `requires` handles. Exactly three sites involve an eager part:

| site | kind | consequence |
|---|---|---|
| `src/video-player/VideoPlayerCanvasWdgt.coffee:14` — `extends CanvasWdgt` | **INHERITANCE** | ⛔ blocks `CanvasWdgt` |
| `src/video-player/SimpleImageWdgt.coffee:26` — `extends CanvasWdgt` | **INHERITANCE** | ⛔ blocks `CanvasWdgt` |
| `src/patch-programming-experimental/DiffingPatchNodeWdgt.coffee:1` and `RegexSubstitutionPatchNodeWdgt.coffee:1` — `extends PatchNodeWdgt` | **INHERITANCE** | ⛔ blocks `PatchNodeWdgt` |
| `src/dev-tools/WidgetFactory.coffee:83` — `new SpeechBubbleWdgt` | reference | ✅ guardable, one line |

An eager part cannot extend a lazy part's class (§0 rule 3), so items 3 and 4 of §1 cannot move while
`video-player` and `patch-programming-experimental` are eager. The `dev-tools` one is a *reference*,
which a guard fixes where it stands.

### §1.2 Directory facts that shape the move

Parts own directories, so the movers must land in a new directory. Current homes:

- `src/toolbars/` contains **only** `ToolbarWdgt.coffee` → emptied by this move; its entry must come
  out of `core`'s `dirs` in `parts.json`.
- `src/buttons/` has 7 files; 2 move, 5 stay → `src/buttons` stays a core directory.
- `src/mixins/` has 8 files; 2 move, 6 stay → stays core.
- `src/patch-programming/` contains **only** `PatchNodeWdgt.coffee` (its sibling moved to `authoring`
  in `7f5830ef`) → relevant only if §5.3 is ever executed.

---

## §2 Why it is shaped this way

Not an oversight — sequencing. Core was originally everything; parts were carved out one app-slice at
a time (`maps`, `plots`, `spreadsheet`, `authoring`, the five `example-*` doors). Each slice moved the
classes that were *only* that slice's. A class that **two or more** slices derive from could not go
into either without an unordered cross-part edge, so it stayed in core by default — correctly, at the
time, because `parts.json` had no `requires` mechanism at all until arc 4.

`requires` exists now. What is left in core is therefore not "core material"; it is **the residue of a
partition that only ever had one direction to move things in**. The shared base layer was never given
a home because there was nowhere to put it.

---

## §3 The distilled argument

1. **The classes are a layer, not a leftover.** 52 inheritance edges from 13 parts is the definition
   of a shared base, and a shared base with no part of its own is a partition that is missing a piece.
2. **A part of their own makes the cost trivial.** The blocking objection was `plots requires
   authoring` = 225.5 KB at a chart click. `plots requires <the new part>` is ~24 KB of source, and
   `plots` derives from three of its classes, so it is not incidental weight — it is what `plots` is
   built from.
3. **`requires` is the mechanism this is for.** The doc calls it "the only thing that makes cross-part
   inheritance safe". This plan is the first configuration where that sentence is load-bearing across
   many parts at once.
4. **The eager blockers are a different problem, and small.** Two classes, both blocked by *inheritance
   from an eager part*. §5.3 prices unblocking them and recommends against it for now, with evidence.
5. **Why now:** the boot-cost arc is closed and pushed, the analyser exists and is selftested, and this
   is the last thing it reports. Doing it converts an open "movable but not free" item into either a
   move or a recorded decision.

---

## §4 Fix shape

### §4.1 One new lazy part

Add to `buildSystem/parts.json`:

```json
"app-kit": {
  "//": "The shared BASE LAYER: the classes two or more lazy parts DERIVE from …",
  "eager": false,
  "dirs": ["src/app-kit"]
}
```

⚠ **The name is the owner's to change** — `app-kit`, `desktop-kit` and `authoring-kit` were all
considered. What matters is that it reads as *a layer many parts build on*, not as one app's private
drawer, because `plots requires <name>` has to look sensible to the next reader.

Nine files move into `src/app-kit/`:

`IconicDesktopSystemWindowedApp` · `ToolbarWdgt` · `ToolbarCreatorButtonWdgt` · `CreatorButtonWdgt` ·
`ToolPanelWdgt` · `GlassBoxTopWdgt` · `SpeechBubbleWdgt` · `ParentStainerMixin` ·
`WidgetCreatorAndSmartPlacerOnClickMixin`

### §4.2 The `requires` edges

Every lazy part that derives from or references a class in `app-kit` declares it. From §0's table plus
the reference edges:

| part | why |
|---|---|
| `authoring` | derives from 6 of the 9 |
| `plots` | derives from `ToolbarWdgt`, `ToolbarCreatorButtonWdgt`, `CreatorButtonWdgt` |
| `maps` | derives from `CreatorButtonWdgt` |
| `fizzytiles` | derives from `IconicDesktopSystemWindowedApp` |
| `demos` | references `ToolPanelWdgt`, `WidgetCreatorAndSmartPlacerOnClickMixin` |
| `example-degrees-converter`, `example-doc`, `example-slide`, `example-dashboard`, `example-sheet` | each app class **extends** `IconicDesktopSystemWindowedApp` |

⚠⚠ **Adding `requires` to the five `example-*` parts does NOT reverse the ⛔ recorded in each of
them.** That prohibition — *"NO parts.json `requires` here, deliberately … it would drag the app in
behind the door instead of behind the click"* — is about naming the **app's own parts** (`authoring`,
`maps`, `plots`), which the class already awaits at click time through `requiredParts`. This is the
opposite case: the door's class **extends** a class in `app-kit`, so `app-kit` must be ingested
*before* the door can be defined at all, and `requires` is the only construct that orders that. Update
each part's `//eager` note to say so, or the next reader will think the rule was quietly dropped.

### §4.3 The one guard

`src/dev-tools/WidgetFactory.coffee:83` — `newWdgt = new SpeechBubbleWdgt`. `dev-tools` is EAGER, so
it needs a guard where it stands, not a `requires`:

```coffee
newWdgt = new SpeechBubbleWdgt  if SpeechBubbleWdgt?
```

⚠ Check what the surrounding method does with `newWdgt` — a guard that leaves it `nil` may need the
enclosing branch skipped instead. Read the method before editing; do not paste the line above blindly.

### §4.4 What stays, and why (see §5.3 for the full pricing)

`CanvasWdgt` and `PatchNodeWdgt` stay in `core`. Record the reason in `parts.json` or in
`build-and-packaging.md` §5 so it is a decision on the record, not an unexplained residue.

---

## §5 Central risks

### §5.1 An eager part must never end up extending an `app-kit` class

This is the failure this plan is closest to. `check-part-edges.js` catches it, and it is a HARD fail
with a clear message — but understand it before you see it: the fix is never "add a `requires`", it is
either "the class stays in core" or "that part becomes lazy". The eager parts today are `dev-tools`,
`dev-icons`, `macros`, `harness`, `patch-programming-experimental`, `video-player`.

### §5.2 `lean` loses the app protocol

`lean` ships `core` only, so after the move it has no `IconicDesktopSystemWindowedApp`. That is
correct — `lean` ships no app parts either, and `createDesktop` already asks
`world.parts.canEverProvideClass` before drawing any icon, so it draws none. **Verify rather than
assume:** the lean smoke (§7) boots it and fails on any console error.

### §5.3 The two that stay — what unblocking them would actually cost

**`PatchNodeWdgt`** needs `patch-programming-experimental` to become lazy. That part is **entangled
with core**: `FanoutWdgt` is named by `src/ScriptWdgt.coffee`, `src/CodePromptWdgt.coffee` and
`src/ToolPanelWdgt.coffee`, and `FanoutPinWdgt` by `src/mixins/ControllerMixin.coffee` — the dataflow
wiring substrate. Those core sites are guarded today, which is right for an *absent* part and **wrong
for a lazy one** (a guard silently swallows the click instead of fetching), so each would have to
become an await — and `ControllerMixin.ensureWireEdge` is exactly the kind of site that has no async
seam. That is the same reasoning that keeps `src/dataflow/` out of the partition
(`build-and-packaging.md`, "What is deliberately NOT a part"). ⇒ **Not worth 2.0 KB.** Do not start it
without deciding that question first, on its own merits.

**`CanvasWdgt`** needs `video-player` to become lazy. `video-player` is auto-launched **at boot**:
`src/WorldWdgt.coffee:648`, `if window.VideoPlayerWithRecommendationsWdgt? then
world.draftRunVideoPlayer()`. A part that runs at boot is eager by definition, so this is not a
packaging change but a product one (should a flag-gated draft feature auto-launch at all?).
⚠ Independently: `CanvasWdgt` lives in `src/basic-widgets/` and is the base for three different
parts' canvas widgets. **It is defensible core material on layering merits alone**, regardless of the
blocker — "no boot path reaches it" is not the same as "it does not belong in core". ⇒ **Leave it, and
say so.**

### §5.4 Recapture

A file changing parts should move no pixels — nothing about a class's members or rendering changes.
**Predict none.** If the gauntlet reports a diff, that is a FINDING: understand it before recapturing,
because the plausible causes (a class failing to load, a guard skipping a branch) are all real bugs.
If it turns out benign, recapture with `fg recapture --auto` and move on — churn does not constrain
the design.

### §5.5 Measure, do not estimate

Nine classes / ~24 KB source / 9.8 KB code. ⚠ The image tracks **class count** at least as much as
bytes, and this estimator has missed in both directions five times running. State a predicted delta in
words before building, then `fg fingerprint homepage 7f5830ef`, and treat any unpredicted file as a
finding.

---

## §6 Execution steps

1. **`mkdir src/app-kit`**, then `git mv` the nine files of §4.1 into it.
2. **`parts.json`**: add the `app-kit` part (§4.1); remove `"src/toolbars"` from `core`'s `dirs` (it is
   now empty — §1.2); add `requires` to the ten parts in §4.2. ⚠ `requires` is a *list*; several of
   those parts already have one (`demos` has five entries) — add to it, do not replace it.
3. **Profiles**: `homepage.json` must name `app-kit` (production ships every part that derives from
   it). `dev`/`dev-notests` use `"parts": "all"` and pick it up automatically. `lean` must NOT name it
   (§5.2). ⚠ `buildProfile.py` fails a profile that ships a part without what it requires, so a missed
   profile is a loud build failure, not a silent one.
4. **The guard** at `src/dev-tools/WidgetFactory.coffee:83` (§4.3).
5. **`fg build`.** Expect `check-part-edges` and `check-shippable-coverage` to be the ones that speak
   if anything is wrong. Iterate until clean.
6. **Update the `//eager` note in each of the five `example-*` parts** to explain why a `requires` on
   `app-kit` is consistent with their standing ⛔ (§4.2). This is not optional: without it the next
   reader sees a contradiction.
7. **Docs**: `build-and-packaging.md` §2 (a new paragraph on the shared base layer and why `requires`
   is forced for it) and §5 (a measurement row); the partition figure and legend in
   `docs/explainers/build-and-packaging.html` (it draws every part to scale — a new part means a new
   bar segment and a legend entry); `docs/BACKLOG.md`; close this plan out to `archive/` with a status
   stamp and an `archive/INDEX.md` line, per `docs/README.md`.
8. **Record the §5.3 decision** for `CanvasWdgt` and `PatchNodeWdgt` where a future reader will hit it:
   `build-and-packaging.md` §5, next to the FIXPOINT note.

---

## §7 Verification protocol

Run from anywhere; `fg` is path-correct. Long ones in the background — wait for the notification.

| # | command | must say |
|---|---|---|
| 1 | `fg build` | `BUILD EXIT=0 OK`; `check-part-edges` 0 unguarded / 0 inheritance |
| 2 | `fg whatpins` | the 11 are now **2** (`CanvasWdgt`, `PatchNodeWdgt`), and "reached from boot" is UNCHANGED at 202 — that second number is the real invariant: it says nothing came loose that should not have |
| 3 | `fg gauntlet` | 14/14 |
| 4 | `git -C …/Fizzygum-tests status --short` | predicted: EMPTY. Non-empty ⇒ read §5.4 before touching anything |
| 5 | `fg lazyprobe` | `LAZY ICONS OK`, all 14 icons — ⚠ this is the one that exercises `IconicDesktopSystemWindowedApp` arriving from a lazy part on a click |
| 6 | `fg homepage` | `EXIT=0 OK` — it also loads a lazy part and asserts zero eager batches came with it |
| 7 | `./build_and_smoke.sh --profile lean` | `BOOT OK` (§5.2) |
| 8 | `fg fingerprint homepage 7f5830ef` | only predicted files differ (§5.5) |

⚠ `fg fingerprint` leaves the tree on the fingerprinted profile — run `fg build` afterwards.

**One manual check no gate covers:** open `Fizzygum-builds/latest/index.html`, click a desktop Maker
icon and an Examples door, and confirm both windows open. `fg lazyprobe` does this headlessly, but
`IconicDesktopSystemWindowedApp` moving into a lazy part is precisely the change that would break a
door, so it is worth seeing once.

---

## §8 Rejected alternatives — do not re-attempt

- **⛔ Move all 11 into `authoring`.** What `fg whatpins` proposes, and what makes them look
  unaffordable. `plots`/`maps` would each declare `requires: ["authoring"]`, so opening a chart or a
  map first fetches 225.5 KB of Makers. It also asserts something false about the layering: these are
  not `authoring`'s classes, they are the layer `authoring` itself derives from.
- **⛔ Leave them in core because "none are free".** The earlier verdict, and it was reached by pricing
  only one candidate home. Recorded so the reasoning is visible rather than repeated.
- **⛔ Use `requiredParts` (the per-class declaration) instead of `parts.json requires` for the doors.**
  It satisfies `check-part-edges`, so it *looks* sufficient — and it is wrong here: `requiredParts` is
  awaited inside `launch`, long after the class had to be DEFINED. A base class must be ingested
  before the deriving class exists at all, and only `requires` orders that.
- **⛔ Make `patch-programming-experimental` or `video-player` lazy to unblock the last two.** Priced
  in §5.3: the first needs core guards converted to awaits at a site with no async seam
  (`ControllerMixin`), the second is a product decision about a boot-time auto-launch. 4.3 KB is not
  the reason to do either.
- **⛔ One part per base class.** The manifest cost is per class NAME rather than per part, so it is
  not expensive — but it produces nine parts whose members are always wanted together, and every
  consumer would name several. The loading unit should match what is used as a unit.

---

## §9 References

- `docs/architecture/build-and-packaging.md` — §2 (parts, `requires`, the eager/lazy asymmetry, "an
  icon is not its app"), §5 (the slice measurements, the FIXPOINT note, what is deliberately NOT a
  part). Authoritative and present-tense.
- `docs/explainers/build-and-packaging.html` / `boot-and-lazy-parts.html` — the same, illustrated.
- `buildSystem/what-pins-core.js` (`fg whatpins`) — what no boot path reaches, plus the SOLE ROUTES
  ranking. `--selftest` is 11 assertions on planted input. ⚠ Its "→ 'authoring' iff …" advice names the
  cheapest EXISTING home; it does not consider inventing a part, which is what this plan does.
- `buildSystem/hypothetical-part.js` (`fg hypopart <paths…>`) — inheritance edges and cross-part
  callers for a proposed grouping, using the build gate's own classifier. This plan's §0 and §1 tables
  came from it; re-run it if anything looks stale.
- `docs/archive/app-descriptor-unification-plan.md` — the immediately prior arc (`7f5830ef`), which
  moved `IconicDesktopSystemWindowedApp`'s identity fields into `AppCatalog`. Relevant because that
  class is item 6 here.
- **Owner standing rule — "don't let recapture churn dictate design."** Pick the right boundary, then
  recapture what moves.
