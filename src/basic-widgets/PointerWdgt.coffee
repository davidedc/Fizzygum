# this file is excluded from the fizzygum homepage build

# Points to a Widget. There can be multiple PointerWdgt(s) for any
# Widget.

class PointerWdgt extends BoxWdgt

  constructor: (@target) ->
    super()

    @color = Color.create 160, 160, 160
    @noticesTransparentClick = true

    @_buildAndConnectChildren()

    @moveTo new Point 10 + 60 * 0, 30 + 50 * 1

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    lmContent1 = new CollapsedStateIconWdgt
    lmContent2 = new StringWdgt(
      @target.toString(),
      nil, #@originallySetFontSize,
      nil, #@fontStyle,
      nil, #@isBold,
      nil, #@isItalic,
      false, # isNumeric
      nil, #color,
      Color.WHITE, #@backgroundColor,
      nil, #@backgroundTransparency
    )
    # override inherited properties:
    lmContent2.noticesTransparentClick = true
    lmContent2.isEditable = false

    lmContent2.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    lmContent2.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.CROP


    lmContent3 = new CloseIconButtonWdgt

    @_addNoSettle lmContent1, layoutSpec: LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @_addNoSettle lmContent2, layoutSpec: LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @_addNoSettle lmContent3, layoutSpec: LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    #lmContent1.setColor Color.LIME
    #lmContent2.setColor Color.BLUE

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), LayoutSpec.SPREADABILITY_NONE
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), LayoutSpec.SPREADABILITY_MEDIUM
    lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), LayoutSpec.SPREADABILITY_NONE


  mouseClickLeft: (pos) ->
    if @target.destroyed
      @inform "The pointed widget\nis dead!"
      return

    if @target.isAncestorOf @
      @inform "The pointed widget is\nalready open and containing\nwhat you just clicked on!"
      return

    if !@target.isOrphan()
      @target.createPointerWdgt()
    myPosition = @positionAmongSiblings()
    @parent.add @target, myPosition
    @target.moveTo @position()
    @target.fullChanged()
    @close()

  closeThis: ->
    @close()

  closeThisAndTarget: ->
    @target.close()
    @close()

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    menu.addLine 1
    menu.addMenuItem "close this button", @, "closeThis"
    menu.addMenuItem "close target widget", @, "closeThisAndTarget"
