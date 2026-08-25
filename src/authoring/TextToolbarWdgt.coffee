# The TEXT-editing toolbar -- ONE variant serving every text widget: its
# buttons act on the focused widget (see EditorContentPropertyChangerButtonWdgt),
# so the same list serves the docked home (a Docs frame's toolbar-slot) and the
# floating home (TextToolbarCreatorButtonWdgt) alike.

class TextToolbarWdgt extends ToolbarWdgt

  # text docks TOP (D9). The strip's thickness and its grid insets are the shared toolbar
  # dials (ONE geometry, ruling G1): a text strip is a one-row strip like every other, so its
  # depth derives from the standard grid metrics rather than from a private pair.
  dockSide: 'top'

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
