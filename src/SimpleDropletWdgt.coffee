# An empty icon holder's DROP PLACEHOLDER (the glyph a WidgetHolderWithCaptionWdgt, or a composite
# icon, shows while it holds none): it replaces itself with whatever you drop on it, and can also
# assign the dropped widget to a parent field of choice. A placeholder, not a button: my look
# (SimpleDropletAppearance, a borderless well with a plus) is the same in every pointer state and
# is read from the theme as I am painted, never from a colour of mine.

class SimpleDropletWdgt extends Widget

  _acceptsDrops: true
  parentFieldToAttachingTheWidgetToAsString: undefined

  constructor: (@parentFieldToAttachingTheWidgetToAsString) ->
    super()
    @appearance = new SimpleDropletAppearance @

  _reactToChildDropped: (widgetBeingDropped) ->
    @parent?[@parentFieldToAttachingTheWidgetToAsString] = widgetBeingDropped
    @addAsSiblingAfterMe widgetBeingDropped
    # _reactToChildDropped runs inside the drop's single settle, so it uses NON-settling calls throughout:
    # addAsSiblingAfterMe already routes through _addNoSettle; _commitBounds is the immediate mutator (the
    # dropped widget is freefloating -- added via addAsSiblingAfterMe with an undefined layoutSpec (free-floating) --
    # so the immediate raw set is byte-identical to the deferred setBounds path and fires the container
    # re-fit seam); fullDestroy -> _fullDestroyNoSettle.
    widgetBeingDropped._commitBounds @bounds
    @_fullDestroyNoSettle()



