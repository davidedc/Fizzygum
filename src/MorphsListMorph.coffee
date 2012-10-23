# MorphsListMorph //////////////////////////////////////////////////////

class MorphsListMorph extends BoxMorph
  constructor: (target) ->
    # additional properties:
    #
    # initialize inherited properties:
    super()
    #
    # override inherited properties:
    @silentSetExtent new Point(WorldMorph.MorphicPreferences.handleSize * 10, WorldMorph.MorphicPreferences.handleSize * 20 * 2 / 3)
    @isDraggable = true
    @border = 1
    @edge = 5
    @color = new Color(60, 60, 60)
    @borderColor = new Color(95, 95, 95)
    @drawNew()
    #
    # panes:
    @morphsList = null
    @buttonClose = null
    @resizer = null
    @buildPanes()
  
  setTarget: (target) ->
    @target = target
    @currentProperty = null
    @buildPanes()
  
  buildPanes: ->
    attribs = []
    property = undefined
    ctrl = undefined
    ev = undefined
    #
    # remove existing panes
    @children.forEach (m) ->
      # keep work pane around
      m.destroy()  if m isnt @work
    #
    @children = []
    #
    # label
    @label = new TextMorph("Morphs List")
    @label.fontSize = WorldMorph.MorphicPreferences.menuFontSize
    @label.isBold = true
    @label.color = new Color(255, 255, 255)
    @label.drawNew()
    @add @label
    #
    ListOfMorphs = []
    for i of window
      theWordMorph = "Morph"
      ListOfMorphs.push i  if i.indexOf(theWordMorph, i.length - theWordMorph.length) isnt -1
    @morphsList = new ListMorph(ListOfMorphs, null)
    #
    # so far nothing happens when items are selected
    #@morphsList.action = (selected) ->
    #  val = undefined
    #  txt = undefined
    #  cnts = undefined
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
    #
    @morphsList.hBar.alpha = 0.6
    @morphsList.vBar.alpha = 0.6
    @add @morphsList
    #
    # close button
    @buttonClose = new TriggerMorph()
    @buttonClose.labelString = "close"
    @buttonClose.action = =>
      @destroy()
    #
    @add @buttonClose
    #
    # resizer
    @resizer = new HandleMorph(@, 150, 100, @edge, @edge)
    #
    # update layout
    @fixLayout()
  
  fixLayout: ->
    x = undefined
    y = undefined
    r = undefined
    b = undefined
    w = undefined
    h = undefined
    Morph::trackChanges = false
    #
    # label
    x = @left() + @edge
    y = @top() + @edge
    r = @right() - @edge
    w = r - x
    @label.setPosition new Point(x, y)
    @label.setWidth w
    if @label.height() > (@height() - 50)
      @silentSetHeight @label.height() + 50
      @drawNew()
      @changed()
      @resizer.drawNew()
    #
    # morphsList
    y = @label.bottom() + 2
    w = @width() - @edge
    w -= @edge
    b = @bottom() - (2 * @edge) - WorldMorph.MorphicPreferences.handleSize
    h = b - y
    @morphsList.setPosition new Point(x, y)
    @morphsList.setExtent new Point(w, h)
    #
    # close button
    x = @morphsList.left()
    y = @morphsList.bottom() + @edge
    h = WorldMorph.MorphicPreferences.handleSize
    w = @morphsList.width() - h - @edge
    @buttonClose.setPosition new Point(x, y)
    @buttonClose.setExtent new Point(w, h)
    Morph::trackChanges = true
    @changed()
  
  setExtent: (aPoint) ->
    super aPoint
    @fixLayout()
