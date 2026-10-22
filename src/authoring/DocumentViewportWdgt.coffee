# DocumentWdgt's viewport (extends VerticalStackViewportWdgt) -- named for that role, not
# just for having "a more human name". Also provides additional document-oriented
# features such as for adding divider lines, bullets etc.
#
# A document is a PAGE: a borderless documentPageFill, its items stacked documentItemSpacing apart
# and documentItemSpacing in from the edge of the space around the page -- my own edges, or the
# body of a window that keeps its page gutter around me, the gutter counted toward it -- each
# paragraph in the document text (fonts.document, the documentText ink) on the editable-item fill,
# and the texts on the page dressed as ITEMS: rounded blocks, each text inset from its block's
# edges (itemShapeOfTextOnPlane).

class DocumentViewportWdgt extends VerticalStackViewportWdgt

  colloquialName: ->
    "document"

  # I am a PAGE, not a pane: a window holding me keeps the theme's page gutter (windowPageGutter)
  # around me on every side and between me and each band it docks, and my items' inset YIELDS to
  # that gutter (_itemInset), so my items stand where they would with no gutter at all. Asked by
  # that window at every measure and arrange (FrameWdgt._hostsAPage), through ?(): a payload that
  # does not answer is a pane.
  wantsWindowPageGutter: -> true

  # THE RECEIVER OF DROPS AROUND ME: my stack, where a drop on my page lands. Asked through ?() by a
  # window keeping its page gutter around me (FrameWdgt.dropReceiverForPointsOnMyBody), so a payload
  # released in that gutter goes into my stack, slotted among my items by the release point's height
  # exactly as a drop on my page is (VerticalStackPanelWdgt._indexForDropAt): above my page, first;
  # below it, last.
  receiverOfDropsAroundMe: ->
    @contents

  # Smart-placement protocol (see WidgetCreatorAndSmartPlacerOnClickMixin):
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
  # my own -- a borderless sheet whose edge is where its fill ends, inside the page gutter of a
  # window holding me or bare on the desk.
  _defaultPaneFill: ->
    WorldWdgt.theme.documentPageFill

  _surfaceStroke: ->
    undefined

  # MY ITEM SPACING (documentItemSpacing): my items stand that far apart -- the GAP, which my stack
  # asks of me through its plane (interElementGapOfPlane) -- and that far in from the edge of the
  # space around me, a gutter my window keeps around me counted toward it, so my own INSET is what
  # is left of the spacing past that gutter (_itemInset). The inset is my stack's padding, and my
  # content frame keeps the same margin around my items (my extraPadding; the two must agree, or my
  # arrange and my stack's would each size the stack to a different bottom). Taken from the theme
  # and my parent at the top of every arrange of mine, never from a previous one: a document saved,
  # loaded, duplicated or moved is spaced for the theme and the parent it is next laid out in.
  _positionAndResizeChildren: ->
    @_takeItemSpacing()
    super

  _takeItemSpacing: ->
    inset = @_itemInset()
    @extraPadding = inset
    @contents?.padding = inset

  # MY ITEMS' INSET: the item spacing less the page gutter my parent keeps around me, never below
  # zero -- the band rule applied to items. Asked of my parent through ?() (a window holding me as
  # its page answers its gutter, FrameWdgt.pageGutterAround); a parent that does not answer (the
  # desk, a transform island, a stack) keeps no gutter, so a bare document keeps the whole spacing.
  _itemInset: ->
    Math.max 0, WorldWdgt.theme.documentItemSpacing - ((@parent?.pageGutterAround? @) ? 0)

  # RE-PARENTED: when my new parent changes my items' inset (a window keeping its page gutter around
  # me, or a parent that keeps none), I mark my own layout so my next arrange re-takes it -- the
  # inset is taken only at the top of an arrange of mine (_takeItemSpacing), and a re-parenting
  # does not arrange a viewport by itself (a window adopting me as its page can keep my extent, and
  # an unchanged extent re-fits nothing). Nothing is marked while the inset stays what it is. A
  # dirty mark, no settle (a notification hook is settle-neutral: the add's dispatcher owns the
  # settle), through the phase valve, because an add can run inside a layout pass, where the
  # climbing _invalidateLayout throws.
  _reactToBeingAdded: (whereTo, beingDropped) ->
    super
    @_scheduleRelayoutRespectingPhase() unless @_itemInset() is @extraPadding

  # content set into me stands at my items' inset (_itemInset: the margin my arrange keeps around
  # it), so a caller hands me the content alone
  setContents: (aWdgt) ->
    super aWdgt, @_itemInset()

  # THE GAP between two consecutive items on my page, asked through my plane by my stack
  # (VerticalStackPanelWdgt.interElementGap) at every measure and arrange: the theme's item spacing,
  # whatever gutter surrounds me -- only my inset yields to a window's gutter, never the space
  # between my items. Read from the theme at every ask and kept nowhere.
  interElementGapOfPlane: (plane) ->
    return undefined unless @isMyContentsPanel plane
    WorldWdgt.theme.documentItemSpacing

  # MY CARET SCROLL MARGIN (ViewportWdgt._caretScrollMargin, read by scrollCaretIntoView): a caret I
  # bring into view comes to stand the theme's item spacing past my padded interior's edge, whatever
  # my inset is. It is my SCROLL padding (CSS scroll-padding), a scrolling policy apart from my
  # layout inset (CSS padding): where my inset yields to a window's page gutter (_itemInset, 0 at a
  # gutter of the whole spacing) a caret scrolled into view still keeps some of its neighbouring
  # lines in sight instead of landing flush with my edge; bare on the desk it equals my inset, as
  # for any viewport. Read from the theme at every follow and kept nowhere.
  _caretScrollMargin: ->
    @padding + WorldWdgt.theme.documentItemSpacing

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
