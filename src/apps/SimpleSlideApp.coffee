# SimpleSlideApp -- the "Slides Maker" launcher app: opens a fresh SimpleSlide window
# (+ its info widget) on each launch. An IconicDesktopSystemWindowedApp (Phase 6 6c.4).
# Distinct from SampleSlideApp, which opens the filled NYC sample slide.
class SimpleSlideApp extends IconicDesktopSystemWindowedApp

  title: "Slides Maker"
  buildIcon:    -> new SimpleSlideIconWdgt
  buildWindow:  -> world.openFrameWith (new SlideWdgt), (new Point 460, 400), (new Point 168, 134)
  windowOpened: (wm) -> InfoDocs.createNextTo "slidesMaker", wm

  # The window's docked SlidesToolbarWdgt offers the two map tools, which are the LAZY 'maps' part.
  # OPTIONAL rather than required -- a slide window without the map tools is a smaller palette, not
  # a broken window -- so a profile that ships no 'maps' still opens it. See DashboardsApp.launch
  # and PartsRegistry.whenOptionalPartsLoaded for why the distinction matters.
  launch: ->
    world.parts.whenOptionalPartsLoaded ["maps"], => super()
