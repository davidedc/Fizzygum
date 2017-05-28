# PointerMorph ///////////////////////////////////////////////////////////


# Points to a Morph. There can be multiple PointerMorph(s) for any
# Morph.

class PointerMorph extends BoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  # panes:
  scrollFrame: null
  buttonClose: null
  resizer: null
  underTheCarpetMorph: null

  constructor: (@target) ->
    super()

    @color = new Color 160, 160, 160
    @noticesTransparentClick = true

    lmContent1 = new CollapsedStateIconMorph()
    lmContent2 = new StringMorph2(
      @target.toString(),
      null, #@originallySetFontSize,
      null, #@fontStyle,
      null, #@isBold,
      null, #@isItalic,
      false, # isNumeric
      null, #color,
      new Color 255, 255, 255, #@backgroundColor,
      null, #@backgroundTransparency
    )
    # override inherited properties:
    lmContent2.noticesTransparentClick = true
    lmContent2.isEditable = false

    lmContent2.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    lmContent2.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.CROP


    lmContent3 = new CloseIconButtonMorph @

    @add lmContent1, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @add lmContent2, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    @add lmContent3, null, LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
    
    #lmContent1.setColor new Color 0, 255, 0
    #lmContent2.setColor new Color 0, 0, 255

    lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), LayoutSpec.SPREADABILITY_NONE
    lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), LayoutSpec.SPREADABILITY_MEDIUM
    lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), LayoutSpec.SPREADABILITY_NONE

    @fullRawMoveTo new Point 10 + 60 * 0, 30 + 50 * 1


  mouseClickLeft: (pos) ->
    debugger
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
    @destroy()

  closeThis: ->
    @destroy()

  closeThisAndTarget: ->
    @target.destroy()
    @destroy()

  developersMenu: ->
    menu = @developersMenuOfMorph()
    menu.addLine 1
    menu.addItem "close this button", true, @, "closeThis"
    menu.addItem "close target morph", true, @, "closeThisAndTarget"
    menu
