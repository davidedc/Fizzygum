# the glassbox bottom goes UNDER a thumbnail, it provides
# support for both a widget that would go on top of
# it, and potentially for the glass box top that
# might be at the top of everything.
# This helps with the following: it provides a
# visually contrasting background and it gives
# a larger target to grab the widget.

class GlassBoxBottomWdgt extends BoxMorph

  constructor: ->
    super
    @setColor new Color 230,230,230
    @strokeColor = new Color 196,195,196
    @setAlphaScaled 50

  reLayout: ->
    debugger

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

    thumbnailSize = @width()

    childrenNotHandlesNorCarets = @children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    for eachChild in childrenNotHandlesNorCarets

      if (eachChild instanceof MenuItemMorph)
        eachChild.fullRawMoveTo @topLeft().add((new Point 0 ,(@height() - eachChild.height())/2 ).round())
      else
        if eachChild.idealRatioWidthToHeight?
          ratio = eachChild.idealRatioWidthToHeight
          if ratio > 1
            # more wide than tall
            eachChild.rawSetExtent new Point thumbnailSize, thumbnailSize / ratio
          else
            # more tall than wide
            eachChild.rawSetExtent new Point thumbnailSize * ratio, thumbnailSize 
        else
          eachChild.rawSetExtent new Point thumbnailSize, thumbnailSize

        eachChild.fullRawMoveTo @topLeft().add((new Point (thumbnailSize - eachChild.width())/2 ,(thumbnailSize - eachChild.height())/2 ).round())


    trackChanges.pop()
    @fullChanged()
