class ChangeFontButtonWdgt extends IconMorph

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.create 230, 230, 230

  simpleDocument: nil

  constructor: (@simpleDocument) ->
    super nil
    @appearance = new ChangeFontIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor

    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @toolTipMessage = "change font"

  mouseClickLeft: ->
    # if there is already a font selection menu for the editor,
    # bring that one up, otherwise create one and remember that we created it
    if @simpleDocument.fontSelectionMenu? and
     !@simpleDocument.fontSelectionMenu.destroyed
      @simpleDocument.fontSelectionMenu.popUp @position().subtract(new Point 80,0), world
    else
      menu = new MenuMorph @, false, @, true, true, "Fonts"
      menu.addMenuItem "Arial", true, @, "setFontName", nil, nil, nil, nil, nil, "justArialFontStack"
      menu.addMenuItem "Times", true, @, "setFontName", nil, nil, nil, nil, nil, "timesFontStack"
      menu.addMenuItem "Georgia", true, @, "setFontName", nil, nil, nil, nil, nil, "georgiaFontStack"
      menu.addMenuItem "Garamo", true, @, "setFontName", nil, nil, nil, nil, nil, "garamoFontStack"
      menu.addMenuItem "Helve", true, @, "setFontName", nil, nil, nil, nil, nil, "helveFontStack"
      menu.addMenuItem "Verda", true, @, "setFontName", nil, nil, nil, nil, nil, "verdaFontStack"
      menu.addMenuItem "Treby", true, @, "setFontName", nil, nil, nil, nil, nil, "trebuFontStack"
      menu.addMenuItem "Heavy", true, @, "setFontName", nil, nil, nil, nil, nil, "heavyFontStack"
      menu.addMenuItem "Mono", true, @, "setFontName", nil, nil, nil, nil, nil, "monoFontStack"

      menu.popUp @position().subtract(new Point 80,0), world

      menu.editorContentPropertyChangerButton = true
      menu.forAllChildrenBottomToTop (eachDescendent) ->
        eachDescendent.editorContentPropertyChangerButton = true

      @simpleDocument.fontSelectionMenu = menu

  setFontName: (ignored1, ignored2, theNewFontName) ->
    if world.lastNonTextPropertyChangerButtonClickedOrDropped?.setFontName?
      widgetClickedLast = world.lastNonTextPropertyChangerButtonClickedOrDropped
      widgetClickedLast.setFontName(nil, ignored2, widgetClickedLast[theNewFontName])



