# Base for the editor's "content property changer" buttons — the little icon
# buttons in the text-editing toolbar (bold, italic, the alignment trio, font,
# font-size, format-as-code, templates) that act on the LAST widget the user
# clicked or dropped (world.editorFocusWdgt).
#
# They share: the highlightable hover/press colouring + parent-stainer mixins,
# the grey hover/press/normal colour scheme, the thumbnail-actionability flag
# and the editor-chrome exclusion below. A subclass supplies only its icon
# (createAppearance), its tooltip (iconToolTipMessage), and its mouseClickLeft.
#
# All of them are icon-shaped, hence the IconWdgt base. (Bold/Italic and the
# Align trio used to extend Widget directly — an inconsistency, since they draw
# through icon appearances exactly like the font/size/code/templates buttons.)

class EditorContentPropertyChangerButtonWdgt extends IconWdgt

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.create 230, 230, 230

  actionableAsThumbnail: true

  # Editor CHROME (Frame-model plan §5.D D2a): pressing me acts ON the editor
  # focus, so the press must neither steal the focus pointer nor end the
  # ongoing edit (the caret reads the selection my action needs). Honored BY
  # ANCESTRY at ActivePointerWdgt's focus-set sites and its caret-survival
  # policy — one capability for both, declared here for buttons standing
  # outside a toolbar (inside one, the toolbar's own declaration covers them).
  excludedFromEditorFocusTracking: ->
    true

  iconToolTipMessage: nil

  constructor: (@color) ->
    super @color
    @appearance = @createAppearance()
    # set after super (mirrors the family's original constructors); a subclass
    # provides the icon via createAppearance and the text via iconToolTipMessage.
    @toolTipMessage = @iconToolTipMessage
