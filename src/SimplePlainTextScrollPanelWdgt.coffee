# SimplePlainTextScrollPanelWdgt ////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

# The SimplePlainTextScrollPanelWdgt allows you show/edit ONE
# text blurb only.
# It doesn't allow you to view/edit multiple text blurbs or
# other Morphs like the SimpleVerticalStackPanelWdgt/DocumentEditor do.
#
# However, what the SimplePlainTextScrollPanelWdgt DOES
# in respect to the SimpleVerticalStackPanelWdgt/DocumentEditor is to
# view/edit UNWRAPPED text, which is quite important for
# code, since really code must have the option of an
# unwrapped view.

class SimplePlainTextScrollPanelWdgt extends ScrollPanelWdgt

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
    ostmA = new SimplePlainTextWdgt(
      textAsString,nil,nil,nil,nil,nil,new Color(230, 230, 130), 1)
    ostmA.isEditable = true
    if !wraps
      ostmA.maxTextWidth = 0
    ostmA.enableSelecting()
    @setContents ostmA, padding
    ostmA.lockToPanels()

  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec PreferredSize.DONT_MIND , PreferredSize.DONT_MIND, 1
