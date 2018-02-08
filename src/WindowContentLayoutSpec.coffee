# WindowContentLayoutSpec
# REQUIRES DeepCopierMixin


class WindowContentLayoutSpec extends VerticalStackLayoutSpec

  @augmentWith DeepCopierMixin

  # when you drop something on a window, you
  # expect a couple of possible behaviours:
  # 1) the window takes the size of the dropped item
  # 2) the item takes the size of the window
  # You normally expect 1) with things that inherently have
  # a particular size and proportion, for example a slider
  # (which makes no sense when enlarged and deformed to a
  # different proportion)
  # You expect 2) with things that are "small", since you
  # want to "window" them you probably want to give them
  # more importance.
  # These two properties can define which behaviour is
  # going to take effect.
  preferredStartingWidth: nil
  preferredStartingHeight: nil
  
  # if this is set, it means that the widget can
  # meaningfully have its height set to any value,
  # so the holding window can be stretched
  # vertically to any extent (if the window itself
  # is not constrained by a layout, that is)
  # This is true for example for vertical sliders, or
  # scrolling panels (scrolling stacks, or scrolling text
  # panels, or documents).
  # This is FALSE for icons (since they'd only show empty
  # vertical space which would not be meaningful)
  # or the clock (same reason) or vertical stacks or "naked"
  # wrapping text (in those cases it's the content that dictates
  # what the height should be, there literally is nothing
  # boyond the height that they have).
  #
  # Note that we'll have to override this when we'll want
  # to maximise windows, we'll just have to
  # leave the empty vertical space.
  canSetHeightFreely: true

  resizerCanOverlapContents: true

  rememberInitialDimensions: (@element, @stack) ->
    super
    
    availableWidthInStack = @stack.availableWidthForContents()
    if @preferredStartingWidth == PreferredSize.DONT_MIND
      @widthOfElementWhenAdded = availableWidthInStack
      @elasticity = 1

  constructor: (@preferredStartingWidth, @preferredStartingHeight, elasticity) ->
    super elasticity
