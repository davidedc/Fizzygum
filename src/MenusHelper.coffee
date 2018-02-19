# MenusHelper ////////////////////////////////////////////////////////////
# REQUIRES DeepCopierMixin

# All "actions" functions for all accessory menu items should belong
# in here. Also helps so we don't pollute moprhs with a varying number
# of helper functions, which is problematic for visual diffing
# on inspectors (the number of methods keeps changing).

class MenusHelper

  @augmentWith DeepCopierMixin

  createFridgeMagnets: ->
    fmm = new FridgeMagnetsMorph()
    world.create fmm
    fmm.setExtent new Point 570, 400

  createReconfigurablePaint: ->
    reconfPaint = new ReconfigurablePaintMorph()
    wm = new WindowWdgt nil, nil, reconfPaint
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
      reconfPaint = new ReconfigurablePaintMorph()
      wm = new WindowWdgt nil, nil, reconfPaint
      wm.setExtent new Point 460, 400
      wm.fullRawMoveTo world.hand.position()
      wm.fullRawMoveWithin world
      world.add wm
      wm.changed()
    """

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

