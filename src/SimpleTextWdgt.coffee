# A multi-line word-wrapping text that is "CONTAINED": it fits its BOX to its
# TEXT (FIT_BOX_TO_TEXT) — it wraps to the width it is laid out at and its height
# follows the wrapped content, which is what "normal" text editing / a text
# document paragraph looks like. (A bare TextWdgt is FIT_TEXT_TO_BOX by default and
# just blurts itself out across the screen; for one-off long text scroll it in a
# SimpleTextScrollPanelWdgt.)
#
# SimpleTextWdgt is a THIN specialization of TextWdgt: its ctor just opts
# into FIT_BOX_TO_TEXT (the contained-text mode) — see TextWdgt::_reLayoutSelf and the
# FITTING MODEL comment in StringWdgt. The contained-reflow engine and the EDIT
# triggers (re-flow the box then invalidate the container so it re-fits, on
# setText/setFontSize/setFontName/toggle*)
# live on the base StringWdgt: its seven text setters self-settle and call the
# non-settling StringWdgt::_reflowContainedTextThenInvalidateLayout core (gated by the mode), so ANY
# TextWdgt (not just this one) can be contained text.
# What's left specific to THIS class is its CONTROLLER chrome: pinning
# _contentStackSpec.canSetHeightFreely = false (height is content-driven), the
# scroll-panel soft-wrap toggle (softWrapOn/Off), the "set target" controller menu +
# the dataflow plumbing (updateTarget + bang), and the panel-colour blend helpers.

class SimpleTextWdgt extends TextWdgt

  @augmentWith ControllerMixin

  # Same head and same opts vocabulary as TextWdgt -> StringWdgt, which does all the assigning
  # (see the note in TextWdgt's constructor for why nothing here is a `@param`).
  #
  # This class states NO defaults of its own, deliberately: the ones it used to declare
  # (12pt, Color.BLACK, "SimpleText") never reached an instance and were removed with this
  # signature. A bare `super` compiles to `.apply(this, arguments)` — the arguments the CALLER
  # passed, not this constructor's defaulted parameters — while `@param` assignment happens
  # BEFORE that call, so the base re-defaulted every omitted slot straight over the top. What
  # a SimpleTextWdgt has always actually got is StringWdgt's normalTextFontSize and
  # Color(37,37,37). Restoring the stated intent is a visible change to every unsized
  # SimpleTextWdgt in the system, so it is a decision, not a cleanup.
  constructor: (text, opts = {}) ->
    super text, opts
    @_commitBounds new Rectangle 0,0,400,40
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

  # On Tab, this widget inserts two spaces instead of letting the target handle Tab
  # (instead of `@target instanceof SimpleTextWdgt` in the caret; type-test-elimination campaign)
  tabInsertsSpaces: ->
    true

  initialiseDefaultFrameContentLayoutSpec: ->
    super
    @_contentStackSpec.canSetHeightFreely = false

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

    @_addTargetConnectionMenuEntries menu

    if @_amIDirectlyInsideScrollPanelWdgt()
      # the caret is a world singleton, compared by identity instead of
      # `!(m instanceof CaretWdgt)` (type-test-elimination campaign)
      childrenNotCarets = @parent.children.filter (m) ->
        m != world.caret
      if childrenNotCarets.length == 1
        menu.addLine()
        if @parent.parent.isTextLineWrapping
          menu.addMenuItem "☒ soft wrap", @, "softWrapOff"
        else
          menu.addMenuItem "☐ soft wrap", @, "softWrapOn"

    menu.removeConsecutiveLines()


  softWrapOn:  -> @setSoftWrap true
  softWrapOff: -> @setSoftWrap false

  # Toggle soft-wrap for a text inside a scroll panel. The directions are deliberately ASYMMETRIC: wrap ON
  # re-constrains the content to the viewport (inside setTextLineWrapping) and lets the layout re-wrap; wrap
  # OFF must _reLayoutSelf the text to its NATURAL un-wrapped width so the panel scrolls horizontally --
  # because TextWdgt::_reLayoutSelf wraps to the current extent when @softWrap, but measures the full
  # natural width when not.
  #
  # This runs synchronously in a click handler with IMMEDIATE layout work (raw resize inside
  # setTextLineWrapping + an explicit _reLayoutSelf) instead of the framework's deferred _invalidateLayout()
  # pattern: the deferred mechanism is half-built (geometry accessors read applied @bounds only), and
  # soft-wrap has an EXTRA blocker -- the content/text are free-floating (undefined layoutSpec) (so _invalidateLayout()
  # never climbs to the scroll panel) and the wrap geometry lives in _positionAndResizeChildren, off the
  # _reLayout cycle. Completing the deferred model stays the goal -- see
  # docs/archive/softwrap-deferred-layout-conversion-plan.md for the obstacle map and what a conversion
  # would take.
  #
  # setSoftWrap SELF-SETTLES (one layout flush per toggle): the public wrapper is JUST the settle and ALL
  # the work -- INCLUDING the already-in-this-state early return -- lives in the NoSettle core, so
  # check-layering rule [H] (early-return-before-settle) sees no guard in the wrapper.
  setSoftWrap: (wrap) ->
    @_settleLayoutsAfter => @_setSoftWrapNoSettle wrap

  _setSoftWrapNoSettle: (wrap) ->
    return if @parent.parent.isTextLineWrapping == wrap   # already in this state -- skip the relayout + repaint
    @softWrap = wrap
    @parent.parent.setTextLineWrapping wrap
    @_reLayoutSelf() unless wrap
    # (property sub-seam deletion) I re-laid MYSELF above; now climb so my tracking container re-fits -- via the
    # parent with me as trigger (NOT @_invalidateLayout, which re-marks me redundantly), the uniform-climb seam replacement.
    @parent?.parent?._invalidateLayout()   # (proper-layouts) re-fit the scroll-panel grandparent; the trigger form @parent._invalidateLayout(@) gets dropped at the non-tracking @contents PanelWdgt, so reach past it (bare)

  # the bang makes the node fire the current output value
  bang: (newvalue) ->
    # a bang is a FORCE-fire (spec §8): mark stale+forced so it propagates despite the equal-value cutoff.
    world.dataflow.markStale @, true
    return

  # The bang pin is declared HERE because `bang` is implemented HERE. Declaring it up on StringWdgt
  # would advertise it for the whole family, including the TextWdgt/StringWdgt that have no `bang` at
  # all and would silently dispatch to nothing. "any": a bang ignores the value it is handed.
  pins: -> super().concat [ new PinSpec "bang!", "any", set: "bang" ]

  # This is also invoked for example when you take a slider and set it to target this. The box re-flow on a
  # text change is the inherited StringWdgt::setText (gated by FIT_BOX_TO_TEXT), reached via super.
  setText: (theTextContent, stringFieldWidget) ->
    super theTextContent, stringFieldWidget
    # No trailing @updateTarget() here: super -> StringWdgt::_setTextNoSettle already fires it (StringWdgt
    # ~:1258). Removed 2026-07-03 (Tier H1).
    return

  # The whole CONTROLLER surface is inherited from StringWdgt -- updateTarget, reactToTargetConnection
  # and the setter tables were all byte-identical overrides here and were dropped 2026-07-15. A
  # plain-text controller drives its target exactly the way a StringWdgt does, so there is nothing to
  # specialise: StringWdgt declares the `text` pin and `producesPinKind: "string"` for the family, and
  # openTargetPropertySelector is now one shared method on Widget. All this class adds is the `bang`
  # pin above, because `bang` is the one controller verb that IS specific to it.

  # setText (above) + the inherited setFontSize / setFontName / toggleShowBlanks /
  # toggleWeight / toggleItalic / toggleIsPassword all re-flow the box AND nudge the
  # container via StringWdgt::_reflowContainedTextThenInvalidateLayout (gated by FIT_BOX_TO_TEXT).
  # softWrapOn/Off (above) are scroll-panel-specific (they flip
  # @parent.parent.isTextLineWrapping).

  blendInWithPanelColor: ->
    if @backgroundColor.equals WorldWdgt.preferencesAndSettings.editableItemBackgroundColor
      @setBackgroundColor Color.create 249, 249, 249

  contrastOutFromPanelColor: ->
    if @backgroundColor.equals Color.create 249, 249, 249
      @setBackgroundColor WorldWdgt.preferencesAndSettings.editableItemBackgroundColor
