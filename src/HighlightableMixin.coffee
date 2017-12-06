# changes the color of a morph based on whether pointer is
# hovering over or pressing on it

# these comments below needed to figure out dependencies between classes
# REQUIRES globalFunctions


HighlightableMixin =
  # klass properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      color_hover: new Color 192, 192, 192
      color_pressed: new Color 128, 128, 128
      color_normal: new Color 255, 255, 255

      state: 0
      STATE_NORMAL: 0
      STATE_HIGHLIGHTED: 1
      STATE_PRESSED: 2


      updateColor: ->
        @color = switch @state
          when @STATE_NORMAL
            @color_normal
          when @STATE_HIGHLIGHTED
            @color_hover
          when @STATE_PRESSED
            @color_pressed

        @changed()
      
      # TriggerMorph events:
      mouseEnter: ->
        @state = @STATE_HIGHLIGHTED
        @updateColor()
        @startCountdownForBubbleHelp @hint  if @hint
      
      mouseLeave: ->
        @state = @STATE_NORMAL
        @updateColor()
        world.hand.destroyTemporaries()  if @hint
      
      mouseDownLeft: ->
        @state = @STATE_PRESSED
        @updateColor()

        if !window[@[arguments.callee.name + "_class_injected_in"]]?
          debugger

        # rephrasing "super" here...
        # we can't compile "super" in a mixin because we can't tell which
        # class this will be mixed in in advance, i.e. at compile time it doesn't
        # belong to a class, so at compile time it doesn't know which class
        # it will be injected in.
        # So that's why _at time of injection_ we need
        # to store the class it's injected in in a special
        # variable... and then at runtime here we use that variable to
        # implement super
        # TODO This rephrasing of "super" can be done at compile time
        window[@[arguments.callee.name + "_class_injected_in"]].__super__[arguments.callee.name]

      mouseUpLeft: ->
        @state = @STATE_NORMAL
        @updateColor()
