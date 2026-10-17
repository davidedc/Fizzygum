# The TextAreaWdgt allows you show/edit ONE
# text blurb only.
# It doesn't allow you to view/edit multiple text blurbs or
# other Widgets like the VerticalStackPanelWdgt/DocumentWdgt do.
#
# However, what the TextAreaWdgt DOES
# in respect to the VerticalStackPanelWdgt/DocumentWdgt is to
# view/edit UNWRAPPED text, which is quite important for
# code, since really code must have the option of an
# unwrapped view.

class TextAreaWdgt extends ViewportWdgt

  textWdgt: undefined
  modifiedTextTriangleAnnotation: undefined
  widgetToBeNotifiedOfTextModificationChange: undefined

  # a text panel's scroll behavior is intrinsic (the unwrapped code view exists
  # to scroll horizontally); belt+braces — my menus are taken over by the text
  # anyway (see ViewportWdgt.offersScrollPolicyToggle)
  offersScrollPolicyToggle: false

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
    @color = WorldWdgt.theme.textAreaFill
    @textWdgt = new SimpleTextWdgt textAsString,
      backgroundColor: Color.create(230, 230, 130)
      backgroundTransparency: 1
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
  # isEditable, read-only otherwise. The Console / errors-log family reaches this through CodeAreaWdgt's
  # shared _buildMonoCodeAreaNoSettle; the patch nodes (CalculatingPatchNodeWdgt,
  # RegexSubstitutionPatchNodeWdgt, DiffingPatchNodeWdgt) still hand-copy the ~identical setup, each
  # constructing its own panel and keeping its own textWdgt-derived field.
  # The drops/colour lines re-assert the constructor's defaults verbatim — kept so
  # this is pure code-motion (the exact op sequence the call sites ran), not an idempotency argument.
  configureAsMonoTextPanel: (isEditable) ->
    @disableDrops()
    @contents.disableDrops()
    @color = WorldWdgt.theme.textAreaFill
    @textWdgt.backgroundColor = Color.TRANSPARENT
    @textWdgt._setFontNameNoSettle @textWdgt.monoFontStack
    @textWdgt.isEditable = isEditable
    if isEditable then @textWdgt.enableSelecting()
    return @

  # The least height at which I show one whole line of my text without scrolling: one line at my
  # text's font, plus the content inset I keep above and below it (_positionAndResizeChildren's
  # padding). It measures the font, not the text, so a container that floors a text box at it gets
  # the same floor whatever the box holds.
  heightShowingOneLine: ->
    (Math.ceil @textWdgt.fontHeight @textWdgt.originallySetFontSize) + 2 * Math.floor(@extraPadding + @padding)

  colloquialName: ->
    return "text"

  # always content-sizing, wrap on or off (type-test-elimination ε; see
  # ViewportWdgt.isContentSizing)
  isContentSizing: ->
    true

  initialiseDefaultFrameContentLayoutSpec: ->
    @_contentStackSpec = new FrameContentLayoutSpec FrameContentLayoutSpec.DONT_MIND , FrameContentLayoutSpec.DONT_MIND, 1

  checkIfTextContentWasModifiedFromTextAtStart: ->
    @textWdgt.checkIfTextContentWasModifiedFromTextAtStart()

  addModifiedContentIndicator: ->
    @modifiedTextTriangleAnnotation = new ModifiedTextTriangleAnnotationWdgt @
    @textWdgt.widgetToBeNotifiedOfTextModificationChange = @

    @textWdgt.checkIfTextContentWasModifiedFromTextAtStart()

  textContentModified: ->
    @modifiedTextTriangleAnnotation?.show()
    @widgetToBeNotifiedOfTextModificationChange?.textContentModified()

  textContentUnmodified: ->
    @modifiedTextTriangleAnnotation?.hide()
    @widgetToBeNotifiedOfTextModificationChange?.textContentUnmodified()
