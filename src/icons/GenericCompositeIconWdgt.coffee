# Shared base of the two composite desktop icons (GenericObjectIconWdgt /
# GenericShortcutIconWdgt): a square composite whose two children are placed by the
# concrete class's own _reLayout. Hosts the surface the pair used to duplicate
# byte-identically; each concrete class keeps its ctor field, its
# _buildAndConnectChildrenNoSettle, its _compositeChildrenBuilt predicate and its
# placement _reLayout. Never instantiated directly.
class GenericCompositeIconWdgt extends Widget

  constructor: (@icon) ->
    super()
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  widthWithoutSpacing: ->
    Math.min @width(), @height()

  _resizeToWithoutSpacing: ->
    @_applyExtent new Point @widthWithoutSpacing(), @widthWithoutSpacing()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  _setWidthSizeHeightAccordingly: (newWidth) ->
    @_resizeToWithoutSpacing()
    @_applyExtent new Point newWidth, newWidth
    @_reLayout()
    @height()  # Path B: hand the resulting height back. See Widget._setWidthSizeHeightAccordingly.

  # Self-protecting resize (INV-2): I am a composite whose children are placed by my
  # _reLayout, but parents size me with the raw _applyExtent core (e.g.
  # WidgetHolderWithCaptionWdgt._reLayout), which alone would leave my children at
  # stale geometry -- the 2026-07 broken-icons regression. Same idiom as
  # StretchablePanelWdgt/StretchableWidgetContainerWdgt._applyExtent. The
  # _compositeChildrenBuilt() guard skips the re-layout during construction (the ctor
  # _applyExtents 95x95 BEFORE the second child is built); the trailing
  # _invalidateLayout/settle lays the children out then.
  _applyExtent: (extent) ->
    if extent.equals @extent()
      return
    super
    if @_compositeChildrenBuilt()
      @_reLayout @bounds

  # per-class predicate: BOTH composite children exist (see _applyExtent's guard note)
  _compositeChildrenBuilt: ->
    false
