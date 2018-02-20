# MagnetMorph ////////////////////////////////////////////////////////


class MagnetMorph extends TriggerMorph

  putIntoWords: false
  isTemplate: true

  constructor: (
      @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked,
      @target
     ) ->
    super
    @defaultRejectDrags = false

  rightCenter: ->
    new Point(@right(),@height()/2)

  leftCenter: ->
    new Point(@left(),@height()/2)

