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



