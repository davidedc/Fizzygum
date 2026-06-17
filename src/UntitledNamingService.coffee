# UntitledNamingService — hands out the default "Untitled" / "new folder" names
# for freshly-created desktop shortcuts and folders, tracking how many of each
# have been made so the Nth gets an " N" suffix.
#
# Lifted out of WorldWdgt as a plain delegated collaborator (the MacroToolkit
# pattern — the codebase's mixins-to-delegation direction): the world HAS-A one,
# created in the WorldWdgt constructor and reachable as
# world.untitledNamingService. The counters live here now; like the old
# WorldWdgt instance fields they simply reset to 0 with each new world (the
# service is reconstructed in the ctor, not serialized). OO-backlog Phase 6 step
# 6a.1 — the first God-class extraction.
class UntitledNamingService

  howManyUntitledShortcuts: 0
  howManyUntitledFoldersShortcuts: 0

  getNextUntitledShortcutName: ->
    name = "Untitled"
    if @howManyUntitledShortcuts > 0
      name += " " + (@howManyUntitledShortcuts + 1)

    @howManyUntitledShortcuts++

    return name

  getNextUntitledFolderShortcutName: ->
    name = "new folder"
    if @howManyUntitledFoldersShortcuts > 0
      name += " " + (@howManyUntitledFoldersShortcuts + 1)

    @howManyUntitledFoldersShortcuts++

    return name

  # Creating a folder (PanelWdgt.makeFolder) also consumes an "untitled shortcut"
  # number, so it advances this counter on top of the folder counter above. This
  # encapsulates a former raw `world.howManyUntitledShortcuts++` poke at the field.
  noteShortcutCreated: ->
    @howManyUntitledShortcuts++
