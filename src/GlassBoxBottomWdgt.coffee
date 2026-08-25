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

  # Role query (replaces the `aWdgt instanceof GlassBoxBottomWdgt` wrap-idempotency guard in
  # ToolPanelWdgt.add): "am I already a glass-box template wrapper?" -- true
  # here only, so a widget is never wrapped twice. Dispatched via ?() (nothing on Widget).
  # (type-test-elimination campaign)
  isGlassBoxWrapper: ->
    true

  # The one widget I wrap -- the tool this cell offers, which is what names the cell in a menu.
  # (GlassBoxTopWdgt's grab reads the same first child.)
  glassBoxItem: ->
    @children[0]

  # The widget a TAP on me actually reaches, which is therefore what any PROJECTION of this cell
  # -- a toolbar overflow menu's row -- must click: one dispatch contract for every tool family.
  # A tool that is not actionable as a thumbnail wears a LID (ToolPanelWdgt puts one there), and
  # then the lid is what the pointer lands on and the lid is what carries the click; a tool that
  # handles its own clicks wears none and catches its taps itself.
  thumbnailClickReceiver: ->
    (@firstChildSuchThat (eachChild) -> eachChild.isGlassBoxLid?()) ? @glassBoxItem()

  _reLayoutSelf: ->

    @_repaintAsOneUnit =>

      thumbnailSize = @width()

      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      for w in childrenNotHandlesNorCarets

        # a menu item is sized to its text; other contents become square thumbnails
        # (instead of `w instanceof MenuItemWdgt`; type-test-elimination campaign)
        if w.isTextSizedGlassBoxItem?()
          w._applyMoveTo @topLeft().add((new Point 0 ,(@height() - w.height())/2 ).round())
        else
          if w.idealRatioWidthToHeight?
            ratio = w.idealRatioWidthToHeight
            if ratio > 1
              # more wide than tall
              w._applyExtent new Point thumbnailSize, thumbnailSize / ratio
            else
              # more tall than wide
              w._applyExtent new Point thumbnailSize * ratio, thumbnailSize
          else
            w._applyExtent new Point thumbnailSize, thumbnailSize

          w._applyMoveTo @topLeft().add((new Point (thumbnailSize - w.width())/2 ,(thumbnailSize - w.height())/2 ).round())
