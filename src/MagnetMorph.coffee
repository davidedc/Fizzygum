# MagnetMorph ////////////////////////////////////////////////////////


class MagnetMorph extends TriggerMorph

  putIntoWords: false
  isTemplate: true

  rightCenter: ->
    new Point(@right(),@height()/2)

  leftCenter: ->
    new Point(@left(),@height()/2)

