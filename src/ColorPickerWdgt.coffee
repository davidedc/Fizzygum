# Note that the ColorPicker has no "set target..." from
# the menu.

class ColorPickerWdgt extends Widget

  # pattern: declare every child field here (not only set in the constructor) so
  # DeepCopierMixin's duplication picks it up even under lazy initialisation.
  feedback: nil
  choice: nil
  colorPalette: nil
  grayPalette: nil
  # my as-built width, frozen at the first menuEntryPreferredWidth ask (see
  # that method); declared so DeepCopierMixin duplication carries it.
  menuEntryNaturalWidth: nil

  constructor: ( @choice = Color.WHITE ) ->
    super()
    @appearance = new RectangularAppearance @
    @color = Color.WHITE
    @_applyExtent new Point 80, 80
    @_buildAndConnectChildren()

  colloquialName: ->
    "color picker"

  # As a menu entry, prefer the width I was BUILT at (the ctor's design extent,
  # or whatever a builder resized me to), frozen at the first ask — byte-what
  # the old `@width()` read-back answered at the rows-panel's first arrange,
  # but immune to the post-stretch no-shrink ratchet (menu-row-conformance
  # plan, Phase 1).
  menuEntryPreferredWidth: -> @menuEntryNaturalWidth ?= @width()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  # (Was `buildSubwidgets`, an ad-hoc one-hop indirection that hid the ctor child-building from the
  # constructor-build gate; converted to the canonical pattern, matching ButtonWdgt.)
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @feedback = new RectangleWdgt new Point(20, 20), @choice
    @colorPalette = new ColorPaletteWdgt @feedback, new Point @width(), 50
    @grayPalette = new GrayPaletteWdgt @feedback, new Point @width(), 5
    @_addNoSettle @colorPalette
    @_addNoSettle @grayPalette
    @_addNoSettle @feedback
    @_invalidateLayout()

  _reactToBeingAdded: (whereTo, beingDropped) ->

  getColor: ->
    @feedback.color
  

  # The palette/feedback arrange from my applied frame — the engine's standard
  # re-fit chokepoint (menu-row-conformance plan, Phase 2c: pure extraction from
  # the custom _reLayout below, which now composes it the stack-pattern way).
  # Declaring it also classifies me as the size-tracking container I am: a
  # stack / rows-panel arrange sizes me via _setWidthSizeHeightAccordingly
  # (virtual _applyWidth + synchronous _reLayout), re-arranging my innards in
  # the same write instead of relying on a later valve-scheduled pass.
  _reLayoutChildren: ->
    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of this widget are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    @colorPalette._applyMoveTo @position()
    @colorPalette._applyExtent new Point @width(), Math.round(@height() * 0.625)

    @grayPalette._applyMoveTo @colorPalette.bottomLeft()
    @grayPalette._applyExtent new Point @width(), Math.round(@height() * 0.0625)

    # SIZE feedback FIRST, then centre it from its NEW dims (schedule-valve arc V3, 2026-07-16):
    # the old move-then-resize order centred it with the STALE size, leaving the first pass after
    # any frame change off-centre by half the size delta -- a per-pass NON-IDEMPOTENCE the retired
    # synchronous hook's extra re-lay passes used to converge away (the census's force-re-lay
    # caught it the moment the valve made one pass the norm).
    @feedback._applyExtent new Point Math.min(@width(), Math.round(@height() * 0.25)), Math.round(@height() * 0.25)
    x = @grayPalette.left() + Math.floor((@grayPalette.width() - @feedback.width()) / 2)
    y = @grayPalette.bottom() + Math.floor((@bottom() - @grayPalette.bottom() - @feedback.height()) / 2)
    @feedback._applyMoveTo new Point x, y

    world.maybeEnableTrackChanges()
    @_fullChanged()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyBounds newBoundsForThisLayout
    @_reLayoutChildren()

    super
    @_markLayoutAsFixed()

