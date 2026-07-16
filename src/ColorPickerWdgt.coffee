# Note that the ColorPicker has no "set target..." from
# the menu.

class ColorPickerWdgt extends Widget

  # pattern: all the children should be declared here
  # the reason is that when you duplicate a widget
  # , the duplicated widget needs to have the handles
  # that will be duplicated. If you don't list them
  # here, then they need to be initialised in the
  # constructor. But actually they might not be
  # initialised in the constructor if a "lazy initialisation"
  # approach is taken. So it's good practice
  # to list them here so they can be duplicated either way.
  feedback: nil
  choice: nil
  colorPalette: nil
  grayPalette: nil

  constructor: ( @choice = Color.WHITE ) ->
    super()
    @appearance = new RectangularAppearance @
    @color = Color.WHITE
    @_applyExtent new Point 80, 80
    @_buildAndConnectChildren()

  colloquialName: ->
    "color picker"

  # As a menu entry, prefer my own current width (MenuWdgt.maxWidthOfMenuEntries
  # calls this polymorphically instead of type-checking the entry).
  menuEntryPreferredWidth: -> @width()

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

  # Construction-order guard for the composite-child re-lay (the WidgetHolderWithCaptionWdgt
  # pattern): my ctor _applyExtents 80x80 BEFORE _buildAndConnectChildren, so the immediate-resize
  # hook must stay inert until my palettes/feedback exist (the trailing _invalidateLayout/settle
  # lays them out once, when they all do).
  _compositeChildrenBuilt: ->
    @feedback?

  getColor: ->
    @feedback.color
  

  # (ordered-downwalk plan §9-N3, 2026-07-16) Replaces the Stage-A-era exempt marker: its census
  # boilerplate answered "who raw-_applyExtents me?", but Stage B3 changed the question to "can an
  # ARRANGE move/resize me without my _reLayout running?" -- yes: I am desktop-creatable and droppable into windows/stacks,
  # so I can sit bypass-sized (_applyExtentBase) with my children laid for the OLD frame. Declaring
  # puts me under the settle engine's frame-changed child re-lay (__reLayoutOneSettleNode injection)
  # and the base Widget._applyExtent immediate-resize hook.
  _placesChildrenInLayout: ->
    true

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

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

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyBounds newBoundsForThisLayout
    @colorPalette._applyMoveTo @position()
    @colorPalette._applyExtent new Point @width(), Math.round(@height() * 0.625)

    @grayPalette._applyMoveTo @colorPalette.bottomLeft()
    @grayPalette._applyExtent new Point @width(), Math.round(@height() * 0.0625)

    x = @grayPalette.left() + Math.floor((@grayPalette.width() - @feedback.width()) / 2)
    y = @grayPalette.bottom() + Math.floor((@bottom() - @grayPalette.bottom() - @feedback.height()) / 2)
    @feedback._applyMoveTo new Point x, y
    @feedback._applyExtent new Point Math.min(@width(), Math.round(@height() * 0.25)), Math.round(@height() * 0.25)

    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()

