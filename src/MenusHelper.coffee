# REQUIRES DeepCopierMixin

# All "actions" functions for all accessory menu items should belong
# in here. Also helps so we don't pollute moprhs with a varying number
# of helper functions, which is problematic for visual diffing
# on inspectors (the number of methods keeps changing).

class MenusHelper

  @augmentWith DeepCopierMixin

  createFridgeMagnets: ->
    debugger
    fmm = new FridgeMagnetsMorph()
    wm = new WindowWdgt nil, nil, fmm
    wm.setExtent new Point 570, 400
    wm.fullRawMoveTo world.hand.position()
    wm.fullRawMoveWithin world
    world.add wm
    wm.changed()


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

  createFizzyPaintLauncherAndItsIcon: ->
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
    world.add wm
    wm.changed()

    fizzyPaintLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Fizzypaint", new PaintBucketIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add fizzyPaintLauncher
    fizzyPaintLauncher.setExtent new Point 75, 75
    fizzyPaintLauncher.fullChanged()

  createSimpleDocumentLauncherAndItsIcon: ->
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
    world.add wm
    wm.changed()

    fizzyPaintLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Simple docs", new TypewriterIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add fizzyPaintLauncher
    fizzyPaintLauncher.setExtent new Point 75, 75
    fizzyPaintLauncher.fullChanged()

  createSimpleSlideLauncherAndItsIcon: ->
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
    world.add wm
    wm.changed()

    fizzyPaintLauncher = new IconicDesktopSystemScriptShortcutWdgt wm, "Simple slides", new SimpleSlideIconWdgt()
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add fizzyPaintLauncher
    fizzyPaintLauncher.setExtent new Point 75, 75
    fizzyPaintLauncher.fullChanged()


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
    menu.addMenuItem "function plot", true, menusHelper, "createExampleFunctionPlot"
    menu.addMenuItem "bar plot", true, menusHelper, "createExampleBarPlot"
    menu.addMenuItem "3D plot", true, menusHelper, "createExample3DPlot"

    menu.popUpAtHand()

  popUpSupportDocsMenu: (morphOpeningThePopUp) ->
    menu = new MenuMorph morphOpeningThePopUp,  false, @, true, true, "Support Docs"
    menu.addMenuItem "welcome message", true, @, "createWelcomeMessageWindow", "welcome message"

    menu.popUpAtHand()

  createWelcomeMessageWindow: ->
    sdspw = new SimpleDocumentScrollPanelWdgt()

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new FizzygumLogoIconWdgt()
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setAlignmentToCenter()


    startingContent = new SimplePlainTextWdgt(
      "Welcome to Fizzygum",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.alignCenter()
    startingContent.setFontSize 24
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()

    startingContent = new SimplePlainTextWdgt(
      "Fizzygum is an open web framework to:",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.isTemplate = true
    sdspw.add startingContent

    sdspw.addBulletPoint "make dashboards and visualise data"
    sdspw.addBulletPoint "author documents (drawings / text docs / slides)"
    sdspw.addBulletPoint "embed live graphs, dynamic calculations or even entire running programs inside any document, via simple drag & drop"
    sdspw.addBulletPoint "go beyond traditional embedding: you can now infinitely nest and compose programs and documents. Want to run a program inside a document inside a presentation inside another running program? No problem"
    sdspw.addBulletPoint "make custom utilities (e.g. temperature converter) by simply connecting existing components (no coding required)"
    sdspw.addBulletPoint "use the internal development tools to create entirely new apps, or change existing ones while they are running. Add custom features without even needing to refresh the page."

    sdspw.addSpacer()

    startingContent = new SimplePlainTextWdgt(
      "New here?",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "Feel free to click around this sandbox. Just reload to start again from clean sheet."

    sdspw.addSpacer()
    sdspw.addNormalParagraph "Also check out some screenshots here:"

    startingContent = new SimpleLinkWdgt "screenshots"
    startingContent.rawSetExtent new Point 405, 50
    startingContent.isTemplate = true
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addNormalParagraph "...or watch some quick demos on the Youtube channel:"

    startingContent = new SimpleVideoLinkWdgt "YouTube channel"
    startingContent.rawSetExtent new Point 405, 50
    startingContent.isTemplate = true
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addNormalParagraph "...or docs here:"

    startingContent = new SimpleLinkWdgt "docs"
    startingContent.rawSetExtent new Point 405, 50
    startingContent.isTemplate = true
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addSpacer(2)

    startingContent = new SimplePlainTextWdgt(
      "Get in touch",nil,nil,nil,nil,nil,(new Color 240, 240, 240), 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "Mail? Mailing list? Facebook page? Twitter? Chat? We have it all."

    startingContent = new SimpleLinkWdgt "contacts"
    startingContent.rawSetExtent new Point 405, 50
    startingContent.isTemplate = true
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()


    wm = new WindowWdgt nil, nil, sdspw
    wm.fullRawMoveTo new Point 114, 10
    wm.rawSetExtent new Point 365, 405
    world.add wm
    wm.setTitleWithoutPrependedContentName "Welcome"
    wm.changed()

