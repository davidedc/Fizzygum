# MenusHelper ////////////////////////////////////////////////////////////

# All "actions" functions for all accessory menu items should belong
# in here. Also helps so we don't pollute moprhs with a varying number
# of helper functions, which is problematic for visual diffing
# on inspectors (the number of methods keeps changing).

class MenusHelper
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

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
    world.create new SimpleRectangularButtonMorph true, @, null, new IconMorph(null)

  createSwitchButtonMorph: ->
    button1 = new SimpleRectangularButtonMorph true, @, null, new IconMorph(null)
    button2 = new SimpleRectangularButtonMorph true, @, null, new StringMorph2 "Hello World! ⎲ƒ⎳⎷ ⎸⎹ "
    world.create new SwitchButtonMorph [button1, button2]

