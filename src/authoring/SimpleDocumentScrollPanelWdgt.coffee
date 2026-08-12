# this wraps the functionality of the
# SimpleVerticalStackScrollPanelWdgt into something that has
# a more human name. Also provides additional document-oriented
# features such as for adding divider lines, bullets etc.

class SimpleDocumentScrollPanelWdgt extends SimpleVerticalStackScrollPanelWdgt

  colloquialName: ->
    "document"

  # Smart-placement protocol (see WidgetCreatorAndSmartPlacerOnClickMixin):
  # the placer routes a creator-button click to a frame's CONTENT --
  # `where.contents.smartPlace` -- and for a DocumentWdgt that content is this
  # panel: append the click-created widget and scroll it into view. (§5.B: was
  # on the fused SimpleDocumentWdgt, which only relayed to this panel.)
  acceptsSmartPlacedWidgets: ->
    @dragsDropsAndEditingEnabled

  smartPlace: (widgetToBePlaced, creator) ->
    @add widgetToBePlaced
    @scrollToBottom()
    @bringToForeground()
    creator.bringToForeground()

  getNormalParagraph: (text) ->
    paragraph = new SimpleTextWdgt(
      text,nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    paragraph.isEditable = true
    paragraph.enableSelecting()
    return paragraph

  makeAllContentIntoTemplates: ->
    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents

    for w in childrenNotHandlesNorCarets
      w.isTemplate = true

  addNormalParagraph: (text) ->
    paragraph = @getNormalParagraph text
    @add paragraph
    return paragraph

  addDivider: ->
    divider = @getNormalParagraph ""
    divider.toggleHeaderLine()
    @add divider
    return divider

  # the standard centred 22px title line of the info documents (InfoDocs'
  # shared header, the welcome doc's sections)
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
    codeBlock.setFontName nil, nil, codeBlock.monoFontStack
    @add codeBlock
    return codeBlock

  addSpacer: (numberOfLines = 1) ->
    spacer = @getNormalParagraph "\n".repeat(Math.max 0, numberOfLines - 1)
    spacer.isEditable = true
    spacer.enableSelecting()
    @add spacer
    return spacer