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
# What's left specific to THIS class is its chrome: pinning
# layoutSpecDetails.canSetHeightFreely = false (height is content-driven), the
# scroll-panel soft-wrap toggle (softWrapOn/Off), the "set target" controller menu,
# and the reLayout + refreshScrollPanelWdgtOrVerticalStackIfIamInIt triggers on
# setText/setFontSize/toggle* (so an EDIT re-flows it AND nudges the container — a
# bare TextWdgt re-flows on a container RESIZE but not yet on its own setText, so
# use this class when the text content itself changes).

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
    menu = new MenuMorph @, false, @, true, true, "choose target property:"
    for i in [0...menuEntriesStrings.length]
      menu.addMenuItem menuEntriesStrings[i], true, @, "setTargetAndActionWithOnesPickedFromMenu", nil, nil, nil, nil, nil, theTarget, functionNamesStrings[i]
    if menuEntriesStrings.length == 0
      menu = new MenuMorph @, false, @, true, true, "no target properties available"
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
        !(m instanceof CaretMorph)
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

  # This is also invoked for example when you take a slider
  # and set it to target this.
  setText: (theTextContent, stringFieldMorph, connectionsCalculationToken, superCall) ->
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken
    super theTextContent, stringFieldMorph, connectionsCalculationToken, true
    @reLayout()
    @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()
    @updateTarget()

  updateTarget: ->
    if @action and @action != ""
      @target[@action].call @target, @text, nil, @connectionsCalculationToken
    return

  reactToTargetConnection: ->
    @updateTarget()

  toggleShowBlanks: ->
    super
    @reLayout()
    @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()
  
  toggleWeight: ->
    super
    @reLayout()
    @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()
  
  toggleItalic: ->
    super
    @reLayout()
    @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  toggleIsPassword: ->
    super
    @reLayout()
    @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  setFontSize: (sizeOrMorphGivingSize, morphGivingSize) ->
    super
    @reLayout()
    @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  setFontName: (ignored1, ignored2, theNewFontName) ->
    super
    @reLayout()
    @refreshScrollPanelWdgtOrVerticalStackIfIamInIt()

  blendInWithPanelColor: ->
    if @backgroundColor.equals WorldMorph.preferencesAndSettings.editableItemBackgroundColor
      @setBackgroundColor Color.create 249, 249, 249

  contrastOutFromPanelColor: ->
    if @backgroundColor.equals Color.create 249, 249, 249
      @setBackgroundColor WorldMorph.preferencesAndSettings.editableItemBackgroundColor

  # NOTE: the reLayout that used to live here — the contained-text sizing (wrap to
  # the given width, height = lineCount × fontHeight; or hug the natural width when
  # not wrapping) — now lives on the base TextWdgt::reLayout, gated by
  # fittingSpec == FIT_BOX_TO_TEXT (set in this ctor). It reads @softWrap where it
  # used to read @maxTextWidth. Likewise rawSetExtent (re-layout on a container
  # resize) is the inherited base override. So this class no longer needs either.
