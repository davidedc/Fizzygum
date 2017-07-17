# UnderTheCarpetMorph //////////////////////////////////////////////////////

class UnderTheCarpetMorph extends BoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  # panes:
  scrollFrame: null
  buttonClose: null
  resizer: null

  constructor: (target) ->
    super()

    @silentRawSetExtent new Point 340, 270
    @color = new Color 60, 60, 60
    @padding = 5
    @buildAndConnectChildren()
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
    @buildAndConnectChildren()
  
  buildAndConnectChildren: ->
    @attribs = []

    # remove existing panes
    @fullDestroyChildrenButNotTheShadow()

    # label
    @label = new TextMorph "Under the carpet"
    @label.fontSize = WorldMorph.preferencesAndSettings.menuFontSize
    @label.isBold = true
    @label.color = new Color 255, 255, 255
    @add @label

    # Check which objects end with the word Morph
    theWordMorph = "Morph"

    @scrollFrame = new ScrollFrameMorph()

    @add @scrollFrame

    # close button
    @buttonClose = new TriggerMorph true, @
    @buttonClose.setLabel "close"
    @buttonClose.action = "removeFromTree"

    @add @buttonClose

    # resizer
    @resizer = new HandleMorph @

    # update layout
    @layoutSubmorphs()
  
  layoutSubmorphs: ->
    super()
    trackChanges.push false

    # label
    x = @left() + @cornerRadius
    y = @top() + @cornerRadius
    r = @right() - @cornerRadius
    w = r - x
    @label.fullRawMoveTo new Point x, y
    @label.rawSetWidth w
    if @label.height() > (@height() - 50)
      @rawSetHeight @label.height() + 50
      @changed()

    # scrollFrame
    y = @label.bottom() + 2
    w = @width() - @cornerRadius
    w -= @cornerRadius
    b = @bottom() - (2 * @cornerRadius) - WorldMorph.preferencesAndSettings.handleSize
    h = b - y
    @scrollFrame.fullRawMoveTo new Point x, y
    @scrollFrame.rawSetExtent new Point w, h

    # close button
    x = @scrollFrame.left()
    y = @scrollFrame.bottom() + @cornerRadius
    h = WorldMorph.preferencesAndSettings.handleSize
    w = @scrollFrame.width() - h - @cornerRadius
    @buttonClose.fullRawMoveTo new Point x, y
    @buttonClose.rawSetExtent new Point w, h
    trackChanges.pop()
    @changed()
  
