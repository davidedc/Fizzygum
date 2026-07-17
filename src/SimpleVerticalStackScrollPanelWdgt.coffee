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

  # always content-sizing, wrap on or off (type-test-elimination ε; see
  # ScrollPanelWdgt.isContentSizing)
  isContentSizing: ->
    true

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.removeMenuItem "move all inside"

    if @contents?
      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents

    @_addEditingLockMenuEntries menu, childrenNotHandlesNorCarets

  # Bubble enable/disable-editing up to my editing-coordinating parent if it is one
  # (was `@parent instanceof SimpleDocumentWdgt`), otherwise do the local Widget work
  # via super. Widget defines a base enableDragsDropsAndEditing, so a bare
  # `@parent.enableDragsDropsAndEditing?()` would bubble to ANY parent -- the capability
  # query keeps it to the coordinator. (type-test-elimination campaign)
  # Only the CORES are overridden here: ScrollPanelWdgt's public enable/disableDragsDropsAndEditing
  # wrappers are the canonical settle-wraps and dispatch straight back to these.
  _enableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.showEditModeInBar?()
    if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
      @parent._enableDragsDropsAndEditingNoSettle @
    else
      super @

  _disableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.showViewModeInBar?()
    if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
      @parent._disableDragsDropsAndEditingNoSettle @
    else
      super @