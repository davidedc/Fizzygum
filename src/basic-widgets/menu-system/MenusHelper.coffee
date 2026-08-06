# What is left of the menu-action helper after arc 3 split the demo catalogue out into
# DemoMenus: the three actions that SHIP. `binIconAndText` builds the Bin desktop icon
# (WorldWdgt.createDesktop calls it), `popUpDevToolsMenu` is the "dev ➜" menu reachable
# from any widget's context menu on the index page, and `newScriptWindow` opens a script
# frame. Everything demo-shaped lives in DemoMenus (reached as `demoMenus`), which a
# production build does not ship at all.
#
# Keeping actions off the widgets themselves is still the point: a varying number of helper
# methods on a widget is problematic for visual diffing on inspectors.

class MenusHelper

  popUpDevToolsMenu: (widgetOpeningThePopUp, widgetThisMenuIsAbout) ->
    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: "Dev Tools"
    menu.addMenuItem "inspect", widgetThisMenuIsAbout, "inspect", toolTip: "open a window\non all properties"
    menu.addMenuItem "console", widgetThisMenuIsAbout, "createConsole", toolTip: "console"

    menu.popUpAtHand()


  binIconAndText: ->
    binOpener = new BinOpenerWdgt
    # the creator ARMS the opener's corner knob: corner-anchored until the user grabs it
    # (the grab disarms the slot; nothing re-arms it -- the spec-family lifecycle)
    world.add binOpener, nil, binOpener.cornerSpec

  newScriptWindow: ->
    scriptWdgt = new ScriptWdgt
    world.openFrameWith scriptWdgt, (new Point 460, 400), world.hand.position().subtract(new Point 50, 100)
