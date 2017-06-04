# SimpleRectangularButtonMorph ////////////////////////////////////////////////////////

# sends a message to a target object when pressed.
# takes a rectangular shape, and can host
# a morph to be used as "face"

class SimpleRectangularButtonMorph extends EmptyButtonMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  constructor: (
      @closesUnpinnedMenus = true,
      @target = null,
      @action = null,

      @faceMorph = null,

      @dataSourceMorphForTarget = null,
      @morphEnv,
      @hint = null,

      @doubleClickAction = null,
      @argumentToAction1 = null,
      @argumentToAction2 = null,
      @representsAMorph = false
      ) ->

    # additional properties:

    super

    @appearance = new RectangularAppearance @

