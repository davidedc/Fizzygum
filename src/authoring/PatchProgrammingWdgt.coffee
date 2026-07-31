# The framed PATCH-PROGRAMMING citizen (Frame-model plan §5.B): kind name +
# icon + toolbar variant on the GenericPanelWdgt family base. (Re-based from
# the retired StretchableEditableWdgt editor shape -- the plain name was
# already the citizen name.)

class PatchProgrammingWdgt extends GenericPanelWdgt

  colloquialName: ->
    "Patch Programming"

  representativeIcon: ->
    new PatchProgrammingIconWdgt

  # the frame docks this variant in its toolbar-slot (§5.C) -- the SAME list
  # the floating components palette summons (one-variant rule)
  buildToolbar: ->
    new PatchProgrammingToolbarWdgt
