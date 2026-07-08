# this file is excluded from the fizzygum homepage build
# FridgeMagnetsApp -- the fridge-magnets ("Fizzytiles") launcher app: opens a
# fresh fridge-magnets window at the hand on each launch (same window shape as
# MenusHelper.createFridgeMagnets, which stays as the menu path to the same
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
  buildWindow: -> world.openWindowWith (new FridgeMagnetsWdgt), (new Point 570, 400), world.hand.position()
