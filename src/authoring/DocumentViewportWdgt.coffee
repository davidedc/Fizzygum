# DocumentWdgt's viewport (extends VerticalStackViewportWdgt) -- named for that role, not
# just for having "a more human name". Also provides additional document-oriented
# features such as for adding divider lines, bullets etc.
#
# A document is a sheet of PAPER: a borderless documentPageFill reaching my own edges, in a window
# as bare on the desk -- a window holding me is my frame, its lines my edges, and keeps no gutter
# around me (I am its pane: FrameWdgt._hostsAPage) -- its items stacked documentItemSpacing apart
# and documentItemSpacing in from my edges, the MARGIN I keep around my plane (planeMargin), where
# my plane is cropped and my scroll indicators and my plane's selection ring stand; each paragraph
# in the document text (fonts.document, the documentText ink) on the editable-item fill, and the
# texts on the page dressed as ITEMS: rounded blocks, each text inset from its block's edges
# (itemShapeOfTextOnPlane).

class DocumentViewportWdgt extends VerticalStackViewportWdgt

  colloquialName: ->
    "document"

  # Smart-placement protocol (see CreatorWdgt.activated):
  # the placer routes a creator-button click to a frame's CONTENT --
  # `where.contents.smartPlace` -- and for a DocumentWdgt that content is this
  # viewport: append the click-created widget and scroll it into view. (§5.B: was
  # on the fused SimpleDocumentWdgt, which only relayed to this viewport.)
  acceptsSmartPlacedWidgets: ->
    @dragsDropsAndEditingEnabled

  smartPlace: (widgetToBePlaced, creator) ->
    @add widgetToBePlaced
    @scrollToBottom()
    @bringToForeground()
    creator.bringToForeground()

  # A paragraph of mine: editable, selectable text in the document role (fonts.document, the
  # documentText ink) on the editable-item fill. Every paragraph a document builds comes from
  # here -- the helpers below, the Docs Maker's starting paragraph, the info, welcome, how-to-save
  # and sample documents -- and one set at another size (a title) keeps the role's line height
  # scaled with its em box (StringWdgt.linePitch).
  getNormalParagraph: (text) ->
    theme = WorldWdgt.theme
    paragraph = new SimpleTextWdgt text,
      fontRole: theme.fonts.document
      color: theme.documentText
      backgroundColor: theme.editableItemFill
      backgroundTransparency: 1
    paragraph.isEditable = true
    paragraph.enableSelecting()
    return paragraph

  # I open with one of my own paragraphs (the stack sample opens with a plain text)
  _scaffoldParagraph: (text) ->
    @getNormalParagraph text

  # My look as a page, read as I and my stack are painted: the document's paper, with no border of
  # my own -- a borderless sheet whose edge is where its fill ends, at the lines of a window holding
  # me or bare on the desk; my margin shows my own fill, which is my plane's (the mimic).
  _defaultPaneFill: ->
    WorldWdgt.theme.documentPageFill

  _surfaceStroke: ->
    undefined

  # MY ITEM SPACING (documentItemSpacing): my items stand that far apart -- the GAP, which my stack
  # asks of me through its plane (interElementGapOfPlane) -- and that far in from my edges: my MARGIN
  # (planeMargin), where my plane is cropped and my indicators and my plane's selection ring stand,
  # and my stack's padding, so my content frame and my stack's own arrange size the stack to one
  # bottom. Taken from the theme at the top of every arrange of mine, never from a previous one: a
  # document saved, loaded, duplicated or moved is spaced for the theme it is next laid out in, in a
  # window as on the desk. The margin is mapping state, so it goes through its write door
  # (ViewportWdgt._writePlaneMargin).
  _positionAndResizeChildren: ->
    @_takeItemSpacing()
    super

  _takeItemSpacing: ->
    spacing = WorldWdgt.theme.documentItemSpacing
    @_writePlaneMargin spacing
    @extraPadding = 0
    @contents?.padding = spacing

  # content set into me stands at my margin, which I take first: my constructor sets my opening
  # paragraph before any arrange of mine has run (VerticalStackViewportWdgt)
  setContents: (aWdgt) ->
    @_takeItemSpacing()
    super aWdgt

  # THE GAP between two consecutive items on my page, asked through my plane by my stack
  # (VerticalStackPanelWdgt.interElementGap) at every measure and arrange: the theme's item spacing,
  # the same as my margin. Read from the theme at every ask and kept nowhere.
  interElementGapOfPlane: (plane) ->
    return undefined unless @isMyContentsPanel plane
    WorldWdgt.theme.documentItemSpacing

  # THE ITEM SHAPE a text standing on my page wears, asked through my plane (the stack:
  # VerticalStackPanelWdgt.itemShapeOfContainedText) by the text itself, at every measure, paint and
  # point mapping (StringWdgt's THE ITEM SHAPE, which also says which texts can wear one): a block
  # filled rounded at documentItemCornerRadius, its text standing documentItemHorizontalPadding in
  # from the block's sides and documentItemVerticalPadding from its top and bottom. Read from the
  # theme at every ask and kept nowhere, so a document laid out in a world wears that world's.
  itemShapeOfTextOnPlane: (plane) ->
    return undefined unless @isMyContentsPanel plane
    theme = WorldWdgt.theme
    cornerRadius: theme.documentItemCornerRadius
    inset: new Point theme.documentItemHorizontalPadding, theme.documentItemVerticalPadding

  makeAllContentIntoTemplates: ->
    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents

    for w in childrenNotHandlesNorCarets
      w.isTemplate = true

  addNormalParagraph: (text) ->
    paragraph = @getNormalParagraph text
    @add paragraph
    return paragraph

  # a DIVIDER: an empty paragraph with a header line -- one line tall, so on my page an item one
  # line plus its padding tall, its rule running through the middle of that line from 5 px past
  # the (empty) text to the end of the item's text area (StringWdgt._drawHeaderUnderline)
  addDivider: ->
    divider = @getNormalParagraph ""
    divider.toggleHeaderLine()
    @add divider
    return divider

  # the standard centred 22 px title line of the info documents (InfoDocs' shared header, the
  # welcome doc's sections), on the document role's line height scaled to its size (33 px lines)
  addTitle: (text) ->
    title = @getNormalParagraph text
    title.alignCenter()
    title.setFontSize 22
    @add title
    return title

  # a bold section heading at the running text size (the templates window's
  # section labels)
  addSectionHeading: (text) ->
    heading = @getNormalParagraph text
    heading.toggleWeight()
    @add heading
    return heading

  addIndentedText: (text)->
    indentedText = @getNormalParagraph text
    indentedText._applyExtent new Point Math.round(92*@width()/100), 335
    @add indentedText
    indentedText._contentStackSpec.setAlignmentToRight()
    return indentedText

  addBulletPoint: (text) ->
    bulletPoint = @addIndentedText "• " + text
    return bulletPoint

  addCodeBlock: (text) ->
    codeBlock = @addIndentedText "a code block with\n  some example\n    code in here"
    codeBlock.setFontName codeBlock.monoFontStack
    @add codeBlock
    return codeBlock

  addSpacer: (numberOfLines = 1) ->
    spacer = @getNormalParagraph "\n".repeat(Math.max 0, numberOfLines - 1)
    spacer.isEditable = true
    spacer.enableSelecting()
    @add spacer
    return spacer
