# LinearLayoutMorph

# this comment below is needed to figure out dependencies between classes
# REQUIRES Color
# REQUIRES Point
# REQUIRES Rectangle
# REQUIRES LinearLayoutAdjustingMorph

# This is a port of the
# LayoutMorph Cuis Smalltalk classe (version 4.2-1766)
# Cuis is by Juan Vuletich

# A Layout that arranges its children in a single column or a single row.
# I.e. a row or column of widgets, does layout by placing
# them either (respectively) horizontally or vertically.

# Submorphs might have a linearLinearLayoutSpec property
# specifying a LinearLayoutSpec.
# If some don't, then, for a column, the column
# width is taken as the width, and any morph height
# is kept. Same for rows: submorph width would be
# maintained, and submorph height would be made
# equal to row height.

class LinearLayoutMorph extends LayoutMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  instanceVariableNames: 'direction separation float'
  classVariableNames: ''
  poolDictionaries: ''

  direction: ""
  float: 0 # equivalent to #left, or #top
  separation: null # contains a Point

  constructor: ->
    super()
    @separation = new Point 0,0
  
  @newColumn: ->
    newLinearLayoutMorph =  new @()
    newLinearLayoutMorph.beColumn()
    return newLinearLayoutMorph

  @newRow: ->
    #debugger
    newLinearLayoutMorph =  new @()
    newLinearLayoutMorph.beRow()
    return newLinearLayoutMorph

  beColumn: ->
    @direction = "#vertical"
    @setFloat "#center"

  beRow: ->
    @direction = "#horizontal"
    @setFloat= "#left"

  defaultColor: ->
    return Color.transparent()

  # This sets how extra space is used when doing layout.
  # For example, a column might have extra , un-needed
  # vertical space. #top means widgets are set close
  # to the top, and extra space is at bottom. Conversely,
  # #bottom means widgets are set close to the bottom,
  # and extra space is at top. Valid values include
  # #left and #right (for rows) and #center. Alternatively,
  # any number between 0.0 and 1.0 might be used.
  #   self new float: #center
  #   self new float: 0.9
  setFloat: (howMuchFloat) ->
    switch howMuchFloat
      when "#top" then @float = 0.0
      when "#left" then @float = 0.0
      when "#center" then @float = 0.5
      when "#right" then @float = 1.0
      when "#bottom" then @float = 1.0
      else @float = howMuchFloat

  setSeparation: (@separation) ->

  xSeparation: ->
    return @separation.x

  ySeparation: ->
    return @separation.y

  # Compute a new layout based on the given layout bounds
  layoutSubmorphs: ->
    console.log "layoutSubmorphs in LinearLayoutMorph"
    #debugger
    if @children.length == 0
      @layoutNeeded = false
      return @

    @layoutSubmorphsWithinBounds @bounds, @direction

    @layoutNeeded = false

  # Compute a new layout based on the given layout bounds.
  horizontalErrorForMorphIfContainerHasWith: (tryingWidth, morph, intendedMorphWidth) ->


  # Compute a new layout based on the given layout bounds.
  # Note that the layout doesn't look at all at the current size
  # of the morphs inside the layout. It rather sets them based
  # on the bounds of the layout.
  layoutSubmorphsWithinBounds: (boundsForLayout, direction) ->
    debugger
    #| xSep ySep usableWidth sumOfFixed normalizationFactor availableForPropWidth widths l usableHeight boundsTop boundsRight t |
    xSep = @xSeparation()
    ySep = @ySeparation()

    if direction == "#horizontal"
      separationInMainDirection = xSep
      separationInMinorDirection = ySep
      minorDirectionStart = boundsForLayout.top()
      mainDirectionEnd = boundsForLayout.right()
      mainDirectionStart = boundsForLayout.left()

      mainDirectionBoundsExtent = boundsForLayout.width()
      minorDirectionBoundsExtent = boundsForLayout.height()
      fixedMainDirectionVarName = "fixedWidth"
      getFixedMainDirectionVarName = "getFixedWidth"
      mainDirectionForVarName = "widthFor"
      minorDirectionForVarName = "heightFor"
    else if direction == "#vertical"
      separationInMainDirection = ySep
      separationInMinorDirection = xSep
      minorDirectionStart = boundsForLayout.left()
      mainDirectionEnd = boundsForLayout.bottom()
      mainDirectionStart = boundsForLayout.top()

      mainDirectionBoundsExtent = boundsForLayout.height()
      minorDirectionBoundsExtent = boundsForLayout.width()
      fixedMainDirectionVarName = "fixedHeight"
      getFixedMainDirectionVarName = "getFixedHeight"
      mainDirectionForVarName = "heightFor"
      minorDirectionForVarName = "widthFor"


    usableMainDirectionSpace = mainDirectionBoundsExtent - ((@children.length + 1) * separationInMainDirection)
    sumOfFixed = 0
    @children.forEach (child) =>
      if child.linearLinearLayoutSpec?
        if child.linearLinearLayoutSpec[fixedMainDirectionVarName]?
          sumOfFixed += child.linearLinearLayoutSpec[getFixedMainDirectionVarName]()
    availableForPropMainDirection = usableMainDirectionSpace - sumOfFixed
    normalizationFactor = @proportionalMainDirectionNormalizationFactor()
    availableForPropMainDirection = availableForPropMainDirection * normalizationFactor
    mainDirections = []
    sumOfMainDirections = 0
    @children.forEach (child) =>
      if child.linearLinearLayoutSpec?
        #debugger
        theMainDirection = child.linearLinearLayoutSpec[mainDirectionForVarName] availableForPropMainDirection
        sumOfMainDirections += theMainDirection
        mainDirections.push theMainDirection
    l = ((usableMainDirectionSpace - sumOfMainDirections) * @float + Math.max(separationInMainDirection, 0)) +  mainDirectionStart

    usableMinorDirection = minorDirectionBoundsExtent - Math.max(2*separationInMinorDirection,0)
    
    for i in [@children.length-1 .. 0]
      m = @children[i]
      # major direction
      w = mainDirections[i]
      # minor direction
      ls = m.linearLinearLayoutSpec
      if not ls?
        # there might be submorphs that don't have a layout.
        # for example, currently, the HandleMorph can be attached
        # to the LinearLayoutMorph without a linearLinearLayoutSpec.
        # just skip those. The HandleMorph does its own
        # layouting.
        continue
      h = Math.min(usableMinorDirection, ls[minorDirectionForVarName](usableMinorDirection))
      t = (usableMinorDirection - h) * ls.minorDirectionFloat + separationInMinorDirection + minorDirectionStart

      # Set bounds and adjust major direction for next step
      # self flag: #jmvVer2.
      # should extent be set in m's coordinate system? what if its scale is not 1?
      if direction == "#horizontal"
        newExtent = new Point(Math.min(w,mainDirectionBoundsExtent),h)
      else if direction == "#vertical"
        newExtent = new Point(h,Math.min(w,mainDirectionBoundsExtent))

      if direction == "#horizontal"
        m.setPosition(new Point(l,t))
      else if direction == "#vertical"
        m.setPosition(new Point(t,l))
      #debugger
      m.setExtent(newExtent)

      if w>0
        l = Math.min(l + w + separationInMainDirection, mainDirectionEnd)


  # So the user can adjust layout
  addAdjusterMorph: ->
    thickness = 4
    adjuster = new LinearLayoutAdjustingMorph()

    if @direction == "#horizontal"
      @addMorphFixedWidth adjuster, thickness

    if @direction == "#vertical"
      @addMorphFixedHeight adjuster, thickness

    adjuster

  #"Add a submorph, at the bottom or right, with aLinearLayoutSpec"
  addMorphWithLinearLayoutSpec: (aMorph, aLinearLayoutSpec) ->
    aMorph.linearLinearLayoutSpec = aLinearLayoutSpec
    @add aMorph


  proportionalMainDirectionNormalizationFactor: ->
    sumOfProportional = 0
    @children.forEach (child) =>
      if child.linearLinearLayoutSpec?
        if @direction == "#horizontal"
          sumOfProportional += child.linearLinearLayoutSpec.getProportionalWidth()
        else if @direction == "#vertical"
          sumOfProportional += child.linearLinearLayoutSpec.getProportionalHeight()

    return 1.0/Math.max(sumOfProportional, 1.0)


  adjustByAt: (aLayoutAdjustMorph, aPoint) ->
    # | delta l ls r rs lNewWidth rNewWidth i lCurrentWidth rCurrentWidth doNotResizeBelow |

    i = @children.indexOf(aLayoutAdjustMorph)

    l = @children[i+1]
    r = @children[i - 1]

    ls = l.linearLinearLayoutSpec

    if @direction == "#horizontal"      
      doNotResizeBelow =  @minPaneWidthForReframe()
      lSize = l.width()
      rSize = r.width()
      delta = aPoint.x - aLayoutAdjustMorph.position().x
      checkProportionalSizeVarName = "isProportionalWidth"
      setProportionalSizeVarName = "setProportionalWidth"
      getProportionalSizeVarName = "getProportionalWidth"
      setFixedSizeVarName = "setFixedOrMorphWidth"
    else
      doNotResizeBelow =  @minPaneHeightForReframe()
      lSize = l.height()
      rSize = r.height()
      delta = aPoint.y - aLayoutAdjustMorph.position().y
      checkProportionalSizeVarName = "isProportionalHeight"
      setProportionalSizeVarName = "setProportionalHeight"
      getProportionalSizeVarName = "getProportionalHeight"
      setFixedSizeVarName = "setFixedOrMorphHeight"

    lCurrentWidth = Math.max(lSize,1) # avoid division by zero

    rs = r.linearLinearLayoutSpec
    rCurrentWidth = Math.max(rSize,1) # avoid division by zero

    delta = Math.max(delta, doNotResizeBelow - lCurrentWidth)
    delta = Math.min(delta, rCurrentWidth - doNotResizeBelow)
    if delta == 0 then return @
    lNewWidth = lCurrentWidth + delta
    rNewWidth = rCurrentWidth - delta
    if ls[checkProportionalSizeVarName]() and rs[checkProportionalSizeVarName]()
      # If both proportional, update them
      ls[setProportionalSizeVarName] 1.0 * lNewWidth / lCurrentWidth * ls[getProportionalSizeVarName]()
      rs[setProportionalSizeVarName] 1.0 * rNewWidth / rCurrentWidth * rs[getProportionalSizeVarName]()
    else
      # If at least one is fixed, update only the fixed
      if !ls[checkProportionalSizeVarName]()
          ls[setFixedSizeVarName] lNewWidth
      if !rs[checkProportionalSizeVarName]()
          rs[setFixedSizeVarName] rNewWidth
    @layoutSubmorphs()


  #####################
  # convenience methods
  #####################

  addAdjusterAndMorphFixedWidth: (aMorph,aNumber) ->
    @addAdjusterAndMorphLinearLayoutSpec(aMorph, LinearLayoutSpec.newWithFixedWidth aNumber)

  addAdjusterAndMorphFixedHeight: (aMorph,aNumber) ->
    @addAdjusterAndMorphLinearLayoutSpec(aMorph, LinearLayoutSpec.newWithFixedHeight aNumber)

  addAdjusterAndMorphLinearLayoutSpec: (aMorph, aLinearLayoutSpec) ->
    #Add a submorph, at the bottom or right, with aLinearLayoutSpec"
    adj = @addAdjusterMorph()
    @addMorphWithLinearLayoutSpec aMorph, aLinearLayoutSpec

  addAdjusterAndMorphProportionalHeight: (aMorph, aNumber) ->
    @addAdjusterAndMorphLinearLayoutSpec(aMorph, LinearLayoutSpec.newWithProportionalHeight(aNumber))

  addAdjusterAndMorphProportionalWidth: (aMorph, aNumber) ->
    @addAdjusterAndMorphLinearLayoutSpec(aMorph, LinearLayoutSpec.newWithProportionalWidth(aNumber))

  addMorphFixedHeight: (aMorph, aNumber) ->
    @addMorphWithLinearLayoutSpec(aMorph, LinearLayoutSpec.newWithFixedHeight(aNumber))

  addMorphFixedWidth: (aMorph, aNumber) ->
    @addMorphWithLinearLayoutSpec(aMorph, LinearLayoutSpec.newWithFixedWidth(aNumber))

  addMorphWithLinearLayoutSpec: (aMorph, aLinearLayoutSpec) ->
    # Add a submorph, at the bottom or right, with aLinearLayoutSpec
    aMorph.linearLinearLayoutSpec = aLinearLayoutSpec
    @add aMorph

  addMorphProportionalHeight: (aMorph, aNumber) ->
    @addMorphWithLinearLayoutSpec(aMorph, LinearLayoutSpec.newWithProportionalHeight(aNumber))

  addMorphProportionalWidth: (aMorph, aNumber) ->
    @addMorphWithLinearLayoutSpec(aMorph, LinearLayoutSpec.newWithProportionalWidth(aNumber))

  addMorphUseAll: (aMorph) ->
    @addMorphWithLinearLayoutSpec(aMorph, LinearLayoutSpec.useAll())

  addMorphs: (morphs) ->
    morphs.forEach (morph) =>
      @addMorphProportionalWidth(morph,1)

  addMorphsWidthProportionalTo: (morphs, widths) ->
    morphs.forEach (morph) =>
      @addMorphProportionalWidth(morph, widths)

  # unclear how to translate this one for the time being
  is: (aSymbol) ->
    return aSymbol == "#LinearLayoutMorph" # or [ super is: aSymbol ]


  @testSet1: ->
    @testScenario1("#horizontal")
    @testScenario2("#horizontal")
    @testScenario3("#horizontal")
    @testScenario4("#horizontal")
    @testScenario5("#horizontal")

  @testSet2: ->
    @testScenario1("#vertical")
    @testScenario2("#vertical")
    @testScenario3("#vertical")
    @testScenario4("#vertical")
    @testScenario5("#vertical")

  @testScenario1: (direction = "#horizontal")->
    rect1 = new RectangleMorph(new Point(20,20), new Color(255,0,0));
    rect2 = new RectangleMorph(new Point(20,20), new Color(0,255,0));
    
    if direction == "#horizontal"      
      line = LinearLayoutMorph.newRow()
      line.addMorphProportionalWidth(rect1,2)
      line.addMorphProportionalWidth(rect2,1)
    else
      line = LinearLayoutMorph.newColumn()
      line.addMorphProportionalHeight(rect1,2)
      line.addMorphProportionalHeight(rect2,1)

    line.layoutSubmorphs()
    line.setPosition new Point(10,10)
    line.keepWithin(world);
    world.add(line);
    line.changed();

    # attach a HandleMorph to it so that
    # we can check how it resizes
    new HandleMorph(line)


  @testScenario2: (direction = "#horizontal")->
    rect3 = new RectangleMorph(new Point(20,20), new Color(255,0,0));
    rect4 = new RectangleMorph(new Point(20,20), new Color(0,255,0));

    if direction == "#horizontal"      
      line = LinearLayoutMorph.newRow()
      line.addMorphFixedWidth(rect3,10)
      line.addMorphProportionalWidth(rect4,1)
    else
      line = LinearLayoutMorph.newColumn()
      line.addMorphFixedHeight(rect3,10)
      line.addMorphProportionalHeight(rect4,1)

    line.layoutSubmorphs()
    line.setPosition new Point(110,10)
    line.keepWithin(world);
    world.add(line);
    line.changed();

    # attach a HandleMorph to it so that
    # we can check how it resizes
    new HandleMorph(line)

  @testScenario3: (direction = "#horizontal")->
    rect5 = new RectangleMorph(new Point(20,20), new Color(255,0,0));
    rect6 = new RectangleMorph(new Point(20,20), new Color(0,255,0));
    rect7 = new RectangleMorph(new Point(20,20), new Color(0,0,255));

    if direction == "#horizontal"      
      line = LinearLayoutMorph.newRow()
      line.addMorphProportionalWidth(rect6,2) # green
      line.addAdjusterAndMorphProportionalWidth(rect7,1) # blue
      line.addMorphProportionalWidth(rect5,3) # red
      #line.addMorphFixedWidth(rect5,10) # red
    else
      line = LinearLayoutMorph.newColumn()
      line.addMorphProportionalHeight(rect6,2) # green
      line.addAdjusterAndMorphProportionalHeight(rect7,1) # blue
      line.addMorphProportionalHeight(rect5,3) # red
      #line.addMorphFixedHeight(rect5,10) # red

    #line.addMorphProportionalWidth(rect7,1)
    line.layoutSubmorphs()
    line.setPosition new Point(210,10)
    line.keepWithin(world)
    world.add(line)
    line.changed()

    # attach a HandleMorph to it so that
    # we can check how it resizes
    new HandleMorph(line)

  @testScenario4: (direction = "#horizontal")->
    # //////////////////////////////////////////////////
    # note how the vertical spacing in the horizontal layout
    # is different. the vertical size is not adjusted considering
    # all other morphs. A proportional of 1.1 is proportional to the
    # container, not to the other layouts.
    # Equivalent smalltalk code:
    # | pane rect1 rect2 |
    # pane _ LinearLayoutMorph newRow separation: 5. "3"
    # pane addMorph: (StringMorph contents: '3').
    # 
    # rect1 := BorderedRectMorph new color: (Color lightOrange).
    # pane addMorph: rect1 
    #          linearLinearLayoutSpec: (LinearLayoutSpec  fixedWidth: 20 proportionalHeight: 1.1 minorDirectionFloat: #center).
    # rect2 := BorderedRectMorph new color: (Color cyan);
    #   linearLinearLayoutSpec: (LinearLayoutSpec  fixedWidth: 20 proportionalHeight: 0.5 minorDirectionFloat: #center).
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

    if direction == "#horizontal"
      line = LinearLayoutMorph.newRow()
      line.addMorphProportionalWidth(rect6,0.5) # green
      line.addMorphFixedWidth(rect5,20) # red
      line.addMorphProportionalWidth(rect7,1.0) # blue
    else
      line = LinearLayoutMorph.newColumn()
      line.addMorphProportionalHeight(rect6,0.5) # green
      line.addMorphFixedHeight(rect5,20) # red
      line.addMorphProportionalHeight(rect7,1.0) # blue
 
    line.layoutSubmorphs()
    line.setPosition new Point(310,10)
    line.keepWithin(world);
    world.add(line);
    line.changed();

    # attach a HandleMorph to it so that
    # we can check how it resizes
    new HandleMorph(line)

  @testScenario5: (direction = "#horizontal")->
    # //////////////////////////////////////////////////
    # note how the vertical spacing in the horizontal layout
    # is different. the vertical size is not adjusted considering
    # all other morphs. A proportional of 1.1 is proportional to the
    # container, not to the other layouts.
    # Equivalent smalltalk code:
    # | pane rect1 rect2 |
    # pane _ LinearLayoutMorph newRow separation: 5. "3"
    # pane addMorph: (StringMorph contents: '3').
    # 
    # rect1 := BorderedRectMorph new color: (Color lightOrange).
    # pane addMorph: rect1 
    #          linearLinearLayoutSpec: (LinearLayoutSpec  fixedWidth: 20 proportionalHeight: 1.1 minorDirectionFloat: #center).
    # rect2 := BorderedRectMorph new color: (Color cyan);
    #   linearLinearLayoutSpec: (LinearLayoutSpec  fixedWidth: 20 proportionalHeight: 0.5 minorDirectionFloat: #center).
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

    if direction == "#horizontal"
      line = LinearLayoutMorph.newRow()
      line.addMorphProportionalWidth(rect6,0.5) # green
      line.addMorphProportionalWidth(rect7,1.0) # blue
      line.addAdjusterAndMorphFixedWidth(rect5,20) # red
    else
      line = LinearLayoutMorph.newColumn()
      line.addMorphProportionalHeight(rect6,0.5) # green
      line.addMorphProportionalHeight(rect7,1.0) # blue
      line.addAdjusterAndMorphFixedHeight(rect5,20) # red

    line.layoutSubmorphs()
    line.setPosition new Point(410,10)
    line.keepWithin(world);
    world.add(line);
    line.changed();

    # attach a HandleMorph to it so that
    # we can check how it resizes
    new HandleMorph(line)
