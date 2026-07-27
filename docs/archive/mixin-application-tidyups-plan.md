# Mixin application tidy-ups (the inverse audit) — new edit-mode-bubbling mixin, Highlightable hoist, ratio-variant documentation

> **Status: EXECUTED IN FULL 2026-07-27** (authored 2026-07-26/27, owner-approved scope:
> all three items). Item A: `BubblesEditModeToCoordinatorMixin` created, three consumers
> converted (verbatim-diff gate passed; presuite green, zero pixel churn). Item B:
> `HighlightableMixin` + colour triple hoisted to `IconicDesktopSystemLinkWdgt` (3
> augments → 1, 9 colour fields → 3; the census `color_*` PULL-UP families dissolved);
> ONE benign one-digit ref churn — the mixin-edit test's save-confirmation popup counts
> live consumers, 9 → 7 — verified via `fg diffpage`, gated recapture COMPLETE at
> dpr 1+2. Item C: documentation landed as written (conversion stays falsified).
> Close gate: full gauntlet 13/13 green (capstone parallel run hit the documented
> CDP-launch infra flake, serial retry PASS). Written to be executed COLD; kept
> verbatim below.

**Mandate.** Complete the transformation each item names — land the new mixin, hoist the
injection, correct the documentation — not a partial gesture. Item C is deliberately a
DOCUMENTATION fix because the code change it replaces was FALSIFIED during authoring
(§3); do not "upgrade" it back into a conversion.

## §0 Orientation

Fizzygum is a CoffeeScript canvas GUI framework: no module system, every class a global,
sources ship as text and compile in-browser; `src/meta/Class.coffee`/`Mixin.coffee`
parse each source at runtime. Mixins (`src/mixins/`, applied via
`@augmentWith SomeMixin, @name`) are a **permanent mechanism with a narrow remit**
(standing policy + inventory: `docs/architecture/mixins.md`): behaviour that must be
INJECTED into classes on unrelated hierarchy branches (framework-hook overrides that
cannot delegate and have no shared base) stays a mixin; delegable responsibility becomes
a collaborator; single-consumer/single-subtree behaviour folds into the consumer/base.

The 2026-07-26 mixin program (all PUSHED): 5 misfiled mixins folded to standard OO
(`194e252d`), DeepCopierMixin → the `Duplicator` engine (`a70efe23`), live mixin
EDITING v1+v2+field-parity (`8fc41920`, `765284d8`, `58dcecc0` + tests through
`db953e498`). The owner then asked for the INVERSE exercise: find aspects of the
current source that would be BETTER as mixins. The audit ran `./find_duplicated_code.sh`
+ `./find_similar_code.sh` (reports regenerate into the gitignored
`duplication-report/`; `jscpd-report.ai.txt` / `jsinspect-report.ai.txt` are the
LLM-handoff lists) and both censuses
(`node buildSystem/census-hierarchy-duplication.js`, `census-property-placement.js`),
then hand-verified every candidate against the doctrine. Three items survived; they are
this plan. (Cross-branch duplication that did NOT survive — and must not be "rescued"
into mixins — is recorded in §6.)

**Critical reframe (read before item C):** the audit initially classified the two
`@ratio`-based copies of `KeepsRatioWhenInVerticalStackMixin` code as
"should just augment". Fact-checking FALSIFIED that: both classes implement a
*pinned-ratio field* variant that is semantically different from the mixin's
*current-aspect* sizing, and one of them documents its non-augment deliberately.
Item C fixes the documentation (including one factually wrong comment), it does not
convert.

## §0.5 Cold-execution protocol

1. Re-orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status` (expect both repos
   clean; if this plan is the only dirty/last-committed thing, proceed).
2. Read this plan fully, then `docs/architecture/mixins.md` §2–§3 (the doctrine, the
   editing machinery, the inventory you will update).
3. Line numbers in this plan were verified 2026-07-26 and DRIFT; the quoted code and
   method names are authoritative — re-grep before trusting any `file:line`.
4. Execute items in order A → B → C (A is the only new code; B is a move; C is
   comments/docs). Each item ends with its own gate (§5); close the arc with the full
   gauntlet.
5. Work straight through; ONE end-of-arc review. Do NOT commit/push without the owner's
   explicit word — present the summary + drafted commit message and wait.
6. Ratchet gates are absolute: `instanceof-type-test`, `undefined-literal`,
   call-separation counts stay at baseline — factor deeper, never baseline-bump.

## §1 Item A — NEW mixin: edit-mode bubbling to a coordinating parent

### Current state (verified 2026-07-26)

Three classes on UNRELATED branches override the framework's edit-mode-toggle CORES
with **byte-identical** ~10-line bodies (modulo their leading comments):

- `src/SimpleVerticalStackScrollPanelWdgt.coffee` (~:45,:55) — `extends ScrollPanelWdgt`
- `src/StretchablePanelWdgt.coffee` (~:94,:107) — `extends PanelWdgt`
- `src/StretchableWidgetContainerWdgt.coffee` (~:259,:272) — `extends Widget`

The enable core (the disable core is its mirror with `!@dragsDropsAndEditingEnabled`,
`showViewModeInBar`, `_disable...`):

```coffee
  _enableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.showEditModeInBar?()
    if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
      @parent._enableDragsDropsAndEditingNoSettle @
    else
      super @
```

Semantics: bubble the pencil/eye toggle UP to an editing-coordinating parent
(capability query `coordinatesDragsDropsAndEditingForChildren?()` — defined today only
on `StretchableWidgetContainerWdgt` ~:253; the query replaced an
`instanceof SimpleDocumentWdgt` type-test), else do the local Widget work via `super`.

The wider definition map (do not disturb): base public wrappers + cores on `Widget`
(~:4416–4460, cores take NO param); `ScrollPanelWdgt` (~:877–899) and `FrameWdgt`
(~:823–836) have their own wrapper+core variants (FrameWdgt's is a DIFFERENT short
relay — not part of the triple); the two Stretchables also define their own thin public
wrappers (`enableDragsDropsAndEditing`/`disable...`) around the cores.

### Why it is shaped this way

The three classes grew the same override independently as the pencil/eye edit-mode arc
and the type-test-elimination campaign touched each; no shared base below `Widget` is
possible (ScrollPanel / Panel / Widget branches), and the behaviour must BE each class's
own core override (the settle machinery dispatches to `_...NoSettle` cores
polymorphically) — delegation cannot express it. That is the mixin remit, verbatim.

### Fix shape

1. Create `src/mixins/BubblesEditModeToCoordinatorMixin.coffee` (owner may prefer a
   different name — rename freely at review; keep the `Mixin` suffix and one-class-per-
   file naming). Standard mixin shape (copy the skeleton of
   `KeepsRatioWhenInVerticalStackMixin.coffee`): header comment stating the contract
   (bubble the toggle to a `coordinatesDragsDropsAndEditingForChildren?()` parent, else
   local work via super; consumers override ONLY the cores — the public wrappers stay
   wherever they are today), then `onceAddedClassProperties` / `addInstanceProperties`
   with EXACTLY the two cores, moved verbatim (keep the load-bearing comment about
   "Only the COREs are overridden here" from SimpleVerticalStackScrollPanelWdgt — it
   explains the wrapper split).
2. In each of the three consumers: delete the two core methods, add
   `@augmentWith BubblesEditModeToCoordinatorMixin, @name` under the class line
   (matching the house form with the `@name` second arg). Do NOT touch the Stretchables'
   public wrappers or `coordinatesDragsDropsAndEditingForChildren`.
3. `super @` inside the moved bodies is the `super arg` form — supported by the mixin
   rewriter (all four forms since v2). The fake-super companion resolves
   `window[<Consumer>].__super__[<name>]` per consumer, which is EXACTLY what the
   class-compiled `super` resolved before (Consumer.__super__ is the same object) —
   semantics-exact per the fold-arc's proof. Verify per consumer that the super target
   is what it was: SimpleVerticalStackScrollPanelWdgt → ScrollPanelWdgt's core;
   StretchablePanelWdgt → PanelWdgt('s inherited Widget) core; 
   StretchableWidgetContainerWdgt → Widget's core (param-less base — passing `@` is
   harmless today and stays harmless).
4. GATE before deleting anything: verbatim-diff the three enable bodies and the three
   disable bodies against each other (`diff <(awk …) <(awk …)` or hand-eye) — they must
   be identical modulo comments/whitespace, as verified at authoring. If ANY body has
   drifted since, STOP and re-diff semantics before folding.
5. The dependency finder picks up the new `@augmentWith` edges automatically
   (`src/boot/dependencies-finding.coffee` regex); `build.py` auto-globs `src/mixins/`;
   the syntax gate drives any new mixin through the real `Mixin` class — no build-system
   edits needed.

### Risks

- Boot-order shadowing: none — after step 2 no consumer's class body defines the cores.
- Pixel churn: none expected (byte-identical behaviour). The suite decides.
- The mixin becomes live-editable in the inspector for free (v1/v2 machinery); its
  members list `<name>_class_injected_in` companions on consumer prototypes — normal.

## §2 Item B — apply `HighlightableMixin` at the right LEVEL in the desktop-link family

### Current state (verified 2026-07-26)

`IconicDesktopSystemLinkWdgt` (`extends WidgetHolderWithCaptionWdgt`, which
`extends Widget`; NEITHER defines any Highlightable-family member) has exactly three
direct subclasses, and EACH separately does:

```coffee
  @augmentWith HighlightableMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.BLACK
```

- `src/BinOpenerWdgt.coffee` (~:3–7)
- `src/IconicDesktopSystemShortcutWdgt.coffee` (~:19–23)
- `src/IconicDesktopSystemWindowedAppLauncherWdgt.coffee` (~:3–7)

The colour triples are IDENTICAL (census-property-placement's top PULL-UP findings).
None of the three shadows any Highlightable METHOD. The deeper descendants
(`IconicDesktopSystemDocumentShortcutWdgt`, `...ScriptShortcutWdgt`,
`...FolderShortcutWdgt`, all `extends IconicDesktopSystemShortcutWdgt`) declare no
Highlightable members either — they inherit the Shortcut prototype's injected ones.

### Why it is shaped this way, and the case law that blocks the naive fix

Each subclass grew its augment independently. A naive "pull the three colour fields up
to the parent" WITHOUT moving the augment is DEFEATED by injection: augmentWith writes
the mixin's defaults as OWN props on each subclass prototype, which would shadow any
parent-level field (archive INDEX ⚖ case law 11, `god-class-decomposition-plan.md`
era). The correct move hoists the INJECTION itself.

### Fix shape

1. In `IconicDesktopSystemLinkWdgt.coffee`: add under the class line
   `@augmentWith HighlightableMixin, @name` followed by the three colour overrides
   (verbatim from any subclass).
2. In each of the three subclasses: delete the `@augmentWith` line and the three colour
   fields. If that leaves an empty class-body section, tidy blank lines only.
3. Semantics proof to re-verify while executing:
   - Every current consumer keeps every member via the prototype chain (subclass
     prototype → IconicDesktopSystemLinkWdgt.prototype now carries the injections).
   - No descendant GAINS behaviour: all three direct subclasses already augment; the
     grandchildren already inherit through Shortcut. (Re-run
     `grep -rn "extends IconicDesktopSystemLinkWdgt" src --include="*.coffee"` to
     confirm no new subclass appeared since authoring.)
   - Fake-super target: HighlightableMixin's `mouseDownLeft` ends in bare `super`.
     Before: companion=`BinOpenerWdgt` → `BinOpenerWdgt.__super__` =
     IconicDesktopSystemLinkWdgt.prototype → (no own mouseDownLeft) → resolves up to
     `Widget.prototype.mouseDownLeft`. After: companion=`IconicDesktopSystemLinkWdgt`
     → its `__super__` = WidgetHolderWithCaptionWdgt.prototype → (defines no mouse*
     members — verified) → same `Widget.prototype.mouseDownLeft`. Identical resolution.
   - Serialization/duplication: prototype-level fields are not serialized; instances'
     own `@state` writes are unchanged. No compat concern (standing owner policy: no
     serialization compat obligations anyway).
4. Net: 3 augments → 1, 9 colour declarations → 3, and the two census PULL-UP families
   dissolve (re-run `node buildSystem/census-property-placement.js` and confirm the
   three `color_*` PULL-UP lines are gone; the census is advisory, this is a courtesy
   check, not a gate).

### Risks

- Inspector member lists of the three subclasses change (own → inherited, hidden by
  default). No SystemTest inspects these classes (verified: no test drives their class
  inspectors); if the suite disagrees, `fg diffpage` the failures before touching
  references.
- Hover/press pixels: identical values through the chain — zero churn expected.

## §3 Item C — document the two DELIBERATE pinned-ratio variants (conversion FALSIFIED)

### The falsification (do not re-attempt the conversion)

`Example3DPlotWdgt` (`extends Widget`, `src/graphs-plots-charts/`, ratio block
~:60–124) and `StretchableWidgetContainerWdgt` (`extends Widget`, ratio machinery
~:46–103, 122–178) both carry hand-written ratio protocols that jscpd/jsinspect flag as
clones of `KeepsRatioWhenInVerticalStackMixin` (`src/mixins/`, 6 members). Verified
reality: they share only the two 3-line `_reactToHolderFrame*` relays and the middle
block of `_freeFromRatioConstraints`; the SIZING pair differs by design —

- mixin: CURRENT-ASPECT — `_setWidthSizeHeightAccordingly` recomputes
  `@height()/@width()` each call; no stored state; no super-fallback.
- both variants: PINNED `@ratio` FIELD — captured at `_constrainToRatio` time
  (Example3D) or lazily/content-aware (Stretchable, plus public
  `setRatio`/`resetRatio`), sizing falls back to `super` when unpinned; Example3D also
  wires the DIRECT drop/grab hooks (`_reactToBeingDropped`/`_reactToBeingGrabbed`) in
  addition to the holder-frame pair.

Augmenting would inject 6 members of which 4 would be immediately shadowed by
class-body definitions — technically legal under the boot-order rule, but noise
(an "augments-but-overrides-most-of-it" read). The D6 aspect contract (header of the
mixin file, from `docs/archive/sizing-model-unification-plan.md` §9.8) explicitly
blesses per-class measure twins, so unifying the two protocols fights a settled design.

### What to actually do

1. `StretchableWidgetContainerWdgt.coffee` ~:72–78 — the existing comment's REASON is
   factually wrong post-boot-order-rule ("augmenting it here would clobber my own
   content-aware pair" — it would not: class-body members always win over injections,
   the July 2026 mixin arcs re-proved it). Rewrite the parenthetical to the TRUE
   reason. Suggested text (adapt in place, keep the surrounding lines):

   ```
   # (Hand-written, NOT the mixin -- deliberately: my sizing pair is the PINNED
   # @ratio variant (content-aware, super-fallback), so augmenting would inject six
   # members only to have four immediately shadowed by my class body -- legal under
   # the boot-order rule (class body wins), but a misleading "augments-yet-overrides-
   # most-of-it" read. Only these two 3-line relays would survive; not worth it.)
   ```

2. `Example3DPlotWdgt.coffee` — add the equivalent short comment above its ratio block
   (~:60), which today has NO note about the mixin at all; mirror the wording, noting
   its variant pins `@ratio` at constrain time and adds the direct drop/grab hooks.
3. `docs/architecture/mixins.md` §3 inventory, KeepsRatioWhenInVerticalStackMixin row:
   add one sentence naming the two deliberate pinned-ratio NON-consumers and pointing
   at their in-file comments (so the next duplication audit doesn't re-flag them
   blind).

## §4 Documents to update (same arc, not afterwards)

- `docs/architecture/mixins.md`:
  - §3 inventory: NEW row for the edit-mode mixin (3 consumers, member list, remit);
    Highlightable row: consumer set changes (3 subclass files → 1 parent file — recount
    the header's "N mixins, M L, K consumer files" line by re-grepping);
    KeepsRatio row: the §3-item-C sentence.
  - §2 nothing structural changes (the editing machinery is untouched); do NOT add
    chronological notes (present-tense doc).
- In-file comments per §1/§2/§3 above (comments are a deliverable — owner preference).
- At arc CLOSE: `git mv` this plan → `docs/archive/`, stamp the status header
  EXECUTED with the verification results, add the `docs/archive/INDEX.md` line
  (section "OO cleanup, lint & modernization", alphabetical) with ⚖ bullets for
  (a) the item-C falsification and (b) case-law-11 applied-in-reverse (hoist the
  injection, not the fields).
- Memory: update the owner-memory topic file + MEMORY.md index line at close.

## §5 Verification protocol

- After EACH item: `/Users/davidedellacasa/code/Fizzygum-all/fg build` then
  `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (background it, redirect to a
  log, wait for the task notification; never foreground-poll — read
  `/tmp/fg-presuite.verdict`).
- Expected: ZERO pixel churn for A and B, zero everything for C. Any suite failure →
  `fg diffpage <names>` and diagnose BEFORE touching references; recapture only via the
  gated `fg recapture <names>` and only for verified-benign diffs (none are expected —
  treat any as a defect first).
- Suite-leak awareness (case law from the mixin-editing arc): these conversions do NOT
  edit mixins at runtime, so no restore-tail concerns; but if you write any new
  SystemTest that DOES edit a mixin/class, its macro must restore in its tail
  (`src/macros/MACRO-PATTERNS.md`, the mixin-editing entry).
- Optional deep sanity for item A/B: the 40-check functional probe
  `Fizzygum-tests/.scratch/mixin-edit-probe.js` (gitignored; needs a fresh build) —
  it exercises Highlightable's injection machinery on ButtonWdgt and is UNAFFECTED by
  the hoist (ButtonWdgt augments directly); a pass confirms the meta-machinery intact.
- Arc close: full `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet` (background,
  ~5 min, 13 legs) — must be green before the end-of-arc review.

## §6 Rejected alternatives (do not re-attempt)

- **Augment the two ratio-variant classes with KeepsRatioWhenInVerticalStackMixin** —
  falsified 2026-07-26 (§3): 4-of-6 members shadowed, protocols genuinely differ.
- **Unify the current-aspect and pinned-ratio protocols into one parameterized mixin**
  — fights the D6 aspect contract's by-design per-class measure twins; touches 5
  consumers + 2 variants for ~30 saved lines; declined at authoring.
- **Pull up the colour fields WITHOUT hoisting the augment** (item B) — defeated by
  injection shadowing (⚖ case law 11); the fields would be dead text.
- **Mixins for the OTHER audit findings** — the 9-class paint-prologue family
  (AnalogClock/Pen/HandleWdgt/LayoutChrome/GraphsPlotsCharts/Example3DPlot/LabelButton/
  CellWdgt/SheetHeaderCell) belongs to the APPEARANCE-delegation seam (its own future
  arc; biggest LOC win in the codebase); the code-area-with-run-buttons family
  (Console/Script/CodePrompt/ErrorsLogViewer, all `extends Widget`) wants a shared
  BASE class (the fold-arc's IconicDesktopSystemPanelWdgt shape); the
  `stringSetters`/`numericalSetters`/`colorSetters` triples are per-class DATA in a
  shared idiom (correctly class-side, like serialization hooks); the small pairs
  (centered-square icon math, wheel normalization, pixel-alpha `isTransparentAt`) want
  plain shared helpers. None of these are mixin material; do not convert them here.

## §7 References

- `docs/architecture/mixins.md` — doctrine, inventory, the editing machinery this arc
  gets for free.
- `docs/archive/mixin-editing-v2-plan.md` + its INDEX ⚖ bullets — the editing arc +
  the two hard-won gotchas (edit-leak restore tails; never `evaluateString` on a
  prototype).
- `docs/archive/sizing-model-unification-plan.md` §9.8 — the D6 aspect contract
  (item C's design backdrop).
- `duplication-report/` (gitignored, regenerate with `./find_duplicated_code.sh` /
  `./find_similar_code.sh`) — the raw clone evidence behind §1/§6.
- Root `CLAUDE.md` — build/test wrappers (`fg`), long-op discipline, shell gotchas.
