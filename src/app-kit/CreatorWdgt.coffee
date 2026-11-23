# A CREATOR: a toolbar tool that makes a widget when clicked (_createWidgetToBeHandled, my
# subclasses') and places it where the toolbar I stand in works for (ToolbarWdgt.hostWindowOf):
#   - DOCKED on a window, I work for that window: the widget goes into my host's content when that
#     content takes a click-placed widget, and otherwise NOWHERE -- I make nothing at all, so a host
#     that takes nothing is never handed a widget it cannot place, and nothing lands elsewhere.
#   - FLOATING (or standing in no toolbar), I work for the person: the widget goes into the topmost
#     window whose content takes a click-placed widget, else beside me on the desktop.
# A window in view mode takes none, and neither does a content that stamps what is dropped on it (a
# drawing): a click ends in the same kind of result a drop would. A DRAG out of me carries the very
# thing a click would place, made by the same method (grabbedWidgetSwitcheroo), and where it lands is
# the drop's to name, not mine. The base of the creator buttons and of a tool cell's lid
# (GlassBoxTopWdgt).

class CreatorWdgt extends Widget

  # MY HOVER AND PRESS show on the tool cell I stand in, never on me: the cell reads the hand's answers
  # about me as it paints (GlassBoxBottomWdgt.fillForToolState asks this), and I tell it when they move.
  lightsAToolCell: ->
    true

  # The hand's answers about me may have moved (ActivePointerWdgt._tellPointerStateChanged): my glyph
  # keeps its one ink, so I tell the cell I stand in, which repaints over me. A parent that is no cell
  # answers nothing.
  notePointerStateChanged: ->
    @parent?.noteItemStateChanged?()

  # A DRAG OUT OF ME carries what a click on me would place: the hand asks me what comes onto it
  # (ActivePointerWdgt.determineGrabs), and I make it there and then, so my two gestures make one thing.
  grabbedWidgetSwitcheroo: ->
    @_createWidgetToBeHandled()

  # I am what the drag takes hold of, never the tool cell I stand in: otherwise the cell would answer the
  # drag and the hand would carry my cell's tool away instead of what I make
  grabsToParentWhenDragged: ->
    false


  activated: (ignored, ignored2, ignored3, ignored4, ignored5, ignored6, ignored7, partOfDoubleClick) ->
    return if partOfDoubleClick
    host = ToolbarWdgt.hostWindowOf @
    if host? then @_placeIntoMyHost host else @_placeForThePerson()

  # DOCKED: into my host's content, or nowhere. Decided BEFORE anything is made -- a copy that is
  # refused tells the person why, so a widget that cannot be placed must never be made.
  _placeIntoMyHost: (host) ->
    return unless host.contents?.acceptsSmartPlacedWidgets?()
    widgetToBePlaced = @_createWidgetToBeHandled()
    # none made (a copy refused, and told): nothing to place
    return unless widgetToBePlaced?
    host.contents.smartPlace widgetToBePlaced, @

  # FLOATING: the topmost window that takes a click-placed widget, else the desktop beside me.
  _placeForThePerson: ->
    widgetToBePlaced = @_createWidgetToBeHandled()
    # none made (a copy refused, and told): nothing to place
    return unless widgetToBePlaced?

    # TODO un-handled cases:
    #  - empty window with drop-in placeholder
    #  - window with panel
    #  - window with scrollpanel
    # find the topmost window whose content takes a smart-placed widget, then let that content
    # place it. acceptsSmartPlacedWidgets / smartPlace live on the content widgets (the citizens'
    # StretchableWidgetContainerWdgt payload, and a DocumentWdgt's DocumentViewportWdgt payload),
    # asked through ?(). A content takes none while its editing is off (a window in view mode), nor
    # when it stamps what is dropped on it (a drawing: StretchableCanvasWdgt.stampsDroppedWidgets),
    # so the search passes over such a window and goes on to the next one down.
    where = world.topmostChildSuchThat (w) ->
      # instead of `w instanceof FrameWdgt` (type-test-elimination campaign)
      w.isFrame?() and w.contents?.acceptsSmartPlacedWidgets?()

    if where?
      where.contents.smartPlace widgetToBePlaced, @
    else
      # the new widget is a WORLD child placed beside ME, and I live on a toolbar's
      # scrolled plane — emit my corner through the plane→screen map (identity when
      # unscrolled/untilted, rounded because screen-family values may be fractional
      # under tilt), never the raw plane-local @topRight() (paint-time scroll review F1).
      widgetToBePlaced._applyMoveTo (@localPointToScreen @topRight()).round().add new Point 20, -40
      widgetToBePlaced._moveWithin world
      world.add widgetToBePlaced
