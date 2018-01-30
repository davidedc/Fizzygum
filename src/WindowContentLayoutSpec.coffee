# WindowContentLayoutSpec


class WindowContentLayoutSpec extends VerticalStackLayoutSpec

  @augmentWith DeepCopierMixin

  preferredStartingWidth: nil
  preferredStartingHeight: nil
  
  # if this is set, it means that the widget can
  # meaningfully have its height set to any value
  # this is true for example for vertical sliders,
  # but false for icons (since they'd only show empty
  # vertical space which would not be meaningful)
  # or vertical stacks or "naked" wrapping text
  # If this is set, the holding window can be stretched
  # vertically to any extent (if the window itself
  # is not constrained by a layout)
  canSetHeightFreely: true

  resizerCanOverlapContents: true

  constructor: (@preferredStartingWidth, @preferredStartingHeight, elasticity) ->
    super elasticity
