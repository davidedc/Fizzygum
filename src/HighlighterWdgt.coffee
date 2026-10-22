# Temporarily highlights a widget: hovering a widget's entry in a menu washes that widget (the FILL
# form), and a drag outlines the widget or the dock band a release would reach (the OUTLINE form).
#
# Doesn't cast a shadow (that would be too much, this is simple
# highlighting, it's not anything material that the user is
# supposed to click/drag/interact with).
#
# These widgets are transparently/automatically added/removed by the
# addHighlightingWidgets function in doOneCycle -- one of the per-cycle
# reconciler steps that all run before the @_repaintDamagedRects() call.
#
# That addHighlightingWidgets function RECONCILES: it only adds/modifies/removes
# the HighlighterWdgts that are new, need to change position, or need to go away
# (i.e. they are not blindly recreated each frame). That is load-bearing, not an
# optimisation: a steady highlight must emit ZERO damage (a per-frame recreate
# would repaint every cycle), and the kept identity is what the affine island
# re-homing and per-target style reconciliation hang off.
# addDragAffordanceWidgets copies this declare-and-reconcile shape.
#
# These widgets are always at the top, so you can always see a widget being
# highlighted even if it's (partially) occluded by other widgets.

class HighlighterWdgt extends RectangleWdgt

  # I am an EPHEMERAL overlay (owner's term): reconciler-owned, hit-test-excluded, shadow-free and
  # snapshot-excluded — all derived from this one flag via the isEphemeral() capability on Widget
  # (was a dedicated `skipsAddShadowManagement -> true` plus two per-marker hit-test predicates;
  # type-test-elimination campaign). Prototype flag: EVERY HighlighterWdgt is an ephemeral.
  _ephemeralOverlay: true

  # I am LAYOUT-INERT chrome, exactly like HandleWdgt / CaretWdgt (the only other isLayoutInert
  # classes). Affine transforms rough edge R2 (§6): the reconciler now parents a highlight INTO its
  # target's enclosing island so it warps + clips with the target (§4.6 halo-handle model). Being
  # layout-inert excludes me from childrenNotHandlesNorCarets / subWidgetsMergedFullBounds, so I can
  # never disturb a size-tracking container's content bounds — in particular I never count as the
  # single content child of a sugar island (a highlighted rotated widget would otherwise fail the
  # TrackingTransformFrameWdgt single-child check, and a second setRotationDegrees while hovered would
  # nest a second island). Still PAINTED into the island buffer (painting iterates ALL children, not
  # just the non-inert ones), so the highlight stays visible. No effect on the world-child path (those
  # content-bounds enumerations run only on scroll / size-tracking containers, never the world).
  isLayoutInert: -> true

  # The per-corner radii [topLeft, topRight, bottomRight, bottomLeft] I round my box's corners at, in
  # either form: the corners of what I cover where my box meets them, else 0 -- my OUTLINE form's
  # ring follows them (HighlightOutlineAppearance), and so does my FILL form's wash
  # (HighlightWashAppearance). coverBox sets them with my box, so they always describe the box I
  # have; square until then.
  outlineRadii: undefined

  # --- highlight style channel (drag-embed arc) ------------------------------------------------
  # A style descriptor is a plain record. Producers declare a target -> descriptor into
  # world.widgetsToBeHighlighted (a Map); the reconciler builds one HighlighterWdgt per target and
  # calls applyHighlightStyle. Two forms:
  #   {form:"fill",    color}               — a wash over the box (menu hover-highlight), in a colour
  #                                           translucent by its own alpha, painted at full alpha
  #   {form:"outline", color, alpha}        — a ring inside the box (drag candidate/reluctant affordance)
  @fillStyle: (color) -> {form: "fill", color: color}

  # Drag-embed candidate/reluctant outlines (spec §11), drawn at one width so a target that changes
  # state does not jump: a receptive candidate (and a dock band) in the accent -- the target the
  # release reaches --, a view-mode target that declines the drop in the neutral line colour. An
  # outline, not a wash: the whole-target fill is far too loud for a drag affordance.
  @candidateOutlineStyle: -> {form: "outline", color: WorldWdgt.theme.dropCandidateOutline, alpha: 1}
  @reluctantOutlineStyle: -> {form: "outline", color: WorldWdgt.theme.dropReluctantOutline, alpha: 1}

  # The editor-focus indicator is not a HighlighterWdgt: it is a per-widget PAINT-TIME selection
  # overlay drawn on top of the selected widget's own content (Widget._drawSelectionOverlay).

  # A highlighter takes one style for its life (the reconcilers apply it once, as they build it), and
  # each form is its own appearance: the outline paints nothing but its ring, so it holds no fill;
  # the wash paints nothing but its fill, so it holds no stroke.
  applyHighlightStyle: (style) ->
    if style.form is "outline"
      # the ring, in the style's colour, inside my box (HighlightOutlineAppearance); @alpha its opacity
      @appearance = new HighlightOutlineAppearance @
      @strokeColor = style.color
      @alpha = style.alpha ? 1
      @_changed()
    else
      # the wash, in the style's colour, over my box (HighlightWashAppearance), at my full alpha: the
      # colour carries the wash's translucency, so no second alpha dims it further
      @appearance = new HighlightWashAppearance @
      @strokeColor = undefined
      @color = style.color
      @alpha = 1
      @_changed()

  # Lay me over `aBox` (in my parent's plane), my outline rounding its corners at `radii`
  # (outlineRadii; undefined: square). My box and my corners are set here, together, and only here.
  coverBox: (aBox, radii = [0, 0, 0, 0]) ->
    @_applyBounds aBox
    unless @outlineRadii? and @outlineRadii.every((radius, corner) -> radius is radii[corner])
      @outlineRadii = radii
      @_changed()

  # Lay me over `aTarget` as the per-widget channel shows it: over its clipped-through bounds, in its
  # plane (the reconciler parents me there), my outline following the corners it shows.
  coverTarget: (aTarget) ->
    box = aTarget.clippedThroughBounds()
    @coverBox box, aTarget.cornerRadiiFollowingMyOutline box

