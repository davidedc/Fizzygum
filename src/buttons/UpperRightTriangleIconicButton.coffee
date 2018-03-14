# like an UpperRightTriangle, but it adds an icon on the top-right
# note that this should all be done with actual layouts but this
# will do for the moment.

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions
#
# to test this:
# create a canvas. then:
# new UpperRightTriangleIconicButton(world.children[0])

class UpperRightTriangleIconicButton extends UpperRightTriangle

  @augmentWith HighlightableMixin, @name

  color: new Color 255, 255, 255
  pencilIconMorph: nil

  constructor: (parent = nil) ->
    super
    @pencilIconMorph = new PencilIconMorph new Color 0,0,0

    @pencilIconMorph.parentHasReLayouted = ->
      @updateResizerPosition()
      @moveInFrontOfSiblings()

    @pencilIconMorph.updateResizerPosition = ->
      if @parent
        @silentUpdateResizerPosition()
        @changed()

    @pencilIconMorph.silentUpdateResizerPosition = ->
      if @parent
        xDim = @parent.width()
        yDim = @parent.height()
        minDim = Math.min(xDim, yDim) / 2

        @silentRawSetExtent new Point minDim, minDim
        @silentFullRawMoveTo new Point @parent.right() - minDim, @parent.top()

    @add @pencilIconMorph
    @pencilIconMorph.updateResizerPosition()

