# CursorMorph /////////////////////////////////////////////////////////

# I am a String/Text editing widget

class CursorMorph
  constructor: (aStringOrTextMorph) ->
    @init aStringOrTextMorph

# CursorMorph: referenced constructors

# CursorMorph inherits from BlinkerMorph:
CursorMorph:: = new BlinkerMorph()
CursorMorph::constructor = CursorMorph
CursorMorph.uber = BlinkerMorph::

# CursorMorph instance creation:
CursorMorph::init = (aStringOrTextMorph) ->
  ls = undefined
  
  # additional properties:
  @keyDownEventUsed = false
  @target = aStringOrTextMorph
  @originalContents = @target.text
  @slot = @target.text.length
  CursorMorph.uber.init.call this
  ls = fontHeight(@target.fontSize)
  @setExtent new Point(Math.max(Math.floor(ls / 20), 1), ls)
  @drawNew()
  @image.getContext("2d").font = @target.font()
  @gotoSlot @slot


# CursorMorph event processing:
CursorMorph::processKeyPress = (event) ->
  
  # this.inspectKeyEvent(event);
  if @keyDownEventUsed
    @keyDownEventUsed = false
    return null
  if (event.keyCode is 40) or event.charCode is 40
    @insert "("
    return null
  if (event.keyCode is 37) or event.charCode is 37
    @insert "%"
    return null
  navigation = [8, 13, 18, 27, 35, 36, 37, 38, 40]
  if event.keyCode # Opera doesn't support charCode
    unless contains(navigation, event.keyCode)
      if event.ctrlKey
        @ctrl event.keyCode
      else
        @insert String.fromCharCode(event.keyCode)
  else if event.charCode # all other browsers
    unless contains(navigation, event.charCode)
      if event.ctrlKey
        @ctrl event.charCode
      else
        @insert String.fromCharCode(event.charCode)
  
  # notify target's parent of key event
  @target.escalateEvent "reactToKeystroke", event

CursorMorph::processKeyDown = (event) ->
  
  # this.inspectKeyEvent(event);
  @keyDownEventUsed = false
  if event.ctrlKey
    @ctrl event.keyCode
    
    # notify target's parent of key event
    @target.escalateEvent "reactToKeystroke", event
    return
  switch event.keyCode
    when 37
      @goLeft()
      @keyDownEventUsed = true
    when 39
      @goRight()
      @keyDownEventUsed = true
    when 38
      @goUp()
      @keyDownEventUsed = true
    when 40
      @goDown()
      @keyDownEventUsed = true
    when 36
      @goHome()
      @keyDownEventUsed = true
    when 35
      @goEnd()
      @keyDownEventUsed = true
    when 46
      @deleteRight()
      @keyDownEventUsed = true
    when 8
      @deleteLeft()
      @keyDownEventUsed = true
    when 13
      if @target instanceof StringMorph
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


# CursorMorph navigation:
CursorMorph::gotoSlot = (newSlot) ->
  @setPosition @target.slotPosition(newSlot)
  @slot = Math.max(newSlot, 0)

CursorMorph::goLeft = ->
  @target.clearSelection()
  @gotoSlot @slot - 1

CursorMorph::goRight = ->
  @target.clearSelection()
  @gotoSlot @slot + 1

CursorMorph::goUp = ->
  @target.clearSelection()
  @gotoSlot @target.upFrom(@slot)

CursorMorph::goDown = ->
  @target.clearSelection()
  @gotoSlot @target.downFrom(@slot)

CursorMorph::goHome = ->
  @target.clearSelection()
  @gotoSlot @target.startOfLine(@slot)

CursorMorph::goEnd = ->
  @target.clearSelection()
  @gotoSlot @target.endOfLine(@slot)

CursorMorph::gotoPos = (aPoint) ->
  @gotoSlot @target.slotAt(aPoint)
  @show()


# CursorMorph editing:
CursorMorph::accept = ->
  world = @root()
  world.stopEditing()  if world
  @escalateEvent "accept", null

CursorMorph::cancel = ->
  world = @root()
  world.stopEditing()  if world
  @target.text = @originalContents
  @target.changed()
  @target.drawNew()
  @target.changed()
  @escalateEvent "cancel", null

CursorMorph::insert = (aChar) ->
  text = undefined
  return @target.tab(@target)  if aChar is "\t"
  if not @target.isNumeric or not isNaN(parseFloat(aChar)) or contains(["-", "."], aChar)
    if @target.selection() isnt ""
      @gotoSlot @target.selectionStartSlot()
      @target.deleteSelection()
    text = @target.text
    text = text.slice(0, @slot) + aChar + text.slice(@slot)
    @target.text = text
    @target.drawNew()
    @target.changed()
    @goRight()

CursorMorph::ctrl = (aChar) ->
  if (aChar is 97) or (aChar is 65)
    @target.selectAll()
    return null
  if aChar is 123
    @insert "{"
    return null
  if aChar is 125
    @insert "}"
    return null
  if aChar is 91
    @insert "["
    return null
  if aChar is 93
    @insert "]"
    null

CursorMorph::deleteRight = ->
  text = undefined
  if @target.selection() isnt ""
    @gotoSlot @target.selectionStartSlot()
    @target.deleteSelection()
  else
    text = @target.text
    @target.changed()
    text = text.slice(0, @slot) + text.slice(@slot + 1)
    @target.text = text
    @target.drawNew()

CursorMorph::deleteLeft = ->
  text = undefined
  if @target.selection() isnt ""
    @gotoSlot @target.selectionStartSlot()
    @target.deleteSelection()
  text = @target.text
  @target.changed()
  text = text.slice(0, Math.max(@slot - 1, 0)) + text.slice(@slot)
  @target.text = text
  @target.drawNew()
  @goLeft()


# CursorMorph utilities:
CursorMorph::inspectKeyEvent = (event) ->
  
  # private
  @inform "Key pressed: " + String.fromCharCode(event.charCode) + "\n------------------------" + "\ncharCode: " + event.charCode.toString() + "\nkeyCode: " + event.keyCode.toString() + "\naltKey: " + event.altKey.toString() + "\nctrlKey: " + event.ctrlKey.toString()
