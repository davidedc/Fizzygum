class VerticalStackViewportWdgt extends ViewportWdgt

  @augmentWith BubblesEditModeToCoordinatorMixin, @name

  # a stack/document's height IS its content — cropping it silently hides
  # paragraphs (see ViewportWdgt.offersScrollPolicyToggle)
  offersScrollPolicyToggle: false

  constructor: (@isTextLineWrapping = true) ->
    VS = new VerticalStackPanelWdgt

    if !@isTextLineWrapping
      VS.constrainContentWidth = false

    VS.tight = false
    VS.isLockingToPanels = true
    super VS
    @disableDrops()

    ostmA = new SimpleTextWdgt "A small string\n\n\nhere another.",
      backgroundColor: WorldWdgt.preferencesAndSettings.editableItemBackgroundColor
      backgroundTransparency: 1
    ostmA.isEditable = true
    ostmA.enableSelecting()
    @setContents ostmA, 5
    @setColor Color.create 249, 249, 249

  colloquialName: ->
    "stack"

  # always content-sizing, wrap on or off (type-test-elimination ε; see
  # ViewportWdgt.isContentSizing)
  isContentSizing: ->
    true

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super

    if @contents?
      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents

    @_addEditingLockMenuEntries menu, childrenNotHandlesNorCarets
    # surface the edit-layout toggle on the DOCUMENT's own menu (what the user right-clicks),
    # targeting the inner stack that owns the scaffold — same reach-into-contents shape as
    # the editing-lock entries above
    if @contents?.hostsContentStackDropSlots?()
      @contents.addLayoutEditingMenuEntries menu