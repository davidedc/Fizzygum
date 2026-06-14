You are picking up a series of "bring a class to latest" modernizations in the Fizzygum CoffeeScript GUI framework (workspace: /Users/davidedellacasa/code/Fizzygum-all/, with sibling git repos Fizzygum/ = source, Fizzygum-tests/ = the 160 macro SystemTests). You have NO prior context, so start by reading these, in order:

 1. The PLAYBOOK distilled from these arcs (process + gotchas, written to be reused): Fizzygum/docs/class-modernization-playbook.md — read it in full first.
 2. The prior approved plans (read them — together they show a clean rename arc, a "rejected target → pivot to the tractable one" arc, and a dead-code-deletion arc):
    - /Users/davidedellacasa/.claude/plans/add-an-option-or-typed-squirrel.md (filename is stale — its CONTENTS are the InspectorMorph cleanup).
    - /Users/davidedellacasa/.claude/plans/you-are-picking-up-sparkling-galaxy.md (filename is stale — its CONTENTS are the inspect/inspect2 consolidation; its "Why this, and not StringMorph" and "Potential follow-ups" sections record StringMorph/Text findings you should NOT re-derive).
    - /Users/davidedellacasa/.claude/plans/stringmorph3-dead-code-deletion.md (the StringMorph3 deletion arc; its "Why this, and NOT the String + Text arc" section records the menu/button-family BLOCKER — the central finding below).
 3. The macro-test subsystem docs: Fizzygum/src/macros/CLAUDE.md and Fizzygum/src/macros/MACRO-PATTERNS.md, plus the /author-macro-test skill in Fizzygum-tests. (An auto-memory note "InspectorWdgt windowed cleanup" should also surface — it summarizes the prior arcs' key findings.)

 WHAT IS ALREADY DONE (committed + pushed; do NOT redo):
 - Arc 1: DELETED legacy InspectorMorph, renamed InspectorMorph2 -> InspectorWdgt (+ ClassInspectorMorph -> ClassInspectorWdgt), made it windowed everywhere, re-authored its ~14 macro tests.
 - Arc 2: CONSOLIDATED the two inspector entry points — deleted the duplicate inspect2/spawnInspector2, kept inspect/spawnInspector as the single windowed entry point (repointed the "dev -> inspect" menu item), and dropped its homepage-exclusion guard so the one inspector ships in --homepage. Suite 160/160.
 - Arc 3: DELETED the dead StringMorph3 "Morph3" experiment (a stale, feature-stripped FORK of StringMorph2 — same ~1050 lines minus ControllerMixin / undo-redo / text-modification-tracking / the SWCanvas font-size cap, plus an unfinished, half-wired "fit text to box / fit box to text" submenu whose toggles were no-ops). Also removed the sibling dangling demo plumbing for TextMorph3 — a class that never existed (createNewTextMorph3WithBackground + its menu items referenced an undefined global). Recaptured 4 legitimately-changed tests (3 submenu tests whose photographed "test menu" lost the two dead items; macroDuplicatedInspectorDrivesCopiedTargetOnly whose inspector method-list lost the two deleted Widget demo methods). Suite 160/160. As part of this arc, a block comment was added at StringMorph2.coffee's fitting-spec properties documenting how to add the "fit box to text (tight/loose · which-dimension-adjusts)" axis PROPERLY (behaviour in reflowText/fitToExtent via silentRawSetExtent, invalidateLayout for container reflow, cache-key wiring, menu last) — so the abandoned StringMorph3 experiment's INTENT survives without its broken code.

 ====================================================================
 THE STANDING GOAL NOW: find a path to DEPRECATE/DELETE StringMorph AND TextMorph
 in favour of their successors StringMorph2 and TextMorph2.
 ====================================================================
 These two are the LAST legacy text widgets and the last big obstacle to a coherent String/Text family
 (every other clean modernization candidate is now either DONE or genuinely blocked — see "candidates exhausted"
 below). The successors already exist and are in production use; the job is no longer "is there a successor?" but
 "how do we get there safely?". Treat this as the priority, and plan the PATH — do not keep deferring it.

 KEY FINDINGS (do not re-investigate from scratch — these are established):

 1. THE REAL BLOCKER (the central reason this hasn't happened yet): the OLD StringMorph/TextMorph are
    LOAD-BEARING in the core UI chrome — the menu/button/tooltip system — which is the SAME deprecated
    TriggerMorph family. Verified (file:line):
      - MenuItemMorph EXTENDS TriggerMorph (MenuItemMorph.coffee:3) and builds its label with `new TextMorph` (:42) → every menu item.
      - TriggerMorph (header: "now deprecated, use SimpleButton") builds its label with `new StringMorph(…, false, @labelColor)` (TriggerMorph.coffee:172).
      - MenuHeader builds `new TextMorph(textContents, …, "center")` (MenuHeader.coffee:9) — passing the OLD family's STRING alignment.
      - ToolTipWdgt builds `new TextMorph(@contents, …, "center")` twice (ToolTipWdgt.coffee:75,91).
    So you CANNOT delete StringMorph/TextMorph without first re-pointing TriggerMorph + MenuItemMorph + MenuHeader
    + ToolTipWdgt onto StringMorph2/TextMorph2 — which is the blocked button/menu-family refactor. The two families
    have DIFFERENT fitting/alignment/back-buffer engines (old: string alignment + BackBufferMixin; new:
    AlignmentSpec* enums + fitToExtent/searchLargestFittingFont + ControllerMixin), so swapping them risks shifting
    the rendered pixels of EVERY menu item / menu header / tooltip — and re-baselining the LARGE fraction of the 160
    SystemTests that open a menu or show a tooltip. That suite-wide reference churn is the cost to plan for.
    (Window title bars and EmptyButtonMorph/SimpleButtonMorph ALREADY use StringMorph2 — they are not blockers.)

 2. THE PER-CLASS DIVERGENCES (must be reconciled, not silently ported): incompatible constructor signatures
    (different arg order/count — StringMorph2 takes originallySetFontSize/fontName/isHeaderLine/backgroundColor…,
    old TextMorph takes alignment/maxTextWidth/shadowOffset/shadowColor); StringMorph2 opens an "edit:" prompt when
    cropped (StringMorph does not); `currentlySelecting` is a METHOD on StringMorph2 but a PROPERTY on the old
    StringMorph; the caret path differs (gotoSlot vs gotoPos — and CaretMorph.coffee:27 special-cases
    `instanceof TextMorph` for the old string-alignment, CaretMorph.coffee:90 keys Enter-accept on
    constructor.name == "StringMorph"/"StringMorph2"); old TextMorph supports text SHADOWS (shadowOffset/shadowColor)
    that TextMorph2 lacks (the chrome sites don't pass shadows — verified — so this one is free); fitting specs /
    alignment / softWrap / undo. See plan #2's "Why this, and not StringMorph" for specifics.

 3. TESTS THAT DELIBERATELY DEPEND ON THE OLD CLASSES (need explicit per-test handling, not a blind swap):
      - macroEditingStringInScrollablePanelCaretAlwaysVisible and macroScrollPanelCaretBroughtIntoViewWhenMoved
        pick the OLD StringMorph ON PURPOSE (isScrollable, NO edit-prompt-on-crop, NO slotAt overshoot).
      - macroTextRelayoutsCorrectlyOnResize asserts the OLD TextMorph resize law (rawSetExtent keeps only x →
        maxTextWidth, height from content) — TextMorph2 does NOT reproduce it. It's the suite's only dedicated
        old-TextMorph behavioural assertion.
    Also: TextMorph extends StringMorph and TextMorph2 extends StringMorph2, so the families move together;
    HhmmssLabelWdgt (→ VideoTimeLabelWdgt/VideoDurationLabelWdgt) already sits on the modern StringMorph2 base;
    TextMorph2's subclasses are SimplePlainTextWdgt, WindowContentsPlaceholderText, FizzytilesCodeMorph.

 CANDIDATES EXHAUSTED (so the String+Text problem can no longer be side-stepped): StringMorph3 deletion = DONE
 (Arc 3); inspect/inspect2 consolidation = DONE (Arc 2); ListMorph -> ListWdgt is a pure nomenclature rename with
 no legacy to delete (lower value, against the "don't mass-rename *Morph" convention without a reason); the button
 family is exactly the blocker in finding #1. There is no cheaper arc left to pick instead.

 YOUR TASK: produce a PLAN (do not implement yet) for the PATH to deprecate/delete StringMorph and TextMorph,
 applying the playbook. The plan must engage the blocker directly rather than defer it. Decide and lay out a route,
 e.g. one of:
   (a) PREREQUISITE-FIRST: a phased arc that FIRST migrates the menu/button/tooltip chrome (TriggerMorph,
       MenuItemMorph, MenuHeader, ToolTipWdgt) onto StringMorph2/TextMorph2 — reconciling string-alignment→enum and
       the fitting/back-buffer differences, and triaging the menu/tooltip reference churn — and ONLY THEN deletes
       StringMorph/TextMorph and renames StringMorph2 -> StringWdgt / TextMorph2 -> TextWdgt. Surface, as an explicit
       owner decision up front, whether the menu/tooltip pixels are ALLOWED to change (they almost certainly will);
       that decision sizes the whole arc.
   (b) STAGED DEPRECATION: turn the old classes into thin compatibility shims / mark them deprecated, migrate call
       sites incrementally across several landings (chrome last, since it's the riskiest), then delete. Spell out
       what each landing verifies.
 Recommend ONE route, justify it against the other, and structure it in PHASES with continuous verification (per the
 owner-workflow memory note: run straight through, ONE end-of-arc review).

 In the plan, specifically:
 - Use Explore/Plan agents to (re)confirm the touch-list (the prior arc already mapped most of it — reconfirm, don't
   re-derive): every bare-identifier reference to StringMorph/StringMorph2/TextMorph/TextMorph2 across Fizzygum/src
   (extends/new/instanceof/findTopWidgetByClassNameOrClass — use \b word boundaries, StringMorph is a substring of
   StringMorph2; StringMorph3 is now GONE), the build hooks, serialization (constructor.name string checks, e.g.
   CaretMorph:90), the menu-demo string literals, and the homepage/precompiled paths — confirm the eventual rename
   is name-extraction-only (no manifest), per playbook §1. Pay special attention to the chrome call sites in finding #1.
 - PRESENTATION/BEHAVIOUR CHECK (playbook §2): for each legacy call site — ESPECIALLY the chrome (menu item, menu
   header, tooltip, deprecated-button label) — open the modern widget the way that site does and LOOK at it; surface
   every behaviour/appearance divergence (string-alignment→enum, edit-prompt-on-crop, currentlySelecting, caret API,
   missing shadows) as an explicit owner decision BEFORE any test work, not a silent port.
 - Enumerate EVERY macro SystemTest that FUNCTIONALLY uses any of the four classes (not just prose) and classify each:
   relabel-only vs. constructor-swap-only-then-recapture vs. genuine re-author vs. "expected reference churn because it
   photographs a menu/tooltip/inspector-method-list that the chrome migration changes". Note the three tests in finding
   #3 need special handling.
 - Call out the playbook-§4 gotchas likely to bite for a text/string widget (TextMorph2 right-click menus not
   macro-drivable, editable-only-after-focus, softWrap, empty-text click crash, caret/selection, hover/determinism,
   menu/tooltip/inspector-method-list shots changing when a class or method set changes, the --clean --no-build trap)
   and how each affected test will handle them.
 - Make the plan SELF-CONTAINED for a future no-context session (Orientation + Glossary like the prior plans), list the
   source touch-list and the test list per phase, give the verification steps (build_and_smoke, per-test capture at
   dpr 1&2, build_and_test = 160/160, a --homepage build+boot since the chrome ships in homepage), and a "Potential
   follow-ups" section.
