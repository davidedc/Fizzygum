# The TEXT-editing toolbar -- ONE variant serving every text widget: its
# buttons act on the focused widget (see EditorContentPropertyChangerButtonWdgt),
# so the same list serves the docked home (a Docs frame's toolbar-slot) and the
# floating home (TextToolbarCreatorButtonWdgt) alike.
#
# I MIRROR THE EDITED TEXT: B, I, </> and the alignment trio each answer whether they are the active
# tool from the widget being edited (world.editorFocusWdgt; BoldButtonWdgt.isActiveTool and its
# siblings), and their cells show it (GlassBoxBottomWdgt). The world ANNOUNCES whenever that focus
# moves or its style does (WorldWdgt._setEditorFocusNoSettle / noteStyleChanged), and I hear it
# through ONE dataflow edge world -> me -- so every text toolbar in the world (a docked Docs Maker
# band, a floating one, a copy) follows the same focus with no list of toolbars anywhere: the
# engine's edge index is the set, and Widget._destroyNoSettle takes me out of it as I die.
# firesOnAnyChange because the focus is not the world's VALUE (the announcement is a
# markNonValueChange); I never read what is delivered, my tools re-read the focus. The drain runs in
# the cycle's dataflow station, ahead of layout and paint, so what my cells show is a function of
# the event stream.

class TextToolbarWdgt extends ToolbarWdgt

  # text docks TOP (D9). The strip's thickness and its grid insets are the shared toolbar
  # dials (ONE geometry, ruling G1): a text strip is a one-row strip like every other, so its
  # depth derives from the standard grid metrics rather than from a private pair.
  dockSide: 'top'

  # the edge world -> me (see the header), made with my tools; neither a deserialized shell nor a
  # duplicate runs a constructor, so each makes it again here (PaintToolbarWdgt's precedent)
  _buildAndConnectChildrenNoSettle: ->
    super
    @_followTheEditedText()

  _afterDeserialization: ->
    @_followTheEditedText()

  _reactToBeingCopied: ->
    @_followTheEditedText()

  # Subscribe to the world's editor focus (once: the index already knows whether I am) and show the
  # focus as it stands, so a toolbar built, loaded or copied while a bold text is being edited shows
  # B active from the start.
  _followTheEditedText: ->
    if world?.dataflow? and !world.dataflow.hasEdge world, @
      world.dataflow.addEdge world, @, action: "mirrorTheEditedText", firesOnAnyChange: true
    @mirrorTheEditedText()
    return

  # The focus or its style moved: every one of my cells re-derives its look, asking its tool (a tool
  # with no state to mirror answers nothing and stays at rest). The hidden cells too, so a cell my
  # strip shows later shows the focus as it is then.
  mirrorTheEditedText: ->
    for cell in @contents.childrenNotHandlesNorCarets()
      cell.noteItemStateChanged?()
    return

  _toolbarItems: -> [
    # the toolbar itself is the font-menu stash home (re-clicking re-focuses
    # the open menu instead of stacking a new one)
    new ChangeFontButtonWdgt @
    new BoldButtonWdgt
    new ItalicButtonWdgt
    new FormatAsCodeButtonWdgt
    new IncreaseFontSizeButtonWdgt
    new DecreaseFontSizeButtonWdgt

    new AlignLeftButtonWdgt
    new AlignCenterButtonWdgt
    new AlignRightButtonWdgt

    new TemplatesButtonWdgt
  ]
