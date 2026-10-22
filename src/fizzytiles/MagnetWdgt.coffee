# A draggable "fridge magnet" tile: a labeled button (LabelButtonWdgt) that
# is draggable (rejectDrags=false) rather than a menu row. The generic
# label-button machinery it relies on (label, centring) lives in
# LabelButtonWdgt -- the base's single-line StringWdgt _createLabel is exactly
# what a magnet wants (a self-sized label, no box resize).
#
# MY LOOK is the design's button (visual-design-system §4.3, "a bordered rounded rectangle means
# press me"), a pure function of my STATE (HighlightableMixin's, set by LabelButtonWdgt's
# transitions) and the theme, read as I am painted (MagnetAppearance, through _fillForMyState /
# _strokeForMyState): magnetFill inside a 1 px magnetStroke border at rest, magnetHoverFill hovered,
# magnetPressFill inside magnetPressStroke pressed, rounded at magnetCornerRadius. My label is a
# code token, built in fonts.code and magnetText (_labelTextOptions). I hold no colour or font of
# my own -- my builder gives LabelButtonWdgt none -- so a saved, loaded or duplicated magnet wears
# the look of the world it is shown in. My box is Widget's default 50 x 40, my label centred in it.

class MagnetWdgt extends LabelButtonWdgt

  putIntoWords: false
  isTemplate: true

  # A magnet has a target and no action — it is dragged, not triggered — so `target` is the
  # whole head. (A bare `super` would forward `arguments` verbatim into LabelButtonWdgt's
  # (target, action, opts), which is exactly how a signature change mis-binds a field in
  # silence: the call must be explicit.)
  constructor: (target) ->
    super target, undefined
    @defaultRejectDrags = false

  createAppearance: -> new MagnetAppearance @

  # my label, a code token: the code role's font, in my label's ink, read from the theme whenever
  # my label is built
  _labelTextOptions: ->
    theme = WorldWdgt.theme
    fontRole: theme.fonts.code
    color: theme.magnetText

  # my box's fill and border for the state I am in now, which my appearance reads as it paints
  _fillForMyState: ->
    theme = WorldWdgt.theme
    switch @state
      when @STATE_PRESSED then theme.magnetPressFill
      when @STATE_HIGHLIGHTED then theme.magnetHoverFill
      else theme.magnetFill

  _strokeForMyState: ->
    theme = WorldWdgt.theme
    if @state is @STATE_PRESSED then theme.magnetPressStroke else theme.magnetStroke

  rightCenter: ->
    new Point(@right(),@height()/2)

  leftCenter: ->
    new Point(@left(),@height()/2)
