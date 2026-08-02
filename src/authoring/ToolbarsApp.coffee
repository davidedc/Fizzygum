# ToolbarsApp -- the "Super Toolbar" launcher app: opens the SuperToolbarWdgt
# palette (the toolbar-creator buttons) + its info widget on each launch.
# IconicDesktopSystemWindowedApp (Phase 6 6c.4). The window wrap is the shared
# world.openFrameWith.
class ToolbarsApp extends IconicDesktopSystemWindowedApp

  requiredParts: ["authoring"]

  # ⚠⚠ THE SAME PALETTE MUST NOT DEPEND ON HOW IT WAS OPENED, and without these it did. Every
  # toolbar this window can pop is built by a CREATOR BUTTON, which has no async seam
  # (WidgetCreatorAndSmartPlacerOnClickMixin.mouseClickLeft and grabbedWidgetSwitcheroo both consume
  # createWidgetToBeHandled()'s return value synchronously), so the await has to happen at the one
  # door that CAN await -- this one -- and it has to happen for the parts the palettes' CONTENTS
  # come from, not just the parts this window's own classes come from. Two symptoms it fixes:
  #   - SlidesToolbarWdgt reached from here silently lacked the two map tools, while the SAME class
  #     docked in a Slides Maker window had them (SimpleSlideApp declares 'maps' optional);
  #   - the Super Toolbar itself offered five palettes instead of six, because
  #     SuperToolbarWdgt filters PlotsToolbarCreatorButtonWdgt by class existence.
  # Neither was visible to the suite: the harness page presets FIZZYGUM_EAGER_ALL_PARTS, so there
  # both parts were always in and the tests recorded the COMPLETE palette all along -- the reduced
  # one only ever appeared on index.html, the page no test drives.
  # ⚠ OPTIONAL, not required: on a profile with neither part (the appliance) a Super Toolbar with
  # fewer palettes is reduced, not broken, and the toolbars' own `if X?` filters already produce it.
  optionalParts: ["maps", "plots"]


  buildWindow: ->
    world.openFrameWith new SuperToolbarWdgt, (new Point 60, 261), (new Point 170, 170)

  windowOpened: (wm) -> InfoDocs.createNextTo "superToolbar", wm
