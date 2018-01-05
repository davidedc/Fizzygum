# ToggleButtonMorph ////////////////////////////////////////////////////////


class ToggleButtonMorph extends SwitchButtonMorph


  constructor: (button1, button2, startingButton = 0) ->
    if startingButton == 0
      super [button1, button2]
    else
      super [button2, button1]

  mouseClickLeft: ->
    # can't "unselect" a radio button if it's attached to a radio
    # panel that mandates that at least one of the radio
    # buttons must be switched on.
    if @parent.wantsButtonsToBehaveLikeRadioButtons? and @parent.wantsButtonsToBehaveLikeRadioButtons
      unless @parent.allowsRadioButtonsToBeAllDisabled? and @parent.allowsRadioButtonsToBeAllDisabled
        if @buttonShown == 1
          return

    super

  select: (whichOne) ->
    if @buttonShown != whichOne
      @buttons[@buttonShown].mouseClickLeft()
