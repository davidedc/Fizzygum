# REQUIRES WindowContentsPlaceholderText

class WindowWdgt extends SimpleVerticalStackPanelWdgt

  # TODO we already have the concept of "droplet" widget
  # so probably we should re-use that. The current drop
  # area management seems a little byzantine...

  label: nil
  closeButton: nil
  editButton: nil
  collapseUncollapseSwitchButton: nil
  labelContent: nil
  resizer: nil
  padding: nil
  contents: nil
  titlebarBackground: nil
  contentNeverSetInPlaceYet: true
  # used to avoid recursively re-entering the
  # adjustContentsBounds function
  _adjustingContentsBounds: false
  internal: false
  defaultContents: nil
  reInflating: false

  # TODO passing the @labelContent doesn't quite work, when
  # you add a widget to the window it overwrites the
  # title which means that this one parameter passed in
  # the constructor has no effect
  constructor: (@labelContent = "my window", @closeButton, @contents, @internal = false) ->
    super nil, nil, 40, true

    if @internal
      @appearance = new RectangularAppearance @
    else
      @appearance = new BoxyAppearance @

    @strokeColor = new Color 125,125,125
    @tight = true

    @defaultContents = new WindowContentsPlaceholderText()
    if !@contents?
      @contents = @defaultContents

    @padding = 5
    @color = new Color 248, 248, 248
    @buildAndConnectChildren()

    if @contents == @defaultContents
      @setEmptyWindowLabel()
    else
      @disableDrops()
      # TODO there is a duplicate of this down below
      titleToBeSet = @contents.colloquialName()
      if titleToBeSet == "window"
        titleToBeSet = "window with another " + titleToBeSet
      if titleToBeSet == "internal window"
        titleToBeSet = "window with an " + titleToBeSet
      @label.setText titleToBeSet

    @rawSetExtent new Point 300, 300

  # in general, windows just create a reference of themselves and
  # that is it. However, windows containing a ScriptWdgt create
  # a special type of reference that has a slightly different icon
  # and when double-clicked actually runs the script rather than
  # bringing up the script 
  createReference: (referenceName, placeToDropItIn) ->
    # this function can also be called as a callback
    # of a trigger, in which case the first parameter
    # here is a menuItem. We take that parameter away
    # in that case.
    if referenceName? and typeof(referenceName) != "string"
      referenceName = nil
      placeToDropItIn = world

    if @contents? and (@contents instanceof ScriptWdgt)
      morphToAdd = new IconicDesktopSystemScriptShortcutWdgt @, referenceName
      # this "add" is going to try to position the reference
      # in some smart way (i.e. according to a grid)
      placeToDropItIn.add morphToAdd
      morphToAdd.setExtent new Point 75, 75
      morphToAdd.fullChanged()
      @bringToForeground()
    else
      super


  setTitle: (newTitle) ->
    @label.setText @contents.colloquialName() + ": " + newTitle

  setTitleWithoutPrependedContentName: (newTitle) ->
    @label.setText newTitle

  representativeIcon: ->
    if @contents == @defaultContents
      return super
    else
      return @contents.representativeIcon()

  closeFromWindowBar: ->
    @contents?.closeFromContainerWindow @

  contentsRecursivelyCanSetHeightFreely: ->
    if !(@contents instanceof WindowWdgt)
      return (@contents.layoutSpecDetails.canSetHeightFreely and !@contents.isCollapsed()) and !@reInflating
    return @contents.contentsRecursivelyCanSetHeightFreely()

  recursivelyAttachedAsFreeFloating: ->
    if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING
      return true

    if @parent?
      if @parent instanceof WindowWdgt
        return @parent.recursivelyAttachedAsFreeFloating()

    return false


  rejectsBeingDropped: ->
    return !@internal

  setEmptyWindowLabel: ->
    if @internal
      @label.setText "empty internal window"
    else
      @label.setText "empty window"

  colloquialName: ->
    if @internal
      return "internal window"
    else
      return "window"

  add: (aMorph, position = nil, layoutSpec, beingDropped, notContent) ->
    unless notContent or (aMorph instanceof CaretMorph) or (aMorph instanceof HandleMorph)
      @contentNeverSetInPlaceYet = true
      titleToBeSet = aMorph.colloquialName()
      if titleToBeSet == "window"
        titleToBeSet = "window with another " + titleToBeSet
      if titleToBeSet == "internal window"
        titleToBeSet = "window with an " + titleToBeSet
      @label.setText titleToBeSet
      @removeChild @contents
      @contents = aMorph
      @adjustContentsBounds()
      super aMorph, position, LayoutSpec.ATTACHEDAS_WINDOW_CONTENT, beingDropped
    else
      super aMorph, position, LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped
    @resizer?.moveInFrontOfSiblings()

  childBeingDestroyed: (child) ->
    if child == @contents
      @resetToDefaultContents()

  childBeingPickedUp: (child) ->
    if child == @contents
      @resetToDefaultContents()

  childBeingClosed: (child) ->
    if child == @contents
      @resetToDefaultContents()

  childBeingCollapsed: (child) ->
    if child == @contents
      @widthWhenUnCollapsed = @width()
      @contentsExtentWhenCollapsed = @contents.extent()
      @extentWhenCollapsed = @extent()

  childBeingUnCollapsed: (child) ->
    if child == @contents
      @widthWhenCollapsed = @width()

  childCollapsed: (child) ->
    if child == @contents
      if @widthWhenCollapsed?
        @rawSetWidth @widthWhenCollapsed
      @adjustContentsBounds()
      @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  childUnCollapsed: (child) ->
    if child == @contents
      @reInflating = true
      @rawSetExtent @extentWhenCollapsed
      @contents.rawSetExtent @contentsExtentWhenCollapsed
      if @widthWhenUnCollapsed?
        @rawSetWidth @widthWhenUnCollapsed
      @adjustContentsBounds()
      @reInflating = false
      @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  resetToDefaultContents: ->
    @enableDrops()
    @contents = @defaultContents
    @buildAndConnectChildren()
    @setEmptyWindowLabel()
    if @recursivelyAttachedAsFreeFloating()
      @rawSetExtent new Point 300, 300

  aboutToDrop: ->
    @removeChild @contents

  reactToDropOf: (theWidget) ->
    @contents = theWidget
    super
    @disableDrops()
    @buildAndConnectChildren()
  
  buildAndConnectChildren: ->

    if !@titlebarBackground?
      if @internal
        @titlebarBackground = new RectangleMorph()
      else
        @titlebarBackground = new BoxMorph()
      if @internal
        @titlebarBackground.setColor new Color 172,172,172
        @titlebarBackground.strokeColor = new Color 150,150,150
      else
        @titlebarBackground.setColor new Color 125,125,125
        @titlebarBackground.strokeColor = new Color 100,100,100
      @add @titlebarBackground, nil, nil, nil, true

    # label
    @label?.fullDestroy()
    @label = new StringMorph2 @labelContent
    @label.fontSize = WorldMorph.preferencesAndSettings.menuFontSize
    @label.isBold = true
    @label.color = new Color 255, 255, 255
    @add @label, nil, nil, nil, true

    # upper-left button, often a close button
    # but it can be anything
    if !@closeButton?
      @closeButton = new CloseIconButtonMorph @

    if @contents?.providesAmenitiesForEditing and !@editButton?
      @editButton = new EditIconButtonWdgt @

    if !@collapseUncollapseSwitchButton?
      collapseButton = new CollapseIconButtonMorph()
      uncollapseButton = new UncollapseIconButtonMorph()
      @collapseUncollapseSwitchButton = new SwitchButtonMorph [collapseButton, uncollapseButton]


    @add @closeButton, nil, nil, nil, true
    @add @collapseUncollapseSwitchButton, nil, nil, nil, true

    if @editButton?
      @add @editButton, nil, nil, nil, true

    @add @contents

    if !@resizer?
      @resizer = new HandleMorph @

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  adjustContentsBounds: ->
    # avoid recursively re-entering this function
    if @_adjustingContentsBounds then return else @_adjustingContentsBounds = true

    totalPadding = 2 * @padding
    closeIconSize = 16




    # close button
    if @closeButton? and @closeButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @padding, @top() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @closeButton.doLayout buttonBounds

    if @collapseUncollapseSwitchButton? and @collapseUncollapseSwitchButton.parent == @
      buttonBounds = new Rectangle new Point @left() + closeIconSize + 2 * @padding, @top() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @collapseUncollapseSwitchButton.doLayout buttonBounds



    stackHeight = 0

    if @contents? and !@contents.collapsed
      if @contents.layoutSpec != LayoutSpec.ATTACHEDAS_WINDOW_CONTENT
        @contents.initialiseDefaultWindowContentLayoutSpec()
        @contents.setLayoutSpec LayoutSpec.ATTACHEDAS_WINDOW_CONTENT

      if @contentNeverSetInPlaceYet
        # in this case the contents has just been added

        if @contents.layoutSpecDetails.preferredStartingWidth == PreferredSize.THIS_ONE_I_HAVE_NOW
          recommendedElementWidth = @contents.width()
          if @recursivelyAttachedAsFreeFloating()
            windowWidth = recommendedElementWidth + @padding * 2
          else
            windowWidth = Math.min @width(), recommendedElementWidth + @padding * 2
          @rawSetWidth windowWidth
        else if @contents.layoutSpecDetails.preferredStartingWidth == PreferredSize.DONT_MIND
          recommendedElementWidth = @width()  - 2 * @padding
        else
          recommendedElementWidth = @contents.layoutSpecDetails.preferredStartingWidth
          if @recursivelyAttachedAsFreeFloating()
            windowWidth = recommendedElementWidth + @padding * 2
          else
            windowWidth = Math.min @width(), recommendedElementWidth + @padding * 2
          @rawSetWidth windowWidth

        @contents.layoutSpecDetails.rememberInitialDimensions @contents, @


      else
        # the content was already there
        recommendedElementWidth = @contents.layoutSpecDetails.getWidthInStack()

      if @contents.layoutSpecDetails.resizerCanOverlapContents
        partOfHeightUsedUp = Math.round (closeIconSize + @padding + @padding) + 2 * @padding
      else
        partOfHeightUsedUp = Math.round (closeIconSize + @padding + @padding) + 3 * @padding + WorldMorph.preferencesAndSettings.handleSize

      # this re-layouts each widget to fit the width.
      if @contentNeverSetInPlaceYet
        # in this case the contents has just been added
        if @contents.layoutSpecDetails.preferredStartingHeight == PreferredSize.THIS_ONE_I_HAVE_NOW
          desiredHeight = @contents.height()
          if !@recursivelyAttachedAsFreeFloating()
            desiredHeight = Math.min desiredHeight, @height() - partOfHeightUsedUp
          @contents.rawSetWidth recommendedElementWidth
          @rawSetWidth windowWidth
          @contents.rawSetHeight desiredHeight
        else if @contents.layoutSpecDetails.preferredStartingHeight == PreferredSize.DONT_MIND
          @contents.rawSetWidth recommendedElementWidth
          desiredHeight = Math.round @height() - partOfHeightUsedUp
          @contents.rawSetHeight desiredHeight
        else
          @contents.rawSetWidthSizeHeightAccordingly recommendedElementWidth
          desiredHeight = @contents.height()

        @contentNeverSetInPlaceYet = false
      else
        # the content was already there
        @contents.rawSetWidthSizeHeightAccordingly recommendedElementWidth
        desiredHeight = @contents.height()

        if @contentsRecursivelyCanSetHeightFreely()
          desiredHeight = Math.round @height() - partOfHeightUsedUp
          @contents.rawSetHeight desiredHeight

      # the SimplePlainTextWdgt just needs this to be different from null
      # while the TextMorph actually uses this number
      if (@contents instanceof TextMorph) or (@contents instanceof SimplePlainTextWdgt)
        @contents.maxTextWidth = recommendedElementWidth

      leftPosition = @left() + Math.floor (@width() - recommendedElementWidth) / 2

      @contents.fullRawMoveTo new Point leftPosition, @top() + (closeIconSize + @padding + @padding) + @padding
      stackHeight += desiredHeight

    if @contents? and @contents.collapsed
      partOfHeightUsedUp = Math.round closeIconSize + @padding + @padding


    newHeight = stackHeight + partOfHeightUsedUp

    @rawSetHeight newHeight

    @titlebarBackground.rawSetExtent (new Point @width(), closeIconSize + 2 * @padding).subtract new Point 2,2
    @titlebarBackground.fullRawMoveTo @position().add new Point 1,1

    # label
    if @label? and @label.parent == @
      labelLeft = @left() + @padding + 2 * (closeIconSize + @padding)
      labelTop = @top() + @padding
      labelRight = @right() - @padding
      if @editButton?
        labelRight -= 1 * (closeIconSize + @padding)
      labelWidth = labelRight - labelLeft

      labelBounds = new Rectangle new Point labelLeft, labelTop
      labelBounds = labelBounds.setBoundsWidthAndHeight labelWidth, 15
      @label.rawSetBounds labelBounds

    # edit button
    if @editButton? and @editButton.parent == @
      buttonBounds = new Rectangle new Point labelRight + @padding, @top() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @editButton.doLayout buttonBounds


    @resizer?.silentUpdateResizerHandlePosition()

    @_adjustingContentsBounds = false
