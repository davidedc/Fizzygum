#| FrameMorph //////////////////////////////////////////////////////////
#| 
#| I clip my submorphs at my bounds. Which potentially saves a lot of redrawing
#| 
#| and event handling. 
#| 
#| It's a good idea to use me whenever it's clear that there is a  
#| 
#| "container"/"contained" scenario going on.

# REQUIRES RectangularAppearance
# REQUIRES ClippingMixin
# TODO unclear whether this actually requires RectangularAppearance

class FrameMorph extends Morph

  @augmentWith ClippingMixin, @name

  scrollFrame: nil
  extraPadding: 0
  _acceptsDrops: true

  # if this frame belongs to a scrollFrame, then
  # the @scrollFrame points to it
  constructor: (@scrollFrame = nil) ->
    super()
    @appearance = new RectangularAppearance @

    @color = new Color 255, 250, 245
    @strokeColor = new Color 100, 100, 100

    if @scrollFrame
      @noticesTransparentClick = false

  setColor: (aColorOrAMorphGivingAColor, morphGivingColor) ->
    aColor = super(aColorOrAMorphGivingAColor, morphGivingColor)
    # keep in synch the value of the container scrollFrame
    # if there is one. Note that the container scrollFrame
    # is actually not painted.
    if @scrollFrame
      unless @scrollFrame.color.eq aColor
        @scrollFrame.color = aColor
    return aColor


  setAlphaScaled: (alphaOrMorphGivingAlpha, morphGivingAlpha) ->
    alpha = super(alphaOrMorphGivingAlpha, morphGivingAlpha)
    if @scrollFrame
      unless @scrollFrame.alpha == alpha
        @scrollFrame.alpha = alpha
    return alpha


  mouseClickLeft: (pos, ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey) ->
    @bringToForegroud()

    # when you click on an "empty" part of a frame that contains
    # a piece of text, we pass the click on to the text to it
    # puts the caret at the end of the text.
    # TODO the focusing and placing of the caret at the end of
    # the text should happen via API rather than via spoofing
    # a mouse event?
    if @parent? and @parent instanceof ScrollFrameMorph
      childrenNotCarets = @children.filter (m) ->
        !(m instanceof CaretMorph)
      if childrenNotCarets.length == 1
        item = @firstChildSuchThat (m) ->
          (m instanceof TextMorph) or
          (m instanceof TextMorph2BridgeForWrappingText)
        item?.mouseClickLeft item.bottomRight(), ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey


  reactToDropOf: ->
    if @parent?
      if @parent.adjustContentsBounds?
        @parent.adjustContentsBounds()
        @parent.adjustScrollBars()

  detachesWhenDragged: ->
    if @parent?

      # otherwise you could detach a Frame contained in a
      # ScrollFrameMorph which is very strange
      if @parent instanceof ScrollFrameMorph
        return false

      return super

  grabsToParentWhenDragged: ->
    if @parent?

      # otherwise you could detach a Frame contained in a
      # ScrollFrameMorph which is very strange
      if @parent instanceof ScrollFrameMorph
        if @parent.canScrollByDraggingBackground and @parent.anyScrollBarShowing()
          return false
        else
          return true

      return super

    # doesn't have a parent
    return false
  
  reactToGrabOf: ->
    if @parent?
      if @parent.adjustContentsBounds?
        @parent.adjustContentsBounds()
        @parent.adjustScrollBars()

  # FrameMorph menus:
  addMorphSpecificMenuEntries: (morphOpeningTheMenu, menu) ->
    super
    if @children.length
      menu.addLine()
      menu.addMenuItem "move all inside", true, @, "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
  
  keepAllSubmorphsWithin: ->
    @children.forEach (m) =>
      m.fullRawMoveWithin @
