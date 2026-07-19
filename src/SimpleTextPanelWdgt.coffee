# TODO the SimpleTextPanelWdgt can't quite stand on its own,
# it's really meant to be inside a ScrollPanel.
#
# The analogous VerticalStackPanel is better engineered,
# that one can indeed stand on its own.
#
# However, there really isn't a need for this widget
# because it doesn't provide anything more than what the
# SimpleText widget can already provide.

class SimpleTextPanelWdgt extends PanelWdgt

  constructor: (
    @textAsString,
    wraps,
    padding
    ) ->

    super()
    @disableDrops()
    @disableDrops()
    @isTextLineWrapping = wraps
    @color = Color.WHITE
    @_buildAndConnectChildren()

  # (type-test-elimination ε) My constructor's `@takesOverAndMergesChildrensMenus = true` write
  # was DELETED — it was dead (both read sites were scroll-frame-scoped), and Widget's menu
  # take-over read is now field-only. A document saved BEFORE that change carries the flag as a
  # serialized own-property, which would newly make ME (the nearest matching parent) hijack my
  # text's context menu on load — strip it, restoring the class default (false) and the old
  # behaviour.
  _afterDeserialization: ->
    delete @takesOverAndMergesChildrensMenus

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    ostmA = new SimpleTextWdgt(
      @textAsString,nil,nil,nil,nil,nil,Color.create(230, 230, 130), 1)
    ostmA.isEditable = true
    if !@isTextLineWrapping
      # non-wrapping ("code view"): hug the natural text width.
      ostmA.softWrap = false
    ostmA.enableSelecting()
    @_addNoSettle ostmA
    ostmA.lockToPanels()

