# LayoutMorph

# this comment below is needed to figure out dependencies between classes
# REQUIRES Color


class LayoutMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  classVariableNames: ''
  poolDictionaries: ''

  layoutNeeded: false
  category: 'Morphic-Layouts'

  constructor: ->
    super()
    @setColor @defaultColor()

  defaultColor: ->
    return Color.transparent()

  minPaneHeightForReframe: ->
    return 20

  minPaneWidthForReframe: ->
    return 40
