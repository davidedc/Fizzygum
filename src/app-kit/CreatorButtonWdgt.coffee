class CreatorButtonWdgt extends CreatorWdgt

  actionableAsThumbnail: true

  # MY FACE IS A PICTURE that fills its box, so the tool cell I stand in -- whose whole square is my
  # target -- names the side it is drawn at (GlassBoxBottomWdgt._reLayoutSelf, the mark box). A
  # creator whose face is a glyph drawn for the whole cell carries its own white space and says false.
  drawsFaceInToolMarkBox: true

  # THE SIDE MY PICTURE IS DRAWN AT inside my box, read by my icon appearance
  # (IconAppearance.calculateRectangleOfIcon, SizeAwareIconAppearance): the tool cell I stand in
  # writes it as it seats me, my box staying the cell's whole target; unset, my picture fills my box.
  glyphSize: undefined

  # Editor CHROME (Frame-model plan §5.D D2a): a creator button acts on the
  # editor focus (smart-place into the focused content), so its press must not
  # steal the focus pointer nor end the ongoing edit. Ancestry-honored at
  # ActivePointerWdgt's focus-set sites + caret-survival policy — the one
  # capability, for a creator standing outside a toolbar.
  excludedFromEditorFocusTracking: ->
    true

  # subclasses supply createAppearance (the icon, in the toolbarGlyph ink) + toolTipMessage
  # (hover text, declared on Widget); the appearance is set here after super, as the original
  # ctors did.
  constructor: ->
    super
    @appearance = @createAppearance()

  grabbedWidgetSwitcheroo: ->
    return @_createWidgetToBeHandled()

  # otherwise the glassbox bottom will answer on drags
  # and will just pick up the button and move it,
  # while we want the drag to create a textbox
  grabsToParentWhenDragged: ->
    false

