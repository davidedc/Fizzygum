# looks like a plus sign and it replaces itself with whatever you
# drop on it. It can also assign the dropped widget to a parent field
# of choice.

class SimpleDropletWdgt extends Widget

  @augmentWith HighlightableMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.BLACK

  _acceptsDrops: true
  parentFieldToAttachingTheWidgetToAsString: undefined

  constructor: (@parentFieldToAttachingTheWidgetToAsString) ->
    super()
    @appearance = new SimpleDropletAppearance @
    @setColor Color.BLACK

  _reactToChildDropped: (widgetBeingDropped) ->
    @parent?[@parentFieldToAttachingTheWidgetToAsString] = widgetBeingDropped
    @addAsSiblingAfterMe \
      widgetBeingDropped,
      undefined,
      undefined
    # _reactToChildDropped runs inside the drop's single settle, so it uses NON-settling calls throughout:
    # addAsSiblingAfterMe already routes through _addNoSettle; _commitBounds is the immediate mutator (the
    # dropped widget is freefloating -- added via addAsSiblingAfterMe with an undefined layoutSpec (free-floating) --
    # so the immediate raw set is byte-identical to the deferred setBounds path and fires the container
    # re-fit seam); fullDestroy -> _fullDestroyNoSettle.
    widgetBeingDropped._commitBounds @bounds
    @_fullDestroyNoSettle()



