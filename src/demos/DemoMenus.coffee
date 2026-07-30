# The DEMO / parts-bin menus: the "demo ➜" catalogue, the icon galleries, the widget and
# layout sample factories, and the test menu they hang off.
#
# This is the bulk of what used to be MenusHelper. Before arc 3, 689 of that class's 758
# lines sat inside `»>>` markers (the retired region-exclusion mechanism) — i.e. MenusHelper
# was already a demo class with three product members stranded inside it. Arc 3 split it the
# way the sizes suggest: the demo content moved HERE and the file carries a whole-file marker
# (arc 4 turns that into part membership), while MenusHelper keeps only what ships.
#
# Reached as `demoMenus`, built in globalFunctions behind `if DemoMenus?` — the collaborator
# pattern (cf. `world.widgetFactory`, `world.pinouts`). Menu items name it as their target;
# the few that point at a surviving MenusHelper member still say `menusHelper`.
class DemoMenus

  # Placeholder body text reused verbatim by the demo text-widget menu actions below, hoisted to two
  # constants so each string lives (and is edited) in one place. LOREM_LONG: 4 sites; LOREM_SHORT: 2 sites.
  # (The one medium-length variant in createNewNonWrappingSimpleTextWdgtWithBackground is unique, so
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

  # The demo menu's route to the same widget the desktop launcher opens. FridgeMagnetsWdgt is in the
  # LAZY 'fizzytiles' part, so it may not be in the page yet -- go through the parts API, which
  # loads it if needed and hands back the instance. (A `if FridgeMagnetsWdgt?` guard would be wrong
  # here for the same reason as in FridgeMagnetsApp.launch: for a lazy part it means "silently do
  # nothing".) Menu actions are fire-and-forget, so returning a promise changes nothing for callers.
  createFridgeMagnets: ->
    world.parts.launch("FridgeMagnetsWdgt").then (fmm) ->
      world.openFrameWith fmm, (new Point 570, 400), world.hand.position()


  createImageWdgt: ->
    world.openFrameWith (new ImageWdgt), (new Point 460, 400), world.hand.position()

  createSlideWdgt: ->
    world.openFrameWith (new SlideWdgt), (new Point 460, 400), world.hand.position()

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

  createBinIconWdgt: ->
    world.create new BinIconWdgt

  createWidgetIconWdgt: ->
    world.create new WidgetIconWdgt

  makeGenericReferenceIcon: ->
    world.create new GenericShortcutIconWdgt

  makeGenericObjectIcon: ->
    world.create new GenericObjectIconWdgt



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

  popUpMore1IconsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "More Icons 1"
    menu.addMenuItem "Pencil 1 icon", demoMenus, "createPencil1IconWdgt"
    menu.addMenuItem "Pencil 2 icon", demoMenus, "createPencil2IconWdgt"
    menu.addMenuItem "Brush icon", demoMenus, "createBrushIconWdgt"
    menu.addMenuItem "Toothpaste icon", demoMenus, "createToothpasteIconWdgt"
    menu.addMenuItem "Eraser icon", demoMenus, "createEraserIconWdgt"
    menu.addMenuItem "Shortcut arrow icon", demoMenus, "createShortcutArrowIconWdgt"
    menu.addMenuItem "Raster pic icon", demoMenus, "createRasterPicIconWdgt"
    menu.addMenuItem "Paint bucket icon", demoMenus, "createPaintBucketIconWdgt"
    menu.addMenuItem "Object icon", demoMenus, "createObjectIconWdgt"
    menu.addMenuItem "Folder icon", demoMenus, "createFolderIconWdgt"
    menu.addMenuItem "Bin icon", demoMenus, "createBinIconWdgt"
    menu.addMenuItem "Widget icon", demoMenus, "createWidgetIconWdgt"
    menu.popUpAtHand()

  popUpMore2IconsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "More Icons 2"
    menu.addMenuItem "Format as code icon", demoMenus, "createFormatAsCodeIconWdgt"
    menu.addMenuItem "Ch. X icon", demoMenus, "createChXIconWdgt"
    menu.addMenuItem "Ch. X.X icon", demoMenus, "createChXXIconWdgt"
    menu.addMenuItem "Ch. X.X.X icon", demoMenus, "createChXXXIconWdgt"
    menu.addMenuItem "Align right icon", demoMenus, "createAlignRightIconWdgt"
    menu.addMenuItem "Align center icon", demoMenus, "createAlignCenterIconWdgt"
    menu.addMenuItem "Align left icon", demoMenus, "createAlignLeftIconWdgt"
    menu.addMenuItem "Bold icon", demoMenus, "createBoldIconWdgt"
    menu.addMenuItem "Italic icon", demoMenus, "createItalicIconWdgt"
    menu.addMenuItem "Information icon", demoMenus, "createInformationIconWdgt"
    menu.addMenuItem "Textbox icon", demoMenus, "createTextboxIconWdgt"
    menu.addMenuItem "Video play icon", demoMenus, "createVideoPlayIconWdgt"

    menu.addMenuItem "Decrease font size icon", demoMenus, "createDecreaseFontSizeIconWdgt"
    menu.addMenuItem "Increase font size icon", demoMenus, "createIncreaseFontSizeIconWdgt"
    menu.addMenuItem "External link icon", demoMenus, "createExternalLinkIconWdgt"
    menu.addMenuItem "Templates icon", demoMenus, "createTemplatesIconWdgt"

    menu.popUpAtHand()

  popUpMore3IconsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "More Icons 2"
    menu.addMenuItem "Fizzygum logo", demoMenus, "createFizzygumLogoIconWdgt"
    menu.addMenuItem "Fizzygum logo with text", demoMenus, "createFizzygumLogoWithTextIconWdgt"
    menu.addMenuItem "Vaporwave sun", demoMenus, "createVaporwaveSunIconWdgt"
    menu.addMenuItem "Vaporwave background", demoMenus, "createVaporwaveBackgroundIconWdgt"
    menu.addMenuItem "Change font icon", demoMenus, "createChangeFontIconWdgt"
    menu.addMenuItem "C <-> F converter icon", demoMenus, "createCFDegreesConverterIconWdgt"
    menu.addMenuItem "Simple slide icon", demoMenus, "createSimpleSlideIconWdgt"
    menu.addMenuItem "Typewriter icon", demoMenus, "createTypewriterIconWdgt"
    menu.addMenuItem "Little world icon", demoMenus, "createLittleWorldIconWdgt"
    menu.addMenuItem "Little USA icon", demoMenus, "createLittleUSAIconWdgt"
    menu.addMenuItem "Map pin icon", demoMenus, "createMapPinIconWdgt"
    menu.addMenuItem "Save icon", demoMenus, "createSaveIconWdgt"

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
    menu.addMenuItem "Arrow N icon", demoMenus, "createArrowNIconWdgt"
    menu.addMenuItem "Arrow S icon", demoMenus, "createArrowSIconWdgt"
    menu.addMenuItem "Arrow W icon", demoMenus, "createArrowWIconWdgt"
    menu.addMenuItem "Arrow E icon", demoMenus, "createArrowEIconWdgt"
    menu.addMenuItem "Arrow NW icon", demoMenus, "createArrowNWIconWdgt"
    menu.addMenuItem "Arrow NE icon", demoMenus, "createArrowNEIconWdgt"
    menu.addMenuItem "Arrow SE icon", demoMenus, "createArrowSEIconWdgt"
    menu.addMenuItem "Arrow SW icon", demoMenus, "createArrowSWIconWdgt"
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

  createDocumentWdgt: ->
    world.openFrameWith (new DocumentWdgt), (new Point 368, 335), world.hand.position().subtract(new Point 50, 100)

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
    menu.addMenuItem "world map", demoMenus, "createWorldMapIconWdgt", toolTip: "others"
    menu.addMenuItem "USA map", demoMenus, "createUSAMapIconWdgt", toolTip: "others"

    menu.popUpAtHand()

  popUpGraphsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "graphs"
    menu.addMenuItem "axis", demoMenus, "create2DAxis"
    menu.addMenuItem "scatter plot", demoMenus, "createExampleScatterPlot"
    menu.addMenuItem "scatter plot with axes", demoMenus, "createExampleScatterPlotWithAxes"
    menu.addMenuItem "function plot", demoMenus, "createExampleFunctionPlot"
    menu.addMenuItem "bar plot", demoMenus, "createExampleBarPlot"
    menu.addMenuItem "3D plot", demoMenus, "createExample3DPlot"

    menu.popUpAtHand()

  popUpSupportDocsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Support Docs"
    menu.addMenuItem "welcome message", @, "createWelcomeMessageWindowAndShortcut", toolTip: "welcome message"

    menu.popUpAtHand()

  popUpPatchProgrammingMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Patch Programming"
    menu.addMenuItem "fanout", demoMenus, "createFanout"
    menu.addMenuItem "calculating node", demoMenus, "createCalculatingPatchNode"
    menu.addMenuItem "diffing node", demoMenus, "createDiffingPatchNode"
    menu.addMenuItem "slider", demoMenus, "createSliderWithSmallestValueAtBottomEnd"
    menu.addMenuItem "regex subst. node", demoMenus, "createRegexSubstitutionPatchNodeWdgt"
    menu.popUpAtHand()

  popUpVerticalStackMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Vertical stack"
    menu.addMenuItem "vertical stack constrained contents width", demoMenus, "createSimpleVerticalStackPanelWdgt"
    menu.addMenuItem "vertical stack scrollpanel constrained contents width", demoMenus, "createSimpleVerticalStackScrollPanelWdgt"
    menu.addMenuItem "vertical stack panel and scrollpanel constrained contents width", demoMenus, "createSimpleVerticalStackPanelWdgtAndScrollPanel"
    menu.addMenuItem "vertical stack free contents width", demoMenus, "createSimpleVerticalStackPanelWdgtFreeContentsWidth"
    menu.addMenuItem "vertical stack scrollpanel free contents width", demoMenus, "createSimpleVerticalStackScrollPanelWdgtFreeContentsWidth"
    menu.addMenuItem "vertical stack panel and scrollpanel free contents width", demoMenus, "createSimpleVerticalStackPanelWdgtAndScrollPanelFreeContentsWidth"

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
    svsspw.setBounds (new Point 430, 25), new Point 370, 325

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
    menu.addMenuItem "Destroy icon", demoMenus, "createDestroyIconWdgt"
    menu.addMenuItem "Under the carpet icon", demoMenus, "createUnderCarpetIconWdgt"
    menu.addMenuItem "Collapsed state icon", demoMenus, "createCollapsedStateIconWdgt"
    menu.addMenuItem "Uncollapsed state icon", demoMenus, "createUncollapsedStateIconWdgt"
    menu.addMenuItem "Close icon", demoMenus, "createCloseIconButtonWdgt"
    menu.addMenuItem "Scratch area icon", demoMenus, "createScratchAreaIconWdgt"
    menu.addMenuItem "Flora icon", demoMenus, "createFloraIconWdgt"
    menu.addMenuItem "Scooter icon", demoMenus, "createScooterIconWdgt"
    menu.addMenuItem "Heart icon", demoMenus, "createHeartIconWdgt"

    menu.addMenuItem "more 1 ➜", demoMenus, "popUpMore1IconsMenu", closesUnpinnedPopUps: false, toolTip: "others"
    menu.addMenuItem "more 2 ➜", demoMenus, "popUpMore2IconsMenu", closesUnpinnedPopUps: false, toolTip: "others"
    menu.addMenuItem "arrows ➜", demoMenus, "popUpArrowsIconsMenu", closesUnpinnedPopUps: false, toolTip: "others"
    menu.addMenuItem "maps ➜", demoMenus, "popUpMapsMenu", closesUnpinnedPopUps: false, toolTip: "maps"
    menu.addMenuItem "more 3 ➜", demoMenus, "popUpMore3IconsMenu", closesUnpinnedPopUps: false, toolTip: "maps"

    menu.popUpAtHand()

  popUpWindowsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Windows"
    menu.addMenuItem "empty window", demoMenus, "createEmptyWindow"
    menu.addMenuItem "empty internal window", demoMenus, "createEmptyInternalWindow"

    menu.popUpAtHand()

  popUpShortcutsAndScriptsMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Shortcuts & Scripts"
    menu.addMenuItem "bin shortcut", menusHelper, "binIconAndText"
    menu.addMenuItem "new script", menusHelper, "newScriptWindow"
    menu.addMenuItem "Fizzypaint launcher", (new FizzyPaintApp), "createOpener"
    menu.addMenuItem "document launcher", (new SimpleDocumentApp), "createOpener"
    menu.addMenuItem "slide launcher", (new SimpleSlideApp), "createOpener"
    menu.addMenuItem "Link", demoMenus, "createSimpleLinkWdgt"
    menu.addMenuItem "Video link", demoMenus, "createSimpleVideoLinkWdgt"
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

  createNewWrappingSimpleTextWdgtWithBackground: ->
    newWdgt = new SimpleTextWdgt(
      @LOREM_LONG,nil,nil,nil,nil,nil,Color.create(230, 230, 130), 1)
    newWdgt.isEditable = true

    world.add newWdgt
    newWdgt.setBounds new Point(25, 40), new Point(500, 300)

  createNewNonWrappingSimpleTextWdgtWithBackground: ->
    newWdgt = new SimpleTextWdgt(
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

  createNewWrappingAndNonWrappingSimpleTextWdgtWithBackground: ->
    @createNewWrappingSimpleTextWdgtWithBackground()
    @createNewNonWrappingSimpleTextWdgtWithBackground()

  createWrappingSimpleTextScrollPanelWdgt: ->
    SfA = new SimpleTextScrollPanelWdgt(
      @LOREM_LONG,true, 10)
    world.add SfA
    SfA.setBounds new Point(20, 25), new Point(390, 305)

  createNonWrappingSimpleTextScrollPanelWdgt: ->
    SfB = new SimpleTextScrollPanelWdgt(
      @LOREM_SHORT,false, 10)
    world.add SfB
    SfB.setBounds new Point(430, 25), new Point(390, 305)

  createWrappingAndNonWrappingSimpleTextScrollPanelWdgt: ->
    @createWrappingSimpleTextScrollPanelWdgt()
    @createNonWrappingSimpleTextScrollPanelWdgt()

  # this is provided for completeness, however see the
  # note in SimpleTextPanelWdgt about how this is
  # incomplete and why this widget is not useful anyways
  createWrappingSimpleTextPanelWdgt: ->
    SfA = new SimpleTextPanelWdgt(
      @LOREM_LONG,true, 10)
    world.add SfA
    SfA.setBounds new Point(20, 25), new Point(390, 305)

  # this is provided for completeness, however see the
  # note in SimpleTextPanelWdgt about how this is
  # incomplete and why this widget is not useful anyways
  createNonWrappingSimpleTextPanelWdgt: ->
    SfB = new SimpleTextPanelWdgt(
      @LOREM_SHORT,false, 10)
    world.add SfB
    SfB.setBounds new Point(430, 25), new Point(390, 305)

  # this is provided for completeness, however see the
  # note in SimpleTextPanelWdgt about how this is
  # incomplete and why this widget is not useful anyways
  createWrappingAndNonWrappingSimpleTextPanelWdgt: ->
    @createWrappingSimpleTextPanelWdgt()
    @createNonWrappingSimpleTextPanelWdgt()


  createSimpleDocumentScrollPanelWdgt: ->
    sdspw = new SimpleDocumentScrollPanelWdgt
    world.add sdspw
    # public setters on the ATTACHED panel self-settle in place (was _applyMoveTo/_applyExtent, whose raw
    # resize on an attached panel used to trip the now-deleted _announceGeometryChangeToContainer geom seam into an off-settle re-fit)
    sdspw.setBounds (new Point 35, 30), new Point 370, 325

  popUpDocumentMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Document"
    menu.addMenuItem "simple document scrollpanel", demoMenus, "createSimpleDocumentScrollPanelWdgt"
    menu.addMenuItem "document", demoMenus, "createDocumentWdgt"
    menu.popUpAtHand()

  popUpSimpleTextWdgtMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Simple plain text"
    menu.addMenuItem "simple plain text wrapping", demoMenus, "createNewWrappingSimpleTextWdgtWithBackground"
    menu.addMenuItem "simple plain text not wrapping", demoMenus, "createNewNonWrappingSimpleTextWdgtWithBackground"
    menu.addMenuItem "simple plain text (wrapping / not wrapping)", demoMenus, "createNewWrappingAndNonWrappingSimpleTextWdgtWithBackground"
    menu.addMenuItem "simple plain text panel wrapping", demoMenus, "createWrappingSimpleTextPanelWdgt"
    menu.addMenuItem "simple plain text panel not wrapping", demoMenus, "createNonWrappingSimpleTextPanelWdgt"
    menu.addMenuItem "simple plain text panel (wrapping / not wrapping)", demoMenus, "createWrappingAndNonWrappingSimpleTextPanelWdgt"
    menu.addMenuItem "simple plain text scrollpanel wrapping", demoMenus, "createWrappingSimpleTextScrollPanelWdgt"
    menu.addMenuItem "simple plain text scrollpanel not wrapping", demoMenus, "createNonWrappingSimpleTextScrollPanelWdgt"
    menu.addMenuItem "simple plain text scrollpanel (wrapping / not wrapping)", demoMenus, "createWrappingAndNonWrappingSimpleTextScrollPanelWdgt"

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
    menu.addMenuItem "StringWdgt without background", demoMenus, "createNewStringWdgtWithoutBackground"
    menu.addMenuItem "StringWdgt with background", demoMenus, "createNewStringWdgtWithBackground"
    menu.addMenuItem "TextWdgt with background", demoMenus, "createNewTextWdgtWithBackground"
    if world.pinouts?.isShowing targetWidget
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

    menu.addMenuItem "others ➜", demoMenus, "popUpFirstMenu", closesUnpinnedPopUps: false, toolTip: "others"
    menu.addMenuItem "others 2 ➜", demoMenus, "popUpSecondMenu", closesUnpinnedPopUps: false, toolTip: "others"


    menu.popUpAtHand()

  popUpFirstMenu: (widgetOpeningThePopUp, widgetThisMenuIsAbout) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "others"
    menu.addMenuItem "make sliders' buttons states bright", demoMenus, "makeSlidersButtonsStatesBright"
    menu.addMenuItem "make pointer", widgetThisMenuIsAbout, "createPointerWdgt"
    menu.addMenuItem "icon with text", demoMenus, "makeIconWithText"
    menu.addMenuItem "empty icon with text", demoMenus, "makeEmptyIconWithText"
    menu.addMenuItem "generic reference icon", demoMenus, "makeGenericReferenceIcon"
    menu.addMenuItem "generic object icon", demoMenus, "makeGenericObjectIcon"
    menu.addMenuItem "folder window", demoMenus, "makeFolderWindow"
    menu.addMenuItem "bouncing particle", demoMenus, "makeBouncingParticle"
    menu.addMenuItem "throw an error", demoMenus, "throwAnError"
    menu.addMenuItem "stretchable panel", demoMenus, "createStretchablePanel"
    menu.addMenuItem "tools panel", demoMenus, "createToolsPanel"
    menu.addMenuItem "slide", demoMenus, "createSlideWdgt"
    menu.addMenuItem "patch programming ➜", demoMenus, "popUpPatchProgrammingMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "graphs ➜", demoMenus, "popUpGraphsMenu", closesUnpinnedPopUps: false, toolTip: "graphs"
    menu.addMenuItem "support docs ➜", demoMenus, "popUpSupportDocsMenu", closesUnpinnedPopUps: false, toolTip: "support docs"

    menu.popUpAtHand()

  popUpSecondMenu: (widgetOpeningThePopUp) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "others"
    menu.addMenuItem "icons ➜", demoMenus, "popUpIconsMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "simple plain text ➜", demoMenus, "popUpSimpleTextWdgtMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "vertical stack ➜", demoMenus, "popUpVerticalStackMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "document ➜", demoMenus, "popUpDocumentMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "windows ➜", demoMenus, "popUpWindowsMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "shortcuts & scripts ➜", demoMenus, "popUpShortcutsAndScriptsMenu", closesUnpinnedPopUps: false, toolTip: "Shortcuts & Scripts"
    menu.addMenuItem "analog clock", demoMenus, "analogClock"
    menu.addMenuItem "dev tools ➜", menusHelper, "popUpDevToolsMenu", closesUnpinnedPopUps: false, toolTip: "icons"
    menu.addMenuItem "fizzytiles", demoMenus, "createFridgeMagnets"
    menu.addMenuItem "fizzypaint", demoMenus, "createImageWdgt"
    menu.addMenuItem "simple button", demoMenus, "createSimpleButton"
    menu.addMenuItem "switch button", demoMenus, "createSwitchButtonWdgt"
    menu.addMenuItem "clipping box", demoMenus, "createNewClippingBoxWdgt"

    menu.popUpAtHand()


  createWelcomeMessageWindowAndShortcut: ->
    wm = WelcomeMessageInfoWdgt.create()
    readmeLauncher = new IconicDesktopSystemDocumentShortcutWdgt wm, "Welcome", new WelcomeIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add readmeLauncher
    readmeLauncher.setExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()
