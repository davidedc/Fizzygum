class SimpleVerticalStackScrollPanelWdgt extends ScrollPanelWdgt

  @augmentWith BubblesEditModeToCoordinatorMixin, @name

  constructor: (@isTextLineWrapping = true) ->
    VS = new SimpleVerticalStackPanelWdgt

    if !@isTextLineWrapping
      VS.constrainContentWidth = false

    VS.tight = false
    VS.isLockingToPanels = true
    super VS
    @disableDrops()

    ostmA = new SimpleTextWdgt(
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