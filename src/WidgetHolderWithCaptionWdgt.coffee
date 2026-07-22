# This is what typically people refer to as "icons", however that's not
# quite precise. An icon is just a graphic symbol, it doesn't have a caption per se.
# This widget has a caption instead. Also, since it can hold any widget, the
# final name is WidgetHolderWithCaptionWdgt.

class WidgetHolderWithCaptionWdgt extends Widget

  label: nil

  # The ONE home for the standard desktop-icon extent — every launcher/shortcut
  # creation site sizes through this: a 60px icon band + the two-line caption
  # band below it (2 × fontHeight(shortcutsFontSize 12) + 2 = 32).
  @standardDesktopIconExtent: -> new Point 95, 92

  constructor: (@labelContent, @icon) ->
    super()
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if !@icon?
      @icon = new SimpleDropletWdgt "icon"
    @_applyExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()
    @_addNoSettle @icon
    # the caption: a soft-wrapping TextWdgt in a fixed two-line band. FLOAT
    # keeps the set font size (SCALEUP would inflate short captions to fill
    # both lines); the CROP default ellipsises what overflows line 2, and
    # editing an ellipsised caption hands off to the pop-out editor
    # (handOffToPopoutEditorIfOverflowing), same as the old one-line label.
    @label = new TextWdgt @labelContent, WorldWdgt.preferencesAndSettings.shortcutsFontSize
    @label.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.FLOAT
    @label.color = Color.WHITE
    @label.hasDarkOutline = true
    @_addNoSettle @label, beingDropped: true
    @label.alignCenter()
    @label.isEditable = true
    # update layout
    @_invalidateLayout()

  # the caption band: two lines at the label's set font size, plus a whisker of
  # breathing room. (The label owns the font; the holder only sizes the band.)
  _labelBandHeight: ->
    2 * (@label.fontHeight @label.originallySetFontSize) + 2

  # I am a desktop icon (an icon with a caption). isDesktopIcon replaces the
  # `instanceof WidgetHolderWithCaptionWdgt` tests that find/skip icons among desktop
  # children; participatesInIconGrid additionally drives the auto grid-positioning of
  # newly-created icons -- BinOpenerWdgt overrides it to false (it is an icon but the
  # desktop places it itself, not the grid). (type-test-elimination campaign)
  isDesktopIcon: ->
    true

  participatesInIconGrid: ->
    true


  setColor: (theColor, ignored) ->
    @icon.setColor theColor

  # width → height rule: the icon band scales with the width (60/95 of it, the
  # standard extent's proportion) while the caption band is font-fixed.
  _heightForWidth: (aWidth) ->
    (Math.round aWidth * 60 / 95) + @_labelBandHeight()

  widthWithoutSpacing: ->
    Math.min @width(), @height()

  _resizeToWithoutSpacing: ->
    @_applyExtent new Point @widthWithoutSpacing(), @_heightForWidth @widthWithoutSpacing()

  initialiseDefaultFrameContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  _setWidthSizeHeightAccordingly: (newWidth) ->
    @_resizeToWithoutSpacing()
    @_applyExtent new Point newWidth, @_heightForWidth newWidth
    @_reLayout()
    @height()  # Path B: hand the resulting height back. See Widget._setWidthSizeHeightAccordingly.

  # §4.1 pure measure (sizing-model unification U3-B): the holder's height follows its
  # width via _heightForWidth (mirrors _setWidthSizeHeightAccordingly above). No mutation,
  # no seam -- gives a parent's measure of this container the real answer even OFF the
  # fixed point (it used to fall back to the base width-invariant measure, correct only
  # at the fixed point).
  preferredExtentForWidth: (availW) ->
    new Point availW, @_heightForWidth availW

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyGrantedBounds newBoundsForThisLayout

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

    # two full-width bands: the icon on top, the (up to two-line) caption below.
    # The icon widget letterboxes its art within its band, so a band wider than
    # the art just centres it.
    height = @height()
    width = @width()
    labelBand = Math.min height, @_labelBandHeight()
    iconBand = height - labelBand

    p0 = @topLeft()
    @icon._applyBounds p0, (new Point width, iconBand).round()
    @label._applyBounds (p0.add new Point 0, iconBand), (new Point width, labelBand).round()

    world.maybeEnableTrackChanges()
    @_fullChanged()

    super
    @_markLayoutAsFixed()

