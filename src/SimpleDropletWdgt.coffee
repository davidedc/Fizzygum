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

  _reactToDropOf: (widgetBeingDropped) ->
    # TODO we add as FREEFLOATING if we don't pass
    # the third parameter, certainly that's not always
    # the case?
    @parent?[@parentFieldToAttachingTheWidgetToAsString] = widgetBeingDropped
    @addAsSiblingAfterMe \
      widgetBeingDropped,
      nil,
      nil
    # _reactToDropOf is low-level (it runs inside the drop's settle batch), so it uses the RAW bounds setter,
    # not the public deferred setBounds (lint [A]: a low-level method must not call a public geometry setter).
    # The dropped widget is freefloating here (added via addAsSiblingAfterMe with nil -> ATTACHEDAS_FREEFLOATING),
    # so the immediate raw set is byte-identical to setBounds's desired-extent/position path, and
    # silentRawSetExtent fires the container re-fit seam. (Structural calls -- addAsSiblingAfterMe / fullDestroy --
    # stay public: they are absorbed by the drop's batch and self-settle at the non-batch return-to-origin caller.)
    widgetBeingDropped.silentRawSetBounds @bounds
    @fullDestroy()



