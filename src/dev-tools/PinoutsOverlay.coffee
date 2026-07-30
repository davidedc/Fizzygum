# The PINOUT debug overlay: floating blue labels that name the widget they point at.
#
# A dev/debug affordance reached from a widget's context menu ("show output pins" /
# "remove output pins"), never product UI -- so it lives in its own collaborator class
# rather than inside WorldWdgt. Before arc 3 the three tracking Sets, the per-cycle
# reconciler and the two menu actions sat in WorldWdgt/Widget wrapped in `»>>` markers
# (the retired region-exclusion mechanism); re-homing them here is what let it be retired.
#
# Reached as `world.pinouts`, built in WorldWdgt's constructor behind `if PinoutsOverlay?`
# -- the collaborator pattern (cf. `world.macroToolkit`, `world.widgetFactory`), so every
# caller soaks: `world.pinouts?.…`. A build that does not ship this file simply has no
# pinouts, and nothing else has to know.
#
# THE THREE SETS, and why there are three. `widgetsToBePinouted` is the WANTED state (what
# the user asked to see pinned out). The other two are the reconciler's bookkeeping of the
# ACTUAL state: `currentPinoutingWidgets` holds the live label widgets, `widgetsBeingPinouted`
# the targets they point at. `reconcile` (once per cycle, from the world's flush) walks the
# difference and creates/moves/destroys labels so ACTUAL matches WANTED. Same reconciler
# shape as the highlight trio on WorldWdgt.
class PinoutsOverlay

  constructor: ->
    @widgetsToBePinouted = new Set
    @currentPinoutingWidgets = new Set
    @widgetsBeingPinouted = new Set

  # the two context-menu actions (Widget.showOutputPins / removeOutputPins forward here)
  show: (aWidget) ->
    @widgetsToBePinouted.add aWidget

  remove: (aWidget) ->
    @widgetsToBePinouted.delete aWidget

  isShowing: (aWidget) ->
    @widgetsToBePinouted.has aWidget

  # World teardown: drop every reference to labels the world just destroyed, and forget the
  # wanted state. Called from the SHIPPING teardown core through a soak, beside the highlight
  # trio it mirrors.
  reset: ->
    @widgetsToBePinouted.clear()
    @currentPinoutingWidgets.clear()
    @widgetsBeingPinouted.clear()

  reconcile: ->
    @currentPinoutingWidgets.forEach (eachPinoutingWidget) =>
      if @widgetsToBePinouted.has eachPinoutingWidget.wdgtThisWdgtIsPinouting
        if eachPinoutingWidget.wdgtThisWdgtIsPinouting.hasMaybeChangedPaintBounds()
          # reposition the pinout widget if needed. The label is a WORLD child, so it must anchor to the
          # target's SCREEN footprint: clippedThroughBounds is plane-local, and for a target inside a
          # rotated/scaled island the un-mapped box is the wrong plane (§7.11) — off any island
          # mapRectToScreen returns the box unchanged.
          target = eachPinoutingWidget.wdgtThisWdgtIsPinouting
          peekThroughBox = target.mapRectToScreen target.clippedThroughBounds()
          eachPinoutingWidget._applyMoveTo new Point(peekThroughBox.right() + 10,peekThroughBox.top())

      else
        @currentPinoutingWidgets.delete eachPinoutingWidget
        @widgetsBeingPinouted.delete eachPinoutingWidget.wdgtThisWdgtIsPinouting
        eachPinoutingWidget.wdgtThisWdgtIsPinouting = nil
        eachPinoutingWidget.fullDestroy()

    @widgetsToBePinouted.forEach (eachWidgetNeedingPinout) =>
      unless @widgetsBeingPinouted.has eachWidgetNeedingPinout
        hM = new StringWdgt eachWidgetNeedingPinout.toString()
        # this bare StringWdgt is used as an ephemeral overlay — mark the INSTANCE before @add so it
        # is hit-test-excluded and shadow-free (isEphemeral capability), like the HighlighterWdgt.
        hM._ephemeralOverlay = true
        world.add hM
        hM.wdgtThisWdgtIsPinouting = eachWidgetNeedingPinout
        # SCREEN-anchor, same mapping as the reposition branch above (§7.11)
        peekThroughBox = eachWidgetNeedingPinout.mapRectToScreen eachWidgetNeedingPinout.clippedThroughBounds()
        hM._applyMoveTo new Point(peekThroughBox.right() + 10,peekThroughBox.top())
        hM.setColor Color.BLUE
        hM.setWidth 400
        @currentPinoutingWidgets.add hM
        @widgetsBeingPinouted.add eachWidgetNeedingPinout
