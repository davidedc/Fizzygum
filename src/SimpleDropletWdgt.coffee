# this file is excluded from the fizzygum homepage build

# looks like a plus sign and it replaces itself with whatever you
# drop on it. It can also assign the dropped widget to a parent field
# of choice.

class SimpleDropletWdgt extends Widget

  @augmentWith HighlightableMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.BLACK

  _acceptsDrops: true
  parentFieldToAttachingTheWidgetToAsString: nil

  constructor: (@parentFieldToAttachingTheWidgetToAsString) ->
    super()
    @appearance = new SimpleDropletAppearance @
    @setColor Color.BLACK

  _reactToChildDropped: (widgetBeingDropped) ->
    # TODO we add as FREEFLOATING if we don't pass
    # the third parameter, certainly that's not always
    # the case?
    @parent?[@parentFieldToAttachingTheWidgetToAsString] = widgetBeingDropped
    @addAsSiblingAfterMe \
      widgetBeingDropped,
      nil,
      nil
    # _reactToChildDropped runs inside the drop's single settle, so it uses NON-settling calls throughout:
    # addAsSiblingAfterMe already routes through _addNoSettle; _commitBounds is the immediate mutator (the
    # dropped widget is freefloating -- added via addAsSiblingAfterMe with nil -> ATTACHEDAS_FREEFLOATING --
    # so the immediate raw set is byte-identical to the deferred setBounds path and fires the container
    # re-fit seam); fullDestroy -> _fullDestroyNoSettle.
    widgetBeingDropped._commitBounds @bounds
    @_fullDestroyNoSettle()



