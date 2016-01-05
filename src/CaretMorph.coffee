# CaretMorph /////////////////////////////////////////////////////////

# I mark where the caret is in a String/Text while editing

class CaretMorph extends BlinkerMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  keyDownEventUsed: false
  target: null
  originalContents: null
  slot: null
  viewPadding: 1

  constructor: (@target) ->
    # additional properties:
    @originalContents = @target.text
    @originalAlignment = @target.alignment
    @slot = @target.text.length
    super()

    # font could be really small I guess?
    @minimumExtent = new Point 1,1

    if (@target instanceof TextMorph) and (@target.alignment != 'left')
      @target.setAlignmentToLeft()
    @gotoSlot @slot
    @updateCaretDimension()

  updateCaretDimension: ->
    ls = fontHeight @target.actualFontSizeUsedInRendering()
    @rawSetExtent new Point Math.max(Math.floor(ls / 20), 1), ls
  
  # CaretMorph event processing:
  processKeyPress: (charCode, symbol, shiftKey, ctrlKey, altKey, metaKey) ->
    # @inspectKeyEvent event
    if @keyDownEventUsed
      @keyDownEventUsed = false
      @updateCaretDimension()
      return null
    if ctrlKey
      @ctrl charCode
    # in Chrome/OSX cmd-a and cmd-z
    # don't trigger a keypress so this
    # function invocation here does
    # nothing.
    else if metaKey
      @cmd charCode
    else
      @insert symbol, shiftKey
    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", charCode, symbol, shiftKey, ctrlKey, altKey, metaKey
    @updateCaretDimension()
  
  processKeyDown: (scanCode, shiftKey, ctrlKey, altKey, metaKey) ->
    # @inspectKeyEvent event
    @keyDownEventUsed = false
    if ctrlKey
      @ctrl scanCode
      # notify target's parent of key event
      @target.escalateEvent "reactToKeystroke", scanCode, null, shiftKey, ctrlKey, altKey, metaKey
      @updateCaretDimension()
      return
    else if metaKey
      @cmd scanCode
      # notify target's parent of key event
      @target.escalateEvent "reactToKeystroke", scanCode, null, shiftKey, ctrlKey, altKey, metaKey
      @updateCaretDimension()
      return
    switch scanCode
      when 37
        @goLeft shiftKey
        @keyDownEventUsed = true
      when 39
        @goRight shiftKey
        @keyDownEventUsed = true
      when 38
        @goUp shiftKey
        @keyDownEventUsed = true
      when 40
        @goDown shiftKey
        @keyDownEventUsed = true
      when 36
        @goHome shiftKey
        @keyDownEventUsed = true
      when 35
        @goEnd shiftKey
        @keyDownEventUsed = true
      when 46
        @deleteRight()
        @keyDownEventUsed = true
      when 8
        @deleteLeft()
        @keyDownEventUsed = true
      when 13
        # we can't check the class using instanceof
        # because TextMorphs are instances of StringMorphs
        # but they want the enter to insert a carriage return.
        if @target.constructor.name == "StringMorph" or @target.constructor.name == "StringMorph2"
          @accept()
        else
          @insert "\n"
        @keyDownEventUsed = true
      when 27
        @cancel()
        @keyDownEventUsed = true
      else
    # @inspectKeyEvent event
    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", scanCode, null, shiftKey, ctrlKey, altKey, metaKey
    @updateCaretDimension()
  
  
  # CaretMorph navigation - simple version
  #gotoSlot: (newSlot) ->
  #  @fullRawMoveTo @target.slotCoordinates(newSlot)
  #  @slot = Math.max newSlot, 0

  gotoSlot: (slot) ->
    # check that slot is within the allowed boundaries of
    # of zero and text length.
    length = @target.text.length
    @slot = (if slot < 0 then 0 else (if slot > length then length else slot))

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
      #console.log "moving caret to: " + pos
      @show()
      @fullRawMoveTo pos.floor()

      if @parent and @parent.parent instanceof ScrollFrameMorph and @target.isScrollable
        @parent.parent.scrollCaretIntoView @
  
  goLeft: (shift) ->
    @target.caretHorizPositionForVertMovement = @left()
    if !shift and @target.selectionStartSlot()?
      @gotoSlot @target.selectionStartSlot()
      @updateSelection shift
    else
      @updateSelection shift
      @gotoSlot @slot - 1
      @updateSelection shift
      @clearSelectionIfStartAndEndMeet shift
  
  goRight: (shift, howMany) ->
    @target.caretHorizPositionForVertMovement = @left()
    if !shift and @target.selectionEndSlot()?
      @gotoSlot @target.selectionEndSlot()
      @updateSelection shift
    else
      @updateSelection shift
      @gotoSlot @slot + (howMany || 1)
      @updateSelection shift
      @clearSelectionIfStartAndEndMeet shift
  
  goUp: (shift) ->
    if !shift and @target.selectionEndSlot()?
      @gotoSlot @target.selectionStartSlot()
      @updateSelection shift
    else
      @updateSelection shift
      @gotoSlot @target.upFrom @slot
      @updateSelection shift
      @clearSelectionIfStartAndEndMeet shift
  
  goDown: (shift) ->
    if !shift and @target.selectionEndSlot()?
      @gotoSlot @target.selectionEndSlot()
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
    @gotoSlot slotToGoTo
    @show()
    return slotToGoTo

  clearSelectionIfStartAndEndMeet: (shift) ->
    if shift
      #console.log "@target.startMark: " + @target.startMark + " @target.endMark: " + @target.endMark
      if @target.startMark == @target.endMark
        #console.log "clearSelectionIfStartAndEndMeet clearing selection"
        @target.clearSelection()
        @target.changed()

  updateSelection: (shift) ->
    if shift
      if (@target.endMark is null) and (@target.startMark is null)
        @target.startMark = @slot
        @target.endMark = @slot
      else if @target.endMark isnt @slot
        @target.endMark = @slot
        @target.reLayout()

        @target.changed()
    else
      @target.clearSelection()
  
  # CaretMorph editing.

  # User presses enter on a stringMorph
  accept: ->
    world.stopEditing()
    @escalateEvent "accept", null
  
  # User presses ESC
  cancel: ->
    @undo()
    world.stopEditing()
    @escalateEvent 'cancel', null
    
  # User presses CTRL-Z or CMD-Z
  # Note that this is not a real undo,
  # what we are doing here is just reverting
  # all the changes and sort-of-resetting the
  # state of the target.
  undo: ->
    @target.setContent @originalContents
    @target.clearSelection()
    
    # in theory these three lines are not
    # needed because clearSelection runs them
    # already, but I'm leaving them here
    # until I understand better this changed
    # vs. updateBackBuffer semantics.
    @target.reLayout()    
    @target.changed()

    @gotoSlot 0
  
  insert: (symbol, shiftKey) ->
    if symbol is "\t"
      @target.escalateEvent 'reactToEdit', @target
      if shiftKey
        return @target.backTab @target
      return @target.tab @target
    if not @target.isNumeric or not isNaN(parseFloat(symbol)) or contains(["-", "."], symbol)
      if @target.selection() isnt ""
        @gotoSlot @target.selectionStartSlot()
        @target.deleteSelection()
      text = @target.text
      text = text.slice(0, @slot) + symbol + text.slice(@slot)
      @target.setContent text
      @goRight false, symbol.length
      @updateCaretDimension()
  
  ctrl: (scanCodeOrCharCode) ->
    # ctrl-a apparently can come from either
    # keypress or keydown
    # 64 is for keydown
    # 97 is for keypress
    # in Chrome on OSX there is no keypress
    if (scanCodeOrCharCode is 97) or (scanCodeOrCharCode is 65)
      @target.selectAll()
    # ctrl-z arrives both via keypress and
    # keydown but 90 here matches the keydown only
    else if scanCodeOrCharCode is 90
      @undo()
    # unclear which keyboard needs ctrl
    # to be pressed to give a keypressed
    # event for {}[]@
    # but this is what this catches
    else if scanCodeOrCharCode is 123
      @insert "{"
    else if scanCodeOrCharCode is 125
      @insert "}"
    else if scanCodeOrCharCode is 91
      @insert "["
    else if scanCodeOrCharCode is 93
      @insert "]"
    else if scanCodeOrCharCode is 64
      @insert "@"
  
  # these two arrive only from
  # keypressed, at least in Chrome/OSX
  # 65 and 90 are both scan codes.
  cmd: (scanCode) ->
    # CMD-A
    if scanCode is 65
      @target.selectAll()
    # CMD-Z
    else if scanCode is 90
      @undo()
  
  deleteRight: ->
    if @target.selection() isnt ""
      @gotoSlot @target.selectionStartSlot()
      @target.deleteSelection()
    else
      text = @target.text
      @target.changed()
      text = text.slice(0, @slot) + text.slice(@slot + 1)
      @target.setContent text    
  
  deleteLeft: ->
    if @target.selection()
      @gotoSlot @target.selectionStartSlot()
      @target.deleteSelection()
    else
      text = @target.text
      @target.changed()
      @target.setContent text.substring(0, @slot - 1) + text.substr(@slot)
      @goLeft()
    @target.reflowText()

    @updateSelection false
    @gotoSlot @slot
    @updateSelection false
    @clearSelectionIfStartAndEndMeet false

    @changed()

  # CaretMorph destroying:
  destroy: ->
    WorldMorph.numberOfAddsAndRemoves++
    if @target.alignment isnt @originalAlignment
      @target.alignment = @originalAlignment
      @target.reLayout()
      
      @target.changed()
    super  
  
  # CaretMorph utilities:
  inspectKeyEvent: (event) ->
    # private
    @inform "Key pressed: " + String.fromCharCode(event.charCode) + "\n------------------------" + "\ncharCode: " + event.charCode + "\nkeyCode: " + event.keyCode + "\naltKey: " + event.altKey + "\nctrlKey: " + event.ctrlKey  + "\ncmdKey: " + event.metaKey
