# The GENERIC-PANEL framed citizen AND the container-citizen family BASE
# (Frame-model plan §5.B): a stretchable panel IS its window. Builds the
# shared naked payload -- a StretchableWidgetContainerWdgt -- and declares the
# family's shared knowledge: the save-or-destroy close policy, the
# payload-rebuild reset, the kind-names-the-window title. SlideWdgt /
# DashboardWdgt / PatchProgrammingWdgt are thin subclasses (kind name + icon +
# toolbar variant) -- the same two-role shape the retired
# StretchableEditableWdgt family had, minus the editor middle layer, whose
# coordination relays dissolved into the frame<->payload protocols (§5.B
# B-iii): the CONTAINER owns the edit mode + ratio behaviour, the frame does
# the chrome.

class GenericPanelWdgt extends FrameWdgt

  providesAmenitiesForEditing: true

  constructor: ->
    super @_makeStartingPayload()

  # the family's payload hook (the DocumentWdgt shape): the ctor AND the reset
  # below build through it, so a subclass with a richer apparatus (ImageWdgt's
  # canvas + glass) overrides ONE method.
  _makeStartingPayload: ->
    new StretchableWidgetContainerWdgt

  colloquialName: ->
    "Generic panel"

  # the kind names the window -- the base hook would title from the payload's
  # colloquialName ("stretchable panel")
  _titleForContents: (aWdgt) ->
    @colloquialName()

  representativeIcon: ->
    new GenericPanelIconWdgt

  # content dropped in crystallizes the container's ratio -- that IS the
  # "user changed something" signal (byte-what the retired editor checked)
  hasStartingContentBeenChangedByUser: ->
    @contents?.ratio?

  # The save-or-destroy close policy (was the retired editor's
  # closeFromContainerFrame). The citizen IS the window, so the save prompt
  # takes it in both roles -- the FolderWindowWdgt shape.
  closeFromFrameBar: ->
    if !@hasStartingContentBeenChangedByUser() and !world.anyReferenceToWdgt @
      # there is no real contents to save
      @fullDestroy()
    else if !world.anyReferenceToWdgt @
      prompt = new SaveShortcutPromptWdgt @, @
      prompt.popUpAtHand()
    else
      @close()

  # A citizen never falls back to the empty-window placeholder: losing the
  # payload rebuilds a FRESH container (was the retired editor's
  # _reactToChildPickedUp recreate). NOT during my own teardown (§5.B B3 case
  # law: constructing a fresh child inside the destroy-until-empty iteration
  # never terminates).
  _resetToDefaultContents: ->
    return if @_beingFullDestroyed
    @_destroyToolbarNoSettle()
    @contents = @_makeStartingPayload()
    @_buildAndConnectChildrenNoSettle()
