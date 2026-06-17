# Base for the editor's "content property changer" buttons — the little icon
# buttons in the text-editing toolbar (bold, italic, the alignment trio, font,
# font-size, format-as-code, templates) that act on the LAST widget the user
# clicked or dropped (world.lastNonTextPropertyChangerButtonClickedOrDropped).
#
# They share: the highlightable hover/press colouring + parent-stainer mixins,
# the grey hover/press/normal colour scheme, and the two flags that mark them
# as editor-content changers. A subclass supplies only its icon
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
  editorContentPropertyChangerButton: true

  iconToolTipMessage: nil

  constructor: (@color) ->
    super @color
    @appearance = @createAppearance()
    # set after super (mirrors the family's original constructors); a subclass
    # provides the icon via createAppearance and the text via iconToolTipMessage.
    @toolTipMessage = @iconToolTipMessage
