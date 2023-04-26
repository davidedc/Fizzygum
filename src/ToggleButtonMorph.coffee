class ToggleButtonMorph extends SwitchButtonMorph


  constructor: (button1, button2, startingButton = 0) ->
    if startingButton == 0
      super [button1, button2]
    else
      super [button2, button1]

  # changes the toggle without firing the action
  # i.e. clicking the toggle button
  # This is useful when the toggle needs to reflect the
  # state of something that has been independently changed
  # (i.e. changed by something else than the user clicking this toggle)
  # TODO this probably needs a better name, and also
  # TODO this should probably be in SwitchButtonMorph
  setToggleState: (whichOne) ->
    if @buttonShown != whichOne
      @buttonShown = whichOne
      @invalidateLayout()

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

  toggle: ->
    @buttons[@buttonShown].mouseClickLeft()
