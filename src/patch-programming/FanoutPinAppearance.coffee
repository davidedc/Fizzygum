# this file is excluded from the fizzygum homepage build

class FanoutPinAppearance extends IconAppearance

  constructor: (@widget) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    # matches the old inline ownColorInsteadOfWidgetColor?-ternary exactly (byte-identical)
    iconColorString = @_iconColorString()
    outlineColor = 'rgb(184, 184, 184)'
    #// outline Drawing
    @_paintRoundedSquareBadge context, outlineColor, iconColorString
