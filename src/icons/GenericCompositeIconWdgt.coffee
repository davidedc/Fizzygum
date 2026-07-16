# Shared base of the two composite desktop icons (GenericObjectIconWdgt /
# GenericShortcutIconWdgt): a square composite whose two children are placed by the
# concrete class's own _reLayout. Hosts the surface the pair used to duplicate
# byte-identically; each concrete class keeps its ctor field, its
# _buildAndConnectChildrenNoSettle and its placement _reLayout. Never instantiated
# directly.
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
