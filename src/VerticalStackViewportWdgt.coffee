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

    ostmA = @_scaffoldParagraph "A small string\n\n\nhere another."
    ostmA.isEditable = true
    ostmA.enableSelecting()
    @setContents ostmA, 5
    @_wearPageLook()

  # The paragraph I open with, which a caller's setContents replaces: a plain text on the
  # editable-item fill. A document opens with one of its own paragraphs (DocumentViewportWdgt).
  _scaffoldParagraph: (text) ->
    new SimpleTextWdgt text,
      backgroundColor: WorldWdgt.theme.editableItemFill
      backgroundTransparency: 1

  # My look as a page: the stack sample's fill, inside the border every viewport has
  # (panelStroke). A document's page wears its own (DocumentViewportWdgt).
  _wearPageLook: ->
    @setColor WorldWdgt.theme.stackViewportFill

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