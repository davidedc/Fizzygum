# I mark where the caret is in a String/Text while editing

class CaretWdgt extends BlinkerWdgt

  target: nil
  slot: nil
  viewPadding: 1
  currentCaretFontSize: nil
  # set by a caret MOVE (_gotoSlotNoSettle); consumed once per cycle by WorldWdgt.doOneCycle AFTER the
  # end-of-cycle flush and BEFORE paint, to scroll the caret into view on settled geometry (see
  # _scrollCaretIntoViewNoSettle). A plain wheel/scroll never sets it, so the panel follows the caret
  # only when the caret MOVES.
  _pendingScrollIntoView: nil

  constructor: (@target) ->
    # additional properties:
    @slot = @target.text.length
    super()

    # if the only thing in the undo history is the
    # first positioning of the caret via click, we can clear
    # that because we are going to set out own with
    # the first click
    if @target.undoHistory?.length == 1
      onlyUndo = @target.undoHistory[@target.undoHistory.length - 1]
      if onlyUndo.isJustFirstClickToPositionCursor
        @target.undoHistory = []

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
  # layout (moves @target / @contents) and must happen out of paint -- see _scrollCaretIntoViewNoSettle and
  # WorldWdgt.doOneCycle. (Also called from the constructor.)
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
      @rawSetExtent new Point Math.max(Math.floor(ls / 20), 1), ls
  
  # CaretWdgt event processing:

  processKeyDown: (key, code, shiftKey, ctrlKey, altKey, metaKey) ->
    # @inspectKeyEvent event

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

    # @inspectKeyEvent event
    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", key, code, shiftKey, ctrlKey, altKey, metaKey
    @updateDimension()
  
  processCut: (selectedText) ->
    #console.log "processing cut"
    @deleteLeft()


  # unused
  processCopy: (selectedText) ->
    #console.log "processing copy"

  processPaste: (clipboardText) ->
    #console.log "about to insert text: " + clipboardText
    @insert clipboardText

  
  # gotoSlot is the public "move the caret to slot N" API: it SELF-SETTLES -- the inert re-place flushes once,
  # DURING the event that moved the caret (the doOneCycle model: process events fixing layouts step by step,
  # then flush coalesced, then paint). Reached cross-widget (world.caret.gotoSlot from StringWdgt/TextWdgt click
  # handlers), by the caret's own click / undo-redo restore, AND by the arrow / Home / End navigation keystrokes
  # (goLeft/goRight/...). Per-keystroke caret navigation is NOT a high-traffic stream, so it does NOT coalesce
  # (contrast setMaxDimCoalesced, for ~50-per-frame drag/scroll STREAMS) -- each keystroke self-settles, one flush
  # per discrete move.
  #   _gotoSlotNoSettle does ONLY the layout-free work: clamp the slot, re-place the caret on the target's current
  #   slot coordinate (inert), and REQUEST a scroll-follow (@_pendingScrollIntoView). The actual scroll-follow --
  #   the only layout-MUTATING part -- is deferred to WorldWdgt.doOneCycle, which runs it once AFTER the cycle's
  #   flush (so @target is settled -- doing it inline computed against UN-settled geometry, which is why the old
  #   code leaned on a paint-time re-sync to finish the job) and BEFORE paint (so paint stays read-only). The core
  #   is the non-settling member reached where settling is wrong or already provided: (1) insert/delete, where a
  #   subsequent self-settling @target.setText/deleteSelection flushes the move within the same event; and (2)
  #   construction (the caret is an orphan, so it defers and settles when first added).
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
    # ... and REQUEST a post-flush convergence pass for the cases that need MORE than one (a scroll panel's
    # vertical follow advances only partway per pass): doOneCycle runs _scrollCaretIntoViewNoSettle once after
    # the flush, on settled geometry, before paint. The wheel/scroll path does NOT come through here, so it
    # never requests a follow -- the panel chases the caret only when the caret MOVES.
    @_pendingScrollIntoView = true

    if becauseOfMouseClick and @target.undoHistory?.length == 0
      @target.pushUndoState? @slot, true

  # The INERT re-place (no layout): put the caret at the target's current slot coordinate. Shared by the
  # paint/ctor re-sync (adjustAccordingToTargetText) and every caret move (_gotoSlotNoSettle).
  _repositionToSlotNoSettle: ->
    pos = @target.slotCoordinates @slot
    if pos?
      @show()
      @fullRawMoveTo pos.floor()

  # The SCROLL-FOLLOW: bring the caret into view by scrolling @target horizontally and/or the enclosing scroll
  # panel vertically (ScrollPanelWdgt.scrollCaretIntoView). This MUTATES layout, so it must run OUT of paint:
  # WorldWdgt.doOneCycle calls it once AFTER the end-of-cycle flush (so @target's geometry is final) and BEFORE
  # paint (so updateBroken stays read-only), and only when a move set @_pendingScrollIntoView.
  #   It iterates to a FIXED POINT: ScrollPanelWdgt.scrollCaretIntoView reaches its mark over a FEW passes (its
  # trailing keepContentsInScrollPanelWdgt clamp advances @contents only PARTWAY toward the target each call), and
  # the old design leaned on the per-PAINT re-sync to supply those repeated passes across successive frames. Doing
  # it in ONE place means doing it to convergence HERE -- which is deterministic (same settled geometry in => same
  # number of passes), unlike a frame-count-dependent multi-frame convergence. A safety cap guards the unlikely
  # non-convergent case (the loop is bounded either way, so determinism holds).
  # thin-wrap-exempt: standalone non-settling step run at a controlled point in doOneCycle (no public twin --
  # settling is provided by the cycle, not a self-settling wrapper).
  _scrollCaretIntoViewNoSettle: ->
    cap = 12
    loop
      beforeT = @top() ; beforeL = @left()
      beforeParentT = @parent?.top() ; beforeParentL = @parent?.left()
      @_oneScrollCaretIntoViewPassNoSettle()
      cap -= 1
      # converged once neither the caret nor its (scrolled) container moved on the last pass
      stable = @top() == beforeT and @left() == beforeL and @parent?.top() == beforeParentT and @parent?.left() == beforeParentL
      break if stable or cap <= 0

  # A SINGLE scroll-follow pass (see _scrollCaretIntoViewNoSettle, which iterates this to a fixed point). Re-derives
  # pos from the current (settled) geometry, applies the horizontal clamp (which scrolls @target and adjusts where
  # the caret lands), re-places the caret, then asks the scroll panel to scroll it vertically into view.
  # thin-wrap-exempt: one convergence pass of _scrollCaretIntoViewNoSettle (no public twin -- see above).
  _oneScrollCaretIntoViewPassNoSettle: ->
    pos = @target.slotCoordinates @slot
    if pos?
      if @parent and @target.isScrollable
        right = @parent.right() - @viewPadding
        left = @parent.left() + @viewPadding
        if pos.x > right
          @target.fullRawMoveLeftSideTo @target.left() + right - pos.x
          pos.x = right
        if pos.x < left
          left = Math.min @parent.left(), left
          @target.fullRawMoveLeftSideTo @target.left() + left - pos.x
          pos.x = left
        if @target.right() < right and right - @target.width() < left
          pos.x += right - @target.right()
          @target.fullRawMoveRightSideTo right
      @show()
      @fullRawMoveTo pos.floor()

      if @_amIDirectlyInsideScrollPanelWdgt() and @target.isScrollable
        @parent.parent.scrollCaretIntoView @

  
  # Navigation keystrokes SELF-SETTLE (one flush per arrow press, during the event) -- caret navigation is not a
  # high-traffic stream, so it does not coalesce (see the comment on gotoSlot). goLeft / goRight are ALSO called
  # INTERNALLY (insert -> goRight to advance past the typed char; deleteLeft -> goLeft), where the surrounding
  # setText / deleteSelection already self-settled and the caret advance must ride the SAME deferred flush as the
  # original -- self-settling it early reorders the fit (it broke macroStringWdgtInlineTypingRefitsUnderFittingModes:
  # the advance scroll flushed before updateDimension/escalateEvent). So goLeft/goRight split into a self-settling
  # public wrapper (the keystroke path) + a non-settling _go*NoSettle core (the internal path). goUp/goDown/goHome/
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
    @target.caretHorizPositionForVertMovement = @slot

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
    @target.caretHorizPositionForVertMovement = @slot

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
      #console.log "@target.startMark: " + @target.startMark + " @target.endMark: " + @target.endMark
      if @target.startMark == @target.endMark
        #console.log "clearSelectionIfStartAndEndMeet clearing selection"
        @target.clearSelection()

  updateSelection: (shift) ->
    if shift
      if (!@target.endMark?) and (!@target.startMark?)
        @target.selectBetween @slot, @slot
      else if @target.endMark isnt @slot
        @target.setEndMark @slot
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
  
  # »>> this part is excluded from the fizzygum homepage build
  # CaretWdgt utilities:
  inspectKeyEvent: (event) ->
    # private
    @inform "Key pressed: " + event.key + "\n------------------------" + "\nkey: " + event.key + "\ncode: " + event.code + "\naltKey: " + event.altKey + "\nctrlKey: " + event.ctrlKey  + "\ncmdKey: " + event.metaKey
  # this part is excluded from the fizzygum homepage build <<«
