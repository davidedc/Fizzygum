# One descriptor per app — killing the duplicated launcher identity

> ## ✅ COMPLETE — executed 2026-08-02, same day it was authored.
> `src/AppCatalog.coffee` holds one entry per app, keyed by class NAME; both launcher modes read it
> through the single `IconicDesktopSystemWindowedAppLauncherWdgt._fromCatalogEntry`. `title` /
> `buildIcon` / `toolTip` are gone from all 14 app classes and from the base. **The §1.4 bug is
> fixed**: the "Super Toolbar" and "Fizzytiles" desktop icons have their bubble help back (probed
> directly on `index.html`, since no gate covers tooltips).
>
> **§5.1 was decided as the plan recommends — one name per app, no label override.** The four
> Examples doors' captions are now the app names: "Slide", "Dashboard", "Document", and
> "C-F converter" for the C↔F door. ⚠ The shipping product's appearance is UNCHANGED — those five
> launchers only ever appear inside the Examples folder, which already used these strings.
>
> **Churn: exactly as PREDICTED — one test.** `SystemTest_macroDesktopShortcutIcons` draws
> `createOpener` captions on the desktop, so "Sample slide"/"Sample dashboard"/"Sample doc" became
> "Slide"/"Dashboard"/"Document" (and "Dashboard" stopped wrapping to two lines). Recaptured with
> `fg recapture`, `✅ RECAPTURE COMPLETE` at dpr 1 and 2. Nothing else moved.
> ⚠ Note for the next recapture: the new files carry a different `systemInfoHash` (1747348995 vs
> 1315295150) because they were captured on a different DISPLAY (1512×982/30-bit vs 2560×1440/24-bit)
> — the browser was identical. That is **cosmetic**: the hash is metadata and matching is purely the
> pixel `dataHash` (`scripts/capture-macro-test-references.js` header).
>
> **Two execution findings the plan did not predict, both meta-system constraints** (§6 step 1 now
> carries them as comments in `AppCatalog`): a class-level object field must be a **method**, and
> each entry must be **one line**. `src/meta/Class.coffee` splits a class body with
> `/^  (@?ident) *: *(.*)/` and compiles each member's body ALONE, so a value starting on the next
> line, or an entry wrapped onto a second line, fails as "unexpected indentation" — and ONLY under
> the fragmented compile the browser uses, so `coffee -c` on the file passes and the build gate is
> what catches it.
>
> Gates: `fg build` OK · `fg gauntlet` **14/14** (258s, incl. webkit) · `fg lazyprobe` OK ·
> `fg homepage` OK · lean smoke OK. See the bottom of §7 for what each proved.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.** Everything
needed is embedded here or one named-doc hop away. **Line numbers WILL drift — the quoted symbol,
method name or code fragment is authoritative; re-grep before editing.** All facts below were
verified against the tree at commit `dae866f9` (2026-08-02).

**MANDATE: eliminate the duplication, not manage it.** The end state is that "SimpleDocumentApp is
called 'Docs Maker' and draws a Typewriter icon" is written **once**, in one place, and both launcher
modes read it. A plan that leaves the two statements in place and merely documents that they must
agree has failed.

⚠⚠ **RECAPTURE IS A CONSEQUENCE, NEVER A CONSTRAINT.** Decide the design on merits — clean code and
good architecture — and then recapture whatever screenshots the right design moves. Do NOT shape an
API, keep a redundant field, or preserve a string because changing it would churn a reference image.
This plan was drafted once with "zero reference churn" as a target and that was **wrong**; it had
already bent one design decision (§5.1) before the error was caught. The useful distinction is not
churn-vs-no-churn but **PREDICTED vs UNPREDICTED**: churn you called in advance is a recapture, churn
you did not is a finding to investigate. See the owner-standing rule in §9.

---

## §0 Orientation

### What Fizzygum is (30 seconds)

A CoffeeScript GUI framework — a "web operating system" rendered on one HTML5 canvas. ~470 classes,
**no module system**: every class is a global, shipped as escaped source text and compiled in the
browser. One class per file, filename == class name. `nil` means `undefined`. To reference another
class you just name it. Root workspace `Fizzygum-all/` holds three sibling repos; source is
`Fizzygum/`, tests are `Fizzygum-tests/`, build output is `Fizzygum-builds/`.

### The arc that created this problem, and its one big idea

The **boot-cost arc** (closed 2026-08-02, `docs/plans/boot-cost-reduction-plan.md`) cut production's
`js/pre-compiled.js` from 936,920 to 682,031 bytes, −27.2%. Its central realisation:

> ⭐ **AN ICON IS NOT ITS APP.** `WorldWdgt.createDesktop` runs at boot and places every desktop and
> in-folder app icon. That *looked* like it forced every lazy app to keep a tiny EAGER part beside it,
> purely so `createDesktop` had a class to construct — and for a long time it did, in parts called
> `authoring-launcher`, `fizzytiles-launcher` and `spreadsheet-launcher`. But `createDesktop` only ever
> constructed the app **to ask it for a title and an icon**, and the art is core. So the launcher now
> holds the app's class **NAME** as a string and resolves it on the click. All three launcher parts
> were **deleted**. What forces eagerness is boot-time REACHABILITY, and *reading a name is not
> reaching a class.*

Present-tense reference: `docs/architecture/build-and-packaging.md` §2. Illustrated by
`docs/explainers/boot-and-lazy-parts.html` §3–4.

### ⚠⚠ THE CRITICAL REFRAME — read this before designing anything

The obvious reading of "give an app one descriptor" is **"put `title` and `icon` on the app class and
have `createDesktop` read them."** That is exactly backwards and would undo the entire arc above.

Reading a field off the app class means **touching the app class at boot**, which is precisely what
"an icon is not its app" removed. Do that and every app is eager again, the three launcher parts come
back, and ~254 KB returns to the production image.

⇒ **The descriptor MUST live in CORE, keyed by class NAME, never on the app class.** The app class is
the thing that must stay unreachable at boot. This inverts the intuition: the fix is not "move the
call site's data onto the app", it is **"move the app's data off the app"**.

### Why this plan exists now

The lazy mode was introduced call-site-first: `createDesktop` and `ExamplesFolderWindowWdgt` were
given literal titles and icon thunks, while the app classes kept the `title:` / `buildIcon:` /
`toolTip:` fields the *eager* mode still reads. Nobody removed either copy. The result is one rule in
two places — the shape `docs/archive/build-arc-4-dynamic-parts-plan.md` blames for **four bugs of one
kind**. It has already produced a fifth, which is currently shipping (§1.4).

---

## §0.5 Cold-execution protocol

1. **Orient (5 min).** Run `/Users/davidedellacasa/code/Fizzygum-all/fg status`. Expect both `Fizzygum`
   and `Fizzygum-tests` clean and `ahead 0`. Read `docs/architecture/build-and-packaging.md` §2 —
   specifically the "AN ICON IS NOT ITS APP" block. Do not skip it; §0's reframe depends on it.
2. **Re-verify §1 against the tree.** Every count and path in §1 is a claim. Re-grep them. If one has
   drifted, fix the plan first, then proceed.
3. **Execute §6 in order.** It is one coherent change; there is no useful half-way commit.
4. **Gate with §7.** `fg build` after each step, the full battery once at the end.
5. **Do not commit or push without the owner's approval.** Present a summary and the proposed message
   and wait. Use `git commit -F <file>`, never `-m` (backticks in a message corrupt it).

**Working rules that apply throughout:** long operations go in the background (`run_in_background`)
and you wait for the notification — no foreground `until … sleep` pollers, they are blocked by a guard
hook. **Never edit `src/` or `tests/` while a gauntlet or suite is running** — it trips the
stale-build guard and wastes the run. Use absolute paths. **Never `git stash` in this repo** (a
`stash pop` once silently emptied both the working tree and the stash list).

---

## §1 Exact current state

### §1.1 The two modes

Both build an `IconicDesktopSystemWindowedAppLauncherWdgt`. Its header comment already names the
concept this plan formalises — *"LAZY — built from a DESCRIPTOR: a title, an icon made of CORE art,
and the app's class NAME as a string."* Today that "descriptor" is three loose positional arguments,
not an object.

**LAZY** (`src/IconicDesktopSystemWindowedAppLauncherWdgt.coffee`) — the mode that builds **all 14
icons in the running system**:

```coffee
@addToFolder:  (folder, appClassName, title, buildIcon) -> …   # 5 icons, from ExamplesFolderWindowWdgt
@addToDesktop: (appClassName, title, buildIcon) -> …           # 9 icons, from WorldWdgt.createDesktop
@_lazyLauncherFor: (appClassName, title, buildIcon) ->
  return nil unless world.parts.canEverProvideClass appClassName
  launcher = new @ title, buildIcon(), nil, nil
  launcher.appClassName = appClassName
  launcher
```

⚠ `addToFolder` sizes **then** adds; `addToDesktop` adds **then** sizes. That is not interchangeable
and is not cosmetic — the desktop places by smart grid ON ADD, a folder's grid reads the extent as it
adds. Preserve both orders exactly.

**EAGER** (`src/IconicDesktopSystemWindowedApp.coffee:55-66`) — takes a live app instance:

```coffee
createOpener: (inWhichFolder) ->
  launcher = new IconicDesktopSystemWindowedAppLauncherWdgt @title, @buildIcon(), @, "launch"
  launcher.toolTipMessage = @toolTip if @toolTip?
  …
```

### §1.2 The duplication, exactly

14 apps, all of them either on the desktop (9) or in the Examples folder (5). For each, the caption
and the art are stated **twice** — once as fields on the app class, once as literals at the call site.

| app | class fields | `createDesktop` / folder call site |
|---|---|---|
| `HowToSaveMessageApp` | `"How to save?"` · `FloppyDiskIconWdgt` | identical |
| `SimpleDocumentApp` | `"Docs Maker"` · `TypewriterIconWdgt` | identical |
| `FizzyPaintApp` | `"Draw"` · `PaintBucketIconWdgt` | identical |
| `SimpleSlideApp` | `"Slides Maker"` · `SimpleSlideIconWdgt` | identical |
| `DashboardsApp` | `"Dashboards"` · `DashboardsIconWdgt` | identical |
| `PatchProgrammingApp` | `"Patch programming"` · `PatchProgrammingIconWdgt` | identical |
| `GenericPanelApp` | `"Generic panel"` · `GenericPanelIconWdgt` | identical |
| `ToolbarsApp` | `"Super Toolbar"` · `ToolbarsIconWdgt` | identical |
| `FridgeMagnetsApp` | `"Fizzytiles"` · `FridgeMagnetsIconWdgt` | identical |
| `DegreesConverterApp` | `"°C ↔ °F"` · `DegreesConverterIconWdgt` | icon identical, label **`"C-F converter"`** |
| `SampleSlideApp` | `"Sample slide"` · `GenericShortcutIconWdgt(SimpleSlideIconWdgt)` | icon identical, label **`"Slide"`** |
| `SampleDashboardApp` | `"Sample dashboard"` · `GenericShortcutIconWdgt(DashboardsIconWdgt)` | icon identical, label **`"Dashboard"`** |
| `SampleDocApp` | `"Sample doc"` · `GenericShortcutIconWdgt(TypewriterIconWdgt)` | icon identical, label **`"Document"`** |
| `SpreadsheetApp` | `"Spreadsheet"` · `GenericShortcutIconWdgt(TypewriterIconWdgt)` | identical |

⚠⚠ **The icon is duplicated in all 14 cases. The title is duplicated in 10 and DIFFERENT in 4.**
Whether those four differences are *information* or *drift* is the one real design question in this
plan, and §5.1 answers it: they are drift. Note the existing set is already internally inconsistent —
three Examples apps carry a `"Sample "` prefix and `SpreadsheetApp` does not.

### §1.3 Who reads the app-side fields — exactly one place

Verified by grep over all of `src/` and `Fizzygum-tests/`:

- `@title`, `@toolTip`, `@buildIcon()` on an app are read **only** at
  `IconicDesktopSystemWindowedApp.coffee:56-57`, inside `createOpener`.
- `createOpener` has **7 call sites, in 2 files**:
  - `src/demos/DemoMenus.coffee` (~line 559-561, in `popUpShortcutsAndScriptsMenu`) — three menu
    items: `(new FizzyPaintApp)`, `(new SimpleDocumentApp)`, `(new SimpleSlideApp)`, each
    `menu.addMenuItem "<label> launcher", <app>, "createOpener"`.
  - `Fizzygum-tests/tests/SystemTest_macroDesktopShortcutIcons/SystemTest_macroDesktopShortcutIcons_automationCommands.js`
    — four: `(new SampleSlideApp).createOpener()` and the same for `SampleDashboardApp`,
    `SampleDocApp`, `SpreadsheetApp`.

⇒ Deleting `title:` / `buildIcon:` / `toolTip:` from the app classes breaks nothing else.

### §1.4 ⚠⚠ THE BUG THIS HAS ALREADY CAUSED — currently shipping

`toolTip` is part of an app's identity and **the lazy path silently drops it**. `_lazyLauncherFor`
takes only `(appClassName, title, buildIcon)`; nothing sets `toolTipMessage`. Two apps define one, and
**both are desktop icons**, i.e. both are built by the lazy path today:

- `src/authoring/ToolbarsApp.coffee:27` — `toolTip: "a toolbar to rule them all"`
- `src/fizzytiles/FridgeMagnetsApp.coffee:15` — `toolTip: "fridge magnets"`

`toolTipMessage` drives `LabelButtonWdgt.coffee:145` `@startCountdownForBubbleHelp @toolTipMessage`,
so this is user-visible: hovering those two desktop icons used to show bubble help and now shows
nothing. **Zero SystemTests mention `toolTip`**, which is why nothing caught it.

This is the fifth instance of the "one rule in two places" failure and it is the plan's strongest
justification: the second copy did not drift, it was simply **incomplete**, and no gate can see that.

### §1.5 The one constraint that shapes the whole design

10 of the 11 icon classes named by the two call sites are CORE (`src/icons/`). **One is not:**

```
src/examples-icons/DegreesConverterIconWdgt.coffee   →  part `examples-icons`, LAZY
```

`ExamplesFolderWindowWdgt` may name it only because it builds its five openers **inside** a
`world.parts.whenAllLoaded [...], ->` scope. `buildSystem/check-part-edges.js` reads **one line at a
time**: a line in a core file saying `-> new DegreesConverterIconWdgt` is an unguarded core→lazy
reference and **fails the build**, no matter when the thunk is actually called.

⇒ A core catalog cannot hold that one icon thunk. §4 handles it with an explicit per-call-site
override, which is also what the four differing labels need anyway.

### §1.6 Idiom already available

`IconicDesktopSystemWindowedApp.coffee:24` already does `wellKnownKey: -> "app:" + @constructor.name`.
So `@constructor.name` is a working, in-use way for an app to name itself — `createOpener` can use it
to find its own catalog entry. No new mechanism needed.

`IconicDesktopSystemWindowedApp` is a **plain class, not a Widget** (`class IconicDesktopSystemWindowedApp`,
no `extends`). It is core; the app *subclasses* live in lazy parts.

---

## §2 Why it is shaped this way

Not carelessness — sequencing. Before the boot-cost arc, the ONLY mode was the eager one, and putting
`title`/`buildIcon`/`toolTip` on the app class was correct: `createDesktop` constructed each app
anyway, so the app was the natural home for its own identity.

The arc then removed the construction, and the identity had nowhere to go — it could not stay on the
app (unreachable at boot, §0) and no core home existed. The pragmatic move was to inline the literals
at the two call sites and leave the app-side fields for the eager mode. That was the right call for
shipping the arc; it left this behind.

The launcher's header comment still carries a **ghost reference** from that era: it says
`authoring-launcher and fizzytiles-launcher exist as eager slivers`, present tense. Those parts were
deleted. §6 step 6 fixes it.

---

## §3 The distilled argument

1. **The duplication is not stable.** It has already failed once, silently, in production (§1.4). The
   failure mode is not "the two copies disagree" (a reviewer might catch that) but "the second copy is
   missing a field the first one has", which is invisible to reading and to every gate.
2. **No gate can cover it.** `check-part-edges` reasons about parts, not about identity. The suite
   never asserts a tooltip. `fg lazyprobe` asserts icons are drawn and apps are not loaded, not that
   the icon is *correct*. There is nothing to add a check to — the fix has to be structural.
3. **The eager mode is worth keeping**, so "delete one side" is not available. Handing over a live app
   singleton is genuinely the right shape when you already hold one, which `DemoMenus` does.
4. **A core, name-keyed catalog is the only home that satisfies both.** It is reachable at boot
   (core), it does not touch the app class (name-keyed), and both modes can read it.
5. **Why now:** the arc is closed and pushed, the tree is clean, and the analyser
   (`fg whatpins`) confirms no further partition work is pending in this area. This is the
   residue, and it is small and well-bounded.

---

## §4 Fix shape

### §4.1 The catalog

New core class, one file, `src/AppCatalog.coffee`. Class-level members only — precedent:
`src/authoring/InfoDocs.coffee` is a plain `class InfoDocs` with only `@`-level methods.

```coffee
# The ONE statement of what an app is as a desktop citizen: its caption, its art, its hover text.
# ⚠⚠ KEYED BY CLASS NAME, NEVER BY CLASS OBJECT, and that is the whole point rather than a detail:
# an icon is drawn at BOOT for an app whose class has not been fetched, so anything here that
# *reached* the app class would make every app eager again and undo the boot-cost arc. Reading a
# name is not reaching a class.
class AppCatalog

  @entries:
    "HowToSaveMessageApp": {title: "How to save?",      icon: -> new FloppyDiskIconWdgt}
    "SimpleDocumentApp":   {title: "Docs Maker",        icon: -> new TypewriterIconWdgt}
    # … one line per app …
    "ToolbarsApp":         {title: "Super Toolbar",     icon: -> new ToolbarsIconWdgt,
                            toolTip: "a toolbar to rule them all"}

  @get: (appClassName) -> @entries[appClassName]
```

⚠ `DegreesConverterApp`'s entry carries **no `icon`** — its art is in the lazy `examples-icons` part
and a core file may not name it (§1.5). Its entry still carries the title. The folder supplies the
icon at the call site, inside the await that makes it legal, with a comment saying exactly why.

### §4.2 The two modes both read it

**Lazy** — `addToDesktop`/`addToFolder` take the class name and nothing else. ⚠ There is **no label
override**: an app has one name (§5.1). The only extra parameter is the icon, and it exists for one
structural reason (§1.5), not as a general escape hatch:

```coffee
@addToDesktop: (appClassName) ->
@addToFolder:  (folder, appClassName, iconOverride) ->   # iconOverride: ONE caller, see §1.5
```

`_lazyLauncherFor` looks up `AppCatalog.get appClassName` and — the bug fix — sets
`launcher.toolTipMessage = entry.toolTip if entry.toolTip?`, exactly as `createOpener` does.

**Eager** — `createOpener` reads `AppCatalog.get @constructor.name` instead of `@title` /
`@buildIcon()` / `@toolTip`.

### §4.3 Call sites afterwards

```coffee
# WorldWdgt.createDesktop — name only; the catalog knows the rest
addOpener "SimpleDocumentApp"
addOpener "ToolbarsApp"                  # …and its tooltip now actually appears

# ExamplesFolderWindowWdgt — the name comes from the catalog, here as everywhere else
L.addToFolder @, "SampleSlideApp"
L.addToFolder @, "SampleDashboardApp"
L.addToFolder @, "SampleDocApp"
L.addToFolder @, "SpreadsheetApp"
# the ONE override in the system, and it is FORCED, not a preference: this art is in the LAZY
# examples-icons part, and only this line — inside the whenAllLoaded scope above — may legally
# name it (check-part-edges reads one line at a time). See build-and-packaging.md §2.
L.addToFolder @, "DegreesConverterApp", -> new DegreesConverterIconWdgt
```

And the app classes lose `title:`, `buildIcon:` and `toolTip:` entirely. The base class keeps
`buildWindow`/`windowOpened`/`requiredParts`/`optionalParts` — those are behaviour, not identity, and
stay where they are.

### §4.4 ⚠ ORDER OF ARGUMENTS — do not "tidy" this

`addToDesktop` adds then sizes; `addToFolder` sizes then adds. Keep both. See §1.1.

---

## §5 Central risks

### §5.1 THE ONE REAL DESIGN QUESTION — does a caption belong to the app, or to the placement?

Four apps are captioned differently in the folder than on their own class (§1.2). Two readings:

- **(A) The caption belongs to the APP.** One name, displayed wherever a launcher for it appears.
- **(B) The caption belongs to the PLACEMENT.** The catalog gives a default; a call site may override
  it, e.g. because a folder supplies context and can afford shorter labels.

**(A) is right, and the argument does not mention screenshots.** The same app can get a launcher in
three places: the Examples folder, the desktop (`DemoMenus`, and any icon dragged out of the folder),
and a restored snapshot. A launcher's caption is stored on the widget, so under (B) dragging an icon
out of the folder puts "Slide" on the desktop while `DemoMenus` puts "Sample slide" right next to it —
**two icons for one app, with different names, side by side.** A name that depends on where you are
standing is not a name. (B) also re-creates in miniature the very defect this plan exists to remove: a
second place where an app's identity is written down.

⇒ **No label override. `addToFolder` takes a class name and nothing else** (§4.2). The four
differences are drift, not information — as their own inconsistency shows: three Examples apps carry
a `"Sample "` prefix and `SpreadsheetApp` does not.

#### ⚖ OWNER DECISION — which string wins, per app

Architecture says there is one string. *Which* string is a product call, not an architectural one, so
it is the owner's. Confirm before executing §6 step 1:

| app | class title today | folder label today | recommendation |
|---|---|---|---|
| `SampleSlideApp` | `"Sample slide"` | `"Slide"` | **`"Slide"`** |
| `SampleDashboardApp` | `"Sample dashboard"` | `"Dashboard"` | **`"Dashboard"`** |
| `SampleDocApp` | `"Sample doc"` | `"Document"` | **`"Document"`** |
| `DegreesConverterApp` | `"°C ↔ °F"` | `"C-F converter"` | **owner's taste** — `"°C ↔ °F"` is the nicer glyph, `"C-F converter"` is the consistent one |
| `SpreadsheetApp` | `"Spreadsheet"` | `"Spreadsheet"` | already identical |

Recommending the FOLDER's set for the first three, for two reasons that are about the product rather
than about tests: it is the internally consistent set (no stray `"Sample "` prefix), and **in the
shipping product these four launchers only ever appear inside the Examples folder** — `DemoMenus`
creates launchers for the three *Maker* apps (`FizzyPaintApp`, `SimpleDocumentApp`, `SimpleSlideApp`),
never for the Sample apps. The `"Sample "` prefix is therefore redundant with the folder it lives in.

#### Expected, PREDICTED churn

Changing those strings moves pixels, and that is fine — recapture. Predict it explicitly so an
unpredicted diff still means something:

- `SystemTest_macroDesktopShortcutIcons` `image_0` — it calls `createOpener()` on the four Sample apps
  and draws their captions. **Will change.**
- Any test that opens the Examples folder and screenshots its contents. Find them before running:
  `grep -rl "Examples" Fizzygum-tests/tests | head`.

Recapture with `fg recapture --auto` (it re-runs the FULL suite per dpr and prints
`COMPLETE`/`INCOMPLETE`; a bare capture that silently half-finishes is the trap it exists to close).
⚠ Then rebuild — a recapture changes references, not the build, but the gauntlet's later legs read a
fresh tree.

### §5.2 The tooltip fix DOES change behaviour — deliberately

Restoring the two lost tooltips is a real behavioural change (hovering those icons shows bubble help
again). It is a **fix**, it is what §1.4 documents, and it should be called out in the commit message.
It should not change any screenshot: tooltips appear on a hover countdown, and no test hovers a
desktop icon. Verify rather than assume — if a screenshot does move, stop and understand why.

### §5.3 The lazy-art override must not become a general escape hatch

Exactly one call site may pass `iconOverride`. If a second appears, the catalog is being worked
around. Consider asserting it in a comment; do not build a mechanism for it.

### §5.4 Load-order

`AppCatalog` is named by `WorldWdgt`, `ExamplesFolderWindowWdgt` and
`IconicDesktopSystemWindowedApp` — all core. Load order is auto-discovered by regex-scanning source
text for `extends X` / `@augmentWith X` / `new X` (`src/boot/dependencies-finding.coffee`). ⚠ A
class-level `@entries` object referenced as `AppCatalog.get …` inside a method body is **invisible to
that scanner** (it only sees `new X`, `extends X`, `@augmentWith X`, and two restricted class-body
field-initialiser forms). That is fine here — nothing *extends* `AppCatalog` and it is only read from
method bodies at runtime, never at class-definition time. **But do not put an `AppCatalog` lookup in a
class-body field initialiser**, which would run at compile time with no ordering guarantee.

### §5.5 The Examples doors' apps live in five different lazy parts

`DegreesConverterApp`, `SampleSlideApp`, `SampleDashboardApp`, `SampleDocApp`, `SpreadsheetApp` are
each alone in a one-class part (`example-degrees-converter`, `example-slide`, `example-dashboard`,
`example-doc`, `example-sheet`). The catalog names them **as strings only** — the sanctioned
indirection. Never `new`, never `extends`, no bare identifier. If you find yourself writing a bare
`SampleSlideApp` in a core file, stop.

---

## §6 Execution steps

Run `fg build` after each step; it is ~15s and catches a partition or syntax error immediately.

1. **Create `src/AppCatalog.coffee`** with all 14 entries, transcribing titles/icons/tooltips from the
   app classes (they are authoritative — the call-site literals are the copy). Omit `icon` for
   `DegreesConverterApp` with the comment from §4.1. `src` is claimed by the `core` part already, so no
   `parts.json` change is needed — verify with `fg build` (`check-shippable-coverage.js` fails loudly
   if a directory is unclaimed).
2. **Rework `IconicDesktopSystemWindowedAppLauncherWdgt`**: `addToDesktop` / `addToFolder` /
   `_lazyLauncherFor` take `(appClassName)` — plus `iconOverride` on `addToFolder` alone (§1.5, one
   caller, forced) — read the catalog, and **set
   `toolTipMessage`** (§1.4). Preserve the two add/size orders (§4.4).
3. **Rework `IconicDesktopSystemWindowedApp.createOpener`** to read `AppCatalog.get @constructor.name`.
   Keep the `inWhichFolder` branch and both add/size orders exactly as they are.
4. **Simplify the call sites**: `WorldWdgt.createDesktop`'s nine `addOpener` lines to names only, and
   `ExamplesFolderWindowWdgt`'s five likewise (+ the one forced icon override). ⚠ This is where the
   §5.1 owner decision lands — the four folder labels stop existing as literals, so whichever string
   won becomes the catalog `title`.
   ⚠ `createDesktop`'s **call ORDER is the layout** — icons are placed top-to-bottom, wrapping after
   5. Do not reorder, and keep `menusHelper.binIconAndText()` where it sits between them.
5. **Delete `title:` / `buildIcon:` / `toolTip:` from the 14 app classes**, and their three
   declarations on the base — `IconicDesktopSystemWindowedApp.coffee` currently declares `title: nil`
   (~line 27), `toolTip: nil` (~line 29) and `buildIcon: -> nil` in its per-app-hooks block. Grep
   afterwards: `grep -rn 'buildIcon:\|^  title:\|^  toolTip:' src` should return nothing but the
   catalog. ⚠ Leave `buildWindow:` and `windowOpened:` alone — those are behaviour, not identity.
6. **Fix the ghost reference** in the launcher's header comment (§2): `authoring-launcher and
   fizzytiles-launcher exist as eager slivers` — those parts are deleted; rephrase to past tense or
   drop the clause.
7. **Docs**: update `docs/architecture/build-and-packaging.md` §2 where it describes the eager mode
   (*"`createOpener` hands over a live app singleton…"*) to say both modes read one catalog; and the
   "Launching a lazy part" figcaption in `docs/explainers/build-and-packaging.html`. Add a line to
   `docs/BACKLOG.md` and close out this plan per the `docs/README.md` loop (`git mv` to `archive/`
   with a status stamp + an `archive/INDEX.md` line).

---

## §7 Verification protocol

Run from anywhere; `fg` is path-correct. **Long ones go in the background — wait for the notification.**

| # | command | what it must say |
|---|---|---|
| 1 | `fg build` | `BUILD EXIT=0 OK`; `check-part-edges` 0 unguarded / 0 inheritance |
| 2 | `fg gauntlet` | 14/14 PASS |
| 3 | `git -C …/Fizzygum-tests status --short` | **only the references §5.1 predicted.** Anything else is a finding — investigate it, do not recapture it |
| 4 | `fg lazyprobe` | `LAZY ICONS OK` — 51 passes, all 14 icons |
| 5 | `fg homepage` | `HOMEPAGE EXIT=0 OK` |
| 6 | `./build_and_smoke.sh --profile lean` | `BOOT OK` — ⚠ `lean` ships NO app parts, so `canEverProvideClass` returns false for every app and the desktop must draw **no** app icons and not throw |
| 7 | `fg fingerprint homepage dae866f9` | ⚠ predict in WORDS first. Expect a small `js/pre-compiled.js` change (one class added, 14 shrunk) and a boot-bundle change from the dirty-tree stamp. Any *other* file differing is a finding |

⚠ **`fg fingerprint` leaves the build tree on the fingerprinted profile — run `fg build` afterwards.**

**Manual check the suite cannot do (§1.4 is invisible to it):** open
`Fizzygum-builds/latest/index.html`, hover the "Super Toolbar" and "Fizzytiles" desktop icons, and
confirm bubble help appears. That is the bug being fixed and no automated gate covers it.

⚠ **A screenshot diff §5.1 PREDICTED is a recapture; one it did not is a finding.** Read §5.1 before
reacting either way, and never recapture to make an unexplained diff go away.

---

## §8 Rejected alternatives — do not re-attempt

- **⛔ Put the descriptor on the app class and have `createDesktop` read it.** The intuitive reading of
  "one descriptor", and it is the one thing that must not happen. It re-introduces boot-time
  reachability of every app class, undoing the whole boot-cost arc (§0). Falsification is structural,
  not empirical: `createDesktop` runs at boot, so anything it reads must be in the eager image.
- **⛔ Delete the eager mode instead.** Tempting (7 call sites, 2 files) but it discards a legitimately
  useful shape — handing over a live app singleton — and it would force the four Examples labels and
  the `SystemTest_macroDesktopShortcutIcons` fixture to be rewritten, putting reference images at risk
  for no gain. Revisit only if the eager mode loses its last caller.
- **⛔ Make the catalog's `icon` a class-name STRING (`icon: "TypewriterIconWdgt"`) so the lazy
  `DegreesConverterIconWdgt` entry needs no exception.** Superficially elegant and consistent with "an
  icon is not its app", but most icons are COMPOSED (`new GenericShortcutIconWdgt new
  SimpleSlideIconWdgt`), which a single name cannot express. Encoding composition as a nested-name
  list invents a mini-DSL to save one documented override. Not worth it.
- **⛔ Keep a per-placement label override so the folder can go on using short captions.** This was
  the plan's first answer and it was reached the wrong way — by avoiding a recapture rather than by
  asking what a caption IS. §5.1 settles it on merits: a launcher's caption is stored on the widget,
  so a placement-dependent name puts two differently-named icons for one app side by side on the
  desktop, and re-creates the second-place-for-identity defect this whole plan removes. One app, one
  name; the four differing strings are drift.
- **⛔ Add a build gate that checks the two copies agree.** Considered and rejected: it institutionalises
  the duplication instead of removing it, and it could not have caught §1.4's bug anyway — the copies
  did not disagree, one of them was simply missing a field.

---

## §9 References

- `docs/architecture/build-and-packaging.md` §2 — the partition, the door idioms, **AN ICON IS NOT ITS
  APP**, `canEverProvideClass` vs `whenClassAvailable`. Authoritative and present-tense.
- `docs/explainers/boot-and-lazy-parts.html` §3–4 — the same, illustrated, plus the boot/open/click
  tiers.
- `docs/plans/boot-cost-reduction-plan.md` — the arc that created this residue; §2.5 carries the
  ⛔ SUPERSEDED stamp on the old "anything reached at BOOT forces a launcher split" rule.
- `buildSystem/check-part-edges.js` — the gate whose one-line-at-a-time reading forces §1.5.
- `buildSystem/what-pins-core.js` (`fg whatpins`) — the analyser that closed out the arc; useful for
  confirming nothing here re-pins a class to core.
- **Owner standing rule — "don't let recapture churn dictate design."** Pick the right code home, the
  right API and the right strings on merits, then recapture what moves. This plan violated it once
  (§5.1, §8) and the violation is left visible on purpose, because the pull is strong and silent: the
  churn-avoiding answer arrives feeling like a *constraint discovered* rather than a *design chosen*.
  Related: reference images are not sacred — a benign, understood diff is just a recapture.
- `Fizzygum-tests/DETERMINISM.md` — why an already-loaded await path must stay SYNCHRONOUS
  (`whenAllLoaded` runs inline when the parts are in; a microtask moves the effect a whole world cycle
  and the suite measures cycles). Relevant if you touch `launch`.
