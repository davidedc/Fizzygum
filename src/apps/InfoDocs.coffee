# The one-shot "*Info" documents (Bin / Dashboards Maker / Generic Panel /
# Patch Programming / Drawings Maker / Docs Maker / Slides Maker / Super
# Toolbar / Windows) collapsed into ONE registry of build closures (Option A
# "closure table"), keyed by app. Each app's launcher calls
# `InfoDocs.createNextTo "<key>", windowJustOpened` instead of a dedicated
# one-method factory class. `WelcomeMessageInfoWdgt` stays a standalone class
# (its `@create` is a large bespoke build, not one of these keyed docs).
#
# Every `@REGISTRY` entry's `build` closure keeps the exact per-doc body
# (paragraphs/bullets/links) that its old factory class had, and `@_iconFor`
# keeps each doc's icon construction as a literal `new X` -- so the load-order
# dependency finder (which regex-scans source text for `new X`) still sees
# every edge, with no `# REQUIRES` markers needed.
class InfoDocs

  @REGISTRY:
    bin:
      flag:        "infoDoc_bin_created"
      title:       "Bin"
      windowTitle: "Bin info"
      build: (sdspw) ->
        sdspw.addNormalParagraph "Drag things in here to throw them away.\n\nItems you close without saving a link to also land in here. Documents you did save live behind their link icons and are not shown.\n\n\"Empty bin\" destroys everything shown, for good."

    dashboards:
      flag:        "infoDoc_dashboardsMaker_created"
      title:       "Dashboards Maker"
      windowTitle: "Dashboards Maker info"
      build: (sdspw) ->
        sdspw.addNormalParagraph "Lets you arrange a choice of graphs/charts/plots/maps in any way you please. The visualisations can also be interactive (as in the 3D plot example, which you can drag to rotate) and/or calculated on the fly.\n\nOn the bar on the left you can find four example graphs and two example maps."

        sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
        sdspw.addNormalParagraph "To see an example of use, check out the video here:"

        startingContent = new SimpleVideoLinkWdgt "Dashboards Maker", "http://fizzygum.org/docs/dashboards/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent.layoutSpecDetails.setAlignmentToRight()

    genericPanel:
      flag:        "infoDoc_genericPanel_created"
      title:       "Generic Panel"
      windowTitle: "Generic Panels info"
      build: (sdspw) ->
        sdspw.addNormalParagraph "You can use this panel to temporarily hold widgets, or to put together any mix of widgets. It's just a more generic version of slides and dashboards."
        sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
        sdspw.addNormalParagraph "To see an example of use, check out the video here:"

        startingContent = new SimpleVideoLinkWdgt "Mixing widgets (using generic panels)", "http://fizzygum.org/docs/mixing-widgets/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent.layoutSpecDetails.setAlignmentToRight()

    patchProgramming:
      flag:        "infoDoc_patchProgramming_created"
      title:       "Patch Programming"
      windowTitle: "Patch Programming info"
      build: (sdspw) ->
        sdspw.addNormalParagraph "'Patch programming' is a type of visual programming where you simply connect together existing widgets. It's useful to make simple applications/utilities quickly."
        sdspw.addNormalParagraph "You can imagine the widgets being 'patched together' by imaginary wires."
        sdspw.addNormalParagraph "You can see in the `example docs` folder a °C ↔ °F converter example made with this."
        sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
        sdspw.addNormalParagraph "To see an example of use, check out the videos here:"

        startingContent = new SimpleVideoLinkWdgt "Patch programming - basics", "http://fizzygum.org/docs/basic-connections/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent.layoutSpecDetails.setAlignmentToRight()

        startingContent = new SimpleVideoLinkWdgt "Patch programming - advanced", "http://fizzygum.org/docs/advanced-connections/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent.layoutSpecDetails.setAlignmentToRight()

    drawingsMaker:
      flag:        "infoDoc_drawingsMaker_created"
      title:       "Drawings Maker"
      windowTitle: "Drawings Maker info"
      build: (sdspw) ->
        sdspw.addNormalParagraph "Simple paint app. But you can drop anything inside it (try with the clock) to 'use it as a stamp'."

        sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
        sdspw.addNormalParagraph "To see an example of use, check out the video here:"

        startingContent = new SimpleVideoLinkWdgt "Draw app", "http://fizzygum.org/docs/draw-app/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent.layoutSpecDetails.setAlignmentToRight()

        sdspw.addNormalParagraph "You can also edit the tools you use, by clicking on the pencil icon next to the tool."
        sdspw.addNormalParagraph "To see how an example of editing the tools, see this video:"

        startingContent = new SimpleVideoLinkWdgt "Hacking Fizzygum", "http://fizzygum.org/docs/hacking-fizzygum/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent.layoutSpecDetails.setAlignmentToRight()

    docsMaker:
      flag:        "infoDoc_docsMaker_created"
      title:       "Docs Maker"
      windowTitle: "Docs Maker info"
      build: (sdspw) ->
        sdspw.addNormalParagraph "A basic text editor. But you can drop anything inside it.\n\nNote that the Docs Maker works 'by paragraph': you can drag/drop paragraphs, and when you change the style the whole paragraph is affected.\n\nQuickest way to compose a document is to drag/drop snippets, which you can find by clicking the button that looks like this:"

        startingContent = new GlassBoxBottomWdgt
        startingContent.add new TemplatesButtonWdgt
        startingContent._applyExtent new Point 50, 50
        sdspw.add startingContent
        startingContent.layoutSpecDetails.setAlignmentToCenter()

        sdspw.addSpacer()

        sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
        sdspw.addNormalParagraph "To see an example of use, check out the video here:"

        startingContent = new SimpleVideoLinkWdgt "Docs Maker", "http://fizzygum.org/docs/documents-maker/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent.layoutSpecDetails.setAlignmentToRight()

    slidesMaker:
      flag:        "infoDoc_slidesMaker_created"
      title:       "Slides Maker"
      windowTitle: "Slides Maker info"
      build: (sdspw) ->
        sdspw.addNormalParagraph "Anything you drop inside the slide 'keeps proportion' when resized, which makes it handy to put pins on maps, add callouts, arrange text in custom layouts etc."

        sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
        sdspw.addNormalParagraph "To see an example of use, check out the video here:"

        startingContent = new SimpleVideoLinkWdgt "Slides Maker", "http://fizzygum.org/docs/slides-maker/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent.layoutSpecDetails.setAlignmentToRight()

    superToolbar:
      flag:        "infoDoc_superToolbar_created"
      title:       "Super Toolbar"
      windowTitle: "Super Toolbar info"
      build: (sdspw) ->
        sdspw.addNormalParagraph "The Super Toolbar can create all other toolbars for you, and from those toolbars you can create any widget.\n\nThis is handy because any widget can go in any document... so here is a way to access them all.\n\nFor an example on how this is useful, see the video on `mixing widgets`:"

        startingContent = new SimpleVideoLinkWdgt "Mixing widgets", "http://fizzygum.org/docs/mixing-widgets/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent.layoutSpecDetails.setAlignmentToRight()

    windowsToolbar:
      flag:        "infoDoc_windowsToolbar_created"
      title:       "Types of windows"
      windowTitle: "Windows info"
      build: (sdspw) ->
        sdspw.addNormalParagraph "There are four main types of windows"
        sdspw.addBulletPoint "empty windows, with a target area where you can drop other items in"
        sdspw.addBulletPoint "windows that crop their content"
        sdspw.addBulletPoint "windows with a scroll view on their content"
        sdspw.addBulletPoint "windows with an elastic panel, such that when resized the content will resize as well"

        #sdspw.addNormalParagraph "Check out some examples of use in this video:"

        #startingContent = new SimpleVideoLinkWdgt "Using windows"
        #startingContent._applyExtent new Point 405, 50
        #sdspw.add startingContent
        #startingContent.layoutSpecDetails.setAlignmentToRight()

  # the per-doc ICON is a literal `new X` so the dep finder sees it:
  @_iconFor:
    bin:         -> new BinIconWdgt
    dashboards:       -> new DashboardsIconWdgt
    genericPanel:     -> new GenericPanelIconWdgt
    patchProgramming: -> new PatchProgrammingIconWdgt
    drawingsMaker:    -> new PaintBucketIconWdgt
    docsMaker:        -> new TypewriterIconWdgt
    slidesMaker:      -> new SimpleSlideIconWdgt
    superToolbar:     -> new ToolbarsIconWdgt
    windowsToolbar:   -> new WindowsToolbarIconWdgt

  # Keeps the once-only guard FIRST (so nothing is built on a repeat call),
  # then constructs `doc` + the per-key icon itself, then hands off to the
  # shared layout builder. RETURNS the DocumentWdgt --
  # WindowsToolbarCreatorButtonWdgt's caller captures it (readmeWindow) to
  # reposition it; the other callers discard it.
  @createNextTo: (key, nextToThisWidget) ->
    entry = @REGISTRY[key]
    return if world[entry.flag]

    doc = new DocumentWdgt
    @_buildInfoDocNextTo nextToThisWidget, entry.flag, doc, @_iconFor[key](), entry.title, entry.windowTitle, entry.build

  # Shared builder for the one-shot info documents above. It lays out the
  # common shape -- the icon + centred title + divider header, then the
  # per-key body via the `buildBody sdspw` callback, then places/titles/locks
  # the doc window (set the once-only `world[flagName]`, monkey-patch
  # close-to-destroy, position next to nextToThisWidget) -- and RETURNS the
  # DocumentWdgt.
  @_buildInfoDocNextTo: (nextToThisWidget, flagName, doc, iconWidget, title, windowTitle, buildBody) ->
    sdspw = doc.contents

    iconWidget._applyExtent new Point 85, 85
    sdspw.setContents iconWidget, 5
    iconWidget.layoutSpecDetails.setGrow 0
    iconWidget.layoutSpecDetails.setAlignmentToCenter()

    titleWidget = new SimpleTextWdgt(
      title,nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    titleWidget.alignCenter()
    titleWidget.setFontSize 22
    titleWidget.isEditable = true
    titleWidget.enableSelecting()
    sdspw.add titleWidget

    sdspw.addDivider()

    buildBody sdspw

    doc._applyExtent new Point 365, 405
    doc._moveFullCenterTo world.center()
    world.add doc
    doc.setTitleWithoutPrependedContentName windowTitle

    doc.disableDragsDropsAndEditing()
    world[flagName] = true

    # one-shot info window: closing destroys it outright (no save prompt) --
    # the tracked close policy (§5.E E2), replacing the untracked instance-method
    # injection this once was.
    doc.closeFromFrameBarPolicy = 'destroy'

    doc._moveToSideOf nextToThisWidget
    doc._rememberFractionalSituationInHoldingPanel()

    return doc
