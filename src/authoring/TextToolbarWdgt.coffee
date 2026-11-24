# The TEXT-editing toolbar -- ONE variant serving every text widget, an ITEM LIST on the shared
# toolbar construction (ToolbarWdgt): its tools act on the style the editor focus hands over (see
# EditorContentPropertyChangerButtonWdgt), so the same list serves the docked home (a Docs frame's
# toolbar-slot) and the floating home (TextToolbarCreatorButtonWdgt) alike.
#
# WHOM IT WORKS FOR decides which focus its tools act on (ToolbarWdgt.hostWindow): docked on a
# window, the focus only while it is in that window's reach -- a paragraph of another document, or
# any text while the bar is docked on a window holding none, is nothing to them; floating, the focus
# wherever it is, a paragraph of a Maker wearing its own bar included.
#
# B, I, </> and the alignment trio each answer whether they are the active tool from that same
# subject (BoldButtonWdgt.isActiveTool and its siblings), and their cells show it
# (GlassBoxBottomWdgt); content in view mode hands them nothing, so none is active there
# (WorldWdgt.editableEditorFocus). Every toolbar hears the same announcements -- the focus moving,
# its style moving, the mode of the content holding it flipping -- through the edges the shared
# construction holds (ToolbarWdgt._subscribeToWhatMyToolsShow), and re-derives its cells on each;
# a docked one shows the focus only while it is in its host's reach.

class TextToolbarWdgt extends ToolbarWdgt

  # text docks TOP (D9). The strip's thickness and its grid insets are the shared toolbar
  # dials (ONE geometry, ruling G1): a text strip is a one-row strip, the theme's toolRows, so its
  # depth derives from the standard grid metrics rather than from a private pair.
  dockSide: 'top'

  _toolbarItems: -> [
    # the font tool: I announce what its Fonts menu's rows show (ChangeFontButtonWdgt._fontsMenuAnnouncer)
    new ChangeFontButtonWdgt
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
