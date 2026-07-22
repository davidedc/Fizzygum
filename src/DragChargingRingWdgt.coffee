# The drag-embed CHARGING RING overlay (docs/specs/drag-embed-interaction-spec.md §6/§11): a small
# cursor-anchored ring that fills while a WINDOW payload lingers over a receptive candidate, giving
# the user visible feedback of the dwell-to-arm charge. It is an EPHEMERAL (reconciler-owned,
# hit-test-excluded, shadow-free, snapshot-excluded — the Phase-1 isEphemeral capability).
#
# PRESENTATION ONLY. The arm DECISION is the hand's pure event-time elapsed check
# (ActivePointerWdgt.updateDragEmbedStateMachine); the ring never feeds it. The FILL amount is a pure
# function of ELAPSED time from the linger origin, computed the analog-clock way (src/apps/
# AnalogClockWdgt.coffee): deterministic EVENT-time under the test harness (Automator.animationsPacing
# Control) so a byte-exact screenshot mid-charge is reproducible, WALL-time in production so the ring
# keeps filling smoothly during a physically frozen hold (which emits zero events — the S2 finding).
#
# No stepping registration: WorldWdgt.addDragAffordanceWidgets calls updateChargeDeclaration every
# cycle (the hand's state machine runs on the per-cycle hover re-sync too), so the fill advances each
# cycle and paint stays read-only.

class DragChargingRingWdgt extends Widget

  _ephemeralOverlay: true          # reconciler-owned drag-affordance overlay (Phase-1 capability)
  ringSteps: 5
  chargeStep: 0                    # how many segments are filled (0..ringSteps) — read by the appearance
  filledColor: nil
  emptyColor: nil
  lingerOriginEventTime: nil
  lingerOriginWallTime: nil

  constructor: ->
    super()
    @appearance = new DragChargingRingAppearance @
    @ringSteps = WorldWdgt.preferencesAndSettings.dwellRingSteps
    @filledColor = Color.create 248, 188, 58, 1     # pencil-yellow accent (matches the candidate outline)
    @emptyColor  = Color.create 180, 180, 180, 0.55

  # Reposition at the cursor and recompute the fill from ELAPSED time. Called every cycle the ring is
  # declared. @_changed() only on a quantised step change (paint stays read-only); bounds re-applied
  # only when the cursor actually moved (no spurious dirties during a still hold).
  updateChargeDeclaration: (decl) ->
    @lingerOriginEventTime = decl.lingerOriginEventTime
    @lingerOriginWallTime = decl.lingerOriginWallTime
    c = decl.centerPoint
    unless @_lastRingCenter? and @_lastRingCenter.equals c
      @_applyBounds new Rectangle(c.x - 11, c.y - 11, c.x + 11, c.y + 11)
      @_lastRingCenter = c
    dwellMs = WorldWdgt.preferencesAndSettings.dwellToArmMs
    newStep = Math.max 0, Math.min(@ringSteps, Math.floor(@_elapsedForCharge() / dwellMs * @ringSteps))
    if newStep isnt @chargeStep
      @chargeStep = newStep
      @_changed()

  # Elapsed ms from the linger origin. Event-time (deterministic) under the harness, wall-time in
  # production — the analog-clock precedent (AnalogClockWdgt._calculateHandsAngles).
  _elapsedForCharge: ->
    if Automator? and Automator.animationsPacingControl and Automator.state == Automator.PLAYING
      if WorldWdgt.timeOfEventBeingProcessed? and @lingerOriginEventTime?
        WorldWdgt.timeOfEventBeingProcessed - @lingerOriginEventTime
      else
        0
    else
      if @lingerOriginWallTime? then (WorldWdgt.dateOfCurrentCycleStart - @lingerOriginWallTime) else 0

  colloquialName: ->
    "drag charging ring"
