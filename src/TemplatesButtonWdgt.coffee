# REQUIRES HighlightableMixin
# REQUIRES ParentStainerMixin

class TemplatesButtonWdgt extends IconMorph

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @appearance = new TemplatesIconAppearance @

    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @setColor new Color 0, 0, 0

  createNewTemplatesWindow: ->
    sdspw = new SimpleDocumentScrollPanelWdgt()

    sdspw.rawSetExtent new Point 365, 335

    startingContent = new SimplePlainTextWdgt(
      "Simply drag the items below into your document",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.alignCenter()
    startingContent.setFontSize 18
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true

    sdspw.setContents startingContent, 5


    startingContent = new ArrowSIconWdgt()
    startingContent.rawSetExtent new Point 25, 25
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToCenter()
    startingContent.isTemplate = true

    startingContent = new SimplePlainTextWdgt(
      "",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    startingContent.toggleHeaderLine()
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "Title",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.alignCenter()
    startingContent.setFontName nil, nil, startingContent.georgiaFontStack
    startingContent.setFontSize 48
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "Section X",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.setFontSize 28
    startingContent.isTemplate = true
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "Section X.X",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.setFontSize 24
    startingContent.isTemplate = true
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "Normal text.",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "“Be careful--with quotations, you can damn anything.”\n― André Malraux",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.toggleItalic()
    startingContent.alignRight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    sdspw.add startingContent


    startingContent = new SimplePlainTextWdgt(
      "indented text",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    startingContent.rawSetExtent new Point Math.round(90*sdspw.width()/100), 335
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()


    startingContent = new SimplePlainTextWdgt(
      "a code block with\n  some example\n    code in here",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.setFontName nil, nil, startingContent.monoFontStack
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    startingContent.rawSetExtent new Point Math.round(90*sdspw.width()/100), 335
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    startingContent = new SimplePlainTextWdgt(
      "Spacers:",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "\n",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "\n\n",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "Divider line:",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    startingContent.toggleHeaderLine()
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "Links:",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    sdspw.add startingContent

    startingContent = new SimpleLinkWdgt()
    startingContent.rawSetExtent new Point 405, 50
    startingContent.isTemplate = true
    sdspw.add startingContent

    startingContent = new SimpleVideoLinkWdgt()
    startingContent.rawSetExtent new Point 405, 50
    startingContent.isTemplate = true
    sdspw.add startingContent

    wm = new WindowWdgt nil, nil, sdspw
    wm.setExtent new Point 365, 335
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 50
    wm.fullRawMoveWithin world
    world.add wm
    wm.setTitleWithoutPrependedContentName "templates"
    wm.changed()



    world.simpleEditorTemplates = wm

  bringTemplatesWindowIntoView: ->
    world.simpleEditorTemplates.bringToForeground()
    world.simpleEditorTemplates.fullRawMoveTo world.hand.position().subtract new Point 50, 50
    world.simpleEditorTemplates.fullRawMoveWithin world

  mouseClickLeft: ->
    if world.simpleEditorTemplates?
      if world.simpleEditorTemplates.destroyed or !world.simpleEditorTemplates.parent?
        @createNewTemplatesWindow()
      else if world.simpleEditorTemplates.parent? and world.simpleEditorTemplates.parent == world.basementWdgt.scrollPanel.contents
        world.add world.simpleEditorTemplates
        @bringTemplatesWindowIntoView()
      else if !world.simpleEditorTemplates.destroyed and world.simpleEditorTemplates.parent == world
        @bringTemplatesWindowIntoView()
    else
      @createNewTemplatesWindow()


