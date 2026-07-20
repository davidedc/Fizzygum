# SimpleSlideApp -- the "Slides Maker" launcher app: opens a fresh SimpleSlide window
# (+ its info widget) on each launch. An IconicDesktopSystemWindowedApp (Phase 6 6c.4).
# Distinct from SampleSlideApp, which opens the filled NYC sample slide.
class SimpleSlideApp extends IconicDesktopSystemWindowedApp

  title: "Slides Maker"
  buildIcon:    -> new SimpleSlideIconWdgt
  buildWindow:  -> world.openFrameWith (new SlideWdgt), (new Point 460, 400), (new Point 168, 134)
  windowOpened: (wm) -> InfoDocs.createNextTo "slidesMaker", wm
