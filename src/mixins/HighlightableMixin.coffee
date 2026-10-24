# Changes a widget's colour with its pointer STATE -- at rest, hovered, pressed -- re-deriving it at
# every transition (_updateColor). A state's colour is the widget's state field for it when one is
# set (color_normal / color_hover / color_pressed: set by a consumer, or by a live edit of this
# mixin's own field, which reaches every consumer that does not shadow it); otherwise it is the plain
# button's role for that state (Theme: plainButtonFill, plainButtonHoverFill, plainButtonPressFill),
# read as the state changes, so the mixin declares no colour of its own. A consumer with a look of
# its own answers _updateColor itself (SimpleButtonWdgt, IconButtonWdgt, the edit mark, a desktop
# link, a toolbar tool through ParentStainerMixin).

HighlightableMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      color_hover: undefined
      color_pressed: undefined
      color_normal: undefined

      state: 0
      STATE_NORMAL: 0
      STATE_HIGHLIGHTED: 1
      STATE_PRESSED: 2


      _updateColor: ->
        theme = WorldWdgt.theme
        @setColor switch @state
          when @STATE_NORMAL
            @color_normal ? theme.plainButtonFill
          when @STATE_HIGHLIGHTED
            @color_hover ? theme.plainButtonHoverFill
          when @STATE_PRESSED
            @color_pressed ? theme.plainButtonPressFill

        @_changed()
      
      hoverEntered: ->
        @state = @STATE_HIGHLIGHTED
        @_updateColor()
        @startCountdownForBubbleHelp? @toolTipMessage  if @toolTipMessage

      hoverExited: ->
        @state = @STATE_NORMAL
        @_updateColor()
        world.destroyToolTips()  if @toolTipMessage
      
      # a press shows PRESSED, and goes on up as any widget's does (Widget.pressBegan)
      pressBegan: ->
        @state = @STATE_PRESSED
        @_updateColor()

        if !window[@[arguments.callee.name + "_class_injected_in"]]?
          debugger

        super

      # THE PRESS'S TWO ENDINGS (ActivePointerWdgt, the press's AUDIENCE): whichever comes, I leave
      # PRESSED for the look of where the pointer actually is -- hovered if it rests on me, at rest
      # otherwise, a finger never resting -- because a press can end with the pointer anywhere: let go
      # somewhere else, or carried off me by a scroll. Not through hoverEntered, which would also
      # start my tooltip's countdown.
      pressEnded: ->
        @state = if world.hand.restsOn @ then @STATE_HIGHLIGHTED else @STATE_NORMAL
        @_updateColor()

      pressCancelled: ->
        @state = if world.hand.restsOn @ then @STATE_HIGHLIGHTED else @STATE_NORMAL
        @_updateColor()
