# FrameContentLayoutSpec

class FrameContentLayoutSpec extends VerticalStackLayoutSpec

  # Sentinel values for the constructor's preferredStartingWidth/Height, used as
  # ctor args and in FrameWdgt's comparisons. -1 = "keep the size I have now";
  # -2 = "I don't mind, size me". (Folded in from the former PreferredSize marker
  # class -- docs/archive/accidental-complexity-reduction-plan.md.)
  @THIS_ONE_I_HAVE_NOW: -1
  @DONT_MIND: -2

  # Govern how dropped content and its window negotiate initial size: a widget
  # with an inherent size/proportion (e.g. a slider, which deforms badly) keeps
  # its own size and the window takes it; a "small", proportion-agnostic widget
  # instead takes the window's size.
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
  # beyond the height that they have).
  #
  # Note that we'll have to override this when we'll want
  # to maximise windows, we'll just have to
  # leave the empty vertical space.
  canSetHeightFreely: true

  resizerCanOverlapContents: true

  # born as frame content (see VerticalStackLayoutSpec — a content stack that adopts a kept
  # instance of me flips this false)
  attachedAsFrameContent: true

  # am I ACTIVE as a frame's content right now? (false while a content stack has adopted me)
  isFrameContentActive: ->
    @attachedAsFrameContent

  # Capability query (the isFrame?() idiom): lets a content widget ask "am I
  # laid out as FRAME content right now?" without naming this class -- no base
  # default, dispatched via ?(), a non-frame-content spec answers undefined.
  # Consumer: StretchableWidgetContainerWdgt's crystallization write-guards
  # (§5.B -- ratio crystallization must not height-lock a frame-content spec).
  isFrameContentSpec: -> true

  captureInitialPlacement: (@element, @stack) ->
    super

    availableWidthInStack = @stack.availableWidthForContents()
    if @preferredStartingWidth == FrameContentLayoutSpec.DONT_MIND
      @desiredWidth = availableWidthInStack
      @grow = 1

  # NB every in-tree caller passes a grow explicitly (0 or 1) — an explicit grow survives
  # the capture's derivation (see VerticalStackLayoutSpec.captureInitialPlacement).
  constructor: (@preferredStartingWidth, @preferredStartingHeight, grow) ->
    super grow
