# REQUIRES StretchablePanelWdgt

# We need this because we need a panel that keeps its content
# all in the same relative positions and sizes when its
# resized, so you can drag and drop it inside stacks
# and resizable windows and it doesn't mangle the contents
# when it's resized. The way to achieve that is to
# have a container and a type of panel that works together
# to "cristallize" a specific width/height ratio as soon
# as there is one element dropped/added in the panel.
# So when the panel is empty, you can give it any shape you
# want, but as soon as there is one element, it sticks
# to the ratio it has.

class StretchablePanelContainerWdgt extends Widget

  ratio: nil
  contents: nil

  constructor: ->
    debugger
    super new Point 300, 300
    contents = new StretchablePanelWdgt()
    @add contents

    @contents = contents
    @rawSetExtent new Point 300, 300
    @contents.rawSetExtent new Point @width(), @height()
    @invalidateLayout()

  # actually
  # ends up in the Panel inside it
  add: (aMorph, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped) ->
    debugger
    if !@contents? or (aMorph instanceof ModifiedTextTriangleAnnotationWdgt) or
     (aMorph instanceof HandleMorph)
      super
    else
      @contents.add aMorph, position, layoutSpec, beingDropped
      @grandChildAdded()

  grandChildAdded: ->
    if !@ratio?
      childrenNotHandlesNorCarets = @contents.children.filter (m) ->
        !((m instanceof HandleMorph) or (m instanceof CaretMorph))

      if childrenNotHandlesNorCarets.length != 0
          @ratio = @width() / @height()
          @layoutSpecDetails?.canSetHeightFreely = false

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
      @rawSetExtent new Point @widthWithoutSpacing(), @widthWithoutSpacing()/@ratio
      @invalidateLayout()

  rawSetWidthSizeHeightAccordingly: (newWidth) ->
    debugger
    childrenNotHandlesNorCarets = @contents.children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    if childrenNotHandlesNorCarets.length != 0
      if !@ratio?
        @ratio = @width() / @height()
        @layoutSpecDetails?.canSetHeightFreely = false
      @rawSetExtent new Point newWidth, newWidth/@ratio
      @invalidateLayout()
    else
      @rawSetExtent new Point newWidth, @height()
      @invalidateLayout()

  grandChildRemoved: ->
    childrenNotHandlesNorCarets = @contents.children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    if @ratio? and childrenNotHandlesNorCarets.length == 0
      @ratio = nil
      @layoutSpecDetails?.canSetHeightFreely = true
      @invalidateLayout()

  doLayout: (newBoundsForThisLayout) ->
    if !window.recalculatingLayouts
      debugger

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

    debugger
    @rawSetBounds newBoundsForThisLayout

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
      @contents.doLayout newBounds

    else
      @contents.doLayout @bounds



    trackChanges.pop()
    @fullChanged()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()