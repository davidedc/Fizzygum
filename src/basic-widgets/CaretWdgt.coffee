# I am the text CARET: I mark the slot where typing goes in the String/Text being edited, my target.
# ONE look for every caret -- in a document, a prompt field, a code pane, a cell editor, a caption
# rename, a plain text: I paint in the theme's caretFill (the accent, BlinkerWdgt); I am as tall as
# the font's em box in my slot's line (my target's caretBoxInLine) and the theme's caretWidth wide (a
# twentieth of my height where that is wider); and I stand the theme's caretGap to the RIGHT of my
# slot's boundary (_myTopLeftAtSlot). My colour is taken from the theme as I am built (the world
# builds a caret for each edit); my extent and my place are read from the theme and my target at
# every re-sync. My slot's boundary itself stays my target's answer (slotCoordinates), which clicks,
# selections and the macro toolkit's text aims read.

class CaretWdgt extends BlinkerWdgt

  target: undefined
  slot: undefined
  # how far in from each side of my parent my WHOLE box stays while my target scrolls to keep me in
  # view (_oneScrollCaretIntoViewPassNoSettle): one pixel, clear of a field's 1 px border.
  viewPadding: 1
  # the height my extent was last taken at (_updateDimension re-takes it only when that changes)
  currentCaretFontSize: undefined
  # the VERTICAL RUN I am on: the column slot my Ups and Downs keep, and the text they kept it in ({text,
  # columnSlot}; _columnForVerticalMove reads it). Every placement of mine ends it (_gotoSlotNoSettle) and only
  # an Up or Down starts it again, after its own move. A string and a number, never a widget; a caret is built for
  # each edit, so a run never outlives one.
  _verticalRun: undefined

  constructor: (@target) ->
    @slot = @target.text.length
    super()

    # if the only thing in the undo history is the first positioning of the caret via click, we
    # clear it because we are going to set our own with the first click. The text widget owns its
    # undo history, so it does the check (was an @target.undoHistory = [] reach-in here). (Phase 7a)
    @target.clearUndoHistoryIfOnlyFirstClickPositioning()

    # font could be really small I guess?
    @minimumExtent = new Point 1,1

    # TextWdgt handles the caret correctly under every
    # AlignmentSpecHorizontal — its slotCoordinates / slotAtSingleLineString
    # account for the per-line shift — so no force-left is needed; see
    # SystemTest_macroTextWdgtCaretPlacementUnderAlignments and
    # SystemTest_macroTextWdgtCaretKeepsCorrectAlignment.
    @_adjustAccordingToTargetText()

  # CaretWdgt is overlay chrome (the text-editing caret), not a content child, so
  # it is excluded from content-bounds and real-children calculations (see
  # Widget.fullBounds and TreeNode.childrenNotHandlesNorCarets).
  isLayoutInert: -> true

  # I am a transient overlay, so I am skipped by the add-time drop-shadow management in
  # Widget.add (instead of `instanceof CaretWdgt` there; type-test-elimination campaign)
  skipsAddShadowManagement: -> true

  # THE POINTER NEVER LANDS ON ME, anywhere. Two reasons, both about how I appear:
  #  a) I show up UNDER the mouse right after the first click of a double-click, so I would
  #     swallow the second one;
  #  b) I vanish as soon as a menu opens, so "the widget you clicked" being a caret would be
  #     confusing even when it worked.
  # I am not an ephemeral (Widget.isEphemeral) — I am the editing cursor, not reconciler-owned
  # chrome — so I state this myself rather than borrowing that capability, and I state it HERE
  # rather than letting the hit test single me out by comparing against the `world.caret`
  # singleton: the reason belongs on the class it is about (type-test-elimination convention).
  isPointerTargetAt: (aPoint) -> false

  # The INERT re-sync of the caret to its target: re-size it to the target's caret box and re-place it
  # where a caret stands at the target's CURRENT slot. The caret is isLayoutInert, so this schedules / mutates NO
  # layout -- it is READ-ONLY w.r.t. the layout tree and therefore safe to run at PAINT time
  # (justBeforeBeingPainted). It deliberately does NOT scroll-follow: bringing the caret into view mutates
  # layout (moves @target / @contents) and must happen out of paint -- that is the caret's _reLayout, drained
  # by the per-event IN-PLACE settle (see _requestScrollFollow / _reLayout; the follow never rides the
  # end-of-cycle flush). (Also called from the constructor.)
  _adjustAccordingToTargetText: ->
    @_updateDimension()
    @_repositionToSlotNoSettle()

  # PAINT is read-only: the only caret work here is the inert re-place above (no scroll-follow, no layout).
  justBeforeBeingPainted: ->
    @_adjustAccordingToTargetText()

  # PUBLIC notification — some String/Text widget's rendering changed (buffer swap, reflow, any
  # invalidation). My position/size DERIVE from a text at paint time (justBeforeBeingPainted
  # re-places me AFTER damage rects were already fleshed out), so a text change must pre-break my
  # footprint or my old pixels ghost. I invalidate MYSELF here, in the method the text invokes on
  # me (widget-citizenship point 2) — texts never reach into my _changed(). Conservatively fires on
  # ANY text's change, not just my @target's (a needless extra damage rect is harmless; filtering
  # on @target is a possible future tightening).
  noteTextChanged: ->
    @_changed()

  # MY EXTENT where my target's text is set at `fontSize`: as tall as the caret box its line box
  # answers there (the font's em box in its line), and the theme's caretWidth wide -- or a twentieth of
  # that height where that is wider, so a caret in very large text thickens with it: 2 px up to a 59 px
  # em box (12 px text: 2 x 15; 15 px: 2 x 18; 48 px: 2 x 58), then 3, 4, ... (96 px text: 5 x 116).
  # Whole logical pixels, so dpr 2 doubles it. A pure read: _updateDimension applies it, and the
  # scroll-follow's clamp sizes my box with it before a paint has applied it.
  _extentAtTargetFontSize: (fontSize) ->
    height = (@target.caretBoxInLine fontSize).height()
    new Point (Math.max WorldWdgt.theme.caretWidth, (Math.floor height / 20)), height

  _updateDimension: ->
    extent = @_extentAtTargetFontSize @target.actualFontSizeUsedInRendering()
    if extent.y != @currentCaretFontSize
      @currentCaretFontSize = extent.y
      @_applyExtent extent
  
  # THE KEYS I ACT ON, the one definition of the keys I act on as COMMANDS (verbFor): each a key, or a chord spelled
  # as the macro toolkit spells one ("Meta+ArrowLeft"; Shift is left out, since every verb takes it), and the verb
  # it runs. Two tables:
  #   - keyVerbs: every keyboard family's plain keys, the arrows and Home and End, whatever modifier but Ctrl or Cmd
  #     is held (Alt+Left on a PC is Left to me);
  #   - chordVerbs: each FAMILY's own chords (User.keyboardFamily), STRICT (owner ruling 2026-11-18): a Mac's
  #     Ctrl+A and Ctrl+Z, and a PC's Win+A and Win+Z, do nothing. A word jump to the right lands at the word's END
  #     on a Mac, at the next word's START on a PC. Both redo with Shift and their undo chord; a PC also with
  #     Ctrl+Y, Windows' own redo key. Each delete chord deletes from me to where its family's move of the same
  #     reach lands (a Mac: Option+Backspace and Option+Delete a word, Cmd+Backspace to the line's start; a PC:
  #     Ctrl+Backspace and Ctrl+Delete a word), one character where that move goes nowhere; a PC's Alt+Backspace
  #     stays Backspace, as its Alt+Left stays Left.
  # The browser bridge asks verbFor too, to keep the browser's own default (Back on Cmd+Left, on a PC's Alt+Left;
  # the page's scroll on Home and End) off every key I act on while I am live.
  @keyVerbs:
    "ArrowLeft": "goLeft"
    "ArrowRight": "goRight"
    "ArrowUp": "goUp"
    "ArrowDown": "goDown"
    "Home": "goHome"
    "End": "goEnd"

  @chordVerbs:
    mac:
      "Meta+ArrowLeft": "goHome"
      "Meta+ArrowRight": "goEnd"
      "Meta+ArrowUp": "goDocumentStart"
      "Meta+ArrowDown": "goDocumentEnd"
      "Alt+ArrowLeft": "goWordStart"
      "Alt+ArrowRight": "goWordEnd"
      "Alt+Backspace": "deleteToWordStart"
      "Alt+Delete": "deleteToWordEnd"
      "Meta+Backspace": "deleteToLineStart"
      "Meta+a": "selectAll"
      "Meta+z": "undo"
    pc:
      "Ctrl+Home": "goDocumentStart"
      "Ctrl+End": "goDocumentEnd"
      "Ctrl+ArrowLeft": "goWordStart"
      "Ctrl+ArrowRight": "goNextWordStart"
      "Ctrl+Backspace": "deleteToWordStart"
      "Ctrl+Delete": "deleteToNextWordStart"
      "Ctrl+a": "selectAll"
      "Ctrl+z": "undo"
      "Ctrl+y": "redo"

  # a chord as the tables spell it: its modifiers, then the key (a one-character key in lower case, so Shift+Cmd+Z
  # is "Meta+z" with Shift held); undefined when no Ctrl, Alt or Cmd is held
  @chordOf: (key, ctrlKey, altKey, metaKey) ->
    return undefined unless ctrlKey or altKey or metaKey
    (if ctrlKey then "Ctrl+" else "") + (if altKey then "Alt+" else "") + (if metaKey then "Meta+" else "") +
      (if TextSlots.isOneCharacter key then key.toLowerCase() else key)

  # the verb I run for a key pressed with these modifiers on a keyboard of this family, or undefined where I do not
  # act on it as a command (typing, the keys processKeyDown's switch reads, a chord of another family)
  @verbFor: (key, ctrlKey, altKey, metaKey, family) ->
    CaretWdgt.chordVerbs[family]?[CaretWdgt.chordOf key, ctrlKey, altKey, metaKey] ?
      (CaretWdgt.keyVerbs[key] unless ctrlKey or metaKey)

  # WHETHER A KEYSTROKE MAY TYPE, rather than be a chord (one the tables do not name does nothing): with neither Ctrl
  # nor Cmd held, or as AltGr on a PC. Windows reports AltGr as Ctrl+Alt, so on a PC a key that is one character
  # (TextSlots.isOneCharacter), pressed with Ctrl and Alt and no Win key, is AltGr's character unless it is the
  # character the key's CODE names (_characterNamedByCode: the @ of AltGr+Q or the € of AltGr+E on a German layout,
  # the ą of AltGr+A on a Polish one type; Ctrl+Alt+A on a US layout is a chord, typing nothing, as on Windows). A
  # code names a key by its place on a US layout, so on another layout, or on a punctuation key, Ctrl+Alt on a key
  # that has no AltGr character types that key's own character, where Windows types nothing. Elsewhere AltGr arrives
  # with neither Ctrl nor Alt held (Linux reports it as the AltGraph state), and a Mac's Option types with no Ctrl
  # held; its Ctrl chords do nothing (strict). Asked wherever a key may type: my keystrokes, and a spreadsheet's
  # type-to-edit (SimpleSpreadsheetWdgt._isPrintable).
  @keystrokeMayType: (key, code, ctrlKey, altKey, metaKey, family) ->
    return false if metaKey
    return true unless ctrlKey
    family is "pc" and altKey and (TextSlots.isOneCharacter key) and key.toLowerCase() isnt CaretWdgt._characterNamedByCode code

  # the character a key's code names, where the code names one whatever the layout's place for it: a letter or digit
  # key by its US-layout letter or digit ("KeyQ" -> "q", "Digit7" -> "7"), a numpad digit ("Numpad7" -> "7"), the
  # space bar (" "); undefined for any other key
  @_characterNamedByCode: (code) ->
    return " " if code is "Space"
    match = /^(?:Key([A-Z])|Digit([0-9])|Numpad([0-9]))$/.exec code ? ""
    (match[1] ? match[2] ? match[3]).toLowerCase() if match?

  # CaretWdgt event processing:

  processKeyDown: (key, code, shiftKey, ctrlKey, altKey, metaKey) ->

    # see:
    #   https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key/Key_Values
    #   https://w3c.github.io/uievents/tools/key-event-viewer.html

    verb = CaretWdgt.verbFor key, ctrlKey, altKey, metaKey, world.user.keyboardFamily
    if verb?
      @[verb] shiftKey
    else if CaretWdgt.keystrokeMayType key, code, ctrlKey, altKey, metaKey, world.user.keyboardFamily
      switch key
        when " "
          @insert " "
        when "Delete"
          @deleteRight()
        when "Backspace"
          @deleteLeft()
        when "Tab"
          if @target?
            if shiftKey
              return @target.backTab @target
            else
              # SimpleTextWdgt inserts two spaces on Tab; every other target
              # handles Tab itself (instead of `@target instanceof SimpleTextWdgt`;
              # type-test-elimination campaign)
              if @target.tabInsertsSpaces?()
                @insert "  "
              else
                return @target.tab @target
        when "Enter"
          # A single-line StringWdgt accepts on Enter; a multi-line TextWdgt (and any
          # other StringWdgt subclass) inserts a newline. enterKeyAccepts is true only on
          # the bare StringWdgt and overridden false down the tree -- which is why this
          # can't be `instanceof StringWdgt` (a TextWdgt is-a StringWdgt).
          # (type-test-elimination campaign)
          if @target.enterKeyAccepts?()
            @accept (if shiftKey then "Shift+Enter" else "Enter")
          else
            @insert "\n"
        when "Escape"
          @cancel()
        # don't insert anything in case of shift or alt or CapsLock
        when "Shift", "Alt", "CapsLock"
          return
        else
          @_typeKey key, shiftKey

    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", key, code, shiftKey, ctrlKey, altKey, metaKey
    @_updateDimension()
    # The target geometry is now final (its parent told, the caret re-sized for the new text): converge any
    # deferred caret scroll-follow IN-PLACE, during this keystroke event, rather than leaving it to ride the
    # end-of-cycle flush. (No-op for a nav/no-move keystroke -- see _settleScrollFollow. Typing/delete enqueue
    # off-settle here, so this is where their follow settles.)
    @_settleScrollFollow()

  # A key the switch above does not name types itself only when it IS one character (TextSlots.isOneCharacter):
  # a letter, a digit, a symbol, an emoji. Any other key arrives by its NAME ("PageDown", "F3", "Insert", the
  # "Dead" of an accent waiting for its letter, "Unidentified"), and a name is not text.
  _typeKey: (key, shiftKey) ->
    # public-call-sanctioned: the keystroke DISPATCHER branch -- insert is the public typing command, one
    # settle per discrete keystroke.
    if !key? then console.error "INVARIANT_VIOLATED: a keystroke to insert has no key"
    @insert key, shiftKey if TextSlots.isOneCharacter key

  processCut: (selectedText) ->
    @deleteLeft()
    @_settleScrollFollow()   # converge the deferred caret follow in-place (clipboard event, bypasses processKeyDown)

  processPaste: (clipboardText) ->
    @insert clipboardText
    @_settleScrollFollow()   # converge the deferred caret follow in-place (clipboard event, bypasses processKeyDown)

  
  # gotoSlot is the public "move the caret to slot N" API: it SELF-SETTLES -- the move + scroll-follow flush once,
  # DURING the event that moved the caret (the doOneCycle model: process events fixing layouts step by step,
  # then run the end-of-cycle flush, then paint). Reached cross-widget (world.caret.gotoSlot from StringWdgt/TextWdgt click
  # handlers) and by the caret's own click / undo-redo restore; the navigation keystrokes move through the
  # non-settling core, each inside its own settle. Per-keystroke caret navigation is NOT a high-traffic stream, so it does NOT defer its settle
  # (contrast _setMaxDimDeferredSettle, for ~50-per-frame drag/scroll STREAMS) -- each keystroke self-settles, one flush
  # per discrete move. The follow NEVER rides the end-of-cycle flush.
  #   _gotoSlotNoSettle does ONLY the layout-free work: clamp the slot, re-place the caret where it stands at the
  #   target's current slot (inert), do one best-effort scroll-follow pass inline (load-bearing for in-place typing --
  #   see below), and ENQUEUE the caret for the follow (_requestScrollFollow). The scroll-follow -- the only
  #   layout-MUTATING part -- then runs as the caret's OWN _reLayout, settled in-line with every other widget: the
  #   draining flush picks the caret up AFTER its target / scroll-panel are settled and iterates the follow to a
  #   fixed point via the until-loop -- no post-flush special-case, no hand-rolled convergence loop. The core is
  #   the non-settling member reached where the immediate flush is wrong: (1) typing/delete/paste, whose advance
  #   stays off-settle so the follow converges on the caret as the keystroke re-sizes it (_updateDimension; the
  #   viewport's follow reads the caret's box) -- their editing handler's tail (_settleScrollFollow) drains the
  #   follow in-place at the keystroke's end instead; and
  #   (2) construction (the caret is an orphan, so it defers and settles when first added).
  gotoSlot: (slot, becauseOfMouseClick) ->
    @_settleLayoutsAfter => @_gotoSlotNoSettle slot, becauseOfMouseClick

  _gotoSlotNoSettle: (slot, becauseOfMouseClick) ->
    # every placement ENDS my vertical run: a click, an arrow, Home, End, typing, a delete, an undo -- none has to say
    # so; an Up or Down starts a new run after its own placement (_goVerticallyNoSettle)
    @_verticalRun = undefined
    # clamp slot to [0, text length].
    length = @target.text.length
    @slot = (if slot < 0 then 0 else (if slot > length then length else slot))
    # a caret never stands inside a character (TextSlots): a slot comes from TextSlots, or from a text's own
    # answer that asks it (the hit test, a line's ends, a crop's shown end), so one that does not is a fault to
    # report, and the caret stands at that character's start
    unless TextSlots.isSlot @target.text, @slot
      console.error "INVARIANT_VIOLATED: caret slot #{@slot} stands inside a character of #{@target}"
      @slot = TextSlots.slotAtOrBefore @target.text, @slot

    # Scroll-follow the move ONE pass right here, DURING the event (not at paint). The pass reads its target
    # re-fitted (see _oneScrollCaretIntoViewPassNoSettle), so in in-place TYPING too (insert's advance,
    # before the keystroke's _updateDimension) it lands where the flush's pass would: that pass then moves
    # nothing and confirms in one visit. One pass suffices where the follow converges immediately (e.g. a
    # single-line horizontal scroll) ...
    @_oneScrollCaretIntoViewPassNoSettle()
    # ... and ENQUEUE the caret for the follow for the cases that need MORE than one pass (a viewport's
    # vertical follow advances only partway per pass): the caret's _reLayout runs the follow on settled geometry
    # and the until-loop iterates it to convergence, drained by the next IN-PLACE settle (the discrete move's own,
    # or the editing handler's tail). The wheel/scroll path does NOT come through here, so it never enqueues a
    # follow -- the viewport chases the caret only when the caret MOVES.
    @_requestScrollFollow()

    if becauseOfMouseClick and @target.undoHistory?.length == 0
      @target.pushUndoState? @slot, true

  # WHERE I STAND at my slot, in my target's plane: my target's caretTopLeftAt answers the slot's
  # boundary on its line, at the top of the caret box in that line, and I stand the theme's caretGap to
  # the right of that boundary -- at every slot, a line's first and last included -- so I never cover
  # the ink of the glyph before me. Both of my placements read it, so a move and a paint-time re-sync
  # put me in the same place.
  _myTopLeftAtSlot: ->
    @target.caretTopLeftAt(@slot)?.add new Point WorldWdgt.theme.caretGap, 0

  # The INERT re-place (no layout): put the caret where it stands at its target's current slot
  # (_myTopLeftAtSlot). Called only by the paint/ctor re-sync (_adjustAccordingToTargetText); a caret MOVE
  # places itself UN-clamped inside _oneScrollCaretIntoViewPassNoSettle instead (Point.floor() here clamps
  # to >=0 -- exactly the clamp the 2026-07-01 single-pass follow fix removed for moves; see the note there).
  _repositionToSlotNoSettle: ->
    pos = @_myTopLeftAtSlot()
    if pos?
      # public-call-sanctioned: show is the heavily-public visibility verb (settle-free one-liner);
      # consciously reused by this core.
      @show()
      @_applyMoveTo pos.floor()

  # Schedule THIS caret for a scroll-follow so its _reLayout runs the follow on settled geometry -- the caret
  # settles like any other widget whose layout changed, drained by the NEXT settle (always IN-PLACE, during the
  # event: a discrete click/arrow move self-settles via gotoSlot/goLeft/goRight; a typing/delete/paste advance
  # defers to its editing handler's tail, _settleScrollFollow -- see there). The caret never rides the end-of-cycle
  # flush (it does not defer its settle). It schedules via the CANONICAL _invalidateLayout: the caret is
  # free-floating + inert, so _invalidateLayout's INERT-RECEIVER branch enqueues it with the bare no-climb primitive
  # (__markForRelayout) and skips the climb / flow-rule throw / careless-push audit -- all of which are
  # structurally INAPPLICABLE to an overlay that has no parent layout to climb and no ancestor it can re-dirty
  # (Widget._invalidateLayout; docs/archive/unify-layout-enqueue-primitives-plan.md §2). This USED to open-code the bare
  # push here to dodge that throw + audit (which fired because _invalidateLayout assumed a climbing content widget);
  # the inert branch now makes the canonical verb correct for the caret, so there is ONE scheduling verb, not two.
  # The schedule is correct in BOTH phases -- inside a pass the until-loop picks the caret up; off-pass the next
  # in-place settle drains it. (See WorldWdgt._recalculateLayoutsBody.)
  _requestScrollFollow: ->
    @_invalidateLayout()

  # The caret's layout step IS the scroll-follow. It does ONE pass of _oneScrollCaretIntoViewPassNoSettle then marks
  # itself layout-fixed once no CORRECTIVE container move was needed (see the stable check below). It settles in a
  # SINGLE visit for a caret that only repositions along its line (e.g. typing across a wrapping field -- the common
  # case), and in one move + one confirming visit for a caret that also had to scroll its viewport. Two single-pass
  # properties make that hold (both 2026-07-01): (1) _oneScrollCaretIntoViewPassNoSettle places the caret at its
  # TRUE, un-clamped slot position, so ViewportWdgt.scrollCaretIntoView computes the FULL scroll in ONE call
  # (previously the caret was clamped to y>=0, so a far scroll advanced only one viewport-step per pass and the
  # content crawled to its mark over many re-visits); (2) convergence is detected on the CONTAINERS, not on the
  # caret's own reposition (which is an exact, idempotent one-shot needing no confirming pass). A move pass that DID
  # scroll re-enqueues the viewport (via the settle-time re-fit that succeeded the deleted geometry seam --
  # _reFitMyTrackingContainerAfterSettle / __markForRelayout, in-pass) AHEAD of the caret, and the caret stays
  # layoutIsValid==false so the loop re-runs it AFTER the viewport settles, confirming convergence. This iterates via
  # the flush's until-loop, not a hand-rolled loop; it is deterministic (same settled geometry in => same passes)
  # and bounded (only a true NON-TERMINATING cycle would ever hit WorldWdgt._recalculateLayoutsBody's sanity-limit
  # assert). The caret is isLayoutInert + childless, so there is no base _reLayout work to do (no bounds to fit,
  # no children to place) -- this override is the whole layout step.
  _reLayout: ->
    beforeParentT = @parent?.top() ; beforeParentL = @parent?.left()
    beforeTargetT = @target?.top() ; beforeTargetL = @target?.left()
    @_oneScrollCaretIntoViewPassNoSettle()
    # converged when no CORRECTIVE CONTAINER move was needed this pass -- neither the scroll container (my parent =
    # the viewport's contents) nor the target text had to move to keep me in view. The caret's OWN reposition
    # to its slot is an exact, idempotent one-shot, so a pass that ONLY repositioned the caret is already at the
    # fixed point and needs no confirming re-visit.
    #   INVARIANT this leans on: placing the caret where it stands at its slot (_myTopLeftAtSlot) is idempotent (a
    # direct absolute move), the horizontal clamp moves nothing on a pass after the one that clamped, and my
    # target/panel settle BEFORE me (the flush drains parent-first; the caret is freefloating + inert, drained
    # last). Marking fixed here can only REDUCE settle iterations vs the old "did anything move" check -- it can
    # never ADD a cycle. If a future text-relayout change ever broke that invariant (so my slot moved AFTER I
    # marked fixed), TWO backstops catch it, NEITHER silent: (1) a wrong caret position fails the byte-exact
    # SystemTest suite -- the caret is screenshotted in ~a dozen tests (macroWrappingTextFieldResizesOK,
    # macroMultilineTextInputScrollsWell, the *CaretBroughtIntoView* pair, macroTextWdgtCaretResizing, ...); and
    # (2) an actual non-terminating cycle throws RECALC_NONCONVERGENCE at WorldWdgt._recalculateLayoutsBody's
    # sanity limit, naming this widget (and the determinism torture greps for that token). So a regression here
    # surfaces loudly and is diagnosable -- it does not hang the tab or render 1px-off unnoticed.
    stable = @parent?.top() == beforeParentT and @parent?.left() == beforeParentL and @target?.top() == beforeTargetT and @target?.left() == beforeTargetL
    if stable
      @_markLayoutAsFixed()
    # else: stay layoutIsValid==false -- still in the queue, re-processed after the just-enqueued panel settles

  # Converge the caret's pending scroll-follow IN-PLACE, during the event -- called at the tail of each caret
  # EDITING-event handler (processKeyDown / processCut / processPaste), once the target geometry is final. The
  # discrete moves (click/arrow/Home/End) already settle in-place: their public gotoSlot/goLeft/goRight wrap the
  # advance in _settleLayoutsAfter. The typing/delete/paste advance does not -- it runs inside the editing
  # handler, before the caret is re-sized for the new text (see goLeft/goRight), so it enqueues the caret
  # OFF-settle (_requestScrollFollow) and the convergence is deferred to here, the keystroke's end. This
  # drains it now -- in-place, "step by step" per the doOneCycle invariant -- instead of letting it ride the
  # end-of-cycle flush (the caret is discrete, not a deferred-settle stream, so it belongs in the per-event
  # settle). Reuses the standard in-place settle (_settleLayoutsAfter) with an EMPTY core: the work (the enqueue +
  # the one inline pass) already happened in the advance; we only need to DRAIN the queue now and let the caret's
  # _reLayout iterate the follow to a fixed point. No-op when nothing is pending -- a nav keystroke (already
  # self-settled via gotoSlot), or a keystroke whose reactToKeystroke re-fit happened to self-settle and drain the
  # caret early; in both cases @layoutIsValid is back to true.
  _settleScrollFollow: ->
    # early-return-sanctioned: the guard is the "is a follow pending?" predicate, not a state-skip that belongs in
    #   a _<name>NoSettle core -- this settle has no core (it is a pure drain of an already-enqueued inert overlay).
    return if @layoutIsValid
    @_settleLayoutsAfter => undefined

  # A SINGLE scroll-follow pass (see _reLayout, which iterates this to a fixed point via the flush). Re-derives
  # where the caret stands from the current (settled) geometry, applies the horizontal clamp (which scrolls
  # @target and adjusts where the caret lands), re-places the caret, then asks the viewport to scroll it
  # into view.
  #   Every pass reads its target RE-FITTED first (actualFontSizeUsedInRendering): a keystroke's setText leaves
  # a box-fitted text's size to be redone, and a pass measuring the old size would put the caret where the
  # next pass, measuring the new one, has to move it again -- a corrective second visit of the flush. Read
  # re-fitted, the pass the event runs inline and the flush's confirming pass measure the same text.
  # One convergence pass driven by the caret's _reLayout. It has no public twin: the flush settles it, no
  # self-settling wrapper does.
  _oneScrollCaretIntoViewPassNoSettle: ->
    fontSize = @target.actualFontSizeUsedInRendering()
    pos = @_myTopLeftAtSlot()
    if pos?
      # The caret's TRUE place at its slot, integer-floored but WITHOUT Point.floor()'s clamp-to->=0
      # (Math.max(_, 0)): when the content is scrolled up, a slot above the world origin has a NEGATIVE absolute y.
      # Clamping the caret to 0 there capped scrollCaretIntoView -- which scrolls by (ft - caretWidget.top()) -- at
      # ONE viewport-step (ft) per pass, so a far caret converged over MANY settle re-visits (contents crawled to
      # its mark in +ft steps). Placing the caret at its real (possibly negative, off-viewport, harmlessly clipped)
      # position lets scrollCaretIntoView compute the FULL scroll delta in ONE pass -- byte-identical fixed point,
      # but the follow settles in a single move + verify instead of distance/ft passes. The final resting
      # position is always in view (positive), so the rendered caret is unchanged. Floored BEFORE the clamp,
      # so the clamp below keeps the very box the caret is drawn in, and moves the target by whole pixels.
      pos = new Point (Math.floor pos.x), (Math.floor pos.y)
      if @parent and @target.isScrollable and !@_amIDirectlyInsideViewport()
        # THE HORIZONTAL CLAMP keeps the caret's WHOLE box -- its gap past its slot's boundary and its width,
        # not the boundary alone -- inside its parent less viewPadding at each side: left <= the caret's left,
        # and the caret's right <= right. Where it would not be, the TARGET moves (it scrolls in its field) and
        # the caret moves with it, so a caret at either edge of a clipping field (a prompt's entry, a cell's
        # editor) shows in full, clear of the field's 1 px border; anywhere else nothing moves and the caret
        # stands where its slot puts it. The width is read at the size the slot geometry above is read at (the
        # re-fitted one). Every StringWdgt is isScrollable, so a text that does not scroll moves too, when a
        # caret at a line's end would leave its parent.
        #   A VIEWPORT'S PLANE is no band to clamp to: the viewport scrolls the caret into view itself (below)
        # and grows its plane to the window it shows, so the plane's edge follows the caret: a band inset from
        # that edge is undone by the same pass's follow, and the flush's next pass would move the target again.
        width = (@_extentAtTargetFontSize fontSize).x
        right = @parent.right() - @viewPadding
        left = @parent.left() + @viewPadding
        if pos.x + width > right
          @target._moveLeftSideTo @target.left() + right - (pos.x + width)
          pos = new Point right - width, pos.y
        if pos.x < left
          @target._moveLeftSideTo @target.left() + left - pos.x
          pos = new Point left, pos.y
        # a target wider than that band whose right edge has come short of the band's (scrolled too far
        # left) slides back right: up to that edge, and no further than keeps the caret's box inside the
        # band -- sliding the target's edge all the way would carry a caret at the text's end straight back
        # past the band, undoing the first clamp in the same pass
        if @target.right() < right and right - @target.width() < left
          slide = Math.min right - @target.right(), right - (pos.x + width)
          if slide > 0
            @target._moveRightSideTo @target.right() + slide
            pos = new Point pos.x + slide, pos.y
      # public-call-sanctioned: show is the heavily-public visibility verb (settle-free one-liner);
      # consciously reused by this core.
      @show()
      @_applyMoveTo pos

      if @_amIDirectlyInsideViewport() and @target.isScrollable
        @parent.parent.scrollCaretIntoView @

  
  # Navigation keystrokes SELF-SETTLE (one flush per arrow press, during the event) -- caret navigation is not a
  # high-traffic stream, so it does not defer its settle (see the comment on gotoSlot). The caret's moves inside an
  # edit (insert advancing past what it typed, deleteLeft stepping back over what it deleted) must NOT self-settle
  # early -- the flush would converge the follow before the keystroke re-sizes the caret for the new text
  # (_updateDimension), and the viewport's follow reads the caret's box. They move with the non-settling
  # _gotoSlotNoSettle, which enqueues the follow off-settle, and the editing handler's tail settles it in-place once
  # the caret is re-sized (processKeyDown -> _settleScrollFollow). goLeft/goRight and goUp/goDown are self-settling
  # public wrappers (the keystroke path) around a non-settling core (_goLeftNoSettle, _goRightNoSettle,
  # _goVerticallyNoSettle), as the line, document and word jumps are around _jumpToNoSettle. Each step is one
  # CHARACTER, wherever that is more than one code unit (TextSlots). updateSelection / clearSelectionIf... only
  # touch selection marks (no layout).
  goLeft: (shift) ->
    @_settleLayoutsAfter => @_goLeftNoSettle shift
  _goLeftNoSettle: (shift) ->
    if !shift and @target.firstSelectedSlot()?
      @_gotoSlotNoSettle @target.firstSelectedSlot()
      @updateSelection shift
    else
      @updateSelection shift
      @_gotoSlotNoSettle TextSlots.slotBefore @target.text, @slot
      @updateSelection shift
      @clearSelectionIfStartAndEndMeet shift

  goRight: (shift) ->
    @_settleLayoutsAfter => @_goRightNoSettle shift
  _goRightNoSettle: (shift) ->
    if !shift and @target.lastSelectedSlot()?
      @_gotoSlotNoSettle @target.lastSelectedSlot()
      @updateSelection shift
    else
      @updateSelection shift
      @_gotoSlotNoSettle TextSlots.slotAfter @target.text, @slot
      @updateSelection shift
      @clearSelectionIfStartAndEndMeet shift

  # Up and Down share one core (_goVerticallyNoSettle), self-settling as goLeft and goRight do.
  goUp: (shift) ->
    @_settleLayoutsAfter => @_goVerticallyNoSettle shift, true

  goDown: (shift) ->
    @_settleLayoutsAfter => @_goVerticallyNoSettle shift, false

  # THE COLUMN an Up or Down keeps is DERIVED from the vertical run I am on (_verticalRun): a run goes on only from
  # Up or Down to Up or Down, with no other placement of mine between them (each ends it) and my text unchanged, so
  # two Downs across a short line land back under the column the first one started from; after any other move or
  # edit the next Up or Down starts from where I stand. No move has to remember a column.
  _columnForVerticalMove: ->
    run = @_verticalRun
    if run? and run.text is @target.text then run.columnSlot else @slot

  # a plain Up or Down over a selection only collapses it, to its first or its last slot; else I land on the line
  # above or below, under the run's column (_columnForVerticalMove), and the run goes on from there
  _goVerticallyNoSettle: (shift, up) ->
    if !shift and @target.lastSelectedSlot()?
      @_gotoSlotNoSettle (if up then @target.firstSelectedSlot() else @target.lastSelectedSlot())
      @updateSelection shift
    else
      column = @_columnForVerticalMove()
      @updateSelection shift
      @_gotoSlotNoSettle (if up then @target.upFrom @slot, column else @target.downFrom @slot, column)
      @updateSelection shift
      @clearSelectionIfStartAndEndMeet shift
      @_verticalRun = text: @target.text, columnSlot: column

  # THE ONE JUMP every line, document and word move makes: to `slot`, the selection extended to it while Shift is held
  _jumpToNoSettle: (slot, shift) ->
    @updateSelection shift
    @_gotoSlotNoSettle slot
    @updateSelection shift
    @clearSelectionIfStartAndEndMeet shift

  # the line's ends (Home and End; on a Mac, Cmd+Left and Cmd+Right too)
  goHome: (shift) ->
    @_settleLayoutsAfter => @_jumpToNoSettle (@target.startOfLine @slot), shift

  goEnd: (shift) ->
    @_settleLayoutsAfter => @_jumpToNoSettle (@target.endOfLine @slot), shift

  # the text's ends (Cmd+Up and Cmd+Down on a Mac, Ctrl+Home and Ctrl+End on a PC)
  goDocumentStart: (shift) ->
    @_settleLayoutsAfter => @_jumpToNoSettle 0, shift

  goDocumentEnd: (shift) ->
    @_settleLayoutsAfter => @_jumpToNoSettle @target.text.length, shift

  # the word jumps (TextSlots's words): left to a word's start in both families; right to the word's end on a Mac
  # (Option+Right), to the next word's start on a PC (Ctrl+Right)
  goWordStart: (shift) ->
    @_settleLayoutsAfter => @_jumpToNoSettle (TextSlots.wordStartBefore @target.text, @slot), shift

  goWordEnd: (shift) ->
    @_settleLayoutsAfter => @_jumpToNoSettle (TextSlots.wordEndAfter @target.text, @slot), shift

  goNextWordStart: (shift) ->
    @_settleLayoutsAfter => @_jumpToNoSettle (TextSlots.wordStartAfter @target.text, @slot), shift

  # Cmd+A on a Mac, Ctrl+A on a PC: my target selects all it shows (Shift changes nothing)
  selectAll: (shift) ->
    @target.selectAll()

  gotoPos: (aPoint) ->
    slotToGoTo = @target.slotAt aPoint
    @gotoSlot slotToGoTo   # discrete (click-to-position) -> public self-settling gotoSlot
    @show()
    return slotToGoTo

  clearSelectionIfStartAndEndMeet: (shift) ->
    if shift
      @target.clearSelectionIfCollapsed()

  updateSelection: (shift) ->
    if shift
      @target.anchorOrExtendSelectionTo @slot
    else
      @target.clearSelection()
  
  # CaretWdgt editing.

  # User presses enter on a stringWidget (or clicks/actions away from the edit — the
  # pointer's action-elsewhere funnel accepts too). The escalation climbs from the TARGET,
  # not from me: stopEditing destroys me and clears my @parent, so an escalation from the
  # caret could never deliver (it climbed from undefined — nobody ever received these events
  # until the spreadsheet cell became the first consumer). The target is still parented
  # at this moment, so accept/cancel reach ITS parent chain — for a spreadsheet cell
  # editor that is cell → cells panel → sheet, for its formula bar the bar.
  #   `how` is the key that ended the edit, "Enter" or "Shift+Enter", and undefined when acting
  # elsewhere ended it: a receiver that moves on after a key (a spreadsheet's selection steps
  # down, or up) must not move when the user simply clicked away. It rides the escalation as its
  # argument.
  accept: (how) ->
    target = @target
    world.stopEditing()
    target.escalateEvent "accept", how

  # User presses ESC
  cancel: ->
    target = @target
    world.stopEditing()
    target.escalateEvent 'cancel', undefined

  # User presses Cmd+Z (a Mac) or Ctrl+Z (a PC); with Shift held, that redoes (redo)
  undo: (shiftKey) ->
    return @redo() if shiftKey
    if !@target.undoHistory?
      return

    if @target.undoHistory.length > 1
      @target.popUndoState()
      undoState = @target.undoHistory[@target.undoHistory.length - 1]
      @bringTextAndCaretToState undoState

  # User presses Shift with the undo chord, or Ctrl+Y on a PC (chordVerbs): the last undone state comes back
  # (Shift changes nothing)
  redo: (shift) ->
    if !@target.undoHistory?
      return

    redoState = @target.popRedoState()
    if redoState?
      @bringTextAndCaretToState redoState

  bringTextAndCaretToState: (state) ->
    # gotoSlot is the designed public one-settle caret-move entry; an undo/redo restore is a
    # discrete event outside any pass, so the self-settling form is exactly right here. (This
    # method stays PUBLIC: its setText drive makes the _-form an [A] violation — see the
    # public-api-allowlist entry.)
    @target.setText state.textContent
    @gotoSlot state.cursorPos   # discrete (undo/redo restore) -> public self-settling gotoSlot
    if state.selectionStart? and state.selectionEnd?
      @target.selectBetween state.selectionStart, state.selectionEnd
    else
      @target.clearSelection()
  
  insert: (key, shiftKey) ->
    # if the target "isNumeric", then only accept
    # numbers and "-" and "." as input
    if not @target.isNumeric or not isNaN(parseFloat(key)) or key in ["-", "."]
      
      # Pushed before AND after the change (not redundant): (1) before, so an insert that replaces a
      # selection saves state pre-selection-touch, letting undo return the user there; (2) before, so
      # undo lands on the position BEFORE an edit rather than jumping to the end of the prior edit,
      # matching real-editor undo semantics. In continuous typing this doesn't spam history:
      # pushUndoState dedupes a state that is only a position change of one character from the previous state.

      @target.pushUndoState? @slot

      if @target.selection() isnt ""
        @_gotoSlotNoSettle @target.firstSelectedSlot()
        @target.deleteSelection()
      text = @target.text
      text = text.slice(0, @slot) + key + text.slice(@slot)
      # this is a setText that will trigger the text
      # connections "from within", starting a new connections
      # update round
      @target.setText text
      # The text just GREW: if it no longer fits a CROP-overflow field, hand off to the pop-out editor NOW, at
      # event time (off the flush). This is the explicit home of what used to fire lazily + impurely inside
      # slotCoordinates -- insert (typing + paste) is the only path that can grow inline-edited text past the
      # fit. If it hands off, the inline caret is gone, so stop here (no advance / dimension / undo to do).
      return if @target.handOffToPopoutEditorIfOverflowing()
      # the caret ADVANCES PAST what was typed, however many characters that is (a paste, the two spaces of a
      # Tab): an offset, not a step, and past the whole of a character the typing joined to the one after it (a
      # flag's second half typed before its first). setText dropped any selection. Settles at the handler's tail,
      # NOT early (see goLeft/goRight).
      @_gotoSlotNoSettle TextSlots.slotAtOrAfter @target.text, @slot + key.length
      @_updateDimension()
      @target.pushUndoState? @slot
  
  deleteRight: ->
    if @target.selection() isnt ""
      @_gotoSlotNoSettle @target.firstSelectedSlot()
      @target.deleteSelection()
    else
      text = @target.text
      @target.setText text.slice(0, @slot) + text.slice TextSlots.slotAfter text, @slot

  # Backspace deletes the character before me whole (TextSlots), and I step back over it: to where it began, or
  # to the start of the character its two neighbours joined into once it went (two flag halves)
  deleteLeft: ->
    if @target.selection()
      @_gotoSlotNoSettle @target.firstSelectedSlot()
      @target.deleteSelection()
    else
      text = @target.text
      before = TextSlots.slotBefore text, @slot
      @target.setText text.slice(0, before) + text.slice @slot
      # internal: settles at the handler's tail, NOT early (see goLeft/goRight)
      @_gotoSlotNoSettle TextSlots.slotAtOrBefore @target.text, before

    @updateSelection false
    @_gotoSlotNoSettle @slot
    @updateSelection false
    @clearSelectionIfStartAndEndMeet false

  # THE DELETE CHORDS (chordVerbs): each deletes from me to where its family's move of the same reach lands (the
  # slot goWordStart, goHome, goWordEnd or goNextWordStart goes to) -- the span is selected, without moving me, and
  # Backspace or Delete deletes the selection -- so a word or a line goes as the person's platform jumps over it.
  # A selection already made is deleted instead, as Backspace and Delete delete one; where the move would go
  # nowhere (Cmd+Backspace at a line's start) the key deletes one character, as Backspace or Delete does.
  # (Shift changes nothing.)
  deleteToWordStart: (shift) ->
    @target.selectBetween @slot, (TextSlots.wordStartBefore @target.text, @slot) unless @target.selection()
    @deleteLeft()

  deleteToLineStart: (shift) ->
    @target.selectBetween @slot, (@target.startOfLine @slot) unless @target.selection()
    @deleteLeft()

  deleteToWordEnd: (shift) ->
    @target.selectBetween @slot, (TextSlots.wordEndAfter @target.text, @slot) unless @target.selection()
    @deleteRight()

  deleteToNextWordStart: (shift) ->
    @target.selectBetween @slot, (TextSlots.wordStartAfter @target.text, @slot) unless @target.selection()
    @deleteRight()
