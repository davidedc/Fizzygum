# Static gates — shapes chosen to quiet a gate (audit, 2026-11-21)

Read against Fizzygum `b6b2f60f` / Fizzygum-tests `e06b7c26a`. Read-only: no build, no `fg`, no repo edit.
Scope: the STATIC gates of `Fizzygum/buildSystem/gates.js` (rows 1–12 of the brief). Not in scope (sibling
workers): `WORLD_CONSTRUCTION_DRIFT`, the revisit/settle flags, `AIM MISSED` / `pressMustLandOn`, `pointerKinds`,
recaptures, ratchet numbers and the complexity ceiling.

Each claim is marked **VERIFIED** (I read the lines, the commit, or ran the scan named) or **INFERRED** (from
shape or from a sample). Paths are relative to `/Users/davidedellacasa/code/Fizzygum-all/`.

Verdict words: CONTORTION-STANDING · CONTORTION-UNDONE · DEFENSIBLE SANCTION · RIGHT SHAPE · UNSURE.

---

## 1. Standing contortions — the actionable list

Eleven items, C1–C11, in the order found (C1–C8 from the tree and git, C9–C11 from the transcripts and
ledgers, then verified in the tree). The strongest evidence — the session's own sentence naming the gate — is
on C9 and C10; the largest is C1. "Pixels" says whether undoing can move a screenshot reference.

### C1. Eleven internal methods are spelled PUBLIC because a gate refuses their `_` form, and are excused in the end-user API allowlist

- **Where:** `Fizzygum/buildSystem/public-api-allowlist.txt:27-37` — `addText`, `bringTextAndCaretToState`,
  `createWidgetToBeHandled`, `actOn`, `bringUpReferencedWidget` (reason: "[A] forbids the _-form" or "[A]/[G]");
  `addHighlightingWidgets` ("[G] forbids the _-form"); `autoScroll`, `startAutoScrolling`,
  `runAllSystemTestsAtSpeed`, `startTestPlayingWithSlideIntro` ("[S] forbids the _-form"); `wrapContent`
  ("[S]/[G] forbid the _-form"). Definitions e.g. `Fizzygum/src/basic-widgets/ViewportWdgt.coffee:1345`
  (`startAutoScrolling`), `:1378` (`autoScroll`), `Fizzygum/src/WorldWdgt.coffee:1716`
  (`addHighlightingWidgets`), `Fizzygum/src/TransformFrameWdgt.coffee:199` (`wrapContent`).
- **Quoted:** `autoScroll                # ViewportWdgt's drag auto-scroll step; it scrolls through the public scrollX/scrollY — [S] forbids the _-form`
- **Gate:** `check-call-separation` [U] (a self-only public method must be `_`-tier) against `check-layering`
  [A]/[G] and `check-call-separation` [S] (a `_` method must not call a public command).
- **Evidence it was gate-driven — VERIFIED:** the allowlist's own reasons, and the commit messages:
  `078d67d4` (2026-07-12) "a public method whose body drives the public settling API on OTHER widgets cannot
  take the _-form ([A] has no marker) - such names stay public via the allowlist"; `fab3f8ad` (2026-11-06)
  "allowlisted because a gate refused the _ form: addHighlightingWidgets ([G]), autoScroll and
  startAutoScrolling ([S]), wrapContent ([S]/[G])"; `820298d7`, `24fc1e1b` likewise. Every one has only `@`
  self-calls today (the git worker counted; I re-checked `autoScroll`, `startAutoScrolling`,
  `addHighlightingWidgets`, `wrapContent`).
- **Why it is worse:** the tier states a role the member does not have. The allowlist's header says it holds
  "deliberate end-user surface"; these are a per-cycle reconciler, a drag step, two harness steps and a
  constructor helper. Each also shows in every inspector's member list as API.
- **Right shape:** for the six with a per-method marker available ([S]: `# public-call-sanctioned`, [G]:
  `# nosettle-sanctioned`) — `autoScroll`, `startAutoScrolling`, `runAllSystemTestsAtSpeed`,
  `startTestPlayingWithSlideIntro`, `addHighlightingWidgets`, `wrapContent` — rename to `_name`, put the marker
  with the same reason on the method, delete the allowlist line. For the five [A] ones there is no marker:
  either the body moves to the `_…NoSettle` cores and the one caller settles, or [A] gains a marker with a
  required reason (a gate change, owner call). The 2026-07-12 batch was owner-triaged at the time
  (allowlist header: "Owner-triaged (plan §6 T4/§7-1)"); the six added 2026-11-06…17 were not.
- **Blast radius:** M (11 renames, each with 1–4 call sites; `createWidgetToBeHandled` is a 5-class family).
  **Pixels:** yes, possibly — a renamed member moves inspector member lists (the `setMinimumExtent` →
  `_setMinimumExtent` rename of 2026-07-18 cost one inspector recapture). **Gate change:** only for the [A] five.

### C2. `Widget.isVisuallyTransformed` is a public copy of `_isInsideNonIdentityIsland`, made so a macro can call it

- **Where:** `Fizzygum/src/basic-widgets/Widget.coffee:1871-1876` and `:1759-1760`.
- **Quoted:**
  ```
  # ... The blessed
  # public name for the private _isInsideNonIdentityIsland (macros cannot call `_`-prefixed members).
  isVisuallyTransformed: ->
    @_enclosingNonIdentityIsland()?
  ```
  and `_isInsideNonIdentityIsland: ->` / `@_enclosingNonIdentityIsland()?` — the same body.
- **Gate:** `check-layering` [D] (a macro may not call a `_` member).
- **Evidence — VERIFIED** from the comment. Product code calls the PRIVATE spelling cross-object
  (`Fizzygum/src/WorldWdgt.coffee:1820` `bandHost._isInsideNonIdentityIsland()`); the public one has no product
  caller, only two tests (`SystemTest_macroGeometryApiTwoVocabularies`, `SystemTest_macroIslandBufferCacheByteIdentity`).
  Born `05e70b19` (2026-07-11, "Affine Phase 5: public geometry API under transforms").
- **Right shape:** one name. The predicate is part of the public geometry vocabulary that phase introduced
  (beside `rotationDegrees`, `scaleFactor`, `accumulated*`), so the honest end state is the public name alone:
  `WorldWdgt:1820` asks `isVisuallyTransformed()`, and `_isInsideNonIdentityIsland` goes. (The other way — keep
  the private one and have the two tests read it under `# macro-private-call-sanctioned:` — also removes the
  duplicate; the first matches what the tests assert, a public contract.)
- **Blast radius:** S. **Pixels:** no, unless an inspector reference lists Widget's members around that name.
  **Gate change:** none.

### C3. `ShortcutWdgt.isDesktopShortcut` — a type-named predicate with no product caller, alive only because two rigs call it

- **Where:** `Fizzygum/src/ShortcutWdgt.coffee:89-94`.
- **Quoted:**
  ```
  # I am a desktop shortcut (a reference), not a real widget being dropped in. A folder's drop
  # handling positions/references me accordingly, asking this instead of testing
  # `instanceof ShortcutWdgt`; inherited by all shortcut subclasses.
  # (type-test-elimination campaign)
  isDesktopShortcut: ->
    true
  ```
- **Gates:** `instanceof-type-test` stink (why it exists), `check-dead-methods` (why it stays).
- **Evidence — VERIFIED:** zero references in `Fizzygum/src` and the harness; nine in
  `Fizzygum-tests/scripts/graph-liveness-headless.js` and `serialization-roundtrip-headless.js`, each
  `c.isDesktopShortcut && c.isDesktopShortcut() && c.referencedWidget === doc`. The comment's "a folder's drop
  handling … asking this" is false today. `cd24c28d` (2026-11-06): "isDesktopShortcut is called by two rigs"
  (the reason its dead-method allowlist entry of `9778d12c`, 2026-10-19, could go).
- **Right shape:** the rigs ask the capability that already sits one method above it,
  `isShortcutTo(widget)` (`ShortcutWdgt.coffee:86`, which "folds the referent check in" — exactly the rigs'
  two-part test); the one rig line that wants "any shortcut" reads `referencedWidget`. Then delete the method.
- **Blast radius:** S (one method, nine rig lines). **Pixels:** no. **Gate change:** none.

### C4. A class named as a STRING to get past `check-part-edges`, at eleven sites — nine of them inside a scope where the bare name is legal

- **Where:** `Fizzygum/src/demos/DemoMenus.coffee:417,423,429,430,436,442,448`;
  `Fizzygum/src/WorldWdgt.coffee:3515,3542`; `Fizzygum/src/basic-widgets/Widget.coffee:4999,5011`.
- **Quoted:** `vertAxis = new (window["AxisWdgt"])` under `world.parts.whenAllLoaded ["plots"], ->`;
  `window.demoMenus ?= new (window["DemoMenus"])`; `consoleWdgt = new (window["ConsoleWdgt"]) @`. And the
  reason, `Widget.coffee:4977-4981`: "The class is named as a STRING. buildSystem/check-part-edges.js requires a
  guard wherever core names a part-owned class as a SYMBOL, and the correct guard for a lazy part does not
  exist -- so the gate's own sanctioned escape applies: name it as DATA".
- **Gate:** `check-part-edges`.
- **Evidence — VERIFIED:** the comment above; and the dates. The sites landed `058ea35f` (2026-07-30) and
  `e39392bf` (2026-07-31). The gate learned "AN AWAIT IS A GUARD" (its header's rule 6) in `510c1e74`
  (2026-07-31), after which "the correct guard for a lazy part does not exist" is no longer true: a line under
  `world.parts.whenAllLoaded [...]` may name the class. `Fizzygum/src/dev-tools/WidgetFactory.coffee:127-128,163-164`
  does exactly that today (`world.parts.whenAllLoaded ["demos"], ->` / `foo = new BouncerWdgt`). Since
  `d7e1bab3` (2026-10-24) the house rule is also "ask `classNamed name`, never `window[name]`" (CLAUDE.md).
- **Why it is worse:** the same door is spelled two ways in the tree; the string spelling hides the reference
  from the one gate that judges it (the gate header calls this its blind spot) and from any reader of symbols;
  the stated reason is stale.
- **Right shape:** the nine sites that sit lexically under their `whenAllLoaded` (`DemoMenus` ×7, `WorldWdgt`
  ×2) name the class bare: `new AxisWdgt`, `new DemoMenus`. The two in `Widget` (`spawnInspector`,
  `createConsole`) build inside a closure defined ABOVE the await, so the line-at-a-time gate would refuse a
  bare name there: either move the construction under the `whenAllLoaded` line, or keep the class as data but
  through `classNamed "InspectorWdgt"`. Rewrite the comment at `Widget.coffee:4977` and `WorldWdgt.coffee:3532-3535`.
- **Blast radius:** S. **Pixels:** no (same objects built at the same time). **Gate change:** none.
- **Caveat:** the gate header still says the data spelling is "the prescribed shape for a lazy part"; that
  sentence and rule 6 now disagree, and the header wants the same edit. The git worker read these as a
  defensible sanction for that reason; I count the nine in-scope ones as standing because the tree itself
  shows the plainer spelling passing. A bare name of a lazy part's class in a core method body is already
  shipped and harmless at boot (`Widget.coffee:6335` `new LayoutElementAdderOrDropletWdgt` after its guard;
  the boot dependency finder reads only `extends` and class-body initialisers) — VERIFIED by reading, not by
  a build.

### C5. A public settling setter is hoisted into a constructor because [A] keeps it out of the `_` method it belongs to

- **Where:** `Fizzygum/src/basic-widgets/menu-system/InertIconHolderWdgt.coffee:48-58`.
- **Quoted:**
  ```
  # ... It is
  # called here, in the constructor, because check-layering's rule [A] keeps it out of `_` methods.
  if widgetToPicture.children.length isnt 0
    widgetToPicture.setExtent @_extentFitting widgetToPicture, opts.fitInto
  @_takePictureOf widgetToPicture, opts.fitInto
  ```
- **Gate:** `check-layering` [A] (no marker exists for it).
- **Evidence — VERIFIED** from the comment; landed `b819a68a` (2026-11-18, "Toolbars: an overflow row pictures
  a tool with children whole").
- **Why it is worse:** sizing the subject is a step of taking its picture, and it lives apart from
  `_takePictureOf` only because of that method's name; the constructor now settles another widget
  (`OverflowChevronButtonWdgt.coffee:91` carries a `# nosettle-sanctioned` that has to explain "The picture's
  constructor settles too").
- **Right shape:** the size-then-shoot sequence in one place. Two honest ways: (a) the caller
  (`OverflowChevronButtonWdgt._miniatureOf`, an event-time path already sanctioned for settling) sizes the copy
  with the public setter before handing it over, and the constructor only takes the picture; or (b) [A] gains a
  per-method marker like [G]'s, for a low-level method that settles ANOTHER, detached widget on purpose.
- **Blast radius:** S. **Pixels:** no if the order of size and shot is kept. **Gate change:** only for (b).

### C6. `m.updateVisibility?` stands in for `m instanceof HandleWdgt`

- **Where:** `Fizzygum/src/basic-widgets/Widget.coffee:1035-1039`.
- **Quoted:**
  ```
  # only HandleWdgt defines updateVisibility, so the ?-existence filter is exactly the old
  # `m instanceof HandleWdgt` (type-test-elimination ε — the keep-links-back precedent)
  isThereAnHandle = @firstChildSuchThat (m) ->
    m.updateVisibility?
  isThereAnHandle?.updateVisibility()
  ```
- **Gate:** `instanceof-type-test` stink.
- **Evidence — VERIFIED** from the comment and `4e4a6ee7` (2026-07-17): "`m instanceof HandleWdgt` -> filter on
  `m.updateVisibility?` -- only HandleWdgt defines that verb, so the set is exact with zero new methods". It
  was owner-gated then. It is the backlog table's "duck-typed type test in disguise", by its own words.
- **Right shape:** guidelines §14 rank 1 — the branch disappears: the container tells its children its layout
  spec changed and the handle is the one that listens (the TODO two lines above already asks "should we rather
  have handles subscribe to the parent layout change"); or an honest type test kept with its reason. Note it
  finds only the FIRST such child.
- **Blast radius:** S. **Pixels:** no for an equivalent rewrite. **Gate change:** an honest `instanceof` raises
  the stink's count by one (needs a dated reason).

### C7. Type-named predicates from the type-test campaign (`isX: -> true`, X = the class)

The backlog table names this quiet fix; guidelines §14: "Never `isScrollPanel` — a type-named predicate is
only cosmetically better than the type test." All VERIFIED standing; gate-driven VERIFIED where the site's
own comment says "instead of `instanceof X`; type-test-elimination campaign", INFERRED otherwise.

| predicate (definer:line) | soaked call sites | born | names exactly one class? | my verdict |
|---|---|---|---|---|
| `isDesktopShortcut` (`src/ShortcutWdgt.coffee:93`) | 0 in product | 2026-06-22 `f900db2a` | yes | CONTORTION-STANDING — see C3 |
| `isDivider` (`src/basic-widgets/menu-system/DividerWdgt.coffee:31`) | 2, both in `CommandPanelWdgt.removeConsecutiveLines` | 2026-07-18 `44493b78` ("instanceof stink baseline ratcheted 97->95") | yes | CONTORTION-STANDING (mild): one consumer, same subsystem. Right shape: move the behaviour (a row answers whether it merges with a like neighbour) or an honest sanctioned type test |
| `isGlassBoxWrapper` (`src/GlassBoxBottomWdgt.coffee:44`) | 1 (`ToolPanelWdgt:85`) | 2026-06-22 `9b0f349b` | yes | CONTORTION-STANDING (mild): "am I already wrapped" asked of the wrapper class by name |
| `isGlassBoxLid` (`src/app-kit/GlassBoxTopWdgt.coffee:20`) | 1 (`GlassBoxBottomWdgt:59`) | 2026-08-25 `5a45a135` | yes | CONTORTION-STANDING (mild): the wrapper could hold its lid in a field instead of searching its children by type |
| `isLayoutChrome` (`src/LayoutChromeWdgt.coffee:44`) | 1 (`Widget:5219`) | 2026-08-05 `eee46adc` | yes | CONTORTION-STANDING (mild): the question is "do I offer the division-cell menu" |
| `isLayoutAdderOrDroplet` (`src/authoring/LayoutElementAdderOrDropletWdgt.coffee:15`) | 4 | 2026-06-22 `b92345d9` | yes | UNSURE: also keeps core from naming a lazy part's class, a real gain; a capability name (drop slot) would only rename it |
| `isFrame` (`src/FrameWdgt.coffee:1025`) | 19 | 2026-06-17 (as `isWindow`, `4b8ff5d8`) | yes | UNSURE: its comment says "Polymorphic replacement for `instanceof FrameWdgt`", so it is the listed quiet fix; but "is it a frame" is the frame model's own structural question at most sites. Owner call; 19 sites, and honest type tests would raise the stink by 19 |
| `isDesktopIcon` (`src/WidgetHolderWithCaptionWdgt.coffee:98`) | 6 | 2026-06-22 `e5e70918` | named for the role, not the class | DEFENSIBLE |
| `isConnectionPin` (`src/patch-programming-experimental/FanoutPinWdgt.coffee:21`) | 2 | 2026-06-22 `679318a9` | role name; also avoids a part edge | DEFENSIBLE |
| `isMenu` (`MenuWdgt:42`, `PromptWdgt:49`) | 1 | 2026-06-22 `7ae82f33` | two unrelated answerers | DEFENSIBLE |
| `isTextSizedGlassBoxItem` (`MenuItemWdgt:264`) | 1 | 2026-06-22 `ec308695` | capability name | RIGHT SHAPE |
| layout specs: `isDivisionElement` (13), `isFrameContentSpec` (5), `isStretchElement` (4), `isCornerInternal` (2), `isEdgeDock` (1) | 25 | 2026-07-19 … 08-24 | each names one spec class | UNSURE: they replaced an enum compare, and "which arrangement holds this child" is what the callers ask. Not clearly worse than a type test, not better either |

- **Blast radius:** S each for the five mild ones; L for `isFrame`. **Pixels:** no for faithful conversions
  (§14: "Any red test after such a swap is a faithfulness bug"). **Gate change:** an honest `instanceof` needs
  the stink's baseline raised with a dated reason.

### C8. Test prose made vaguer so a census would count a method

- **Where:** `Fizzygum-tests/tests/SystemTest_macroHandleWdgtIsItselfResizable/*_automationCommands.js` (macro
  comment), `SystemTest_macroHandleAttachedToNothing/*_automationCommands.js`,
  `SystemTest_macroRoundedBoxCornerClickThrough/*.js` (`intent`), and their generated `visualisation.html`.
- **Quoted (the change):** "it declares catchesPointerAt over its whole box" → "it declares its whole box as
  its pointer surface".
- **Gate:** `check-call-separation` [U], stale allowlist entry.
- **Evidence — VERIFIED:** `Fizzygum-tests 466109712` (2026-08-22) "tests: stop naming catchesPointerAt in
  prose, so the census can see it again … Meaning is preserved, only the bare identifier goes". The reader
  stopped counting prose on 2026-11-06 (`cd24c28d`: "A bare word …, a comment or prose reaches nothing"), so
  the cause is gone.
- **Right shape:** name the method again in those four places. **Blast radius:** S. **Pixels:** no.

### C9. Code respelled because `check-unresolved-sends` does not know a platform method (four sites)

A quiet fix the backlog table does not list: the gate fails on a paren-call of a platform name missing from its
in-file `BUILTINS`, and the session rewrote the CODE instead of adding the name.

- **Where and what — all VERIFIED in the tree, each with the session's own words (transcript `17e8eba8`):**
  - `Fizzygum/src/duplication/Duplicator.coffee:155` `Kind = original.constructor` — a review-recommended
    hardening (`Object.getPrototypeOf(original).constructor`) was dropped. 2026-11-11, L69480: "The gate's list
    doesn't include Object.getPrototypeOf, and the review rated the shadowed-constructor case low, so I'm
    dropping that hardening and going back to original.constructor." **This one changes behaviour** (a view
    carrying an own `constructor` property is copied by the wrong kind).
  - `Fizzygum/src/serialization/SerializationError.coffee:84` `if key is 0 and 1 / key < 0 then "-0"` in place
    of `Object.is(key, -0)`. 2026-11-12, L83442: "The unresolved-sends gate matches by name and doesn't know
    `Object.is` … I'll spell -0 with the `1 / key < 0` test instead." (`Serializer.coffee:76` writes the
    paren-less `Object.is n, value`, which the gate does not read — the same call, two spellings.)
  - `Fizzygum/src/serialization/Deserializer.coffee:646` `/^data:image\//.test(record.data)` in place of
    `startsWith`. 2026-11-10, L60760: "The unresolved-sends gate doesn't know the native `startsWith(`. I'll
    use a regex test there instead."
  - `Fizzygum/src/meta/Class.coffee:156` `.replace(/^\s+/, "")` in place of `.trimStart()`. 2026-11-08, L10067:
    "The build failed because the unresolved-sends gate doesn't recognize `.trimStart(`, so I'm switching to a
    regex replace". (`trimEnd` IS in `BUILTINS`, `check-unresolved-sends.js:192`.)
- **Right shape:** the route the same sessions took elsewhere (`.next(`, `getImageData`, `map`): add the name to
  `BUILTINS` — bare for `startsWith` / `trimStart`, KEYED for `Object.is` and `Object.getPrototypeOf` (the
  table's `Math.round` form) — then write the plain call, and restore the Duplicator hardening.
- **Blast radius:** S. **Pixels:** no. **Gate change:** four `BUILTINS` entries (data, not a rule).

### C10. A rig's expected list was replaced by a read of the product's own rule, to satisfy `check-hand-lists`

- **Where:** `Fizzygum-tests/scripts/serialization-roundtrip-headless.js:1265-1268`.
- **Quoted:**
  ```
  // the pane's runtime values, derived from what the pane declares: its transient fields whose value rebuilds itself
  const runtime = Array.from(Serializer.transientsForClass(FridgeMagnets3DCanvasWdgt))
    .filter((k) => NativeValueKinds.rebuildsItself(pane[k]) && !NativeValueKinds.isCanvasContext(pane[k]));
  ```
- **Evidence — VERIFIED:** transcript `17e8eba8` L60299 (2026-11-10): "The hand-lists gate rejects the rig's
  literal list of field names (\"derive the list\"). Deriving it instead: the pane's transient fields whose
  values rebuild themselves."; ledger `Fizzygum-tests/.scratch/backlog-loop-2026-11-10/LEDGER.md:453`. The
  literal was `['transforms','meshCache','surface']`.
- **Why it is worse:** the check `paneRuntime.derivedInThePanesOwnFields` now takes its expected set from
  `Serializer.transientsForClass` and `NativeValueKinds.rebuildsItself` — the two product rules it is there to
  judge. A field dropped from the transients, or a predicate that stops matching, shrinks the expectation
  instead of failing it (only `runtime.length > 0` stands guard). This is the backlog table's "replace a clear
  list by reflection".
- **Right shape:** the table's own answer — the literal list, asserted both ways against what the pane
  declares, with `// hand-list-sanctioned:` naming this check as its guard.
- **Blast radius:** S. **Pixels:** no. **Gate change:** one sanction line.

### C11. `p?._materializedBySugar?` — a private field's existence used as the "is it an island" test

- **Where:** `Fizzygum/src/basic-widgets/Widget.coffee:2137-2142`.
- **Quoted:** "only islands define _materializedBySugar (as _dropPolicyProxy relies on), so its presence is the
  island test." / `return undefined if !p?._materializedBySugar?`
- **Gate:** `instanceof-type-test` stink. **Evidence:** shape VERIFIED by the comment; motive INFERRED — ledger
  `Fizzygum-tests/.scratch/cleanups-loop/LEDGER.md:784` ("`_enclosingSoleContentIsland` asks
  `p?._materializedBySugar?`. instanceof stink 74 → 64 (baseline set)"), commit `056c8328` (2026-11-13).
- **Right shape:** the island answers a query named for what is asked (it is transform plumbing round ONE
  figure, at identity too), dispatched `?()`; or an honest `instanceof TransformFrameWdgt` with its reason.
  Same family as C6.
- **Blast radius:** S. **Pixels:** no. **Gate change:** only for the honest type test (+1).

### Unsure — gate motive VERIFIED from a session, shape not clearly worse; each with what would settle it

- **`FooterBandLayout.@_arrange`** (`Fizzygum/src/FooterBandLayout.coffee:75`; called from `BinWdgt.coffee:154`,
  `CodeAreaWdgt.coffee:106`, `meta-tools/InspectorWdgt.coffee:647`). [F] fired on `@arrange`; the agent
  recommended the marker, the session renamed (transcript `d055260b` agent-a6 L1491, 2026-10-25: "(i)
  Recommended. Add a sanction line" → "I'll rename `@arrange` to `@_arrange`"). The sibling engine is
  `StackLayoutEngine.arrange`, public with `# layout-apply-sanctioned: this IS the arrange`
  (`StackLayoutEngine.coffee:134`). Two engines of one role, two tiers. Settles it: pick one spelling for both.
- **The content-property tools' verb as a string** (`Fizzygum/src/authoring/EditorContentPropertyChangerButtonWdgt.coffee:118-119`
  `subject?[@verb]?`, `:141-142` `subject[@verb]()`; `IncreaseFontSizeButtonWdgt.coffee:9` and
  `DecreaseFontSizeButtonWdgt.coffee:9` `verb: "originallySetFontSize"`, a FIELD name). Transcript `fd5c9317`
  L5996 (2026-11-17): "The brief's `_actOn` / per-subclass `_offersMyVerb` shape is illegal under
  check-layering rule [A], so I used the nearest legal shape". The string dispatch is seen by neither [A] nor
  `check-unresolved-sends`, and the font-size pair's "verb" is a field probe. Settles it: would the brief's
  shape be chosen if [A] had a marker?
- **The delete chords select, then delete** (`Fizzygum/src/basic-widgets/CaretWdgt.coffee:765-779`).
  Transcript `f6c026f1` L2791 (2026-11-19): "no shared delete core — a new self-only public core would grow the
  [U] allowlist (not granted) and a private one breaks [A]". Settles it: Alt+Backspace then undo — is the
  restored word left selected?
- **`NativeValueKinds.rebuildsItself` lost its widget exclusion** (`Fizzygum/src/serialization/NativeValueKinds.coffee:37-38`;
  ledger `backlog-loop-2026-11-10/LEDGER.md:468-470`: "it needed an `instanceof`, which the instanceof stink
  failed a build on"). Settles it: should a widget that defines `rebuildDerivedValue` be dropped from a save?
- **`Serializer._colorComponentsProblem`** (`Fizzygum/src/serialization/Serializer.coffee:84-87`): the list
  `["_r","_g","_b","_a"]` became `[color._r, …]` with `"rgba".charAt(i)` (transcript `17e8eba8` L70299). The
  fields are now symbols a rename sees; the name is coupled by index. Minor either way.
- **`@_clipThroughForChild?(rectangle, child)`** (`Fizzygum/src/basic-widgets/Widget.coffee:3258`): the hook
  was renamed `_`-tier on 2026-11-21 "instead of raising the baseline" ([U] query count 104 vs 103); an honest
  self-only hook, noted because the count drove it.

### Gate-forced shapes the authors declared and defended — owner call, not counted above

- **The Examples folder's one icon override.** `Fizzygum/src/AppCatalog.coffee:56-60` ("`DegreesConverterApp`
  has NO `icon`, and that is forced rather than chosen: its art lives in the LAZY `examples-icons` part and
  check-part-edges.js reads ONE LINE AT A TIME"), `:78` (the entry without an icon),
  `Fizzygum/src/AppLauncherWdgt.coffee:47-50` (`iconOverride`, "exactly ONE caller in the system"),
  `Fizzygum/src/ExamplesFolderWindowWdgt.coffee:68-73` ("THE ONE ICON OVERRIDE IN THE SYSTEM, and it is forced
  rather than preferred"). VERIFIED gate-driven by those comments. UNSURE whether it is worse than the
  alternatives: the catalog has one irregular row and the launcher one extra parameter; regular shapes would be
  the converter's icon living in core like the other ten doors' art (costs core bytes), or a catalog thunk that
  names the class as data. What would settle it: the owner's view on whether that art may be core.
- **The Examples folder's populate step may not be a helper.** `ExamplesFolderWindowWdgt.coffee:47-51`
  ("factoring them into a `_populate` helper is not a tidy-up available here … and the gate is right").
  DEFENSIBLE: the authors argue the gate's reading is the reader's.

---

## 2. Per-gate findings

| # | Gate → quiet fix | What I looked at | Result |
|---|---|---|---|
| 1 | `check-part-edges` → `if X?` guard | Every `Class?` existence test whose class is in another part (script over `parts.json`): 37 sites, 16 of them on a LAZY part | **No guard swallows a click (VERIFIED).** The lazy ones are: toolbar item lists filtered behind `optionalParts` that the app's `launch` awaits (`DashboardsToolbarWdgt:16-22`, `SlidesToolbarWdgt:17-18`, `SuperToolbarWdgt:25`) — RIGHT SHAPE; `return unless LayoutElementAdderOrDropletWdgt?` in four arrange cores, with the user door `editLayout` awaiting `ensureLoaded('authoring')` (`Widget.coffee:6317`) — RIGHT SHAPE; `createPointerWdgt` (`Widget:3518`) and `new DemoMenus if DemoMenus?` at boot, whose doors await `demos` — RIGHT SHAPE; `MacroToolkit:2203` — DEFENSIBLE (exact answer). The other spelling of the quiet fix, the class as a string, is C4. The one-line reading forced the icon override above |
| 2 | `check-unresolved-sends` → stub or soak | (a) every trivially-bodied method on 18 base classes with its overriders and callers; (b) every soaked send `x.name?(…)` / `x.name? …` whose name has no callable definition (the gate's own `lib/name-definitions.js`); (c) the transcript worker's 21 real firings | **No stub added for the gate found (VERIFIED for Widget's one-liners by date and commit; neither worker found one).** Widget's defaults (`_rowNameDistinction`, `graphEdgesOut`, `_seamRects`, `_layOutOwnContents` …) are template-method defaults its own code reads. **The quiet fix this gate actually drew is a third one: respelling a platform call it does not know — C9, four sites.** Soaks: none shown to be added for the gate; four dead ones stand — see §4. Allowlist (7 entries) all DEFENSIBLE |
| 3 | `check-dead-methods` → delete / keep alive | allowlist (10 entries); product members referenced only from the test side (script: 30) | No wrong deletion found (git worker: the `cd24c28d` four had no by-name reference). **Kept alive by a test only: `isDesktopShortcut` (C3).** `LabelButtonWdgt.setLabel` is test-only too but says so and is the public twin of a live core — DEFENSIBLE. Allowlist: see §3 |
| 4 | `check-layering` [D] → promote to public; [G]/tiers → fold or rename | `_x` → `x` renames in history (script: 5, each gained a product caller); test-only product members | **C2 (`isVisuallyTransformed`).** `SimpleSpreadsheetWdgt.hostedWidgetAt` ("a macro drags `sheet.hostedWidgetAt "A1"`, never the private cell index") is a public accessor written for macros, 2026-07-19 — UNSURE, it is a meaning-named query a script would want too. `ScrollIndicatorHostWdgt.buttonScreenBoxOnArrival` / `barScreenFrameOnArrival` / `barPartMetOnArrivalAt` (2026-11-21) have only `MacroToolkit` as caller — UNSURE, the product owns the derivation the toolkit must not copy; the test-side worker's area. No folded helper found. [A]-driven placement: C5 |
| 5 | `check-call-separation` [S]/[U] → tier rename; thin sanctions | all 42 `# public-call-sanctioned`; the allowlist; the `cd24c28d` sweep | **C1.** The 24 renames of 2026-11-06 are honest re-tiers (VERIFIED by the git worker: each `@`-self-called only). Residue: `LCLCodePreprocessor` now has 18 `_` pipeline steps beside 12 public ones that are equally self-only — UNSURE. Markers: see §3 |
| 6 | `instanceof-type-test` → type-named predicate / duck test | every constant-answer `is*` method; `constructor.name`, `widgetClassString() ==`, prototype-identity tests | **C3, C6, C7, C11.** `ToolPanelWdgt:79` (`grabbedWidgetSwitcheroo == Widget::grabbedWidgetSwitcheroo`) and `Widget:6132` date from 2018 / June 2026 naming work, not the stink — not counted |
| 7 | `check-hand-lists` → reflection / reshaped literal | word-split lists, all 42 `hand-list-sanctioned` lines, the transcript worker's 17 hand-list episodes | **C10 (a rig list replaced by reflection on the product's rule).** Reshapes: `Serializer._colorComponentsProblem` (unsure list above); a rig's two-name list moved into a per-case object field (`scripts/parts-snapshot-load-headless.js:423-444`) — DEFENSIBLE; a three-name `.every` list unrolled into three `&&` terms on 2026-11-10 — CONTORTION-UNDONE (the section left with mixin removal). No word-split list found. UNSURE: `Widget.isDerivedStateField` (`Widget.coffee:91-93`, `6e87c7fb`, 2026-11-05) replaced 19 listed cache names with a name-pattern rule one day before the gate landed — plan-driven; a field's NAME now decides whether it is saved. Settles it: is there a check that fails when a `cached*` field holds state that cannot be re-derived? |
| 8 | `IDENTICAL_OVERRIDE` → delete an override | `4921a02b` (2026-11-15) | RIGHT SHAPE (VERIFIED from its message: a before/after resolution map of every class, "every deleted member resolves to a function of the same hash"; I did not re-run it). Zero `identical-override-sanctioned` sites |
| 9 | `comment-narration` / `check-doc-narration` → delete a warning | script over every removed comment block since 2026-07-01 in `Fizzygum/src` that held a narration word AND a warning word (17 blocks), read against the comments added in the same hunk | **None lost (INFERRED from that scan).** The low-overlap ones went with deleted or moved code (`a2015c07`, `68cedf94`, `a70efe23`, `1e06b79f`). Docs side not scanned beyond the 7 real `narration-ok` markers, all reasoned |
| 10 | `check-plane-discipline` / `check-raw-pointer-reads` → wholesale map | sites whose comment cites the lint (`ToolTipWdgt:44-48`, `ViewportWdgt:1278`), zero sanction markers | None standing (VERIFIED for the cited sites: each maps one read, for a stated tilted-widget reason). The backlog's caret-slot case is not in git as a standing shape |
| 11 | others | public one-line wrappers over `_changed` (12); placeholder arguments; `ignored_*` parameters | The `note…Changed` methods are the prescribed, owner-directed shape (`863a1bfe`) — RIGHT SHAPE. No stuffed options object found. `check-menu-actions`' `ignored` naming is its stated convention. `check-source-vault`, `nil-literal`: nothing |

---

## 3. Sanction / allowlist census (row 12)

Counts are of the tree today (VERIFIED by grep; "tooling" lines exclude self-tests).

| Marker / list | Count | Reasons |
|---|---|---|
| `# public-call-sanctioned` | 42 (src) | all stated. Thinnest: "show is the heavily-public visibility verb (settle-free one-liner); consciously reused by this core" ×2 (`CaretWdgt:364,498`) and the `enableDrops`/`disableDrops` four — boilerplate but true. Four in `WorldWdgt` (`:2264,2287,2306,2542`) say "createErrorConsole stays public … rule [A] forbids the _-form" — the C1 pattern; `:2287` points at "its public-api-allowlist entry", which no longer exists (stale pointer) |
| `# nosettle-sanctioned` | 10 (9 src + 1 harness) | all stated; `MacroToolkit:686` sanctions an existence PROBE the gate reads as a call (a gate false positive, honestly labelled) |
| `# layout-apply-sanctioned` | 16 | ten read "scroll-input …, determinism-exempt (residuals-audit fam 1)" — a family exemption the lint doc names. `ViewportWdgt:753` reuses "public content-change endpoint" on a `_…NoSettle` method, which [F] does not judge: a superfluous marker with a copied reason |
| `# early-return-sanctioned` | 11 | all specific (`1b94ee27` added five at once, each argued) |
| `# double-settle-sanctioned` | 5 | all specific |
| `# thin-wrap-exempt` | 9 | all specific |
| `# cross-invalidation-sanctioned` | 16 (13 src + 3 harness) | all specific. Weakest: `FileLoading:97` (`widget._fullChanged?()` — "no receiver-side method seam for this") |
| `# macro-private-call-sanctioned` | 70 lines in 29 tests | all say what the oracle reads; 19 are the canonical `world._fullChanged()`. One DRIVES rather than reads: `doc._settleLayoutsAfter => doc._afterDeserialization()` (reason given: no public door plays a load on a live document) |
| `# hand-list-sanctioned` | 5 (4 src + 1 harness) + 37 tooling | each names a guard the gate resolves. `FourWayArrowIconAppearance:58` sanctions the two-item `["x", "y"]` — a detector false positive paid for with three comment lines |
| `# saved-content` / `# page-element-not-held` | 1 / 4 | specific |
| `# private-use-`, `relayout-bounds-first-`, `raw-screen-pointer-`, `escalated-pos-`, `constructor-build-`, `stringified-script-`, `identical-override-` | 0 each | — |
| `<!-- narration-ok -->` (living docs) | 7 real + 3 that document the marker | specific |
| `dead-method-allowlist.txt` | 10 | six LCL names kept "pending that subsystem's completion" (known, has its own plan); `asArray`, `getBody`, `bringUpTestMenu_InputEvents` kept as "intentional API … just currently unused" — the weakest reason standing, but stated |
| `unresolved-sends-allowlist.txt` | 7 | vendor / host / one closure-holding field — all DEFENSIBLE |
| `public-api-allowlist.txt` | 28 | **11 are C1.** Also thin: `scrollX` / `scrollY` ("sibling of scrollToBottom/setScrollPolicy, which macros call" — their only caller is `autoScroll`); `reactToTargetConnection` ("connection protocol hook", nothing more); `processDoubleClick` / `processTripleClick` ("dispatches to the settling drop") |
| stinks `sanctioned:` for `instanceof-type-test` | 3 | specific |

No marker with an empty reason and none that says only "needed" or "intentional" was found.

---

## 4. Side findings — not gate-driven, but they show a blind spot

A soaked send is invisible to `check-unresolved-sends` (its call pattern is `name(`, and `name?(` does not
match), so a method can be deleted and its soaked caller stays, silently doing nothing. Four stand (VERIFIED:
no callable definition anywhere in src or the harness):

- `Fizzygum/src/SwitchButtonWdgt.coffee:145` `@parent?.radioButtonWasSwitched? @` — the last implementor went
  in `97a7a647` (2026-08-26), whose message says it "survives as the capability its other consumers use";
  there are none. With it, `Fizzygum/src/ToggleButtonWdgt.coffee:14-15` tests two parent fields
  (`wantsButtonsToBehaveLikeRadioButtons`, `allowsRadioButtonsToBeAllDisabled`) nothing sets.
- `Fizzygum/src/basic-widgets/RectangularAppearance.coffee:84` `@drawAdditionalPartsOnBaseShape? …` — last
  implementor removed `e7c18775` (2026-10-21).
- `Fizzygum/src/events-input/KeyupInputEvent.coffee:10` `processKeyUp?` — documented in place as a no-op loop.
- `Fizzygum/src/dataflow/DataflowEngine.coffee:640` `node.dataflowApply?(newVal)` — documented as a reserved hook.

None was added to quiet the gate (INFERRED from dates: each soak predates its implementor's removal). They are
dead code a deletion left behind.

---

## 5. What I could not check, and counts scanned

- **Tree:** 37 cross-part existence guards; every trivially-bodied method on 18 base classes; every soaked
  member test in `Fizzygum/src` + the harness (3 + ~40 names without a definition, read one by one); 24
  constant-answer predicates; every sanction marker listed in §3 read with its reason; 117 source comments that
  cite a gate, read for "the gate made me" wording; 30 product members with only test-side references (11
  read). Macro sources were scanned for markers and references, not read as code.
- **Git (a forked worker, `static-audit-git.md` in the session scratchpad):** 1025 + 643 commits since
  2026-07-01 by message grep and targeted diffs; all three allowlists' full add/remove history; the
  `cd24c28d` renames one by one. Not reached: about 115 of 142 "sanction"/"allowlist" commit bodies; the
  2026-07-12 batch of 53 renames beyond a 25-name sample; diffs of the call-arguments conversions.
- **Transcripts and ledgers:** see the section below.
- **Not done:** I did not re-run any gate, proof or resolution map; verdicts of RIGHT SHAPE for `4921a02b` and
  for the lazy doors rest on reading. Row 7's object-keyed and regex forms of a reshaped list were not searched.
  Row 9 was a heuristic scan of `Fizzygum/src` only (not the harness, not the docs).

### Transcripts and ledgers (a forked worker, `static-audit-transcripts.md` in the session scratchpad)

- **Reached:** 31 of 32 main sessions and 538 of 542 subagent files (the running session excluded), by
  co-occurrence windows of a gate token and a quiet-fix phrase (166 broad hits read; 26 rule-[D] episodes; 21
  distinct real firings of `check-unresolved-sends`, 2 of `check-part-edges`, 4 of `check-hand-lists`
  extracted); 14 `LEDGER.md` files (76 lines naming a gate beside a quiet-fix word).
- **What that reading sees:** assistant and user text and the thinking that is present (mostly empty in these
  files). **Not swept:** Edit/Write inputs and tool results, so real firings of `check-dead-methods`,
  `check-call-separation`, `check-layering`, the stinks and `check-call-arguments` were not enumerated — a
  quiet fix made without a sentence about it is invisible here.
- **Reach in time:** transcripts start about 2026-10-15; July to mid-October is git only.
- **Not chased:** `5fae7abf` agent-ab L903 (`DRIFT_HOOKS` against the stale-sanction rule); `17e8eba8` L61610
  (`_scrollStep` macro reads removed for [D]); `3aefc39e` L641 (`.containing(`) and `0f0aec85` L3204
  (`.loadFont(`) firings.
- **Refusals of the quiet fix seen (RIGHT SHAPE):** a toolkit verb instead of product API for [D]
  (`MacroToolkit.sliderButtonPressPoint`, 2026-10-15); platform names added to `BUILTINS` (`.next(`,
  `getImageData`); `parts.json` `requires` corrected for `INHERITS_FROM_PART`; every `comment-narration`
  firing found (10+) was a new comment reworded, none a warning deleted.

### What nobody answered

- Whether the nine identical-override deletions of `4921a02b` changed what any reader of prototype OWNERSHIP
  sees (the commit's proof covers resolution, and "no pixel moved").
- Whether undoing C1's renames moves inspector references: it needs a build and the suite.

