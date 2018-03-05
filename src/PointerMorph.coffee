# Points to a Widget. There can be multiple PointerMorph(s) for any
# Widget.

class PointerMorph extends BoxMorph

  constructor: (@target) ->
    super()

    @color = new Color 160, 160, 160
    @noticesTransparentClick = true

    lmContent1 = new CollapsedStateIconMorph()
    lmContent2 = new StringMorph2(
      @target.toString(),
      nil, #@originallySetFontSize,
      nil, #@fontStyle,
      nil, #@isBold,
      nil, #@isItalic,
      false, # isNumeric
      nil, #color,
      new Color 255, 255, 255, #@backgroundColor,
      nil, #@backgroundTransparency
    )
    # override inherited properties:
    lmContent2.noticesTransparentClick = true
    lmContent2.isEditable = false

    lmContent2.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    lmContent2.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.CROP


    lmContent3 = new CloseIconButtonMorph @

    @add lmContent1, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @add lmContent2, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @add lmContent3, nil, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    #lmContent1.setColor new Color 0, 255, 0
    #lmContent2.setColor new Color 0, 0, 255

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), LayoutSpec.SPREADABILITY_NONE
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), LayoutSpec.SPREADABILITY_MEDIUM
    lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), LayoutSpec.SPREADABILITY_NONE

    @fullMoveTo new Point 10 + 60 * 0, 30 + 50 * 1


  mouseClickLeft: (pos) ->
    if @target.destroyed
      @inform "The pointed morph\nis dead!"
      return

    if @target.isAncestorOf @
      @inform "The pointed morph is\nalready open and containing\nwhat you just clicked on!"
      return

    if !@target.isOrphan()
      @target.createPointerMorph()
    myPosition = @positionAmongSiblings()
    @parent.add @target, myPosition
    @target.fullMoveTo @position()
    @target.fullChanged()
    @close()

  closeThis: ->
    @close()

  closeThisAndTarget: ->
    @target.close()
    @close()

  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    menu.addLine 1
    menu.addMenuItem "close this button", true, @, "closeThis"
    menu.addMenuItem "close target morph", true, @, "closeThisAndTarget"
