# All "actions" functions for all accessory menu items should belong
# in here. Also helps so we don't pollute moprhs with a varying number
# of helper functions, which is problematic for visual diffing
# on inspectors (the number of methods keeps changing).

class MenusHelper

  @augmentWith DeepCopierMixin

  # Placeholder body text reused verbatim by the demo text-widget menu actions below, hoisted to two
  # constants so each string lives (and is edited) in one place. LOREM_LONG: 4 sites; LOREM_SHORT: 2 sites.
  # (The one medium-length variant in createNewNonWrappingSimplePlainTextWdgtWithBackground is unique, so
  # it stays inline.) Kept as the exact same "+"-concatenation the call sites used, so the value is identical.
  LOREM_LONG:
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
    "nisi."

  LOREM_SHORT:
    "Lorem ipsum dolor sit amet, consectetur adipiscing " +
    "elit. Integer rhoncus pharetra nulla, vel maximus " +
    "\n\n" +
    "Pellentesque commodo, nulla mattis vulputate " +
    "porttitor, elit augue vestibulum est, nec congue " +
    "nisi."

  popUpDevToolsMenu: (widgetOpeningThePopUp, widgetThisMenuIsAbout) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Dev Tools"
    menu.addMenuItem "inspect", widgetThisMenuIsAbout, "inspect", toolTip: "open a window\non all properties"
    menu.addMenuItem "console", widgetThisMenuIsAbout, "createConsole", toolTip: "console"

    menu.popUpAtHand()


  # »>> this part is excluded from the fizzygum homepage build
  createFridgeMagnets: ->
    fmm = new FridgeMagnetsWdgt
    world.openFrameWith fmm, (new Point 570, 400), world.hand.position()


  createReconfigurablePaint: ->
    reconfPaint = new ReconfigurablePaintWdgt
    world.openFrameWith reconfPaint, (new Point 460, 400), world.hand.position()

  createSimpleSlideWdgt: ->
    simpleSlide = new SimpleSlideWdgt
    world.openFrameWith simpleSlide, (new Point 460, 400), world.hand.position()

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
    world.openFrameWith scriptWdgt, (new Point 460, 400), world.hand.position().subtract(new Point 50, 100)
  # this part is excluded from the fizzygum homepage build <<«

  # »>> this part is excluded from the fizzygum homepage build
  createFanout: ->
    fanoutWdgt = new FanoutWdgt
    world.create fanoutWdgt
    fanoutWdgt.setExtent new Point 100, 100

  createCalculatingPatchNode: ->
    calculatingPatchNodeWdgt = new CalculatingPatchNodeWdgt
    world.openFrameWith calculatingPatchNodeWdgt, (new Point 460, 400), world.hand.position().subtract(new Point 50, 100)

  createDiffingPatchNode: ->
    diffingPatchNodeWdgt = new DiffingPatchNodeWdgt
    world.openFrameWith diffingPatchNodeWdgt, (new Point 460, 400), world.hand.position().subtract(new Point 50, 100)

  createSliderWithSmallestValueAtBottomEnd: ->
    world.create new SliderWdgt nil, nil, nil, nil, nil, true

  createRegexSubstitutionPatchNodeWdgt: ->
    regexSubstitutionPatchNodeWdgt = new RegexSubstitutionPatchNodeWdgt
    world.openFrameWith regexSubstitutionPatchNodeWdgt, (new Point 460, 400), world.hand.position().subtract(new Point 50, 100)

  throwAnError: ->
    throw new Error "you manually threw an error!"

  createStretchablePanel: ->
    stretchablePanel = new StretchableWidgetContainerWdgt
    world.create stretchablePanel
    stretchablePanel.setExtent new Point 400, 300

  createToolsPanel: ->
    toolPanel = new ScrollPanelWdgt new ToolPanelWdgt
    world.openFrameWith toolPanel, (new Point 200, 400), world.hand.position().subtract(new Point 50, 100)

  createHorizontalMenuPanelPanel: ->
    horizontalMenuPanel = new HorizontalMenuPanelWdgt
    world.openFrameWith horizontalMenuPanel, (new Point 200, 400), world.hand.position().subtract(new Point 50, 100)


  popUpMore1IconsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "More Icons 1"
    menu.addMenuItem "Pencil 1 icon", menusHelper, "createPencil1IconWdgt"
    menu.addMenuItem "Pencil 2 icon", menusHelper, "createPencil2IconWdgt"
    menu.addMenuItem "Brush icon", menusHelper, "createBrushIconWdgt"
    menu.addMenuItem "Toothpaste icon", menusHelper, "createToothpasteIconWdgt"
    menu.addMenuItem "Eraser icon", menusHelper, "createEraserIconWdgt"
    menu.addMenuItem "Trashcan icon", menusHelper, "createTrashcanIconWdgt"
    menu.addMenuItem "Shortcut arrow icon", menusHelper, "createShortcutArrowIconWdgt"
    menu.addMenuItem "Raster pic icon", menusHelper, "createRasterPicIconWdgt"
    menu.addMenuItem "Paint bucket icon", menusHelper, "createPaintBucketIconWdgt"
    menu.addMenuItem "Object icon", menusHelper, "createObjectIconWdgt"
    menu.addMenuItem "Folder icon", menusHelper, "createFolderIconWdgt"
    menu.addMenuItem "Basement icon", menusHelper, "createBasementIconWdgt"
    menu.addMenuItem "Widget icon", menusHelper, "createWidgetIconWdgt"
    menu.popUpAtHand()

  popUpMore2IconsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "More Icons 2"
    menu.addMenuItem "Format as code icon", menusHelper, "createFormatAsCodeIconWdgt"
    menu.addMenuItem "Ch. X icon", menusHelper, "createChXIconWdgt"
    menu.addMenuItem "Ch. X.X icon", menusHelper, "createChXXIconWdgt"
    menu.addMenuItem "Ch. X.X.X icon", menusHelper, "createChXXXIconWdgt"
    menu.addMenuItem "Align right icon", menusHelper, "createAlignRightIconWdgt"
    menu.addMenuItem "Align center icon", menusHelper, "createAlignCenterIconWdgt"
    menu.addMenuItem "Align left icon", menusHelper, "createAlignLeftIconWdgt"
    menu.addMenuItem "Bold icon", menusHelper, "createBoldIconWdgt"
    menu.addMenuItem "Italic icon", menusHelper, "createItalicIconWdgt"
    menu.addMenuItem "Information icon", menusHelper, "createInformationIconWdgt"
    menu.addMenuItem "Textbox icon", menusHelper, "createTextboxIconWdgt"
    menu.addMenuItem "Video play icon", menusHelper, "createVideoPlayIconWdgt"

    menu.addMenuItem "Decrease font size icon", menusHelper, "createDecreaseFontSizeIconWdgt"
    menu.addMenuItem "Increase font size icon", menusHelper, "createIncreaseFontSizeIconWdgt"
    menu.addMenuItem "External link icon", menusHelper, "createExternalLinkIconWdgt"
    menu.addMenuItem "Templates icon", menusHelper, "createTemplatesIconWdgt"

    menu.popUpAtHand()

  popUpMore3IconsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "More Icons 2"
    menu.addMenuItem "Fizzygum logo", menusHelper, "createFizzygumLogoIconWdgt"
    menu.addMenuItem "Fizzygum logo with text", menusHelper, "createFizzygumLogoWithTextIconWdgt"
    menu.addMenuItem "Vaporwave sun", menusHelper, "createVaporwaveSunIconWdgt"
    menu.addMenuItem "Vaporwave background", menusHelper, "createVaporwaveBackgroundIconWdgt"
    menu.addMenuItem "Change font icon", menusHelper, "createChangeFontIconWdgt"
    menu.addMenuItem "C <-> F converter icon", menusHelper, "createCFDegreesConverterIconWdgt"
    menu.addMenuItem "Simple slide icon", menusHelper, "createSimpleSlideIconWdgt"
    menu.addMenuItem "Typewriter icon", menusHelper, "createTypewriterIconWdgt"
    menu.addMenuItem "Little world icon", menusHelper, "createLittleWorldIconWdgt"
    menu.addMenuItem "Little USA icon", menusHelper, "createLittleUSAIconWdgt"
    menu.addMenuItem "Map pin icon", menusHelper, "createMapPinIconWdgt"
    menu.addMenuItem "Save icon", menusHelper, "createSaveIconWdgt"

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
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Arrows"
    menu.addMenuItem "Arrow N icon", menusHelper, "createArrowNIconWdgt"
    menu.addMenuItem "Arrow S icon", menusHelper, "createArrowSIconWdgt"
    menu.addMenuItem "Arrow W icon", menusHelper, "createArrowWIconWdgt"
    menu.addMenuItem "Arrow E icon", menusHelper, "createArrowEIconWdgt"
    menu.addMenuItem "Arrow NW icon", menusHelper, "createArrowNWIconWdgt"
    menu.addMenuItem "Arrow NE icon", menusHelper, "createArrowNEIconWdgt"
    menu.addMenuItem "Arrow SE icon", menusHelper, "createArrowSEIconWdgt"
    menu.addMenuItem "Arrow SW icon", menusHelper, "createArrowSWIconWdgt"
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
    world.openFrameWith simpleDocument, (new Point 368, 335), world.hand.position().subtract(new Point 50, 100)

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
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Maps"
    menu.addMenuItem "world map", menusHelper, "createWorldMapIconWdgt", toolTip: "others"
    menu.addMenuItem "USA map", menusHelper, "createUSAMapIconWdgt", toolTip: "others"

    menu.popUpAtHand()

  popUpGraphsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "graphs"
    menu.addMenuItem "axis", menusHelper, "create2DAxis"
    menu.addMenuItem "scatter plot", menusHelper, "createExampleScatterPlot"
    menu.addMenuItem "scatter plot with axes", menusHelper, "createExampleScatterPlotWithAxes"
    menu.addMenuItem "function plot", menusHelper, "createExampleFunctionPlot"
    menu.addMenuItem "bar plot", menusHelper, "createExampleBarPlot"
    menu.addMenuItem "3D plot", menusHelper, "createExample3DPlot"

    menu.popUpAtHand()

  popUpSupportDocsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Support Docs"
    menu.addMenuItem "welcome message", @, "createWelcomeMessageWindowAndShortcut", toolTip: "welcome message"

    menu.popUpAtHand()

  popUpPatchProgrammingMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Patch Programming"
    menu.addMenuItem "fanout", menusHelper, "createFanout"
    menu.addMenuItem "calculating node", menusHelper, "createCalculatingPatchNode"
    menu.addMenuItem "diffing node", menusHelper, "createDiffingPatchNode"
    menu.addMenuItem "slider", menusHelper, "createSliderWithSmallestValueAtBottomEnd"
    menu.addMenuItem "regex subst. node", menusHelper, "createRegexSubstitutionPatchNodeWdgt"
    menu.popUpAtHand()

  popUpVerticalStackMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Vertical stack"
    menu.addMenuItem "vertical stack constrained contents width", menusHelper, "createSimpleVerticalStackPanelWdgt"
    menu.addMenuItem "vertical stack scrollpanel constrained contents width", menusHelper, "createSimpleVerticalStackScrollPanelWdgt"
    menu.addMenuItem "vertical stack panel and scrollpanel constrained contents width", menusHelper, "createSimpleVerticalStackPanelWdgtAndScrollPanel"
    menu.addMenuItem "vertical stack free contents width", menusHelper, "createSimpleVerticalStackPanelWdgtFreeContentsWidth"
    menu.addMenuItem "vertical stack scrollpanel free contents width", menusHelper, "createSimpleVerticalStackScrollPanelWdgtFreeContentsWidth"
    menu.addMenuItem "vertical stack panel and scrollpanel free contents width", menusHelper, "createSimpleVerticalStackPanelWdgtAndScrollPanelFreeContentsWidth"

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
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "icons"
    menu.addMenuItem "Destroy icon", menusHelper, "createDestroyIconWdgt"
    menu.addMenuItem "Under the carpet icon", menusHelper, "createUnderCarpetIconWdgt"
    menu.addMenuItem "Collapsed state icon", menusHelper, "createCollapsedStateIconWdgt"
    menu.addMenuItem "Uncollapsed state icon", menusHelper, "createUncollapsedStateIconWdgt"
    menu.addMenuItem "Close icon", menusHelper, "createCloseIconButtonWdgt"
    menu.addMenuItem "Scratch area icon", menusHelper, "createScratchAreaIconWdgt"
    menu.addMenuItem "Flora icon", menusHelper, "createFloraIconWdgt"
    menu.addMenuItem "Scooter icon", menusHelper, "createScooterIconWdgt"
    menu.addMenuItem "Heart icon", menusHelper, "createHeartIconWdgt"

    menu.addMenuItem "more 1 ➜", menusHelper, "popUpMore1IconsMenu", closesUnpinnedPopUps: false, toolTip: "others"
    menu.addMenuItem "more 2 ➜", menusHelper, "popUpMore2IconsMenu", closesUnpinnedPopUps: false, toolTip: "others"
    menu.addMenuItem "arrows ➜", menusHelper, "popUpArrowsIconsMenu", closesUnpinnedPopUps: false, toolTip: "others"
    menu.addMenuItem "maps ➜", menusHelper, "popUpMapsMenu", closesUnpinnedPopUps: false, toolTip: "maps"
    menu.addMenuItem "more 3 ➜", menusHelper, "popUpMore3IconsMenu", closesUnpinnedPopUps: false, toolTip: "maps"

    menu.popUpAtHand()

  popUpWindowsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Windows"
    menu.addMenuItem "empty window", menusHelper, "createEmptyWindow"
    menu.addMenuItem "empty internal window", menusHelper, "createEmptyInternalWindow"

    menu.popUpAtHand()

  popUpShortcutsAndScriptsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Shortcuts & Scripts"
    menu.addMenuItem "basement shortcut", menusHelper, "basementIconAndText"
    menu.addMenuItem "new script", menusHelper, "newScriptWindow"
    menu.addMenuItem "Fizzypaint launcher", (new FizzyPaintApp), "createOpener"
    menu.addMenuItem "Simple doc launcher", (new SimpleDocumentApp), "createOpener"
    menu.addMenuItem "Simple slide launcher", (new SimpleSlideApp), "createOpener"
    menu.addMenuItem "Link", menusHelper, "createSimpleLinkWdgt"
    menu.addMenuItem "Video link", menusHelper, "createSimpleVideoLinkWdgt"
    menu.popUpAtHand()

  createEmptyInternalWindow: ->
    wm = new FrameWdgt()
    wm.moveTo world.hand.position()
    wm.moveWithin world
    world.add wm

  createEmptyWindow: ->
    wm = new FrameWdgt()
    wm.moveTo world.hand.position()
    wm.moveWithin world
    world.add wm

  createNewWrappingSimplePlainTextWdgtWithBackground: ->
    newWdgt = new SimplePlainTextWdgt(
      @LOREM_LONG,nil,nil,nil,nil,nil,Color.create(230, 230, 130), 1)
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
      @LOREM_LONG,true, 10)
    world.add SfA
    SfA.setBounds new Point(20, 25), new Point(390, 305)

  createNonWrappingSimplePlainTextScrollPanelWdgt: ->
    SfB = new SimplePlainTextScrollPanelWdgt(
      @LOREM_SHORT,false, 10)
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
      @LOREM_LONG,true, 10)
    world.add SfA
    SfA.setBounds new Point(20, 25), new Point(390, 305)

  # this is provided for completeness, however see the
  # note in SimplePlainTextPanelWdgt about how this is
  # incomplete and why this widget is not useful anyways
  createNonWrappingSimplePlainTextPanelWdgt: ->
    SfB = new SimplePlainTextPanelWdgt(
      @LOREM_SHORT,false, 10)
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
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Document"
    menu.addMenuItem "simple document scrollpanel", menusHelper, "createSimpleDocumentScrollPanelWdgt"
    menu.addMenuItem "simple document", menusHelper, "createSimpleDocumentWdgt"
    menu.popUpAtHand()

  popUpSimplePlainTextWdgtMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Simple plain text"
    menu.addMenuItem "simple plain text wrapping", menusHelper, "createNewWrappingSimplePlainTextWdgtWithBackground"
    menu.addMenuItem "simple plain text not wrapping", menusHelper, "createNewNonWrappingSimplePlainTextWdgtWithBackground"
    menu.addMenuItem "simple plain text (wrapping / not wrapping)", menusHelper, "createNewWrappingAndNonWrappingSimplePlainTextWdgtWithBackground"
    menu.addMenuItem "simple plain text panel wrapping", menusHelper, "createWrappingSimplePlainTextPanelWdgt"
    menu.addMenuItem "simple plain text panel not wrapping", menusHelper, "createNonWrappingSimplePlainTextPanelWdgt"
    menu.addMenuItem "simple plain text panel (wrapping / not wrapping)", menusHelper, "createWrappingAndNonWrappingSimplePlainTextPanelWdgt"
    menu.addMenuItem "simple plain text scrollpanel wrapping", menusHelper, "createWrappingSimplePlainTextScrollPanelWdgt"
    menu.addMenuItem "simple plain text scrollpanel not wrapping", menusHelper, "createNonWrappingSimplePlainTextScrollPanelWdgt"
    menu.addMenuItem "simple plain text scrollpanel (wrapping / not wrapping)", menusHelper, "createWrappingAndNonWrappingSimplePlainTextScrollPanelWdgt"

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
      @LOREM_LONG,nil,nil,nil,nil,nil,Color.create(230, 230, 130), 1)
    newWdgt.isEditable = true
    world.create newWdgt

  analogClock: ->
    world.create new AnalogClockWdgt

  testMenu: (widgetOpeningThePopUp,targetWidget)->
    menu = new MenuWdgt widgetOpeningThePopUp, target: targetWidget
    menu.addMenuItem "serialise widget to memory", targetWidget, "serialiseToMemory"
    menu.addMenuItem "deserialize from memory and attach to world", targetWidget, "deserialiseFromMemoryAndAttachToWorld"
    menu.addMenuItem "deserialize from memory and attach to hand", targetWidget, "deserialiseFromMemoryAndAttachToHand"
    menu.addMenuItem "attach with horizontal layout", targetWidget, "attachWithHorizLayout"
    menu.addMenuItem "make spacers transparent", targetWidget, "makeSpacersTransparent"
    menu.addMenuItem "make spacers opaque", targetWidget, "makeSpacersOpaque"
    menu.addMenuItem "show adders", targetWidget, "showAdders"
    menu.addMenuItem "remove adders", targetWidget, "removeAdders"
    menu.addMenuItem "StringWdgt without background", menusHelper, "createNewStringWdgtWithoutBackground"
    menu.addMenuItem "StringWdgt with background", menusHelper, "createNewStringWdgtWithBackground"
    menu.addMenuItem "TextWdgt with background", menusHelper, "createNewTextWdgtWithBackground"
    if world.widgetsToBePinouted.has targetWidget
      menu.addMenuItem "remove output pins", targetWidget, "removeOutputPins"
    else
      menu.addMenuItem "show output pins", targetWidget, "showOutputPins"

    # unclear whether the "un-collapse" entry would ever be
    # visible.
    if targetWidget?
      if targetWidget.collapsed
        menu.addMenuItem "un-collapse", targetWidget, "unCollapse"
      else
        menu.addMenuItem "collapse", targetWidget, "collapse"

    menu.addMenuItem "others ➜", menusHelper, "popUpFirstMenu", closesUnpinnedPopUps: false, toolTip: "others"
    menu.addMenuItem "others 2 ➜", menusHelper, "popUpSecondMenu", closesUnpinnedPopUps: false, toolTip: "others"


    menu.popUpAtHand()

  popUpFirstMenu: (widgetOpeningThePopUp, widgetThisMenuIsAbout) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "others"
    menu.addMenuItem "make sliders' buttons states bright", menusHelper, "makeSlidersButtonsStatesBright"
    menu.addMenuItem "make pointer", widgetThisMenuIsAbout, "createPointerWdgt"
    menu.addMenuItem "icon with text", menusHelper, "makeIconWithText"
    menu.addMenuItem "empty icon with text", menusHelper, "makeEmptyIconWithText"
    menu.addMenuItem "generic reference icon", menusHelper, "makeGenericReferenceIcon"
    menu.addMenuItem "generic object icon", menusHelper, "makeGenericObjectIcon"
    menu.addMenuItem "folder window", menusHelper, "makeFolderWindow"
    menu.addMenuItem "bouncing particle", menusHelper, "makeBouncingParticle"
    menu.addMenuItem "throw an error", menusHelper, "throwAnError"
    menu.addMenuItem "stretchable panel", menusHelper, "createStretchablePanel"
    menu.addMenuItem "tools panel", menusHelper, "createToolsPanel"
    menu.addMenuItem "horiz. menu panel", menusHelper, "createHorizontalMenuPanelPanel"
    menu.addMenuItem "Simple slide", menusHelper, "createSimpleSlideWdgt"
    menu.addMenuItem "patch programming ➜", menusHelper, "popUpPatchProgrammingMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "graphs ➜", menusHelper, "popUpGraphsMenu", closesUnpinnedPopUps: false, toolTip: "graphs"
    menu.addMenuItem "support docs ➜", menusHelper, "popUpSupportDocsMenu", closesUnpinnedPopUps: false, toolTip: "support docs"

    menu.popUpAtHand()

  popUpSecondMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "others"
    menu.addMenuItem "icons ➜", menusHelper, "popUpIconsMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "simple plain text ➜", menusHelper, "popUpSimplePlainTextWdgtMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "vertical stack ➜", menusHelper, "popUpVerticalStackMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "document ➜", menusHelper, "popUpDocumentMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "windows ➜", menusHelper, "popUpWindowsMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "shortcuts & scripts ➜", menusHelper, "popUpShortcutsAndScriptsMenu", closesUnpinnedPopUps: false, toolTip: "Shortcuts & Scripts"
    menu.addMenuItem "analog clock", menusHelper, "analogClock"
    menu.addMenuItem "dev tools ➜", menusHelper, "popUpDevToolsMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "fizzytiles", menusHelper, "createFridgeMagnets"
    menu.addMenuItem "fizzypaint", menusHelper, "createReconfigurablePaint"
    menu.addMenuItem "simple button", menusHelper, "createSimpleButton"
    menu.addMenuItem "switch button", menusHelper, "createSwitchButtonWdgt"
    menu.addMenuItem "clipping box", menusHelper, "createNewClippingBoxWdgt"

    menu.popUpAtHand()

  # this part is excluded from the fizzygum homepage build <<«

  # »>> this part is only needed for Macros
  testMenuForMacros: ->
    menu = new MenuWdgt world, target: world, title: "Tests"
    menu.addMenuItem "create desktop", world, "createDesktop"


    menu.addMenuItem "attach with horizontal layout", world, "attachWithHorizLayout"
    menu.addMenuItem "make spacers transparent", world, "makeSpacersTransparent"
    menu.addMenuItem "make spacers opaque", world, "makeSpacersOpaque"
    menu.addMenuItem "show adders", world, "showAdders"
    menu.addMenuItem "remove adders", world, "removeAdders"
    menu.addMenuItem "StringWdgt without background", menusHelper, "createNewStringWdgtWithoutBackground"
    menu.addMenuItem "StringWdgt with background", menusHelper, "createNewStringWdgtWithBackground"
    menu.addMenuItem "TextWdgt with background", menusHelper, "createNewTextWdgtWithBackground"

    menu.addMenuItem "others ➜", menusHelper, "popUpFirstMenu", closesUnpinnedPopUps: false, toolTip: "others"
    menu.addMenuItem "others 2 ➜", menusHelper, "popUpSecondMenu", closesUnpinnedPopUps: false, toolTip: "others"


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

