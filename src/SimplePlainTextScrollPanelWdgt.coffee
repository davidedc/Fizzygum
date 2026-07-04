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
    

  colloquialName: ->
    return "text"

  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec PreferredSize.DONT_MIND , PreferredSize.DONT_MIND, 1

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
