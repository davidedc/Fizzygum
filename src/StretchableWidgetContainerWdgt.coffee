# We need this because we need a panel that keeps its content
# all in the same relative positions and sizes when its
# resized, so you can drag and drop it inside stacks
# and resizable windows and it doesn't mangle the contents
# when it's resized. The way to achieve that is to
# have a container and a type of panel that works together
# to "crystallize" a specific width/height ratio as soon
# as there is one element dropped/added in the panel.
# So when the panel is empty, you can give it any shape you
# want, but as soon as there is one element, it sticks
# to the ratio it has.

class StretchableWidgetContainerWdgt extends Widget

  ratio: nil
  contents: nil

  constructor: (contents) ->
    super new Point 300, 300
    
    if !contents?
      contents = new StretchablePanelWdgt

    @add contents
    @contents = contents

    @rawSetExtent new Point 300, 300
    @contents.rawSetExtent new Point @width(), @height()
    @invalidateLayout()

  # actually
  # ends up in the Panel inside it
  add: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped) ->
    if !@contents? or (aWdgt instanceof ModifiedTextTriangleAnnotationWdgt) or
     (aWdgt instanceof HandleMorph)
      super
    else
      @contents.add aWdgt, position, layoutSpec, beingDropped
      @grandChildAdded?()

  setRatio: (@ratio) ->
    @layoutSpecDetails?.canSetHeightFreely = false

  resetRatio: ->
    if @ratio?
      @ratio = nil
      @layoutSpecDetails?.canSetHeightFreely = true
      @invalidateLayout()


  colloquialName: ->
    "stretchable panel"

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = !@ratio?


  widthWithoutSpacing: ->
    height = @height()
    width = @width()

    if @ratio?
      widthBasedOnHeight = height * @ratio
      heightBasedOnWidth = width / @ratio

      if widthBasedOnHeight <= width
        return widthBasedOnHeight

      else if heightBasedOnWidth <= height
        return width

    else
        return width

  rawResizeToWithoutSpacing: ->
    if @ratio?
      @rawSetExtent new Point @widthWithoutSpacing(), Math.round(@widthWithoutSpacing()/@ratio)
      @invalidateLayout()

  rawSetWidthSizeHeightAccordingly: (newWidth) ->
    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents

    if childrenNotHandlesNorCarets.length != 0
      if !@ratio?
        @ratio = @width() / @height()
        @layoutSpecDetails?.canSetHeightFreely = false
      @rawSetExtent new Point newWidth, Math.round(newWidth/@ratio)
      @invalidateLayout()
    else
      @rawSetExtent new Point newWidth, @height()
      @invalidateLayout()


  rawSetExtent: (extent) ->

    if extent.equals @extent()
      return

    super
    @doLayout @bounds


  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    #console.log "spanel @contents: " + @contents + " doLayout 1"


    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    #console.log "spanel @contents: " + @contents + " doLayout 2"

    # TODO shouldn't be calling this rawSetBounds from here,
    # rather use super
    @rawSetBounds newBoundsForThisLayout

    #console.log "spanel @contents: " + @contents + " doLayout 3"

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    height = @height()
    width = @width()

    if @ratio?
      widthBasedOnHeight = height * @ratio
      heightBasedOnWidth = width / @ratio

       # p0 is the origin, the origin being in the top-left corner
      p0 = @topLeft()

      if widthBasedOnHeight <= width
        p0 = p0.add new Point (width - widthBasedOnHeight) / 2 , 0
        newExtent = new Point widthBasedOnHeight, height

      else if heightBasedOnWidth <= height
        p0 = p0.add new Point 0 , (height - heightBasedOnWidth) / 2
        newExtent = new Point width, heightBasedOnWidth

      newBounds = (new Rectangle p0).setBoundsWidthAndHeight newExtent
      #console.log "spanel @contents: " + @contents + " bounds: " + newBounds.round()
      @contents.doLayout newBounds.round()

    else
      @contents.doLayout @bounds



    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

  # same as simpledocumentscrollpanel, you can lock the contents.
  # worth factoring it out as a mixin?
  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length > 0
      menu.addLine()
      if !@dragsDropsAndEditingEnabled
        menu.addMenuItem "enable editing", true, @, "enableDragsDropsAndEditing", "lets you drag content in and out"
      else
        menu.addMenuItem "disable editing", true, @, "disableDragsDropsAndEditing", "prevents dragging content in and out"

    menu.removeConsecutiveLines()

  enableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if @dragsDropsAndEditingEnabled
      return
    @parent?.makePencilYellow?()
    if @parent? and @parent != triggeringWidget and @parent instanceof SimpleSlideWdgt
      @parent.enableDragsDropsAndEditing @
    else
      super @

  disableDragsDropsAndEditing: (triggeringWidget) ->
    if !triggeringWidget? then triggeringWidget = @
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.makePencilClear?()
    if @parent? and @parent != triggeringWidget and @parent instanceof SimpleSlideWdgt
      @parent.disableDragsDropsAndEditing @
    else
      super @
