# ToggleButtonMorph ////////////////////////////////////////////////////////


class ToggleButtonMorph extends SwitchButtonMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype


  constructor: (button1, button2) ->

    super [button1, button2]

  mouseClickLeft: ->
    debugger

    if @parent.wantsButtonsToBehaveLikeRadioButtons?
      if @buttonShown == 1
        return

    super

