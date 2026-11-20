# Opens my Fonts menu (or re-focuses it while it is open), whose rows apply the
# chosen font to the last-clicked widget. My verb is setting a font by name: while
# I am handed nothing that sets one, I have nothing to act on, and a press on me
# opens no menu.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.
#
# I KEEP NOTHING ABOUT MY MENU: which menu is mine is found at the press (the open
# Fonts menu I opened, _myOpenFontsMenu), the font its rows tick is read off me
# (currentFontName) and who announces a move of either is picked as the menu is
# built (_fontsMenuAnnouncer). So a copy of me -- my own "Duplicate", or a copy of
# the window I stand in -- is a tool of its own and opens a menu of its own.

class ChangeFontButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  # MY FONTS MENU'S TITLE, which _newFontsMenu gives it and _myOpenFontsMenu finds it by: the title is
  # what tells my own Fonts menu from the other pop-ups I open (the prompts and the hierarchy menu my
  # context gesture opens name me as their opener too)
  @FONTS_MENU_TITLE: "Fonts"

  toolTipMessage: "change font"

  # a font set by name: what my menu's rows apply
  verb: "setFontName"

  createAppearance: -> new ChangeFontIconAppearance @

  # the font of what I am handed (_styleSubject: the edited text within the window my toolbar works
  # for; the person's focus wherever it is while I stand in no toolbar or my toolbar floats), undefined
  # while I am handed nothing: what my menu's rows read to decide which is ticked
  # (MenuRowReflectionSpec.readerName), as a text's own fonts menu reads StringWdgt.currentFontName
  currentFontName: ->
    @_styleSubject()?.fontName

  # the menu is a WORLD child, so it opens at my on-SCREEN position — my own @position()
  # is plane-local and lands offset-pixels away when I sit in a scrolled pane (or inside an
  # island); mapped + rounded because the screen family can be fractional under tilt and
  # popUp commits integer bounds (same shape as ToolTipWdgt's bubble).
  _menuPopUpPoint: ->
    (@localPointToScreen @position()).round().subtract new Point 80, 0

  # My act is the MENU, not the font: a row of it applies its font to whatever subject I am handed
  # when the row is chosen (setFontNameFromMenu), so the subject a press found is not kept. A press
  # brings up my open Fonts menu, pinned or not, at me, rather than stacking a second one; with none
  # open it opens a fresh one.
  actOn: (ignoredSubject) ->
    (@_myOpenFontsMenu() ? @_newFontsMenu()).popUp @_menuPopUpPoint(), world

  # MY OPEN FONTS MENU, asked at every press of the set of open pop-ups (world.openPopUps: transient
  # and pinned alike; a close or a destroy takes a pop-up out of it): the one with my Fonts menu's title
  # (FONTS_MENU_TITLE) whose opener is me (widgetOpeningThePopUp) and that still stands in the world or
  # on the hand (isOrphan, as the world's own sweep reads "open"). undefined when there is none: a copy
  # of me opened nothing, and a pinned menu closed to the bin is not open, so a press opens a fresh one.
  # A copy of a pinned Fonts menu never joins the set (FrameWdgt.fullCopy), so a press never brings it up.
  _myOpenFontsMenu: ->
    title = ChangeFontButtonWdgt.FONTS_MENU_TITLE
    for each from world.openPopUps
      return each if each.widgetOpeningThePopUp is @ and each.title is title and not each.destroyed and not each.isOrphan()
    undefined

  # A FRESH FONTS MENU, opened by me (its widgetOpeningThePopUp, what _myOpenFontsMenu finds it by) and
  # targeting me: the fonts every fonts menu offers (StringWdgt.fontStackMenuEntries), each row ticked
  # while it is the font of what I am handed (currentFontName) -- a VIEW, so the tick follows a new
  # selection and a new font, in this menu and in any pinned copy -- and enabled while I have something
  # to act on, which is what my cell dims by and a press on me refuses by. Both are re-read whenever
  # the announcer _fontsMenuAnnouncer picks (the toolbar I stand in, else the world) announces, so a
  # pinned copy greys with me.
  _newFontsMenu: ->
    announcer = @_fontsMenuAnnouncer()
    menu = new MenuWdgt @, target: @, title: ChangeFontButtonWdgt.FONTS_MENU_TITLE
    enabled = MenuRowReflectionSpec.enabledWhile @, "hasSomethingToActOn", true, announcedBy: announcer
    for [ fontStack, menuLabel ] in StringWdgt.fontStackMenuEntries()
      menu.addMenuItem menuLabel, @, "setFontNameFromMenu",
        arg1: fontStack
        reflection: MenuRowReflectionSpec.tickWhen @, "currentFontName", fontStack, menuLabel, announcedBy: announcer
        enablement: enabled
    menu

  # WHO ANNOUNCES what my menu's rows show: I only PICK it here, and the one picked announces (I
  # announce nothing myself). The toolbar I stand in (ToolbarWdgt.toolbarOf), which passes on every
  # move of the focus, its style or the mode holding it, and also announces when it docks or leaves,
  # which changes whom I work for (ToolbarWdgt.noteToolStatesChanged); standing in no toolbar, the
  # world, which announces those moves itself. Picked as each menu is built, from where I stand then.
  _fontsMenuAnnouncer: ->
    ToolbarWdgt.toolbarOf(@) ? world

  # THE MENU ADAPTER (see StringWdgt.setFontNameFromMenu): my items carry the font stack in arg1,
  # which slot 3 of the dispatcher's fixed convention delivers here. A row refuses its press first,
  # while I have nothing to act on (its enablement); the style door's `?` stays the defence for an
  # action delivered by other means.
  setFontNameFromMenu: (ignored1, ignored2, theFontStack) ->
    @_styleSubject()?.setFontName? theFontStack
