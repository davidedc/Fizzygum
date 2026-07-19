class PatchProgrammingWdgt extends StretchableEditableWdgt

  colloquialName: ->
    "Patch Programming"

  representativeIcon: ->
    new PatchProgrammingIconWdgt


  # the frame docks this variant in its toolbar-slot (Frame-model plan §5.C) --
  # the SAME list the floating components palette summons (one-variant rule)
  buildToolbar: ->
    new PatchProgrammingToolbarWdgt

  # (_createNewStretchablePanelNoSettle is inherited from StretchableEditableWdgt — this class's
  # createNewStretchablePanel override was a byte-identical copy of the base and was deleted in the
  # rule-[S] convert, like the hoisted _reLayoutSelf below.)

  # (_reLayoutSelf is inherited from StretchableEditableWdgt — the byte-identical
  # Dashboards/PatchProgramming/SimpleSlide copies were hoisted there 2026-07-12.)

