# I can have an optionally rounded border

class BoxWdgt extends Widget

  cornerRadius: undefined

  constructor: (@cornerRadius = 4) ->
    super()
    @appearance = new BoxyAppearance @


  setCornerRadius: (radiusOrWidgetGivingRadius, widgetGivingRadius) ->
    if widgetGivingRadius?.getValue?
      radius = widgetGivingRadius.getValue()
    else
      radius = radiusOrWidgetGivingRadius

    if typeof radius is "number"
      @cornerRadius = Math.max radius, 0
    else
      newRadius = parseFloat radius
      if !isNaN newRadius
        @cornerRadius = Math.max newRadius, 0
    @_changed()
