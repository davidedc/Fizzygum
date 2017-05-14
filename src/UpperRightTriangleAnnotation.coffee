# UpperRightTriangleAnnotation ////////////////////////////////////////////////////////

# like an UpperRightTriangle, but it adds an icon on the top-right
# note that this should all be done with actual layouts but this
# will do for the moment.

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions
#
# to test this:
# create a canvas. then:
# new UpperRightTriangleAnnotation(world.children[0])

class UpperRightTriangleAnnotation extends UpperRightTriangle
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  pencilIconMorph = null

  constructor: (parent = null) ->
    super
    @pencilIconMorph = new PencilIconMorph new Point(200,200),null

    @pencilIconMorph.parentHasReLayouted = ->
      @updateResizerPosition()
      @moveInFrontOfSiblings()

    @pencilIconMorph.updateResizerPosition = ->
      if @parent
        @silentUpdateResizerPosition()
        @changed()

    @pencilIconMorph.silentUpdateResizerPosition = ->
      if @parent
        debugger
        xDim = @parent.width()
        yDim = @parent.height()
        minDim = Math.min(xDim, yDim) / 2

        @silentRawSetExtent new Point minDim, minDim
        @silentFullRawMoveTo new Point @parent.right() - minDim, @parent.top()

    @pencilIconMorph.isFloatDraggable = ->
      if @parent?

        # an instance of ScrollFrameMorph is also an instance of FrameMorph
        # so gotta do this check first ahead of next paragraph.
        #if @parentThatIsA(ScrollFrameMorph)?
        #  return false

        if @parent instanceof WorldMorph
          return true
      return false

    @add @pencilIconMorph
    @pencilIconMorph.updateResizerPosition()


  parentHasReLayouted: ->
    @updateResizerPosition()
    @moveInFrontOfSiblings()
    super

  updateResizerPosition: ->
    if @parent
      @silentUpdateResizerPosition()
      @changed()

  silentUpdateResizerPosition: ->
    if @parent
      debugger
      xDim = @parent.width()
      yDim = @parent.height()
      minDim = Math.min(xDim, yDim) * 3/8

      @silentRawSetExtent new Point minDim, minDim
      @silentFullRawMoveTo new Point @parent.right() - minDim, @parent.top()
  
