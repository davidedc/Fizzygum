# A draggable "fridge magnet" tile: a flat labeled button (LabelButtonWdgt) that
# is draggable (rejectDrags=false) rather than a menu row. The generic
# flat-label-button machinery it relies on (label, flat paint, centring) lives in
# LabelButtonWdgt, so it needs no label/paint code of its own -- the base's
# single-line StringWdgt _createLabel is exactly what a magnet wants (a self-sized
# label, no box resize).

class MagnetWdgt extends LabelButtonWdgt

  putIntoWords: false
  isTemplate: true

  # A magnet has a target and no action — it is dragged, not triggered — so `target` is the
  # whole head. (A bare `super` would forward `arguments` verbatim into LabelButtonWdgt's
  # (target, action, opts), which is exactly how a signature change mis-binds a field in
  # silence: the call must be explicit.)
  constructor: (target) ->
    super target, undefined
    @defaultRejectDrags = false

  rightCenter: ->
    new Point(@right(),@height()/2)

  leftCenter: ->
    new Point(@left(),@height()/2)
