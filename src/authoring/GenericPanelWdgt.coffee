# The GENERIC-PANEL framed citizen AND the container-citizen family BASE
# (Frame-model plan §5.B): a stretchable panel IS its window. One of the Makers'
# documents (MakerDocumentWdgt, which owns the title, the save-or-destroy close
# and the payload rebuild every such document shares): this class builds the
# family's shared naked payload -- a StretchableWidgetContainerWdgt -- and states
# what counts as the user having changed it. SlideWdgt / DashboardWdgt /
# PatchProgrammingWdgt / ImageWdgt are thin subclasses (kind name + icon +
# toolbar variant, and ImageWdgt its own payload) -- the same two-role shape the
# retired StretchableEditableWdgt family had, minus the editor middle layer,
# whose coordination relays dissolved into the frame<->payload protocols (§5.B
# B-iii): the CONTAINER owns the edit mode + ratio behaviour, the frame does
# the chrome.

class GenericPanelWdgt extends MakerDocumentWdgt

  providesAmenitiesForEditing: true

  # the family's payload hook (the DocumentWdgt shape): the ctor AND the reset
  # build through it (MakerDocumentWdgt), so a subclass with a richer apparatus
  # (ImageWdgt's canvas + glass) overrides ONE method.
  _makeStartingPayload: ->
    new StretchableWidgetContainerWdgt

  # ⚠ Do NOT delete this as "the same as the derivation". It IS what Widget's derivation would
  # produce, but I extend FrameWdgt -- so without it the chain answers FrameWdgt's "window", not the
  # derivation, and the window's title goes with it (MakerDocumentWdgt titles it with this).
  # (SpreadsheetWdgt sits in the same trap.)
  colloquialName: ->
    "generic panel"

  representativeIcon: ->
    new GenericPanelIconWdgt

  # content dropped in crystallizes the container's ratio -- that IS the
  # "user changed something" signal (byte-what the retired editor checked)
  hasStartingContentBeenChangedByUser: ->
    @contents?.ratio?
