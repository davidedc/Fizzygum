# AppCatalog -- the ONE statement of what each windowed app is as a desktop citizen: the caption its
# launcher shows, the art it draws, and the hover text if it has one.
#
# ⚠⚠ KEYED BY CLASS NAME, NEVER BY CLASS OBJECT, and that is the point rather than a detail. An icon
# is drawn at BOOT for an app whose class has not been fetched and may never be -- so anything here
# that REACHED an app class would make every app eager again and undo the boot-cost arc (production's
# js/pre-compiled.js is 27% smaller because reading a name is not reaching a class). Every app name
# below is a STRING LITERAL for that reason; none of them may ever become a bare identifier.
# See docs/architecture/build-and-packaging.md §2, "AN ICON IS NOT ITS APP".
#
# ⚠⚠ WHY ONE PLACE AND NOT TWO. An app's identity is read by two launcher modes -- the EAGER one
# (a live app singleton in hand) and the LAZY one (a class name only) -- and one entry serves both,
# through the single reader AppLauncherWdgt._fromCatalogEntry. The point
# is not tidiness. Split this across the two modes and the defect you get is not that the copies
# DISAGREE, it is that one is INCOMPLETE -- a field present in one and simply absent from the other,
# which reads as correct and which no gate can see (nothing asserts a tooltip, and a checker that
# compared two copies would find them consistent). One place to write a field is the only thing that
# prevents it: a field added below reaches both modes or neither.
#
# ⚠ AN APP HAS ONE NAME, and this is where it is written. A launcher's caption is stored on the
# widget, so a per-placement name would put two differently-named icons for the same app side by
# side the moment one is dragged out of the Examples folder onto the desktop. Hence deliberately NO
# per-call-site label override: a folder shows an app's name, it does not rename it.

class AppCatalog

  # The desktop's nine, in createDesktop's order, then the Examples folder's five.
  # ⚠ `icon` is a THUNK: it must not run until a launcher is actually being built, because on a
  # profile that cannot produce the app no widget should be constructed at all.
  #
  # ⚠⚠ A METHOD, NOT A FIELD, and that is forced by the meta-system rather than a style choice.
  # src/meta/Class.coffee splits a class body into members with /^  (@?ident) *: *(.*)/ and compiles
  # each member's body ON ITS OWN, taking whatever follows the colon as the body's first line. A
  # field whose value starts on the NEXT line therefore compiles as a bare indented block with
  # nothing to attach to — "unexpected indentation", and ONLY under the fragmented compile the
  # browser uses, so a plain `coffee -c` on this file passes and the build gate is what catches it.
  # The `->` gives the block something to attach to. (Rebuilt per call rather than memoised: it is
  # read once per launcher, ~14 times at desktop build, and a cache would be more machinery than the
  # thing it caches.)
  # ⚠⚠ ONE LINE PER ENTRY, NO BLANK LINES, NO COMMENTS INSIDE THE OBJECT — the same fragmentation
  # constraint as above, one level deeper. A member's body is compiled alone, and a CONTINUATION
  # line (an entry wrapped onto a second line) fails as "unexpected indentation" in that context
  # even though the whole file compiles fine with `coffee -c`. Every thunk is PARENTHESISED so the
  # key order inside an entry does not matter: an unparenthesised `->` in an object literal swallows
  # the rest of the line, so anything after it would parse as part of its body.
  #
  # ⚠ `DegreesConverterApp` has NO `icon`, and that is forced rather than chosen: its art lives in
  # the LAZY `examples-icons` part and check-part-edges.js reads ONE LINE AT A TIME, so naming it in
  # this CORE file would be an unguarded core->lazy reference and fail the build whenever the thunk
  # would actually run. ExamplesFolderWindowWdgt passes that icon in from inside the `whenAllLoaded`
  # scope that makes naming it legal — the only override in the system.
  #
  # Every icon here is BARE — no GenericShortcutIconWdgt arrow wrap: a launcher is not a
  # reference (it spawns independent instances), and under the arrow contract
  # (reference-widgets plan §4.4) the arrow badge is reserved for genuine widget references
  # made by "create shortcut".
  @entries: ->
    "HowToSaveMessageApp": {title: "How to save?",      icon: (-> new FloppyDiskIconWdgt)}
    "SimpleDocumentApp":   {title: "Docs Maker",        icon: (-> new TypewriterIconWdgt)}
    "FizzyPaintApp":       {title: "Draw",              icon: (-> new PaintBucketIconWdgt)}
    "SimpleSlideApp":      {title: "Slides Maker",      icon: (-> new SimpleSlideIconWdgt)}
    "DashboardsApp":       {title: "Dashboards",        icon: (-> new DashboardsIconWdgt)}
    "PatchProgrammingApp": {title: "Patch programming", icon: (-> new PatchProgrammingIconWdgt)}
    "GenericPanelApp":     {title: "Generic panel",     icon: (-> new GenericPanelIconWdgt)}
    "ToolbarsApp":         {title: "Super Toolbar",     icon: (-> new ToolbarsIconWdgt), toolTip: "a toolbar to rule them all"}
    "FridgeMagnetsApp":    {title: "Fizzytiles",        icon: (-> new FridgeMagnetsIconWdgt), toolTip: "fridge magnets"}
    "DegreesConverterApp": {title: "C-F converter"}
    "SampleSlideApp":      {title: "Slide",             icon: (-> new SimpleSlideIconWdgt)}
    "SampleDashboardApp":  {title: "Dashboard",         icon: (-> new DashboardsIconWdgt)}
    "SampleDocApp":        {title: "Document",          icon: (-> new TypewriterIconWdgt)}
    "SpreadsheetApp":      {title: "Spreadsheet",       icon: (-> new TypewriterIconWdgt)}

  @get: (appClassName) ->
    @entries()[appClassName]
