# the glassbox bottom goes UNDER a thumbnail, it provides
# support for both a widget that would go on top of
# it, and potentially for the glass box top that
# might be at the top of everything.
# This helps with the following: it provides a
# visually contrasting background and it gives
# a larger target to grab the widget.

class GlassBoxBottomWdgt extends BoxWdgt

  constructor: ->
    super
    @setColor Color.create 230,230,230
    @strokeColor = Color.create 196,195,196
    @setAlphaScaled 50

  # Role query (replaces the `aWdgt instanceof GlassBoxBottomWdgt` wrap-idempotency guards in
  # ToolPanelWdgt/HorizontalMenuPanelWdgt.add): "am I already a glass-box template wrapper?" -- true
  # here only, so a widget is never wrapped twice. Dispatched via ?() (nothing on Widget).
  # (type-test-elimination campaign)
  isGlassBoxWrapper: ->
    true

  _reLayoutSelf: ->

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    thumbnailSize = @width()

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    for w in childrenNotHandlesNorCarets

      # a menu item is sized to its text; other contents become square thumbnails
      # (was `w instanceof MenuItemWdgt`). (type-test-elimination campaign)
      if w.isTextSizedGlassBoxItem?()
        w._applyMoveToAndNotify @topLeft().add((new Point 0 ,(@height() - w.height())/2 ).round())
      else
        if w.idealRatioWidthToHeight?
          ratio = w.idealRatioWidthToHeight
          if ratio > 1
            # more wide than tall
            w._applyExtentAndNotify new Point thumbnailSize, thumbnailSize / ratio
          else
            # more tall than wide
            w._applyExtentAndNotify new Point thumbnailSize * ratio, thumbnailSize
        else
          w._applyExtentAndNotify new Point thumbnailSize, thumbnailSize

        w._applyMoveToAndNotify @topLeft().add((new Point (thumbnailSize - w.width())/2 ,(thumbnailSize - w.height())/2 ).round())


    world.maybeEnableTrackChanges()
    @fullChanged()
