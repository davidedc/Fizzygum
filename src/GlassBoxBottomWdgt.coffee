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
    @setColor Color.create 230,230,230
    @strokeColor = Color.create 196,195,196
    @setAlphaScaled 50

  reLayout: ->

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    thumbnailSize = @width()

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    for w in childrenNotHandlesNorCarets

      if (w instanceof MenuItemMorph)
        w.fullRawMoveTo @topLeft().add((new Point 0 ,(@height() - w.height())/2 ).round())
      else
        if w.idealRatioWidthToHeight?
          ratio = w.idealRatioWidthToHeight
          if ratio > 1
            # more wide than tall
            w.rawSetExtent new Point thumbnailSize, thumbnailSize / ratio
          else
            # more tall than wide
            w.rawSetExtent new Point thumbnailSize * ratio, thumbnailSize
        else
          w.rawSetExtent new Point thumbnailSize, thumbnailSize

        w.fullRawMoveTo @topLeft().add((new Point (thumbnailSize - w.width())/2 ,(thumbnailSize - w.height())/2 ).round())


    world.maybeEnableTrackChanges()
    @fullChanged()
