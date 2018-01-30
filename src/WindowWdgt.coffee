# WindowWdgt //////////////////////////////////////////////////////
# REQUIRES WindowContentsPlaceholderText

class WindowWdgt extends SimpleVerticalStackPanelWdgt

  label: nil
  closeButton: nil
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

  constructor: (@labelContent = "my window", @closeButton, @contents, @internal = false) ->
    super nil, nil, 40, true

    if @internal
      @appearance = new RectangularAppearance @
    else
      @appearance = new BoxyAppearance @

    @strokeColor = new Color 125,125,125
    @tight = true

    @defaultContents = new WindowContentsPlaceholderText()
    @contents = @defaultContents

    @padding = 5
    @color = new Color 172, 172, 172
    @buildAndConnectChildren()

    @setEmptyWindowLabel()
    @rawSetExtent new Point 300, 300

    #@adjustContentsBounds()

  contentsRecursivelyCanSetHeightFreely: ->
    if !(@contents instanceof WindowWdgt)
      return @contents.layoutSpecDetails.canSetHeightFreely
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

  add: (aMorph, position = nil, layoutSpec, notContent) ->
    debugger
    unless notContent or (aMorph instanceof CaretMorph) or (aMorph instanceof HandleMorph)
      @contentNeverSetInPlaceYet = true
      @label.setText aMorph.colloquialName()
      @removeChild @contents
      @contents = aMorph
      @adjustContentsBounds()
      super aMorph, position, LayoutSpec.ATTACHEDAS_WINDOW_CONTENT
    else
      super aMorph, position, LayoutSpec.ATTACHEDAS_FREEFLOATING
    @resizer?.moveInFrontOfSiblings()

  childBeingDestroyed: (child) ->
    debugger
    if child == @contents
      @resetToDefaultContents()

  childBeingPickedUp: (child) ->
    if child == @contents
      @resetToDefaultContents()

  childBeingClosed: (child) ->
    if child == @contents
      @resetToDefaultContents()

  resetToDefaultContents: ->
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
      @add @titlebarBackground, nil, nil, true

    # label
    @label?.destroy()
    @label = new StringMorph2 @labelContent
    @label.fontSize = WorldMorph.preferencesAndSettings.menuFontSize
    @label.isBold = true
    @label.color = new Color 255, 255, 255
    @add @label, nil, nil, true

    # upper-left button, often a close button
    # but it can be anything
    if !@closeButton?
      @closeButton = new CloseIconButtonMorph @

    if !@collapseUncollapseSwitchButton?
      collapseButton = new CollapseIconButtonMorph()
      uncollapseButton = new UncollapseIconButtonMorph()
      @collapseUncollapseSwitchButton = new SwitchButtonMorph [collapseButton, uncollapseButton]


    @add @closeButton, nil, nil, true
    @add @collapseUncollapseSwitchButton, nil, nil, true

    @add @contents

    if !@resizer?
      @resizer = new HandleMorph @

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  adjustContentsBounds: ->
    debugger
    # avoid recursively re-entering this function
    if @_adjustingContentsBounds then return else @_adjustingContentsBounds = true

    totalPadding = 2 * @padding
    closeIconSize = 16

    # label
    labelLeft = @left() + @padding + 2 * (closeIconSize + @padding)
    labelTop = @top() + @padding
    labelRight = @right() - @padding
    labelWidth = labelRight - labelLeft

    if @label? and @label.parent == @
      labelBounds = new Rectangle new Point labelLeft, labelTop
      labelBounds = labelBounds.setBoundsWidthAndHeight labelWidth, 15
      @label.doLayout labelBounds
    labelBottom = labelTop + @label.height() + 2


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

    if @contents?
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

    newHeight = stackHeight + partOfHeightUsedUp

    @rawSetHeight newHeight

    @titlebarBackground.rawSetExtent (new Point @width(), closeIconSize + 2 * @padding).subtract new Point 2,2
    @titlebarBackground.fullRawMoveTo @position().add new Point 1,1
    @resizer?.silentUpdateResizerHandlePosition()

    @_adjustingContentsBounds = false
