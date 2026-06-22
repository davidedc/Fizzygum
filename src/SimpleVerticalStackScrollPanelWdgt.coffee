class SimpleVerticalStackScrollPanelWdgt extends ScrollPanelWdgt

  constructor: (@isTextLineWrapping = true) ->
    VS = new SimpleVerticalStackPanelWdgt

    if !@isTextLineWrapping
      VS.constrainContentWidth = false

    VS.tight = false
    VS.isLockingToPanels = true
    super VS
    @disableDrops()

    ostmA = new SimplePlainTextWdgt(
      "A small string\n\n\nhere another.",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    ostmA.isEditable = true
    ostmA.enableSelecting()
    @setContents ostmA, 5
    @setColor Color.create 249, 249, 249

  colloquialName: ->
    "stack"

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.removeMenuItem "move all inside"

    if @contents?
      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents

    if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length > 0
      menu.addLine()
      if !@dragsDropsAndEditingEnabled
        menu.addMenuItem "enable editing", true, @, "enableDragsDropsAndEditing", "lets you drag content in and out"
      else
        menu.addMenuItem "disable editing", true, @, "disableDragsDropsAndEditing", "prevents dragging content in and out"

    menu.removeConsecutiveLines()

  # Bubble enable/disable-editing up to my editing-coordinating parent if it is one
  # (was `@parent instanceof SimpleDocumentWdgt`), otherwise do the local Widget work
  # via super. Widget defines a base enableDragsDropsAndEditing, so a bare
  # `@parent.enableDragsDropsAndEditing?()` would bubble to ANY parent -- the capability
  # query keeps it to the coordinator. (type-test-elimination campaign)
  enableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.makePencilYellow?()
    if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
      @parent.enableDragsDropsAndEditing @
    else
      super @

  disableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.makePencilClear?()
    if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
      @parent.disableDragsDropsAndEditing @
    else
      super @