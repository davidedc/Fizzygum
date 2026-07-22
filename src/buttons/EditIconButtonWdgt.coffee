# Tells the window's contents that the edit button was pressed.
# See IconButtonWdgt for the shared icon-button family contract.

class EditIconButtonWdgt extends IconButtonWdgt

  # pencil<->eye edit-mode toggle with HOVER FEEDFORWARD (docs/archive/pencil-eye-edit-mode-toggle-plan.md §8):
  #   1. MONOCHROME AT REST — the resting glyph is uncoloured (near-white on the gray bar)
  #      for BOTH modes; the SHAPE alone names the current mode (pencil = editing now,
  #      eye = viewing now). Drops the editing-yellow at rest.
  #   2. FEEDFORWARD ON HOVER — while hovered (or pressed) the button morphs to the glyph
  #      of the mode a click switches TO, in a single "this button does something" YELLOW.
  #      The shape carries the meaning; the colour just says "active / clickable".
  #   3. IMMEDIATE tooltip — the action bubble pops on hover with (almost) no delay, so the
  #      text explanation lands together with the visual preview (the shipped delay is 500ms).
  # Rest = pure status (shape); hover = pure control (next-state glyph + affordance colour + text).
  restColor: Color.create 245, 244, 245        # near-white; both glyphs at rest, reads on the gray bar
  hoverColor: Color.create 248, 188, 58         # yellow = "this button does something" (both hover previews)

  # default the mode so an early paint (before the window sets the real mode) is a mono pencil
  _editModeNow: true

  iconToolTipMessage: "edit contents"

  createAppearance: -> new PencilIconAppearance @

  actOnClick: ->
    # Notify the containing window its edit button was pressed (the window forwards
    # to its contents); only a window answers editButtonInBarPressed. (type-test-elimination)
    @parent?.editButtonInBarPressed?()

  # The window's showEditModeInBar / showViewModeInBar call these to set the CURRENT
  # mode; the glyph + colour for every state are then derived by @_updateColor, so
  # rest and hover can never disagree.
  showPencilGlyph: ->          # edit mode NOW
    @_editModeNow = true
    @toolTipMessage = "switch to view mode"
    @_updateColor()

  showEyeGlyph: ->             # view mode NOW
    @_editModeNow = false
    @toolTipMessage = "edit contents"
    @_updateColor()

  # Override the HighlightableMixin colour hook to ALSO swap the glyph. At rest: the
  # CURRENT mode's glyph, monochrome. Highlighted / pressed: the glyph of the mode a
  # click switches TO, in the affordance yellow (the feedforward).
  _updateColor: ->
    if @state is @STATE_NORMAL
      @appearance = if @_editModeNow then new PencilIconAppearance @ else new EyeIconAppearance @
      previewColor = @restColor
    else                       # hovered or pressed -> preview the OTHER mode, in yellow
      @appearance = if @_editModeNow then new EyeIconAppearance @ else new PencilIconAppearance @
      previewColor = @hoverColor
    # public-call-sanctioned: mirrors HighlightableMixin._updateColor (which this overrides) — setColor is the
    # pure paint-colour setter (sets @color + changed, no layout settle), here driving the per-state glyph colour.
    @setColor previewColor
    @_changed()   # explicit: setColor early-returns when the colour is unchanged, but the GLYPH may still have swapped

  # Immediate action tooltip: the base delay is 500ms; on THIS button the
  # bubble explains what a click does, so we want it to land with the hover preview — show
  # it ~next-frame instead of after the pause. (SystemTests already bypass the delay, so this
  # only changes the live/interactive timing.)
  startCountdownForBubbleHelp: (contents) ->
    ToolTipWdgt.createInAWhileIfHandStillContainedInWidget @, contents, 1
