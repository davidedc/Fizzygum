# All "actions" functions for all accessory menu items should belong
# in here. Also helps so we don't pollute moprhs with a varying number
# of helper functions, which is problematic for visual diffing
# on inspectors (the number of methods keeps changing).

class MenusHelper

  @augmentWith DeepCopierMixin

  popUpDevToolsMenu: (widgetOpeningThePopUp, widgetThisMenuIsAbout) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "Dev Tools"
    menu.addMenuItem "inspect", true, widgetThisMenuIsAbout, "inspect", "open a window\non all properties"
    menu.addMenuItem "console", true, widgetThisMenuIsAbout, "createConsole", "console"

    menu.popUpAtHand()


  # »>> this part is excluded from the fizzygum homepage build
  createFridgeMagnets: ->
    fmm = new FridgeMagnetsWdgt
    world.openWindowWith fmm, (new Point 570, 400), world.hand.position()


  createReconfigurablePaint: ->
    reconfPaint = new ReconfigurablePaintWdgt
    world.openWindowWith reconfPaint, (new Point 460, 400), world.hand.position()

  createSimpleSlideWdgt: ->
    simpleSlide = new SimpleSlideWdgt
    world.openWindowWith simpleSlide, (new Point 460, 400), world.hand.position()

  createSimpleButton: ->
    world.create new SimpleRectangularButtonWdgt true, @, nil, new IconWdgt(nil)

  createSwitchButtonWdgt: ->
    button1 = new SimpleRectangularButtonWdgt true, @, nil, new IconWdgt(nil)
    button2 = new SimpleRectangularButtonWdgt true, @, nil, new StringWdgt "Hello World! ⎲ƒ⎳⎷ ⎸⎹ "
    world.create new SwitchButtonWdgt [button1, button2]

  createNewClippingBoxWdgt: ->
    world.create new ClippingBoxWdgt

  makeSlidersButtonsStatesBright: ->
    world.forAllChildrenBottomToTop (child) ->
      if child instanceof SliderButtonWdgt
       child.pressColor = Color.LIME
       child.highlightColor = Color.BLUE
       child.normalColor = Color.BLACK

  # Icons --------------------------------------------------------------

  makeIconWithText: ->
    world.create new WidgetHolderWithCaptionWdgt "hey there", new BrushIconWdgt

  makeEmptyIconWithText: ->
    world.create new WidgetHolderWithCaptionWdgt "hey there"

  makeFolderWindow: (a,b,c,d,e) ->
    world.create new FolderWindowWdgt nil,nil,nil,nil, @

  makeBouncingParticle: ->
    world.create new BouncerWdgt

  createDestroyIconWdgt: ->
    world.create new DestroyIconWdgt

  createUnderCarpetIconWdgt: ->
    world.create new UnderCarpetIconWdgt

  createUncollapsedStateIconWdgt: ->
    world.create new UncollapsedStateIconWdgt

  createCollapsedStateIconWdgt: ->
    world.create new CollapsedStateIconWdgt

  createCloseIconButtonWdgt: ->
    world.create new CloseIconButtonWdgt

  createScratchAreaIconWdgt: ->
    world.create new ScratchAreaIconWdgt

  createFloraIconWdgt: ->
    world.create new FloraIconWdgt

  createScooterIconWdgt: ->
    world.create new ScooterIconWdgt

  createHeartIconWdgt: ->
    world.create new HeartIconWdgt


  createPencil1IconWdgt: ->
    world.create new PencilIconWdgt

  createPencil2IconWdgt: ->
    world.create new Pencil2IconWdgt

  createBrushIconWdgt: ->
    world.create new BrushIconWdgt

  createToothpasteIconWdgt: ->
    world.create new ToothpasteIconWdgt

  createEraserIconWdgt: ->
    world.create new EraserIconWdgt


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
    world.openWindowWith scriptWdgt, (new Point 460, 400), world.hand.position().subtract(new Point 50, 100)
  # this part is excluded from the fizzygum homepage build <<«

  # »>> this part is excluded from the fizzygum homepage build
  createFanout: ->
    fanoutWdgt = new FanoutWdgt
    world.create fanoutWdgt
    fanoutWdgt.setExtent new Point 100, 100

  createCalculatingPatchNode: ->
    calculatingPatchNodeWdgt = new CalculatingPatchNodeWdgt
    wm = new WindowWdgt nil, nil, calculatingPatchNodeWdgt, true
    wm.setExtent new Point 460, 400
    wm.moveTo world.hand.position().subtract new Point 50, 100
    wm.moveWithin world
    world.add wm

  createDiffingPatchNode: ->
    diffingPatchNodeWdgt = new DiffingPatchNodeWdgt
    wm = new WindowWdgt nil, nil, diffingPatchNodeWdgt, true
    wm.setExtent new Point 460, 400
    wm.moveTo world.hand.position().subtract new Point 50, 100
    wm.moveWithin world
    world.add wm

  createSliderWithSmallestValueAtBottomEnd: ->
    world.create new SliderWdgt nil, nil, nil, nil, nil, true

  createRegexSubstitutionPatchNodeWdgt: ->
    regexSubstitutionPatchNodeWdgt = new RegexSubstitutionPatchNodeWdgt
    wm = new WindowWdgt nil, nil, regexSubstitutionPatchNodeWdgt, true
    wm.setExtent new Point 460, 400
    wm.moveTo world.hand.position().subtract new Point 50, 100
    wm.moveWithin world
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
    wm.moveTo world.hand.position().subtract new Point 50, 100
    wm.moveWithin world
    world.add wm

  createHorizontalMenuPanelPanel: ->
    horizontalMenuPanel = new HorizontalMenuPanelWdgt
    wm = new WindowWdgt nil, nil, horizontalMenuPanel, true
    wm.setExtent new Point 200, 400
    wm.moveTo world.hand.position().subtract new Point 50, 100
    wm.moveWithin world
    world.add wm


  popUpMore1IconsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "More Icons 1"
    menu.addMenuItem "Pencil 1 icon", true, menusHelper, "createPencil1IconWdgt"
    menu.addMenuItem "Pencil 2 icon", true, menusHelper, "createPencil2IconWdgt"
    menu.addMenuItem "Brush icon", true, menusHelper, "createBrushIconWdgt"
    menu.addMenuItem "Toothpaste icon", true, menusHelper, "createToothpasteIconWdgt"
    menu.addMenuItem "Eraser icon", true, menusHelper, "createEraserIconWdgt"
    menu.addMenuItem "Trashcan icon", true, menusHelper, "createTrashcanIconWdgt"
    menu.addMenuItem "Shortcut arrow icon", true, menusHelper, "createShortcutArrowIconWdgt"
    menu.addMenuItem "Raster pic icon", true, menusHelper, "createRasterPicIconWdgt"
    menu.addMenuItem "Paint bucket icon", true, menusHelper, "createPaintBucketIconWdgt"
    menu.addMenuItem "Object icon", true, menusHelper, "createObjectIconWdgt"
    menu.addMenuItem "Folder icon", true, menusHelper, "createFolderIconWdgt"
    menu.addMenuItem "Basement icon", true, menusHelper, "createBasementIconWdgt"
    menu.addMenuItem "Widget icon", true, menusHelper, "createWidgetIconWdgt"
    menu.popUpAtHand()

  popUpMore2IconsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "More Icons 2"
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

  popUpMore3IconsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "More Icons 2"
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

  popUpArrowsIconsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "Arrows"
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

  createWorldMapIconWdgt: ->
    world.create new SimpleWorldMapIconWdgt

  createUSAMapIconWdgt: ->
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
    world.openWindowWith simpleDocument, (new Point 368, 335), world.hand.position().subtract(new Point 50, 100)

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
    plotWithAxesWdgt.setExtent new Point 300, 300
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

  popUpMapsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "Maps"
    menu.addMenuItem "world map", true, menusHelper, "createWorldMapIconWdgt", "others"
    menu.addMenuItem "USA map", true, menusHelper, "createUSAMapIconWdgt", "others"

    menu.popUpAtHand()

  popUpGraphsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "graphs"
    menu.addMenuItem "axis", true, menusHelper, "create2DAxis"
    menu.addMenuItem "scatter plot", true, menusHelper, "createExampleScatterPlot"
    menu.addMenuItem "scatter plot with axes", true, menusHelper, "createExampleScatterPlotWithAxes"
    menu.addMenuItem "function plot", true, menusHelper, "createExampleFunctionPlot"
    menu.addMenuItem "bar plot", true, menusHelper, "createExampleBarPlot"
    menu.addMenuItem "3D plot", true, menusHelper, "createExample3DPlot"

    menu.popUpAtHand()

  popUpSupportDocsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "Support Docs"
    menu.addMenuItem "welcome message", true, @, "createWelcomeMessageWindowAndShortcut", "welcome message"

    menu.popUpAtHand()

  popUpPatchProgrammingMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "Patch Programming"
    menu.addMenuItem "fanout", true, menusHelper, "createFanout"
    menu.addMenuItem "calculating node", true, menusHelper, "createCalculatingPatchNode"
    menu.addMenuItem "diffing node", true, menusHelper, "createDiffingPatchNode"
    menu.addMenuItem "slider", true, menusHelper, "createSliderWithSmallestValueAtBottomEnd"
    menu.addMenuItem "regex subst. node", true, menusHelper, "createRegexSubstitutionPatchNodeWdgt"
    menu.popUpAtHand()

  popUpVerticalStackMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "Vertical stack"
    menu.addMenuItem "vertical stack constrained contents width", true, menusHelper, "createSimpleVerticalStackPanelWdgt"
    menu.addMenuItem "vertical stack scrollpanel constrained contents width", true, menusHelper, "createSimpleVerticalStackScrollPanelWdgt"
    menu.addMenuItem "vertical stack panel and scrollpanel constrained contents width", true, menusHelper, "createSimpleVerticalStackPanelWdgtAndScrollPanel"
    menu.addMenuItem "vertical stack free contents width", true, menusHelper, "createSimpleVerticalStackPanelWdgtFreeContentsWidth"
    menu.addMenuItem "vertical stack scrollpanel free contents width", true, menusHelper, "createSimpleVerticalStackScrollPanelWdgtFreeContentsWidth"
    menu.addMenuItem "vertical stack panel and scrollpanel free contents width", true, menusHelper, "createSimpleVerticalStackPanelWdgtAndScrollPanelFreeContentsWidth"

    menu.popUpAtHand()

  createSimpleVerticalStackPanelWdgt: ->
    svspw = new SimpleVerticalStackPanelWdgt
    world.add svspw
    svspw.setBounds new Point(35, 30), new Point(370, 325)

  createSimpleVerticalStackScrollPanelWdgt: ->
    svsspw = new SimpleVerticalStackScrollPanelWdgt
    world.add svsspw
    # public setters on the ATTACHED panel self-settle in place (was _applyMoveTo/_applyExtent, whose raw
    # resize on an attached panel used to trip the now-deleted _announceGeometryChangeToContainer geom seam into an off-settle re-fit)
    svsspw.moveTo new Point 430, 25
    svsspw.setExtent new Point 370, 325

  createSimpleVerticalStackPanelWdgtAndScrollPanel: ->
    @createSimpleVerticalStackPanelWdgt()
    @createSimpleVerticalStackScrollPanelWdgt()

  createSimpleVerticalStackPanelWdgtFreeContentsWidth: ->
    svspw = new SimpleVerticalStackPanelWdgt null, null, null, false
    world.add svspw
    svspw.setBounds new Point(35, 30), new Point(370, 325)

  createSimpleVerticalStackScrollPanelWdgtFreeContentsWidth: ->
    svsspw = new SimpleVerticalStackScrollPanelWdgt false
    world.add svsspw
    svsspw.setBounds new Point(430, 25), new Point(370, 325)

  createSimpleVerticalStackPanelWdgtAndScrollPanelFreeContentsWidth: ->
    @createSimpleVerticalStackPanelWdgt()
    @createSimpleVerticalStackScrollPanelWdgt()

  popUpIconsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "icons"
    menu.addMenuItem "Destroy icon", true, menusHelper, "createDestroyIconWdgt"
    menu.addMenuItem "Under the carpet icon", true, menusHelper, "createUnderCarpetIconWdgt"
    menu.addMenuItem "Collapsed state icon", true, menusHelper, "createCollapsedStateIconWdgt"
    menu.addMenuItem "Uncollapsed state icon", true, menusHelper, "createUncollapsedStateIconWdgt"
    menu.addMenuItem "Close icon", true, menusHelper, "createCloseIconButtonWdgt"
    menu.addMenuItem "Scratch area icon", true, menusHelper, "createScratchAreaIconWdgt"
    menu.addMenuItem "Flora icon", true, menusHelper, "createFloraIconWdgt"
    menu.addMenuItem "Scooter icon", true, menusHelper, "createScooterIconWdgt"
    menu.addMenuItem "Heart icon", true, menusHelper, "createHeartIconWdgt"

    menu.addMenuItem "more 1 ➜", false, menusHelper, "popUpMore1IconsMenu", "others"
    menu.addMenuItem "more 2 ➜", false, menusHelper, "popUpMore2IconsMenu", "others"
    menu.addMenuItem "arrows ➜", false, menusHelper, "popUpArrowsIconsMenu", "others"
    menu.addMenuItem "maps ➜", false, menusHelper, "popUpMapsMenu", "maps"
    menu.addMenuItem "more 3 ➜", false, menusHelper, "popUpMore3IconsMenu", "maps"

    menu.popUpAtHand()

  popUpWindowsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "Windows"
    menu.addMenuItem "empty window", true, menusHelper, "createEmptyWindow"
    menu.addMenuItem "empty internal window", true, menusHelper, "createEmptyInternalWindow"

    menu.popUpAtHand()

  popUpShortcutsAndScriptsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "Shortcuts & Scripts"
    menu.addMenuItem "basement shortcut", true, menusHelper, "basementIconAndText"
    menu.addMenuItem "new script", true, menusHelper, "newScriptWindow"
    menu.addMenuItem "Fizzypaint launcher", true, (new FizzyPaintApp), "createOpener"
    menu.addMenuItem "Simple doc launcher", true, (new SimpleDocumentApp), "createOpener"
    menu.addMenuItem "Simple slide launcher", true, (new SimpleSlideApp), "createOpener"
    menu.addMenuItem "Link", true, menusHelper, "createSimpleLinkWdgt"
    menu.addMenuItem "Video link", true, menusHelper, "createSimpleVideoLinkWdgt"
    menu.popUpAtHand()

  createEmptyInternalWindow: ->
    wm = new WindowWdgt nil, nil, nil, true
    wm.moveTo world.hand.position()
    wm.moveWithin world
    world.add wm

  createEmptyWindow: ->
    wm = new WindowWdgt nil, nil, nil
    wm.moveTo world.hand.position()
    wm.moveWithin world
    world.add wm

  createNewWrappingSimplePlainTextWdgtWithBackground: ->
    newWdgt = new SimplePlainTextWdgt(
      "Lorem ipsum dolor sit amet, consectetur adipiscing " +
      "elit. Integer rhoncus pharetra nulla, vel maximus " +
      "lectus posuere a. Phasellus finibus blandit ex vitae " +
      "varius. Vestibulum blandit velit elementum, ornare " +
      "ipsum sollicitudin, blandit nunc. Mauris a sapien " +
      "nibh. Nulla nec bibendum quam, eu condimentum nisl. " +
      "Cras consequat efficitur nisi sed ornare. " +
      "Pellentesque vitae urna vitae libero malesuada " +
      "pharetra." +
      "\n\n" +
      "Pellentesque commodo, nulla mattis vulputate " +
      "porttitor, elit augue vestibulum est, nec congue " +
      "ex dui a velit. Nullam lectus leo, lobortis eget " +
      "erat ac, lobortis dignissim magna. Morbi ac odio " +
      "in purus blandit dignissim. Maecenas at sagittis " +
      "odio. Suspendisse tempus mattis erat id euismod. " +
      "Duis semper mauris nec odio sagittis vulputate. " +
      "Praesent varius ac erat id fringilla. Suspendisse " +
      "porta sollicitudin bibendum. Pellentesque imperdiet " +
      "at eros nec euismod. Etiam ac mattis odio, ac finibus " +
      "nisi.",nil,nil,nil,nil,nil,Color.create(230, 230, 130), 1)
    newWdgt.isEditable = true

    world.add newWdgt
    newWdgt.setBounds new Point(25, 40), new Point(500, 300)

  createNewNonWrappingSimplePlainTextWdgtWithBackground: ->
    newWdgt = new SimplePlainTextWdgt(
      "Lorem ipsum dolor sit amet, consectetur adipiscing " +
      "elit. Integer rhoncus pharetra nulla, vel maximus " +
      "lectus posuere a. Phasellus finibus blandit ex vitae " +
      "varius." +
      "\n\n" +
      "Pellentesque commodo, nulla mattis vulputate " +
      "porttitor, elit augue vestibulum est, nec congue " +
      "ex dui a velit. Nullam lectus leo, lobortis eget " +
      "erat ac, lobortis dignissim " +
      "magna.",nil,nil,nil,nil,nil,Color.create(230, 230, 130), 1)
    newWdgt.isEditable = true
    # non-wrapping ("code view"): hug the natural text width.
    newWdgt.softWrap = false

    world.add newWdgt
    newWdgt.setBounds new Point(540, 40), new Point(500, 300)

  createNewWrappingAndNonWrappingSimplePlainTextWdgtWithBackground: ->
    @createNewWrappingSimplePlainTextWdgtWithBackground()
    @createNewNonWrappingSimplePlainTextWdgtWithBackground()

  createWrappingSimplePlainTextScrollPanelWdgt: ->
    SfA = new SimplePlainTextScrollPanelWdgt(
      "Lorem ipsum dolor sit amet, consectetur adipiscing " +
      "elit. Integer rhoncus pharetra nulla, vel maximus " +
      "lectus posuere a. Phasellus finibus blandit ex vitae " +
      "varius. Vestibulum blandit velit elementum, ornare " +
      "ipsum sollicitudin, blandit nunc. Mauris a sapien " +
      "nibh. Nulla nec bibendum quam, eu condimentum nisl. " +
      "Cras consequat efficitur nisi sed ornare. " +
      "Pellentesque vitae urna vitae libero malesuada " +
      "pharetra." +
      "\n\n" +
      "Pellentesque commodo, nulla mattis vulputate " +
      "porttitor, elit augue vestibulum est, nec congue " +
      "ex dui a velit. Nullam lectus leo, lobortis eget " +
      "erat ac, lobortis dignissim magna. Morbi ac odio " +
      "in purus blandit dignissim. Maecenas at sagittis " +
      "odio. Suspendisse tempus mattis erat id euismod. " +
      "Duis semper mauris nec odio sagittis vulputate. " +
      "Praesent varius ac erat id fringilla. Suspendisse " +
      "porta sollicitudin bibendum. Pellentesque imperdiet " +
      "at eros nec euismod. Etiam ac mattis odio, ac finibus " +
      "nisi.",true, 10)
    world.add SfA
    SfA.setBounds new Point(20, 25), new Point(390, 305)

  createNonWrappingSimplePlainTextScrollPanelWdgt: ->
    SfB = new SimplePlainTextScrollPanelWdgt(
      "Lorem ipsum dolor sit amet, consectetur adipiscing " +
      "elit. Integer rhoncus pharetra nulla, vel maximus " +
      "\n\n" +
      "Pellentesque commodo, nulla mattis vulputate " +
      "porttitor, elit augue vestibulum est, nec congue " +
      "nisi.",false, 10)
    world.add SfB
    SfB.setBounds new Point(430, 25), new Point(390, 305)

  createWrappingAndNonWrappingSimplePlainTextScrollPanelWdgt: ->
    @createWrappingSimplePlainTextScrollPanelWdgt()
    @createNonWrappingSimplePlainTextScrollPanelWdgt()

  # this is provided for completeness, however see the
  # note in SimplePlainTextPanelWdgt about how this is
  # incomplete and why this widget is not useful anyways
  createWrappingSimplePlainTextPanelWdgt: ->
    SfA = new SimplePlainTextPanelWdgt(
      "Lorem ipsum dolor sit amet, consectetur adipiscing " +
      "elit. Integer rhoncus pharetra nulla, vel maximus " +
      "lectus posuere a. Phasellus finibus blandit ex vitae " +
      "varius. Vestibulum blandit velit elementum, ornare " +
      "ipsum sollicitudin, blandit nunc. Mauris a sapien " +
      "nibh. Nulla nec bibendum quam, eu condimentum nisl. " +
      "Cras consequat efficitur nisi sed ornare. " +
      "Pellentesque vitae urna vitae libero malesuada " +
      "pharetra." +
      "\n\n" +
      "Pellentesque commodo, nulla mattis vulputate " +
      "porttitor, elit augue vestibulum est, nec congue " +
      "ex dui a velit. Nullam lectus leo, lobortis eget " +
      "erat ac, lobortis dignissim magna. Morbi ac odio " +
      "in purus blandit dignissim. Maecenas at sagittis " +
      "odio. Suspendisse tempus mattis erat id euismod. " +
      "Duis semper mauris nec odio sagittis vulputate. " +
      "Praesent varius ac erat id fringilla. Suspendisse " +
      "porta sollicitudin bibendum. Pellentesque imperdiet " +
      "at eros nec euismod. Etiam ac mattis odio, ac finibus " +
      "nisi.",true, 10)
    world.add SfA
    SfA.setBounds new Point(20, 25), new Point(390, 305)

  # this is provided for completeness, however see the
  # note in SimplePlainTextPanelWdgt about how this is
  # incomplete and why this widget is not useful anyways
  createNonWrappingSimplePlainTextPanelWdgt: ->
    SfB = new SimplePlainTextPanelWdgt(
      "Lorem ipsum dolor sit amet, consectetur adipiscing " +
      "elit. Integer rhoncus pharetra nulla, vel maximus " +
      "\n\n" +
      "Pellentesque commodo, nulla mattis vulputate " +
      "porttitor, elit augue vestibulum est, nec congue " +
      "nisi.",false, 10)
    world.add SfB
    SfB.setBounds new Point(430, 25), new Point(390, 305)

  # this is provided for completeness, however see the
  # note in SimplePlainTextPanelWdgt about how this is
  # incomplete and why this widget is not useful anyways
  createWrappingAndNonWrappingSimplePlainTextPanelWdgt: ->
    @createWrappingSimplePlainTextPanelWdgt()
    @createNonWrappingSimplePlainTextPanelWdgt()


  createSimpleDocumentScrollPanelWdgt: ->
    sdspw = new SimpleDocumentScrollPanelWdgt
    world.add sdspw
    # public setters on the ATTACHED panel self-settle in place (was _applyMoveTo/_applyExtent, whose raw
    # resize on an attached panel used to trip the now-deleted _announceGeometryChangeToContainer geom seam into an off-settle re-fit)
    sdspw.moveTo new Point 35, 30
    sdspw.setExtent new Point 370, 325

  popUpDocumentMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "Document"
    menu.addMenuItem "simple document scrollpanel", true, menusHelper, "createSimpleDocumentScrollPanelWdgt"
    menu.addMenuItem "simple document", true, menusHelper, "createSimpleDocumentWdgt"
    menu.popUpAtHand()

  popUpSimplePlainTextWdgtMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "Simple plain text"
    menu.addMenuItem "simple plain text wrapping", true, menusHelper, "createNewWrappingSimplePlainTextWdgtWithBackground"
    menu.addMenuItem "simple plain text not wrapping", true, menusHelper, "createNewNonWrappingSimplePlainTextWdgtWithBackground"
    menu.addMenuItem "simple plain text (wrapping / not wrapping)", true, menusHelper, "createNewWrappingAndNonWrappingSimplePlainTextWdgtWithBackground"
    menu.addMenuItem "simple plain text panel wrapping", true, menusHelper, "createWrappingSimplePlainTextPanelWdgt"
    menu.addMenuItem "simple plain text panel not wrapping", true, menusHelper, "createNonWrappingSimplePlainTextPanelWdgt"
    menu.addMenuItem "simple plain text panel (wrapping / not wrapping)", true, menusHelper, "createWrappingAndNonWrappingSimplePlainTextPanelWdgt"
    menu.addMenuItem "simple plain text scrollpanel wrapping", true, menusHelper, "createWrappingSimplePlainTextScrollPanelWdgt"
    menu.addMenuItem "simple plain text scrollpanel not wrapping", true, menusHelper, "createNonWrappingSimplePlainTextScrollPanelWdgt"
    menu.addMenuItem "simple plain text scrollpanel (wrapping / not wrapping)", true, menusHelper, "createWrappingAndNonWrappingSimplePlainTextScrollPanelWdgt"

    menu.popUpAtHand()

  createNewStringWdgtWithBackground: ->
    #newWdgt = new StringWdgt "Hello World! ⎲ƒ⎳⎷ ⎸⎹ aaa",nil,nil,nil,nil,nil,nil,nil, Color.create(255, 255, 54), 0.5
    newWdgt = new StringWdgt "Hello World! ⎲ƒ⎳⎷ ⎸⎹ aaa",nil,nil,nil,nil,nil,nil,nil, Color.create(230, 230, 130), 1
    newWdgt.isEditable = true
    world.create newWdgt

  createNewStringWdgtWithoutBackground: ->
    newWdgt = new StringWdgt "Hello World! ⎲ƒ⎳⎷ ⎸⎹ aaa"
    newWdgt.isEditable = true
    world.create newWdgt

  createNewTextWdgtWithBackground: ->
    newWdgt = new TextWdgt(
      "Lorem ipsum dolor sit amet, consectetur adipiscing " +
      "elit. Integer rhoncus pharetra nulla, vel maximus " +
      "lectus posuere a. Phasellus finibus blandit ex vitae " +
      "varius. Vestibulum blandit velit elementum, ornare " +
      "ipsum sollicitudin, blandit nunc. Mauris a sapien " +
      "nibh. Nulla nec bibendum quam, eu condimentum nisl. " +
      "Cras consequat efficitur nisi sed ornare. " +
      "Pellentesque vitae urna vitae libero malesuada " +
      "pharetra." +
      "\n\n" +
      "Pellentesque commodo, nulla mattis vulputate " +
      "porttitor, elit augue vestibulum est, nec congue " +
      "ex dui a velit. Nullam lectus leo, lobortis eget " +
      "erat ac, lobortis dignissim magna. Morbi ac odio " +
      "in purus blandit dignissim. Maecenas at sagittis " +
      "odio. Suspendisse tempus mattis erat id euismod. " +
      "Duis semper mauris nec odio sagittis vulputate. " +
      "Praesent varius ac erat id fringilla. Suspendisse " +
      "porta sollicitudin bibendum. Pellentesque imperdiet " +
      "at eros nec euismod. Etiam ac mattis odio, ac finibus " +
      "nisi.",nil,nil,nil,nil,nil,Color.create(230, 230, 130), 1)
    newWdgt.isEditable = true
    world.create newWdgt

  analogClock: ->
    world.create new AnalogClockWdgt

  testMenu: (widgetOpeningThePopUp,targetWidget)->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, targetWidget, true, true, nil
    menu.addMenuItem "serialise widget to memory", true, targetWidget, "serialiseToMemory"
    menu.addMenuItem "deserialize from memory and attach to world", true, targetWidget, "deserialiseFromMemoryAndAttachToWorld"
    menu.addMenuItem "deserialize from memory and attach to hand", true, targetWidget, "deserialiseFromMemoryAndAttachToHand"
    menu.addMenuItem "attach with horizontal layout", true, targetWidget, "attachWithHorizLayout"
    menu.addMenuItem "make spacers transparent", true, targetWidget, "makeSpacersTransparent"
    menu.addMenuItem "make spacers opaque", true, targetWidget, "makeSpacersOpaque"
    menu.addMenuItem "show adders", true, targetWidget, "showAdders"
    menu.addMenuItem "remove adders", true, targetWidget, "removeAdders"
    menu.addMenuItem "StringWdgt without background", true, menusHelper, "createNewStringWdgtWithoutBackground"
    menu.addMenuItem "StringWdgt with background", true, menusHelper, "createNewStringWdgtWithBackground"
    menu.addMenuItem "TextWdgt with background", true, menusHelper, "createNewTextWdgtWithBackground"
    if world.widgetsToBePinouted.has targetWidget
      menu.addMenuItem "remove output pins", true, targetWidget, "removeOutputPins"
    else
      menu.addMenuItem "show output pins", true, targetWidget, "showOutputPins"

    # unclear whether the "un-collapse" entry would ever be
    # visible.
    if targetWidget?
      if targetWidget.collapsed
        menu.addMenuItem "un-collapse", true, targetWidget, "unCollapse"
      else
        menu.addMenuItem "collapse", true, targetWidget, "collapse"

    menu.addMenuItem "others ➜", false, menusHelper, "popUpFirstMenu", "others"
    menu.addMenuItem "others 2 ➜", false, menusHelper, "popUpSecondMenu", "others"


    menu.popUpAtHand()

  popUpFirstMenu: (widgetOpeningThePopUp, widgetThisMenuIsAbout) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "others"
    menu.addMenuItem "make sliders' buttons states bright", true, menusHelper, "makeSlidersButtonsStatesBright"
    menu.addMenuItem "make pointer", true, widgetThisMenuIsAbout, "createPointerWdgt"
    menu.addMenuItem "icon with text", true, menusHelper, "makeIconWithText"
    menu.addMenuItem "empty icon with text", true, menusHelper, "makeEmptyIconWithText"
    menu.addMenuItem "generic reference icon", true, menusHelper, "makeGenericReferenceIcon"
    menu.addMenuItem "generic object icon", true, menusHelper, "makeGenericObjectIcon"
    menu.addMenuItem "folder window", true, menusHelper, "makeFolderWindow"
    menu.addMenuItem "bouncing particle", true, menusHelper, "makeBouncingParticle"
    menu.addMenuItem "throw an error", true, menusHelper, "throwAnError"
    menu.addMenuItem "stretchable panel", true, menusHelper, "createStretchablePanel"
    menu.addMenuItem "tools panel", true, menusHelper, "createToolsPanel"
    menu.addMenuItem "horiz. menu panel", true, menusHelper, "createHorizontalMenuPanelPanel"
    menu.addMenuItem "Simple slide", true, menusHelper, "createSimpleSlideWdgt"
    menu.addMenuItem "patch programming ➜", false, menusHelper, "popUpPatchProgrammingMenu", "icons"
    menu.addMenuItem "graphs ➜", false, menusHelper, "popUpGraphsMenu", "graphs"
    menu.addMenuItem "support docs ➜", false, menusHelper, "popUpSupportDocsMenu", "support docs"

    menu.popUpAtHand()

  popUpSecondMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp,  false, @, true, true, "others"
    menu.addMenuItem "icons ➜", false, menusHelper, "popUpIconsMenu", "icons"
    menu.addMenuItem "simple plain text ➜", false, menusHelper, "popUpSimplePlainTextWdgtMenu", "icons"
    menu.addMenuItem "vertical stack ➜", false, menusHelper, "popUpVerticalStackMenu", "icons"
    menu.addMenuItem "document ➜", false, menusHelper, "popUpDocumentMenu", "icons"
    menu.addMenuItem "windows ➜", false, menusHelper, "popUpWindowsMenu", "icons"
    menu.addMenuItem "shortcuts & scripts ➜", false, menusHelper, "popUpShortcutsAndScriptsMenu", "Shortcuts & Scripts"
    menu.addMenuItem "analog clock", true, menusHelper, "analogClock"
    menu.addMenuItem "dev tools ➜", false, menusHelper, "popUpDevToolsMenu", "icons"
    menu.addMenuItem "fizzytiles", true, menusHelper, "createFridgeMagnets"
    menu.addMenuItem "fizzypaint", true, menusHelper, "createReconfigurablePaint"
    menu.addMenuItem "simple button", true, menusHelper, "createSimpleButton"
    menu.addMenuItem "switch button", true, menusHelper, "createSwitchButtonWdgt"
    menu.addMenuItem "clipping box", true, menusHelper, "createNewClippingBoxWdgt"

    menu.popUpAtHand()

  # this part is excluded from the fizzygum homepage build <<«

  # »>> this part is only needed for Macros
  testMenuForMacros: ->
    menu = new MenuWdgt world, false, world, true, true, "Tests"
    menu.addMenuItem "create desktop", true, world, "createDesktop"


    menu.addMenuItem "attach with horizontal layout", true, world, "attachWithHorizLayout"
    menu.addMenuItem "make spacers transparent", true, world, "makeSpacersTransparent"
    menu.addMenuItem "make spacers opaque", true, world, "makeSpacersOpaque"
    menu.addMenuItem "show adders", true, world, "showAdders"
    menu.addMenuItem "remove adders", true, world, "removeAdders"
    menu.addMenuItem "StringWdgt without background", true, menusHelper, "createNewStringWdgtWithoutBackground"
    menu.addMenuItem "StringWdgt with background", true, menusHelper, "createNewStringWdgtWithBackground"
    menu.addMenuItem "TextWdgt with background", true, menusHelper, "createNewTextWdgtWithBackground"

    menu.addMenuItem "others ➜", false, menusHelper, "popUpFirstMenu", "others"
    menu.addMenuItem "others 2 ➜", false, menusHelper, "popUpSecondMenu", "others"


    menu.popUpAtHand()
  # this part is only needed for Macros <<«

  createWelcomeMessageWindowAndShortcut: ->
    wm = WelcomeMessageInfoWdgt.create()
    readmeLauncher = new IconicDesktopSystemDocumentShortcutWdgt wm, "Welcome", new WelcomeIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add readmeLauncher
    readmeLauncher.setExtent new Point 75, 75
    readmeLauncher.fullChanged()

