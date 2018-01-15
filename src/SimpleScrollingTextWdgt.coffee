# SimpleScrollingTextWdgt ////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

class SimpleScrollingTextWdgt extends ScrollFrameMorph

  constructor: (
    textAsString,
    wraps,
    padding
    ) ->

    super()
    @takesOverAndCoalescesChildrensMenus = true
    @disableDrops()
    @contents.disableDrops()
    @isTextLineWrapping = wraps
    @color = new Color 255, 255, 255
    ostmA = new TextMorph2BridgeForWrappingText(
      textAsString,nil,nil,nil,nil,nil,new Color(230, 230, 130), 1)
    ostmA.isEditable = true
    if !wraps
      ostmA.maxTextWidth = 0
    ostmA.enableSelecting()
    @setContents ostmA, padding

