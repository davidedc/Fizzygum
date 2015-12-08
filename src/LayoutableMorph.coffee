# LayoutableMorph //////////////////////////////////////////////////////

# This is gonna trampoline a second version of the layout system.

# this comment below is needed to figure out dependencies between classes
# REQUIRES LayoutSpec


class LayoutableMorph extends Morph

  overridingDesiredDim: null

  add: (aMorph, position = null, layoutSpec = LayoutSpec.FREEFLOATING ) ->
    
    if layoutSpec == LayoutSpec.FREEFLOATING
      return super
    else
      super
      aMorph.layoutSpec = layoutSpec

  setDesiredDim: (@overridingDesiredDim) ->


  getDesiredDim: ->
    
    if @overridingDesiredDim?
      return @overridingDesiredDim

    # TBD the exact shape of @checkDesiredDimCache
    #if @checkDesiredDimCache
    #  return @desiredDimCache

    desiredWidth = -1
    desiredHeight = -1
    for C in @children
      if C.layoutSpec == LayoutSpec.HORIZONTAL_STACK
        childSize = C.getDesiredDim()
        desiredWidth += childSize.width()
        if desiredHeight < childSize.height()
          desiredHeight = childSize.height()

    if desiredWidth == -1
      desiredWidth = 20

    if desiredHeight == -1
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

    minWidth = -1
    minHeight = -1
    for C in @children
      if C.layoutSpec == LayoutSpec.HORIZONTAL_STACK
        childSize = C.getMinDim()
        minWidth += childSize.width()
        if minHeight < childSize.height()
          minHeight = childSize.height()

    if minWidth == -1
      minWidth = 20

    if minHeight == -1
      minHeight = 20

    # TBD the exact shape of @checkMinDimCache
    @checkMinDimCache = true
    @minDimCache = new Dimension minWidth, minHeight

    # the user might have forced the "desired" to
    # be smaller than the standard minimum set by
    # the widget
    return Math.min(@minDimCache, @getDesiredDim())

  getMaxDim: ->
    # TBD the exact shape of @checkMaxDimCache
    #if @checkMaxDimCache
    #  # the user might have forced the "desired" to
    #  # be bigger than the standard maximum set by
    #  # the widget
    #  return Math.max @maxDimCache, @getDesiredDim()

    maxWidth = -1
    maxHeight = -1
    for C in @children
      if C.layoutSpec == LayoutSpec.HORIZONTAL_STACK
        childSize = C.getMaxDim()
        maxWidth += childSize.width()
        if maxHeight < childSize.height()
          maxHeight = childSize.height()

    if maxWidth == -1
      maxWidth = 20

    if maxHeight == -1
      maxHeight = 20

    # TBD the exact shape of @checkMaxDimCache
    @checkMaxDimCache = true
    @maxDimCache = new Dimension maxWidth, maxHeight

    # the user might have forced the "desired" to
    # be bigger than the standard maximum set by
    # the widget
    return Math.max(@maxDimCache, @getDesiredDim())
