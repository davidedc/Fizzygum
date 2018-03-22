# REQUIRES DeepCopierMixin

# All "actions" functions for all accessory menu items should belong
# in here. Also helps so we don't pollute moprhs with a varying number
# of helper functions, which is problematic for visual diffing
# on inspectors (the number of methods keeps changing).

class MenusHelper

  @augmentWith DeepCopierMixin

  popUpDevToolsMenu: (morphOpeningThePopUp, widgetThisMenuIsAbout) ->
    debugger
    menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "Dev Tools"
    menu.addMenuItem "inspect", true, widgetThisMenuIsAbout, "inspect2", "open a window\non all properties"
    menu.addMenuItem "console", true, widgetThisMenuIsAbout, "createConsole", "console"

    menu.popUpAtHand()


  # »>> this part is excluded from the fizzygum homepage build
  createFridgeMagnets: ->
    debugger
    fmm = new FridgeMagnetsMorph()
    wm = new WindowWdgt nil, nil, fmm
    wm.setExtent new Point 570, 400
    wm.fullRawMoveTo world.hand.position()
    wm.fullRawMoveWithin world
    world.add wm
    wm.changed()
  # this part is excluded from the fizzygum homepage build <<«


  createReconfigurablePaint: ->
    reconfPaint = new ReconfigurablePaintWdgt()
    wm = new WindowWdgt nil, nil, reconfPaint
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position()
    wm.fullRawMoveWithin world
    world.add wm
    wm.changed()

  createSimpleSlideWdgt: ->
    simpleSlide = new SimpleSlideWdgt()
    wm = new WindowWdgt nil, nil, simpleSlide
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position()
    wm.fullRawMoveWithin world
    world.add wm
    wm.changed()

  createSimpleButton: ->
    world.create new SimpleRectangularButtonMorph true, @, nil, new IconMorph(nil)

  createSwitchButtonMorph: ->
    button1 = new SimpleRectangularButtonMorph true, @, nil, new IconMorph(nil)
    button2 = new SimpleRectangularButtonMorph true, @, nil, new StringMorph2 "Hello World! ⎲ƒ⎳⎷ ⎸⎹ "
    world.create new SwitchButtonMorph [button1, button2]

  createNewClippingBoxMorph: ->
    world.create new ClippingBoxMorph()

  makeSlidersButtonsStatesBright: ->
    world.forAllChildrenBottomToTop (child) ->
      if child instanceof SliderButtonMorph
       child.pressColor = new Color 0, 255, 0
       child.highlightColor = new Color 0, 0, 255
       child.normalColor = new Color 0, 0, 0

  # Icons --------------------------------------------------------------

  makeIconWithText: ->
    world.create new WidgetHolderWithCaptionWdgt "hey there", new BrushIconMorph()

  makeEmptyIconWithText: ->
    world.create new WidgetHolderWithCaptionWdgt "hey there"

  makeFolderWindow: (a,b,c,d,e) ->
    debugger
    world.create new FolderWindowWdgt nil,nil,nil,nil, @

  makeBouncingParticle: ->
    world.create new BouncerWdgt()

  createDestroyIconMorph: ->
    world.create new DestroyIconMorph()

  createUnderCarpetIconMorph: ->
    world.create new UnderCarpetIconMorph()

  createUncollapsedStateIconMorph: ->
    world.create new UncollapsedStateIconMorph()

  createCollapsedStateIconMorph: ->
    world.create new CollapsedStateIconMorph()

  createCloseIconButtonMorph: ->
    world.create new CloseIconButtonMorph()

  createScratchAreaIconMorph: ->
    world.create new ScratchAreaIconMorph()

  createFloraIconMorph: ->
    world.create new FloraIconMorph()

  createScooterIconMorph: ->
    world.create new ScooterIconMorph()

  createHeartIconMorph: ->
    world.create new HeartIconMorph()


  createPencil1IconMorph: ->
    world.create new PencilIconMorph()

  createPencil2IconMorph: ->
    world.create new Pencil2IconMorph()

  createBrushIconMorph: ->
    world.create new BrushIconMorph()

  createToothpasteIconMorph: ->
    world.create new ToothpasteIconMorph()

  createEraserIconMorph: ->
    world.create new EraserIconMorph()


  createTrashcanIconWdgt: ->
    world.create new TrashcanIconWdgt()

  createShortcutArrowIconWdgt: ->
    world.create new ShortcutArrowIconWdgt()

  createRasterPicIconWdgt: ->
    world.create new RasterPicIconWdgt()

  createPaintBucketIconWdgt: ->
    world.create new PaintBucketIconWdgt()

  createObjectIconWdgt: ->
    world.create new ObjectIconWdgt()

  createFolderIconWdgt: ->
    world.create new FolderIconWdgt()

  createBasementIconWdgt: ->
    world.create new BasementIconWdgt()

  createWidgetIconWdgt: ->
    world.create new WidgetIconWdgt()

  makeGenericReferenceIcon: ->
    world.create new GenericShortcutIconWdgt()

  makeGenericObjectIcon: ->
    world.create new GenericObjectIconWdgt()


  basementIconAndText: ->
    world.add new BasementOpenerWdgt()

  newScriptWindow: ->
    scriptWdgt = new ScriptWdgt()
    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm
    wm.changed()

  createFizzyPaintLauncher: ->
    scriptWdgt = new ScriptWdgt """
      reconfPaint = new ReconfigurablePaintWdgt()
      wm = new WindowWdgt nil, nil, reconfPaint
      wm.setExtent new Point 460, 400
      wm.fullRawMoveTo world.hand.position()
      wm.fullRawMoveWithin world
      world.add wm
      wm.changed()
    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    wm.changed()

    fizzyPaintLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Fizzypaint", new PaintBucketIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add fizzyPaintLauncher
    fizzyPaintLauncher.setExtent new Point 75, 75
    fizzyPaintLauncher.fullChanged()
    return wm

  createFizzyPaintLauncherAndItsIcon: ->
    wm = @createFizzyPaintLauncher()
    world.add wm

  createSimpleDocumentLauncher: ->
    scriptWdgt = new ScriptWdgt """
      reconfPaint = new SimpleDocumentWdgt()
      wm = new WindowWdgt nil, nil, reconfPaint
      wm.setExtent new Point 460, 400
      wm.fullRawMoveTo world.hand.position()
      wm.fullRawMoveWithin world
      world.add wm
      wm.changed()
    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    wm.changed()

    simpleDocumentLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Simple docs", new TypewriterIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add simpleDocumentLauncher
    simpleDocumentLauncher.setExtent new Point 75, 75
    simpleDocumentLauncher.fullChanged()
    return wm

  createSimpleDocumentLauncherAndItsIcon: ->
    wm = @createSimpleDocumentLauncher()
    world.add wm

  createSimpleSlideLauncher: ->
    scriptWdgt = new ScriptWdgt """
      reconfPaint = new SimpleSlideWdgt()
      wm = new WindowWdgt nil, nil, reconfPaint
      wm.setExtent new Point 460, 400
      wm.fullRawMoveTo world.hand.position()
      wm.fullRawMoveWithin world
      world.add wm
      wm.changed()
    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    wm.changed()

    simpleSlideLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Simple slides", new SimpleSlideIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add simpleSlideLauncher
    simpleSlideLauncher.setExtent new Point 75, 75
    simpleSlideLauncher.fullChanged()
    return wm

  createSimpleSlideLauncherAndItsIcon: ->
    wm = @createSimpleSlideLauncher()
    world.add wm

  createDashboardsLauncher: ->
    scriptWdgt = new ScriptWdgt """
      reconfPaint = new DashboardsWdgt()
      wm = new WindowWdgt nil, nil, reconfPaint
      wm.setExtent new Point 460, 400
      wm.fullRawMoveTo world.hand.position()
      wm.fullRawMoveWithin world
      world.add wm
      wm.changed()
    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    wm.changed()

    simpleDashboardsLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Dashboards", new DashboardsIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add simpleDashboardsLauncher
    simpleDashboardsLauncher.setExtent new Point 75, 75
    simpleDashboardsLauncher.fullChanged()
    return wm


  createPatchProgrammingLauncher: ->
    scriptWdgt = new ScriptWdgt """
      reconfPaint = new PatchProgrammingWdgt()
      wm = new WindowWdgt nil, nil, reconfPaint
      wm.setExtent new Point 460, 400
      wm.fullRawMoveTo world.hand.position()
      wm.fullRawMoveWithin world
      world.add wm
      wm.changed()
    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    wm.changed()

    patchProgrammingLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Patch progr.", new PatchProgrammingIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add patchProgrammingLauncher
    patchProgrammingLauncher.setExtent new Point 75, 75
    patchProgrammingLauncher.fullChanged()
    return wm

  createGenericPanelLauncher: ->
    scriptWdgt = new ScriptWdgt """
      genericPanel = new StretchableEditableWdgt()
      wm = new WindowWdgt nil, nil, genericPanel
      wm.setExtent new Point 460, 400
      wm.fullRawMoveTo world.hand.position()
      wm.fullRawMoveWithin world
      world.add wm
      wm.changed()
    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    wm.changed()

    genericPanelLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Generic panel", new GenericPanelIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add genericPanelLauncher
    genericPanelLauncher.setExtent new Point 75, 75
    genericPanelLauncher.fullChanged()
    return wm

  createToolbarsOpener: ->
    scriptWdgt = new ScriptWdgt """

      # tools -------------------------------
      toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt()

      toolsPanel.addMany [
        new TextToolbarCreatorButtonWdgt()
        new UsefulTextSnippetsToolbarCreatorButtonWdgt()
        new SlidesToolbarCreatorButtonWdgt()
        new PlotsToolbarCreatorButtonWdgt()
        new PatchProgrammingComponentsToolbarCreatorButtonWdgt()
        new WindowsToolbarCreatorButtonWdgt()
      ]

      toolsPanel.disableDragsDropsAndEditing()

      wm = new WindowWdgt nil, nil, toolsPanel
      wm.setExtent new Point 60, 261
      wm.fullRawMoveTo new Point 90, Math.floor((world.height()-192)/2)
      wm.fullRawMoveWithin world
      world.add wm
      wm.changed()


    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    wm.changed()

    toolbarsOpenerLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Super Toolbar", new ToolbarsIconWdgt()
    toolbarsOpenerLauncher.toolTipMessage = "a toolbar to rule them all"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add toolbarsOpenerLauncher
    toolbarsOpenerLauncher.setExtent new Point 75, 75
    toolbarsOpenerLauncher.fullChanged()
    return wm

  createNewTemplatesWindow: ->
    sdspw = new SimpleDocumentScrollPanelWdgt()

    sdspw.rawSetExtent new Point 365, 335

    startingContent = new SimplePlainTextWdgt(
      "Simply drag the items below into your document",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 18
    startingContent.isEditable = true
    startingContent.enableSelecting()

    sdspw.setContents startingContent, 5


    startingContent = new ArrowSIconWdgt()
    startingContent.rawSetExtent new Point 25, 25
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    sdspw.addDivider()

    startingContent = new SimplePlainTextWdgt(
      "Title",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontName nil, nil, startingContent.georgiaFontStack
    startingContent.setFontSize 48
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "Section X",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.setFontSize 28
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "Section X.X",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.setFontSize 24
    sdspw.add startingContent

    sdspw.addNormalParagraph "Normal text."

    startingContent = new SimplePlainTextWdgt(
      "“Be careful--with quotations, you can damn anything.”\n― André Malraux",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleItalic()
    startingContent.alignRight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent


    sdspw.addIndentedText "indentedText"
    sdspw.addBulletPoint "bullet point"
    sdspw.addCodeBlock "a code block with\n  some example\n    code in here"


    startingContent = new SimplePlainTextWdgt(
      "Spacers:",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addSpacer()
    sdspw.addSpacer 2
    sdspw.addSpacer 3

    startingContent = new SimplePlainTextWdgt(
      "Divider line:",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()

    startingContent = new SimplePlainTextWdgt(
      "Links:",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    startingContent = new SimpleLinkWdgt()
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    startingContent = new SimpleVideoLinkWdgt()
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    startingContent = new SimplePlainTextWdgt(
      "Useful characters:",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent
    # in March 2018, greek chars take a long time to paint on OSX/Chrome so
    # not adding those to the paragraph, however here they are:
    # αβγδεζηθικλμνξοπρστυφχψω ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ
    specialCharsParagraph = sdspw.addNormalParagraph "… †‡§ ↵⏎⇧␣ ☐☑☒✓X✗ •‣⁃◦ °±⁻¹²³µ×÷ℓΩ√∛∜∝∞∟∠∡∩∪∿≈⊂⋅⌀▫◽◻□⩽⩾ ¼½¾⅛⅜⅝⅞ ←↑→↓↔↕↵⇎⇏⇑⇒⇓⇔⇕ ©®™ $£€¥"
    specialCharsParagraph.setFontSize 16


    sdspw.makeAllContentIntoTemplates()

    wm = new WindowWdgt nil, nil, sdspw
    wm.setExtent new Point 365, 335
    wm.setTitleWithoutPrependedContentName "useful snippets"
    wm.changed()
    return wm


  createFanout: ->
    fanoutWdgt = new FanoutWdgt()
    world.create fanoutWdgt
    fanoutWdgt.setExtent new Point 100, 100

  createCalculatingPatchNode: ->
    calculatingPatchNodeWdgt = new CalculatingPatchNodeWdgt()
    wm = new WindowWdgt nil, nil, calculatingPatchNodeWdgt, true
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm
    wm.changed()

  createDiffingPatchNode: ->
    diffingPatchNodeWdgt = new DiffingPatchNodeWdgt()
    wm = new WindowWdgt nil, nil, diffingPatchNodeWdgt, true
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm
    wm.changed()

  createSliderWithSmallestValueAtBottomEnd: ->
    debugger
    world.create new SliderMorph nil, nil, nil, nil, nil, true

  createRegexSubstitutionPatchNodeWdgt: ->
    regexSubstitutionPatchNodeWdgt = new RegexSubstitutionPatchNodeWdgt()
    wm = new WindowWdgt nil, nil, regexSubstitutionPatchNodeWdgt, true
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm
    wm.changed()

  throwAnError: ->
    throw new Error "you manually threw an error!"

  createStretchablePanel: ->
    stretchablePanel = new StretchableWidgetContainerWdgt()
    world.create stretchablePanel
    stretchablePanel.setExtent new Point 400, 300

  createToolsPanel: ->
    toolPanel = new ScrollPanelWdgt new ToolPanelWdgt()
    wm = new WindowWdgt nil, nil, toolPanel, true
    wm.setExtent new Point 200, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm
    wm.changed()

  createHorizontalMenuPanelPanel: ->
    horizontalMenuPanel = new HorizontalMenuPanelWdgt()
    wm = new WindowWdgt nil, nil, horizontalMenuPanel, true
    wm.setExtent new Point 200, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm
    wm.changed()

  popUpMore1IconsMenu: (morphOpeningThePopUp) ->
    menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "More Icons 1"
    menu.addMenuItem "Pencil 1 icon", true, menusHelper, "createPencil1IconMorph"
    menu.addMenuItem "Pencil 2 icon", true, menusHelper, "createPencil2IconMorph"
    menu.addMenuItem "Brush icon", true, menusHelper, "createBrushIconMorph"
    menu.addMenuItem "Toothpaste icon", true, menusHelper, "createToothpasteIconMorph"
    menu.addMenuItem "Eraser icon", true, menusHelper, "createEraserIconMorph"
    menu.addMenuItem "Trashcan icon", true, menusHelper, "createTrashcanIconWdgt"
    menu.addMenuItem "Shortcut arrow icon", true, menusHelper, "createShortcutArrowIconWdgt"
    menu.addMenuItem "Raster pic icon", true, menusHelper, "createRasterPicIconWdgt"
    menu.addMenuItem "Paint bucket icon", true, menusHelper, "createPaintBucketIconWdgt"
    menu.addMenuItem "Object icon", true, menusHelper, "createObjectIconWdgt"
    menu.addMenuItem "Folder icon", true, menusHelper, "createFolderIconWdgt"
    menu.addMenuItem "Basement icon", true, menusHelper, "createBasementIconWdgt"
    menu.addMenuItem "Widget icon", true, menusHelper, "createWidgetIconWdgt"
    menu.popUpAtHand()

  popUpMore2IconsMenu: (morphOpeningThePopUp) ->
    menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "More Icons 2"
    menu.addMenuItem "Format as code icon", true, menusHelper, "createFormatAsCodeIconWdgt"
    menu.addMenuItem "Ch. X icon", true, menusHelper, "createChXIconWdgt"
    menu.addMenuItem "Ch. X.X icon", true, menusHelper, "createChXXIconWdgt"
    menu.addMenuItem "Ch. X.X.X icon", true, menusHelper, "createChXXXIconWdgt"
    menu.addMenuItem "Align right icon", true, menusHelper, "createAlignRightIconWdgt"
    menu.addMenuItem "Align center icon", true, menusHelper, "createAlignCenterIconWdgt"
    menu.addMenuItem "Align left icon", true, menusHelper, "createAlignLeftIconWdgt"
    menu.addMenuItem "Bold icon", true, menusHelper, "createBoldIconWdgt"
    menu.addMenuItem "Italic icon", true, menusHelper, "createItalicIconWdgt"
    menu.addMenuItem "Information icon", true, menusHelper, "createInformationIconWdgt"
    menu.addMenuItem "Textbox icon", true, menusHelper, "createTextboxIconWdgt"
    menu.addMenuItem "Video play icon", true, menusHelper, "createVideoPlayIconWdgt"

    menu.addMenuItem "Decrease font size icon", true, menusHelper, "createDecreaseFontSizeIconWdgt"
    menu.addMenuItem "Increase font size icon", true, menusHelper, "createIncreaseFontSizeIconWdgt"
    menu.addMenuItem "External link icon", true, menusHelper, "createExternalLinkIconWdgt"
    menu.addMenuItem "Templates icon", true, menusHelper, "createTemplatesIconWdgt"

    menu.popUpAtHand()

  popUpMore3IconsMenu: (morphOpeningThePopUp) ->
    menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "More Icons 2"
    menu.addMenuItem "Fizzygum logo", true, menusHelper, "createFizzygumLogoIconWdgt"
    menu.addMenuItem "Fizzygum logo with text", true, menusHelper, "createFizzygumLogoWithTextIconWdgt"
    menu.addMenuItem "Vaporwave sun", true, menusHelper, "createVaporwaveSunIconWdgt"
    menu.addMenuItem "Vaporwave background", true, menusHelper, "createVaporwaveBackgroundIconWdgt"
    menu.addMenuItem "Change font icon", true, menusHelper, "createChangeFontIconWdgt"
    menu.addMenuItem "C <-> F converter icon", true, menusHelper, "createCFDegreesConverterIconWdgt"
    menu.addMenuItem "Simple slide icon", true, menusHelper, "createSimpleSlideIconWdgt"
    menu.addMenuItem "Typewriter icon", true, menusHelper, "createTypewriterIconWdgt"
    menu.addMenuItem "Little world icon", true, menusHelper, "createLittleWorldIconWdgt"
    menu.addMenuItem "Little USA icon", true, menusHelper, "createLittleUSAIconWdgt"
    menu.addMenuItem "Map pin icon", true, menusHelper, "createMapPinIconWdgt"
    menu.addMenuItem "Save icon", true, menusHelper, "createSaveIconWdgt"

    menu.popUpAtHand()

  createFizzygumLogoWithTextIconWdgt : ->
    world.create new FizzygumLogoWithTextIconWdgt()

  createVaporwaveBackgroundIconWdgt : ->
    world.create new VaporwaveBackgroundIconWdgt()

  createCFDegreesConverterIconWdgt : ->
    world.create new CFDegreesConverterIconWdgt()

  createFizzygumLogoIconWdgt : ->
    world.create new FizzygumLogoIconWdgt()

  createVaporwaveSunIconWdgt : ->
    world.create new VaporwaveSunIconWdgt()

  createLittleWorldIconWdgt : ->
    world.create new LittleWorldIconWdgt()

  createChangeFontIconWdgt : ->
    world.create new ChangeFontIconWdgt()

  createSimpleSlideIconWdgt : ->
    world.create new SimpleSlideIconWdgt()

  createTypewriterIconWdgt : ->
    world.create new TypewriterIconWdgt()

  createLittleUSAIconWdgt : ->
    world.create new LittleUSAIconWdgt()

  createMapPinIconWdgt : ->
    world.create new MapPinIconWdgt()

  createSaveIconWdgt : ->
    world.create new SaveIconWdgt()


  popUpArrowsIconsMenu: (morphOpeningThePopUp) ->
    menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "Arrows"
    menu.addMenuItem "Arrow N icon", true, menusHelper, "createArrowNIconWdgt"
    menu.addMenuItem "Arrow S icon", true, menusHelper, "createArrowSIconWdgt"
    menu.addMenuItem "Arrow W icon", true, menusHelper, "createArrowWIconWdgt"
    menu.addMenuItem "Arrow E icon", true, menusHelper, "createArrowEIconWdgt"
    menu.addMenuItem "Arrow NW icon", true, menusHelper, "createArrowNWIconWdgt"
    menu.addMenuItem "Arrow NE icon", true, menusHelper, "createArrowNEIconWdgt"
    menu.addMenuItem "Arrow SE icon", true, menusHelper, "createArrowSEIconWdgt"
    menu.addMenuItem "Arrow SW icon", true, menusHelper, "createArrowSWIconWdgt"
    menu.popUpAtHand()

  createArrowEIconWdgt: ->
    world.create new ArrowEIconWdgt()

  createArrowNEIconWdgt: ->
    world.create new ArrowNEIconWdgt()

  createArrowNIconWdgt: ->
    world.create new ArrowNIconWdgt()

  createArrowNWIconWdgt: ->
    world.create new ArrowNWIconWdgt()

  createArrowSEIconWdgt: ->
    world.create new ArrowSEIconWdgt()

  createArrowSIconWdgt: ->
    world.create new ArrowSIconWdgt()

  createArrowSWIconWdgt: ->
    world.create new ArrowSWIconWdgt()

  createArrowWIconWdgt: ->
    world.create new ArrowWIconWdgt()

  createDecreaseFontSizeIconWdgt: ->
    world.create new DecreaseFontSizeIconWdgt()

  createExternalLinkIconWdgt: ->
    world.create new ExternalLinkIconWdgt()

  createIncreaseFontSizeIconWdgt: ->
    world.create new IncreaseFontSizeIconWdgt()

  createTemplatesIconWdgt: ->
    world.create new TemplatesIconWdgt()

  createFormatAsCodeIconWdgt: ->
    world.create new FormatAsCodeIconWdgt()

  createChXIconWdgt: ->
    world.create new ChapterXIconWdgt()

  createChXXIconWdgt: ->
    world.create new ChapterXXIconWdgt()

  createChXXXIconWdgt: ->
    world.create new ChapterXXXIconWdgt()

  createAlignRightIconWdgt: ->
    world.create new AlignRightIconWdgt()

  createAlignCenterIconWdgt: ->
    world.create new AlignCenterIconWdgt()

  createAlignLeftIconWdgt: ->
    world.create new AlignLeftIconWdgt()

  createWorldMapIconMorph: ->
    world.create new SimpleWorldMapIconWdgt()

  createUSAMapIconMorph: ->
    world.create new SimpleUSAMapIconWdgt()

  createBoldIconWdgt: ->
    world.create new BoldIconWdgt()

  createItalicIconWdgt: ->
    world.create new ItalicIconWdgt()

  createInformationIconWdgt: ->
    world.create new InformationIconWdgt()

  createTextboxIconWdgt: ->
    world.create new TextIconWdgt()

  createVideoPlayIconWdgt: ->
    world.create new VideoPlayIconWdgt()

  createSimpleDocumentWdgt: ->
    simpleDocument = new SimpleDocumentWdgt()
    wm = new WindowWdgt nil, nil, simpleDocument
    wm.setExtent new Point 368, 335
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm
    wm.changed()

  createSimpleLinkWdgt: ->
    simpleLinkWdgt = new SimpleLinkWdgt()
    simpleLinkWdgt.setExtent new Point 405, 50
    world.create simpleLinkWdgt

  createSimpleVideoLinkWdgt: ->
    simpleVideoLinkWdgt = new SimpleVideoLinkWdgt()
    simpleVideoLinkWdgt.setExtent new Point 405, 50
    world.create simpleVideoLinkWdgt

  create2DAxis: ->
    vertAxis = new AxisWdgt()
    vertAxis.setExtent new Point 40, 300
    world.create vertAxis

  createExampleScatterPlot: ->
    exampleScatterPlot = new ExampleScatterPlotWdgt()
    exampleScatterPlot.setExtent new Point 300, 300
    world.create exampleScatterPlot

  createExampleScatterPlotWithAxes: ->
    exampleScatterPlot = new ExampleScatterPlotWdgt()
    plotWithAxesWdgt = new PlotWithAxesWdgt exampleScatterPlot
    plotWithAxesWdgt.rawSetExtent new Point 300, 300
    world.create plotWithAxesWdgt

  createExampleFunctionPlot: ->
    exampleFunctionPlot = new ExampleFunctionPlotWdgt()
    exampleFunctionPlot.setExtent new Point 300, 300
    world.create exampleFunctionPlot
  
  createExampleBarPlot: ->
    exampleBarPlot = new ExampleBarPlotWdgt()
    exampleBarPlot.setExtent new Point 300, 300
    world.create exampleBarPlot

  createExample3DPlot: ->
    example3DPlot = new Example3DPlotWdgt()
    example3DPlot.setExtent new Point 300, 300
    world.create example3DPlot

  popUpMapsMenu: (morphOpeningThePopUp) ->
    menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "Maps"
    menu.addMenuItem "world map", true, menusHelper, "createWorldMapIconMorph", "others"
    menu.addMenuItem "USA map", true, menusHelper, "createUSAMapIconMorph", "others"

    menu.popUpAtHand()

  popUpGraphsMenu: (morphOpeningThePopUp) ->
    menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "graphs"
    menu.addMenuItem "axis", true, menusHelper, "create2DAxis"
    menu.addMenuItem "scatter plot", true, menusHelper, "createExampleScatterPlot"
    menu.addMenuItem "scatter plot with axes", true, menusHelper, "createExampleScatterPlotWithAxes"
    menu.addMenuItem "function plot", true, menusHelper, "createExampleFunctionPlot"
    menu.addMenuItem "bar plot", true, menusHelper, "createExampleBarPlot"
    menu.addMenuItem "3D plot", true, menusHelper, "createExample3DPlot"

    menu.popUpAtHand()

  popUpSupportDocsMenu: (morphOpeningThePopUp) ->
    menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "Support Docs"
    menu.addMenuItem "welcome message", true, @, "createWelcomeMessageWindowAndShortcut", "welcome message"

    menu.popUpAtHand()

  createWelcomeMessageWindowAndShortcut: ->
    simpleDocument = new SimpleDocumentWdgt()
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new FizzygumLogoIconWdgt()
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()


    startingContent = new SimplePlainTextWdgt(
      "Welcome to Fizzygum",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 24
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "version 1.0.0",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 9
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()


    sdspw.addNormalParagraph "Welcome to a powerful new framework designed from the ground up to do complex things, simply. Welcome to Fizzygum."

    sdspw.addSpacer()

    startingContent = new SimplePlainTextWdgt(
      "What it can do for you",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "Fizzygum enables you to do all of this and more:"

    sdspw.addBulletPoint "make dashboards and visualise data (plots, maps, ...)"
    sdspw.addBulletPoint "author, organise and navigate documents (drawings / text docs / slides)"
    sdspw.addBulletPoint "embed live graphs, dynamic calculations or even entire running programs inside any document, via simple drag & drop"
    sdspw.addBulletPoint "go beyond traditional embedding: you can now infinitely nest and compose programs and documents. Need a program inside a presentation inside a text? You have it"
    sdspw.addBulletPoint "make custom utilities (e.g. temperature converter) by simply connecting existing components - no coding required"
    sdspw.addBulletPoint "use the internal development tools to create entirely new apps, or change existing ones while they are running. Add custom features without even needing to refresh the page."
    sdspw.addBulletPoint "do all of the above, concurrently"

    sdspw.addSpacer()

    startingContent = new SimplePlainTextWdgt(
      "New here?",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "Feel free to click around this sandbox. Just reload to start again from scratch."

    sdspw.addSpacer()
    sdspw.addNormalParagraph "Also check out some screenshots here:"

    startingContent = new SimpleLinkWdgt "screenshots"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addNormalParagraph "...or watch some quick demos on the Youtube channel:"

    startingContent = new SimpleVideoLinkWdgt "YouTube channel"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addNormalParagraph "...or docs here:"

    startingContent = new SimpleLinkWdgt "docs"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addSpacer(2)

    startingContent = new SimplePlainTextWdgt(
      "Get in touch",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "Mail? Mailing list? Facebook page? Twitter? Chat? We have it all."

    startingContent = new SimpleLinkWdgt "contacts"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Welcome"
    wm.changed()

    simpleDocument.disableDragsDropsAndEditing()

    readmeLauncher = new IconicDesktopSystemDocumentShortcutWdgt wm, "Welcome", new WelcomeIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add readmeLauncher
    readmeLauncher.setExtent new Point 75, 75
    readmeLauncher.fullChanged()

  createDegreesConverterOpener: (inWhichFolder) ->
    scriptWdgt = new ScriptWdgt """

     menusHelper.createDegreesConverterWindowOrBringItUpIfAlreadyCreated()


    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    wm.changed()

    degreesConverterOpenerLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "°C ↔ °F", new DegreesConverterIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    
    degreesConverterOpenerLauncher.setExtent new Point 75, 75
    if inWhichFolder?
      inWhichFolder.contents.contents.add degreesConverterOpenerLauncher
    else
      world.add degreesConverterOpenerLauncher
    return wm


  createDegreesConverterWindowOrBringItUpIfAlreadyCreated: ->
    if world.degreesConverterWindow?
      if !world.degreesConverterWindow.destroyed and world.degreesConverterWindow.parent?
        world.add world.degreesConverterWindow
        world.degreesConverterWindow.bringToForeground()
        world.degreesConverterWindow.fullRawMoveTo world.hand.position().add new Point 100, -50
        world.degreesConverterWindow.fullRawMoveWithin world
        return

    xCorrection = 32
    yCorrection = 50
    patchProgrammingWdgt = new PatchProgrammingWdgt()

    container = patchProgrammingWdgt.stretchableWidgetContainer.contents
    container.rawSetExtent new Point 584,552

    slider1 = new SliderMorph nil, nil, nil, nil, nil, true
    slider1.fullRawMoveTo container.position().add new Point 43+xCorrection, 195+yCorrection
    slider1.rawSetExtent new Point 20, 100
    container.add slider1
    slider1.rememberFractionalSituationInHoldingPanel()

    slider2 = new SliderMorph nil, nil, nil, nil, nil, true
    slider2.fullRawMoveTo container.position().add new Point 472+xCorrection, 203+yCorrection
    slider2.rawSetExtent new Point 20, 100
    container.add slider2
    slider2.rememberFractionalSituationInHoldingPanel()

    cText = new TextMorph2 "0"
    cText.fullRawMoveTo container.position().add new Point 104, 253
    cText.rawSetExtent new Point 150, 75
    container.add cText
    cText.rememberFractionalSituationInHoldingPanel()

    fText = new TextMorph2 "0"
    fText.fullRawMoveTo container.position().add new Point 344, 255
    fText.alignRight()
    fText.rawSetExtent new Point 150, 75
    container.add fText
    fText.rememberFractionalSituationInHoldingPanel()

    calc1 = new WindowWdgt nil, nil, new CalculatingPatchNodeWdgt("# °C → °F formula\n(in1)->Math.round in1*9/5+32"), true
    calc1.fullRawMoveTo container.position().add new Point 148+xCorrection/2, 19
    calc1.rawSetExtent new Point 241, 167
    container.add calc1
    calc1.rememberFractionalSituationInHoldingPanel()

    calc2 = new WindowWdgt nil, nil, new CalculatingPatchNodeWdgt("# °F → °C formula\n(in1)->Math.round (in1-32)*5/9"), true
    calc2.fullRawMoveTo container.position().add new Point 148+xCorrection/2, 365
    calc2.rawSetExtent new Point 241, 167
    container.add calc2
    calc2.rememberFractionalSituationInHoldingPanel()


    slider1.setTargetAndActionWithOnesPickedFromMenu nil, nil, cText, "setText"
    cText.setTargetAndActionWithOnesPickedFromMenu nil, nil, calc1.contents, "setInput1"
    calc1.contents.setTargetAndActionWithOnesPickedFromMenu nil, nil, fText, "setText"
    fText.setTargetAndActionWithOnesPickedFromMenu nil, nil, slider2, "setValue"
    slider2.setTargetAndActionWithOnesPickedFromMenu nil, nil, calc2.contents, "setInput1"
    calc2.contents.setTargetAndActionWithOnesPickedFromMenu nil, nil, slider1, "setValue"



    cLabel = new TextMorph2 "°C"
    cLabel.fullRawMoveTo container.position().add new Point 0+xCorrection, 102+yCorrection
    cLabel.rawSetExtent new Point 90, 90
    container.add cLabel
    cLabel.rememberFractionalSituationInHoldingPanel()

    fLabel = new TextMorph2 "°F"
    fLabel.fullRawMoveTo container.position().add new Point 422+xCorrection, 102+yCorrection
    fLabel.rawSetExtent new Point 90, 90
    container.add fLabel
    fLabel.rememberFractionalSituationInHoldingPanel()

    #@inform (@position().subtract @parent.position()) + " " +  @extent()

    wm = new WindowWdgt nil, nil, patchProgrammingWdgt
    wm.fullRawMoveTo new Point 114, 10
    wm.rawSetExtent new Point 596, 592
    world.add wm
    wm.setTitleWithoutPrependedContentName "°C ↔ °F converter"
    wm.changed()


    patchProgrammingWdgt.disableDragsDropsAndEditing()
    
    cText.isEditable = true
    fText.isEditable = true

    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    patchProgrammingWdgt.closeFromContainerWindow = (containerWindow) ->
      containerWindow.close()

    world.degreesConverterWindow = wm

  createHowToSaveMessageOpener: ->
    scriptWdgt = new ScriptWdgt """

     menusHelper.createHowToSaveMessageWindowOrBringItUpIfAlreadyCreated()


    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    wm.changed()

    toolbarsOpenerLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "How to save?", new FloppyDiskIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add toolbarsOpenerLauncher
    toolbarsOpenerLauncher.setExtent new Point 75, 75
    toolbarsOpenerLauncher.fullChanged()
    return wm


  createHowToSaveMessageWindowOrBringItUpIfAlreadyCreated: ->
    if world.howToSaveDocWindow?
      if !world.howToSaveDocWindow.destroyed and world.howToSaveDocWindow.parent?
        world.add world.howToSaveDocWindow
        world.howToSaveDocWindow.bringToForeground()
        world.howToSaveDocWindow.fullRawMoveTo world.hand.position().add new Point 100, -50
        world.howToSaveDocWindow.fullRawMoveWithin world
        return

    simpleDocument = new SimpleDocumentWdgt()
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new FloppyDiskIconWdgt()
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "How to save?",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 24
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent


    sdspw.addDivider()


    sdspw.addNormalParagraph "There are a couple of ways to save data in Fizzygum.¹\n\nHowever, \"in-house\" stable saving solutions are only available in internal versions.²\n\nIn the meantime that these solutions make their way into the public version, the Fizzygum team can consult for you to tailor 'saving' functionality to your needs (save to file, save to cloud, connect to databases etc. ).\n\nPlease enquiry via one of the Fizzygum contacts here:"

    sdspw.addSpacer()

    startingContent = new SimpleLinkWdgt "contacts"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addSpacer()

    startingContent = new SimplePlainTextWdgt(
      "Footnotes",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.toggleHeaderLine()
    sdspw.add startingContent

    sdspw.addSpacer()

    sdspw.addNormalParagraph "¹ Saving solutions:\n"+
     "1) saving data with existing formats (e.g. markdown etc.). Advantages: compatibility. Disadvantages: works only with \"plain\" documents (no live documents, no documents within documents etc.)\n"+
     "2) serialising objects graph. Advantages: fidelity. Disadvantages: needs some management of versioning of Fizzygum platform and documents\n"+
     "3) deducing source code to generate content. Advantages: compactness, inspectability of source code, high-level semantics of source code preserved. Disadvantages: only possible with relatively simple objects.\n"+
     "\n"+
     "² Why private beta:\n"+
     "Proliferation of saving solutions done without our help could be detrimental to the Fizzygum platform (due to degraded experience on third party sites, incompatibilities between sites, migration issues, security issues, etc.), hence the Fizzygum team decided to withhold this functionality from public until we can package an open turn-key solution that minimises misuse and sub-par experiences."


    wm = new WindowWdgt nil, nil, simpleDocument
    wm.fullRawMoveTo new Point 114, 10
    wm.rawSetExtent new Point 365, 447
    world.add wm
    wm.setTitleWithoutPrependedContentName "How to save?"
    wm.changed()

    simpleDocument.disableDragsDropsAndEditing()

    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.close()


    world.howToSaveDocWindow = wm

