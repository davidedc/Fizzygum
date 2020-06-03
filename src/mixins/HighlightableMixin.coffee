# changes the color of a morph based on whether pointer is
# hovering over or pressing on it

# REQUIRES Color

HighlightableMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      color_hover: new Color 192, 192, 192
      color_pressed: new Color 128, 128, 128
      color_normal: new Color 245, 244, 245

      state: 0
      STATE_NORMAL: 0
      STATE_HIGHLIGHTED: 1
      STATE_PRESSED: 2


      updateColor: ->
        @setColor switch @state
          when @STATE_NORMAL
            @color_normal
          when @STATE_HIGHLIGHTED
            @color_hover
          when @STATE_PRESSED
            @color_pressed

        @changed()
      
      mouseEnter: ->
        @state = @STATE_HIGHLIGHTED
        @updateColor()
        @startCountdownForBubbleHelp? @toolTipMessage  if @toolTipMessage
      
      mouseLeave: ->
        @state = @STATE_NORMAL
        @updateColor()
        world.destroyToolTips()  if @toolTipMessage
      
      mouseDownLeft: ->
        @state = @STATE_PRESSED
        @updateColor()

        if !window[@[arguments.callee.name + "_class_injected_in"]]?
          debugger

        super

      mouseUpLeft: ->
        @state = @STATE_NORMAL
        @updateColor()
