# MorphsListMorph //////////////////////////////////////////////////////

class MorphsListMorph extends BoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  # panes:
  morphsList: null
  buttonClose: null
  resizer: null

  constructor: (target) ->
    super()

    @silentSetExtent new Point(
      WorldMorph.preferencesAndSettings.handleSize * 10,
      WorldMorph.preferencesAndSettings.handleSize * 20 * 2 / 3)
    @isfloatDraggable = true
    @border = 1
    @edge = 5
    @color = new Color(60, 60, 60)
    @buildAndConnectChildren()
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
    @buildAndConnectChildren()
  
  buildAndConnectChildren: ->
    @attribs = []

    # remove existing panes
    @destroyAll()

    # label
    @label = new TextMorph("Morphs List")
    @label.fontSize = WorldMorph.preferencesAndSettings.menuFontSize
    @label.isBold = true
    @label.color = new Color(255, 255, 255)
    @add @label

    # Check which objects end with the word Morph
    theWordMorph = "Morph"
    ListOfMorphs = (Object.keys(window)).filter (i) ->
      i.indexOf(theWordMorph, i.length - theWordMorph.length) isnt -1
    @morphsList = new ListMorph(ListOfMorphs, null)

    # so far nothing happens when items are selected
    #@morphsList.action = (selected) ->
    #  val = myself.target[selected]
    #  myself.currentProperty = val
    #  if val is null
    #    txt = "NULL"
    #  else if isString(val)
    #    txt = val
    #  else
    #    txt = val.toString()
    #  cnts = new TextMorph(txt)
    #  cnts.isEditable = true
    #  cnts.enableSelecting()
    #  cnts.setReceiver myself.target
    #  myself.detail.setContents cnts

    @morphsList.hBar.alpha = 0.6
    @morphsList.vBar.alpha = 0.6
    @add @morphsList

    # close button
    @buttonClose = new TriggerMorph(true, @)
    @buttonClose.setLabel "close"
    @buttonClose.action = "destroy"

    @add @buttonClose

    # resizer
    @resizer = new HandleMorph(@, @edge, @edge)

    # update layout
    @layoutSubmorphs()
  
  layoutSubmorphs: ->
    Morph::trackChanges = false

    # label
    x = @left() + @edge
    y = @top() + @edge
    r = @right() - @edge
    w = r - x
    @label.setPosition new Point(x, y)
    @label.setWidth w
    if @label.height() > (@height() - 50)
      @setHeight @label.height() + 50
      @changed()
      #@resizer.updateBackingStore()

    # morphsList
    y = @label.bottom() + 2
    w = @width() - @edge
    w -= @edge
    b = @bottom() - (2 * @edge) - WorldMorph.preferencesAndSettings.handleSize
    h = b - y
    @morphsList.setPosition new Point(x, y)
    @morphsList.setExtent new Point(w, h)

    # close button
    x = @morphsList.left()
    y = @morphsList.bottom() + @edge
    h = WorldMorph.preferencesAndSettings.handleSize
    w = @morphsList.width() - h - @edge
    @buttonClose.setPosition new Point(x, y)
    @buttonClose.setExtent new Point(w, h)
    Morph::trackChanges = true
    @changed()
  
  setExtent: (aPoint) ->
    super aPoint
