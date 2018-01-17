# SimplePlainTextScrollPane ////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

# The SimplePlainTextScrollPane allows you show/edit ONE
# text blurb only.
# It doesn't allow you to view/edit multiple text blurbs or
# other Morphs like the VerticalStackWdgt/DocumentEditor do.
#
# However, what the SimplePlainTextScrollPane DOES
# in respect to the VerticalStackWdgt/DocumentEditor is to
# view/edit UNWRAPPED text, which is quite important for
# code, since really code must have the option of an
# unwrapped view.

class SimplePlainTextScrollPane extends ScrollFrameMorph

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
    ostmA = new SimplePlainText(
      textAsString,nil,nil,nil,nil,nil,new Color(230, 230, 130), 1)
    ostmA.isEditable = true
    if !wraps
      ostmA.maxTextWidth = 0
    ostmA.enableSelecting()
    @setContents ostmA, padding

