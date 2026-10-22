class LayoutElementAdderOrDropletWdgt extends LayoutChromeWdgt
  _acceptsDrops: true

  # what a person calls me: a slot a widget is dropped into (a click on me adds another after me)
  colloquialName: -> "drop slot"

  constructor: ->
    super()
    @setMinAndMaxBoundsAndSpreadability (new Point 15,15) , (new Point 15,15), DivisionStackLayoutSpec.SPREADABILITY_HANDLES

  # Role query (replaces the `x instanceof LayoutElementAdderOrDropletWdgt` filters in
  # Widget._addOrRemoveAdders): "am I one of the auto-inserted stack add/drop placeholders?" — true
  # here (and any subclass), so callers skip these chrome placeholders when scanning real stack
  # content. Parallels isLayoutInert. (type-test-elimination campaign, capability-first)
  isLayoutAdderOrDroplet: ->
    true

  # MY GLYPH (LayoutChromeWdgt._glyphOnMyPlate): a plus in layoutChromeGlyph, centred on my plate --
  # at layoutAdderGlyphSize as a DIVISION slot (a strip between a division's cells), at
  # layoutDropSlotGlyphSize as a CONTENT-stack drop slot or on my own. My plate and its pointer
  # states are my base's (LayoutChromeWdgt, LayoutChromeAppearance).
  _glyphOnMyPlate: ->
    theme = WorldWdgt.theme
    side = if @layoutSpec?.isDivisionElement?() then theme.layoutAdderGlyphSize else theme.layoutDropSlotGlyphSize
    [(new PlusIconAppearance @, theme.layoutChromeGlyph), side]

  # Both gestures below are MODE-AWARE off my OWN active spec: as a DIVISION slot my
  # insertions join the division layout (a division box rides along), as a CONTENT-stack
  # slot they are inserted SPEC-LESS so the stack's arrange adopts them at that position.
  activated: ->
    @bringToForeground()
    # if the adder/droplet is on its own, free floating, then
    # put a supporting widget underneath it and put the adder/droplet
    # in a layout.
    if @isFreeFloating()
      newWdgt = new Widget
      @parent.add newWdgt
      newWdgt._applyGrantedBounds @boundingBox()
      newWdgt.add @, layoutSpec: @_ensureDivisionBox()
      newWdgt.showAdders()

    newAdder = new LayoutElementAdderOrDropletWdgt
    if @layoutSpec?.isDivisionElement?()
      @addAsSiblingAfterMe newAdder, layoutSpec: newAdder._divisionBox
    else
      @addAsSiblingAfterMe newAdder

  # Runs inside the drop's single settle: addAsSiblingAfterMe is already non-settling (-> _addNoSettle),
  # and fullDestroy -> the non-settling core _fullDestroyNoSettle.
  _reactToChildDropped: (widgetBeingDropped) ->
    if @layoutSpec?.isDivisionElement?()
      @addAsSiblingAfterMe widgetBeingDropped, layoutSpec: widgetBeingDropped._ensureDivisionBox()
    else
      @addAsSiblingAfterMe widgetBeingDropped
    @_fullDestroyNoSettle()


