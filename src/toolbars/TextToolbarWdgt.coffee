# The TEXT-editing toolbar -- ONE variant serving every text widget: its
# buttons act on the focused widget (see EditorContentPropertyChangerButtonWdgt),
# so the same list serves the docked home (a Docs frame's toolbar-slot) and the
# floating home (TextToolbarCreatorButtonWdgt) alike.

class TextToolbarWdgt extends ToolbarWdgt

  # text docks TOP (D9): a one-row 30px-thumbnail strip
  dockSide: 'top'
  dockThickness: 40

  constructor: ->
    super
    # a one-row strip is 40px at 5px insets -- tighten the grid's 10px default
    # so the docked strip and the floating grid share one geometry. Safe after
    # super: the toolbar is an orphan here, every settle defers, so this lands
    # before the first arrange (on attach).
    @contents.externalPadding = 5

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
