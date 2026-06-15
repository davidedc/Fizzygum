You are picking up a series of "bring a class to latest" modernizations in the Fizzygum CoffeeScript GUI framework (workspace: /Users/davidedellacasa/code/Fizzygum-all/, with sibling git repos Fizzygum/ = source, Fizzygum-tests/ = the 160 macro SystemTests). You have NO prior context, so start by reading these, in order:

 1. The PLAYBOOK distilled from these arcs (process + gotchas, written to be reused): Fizzygum/docs/class-modernization-playbook.md — read it in full first (its §7 records the String/Text arc that just closed, with lessons).
 2. The prior approved plans (read them — together they show a clean rename arc, a "rejected target → pivot to the tractable one" arc, a dead-code-deletion arc, and the just-finished prerequisite-first chrome-migrate-then-delete-and-rename arc):
    - /Users/davidedellacasa/.claude/plans/add-an-option-or-typed-squirrel.md (filename is stale — its CONTENTS are the InspectorMorph cleanup).
    - /Users/davidedellacasa/.claude/plans/you-are-picking-up-sparkling-galaxy.md (filename is stale — its CONTENTS are the inspect/inspect2 consolidation).
    - /Users/davidedellacasa/.claude/plans/stringmorph3-dead-code-deletion.md (the StringMorph3 deletion arc).
    - /Users/davidedellacasa/.claude/plans/you-are-picking-up-streamed-yeti.md (filename is stale — its CONTENTS are the String/Text arc: migrate the menu/button/tooltip CHROME onto the modern text family, THEN delete StringMorph/TextMorph and rename StringMorph2 -> StringWdgt / TextMorph2 -> TextWdgt. This is the template for the route now recommended below — read its phasing and its owner-decision-up-front handling of menu pixel churn.)
 3. The macro-test subsystem docs: Fizzygum/src/macros/CLAUDE.md and Fizzygum/src/macros/MACRO-PATTERNS.md, plus the /author-macro-test skill in Fizzygum-tests. (Two auto-memory notes should also surface: "String/Text Wdgt modernization" — the arc just closed — and "InspectorWdgt windowed cleanup" — the earlier arcs. They summarize the key findings so you don't re-derive them.)

 WHAT IS ALREADY DONE (committed + pushed; do NOT redo):
 - Arc 1: DELETED legacy InspectorMorph, renamed InspectorMorph2 -> InspectorWdgt (+ ClassInspectorMorph -> ClassInspectorWdgt), made it windowed everywhere, re-authored its ~14 macro tests.
 - Arc 2: CONSOLIDATED the two inspector entry points — deleted the duplicate inspect2/spawnInspector2, kept inspect/spawnInspector as the single windowed entry point, dropped its homepage-exclusion guard so the one inspector ships in --homepage. Suite 160/160.
 - Arc 3: DELETED the dead StringMorph3 "Morph3" experiment (a stale, feature-stripped FORK of StringMorph2) and the sibling dangling TextMorph3 demo plumbing (a class that never existed). Recaptured 4 legitimately-changed tests. Suite 160/160. A block comment was left at the modern widget's fitting-spec properties documenting how to add the "fit box to text" axis PROPERLY, so the abandoned experiment's INTENT survives without its broken code.
 - Arc 4 (THE String/Text arc — the one that used to be "the standing goal" of this very prompt; now CLOSED): DELETED legacy StringMorph and TextMorph; renamed StringMorph2 -> StringWdgt and TextMorph2 -> TextWdgt; and FIRST migrated the menu/button/tooltip CHROME onto the modern family so the delete was unblocked. Landed in two pushes (chrome migration, then delete+rename), suite 160/160 at dpr 1 and (after a bug fix, below) dpr 2. Verified current reality (file:line):
     * StringWdgt extends Widget; TextWdgt extends StringWdgt (StringWdgt.coffee / TextWdgt.coffee). Old StringMorph/TextMorph/StringMorph2/TextMorph2/StringMorph3 are all GONE — a `\b`-bounded grep of Fizzygum/src finds the old names only in historical COMMENTS, no live extends/new/instanceof.
     * The chrome now builds its labels from the modern family + a new fitting helper: TriggerMorph `new StringWdgt(...)` + `@label.sizeToTextAndDisableFitting()` (TriggerMorph.coffee:172,185); MenuItemMorph `new TextWdgt @labelString,…` + helper (MenuItemMorph.coffee:44,50); MenuHeader `new TextWdgt(...)` + helper (MenuHeader.coffee:9,22); ToolTipWdgt `new TextWdgt(...)` ×2 + helper (ToolTipWdgt.coffee:79,96,108). The helper `StringWdgt#sizeToTextAndDisableFitting` (FLOAT+SCALEDOWN, measure, silentRawSetExtent) + the `autoSizeBoxToText` flag re-hug the box on every later setText/setFontSize — the modern family otherwise sizes TEXT to a FIXED box, the opposite of the old box-hugs-text law.
     * CaretMorph was reconciled: the old-TextMorph force-left-while-editing block is gone (modern TextWdgt handles the caret under every alignment) — CaretMorph.coffee:27-33 is now just the explanatory comment; Enter-accept keys on `@target.constructor.name == "StringWdgt"` (single-line accepts; multi-line TextWdgt inserts a newline) at CaretMorph.coffee:95; SimplePlainTextWdgt is special-cased at :87.
     * Subclasses present and on the modern base: SimplePlainTextWdgt, WindowContentsPlaceholderText, FizzytilesCodeMorph (← TextWdgt); HhmmssLabelWdgt (← StringWdgt).
     * MENU/TARGET/HIERARCHY LABELS STRIP "Wdgt": `toString()/getTextDescription()` do `.replace("Wdgt","")`, so a TextWdgt navigates/displays as "a Text", a StringWdgt as "a String", a WindowWdgt as "a Window". `findTopWidgetByClassNameOrClass` and `instanceof` use the REAL name; the inspector HIERARCHY diagram shows the real name. (This made the rename NOT pixel-free and is documented in src/macros/CLAUDE.md.)
     * The three tests that USED to "deliberately depend on the old classes" (macroEditingStringInScrollablePanelCaretAlwaysVisible, macroScrollPanelCaretBroughtIntoViewWhenMoved, macroTextRelayoutsCorrectlyOnResize) still exist by those names but were RE-AUTHORED onto the modern family during the arc (the old classes they targeted no longer exist; macroTextRelayoutsCorrectlyOnResize now asserts the TextWdgt resize law — box = dragged extent in BOTH dims, text re-wraps to width).
   - Follow-on bug fix shipped during Arc 4 validation (Fizzygum commit e78acaa6 + recaptured ref): ScrollPanelWdgt scroll-on-drag was dropping to ZERO under frame-cadence collapse, so a locked-panel drag scrolled at dpr 1 but not dpr 2; fixed with a `collapsedScrollDrag` release-flush. Unrelated to class modernization — mentioned only so you don't trip over it in git log.

 ====================================================================
 THE STANDING GOAL NOW: DELETE the deprecated TriggerMorph and re-base its subclasses
 (MenuItemMorph and MagnetMorph) onto the modern button family (EmptyButtonMorph /
 SimpleButtonMorph) — completing the menu/button modernization that Arc 4 began.
 ====================================================================
 Arc 4 modernized the LABELS inside the chrome (they're StringWdgt/TextWdgt now). What remains is the BASE
 CLASS: TriggerMorph itself is still flagged deprecated ("use the SimpleButton instead", TriggerMorph.coffee:1-4)
 and is still the base of every menu item and of MagnetMorph. The modern successor already exists and is already
 on the modern text family — so, exactly as in the String/Text arc, the job is no longer "is there a successor?"
 but "how do we get there safely?". Treat this as the priority; plan the PATH, do not defer it.

 KEY FINDINGS (verified file:line — do not re-investigate from scratch):

 1. WHO STILL DEPENDS ON TriggerMorph (the whole touch surface of subclassers):
      - `class MenuItemMorph extends TriggerMorph` (MenuItemMorph.coffee:3) — every menu item.
      - `class MagnetMorph extends TriggerMorph` (fizzytiles/MagnetMorph.coffee:3) — a fizzytiles demo widget.
    Nothing else extends/`new`s/`instanceof`-checks TriggerMorph in Fizzygum/src (confirm with a `\b`-bounded
    grep). TriggerMorph itself `extends Widget` (TriggerMorph.coffee:13).

 2. THE SUCCESSOR ALREADY EXISTS AND IS MODERN: `class EmptyButtonMorph extends Widget` builds its face with
    `new StringWdgt …` (EmptyButtonMorph.coffee:9,65); `class SimpleButtonMorph extends EmptyButtonMorph`
    (SimpleButtonMorph.coffee:5). Window title bars and these buttons were never blockers. So the route is to
    move MenuItemMorph (and MagnetMorph) onto this family and delete TriggerMorph.

 3. THE REAL WORK / DIVERGENCE TO RECONCILE (this is what the plan must pin down — NOT yet investigated in
    depth, do it in the plan): TriggerMorph provides the "trigger" machinery (dataSourceMorphForTarget / target /
    action — see its class comment) that MenuItemMorph relies on. The EmptyButtonMorph/SimpleButtonMorph family
    has its own action model. The central question is how MenuItemMorph's trigger/target/action behaviour maps
    onto the button family without changing menu behaviour — and whether TriggerMorph's logic should be folded
    INTO MenuItemMorph, or MenuItemMorph re-based on SimpleButtonMorph with the trigger bits ported. Treat the
    mapping of trigger→action as the load-bearing design decision, the analogue of Arc 4's string-alignment→enum.

 4. PIXEL-CHURN RISK (smaller than Arc 4's, but still present): menu items ARE the chrome, so a LARGE fraction
    of the 160 SystemTests open a menu. Arc 4 already moved the menu-item LABEL pixels onto the modern text
    family (and re-baselined accordingly), so a base-class swap that preserves geometry MAY be close to
    pixel-neutral — but any change to padding/hit-area/highlight/press visuals from the button family will shift
    menu pixels and re-baseline the menu-opening tests. Surface, as an explicit owner decision UP FRONT, whether
    menu/button pixels are ALLOWED to change; that decision sizes the arc (per the streamed-yeti plan's model).

 SECONDARY DEFERRED FOLLOW-UPS from Arc 4 (smaller than a full arc — fold in or schedule separately, your call
 in the plan):
   - Bare-TextWdgt CONTENT layout: the window/panel/scroll content-layout sites special-case only
     SimplePlainTextWdgt for the maxTextWidth→softWrap reflow (WindowWdgt, SimpleVerticalStackPanelWdgt,
     ScrollPanelWdgt, PanelWdgt). A bare TextWdgt dropped as content doesn't get that wiring. Decide whether to
     generalize it to TextWdgt.
   - TextWdgt has NO text SHADOWS (the old TextMorph's shadowOffset/shadowColor were dropped; the chrome sites
     never passed shadows, so it was free). Re-add only if a concrete site needs it.

 CANDIDATES EXHAUSTED ELSEWHERE (so the menu/button arc is the right next pick): InspectorMorph cleanup, the
 inspect/inspect2 consolidation, the StringMorph3 deletion, and the whole String/Text family are all DONE.
 ListMorph -> ListWdgt remains a pure nomenclature rename with no legacy to delete (lower value, and against the
 "don't mass-rename *Morph without a reason" convention). The deprecated TriggerMorph is the clear remaining
 deprecated-class-with-a-living-successor, and Arc 4 already set it up.

 YOUR TASK: produce a PLAN (do not implement yet) for the PATH to delete TriggerMorph and modernize MenuItemMorph
 (and MagnetMorph), applying the playbook. Engage finding #3 (the trigger→action mapping) directly rather than
 defer it. Decide and lay out a route, e.g. one of:
   (a) FOLD-IN: absorb TriggerMorph's trigger/target/action machinery directly INTO MenuItemMorph (and give
       MagnetMorph the small piece it needs), then delete TriggerMorph. Lowest pixel risk if geometry is held
       fixed; spell out exactly what moves where.
   (b) RE-BASE: re-base MenuItemMorph on SimpleButtonMorph/EmptyButtonMorph, porting the trigger bits onto the
       button action model, then delete TriggerMorph. Cleaner long-term (one button family) but more likely to
       shift menu visuals — name what changes and what re-baselines.
 Recommend ONE route, justify it against the other, and structure it in PHASES with continuous verification (per
 the owner-workflow memory note: run straight through, ONE end-of-arc review; commit/push only after that review).

 In the plan, specifically:
 - Use Explore/Plan agents to confirm the touch-list (reconfirm, don't re-derive): every bare-identifier
   reference to TriggerMorph / MenuItemMorph / MagnetMorph across Fizzygum/src (extends / new / instanceof /
   findTopWidgetByClassNameOrClass — use `\b` word boundaries; note MenuItemMorph is a distinct token but watch
   for substring traps), the build hooks, serialization (constructor.name string checks), any menu-demo string
   literals, and the homepage/precompiled paths — confirm the deletion is name-extraction-only (no manifest),
   per playbook §1. The chrome ships in --homepage, so include a --homepage build+boot in verification.
 - PRESENTATION/BEHAVIOUR CHECK (playbook §2): open a real menu, a real button, and a MagnetMorph the way each
   site builds them and LOOK — surface every behaviour/appearance divergence between TriggerMorph's trigger
   model and the button family's action model (target/action wiring, highlight/press visuals, padding/hit-area,
   keyboard/hover) as an explicit owner decision BEFORE any test work, not a silent port.
 - Enumerate EVERY macro SystemTest that FUNCTIONALLY exercises a menu item, a TriggerMorph-derived button, or a
   MagnetMorph, and classify each: pixel-neutral (passes unchanged) vs. constructor/geometry-swap-then-recapture
   vs. genuine re-author vs. "expected reference churn because it photographs a menu the base-class swap
   changes". Remember menus strip "Wdgt" from class names in nav/labels (Arc 4 finding) — menu-navigation
   strings already target "a Text"/"a String"; a base-class rename of MenuItemMorph would move the
   "a MenuItemMorph"/"a MenuItem" hierarchy labels too — account for it.
 - Call out the playbook-§4 gotchas likely to bite a menu/button arc (menu hierarchy/context-menu shots changing
   when a class or its ancestor chain changes; getMostRecentlyOpenedMenu being fresh-only; right-click opening
   the ANCESTOR hierarchy menu; hover/determinism; the menus-strip-"Wdgt" naming; the capture `--clean`
   deletes-both-densities trap; run-macro-test-headless not rebuilding) and how each affected test handles them.
 - Make the plan SELF-CONTAINED for a future no-context session (Orientation + Glossary like the prior plans),
   list the source touch-list and the test list per phase, and give verification steps: build_and_smoke, per-test
   capture at dpr 1 AND dpr 2, build_and_test = 160/160, and a --homepage build+boot (the chrome ships in
   homepage). Add a "Potential follow-ups" section (carry the two Arc-4 deferred items above, and any new ones).
