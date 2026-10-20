class CreatorButtonWdgt extends Widget

  # my hover / press state shows on the tool cell I stand in, never on me (ParentStainerMixin)
  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name
  @augmentWith WidgetCreatorAndSmartPlacerOnClickMixin, @name

  actionableAsThumbnail: true

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
    return @createWidgetToBeHandled()

  # otherwise the glassbox bottom will answer on drags
  # and will just pick up the button and move it,
  # while we want the drag to create a textbox
  grabsToParentWhenDragged: ->
    false

