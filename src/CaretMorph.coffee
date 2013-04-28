# CaretMorph /////////////////////////////////////////////////////////

# I am a String/Text editing widget

class CaretMorph extends BlinkerMorph

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
    ls = fontHeight(@target.fontSize)
    @setExtent new Point(Math.max(Math.floor(ls / 20), 1), ls)
    @updateRendering()
    @image.getContext("2d").font = @target.font()
    if (@target instanceof TextMorph && (@target.alignment != 'left'))
      @target.setAlignmentToLeft()
    @gotoSlot @slot
  
  # CaretMorph event processing:
  processKeyPress: (event) ->
    # @inspectKeyEvent event
    if @keyDownEventUsed
      @keyDownEventUsed = false
      return null
    if (event.keyCode is 40) or event.charCode is 40
      @insert "("
      return null
    if (event.keyCode is 37) or event.charCode is 37
      @insert "%"
      return null
    if event.keyCode # Opera doesn't support charCode
      if event.ctrlKey
        @ctrl event.keyCode
      else if event.metaKey
        @cmd event.keyCode
      else
        @insert String.fromCharCode(event.keyCode), event.shiftKey
    else if event.charCode # all other browsers
      if event.ctrlKey
        @ctrl event.charCode
      else if event.metaKey
        @cmd event.keyCode
      else
        @insert String.fromCharCode(event.charCode), event.shiftKey
    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", event
  
  processKeyDown: (event) ->
    # this.inspectKeyEvent(event);
    shift = event.shiftKey
    @keyDownEventUsed = false
    if event.ctrlKey
      @ctrl event.keyCode
      # notify target's parent of key event
      @target.escalateEvent "reactToKeystroke", event
      return
    else if event.metaKey
      @cmd event.keyCode
      # notify target's parent of key event
      @target.escalateEvent "reactToKeystroke", event
      return
    switch event.keyCode
      when 37
        @goLeft(shift)
        @keyDownEventUsed = true
      when 39
        @goRight(shift)
        @keyDownEventUsed = true
      when 38
        @goUp(shift)
        @keyDownEventUsed = true
      when 40
        @goDown(shift)
        @keyDownEventUsed = true
      when 36
        @goHome(shift)
        @keyDownEventUsed = true
      when 35
        @goEnd(shift)
        @keyDownEventUsed = true
      when 46
        @deleteRight()
        @keyDownEventUsed = true
      when 8
        @deleteLeft()
        @keyDownEventUsed = true
      when 13
        # we can't check the class using instanceOf
        # because TextMorphs are instances of StringMorphs
        # but they want the enter to insert a carriage return.
        if @target.constructor.name == "StringMorph"
          @accept()
        else
          @insert "\n"
        @keyDownEventUsed = true
      when 27
        @cancel()
        @keyDownEventUsed = true
      else
    # this.inspectKeyEvent(event);
    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", event
  
  
  # CaretMorph navigation - simple version
  #gotoSlot: (newSlot) ->
  #  @setPosition @target.slotCoordinates(newSlot)
  #  @slot = Math.max(newSlot, 0)

  gotoSlot: (slot) ->
    length = @target.text.length
    pos = @target.slotCoordinates(slot)
    @slot = (if slot < 0 then 0 else (if slot > length then length else slot))
    if @parent and @target.isScrollable
      right = @parent.right() - @viewPadding
      left = @parent.left() + @viewPadding
      if pos.x > right
        @target.setLeft @target.left() + right - pos.x
        pos.x = right
      if pos.x < left
        left = Math.min(@parent.left(), left)
        @target.setLeft @target.left() + left - pos.x
        pos.x = left
      if @target.right() < right and right - @target.width() < left
        pos.x += right - @target.right()
        @target.setRight right
    @show()
    @setPosition pos

    if @parent and @parent.parent instanceof ScrollFrameMorph and @target.isScrollable
      @parent.parent.scrollCaretIntoView @
  
  goLeft: (shift) ->
    @updateSelection shift
    @gotoSlot @slot - 1
    @updateSelection shift
  
  goRight: (shift, howMany) ->
    @updateSelection shift
    @gotoSlot @slot + (howMany || 1)
    @updateSelection shift
  
  goUp: (shift) ->
    @updateSelection shift
    @gotoSlot @target.upFrom(@slot)
    @updateSelection shift
  
  goDown: (shift) ->
    @updateSelection shift
    @gotoSlot @target.downFrom(@slot)
    @updateSelection shift
  
  goHome: (shift) ->
    @updateSelection shift
    @gotoSlot @target.startOfLine(@slot)
    @updateSelection shift
  
  goEnd: (shift) ->
    @updateSelection shift
    @gotoSlot @target.endOfLine(@slot)
    @updateSelection shift
  
  gotoPos: (aPoint) ->
    @gotoSlot @target.slotAt(aPoint)
    @show()

  updateSelection: (shift) ->
    if shift
      if not @target.endMark and not @target.startMark
        @target.startMark = @slot
        @target.endMark = @slot
      else if @target.endMark isnt @slot
        @target.endMark = @slot
        @target.updateRendering()
        @target.changed()
    else
      @target.clearSelection()  
  
  # CaretMorph editing:
  accept: ->
    world = @root()
    world.stopEditing()  if world
    @escalateEvent "accept", null
  
  cancel: ->
    world = @root()
    @undo()
    world.stopEditing()  if world
    @escalateEvent 'cancel', null
    
  # Note that this is not a real undo,
  # what we are doing here is just reverting
  # all the changes and sort-of-resetting the
  # state of the target.
  undo: ->
    @target.text = @originalContents
    @target.clearSelection()
    
    # in theory these three lines are not
    # needed because clearSelection runs them
    # already, but I'm leaving them here
    # until I understand better this changed
    # vs. updateRendering semantics.
    @target.changed()
    @target.updateRendering()
    @target.changed()

    @gotoSlot 0
  
  insert: (aChar, shiftKey) ->
    if aChar is "\t"
      @target.escalateEvent 'reactToEdit', @target
      if shiftKey
        return @target.backTab(@target);
      return @target.tab(@target)
    if not @target.isNumeric or not isNaN(parseFloat(aChar)) or contains(["-", "."], aChar)
      if @target.selection() isnt ""
        @gotoSlot @target.selectionStartSlot()
        @target.deleteSelection()
      text = @target.text
      text = text.slice(0, @slot) + aChar + text.slice(@slot)
      @target.text = text
      @target.updateRendering()
      @target.changed()
      @goRight false, aChar.length
  
  ctrl: (aChar) ->
    if (aChar is 97) or (aChar is 65)
      @target.selectAll()
    else if aChar is 90
      @undo()
    else if aChar is 123
      @insert "{"
    else if aChar is 125
      @insert "}"
    else if aChar is 91
      @insert "["
    else if aChar is 93
      @insert "]"
    else if aChar is 64
      @insert "@"
  
  cmd: (aChar) ->
    if aChar is 65
      @target.selectAll()
    else if aChar is 90
      @undo()
  
  deleteRight: ->
    if @target.selection() isnt ""
      @gotoSlot @target.selectionStartSlot()
      @target.deleteSelection()
    else
      text = @target.text
      @target.changed()
      text = text.slice(0, @slot) + text.slice(@slot + 1)
      @target.text = text
      @target.updateRendering()
  
  deleteLeft: ->
    if @target.selection()
      @gotoSlot @target.selectionStartSlot()
      return @target.deleteSelection()
    text = @target.text
    @target.changed()
    @target.text = text.substring(0, @slot - 1) + text.substr(@slot)
    @target.updateRendering()
    @goLeft()

  # CaretMorph destroying:
  destroy: ->
    if @target.alignment isnt @originalAlignment
      @target.alignment = @originalAlignment
      @target.updateRendering()
      @target.changed()
    super  
  
  # CaretMorph utilities:
  inspectKeyEvent: (event) ->
    # private
    @inform "Key pressed: " + String.fromCharCode(event.charCode) + "\n------------------------" + "\ncharCode: " + event.charCode.toString() + "\nkeyCode: " + event.keyCode.toString() + "\naltKey: " + event.altKey.toString() + "\nctrlKey: " + event.ctrlKey.toString()  + "\ncmdKey: " + event.metaKey.toString()
