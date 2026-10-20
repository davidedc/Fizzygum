# Base for the editor's "content property changer" buttons — the little icon
# buttons in the text-editing toolbar (bold, italic, the alignment trio, font,
# font-size, format-as-code, templates) that act on the LAST widget the user
# clicked or dropped (world.editorFocusWdgt).
#
# They share: the hover/press state machine (HighlightableMixin), shown on the
# tool cell each stands in rather than on the button (ParentStainerMixin: the
# cell derives its look from the state, GlassBoxBottomWdgt), the
# thumbnail-actionability flag and the editor-chrome exclusion below. A subclass
# supplies only its icon (createAppearance, in the toolbarGlyph ink), its tooltip
# (toolTipMessage), and its activated -- and, when it toggles a state of the text
# it acts on (bold, italic, the mono font, an alignment), whether it is the ACTIVE
# tool: isActiveTool, true while that text has the state, so its cell MIRRORS the
# edited text (re-derived whenever the world announces the focus or its style
# moved, TextToolbarWdgt). A tool with no state (the font, font-size and
# templates buttons) answers nothing and is never active.
#
# All of them are icon-shaped, hence the IconWdgt base: they paint through icon
# appearances, like every other glyph-faced tool. Bold, italic and format-as-code
# TYPE their face (a "B", an "I", a "</>") from the glyph atlases in a theme font
# role (TypedFaceIconAppearance); the others draw theirs.

class EditorContentPropertyChangerButtonWdgt extends IconWdgt

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  actionableAsThumbnail: true

  # Editor CHROME (Frame-model plan §5.D D2a): pressing me acts ON the editor
  # focus, so the press must neither steal the focus pointer nor end the
  # ongoing edit (the caret reads the selection my action needs). Honored BY
  # ANCESTRY at ActivePointerWdgt's focus-set sites and its caret-survival
  # policy — one capability for both, declared here for buttons standing
  # outside a toolbar (inside one, the toolbar's own declaration covers them).
  excludedFromEditorFocusTracking: ->
    true

  constructor: (@color) ->
    super @color
    @appearance = @createAppearance()
