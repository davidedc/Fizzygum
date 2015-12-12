# LayoutableMorph //////////////////////////////////////////////////////

# This is gonna trampoline a second version of the layout system.

# this comment below is needed to figure out dependencies between classes
# REQUIRES LayoutSpec

# So layouts in ZK work the following way:
#  1) Any Morph can contain a number of other morphs
#     according to a number of layouts *simultaneously*
#     e.g. you can have two morphs being horizontally stacked
#     and two other morphs being inset for example
#  2) There is no need for an explicit special container. Any
#     Morph can be a container when needed.
#  3) The default attaching of Morphs to a Morph puts them
#     under the effect of the most basic layout: the FREEFLOATING
#     layout.
#  3) You can only do a high-level-resize or move to a FREEFLOATING
#     Morph. All other Morphs are under the effect of more complex
#     layout strategies so they can't be moved willy nilly.
#     Control of size and placement can be done but in other
#     means below.
#  4) You CAN control the size and location of Morphs under the
#     effect of complex layouts by programmatically changing their
#     layout spec properties.
#  5) You CAN also manually control the size and location of Morphs
#     under the effect of complex layouts by using special Adjusting
#     Morphs, which are provided by the container, and give handles
#     to manually control the content. These manual controls
#     under the courtains go and programmatically modify the layout
#     spec properties of the content.

class LayoutableMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  minWidth: 10
  desiredWidth: 20
  maxWidth: 100

  minHeight: 10
  desiredHeight: 20
  maxHeight: 100

  constructor: ->
    super()
    @setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)


  setMinAndMaxBoundsAndSpreadability: (minBounds, desiredBounds, spreadability = LayoutSpec.SPREADABILITY_MEDIUM) ->
    @minWidth = minBounds.x
    @minHeight = minBounds.y

    @desiredWidth = desiredBounds.x
    @desiredHeight = desiredBounds.y

    maxWidth = desiredBounds.x + spreadability * desiredBounds.x/100
    maxHeight = desiredBounds.y + spreadability * desiredBounds.y/100
    @setMaxDim new Dimension maxWidth, maxHeight

    @invalidateLayout()


  setMaxDim: (overridingMaxDim) ->

    ###
    currentMax = @getRecursiveMaxDim()
    ratio = currentMax.x / overridingMaxDim.x

    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        C.setMaxDim C.getRecursiveMaxDim().divideBy ratio
    ###


    @maxWidth = overridingMaxDim.x
    @maxHeight = overridingMaxDim.y

    @invalidateLayout()

  getDesiredDim: ->
    desiredDim = new Dimension @desiredWidth, @desiredHeight
    return desiredDim.min @getMaxDim()
  getMinDim: ->
    minDim = new Dimension @minWidth, @minHeight
    return minDim.min @getMaxDim()
  getMaxDim: ->
    maxDim = new Dimension @maxWidth, @maxHeight
    return maxDim

  # if you use this paragraph, then the container of further
  # layouts will have a minimum equal to the sum of minimums
  # of the contents. I think we shouldn't do this.
  # Rather, we have a system where you CAN easily resize things to any
  # size, so to have maximum flexibility we are not binding the
  # minimum of a container to the minimums of the contents.
  # Rather, you can just set any minimum you want to the container.
  # If you want to make then zero, then be it, the minimums of the
  # contents won't matter.
  ###
  getDesiredDim: ->
    @getRecursiveDesiredDim()
  getMinDim: ->
    @getRecursiveMinDim()
  getMaxDim: ->
    maxDim = new Dimension @maxWidth, @maxHeight
    return maxDim.max @getDesiredDim()
  ###


  getRecursiveDesiredDim: ->
    
    # TBD the exact shape of @checkDesiredDimCache
    #if @checkDesiredDimCache
    #  return @desiredDimCache

    desiredWidth = null
    desiredHeight = null
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C.getDesiredDim()
        if !desiredWidth? then desiredWidth = 0
        desiredWidth += childSize.width()
        if desiredHeight < childSize.height()
          if !desiredHeight? then desiredHeight = 0
          desiredHeight = childSize.height()

    if !desiredWidth?
      desiredWidth = @desiredWidth

    if !desiredHeight?
      desiredHeight = @desiredHeight

    # TBD the exact shape of @checkDesiredDimCache
    @checkDesiredDimCache = true
    @desiredDimCache = new Dimension desiredWidth, desiredHeight

    return @desiredDimCache.min @getRecursiveMaxDim()


  getRecursiveMinDim: ->
    # TBD the exact shape of @checkMinDimCache
    #if @checkMinDimCache
    #  # the user might have forced the "desired" to
    #  # be smaller than the standard minimum set by
    #  # the widget
    #  return Math.min @minDimCache, @getRecursiveDesiredDim()

    minWidth = null
    minHeight = null
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C.getMinDim()
        minWidth += childSize.width()
        if minHeight < childSize.height()
          minHeight = childSize.height()

    if !minWidth?
      minWidth = @minWidth

    if !minHeight?
      minHeight = @minHeight

    # TBD the exact shape of @checkMinDimCache
    @checkMinDimCache = true
    @minDimCache = new Dimension minWidth, minHeight

    # the user might have forced the "desired" to
    # be smaller than the standard minimum set by
    # the widget
    return @minDimCache.min @getRecursiveMaxDim()

  getRecursiveMaxDim: ->

    # TBD the exact shape of @checkMaxDimCache
    #if @checkMaxDimCache
    #  # the user might have forced the "desired" to
    #  # be bigger than the standard maximum set by
    #  # the widget
    #  return Math.max @maxDimCache, @getRecursiveDesiredDim()

    maxWidth = null
    maxHeight = null
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        childSize = C.getMaxDim()
        maxWidth += childSize.width()
        if maxHeight < childSize.height()
          maxHeight = childSize.height()

    if !maxWidth?
      maxWidth = @maxWidth

    if !maxHeight?
      maxHeight = @maxHeight

    # TBD the exact shape of @checkMaxDimCache
    @checkMaxDimCache = true
    @maxDimCache = new Dimension maxWidth, maxHeight

    # the user might have forced the "desired" to
    # be bigger than the standard maximum set by
    # the widget
    return @maxDimCache

  countOfChildrenToLayout: ->
    count = 0
    for C in @children
      if C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
        count++
    return count

  doLayout: (newBoundsForThisLayout = @boundingBox()) ->

    #if (@ instanceof LayoutableMorph) and (newBoundsForThisLayout.eq @boundingBox())
    #  debugger

    # freefloating layouts never need
    # adjusting. We marked the @layoutIsValid
    # to false because it's an important breadcrumb
    # for finding the morphs that actually have a
    # layout to be recalculated but this Morph
    # now needs to do nothing.
    #if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING
    #  @layoutIsValid = true
    #  return
    
    # todo should we do a fullChanged here?
    # rather than breaking what could be many
    # rectangles?
    @rawSetBounds newBoundsForThisLayout

    min = @getRecursiveMinDim()
    desired = @getRecursiveDesiredDim()
    max = @getRecursiveMaxDim()
    
    # we are forced to be in a space smaller
    # than the minimum. We obey.
    if min.width() >= newBoundsForThisLayout.width()
      if @parent == world then console.log "case 1"
      # Give all children under minimum
      # this is unfortunate but
      # we don't want to rely on clipping what's
      # beyond the allocated space. Clipping
      # in this Morphic implementation has special
      # status and we don't want to meddle with
      # that.
      # example: if newBoundsForThisLayout.width() is 10 and min.width() is 50
      # then reductionFraction = 1/5 , i.e. all the minimums
      # will be further reduced to fit
      reductionFraction = newBoundsForThisLayout.width() / min.width()
      childLeft = newBoundsForThisLayout.left()
      for C in @children
        if C.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED then continue
        childBounds = new Rectangle \
          childLeft,
          newBoundsForThisLayout.top(),
          childLeft +  C.getMinDim().width() * reductionFraction,
          newBoundsForThisLayout.top() + newBoundsForThisLayout.height()
        childLeft += childBounds.width()
        C.doLayout childBounds

    # the min is within the bounds but the desired is just
    # equal or larger than the bounds.
    # give min to all and then what is left available
    # redistribute proportionally based on desired
    else if desired.width() >= newBoundsForThisLayout.width()
      if @parent == world then console.log "case 2"
      desiredMargin = desired.width() - min.width()
      if desiredMargin != 0
        fraction = (newBoundsForThisLayout.width() - min.width()) / desiredMargin
      else
        fraction = 0      
      childLeft = newBoundsForThisLayout.left()
      for C in @children
        if C.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED then continue
        minWidth = C.getMinDim().width()
        desWidth = C.getDesiredDim().width()
        childBounds = new Rectangle \
          childLeft,
          newBoundsForThisLayout.top(),
          childLeft + minWidth + (desWidth - minWidth)*fraction,
          newBoundsForThisLayout.top() + newBoundsForThisLayout.height()
        childLeft += childBounds.width()
        C.doLayout childBounds

    # min and desired are strictly less than the bounds
    # hence we have more space than needed,
    # allocate extra space based on maximum widths
    else
      maxMargin = max.width()-desired.width()
      totDesWidth = desired.width()
      maxWidth = null
      desWidth = null
      extraSpace = newBoundsForThisLayout.width() - desired.width()
      if extraSpace < 0
        alert "extraSpace is negative"
      if @parent == world then console.log "case 3 maxMargin: " + maxMargin

      if maxMargin > 0
        ssss = 0
      else if maxMargin == 0
        ssss = 1
      else
        alert "maxMargin negative"

      childLeft = newBoundsForThisLayout.left()
      for C in @children
        #if (C instanceof LayoutableMorph) and (C.children.length != 0)
        #  debugger
        if C.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED then continue
        maxWidth = C.getMaxDim().width()
        desWidth = C.getDesiredDim().width()
        if (maxWidth - desWidth) > 0
          xtra = extraSpace * ((maxWidth - desWidth)/maxMargin)
        else
          xtra = 0
        childBounds = new Rectangle \
          childLeft,
          newBoundsForThisLayout.top(),
          childLeft + desWidth + xtra + ssss * (newBoundsForThisLayout.width()-desired.width()) * (desWidth / totDesWidth),
          newBoundsForThisLayout.top() + newBoundsForThisLayout.height()
        childLeft += childBounds.width()
        if childLeft > newBoundsForThisLayout.right() + 5
          debugger
        C.doLayout childBounds

    @layoutIsValid = true
