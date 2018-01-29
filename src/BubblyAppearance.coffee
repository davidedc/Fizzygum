# BubblyAppearance //////////////////////////////////////////////////////////////

class BubblyAppearance extends BoxyAppearance

  isThought: nil
  isPointingRight: nil

  constructor: (morph, @isThought, @isPointingRight) ->
    super morph

  outlinePath: (context, radius) ->
    # console.log "bubble outlinePath"
    circle = (x, y, r) ->
      context.moveTo x + r, y
      context.arc x, y, r, degreesToRadians(0), degreesToRadians(360)
    offset = radius
    w = @morph.width()
    h = @morph.height()

    # top left:
    context.arc offset, offset, radius, degreesToRadians(-180), degreesToRadians(-90)

    # top right:
    context.arc w - offset, offset, radius, degreesToRadians(-90), degreesToRadians(-0)

    # bottom right:
    context.arc w - offset, h - offset - radius, radius, degreesToRadians(0), degreesToRadians(90)
    unless @isThought # draw speech bubble hook
      if @isPointingRight
        context.lineTo offset + radius, h - offset
        context.lineTo radius / 2, h
      else # pointing left
        context.lineTo w - (radius / 2), h
        context.lineTo w - (offset + radius), h - offset

    # bottom left:
    context.arc offset, h - offset - radius, radius, degreesToRadians(90), degreesToRadians(180)

    if @isThought
      # close large bubble:
      context.lineTo 0, offset

      # draw thought bubbles:
      if @isPointingRight

        # tip bubble:
        rad = radius / 4
        circle rad, h - rad, rad

        # middle bubble:
        rad = radius / 3.2
        circle rad * 2, h - rad, rad

        # top bubble:
        rad = radius / 2.8
        circle rad * 3, h - rad, rad
      else # pointing left
        # tip bubble:
        rad = radius / 4
        circle w - (rad), h - rad, rad

        # middle bubble:
        rad = radius / 3.2
        circle w - (rad * 2), h - rad, rad

        # top bubble:
        rad = radius / 2.8
        circle w - (rad * 3), h - rad, rad
