# A widget shown as a PICTURE. I hold one widget -- a command's icon: a paint-only icon widget, or
# a copy of the live tool the command stands for -- and I present it as an image, never as
# something to press. A menu row places me as its glyph (MenuItemWdgt._placeMyIcon) and a tap
# anywhere on that row is the ROW's click, whole.
#
# WHY I EXIST: an icon derived from a live thing IS that thing. A copy of a tool is a button, and a
# button under a pointer behaves like a button -- it highlights, it presses, it triggers -- which
# would make a row's picture a second, smaller target sitting inside the first. Held by me it hears
# no pointer at all: I declare `catchesPointerAt: -> false`, so the hit falls through me to
# whatever encloses me, and my child is never asked.
#   ⓘ That declaration is a ROLE, not a shape -- the PopUpRowsViewportWdgt precedent, whose comment
# states the same law from the other side ("alpha is PAINTING, not hit-testing"). Where a widget's
# surface stops the pointer is a question about its shape and belongs to its appearance; WHETHER it
# is offered as a target at all is the widget's own business, and mine is to be looked at.
#
# I track what I hold: my box IS the picture's box, so sizing me to a glyph box sizes the picture
# with it, and whoever builds me decides what it looks like.

class InertIconHolderWdgt extends Widget

  # the widget I show. Taken by the constructor -- it is what I AM, so there is nothing to keep a
  # class-level default for.
  heldWidget: undefined

  constructor: (@heldWidget) ->
    super()
    @_buildAndConnectChildren()

  colloquialName: ->
    "icon"

  # THE ROLE (see the header): invisible-to-the-pointer chrome, whatever my shape says.
  catchesPointerAt: (aPoint) ->
    false

  # I am a picture, not an editing surface. The editor SELECTION walk
  # (WorldWdgt._widgetBeingEdited) climbs to the first ancestor with an OPINION, and mine is none:
  # `undefined` lets the walk pass through me to whoever is really being edited.
  providesAmenitiesForEditing: undefined

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    return unless @heldWidget?
    # the quietest correct verb (widget-authoring-guidelines §3.6): I am not attached yet, so there
    # is nothing to re-lay and nothing to repaint -- I simply start out the size of my picture.
    @__commitExtent @heldWidget.extent()
    @_addNoSettle @heldWidget

  # I track my content's size, so I own this chokepoint (§6.1) and the engine drives it: what I
  # hold fills me exactly. That is what makes sizing ME the way to size the picture.
  _reLayoutChildren: ->
    return unless @heldWidget?
    @heldWidget._applyBounds @position(), @extent()

  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()
