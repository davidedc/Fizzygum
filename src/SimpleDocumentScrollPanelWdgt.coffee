# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

# this wraps the functionality of the
# SimpleVerticalStackScrollPanelWdgt into something that has
# a more human name. Also provides additional document-oriented
# features such as for addind divider lines, bullets etc.

class SimpleDocumentScrollPanelWdgt extends SimpleVerticalStackScrollPanelWdgt

  colloquialName: ->
    "document"

  getNormalParagraph: (text) ->
    paragraph = new SimplePlainTextWdgt(
      text,nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    paragraph.isEditable = true
    paragraph.enableSelecting()
    return paragraph

  makeAllContentIntoTemplates: ->
    childrenNotHandlesNorCarets = @contents.children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    for eachChild in childrenNotHandlesNorCarets
      eachChild.isTemplate = true

  addNormalParagraph: (text) ->
    paragraph = @getNormalParagraph text
    @add paragraph
    return paragraph

  addDivider: ->
    divider = @getNormalParagraph ""
    divider.toggleHeaderLine()
    @add divider
    return divider

  addIndentedText: (text)->
    indentedText = @getNormalParagraph text
    indentedText.rawSetExtent new Point Math.round(92*@width()/100), 335
    @add indentedText
    indentedText.layoutSpecDetails.setAlignmentToRight()
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

    # TODO it's 2018 now, if you see this in 2019
    # consider replacing this with ES6 repeat() method
    repeatStringNumTimes = (string, times) ->
      repeatedString = ''
      while times > 0
        repeatedString += string
        times--
      repeatedString

    spacer = @getNormalParagraph repeatStringNumTimes("\n",numberOfLines-1)
    spacer.isEditable = true
    spacer.enableSelecting()
    @add spacer
    return spacer