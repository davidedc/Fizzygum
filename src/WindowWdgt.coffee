# TODO: when floating, windows should really be able to
# accommodate any extent always, because really windows should
# be stackable and dockable in any place...
# ...and that's now how we do it now, for example a window
# with a clock right now keeps ratio...
# Only when being part of other layouts e.g. stacks the
# windows should keep a ratio etc...
# So I'm inclined to think that a window should do what the
# StretchableWidgetContainerWdgt does...

# TODO: this is such a special version of SimpleVerticalStackPanelWdgt
# that really it seems like this extension is misleading...

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

  internalExternalSwitchButton: nil
  alwaysShowInternalExternalButton: nil

  # TODO passing the @labelContent doesn't quite work, when
  # you add a widget to the window it overwrites the
  # title which means that this one parameter passed in
  # the constructor has no effect
  constructor: (@labelContent = "my window", @closeButton, @contents, @internal = false, @alwaysShowInternalExternalButton = false) ->
    super nil, nil, 40, true

    if @internal
      @appearance = new RectangularAppearance @
    else
      @appearance = new BoxyAppearance @

    @strokeColor = Color.create 125,125,125
    @tight = true

    @defaultContents = new WindowContentsPlaceholderText
    if !@contents?
      @contents = @defaultContents

    @padding = 5
    # TODO this looks better:
    #@padding = 10
    @color = Color.create 248, 248, 248
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


  makeInternal: ->
    if !@internal
      @internal = true
      @setAppearanceAndColorOfTitleBackground()

  makeExternal: ->
    if @internal
      @internal = false
      # in case the internal window was part of an uneditable
      # document, then it was set to lock to the panel so it
      # couldn't be dragged. But we have to change that now since
      # we ought to be free on the desktop
      @unlockFromPanels()
      @setAppearanceAndColorOfTitleBackground()

      previousParent = @parent
      world.add @

      @contents?.holderWindowMadeIntoExternal?()

      # make it jump out a little, but still, fit it
      # in the world
      if previousParent != world
        @fullRawMoveTo @position().add new Point 10, 10
        @fullRawMoveWithin world
        @rememberFractionalSituationInHoldingPanel()

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

  add: (aWdgt, position = nil, layoutSpec, beingDropped, notContent) ->
    unless notContent or (aWdgt instanceof CaretMorph) or (aWdgt instanceof HandleMorph)
      @contentNeverSetInPlaceYet = true
      titleToBeSet = aWdgt.colloquialName()
      if titleToBeSet == "window"
        titleToBeSet = "window with another " + titleToBeSet
      if titleToBeSet == "internal window"
        titleToBeSet = "window with an " + titleToBeSet
      @label.setText titleToBeSet
      @removeChild @contents
      @contents = aWdgt
      @adjustContentsBounds()
      super aWdgt, position, LayoutSpec.ATTACHEDAS_WINDOW_CONTENT, beingDropped
    else
      super aWdgt, position, layoutSpec, beingDropped
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

      @editButton?.destroy()
      @editButton = nil

      @internalExternalSwitchButton?.destroy()
      @internalExternalSwitchButton = nil

  childBeingUnCollapsed: (child) ->
    if child == @contents
      @widthWhenCollapsed = @width()

    @createAndAddEditButton()
    @createAndAddInternalExternalSwitchButton()

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
      @rememberFractionalSituationInHoldingPanel()
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

  justDropped: (whereIn) ->
    super
    @contents?.holderWindowJustDropped? whereIn

  justBeenGrabbed: (whereFrom) ->
    @contents?.holderWindowJustBeenGrabbed? whereFrom

  reactToDropOf: (theWidget) ->
    @contents = theWidget
    super
    @disableDrops()
    @buildAndConnectChildren()

  setAppearanceAndColorOfTitleBackground: ->
    if @internal
      @titlebarBackground.appearance = new RectangularAppearance @titlebarBackground
    else
      @titlebarBackground.appearance = new BoxyAppearance @titlebarBackground

    if @internal
      @titlebarBackground.setColor WorldMorph.preferencesAndSettings.internalWindowBarBackgroundColor
      @titlebarBackground.strokeColor = WorldMorph.preferencesAndSettings.internalWindowBarStrokeColor
    else
      @titlebarBackground.setColor WorldMorph.preferencesAndSettings.externalWindowBarBackgroundColor
      @titlebarBackground.strokeColor = WorldMorph.preferencesAndSettings.externalWindowBarStrokeColor


  buildTitlebarBackground: ->
    if @titlebarBackground?
      @titlebarBackground.fullDestroy()

    # TODO we should really just instantiate a Widget,
    # and give it the shape, there is no reason to create
    # the dedicated shape morph and then change the appearance
    # as the window changes from internal to external and vice versa
    # HOWEVER a bunch of tests would fail if I do the proper
    # thing so we are doing this for the time being.
    if @internal
      @titlebarBackground = new RectangleMorph
    else
      @titlebarBackground = new BoxMorph

    @setAppearanceAndColorOfTitleBackground()
    @add @titlebarBackground, nil, nil, nil, true
  
  buildAndConnectChildren: ->

    if !@titlebarBackground?
      @buildTitlebarBackground()

    # label
    @label?.fullDestroy()
    @label = new StringMorph2 @labelContent, WorldMorph.preferencesAndSettings.titleBarTextFontSize

    # as of March 2018, Safari 10.1.1 on OSX 10.12.5 :
    # safari's rendering of bright text on dark background is atrocious
    # so we have to force bold style in the window bars
    if /^((?!chrome|android).)*safari/i.test navigator.userAgent
      @label.isBold = true
    else
      @label.isBold = WorldMorph.preferencesAndSettings.titleBarBoldText

    @label.color = Color.WHITE
    @add @label, nil, nil, nil, true

    # upper-left button, often a close button
    # but it can be anything
    if !@closeButton?
      @closeButton = new CloseIconButtonMorph
    @add @closeButton, nil, nil, nil, true


    if !@collapseUncollapseSwitchButton?
      collapseButton = new CollapseIconButtonMorph
      uncollapseButton = new UncollapseIconButtonMorph
      @collapseUncollapseSwitchButton = new SwitchButtonMorph [collapseButton, uncollapseButton]
    @add @collapseUncollapseSwitchButton, nil, nil, nil, true


    @createAndAddInternalExternalSwitchButton()
    @createAndAddEditButton()

    @add @contents

    if !@resizer?
      @resizer = new HandleMorph @

  createAndAddInternalExternalSwitchButton: ->
    if (@contents?.providesAmenitiesForEditing or @alwaysShowInternalExternalButton) and !@internalExternalSwitchButton?
      externalButton = new ExternalIconButtonWdgt
      internalButton = new InternalIconButtonWdgt
      if @internal
        listOfButtons = [internalButton, externalButton]
      else
        listOfButtons = [externalButton, internalButton]
      @internalExternalSwitchButton = new SwitchButtonMorph listOfButtons
      @add @internalExternalSwitchButton, nil, nil, nil, true

  makePencilYellow: ->
      # TODO assigning to color_normal is not enough
      # there should be a way to do these two lines with one line
      @editButton?.color_normal = Color.create 248, 188, 58
      @editButton?.setColor Color.create 248, 188, 58
      @editButton?.changed()

  makePencilClear: ->
      # TODO assigning to color_normal is not enough
      # there should be a way to do these two lines with one line
      @editButton?.color_normal = Color.create 245, 244, 245
      @editButton?.setColor Color.create 245, 244, 245
      @editButton?.changed()

  createAndAddEditButton: ->
    if @contents?.providesAmenitiesForEditing and !@editButton?
      @editButton = new EditIconButtonWdgt @
      @add @editButton, nil, nil, nil, true

      if @contents.dragsDropsAndEditingEnabled
        @makePencilYellow()
      else
        @makePencilClear()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  adjustContentsBounds: ->
    # avoid recursively re-entering this function
    if @_adjustingContentsBounds then return else @_adjustingContentsBounds = true

    closeIconSize = 16

    # close button
    if @closeButton? and @closeButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @padding, @top() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @closeButton.doLayout buttonBounds

    # collapse/uncollapse button
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
    # TODO this looks better:
    #@titlebarBackground.rawSetExtent (new Point @width(), closeIconSize + 2 * @padding).subtract new Point 4,4
    #@titlebarBackground.fullRawMoveTo @position().add new Point 2,2

    if @width() < 4 * (closeIconSize + @padding) + @padding
      @editButton?.collapse()
    else
      @editButton?.unCollapse()

    if @width() < 3 * (closeIconSize + @padding) + @padding
      @internalExternalSwitchButton?.collapse()
    else
      @internalExternalSwitchButton?.unCollapse()

    # label
    if @label? and @label.parent == @
      labelLeft = @left() + @padding + 2 * (closeIconSize + @padding)
      labelTop = @top() + @padding
      labelRight = @right() - @padding
      if @editButton? and !@editButton.isCollapsed()
        labelRight -= 1 * (closeIconSize + @padding)
      if @internalExternalSwitchButton? and !@internalExternalSwitchButton.isCollapsed()
        labelRight -= 1 * (closeIconSize + @padding)
      labelWidth = labelRight - labelLeft

      labelBounds = new Rectangle new Point labelLeft, labelTop
      labelBounds = labelBounds.setBoundsWidthAndHeight labelWidth, WorldMorph.preferencesAndSettings.titleBarTextHeight
      @label.rawSetBounds labelBounds

    # edit button
    if @editButton? and !@editButton.isCollapsed() and @editButton.parent == @
      buttonBounds = new Rectangle new Point @right() - 2 * (closeIconSize + @padding), @top() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @editButton.doLayout buttonBounds

    # internal/external button
    if @internalExternalSwitchButton? and !@internalExternalSwitchButton.isCollapsed() and @internalExternalSwitchButton.parent == @
      buttonBounds = new Rectangle new Point @right() - 1 * (closeIconSize + @padding), @top() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @internalExternalSwitchButton.doLayout buttonBounds



    @resizer?.silentUpdateResizerHandlePosition()

    @_adjustingContentsBounds = false
