# ScratchAreaIconMorph //////////////////////////////////////////////////////


# based on https://thenounproject.com/term/organization/153374/
class ScratchAreaIconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new ScratchAreaIconAppearance @


