# Note that the ColorPicker has no "set target..." from
# the menu.

class ColorPickerMorph extends Widget

  # pattern: all the children should be declared here
  # the reason is that when you duplicate a morph
  # , the duplicated morph needs to have the handles
  # that will be duplicated. If you don't list them
  # here, then they need to be initialised in the
  # constructor. But actually they might not be
  # initialised in the constructor if a "lazy initialisation"
  # approach is taken. So it's good practice
  # to list them here so they can be duplicated either way.
  feedback: nil
  choice: nil
  colorPalette: nil
  grayPalette: nil

  constructor: (
    @choice = (new Color 255, 255, 255)
    ) ->    
    super()
    @appearance = new RectangularAppearance @
    @color = new Color 255, 255, 255
    @rawSetExtent new Point 80, 80
    @buildSubmorphs()

  colloquialName: ->
    "color picker"

  buildSubmorphs: ->
    @feedback = new RectangleMorph new Point(20, 20), @choice
    @colorPalette = new ColorPaletteMorph @feedback, new Point @width(), 50
    @grayPalette = new GrayPaletteMorph @feedback, new Point @width(), 5
    @add @colorPalette
    @add @grayPalette
    @add @feedback
    @invalidateLayout()

  iHaveBeenAddedTo: (whereTo, beingDropped) ->
  
  getColor: ->
    @feedback.color
  

  rawSetExtent: (aPoint) ->
    super
    @invalidateLayout()

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts
    #  debugger

    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      if @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

    @rawSetBounds newBoundsForThisLayout
    @colorPalette.fullRawMoveTo @position()
    @colorPalette.rawSetExtent new Point @width(), Math.round(@height() * 0.625)

    @grayPalette.fullRawMoveTo @colorPalette.bottomLeft()
    @grayPalette.rawSetExtent new Point @width(), Math.round(@height() * 0.0625)

    x = @grayPalette.left() + Math.floor((@grayPalette.width() - @feedback.width()) / 2)
    y = @grayPalette.bottom() + Math.floor((@bottom() - @grayPalette.bottom() - @feedback.height()) / 2)
    @feedback.fullRawMoveTo new Point x, y
    @feedback.rawSetExtent new Point Math.min(@width(), Math.round(@height() * 0.25)), Math.round(@height() * 0.25)

    trackChanges.pop()
    @fullChanged()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
