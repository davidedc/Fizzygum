# The one-shot "info" documents -- one per Maker (Dashboards, Generic panel, Patch programming,
# Draw, Docs Maker, Slides Maker, Super toolbar) plus the Windows toolbar's -- as ONE registry of
# build closures. An app's `windowOpened` hook calls `InfoDocs.createNextTo @constructor.name,
# windowJustOpened` instead of a dedicated one-method factory class. `WelcomeMessageInfoWdgt` stays
# a standalone class (its `@create` is a large bespoke build, not one of these keyed docs).
#
# ⚠ KEYED BY APP CLASS NAME, and an app's entry states only its BODY. Its heading, its window title
# ("<name> info") and its icon are the app's own, read from AppCatalog -- AN APP HAS ONE NAME (see
# AppCatalog's header), so the info window a launch opens cannot call the app something its icon
# does not ("Draw info" beside the "Draw" icon). A title typed here would be a second name for the
# app, free to disagree with the first, so an app entry may not state one. The one entry no app
# owns (windowsToolbar, opened by WindowsToolbarCreatorButtonWdgt) states its own title, window
# title and icon. _identityOf holds both shapes, and refuses an entry that is neither (or both) --
# loudly, the first time it is built.
# (Every app-keyed doc is built by the `apps` gauntlet leg, which launches every desktop app.)
class InfoDocs

  @REGISTRY:
    DashboardsApp:
      build: (sdspw) ->
        sdspw.addNormalParagraph "Lets you arrange a choice of graphs/charts/plots/maps in any way you please. The visualisations can also be interactive (as in the 3D plot example, which you can drag to rotate) and/or calculated on the fly.\n\nOn the bar on the left you can find four example graphs and two example maps."

        sdspw.addNormalParagraph "Once you are done editing, flip the switch on the window bar to the eye."
        sdspw.addNormalParagraph "To see an example of use, check out the video here:"

        startingContent = new SimpleVideoLinkWdgt "Dashboards Maker", "http://fizzygum.org/docs/dashboards/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent._contentStackSpec.setAlignmentToRight()

    GenericPanelApp:
      build: (sdspw) ->
        sdspw.addNormalParagraph "You can use this panel to temporarily hold widgets, or to put together any mix of widgets. It's just a more generic version of slides and dashboards."
        sdspw.addNormalParagraph "Once you are done editing, flip the switch on the window bar to the eye."
        sdspw.addNormalParagraph "To see an example of use, check out the video here:"

        startingContent = new SimpleVideoLinkWdgt "Mixing widgets (using generic panels)", "http://fizzygum.org/docs/mixing-widgets/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent._contentStackSpec.setAlignmentToRight()

    PatchProgrammingApp:
      build: (sdspw) ->
        sdspw.addNormalParagraph "'Patch programming' is a type of visual programming where you simply connect together existing widgets. It's useful to make simple applications/utilities quickly."
        sdspw.addNormalParagraph "You can imagine the widgets being 'patched together' by imaginary wires."
        sdspw.addNormalParagraph "You can see in the `example docs` folder a °C ↔ °F converter example made with this."
        sdspw.addNormalParagraph "Once you are done editing, flip the switch on the window bar to the eye."
        sdspw.addNormalParagraph "To see an example of use, check out the videos here:"

        startingContent = new SimpleVideoLinkWdgt "Patch programming - basics", "http://fizzygum.org/docs/basic-connections/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent._contentStackSpec.setAlignmentToRight()

        startingContent = new SimpleVideoLinkWdgt "Patch programming - advanced", "http://fizzygum.org/docs/advanced-connections/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent._contentStackSpec.setAlignmentToRight()

    FizzyPaintApp:
      build: (sdspw) ->
        sdspw.addNormalParagraph "Simple paint app. But you can drop anything inside it (try with the clock) to 'use it as a stamp'."

        sdspw.addNormalParagraph "Once you are done editing, flip the switch on the window bar to the eye."
        sdspw.addNormalParagraph "To see an example of use, check out the video here:"

        startingContent = new SimpleVideoLinkWdgt "Draw app", "http://fizzygum.org/docs/draw-app/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent._contentStackSpec.setAlignmentToRight()

        sdspw.addNormalParagraph "You can also edit the tools you use, by clicking on the pencil icon next to the tool."
        sdspw.addNormalParagraph "To see how an example of editing the tools, see this video:"

        startingContent = new SimpleVideoLinkWdgt "Hacking Fizzygum", "http://fizzygum.org/docs/hacking-fizzygum/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent._contentStackSpec.setAlignmentToRight()

    SimpleDocumentApp:
      build: (sdspw) ->
        sdspw.addNormalParagraph "A basic text editor. But you can drop anything inside it.\n\nNote that the Docs Maker works 'by paragraph': you can drag/drop paragraphs, and when you change the style the whole paragraph is affected.\n\nQuickest way to compose a document is to drag/drop snippets, which you can find by clicking the button that looks like this:"

        startingContent = new GlassBoxBottomWdgt
        startingContent.add new TemplatesButtonWdgt
        startingContent._applyExtent new Point 50, 50
        sdspw.add startingContent
        startingContent._contentStackSpec.setAlignmentToCenter()

        sdspw.addSpacer()

        sdspw.addNormalParagraph "Once you are done editing, flip the switch on the window bar to the eye."
        sdspw.addNormalParagraph "To see an example of use, check out the video here:"

        startingContent = new SimpleVideoLinkWdgt "Docs Maker", "http://fizzygum.org/docs/documents-maker/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent._contentStackSpec.setAlignmentToRight()

    SimpleSlideApp:
      build: (sdspw) ->
        sdspw.addNormalParagraph "Anything you drop inside the slide 'keeps proportion' when resized, which makes it handy to put pins on maps, add callouts, arrange text in custom layouts etc."

        sdspw.addNormalParagraph "Once you are done editing, flip the switch on the window bar to the eye."
        sdspw.addNormalParagraph "To see an example of use, check out the video here:"

        startingContent = new SimpleVideoLinkWdgt "Slides Maker", "http://fizzygum.org/docs/slides-maker/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent._contentStackSpec.setAlignmentToRight()

    ToolbarsApp:
      build: (sdspw) ->
        sdspw.addNormalParagraph "The Super Toolbar can create all other toolbars for you, and from those toolbars you can create any widget.\n\nThis is handy because any widget can go in any document... so here is a way to access them all.\n\nFor an example on how this is useful, see the video on `mixing widgets`:"

        startingContent = new SimpleVideoLinkWdgt "Mixing widgets", "http://fizzygum.org/docs/mixing-widgets/"
        startingContent._applyExtent new Point 405, 50
        sdspw.add startingContent
        startingContent._contentStackSpec.setAlignmentToRight()

    windowsToolbar:
      title:       "Types of windows"
      windowTitle: "Windows info"
      icon:        -> new WindowsToolbarIconWdgt
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
        #startingContent._contentStackSpec.setAlignmentToRight()

  # What the doc `key` names is called and wears: {title, windowTitle, icon}. An app's comes from
  # AppCatalog; the entry no app owns states its own. ⚠ Either shape alone, never both and never
  # neither: an app entry stating a title would be a second name for the app (the drift this
  # replaced), and an entry naming no app and stating nothing would have no name at all.
  @_identityOf: (key) ->
    entry = @REGISTRY[key]
    if !entry?
      throw new Error "InfoDocs has no entry '#{key}'"
    app = AppCatalog.get key
    statesItsOwn = entry.title? or entry.windowTitle? or entry.icon?
    if app? and statesItsOwn
      throw new Error "InfoDocs entry '#{key}' states a title or icon, but #{key} is an app: AppCatalog names it"
    if app?
      return {title: app.title, windowTitle: app.title + " info", icon: (-> AppCatalog.iconOf key)}
    if !(entry.title? and entry.windowTitle? and entry.icon?)
      throw new Error "InfoDocs entry '#{key}' is no AppCatalog app, so it must state its own title, windowTitle and icon"
    entry

  # Builds the one-shot info document `key` names, next to nextToThisWidget. The once-only guard
  # comes FIRST, so nothing is built on a repeat call. Then the common shape: the icon + centred
  # title + divider header (_identityOf), the per-key body via the entry's `build sdspw` callback,
  # then the doc window is placed, titled and locked (the once-only `infoDoc_<key>_created` world
  # flag, the destroy-on-close policy, positioned next to nextToThisWidget). RETURNS the DocumentWdgt --
  # WindowsToolbarCreatorButtonWdgt's caller captures it (readmeWindow) to reposition it; the other
  # callers discard it.
  # ⚠ NO await here, and that is a property of where this class LIVES. Every info doc IS a
  # DocumentWdgt, and InfoDocs sits in the same 'authoring' part as DocumentWdgt -- seven of its
  # REGISTRY keys name a Maker and the eighth the windows toolbar, so it is authoring-surface material
  # and nothing in core reaches it.
  # Its callers are the seven Makers' `windowOpened` hooks, which the base runs after buildWindow,
  # i.e. after `launch` already awaited; and WindowsToolbarCreatorButtonWdgt, which is in this part.
  @createNextTo: (key, nextToThisWidget) ->
    identity = @_identityOf key
    flag = "infoDoc_" + key + "_created"
    return if world[flag]

    doc = new DocumentWdgt
    iconWidget = identity.icon()
    sdspw = doc.contents

    iconWidget._applyExtent new Point 85, 85
    sdspw.setContents iconWidget
    iconWidget._contentStackSpec.setGrow 0
    iconWidget._contentStackSpec.setAlignmentToCenter()

    sdspw.addTitle identity.title

    sdspw.addDivider()

    @REGISTRY[key].build sdspw

    doc._applyExtent new Point 365, 405
    doc._moveFullCenterTo world.center()
    world.add doc
    doc.setTitleWithoutPrependedContentName identity.windowTitle

    doc.disableDragsDropsAndEditing()
    world[flag] = true

    # one-shot info window: closing destroys it outright (no save prompt) --
    # the tracked close policy (§5.E E2).
    doc.closeFromFrameBarPolicy = 'destroy'

    doc._moveToSideOf nextToThisWidget

    return doc
