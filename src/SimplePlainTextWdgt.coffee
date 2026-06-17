# A multi-line word-wrapping text that is "CONTAINED": it fits its BOX to its
# TEXT (FIT_BOX_TO_TEXT) — it wraps to the width it is laid out at and its height
# follows the wrapped content, which is what "normal" text editing / a text
# document paragraph looks like. (A bare TextWdgt is FIT_TEXT_TO_BOX by default and
# just blurts itself out across the screen; for one-off long text scroll it in a
# SimplePlainTextScrollPanelWdgt.)
#
# SimplePlainTextWdgt is now a THIN specialization of TextWdgt: its ctor just opts
# into FIT_BOX_TO_TEXT (the contained-text mode) — see TextWdgt::reLayout and the
# FITTING MODEL comment in StringWdgt. It USED to be a "compatibility layer" that
# hard-coded this behaviour through the dead-TextMorph `maxTextWidth` knob and
# three `instanceof SimplePlainTextWdgt` leaks in the base, with a TODO to do "a
# larger layout rework". That rework is the FIT_BOX_TO_TEXT arc: it retired
# maxTextWidth + the leaks and moved the contained-reflow engine onto the base
# gated by the mode, so ANY TextWdgt (not just this one) can now be contained text.
# A follow-up then moved the EDIT triggers up too: the reLayout +
# refreshScrollPanelWdgtOrVerticalStackIfIamInIt that re-flow the box and nudge the
# container on setText/setFontSize/setFontName/toggle* now live on the base
# (TextWdgt::reLayoutAndRefreshContainerIfContainedText, gated by the mode), so a
# bare FIT_BOX_TO_TEXT TextWdgt re-flows on its OWN setText too and is a full
# drop-in for this class.
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
    # the layout, height from the wrapped content). The sizing now lives on the
    # base TextWdgt::reLayout, driven by this mode; softWrap (true by default on
    # TextWdgt = wrap to the given width) is what used to be @maxTextWidth = true.
    @fittingSpec = FittingSpecText.FIT_BOX_TO_TEXT
    @reLayout()


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

  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
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
      menu.addMenuItem "set target", true, @, "openTargetSelector", "choose another morph\nwhose numerical property\n will be" + " controlled by this one"

    if @amIDirectlyInsideScrollPanelWdgt()
      childrenNotCarets = @parent.children.filter (m) ->
        !(m instanceof CaretWdgt)
      if childrenNotCarets.length == 1
        menu.addLine()
        if @parent.parent.isTextLineWrapping
          menu.addMenuItem "☒ soft wrap", true, @, "softWrapOff"
        else
          menu.addMenuItem "☐ soft wrap", true, @, "softWrapOn"

    menu.removeConsecutiveLines()


  softWrapOn: ->
    @parent.parent.isTextLineWrapping = true
    @softWrap = true

    @parent.fullRawMoveTo @parent.parent.position()
    @parent.rawSetExtent @parent.parent.extent()
    @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  softWrapOff: ->
    @parent.parent.isTextLineWrapping = false
    @softWrap = false

    @reLayout()

    @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

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
  # container via TextWdgt::reLayoutAndRefreshContainerIfContainedText now (gated by
  # FIT_BOX_TO_TEXT), so this class no longer overrides them. softWrapOn/Off (above)
  # stay — they are scroll-panel-specific (they flip @parent.parent.isTextLineWrapping).

  blendInWithPanelColor: ->
    if @backgroundColor.equals WorldWdgt.preferencesAndSettings.editableItemBackgroundColor
      @setBackgroundColor Color.create 249, 249, 249

  contrastOutFromPanelColor: ->
    if @backgroundColor.equals Color.create 249, 249, 249
      @setBackgroundColor WorldWdgt.preferencesAndSettings.editableItemBackgroundColor

  # NOTE: the reLayout that used to live here — the contained-text sizing (wrap to
  # the given width, height = lineCount × fontHeight; or hug the natural width when
  # not wrapping) — now lives on the base TextWdgt::reLayout, gated by
  # fittingSpec == FIT_BOX_TO_TEXT (set in this ctor). It reads @softWrap where it
  # used to read @maxTextWidth. Likewise rawSetExtent (re-layout on a container
  # resize) and the setText/setFontSize/setFontName/toggle* edit triggers (reLayout +
  # refreshScrollPanelWdgtOrVerticalStackIfIamInIt, via
  # TextWdgt::reLayoutAndRefreshContainerIfContainedText) are inherited base overrides.
  # setText is still overridden above, but only for the controller plumbing (the
  # token guard + updateTarget) — it delegates the re-flow to the base via super.
