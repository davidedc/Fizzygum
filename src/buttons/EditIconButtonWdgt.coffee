# The frame strip's EDIT-MODE TOGGLE: a sliding switch naming both modes, the eye at its left end and
# the pencil at its right, with a knob standing under the one my window's content is in now. Right is
# on: editing. A press anywhere on me flips the mode, and I tell the window's contents I was pressed.
# Both modes are always on show, so I carry no hover preview and my look never contradicts my state;
# why I look like this rather than anything else: docs/archive/edit-mode-sliding-toggle.md. I keep the
# icon-button family's contract (see IconButtonWdgt), and my strip gives me a wider slot than its other
# pieces (FrameWdgt._barSpec's pieceLengths).
#
# MY MODE IS MY WINDOW'S. It tells me through showEditMode / showViewMode, driven by the enable/disable
# state-reflection callers (FrameWdgt.showEditModeInBar / showViewModeInBar) and not by my click, so I
# follow the mode however it changes.
#
# THE SLIDE IS FEEDBACK TO THE PERSON WHO PRESSED ME. Only a mode change my own press caused slides my
# knob. Any other arrives at once, or every view-mode window would slide as it is built, uncollapsed or
# restored. A slide steps on the cycle clock, a wall-clock reading, so it must never reach a captured
# pixel: world.anyKnobSlideOngoing holds the macro pump until my knob has stopped, exactly as a scroll
# glide holds it (MacroToolkit._queueDrained / readyForMacroScreenshot). My paint is a function of
# where the knob stands, so a stopped knob is the same pixels whichever cycles it took to get there.

class EditIconButtonWdgt extends IconButtonWdgt

  # default the mode so an early paint (before the window sets the real one) shows editing
  _editModeNow: true

  # where my knob stands along its travel: 0 under the eye, 1 under the pencil
  _knobPosition: 1

  # the slide under way, while I am in world.steppingWdgts: where the knob left from, and when
  _slideFrom: undefined
  _slideStartedAt: undefined

  # true only for the length of my own press (actOnClick)
  _slidesOnModeChange: false

  toolTipMessage: "edit contents"

  createAppearance: -> new EditModeToggleAppearance @

  actOnClick: ->
    @_slidesOnModeChange = true
    # Notify the containing window its edit button was pressed (the window forwards
    # to its contents); only a window answers editButtonInBarPressed. (type-test-elimination)
    @parent?.editButtonInBarPressed?()
    @_slidesOnModeChange = false

  # The window's showEditModeInBar / showViewModeInBar call these to set the CURRENT mode. The tooltip
  # always states what a press does.
  showEditMode: ->
    @toolTipMessage = "switch to view mode"
    @_moveKnobToMode true

  showViewMode: ->
    @toolTipMessage = "edit contents"
    @_moveKnobToMode false

  # where my knob stands (my appearance paints it there), and whether it is still on its way
  knobPosition: ->
    @_knobPosition

  isKnobSliding: ->
    world.steppingWdgts.has @

  # A no-op when the mode is the one I already show: the window's reflector is re-driven idempotently,
  # and a slide under way must not restart.
  _moveKnobToMode: (editing) ->
    return if editing is @_editModeNow
    @_editModeNow = editing
    if @_slidesOnModeChange
      @_slideFrom = @_knobPosition
      @_slideStartedAt = WorldWdgt.dateOfCurrentCycleStart.getTime()
      world.steppingWdgts.add @
    else
      world.steppingWdgts.delete @
      @_knobPosition = if editing then 1 else 0
      @_changed()

  # One frame of a slide, eased out: quick off the mark, settling onto the far end. A restored or
  # copied slide finds its start long gone and simply lands.
  step: ->
    target = if @_editModeNow then 1 else 0
    elapsed = WorldWdgt.dateOfCurrentCycleStart.getTime() - @_slideStartedAt
    progress = Math.max 0, Math.min 1, elapsed / WorldWdgt.theme.barToggleSlideMs
    if progress is 1
      @_knobPosition = target
      world.steppingWdgts.delete @
    else
      @_knobPosition = @_slideFrom + (target - @_slideFrom) * (1 - Math.pow 1 - progress, 3)
    @_changed()
