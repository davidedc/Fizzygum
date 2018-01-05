# SimpleButtonMorph ////////////////////////////////////////////////////////

# sends a message to a target object when pressed.
# takes a rectangular shape, and can host
# a morph to be used as "face"

class SimpleButtonMorph extends EmptyButtonMorph

  constructor: (
      @closesUnpinnedMenus = true,
      @target = nil,
      @action = nil,

      @faceMorph = nil,

      @dataSourceMorphForTarget = nil,
      @morphEnv,
      @hint = nil,

      @doubleClickAction = nil,
      @argumentToAction1 = nil,
      @argumentToAction2 = nil,
      @representsAMorph = false
      ) ->

    # additional properties:

    super

    @appearance = new BoxyAppearance @

