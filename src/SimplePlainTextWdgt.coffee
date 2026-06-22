# A multi-line word-wrapping text that is "CONTAINED": it fits its BOX to its
# TEXT (FIT_BOX_TO_TEXT) — it wraps to the width it is laid out at and its height
# follows the wrapped content, which is what "normal" text editing / a text
# document paragraph looks like. (A bare TextWdgt is FIT_TEXT_TO_BOX by default and
# just blurts itself out across the screen; for one-off long text scroll it in a
# SimplePlainTextScrollPanelWdgt.)
#
# SimplePlainTextWdgt is a THIN specialization of TextWdgt: its ctor just opts
# into FIT_BOX_TO_TEXT (the contained-text mode) — see TextWdgt::_reLayoutSelf and the
# FITTING MODEL comment in StringWdgt. The contained-reflow engine and the EDIT
# triggers (the _reLayoutSelf + _refreshScrollPanelWdgtOrVerticalStackIfIamInIt that
# re-flow the box and nudge the container on setText/setFontSize/setFontName/toggle*)
# live on the base (TextWdgt::reLayoutAndRefreshContainerIfContainedText, gated by
# the mode), so ANY TextWdgt (not just this one) can be contained text.
# What's left specific to THIS class is its CONTROLLER chrome: pinning
# layoutSpecDetails.canSetHeightFreely = false (height is content-driven), the
# scroll-panel soft-wrap toggle (softWrapOn/Off), the "set target" controller menu +
# the dataflow plumbing (setText's connectionsCalculationToken guard + updateTarget,
# bang), and the panel-colour blend helpers.

class SimplePlainTextWdgt extends TextWdgt

  @augmentWith ControllerMixin

  constructor: (
   @text = "SimplePlainText",
   @originallySetFontSize = 12,
   @fontName = @justArialFontStack,
   @isBold = false,
   @isItalic = false,
   #@isNumeric = false,
   @color = Color.BLACK,
   @backgroundColor = nil,
   @backgroundTransparency = nil
   ) ->

    super
    @silentRawSetBounds new Rectangle 0,0,400,40
    @fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.FLOAT
    @fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN
    # this widget IS the contained-text case: fit the BOX to the TEXT (width from
    # the layout, height from the wrapped content). The sizing lives on the
    # base TextWdgt::_reLayoutSelf, driven by this mode; softWrap (true by default on
    # TextWdgt) wraps to the given width.
    @fittingSpec = FittingSpecText.FIT_BOX_TO_TEXT
    @_reLayoutSelf()


  colloquialName: ->
    "text"

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    [menuEntriesStrings, functionNamesStrings] = theTarget.stringSetters()
    menu = new MenuWdgt @, false, @, true, true, "choose target property:"
    for i in [0...menuEntriesStrings.length]
      menu.addMenuItem menuEntriesStrings[i], true, @, "setTargetAndActionWithOnesPickedFromMenu", nil, nil, nil, nil, nil, theTarget, functionNamesStrings[i]
    if menuEntriesStrings.length == 0
      menu = new MenuWdgt @, false, @, true, true, "no target properties available"
    menu.popUpAtHand()

  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!", "text"
    functionNamesStrings.push "bang", "setText"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.removeMenuItem "soft wrap"
    menu.removeMenuItem "soft wrap".tick()
    menu.removeMenuItem "soft wrap"

    menu.removeMenuItem "←☓→ don't expand to fill"
    menu.removeMenuItem "←→ expand to fill"
    menu.removeMenuItem "→← shrink to fit"
    menu.removeMenuItem "→⋯← crop to fit"

    menu.removeMenuItem "header line"
    menu.removeMenuItem "no header line"

    menu.removeMenuItem "↑ align top"
    menu.removeMenuItem "⍿ align middle"
    menu.removeMenuItem "↓ align bottom"

    menu.addLine()
    if world.isIndexPage
      menu.addMenuItem "connect to ➜", true, @, "openTargetSelector", "connect to\nanother widget"
    else
      menu.addMenuItem "set target", true, @, "openTargetSelector", "choose another widget\nwhose numerical property\n will be" + " controlled by this one"

    if @_amIDirectlyInsideScrollPanelWdgt()
      childrenNotCarets = @parent.children.filter (m) ->
        !(m instanceof CaretWdgt)
      if childrenNotCarets.length == 1
        menu.addLine()
        if @parent.parent.isTextLineWrapping
          menu.addMenuItem "☒ soft wrap", true, @, "softWrapOff"
        else
          menu.addMenuItem "☐ soft wrap", true, @, "softWrapOn"

    menu.removeConsecutiveLines()


  softWrapOn:  -> @setSoftWrap true
  softWrapOff: -> @setSoftWrap false

  # Toggle soft-wrap for a text inside a scroll panel. The directions are
  # deliberately ASYMMETRIC: wrap ON re-constrains the content to the viewport
  # (inside setTextLineWrapping) and lets the layout re-wrap; wrap OFF must
  # _reLayoutSelf the text to its NATURAL un-wrapped width so the panel scrolls
  # horizontally -- because TextWdgt::_reLayoutSelf wraps to the current extent when
  # @softWrap, but measures the full natural width when not.
  #
  # This runs synchronously in a click handler and does IMMEDIATE layout work (the
  # raw resize inside setTextLineWrapping + an explicit _reLayoutSelf) rather than the
  # framework's deferred invalidateLayout() pattern. This is INTERMEDIATE state, not
  # an oversight: the deferred mechanism is half-built by construction (the geometry
  # accessors read applied @bounds only, so handler-level raw geometry is a symptom of
  # that incompleteness). Soft-wrap also has an EXTRA blocker: the content/text are
  # ATTACHEDAS_FREEFLOATING (so invalidateLayout() never climbs to the scroll panel)
  # and the wrap geometry lives in _positionAndResizeChildren, off the _reLayout cycle.
  # Completing the deferred model stays the goal -- see
  # docs/softwrap-deferred-layout-conversion-plan.md for the model finding, the
  # obstacle map, and what a conversion would take.
  setSoftWrap: (wrap) ->
    return if @parent.parent.isTextLineWrapping == wrap   # already in this state -- skip the relayout + repaint
    @softWrap = wrap
    @parent.parent.setTextLineWrapping wrap
    @_reLayoutSelf() unless wrap
    @_refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  # the bang makes the node fire the current output value
  bang: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken
    @updateTarget()

  # This is also invoked for example when you take a slider and set it to target
  # this. Only the controller plumbing (the connectionsCalculationToken guard +
  # updateTarget) is SPTW-specific now; the box re-flow on a text change is the
  # inherited TextWdgt::setText (gated by FIT_BOX_TO_TEXT), reached via super.
  setText: (theTextContent, stringFieldWidget, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken
    super theTextContent, stringFieldWidget, connectionsCalculationToken, true
    @updateTarget()

  updateTarget: ->
    if @action and @action != ""
      @target[@action].call @target, @text, nil, @connectionsCalculationToken
    return

  reactToTargetConnection: ->
    @updateTarget()

  # setText (above) + the inherited setFontSize / setFontName / toggleShowBlanks /
  # toggleWeight / toggleItalic / toggleIsPassword all re-flow the box AND nudge the
  # container via TextWdgt::reLayoutAndRefreshContainerIfContainedText (gated by
  # FIT_BOX_TO_TEXT). softWrapOn/Off (above) are scroll-panel-specific (they flip
  # @parent.parent.isTextLineWrapping).

  blendInWithPanelColor: ->
    if @backgroundColor.equals WorldWdgt.preferencesAndSettings.editableItemBackgroundColor
      @setBackgroundColor Color.create 249, 249, 249

  contrastOutFromPanelColor: ->
    if @backgroundColor.equals Color.create 249, 249, 249
      @setBackgroundColor WorldWdgt.preferencesAndSettings.editableItemBackgroundColor
