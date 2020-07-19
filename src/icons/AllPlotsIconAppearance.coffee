class AllPlotsIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    context.fillStyle = iconColorString

    # this is all done in one path - but note how it has some unconnected
    # parts: moveTo() is used to put together the unconnected parts
    # into one path

    context.beginPath()

    # axes
    # ...this would look like a better job for a stroke rather than a fill, however
    # hey hardware is fast and this way we only create one path that is filled
    # all at once.
    context.moveTo 7, 8
    context.lineTo 11.25, 8
    context.lineTo 11.25, 88.76
    context.lineTo 92, 88.76
    context.lineTo 92, 93
    context.lineTo 7, 93
    context.lineTo 7, 8

    # dots
    context.moveTo 37, 20
    context.arc 37, 20, 3, 0, 2 * Math.PI
    context.moveTo 20, 39
    context.arc 20, 39, 3, 0, 2 * Math.PI
    context.moveTo 20, 18
    context.arc 20, 18, 3, 0, 2 * Math.PI
    context.moveTo 29, 29
    context.arc 29, 29, 3, 0, 2 * Math.PI
    context.moveTo 42, 29
    context.arc 42, 29, 3, 0, 2 * Math.PI
    context.moveTo 53, 25
    context.arc 53, 25, 3, 0, 2 * Math.PI
    context.moveTo 53, 15
    context.arc 53, 15, 3, 0, 2 * Math.PI

    # function plot line drawing
    # ...this would look like a better job for a stroke rather than a fill, however
    # hey hardware is fast and this way we only create one path that is filled
    # all at once.
    context.moveTo 20.06, 79.26
    context.lineTo 15.23, 75.9
    context.lineTo 26.06, 56.31
    context.bezierCurveTo 30.65, 47.24, 35.32, 43.21, 40.07, 44.24
    context.bezierCurveTo 43.14, 44.9, 54.09, 61.41, 57.5, 57.37
    context.bezierCurveTo 58.98, 57.16, 82.84, 11.04, 82.84, 11.04
    context.lineTo 87.75, 14.04
    context.bezierCurveTo 87.75, 14.04, 64.04, 58.55, 62.73, 60.59
    context.bezierCurveTo 61.13, 62.57, 59.42, 63.75, 57.1, 63.64
    context.bezierCurveTo 54.43, 63.84, 52, 63, 48.31, 59.85
    context.bezierCurveTo 44.62, 56.71, 41.39, 52.14, 38.2, 51.57
    context.bezierCurveTo 35, 51, 32.45, 56.53, 30.62, 59.61
    # now close this part of the path back to its opening point
    context.lineTo 20.06, 79.26

    # bars
    # note that rects don't need moveTo to draw correctly as
    # distinct parts of the path (while arcs do!)
    context.rect 79, 41, 11, 45
    context.rect 63, 66, 11, 20
    context.rect 47, 72, 11, 14
    context.rect 32, 66, 10, 20

    context.fill()
