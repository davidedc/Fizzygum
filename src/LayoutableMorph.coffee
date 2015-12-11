# LayoutableMorph //////////////////////////////////////////////////////

# This is gonna trampoline a second version of the layout system.

# this comment below is needed to figure out dependencies between classes
# REQUIRES LayoutSpec


class LayoutableMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  overridingDesiredDim: null

  minWidth: 10
  desiredWidth: 20
  maxWidth: 100

  minHeight: 10
  desiredHeight: 20
  maxHeight: 100

  setMinAndMaxBoundsAndSpreadability: (minBounds, desiredBounds, spreadability = LayoutSpec.SPREADABILITY_MEDIUM) ->
    @minWidth = minBounds.x
    @minHeight = minBounds.y

    @desiredWidth = desiredBounds.x
    @desiredHeight = desiredBounds.y

    @maxWidth = desiredBounds.x + spreadability * desiredBounds.x/100
    @maxHeight = desiredBounds.y + spreadability * desiredBounds.y/100

    @invalidateLayout()


  setMaxDim: (overridingMaxDim) ->
    @overridingMaxDim = overridingMaxDim
    @invalidateLayout()

  setDesiredDim: (overridingDesiredDim) ->
    @overridingDesiredDim = overridingDesiredDim

    ###
    minWidthPerc = @minWidth / @desiredWidth
    minHeightPerc = @minHeight / @desiredHeight
    maxWidthPerc = @maxWidth / @desiredWidth
    maxHeightPerc = @maxHeight / @desiredHeight


    @desiredWidth = overridingDesiredDim.x
    @desiredHeight = overridingDesiredDim.y

    @maxWidth = @desiredWidth * maxWidthPerc
    @maxHeight = @desiredHeight * maxHeightPerc
    #@minWidth = @desiredWidth * minWidthPerc
    #@minHeight = @desiredHeight * minHeightPerc
    ###

    @invalidateLayout()


  getDesiredDim: ->
    
    if @overridingDesiredDim?
      return @overridingDesiredDim

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

    return @desiredDimCache.min @getMaxDim()


  getMinDim: ->
    # TBD the exact shape of @checkMinDimCache
    #if @checkMinDimCache
    #  # the user might have forced the "desired" to
    #  # be smaller than the standard minimum set by
    #  # the widget
    #  return Math.min @minDimCache, @getDesiredDim()

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
    return @minDimCache.min @getMaxDim()

  getMaxDim: ->
    if @overridingMaxDim?
      return @overridingMaxDim

    # TBD the exact shape of @checkMaxDimCache
    #if @checkMaxDimCache
    #  # the user might have forced the "desired" to
    #  # be bigger than the standard maximum set by
    #  # the widget
    #  return Math.max @maxDimCache, @getDesiredDim()

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

  doLayout: (newBounds = @boundingBox()) ->

    debugger
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
    @rawSetBounds newBounds

    min = @getMinDim()
    desired = @getDesiredDim()
    max = @getMaxDim()
    
    # we are forced to be in a space smaller
    # than the minimum. We obey.
    if min.width() >= newBounds.width()
      if @parent == world then console.log "case 1"
      # Give all children under minimum
      # this is unfortunate but
      # we don't want to rely on clipping what's
      # beyond the allocated space. Clipping
      # in this Morphic implementation has special
      # status and we don't want to meddle with
      # that.
      # example: if newBounds.width() is 10 and min.width() is 50
      # then reductionFraction = 1/5 , i.e. all the minimums
      # will be further reduced to fit
      reductionFraction = newBounds.width() / min.width()
      childLeft = newBounds.left()
      for C in @children
        if C.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED then continue
        childBounds = new Rectangle \
          childLeft,
          newBounds.top(),
          childLeft +  C.getMinDim().width() * reductionFraction,
          newBounds.top() + newBounds.height()
        childLeft += childBounds.width()
        C.doLayout childBounds

    # the min is within the bounds but the desired is just
    # equal or larger than the bounds.
    # give min to all and then what is left available
    # redistribute proportionally based on desired1
    else if desired.width() >= newBounds.width()
      if @parent == world then console.log "case 2"
      desiredMargin = desired.width() - min.width()
      if desiredMargin != 0
        fraction = (newBounds.width() - min.width()) / desiredMargin
      else
        fraction = 0      
      childLeft = newBounds.left()
      for C in @children
        if C.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED then continue
        minWidth = C.getMinDim().width()
        desWidth = C.getDesiredDim().width()
        childBounds = new Rectangle \
          childLeft,
          newBounds.top(),
          childLeft + minWidth + (desWidth - minWidth)*fraction,
          newBounds.top() + newBounds.height()
        childLeft += childBounds.width()
        C.doLayout childBounds

    # min and desired are strictly less than the bounds
    # hence we have more space than needed,
    # allocate extra space based on maximum widths
    else
      maxMargin = max.width()-desired.width()
      totDesWidth = desired.width()
      extraSpace = newBounds.width() - desired.width()
      if @parent == world then console.log "case 3 maxMargin: " + maxMargin

      if maxMargin > 0
        fraction = (newBounds.width()-desired.width()) / maxMargin
        absolute = 0
        ssss = 0
        #fraction = 0
        #absolute = (newBounds.width()-desired.width()) / @countOfChildrenToLayout()
      else if maxMargin == 0
        fraction = 0
        #absolute = 0
        absolute = (newBounds.width()-desired.width()) / @countOfChildrenToLayout()
        ssss = 1
      else
        alert "maxMargin negative"

      childLeft = newBounds.left()
      for C in @children
        if C.layoutSpec != LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED then continue
        maxWidth = C.getMaxDim().width()
        desWidth = C.getDesiredDim().width()
        if (maxWidth - desWidth) > 0
          xtra = extraSpace * ((maxWidth - desWidth)/maxMargin)
        else
          xtra = 0
        childBounds = new Rectangle \
          childLeft,
          newBounds.top(),
          childLeft + desWidth + xtra + ssss * (newBounds.width()-desired.width()) * (desWidth / totDesWidth),
          newBounds.top() + newBounds.height()
        childLeft += childBounds.width()
        C.doLayout childBounds

    @layoutIsValid = true
