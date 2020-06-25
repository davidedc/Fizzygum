class SwitchButtonMorph extends Widget

  buttons: nil
 
  highlightColor: new Color 192, 192, 192
  pressColor: new Color 128, 128, 128
 
  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  
  buttonShown: 0

  # overrides to superclass
  color: Color.WHITE

  constructor: (@buttons) ->

    # additional properties:

    super()

    #@color = new Color 255, 152, 152
    #@color = Color.WHITE
    for eachButton in @buttons
      @add eachButton

    @invalidateLayout()
  
  # so that when you duplicate a "selected" toggle
  # and you pick it up and you attach it somewhere else
  # it gets automatically unselected
  iHaveBeenAddedTo: (whereTo, beingDropped) ->
    @resetSwitchButton()

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts
    #  debugger

    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      if @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout


    @rawSetBounds newBoundsForThisLayout

    counter = 0
    for eachButton in @buttons
      if eachButton.parent == @
        eachButton.doLayout @bounds
        if counter % @buttons.length == @buttonShown
          eachButton.show()
        else
          eachButton.hide()
      counter++

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()


  # TODO
  getTextDescription: ->

  # if one calls "isSelected" it probably means that this SwitchButton
  # has two buttons: a "selected" button and an "unselected" button
  isSelected: ->
    return @buttonShown != 0  

  mouseClickLeft: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    @buttonShown++
    @buttonShown = @buttonShown % @buttons.length

    @invalidateLayout()
    # TODO gross pattern break - usually mouseClickLeft has 9 params
    # none of which is a widget
    @escalateEvent "mouseClickLeft", @

  resetSwitchButton: ->
    @buttonShown = 0
    @invalidateLayout()
