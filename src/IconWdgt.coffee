class IconWdgt extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  constructor: (@color = WorldWdgt.preferencesAndSettings.iconDarkLineColor) ->
    super()
    @appearance = @createAppearance()

  # the generic icon; subclasses override with their specific appearance.
  # (a method, not a class field, so the build's dependency-finder still sees
  # the `new <X>IconAppearance` edge and orders the appearance before the icon.)
  createAppearance: -> new IconAppearance @

  widthWithoutSpacing: ->
    @appearance.widthWithoutSpacing()

  _resizeToWithoutSpacing: ->
    @_applyExtent @appearance.calculateRectangleOfIcon().extent()

  initialiseDefaultFrameContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false
    # FIXED (grow 0): an icon keeps its own natural size as window content rather than
    # stretching to fill the window -- an aspect/natural-size object, like the clock. (Also makes
    # its width convergence-independent: at grow 0 getWidthInStack = min(desiredWidth, availW).)
    @layoutSpecDetails.grow = 0

