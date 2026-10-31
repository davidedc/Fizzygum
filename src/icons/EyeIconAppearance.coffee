# The eye at the view end of a window's edit-mode toggle (EditModeToggleAppearance).
# Same single-fill idiom as PencilIconAppearance: the glyph takes the ink it is
# given, else the widget's color.

class EyeIconAppearance extends IconAppearance

  paintFunction: (context) ->
    context.save()

    # almond outline band: outer contour top-first, inner contour
    # bottom-first -- opposite windings, so the nonzero fill rule leaves
    # the band between them (cf. the donut in IconAppearance.paintFunction)
    context.beginPath()
    context.moveTo 8, 100
    context.bezierCurveTo 38, 34, 162, 34, 192, 100
    context.bezierCurveTo 162, 166, 38, 166, 8, 100
    context.closePath()
    context.moveTo 30, 100
    context.bezierCurveTo 56, 144, 144, 144, 170, 100
    context.bezierCurveTo 144, 56, 56, 56, 30, 100
    context.closePath()
    # pupil (its own subpath; any winding, it doesn't overlap the band)
    @circle context, 100, 100, 27
    context.fillStyle = @_iconColorString()
    context.fill()

    context.restore()
