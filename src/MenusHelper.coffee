# MenusHelper ////////////////////////////////////////////////////////////

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
    world.create reconfPaint
    reconfPaint.setExtent new Point 460, 400

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
    world.create new IconWithTextWdgt "hey there", new BrushIconMorph()

  makeEmptyIconWithText: ->
    world.create new IconWithTextWdgt "hey there"

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

  makeGenericReferenceIcon: ->
    world.create new GenericShortcutIconWdgt()

  makeGenericObjectIcon: ->
    world.create new GenericObjectIconWdgt()
