# THE INSPECTOR'S BODY under a part of the tool that stands on its own. The inspector browser paints the
# body every part of the tool in it stands on (InspectorBrowserWdgt, inspectorBodyFill), its set of
# inspectors lays that body under its inspectors, and an inspector holds its views on it; a part that
# stands anywhere else -- a view a person took out of its inspector, an inspector picked out of its row
# -- would show whatever lies under it (the desktop, its own drop shadow through its panes) and cast one
# shadow per control. So the part I paint for paints the body itself, exactly while its HOLDER lays none
# under its parts (laysTheInspectorBodyUnderItsParts, answered by the browser, by its set, InspectorRowWdgt,
# and by an inspector): asked of the holder at every paint, never stored, so the look follows every
# re-parenting.
#   Not painting the body, I am my base exactly -- my widget's seam rules and nothing else, nothing on the
# shadow pass, and no opaque cover, so the body my holder stands on shows through. Painting it, I fill my
# widget's box with inspectorBodyFill, read as I paint, its seam rules over it, and its box on the shadow
# pass: one body, one rectangular shadow, and an opaque cover of my widget's box. My outline is my
# widget's whole box either way, as my base's is.
#   ONE SHADOW AT ONE TONE: while I paint the body of an opaque widget, its shadow is the body's box
# alone (castsOnlyTheBody), as an opaque clipping panel's is its own box (ClippingWdgt) and a desktop
# icon's its own silhouette (WidgetHolderWithCaptionWdgt). Every part of the tool stands inside its box,
# so a part's silhouette adds nothing to the shape; it only darkens the strip twice where it falls flush
# with an edge (a list, its rows' panel, a code area). Each widget that wears me asks it in its shadow
# pass (_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow), the same few lines in each.
#   Worn by an inspector (InspectorWdgt) and by each of its views (MemberListWdgt, ObjectListWdgt,
# MemberEditorWdgt).
class InspectorBodyAppearance extends SeamRulesAppearance

  #: testing

  # Do I paint the body under my widget? Exactly while its holder lays none under its parts.
  _paintsTheBody: ->
    !(@widget.parent?.laysTheInspectorBodyUnderItsParts?() is true)

  # Does my widget cast only the body on this pass? On a shadow pass (appliedShadow given: its own shadow,
  # the hand's lift while it is carried, or an ancestor's), exactly while I paint the body and my widget
  # is opaque: a translucent widget lets its parts' coverage through, as a clipping panel's does.
  castsOnlyTheBody: (appliedShadow) ->
    appliedShadow? and @widget.alpha == 1 and @_paintsTheBody()

  #: colour roles

  # the colour I fill with when I paint the body, read as I paint (Widget.opaqueCoveredRect asks it too)
  _fillColor: ->
    WorldWdgt.theme.inspectorBodyFill

  #: geometry

  # what I fill fully opaque: my widget's box while I paint the body, nothing otherwise
  opaqueCoveredRect: ->
    return undefined unless @_paintsTheBody()
    @widget.boundingBox()

  #: drawing

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    unless @_paintsTheBody()
      return super aContext, clippingRectangle, appliedShadow
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx, localDamageBox) =>
      ctx.fillStyle = (if appliedShadow? then WorldWdgt.theme.shadowColor else @_fillColor()).toString()
      myBox = new Rectangle 0, 0, @widget.width(), @widget.height()
      @_fillLocalRectSnappedToDevicePixels ctx, localDamageBox.intersect(myBox)
      @_paintSeamRules ctx, localDamageBox  unless appliedShadow?
