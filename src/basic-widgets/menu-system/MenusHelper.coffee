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
    world.create new SliderWdgt nil, nil, nil, nil, nil, true

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

  # this part is excluded from the fizzygum homepage build <<«

  createWelcomeMessageWindowAndShortcut: ->
    wm = WelcomeMessageInfoWdgt.create()
    readmeLauncher = new IconicDesktopSystemDocumentShortcutWdgt wm, "Welcome", new WelcomeIconWdgt
    # this "add" is going to try to position the reference
    # in some smart way (i.e. according to a grid)
    world.add readmeLauncher
    readmeLauncher.setExtent new Point 75, 75
    readmeLauncher.fullChanged()

