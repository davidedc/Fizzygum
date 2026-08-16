# Opens (or re-focuses) the editor's font-selection menu and applies the chosen
# font to the last-clicked widget.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class ChangeFontButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  # the object the font-selection menu is stashed on, so a re-click re-focuses
  # the open menu instead of stacking a new one -- each home passes its own
  # per-editor object (a toolbar, a document)
  fontSelectionMenuHolder: undefined

  iconToolTipMessage: "change font"

  constructor: (@fontSelectionMenuHolder) ->
    super undefined  # undefined keeps @color = undefined as before; icon line-colour set in createAppearance

  createAppearance: -> new ChangeFontIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  mouseClickLeft: ->
    # if there is already a font selection menu for the editor,
    # bring that one up, otherwise create one and remember that we created it
    if @fontSelectionMenuHolder.fontSelectionMenu? and
     !@fontSelectionMenuHolder.fontSelectionMenu.destroyed
      @fontSelectionMenuHolder.fontSelectionMenu.popUp @position().subtract(new Point 80,0), world
    else
      menu = new MenuWdgt @, target: @, title: "Fonts"
      menu.addMenuItem "Arial", @, "setFontNameFromMenu", arg1: "justArialFontStack"
      menu.addMenuItem "Times", @, "setFontNameFromMenu", arg1: "timesFontStack"
      menu.addMenuItem "Georgia", @, "setFontNameFromMenu", arg1: "georgiaFontStack"
      menu.addMenuItem "Garamo", @, "setFontNameFromMenu", arg1: "garamoFontStack"
      menu.addMenuItem "Helve", @, "setFontNameFromMenu", arg1: "helveFontStack"
      menu.addMenuItem "Verda", @, "setFontNameFromMenu", arg1: "verdaFontStack"
      menu.addMenuItem "Treby", @, "setFontNameFromMenu", arg1: "trebuFontStack"
      menu.addMenuItem "Heavy", @, "setFontNameFromMenu", arg1: "heavyFontStack"
      menu.addMenuItem "Mono", @, "setFontNameFromMenu", arg1: "monoFontStack"

      menu.popUp @position().subtract(new Point 80,0), world

      # editor CHROME: applying a font must act on the focused text without
      # stealing the focus pointer or ending the edit (§5.D D2a). The menu
      # opts in at its ROOT — ancestry covers every item, so the former
      # per-descendant stamping loop is gone.
      menu.actsAsEditorChrome = true

      @fontSelectionMenuHolder.fontSelectionMenu = menu

  # THE MENU ADAPTER (see StringWdgt.setFontNameFromMenu): my items carry the NAME of a
  # font-stack field in arg1, which slot 3 of the dispatcher's fixed convention delivers here.
  setFontNameFromMenu: (ignored1, ignored2, theNewFontName) ->
    if world.editorFocusWdgt?.setFontName?
      widgetClickedLast = world.editorFocusWdgt
      widgetClickedLast.setFontName widgetClickedLast[theNewFontName]
