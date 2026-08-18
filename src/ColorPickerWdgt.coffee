# A colour picker: two palettes to drag across and a swatch showing what came out.
#
# It is a CONTROLLER exactly as its own palettes are — "set target..." aims it at another widget,
# and a pick then drives that widget's colour property. In a system whose principle is "a colour is
# changed with a picker aimed at the thing", the picker is the last widget that should lack the
# handle; a palette carries both the handle and (through its choice marker) the picture, and so
# does this.

class ColorPickerWdgt extends Widget

  @augmentWith ControllerMixin


  # I drive colours: what the "choose target property" menu filters the target's pins by, and the
  # adjective in the "set target" tooltip.
  producesPinKind: "color"

  # pattern: declare every child field here (not only set in the constructor) so
  # the Duplicator's walk picks it up even under lazy initialisation.
  feedback: undefined
  # the colour I am SEEDED with, which is all this is: the swatch below is built from it and from
  # then on the swatch holds the truth (getColor reads it). Nothing re-reads this field, so a pick
  # deliberately does not write it back — that would be a second, driftable statement of a fact
  # @feedback.color already makes.
  choice: undefined
  colorPalette: undefined
  grayPalette: undefined
  # my as-built width, frozen at the first menuEntryPreferredWidth ask (see
  # that method); declared so Duplicator duplication carries it.
  menuEntryNaturalWidth: undefined

  constructor: ( @choice = Color.WHITE ) ->
    super()
    @appearance = new RectangularAppearance @
    @color = Color.WHITE
    @_applyExtent new Point 80, 80
    @_buildAndConnectChildren()


  # As a menu entry, prefer the width I was BUILT at (the ctor's design extent,
  # or whatever a builder resized me to), frozen at the first ask — byte-what
  # the old `@width()` read-back answered at the rows-panel's first arrange,
  # but immune to the post-stretch no-shrink ratchet (menu-row-conformance
  # plan, Phase 1).
  menuEntryPreferredWidth: -> @menuEntryNaturalWidth ?= @width()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  # (The canonical name matters: an ad-hoc alias like `buildSubwidgets` hides the ctor
  # child-building from the constructor-build gate; matches ButtonWdgt.)
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @feedback = new RectangleWdgt new Point(20, 20), @choice
    @colorPalette = new ColorPaletteWdgt new Point @width(), 50
    @grayPalette = new GrayPaletteWdgt new Point @width(), 5
    # Both palettes drive ME rather than the swatch directly. I am the one that knows a pick has
    # happened, so I can keep the swatch showing it AND fire my own wire onward; aimed at the
    # swatch they would update it and nothing would ever tell me. wireTo, not a hand-built record,
    # because it is the named wire verb and it declares the edge there and then.
    palette.wireTo @, "setPickedColor" for palette in [@colorPalette, @grayPalette]
    @_addNoSettle @colorPalette
    @_addNoSettle @grayPalette
    @_addNoSettle @feedback
    @_invalidateLayout()

  _reactToBeingAdded: (whereTo, beingDropped) ->

  getColor: ->
    @feedback.color

  # A colour picked THROUGH me: the write half of my picked-colour pin, and what both my palettes
  # drive. Keep the swatch showing it, then fire my own wire onward so a picker aimed at a target
  # behaves like every other controller.
  setPickedColor: (aColor) ->
    return unless aColor?
    @feedback.setColor aColor
    @updateTarget()
    return aColor

  # My picked colour is a genuine read/WRITE pin — the pair reads and writes @feedback.color, the
  # same property. (Widget's own `color` pin is a different one: it writes @color, my chrome, which
  # the constructor sets to white and which has nothing to do with the picked colour. Pairing THOSE
  # two into one pin would be the lie, because a wire writing it would not change what a reader
  # reads.) The names are asymmetric because each is fixed from its own side: `getColor` is the
  # duck-typed spelling Widget.setColor and the spreadsheet's cell reader both look for, and
  # `setColor` was already taken by the chrome.
  # `picked color` ANNOUNCES: `setPickedColor` is the ONLY write path (audited — `@feedback` is mine
  # alone, no other class touches it, and the constructor runs before anyone can be following me), and
  # it raises `updateTarget`, which announces whether or not I drive anything.
  pins: -> super().concat [ new PinSpec "picked color", "color", set: "setPickedColor", get: "getColor", announces: true ]
  principalPinLabel: "picked color"

  # the wire verb every controller ends at: fire my picked colour to whatever I am aimed at.
  # (like PaletteWdgt, no half-built-wire repair at fire time: a WireSpec carries both its target and
  # its action from construction — §P4)
  updateTarget: ->
    @_fireConnection @getColor()
    return

  # push my current colour the moment I am wired, as a slider does — I always have one to push.
  reactToTargetConnection: ->
    @updateTarget()

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addTargetConnectionMenuEntries menu


  # The palette/feedback arrange from my applied frame — the engine's standard
  # re-fit chokepoint (menu-row-conformance plan, Phase 2c: pure extraction from
  # the custom _reLayout below, which now composes it the stack-pattern way).
  # Declaring it also classifies me as the size-tracking container I am: a
  # stack / rows-panel arrange sizes me via _setWidthSizeHeightAccordingly
  # (virtual _applyWidth + synchronous _reLayout), re-arranging my innards in
  # the same write instead of relying on a later valve-scheduled pass.
  _reLayoutChildren: ->
    @_repaintAsOneUnit =>

      @colorPalette._applyBounds @position(), new Point @width(), Math.round(@height() * 0.625)

      @grayPalette._applyBounds @colorPalette.bottomLeft(), new Point @width(), Math.round(@height() * 0.0625)

      # SIZE feedback FIRST, then centre it from its NEW dims (schedule-valve arc V3, 2026-07-16):
      # the old move-then-resize order centred it with the STALE size, leaving the first pass after
      # any frame change off-centre by half the size delta -- a per-pass NON-IDEMPOTENCE the retired
      # synchronous hook's extra re-lay passes used to converge away (the census's force-re-lay
      # caught it the moment the valve made one pass the norm).
      @feedback._applyExtent new Point Math.min(@width(), Math.round(@height() * 0.25)), Math.round(@height() * 0.25)
      x = @grayPalette.left() + Math.floor((@grayPalette.width() - @feedback.width()) / 2)
      y = @grayPalette.bottom() + Math.floor((@bottom() - @grayPalette.bottom() - @feedback.height()) / 2)
      @feedback._applyMoveTo new Point x, y

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyGrantedBounds newBoundsForThisLayout
    @_reLayoutChildren()

    super
    @_markLayoutAsFixed()

