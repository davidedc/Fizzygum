# The SimplePlainTextScrollPanelWdgt allows you show/edit ONE
# text blurb only.
# It doesn't allow you to view/edit multiple text blurbs or
# other Widgets like the SimpleVerticalStackPanelWdgt/DocumentViewerOrEditor do.
#
# However, what the SimplePlainTextScrollPanelWdgt DOES
# in respect to the SimpleVerticalStackPanelWdgt/DocumentViewerOrEditor is to
# view/edit UNWRAPPED text, which is quite important for
# code, since really code must have the option of an
# unwrapped view.

class SimplePlainTextScrollPanelWdgt extends ScrollPanelWdgt

  textWdgt: nil
  modifiedTextTriangleAnnotation: nil
  widgetToBeNotifiedOfTextModificationChange: nil

  constructor: (
    textAsString,
    wraps,
    padding
    ) ->

    super()
    @takesOverAndMergesChildrensMenus = true
    @disableDrops()
    @contents.disableDrops()
    @isTextLineWrapping = wraps
    @color = Color.WHITE
    @textWdgt = new SimplePlainTextWdgt(
      textAsString,nil,nil,nil,nil,nil,Color.create(230, 230, 130), 1)
    @textWdgt.isEditable = true
    if !wraps
      # non-wrapping ("code view"): the box hugs the natural, un-wrapped text width
      # and scrolls horizontally.
      @textWdgt.softWrap = false
    @textWdgt.enableSelecting()
    @setContents @textWdgt, padding
    @textWdgt.lockToPanels()

  # Configure this panel as the "mono text-entry box" the code-editing widgets share: a white, drops-disabled
  # panel whose text widget has a transparent background and a monospaced font, editable-and-selectable when
  # isEditable, read-only otherwise. Factored out of the ~identical setup copied into the patch nodes, the
  # Console and the errors-log viewer (each still does its own `new … , false, 5` and keeps its own textWdgt
  # reference + _addNoSettle). The drops/colour lines re-assert the constructor's defaults verbatim — kept so
  # this is pure code-motion (the exact op sequence the call sites ran), not an idempotency argument.
  configureAsMonoTextPanel: (isEditable) ->
    @disableDrops()
    @contents.disableDrops()
    @color = Color.WHITE
    @textWdgt.backgroundColor = Color.TRANSPARENT
    @textWdgt._setFontNameNoSettle nil, nil, @textWdgt.monoFontStack
    @textWdgt.isEditable = isEditable
    if isEditable then @textWdgt.enableSelecting()
    return @

  colloquialName: ->
    return "text"

  # always content-sizing, wrap on or off (type-test-elimination ε; see
  # ScrollPanelWdgt.isContentSizing)
  isContentSizing: ->
    true

  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec WindowContentLayoutSpec.DONT_MIND , WindowContentLayoutSpec.DONT_MIND, 1

  checkIfTextContentWasModifiedFromTextAtStart: ->
    @textWdgt.checkIfTextContentWasModifiedFromTextAtStart()

  addModifiedContentIndicator: ->
    @modifiedTextTriangleAnnotation = new ModifiedTextTriangleAnnotationWdgt @
    @textWdgt.widgetToBeNotifiedOfTextModificationChange = @

    # just because we add the modified content indicator it
    # doesn't mean that we automatically "save" the content,
    # so removing this.
    # @textWdgt.considerCurrentTextAsReferenceText()

    @textWdgt.checkIfTextContentWasModifiedFromTextAtStart()

  textContentModified: ->
    @modifiedTextTriangleAnnotation?.show()
    @widgetToBeNotifiedOfTextModificationChange?.textContentModified()

  textContentUnmodified: ->
    @modifiedTextTriangleAnnotation?.hide()
    @widgetToBeNotifiedOfTextModificationChange?.textContentUnmodified()
