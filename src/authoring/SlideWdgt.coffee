# The framed SLIDE citizen (Frame-model plan §5.B, owner decision D2): kind
# name + icon + toolbar variant on the GenericPanelWdgt family base.

class SlideWdgt extends GenericPanelWdgt

  #: printing

  colloquialName: ->
    "Slides Maker"

  #: shortcuts

  representativeIcon: ->
    new SimpleSlideIconWdgt

  #: docking

  # the frame docks this variant in its toolbar-slot (§5.C)
  _buildToolbar: ->
    new SlidesToolbarWdgt
