# Layout spec-family follow-ups — division-cell product surface, content-stack drop-slots, dock completion

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-04, hours after its parent arc closed; every citation verified against Fizzygum
`c9f84d4c` / Fizzygum-tests `ac50cbfdc` (both pushed, all gates green). ⚠ Line numbers drift — quoted
method/class names are authoritative; re-grep before trusting a line.

**MANDATE.** Finish what the parent arc opened: every knob the layout spec family carries must be
reachable by DIRECT MANIPULATION (menus/setters/drop-slots), not only programmatically — and the two
items the parent arc consciously left (content-stack drop-slots; the frame's `right`/`bottom` dock)
get closed or explicitly re-banked by the owner. No new mechanisms: everything here rides the family,
the engine, and the idioms the parent arc landed.

---

## §0 Orientation

**Fizzygum** — CoffeeScript canvas GUI framework, ~505 classes, no modules; build/test via the `fg`
wrapper (`fg build` / `fg presuite` ~2 min / `fg gauntlet` ~5 min, launched ONCE in background with a
log; peek via `cat /tmp/fg-<cmd>.verdict`). Read `Fizzygum/CLAUDE.md` + `docs/architecture/layout.md`
(§4.2 is the spec-family reference, §8 the new-layout rulebook) before touching anything.

**The parent arc** (`docs/archive/layout-spec-family-unification-plan.md`, executed 2026-08-04 —
its §11 ledger is the full record): the `LayoutSpec` enum + loose per-widget box fields are GONE.
A child carries ONE spec object in `Widget.layoutSpec` (nil = free-floating); the division machinery
lives in the axis-parameterized `StackLayoutEngine` (three-regime min/desired/max division of either
axis; cross axis stretches or start/center/end-aligns per `DivisionStackLayoutSpec.crossAlign`);
the divider (`StackElementsSizeAdjustingWdgt`) drags exactly on either axis; "edit layout" on a
division container's context menu shows drop-slot adders (`LayoutElementAdderOrDropletWdgt` +
`LayoutSpacerWdgt`, both in the LAZY `authoring` part; `Widget.editLayout` awaits it); border
layouts are COMPOSITION (see `WidgetFactory.createBorderLayoutScaffold`). Suite: 274 tests.

**Why this plan exists:** the parent arc left five follow-ups, one of them a planned-but-unexecuted
item (F2 below), one a small correctness omission (F0-1), and one an old BACKLOG debt the arc's
machinery makes newly cheap (F4).

---

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — expect both repos at/past
   `c9f84d4c`/`ac50cbfdc`, clean; if src moved since, re-grep every symbol cited below.
2. Read `docs/architecture/layout.md` in full, then this plan, then skim the parent plan's §11
   ledger (`docs/archive/layout-spec-family-unification-plan.md`) — the idioms F1/F2 copy live there.
3. Execute phases in order F0→F5. Every phase: edit → `fg presuite` (background, wait for the
   notification) → classify any diff BEFORE recapturing (`fg diffpage <test>` + eyeball; the ONLY
   pre-authorized churn is what each phase names). Phase close: `fg gauntlet`; after any
   parts/menu/production-relevant change also `fg homepage`. Recaptures via
   `fg recapture <names…>` (gated) only after diffpage confirmation.
4. ⚠ Never edit src or tests while a suite/gauntlet/recapture runs. ⚠ Use the Edit tool for .coffee
   (perl in-place edits have de-indented CoffeeScript before). Two falsified fix shapes on one
   problem = stop and re-frame.
5. F4 is OWNER-GATED: present the phase summary and ask before starting it. Commits: present
   messages at the end (git commit -F <file>), never commit/push without the owner's word.

---

## §1 Current state (verified at `c9f84d4c`)

- **Division cells have NO user-facing knob surface.** `VerticalStackLayoutSpec` elements get the
  "layout in stack ➜" context submenu (base width / elasticity / align, each a self-settling setter
  that settles on `@element` — `VerticalStackLayoutSpec.coffee`, the `setAlignmentToLeft`…
  `_setDesiredWidthNoSettle` family, all `thin-wrap-exempt` commented). A DIVISION cell has nothing:
  `DivisionStackLayoutSpec` has NO `element` back-ref, NO setters, NO menu hook — its box is edited
  only via the widget-level `setMinAndMaxBoundsAndSpreadability`/`setMaxDim` or the divider drag,
  and `crossAlign` is construction-time only (set as a field before add; the parent arc's
  `macroDivisionCrossAlignment` fixture does exactly that).
- **The menu gate**: `Widget.addWidgetSpecificMenuEntries` shows "edit layout"/"done editing layout"
  on widgets where `@_divisionChildrenAxis()?` — i.e. division CONTAINERS with at least one child.
  Content stacks (`SimpleVerticalStackPanelWdgt` — documents!) and EMPTY containers get no entry.
- **Content stacks have no drop-slots.** `_addOrRemoveAdders` is invoked only from
  `StackLayoutEngine.arrange` (division stacks); a document/stack accepts drops with a silent
  index-from-drop-Y (`SimpleVerticalStackPanelWdgt._addNoSettle`) and shows no slot affordance.
  This was in the parent plan's P4 text and consciously NOT executed (ledger records the scope).
- **F0-1 omission:** `buildSystem/parts.json` `dev-tools` declares `requires: ['demos', 'app-kit']`
  but its three `whenAllLoaded ["authoring"]` awaits (in `WidgetFactory`:
  `createNewLayoutElementAdderOrDropletWdgt`, `setupTestScreen1`) have no matching INCLUSION
  declaration — per dev-tools' own `//requires` comment doctrine ("the await is the timing half,
  this line is the other half (inclusion)"), `'authoring'` belongs in that list. The gate discounts
  requires-to-lazy when scanning, so this is a declaration gap, not a build break.
- **F0-2 stale comment:** `LayoutChromeWdgt.coffee` header still says the halo inserts the adjuster
  "around horizontal-stack siblings" (it is axis-aware now) and frames the spacer/adder as
  editing-only scaffolding without naming their new home (the lazy `authoring` part,
  product-reachable via "edit layout").
- **F0-3:** `src/macros/MACRO-PATTERNS.md` teaches only the 'x'-row recipe; the vertical-division
  (`divisionBox('y')`), `crossAlign`, and border-composition recipes exist only in the three new
  tests.
- **`removeAdders`** is public but not the canonical self-settle shape (`@_showsAdders = false;
  @_invalidateLayout()` — rides the end-of-cycle flush; passes the capstone gate today).
- **F4 debt:** `ToolbarWdgt.dockSide` `'right'`/`'bottom'`/`'float'` are reserved values with no
  arrange support (`app-kit/ToolbarWdgt.coffee` ~:18, `docs/BACKLOG.md` "§5.C follow-ons" line —
  incl. the "undock-to-float context-menu entry (D9 tail, never a bar button)"). `FrameWdgt`'s
  arrange places only 'top' (full-width strip under the title bar) and 'left' (column beside the
  content); the chrome math is `_topDockThickness`/`_leftDockThickness`/`_chromeWidth`/`_chromeHeight`.
- **Tests that pin the area** (all green at `ac50cbfdc`): macroStackDividerFollowsPointerExactly
  (+Vertical), macroVerticalDivisionBorderSkeleton, macroDivisionCrossAlignment, the 6 layout/spacer
  macros, 3 submenu-navigation tests (recaptured for the "border layout scaffold" demo-menu row —
  NB any NEW demo-menu row churns them again).

## §2 Why it is shaped this way

The parent arc unified the MECHANISM and deliberately kept product-surface work minimal (owner
review scoped P4/P5 to the division-container toggle + dev factory). The VSLS side has years of
product surface (menu + setters) because documents needed it; the division side never had users
until the arc made it general. Content-stack drop-slots were planned but the adder machinery is
division-shaped (engine-invoked, division-attached), so the content variant needed its own design —
deferred rather than rushed.

## §3 The distilled argument

Direct manipulation is the point of Fizzygum, and the family now has exactly ONE under-served spec
class. Every ingredient exists and is proven: the settle-on-element setter idiom (copy VSLS
verbatim), the spec menu hook (`addWidgetSpecificMenuEntries` on the spec, dispatched from the
widget's gate), the adopt-on-arrange behaviour of content stacks (which makes content drop-slots
STRUCTURALLY simpler than the division ones — a droplet added with NO spec is adopted as a stack
element automatically), and the axis-parameterized engine (which makes right/bottom docks a
transpose, not a feature). Doing these now, while the arc's case law is fresh, is the cheap moment.

---

## §4 Phases

### F0 — hygiene batch (no pixels; ~half an hour)
1. `parts.json`: `dev-tools.requires` += `'authoring'`, with a one-line `//` note mirroring the
   existing doctrine comment (inclusion half; the awaits are the timing half).
2. `LayoutChromeWdgt.coffee` header truth-up: axis-aware halo insertion; spacer+adder live in the
   lazy `authoring` part and are product-reachable via "edit layout" (divider + base stay core).
3. `MACRO-PATTERNS.md`: add the vertical-division recipe (`holder.add cell, nil,
   cell.divisionBox('y')`), the `crossAlign` knob, and a pointer to
   `macroVerticalDivisionBorderSkeleton` as the border-composition template.
Gate: `fg presuite` byte-identical; `fg gauntlet` parts leg (the requires edit) + `fg homepage`.

### F1 — division-cell product surface
1. `DivisionStackLayoutSpec` gains `element: nil`, bound where the box is materialized
   (`Widget._ensureDivisionBox: @_divisionBox ?= …; @_divisionBox.element ?= @` — bind
   unconditionally there; the box never changes owner).
2. Self-settling setters ON THE SPEC, copying the VSLS idiom verbatim (public wrapper =
   `@element._settleLayoutsAfter => @_<name>NoSettle …`, ALL logic incl. the already-in-state guard
   in the core, core ends `@element._invalidateLayout()`; mark each `# thin-wrap-exempt:` exactly as
   VSLS does — rule [H]): `setCrossAlignToStretch/Start/Center/End` (four wrappers over one
   parameterized `_setCrossAlignNoSettle`, named separately because menus address BY NAME),
   `setDesiredMainDim`, `setMaxMainDim` (prompt-adapter signatures like VSLS's
   `setDesiredWidth` — value-or-widget-giving-value; they write the box pair for the spec's CURRENT
   `axis`: desiredWidth/maxWidth under 'x', desiredHeight/maxHeight under 'y').
3. Menu: `DivisionStackLayoutSpec.addWidgetSpecificMenuEntries` + a `rowCellMenu` popout —
   "layout in row ➜" (under 'x') / "layout in column ➜" (under 'y') with: "desired size...",
   "max size...", and the four cross entries ("cross: stretch/start/center/end", current one
   omitted, mirroring vertStackMenu's alignment pattern). Dispatch from the widget gate: in
   `Widget.addWidgetSpecificMenuEntries`, next to the existing `isStackElementActive` branch, add
   `else if @layoutSpec?.isDivisionElement?()` → `@layoutSpec.addWidgetSpecificMenuEntries …`.
   ⚠ Exclude the chrome: gate the branch on `!@isLayoutAdderOrDroplet?()` and not-a-divider
   (`@ instanceof StackElementsSizeAdjustingWdgt` is a type test — use the existing
   `detachesWhenDragged`-style capability or add `isLayoutChrome?()` on `LayoutChromeWdgt`).
4. Retire the dev-menu duplication for the covered case: in `DemoMenus`, drop the
   "show adders"/"remove adders" pair ONLY if the owner confirms (they still cover content stacks
   until F2 lands — safest: retire them in F2, note here).
Gates: `fg presuite` — expect ZERO churn (no existing test opens a division cell's context menu;
verify, don't assume); dead-method gate will demand every new setter has a caller — the menu
strings ARE the callers (quoted names count); [S]/[U] follow the VSLS precedent (spec setters are
public, settle on element). New test: `macroDivisionCellMenuEditsSpec` — build a row, open a cell's
context menu, drive "cross: center" + "max size..." via the menu (clickMenuItemOfWidget /
prompt-driving verbs exist in the toolkit — crib from tests that drive the VSLS menu), assert
placement changed accordingly (value-asserts preferred; screenshots only if menu-driving needs them).

### F2 — content-stack drop-slots (the unexecuted P4 remainder)
Design (settled here, execution refines): "edit layout" extends to CONTENT stacks —
1. Menu gate: `Widget.addWidgetSpecificMenuEntries`' edit-layout branch also fires when
   `@_reLayoutChildren?` and the widget is a content stack (capability: SimpleVerticalStackPanelWdgt
   defines something like `hostsContentStackDropSlots: -> true`; NOT on FrameWdgt — a window's
   content is one widget, slots are meaningless; NOT on MenuRowsPanelWdgt — menus are not
   user-editable layouts, `_acceptsDrops: false` already says so).
2. `showAdders` on a content stack inserts droplets BETWEEN `childrenNotHandlesNorCarets` (and at
   both ends) with NO spec — the stack's arrange ADOPTS them as elements (VSLS captures desired 15,
   grow 0 ⇒ a thin full-visibility slot row). The droplet's `_reactToChildDropped` already inserts
   the payload as its own sibling — for a content-stack droplet the insert must pass NO
   division spec (nil): make the droplet axis/mode-aware via its OWN active spec
   (`if @layoutSpec?.isDivisionElement?()` → current behaviour, else sibling-insert with nil and
   let the stack adopt). Maintenance: the stack's `_positionAndResizeChildren` calls the adder
   reconciler when `@_showsAdders` (mirror the engine's hook; the existing
   `_insertAddersSuchThat` scan generalizes — its filters currently check `isDivisionElement`;
   parameterize the membership predicate).
3. "done editing layout" (removeAdders) already destroys by `isLayoutAdderOrDroplet` — extend its
   filter the same way (it currently also requires `isDivisionElement`).
4. Convert `removeAdders` to the canonical self-settle shape while touching it
   (`@_settleLayoutsAfter => @_removeAddersNoSettle()`), core holds the guard + work.
5. Retire the DemoMenus "show adders"/"remove adders" pair (dup of the product entries once both
   families are covered) — churns the 3 submenu-navigation tests AGAIN (menu one row shorter ×2):
   diffpage-confirm + `fg recapture` them; batch with F1/F2's other recaptures.
Gates: presuite (expect churn ONLY in the retired-menu tests); new test
`macroDocumentEditLayoutDropSlots` — a document/stack with 2 paragraphs, "edit layout", drop a
rectangle ONTO a droplet, assert insertion position + screenshot the slot look; `fg gauntlet`.
⚠ RISK: droplet adoption gives it VSLS capture semantics (desired 15 grow 0) — if the slot row
renders wider/odd, the fallback design is explicit `initialiseDefaultVerticalStackLayoutSpec` +
`grow = 0` at insert time. ⚠ The document is a SCROLL panel wrapping the stack — "edit layout"
must land on the INNER stack (the context-menu target the user right-clicks may be the scroll
frame; route via the existing contained-panel notification chain or gate the capability on the
stack and let menu composition surface it — spike this FIRST, it is the phase's one unknown).

### F3 — y-axis crossAlign coverage
`macroDivisionCrossAlignment` covers 'x' only. Extend IT (don't add a test): a second fixture
holder in the same macro built with `divisionBox('y')` cells crossAlign start/center/end (cross =
horizontal), one screenshot before + after a width change. Recapture that one test (gated), update
its metadata prose. (The engine path is shared by construction; this pins the transpose.)

### F4 — frame dock `right`/`bottom` + undock-to-float (OWNER-GATED — ask before starting)
Closes the BACKLOG "§5.C follow-ons" line. NOT spec-family work (frame chrome), but the transpose
is now idiomatic:
1. `FrameWdgt`: `_rightDockThickness`/`_bottomDockThickness` twins; `_chromeWidth`/`_chromeHeight`
   gain the right/bottom terms; the arrange's toolbar-slot branch gains the two placements
   ('right' = column at `right() - padding - dockThickness`, content region shrinks from the
   right — the content-centring math (`contentRegionLeft`, `leftPosition`) must subtract BOTH side
   docks; 'bottom' = full-width strip above `bottom() - padding - dockThickness`, content height
   loses it via `_chromeHeight`). ⚠ resizer overlap: the bottom-right resizer sits over a
   right/bottom dock — decide (inset the dock, or accept overlap as 'top'/'left' do with content
   when `resizerCanOverlapContents`).
2. Undock-to-float: a context-menu entry on the frame (D9: NEVER a bar button — the BACKLOG line
   records that owner ruling) that floats the docked toolbar as its ToolbarCreatorButton float form
   — check `onion-widget-composition-plan.md` §5.C for the float-home mechanism before designing.
3. Test: extend or clone a toolbar-bearing frame test to dock right + bottom, screenshot each.
Expect ZERO churn outside the new coverage (no existing content uses these values).

### F5 — docs + close
`layout.md` §4.2 scaffold paragraph (content-stack slots + the cell menus), `BACKLOG.md` (close the
§5.C line if F4 ran; else annotate re-banked-with-reason), archive INDEX line, this plan →
`docs/archive/` stamped, memory updated, ONE end-of-arc review, commit messages presented.

---

## §5 Rejected / do-not-re-attempt (carried from the parent arc + this plan's own calls)

- No horizontal CONTENT stack, no grid/table spec families, no FractionalPlacementSpec migration
  (desired-geometry channel by classification), no FF singleton spec, no re-litigation of D2-def /
  §9.7-Q / hug-suppression (multiply falsified — parent plan §7).
- Widget-level `setMinAndMaxBoundsAndSpreadability`/`setMaxDim` STAY (divider + factories + macros
  call them; F1's spec setters are the product face, not a replacement — deprecating the widget
  face is churn without payoff).
- crossAlign for the DIVIDER cells themselves: no (chrome stretches; aligning a divider is meaningless).

## §6 Verification protocol

Per batch: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (background + log + verdict file).
Per phase: `fg gauntlet`; `fg homepage` after F0 (parts) and any phase touching menus/production
reachability. Recaptures: `fg diffpage <test>` + eyeball FIRST, then `fg recapture <names…>` and
require "✅ RECAPTURE COMPLETE". Single test: `fg test <name>`. The known-churn ledger for this plan:
the 3 submenu-navigation tests (any demo-menu row change), macroDivisionCrossAlignment (F3),
and the inspector member-list test iff Widget's prototype membership changes (diffpage-verify, then
recapture — case law: benign-inspector-recapture).

## §7 References

`docs/architecture/layout.md` §4.2/§8 · `docs/archive/layout-spec-family-unification-plan.md`
(§11 ledger: the stash lifecycle, role bit, [D]-forced public `divisionBox()`, whenAllLoaded
gallery wrap, the [G]-exposure) · `VerticalStackLayoutSpec.coffee` (the setter/menu idiom F1
copies) · `docs/plans/onion-widget-composition-plan.md` §5.C (dock/toolbar float homes, F4) ·
`docs/BACKLOG.md` §5.C follow-ons line · memory: `layout-spec-family-plan-authored`,
`ask-before-commit-push`, `stop-iterating-fix-shapes-after-two-falsifications`.

## §8 Execution ledger (append per phase; empty at authoring)

### Pre-flight fact-check — DONE 2026-08-04 (execution session)
- Baseline confirmed: Fizzygum `c9f84d4c` / tests `ac50cbfdc`, clean (only this plan uncommitted),
  gauntlet 14/14 green at 19:00, 274 tests. Every §1 claim re-verified against src. One miscount:
  dev-tools has TWO `whenAllLoaded ["authoring"]` awaits (WidgetFactory :33
  createNewLayoutElementAdderOrDropletWdgt, :175 setupTestScreen1), not three — fix unchanged.
- Discovered adjacent staleness (F0 scope, same class as F0-2): `Widget.coffee` comment block above
  `removeAdders` still said the chrome lives in 'dev-tools' and production lacks it (it is in the
  LAZY 'authoring' part, product-reachable); also `parts.json` dev-tools' own "//" description still
  claimed the part contains the layout-editing chrome.

### F0 — hygiene batch, 2026-08-04
- 1. `parts.json`: dev-tools `requires` += 'authoring'; its "//" description corrected (chrome is in
  'authoring', not here) and "//requires" doctrine comment extended to name the two authoring awaits.
- 2. `LayoutChromeWdgt.coffee` header truth-up: axis-aware halo insertion (axis read off the
  neighbouring cell's spec), spacer+adder homed in lazy 'authoring', product-reachable via
  "edit layout". PLUS the discovered `Widget.coffee` block above `removeAdders` (see pre-flight).
- 3. `MACRO-PATTERNS.md` Layout section: three new entries — vertical-division recipe
  (`divisionBox('y')`, one-axis-per-parent warning), crossAlign knob, border-composition template
  (pointing at `macroVerticalDivisionBorderSkeleton` + `createBorderLayoutScaffold`).
- Gate: `fg presuite` PASS 19:25 (dpr1 57s + paint 87s), zero churn. **F0 CLOSED 19:30: FULL
  GAUNTLET GREEN, all 14 legs (252s) + `fg homepage` GREEN** (production boots from the pre-compiled
  image, lazy parts on demand, snapshot round-trip clean; dev build restored).
- Noted for F5 (pre-existing, not F0's doing): the build's [call-separation] gate prints two
  ratchet NOTEs — `[U]` allowlist entry `ensureLoaded` no longer self-only-public (delete from
  public-api-allowlist.txt) and `[U] QUERY: 127 < baseline 131` (tighten BASELINE_U_QUERY).

### F2 — content-stack drop-slots, 2026-08-04
- **The spike resolved by reading, no code needed:** the document's `@contents` IS the stack
  (`SimpleVerticalStackScrollPanelWdgt` ctor passes it to `super`), `takesOverAndMergesChildrensMenus`
  is false for documents, and the SVSSP menu override ALREADY reaches into `@contents` (the
  editing-lock entries) — that precedent is the routing: the document surfaces the toggle on its
  own menu, entries TARGET the inner stack.
- Landed: `SimpleVerticalStackPanelWdgt.hostsContentStackDropSlots` (= `@_acceptsDrops`, so
  `MenuRowsPanelWdgt` self-excludes for the stated reason); `_reconcileContentDropSlots` (content
  twin of the engine hook, called at `_positionAndResizeChildren` top; spec-less droplets the
  arrange ADOPTS); `_insertAddersSuchThat` gains a membership-predicate param (content:
  `!isLayoutInert`; axis nil ⇒ spec-less — ⚠ NO CoffeeScript default on axis, nil is meaningful);
  widget menu gate extends to `hostsContentStackDropSlots?()` via extracted
  `addLayoutEditingMenuEntries` (also called by SVSSP on `@contents`); `removeAdders` converted to
  the canonical wrapper over `_removeAddersNoSettle`; droplet `mouseClickLeft`/`_reactToChildDropped`
  mode-aware off their OWN spec; DemoMenus "show adders"/"remove adders" pair RETIRED.
- **TWO LATENT PARENT-ARC BUGS found and fixed — the division flavour's reconciler was mid-pass
  ILLEGAL both ways, undetected because NO test had ever driven "edit layout"** (this phase's tests
  are the first): (1) INSERT: passing the division box as the add's layoutSpec made
  `Widget._addNoSettle`'s new-container invalidate reach a NON-freefloating child mid-pass ⇒
  FLOWRULE throw. Fix: the reconciler inserts the adder SPEC-LESS (an FF child's add-invalidate is
  the sanctioned silent no-op) then ACTIVATES the division attachment via the non-scheduling
  `_setLayoutSpec` — the stack-adoption idiom. (2) DESTROY: `_fullDestroyNoSettle` of a
  spec-carrying adder made the teardown's parent-invalidate throw the same way. Fix: detach the
  spec first (`_setLayoutSpec nil`), both reconcilers. Also: the destroy sweeps are now DIRECT
  children (were deep `collectAllChildren…` + isDivisionElement conjunct) — a deep sweep would
  destroy a NESTED content stack's slots on every not-showing division arrange; each container's
  toggle owns its own adders.
- En route falsification (mine): `axis = nil` as the content sentinel was swallowed by the
  CoffeeScript default `axis = 'x'` (defaults replace undefined!) — probe-diagnosed via an
  instrumented `_setLayoutSpec` (probes kept in `Fizzygum-tests/.scratch/probe-*`).
- New test `SystemTest_macroDocumentEditLayoutDropSlots` (3 refs dpr1+2, 7 value asserts, all
  green at capture verify): document → hierarchy → the document's own menu → "edit layout" (3
  slots), drop a lime rect ONTO the middle slot (lands exactly between the paragraphs, 4 slots
  re-form), "done editing layout" (0 slots, 3 elements stay). Macro nav gotcha recorded in-test:
  the inner stack FILLS the viewport (loose + floor), so every in-document right-click opens the
  HIERARCHY menu — descend by "a SimpleDocumentScrollPanel"; and editLayout's ensureLoaded
  microtask needs one extra wait before asserting.
- Pre-existing bug OBSERVED for BACKLOG (not fixed here): the in-world error console
  (`ErrorsLogViewerWdgt`) itself commits degenerate/inverted child bounds while being built
  (`NON_INTEGER_GEOMETRY … [12@25 | 38@15]` cascade whenever it pops).
- Gates: presuite 20:16 — failing set EXACTLY the pre-authorized four (3 submenu tests + the
  duplicated-inspector member-list test), nothing else; the new test rides green. Churn classified
  BEFORE recapture: `fg classify` first returned stale F1-era artifacts (⚠ it reads the existing
  diff-page dump — run `fg diffpage <names>` fresh first); fresh diffpage: 8/14 BENIGN?row (pure
  submenu 2-row-loss translations), 6 REVIEW eyeballed — dragging-menus shots show exactly the
  retired pair gone (all other rows identical), inspector shots are the canonical member-list
  window shift (`addLayoutEditingMenuEntries` sorts above `alpha`, revealing `allSetters`;
  inspected values identical). Gated recapture of the four: ✅ RECAPTURE COMPLETE (full suite
  green at dpr1+2). Division-flavour END-TO-END PROOF (no SystemTest drives it):
  `.scratch/probe-division-edit-layout.js` — showAdders on a 3-cell row ⇒ 4 division-attached
  adders, removeAdders ⇒ 0, ZERO console errors.
- **THIRD latent find, caught by the first gauntlet's CAPSTONE leg (13/14 green, capstone FAIL):
  `showAdders` had the same careless non-settling shape the plan's §1 flagged on `removeAdders`**
  (flag + bare `_invalidateLayout`, riding the end-of-cycle flush) — invisible for the same reason
  as the FLOWRULE pair: nothing ever drove it; the new test is the first, and ONE showAdders call
  records TWO careless pushes (the stack + the climbing scroll frame). Converted to the canonical
  wrapper over `_showAddersNoSettle` (same as removeAdders). Test still green against its refs;
  division probe still clean.
- ⚠ Self-inflicted sequencing lesson: the capstone fix added ONE more Widget prototype member
  AFTER the four-test recapture ⇒ the inspector test churned AGAIN (one-row window shift,
  diffpage-verified benign) and needed a second single-test gated recapture. Order the
  Widget-member-adding edits BEFORE the recapture batch next time. The gauntlet re-run that
  caught it also ate an 18-min "world never booted" boot-storm paint-leg flake — killed the
  run + `fg killz` rather than riding out serial retries with a known-dirty leg.
- **F2 CLOSED 22:34: gauntlet EXIT=0 all 14 legs, 276 tests** (revisits/serialization/storage
  passed on the serial retry — the sanctioned load-flake path, parallel logs kept; the machine
  was heavily loaded all evening) **+ `fg homepage` GREEN (45 PASS)**. Inspector re-recapture
  ✅ COMPLETE. Suite is now 276 (the two new tests ride permanently).

### F3 — y-axis crossAlign coverage, 2026-08-04/05
- Extended `macroDivisionCrossAlignment` (per the plan: extend IT, no new test): a second fixture
  holder side by side — a `divisionBox('y')` vertical division stack, same colours/boxes,
  crossAlign start/center/end on the HORIZONTAL cross axis (left/middle/right) — and image_2 now
  grows BOTH cross axes (row taller 160→260, stack wider 220→280). Metadata intent/scenario/
  assertions updated to cover both fixtures. Zero src changes.
- Gated recapture ✅ COMPLETE (full suite green at dpr1+2); both new references eyeballed —
  aligned cells hold their desired cross extent and track start/middle/end on BOTH axes, stretch
  cells fill.
- ⚠ The overnight phase-close gauntlet was a POISONED RUN, not signal: the machine slept mid-run
  (launched 22:47, "finished" 08:11 — 7 h for a ~7 min run; the pure-Node refs leg took 35 min;
  every "failing" suite leg shows failed: 0 with shards complete 0/N and STALLED reaps; parts
  passed its serial retry; 55 infra-flake signatures). Diagnosis per the leg stats, no code chase.
  Re-run under `caffeinate -i` — overnight/long gauntlets should ALWAYS be caffeinated (the
  torture-runner doc already says so; now applied to gauntlets too).
- **F3 CLOSED 08:36 (2026-08-05): the caffeinated re-run is FULL GREEN, all 14 legs, 252s, ZERO
  serial retries** — a healthy machine also retro-confirms every overnight failure was suspension.

### F5 — docs + close, 2026-08-05
- `layout.md` §4.2 scaffold paragraph rewritten: both families' "edit layout", the shared
  membership-parameterized scan, the mid-pass FF-at-the-boundary discipline, the division-cell
  submenu, chrome exclusion by capability.
- `BACKLOG.md`: two discovered pre-existing issues filed under the arc's archive heading
  (unreachable menu tail beyond the world's height; the error console's degenerate-bounds
  construction cascade).
- The two F0-noted [call-separation] ratchet NOTEs FIXED (pre-existing drift, locked at close):
  `ensureLoaded` deleted from public-api-allowlist.txt (editLayout gave it a real src caller —
  the entry's own rationale was superseded by the parent arc) and BASELINE_U_QUERY 131→127 with
  the dated reason. Build green: `[U] 127/127`, 24 allowlisted, no NOTEs.
- Memory updated (`layout-spec-family-followups-arc`); commit messages drafted; end-of-arc review
  presented 2026-08-05.
- **OWNER DECISIONS (2026-08-05, via AskUserQuestion): F4 runs in a FRESH SESSION (this plan stays
  in `plans/` with F4 as its one open phase — it moves to `archive/` + INDEX when F4 resolves);
  commit both repos now.** BACKLOG §5.C line annotated to point here.

### F1 — division-cell product surface, 2026-08-04
- `DivisionStackLayoutSpec` gained: `element` back-ref (bound in `Widget._ensureDivisionBox`, the
  one materialization point; the shared `@defaults()` instance keeps NO element);
  `addWidgetSpecificMenuEntries` → "layout in row ➜" ('x') / "layout in column ➜" ('y') →
  `divisionCellMenu` popout with "desired size..." / "max size..." prompts + the four "cross: …"
  entries (current omitted, VSLS-alignment pattern); the settle-on-element setter family
  (`setCrossAlignToStretch/Start/Center/End` over one `_setCrossAlignNoSettle`;
  `setDesiredMainDim`/`setMaxMainDim` prompt-adapters over axis-keyed cores writing the CURRENT
  axis's box pair), each `# thin-wrap-exempt:` per the VSLS precedent, rule [H] honored (all logic
  incl. already-in-state guards in the cores, cores end `@element._invalidateLayout()`).
- Widget menu gate: `else if @layoutSpec?.isDivisionElement?() and !@isLayoutChrome?()` dispatches
  to the spec; NEW capability `LayoutChromeWdgt.isLayoutChrome` (landed WITH its caller) excludes
  divider/adder/spacer — capability, not a type test, covering all three chrome classes at the base.
- DEVIATIONS from the plan's letter: popout named `divisionCellMenu` (plan sketched `rowCellMenu`
  — wrong word under 'y'; labels match the plan exactly); F1.4 (DemoMenus "show adders"/"remove
  adders" retirement) deferred to F2 per the plan's own "safest" note.
- New test `SystemTest_macroDivisionCellMenuEditsSpec` — value-assert only (0 refs, no screenshots):
  fixture regime sanity, then cross: center / desired size 120 / max size 120 all driven through
  REAL right-click → hierarchy → submenu → prompt input; exact-pin assertion: max=desired ⇒ zero
  max margin ⇒ cell EXACTLY 120 wide. PASSED after one fixture-assert fix (400/3 rounds 133|134|133
  — asserting left==mid was arithmetically impossible; assert the symmetric outer pair instead;
  test-authoring bug, not product).
- Build: 0 violations first try (dead-method sees the menu-string callers; thin-wrap exemptions
  accepted).
- **The "expect ZERO churn — verify, don't assume" warning PAID OFF: one existing test DOES
  right-click a division cell.** First presuite: 275 tests, 1 fail —
  `macroStringWdgtAndTextWdgtResizingInLayout`, img6/7 both dprs. Diffpage showed NOT the benign
  menu-row class: the TextWdgt kept its full-size font + ellipsis at the narrow beat (the
  "shrink to fit" toggle never landed). A `.scratch` puppeteer probe measured the real mechanism:
  the TextWdgt-with-background context menu is now **501px tall in the 440px harness world**
  (menus clamp their TOP via `_moveWithin`, so the tail overflows the bottom) — "→← shrink to
  fit" sits at y=455, OFF-CANVAS; the test had been passing on a **3px margin** (pre-F1: y≈437),
  and the new row+separator (18px) consumed it. "✓ soft wrap" (y≈455 pre-F1) and "run contents"
  were ALREADY unreachable — which is exactly why `toggleSoftWrap()` is the sanctioned direct-call
  escape hatch. FIX: the same sanctioned escape hatch for the same cause — the shrink-to-fit beat
  becomes `textW.togglefittingSpecWhenBoundsTooSmall()` (macros CLAUDE.md rule: direct call OK
  when "the behaviour's UI trigger is genuinely blocked"), comment + metadata scenario updated.
  Rejected alternatives: reordering the toggle before the attach (img3's reference DEPENDS on
  toggle-off ellipsis slivers → would churn img2/3); recapture (would bake in a silently-missed
  click — the diff was a BROKEN INTERACTION, not churn). Result: test passes against the
  EXISTING references — F1 stays zero-recapture. Probe kept at
  `Fizzygum-tests/.scratch/probe-division-cell-menu-geometry.js`.
- PRE-EXISTING product limit surfaced (for BACKLOG at F5): a context menu taller than the world
  clamps its top and leaves its tail permanently unreachable — real on small screens too, and it
  silently degrades what macros can drive at 960×440.
- Gates: presuite re-run PASS 19:46 (275/275, zero churn — the new test rides; every other test
  byte-identical). **FULL GAUNTLET GREEN 19:54, all 14 legs, 275 tests** — revisits baseline EMPTY
  held, census zero movers, BOTH serialization rigs green (the spec's widget back-ref serializes/
  duplicates cleanly on the VSLS precedent), webkit green. **F1 CLOSED 19:54: `fg homepage` GREEN**
  (45 PASS lines, snapshot round-trip clean, dev build restored). Zero recaptures in the phase.
