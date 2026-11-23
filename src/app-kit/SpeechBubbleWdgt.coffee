# the speech bubble is similar to the Tooltip,
# however it's more like the callouts of some
# famous presentation software: you drop them
# somewhere and you type text in them. If you resize
# them, the text inside them is resized too.
# They don't pop up within a certain time.

class SpeechBubbleWdgt extends Widget

  contents: undefined
  padding: undefined # additional vertical pixels
  widgetInvokingThis: undefined
  # per class, not pulled up: this extends Widget, not BoxWdgt
  cornerRadius: undefined
  # the TextWdgt child holding @contents
  contentsWidget: undefined

  # what I am as a tool in a panel, in a word: the lid over me in a tool cell shows it as its tooltip
  # (ToolPanelWdgt), and a toolbar's overflow row names me by it (OverflowChevronButtonWdgt). I show
  # no tooltip of my own.
  toolName: "speech bubble"

  # the size I have as a tool: a toolbar builds me at it before my cell takes me in (ToolbarWdgt), so a
  # copy of me leaves the cell at it. Outside a toolbar's own roster it is read by nothing: built anywhere
  # else I am born at Widget's size, and put into a toolbar by a person I keep the size I arrive at.
  toolExtent: new Point 130, 100

  # no fill or stroke colour of my own until one is set on me (my color is declared undefined here,
  # over Widget's content default; my strokeColor is Widget's, undefined): until then my
  # BubblyAppearance paints me in the speech bubble's roles, read as I am painted (_surfaceFill,
  # _surfaceStroke), so a bubble saved, loaded or duplicated wears the world's look
  color: undefined

  constructor: (@contents="hello") ->
    super()
    @padding = 0
    @cornerRadius = WorldWdgt.theme.speechBubbleCornerRadius
    @appearance = new BubblyAppearance @
    @_buildAndConnectChildren()
    @minimumExtent = new Point 10,10

  # the fill and the 1 px border my BubblyAppearance paints me in while I hold no colour of my own
  _surfaceFill: ->
    WorldWdgt.theme.speechBubbleFill

  _surfaceStroke: ->
    WorldWdgt.theme.speechBubbleStroke

  # MY PICTURE IN A MENU ROW (a toolbar overflow row's, OverflowChevronButtonWdgt._miniatureOf) shows the bubble
  # without its words: in a menu row's glyph box no size of them is legible on either backend, and a bubble with no
  # words still reads as a speech bubble. Asked of the throwaway copy the row photographs, never of a bubble in use.
  # The text is HIDDEN, neither destroyed (my _reLayout lays it out) nor emptied (its fit would then be searched for
  # an empty string), and a hidden text paints nothing into the picture.
  prepareForMenuRowPicture: ->
    @contentsWidget.hide()


  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    # The text's ink is the speech bubble's text role, given here as the text is built. The
    # centring this widget wants is @contentsWidget.alignCenter() below — the layout verb, not a
    # constructor argument.
    theme = WorldWdgt.theme
    @contentsWidget = new TextWdgt @contents,
      fontRole: theme.fonts.speechBubble
      italic: true
      color: theme.speechBubbleText

    @contentsWidget.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    @contentsWidget.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    @contentsWidget.alignMiddle()
    @contentsWidget.alignCenter()
    @contentsWidget.isEditable = true


    @_addNoSettle @contentsWidget
    @_invalidateLayout()


  _reLayout: (newBoundsForThisLayout) ->


    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    @_repaintAsOneUnit =>

      # adjust my layout -- apply BOTH position and size up front (was _applyWidth + _applyHeight,
      # which left the origin stale, so @position() below lagged one cadence on a move)
      @_applyGrantedBounds newBoundsForThisLayout

      @contentsWidget._reLayout (
        (new Rectangle 0, 0,
          (newBoundsForThisLayout.width() - (2 * @cornerRadius)),
          (newBoundsForThisLayout.height() - (2 * @cornerRadius) - newBoundsForThisLayout.height()/5))
        .translateBy @position().add @padding + @cornerRadius
      )

    super
    @_markLayoutAsFixed()



