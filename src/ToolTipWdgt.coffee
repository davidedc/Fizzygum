# ToolTipWdgt ///////////////////////////////////////////////////

# when invoked using...
#    createInAWhileIfHandStillContainedInMorph / openAt
#	... I can temporarily display any widget.
# (is you just use the default constructor it will just sit there
# and basically _not_ behave like a tool tip)
# Note that I'm not a PopUp, for example I can't be pinned.
# I'm always attached to the world, without any layout constraints.

class ToolTipWdgt extends Widget

  contents: nil
  padding: nil # additional vertical pixels
  morphInvokingThis: nil

  constructor: (
   @contents="",
   @morphInvokingThis,
   @color = (new Color 230, 230, 230),
   cornerRadius,
   @padding = 0,
   isThought = false) ->
    # console.log "bubble super"
    super()
    @cornerRadius = cornerRadius or 6
    @appearance = new BubblyAppearance @, isThought, true
    # console.log @color
  
  @createBubbleHelpIfHandStillOnMorph: (contents, morphInvokingThis) ->
    # console.log "bubble createBubbleHelpIfHandStillOnMorph"
    # let's check that the item that the
    # bubble is about is still actually there
    # and the mouse is still over it, otherwise
    # do nothing.
    if morphInvokingThis.root() == world and morphInvokingThis.boundsContainPoint world.hand.position()
      theBubble = new @ localize(contents), morphInvokingThis, nil, nil
      theBubble.openAt theBubble.morphInvokingThis.rightCenter().add new Point -8, 0

  @createInAWhileIfHandStillContainedInMorph: (morphInvokingThis, contents, delay = 500) ->
    # console.log "bubble createInAWhileIfHandStillContainedInMorph"
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.animationsPacingControl and
     AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE
        @createBubbleHelpIfHandStillOnMorph contents, morphInvokingThis
    else
      setTimeout (=>
        @createBubbleHelpIfHandStillOnMorph contents, morphInvokingThis
        )
        , delay
  
  # ToolTipWdgt invoking:
  openAt: (pos) ->
    # console.log "tool tip opening"
    @fullRawMoveTo pos.subtract new Point 0, @height()
    @fullRawMoveWithin world

    @buildAndConnectChildren()

    world.add @
    @addShadow()
    @fullChanged()
    world.hand.destroyToolTips()
    world.hand.toolTipsList.push @
    
  buildAndConnectChildren: ->
    # console.log "bubble buildAndConnectChildren"
    # re-build my contents
    if @contentsMorph
      @contentsMorph = @contentsMorph.destroy()
    if @contents instanceof Widget
      @contentsMorph = @contents
    else if isString @contents
      @contentsMorph = new TextMorph(
        @contents,
        WorldMorph.preferencesAndSettings.bubbleHelpFontSize,
        nil,
        false,
        true,
        "center")
    else if @contents instanceof HTMLCanvasElement
      @contentsMorph = new Widget()
      @contentsMorph.silentRawSetWidth @contents.width
      @contentsMorph.silentRawSetHeight @contents.height
      @contentsMorph.backBuffer = @contents
      @contentsMorph.backBufferContext = @contentsMorph.backBuffer.getContext "2d"
    else
      @contentsMorph = new TextMorph(
        @contents.toString(),
        WorldMorph.preferencesAndSettings.bubbleHelpFontSize,
        nil,
        false,
        true,
        "center")
    @add @contentsMorph

    # adjust my layout
    @silentRawSetWidth @contentsMorph.width() + ((if @padding then @padding * 2 else @cornerRadius * 2))
    @silentRawSetHeight @contentsMorph.height() + @cornerRadius + @padding * 2 + 2

    # position my contents
    @contentsMorph.fullRawMoveTo @position().add(
      new Point(@padding or @cornerRadius, @padding + 1))


