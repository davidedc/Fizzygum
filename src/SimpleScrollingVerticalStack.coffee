# SimpleScrollingVerticalStack ////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

class SimpleScrollingVerticalStack extends ScrollFrameMorph

  constructor: ->
    VS = new VerticalStackWdgt()
    VS.tight = false
    VS.isLockingToPanels = true
    super VS
    @disableDrops()
    @isTextLineWrapping = true
    @color = new Color 255, 255, 255

    ostmA = new TextMorph2BridgeForWrappingText(
      "A small string\n\n\nhere another.",nil,nil,nil,nil,nil,new Color(230, 230, 130), 1)
    ostmA.isEditable = true
    ostmA.enableSelecting()
    @setContents ostmA, 5

