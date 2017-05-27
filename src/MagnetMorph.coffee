# MagnetMorph ////////////////////////////////////////////////////////


class MagnetMorph extends TriggerMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  putIntoWords: false
  isTemplate: true

  rightCenter: ->
    new Point(@right(),@height()/2)

  leftCenter: ->
    new Point(@left(),@height()/2)

