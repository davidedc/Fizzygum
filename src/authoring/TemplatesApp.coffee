# TemplatesApp -- the Docs Maker's "useful snippets" window, as an app that opens ONE window
# (opensOneWindow). TemplatesButtonWdgt launches it, so the window lives in world.appWindows beside
# the Examples' and "How to save?"'s, and everything that must know it -- the bring-forward on a
# later click, the storage sort (a closed one stays reachable, so it is shelved, not binned), the
# liveness roots, a snapshot, the teardown -- reads the registry like any other app window, with no
# world field of its own and no special case anywhere.
# ⚠ NO AppCatalog ENTRY, and none is owed: the catalog states what an app looks like as a DESKTOP
# citizen (its launcher's caption and art), and this app has no launcher -- its door is a toolbar
# button. Its window titles itself (TemplatesWindowWdgt.create), so _title is never read for it.
# (The super toolbar's UsefulTextSnippetsToolbarCreatorButtonWdgt builds a FRESH templates window per
# drag through TemplatesWindowWdgt.create: that one is a widget handed to the user, not this app's.)

class TemplatesApp extends WindowedApp

  opensOneWindow: true

  buildWindow: ->
    templatesWindow = TemplatesWindowWdgt.create()
    templatesWindow._applyMoveTo world.hand.position().subtract new Point 50, 50
    templatesWindow._moveWithin world
    world.add templatesWindow
    templatesWindow
