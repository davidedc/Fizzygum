class ExampleBarPlotWdgt extends GraphsPlotsChartsWdgt

  graphNumber: 1
  drawOnlyPartOfBoundingRect: false

  constructor: (@drawOnlyPartOfBoundingRect)->
    super()
    @fps = 0.5
    world.steppingWdgts.add @

  colloquialName: ->
    "Bar plot"


  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @backgroundTransparency

    # paintRectangle here is made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, this is why
    # it's called before the scaling.
    @paintRectangle aContext, al, at, w, h, @backgroundColor
    aContext.useLogicalPixelsUntilRestore()

    morphPosition = @position()
    aContext.translate morphPosition.x, morphPosition.y

    @renderingHelper aContext, new Color(255, 255, 255), appliedShadow

    aContext.restore()

    # paintHighlight here is made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, this is why
    # it's called outside the effect of the scaling
    # (after the restore).
    @paintHighlight aContext, al, at, w, h


  step: ->
    @graphNumber++
    @changed()

  renderingHelper: (context, color, appliedShadow) ->

    @seed = @graphNumber
    circleRadius = 5
    height = @height()
    width = @width()

    if appliedShadow?
      @simpleShadow context, color, appliedShadow
      return

    context.fillStyle = WorldMorph.preferencesAndSettings.editableItemBackgroundColor.toString()
    context.fillRect 0, 0, width, height

    availableHeight = height

    context.globalAlpha = @alpha

    for i in [0..20]
      xPos = (i/21)*width
      heightPerc = 0.2 + Math.sin(i/100)*3 - i/10000 + @seeded_randn_bm() / 20
      if @seededRandom() > 0.5
        context.fillStyle = '#325FA2'
      else
        context.fillStyle = '#FF0000'
      context.fillRect Math.round(xPos), Math.round(availableHeight - (availableHeight * heightPerc)), Math.round((1/20)*width - 2), Math.round(availableHeight * heightPerc)

    @drawBoundingBox context, color, appliedShadow
