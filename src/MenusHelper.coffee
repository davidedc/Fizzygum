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

