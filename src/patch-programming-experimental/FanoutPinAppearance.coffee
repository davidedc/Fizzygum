class FanoutPinAppearance extends IconAppearance

  constructor: (@widget) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    # my widget holds no colour until one is set on it (FanoutPinWdgt.color): until then the icon ink
    iconColorString = (@ownColorInsteadOfWidgetColor ? @widget.color ? WorldWdgt.theme.iconInk).toString()
    outlineColor = 'rgb(184, 184, 184)'
    #// outline Drawing
    @_paintRoundedSquareBadge context, outlineColor, iconColorString
