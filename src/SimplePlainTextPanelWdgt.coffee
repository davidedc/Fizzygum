# SimplePlainTextPanelWdgt ////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

# TODO the SimplePlainTextPanelWdgt can't quite stand on its own,
# it's really meant to be inside a ScrollPanel.
#
# The analogous VerticalStackPanel is better engineered,
# that one can indeed stand on its own.
#
# However, there really isn't a need for this widget
# because it doesn't provide anything more than what the
# SimplePlainText widget can already provide.

class SimplePlainTextPanelWdgt extends PanelWdgt

  constructor: (
    textAsString,
    wraps,
    padding
    ) ->

    debugger
    super()
    @takesOverAndCoalescesChildrensMenus = true
    @disableDrops()
    @disableDrops()
    @isTextLineWrapping = wraps
    @color = new Color 255, 255, 255
    ostmA = new SimplePlainTextWdgt(
      textAsString,nil,nil,nil,nil,nil,new Color(230, 230, 130), 1)
    ostmA.isEditable = true
    if !wraps
      ostmA.maxTextWidth = 0
    ostmA.enableSelecting()
    @add ostmA
    ostmA.lockToPanels()

