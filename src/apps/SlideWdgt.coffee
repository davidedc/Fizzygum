# The framed SLIDE citizen (Frame-model plan §5.B, owner decision D2): kind
# name + icon + toolbar variant on the GenericPanelWdgt family base.

class SlideWdgt extends GenericPanelWdgt

  colloquialName: ->
    "Slides Maker"

  representativeIcon: ->
    new SimpleSlideIconWdgt

  # the frame docks this variant in its toolbar-slot (§5.C)
  buildToolbar: ->
    new SlidesToolbarWdgt
