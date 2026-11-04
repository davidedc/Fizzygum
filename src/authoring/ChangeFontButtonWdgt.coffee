# Opens (or re-focuses) the editor's font-selection menu and applies the chosen
# font to the last-clicked widget.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class ChangeFontButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  # the toolbar I stand in, which holds my font-selection menu — so a re-click re-focuses the open
  # menu instead of stacking a new one — and which the menu's rows show the font of: it MIRRORS THE
  # EDITED TEXT (TextToolbarWdgt.currentFontName), and announces whenever that text, or its style, moves
  fontSelectionMenuHolder: undefined

  toolTipMessage: "change font"

  constructor: (@fontSelectionMenuHolder) ->
    super undefined  # undefined keeps @color = undefined as before; icon line-colour set in createAppearance

  createAppearance: -> new ChangeFontIconAppearance @, WorldWdgt.theme.toolbarGlyph

  # the menu is a WORLD child, so it opens at my on-SCREEN position — my own @position()
  # is plane-local and lands offset-pixels away when I sit in a scrolled pane (or inside an
  # island); mapped + rounded because the screen family can be fractional under tilt and
  # popUp commits integer bounds (same shape as ToolTipWdgt's bubble).
  _menuPopUpPoint: ->
    (@localPointToScreen @position()).round().subtract new Point 80, 0

  activated: ->
    # if there is already a font selection menu for the editor,
    # bring that one up, otherwise create one and remember that we created it
    if @fontSelectionMenuHolder.fontSelectionMenu? and
     !@fontSelectionMenuHolder.fontSelectionMenu.destroyed
      @fontSelectionMenuHolder.fontSelectionMenu.popUp @_menuPopUpPoint(), world
    else
      # the fonts every fonts menu offers (StringWdgt.fontStackMenuEntries), each row ticked while
      # it is the edited text's font — a VIEW of my toolbar's mirror, so the tick follows a new
      # selection and a new font, in this menu and in any pinned copy
      menu = new MenuWdgt @, target: @, title: "Fonts"
      for [ fontStack, menuLabel ] in StringWdgt.fontStackMenuEntries()
        menu.addMenuItem menuLabel, @, "setFontNameFromMenu",
          arg1: fontStack
          reflection: MenuRowReflectionSpec.tickWhen @fontSelectionMenuHolder, "currentFontName", fontStack, menuLabel

      menu.popUp @_menuPopUpPoint(), world

      # editor CHROME: applying a font must act on the focused text without
      # stealing the focus pointer or ending the edit (§5.D D2a). The menu
      # opts in at its ROOT — ancestry covers every item, so the former
      # per-descendant stamping loop is gone.
      menu.actsAsEditorChrome = true

      @fontSelectionMenuHolder.fontSelectionMenu = menu

  # THE MENU ADAPTER (see StringWdgt.setFontNameFromMenu): my items carry the font stack in arg1,
  # which slot 3 of the dispatcher's fixed convention delivers here.
  setFontNameFromMenu: (ignored1, ignored2, theFontStack) ->
    @_styleSubject()?.setFontName? theFontStack
