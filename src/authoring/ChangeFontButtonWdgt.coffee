# Opens (or re-focuses) the editor's font-selection menu and applies the chosen
# font to the last-clicked widget. My verb is setting a font by name: while I am
# handed nothing that sets one, I have nothing to act on, and a press on me
# opens no menu.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class ChangeFontButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  # the toolbar I stand in, which holds my font-selection menu — so a re-click re-focuses the open
  # menu instead of stacking a new one — and which the menu's rows show the font of: it MIRRORS THE
  # EDITED TEXT (TextToolbarWdgt.currentFontName), and announces whenever that text, or its style, moves
  fontSelectionMenuHolder: undefined

  toolTipMessage: "change font"

  # a font set by name: what my menu's rows apply
  verb: "setFontName"

  constructor: (@fontSelectionMenuHolder) ->
    super undefined  # no colour passed: my glyph's ink is read as I paint (the family's _fillForMyState)

  createAppearance: -> new ChangeFontIconAppearance @

  # the menu is a WORLD child, so it opens at my on-SCREEN position — my own @position()
  # is plane-local and lands offset-pixels away when I sit in a scrolled pane (or inside an
  # island); mapped + rounded because the screen family can be fractional under tilt and
  # popUp commits integer bounds (same shape as ToolTipWdgt's bubble).
  _menuPopUpPoint: ->
    (@localPointToScreen @position()).round().subtract new Point 80, 0

  # My act is the MENU, not the font: a row of it applies its font to whatever subject I am handed
  # when the row is chosen (setFontNameFromMenu), so the subject a press found is not kept.
  actOn: (ignoredSubject) ->
    # if there is already a font selection menu for the editor,
    # bring that one up, otherwise create one and remember that we created it
    if @fontSelectionMenuHolder.fontSelectionMenu? and
     !@fontSelectionMenuHolder.fontSelectionMenu.destroyed
      @fontSelectionMenuHolder.fontSelectionMenu.popUp @_menuPopUpPoint(), world
    else
      # the fonts every fonts menu offers (StringWdgt.fontStackMenuEntries), each row ticked while
      # it is the edited text's font — a VIEW of my toolbar's mirror, so the tick follows a new
      # selection and a new font, in this menu and in any pinned copy — and enabled while I have
      # something to act on, which is what my cell dims by and a press on me refuses by: my toolbar
      # announces whenever that may have moved (ToolbarWdgt.noteToolStatesChanged), so a pinned
      # copy greys with me
      menu = new MenuWdgt @, target: @, title: "Fonts"
      enabled = MenuRowReflectionSpec.enabledWhile @, "hasSomethingToActOn", true, announcedBy: @fontSelectionMenuHolder
      for [ fontStack, menuLabel ] in StringWdgt.fontStackMenuEntries()
        menu.addMenuItem menuLabel, @, "setFontNameFromMenu",
          arg1: fontStack
          reflection: MenuRowReflectionSpec.tickWhen @fontSelectionMenuHolder, "currentFontName", fontStack, menuLabel
          enablement: enabled

      menu.popUp @_menuPopUpPoint(), world

      @fontSelectionMenuHolder.fontSelectionMenu = menu

  # THE MENU ADAPTER (see StringWdgt.setFontNameFromMenu): my items carry the font stack in arg1,
  # which slot 3 of the dispatcher's fixed convention delivers here. A row refuses its press first,
  # while I have nothing to act on (its enablement); the style door's `?` stays the defence for an
  # action delivered by other means.
  setFontNameFromMenu: (ignored1, ignored2, theFontStack) ->
    @_styleSubject()?.setFontName? theFontStack
