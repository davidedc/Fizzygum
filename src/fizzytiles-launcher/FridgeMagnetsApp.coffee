# FridgeMagnetsApp -- the fridge-magnets ("Fizzytiles") launcher app: opens a
# fresh fridge-magnets window at the hand on each launch (same window shape as
# DemoMenus.createFridgeMagnets, which stays as the menu path to the same
# widget). An IconicDesktopSystemWindowedApp; like the whole fizzytiles family
# this ships only in the full build, so its desktop-launcher creation in
# WorldWdgt.createDesktop is homepage-excluded too. The launcher caption is a
# single-line StringWdgt that truncates past ~13 chars, so the title is the
# widget's own colloquial name ("Fizzytiles", also the window-bar title) and
# the tooltip carries the descriptive name.
class FridgeMagnetsApp extends IconicDesktopSystemWindowedApp

  title: "Fizzytiles"
  toolTip: "fridge magnets"
  buildIcon:   -> new FridgeMagnetsIconWdgt
  buildWindow: -> world.openFrameWith (new FridgeMagnetsWdgt), (new Point 570, 400), world.hand.position()

  # THE ONE LAZY LAUNCH SITE. This class and its icon are the eager 'fizzytiles-launcher' part, so
  # the desktop opener exists from boot; the engine (FridgeMagnetsWdgt and the ~9 classes behind it,
  # plus the 3D vendor payload) is the lazy 'fizzytiles' part and is not in the page until here.
  #
  # An `if FridgeMagnetsWdgt?` guard would be WRONG: for a LAZY part that reads "not loaded yet, so
  # silently do nothing", i.e. a click that does nothing. Awaiting the load is the only correct
  # shape, and it is safe to make this async because the base launch() is fire-and-forget -- the
  # launcher widget invokes it through reflection by name and ignores the return value. So no other
  # app and no base-class code changes.
  launch: ->
    world.parts.ensureLoaded("fizzytiles").then =>
      super()
