# FridgeMagnetsApp -- the fridge-magnets ("Fizzytiles") launcher app: opens a
# fresh fridge-magnets window at the hand on each launch (same window shape as
# DemoMenus.createFridgeMagnets, which stays as the menu path to the same
# widget). An WindowedApp; like the whole fizzytiles family
# this ships only in the full build. Its caption, icon and tooltip are NOT
# declared here -- they live in AppCatalog, keyed by class name, so drawing
# its desktop icon never reaches this class (see AppCatalog's header).
class FridgeMagnetsApp extends WindowedApp

  requiredParts: ["fizzytiles"]

  buildWindow: -> world.openFrameWith (new FridgeMagnetsWdgt), (new Point 570, 400), world.hand.position()
