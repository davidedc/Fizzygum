# I mark where the caret is in a String/Text while editing

class CaretWdgt extends BlinkerWdgt

  target: nil
  slot: nil
  viewPadding: 1
  currentCaretFontSize: nil

  constructor: (@target) ->
    # additional properties:
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
    @adjustAccordingToTargetText()

  # CaretWdgt is overlay chrome (the text-editing caret), not a content child, so
  # it is excluded from content-bounds and real-children calculations (see
  # Widget.fullBounds and TreeNode.childrenNotHandlesNorCarets).
  isLayoutInert: -> true

  # I am a transient overlay, so I am skipped by the add-time drop-shadow management in
  # Widget.add (was `instanceof CaretWdgt` there). (type-test-elimination campaign)
  skipsAddShadowManagement: -> true

  # The INERT re-sync of the caret to its target: re-size it to the target's font height and re-place it
  # on the target's CURRENT slot coordinate. The caret is isLayoutInert, so this schedules / mutates NO
  # layout -- it is READ-ONLY w.r.t. the layout tree and therefore safe to run at PAINT time
  # (justBeforeBeingPainted). It deliberately does NOT scroll-follow: bringing the caret into view mutates
  # layout (moves @target / @contents) and must happen out of paint -- that is the caret's _reLayout, settled
  # inside the end-of-cycle flush (see _requestScrollFollow / _reLayout). (Also called from the constructor.)
  adjustAccordingToTargetText: ->
    @updateDimension()
    @_repositionToSlotNoSettle()

  # PAINT is read-only: the only caret work here is the inert re-place above (no scroll-follow, no layout).
  justBeforeBeingPainted: ->
    @adjustAccordingToTargetText()

  updateDimension: ->
    ls = @target.fontHeight @target.actualFontSizeUsedInRendering()
    if ls != @currentCaretFontSize
      @currentCaretFontSize = ls
      @_applyExtent new Point Math.max(Math.floor(ls / 20), 1), ls
  
  # CaretWdgt event processing:

  processKeyDown: (key, code, shiftKey, ctrlKey, altKey, metaKey) ->

    # see:
    #   https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key/Key_Values
    #   https://w3c.github.io/uievents/tools/key-event-viewer.html

    if ctrlKey
      @ctrl key, shiftKey
    else if metaKey
      @cmd key, shiftKey
    else
      switch key
        when " "
          @insert " "
        when "ArrowLeft"
          @goLeft shiftKey
        when "ArrowRight"
          @goRight shiftKey
        when "ArrowUp"
          @goUp shiftKey
        when "ArrowDown"
          @goDown shiftKey
        when "Home"
          @goHome shiftKey
        when "End"
          @goEnd shiftKey
        when "Delete"
          @deleteRight()
        when "Backspace"
          @deleteLeft()
        when "Tab"
          if @target?
            if shiftKey
              return @target.backTab @target
            else
              # SimplePlainTextWdgt inserts two spaces on Tab; every other target
              # handles Tab itself (was `@target instanceof SimplePlainTextWdgt`).
              # (type-test-elimination campaign)
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
            @accept()
          else
            @insert "\n"
        when "Escape"
          @cancel()
        # don't insert anything in case of shift or alt or CapsLock
        when "Shift", "Alt", "CapsLock"
          return
        else
          if !key? then debugger
          @insert key, shiftKey

    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", key, code, shiftKey, ctrlKey, altKey, metaKey
    @updateDimension()
    # The target geometry is now final (reactToKeystroke re-fit done): converge any deferred caret scroll-follow
    # IN-PLACE, during this keystroke event, rather than leaving it to ride the end-of-cycle flush. (No-op for a
    # nav/no-move keystroke -- see _settleScrollFollow. Typing/delete enqueue off-settle here, so this is
    # where their follow settles, AFTER the reactToKeystroke re-fit the inline advance pass had to precede.)
    @_settleScrollFollow()

  processCut: (selectedText) ->
    @deleteLeft()
    @_settleScrollFollow()   # converge the deferred caret follow in-place (clipboard event, bypasses processKeyDown)

  processPaste: (clipboardText) ->
    @insert clipboardText
    @_settleScrollFollow()   # converge the deferred caret follow in-place (clipboard event, bypasses processKeyDown)

  
  # gotoSlot is the public "move the caret to slot N" API: it SELF-SETTLES -- the move + scroll-follow flush once,
  # DURING the event that moved the caret (the doOneCycle model: process events fixing layouts step by step,
  # then flush coalesced, then paint). Reached cross-widget (world.caret.gotoSlot from StringWdgt/TextWdgt click
  # handlers), by the caret's own click / undo-redo restore, AND by the arrow / Home / End navigation keystrokes
  # (goLeft/goRight/...). Per-keystroke caret navigation is NOT a high-traffic stream, so it does NOT coalesce
  # (contrast _setMaxDimDeferredSettle, for ~50-per-frame drag/scroll STREAMS) -- each keystroke self-settles, one flush
  # per discrete move. The follow NEVER rides the end-of-cycle coalesced flush.
  #   _gotoSlotNoSettle does ONLY the layout-free work: clamp the slot, re-place the caret on the target's current
  #   slot coordinate (inert), do one best-effort scroll-follow pass inline (load-bearing for in-place typing --
  #   see below), and ENQUEUE the caret for the follow (_requestScrollFollow). The scroll-follow -- the only
  #   layout-MUTATING part -- then runs as the caret's OWN _reLayout, settled in-line with every other widget: the
  #   draining flush picks the caret up AFTER its target / scroll-panel are settled and iterates the follow to a
  #   fixed point via the until-loop -- no post-flush special-case, no hand-rolled convergence loop. The core is
  #   the non-settling member reached where the immediate flush is wrong: (1) typing/delete/paste, whose advance
  #   must stay off-settle so its inline pass precedes the keystroke's reactToKeystroke re-fit -- their editing
  #   handler's tail (_settleScrollFollow) drains the follow in-place at the keystroke's end instead; and
  #   (2) construction (the caret is an orphan, so it defers and settles when first added).
  gotoSlot: (slot, becauseOfMouseClick) ->
    @_settleLayoutsAfter => @_gotoSlotNoSettle slot, becauseOfMouseClick

  _gotoSlotNoSettle: (slot, becauseOfMouseClick) ->
    # check that slot is within the allowed boundaries of
    # of zero and text length.
    length = @target.text.length
    @slot = (if slot < 0 then 0 else (if slot > length then length else slot))

    # Scroll-follow the move ONE pass right here, DURING the event (not at paint). This is load-bearing for
    # in-place TYPING (insert -> _goRightNoSettle): the advance scroll must happen BEFORE the keystroke's
    # escalateEvent re-fit, which reads the (now-scrolled) target geometry -- deferring it past that re-fit
    # shifts the result (macroStringWdgtInlineTypingRefitsUnderFittingModes). One pass suffices where the
    # follow converges immediately (e.g. a single-line horizontal scroll) ...
    @_oneScrollCaretIntoViewPassNoSettle()
    # ... and ENQUEUE the caret for the follow for the cases that need MORE than one pass (a scroll panel's
    # vertical follow advances only partway per pass): the caret's _reLayout runs the follow on settled geometry
    # and the until-loop iterates it to convergence, drained by the next IN-PLACE settle (the discrete move's own,
    # or the editing handler's tail). The wheel/scroll path does NOT come through here, so it never enqueues a
    # follow -- the panel chases the caret only when the caret MOVES.
    @_requestScrollFollow()

    if becauseOfMouseClick and @target.undoHistory?.length == 0
      @target.pushUndoState? @slot, true

  # The INERT re-place (no layout): put the caret at the target's current slot coordinate. Shared by the
  # paint/ctor re-sync (adjustAccordingToTargetText) and every caret move (_gotoSlotNoSettle).
  _repositionToSlotNoSettle: ->
    pos = @target.slotCoordinates @slot
    if pos?
      @show()
      @_applyMoveTo pos.floor()

  # Schedule THIS caret for a scroll-follow so its _reLayout runs the follow on settled geometry -- the caret
  # settles like any other widget whose layout changed, drained by the NEXT settle (always IN-PLACE, during the
  # event: a discrete click/arrow move self-settles via gotoSlot/goLeft/goRight; a typing/delete/paste advance
  # defers to its editing handler's tail, _settleScrollFollow -- see there). The caret never rides the end-of-cycle
  # coalesced flush (it does not coalesce). It schedules via the CANONICAL _invalidateLayout: the caret is
  # free-floating + inert, so _invalidateLayout's INERT-RECEIVER branch enqueues it with the bare no-climb primitive
  # (__markForRelayout) and skips the climb / flow-rule throw / careless-push audit -- all of which are
  # structurally INAPPLICABLE to an overlay that has no parent layout to climb and no ancestor it can re-dirty
  # (Widget._invalidateLayout; docs/unify-layout-enqueue-primitives-plan.md §2). This USED to open-code the bare
  # push here to dodge that throw + audit (which fired because _invalidateLayout assumed a climbing content widget);
  # the inert branch now makes the canonical verb correct for the caret, so there is ONE scheduling verb, not two.
  # The schedule is correct in BOTH phases -- inside a pass the until-loop picks the caret up; off-pass the next
  # in-place settle drains it. (See WorldWdgt._recalculateLayoutsBody.)
  _requestScrollFollow: ->
    @_invalidateLayout()

  # The caret's layout step IS the scroll-follow. It does ONE pass of _oneScrollCaretIntoViewPassNoSettle then marks
  # itself layout-fixed once no CORRECTIVE container move was needed (see the stable check below). It settles in a
  # SINGLE visit for a caret that only repositions along its line (e.g. typing across a wrapping field -- the common
  # case), and in one move + one confirming visit for a caret that also had to scroll its panel. Two single-pass
  # properties make that hold (both 2026-07-01): (1) _oneScrollCaretIntoViewPassNoSettle places the caret at its
  # TRUE, un-clamped slot position, so ScrollPanelWdgt.scrollCaretIntoView computes the FULL scroll in ONE call
  # (previously the caret was clamped to y>=0, so a far scroll advanced only one viewport-step per pass and the
  # content crawled to its mark over many re-visits); (2) convergence is detected on the CONTAINERS, not on the
  # caret's own reposition (which is an exact, idempotent one-shot needing no confirming pass). A move pass that DID
  # scroll re-enqueues the scroll panel (via the settle-time re-fit that succeeded the deleted geometry seam --
  # _reFitMyTrackingContainerAfterSettle / __markForRelayout, in-pass) AHEAD of the caret, and the caret stays
  # layoutIsValid==false so the loop re-runs it AFTER the panel settles, confirming convergence. This iterates via
  # the flush's until-loop, not a hand-rolled loop; it is deterministic (same settled geometry in => same passes)
  # and bounded (only a true NON-TERMINATING cycle would ever hit WorldWdgt._recalculateLayoutsBody's sanity-limit
  # assert). The caret is isLayoutInert + childless, so there is no base _reLayout work to do (no bounds to fit,
  # no children to place) -- this override is the whole layout step.
  _reLayout: ->
    beforeParentT = @parent?.top() ; beforeParentL = @parent?.left()
    beforeTargetT = @target?.top() ; beforeTargetL = @target?.left()
    @_oneScrollCaretIntoViewPassNoSettle()
    # converged when no CORRECTIVE CONTAINER move was needed this pass -- neither the scroll container (my parent =
    # the scroll panel's contents) nor the target text had to move to keep me in view. The caret's OWN reposition
    # to its slot is an exact, idempotent one-shot, so a pass that ONLY repositioned the caret is already at the
    # fixed point and needs no confirming re-visit.
    #   INVARIANT this leans on: placing the caret at slotCoordinates is idempotent (a direct absolute move), and my
    #   target/panel settle BEFORE me (the flush drains parent-first; the caret is freefloating + inert, drained
    #   last). Marking fixed here can only REDUCE settle iterations vs the old "did anything move" check -- it can
    #   never ADD a cycle. If a future text-relayout change ever broke that invariant (so my slot moved AFTER I
    #   marked fixed), TWO backstops catch it, NEITHER silent: (1) a wrong caret position fails the byte-exact
    #   SystemTest suite -- the caret is screenshotted in ~a dozen tests (macroWrappingTextFieldResizesOK,
    #   macroMultilineTextInputScrollsWell, the *CaretBroughtIntoView* pair, macroTextWdgtCaretResizing, ...); and
    #   (2) an actual non-terminating cycle throws RECALC_NONCONVERGENCE at WorldWdgt._recalculateLayoutsBody's
    #   sanity limit, naming this widget (and the determinism torture greps for that token). So a regression here
    #   surfaces loudly and is diagnosable -- it does not hang the tab or render 1px-off unnoticed.
    stable = @parent?.top() == beforeParentT and @parent?.left() == beforeParentL and @target?.top() == beforeTargetT and @target?.left() == beforeTargetL
    if stable
      @markLayoutAsFixed()
    # else: stay layoutIsValid==false -- still in the queue, re-processed after the just-enqueued panel settles

  # Converge the caret's pending scroll-follow IN-PLACE, during the event -- called at the tail of each caret
  # EDITING-event handler (processKeyDown / processCut / processPaste), once the target geometry is final. The
  # discrete moves (click/arrow/Home/End) already settle in-place: their public gotoSlot/goLeft/goRight wrap the
  # advance in _settleLayoutsAfter. The typing/delete/paste advance can't do that -- its inline scroll pass must
  # precede the keystroke's reactToKeystroke re-fit (§ byte-exact typing, see goLeft/goRight), so it enqueues the
  # caret OFF-settle (_requestScrollFollow) and the convergence is deferred to here, the keystroke's end. This
  # drains it now -- in-place, "step by step" per the doOneCycle invariant -- instead of letting it ride the
  # end-of-cycle coalesced flush (the caret is discrete, not a coalesced stream, so it belongs in the per-event
  # settle). Reuses the standard in-place settle (_settleLayoutsAfter) with an EMPTY core: the work (the enqueue +
  # the one inline pass) already happened in the advance; we only need to DRAIN the queue now and let the caret's
  # _reLayout iterate the follow to a fixed point. No-op when nothing is pending -- a nav keystroke (already
  # self-settled via gotoSlot), or a keystroke whose reactToKeystroke re-fit happened to self-settle and drain the
  # caret early; in both cases @layoutIsValid is back to true.
  _settleScrollFollow: ->
    # early-return-sanctioned: the guard is the "is a follow pending?" predicate, not a state-skip that belongs in
    #   a _<name>NoSettle core -- this settle has no core (it is a pure drain of an already-enqueued inert overlay).
    return if @layoutIsValid
    @_settleLayoutsAfter => nil

  # A SINGLE scroll-follow pass (see _reLayout, which iterates this to a fixed point via the flush). Re-derives
  # pos from the current (settled) geometry, applies the horizontal clamp (which scrolls @target and adjusts where
  # the caret lands), re-places the caret, then asks the scroll panel to scroll it vertically into view.
  # thin-wrap-exempt: one convergence pass driven by the caret's _reLayout (no public twin -- settling is provided
  # by the flush, not a self-settling wrapper).
  _oneScrollCaretIntoViewPassNoSettle: ->
    pos = @target.slotCoordinates @slot
    if pos?
      if @parent and @target.isScrollable
        right = @parent.right() - @viewPadding
        left = @parent.left() + @viewPadding
        if pos.x > right
          @target._moveLeftSideTo @target.left() + right - pos.x
          pos.x = right
        if pos.x < left
          left = Math.min @parent.left(), left
          @target._moveLeftSideTo @target.left() + left - pos.x
          pos.x = left
        if @target.right() < right and right - @target.width() < left
          pos.x += right - @target.right()
          @target._moveRightSideTo right
      @show()
      # Place the caret at its TRUE slot position, integer-floored but WITHOUT Point.floor()'s clamp-to->=0
      # (Math.max(_, 0)): when the content is scrolled up, a slot above the world origin has a NEGATIVE absolute y.
      # Clamping the caret to 0 there capped scrollCaretIntoView -- which scrolls by (ft - caretWidget.top()) -- at
      # ONE viewport-step (ft) per pass, so a far caret converged over MANY settle re-visits (contents crawled to
      # its mark in +ft steps). Placing the caret at its real (possibly negative, off-viewport, harmlessly clipped)
      # position lets scrollCaretIntoView compute the FULL scroll delta in ONE pass -- byte-identical fixed point,
      # but the follow now settles in a single move + verify instead of distance/ft passes. The final resting
      # position is always in view (positive), so the rendered caret is unchanged.
      @_applyMoveTo new Point (Math.floor pos.x), (Math.floor pos.y)

      if @_amIDirectlyInsideScrollPanelWdgt() and @target.isScrollable
        @parent.parent.scrollCaretIntoView @

  
  # Navigation keystrokes SELF-SETTLE (one flush per arrow press, during the event) -- caret navigation is not a
  # high-traffic stream, so it does not coalesce (see the comment on gotoSlot). goLeft / goRight are ALSO called
  # INTERNALLY (insert -> goRight to advance past the typed char; deleteLeft -> goLeft), where the caret advance
  # must NOT self-settle early -- doing so reorders the fit (it broke macroStringWdgtInlineTypingRefitsUnderFitting-
  # Modes: the advance scroll flushed before updateDimension/escalateEvent). The advance instead enqueues the
  # follow off-settle and lets the editing handler's tail settle it in-place once the reactToKeystroke re-fit is
  # done (processKeyDown -> _settleScrollFollow). So goLeft/goRight split into a self-settling public
  # wrapper (the keystroke path) + a non-settling _go*NoSettle core (the internal path). goUp/goDown/goHome/
  # goEnd have NO internal callers, so they self-settle inline via gotoSlot. updateSelection / clearSelectionIf...
  # only touch selection marks (no layout). (end-of-cycle-flush-drawdown CONVERT.)
  goLeft: (shift) ->
    @_settleLayoutsAfter => @_goLeftNoSettle shift
  _goLeftNoSettle: (shift) ->
    if !shift and @target.firstSelectedSlot()?
      @_gotoSlotNoSettle @target.firstSelectedSlot()
      @updateSelection shift
    else
      @updateSelection shift
      @_gotoSlotNoSettle @slot - 1
      @updateSelection shift
      @clearSelectionIfStartAndEndMeet shift
    @target.rememberCaretColumn @slot

  goRight: (shift, howMany) ->
    @_settleLayoutsAfter => @_goRightNoSettle shift, howMany
  _goRightNoSettle: (shift, howMany) ->
    if !shift and @target.lastSelectedSlot()?
      @_gotoSlotNoSettle @target.lastSelectedSlot()
      @updateSelection shift
    else
      @updateSelection shift
      @_gotoSlotNoSettle @slot + (howMany || 1)
      @updateSelection shift
      @clearSelectionIfStartAndEndMeet shift
    @target.rememberCaretColumn @slot

  goUp: (shift) ->
    if !shift and @target.lastSelectedSlot()?
      @gotoSlot @target.firstSelectedSlot()
      @updateSelection shift
    else
      @updateSelection shift
      @gotoSlot @target.upFrom @slot
      @updateSelection shift
      @clearSelectionIfStartAndEndMeet shift

  goDown: (shift) ->
    if !shift and @target.lastSelectedSlot()?
      @gotoSlot @target.lastSelectedSlot()
      @updateSelection shift
    else
      @updateSelection shift
      @gotoSlot @target.downFrom @slot
      @updateSelection shift
      @clearSelectionIfStartAndEndMeet shift

  goHome: (shift) ->
    @updateSelection shift
    @gotoSlot @target.startOfLine @slot
    @updateSelection shift
    @clearSelectionIfStartAndEndMeet shift

  goEnd: (shift) ->
    @updateSelection shift
    @gotoSlot @target.endOfLine @slot
    @updateSelection shift
    @clearSelectionIfStartAndEndMeet shift
  
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

  # User presses enter on a stringWidget
  accept: ->
    world.stopEditing()
    @escalateEvent "accept", nil
  
  # User presses ESC
  cancel: ->
    world.stopEditing()
    @escalateEvent 'cancel', nil

  # User presses CTRL-Z or CMD-Z, potentially with shift
  undo: (shiftKey) ->
    if !@target.undoHistory?
      return

    if !shiftKey
      if @target.undoHistory.length > 1
        @target.popUndoState()
        undoState = @target.undoHistory[@target.undoHistory.length - 1]
        @bringTextAndCaretToState undoState
    else
      redoState = @target.popRedoState()
      if redoState?
        @bringTextAndCaretToState redoState

  bringTextAndCaretToState: (state) ->
    @target.setText state.textContent, nil, nil
    @gotoSlot state.cursorPos   # discrete (undo/redo restore) -> public self-settling gotoSlot
    if state.selectionStart? and state.selectionEnd?
      @target.selectBetween state.selectionStart, state.selectionEnd
    else
      @target.clearSelection()
  
  insert: (key, shiftKey) ->
    # if the target "isNumeric", then only accept
    # numbers and "-" and "." as input
    if not @target.isNumeric or not isNaN(parseFloat(key)) or key in ["-", "."]
      
      # we push the state here before the change, then again
      # after the change. This seems redundant, however
      # it's needed because:
      #
      # 1) in case we are about to insert something that
      #    replaces a selection, then it's actually
      #    important to save the state before the selection
      #    is touched so that the user can go back to it
      # 2) in case of edit "far" from the previous edit,
      #    this is going to be very very useful because
      #    it's much *much* more natural
      #    for the user to undo up to the position BEFORE an
      #    edit. If you don't save that position before the
      #    edit, you jump directly to the end of the edit before,
      #    it's actually quite puzzling.
      #    It's nominally "functional" to only jump to text changes,
      #    but it's quite unnatural, it's not how undos work
      #    in real editors.
      # 
      # In the "normal" case of continuous typing this
      # would be indeed redundant, HOWEVER we avoid such
      # redundancy, because the sequences of:
      #
      #         position, text, position, text, ...
      #
      # actually are saved without the "position"
      # changes (there is a check in "pushUndoState" that if there
      # is only a change position of one then that state is not
      # pushed)

      @target.pushUndoState? @slot

      if @target.selection() isnt ""
        @_gotoSlotNoSettle @target.firstSelectedSlot()
        @target.deleteSelection()
      text = @target.text
      text = text.slice(0, @slot) + key + text.slice(@slot)
      # this is a setText that will trigger the text
      # connections "from within", starting a new connections
      # update round
      @target.setText text, nil, nil
      # The text just GREW: if it no longer fits a CROP-overflow field, hand off to the pop-out editor NOW, at
      # event time (off the flush). This is the explicit home of what used to fire lazily + impurely inside
      # slotCoordinates -- insert (typing + paste) is the only path that can grow inline-edited text past the
      # fit. If it hands off, the inline caret is gone, so stop here (no advance / dimension / undo to do).
      return if @target.handOffToPopoutEditorIfOverflowing()
      @_goRightNoSettle false, key.length   # internal advance: rides setText's flush, must NOT self-settle early
      @updateDimension()
      @target.pushUndoState? @slot
  
  ctrl: (key, shiftKey) ->
    switch key
      when "a", "A"
        @target.selectAll()
      when "z", "Z"
        @undo shiftKey

  cmd: (key, shiftKey) ->
    switch key
      when "a", "A"
        @target.selectAll()
      when "z", "Z"
        @undo shiftKey
  
  deleteRight: ->
    if @target.selection() isnt ""
      @_gotoSlotNoSettle @target.firstSelectedSlot()
      @target.deleteSelection()
    else
      text = @target.text
      text = text.slice(0, @slot) + text.slice(@slot + 1)
      @target.setText text, nil, nil
  
  deleteLeft: ->
    if @target.selection()
      @_gotoSlotNoSettle @target.firstSelectedSlot()
      @target.deleteSelection()
    else
      text = @target.text
      @target.setText text.substring(0, @slot - 1) + text.substr(@slot), nil, nil
      @_goLeftNoSettle()   # internal: rides setText's flush, must NOT self-settle early (see goLeft/goRight)

    @updateSelection false
    @_gotoSlotNoSettle @slot
    @updateSelection false
    @clearSelectionIfStartAndEndMeet false
