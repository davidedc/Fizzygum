# All "actions" functions for all accessory menu items should belong
# in here. Also helps so we don't pollute moprhs with a varying number
# of helper functions, which is problematic for visual diffing
# on inspectors (the number of methods keeps changing).

class MenusHelper

  @augmentWith DeepCopierMixin

  popUpDevToolsMenu: (morphOpeningThePopUp, widgetThisMenuIsAbout) ->
    menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "Dev Tools"
    menu.addMenuItem "inspect", true, widgetThisMenuIsAbout, "inspect2", "open a window\non all properties"
    menu.addMenuItem "console", true, widgetThisMenuIsAbout, "createConsole", "console"

    menu.popUpAtHand()


  # »>> this part is excluded from the fizzygum homepage build
  createFridgeMagnets: ->
    fmm = new FridgeMagnetsMorph
    wm = new WindowWdgt nil, nil, fmm
    wm.setExtent new Point 570, 400
    wm.fullRawMoveTo world.hand.position()
    wm.fullRawMoveWithin world
    world.add wm


  createReconfigurablePaint: ->
    reconfPaint = new ReconfigurablePaintWdgt
    wm = new WindowWdgt nil, nil, reconfPaint
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position()
    wm.fullRawMoveWithin world
    world.add wm

  createSimpleSlideWdgt: ->
    simpleSlide = new SimpleSlideWdgt
    wm = new WindowWdgt nil, nil, simpleSlide
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position()
    wm.fullRawMoveWithin world
    world.add wm

  createSimpleButton: ->
    world.create new SimpleRectangularButtonMorph true, @, nil, new IconMorph(nil)

  createSwitchButtonMorph: ->
    button1 = new SimpleRectangularButtonMorph true, @, nil, new IconMorph(nil)
    button2 = new SimpleRectangularButtonMorph true, @, nil, new StringMorph2 "Hello World! ⎲ƒ⎳⎷ ⎸⎹ "
    world.create new SwitchButtonMorph [button1, button2]

  createNewClippingBoxMorph: ->
    world.create new ClippingBoxMorph

  makeSlidersButtonsStatesBright: ->
    world.forAllChildrenBottomToTop (child) ->
      if child instanceof SliderButtonMorph
       child.pressColor = Color.LIME
       child.highlightColor = Color.BLUE
       child.normalColor = Color.BLACK

  # Icons --------------------------------------------------------------

  makeIconWithText: ->
    world.create new WidgetHolderWithCaptionWdgt "hey there", new BrushIconMorph

  makeEmptyIconWithText: ->
    world.create new WidgetHolderWithCaptionWdgt "hey there"

  makeFolderWindow: (a,b,c,d,e) ->
    world.create new FolderWindowWdgt nil,nil,nil,nil, @

  makeBouncingParticle: ->
    world.create new BouncerWdgt

  createDestroyIconMorph: ->
    world.create new DestroyIconMorph

  createUnderCarpetIconMorph: ->
    world.create new UnderCarpetIconMorph

  createUncollapsedStateIconMorph: ->
    world.create new UncollapsedStateIconMorph

  createCollapsedStateIconMorph: ->
    world.create new CollapsedStateIconMorph

  createCloseIconButtonMorph: ->
    world.create new CloseIconButtonMorph

  createScratchAreaIconMorph: ->
    world.create new ScratchAreaIconMorph

  createFloraIconMorph: ->
    world.create new FloraIconMorph

  createScooterIconMorph: ->
    world.create new ScooterIconMorph

  createHeartIconMorph: ->
    world.create new HeartIconMorph


  createPencil1IconMorph: ->
    world.create new PencilIconMorph

  createPencil2IconMorph: ->
    world.create new Pencil2IconMorph

  createBrushIconMorph: ->
    world.create new BrushIconMorph

  createToothpasteIconMorph: ->
    world.create new ToothpasteIconMorph

  createEraserIconMorph: ->
    world.create new EraserIconMorph


  createTrashcanIconWdgt: ->
    world.create new TrashcanIconWdgt

  createShortcutArrowIconWdgt: ->
    world.create new ShortcutArrowIconWdgt

  createRasterPicIconWdgt: ->
    world.create new RasterPicIconWdgt

  createPaintBucketIconWdgt: ->
    world.create new PaintBucketIconWdgt

  createObjectIconWdgt: ->
    world.create new ObjectIconWdgt

  createFolderIconWdgt: ->
    world.create new FolderIconWdgt

  createBasementIconWdgt: ->
    world.create new BasementIconWdgt

  createWidgetIconWdgt: ->
    world.create new WidgetIconWdgt

  makeGenericReferenceIcon: ->
    world.create new GenericShortcutIconWdgt

  makeGenericObjectIcon: ->
    world.create new GenericObjectIconWdgt

  # this part is excluded from the fizzygum homepage build <<«


  basementIconAndText: ->
    world.add new BasementOpenerWdgt

  # »>> this part is excluded from the fizzygum homepage build
  newScriptWindow: ->
    scriptWdgt = new ScriptWdgt
    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm
  # this part is excluded from the fizzygum homepage build <<«

  # ------------------------------------------------------------------------

  launchFizzyPaint: ->
    wm = new WindowWdgt nil, nil, new ReconfigurablePaintWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo new Point 174, 114
    wm.fullRawMoveWithin world
    world.add wm

    ReconfigurablePaintInfoWdgt.createNextTo wm

  createFizzyPaintLauncher: ->
    fizzyPaintLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "Draw", new PaintBucketIconWdgt, @, "launchFizzyPaint"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add fizzyPaintLauncher
    fizzyPaintLauncher.setExtent new Point 75, 75
    fizzyPaintLauncher.fullChanged()

  # ------------------------------------------------------------------------

  launchSimpleDocument: ->
    wm = new WindowWdgt nil, nil, new SimpleDocumentWdgt
    wm.setExtent new Point 370, 395
    wm.fullRawMoveTo new Point 170, 88
    wm.fullRawMoveWithin world
    world.add wm

    SimpleDocumentInfoWdgt.createNextTo wm


  createSimpleDocumentLauncher: ->
    simpleDocumentLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "Docs Maker", new TypewriterIconWdgt, @, "launchSimpleDocument"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add simpleDocumentLauncher
    simpleDocumentLauncher.setExtent new Point 75, 75
    simpleDocumentLauncher.fullChanged()

  # ------------------------------------------------------------------------

  createSimpleSlideLauncher: ->
    scriptWdgt = new ScriptWdgt """
      reconfPaint = new SimpleSlideWdgt
      wm = new WindowWdgt nil, nil, reconfPaint
      wm.setExtent new Point 460, 400
      wm.fullRawMoveTo new Point 168, 134
      wm.fullRawMoveWithin world
      world.add wm
 
      menusHelper.createSlidesMakerOneOffInfoWindowNextTo wm

    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world

    simpleSlideLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Slides Maker", new SimpleSlideIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add simpleSlideLauncher
    simpleSlideLauncher.setExtent new Point 75, 75
    simpleSlideLauncher.fullChanged()
    return wm

  # »>> this part is excluded from the fizzygum homepage build
  createSimpleSlideLauncherAndItsIcon: ->
    wm = @createSimpleSlideLauncher()
    world.add wm
  # this part is excluded from the fizzygum homepage build <<«

  createDashboardsLauncher: ->
    scriptWdgt = new ScriptWdgt """
      reconfPaint = new DashboardsWdgt
      wm = new WindowWdgt nil, nil, reconfPaint
      wm.setExtent new Point 460, 400
      wm.fullRawMoveTo world.hand.position()
      wm.fullRawMoveWithin world
      world.add wm

      menusHelper.createDashboardsMakerOneOffInfoWindowNextTo wm
    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world

    simpleDashboardsLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Dashboards", new DashboardsIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add simpleDashboardsLauncher
    simpleDashboardsLauncher.setExtent new Point 75, 75
    simpleDashboardsLauncher.fullChanged()
    return wm


  createPatchProgrammingLauncher: ->
    scriptWdgt = new ScriptWdgt """
      patchProgramming = new PatchProgrammingWdgt
      wm = new WindowWdgt nil, nil, patchProgramming
      wm.setExtent new Point 460, 400
      wm.fullRawMoveTo world.hand.position()
      wm.fullRawMoveWithin world
      world.add wm
      
      menusHelper.createPatchProgrammingOneOffInfoWindowNextTo wm
    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world

    patchProgrammingLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Patch progr.", new PatchProgrammingIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add patchProgrammingLauncher
    patchProgrammingLauncher.setExtent new Point 75, 75
    patchProgrammingLauncher.fullChanged()
    return wm

  createGenericPanelLauncher: ->
    scriptWdgt = new ScriptWdgt """
      genericPanel = new StretchableEditableWdgt
      wm = new WindowWdgt nil, nil, genericPanel
      wm.setExtent new Point 460, 400
      wm.fullRawMoveTo world.hand.position()
      wm.fullRawMoveWithin world
      world.add wm

      menusHelper.createGenericPanelOneOffInfoWindowNextTo wm
    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world

    genericPanelLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Generic panel", new GenericPanelIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add genericPanelLauncher
    genericPanelLauncher.setExtent new Point 75, 75
    genericPanelLauncher.fullChanged()
    return wm

  createToolbarsOpener: ->
    scriptWdgt = new ScriptWdgt """

      # tools -------------------------------
      toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt

      toolsPanel.addMany [
        new TextToolbarCreatorButtonWdgt
        new UsefulTextSnippetsToolbarCreatorButtonWdgt
        new SlidesToolbarCreatorButtonWdgt
        new PlotsToolbarCreatorButtonWdgt
        new PatchProgrammingComponentsToolbarCreatorButtonWdgt
        new WindowsToolbarCreatorButtonWdgt
      ]

      toolsPanel.disableDragsDropsAndEditing()

      wm = new WindowWdgt nil, nil, toolsPanel
      wm.setExtent new Point 60, 261
      wm.fullRawMoveTo new Point 170, 170
      wm.fullRawMoveWithin world
      world.add wm

      menusHelper.createSuperToolbarOneOffInfoWindowNextTo wm

    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world

    toolbarsOpenerLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Super Toolbar", new ToolbarsIconWdgt
    toolbarsOpenerLauncher.toolTipMessage = "a toolbar to rule them all"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add toolbarsOpenerLauncher
    toolbarsOpenerLauncher.setExtent new Point 75, 75
    toolbarsOpenerLauncher.fullChanged()
    return wm

  createNewTemplatesWindow: ->
    sdspw = new SimpleDocumentScrollPanelWdgt

    sdspw.rawSetExtent new Point 365, 335

    startingContent = new SimplePlainTextWdgt(
      "Simply drag the items below into your document",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 18
    startingContent.isEditable = true
    startingContent.enableSelecting()

    sdspw.setContents startingContent, 5


    startingContent = new ArrowSIconWdgt
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

    startingContent = new SimpleLinkWdgt
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    startingContent = new SimpleVideoLinkWdgt
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
    wm.setExtent new Point 370, 335
    wm.setTitleWithoutPrependedContentName "useful snippets"

    return wm


  # »>> this part is excluded from the fizzygum homepage build
  createFanout: ->
    fanoutWdgt = new FanoutWdgt
    world.create fanoutWdgt
    fanoutWdgt.setExtent new Point 100, 100

  createCalculatingPatchNode: ->
    calculatingPatchNodeWdgt = new CalculatingPatchNodeWdgt
    wm = new WindowWdgt nil, nil, calculatingPatchNodeWdgt, true
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm

  createDiffingPatchNode: ->
    diffingPatchNodeWdgt = new DiffingPatchNodeWdgt
    wm = new WindowWdgt nil, nil, diffingPatchNodeWdgt, true
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm

  createSliderWithSmallestValueAtBottomEnd: ->
    world.create new SliderMorph nil, nil, nil, nil, nil, true

  createRegexSubstitutionPatchNodeWdgt: ->
    regexSubstitutionPatchNodeWdgt = new RegexSubstitutionPatchNodeWdgt
    wm = new WindowWdgt nil, nil, regexSubstitutionPatchNodeWdgt, true
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm

  throwAnError: ->
    throw new Error "you manually threw an error!"

  createStretchablePanel: ->
    stretchablePanel = new StretchableWidgetContainerWdgt
    world.create stretchablePanel
    stretchablePanel.setExtent new Point 400, 300

  createToolsPanel: ->
    toolPanel = new ScrollPanelWdgt new ToolPanelWdgt
    wm = new WindowWdgt nil, nil, toolPanel, true
    wm.setExtent new Point 200, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm

  createHorizontalMenuPanelPanel: ->
    horizontalMenuPanel = new HorizontalMenuPanelWdgt
    wm = new WindowWdgt nil, nil, horizontalMenuPanel, true
    wm.setExtent new Point 200, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm


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
    world.create new FizzygumLogoWithTextIconWdgt

  createVaporwaveBackgroundIconWdgt : ->
    world.create new VaporwaveBackgroundIconWdgt

  createCFDegreesConverterIconWdgt : ->
    world.create new CFDegreesConverterIconWdgt

  createFizzygumLogoIconWdgt : ->
    world.create new FizzygumLogoIconWdgt

  createVaporwaveSunIconWdgt : ->
    world.create new VaporwaveSunIconWdgt

  createLittleWorldIconWdgt : ->
    world.create new LittleWorldIconWdgt

  createChangeFontIconWdgt : ->
    world.create new ChangeFontIconWdgt

  createSimpleSlideIconWdgt : ->
    world.create new SimpleSlideIconWdgt

  createTypewriterIconWdgt : ->
    world.create new TypewriterIconWdgt

  createLittleUSAIconWdgt : ->
    world.create new LittleUSAIconWdgt

  createMapPinIconWdgt : ->
    world.create new MapPinIconWdgt

  createSaveIconWdgt : ->
    world.create new SaveIconWdgt

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
    world.create new ArrowEIconWdgt

  createArrowNEIconWdgt: ->
    world.create new ArrowNEIconWdgt

  createArrowNIconWdgt: ->
    world.create new ArrowNIconWdgt

  createArrowNWIconWdgt: ->
    world.create new ArrowNWIconWdgt

  createArrowSEIconWdgt: ->
    world.create new ArrowSEIconWdgt

  createArrowSIconWdgt: ->
    world.create new ArrowSIconWdgt

  createArrowSWIconWdgt: ->
    world.create new ArrowSWIconWdgt

  createArrowWIconWdgt: ->
    world.create new ArrowWIconWdgt

  createDecreaseFontSizeIconWdgt: ->
    world.create new DecreaseFontSizeIconWdgt

  createExternalLinkIconWdgt: ->
    world.create new ExternalLinkIconWdgt

  createIncreaseFontSizeIconWdgt: ->
    world.create new IncreaseFontSizeIconWdgt

  createTemplatesIconWdgt: ->
    world.create new TemplatesIconWdgt

  createFormatAsCodeIconWdgt: ->
    world.create new FormatAsCodeIconWdgt

  createChXIconWdgt: ->
    world.create new ChapterXIconWdgt

  createChXXIconWdgt: ->
    world.create new ChapterXXIconWdgt

  createChXXXIconWdgt: ->
    world.create new ChapterXXXIconWdgt

  createAlignRightIconWdgt: ->
    world.create new AlignRightIconWdgt

  createAlignCenterIconWdgt: ->
    world.create new AlignCenterIconWdgt

  createAlignLeftIconWdgt: ->
    world.create new AlignLeftIconWdgt

  createWorldMapIconMorph: ->
    world.create new SimpleWorldMapIconWdgt

  createUSAMapIconMorph: ->
    world.create new SimpleUSAMapIconWdgt

  createBoldIconWdgt: ->
    world.create new BoldIconWdgt

  createItalicIconWdgt: ->
    world.create new ItalicIconWdgt

  createInformationIconWdgt: ->
    world.create new InformationIconWdgt

  createTextboxIconWdgt: ->
    world.create new TextIconWdgt

  createVideoPlayIconWdgt: ->
    world.create new VideoPlayIconWdgt

  createSimpleDocumentWdgt: ->
    simpleDocument = new SimpleDocumentWdgt
    wm = new WindowWdgt nil, nil, simpleDocument
    wm.setExtent new Point 368, 335
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world
    world.add wm

  createSimpleLinkWdgt: ->
    simpleLinkWdgt = new SimpleLinkWdgt
    simpleLinkWdgt.setExtent new Point 405, 50
    world.create simpleLinkWdgt

  createSimpleVideoLinkWdgt: ->
    simpleVideoLinkWdgt = new SimpleVideoLinkWdgt
    simpleVideoLinkWdgt.setExtent new Point 405, 50
    world.create simpleVideoLinkWdgt

  create2DAxis: ->
    vertAxis = new AxisWdgt
    vertAxis.setExtent new Point 40, 300
    world.create vertAxis

  createExampleScatterPlot: ->
    exampleScatterPlot = new ExampleScatterPlotWdgt
    exampleScatterPlot.setExtent new Point 300, 300
    world.create exampleScatterPlot

  createExampleScatterPlotWithAxes: ->
    exampleScatterPlot = new ExampleScatterPlotWdgt
    plotWithAxesWdgt = new PlotWithAxesWdgt exampleScatterPlot
    plotWithAxesWdgt.rawSetExtent new Point 300, 300
    world.create plotWithAxesWdgt

  createExampleFunctionPlot: ->
    exampleFunctionPlot = new ExampleFunctionPlotWdgt
    exampleFunctionPlot.setExtent new Point 300, 300
    world.create exampleFunctionPlot
  
  createExampleBarPlot: ->
    exampleBarPlot = new ExampleBarPlotWdgt
    exampleBarPlot.setExtent new Point 300, 300
    world.create exampleBarPlot

  createExample3DPlot: ->
    example3DPlot = new Example3DPlotWdgt
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

  # this part is excluded from the fizzygum homepage build <<«

  createWelcomeMessageWindowAndShortcut: ->
    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new FizzygumLogoIconWdgt
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
      "version 1.1.10",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 9
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()


    sdspw.addNormalParagraph "Tired of stringing libraries together?"
    sdspw.addNormalParagraph "Welcome to a powerful new framework designed from the ground up to do complex things, easily."

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

    sdspw.addNormalParagraph "Feel free to click around this sandbox. Double-click the items on the desktop to open them. Just reload to start again from scratch."

    sdspw.addSpacer()
    sdspw.addNormalParagraph "Also check out some screenshots here:"

    startingContent = new SimpleLinkWdgt "Screenshots", "http://fizzygum.org/screenshots/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addNormalParagraph "...or watch some quick demos on the Youtube channel:"

    startingContent = new SimpleVideoLinkWdgt "YouTube channel", "https://www.youtube.com/channel/UCmYco9RU3h9dofRVN3bqxIw"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addNormalParagraph "...or docs here:"

    startingContent = new SimpleLinkWdgt "Docs", "http://fizzygum.org/docs/intro/"
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

    startingContent = new SimpleLinkWdgt "Contacts", "http://fizzygum.org/contact/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Welcome"

    simpleDocument.disableDragsDropsAndEditing()

    readmeLauncher = new IconicDesktopSystemDocumentShortcutWdgt wm, "Welcome", new WelcomeIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add readmeLauncher
    readmeLauncher.setExtent new Point 75, 75
    readmeLauncher.fullChanged()

  createSuperToolbarOneOffInfoWindowNextTo: (nextToThisWidget) ->
    if world.infoDoc_superToolbar_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new ToolbarsIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "Super Toolbar",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "The Super Toolbar can create all other toolbars for you, and from those toolbars you can create any widget.\n\nThis is handy because any widget can go in any document... so here is a way to access them all.\n\nFor an example on how this is useful, see the video on `mixing widgets`:"

    startingContent = new SimpleVideoLinkWdgt "Mixing widgets", "http://fizzygum.org/docs/mixing-widgets/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Super Toolbar info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_superToolbar_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()

  createSlidesMakerOneOffInfoWindowNextTo: (nextToThisWidget) ->
    if world.infoDoc_slidesMaker_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new SimpleSlideIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "Slides Maker",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "Anything you drop inside the slide 'keeps proportion' when resized, which makes it handy to put pins on maps, add callouts, arrange text in custom layouts etc."

    sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
    sdspw.addNormalParagraph "To see an example of use, check out the video here:"

    startingContent = new SimpleVideoLinkWdgt "Slides Maker", "http://fizzygum.org/docs/slides-maker/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Slides Maker info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_slidesMaker_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()

  createDashboardsMakerOneOffInfoWindowNextTo: (nextToThisWidget) ->
    if world.infoDoc_dashboardsMaker_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new DashboardsIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "Dashboards Maker",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "Lets you arrange a choice of graphs/charts/plots/maps in any way you please. The visualisations can also be interactive (as in the 3D plot example, which you can drag to rotate) and/or calculated on the fly.\n\nOn the bar on the left you can find four example graphs and two example maps."

    sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
    sdspw.addNormalParagraph "To see an example of use, check out the video here:"

    startingContent = new SimpleVideoLinkWdgt "Dashboards Maker", "http://fizzygum.org/docs/dashboards/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Dashboards Maker info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_dashboardsMaker_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()

  createPatchProgrammingOneOffInfoWindowNextTo: (nextToThisWidget) ->
    if world.infoDoc_patchProgramming_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new PatchProgrammingIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "Patch Programming",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "'Patch programming' is a type of visual programming where you simply connect together existing widgets. It's useful to make simple applications/utilities quickly."
    sdspw.addNormalParagraph "You can imagine the widgets being 'patched together' by imaginary wires."
    sdspw.addNormalParagraph "You can see in the `example docs` folder a °C ↔ °F converter example made with this."
    sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
    sdspw.addNormalParagraph "To see an example of use, check out the videos here:"

    startingContent = new SimpleVideoLinkWdgt "Patch programming - basics", "http://fizzygum.org/docs/basic-connections/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    startingContent = new SimpleVideoLinkWdgt "Patch programming - advanced", "http://fizzygum.org/docs/advanced-connections/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Patch Programming info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_patchProgramming_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()

  createGenericPanelOneOffInfoWindowNextTo: (nextToThisWidget) ->
    if world.infoDoc_genericPanel_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new GenericPanelIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "Generic Panel",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "You can use this panel to temporarily hold widgets, or to put together any mix of widgets. It's just a more generic version of slides and dashboards."
    sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
    sdspw.addNormalParagraph "To see an example of use, check out the video here:"

    startingContent = new SimpleVideoLinkWdgt "Mixing widgets (using generic panels)", "http://fizzygum.org/docs/mixing-widgets/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Generic Panels info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_genericPanel_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()

  createBasementOneOffInfoWindowNextTo: (nextToThisWidget) ->
    if world.infoDoc_basement_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new BasementIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "Basement",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "Drag things in here to recycle them.\n\nClosed or invisible items also end up in here, and the items that can't be used again are automatically recycled."

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Basement info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_basement_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()

  createWindowsToolbarOneOffInfoWindowNextTo: (nextToThisWidget) ->
    if world.infoDoc_windowsToolbar_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new WindowsToolbarIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "Types of windows",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "There are four main types of windows"
    sdspw.addBulletPoint "empty windows, with a target area where you can drop other items in"
    sdspw.addBulletPoint "windows that crop their content"
    sdspw.addBulletPoint "windows with a scroll view on their content"
    sdspw.addBulletPoint "windows with an elastic panel, such that when resized the content will resize as well"

    #sdspw.addNormalParagraph "Check out some examples of use in this video:"

    #startingContent = new SimpleVideoLinkWdgt "Using windows"
    #startingContent.rawSetExtent new Point 405, 50
    #sdspw.add startingContent
    #startingContent.layoutSpecDetails.setAlignmentToRight()


    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Windows info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_windowsToolbar_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()
    return wm

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

    degreesConverterOpenerLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "°C ↔ °F", new DegreesConverterIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    
    degreesConverterOpenerLauncher.setExtent new Point 75, 75
    if inWhichFolder?
      inWhichFolder.contents.contents.add degreesConverterOpenerLauncher
    else
      world.add degreesConverterOpenerLauncher
    return wm

  createSampleDashboardOpener: (inWhichFolder) ->
    scriptWdgt = new ScriptWdgt """

     menusHelper.createSampleDashboardWindowOrBringItUpIfAlreadyCreated()


    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world

    degreesConverterOpenerLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "sample dashb", new GenericShortcutIconWdgt new DashboardsIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    
    degreesConverterOpenerLauncher.setExtent new Point 75, 75
    if inWhichFolder?
      inWhichFolder.contents.contents.add degreesConverterOpenerLauncher
    else
      world.add degreesConverterOpenerLauncher
    return wm

  createSampleSlideOpener: (inWhichFolder) ->
    scriptWdgt = new ScriptWdgt """

     menusHelper.createSampleSlideWindowOrBringItUpIfAlreadyCreated()


    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world

    degreesConverterOpenerLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "sample slide", new GenericShortcutIconWdgt new SimpleSlideIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    
    degreesConverterOpenerLauncher.setExtent new Point 75, 75
    if inWhichFolder?
      inWhichFolder.contents.contents.add degreesConverterOpenerLauncher
    else
      world.add degreesConverterOpenerLauncher
    return wm


  createSampleDocOpener: (inWhichFolder) ->
    scriptWdgt = new ScriptWdgt """

     menusHelper.createSampleDocWindowOrBringItUpIfAlreadyCreated()


    """
    # the starting script string above is not
    # actually saved, it's just there as starting
    # content, so let's save it
    scriptWdgt.saveScript()

    wm = new WindowWdgt nil, nil, scriptWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
    wm.fullRawMoveWithin world

    degreesConverterOpenerLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "sample doc", new GenericShortcutIconWdgt new TypewriterIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    
    degreesConverterOpenerLauncher.setExtent new Point 75, 75
    if inWhichFolder?
      inWhichFolder.contents.contents.add degreesConverterOpenerLauncher
    else
      world.add degreesConverterOpenerLauncher
    return wm

  

  createSampleSlideWindowOrBringItUpIfAlreadyCreated: ->
    if world.sampleSlideWindow?
      if !world.sampleSlideWindow.destroyed and world.sampleSlideWindow.parent?
        world.add world.sampleSlideWindow
        world.sampleSlideWindow.bringToForeground()
        world.sampleSlideWindow.fullRawMoveTo world.hand.position().add new Point 100, -50
        world.sampleSlideWindow.fullRawMoveWithin world
        world.sampleSlideWindow.rememberFractionalSituationInHoldingPanel()
        return

    slideWdgt = new SimpleSlideWdgt

    container = slideWdgt.stretchableWidgetContainer.contents
    container.rawSetExtent new Point 575,454

    windowWithScrollingPanel = new WindowWdgt nil, nil, new ScrollPanelWdgt, true, true
    windowWithScrollingPanel.setTitleWithoutPrependedContentName "New York City"
    windowWithScrollingPanel.fullRawMoveTo container.position().add new Point 28, 43
    windowWithScrollingPanel.rawSetExtent new Point 322, 268
    container.add windowWithScrollingPanel
    windowWithScrollingPanel.rememberFractionalSituationInHoldingPanel()


    usaMap = new SimpleUSAMapIconWdgt Color.create 183, 183, 183
    usaMap.rawSetExtent new Point 1808, 1115
    windowWithScrollingPanel.contents.add usaMap
    windowWithScrollingPanel.contents.scrollTo new Point 1484, 246
    usaMap.rememberFractionalSituationInHoldingPanel()

    mapPin = new MapPinIconWdgt
    windowWithScrollingPanel.contents.add mapPin
    mapPin.fullRawMoveTo windowWithScrollingPanel.contents.contents.position().add new Point 1606, 343
    mapPin.rememberFractionalSituationInHoldingPanel()

    sampleBarPlot = new WindowWdgt nil, nil, new PlotWithAxesWdgt(new ExampleBarPlotWdgt), true, true
    sampleBarPlot.rawSetExtent new Point 240, 104
    windowWithScrollingPanel.contents.add sampleBarPlot
    sampleBarPlot.fullRawMoveTo windowWithScrollingPanel.contents.contents.position().add new Point 1566, 420
    sampleBarPlot.setTitleWithoutPrependedContentName "NYC: traffic"


    windowWithScrollingPanel.contents.disableDragsDropsAndEditing()

    mapCaption = new TextMorph2 "The City of New York, often called New York City or simply New York, is the most populous city in the United States. With an estimated 2017 population of 8,622,698 distributed over a land area of about 302.6 square miles (784 km2), New York City is also the most densely populated major city in the United States."
    mapCaption.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    mapCaption.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN

    mapCaption.fullRawMoveTo container.position().add new Point 366, 40
    mapCaption.rawSetExtent new Point 176, 387
    container.add mapCaption
    mapCaption.rememberFractionalSituationInHoldingPanel()

    wikiLink = new SimpleLinkWdgt "New York City Wikipedia page", "https://en.wikipedia.org/wiki/New_York_City"
    wikiLink.fullRawMoveTo container.position().add new Point 110, 348
    wikiLink.rawSetExtent new Point 250, 50
    container.add wikiLink
    wikiLink.rememberFractionalSituationInHoldingPanel()


    wm = new WindowWdgt nil, nil, slideWdgt
    wm.fullRawMoveTo new Point 114, 10
    wm.rawSetExtent new Point 596, 592
    world.add wm
    wm.setTitleWithoutPrependedContentName "Sample slide"

    slideWdgt.disableDragsDropsAndEditing()
    
    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    slideWdgt.closeFromContainerWindow = (containerWindow) ->
      containerWindow.close()

    world.sampleSlideWindow = wm

  createSampleDocWindowOrBringItUpIfAlreadyCreated: ->
    if world.sampleDocWindow?
      if !world.sampleDocWindow.destroyed and world.sampleDocWindow.parent?
        world.add world.sampleDocWindow
        world.sampleDocWindow.bringToForeground()
        world.sampleDocWindow.fullRawMoveTo world.hand.position().add new Point 100, -50
        world.sampleDocWindow.fullRawMoveWithin world
        world.sampleDocWindow.rememberFractionalSituationInHoldingPanel()
        return

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new SimplePlainTextWdgt(
      "Sample Doc",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.setContents startingContent, 5

    sdspw.addDivider()    

    sdspw.addNormalParagraph "Text documents (or simply: docs) don't just contain text or images: they can embed any widget."
    sdspw.addNormalParagraph "For example, here is an interactive 3D plot:\n"

    plot3D = new WindowWdgt nil, nil, new Example3DPlotWdgt, true, true
    plot3D.rawSetExtent new Point 400, 255
    # "constrainToRatio" makes it so the plot in the doc gets taller
    # as the page is made wider
    plot3D.contents.constrainToRatio()
    sdspw.add plot3D

    sdspw.addSpacer()

    sdspw.addNormalParagraph "Connected widgets can be added too, for example this slider below controls the data points of the graph above:\n"

    slider1 = new SliderMorph nil, nil, nil, nil, nil, true
    slider1.rawSetExtent new Point 400, 24
    sdspw.add slider1
    slider1.setTargetAndActionWithOnesPickedFromMenu nil, nil, plot3D.contents, "setParameter"

    sdspw.addSpacer()

    sdspw.addNormalParagraph "How to add connected widgets? Simple: just connect any number of them (see the °C ↔ °F converter for an example), then drop them in the doc."

    sdspw.addSpacer()

    sdspw.addNormalParagraph "What else could be added? Anything! Scripts, maps, maps inside scrolling views, maps with graphs, slides, other docs, and on and on and on..."

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 331, 545
    wm.fullRawMoveTo new Point 257, 110
    world.add wm
    wm.setTitleWithoutPrependedContentName "Sample text document"

    simpleDocument.disableDragsDropsAndEditing()

    
    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.close()

    world.sampleDocWindow = wm

  createSampleDashboardWindowOrBringItUpIfAlreadyCreated: ->
    if world.sampleDashboardWindow?
      if !world.sampleDashboardWindow.destroyed and world.sampleDashboardWindow.parent?
        world.add world.sampleDashboardWindow
        world.sampleDashboardWindow.bringToForeground()
        world.sampleDashboardWindow.fullRawMoveTo world.hand.position().add new Point 100, -50
        world.sampleDashboardWindow.fullRawMoveWithin world
        world.sampleDashboardWindow.rememberFractionalSituationInHoldingPanel()
        return

    slideWdgt = new DashboardsWdgt

    container = slideWdgt.stretchableWidgetContainer.contents
    container.rawSetExtent new Point 725,556

    scatterPlot = new WindowWdgt nil, nil, new PlotWithAxesWdgt(new ExampleScatterPlotWdgt), true, true
    scatterPlot.fullRawMoveTo container.position().add new Point 19, 86
    scatterPlot.rawSetExtent new Point 200, 200
    container.add scatterPlot
    scatterPlot.rememberFractionalSituationInHoldingPanel()

    functionPlot = new WindowWdgt nil, nil, new PlotWithAxesWdgt(new ExampleFunctionPlotWdgt), true, true
    functionPlot.fullRawMoveTo container.position().add new Point 251, 86
    functionPlot.rawSetExtent new Point 200, 200
    container.add functionPlot
    functionPlot.rememberFractionalSituationInHoldingPanel()

    barPlot = new WindowWdgt nil, nil, new PlotWithAxesWdgt(new ExampleBarPlotWdgt), true, true
    barPlot.fullRawMoveTo container.position().add new Point 19, 327
    barPlot.rawSetExtent new Point 200, 200
    container.add barPlot
    barPlot.rememberFractionalSituationInHoldingPanel()

    plot3D = new WindowWdgt nil, nil, new Example3DPlotWdgt, true, true
    plot3D.fullRawMoveTo container.position().add new Point 491, 327
    plot3D.rawSetExtent new Point 200, 150
    container.add plot3D
    plot3D.rememberFractionalSituationInHoldingPanel()

    usaMap = new SimpleUSAMapIconWdgt Color.create 183, 183, 183
    usaMap.fullRawMoveTo container.position().add new Point 242, 355
    usaMap.rawSetExtent new Point 230, 145
    container.add usaMap
    usaMap.rememberFractionalSituationInHoldingPanel()

    mapPin1 = new MapPinIconWdgt
    mapPin1.fullRawMoveTo container.position().add new Point 226, 376
    container.add mapPin1
    mapPin1.rememberFractionalSituationInHoldingPanel()

    mapPin2 = new MapPinIconWdgt
    mapPin2.fullRawMoveTo container.position().add new Point 289, 363
    container.add mapPin2
    mapPin2.rememberFractionalSituationInHoldingPanel()

    mapPin3 = new MapPinIconWdgt
    mapPin3.fullRawMoveTo container.position().add new Point 323, 397
    container.add mapPin3
    mapPin3.rememberFractionalSituationInHoldingPanel()

    mapPin4 = new MapPinIconWdgt
    mapPin4.fullRawMoveTo container.position().add new Point 360, 421
    container.add mapPin4
    mapPin4.rememberFractionalSituationInHoldingPanel()

    mapPin5 = new MapPinIconWdgt
    mapPin5.fullRawMoveTo container.position().add new Point 417, 374
    container.add mapPin5
    mapPin5.rememberFractionalSituationInHoldingPanel()

    worldMap = new SimpleWorldMapIconWdgt Color.create 183, 183, 183
    worldMap.fullRawMoveTo container.position().add new Point 464, 128
    worldMap.rawSetExtent new Point 240, 125
    container.add worldMap
    worldMap.rememberFractionalSituationInHoldingPanel()

    speechBubble1 = new SpeechBubbleWdgt "online"
    speechBubble1.fullRawMoveTo container.position().add new Point 506, 123
    speechBubble1.rawSetExtent new Point 66, 42
    container.add speechBubble1
    speechBubble1.rememberFractionalSituationInHoldingPanel()

    speechBubble2 = new SpeechBubbleWdgt "offline"
    speechBubble2.fullRawMoveTo container.position().add new Point 590, 105
    speechBubble2.rawSetExtent new Point 66, 42
    container.add speechBubble2
    speechBubble2.rememberFractionalSituationInHoldingPanel()

    dashboardTitle = new TextMorph2 "Example dashboard with interactive 3D plot"
    dashboardTitle.alignCenter()
    dashboardTitle.alignMiddle()
    dashboardTitle.fullRawMoveTo container.position().add new Point 161, 6
    dashboardTitle.rawSetExtent new Point 403, 50
    container.add dashboardTitle
    dashboardTitle.rememberFractionalSituationInHoldingPanel()


    slider1 = new SliderMorph nil, nil, nil, nil, nil, true
    slider1.fullRawMoveTo container.position().add new Point 491, 484
    slider1.rawSetExtent new Point 201, 24
    container.add slider1
    slider1.rememberFractionalSituationInHoldingPanel()

    slider1.setTargetAndActionWithOnesPickedFromMenu nil, nil, plot3D.contents, "setParameter"

    wm = new WindowWdgt nil, nil, slideWdgt
    wm.fullRawMoveTo new Point 114, 10
    wm.rawSetExtent new Point 596, 592
    world.add wm
    wm.setTitleWithoutPrependedContentName "Sample dashboard"


    slideWdgt.disableDragsDropsAndEditing()
    
    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    slideWdgt.closeFromContainerWindow = (containerWindow) ->
      containerWindow.close()

    world.sampleDashboardWindow = wm



  createDegreesConverterWindowOrBringItUpIfAlreadyCreated: ->
    if world.degreesConverterWindow?
      if !world.degreesConverterWindow.destroyed and world.degreesConverterWindow.parent?
        world.add world.degreesConverterWindow
        world.degreesConverterWindow.bringToForeground()
        world.degreesConverterWindow.fullRawMoveTo world.hand.position().add new Point 100, -50
        world.degreesConverterWindow.fullRawMoveWithin world
        world.degreesConverterWindow.rememberFractionalSituationInHoldingPanel()
        return

    xCorrection = 32
    yCorrection = 50
    patchProgrammingWdgt = new PatchProgrammingWdgt

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

    toolbarsOpenerLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "How to save?", new FloppyDiskIconWdgt
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
        world.howToSaveDocWindow.rememberFractionalSituationInHoldingPanel()
        return

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new FloppyDiskIconWdgt
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


    sdspw.addNormalParagraph "There are a couple of ways to save data in Fizzygum.¹\n\nHowever, \"in-house\" stable saving solutions are only available in private versions.²\n\nIn the meantime that these solutions make their way into the public version, the Fizzygum team can consult for you to tailor 'saving' functionality to your needs (save to file, save to cloud, connect to databases etc. ).\n\nPlease enquiry via one of the Fizzygum contacts here:"

    sdspw.addSpacer()

    startingContent = new SimpleLinkWdgt "Contacts", "http://fizzygum.org/contact/"
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
    wm.rememberFractionalSituationInHoldingPanel()
    wm.setTitleWithoutPrependedContentName "How to save?"

    simpleDocument.disableDragsDropsAndEditing()

    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.close()


    world.howToSaveDocWindow = wm

