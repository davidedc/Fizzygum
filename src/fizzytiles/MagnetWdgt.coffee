# this file is excluded from the fizzygum homepage build

# A draggable "fridge magnet" tile: a flat labeled button (LabelButtonWdgt) that
# is draggable (rejectDrags=false) rather than a menu row. The generic
# flat-label-button machinery it relies on (label, flat paint, centring) lives in
# LabelButtonWdgt, so it needs no label/paint code of its own -- the base's
# single-line StringWdgt _createLabel is exactly what a magnet wants (a self-sized
# label, no box resize).

class MagnetWdgt extends LabelButtonWdgt

  putIntoWords: false
  isTemplate: true

  constructor: (
      @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked,
      @target
     ) ->
    super
    @defaultRejectDrags = false

  rightCenter: ->
    new Point(@right(),@height()/2)

  leftCenter: ->
    new Point(@left(),@height()/2)
