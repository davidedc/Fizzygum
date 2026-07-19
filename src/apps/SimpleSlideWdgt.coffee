class SimpleSlideWdgt extends StretchableEditableWdgt

  colloquialName: ->
    "Slides Maker"

  representativeIcon: ->
    new SimpleSlideIconWdgt


  # the frame docks this variant in its toolbar-slot (Frame-model plan §5.C)
  buildToolbar: ->
    new SlidesToolbarWdgt

  # (_createNewStretchablePanelNoSettle is inherited from StretchableEditableWdgt — this class's
  # createNewStretchablePanel override was a byte-identical copy of the base and was deleted in the
  # rule-[S] convert, like the hoisted _reLayoutSelf below.)

  # I coordinate drags/drops/editing for my stretchable container, which delegates its
  # enable/disable up to me (replacing its `@parent instanceof SimpleSlideWdgt` test
  # with this query). (type-test-elimination campaign)
  coordinatesDragsDropsAndEditingForChildren: ->
    true


  # (_reLayoutSelf is inherited from StretchableEditableWdgt — the byte-identical
  # Dashboards/PatchProgramming/SimpleSlide copies were hoisted there 2026-07-12.)

