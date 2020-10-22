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

  launchSimpleSlide: ->
    wm = new WindowWdgt nil, nil, new SimpleSlideWdgt
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo new Point 168, 134
    wm.fullRawMoveWithin world
    world.add wm

    SimpleSlideInfoWdgt.createNextTo wm

  createSimpleSlideLauncher: ->
    simpleSlideLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "Slides Maker", new SimpleSlideIconWdgt, @, "launchSimpleSlide"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add simpleSlideLauncher
    simpleSlideLauncher.setExtent new Point 75, 75
    simpleSlideLauncher.fullChanged()

  # ------------------------------------------------------------------------

  launchDashboards: ->
    reconfPaint = new DashboardsWdgt
    wm = new WindowWdgt nil, nil, reconfPaint
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position()
    wm.fullRawMoveWithin world
    world.add wm

    DashboardsInfoWdgt.createNextTo wm

  createDashboardsLauncher: ->
    simpleDashboardsLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "Dashboards", new DashboardsIconWdgt, @, "launchDashboards"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add simpleDashboardsLauncher
    simpleDashboardsLauncher.setExtent new Point 75, 75
    simpleDashboardsLauncher.fullChanged()


  # ------------------------------------------------------------------------

  launchPatchProgramming: ->
    patchProgramming = new PatchProgrammingWdgt
    wm = new WindowWdgt nil, nil, patchProgramming
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position()
    wm.fullRawMoveWithin world
    world.add wm
    
    PatchProgrammingInfoWdgt.createNextTo wm

  createPatchProgrammingLauncher: ->
    patchProgrammingLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "Patch progr.", new PatchProgrammingIconWdgt, @, "launchPatchProgramming"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add patchProgrammingLauncher
    patchProgrammingLauncher.setExtent new Point 75, 75
    patchProgrammingLauncher.fullChanged()

  # ------------------------------------------------------------------------

  launchGenericPanel: ->
    genericPanel = new StretchableEditableWdgt
    wm = new WindowWdgt nil, nil, genericPanel
    wm.setExtent new Point 460, 400
    wm.fullRawMoveTo world.hand.position()
    wm.fullRawMoveWithin world
    world.add wm

    GenericPanelInfoWdgt.createNextTo wm

  createGenericPanelLauncher: ->
    genericPanelLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "Generic panel", new GenericPanelIconWdgt, @, "launchGenericPanel"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add genericPanelLauncher
    genericPanelLauncher.setExtent new Point 75, 75
    genericPanelLauncher.fullChanged()

  # ------------------------------------------------------------------------

  launchToolbars: ->
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

    ToolbarsInfoWdgt.createNextTo wm

  createToolbarsOpener: ->
    toolbarsOpenerLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "Super Toolbar", new ToolbarsIconWdgt, @, "launchToolbars"
    toolbarsOpenerLauncher.toolTipMessage = "a toolbar to rule them all"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add toolbarsOpenerLauncher
    toolbarsOpenerLauncher.setExtent new Point 75, 75
    toolbarsOpenerLauncher.fullChanged()

  # ------------------------------------------------------------------------

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
    wm = WelcomeMessageInfoWdgt.create()
    readmeLauncher = new IconicDesktopSystemDocumentShortcutWdgt wm, "Welcome", new WelcomeIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add readmeLauncher
    readmeLauncher.setExtent new Point 75, 75
    readmeLauncher.fullChanged()

  # ------------------------------------------------------------------------

  launchDegreesConverter: ->
    @createDegreesConverterWindowOrBringItUpIfAlreadyCreated()

  createDegreesConverterOpener: (inWhichFolder) ->
    degreesConverterOpenerLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "°C ↔ °F", new DegreesConverterIconWdgt, @, "launchDegreesConverter"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    
    degreesConverterOpenerLauncher.setExtent new Point 75, 75
    if inWhichFolder?
      inWhichFolder.contents.contents.add degreesConverterOpenerLauncher
    else
      world.add degreesConverterOpenerLauncher

  # ------------------------------------------------------------------------

  launchSampleDashboard: ->
    @createSampleDashboardWindowOrBringItUpIfAlreadyCreated()

  createSampleDashboardOpener: (inWhichFolder) ->
    degreesConverterOpenerLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "sample dashb", (new GenericShortcutIconWdgt new DashboardsIconWdgt), @, "launchSampleDashboard"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    
    degreesConverterOpenerLauncher.setExtent new Point 75, 75
    if inWhichFolder?
      inWhichFolder.contents.contents.add degreesConverterOpenerLauncher
    else
      world.add degreesConverterOpenerLauncher

  # ------------------------------------------------------------------------

  launchSampleSlide: ->
    @createSampleSlideWindowOrBringItUpIfAlreadyCreated()

  createSampleSlideOpener: (inWhichFolder) ->
    degreesConverterOpenerLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "sample slide", (new GenericShortcutIconWdgt new SimpleSlideIconWdgt), @, "launchSampleSlide"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    
    degreesConverterOpenerLauncher.setExtent new Point 75, 75
    if inWhichFolder?
      inWhichFolder.contents.contents.add degreesConverterOpenerLauncher
    else
      world.add degreesConverterOpenerLauncher

  # ------------------------------------------------------------------------

  launchSampleDoc: ->
    @createSampleDocWindowOrBringItUpIfAlreadyCreated()

  createSampleDocOpener: (inWhichFolder) ->
    degreesConverterOpenerLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "sample doc", (new GenericShortcutIconWdgt new TypewriterIconWdgt), @, "launchSampleDoc"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    
    degreesConverterOpenerLauncher.setExtent new Point 75, 75
    if inWhichFolder?
      inWhichFolder.contents.contents.add degreesConverterOpenerLauncher
    else
      world.add degreesConverterOpenerLauncher

  # ------------------------------------------------------------------------

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

    world.sampleDocWindow = SimpleDocumentSampleWdgt.create()

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

  # ------------------------------------------------------------------------

  launchHowToSaveMessage: ->
    @createHowToSaveMessageWindowOrBringItUpIfAlreadyCreated()

  createHowToSaveMessageOpener: ->
    toolbarsOpenerLauncher = new IconicDesktopSystemWindowedAppLauncherWdgt "How to save?", new FloppyDiskIconWdgt, @, "launchHowToSaveMessage"
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add toolbarsOpenerLauncher
    toolbarsOpenerLauncher.setExtent new Point 75, 75
    toolbarsOpenerLauncher.fullChanged()

  # ------------------------------------------------------------------------

  createHowToSaveMessageWindowOrBringItUpIfAlreadyCreated: ->
    if world.howToSaveDocWindow?
      if !world.howToSaveDocWindow.destroyed and world.howToSaveDocWindow.parent?
        world.add world.howToSaveDocWindow
        world.howToSaveDocWindow.bringToForeground()
        world.howToSaveDocWindow.fullRawMoveTo world.hand.position().add new Point 100, -50
        world.howToSaveDocWindow.fullRawMoveWithin world
        world.howToSaveDocWindow.rememberFractionalSituationInHoldingPanel()
        return

    world.howToSaveDocWindow = HowToSaveMessageInfoWdg.create()

