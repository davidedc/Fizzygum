# Opens (or re-focuses) the editor's font-selection menu and applies the chosen
# font to the last-clicked widget.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class ChangeFontButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  # the object the font-selection menu is stashed on, so a re-click re-focuses
  # the open menu instead of stacking a new one -- each home passes its own
  # per-editor object (a toolbar, a document)
  fontSelectionMenuHolder: nil

  iconToolTipMessage: "change font"

  constructor: (@fontSelectionMenuHolder) ->
    super nil  # nil keeps @color = nil as before; icon line-colour set in createAppearance

  createAppearance: -> new ChangeFontIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  mouseClickLeft: ->
    # if there is already a font selection menu for the editor,
    # bring that one up, otherwise create one and remember that we created it
    if @fontSelectionMenuHolder.fontSelectionMenu? and
     !@fontSelectionMenuHolder.fontSelectionMenu.destroyed
      @fontSelectionMenuHolder.fontSelectionMenu.popUp @position().subtract(new Point 80,0), world
    else
      menu = new MenuWdgt @, target: @, title: "Fonts"
      menu.addMenuItem "Arial", @, "setFontName", arg1: "justArialFontStack"
      menu.addMenuItem "Times", @, "setFontName", arg1: "timesFontStack"
      menu.addMenuItem "Georgia", @, "setFontName", arg1: "georgiaFontStack"
      menu.addMenuItem "Garamo", @, "setFontName", arg1: "garamoFontStack"
      menu.addMenuItem "Helve", @, "setFontName", arg1: "helveFontStack"
      menu.addMenuItem "Verda", @, "setFontName", arg1: "verdaFontStack"
      menu.addMenuItem "Treby", @, "setFontName", arg1: "trebuFontStack"
      menu.addMenuItem "Heavy", @, "setFontName", arg1: "heavyFontStack"
      menu.addMenuItem "Mono", @, "setFontName", arg1: "monoFontStack"

      menu.popUp @position().subtract(new Point 80,0), world

      menu.editorContentPropertyChangerButton = true
      menu.forAllChildrenBottomToTop (eachDescendent) ->
        eachDescendent.editorContentPropertyChangerButton = true

      @fontSelectionMenuHolder.fontSelectionMenu = menu

  setFontName: (ignored1, ignored2, theNewFontName) ->
    if world.lastNonTextPropertyChangerButtonClickedOrDropped?.setFontName?
      widgetClickedLast = world.lastNonTextPropertyChangerButtonClickedOrDropped
      widgetClickedLast.setFontName(nil, ignored2, widgetClickedLast[theNewFontName])
