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

  # Self-protecting resize (INV-2): I am a composite whose children are placed by my subclasses'
  # _reLayout, but parents size me with the raw _applyExtent core (e.g.
  # WidgetHolderWithCaptionWdgt._reLayout), which alone would leave my children at stale
  # geometry -- the 2026-07 broken-icons regression. Declaring the capability makes the base
  # Widget._applyExtent re-lay my children when an immediate resize commits my frame (the
  # unified INV-2 mechanism, 2026-07-16 -- this class carried the first of the 8 hand-copied
  # _applyExtent overrides that mechanism replaced).
  _placesChildrenInLayout: ->
    true

  # per-class predicate gating the base's composite-child re-lay: BOTH composite children must
  # exist (the ctor _applyExtents 95x95 BEFORE the second child is built; the trailing
  # _invalidateLayout/settle lays the children out then). Abstract-false at this level; the
  # subclasses (GenericShortcutIconWdgt / GenericObjectIconWdgt) answer for their own child pairs.
  _compositeChildrenBuilt: ->
    false
