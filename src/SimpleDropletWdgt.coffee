# REQUIRES HighlightableMixin

# looks like a plus sign and it replaces itself with whatever you
# drop on it. It can also assign the dropped widget to a parent field
# of choice.

class SimpleDropletWdgt extends Widget

  @augmentWith HighlightableMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 0, 0, 0

  _acceptsDrops: true
  parentFieldToAttachingTheWidgetToAsString: nil

  constructor: (@parentFieldToAttachingTheWidgetToAsString) ->
    super()
    @appearance = new SimpleDropletAppearance @
    @setColor new Color 0, 0, 0

  reactToDropOf: (morphBeingDropped) ->
    # TODO we add as FREEFLOATING if we don't pass
    # the third parameter, certainly that's not always
    # the case?
    @parent?[@parentFieldToAttachingTheWidgetToAsString] = morphBeingDropped
    @addAsSiblingAfterMe \
      morphBeingDropped,
      nil,
      nil
    morphBeingDropped.setBounds @bounds
    @fullDestroy()



