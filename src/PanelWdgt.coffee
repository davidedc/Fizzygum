#| PanelWdgt //////////////////////////////////////////////////////////
#| 
#| I clip my submorphs at my bounds. Which potentially saves a lot of redrawing
#| 
#| and event handling. 
#| 
#| It's a good idea to use me whenever it's clear that there is a  
#| 
#| "container"/"contained" scenario going on.

# REQUIRES RectangularAppearance
# REQUIRES ClippingAtRectangularBoundsMixin
# TODO unclear whether this actually requires RectangularAppearance

class PanelWdgt extends Morph

  @augmentWith ClippingAtRectangularBoundsMixin, @name

  scrollPanel: nil
  extraPadding: 0
  _acceptsDrops: true

  # if this Panel belongs to a ScrollPanel, then
  # the @scrollPanel points to it
  constructor: (@scrollPanel = nil) ->
    super()
    @appearance = new RectangularAppearance @

    @color = new Color 255, 250, 245
    @strokeColor = new Color 100, 100, 100

    if @scrollPanel
      @noticesTransparentClick = false

  setColor: (aColorOrAMorphGivingAColor, morphGivingColor) ->
    aColor = super(aColorOrAMorphGivingAColor, morphGivingColor)
    # keep in synch the value of the container scrollPanel
    # if there is one. Note that the container scrollPanel
    # is actually not painted.
    if @scrollPanel
      unless @scrollPanel.color.eq aColor
        @scrollPanel.color = aColor
    return aColor


  setAlphaScaled: (alphaOrMorphGivingAlpha, morphGivingAlpha) ->
    alpha = super(alphaOrMorphGivingAlpha, morphGivingAlpha)
    if @scrollPanel
      unless @scrollPanel.alpha == alpha
        @scrollPanel.alpha = alpha
    return alpha


  mouseClickLeft: (pos, ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey) ->
    @bringToForegroud()

    # when you click on an "empty" part of a Panel that contains
    # a piece of text, we pass the click on to the text to it
    # puts the caret at the end of the text.
    # TODO the focusing and placing of the caret at the end of
    # the text should happen via API rather than via spoofing
    # a mouse event?
    if @parent? and @parent instanceof ScrollPanelWdgt
      childrenNotCarets = @children.filter (m) ->
        !(m instanceof CaretMorph)
      if childrenNotCarets.length == 1
        item = @firstChildSuchThat (m) ->
          (m instanceof TextMorph) or
          (m instanceof SimplePlainTextWdgt)
        item?.mouseClickLeft item.bottomRight(), ignored_button, ignored_buttons, ignored_ctrlKey, shiftKey, ignored_altKey, ignored_metaKey


  reactToDropOf: ->
    if @parent?
      if @parent.adjustContentsBounds?
        @parent.adjustContentsBounds()
        @parent.adjustScrollBars()

  detachesWhenDragged: ->
    if @parent?

      # otherwise you could detach a Frame contained in a
      # ScrollPanelWdgt which is very strange
      if @parent instanceof ScrollPanelWdgt
        return false

      return super

  grabsToParentWhenDragged: ->
    if @parent?

      # otherwise you could detach a Frame contained in a
      # ScrollPanelWdgt which is very strange
      if @parent instanceof ScrollPanelWdgt
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

  # PanelWdgt menus:
  addMorphSpecificMenuEntries: (morphOpeningTheMenu, menu) ->
    super
    if @children.length
      menu.addLine()
      menu.addMenuItem "move all inside", true, @, "keepAllSubmorphsWithin", "keep all submorphs\nwithin and visible"
  
  keepAllSubmorphsWithin: ->
    @children.forEach (m) =>
      m.fullRawMoveWithin @
