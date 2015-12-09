# LayoutableMorph //////////////////////////////////////////////////////

# This is gonna trampoline a second version of the layout system.

# this comment below is needed to figure out dependencies between classes
# REQUIRES LayoutSpec


class LayoutableMorph extends Morph

  overridingDesiredDim: null

  # attaches submorph on top
  add: (aMorph, position = null, layoutSpec = LayoutSpec.FREEFLOATING ) ->

    if layoutSpec == LayoutSpec.FREEFLOATING
      return super
    else
      super
      aMorph.layoutSpec = layoutSpec
      @invalidateLayout()

  setDesiredDim: (@overridingDesiredDim) ->
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
      if C.layoutSpec == LayoutSpec.HORIZONTAL_STACK
        childSize = C.getDesiredDim()
        desiredWidth += childSize.width()
        if desiredHeight < childSize.height()
          desiredHeight = childSize.height()

    if !desiredWidth?
      desiredWidth = 20

    if !desiredHeight?
      desiredHeight = 20

    # TBD the exact shape of @checkDesiredDimCache
    @checkDesiredDimCache = true
    @desiredDimCache = new Dimension desiredWidth, desiredHeight

    return @desiredDimCache


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
      if C.layoutSpec == LayoutSpec.HORIZONTAL_STACK
        childSize = C.getMinDim()
        minWidth += childSize.width()
        if minHeight < childSize.height()
          minHeight = childSize.height()

    if !minWidth?
      minWidth = 20

    if !minHeight?
      minHeight = 20

    # TBD the exact shape of @checkMinDimCache
    @checkMinDimCache = true
    @minDimCache = new Dimension minWidth, minHeight

    # the user might have forced the "desired" to
    # be smaller than the standard minimum set by
    # the widget
    return @minDimCache.min @getDesiredDim()

  getMaxDim: ->
    # TBD the exact shape of @checkMaxDimCache
    #if @checkMaxDimCache
    #  # the user might have forced the "desired" to
    #  # be bigger than the standard maximum set by
    #  # the widget
    #  return Math.max @maxDimCache, @getDesiredDim()

    maxWidth = null
    maxHeight = null
    for C in @children
      if C.layoutSpec == LayoutSpec.HORIZONTAL_STACK
        childSize = C.getMaxDim()
        maxWidth += childSize.width()
        if maxHeight < childSize.height()
          maxHeight = childSize.height()

    if !maxWidth?
      maxWidth = 20

    if !maxHeight?
      maxHeight = 20

    # TBD the exact shape of @checkMaxDimCache
    @checkMaxDimCache = true
    @maxDimCache = new Dimension maxWidth, maxHeight

    # the user might have forced the "desired" to
    # be bigger than the standard maximum set by
    # the widget
    return @maxDimCache.max @getDesiredDim()

  countOfChildrenToLayout: ->
    count = 0
    for C in @children
      if C.layoutSpec == LayoutSpec.HORIZONTAL_STACK
        count++
    return count


  doLayout: (newBounds = @boundingBox()) ->

    # freefloating layouts never need
    # adjusting. We marked the @layoutIsValid
    # to false because it's an important breadcrumb
    # for finding the morphs that actually have a
    # layout to be recalculated but this Morph
    # now needs to do nothing.
    #if @layoutSpec == LayoutSpec.FREEFLOATING
    #  @layoutIsValid = true
    #  return
    
    # todo should we do a fullChanged here?
    # rather than breaking what could be many
    # rectangles?
    debugger
    @rawSetBounds newBounds

    min = @getMinDim()
    desired = @getDesiredDim()
    max = @getMaxDim()
    
    # we are forced to be in a space smaller
    # than the minimum. We obey.
    if min.width() >= newBounds.width()
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
        childBounds = new Rectangle \
          childLeft,
          newBounds.top(),
          childLeft +  C.getMinDim().width() * reductionFraction,
          newBounds.top() + newBounds.height()
        childLeft += childBounds.width()
        C.doLayout childBounds
    # the min is within the bounds but the desired is just
    # equal or larger than the bounds.
    else if desired.width() >= newBounds.width()
      # give min to all and then what is left available
      # redistribute proportionally based on desired1
      desiredMargin = desired.width() - min.width()
      fraction = (newBounds.width() - min.width()) / desiredMargin
      childLeft = newBounds.left()
      for C in @children
        minWidth = C.getMinDim().width()
        desWidth = C.getDesiredDim().width()
        childBounds = new Rectangle \
          childLeft,
          newBounds.top(),
          childLeft + minWidth + (desWidth-minWidth)*fraction,
          newBounds.top() + newBounds.height()
        childLeft += childBounds.width()
        C.doLayout childBounds
    else
      # allocate what remains based on maximum widths
      maxMargin = max.width()-desired.width()
      if maxMargin != 0
        fraction = (newBounds.width()-desired.width()) / maxMargin
      else
        fraction = 0
      childLeft = newBounds.left()
      for C in @children
        maxWidth = C.getMaxDim().width()
        desWidth = C.getDesiredDim().width()
        childBounds = new Rectangle \
          childLeft,
          newBounds.top(),
          childLeft + maxWidth + (desWidth-maxWidth)*fraction,
          newBounds.top() + newBounds.height()
        childLeft += childBounds.width()
        C.doLayout childBounds

    @layoutIsValid = true
