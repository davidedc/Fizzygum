# LayoutMorph

# this comment below is needed to figure our dependencies between classes
# REQUIRES Color
# REQUIRES Point
# REQUIRES Rectangle

# This is a port of the
# respective Cuis Smalltalk classes (version 4.2-1766)
# Cuis is by Juan Vuletich

# A row or column of widgets, does layout by placing
# them either horizontally or vertically.

# Submorphs might specify a LayoutSpec.
# If some don't, then, for a column, the column
# width is taken as the width, and any morph height
# is kept. Same for rows: submorph width would be
# maintained, and submorph height would be made
# equal to row height.

class LayoutMorph extends Morph

  instanceVariableNames: 'direction separation padding'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Morphic-Layouts'

  direction: ""
  padding: 0
  separation: null # contains a Point
  layoutNeeded: false
  layoutBounds: null
  proportionalWidthNormalizationFactor: 1

  constructor: ->
    @separation = new Point 0,0
  
  @newColumn: ->
    return (new LayoutMorph).beColumn()

  @newRow: ->
    return (new LayoutMorph).beRow()

  beColumn: ->
    @direction = "#vertical"
    @setPadding "#center"

  beRow: ->
    @direction = "#horizontal"
    @setPadding= "#left"

  defaultColor: ->
    return Color.transparent()

  # This sets how extra space is used when doing layout.
  # For example, a column might have extra , unneded
  # vertical space. #top means widgets are set close
  # to the top, and extra space is at bottom. Conversely,
  # #bottom means widgets are set close to the bottom,
  # and extra space is at top. Valid values include
  # #left and #right (for rows) and #center. Alternatively,
  # any number between 0.0 and 1.0 might be used.
  #   self new padding: #center
  #   self new padding: 0.9
  setPadding: (howMuchPadding) ->
    switch howMuchPadding
      when "#top" then @padding = 0.0
      when "#left" then @padding = 0.0
      when "#center" then @padding = 0.5
      when "#right" then @padding = 1.0
      when "#bottom" then @padding = 1.0
      else @padding = howMuchPadding

  setSeparation: (howMuchSeparation) ->
    @separation = howMuchSeparation

  xSeparation: ->
    return @separation.x

  ySeparation: ->
    return @separation.y

  # Compute a new layout based on the given layout bounds
  layoutSubmorphs: ->
    if @children.length == 0
      @layoutNeeded = false
      return @

    if @direction == "#horizontal"
      @layoutSubmorphsHorizontallyIn @,@layoutBounds

    if @direction == "#vertical"
      @layoutSubmorphsVerticallyIn @,@layoutBounds

    @layoutNeeded = false

  # Compute a new layout based on the given layout bounds.
  layoutSubmorphsHorizontallyIn: (boundsForLayout) ->
    #| xSep ySep usableWidth sumOfFixed normalizationFactor availableForPropWidth widths l usableHeight boundsTop boundsRight t |
    xSep = @xSeparation()
    ySep = @ySeparation()
    usableWidth = boundsForLayout.width() - ((@children.length + 1) * xSep)
    sumOfFixed = 0
    @children.forEach (child) =>
      if child.layoutSpec?
        if child.layoutSpec.fixedWidth?
          sumOfFixed += child.layoutSpec.fixedWidth
    availableForPropWidth = usableWidth - sumOfFixed
    normalizationFactor = @proportionalWidthNormalizationFactor
    availableForPropWidth = availableForPropWidth * normalizationFactor
    widths = []
    sumOfWidths = 0
    @children.forEach (child) =>
      if child.layoutSpec?
        theWidth = child.layoutSpec.widthFor availableForPropWidth
        sumOfWidths += theWidth
        widths.append theWidth
    l = ((usableWidth - sumOfWidths) * padding + Math.max(xSep, 0)) +  boundsForLayout.left()
    usableHeight = boundsForLayout.height() - Math.max(2*ySep,0)
    boundsTop = boundsForLayout.top()
    boundsRight = boundsForLayout.right()
    for i in [children.length-1 .. 0]
      m = @children[i]
      # major direction
      w = widths[i]
      # minor direction
      ls = m.layoutSpec
      h = Math.min(usableHeight, ls.heightFor(usableHeight))
      t = (usableHeight - h) * ls.minorDirectionPadding() + ySep + boundsTop
      # Set bounds and adjust major direction for next step
      # self flag: #jmvVer2.
      # should extent be set in m's coordinate system? what if its scale is not 1?
      m.setPosition(new Point(l,t))
      m.setExtent(Math.min(w,boundsForLayout.width()),h)
      if w>0
        l = Math.min(l + w + xSep, boundsRight)

  # this is the symetric of the previous method
  layoutSubmorphsVerticallyIn: (boundsForLayout) ->
    usableHeight boundsTop boundsRight t |
    xSep = @xSeparation()
    ySep = @ySeparation()
    usableWidth = boundsForLayout.height() - ((@children.length + 1) * ySep)
    sumOfFixed = 0
    @children.forEach (child) =>
      if child.layoutSpec?
        if child.layoutSpec.fixedWidth?
          sumOfFixed += child.layoutSpec.fixedHeight
    availableForPropHeight = usableHeight - sumOfFixed
    normalizationFactor = @proportionalHeightNormalizationFactor
    availableForPropHeight = availableForPropHeight * normalizationFactor
    heights = []
    sumOfHeights = 0
    @children.forEach (child) =>
      if child.layoutSpec?
        theHeight = child.layoutSpec.heightFor availableForPropHeight
        sumOfHeights += theHeight
        heights.append theHeight
    t = ((usableHeight - sumOfHeights) * padding + Math.max(ySep, 0)) +  boundsForLayout.top()
    usableWidth = boundsForLayout.width() - Math.max(2*xSep,0)
    boundsBottom = boundsForLayout.bottom()
    boundsLeft = boundsForLayout.left()
    for i in [children.length-1 .. 0]
      m = @children[i]
      # major direction
      h = heights[i]
      # minor direction
      ls = m.layoutSpec
      w = Math.min(usableWidth, ls.widthFor(usableWidth))
      l = (usableWidth - w) * ls.minorDirectionPadding() + xSep + boundsLeft
      # Set bounds and adjust major direction for next step
      # self flag: #jmvVer2.
      # should extent be set in m's coordinate system? what if its scale is not 1?
      m.setPosition(new Point(l,t))
      m.setExtent(Math.min(w,boundsForLayout.height()),h)
      if h>0
        t = Math.min(t + h + ySep, boundsBottom)

    # So the user can adjust layout
    addAdjusterMorph: ->
      thickness = 4

      if @direction == "#horizontal"
        @addMorph( new LayoutAdjustingMorph() )
        @layoutSpec = LayoutSpec.fixedWidth(thickness)

      if @direction == "#vertical"
        @addMorph( new LayoutAdjustingMorph() )
        @layoutSpec = LayoutSpec.fixedHeight(thickness)

