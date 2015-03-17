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
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  instanceVariableNames: 'direction separation padding'
  classVariableNames: ''
  poolDictionaries: ''
  category: 'Morphic-Layouts'

  direction: ""
  padding: 0
  separation: null # contains a Point
  layoutNeeded: false

  constructor: ->
    super()
    @separation = new Point 0,0
  
  @newColumn: ->
    newLayoutMorph =  new @()
    newLayoutMorph.beColumn()
    return newLayoutMorph

  @newRow: ->
    #debugger
    newLayoutMorph =  new @()
    newLayoutMorph.beRow()
    return newLayoutMorph

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
    console.log "layoutSubmorphs in LayoutMorph"
    #debugger
    if @children.length == 0
      @layoutNeeded = false
      return @

    if @direction == "#horizontal"
      @layoutSubmorphsHorizontallyIn @bounds

    if @direction == "#vertical"
      @layoutSubmorphsVerticallyIn @bounds

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
          sumOfFixed += child.layoutSpec.getFixedWidth()
    availableForPropWidth = usableWidth - sumOfFixed
    normalizationFactor = @proportionalWidthNormalizationFactor()
    availableForPropWidth = availableForPropWidth * normalizationFactor
    widths = []
    sumOfWidths = 0
    @children.forEach (child) =>
      if child.layoutSpec?
        #debugger
        theWidth = child.layoutSpec.widthFor availableForPropWidth
        sumOfWidths += theWidth
        widths.push theWidth
    l = ((usableWidth - sumOfWidths) * @padding + Math.max(xSep, 0)) +  boundsForLayout.left()
    usableHeight = boundsForLayout.height() - Math.max(2*ySep,0)
    boundsTop = boundsForLayout.top()
    boundsRight = boundsForLayout.right()
    for i in [@children.length-1 .. 0]
      m = @children[i]
      # major direction
      w = widths[i]
      # minor direction
      ls = m.layoutSpec
      if not ls?
        # there might be submorphs that don't have a layout.
        # for example, currently, the HandleMorph can be attached
        # to the LayoutMorph without a layoutSpec.
        # just skip those. The HandleMorph does its own
        # layouting.
        continue
      h = Math.min(usableHeight, ls.heightFor(usableHeight))
      t = (usableHeight - h) * ls.minorDirectionPadding + ySep + boundsTop
      # Set bounds and adjust major direction for next step
      # self flag: #jmvVer2.
      # should extent be set in m's coordinate system? what if its scale is not 1?
      m.setPosition(new Point(l,t))
      #debugger
      m.setExtent(new Point(Math.min(w,boundsForLayout.width()),h))
      if w>0
        l = Math.min(l + w + xSep, boundsRight)

  # this is the symmetric of the previous method
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
        heights.push theHeight
    t = ((usableHeight - sumOfHeights) * @padding + Math.max(ySep, 0)) +  boundsForLayout.top()
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

  #"Add a submorph, at the bottom or right, with aLayoutSpec"
  addMorphWithLayoutSpec: (aMorph, aLayoutSpec) ->
    aMorph.layoutSpec = aLayoutSpec
    @addMorph aMorph

  minPaneHeightForReframe: ->
    return 20

  minPaneWidthForReframe: ->
    return 40

  proportionalHeightNormalizationFactor: ->
    sumOfProportional = 0
    @children.forEach (child) =>
      if child.layoutSpec?
        sumOfProportional += child.layoutSpec.proportionalHeight()
    return 1.0/Math.max(sumOfProportional, 1.0)

  proportionalWidthNormalizationFactor: ->
    sumOfProportional = 0
    @children.forEach (child) =>
      if child.layoutSpec?
        sumOfProportional += child.layoutSpec.getProportionalWidth()
    return 1.0/Math.max(sumOfProportional, 1.0)

  adjustByAt: (aLayoutAdjustMorph, aPoint) ->
    if @direction == "#horizontal"
      @adjustHorizontallyByAt aLayoutAdjustMorph, aPoint

    if @direction == "#vertical"
      @adjustVerticallyByAt aLayoutAdjustMorph, aPoint

  adjustHorizontallyByAt: (aLayoutAdjustMorph, aPoint) ->
    # | delta l ls r rs lNewWidth rNewWidth i lCurrentWidth rCurrentWidth doNotResizeBelow |
    doNotResizeBelow =  @minPaneWidthForReframe
    i = @children[aLayoutAdjustMorph]
    l = @children[i+1]
    ls = l.layoutSpec
    lCurrentWidth = Math.max(l.morphWidth(),1) # avoid division by zero
    r = @children[i - 1]
    rs = r.layoutSpec
    rCurrentWidth = Math.max(r.morphWidth(),1) # avoid division by zero
    delta = aPoint.x - aLayoutAdjustMorph.position().x
    delta = Math.max(delta, doNotResizeBelow - lCurrentWidth)
    delta = Math.min(delta, rCurrentWidth - doNotResizeBelow)
    if delta == 0 then return @
    rNewWidth = rCurrentWidth - delta
    lNewWidth = lCurrentWidth + delta
    if ls.isProportionalWidth() and rs.isProportionalWidth()
      # If both proportional, update them
      ls.setProportionalWidth 1.0 * lNewWidth / lCurrentWidth * ls.proportionalWidth()
      rs.setProportionalWidth 1.0 * rNewWidth / rCurrentWidth * rs.proportionalWidth()
    else
      # If at least one is fixed, update only the fixed
      if !ls.isProportionalWidth()
          ls.fixedOrMorphWidth lNewWidth
      if !rs.isProportionalWidth()
          rs.fixedOrMorphWidth rNewWidth
    @layoutSubmorphs()

  adjustVerticallyByAt: (aLayoutAdjustMorph, aPoint) ->
    # | delta t ts b bs tNewHeight bNewHeight i tCurrentHeight bCurrentHeight doNotResizeBelow |
    doNotResizeBelow = @minPaneHeightForReframe()
    i = @children[aLayoutAdjustMorph]
    t = @children[i+1]
    ts = t.layoutSpec()
    tCurrentHeight = Math.max(t.morphHeight(),1) # avoid division by zero
    b = @children[i - 1]
    bs = b.layoutSpec
    bCurrentHeight = Math.max(b.morphHeight(),1) # avoid division by zero
    delta = aPoint.y - aLayoutAdjustMorph.position().y
    delta = Math.max(delta, doNotResizeBelow - tCurrentHeight)
    delta = Math.min(delta, bCurrentHeight - doNotResizeBelow)
    if delta == 0 then return @
    tNewHeight = tCurrentHeight + delta
    bNewHeight = bCurrentHeight - delta
    if ts.isProportionalHeight() and bs.isProportionalHeight()
      # If both proportional, update them
      ts.setProportionalHeight 1.0 * tNewHeight / tCurrentHeight * ts.proportionalHeight()
      bs.setProportionalHeight 1.0 * bNewHeight / bCurrentHeight * bs.proportionalHeight()
    else
      # If at least one is fixed, update only the fixed
      if !ts.isProportionalHeight()
          ts.fixedOrMorphHeight tNewHeight
      if !bs.isProportionalHeight()
          bs.fixedOrMorphHeight bNewHeight
    @layoutSubmorphs()

  #####################
  # convenience methods
  #####################

  addAdjusterAndMorphFixedHeight: (aMorph,aNumber) ->
    @addAdjusterAndMorphLayoutSpec(aMorph, LayoutSpec.newWithFixedHeight aNumber)

  addAdjusterAndMorphLayoutSpec: (aMorph, aLayoutSpec) ->
    #Add a submorph, at the bottom or right, with aLayoutSpec"
    @addAdjusterMorph()
    @addMorphLayoutSpec(aMorph, aLayoutSpec)

  addAdjusterAndMorphProportionalHeight: (aMorph, aNumber) ->
    @addAdjusterAndMorphLayoutSpec(aMorph, LayoutSpec.newWithProportionalHeight(aNumber))

  addAdjusterAndMorphProportionalWidth: (aMorph, aNumber) ->
    @addAdjusterAndMorphLayoutSpec(aMorph, LayoutSpec.newWithProportionalWidth(aNumber))

  addMorphFixedHeight: (aMorph, aNumber) ->
    @addMorphLayoutSpec(aMorph, LayoutSpec.newWithFixedHeight(aNumber))

  addMorphFixedWidth: (aMorph, aNumber) ->
    @addMorphLayoutSpec(aMorph, LayoutSpec.newWithFixedWidth(aNumber))

  addMorphLayoutSpec: (aMorph, aLayoutSpec) ->
    # Add a submorph, at the bottom or right, with aLayoutSpec
    aMorph.layoutSpec = aLayoutSpec
    @add aMorph

  addMorphProportionalHeight: (aMorph, aNumber) ->
    @addMorphLayoutSpec(aMorph, LayoutSpec.newWithProportionalHeight(aNumber))

  addMorphProportionalWidth: (aMorph, aNumber) ->
    @addMorphLayoutSpec(aMorph, LayoutSpec.newWithProportionalWidth(aNumber))

  addMorphUseAll: (aMorph) ->
    @addMorphLayoutSpec(aMorph, LayoutSpec.useAll())

  addMorphs: (morphs) ->
    morphs.forEach (morph) =>
      @addMorphProportionalWidth(m,1)

  addMorphsWidthProportionalTo: (morphs, widths) ->
    morphs.forEach (morph) =>
      @addMorphProportionalWidth(m,w)

  # unclear how to translate this one for the time being
  is: (aSymbol) ->
    return aSymbol == "#LayoutMorph" # or [ super is: aSymbol ]

  @test1: ->
    rect1 = new RectangleMorph(new Point(20,20), new Color(255,0,0));
    rect2 = new RectangleMorph(new Point(20,20), new Color(0,255,0));
    row = LayoutMorph.newRow()
    row.addMorphProportionalWidth(rect1,2)
    row.addMorphProportionalWidth(rect2,1)
    row.layoutSubmorphs()
    row.setPosition(world.hand.position());
    row.keepWithin(world);
    world.add(row);
    row.changed();

    # attach a HandleMorph to it so that
    # we can check how it resizes
    handle = new HandleMorph()
    handle.isDraggable = false
    handle.target = row
    handle.updateBackingStore()
    handle.noticesTransparentClick = true

  @test2: ->
    rect3 = new RectangleMorph(new Point(20,20), new Color(255,0,0));
    rect4 = new RectangleMorph(new Point(20,20), new Color(0,255,0));
    row2 = LayoutMorph.newRow()
    row2.addMorphFixedWidth(rect3,10)
    row2.addMorphProportionalWidth(rect4,1)
    row2.layoutSubmorphs()
    row2.setPosition(world.hand.position());
    row2.keepWithin(world);
    world.add(row2);
    row2.changed();

    # attach a HandleMorph to it so that
    # we can check how it resizes
    handle = new HandleMorph()
    handle.isDraggable = false
    handle.target = row2
    handle.updateBackingStore()
    handle.noticesTransparentClick = true

  @test3: ->
    rect5 = new RectangleMorph(new Point(20,20), new Color(255,0,0));
    rect6 = new RectangleMorph(new Point(20,20), new Color(0,255,0));
    rect7 = new RectangleMorph(new Point(20,20), new Color(0,0,255));
    row3 = LayoutMorph.newRow()
    row3.addMorphProportionalWidth(rect6,2)
    row3.addMorphFixedWidth(rect5,10)
    row3.addMorphProportionalWidth(rect7,1)
    row3.layoutSubmorphs()
    row3.setPosition(world.hand.position());
    row3.keepWithin(world);
    world.add(row3);
    row3.changed();

    # attach a HandleMorph to it so that
    # we can check how it resizes
    handle = new HandleMorph()
    handle.isDraggable = false
    handle.target = row3
    handle.updateBackingStore()
    handle.noticesTransparentClick = true

  @test4: ->
    # //////////////////////////////////////////////////
    # note how the vertical spacing in the horizontal layout
    # is different. the vertical size is not adjusted considering
    # all other morphs. A proportional of 1.1 is proportional to the
    # container, not to the other layouts.
    # Equivalent smalltalk code:
    # | pane rect1 rect2 |
    # pane _ LayoutMorph newRow separation: 5. "3"
    # pane addMorph: (StringMorph contents: '3').
    # 
    # rect1 := BorderedRectMorph new color: (Color lightOrange).
    # pane addMorph: rect1 
    #          layoutSpec: (LayoutSpec  fixedWidth: 20 proportionalHeight: 1.1 minorDirectionPadding: #center).
    # rect2 := BorderedRectMorph new color: (Color cyan);
    #   layoutSpec: (LayoutSpec  fixedWidth: 20 proportionalHeight: 0.5 minorDirectionPadding: #center).
    # pane addMorph: rect2.
    # pane
    #   color: Color lightGreen;
    #   openInWorld;
    #   morphPosition: 520 @ 50;
    #   morphExtent: 180 @ 100
    # //////////////////////////////////////////////////

    rect5 = new RectangleMorph(new Point(20,20), new Color(255,0,0));
    rect6 = new RectangleMorph(new Point(20,20), new Color(0,255,0));
    rect7 = new RectangleMorph(new Point(20,20), new Color(0,0,255));
    row3 = LayoutMorph.newRow()
    row3.addMorphProportionalHeight(rect6,0.5)
    row3.addMorphFixedHeight(rect5,200)
    row3.addMorphProportionalHeight(rect7,1.1)
    row3.layoutSubmorphs()
    row3.setPosition(world.hand.position());
    row3.keepWithin(world);
    world.add(row3);
    row3.changed();

    # attach a HandleMorph to it so that
    # we can check how it resizes
    handle = new HandleMorph()
    handle.isDraggable = false
    handle.target = row3
    handle.updateBackingStore()
    handle.noticesTransparentClick = true #
